// six spectrum bands (log spectrum 0 = 28 Hz .. 1 = 16 kHz) plus a seventh slot that follows the dominant pitch
const cymaEdges = [.03, .17, .31, .45, .59, .73, .9];
function cymaAnalyse(c) {
  if (typeof specBytes === 'undefined') return;
  for (let b = 0; b < 6; b++) {
    const i0 = Math.floor(cymaEdges[b] * NB), i1 = Math.floor(cymaEdges[b + 1] * NB);
    let s = 0, w = 0, wx = 0;
    for (let i = i0; i < i1; i++) { const v = specBytes[i] / 255; s += v; const v2 = v * v * v; w += v2; wx += v2 * (i - i0) / (i1 - i0); }
    c.en[b] = s / (i1 - i0); c.ce[b] = w > 1e-5 ? wx / w : .5;
  }
  // dominant pitch: strongest smoothed bin between ~60 Hz and ~6 kHz
  let bi = 0, bv = -1;
  for (let i = Math.floor(.12 * NB); i < Math.floor(.84 * NB); i++) {
    const v = specBytes[i] * 2 + specBytes[i - 1] + specBytes[i + 1];
    if (v > bv) { bv = v; bi = i; }
  }
  c.pitch = bi / NB;
}
// mode number for a band: low bands simple figures, high bands intricate; the pitch inside the band, its loudness,
// the build and a recent drop all push the mode up
function cymaTarget(c, b) {
  const lift = c.buildS * 9 + c.dropK * 2.5;
  if (b === 6) return Math.round(2 + clamp((c.pitch - .12) / .72, 0, 1) * 10 + lift * 1.7);
  return Math.round(1 + b * 1.3 + c.ce[b] * 3 + c.en[b] * 2 + lift);
}
function cymaRetarget(c, b, force) {
  const s = c.bs[b];
  if (s.t < 1 && !force) return;
  s.a = s.t >= .5 ? s.b : s.a;
  const k = Math.max(1, Math.min(34, cymaTarget(c, b)));
  const v = ((s.b % 8) + 1 + Math.floor(rand() * 7)) % 8;
  s.b = k * 8 + v; if (s.b === s.a) s.b = k * 8 + ((v + 3) % 8);
  s.t = 0;
}
function cymaPick(n, cur) { let v; do { v = Math.floor(rand() * n); } while (v === cur && n > 1); return v; }
// w4: eight ENERGY SCHEMES in place of the old five-hue palettes. The plates and the floor are dark materials now (bronze, dark
// gold, lapis, jade, basalt); what the sound lights is energy in two hue families per scheme: stops 0..2 = the energy (deep,
// full, hot), stops 3..4 = its accent (full, deep). Even rings take the energy, odd rings the accent. Blended, hue-nudged and
// prepared here, then packed 8 bits per channel (sqrt space, range 0..2) into one float per stop for the shader
const cymaPals = [
  [[1,.52,.1],[1,.7,.18],[1,.86,.5],[.1,.8,.74],[.06,.5,.78]],        // molten gold, teal
  [[.2,.42,1],[.36,.66,1],[.62,.85,1],[1,.72,.26],[1,.54,.14]],       // moon blue, gold
  [[.04,.55,.38],[.12,.82,.56],[.5,1,.78],[1,.64,.2],[1,.46,.12]],     // deep jade, amber
  [[.04,.58,.5],[.1,.84,.72],[.5,1,.9],[.66,.42,1],[.42,.22,.9]],     // sea green, violet (no warm hue at all)
  [[.5,.22,1],[.72,.44,1],[.86,.7,1],[1,.76,.3],[1,.5,.16]],          // violet, pale gold
  [[.05,.7,.9],[.16,.92,.9],[.6,1,.92],[1,.64,.5],[1,.48,.42]],       // turquoise, rose gold (a true rose gold: the first version read as plain red)
  [[1,.6,.2],[1,.8,.42],[1,.93,.72],[.55,.3,1],[.34,.16,.85]],        // white gold, deep violet
  [[.14,.3,1],[.3,.5,1],[.6,.75,1],[1,.86,.5],[1,.62,.2]]             // lapis, white gold
];
function cymaPrep(A, B, t, hue, out) {
  const h = .12 * Math.sin(hue * 6.2831853)   /* w4: a small drift only, so a scheme keeps its two families */, ca = Math.cos(h), sa = Math.sin(h), k = .57735, o = (1 - ca) / 3;
  const m0 = ca + o, mp = o + k * sa, mn = o - k * sa;
  // v19: every palette reaches the same light level. Each stop keeps its own hue, but a palette of deep blues and violets
  // used to sit in the dark next to a palette of yellows: one palette-wide gain, shared by all five stops, evens them out
  const st = [];let lm = 0;
  for (let i = 0; i < 5; i++) {
    const a = A[i], b = B[i];
    const x = Math.pow(a[0] + (b[0] - a[0]) * t, 2.2), y = Math.pow(a[1] + (b[1] - a[1]) * t, 2.2), z = Math.pow(a[2] + (b[2] - a[2]) * t, 2.2);
    let r = Math.max(0, m0 * x + mn * y + mp * z), g = Math.max(0, mp * x + m0 * y + mn * z), bl = Math.max(0, mn * x + mp * y + m0 * z);
    const lu = .2126 * r + .7152 * g + .0722 * bl, f = Math.pow(Math.max(1, .18 / Math.max(lu, .01)), .7);
    st.push(r * f, g * f, bl * f); lm += Math.min(lu * f, .75);
  }
  const G = Math.min(1.5, Math.pow(Math.max(1, .42 / Math.max(lm / 5, .05)), .85));
  // the gain goes to the dim stops (blues, violets); a bright red or yellow is already at full value and would only clip flat
  const q = (v, g) => Math.min(255, Math.round(Math.sqrt(v * g) * 127.5));
  for (let i = 0; i < 5; i++) {
    const r = st[i * 3], g = st[i * 3 + 1], bl = st[i * 3 + 2], lu = .2126 * r + .7152 * g + .0722 * bl, gi = 1 + (G - 1) * Math.max(0, Math.min(1, (.21 - lu) / .1));
    out[i] = q(r, gi) + 256 * q(g, gi) + 65536 * q(bl, gi);
  }
  return out;
}
// materials: 0 sand, 1 water, 2 sand/water, 3 liquid metal/sand, 4 liquid metal/water
function cymaMatPick(x) { return x < .3 ? 0 : x < .45 ? 1 : x < .62 ? 2 : x < .84 ? 3 : 4; }
// camera tilt states (0 = straight down .. 1 = about 36 degrees off vertical)
const cymaTilts = [.3, .55, .8, 1];   // w4: never quite straight down, so the plates always show their thickness
// v18: mode pairs for the great Chladni figure drawn across the whole floor
const cymaGreat = [[1,3],[2,5],[3,5],[3,7],[4,7],[2,7],[5,9],[1,5]];
// CYMA: two 0..1 values packed in one uniform float (12-bit integer part + fraction), unpacked by cyUp in the shader
function cymaPack(a, b) { a = Math.max(0, Math.min(.9999, a || 0)); b = Math.max(0, Math.min(.9995, b || 0)); return Math.floor(a * 4096) + b; }
