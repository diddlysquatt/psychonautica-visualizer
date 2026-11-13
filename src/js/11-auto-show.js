/* ============================== AUTO SHOW ============================== */
/* ENGINE v10. One switch (S.autoShow, on for new visitors) that runs the whole show: which realm comes next and in
   what order, how long each one stays, how it arrives (transition style and time), colour flow, trails, liquid warp,
   glow, prism, flash and the kaleidoscope, plus adaptive resolution and detail. It never touches Energy (dose), Speed,
   Motion smoothness, Audio sensitivity, Pointer influence, Saturation or volume.
   - Per realm it reads R.auto when the realm provides it:
       auto: { kal: [folds best first, 0 = unfolded], kalCycle: bool, kalZoom: number, transitions: ['portal', ...],
               bars: phrase length, tier: 1 (show-stopper) .. 3, kind: 'flat' | '3d' | 'tunnel', fx: { trails, warp, ... } }
     otherwise the engine's own profile below (AUTO_REALM), otherwise it derives one from syms / fb.live.
   - kalCycle realms go through 2-4 different folds within one visit, changing on phrase lines and drops with the
     radial fold wipe in the compose pass (uSymA0 / uSymT), at most once per KAL_MIN_BARS (16) bars and never the same
     fold twice in a row; other realms get one fold per visit (re-picked on drops). Only folds in the realm's kal list
     are used (v12), unfolded (0) too when listed.
   - Any change the person makes to an Auto setting (slider, select, key, touch, API) takes that one setting out of
     Auto (S.autoManual, persisted); its row shows "manual" with a button that gives it back. */
