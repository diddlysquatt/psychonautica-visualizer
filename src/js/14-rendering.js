/* ============================== rendering ============================= */
// uZoom contract: 1 = the realm's default framing, below 1 = zoomed out (camera further back / wider view), above 1 = in.
// The user's wheel/pinch zoom spans ZOOM_MIN..ZOOM_MAX. While a kaleidoscope fold is active the realm is also pulled
// back by its kalZoom (default .7) so the folded image shows more of the world.
// v13 zoom contract for realms: zoom is a camera move inside the current world (never a trigger for travel, dives or
// realm-internal scene changes), every step of the range visibly changes the framing (no dead zones), nothing goes
// dark, blurry or empty anywhere in 0.15..2.5, and any nested-world swap is a cross-fade spread over a zoom span.
const ZOOM_MIN = 0.15, ZOOM_MAX = 2.5, ZOOM_HOME = 0.8;
// Wheel / pinch zoom feel: the target moves in log space and PTR.zoom follows it on a critically damped spring in log
// space, so zooming in and out feel equally fast at every scale and stop without drift. Crossing the default framing
// (.8) the wheel rests there for a moment (ZOOM_DETENT of log zoom must be pushed through), so it is easy to get back.
const ZOOM_W = 9, ZOOM_DETENT = 0.14, ZOOMS = { v: 0, push: 0, pushT: -9 };
function zoomTo(z) { PTR.zoomT = clamp(z, ZOOM_MIN, ZOOM_MAX); }
function zoomWheel(dl) {
  AUTOZ.userT = TIME;
  const l0 = Math.log(PTR.zoomT/ZOOM_HOME), now = performance.now();
  if (now - ZOOMS.pushT > 450) ZOOMS.push = 0;
  ZOOMS.pushT = now;
  if (Math.abs(l0) < 1e-6) { // resting on the default framing: push through the detent first
    ZOOMS.push += dl; if (Math.abs(ZOOMS.push) < ZOOM_DETENT) return;
    dl = ZOOMS.push - Math.sign(ZOOMS.push) * ZOOM_DETENT; ZOOMS.push = 0;
  } else if (l0 * (l0 + dl) < 0) { zoomTo(ZOOM_HOME); ZOOMS.push = 0; return; } // stop on the wide home framing
  zoomTo(ZOOM_HOME*Math.exp(l0 + dl));
}
function zoomSpring(dt) {
  const l = Math.log(Math.max(1e-3, PTR.zoom)), lt = Math.log(PTR.zoomT), w = ZOOM_W, e = Math.exp(-w * dt);
  const d = l - lt, q = ZOOMS.v + w * d, nl = lt + (d + q * dt) * e;
  ZOOMS.v = (ZOOMS.v - w * q * dt) * e;
  PTR.zoom = Math.abs(nl - lt) < 1e-4 && Math.abs(ZOOMS.v) < 1e-3 ? PTR.zoomT : Math.exp(nl);
}
/* v21 camera distance. Every scene arrives at its own wide home framing (SHOW z[1]) and lives there: after a good first
   look it only leaves home for short visits and always comes back.
   - close-up: starts on a 4-bar line (or rides a build in), glides in, holds one or two bars, glides back; a drop while it
     is in or close sends it back out at once. Never two close-ups without a long stay at home between them.
   - far view: the scene's widest worthwhile framing, held a little longer.
   - drift: a small breath round home, so the picture is never frozen.
   Which comes next, how far it goes and how long everything takes come from a generator seeded by the visit: nothing
   repeats on a fixed period. Every move is a quintic in log zoom that starts from the current position, speed and
   acceleration (a retarget never kinks) and is long enough to stay under about .15 log-zoom per second.
   A folded scene only drifts. Manual wheel / pinch / 0 input pauses all of it for 25 seconds, as before; the framing
   tour also runs with quiet music, in visual-only mode and with the Auto Show off (Framing: Tour), as before. */
