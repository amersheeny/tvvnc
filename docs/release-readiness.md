# TV VNC release status — 2026-09-24

The Google Play app entry has been created in Apptico LTD account
`7883012350776988385`, app ID `4975411859587523968`, for package
`com.asheeny.tvvnc`. The developer authorized the three required creation
declarations and disabling the optional installer check. Support contact:
`support@apptico.com`. No release has been submitted or approved.

The headed Android emulator is the release-validation environment. The owner's
physical phone is optional supplementary coverage, never a release prerequisite.
Post-fix behavior must be exercised on the actual app running in that emulator;
physical-TV observations remain separately labelled and are not inferred from
protocol fixtures. Source publication is a draft checkpoint, not release
sign-off. Native dependency URLs name public forks, not local filesystem paths.

The current Power code retains a usable authenticated native toggle in standby;
Sony/Wake-on-LAN recovery remains available when that route is unavailable.
The icon is the same 56 dp size and tonal style as Keyboard, directly above it.
The headed emulator demonstrated native On → Standby → On without a Sony key,
and a separate authenticated Sony-only sequence passed with native keys disabled.
Failed Sony wake authentication is reported immediately and remains in the
diagnostic report after the wake timeout. These are protocol-fixture tests,
not a claim of universal physical-TV compatibility.

The app now explains TV-side VNC server setup on Your TVs and includes a bundled,
offline Privacy policy. The VNC interrupted-read/write fix is integrated.
Native dependency URLs are public, immutable gitlinks. Store text, source-code
directions, license notices, artwork and new 1080×1920 screenshots are prepared.
The TV image is an AI-generated illustration displayed through the real viewer.

The current signed AAB was built from the application source at `e0cd069`:
`/Users/amsh/worktrees/tvVNC/worktree/build/app/outputs/bundle/release/app-release.aab`.
Its SHA-256 is
`5e6704b7425997b074861253e0257b337ee61d12933394dd17450a019055aab0`.
The signed APK SHA-256 is
`bf3ec050d18703172a73790a1e7a856f440c5c02f904bb44fa3dcf2a3a6d7afe`.
Subsequent commits add only test-flow/evidence records, not application build inputs.
The older signed artifacts mentioned in historical checkpoints are superseded.

Current evidence: 169 Flutter tests, 49 Android application unit tests, clean
Flutter analysis, an actual Android runtime probe of minified protobuf/pairing
classes, APK signature verification and 16 KB ZIP alignment. All twelve expected
license/notice files match their source bytes in the signed AAB and APK.
Evidence logs are `/Users/amsh/worktrees/tvVNC/release-final-flutter-tests.log`,
`/Users/amsh/worktrees/tvVNC/wake-release-app-tests.log`,
`/Users/amsh/worktrees/tvVNC/release-final-analyze.log`,
`/Users/amsh/worktrees/tvVNC/wake-release-art-probe.log`, and
`/Users/amsh/worktrees/tvVNC/wake-release-apk-signature.log`.
Rendered runs are `/Users/amsh/worktrees/tvVNC/power-native-fallback-after`,
`/Users/amsh/worktrees/tvVNC/sony-power-release`,
`/Users/amsh/worktrees/tvVNC/wake-auth-diagnostic-confirm`,
`/Users/amsh/worktrees/tvVNC/standby-diagnostics-after`, and
`/Users/amsh/worktrees/tvVNC/play-current-capture`.

Restarting the app in a saved standby state now passes a one-press native wake
test, both without a MAC address and with a synthetic MAC that cannot wake the
fixture: `/Users/amsh/worktrees/tvVNC/power-restored-final.xml` and
`/Users/amsh/worktrees/tvVNC/power-restored-mac.xml`. An actual 102-byte WOL packet
was captured before enabling native keys; no late power toggle followed it.
Evidence: `/Users/amsh/worktrees/tvVNC/wake-fence-evidence.txt`. This is not a
claim of physical-TV WOL support. The Power job still waits for catalog work
needed by macros, but the UI stops claiming the TV is waking once On is observed.

