// VELVET: weave drafts are 8x8 over/under matrices (1 = the row ribbon passes over the column ribbon)
const VELVET_DRAFTS = [
  (i, j) => (i + j) % 2,                                        // plain
  (i, j) => (i + j) % 4 < 2,                                    // 2/2 twill
  (i, j) => (((i >> 1) + (j >> 1)) % 2),                        // 2x2 basket
  (i, j) => (j * 3 + i) % 8 !== 0,                              // 8-harness satin (long satin floats)
  (i, j) => { const k = j % 8; return (((i + (k < 4 ? j : -j)) % 4) + 4) % 4 < 2; }, // herringbone
  (i, j) => (Math.abs(i - 4) + Math.abs(j - 4)) % 4 < 2,        // diamond twill
  (i, j) => (((i - j) % 4) + 4) % 4 !== 0,                      // 3/1 twill
  (i, j) => { const b = ((i >> 2) + (j >> 2)) % 2; return (((i + (b ? -j : j)) % 4) + 4) % 4 < 2; }, // pinwheel twill
  (i, j) => (((i >> 2) + (j >> 2)) % 2),                        // 4x4 basket (checkerboard of floats)
  (i, j) => (i + (j >> 1)) % 2,                                 // rib weave
  (i, j) => [0, 1, 3, 2][i % 4] === j % 4 ? 0 : 1,              // crow's foot
  null,                                                         // dobby: a random mirrored draft
  // v21: nine more structures
  (i, j) => (i + [0, 1, 3, 2][j % 4]) % 4 < 2,                   // 12 broken twill
  (i, j) => (i + Math.abs((j % 8) - 4)) % 4 < 2,                 // 13 point twill (a zigzag across the warp)
  (i, j) => (Math.abs((i % 4) - 2) + Math.abs((j % 4) - 2)) % 2, // 14 bird's eye
  (i, j) => Math.max(Math.abs((i % 8) - 3.5), Math.abs((j % 8) - 3.5)) % 2 < 1, // 15 honeycomb (nested squares of floats)
  (i, j) => ((i % 8 < 4) === (j % 8 < 4) ? (i + j) % 2 : i % 2), // 16 huck: blocks of plain weave between blocks of floats
  (i, j) => j % 4 !== 0,                                         // 17 rep: the rows ride over three and under one
  (i, j) => ([0, 2, 1, 3][i % 4] === j % 4 ? 1 : 0),             // 18 satinet
  (i, j) => (i * 2 + j) % 8 < 4,                                 // 19 steep twill
  (i, j) => (j + Math.abs((i % 8) - 4)) % 4 < 2                  // 20 point twill the other way (a zigzag along the warp)
];
// v21 setts: the order of colours across the warp and across the weft, eight ribbons each, and the weave that goes with it (-1: any).
// a, b, c are the palette's three ribbon colours dealt afresh each generation; 0 is the metal thread.
const VELVET_SETTS = [
  ['aaabaaab', 'cccccccc', -1], ['abababab', 'cccccccc', -1], ['aabbaabb', 'cccccccc', -1], ['abcbabcb', 'bcacbcac', -1],   // the four old orders, near enough
  ['aaaabbbb', 'aaaabbbb', 1],   // houndstooth: four and four on a 2/2 twill
  ['aaaabbbb', 'aaaabbbb', 0],   // gingham
  ['aabbaabb', 'aabbaabb', 1],   // glen check
  ['ababbaba', 'ababbaba', 0],   // log cabin
  ['aaa0aaaa', 'bbbbbbbb', -1],  // a pin stripe of metal
  ['aab0baac', 'aab0baac', -1],  // tartans, mirrored setts
  ['abccbaac', 'abccbaac', -1],
  ['aaabbbcc', 'ccbbbaaa', -1],  // ombre, warp against weft
  ['aaabaaac', 'bbbcbbba', -1],  // broad grounds with single threads of the other colours
  ['aaaacccc', 'bbbbbbbb', 19],  // broad stripes on a steep twill
  ['a0a0a0a0', 'bbbbcccc', -1],  // metal and silk by turns
  ['aabbccbb', 'aabbccbb', 13]   // a plaid on a point twill
];
function velvetSett(h) {
  const t = VELVET_SETTS[Math.floor(h * VELVET_SETTS.length) % VELVET_SETTS.length], k = Math.floor(h * 977) % 6;
  const P = [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]][k], enc = (o) => { let v = 0; for (let i = 0; i < 8; i++) v += (o[i] === '0' ? 0 : P[o.charCodeAt(i) - 97]) * Math.pow(4, i); return v; };
  return { sw: enc(t[0]), sf: enc(t[1]), wv: t[2] };
}
function velvetDraft(type, R) {
  let f = VELVET_DRAFTS[type];
  if (!f) {
    const t = []; for (let k = 0; k < 16; k++) t.push(R() < 0.5 ? 1 : 0);
    const m = (i) => (i < 4 ? i : 7 - i);
    f = (i, j) => t[m(i) * 4 + m(j)] ^ ((i + j) % 2);
  }
  const inv = R() < 0.3, tr = R() < 0.5, w = [0, 0, 0];
  for (let i = 0; i < 8; i++) for (let j = 0; j < 8; j++) {
    let b = (tr ? f(j, i) : f(i, j)) ? 1 : 0; if (inv) b ^= 1;
    if (b) w[Math.floor(i / 3)] += Math.pow(2, (i % 3) * 8 + j);
  }
  return w;
}
// one "generation" of the loom = palette, weave draft, embroidery motif, ribbon width, colour sequence, thread
function velvetGen(lay, prev, R) {
  R = R || rand;
  const n = lay === 2 ? 3 : VELVET_DRAFTS.length;
  let pal = Math.floor(R() * 8) % 8; if (prev && pal === prev.pal) pal = (pal + 1 + Math.floor(R() * 7)) % 8;
  let wv = Math.floor(R() * n) % n; if (prev && wv === prev.wv) wv = (wv + 1 + Math.floor(R() * (n - 1))) % n;
  // gs seeds the embroidery: every colour slot gets its own medallion family, border row and stitch (see vvSlot)
  const gs = Math.floor(R() * 4096) / 4096;
  // v21: gs also deals the sett (which can ask for its own weave) and the family of the great carpet figure
  const st = velvetSett((gs * 7.31 + 0.137) % 1), fam = Math.floor(((gs * 13.7 + 0.61) % 1) * 5) % 5;
  if (lay !== 2 && st.wv >= 0) wv = st.wv;
  // w4: most generations carry a figure (and are a plain weave under it); now and then the cloth rests in a plain twill, satin or basket
  const kn = lay !== 2 && R() < 0.84, kk = Math.floor(R() * 12);
  // square and lozenge looms are sometimes woven open, so the glowing backing shows through
  const wr = kn ? [0.62, 0.73] : (lay === 0 || lay === 3) && R() < 0.4 ? [0.5, 0.64] : [[0.8, 0.93], [0.64, 0.8], [0.25, 0.31], [0.76, 0.9]][lay];   // w4: a band that turns corners is a little narrower, so its path reads
  const seq0 = Math.floor(R() * 4) % 4;   // (kept so the generator's later draws stay where they were)
  const G = { pal, wv, gs, w: wr[0] + (wr[1] - wr[0]) * R(), seq: lay === 2 ? seq0 : st.sw, sf: st.sf, fig: fam * 256 + (1 + Math.floor(R() * 4) % 4) * 16 + 5 + Math.floor(R() * 8), bits: velvetDraft(lay === 2 ? 0 : wv, R) };
  // the heavier figures come up more often than the plain windings
  if (kn) velvetKnot(G, [0, 0, 0, 1, 1, 2, 3, 4, 5, 6, 7, 8][kk % 12], R);
  return G;
}
function velvetPack(g) { return new Float32Array([g.pal + 8 * (g.sf || 0), g.kn || g.wv, g.gs, g.w, g.seq, g.fig, g.bits[0], g.bits[1], g.bits[2]]); }
// loom framing per phrase: [scale multiplier], from fine ribbons to macro ribbons three or four across the screen
const VELVET_FORMS = [[2.4], [2.6], [2.8], [3.1], [2.5], [2.95]];   // w4: the bands are the scene: broad at the home framing (five to eight of them up the screen)
function velvetForm(prev, R) { let f = Math.floor(R() * 6) % 6; if (f === prev) f = (f + 1 + Math.floor(R() * 5)) % 6; return f; }
// w4 THE KNOT (see work/velvet/NOTES-V22.md, wave 4). A figure is a set of BROKEN crossings on a plain weave, period 8 by 8: bit a*8+b is the
// crossing of column a and row b. At a broken crossing the two bands turn a rounded corner onto each other's line instead of crossing, so the
// bands themselves wind into curls, loops and knots and run on into the cloth; over-under stays strictly alternating. Every pattern here was
// traced on the torus (work/velvet/w4/tools/knot.py): no band closes on itself inside a figure. They may be shifted by even steps only.
const VELVET_KNOTS = ['1166434518622538760', '17798546325504', '2783368605750855012', '5081678860790243682', '469711367386112352', '7106964985514853702',
  '72624976532079105', '145249884080210433', '134480385'];
