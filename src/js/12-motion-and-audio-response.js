/* =========================== MOTION SMOOTHNESS =========================== */
/* ENGINE v10. S.motionSmooth (0 snappy .. 1 glide; default .75 = the established feel) is one global control:
   - engine camera: feedback kick zoom, rotation and marbling (viewMotionIntegral), the kick pulse (calmPulse plus a
     low-pass above the default), snare spin, the kaleidoscope's bar click, drop shock waves, build stutter,
     transition easing and style choice, the fold wipe, and the liquid flow's speed and bass breathing;
   - V.trav: its per-beat surge flattens with smoothness, completely at 1;
   - realms: F.kickS F.hitS F.hatS F.subS F.bassS F.midS F.highS F.levelS are smoothed copies (attack and release
     grow with the dial), F.smooth and the uniform uSmooth carry the dial itself (0 for MUMM3);
   - per-realm motion low-pass (MOTION_LP, or R.motionLP 0..1): above its start point the realm's frame() is fed a
     smoothed F (kick, hit, hat, levels), smoothed BANDS and a smoothed spectrum (specBytes), and its shader gets the
     same smoothed uKick/uHit/uHat/levels/uB1/uB2/uO1/uO2. Lights in the compose pass still hit on the beat. */
const MOTION_3D = new Set(['cathedral', 'foam', 'void9', 'merc', 'klnn', 'boxx', 'kubik', 'tess', 'swarm', 'hypr', 'abyss']);
const MOTION_LP = { kubik: [1, 0.5] }; // [weight, start]: KUB1K's cubes follow the raw spectrum and kicks, so it starts at 50%
function motionLPWeight(V) {
  if (!V || viewMotionProtected(V)) return 0;
  const R = V.R, own = Number(R.motionLP), d = MOTION_LP[R.key] || [Number.isFinite(own) ? clamp(own, 0, 1) : MOTION_3D.has(R.key) ? 1 : 0.7, 0.75];
  const m = clamp(Number(S.motionSmooth) || 0, 0, 1);
  return m <= d[1] ? 0 : d[0] * Math.pow((m - d[1]) / (1 - d[1]), 0.8);
}
const SMF = { keys: ['kick', 'hit', 'hat', 'sub', 'bass', 'mid', 'high', 'level', 'subN', 'bassN', 'midN', 'highN', 'levelN', 'impact', 'note', 'tension', 'energy'], s1: {}, s2: {}, spec: new Float32Array(NB), lv1: new Float32Array(8), lv: new Float32Array(8), on1: new Float32Array(8), on: new Float32Array(8),
  F: {}, lvMix: new Float32Array(8), onMix: new Float32Array(8), specSave: new Uint8Array(NB), init: false };
function smoothReset() { SMF.init = false; }
function smoothFeatures(dt) {
  const m = clamp(Number(S.motionSmooth) || 0, 0, 1), att = 0.05 + 0.12 * m, rel = 0.15 + 0.45 * m;
  if (!SMF.init) { SMF.keys.forEach((k) => { SMF.s1[k] = SMF.s2[k] = F[k] || 0; }); for (let i = 0; i < NB; i++) SMF.spec[i] = specBytes[i]; SMF.lv1.set(BANDS.lv); SMF.lv.set(BANDS.lv); SMF.on1.fill(0); SMF.on.fill(0); SMF.init = true; }
  const two = (x, a, b, i) => { const tau = x > b[i] ? att : rel; a[i] = ease(a[i], x, dt, tau); b[i] = ease(b[i], a[i], dt, tau); };
  for (const k of SMF.keys) {
    two(F[k] || 0, SMF.s1, SMF.s2, k);
    // transient envelopes (kick, hit, hat) lose height in a low-pass: restore roughly the original peak
    F[k + 'S'] = (k === 'kick' || k === 'hit' || k === 'hat') ? Math.min(1.2, SMF.s2[k] * (1.3 + 2 * att)) : SMF.s2[k];
  }
  for (let b = 0; b < 8; b++) { two(BANDS.lv[b], SMF.lv1, SMF.lv, b); two(BANDS.on[b], SMF.on1, SMF.on, b); }
  const ks = 1 - Math.exp(-dt / Math.max(1e-3, rel * 0.6)), ka = 1 - Math.exp(-dt / Math.max(1e-3, att));
  for (let i = 0; i < NB; i++) { const x = specBytes[i]; SMF.spec[i] += (x - SMF.spec[i]) * (x > SMF.spec[i] ? ka : ks); }
  F.smooth = m;
}
/* ============================ AUDIO RESPONSE (v11) ============================ */
/* ENGINE v11. One place decides how strongly each realm hears the music, so every realm looks about equally alive at
   the default settings and Audio sensitivity feels the same in every realm (before v11 it only reached the four level
   envelopes, while most realms listen to the 8-band envelopes uB1/uB2 and onsets uO1/uO2, so they ignored the dial).
   realmAudio(V) builds the inputs one realm sees, once per frame; realmFrame() hands them to R.frame (F, BANDS.lv,
   BANDS.on, specBytes) and renderRealm() uploads the same values (uSub..uLevel, uB1/uB2, uO1/uO2, uKick/uHit/uHat).
   - motion low-pass (v10, MOTION_LP / R.motionLP): mixed in first, unchanged.
   - gain g = calibration x sensitivity. Calibration: REALM_REACT[key] or R.react (a number, 1 = as designed), measured
     with work/engine11/levels.cjs so the realms pulse about equally hard on the built-in demo. Sensitivity: sensGain().
     Levels (F.sub..F.level, taken from the sensitivity-neutral F.subN..F.levelN, BANDS.lv, the JS spectrum) are
     expanded around their own ~1.2 s mean: g > 1 moves more,
     g < 1 moves less, the average look stays the same. Transients (F.kick/hit/hat, BANDS.on) are scaled, with a soft
     ceiling so high gains swell instead of clipping into flat white.
   - flicker guard: transient inputs get a short attack (REACT_GUARD) and a release floor, which leaves kicks intact but
     turns sixteenth-note hat chatter into a ripple. It fades in as the gain rises above 1 (so the top of the
     Sensitivity dial never strobes) and is always on for the realms listed in REALM_FLICKER.
   - Energy (S.dose) still reaches realms through uDose / uKick and their own code; realms that never read it
     (REALM_DOSE) get it through the same gain instead, so 0% calms and 200% lifts every realm.
   - MUMM3 and LED 06 (viewMotionProtected) are never touched: they hear exactly what they always did. */
