const oamFr = (x) => x - Math.floor(x);
// species of the foam being navigated (set by the visit before it steps): 0 FOAM = planes y,z; 1 LATTICE = x,y,z; 2 LACE = y
let oamSpc = 0;
function oamDE(x, y, z, k, N) {
  let s = 1;
  for (let i = 0; i < N; i++) {
    x = -1 + 2 * oamFr(0.5 * x + 0.5); y = -1 + 2 * oamFr(0.5 * y + 0.5); z = -1 + 2 * oamFr(0.5 * z + 0.5);
    const r2 = Math.max(x * x + y * y + z * z, 1e-12), q = k / r2;
    x *= q; y *= q; z *= q; s *= q;
  }
  let d = Math.abs(y);
  if (oamSpc < 1.5) d = Math.min(d, Math.abs(z));
  if (oamSpc === 1) d = Math.min(d, Math.abs(x));
  return d / s; // true-ish distance (the shader marches with a 0.25 safety factor)
}
const oN = (a) => { const l = Math.hypot(a[0], a[1], a[2]) || 1; return [a[0] / l, a[1] / l, a[2] / l]; };
const oDot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const oX = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const oAdd = (a, b, s) => [a[0] + b[0] * s, a[1] + b[1] * s, a[2] + b[2] * s];
function oRot(v, a, t) {
  const c = Math.cos(t), s = Math.sin(t), d = oDot(a, v) * (1 - c), x = oX(a, v);
  return [v[0] * c + x[0] * s + a[0] * d, v[1] * c + x[1] * s + a[1] * d, v[2] * c + x[2] * s + a[2] * d];
}
const oFold = (p) => p.map((x) => -1 + 2 * oamFr(0.5 * x + 0.5));
// march along dir: free distance (<= L), narrowest clearance after t0 and where it is, widest clearance after that
function oamProbe(p, dir, k, L, N, t0) {
  let t = 0, m = 1e9, tm = 0, after = 0, h = 0;
  for (let i = 0; i < 64; i++) {
    h = oamDE(p[0] + dir[0] * t, p[1] + dir[1] * t, p[2] + dir[2] * t, k, N);
    if (t > t0) { if (h < m) { m = h; tm = t; after = 0; } else if (h > after) after = h; }
    if (h < L * 0.002) return { f: t, m, tm, after, hit: true };
    t += Math.max(h * 0.6, L * 0.004); if (t > L) break;
  }
  return { f: Math.min(t, L), m, tm, after, hit: false };
}
function oamMakeCam(k, rnd) {
  let best = null, bd = -1;
  for (let i = 0; i < 800; i++) {
    const q = [rnd() * 2 - 1, rnd() * 2 - 1, rnd() * 2 - 1];
    const d = oamDE(q[0], q[1], q[2], k, 12);
    const sc = d > 0.04 && d < 0.1 ? d : d * 0.1;
    if (sc > bd) { bd = sc; best = q; }
  }
  const W = oN([rnd() - 0.5, rnd() - 0.5, rnd() - 0.5]);
  const U = oN(oX(W, Math.abs(W[1]) > 0.9 ? [1, 0, 0] : [0, 1, 0])), V = oX(U, W);
  const d = oamDE(best[0], best[1], best[2], k, 12);
  return { p: best, U, V, W, sc: d, d, level: 0, zoom: 0, off: [0, 0, 0], X: null, Xm: 0, cand: null, ho: 0, wob: rnd() * 100, rnd, through: 0, gx: 0, gy: 0, gr: 0, aim: W, ref: d * 0.5, offs: [], vis: 2 };
}
// Re-express the camera in the next level's coordinates (descend: the map's own fold + sphere inversion) or the
// previous level's (ascend: undo it). Locally either is a pure conformal magnification, so the picture does not change
// while the numbers become well conditioned again. Inversion reverses handedness, which the renderer does not mind.
function oamRebase(c, k, up) {
  const top = c.offs.length ? c.offs[c.offs.length - 1] : null;
  const ctr = up ? top : [0, 0, 0];
  const y0 = [c.p[0] - ctr[0], c.p[1] - ctr[1], c.p[2] - ctr[2]], J = k / Math.max(oDot(y0, y0), 1e-18), n = oN(y0);
  const refl = (v) => { const t = 2 * oDot(v, n); return [v[0] - t * n[0], v[1] - t * n[1], v[2] - t * n[2]]; };
  const inv = (x) => { const y = [x[0] - ctr[0], x[1] - ctr[1], x[2] - ctr[2]], s = k / Math.max(oDot(y, y), 1e-18); return [y[0] * s, y[1] * s, y[2] * s]; };
  const q = inv(c.p);
  let off = [0, 0, 0];
  if (up) c.offs.pop();
  else { const qf = oFold(q); off = [qf[0] - q[0], qf[1] - q[1], qf[2] - q[2]]; c.offs.push(off); if (c.offs.length > 96) c.offs.shift(); }
  const tr = (x) => { const y = inv(x); return [y[0] + off[0], y[1] + off[1], y[2] + off[2]]; };
  if (c.X) { c.X = tr(c.X); c.X0 = tr(c.X0); c.Xm *= J; c.X0m *= J; }
  if (c.cand) { c.cand.X = tr(c.cand.X); c.cand.m *= J; }
  c.p = tr(c.p); c.U = refl(c.U); c.V = refl(c.V); c.W = refl(c.W); c.aim = refl(c.aim);
  c.ref *= J; c.sc *= J; c.d *= J; c.level += up ? -1 : 1; c.zoom += Math.log(J); c.ho++;
  c.off = c.offs.length ? c.offs[c.offs.length - 1] : [0, 0, 0];
}
// which re-expression (if any) magnifies the view here without visible change: 1 = descend, -1 = ascend, 0 = none
function oamRescale(c, k) {
  if (c.sc > 0.006) {
    // grown large (a rise into open space): climb back out to the parent level, which shrinks the numbers again and keeps
    // the eye's surroundings exact (the frame is only approximate near the parent's inversion centre, far beyond the fog)
    if (c.sc > 0.018 && c.offs.length) {
      const o = c.offs[c.offs.length - 1], y = [c.p[0] - o[0], c.p[1] - o[1], c.p[2] - o[2]];
      const Ja = k / Math.max(oDot(y, y), 1e-18); if (Ja < 0.75 && Ja * c.sc > 0.008) return -1;
    }
    return 0;
  }
  const face = (p, m) => 1 - Math.max(Math.abs(p[0]), Math.abs(p[1]), Math.abs(p[2])) > m;
  const r = Math.hypot(c.p[0], c.p[1], c.p[2]), Jd = k / Math.max(r * r, 1e-18);
  let best = 0, bj = 1.0;
  // a pulled-back eye (zoom out) sees further, so the re-expression waits until it is exact over the whole pull
  const ps = c.sc * (1 + (c.pull || 0)), lo = 3e-4 / (1 + 0.1 * (c.pull || 0));
  if (Jd > bj && ((Jd > 1.2 && ps < 0.0035 * r && face(c.p, 30 * c.sc)) || c.sc < lo)) { best = 1; bj = Jd; }
  if (c.offs.length) {
    const o = c.offs[c.offs.length - 1], y = [c.p[0] - o[0], c.p[1] - o[1], c.p[2] - o[2]], ry = Math.hypot(y[0], y[1], y[2]), Ja = k / Math.max(ry * ry, 1e-18);
    const s = k / Math.max(ry * ry, 1e-18), pp = [y[0] * s, y[1] * s, y[2] * s]; // camera in the parent's coordinates
    if (Ja > bj && face(pp, 30 * c.sc * Ja) && ((Ja > 1.2 && ps < 0.0035 * ry) || c.sc < lo)) { best = -1; bj = Ja; }
  }
  return best;
}
// orthonormal pair perpendicular to unit d
function oPerp(d) { const a = oN(oX(d, Math.abs(d[1]) > 0.9 ? [1, 0, 0] : [0, 1, 0])); return [a, oX(d, a)]; }
// is X the middle of a real window (a rim all round it), not just a pass beside one obstacle?
function oamRim(X, dir, m, k, N, rnd) {
  const [a, b] = oPerp(dir); let n = 0; const ph = rnd() * 6.2832;
  for (let i = 0; i < 6; i++) {
    const t = ph + i * 1.0472, e = oN([a[0] * Math.cos(t) + b[0] * Math.sin(t), a[1] * Math.cos(t) + b[1] * Math.sin(t), a[2] * Math.cos(t) + b[2] * Math.sin(t)]);
    const pr = oamProbe(X, e, k, 8 * m, N, 0);
    if (pr.hit) n++;
  }
  return n;
}
// score a window candidate seen from the camera
let oamForwardWeight = 4;
function oamWin(c, pr, dir, k, N) {
  if (pr.m > 1e8) return -1e9;
  const okAfter = pr.hit ? pr.f > pr.tm + 2.5 * pr.m : pr.f >= pr.tm + 2 * pr.m;
  if (!okAfter || pr.after < 1.25 * pr.m || pr.tm < 1.5 * pr.m || pr.m > (c.mmax || 1.5) * c.sc || (!c.lost && pr.m < 0.12 * c.sc)) return -1e9;
  const X = oAdd(c.p, dir, pr.tm), rim = oamRim(X, dir, pr.m, k, N, c.rnd);
  if (rim < 4) return -1e9;
  const r = Math.log(pr.m / Math.min(c.sc, 1.6 * c.ref)) - Math.log(c.lost ? 0.8 : (c.shrink || 0.4)), big = Math.max(0, Math.log(pr.after / pr.m) - Math.log(4));
  return (oamForwardWeight || 4) * oDot(dir, c.W) - r * r * 0.6 - 0.06 * pr.tm / c.sc - 1.5 * big;
}
function oamStep(c, k, dt, adv, opts) {
  opts = opts || {}; oamForwardWeight = opts.fw || 4;
  const N = 12, rnd = c.rnd, L = (opts.L || 10) * c.sc;
  c.wob += dt; c.ho = 0;
  if (opts.noWin) { c.X = null; c.cand = null; }
  // 1) keep the current window target, re-centred by climbing the distance field within the window plane
  if (c.X) {
    const to = [c.X[0] - c.p[0], c.X[1] - c.p[1], c.X[2] - c.p[2]], dist = Math.hypot(to[0], to[1], to[2]), d0 = oN(to);
    if (oDot(to, c.W) < 0.3 * c.Xm) { c.X = null; c.through++; c.ref = c.Xm; }
    else {
      for (let it = 0; it < 3; it++) {
        const h = oamDE(c.X[0], c.X[1], c.X[2], k, N), e = Math.max(h * 0.05, 1e-10);
        let g = [oamDE(c.X[0] + e, c.X[1], c.X[2], k, N) - h, oamDE(c.X[0], c.X[1] + e, c.X[2], k, N) - h, oamDE(c.X[0], c.X[1], c.X[2] + e, k, N) - h].map((x) => x / e);
        g = oAdd(g, d0, -oDot(g, d0));
        const nx = oAdd(c.X, g, h * 0.3), dv = [nx[0] - c.X0[0], nx[1] - c.X0[1], nx[2] - c.X0[2]];
        if (Math.hypot(dv[0], dv[1], dv[2]) < 0.6 * c.X0m && h < 1.6 * c.X0m) { c.X = nx; c.Xm = h; }
      }
      const pr = oamProbe(c.p, oN([c.X[0] - c.p[0], c.X[1] - c.p[1], c.X[2] - c.p[2]]), k, dist + 2 * c.Xm, N, 0);
      if (pr.hit && pr.f < dist) c.X = null;
    }
  }
  // 2) look for the next window: random probes in a forward cone; keep the best candidate across frames
  if (c.cand && !opts.noWin) {
    const to = [c.cand.X[0] - c.p[0], c.cand.X[1] - c.p[1], c.cand.X[2] - c.p[2]], dist = Math.hypot(to[0], to[1], to[2]);
    const dir = oN(to), pr = oamProbe(c.p, dir, k, Math.max(L, dist * 1.5), N, 0.3 * c.d);
    const s = oamWin(c, pr, dir, k, N);
    c.cand = s > -1e8 ? { X: oAdd(c.p, dir, pr.tm), m: pr.m, s } : null;
  }
  for (let i = 0; i < (opts.noWin ? 0 : c.X ? 8 : 40); i++) {
    const ang = Math.acos(1 - rnd() * (1 - Math.cos(opts.cone || (c.X ? 0.9 : 1.25)))), a = rnd() * 6.2832, ca = Math.cos(ang), sa = Math.sin(ang);
    const dir = oN([c.W[0] * ca + (c.U[0] * Math.cos(a) + c.V[0] * Math.sin(a)) * sa, c.W[1] * ca + (c.U[1] * Math.cos(a) + c.V[1] * Math.sin(a)) * sa, c.W[2] * ca + (c.U[2] * Math.cos(a) + c.V[2] * Math.sin(a)) * sa]);
    const pr = oamProbe(c.p, dir, k, L, N, 0.3 * c.d);
    const s = oamWin(c, pr, dir, k, N);
    if (s > -1e8 && (!c.cand || s > c.cand.s)) c.cand = { X: oAdd(c.p, dir, pr.tm), m: pr.m, s };
  }
  c.nowin = c.X ? 0 : (c.nowin || 0) + dt;
  if (!c.X) c.ref *= Math.exp(dt * 0.25);
  c.ref = Math.max(0.15 * c.sc, Math.min(2 * c.sc, c.ref));
  if (!c.X && c.cand) { c.X = c.cand.X; c.Xm = c.cand.m; c.X0 = c.X; c.X0m = c.Xm; c.cand = null; }
  // how far the eye can see here (sets the fog): a few long probes in the view cone
  let vs = 0;
  for (let i = 0; i < 4; i++) {
    const ang = 0.7 * Math.sqrt(rnd()), a = rnd() * 6.2832, ca = Math.cos(ang), sa = Math.sin(ang);
    const dir = oN([c.W[0] * ca + (c.U[0] * Math.cos(a) + c.V[0] * Math.sin(a)) * sa, c.W[1] * ca + (c.U[1] * Math.cos(a) + c.V[1] * Math.sin(a)) * sa, c.W[2] * ca + (c.U[2] * Math.cos(a) + c.V[2] * Math.sin(a)) * sa]);
    vs += Math.log(oamProbe(c.p, dir, k, 400 * c.sc, N, 0).f / c.sc + 1);
  }
  c.vis += (vs / 4 - c.vis) * (1 - Math.exp(-dt * 1.5));
  // 3) aim: at the window, or (no window known) at the most open forward direction
  let aim = c.W;
  if (c.X) aim = oN([c.X[0] - c.p[0], c.X[1] - c.p[1], c.X[2] - c.p[2]]);
  else {
    // no window yet: skim the nearest foam (its bubbles stream past), creeping closer so the zoom never stops
    const h = c.d, e = Math.max(h * 0.02, 1e-10);
    const g = oN([oamDE(c.p[0] + e, c.p[1], c.p[2], k, N) - h, oamDE(c.p[0], c.p[1] + e, c.p[2], k, N) - h, oamDE(c.p[0], c.p[1], c.p[2] + e, k, N) - h]);
    let tg = oAdd(c.W, g, -oDot(c.W, g));
    if (Math.hypot(tg[0], tg[1], tg[2]) < 0.2) tg = oAdd(tg, c.U, 0.5);
    tg = oN(tg);
    const explore = c.lost || opts.explore;
    const want = Math.log(h / ((explore ? 2.5 : opts.noWin ? 2.2 : 0.8) * c.sc));   // v11: the skim keeps further off the wall (point-blank it was one smeared colour)
    // in a void (structure far away for our scale): head for the nearest foam
    aim = oN(oAdd(tg, g, Math.max(h > 3 * c.sc ? -1.5 : -0.6, Math.min(0.6, -want * 0.8 - 0.15))));
    // swerve if the way ahead is shut; when exploring, head for the most open way
    const ah = oamProbe(c.p, aim, k, 4 * c.sc, N, 0);
    c.swT = (c.swT || 0) + dt;
    if ((ah.hit || explore) && c.swA && c.swT < 0.6 && !oamProbe(c.p, c.swA, k, 3 * c.sc, N, 0).hit) aim = c.swA;   // v11: hold the chosen way for a while
    else if (ah.hit || explore) {
      let bs = -1e9;
      for (let i = 0; i < 16; i++) {
        const ang = 1.2 * Math.sqrt(rnd()), a = rnd() * 6.2832, ca = Math.cos(ang), sa = Math.sin(ang);
        const dir = oN([c.W[0] * ca + (c.U[0] * Math.cos(a) + c.V[0] * Math.sin(a)) * sa, c.W[1] * ca + (c.U[1] * Math.cos(a) + c.V[1] * Math.sin(a)) * sa, c.W[2] * ca + (c.U[2] * Math.cos(a) + c.V[2] * Math.sin(a)) * sa]);
        const pr = oamProbe(c.p, dir, k, 8 * c.sc, N, 0);
        const sc = pr.f / (8 * c.sc) + 0.5 * ca + 0.4 * oDot(dir, g);
        if (sc > bs) { bs = sc; aim = dir; }
      }
      c.swA = aim; c.swT = 0;
    }
  }
  // a wall close ahead (a narrowing wedge): slow down and turn harder toward the aim instead of pressing on into the cusp
  const fwd = oamProbe(c.p, c.W, k, 6 * c.sc, N, 0).f / c.sc;
  c.block = Math.max(0, Math.min(1, (1.4 - fwd) / 0.9));
  // v11: rates follow a smoothed block (the raw probe flips frame to frame near cusps); a hard block still reacts fast
  c.blockS = Number.isFinite(c.blockS) ? c.blockS + (c.block - c.blockS) * (1 - Math.exp(-dt * (c.block > c.blockS ? 6 : 1.5))) : c.block;
  const bS = Math.max(c.blockS, c.block > 0.85 ? c.block : 0);
  if (opts.bias) aim = oN(oAdd(oAdd(aim, c.U, opts.bias[0]), c.V, opts.bias[1]));
  const ms = Math.max(0, Math.min(1, opts.ms ?? 0.75));
  c.aim = oN(c.aim.map((x, i) => x + (aim[i] - x) * (1 - Math.exp(-dt * (opts.aimr || 3) * (0.9 - 0.4 * ms) * (1 + 2 * bS)))));
  // v11: turning is an angular velocity (camera-local, so rebases only flip its sign) that eases toward the wanted rate
  // and is capped, so the view never snaps from one turn into the opposite one; Motion smoothness slows and softens it
  if (!c.om) c.om = [0, 0, 0];
  const ax = oX(c.W, c.aim), sn = Math.hypot(ax[0], ax[1], ax[2]);
  let wd = [0, 0, (opts.roll || 0)];
  if (sn > 1e-7) {
    const ang = Math.atan2(sn, oDot(c.W, c.aim)), g = ang / sn * (opts.turn || 2) * (1.15 - 0.45 * ms) * (1 + 2 * bS);
    wd = [oDot(ax, c.U) * g, oDot(ax, c.V) * g, oDot(ax, c.W) * g + (opts.roll || 0)];
  }
  const wmax = (0.85 - 0.4 * ms) * (1 + 1.5 * bS);   // v12: calmer turn cap
  const wl = Math.hypot(wd[0], wd[1], wd[2]); if (wl > wmax) wd = wd.map((x) => x * wmax / wl);
  const tau = (0.3 + 0.85 * ms) / (1 + 2 * bS);   // v12: longer spring
  c.om = c.om.map((x, i) => x + (wd[i] - x) * (1 - Math.exp(-dt / tau)));
  const omW = [c.U[0] * c.om[0] + c.V[0] * c.om[1] + c.W[0] * c.om[2], c.U[1] * c.om[0] + c.V[1] * c.om[1] + c.W[1] * c.om[2], c.U[2] * c.om[0] + c.V[2] * c.om[1] + c.W[2] * c.om[2]];
  const oml = Math.hypot(omW[0], omW[1], omW[2]);
  if (oml > 1e-9) { const a = omW.map((x) => x / oml), t = oml * dt; c.W = oN(oRot(c.W, a, t)); c.U = oN(oRot(c.U, a, t)); c.V = oN(oRot(c.V, a, t)); }
  c.V = oN(oAdd(c.V, c.W, -oDot(c.V, c.W)));
  const hand = Math.sign(oDot(oX(c.U, c.V), c.W)) || 1;
  c.U = oX(c.V, c.W).map((x) => x * hand);
  // 4) advance (speed in units of the local scale = an exponential zoom); never closer than a safe margin
  // v12: the speed factor (slower while turning or near a wall) eases (0.35 s) instead of following each frame's probe;
  // the hard safety limits below still apply at once
  const ca = Math.max(0, oDot(c.W, c.aim)), sfW = (0.3 + 0.7 * ca * ca * ca) * (1 - 0.85 * bS);
  c.sf = Number.isFinite(c.sf) ? c.sf + (sfW - c.sf) * (1 - Math.exp(-dt / (sfW < c.sf ? 0.2 : 0.45))) : sfW;
  const step = Math.min(adv * Math.min(c.sc, 2.5 * c.ref) * c.sf, 0.4 * c.d, 0.2 * fwd * c.sc);
  c.p = oAdd(c.p, c.W, step);
  let d = oamDE(c.p[0], c.p[1], c.p[2], k, N);
  const minD = 0.3 * c.sc;
  if (d < minD) {
    const e = Math.max(d * 0.1, 1e-9);
    const g = oN([oamDE(c.p[0] + e, c.p[1], c.p[2], k, N) - d, oamDE(c.p[0], c.p[1] + e, c.p[2], k, N) - d, oamDE(c.p[0], c.p[1], c.p[2] + e, k, N) - d]);
    c.p = oAdd(c.p, g, (minD - d) * 0.6);
    d = oamDE(c.p[0], c.p[1], c.p[2], k, N);
  }
  // keep the camera in the base cell (the map is periodic); shift the targets with it
  const pf = oFold(c.p), sh = [pf[0] - c.p[0], pf[1] - c.p[1], pf[2] - c.p[2]];
  if (sh[0] || sh[1] || sh[2]) { const keepLampTarget = c.gapLampTargetId === c.X0; if (c.gapLampA) c.gapLampA = oAdd(c.gapLampA, sh, 1); if (c.gapLampB) c.gapLampB = oAdd(c.gapLampB, sh, 1); c.p = pf; if (c.offs.length) { const o = oAdd(c.offs[c.offs.length - 1], sh, 1); c.offs[c.offs.length - 1] = o; c.off = o; } else c.off0 = oAdd(c.off0 || [0, 0, 0], sh, 1); if (c.X) { c.X = oAdd(c.X, sh, 1); c.X0 = oAdd(c.X0, sh, 1); } if (keepLampTarget) c.gapLampTargetId = c.X0; if (c.cand) c.cand.X = oAdd(c.cand.X, sh, 1); }
  c.d = d;
  const dl = (Math.log(Math.max(d, 1e-12)) - Math.log(c.sc)) * (1 - Math.exp(-dt * 2.5));
  const gfast = c.lost || c.d > 3 * c.sc ? (c.d > 8 * c.sc ? 1.1 : 0.45) : opts.grow || 0.05;
  c.sc = Math.exp(Math.log(c.sc) + Math.min(dl, dt * (opts.dive && !c.lost && c.d < 20 * c.sc ? Math.min(gfast, 0.12) - 0.06 : gfast)));
  // at the top level there is no parent foam: growing further would only show the infinite base planes
  const cap = c.level <= 0 ? 0.12 : 0.04;
  if (c.sc > cap) c.sc = Math.max(cap, c.sc * Math.exp(-dt * 0.4));
  // a dive that has found no window for a while creeps closer to the foam, so it always keeps descending
  if (opts.dive && !c.X && (c.nowin || 0) > 3 && c.d < 20 * c.sc) c.sc *= Math.exp(-dt * 0.25);
  if (opts.keepPre) c.pre = { p: [...c.p], U: [...c.U], V: [...c.V], W: [...c.W], sc: c.sc, level: c.level, off: [...c.off], has: c.offs.length > 0 };
  for (let i = 0; i < 3; i++) { const r = oamRescale(c, k); if (!r) break; oamRebase(c, k, r < 0); if (c.om) c.om = c.om.map((x) => -x); }
  c.lost = c.sc < 3e-4;
  return c;
}

