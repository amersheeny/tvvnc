REVIEW-ID: cdff546d-32d1-4d3a-8096-898d86b49246
DATE: 2026-09-23
REVIEWER: content-strategist (Claude CLI, cross-model)
ARTIFACT: /Users/amsh/worktrees/tvVNC/worktree/docs/reviews/copy-privacy-policy.md
DESCRIPTOR: none — derived from current app copy, implementation and Google Play requirements.

The reviewer's verdicts for all three strings are complete and are restated below exactly as delivered. The two REWORD verdicts are the finished review, not unfinished work. The brief said this is "Read-only: no edits, builds, tests or device operations" and "not a request to implement or publish anything". Plan mode for this session also forbids edits. So nothing was applied to the copy file, and there is no open choice to put to the user. The team that commissioned the review applies the approved text.

STRING: privacy

KEYS: privacy
ENGLISH: "Privacy policy"
VERDICT: APPROVE
REWRITE: none
REASONING: None of the corrections affect this string. It is the name people already use for this document, and it uses sentence case like the drawer destinations beside it, such as "All buttons". It works as both the drawer destination and the app-bar title, so the drawer item names exactly the page it opens. It does not suggest that opening the page gives consent, grants microphone access or starts a connection.
RISKS: On the rendered screen, check that the app-bar title is announced as the page heading. If other drawer items have icons, give this one a matching icon. Neither can be checked until the screen exists.

STRING: privacyUnavailable

KEYS: privacyUnavailable
ENGLISH: "The privacy policy could not be loaded. Contact support@apptico.com."
VERDICT: REWORD
REWRITE: "The privacy policy couldn’t be shown. Go back and try again, or contact support@apptico.com."
REASONING: This is the rewrite already accepted in the last round. Root's source check confirms the claim behind "Go back and try again": each new page instance retries the load, and Back stays visible the whole time, so the free, immediate step now comes first. "Shown" describes what the person sees, where "loaded" is engineering language. "Couldn’t" with a curly apostrophe matches the app's existing error style. The email address stays as plain text so it can be selected and copied.
RISKS: The public address https://amersheeny.github.io/tvvnc/ would be a useful third fallback here. Root has said it is planned and not yet live, so it is left out of this string: a link that does not work yet is a dead end at exactly the moment the person is stuck. Once the address is confirmed to serve the policy, adding "or read it at https://amersheeny.github.io/tvvnc/" would be a separate copy change that needs its own review.

STRING: privacy.policy

KEYS: privacy.policy
ENGLISH: the complete policy text reviewed and retained from the previous round, with root's five verified corrections and the public address applied below.
VERDICT: REWORD
REWRITE:
TV VNC Privacy Policy
Effective date: 23 September 2026
Developer: Apptico LTD
Contact: support@apptico.com
Online copy: https://amersheeny.github.io/tvvnc/

TV VNC lets you view and control a compatible TV on your private network from your phone. Use it only with the TV owner's permission. You do not need a TV VNC account. The app has no advertising and no analytics. Your information does not pass through any Apptico LTD server, and the app does not upload anything to Apptico LTD automatically.

Information the app uses
TV VNC uses the TV's address, your saved connection settings and pairing details to connect to your TV. From the TV it receives the screen image and, when the TV provides them: device and service details, installed apps and inputs, power and volume status, and the text in the TV field you are typing into. Your button presses, typed or pasted text, and the apps and inputs you choose are sent to the TV so it can carry out what you ask. When searching for TVs, the app looks for compatible services on your local network. If you enter a TV by name rather than by number address, your network's name lookup service (DNS) may see that name.

Microphone
Voice input is optional. TV VNC asks for microphone permission when you try Voice on a compatible connected TV and permission has not been granted. Granting permission does not start recording; hold Voice again to speak. While you hold Voice, TV VNC records your speech and sends it to the TV as you speak. Recording stops when you release Voice or leave the app. TV VNC does not save audio. The TV's voice assistant may send your speech to its own provider, which may keep it under that provider's privacy policy.

