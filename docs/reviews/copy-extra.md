REVIEW-ID: d567f71b-dee0-40d9-b8db-609493bbcc28
DATE: 2026-09-20
REVIEWER: content-strategist (claude, cross-model)
ARTIFACT: docs/reviews/copy-extra.md
DESCRIPTOR: none — derived from the Phase 0 screen specification

STRING: advertised
KEYS: advertised
ENGLISH: "Detected — not tested yet"
VERDICT: REWORD
REWRITE: "Reported by the TV — not tested yet"
REASONING: This value sits inside a section the inventory already calls "Detected capabilities", so the first and most prominent word of the value repeats its own heading and spends the reader's attention on nothing. Worse, "Detected" quietly claims the wrong thing: the app did not detect this capability by exercising it, the TV announced it, and the entire point of this state — against the admitted constraint that a working screen connection does not prove input is permitted — is that nobody has confirmed the announcement. Naming the source ("Reported by the TV") makes the row's three states resolve into a clean ladder for someone diagnosing why a button does nothing: unknown means we have not asked, reported-but-untested means the TV claims it, ready means it has been proven. The rewrite keeps the same two-part shape and the same length class, and it changes only the half that was misattributing the evidence.
RISKS: The em dash separating a source clause from a status clause is not idiomatic punctuation in every locale; translators should be free to substitute a comma, a colon, or a parenthetical. "Reported" must not be rendered as "reportedly" or as a past action the user performed — the reporter is the television.

STRING: keyCode
KEYS: keyCode
ENGLISH: "Android key code"
VERDICT: APPROVE
REASONING: This labels a numeric field in an explicitly advanced area, and it uses the exact term the platform itself uses, which is the same term the reader will have found in whatever reference told them to send code 82 in the first place. Softening it to something friendlier such as "Button number" would actually make the field harder to use, because the user arrives here holding a value that is named "key code" everywhere they found it. The audience is described as a technically comfortable adult, and this is the one surface in the app where a platform term is what the reader is actively looking for rather than something imposed on them. It also reads correctly as a noun phrase with no verb ambiguity.
RISKS: "Android" is a product name and must never be translated or transliterated. "Key code" should be rendered as the platform's own localized term for the same concept where the Android developer documentation has one, rather than translated word by word into something meaning "password" or "cipher", which is a real hazard for the word "code" in several Romance and Slavic languages.

STRING: sendKey
KEYS: sendKey
ENGLISH: "Send key"
VERDICT: REWORD
REWRITE: "Send key code"
REASONING: The button sits directly beside a field labelled "Android key code", and the two should name the same object with the same noun; as written, the field says "key code" and the button says "key", which asks the reader to notice that those are the same thing. "Send key" is also structurally ambiguous in isolation: it parses as an imperative verb plus object ("send the key") or as a compound noun ("the send-key", meaning the key that sends), and the second reading is not exotic — plenty of hardware has a send key. Saying "Send key code" repeats the field's own noun, removes the compound-noun reading entirely because "send-key-code" is not a plausible object, and costs five characters. Nothing else on the surface is competing for that label, so there is no reason to compress.
RISKS: This must be translated as an imperative verb plus a direct object. The verb-versus-noun ambiguity that this rewrite closes in English will re-open in any language where the translator sees only the string and guesses; the note that "Send" is the action and "key code" is the thing being sent needs to travel with the string.

STRING: androidStarting
KEYS: androidStarting
ENGLISH: "Android is starting…"
VERDICT: REWORD
REWRITE: "Waiting for the TV to start up…"
REASONING: The bare subject "Android" is genuinely ambiguous on a phone that is itself running Android — a reader glancing at a progress line can reasonably wonder whether their own handset is restarting something. It is also the wrong level of description for this audience: the reader's mental model contains a television, not an operating system running on a television, and nothing in the app's noun set introduces "Android" as a standalone thing that has states. The more important gain is the change of frame from a bare state to a wait with an owner: "Waiting for the TV to start up" tells someone helping a parent that the delay belongs to the television and that tapping again will not speed it up, which is exactly the behaviour this line needs to produce. It also becomes shape-consistent with the other three progress lines, which all describe what the app is currently doing or awaiting.
RISKS: The trailing ellipsis convention for in-progress states differs by locale (Japanese and Chinese use their own full-width forms) and should be localized rather than copied. "Start up" must be rendered as booting or powering up, not as launching an application.

STRING: tvResponding
KEYS: tvResponding
ENGLISH: "TV is responding…"
VERDICT: REWORD
REWRITE: "Contacting the TV…"
REASONING: The trailing ellipsis marks this as an in-progress step, but "TV is responding" states a fact that has already happened — if the television is responding, the step succeeded and the line should be a milestone rather than a wait. That internal contradiction leaves the reader unsure whether to keep waiting or to expect the next thing immediately. The string also drops the article, whereas every other string in this set writes "the TV" or "this TV", so it reads as clipped status-bar telegraphy inside an otherwise complete-sentence voice. "Contacting the TV…" keeps the in-progress framing the ellipsis promises, restores the article, names the actor doing the waiting, and lines up with the two "Connecting…" lines that follow it in the same progress area.
RISKS: Present-progressive rendering matters: several languages have no continuous aspect and will need their own idiom for an ongoing attempt, not a completed one. Translators must not render this as "The TV answered", which is the meaning this rewrite deliberately moves away from.

