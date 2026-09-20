REVIEW-ID: c7598a74-2b68-4f63-a4d3-ba4570a5c227
DATE: 2026-09-20
REVIEWER: content-strategist (Claude, cross-model)
ARTIFACT: docs/reviews/copy-initial.md
DESCRIPTOR: none — derived from approved Phase 0 screen specification

`★ Insight ─────────────────────────────────────`
- Three collisions drive most of the rewrites below: the app defines **Screen** as the VNC preview, so "Fit to screen" inverts its own noun; it defines **Settings** as its own tab, so "Open settings" is ambiguous with the OS settings it actually opens; and it calls the local machine **this phone** everywhere, so "device theme" reads as the TV's theme.
- The draft's status vocabulary (`unknown` = "Not checked yet" vs `unsupported` = "Not supported" vs `unavailable` = "Temporarily unavailable") is the strongest thing in it — it holds the "unknown is not unsupported" line precisely. The rewrites keep that discipline and extend it to the two "unconfirmed" strings, where "sent without confirmation" reads as *no confirmation dialog* rather than *the TV did not acknowledge*.
- Register is consistent and deliberate: no contractions, sentence case, typographic apostrophes, periods on sentences but not on labels. Every rewrite below stays inside that register rather than modernising it.
`─────────────────────────────────────────────────`

STRING: appTitle
KEYS: appTitle
ENGLISH: "TV Console"
VERDICT: APPROVE
REASONING: Product name from the approved glossary; "Console" reads as a control surface, not a games console, because every surrounding noun is TV-related.
RISKS: none

STRING: devices
KEYS: devices
ENGLISH: "Your TVs"
VERDICT: APPROVE
REASONING: Uses the product's own noun (TV) rather than the internal key's "devices", and the possessive marks this as the saved list rather than discovery results.
RISKS: none

STRING: addTv
KEYS: addTv
ENGLISH: "Add TV"
VERDICT: APPROVE
REASONING: Verb plus the product noun; parallel with "Find TVs" on the same screen.
RISKS: none

STRING: discover
KEYS: discover
ENGLISH: "Find TVs"
VERDICT: APPROVE
REASONING: "Find" is the plain-language equivalent of discovery and avoids the protocol word; plural correctly implies a scan of several.
RISKS: none

STRING: manual
KEYS: manual
ENGLISH: "Enter address"
VERDICT: APPROVE
REASONING: Appears beside "Find TVs" as the alternative route, where the object is supplied by context; "address" matches the field label it leads to.
RISKS: none

STRING: noDevices
KEYS: noDevices
ENGLISH: "Add a TV to get started."
VERDICT: APPROVE
REASONING: Empty state that names the single next action rather than describing emptiness.
RISKS: none

STRING: discoveryEmpty
KEYS: discoveryEmpty
ENGLISH: "No TVs found. Check that your phone and TV are on the same network."
VERDICT: APPROVE
REASONING: States the result, then the most common cause, without claiming the TV is off or unsupported; "network" rather than "Wi-Fi" stays true for a wired TV.
RISKS: none

STRING: name
KEYS: name
ENGLISH: "TV name"
VERDICT: APPROVE
REASONING: Noun-phrase field label consistent with the rest of the form.
RISKS: none

STRING: address
KEYS: address
ENGLISH: "TV address"
VERDICT: APPROVE
REASONING: Qualified by the product noun, so it cannot be read as a postal address.
RISKS: none

STRING: addressHint
KEYS: addressHint
ENGLISH: "IP address or local hostname"
VERDICT: APPROVE
REASONING: Hint text carrying the two accepted forms; the only place protocol vocabulary is needed and it is placed where the user is already typing one.
RISKS: none

STRING: save
KEYS: save
ENGLISH: "Save"
VERDICT: APPROVE
REASONING: Standard form-commit verb.
RISKS: none

STRING: cancel
KEYS: cancel
ENGLISH: "Cancel"
VERDICT: APPROVE
REASONING: Standard dismissal verb, paired correctly with Save.
RISKS: none

STRING: connect
KEYS: connect
ENGLISH: "Connect"
VERDICT: APPROVE
REASONING: Matches the "Connected"/"Connecting…"/"Not connected" status family.
RISKS: none

STRING: disconnect
KEYS: disconnect
ENGLISH: "Disconnect"
VERDICT: APPROVE
REASONING: Direct inverse of Connect; no ambiguity with turning the TV off because Power is named separately.
RISKS: none

STRING: edit
KEYS: edit
ENGLISH: "Edit"
VERDICT: APPROVE
REASONING: Conventional label for opening the saved TV's form.
RISKS: none

STRING: forget
KEYS: forget
ENGLISH: "Forget TV"
VERDICT: APPROVE
REASONING: "Forget" is the platform-standard verb for removing a saved connection and correctly signals a local removal rather than a change to the TV.
RISKS: none

STRING: forgetTitle
KEYS: forgetTitle
ENGLISH: "Forget this TV?"
VERDICT: APPROVE
REASONING: Question-form title matching the action verb; "this" anchors it to the named TV in the header.
RISKS: none

STRING: forgetBody
KEYS: forgetBody
ENGLISH: "Saved settings and pairing credentials for this TV will be removed from this phone."
VERDICT: REWORD
REWRITE: "Saved settings and pairing for this TV will be removed from this phone. You will need to pair again to reconnect."
REASONING: Two problems in a dialog every user meets. "Pairing credentials" names an artifact the user never typed — unlike the advanced form's credential fields, which they did — so it is jargon here. And the body states what is deleted without stating what it costs; the recovery step is the fact that decides whether to tap Forget.
RISKS: none

STRING: remove
KEYS: remove
ENGLISH: "Forget"
VERDICT: APPROVE
REASONING: The confirm button repeats the title's verb, which is what lets the user confirm without re-reading the body.
RISKS: none

STRING: remote
KEYS: remote
ENGLISH: "Remote"
VERDICT: APPROVE
REASONING: Glossary term for the physical-style control surface; the shortest accurate tab label.
RISKS: none