What is stored on your phone, and for how long
Saved TVs, passwords and Sony keys are encrypted on your phone using Android's secure key storage (Android Keystore). The private keys used for Android TV Remote pairing are kept inside Android Keystore. Connection preferences, and the TV security certificates the app has accepted, are kept in the app's private storage on your phone. Favorites, Recent apps, your remote button order and Shortcuts stay on your phone. Keyboard editing drafts are temporary: TV VNC keeps them in the app's working memory and does not write them to a file. Text from fields the TV marks as private, such as passwords, is excluded from drafts remembered for later reuse.

Saved settings stay on your phone until you remove them. Forget TV removes that TV's saved settings and pairing from this phone. Clearing TV VNC's storage in Android settings, or uninstalling the app, removes its private data from this phone. These steps do not remove information already sent to your TV or its apps, screenshots saved to your Pictures folder, or reports and text you copied or shared.

Screenshots, clipboard and diagnostics
Screenshots are saved only when you choose Save screenshot. On Android 10 or later they go to your phone's shared Pictures folder. On Android 8–9 they are kept in storage that belongs to the app. Other apps, and any photo backup service you use, may be able to see pictures in the shared folder. When you tap Paste, TV VNC reads the text on your phone's clipboard. Android's text-selection menu lets you copy or share selected text with apps you choose.

Diagnostic reports are created on your phone and are copied only when you choose Copy diagnostic report. A report may include TV addresses, the TV's MAC (hardware) address, model, software and service versions, connection status and error details. Reports do not include saved passwords, private pairing keys, text you typed into TV fields or images of the TV screen, but they can still identify your TV and network. Check reports and screenshots before sharing them. Apptico LTD receives support information only if you choose to send it, for example by emailing the contact address above. Your email provider handles that email under its own policy.

Connection security
Android TV Remote connections are encrypted (TLS), and the app checks that the TV presents the same certificate it presented when you paired. Classic VNC and Sony controls connections are not encrypted, so other devices on the same network could see or change that traffic. Use them only on a network you trust, and do not make your TV's control services reachable from the internet. This version of TV VNC does not set up a VPN. If you set up a VPN or other private connection yourself, TV VNC's connections can travel through it.

Other services
TV apps, voice assistants, Android, the apps you share to, and the website that hosts this policy each have their own privacy practices. TV VNC does not sell your data or send it to advertising services. Contact support@apptico.com with privacy questions, or with requests about information you sent to support.

REASONING:
- **Correction 1 (Voice).** The rewrite uses root's permission sentence word for word, so it no longer promises a prompt on the first attempt. It adds the short fact that granting permission does not start recording and that the person holds Voice again. This matches the existing in-app message "Microphone access is allowed. Hold to speak again." "While you hold Voice" now follows the compatibility check the permission sentence already states, so it does not repeat the condition. "Which may keep it" replaces "which keeps it", so the policy no longer states as fact how an outside provider behaves.
- **Correction 2 (drafts and keys).** "Never kept as a draft" is replaced with root's narrower sentence. It does not deny that the password field being edited is held in memory while you type. "The private keys used for Android TV Remote pairing" says precisely what Keystore holds. Public certificates are covered by the separate sentence about accepted TV security certificates. The diagnostics sentence now says "private pairing keys" so the two sections use the same term.
- **Correction 3 (how long data is kept).** "Until you remove them" now applies only to saved settings. Drafts get their own temporary, never-written-to-a-file statement in the storage paragraph. The paragraph about Forget TV and clearing app data keeps its exclusions for data already on the TV and for anything exported.
- **Correction 4 (Android versions).** "Android 10 or later" and "Android 8–9" replace "newer" and "older". Naming the versions exposed a contradiction in the previous text. On Android 8–9, screenshots sit in the app's own storage, which clearing data or uninstalling does remove. The exclusion therefore now says "screenshots saved to your Pictures folder" rather than all saved screenshots. For the same reason, "removes all of its private data" becomes "removes its private data", which drops a word the evidence does not support.
- **Correction 5 (button order).** "Your remote button order" replaces the unexplained "layout choices". It describes what Customize remote saves without inventing a new product name.
- **Identity and address.** The header now carries the online copy address. Developer name and contact stay exactly as they were, matching the Play fields root identified. No postal address is added.
- **Unchanged.** Every other sentence is the wording approved in the last round.