const AUTO_FX = {
  tunnel: { trails: 0.6, warp: 0.55, bloom: 0.8, chroma: 0.5, flashes: 0.8, colorSpeed: 0.6 },
  '3d': { trails: 0.62, warp: 0.5, bloom: 0.86, chroma: 0.45, flashes: 0.8, colorSpeed: 0.6 },
  flat: { trails: 0.48, warp: 0.32, bloom: 0.78, chroma: 0.32, flashes: 0.75, colorSpeed: 0.7 }
};
// tier: 1 show-stopper (stays longer, comes round more evenly), 2 strong, 3 lighter. kal: folds best first.
const AUTO_REALM = {
  gate: /*@scene auto gate*/,
  lattice: /*@scene auto lattice*/,
  cathedral: /*@scene auto cathedral*/,
  foam: /*@scene auto foam*/,
  mandala: /*@scene auto mandala*/,
  void9: /*@scene auto void9*/,
  merc: /*@scene auto merc*/,
  klnn: /*@scene auto klnn*/,
  boxx: /*@scene auto boxx*/,
  kubik: /*@scene auto kubik*/,
  tess: /*@scene auto tess*/,
  swarm: /*@scene auto swarm*/,
  chroma: /*@scene auto chroma*/,
  flux: /*@scene auto flux*/,
  knott: /*@scene auto knott*/,
  sol: /*@scene auto sol*/,
  spiro: /*@scene auto spiro*/,
  velvet: /*@scene auto velvet*/,
  optik: /*@scene auto optik*/,
  hypr: /*@scene auto hypr*/,
  cyma: /*@scene auto cyma*/,
  abyss: /*@scene auto abyss*/,
  marbl: /*@scene auto marbl*/,
  eschr: /*@scene auto eschr*/
};
const AUTO_TIER_HOLD = { 1: 1.35, 2: 1, 3: 0.7 };
const VIBE_FX = { drift:{fx:.55,bars:1}, chill:{fx:.8,bars:1}, trip:{fx:1,bars:1}, vivid:{fx:1.2,bars:1}, insane:{fx:1.45,bars:1} };
const AUTO = { manual: new Set(S.autoManual.filter(k=>AUTO_KEYS.includes(k))), seen: {}, fx: null, listeners: [] };
AUTO_KEYS.forEach((k) => { AUTO.seen[k] = S[k]; });
// first load of this version over older saved settings: whatever the person had changed from the defaults stays theirs
if (stored && stored.autoShow === undefined) AUTO_KEYS.forEach((k) => { if (k in stored && String(stored[k]) !== String(DEFAULTS[k])) AUTO.manual.add(k); });
S.autoManual = [...AUTO.manual];
function autoActive(k) { return !!S.autoShow && !AUTO.manual.has(k); }
function setAutoManual(k, on) {
  if (on) AUTO.manual.add(k); else { AUTO.manual.delete(k); AUTO.seen[k] = S[k]; }
  S.autoManual = [...AUTO.manual]; saveSettings(); AUTO.listeners.forEach((f) => f(k));
}
function setAutoShow(on, quiet) {
  S.autoShow = !!on;
  if(!on){AUTOZ.dur=0;AUTOZ.q.length=0;AUTOZ.armed=null;AUTOZ.kind='';PTR.zoomT=PTR.zoom;ZOOMS.v=0;}
  // switching it on hands everything back to Auto, except a flash level the person turned down for comfort
  if (on) { AUTO.manual.clear(); if (Number(S.flashes) < 0.3) AUTO.manual.add('flashes'); AUTO_KEYS.forEach((k) => { AUTO.seen[k] = S[k]; }); S.autoManual = [...AUTO.manual]; }
  saveSettings(); AUTO.listeners.forEach((f) => f(null));
  if (on && D.cur && !D.nxt) D.cur.kal = autoKalPlan(D.cur);
  if (!quiet) toast(on ? 'Auto Show on' : 'Auto Show off: your own settings');
}
// a realm's show profile: R.auto, else AUTO_REALM, else derived from syms and fb.live
function autoProfile(R) {
  if (R._ap && R._ap.src === R.auto && R._ap.fav === S.favs.includes(R.key)) return R._ap;
  const a = R.auto && typeof R.auto === 'object' ? R.auto : {}, base = AUTO_REALM[R.key] || {};
  const live = R.fb ? (R.fb.live ?? REALM_LIVE[R.key] ?? 1) : 1;
  const kind = ['flat', '3d', 'tunnel'].includes(a.kind) ? a.kind : base.kind || (live <= 0.3 ? 'flat' : '3d');
  const okFold = (n) => [0, 1, 2, 3, 4, 5, 6, 8, 12, 16].includes(n);
  let kal = SHOW[R.key] ? [0].concat(SHOW[R.key].k.s, SHOW[R.key].k.o).filter((n) => n !== 1) : (Array.isArray(a.kal) && a.kal.length ? a.kal : base.kal || null); // v21: the engine's table first
  if (!kal) { // derive: the realm's syms, most frequent first
    const cnt = new Map(); (R.syms || [0]).forEach((n, i) => { n = Number(n) || 0; if (!cnt.has(n)) cnt.set(n, [0, i]); cnt.get(n)[0]++; });
    kal = [...cnt.entries()].sort((x, y) => y[1][0] - x[1][0] || x[1][1] - y[1][1]).map((e) => e[0]);
  }
  kal = kal.map((n) => Number(n) || 0).filter(okFold); if (!kal.length) kal = [0];
  const tr = (Array.isArray(a.transitions) ? a.transitions : base.tr || []).map((n) => TRANS.findIndex((t) => t[0] === n || t[1].toLowerCase() === String(n).toLowerCase())).filter((i) => i >= 0 && i !== 7 && !TRANS_AUTO_OFF.includes(i));
  const fav = S.favs.includes(R.key), tier = fav ? 1 : [1, 2, 3].includes(a.tier) ? a.tier : base.tier || 2;
  const bars = clamp(Number(a.bars) || base.bars || 32, 8, 64);
  const kz = Number.isFinite(Number(a.kalZoom)) && Number(a.kalZoom) > 0 ? Number(a.kalZoom) : (R.kalZoom ?? 0.7);
  return (R._ap = { src: R.auto, fav, tier, kind, kal, kalCycle: a.kalCycle !== undefined ? !!a.kalCycle : !!base.kalCycle, kalZoom: kz, tr, bars,
    fx: Object.assign({}, AUTO_FX[kind], base.fx || {}, a.fx && typeof a.fx === 'object' ? a.fx : {}) });
}
function autoHoldWeight(ri) {
  let sum = 0, n = 0; REALMS.forEach((R) => { if (!R.failed) { sum += AUTO_TIER_HOLD[autoProfile(R).tier]; n++; } });
  const R = REALMS[ri]; return R && sum > 0 ? AUTO_TIER_HOLD[autoProfile(R).tier] * n / sum : 1;
}
/* v21 SHOW: the Auto Show's framing and kaleidoscope rules per scene, decided by looking at every scene
   (work/engine21/zoom/<key>.jpg, work/engine21/kal/<key>.jpg; reasons in work/engine21/NOTES-V21.md). This table takes
   precedence over a realm's own R.auto.kal / R.auto.zoom / kalZoom hints, which only serve scenes it does not know.
   HOW TO FILL A ROW (key: { z, c, w, k, no, hold }), all fields optional except z:
   z: [far, home, close] as effective zoom (what the scene shader gets as uZoom; 1 = the scene's own default, smaller = wider).
      home: the wide framing the show lives at and every visit arrives at (shown whole for 12 to 21 s first). Pick the zoom where
      the whole scene reads, with a little to spare: the owner's rule is "never too close for too long, always show the full scene".
      far: the widest view worth a visit (beyond it the scene repeats, thins or turns to speckle); visits go 45 to 100% of the way.
      close: the closest framing worth a SHORT visit (held 4 or 8 beats, then back home); visits go 50 to 100% of the way.
      far = home = close: the engine never moves the camera (the scene flies itself).
   c: appetite for close-ups, 0 (never) to 1 (at most one every 26 s).   w: appetite for the far view, 0 to 1.
   k: the kaleidoscope (FOLD ROW). p = share of visits that fold at all (at "Auto folds: Some"; 0 = never), s = superb folds
      (weights 4, 3, 2 in table order: the first is the likeliest), o = acceptable folds (weight 1 each; "rarely"), a fold in
      neither list is banned. Folds: 1 the plain left-right mirror, 2 the four-way mirror ("Mirror" in the menu), 3 .. 16 the
      kaleidoscope counts. z = framing of the folded picture as a multiple of home (1.3 = 30% closer while folded),
      cyc = a folded visit may glide on into a second fold (at Lots), ok(V, fold) = optional test: false keeps that fold out now.
   no: transition styles (indices into TRANS) Auto never uses with this scene at either end; the dissolve takes their place.
   hold(V): optional test, true while the scene asks the director to wait: no fold change and no new zoom move starts (a move
      already under way finishes; drops wait too). V.c is the scene's own state from R.init.
   A scene with no row here (a new scene, a community pack) gets SHOW_DEFAULT below (home .6, far .35, close 1), or its own
   R.auto.zoom = [far, close] range, and its own R.auto.kal / syms as folds in 40% of visits (6, 8, 12 first when it lists them;
   3 and 4 only as "rarely"). One row per scene: edit freely. */