STRING: allButtons
KEYS: allButtons
ENGLISH: "All buttons"
VERDICT: APPROVE
REASONING: Distinguishes the exhaustive grid from the curated Remote tab in three words.
RISKS: none

STRING: touchpad
KEYS: touchpad
ENGLISH: "Touchpad"
VERDICT: APPROVE
REASONING: Names a familiar input metaphor that correctly implies relative movement.
RISKS: none

STRING: directTouch
KEYS: directTouch
ENGLISH: "Direct touch"
VERDICT: APPROVE
REASONING: Sits opposite "Touchpad" and carries the absolute-versus-relative distinction; "Touch screen" would collide with the app's Screen noun.
RISKS: none

STRING: keyboard
KEYS: keyboard
ENGLISH: "Keyboard"
VERDICT: APPROVE
REASONING: Names the tab by what it provides.
RISKS: none

STRING: apps
KEYS: apps
ENGLISH: "Apps"
VERDICT: APPROVE
REASONING: The TV platform's own noun for the same list.
RISKS: none

STRING: inputs
KEYS: inputs
ENGLISH: "Inputs"
VERDICT: APPROVE
REASONING: Matches the "Input" button and "Current input" row, so one noun covers the whole concept.
RISKS: none

STRING: diagnostics
KEYS: diagnostics
ENGLISH: "Diagnostics"
VERDICT: APPROVE
REASONING: Sets the expectation that this tab is the technical surface, which licenses the transport names inside it.
RISKS: none

STRING: settings
KEYS: settings
ENGLISH: "Settings"
VERDICT: APPROVE
REASONING: Correct for the app's own settings; the collision this creates is resolved on the OS-settings string rather than here.
RISKS: none

STRING: power
KEYS: power
ENGLISH: "Power"
VERDICT: APPROVE
REASONING: The name printed on a real remote's button, which is what a physical-style control should carry.
RISKS: none

STRING: powerOn
KEYS: powerOn
ENGLISH: "Turn on"
VERDICT: APPROVE
REASONING: Plain verb phrase; the TV is supplied by the header that always shows the device name.
RISKS: none

STRING: powerOff
KEYS: powerOff
ENGLISH: "Turn off"
VERDICT: APPROVE
REASONING: Exact inverse of "Turn on", same length, same structure.
RISKS: none

STRING: powerToggle
KEYS: powerToggle
ENGLISH: "Toggle power"
VERDICT: REWORD
REWRITE: "Turn on or off"
REASONING: "Toggle" is interface-builder vocabulary, not what a TV owner says, and it breaks the family its two siblings establish. The rewrite is the same construction as "Turn on" and "Turn off" and reads correctly when a screen reader announces it on a button whose state is unknown.
RISKS: none

STRING: up
KEYS: up
ENGLISH: "Up"
VERDICT: APPROVE
REASONING: D-pad direction named as the physical control is named.
RISKS: none

STRING: down
KEYS: down
ENGLISH: "Down"
VERDICT: APPROVE
REASONING: Matches "Up" as a physical direction.
RISKS: none

STRING: left
KEYS: left
ENGLISH: "Left"
VERDICT: APPROVE
REASONING: Names a physical D-pad direction rather than a reading direction.
RISKS: RTL — this label describes the physical pad and must not be mirrored or swapped with "Right" in translation.

STRING: right
KEYS: right
ENGLISH: "Right"
VERDICT: APPROVE
REASONING: Same as "Left"; the pair must stay bound to the hardware directions.
RISKS: RTL — must not be mirrored or swapped with "Left" in translation.

STRING: ok
KEYS: ok
ENGLISH: "OK"
VERDICT: APPROVE
REASONING: The label printed on the centre key of most TV remotes; "Select" would be a synonym the hardware does not use.
RISKS: none

STRING: back
KEYS: back
ENGLISH: "Back"
VERDICT: APPROVE
REASONING: Platform-standard navigation name.
RISKS: none

STRING: home
KEYS: home
ENGLISH: "Home"
VERDICT: APPROVE
REASONING: The TV platform's own name for the destination.
RISKS: none

STRING: options
KEYS: options
ENGLISH: "Options"
VERDICT: APPROVE
REASONING: Matches the contextual-menu key as TV platforms name it.
RISKS: none

STRING: input
KEYS: input
ENGLISH: "Input"
VERDICT: APPROVE
REASONING: One noun shared with the Inputs tab, "Current input" and "Select input", so the concept is never renamed.
RISKS: none

STRING: guide
KEYS: guide
ENGLISH: "Guide"
VERDICT: APPROVE
REASONING: Established broadcast term for the programme grid.
RISKS: none

STRING: info
KEYS: info
ENGLISH: "Info"
VERDICT: APPROVE
REASONING: The abbreviation the hardware button uses; expanding it would diverge from the remote being mirrored.
RISKS: none

STRING: volumeUp
KEYS: volumeUp
ENGLISH: "Volume up"
VERDICT: APPROVE
REASONING: Unambiguous, and pairs exactly with its inverse.
RISKS: none

STRING: volumeDown
KEYS: volumeDown
ENGLISH: "Volume down"
VERDICT: APPROVE
REASONING: Parallel to "Volume up".
RISKS: none

STRING: mute
KEYS: mute
ENGLISH: "Mute"
VERDICT: APPROVE
REASONING: Action label matching the "Muted" state string.
RISKS: none

STRING: unmute
KEYS: unmute
ENGLISH: "Unmute"
VERDICT: APPROVE
REASONING: Standard inverse; clearer than reusing "Mute" as a toggle when the state is known.
RISKS: none

STRING: channelUp
KEYS: channelUp
ENGLISH: "Channel up"
VERDICT: APPROVE
REASONING: Parallel with the volume pair and named as the hardware names it.
RISKS: none

