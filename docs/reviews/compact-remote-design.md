# Compact remote controls — 2026-09-22

The user's final placement is the THREE-DOT menu, not the hamburger menu and
not a footer mode selector. The remote view has no mode chips or full-size
power row. Its existing overflow menu contains checked Remote, Touchpad and
Direct touch choices before the connection actions. These are contextual to
the Remote page; Keyboard and other pages retain their existing menu. This
avoids a misleading mode checkmark on another page and creates no second
keyboard-exit/confirmation sequence.

Console owns the mode, retains it across page navigation, and resets it on
device/history reset. RemotePage receives the live property. Existing direct
touch confirmation is preserved, with device/page checks across the dialog.
Viewer already releases its pointer when the direct flag changes. The redundant
Touchpad drawer destination is removed as part of the user's requested move.

The user's subsequent explicit condition supersedes the power-footer plan:
do not present a remote-area power control unless it controls the TV itself.
Actual TV power remains unverified, so the remote currently contains neither
the large power row nor a replacement power icon. The three modes remain in
the overflow menu. No layout/command mapping or hold behavior is changed by
removing that misleading control.

The controller no longer disconnects channels after an unconfirmed power
request. A fresh Sony standby observation is required to pause retry policy;
a sent command alone is not an observation of the panel's power state.

## Plan review ledger

Independent Claude session 27799b89-9474-4dc0-81cb-a277c6feb939.
Artifacts: /Users/amsh/worktrees/tvVNC/compact-remote-plan-retry.log and
/Users/amsh/worktrees/tvVNC/compact-remote-menu-plan.log. Product reviewer:
/root/phase0_design_review, merged expert lenses.

- First critic session-capture blocker was withdrawn after examining
  TvController: remote-channel reconnect does not create a new Session.
  Device-bound/current-session routing nevertheless preserves prior semantics.
- Availability helper button-only theming: resolved by explicit availability
  subtitle in menu items, retaining explanation on tap.
- Mode selector's unnamed purpose: no longer exists after user moved choices
  to checked overflow items.
- Checkmark on unrelated pages and double-confirmation order: resolved by
  contextual mode items only on Remote, without introducing a Keyboard route.
- Product short-wide footer finding: scroll fallback now covers that branch.
- Six original fail-before tests describe commit 460e99e as originally written.
  Subsequent test edits implement the user's changed menu placement and the
  reviewed power ownership policy; they are not the original six-test artifact.

The earlier automatic keyboard build was installed on the Samsung test phone at
13:32:34 with install -r, no data clearing. Compact-layout rendering, final
code review, new installation and actual Sony text-prefill observation remain
separate evidence requirements; no fixture proves the last of these.
