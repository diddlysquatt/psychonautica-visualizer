// VOID 9 nave families (nave half width is always 2, bays are 1 long, a crossing every 8 bays): arcade springing ya,
// vault springing ys, vault radius ratio k (1 = round, 2 = steep lancet), aisle vault ratio ka
const VOID9_FAM = [
  { ya: 3.0, ys: 9.0, k: 1.4, ka: 1.6 },   // high gothic
  { ya: 2.4, ys: 7.4, k: 1.0, ka: 1.0 },   // round romanesque
  { ya: 3.4, ys: 10.8, k: 1.8, ka: 1.9 },  // soaring lancet
  { ya: 3.0, ys: 8.0, k: 1.2, ka: 1.3 }    // broad hall
];
// v12: the level height is the same for every family (the tallest family's apex + 2.6), so a visit can morph its nave
// from one family into another while the camera flies (the floors stay put)
const VOID9_LY = Math.max(...VOID9_FAM.map((f) => f.ys + Math.sqrt(4 * f.k * f.k - (2 * f.k - 2) * (2 * f.k - 2)))) + 2.6;
// v12: the nave section of a morph in progress (family A -> B, eased); updates the derived heights the shots use
function void9Fam(c) {
  const A = VOID9_FAM[c.famA ?? c.fam], B = VOID9_FAM[c.famB ?? c.fam], u = void9Smooth(c.fmT ?? 1), m = (k) => A[k] + (B[k] - A[k]) * u;
  c.ya = m('ya'); c.ys = m('ys'); c.rv = 2 * m('k'); c.ka = m('ka');
  c.t0 = c.ya + Math.sqrt(Math.max(0.5 * c.ka - 0.25, 0)) + 0.25; c.apex = c.ys + Math.sqrt(c.rv * c.rv - (c.rv - 2) * (c.rv - 2));
}
// v12 route moods (a new one every 16 bars): 0 as before, 1 long straight runs, 2 a maze of turns, 3 towers (climbs and dives)
const VOID9_MOOD = [[1, 1], [0.35, 0.7], [1.75, 0.8], [0.8, 2.6]];
const void9Smooth = (x) => { x = clamp(x, 0, 1); return x * x * x * (x * (x * 6 - 15) + 10); };
const void9Mod = (a, b) => a - b * Math.floor(a / b);
// lantern crossings (shafts through every level): must match v9Cross in the shader
function void9Lantern(cx, cz, seed) { return void9Mod(void9Mod(cx, 16) * 5 + void9Mod(cz, 16) * 3 + seed, 3) === 0; }
// arch tunnels (must match v9Tun in the shader): the camera is held 0.3 inside the arches' opening there,
// easing down as it approaches a tunnel segment from its crossing
// (v18) the arch tunnels are gone (the camera lives up at gallery height now); nothing caps it
function void9TunCap() { return 1e3; }
const VOID9_DIR = [[0, 1], [1, 0], [0, -1], [-1, 0]];   // heading index -> (x, z); yaw = index * pi/2
// curated palettes: [deep glass, second glass, gold/metal, third glass, light]. The metal (arches, ribs, stars) is
// always at least 0.3 of a hue turn from the deep glass so stone and glass never read as one colour.
const VOID9_PAL = [
  [[0.04, 0.16, 1], [1, 0.04, 0.1], [1, 0.62, 0.14], [0.03, 0.7, 0.34], [0.55, 0.18, 1]],   // sainte-chapelle
  [[0.85, 0.04, 0.8], [0.04, 0.85, 1], [1, 0.62, 0.08], [0.45, 1, 0.06], [1, 0.25, 0.1]],    // neon (magenta glass, gold metal)
  [[0.18, 0.08, 0.9], [1, 0.33, 0.02], [1, 0.74, 0.18], [0.03, 0.8, 0.72], [1, 0.24, 0.42]], // sunrise
  [[0.02, 0.55, 0.9], [1, 0.1, 0.42], [1, 0.66, 0.12], [0.6, 0.12, 1], [0.3, 1, 0.5]],      // aurora (teal, rose, violet glass, gold metal, mint light)
  [[0.85, 0.02, 0.07], [1, 0.4, 0.02], [0.35, 0.85, 1], [1, 0.75, 0.1], [0.55, 0.06, 0.72]], // fire opal (icy metal)
  [[0.06, 0.28, 1], [1, 0.05, 0.48], [1, 0.9, 0.12], [0.42, 1, 0.04], [1, 0.48, 0]]         // acid
];
// palette fade that keeps chroma (never greys out), then a small hue nudge from the global colour drift
function void9Colour(a, b, t, hue) {
  const A = VOID9_PAL[a], B = VOID9_PAL[b], out = new Float32Array(15), ca = Math.cos(hue), sa = Math.sin(hue), k = 0.57735;
  for (let i = 0; i < 5; i++) {
    const x = A[i], y = B[i], m = [0, 1, 2].map((j) => x[j] + (y[j] - x[j]) * t);
    const la = (x[0] + x[1] + x[2]) / 3, lb = (y[0] + y[1] + y[2]) / 3, lm = (m[0] + m[1] + m[2]) / 3;
    const cm = Math.hypot(m[0] - lm, m[1] - lm, m[2] - lm), ct = Math.hypot(x[0] - la, x[1] - la, x[2] - la) * (1 - t) + Math.hypot(y[0] - lb, y[1] - lb, y[2] - lb) * t;
    const g = Math.min(ct / Math.max(cm, 1e-3), 3), c = m.map((v) => lm + (v - lm) * g);
    const d = k * (c[0] + c[1] + c[2]) * (1 - ca);
    const r = [c[0] * ca + k * (c[2] - c[1]) * sa + k * d, c[1] * ca + k * (c[0] - c[2]) * sa + k * d, c[2] * ca + k * (c[1] - c[0]) * sa + k * d];
    for (let j = 0; j < 3; j++) out[i * 3 + j] = Math.max(0, r[j]);
  }
  return out;
}
// The route is a chain of legs. Each leg runs from the middle of one arm (on a transverse arch) through a crossing to
// the middle of the next arm: straight on (S), turning left or right (L, R) round a quarter circle, or, at a lantern,
// climbing the shaft into the level above (U) or diving the well into the level below (D). Straight and turning legs
// take 8 beats, vertical ones 16; the speed is reshaped so it is exactly one bay per beat at both ends of every leg.
const VOID9_LOW = -2;   // (v19) the castle has three levels: the open citadel (0) and two great halls under it
function void9MakeLeg(c, prev, want) {
  let C, d;
  if (!prev) { C = [0, 0, 8]; d = 0; }
  else {
    const g = VOID9_DIR[prev.g], dy = prev.kind === 'U' ? c.Ly : prev.kind === 'D' ? -c.Ly : 0;
    C = [prev.C[0] + 8 * g[0], prev.C[1] + dy, prev.C[2] + 8 * g[1]]; d = prev.g;
  }
  // the world repeats every 16 crossings across (128 units) and 8 levels up. (v15) only the horizontal wrap is kept: the
  // route is a random walk in height, so leaving the level unwrapped costs no precision, and wrapping it stepped the
  // camera a whole 8-level period (133 units) the first time a visit dived below its starting level, which reads as a
  // camera reset in any trace even though the SDF is level-periodic.
  C = [void9Mod(C[0], 128), C[1], void9Mod(C[2], 128)];
  const lant = void9Lantern(Math.round(C[0] / 8), Math.round(C[2] / 8), c.seed);
  let kind = want || c.force;
  const lv = Math.round(C[1] / c.Ly), noUp = lv >= 0, noDn = lv <= VOID9_LOW;
  if (kind === 'U' && noUp) kind = rand() < 0.5 ? 'L' : 'R';
  if (!kind || ((kind === 'U' || kind === 'D') && !lant)) {
    const mo = VOID9_MOOD[c.mood || 0], r = rand(), up = lant && !noUp ? Math.min(0.7, ((c.mode === 1 ? 0.5 : c.mode === 2 ? 0.1 : 0.3) * mo[1])) : 0, dn = lant && !noDn ? Math.min(0.5, (c.mode === 2 ? 0.45 : c.mode === 1 ? 0 : 0.07) * mo[1]) : 0;
    const turn = Math.min(0.85, (c.mode === 2 ? 0.25 : 0.42) * mo[0]);
    kind = r < up ? 'U' : r < up + dn ? 'D' : r < up + dn + turn ? (rand() < 0.5 ? 'L' : 'R') : 'S';
    if ((kind === 'L' || kind === 'R') && prev && prev.kind !== 'S' && rand() < 0.5) kind = 'S';
  }
  let g = d;
  if (kind === 'L') g = (d + 1) % 4; else if (kind === 'R') g = (d + 3) % 4;
  else if (kind === 'U' || kind === 'D') { const r = rand(); g = r < 0.4 ? d : r < 0.7 ? (d + 1) % 4 : (d + 3) % 4; }
  const yaw0 = prev ? prev.yaw0 + prev.dyaw : 0, dyaw = g === d ? 0 : g === (d + 1) % 4 ? Math.PI / 2 : -Math.PI / 2;
  const v = kind === 'U' || kind === 'D', r = v ? 1.5 : 1.2;
  const len = kind === 'S' ? 8 : v ? 2 * (4 - r) + Math.PI * r + c.Ly - 2 * r : 2 * (4 - r) + Math.PI * r / 2;
  return { tb: prev ? prev.tb + prev.T : c.b0, T: v ? 16 : 8, kind, C, d, g, yaw0, dyaw, r, len, sA: 4 - r, sB: len - (4 - r), lant, spin: kind === 'S' && lant && rand() < 0.2 ? (rand() < 0.5 ? 1 : -1) : 0 };
}
// position on a leg at path length s: [x, y, z, turn fraction (yaw), pitch fraction (vertical legs)]
function void9LegPos(c, L, s) {
  const f = VOID9_DIR[L.d], g = VOID9_DIR[L.g], C = L.C, r = L.r, a = 4 - r;
  if (L.kind === 'S') { const u = s - 4; return [C[0] + f[0] * u, C[1], C[2] + f[1] * u, 0, 0]; }
  if (s < a) { const u = 4 - s; return [C[0] - f[0] * u, C[1], C[2] - f[1] * u, 0, 0]; }
  if (L.kind === 'L' || L.kind === 'R') {
    const arc = Math.PI * r / 2;
    if (s < a + arc) {
      const ph = (s - a) / r, cs = Math.cos(ph), sn = Math.sin(ph);
      return [C[0] - r * f[0] + r * g[0] + r * (-g[0] * cs + f[0] * sn), C[1], C[2] - r * f[1] + r * g[1] + r * (-g[1] * cs + f[1] * sn), ph / (Math.PI / 2), 0];
    }
    const u = r + s - a - arc; return [C[0] + g[0] * u, C[1], C[2] + g[1] * u, 1, 0];
  }
  const sg = L.kind === 'U' ? 1 : -1, arc = Math.PI * r / 2, V = c.Ly - 2 * r;
  if (s < a + arc) {
    const ph = (s - a) / r, cs = Math.cos(ph), sn = Math.sin(ph);
    return [C[0] - r * f[0] + r * f[0] * sn, C[1] + sg * r * (1 - cs), C[2] - r * f[1] + r * f[1] * sn, 0, ph / (Math.PI / 2)];
  }
  if (s < a + arc + V) { const u = s - a - arc; return [C[0], C[1] + sg * (r + u), C[2], void9Smooth(u / V), 1]; }
  if (s < a + 2 * arc + V) {
    const ph = (s - a - arc - V) / r, cs = Math.cos(ph), sn = Math.sin(ph);
    return [C[0] + r * g[0] * (1 - cs), C[1] + sg * (c.Ly - r + r * sn), C[2] + r * g[1] * (1 - cs), 1, 1 - ph / (Math.PI / 2)];
  }
  const u = r + s - a - 2 * arc - V; return [C[0] + g[0] * u, C[1] + sg * c.Ly, C[2] + g[1] * u, 1, 0];
}
// leg time (beats since the leg began) -> path length: speed 1 at both ends, reshaped smoothly in between
function void9LegS(L, tau) { const x = clamp(tau / L.T, 0, 1); return L.T * x + (L.len - L.T) * (x - Math.sin(2 * Math.PI * x) / (2 * Math.PI)); }
// the leg holding beat B (legs are generated ahead as needed)
function void9Leg(c, B) {
  if (!c.legs.length || B < c.legs[0].tb - 1 - 32 || B > c.legs[c.legs.length - 1].tb + 64) { c.b0 = B - 26; c.legs = [void9MakeLeg(c, null)]; }   // (v11) 26 beats of route behind: a zoomed-out trail never waits at the start
  while (c.legs[c.legs.length - 1].tb + c.legs[c.legs.length - 1].T < B + 10) c.legs.push(void9MakeLeg(c, c.legs[c.legs.length - 1]));
  while (c.legs.length > 3 && c.legs[1].tb + c.legs[1].T < B - 34) c.legs.shift();
  for (let i = c.legs.length - 1; i >= 0; i--) if (c.legs[i].tb <= B) return i;
  return 0;
}
function void9At(c, B) {
  const L = c.legs[void9Leg(c, B)], s = void9LegS(L, B - L.tb), P = void9LegPos(c, L, s);
  const yaw = L.yaw0 + L.dyaw * P[3], pitch = (L.kind === 'D' ? -1 : 1) * (Math.PI / 2) * P[4];
  // how far this point is from the turning part of its leg (lateral shot offsets fade to zero there)
  const away = L.kind === 'S' ? 9 : Math.max(L.sA - s, s - L.sB, 0);
  return { p: P, yaw, pitch, away, L, s };
}
// camera shots: [lateral, height, yaw offset, pitch offset, focal, roll]. 0 nave, 1 vault look-up, 2 triforium-level
// tracking across at the far clerestory, 3 low glide beside the piers, 4 telephoto down the nave, 5 weave, 6 high under
// the vault and tilted, 7 looking sideways through the arcade into the rooms, 8 from the gallery balcony looking down
// across the nave onto the floor of light
function void9Shot(c, bay) {
  const sd = (c.shotN % 2 ? 1 : -1) * c.side;
  switch (c.shot) {
    case 1: return [0.3 * sd, c.t0 + 0.6, 0, 0.85, 0.68, 0];
    case 2: return [1.0 * sd, c.t0 + 0.35, 1.2 * sd, -0.02, 0.9, 0];
    case 3: return [1.25 * sd, c.ys - 1.2, -0.3 * sd, -0.18, 0.8, 0];
    case 4: return [0, c.t0 + 1, 0, 0.02, 1.9, 0];
    case 5: return [1.1 * Math.sin(bay * Math.PI / 8), c.ys * 0.55, -0.15 * Math.cos(bay * Math.PI / 8), -0.04, 0.85, 0];
    case 6: return [0.5 * sd, c.ys - 1.0, 0.15 * sd, -0.14, 0.8, 0.16 * sd];
    case 7: return [1.0 * sd, c.t0 + 0.4, -1.4 * sd, -0.05, 0.75, 0];
    case 8: return [0.75 * sd, c.ys - 1.5, -0.5 * sd, -0.42, 0.78, 0];
    // (v19) the citadel's own shots (the top level only: they fly over the wall tops, above the battlements and under the bridges)
    case 9: return [0.2 * sd, c.ys + 3.1, 0, -0.06, 0.85, 0];
    case 10: return [1.1 * sd, c.ys + 3.9, -0.75 * sd, -0.2, 0.72, 0.05 * sd];
    case 11: return [0.6 * sd, c.ys + 2.4, 0.35 * sd, 0.3, 0.7, 0];
    default: return [0, c.ys * 0.62, 0, -0.06, 0.85, 0];
  }
}
// next shot: never the same one twice in a row; alternate forward views (0 4 5 6) with side or vertical views (1 2 3 7 8)
function void9Next(c) {
  const fwd = c.onTop ? [9, 10, 9, 10, 0, 5] : [0, 4, 5, 6], other = c.onTop ? [11, 8, 11, 2, 10] : [1, 2, 3, 7, 8], isF = fwd.includes(c.shot);
  if (isF) c.lastF = c.shot; else c.lastO = c.shot;
  const last = isF ? c.lastO : c.lastF, pool = (isF ? other : fwd).filter((k) => k !== c.shot && k !== last);
  return pool[Math.floor(rand() * pool.length) % pool.length];
}
// v11: critically damped spring (semi-implicit, sub-stepped): x and v arrays follow tgt; om sets the stiffness
// (settle time ~4.7/om s). The camera's shot pose, its offset from the route and its view angles all go through one,
// so a shot interrupted half way, a tunnel cap or a drop move never changes the camera's velocity in one frame.
function void9Spring(x, v, tgt, om, dt) {
  // (v19) the exact closed-form step of a critically damped spring: stable at any dt
  const E = Math.exp(-om * dt);
  for (let i = 0; i < x.length; i++) { const d = x[i] - tgt[i], b = (v[i] + om * d) * dt; x[i] = tgt[i] + (d + b) * E; v[i] = (v[i] - om * b) * E; }
}
// v11: the journey outlives a reseed. When the engine re-seeds this realm (a mutation, an Auto Show return) the new
// visit picks up the route, the building and the camera where the old one is, so the crossfade never jumps the camera
// back to the start of a fresh route; only the glass palette changes.
let VOID9_J = null;
function void9Tick() { try { return frameCount; } catch (e) { return -1; } }
function void9Continue(c, B) {
  const J = VOID9_J, fc = void9Tick();
  if (!J || J.c === c || fc < 0 || fc - J.fc > 3) return false;
  const o = J.c, dB = B - J.B;
  for (const k of ['fam', 'famA', 'famB', 'fmT', 'mood', 'nextMorph', 'ya', 'ys', 'rv', 'ka', 't0', 'apex', 'Ly', 'seed', 'side', 'pet', 'mode', 'shot', 'shotN', 'lastF', 'lastO', 'dropN', 'mvA', 'mvDir', 'grow', 'trail', 'capS', 'spin', 'bars', 'air', 'airB', 'zl', 'zv'])
    if (o[k] !== undefined) c[k] = o[k];
  c.legs = o.legs.map((L) => Object.assign({}, L, { C: L.C.slice(), tb: L.tb + dB }));
  c.b0 = o.b0 + dB; c.lastLeg = o.lastLeg ? c.legs[o.legs.indexOf(o.lastLeg)] || null : null;
  for (const k of ['cam', 'camV', 'oX', 'oV', 'aX', 'aV', 'aZ']) if (o[k]) c[k] = o[k].slice();
  c.palB = c.palA; c.palA = o.palA; c.pm = 0;   // the new visit's palette fades in over the old one
  return true;
}
// level and onset of band b (0..7) from the engine's 8 band envelopes
function void9Band(b) { b = ((Math.round(b) % 8) + 8) % 8; return [BANDS.lv[b] || 0, BANDS.on[b] || 0]; }
