Checked. Confirming your design, with one required addition it does not yet name.

## Sticky sensitivity — confirmed, and my correction was wrong

**My proposed fix was defective in both directions and I withdraw it.** I wrote that the buffer should be discarded "whenever `value || private` holds" — which is true on entry and on exit, so it clears on both transitions. You are right about what each half destroys. Clearing on entry wipes text the user has just decided to protect, at the exact moment they reach for the protection, which is the worst possible time to lose it. Clearing on exit destroys the reveal gesture, which is the ordinary "show what I typed" behaviour and the main reason anyone deselects the control. I proposed repairing an invariant by removing two legitimate behaviours — the same shape of error I have spent this review flagging in your work, arriving from my side.

**Sticky sensitivity closes my exact trigger.** Walking it through step by step: selecting Private sets the flag and removes the already-cached ordinary entry, which is necessary because `schedule()` runs `keepCompose()` on every keystroke, so ordinary text typed before the toggle is already in the cache and must be evicted. Typing under the flag never caches. Deselecting reveals the text while the flag persists, so the cache still refuses it — which is precisely the step my finding named. A context change, lifecycle change or editor change discards the sensitive buffer rather than persisting it, and disposal cannot retain it because the same refusal governs the `keepCompose()` call in `dispose()`. The value never reaches the cache on any path I can construct. Ending sensitivity only on an explicit clear or emptying, and only while masking is off, is the right boundary: a select-all-and-overtype never passes through empty, so the flag survives an edit, which is the safe direction.

It also costs one boolean rather than a second store, so it is the smaller change as well as the better one.

## Required addition: the same root cause reaches a second sink that leaves the device

Your resolution says "send uses sensitive flag for privateText safety". That covers `send`. It does not cover the other call site, and that one is worse than the cache I reported.

The screen-sharing clipboard section in the keyboard screen is gated `if (!private)` — so it becomes visible **exactly when the user reveals** a private buffer. Its first button calls `widget.model.command(CommandKind.paste, origin: origin, value: text.text)` with no privacy argument, and `command` declares `bool privateText = false`, so the command carries false. On the native side `vncPort.accepts` reads `CommandKind.PASTE -> !command.privateText`, so the command is accepted and the revealed text is written to the television's clipboard over the plaintext local screen-sharing protocol.

That is the same conflation of masking with sensitivity, reaching a sink that puts the value on another device and leaves it there. My finding only named the in-memory cache; this is strictly more serious, and any fix that closes the cache while leaving this open has fixed the lesser half.

**Smallest correction:** change that section's condition from `!private` to `!sensitive`, so the clipboard affordance is simply absent while the buffer is sensitive, whether masked or revealed. I prefer hiding it over passing `privateText: sensitive` at the call site, for a concrete reason rather than taste: if the flag is passed while the section stays visible and the screen-sharing transport is the only one available, `accepts` returns false, no transport takes the command, and the user is told "unsupported" — which is a misleading explanation for "we declined to put your password on the television's clipboard". Passing the flag is a valid alternative if you would rather keep the section visible with its own explanation; either way the correction has to reach this call site.

**One thing not to change while you are in there.** The asymmetry between the two command kinds is deliberate and correct: `CommandKind.TEXT` gates only on `!command.replaceText` and does not consult the privacy flag, while `CommandKind.PASTE` does. Typing sensitive text into a television field is the user's explicit intent when they press Send; leaving it resident in the television's clipboard is not. Adding a privacy gate to the text path would break sending on any television where the screen-sharing transport is the only text route.

## Two additions to your regression plan

Your plan — type under privacy, reveal, assert the cache is empty, then leave, reopen, background and change context asserting nothing sensitive is restored, plus clearing a revealed buffer and confirming ordinary caching resumes — covers the cache sink completely.

Add, first, a case that types under privacy, reveals, and asserts the revealed value cannot reach the television clipboard: either the section is absent or the command carries the privacy flag. Without it the second sink has no guard and the fix could pass every listed test while leaving the worse leak open.