const AUTOZ_PAUSE = 25, AUTOZ = { userT: -1e9, key: null, last: .8, t0: 0, dur: 0, c: [0, 0, 0, 0, 0, 0], to: .8, next: 0, q: [], kind: '', lastKind: '', armed: null, closeT: -1e9, arr: null, r: Math.random };
function autoZoomReset() { Object.assign(AUTOZ, { userT: -1e9, key: null, last: .8, t0: 0, dur: 0, to: .8, next: 0, q: [], kind: '', lastKind: '', armed: null, closeT: -1e9, arr: null }); }
function realmHome(V) { return V ? showOf(V.R).z[1] : .72; }
// log zoom, speed and acceleration of the running glide at time t
function autoZoomAt(t) {
  const u = clamp(t - AUTOZ.t0, 0, AUTOZ.dur), c = AUTOZ.c;
  return [c[0] + u * (c[1] + u * (c[2] + u * (c[3] + u * (c[4] + u * c[5])))), c[1] + u * (2 * c[2] + u * (3 * c[3] + u * (4 * c[4] + u * 5 * c[5]))), 2 * c[2] + u * (6 * c[3] + u * (12 * c[4] + u * 20 * c[5]))];
}
function autoZoomGlide(to, dur) {
  let x0 = Math.log(PTR.zoomT), v0 = 0, a0 = 0;
  if (AUTOZ.dur > 0 && Math.abs(PTR.zoomT - AUTOZ.last) < 1e-6) [x0, v0, a0] = autoZoomAt(TIME);
  to = clamp(to, ZOOM_MIN, ZOOM_MAX);
  const T = Math.max(.05, dur), d = Math.log(to) - x0, T2 = T * T, T3 = T2 * T;
  AUTOZ.c = [x0, v0, a0 / 2, (20 * d - 12 * v0 * T - 3 * a0 * T2) / (2 * T3), (-30 * d + 16 * v0 * T + 3 * a0 * T2) / (2 * T3 * T), (12 * d - 6 * v0 * T - a0 * T2) / (2 * T3 * T2)];
  AUTOZ.t0 = TIME; AUTOZ.dur = T; AUTOZ.to = to; AUTOZ.last = PTR.zoomT;
}
// long enough for an unhurried glide: at least `want` seconds, and never faster than ~.15 log-zoom per second at its peak
function autoZoomDur(to, want) { const d = Math.abs(Math.log(to / PTR.zoomT)), m = clamp(Number(S.motionSmooth) || 0, 0, 1); return Math.max(want, d * (9 + 5 * m)); }
/* ENGINE v24: THE CAMERA TRAVELS THE WHOLE ROW (the owner: "the auto camera goes ALL THE WAY OUT and ALL THE WAY IN at some point").
   Until now a visit glided home, held it for a long time and made excursions that mostly stopped short of the ends of the
   scene's SHOW row. Now every visit that is long enough makes one GRAND TOUR soon after its first look: home, a glide all
   the way out to z[0], a held look (6 to 9 s), a glide all the way in to z[2], a shorter held look (2.5 to 4 s), back
   home (the order alternates between visits of a scene; an end whose appetite c / w is 0, or that lies within 15% of home,
   is left out). It leaves on a musical line (4-bar line, section or phrase start; 6 s at the latest), never while the
   scene's hold(V) is true, never while folded. The glides keep the old speed limit (about .15 log-zoom per second at the
   peak); when the visit is too short for that they may run up to 1.4 times faster, and when even that does not fit the
   tour visits one end only (the other one next time), or is left out. A drop while the camera is in close does not break
   the tour off any more: it only cuts the close look to 1.5 s. The Auto folds director waits for a visit's first tour to
   come home (autoKalTick), so a fold never lands in the middle of it. Long visits (and Framing: Tour with the Auto Show
   off) tour again about every minute. Between tours the old excursions remain, with the stays at home between them about
   halved and the small drift round home only where a scene has nowhere else to go.
   Scenes that fly their own camera (continuousJourney: cathedral, void9, boxx; and AUTOZ_OWN) are left exactly as they
   were: no tour, the old stays. A row with far = home = close still never moves. */
