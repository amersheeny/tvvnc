#include <jni.h>
#include <android/native_window_jni.h>
#include <android/hardware_buffer.h>
#include <android/bitmap.h>
#include <rfb/rfbclient.h>
#include <atomic>
#include <chrono>
#include <cstring>
#include <deque>
#include <future>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>
#include <sys/socket.h>
#include <cerrno>
#include "rfb_errors.h"

namespace {
JavaVM* vm = nullptr;
struct Session;
thread_local Session* current = nullptr;
int clientTag;
std::mutex registryMutex;
std::unordered_map<jlong, std::shared_ptr<Session>> sessions;
std::atomic<jlong> nextId{1};

struct Command {
  int kind, a, b, c;
  int expectedWidth = 0, expectedHeight = 0;
  jlong generation = 0;
  std::string text;
  std::atomic<int> stage{0}; // queued, executing, complete, cancelled
  std::promise<int> result;
};
struct Session {
  std::atomic<bool> running{true}, connected{false};
  std::atomic<int> fd{-1}, error{1};
  std::string host, password;
  bool authenticationPending = false;
  int port = 5900, width = 0, height = 0;
  int presentationWidth = 1280;
  std::atomic<jlong> inputGeneration{0};
  int pointerX = 0, pointerY = 0, pointerButtons = 0;
  bool dirty = false, hasFrame = false;
  bool probePending = false;
  std::chrono::steady_clock::time_point probeAt;
  std::mutex pixelsMutex, surfaceMutex, queueMutex, socketMutex;
  std::vector<uint8_t> pixels;
  std::deque<std::shared_ptr<Command>> queue;
  ANativeWindow* window = nullptr;
  jobject callback = nullptr;
  jmethodID event = nullptr, metadata = nullptr;
  std::thread worker;
  rfbClient* client = nullptr;