STRING: channelDown
KEYS: channelDown
ENGLISH: "Channel down"
VERDICT: APPROVE
REASONING: Inverse of "Channel up".
RISKS: none

STRING: rewind
KEYS: rewind
ENGLISH: "Rewind"
VERDICT: APPROVE
REASONING: Transport verb every media user knows; pairs with "Fast-forward".
RISKS: none

STRING: playPause
KEYS: playPause
ENGLISH: "Play or pause"
VERDICT: APPROVE
REASONING: Names both outcomes for a single key whose effect depends on unknown TV state — correct restraint where the app cannot know what is playing.
RISKS: none

STRING: play
KEYS: play
ENGLISH: "Play"
VERDICT: APPROVE
REASONING: Discrete transport action, distinct from the combined key above.
RISKS: none

STRING: pause
KEYS: pause
ENGLISH: "Pause"
VERDICT: APPROVE
REASONING: Discrete inverse of Play.
RISKS: none

STRING: stop
KEYS: stop
ENGLISH: "Stop"
VERDICT: APPROVE
REASONING: Media-transport stop; the shortcut control is qualified as "Stop shortcut" precisely so this one can stay bare.
RISKS: none

STRING: previous
KEYS: previous
ENGLISH: "Previous"
VERDICT: APPROVE
REASONING: Sits inside the transport cluster where the object is implied; naming it "Previous track" would misdescribe the key on apps where it moves between chapters or episodes.
RISKS: none

STRING: next
KEYS: next
ENGLISH: "Next"
VERDICT: APPROVE
REASONING: Same reasoning as "Previous"; the pair must stay symmetrical.
RISKS: none

STRING: fastForward
KEYS: fastForward
ENGLISH: "Fast-forward"
VERDICT: APPROVE
REASONING: Hyphenated form is correct for the verb, and it mirrors "Rewind".
RISKS: none

STRING: voice
KEYS: voice
ENGLISH: "Voice"
VERDICT: APPROVE
REASONING: One-word control label matching the microphone key on TV remotes.
RISKS: none

STRING: holdToSpeak
KEYS: holdToSpeak
ENGLISH: "Hold to speak"
VERDICT: APPROVE
REASONING: States the gesture and its purpose in three words, which is what a press-and-hold control must do since the gesture is not visible.
RISKS: none

STRING: startVoice
KEYS: startVoice
ENGLISH: "Start voice input"
VERDICT: APPROVE
REASONING: Accessible action naming what the app does rather than the gesture, which is correct where the gesture is unavailable.
RISKS: none

STRING: stopVoice
KEYS: stopVoice
ENGLISH: "Stop voice input"
VERDICT: APPROVE
REASONING: Exact inverse of the start action.
RISKS: none

STRING: voiceStarting
KEYS: voiceStarting
ENGLISH: "Starting voice input…"
VERDICT: APPROVE
REASONING: Progressive form plus ellipsis marks an in-flight state and distinguishes it from "Listening…".
RISKS: none

STRING: listening
KEYS: listening
ENGLISH: "Listening…"
VERDICT: APPROVE
REASONING: The one word that tells the user the microphone is now live; brevity matters because it is read while speaking.
RISKS: none

STRING: voiceNotReady
KEYS: voiceNotReady
ENGLISH: "Voice input did not start. Check the TV for a search or setup screen."
VERDICT: APPROVE
REASONING: States the failure without claiming a cause, then sends the user to where the cause is visible. Naming only the search case would strand a user whose TV is waiting on setup.
RISKS: none

STRING: pairRemote
KEYS: pairRemote
ENGLISH: "Pair TV remote"
VERDICT: REWORD
REWRITE: "Pair with your TV"
REASONING: Factually wrong about what the action does. "Remote" is this app's own tab of physical-style controls, so "Pair TV remote" reads as pairing a handset to the TV, when what pairs is this phone with the TV. Naming the two parties is the whole content of the dialog.
RISKS: none

STRING: pairingCode
KEYS: pairingCode
ENGLISH: "Code shown on TV"
VERDICT: REWORD
REWRITE: "Pairing code"
REASONING: Every other field in this app is labelled with a noun naming the value (TV name, TV address, VNC port). This one is a descriptive clause that also duplicates the helper text directly beneath it. Naming the field and leaving the instruction to the helper removes the repetition.
RISKS: none

STRING: pair
KEYS: pair
ENGLISH: "Pair"
VERDICT: APPROVE
REASONING: Confirm button carrying the dialog's verb.
RISKS: none

STRING: pairingWaiting
KEYS: pairingWaiting
ENGLISH: "Enter the code shown on your TV."
VERDICT: APPROVE
REASONING: Tells the user what to do and where to look, in that order, and sets the "your TV" register the rest of the pairing dialog follows.
RISKS: none

STRING: pairingRequired
KEYS: pairingRequired
ENGLISH: "Pair the TV remote to use these controls."
VERDICT: REWORD
REWRITE: "Pair with your TV to use these controls."
REASONING: Same misnaming as the pairing title, applied uniformly: the object of "pair" is the TV, not a remote handset. The rewrite keeps the consequence clause intact, which is what makes the disabled controls make sense.
RISKS: none

STRING: sonyKey
KEYS: sonyKey
ENGLISH: "Sony pre-shared key"
VERDICT: APPROVE
REASONING: An advanced credential field must carry the exact name the TV's own settings use, or the user cannot find the value to copy.
RISKS: none

STRING: vncPassword
KEYS: vncPassword
ENGLISH: "VNC password"
VERDICT: APPROVE
REASONING: Names the protocol whose password it is, which is what disambiguates it from the Sony key on the same form.
RISKS: none

STRING: vncPort
KEYS: vncPort
ENGLISH: "VNC port"
VERDICT: APPROVE
REASONING: Follows the "<service> port" pattern and pairs with the VNC password field.
RISKS: none