const SHOW = {
  gate: /*@scene show gate*/, // v21 rebuild: one endless flower from .15 up
  lattice: /*@scene show lattice*/, // far = home = close: no engine zoom moves at all (the scene flies itself)
  cathedral: /*@scene show cathedral*/,
  foam: /*@scene show foam*/,
  mandala: /*@scene show mandala*/,
  void9: /*@scene show void9*/,
  merc: /*@scene show merc*/,
  klnn: /*@scene show klnn*/,
  boxx: /*@scene show boxx*/, // v22: pulled back = a city of boxes to the horizon
  kubik: /*@scene show kubik*/,
  tess: /*@scene show tess*/,
  swarm: /*@scene show swarm*/, // v21 rebuild: low camera over a sea, unfolded most of the time; mirrors and 16 banned
  chroma: /*@scene show chroma*/,
  flux: /*@scene show flux*/,
  knott: /*@scene show knott*/,
  sol: /*@scene show sol*/,
  spiro: /*@scene show spiro*/,
  velvet: /*@scene show velvet*/, // v22 w4: far = the whole cloth, home = 5 to 8 bands with a figure or two, close = thread and embroidery
  optik: /*@scene show optik*/,
  hypr: /*@scene show hypr*/,
  cyma: /*@scene show cyma*/, // v22 w4: far = the whole board with all eight rings, home = sanctum and four rings, close = the sanctum's relief and insignia
  abyss: /*@scene show abyss*/, // waits while a dive is in flight
  marbl: /*@scene show marbl*/, // the mirror only during a gallery walk; nothing starts in a walk's first 10 s or while it lands
  eschr: /*@scene show eschr*/, // v22: lead kept far .22 (the endless city) and home .42; short close visits up to 1.5 (eschr agent)
  umi: /*@scene show umi*/,
  hoshi: /*@scene show hoshi*/,
  kami: /*@scene show kami*/,
  petri: /*@scene show petri*/,
  tykes: /*@scene show tykes*/, // v22 w3: the scene runs its own journey through its layers; the engine waits while a leg or a rug-pull runs
  scribe: /*@scene show scribe*/ // v22 w3: far = the great book in its rings of books, home = the whole opening at an angle, close = low over the writing
};
// before v21: the tour range and home of a scene, still the fallback for scenes SHOW does not know (community packs)
const AUTO_ZOOM = { }, REALM_HOME = { };
// v22: what a scene with no SHOW row gets (wider than the old .72 home: the owner's standing note is "too close")
const SHOW_DEFAULT = { far: .35, home: .6, close: 1, c: .35, w: .55, p: .4 };
function showOf(R) {
  if (R._show) return R._show;
  const t = SHOW[R.key] || {}, a = R.auto && typeof R.auto === 'object' ? R.auto : {};
  let z = t.z;
  const SD = SHOW_DEFAULT;
  if (!z) { const az = Array.isArray(a.zoom) ? a.zoom : AUTO_ZOOM[R.key] || [SD.far, SD.close], home = REALM_HOME[R.key] || SD.home; z = [clamp(Number(az[0]) || SD.far, ZOOM_MIN, home), home, clamp(Number(az[1]) || SD.close, home, ZOOM_MAX)]; }
  let k = t.k;
  if (!k) { // unknown scene: its own hints; 6, 8, 12 (the folds that work in most scenes) first, 3 and 4 (lopsided) only as acceptable
    const u = [...new Set((Array.isArray(a.kal) ? a.kal : R.syms || []).map(Number).filter((n) => [2, 3, 4, 5, 6, 8, 12, 16].includes(n)))];
    const good = u.filter((n) => [6, 8, 12].includes(n)), s = good.length ? good.slice(0, 3) : u.filter((n) => n > 4).slice(0, 2);
    k = { p: u.length ? SD.p : 0, s, o: u.filter((n) => !s.includes(n)), z: clamp(lerp(R.kalZoom ?? .7, 1, .35), .5, 1) };
  }
  return (R._show = { z, c: t.c ?? (t.z ? .4 : SD.c), w: t.w ?? (t.z ? .5 : SD.w), k, hold: typeof t.hold === 'function' ? t.hold : null });
}
/* v21 kaleidoscope director. The rules: every visit opens unfolded and stays unfolded for a good stretch (14 to 30 s, then
   the next musical moment); a visit folds
   rarely, only into folds SHOW lists for its scene and mostly into the superb ones; a change happens on a musical
   moment (a drop, an 8-bar phrase line, a clear lift in energy; a plain bar line only once the latest time has passed;
   plain time when there is no beat to follow); the change itself is a slow morph in the compose pass (foldUpdate), never
   a cut or a wipe. "Auto folds" (S.autoKal) is the amount: Off never folds; Some folds in the scene's share of visits,
   about once per 90 seconds; Lots folds in most visits, a little sooner, and may glide from one fold into another.
   The plan draws from its own generator seeded by the visit, so the engine's rand() sequence is unchanged. */
