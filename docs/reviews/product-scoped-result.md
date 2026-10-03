# Product review — scoped emulator result

Reviewer: `/root/phase0_design_review`, all merged specialist lenses.
Product source: `dd21473`; APK SHA256
`eb8869c27fc87973eca1bf090d3481e23abf23ae1350113a6edeedc26f449fd9`.

The reviewer reported no new concrete product-design findings in the inspected
source/rendered scope after the final wrapper and sensitive-buffer corrections.
This is not Sony hardware acceptance or comprehensive accessibility certification.

- Full-width unavailable controls retain their info marker within the hit area.
  The All buttons Home fill measures 994 pixels versus 149 before the correction.
  A 500 dp width/marker-tap regression passes.
- Active Undo bars at normal/2× identify the original TV, shortcut and deletion
  number. Dismiss advances deletion 2→3; Undo restores the second item's actual
  Wait-for-TV step, not the earlier same-named Home sequence.
- Revealed sensitive text remains in Gboard incognito mode with suggestions and
  learning disabled. Clear restores ordinary multiline input and learning.
- Permanent denial→Android app settings→Nearby devices Allow→return removes
  the permission-denial panel. All flow steps completed before a runner-only
  log-close warning; the app did not fail.
- Measured contrast: unavailable control 13.264:1 light / 9.571:1 dark;
  Undo text/Dismiss 11.555:1; Undo action 7.698:1.

Evidence roots:

- `/Users/amsh/worktrees/tvVNC/review3-ui/viewer-rebooted/2026-09-21_053653/viewer/takeScreenshot`
- `/Users/amsh/worktrees/tvVNC/review3-ui/screens/2026-09-21_054138/screens/takeScreenshot`
- `/Users/amsh/worktrees/tvVNC/review3-ui/large/2026-09-21_054248/large_text/takeScreenshot`
- `/Users/amsh/worktrees/tvVNC/review3-ui/reveal/2026-09-21_054325/private_reveal/takeScreenshot`
- `/Users/amsh/worktrees/tvVNC/review3-ui/undo/2026-09-21_054425/undo_queue/takeScreenshot`
- `/Users/amsh/worktrees/tvVNC/review3-ui/undo-large/2026-09-21_054532/undo_queue_large/takeScreenshot`
- `/Users/amsh/worktrees/tvVNC/review3-ui/final-permission/2026-09-21_052726/network_permanent_denial37/takeScreenshot`
- `/Users/amsh/worktrees/tvVNC/review3-e2e-exits.tsv`

The subsequent unchanged-APK evidence closed the two remaining scoped emulator
checks, with no new findings:

- 4K: completed flow/captures at
  `/Users/amsh/worktrees/tvVNC/review3-ui/4k/2026-09-21_055338/viewer_4k/takeScreenshot`;
  exported `/Users/amsh/worktrees/tvVNC/final-exported-4k.png` measures 3840×2160.
  Actual size retains target identity and controls.
- TalkBack: `/Users/amsh/worktrees/tvVNC/final-talkback-bound.log` confirms binding
  and touch exploration before the measured gesture. A single kernel-emulated
  finger touch focuses Right in
  `/Users/amsh/worktrees/tvVNC/final-talkback-focused.png` without a key event:
  the fixture remains at four KEY lines, through sequence 2. A timed hardware
  double tap emits exactly one down/up pair, sequence 3, and changes the frame:
  `/Users/amsh/worktrees/tvVNC/final-talkback-activated.png`,
  `/Users/amsh/worktrees/tvVNC/fixture-review3-4k.log` and
  `/Users/amsh/worktrees/tvVNC/final-talkback-after.log`.
  An earlier touch occurred before the service bound; it produced sequence 2
  and is explicitly excluded from accessibility evidence.

The no-audio emulator does not establish audible speech quality. Negotiated
voice states, actual Sony catalogs/power/input/audio/holds, and fixed physical
controller performance remain unproven. The unapplied copy-gate proposal also
awaits the user's exact-diff approval. Neither limitation is converted into a
pass or an unsupported feature label.