Add, second, an assertion on the input-client identity across the ending of sensitivity. When a revealed sensitive buffer is cleared and the flag drops, the field's identity changes and Android is handed a new input client configured for ordinary multi-line text. That transition happens while the field is empty so nothing is lost, but it is the moment the keyboard stops suppressing suggestions and learning, and it deserves the same explicit check the entry transition already has.

## A limit of my own previous pass

Your separate product reviewer found that the wrapper introduced around unavailable controls loses the button's minimum width because the surrounding stack passes loose constraints, putting the marker outside the tap target. I inspected that same wrapper last pass and reported it clean. I was judging contrast and accessibility semantics, which I could settle from source, and I did not evaluate what wrapping a size-constrained button in a stack does to its layout — which cannot be settled from source and needs a rendered capture. The finding is theirs and the rendered evidence outranks my static reading; I am recording that my clean verdict on that wrapper was narrower than it sounded. The constraint-passthrough correction with fail-before width and marker-tap tests is the right shape, and adding the missing active-undo captures closes the other gap in that set.

## Standing

The privacy defect stays open until the fix set lands, now with the clipboard sink named as part of it. I raise no other findings this turn, since this is a resolution call rather than a re-review. The shrinking fix remains verified. Hardware access, the copy-gate approval and fork publication remain open and user-owned, and no receipt is claimed.

---

## Evidence

**Claim: my proposed correction cleared the buffer on both privacy transitions.** My previous message stated the correction as "clear the draft for the current context and replace the buffer with an empty value whenever `value || private` holds, then set `private`." The expression `value || private` evaluates true when the toggle is being switched on, because `value` is then true, and also when it is being switched off, because the old `private` is still true at that moment. That is what makes both transitions destructive, which is what you objected to and what I am conceding.

**Claim: ordinary text is already in the cache before a user marks it private.** In `/Users/amsh/worktrees/tvVNC/worktree/lib/ui/keyboard_page.dart`, the text field's `onChanged` handler is `(_) => schedule()`, and `schedule()` begins with `keepCompose();`, whose body is `if (!private && !live) widget.model.rememberDraft(draftContext, text.value);`. Because that runs on every keystroke while privacy is off, the text is written to the cache as it is typed, which is why the eviction your design keeps on the entry transition is necessary rather than optional.

**Claim: the screen-sharing clipboard section appears only when privacy is deselected.** Reading lines 360 to 392 of the same file shows `if (private)` guarding a short explanatory paragraph, immediately followed by `if (!private)` guarding the `ExpansionTile` that contains the clipboard buttons. A section rendered under `!private` is by construction visible exactly in the revealed state, which is what places it on the path my finding described.

**Claim: the clipboard button sends the field's current text with no privacy argument.** The same excerpt shows the first button's handler as `widget.model.command(CommandKind.paste, origin: origin, value: text.text,)` — three named arguments, none of them the privacy flag. Because the argument is omitted, the parameter default applies.

**Claim: the privacy argument defaults to false.** `grep -n "bool privateText" lib/model/tv_model.dart` printed `201:    bool privateText = false,`. A default of false means an omitted argument produces a command marked non-private.

**Claim: the native layer accepts a non-private paste onto the screen-sharing transport.** `grep -n -A8 "private val vncPort"` in `android/app/src/main/kotlin/dev/tvvnc/tv_vnc/core/TvController.kt` printed the acceptance table, whose line 637 reads `CommandKind.PASTE -> !command.privateText`. With the flag false, the negation is true, so that transport accepts the command and the text is written to the television's clipboard.

**Claim: the text command deliberately does not consult the privacy flag.** The same acceptance table shows line 636 as `CommandKind.TEXT -> !command.replaceText`, with no reference to the privacy flag, alongside the paste line that does reference it. Two adjacent entries treating the flag differently is what shows the asymmetry is a choice rather than an oversight, and why adding a gate to the text entry would remove a working route.

