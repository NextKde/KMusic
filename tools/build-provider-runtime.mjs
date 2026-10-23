// Build-time only: regenerate the checked-in plain-JavaScript provider from TS.
// End users and the installer do not need TypeScript support or npm packages.
import { stripTypeScriptTypes } from 'node:module';
import { readFile, writeFile, mkdir, readdir, rm, copyFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../providers/', import.meta.url));
const output = path.join(root, 'runtime');
const hash = content => createHash('sha256').update(content).digest('hex');
async function sources(directory, relative = '') {
  const result = [];
  for (const entry of (await readdir(directory, { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name, 'en'))) {
    if (entry.name === 'runtime') continue;
    const name = path.posix.join(relative, entry.name);
    if (entry.isDirectory()) result.push(...await sources(path.join(directory, entry.name), name));
    else if (entry.name.endsWith('.ts')) result.push(name);
  }
  return result;
}
// Fail before touching generated artifacts if this developer Node lacks TS.
stripTypeScriptTypes('const supported: boolean = true;', { mode: 'strip' });
const files = await sources(root);
const generated = [];
for (const name of files) {
  const source = await readFile(path.join(root, name), 'utf8');
  const javascript = stripTypeScriptTypes(source, { mode: 'strip' }).replace(
    /(\bfrom\s*["']|\bimport\s*["']|\bimport\s*\(\s*["'])(\.[^"']+)\.ts(["'])/g,
    '$1$2.js$3');
  const content = '// Generated from ../' + name + ' by tools/build-provider-runtime.mjs; edit the TS source.\n' + javascript;
  generated.push({ source: name, sourceHash: hash(source), output: name.replace(/\.ts$/, '.js'), content });
}
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
for (const file of generated) {
  const target = path.join(output, file.output);
  await mkdir(path.dirname(target), { recursive: true });
  await writeFile(target, file.content);
}
for (const name of ['package.json', 'netease/LICENSE', 'netease/NOTICE.md']) {
  await mkdir(path.dirname(path.join(output, name)), { recursive: true });
  await copyFile(path.join(root, name), path.join(output, name));
}
await writeFile(path.join(output, 'manifest.json'), JSON.stringify({
  schemaVersion: 1,
  generator: 'tools/build-provider-runtime.mjs',
  nodeVersion: process.version,
  files: generated.map(({ source, sourceHash, output, content }) => ({ source, sourceHash, output, outputHash: hash(content) }))
}, null, 2) + '\n');
console.log(`Generated ${generated.length} plain-JavaScript modules.`);
