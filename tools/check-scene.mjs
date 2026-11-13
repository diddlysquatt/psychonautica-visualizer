#!/usr/bin/env node
// check-scene.mjs <scene key | folder name | path/to/<key>.scene.js> [options]
//
// One command that tells you whether a scene is fit to share. It
//   1. reads the scene's files and reports the mistakes that can be seen without running anything;
//   2. builds a small visualizer with only that scene (same result as tools/build.py --scenes <key>);
//   3. opens it in a headless browser and fails on any shader, page or console error;
//   4. plays a built-in test track through the scene with the Auto Show on and fails on black frames or
//      non-finite numbers (NaN / Infinity) in what the scene sends to its shader;
//   5. measures how much of the picture answers to each part of the music (bass, mids, highs, kick, snare, hats);
//   6. reports the scene's compile time;
//   7. writes a contact sheet: the zoom ladder, one kaleidoscope fold and a short tour.
// Exit code 0 = passed (warnings may still be printed), 1 = failed, 2 = could not run.
//
// Options:
//   --out DIR        where the build and the sheet go (default: check-out/<key>/)
//   --gl MODE        swiftshader (default: software rendering, works everywhere, slow) | hardware (your GPU;
//                    the only mode whose compile time means anything) | vulkan
//   --seconds N      length of the health run (default 24, the whole test track)
//   --size WxH       picture size for the run (default 480x270; the sheet uses it too)
//   --quick          skip the band-response measurement
// Environment: VISUALIZER_CHROME = path of a Chrome / Chromium to use instead of Playwright's own.
//
// Needs Node 18+ and `npm install` (Playwright is the only dependency). If Playwright has no browser yet the tool
// tries an installed Chrome or Edge; otherwise run `npx playwright install chromium` once.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { assemble } from './build.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const argv = process.argv.slice(2);
const opt = { out: null, gl: 'swiftshader', seconds: 24, size: '480x270', quick: false };
const rest = [];
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--out') opt.out = argv[++i];
  else if (a === '--gl') opt.gl = argv[++i];
  else if (a === '--seconds') opt.seconds = Number(argv[++i]);
  else if (a === '--size') opt.size = argv[++i];
  else if (a === '--quick') opt.quick = true;
  else rest.push(a);
}
if (rest.length !== 1) {
  console.log('usage: node tools/check-scene.mjs <scene key | path/to/<key>.scene.js> [--out DIR] [--gl swiftshader|hardware|vulkan] [--seconds N] [--size WxH] [--quick]');
  process.exit(2);
}
const [W, H] = opt.size.split('x').map(Number);
const FPS = 30;
const fails = [], warns = [];
const fail = (m) => { fails.push(m); console.log('  FAIL  ' + m); };
const warn = (m) => { warns.push(m); console.log('  warn  ' + m); };
const ok = (m) => console.log('  ok    ' + m);
const head = (m) => console.log('\n== ' + m);

