// ---- HYPR: hyperbolic tilings of the Poincare disk ----
// Perfect colourings of each {p,q}: [m, R, H] where R (rotation of the central tile by 2pi/p) and H (half-turn about the
// midpoint of edge 0) are permutations of m colour classes with R fixing class 0 and H moving it, satisfying the
// relations of the (2,p,q) triangle group, so neighbouring tiles always differ. Found by exhaustive search.
const HYPR_COLS={'4,5':[[5,"02143","10324"],[6,"013452","230154"]],
 '5,4':[[2,"01","10"],[6,"023451","102543"]],
 '6,4':[[2,"01","10"],[4,"0132","2301"],[6,"021453","345012"],[7,"0234561","1026543"],[8,"01342675","25067134"]],
 '4,6':[[2,"01","10"],[3,"021","102"],[5,"02341","10432"],[6,"013254","240513"],[7,"0214563","1032465"],[8,"01325674","45670123"]],
 '8,3':[[3,"021","102"],[6,"013452","240513"]],
 '7,3':[[8,"02345671","10743652"]],
 '3,7':[[7,"0231564","1024356"],[8,"01342675","23015476"]],
 '6,6':[[2,"01","10"],[3,"021","102"],[4,"0231","1032"],[6,"012453","345012"],[7,"0231564","1024365"],[8,"01342675","25076143"]],
 '8,4':[[2,"01","10"],[4,"0132","2301"],[5,"02341","10243"],[8,"01325674","46570213"]],
 '4,8':[[2,"01","10"],[4,"0132","2301"],[5,"02341","10243"],[8,"01235674","45670123"]],
 '10,3':[[3,"021","102"],[6,"023451","105342"]],
 '12,3':[[3,"021","102"],[4,"0231","1032"],[6,"013452","240513"],[7,"0234561","1063542"]],
 '5,5':[[6,"023451","102354"]],
 '6,5':[[5,"01342","23014"],[6,"021453","103254"],[7,"0234561","1024365"]],
 '7,4':[[2,"01","10"],[8,"02345671","10274563"]],
 '9,3':[[4,"0231","1032"]],
 '3,8':[[2,"01","10"],[4,"0231","1023"],[8,"01342675","23015467"]],
 '5,6':[[2,"01","10"],[6,"023451","102345"],[7,"0134562","2301465"]]};
function hyprGeom(p, q) {
  const a = Math.PI / p, b = Math.PI / q, den = Math.sqrt(Math.cos(b) ** 2 - Math.sin(a) ** 2);
  const cd = Math.cos(b) / den, cr = Math.sin(a) / den, mm = cd - cr, kk = 1 + mm * mm;
  const sv = cd * Math.cos(a) - Math.sqrt(cd * cd * Math.cos(a) ** 2 - 1);
  return { p, q, a, cd, cr, mm, kk, sv, inR: 2 * Math.atanh(mm), step: 4 * Math.atanh(mm), cen: 2 * mm / kk };
}
// SU(1,1) Mobius maps z -> (al z + be)/(conj(be) z + conj(al)), stored [alr, ali, ber, bei]
const hyprM = {
  id: () => [1, 0, 0, 0],
  mul(A, B) { // A o B
    const [a1, a2, b1, b2] = A, [c1, c2, d1, d2] = B;
    return [a1 * c1 - a2 * c2 + b1 * d1 + b2 * d2, a1 * c2 + a2 * c1 + b2 * d1 - b1 * d2,
      a1 * d1 - a2 * d2 + b1 * c1 + b2 * c2, a1 * d2 + a2 * d1 + b2 * c1 - b1 * c2];
  },
  ap(A, z) {
    const [a1, a2, b1, b2] = A, nr = a1 * z[0] - a2 * z[1] + b1, ni = a1 * z[1] + a2 * z[0] + b2;
    const dr = b1 * z[0] + b2 * z[1] + a1, di = b1 * z[1] - b2 * z[0] - a2, d = dr * dr + di * di || 1e-30;
    return [(nr * dr + ni * di) / d, (ni * dr - nr * di) / d];
  },
  inv: (A) => [A[0], -A[1], -A[2], -A[3]],
  norm(A) { const d = Math.sqrt(Math.max(A[0] * A[0] + A[1] * A[1] - A[2] * A[2] - A[3] * A[3], 1e-12)); return A.map((v) => v / d); },
  rot: (t) => [Math.cos(t / 2), Math.sin(t / 2), 0, 0],
  // hyperbolic translation of the origin by distance D in direction t
  tr: (t, D) => [Math.cosh(D / 2), 0, Math.sinh(D / 2) * Math.cos(t), Math.sinh(D / 2) * Math.sin(t)],
  // the translation taking 0 to the disk point v
  to(v) { const r = Math.min(Math.hypot(v[0], v[1]), 0.999999); return hyprM.tr(Math.atan2(v[1], v[0]), 2 * Math.atanh(r)); },
  half: (G) => [0, -G.kk / (1 - G.mm * G.mm), 0, 2 * G.mm / (1 - G.mm * G.mm)]
};
// fold z into the central tile: returns the map F (z -> central tile, sector 0), the sector indices of each half-turn and the last one
function hyprFold(G, z) {
  let F = hyprM.id(); const ks = []; let kf = 0;
  for (let i = 0; i < 200; i++) {
    const k = Math.floor(Math.atan2(z[1], z[0]) / (2 * G.a) + 0.5), R = hyprM.rot(-2 * G.a * k);
    z = hyprM.ap(R, z); F = hyprM.mul(R, F);
    if (Math.hypot(z[0] - G.cd, z[1]) >= G.cr) { kf = k; break; }
    const H = hyprM.half(G); z = hyprM.ap(H, z); F = hyprM.mul(H, F); ks.push(k);
  }
  return { z, F, ks, kf };
}
const hyprPerm = {
  id: (m) => [...Array(m).keys()],
  comp: (A, B) => B.map((x) => A[x]), // A o B
  inv(A) { const r = []; A.forEach((v, i) => { r[v] = i; }); return r; },
  pow(A, k) { const m = A.length, o = hyprPerm.ord(A); k = ((k % o) + o) % o; let r = hyprPerm.id(m); for (let i = 0; i < k; i++) r = hyprPerm.comp(A, r); return r; },
  ord(A) { let r = A, n = 1; while (!r.every((v, i) => v === i)) { r = hyprPerm.comp(A, r); n++; } return n; },
  pack: (A) => A.reduce((s, v, i) => s + v * Math.pow(8, i), 0)
};
// phi(F^-1) for a fold: R^k1 H R^k2 H ... R^kn H R^kf
function hyprFoldPerm(T, fo) {
  const { R, H } = T;
  let P = hyprPerm.pow(R, fo.kf);
  for (let i = fo.ks.length - 1; i >= 0; i--) P = hyprPerm.comp(hyprPerm.pow(R, fo.ks[i]), hyprPerm.comp(H, P));
  return P;
}
// tile colour (before the display permutation) of the tile containing tiling-space point z
function hyprColourAt(T, z) { const fo = hyprFold(T.G, z); return hyprFoldPerm(T, fo)[0]; }

