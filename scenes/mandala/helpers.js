// Stable multi-period anchors: [power, period, boundary angle, z.real, z.imag].
const DALA_MOTIFS = [[3,2,0.9791297103688188,-0.6826668390787445,0.37792918829730987],[3,3,1.398008730847458,0.48959122342234085,0.5748493046422384],[3,4,2.549926037163716,0.3431095807572898,0.4024288082601605],[4,2,1.4905111812031573,0.14145440360076914,0.9968785547507384],[4,3,1.2112585008840646,0.5801276571832402,0.7288094825907785],[4,4,0.6527531402458792,0.7521749162077414,0.43982019130507494],[5,2,0.4895648551844094,0.07426534091154333,0.7521198177180931],[5,3,0.9084438756630485,0.3179039174286107,0.7258444090546199],[5,4,0.4895648551844094,0.6245300199324516,-0.2962353725420494],[6,2,0.3916518841475275,0.26786218168225207,0.7148239044296213],[6,3,0.7267551005304388,0.7994728493275303,0.43163922315269976],[6,4,0.8943067087218944,0.31984988434507744,0.6275391156682818],[7,2,0.7452555906015786,0.6990451660954806,0.6330777768892503],[7,3,0.6056292504420323,0.5804078549186835,0.5710479573799561],[7,4,0.7452555906015786,0.610367099735922,0.6247728210606741],
  [2,3,2.6874,0.67456,0.23636],[2,4,1.6018,-0.47873,-0.59741],[2,2,1.059,-0.39178,-1.07403],[2,3,2.4858,0.51904,0.19491],[2,4,0.7644,0.51306,0.92103],
  [8,2,0.6087,0.75455,0.54347],[8,4,0.2857,0.85215,0.18873],[8,3,0.5882,-0.1095,0.65047]];

