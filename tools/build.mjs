#!/usr/bin/env node
// build.mjs <rootdir> <out.html> [--scenes a,b,c] [--verify original.html] [--quiet]
//
// The Node twin of build.py: same input, same output, byte for byte (use whichever runtime you have).
// Assembles the single-file visualizer from <rootdir>/src/ (engine parts listed in src/manifest.json) and
// <rootdir>/scenes/<key>/. With no options: every scene the engine lists, then every other folder in scenes/
// whose name does not start with "_".
//   --scenes a,b,c   only these scenes (keys or folder names; "_template" is allowed here): a small, fast file
//   --verify FILE    compare the result with FILE byte for byte
// Also importable:  import { assemble } from './build.mjs'
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const PARTS = ['glsl', 'helpers', 'entry'];
const PART_FILE = { glsl: 'scene.glsl', helpers: 'helpers.js', entry: 'entry.js' };
const MARK = { glsl: 'GLSL', helpers: 'HELPERS', entry: 'ENTRY' };
const TABLES = { show: 'SHOW', auto: 'AUTO_REALM' };
const KEY_RE = /^[a-z][a-z0-9]{1,23}$/;
const LINE_PH = () => /^\/\/@scene (glsl|helpers|entry) ([a-z0-9]+)\n/gm;
const ROW_PH = () => /\/\*@scene (show|auto) ([a-z0-9]+)\*\//g;
const read = (p) => fs.readFileSync(p, 'utf8');
const readJson = (p) => JSON.parse(read(p));
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export function sceneDirs(scenesDir) {
  const out = new Map();
  if (!fs.existsSync(scenesDir)) return out;
  for (const name of fs.readdirSync(scenesDir).sort()) {
    const d = path.join(scenesDir, name);
    if (!fs.existsSync(path.join(d, 'entry.js'))) continue;
    let key = name;
    const meta = path.join(d, 'scene.json');
    if (fs.existsSync(meta)) { try { key = readJson(meta).key || name; } catch (e) { /* keep the folder name */ } }
    out.set(key, d);
  }
  return out;
}
function tableSpan(text, name) {
  const m = new RegExp('^const ' + esc(name) + ' = \\{\\n', 'm').exec(text);
  if (!m) return null;
  const start = m.index + m[0].length, end = text.indexOf('\n};', start - 1);
  return end < 0 ? null : [start, end + 1];
}
export function entryField(entry, field) {
  const m = new RegExp('\\b' + field + '\\s*:\\s*(\'(?:[^\'\\\\\\n]|\\\\.)*\'|"(?:[^"\\\\\\n]|\\\\.)*")').exec(entry);
  return m ? m[1].slice(1, -1).replace(/\\(.)/g, '$1') : null;
}
function eolJoin(text, info) {
  const kind = (info && info.newline) || 'lf';
  if (kind === 'crlf') text = text.replace(/\n/g, '\r\n');
  else if (kind === 'mixed') {
    const lines = text.split('\n'), runs = info.eol_runs || [];
    if (runs.reduce((a, r) => a + r[0], 0) === lines.length - 1) {
      const out = []; let i = 0;
      for (const [count, k] of runs) { for (const line of lines.slice(i, i + count)) out.push(line + (k ? '\r\n' : '\n')); i += count; }
      out.push(lines[lines.length - 1]); text = out.join('');
    } else text = text.replace(/\n/g, '\r\n');
  }
  return Buffer.from(text, 'utf8');
}