STRING: screenConnecting
KEYS: screenConnecting
ENGLISH: "Connecting screen sharing…"
VERDICT: REWORD
REWRITE: "Connecting the TV screen…"
REASONING: "Screen sharing" is a strongly established phrase from video calls and casting, and in both of those the direction is the reverse of what happens here — the phone's screen goes to the other device. A reader who has ever used a meeting app will read this line as the app pushing their phone's display to the television, which is a different feature they might well have been looking for. The app's own noun for this thing is "Screen", used in "Hide screen", "Show screen" and "Screen hidden", and the object being connected is the television's screen arriving on the phone. Saying "Connecting the TV screen…" uses both product nouns, states the direction implicitly and correctly, and removes the casting misread at no cost in length.
RISKS: In languages where "screen" and "display" are separate words with different connotations, choose the word used for a television picture rather than a computer monitor. Do not translate this using the locale's established term for the casting or mirroring feature, which would restore exactly the confusion the rewrite removes.

STRING: remoteConnecting
KEYS: remoteConnecting
ENGLISH: "Connecting remote controls…"
VERDICT: APPROVE
REASONING: "Controls" is already the app's working noun for the things that get sent to the television — it appears in "Sony controls", "Register Sony controls", "send controls" and "sending other controls" — so this line is drawing on vocabulary the reader meets repeatedly rather than inventing a term for the progress area. Paired with the screen line above it, the reader gets a clean two-part picture of what is still being established: the picture and the buttons. It correctly avoids naming any internal mechanism, which is what the brief rules out for consumer surfaces, and it avoids promising which specific service won the connection, which the app cannot know at this moment.
RISKS: "Remote controls" must be understood as the control functions, not as a count of physical handsets; several languages have a single common noun for a handset and a translator working from the string alone could easily produce "connecting the remote handsets", which is wrong and slightly absurd.

STRING: micPermission
KEYS: micPermission
ENGLISH: "Microphone access is ready. Hold Voice again to speak."
VERDICT: REWORD
REWRITE: "Microphone access is allowed. Hold to speak again."
REASONING: The second sentence directs the reader to a control called "Voice", and the screen inventory says the control on the Remote is labelled "Hold to speak" — so the message names a button that does not exist under that name, which is the most concrete kind of copy error because the reader will scan for the word and fail to find it. The rewrite quotes the real label verbatim, so the instruction and the button match letter for letter. The first sentence also needs care against the admitted constraint that granting permission must not start recording: "is ready" can be read as the microphone now being live and listening, which is precisely the impression this message must not create, while "is allowed" describes a permission state and nothing more. Together the two sentences now say exactly what happened (you granted access, nothing is recording) and exactly what to do next (repeat the hold gesture).
RISKS: The word "again" attaches to the holding, not to the speaking — "hold it again in order to speak", never "hold it in order to speak again". This is a genuine trap and the note must travel with the string. "Hold to speak" must be translated identically here and on the button itself, so the two strings should be linked for the translator. "Allowed" should be rendered with the locale's standard permissions vocabulary as used in the platform's own settings, not as a moral permission.

STRING: microphoneUnavailable
KEYS: microphoneUnavailable
ENGLISH: "The phone microphone is unavailable. Check microphone access in phone settings."
VERDICT: REWORD
REWRITE: "The phone’s microphone is unavailable. Check this app’s microphone permission in phone settings."
REASONING: The guidance sentence sends the reader into the phone's settings to look for "microphone access", and on Android there is no such global control to find — what exists is a per-application permission, reached through the app's own entry in Settings. A reader who takes the instruction literally will open Settings, hunt for a microphone switch, not find one, and conclude the app is wrong rather than that they looked in the wrong place. Naming it as this app's microphone permission points at the actual screen using the platform's own word, which is the same discipline as using a product's own nouns. The possessive "the phone's microphone" also reads more naturally than the noun pile "the phone microphone", which momentarily parses as a kind of microphone.
RISKS: "Permission" must use the locale's exact Android settings terminology rather than a legal or interpersonal synonym. "This app" should be rendered so it clearly means the application the reader is currently using, which in some languages needs a demonstrative that does not drift into meaning "that app over there".

STRING: pointerTitle
KEYS: pointerTitle
ENGLISH: "Enable direct touch?"
VERDICT: APPROVE
REASONING: The title uses the product's own noun, "Direct touch", and its verb matches the confirming button exactly, so the reader's eye can travel from the question to "Enable" and find the same word waiting. Phrasing it as a question matches the sibling confirmation on the buttons page, "Send this TV command?", which means the app has one consistent shape for "we are about to do something you should agree to". It is short enough to survive a dialog title line and carries no claim about whether direct touch will actually work, which is the fact the body has to deliver.
RISKS: The title verb and the button verb must be translated with the same lexical root; if one becomes "activate" and the other "switch on", the visual pairing that makes this dialog easy to answer is lost. Question-mark titles are stylistically unusual in some locales and the translator may need to convert to a statement — acceptable, provided the verb still matches the button.

