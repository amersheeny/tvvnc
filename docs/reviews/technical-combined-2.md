Audit complete across all three repositories, the full Dart layer, and every evidence artifact.

---

# Combined pass — frozen artifact (app `38bdca0`, remote library `299e142`, LibVNCClient `07280ef5`)

## Dominant risk

**The blocking defect from the previous pass is genuinely fixed, and the remaining exposure has moved into the privacy control on the keyboard screen.** The shrinking failure is resolved at the right layer and proven on the real artifact. Inspecting the Dart layer in full this pass — which the previous pass only sampled — surfaced one defect where the "Private text" toggle writes previously-private text into the ordinary draft cache on the way out of private mode, defeating the control's stated invariant on a one-tap path that no test covers.

## Resolution verification

**F1, protobuf under shrinking — VERIFIED FIXED at the correct layer.** The keep rule is not merely declared; it is packaged. Reading `proguard.txt` out of `androidtv-remote-release.aar` gives the comment plus `-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }`, so every consumer of the library inherits it rather than this one application being patched. The proof is on the real artifact: `release-protobuf-after-corrected.log` names the package by hash `a063af9f…`, matching the current release package, and records `ROUNDTRIP remote.Remotemessage$RemoteMessage fixtures=3` and `ROUNDTRIP com.google.polo.wire.protobuf.PoloProto$OuterMessage fixtures=2`. Both namespaces that previously failed — the one carrying `remoteConfigure_` and the one carrying `protocolVersion_` — now serialize and round-trip. Shrinking remains on. The wildcard form was necessary and was used.

**The harness correction is the right kind of correction.** When the first post-fix probe failed on the empty acknowledgement case, the cause was the probe using strict parsing against a message the service legitimately sends without a required field, not a field lookup. Fixing the harness to call the actual minified production receive path — the merge-and-build-partial route that `NativePairing` and `GeneratedProtocolTest` already use — rather than deleting the case or loosening production behaviour, is repairing the oracle instead of the subject. No additional shrinking rule was added to make a test pass.

**F2, enum names — my withdrawal stands and needed no further action.** Nothing was added and no stored data is dropped.

**The four product corrections are present in source.** Unavailable controls now render through `availabilityHint` with `onSurface` foreground on `surfaceContainerHighest` with an outline and an `info_outline` marker that is both `IgnorePointer` and `ExcludeSemantics`; the whole-control fade is gone and the explanation stays reachable. The keyboard's mode and send ownership is unified behind `modeEpoch`, `sendSequence`/`activeSend`, `changingBuffer` and `replaceBuffer`, with `send` re-checking epoch, target, context and revision before touching state, and a same-context live failure restoring Compose. Each deletion bar names the shortcut, the original television and a monotonically increasing deletion number with an explicit Dismiss control, and each Undo closure owns its exact macro and originating profile with a guard against double-restore. The voice control distinguishes `voiceStarting` from `listening` from `holdToSpeak` in its accessibility value, begins capture on accepted long press rather than raw pointer contact, and stops on cancellation, dispose and explicit action.

## Finding

### 1 — Leaving private mode writes the previously-private text into the ordinary draft cache

- **LOCATION:** `lib/ui/keyboard_page.dart`, the "Private text" `FilterChip` handler (lines 261-270), in combination with `keepCompose` (lines 70-72) and `restoreCompose` (lines 74-78)
- **ORIGIN:** introduced by this change set, app commit `38bdca0`
- **TRIGGER:** Select "Private text", type something sensitive, then deselect "Private text" without first clearing the field — the ordinary gesture for revealing what you just typed.
- **EXPECTED:** Text entered under the privacy control never enters the draft cache. The plan requires masking and clearing user-marked sensitive input, and the resolution ledger states the invariant directly: "Private drafts never enter that cache."
- **ACTUAL:** The handler runs `invalidateMode()`, then `if (value) widget.model.clearDraft(draftContext)` — which only clears when switching *into* private mode — then `setState(() => private = value)`, then `keepCompose()`. Because `private` has already become `false` by the time `keepCompose` runs, its guard `if (!private && !live)` passes and it calls `rememberDraft(draftContext, text.value)` with the text typed while private was active. The text controller is owned by the page, not the field, so the `key: ValueKey(private)` remount does not clear it. The cached value is then restored into a visible, non-obscured field by `restoreCompose()` on the next context change, target change or return from background, and persists in memory keyed by television and application until the profile is forgotten or the model is disposed.
- **SCOPE, stated plainly:** this cache is a Dart-side in-memory map. The text is not written to disk, does not reach the encrypted profile store, and never leaves the device. The defect is that an explicit privacy affordance is defeated and a written invariant is violated, not that data is exported.
- **EVIDENCE:** the handler and both helpers as quoted above; `test/widget_safety_test.dart` contains exactly three private-mode tests — "private text requests an obscured non-learning IME", "private composition is cleared on TV editor change" and "backgrounding clears private input and cancels live edit" — and none exercises the transition out of private mode, which is why the path is uncovered.
- **SEVERITY:** major
- **SMALLEST CORRECTION:** make any privacy transition discard the buffer rather than only the entry transition. Evaluating the old mode before mutating it is sufficient: clear the draft for the current context and replace the buffer with an empty value whenever `value || private` holds, then set `private`. Add one widget test that types under privacy, deselects it, changes context and asserts the field returns empty.

