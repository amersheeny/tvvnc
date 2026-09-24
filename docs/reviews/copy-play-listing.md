REVIEW-ID: 61de0393-23e3-457c-899c-00409f19c31c
DATE: 2026-09-23
REVIEWER: content-strategist (Claude, cross-model)
ARTIFACT: /Users/amsh/worktrees/tvVNC/worktree/docs/reviews/copy-play-listing.md
DESCRIPTOR: none — derived from assets/copy/en.json, README.md, and real store-candidate screenshots

STRING: play.title
KEYS: play.title
ENGLISH: "TV VNC"
VERDICT: APPROVE
REWRITE: (none)
REASONING: This is the product's own name. It is well under the 30-character limit, matches the brief's product nouns, and makes no claim. "VNC" will mean little to a non-technical helper, but the short description and screenshots explain what the app does. The title does not need to.
RISKS: A search for "TV remote" will not match on the title alone. That affects how easily people find the app, not whether the copy is true or clear.

STRING: play.short
KEYS: play.short
ENGLISH: "See and control your Android TV from your phone on a private local network."
VERDICT: REWORD
REWRITE: "See and control a compatible Android TV from your phone on your local network."
REASONING: "Your Android TV" implies any Android TV works as soon as the phone app is installed. In fact the picture needs a screen-sharing server on the TV and the controls need pairing, so "a compatible" sets the right expectation in the line most people read. "On your local network" describes the normal setup and does not promise offsite access. It is not an absolute ban either, so it stays true for a private route to the TV that the user has set up. It also avoids "private … network", which some readers link with a built-in VPN, and the listing says there is none. Length: 78 of 80 characters.
RISKS: Sony BRAVIA is not named in this line; the full description names it. Tablets are not named; the full description names them.

STRING: play.full
KEYS: play.full
ENGLISH: "See what is on your TV and use familiar remote controls from your Android phone or tablet. TV VNC brings a screen viewer, remote buttons and phone-keyboard input together, making it easier to operate your TV or help someone with its menus.

SET UP YOUR TV FIRST
Your phone and TV must be on the same trusted local network. Screen viewing requires a running droidVNC-NG or compatible VNC server on the TV, with screen-sharing permission granted there. Native Android TV controls use separate TV pairing. Sony-specific functions require a supported, configured Sony IP-control service. Installing this phone app alone does not enable those services.

A REMOTE WITH A VIEW
• D-pad, OK, Back, Home, volume, mute and media controls.
• Additional TV-reported buttons, with long presses where supported.
• Remote, Touchpad and Direct touch navigation.
• Resizable live preview, zoom, pan, fullscreen and screenshots.
• Keyboard input, paste and native editor prefill with live editing when the TV shares its focused text field.
• Detected inputs and TV apps, with direct switching and launching where supported.
• Favourite apps, recent launches, custom button order and local Shortcuts.
• Connection status and Diagnostics for troubleshooting.

Capabilities depend on your television, its apps, permissions and available services. Screen sharing and remote controls use independent connections, so an unavailable picture does not necessarily prevent control. Voice streaming and TV wake controls are offered only when supported; their availability varies.

PRIVATE-NETWORK USE
No advertising, analytics or developer cloud relay. There is no built-in VPN in this release. Use TV VNC only with the TV owner's permission. Classic VNC and Sony HTTP traffic are not encrypted; use a trusted private network and never expose TV-control ports to the public internet.

Protected video may appear black, and an HDMI source may not be visible through TV screen capture. TV VNC does not bypass content protection.

Android 8.0 or later is required on the phone or tablet. TV VNC is an independent project, not an official Sony or Google application.

The TV picture in the store screenshots is an AI-generated illustration displayed by the real app; it is not footage from a physical TV."
VERDICT: REWORD
REWRITE: "See what is on your TV and use familiar remote controls from your Android phone or tablet. TV VNC puts a screen viewer, remote buttons and your phone keyboard in one app, making it easier to operate a compatible Android TV or Sony BRAVIA TV, or to help someone with its menus.