STRING: remotePort
KEYS: remotePort
ENGLISH: "Remote port"
VERDICT: REWORD
REWRITE: "Remote service port"
REASONING: "Remote port" carries a second, standard networking sense — the far end of a connection — which is exactly the wrong reading on a form where the user is entering the TV's own port. Adding "service" matches the Diagnostics row "Remote service version" and restores the "<service> port" pattern its two neighbours follow.
RISKS: none

STRING: pairingPort
KEYS: pairingPort
ENGLISH: "Pairing port"
VERDICT: APPROVE
REASONING: Follows the "<service> port" pattern, and "pairing" is already established by the dialog.
RISKS: none

STRING: mac
KEYS: mac
ENGLISH: "Network MAC address"
VERDICT: APPROVE
REASONING: "Network" is mildly redundant but does useful work for a user who has never met the acronym, and it matches the wording of the validation error.
RISKS: none

STRING: screen
KEYS: screen
ENGLISH: "Screen"
VERDICT: APPROVE
REASONING: Glossary noun for the preview, and the anchor that the Show/Hide pair depends on.
RISKS: none

STRING: showScreen
KEYS: showScreen
ENGLISH: "Show screen"
VERDICT: APPROVE
REASONING: Verb plus the product's own noun; inverse is exact.
RISKS: none

STRING: hideScreen
KEYS: hideScreen
ENGLISH: "Hide screen"
VERDICT: APPROVE
REASONING: Exact inverse of "Show screen" — important because this control is how a user gets privacy quickly.
RISKS: none

STRING: fullScreen
KEYS: fullScreen
ENGLISH: "Full screen"
VERDICT: APPROVE
REASONING: A fixed idiom for the viewer mode, understood independently of which screen is meant, and its meaning does not invert under the app's Screen noun.
RISKS: none

STRING: exitFullScreen
KEYS: exitFullScreen
ENGLISH: "Exit full screen"
VERDICT: APPROVE
REASONING: Standard inverse of the same idiom.
RISKS: none

STRING: fit
KEYS: fit
ENGLISH: "Fit to screen"
VERDICT: REWORD
REWRITE: "Fit"
REASONING: This app has taught the user that "Screen" is the TV's picture, so "Fit to screen" reads as fitting something *to* the TV picture — the reverse of what it does. The collision is specific to the "to <target>" construction, which is why "Full screen" survives and this does not. "Fit" alone carries the meaning and pairs cleanly with the zoom control beside it.
RISKS: none

STRING: actualSize
KEYS: actualSize
ENGLISH: "1:1"
VERDICT: REWORD
REWRITE: "Actual size"
REASONING: A ratio glyph is not readable as a label: a screen reader announces it as characters, and it carries no meaning for a user who has not used a desktop image viewer. "Actual size" is the conventional name for the same mode and pairs with "Fit".
RISKS: none — the rewrite also removes the bidi-neutral digit pair, which would have rendered unpredictably in RTL layouts.

STRING: zoomIn
KEYS: zoomIn
ENGLISH: "Zoom in"
VERDICT: APPROVE
REASONING: Universal viewer verb with an exact inverse.
RISKS: none

STRING: zoomOut
KEYS: zoomOut
ENGLISH: "Zoom out"
VERDICT: APPROVE
REASONING: Inverse of "Zoom in".
RISKS: none

STRING: screenshot
KEYS: screenshot
ENGLISH: "Save screenshot"
VERDICT: APPROVE
REASONING: The verb states the effect — a file is kept — rather than merely capturing, which is what the confirmation toast then reports.
RISKS: none

STRING: reconnect
KEYS: reconnect
ENGLISH: "Reconnect"
VERDICT: APPROVE
REASONING: One word, correct for an existing connection that dropped, and consistent with the Connect family.
RISKS: none

STRING: lastFrame
KEYS: lastFrame
ENGLISH: "Last received frame — not live"
VERDICT: REWORD
REWRITE: "Not live — last image received"
REASONING: "Frame" is video-pipeline vocabulary; the user sees a picture. The order is also wrong for a warning badge: the fact that matters — this is stale — arrives last, after a phrase that sounds like a normal status.
RISKS: none

STRING: screenUnavailable
KEYS: screenUnavailable
ENGLISH: "Screen sharing is unavailable. Remote controls can still work."
VERDICT: REWORD
REWRITE: "Screen sharing is unavailable. The remote controls use a separate connection."
REASONING: "Can still work" is a hedge that answers nothing — the user cannot tell whether to try. Stating the structural fact (a separate connection) tells them why the rest of the app is still worth using without asserting that any particular command will succeed, which the app cannot know.
RISKS: none

STRING: screenshotSaved
KEYS: screenshotSaved
ENGLISH: "Screenshot saved on this phone."
VERDICT: APPROVE
REASONING: Confirms the effect and locates the file on the phone rather than the TV, matching the "this phone" vocabulary used in the Forget dialog.
RISKS: none

STRING: compose
KEYS: compose
ENGLISH: "Compose"
VERDICT: APPROVE
REASONING: Implies writing before sending, which is exactly what distinguishes it from the live mode beside it.
RISKS: none

STRING: liveEdit
KEYS: liveEdit
ENGLISH: "Live edit"
VERDICT: APPROVE
REASONING: "Live" carries the key difference — keystrokes reach the TV as typed — and the mode is referenced by this exact name in the recovery message.
RISKS: none

STRING: textHint
KEYS: textHint
ENGLISH: "Type or paste text"
VERDICT: APPROVE
REASONING: Names both entry routes, one of which has its own button on the same row.
RISKS: none

STRING: paste
KEYS: paste
ENGLISH: "Paste"
VERDICT: APPROVE
REASONING: Standard clipboard verb.
RISKS: none

STRING: send
KEYS: send
ENGLISH: "Send"
VERDICT: APPROVE
REASONING: Commits the composed text to the TV; matched by the "Text was sent" outcome messages.
RISKS: none

STRING: enter
KEYS: enter
ENGLISH: "Enter"
VERDICT: APPROVE
REASONING: Named as the key is named on a keyboard, which is what this row reproduces.
RISKS: none