STRING: pointerBody
KEYS: pointerBody
ENGLISH: "Use direct touch only after checking that taps control the expected location on this TV. A connected screen alone does not confirm touch control."
VERDICT: REWORD
REWRITE: "Seeing the TV screen here does not mean taps will work. Turn this on, then watch the TV to check that your taps land where you expect."
REASONING: The instruction as written is circular at the exact moment it is shown: this dialog appears on the first attempt, so the reader is being told to use direct touch only after checking something they cannot check until they turn direct touch on. That leaves them with no move that satisfies the sentence. The rewrite reorders it into the sequence the flow actually runs — the picture arriving is not proof, so switch it on and then watch the television — which also matches the downstream Settings checkbox where they record the result. The second admitted fact, that a working screen connection does not establish that input is permitted, is preserved but stated in terms of what the reader can see ("seeing the TV screen here") rather than as an abstract claim about connections, and "land where you expect" is plainer than "control the expected location" while carrying the same warning about misaligned coordinates.
RISKS: "Land where you expect" is idiomatic and must not be translated literally into a physical landing; the meaning is that the tap arrives at the intended place on the screen. "Watch the TV" means observe the television's picture, not watch a programme, and several languages use different verbs for those two senses.

STRING: enable
KEYS: enable
ENGLISH: "Enable"
VERDICT: APPROVE
REASONING: The confirming button repeats the title's verb, which is the single most useful property a confirmation button can have — the reader does not have to translate between the question and the answer. It is paired with Cancel, so the destructive-versus-proceeding relationship is conventional and immediately readable, and sentence case matches the rest of the set. A more descriptive label such as "Enable direct touch" would be redundant directly under a title that already says it.
RISKS: This is a bare verb with no object and must be rendered as an imperative, not as an infinitive or a noun; in languages that inflect for the object's gender or number, the translator needs to know the object is "direct touch" as rendered in the title, and the two strings should be supplied together.

STRING: holdUnavailable
KEYS: holdUnavailable
ENGLISH: "Press-and-hold is not available through the connected controls."
VERDICT: REWORD
REWRITE: "Press and hold is not available through the controls connected to this TV."
REASONING: The feature's own buttons are labelled "Press and hold" and "Release" without hyphens, and this message hyphenates the name into "Press-and-hold", so the message and the control it describes are spelled differently on the same screen — small, but it is the class of mismatch that makes a reader pause to check whether two different things are meant. The second change scopes the limitation to the television in front of them: as written, "the connected controls" is floating and could be read as a permanent property of the app, when in fact it describes what is connected to this particular set right now, and the app is explicitly multi-TV. "Controls" itself stays, because it is established vocabulary here rather than internal mechanism language, and the string correctly declines to name which service is in use, which the reader does not need in order to understand that holding is not on offer.
RISKS: "Press and hold" must be translated identically here and on the button, so the strings should be linked. Avoid a rendering that suggests the function is temporarily down and will return shortly; the meaning is that the currently connected controls have no such capability at all.

STRING: runButtonTitle
KEYS: runButtonTitle
ENGLISH: "Send this TV command?"
VERDICT: APPROVE
REASONING: The title verb matches the confirming button "Send", which gives the dialog the same clean question-to-answer pairing as the direct-touch dialog, and the whole dialog stays internally consistent by saying "command" in both the title and the body. The word "command" is also the more accurate noun for this object than "button": the list is browsed under the umbrella "All buttons", but the individual entries are commands the television itself reports, several of which correspond to no physical button on any handset. Attaching "TV" makes clear the thing is being sent to the television rather than run locally, and the command's own name is displayed alongside, so the title does not need to carry it.
RISKS: "TV command" is a noun stack; in languages that need an explicit relation it should become "command for the TV" rather than "TV-like command". The question form may need to become a statement in locales where interrogative dialog titles read as uncertainty on the app's part.

STRING: runButtonBody
KEYS: runButtonBody
ENGLISH: "This TV reports this command as potentially disruptive. It may stop playback or change TV settings."
VERDICT: APPROVE
REASONING: The first sentence attributes the warning to the television rather than to the app, which is both true and useful — it tells the reader that the app is relaying a flag, not making a judgement about their choice, so they are not being second-guessed for tapping something. The second sentence does the thing most warnings fail to do: it names concrete consequences, stopping playback or changing settings, instead of leaving "disruptive" to the imagination. That pairing of attribution plus consequence is exactly what a reader needs in order to decide in one second whether to continue. The repetition of "this" in the first sentence is slightly heavy but each instance is doing work, distinguishing this television from others configured in the app and this command from the rest of the list.
RISKS: "Reports" means announces or flags, not files a complaint. "Playback" needs the locale's television and streaming term rather than a generic word for reproduction. Keep the two sentences separate; merging them into one long clause loses the attribution-then-consequence rhythm that makes the warning quick to read.

STRING: tvClipboard
KEYS: tvClipboard
ENGLISH: "Copy to TV clipboard"
VERDICT: APPROVE
REASONING: This is a verb-first label naming a destination the reader can picture, and "clipboard" is universal consumer vocabulary rather than protocol language. Dropping the article is the normal convention for a control label and keeps it scannable. It also sets up the two-step relationship with the separate paste control cleanly: copy puts the text somewhere, and a second, explicitly separate action does something with it — which is precisely the distinction the admitted constraint requires the interface to preserve rather than blur.
RISKS: "Clipboard" must use the locale's established computing term, which in several languages is a fixed platform word rather than the office-supply object. The direction of the preposition matters: the text travels from the phone to the television, and a translator working blind could reverse it.

