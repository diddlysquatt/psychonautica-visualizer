// Colour families: [hue in degrees, pull toward that hue, pull toward it and its complement] (pulls sum < 1, so the
// palette remap stays monotonic). Each visit draws one from its seeded randoms; the original look (no pull) is two of
// the eight entries. The shader keeps the palette's own colours and only changes how often each one appears.
const GATE_FAMS = [ // ordered so that stepping three entries on (each drop) always lands on a contrasting family
  [0, 0, 0],          // original jewel rainbow
  [322, 0.8, 0],      // orchid: magenta, rose, violet
  [282, 0.8, 0],      // amethyst: violet, magenta, indigo
  [18, 0.8, 0],       // ember: scarlet, orange, rose
  [0, 0, 0],          // original jewel rainbow
  [12, 0.45, 0.5],    // coral with teal accents (complementary)
  [205, 0.8, 0],      // glacier: azure, cyan, ultramarine
  [45, 0.45, 0.5]     // gold and orange with sapphire accents (complementary)
];
// how much of the kick's broadband light surge is compressed (0 none, 1 flat)
const GATE_SQUASH = 0.85;
// unit chroma direction of a hue (degrees), as an RGB offset from grey
function gateHueDir(deg) {
  const h = (((deg % 360) + 360) % 360) / 60, f = h - Math.floor(h), i = Math.floor(h) % 6;
  const rgb = [[1, f, 0], [1 - f, 1, 0], [0, 1, f], [0, 1 - f, 1], [f, 0, 1], [1, 0, 1 - f]][i];
  const m = (rgb[0] + rgb[1] + rgb[2]) / 3, e = rgb.map((v) => v - m), l = Math.hypot(e[0], e[1], e[2]) || 1;
  return e.map((v) => v / l);
}
// the shader's pal(t), including the chroma-keeping crossfade between two palettes
function gatePal(pl, hue, t) {
  const cos = (P, i) => P.a[i] + P.b[i] * Math.cos(6.28318531 * (P.c[i] * t + P.d[i] + hue));
  const A = [0, 1, 2].map((i) => cos(pl.A, i));
  if (!(pl.t > 0)) return A;
  const B = [0, 1, 2].map((i) => cos(pl.B, i)), M = A.map((v, i) => v + (B[i] - v) * pl.t);
  const L = (v) => (v[0] + v[1] + v[2]) / 3, C = (v) => { const l = L(v); return Math.hypot(v[0] - l, v[1] - l, v[2] - l); };
  const lm = L(M), k = Math.min((C(A) + (C(B) - C(A)) * pl.t) / Math.max(C(M), 1e-3), 4);
  return M.map((v) => Math.max(lm + (v - lm) * k, 0));
}
// palette position (0..1) whose colour lies furthest toward the family hue
function gateFamPos(c, hue) {
  if (typeof palPair !== 'function') return 0;
  const pl = palPair(), e = gateHueDir(c.fh);
  let best = -1e9, bt = 0;
  for (let j = 0; j < 96; j++) {
    const t = j / 96, v = gatePal(pl, hue, t), m = (v[0] + v[1] + v[2]) / 3;
    const sc = (v[0] - m) * e[0] + (v[1] - m) * e[1] + (v[2] - m) * e[2];
    if (sc > best) { best = sc; bt = t; }
  }
  return bt;
}
function gateFam(s) {
  const fi = Math.floor((((s[0] * 7.31 + s[1] * 3.17 + s[3] * 5.53) % 1) + 1) % 1 * GATE_FAMS.length) % GATE_FAMS.length, F = GATE_FAMS[fi];
  return { fi, fh: F[0], fa: F[1], fb: F[2] };
}
// a drop moves the flower to another colour family (three entries on, so successive drops visit all of them);
// the change eases in over about a beat while the drop's shockwave and bloom cover it
function gateDropFamily(V) {
  const c = V.c, n = GATE_FAMS.length; let fi = (c.fi + 3) % n;
  if (GATE_FAMS[fi][1] + GATE_FAMS[fi][2] <= 0 && GATE_FAMS[c.fi][1] + GATE_FAMS[c.fi][2] <= 0) fi = (fi + 3) % n;
  c.fi = fi; const F = GATE_FAMS[fi];
  const fh = c.fh + ((((F[0] - c.fh) % 360) + 540) % 360 - 180); // shortest way round the hue circle
  c.fT = { fh, fa: F[1], fb: F[2] };
  if (V.tgt) Object.assign(V.tgt, c.fT); // a pending morph agrees with the new family instead of pulling back
}
// broadband spectrum level over the bands MUMM3 reads (0.03..0.83 of the log spectrum)
function gateBroad() {
  if (typeof specBytes === 'undefined') return 0;
  let m = 0, n = 0; for (let i = 8; i <= 212; i += 4) { m += specBytes[i]; n++; }
  return m / (n * 255);
}