STRING: backspace
KEYS: backspace
ENGLISH: "Backspace"
VERDICT: APPROVE
REASONING: Keyboard key name; renaming it would break the mapping the row exists to provide.
RISKS: none

STRING: delete
KEYS: delete
ENGLISH: "Delete"
VERDICT: APPROVE
REASONING: The forward-delete key's own name, kept distinct from "Clear" which empties the field.
RISKS: none

STRING: privateText
KEYS: privateText
ENGLISH: "Private text"
VERDICT: APPROVE
REASONING: Names a mode rather than making a promise. Rewriting it into an assurance about what is not stored would claim something on the TV's behalf, which the anti-overclaim rule forbids.
RISKS: none

STRING: clear
KEYS: clear
ENGLISH: "Clear"
VERDICT: APPROVE
REASONING: Conventional verb for emptying a field, distinct from the two per-character keys beside it.
RISKS: none

STRING: editorChanged
KEYS: editorChanged
ENGLISH: "The TV text field changed. Open Live edit again to continue."
VERDICT: REWORD
REWRITE: "The TV text field changed. Switch to Live edit again to continue."
REASONING: "Open" describes opening a panel; Live edit is one side of a two-state toggle, so the instruction points at an interaction that does not exist on screen. "Switch to" matches the control the user must actually operate.
RISKS: none

STRING: noEditor
KEYS: noEditor
ENGLISH: "Select a text field on the TV first."
VERDICT: APPROVE
REASONING: Single imperative naming the device where the action happens — essential when the fix is on the other screen.
RISKS: none

STRING: textUnconfirmed
KEYS: textUnconfirmed
ENGLISH: "Text was sent, but insertion could not be confirmed. Check the TV before sending again."
VERDICT: REWORD
REWRITE: "Text was sent, but the TV did not confirm it. Check the TV before sending again."
REASONING: "Insertion could not be confirmed" is jargon in the passive, and it hides who failed to confirm. Naming the TV as the actor keeps the claim honest — the app sent it, the TV stayed silent — and makes the "check the TV" instruction follow logically.
RISKS: none

STRING: search
KEYS: search
ENGLISH: "Search"
VERDICT: APPROVE
REASONING: Standard label for filtering the app and input rows.
RISKS: none

STRING: favorites
KEYS: favorites
ENGLISH: "Favorites"
VERDICT: APPROVE
REASONING: Section name matching the add/remove actions exactly.
RISKS: none

STRING: recent
KEYS: recent
ENGLISH: "Recent"
VERDICT: APPROVE
REASONING: Names the ordering principle of the row in one word.
RISKS: none

STRING: favorite
KEYS: favorite
ENGLISH: "Add to favorites"
VERDICT: APPROVE
REASONING: Names the destination section verbatim, so the user knows where the app will appear.
RISKS: none

STRING: unfavorite
KEYS: unfavorite
ENGLISH: "Remove from favorites"
VERDICT: APPROVE
REASONING: Exact inverse, and avoids the non-word the key uses.
RISKS: none

STRING: noApps
KEYS: noApps
ENGLISH: "No app list is available yet. Connect or refresh to check."
VERDICT: APPROVE
REASONING: Carefully says the *list* is unavailable rather than claiming the TV has no apps — the unknown-is-not-unsupported distinction applied correctly — and offers the two actions that can resolve either state.
RISKS: none

STRING: noInputs
KEYS: noInputs
ENGLISH: "No input list is available yet. Connect or refresh to check."
VERDICT: APPROVE
REASONING: Same construction as the apps empty state, which is right: two identical situations should not read differently.
RISKS: none

STRING: refresh
KEYS: refresh
ENGLISH: "Refresh"
VERDICT: APPROVE
REASONING: The verb the two empty states name, so the instruction and the button match.
RISKS: none

STRING: openLink
KEYS: openLink
ENGLISH: "Open app link"
VERDICT: APPROVE
REASONING: "Open" is correct for a link and stays distinct from "Launch", which starts an installed app.
RISKS: none

STRING: appLink
KEYS: appLink
ENGLISH: "App link"
VERDICT: APPROVE
REASONING: Noun-phrase field label matching the action label above it.
RISKS: none

STRING: launch
KEYS: launch
ENGLISH: "Launch"
VERDICT: APPROVE
REASONING: Reserving "Launch" for starting an app and "Open" for following a link keeps two different outcomes distinguishable; it also matches the shortcut step "Launch app".
RISKS: none

STRING: connected
KEYS: connected
ENGLISH: "Connected"
VERDICT: APPROVE
REASONING: Plain state word appearing beside the named transport that is connected.
RISKS: none

STRING: connecting
KEYS: connecting
ENGLISH: "Connecting…"
VERDICT: APPROVE
REASONING: Progressive form and ellipsis mark work in flight rather than a settled result.
RISKS: none

STRING: disconnected
KEYS: disconnected
ENGLISH: "Not connected"
VERDICT: APPROVE
REASONING: "Not connected" covers both never-connected and dropped, where "Disconnected" would wrongly imply a connection existed.
RISKS: none

STRING: unknown
KEYS: unknown
ENGLISH: "Not checked yet"
VERDICT: APPROVE
REASONING: The single most important string in the status set: it keeps an unchecked capability from reading as an absent one, and "yet" promises the check is still possible.
RISKS: none

STRING: needsSetup
KEYS: needsSetup
ENGLISH: "Needs setup"
VERDICT: APPROVE
REASONING: Attributes the gap to missing configuration rather than to the TV lacking the feature, and appears beside the named transport that needs it.
RISKS: none

STRING: permissionRequired
KEYS: permissionRequired
ENGLISH: "Permission required"
VERDICT: APPROVE
REASONING: Names the specific blocker, with the explanatory body and the settings action carrying the resolution.
RISKS: none

