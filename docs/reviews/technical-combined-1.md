Audit complete. Writing the combined pass.

---

# Combined pass — frozen Phase 0 artifact

## Dominant risk

**One defect in the release build configuration disables the app's primary control transport, and no artifact in the evidence set could have caught it.** Release builds are minified; the generated Android TV Remote protocol messages are protobuf-lite classes whose runtime resolves fields reflectively by name; and the only keep rule in the project covers a different class. Every piece of protocol evidence gathered so far runs either on the JVM (39 library tests, 26 app tests — no shrinking) or against a VNC fixture in the release app (which exercises no protobuf). So the one build that would ship has never executed a single Android TV Remote message. Everything else I examined in this pass is in good order, and several resolutions are stronger than what I asked for.

## Resolution verification — all eight technical items and all seven socket-plan items

**T1 power intent — VERIFIED.** `PowerObservation.kt` is a 16-line pure helper whose `isOn`/`isStandby` both return the Android service state only when the panel observation is absent, and neither infers standby from absence. Three `PowerObservationTest` cases pass. The shared-predicate reach correction I asked for is satisfied by the helper existing as one object both callers use.

**T2 authentication classification — VERIFIED, and the fix found something my correction would have missed.** `rfb_errors.h` is shared between the app and the regression, exactly as I asked, and the real handshake exposed that RFB 3.8's failure path logs `"VNC connection failed"` rather than the older fixed message — so the classifier gained an `authenticationPending` gate scoped between `GetPassword` and the OK result. My proposed test would never have revealed that, because it fed back the literal the classifier already searched for. `review-native-sanitizers.log` records `PASS actual upstream type-2 accepted/rejected handshake classification`.

**T3 screenshot memory — VERIFIED.** `copyBitmap` in `vnc_bridge.cpp` validates `hasFrame`, `AndroidBitmap_getInfo` success, `format == ANDROID_BITMAP_FORMAT_RGBA_8888`, exact width and height against the live framebuffer, `stride >= width * 4` and four-byte stride alignment, all under `pixelsMutex`, before locking; it copies row-by-row honouring stride, sets alpha opaque, and returns the unlock result. `jnigraphics` is linked at `CMakeLists.txt:44`. The Java byte array and its intermediate vector are both gone. My chunking proposal was the weaker fix and this supersedes it correctly.

**T4 diagnostic seam — VERIFIED.** `DiagnosticSink` with `RemoteDiagnostic.TLS_CONNECTED` and `SERVER_IDENTITY_OBSERVED`, threaded per-instance through `AndroidTvSocketFactory`, `NativePairing` and `NativeRemoteSession`, defaulting to `DiagnosticSink.NONE`. The two former interpolated strings carrying host and certificate fingerprint are gone. My own `(String) -> Unit` suggestion would have reintroduced that leak; this design does not.

**T5 Wake-on-LAN disclosure — VERIFIED in the ledger and copy artifacts.** Confirmation precedes `actRegister`, with no claim that a persistent setting changes, and the physical observation is on the hardware checklist.

**T6 configuration cache — VERIFIED.** `configuration-final-problems.json` records `"requestedTasks": ":androidtv-remote:androidtv-remote:generateRemoteMessages"` with `"totalProblemCount": 14`, and all fourteen diagnostics are Kotlin deprecation, unchecked-cast and always-true warnings attributed to `:gradle:compileKotlin` — the Flutter tooling build, not the generation task and not configuration-cache incompatibility. The store and reuse logs pair with it. The evidence gap I raised is closed.

**T7 storage error categories — VERIFIED, and broader than I asked.** `ProfileStore.kt` wraps every storage operation with `catch (error: LocalRequestError) { throw error }`, `catch (error: IdentityStorageException) { throw LocalRequestError(error.code) }`, `catch (_: Exception) { throw LocalRequestError("secure_storage_failed") }`, plus specific codes for `credential_storage_invalid`, `credential_storage_failed`, `profile_storage_failed` and `profile_missing`. `IdentityStorageException` overrides `toString()` to return only its code. No raw platform exception message can leave the storage layer. My withdrawn key-invalidation claim stays withdrawn and the decision not to ship "cannot be recovered" copy is right.

**T8 pinned inputs — VERIFIED as reconciled.** Manual proof, no gate installed, consistent with my withdrawal of that demand.

