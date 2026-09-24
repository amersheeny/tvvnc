# Historical Phase 0 implementation ledger

This ledger preserves earlier checkpoints, not current release status. See
[the release status](release-readiness.md) for current evidence and publication
work. References below to a proposed copy gate are historical: it was not
installed and is not being pursued as part of this release.

The implementation and the proof are deliberately tracked separately. A checked
implementation item is not a claim of Sony hardware acceptance.

| Area | Code | Evidence so far |
| --- | --- | --- |
| Native Android Remote library | Implemented in a separate ScreenCast fork | 39 JVM protocol/crypto/TLS/write-deadline tests; phone-to-Sony pairing pending |
| LibVNCClient viewer | Implemented through JNI and SurfaceProducer | Authenticated type-2/Tight/JPEG stream in the running Android app |
| Command routing | Implemented | No uncertain replay, stale-target rejection and transport-bound hold tests |
| Sony REST/IRCC | Implemented | Read-only probes of the real TV; encrypted-text envelope unit test; actuation pending |
| Flutter screens | Implemented | Real app launch and viewer/keyboard/diagnostics flow on an owned emulator |
| Keyboard / voice | Implemented | Editor/Unicode/voice wire tests and keyboard-to-RFB integration; real-TV checks pending |
| Wake / shortcuts / recovery | Implemented | Packet format and lifetime tests; real standby/boot and independent-drop matrix pending |
| Copy | Independently reviewed | 267 strings, two copy-only review sessions and their correction artifacts |
| Copy gate | Proposed, not applied | Exact new blocking-gate diff awaits the user's approval |
| Product / full code audit | Scoped reviews clear; overall acceptance open | Final technical pass returned 0 findings; scoped product/emulator review found no new issues. Hardware and user-owned gates remain |
| Performance | Not measured | Fixed physical controller and independent display timing are required |

Android 17 / API 37 local-network permission was exercised in the running app:
request, denial, a second explicit request and grant. The owned emulator uses
16 KB memory pages. Microphone permission remained ungranted in that flow.

## Current environment constraint

The final technical report is
`/Users/amsh/worktrees/tvVNC/worktree/docs/reviews/technical-final.md`.
No gate receipt or publication approval is implied by that report. The copy
gate is still unapplied; the latest exact proposal is
`/Users/amsh/worktrees/tvVNC/copy-gate-proposal-v2.patch`.

The Mac's read-only Sony requests succeed. The owned Android 15 and Android 17 emulators' direct
LAN socket test returns `No route to host`; loopback-host traffic works. An
asynchronous question asks the user to inspect macOS Local Network access for
the emulator. This is not evidence that droidVNC-NG cannot capture the TV, or
that the TV lacks an advertised protocol. No TV password, Sony secret or real
pairing code has been supplied to this task.

The local protocol fixture binds only to `127.0.0.1:15900`, uses a deliberately
synthetic test password, and controls no real TV. Its test pattern is an RFB
integration oracle, not a substitute for Sony hardware validation.

User-confirmed baseline: the Sony KD-55AF8 is viewable through droidVNC-NG in
existing VNC clients. The new app must reproduce that path and add native
control. This is the first test target, not a product restriction.

Acceptance includes navigation and holds, native remote button families,
direct inputs, volume/mute, discovered apps, Unicode input, live viewing,
standby wake and independent recovery. A failed required check is not converted
into a pass by relabelling a feature unsupported. Voice and HDMI capture need
independent capability evidence.

## Read-only reference-TV findings

Reference model: Sony KD-55AF8. Addresses and MACs are intentionally not committed
as application constants or public test fixtures.