// ---- tilings, choreography and uniform packing ----
// tilings by fineness (more, smaller tiles first); motifs: 0 jewel, 1 star strapwork, 3 Wythoff (uniform truncations
// that morph; the jewel is its plain end)
const HYPR_TILES = [[3, 8], [3, 7], [4, 5], [5, 4], [4, 6], [6, 4], [7, 3], [5, 5], [8, 3], [4, 8], [7, 4], [6, 5], [5, 6], [9, 3], [8, 4], [10, 3], [6, 6], [12, 3]];
// 0 jewel cathedral, 1 close jewel cathedral, 2 band friezes, 3 half-plane cathedral (weights by repetition)
const HYPR_MODELS = [0, 0, 1, 1, 2, 2, 3, 3];
const HYPR_MOTIFS = [0, 1, 3, 3, 0, 1, 3, 0];
// cathedral (macro) families
const HYPR_MACROS = [[7, 3], [5, 4], [6, 4], [4, 5], [5, 5], [8, 3], [4, 6], [7, 4]];
const hyprMacroRho = (k, mo) => { const G = hyprGeom(...HYPR_MACROS[k]); return mo ? G.sv : Math.tanh(0.88 * Math.atanh(G.mm)); };
// Wythoff point keyframes [s along the edge arc (0 midpoint .. 1 vertex), u pulled toward the centre]
const HYPR_WY = [[0.93, 0], [0.62, 0], [0.32, 0], [0.06, 0], [0.5, 0.28], [0.4, 0.16], [0.8, 0.22], [0.2, 0.4], [0.55, 0.45]];
// curated palettes: six class colours, metal accent, deep ground (crossfaded in JS, sent packed as 24-bit integers)
const HYPR_PALS = [[0x0d33ff,0xff0a1f,0x05c74d,0x991aff,0xff8c08,0x0abff2,0xffb847,0x030209],[0xff0a80,0x00ccff,0x7314ff,0x80ff0d,0xff5900,0x1a40ff,0xbff2ff,0x040009],
  [0xf2051a,0xff6b05,0xe60a9e,0x009e9e,0xffc71a,0x610d8c,0xffd999,0x080105],[0x00b4ff,0x0d33f2,0x8a2bff,0x00e09a,0xff1f8f,0x00739e,0x59c2ff,0x000309],
  [0xff5900,0xffcc0d,0xff0a0a,0x8000bf,0xff2e80,0x009e8c,0xffe699,0x090003],[0xff00b3,0x6b00ff,0x73ff00,0x00bfad,0xffe000,0xff6600,0xffffe0,0x050008],
  [0x009e8f,0x0d26f2,0xffad14,0x1ad126,0x731ad9,0xeb5214,0xffc759,0x000406],[0xff0f6e,0x00d977,0x6a1fff,0xff6a00,0x0a7dff,0xffd000,0xffa62b,0x0b030e]]
  .map((p) => p.map((h) => [(h >> 16) & 255, (h >> 8) & 255, h & 255]));
