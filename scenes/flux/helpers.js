// ISOBAR palettes: five-step ramps (dark -> light) plus an accent ink, all sRGB hex.
const fluxPALS = [
  ['1a0848', '5a1fd6', 'ff3d7f', 'ff8f5c', 'ffd23f', '00e0c8'], // ultraviolet -> hot coral -> sun
  ['2c0b40', '0b7f88', '3fe8b0', 'ff6fb8', 'ffd84d', '7a3cff'], // plum -> teal -> mint -> pink -> yellow
  ['0a1a5c', '0078c8', 'ff48b0', 'ffe600', 'ffa463', 'ff6c2f'], // riso blue / fluoro pink / yellow
  ['2b0638', 'a8136e', 'ff4a2c', 'ffac1c', 'ffe14a', '28ccff'], // magenta sunset
  ['060e3c', '2442ff', '1fd6ff', 'b8ff38', 'e6ff6e', 'ff2ad4'], // electric blue -> lime
  ['3a0c22', 'e2213a', 'ff8a1a', 'ff8ad0', 'b49cff', '3b2bff'], // tomato / tangerine / lilac
  ['04261f', '0a9064', 'c6f23a', 'ff2f9e', 'ff9ad8', '7040ff'], // jungle -> chartreuse -> magenta
  ['15063c', '6a2aff', '3ec6ff', '8dffd8', 'c6f6ff', 'ff5a86'], // ice violet
  ['12063a', '0050ff', 'ff2e88', 'ff9e00', 'fff23a', '00d68f'], // riso clash: blue / fluoro pink / orange / yellow
  ['1a0010', 'd0002a', 'ff5a36', '00c2b0', '9bfff0', 'ffd400'], // red vs teal
  ['14002e', '7a00ff', 'ff00b4', 'ff6e3c', 'd4ff3a', '00f0ff'], // violet / magenta / lime
  ['001a2e', '00807a', '00e0a0', 'ffe066', 'ff4fa0', '7b2cff'], // lagoon -> sun -> pink
  ['ff2e6e', 'ff8a00', 'ffe600', '35e0a8', '19b6ff', '5b1cff'], // v19: full spectrum poster, no dark end
  ['6a00f4', 'd100d1', 'f72585', 'ffb703', 'fff3b0', '00f5d4'], // ultra grape to cream
  ['004e64', '00a5cf', '9fffcb', 'ffe45e', 'ff6392', 'ff006e'], // tropic print
  ['ff5400', 'ffbd00', 'fff275', '8ac926', '1982c4', '6a4c93'], // citrus atlas
  ['3a0ca3', '4361ee', '4cc9f0', 'f8f7ff', 'ffc8dd', 'f72585'], // ice sugar
  ['b5179e', 'ff4d6d', 'ff9e00', 'caffbf', '9bf6ff', '3a86ff'], // candy map
  ['0b6e4f', '08a045', 'd0f4de', 'ffd166', 'ef476f', '118ab2'], // survey green
  ['7f0037', 'ff006e', 'ffbe0b', 'fb5607', 'c0fdff', '8338ec']  // cherry brass
];
function fluxLab(hex) {
  const v = [0, 2, 4].map(i => { const c = parseInt(hex.substr(i, 2), 16) / 255; return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); });
  const l = Math.cbrt(0.4122214708 * v[0] + 0.5363325363 * v[1] + 0.0514459929 * v[2]);
  const m = Math.cbrt(0.2119034982 * v[0] + 0.6806995451 * v[1] + 0.1073969566 * v[2]);
  const s = Math.cbrt(0.0883024619 * v[0] + 0.2817188376 * v[1] + 0.6299787005 * v[2]);
  return [0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s, 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s, 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s];
}
// OKLab -> gamma-ish (sqrt of linear) rgb, which the shader squares back to linear
function fluxGam(L) {
  const l = Math.pow(L[0] + 0.3963377774 * L[1] + 0.2158037573 * L[2], 3), m = Math.pow(L[0] - 0.1055613458 * L[1] - 0.0638541728 * L[2], 3), s = Math.pow(L[0] - 0.0894841775 * L[1] - 1.291485548 * L[2], 3);
  return [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, -0.0041960771 * l - 0.7034186147 * m + 1.707614701 * s].map(x => Math.sqrt(Math.max(0, x)));
}
function fluxPalLab(i) { return fluxPALS[i].map(fluxLab); }
// field sources are laid out here (pixel-invariant, so not per pixel in the shader): position and base weight
function fluxH4(x, y) {
  const f = Math.fround, fr = v => { v = f(v); return f(v - Math.floor(v)); };
  const q = [fr(x * 0.1031), fr(y * 0.103), fr(x * 0.0973), fr(y * 0.1099)];
  const d = f(q[0] * (q[3] + 33.33) + q[1] * (q[2] + 33.33) + q[2] * (q[0] + 33.33) + q[3] * (q[1] + 33.33));
  for (let i = 0; i < 4; i++) q[i] = f(q[i] + d);
  return [fr((q[0] + q[1]) * q[2]), fr((q[0] + q[2]) * q[1]), fr((q[1] + q[2]) * q[3]), fr((q[2] + q[3]) * q[0])];
}
function fluxSrc(cfg, i, n, clk) {
  const TAU = 2 * Math.PI, nn = Math.max(n, 1), j = i < n ? i : i % nn;
  const h = fluxH4(cfg * 17.31 + 3.1, j * 5.77 + 1.3), g = fluxH4(cfg * 7.7 + 0.3, 9.1);
  const ros = g[0] < 0.42;
  if (!ros && g[0] < 0.7) {
    const pr = Math.floor(j * 0.5), hx = (g[2] * (pr * 7.13 + 3.7) + pr * 0.618) % 1, hy = (g[3] * (pr * 7.13 + 3.7) + pr * 0.618) % 1;
    const pa = TAU * pr / Math.max(Math.ceil(nn * 0.5), 1) + cfg * 1.7 + clk * 0.35, ba = clk * 1.6 * (hx < 0.5 ? 1 : -1) + (j % 2) * Math.PI;
    const R = nn < 2.5 ? 0 : 0.24, rb = 0.09 + 0.05 * hy;
    return [Math.cos(pa) * 1.45 * R + Math.cos(ba) * rb, Math.sin(pa) * R + Math.sin(ba) * rb, (0.8 + 0.4 * h[2]) * (i < n ? 1 : 0)];
  }
  const a = ros ? TAU * j / nn + cfg * 2.4 + clk * 0.55 : TAU * (j + 0.6 * h[0]) / nn + cfg * 2.4 + clk * (0.35 + 0.6 * h[1]) * (h[3] < 0.25 ? -1 : 1);
  const R = ros ? (n < 1.5 ? 0 : 0.2 + 0.16 * g[1]) : 0.1 + 0.32 * h[3];
  return [Math.cos(a) * 1.5 * R + 0.07 * Math.sin(clk * (1.1 + h[2]) + h[1] * 6), Math.sin(a) * R + 0.07 * Math.cos(clk * (0.9 + h[2]) + h[3] * 6), (0.75 + 0.5 * h[2]) * (i < n ? 1 : 0)];
}
function fluxNewCfg(c, beats, drop) {
  // start a topology change: sources glide, split or merge into a new configuration over `beats`
  if (c.mo > 0 && c.mo < 1) { c.pend = drop ? 2 : Math.max(c.pend, 1); c.moRate = 3; return; }
  c.cfgA = c.cfgB; c.nA = c.nB; c.mo = 0;
  c.cfgB = (c.cfgB * 7.31 + 0.377 + rand()) % 97;
  let n = c.nA;
  while (n === c.nA) n = 2 + Math.floor(rand() * 5);
  if (c.fam === 3) n = Math.min(n, 4);
  c.nB = n; c.moDur = beats; c.moRate = 1;
}
// v19 a new fold of the map (or none) and a new print texture for the cells; the old fold closes first, so a change is always a glide
function fluxNewDom(c, chance) {
  c.dmNext = rand() < chance ? Math.floor(rand() * 4) : -1; c.dnNext = 2 + Math.floor(rand() * 3);
  if (rand() < 0.7) { c.txNext = rand() < 0.78 ? Math.floor(rand() * 10) : -1; }
}
function fluxDrop(c) {
  fluxNewDom(c, 0.75);
  fluxNewCfg(c, 1.5, true);
  c.dir = -c.dir;
  let p = c.pal; while (p === c.pal) p = Math.floor(rand() * fluxPALS.length);
  c.pal = p; c.palT = fluxPalLab(p); c.palRate = 4;
  if (rand() < 0.45) c.st = Math.floor(rand() * 4);
  if (rand() < 0.5) c.foil = Math.floor(rand() * 4);
  c.ev = null;
  fluxNewComp(c, 1);
  c.swK += 2.2 * c.dir;
  c.r2 = c.r1; c.r1 = { i: 7, age: 0, a: 1.6 };
  c.colT += 4;
  c.fswT += 2.5;
}
// composition modes [macro zoom, strata, islands, atlas pull-back, inset, overprint] and the inset shape
// (0 loupe, 1 inset sheet): full field, islands on a dark sea, macro on one source, horizon (strata under a dark
// sky), strata, macro coastline, atlas, continents, loupe, inset sheet, overprint, macro overprint
const fluxCOMP = [[0, 0, 0, 0, 0, 0], [0, 0, 1, 0, 0, 0], [1, 0, 0, 0, 0, 0], [0, 1, 1, 0, 0, 0], [0, 1, 0, 0, 0, 0], [1, 0, 1, 0, 0, 0],
  [0, 0, 0, 1, 0, 0.6], [0, 0, 1, 0.8, 0, 0], [0, 0, 0, 0, 1, 0], [0, 0, 0, 0.3, 1, 0], [0, 0, 0, 0, 0, 1], [1, 0, 0, 0, 0, 1]];
