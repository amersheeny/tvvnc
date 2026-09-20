# Phase 0 review resolution ledger — 2026-09-21

Full artifact: the LAN-only app, the separately maintained Android Remote
library delta, and the LibVNCClient partial-read delta. No VPN implementation,
TV companion or cloud service was added; no real TV control action was sent. The Sony
hardware acceptance matrix is unchanged and remains open.

Technical reviewer session: `27799b89-9474-4dc0-81cb-a277c6feb939`.
Product reviewer: `/root/phase0_design_review` (all merged specialist lenses).
Copy sessions and verbatim verdicts are recorded in the adjacent review files.

Initial classification: AGREE 21 / DISAGREE 1 / TRADEOFF 0 across eight
technical and fourteen product findings. T8's stronger automatic-build-gate
interpretation was subsequently withdrawn. No finding was filed or dropped.
No final receipt is claimed while hardware access and the exact copy-gate
approval remain open. Paths below are relative to the app worktree unless
explicitly absolute; they identify code, not hidden external state.

## Technical findings and seam checks

1. **Unknown power toggle inferred Off — fixed.** `PowerObservation.kt` accepts
   only positive observed-on evidence. `TvController.execute/wake/snapshot` use
   a power-intent epoch, cancel pending wake before Off dispatch, invalidate
   cached power and do not call uncertain delivery physical standby. Read the
   Sony power refresh, native connection state, macro waits and Off retry loops.
   Three independent observation tests and current router tests pass; actual
   standby/wake is still hardware-blocked.
2. **RFB authentication classification lacked real evidence — fixed.** Shared
   `rfb_errors.h` is used by the app and the upstream-handshake regression. The
   real RFB 3.8 failure path uses a different log prefix than the initial
   classifier expected; the fail-before harness exposed it. Positive and
   negative type-2 handshakes now pass. Read `rfbclient.c` authentication,
   password callback and app retry policy. No server reason or secret is logged.
3. **Full-frame screenshot copies — fixed with the revised reviewed design.**
   The first chunk-copy proposal still left a third full buffer during Bitmap
   creation; reviewer and author corrected it before accepting the resolution.
   JNI now copies directly into a locked Android Bitmap, validates dimensions,
   stride and format, sets alpha opaque, and refuses resize races. Read Kotlin
   allocation/save/finally recycle, JNI registration/keep rule and frame mutex.
   At the pixel cap, framebuffer + Bitmap is 128 MiB before encoder overhead;
   the copy still briefly holds the decode mutex. No zero-stall claim.
4. **No diagnostic seam in extracted library — fixed.** Per-instance typed sink
   records only TLS_CONNECTED and SERVER_IDENTITY_OBSERVED. Read both socket
   constructors, pin validation, pairing cancel and bounded 16-event export.
   TLS fixture tests cover the sink; no fingerprint/host/payload strings exist
   in its public event contract.
5. **Sony registration asks for WOL without disclosure — fixed.** Confirmation
   precedes actRegister and explains the request using independently reviewed
   copy. No claim that this definitely changes a persistent TV setting. The
   physical observation is in the hardware checklist.
6. **Configuration-cache proof covered only dependencies — fixed evidence.**
   Executed the actual included-build generation task with store and reuse.
   The initial final-check command omitted the included-build project segment
   and failed task selection; the corrected exact task executed successfully.
   The captured report names that generation task; 14 warnings are from the
   current Flutter/Gradle toolchain, not failed generation. No speculative
   Gradle provider rewrite and no global cache enablement.
7. **Storage failures collapsed into network failures — fixed.** Sanitized
   storage categories survive SecretStore/ProfileStore, library identities,
   generated Pigeon wrapping, native safeError and Flutter codeKey. Read every
   save/forget/intent/decrypt call site and direct versus command-outcome error
   paths. Unknown exceptions still never export arbitrary messages. The
   proposed “cannot be recovered” copy was not shipped because failure does
   not prove permanent loss. The reviewer's lock-removal invalidation assertion
   was withdrawn: these keys are not user-authentication-bound.
8. **Automatic submodule refusal — reconciled, not installed.** The plan asks
   for pinned commit/clean-state verification before building; manual gitlink,
   HEAD and status checks satisfy it. The reviewer withdrew the demand for an
   unapproved blocking hook. Exact fork commits, nested schema and clean source
   states are recorded. LibVNC's docs/noVNC submodules are not build inputs and
   intentionally remain uninitialized. Public fork publication remains gated.

## Product findings and seam checks