function hyprPackPal(P) {
  const q = (c) => Math.round(clamp(c[0], 0, 255)) * 65536 + Math.round(clamp(c[1], 0, 255)) * 256 + Math.round(clamp(c[2], 0, 255));
  const d = P[7].map((v) => Math.round(clamp(v / 255 / 0.004, 0, 15)));
  return { k: P.slice(0, 7).map(q), deep: d[0] * 256 + d[1] * 16 + d[2] };
}
function hyprRng(seed) { let s = Math.floor((seed - Math.floor(seed)) * 2147483646) + 1; const r = () => (s = (s * 16807) % 2147483647) / 2147483647; for (let i = 0; i < 5; i++) r(); return r; }
function hyprPick(r, a) { return a[Math.floor(r() * a.length) % a.length]; }
// strap contact angles whose hankin rays meet the neighbouring ray inside the tile
function hyprStyles(G) {
  const ok = [];
  for (let st = 0; st < 16; st++) {
    const th = 0.6 + 0.06 * st, nx = Math.cos(th), ny = Math.sin(th), t = (1 - G.mm * G.mm) / (2 * G.mm * nx);
    const cx = G.mm + t * nx, cy = t * ny, ec = Math.cos(G.a) * cx + Math.sin(G.a) * cy;
    if (ec * ec <= 1) continue;
    const s = ec - Math.sqrt(ec * ec - 1);
    if (s > 0.05 * G.sv && s < 0.8 * G.sv) ok.push(st);
  }
  return ok.length ? ok : [8];
}
function hyprMotif(r, p, want, not) {
  if (want !== undefined && HYPR_MOTIFS.includes(want)) return want;
  const c = HYPR_MOTIFS.filter((x) => x !== not);
  return hyprPick(r, c.length ? c : HYPR_MOTIFS);
}
function hyprMakeTiling(r, o) {
  o = o || {};
  let pq = o.pq;
  if (!pq) {
    let cand = HYPR_TILES.filter((t, i) => (!o.not || t[0] !== o.not[0] || t[1] !== o.not[1]) && (!o.coarse || i >= 3));
    if (o.finer && o.not) {
      const i0 = HYPR_TILES.findIndex((t) => t[0] === o.not[0] && t[1] === o.not[1]);
      const f = HYPR_TILES.slice(0, Math.max(3, i0)).filter((t) => t[0] !== o.not[0] || t[1] !== o.not[1]);
      if (f.length) cand = f;
    }
    pq = hyprPick(r, cand);
  }
  const [p, q] = pq, G = hyprGeom(p, q), cols = HYPR_COLS[p + ',' + q];
  // prefer 3..6 colour classes; 2-colour checkerboards and 7/8-class mosaics now and then
  const pref = cols.filter((c) => c[0] >= 3 && c[0] <= (p === 3 ? 4 : 6));
  const cc = (pref.length && r() < 0.8) ? hyprPick(r, pref) : hyprPick(r, cols);
  const R = [...cc[1]].map(Number), H = [...cc[2]].map(Number);
  const motif = hyprMotif(r, p, o.motif, o.notMotif);
  let pal = o.pal ?? Math.floor(r() * 8);
  if (o.notPal !== undefined && pal === o.notPal) pal = (pal + 1 + Math.floor(r() * 7)) % 8;
  let model = o.model ?? hyprPick(r, HYPR_MODELS);
  // very large tiles leave too few of them on screen in the close views
  if (model === 3 && G.inR > 0.7) model = 2;
  if (model === 1 && G.inR > 0.95) model = 0;
  const macro = o.macro ?? Math.floor(r() * 8);
  const phi0 = model >= 2 ? (p % 2 ? Math.PI / 2 : 0) : r() * 6.283;
  return { p, q, G, m: cc[0], R, H, ordR: hyprPerm.ord(R), motif, pal, model, macro, mosaic: o.mosaic ?? (r() < 0.7 ? 1 : 0), view: o.view ?? (model === 2 && r() < 0.5 ? 1 : (model < 2 && r() < 0.35 ? 2 : 0)), stone: o.stone ?? hyprStone(r(), -1), style: hyprPick(r, hyprStyles(G)),
    Ys: hyprM.rot(phi0), Q: hyprPerm.id(cc[0]) };
}
// the same geometry and camera with a new look (phrase changes)
// v20: what sits in the tiles. 0 faceted stones, 1 black opal, 2 star sapphire, 3 cloisonne enamel, 4 agate, 5 mixed by colour class
// (faceted / enamel / star), 6 mixed (enamel / agate / opal). x is one random number; not = the kind to avoid
const HYPR_STONES = [0.2, 0.09, 0.12, 0.17, 0.1, 0.19, 0.13];
function hyprStone(x, not) {
  let k = 0, a = 0; for (; k < 6; k++) { a += HYPR_STONES[k]; if (x < a) break; }
  return k === not ? (k + 1 + Math.floor(x * 97) % 6) % 7 : k;
}
function hyprRestyle(r, T) {
  const N = Object.assign({}, T);
  N.Q = T.Q.slice(); N.Ys = T.Ys.slice();
  N.motif = hyprMotif(r, T.p, undefined, T.motif);
  if (r() < 0.6) N.pal = (T.pal + 1 + Math.floor(r() * 7)) % 8;
  N.style = hyprPick(r, hyprStyles(T.G));
  if (r() < 0.6) N.stone = hyprStone(r(), T.stone);
  if (T.model < 2 && !T.view && r() < 0.3) N.mosaic = 1 - T.mosaic;
  if (T.model < 2 && r() < 0.18) N.view = T.view ? 0 : 2;
  return N;
}
function hyprPack(T) {
  const Qi = hyprPerm.inv(T.Q), Hc = hyprPerm.comp(T.Q, hyprPerm.comp(T.H, Qi)), Rc = hyprPerm.comp(T.Q, hyprPerm.comp(T.R, Qi));
  const R2 = hyprPerm.comp(Rc, Rc), R4 = hyprPerm.comp(R2, R2);
  T.pw = [hyprPerm.pack(R2), hyprPerm.pack(R4)];
  const MA = HYPR_MACROS[T.macro];
  return [T.p + 16 * T.q + 256 * T.motif + 2048 * T.model + 8192 * MA[0] + 131072 * MA[1],
    T.m + 16 * T.Q[0] + 256 * T.ordR + 4096 * T.style + 65536 * (T.mosaic ? 1 : 0) + 131072 * (T.view || 0) + 524288 * (T.stone || 0), hyprPerm.pack(Hc), hyprPerm.pack(Rc)];
}
// re-centre the camera on the central tile (a symmetry of the tiling: the picture is unchanged, colour classes relabel)
function hyprRenorm(T) {
  const fo = hyprFold(T.G, hyprM.ap(T.Ys, [0, 0]));
  if (!fo.ks.length && !fo.kf) return;
  T.Ys = hyprM.norm(hyprM.mul(fo.F, T.Ys));
  T.Q = hyprPerm.comp(T.Q, hyprFoldPerm(T, fo));
}
// a vertex (or neighbouring tile centre) of the tile under the screen centre, in the screen frame, nearest a heading
function hyprAnchor(T, heading, vertex) {
  const G = T.G, iY = hyprM.inv(T.Ys), fo = hyprFold(G, hyprM.ap(T.Ys, [0, 0])), Fi = hyprM.inv(fo.F);
  let best = null, bd = 9;
  for (let j = 0; j < G.p; j++) {
    const t = (vertex ? 2 * j + 1 : 2 * j) * G.a, R0 = vertex ? G.sv : G.cen;
    const s = hyprM.ap(iY, hyprM.ap(Fi, [R0 * Math.cos(t), R0 * Math.sin(t)]));
    const rr = Math.hypot(s[0], s[1]); if (rr > 0.8 || rr < 1e-3) continue;
    const an = Math.atan2(s[1], s[0]), d = Math.abs(Math.atan2(Math.sin(an - heading), Math.cos(an - heading)));
    if (d < bd) { bd = d; best = s; }
  }
  return best || [0.3 * Math.cos(heading), 0.3 * Math.sin(heading)];
}
// unit-speed flow generators [w, bx, by] in the screen frame (field V(z) = b + i w z - conj(b) z^2; speed 1 at the centre)
const hyprGen = {
  tr: (t) => [0, 0.5 * Math.cos(t), 0.5 * Math.sin(t)],
  horo: (t, s) => [s, 0.5 * s * Math.sin(t), -0.5 * s * Math.cos(t)],
  about(c, s) { // rotation about the screen point c
    const c2 = c[0] * c[0] + c[1] * c[1], d = 2 * Math.atanh(Math.min(Math.sqrt(c2), 0.95)), w = s / Math.max(Math.sinh(d), 0.35);
    return [w * (1 + c2) / (1 - c2), w * c[1] / (1 - c2), -w * c[0] / (1 - c2)];
  }
};
const HYPR_FLOWS = [['stream', 'weave', 'spiral', 'orbit', 'spin', 'horo', 'weave', 'spiral'], ['stream', 'weave', 'spiral', 'orbit', 'spin', 'horo', 'weave', 'spiral'],
  ['stream', 'weave', 'orbit', 'stream'], ['horo', 'horo', 'hweave', 'stream', 'orbit']];