STRING: tvClipboardBody
KEYS: tvClipboardBody
ENGLISH: "This puts text on the TV clipboard. It does not insert it into a text field."
VERDICT: REWORD
REWRITE: "This puts your text on the TV clipboard. It does not paste the text into a text field on the TV."
REASONING: The second sentence runs two pronouns with different referents into six words — the leading "It" means this action, and the trailing "it" means the text — and a reader moving quickly will tangle them, which is unfortunate in the one sentence whose whole job is to prevent a misunderstanding. Naming the text explicitly removes the collision. The verb also matters: "insert" is a neutral word, while the mistaken expectation this sentence exists to correct is specifically that copying will paste, so using "paste" names the thing that will not happen in the reader's own vocabulary and connects to the separate paste control sitting nearby. Adding "on the TV" pins down where the field is, since the reader is looking at a text area on their phone at that moment and could otherwise read the sentence as being about the phone. The label's noun, "TV clipboard", is repeated exactly rather than shifted to a possessive form.
RISKS: "Paste" must be the locale's standard editing term so that it visibly contrasts with "copy" in the label above. "Text field" should use the platform's own term for an input box; a literal rendering meaning "field of text" is wrong.

STRING: commandTimeout
KEYS: commandTimeout
ENGLISH: "The TV did not confirm this action before the time limit. Check the TV before trying again."
VERDICT: REWORD
REWRITE: "The TV did not confirm this action in time. Check the TV before trying again."
REASONING: "The time limit" introduces a definite article for something the reader has never seen, which invites them to go looking for a timeout setting that they cannot adjust and that is none of their business; "in time" says the same thing without implying a configurable object exists. The rest of the message is doing careful and correct work that is worth preserving exactly: it says the television did not confirm, rather than claiming the action failed, which is the honest description of a deadline expiring, and it tells the reader to look at the television before repeating the command — the right advice, because the action may well have taken effect and repeating it blindly could double it.
RISKS: "In time" means before the deadline elapsed, not "eventually" or "on schedule". Preserve the distinction between not confirming and not working: a translation that says the action failed asserts something the app does not know.

STRING: shortcutFailed
KEYS: shortcutFailed
ENGLISH: "The shortcut stopped because a step could not be confirmed."
VERDICT: REWORD
REWRITE: "The shortcut stopped because a step could not be confirmed. Earlier steps may have already run. Check the TV."
REASONING: The existing sentence is accurate and its passive voice is deliberately doing the right thing — it avoids blaming the television for something the app cannot attribute — so the rewrite keeps it untouched. What is missing is the consequence the reader is actually standing in: a sequence that halts partway has already executed everything before the failing step, so the television may be woken, switched to a different input, and sitting on a half-set-up state. Without that sentence the reader is told an automation stopped and left to discover the intermediate state themselves, possibly by running the shortcut again from the beginning on a television that is already halfway there. Naming it and pointing them at the television turns a bare failure notice into something they can act on, and it matches the recovery guidance the timeout message already gives, so the two error surfaces behave consistently.
RISKS: "Earlier steps" means the steps before the one that stopped, not steps from a previous run; a translator working from the string alone could produce the second meaning. Keep the three sentences short and separate — a single long sentence in a compact error surface will wrap badly and bury the instruction at the end.

STRING: networkMacHelp
KEYS: networkMacHelp
ENGLISH: "Use the TV’s Wi-Fi or Ethernet MAC address, not its Bluetooth address."
VERDICT: APPROVE
REASONING: This prevents a specific, common, and otherwise baffling failure — televisions list several hardware addresses and the Bluetooth one is often the first or most prominent, and a wake-on-network setup that silently never works is close to impossible to debug from the phone side. The string names both acceptable sources and the one wrong source, which is more useful than a general instruction to find the right address. "MAC address" is jargon in the abstract, but it is exactly the label the reader will be staring at on the television's own information screen, so using anything else would make the value harder to locate. The typographic apostrophe matches the house style used elsewhere in the set.
RISKS: "Wi-Fi", "Ethernet", "Bluetooth" and "MAC" are proper names and initialisms that must not be translated or expanded. The contrastive structure — use this, not that — must survive; flattening it into a single positive instruction removes the entire value of the sentence.

STRING: screenPointer
KEYS: screenPointer
ENGLISH: "Screen pointer"
VERDICT: REWORD
REWRITE: "Touch and pointer control"
REASONING: A reader reaches this row for one reason: their taps are not doing anything and they want to know whether the app thinks pointing is possible at all. "Screen pointer" is a thing rather than a capability, and it does not obviously connect to either of the two features it governs — Touchpad and Direct touch — so someone scanning the capability list for an answer about touch may pass straight over it. Naming both halves, touch and pointer, makes the row findable from either feature and describes an ability rather than an object. The brief states that capability labels are human descriptions, so a short descriptive phrase is exactly what belongs here, and the words used are ones the app already trades in rather than invented ones.
RISKS: "Pointer" is the on-screen cursor sense, not a pointing device and not a memory pointer; the false-friend risk is real in technical registers. The two nouns are coordinated under one verb-like head, so languages that need to repeat the head noun should do so rather than produce a compound that means a pointer made of touch.

STRING: sonyIrcc
KEYS: sonyIrcc
ENGLISH: "Sony remote buttons"
VERDICT: APPROVE
REASONING: This is a genuinely human description of a capability whose real name is an unpronounceable protocol initialism, and it tells the reader what they get — the buttons from the Sony handset — rather than how it is delivered. The "Sony" qualifier earns its place because the capability list is flat and spans several services, so without it the row would be indistinguishable from key sending over the other remote service. It also matches the vocabulary the reader has already met on the buttons page, where "Sony controls" is a filter and "buttons" is what the page is full of, so the row lands inside an established naming family rather than beside it.
RISKS: "Sony" is a brand name and must never be translated or declined in a way that obscures it. "Remote buttons" means the buttons of a remote control handset; a rendering meaning "distant buttons" or "buttons that are far away" is a live hazard in several languages.