| Capability | Observed on the reference TV | Not yet established by this app |
| --- | --- | --- |
| RFB | Version 3.8; classic authentication offered; user already views droidVNC-NG in other apps | In-app viewing with the TV's saved password |
| Sony remote catalog | 146 names / 140 distinct reported codes | Actuation and button-family behavior |
| Power and audio reads | Active power and volume/mute responses | Standby wake, absolute changes and restoration |
| External inputs | HDMI 1–4, AV and screen-mirroring sources; empty user labels at probe time | Direct source changes and actual HDMI capture |
| Sony text | setTextForm v1.0 with string parameter is exposed | Unicode insertion in real focused TV fields |
| App/system data | Authentication required for protected queries | App catalog, launches and firmware value |
| Android Remote | v2 mDNS advertisement and service/pairing ports | Negotiated features, installed service version, pairing persistence and actuation |
| Voice | Not inferred from Android version or an open port | Negotiation, audio session and actual assistant behavior |
| WOL | Network MAC can be configured/discovered | A successful, observed standby-wake test |

The Sony interface version seen in research is an API generation, not a firmware
version. No firmware value is invented from that number.

## Evidence locations

Latest product bytes: three-ABI APK SHA256
`eb8869c27fc87973eca1bf090d3481e23abf23ae1350113a6edeedc26f449fd9`.
Current41Flutter tests/analyzer and the exact minified Android ART protocol
probe pass:
`/Users/amsh/worktrees/tvVNC/review3-final-flutter-tests.log`,
`/Users/amsh/worktrees/tvVNC/review3-final-analyze.log`,
`/Users/amsh/worktrees/tvVNC/review3-final-release-protocol.log`.
The26app JVM/39library results carry unchanged native inputs. Current rendered
permission, viewer, light/dark/large-text, sensitive-reveal and numbered Undo
checks are under `/Users/amsh/worktrees/tvVNC/review3-ui`; per-flow exit records
are `/Users/amsh/worktrees/tvVNC/review3-e2e-exits.tsv`. The independent scoped
product result and exact captures are recorded in
`/Users/amsh/worktrees/tvVNC/worktree/docs/reviews/product-scoped-result.md`.
The original first-touch-after-enabling-TalkBack is excluded: the service had
not yet bound. The subsequent bound-service focus/activation pair is the proof.

The first latest viewer attempt was disrupted by Gboard's stylus-handwriting
state after low-level accessibility-input testing. No application workaround
was added. Rebooting the owned emulator restored its ordinary keyboard; the
unchanged APK's viewer flow then completed. A later test uses explicit finger
events. This does not waive any required rendered check.

The subsequent combined review found a release-only protobuf shrinking defect.
The original release APK's Android Remote transport is **not accepted**: actual
Android ART execution reproduced reflective field lookup failures in both
pairing and remote-control messages. A library consumer keep rule fixes the
root cause without disabling shrinking. The current APK passes exact minified
message round-trips, including the real pairing decoder's partial-ack path:
`/Users/amsh/worktrees/tvVNC/release-protobuf-after-corrected.log`.
Current APK SHA256 is
`a063af9faf99c9b76dcb23ae840166dd65603d7abf1d0c8e54ff515ae70e0d8d`.
Current correction-set evidence is 36 Flutter tests/analyzer clean, 26 app JVM
tests and 39 library tests plus the AAR's packaged consumer rule:
`/Users/amsh/worktrees/tvVNC/review2-flutter-tests.log`,
`/Users/amsh/worktrees/tvVNC/review2-analyze-final.log`,
`/Users/amsh/worktrees/tvVNC/review2-app-tests.log`,
`/Users/amsh/worktrees/tvVNC/remote-library-consumer-tests.log`.
Rendered checks for that APK are recorded under
`/Users/amsh/worktrees/tvVNC/review2-ui` and require image inspection before any
visual claim. The prior 4K run exported a3840×2160PNG and recovered after fixture
shutdown; that is viewer evidence, not Sony HDMI or latency acceptance.
The latest unapplied gate proposal is
`/Users/amsh/worktrees/tvVNC/copy-gate-proposal-v2.patch`.

The following runs are historical evidence, not approval of the current whole:

