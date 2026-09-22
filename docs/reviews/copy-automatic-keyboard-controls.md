REVIEW-ID: 4511adc8-c8a2-4a11-908c-14248e81f535
DATE: 2026-09-22
REVIEWER: content-strategist (Claude subscription CLI, cross-model)
ARTIFACT: /Users/amsh/worktrees/tvVNC/worktree/docs/reviews/copy-automatic-keyboard-controls.md
DESCRIPTOR: none — derived from /Users/amsh/worktrees/tvVNC/worktree/assets/copy/en.json and the supplied existing renders

STRING: screenSize
KEYS: screenSize
ENGLISH: 'Screen height'
VERDICT: APPROVE
REASONING: The earlier approval leaned partly on matching the visible caption, and you are right that the justification changed when the caption was removed; the name survives the change on its own merits. As a spoken name it still does the two things a slider name must do: it names the object using the product's own noun, shipped in "Hide screen", "Full screen" and "Screen sharing is unavailable" and carried into the approved compact "Screen options", and it names the dimension that changes, which is what keeps it from being confused with the zoom actions sitting in the same row. Announced with the separate percentage and the standard increase and decrease actions, it produces the ordinary slider announcement shape. The supplied dark landscape capture at /Users/amsh/worktrees/tvVNC/prefill-final-dark-runtime/screenshots/keyboard-wide-ime.png shows these words rendered today as a visible compact cue beside the grip and the overflow dots, so what is ending is this string's visible life, not its usefulness as a name.
RISKS: With no caption and no tooltip, a sighted user meets a four-pixel bar carrying no words at all, so this string can no longer help anyone who is not using a screen reader; that is a consequence of the layout decision rather than of the wording, and it means any future discoverability problem must be solved with an affordance, not by putting these words back. The announcement has never been heard, since the revised arrangement has no render.

STRING: loadTvText
KEYS: loadTvText
ENGLISH: 'Load TV text'
VERDICT: APPROVE
REASONING: Short, verb-led, and directionally unambiguous: "TV text" is plainly the text that is on the television, so the button reads as bringing that text here rather than sending anything out, which matches an action that sends nothing. "Copy" would have been the obvious alternative verb and is unusable on this screen, because Paste and the clipboard already occupy that word. The one thing the label does not say is that the action discards what the user has typed, and that is acceptable only because the warning line directly above it states the replacement explicitly and names this button while doing so; that division, a short button with the cost stated immediately above at the point of decision, is the right one, and it is better than folding "replace" into the label, which would force the warning sentence to say replace twice.
RISKS: The division of labour only holds while the warning line is present and adjacent. If this button is ever shown without that line above it, the label alone is not self-warning and a user who skims will lose typed text, so the two must be treated as a unit in layout and in any future edit.

STRING: pausedEditingBody
KEYS: pausedEditingBody
ENGLISH: 'Text is not being sent automatically. Select Load TV text to replace what is here with the TV’s current text.'
VERDICT: REWORD
REWRITE: Your text is not being sent automatically. Select Load TV text to replace what is here with the TV’s current text.
REASONING: One word, for consistency with the message that occupies the identical position under the identical field in the neighbouring state. That message, which you are keeping unchanged, reads "Your text is not going to the TV. Select Send to try again." Writing "Your text" in one and bare "Text" in the other splits the same idea across two lines the same person meets in the same place on different occasions, and the possessive is also the better of the two on its own merits, since it is the user's text that has stopped moving and saying so is what makes the sentence about them. Everything else in the proposal is right and stays: the present continuous frame reports the ongoing state rather than asserting that the last attempt definitely failed, which keeps it honest about ambiguous delivery; "replace what is here" names the cost at the point of decision; the button is quoted by its exact label; and the typographic apostrophe matches the convention settled in the previous pass.
RISKS: This string is only correct while the button exists. The brief states the button appears only when the television has reported a text field, and that the warning itself shows on pause, conflict or ambiguous delivery, so there is a reachable state in which this line instructs the user to select a control that is not on screen; that gap is recorded below and needs a second string rather than a change to this one. Separately, because the neighbouring sync-failure line now differs from this one only in its verb and its remedy, the two must stay distinct in their openings, as their remedies have opposite consequences for typed text: Send preserves it, this button discards it.

STRING: editorChanged
KEYS: editorChanged
ENGLISH: 'The TV text field changed.'
VERDICT: APPROVE
REASONING: Dropping the old second sentence is required rather than optional, since it told the user to switch to a mode chip that will no longer exist, and the captures at /Users/amsh/worktrees/tvVNC/prefill-final-runtime/screenshots/keyboard-ime-default.png show those chips still present today. What remains is a plain statement of what happened on the far end, with no internal code, no protocol vocabulary, and no claim about whether the user's text arrived, which is exactly what the ambiguous-delivery constraint requires; adding any reassurance about the text would be the one thing this message is forbidden to assert.
RISKS: The word "changed" does not distinguish between a different field becoming active on the television and the same field's contents changing, and I cannot settle which from the brief, so the more precise wording would risk being wrong. The message also states a fact without stating what it means for the user, which is acceptable only if the under-field warning appears at the same moment to carry the meaning; the brief does not say whether the two always co-occur, and that is recorded below.

STRING: hideText
KEYS: hideText
ENGLISH: 'Hide text'
VERDICT: APPROVE
REASONING: The eye control in a text field is a universally understood mask toggle, and naming it by the visible effect is what makes it instantly readable. It also sits correctly in this screen's vocabulary, where "Hide screen" already establishes that a "Hide" label means hiding something on the phone rather than acting on the television, which is precisely the boundary this control must not blur. Crucially, the label is right to describe only the masking and not the keyboard-learning safeguards, because those two behaviours have different lifecycles: masking toggles, while the safeguards persist after revealing until the field is cleared. A label promising privacy would therefore become false on the opposite side of the toggle.
RISKS: Because the label deliberately covers only the visual half, nothing in it tells the user that hiding also stops the phone's keyboard from learning or caching what they type; with the "Private text" chip being removed, that information currently has no home on the planned screen, which is recorded below.

STRING: showText
KEYS: showText
ENGLISH: 'Show text'
VERDICT: APPROVE
REASONING: The exact mirror of its partner, which is what a two-state toggle needs so that a user who learns one side has learned the other. It is also correct in what it withholds: revealing the text does not re-enable the phone's learning or caching for what was already protected, so any wording suggesting that privacy has been switched off would be a false statement, and this label makes none.
RISKS: A user may reasonably infer from "Show text" that showing undoes everything hiding did, which is not true of the safeguards; the label cannot carry that nuance without becoming wrong on the other side, so it belongs in the helper text noted below. Neither toggle state has been rendered.

BRIEF DEFECT: Three items. First, the under-field warning needs a second string for the state where the reload button is absent, because the approved sentence instructs the user to select a control the brief says may not be there, and no single sentence can both name that button and stay true when it is missing; the rewrite above is correct for the button-present case only. Second, removing the "Private text" chip visible in both supplied captures removes the only place the product currently tells the user that their typing is kept out of the phone's keyboard learning and cache, and no string in the planned inventory replaces it, including the fact that those safeguards continue after the text is revealed until it is cleared; that is user-facing information disappearing with a layout change rather than a defect in the two toggle labels. Third, the brief does not say whether the transient "The TV text field changed." always appears alongside the under-field warning; if it can appear alone, the user is left with a statement about the television and nothing about their own text.

COPY REVIEW COMPLETE: 6 strings (5 approved, 1 reworded)