STRING: appCatalog
KEYS: appCatalog
ENGLISH: "App list"
VERDICT: APPROVE
REASONING: The internal name for this capability is a catalogue, and the copy sensibly declines to use that word, which carries a retail or library connotation nobody needs here. "App list" describes precisely what the capability provides — the ability to see what is installed on the television — in two short words that fit a diagnostics row. It also sits consistently with the product noun "Apps", so a reader who has used the Apps surface will connect the two without effort.
RISKS: "App" should use the locale's ordinary consumer abbreviation for an application rather than a formal or computing-science term. In languages that mark plurality on the modifier, the list contains many apps even though the English modifier is singular.

STRING: nativeText
KEYS: nativeText
ENGLISH: "Native text input"
VERDICT: REWORD
REWRITE: "Text entry on the TV"
REASONING: "Native" is engineering vocabulary that means nothing to this reader in this position — it distinguishes an implementation route, not an outcome, and a reader diagnosing why pasted text never reaches the television's search box gains nothing from knowing which route is native. There is also a mild false-friend hazard, since "native" in everyday English is about origin or language rather than software layering. Describing the capability by what it delivers, entering text on the television, connects the row directly to the Keyboard feature the reader was trying to use when it failed, and the brief explicitly licenses human descriptions for these labels. The phrase stays short enough for a diagnostics row with a status value beside it.
RISKS: "Text entry" means typing or sending text into a field, not a text entry in a list or a log. In locales where "input" and "entry" collapse into one word, prefer the platform's own term for typing into a field.

STRING: wakeOnLan
KEYS: wakeOnLan
ENGLISH: "Wake-on-LAN"
VERDICT: APPROVE
REASONING: This is the proper name of a specific networking feature, and critically it is the name the reader will meet on the television's own settings screen, where they have to switch it on before any of this works — Sony and Android televisions expose it under this name or an obvious relative of it. Replacing it with a friendlier description such as "Turn on over the network" would sever that link and leave the reader unable to find the setting they need to enable. It sits alongside the MAC address help text, which is the other half of the same setup task, so the two reinforce each other. At the action level the app already offers a plain-language alternative, "Wake TV" in Shortcuts, so naming the mechanism here does not force the jargon on anyone who does not want it.
RISKS: This is a proper name and must be kept in English, including its hyphenation and the capitalisation of LAN; translating it would break the match with the television's own settings menu, which is the entire reason it is written this way.

STRING: powerState
KEYS: powerState
ENGLISH: "Power status"
VERDICT: APPROVE
REASONING: "Status" is the consumer-facing word where "state" is the engineering one, and the string correctly chose the former even though the underlying key did not. It sits in a diagnostics group alongside input, volume and current app, so the parallel construction is obvious and the row needs no further qualification — the only power in question is the television's. Two words is the right length for a label whose value carries the information.
RISKS: "Power" here means electrical on-or-off state, not strength, capability or authority — a genuine ambiguity in several languages where the same noun covers all of those. Use the locale's standard term from television and appliance interfaces.

STRING: sonyPin
KEYS: sonyPin
ENGLISH: "Sony registration PIN"
VERDICT: APPROVE
REASONING: The field label names the brand, the process and the kind of value, which is precisely what a reader needs when a four-digit number has just appeared on their television and they are looking for where to put it. It is consistent with the button that starts the flow, "Register Sony controls", and with the instruction that accompanies it, so the three strings form a coherent sequence using one root word, "register", throughout. "PIN" is universally understood consumer vocabulary for exactly this kind of short numeric code.
RISKS: "PIN" is an established loanword in many locales and should usually be left as is rather than expanded into a phrase meaning "personal identification number", which sounds like banking. "Registration" must keep its pairing-and-authorising sense rather than becoming enrolment or subscription, either of which would suggest an account is being created.

STRING: registerSony
KEYS: registerSony
ENGLISH: "Register Sony controls"
VERDICT: APPROVE
REASONING: The brief states that this flow must be explicitly initiated by the user rather than triggered as a side effect, and a verb-first button label that names both the action and its object is the correct expression of that: nothing here is ambiguous about the fact that pressing it starts something. It uses "Sony controls", which is the app's established name for that service in the diagnostics list and in the buttons filter, so the same phrase means the same thing in all three places. The verb also matches the PIN dialog's confirming action, keeping one word for one concept across the whole flow.
RISKS: "Register" must mean pairing this app with the television, not signing up for an account or a service — the wrong sense here would be alarming. "Sony" stays untranslated, and in languages that inflect the object the phrase should stay recognisably the same as the diagnostics service name.

STRING: sonyPinWaiting
KEYS: sonyPinWaiting
ENGLISH: "Enter the PIN shown on your TV."
VERDICT: REWORD
REWRITE: "Enter the PIN shown on this TV."
REASONING: This is the only string in the set that addresses the reader in the second person possessive; everywhere else the app says "the TV" or "this TV", so "your TV" is a small register wobble inside an otherwise consistent voice. It also carries a real ambiguity in an app whose entire structure is per-television: someone who has three sets configured and is registering the one in the bedroom is told to look at "your TV", which names none of them, whereas "this TV" points at the one whose settings page they are currently inside and matches the phrasing already used by the direct-touch checkbox and the droidVNC-NG note. The instruction itself is otherwise good — it is short, it says where to look, and it is the whole of what the reader needs at that moment.
RISKS: "This TV" must be the demonstrative referring to the television currently being configured in the app, not a deictic meaning the physical object nearest the speaker; languages with proximal and distal demonstratives should choose the one used for the item under discussion. "PIN" should be handled as in the field label so the two strings agree.

