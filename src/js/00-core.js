(() => {
'use strict';
/* =====================================================================
   HYPER VISUALIZER — raw WebGL2, no dependencies.
   Pipeline per frame: realm shader(s) -> feedback/compose -> bloom chain -> composite.
   ===================================================================== */
const $ = (s) => document.querySelector(s);
// v21: the support link (a small coffee cup) and the source link (a small GitHub mark), in the controls footer and on the
// enter screen. While a constant is empty its icon is not rendered at all. Only https addresses are accepted.
const SUPPORT_URL = '', REPO_URL = '';
const clamp = (x, a, b) => (x < a ? a : x > b ? b : x);
const lerp = (a, b, t) => a + (b - a) * t;
const ease = (cur, tgt, dt, tau) => cur + (tgt - cur) * (1 - Math.exp(-dt / Math.max(tau, 1e-4)));
const fract = (x) => x - Math.floor(x);
const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX', 'XXI', 'XXII', 'XXIII', 'XXIV'];
let rand = Math.random; // swapped for a seeded generator in offline renders
// wall clock in seconds, or the virtual clock of an offline (frame-by-frame) render
const OFF = { on: false, clock: 0, tick: 0 };
const nowS = () => (OFF.on ? OFF.clock : performance.now() / 1000);
const pick = (arr) => arr[Math.floor(rand() * arr.length)];

let inShell = false;
try { inShell = window.self !== window.top && !!window.parent.location.href; } catch (e) { inShell = false; }
if (inShell) document.body.classList.add('shell-context');
// Psychonautica hub contract: ?clean=1 / ?hideUI=1, or a {type:'sp-toggle-clean-mode'} message, asks for an immersive, chrome-light view.
const qs = new URLSearchParams(location.search || '');
function setClean(on) { document.body.classList.toggle('clean-embed-mode', !!on); }
setClean(qs.get('clean') === '1' || qs.get('hideUI') === '1');
window.addEventListener('message', (ev) => { const d = ev && ev.data; if (d && typeof d === 'object' && d.type === 'sp-toggle-clean-mode') setClean(d.enabled !== false); });
const reduceMotion = !!(window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches);
// MOBILE: phones and tablets (a coarse primary pointer on a touch screen, or a mobile user agent with touch).
// Gates the phone defaults: lazy realm preparation, lower start resolution, DPR cap, touch gestures, bigger controls.
// ?mobile=1 / ?mobile=0 force it either way (testing).
const MOBILE = (() => {
  const f = qs.get('mobile'); if (f === '1' || f === '0') return f === '1';
  try {
    const touch = (navigator.maxTouchPoints || 0) > 0, coarse = !!(window.matchMedia && matchMedia('(pointer: coarse)').matches);
    return touch && (coarse || /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent || ''));
  } catch (e) { return false; }
})();
const MOBILE_DPR = 1.5, MOBILE_AHEAD = 1, MOBILE_KEEP = 6, MOBILE_PIX = 1.6e6, MOBILE_PIX_SS = 4e6, MOBILE_START_BUDGET = 0.3;
if (MOBILE) {
  document.body.classList.add('mobile');
  // iOS Safari ignores user-scalable=no: stop page pinch-zoom so a pinch always reaches the visualizer
  ['gesturestart', 'gesturechange'].forEach((ev) => document.addEventListener(ev, (e) => e.preventDefault(), { passive: false }));
}

/* ------------------------------ settings ------------------------------ */
const STORE_KEY = 'hyperVisualizer.v10';
const DEFAULTS = {
  dose: 1, reactivity: 1, speed: 1, trails: 0.6, warp: 0.55, symmetry: 'auto', palette: 'auto',
  colorSpeed: 0.6, bloom: 0.8, chroma: 0.5, flashes: 0.8, quality: 'auto', autopilot: true,
  switchBars: 32, journeyMinutes: 0, sceneDuration: 90, cameraMode: 'tour', motionSmooth: 0.75, hud: false, volume: 0.9, detail: 1, ptrSens: 0.35, transition: 'auto', transTime: 1,
  // ENGINE v10: Auto Show (on for new visitors), the settings the person took over from it, how much kaleidoscope it
  // uses, colour saturation, favourite realms and whether autopilot plays only them.
  autoShow: true, autoManual: [], autoKal: 'subtle', saturation: 1, favs: [], favMode: 'all', vibe: 'trip', perf: 'balanced',
  plShuffle: false, plRepeat: 'all', kalV21: true // v21: music queue order; kalV21 marks settings saved since Auto folds became a visible control
};
function readStore() { try { const raw = localStorage.getItem(STORE_KEY); return raw ? JSON.parse(raw) : null; } catch (e) { return null; } }
const stored = readStore();
const S = Object.assign({}, DEFAULTS, (reduceMotion && !stored) ? { flashes: 0.12, speed: 0.6, chroma: 0.2, dose: 0.75, autoManual: ['flashes', 'chroma'] } : {}, stored || {});
S.autoManual = Array.isArray(S.autoManual) ? S.autoManual.filter((k) => typeof k === 'string') : [];
S.favs = Array.isArray(S.favs) ? S.favs.filter((k) => typeof k === 'string') : [];
// v21: Auto folds is the person's own amount control now (Off / Some / Lots). Settings saved by earlier versions carried a
// value nobody had chosen, so they start again at Some.
if (stored && stored.kalV21 === undefined) S.autoKal = 'subtle';
S.kalV21 = true;
S.autoShow = S.autoShow !== false; S.autoKal = ['off', 'subtle', 'lots'].includes(S.autoKal) ? S.autoKal : 'subtle';
S.plShuffle = !!S.plShuffle; S.plRepeat = ['all', 'one', 'off'].includes(S.plRepeat) ? S.plRepeat : 'all';
S.saturation = Number.isFinite(Number(S.saturation)) ? clamp(Number(S.saturation), 0, 2) : 1;
S.favMode = S.favMode === 'favs' ? 'favs' : 'all';
S.detail = Number.isFinite(Number(S.detail)) ? clamp(Number(S.detail), 0.5, 16) : 1;
S.journeyMinutes = [0,60,120].includes(Number(S.journeyMinutes)) ? Number(S.journeyMinutes) : 60;
// v16 migration: duration is per scene; retain an old quick-tour bar choice explicitly.
S.sceneDuration = stored && stored.sceneDuration == null ? (Number(stored.journeyMinutes)===0?'bars':90) : S.sceneDuration;
if(!['bars',0,30,60,90,120,180,300].includes(S.sceneDuration))S.sceneDuration='bars'===S.sceneDuration?'bars':([0,30,60,90,120,180,300].includes(Number(S.sceneDuration))?Number(S.sceneDuration):90);
S.cameraMode = S.cameraMode==='hold'?'hold':'tour';
S.switchBars=[8,16,32,64].includes(Number(S.switchBars))?Number(S.switchBars):32;
S.motionSmooth = Number.isFinite(Number(S.motionSmooth)) ? clamp(Number(S.motionSmooth),0,1) : 0.75;
// Never resume an expensive recording profile merely by opening the page.
const previousRenderSettings = { quality: S.quality, detail: S.detail };
const hadHeavySettings = !['auto','low','medium','high'].includes(S.quality) || S.detail > 1;
if (hadHeavySettings) { S.quality = 'auto'; S.detail = 1; }
let saveT = 0;
let renderSettingsChosen = false;
function saveSettings() { clearTimeout(saveT); saveT = setTimeout(() => { try { const saved={...S};if(hadHeavySettings&&!renderSettingsChosen)Object.assign(saved,previousRenderSettings);localStorage.setItem(STORE_KEY, JSON.stringify(saved)); } catch (e) { /* storage blocked */ } }, 250); }
/* ENGINE v10: E = the effective settings the engine renders with. For the AUTO_KEYS below it is the Auto Show's own
   choice for the realm on screen while Auto Show is on and the person has not taken that setting over (S.autoManual);
   otherwise the person's setting in S. Every other key reads S directly. autoUpdate() refreshes E once per frame.
   Realms keep reading S (S.dose, S.speed, S.motionSmooth ...): Auto Show never changes those. */
const AUTO_KEYS = [ 'transition', 'transTime', 'trails', 'warp', 'bloom', 'chroma', 'flashes', 'colorSpeed', 'palette', 'symmetry', 'quality', 'detail'];
const E = {autopilot: S.autoShow, switchBars: S.switchBars};
AUTO_KEYS.forEach((k) => { E[k] = S[k]; });

/* ------------------- ENGINE v24: scene set and playlist (state) ------------------- */
// Which scenes play, in what order, for how long. Kept apart from S (its own storage key) and by scene KEY, so a scene
// added later is simply on. off: keys switched off. mode: 'shuffle' (the Auto Show's own running order over the scenes
// that are on) or 'sequence' (exactly `order`, looping). order: keys in list order (scenes it does not name follow in
// built-in order). secs: per-scene length in seconds (sequence mode). A link (?scenes=a,b&mode=sequence&secs=30)
// replaces it for this visit and is never saved (SCN.link; SCN.only = the link's scene set).
// With nothing changed (all on, shuffle, no link) every engine path is exactly the one before v24.
const SCN_KEY = 'hyperVisualizer.scenes.v1', SCN_KEY_RE = /^[a-z][a-z0-9]{1,23}$/;
const SCN = { off: new Set(), only: null, mode: 'shuffle', order: [], secs: {}, link: false, linkSecs: 0, rev: 0, ord: null, ordRev: -1, ordN: -1,
  ui: null, verify: [], waits: new Map(), added: new Map(), broken: [], restored: null };
function scnSecsOk(v) { v = Math.round(Number(v)); return v >= 5 && v <= 3600 ? v : 0; }
function scnKeys(a) { return [...new Set((Array.isArray(a) ? a : []).filter((k) => typeof k === 'string' && SCN_KEY_RE.test(k)))]; }
function scnSet(o) {
  o = o && typeof o === 'object' ? o : {};
  SCN.order = scnKeys(o.order); SCN.off = new Set(scnKeys(o.off)); SCN.only = null; SCN.mode = o.mode === 'sequence' ? 'sequence' : 'shuffle';
  SCN.secs = {};
  if (o.secs && typeof o.secs === 'object') for (const k of Object.keys(o.secs)) { const v = scnSecsOk(o.secs[k]); if (v && SCN_KEY_RE.test(k)) SCN.secs[k] = v; }
  SCN.rev++;
}
try { scnSet(JSON.parse(localStorage.getItem(SCN_KEY) || 'null')); } catch (e) { /* storage blocked or damaged: the defaults */ }
{ // a link's playlist: this visit only
  const sc = scnKeys(String(qs.get('scenes') || '').toLowerCase().split(',').map((k) => k.trim())), md = qs.get('mode'), sx = scnSecsOk(qs.get('secs'));
  if (sc.length || md === 'sequence' || md === 'shuffle' || sx) {
    SCN.link = true; SCN.linkSecs = sx;
    if (sc.length) { SCN.only = new Set(sc); SCN.order = sc; SCN.off = new Set(); SCN.secs = {}; SCN.mode = 'shuffle'; }
    if (md === 'sequence' || md === 'shuffle') SCN.mode = md;
    SCN.rev++;
  }
}

/* ------------------------------ palettes ------------------------------ */
// Cosine palettes: color(t) = a + b * cos(2pi * (c*t + d))
const PALETTES = [
  { name: 'Prism',        a: [.5, .5, .5],    b: [.5, .5, .5],    c: [1, 1, 1],     d: [0, .33, .67] },
  { name: 'Orchid Neon',  a: [.55, .35, .62], b: [.45, .38, .38], c: [1, 1, 1],     d: [.85, .15, .45] },
  { name: 'Elf Gold',     a: [.58, .42, .36], b: [.45, .38, .45], c: [1, 1, .8],    d: [.08, .2, .55] },
  { name: 'Abyssal Jade', a: [.32, .5, .5],   b: [.35, .45, .4],  c: [1, 1, 1],     d: [.55, .25, .15] },
  { name: 'Solar Fever',  a: [.5, .5, .5],    b: [.5, .5, .5],    c: [1, .7, .4],   d: [0, .25, .45] },
  { name: 'Ultraviolet',  a: [.45, .3, .68],  b: [.45, .35, .35], c: [1, 1, 1],     d: [.7, .35, .1] },
  { name: 'Acid Bloom',   a: [.5, .5, .5],    b: [.5, .5, .5],    c: [1, 1, .5],    d: [.8, .9, .3] },
  { name: 'Infrared',     a: [.6, .3, .36],   b: [.45, .35, .4],  c: [1, .8, 1],    d: [0, .1, .35] },
  { name: 'Ice Mandala',  a: [.35, .45, .7],  b: [.4, .45, .3],   c: [1, 1, 1],     d: [.5, .7, .95] },
  { name: 'Sunset Rite',  a: [.5, .5, .5],    b: [.5, .5, .5],    c: [2, 1, 0],     d: [.5, .2, .25] }
];