The final wake regression set additionally covers a repeated Power tap during an
unresolved wake, Sony-first recovery after restart, and the distinction between
an unsent WOL failure and possibly delivered packets. The repeated-tap run is
`/Users/amsh/worktrees/tvVNC/power-repeat-after.xml`; the receiver recorded native
Up but no additional Power toggle. Fresh restart tests with rejected Sony
credentials passed without and with a synthetic MAC in
`/Users/amsh/worktrees/tvVNC/wake-release-restored.xml` and
`/Users/amsh/worktrees/tvVNC/wake-release-mac.xml`. Native keyboard prefill,
per-keystroke editing, deletion and Search passed in
`/Users/amsh/worktrees/tvVNC/wake-release-keyboard.xml`, with matching receiver
events. These are tests of the signed APK on the headed emulator. The fresh WOL
capture contains three complete 102-byte packets across the broadcast/unicast
destinations; enabling native keys afterward and repeating Power sent no toggle.
Evidence: `/Users/amsh/worktrees/tvVNC/wake-release-wol-packet-check.log` and
`/Users/amsh/worktrees/tvVNC/wake-release-wol-repeat.xml`. The authentication-only
failure remains visible when no alternative wake route can send, verified in
`/Users/amsh/worktrees/tvVNC/wake-release-auth.xml`.

The public policy is live at https://amersheeny.github.io/tvvnc/ and its fetched
SHA-256 matches the generated bundled-policy page. Privacy, reviewer access,
Advertising ID, Health, Ads, Government and Financial declarations are saved in
Play Console. The Tools category, support email and HTTPS project website are
also saved; the dashboard reports 7 of 11 initial setup tasks complete. Data
safety answers are saved as a draft pending the required
audience choice. IARC terms acceptance and audience selection await the publisher.
Final PR publication checks, remaining Console setup, bundle upload and submission
are unfinished. No new agent-blocking gate, hook or custom workflow,
VPN, companion or app cloud service has been installed. The user has directed that
no further scope be added. Progress is tracked at
https://github.com/amersheeny/tvvnc/issues/1; app PR:
https://github.com/amersheeny/tvvnc/pull/2.

## Historical checkpoints — superseded status follows

The records below preserve earlier tests and diagnoses. Statements about
publication, contact details, signing, or outstanding authorization describe
those earlier checkpoints, not the current status above.

Publication is requested but not complete. The public repository is
https://github.com/amersheeny/tvvnc, currently empty. The outstanding release
work is tracked at https://github.com/amersheeny/tvvnc/issues/1.
No source push, GitHub release, Play app entry or Play submission has been made.
The installed application
remains the data-preserving development build, not a Play-signed release.

## Latest local checkpoint

App `163ef6d`, native Remote library `a17e093` are committed. The APK is
`/Users/amsh/worktrees/tvVNC/releases/tvvnc-163ef6d-debug.apk`, SHA-256
`2db9ef574f6181fb373a8df7530015ed916a752a92e1a68407a18bfb8aa23dce`.
It is installed on the headed emulator, not the physical Samsung. The last
phone installation remains the artifact recorded below; subsequent USB and
wireless-ADB discovery do not currently show the phone.

The five original control findings below and atomic native editor publication
have source repairs and regression tests. Native metadata now carries TV input
type, IME options and action information. Phone selection is sent in native
edit batches; TV-declared passwords are masked before prefill. Native pending
echoes keep keyed fingerprints instead of historical plaintext values.

The latest Flutter run reports 153 passing tests in
`/Users/amsh/worktrees/tvVNC/editor-edges-final-tests.log`; analyzer is clean
in `/Users/amsh/worktrees/tvVNC/editor-edges-final-analyze.log`. Android app units
passed in `/Users/amsh/worktrees/tvVNC/editor-metadata-app-tests.log`; the
unchanged native library inputs retain their full-suite and metadata-test
results in `/Users/amsh/worktrees/tvVNC/editor-metadata-core-tests.log` and
`/Users/amsh/worktrees/tvVNC/editor-metadata-core-native-tests.log`.

