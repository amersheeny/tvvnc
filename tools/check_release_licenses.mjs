import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {readFileSync, readdirSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const archive = process.argv[2];
assert.ok(archive && /\.(apk|aab)$/.test(archive), 'Pass the APK or AAB path');
const prefix = archive.endsWith('.aab') ? 'base/assets/flutter_assets/' : 'assets/flutter_assets/';
const files = ['LICENSE', 'NOTICE',
  'native/libvncserver/COPYING', 'native/libvncserver/AUTHORS', 'native/libvncserver/TVCONSOLE_CHANGES.md',
  'native/libjpeg-turbo/LICENSE.md', 'native/libjpeg-turbo/README.ijg',
  'native/androidtv-remote/LICENSE', 'native/androidtv-remote/androidtv-remote/NOTICE',
  'native/androidtv-remote/protocol-schemas/LICENSE',
  ...readdirSync(path.join(root, 'assets/licenses')).map(name => `assets/licenses/${name}`)];
for (const file of files) {
  const packaged = execFileSync('unzip', ['-p', archive, prefix + file]);
  assert.deepEqual(packaged, readFileSync(path.join(root, file)), `License content differs: ${file}`);
  process.stdout.write(`MATCH ${file}\n`);
}
const notices = execFileSync('unzip', ['-p', archive, prefix + 'NOTICES.Z']);
assert.ok(notices.length > 0, 'Flutter dependency notices are missing');
process.stdout.write(`${files.length} legal files match; Flutter NOTICES.Z present\n`);