STRING: unavailable
KEYS: unavailable
ENGLISH: "Temporarily unavailable"
VERDICT: APPROVE
REASONING: "Temporarily" is load-bearing — it separates a transient failure from "Not supported" and tells the user retrying is worthwhile.
RISKS: none

STRING: unsupported
KEYS: unsupported
ENGLISH: "Not supported"
VERDICT: APPROVE
REASONING: Reserved for a determined negative, with "Not checked yet" covering the undetermined case; the row label supplies which operation is unsupported.
RISKS: none

STRING: ready
KEYS: ready
ENGLISH: "Ready"
VERDICT: APPROVE
REASONING: States usability rather than connection state, which is the distinction a diagnostics reader needs.
RISKS: none

STRING: tv
KEYS: tv
ENGLISH: "TV"
VERDICT: APPROVE
REASONING: The glossary noun used as the row label for the device itself.
RISKS: none

STRING: on
KEYS: on
ENGLISH: "On"
VERDICT: APPROVE
REASONING: Power-state value paired with "Standby"; short enough to read as a value rather than a label.
RISKS: none

STRING: standby
KEYS: standby
ENGLISH: "Standby"
VERDICT: APPROVE
REASONING: The correct television term, and more accurate than "Off" for a TV that is still reachable on the network.
RISKS: none

STRING: waking
KEYS: waking
ENGLISH: "Waking TV…"
VERDICT: APPROVE
REASONING: Progressive state that matches the "Wake TV" shortcut step and explains a delay the user would otherwise read as failure.
RISKS: none

STRING: currentInput
KEYS: currentInput
ENGLISH: "Current input"
VERDICT: APPROVE
REASONING: Reuses the Input noun and marks the value as live rather than configured.
RISKS: none

STRING: currentApp
KEYS: currentApp
ENGLISH: "Current app"
VERDICT: APPROVE
REASONING: Parallel with "Current input"; two live values labelled the same way.
RISKS: none

STRING: volume
KEYS: volume
ENGLISH: "Volume"
VERDICT: APPROVE
REASONING: Row label matching the control names.
RISKS: none

STRING: muted
KEYS: muted
ENGLISH: "Muted"
VERDICT: APPROVE
REASONING: State adjective distinct from the "Mute" action, which is what a diagnostics row should show.
RISKS: none

STRING: yes
KEYS: yes
ENGLISH: "Yes"
VERDICT: APPROVE
REASONING: Plain value for a boolean diagnostics row; more readable than "True" or "Enabled" for a non-technical helper.
RISKS: none

STRING: no
KEYS: no
ENGLISH: "No"
VERDICT: APPROVE
REASONING: Inverse of "Yes" in the same register.
RISKS: none

STRING: androidRemote
KEYS: androidRemote
ENGLISH: "Android TV Remote"
VERDICT: APPROVE
REASONING: Diagnostics is the one surface where the transport's real name helps, and this is the name the platform itself uses, so a search for it finds the right documentation.
RISKS: none

STRING: sonyApi
KEYS: sonyApi
ENGLISH: "Sony controls"
VERDICT: APPROVE
REASONING: Keeps the vendor name, which the user needs, while dropping "API", which tells them nothing about what the row governs.
RISKS: none

STRING: vnc
KEYS: vnc
ENGLISH: "VNC"
VERDICT: APPROVE
REASONING: Matches the VNC port and password fields, so a diagnostics row points back at the settings that control it.
RISKS: none

STRING: latency
KEYS: latency
ENGLISH: "Response time"
VERDICT: APPROVE
REASONING: Replaces the engineering term with the plain one without losing precision — exactly the right trade on a row a non-expert reads while troubleshooting.
RISKS: none

STRING: model
KEYS: model
ENGLISH: "Model"
VERDICT: APPROVE
REASONING: The word printed on the TV's own information screen.
RISKS: none

STRING: firmware
KEYS: firmware
ENGLISH: "Software version"
VERDICT: APPROVE
REASONING: "Software version" is what TV settings screens call it, so the user can compare the two values; "Firmware" would be the app inventing its own term.
RISKS: none

STRING: serviceVersion
KEYS: serviceVersion
ENGLISH: "Remote service version"
VERDICT: APPROVE
REASONING: Distinguishes the control service's version from the TV's own software version on an adjacent row.
RISKS: none

STRING: capabilities
KEYS: capabilities
ENGLISH: "Detected capabilities"
VERDICT: APPROVE
REASONING: "Detected" is the key word — it frames the list as what was found, not what exists, preserving the unknown-is-not-unsupported line at the row level.
RISKS: none

STRING: errors
KEYS: errors
ENGLISH: "Service errors"
VERDICT: APPROVE
REASONING: Qualified so it cannot be read as errors in the app itself.
RISKS: none

STRING: copyReport
KEYS: copyReport
ENGLISH: "Copy diagnostic report"
VERDICT: APPROVE
REASONING: Names the artifact being copied, which matters because the user is about to paste it somewhere.
RISKS: none

STRING: reportCopied
KEYS: reportCopied
ENGLISH: "Diagnostic report copied."
VERDICT: APPROVE
REASONING: Echoes the action's noun so the confirmation is unmistakably about that button.
RISKS: none

STRING: testConnections
KEYS: testConnections
ENGLISH: "Test connections"
VERDICT: APPROVE
REASONING: Plural is correct — several transports are tested — and "Test" sets the expectation that nothing on the TV changes.
RISKS: none

STRING: refreshCapabilities
KEYS: refreshCapabilities
ENGLISH: "Refresh capabilities"
VERDICT: APPROVE
REASONING: Uses the same noun as the row it updates, so the button and its target are visibly connected.
RISKS: none

STRING: reboot
KEYS: reboot
ENGLISH: "Restart TV"
VERDICT: APPROVE
REASONING: "Restart" rather than the key's "reboot" is the plainer word, and naming the TV marks this as acting on the device, not the app.
RISKS: none

STRING: rebootTitle
KEYS: rebootTitle
ENGLISH: "Restart this TV?"
VERDICT: APPROVE
REASONING: Question-form title reusing the action verb, consistent with the Forget dialog.
RISKS: none