**G1 through G7 and the socket repair — VERIFIED in source and in a run.** The `sockets.c` delta extracts `WaitForSocket`, leaves `WaitForMessage`'s replay and buffered fast paths intact ahead of it, initialises `remainingWait` from `readTimeout` at function entry, charges only the measured monotonic time around the wait, never resets on progress, caps each wait at the smaller of the remainder and 100 ms, treats zero timeout as unlimited, and returns failure — not process termination — on clock failure or an invalid descriptor. `libvnc-reader-final.log` is the strongest single artifact in this review:

```
fragmented bytes=2 pieces=2 accepted=1 elapsed_ms=58
fragmented bytes=20 pieces=20 accepted=1 elapsed_ms=504
fragmented bytes=307200 pieces=20 accepted=1 elapsed_ms=541
fragmented bytes=80 pieces=80 accepted=0 elapsed_ms=1003
fragmented bytes=2 pieces=2 accepted=1 elapsed_ms=1109
```

The original reproduction now succeeds in 58 ms rather than failing at 0 ms; the large branch at 307,200 bytes is covered; the cumulative-overflow case I asked for fails at **1003 ms** against a one-second budget, which is the precise number that distinguishes cumulative idle accounting from reset-on-progress; and the zero-timeout case waits 1109 ms and still succeeds. `CHECK` rather than `assert` keeps these active under release compilation. Every item I raised in G1 and G3 is implemented and demonstrated.

## Findings

### 1 — Generated protocol messages are not kept under release minification, so the Android TV Remote transport cannot work in a release build

- **LOCATION:** `android/app/proguard-rules.pro` (whole file); `androidtv-remote/build.gradle.kts` (no `consumerProguardFiles`)
- **ORIGIN:** introduced by this change set — app commit `4cd3396`, with the protobuf dependency introduced at library commit `687a3be`
- **TRIGGER:** Run the release APK and pair with, or send any command to, an Android TV over the v2 protocol. The first parse or serialize of any generated message.
- **EXPECTED:** Messages encode and decode as they do in debug and in the 39 JVM library tests.
- **ACTUAL:** Release builds are minified — `FlutterPluginUtils.shouldShrinkResources` returns `true` by default and `FlutterPlugin.kt` then sets `releaseBuildType.isMinifyEnabled = true`. The generated `Remotemessage.java` references `GeneratedMessageLite` 337 times and carries 49 distinct field-name strings (`"sessionId_"`, `"appLink_"`, `"direction_"`, `"counterField_"`, …) that the lite runtime resolves reflectively. protobuf's own documentation states the lite runtime "internally uses reflection to avoid generating hashCode/equals/parse/serialize methods", that obfuscating field names breaks it with `java.lang.RuntimeException: Field {NAME}_ for {CLASS} not found`, and prescribes one keep rule. The `protobuf-javalite:4.36.2` artifact is a plain JAR containing zero `META-INF/proguard` entries, so it ships no consumer rules; the library module declares no `consumerProguardFiles`; and the app's entire rule file is the single line `-keep class dev.tvvnc.tv_vnc.core.VncBridge { *; }`. Nothing keeps the message classes. Pairing, key injection, holds, text, voice and app launch all fail.
- **WHY NO EVIDENCE CAUGHT IT:** the 39 library and 26 app tests run on the JVM with no shrinking, and the only release-build exercise is the VNC fixture flow, which sends no protobuf. This defect is invisible to every artifact in the set.
- **SEVERITY:** blocker
- **MINIMAL CORRECTION:** add a consumer rule in the module that owns the dependency — a one-line `androidtv-remote/consumer-rules.pro` containing `-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }`, referenced by `consumerProguardFiles("consumer-rules.pro")` in that module's `defaultConfig`. That fixes every consumer rather than only this app. Then add one release-build check that a generated message round-trips, so the gap that hid this cannot reopen; while doing so, confirm the keep-rule situation of the other minified dependencies rather than protobuf alone.

### 2 — Saved shortcuts depend on enum constant names surviving minification