SET UP YOUR TV FIRST
Installing TV VNC on your phone is only half of the setup. You also need:
• Your phone and TV on the same trusted local network. More generally, your phone must be able to reach the TV on a trusted private network. TV VNC does not provide a cloud relay or built-in VPN.
• For the TV picture: a screen-sharing app such as droidVNC-NG, or another compatible VNC server, installed and running on the TV, with its screen-capture permission allowed.
• For Android TV remote controls: a separate pairing between TV VNC and the TV.
• For Sony BRAVIA features: the TV's Sony IP control service, supported and set up.

WHAT YOU CAN DO
• D-pad, OK, Back, Home, volume, mute and media controls.
• Extra buttons your TV reports, with long presses where supported, all searchable on the All buttons page.
• Three ways to navigate: Remote, Touchpad and Direct touch.
• A live TV picture you can resize, zoom, pan, view fullscreen and save as a screenshot.
• Keyboard: type with your phone keyboard and paste text. When the TV shares the text box you are in, its text appears on your phone and your edits show on the TV as you type.
• Inputs and Apps: see your TV's inputs and apps, and switch inputs or open apps where supported.
• Favourite apps, recent launches, your own button order and Shortcuts saved on your phone.
• Connection status and Diagnostics to help with troubleshooting.

What works depends on your TV, its apps, permissions and services. The TV picture and the remote controls use separate connections, so the remote buttons may still work when the picture is unavailable. Voice input and waking the TV from standby are not available on every TV.

PRIVACY AND SECURITY
You don't need a TV VNC account, and TV VNC has no advertising or analytics. Your phone connects to your TV without going through a TV VNC server. Use TV VNC only with the TV owner's permission. Standard VNC screen sharing and Sony IP control are not encrypted, so use them only on a network you trust and never expose TV-control ports to the internet.

Protected video may appear black, and an HDMI source may not be visible in the TV picture. TV VNC does not bypass content protection.

Requires Android 8.0 or later on your phone or tablet. TV VNC is an independent app, not an official Sony or Google app.

The TV picture in the store screenshots is an AI-generated illustration shown by the real app; it is not footage from a physical TV."
REASONING:
(1) The original never names Sony BRAVIA, although the app supports it. It is now named in the opening sentence.
(2) The setup requirements were one dense paragraph. They are now a list, one item per thing the user must provide, and it opens with "only half of the setup". That is the fact a relative setting this up most needs, and the store would otherwise leave them to discover it after installing.
(3) The network item follows the verified correction. The same local network is the normal case, and the wider requirement is phrased as reaching the TV on a trusted private network. There is no absolute claim that the internet can never be involved, because an existing private route set up by the user can reach the TV. It also does not promise built-in offsite access, since there is no cloud relay and no built-in VPN.
(4) Jargon is replaced with plain descriptions of the same facts: "native editor prefill with live editing when the TV shares its focused text field", "Native Android TV controls", "TV-reported", "Classic VNC" and "Sony HTTP traffic".
(5) The app's own nouns are used exactly: Remote, Touchpad, Direct touch, Keyboard, All buttons, Inputs, Apps, Shortcuts, Diagnostics. All buttons appears in a store screenshot but was missing from the original text.
(6) The double negative "an unavailable picture does not necessarily prevent control" is now a positive statement.
(7) "Offered only when supported" claimed that the app reliably detects voice and wake support, which has not been tested on hardware. It is replaced by a plain limit that promises nothing universal.
(8) "No account" is now "You don't need a TV VNC account". Third-party TV apps may still need their own accounts, so the claim is limited to TV VNC.
(9) "No developer cloud relay" is now "without going through a TV VNC server", which avoids the jargon word "relay". The built-in VPN statement now appears once, in the setup list, instead of twice.
(10) The pun heading "A REMOTE WITH A VIEW" becomes "WHAT YOU CAN DO". "PRIVATE-NETWORK USE" becomes "PRIVACY AND SECURITY", because that section covers data collection and encryption as well as the network.
(11) Kept: every implemented feature and its conditions, the owner-permission line, the encryption warning, the content-protection limit, the Android version, the independent-app disclaimer and the AI-illustration disclosure.
Length is about 2,600 characters, under the 4,000 limit.
RISKS: "Shortcuts saved on your phone" reads the brief's "local Shortcuts" as stored on the device. If "local" meant something else, go back to "local Shortcuts". "Your edits show on the TV as you type" relies on the brief's "live editing". The keyboard screenshot also shows a Send button and says "Enter sends your text", so if live editing only applies in some modes, add "where supported" after "as you type".

