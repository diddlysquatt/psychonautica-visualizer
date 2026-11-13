/* ============================== quality =============================== */
// Auto keeps one relative cost budget per realm (1 = native resolution at the chosen detail) and spends it in this
// order: resolution down to AUTO_RES_FLOOR of native (barely visible after the EASU upscale), then the fractal detail
// the realm shaders get (an internal multiplier shown in the render info line, never below 0.5x effective), and only
// as a last resort resolution below the floor. Recovery runs the same ladder upward.
// MOBILE: the resolution floor is lower (the EASU upscale hides it on a small, dense screen) and Auto starts from a
// smaller budget (MOBILE_START_BUDGET: ~0.7 resolution at ~0.6x detail) and climbs only if the phone keeps up.
const AUTO_RES_FLOOR = MOBILE ? 0.7 : 0.85, AUTO_START = AUTO_RES_FLOOR * AUTO_RES_FLOOR;
const Q = { scale: 0.75, acc: 0, n: 0, t: 0, ceil: 1, ceilT: 0, realmScale: REALMS.map(() => null), last: 0, lastRi: -1, detailNow: 1 };
if (MOBILE) Q.lastScale = MOBILE_START_BUDGET;
function autoDetailFloor() { return clamp(0.5 / Math.max(0.5, E.detail), 0.03, 1); }
// cost budget -> [resolution scale, detail multiplier]
function budgetSplit(b) {
  const f2 = AUTO_START, dmin = autoDetailFloor();
  if (b >= f2) return [Math.sqrt(b), 1];
  if (b >= f2 * dmin) return [AUTO_RES_FLOOR, b / f2];
  return [Math.max(0.3, Math.sqrt(b / dmin)), dmin];
}
// A realm not measured yet starts from the budget the last realm settled at instead of restarting low and climbing
// through several reallocations on every switch; a slow realm still drops within one measurement window.
function realmStartScale(ri) { return Q.lastScale || AUTO_START; }
// above 1 the frame is rendered larger than the screen and averaged down (supersampling) for recording on big GPUs
const QUALITY = { low: 0.42, medium: 0.58, high: 0.78, ultra: 1.0, cinema: 1.5, insane: 2.0, extreme: 3.0, offline: 4.0 };
const PIXEL_BUDGET = { auto: 8.5e6, low: 8.5e6, medium: 8.5e6, high: 8.5e6, ultra: 36e6, cinema: 36e6, insane: 36e6, extreme: 64e6, offline: 96e6 };
function autoBudget() {
  if (D.nxt || D.peek || !D.cur) return Q.lastScale || AUTO_START; // hold through a crossfade or a peek
  const ri = D.cur.ri;
  if (Q.realmScale[ri] == null) Q.realmScale[ri] = realmStartScale(ri);
  Q.lastRi = ri;
  return (Q.lastScale = Q.realmScale[ri]);
}
function targetScale() {
  if (E.quality !== 'auto') return QUALITY[E.quality] || 0.75;
  if (OFF.on) return 1; // a virtual clock has no meaningful realtime performance signal
  return budgetSplit(autoBudget())[0];
}
function qualityUpdate(dt) {
  if (OFF.on || E.quality !== 'auto' || !D.cur) { Q.detailNow = 1; return; }
  // the detail multiplier eases (a step in loop counts would pop); resolution changes are discrete anyway
  Q.detailNow = ease(Q.detailNow, budgetSplit(autoBudget())[1], dt, 0.5);
  if (D.nxt || D.peek) { Q.acc = 0; Q.n = 0; Q.t = 0; return; } // two realms render; don't charge that to either
  Q.acc += dt; Q.n++; Q.t += dt; Q.ceilT -= dt;
  if (Q.t < 1.2) return;
  const avg = Q.acc / Q.n; Q.acc = 0; Q.n = 0; Q.t = 0;
  const ri = D.cur.ri;
  if (Q.realmScale[ri] == null) Q.realmScale[ri] = realmStartScale(ri);
  let b = Q.realmScale[ri];
  // a display or power mode capped at 30 Hz never gets faster by lowering the cost: detect that and stop
  if (Q.probe && Q.probe.ri === ri) {
    if (avg > Q.probe.avg * 0.93) { b = Q.probe.scale; Q.capDt = avg * 1.12; }
    Q.probe = null;
  }
  const slow = Math.max(1 / 47, Q.capDt || 0);
  if (avg > slow) { Q.ceil = b * 0.92; Q.ceilT = 20; Q.probe = { ri, avg, scale: b }; b *= avg > slow * 1.45 ? 0.61 : 0.77; }
  else if (avg < Math.max(1 / 57, (Q.capDt || 0) * 0.8) && !D.nxt) { const cap = Q.ceilT > 0 ? Q.ceil : 1; b = Math.min(cap, b * 1.1025); }
  Q.realmScale[ri] = clamp(b, 0.09 * autoDetailFloor(), 1);
}

