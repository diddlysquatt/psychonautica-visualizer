function chromaRng(seed) { let s = Math.floor(seed * 2147483646) + 1; const r = () => (s = (s * 16807) % 2147483647) / 2147483647; for (let i = 0; i < 6; i++) r(); return r; }
function chromaForm(r, prev) {
  const f = { lay: Math.floor(r() * 4), tile: Math.floor(r() * 6), tileH: 0, orn: Math.floor(r() * 4), rim: Math.floor(r() * 3), gem: Math.floor(r() * 3), pal: Math.floor(r() * 14), palB: 0,
    spiral: Math.floor(r() * 3), band: Math.floor(r() * 4), arm: Math.floor(r() * 4), nw: r() < 0.3 ? 1 : 0, dens: 3.1 + r() * .7, ang: r() * 6.28, al: r() * 6.28 };
  if (prev && f.pal === prev.pal) f.pal = (f.pal + 1 + Math.floor(r() * 12)) % 14;
  if (prev && f.lay === prev.lay) f.lay = (f.lay + 1 + Math.floor(r() * 3)) % 4;
  f.palB = (f.pal + 1 + Math.floor(r() * 12)) % 14;
  { const hp = [5, 4, 1, 5, 4].filter(k => k !== f.tile); f.tileH = hp[Math.floor(r() * hp.length)]; }   // the heroes are pointed plumes of another outline
  return f;
}
// one float holds 23 bits (exact in float32); the second palette and the hero outline ride with the density
function chromaPack(f, o, i) {
  o[i] = f.lay + 8 * f.tile + 64 * f.orn + 256 * f.rim + 1024 * f.gem + 4096 * f.pal + 65536 * f.spiral + 262144 * f.band + 1048576 * f.arm + 4194304 * f.nw;
  o[i + 1] = f.dens + 16 * f.palB + 256 * f.tileH; o[i + 2] = f.ang; o[i + 3] = f.al;
}
function chromaSpr(o, k, tgt, w, dt) {
  const x0 = o[k] - tgt, v0 = o[k + 'v'], e = Math.exp(-w * dt), a = v0 + w * x0;
  o[k] = tgt + (x0 + a * dt) * e; o[k + 'v'] = (v0 - w * a * dt) * e;
}
