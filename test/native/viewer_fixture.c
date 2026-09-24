/* Local-only technical test peer using the real upstream RFB server. No TV
 * traffic, cloud, or data from a user's device is involved. */
#include <rfb/rfb.h>
#include <rfb/keysym.h>
#include <arpa/inet.h>
#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

static volatile sig_atomic_t running = 1;
static unsigned int sequence = 0;
static uintptr_t next_client = 0;
static void stop(int signal_number) { (void)signal_number; running = 0; }
static void paint(rfbScreenInfoPtr screen) {
  uint8_t* pixels = (uint8_t*)screen->frameBuffer;
  for (int y = 0; y < screen->height; ++y) for (int x = 0; x < screen->width; ++x) {
    int p = (y * screen->width + x) * 4;
    pixels[p] = (x * 255 / screen->width + sequence * 13) % 256;
    pixels[p + 1] = y * 255 / screen->height;
    pixels[p + 2] = ((x / 80 + y / 80) % 2) ? 192 : 32;
    pixels[p + 3] = 0;
  }
  rfbMarkRectAsModified(screen, 0, 0, screen->width, screen->height);
}
static void key(rfbBool down, rfbKeySym code, rfbClientPtr client) {
  if (down) { ++sequence; paint(client->screen); }
  printf("KEY client=%lu direction=%s unicode=%s sequence=%u\n", (unsigned long)(uintptr_t)client->clientData, down ? "down" : "up", code >= 0x01000000 ? "yes" : "no", sequence);
  fflush(stdout);
}
static void pointer(int mask, int x, int y, rfbClientPtr client) {
  if (mask & 1) { ++sequence; paint(client->screen); }
  printf("POINTER client=%lu buttons=%d x=%d y=%d sequence=%u\n", (unsigned long)(uintptr_t)client->clientData, mask, x, y, sequence); fflush(stdout);
}
static void disconnected(rfbClientPtr client) {
  printf("CLIENT_DISCONNECTED id=%lu\n", (unsigned long)(uintptr_t)client->clientData); fflush(stdout);
}
static enum rfbNewClientAction connected(rfbClientPtr client) {
  client->clientData = (void*)++next_client;
  client->clientGoneHook = disconnected;
  printf("CLIENT_CONNECTED id=%lu\n", (unsigned long)(uintptr_t)client->clientData);
  fflush(stdout); return RFB_CLIENT_ACCEPT;
}
int main(int argc, char** argv) {
  const int width = argc > 1 ? atoi(argv[1]) : 1280;
  const int height = argc > 2 ? atoi(argv[2]) : 720;
  if (width < 16 || width > 4096 || height < 16 || height > 2160) return 3;
  argc = 1;
  rfbScreenInfoPtr screen = rfbGetScreen(&argc, argv, width, height, 8, 3, 4);
  if (!screen) return 1;
  screen->listenInterface = htonl(INADDR_LOOPBACK);
  screen->port = 15900; screen->ipv6port = -1;
  screen->desktopName = "TV Console protocol test";
  screen->frameBuffer = calloc((size_t)width * height, 4);
  if (!screen->frameBuffer) return 2;
  /* Deliberately synthetic, non-user credential for testing type-2 auth. */
  static char* passwords[] = { "viewer-test", NULL };
  screen->authPasswdData = passwords;
  screen->passwordCheck = rfbCheckPasswordByList;
  screen->authPasswdFirstViewOnly = 1;
  screen->alwaysShared = TRUE;
  screen->kbdAddEvent = key; screen->ptrAddEvent = pointer; screen->newClientHook = connected;
  signal(SIGINT, stop); signal(SIGTERM, stop);
  paint(screen); rfbInitServer(screen);
  puts("READY 127.0.0.1:15900"); fflush(stdout);
  while (running && rfbIsActive(screen)) rfbProcessEvents(screen, 20000);
  rfbShutdownServer(screen, TRUE);
  free(screen->frameBuffer); screen->frameBuffer = NULL;
  rfbScreenCleanup(screen);
  return 0;
}