Actual app testing with the loopback protocol fixture uncovered a disposed
controller on pairing-dialog exit. The same defect was reproduced in Sony PIN
and app-link dialogs. All three now let the field own its controller; automatic
pairing closure additionally checks that the dialog route is still current.
Failing-before logs are `/Users/amsh/worktrees/tvVNC/pair-dialog-before.log`,
`/Users/amsh/worktrees/tvVNC/sony-dialog-before.log` and
`/Users/amsh/worktrees/tvVNC/link-dialog-before.log`. The passing navigation
run, including cancellation and underlying-page protection, is
`/Users/amsh/worktrees/tvVNC/dialog-lifetime-after.log`.

The real headed-emulator re-pair/edit flow passed in
`/Users/amsh/worktrees/tvVNC/editor-fixture-edit2.log`. Its inspected captures
are in `/Users/amsh/worktrees/tvVNC/editor-fixture-edit2/screenshots`.
The independent receiver log `/Users/amsh/worktrees/tvVNC/editor-fixture.log`
records successive edit lengths 15, 16, 17, 18, backspace to 17, and native
Search action 3 without Send. Password mask/reveal checks passed with inspected
light and dark/130%-text captures in
`/Users/amsh/worktrees/tvVNC/editor-fixture-password/screenshots` and
`/Users/amsh/worktrees/tvVNC/editor-fixture-password-dark-large/screenshots`.
Temporary emulator night/font settings were restored to no/1.0.

Later edge cases and their source/test dispositions are recorded in
`/Users/amsh/worktrees/tvVNC/worktree/docs/reviews/editor-metadata-edge-resolution.md`:
password reveal/Clear/retype protection, custom action label/ID agreement,
Next/custom action focus, mouse-control focus and editable accessibility bounds.
The updated emulator flows establish cursor insertion, native action 91 and
password masking on return from background; they do not extend physical-TV
claims. One local metadata fixup commit remains to be autosquashed before
source publication.

These fixtures are not the physical Sony. Their RFB picture is a test pattern,
not an editor rendering. New physical caret, password, numeric/multiline and
editor-action acceptance remains open. The local Sony HTTP fixture cannot
bind privileged port 80 in this environment; its port-18080 responses are not
claimed as actual-app Sony fallback proof. The final combined technical and
rendered-product reviews, currentness checks, copy gate and production signing
remain open. The Diagnostics standby explanation also needs correction: fresh
Sony On observations can resume reconnects, contrary to its current wording.

The user confirmed public GitHub publication and a free Play app under Apptico
LTD. Play reports package `com.asheeny.tvvnc` available. The prepared form is
awaiting the user's declaration confirmation and installer-check choice.
Public support email is still needed. No legal declaration was accepted.

## Installed artifact and physical evidence

App source: `d63a51f7a1aa629eee1b911d5231225424877832`.
Android Remote dependency: `c1c82e5775f84fc89c6053d983d4e79588bdc056`.
Package: `com.asheeny.tvvnc`; display name: TV VNC.

The Samsung SM-S931B accepted the replacement installation at 17:17:46 local
time. The install log reports Success and the foreground activity is TV VNC.
The APK SHA-256 is
`29f272244847a9a37962c8ab78db87d6a5f78557dacd98bec6f9c29b01cbf669`.
Artifact: `/Users/amsh/worktrees/tvVNC/releases/tvvnc-d63a51f-debug.apk`.
Install and launch logs:
`/Users/amsh/worktrees/tvVNC/controls-queued-phone-install.log` and
`/Users/amsh/worktrees/tvVNC/controls-queued-phone-launch.log`.