STRING: removeSavedSecret
KEYS: removeSavedSecret
ENGLISH: "Remove saved credential"
VERDICT: APPROVE
REASONING: The control has to cover two different stored values, a VNC password and a Sony pre-shared key, so it needs an umbrella noun, and "credential" is the least technical umbrella available that is still accurate — "password" would be wrong for the key and "secret" would be worse, since it is the internal word and reads oddly in consumer copy. It also pairs with the reassurance line about saved credentials staying on the phone, so the same noun covers storage and deletion, letting the reader connect the two statements. Verb-first phrasing makes the consequence plain, and the label does not overpromise by saying "forget" or "clear", which are vaguer about whether the value is gone.
RISKS: "Credential" must use the locale's security and sign-in vocabulary rather than a word meaning qualification, reference or diploma, which is a real hazard across Romance languages. Singular here refers to the stored value for the television in view, while the reassurance string uses the plural for all of them; translators should not harmonise the two into one number.

STRING: anyButtons
KEYS: anyButtons
ENGLISH: "Every button"
VERDICT: REWORD
REWRITE: "All buttons"
REASONING: The page is titled "All buttons" and the unfiltered chip directly beneath it says "Every button", so the same screen offers two different quantifiers for the same scope within a few millimetres of each other. A reader will either not notice, in which case the variation bought nothing, or will notice and wonder what distinction is being drawn between all and every — the worse outcome, since none is intended. Matching the page title exactly makes the chip unmistakably the no-filter option, and the chip row then reads as one unfiltered option beside two source-named ones, which is a conventional and instantly legible filter pattern. Keeping the noun rather than reducing to a bare "All" also protects the label in translation, where a standalone quantifier often needs its noun to inflect correctly.
RISKS: This label and the page title must be translated identically; if they diverge, the inconsistency the rewrite removes simply reappears in every other locale. The quantifier must agree in gender and number with the locale's word for buttons.

STRING: localNetwork
KEYS: localNetwork
ENGLISH: "Local network"
VERDICT: APPROVE
REASONING: This heads the diagnostics group covering whether the television can be reached at all, and "local network" is the ordinary consumer phrase for the home network that both devices sit on — it is what router interfaces, phone settings and support articles all call it, so the reader arrives already knowing what it means. It correctly avoids naming a protocol or a layer, and it sets the right expectation for the whole app, which the brief describes as operating over a private network rather than through any cloud service.
RISKS: Use the locale's established phrase for a home or local area network rather than a literal rendering of "local", which in some languages suggests a venue or a locality. It should not be rendered as the initialism LAN if the surrounding copy is plain-language, though LAN remains correct inside the Wake-on-LAN proper name.

STRING: secretsSaved
KEYS: secretsSaved
ENGLISH: "Saved credentials stay on this phone."
VERDICT: APPROVE
REASONING: This appears beside fields where the reader is about to type a password for a device in their own home, and it answers the only question they are actually asking at that moment: does this leave my phone. It is a complete, verifiable, plainly worded claim with no hedging and no marketing, and it aligns with the stated fact that there is no cloud component and no analytics. It deliberately stops short of describing encryption, which is the right call for this surface — a storage-security claim in a one-line reassurance invites a question the line cannot answer, while "stays on this phone" is the fact that actually determines the reader's exposure. The noun matches the removal control directly above or below it, so the two strings describe one thing.
RISKS: "Stay on this phone" means they are never transmitted, not merely that they remain present; a rendering meaning "remain stored" loses the point. "This phone" should contrast with anywhere else, especially any cloud or server, so the demonstrative needs to be emphatic enough to carry that contrast.

STRING: vncInput
KEYS: vncInput
ENGLISH: "VNC keyboard shortcuts"
VERDICT: REWORD
REWRITE: "Key input over VNC"
REASONING: In ordinary software usage "keyboard shortcuts" means combinations the user presses on their own keyboard, so a diagnostics row with that name reads as a list of shortcuts available to the reader rather than as a capability of the connection — and since this row carries a tested-or-not status, that misreading produces genuine confusion about what has or has not been proven. The underlying capability is whether key events reach the television through the screen connection at all, which covers both the mapped button shortcuts described in the droidVNC-NG note and ordinary typed characters, so a label restricted to shortcuts would also under-describe it. "Key input over VNC" names the capability, names the route using the proper name that is already established in this app, and cannot be misread as a list of things to press. It is slightly technical, but this is a diagnostics surface that already carries MAC addresses and software versions.
RISKS: "VNC" is a proper name and stays in English. "Key input" means keystrokes being delivered, not a cryptographic key and not an important input — both are live false friends and the distinction should be stated for translators. "Over" here means via or through, not above.

