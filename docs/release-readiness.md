# TV VNC release status — 2026-09-22

Publication is requested but not complete. No public repository, GitHub release,
Play app entry or Play submission has been created. The installed application
remains the data-preserving development build, not a Play-signed release.

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

## Outstanding control repairs

All items below are HIGH-priority release work, not completed fixes. There is
currently no repository remote or issue tracker; carry these entries into the
publication pull request's findings ledger when that exists.

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

- GitHub CLI is authenticated as `amersheeny`; `amersheeny/tvvnc` does not exist.
- Play Console is accessible under the Apptico LTD organization account. It
  shows no existing apps and an inactivity warning with a November 14 deadline.
  Account/pricing confirmation is pending; no declarations were accepted.
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