The app reconnected to Android Remote and droidVNC-NG without a new pairing
prompt. Home, directional navigation, OK and TV Back were exercised against
the Sony KD-55AF8. The physical search-field sequence established:

- A TV-entered `q` prefilled the phone field.
- Input of `tvvnc` produced `qtvvnc` on the phone and TV without Send.
- One backspace produced `qtvvn` on both without Send.
- Local Keyboard Back returned to Remote; reopening prefilled `qtvvn`.
- Tapping the Samsung keyboard's `r` key produced `qtvvnr` on both without Send.
- Erasing the six test characters cleared both fields, without Send or TV Enter.

The actual run logs are
`/Users/amsh/worktrees/tvVNC/phone-validation-native-editor.log`,
`/Users/amsh/worktrees/tvVNC/phone-validation-live-typing.log`,
`/Users/amsh/worktrees/tvVNC/phone-validation-live-delete.log`,
`/Users/amsh/worktrees/tvVNC/phone-validation-soft-key.log`, and
`/Users/amsh/worktrees/tvVNC/phone-validation-clear.log`.
Each corresponding output directory contains that run's screenshots, which
were inspected locally. Private phone/TV screenshots are not publication assets
and are intentionally outside the repository.

This evidence does not qualify all applications, caret synchronization,
Unicode/emoji, multiline editing, focus races, voice, panel standby/wake,
external HDMI capture, or the entire hardware-acceptance checklist. No measured
latency percentile is claimed.

## Original control findings at the installed phone checkpoint

The following historical diagnoses describe `d63a51f`, not the current local
source. The source repairs and remaining acceptance limits are recorded above.

1. Macro panel readiness: the `WAKE`/`WAIT_FOR_TV` condition in
   `/Users/amsh/worktrees/tvVNC/worktree/android/app/src/main/kotlin/dev/tvvnc/tv_vnc/core/TvController.kt`
   still accepts Android interactivity when an identified Sony panel has no
   current power observation, unlike direct wake. Both consumers need the same
   panel-aware observation rule. This inconsistency was exposed by `d63a51f`.
2. Volume-only mute: the short KEY 164 acceptance path in the same controller
   still requires KEY feature 2 although its send path can use VOLUME feature
   64. Accept that short mute route independently; holds remain real key events.
3. Native output race: volume context validation and the ID passed to
   `setVolume` read different native snapshots. Capture one output/range state,
   derive its context, and pass its ID through the existing guarded write. The
   UI snapshot must use that same observation for value, range and context.
4. Sony output mismatch: the refresh path in
   `/Users/amsh/worktrees/tvVNC/worktree/android/app/src/main/kotlin/dev/tvvnc/tv_vnc/core/SonyTransport.kt`
   may choose a non-speaker record, but the setter writes `speaker`. Retain the
   reported target and minimum/maximum with its value and use that same target
   for context and requests. This pre-existing defect is on the volume path.
5. Live caret synchronization: `editLocally` in
   `/Users/amsh/worktrees/tvVNC/worktree/lib/ui/keyboard_page.dart` returns after
   changing local selection for Left/Right. It does not send selection to the
   TV; the text command sends a replacement range and string, not the phone's
   selection. The editing-key description promises both fields change. Local
   insertion position and TV caret movement require separate physical proof
   and a selection transport repair where that promise is not met.

The product-design audit completed across the supplied real emulator renders
and direct consumers, returning items 1–4. Source inspection independently
confirmed them. Item 5 was identified by subsequent owner source inspection;
it has not been physically reproduced. The remediation plan was sent to the
existing independent Claude session, but that run stopped at its subscription
session limit without a completed resolution review:
`/Users/amsh/worktrees/tvVNC/controls-resolution-review.log`.
No new review receipt is claimed. No app code was changed during this validation
run.

## Actual audio observations

