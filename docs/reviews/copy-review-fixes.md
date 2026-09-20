REVIEW-ID: c7598a74-2b68-4f63-a4d3-ba4570a5c227
DATE: 2026-09-21
REVIEWER: content-strategist (Claude CLI, cross-model, existing copy-only session; new-session branch guard required reuse)
ARTIFACT: docs/reviews/copy-review-fixes.md
DESCRIPTOR: none — derived from reviewed string inventory and real screen captures in brief

`★ Insight ─────────────────────────────────────`
- The Diagnostics capture settles the first two strings on its own: nine consecutive rows — TV, Current input, Current app, Volume, Muted, Network MAC address, Model, Software version, Remote service version — all read **"Not checked yet"**. One string is currently doing two jobs, and the result is a column with no information in it. Splitting "Unknown" (asked, no reliable answer) from "Not checked yet" (never asked) is what makes that column readable.
- The Keyboard capture shows the five TV-key buttons are **icon-only**, and the second icon is a **trash can** sitting directly beneath the word **Clear**. A sighted user has every reason to read that trash can as "empty my draft". The proposed heading and body are not decoration — they are the only thing standing between the user and deleting the wrong thing.
- Three of the rewrites below come from a single habit: a second sentence that names a place or a state instead of a control the user can actually operate. "Check Diagnostics" is a dead end when the message renders inside Diagnostics; "Reconnect the viewer" names a noun that appears nowhere on screen; "Add a star" renames an action the app already calls Add to favorites.
`─────────────────────────────────────────────────`

BRIEF DEFECT: The role given for `liveScreen` states it is "also a deterministic UI test observable" — that is, the wording doubles as a hook that an automated test matches on. That is an implementation dependency, it carries no provenance as a fact about the reader's experience, and the brief's own rule says only the reader's experience matters and implementation cost does not. The constraint is void and was disregarded; the verdict below was decided on reader grounds alone, and the string must remain free to change if a future review finds a better one.

BRIEF DEFECT: No other constraint in the brief lacks provenance. The factual-behaviour statements are all sourced to the call-path reading and screenshot comparison dated 2026-09-21, the brief explicitly disclaims string-budget limits, and it states that no localization constraints apply. Reporting one defect rather than a list is the accurate result, not a shortened one.

OUT-OF-SCOPE OBSERVATION (no verdict, not part of the 33): the shortcut editor capture shows the screen titled **"Shortcuts"** while it edits exactly one shortcut, with an empty "Shortcut name" field and a single "Add step" button beneath it. The section name has been reused as the screen name, so the title does not say whether the user is creating or editing. That string is not in this review set and no verdict is issued on it.

STRING: unknown
KEYS: unknown
ENGLISH: "Unknown"
VERDICT: APPROVE
REASONING: This is the right word for the state the brief defines — a value the app asked for and did not get reliably — and the rendered Diagnostics screen shows exactly why the split from "Not checked yet" is needed rather than cosmetic: every one of the nine value slots on that screen currently reads "Not checked yet", which tells the reader nothing about which values were attempted and came back empty. "Unknown" is the conventional, shortest value for a diagnostics column, it reads cleanly aloud in the row pattern a screen reader produces ("Current input, Unknown"), and it sits naturally in the existing value family alongside Ready, Not connected, Needs setup and Temporarily unavailable. Critically, it still does not claim the capability is absent, which is the distinction this app has been careful to protect everywhere else.
RISKS: none

STRING: notCheckedYet
KEYS: notCheckedYet
ENGLISH: "Not checked yet"
VERDICT: APPROVE
REASONING: The text is unchanged from the string already shipping and rendered in the Diagnostics capture, and the state it now names is narrower than before — the brief restricts it to a capability whose observation time is zero, meaning nothing has ever been recorded. The words fit that narrowed meaning exactly: "yet" promises the check is still to come, which is true only for a value never observed, and would have been a small lie in the case now handed to "Unknown". Keeping the wording identical while tightening the trigger means no user has to relearn anything, and the two values now differ in meaning in a way the words themselves carry.
RISKS: none