1. Private keyboard: text+obscure, suggestions/autocorrect/learning disabled,
   and a new TextField identity when privacy changes. Actual Android text-input
   channel lacks updateConfig, so merely updating widget flags was insufficient.
   Real Gboard capture/log shows password/no-suggestion/incognito mode. Read
   mode toggle, ordinary draft cache, sensitive credentials and PIN inputs.
2. Per-action availability is computed in Kotlin from adapter acceptance and
   live provider state; Flutter decorates/explains it, without protocol routing.
   Screen-only connection is named as VNC. Protected app-list failure does not
   disable separately reported Sony keys. Timeout is not unsupported.
3. Unsupported long press is consumed and explained, never a release tap.
   Pointer-origin target and transport generations survive holds/cancel;
   queued taps cannot move onto replacement connections. Touchpad help covers
   swipe/tap and advertises hold only when supported. Regression tests cover
   target changes, cancellation and unavailable holds.
4. TV editing keys have a separate heading/body and qualified labels, distinct
   from local draft Clear. The delete key no longer uses the draft-trash icon.
5. Ordinary Compose drafts persist only in memory by TV/application; Live Edit
   has separate content. Private drafts never enter that cache and clear on
   context/background/navigation. IME commit-without-text-change is observed.
   Read composition listener ordering, dispose, paste futures, forget and
   target-switch listeners. Widget tests cover these paths.
6. Status row minimum is 48 dp. Read row constraints and wrapping consumers;
   final rendered large-text measurement is required.
7. Default core layout places D-pad, volume/mute and Keyboard/Voice together;
   Back/Home remain prominent. Custom ordering is preserved without duplicate
   volume controls. Final light/dark/large-text captures judge the result.
8. Apps empty catalog, no matches, empty favorites and empty recents are distinct.
9. Unknown diagnostics are not “Not checked yet”; the latter is reserved for
   observations with timestamp zero. Report expansion keeps stable identity.
10. First-run permission denial has a persistent Open phone settings route;
    resume rechecks permission and native snapshots clear stale denial state.
11. Theme choices expose checked/mutually-exclusive semantics.
12. Shortcut Save is disabled until both name and steps are present.
13. Shortcut deletion offers Undo; serialized latest-profile writes neither
    recreate a forgotten TV nor overwrite a newer shortcut with the same ID.
    Read favorite/layout/native recents writers as same-class concurrency seams.
14. Voice capture starts only after accepted long press, not raw pointer down;
    scrolling cancels before recording. Accepted hold release/cancel stops it;
    explicit accessible Start/Stop remains. Tooltip placement was corrected
    after the gesture regression test showed it stealing the long press.

## Additional author checks and corrections

- The initial successful release harness had stale images and was withdrawn.
  Fragmented input reproduced an upstream LibVNCClient immediate-timeout bug.
  The separate fork preserves WaitForMessage's buffered/replay fast path but
  uses socket-only waits inside ReadFromRFBServer. Actual cumulative idle time
  is charged in both small/large paths, never reset on progress. ASan/UBSan
  covers fragmented success, cumulative expiry with progress, no-timeout,
  buffered fast path, EOF, invalid fd and replay. TLS/SASL/Windows runtime is
  not claimed. Adaptive quality intentionally measures end-to-end response,
  not decoder-only CPU time; the contrary review proposal was withdrawn.
- SO_TIMEOUT does not bound writes. Native Remote now closes only the captured
  socket after a five-second write deadline and reports uncertain delivery;
  an old deadline cannot close a new socket. A blocked-writer socket test is
  included in the 39-test library result. Read reader/ping mutex, disconnect,
  connection generation and dispose ownership.
- Sony HTTP now uses current OkHttp 5.5.0 with one-shot bodies, no retries,
  no redirects/proxy/cookie jar/cache/logging, bounded response reads and a
  whole-call deadline. A socket factory pins the already-private address and
  preserves IPv6 interface scope; normal TLS verification stays enabled.
  Loopback server tests independently prove pinning, credential redirect
  rejection, active-read cancellation, response cap and drip deadline without
  replay. The first test run caught an inherited Socket property shadowing
  the factory address; qualified ownership fixed it before the passing run.
- Sony encrypted text caches only the TV public key. Each request generates a
  fresh key/IV envelope; the cipher is one-shot and cleared afterward. The
  independent RSA/AES receiver test decrypts Unicode and block-boundary inputs
  and rejects IV reuse. Actual reference TV exposes v1.0, so v1.1 actuation is
  not represented as Sony hardware proof.
- Late Sony registration cannot restore forgotten/replaced credentials:
  return cookie to controller, fence session, then atomically compare the
  process-local auth revision/existence with the profile store before saving.
  Forget, Sony secret edits and host changes invalidate that revision; layout,
  favorites, recents and MAC changes do not. Read shared preference locks and
  controller target switching. Keystore-backed race instrumentation is pending.
