#include <rfb/rfbclient.h>
#include <minilzo.h>
#include <zlib.h>
#include <sys/socket.h>
#include <unistd.h>
#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <thread>
#include <chrono>
#include <fcntl.h>
#include "../../android/app/src/main/cpp/rfb_errors.h"

using Bytes = std::vector<unsigned char>;
static int authCategory = 0;
static bool authPending = false;
static void classifiedLog(const char* format, ...) {
  if (std::strstr(format, "VNC authentication succeeded")) authPending = false;
  if (const auto code = rfbErrorCategory(format, authPending)) authCategory = code;
}
static char* testPassword(rfbClient*) { authPending = true; return strdup("synthetic"); }
void u16(Bytes& b, unsigned v) { b.push_back(v >> 8); b.push_back(v); }
void u32(Bytes& b, unsigned v) { for (int s = 24; s >= 0; s -= 8) b.push_back(v >> s); }
Bytes update(unsigned x, unsigned y, unsigned w, unsigned h, unsigned encoding) {
  Bytes b{0, 0, 0, 1}; u16(b, x); u16(b, y); u16(b, w); u16(b, h); u32(b, encoding); return b;
}
void compact(Bytes& b, unsigned v) {
  b.push_back((v & 127) | (v > 127 ? 128 : 0));
  if (v > 127) b.push_back(((v >> 7) & 127) | (v > 16383 ? 128 : 0));
  if (v > 16383) b.push_back(v >> 14);
}
bool decode(const Bytes& bytes, int width, int height) {
  int fd[2]; assert(socketpair(AF_UNIX, SOCK_STREAM, 0, fd) == 0);
  auto* client = rfbGetClient(8, 3, 4);
  client->width = width; client->height = height; client->sock = fd[0]; client->readTimeout = 1;
  client->format.bitsPerPixel = 32; client->format.depth = 24; client->format.trueColour = TRUE;
  client->format.redMax = client->format.greenMax = client->format.blueMax = 255;
  client->format.redShift = 0; client->format.greenShift = 8; client->format.blueShift = 16;
  client->frameBuffer = static_cast<uint8_t*>(calloc(width * height, 4));
  assert(write(fd[1], bytes.data(), bytes.size()) == static_cast<ssize_t>(bytes.size()));
  shutdown(fd[1], SHUT_WR);
  const bool accepted = HandleRFBServerMessage(client);
  free(client->frameBuffer); client->frameBuffer = nullptr;
  rfbClientCleanup(client); close(fd[1]); return accepted;
}
Bytes ultra(const Bytes& raw) {
  Bytes compressed(raw.size() + raw.size() / 16 + 64 + 3);
  std::vector<lzo_align_t> work((LZO1X_1_MEM_COMPRESS + sizeof(lzo_align_t) - 1) / sizeof(lzo_align_t));
  lzo_uint length = compressed.size();
  assert(lzo1x_1_compress(raw.data(), raw.size(), compressed.data(), &length, work.data()) == LZO_E_OK);
  auto b = update(1, raw.size(), 0, 0, rfbEncodingUltraZip); u32(b, length);
  b.insert(b.end(), compressed.begin(), compressed.begin() + length); return b;
}
void authRegression(bool success) {
  int fd[2]; assert(socketpair(AF_UNIX, SOCK_STREAM, 0, fd) == 0);
  Bytes wire{'R','F','B',' ','0','0','3','.','0','0','8','\n',1,2};
  wire.insert(wire.end(), 16, 0); u32(wire, success ? 0 : 1);
  if (success) {
    u16(wire, 1); u16(wire, 1);
    wire.insert(wire.end(), {32,24,0,1});
    u16(wire,255); u16(wire,255); u16(wire,255);
    wire.insert(wire.end(), {0,8,16,0,0,0});
    u32(wire,4); wire.insert(wire.end(), {'t','e','s','t'});
  } else u32(wire, 0);
  assert(write(fd[1], wire.data(), wire.size()) == static_cast<ssize_t>(wire.size()));
  shutdown(fd[1], SHUT_WR);
  auto* client = rfbGetClient(8,3,4);
  client->sock = fd[0]; client->GetPassword = testPassword;
  const auto previousLog = rfbClientLog, previousErr = rfbClientErr;
  rfbClientLog = classifiedLog; rfbClientErr = classifiedLog; authCategory = 0; authPending = false;
  const bool accepted = rfbClientInitialise(client);
  rfbClientLog = previousLog; rfbClientErr = previousErr;
  assert(accepted == success);
  assert(authCategory == (success ? 0 : 2));
  if (success) assert(!authPending);
  free(client->frameBuffer); client->frameBuffer = nullptr;
  rfbClientCleanup(client); close(fd[1]);
}
int main() {
  assert(rfbErrorCategory("VNC connection failed: %s\n", false) == 0);
  authRegression(true); authRegression(false);
  puts("PASS actual upstream type-2 accepted/rejected handshake classification");
  {
    int fd[2]; assert(socketpair(AF_UNIX, SOCK_STREAM, 0, fd) == 0);
    auto* client = rfbGetClient(8, 3, 4);
    client->sock = fd[0]; client->readTimeout = 1;
    assert(fcntl(fd[0], F_SETFL, fcntl(fd[0], F_GETFL) | O_NONBLOCK) == 0);
    assert(write(fd[1], "A", 1) == 1);
    std::thread peer([&] {
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
      assert(write(fd[1], "B", 1) == 1);
    });
    char result[2]{};
    const auto start = std::chrono::steady_clock::now();
    const bool accepted = ReadFromRFBServer(client, result, 2);
    const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - start).count();
    peer.join();
    printf("fragmented read accepted=%d elapsed_ms=%lld\n", accepted, static_cast<long long>(elapsed)); fflush(stdout);
    rfbClientCleanup(client); close(fd[1]);
    assert(accepted && result[0] == 'A' && result[1] == 'B');
    puts("PASS partially buffered read waits for missing socket bytes");
  }
  assert(lzo_init() == LZO_E_OK);
  // Known-good Raw is the positive control: a decoder that rejects every
  // message must not make this regression suite green.
  auto valid = update(0, 0, 2, 1, rfbEncodingRaw);
  valid.insert(valid.end(), {17, 34, 51, 0, 68, 85, 102, 0}); assert(decode(valid, 2, 1));
  puts("PASS raw positive control");

  auto gradient = update(0, 0, 2049, 1, rfbEncodingTight);
  gradient.insert(gradient.end(), {0x40, 0x02}); assert(!decode(gradient, 2049, 1));
  puts("PASS GHSA-jcc5-8wj4-7c58 gradient width guard");

  Bytes twoRows(24, 77), zipped(compressBound(twoRows.size())); uLongf zipLength = zipped.size();
  assert(compress2(zipped.data(), &zipLength, twoRows.data(), twoRows.size(), Z_DEFAULT_COMPRESSION) == Z_OK);
  auto rows = update(0, 0, 4, 1, rfbEncodingTight); rows.push_back(0x01); compact(rows, zipLength);
  rows.insert(rows.end(), zipped.begin(), zipped.begin() + zipLength); assert(!decode(rows, 4, 1));
  puts("PASS GHSA-v9pm-47h4-jcq8 excess decompressed rows guard");

  assert(!decode(ultra(Bytes(4, 0)), 16, 16));
  Bytes rawHeader; u16(rawHeader, 0); u16(rawHeader, 0); u16(rawHeader, 2); u16(rawHeader, 2); u32(rawHeader, rfbEncodingRaw);
  rawHeader.insert(rawHeader.end(), {1, 2, 3, 4}); assert(!decode(ultra(rawHeader), 16, 16));
  puts("PASS GHSA-87q7-v983-qwcj truncated header and raw payload guards");
  auto oversize = update(0, 0, 65535, 65535, rfbEncodingRaw); assert(!decode(oversize, 16, 16));
  puts("PASS out-of-frame rectangle rejection");
}