STRING: droidConfirmed
KEYS: droidConfirmed
ENGLISH: "This server is droidVNC-NG"
VERDICT: REWORD
REWRITE: "This TV runs droidVNC-NG"
REASONING: The reader's unit of thought throughout this app is the television, not a server — every other string in Settings is about a TV, its address, its credentials and its direct-touch state — so introducing "this server" as the subject makes them briefly resolve which server is meant and where it lives. It runs on the television, so saying so directly is both simpler and more precise about what they are asserting. This matters because the reader is ticking a box to declare a fact from their own knowledge, and the fact is "I installed that app on that television"; phrased as "This TV runs droidVNC-NG" the assertion matches the memory they are drawing on. It also aligns with the shortcut note beside it, which already frames its condition in terms of the television rather than a server.
RISKS: "droidVNC-NG" is a product name with a specific mixed-case spelling and must be reproduced exactly, never translated, transliterated or case-normalised. "Runs" here means hosts or has installed and running, not operates in the sense of managing.

STRING: droidShortcuts
KEYS: droidShortcuts
ENGLISH: "Use droidVNC-NG’s default Home, Back and volume shortcuts only if this TV has not customized them."
VERDICT: REWORD
REWRITE: "Home, Back and volume use droidVNC-NG’s default shortcuts. If those were changed in droidVNC-NG, these buttons may not work as expected."
REASONING: The original makes the television the agent that customises the shortcuts, which is a category error — a television does not configure anything; a person changed a setting inside the droidVNC-NG app, which is the admitted upstream fact. That misattribution hides the only action the reader can take, which is to open droidVNC-NG on the television and look at its shortcut settings, and it leaves them with a conditional they cannot evaluate. The rewrite states what the app will do, then states the consequence if the assumption is false and where the change would have been made, so the reader can verify it. It also softens the consequence to "may not work as expected" rather than asserting outright failure, because a remapped shortcut does not stop working, it does something else — which is the more confusing outcome and worth describing accurately.
RISKS: "Home" and "Back" are the names of television navigation buttons and should be rendered exactly as the platform names them in that locale, not translated as ordinary words. "Default" means the factory setting of the droidVNC-NG app; "changed" must be read as changed by a person in that app's own settings, not changed by this app.

STRING: confirmInput
KEYS: confirmInput
ENGLISH: "Direct touch checked on this TV"
VERDICT: REWORD
REWRITE: "Direct touch verified on this TV"
REASONING: The word "checked" collides with the widget it sits on: on a checkbox, "checked" is the name of the control's own state, so the label can be parsed as describing the tick mark rather than as describing a verification the person performed. Since the entire purpose of this control is for the reader to record that they watched the television and confirmed their taps landed correctly, that particular ambiguity undermines the one job the label has. "Verified" cannot be confused with the checkbox state, keeps the same shape and length, and preserves the crucial property that this is the reader's own assertion rather than a claim by the app — it describes what they did, and only they can tick it. The per-television scoping is correct and is retained unchanged.
RISKS: "Verified" must be rendered as something the user did, not as a certification the app or a third party issued; a passive form implying official validation would make a false claim. Keep the past-tense sense of a completed check, not an ongoing one.

STRING: sendClipboardPaste
KEYS: sendClipboardPaste
ENGLISH: "Paste from TV clipboard"
VERDICT: REWORD
REWRITE: "Paste on the TV"
REASONING: As written, the direction reads backwards. "Paste from TV clipboard" most naturally means pulling the television's clipboard contents into whatever the reader is looking at on their phone, whereas the control — placed beside a copy action, described as a separate second step, and named in the interface spec as sending a paste — tells the television to paste what it already holds. A reader who takes the label at face value will tap it expecting text to appear in their phone's text area, and nothing will. Renaming it "Paste on the TV" puts the action where it happens and turns the two controls into a legible sequence: first copy the text to the television's clipboard, then tell the television to paste it. That sequencing is exactly what the admitted constraint requires the interface to make explicit rather than imply, since insertion does not follow automatically from copying.
RISKS: "On the TV" indicates where the paste happens, not a surface something rests on. The verb must be the locale's standard editing term so it visibly pairs with the copy label, and translators must be told the direction: the phone is instructing the television, not retrieving from it.

STRING: selectStep
KEYS: selectStep
ENGLISH: "Choose an action"
VERDICT: APPROVE
REASONING: The shortcut builder uses "Steps" and "Add step" for the container and "action" for what goes inside one, and that is a conventional, well-understood relationship rather than a vocabulary conflict — you add a step, then you say what it does. The list this title introduces is full of verbs, Wake TV, Go Home, Select input, Launch app, Wait for TV ready, so "action" describes its contents accurately, whereas a title saying "Choose a step" would sit oddly above a list of things to do. "Choose" is also the friendlier and more common verb than the underlying "select", and the copy correctly preferred it.
RISKS: "Action" should be the everyday word for something done, not a legal or dramatic sense. The indefinite article carries a one-of-many meaning that some languages express differently; the title must not imply that only one action may ever be chosen for the whole shortcut.

STRING: screenHidden
KEYS: screenHidden
ENGLISH: "Screen hidden. Remote controls remain available."
VERDICT: APPROVE
REASONING: This does the two things a state-change confirmation should do: it states what just happened and it pre-empts the fear the change creates, which here is that hiding the picture has disconnected everything. The first half uses the product's own noun for the television picture, matching the Hide screen and Show screen controls exactly, and the second half uses "controls", which is the vocabulary this app consistently uses for the things it sends. "Remain available" is slightly formal in isolation, but it sits inside a set that is uniformly plain-but-composed — "Turn the TV on before sending other controls", "Connect to this TV to send controls" — so it matches the established register rather than departing from it, and changing it here alone would introduce the inconsistency it was meant to remove.
RISKS: "Screen hidden" is a completed state, not an instruction to hide; languages that distinguish participles from imperatives need the state reading. "Remain available" means continue to work, not merely continue to be displayed on screen.