// measured on the built-in demo (work/engine11/levels-before.json, sweep.json): realms not listed stay at 1
const REALM_REACT = { cathedral: 1.6, mandala: 2.4, merc: 1.6, klnn: 1.4, boxx: 1.2, kubik: 2, knott: 1.3, tess: 1.5, optik: 0.45, flux: 0.5 };
// ISOBAR lights its contour rings on every high-band onset (sixteenth-note hats): always guarded, twice as long
const REALM_FLICKER = { flux: 2 };
// Energy exponent for realms whose own code ignores Energy (measured: no change in pulse at Energy 200%)
const REALM_DOSE = { chroma: 0.7, abyss: 0.7, kubik: 0.7 };
const REACT_GUARD = { attack: 0.035, release: 0.17 };
const REACT_KEYS = ['sub', 'bass', 'mid', 'high', 'level'], REACT_HITS = ['kick', 'hit', 'hat', 'note']; // v22: melodic onsets follow Audio sensitivity like the other transients
// Audio sensitivity: 0.3..2.5 (default 1). The realm's modulation gain follows it a little less than linearly.
function sensGain() { const s = clamp(Number(S.reactivity) || 1, 0.3, 2.5); return Math.pow(s, 0.85); }
function realmReact(V) {
  if (!V || viewMotionProtected(V)) return { g: 1, guard: 0 };
  const own = Number(V.R.react), cal = Number.isFinite(own) && own > 0 ? own : (REALM_REACT[V.R.key] || 1);
  // Energy: realms that never read uDose / S.dose themselves (REALM_DOSE) feel it here instead
  const dose = REALM_DOSE[V.R.key] ? Math.pow(clamp(Number(S.dose) || 0, 0, 2), REALM_DOSE[V.R.key]) : 1;
  const dbg = DBG.react || null, g = clamp((dbg && dbg.gain != null ? dbg.gain : cal) * sensGain() * dose, 0, 5);
  const flag = REALM_FLICKER[V.R.key] || 0;
  return { g, guard: dbg && dbg.guard != null ? dbg.guard : Math.max(flag, clamp((g - 1) / 1.5, 0, 1)) };
}
// The engine's kick pulse (the live image's zoom punch in the feedback pass) per realm: REALM_PULSE lifts it for realms
// whose own picture barely follows the music (measured: their pulse does not grow with their input gain), and Audio
// sensitivity scales it in every realm, so the dial is felt even where a realm listens mostly to the beat clock.
const REALM_PULSE = { flux: 0.5, optik: 0.7, foam: 3, void9: 3, kubik: 3, eschr: 2, boxx: 3, knott: 2, mandala: 1.5, merc: 1.5, klnn: 1.5 };
function reactPulse(V) {
  if (!V || viewMotionProtected(V)) return 1;
  const dbg = DBG.react || null, p = dbg && dbg.pulse != null ? dbg.pulse : (REALM_PULSE[V.R.key] || 1);
  return Math.min(4, p * Math.pow(clamp(Number(S.reactivity) || 1, 0.3, 2.5), 0.6)); // capped: even at the top of the dial a kick is a punch, never a jolt
}
// soft ceiling for scaled transients: identity up to the knee, then a smooth approach to the ceiling c
function reactSoft(z, c, knee) { return z <= knee ? z : knee + (c - knee) * Math.tanh((z - knee) / (c - knee)); }
function realmAudio(V, dt) {
  const w = SMF.init ? motionLPWeight(V) : 0, r = realmReact(V);
  if (!(w > 0) && r.g === 1 && !(r.guard > 0)) { V.au = null; return null; }
  let A = V.au;
  if (!A) A = V.au = { F: {}, lv: new Float32Array(8), on: new Float32Array(8), lvM: new Float32Array(8), onG: new Float32Array(8),
    m: {}, hg: {}, ls: {}, lvS: new Float32Array(8), spec: new Uint8Array(NB), specM: new Float32Array(NB), init: false, t: -1 };
  const FP = Object.assign(A.F, F);
  for (const k of SMF.keys) FP[k] = w > 0 ? lerp(F[k] || 0, F[k + 'S'], w) : (F[k] || 0);
  for (let b = 0; b < 8; b++) { A.lv[b] = w > 0 ? lerp(BANDS.lv[b], SMF.lv[b], w) : BANDS.lv[b]; A.on[b] = w > 0 ? lerp(BANDS.on[b], SMF.on[b], w) : BANDS.on[b]; }
  for (let i = 0; i < NB; i++) A.spec[i] = w > 0 ? Math.round(lerp(specBytes[i], SMF.spec[i], w)) : specBytes[i];
  if (!A.init) {
    for (const k of REACT_KEYS) A.m[k] = A.ls[k] = FP[k + 'N'] ?? FP[k];
    for (const k of REACT_HITS) A.hg[k] = FP[k];
    A.lvM.set(A.lv); A.lvS.set(A.lv); A.onG.set(A.on); for (let i = 0; i < NB; i++) A.specM[i] = A.spec[i];
    A.init = true;
  }
  const g = r.g, km = 1 - Math.exp(-Math.max(0, dt) / 1.2), knee = 1 - 0.2 * clamp((g - 1) * 4, 0, 1);
  const expand = (x, m, hi) => clamp(m + (x - m) * g, 0, hi);
  // levels: low-passed by the flicker guard (an expanded level must not amplify frame-to-frame spectral jitter), then
  // expanded around their own slow mean
  const gd = clamp(r.guard, 0, 2), kl = gd > 0 ? 1 - Math.exp(-Math.max(0, dt) / (0.05 * gd)) : 1;
  // (from the sensitivity-neutral envelopes F.subN ..., so the dial is applied once, here)
  for (const k of REACT_KEYS) { A.ls[k] += ((FP[k + 'N'] ?? FP[k]) - A.ls[k]) * kl; A.m[k] += (A.ls[k] - A.m[k]) * km; FP[k] = expand(A.ls[k], A.m[k], 1.5); }
  for (let b = 0; b < 8; b++) { A.lvS[b] += (A.lv[b] - A.lvS[b]) * kl; A.lvM[b] += (A.lvS[b] - A.lvM[b]) * km; if (g !== 1 || gd > 0) A.lv[b] = expand(A.lvS[b], A.lvM[b], 1); }
  if (g !== 1) for (let i = 0; i < NB; i++) { A.specM[i] += (A.spec[i] - A.specM[i]) * km; A.spec[i] = Math.round(expand(A.spec[i], A.specM[i], 255)); }
  else for (let i = 0; i < NB; i++) A.specM[i] += (A.spec[i] - A.specM[i]) * km;
  // transients: flicker guard (attack low-pass + release floor, peak-compensated), then scaled with a soft ceiling
  const ta = REACT_GUARD.attack * gd, tr = REACT_GUARD.release * gd, comp = 1 + 0.3 * Math.min(1, gd);
  const guard = (x, y) => { if (!(gd > 0)) return x; const tau = x > y ? ta : tr; return tau > 1e-4 ? y + (x - y) * (1 - Math.exp(-Math.max(0, dt) / tau)) : x; };
  for (const k of REACT_HITS) { A.hg[k] = guard(FP[k], A.hg[k]); FP[k] = reactSoft(Math.min(1.2, A.hg[k] * (gd > 0 ? comp : 1)) * g, 1.2, 1.2 * knee); }
  for (let b = 0; b < 8; b++) { A.onG[b] = guard(A.on[b], A.onG[b]); A.on[b] = reactSoft(Math.min(1, A.onG[b] * (gd > 0 ? comp : 1)) * g, 1, knee); }
  FP.react = g;
  A.t = TIME;
  return A;
}
// call a realm's frame() with the inputs realmAudio() built for it (the engine's own are restored after)
// v15: a local score keeps each realm's existing phrase choreography alive through silence and
// unreliable bar detection. It supplies structural cues only: no fake kick, spectrum, drop or audio clock.
function realmScore(V, input, dt) {
  const c=V.score||(V.score={quiet:0,phase:0,index:input.barIndex|0,ambient:0,inputs:{}});
  const step=Math.max(0,Number.isFinite(dt)?dt:0),speed=clamp(Number(S.speed)||0,0,2.5);
  c.quiet+=step;
  if(input.onBar){c.quiet=0;c.phase=0;c.index=input.barIndex|0;return input;}
  if(c.quiet<6||speed===0)return input;
  c.phase+=step*speed;
  const cue=c.phase>=2.5;
  if(cue){c.phase%=2.5;c.index++;c.ambient++;}
  return Object.assign(c.inputs,input,{onSceneBar:cue,sceneBarIndex:c.index});
}
function realmFrame(V, dt) {
  const A = realmAudio(V, dt),scene=realmScore(V,A?A.F:F,dt);
  if (!A) { V.R.frame(V, scene, dt); return; }
  const lv = BANDS.lv, on = BANDS.on;
  SMF.specSave.set(specBytes.subarray(0, NB));
  specBytes.set(A.spec, 0);
  BANDS.lv = A.lv; BANDS.on = A.on;
  try { V.R.frame(V, scene, dt); }
  finally { BANDS.lv = lv; BANDS.on = on; specBytes.set(SMF.specSave, 0); }
}
// The fold the compose pass shows for the current realm, with a radial wipe whenever it changes within a visit.
/* v21 fold changes within a visit, as the compose pass sees them.
   - fold to fold (both 2 or more): the fold count itself glides (in log space, so the mirror angle opens or closes evenly),
     together with the fold's rotation. The picture stays one continuous kaleidoscope the whole way.
   - to or from the unfolded view or the plain mirror: a slow cross-dissolve (uSymA0 -> uSymA over uSymT).
   The Auto Show's own changes take about two bars; a fold picked by hand keeps its quick response.
   The Auto Show holds the four-way mirror (2) square to the screen; every other fold turns with the music as before. */