STRING: tvEditingKeys
KEYS: tvEditingKeys
ENGLISH: "TV editing keys"
VERDICT: APPROVE
REASONING: The Keyboard capture makes the case for this heading better than any argument could: the five buttons it labels are icon-only circles, and the row sits immediately below Paste, Send and Clear, with the second icon rendered as a trash can directly under the word Clear. Without a heading, a sighted user scanning that screen has no grouping cue at all and a reasonable path to reading the trash icon as "empty my draft". "TV editing keys" supplies the grouping and the target in three words, uses the product's own noun for the device, and reads correctly aloud as a heading before the five buttons are announced. "Editing" is accurate for the set it covers — backspace, delete, cursor left, cursor right and enter are text-editing keys and nothing else.
RISKS: none

STRING: tvEditingBody
KEYS: tvEditingBody
ENGLISH: "These keys act on the TV, not the draft above."
VERDICT: APPROVE
REASONING: The spatial claim is true in the rendered layout — the Keyboard capture shows the text field with the hint "Type or paste text" sitting above the key row, with Paste, Send and Clear between them — so "above" points at something really above. "Draft" is the load-bearing word and is worth keeping over a plainer "text": the entire risk this sentence exists to remove is that a user presses the trash icon expecting to clear unsent text they typed on the phone, and "draft" is the ordinary English word that carries "not sent yet". The sentence states the contrast in one short line rather than explaining the mechanism, which is the correct depth for a body line under a heading. It assumes the Compose contrast the brief describes, which is the state in which the confusion actually occurs.
RISKS: length. The private-text capture shows that when the software keyboard is open it covers the lower part of this screen, and the existing one-sentence privacy disclosure is already clipped mid-way through its second line ("Private text is cleared when you leave the Keyboard or switch TVs" renders with the second line cut). A body line longer than this one would be clipped the same way, so this string should not grow.

STRING: tvBackspace
KEYS: tvBackspace
ENGLISH: "Backspace on TV"
VERDICT: APPROVE
REASONING: This is the existing key name plus the qualifier that separates it from the phone-side "Backspace" already in the string table, which is exactly the disambiguation an accessible label on an icon-only button has to supply. The capture confirms the button carries no visible text, so this label is the only thing a screen-reader user receives, and it reads cleanly aloud as "Backspace on TV, button". Keeping the bare key name first and the qualifier last means the five labels in this row all scan the same way and the distinguishing word lands in the same position every time.
RISKS: none

STRING: tvDelete
KEYS: tvDelete
ENGLISH: "Delete on TV"
VERDICT: APPROVE
REASONING: Same construction as its neighbours, and it is the label carrying the most weight in the group, because the capture shows this button rendered as a trash can positioned directly beneath the word Clear. A screen-reader user hears "Delete on TV, button" and is told the target; the two words "on TV" are the whole defence against the reading "delete what I typed here". The label cannot fix the icon choice itself, which is a visual-design question outside this review, but the wording does everything wording can do, and the section heading and body reinforce it for users who are reading rather than listening.
RISKS: none

STRING: tvCursorLeft
KEYS: tvCursorLeft
ENGLISH: "Move cursor left on TV"
VERDICT: APPROVE
REASONING: The label names the action rather than a key, which is correct because there is no single key name for this movement, and it keeps the "on TV" qualifier in the same final position as its siblings so the row stays uniform when read aloud. "Cursor" is ordinary vocabulary for the stated audience of a technically comfortable adult, and it is more precise than alternatives like "move left", which would not say what moves. The verb-phrase form alongside the bare-key-name form of its neighbours is not an inconsistency: Backspace, Delete and Enter have names, and cursor movement does not.
RISKS: RTL. "Left" here is a text-cursor direction, not a physical pad direction, so unlike the existing D-pad Left and Right labels it is not automatically stable across writing directions. A translator into a right-to-left language has to be told whether this key moves the insertion point toward the start of the text or toward the physical left of the screen; the English is unambiguous only because English runs left to right.