The physical TV reported volume 13 and unmuted before testing. The short Mute
button changed the observed state to muted with volume 0; a second press
restored unmuted and volume 13. The complete restore flow passed:
`/Users/amsh/worktrees/tvVNC/phone-validation-unmute.log`, with inspected
screenshots in `/Users/amsh/worktrees/tvVNC/phone-validation-unmute/screenshots`.
The earlier mute flow failed its selector because the accessibility node is
`Muted\nYes`, not a standalone `Yes`; its failure screenshot already showed
the muted state. That failed flow is not reported as passing.

The visible volume slider changed the TV's reported level from 13 to 3 without
the Sony credential error. Its run is
`/Users/amsh/worktrees/tvVNC/phone-validation-slider-set2.log`; the earlier run
never sent a tap because Maestro's percentage parser rejected a decimal.
The restore flow passed at
`/Users/amsh/worktrees/tvVNC/phone-validation-slider-restore.log`: the slider
returned to 13, Diagnostics independently showed volume 13 and unmuted, and
the app returned to Remote. Screenshots from that same run are in
`/Users/amsh/worktrees/tvVNC/phone-validation-slider-restore/screenshots`.
These ordinary single-output observations do not close the output-transition
or capability edge cases listed above.

The TV search editor was exited without submitting, returning to TiviMate's
navigation/guide. The phone's temporary USB keep-awake setting was restored to
its original value, 0. A subsequent optional attempt to return to fullscreen
playback did not reach its Back button: the phone reported keyguard showing.
No fullscreen-playback restoration is claimed, and no TV power operation was
performed in this validation run.

## Publication preparation

- GitHub CLI is authenticated as `amersheeny`; the empty public repository and
  release-tracking issue linked above now exist.
- Play Console is accessible under the Apptico LTD organization account. It
  shows no existing apps and an inactivity warning with a November 14 deadline.
  Account/pricing were confirmed by the user; no declarations were accepted.
- The app is GPL-3.0-or-later, with existing dependency notices. Two gitlinks
  still use local URLs; the maintained Android Remote and LibVNCServer forks
  must be publicly fetchable before source publication is usable.
- Redacted history scans found no leaks in the app or Android Remote library.
  Ten LibVNCServer findings are all ancestors of its upstream `origin/master`,
  not new private changes. Its current checkout scan found no leaks. Scan logs:
  `/Users/amsh/worktrees/tvVNC/release-main-secret-scan.log`,
  `/Users/amsh/worktrees/tvVNC/release-core-secret-scan.log`,
  `/Users/amsh/worktrees/tvVNC/release-vnc-secret-scan.log`, and
  `/Users/amsh/worktrees/tvVNC/release-vnc-current-secret-scan.log`.
- The installed APK passed the 16 KB ZIP-alignment check. That is not ELF
  segment, page-size runtime, release-AAB, or Play-delivery validation.
- Release currently signs with the debug key. A real upload/signing-key setup,
  secure key custody and backup, signed AAB, release runtime checks and exact
  artifact/source correspondence remain required. Do not uninstall the user's
  debug-signed app to replace its signature or destroy its pairing data.
- README keyboard instructions describe the older explicit Compose/Live UI and
  need updating. Store copy, privacy policy, Data safety, review-access
  instructions, real non-private store images, content rating and target
  audience declarations remain to be prepared and checked.
- No new global instructions, hooks or gates are authorized by this record.

Primary publication references checked for this task:

- [Android signing](https://developer.android.com/studio/publish/app-signing)
- [Android 16 KB compatibility](https://developer.android.com/guide/practices/page-sizes)
- [Create and set up a Play app](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)
- [Prepare a Play app for review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)
- [Data safety definitions](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Export compliance](https://support.google.com/googleplay/android-developer/answer/113770?hl=en)

Absence of analytics does not by itself settle the Data safety form: Google
defines collection in terms of off-device transmission and documents specific
exceptions. TV text/voice/control routes and plaintext VNC/Sony paths must be
classified against those definitions; do not claim universal encrypted transit.