// paper tilt per composition: the sheet leans back into perspective, so the map recedes towards a far horizon
const fluxTILT = [0, 0, 0, 0.8, 0.55, 0, 0.65, 0.7, 0, 0.5, 0, 0];
const fluxISH = [-1, -1, -1, -1, -1, -1, -1, -1, 0, 1, -1, -1];
// mood 0 normal, 1 drop (focal impact), 2 breakdown (calm, vast)
function fluxNewComp(c, mood) {
  const pool = mood === 1 ? [0, 8, 2, 9, 11, 0, 8] : mood === 2 ? [6, 7, 4, 1, 3, 6] : [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 8, 9, 6];
  let m = c.comp, k = 0;
  while ((m === c.comp || (mood === 1 && m === c.comp)) && k++ < 20) m = pool[Math.floor(rand() * pool.length)];
  c.comp = m; c.cmRate = mood === 1 ? 2.4 : 0.55;
  c.tlx = fluxCOMP[m][0] < 0.5 && rand() < 0.3 ? 0.35 + 0.3 * rand() : 0;
  fluxFocus(c);
  if (fluxISH[m] >= 0) c.iShT = fluxISH[m];
  if (rand() < 0.35) c.iSty = 1 - c.iSty;
}
// the focus (macro / inset) glides from the current source to a new one
function fluxFocus(c) {
  const n = Math.max(1, Math.min(c.nA, c.nB));
  const cur = c.ft > 0.5 ? c.fb : c.fa;
  let f = Math.floor(rand() * n); if (f === cur && n > 1) f = (f + 1) % n;
  c.fa = cur; c.fb = f; c.ft = 0;
}