// Returns { bytes, text, chosen, manifest }. `only`: array of scene keys / folder names, or null for all.
export function assemble(root, only = null, log = console.log) {
  if (path.basename(path.resolve(root)) === 'src' && fs.existsSync(path.join(root, 'manifest.json'))) root = path.dirname(path.resolve(root));
  const src = path.join(root, 'src'), scenesDir = path.join(root, 'scenes');
  const manifest = readJson(path.join(src, 'manifest.json'));
  let text = manifest.parts.map((rel) => read(path.join(src, rel))).join('');
  const dirs = sceneDirs(scenesDir);
  const byFolder = new Map([...dirs].map(([k, d]) => [path.basename(d), k]));
  const fail = (msg) => { throw new Error('build: ' + msg); };

  const listed = [];
  for (const m of text.matchAll(LINE_PH())) if (!listed.includes(m[2])) listed.push(m[2]);
  let extra = [...dirs.keys()].filter((k) => !listed.includes(k) && !path.basename(dirs.get(k)).startsWith('_'));
  let chosen;
  if (!only) chosen = listed.concat(extra);
  else {
    chosen = only.map((name) => {
      const key = dirs.has(name) ? name : byFolder.get(name);
      if (!key) fail('no scene "' + name + '" in ' + scenesDir + ' (have: ' + [...dirs.keys()].sort().join(', ') + ')');
      return key;
    });
    extra = chosen.filter((k) => !listed.includes(k));
  }
  for (const key of chosen) {
    if (!dirs.has(key)) fail('the engine lists scene "' + key + '" but ' + scenesDir + ' has no folder for it');
    if (!KEY_RE.test(key)) fail('scene key "' + key + '" must be 2-24 lowercase letters / digits, starting with a letter');
  }
  const chosenSet = new Set(chosen), cache = new Map();
  const region = (part, key) => {
    const p = path.join(dirs.get(key), PART_FILE[part]);
    let body = fs.existsSync(p) ? read(p) : '';
    if (body && !body.endsWith('\n')) body += '\n';
    return '// BEGIN NEWREALM ' + MARK[part] + ': ' + key + '\n' + body + '// END NEWREALM ' + MARK[part] + ': ' + key + '\n';
  };
  const meta = (key) => {
    if (!cache.has(key)) { const p = dirs.has(key) ? path.join(dirs.get(key), 'scene.json') : ''; cache.set(key, p && fs.existsSync(p) ? readJson(p) : {}); }
    return cache.get(key);
  };

  if (extra.length) {
    for (const part of PARTS) {
      let last = null;
      for (const m of text.matchAll(LINE_PH())) if (m[1] === part) last = m;
      if (!last) fail('src/ has no //@scene ' + part + ' placeholder to put new scenes after');
      const at = last.index + last[0].length;
      text = text.slice(0, at) + extra.map((k) => '//@scene ' + part + ' ' + k + '\n').join('') + text.slice(at);
    }
    for (const [kind, table] of Object.entries(TABLES)) {
      const have = new Set([...text.matchAll(ROW_PH())].filter((m) => m[1] === kind).map((m) => m[2]));
      const add = extra.filter((k) => !have.has(k) && meta(k)[kind]).map((k) => '  ' + k + ': /*@scene ' + kind + ' ' + k + '*/,\n').join('');
      if (!add) continue;
      const span = tableSpan(text, table);
      if (!span) { log('build: warning: table ' + table + ' not found; "' + kind + '" of new scenes ignored'); continue; }
      text = text.slice(0, span[0]) + add + text.slice(span[0]);
    }
  }
  // a scene left out of the build: nothing, except a stand-in for any name of its that the engine itself refers to
  const stubs = manifest.stubs || {};
  text = text.replace(LINE_PH(), (all, part, key) => (chosenSet.has(key) ? region(part, key) : part === 'helpers' ? stubs[key] || '' : ''));
  text = text.replace(ROW_PH(), (all, kind, key) => {
    const value = dirs.has(key) ? meta(key)[kind] : null;
    if (!value) {
      if (chosenSet.has(key)) fail('scenes/' + key + '/scene.json has no "' + kind + '" (the engine table ' + TABLES[kind] + ' expects one)');
      return '{}';
    }
    return value;
  });
  for (const key of chosen) {
    const e = read(path.join(dirs.get(key), PART_FILE.entry)), ek = entryField(e, 'key');
    if (ek && ek !== key) fail('scenes/' + path.basename(dirs.get(key)) + ": entry.js says key:'" + ek + '\' but the scene key is "' + key + '"');
    const nm = entryField(e, 'name'), jn = meta(key).name;
    if (nm && jn && nm !== jn) log('build: warning: scene "' + key + '": name in entry.js (' + nm + ') differs from scene.json (' + jn + ')');
  }
  return { bytes: eolJoin(text, manifest), text, chosen, manifest, dirs };
}

function main(argv) {
  const args = []; let only = null, verify = null, quiet = false;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--scenes') only = argv[++i].split(',').map((s) => s.trim()).filter(Boolean);
    else if (a.startsWith('--scenes=')) only = a.slice(9).split(',').map((s) => s.trim()).filter(Boolean);
    else if (a === '--verify') verify = argv[++i];
    else if (a === '--quiet') quiet = true;
    else args.push(a);
  }
  if (args.length !== 2) { console.log('usage: node tools/build.mjs <rootdir> <out.html> [--scenes a,b,c] [--verify original.html] [--quiet]'); return 2; }
  const log = quiet ? () => {} : console.log;
  let r;
  try { r = assemble(args[0], only, log); } catch (e) { console.error(e.message); return 1; }
  fs.mkdirSync(path.dirname(path.resolve(args[1])), { recursive: true });
  fs.writeFileSync(args[1], r.bytes);
  log('build: ' + args[1] + '  ' + r.bytes.length + ' bytes, ' + r.chosen.length + ' scenes (' + (r.chosen.length <= 8 ? r.chosen.join(', ') : r.chosen.slice(0, 8).join(', ') + ', ...') + ')');
  if (verify) {
    const want = fs.readFileSync(verify);
    if (want.equals(r.bytes)) console.log('verify: IDENTICAL to ' + verify + ' (' + r.bytes.length + ' bytes, sha256 ' + crypto.createHash('sha256').update(r.bytes).digest('hex') + ')');
    else {
      let n = 0; const lim = Math.min(want.length, r.bytes.length);
      while (n < lim && want[n] === r.bytes[n]) n++;
      console.log('verify: DIFFERENT from ' + verify + ': first difference at byte ' + n + ' (sizes ' + want.length + ' / ' + r.bytes.length + ')');
      return 1;
    }
  }
  return 0;
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) process.exit(main(process.argv.slice(2)));