const KAL_MIN_BARS = 16; // (older tools read it) fold changes are never closer together than this
function autoKalHold(V) { return E.autopilot ? realmHoldSeconds(V) : Infinity; } // ENGINE v24: V = the visit asked about (default: the one on screen)
function autoKalPlan(V) {
  const sh = showOf(V.R).k, mode = S.autoKal, r = mulberry(((V.seed[0] * 4294967296) >>> 0) ^ 0x2545f491), lots = mode === 'lots';
  const p = mode === 'off' || !(sh.s.length + sh.o.length) ? 0 : lots ? Math.min(1, sh.p * 1.35 + 0.12) : sh.p;
  const hold = Math.min(autoKalHold(V), 600), short = hold < 50;
  const k = { seq: [0], i: 0, bars: 0, r, fold: 0, phase: 'open', t: 0, on: r() < p && hold >= 24, n: 0, chain: 0, last: 0, lots, e1: 0, e2: 0, lifted: false, cue: 0, minT: 0, maxT: 0 };
  k.minT = Math.min((lots ? 12 : 14) + r() * 16, Math.max(8, hold * 0.3)); k.maxT = k.minT + (short ? 6 : 10 + r() * 8);
  return k;
}
function autoKalPick(V, k) {
  const sh = showOf(V.R).k, w = new Map();
  sh.s.forEach((n, i) => w.set(n, i === 0 ? 4 : i === 1 ? 3 : 2)); sh.o.forEach((n) => { if (!w.has(n)) w.set(n, 1); }); // superb folds weigh 4, 3, 2 in table order; acceptable ones 1
  w.delete(k.last); if (k.fold) w.delete(k.fold);
  if (sh.ok) for (const n of [...w.keys()]) if (!sh.ok(V, n)) w.delete(n); // v22: a fold the scene keeps out at this moment
  if (!w.size) return k.last || sh.s[0] || sh.o[0] || 0;
  if (w.size > 1 && w.has(V.R._kalLast)) w.set(V.R._kalLast, w.get(V.R._kalLast) * 0.3); // the next visit to this scene prefers a different fold
  let x = k.r() * [...w.values()].reduce((a, v) => a + v, 0);
  for (const [n, v] of w) { x -= v; if (x <= 0) return n; }
  return [...w.keys()][0];
}
// fold 1 (the plain mirror) is only ever drawn by the compose pass: k.seq, effectiveSym and so every realm's own code see 0
function autoKalSet(V, k, f) { k.last = k.fold || k.last; k.fold = f; k.seq = [f === 1 ? 0 : f]; k.i = 0; k.t = 0; k.bars = 0; if (f) V.R._kalLast = f; }
// per frame, for the scene on screen
function autoKalTick(V, dt) {
  const k = V && V.kal; if (!k || k.fold === undefined) return;
  k.t += dt; if (F.onBar) k.bars++;
  k.e1 = ease(k.e1, F.level, dt, 1.5); k.e2 = ease(k.e2, F.level, dt, 12);
  const up = k.e1 > k.e2 * 1.3 + 0.04, lift = up && !k.lifted; k.lifted = up;
  const strong = F.onDrop || k.cue > 0; k.cue = 0;
  if (E.symmetry !== 'auto' || S.autoKal === 'off') { if (k.fold) autoKalSet(V, k, 0); k.phase = 'open'; k.on = false; return; }
  if (!k.on && !k.fold) return;
  if (k.t < k.minT) return;
  const tempo = F.conf > 0.35 && F.bpm > 40 && !F.silent;
  const phrase = F.onBar && tempo && (F.barIndex - D.phraseBase) % 8 === 0;
  const late = k.t >= k.maxT && (tempo ? F.onBar || k.t >= k.maxT + 4 : true);
  if (!(strong || phrase || lift || late)) return;
  if (showOf(V.R).hold && showOf(V.R).hold(V)) return; // v22: the scene asks to wait (e.g. MARBL's walk)
  // ENGINE v24: a fold never starts before or in the middle of the visit's grand zoom tour (autoZoomUpdate)
  if (!k.fold && V === D.cur && AUTOZ.key === V.R && (AUTOZ.tourWait || AUTOZ.kind === 'tour' || (AUTOZ.armed && AUTOZ.armed.kind === 'tour') || TIME < AUTOZ.tourEnd)) return;
  const left = autoKalHold() - (V === D.cur ? D.realmTime : 0), r = k.r, sh = showOf(V.R).k;
  if (k.fold && left < 34) return; // not enough of the visit left for a second good look at the full scene: stay folded into the transition
  if (!k.fold) { // unfolded: fold now, unless the scene is about to change
    if (left < Math.min(20, autoKalHold() * 0.4)) { k.on = false; return; }
    autoKalSet(V, k, autoKalPick(V, k)); k.phase = 'fold'; k.n++; k.chain = 0;
    k.minT = Math.min((k.lots ? 18 : 22) + r() * 10, Math.max(10, left * 0.45)); k.maxT = k.minT + 12 + r() * 8;
  } else if (k.lots && sh.cyc && k.chain < 1 && left > 26 && sh.s.length + sh.o.length > 1 && r() < 0.55) { // glide on into a second fold
    autoKalSet(V, k, autoKalPick(V, k)); k.chain++;
    k.minT = 18 + r() * 10; k.maxT = k.minT + 12 + r() * 8;
  } else { // back to the full scene
    autoKalSet(V, k, 0); k.phase = 'rest';
    k.on = left > (k.lots ? 45 : 75); // long visits (or "stay on this scene") fold again later
    k.minT = (k.lots ? 20 : 30) + r() * (k.lots ? 14 : 20); k.maxT = k.minT + 14 + r() * 8;
  }
}
// (name kept: triggerDrop calls it) a drop is the strongest cue for the next fold change of the visit
function autoKalAdvance(V, why) { const k = V && V.kal; if (k && why === 'drop') k.cue = 1; return false; }
// how far a folded scene sits from its unfolded framing (a multiple of it)
function autoKalZoom(V) {
  if (E.symmetry !== 'auto') return V.R.kalZoom ?? 0.7;
  const sh = showOf(V.R); return clamp(sh.k.z ?? 0.9, sh.z[0] / sh.z[1], 1.6);
}
// Running order: tier-1 realms (and favourites) spread evenly through the cycle, never two of the same kind in a row
// when it can be helped. A permutation of the shuffled bag, decided by journeyRand only: still deterministic.
function autoOrderBag() {
  const order = D.bag.slice().reverse(), tiers = { 1: [], 2: [], 3: [] }, out = [], taken = { 1: 0, 2: 0, 3: 0 };
  order.forEach((ri) => tiers[autoProfile(REALMS[ri]).tier].push(ri));
  const n = order.length;
  for (let pos = 0; pos < n; pos++) {
    let best = 0, bestScore = -Infinity;
    for (const t of [1, 2, 3]) { if (!tiers[t].length) continue; const score = (tiers[t].length + taken[t]) / n * (pos + 1) - taken[t] + (t === 1 && pos === 0 ? 9 : 0) - t * 1e-3; if (score > bestScore) { bestScore = score; best = t; } }
    const list = tiers[best], prev = out.length ? autoProfile(REALMS[out[out.length - 1]]).kind : '';
    let j = list.findIndex((ri) => autoProfile(REALMS[ri]).kind !== prev); if (j < 0) j = 0;
    out.push(list.splice(j, 1)[0]); taken[best]++;
  }
  D.bag = out.reverse();
}
function favouriteFilterBag() {
  if (S.favMode !== 'favs') return;
  const favs = D.bag.filter((ri) => S.favs.includes(REALMS[ri].key) && !REALMS[ri].failed);
  if (favs.length >= 2) D.bag = favs;
}
// per-frame: notice the person's changes, ease the effect targets of the realm(s) on screen, publish E
function autoUpdate(dt) {
  for (const k of AUTO_KEYS) if (String(S[k]) !== String(AUTO.seen[k])) { AUTO.seen[k] = S[k]; if (S.autoShow && !AUTO.manual.has(k)) setAutoManual(k, true); }
  const A = D.cur, B = D.nxt, vibe = VIBE_FX[S.vibe] || VIBE_FX.trip;
  if (A) {
    const pa = autoProfile(A.R), pb = B ? autoProfile(B.R) : pa, mx = B ? D.mix * D.mix * (3 - 2 * D.mix) : 0;
    if (!AUTO.fx) AUTO.fx = Object.assign({}, pa.fx);
    for (const k of ['trails', 'warp', 'bloom', 'chroma', 'flashes', 'colorSpeed']) {
      let t = lerp(pa.fx[k], pb.fx[k], mx);
      if (k === 'trails' || k === 'warp' || k === 'chroma') t *= vibe.fx;
      if (k === 'bloom') t = t * (0.9 + 0.1 * vibe.fx) + 0.12 * F.drop; // the drop blooms a little more
      if (k === 'chroma') t += 0.12 * F.build; // and the build splits the prism a little wider
      AUTO.fx[k] = ease(AUTO.fx[k], t, dt, 1.4);
    }
    if (A.kal && !B) autoKalTick(A, dt); // v21 kaleidoscope director
  }
  const fx = AUTO.fx || AUTO_FX.tunnel, ap = A ? autoProfile(A.R) : null;
  const val = { autopilot: true, switchBars: ap ? clamp(Math.round(ap.bars * vibe.bars / 8) * 8, 8, 64) : 32, transition: 'auto', transTime: 1, // the per-style durations are already musical (beats)
    trails: clamp(fx.trails, 0, 1), warp: clamp(fx.warp, 0, 1.5), bloom: clamp(fx.bloom, 0, 1.6), chroma: clamp(fx.chroma, 0, 1.5), flashes: clamp(fx.flashes, 0, DEFAULTS.flashes),
    colorSpeed: clamp(fx.colorSpeed, 0, 6), palette: 'auto', symmetry: 'auto', quality: 'auto', detail: 1 };
  for (const k of AUTO_KEYS) E[k] = autoActive(k) ? val[k] : S[k];
  E.autopilot=!!S.autoShow&&(Number(S.sceneDuration)!==0||scnTimed());E.switchBars=Number(S.switchBars); // ENGINE v24: scnTimed
}