STRING: privateDraft
KEYS: privateDraft
ENGLISH: "Private text is cleared when you leave this screen or switch TVs."
VERDICT: REWORD
REWRITE: "Private text is cleared when you leave the Keyboard or switch TVs."
REASONING: "Screen" is a claimed product noun in this app, meaning the television's picture as shown on the phone, and the Keyboard page itself displays a small television preview with Hide screen and Show screen behaviour nearby — so telling the reader that their text is cleared "when you leave this screen" collides directly with a term that means something else a few pixels away. A reader can plausibly conclude their private text is wiped whenever they hide the preview, which is a different and more alarming rule than the one actually in force. Naming the page, the Keyboard, removes the collision and is also more concrete: it tells them the exact boundary that triggers the clearing. The rest of the sentence is good and is kept verbatim, including the second condition, since switching televisions is a non-obvious trigger worth stating.
RISKS: "Keyboard" here is the name of a page in this app, not the on-screen keyboard of the phone and not a physical one; it must be translated identically to that page's own title, and the two strings should be supplied together. "Private text" is likewise a named mode and must match its control label exactly.

STRING: powerOffFirst
KEYS: powerOffFirst
ENGLISH: "Turn the TV on before sending other controls."
VERDICT: APPROVE
REASONING: This is the rare message that both explains and instructs in one short sentence, and its verb matches the control the reader must use — the Remote's power control is labelled "Turn on", so "Turn the TV on" leads them straight to it. It explains the ordering constraint without any mechanism talk: a set that is off cannot act on anything else, so power comes first. "Other controls" is unambiguous in position, since the only control excluded is the power one they are being told to use. It also avoids scolding; it reads as a sequence, not as an error the reader committed.
RISKS: The separable phrasal verb "turn ... on" must be rendered with the locale's normal power-on verb for appliances. "Other controls" means the remaining control functions, not other remote handsets and not different settings.

STRING: standbyIntent
KEYS: standbyIntent
ENGLISH: "Automatic reconnection is paused after turning the TV off."
VERDICT: REWORD
REWRITE: "The app will not reconnect on its own while the TV is off."
REASONING: "Automatic reconnection" is a mechanism noun the reader has never been introduced to — the interface offers a Reconnect button and a connection progress area, not a named automatic-reconnection feature — so the sentence opens by naming a system the reader does not know they have. The participle "after turning the TV off" is also left dangling, with no stated subject, so strictly it reads as though the reconnection turned the television off. More importantly, "is paused" raises the question of when it resumes and then declines to answer it, leaving the reader unsure whether waiting will fix things. The rewrite states the behaviour in terms the reader already holds, names the app as the actor, ties the behaviour to a condition they can observe and change (the television being off), and deliberately makes no promise about the resume rule, which the supplied material does not establish.
RISKS: "On its own" means without the user asking, not independently in a technical sense. "While the TV is off" is a condition that persists, not a single moment, and should not be rendered as "once the TV has been turned off" if that implies a permanent stop.

STRING: notConnected
KEYS: notConnected
ENGLISH: "Connect to this TV to send controls."
VERDICT: REWORD
REWRITE: "Not connected to this TV. Reconnect to send controls."
REASONING: Two problems, one of naming and one of order. The instruction tells the reader to "Connect", and the app's actual control for establishing the link is labelled "Reconnect" in the Remote's preview area — so the message uses a word that does not appear on any button, sending the reader to look for something they will not find under that name. Second, the message leads with a fix and never states the condition, so a reader who tapped a button and saw nothing happen is told what to do without being told why their tap did nothing; stating the state first explains the silence, and the instruction then lands as a remedy rather than as a non-sequitur. The rewrite keeps the whole thing to two short clauses so it still fits a compact empty or disabled state.
RISKS: "Reconnect" must be translated identically to the button of the same name, and the two strings should be linked, since the entire value of the rewrite is that the word in the sentence matches the word on the control. "Not connected" is a state, not an instruction not to connect.

BRIEF DEFECT: The supplied screen inventory names the Remote's voice control "Hold to speak", while the string micPermission instructs the reader to "Hold Voice again"; the brief does not say which is the real label, so the rewrite was resolved toward the inventory's label. If the control actually reads "Voice", the micPermission rewrite must be re-pointed at that word and re-reviewed.
BRIEF DEFECT: The brief does not state whether tvResponding is an in-flight wait or a completed handshake milestone. The trailing ellipsis was taken as authoritative and the rewrite preserves an in-progress reading; if the state actually marks a received response, the string should be a completed milestone without an ellipsis and needs a fresh review.
BRIEF DEFECT: The direction of sendClipboardPaste is not stated. It was inferred from the key name and from the inventory's description of it as a separate step following "Copy to TV clipboard"; if the control instead retrieves the television's clipboard into the phone's text area, the rewrite is wrong and the string must be re-reviewed.
BRIEF DEFECT: The brief does not say which surfaces display notConnected, so it is unverified that a control named "Reconnect" is reachable from all of them. The rewrite names that control; wherever the message can appear, a Reconnect affordance must be present, or the second sentence must point to where it is.

COPY REVIEW COMPLETE: 44 strings (20 approved, 24 reworded)