const FOLD = { visit: null, cur: 0, from: 0, t: 1, dur: 1, glide: false, n0: 0, dRot: 0 };
const foldAuto = () => E.symmetry === 'auto';
function foldOf(V) { const s = effectiveSym(V); return foldAuto() ? (V.kal && V.kal.fold === 1 && s === 0 ? 1 : s) : s === 1 ? 0 : s; } // the plain mirror is the director's alone
function foldRot(s) { return s === 2 && foldAuto() ? Math.PI / 2 : D.symRot; }
const wrapPi = (a) => a - 2 * Math.PI * Math.round(a / (2 * Math.PI));
function foldNow() { // [fold count to draw, its rotation]
  if (!(FOLD.glide && FOLD.t < 1)) return [FOLD.cur, foldRot(FOLD.cur)];
  const u = FOLD.t, e = u * u * u * (u * (6 * u - 15) + 10);
  return [Math.exp(lerp(Math.log(FOLD.n0), Math.log(FOLD.cur), e)), foldRot(FOLD.cur) + (1 - e) * FOLD.dRot];
}
function foldUpdate(A, B, dt) {
  const s = foldOf(A);
  if (B || FOLD.visit !== A) { FOLD.visit = A; FOLD.cur = s; FOLD.from = s; FOLD.t = 1; FOLD.glide = false; return; }
  if (s !== FOLD.cur) {
    const m = viewMotionProtected(A) ? 0 : clamp(Number(S.motionSmooth) || 0, 0, 1), auto = foldAuto();
    const glide = s >= 2 && FOLD.cur >= 2 && (FOLD.t >= 1 || FOLD.glide);
    if (glide) { const now = foldNow(); FOLD.n0 = now[0]; FOLD.dRot = wrapPi(now[1] - foldRot(s)); FOLD.from = FOLD.cur; }
    else FOLD.from = FOLD.t < 0.5 ? FOLD.from : FOLD.cur;
    FOLD.glide = glide; FOLD.cur = s; FOLD.t = 0;
    FOLD.dur = auto ? beatsDur(8, 4) * (0.8 + 0.6 * m) * (glide ? 1 + 0.35 * Math.abs(Math.log2(s / FOLD.n0)) : 1) : beatsDur(2, 1) * (0.6 + 1.2 * m);
  }
  if (FOLD.t < 1) FOLD.t = Math.min(1, FOLD.t + dt / Math.max(0.05, FOLD.dur));
}
// The liquid flow field's clock and its smoothed bass breathing (see flowField in FS_FEEDBACK).
const FLOW = { t: 0, breath: 0 }, PULSE_LP = { x: 0, y: 0 };

