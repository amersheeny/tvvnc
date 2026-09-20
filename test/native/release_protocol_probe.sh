#!/bin/bash
# Explicit developer test, not an installed hook. Loads the exact already-built
# release APK on the chosen controller emulator/device; no TV or app data access.
set -euo pipefail
serial="${1:?Pass the adb serial of the test controller}"
repo="$(git rev-parse --show-toplevel)"
sdk="${ANDROID_HOME:?Set ANDROID_HOME to the Android SDK}"
apk="$repo/build/app/outputs/flutter-apk/app-release.apk"
mapping="$repo/build/app/outputs/mapping/release/mapping.txt"
probe_dir="$(mktemp -d "${TMPDIR:-/tmp}/tvvnc-release-probe.XXXXXX")"
probe_tag="$(basename "$probe_dir")"
remote_apk="/data/local/tmp/$probe_tag.apk"
remote_jar="/data/local/tmp/$probe_tag.jar"
mkdir -p "$probe_dir/classes"
javac --release 17 -d "$probe_dir/classes" "$repo/test/native/ReleaseProtocolProbe.java"
"$sdk/build-tools/37.0.0/d8" --min-api 26 --output "$probe_dir/probe.jar" "$probe_dir/classes/"*.class
remote_class="$(sed -n 's/^remote.Remotemessage\$RemoteMessage -> \(.*\):/\1/p' "$mapping")"
polo_class="$(sed -n 's/^com.google.polo.wire.protobuf.PoloProto\$OuterMessage -> \(.*\):/\1/p' "$mapping")"
macro_class="$(sed -n 's/^dev.tvvnc.tv_vnc.bridge.MacroAction -> \(.*\):/\1/p' "$mapping")"
pairing_class="$(sed -n 's/^io.github.ddagunts.screencast.androidtv.NativePairing\$pair\$2 -> \(.*\):/\1/p' "$mapping")"
for mapped in "$remote_class" "$polo_class" "$macro_class" "$pairing_class"; do
  [[ "$mapped" =~ ^[A-Za-z0-9_.$]+$ ]] || { echo 'Missing/invalid release mapping'; exit 1; }
done
shasum -a 256 "$apk"
adb -s "$serial" push "$apk" "$remote_apk"
adb -s "$serial" push "$probe_dir/probe.jar" "$remote_jar"
adb -s "$serial" shell "chmod 444 '$remote_apk' '$remote_jar'"
adb -s "$serial" shell "CLASSPATH='$remote_apk:$remote_jar' app_process -Xmx64m /system/bin ReleaseProtocolProbe '$remote_class' '$polo_class' '$macro_class' '$pairing_class'"
