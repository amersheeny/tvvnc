# Draggable TV pane

The user requested changing the TV-view height by dragging its bottom edge,
after the keyboard repair. Keyboard build 54c84f8 was installed on the Samsung
phone before this feature was implemented.

Two ValueNotifiers on TvModel retain preferred heights for Remote (including
Touchpad/Direct touch) and Keyboard. Only the pane subscribes; transport and
Console notifications are not involved. Temporary clamping, hiding, and changes
to keyboard/orientation constraints never overwrite the preference. A drag
begins at the effective height; trying to drag farther at a bound does not erase
a larger temporarily clamped preference.

On 2026-09-22 the user explicitly replaced the labeled band with a thin,
unlabeled grip above the viewing icons. The grip is 48 × 4 dp inside an 8 dp
strip. Together with the existing 48 dp toolbar it occupies 56 dp, rather than
the old 96 dp minimum. No visible label or tooltip is shown.

The vertical resize gesture belongs to the existing toolbar chrome, not an
overlay over TV pixels. Child icon taps and horizontal scrolling retain their
own gesture recognizers. The adjustable semantic container preserves individual
button nodes. At a fixed resize range the vertical recognizer is omitted, so
whole-page scrolling remains available even below the 56 dp chrome floor.

Keyboard's actual essential editor block is measured after layout via a
post-frame callback. SizeChangedLayoutNotification only schedules that callback;
it never sets state or changes layout during layout. Measurement is deduplicated
and only changes the reserve when the actual block size changes. This protects
the field/actions when text and mode chips wrap; independent scrolling remains
available. Under a 192 dp stacked body, whole-page scrolling prevents overflow.

At widths over 760 dp, the Keyboard uses a 3:2 viewer/editor arrangement, approved
at pre-design by the product-design reviewer. Remote retains its existing 3:2
wide arrangement. Both have the handle above the left viewing toolbar and independently
scrollable right controls. Shortening the left view leaves empty space below it.
GlobalKeys preserve the pane, editor list and essential input subtree across
layout branches, avoiding needless input-client disposal during rotation.
The preserving key is above the TextField; the field retains its separate
security-mode ValueKey, so toggling privacy still replaces the native client.

The separator no longer needs text measurement. Both wide layouts require at
least 56 dp; smaller bodies use the existing whole-page scrolling fallback.
The compact menu is used only for very short panes whose width cannot fit the
eight 48 dp controls. A wide pane keeps its full toolbar even at minimum height;
collapsing it into a menu would not save vertical space.

The viewer keeps all existing geometry-change input release, pointer clearing,
and frame reset behavior. The user’s new resize policy supersedes sticky zoom:
an actual handle adjustment or window-size change arms aspect-preserving Fit.
An adjustment stopped by a bound does not erase a chosen zoom. IME-only changes
retain manual zoom/pan/Actual size, including the menu hiding and restoring the
keyboard. Ordinary framebuffer updates never reset a chosen zoom. Pending
geometry callbacks remain generation-fenced. Fullscreen is independent of pane
sizing but also refits when its window size changes.

The product review identified a concrete case that revises the earlier plan
audit's conclusion about external cancellation: when a TV pointer is held and
a second finger touches the handle AT A SIZE BOUND, there is no geometry change,
so geometry-change release never runs. Handle pointer-down therefore calls the
viewer's narrow cancelPointerInput method, also used by accessible adjustments.
No separate external geometry-change release was added. A regression covers
this exact held-pointer-at-bound case.

The handle is a focusable adjustable semantic control with reviewed percentage
value and increased/decreased values. Up/Down and accessibility actions use at
least 16 dp, increased to 1% for unusually tall content areas so whole-number
announcements remain useful. Arrow handling is restricted to the adjuster’s
primary focus, not a child button’s focus. Touch dragging does not request keyboard focus.
Target, orientation/constraint changes and lifecycle interruption cancel drag
tracking. Handle events never become TV commands.

Copy: docs/reviews/copy-keyboard-controls.md and
docs/reviews/copy-screen-height-value.md, both independent content-review records.
The latter approves the percentage template with a whole-number placeholder.

Required proof: full Flutter tests/analyzer, release build, actual headed
portrait/wide/IME/large-text/dark/hidden-restored/Direct-touch captures, accessible
resize, explicit refitting and IME-only zoom preservation, native protocol smoke, and installation
on the physical phone without resetting credentials. Fixture rendering is not
proof of the Sony's reported text or captured content.
