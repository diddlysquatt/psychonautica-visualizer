function scribeRng(seed) { let s = Math.floor(seed * 2147483646) + 1; const r = () => (s = (s * 16807) % 2147483647) / 2147483647; for (let i = 0; i < 6; i++) r(); return r; }
const scribeSS = (a, b, x) => { const t = clamp((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t); };
// exact critically damped spring step (stable at any dt)
function scribeSpr(o, k, tgt, w, dt) {
  const x0 = o[k] - tgt, v0 = o[k + 'v'] || 0, e = Math.exp(-w * dt), a = v0 + w * x0;
  o[k] = tgt + (x0 + a * dt) * e; o[k + 'v'] = (v0 - w * a * dt) * e;
}
// the page layouts as the main hand sees them: line slots and cells per slot (the shader computes the same from its geometry)
const SCRIBE_LAY = [
  { n: 12, C: (l) => (l < 5 ? 10 : 19), pen: (l, f) => [(l < 5 ? -0.03 : -0.33) + (l < 5 ? 0.36 : 0.66) * f, 0.38 - l * 0.076 - 0.0602] },
  { n: 24, C: (l) => (l < 12 ? (l < 3 ? 4 : 9) : 9), pen: (l, f) => [(l < 12 ? (l < 3 ? -0.17 : -0.33) : 0.015) + (l < 12 && l < 3 ? 0.155 : 0.315) * f, 0.38 - (l % 12) * 0.076 - 0.0602] },
  { n: 9, C: (l) => (l < 6 ? [13, 13, 20, 20, 27, 27][l] : 19), pen: (l, f) => { if (l >= 6) return [-0.33 + 0.66 * f, -0.335 - (l - 6) * 0.076 - 0.0602]; const rb = 0.1438 + 0.076 * (l >> 1), th = (l & 1) ? -Math.PI * f : Math.PI * (1 - f); return [rb * Math.cos(th), 0.03 + rb * Math.sin(th)]; } },
  { n: 5, C: () => 19, pen: (l, f) => [-0.33 + 0.66 * f, 0.38 - (l < 2 ? l : l + 7) * 0.076 - 0.0602] }
];
// a form: script family 0 cursive, 1 square, 2 wheels, 3 wedges, 4 hanging; layout 0 one column, 1 two columns, 2 rota (rings round a medallion), 3 carpet page;
// palette (10); border 0 cable in pigment, 1 cable in gold, 2 vine
function scribeForm(r, prev, what) {
  const f = prev ? Object.assign({}, prev) : { fam: Math.floor(r() * 5), lay: [0, 0, 1, 2, 3][Math.floor(r() * 5)], pal: Math.floor(r() * 10), bor: Math.floor(r() * 3), mode: Math.floor(r() * 3), deal: Math.floor(r() * 512), al: 1 + Math.floor(r() * 16777000) };
  if (!prev) return f;
  const w = what || { fam: 1, lay: 0.5, pal: 0.6, bor: 0.4 };
  if (r() < w.fam) { f.fam = (f.fam + 1 + Math.floor(r() * 4)) % 5; f.al = 1 + Math.floor(r() * 16777000); }
  if (r() < w.lay) f.lay = (f.lay + 1 + Math.floor(r() * 3)) % 4;
  if (r() < w.pal) f.pal = (f.pal + 1 + Math.floor(r() * 9)) % 10;
  if (r() < w.bor) f.bor = (f.bor + 1 + Math.floor(r() * 2)) % 3;
  f.deal = (f.deal + 1 + Math.floor(r() * 500)) % 512;
  if (r() < (w.mode == null ? 0.7 : w.mode)) f.mode = (f.mode + 1 + Math.floor(r() * 2)) % 3;
  return f;
}
function scribePack(f) { return f.fam + 8 * f.lay + 64 * f.pal + 1024 * f.bor + 4096 * (f.mode || 0) + 16384 * (f.deal || 0); }
// the library: which places hold a great book (the shader's own hash), so the camera only travels to ordinary ones
function scribeH(x) { x >>>= 0; x ^= x >>> 16; x = Math.imul(x, 0x7feb352d) >>> 0; x ^= x >>> 15; x = Math.imul(x, 0x846ca68b) >>> 0; x ^= x >>> 16; return x >>> 0; }
function scribeBig(x, y) { const bx = Math.floor(x / 2), by = Math.floor(y / 2); if (bx === 0 && by === 0) return false; return scribeH(((bx + 4057) ^ scribeH((by + 4057 + 0x9e3779b9) >>> 0)) >>> 0) % 100 < 34; }
function scribeGo(r, cc) {
  for (let k = 0; k < 24; k++) { const dx = Math.floor(r() * 3) - 1, dy = Math.floor(r() * 3) - 1, x = cc[0] + dx, y = cc[1] + dy;
    if ((dx || dy) && Math.abs(x) <= 9 && Math.abs(y) <= 7 && !scribeBig(x, y)) return [x, y]; }
  return [0, 0];
}
