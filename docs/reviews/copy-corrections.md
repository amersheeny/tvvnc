REVIEW-ID: c7598a74-2b68-4f63-a4d3-ba4570a5c227
DATE: 2026-09-20
REVIEWER: content-strategist (Claude, cross-model)
ARTIFACT: docs/reviews/copy-corrections.md
DESCRIPTOR: none — derived from approved Phase 0 screen specification

`★ Insight ─────────────────────────────────────`
- All three corrections share one shape: each earlier rewrite made the string **more specific** than the draft, and specificity is exactly where copy can newly become false. A character count, a recovery step, and a connection topology are all claims the app cannot honour in every case the string appears in.
- The fix in each case is not to restore vagueness but to move the specificity to a claim that always holds — from "eight characters" to "extra length buys nothing", from "pair again" to "add it again", from "a separate connection" to "try it and see".
- Note that the byte/character distinction also removes the only numeral from the three strings, which incidentally retires the bidi-neutral digit concern flagged elsewhere in this review.
`─────────────────────────────────────────────────`

STRING: classicVnc
KEYS: classicVnc
ENGLISH: "Classic VNC uses only the first eight password bytes and does not encrypt the screen connection."
VERDICT: REWORD
REWRITE: "Classic VNC uses only the beginning of the password and does not encrypt the screen connection. A longer password does not add protection."
REASONING: The earlier rewrite to "eight characters" is withdrawn. For any password containing multibyte characters the truncation point does not fall where a character count predicts, so the string would have told the user their password was protected further than it is — the one error a security disclosure must not make. The replacement drops the count rather than substituting "bytes", because "bytes" is unreadable for a user choosing a password and the count is not the actionable part; what the user must act on is that extra length buys nothing, which the second sentence now states outright. The exact byte semantics belong in the advanced protocol documentation, as proposed. The only departure from the proposed wording is the singular "A longer password": as a plural it reads as a general statement about passwords everywhere and loses its referent, whereas the singular ties it directly to "the password" named one sentence earlier — the user's own.
RISKS: none

STRING: forgetBody
KEYS: forgetBody
ENGLISH: "Saved settings and pairing credentials for this TV will be removed from this phone."
VERDICT: REWORD
REWRITE: "Saved settings and any pairing for this TV will be removed from this phone. Add the TV again to reconnect."
REASONING: The earlier rewrite's "You will need to pair again to reconnect" is withdrawn. For a TV saved with only VNC or Sony controls there is no pairing step to return to, so the dialog would have sent the user looking for a screen that does not apply to their TV — a factual error about the product, not a wording preference. "Add the TV again" holds for every saved TV whatever controls it uses, and it names the app's own button, so the instruction and the control the user must find carry the same word. The same fact reaches the first sentence, which asserted pairing unconditionally; "any pairing" covers the paired and unpaired cases in one word. Applying the correction only to the second sentence would have left the first one making precisely the claim the correction disproved.
RISKS: none

STRING: screenUnavailable
KEYS: screenUnavailable
ENGLISH: "Screen sharing is unavailable. Remote controls can still work."
VERDICT: REWORD
REWRITE: "Screen sharing is unavailable. Try the remote controls."
REASONING: The earlier rewrite's "use a separate connection" is withdrawn. Where the fallback controls ride the same viewing connection, that connection is the one that has just failed — so the reassurance would be false in exactly the circumstances this message appears in, which is the worst possible distribution for an error string. An imperative that claims nothing is the right form precisely because the app cannot know which controls survive a given failure: it gives the user the one useful action and lets the attempt answer the question, rather than the app promising something it may not be able to honour. This also settles the original objection to "can still work", which hedged without telling the user what to do; "Try the remote controls" hedges nothing and is actionable.
RISKS: none

COPY REVIEW COMPLETE: 3 strings (0 approved, 3 reworded)
