# Screenshot provenance

These are unmodified captures of the actual TV VNC Android app. The TV preview
within the app displays AI-generated illustrative content; the surrounding
phone interface was not generated or retouched. They were captured on 2026-09-23
from the headed Android 15 controller emulator at 1080 × 2400, using application
checkpoint `163ef6d` and native Android Remote library checkpoint `a17e093`.

The controller was connected only to the development protocol fixtures. The
saved profile name **Demo TV** and the **Search for a film** text are synthetic.
The [illustrative TV screen](tv-screen-illustration.png) was generated with the
built-in image-generation tool using [this prompt](tv-screen-prompt.txt), then
streamed at its native 1672 × 941 resolution by the local RFB fixture. It is a
fictional streaming/search interface, not evidence of a particular TV's UI or
an installed application. No physical TV content was captured.

| Image | Content checked before adding to Git |
| --- | --- |
| [Remote](remote.png) | Demo name, illustrative TV preview and app controls. No real address/MAC, account, password, pairing code or private TV content. |
| [Keyboard](keyboard.png) | Synthetic prefilled text, illustrative TV search screen and the controller keyboard. No real typed content, credentials, pairing code or user clipboard contents. |
| [All buttons](all-buttons.png) | App-provided control names and filters only. No private device or account information. |

The captures illustrate the app UI and actual viewer scaling. The TV picture is
a static illustration: it does not prove text mirroring or remote interaction.
They do not establish physical-TV compatibility, voice support, HDMI/DRM capture
or power/wake success. The temporary demo profile name was restored after the
capture flow. Raw test logs and failure captures are not included in this gallery.
