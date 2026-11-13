
// ESCHR helpers. Penrose stair ring with tread 1 and rise 1/q whose turn rises K: corners count as steps, so
// nA - nC = K (x and y each advance K) and (2nA + 2nC + 4)/q = K (z advances K).
// Families: 0 Penrose stairs, 1 Penrose aqueduct, 2 both, 3 the great tribar, 4 the Spindle (turning drums).
const ESCHR_FAMS = 5, ESCHR_PALS = 8;
const ESCHR_TS = [3.2, 2.8, 3.6, 3], ESCHR_WS = [1, 1.12, .92, 1.22];
const ESCHR_ST = [[12, 6, 2.5], [10, 6, 2.5], [14, 6, 3], [16, 5, 3]], ESCHR_AQ = [25, 28, 22, 31];
function eschrRing(v) {
  const [K, q, w] = ESCHR_ST[v], sm = K * q / 2 - 2;
  return { K, q, w, r: 1 / q, nA: (sm + K) / 2, nC: (sm - K) / 2, N: 2 * sm + 4 };
}
function eschrStep(R, m) {
  const s1 = R.nA + 1, s2 = 2 * R.nA + 2, s3 = 2 * R.nA + R.nC + 3, LA = R.w + R.nA, hw = R.w / 2;
  const sx = m >= s1 ? 1 : 0, sy = m >= s2 ? 1 : 0, sz = m >= s3 ? 1 : 0, q = sx + sy + sz;
  const k = m - (sx * s1 + sy * (s2 - s1) + sz * (s3 - s2)), fl = k >= .5 ? 1 : 0;
  const dx = Math.round(Math.cos(q * Math.PI / 2)), dy = Math.round(Math.sin(q * Math.PI / 2));
  const Px = sx * LA - sz * (R.w + R.nC), Py = sy * LA;
  return [Px + dx * fl * (hw + k - .5), Py + dy * fl * (hw + k - .5), (m + 1) * R.r];
}
const eschrProj = (x, y, z) => [.8660254 * (x - y), -.5 * (x + y) + z];
// framing centre kc, foot line yb (where the figure's columns end in the mist) and half width cw (level units)
function eschrFrame(fam, v) {
  if (fam === 4) { const w = ESCHR_WS[v]; return { kc: [0, 9 * w], yb: -7 * w, cw: 10 * w }; }
  const R = eschrRing(v), LA = R.w + R.nA, LC = R.w + R.nC, hw = R.w / 2, L = fam === 2 ? 20 : ESCHR_AQ[v];
  const P = [eschrProj(0, 0, R.r), eschrProj(LA, 0, (R.nA + 2) * R.r), eschrProj(LA, LA, (2 * R.nA + 3) * R.r), eschrProj(LA - LC, LA, (2 * R.nA + R.nC + 4) * R.r)];
  const ks = [P.reduce((a, p) => a + p[0], 0) / 4, P.reduce((a, p) => a + p[1], 0) / 4];
  const o = fam === 2 ? [LA * .95, -LA * 1.25, 0] : [0, 0, 0], po = eschrProj(o[0], o[1], o[2]);
  const a = eschrProj(1.5, 1.5, 3), b = eschrProj(L - 1.5, 1.5, 3), c = eschrProj(L - 1.5, L - 1.5, 3);
  const kt = [(a[0] + b[0] + c[0]) / 3 + po[0], (a[1] + b[1] + c[1]) / 3 + 1.5 + po[1]];
  const ys = -(LA + hw) + (2 * R.nA + 3) * R.r - 2.6, ya = po[1] - L - 4;
  if (fam === 3) { const T = ESCHR_TS[v] * 7.5; return { kc: [.289 * T, -.45 * T], yb: -T - 2, cw: .62 * T + 3 }; }
  if (fam === 1) return { kc: kt, yb: ya, cw: .866 * L + 3 };
  if (fam === 2) return { kc: [(ks[0] + kt[0]) / 2, (ks[1] + kt[1]) / 2], yb: Math.min(ys, ya), cw: Math.abs(kt[0] - ks[0]) / 2 + .866 * (LA + hw) + 3 };
  return { kc: ks, yb: ys, cw: .866 * (LA + hw) + 2.5 };
}
// the seat on a colossus where the hero stands: the top of its pedestal (mirrors gP in esPass), screen coordinates
function eschrSeat(fam, v) {
  if (fam === 4) { const w = ESCHR_WS[v]; return eschrProj(5.5 * w, 5.5 * w, 1.2 * 4.55 * w); }
  if (fam === 3) { const L = 7.5 * ESCHR_TS[v]; return eschrProj(L * .4, L * .45, -1); }
  if (fam === 1) { const L = ESCHR_AQ[v]; return eschrProj(L * .4, L * .55, -2); }
  const R = eschrRing(v), LA = R.w + R.nA;
  return eschrProj(LA * .35, LA * .62, -3);
}
// level units per screen height that frame each figure at uZoom 1 (the figure fills the frame)
function eschrScale(fam, v) {
  const f = eschrFrame(fam, v);
  return Math.max(16, (f.kc[1] - f.yb) * (fam === 3 ? 2.1 : 1.85), f.cw * 1.1);
}
// the lead walker's screen offset from the framing centre: the camera drifts after it round the loop
function eschrLead(fam, v, step) {
  const c = eschrFrame(fam, v).kc;
  if (fam === 4) return [0, 0];
  if (fam === 3) {
    const s = ESCHR_TS[v], L = 7.5 * s, w = .75 * s, l1 = L - w, l3 = L - 2 * w, l4 = 1.4 * w, d = ((step * .025) % 1) * (2 * l1 + l3 + l4);
    const P = d < l1 ? [d, w, 2 * w] : d < 2 * l1 ? [l1, w + d - l1, 2 * w] : d < 2 * l1 + l3 ? [l1, L, 2 * w + d - 2 * l1] : [l1, L, L];
    const p = eschrProj(P[0], P[1], P[2]);
    return [p[0] - c[0], p[1] - c[1]];
  }
  if (fam === 1) {
    const L = ESCHR_AQ[v], gP = L - 2, lA = gP - 1, lB = L - 2, lD = L - 2.2, T = lA + lB + 1.2 + lD;
    const d = ((step * .022) % 1) * T;
    const P = d < lA ? [L - 1, gP - d, 2] : d < lA + lB ? [L - 1 - (d - lA), 1, 2] : d < lA + lB + 1.2 ? [1, 1 + d - lA - lB, 2] : [1 + gP, 2.35 + gP, L - 2];
    const p = eschrProj(P[0], P[1], P[2]);
    return [p[0] - c[0], p[1] - c[1]];
  }
  const R = eschrRing(v), m = ((Math.floor(step) % R.N) + R.N) % R.N, P = eschrStep(R, m), p = eschrProj(P[0], P[1], P[2]);
  return [p[0] - c[0], p[1] - c[1]];
}
// the twin rings only come in the two smaller ring sizes
function eschrVar(fam, v) { return fam === 2 ? (v & 1 ? 1 : 0) : v; }
// curated palettes: stone, shadow tint, accent A, accent B, water, glow A, glow B, paving
const ESCHR_PAL = [
  [[.96,.66,.38],[.30,.06,.42],[.95,.20,.25],[.08,.75,.72],[.05,.35,.70],[1,.80,.25],[.30,.95,1],[.82,.45,.35]],   // angkor dusk
  [[.22,.72,.55],[.04,.13,.38],[1,.75,.15],[.98,.30,.35],[.10,.25,.80],[1,.90,.40],[.40,1,.80],[.50,.82,.60]],       // jade and gold
  [[.20,.38,.95],[.10,.03,.40],[1,.72,.18],[.95,.20,.70],[.08,.85,.85],[1,.85,.30],[1,.40,.85],[.45,.55,.95]],       // lapis
  [[.40,.24,.86],[.12,.04,.36],[1,.15,.55],[.55,1,.20],[.10,.50,1],[1,.30,.70],[.50,1,.30],[.42,.30,.78]],          // obsidian neon
  [[.92,.42,.22],[.25,.05,.35],[.05,.70,.70],[1,.82,.35],[.10,.55,.80],[1,.70,.25],[.30,.95,.90],[.85,.55,.40]],     // terracotta teal
  [[.93,.85,.72],[.40,.08,.35],[.85,.08,.20],[.12,.30,.85],[.08,.20,.60],[1,.50,.20],[.40,.60,1],[.85,.72,.58]],     // bone and crimson
  [[.55,.30,.85],[.12,.04,.45],[.10,.75,.45],[1,.65,.10],[.25,.80,.95],[.80,.40,1],[1,.75,.20],[.65,.45,.85]],       // amethyst malachite
  [[1,.55,.45],[.35,.08,.50],[.22,.15,.75],[1,.90,.25],[.10,.75,.85],[1,.90,.30],[.30,.90,1],[1,.70,.55]],          // sunset coral
];
// blend two palettes keeping chroma (a fade never greys out), turn the hue a little, pack each colour as 24-bit RGB
function eschrPack(a, b, t, hue) {
  const out = new Float32Array(9), co = Math.cos(hue), si = Math.sin(hue), k = 0.57735;
  for (let i = 0; i < 8; i++) {
    const A = ESCHR_PAL[a][i], B = ESCHR_PAL[b][i];
    let c = [0, 1, 2].map(j => A[j] + (B[j] - A[j]) * t);
    const la = (A[0] + A[1] + A[2]) / 3, lb = (B[0] + B[1] + B[2]) / 3, lm = (c[0] + c[1] + c[2]) / 3;
    const ca = Math.hypot(A[0] - la, A[1] - la, A[2] - la), cb = Math.hypot(B[0] - lb, B[1] - lb, B[2] - lb);
    const cm = Math.hypot(c[0] - lm, c[1] - lm, c[2] - lm), ct = ca + (cb - ca) * t, g = Math.min(ct / Math.max(cm, 1e-3), 3);
    c = c.map(v => lm + (v - lm) * g);
    const d = k * (c[0] + c[1] + c[2]);
    const r = [0, 1, 2].map(j => c[j] * co + (k * (c[(j + 1) % 3] - c[(j + 2) % 3])) * si + k * d * (1 - co));
    const q = r.map(v => Math.round(Math.max(0, Math.min(1, v)) * 255));
    out[i] = q[0] * 65536 + q[1] * 256 + q[2];
  }
  return out;
}
