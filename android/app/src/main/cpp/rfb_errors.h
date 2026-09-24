#pragma once
#include <string_view>

// Inspect only the library's format string, never interpolated server payloads.
// The handshake regression invokes the pinned upstream logger, so upstream
// wording drift is detected rather than asserted from a duplicated fixture.
inline int rfbErrorCategory(std::string_view format, bool authenticationPending = false) {
  if (format.find("authentication failed") != std::string_view::npos ||
      format.find("password required") != std::string_view::npos) return 2;
  // RFB 3.8's rfbVncAuthFailed path reports ReadReason rather than the older
  // fixed authentication message. The same format is also used before security
  // negotiation, so it is an auth failure only after GetPassword and before OK.
  if (authenticationPending && format.find("VNC connection failed") != std::string_view::npos) return 2;
  if (format.find("out of bounds") != std::string_view::npos ||
      format.find("Unknown rect encoding") != std::string_view::npos ||
      format.find("Rect too large") != std::string_view::npos) return 3;
  if (format.find("Connection timed out") != std::string_view::npos) return 6;
  return 0;
}
