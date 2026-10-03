import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
execFileSync(process.execPath, [path.join(root, 'tools/privacy_site.mjs')]);
const html = fs.readFileSync(path.join(root, 'build/privacy-site/index.html'), 'utf8');
const policy = JSON.parse(fs.readFileSync(path.join(root, 'assets/privacy-policy.json'), 'utf8'));
const decoded = html.replace(/&(#39|quot|gt|lt|amp);/g,
  (_, entity) => ({'#39': "'", quot: '"', gt: '>', lt: '<', amp: '&'}[entity]));

test('the public page preserves every approved in-app policy paragraph', () => {
  for (const text of [policy.title, ...policy.metadata, policy.introduction,
    ...policy.sections.flatMap(s => [s.heading, ...s.paragraphs])]) {
    assert.ok(decoded.includes(text), `Missing approved policy text: ${text}`);
  }
  assert.equal((html.match(/<h1>/g) ?? []).length, 1);
  assert.equal((html.match(/<h2>/g) ?? []).length, policy.sections.length);
  assert.equal((html.match(/<section>/g) ?? []).length, policy.sections.length);
});

test('the policy is self-contained static HTML with mobile text wrapping', () => {
  assert.match(html, /<html lang="en">/);
  assert.match(html, /name="viewport" content="width=device-width, initial-scale=1"/);
  assert.match(html, /overflow-wrap:anywhere/);
  assert.doesNotMatch(html, /<(script|iframe|img|link|form)\b/i);
  assert.doesNotMatch(html, /(?:src|href)\s*=/i);
  assert.equal(fs.readFileSync(path.join(root, 'build/privacy-site/.nojekyll'), 'utf8'), '');
});
