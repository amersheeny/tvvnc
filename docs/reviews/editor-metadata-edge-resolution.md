# Native editor edge-case resolution — 2026-09-22

This is a scoped findings ledger, not release approval. User acceptance remains
live phone-to-TV editing, prefill, deletion and a usable exit. Installation is
independent of reviews; the physical Samsung is currently absent from ADB.

Product reviewer: `/root/phase0_design_review`.
Technical plan reviewer: Claude session
`27799b89-9474-4dc0-81cb-a277c6feb939`.
Plan artifact: `/Users/amsh/worktrees/tvVNC/editor-edge-plan-review.log`.
Disposition: AGREE on both returned product findings and the independently
reproduced focus/semantics cases; no product tradeoff or scope reduction.

## Findings and direct seams

1. TV-declared password protection survived reveal but not reveal → Clear →
   retype. The sensitivity getter now includes the TV's password metadata, so
   manual reveal and an empty local buffer cannot remove that classification.
   Read compositionChanged, replaceBuffer, keepCompose, background handling,
   clearDeclaredPassword and its changed/bindEditor callers. The old protected
   buffer is emptied before metadata is reset or a replacement field adopted.
   The fail-before test is
   `/Users/amsh/worktrees/tvVNC/editor-password-clear-before.log`; the current
   native-metadata widget tests cover privateText, disabled suggestions, cache
   exclusion and background clearing. No prior real-secret disclosure was
   observed or is asserted.
2. The phone could display Search while the native service received a different
   custom action ID. The settings model now retains the custom label; both the
   phone action mapping and explicit submission consult its presence. The
   existing Send position uses the TV's label for a bound/live custom action,
   with generic Send only for a blank label. Standard fields retain their
   normal phone action. Custom multiline fields retain newline and expose the
   custom command separately. The same successful-flush, target and revision
   checks precede dispatch. No new app-authored string or protocol was added.
   Fail-before: `/Users/amsh/worktrees/tvVNC/editor-custom-before.log`.
3. The custom success branch must not guess that an arbitrary action means
   Done. It retains focus; next-field metadata is still authoritative. A
   further seam test showed the configuration-reattachment helper dropping
   focus when Next/custom changed input type before the action completed.
   That helper now preserves an active, not-user-dismissed field independently
   of the command's finishing flag. Explicit page exit still unfocuses first.
   Both standard Next and custom cases failed before in
   `/Users/amsh/worktrees/tvVNC/editor-next-focus-before.log` and pass now.
4. Mouse/stylus editing-button taps could unfocus the field. The documented
   TextFieldTapRegion groups the editor controls, leaving preview/navigation
   outside. Fail-before: `/Users/amsh/worktrees/tvVNC/editor-focus-before.log`.
   This mouse test is not evidence that finger taps followed that mechanism.
5. The real emulator failure was separate: the editable accessibility node
   included Paste/Send/Clear. Its bounds were `[32,1084][1049,1378]`, so a
   coordinate tap at its center missed the visible field. A field Semantics
   boundary keeps those controls separate. The independent size assertion
   failed with a 168-dp semantic height versus a 64-dp field, then passed with
   equality. Logs: `/Users/amsh/worktrees/tvVNC/editor-semantic-before.log` and
   `/Users/amsh/worktrees/tvVNC/editor-semantic-after.log`.

The actual Maestro 2.1.0 driver was traced through clickExt, clickNoSync and
the installed Configurator: it injects touchscreen source 4098 and finger
tool type 1. Thus the emulator's miss was not relabelled as a mouse event.
The examined generated sources are outside the repository at
`/Users/amsh/worktrees/tvVNC/maestro-interaction-analysis.java` and
`/Users/amsh/worktrees/tvVNC/maestro-configurator-analysis.java`.

## Executed evidence

Application checkpoint `163ef6d`, native library `a17e093`.
APK `/Users/amsh/worktrees/tvVNC/releases/tvvnc-163ef6d-debug.apk` has SHA-256
`2db9ef574f6181fb373a8df7530015ed916a752a92e1a68407a18bfb8aa23dce`.
It is installed on the headed emulator, not on the disconnected Samsung.

- All 153 Flutter tests pass in
  `/Users/amsh/worktrees/tvVNC/editor-edges-final-tests.log`; analyzer is clean
  in `/Users/amsh/worktrees/tvVNC/editor-edges-final-analyze.log`.
- Real app TLS re-pairing, prefill, immediate edits/backspace and standard
  Search passed in `/Users/amsh/worktrees/tvVNC/editor-edges-pair-edit.log`.
- Cursor-left then typing passed in
  `/Users/amsh/worktrees/tvVNC/editor-edges-cursor.log`: the phone displays
  `Example searcXh`; the independent receiver records selection 13 then an
  insertion with length 15 and selection 14.
- Custom action passed in
  `/Users/amsh/worktrees/tvVNC/editor-edges-custom.log`: the labelled button
  sends ID 91, then another typed character arrives without reopening the IME.
- Reveal/Clear/retype/background passed in
  `/Users/amsh/worktrees/tvVNC/editor-edges-password-clear2.log` with retained
  privacy feedback and remasked prefill on return. The first run's privacy
  label assertion was below the visible viewport; the corrected test scrolls
  to it rather than removing that assertion.
- The last three run directories contain their inspected screenshots. The
  independent wire-event log is
  `/Users/amsh/worktrees/tvVNC/editor-fixture2.log`; it records lengths,
  selection and action IDs, never editor text.

The RFB fixture is a color pattern, not the rendered TV editor. These runs do
not establish the new behavior on the physical Sony. Full release review,
production signing, copy-gate approval and Play submission remain open in
https://github.com/amersheeny/tvvnc/issues/1.
