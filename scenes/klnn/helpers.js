/* ---- KLNN helpers: a beat-locked walker through the corridor network of the pseudo-Kleinian.
   Naves run along x at (y,z) = (Cy(2j+1), Cz(2m+1)) and shafts along y at (x,z) = (Cx(2i+1), Cz(2m+1)), each
   about 0.6 wide whatever the inversion size, meeting at junctions every 2C. The walker goes forward along x
   and now and then dives down a shaft, rounding each corner with a quarter circle. ---- */
const KLNN_R = 0.42;
function klnnChoose(w, d) {
  w.run++;
  // while the great hall is open the walker keeps to its nave (the hall is carved along x), leaving a shaft at once
  if (w.noDive) return d[1] === 0 ? d : [w.hd, 0, 0];
  if (d[1] === 0) { if (w.run >= 2 && rand() < 0.45) { w.run = 0; return [0, -1, 0]; } return d; }
  if (w.run >= 1 && rand() < 0.6) { w.run = 0; return [w.hd, 0, 0]; }
  return d;
}
function klnnWalker(C, hd) {
  const w = { C, hd, node: [C[0], C[1], C[2]], dir: [hd, 0, 0], nd: null, pcs: [], s: 0, run: 0, pt: false };
  w.nd = klnnChoose(w, w.dir);
  return w;
}
function klnnExtend(w) {
  const C = w.C, d = w.dir, nd = w.nd, R = KLNN_R;
  const L = 2 * (d[0] !== 0 ? C[0] : C[1]);
  const sa = w.pt ? R : 0, turn = nd[0] !== d[0] || nd[1] !== d[1], sb = turn ? R : 0;
  const N = w.node, N1 = [N[0] + d[0] * L, N[1] + d[1] * L, N[2]];
  w.pcs.push({ k: 0, a: [N[0] + d[0] * sa, N[1] + d[1] * sa, N[2]], d, len: L - sa - sb });
  if (turn) w.pcs.push({ k: 1, c: [N1[0] + (nd[0] - d[0]) * R, N1[1] + (nd[1] - d[1]) * R, N1[2]], d0: d, d1: nd, len: R * Math.PI / 2 });
  w.node = N1; w.pt = turn; w.dir = nd; w.nd = klnnChoose(w, nd);
}
function klnnAt(w, s) {
  for (let i = 0; ; i++) {
    while (i >= w.pcs.length) klnnExtend(w);
    const q = w.pcs[i];
    if (s <= q.len) {
      if (q.k === 0) return { p: [q.a[0] + q.d[0] * s, q.a[1] + q.d[1] * s, q.a[2]], t: q.d };
      const th = s / KLNN_R, co = Math.cos(th), si = Math.sin(th);
      return {
        p: [q.c[0] + (q.d0[0] * si - q.d1[0] * co) * KLNN_R, q.c[1] + (q.d0[1] * si - q.d1[1] * co) * KLNN_R, q.c[2]],
        t: [q.d1[0] * si + q.d0[0] * co, q.d1[1] * si + q.d0[1] * co, 0]
      };
    }
    s -= q.len;
  }
}
function klnnAdvance(w, ds) {
  w.s += ds;
  for (;;) {
    if (!w.pcs.length) klnnExtend(w);
    if (w.s <= w.pcs[0].len) break;
    w.s -= w.pcs[0].len; w.pcs.shift();
  }
  // the lattice repeats every 4C, so shifting everything by whole periods is invisible and keeps floats small
  // (x shifts by 24 periods: the great hall's rib rhythms (major arch every 3 or 4, band cycle of 8) all divide 24)
  const Px = 4 * w.C[0], Py = 4 * w.C[1];
  const sx = Math.abs(w.node[0]) > 24 * Px ? Math.round(w.node[0] / (24 * Px)) * 24 * Px : 0;
  const sy = Math.abs(w.node[1]) > 2 * Py ? Math.round(w.node[1] / Py) * Py : 0;
  if (sx || sy) {
    const f = (v) => { v[0] -= sx; v[1] -= sy; };
    f(w.node); w.pcs.forEach((q) => f(q.k === 0 ? q.a : q.c));
    // the lattice is periodic but the architecture's slow spatial drift (inversion size, rim radius) is not: keep the
    // total shift so the drift phases stay continuous (before v11 every shift changed the whole building in one frame)
    w.ox = (w.ox || 0) + sx; w.oy = (w.oy || 0) + sy;
  }
}
const KLNN_BOX = [[0.808, 0.8, 1.137], [0.808, 0.808, 1.167], [0.92436, 0.90756, 0.92436], [0.9, 0.9, 1.3], [0.78, 0.8, 1.1]];
// structure families: [twist angle, shift x, shift y, shift z] applied after every inversion (mirrors the GLSL table):
// 0 the classic rose-window nave, 1 ribbed trumpets (shifted inversion), 2 spiral rosettes (twisted, boxes 2 and 3 only)
const KLNN_VAR = [[0, 0, 0, 0], [0, 0, 0, 0.14], [0, 0.07, 0, 0.08]];
function klnnFamily(bi, r) { return bi === 2 || bi === 3 ? (r < 0.4 ? 0 : r < 0.7 ? 1 : 2) : (r < 0.55 ? 0 : 1); }
// CPU copy of the distance estimate (no relief): keeps off-axis camera shots clear of the walls
// the great hall's void (mirrors kHall in GLSL): > 0 inside
// the hall's section: half-height .9R, half-width asp x that (gothic, barrel, slender); > 0 inside (approximate)
const KLNN_ASP = [0.65, 0.9, 0.5];
function klnnHall(p, C, R, ay, asp) { const b = 0.9 * R, a = b * (asp || 0.65); return (1 - Math.hypot((p[2] - C[2]) / a, (p[1] - ay) / b)) * a; }
function klnnDE(p, C, S0, sa, ph, R0, e, v, hall, kBr) {
  // ph: [inversion-size drift phase, rim drift phase] (a number means the old single phase)
  const pS = Array.isArray(ph) ? ph[0] : ph, pR = Array.isArray(ph) ? ph[1] : ph * 0.7;
  const w = Math.sin(p[0] * 0.43 + p[1] * 0.31 + p[2] * 0.19 + pS);
  const S = clamp(S0 + sa * w, 0.6, 0.885);
  const Rr = R0 + 0.06 * Math.cos(p[0] * 0.27 - p[1] * 0.37 + p[2] * 0.21 + pR);
  // v is the (continuous) structure family: interpolate the table rows, as the GLSL does
  const vi = clamp(Math.floor(v || 0), 0, 1), vf = clamp((v || 0) - vi, 0, 1), A = KLNN_VAR[vi], B = KLNN_VAR[vi + 1];
  const V = A.map((x, i) => x + (B[i] - x) * vf), tc = Math.cos(V[0]), ts = Math.sin(V[0]);
  let x, y, z, DF = 1;
  const fold = (u, c) => { let m = (u + c) % (4 * c); if (m < 0) m += 4 * c; return c - Math.abs(m - 2 * c); };
  x = fold(p[0], C[0]); y = fold(p[1], C[1]); z = fold(p[2], C[2]);
  for (let i = 0; i < 8; i++) {
    x = 2 * clamp(x, -C[0], C[0]) - x; y = 2 * clamp(y, -C[1], C[1]) - y; z = 2 * clamp(z, -C[2], C[2]) - z;
    const k = Math.max(S / Math.max(x * x + y * y + z * z, 1e-6), 1);
    x *= k; y *= k; z *= k; DF *= k;
    const nx = x * tc - y * ts + V[1]; y = x * ts + y * tc + V[2]; x = nx; z += V[3];
  }
  const rxy = Math.hypot(x, y);
  const slab = (Math.abs(rxy * z) - e) / Math.sqrt(x * x + y * y + z * z + e);
  // v18: the openings pierced in the great discs (mirrors kdeR in GLSL)
  const aN = (((Math.atan2(y, x) * 2.5464791 + 0.5) % 1) + 1) % 1, dBar = Math.abs(aN - 0.5) * 0.3926991 * rxy, b0 = clamp((DF - 2.6) / 3.4, 0, 1);
  const cut = Math.min(dBar - (kBr ?? 0.05), Rr - 0.03 - rxy) - b0 * b0 * (3 - 2 * b0) * 0.4;
  const d = Math.max(Math.max(rxy - Rr, slab), cut) / DF;
  return hall && hall[0] > 0.02 ? Math.max(d, klnnHall(p, C, hall[0], hall[1], hall[2])) : d;
}
// palette temperature families (mirrors kPalOne): warm = ruby, synth sunset, copper; cool = amethyst, malachite,
// sapphire, jade, acid. A palette change always crosses to the other family.
const KLNN_WARM = [2, 4, 7], KLNN_COOL = [0, 1, 3, 5, 6];
function klnnNextPal(pi, r) { const f = KLNN_WARM.includes(pi) ? KLNN_COOL : KLNN_WARM; return f[Math.min(f.length - 1, Math.floor(r * f.length))]; }
// critically damped spring, the exact closed-form step: position and velocity arrays follow a target vector.
// om is the spring's angular frequency; ~om/4.7 s is its settle time. Stable at any dt. Everything the camera does goes through one.
function klnnSpring(x, v, tgt, om, dt) {
  const ex = Math.exp(-om * dt);
  for (let i = 0; i < x.length; i++) { const d = x[i] - tgt[i], c = v[i] + om * d; x[i] = tgt[i] + (d + c * dt) * ex; v[i] = (v[i] - om * c * dt) * ex; }
}