// v22: around a scene change the exposure meter's time constant is tau (s) instead of 0.8 (during it and 1.5 s after), and the
// composite's brightness bridge (uBridgeW) holds the picture toward the outgoing scene's screen level: weight 1 through the
// change, then a 2.5 s ease to 0. ref: this frame the meter stores the outgoing scene's level (the change has just begun).
const EXPO_FAST = { until: -1e9, tau: 0.22, ref: false, was: false, end: -1e9, w: 0, out: 2.5 };
function bridgeUpdate() {
  const on = !!D.nxt && D.nxt.R !== (D.cur && D.cur.R); // a reseed of the same scene needs no bridge
  if (on && !EXPO_FAST.was) EXPO_FAST.ref = true;
  if (D.nxt) EXPO_FAST.until = TIME + 1.5;
  if (!on && EXPO_FAST.was) EXPO_FAST.end = TIME;
  EXPO_FAST.was = on;
  const x = clamp((TIME - EXPO_FAST.end) / EXPO_FAST.out, 0, 1);
  EXPO_FAST.w = on ? 1 : 0.5 + 0.5 * Math.cos(Math.PI * x);
}
function resize() {
  const dpr = Math.min(window.devicePixelRatio || 1, MOBILE ? MOBILE_DPR : 2); // MOBILE: lower DPR cap
  const cw = Math.max(1, Math.floor(canvas.clientWidth * dpr)), ch = Math.max(1, Math.floor(canvas.clientHeight * dpr));
  if (cw !== W || ch !== H) { W = canvas.width = cw; H = canvas.height = ch; }
  // MOBILE: cap the scene's pixel count (render targets are ~60 bytes/pixel in total) to fit phone GPU memory
  const requested = targetScale(), maxPix = Math.min(PIXEL_BUDGET[E.quality] || 8.5e6, MOBILE ? ((QUALITY[E.quality] || 0) > 1 ? MOBILE_PIX_SS : MOBILE_PIX) : Infinity);
  const mts = MAXTEX || 4096;
  const sc = Math.min(requested, Math.sqrt(maxPix / (W * H)), mts / W, mts / H);
  Q.requestedScale = requested; Q.appliedScale = sc;
  Q.limit = sc < requested - 1e-6 ? (W * requested > mts || H * requested > mts ? 'GPU texture limit' : Math.round(maxPix / 1e6) + ' MP budget') : '';
  // Scale both axes together: a texture-size cap must not squash the camera's aspect ratio.
  const rw = Math.max(1, Math.floor(W * sc)), rh = Math.max(1, Math.floor(H * sc));
  if (rw !== RW || rh !== RH) {
    const request = rw + 'x' + rh;
    if (Q.failedRequest === request) { Q.appliedScale = RW / W; if (OFF.on) throw new Error(Q.error || 'GPU target allocation failed'); return; }
    try { allocTargets(rw, rh); Q.error = ''; Q.failedRequest = null; }
    catch (error) {
      Q.error = error.message; Q.failedRequest = request; Q.appliedScale = RW / W;
      if (OFF.on || !RW || !RH) throw error;
      toast(error.message + ' The previous render size is still active.');
    }
  }
  // the EASU upscale target (screen size) whenever the scene renders below native; kept while the screen size holds
  if (RW < W && (!RT.hi || RT.hi.w !== W || RT.hi.h !== H) && Q.hiFailed !== W + 'x' + H) {
    freeTarget(RT.hi); RT.hi = null;
    try { RT.hi = makeTarget(W, H); } catch (error) { Q.hiFailed = W + 'x' + H; } // falls back to a bilinear stretch
  }
}