## Verdict by criterion

**Resolution completeness — CLEAN.** Both technical findings from the previous pass are disposed of correctly: one fixed at the layer that owns the dependency and proven on the shipped artifact, one withdrawn by its author with nothing added. All four product corrections are present in source.

**Dart model and bridge contracts — CLEAN.** `TvModel` guards every asynchronous result against target and session identity through `_isCurrent`, rejects snapshots from older sessions and out-of-order sequences within a session, serialises all profile writes through a single chain, never recreates a forgotten television in `updateSaved`, bounds the icon cache and clears it on connect, and maps every error code the native layer can emit — including the storage and identity categories added for the storage finding — with a catch-all so no internal token can reach a user. The write chain is structurally sensitive to a callback throwing, but the callback body is exception-free: `guard` swallows everything from the operation, Flutter's notifier reports listener exceptions rather than rethrowing, and each completer is fresh.

**Dart interface consumers — DEFECTIVE in one place.** Finding 1. Everything else I read holds: `RemoteButton` captures the target at pointer contact and uses it for the resulting tap, consumes an unsupported long press without degrading it into a release tap, releases on the original target when disposed, and meets the touch-target floor at 56 by 56; the viewer clears pending pointer state on generation change, staleness, multi-touch and direct-mode change, and rejects coordinates outside the framebuffer; every `addListener` has a matching `removeListener`; and every call that reaches the platform from the interface is wrapped in `guard` or `onTarget`, or in an explicit try-and-catch with a mounted check, so no unhandled asynchronous error can escape.

**Native socket accounting — CLEAN, unchanged and previously proven.** The LibVNCClient delta is byte-identical to the one verified last pass, whose run showed the original reproduction succeeding in 58 milliseconds, the large path covered at 307,200 bytes, cumulative expiry landing at 1003 milliseconds against a one-second budget, and the unlimited case waiting 1109 milliseconds and still succeeding.

**Native memory safety — CLEAN.** The screenshot copy validates format, exact dimensions, stride floor and stride alignment under the frame mutex before locking, and reports the unlock result.

**Network confinement — CLEAN.** The bounded client disables proxying, redirects, retry and fast fallback, sets all four timeouts including a whole-call deadline, uses a one-shot body, and pins both name resolution and the socket to the already-validated address.

**Credential and secret handling — CLEAN.** Storage operations wrap every exception into sanitized categories, identity exceptions carry codes only, and the diagnostic sink carries no strings.

**Licensing and attribution — CLEAN.** The modification notice on the forked screen-viewing library marks its base revision, retains the original licence, and states exactly which platforms were validated.

**Build and dependency wiring — CLEAN.** The keep rule ships inside the library archive; the configuration-cache evidence names the generation task; the pinned states are recorded.

**Test and oracle quality — CLEAN, with the coverage gap that finding 1 names.** Verified from result files rather than exit codes: 26 application tests, 39 library tests, 36 Flutter tests, zero failures; the analyzer reports no issues. The shrinking regression now runs against the minified package, which is the oracle whose absence hid the original defect.

**Over-engineering — CLEAN.** Nothing added exceeds its requirement; the contrast correction replaced a fade rather than adding a layer.

**Interface evidence — accepted with your correction.** I accept that a zero exit from the flow runner together with completed commands is the actual result and that the absence of a printed pass word does not establish failure; I withdraw the implication to the contrary from my previous pass. Five flow directories are complete with 11 to 51 completed commands each. I did not observe the exit codes myself, since the logs do not contain them, so that part rests on your statement rather than on my inspection.

**Completeness.** I read the screen-viewing delta in full, the remote library's security-relevant code in full, the resolution ledger, every fresh evidence artifact named, the native bridge, and — new this pass — the model, the keyboard screen, the shortcuts screen, the shared widgets and the viewer in full, with the remaining interface files swept for asynchronous-contract defects rather than read line by line. That sweep is narrower than a full reading and I state it as such. This establishes that the scoped artifact was inspected and every criterion reported; it does not establish that no undiscovered defect remains.

## Open items that are not code defects

No real television has been reached, so the hardware checklist stands entirely open; no genuine pairing code, screen-sharing password or Sony authentication has been entered; the physical controller model and operating system version were requested and not supplied. The copy gate proposal remains uninstalled pending exact-diff approval. Both dependency forks still need publicly reachable addresses before any open-source release. Real screen-reader verification, permanent permission recovery and the latest high-resolution rerun remain pending emulator work. The release package is signed with debug keys. No receipt is claimed and none was requested.

AUDIT COMPLETE: 1 findings (1 blocking)