// Lighting-only transport wrapper. Original navigator arithmetic/RNG is unchanged.
const oamRebaseWithoutLanterns=oamRebase;
oamRebase=function(c,k,up){
  const ctr=up&&c.offs.length?c.offs[c.offs.length-1].slice():[0,0,0];
  const keep=c.gapLampTargetId===c.X0;
  const a=c.gapLampA?c.gapLampA.slice():null,b=c.gapLampB?c.gapLampB.slice():null;
  oamRebaseWithoutLanterns(c,k,up);
  const shift=up?[0,0,0]:c.off;
  const transport=p=>{const v=p.map((x,i)=>x-ctr[i]),q=k/Math.max(oDot(v,v),1e-18);return v.map((x,i)=>x*q+shift[i]);};
  if(a){c.gapLampA=transport(a);if(!(up?c.gapLampA:a).every(x=>Math.abs(x)<1.-1e-9))c.gapLampAValid=false;}
  if(b){c.gapLampB=transport(b);if(!(up?c.gapLampB:b).every(x=>Math.abs(x)<1.-1e-9))c.gapLampBValid=false;}
  if(keep)c.gapLampTargetId=c.X0;
};
function oamGapLights(c,dt){
  dt=Math.max(0,dt);if(!Number.isFinite(c.gapLampMix))c.gapLampMix=1;
  const sameTarget=c.X&&c.gapLampTargetId===c.X0;
  // A completed handoff prevents rapid target changes from flashing extra fixtures.
  if(c.X&&(!c.gapLampA||sameTarget||c.gapLampMix>.985||c.gapLampAValid===false)){
    if(!sameTarget){
      c.gapLampB=c.gapLampA?c.gapLampA.slice():null;c.gapLampBValid=c.gapLampAValid!==false;c.gapLampAValid=true;
      c.gapLampPreviousGain=c.gapLampA?c.gapLampMix*(c.gapLampDecay||1):0;
      c.gapLampMix=0;c.gapLampTargetId=c.X0;
    }
    c.gapLampA=c.X.map((x,i)=>x+c.V[i]*c.Xm*.08);c.gapLampAge=0;
  }else if(c.gapLampA)c.gapLampAge=(c.gapLampAge||0)+dt;
  if(c.gapLampA){
    c.gapLampMix+=(1-c.gapLampMix)*(1-Math.exp(-dt*2.6));
    c.gapLampDecay=Math.exp(-Math.max(0,(c.gapLampAge||0)-4)*.55);
    if(c.gapLampDecay<.015){c.gapLampA=null;c.gapLampB=null;c.gapLampTargetId=null;c.gapLampMix=1;}
  }else c.gapLampDecay=0;
}
function oamLanternRange(p,c){
  const distance=Math.hypot(...p.map((x,i)=>x-c.p[i]))/Math.max(c.sc,1e-12);
  const t=Math.max(0,Math.min(1,(distance-18)/10));return 1-t*t*(3-2*t);
}
// Lens aim (not the flight path): lean the view toward the richest nearby structure, away from blank voids and
// point-blank walls. Kept as small offsets in the camera's own basis, so self-similar rebases (reflections) cannot jump it.
function oamLook(c, cam, k, dt, t) {
  if (!Number.isFinite(c.lx)) { c.lx = 0; c.ly = 0; }
  let ax = 0, ay = 0, wsum = 0.6;
  for (let i = 0; i < 7; i++) {
    const ang = 0.62 * Math.sqrt((i + 0.5) / 7), a = i * 2.39996 + t * 0.21, ca = Math.cos(ang), sa = Math.sin(ang);
    const ex = Math.cos(a) * sa, ey = Math.sin(a) * sa;
    const dir = oN([cam.W[0] * ca + cam.U[0] * ex + cam.V[0] * ey, cam.W[1] * ca + cam.U[1] * ex + cam.V[1] * ey, cam.W[2] * ca + cam.U[2] * ex + cam.V[2] * ey]);
    const f = oamProbe(cam.p, dir, k, 160 * cam.sc, 12, 0).f / cam.sc;
    const l = Math.log(Math.max(f, 1e-3) / 9), s = Math.exp(-l * l / 1.3);
    ax += ex / ca * s; ay += ey / ca * s; wsum += s;
  }
  let wx = ax / wsum, wy = ay / wsum; const m = Math.hypot(wx, wy), lim = 0.26;
  if (m > lim) { wx *= lim / m; wy *= lim / m; }
  const ms = Math.max(0, Math.min(1, (typeof S !== 'undefined' && S.motionSmooth) ?? 0.75)), e = 1 - Math.exp(-dt * (0.95 - 0.45 * ms));
  if (!Number.isFinite(c.lx2)) { c.lx2 = c.lx; c.ly2 = c.ly; }
  c.lx2 += (wx - c.lx2) * e; c.ly2 += (wy - c.ly2) * e;   // v11: two cascaded easings: the lean starts and stops softly
  c.lx += (c.lx2 - c.lx) * e; c.ly += (c.ly2 - c.ly) * e;
  const W = oN(oAdd(oAdd(cam.W, cam.U, c.lx), cam.V, c.ly));
  const U = oN(oAdd(cam.U, W, -oDot(cam.U, W)));
  const V = oN(oAdd(oAdd(cam.V, W, -oDot(cam.V, W)), U, -oDot(cam.V, U)));
  return { U, V, W };
}
// Zoom out (and the realm's own wide shots): the eye backs away from the camera along the freest direction behind it.
// Each frame the actual segment is probed, so the eye never ends up behind a sheet; the offset lives in the view basis in
// local-scale units, so the self-similar rebases (reflections) cannot jump it. Returns the eye position.
function oamPull(c, cam, R, k, dt, wantA, wantZ) {
  // v13: the route's own pull (wantA) eases; the wheel's pull (wantZ) follows PTR.zoom at once (the engine spring already
  // smooths it), so the picture stops when the hand stops
  const want = wantA + (wantZ || 0);
  if (!c.pb) c.pb = { d: [0, -0.25, -1], L: 0 };
  const P = c.pb, toW = (d) => oN([R.U[0] * d[0] + R.V[0] * d[1] + R.W[0] * d[2], R.U[1] * d[0] + R.V[1] * d[1] + R.W[1] * d[2], R.U[2] * d[0] + R.V[2] * d[1] + R.W[2] * d[2]]);
  const L = Math.max(want, 0) * 1.35 * cam.sc;
  // look for a freer way back every few frames (back, back-up, back-down, back-left, back-right)
  P.t = (P.t || 0) + dt;
  if (want > 0.5 && P.t > 0.25) {
    P.t = 0; let best = null, bf = -1;
    const C = [[0, -0.25, -1], [0, 0.55, -1], [0, -0.75, -1], [0.7, 0.1, -1], [-0.7, 0.1, -1], [0, 1, -0.35], [0, -1, -0.35], [1, 0, -0.35], [-1, 0, -0.35], [0.6, 0.6, -0.6], [-0.6, -0.6, -0.6]];
    for (const d of C) { const f = oamProbe(cam.p, toW(d), k, L, 12, 0).f * (d[0] === 0 && d[1] === -0.25 ? 1.15 : 1); if (f > bf) { bf = f; best = d; } }
    P.goal = best;
  }
  if (P.goal) { const e = 1 - Math.exp(-dt * 0.55); if (!P.d2) P.d2 = P.d.slice(); P.d2 = P.d2.map((x, i) => x + (P.goal[i] - x) * e); P.d = P.d.map((x, i) => x + (P.d2[i] - x) * e); }
  const dir = toW(P.d), free = want > 0.05 ? oamProbe(cam.p, dir, k, L + 2 * cam.sc, 12, 0).f / cam.sc : 0;
  // the eye may back away further than the free path: the march then starts on a sphere around the eye that just
  // reaches the free part (a near clip), so the foam in between is cut away and the eye looks out over a carved hall
  if (!Number.isFinite(P.La)) P.La = Number.isFinite(P.L) ? P.L : 0;
  P.La += (wantA - P.La) * (1 - Math.exp(-dt * (wantA < P.La ? 3 : 0.9)));
  P.L = Math.max(0, P.La + (wantZ || 0));
  const clip = Math.max(0, P.L - Math.max(0.75 * free, 1.2));
  P.clip = Number.isFinite(P.clip) ? P.clip + (clip - P.clip) * (1 - Math.exp(-dt * 14)) : clip;
  P.clip = Math.min(P.clip, Math.max(0, P.L - 0.8));
  cam.pull = P.L;
  return oAdd(cam.p, dir, P.L * cam.sc);
}
// The director: which way the journey goes (route), how the foam is lit (style), which species, and the rare events.
// Routes: 0 DIVE (thread ever smaller windows), 1 CRUISE (windows of the same size: a chain of chambers), 2 RISE (head for
// open space and bigger windows: the foam opens up into vast chambers), 3 SKIM (no window: race along the nearest wall)
const OAM_ROUTES = [
  { shrink: 0.4, mmax: 1.5, grow: 0.05, speed: 1, roll: 0, pull: 0 },
  { shrink: 1.0, mmax: 2.4, grow: 0.15, speed: 0.9, roll: 0.05, pull: 2 },
  { shrink: 2.4, mmax: 6, grow: 0.45, speed: 0.75, roll: -0.04, pull: 7, explore: true },
  { shrink: 0.6, mmax: 1.5, grow: 0.05, speed: 1.0, roll: 0.08, pull: 1, noWin: true },
];
const OAM_ZMAX = 6;