**Claim: the field's identity already changes with the privacy mode, so the new-client mechanism exists.** The text field in the same file is declared with `key: ValueKey(private)` directly above a comment reading "Android's current text-input channel does not implement updateConfig. A security-mode change needs a new client, not merely obscured Flutter pixels over the old IME flags." A key that varies with the mode is what forces a new widget and therefore a new input connection, which is the mechanism your design extends to cover the sensitivity flag as well.

**Claim: the page-owned controller keeps its text across that identity change.** The same file declares `final text = TextEditingController();` as a field of the page's state object, and passes `controller: text` into the field. Because the controller outlives the field widget, replacing the field does not clear the text, which is what makes reveal work and what makes clearing on exit destructive.

## Unverified claims

**That `TextInputType.visiblePassword` actually suppresses suggestions and personalised learning on the specific keyboard the user runs.** You named this yourself as something to be checked against the real keyboard, and I did not read Android's input-type documentation or run anything on a device this turn, because this turn is read-only with no device actions. My agreement that it is the right choice for a visible-but-sensitive field rests on the general meaning of that input type, not on observed keyboard behaviour.

**That hiding the clipboard section is preferable to passing the privacy flag.** I argued this from the error path: with the flag set and no other transport available, the command is refused and the user is shown the generic unsupported message. I traced that path through the acceptance table and the error mapping rather than observing it, and I did not run the application to see what a user actually sees in that situation.

**That a select-all-and-overtype never passes the field through an empty value.** I reasoned that replacing a selection produces a single value change rather than a deletion followed by an insertion. I did not write or run a test to confirm how the text controller reports that interaction, so the conclusion that sensitivity survives an overtype is reasoned rather than observed.

**That the wrapper's layout regression is as the product reviewer describes.** I could not derive it from the source: a stack passing loose constraints should still allow a button to honour its own minimum size, so my static reading does not reproduce their conclusion. I did not view their rendered captures this turn and I am accepting their finding on the strength of rendered evidence over my reasoning, not because I verified it.

**That no path other than the cache and the clipboard reaches sensitive text.** I traced the two sinks named above and checked the live-edit and compose send routes against the acceptance table. I did not exhaustively enumerate every consumer of the text controller across all interface files this turn, so I cannot claim there is no third sink.

## Next steps

**Implement sticky sensitivity, extend the correction to the clipboard call site, and add the two regression cases — yours.** Not done during this turn because you instructed: "RESOLUTION CALL only, no combined pass yet. Read-only, no edits/tests/builds/device actions." The clipboard call site is the part your resolution did not yet name, and it is the one that puts data on another device.

**Apply the constraint-passthrough correction to the unavailable-control wrapper and add the missing active-undo captures — yours, with your product reviewer.** Not done during this turn for the same reason, quoted above. Those are that reviewer's findings and their fail-before tests belong with them.

**Check the visible-sensitive input configuration against the real keyboard on a device — yours.** Not done during this turn because it requires running the application on a device, which this turn's instruction excludes. You have already identified it as needing that check.

**Run the complete fix set and then the combined pass — yours.** Not done during this turn because the fixes do not exist yet and this turn forbids running anything. Running the suites after the whole set rather than after each change is the right order, since a change that satisfies its own test while breaking two others is indistinguishable from a correct one when checked alone.

**Supply the television credentials, the routing to the real device, and the controller model and operating system version, then work the hardware checklist — the user's.** This is the user's because it needs their television, their pairing code, their screen-sharing password and their Sony authentication, plus a phone or tablet that has been asked for and not named. None of that can be produced by you or by me, and the secrets must not be pasted into this conversation.

**Approve or reject the copy-gate proposal — the user's.** It remains proposed and uninstalled. This is the user's because it would introduce a new condition capable of blocking other agents, which requires their approval on the exact text of the change rather than on a summary of it.

**Give both dependency forks publicly reachable addresses before any open-source release — the user's.** Both currently sit at local filesystem paths, so nobody else can build the application from source. This is the user's because publishing a repository is an outward-facing action governed by their own publication rules.