STRING: rebootBody
KEYS: rebootBody
ENGLISH: "Playback will stop while the TV restarts."
VERDICT: REWORD
REWRITE: "The TV will turn off and start again. Anything playing will stop."
REASONING: The current body only speaks to a user who is mid-playback; for everyone else it describes a consequence that does not apply, and it never states the main one — the TV goes dark for a while. The rewrite leads with the universal effect and keeps the playback consequence as the second sentence.
RISKS: none

STRING: restart
KEYS: restart
ENGLISH: "Restart"
VERDICT: APPROVE
REASONING: Confirm button repeating the title's verb.
RISKS: none

STRING: customize
KEYS: customize
ENGLISH: "Customize remote"
VERDICT: APPROVE
REASONING: Names the surface being customized using the tab's own noun, so the user knows what will change.
RISKS: none

STRING: resetLayout
KEYS: resetLayout
ENGLISH: "Reset layout"
VERDICT: APPROVE
REASONING: Scopes the reset to arrangement only, so a user does not fear losing saved TVs or shortcuts.
RISKS: none

STRING: moveUp
KEYS: moveUp
ENGLISH: "Move up"
VERDICT: APPROVE
REASONING: Reorder action naming direction of travel in list terms.
RISKS: none

STRING: moveDown
KEYS: moveDown
ENGLISH: "Move down"
VERDICT: APPROVE
REASONING: Exact inverse of "Move up".
RISKS: none

STRING: hold
KEYS: hold
ENGLISH: "Hold button"
VERDICT: REWORD
REWRITE: "Press and hold"
REASONING: In a surface full of button names ("Volume up", "Mute", "Guide"), "Hold button" parses as the name of a button called Hold rather than as an action performed on one. "Press and hold" can only be read as a gesture, and it matches how the platform announces the same interaction.
RISKS: none

STRING: release
KEYS: release
ENGLISH: "Release button"
VERDICT: REWORD
REWRITE: "Release"
REASONING: Applied uniformly with its pair: the trailing noun creates the same button-name misreading, and once the hold action names the gesture rather than the object, its inverse must match.
RISKS: none

STRING: macros
KEYS: macros
ENGLISH: "Shortcuts"
VERDICT: APPROVE
REASONING: Correctly ships the user-facing noun from the glossary rather than the internal word "macros", which would be the app naming a thing after its implementation.
RISKS: none

STRING: addMacro
KEYS: addMacro
ENGLISH: "Add shortcut"
VERDICT: APPROVE
REASONING: Uses the shipped noun, matching the section title and the empty state.
RISKS: none

STRING: shortcutName
KEYS: shortcutName
ENGLISH: "Shortcut name"
VERDICT: APPROVE
REASONING: Noun-phrase field label following the same pattern as "TV name".
RISKS: none

STRING: steps
KEYS: steps
ENGLISH: "Steps"
VERDICT: APPROVE
REASONING: Names the sequence in the term the empty state and the Add action both use.
RISKS: none

STRING: addStep
KEYS: addStep
ENGLISH: "Add step"
VERDICT: APPROVE
REASONING: Singular object is correct for one insertion, and it matches the section heading.
RISKS: none

STRING: run
KEYS: run
ENGLISH: "Run"
VERDICT: APPROVE
REASONING: The verb the empty state promises ("to run a sequence"), so the button fulfils the description.
RISKS: none

STRING: stopShortcut
KEYS: stopShortcut
ENGLISH: "Stop shortcut"
VERDICT: APPROVE
REASONING: Qualifying this one prevents any collision with the media Stop key, which is the reason that one can stay bare.
RISKS: none

STRING: wakeStep
KEYS: wakeStep
ENGLISH: "Wake TV"
VERDICT: APPROVE
REASONING: "Wake" is meaningfully different from "Turn on" — it is the step that works from Standby — and it is bound to the "Waking TV…" and "Standby" strings the user already sees.
RISKS: none

STRING: homeStep
KEYS: homeStep
ENGLISH: "Go Home"
VERDICT: APPROVE
REASONING: Capitalised Home names the platform's own destination, matching the remote button of the same name, and the verb keeps the step list parallel.
RISKS: none

STRING: inputStep
KEYS: inputStep
ENGLISH: "Select input"
VERDICT: APPROVE
REASONING: Reuses the Input noun and signals that this step takes a parameter.
RISKS: none

STRING: appStep
KEYS: appStep
ENGLISH: "Launch app"
VERDICT: APPROVE
REASONING: Same verb as the Apps tab action, so one operation has one name across two screens.
RISKS: none

STRING: waitStep
KEYS: waitStep
ENGLISH: "Wait for TV"
VERDICT: REWORD
REWRITE: "Wait for the TV to be ready"
REASONING: "Wait for TV" leaves the condition unstated, so a user building a shortcut cannot tell whether this step waits on a state or on a duration they must supply. Naming readiness states the semantic that distinguishes this step from a fixed delay, and it ties back to the "Ready" status.
RISKS: none

STRING: noMacros
KEYS: noMacros
ENGLISH: "Create a shortcut to run a sequence of TV actions."
VERDICT: APPROVE
REASONING: Explains the feature and names the first action in one sentence, using the shipped noun and the button's own verb.
RISKS: none

STRING: networkChanged
KEYS: networkChanged
ENGLISH: "The phone’s network changed. Reconnecting on the current network…"
VERDICT: REWORD
REWRITE: "The phone’s network changed. Reconnecting on the new network…"
REASONING: "Changed" and "current" in consecutive clauses leave the user unsure which of the two networks is meant. "New" names it unambiguously against the change just reported.
RISKS: none

STRING: permissionBody
KEYS: permissionBody
ENGLISH: "Allow local network access to find and connect to your TVs."
VERDICT: APPROVE
REASONING: Gives the reason before the request, in terms of what the user wants (finding their TVs) rather than what the system calls the permission.
RISKS: none

