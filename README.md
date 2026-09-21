# TV VNC

A local-network Android TV remote console. Flutter supplies the interface;
Android TV Remote v2 and vendor APIs supply native controls; RFB supplies the
screen and pointer. Viewing and control have independent lifecycles.

Phase 0 is **local-network only**. OpenVPN, WireGuard, profile imports and VPN
recovery are outside this phase. Device addresses, passwords, MACs and installed
apps are discovered or configured per device, never compiled into the app.

No analytics, advertising, relay or cloud telemetry. Secrets remain in Android
Keystore-backed storage and are excluded from diagnostic exports.

Android application ID: `com.asheeny.tvvnc`. This is a separate installation
from the early `dev.tvvnc.tv_vnc` test app; Android does not transfer that app's
saved TVs or Keystore credentials automatically. Keep the old installation
until setup of the new one is complete.

## Implementation status

This is an implementation under validation, not a completed hardware-qualified
release. The Android APK builds; native protocol/security tests and local RFB
integration have run. Pairing, actuation, voice, wake and performance on the Sony
reference television remain separate acceptance checks. See the implementation
ledger and hardware checklist in this repository's documentation.

The application has saved-TV setup, a physical-remote layout, all discovered
buttons, touchpad/direct-touch modes, a native viewer, keyboard, inputs, apps,
favorites, shortcuts, layout customization and diagnostics. TV functions are
attempted through a capability router; a viewer failure does not remove native
remote controls. ADB is not a runtime dependency.

## Local development

The current checkout is `/Users/amsh/worktrees/tvVNC/worktree`. The native
control library's source is maintained separately at
`/Users/amsh/worktrees/tvVNC-remote-core/worktree`. The socket-read repair is
maintained at `/Users/amsh/worktrees/tvVNC-libvncserver/worktree`. Both are pinned
through Git submodules with development-only local URLs. Fetchable public
fork URLs are required before a clean-machine open-source release; no public
repository or branch has been published by this task.

```sh
cd /Users/amsh/worktrees/tvVNC/worktree
git submodule update --init --recursive
git submodule status --recursive
git ls-tree HEAD native/androidtv-remote native/libvncserver native/libjpeg-turbo
git -C /Users/amsh/worktrees/tvVNC/worktree/native/androidtv-remote rev-parse HEAD
git -C /Users/amsh/worktrees/tvVNC/worktree/native/androidtv-remote status --porcelain
git -C /Users/amsh/worktrees/tvVNC/worktree/native/libvncserver rev-parse HEAD
git -C /Users/amsh/worktrees/tvVNC/worktree/native/libvncserver status --porcelain
flutter pub get
dart run pigeon --input /Users/amsh/worktrees/tvVNC/worktree/pigeons/tv_api.dart
env ANDROID_HOME=/Users/amsh/Library/Android/sdk flutter build apk --debug --target-platform android-arm64
```

Before gathering build evidence, compare each dependency HEAD to its recorded
gitlink and confirm its working tree is clean. Capture these reporting commands
alongside that build's log. They are not an installed hook or a new build gate.

The debug APK is produced at
`/Users/amsh/worktrees/tvVNC/worktree/build/app/outputs/flutter-apk/app-debug.apk`.
Debug signing is for local development; release signing and publication remain
delivery work. Minimum controller Android version is API 26; target/compile SDK
is 37. No assumption is made about the TV matching the controller's OS version.

## Setup

1. Put the phone and TV on the same private LAN, then find a TV or enter its
   address. Runtime network permission is requested when needed.
2. Enter the existing VNC password and port in the TV's settings. Keep the TV's
   existing droidVNC-NG capture session; this app does not require replacing it.
3. Pair Android TV Remote using the code displayed on the TV. Each saved TV gets
   a non-exportable Android Keystore identity; successful pairing is retained.
4. For Sony-specific controls, enter the TV's pre-shared key, or explicitly start
   PIN registration. Command names, IRCC codes, input URIs and app catalogs come
   from the television, not a hardcoded device list.
5. Store the actual Wi-Fi/Ethernet MAC for Wake-on-LAN, not a Bluetooth MAC. WOL
   remains marked as an untested mechanism until standby-wake is established on
   the hardware. The TV may require its Remote start/network standby settings.

Direct touch must be checked against the TV's displayed picture. Two fingers
pan/zoom locally; a tap sends a balanced pointer press/release. Native Android
holds use START_LONG/END_LONG; taps use SHORT. Sony IRCC-only controls are not
misrepresented as genuine key holds.

Compose text stays local until Send. Live edit is explicit and tied to the TV
editor context. Unconfirmed text stays in the compose bar. Private drafts clear
on backgrounding, editor changes and target changes. VNC clipboard copying is a
separate action from pasting on the TV: a successful socket write is not proof
that the field was edited. Do not assume droidVNC-NG's clipboard/UI-thread
ordering provides an insertion acknowledgement.
Ordinary Compose drafts are retained only in memory, by TV/application, when
leaving the Keyboard or backgrounding. They are never sent automatically or
written to persistent storage. TV editing keys are separate from local draft
actions. Deleting a shortcut offers Undo without recreating a forgotten TV.
Revealing text that was marked private does not make it an ordinary draft:
it remains excluded from the draft cache and TV clipboard, with keyboard
suggestions/learning disabled, until cleared or emptied. Leaving its context
clears it. Undo messages identify the shortcut, original TV and deletion order;
Dismiss closes the current message without restoring its shortcut.

Voice is attempted only when the authenticated service negotiates VOICE. Granting
microphone permission does not start recording; hold again. Audio is PCM16 mono
8 kHz, streamed in bounded chunks and not saved. Recognition is performed by the
TV's existing assistant; its own network behavior is unchanged.

## Safety and limitations

Sessions are foreground-only. Backgrounding closes connections and stops input.
Disconnect suspends retries until Connect; deliberate Turn off preserves a
separate no-wake intent. Power On uses discrete mechanisms and observable
readiness. Shortcuts stop on cancellation or an unconfirmed required step;
earlier steps can already have taken effect.
An unknown power state is not treated as proof of standby after a toggle.

The VNC quality controller measures end-to-end message-processing time, including
network waiting, and adapts its quality level within 2–6. It is not a CPU-only
decode benchmark. The maintained client repair fixes partial-buffer readiness
and cumulative idle timeout accounting, without increasing timeout values.
Screenshots copy directly into an Android bitmap: the maximum framebuffer and
snapshot together occupy 128 MiB, plus encoder working memory and other app
allocations. Decoding still waits during that single copy.

Classic VNC Authentication uses only the first eight password bytes and does not
encrypt screen traffic. Sony HTTP is also a LAN protocol. Destination validation
and redirect refusal confine these connections; they do not turn them into TLS.
Android Remote certificates are pinned. Diagnostic exports exclude passwords,
cookies, private keys, pairing codes, editor contents and framebuffer pixels.
Profile metadata and credentials are encrypted; backup/device-transfer exclusions
cover private app storage. Explicit screenshots are local files; the phone's
separate gallery/backup settings still apply to exported images.

Protected content can be black. Black pixels alone do not prove DRM or a stalled
capture. HDMI capture needs an actual check on the TV; no protection is bypassed.
The viewing interface is separate from command routing so a future private
external feed can be added without replacing native controls.

An unplugged TV, offline router, disconnected network hardware or firmware frozen
before networking cannot be repaired by this software alone. No smart-plug or
hard-power-cycle integration is included in Phase 0. No companion is installed
by this app: a companion is justified only by a demonstrated standard-service
gap, not by avoiding the Sony/Android APIs already available.