STRING: tvCursorRight
KEYS: tvCursorRight
ENGLISH: "Move cursor right on TV"
VERDICT: APPROVE
REASONING: Exact mirror of its pair, with the same verb, the same object and the same trailing qualifier, which is what keeps the two announcements distinguishable by one word when a screen-reader user moves between the two adjacent buttons. Approving it on the same grounds as the left variant is required rather than incidental: these two are a single class and a judgement that held for one would have to hold for the other.
RISKS: RTL. Identical to the left variant — the direction is text-relative rather than physical, and the translator must be told which reading applies.

STRING: tvEnter
KEYS: tvEnter
ENGLISH: "Enter on TV"
VERDICT: APPROVE
REASONING: Completes the five-label pattern with the key's own name and the qualifier that separates it from the phone-side "Enter" already in the table. The capture shows this button as a return-arrow icon with no text, so the label is again the only information a screen-reader user gets, and "Enter on TV" states both the key and its target in three words. Nothing here needs a verb phrase because Enter is the name of the key on every keyboard the user has met.
RISKS: none

STRING: touchpadHelp
KEYS: touchpadHelp
ENGLISH: "Swipe to move. Tap for OK."
VERDICT: APPROVE
REASONING: Two short sentences, each mapping one gesture to one result, with "OK" matching the product's own name for the centre control. The obvious objection is that "move" does not say what moves, and the Remote capture shows the TV picture with its own Fit and Zoom controls sitting on the same screen, so a reader could in principle wonder whether swiping pans the picture. That objection does not survive the placement: the instruction renders inside the touch area itself, which is a separate surface from the picture and its toolbar, and one swipe resolves any doubt. The stronger reason not to rewrite is that every specific alternative requires asserting a movement model — whether a swipe produces discrete directional presses or continuous pointer movement — and the brief establishes neither. A vague instruction that is true costs the reader one swipe; a specific instruction that is wrong costs them their confidence in everything else the screen says.
RISKS: length. The large-text capture shows the mode chips already wrapping from one row to two at the largest text setting, so this instruction will wrap inside the touch area at that size; two short sentences wrap acceptably, a longer single sentence would not.

STRING: touchpadHold
KEYS: touchpadHold
ENGLISH: "Press and hold for a long OK press."
VERDICT: REWORD
REWRITE: "Touch and hold for a long press of OK."
REASONING: Two things are wrong and one rewrite fixes both. First, the gesture verb belongs to the wrong surface: the app already uses "Press and hold" as the label for holding a remote *button*, and this string describes a gesture on a *touch area*, which the platform's own accessibility vocabulary calls touch and hold. Using the two phrases for the two different physical actions makes them distinguishable instead of interchangeable. Second, the draft stacks "Press" and "press" seven words apart with "OK press" as a compound, which is a genuine stumble when the line is read aloud in a touch area a screen-reader user is exploring; "a long press of OK" unpacks the compound and lets the sentence land. The meaning is unchanged and the length is the same to within a character.
RISKS: length. As with the movement instruction, the large-text capture shows this screen already wrapping its chips at the largest text setting, so this line will occupy two rows inside the touch area there.

STRING: noMatchingApps
KEYS: noMatchingApps
ENGLISH: "No apps match this search."
VERDICT: APPROVE
REASONING: Accurate, complete, and carefully scoped to the search rather than to the catalogue — it says these particular words matched nothing, not that the TV has no apps, which is the distinction this app protects everywhere and which the rendered Apps screen depends on, since the unavailable-catalogue case has its own separate message. No next step is offered and none is needed: when a search returns nothing, changing the search is the only move available and the search field is directly above. Adding "Try a different search" would be padding that a reader has to process before getting back to the field.
RISKS: none

STRING: noFavorites
KEYS: noFavorites
ENGLISH: "No favorite apps yet. Add a star to an app in the Apps list."
VERDICT: REWORD
REWRITE: "No favorite apps yet. Choose Add to favorites on an app in the Apps list."
REASONING: The second sentence invents a name for an action the product has already named. The control's own label is "Add to favorites" — that is what a screen-reader user hears when they reach the star, and it is what the app's string table calls it — whereas "Add a star to an app" is a third description that appears nowhere else, and "add a star to" is not even the idiom for the gesture ("star an app" or "tap the star" would be). A user told to add a star and then hearing "Add to favorites" has to bridge the gap themselves. The replacement uses the exact control name and adopts the construction the app already uses for this job elsewhere, "Choose Connect to send controls", so the instruction and the control now match word for word. The first sentence is kept: "yet" is right here because favourites fill through a deliberate action the user has not taken.
RISKS: length. The Apps capture shows an empty-state line of comparable length wrapping to two rows in this position, which renders legibly; this replacement is a few words longer and will wrap the same way.