- App icons are requested by lazily mounted row widgets, not eagerly for all
  catalog entries. A 1,000-app widget test requests fewer than 30 icons and
  never requests app999 initially. Late errors are fenced to the originating TV.
- When no REST input catalog exists, the picker exposes only reported discrete
  Tv/HdmiN commands. No presumed HDMI count, factory command or IRCC constant
  is added. Cable status remains Unknown; selection and shortcut waits use
  actual reported content. Unit tests cover port2 versus port20 and null state.
- Native startVoice refuses a closed/background session before permission or
  capture. Actual microphone/assistant behavior remains hardware-blocked.

## Open decisions and proof requirements

The exact new copy-gate diff is proposed at
`/Users/amsh/worktrees/tvVNC/copy-gate-proposal-v2.patch`, not installed. It includes
267 text hashes tied to completed independent verdicts; its parser was run
against the current working files and proposed manifest (not claimed installed
or as a HEAD gate pass). Await the user's explicit diff/hook approval.

Real Sony pairing credentials and a reachable Android controller are absent.
Mac read-only queries work; the owned emulator's actual-TV route fails. Needed:
the user's Android phone/model/OS and in-app credential entry, or corrected
emulator local-network access. Secrets must not be sent in chat. Hardware and
performance acceptance cannot be replaced by fixture tests. No final receipt,
publication, overall completion or actual-TV actuation claim is permitted yet.

## Combined-pass correction set

Full technical report is archived in `technical-combined-1.md`; its resolution
call is archived in `technical-shrinking-resolution.md`. The product reviewer
reported four additional medium findings. Classification before edits:
AGREE 5 / DISAGREE 1 / TRADEOFF 0. The sole disagreement (enum names) was
withdrawn in full by its author. Nothing was silently dropped or filed.

The four UI gaps originated in the preceding correction set: 4 / 14 = 28.6%,
triggering a substrate pass, not another symptom-by-symptom patch. Read this
round: every KeyboardPage composition/mode/context/background/dispose/send
transition; TvModel target guards/draft storage and serialized metadata edits;
all availabilityHint and RemoteButton consumers; VoiceCapture status ordering
and VoiceButton accessibility consumers; Shortcuts deletion/Undo identity and
Flutter's actual SnackBar queue/persist/close implementation. Those seams led
to the unified mode/send ownership and explicit per-record Undo presentation
below. The product reviewer approved the complete resolution design, including
the added same-name deletion-order distinction, before implementation.

- **R8 protobuf failure, confirmed and corrected.** A separate Java harness
  loaded the exact original release APK on Android ART. Both message families
  failed reflective lookup after shrinking, while the macro enum names remained
  intact. Evidence:
  `/Users/amsh/worktrees/tvVNC/release-protobuf-enum-confirmed.log` and
  `/Users/amsh/worktrees/tvVNC/release-protobuf-before-crash.log`.
  The remote library now packages a consumer rule for subclasses of
  GeneratedMessageLite; shrinking remains enabled. The built AAR's proguard.txt
  was read to confirm packaging. The unchanged-library-code 39 tests and AAR
  assembly passed in
  `/Users/amsh/worktrees/tvVNC/remote-library-consumer-tests.log`.
  The exact new minified APK round-trips three hold-direction fixtures and two
  Polo fixtures in
  `/Users/amsh/worktrees/tvVNC/release-protobuf-after-corrected.log`.
  The empty SecretAck fixture must use the actual minified pairing receive
  function (mergeFrom/buildPartial), not strict parseFrom, because the known
  service variant omits a proto2-required empty field. The first probe after
  the fix used the wrong strict oracle for this case; its failure was corrected
  in the harness, not hidden by deleting the case or changing product behavior.
  The runner does not simulate or claim a TLS handshake or real-TV pairing.
- **Enum-name claim refuted.** Same-APK ART output retains WAKE/HOME/INPUT/APP/
  WAIT_FOR_TV/KEY/SONY despite renamed static fields. Enum.name is data, not a
  reflective field lookup. No redundant enum keep rule or silent shortcut
  dropping was added. A future deliberate schema rename needs migration, but
  none exists in this initial implementation.
- **Clickable unavailable controls:** removed .55 whole-control fading. A
  neutral outlined presentation retains full-contrast foreground plus an info
  marker and existing availability semantics. Explanation remains clickable.
  This is not disabling or deleting unavailable capability affordances.
