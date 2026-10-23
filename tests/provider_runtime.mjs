// Run in the test VM with its ordinary distro Node, without TS flags/support.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../providers/', import.meta.url));
const runtime = path.join(root, 'runtime');
const manifest = JSON.parse(await readFile(path.join(runtime, 'manifest.json'), 'utf8'));
const hash = data => createHash('sha256').update(data).digest('hex');
for (const file of manifest.files) {
  assert.equal(hash(await readFile(path.join(root, file.source))), file.sourceHash, `Regenerate changed source: ${file.source}`);
  assert.equal(hash(await readFile(path.join(runtime, file.output))), file.outputHash, `Generated artifact mismatch: ${file.output}`);
}
const child = spawn(process.execPath, [path.join(runtime, 'helper.js')], { stdio: ['pipe', 'pipe', 'pipe'] });
let stdout = '', stderr = '';
child.stdout.setEncoding('utf8'); child.stderr.setEncoding('utf8');
child.stdout.on('data', chunk => { stdout += chunk; });
child.stderr.on('data', chunk => { stderr += chunk; });
const timer = setTimeout(() => { child.kill(); }, 5000);
child.stdin.end([
  { id: 1, action: 'sessionRestore', params: { cookie: '' } },
  { id: 2, action: 'discoveryDailySongs', params: {} },
  { id: 3, action: 'discoveryDailyPlaylists', params: {} }
].map(value => JSON.stringify(value)).join('\n') + '\n');
const code = await new Promise((resolve, reject) => { child.on('error', reject); child.on('close', resolve); });
clearTimeout(timer);
assert.equal(code, 0, `Helper failed: ${stderr}`);
const rows = new Map(stdout.trim().split('\n').map(line => { const row = JSON.parse(line); return [row.id, row]; }));
assert.equal(rows.get(1)?.ok, true, 'Plain-JS helper must start and restore an empty session');
for (const id of [2, 3]) {
  assert.equal(rows.get(id)?.ok, false);
  assert.equal(rows.get(id)?.category, 'auth', 'Daily recommendations must remain login gated');
}
console.log(`PASS: ${manifest.files.length} source/artifact hashes; plain-JS startup and login guards on ${process.version}.`);
