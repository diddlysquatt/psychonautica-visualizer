const knottLin = knottPals.map((P) => P.map((h) => [0, 2, 4].map((i) => Math.pow(parseInt(h.substr(i, 2), 16) / 255, 2.2))));
// mean chroma direction of each palette (an angle about the grey axis), used to pick hue-contrasting drop palettes
const knottHueOf = knottLin.map((P) => {
  let x = 0, y = 0;
  for (let k = 0; k < 5; k++) { const [r, g, b] = P[k].map((v) => Math.pow(v, 1 / 2.2)); x += r - 0.5 * (g + b); y += 0.866 * (g - b); }
  return Math.atan2(y, x);
});
function knottContrastPal(cur) {
  // two random candidates, keep the one whose hue character is furthest from the current palette
  let best = -1, bd = -1;
  for (let i = 0; i < 2; i++) {
    const k = (cur + 1 + Math.floor(rand() * 5)) % 6, d = Math.abs(Math.atan2(Math.sin(knottHueOf[k] - knottHueOf[cur]), Math.cos(knottHueOf[k] - knottHueOf[cur])));
    if (d > bd) { bd = d; best = k; }
  }
  return best;
}
function knottChromaMix(a, b, t) {
  const m = a.map((x, i) => x + (b[i] - x) * t), L = (v) => (v[0] + v[1] + v[2]) / 3, la = L(a), lb = L(b), lm = L(m);
  const ch = (v, l) => Math.hypot(v[0] - l, v[1] - l, v[2] - l), cm = ch(m, lm), ct = ch(a, la) + (ch(b, lb) - ch(a, la)) * t;
  const k = Math.min(ct / Math.max(cm, 1e-3), 3);
  return m.map((x) => Math.max(lm + (x - lm) * k, 0));
}
function knottHueRot(c, a) {
  // rotation about the grey axis
  const k = 0.57735, ca = Math.cos(a), sa = Math.sin(a), d = k * (c[0] + c[1] + c[2]) * (1 - ca);
  const cr = [k * (c[2] - c[1]), k * (c[0] - c[2]), k * (c[1] - c[0])];
  return [0, 1, 2].map((i) => Math.max(c[i] * ca + cr[i] * sa + k * d, 0));
}
// KNOTT: state per visit. fam: 0 square thirds (quadtree), 1 triangle thirds (quadtree), 2 hex tubes.
function knottInit(s) {
  const fam = Math.floor(s[0] * 3) % 3;
  const pal = Math.floor(s[1] * 6) % 6;
  // a visit opens on the plain neon tube look (the shader picks the band look from the phrase epoch, as kSty); later
  // phrases and drops bring the Celtic ribbon, rope and chain looks
  let ep0 = Math.floor(s[0] * 50);
  for (let i = 0; i < 8 && ((ep0 * 0.618034 + s[2] * 3.7) % 1) >= 0.38; i++) ep0++;
  return {
    fam, famPrev: fam, pal, palB: pal, palMix: 0, map: s[2] < 0.5 ? 0 : 1,
    sweep: (s[3] * 7.31) % 1, ring: 0.1 + 0.25 * ((s[2] * 5.7) % 1), pin: 0.25 + 0.3 * ((s[3] * 3.3) % 1),
    hue: s[1], panA: s[3] * 6.283, pan: [s[0] * 200 - 100, s[2] * 200 - 100], tiles: 3.8 + 1.3 * ((s[2] * 3.1) % 1),
    tz: 1, tzT: 1, tzV: 0, c: 0, cT: 0, lb: null, flow: 0, kw: 0, bass: 0, hat: 0, build: 0, mid: 0,
    bands: new Array(8).fill(0), bmax: new Array(8).fill(0.25),
    lens: 0, lensT: 0, lensV: 0, lensEnd: -1, kG: 0, rate: 0, spd: 0.1,
    mS: 0, mT: s[3] < 0.5 ? 1 : 0, cM: 0, cMT: 0, mFl: 0, D: s[2] < 0.6 ? 1.25 : 0.95, Dn: 0, sat: 0, satT: 1, ph: 0, wipe: 1, ep: ep0, epPrev: 0, drops: 0, lastBar: -1, ct: s[1] * 5
  };
}
function knottBands(c, dt) {
  // eight log-spaced spectrum bands, each auto-ranged against its own slow peak; the split field follows each band's
  // level RELATIVE to the others (so the loud part of the spectrum splits its region), smoothed over ~half a second
  const n = new Array(8);
  let mean = 0;
  for (let b = 0; b < 8; b++) {
    const i0 = Math.floor(b * 240 / 8), i1 = Math.floor((b + 1) * 240 / 8);
    let m = 0; for (let i = i0; i < i1; i++) m += specBytes[i]; m /= (i1 - i0) * 255;
    c.bmax[b] = Math.max(m, c.bmax[b] * Math.exp(-dt * 0.1), 0.05);
    n[b] = m / c.bmax[b]; mean += n[b] / 8;
  }
  for (let b = 0; b < 8; b++) {
    const v = clamp(0.45 + 1.3 * (n[b] - mean) + 0.4 * (mean - 0.55), 0, 1);
    c.bands[b] += (v - c.bands[b]) * (1 - Math.exp(-dt * (v > c.bands[b] ? 1.3 : 0.6) * (1.4 - 0.8 * clamp(Number(S.motionSmooth) || 0, 0, 1))));
  }
}
function knottDrop(c) {
  // odd drops switch the tiling family behind a radial wipe, even drops re-space the medallion lattice (it closes and
  // ripples open again in a new spacing) over the re-routing giant knot
  c.drops++;
  if (c.drops % 2 === 1) { c.famPrev = c.fam; c.epPrev = c.ep; c.fam = (c.fam + 1 + Math.floor(rand() * 2)) % 3; c.ep++; c.wipe = 0; }
  else { c.famPrev = c.fam; c.epPrev = c.ep; c.ep++; c.wipe = 0; c.Dn = [1.25, 0.95, 1.6, 1.1].filter((d) => d !== c.D)[Math.floor(rand() * 3)]; c.sat = Math.min(c.sat, 0.02); }
  // (every drop wipes in a new band look: neon, Celtic ribbon, rope braid or chain)
  // the drop lands on big bold tiles in a hue-contrasting palette
  c.tzT = 1; c.vista = 0;
  // now and then the drop lands with the focal lens opening off-centre for four bars
  c.lensT = 0;
  // the giant knot re-routes on every drop (all macro tiles turn in one sweep) and shows itself
  c.cMT += 1; c.mT = 1; c.satT = 1;
  c.palB = knottContrastPal(c.pal); c.palMix = 0.001;
}
function knottFrame(V, F, dt) {
  const c = V.c, M = 8;
  knottBands(c, dt);
  const beatDur = 60 / Math.max(60, F.bpm || 120);
  // flips: each beat starts one sweep (one group of the cycle turns), builds add more, snares add cascades
  const b = Math.floor(V.trav);
  if (c.lb === null) c.lb = b;
  if (b > c.lb) {
    const n = Math.min(b - c.lb, 2) * (F.breakdown > 0.6 ? (b % 2) : 1 + (F.build > 0.4 ? 1 : 0) + (F.build > 0.75 ? 1 : 0));
    c.cT += n / M; c.lb = b;
  }
  if (F.onHit) { c.cT += 2 / M; c.sn = ((c.sn || 0) + 1) % 256; }
  if (c.cT - c.c > 4 / M) c.cT = c.c + 4 / M;
  // the sweep speed itself is smoothed, so a snare cascade speeds the turning tiles up without a velocity step;
  // Motion smoothness (0 snappy .. 1 very smooth) sets how fast it adapts
  const ms = clamp(Number(S.motionSmooth) || 0, 0, 1);
  const rateT = Math.max((1 / M) / (0.75 * beatDur), (c.cT - c.c) * 2.5);
  c.rate += (rateT - c.rate) * (1 - Math.exp(-dt * (14 - 10 * ms)));
  c.c = Math.min(c.cT, c.c + Math.max(c.rate, (1 / M) / (1.5 * beatDur)) * dt * S.speed);
  if (c.c > 4096) { c.c -= 4096; c.cT -= 4096; }
  // envelopes: kick pulses band thickness and surges the flow; bass breathes the zoom; hats sparkle
  c.kw += (F.kick - c.kw) * (1 - Math.exp(-dt * (F.kick > c.kw ? 30 : 7)));
  // geometry kick (tube width): attack >= ~80 ms, release >= ~250 ms, slower with Motion smoothness
  c.kG += (c.kw - c.kG) * (1 - Math.exp(-dt * (c.kw > c.kG ? 12 - 6 * ms : 4 - 2 * ms)));
  c.bass += (F.bass - c.bass) * (1 - Math.exp(-dt * 1.5));
  c.hat += (F.hat - c.hat) * (1 - Math.exp(-dt * (F.hat > c.hat ? 25 : 8)));
  c.build += (F.build - c.build) * (1 - Math.exp(-dt * 2));
  c.mid += (F.mid - c.mid) * (1 - Math.exp(-dt * 3));
  c.flow = (c.flow + dt * S.speed * (1 - 0.5 * clamp(F.breakdown, 0, 1)) * (0.3 + 0.35 * F.level + 2.2 * c.kw + 0.6 * F.drop + 1.1 * c.build)) % 1;
  // tile density: a critically damped spring (no velocity jump) toward the phrase target
  const kz = 5 - 2.5 * ms;
  c.tzV += (kz * kz * (c.tzT - c.tz) - 2 * kz * c.tzV) * Math.min(dt, 0.05);
  c.tz += c.tzV * Math.min(dt, 0.05);
  // lens radius: a slightly underdamped spring, so it opens with a small overshoot (clamped for packing)
  const kl = 4;
  c.lensV += (kl * kl * (c.lensT - c.lens) - 2 * kl * c.lensV) * Math.min(dt, 0.05);
  c.lens += c.lensV * Math.min(dt, 0.05);
  c.ct += dt * S.speed * (0.04 + 0.08 * c.mid);
  // drops: odd drops switch the tiling family behind a radial wipe, even drops re-space the medallions
  if (F.onDrop || c.forceDrop) { c.forceDrop = 0; knottDrop(c); }
  // phrases: every 8 bars a new set of tile types wipes in, every 16 a new palette fades in
  if ((F.onBar || F.onSceneBar) && (F.sceneBarIndex ?? F.barIndex) !== c.lastBar) {
    c.lastBar = (F.sceneBarIndex ?? F.barIndex);
    if ((F.sceneBarIndex ?? F.barIndex) % 8 === 0 && c.wipe >= 1) {
      c.famPrev = c.fam; c.epPrev = c.ep; c.ep++; c.wipe = 0;
      // some phrases zoom out to a dense field of small knots (density contrast), the next one returns
      c.tzT = c.tzT > 1 ? 1 : (rand() < 0.6 ? 1.8 : 1);
      // the focal lens opens on most phrases and closes on some (graphic pause in the composition)
      // (a rare focal moment now: a small lens that opens off-centre on about one phrase in five, for four bars)
      if (c.lensT < 0.5 && rand() < 0.08) { c.lensT = 1; c.lensEnd = (F.sceneBarIndex ?? F.barIndex) + 4; }
      // the giant knot shows itself on some phrases at the default framing (always when zoomed out)
      c.mT = rand() < 0.7 ? 1 : 0;
      // the medallion lattice closes, takes a new spacing, and ripples open again
      if (rand() < 0.4) { c.Dn = [1.25, 0.95, 1.6, 1.1][Math.floor(rand() * 4)]; c.satT = 0; }
      // rare surprise: the whole giant knot re-routes in one long sweep
      if (rand() < 0.15) c.cMT += 1;
      // rare surprise (outside builds): a vista phrase, the realm pulls itself far back so the giant knot fills the
      // frame with hundreds of small knots inside it, the medallion lattice opens; the next phrase returns
      if (c.vista) { c.vista = 0; c.tzT = 1; }
      else if (F.build < 0.3 && rand() < 0.12) { c.vista = 1; c.tzT = 2.6; c.mT = 1; c.satT = 1; }
      // rarer still: a jewel phrase, the medallion lattice closes and ripples open again packed tight
      // rarer still: the medallion lattice (zoomed out) closes and ripples open again packed tight
      else if (rand() < 0.06) { c.Dn = 0.95; c.satT = 0; }
    }
    // every 4 bars one group of giant tiles turns (outside breakdowns)
    if ((F.sceneBarIndex ?? F.barIndex) % 4 === 2 && F.breakdown < 0.6) c.cMT += 0.25;
    if (c.lensEnd === -2) c.lensEnd = (F.sceneBarIndex ?? F.barIndex) + 4;
    if (c.lensT > 0.5 && c.lensEnd >= 0 && (F.sceneBarIndex ?? F.barIndex) >= c.lensEnd) { c.lensT = 0; c.lensEnd = -1; }
    if ((F.sceneBarIndex ?? F.barIndex) % 16 === 8 && c.palMix === 0) { c.palB = knottContrastPal(c.pal); c.palMix = 0.001; }
  }
  if (c.wipe < 1) c.wipe = Math.min(1, c.wipe + dt / (2 * beatDur));
  if (c.palMix > 0) { c.palMix += dt / (4 * beatDur); if (c.palMix >= 1) { c.pal = c.palB; c.palMix = 0; } }
  // giant knot: presence spring, turn counter (one group of giant tiles turns over about 1.2 beats)
  c.mS += ((F.breakdown > 0.6 ? 1 : c.mT) - c.mS) * (1 - Math.exp(-dt * 1.2));
  if (c.cMT - c.cM > 2) c.cM = c.cMT - 2;
  c.cM = Math.min(c.cMT, c.cM + Math.max(0.125 / beatDur, (c.cMT - c.cM) * 0.4) * dt * S.speed);
  if (c.cM > 1024) { c.cM -= 1024; c.cMT -= 1024; }
  // medallion lattice: builds close the satellites (tension), they ripple open again on the drop; a pending new
  // spacing is taken while they are closed
  const satT = c.build > 0.5 ? 0 : c.satT;
  c.sat += (satT - c.sat) * (1 - Math.exp(-dt * (satT > c.sat ? 0.9 : 2.5)));
  if (c.Dn && c.sat < 0.03) { c.D = c.Dn; c.Dn = 0; c.satT = 1; }
  // camera: slow drift along a wandering heading, a gentle sway, bass breathing in the zoom
  c.panA += dt * 0.03 * Math.sin(V.mt * 0.02);
  c.spd += (0.1 + 0.18 * F.level + 0.25 * F.drop - c.spd) * (1 - Math.exp(-dt * 1.5));
  const sp = dt * S.speed * c.spd;
  c.pan[0] = (c.pan[0] + Math.cos(c.panA) * sp) % 2048; c.pan[1] = (c.pan[1] + Math.sin(c.panA) * sp) % 2048;
  // builds pull back to many smaller, thinner, hotter knots (tension); the drop springs back to big tiles
  // zoomed out, the phrase/build densities ease off so the knots stay legible (the zoom itself shows more of them)
  const z = PTR.zoom * (V.kz ?? 1), zd = clamp((z - 0.3) / 0.6, 0, 1);
  const scale = c.tiles * (1 + (c.tz * (1 + 0.5 * c.build) - 1) * zd) / (1 + 0.07 * c.bass * S.dose);
  V.p1 = [scale, c.pan[0] + PTR.x * 0.3 * PTR.inf, c.pan[1] + PTR.y * 0.3 * PTR.inf, c.c];
  V.p2 = [c.flow, c.fam + 4 * c.ep + 0.9 * clamp(c.lens, 0, 1), c.famPrev + 4 * c.epPrev, c.wipe];
  const Bd = c.bands, pk = (a, b) => Math.floor(clamp(a, 0, 1) * 999) + clamp(b, 0, 0.999);
  // per-band light: hats = high/air envelopes + their onsets (beads), bassline = sub/bass envelopes + onsets (the giant
  // knot's inlay lines)
  const BL = BANDS.lv, BO = BANDS.on;
  // (hat onsets come every sixteenth: a short-release envelope keeps them as a steady glitter instead of spikes)
  c.hb = Math.max(Math.max(BO[6], BO[7]), (c.hb || 0) * Math.exp(-dt / 0.16));
  const hat = clamp(S.dose * (0.35 * BL[6] + 0.35 * BL[7] + 0.7 * c.hb + 0.3 * c.hat), 0, 1.99);
  V.p3 = [Math.floor(clamp(c.kG * S.dose, 0, 1) * 999) + clamp(c.kw * S.dose, 0, 0.999), hat * 0.5, (c.sn || 0) + clamp(c.build, 0, 0.999), 1 + 1.4 * BL[1] + 0.8 * BL[0] + 2.4 * Math.max(BO[0], BO[1])];
  V.p4 = [pk(Bd[0], Bd[1]), pk(Bd[2], Bd[3]), pk(Bd[4], Bd[5]), pk(Bd[6], Bd[7])];
  // the satellite medallions are jewels of the zoomed-out tapestry only; at the default framing the field stays pure
  // knotwork (no stray little circles)
  V.p5 = [Math.max(c.mS, clamp((0.85 - z) / 0.35, 0, 1)), c.cM, c.D, c.sat * clamp((0.45 - z) / 0.25, 0, 1)];
  // palette: five band colours + background, crossfaded with chroma kept, nudged by the global hue drift
  const t = c.palMix > 0 ? c.palMix * c.palMix * (3 - 2 * c.palMix) : 0;
  const A = knottLin[c.pal], B = knottLin[c.palB], hr = Math.sin(((D.hue + (F.cent - 0.45) * 0.35) % 1000) * 6.2832) * 0.35;
  const m1 = V.m1 instanceof Float32Array && V.m1.length === 9 && V.m1 !== V.m2 ? V.m1 : (V.m1 = new Float32Array(9));
  const m2 = V.m2 instanceof Float32Array && V.m2.length === 9 && V.m2 !== V.m1 ? V.m2 : (V.m2 = new Float32Array(9));
  for (let k = 0; k < 6; k++) {
    let col = t > 0 ? (k < 5 ? knottChromaMix(A[k], B[k], t) : A[k].map((x, j) => x + (B[k][j] - x) * t)) : A[k];
    col = knottHueRot(col, hr);
    if (k < 5) {
      // lift dark palette entries (deep violets, blues) so no variant reads dim
      const Y = 0.2126 * col[0] + 0.7152 * col[1] + 0.0722 * col[2];
      if (Y < 0.24) { const g = Math.min(1.9, Math.pow(0.24 / Math.max(Y, 0.01), 0.7)); col = col.map((x) => x * g); }
    }
    const M = k < 3 ? m1 : m2, o = (k % 3) * 3;
    M[o] = col[0]; M[o + 1] = col[1]; M[o + 2] = col[2];
  }
}