STRING: play.screenshot.remote.alt
KEYS: play.screenshot.remote.alt
ENGLISH: "TV VNC remote controls with an illustrative TV search screen, D-pad, volume, Back and Home."
VERDICT: REWORD
REWRITE: "TV VNC Remote with an illustrative TV film-search screen, D-pad, OK, volume, mute, Back and Home buttons."
REASONING: The screenshot shows an OK button in the centre of the D-pad and a separate mute button. A person using a screen reader should hear the same main controls a sighted person sees. "Remote" is the app's own noun, so it replaces the generic "remote controls". "Film-search" matches the "Search for a film" text visible in the illustration. "Illustrative" makes clear that the TV scene does not prove a real TV was being mirrored.
RISKS: Options, Input, Guide, Info and the keyboard and microphone buttons are left out to keep the text short. The microphone is left out on purpose, so the alt text does not suggest a voice promise.

STRING: play.screenshot.keyboard.alt
KEYS: play.screenshot.keyboard.alt
ENGLISH: "TV VNC keyboard with prefilled example text, a TV preview and the phone keyboard."
VERDICT: REWORD
REWRITE: "TV VNC Keyboard with prefilled demo text, Paste, Send and Clear buttons, an illustrative TV preview and the phone keyboard."
REASONING: This takes the proposed wording after judging it on its merits. The verified provenance shows that "Search for a film" is example content supplied by the test setup. "Prefilled demo text" is therefore accurate, and unlike the previous suggestion it does not imply the text was read from a real TV app. "Illustrative TV preview" keeps the static generated picture from reading as proof of mirroring. Naming Paste, Send and Clear describes the controls that are labelled on screen. The capitalised "Keyboard" (the app's page name) against the lowercase "phone keyboard" (Android's on-screen keyboard) is enough to tell the two apart.
RISKS: Some readers may wonder what "demo" means in a store listing. The full description's AI-illustration disclosure gives that context.

STRING: play.screenshot.buttons.alt
KEYS: play.screenshot.buttons.alt
ENGLISH: "All buttons page with search, transport filters and available navigation commands."
VERDICT: REWORD
REWRITE: "TV VNC All buttons page with search, filters for Sony controls and Android TV Remote, and buttons such as Up, Down, OK, Home and Back."
REASONING: The filter chips on screen are "All buttons", "Sony controls" and "Android TV Remote", so they filter by where each button comes from. To TV users, "transport" means playback keys such as play and pause, and none are shown, so the old wording misdescribes the screen. "Navigation commands" is abstract, so the rewrite names the visible buttons. It now starts with "TV VNC" like the other two alt texts.
RISKS: None found.

BRIEF DEFECT: play.full claims "Voice streaming and TV wake controls are offered only when supported". This says the app reliably detects support, but the brief says hardware acceptance for voice and standby wake is still pending. The rewrite removes the claim.
BRIEF DEFECT: play.screenshot.buttons.alt says "transport filters". The All buttons screenshot at /Users/amsh/worktrees/tvVNC/worktree/docs/images/all-buttons.png contradicts this: its filters are by source, not by playback function. The rewrite corrects it.
BRIEF DEFECT WITHDRAWN: The earlier defect saying "prefilled example text" misdescribed the keyboard screenshot is withdrawn. The verified provenance shows the text is synthetic example content from the test setup, so calling it example or demo text is accurate.

COPY REVIEW COMPLETE: 6 strings (1 approved, 5 reworded)