// which of them a visit may meet, heaviest first: 0 a curl at every corner of a frame of four bands, 1 an S of two curls, 2-5 four-fold knots of
// loops, 6-8 the bands simply wind (zigzag, lozenge, chevron)
function velvetKnot(g, k, R) {
  let v = BigInt(VELVET_KNOTS[k]); const di = 2 * (Math.floor(R() * 4) % 4), dj = 2 * (Math.floor(R() * 4) % 4), br = [];
  for (let n = 0; n < 64; n++) if ((v >> BigInt(n)) & 1n) br.push([((n >> 3) + di) % 8, ((n & 7) + dj) % 8]);
  // lines joined by a break are one band: one colour for every class (union-find over 8 columns + 8 rows)
  const par = []; for (let i = 0; i < 16; i++) par.push(i);
  const f = (x) => { while (par[x] !== x) x = par[x]; return x; };
  const w = [0, 0, 0]; let mask = 65536;
  for (const [a, b] of br) { par[f(a)] = f(8 + b); w[Math.floor(a / 3)] += Math.pow(2, (a % 3) * 8 + b); if (!(mask >> a & 1)) mask += 1 << a; if (!(mask >> (8 + b) & 1)) mask += 1 << (8 + b); }
  // the ground keeps the sett; the classes take the palette's three colours in a dealt order
  const dig = (v4, i) => Math.floor(v4 / Math.pow(4, i)) % 4, col = [], row = [];
  for (let i = 0; i < 8; i++) { col.push(dig(g.sf, i)); row.push(dig(g.seq, i)); }   // col[] is indexed by the shader's own column index (8 - a) % 8
  const deal = [3, 1, 2], o = Math.floor(R() * 3) % 3, cls = {}; let nc = 0;   // (never the metal thread: a figure in pale metal is a pale figure)
  for (let x = 0; x < 16; x++) {
    if (!(mask >> x & 1)) continue;
    const c = f(x); if (cls[c] === undefined) cls[c] = deal[(nc++ + o) % 3];
    if (x < 8) col[(8 - x) % 8] = cls[c]; else row[x - 8] = cls[c];
  }
  // the ground beside a feature band never wears the same colour as it (the figure must stand off the cloth)
  if (nc < 3) for (let x = 0; x < 16; x++) {
    if (mask >> x & 1) continue;
    const used = Object.values(cls), free = [1, 2, 3].filter((q) => used.indexOf(q) < 0), arr = x < 8 ? col : row, ix = x < 8 ? (8 - x) % 8 : x - 8;
    if (used.indexOf(arr[ix]) >= 0 && free.length) arr[ix] = free[(x + (x >> 1)) % free.length];
  }
  const enc = (arr) => arr.reduce((s, d, i) => s + d * Math.pow(4, i), 0);
  g.sf = enc(col); g.seq = enc(row); g.bits = w; g.kn = mask; g.kk = k;
}
