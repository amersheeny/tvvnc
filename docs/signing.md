# Android release signing

Release signing is separate from TV pairing credentials. The debug build keeps
its existing signing configuration. A release never falls back to that key.

## Upload key configuration

Supply these environment variables to the build process from a secret manager:

| Variable | Value |
| --- | --- |
| `TVVNC_UPLOAD_KEYSTORE` | Absolute path to the private upload keystore. |
| `TVVNC_UPLOAD_STORE_PASSWORD` | Keystore password. |
| `TVVNC_UPLOAD_KEY_ALIAS` | Key alias; defaults to `upload`. |
| `TVVNC_UPLOAD_KEY_PASSWORD` | Key password; defaults to the store password. |

Do not put passwords in command-line arguments, logs, tracked files or public
build output. Keep the keystore outside the checkout, restrict access to its
owner, and keep a recoverable backup under the developer's control. The local
macOS release setup keeps the password in Keychain. A new PKCS12 keystore must
use the same password for its store and key; separate passwords are not supported
by `keytool` for that format.

With the variables supplied, run from the configured maintainer checkout:

```sh
flutter build appbundle --release
flutter build apk --release
```

The outputs are `build/app/outputs/bundle/release/app-release.aab` and
`build/app/outputs/flutter-apk/app-release.apk`. Record the source revision,
dependency revisions, artifact hashes and signing-certificate fingerprint.

When `TVVNC_UPLOAD_KEYSTORE` is absent, no release signing configuration is
selected. Direct Gradle builds can produce unsigned artifacts; Flutter's APK
command may report that its expected signed output is missing. An unsigned
bundle or APK is not ready for upload or installation. Partial or incorrect
credentials are checked by the Android Gradle plugin's signing validation.
Move old output files aside before testing this case so they cannot be mistaken
for newly built artifacts.

## Validate the exact release artifacts

- Verify the bundle with `jarsigner -verify -verbose -certs` and compare its
  certificate fingerprint with the intended upload certificate.
- Verify the APK with Android SDK `apksigner verify --verbose --print-certs`;
  do not accept an Android Debug certificate as the release signer.
- Inspect native ELF segment alignment for every bundled ABI and check APK ZIP
  alignment with `zipalign -c -P 16 -v 4` from the Android SDK build tools.
- Run the minified [protocol probe](../test/native/release_protocol_probe.sh)
  against the freshly built, hash-recorded signed APK. It loads code through
  Android ART without replacing the installed app or accessing its saved TVs.
- Test the Play-generated APKs as well: an upload-signed local APK is not the
  final artifact Google distributes.

## Play App Signing and existing installations

The upload key authenticates uploads to Google Play. Play App Signing can use a
different key for APKs delivered to users. Choosing and enrolling that key is a
separate Console step; this configuration does not enroll the app or accept
Google's terms.

The development app already installed on a phone has its own debug certificate.
A release with another certificate is not automatically a compatible update.
Do not uninstall it, clear its data, or discard TV pairing material to bypass a
signature mismatch. Keep data-preserving debug updates separate from release
testing until a validated signing/migration path has been agreed.

References: [Flutter Android releases](https://docs.flutter.dev/deployment/android),
[Android app signing](https://developer.android.com/studio/publish/app-signing),
[16 KB compatibility](https://developer.android.com/guide/practices/page-sizes).
