function tykesRng(seed) { let s = Math.floor(seed * 2147483646) + 1; const r = () => (s = (s * 16807) % 2147483647) / 2147483647; for (let i = 0; i < 6; i++) r(); return r; }
// exact critically damped spring step (stable at any dt)
function tykesSpr(o, k, tgt, w, dt) {
  const x0 = o[k] - tgt, v0 = o[k + 'v'] || 0, e = Math.exp(-w * dt), a = v0 + w * x0;
  o[k] = tgt + (x0 + a * dt) * e; o[k + 'v'] = (v0 - w * a * dt) * e;
}
// families: 0 tower (acrobats, hats between the legs above), 1 zip (strips of head-to-toe gnomes), 2 wheels (turning rings of gnomes)
// step: what one tick of the mechanism is (a strip slides one figure along; a wheel turns one figure round); fsc: drawn size
const TYKES_FAM = [ { step: 1, fsc: 1 }, { step: 1, fsc: 1.1 }, { step: Math.PI / 4, fsc: 1 } ];
// nH, nV: how many times the figures of this level have changed places sideways / by rows (the shader finds who stands where from
// them); flip: the tower's cut is mirrored (everyone on their hands)
function tykesSlot(r, fam) { return { fam, awA: 1, awB: 1, cw: Math.floor(r() * 4), look: r() < .5 ? 4 : 0, morph: 0, pan: [r() * 6, r() * 6], th: 0, thT: 0, lag: 0, single: 0, nH: 0, nV: 0, flip: 0 }; }
function tykesPack(s, o, i, n) {
  o[i] = 1048576 * n + s.fam + 4 * s.single + 8 * Math.round(clamp(s.awB, 0, 1) * 63) + 512 * Math.round(clamp(s.awA, 0, 1) * 63) + 32768 * (s.cw & 3) + 131072 * (s.look & 7) + 4194304 * (s.flip ? 1 : 0);
  o[i + 1] = Math.round(clamp(s.morph, 0, 1) * 255) + 256 * (s.nH & 255) + 65536 * (s.nV & 255); o[i + 2] = s.pan[0]; o[i + 3] = s.pan[1];
}
// a layout: 0 the flat plane (upright, or leaning a sixteenth or an eighth of a turn), 1 rings round one pole, 2 rings pouring
// between two poles. A visit starts flat (the figures changing places is the scene); the rings are short episodes and always
// give way to the plane again.
function tykesFlat(r) { return 4 * [0, 0, 0, 0, 0, 1, 15, 2, 14, 0][Math.floor(r() * 10)]; }
function tykesLay(r, prev) {
  const pk = prev < 0 ? 1 : (prev & 3); const k = pk === 0 ? (r() < .55 ? 1 : 2) : 0;
  return k === 0 ? tykesFlat(r) : k + 4 * Math.floor(r() * (k === 1 ? 12 : 16));
}
// where a ring of laughter starts, in quarter tiles either side of the middle of the picture
function tykesWp(w) { return clamp(Math.round(w[0] * 4) + 2048, 0, 4095) + 4096 * clamp(Math.round(w[1] * 4) + 2048, 0, 4095); }
// the moves a visit is dealt for its kicks: eight in a row, each 0 (the mechanism ticks: hats swing, strips slide, wheels turn)
// or type + 8 * style of an exchange in the air. Tower types: 1 neighbours change places (styles: 0 leapfrog with a somersault,
// 1 both roll, 2 through each other, 3 both flip; +4 one pair after another along the row), 2 rows change places (0 climbing
// round, 1 both somersault, 2 one somersaults; +4 column after column), 3 a somersault on the spot (0 everyone, 1 and 2 one
// half of the board, then the other). Zip type 1: pairs cartwheel half round the point between them (+1: alternate pairs first).
// (v22 wave 2: the owner wants the fit kept while they move, and loves the gears going back and forth and the travelling rows: most kicks
// are the mechanism, which never opens a gap; the flights, where a figure leaves a hole and lands in its neighbour's, are the accents)
const TYKES_DEAL = [
  [ [0, 0, 0, 0, 1, 1, 1, 1], [1, 0, 1, 0, 1, 0, 1, 0], [0, 0, 11, 19, 0, 0, 11, 19], [0, 0, 0, 0, 9, 9, 9, 9], [33, 0, 0, 0, 34, 0, 0, 0],
    [17, 17, 0, 0, 17, 17, 0, 0], [0, 0, 0, 0, 25, 25, 3, 0], [1, 0, 0, 0, 2, 0, 0, 0], [0, 0, 0, 0, 0, 0, 11, 19], [9, 9, 0, 0, 42, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0], [1, 1, 1, 1, 0, 0, 0, 0] ],
  [ [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 1, 0, 0, 0, 1], [0, 0, 0, 0, 1, 1, 0, 0], [0, 0, 9, 0, 0, 0, 9, 0], [1, 0, 0, 0, 1, 0, 0, 0], [0, 0, 0, 0, 0, 0, 1, 1],
    [1, 1, 0, 0, 0, 0, 0, 0] ],
  [ [0, 0, 0, 0, 0, 0, 0, 0] ]
];
// (wave 3) the journey a visit takes: legs dealt per visit, one on every phrase line (or section). in / out: down into the elves a
// figure is made of, or up to the giants it is part of (one level, the family on top changes); deep / high: two levels; close / far:
// stop at the big characters or at the giants made of elves, then go on or come back; pan: travel across the plane; ring: the rings
// open (the fractal circles); seam: a seam or a paper fold brings another family, upright <-> diagonal. Dealt so that all three
// families are on top within the first five legs, the rings come within the first seven and the seam within the first eight.
const TYKES_LEGS = ['in', 'out', 'in', 'seam', 'close', 'ring', 'far', 'deep', 'seam', 'out', 'high', 'pan'];
function tykesJDeck(r) {
  const K = TYKES_LEGS.slice(), off = { in: 1, out: 2, deep: 2, high: 1, seam: 1 };
  for (let t = 0; t < 60; t++) {
    for (let i = K.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [K[i], K[j]] = [K[j], K[i]]; }
    let ok = K.indexOf('ring') < 7 && K.indexOf('seam') < 5, f = 0; const seen = new Set([0]);
    for (let i = 0; i < K.length && ok; i++) { if (i && (K[i] === K[i - 1] || (K[i] === 'ring' && K[i - 1] === 'seam') || (K[i] === 'seam' && K[i - 1] === 'ring'))) ok = false; if (i < 5) { f = (f + (off[K[i]] || 0)) % 3; seen.add(f); } }
    if (ok && seen.size === 3) break;
  }
  return K;
}
// a new flat layout for the journey's seam: from upright to a diagonal, from a diagonal back upright (a visit alternates)
function tykesLean(r, lay) { const ai = (lay >> 2) & 15; return 4 * (ai === 0 ? [2, 14, 1, 15, 2, 14][Math.floor(r() * 6)] : 0); }
function tykesDeal(r, fam, prev) { const L = TYKES_DEAL[fam]; let i; do { i = Math.floor(r() * L.length); } while (L.length > 1 && i === prev); return i; }
