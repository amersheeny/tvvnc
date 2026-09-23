# Development notes

## Build availability

This is a maintainer build, not yet a reproducible public-clone release. Two
native submodule URLs still point to local development repositories. They must
be replaced by fetchable, reviewed fork commits before a new checkout can build.
Do not substitute unmodified upstream commits: the maintained forks contain
Android Remote integration and VNC socket-read changes used by this app.

Track source publication, signing and acceptance in
[the release checklist](https://github.com/amersheeny/tvvnc/issues/1).

## Toolchain and native sources

The committed configuration currently specifies:

- Flutter with a Dart SDK satisfying `^3.13.2` in the package configuration.
- Android controller minimum API 26; compile/target API 37.
- Android Gradle plugin 9.4.1, Kotlin 2.4.20 and Gradle wrapper 9.7.1.
- Android NDK `30.0.15729638` and CMake `4.1.2`.
- The recorded builds use JDK 21.

These are build inputs, not a requirement that the television run the same
Android version as the controller.

| Source | Integration |
| --- | --- |
| `native/androidtv-remote` | Maintained ScreenCast-derived Android Remote library, included by Gradle; its `protocol-schemas` submodule supplies the pinned androidtvremote2 schemas. |
| `native/libvncserver` | Maintained LibVNCClient fork with partial-buffer readiness and cumulative idle-timeout fixes; called through JNI. |
| `native/libjpeg-turbo` | Pinned JPEG implementation used by the native viewer. |
| `pigeons/tv_api.dart` | Typed Flutter/native bridge definition; regenerate both sides together. |

No TV address, password, installed app list or MAC is compiled into the product.
Flutter is the UI layer; command routing, TLS/protobuf, Sony networking, audio
capture and VNC decoding use the native components where appropriate.

## Building an existing maintainer checkout

The placeholders below must be replaced with absolute paths on your machine.
This procedure assumes the local native forks are already available; it does
not solve the public-submodule publication blocker above.

```sh
TVVNC_CHECKOUT=/absolute/path/to/tvvnc
TVVNC_ANDROID_SDK=/absolute/path/to/android-sdk
TVVNC_JDK=/absolute/path/to/jdk-21

cd "$TVVNC_CHECKOUT"
git submodule update --init --recursive
git submodule status --recursive
git ls-tree HEAD native/androidtv-remote native/libvncserver native/libjpeg-turbo
git -C "$TVVNC_CHECKOUT/native/androidtv-remote" rev-parse HEAD
git -C "$TVVNC_CHECKOUT/native/androidtv-remote" status --porcelain
git -C "$TVVNC_CHECKOUT/native/libvncserver" rev-parse HEAD
git -C "$TVVNC_CHECKOUT/native/libvncserver" status --porcelain

flutter pub get
dart run pigeon --input "$TVVNC_CHECKOUT/pigeons/tv_api.dart"
env ANDROID_HOME="$TVVNC_ANDROID_SDK" JAVA_HOME="$TVVNC_JDK" \
  flutter build apk --debug --target-platform android-arm64
```

Compare each dependency's HEAD with its recorded gitlink and check its working
tree before attributing a build to a source revision. Keep the command output
with that build's evidence. These are reporting steps, not an installed hook.

The ARM64 debug APK is written to
`$TVVNC_CHECKOUT/build/app/outputs/flutter-apk/app-debug.apk`. Omit the target
platform option when preparing the normal multi-ABI debug artifact.

**Release signing is not configured yet.** The current Gradle release build
still uses a debug signing key. A successful `--release` build is not a
Play-ready artifact, and the user's installed app must not be uninstalled to
work around a signing mismatch.

## Checks

From the same configured checkout:

```sh
flutter analyze
flutter test
env ANDROID_HOME="$TVVNC_ANDROID_SDK" JAVA_HOME="$TVVNC_JDK" \
  "$TVVNC_CHECKOUT/android/gradlew" -p "$TVVNC_CHECKOUT/android" :app:testDebugUnitTest
```

The repository also contains native decoder/security tests, Android ART probes
for the minified protocol classes, and device-driven flows. Run the real paths
changed by a patch; a protocol fixture is not evidence that an untested TV
supports voice, panel wake, HDMI capture or a particular app's editor.

The [local protocol fixture](../test/native/README.md) can exercise native
pairing/editor behaviour without sending commands to a real television. Real
support reports should include TV/controller models, OS and service versions,
capture mode and transport state, with credentials and personal text removed.

## Protocol and implementation details

- Native Android taps use SHORT and supported holds use START_LONG/END_LONG.
  The router keeps a key release on the transport that received the press.
  Sony IRCC-only controls do not pretend to offer native hold semantics.
- VNC clipboard transfer and a TV paste request are distinct. Delivery to a
  socket is not proof that an editor accepted the text. droidVNC-NG clipboard
  and UI-thread ordering must not be treated as an insertion acknowledgement.
- Voice capture selects an available PCM16 mono capture rate and sends 8 kHz
  audio in bounded chunks without saving it. Negotiated support and microphone
  permission are required. Granting permission does not itself start recording;
  another deliberate hold is required. The TV assistant's own network use is
  unchanged.
- Screen and control sessions have independent lifecycles. Backgrounding closes
  sessions and stops input. Explicit Disconnect clears reconnect intent;
  explicit TV Off has a separate no-wake intent. Power-on readiness uses observed
  state, and an unknown power result is not proof that a panel entered standby.
- Shortcuts stop on cancellation or an unconfirmed required step. Earlier
  steps may already have taken effect. Deleting a shortcut offers Undo tied to
  the original TV; Undo must not recreate a forgotten TV. Dismiss does not undo.
- Normal drafts are in-memory and scoped by TV/application. Protected drafts
  do not enter that cache or the TV clipboard. Revealing a TV-declared password,
  clearing it and typing again do not remove its declared sensitivity.
- The viewer quality controller adapts within levels 2–6 using end-to-end
  message-processing time, including network waiting. This is not a CPU-only
  decode benchmark or a measured latency guarantee.
- The framebuffer limit is 16,777,216 pixels. At four bytes per pixel, a full
  framebuffer and one snapshot occupy `2 × 16,777,216 × 4 = 128 MiB`, before
  encoder work and other app allocations. A snapshot copies directly into an
  Android bitmap; decoding still waits during that copy.
- Capture can be unavailable or protected while control remains possible. The
  viewing-source interface is separate from command routing so a future private
  external feed need not replace the remote-control layer. There is no external
  HDMI feed, smart-plug recovery or TV companion integration in this phase.

## Package identity and older test builds

The display name is **TV VNC**, application ID `com.asheeny.tvvnc`. Some early
development artifacts use the name TV Console.

The older `dev.tvvnc.tv_vnc` test application is a different Android package.
Android does not automatically transfer its saved TVs or Keystore credentials
to `com.asheeny.tvvnc`; keep the old installation until the new setup is complete.
Updates within the current package must preserve app data and pairing.
