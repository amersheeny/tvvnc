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

One neutral 24 dp power icon occupies a 48 dp target below the control list.
Its menu preserves explicit on, off and toggle actions; opening sends nothing.
Device ownership is captured at opening, capability and session at selection.
Unavailable items show existing availability wording and remain tappable for
the explanation. Unknown capability still permits an attempt.

The footer is pinned in ordinary portrait/wide layouts without overlaying the
list. On an extremely short wide column (<56+48 dp) it scrolls with that list;
the existing narrow whole-page-scroll layout also includes it in content.
No transport, command mapping, hold semantics, custom button order or copy is
changed.

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