const AUTOZ_OWN = new Set(['tykes']); // scene code runs its own camera journey: the engine keeps to the old small moves
// the legs of a grand tour that fits into `left` seconds of the visit, or null
function autoZoomTour(V, sh, left, beats, canFar, canNear) {
  const Z = AUTOZ, far = sh.z[0], home = sh.z[1], close = sh.z[2], rate = 9 + 5 * clamp(Number(S.motionSmooth) || 0, 0, 1);
  const hold = { far: beats(12, 6, 9), close: beats(6, 2.5, 4) }, at = { far, close }; // the close look is the shorter one
  const plan = (ends) => {
    let glide = 0, from = PTR.zoomT, holds = 0;
    for (const e of ends.concat(['home'])) { const to = e === 'home' ? home : at[e]; glide += Math.max(3, Math.abs(Math.log(to / from)) * rate); from = to; if (e !== 'home') holds += hold[e]; }
    const k = left === Infinity ? 1 : Math.min(1, (left - 10 - holds) / glide); // 10 s: the wait for a musical line, and a moment at home before the scene changes
    if (!(k >= .7)) return null;
    return ends.map((e) => ({ to: at[e], dur: 3, rate: rate * k, hold: hold[e], end: e })).concat([{ to: home, dur: 3, rate: rate * k, hold: 4 + Z.r() * 4 }]);
  };
  const first = V.R._zFirst ? (V.R._zFirst === 'far' ? 'close' : 'far') : Z.r() < .65 ? 'far' : 'close'; // the other way round than last time
  let legs = canFar && canNear ? plan(first === 'far' ? ['far', 'close'] : ['close', 'far']) : null;
  if (!legs) { // one end only: the one this scene did not show on its last one-ended tour
    const ends = [canFar && 'far', canNear && 'close'].filter(Boolean); if (ends.length > 1 && V.R._zEnd === ends[0]) ends.reverse();
    for (const e of ends) { legs = plan([e]); if (legs) break; }
  }
  return legs;
}
function autoZoomUpdate() {
  const V = D.nxt || D.cur; if (!V) return; const Z = AUTOZ;
  if (S.cameraMode === 'hold') { Z.dur = 0; Z.q.length = 0; Z.armed = null; Z.arr = null; Z.leg = null; Z.tourWait = false; return; }
  const user = TIME - Z.userT < AUTOZ_PAUSE, sh = showOf(V.R), far = sh.z[0], home = sh.z[1], close = sh.z[2];
  const beat = F.conf > .35 && F.bpm > 40 && !F.silent ? 60 / F.bpm : 0, beats = (n, lo, hi) => clamp(n * (beat || .45), lo, hi);
  const own = V.R.continuousJourney === true || AUTOZ_OWN.has(V.R.key); // the scene flies itself
  const canFar = sh.w > 0 && home / far > 1.15, canNear = sh.c > 0 && close / home > 1.15, tours = !own && (canFar || canNear);
  if (Z.key !== V.R) { // a different scene: it arrives at its own home and is shown whole before anything else
    Z.key = V.R; Z.r = mulberry((((V.seed[1] || .5) * 4294967296) >>> 0) ^ 0x7f4a7c15); Z.q.length = 0; Z.armed = null; Z.kind = ''; Z.lastKind = ''; Z.closeT = TIME - 12;
    Z.leg = null; Z.tourN = 0; Z.tourT = -1e9; Z.tourEnd = -1e9; Z.noTour = false; Z.homeT = TIME;
    if (TIME - Z.userT > 4) { autoZoomGlide(home, autoZoomDur(home, clamp(D.nxt ? D.dur * 1.5 : 3, 2.5, 6))); Z.next = TIME + Z.dur + (tours ? 5 + Z.r() * 4 : 12 + Z.r() * 9); Z.arr = V; }
    else { Z.next = TIME + 12; Z.arr = null; }
  }
  const r = Z.r, folded = foldOf(V) >= 1, off = Math.abs(Math.log(PTR.zoomT / home));
  const stay = (a, b, a2, b2) => own ? a + r() * b : a2 + r() * b2; // seconds at home after a move: as before for self-flying scenes, about half for the others
  // the Auto folds director waits for this visit's first tour (see autoKalTick)
  Z.tourWait = tours && !Z.noTour && Z.tourN === 0 && !user && E.symmetry === 'auto';
  // a drop while the tour is in close: that look is cut short, the tour goes on
  if (!user && Z.kind === 'tour' && F.onDrop && Z.leg && Z.leg.end === 'close') Z.next = Math.min(Z.next, Math.max(TIME, Z.landT + 1.5));
  // out at once: a drop while in close (the short excursion), or a fold arriving during any excursion
  if (!user && (Z.kind === 'close' || Z.kind === 'wide' || Z.kind === 'tour') && ((Z.kind === 'close' && F.onDrop) || folded) && (Z.q.length || off > .1)) {
    Z.q.length = 0; if (Z.kind === 'close') Z.closeT = TIME; Z.lastKind = Z.kind; Z.kind = ''; Z.leg = null;
    autoZoomGlide(home, autoZoomDur(home, beats(8, 3.5, 6))); Z.homeT = TIME + Z.dur; Z.next = Z.homeT + stay(10, 12, 5, 6);
  }
  if (Z.dur > 0) {
    if (user || Math.abs(PTR.zoomT - Z.last) > 1e-6) { Z.dur = 0; Z.q.length = 0; Z.armed = null; Z.kind = ''; Z.arr = null; Z.leg = null; Z.next = TIME + 6; return; }
    PTR.zoomT = Z.last = clamp(Math.exp(autoZoomAt(TIME)[0]), ZOOM_MIN, ZOOM_MAX);
    if (TIME - Z.t0 >= Z.dur) Z.dur = 0;
    return;
  }
  if (D.nxt || user) { if (user) { Z.q.length = 0; Z.armed = null; Z.kind = ''; Z.leg = null; } return; }
  const held = !!(sh.hold && sh.hold(V)); // v22: the scene asks to wait: no new zoom move starts
  if (Z.q.length) { // the next leg of the excursion under way
    if (TIME < Z.next || held) return;
    const leg = Z.q.shift();
    autoZoomGlide(leg.to, leg.rate ? Math.max(leg.dur, Math.abs(Math.log(leg.to / PTR.zoomT)) * leg.rate) : autoZoomDur(leg.to, leg.dur));
    Z.leg = leg; Z.landT = TIME + Z.dur; Z.next = Z.landT + leg.hold;
    if (!Z.q.length) { // the last leg: on its way home
      if (Z.kind === 'close' || Z.kind === 'tour') Z.closeT = Z.next;
      if (Z.kind === 'tour') { Z.tourN++; Z.tourT = Z.tourEnd = Z.landT; }
      Z.lastKind = Z.kind; Z.kind = ''; Z.homeT = Z.landT;
    }
    return;
  }
  // at rest. A build may pull the camera in early; otherwise wait out the stay.
  const canClose = !folded && sh.c > 0 && close / home > 1.15 && TIME - Z.closeT > (own ? 26 : 16);
  const build = canClose && F.build > .5 && TIME > Z.next - 8 && Z.lastKind !== 'close' && r() < .02 + sh.c * .05;
  if (held) return;
  if (!Z.armed && (TIME >= Z.next || build)) {
    if (off > .16) { autoZoomGlide(home, autoZoomDur(home, 5)); Z.homeT = TIME + Z.dur; Z.next = Z.homeT + stay(6, 8, 4, 4); return; } // someone left it away from home: go home first
    let legs = null;
    if (tours && !folded && !build && !Z.noTour && TIME - Z.tourT > (Z.tourN ? 40 + r() * 25 : 0)) {
      legs = autoZoomTour(V, sh, autoKalHold(V) - (V === D.cur ? D.realmTime : 0), beats, canFar, canNear);
      if (!legs && !Z.tourN) Z.noTour = true; // this visit is too short for one (what is left of it only shrinks)
    }
    if (legs) Z.armed = { kind: 'tour', legs, until: TIME + 6 };
    else {
      const wC = build ? 1e3 : canClose ? .5 * sh.c * (Z.lastKind === 'close' ? .2 : 1) : 0, wW = folded || home / far < 1.15 ? 0 : .42 * sh.w * (Z.lastKind === 'wide' ? .3 : 1);
      const wD = !own && wC + wW > 0 ? 0 : .7 * (Z.lastKind === 'drift' ? .6 : 1); // the breath round home only where there is nowhere else to go
      const x = r() * (wC + wW + wD);
      Z.armed = { kind: x < wC ? 'close' : x < wC + wW ? 'wide' : 'drift', until: TIME + (build ? 0 : own ? 7 : 5) };
    }
  }
  if (!Z.armed) return;
  // excursions leave on a musical line when there is a beat to follow: a 4-bar line, a new section or phrase
  const line = (F.onBar && beat > 0 && (F.barIndex - D.phraseBase) % 4 === 0) || (Z.armed.kind === 'tour' && (F.onSection || F.onPhrase));
  if (!(line || TIME >= Z.armed.until || Z.armed.kind === 'drift')) return;
  const kind = Z.armed.kind, legs = Z.armed.legs; Z.armed = null; Z.kind = kind;
  if (kind === 'tour') {
    Z.q.push(...legs);
    if (legs.length > 2) V.R._zFirst = legs[0].end; else V.R._zEnd = legs[0].end;
  } else if (kind === 'close') {
    const to = home * Math.exp(lerp(.5, 1, r()) * Math.log(close / home));
    Z.q.push({ to, dur: beats(12, 4.5, 8), hold: beats(4 + 4 * Math.floor(r() * 2), 2, 5) }, { to: home, dur: beats(12, 4.5, 8), hold: stay(14, 16, 6, 6) });
  } else if (kind === 'wide') {
    const to = home * Math.exp(lerp(.45, 1, r()) * Math.log(far / home));
    Z.q.push({ to, dur: beats(16, 6, 10), hold: beats(8 + 8 * Math.floor(r() * 3), 5, 13) }, { to: home, dur: beats(16, 6, 10), hold: stay(9, 12, 5, 6) });
  } else {
    const amp = folded ? lerp(.03, .07, r()) : lerp(.04, .1, r()), to = clamp(home * Math.exp((r() < .5 ? -1 : 1) * amp), far, close);
    Z.q.push({ to, dur: 8 + r() * 6, hold: 3 + r() * 6 });
  }
  Z.next = TIME;
}