  void notify(JNIEnv* env, int kind, int a = 0, int b = 0) {
    env->CallVoidMethod(callback, event, kind, a, b);
    if (env->ExceptionCheck()) { env->ExceptionClear(); running = false; error = 5; }
  }
  bool render() {
    std::lock_guard<std::mutex> guard(surfaceMutex);
    if (!window || !hasFrame) return false;
    const int targetWidth = presentationWidth == 0 ? width : std::min(width, presentationWidth);
    const int targetHeight = std::max(1, height * targetWidth / width);
    if (ANativeWindow_setBuffersGeometry(window, targetWidth, targetHeight, AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM) < 0) {
      return false;
    }
    ANativeWindow_Buffer buffer{};
    if (ANativeWindow_lock(window, &buffer, nullptr) != 0) return false;
    const bool valid = buffer.width >= targetWidth && buffer.height >= targetHeight;
    if (valid) {
      auto* source = reinterpret_cast<const uint32_t*>(pixels.data());
      auto* target = static_cast<uint32_t*>(buffer.bits);
      for (int y = 0; y < targetHeight; ++y)
        for (int x = 0; x < targetWidth; ++x)
          target[y * buffer.stride + x] = source[(y * height / targetHeight) * width + x * width / targetWidth] | 0xff000000u;
    }
    return ANativeWindow_unlockAndPost(window) == 0 && valid;
  }
  void drain() {
    std::deque<std::shared_ptr<Command>> pending;
    { std::lock_guard<std::mutex> guard(queueMutex); pending.swap(queue); }
    for (auto& command : pending) {
      int expected = 0;
      if (!running || !command->stage.compare_exchange_strong(expected, 1)) {
        std::fill(command->text.begin(), command->text.end(), '\0');
        command->result.set_value(0); continue;
      }
      rfbBool sent = FALSE;
      switch (command->kind) {
        case 0:
          if (command->generation != inputGeneration || width != command->expectedWidth || height != command->expectedHeight ||
              command->a < 0 || command->b < 0 || command->a >= width || command->b >= height) {
            command->stage = 2; command->result.set_value(0); continue;
          }
          sent = SendPointerEvent(client, command->a, command->b, command->c);
          pointerX = command->a; pointerY = command->b; pointerButtons = command->c; break;
        case 1: sent = SendKeyEvent(client, static_cast<uint32_t>(command->a), command->b != 0); break;
        case 2:
          if (client->extendedClipboardServerCapabilities)
            sent = SendClientCutTextUTF8(client, command->text.data(), static_cast<int>(command->text.size()));
          else {
            // Classic ClientCutText is Latin-1, not UTF-8. A Unicode string
            // cannot be silently corrupted into this representation.
            bool ascii = true;
            for (unsigned char byte : command->text) if (byte >= 128) ascii = false;
            if (!ascii) { command->stage = 2; command->result.set_value(0); std::fill(command->text.begin(), command->text.end(), '\0'); continue; }
            sent = SendClientCutText(client, command->text.data(), static_cast<int>(command->text.size()));
          }
          break;
        case 3: sent = SendFramebufferUpdateRequest(client, 0, 0, width, height, FALSE); break;
        case 4:
          presentationWidth = command->a == 0 ? 0 : 1280;
          sent = SendFramebufferUpdateRequest(client, 0, 0, width, height, FALSE); break;
        case 5:
          sent = SendPointerEvent(client, std::min(pointerX, std::max(0, width - 1)),
              std::min(pointerY, std::max(0, height - 1)), 0);
          pointerButtons = 0; break;
      }
      std::fill(command->text.begin(), command->text.end(), '\0');
      command->stage = 2;
      command->result.set_value(sent ? 1 : 2);
    }
  }
};

void libraryLog(const char* format, ...) {
  // Never forward server strings or secret-bearing protocol payloads into logs.
  // Errors remain observable as categorized connection events.
  if (!current || !format) return;
  std::string text(format);
  if (text.find("VNC authentication succeeded") != std::string::npos) current->authenticationPending = false;
  if (const auto category = rfbErrorCategory(text, current->authenticationPending)) {
    if (current->error != 2) current->error = category;
  }
}
Session* state(rfbClient* client) { return static_cast<Session*>(rfbClientGetClientData(client, &clientTag)); }
char* password(rfbClient* client) {
  state(client)->authenticationPending = true;
  return strdup(state(client)->password.c_str());
}
rfbBool allocate(rfbClient* client) {
  auto* s = state(client);
  if (s->width == client->width && s->height == client->height && !s->pixels.empty()) {
    // SetEncodings can elicit another unchanged ExtDesktopSize. It is not a
    // geometry change and must not reset zoom or discard the current pixels.
    client->frameBuffer = s->pixels.data(); return TRUE;
  }
  s->inputGeneration = 0;
  if (s->pointerButtons) {
    SendPointerEvent(client, 0, 0, 0); s->pointerButtons = 0;
  }
  const int width = client->width, height = client->height;
  if (width <= 0 || height <= 0 || width > 8192 || height > 8192 ||
      static_cast<uint64_t>(width) * height > 16777216) { s->error = 4; return FALSE; }
  try { s->pixels.assign(static_cast<size_t>(width) * height * 4, 0); }
  catch (const std::bad_alloc&) { s->error = 4; return FALSE; }
  s->width = width; s->height = height; s->hasFrame = false;
  client->frameBuffer = s->pixels.data();
  JNIEnv* env = nullptr;
  vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
  if (env) s->notify(env, 1, width, height);
  return TRUE;
}
void rectangle(rfbClient* client, int, int, int w, int h) { if (w > 0 && h > 0) state(client)->dirty = true; }
void frame(rfbClient* client) {
  auto* s = state(client);
  s->probePending = false;
  if (!s->dirty) return;
  s->dirty = false; s->hasFrame = true;
  const bool presented = s->render();
  JNIEnv* env = nullptr;
  vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
  if (env) s->notify(env, presented ? 2 : 5, s->width, s->height);
}
std::shared_ptr<Session> lookup(jlong id) {
  std::lock_guard<std::mutex> guard(registryMutex);
  auto item = sessions.find(id);
  return item == sessions.end() ? nullptr : item->second;
}

jlong start(JNIEnv* env, jobject owner, jstring host, jint port, jbyteArray secret) {
  auto s = std::make_shared<Session>();
  const char* hostname = env->GetStringUTFChars(host, nullptr);
  s->host = hostname; env->ReleaseStringUTFChars(host, hostname);
  const auto length = env->GetArrayLength(secret);
  s->password.resize(length);
  env->GetByteArrayRegion(secret, 0, length, reinterpret_cast<jbyte*>(s->password.data()));
  s->port = port;
  s->callback = env->NewGlobalRef(owner);
  s->event = env->GetMethodID(env->GetObjectClass(owner), "onNativeEvent", "(III)V");
  s->metadata = env->GetMethodID(env->GetObjectClass(owner), "onNativeMetadata", "([BIIIZ)V");
  const jlong id = nextId++;
  { std::lock_guard<std::mutex> guard(registryMutex); sessions[id] = s; }
  s->worker = std::thread([s] {
    JNIEnv* workerEnv = nullptr;
    vm->AttachCurrentThread(&workerEnv, nullptr);
    current = s.get();
    auto* client = rfbGetClient(8, 3, 4);
    s->client = client;
    client->serverHost = strdup(s->host.c_str());
    client->serverPort = s->port;
    client->connectTimeout = 4; client->readTimeout = 4;
    client->appData.shareDesktop = TRUE;
    client->appData.encodingsString = "tight zrle hextile raw";
    client->appData.qualityLevel = 6;
    client->appData.compressLevel = 2;
    client->format.bitsPerPixel = 32; client->format.depth = 24;
    client->format.trueColour = TRUE; client->format.bigEndian = FALSE;
    client->format.redMax = client->format.greenMax = client->format.blueMax = 255;
    client->format.redShift = 0; client->format.greenShift = 8; client->format.blueShift = 16;
    client->GetPassword = password;
    client->MallocFrameBuffer = allocate;
    client->GotFrameBufferUpdate = rectangle;
    client->FinishedFrameBufferUpdate = frame;
    rfbClientSetClientData(client, &clientTag, s.get());
    // Use the two stages explicitly: rfbInitClient frees its client on failure,
    // whereas this session owns cleanup for every outcome.
    bool initialized = false;
    if (rfbClientConnect(client)) {
      { std::lock_guard<std::mutex> socketGuard(s->socketMutex); s->fd = client->sock; }
      std::lock_guard<std::mutex> guard(s->pixelsMutex);
      if (s->running) initialized = rfbClientInitialise(client);
    }
    if (!initialized && (errno == EACCES || errno == EPERM) && s->error == 1) s->error = 7;
    std::fill(s->password.begin(), s->password.end(), '\0'); s->password.clear();
    const auto nameLength = client->desktopName ? std::min<size_t>(std::strlen(client->desktopName), 256) : 0;
    auto name = workerEnv->NewByteArray(static_cast<jsize>(nameLength));
    if (name) {
      if (nameLength) workerEnv->SetByteArrayRegion(name, 0, static_cast<jsize>(nameLength), reinterpret_cast<const jbyte*>(client->desktopName));
      workerEnv->CallVoidMethod(s->callback, s->metadata, name, client->major, client->minor,
          static_cast<jint>(client->authScheme), static_cast<jboolean>(client->extendedClipboardServerCapabilities != 0));
      workerEnv->DeleteLocalRef(name);
    }
    if (workerEnv->ExceptionCheck()) { workerEnv->ExceptionClear(); s->running = false; s->error = 5; }
    if (initialized && s->running) {
      s->connected = true; s->notify(workerEnv, 3);
      s->probePending = true;
      s->probeAt = std::chrono::steady_clock::now();
      auto lastProbe = s->probeAt;
      int fastFrames = 0;
      while (s->running) {
        s->drain();
        const auto now = std::chrono::steady_clock::now();
        if (s->probePending && now - s->probeAt > std::chrono::seconds(10)) { s->error = 6; break; }
        if (!s->probePending && now - lastProbe > std::chrono::seconds(5)) {
          if (!SendFramebufferUpdateRequest(client, 0, 0, s->width, s->height, FALSE)) break;
          s->probePending = true; s->probeAt = now; lastProbe = now;
        }
        const int result = WaitForMessage(client, 20'000);
        if (result < 0) break;
        if (result > 0) {
          std::lock_guard<std::mutex> guard(s->pixelsMutex);
          const auto begun = std::chrono::steady_clock::now();
          if (!HandleRFBServerMessage(client)) break;
          const auto elapsed = std::chrono::steady_clock::now() - begun;
          if (elapsed > std::chrono::milliseconds(250) && client->appData.qualityLevel > 2) {
            --client->appData.qualityLevel; fastFrames = 0;
            if (!SetFormatAndEncodings(client)) break;
          } else if (elapsed < std::chrono::milliseconds(50) && ++fastFrames >= 30 && client->appData.qualityLevel < 6) {
            ++client->appData.qualityLevel; fastFrames = 0;
            if (!SetFormatAndEncodings(client)) break;
          }
        }
      }
    }
    s->running = false; s->connected = false; s->drain();
    { std::lock_guard<std::mutex> guard(s->socketMutex);
      s->fd = -1;
      rfbClientCleanup(client); s->client = nullptr;
    }
    s->notify(workerEnv, 4, s->error);
    current = nullptr;
    vm->DetachCurrentThread();
  });
  return id;
}
void surface(JNIEnv* env, jobject, jlong id, jobject target) {
  auto s = lookup(id); if (!s) return;
  auto* window = target ? ANativeWindow_fromSurface(env, target) : nullptr;
  std::lock_guard<std::mutex> guard(s->surfaceMutex);
  if (s->window) ANativeWindow_release(s->window);
  s->window = window;
}
jint command(JNIEnv* env, jobject, jlong id, jint kind, jint a, jint b, jint c, jint expectedWidth, jint expectedHeight, jbyteArray bytes, jlong generation) {
  auto s = lookup(id); if (!s || !s->connected || !s->running) return 0;
  auto operation = std::make_shared<Command>();
  operation->kind = kind; operation->a = a; operation->b = b; operation->c = c;
  operation->expectedWidth = expectedWidth; operation->expectedHeight = expectedHeight;
  operation->generation = generation;
  if (bytes) {
    const auto size = env->GetArrayLength(bytes);
    if (size > 1048576) return 0;
    operation->text.resize(size);
    env->GetByteArrayRegion(bytes, 0, size, reinterpret_cast<jbyte*>(operation->text.data()));
  }
  auto result = operation->result.get_future();
  { std::lock_guard<std::mutex> guard(s->queueMutex);
    if (s->queue.size() >= 32 || !s->running) return 0;
    s->queue.push_back(operation);
  }
  if (result.wait_for(std::chrono::seconds(5)) == std::future_status::ready) return result.get();
  int queued = 0;
  return operation->stage.compare_exchange_strong(queued, 3) ? 0 : 2;
}
void inputEpoch(JNIEnv*, jobject, jlong id, jlong generation) {
  auto s = lookup(id); if (!s) return;
  if (s->inputGeneration.exchange(generation) == generation) return;
  // Queue the release atomically with the fence, before any new-generation
  // gesture can be queued. A delayed Java coroutine cannot release a new drag.
  auto release = std::make_shared<Command>(); release->kind = 5;
  std::lock_guard<std::mutex> guard(s->queueMutex);
  for (auto it = s->queue.begin(); it != s->queue.end();) {
    if ((*it)->kind == 0 || (*it)->kind == 5) {
      (*it)->stage = 3; (*it)->result.set_value(0); it = s->queue.erase(it);
    } else ++it;
  }
  s->queue.push_front(release);
}
jboolean copyBitmap(JNIEnv* env, jobject, jlong id, jobject bitmap) {
  auto s = lookup(id); if (!s || !s->running || !s->connected) return JNI_FALSE;
  std::lock_guard<std::mutex> guard(s->pixelsMutex);
  AndroidBitmapInfo info{};
  if (!s->hasFrame || AndroidBitmap_getInfo(env, bitmap, &info) != ANDROID_BITMAP_RESULT_SUCCESS ||
      info.format != ANDROID_BITMAP_FORMAT_RGBA_8888 || info.width != static_cast<uint32_t>(s->width) ||
      info.height != static_cast<uint32_t>(s->height) || info.stride < info.width * 4 || info.stride % 4 != 0) return JNI_FALSE;
  void* target = nullptr;
  if (AndroidBitmap_lockPixels(env, bitmap, &target) != ANDROID_BITMAP_RESULT_SUCCESS) return JNI_FALSE;
  const auto* source = reinterpret_cast<const uint32_t*>(s->pixels.data());
  for (uint32_t y = 0; y < info.height; ++y) {
    auto* row = reinterpret_cast<uint32_t*>(static_cast<uint8_t*>(target) + static_cast<size_t>(y) * info.stride);
    for (uint32_t x = 0; x < info.width; ++x) row[x] = source[static_cast<size_t>(y) * info.width + x] | 0xff000000u;
  }
  return AndroidBitmap_unlockPixels(env, bitmap) == ANDROID_BITMAP_RESULT_SUCCESS ? JNI_TRUE : JNI_FALSE;
}
void stop(JNIEnv* env, jobject, jlong id) {
  auto s = lookup(id); if (!s) return;
  { std::lock_guard<std::mutex> guard(registryMutex); sessions.erase(id); }
  s->running = false;
  { std::lock_guard<std::mutex> guard(s->socketMutex);
    const int fd = s->fd.load(); if (fd >= 0) shutdown(fd, SHUT_RDWR);
  }
  if (s->worker.joinable()) s->worker.join();
  { std::lock_guard<std::mutex> guard(s->surfaceMutex);
    if (s->window) { ANativeWindow_release(s->window); s->window = nullptr; }
  }
  env->DeleteGlobalRef(s->callback);
}
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* machine, void*) {
  vm = machine;
  JNIEnv* env = nullptr;
  if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) return JNI_ERR;
  const JNINativeMethod methods[] = {
    {const_cast<char*>("nativeStart"), const_cast<char*>("(Ljava/lang/String;I[B)J"), reinterpret_cast<void*>(start)},
    {const_cast<char*>("nativeSurface"), const_cast<char*>("(JLandroid/view/Surface;)V"), reinterpret_cast<void*>(surface)},
    {const_cast<char*>("nativeCommand"), const_cast<char*>("(JIIIIII[BJ)I"), reinterpret_cast<void*>(command)},
    {const_cast<char*>("nativeInputEpoch"), const_cast<char*>("(JJ)V"), reinterpret_cast<void*>(inputEpoch)},
    {const_cast<char*>("nativeCopyBitmap"), const_cast<char*>("(JLandroid/graphics/Bitmap;)Z"), reinterpret_cast<void*>(copyBitmap)},
    {const_cast<char*>("nativeStop"), const_cast<char*>("(J)V"), reinterpret_cast<void*>(stop)},
  };
  auto cls = env->FindClass("dev/tvvnc/tv_vnc/core/VncBridge");
  if (!cls || env->RegisterNatives(cls, methods, sizeof(methods) / sizeof(methods[0])) != JNI_OK) return JNI_ERR;
  rfbClientLog = libraryLog; rfbClientErr = libraryLog;
  return JNI_VERSION_1_6;
}