STRING: noRecentApps
KEYS: noRecentApps
ENGLISH: "No recently launched apps."
VERDICT: APPROVE
REASONING: True, short, and it does the useful secondary job of explaining what the Recent chip collects, which a user meeting an empty list needs more than an instruction. Two changes were considered and rejected for specific reasons. Adding "yet" to match the favourites line would imply the list is simply waiting to fill, but the brief defines this state as "none of the currently catalogued apps appear in the stored recent list", which an app can also leave by dropping out of the catalogue — so "yet" would overstate. Adding a how-to to match the favourites line would require saying which launches are recorded, and the brief establishes that the list is stored but not what populates it; inventing that would be worse than omitting it. The asymmetry with the favourites empty state is therefore principled rather than sloppy: favourites has a control to point at, and this list does not.
RISKS: none

STRING: shortcutRemoved
KEYS: shortcutRemoved
ENGLISH: "Shortcut deleted."
VERDICT: APPROVE
REASONING: The verb matches the control the user just used — the shortcut cards offer run, edit and delete — so the confirmation echoes the action rather than renaming it, which is what lets a user confirm at a glance that the thing they intended is the thing that happened. It is also correctly distinct from "Forget", which this app reserves for removing a saved TV; keeping two different removal verbs for two different objects is what stops a snackbar being ambiguous about what just disappeared. The sentence is complete and stops there, leaving the recovery action to the button beside it.
RISKS: none

STRING: undo
KEYS: undo
ENGLISH: "Undo"
VERDICT: APPROVE
REASONING: The platform-standard action word for this exact pattern, scoped by the snackbar it sits in, so the reader does not have to be told what will be undone. The brief notes real limits — the restore will not overwrite a newer shortcut carrying the same identifier and will not recreate a TV that has since been forgotten — but both of those require the user to perform another substantial action inside the few seconds a snackbar lives, and qualifying a snackbar action for them would make the common case worse to serve an almost unreachable one. One word is also the right length for a control that must not crowd the message beside it.
RISKS: none

STRING: sonyRegistrationTitle
KEYS: sonyRegistrationTitle
ENGLISH: "Register Sony controls?"
VERDICT: APPROVE
REASONING: The title repeats the button the user just pressed and adds a question mark, which is the pattern this app has already established for confirmations — "Forget this TV?", "Restart this TV?", "Enable direct touch?", "Send this TV command?" — and repeating the action verbatim is what lets a reader confirm without re-reading the body. "Sony controls" is the product's own name for that service, used identically in the Diagnostics rows visible in the capture, so the dialog, the button and the diagnostics row all name one thing one way.
RISKS: none

STRING: sonyRegistrationBody
KEYS: sonyRegistrationBody
ENGLISH: "Registration also asks the TV to allow network wake. Depending on the TV, this may change standby settings. Check the TV’s settings after registering."
VERDICT: REWORD
REWRITE: "Registration also asks the TV to turn on Wake-on-LAN. Depending on the TV, this may change standby settings. Check the TV’s settings after registering."
REASONING: The hedging is exactly right and is kept untouched — "asks the TV to" describes a request rather than an outcome, and "may change" does not assert the persistent change the brief says is not established — so the only defect is the name. This app already calls this capability "Wake-on-LAN" in its Diagnostics list, and "network wake" is a second name for the same thing invented at the point of use, which is the failure mode that survives review precisely because it reads smoothly. Using the shipped name also does concrete work for the reader here, because the third sentence sends them into the TV's own settings to look, and the technical name is what they will be hunting for there; television manufacturers label that area with terms like Wake on LAN, Remote start or Network standby, none of which contain the phrase "network wake". The audience is described as technically comfortable, so the term costs them nothing.
RISKS: length. Three sentences is long for a confirmation body, but the settings capture shows the droidVNC-NG disclosure rendering across five lines and remaining readable in the same visual register, so this sits within what the app already asks readers to absorb.