// The framing factor of a visit (V.kz; realms read PTR.zoom * V.kz as their effective zoom). Two parts:
// - the fold pull-back (V.kf). Under Automatic it is an unhurried critically damped glide in log space, in step with the fold
//   morph; a fold picked by hand keeps the quick ease it always had.
// - the arrival factor (V.zf). The wheel zoom is one value shared by the outgoing and the incoming scene, and it glides to the
//   new scene's home without hurry; V.zf makes up the difference for the incoming scene, so it stands at its own home framing
//   from its first frame (a scene whose home is close never arrives as a small thing, one whose home is wide never arrives
//   cropped). It is exactly 1 again when the glide lands.
function kzUpdate(V, dt) {
  const want = effectiveSym(V) > 1 ? autoKalZoom(V) : 1;
  if (V.kf === undefined) { V.kf = want; V.kzV = 0; V.zf = AUTOZ.arr && AUTOZ.arr !== V && AUTOZ.arr.R === V.R && AUTOZ.arr.zf ? AUTOZ.arr.zf : 1; } // a reseed inherits the arrival factor
  if (dt > 0) {
    if (E.symmetry === 'auto') {
      const w = 1.1 / (.7 + .4 * clamp(Number(S.motionSmooth) || 0, 0, 1)), x = Math.log(V.kf / want), q = (V.kzV || 0) + w * x, e = Math.exp(-w * dt);
      V.kf = want * Math.exp((x + q * dt) * e); V.kzV = ((V.kzV || 0) - w * q * dt) * e;
    } else { V.kf += (want - V.kf) * (1 - Math.exp(-dt * 2.5)); V.kzV = 0; }
  }
  if (AUTOZ.arr && AUTOZ.arr.R === V.R && AUTOZ.dur > 0) V.zf = clamp(realmHome(V) / Math.max(1e-3, PTR.zoom), .3, 3.4);
  else if (V.zf !== 1) { if (AUTOZ.arr && AUTOZ.arr.R === V.R) AUTOZ.arr = null; V.zf = Math.abs(Math.log(V.zf)) < 2e-3 || !(dt > 0) ? (dt > 0 ? 1 : V.zf) : Math.exp(Math.log(V.zf) * Math.exp(-dt * 1.2)); }
  V.kz = V.kf * V.zf;
}
function realmZoom(V) { if (V.kz === undefined) kzUpdate(V, 0); return clamp(PTR.zoom * V.kz, ZOOM_MIN * .5, ZOOM_MAX * 1.5); }
// 8-band envelopes and onsets from the displayed (audible-aligned) spectrum
const BANDS = { edges: [0, .08, .18, .3, .42, .55, .68, .82, 1], fast: new Float32Array(8), slow: new Float32Array(8), hi: new Float32Array(8).fill(.3), lv: new Float32Array(8), on: new Float32Array(8) };
function bandsUpdate(dt) {
  const B = BANDS, k = 1 - Math.exp(-dt / 0.035), ks = 1 - Math.exp(-dt / 0.4), ko = Math.exp(-dt / 0.15);
  for (let b = 0; b < 8; b++) {
    const i0 = Math.floor(B.edges[b] * NB), i1 = Math.max(i0 + 1, Math.floor(B.edges[b + 1] * NB));
    let m = 0; for (let i = i0; i < i1; i++) m += specBytes[i]; m /= (i1 - i0) * 255;
    B.fast[b] += (m - B.fast[b]) * k; B.slow[b] += (m - B.slow[b]) * ks;
    B.hi[b] = Math.max(B.fast[b], B.hi[b] - dt * 0.04, 0.15);
    B.lv[b] = clamp(B.fast[b] / B.hi[b], 0, 1);
    B.on[b] = Math.max(B.on[b] * ko, clamp((B.fast[b] - B.slow[b] - 0.04) / (0.25 * B.hi[b]), 0, 1));
  }
}
/* Image sliders. Each one's default position reproduces the established look exactly. Above it the response grows
   faster than linear and progressively overrides the per-realm damping (fb.live / REALM_LIVE, which keeps crisp
   graphic realms at ~0.1-0.3), so at the top of its range every effect is clearly visible in every realm. Below the
   default the response stays linear down to off. */