function hyprShape(c, T, bc) {
  const G = T.G, s = c.sgn, md = T.model, h = c.heading;
  switch (c.mode) {
    case 'weave': { const hh = h + (md === 2 ? 0.35 : 0.75) * Math.sin(bc * Math.PI / 4); return hyprGen.tr(hh); }
    case 'spiral': { const g = hyprGen.tr(h); g[0] = s * 0.55; return g; }
    case 'orbit': return hyprGen.about(c.oc, s);
    case 'spin': return [s * G.a / G.inR, 0, 0];
    case 'horo': return hyprGen.horo(md === 3 ? Math.PI / 2 : h, s);
    case 'hweave': { const g = hyprGen.horo(Math.PI / 2, s), u = hyprGen.tr(Math.PI / 2); const k = 0.45 * Math.sin(bc * Math.PI / 4); return [g[0] + k * u[0], g[1] + k * u[1], g[2] + k * u[2]]; }
    default: return hyprGen.tr(h);
  }
}
function hyprNewFlow(c, T, rnd) {
  const md = T.model, list = HYPR_FLOWS[md];
  let mode = hyprPick(rnd, list);
  if (c.breakdown && rnd() < 0.6) mode = md === 3 ? 'horo' : (md === 2 ? 'orbit' : hyprPick(rnd, ['spin', 'orbit', 'horo']));
  if (mode === c.mode && rnd() < 0.7) mode = hyprPick(rnd, list);
  c.mode = mode; c.sgn = rnd() < 0.5 ? -1 : 1;
  if (md === 2) c.heading = rnd() < 0.5 ? 0 : Math.PI;
  else if (md === 3) c.heading = rnd() < 0.5 ? Math.PI / 2 : -Math.PI / 2;
  else c.heading += (rnd() - 0.5) * 2.4;
  if (mode === 'orbit') c.oc = hyprAnchor(T, c.heading, rnd() < 0.6);
}
// von Mises beat pulse, normalised to mean 1: the flow surges just after each beat and glides between them
function hyprI0(k) { let s = 1, t = 1; for (let j = 1; j < 12; j++) { t *= (k / 2) * (k / 2) / (j * j); s += t; } return s; }
function hyprPulse(x, k) { return Math.exp(k * (Math.cos(2 * Math.PI * (x - 0.12)) - 1)) / (hyprI0(k) * Math.exp(-k)); }
// the dive: fly into the micro jewel at the screen centre; inside it the new world (any view) waits at its own zoom 1/Z.
// Z is chosen so the new world's own jewel rim matches the window at the start; when the dive ends the new world is at
// zoom 1 and simply becomes the view
const hyprR0 = (T) => (T.model === 0 ? 0.3 : 0.46);
function hyprStartDive(c, Bt, beats) {
  const A = c.B || c.A, Z = Bt.model < 2 ? hyprR0(Bt) / (hyprR0(A) * hyprMacroRho(Bt.macro, Bt.mosaic)) : 2.6;
  c.B = Bt; c.w = 0; c.wDur = beats; c.dv = { t: 0, Z: Math.max(1.6, Math.min(Z, 5)), lz0: c.lz, r0: hyprR0(A) };
}
function hyprInit(s) {
  const r = hyprRng(s[0] * 0.613 + s[1] * 0.291 + s[2] * 0.177 + s[3] * 0.071 + 0.013);
  const model = HYPR_MODELS[Math.floor(s[1] * HYPR_MODELS.length) % HYPR_MODELS.length];
  const A = hyprMakeTiling(r, { pq: HYPR_TILES[Math.floor(s[0] * HYPR_TILES.length) % HYPR_TILES.length], motif: HYPR_MOTIFS[Math.floor(s[2] * 8) % 8], pal: Math.floor(s[3] * 8) % 8, model });
  const c = { A, B: null, w: 0, wDur: 2, mode: 'stream', sgn: 1, heading: r() * 6.283, oc: [0.3, 0], g: [0, 0, 0], gv: [0, 0, 0],
    spd: 0, tpb: 0.5, lb: 0.4, hb: 0, lastP: -1, flipR: 60, flipT: 0, kick: 0, ringR: 9, ringA: 0, midPh: 0, la: r() * 6.283, pd: 0,
    bars: 0, buildDone: false, drop: 0, rimHue: 0, spin: 0, breakdown: false, bdT: 0, mth: r() * 6.283, mw: 0, mdir: r() < 0.5 ? -1 : 1,
    lz: 0, lzv: 0, ascUntil: -1, dv: null, wy: [0.93, 0], wyT: [0.93, 0], sweep: -1, pal: HYPR_PALS[A.pal].map((c) => c.slice()) };
  hyprNewFlow(c, A, r);
  c.g = hyprShape(c, A, 0);
  return c;
}
function hyprFrame(V, F, dt) {
  const c = V.c, dz = S.dose, sp = S.speed, bps = (F.bpm > 0 ? F.bpm : 120) / 60, B = BANDS.lv, BO = BANDS.on;
  dt = Math.min(Math.max(dt, 0), 0.05);
  const locked = F.conf > 0.45 && !F.silent, bc = locked ? F.beatClock : V.trav;
  const tiles = () => (c.B ? [c.A, c.B] : [c.A]);
  c.breakdown = F.breakdown > 0.6; c.bdT = c.breakdown ? c.bdT + dt * bps : 0;
  const T0 = c.B || c.A;
  // phrase-level flow changes: every 8 beats the flow may change shape (orbit, spin, spiral, weave, horocycle drift)
  const ph8 = Math.floor(bc / 8);
  if (ph8 !== c.lastP) { if (c.lastP >= 0 && (rand() < 0.6 || c.breakdown !== c.wasBd)) hyprNewFlow(c, T0, rand); c.lastP = ph8; c.wasBd = c.breakdown; }
  if (T0.model < 2) c.heading += dt * 0.07 * c.sgn;
  // the flow generator glides to its new shape on a critically damped spring (no sudden turns)
  const gT = hyprShape(c, T0, bc), om = 2.6;
  for (let i = 0; i < 3; i++) { c.gv[i] += (om * om * (gT[i] - c.g[i]) - 2 * om * c.gv[i]) * dt; c.g[i] += c.gv[i] * dt; }
  // speed: tiles per beat, surging just after every beat; builds accelerate and sharpen the surge, drops rush, breakdowns float
  c.drop *= Math.exp(-dt * bps / 3);
  const tpb = F.silent ? 0.12 : (c.breakdown ? 0.26 : 0.5 + 0.5 * F.build) + 0.75 * c.drop;
  c.tpb += (tpb - c.tpb) * (1 - Math.exp(-dt * 2));
  c.hb += ((F.build > 0.5 || c.drop > 0.5 ? 1 : 0) - c.hb) * (1 - Math.exp(-dt * 1.5));
  c.lb += (Math.max(B[0], B[1]) - c.lb) * (1 - Math.exp(-dt * 4));
  const ph = ((bc % 1) + 1) % 1, kp = c.breakdown ? 0.8 : 2 + 1.2 * F.build, depth = c.breakdown ? 0.35 : 0.62;
  const pulse = (1 - c.hb) * hyprPulse(ph, kp) + c.hb * hyprPulse((ph * 2) % 1, kp);
  const want = c.tpb * bps * 2 * T0.G.inR * (1 - depth + depth * pulse) * (0.78 + 0.45 * c.lb) * sp;
  c.spd += (want - c.spd) * (1 - Math.exp(-dt / 0.06));
  // integrate the flow: an infinitesimal Mobius step in the screen frame, applied to both tilings during a wipe
  const st = c.spd * dt, M = hyprM.norm([1, c.g[0] * st / 2, c.g[1] * st, c.g[2] * st]);
  for (const T of tiles()) { T.Ys = hyprM.norm(hyprM.mul(T.Ys, M)); hyprRenorm(T); }
  c.oc = hyprM.ap(hyprM.inv(M), c.oc);
  if (c.mode === 'orbit' && Math.hypot(c.oc[0], c.oc[1]) > 0.85) c.oc = hyprAnchor(T0, c.heading, true);
  // snare: colour classes cycle one step in a wave running out from the centre
  if (F.onHit) { c.flipT = (c.flipT + 1) % 840; c.flipR = 0; }
  c.flipR = Math.min(60, c.flipR + dt * 22);
  // kick: a ring of light runs out through the generations of tiles (the outlines pulse on the engine kick envelope)
  if (F.onKick) { c.ringR = 0; c.ringA = Math.min(1.2, 0.5 + F.kick) * dz; }
  c.ringR += dt * bps * 3.2; c.ringA *= Math.exp(-dt * 1.6);
  c.midPh += dt * (0.15 + 0.8 * B[2] + 0.8 * B[3]) * sp; if (c.midPh > 1000) c.midPh -= 1000;
  c.la += dt * (0.12 + 0.5 * F.build - (c.breakdown ? 0.06 : 0)) * sp;
  c.spin += dt * (0.05 + 0.4 * B[3]) * sp;
  // the cathedral turns slowly, a little faster with the low mids and on every beat surge
  const mwT = c.mdir * (0.03 + 0.07 * B[2]) * (c.breakdown ? 0.6 : 1) * (0.7 + 0.3 * pulse) * sp;
  c.mw += (mwT - c.mw) * (1 - Math.exp(-dt * 1.2)); c.mth += c.mw * dt;
  // internal zoom on a slow spring: breakdowns and rare "ascensions" pull far back into the cathedral, builds lean in
  if ((F.onBar || F.onSceneBar) && c.ascUntil < bc && F.build < 0.2 && rand() < (c.bdT > 8 ? 0.2 : 0.025)) c.ascUntil = bc + 12;
  c.tourT=(c.tourT||0)+dt*S.speed;
  if(c.tourT>24&&!c.dv&&!c.B){c.tourT=0;c.ascUntil=bc+10;c.sweep=bc;}
  const lzT = Math.log(c.ascUntil > bc ? 0.34 : (c.breakdown ? 0.72 : 1 + 0.22 * F.build));
  if (c.dv) {
    // during a dive the internal zoom follows a smootherstep from the start zoom to Z times it
    c.dv.t += dt * bps / c.wDur; const t = Math.min(c.dv.t, 1), e = t * t * t * (t * (6 * t - 15) + 10);
    c.lz = c.dv.lz0 + e * Math.log(c.dv.Z); c.lzv = 0;
  } else { const oz = 1.4; c.lzv += (oz * oz * (lzT - c.lz) - 2 * oz * c.lzv) * dt; c.lz += c.lzv * dt; }
  // structure: drops wipe in a new {p,q}, motif, palette (sometimes a new view or cathedral); builds wipe to a finer tiling
  const dropEdge = F.onDrop || (F.drop > 0.85 && c.pd < 0.5); c.pd = F.drop;
  const startWipe = (Bt, beats) => { if (c.B) c.A = c.B; c.B = Bt; c.w = 0; c.wDur = beats; };
  const canDive = !c.B && c.A.model < 2 && !c.A.view;
  if (c.diveNow !== undefined && canDive) { // test / remote hook: dive now into a world of view diveNow (-1 any)
    hyprStartDive(c, hyprMakeTiling(rand, { not: [c.A.p, c.A.q], notMotif: c.A.motif, model: c.diveNow < 0 ? undefined : c.diveNow }), 6);
    hyprNewFlow(c, c.B, rand); c.diveNow = undefined;
  }
  if (dropEdge) {
    c.drop = 1; c.bars = 0; c.buildDone = false; c.ringR = 0; c.ringA = 1.3 * dz; c.ascUntil = -1;
    c.wyT = hyprPick(rand, HYPR_WY); c.palSnap = true;
    if (!c.dv) {
      const A = c.B || c.A, model = rand() < 0.35 ? hyprPick(rand, HYPR_MODELS.filter((m) => m !== A.model)) : A.model;
      // drops avoid the three finest tilings (legible, not busy) and sometimes dive straight into the jewel
      const Bt = hyprMakeTiling(rand, { not: [A.p, A.q], notMotif: A.motif, notPal: A.pal, model, coarse: true, macro: rand() < 0.5 ? undefined : A.macro });
      if (canDive && rand() < 0.4) hyprStartDive(c, Bt, 3); else startWipe(Bt, 1.5);
      hyprNewFlow(c, c.B, rand);
    }
  } else if (F.build > 0.4 && !c.buildDone && !c.B) {
    c.buildDone = true; const A = c.A;
    startWipe(hyprMakeTiling(rand, { not: [A.p, A.q], finer: true, motif: A.motif, pal: A.pal, model: A.model, macro: A.macro }), 2);
  } else if ((F.onBar || F.onSceneBar) && canDive && F.build < 0.2 && c.bars % 4 !== 3 && rand() < 0.02) {
    // rare surprise: a dive mid-phrase
    c.bars++; const A = c.A;
    hyprStartDive(c, hyprMakeTiling(rand, { not: [A.p, A.q], notMotif: A.motif, model: rand() < 0.5 ? A.model : undefined }), 6);
    hyprNewFlow(c, c.B, rand);
  } else if ((F.onBar || F.onSceneBar)) {
    c.bars++; if (F.build < 0.2) c.buildDone = false;
    if (c.bars % 16 === 0) c.mdir = -c.mdir;
    if (!c.B && c.bars % 4 === 0) {
      // every 4 bars a new palette, every 8 a new motif, every 16 a new tiling (now and then a new cathedral or view)
      const A = c.A;
      if (c.bars % 16 === 0) {
        // a new tiling: a wipe, or (from a cathedral view) a dive through the central jewel into a new world and view
        const dive = A.model < 2 && rand() < 0.4;
        const model = rand() < (dive ? 0.5 : 0.25) ? hyprPick(rand, HYPR_MODELS.filter((m) => m !== A.model)) : A.model;
        const Bt = hyprMakeTiling(rand, { not: [A.p, A.q], notMotif: A.motif, model, macro: rand() < 0.4 ? undefined : A.macro });
        if (dive) hyprStartDive(c, Bt, 6); else startWipe(Bt, 2);
        if (model !== A.model) hyprNewFlow(c, c.B, rand);
      } else if (c.bars % 8 === 0) {
        // (the new look may also swap faceted stones for black opal and the round jewels for leaded panes)
        // a new motif; arriving at the Wythoff motif it starts from the plain jewel tiling and morphs through its truncations
        const N = hyprRestyle(rand, A); startWipe(N, 2);
        if (N.motif === 3) { c.wy = [0.93, 0]; c.sweep = bc + 2; }
      }
      else { const N = hyprRestyle(rand, A); N.motif = A.motif; N.style = A.style; N.pal = (A.pal + 1 + Math.floor(rand() * 7)) % 8; startWipe(N, 1.5); }
    }
  }
  let wr = -1, kB = 1;
  if (c.dv) {
    // the window is the central micro jewel's rim, then it opens past the screen edge before the dive ends
    const t = Math.min(c.dv.t, 1), g = t < 0.5 ? 0 : (t - 0.5) * 2, g2 = g * g * (3 - 2 * g);
    wr = c.dv.r0 * PTR.zoom * (V.kz ?? 1) * Math.exp(c.lz) * (1 + 3 * g2) + 1.2 * g2 * g2; kB = 1 / c.dv.Z;
    if (c.dv.t >= 1) { c.A = c.B; c.B = null; c.lz -= Math.log(c.dv.Z); c.dv = null; wr = -1; kB = 1; }
  } else if (c.B) {
    c.w += dt * bps / c.wDur; if (c.w >= 1) { c.A = c.B; c.B = null; c.w = 0; }
    if (c.B) wr = 1.12 * Math.pow(c.w, 1.3);
  }
  // Wythoff morph: every 8 beats the point glides to a new keyframe (the tiling morphs through its truncations);
  // now and then a sweep runs through all of them in 8 beats
  if (c.lastWy !== ph8) { c.lastWy = ph8; c.wyT = hyprPick(rand, HYPR_WY); if (c.sweep < 0 && rand() < 0.12) c.sweep = bc; }
  if (c.sweep >= 0) {
    const k = (bc - c.sweep) / 8 * (HYPR_WY.length - 1), i = Math.floor(k);
    if (k < 0) c.wyT = HYPR_WY[0];
    else if (i >= HYPR_WY.length - 1) c.sweep = -1;
    else { const f = k - i, e = f * f * (3 - 2 * f); c.wyT = [0, 1].map((j) => HYPR_WY[i][j] + (HYPR_WY[i + 1][j] - HYPR_WY[i][j]) * e); }
  }
  for (let j = 0; j < 2; j++) c.wy[j] = ease(c.wy[j], c.wyT[j], dt, (c.sweep >= 0 ? 0.08 : 0.5) / bps);
  // palette: a quick crossfade (about a quarter beat) toward the newest tiling's palette
  // (a drop snaps it: colour may jump on a transient, and a slow RGB blend would pass through muddy greys)
  const PT = HYPR_PALS[(c.B || c.A).pal], kp2 = c.palSnap && (PTR.zoom || 1) > 0.6 ? 1 : 1 - Math.exp(-dt * bps * 5 * Math.min(1, Math.max(0.35, Math.sqrt(PTR.zoom || 1)))); // v13: zoomed far out the whole field (and the flat ground round the disk) recolours at once, so drops fade there (~0.2 s) instead of snapping, and phrase fades run a little slower
  c.palSnap = false;
  for (let i = 0; i < 8; i++) for (let j = 0; j < 3; j++) c.pal[i][j] += (PT[i][j] - c.pal[i][j]) * kp2;
  const pk = hyprPackPal(c.pal);
  const pa = hyprPack(c.A), pb = c.B ? hyprPack(c.B) : pa;
  V.p1 = pa; V.p2 = c.A.Ys.slice(); V.p3 = pb; V.p4 = (c.B || c.A).Ys.slice();
  const pwB = c.B ? c.B.pw : c.A.pw;
  V.p5 = [wr, pwB[0], pwB[1], c.flipT + 1024 * pk.deep];
  const wyP = Math.round(clamp(c.wy[0], 0, 1) * 1023) + 1024 * Math.round(clamp(c.wy[1], 0, 0.9) * 1023);
  const rgP = Math.floor(Math.min(c.ringR, 60) * 128) * 128 + Math.floor(clamp(c.ringA, 0, 1.4) * 90);
  // v12 hat activity (each hat adds, 0.25 s release) rides above the snare wave clock: lights the grout neon and vertex glints
  // v13: the hold envelope is followed with a 60 ms attack, so the hat light (jewel glitter, rims) swells and never chatters
  c.haT = Math.max((c.haT || 0) * Math.exp(-dt / 0.3), Math.min(1, (F.hat || 0) * 1.2), BO[6] * 0.9, BO[7]);
  c.ha = (c.ha || 0) + (c.haT - (c.ha || 0)) * (1 - Math.exp(-dt / 0.06));
  V.m1 = new Float32Array([c.la, c.mth, kB, c.midPh, Math.exp(c.lz), c.spin, wyP, c.flipR + 64 * Math.round(Math.min(1, c.ha) * 100), rgP]);
  V.m2 = new Float32Array([pk.k[0], pk.k[1], pk.k[2], pk.k[3], pk.k[4], pk.k[5], pk.k[6], c.A.pw[0], c.A.pw[1]]);
  // v14: the hat envelope (above) and two band levels go to the engine's own per-realm slot V.qa, which it uploads as
  // uQa packed as full floats; the m1 pack still carries its rounded copy, so anything else that reads it is unchanged.
  V.qa = [Math.min(1.2, c.ha), B[5], B[4], BO[5]];
}