const dalaMul = (a, b) => [a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0]];
const dalaDiv = (a, b) => { const d = b[0] * b[0] + b[1] * b[1] || 1e-300; return [(a[0] * b[0] + a[1] * b[1]) / d, (a[1] * b[0] - a[0] * b[1]) / d]; };
// p steps of z -> z^n + c from z, with the derivative of the composite
function dalaOrbit(z, n, c, p) {
  let w = z, dw = [1, 0];
  for (let i = 0; i < p; i++) {
    let w1 = [1, 0];
    for (let k = 0; k < n - 1; k++) w1 = dalaMul(w1, w);
    dw = dalaMul([n * w1[0], n * w1[1]], dw);
    const wn = dalaMul(w1, w); w = [wn[0] + c[0], wn[1] + c[1]];
  }
  return { w, dw };
}
function dalaNewton(z, n, c, p, it) {
  for (let i = 0; i < it; i++) {
    const o = dalaOrbit(z, n, c, p), s = dalaDiv([o.w[0] - z[0], o.w[1] - z[1]], [o.dw[0] - 1, o.dw[1]]);
    z = [z[0] - s[0], z[1] - s[1]];
    if (!isFinite(z[0]) || !isFinite(z[1]) || Math.hypot(z[0], z[1]) > 4) return null;
    if (Math.hypot(s[0], s[1]) < 1e-15) break;
  }
  return z;
}
// a repelling cycle of exact period p, all of whose points stay clear of the critical point
function dalaCycleAt(z, n, c, p) {
  const o = dalaOrbit(z, n, c, p);
  if (Math.hypot(o.w[0] - z[0], o.w[1] - z[1]) > 1e-9) return null;
  for (let q = 1; q < p; q++) if (p % q === 0) { const w = dalaOrbit(z, n, c, q).w; if (Math.hypot(w[0] - z[0], w[1] - z[1]) < 1e-6) return null; }
  const pts = [z]; let w = z;
  for (let i = 1; i < p; i++) { w = dalaOrbit(w, n, c, 1).w; pts.push(w); }
  return { z, p, pts, lam: o.dw, L: Math.hypot(o.dw[0], o.dw[1]) };
}
function dalaFind(n, c, prefer, desired, anchor) {
  let best = null, wanted = null, bs = -1e9, ws = -1e9;
  for (let t = 0; t < 48; t++) {
    const p = desired && t < 24 ? desired : [2, 3, 4, 1][t % 4];
    const r = 0.2 + rand() * 1.1, a = rand() * 6.283;
    const start = t === 0 && anchor ? anchor : [r * Math.cos(a), r * Math.sin(a)];
    const z = dalaNewton(start, n, c, p, 60);
    if (!z) continue;
    const C = dalaCycleAt(z, n, c, p);
    if (!C || C.L < 1.6 || C.L > 80 || Math.min(...C.pts.map((q) => Math.hypot(q[0], q[1]))) < 0.12) continue;
    // prefer spiralling cycles (multiplier well off the real axis) that are not too far out
    const jit = 0.6 * rand(), cov = dalaCover(C, n, c);   // rand first: the shared random sequence stays as before
    if (cov < 0.12) continue;
    const arg = Math.abs(Math.atan2(C.lam[1], C.lam[0])), sc = Math.min(arg, 1.6) - 0.25 * Math.log(C.L) + jit + (prefer === undefined ? 0.16 : prefer) * (p - 1) + 2 * cov;
    if (sc > bs) { bs = sc; best = C; }
    if (p === desired && sc > ws) { ws = sc; wanted = C; }
  }
  return wanted || best;
}
// iterations until the critical orbit of z^n + cb escapes (it when it never does)
function dalaEsc(cb, n, it) {
  let u = cb;
  for (let i = 0; i < it; i++) { let u1 = [1, 0]; for (let j = 0; j < n - 1; j++) u1 = dalaMul(u1, u); const un = dalaMul(u1, u); u = [un[0] + cb[0], un[1] + cb[1]]; if (u[0] * u[0] + u[1] * u[1] > 1e8) return i; }
  return it;
}
// distance estimate from cb to the connectedness locus (0 when the critical orbit never escapes)
function dalaDE(cb, n, it) {
  let w = cb, dw = [1, 0];
  for (let i = 0; i < it; i++) {
    let w1 = [1, 0]; for (let j = 0; j < n - 1; j++) w1 = dalaMul(w1, w);
    const d = dalaMul([n * w1[0], n * w1[1]], dw); dw = [d[0] + 1, d[1]];
    const wn = dalaMul(w1, w); w = [wn[0] + cb[0], wn[1] + cb[1]];
    const r2 = w[0] * w[0] + w[1] * w[1];
    if (r2 > 1e12) { const r = Math.sqrt(r2); return r * Math.log(r) / Math.max(Math.hypot(dw[0], dw[1]), 1e-300); }
    if (!Number.isFinite(r2)) return 0;
  }
  return 0;
}
// how much of the view one cycle-length deep is lit (filaments, field-line glow or basin) on a coarse 8x5 grid:
// dives into cycles whose neighbourhood is mostly empty escape field showed a small star in black
function dalaCover(C, n, c) {
  const h = Math.pow(C.L, -1.5), px = h / 100; let lit = 0;
  for (let gy = 0; gy < 5; gy++) for (let gx = 0; gx < 8; gx++) {
    let x = C.z[0] + (gx - 3.5) / 3.5 * 1.7 * h, y = C.z[1] + (gy - 2) / 2 * 0.9 * h, dx = 1, dy = 0, e = 1;
    for (let i = 0; i < 250; i++) {
      let a = 1, b = 0; for (let k = 1; k < n; k++) { const t = a * x - b * y; b = a * y + b * x; a = t; }
      const t2 = n * (a * dx - b * dy); dy = n * (a * dy + b * dx); dx = t2;
      const t3 = a * x - b * y; y = a * y + b * x + c[1]; x = t3 + c[0];
      const r2 = x * x + y * y;
      if (r2 > 1e8) { const r = Math.sqrt(r2), de = r * Math.log(r) / Math.max(Math.hypot(dx, dy), 1e-300); e = de < 3 * px ? 1 : (de < 12 * px ? 0.35 : 0); break; }
    }
    lit += e;
  }
  return lit / 40;
}
// glass visits: a disc round the critical point that holds the attracting cycle's nearest point and stays inside the
// filled set; every basin orbit falls into it at last, so the basin tiles into jewels (pulled-back copies of it)
function dalaRhoGlass(n, c) {
  const it = (x, y, N) => { for (let i = 0; i < N; i++) { let a = x, b = y; for (let k = 1; k < n; k++) { const t = a * x - b * y; b = a * y + b * x; a = t; } x = a + c[0]; y = b + c[1]; if (x * x + y * y > 1e4) return null; } return [x, y]; };
  let w = it(0, 0, 300); if (!w) return 0;
  let dmin = 9; for (let i = 0; i < 64; i++) { w = it(w[0], w[1], 1); if (!w) return 0; dmin = Math.min(dmin, Math.hypot(w[0], w[1])); }
  let r = Math.min(0.6, Math.max(0.3, 1.6 * dmin));
  for (let s = 0; s < 8; s++) { let ok = true; for (let j = 0; j < 12 && ok; j++) { const a = j * 0.5236 + 0.1; if (!it(r * Math.cos(a), r * Math.sin(a), 200)) ok = false; } if (ok) return r; r *= 0.8; }
  return r;
}
// Phrase director: the dive alternates with pull-backs that reveal the cathedral of medallions round the set
// (breakdowns always pull back, otherwise now and then after 16 bars); builds close the cathedral back in and a drop
// plunges into the set. Rings counter-rotate on the bass and stream outward with the beat; a rare rush speeds them up.
function dalaDirector(c, F, dt, dtr, sp) {
  const bd = F.breakdown || 0, L = typeof BANDS !== 'undefined' ? BANDS.lv : null, lowB = L ? 0.5 * (L[0] + L[1]) : F.bass;
  if (c.bE === undefined) c.bE = lowB;
  c.bE += (lowB - c.bE) * (1 - Math.exp(-dt / (lowB > c.bE ? 0.15 : 0.7)));
  if ((F.onBar || F.onSceneBar)) {
    c.pb = (c.pb || 0) + 1;
    if (c.wide) {
      if (c.pb >= c.wideLen && bd < 0.5) { c.wide = 0; c.pb = 0; c.rush = 0; }
      else if (c.rush) c.rush--;
      else if (rand() < 0.12) c.rush = 2;
    } else if ((c.pb >= 16 && rand() < 0.18) || (bd > 0.6 && c.pb >= 2) || c.pb >= 40) {
      c.wide = 1; c.pb = 0; c.wideLen = rand() < 0.7 ? 8 : 16; c.wideZ = 0.3 + 0.28 * rand(); c.out = 1;
    }
  }
  const wT = c.wide ? Math.min(1, c.wideZ + 0.7 * F.build) : 1;
  c.wd = Math.exp(Math.log(c.wd || 1) + (Math.log(wT) - Math.log(c.wd || 1)) * (1 - Math.exp(-dt / (c.plunge ? 0.3 : 1.8))));
  if (c.plunge && c.wd > 0.97) c.plunge = 0;
  const rs = (0.012 + 0.2 * c.bE + 0.1 * F.build + (c.rush ? 0.15 : 0)) * sp * (1 - 0.6 * bd);
  c.rotE = ((c.rotE || 0) + dt * rs * c.rdE) % 1; c.rotO = ((c.rotO || 0) + dt * rs * c.rdO) % 1;
  c.flow = ((c.flow || 0) + dtr * (0.04 + 0.22 * F.build + (c.rush ? 0.5 : 0)) * (1 - 0.7 * bd) + dt * 0.05 * c.bE * sp) % 4;
}
function dalaFrame(V, F, dt) {
  const c = V.c, n = c.pw, sp = S.speed, dz = S.dose;
  if (c.lt === undefined) c.lt = V.trav;
  const dtr = Math.max(0, V.trav - c.lt); c.lt = V.trav;
  // c rides just outside the Multibrot main body: c = k (rho e^{i phi} - rho^n e^{i n phi}); the bass makes it breathe
  const rho = Math.pow(n, -1 / (n - 1)), rn = Math.pow(rho, n);
  const cAt = (t, k) => [k * (rho * Math.cos(t) - rn * Math.cos(n * t)), k * (rho * Math.sin(t) - rn * Math.sin(n * t))];
  const kAt = (t, add) => add + 1.035 + 0.02 * c.sb + 0.01 * Math.sin(t * 1.9 + c.sb * 5) - (c.glass ? 0.012 * F.build : 0);
  const KCAP = 0.14, KMIN = -0.03, DE0 = c.de0 || 0.003, inside = (t, add) => dalaEsc(cAt(t, kAt(t, add)), n, 200) >= 200;
  if (c.thT === undefined) c.thT = c.th;
  if (c.thDir === undefined) c.thDir = 1;
  // a visit keeps one topology: dust visits stay outside the connectedness locus, glass visits inside a bulb.
  // The boundary walk bounces off anything that would change it, because crossing it reorganises the whole set.
  // place c for this stretch of the boundary: glass visits sit mid-bulb (or just inside the main body),
  // dust visits sit DE0 outside the locus
  const bulbAt = (t) => {
    let k1 = -1, k2 = -1;
    for (let a = 0.001; a < 0.15; a += 0.002) { const inn = inside(t, a); if (inn && k1 < 0) k1 = a; if (!inn && k1 >= 0) { k2 = a; break; } }
    return k1 >= 0 && k2 > k1 + 0.006 ? [0.5 * (k1 + k2), k2 - k1] : null;
  };
  const settle = () => {
    if (c.glass) { const b = bulbAt(c.th); c.kAdd = b ? b[0] : -0.05; c.bulbW = b ? b[1] : 0.04; return; }
    for (let i = 0; i < 200; i++) { const d = dalaDE(cAt(c.th, kAt(c.th, c.kAdd)), n, 400); if (d > DE0 * 0.8 && d < DE0 * 1.25) break; const k0 = c.kAdd; c.kAdd = Math.min(KCAP, Math.max(KMIN, c.kAdd + (d < DE0 ? 0.0015 : -0.001))); if (c.kAdd === k0) break; }
  };
  if (!c.settled) {
    c.settled = 1;
    if (!c.glass && inside(c.th, KCAP)) { for (let i = 1; i < 40; i++) { const t = c.th + (i % 2 ? 1 : -1) * Math.ceil(i / 2) * 0.01; if (!inside(t, KCAP)) { c.th = c.thT = t; break; } } }
    settle();
  }
  if (F.onDrop) {
    // a drop cuts to a new stretch of the boundary (same topology) right on the beat, then blooms out from it
    let best = c.th + 0.5 + rand() * 0.8;
    for (let i = 0; i < 8; i++) { const t = c.th + 0.5 + rand() * 0.8; if (c.glass ? bulbAt(t) : !inside(t, KCAP)) { best = t; break; } }
    c.th = c.thT = best; settle();
    c.cyc = null; c.cc = null; c.dropCut = 1; c.bloom = 1; c.wrap = 0;
    c.wide = 0; c.pb = 0; c.plunge = 1; c.rush = 0;
  }
  dalaDirector(c, F, dt, dtr, sp);
  let thN = c.thT + c.thDir * dt * (c.glass ? 0.25 : 1) * (0.005 + F.level * 0.01 * dz + F.build * 0.03) * sp;
  if (c.bloom < 0.15 && (c.glass ? inside(c.th, c.kAdd) && !inside(thN, c.kAdd) : inside(thN, KCAP))) { c.thDir = -c.thDir; thN = c.thT; }
  c.thT = thN;
  c.th += (c.thT - c.th) * (1 - Math.exp(-dt / 0.9));
  // colour phase: the kick steps it, eased over ~0.1 s so the stripes slide instead of jumping
  if (c.phT === undefined) c.phT = c.ph;
  c.phT += dt * (0.4 + 1.6 * F.mid * dz) * sp + (F.onKick ? (c.kickPh ?? 0.35) * dz : 0);
  c.ph += (c.phT - c.ph) * (1 - Math.exp(-dt / 0.1));
  // geometry envelopes: low end with ~0.1 s attack and 0.8 s release, kick pump with 70 ms attack and 0.3 s release
  const lowIn = 0.6 * F.bass + 0.4 * F.sub;
  c.br = c.br === undefined ? lowIn : c.br + (lowIn - c.br) * (1 - Math.exp(-dt / (lowIn > c.br ? 0.1 : 0.8)));
  c.kp = (c.kp || 0) + (F.kick - (c.kp || 0)) * (1 - Math.exp(-dt / (F.kick > (c.kp || 0) ? 0.07 : 0.3)));
  // v11 fractal reactivity (geometry on smoothed envelopes only: >= 70 ms attack, release scaled by Motion smoothness):
  // per-band jewel bloom (each band swells its own generations of gems), ring traps swelling with the low mids,
  // a tempo-locked turn of the whole mandala, and a bass breath of the scale
  const BL = (typeof BANDS !== 'undefined' && BANDS.lv) || [0, 0, 0, 0, 0, 0, 0, 0], BO = (typeof BANDS !== 'undefined' && BANDS.on) || BL;
  const msm = Math.max(0, Math.min(1, S.motionSmooth ?? 0.75)), rel = 0.3 + 0.5 * msm;
  const env = (o, x, a) => o === undefined ? x : o + (x - o) * (1 - Math.exp(-dt / (x > o ? a : rel)));
  c.jbB = env(c.jbB, Math.min(1, Math.max(BO[0], BO[1], 0.8 * F.kick) * dz), 0.07);
  c.jbM = env(c.jbM, Math.min(1, Math.max(BO[2], BO[3], 0.6 * BO[4]) * dz), 0.08);
  c.jbH = env(c.jbH, Math.min(1, Math.max(BO[5], BO[6], 0.7 * BO[7]) * dz), 0.08);
  c.lmS = env(c.lmS, BL[2] * 0.6 + BL[3] * 0.4, 0.15);
  c.bS = env(c.bS, 0.6 * BL[1] + 0.4 * BL[0], 0.12);
  // tempo-locked rotation: a few degrees per beat, the beat surge eased out
  c.spT = (c.spT || 0) + dtr * 0.025 * (c.spDir ?? (c.spDir = c.sb < 0.5 ? 1 : -1)) * (1 + 0.5 * F.build);
  c.spin = (c.spin ?? c.spT) + (c.spT - (c.spin ?? c.spT)) * (1 - Math.exp(-dt / (0.25 + 0.6 * msm)));
  // snare: a ripple launched from the set outward across the field lines; hats: a counter that picks which satellites twinkle
  c.snT = (c.snT === undefined ? 9 : c.snT) + dt;
  if (F.onHit && F.hit > 0.4) { c.snT = 0; c.snA = Math.min(1, F.hit); }
  if (F.hat > 0.45 && F.hat > (c.hatP || 0) + 0.2) c.hc = ((c.hc || 0) + 1) % 251;
  c.hatP = F.hat;
  const th = c.th, cOf = (k) => cAt(th, k), kOf = () => kAt(th, c.kAdd);
  // the low end pushes c a little further out of the connectedness locus, so the set breathes (sparser on the bass);
  // the push is gated off whenever it would change the set's topology (bulb to dust), which is what used to shatter it
  const kb = kOf(), deb = dalaDE(cOf(kb), n, 400), kBass = (c.glass ? 0.06 * (c.bulbW || 0.04) : 1.3 * DE0) * c.br * dz * (c.bassG ?? 1);
  const flip = (deb > 0) !== (dalaDE(cOf(kb + kBass), n, 400) > 0); c.eb = deb > 0 ? 1 : 0;
  // dust visits: hold the critical orbit 50-90 iterations from escaping (rich, near the boundary), looking ahead to
  // the target angle so the controller lifts c over a bulb before the eased walk reaches it
  if (!c.glass) {
    // hold c a fixed distance outside the locus: there the dust is rich, yet the set moves smoothly (structurally
    // stable), whereas right on the boundary it reorganises at the slightest touch
    const de = deb; c.de = de;
    const step = de > 0 ? (DE0 - de) * 1.2 : 0.004;
    c.kAdd = Math.min(KCAP, Math.max(KMIN, c.kAdd + Math.max(-0.002, Math.min(0.004, step)) * Math.min(1, dt / 0.25)));
  }
  c.bg = (c.bg === undefined ? 1 : c.bg) + ((flip ? 0 : 1) - (c.bg === undefined ? 1 : c.bg)) * (1 - Math.exp(-dt / (flip ? 0.12 : 1.2)));
  // a drop loosens the set a little (it condenses back as the bloom decays); a bigger push turned it into sub-pixel
  // dust that read as a soft glowing blob for the first half second
  const k = kb + c.bg * kBass + (c.glass ? 0.05 * (c.bulbW || 0.04) : 0.7 * DE0) * c.bloom * c.bloom;
  let cc = cOf(k);
  // keep the dive locked on its repelling cycle while c moves (Newton continuation in double precision)
  let C = null;
  if (c.cyc) { const z = dalaNewton(c.cyc.z, n, cc, c.cyc.p, 6); if (z) C = dalaCycleAt(z, n, cc, c.cyc.p); if (C && (!Number.isFinite(C.L) || C.L < 1.45 || C.L > 128)) C = null; }
  if (!C) {
    if (c.cyc && c.cc) {
      // A failed continuation must not use an old cycle with a new polynomial.
      // Freeze its matching parameter while the musical bloom-out returns wide.
      c.out = 1; C = c.cyc; cc = c.cc.slice();
    } else { C = dalaFind(n, cc, c.periodBias, c.targetPeriod, c.anchor); c.Z = 0; }
  }
  if (!C) { C = { z: [0, 0], p: 1, pts: [[0, 0]], lam: [2, 0], L: 2 }; }
  // after a drop cut, start a little way down the new cycle and bloom out from there
  if (c.dropCut) { c.dropCut = 0; c.Z = 0.9 * Math.log(C.L); c.out = 1; }
  // unwrap the multiplier's argument so the spiral never jumps
  let arg = Math.atan2(C.lam[1], C.lam[0]);
  if (c.cyc && c.arg !== undefined && c.cyc.p === C.p) { while (arg - c.arg > Math.PI) arg -= 2 * Math.PI; while (arg - c.arg < -Math.PI) arg += 2 * Math.PI; }
  // back on the principal branch whenever we are near the surface; a spiral that has wound too far triggers a bloom-out
  if ((c.Z || 0) < 0.02) arg = Math.atan2(C.lam[1], C.lam[0]);
  if (Math.abs(arg) > 2 * Math.PI) c.out = 1;
  c.arg = arg; c.cyc = C; c.cc = cc.slice();
  const lnL = Math.log(C.L), p = C.p;
  const Kw = Math.max(1, Math.min(Math.ceil(Math.log(1500) / lnL), Math.floor(62 / p) - 1));
  // depth: e-folds per beat, slowed when the cycle spirals hard so the spin stays watchable
  c.bars = (c.bars || 0) + ((F.onBar || F.onSceneBar) ? 1 : 0); c.tOut = (c.tOut || 0) + dt;
  if (((F.onBar || F.onSceneBar) && c.bars % 32 === 0) || c.tOut > 80) c.out = 1;
  // depth is kept in e-folds, so the zoom stays smooth even while the cycle's multiplier swings as c breathes
  c.Z = c.Z || 0;
  if (c.out) {
    c.Z *= Math.exp(-dt / 0.4);
    if (c.Z < 0.04) { c.Z = 0; c.wrap = 0; c.out = 0; c.tOut = 0; const tp = rand() < 0.45 ? c.targetPeriod : 1 + Math.floor(rand() * 4), N = dalaFind(n, cc, c.periodBias, tp, tp === c.targetPeriod ? c.anchor : null); if (N) { c.cyc = N; c.arg = Math.atan2(N.lam[1], N.lam[0]); } }
  } else {
    const ef = (0.16 + 0.18 * F.build + 0.16 * F.drop) * Math.min(1, 0.55 * lnL / Math.max(Math.abs(arg), 0.01)) * (c.wide ? 0 : 1);
    // v13: while the hand pulls the wheel out, the inward dive holds (it would cancel part of the pull-back); it resumes
    // as soon as the zoom rests. Zooming in is left alone (dive and zoom go the same way).
    const zNow = Math.log(typeof PTR !== 'undefined' && PTR.zoom > 0 ? PTR.zoom : 1), zr = dt > 0 && Number.isFinite(c.zLog) ? (zNow - c.zLog) / dt : 0;
    c.zLog = zNow; c.zOut = (c.zOut || 0) + (Math.min(1, Math.max(0, -zr / 0.5)) - (c.zOut || 0)) * (1 - Math.exp(-dt / 0.08));
    c.Z += dtr * ef * (1 - 0.9 * c.zOut);
    // v14: a self-similar re-anchor, not a position jump: the screen map is rescaled by the cycle multiplier
    // while the orbit moves one period, so the image is invariant. Count the re-anchors so the shader can
    // unwrap orbit-step-based shading (jewel generations, satellite twinkle, on-set colour).
    if (c.Z / lnL > Kw + 1) { c.Z -= lnL; c.wrap = (c.wrap || 0) + 1; }
  }
  c.T = c.Z / Math.log(c.cyc.L);
  const Cy = c.cyc, T = c.T, lnL2 = Math.log(Cy.L), arg2 = c.arg;
  const mag = Math.exp(-T * lnL2), ang = -T * arg2;
  const Sc = 2.0 * (1 - 0.035 * c.kp * dz) * (1 - 0.05 * (c.bS || 0) * dz) * (1 - 0.15 * c.bloom) / c.wd, rot = c.orient + V.mt * 0.02 + (c.spin || 0);
  const lt = [mag * Math.cos(ang), mag * Math.sin(ang)];
  const A = dalaMul(lt, [Sc * Math.cos(rot), Sc * Math.sin(rot)]);
  const x = Math.min(T / 1.5, 1), m = 1 - x * x * (3 - 2 * x);
  const B = dalaMul(lt, [-Cy.z[0] * m, -Cy.z[1] * m]);
  const P = Cy.pts, q = (i) => P[i % P.length];
  c.laT += dt * 0.1 + (F.onHit && F.hit > 0.5 ? 1.1 : 0);
  // the light swings on snares; a pointer leans it gently toward itself
  const influence = Number.isFinite(PTR.inf) ? PTR.inf : PTR.inf;
  const laP = c.laT + 0.6 * influence * Math.sin(Math.atan2(PTR.y, PTR.x) - c.laT);
  c.la += (laP - c.la) * (1 - Math.exp(-dt / 0.25));
  c.bloom *= Math.exp(-dt / 0.7);
  // the critical jewel radius: the disc round 0 that maps to within half the critical value's distance from the set
  let w = cc, dw = [1, 0], esc = false, ei = 400;
  for (let i = 0; i < 400; i++) { let w1 = [1, 0]; for (let k = 0; k < n - 1; k++) w1 = dalaMul(w1, w); dw = dalaMul([n * w1[0], n * w1[1]], dw); const wn = dalaMul(w1, w); w = [wn[0] + cc[0], wn[1] + cc[1]]; const r = Math.hypot(w[0], w[1]); if (r > 1e6) { esc = true; ei = i; break; } }
  const cde = esc ? Math.hypot(w[0], w[1]) * Math.log(Math.hypot(w[0], w[1])) / Math.hypot(dw[0], dw[1]) : 0;
  // most visits stay in the dust (c outside the connectedness locus); 'glass' visits may fall into a bulb
  c.rho = (c.rho === undefined ? 0 : c.rho) + (Math.min(Math.pow(0.5 * cde, 1 / n), 0.75) - (c.rho || 0)) * (1 - Math.exp(-dt / 0.3));
  // jewel trap radius: dust visits use the ring trap's (critical value) radius; glass visits get their own disc
  if (c.glass) {
    c.rjT = (c.rjT || 0) - dt;
    if (c.rjT <= 0 || c.rjG === undefined) { c.rjT = 0.4; c.rjG = esc ? 0 : dalaRhoGlass(n, cc); }
    c.rj = c.rj === undefined ? c.rjG : c.rj + (c.rjG - c.rj) * (1 - Math.exp(-dt / 0.3));
  } else c.rj = c.rho;
  // mirror visits fold the screen into 2n wedges: turn the wedge toward the lit part of the view (the set's filaments,
  // field glow or basin), found on a coarse grid twice a second, so a deep mirror dive never folds empty black space
  if (c.mirror) {
    c.fT = (c.fT || 0) - dt;
    if (c.fT <= 0) {
      c.fT = 0.5; const zU0 = (typeof PTR !== 'undefined' && PTR.zoom > 0 ? PTR.zoom : 1) * (V.kz || 1), px = Math.hypot(A[0], A[1]) / zU0 / 200;
      let sx = 0, sy = 0;
      for (let gy = 0; gy < 7; gy++) for (let gx = 0; gx < 12; gx++) {
        const vx = (gx - 5.5) / 5.5 * 0.85 / zU0, vy = (gy - 3) / 3 * 0.47 / zU0, av = dalaMul(A, [vx, vy]);
        let x = P[0][0] + av[0] + B[0], y = P[0][1] + av[1] + B[1], dx = 1, dy = 0, e = 1;
        for (let i = 0; i < 200; i++) {
          let a = 1, b = 0; for (let k = 1; k < n; k++) { const tt = a * x - b * y; b = a * y + b * x; a = tt; }
          const t2 = n * (a * dx - b * dy); dy = n * (a * dy + b * dx); dx = t2;
          const t3 = a * x - b * y; y = a * y + b * x + cc[1]; x = t3 + cc[0];
          const r2 = x * x + y * y;
          if (r2 > 1e8) { const r = Math.sqrt(r2), de = r * Math.log(r) / Math.max(Math.hypot(dx, dy), 1e-300); e = de < 3 * px ? 1 : (de < 12 * px ? 0.35 : 0); break; }
        }
        sx += e * vx; sy += e * vy;
      }
      // the folded view shows screen angles [phi, phi + pi/2n]: aim its middle at the lit side
      if (Math.hypot(sx, sy) > 1e-3) { let tg = Math.atan2(sy, sx) - Math.PI / (4 * n); const cur = c.fph ?? tg; while (tg - cur > Math.PI) tg -= 2 * Math.PI; while (tg - cur < -Math.PI) tg += 2 * Math.PI; c.fphT = tg; }
    }
    if (c.fph === undefined) c.fph = c.fphT ?? 0;
    c.fph += ((c.fphT ?? c.fph) - c.fph) * (1 - Math.exp(-dt / 0.6));
  }
  const pk = (x) => 0.98 * Math.min(1, Math.max(0, x || 0));
  V.p1 = [n + pk(c.jbM), c.sd * (1 + 0.8 * F.build), c.ph, c.mirror ? 2 * n + 0.999 * (((c.fph || 0) / (2 * Math.PI)) % 1 + 1) % 1 : 0];
  V.p2 = [cc[0], cc[1], A[0], A[1]];
  V.p3 = [B[0], B[1], Cy.p * Math.floor(T), Cy.p + 16 * (c.wrap || 0) + pk(c.jbB)];
  V.p4 = [q(0)[0], q(0)[1], q(1)[0], q(1)[1]];
  V.p5 = [q(2)[0], q(2)[1], q(3)[0], q(3)[1]];
  // ease big jumps of the global hue (drops) so the colour sweeps instead of cutting; ordinary drift passes through
  const gh = (typeof D !== 'undefined' && Number.isFinite(D.hue)) ? D.hue : 0;
  if (c.hueE === undefined || Math.abs(gh - c.hueE) > 2) c.hueE = c.ghP = gh;
  const dgh = gh - c.ghP; c.ghP = gh;
  if (Math.abs(dgh) < 0.05) c.hueE += dgh;
  c.hueE += (gh - c.hueE) * (1 - Math.exp(-dt / 0.45));
  // the cathedral round the set: oculus just outside the set's radius bound, medallions sized to hold a whole copy
  const rc = Math.hypot(cc[0], cc[1]); let Rb = 1.6; for (let i = 0; i < 8; i++) Rb -= (Math.pow(Rb, n) - Rb - rc) / (n * Math.pow(Rb, n - 1) - 1);
  Rb = Math.max(1, Math.min(2.2, Rb || 1.5));
  // the cathedral shows when the view is pulled back (wheel zoom, kaleidoscope pull-back or a cathedral phrase): the
  // oculus slides in from beyond the screen edge, so at the default framing the dive keeps its open black field
  // it is needed only where the screen reaches past the set: farthest screen corner from the centre, in set radii
  const zU = (typeof PTR !== 'undefined' && PTR.zoom > 0 ? PTR.zoom : 1) * (V.kz || 1), zEff = c.wd * zU;
  const far = (Math.hypot(P[0][0] + B[0], P[0][1] + B[1]) + 1.02 * Math.hypot(A[0], A[1]) / zU) / Rb;
  const cvR = Math.min(1, Math.max(0, (far - 1.05) / 0.5)) * Math.min(1, Math.max(0, (0.97 - zEff) / 0.12)), cv = cvR * cvR * (3 - 2 * cvR);
  V.m2 = new Float32Array([1.08 * Rb * Math.exp(3.2 * (1 - cv)), c.catM, c.flow, c.rotE, c.rotO, c.catS, Rb / 0.48, c.catPhi, c.catZ]);
  V.m1 = new Float32Array([Cy.p * T, c.la, c.bloom, c.rho * (1 + 0.35 * (c.lmS || 0) * dz), c.snT, (c.snA || 0) * dz, (c.hc || 0) + pk(c.jbH), c.rj, Math.max(-0.5, Math.min(0.5, c.hueE - gh))]);
}