STRING: storageFailed
KEYS: storageFailed
ENGLISH: "The phone could not securely read or save TV settings. Check available storage and restart the app."
VERDICT: APPROVE
REASONING: The subject is the phone, which is correct and matters — this failure is not the TV's fault and the message does not let the reader blame it — and "TV settings" matches the noun already used in the Forget dialog for the same saved data. The word "securely" is worth keeping rather than trimming, because this app makes an explicit promise on the Settings screen that credentials are encrypted on the phone, visible in the rendered capture, and this message is where that promise is failing; removing the adverb would hide which guarantee broke. Two concrete actions follow, both things a user can actually do. A case could be made that free storage is not the usual cause of a secure-storage failure, but the brief does not establish the cause set, and stripping guidance on the reviewer's own speculation about the mechanism would be inventing a limitation rather than removing one.
RISKS: none

STRING: controlUnavailable
KEYS: controlUnavailable
ENGLISH: "No connected service can send this control right now. Check pairing and connection status in Diagnostics."
VERDICT: APPROVE
REASONING: The first sentence is precisely scoped — it says no currently connected service can carry this particular control at this moment, which claims nothing about whether the TV supports it, the distinction the brief explicitly protects against being destroyed by a timeout. "Control" for a button and "service" for a transport are both the app's own nouns, used the same way in the messages and Diagnostics rows already shipping. The second sentence survives a test that the next string fails: it names *what* to look at, not merely where, so it still helps a reader who is already on the Diagnostics screen and pressing Restart TV there — the rows showing pairing and connection state are exactly what they will then examine. A pointer that names the thing to inspect keeps its value in place; a pointer that names only the destination does not.
RISKS: none

STRING: timeoutFailure
KEYS: timeoutFailure
ENGLISH: "The TV did not respond in time."
VERDICT: APPROVE
REASONING: This is the string most exposed to the one claim the brief forbids — treating silence as proof that a control is unsupported — and it does not go near it: it reports only that no answer arrived within the window, attributing nothing and concluding nothing. It is also meaningfully distinct from the existing message about an action not being confirmed in time, because no response at all and a response without confirmation are different situations and the two sentences carry that difference. No next step is attached, which is right: retrying is the obvious move for a control the user just pressed, and the existing confirmation-timeout message already covers the case where checking the TV first is the correct advice.
RISKS: none

STRING: connectionRefused
KEYS: connectionRefused
ENGLISH: "The TV’s control service refused the connection. Check that the service is running and the port is correct."
VERDICT: APPROVE
REASONING: A refusal is a definite signal rather than an absence of one, so unlike a timeout this message is entitled to state what happened, and it does so without technical residue. Both checks it offers map to things the user genuinely controls: the service on the TV, which for one supported setup is the droidVNC-NG application the Settings screen already names, and the port, which exists as three separate editable fields in the TV profile. Because the brief places these messages against a named service, the reader always knows which of those ports is meant without the string having to guess. "Control service" is the same noun used in the sibling messages.
RISKS: none

STRING: addressUnresolved
KEYS: addressUnresolved
ENGLISH: "The TV address could not be found. Check the address or enter its local IP address."
VERDICT: REWORD
REWRITE: "The TV address could not be found. Check the address, or enter the TV’s local IP address."
REASONING: The pronoun attaches to the wrong noun. In "Check the address or enter its local IP address", the nearest antecedent for "its" is "the address", which yields the nonsense of an address having its own address; the intended owner is the TV, two nouns back. This is not a stylistic preference but a sentence that parses incorrectly on first reading, and it appears in a message whose entire job is telling the user which of two values to supply. Naming the TV explicitly fixes it, the added comma separates two genuinely alternative actions rather than letting them run together, and the phrase "local IP address" matches both the address field's own hint, which offers an IP address or a local hostname, and the app's existing insistence elsewhere on an address on the local network.
RISKS: none

