REVIEW-ID: 383a1357-6977-49c8-ad60-726dce53373c
DATE: 2026-09-21
REVIEWER: content-strategist (Claude CLI, cross-model)
ARTIFACT: /Users/amsh/worktrees/tvVNC/worktree/docs/reviews/copy-product-name.md
DESCRIPTOR: none — derived from rendered app and English inventory; copy gate remains proposed, not installed.

Both renders confirm the brief exactly: the app bar reads **TV Console** on the empty and the populated home, the section heading is **Your TVs**, the empty state is **Add a TV to get started.**, and the two actions are **Find TVs** and **Enter address**. The populated screen adds a card with the owner's saved TV name and private address (redacted for publication), rather than product copy. One detail matters for the verdict and is only visible by looking: the word "Console" occurs exactly once per screen, in the app bar, and nowhere else in the inventory — no other string builds on it.

`★ Insight ─────────────────────────────────────`
- A product name review is not a taste test. The three things a content strategist can actually falsify are: does the name use the product's own nouns, does it make a factual claim the product doesn't honour, and does it fit the boxes it renders into.
- "Orphan noun" is the useful test here. "Console" is a metaphor no other string in the app picks up, so it was carrying zero meaning across the rest of the interface; "TV" is the noun every other string already uses.
- Jargon rules bend for audience and for *role*. An acronym in a button label is a comprehension tax; the same acronym as a proper name on a launcher icon is just a name.
`─────────────────────────────────────────────────`

STRING: the product's proper name, occupying the launcher label, the home app-bar title, the drawer heading, and the controller identity announced to an Android TV during pairing.

KEYS: appTitle; Android application label; Android TV controller clientName/model identity.

ENGLISH: "TV VNC"

VERDICT: APPROVE

REASONING:

The name is the owner's explicit instruction, and the owner is not merely the requester here — on a LAN-only tool running against their own television, the owner is the entire audience. That collapses most of the usual content-strategy objections to a product name, because there is no second reader whose comprehension I am protecting. What remains for me to check is narrower and answerable: whether the name contradicts something the interface says, whether it collides with the vocabulary the interface already uses, and whether it fits where it renders. It passes all three.

On vocabulary, the app's own noun for the thing it connects to is "TV", and it is used with complete consistency in the shipped copy: "Your TVs" as the section, "Find TVs" as the primary action, "Add a TV to get started." as the empty state, and a card carrying a television glyph. "TV VNC" is built from that same noun, so the name and the screen beneath it speak the same language. "Console" did the opposite — it is a metaphor that appears only in the app bar and is picked up by no other string, no menu item, and no button, which makes it an orphan. Replacing an orphan noun with the product's own established noun is a consistency improvement, not merely a lateral move, and that is the strongest argument for the change independent of who asked for it.

On the acronym, I want to be explicit rather than permissive by reflex, because "unexplained initialism in user-facing copy" is normally a rework. VNC stands for Virtual Network Computing, the remote-screen protocol that lets one device display and control another's screen. Two facts save it. First, the audience: a single technical owner who installed a LAN-only remote-presence tool and who will read "VNC" as a precise description of what they built rather than as noise. Second, and more durable, the role: this string lives only on identity surfaces — the icon under the app on the home screen, the heading at the top of the drawer, the name the television shows during pairing. It is never asked to instruct. No button, error, empty state or toast says "VNC", so no user task depends on decoding it. A proper name is permitted to be a name.

On accuracy, the brief's role statement is correct and I am approving it on those terms: the name identifies the app, it does not promise that every operation runs over VNC. That distinction matters because the app carries three transports — the VNC live screen, the Sony controls, and the Android TV Remote — and a name that foregrounds one of three would be a defect if names were read as feature lists. They are not, and nothing in the visible copy contradicts the name. Worth noting that the outgoing name had the same property in the opposite direction: "TV Console" implied a console metaphor that no screen delivered.

On fit, "TV VNC" is six characters against "TV Console" at ten. The app bar currently renders the longer name across roughly a fifth of the available width, so the shorter name fits everywhere the old one did with margin to spare. The direction of change is strictly favourable for every truncating container, which is why the missing large-text and dark renders do not block this verdict — though they also do not constitute proof, and I have listed that under risks rather than quietly treating it as settled.

On casing, "TV" and "VNC" are both initialisms and both correctly rendered in capitals. This does not conflict with any sentence-case convention in the app, partly because a proper name governs its own casing and partly because the surrounding copy already carries capitalised "TV" in "Your TVs" and "Find TVs".

RISKS:

1. Tautology on the television's own screen. During pairing, the TV displays the controller's identity on a TV, so the phrasing lands as something close to "TV VNC wants to pair" shown on a television. It is mildly redundant, though not confusing, and the user's matching task — recognise the name that matches the icon in their hand — still works perfectly. I cannot see this surface: the brief states the native pairing-code UI has not been reached because of a separately diagnosed TLS error.

2. Doubled name during pairing. The brief assigns one string to both `clientName` and the model identity. Android TV pairing surfaces commonly show a client name and a model together, so the TV may end up displaying the name twice, for example "TV VNC (TV VNC)". That is a duplication artefact of one string feeding two fields rather than a fault in the words themselves, but it is the kind of thing that only appears in the render, and it should be checked when the TLS error is cleared and that screen is finally reachable.

3. The name does not explain itself to anyone who is not the owner. "VNC" carries no meaning for a household member handed the phone, and it is not a term anyone would search for. This is entirely acceptable at the current scope, which the brief records as LAN-only and owner-operated, and I am not asking for a change on speculation. It is simply the condition under which the approval holds: if the app is ever shared with a non-technical user or published, the name stops doing explanatory work and should be revisited then.

4. The name is pinned to one of three capabilities, so it will not age with the feature set. If the VNC screen ever stops being the centre of the product, the name will quietly become the least descriptive part of the interface. Acceptable for a proper name today; worth remembering as a deliberate choice rather than an accident.

5. Large-text and dark-theme rendering of this specific string is unproven. The brief discloses that no dark or double-size-name render is attached, and I am approving on the shorter-string argument above, not on evidence. The rendered layout validation still has to happen after the build.

BRIEF DEFECT: No launcher render is attached, yet the launcher label is one of the three named surfaces and is the one with the tightest truncation box — the Android home screen clips app labels far earlier than an app bar does. The two supplied app-bar captures cannot stand in for it, so the launcher surface was judged by argument rather than by looking.

BRIEF DEFECT: The brief does not state whether the outgoing string "TV Console" appears anywhere else in the English inventory — a notification channel name, an about or settings row, share text, an accessibility label, a backup or service description. Without that line I can approve the name itself but cannot confirm the rename will be complete, which leaves open the possibility of a stale "TV Console" surviving on an unlisted surface and contradicting the new identity.

BRIEF DEFECT: The brief states that one string supplies both the controller `clientName` and the model identity, but supplies neither a render nor the final composed text of that pairing surface, so the doubled-name outcome in risk 2 cannot be confirmed or ruled out from the brief alone.

COPY REVIEW COMPLETE: 1 strings (1 approved, 0 reworded)
