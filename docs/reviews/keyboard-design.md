# Keyboard repair acceptance and reviewed design

The user confirmed native Android TV pairing works. This change must prefill
the focused TV text, open the phone IME on entry, and provide an explicit exit.
Preview resizing follows keyboard implementation and validation.

## State and text ownership

- A present native editor, including an empty one, binds automatically. Prefill
  copies text and clamped UTF-16 selection without sending a command.
- On 2026-09-22 the user explicitly removed the Compose/Live edit choices.
  The ordinary fallback bar still has its separate phone draft. A late editor may take over an
  untouched entry, including a briefly displayed saved draft. Its original
  cache key is retained across page recreation; fallback entry returns to that draft
  without overwriting another application's saved draft. A field tap, later
  caret movement, typing or Paste/Send beginning disarms automatic adoption.
  Masking an empty untouched field alone does not prevent prefill. Prefill sends nothing.
  Saved fallback drafts are restored on entry/re-entry and on a change to a
  context with a saved draft and no reported native field. Native text takes
  priority on pristine entry; there is no manual draft or transport selector.
- A first session snapshot may arrive after Keyboard opens, with or without
  the editor. Discovery of that first target must not erase phone typing.
  Genuine target/session changes retain the existing privacy/context rules.
- Clean Live follows field/counter refreshes. A dirty or composing old field
  pauses and retains its text on this page without caching or replaying it.
- **Load TV text replaces a protected local buffer with the last reported TV text.**
  It is an exceptional recovery action, never a normal-operation mode choice.
  Its adjacent warning explains the replacement. A late-arriving editor never
  automatically sends a phone-only draft; explicit Send retains insertion at
  the TV cursor. An ordinary paused native edit can be sent as a replacement
  only after confirmation tied to the captured target, revision and value.
  Missing/just-submitted fields remain unwritable until eligible data arrives.
- Imported Live/paused buffers never enter saved drafts or IME learning. Private
  masking and clearing survive context changes, backgrounding, and disposal.
- Older same-revision echoes cannot replace local edits or move the phone caret.
- Ordinary unsent/ambiguous native edits survive backgrounding and same-TV
  reconnection as paused buffers, never cached or replayed. Clean native mirrors
  follow reported state on resume. Sensitive buffers still clear. Mask/reveal
  preserves pending-send ownership; only pending clipboard reads are invalidated.
- A matching native counter update retains an already received field snapshot.
  Known counters for a different field cannot be used to send the current edit.
  That refusal retains the local buffer and shows an accessible persistent
  notice; automatic typing dispatch stops until a deliberate Send/exit attempt.
  No timer, snapshot or reconnect replays the buffer. The initial zero-counter
  behavior remains until the server supplies counters. Actual Sony counter
  timing remains unverified without the paired phone connected.

## Focus and navigation

- The page owns the input FocusNode and requests focus once after entry. Changing
  the security-mode input client also replaces its node, preserving active focus
  with a fresh keyboard token. Flutter FocusNode.requestFocus is a no-op for an
  already-primary node; a new EditableText otherwise remains detached. This was
  reproduced by three native-input-client widget regressions and inspected in
  the installed Flutter focus_manager.dart and editable_text.dart sources.
- Actual IME dismissal is tracked from visible-to-hidden window insets, so
  updates do not reopen a dismissed keyboard. No raw text-input channel call.
- The phone field has a 48 dp Hide text/Show text eye control rather than a
  privacy chip. Revealing does not remove sticky cache/learning protections;
  the clearing helper remains visible for the protected buffer.
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
  into a submitted or replaced field. The fallback bar retains direct TV editing keys.
- Exact fallback labels supplied back to the independent copy reviewer:
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
changes, without affecting TV commands. Deliberate pane/window resizing refits;
IME-only resizing preserves manual zoom, per the 2026-09-22 user revision.