STRING: openSettings
KEYS: openSettings
ENGLISH: "Open settings"
VERDICT: REWORD
REWRITE: "Open phone settings"
REASONING: This app has its own Settings surface, so an unqualified "Open settings" beside a permission message points at two different destinations. Naming the phone resolves it and matches the "this phone" vocabulary used elsewhere.
RISKS: none

STRING: authFailed
KEYS: authFailed
ENGLISH: "Authentication failed. Check the saved credentials."
VERDICT: REWORD
REWRITE: "The TV did not accept the saved credentials. Check them and try again."
REASONING: "Authentication failed" is an abstraction that names no actor; the user cannot tell whether the app, the network, or the TV refused. "Credentials" stays, because unlike the pairing artifact in the Forget dialog, these are fields the user typed by hand and can go back to.
RISKS: none

STRING: pairingFailed
KEYS: pairingFailed
ENGLISH: "Pairing failed. Check the TV code and try again."
VERDICT: REWORD
REWRITE: "Pairing failed. Check the code shown on your TV and try again."
REASONING: "The TV code" is a noun that appears nowhere else in the app. The rewrite uses the same phrase as the instruction directly above it in the same dialog, so the user is sent back to a thing they have already been told about.
RISKS: none

STRING: identityChanged
KEYS: identityChanged
ENGLISH: "The TV’s identity changed. Pair again before controlling it."
VERDICT: REWORD
REWRITE: "The TV’s security identity changed. It may have been reset, or another device may be answering. Pair again before controlling it."
REASONING: This is the app's one security warning and it currently reads as a routine notice. The user needs to know both readings before they re-pair: the benign one (the TV was reset) and the one that should make them stop (something else is answering at that address). Naming both is accurate and avoids alarming a user whose TV was simply factory reset.
RISKS: none

STRING: connectionFailed
KEYS: connectionFailed
ENGLISH: "Could not connect. Check the address and local network."
VERDICT: APPROVE
REASONING: States the outcome without guessing the cause, then names the two things the user can actually inspect.
RISKS: none

STRING: notSent
KEYS: notSent
ENGLISH: "The command was not sent."
VERDICT: APPROVE
REASONING: Exact about delivery and claims nothing about the TV's state — the correct form when the app knows only that transmission failed.
RISKS: none

STRING: commandUnconfirmed
KEYS: commandUnconfirmed
ENGLISH: "The command was sent without confirmation."
VERDICT: REWORD
REWRITE: "The command was sent, but the TV did not confirm it."
REASONING: "Sent without confirmation" reads as the app having skipped a confirmation prompt — a live misreading in an app that genuinely has confirmation dialogs for Forget and Restart. The rewrite makes the TV the one that stayed silent and matches the parallel text message, so the same situation reads the same way in both places.
RISKS: none

STRING: privateOnly
KEYS: privateOnly
ENGLISH: "Use a local TV address."
VERDICT: REWORD
REWRITE: "Enter an address on your local network."
REASONING: The other two validation errors both begin "Enter…" and both state what would be acceptable; this one breaks the pattern and says "local TV address" without defining it. Naming the local network gives the user a criterion they can check.
RISKS: none

STRING: invalidPort
KEYS: invalidPort
ENGLISH: "Enter a port from 1 to 65535."
VERDICT: APPROVE
REASONING: Gives the exact accepted range, which is the only thing that lets a user fix a rejected port without guessing.
RISKS: RTL — the numeric range is bidi-neutral; it must stay a single unbroken unit so the bounds do not visually reverse.

STRING: invalidMac
KEYS: invalidMac
ENGLISH: "Enter the TV’s network MAC address."
VERDICT: APPROVE
REASONING: Follows the "Enter…" pattern and names the field verbatim. Adding a format example would imply a single accepted separator, which is not established and would be a limitation invented by the copy.
RISKS: none

STRING: classicVnc
KEYS: classicVnc
ENGLISH: "Classic VNC uses only the first eight password bytes and does not encrypt the screen connection."
VERDICT: REWORD
REWRITE: "Classic VNC uses only the first eight characters of the password and does not encrypt the screen connection."
REASONING: "Password bytes" is meaningless to a user choosing a password; they think in characters, and characters is what they must act on. The disclosure's second half — no encryption — is well judged and stays exactly as drafted.
RISKS: none

STRING: noAudioSaved
KEYS: noAudioSaved
ENGLISH: "Microphone audio is sent to the TV and is not saved."
VERDICT: REWORD
REWRITE: "Microphone audio is sent to the TV. This app does not save it."
REASONING: An unattributed "is not saved" reads as a guarantee that nobody keeps the audio, including the TV and whatever service it forwards voice to — a promise this app cannot make about another device. Naming the app as the subject keeps the reassurance while confining the claim to what it can actually answer for.
RISKS: none

STRING: captureApproval
KEYS: captureApproval
ENGLISH: "Screen sharing needs approval on the TV."
VERDICT: APPROVE
REASONING: Reads correctly both as a status value and as a prompt, which matters because its placement is not fixed; an imperative rewrite would work in one position and read oddly in the other.
RISKS: none

STRING: light
KEYS: light
ENGLISH: "Light"
VERDICT: APPROVE
REASONING: Conventional theme name, paired exactly with its opposite.
RISKS: none

STRING: dark
KEYS: dark
ENGLISH: "Dark"
VERDICT: APPROVE
REASONING: Inverse of "Light" in the same one-word form.
RISKS: none

STRING: systemTheme
KEYS: systemTheme
ENGLISH: "Use device theme"
VERDICT: REWORD
REWRITE: "Use phone theme"
REASONING: In this app "device" is the TV — that is the glossary — so "device theme" invites the reading that the phone's appearance follows the television's. Every other string calls the local machine "this phone"; using that noun here removes the collision with one word changed.
RISKS: none

COPY REVIEW COMPLETE: 186 strings (160 approved, 26 reworded)
