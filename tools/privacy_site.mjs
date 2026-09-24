import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const policy = JSON.parse(fs.readFileSync(path.join(root, 'assets/privacy-policy.json'), 'utf8'));
const escape = text => text.replace(/[&<>"']/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));
const paragraph = text => `<p>${escape(text)}</p>`;
const page = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(policy.title)}</title>
<meta name="color-scheme" content="light dark">
<style>body{font:1rem/1.6 system-ui,sans-serif;margin:0;color:CanvasText;background:Canvas}main{max-width:72ch;margin:auto;padding:2rem 1.25rem}h1{font-size:2rem;line-height:1.2}h2{font-size:1.3rem;line-height:1.35;margin-top:2rem}p{overflow-wrap:anywhere}</style>
</head><body><main><h1>${escape(policy.title)}</h1>
<p>${policy.metadata.map(escape).join('<br>')}</p>
${paragraph(policy.introduction)}
${policy.sections.map(section => `<section><h2>${escape(section.heading)}</h2>${section.paragraphs.map(paragraph).join('\n')}</section>`).join('\n')}
</main></body></html>
`;
const output = path.join(root, 'build/privacy-site');
fs.mkdirSync(output, {recursive: true});
fs.writeFileSync(path.join(output, 'index.html'), page);
fs.writeFileSync(path.join(output, '.nojekyll'), '');
process.stdout.write(`${output}\n`);