STRING: networkRouteUnavailable
KEYS: networkRouteUnavailable
ENGLISH: "The phone cannot reach this local network address. Check the Wi-Fi connection and phone network permissions."
VERDICT: REWORD
REWRITE: "The phone cannot reach this local network address. Check the Wi-Fi connection and this app’s local network permission in phone settings."
REASONING: "Phone network permissions" is both vague and readable in the wrong sense — as permissions belonging to the phone network, meaning the router or the carrier, rather than a permission this application holds. The app has already solved this exact problem once, in the microphone message, which says "Check this app's microphone permission in phone settings", and the fix here is to follow that sentence rather than invent a new shape for the same idea. The replacement also names the permission the way the app itself names it when requesting it, as local network access, so the words in the error, the words in the permission prompt, and the words the user will look for after tapping Open phone settings all line up. The first sentence is already correct and is untouched.
RISKS: length. This is the longest message in the set and will occupy three lines in a snackbar, which is at the upper end of what this app already ships — the shortcut-failure message is comparable — but the alternative of dropping "in phone settings" would remove the only part that tells the reader where to go.

STRING: screenInvalid
KEYS: screenInvalid
ENGLISH: "The VNC service sent invalid screen data. Reconnect or check the service on the TV."
VERDICT: APPROVE
REASONING: The subject is named precisely — VNC is one of three distinct services this app talks to and the one that carries the picture, and the Diagnostics capture shows it listed under that exact name — so the reader is not left guessing which part of a multi-service connection went wrong. Attributing the fault to what the service sent is accurate and, usefully, tells the reader this is not something they have misconfigured. Both offered actions exist as real controls: Reconnect is a button on the viewer toolbar and on each service row in Diagnostics, and the service on the TV is the same thing the connection-refused message points at, so the two errors send the reader to the same place for the same class of problem.
RISKS: none

STRING: screenTooLarge
KEYS: screenTooLarge
ENGLISH: "The VNC screen is too large to display safely. Lower the screen-sharing resolution on the TV."
VERDICT: REWORD
REWRITE: "The VNC screen is too large for this phone to display. Lower the screen-sharing resolution on the TV."
REASONING: "Safely" introduces a hazard the reader cannot evaluate and that does not exist in the terms they care about — nothing is at risk, the phone simply cannot render an image that size — and in an app that also ships genuine security notices about unencrypted connections and credential storage, spending the word "safely" on a capacity limit dilutes it where it is doing real work. Saying the phone cannot display it is both true and more useful, because it tells the reader which end of the connection is the constraint and therefore why the fix is on the TV. The second sentence is already correct and is kept verbatim: "screen sharing" is the app's established name for this feature, used in the unavailability message and the approval notice, and lowering the resolution is a real setting on the TV side.
RISKS: none

STRING: screenSurfaceFailure
KEYS: screenSurfaceFailure
ENGLISH: "The phone could not display the screen. Reconnect the viewer."
VERDICT: REWORD
REWRITE: "The phone could not display the TV screen. Choose Reconnect to try again."
REASONING: Two separate faults. First, with "the phone" as the subject, "the screen" is readable as the phone's own display, which turns a message about a failed picture into one that sounds like the handset is broken; adding "TV" removes the reading at no cost and matches the label used on the picture itself. Second, "the viewer" is a word the user has never seen — the app's visible noun for that area is Screen, in Show screen, Hide screen and the hidden-screen notice, and nothing on the rendered viewer toolbar says "viewer" anywhere. Pointing at a named thing that does not appear on screen is the worst kind of instruction because the reader will hunt for it. The replacement names the actual control, whose icon sits in the toolbar directly above where this message appears, using the construction the app already uses for exactly this purpose elsewhere.
RISKS: none

STRING: registrationUnconfirmed
KEYS: registrationUnconfirmed
ENGLISH: "The TV did not confirm Sony registration. Check the TV and try again."
VERDICT: APPROVE
REASONING: This follows the pattern the app has settled on for every unconfirmed outcome — the TV is named as the party that did not confirm, and the app claims only what it knows, which is that its request went out and nothing came back to validate it. "Sony registration" ties the failure to the action the user just authorised and to the dialog that authorised it, so there is no ambiguity about which of several services is being reported. The closing instruction matches the existing pairing-failure and command-timeout messages, which both send the reader to look at the TV before retrying, and that consistency means a reader who has met one of those messages already knows what this one is asking.
RISKS: none