/* ------------------------------------------------------------------ 1. static checks */
function staticChecks(key, glslFile, helpers, entry, isPack) {
  head('1. files');
  const R = 'R_' + key.toUpperCase();
  const tm = /const\s+R_[A-Z0-9]+\s*=\s*`([\s\S]*?)`\s*;/.exec(glslFile);
  const glsl = isPack ? glslFile : tm ? tm[1] : glslFile;
  if (!isPack) {
    if (!tm) warn('scene.glsl: no  const ' + R + ' = `...`;  found (the shader text is usually declared that way)');
    else if (!glslFile.includes('const ' + R + ' ')) warn('scene.glsl: the shader constant is usually named ' + R);
    const ticks = (glslFile.match(/`/g) || []).length;
    if (ticks % 2) fail('scene.glsl: odd number of backticks: a stray backtick inside the shader text ends the string and breaks the whole page');
  }
  if (/\$\{/.test(glsl)) fail('shader text contains "${": inside a JavaScript template string that starts an interpolation');
  if (!/void\s+realm\s*\(\s*\)/.test(glsl)) fail('the shader must define  void realm()');
  if (!/fragColor/.test(glsl)) fail('the shader never writes fragColor');
  if (/#version|precision\s+(highp|mediump|lowp)\s+float\s*;/.test(glsl)) warn('the engine adds #version and precision itself: remove them from the shader');
  if (/^\s*uniform\s/m.test(glsl)) warn('the shader declares its own uniform: the engine only sets the uniforms listed in docs/SCENE-CONTRACT.md (use uP1..uP5, uM1, uM2)');
  if (/\btexture2D\s*\(|\bgl_FragColor\b/.test(glsl)) fail('WebGL1 names (texture2D, gl_FragColor) do not exist in GLSL ES 3.00');
  if (/\bswitch\s*\(/.test(glsl) && /\bcontinue\s*;/.test(glsl)) warn('the shader uses both switch and continue: "continue" inside a "switch" does not compile on Windows (D3D11); use if / else');
  const loops = (glsl.match(/\bfor\s*\(/g) || []).length + (glsl.match(/\bwhile\s*\(/g) || []).length;
  if (/\bwhile\s*\(/.test(glsl)) warn('while loops: use for loops with a constant upper bound and an early break');
  const ternaries = (glsl.match(/\?[^:;\n]{1,120}:/g) || []).length;
  if (ternaries > 40) warn(ternaries + ' "?:" selections in the shader: on Windows each becomes an if / else block and long chains compile slowly (docs/PITFALLS.md)');
  const js = (helpers + '\n' + entry).replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:'"])\/\/.*$/gm, '$1'); // comments removed
  if (/Math\.random\s*\(/.test(js)) fail('Math.random() in the scene\'s JavaScript: use the engine\'s rand() (seeded in tests and offline renders)');
  if (!/\binit\b/.test(entry) || !/\bframe\b/.test(entry)) fail('entry needs init(seed) and frame(V, F, dt)');
  if (!isPack) {
    if (!/\}\s*,$/.test(entry.trim())) fail('entry.js must end with "}," (the scene object is one element of a list)');
    const ek = /\bkey\s*:\s*['"]([^'"]+)['"]/.exec(entry);
    if (!ek) fail('entry.js has no key:\'' + key + '\'');
    else if (ek[1] !== key) fail('entry.js says key:\'' + ek[1] + '\' but the scene is "' + key + '"');
    const bad = [];
    for (const m of helpers.matchAll(/^(?:async\s+)?(?:function\*?|const|let|var|class)\s+([A-Za-z_$][\w$]*)/gm)) if (!m[1].toLowerCase().startsWith(key) && m[1] !== R) bad.push(m[1]);
    if (bad.length) warn('helpers.js: top-level names must start with the scene key "' + key + '" (all scenes share one scope): ' + [...new Set(bad)].slice(0, 8).join(', '));
    const badG = [];
    for (const m of glslFile.replace(/`[\s\S]*?`/g, '``').matchAll(/^(?:function|const|let|var)\s+([A-Za-z_$][\w$]*)/gm)) if (!m[1].toLowerCase().startsWith(key) && !m[1].startsWith('R_')) badG.push(m[1]);
    if (badG.length) warn('scene.glsl: top-level JavaScript names must start with the scene key or R_: ' + badG.join(', '));
  }
  if (!fails.length) ok('shader text, entry and helpers look sane (' + glsl.split('\n').length + ' shader lines, ' + loops + ' loops, ' + ternaries + ' "?:")');
  return glsl;
}

/* ------------------------------------------------------------------ test track */
// 24 s, 128 BPM, mono 16-bit: 4 bars quiet intro (pad + hats), 4 bars groove, 2 bars build (riser, snare roll, no kick),
// then the drop (everything, a lead line). Enough structure for sections, a build and an impact.
function testTrack(seconds = 24, sr = 22050) {
  const n = Math.ceil(seconds * sr), b = Buffer.alloc(44 + n * 2), bpm = 128, spb = 60 / bpm;
  b.write('RIFF'); b.writeUInt32LE(b.length - 8, 4); b.write('WAVEfmt ', 8);
  b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(1, 22);
  b.writeUInt32LE(sr, 24); b.writeUInt32LE(sr * 2, 28); b.writeUInt16LE(2, 32); b.writeUInt16LE(16, 34);
  b.write('data', 36); b.writeUInt32LE(n * 2, 40);
  let seed = 12345; const rnd = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x3fffffff - 1; };
  const notes = [220, 261.63, 329.63, 392, 329.63, 261.63, 440, 392];
  let hp = 0, hprev = 0;
  for (let i = 0; i < n; i++) {
    const t = i / sr, beat = t / spb, bar = Math.floor(beat / 4), ph = beat % 1, noise = rnd();
    const intro = bar < 4, build = bar >= 8 && bar < 10, drop = bar >= 10;
    hp = 0.86 * (hp + noise - hprev); hprev = noise;                               // high-passed noise for hats
    let s = 0;
    const padGain = intro ? 0.10 : build ? 0.05 : 0.07;
    for (const f of [110, 164.81, 220]) s += padGain * Math.sin(2 * Math.PI * f * t) * (0.7 + 0.3 * Math.sin(t * 0.7));
    const h8 = (beat * 2) % 1; s += hp * Math.exp(-h8 * 22) * (intro ? 0.10 : 0.16);          // hats on eighths
    if (!intro && !build) {
      s += Math.sin(2 * Math.PI * (52 * ph * spb + 3.2 * (1 - Math.exp(-ph * spb * 38)))) * Math.exp(-ph * 9) * (drop ? 0.62 : 0.5); // kick
      if (Math.floor(beat) % 2 === 1) s += (noise * 0.6 + Math.sin(2 * Math.PI * 190 * ph * spb) * 0.4) * Math.exp(-ph * 16) * 0.3;  // snare on 2 and 4
      const bt = (beat * 2) % 1; s += Math.sin(2 * Math.PI * 55 * t) * (0.25 + 0.2 * Math.exp(-bt * 6)) * (drop ? 1 : 0.8);          // bass
    }
    if (build) {
      const u = (beat - 32) / 8; // 0..1 through the build
      s += hp * 0.28 * u * u;                                                               // riser
      const roll = (beat * (u < 0.5 ? 2 : 4)) % 1; s += noise * Math.exp(-roll * 18) * 0.22 * (0.4 + u); // snare roll
    }
    if (drop) { const k = Math.floor(beat * 2) % notes.length, e = (beat * 2) % 1; s += 0.14 * Math.sign(Math.sin(2 * Math.PI * notes[k] * 2 * t)) * Math.exp(-e * 5); } // lead
    b.writeInt16LE(Math.round(Math.max(-1, Math.min(1, s)) * 30000), 44 + i * 2);
  }
  return b;
}

/* ------------------------------------------------------------------ browser */
async function launch() {
  let chromium;
  try { ({ chromium } = await import('playwright')); }
  catch (e) { console.error('check-scene: Playwright is not installed. Run `npm install` in the repository root first.'); process.exit(2); }
  const args = ['--autoplay-policy=no-user-gesture-required'];
  if (opt.gl === 'vulkan') args.push('--use-angle=vulkan', '--enable-features=Vulkan');
  else if (opt.gl === 'hardware') args.push('--enable-gpu', '--ignore-gpu-blocklist');
  else args.push('--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader');
  const tries = [];
  if (process.env.VISUALIZER_CHROME) tries.push({ executablePath: process.env.VISUALIZER_CHROME });
  tries.push({}, { channel: 'chrome' }, { channel: 'msedge' });
  let last = null;
  for (const t of tries) {
    try { return await chromium.launch({ headless: true, args, ...t }); } catch (e) { last = e; }
  }
  console.error('check-scene: no browser could be started. Run `npx playwright install chromium` once (or set VISUALIZER_CHROME).\n' + String(last && last.message).split('\n')[0]);
  process.exit(2);
}

/* ------------------------------------------------------------------ main */
const target = rest[0];
const isPack = /\.scene\.js$/i.test(target) && fs.existsSync(target);
let key, buildOnly, packText = null;
if (isPack) {
  packText = fs.readFileSync(target, 'utf8');
  const m = /\bkey\s*:\s*['"]([a-z][a-z0-9]{1,23})['"]/.exec(packText);
  if (!m) { console.error('check-scene: no key: \'...\' found in ' + target); process.exit(2); }
  key = m[1]; buildOnly = ['_template'];
} else { key = target; buildOnly = [target]; }

let built;
try { built = assemble(ROOT, buildOnly, () => {}); }
catch (e) { console.error(String(e.message)); process.exit(2); }
if (!isPack) key = built.chosen[0];
const outDir = path.resolve(opt.out || path.join(ROOT, 'check-out', key));
fs.mkdirSync(outDir, { recursive: true });
const htmlPath = path.join(outDir, key + '.html');
fs.writeFileSync(htmlPath, built.bytes);
console.log('check-scene: ' + (isPack ? 'pack ' + target : 'scene "' + key + '"') + '  ->  ' + path.relative(process.cwd(), outDir));

if (isPack) {
  const grab = (f) => { const m = new RegExp('\\b' + f + '\\s*:\\s*String\\.raw`([\\s\\S]*?)`\\s*,').exec(packText); return m ? m[1] : ''; };
  staticChecks(key, grab('glsl') || packText, grab('helpers'), grab('entry') || packText, true);
} else {
  const d = built.dirs.get(key), rd = (f) => (fs.existsSync(path.join(d, f)) ? fs.readFileSync(path.join(d, f), 'utf8') : '');
  staticChecks(key, rd('scene.glsl'), rd('helpers.js'), rd('entry.js'), false);
  const meta = fs.existsSync(path.join(d, 'scene.json')) ? JSON.parse(rd('scene.json')) : null;
  if (!meta) warn('no scene.json (name, description, author, license, and the Auto Show rows "show" and "auto")');
  else {
    for (const f of ['name', 'description', 'author', 'license']) if (!meta[f]) warn('scene.json: "' + f + '" is empty');
    if (!meta.show) warn('scene.json has no "show" row: the Auto Show will frame this scene with its defaults (home .6, far .35, close 1)');
  }
}
if (fails.length) { console.log('\ncheck-scene: FAILED before running (' + fails.length + ' problem' + (fails.length > 1 ? 's' : '') + ')'); process.exit(1); }

const browser = await launch();
const errors = [];
let exitCode = 0;
try {
  const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', (e) => errors.push(String(e.stack || e.message).split('\n').slice(0, 3).join(' | ')));

  head('2. load and compile');
  const t0 = Date.now();
  await page.goto(pathToFileURL(htmlPath).href, { timeout: 180000 });
  const hasApi = await page.evaluate(() => !!window.HyperVisualizer);
  if (!hasApi) { fail('the page did not start (window.HyperVisualizer is missing): ' + (errors[0] || 'no error message')); throw new Error('stop'); }
  await page.evaluate(() => { window.HyperVisualizer.prepare(); });
  await page.waitForFunction(() => { const h = window.HyperVisualizer, p = h.preparation; return (h.ready && h.allReady) || (p && p.error); }, null, { timeout: 900000, polling: 250 });
  let ri = 0;
  if (isPack) {
    const res = await page.evaluate(async (text) => {
      const h = window.HyperVisualizer;
      if (typeof h.addSceneText !== 'function' && typeof h.registerScene !== 'function') return { error: 'this engine has no scene pack loader (HyperVisualizer.registerScene): see docs/SCENE-PACKS.md' };
      try {
        const r = h.addSceneText ? await h.addSceneText(text, { persist: false }) : await (0, eval)(text);
        return { index: r && r.index };
      } catch (e) { return { error: String(e && e.message || e) }; }
    }, packText);
    if (res.error) { fail('the pack was refused: ' + res.error); throw new Error('stop'); }
    ri = Number.isInteger(res.index) ? res.index : await page.evaluate((k) => window.HyperVisualizer.REALMS.findIndex((r) => r.key === k), key);
    await page.waitForFunction((i) => { const R = window.HyperVisualizer.REALMS[i]; return R && (R.ready || R.failed); }, ri, { timeout: 900000, polling: 250 });
  }
  const st = await page.evaluate((i) => {
    const h = window.HyperVisualizer, R = h.REALMS[i], gl = document.getElementById('stage').getContext('webgl2');
    const e = gl && gl.getExtension('WEBGL_debug_renderer_info'), t = (h.preparation.timings || []).find((x) => x.key === R.key);
    return { key: R.key, name: R.name, ready: !!R.ready, failed: !!R.failed, ok: !!(R.P && R.P.ok), prepError: h.preparation.error || '',
      renderer: gl ? gl.getParameter(e ? e.UNMASKED_RENDERER_WEBGL : gl.RENDERER) : 'no WebGL2', timing: t || null, scenes: h.REALMS.length };
  }, ri);
  console.log('  renderer: ' + st.renderer);
  if (st.prepError) fail('the engine could not prepare: ' + st.prepError);
  if (!st.ready || st.failed) fail('the scene\'s shader did not compile or its first draw failed' + (errors.length ? ': ' + errors.slice(0, 4).join(' || ') : ''));
  else ok('"' + st.name + '" compiled and drew its first frame');
  if (st.timing) {
    const hw = opt.gl !== 'swiftshader';
    console.log('  compile + first draw: ' + st.timing.ms + ' ms (link ' + st.timing.linkMs + ' ms)' + (hw ? '' : '   [software rendering: run with --gl hardware on Windows for the number that matters]'));
    if (hw && st.timing.ms > 8000) warn('first draw took ' + (st.timing.ms / 1000).toFixed(1) + ' s: the limit for the base tier (HD 0, which phones also compile) is about 8 s on D3D11 (docs/PITFALLS.md)');
  }
  if (errors.length) fail('page errors while loading: ' + errors.slice(0, 5).join(' || '));
  if (fails.length) throw new Error('stop');

  /* ---------------- 3. health run: Auto Show on, real analysis of the test track */
  head('3. health run (' + opt.seconds + ' s of the test track, Auto Show on)');
  const wav = testTrack(24).toString('base64');
  await page.evaluate((b64) => { window.__wav = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0)).buffer; }, wav);
  const base = { dose: 1, reactivity: 1, speed: 1, motionSmooth: 0.75, flashes: 0.8, trails: 0.6, warp: 0.55, bloom: 0.8, chroma: 0.5, palette: 'auto', colorSpeed: 0.6, saturation: 1, quality: 'high', detail: 1, hud: false, sceneDuration: 0 };
  await page.evaluate(async ({ ri, base }) => {
    const h = window.HyperVisualizer;
    Object.assign(h.S, base, { symmetry: 'auto', autopilot: false, cameraMode: 'tour' });
    await h.offline.load(window.__wav, { seed: 1234567 });
    h.setAutoShow(true, true);
    h.goRealm(ri, 0.01, undefined, true);
    window.__stats = (gl) => {
      const w = gl.drawingBufferWidth, hh = gl.drawingBufferHeight, px = new Uint8Array(w * hh * 4);
      gl.readPixels(0, 0, w, hh, gl.RGBA, gl.UNSIGNED_BYTE, px);
      let sum = 0, lit = 0, pale = 0, ink = 0, n = 0;
      for (let i = 0; i < px.length; i += 16) {
        const r = px[i], g = px[i + 1], b = px[i + 2], mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        sum += l; lit += mx > 12; pale += l > 170 && (mx - mn) < 0.25 * mx; ink += l < 40; n++;
      }
      return { luma: sum / n, lit: lit / n, pale: pale / n, ink: ink / n };
    };
  }, { ri, base });
  const frames = Math.round(Math.min(24, opt.seconds) * FPS), tourEvery = Math.floor(frames / 8), tour = [];
  let health = { bad: [], rows: [], cues: { section: 0, impact: 0, drop: 0, kick: 0 } };
  for (let from = 0; from < frames; from += 60) {
    const part = await page.evaluate(({ from, to, fps, tourEvery, ri }) => {
      const h = window.HyperVisualizer, cv = document.getElementById('stage'), gl = cv.getContext('webgl2');
      const out = { bad: [], rows: [], shots: [], cues: { section: 0, impact: 0, drop: 0, kick: 0 }, lost: false };
      for (let n = from; n < to; n++) {
        const draw = n % 2 === 0 || n % tourEvery === 0;
        h.offline.frame(n, fps, !draw);
        const V = h.D.cur; if (!V || V.ri !== ri) { if (h.D.nxt && h.D.nxt.ri === ri) continue; out.bad.push('frame ' + n + ': the scene is not on screen'); continue; }
        const u = ['p1', 'p2', 'p3', 'p4', 'p5', 'm1', 'm2'];
        for (const k of u) { const a = Array.from(V[k] || []); if (!a.every(Number.isFinite)) { out.bad.push('frame ' + n + ': V.' + k + ' = [' + a.map((x) => (Number.isFinite(x) ? +x.toFixed(3) : String(x))).join(', ') + ']'); break; } }
        const F = h.F; out.cues.section += F.onSection ? 1 : 0; out.cues.impact += F.onImpact ? 1 : 0; out.cues.drop += F.onDrop ? 1 : 0; out.cues.kick += F.onKick ? 1 : 0;
        if (draw) {
          if (gl.isContextLost()) { out.lost = true; break; }
          const s = window.__stats(gl); s.n = n; s.zoom = +h.autoFraming(V).toFixed(3); out.rows.push(s);
          if (n % tourEvery === 0) out.shots.push({ n, url: cv.toDataURL('image/jpeg', 0.86), label: 't ' + (n / fps).toFixed(1) + ' s   zoom ' + s.zoom });
        }
      }
      return out;
    }, { from, to: Math.min(frames, from + 60), fps: FPS, tourEvery, ri });
    health.bad.push(...part.bad); health.rows.push(...part.rows); tour.push(...part.shots);
    for (const k in part.cues) health.cues[k] += part.cues[k];
    if (part.lost) { fail('the WebGL context was lost during the run'); break; }
  }
  if (health.bad.length) fail('non-finite or missing scene output: ' + health.bad.slice(0, 4).join(' ; ') + (health.bad.length > 4 ? ' ... (' + health.bad.length + ' frames)' : ''));
  else ok('V.p1..p5, V.m1, V.m2 finite on every frame');
  const after = health.rows.filter((r) => r.n >= FPS * 2); // the first two seconds are the arrival and the exposure settling
  let run = 0, worst = 0; for (const r of after) { run = r.lit < 0.02 ? run + 1 : 0; worst = Math.max(worst, run); }
  const mean = (k) => after.reduce((a, r) => a + r[k], 0) / Math.max(1, after.length);
  if (worst >= 5) fail('black frames: ' + worst + ' sampled frames in a row with under 2% of the picture lit');
  else ok('no black passages (darkest stretch: ' + worst + ' sampled frames)');
  console.log('  picture over the run: mean luma ' + mean('luma').toFixed(0) + ' / 255, lit ' + (100 * mean('lit')).toFixed(0) + '%, ink (dark) ' + (100 * mean('ink')).toFixed(0) + '%, pale (washed out) ' + (100 * mean('pale')).toFixed(1) + '%');
  if (mean('pale') > 0.12) warn('more than 12% of the picture is pale (bright and unsaturated): washout is the first thing a reviewer sends back (docs/ART-DIRECTION.md)');
  if (mean('ink') < 0.1) warn('under 10% of the picture is dark: colour needs ink between it to read (docs/ART-DIRECTION.md)');
  if (mean('luma') < 14) warn('the picture is very dark on average');
  console.log('  cues the engine found in the test track: ' + health.cues.kick + ' kicks, ' + health.cues.section + ' section changes, ' + health.cues.impact + ' impacts, ' + health.cues.drop + ' drops');
  if (errors.length) fail('page errors during the run: ' + errors.slice(0, 5).join(' || '));

  /* ---------------- 4. band response: one synthetic input at a time over the same clock */
  const resp = [];
  if (!opt.quick && !fails.length) {
    head('4. response to each part of the music (share of the picture that changes against silence)');
    const scn = ['silence', 'sub_bass', 'mids', 'highs', 'kick', 'snare', 'hats'];
    const ref = {};
    for (const sc of scn) {
      const r = await page.evaluate(async ({ ri, sc, base, fps }) => {
        const h = window.HyperVisualizer, R = h.REALMS[ri], cv = document.getElementById('stage'), gl = cv.getContext('webgl2');
        const ph = (x) => x - Math.floor(x), e = (s, tau) => Math.exp(-Math.max(0, s) / tau);
        const SC = {
          silence: () => ({ F: {}, lv: {}, on: {} }),
          sub_bass: (b, d) => { const t = ph(b * 2) * d / 2, v = .3 + .65 * e(t, .25), o = e(t, .07); return { F: { sub: v, bass: v, subN: v, bassN: v }, lv: { 0: v, 1: v }, on: { 0: o, 1: o } }; },
          mids: (b, d) => { const t = ph(b + .5) * d, v = .3 + .65 * e(t, .3), o = e(t, .07); return { F: { mid: v, midN: v }, lv: { 2: v, 3: v }, on: { 2: o, 3: o } }; },
          highs: (b, d) => { const t = ph(b) * d, v = .35 + .55 * (.6 + .4 * e(t, .2)), o = e(t, .07); return { F: { high: v, highN: v }, lv: { 4: v, 5: v, 6: v, 7: v }, on: { 4: o, 5: o } }; },
          kick: (b, d) => { const t = ph(b) * d, v = e(t, .12), o = e(t, .1); return { F: { kick: v }, lv: {}, on: { 0: o, 1: o } }; },
          snare: (b, d) => { const t = ph((b - 1) / 2) * 2 * d, v = e(t, .12), o = e(t, .1); return { F: { hit: v }, lv: {}, on: { 3: o, 4: o } }; },
          hats: (b, d) => { const t = ph(b * 4) * d / 4, v = e(t, .03); return { F: { hat: v }, lv: {}, on: { 6: v, 7: v } }; }
        };
        await h.offline.load(window.__wav, { seed: 1234567 });
        h.setAutoShow(false, true);
        Object.assign(h.S, base, { symmetry: '0', autopilot: false, cameraMode: 'hold' });
        h.DBG.react = { gain: 1.0001, guard: 0 }; // the shader then gets exactly the inputs frame() got
        h.goRealm(ri, 0.01, undefined, true);
        const V0 = h.D.nxt || h.D.cur; V0.seed = [.1, .3, .5, .7]; V0.c = V0.R.init(V0.seed);
        const home = h.showOf(R).z[1]; h.PTR.zoom = h.PTR.zoomT = home;
        if (!R.__f0) R.__f0 = R.frame;
        const fn = SC[sc], ZK = ['sub', 'bass', 'mid', 'high', 'level', 'subN', 'bassN', 'midN', 'highN', 'levelN', 'kick', 'hit', 'hat'];
        let pb = null;
        R.frame = function (V, Fp, dt) {
          const d = 60 / Math.max(60, Fp.bpm || 120), b = Fp.beatClock || 0, o = fn(b, d);
          for (const k of ZK) Fp[k] = o.F[k] || 0;
          for (const k of ['kickS', 'hitS', 'hatS', 'subS', 'bassS', 'midS', 'highS', 'levelS']) Fp[k] = Fp[k.slice(0, -1)];
          Fp.silent = false; Fp.idle = 0; Fp.onDrop = false; Fp.build = 0; Fp.breakdown = 0; Fp.drop = 0;
          Fp.onSection = false; Fp.onImpact = false; Fp.impact = 0; Fp.impactS = 0; Fp.tension = 0; Fp.tensionS = 0; Fp.note = 0; Fp.noteS = 0; Fp.onNote = false;
          const p = pb == null ? b : pb; pb = b;
          Fp.onKick = sc === 'kick' && Math.floor(b) > Math.floor(p); Fp.onHit = sc === 'snare' && Math.floor((b - 1) / 2) > Math.floor((p - 1) / 2);
          const B = h.BANDS; for (let i = 0; i < 8; i++) { B.lv[i] = o.lv[i] || 0; B.on[i] = o.on[i] || 0; }
          h.PTR.zoom = h.PTR.zoomT = home;
          return R.__f0.call(this, V, Fp, dt);
        };
        const grabs = [], T0 = 8 * fps, NC = 8, STEP = 4;
        try {
          for (let n = 0; n < T0 + NC * STEP; n++) {
            const draw = n >= T0 - 3 && (n < T0 || (n - T0) % STEP === 0);
            h.offline.frame(n, fps, !draw);
            if (n >= T0 && (n - T0) % STEP === 0) {
              const w = gl.drawingBufferWidth, hh = gl.drawingBufferHeight, px = new Uint8Array(w * hh * 4);
              gl.readPixels(0, 0, w, hh, gl.RGBA, gl.UNSIGNED_BYTE, px);
              const small = new Uint8Array(Math.ceil(px.length / 16) * 3); let j = 0;
              for (let i = 0; i < px.length; i += 16) { small[j++] = px[i]; small[j++] = px[i + 1]; small[j++] = px[i + 2]; }
              grabs.push(small);
            }
          }
        } finally { R.frame = R.__f0; h.DBG.react = null; }
        if (sc === 'silence') { window.__ref = grabs; return { area: 0 }; }
        let best = 0, sum = 0;
        grabs.forEach((g, k) => {
          const r0 = window.__ref[k]; let ch = 0; const n = g.length / 3;
          for (let i = 0; i < g.length; i += 3) if (Math.max(Math.abs(g[i] - r0[i]), Math.abs(g[i + 1] - r0[i + 1]), Math.abs(g[i + 2] - r0[i + 2])) > 24) ch++;
          best = Math.max(best, ch / n); sum += ch / n;
        });
        return { area: sum / grabs.length, peak: best };
      }, { ri, sc, base, fps: FPS });
      if (sc !== 'silence') { resp.push({ sc, ...r }); ref[sc] = r; }
    }
    for (const r of resp) console.log('  ' + r.sc.padEnd(9) + (100 * r.area).toFixed(1).padStart(6) + '% mean   ' + (100 * r.peak).toFixed(1).padStart(6) + '% peak');
    const deaf = resp.filter((r) => r.peak < 0.005).map((r) => r.sc);
    if (deaf.length) warn('no visible answer to: ' + deaf.join(', ') + ' (under 0.5% of the picture changes). Bass, mids and highs should each visibly drive something.');
    else ok('every input changes the picture');
    if (errors.length) fail('page errors during the measurement: ' + errors.slice(0, 5).join(' || '));
  }

  /* ---------------- 5. contact sheet: zoom ladder, one fold, the tour */
  head('5. contact sheet');
  const ladder = await page.evaluate(async ({ ri, base, fps }) => {
    const h = window.HyperVisualizer, R = h.REALMS[ri], cv = document.getElementById('stage');
    const sh = h.showOf(R), folds = (sh.k && sh.k.s && sh.k.s.length ? sh.k.s : [6]);
    const views = [[0.15, '0', 'zoom 0.15 (wheel limit)'], [sh.z[0], '0', 'far ' + sh.z[0]], [sh.z[1], '0', 'home ' + sh.z[1]], [sh.z[2], '0', 'close ' + sh.z[2]], [2.5, '0', 'zoom 2.5 (wheel limit)'], [sh.z[1], String(folds[0]), 'home, ' + folds[0] + '-fold']];
    const out = [];
    for (const [z, sym, label] of views) {
      await h.offline.load(window.__wav, { seed: 1234567 });
      h.setAutoShow(false, true);
      Object.assign(h.S, base, { symmetry: sym, autopilot: false, cameraMode: 'hold' });
      h.goRealm(ri, 0.01, undefined, true);
      const V0 = h.D.nxt || h.D.cur; V0.seed = [.1, .3, .5, .7]; V0.c = V0.R.init(V0.seed);
      const T = 12 * fps; // in the groove section of the test track
      for (let n = 0; n <= T; n++) { h.PTR.zoom = h.PTR.zoomT = z; h.offline.frame(n, fps, n < T - 20); }
      out.push({ url: cv.toDataURL('image/jpeg', 0.86), label });
    }
    return out;
  }, { ri, base, fps: FPS });
  const cells = [...ladder, ...tour.slice(0, 8)];
  const sheet = await browser.newPage({ viewport: { width: 4 * (W + 8) + 8, height: 100 }, deviceScaleFactor: 1 });
  const title = st.name + ' (' + key + ')   ' + new Date().toISOString().slice(0, 10) + '   row 1-2: zoom ladder and a fold at t = 12 s; rest: Auto Show tour over the test track';
  await sheet.setContent('<html><body style="margin:0;background:#111;color:#ddd;font:12px sans-serif"><div style="padding:6px 8px">' + title.replace(/[<&]/g, '') + '</div><div style="display:grid;grid-template-columns:repeat(4,' + W + 'px);gap:8px;padding:0 8px 8px">' +
    cells.map((c) => '<div><img src="' + c.url + '" width="' + W + '" height="' + H + '" style="display:block"><div style="padding:2px 0 4px">' + c.label.replace(/[<&]/g, '') + '</div></div>').join('') + '</div></body></html>');
  const sheetPath = path.join(outDir, 'sheet.jpg');
  await sheet.screenshot({ path: sheetPath, type: 'jpeg', quality: 88, fullPage: true });
  await sheet.close();
  if (ladder[2]) fs.writeFileSync(path.join(outDir, 'thumb.jpg'), Buffer.from(ladder[2].url.split(',')[1], 'base64'));
  ok('wrote ' + path.relative(process.cwd(), sheetPath) + ' and thumb.jpg (the home framing): LOOK at them, a number is never proof');
  if (errors.length && !fails.some((f) => f.startsWith('page errors'))) fail('page errors: ' + errors.slice(0, 5).join(' || '));

  fs.writeFileSync(path.join(outDir, 'report.json'), JSON.stringify({ key, name: st.name, renderer: st.renderer, compile: st.timing, health: { frames, worstBlackRun: worst, luma: mean('luma'), lit: mean('lit'), ink: mean('ink'), pale: mean('pale'), cues: health.cues }, response: resp, fails, warns }, null, 2));
} catch (e) {
  if (e.message !== 'stop') { fail('the check itself broke: ' + String(e.stack || e.message).split('\n').slice(0, 3).join(' | ')); }
} finally {
  await browser.close();
}
console.log('\ncheck-scene: ' + (fails.length ? 'FAILED (' + fails.length + ')' : 'PASSED') + (warns.length ? ', ' + warns.length + ' warning' + (warns.length > 1 ? 's' : '') : '') + '  [' + key + ']');
process.exit(fails.length ? 1 : exitCode);