- **LOCATION:** `android/app/src/main/kotlin/dev/tvvnc/tv_vnc/core/ProfileStore.kt:102` reading, and the matching `.put("action", s.action.name)` on the save path
- **ORIGIN:** introduced by this change set, app commit `4cd3396`
- **TRIGGER:** An app update in which R8 produces a different name mapping than the build that wrote the stored shortcuts.
- **EXPECTED:** Saved shortcuts load after an update.
- **ACTUAL:** Shortcut steps are persisted to JSON by enum constant name and read back with `MacroAction.entries.first { it.name == step.getString("action") }`. `first` throws `NoSuchElementException` when nothing matches, and that propagates out of `read`, which `list()` calls for every profile — so one unreadable shortcut makes the whole saved-TV list fail rather than degrading that one entry. Scoped honestly: I did **not** establish that R8 renames these constants. The default optimize configuration keeps `values()` and `valueOf(String)` for all enums, and keeping `valueOf` may force the names to be retained. What I did establish is that stored user data depends on compiler output with nothing guarding it, in the same defect class as finding 1.
- **SEVERITY:** minor
- **MINIMAL CORRECTION:** keep the enum alongside the protobuf rule — `-keepclassmembers enum dev.tvvnc.tv_vnc.bridge.MacroAction { *; }` — which costs one line in the edit already required, and make `read` tolerate an unknown action for one shortcut without failing the whole profile list.

## Verdict by criterion

**Resolution completeness — CLEAN.** All eight technical findings and all seven socket-plan items are implemented and, where runnable, demonstrated. Four resolutions are better than the corrections I proposed: T2 found the real RFB 3.8 log path, T3 removed the allocation that actually set the peak, T4 avoided the fingerprint leak my sink design would have reintroduced, and G3 identified the event-count defect I had only asked for a test about.

**Memory safety and native bounds — CLEAN.** The Bitmap copy validates format, exact dimensions, stride floor and stride alignment before locking and always reports the unlock result; the framebuffer cap, command queue bound and clipboard bound are unchanged; sanitizers pass all three advisory guards plus the raw positive control and the out-of-frame rejection.

**Socket accounting — CLEAN.** Verified in source and by a run whose numbers match the specification exactly.

**Network confinement — CLEAN.** `BoundedHttp` builds its client with `Proxy.NO_PROXY`, `followRedirects(false)`, `followSslRedirects(false)`, `retryOnConnectionFailure(false)`, `fastFallback(false)`, all four timeouts including an eight-second whole-call deadline, a one-shot request body, DNS pinned to the already-validated address, a socket factory pinned to that address and port, and cancellation wired to `call.cancel()`. Normal certificate and hostname verification is retained. Four `BoundedHttpTest` cases pass.

**Credential and secret handling — CLEAN.** Storage exceptions are sanitized at source with a catch-all; identity exceptions carry codes only and override `toString()`; the diagnostic sink carries no strings; application logging is category tokens only.

**Delivery certainty — CLEAN.** The native write deadline uses an atomic completion gate so only one of the writer and the timer wins, and closes the captured peer only, so an expired deadline cannot close a replacement socket.

**Permission model and manifest surface — CLEAN.** Six permissions, all used; `NEARBY_WIFI_DEVICES` carries `neverForLocation`; one exported activity; a scoped `queries` element.

**Licensing and attribution — CLEAN.** `TVCONSOLE_CHANGES.md` marks the LibVNCServer modification against its base commit, retains GPL-2.0-or-later, states the validated platforms and explicitly disclaims Windows, TLS and SASL runtime validation, and records that a local filesystem URL is not a publishable dependency.

**Build and dependency wiring — DEFECTIVE.** Findings 1 and 2. The configuration-cache evidence, the pinned inputs and the toolchain alignment are all sound; the shrinking configuration is not.

**Test and oracle quality — CLEAN, with the release gap that finding 1 names.** 39 + 26 + 29 tests, zero failures, verified from result XML rather than exit codes; the socket regression asserts timing in both directions; the sanitizer harness retains its positive control.

**Over-engineering — CLEAN.** Nothing added exceeds its requirement; the Bitmap path replaced code of similar size rather than adding a layer.

**Completeness of this pass.** I read the LibVNCClient delta in full, the library delta's security-relevant code in full, the resolution ledger, every fresh evidence artifact named, and the app's changed native, storage, power, network and build surfaces. My coverage of the eleven Dart interface files was targeted rather than exhaustive; those carry a separate reviewer and fourteen separately resolved findings. This establishes that the scoped artifact was inspected and every criterion reported — not that no undiscovered defect remains.

## Open items that are not code defects

These remain open by your statement and my inspection, and none is counted as a finding: no real television has been reached, so the entire Sony acceptance checklist is unproven; the final rendered-UI captures are **in progress** — the six flow logs contain step-level `COMPLETED` lines but no flow verdict of any kind, so I claim nothing about them, and the set was still growing while I read it; the release APK is signed with debug keys; the copy gate remains unapplied pending your exact-diff approval; and both dependency forks still need publicly fetchable URLs before any open-source release.

**No receipt.** One blocking finding.

AUDIT COMPLETE: 2 findings (1 blocking)
