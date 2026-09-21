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

The existing per-page viewer defaults are retained, plus the resize band where
space permits. The band is at least 48 dp and uses labelMedium with normal text
scaling, allowing wrapping instead of clipping. Its border is foreground paint
and consumes no layout padding. Text metrics match its actual style, available
width, scaling, and direction. The measured band is included in the pane budget.

Keyboard's actual essential editor block is measured after layout via a
post-frame callback. SizeChangedLayoutNotification only schedules that callback;
it never sets state or changes layout during layout. Measurement is deduplicated
and only changes the reserve when the actual block size changes. This protects
the field/actions when text and mode chips wrap; independent scrolling remains
available. Under a 192 dp stacked body, whole-page scrolling prevents overflow.

At widths over 760 dp, the Keyboard uses a 3:2 viewer/editor arrangement, approved
at pre-design by the product-design reviewer. Remote retains its existing 3:2
wide arrangement. Both have the handle below the left view and independently
scrollable right controls. Shortening the left view leaves empty space below it.
GlobalKeys preserve the pane, editor list and essential input subtree across
layout branches, avoiding needless input-client disposal during rotation.
The preserving key is above the TextField; the field retains its separate
security-mode ValueKey, so toggling privacy still replaces the native client.

The band uses synchronous text measurement because its height is part of the
minimum pane allocation in the same frame. Post-frame band measurement can
temporarily allocate less than the 48 dp viewer toolbar plus the actual wrapped
band, producing an initial overflow at large scale. Unlike the arbitrary editor
block, the band contains one known label; width, merged theme/bold style, locale,
direction and scaler are shared with its Text render. Rendered large-text/RTL
checks and the foreground-only border cover the correspondence.

The viewer keeps all existing geometry-change input release, pointer clearing,
and frame reset behavior. Fit mode reflows; manual zoom/pan and Actual size keep
scale and viewing-center anchor during viewport-only changes. Pending geometry
callbacks are generation-fenced. Fullscreen is independent of pane sizing.

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
announcements remain useful. Touch dragging does not request keyboard focus.
Target, orientation/constraint changes and lifecycle interruption cancel drag
tracking. Handle events never become TV commands.

Copy: docs/reviews/copy-keyboard-controls.md and
docs/reviews/copy-screen-height-value.md, both independent content-review records.
The latter approves the percentage template with a whole-number placeholder.

Required proof: full Flutter tests/analyzer, release build, actual headed
portrait/wide/IME/large-text/dark/hidden-restored/Direct-touch captures, accessible
resize, zoom/Actual-size preservation, native protocol smoke, and installation
on the physical phone without resetting credentials. Fixture rendering is not
proof of the Sony's reported text or captured content.