- **Compose/Live transition ownership:** programmatic buffer changes suppress
  composition-commit callbacks. Mode/context epochs own the pending send as
  well as displayed text; transitions release the old UI busy state, and old
  completion cannot change a new mode or unblock a newer request. Same-context
  Live failure restores Compose. TvModel also suppresses obsolete-editor result
  messages. Three new widget regressions failed before these changes.
- **Undo identity and dismissal:** Flutter's actual persist default is
  action!=null, independently of accessibility mode; the earlier explanation
  attributing persistence solely to accessibility was wrong. Each queued bar
  now names the shortcut, original TV and monotonically increasing deletion
  number, with an explicit Dismiss icon. Each Undo still owns the exact macro
  and profile; no earlier restoration opportunity is silently discarded.
  Two same-name/different-action tests cover Undo-first/Undo-second and
  Dismiss-first/Undo-second, verifying exact restored IDs and steps. Fixed
  notification text was independently reviewed before entering code; names
  and deletion number are substituted in one pass, so placeholder-like user
  names are not reinterpreted. Names are bounded to120characters (the copy
  reviewer called them unbounded; that does not affect its wording verdict).
- **Voice readiness semantics:** Starting and Listening now expose their own
  already-reviewed labels, instead of announcing Listening during negotiation.
  The semantic regression failed before and passes after. Actual microphone
  readiness on a TV remains a separate hardware check.

Fresh correction-set evidence: analyzer clean and 36 Flutter tests in
`/Users/amsh/worktrees/tvVNC/review2-analyze-final.log` and
`/Users/amsh/worktrees/tvVNC/review2-flutter-tests.log`; 26 app JVM tests in
`/Users/amsh/worktrees/tvVNC/review2-app-tests.log`; three-ABI release build in
`/Users/amsh/worktrees/tvVNC/review2-release-build.log`. APK SHA256:
`a063af9faf99c9b76dcb23ae840166dd65603d7abf1d0c8e54ff515ae70e0d8d`.
Rendered correction-set evidence is under
`/Users/amsh/worktrees/tvVNC/review2-ui`; only completed logs and inspected
images count. Hardware/copy-gate/publication items remain open.

## Subsequent whole-artifact pass

Technical report `technical-combined-2.md` confirmed the shrinking fix and
reported a private-to-revealed buffer cache leak. Its resolution call is
`technical-privacy-resolution.md`. The product reviewer confirmed the contrast,
Compose/Live, Undo ownership and voice-label corrections, but found a shared
wrapper constraint regression and required actual active Undo-bar captures.
The new full round was triaged AGREE2 / DISAGREE0 / TRADEOFF0 before edits.

- Stack's default loose fit discarded the incoming minimum width, shrinking
  unavailable controls while placing the info marker at the cell's far edge.
  Read the installed RenderStack sizing/baseline constraint switch and every
  availabilityHint consumer. `StackFit.passthrough` preserves the constraints.
  A fail-before test asserts a500dp button and taps the actual info-marker
  position to open its explanation. No colors or capability policy changed.
- Masking is now separate from a buffer's sensitivity. Marking Private evicts
  its ordinary cache but retains the typed value; revealing retains sensitivity
  without retaining a draft. Context/background/dispose paths cannot cache it.
  Explicit clearing/emptying while unmasked ends sensitivity and starts a new
  normal input client. Sending still types sensitive text as explicitly asked;
  the TV clipboard section is hidden while sensitive and its dispatch also
  carries the privacy flag. The reviewer withdrew its destructive suggestion
  to clear text merely when marking it private or revealing it.
- The same substrate pass read both clipboard sinks and every controller
  assignment, not only the reported cache call. A delayed phone paste is bound
  to mode, target, context and buffer revision. Value equality alone failed
  when the user cleared then retyped identical text while a private paste was
  pending; `/Users/amsh/worktrees/tvVNC/paste-buffer-before.log` demonstrates
  the wrong late text replacing the new buffer. A controller revision now
  rejects that obsolete result, including identical-content edits.

The new wrapper/privacy tests failed before the set in
`/Users/amsh/worktrees/tvVNC/review3-before.log`. All41Flutter tests and analyzer
pass in `/Users/amsh/worktrees/tvVNC/review3-final-flutter-tests.log` and
`/Users/amsh/worktrees/tvVNC/review3-final-analyze.log`. Native/C++/JVM source is
unchanged; its cited results carry. The fresh APK and minified runtime probe
are recorded in `/Users/amsh/worktrees/tvVNC/review3-final-release-build.log`
and `/Users/amsh/worktrees/tvVNC/review3-final-release-protocol.log`.
Real Gboard revealed-sensitive behavior, current rendered matrix, active
numbered Undo bars, screen-reader path and latest4K confirmation still require
the corresponding completed captures before this set can be approved.
