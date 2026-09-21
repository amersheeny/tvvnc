# Keyboard repair acceptance and reviewed design

The user confirmed native Android TV pairing works. This change must prefill
the focused TV text, open the phone IME on entry, and provide an explicit exit.
Preview resizing follows keyboard implementation and validation.

## State and text ownership

- A present native editor, including an empty one, opens in Live edit. Prefill
  copies text and clamped UTF-16 selection without sending a command.
- Compose has a separate ordinary draft. A late editor may take over only an
  untouched, empty entry, never a saved draft, explicit mode choice, or typing.
- Clean Live follows field/counter refreshes. A dirty or composing old field
  pauses and retains its text on this page without caching or replaying it.
- **Selecting Live edit while paused replaces the retained text with TV text.**
  This is deliberate reload, not lossless recovery. The warning says so. Both
  mode chips are unselected while paused, and Send is disabled.
- Imported Live/paused buffers never enter saved drafts or IME learning. Private
  masking and clearing survive context changes, backgrounding, and disposal.
- Older same-revision echoes cannot replace local edits or move the phone caret.

## Focus and navigation

- The page owns the input FocusNode and requests focus once after entry. Changing
  the security-mode input client also replaces its node, preserving active focus
  with a fresh keyboard token. Flutter FocusNode.requestFocus is a no-op for an
  already-primary node; a new EditableText otherwise remains detached. This was
  reproduced by three native-input-client widget regressions and inspected in
  the installed Flutter focus_manager.dart and editable_text.dart sources.
- Actual IME dismissal is tracked from visible-to-hidden window insets, so
  updates do not reopen a dismissed keyboard. No raw text-input channel call.
- Leave Keyboard replaces Your TVs in the shared appbar only on this page. The
  drawer retains Your TVs. Exit returns to the captured previous app page, never
  emits TV Back, and never sends from deactivate/dispose.
- Deliberate exits ask the mounted page to commit its visible composition and
  drain pending Live updates in order. Failed/unknown delivery is not replayed;
  an explicit confirmation permits leaving or retaining the editor.
- PopScope stands down while the drawer is open. Other routes retain their own
  Back handling. Deferred navigation checks that page, device and session still
  match. A GlobalKey represents the one mounted Keyboard page; changing TV
  currently unmounts it by resetting Console history.

## Editing keys

- In Live/paused modes, Backspace/Delete and cursor buttons edit the local mirror
  on grapheme boundaries. Each deletion schedules the existing debounce; cursor
  motion alone does not send a text replacement. Active Live streams edits.
- Local repeat has its own timer. Pointer release/cancel, mode invalidation,
  backgrounding, context change, explicit exit and dispose all stop it. It is
  not the native TV-generated key-repeat mechanism.
- Enter on TV flushes before sending key66, then visibly pauses to avoid replay
  into a submitted or replaced field. Compose retains direct TV editing keys.
- Exact Compose labels supplied back to the independent copy reviewer:
  TV editing keys; These keys act on the TV, not the draft above.; Backspace on TV;
  Delete on TV; Move cursor left on TV; Move cursor right on TV; Enter on TV.
  Copy records carry the review session and literal verdicts, not self-approval.

## Proof required before a completion claim

Full Flutter tests and analyzer; exact release build/protocol smoke; actual
headed-emulator keyboard/IME/Back/Close/private states; physical-phone installation
preserving credentials and real TV non-sensitive text prefill/edit confirmation.
Fixture tests do not establish what this Sony reports. No TV-sensitive text or
pairing secrets in captures, logs or diagnostic reports. The draggable viewing
pane must subsequently be tested in Remote and Keyboard, with IME and orientation
changes, without affecting TV commands or discarding manual zoom.