RISKS:
- **Address not yet live.** The "Online copy" address is planned, not yet serving. Do not submit the app to Play until the address actually returns this exact text. The website copy and the in-app copy must stay identical, including the effective date.
- **Headings.** The eight section headings must be rendered as real semantic headings, so screen-reader users can jump between sections. Check that on the real rendered screen, with large text and with Back working while text is selected.
- **"Phone" on tablets.** The policy says "phone" to match the app's existing strings. On a tablet this reads slightly off, but it is not misleading. Changing it would mean changing the app-wide noun, not just this document.
- **Accepted certificates.** "The TV security certificates the app has accepted" assumes public certificates are stored alongside connection preferences in private storage. Root placed certificate pins there. If the public pairing certificate lives somewhere else, adjust that clause.
- **Unit coverage.** The Android 8–9 sentence assumes the app's lowest supported version is Android 8. If the app supports older versions, change it to "Android 9 or earlier".

COPY REVIEW COMPLETE: 3 strings (1 approved, 2 reworded)

## Subsequent verified identity-record correction

STRING: privacy.policy.pairedIdentity

KEYS: privacy.policy (single-sentence replacement inside "What is stored on your phone, and for how long")
ENGLISH: "Connection preferences and a record used to check your paired TV's identity are kept in the app's private storage on your phone."
VERDICT: REWORD
REWRITE: "Connection preferences, and records used to check the identity of TVs you have paired, are kept in the app's private storage on your phone."
REASONING:
- **The correction is right.** The approved sentence said "the TV security certificates the app has accepted". Root's reading of how the app remembers a TV's certificate shows that is inaccurate: the app keeps a fingerprint, which is a short code that identifies the certificate, not the certificate itself. "A record used to check … identity" describes that truthfully and plainly, without the words "fingerprint" or "hash". It also matches the sentence under "Connection security", "the app checks that the TV presents the same certificate it presented when you paired", so the two sections now tell one consistent story. A reader understands both what is stored and why.
- **Why one more change.** "Your paired TV's" is singular, but the app is built for several TVs: its drawer destination is "Your TVs", and Forget TV acts on one TV among several. A person who has paired two TVs would read the sentence as saying only one identity record exists. The rewrite uses the plural "records … of TVs you have paired". It does not claim exactly one record per TV, because this review has not seen how the records are keyed.
- **Punctuation.** Commas around the inserted clause keep "Connection preferences" and "records" readable as two separate things stored side by side. Without them, the phrase could run together as "preferences and a record used to check…".
- **Unchanged.** Everything else in the policy and both UI strings stay exactly as approved. That includes the next sentence about Favorites, Recent apps, remote button order and Shortcuts, and the diagnostics wording "private pairing keys".
RISKS:
- **Multiple TVs.** The plural assumes a person can have more than one paired TV with a stored identity record at the same time. That fits the "Your TVs" list, but it was not read from the method that saves the records. If the app only ever keeps one record in total, the approved singular wording is accurate and should be used instead.
- **Scope of "paired".** "Paired" refers to Android TV Remote pairing. Sony registration uses a PIN (a short code the TV displays) and a pre-shared key, which the policy covers separately as "Sony keys". Readers are unlikely to confuse the two, but if Sony registration also stores an identity record, this sentence still covers it only loosely.

COPY REVIEW COMPLETE: 1 strings (0 approved, 1 reworded)
