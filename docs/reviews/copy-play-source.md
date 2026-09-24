REVIEW-ID: 61de0393-23e3-457c-899c-00409f19c31c
DATE: 2026-09-24
REVIEWER: content-strategist (Claude, cross-model)
ARTIFACT: /Users/amsh/worktrees/tvVNC/worktree/docs/reviews/copy-play-source.md
DESCRIPTOR: none — derived from reviewed listing, GPL section 6(d) and IJG attribution requirement

STRING: play.full
KEYS: play.full
ENGLISH: "See what is on your TV and use familiar remote controls from your Android phone or tablet. TV VNC puts a screen viewer, remote buttons and your phone keyboard in one app, making it easier to operate a compatible Android TV or Sony BRAVIA TV, or to help someone with its menus.

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

The TV picture in the store screenshots is an AI-generated illustration shown by the real app; it is not footage from a physical TV.

OPEN SOURCE
TV VNC is licensed under GPL-3.0-or-later. Source code and build instructions: https://github.com/amersheeny/tvvnc.
This software is based in part on the work of the Independent JPEG Group."
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

The TV picture in the store screenshots is an AI-generated illustration shown by the real app; it is not footage from a physical TV.

OPEN SOURCE
TV VNC is licensed under the GNU General Public License, version 3 or later (GPL-3.0-or-later).
Source code and build instructions: https://github.com/amersheeny/tvvnc
This software is based in part on the work of the Independent JPEG Group."
REASONING: Everything above the new OPEN SOURCE section is unchanged from the previously reviewed text and still reads well, so only the new section needed attention. It has two small reader-facing problems. First, "GPL-3.0-or-later" on its own is a licence code that a typical helper choosing a TV remote won't recognise. Writing out "the GNU General Public License, version 3 or later" names the licence in plain words and keeps the code in brackets for readers who search for it. Second, the source address ended with a full stop inside the sentence. Some link detectors include a trailing full stop in the link, which would send readers to a page that doesn't exist. The address is now on its own line with nothing after it, which also makes the source directions easier to spot for anyone looking for them. "Source code and build instructions:" is kept word for word because it points to where the source will be without claiming a release already exists, which matches the verified constraint that source is published before the binary. The Independent JPEG Group sentence is kept exactly as supplied, because its wording is required and must not change. The heading "OPEN SOURCE" is kept as a short label for the section. The words "free software" were not added, because in a store listing "free" can read as a price claim, and price promotion isn't allowed. The rewrite adds about 45 characters to the stated 2,918, leaving it well under the 4,000-character limit.
RISKS: The source address will not have released source tags until the source is published before the binary release. If the listing goes live before then, the source directions would point to a page without the corresponding source. That is a release-ordering risk, not a wording one. Google Play shows the full description as plain text with limited formatting, so the line breaks in the OPEN SOURCE section should be checked in the store preview. If they are merged into one line, the address is still followed by a space and new text rather than a full stop, so the link should stay correct.
COPY REVIEW COMPLETE: 1 strings (0 approved, 1 reworded)
