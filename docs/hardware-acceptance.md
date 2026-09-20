# Hardware acceptance — not completed

The reference television is the Sony KD-55AF8. The controller phone/tablet model,
OS version, droidVNC-NG version, capture mode and TV firmware must be recorded
before the performance run. The current Android 15 Pixel 6 AVD (4096 MB, two
cores, software GPU) is a protocol/UI integration environment, not a replacement
for that fixed physical controller.

## Required real-path checks

- [ ] Pair Android Remote in the phone app; reconnect without another PIN.
- [ ] Verify certificate changes require deliberate re-pairing.
- [ ] View the existing droidVNC-NG session using this app and its actual password.
- [ ] Coexist with the existing VNC app without evicting it.
- [ ] Test D-pad, OK, Home, Back and genuine Home/OK/direction/volume holds.
- [ ] Exercise the useful Sony button families, including options, guide, info,
      numbers, colors, captions/audio and media/CEC controls.
- [ ] Switch directly among the detected HDMI inputs and confirm reported state.
- [ ] Test volume, mute/unmute and available absolute controls.
- [ ] Read the protected app list; launch discovered apps and valid deep links.
- [ ] During explicitly confirmed Sony PIN registration, observe whether the
      requested Wake-on-LAN option changes a persistent TV/standby setting.
- [ ] Type, paste, edit and erase non-Latin text/emoji in real TV fields.
- [ ] Check stale focus, private drafts, target switching and backgrounding.
- [ ] Negotiate voice; when supported, test real microphone audio and release.
- [ ] Wake from standby with one Power On action and observe layered recovery.
- [ ] Confirm deliberate Off and Disconnect are not undone by retry loops.
- [ ] Drop VNC while native control works, then drop native control while Sony
      works; reconnect each independently.
- [ ] Exercise phone network changes and runtime permission denial/revocation.
- [ ] Verify diagnostics show real state and export no credentials/keys/text.
- [ ] Confirm unprotected capture; check HDMI capture separately; record DRM
      behavior without bypassing protections.
- [ ] Run app/input shortcuts, cancel them manually, and inspect intermediate
      effects after an unconfirmed step.
- [ ] Verify saved favorites, recents and customized layouts after app restart.
- [ ] Inspect portrait/landscape, light/dark, large text, screen-reader use,
      keyboard-open, empty, populated and degraded states in the rendered app.
- [ ] Complete independent technical and product audits against this evidence.

No required failure is converted to a pass by relabelling it unsupported. A real
platform limit requires independent evidence and an explicit limitation.

## Timing protocol

With this app as the sole VNC client, 720p Tight/JPEG and unloaded LAN RTT no more
than 20 ms, measure both displays using an independent capture/counter method
over 100 transitions. Targets: median TV-to-viewer delay no more than 250 ms,
p95 no more than 500 ms; phone button-to-socket dispatch p95 no more than 50 ms
while viewing. Accessibility capture fallback is a separate measurement.

Record the controller and conditions before running. Do not replace a failing
controller with a faster one and present that as the original result. Non-Sony
interoperability and newer-TV capture-consent cases need their own evidence
before those combinations are claimed tested.