STRING: transportUnavailable
KEYS: transportUnavailable
ENGLISH: "This control service is not connected. Check Diagnostics."
VERDICT: REWORD
REWRITE: "This control service is not connected. Choose Reconnect to try again."
REASONING: The rendered Diagnostics screen exposes the defect directly. The brief states these messages appear as snackbars or as per-service errors, and the per-service errors live on the Diagnostics screen — so this string can tell a reader who is already looking at Diagnostics to go and check Diagnostics, which is a dead end that makes the app look broken at the moment the user most needs it to be coherent. The same capture supplies the fix: every service row carries a Reconnect control right beside its status, and the viewer toolbar carries one too, so naming that control works in both places this message can appear and gives the reader something to press instead of somewhere to go. The construction matches the app's existing "Choose Connect to send controls". The first sentence is accurate and is kept. Note that the sibling message about no connected service being able to send a control was deliberately not changed, because its pointer names what to inspect rather than only where, and that keeps its value even when read in place.
RISKS: none

STRING: invalidLink
KEYS: invalidLink
ENGLISH: "Enter a valid app link."
VERDICT: APPROVE
REASONING: It matches the validation family the app has established — the port, MAC address and local-address errors all open with "Enter" and name the field — and the Apps capture confirms the control it belongs to is labelled "Open app link", so the noun is the product's own. The honest weakness is that "valid" is circular where its siblings are specific, telling the reader a range or a kind of address; the reason it stays is that the brief does not establish which link formats this field accepts, and any specific example or format written here would be an invention that could quietly forbid a form the field actually takes. A generic word that is true is better than a precise one that is guessed, and this is the one string in the set where that trade is forced.
RISKS: none

STRING: tooMuchText
KEYS: tooMuchText
ENGLISH: "This text is too long for the connected service. Send a shorter section."
VERDICT: REWORD
REWRITE: "This text is too long for the connected service. Send it in shorter parts."
REASONING: The first sentence is right and is kept, including the attribution to the connected service, which correctly tells the reader the limit belongs to the transport rather than to their text. The second sentence gives the wrong strategy: "Send a shorter section" implies abandoning most of what they wrote, and "section" suggests they have selected one, which the Keyboard capture shows they have not — there is a single draft field with Paste, Send and Clear beneath it. What the user will actually do is send the text in pieces, and saying so tells them their whole message can still get through, which is the difference between a dead end and a workaround. The replacement is the same length and keeps the sentence shape.
RISKS: none

STRING: confirmationRequired
KEYS: confirmationRequired
ENGLISH: "Confirm this action before sending it to the TV."
VERDICT: APPROVE
REASONING: The sentence is clear, correctly ordered, and explains why nothing happened, which is the job of a message that appears when a control needing confirmation was not confirmed. The noun "action" rather than "command" was examined closely, because the confirmation dialog this refers to is titled "Send this TV command?" and several shipped messages use "command" for the thing sent. The existing confirmation-timeout message, however, already says "did not confirm this action in time" for precisely the same object, so the shipped table is mixed, and changing this one string to "command" would align it with the dialog at the cost of splitting it from its closest sibling. Where a rewrite trades one inconsistency for another it is churn, and the sentence is unambiguous as written.
RISKS: none

STRING: liveScreen
KEYS: liveScreen
ENGLISH: "Live TV screen"
VERDICT: APPROVE
REASONING: Judged purely on what a reader receives, as the void test-hook constraint reported above requires, this is the right label. It names the thing the image actually is and pairs precisely against the stale-image label already shipping, "Not live — last image received", so the two states differ on the single word that matters and a screen-reader user moving between them cannot miss the change. "TV screen" also matches the app's own noun for the area, used in Show screen and Hide screen and in the corrected display-failure message above. Three words is the right length for a label announced every time focus lands on the picture.
RISKS: none

COPY REVIEW COMPLETE: 33 strings (24 approved, 9 reworded)