The initial release-viewer runner returned success while its images showed an
unavailable/stale screen. That run was withdrawn as viewing proof. A fragmented
read regression reproduced an upstream LibVNCClient defect (immediate timeout
with partially buffered input); the separately maintained fork fixes that read
path and cumulative idle-time accounting. The strengthened viewer flow asserts
a live frame and successful screenshot export. The later release captures below
show the actual colored fixture; they are not Sony/HDMI/DRM acceptance.

- Current Flutter analyzer and 29 tests:
  `/Users/amsh/worktrees/tvVNC/frozen-analyze.log`,
  `/Users/amsh/worktrees/tvVNC/frozen-flutter-tests.log`.
- Current app-side 26 JVM tests (including HTTP pinning, no credential redirect,
  cancellation, drip deadline, power observation, routing, text envelope and
  reported-input fallback): `/Users/amsh/worktrees/tvVNC/final-input-app-tests.log`.
- Native library 39 tests:
  `/Users/amsh/worktrees/tvVNC/remote-library-deadline-tests.log`.
- LibVNC partial-read/cumulative-time regression, ASan/UBSan:
  `/Users/amsh/worktrees/tvVNC/libvnc-reader-final.log`.
- Actual RFB type-2 positive/negative authentication and decoder guards:
  `/Users/amsh/worktrees/tvVNC/review-native-sanitizers.log`.
- Protobuf generation actually executed with configuration-cache store and reuse:
  `/Users/amsh/worktrees/tvVNC/configuration-final-store-corrected.log`,
  `/Users/amsh/worktrees/tvVNC/configuration-final-reuse.log`.
  The captured problems report identifies this exact generation task, with 14
  upstream Flutter/Gradle warnings and no protoc entry:
  `/Users/amsh/worktrees/tvVNC/configuration-final-problems.json`.
- Current three-ABI, minified, debug-key-signed release APK build:
  `/Users/amsh/worktrees/tvVNC/final-input-release-build.log`.
  This is a local test artifact, not publication signing.
- Prior inspected live release frames and opaque exported PNG:
  `/Users/amsh/worktrees/tvVNC/maestro-review-release/.maestro/tests/2026-09-21_012707/viewer`,
  `/Users/amsh/worktrees/tvVNC/review-exported-screenshot.png`.
- Actual Gboard private-mode fix (new native input client, no suggestions,
  personalized learning disabled, masked text, cleared on leaving):
  `/Users/amsh/worktrees/tvVNC/maestro-private-fixed/2026-09-21_013712/private_input`.
- Current correction-set UI matrix is recorded separately under
  `/Users/amsh/worktrees/tvVNC/frozen-ui`; final-head confirmation remains pending
  until its images and logs have been inspected.

Historical run locations (not whole-current-tree proof):

- Native library tests: `/Users/amsh/worktrees/tvVNC/remote-library-tests.log`
- App Kotlin tests: `/Users/amsh/worktrees/tvVNC/app-unit-tests.log`
- Flutter tests: `/Users/amsh/worktrees/tvVNC/flutter-tests.log`
- Analyzer: `/Users/amsh/worktrees/tvVNC/analyze.log`
- App build: `/Users/amsh/worktrees/tvVNC/app-ui-build.log`
- Address/undefined-behavior sanitizer regressions:
  `/Users/amsh/worktrees/tvVNC/native-sanitizers.log`
- Running-app viewer flow (passed, 1m 38s):
  `/Users/amsh/worktrees/tvVNC/maestro-current/2026-09-20_233001/viewer`
- Proposed, unapplied gate: `/Users/amsh/worktrees/tvVNC/copy-gate-proposal.patch`
- Android 17 permission flow (passed, 21s):
  `/Users/amsh/worktrees/tvVNC/maestro-permission37/2026-09-20_235726/network_permission37`

These are per-run artifacts. Later changes require re-running the units they
reach; the whole current tree is not declared validated by this ledger.
