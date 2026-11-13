function optikPickOther(n, cur) { let v; do { v = Math.floor(rand() * n); } while (v === cur && n > 1); return v; }
// focal-sphere anchors on the thirds (plus a centre seat); the sphere moves to another one every 4-bar phrase
const optikAnchors = [[-.3, .06], [.3, -.05], [-.22, -.1], [.26, .1], [.05, 0], [-.34, -.04], [.34, .07], [-.08, .12], [.12, -.11]];
// sub-variants per family: VEGA 7 cell decorations (x2 lattice ground), STRIPES 4 (Riley, Zebra, ring moire, line
// moire), CUBE 4 (contours, Tridim, impossible corner, Schroeder stairs), TUNNEL/BLAZE 7 cell decorations; decoration 6
// is the peripheral-drift tile
// v19: 12 illusion families (5 QUASI, 6 QUILT, 7 LOOM, 8 SCALES, 9 ROSETTE, 10 PRESS, 11 ROWS are new)
// v20: 20 families (12 SNAKES, 13 ROTO, 14 STRING, 15 RIDGE, 16 MOVE, 17 PINNA, 18 ENIGMA, 19 TRIBAR are new)
const optikSubs = [7, 2, 4, 7, 7, 8, 8, 4, 4, 4, 1, 4, 4, 8, 4, 4, 7, 4, 4, 4];
// family 10 (PRESS) is retired; the live families, in the order the seed picks from
const optikFams = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19], optikNF = optikFams.length;
// illusions built around the focal point (their far cells crowd into its centre): never used as the second illusion of a zone,
// where the focal bulge would blow that crowded centre up into one plain disc
const optikCentred = f => f === 3 || f === 4 || f === 13 || f === 17 || f === 18;
function optikPickFam(cur) { let v; do { v = optikFams[Math.floor(rand() * optikNF)]; } while (v === cur || optikCentred(v)); return v; }
// zone layout pack: secondary family/palette, secondary bits, layout (0 none 1 sphere window 2 rings 3 wedges 4 hex patches 5 slabs)
function optikZonePack(c) { return c.f2 * 16 + c.p2 + 512 * c.b2 + 131072 * c.zm; }
// a shuffle bag: every family comes up once before any repeats
function optikNextFam(c) { if (!c.bag || !c.bag.length) { c.bag = []; for (let i = 0; i < optikNF; i++) c.bag.splice(Math.floor(rand() * (c.bag.length + 1)), 0, optikFams[i]); } let f = c.bag.pop(); if (f === c.fam) { c.bag.unshift(f); f = c.bag.pop(); } return f; }
function optikBits(c) { return c.sub + 8 * c.duo + 16 * (c.prof - 1) + 32 * c.lat + 64 * (c.inv % 2); }
// satellite lens choreographies (positions relative to the focal sphere; o = orbit phase, i = lens, t = time)
// 0 orbit, 1 figure-eight, 2 parade (lenses ride a wave across and fade at the ends), 3 binary star
function optikSat(m, i, o, t) {
  const TAU = Math.PI * 2;
  if (m === 0) { const a = o + i * TAU / 4 + .3 * Math.sin(t * .07 + i), rr = .62 + .12 * Math.sin(t * .09 + i * 1.7); return [Math.cos(a) * rr * 1.35, Math.sin(a) * rr * .8, 1, 1]; }
  if (m === 1) { const a = o * .7 + i * TAU / 4; return [Math.sin(a) * 1.05, Math.sin(2 * a) * .42, 1, 1]; }
  if (m === 2) { const f = (o / TAU * .5 + i / 4) % 1, x = -1.3 + 2.6 * f; return [x, .3 * Math.sin(x * 3 + o * 1.5), 1, Math.sin(Math.PI * f)]; }
  // 4 equaliser row: the four band lenses stand in a row beside the focal sphere and bob with a slow wave
  if (m === 4) { const x = -.84 + .56 * i; return [x, -.5 + .07 * Math.sin(o * 2 + i * 1.3), .85, 1]; }
  // 5 crown: the four lenses ride close around the focal sphere like moons, slowly turning
  if (m === 5) { const a = o * 1.3 + i * TAU / 4; return [Math.cos(a) * .6, Math.sin(a) * .5, .7, 1]; }
  const a = o * (i === 0 ? 1.6 : .8) + i * TAU / 3, rr = i === 0 ? .58 : .95;
  return [Math.cos(a) * rr * 1.2, Math.sin(a) * rr * .72, i === 0 ? 1.55 : .75, 1];
}