const SLIDER_TOP = { warp: 1.5, bloom: 1.6, chroma: 1.5, flashes: 1 };
function sliderBoost(key) { const d = DEFAULTS[key], v = Number(E[key]) || 0; return v <= d ? 0 : clamp((v - d) / (SLIDER_TOP[key] - d), 0, 1); }
function sliderGain(key, pow) { const d = DEFAULTS[key], v = Math.max(0, Number(E[key]) || 0); return v <= d ? v : d * Math.pow(v / d, pow); }
const liveFor = (live, key) => lerp(live, 1, sliderBoost(key));
// flash strength: linear to the default, then steep (2.2x the default response at 100%)
function flashGain() { const v = clamp(Number(E.flashes) || 0, 0, 1), d = DEFAULTS.flashes; return v <= d ? v : d + (v - d) * 7; }
// The detail the realm shaders get: the chosen detail times Auto's internal multiplier (1 unless the GPU is behind).
function baseDetail() { return Math.min(16, E.detail * (DETAIL_BY_QUALITY[E.quality] || 1)); }
function effectiveDetail() { return baseDetail() * (OFF.on || E.quality !== 'auto' ? 1 : Q.detailNow); }
// res (optional): the uRes the shader sees, when it differs from the target (the 2x2 warm-up draw stands in for a
// corner of a full frame, so the realm runs its usual per-pixel work instead of a degenerate 2-pixel-high frame)
function renderRealm(V, target, res) {
  const p = V.R.P, tw = target.w, th = target.h;
  gl.useProgram(p.p);
  u2(p, 'uRes', res ? res[0] : tw, res ? res[1] : th); u1(p, 'uDetail', effectiveDetail()); u1(p, 'uTime', RTIME % 36000); u1(p, 'uMT', V.mt); u1(p, 'uZoom', realmZoom(V)); u1(p, 'uDose', S.dose); u1(p, 'uHue', (D.hue + (F.cent - 0.45) * 0.35) % 1000);
  const dz = S.dose;
  // v10 motion low-pass: realms on it get smoothed audio uniforms as the dial rises (see realmFrame)
  // v11 audio response: the same inputs realmAudio() gave this realm's frame() this frame (else the v10 path below)
  const AV = V.au && V.au.t === TIME ? V.au : null;
  const lw = AV ? 0 : SMF.init ? motionLPWeight(V) : 0, sf = (k) => AV ? AV.F[k] : lw > 0 ? lerp(F[k] || 0, F[k + 'S'], lw) : F[k];
  u1(p, 'uSub', sf('sub')); u1(p, 'uBass', sf('bass')); u1(p, 'uMid', sf('mid')); u1(p, 'uHigh', sf('high')); u1(p, 'uLevel', sf('level'));
  u1(p, 'uSmooth', V.R && viewMotionProtected(V) ? 0 : clamp(Number(S.motionSmooth) || 0, 0, 1));
  const kv = dz * (0.3 + 0.7 * E.flashes);
  const BL = AV ? AV.lv : lw > 0 ? SMF.lv.map((x, i) => lerp(BANDS.lv[i], x, lw)) : BANDS.lv, BO = AV ? AV.on : lw > 0 ? SMF.on.map((x, i) => lerp(BANDS.on[i], x, lw)) : BANDS.on;
  u4(p, 'uB1', [BL[0], BL[1], BL[2], BL[3]]); u4(p, 'uB2', [BL[4], BL[5], BL[6], BL[7]]); u4(p, 'uO1', [BO[0], BO[1], BO[2], BO[3]]); u4(p, 'uO2', [BO[4], BO[5], BO[6], BO[7]]);
  u1(p, 'uKick', sf('kick') * kv); u1(p, 'uHit', sf('hit') * kv); u1(p, 'uHat', sf('hat') * kv);
  u1(p, 'uBeat', F.beat); u1(p, 'uBar', F.bar); u1(p, 'uDrop', F.drop); u1(p, 'uBuild', F.build);
  u1(p, 'uImpact', sf('impact')); u1(p, 'uTension', sf('tension')); u1(p, 'uEnergy', sf('energy')); u1(p, 'uSecAge', F.sectionAge); u1(p, 'uSection', F.section % 4096); u1(p, 'uBarPh', F.barPhase); u1(p, 'uPhrase', F.phrasePos); u1(p, 'uNote', sf('note') * kv); u1(p, 'uSwell', F.swell); // v22
  u4(p, 'uSeed', V.seed);
  u4(p, 'uVar', [0.5 + 0.5 * Math.sin(TIME * 0.081), 0.5 + 0.5 * Math.sin(TIME * 0.053 + 1), 0.5 + 0.5 * Math.sin(TIME * 0.034 + 2), 0.5 + 0.5 * Math.sin(TIME * 0.021 + 3)]);
  u4(p, 'uP1', V.p1); u4(p, 'uP2', V.p2); u4(p, 'uP3', V.p3); u4(p, 'uP4', V.p4); u4(p, 'uP5', V.p5); um3(p, 'uM1', V.m1); um3(p, 'uM2', V.m2);
  const pl = PAL_NOW;
  u3(p, 'uPa', pl.A.a); u3(p, 'uPb', pl.A.b); u3(p, 'uPc', pl.A.c); u3(p, 'uPd', pl.A.d);
  u3(p, 'uQa', pl.B.a); u3(p, 'uQb', pl.B.b); u3(p, 'uQc', pl.B.c); u3(p, 'uQd', pl.B.d); u1(p, 'uPalT', pl.t);
  u2(p, 'uMouse', PTR.x, PTR.y); u4(p, 'uMouseV', [0, 0, 0, 0]); u2(p, 'uLook', PTR.lx, PTR.ly);
  bindTex(0, specTex); ui(p, 'uSpec', 0);
  drawTo(target, tw, th, true);
}
let PAL_NOW = palPair();
function needsUpcomingWindow(V) {
  if(!V || !(V.R.fb.win>0))return false;
  // These shaders can put the next realm in an aperture; the others only recurse into feedback.
  return ['gate','void9','boxx','klnn'].includes(V.R.key) || (V.R.key==='foam' && F.build>.45);
}
function render(dt) {
  resize();
  gl.bindVertexArray(vao);
  gl.bindTexture(gl.TEXTURE_2D, specTex);
  gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, NB, 2, gl.RED, gl.UNSIGNED_BYTE, specBytes);
  PAL_NOW = palPair();
  const A = D.cur, B = D.nxt;
  const cameraCalm=viewMotionAmount(A,B,D.peek);
  const eighth = fract(F.beat * 2), stutOn = (F.build > 0.75 || Math.floor(F.beat * 2) % 2 === 0) && eighth < 0.16;
  let stutter = !B && !D.peek && D.upcoming && F.conf > 0.4 && F.build > 0.45 && stutOn ? 0.8 * clamp((F.build - 0.45) / 0.4, 0, 1) * (0.3 + 0.7 * E.flashes) : 0;
  if(cameraCalm>0)stutter*=Math.pow(Math.max(0,1-cameraCalm/.65),3);
  renderRealm(A, RT.A);
  if (B) renderRealm(B, RT.B);
  else if (D.peek) renderRealm(D.peek, RT.B);
  else if (D.upcoming && (stutter>0 || needsUpcomingWindow(A))) renderRealm(D.upcoming, RT.N);
  else if (!D.upcoming && needsUpcomingWindow(A)) renderRealm(A, RT.N); // no other realm prepared yet: windows show this one

  // feedback profile (blend realm profiles during a crossfade)
  const fa = A.R.fb, fbB = B ? B.R.fb : fa, m = B ? D.mix : 0;
  const prof = (k) => lerp(fa[k], fbB[k], m);
  // fb.live (default 1) scales the engine's global live warp and kick zoom; crisp graphic realms keep it low
  const liveOf = (R) => R.fb.live ?? REALM_LIVE[R.key] ?? 1;
  const live = lerp(liveOf(A.R), B ? liveOf(B.R) : liveOf(A.R), m);
  const sp = S.speed, step = Math.min(dt * 60, 3);
  const dz = S.dose;
  const screenMotion=lerp(A.R.screenMotion??1,B?(B.R.screenMotion??1):(A.R.screenMotion??1),m);
  const breath = Math.pow(1 - F.beat, 6) * F.conf * 0.004 * dz;
  let zoom = (prof('zoom') * (0.6 + 0.6 * sp) + (F.kick * 0.016 * dz + breath) * (0.3 + 0.7 * E.flashes) + F.build * 0.01 + F.drop * 0.02 * dz) * step;
  if(cameraCalm>0&&dt>0&&step>0){
    const baseZoom=prof('zoom')*(.6+.6*sp), gain=calmGain(cameraCalm);
    const targetZoom=baseZoom+(zoom/step-baseZoom)*gain;
    zoom=viewMotionIntegral(targetZoom,dt,cameraCalm)*(step/dt);
  }else viewMotionReset();
  let rotv = (prof('rot') + (F.mid - 0.3) * 0.002 * dz) * step;
  if(cameraCalm>0&&dt>0&&step>0){
    const baseRot=prof('rot'),gain=calmGain(cameraCalm);
    rotv=viewMotionIntegral(baseRot+(rotv/step-baseRot)*gain,dt,cameraCalm,'rotation')*(step/dt);
  }
  zoom*=screenMotion;rotv*=screenMotion;
  // Liquid warp: above the default it grows quadratically (about 7.4x the default flow at 150%) and reaches realms
  // whose profile has no warp of their own
  const warpG = sliderGain('warp', 2), warpProf = Math.max(prof('warp'), 0.5 * sliderBoost('warp'));
  // v10 liquid: one smooth, divergence-free flow field (flowField in FS_FEEDBACK) moves both the live image (a gentle
  // heat-haze sway, faded out at the frame edges) and the trails (they stream along the same currents). Its strength
  // follows the dial predictably: linear from 0 (off) to the default, then a steeper curve to 150% (about 5x the
  // default sway, typically 2-3% of the screen height and too gently curved to ever fold or tear). Bass and builds breathe it
  // through a smoothed envelope (no per-sixteenth pumping); Motion smoothness slows its currents.
  const ms = viewMotionProtected(A) ? 0 : clamp(Number(S.motionSmooth) || 0, 0, 1), above = clamp((ms - 0.75) / 0.25, 0, 1);
  const wL = Math.max(0, Number(E.warp) || 0), wd = DEFAULTS.warp, ampL = wL <= wd ? wL / wd : Math.pow(wL / wd, 1.6);
  FLOW.breath = ease(FLOW.breath, 0.6 + 0.55 * (F.bassS ?? F.bass) * dz + 0.5 * F.build + 0.3 * F.drop, dt, 0.25 + 0.6 * ms);
  FLOW.t += dt * (0.1 + 0.2 * (F.levelS ?? F.level) + 0.35 * F.build + 0.25 * F.drop) * (0.6 + 0.4 * sp) * (1 - 0.5 * above);
  let decay = clamp(prof('decay') + (E.trails - 0.6) * 0.42 + F.breakdown * 0.05, 0, 0.975);
  decay = Math.pow(decay, step);
  const P = PG.fb, cur = RT.cur, nxt = 1 - cur;
  gl.useProgram(P.p);
  bindTex(0, RT.A.tex); ui(P, 'uA', 0);
  bindTex(1, RT.B.tex); ui(P, 'uB', 1);
  bindTex(2, RT.fb[cur].tex); ui(P, 'uPrev', 2);
  bindTex(5, (B || D.peek) ? RT.B.tex : RT.N.tex); ui(P, 'uN', 5);
  bindTex(6, RT.down[Math.min(2, BLOOM_LEVELS - 1)].tex); ui(P, 'uBlur', 6);
  if(cameraCalm>0&&dt>0&&step>0){
    let curl=warpG*warpProf*(0.05+0.06*F.bass*dz+0.08*F.build)*Math.min(step,2);
    const baseCurl=warpG*warpProf*.05,gain=calmGain(cameraCalm);
    curl=viewMotionIntegral(baseCurl+(curl/Math.min(step,2)-baseCurl)*gain,dt,cameraCalm,'curl')*(Math.min(step,2)/dt);
    u1(P,'uCurl',curl);
  }else{
  u1(P, 'uCurl', warpG * warpProf * (0.05 + 0.06 * F.bass * dz + 0.08 * F.build) * Math.min(step, 2));
  }
  u1(P, 'uStut', stutter);
  u2(P, 'uRes', RW, RH); u1(P, 'uTime', TIME % 36000); u1(P, 'uMix', B ? clamp(D.mix, 0.0001, 1) : 0); u1(P, 'uStyle', D.style);
  foldUpdate(A, B, dt); // v10: a fold change within a visit blooms out from the centre (uSymA0 -> uSymA over uSymT)
  const fN = foldNow(), fB = B ? foldOf(B) : (D.peek ? foldOf(D.peek) : 0);
  u1(P, 'uSymA', fN[0]); u1(P, 'uSymB', fB); u1(P, 'uSymRot', fN[1]); u2(P, 'uSymRot2', foldRot(fB), foldRot(FOLD.from));
  u1(P, 'uSymA0', FOLD.from); u1(P, 'uSymT', B || FOLD.glide ? 1 : FOLD.t);
  u2(P, 'uTC', D.tc[0], D.tc[1]);
  u1(P, 'uEcho', clamp(E.trails * 1.15 - 0.12, 0, 0.95) * lerp(fa.echo ?? 0.7, fbB.echo ?? 0.7, m));
  u1(P, 'uDroste', clamp(Math.max(F.build * 0.85, F.breakdown * 0.3) * dz + (lerp(fa.droste || 0, fbB.droste || 0, m)), 0, 0.9));
  u1(P, 'uPeek', D.peek && !B ? 1 : 0); u1(P, 'uHold', PTR.hold || 0);
  u1(P, 'uWin', prof('win') * (0.75 + 0.25 * E.trails));
  u1(P, 'uZoomFb', zoom); u1(P, 'uRotFb', rotv); u1(P, 'uDecay', decay);
  u1(P, 'uHueStep', (0.004 + F.hat * 0.02 * dz + F.drop * 0.03) * E.colorSpeed * step);
  u4(P, 'uFlow', [0.0068 * ampL * liveFor(live, 'warp') * FLOW.breath, warpG * warpProf * FLOW.breath * 1.7 * 0.0035 * step, FLOW.t, 1.7]);
  u2(P, 'uMouse', PTR.x, PTR.y); u4(P, 'uMouseV', [0, 0, 0, 0]); // v13b: no pointer stir
  u1(P, 'uRaw', DBG.raw ? 1 : 0);
  const safe = 0.3 + 0.7 * E.flashes;
  // Flash strength above its default also drives the snare spin and kick pulse harder, in every realm
  const flashBoost = sliderBoost('flashes'), liveFlash = liveFor(live, 'flashes');
  const spin = D.spin * Math.min(1, liveFlash * 1.3) * (1 + flashBoost)*screenMotion;
  u1(P, 'uSpin', Math.abs(spin) < 2e-4 ? 0 : spin); // below ~0.1 px of corner travel: no resample at all
  let pulse = (0.35 + 0.65 * liveFlash) * (F.kick * 0.02 * dz + Math.pow(1 - F.beat, 8) * F.conf * 0.012 * dz + F.drop * 0.04) * safe
    * (1 + 1.5 * flashBoost) * (viewMotionProtected(A) ? 1 : calmPulse(ms))
    * lerp(reactPulse(A), B ? reactPulse(B) : reactPulse(A), m); // v11: per-realm kick pulse and Audio sensitivity
  // v10: above the default Motion smoothness the (already reduced) pulse is low-passed too: a swell, not a jolt
  if (above > 0 && dt > 0) { const tau = 0.02 + 0.3 * above; PULSE_LP.x = ease(PULSE_LP.x, pulse, dt, tau); PULSE_LP.y = ease(PULSE_LP.y, PULSE_LP.x, dt, tau); pulse = PULSE_LP.y; }
  else { PULSE_LP.x = PULSE_LP.y = pulse; }
  u1(P, 'uPulse', pulse);
  u4(P, 'uHole', HOLE);
  u2(P, 'uMouseVel', 0, 0);
  drawTo(RT.fb[nxt], RW, RH);
  RT.cur = nxt;
  const src = RT.fb[nxt];

  // bloom chain
  const Dn = PG.down, Up = PG.up;
  gl.useProgram(Dn.p);
  let prev = src;
  for (let i = 0; i < BLOOM_LEVELS; i++) {
    const t = RT.down[i];
    bindTex(0, prev.tex); ui(Dn, 'uTex', 0);
    u2(Dn, 'uRes', t.w, t.h); u2(Dn, 'uTexel', 1 / prev.w, 1 / prev.h);
    u1(Dn, 'uPre', i === 0 ? 1 : 0); u1(Dn, 'uThresh', 0.72 - 0.32 * sliderBoost('bloom')); // more glow also catches dimmer light
    drawTo(t, t.w, t.h);
    prev = t;
  }
  // exposure meter reads the log-luminance that the down chain filtered into alpha
  const EX = PG.expo, ei = RT.ei;
  gl.useProgram(EX.p);
  bindTex(0, RT.down[BLOOM_LEVELS - 1].tex); ui(EX, 'uSrc', 0);
  bindTex(1, RT.expo[1 - ei].tex); ui(EX, 'uPrevE', 1);
  bridgeUpdate(); // v22: brightness bridge across scene changes (see EXPO_FAST)
  u1(EX, 'uRate', 1 - Math.exp(-dt / (TIME < EXPO_FAST.until ? EXPO_FAST.tau : 0.8))); u1(EX, 'uPack', HALF ? 0 : 1);
  u1(EX, 'uRef', EXPO_FAST.ref ? 1 : 0); u1(EX, 'uKey', prof('key')); EXPO_FAST.ref = false;
  drawTo(RT.expo[ei], 1, 1);
  RT.ei = 1 - ei;
  gl.useProgram(Up.p);
  let low = RT.down[BLOOM_LEVELS - 1];
  for (let i = BLOOM_LEVELS - 2; i >= 0; i--) {
    const t = RT.up[i];
    bindTex(0, low.tex); ui(Up, 'uTex', 0);
    bindTex(1, RT.down[i].tex); ui(Up, 'uBase', 1);
    u2(Up, 'uRes', t.w, t.h); u2(Up, 'uTexel', 1 / low.w, 1 / low.h);
    drawTo(t, t.w, t.h);
    low = t;
  }

  // Below native resolution the scene is first upscaled with EASU into a screen-size target (RT.hi); the composite
  // then sharpens it with RCAS at screen resolution. Supersampled frames keep the 2x2 average.
  let shown = src;
  if (RW < W && RT.hi && PG.easu) {
    gl.useProgram(PG.easu.p); bindTex(0, src.tex); ui(PG.easu, 'uSrc', 0); u2(PG.easu, 'uRes', W, H);
    drawTo(RT.hi, W, H); shown = RT.hi;
  }

  // composite to screen
  const shadowRecovery=lerp(A.R.shadowRecovery??0,B?(B.R.shadowRecovery??0):(A.R.shadowRecovery??0),m);
  const C = shadowRecovery>0?PG.shadowComp:PG.comp;
  gl.useProgram(C.p);
  bindTex(0, shown.tex); ui(C, 'uFb', 0);
  bindTex(1, RT.up[0].tex); ui(C, 'uBloom', 1);
  u2(C, 'uRes', W, H); u1(C, 'uTime', TIME % 36000);
  bindTex(2, RT.expo[1 - RT.ei].tex); ui(C, 'uExpo', 2);
  u2(C, 'uFbTexel', 1 / shown.w, 1 / shown.h);
  // RCAS strength: firm after an upscale (firmer the lower the render scale), gentle at native, off when supersampled
  const ratio = RW / W;
  u1(C, 'uSharp', ratio > 1.1 ? 0 : ratio < 0.999 ? clamp(0.5 + (1 - ratio) * 0.7, 0.5, 0.8) : 0.35); u1(C, 'uSS', ratio > 1.1 ? 0.25 : 0); u1(C, 'uKey', prof('key')); u1(C, 'uPack', HALF ? 0 : 1);
  u1(C, 'uPeek', D.peek && !D.nxt ? 1 : 0);
  // fine-line realms get less prism split at the default; above it the split grows quadratically (4.5x at 150%)
  u1(C, 'uChroma', sliderGain('chroma', 2) * (0.6 + 0.6 * dz) * (0.35 + 0.65 * liveFor(live, 'chroma')));
  // glow grows faster than linear above its default (about 3.7x at 160%)
  u1(C, 'uBloomAmt', DBG.raw ? 0 : sliderGain('bloom', 2.2) * (0.05 + 0.035 * F.level + 0.06 * F.kick * dz + 0.1 * F.drop));
  const fl = E.flashes;
  u1(C, 'uFlash', screenMotion*flashGain() * (F.drop * F.drop * 0.45 * (0.4 + 0.6 * liveFlash) + F.kick * 0.04 * dz));
  u1(C, 'uVig', 0.38); u1(C, 'uKick', F.kick * dz * (0.3 + 0.7 * fl)); u1(C, 'uSat', (1.14 + 0.15 * F.drop + 0.1 * F.build) * clamp(Number(S.saturation) || 0, 0, 2)); /* v10: Saturation */ u1(C, 'uExposure', 1.0 + F.build * 0.15);
  u1(C, 'uShadowRecovery', shadowRecovery); u1(C, 'uBridgeW', EXPO_FAST.w);
  const wv = WAVE_BUF; wv.fill(0);
  for (let i = 0; i < 6; i++) { const w = WAVES[i]; if (w) { wv[i * 4] = w.x; wv[i * 4 + 1] = w.y; wv[i * 4 + 2] = w.t * w.speed; wv[i * 4 + 3] = w.amp * Math.exp(-w.t * 1.2) * Math.min(1, 0.4 + dz * 0.6) * (1 - 0.8 * above); } }
  const lw = loc(C, 'uWaves[0]'); if (lw) gl.uniform4fv(lw, wv);
  u4(C, 'uHole', HOLE);
  drawTo(null, W, H);
}

