REVIEW-ID: 90f4a6b7-cf00-429f-b740-3ccac191dcc3
DATE: 2026-09-23
REVIEWER: content-strategist (Claude CLI, cross-model)
ARTIFACT: /Users/amsh/worktrees/tvVNC/worktree/docs/reviews/copy-tv-setup-note.md
DESCRIPTOR: none — derived from existing app copy and rendered Your TVs screen.

STRING: tvSetupTitle
KEYS: tvSetupTitle
ENGLISH: "Set up screen sharing on your TV"
VERDICT: APPROVE
REWRITE:
REASONING: This is the rewrite from the previous round, and the owner has accepted it. The heading now covers only the feature that needs the TV-side server, so it no longer suggests the whole TV must be set up before the user can add it. It uses the app's own noun "screen sharing," which already appears in "Screen sharing is unavailable…" and "Screen sharing needs approval on the TV." It says the setup happens on the TV, which is the point the owner asked the note to make. A screen reader user moving by headings hears a label that clearly matches the card.
RISKS: At 32 characters, it fits on one line at default text size and wraps cleanly at large text sizes. There are no placeholders and nothing to count.

STRING: tvSetupBody
KEYS: tvSetupBody
ENGLISH: "To show the TV screen on this phone, the TV needs its own VNC server app, such as droidVNC-NG. Install and start it on the TV, then allow screen sharing when the TV asks. Not every TV can install one. Depending on your TV, remote controls can also work through TV pairing or Sony registration."
VERDICT: APPROVE
REWRITE:
REASONING: The correction fixes a real error in the previous round's rewrite. "Remote controls don’t need it" was stated as true for every TV. The verified routing shows that VNC is also a fallback route for remote buttons, so on a TV with neither Android TV Remote nor Sony control, that sentence would be false. The replacement sentence is accurate in both directions:
- "Can also" lets the server carry remote buttons, without saying it always has to.
- "Depending on your TV" is honest that the native routes don't exist on every model.

It also follows on well from "Not every TV can install one." A user whose TV can't run a server learns straight away that the remote may still work. That keeps them from giving up on the app.

The nouns still match the rest of the app:
- "TV pairing" matches the "Pair with your TV" action and the "Pairing code" field.
- "Sony registration" matches "Register Sony controls."
- "Screen sharing," "on the TV" and "on this phone" keep the server-versus-viewer distinction without adding the jargon word "viewer."

The body is four short sentences with one idea each, which works well with a screen reader. No sentence depends on seeing the icon or the layout.
RISKS: Nothing in the sentence says what "also" is relative to, so the reader has to take it as "in addition to the VNC server app" from the paragraph around it. That reading is the natural one, because the server app is the only other thing the card mentions. "Sony registration" is a shortened form of the "Register Sony controls" action, but it is still recognisable. The sentence depends on the verified routing through three connections: the Android TV Remote port, the Sony control port and the VNC port. If a route is removed, this line has to change. "Such as droidVNC-NG" names one compatible server as an example, so it doesn't suggest it's the only one. There are no placeholders and nothing to count.

COPY REVIEW COMPLETE: 2 strings (2 approved, 0 reworded)
