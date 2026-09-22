# Local protocol fixtures

`tv_fixture.mjs` is an independently encoded test TV, not an actual Sony or a
replacement for physical-TV acceptance. It uses Node's built-in modules and
OpenSSL. It binds only to host loopback: Android Remote TLS on 6466, pairing on
6467, and a synthetic Sony HTTP API on 18080. The app's real Sony transport uses
port 80; this HTTP fixture alone does not validate that path.

Run `node test/native/tv_fixture.mjs` in an interactive terminal. It prints a
synthetic six-character pairing code when a client begins pairing. No real TV
credentials are used. The TLS certificate and its private key live in an
owner-only temporary directory and are removed on normal termination.

Point the controller emulator at `10.0.2.2`, with Remote ports 6466/6467. A
separate RFB fixture can supply the screen on 15900; its password is
`viewer-test`. The picture is a color pattern, not a rendering of the editor.
Observe native edit/action logs separately from screenshots of the phone UI.

Examples accepted as JSON lines on stdin:

```json
{"text":"Example search","type":1,"options":3}
{"text":"Synthetic password","type":129,"options":6}
{"text":"1234","type":18,"options":6}
{"text":"Line one\nLine two","type":131073,"options":1073741825}
{"features":613}
{"target":"headphone","minimum":10,"maximum":30,"volume":15}
```

The normal feature mask is 615; 613 removes key events while retaining volume.
The password and PIN examples are synthetic and must not contain real secrets.
Logs record edit lengths, selection offsets and action numbers, not text.
Type `quit` to close the fixture and remove its generated key material.

The `editor_fixture_*.yaml` flows use a profile named `Editor protocol fixture`.
They never clear app data. Setup is a one-time flow. Pairing and edit flows are
separate so the displayed code can be supplied through `PAIRING_CODE`.
