/* ====================== ENGINE v22: MUSIC STRUCTURE CUES ======================
   What the song is doing on the scale of bars and sections, for any kind of music (see the "ENGINE v22" part of the realm
   contract for what scenes get, and work/engine22/NOTES-V22.md for how each cue was measured).
   CUE.tick() runs inside AU.fastTick() at about 100 Hz on the same 1024-point spectrum the onset detectors read, so the
   cues do not depend on the frame rate and are identical in live playback, mic / tab capture and the offline renderer.
   CUE.frame() runs once per analysed frame and publishes continuous values into FA (they reach F through the same latency
   queue as every other feature). Events (section, impact, downbeat, phrase, note) carry their own time and wait in
   CUE_EVENTS until that moment is audible, like drops do: an event found a moment late still lands on the beat, and one
   that belongs to the next beat is simply scheduled ahead. The cue engine keeps its OWN tempo and beat clock (the old
   F.bpm / F.beat / F.onBar are untouched and still what they were); of the old features it only reads FA.build.
   Audio sensitivity does not touch structure: a chorus is a chorus at any dial setting. No allocation per tick or frame
   (events allocate one small object each). */
const CUE_EVENTS = [];
function cuePush(e) { let i = CUE_EVENTS.length; CUE_EVENTS.push(e); while (i > 0 && CUE_EVENTS[i - 1].t > e.t) { CUE_EVENTS[i] = CUE_EVENTS[i - 1]; i--; } CUE_EVENTS[i] = e; }
// what the visuals have been told so far (audible time): counters and the times decaying envelopes are measured from
const CUE_VIS = { section: 0, secT0: -1e9, impT: -1e9, impS: 0, noteT: -1e9, noteS: 0, notePos: 0.5, dbT: -1e9, phrT: -1e9 };
const CUE_F = 19, CUE_HN = 640, CUE_TN = 320, CUE_HB = 128, CUE_NV = 13, CUE_ON = 1600, CUE_LAG = 484;
const CUE = {
  sr: 0, bins: 0, hiBin: 0, binBand: null, binW: null, binOct: null, tb0: 0, tb1: 0, chromaMap: null, chromaN: 0, chromaSr: 0,
  bandP: new Float32Array(9), bandV: new Float32Array(9), bandPrev: new Float32Array(9), pk: null, pkPrev: null,
  p150: 0, p300: 0, pAR: 0, p2: 0, p3: 0, p8: 0, lowP: 0, low1: 0, gP: new Float32Array(3), gJ: new Float32Array(3), gPk: new Float32Array(3), gPrev: new Float32Array(3), lowRef: -200, ref: -30, quietT: 9, soundT: 0, everSound: false, now: 0,
  // tick ring (about 3 s): time, instant level, 150 ms level, low-band 150 ms level
  tI: 0, tN: 0, tT: new Float64Array(CUE_TN), tL: new Float32Array(CUE_TN), tB: new Float32Array(CUE_TN), tLo: new Float32Array(CUE_TN), tH: new Float32Array(CUE_TN), tO: new Float32Array(CUE_TN), tG: new Float32Array(CUE_TN * 3),
  // hop ring (20 Hz, 32 s) of CUE_F features: 0-8 band level relative to the whole (spectral shape, dB + 45), 9-11 low / mid /
  // high onset flux, 12 level above the floor, 13 peak 150 ms level (dB), 14 brightness (octaves), 15 lowest high-band level, 16-18 peak 150 ms level of the low / mid / high third of the spectrum
  hAcc: 0, hCnt: 0, hI: 0, hN: 0, hop: new Float32Array(CUE_HN * CUE_F), acc: new Float32Array(CUE_F), hOn: new Float32Array(CUE_HN), onAcc: 0, hopN: 0,
  sub: new Float32Array(11 * CUE_NV), sA: new Float32Array(CUE_NV), sB: new Float32Array(CUE_NV), sD: new Float32Array(CUE_NV), srt: new Float32Array(16),
  nv: 0, nv0: 0, secCount: 0, secT: -1e9, secT0: -1e9, secEval: 0, secPend: 0, char: new Float32Array(6), charT: 0, _r2: 0,
  // impact
  impState: 0, impT0: 0, impPrevMax: 0, impPrevLow: 0, impPeak: 0, impLowPeak: 0, impGap: 0, impLast: -9, impLastS: 0, impBase: 0, fallT: 0, gapSharp: false, gapCut: false, gapT: 0, gapRef: -200, gapDur: 0, gapEnd: -9,
  // tension
  ten: 0, tenHold: 0, tenKill: 0, thinT: 0, riserPk: 0, pulseHold: 0, buildOn: false, tenParts: new Float32Array(4),
  // swell / phrase without a beat
  sw: new Float32Array(40), swI: 0, swN: 0, swAcc: 0, swPrev: 0, swDir: 0, phUp: true, phPeak: -200, phMin: 0, phT: -1e9, phLen: 10, phEnv: 0,
  // own tempo and beat clock: 100 Hz onset envelope (16 s), its autocorrelation, beat period T (in 10 ms), beat clock pc
  oe: new Float32Array(CUE_ON), ow: new Float32Array(CUE_ON), wMax: 0, os: new Float32Array(CUE_ON), sMax: 0, oxs: new Float32Array(CUE_ON), ox: new Float32Array(CUE_ON), oxw: new Float32Array(CUE_ON), AC: new Float32Array(CUE_LAG + 2), oI: 0, oN: 0, oAcc: 0, oMax: 0,
  T: 0, Tcand: 0, Tn: 0, tConf: 0, pc: 0, phBad: 0, triAC: false, lockE: 0.5, stableT: 0, beatEv: 0, fly: 0,
  // beat grid: half-beat ring of low / mid / high accents, peak level, votes, and 12 chroma bins each
  hbCur: -1, hbL: new Float32Array(CUE_HB), hbM: new Float32Array(CUE_HB), hbH: new Float32Array(CUE_HB), hbS: new Float32Array(CUE_HB), hbP: new Float32Array(CUE_HB), hbV: new Float32Array(CUE_HB), hbC: new Float32Array(CUE_HB * 12), hbN: 0,
  aL: 0, aM: 0, aH: 0, aS: 0, aP: 0, aC: new Float32Array(12), res: new Float32Array(16 * 6), sc: new Float32Array(16),
  mul: 1, mulCand: 1, mulN: 0, triple: false, tripN: 0, barHB: 8, phi: 0, phiCand: 0, phiN: 0, downConf: 0,
  Rx4: 0, Ry4: 0, Rx3: 0, Ry3: 0, Rn: 0, beatConf: 0, phrBar0: 0, phrAnchor: -1, lastDbT: -9,
  noteD: null, sustain: 0, bright: 0.5, dropT: -9,
  reset() {
    // a new track or render: everything except the section counter (scenes compare it with the last value they saw)
    for (const k of ['p150', 'p300', 'pAR', 'p2', 'p3', 'p8', 'lowP', 'low1', 'tI', 'tN', 'hAcc', 'hCnt', 'hI', 'hN', 'onAcc', 'hopN', 'nv', 'nv0', 'secEval', 'secPend', 'charT', 'impState', 'impGap', 'impLastS', 'gapT', 'gapDur', 'ten', 'tenHold', 'tenKill', 'thinT', 'riserPk', 'pulseHold', 'impBase', 'fallT',
      'swI', 'swN', 'swAcc', 'swPrev', 'swDir', 'phEnv', 'oI', 'oN', 'oAcc', 'oMax', 'T', 'Tcand', 'Tn', 'tConf', 'pc', 'phBad', 'stableT', 'beatEv', 'fly', 'hbN', 'aL', 'aM', 'aH', 'aP', 'mulN', 'tripN', 'phi', 'phiCand', 'phiN', 'downConf', 'Rx4', 'Ry4', 'Rx3', 'Ry3', 'Rn', 'beatConf', 'phrBar0', 'sustain', 'now', 'soundT']) this[k] = 0;
    this.lowRef = this.gapRef = this.phPeak = -200; this.ref = -30; this.quietT = 9; this.everSound = false; this.secT = this.secT0 = this.phT = -1e9; this.impLast = this.gapEnd = this.lastDbT = this.dropT = -9;
    this.hbCur = -1; this.lockE = 0.5; this.mul = this.mulCand = 1; this.triple = this.triAC = false; this.barHB = 8; this.phUp = true; this.phLen = 10; this.bright = 0.5; this.phrAnchor = -1;
    this.bandPrev.fill(0); this.gP.fill(0); this.acc.fill(0); this.hop.fill(0); this.hOn.fill(0); this.char.fill(0); this.sw.fill(0); this.oe.fill(0); this.ow.fill(0); this.wMax = 0; this.os.fill(0); this.sMax = 0; this.hbL.fill(0); this.hbM.fill(0); this.hbH.fill(0); this.hbS.fill(0); this.aS = 0; this.hbP.fill(0); this.hbV.fill(0); this.hbC.fill(0); this.aC.fill(0); this.tenParts.fill(0);
    if (this.pkPrev) this.pkPrev.fill(0);
    this.noteD = new Onset(90, 0.09); CUE_EVENTS.length = 0;
    Object.assign(CUE_VIS, { secT0: -1e9, impT: -1e9, impS: 0, noteT: -1e9, noteS: 0, notePos: 0.5, dbT: -1e9, phrT: -1e9 });
  },
  setup(sr, fftSize, n) {
    const hz = sr / fftSize, E = [40, 80, 160, 320, 640, 1250, 2500, 5000, 10000, 16000];
    this.sr = sr; this.bins = n; this.hiBin = Math.min(n - 4, Math.floor(16000 / hz));
    this.binBand = new Uint8Array(n); this.binW = new Float32Array(n); this.binOct = new Float32Array(n); this.pk = new Float32Array(n); this.pkPrev = new Float32Array(n);
    for (let i = 1; i < n; i++) {
      const f = i * hz; let b = 0; while (b < 8 && f >= E[b + 1]) b++;
      this.binBand[i] = b; this.binOct[i] = Math.log2(Math.max(f, 30) / 30);
      // loudness weighting: the deep sub counts less, the presence range a little more (a rough K curve)
      this.binW[i] = (f * f / (f * f + 70 * 70)) * (1 + 0.6 * f * f / (f * f + 1800 * 1800));
    }
    this.tb0 = Math.max(4, Math.ceil(240 / hz)); this.tb1 = Math.min(n - 4, Math.floor(4000 / hz));
  },
  // the 4096-point analyser, for pitch classes (chroma) between 65 Hz and 1 kHz
  setupChroma(sr, fftSize, n) {
    const hz = sr / fftSize; this.chromaMap = new Int8Array(n).fill(-1); this.chromaN = Math.min(n - 1, Math.floor(1000 / hz)); this.chromaSr = sr;
    for (let i = Math.ceil(65 / hz); i <= this.chromaN; i++) this.chromaMap[i] = ((Math.round(12 * Math.log2(i * hz / 16.3516)) % 12) + 12) % 12;
  },
  hv(k, back) { return this.hop[((this.hI - 1 - back + CUE_HN * 4) % CUE_HN) * CUE_F + k]; }, // feature k, `back` hops ago (0 = newest)
  // least-squares slope per second and r squared (in _r2) of feature k over the last n hops
  slope(k, n) {
    n = Math.min(n, this.hN); if (n < 8) { this._r2 = 0; return 0; }
    let sx = 0, sy = 0, sxx = 0, sxy = 0, syy = 0;
    for (let i = 0; i < n; i++) { const y = this.hv(k, n - 1 - i); sx += i; sy += y; sxx += i * i; sxy += i * y; syy += y * y; }
    const den = n * sxx - sx * sx, num = n * sxy - sx * sy, vy = n * syy - sy * sy;
    this._r2 = vy > 1e-6 ? clamp(num * num / (den * vy), 0, 1) : 0;
    return num / den * 20;
  },
  beatSec() { return this.T * 0.01; },
  tick(now, el, fF, fftSize, sr, onset) {
    if (this.sr !== sr || !this.binBand || this.bins !== fF.length) this.setup(sr, fftSize, fF.length);
    if (!this.noteD) this.noteD = new Onset(90, 0.09);
    this.now = now;
    const bb = this.binBand, bw = this.binW, n = this.hiBin, bp = this.bandP, dB = (p) => 4.3429448 * Math.log(p + 1e-12), ez = (tau) => 1 - Math.exp(-el / tau);
    bp.fill(0); let pw = 0, pu = 0;
    let g0 = 0, g1 = 0, g2 = 0;
    for (let i = 1; i <= n; i++) { const p = Math.exp(fF[i] * 0.2302585), b = bb[i], q = p * bw[i]; bp[b] += p; pw += q; pu += p; if (b < 3) g0 += q; else if (b < 6) g1 += q; else g2 += q; }
    const lowNow = bp[0] + bp[1];
    this.p150 += (pw - this.p150) * ez(0.12); this.p300 += (pw - this.p300) * ez(0.3);
    this.p2 += (pw - this.p2) * ez(2); this.p3 += (pw - this.p3) * ez(3); this.p8 += (pw - this.p8) * ez(8); this.pAR += (pw - this.pAR) * ez(pw > this.pAR ? 0.4 : 1.5);
    this.lowP += (lowNow - this.lowP) * ez(0.12); this.low1 += (lowNow - this.low1) * ez(1);
    { const k = ez(0.12), g = this.gP; g[0] += (g0 - g[0]) * k; g[1] += (g1 - g[1]) * k; g[2] += (g2 - g[2]) * k; }
    const L = dB(pw), Lu = dB(pu), L150 = dB(this.p150), L300 = dB(this.p300);
    const quiet = L300 < this.ref - 52 || L300 < -92;
    if (quiet) { this.quietT += el; this.soundT = 0; } else { this.soundT += el; if (this.soundT > 0.05) this.quietT = 0; }
    // loudness reference: the loudest the track has been (2 s scale), forgetting 3 dB a minute; starts at a typical quiet master
    if (!quiet) { this.ref = Math.max(dB(this.p2), this.ref - el * 0.05); this.lowRef = Math.max(dB(this.low1), this.lowRef - el * 0.4); }
    const floor = this.ref - 50, bv = this.bandV, pv = this.bandPrev, a = this.acc; let fl = 0, fm = 0, fh = 0, wl = 0, wm = 0, vmax = 0;
    for (let b = 0; b < 9; b++) { const v = clamp(dB(bp[b]) - floor, 0, 60); if (v > vmax) vmax = v; }
    for (let b = 0; b < 9; b++) {
      const bd = dB(bp[b]), v = clamp(bd - floor, 0, 60), d = v - pv[b] - 1.5; bv[b] = v; pv[b] = v;
      // wl / wm: the same rise weighted by how loud the band is beside the loudest (a ghost note is not a snare)
      if (d > 0) { const w = clamp((v - vmax + 24) / 24, 0, 1); if (b < 2) { fl += d * 0.1; wl += d * 0.1 * w * w; } else if (b < 7) { fm += d * 0.1; wm += d * 0.1 * w * w; } else fh += d * 0.1; }
      if (!quiet) a[b] += clamp(bd - Lu + 45, 0, 45); // spectral shape: this band against the whole, whatever the level
    }
    const hiLv = Math.max(bv[7], bv[8]);
    // brightness: centroid of the level above a per-bin floor, in octaves above 30 Hz; tonal peaks between 240 Hz and 4 kHz
    const bf = this.ref - 78, pk = this.pk, pp = this.pkPrev; let cs = 0, cw = 0, tfl = 0, tsum = 0, tbest = 0, tbin = 0;
    for (let i = 2; i <= n; i += 2) { const v = fF[i] - bf; if (v > 0) { cs += v * this.binOct[i]; cw += v; } }
    for (let i = this.tb0; i <= this.tb1; i++) {
      let p = 0;
      if (fF[i] > bf + 10 && fF[i] >= fF[i - 1] && fF[i] >= fF[i + 1]) p = clamp(fF[i] - 0.5 * (fF[i - 3] + fF[i + 3]) - 6, 0, 24);
      pk[i] = p;
      if (p > 0) { tsum += p; const d = p - Math.max(pp[i - 1], pp[i], pp[i + 1]); if (d > 0) { tfl += d; if (d > tbest) { tbest = d; tbin = i; } } }
    }
    for (let i = this.tb0; i <= this.tb1; i++) pp[i] = pk[i];
    if (!quiet) {
      const nt = this.noteD.push(tfl, now, 2.2, 5);
      if (nt >= 0) cuePush({ t: now - 0.012, type: 3, s: 0.5 + 0.5 * nt, pos: clamp(Math.log2(tbin * sr / fftSize / 240) / 4.06, 0, 1) });
    }
    // a held note or pad: tonal peaks present and not changing
    this.sustain += ((quiet ? 0 : clamp(tsum / 60, 0, 1) * clamp(1 - tfl / Math.max(4, tsum * 0.25), 0, 1)) - this.sustain) * ez(0.4);
    // ---- tick ring, impact
    const ti = this.tI; this.tT[ti] = now; this.tL[ti] = Math.max(L, floor); this.tB[ti] = Math.max(L150, floor); this.tLo[ti] = Math.max(dB(this.lowP), floor - 6); this.tH[ti] = hiLv; this.tO[ti] = onset;
    for (let g = 0; g < 3; g++) this.tG[ti * 3 + g] = Math.max(dB(this.gP[g]), floor - 6);
    this.tI = (ti + 1) % CUE_TN; if (this.tN < CUE_TN) this.tN++;
    this.impact(now, el, quiet, floor); this.riserCut(now, floor, quiet);
    // ---- onset envelope at an even 100 Hz for the tempo tracker
    const ov = quiet ? 0 : fl + 0.6 * fm + 0.2 * fh; if (ov > this.oMax) this.oMax = ov;
    const ow = quiet ? 0 : wl + 0.8 * wm; if (ow > this.wMax) this.wMax = ow;
    // (snare-like accents: a rise of the top third of the spectrum, 2.5 kHz up, on its 120 ms level; used only to tell the beat from the quarter-beat rival)
    const osv = quiet || this.tN < 2 ? 0 : Math.max(0, this.tG[ti * 3 + 2] - this.tG[((ti - 1 + CUE_TN) % CUE_TN) * 3 + 2] - 1); if (osv > this.sMax) this.sMax = osv;
    this.oAcc += el * 100;
    while (this.oAcc >= 1) { this.oe[this.oI] = this.oMax; this.ow[this.oI] = this.wMax; this.wMax = 0; this.os[this.oI] = this.sMax; this.sMax = 0; this.oI = (this.oI + 1) % CUE_ON; if (this.oN < CUE_ON) this.oN++; this.oAcc -= 1; this.oMax = 0; }
    // ---- own beat clock and the accents on its half-beats
    if (this.T > 0) {
      this.pc += el * 100 / this.T;
      const h = Math.floor(this.pc * 2 + 0.5);
      if (this.hbCur < 0 || h > this.hbCur + 16) this.hbCur = h;
      while (h > this.hbCur) this.halfBeat(now);
      // accents count only near the half-beat itself: a syncopated 16th (a kick on the "and" of 3 at half-time) is not
      // the next half-beat's accent
      const off = this.pc * 2 - h;
      if (off > -0.2 && off < 0.35) { this.aL += wl; this.aM += wm; this.aS += osv; }
      this.aH += fh; this.aP = Math.max(this.aP, L150 - floor);
      if (onset > 0) { // how well strong onsets sit on a 16th or a triplet grid of the clock: part of the honest beat confidence
        const a4 = 6.2831853 * 4 * this.pc, a3 = 6.2831853 * 3 * this.pc;
        this.Rx4 += Math.cos(a4) * onset; this.Ry4 += Math.sin(a4) * onset; this.Rx3 += Math.cos(a3) * onset; this.Ry3 += Math.sin(a3) * onset; this.Rn += onset;
      }
    }
    const rd = Math.exp(-el / 8); this.Rx4 *= rd; this.Ry4 *= rd; this.Rx3 *= rd; this.Ry3 *= rd; this.Rn *= rd;
    if (onset > 0) this.onAcc += 1;
    // ---- hop accumulation (20 Hz)
    a[9] += fl; a[10] += fm; a[11] += fh; a[12] += Math.max(L - floor, 0); a[13] = this.hCnt ? Math.max(a[13], L150) : L150; a[14] += cw > 0 ? cs / cw : 2 + this.bright * 6; a[15] = this.hCnt ? Math.min(a[15], hiLv) : hiLv;
    for (let g = 0; g < 3; g++) { const v = this.tG[ti * 3 + g]; a[16 + g] = this.hCnt ? Math.max(a[16 + g], v) : v; }
    this.hCnt++; this.hAcc += el;
    if (this.hAcc >= 0.05) {
      this.hAcc = Math.min(this.hAcc - 0.05, 0.05); const o = this.hI * CUE_F, c = this.hCnt;
      for (let k = 0; k < CUE_F; k++) this.hop[o + k] = k === 13 || k >= 15 || (k >= 9 && k <= 11) ? a[k] : a[k] / c;
      this.hOn[this.hI] = this.onAcc; this.onAcc = 0;
      this.hI = (this.hI + 1) % CUE_HN; if (this.hN < CUE_HN) this.hN++;
      a.fill(0); this.hCnt = 0;
      this.hopStep(now, quiet, floor);
    }
  },
  /* IMPACT: the 150 ms level sets a new high against the last 2.6 s (a dynamic jump, measured against how much the peaks
     of the last 8 s vary among themselves, so a solo instrument's louder note is not one), or the bass comes back, or
     the music returns after a gap. Decided 120 ms after the level first breaks out, timed at the steepest rise before
     that, graded by the size of the jump, how long ago it was last this loud, the bass, the gap and the tension released. */
  impact(now, el, quiet, floor) {
    const N = this.tN, I = this.tI, i1 = (I - 1 + CUE_TN) % CUE_TN, cur = this.tB[i1], curLo = this.tLo[i1], tG = this.tG, gPrev = this.gPrev, gPk = this.gPk;
    // a gap: the level sits 14 dB under what it was (2 s average, frozen while the gap lasts) for a quarter second or more.
    // Only a cut counts (the level fell those last 10 dB in under 0.6 s): a piano phrase dying away is not a gap
    const L2 = 4.3429448 * Math.log(this.p2 + 1e-12);
    if (this.gapT <= 0) { this.gapRef = Math.max(L2, floor); if (cur >= this.gapRef - 4) this.fallT = now; }
    if (cur < this.gapRef - 14 && this.gapRef > floor + 16) { if (this.gapT <= 0) this.gapSharp = now - this.fallT < 0.6; this.gapT += el; }
    else { if (this.gapT > 0.25) { this.gapDur = this.gapT; this.gapEnd = now; this.gapCut = this.gapSharp; } this.gapT = 0; }
    if (this.gapT > 12) this.gapT = 0; // a new quiet section, not a gap
    if (this.impState === 0) {
      if (quiet || N < 30 || now - this.impLast < 1.1) return;
      let pm = floor, pl = floor - 6; gPrev[0] = gPrev[1] = gPrev[2] = floor - 6;
      for (let j = 20; j < N; j++) {
        const i = (I - 1 - j + CUE_TN * 2) % CUE_TN; if (now - this.tT[i] > 2.6) break;
        if (this.tB[i] > pm) pm = this.tB[i]; if (this.tLo[i] > pl) pl = this.tLo[i];
        for (let g = 0; g < 3; g++) if (tG[i * 3 + g] > gPrev[g]) gPrev[g] = tG[i * 3 + g];
      }
      const gapBack = now - this.gapEnd < 0.3 && this.gapDur > 0.25 && this.gapCut && cur > this.gapRef - 6;
      const lowBack = curLo > pl + 9 && curLo > this.lowRef - 8 && curLo > floor + 18;
      let grp = false; for (let g = 0; g < 3; g++) if (tG[i1 * 3 + g] > gPrev[g] + 4 && tG[i1 * 3 + g] > floor + 20) grp = true;
      if (cur > pm + 2 || gapBack || lowBack || grp) {
        this.impState = 1; this.impT0 = now; this.impPrevMax = pm; this.impPrevLow = pl; this.impPeak = cur; this.impLowPeak = curLo; this.impGap = gapBack ? this.gapDur : 0;
        for (let g = 0; g < 3; g++) gPk[g] = tG[i1 * 3 + g];
        // the 150 ms level a tenth of a second before the break-out (an arrival leaps from there, a swell creeps)
        let b0 = cur; for (let j = 1; j < N; j++) { const i = (I - 1 - j + CUE_TN * 2) % CUE_TN; b0 = this.tB[i]; if (now - this.tT[i] >= 0.1) break; }
        this.impBase = b0;
      }
      return;
    }
    this.impPeak = Math.max(this.impPeak, cur); this.impLowPeak = Math.max(this.impLowPeak, curLo);
    for (let g = 0; g < 3; g++) gPk[g] = Math.max(gPk[g], tG[i1 * 3 + g]);
    if (now - this.impT0 < 0.12) return;
    this.impState = 0;
    const sat = (x) => clamp(x, 0, 1), J = this.impPeak - this.impPrevMax, lowJ = this.impLowPeak - this.impPrevLow, gap = this.impGap > 0 ? this.impGap : now - this.gapEnd < 0.45 && this.gapDur > 0.25 && this.gapCut && this.impPeak > this.gapRef - 6 ? this.gapDur : 0;
    // how much do the peaks of the last 8 s (half-second blocks) differ among themselves: overall, and in each third of the spectrum
    const sdOf = (k) => { let m = 0, v = 0, nb = 0; for (let b = 0; b < 16 && (b + 1) * 10 + 4 <= this.hN; b++) { let mx = -200; for (let j = 0; j < 10; j++) mx = Math.max(mx, this.hv(k, 4 + b * 10 + j)); mx = Math.max(mx, floor - 6); m += mx; v += mx * mx; nb++; } return nb > 3 ? Math.sqrt(Math.max(0, v / nb - (m / nb) * (m / nb))) : 3; };
    const thr = Math.max(3, 2.2 * Math.min(sdOf(13), 6));
    const lowOK = this.impLowPeak > this.lowRef - 8 && this.impLowPeak > floor + 18;
    const gTop = Math.max(gPk[0], gPk[1], gPk[2]), gJ = this.gJ; let xg = 0, ng = 0;
    for (let g = 0; g < 3; g++) { gJ[g] = gPk[g] > gTop - 12 ? (gPk[g] - gPrev[g]) / Math.max(4, 2.2 * Math.min(sdOf(16 + g), 6)) : 0; if (gJ[g] > xg) xg = gJ[g]; if (gJ[g] >= 1) ng++; }
    // a level jump counts when a third of the spectrum really leapt with it (a few dB of wobble in a loud bass line is not one)
    // (or two thirds leapt together, or one by far, while the loudest part held: horns and a crash coming in over an 808 that
    // fills the meter. v22 third pass)
    let g1 = 0, g2 = 0; for (let g = 0; g < 3; g++) { const v = gJ[g] >= 0.5 ? gJ[g] : 0; if (v > g1) { g2 = g1; g1 = v; } else if (v > g2) g2 = v; }
    const xG = (J > -3 || (J > -6 && g2 >= 0.6)) && this.beatConf > 0.4 ? Math.max(0.7 * (g1 + g2), 0.85 * g1) : 0; // (only over a groove: without a pulse a band swelling is not a bam)
    const xLow = lowOK ? lowJ / 9 : 0, x = Math.max(xg >= 1 ? J / thr : Math.min(J / thr, 0.99), xLow, xG), rise150 = this.impPeak - this.impBase;
    if (this.log) this.log('J ' + J.toFixed(1) + ' thr ' + thr.toFixed(1) + ' lowJ ' + lowJ.toFixed(1) + ' lowOK ' + lowOK + ' gap ' + gap.toFixed(2) + ' ten ' + this.ten.toFixed(2) + ' x ' + x.toFixed(2) + ' grp ' + Array.from(gJ).map((v) => v.toFixed(2)).join(' ') + ' gPk ' + Array.from(gPk).map((v) => (v - gTop).toFixed(0)).join(' ') + ' rise150 ' + rise150.toFixed(1) + ' soundT ' + this.soundT.toFixed(1));
    if (this.soundT < 3 && !(gap > 0)) return; // the first seconds of sound are a beginning (a section), not an arrival
    if (x < 1 && !(gap > 0)) return;
    // onset time: the steepest rise of the instant level in the 0.2 s before the break-out
    let best = 0, at = this.impT0;
    for (let j = 12; j < Math.min(N - 1, 36); j++) { const i = (I - 1 - j + CUE_TN * 2) % CUE_TN, i0 = (i - 1 + CUE_TN) % CUE_TN, d = this.tL[i] - this.tL[i0]; if (this.impT0 - this.tT[i] > 0.2) break; if (d > best) { best = d; at = this.tT[i]; } }
    if (this.log) this.log('  rise ' + best.toFixed(1));
    if (best < 3 && !(gap > 0)) return; // a swell, not an arrival
    // how long since it was last this loud (hop ring, up to 32 s)
    let since = 32;
    for (let j = 6; j < this.hN; j++) if (this.hv(13, j) >= this.impPeak - 1.5) { since = j * 0.05; break; }
    if (J < thr && lowOK) since = Math.max(since, Math.min(32, this.thinT * 2 + 2)); // a bass return: since when was the bass gone
    const s = clamp(0.3 + 0.22 * sat((x - 1) / 1.5) + 0.2 * sat((Math.log2(Math.max(since, 1)) - 1) / 3.5) + 0.13 * (lowOK ? sat(lowJ / 9) : 0) + (gap > 0 ? 0.15 + 0.2 * sat(gap / 1.5) : 0) + 0.2 * this.ten, 0, 1);
    if (this.log) this.log('  since ' + since.toFixed(1) + ' s ' + s.toFixed(2));
    this.raiseImpact(at - 0.012, s);
  },
  /* The end of a build: with tension up, a sustained wash in the top bands (the riser) is cut off between one tick and the
     next while the music goes on. That moment is an impact even though the level does not jump, and often falls (a drop
     after a build that kept the kick running). A cut into silence, or one with no kick or snare landing on it, is not one (a false drop: the tension holds instead). */
  riserCut(now, floor, quiet) {
    if (this.ten < 0.4 || this.riserPk < 0.3 || quiet || this.gapT > 0 || now - this.impLast < 1.1 || this.tN < 60) return;
    const I = this.tI, ix = (j) => (I - 1 - j + CUE_TN * 2) % CUE_TN;
    let a = 0, b = 0, bmin = 1e9, inst = -200, pm = floor;
    for (let j = 0; j < 3; j++) { a += this.tH[ix(j)]; inst = Math.max(inst, this.tL[ix(j)]); }
    for (let j = 8; j < 50; j++) { const v = this.tH[ix(j)]; b += v; if (v < bmin) bmin = v; if (this.tB[ix(j)] > pm) pm = this.tB[ix(j)]; }
    a /= 3; b /= 42;
    if (b - a < 8 || bmin < b - 5 || b < 16) return;
    if (this.log) this.log('riser cut: fell ' + (b - a).toFixed(1) + ' ten ' + this.ten.toFixed(2) + ' inst-pm ' + (inst - pm).toFixed(1));
    if (inst < pm - 12) return;
    let at = now, struck = 0, jc = 0; for (let j = 0; j < 8; j++) { if (this.tH[ix(j)] > b - 4) break; at = this.tT[ix(j)]; jc = j; }
    for (let j = 0; j <= jc + 2; j++) struck = Math.max(struck, this.tO[ix(j)]);
    if (struck < 0.7) return; // nothing struck where the riser stopped: it stopped into a pause (the tension holds)
    this.impState = 0; this.riserPk = 0;
    this.raiseImpact(at - 0.012, clamp(0.5 + 0.45 * this.ten, 0, 1));
  },
  raiseImpact(at, s) {
    if (Math.abs(at - this.dropT) < 0.45) s = clamp(Math.max(0.85, s + 0.2), 0, 1); // a drop the level detector also saw is the biggest thing there is
    // one arrival, one event: a drop and the level jump it makes are merged
    for (const e of CUE_EVENTS) if (e.type === 2 && Math.abs(e.t - at) < 0.4) { e.s = Math.max(e.s, s); this.impLastS = e.s; return; }
    if (Math.abs(at - this.impLast) < 0.4) { if (s > this.impLastS) { cuePush({ t: at, type: 2, s, up: true }); this.impLastS = s; this.impactSection(this.impLast, s); } return; }
    this.impLast = at; this.impLastS = s; cuePush({ t: at, type: 2, s });
    this.impactSection(at, s);
    if (s >= 0.4) { this.tenKill = 1.2; this.tenHold = 0; }
    if (this.T > 0 && this.hbCur >= 0) { const h = Math.floor((this.pc - Math.max(0, this.now - at) / this.beatSec()) * 2 + 0.5); this.hbV[((h % CUE_HB) + CUE_HB) % CUE_HB] += s; }
  },
  // a strong impact is the first moment of a new section: both cues land together
  impactSection(at, s) {
    if (s < 0.6 || at - this.secT0 < 2.5 || this.now - this.secT < 1) return;
    this.secT = this.now; this.secT0 = at; this.secCount++; this.charT = 0;
    cuePush({ t: at, type: 1, t0: at, n: this.secCount });
    if (this.T > 0 && this.hbCur >= 0) this.phrAnchor = Math.floor((this.pc - Math.max(0, this.now - at) / this.beatSec()) * 2 + 0.5);
  },
  // every 50 ms: tension, swell and phrase contours, tempo (every 0.5 s), sections (every 0.1 s)
  hopStep(now, quiet, floor) {
    const sat = (x) => clamp(x, 0, 1), dB = (p) => 4.3429448 * Math.log(p + 1e-12);
    this.hopN++;
    if (this.hopN % 10 === 0) this.tempoStep(quiet);
    // ---- tension
    let riser = 0, roll = 0, thin = 0, cres = 0;
    if (!quiet && this.hN > 40) {
      // a riser: the floor of the high band climbs steadily for 3 s while the whole spectrum brightens
      const s1 = this.slope(15, 60), r1 = this._r2, s2 = this.slope(14, 60), r2 = this._r2;
      riser = sat((s1 - 0.8) / 3) * sat((r1 - 0.3) / 0.4) * sat((this.hv(15, 0) - 6) / 8) * (0.4 + 0.6 * sat((s2 - 0.03) / 0.2) * sat((r2 - 0.2) / 0.4));
      // a roll: far more onsets in the last second than in the four before, and many
      let r1s = 0, r4 = 0; for (let j = 0; j < 20; j++) r1s += this.hOn[(this.hI - 1 - j + CUE_HN * 2) % CUE_HN]; for (let j = 20; j < 100 && j < this.hN; j++) r4 += this.hOn[(this.hI - 1 - j + CUE_HN * 2) % CUE_HN];
      r4 /= Math.max(1, (Math.min(100, this.hN) - 20) / 20);
      roll = sat((r1s - Math.max(r4 * 1.5, 6.5)) / 4);
      // thinning out: the bass is gone while the music goes on
      const th = this.lowRef > floor + 14 && dB(this.p300) > this.ref - 36 ? sat((this.lowRef - dB(this.low1) - 10) / 10) : 0;
      this.thinT = th > 0.5 ? this.thinT + 0.05 : Math.max(0, this.thinT - 0.2);
      thin = th * (0.2 + 0.3 * sat(this.thinT / 8));
      // a crescendo: the level climbs for 4 s
      const s3 = this.slope(12, 80); cres = sat((s3 - 1) / 2.5) * sat((this._r2 - 0.4) / 0.4);
    }
    const tp = this.tenParts; tp[0] = riser; tp[1] = roll; tp[2] = thin; tp[3] = cres;
    this.riserPk = Math.max(riser, this.riserPk - 0.05 / 1.2);
    // Tension belongs to music with a pulse: without one (ambient, solo piano) a noise swell or a crescendo is a swell, and
    // F.swell says so. A burst of onsets alone (a fill, a busier new section) is half a sign: it needs another beside it.
    this.pulseHold = Math.max(this.beatConf, this.pulseHold - 0.05 / 30);
    const gate = sat((this.pulseHold - 0.25) / 0.25), ri = riser * gate, cr = cres * gate, ro = roll * (0.5 + 0.5 * sat(Math.max(ri, thin, cr) / 0.3));
    // (the old F.build also reads a quieter passage of a waltz as a build: alone it counts for .4 at most)
    const fb = Math.min((FA.build || 0) * gate, Math.max(ri, ro, cr, thin) < 0.2 ? 0.4 : 1);
    let tgt = Math.max(1 - (1 - 0.8 * ri) * (1 - 0.6 * ro) * (1 - thin) * (1 - 0.4 * cr), fb);
    this.buildOn = Math.max(ri, ro, cr) > 0.15;
    if (ri < 0.3 && thin < 0.3 && fb < 0.45) tgt = Math.min(tgt, 0.45); // a roll or a crescendo alone is a hint, not a build
    if (this.tenKill > 0) { this.tenKill -= 0.05; tgt = 0; this.ten *= Math.exp(-0.05 / 0.12); }
    // a silence straight after a build is the held breath before the drop: keep the tension up to 4 s
    if (quiet || this.gapT > 0.1) { if (this.ten > 0.4 && this.tenHold < 4) { this.tenHold += 0.05; tgt = Math.max(tgt, this.ten); } } else this.tenHold = 0;
    this.ten += (tgt - this.ten) * (1 - Math.exp(-0.05 / (tgt > this.ten ? 0.6 : 1.5)));
    // ---- swell (3 s envelope against its own last 40 s) and phrases from the energy contour when there is no beat
    this.swAcc += 0.05;
    const L3 = Math.max(dB(this.p3), floor);
    if (this.swAcc >= 1) { this.swAcc -= 1; this.swDir = clamp((L3 - this.swPrev) / 1.2, -1, 1); this.swPrev = L3; this.sw[this.swI] = L3; this.swI = (this.swI + 1) % 40; if (this.swN < 40) this.swN++; }
    this.phEnv += (Math.max(dB(this.p300), floor) - this.phEnv) * (1 - Math.exp(-0.05 / 0.5));
    if (!quiet || this.phUp === false) {
      const e = this.phEnv;
      if (this.phUp) { if (e > this.phPeak) this.phPeak = e; if (e < this.phPeak - 5) { this.phUp = false; this.phMin = e; } }
      else { if (e < this.phMin) this.phMin = e; if (e > this.phMin + 3 && now - this.phT > 4) { this.phUp = true; this.phPeak = e; if (this.phT > -1e8) this.phLen = clamp(0.6 * this.phLen + 0.4 * (now - this.phT), 4, 40); this.phT = now - 0.25; if (this.beatConf < 0.4) cuePush({ t: now - 0.25, type: 5 }); } }
    }
    // ---- sections, ten times a second
    if ((this.secEval ^= 1) === 1) this.sections(now, quiet);
  },
  /* TEMPO: autocorrelation of 16 s of the onset envelope. A beat period T is believed when the envelope also repeats at
     2T and at the bar (4T, or 3T for triple time): that is what keeps 3:2 mistakes (a dotted pattern read as the beat) out.
     The phase is the comb of period T that collects the most onset energy; the clock glides to it. */
  tempoStep(quiet) {
    const N = this.oN; if (N < 500 || quiet) { this.tConf *= 0.9; return; }
    const x = this.ox, oe = this.oe, AC = this.AC; let mean = 0;
    for (let i = 0; i < N; i++) { x[i] = oe[(this.oI - N + i + CUE_ON * 2) % CUE_ON]; mean += x[i]; } mean /= N;
    let e0 = 0; for (let i = 0; i < N; i++) { const d = x[i] - mean; e0 += d * d; }
    if (e0 < 1e-6) { this.tConf *= 0.9; return; }
    e0 /= N; const maxLag = Math.min(CUE_LAG - 2, N - 300);
    for (let lag = 12; lag <= maxLag + 1; lag++) { let s = 0; for (let i = lag; i < N; i++) s += (x[i] - mean) * (x[i - lag] - mean); AC[lag] = s / ((N - lag) * e0); }
    const g = (l) => { if (l > maxLag || l < 12) return 0; const i = Math.floor(l), f = l - i; return AC[i] + (AC[i + 1] - AC[i]) * f; };
    const gm = (l) => Math.max(g(l - 1), g(l), g(l + 1));
    let best = -1e9, bT = 0, bRaw = 0, b3 = false;
    for (let T = 30; T <= 100; T += 0.5) {
      const a1 = gm(T), s4 = a1 + 0.8 * gm(2 * T) + gm(4 * T), s3 = a1 + gm(3 * T) + 0.6 * gm(6 * T), s = Math.max(s4, s3 * 0.97);
      const bpm = 6000 / T, sc = s * Math.exp(-0.5 * Math.pow(Math.log2(bpm / 118) / 1.2, 2)) + (this.T > 0 && Math.abs(T / this.T - 1) < 0.03 ? 0.1 : 0);
      if (sc > best) { best = sc; bT = T; bRaw = s; b3 = s3 * 0.97 > s4 + 0.1; }
    }
    // refine on the bar lag, where a small tempo error shows four times as large
    const mulB = b3 ? 3 : 4; let rb = -1e9, rT = bT;
    if (mulB * bT + 3 <= maxLag) { for (let t = mulB * bT - 3; t <= mulB * bT + 3; t += 0.25) { const v = g(t); if (v > rb) { rb = v; rT = t / mulB; } } }
    const conf = clamp((bRaw / 2.8 - 0.06) / 0.3, 0, 1);
    this.tConf += (conf - this.tConf) * 0.3; this.triAC = b3;
    if (conf > 0.15) {
      if (!(this.T > 0)) { this.T = rT; this.Tn = 0; this.stableT = 0; }
      else if (Math.abs(rT / this.T - 1) < 0.04) { this.T += (rT - this.T) * 0.3; this.Tn = 0; this.stableT += 0.5; }
      else if (Math.abs(rT / this.Tcand - 1) < 0.04) { if (++this.Tn >= 4) { const m2 = this.mul * rT / this.T; this.mul = this.mulCand = Math.abs(m2 - 2) < 0.1 ? 2 : Math.abs(m2 - 0.5) < 0.05 ? 0.5 : 1; this.mulN = 0; this.pc *= this.T / rT; this.T = rT; this.Tn = 0; this.stableT = 0; this.lockE = 0.5; this.hbCur = -1; this.hbN = 0; this.phiN = 0; this.Rn = 0; this.Rx4 = this.Ry4 = this.Rx3 = this.Ry3 = 0; } }
      else { this.Tcand = rT; this.Tn = 1; }
    }
    if (!(this.T > 0) || conf < 0.25) return; // (without evidence the clock free-wheels: a breakdown, a pause)
    // phase: where a comb of period T collects the most onset energy over the last 8 s (newer beats weigh more)
    const T = this.T, K = Math.min(Math.floor((N - T - 2) / T), Math.max(4, Math.round(800 / T))), P = Math.ceil(T), cs = this.sc2 || (this.sc2 = new Float32Array(128));
    // (on the level-weighted envelope: kick and snare decide where the beat is, not the off-beat hats and ghost notes)
    const xw = this.oxw, xs = this.oxs; for (let i = 0; i < N; i++) { const j = (this.oI - N + i + CUE_ON * 2) % CUE_ON; xw[i] = this.ow[j]; xs[i] = this.os[j]; }
    let bc = -1, bp = 0, tot = 0, b2 = -1, sTot = 0; const ss = this.sc4 || (this.sc4 = new Float32Array(128));
    for (let p = 0; p < P; p++) {
      let c = 0, c4 = 0; for (let k = 0; k < K; k++) { const i = N - 1 - p - Math.round(k * T), wk = 1 - 0.6 * k / K; c += (xw[i] + (i > 0 ? xw[i - 1] : 0) * 0.5 + (i + 1 < N ? xw[i + 1] : 0) * 0.5) * wk; c4 += Math.max(xs[i], i > 0 ? xs[i - 1] : 0, i + 1 < N ? xs[i + 1] : 0) * wk; }
      cs[p] = c; tot += c; ss[p] = c4; sTot += c4;
    }
    // Of two near-equal combs a quarter beat apart (at half-time: a kick on 1 and one on the "and" of 3), the one that puts
    // the snare-like accents on its beats and half-beats is the beat (a snare is never on a quarter-beat of the felt pulse).
    // The half-beat rival scores the same on this and is decided below on the raw comb.
    // (snare-like accents on the half-beat count in proportion to how much of the comb they would be: scale-free)
    const half = Math.round(T / 2), nr = (a, p) => Math.max(a[((p - 1) % P + P) % P], a[p % P], a[(p + 1) % P]), sk = sTot > 1e-6 ? tot / sTot : 0;
    const c2 = this.sc3 || (this.sc3 = new Float32Array(128));
    let cRaw = -1; for (let p = 0; p < P; p++) { c2[p] = cs[p] + sk * (0.5 * nr(ss, p) + 1.0 * nr(ss, p + half)); if (cs[p] > cRaw) { cRaw = cs[p]; bp = p; } }
    // only the quarter-beat rivals of the best raw comb are arbitrated this way (a half-beat rival scores the same)
    b2 = c2[bp]; const q4 = Math.round(T / 4);
    for (const d of [-q4, q4]) for (let e = -2; e <= 2; e++) { const q = ((bp + d + e) % P + P) % P; if (c2[q] > b2 && cs[q] > 0.5 * cRaw) { b2 = c2[q]; bp = q; } }
    bc = cs[bp];
    // the comb half a beat away is the usual rival (off-beat bass, off-beat hats): stay where we are unless it is clearly better
    const curP = ((Math.round(fract(this.pc) * T - 1.5) % P) + P) % P, near = (p, a) => { let m = 0; for (let d = -2; d <= 2; d++) m = Math.max(m, a[((p + d) % P + P) % P]); return m; };
    const dist = Math.abs(((bp - curP + P * 1.5) % P) - P / 2), halfRival = Math.abs(dist - P / 2) <= 4;
    if (dist > 4 && (halfRival ? near(curP, cs) > 0.85 * bc : near(curP, c2) > 0.85 * b2) && this.hbN > 8) bp = -1;
    if (bp >= 0) {
      // the beat happened (bp + 1.5) samples ago (1.5: what the spectrum window and the flux add)
      let e = (bp + 1.5) / T - fract(this.pc); e -= Math.round(e);
      this.lockE += (Math.min(Math.abs(e), 0.5) - this.lockE) * 0.2;
      if (Math.abs(e) > 0.2) { if (++this.phBad >= 3 || this.hbN < 8) { this.pc += e; this.phBad = 0; } } else { this.pc += e * 0.4; this.phBad = 0; }
    } else this.phBad = 0;
  },
  /* SECTIONS: the feature vector (9 bands of spectral shape, 3 onset densities, loudness) of the last three half-bars
     against the eight half-bars before them, each side reduced to a per-feature median of half-bar means (so a fill, a
     pause or one loud hit cannot fake or hide a change), and scaled by how much the earlier half-bars differ among
     themselves (so a groove that alternates bar to bar is not a change). Fires on the beat after the change is clear; the
     estimated start of the new section (the change point, or the impact that opened it) is kept so sectionAge counts
     from there. A strong impact with a clearly different half-bar after it confirms a section at once. */
  sections(now, quiet) {
    const beatOK = this.beatConf > 0.4 && this.T > 0, beat = beatOK ? this.beatSec() : 0, S = beatOK ? clamp(2 * beat * (beat < 0.4 ? 2 : 1), 0.7, 1.4) : 1, s = Math.round(S / 0.05), nSub = Math.min(11, Math.floor(this.hN / s));
    this.nv *= 0.9;
    if (this.quietT > 0.7) { if (this.quietT > 4) this.secPend = 2; return; }
    // the first sound of a track, or music coming back after a long silence, opens a section there and then
    if (this.secPend === 2 || !this.everSound) { this.everSound = true; this.secPend = 0; this.hN = 0; this.hI = 0; this.fireSection(now, now - 0.1, 0); return; }
    if (nSub < 7) return;
    // the earlier side only holds half-bars of the section we are in: a section is at least eight half-bars long (unless an
    // impact opens the next one), and its first bars are never compared with the section before it
    const sub = this.sub, A = this.sA, B = this.sB, D = this.sD, srt = this.srt, nB = Math.min(nSub - 3, Math.floor((now - this.secT0) / S) - 4); // (-4: the three newest, and the section's own first half-bar: a crash dying away, the arrival)
    if (nB < 4) return;
    for (let j = 0; j < nSub; j++) for (let k = 0; k < CUE_NV; k++) { let m = 0; for (let i = 0; i < s; i++) m += this.hv(k, j * s + i); sub[j * CUE_NV + k] = m / s; }
    let nvSum = 0, nv0Sum = 0, dL0 = 0;
    for (let k = 0; k < CUE_NV; k++) {
      const a0 = sub[k], a1 = sub[CUE_NV + k], a2 = sub[2 * CUE_NV + k];
      A[k] = Math.max(Math.min(a0, a1), Math.min(Math.max(a0, a1), a2));
      for (let j = 0; j < nB; j++) { let v = sub[(j + 3) * CUE_NV + k], i = j; while (i > 0 && srt[i - 1] > v) { srt[i] = srt[i - 1]; i--; } srt[i] = v; }
      B[k] = nB & 1 ? srt[nB >> 1] : 0.5 * (srt[(nB >> 1) - 1] + srt[nB >> 1]);
      let mad = 0; for (let j = 0; j < nB; j++) mad += Math.abs(srt[j] - B[k]); mad /= nB;
      const fl = k < 9 ? 2.5 : k < 12 ? 0.1 : 4, sc = fl + 2 * mad, w = k === 12 ? 3 : 1;
      D[k] = (A[k] - B[k]) / sc; const d0 = (a0 - B[k]) / sc; if (k === 12) dL0 = d0;
      nvSum += w * Math.min(D[k] * D[k], 16); nv0Sum += w * Math.min(d0 * d0, 16);
    }
    this.nv = Math.sqrt(nvSum / (CUE_NV + 2)); this.nv0 = Math.sqrt(nv0Sum / (CUE_NV + 2));
    const bar = beatOK ? this.barHB * beat / 2 : 2, since = now - this.secT;
    // right after a strong impact one clearly different half-bar is enough (and may come sooner after the last section)
    const fast = now - this.impLast < 1.25 * S && now - this.impLast > 0.5 * S && this.impLastS >= 0.4 && (this.nv0 > 1.25 || Math.abs(dL0) > 1.1) && since > Math.max(2.5, bar);
    // with a pulse the half-bars line up with the music and a smaller difference is believed; without one (rubato, drones)
    // phrases differ from each other anyway and only a clear change of texture counts. Never in the middle of a build.
    // (and a section that has only just begun needs a clearer change: its own picture is still forming)
    if (!(fast || (this.nv > (beatOK ? 0.9 : 1.45) * (1 + 0.125 * (8 - Math.min(nB, 8))) && since >= clamp(4 * bar, 5, 8) && !(this.ten > 0.12 && this.buildOn)))) return;
    // where it changed: the split of the last three half-bars that best separates "like before" from "like now"
    let t0 = now - 1.5 * S;
    if (fast) t0 = this.impLast;
    else {
      const n3 = 3 * s; let tot = 0, run = 0, best = -1e9, bi = n3 >> 1;
      for (let pass = 0; pass < 2; pass++) for (let i = n3 - 1; i >= 0; i--) { let p = 0; for (let k = 0; k < CUE_NV; k++) if (Math.abs(D[k]) > 0.5) p += Math.sign(D[k]) * (this.hv(k, i) - 0.5 * (A[k] + B[k])); if (pass === 0) tot += p; else { const sc2 = tot - 2 * run; if (sc2 > best) { best = sc2; bi = i; } run += p; } }
      t0 = now - (bi + 1) * 0.05;
      if (Math.abs(this.impLast - t0) < 0.9 * S && this.impLastS >= 0.4) t0 = this.impLast;
    }
    this.fireSection(now, t0, beat);
  },
  fireSection(now, t0, beat) {
    let t = now;
    if (beat > 0) { // on the beat: the one just passed if it is still within reach of the look-ahead, else the next
      const ph = fract(this.pc), back = ph * beat; t = back < 0.1 ? now - back : now + (1 - ph) * beat;
      const k = Math.round((t0 - t) / beat); t0 = Math.min(t, t + k * beat); // and the section start on the same grid
    }
    this.secT = now; this.secT0 = t0; this.secCount++; this.charT = 0;
    cuePush({ t, type: 1, t0, n: this.secCount });
    if (this.T > 0 && this.hbCur >= 0) this.phrAnchor = Math.floor((this.pc - Math.max(0, now - t0) / this.beatSec()) * 2 + 0.5);
  },
  // one half-beat of the clock has ended: store its accents, and on whole beats re-read metre, feel and downbeat
  halfBeat(now) {
    const i = ((this.hbCur % CUE_HB) + CUE_HB) % CUE_HB;
    this.hbL[i] = this.aL; this.hbM[i] = this.aM; this.hbH[i] = this.aH; this.hbS[i] = this.aS; this.aS = 0; this.hbP[i] = this.aP; this.aL = this.aM = this.aH = this.aP = 0;
    let cn = 0; for (let k = 0; k < 12; k++) cn += this.aC[k] * this.aC[k]; cn = Math.sqrt(cn) || 1;
    for (let k = 0; k < 12; k++) { this.hbC[i * 12 + k] = this.aC[k] / cn; this.aC[k] = 0; }
    this.hbCur++; if (this.hbN < CUE_HB) this.hbN++;
    this.hbV[((this.hbCur + 8) % CUE_HB + CUE_HB) % CUE_HB] = 0; // votes ahead of the write position are stale
    const h = this.hbCur;
    if ((h & 1) === 0) this.metre();
    // schedule the downbeat this half-beat may be (its nominal time is a quarter beat ahead of now)
    if (this.beatConf > 0.4 && (this.beatEv > 0.4 || this.downConf > 0.35) && ((h - this.phi) % this.barHB + this.barHB) % this.barHB === 0) { // (on the flywheel alone only with a sure bar line)
      const t = now + (h / 2 - this.pc) * this.beatSec(), bar = Math.round((h - this.phi) / this.barHB);
      if (t - this.lastDbT > 0.6 * this.barHB * this.beatSec() / 2) { this.lastDbT = t; cuePush({ t, type: 4, phrase: ((bar - this.phrBar0) % 8 + 8) % 8 === 0 }); }
    }
  },
  metre() {
    const N = Math.min(this.hbN - 1, 96), h1 = this.hbCur - 1; if (N < 24) return;
    const ix = (h) => ((h % CUE_HB) + CUE_HB) % CUE_HB;
    let mL = 0, mM = 0, mS = 0; for (let j = 0; j < N; j++) { const i = ix(h1 - j); mL += this.hbL[i]; mM += this.hbM[i]; mS += this.hbS[i]; }
    mL = mL / N + 1e-3; mM = mM / N + 1e-3; mS = mS / N + 1e-3;
    // triple or quadruple: does the onset envelope repeat every 3 beats or every 4 (from the tempo tracker)
    // does the pattern of low accents repeat every three beats rather than every two or four (oom-pah-pah)
    const acL = (lag) => { let s2 = 0, e2 = 0; for (let j = 0; j < N - lag; j++) { const u = this.hbL[ix(h1 - j)] / mL - 1, w = this.hbL[ix(h1 - j - lag)] / mL - 1; s2 += u * w; e2 += u * u; } return e2 > 1e-6 ? s2 / e2 : 0; };
    const a6 = acL(6), a4 = acL(4), a8 = acL(8);
    // and the bar itself: fold the low accents and the chord changes on a bar of 3 beats and on one of 4, and see on which
    // the beats differ from each other (oom-pah-pah: the "oom" is on one beat of three; folded on four it smears evenly)
    const cc = this.ccB || (this.ccB = new Float32Array(CUE_HB)), sp2 = this.mul > 1 ? 1 : 2;
    for (let j = 2; j < N - 2; j++) { const h = h1 - j; let dot = 0, na = 0, nb = 0; for (let c = 0; c < 12; c++) { const u = this.hbC[ix(h + 1) * 12 + c] + this.hbC[ix(h + sp2) * 12 + c], w = this.hbC[ix(h - 1) * 12 + c] + this.hbC[ix(h - sp2) * 12 + c]; dot += u * w; na += u * u; nb += w * w; } cc[j] = 1 - dot / (Math.sqrt(na * nb) + 1e-9); }
    const fold = (P, f) => { const m = new Float32Array(P), n = new Float32Array(P); for (let j = 2; j < N - 2; j++) { const k = (((h1 - j) % P) + P) % P; m[k] += f(j); n[k]++; } let a = 0, v = 0, q = 0; for (let k = 0; k < P; k += 2) { const x = m[k] / Math.max(1, n[k]); a += x; v += x * x; q++; } a /= q; return a > 1e-6 ? Math.sqrt(Math.max(0, v / q - a * a)) / a : 0; };
    const lowF = (j) => this.hbL[ix(h1 - j)] / mL, chF = (j) => cc[j];
    const cv3 = fold(6, lowF) + fold(6, chF), cv4 = fold(8, lowF) + fold(8, chF);
    const tri = this.triAC || (cv3 > 0.5 && cv3 > 1.6 * cv4) || (a6 > 0.3 && a6 > a8 + 0.15 && a6 > a4 + 0.15 && cv3 > cv4); this.dbgT = [a4, a6, a8, cv3, cv4];
    if (tri !== this.triple) { if (++this.tripN > 12) { this.triple = tri; this.tripN = 0; } } else this.tripN = 0;
    // feel: where the backbeat (strong mid-band hits) repeats. On every beat of the clock: the clock runs at half speed;
    // every 2 beats: as it should; every 4: half-time
    let mul = 1;
    if (!this.triple) {
      // (the backbeat is a snare: broadband mid accents and snare-like rises of the top third, each against its own mean)
      const r = this.sc; r.fill(0); for (let j = 0; j < N; j++) r[(((h1 - j) % 8) + 8) % 8] += this.hbM[ix(h1 - j)] / mM + this.hbS[ix(h1 - j)] / mS;
      let tot = 1e-6, x2 = 0, x4r = 0, x4i = 0, x8r = 0, x8i = 0;
      for (let k = 0; k < 8; k++) { tot += r[k]; x2 += r[k] * (k & 1 ? -1 : 1); x4r += r[k] * Math.cos(Math.PI * k / 2); x4i += r[k] * Math.sin(Math.PI * k / 2); x8r += r[k] * Math.cos(Math.PI * k / 4); x8i += r[k] * Math.sin(Math.PI * k / 4); }
      const A2 = Math.abs(x2) / tot, A4 = Math.hypot(x4r, x4i) / tot, A8 = Math.hypot(x8r, x8i) / tot, bpm = 6000 / this.T;
      this.dbgA = [A2, A4, A8];
      if (A8 > 0.3 && A8 > 1.5 * A4 && A8 > 1.5 * A2 && bpm > 100) mul = 0.5;
      else if (A2 > 0.3 && A2 > 1.5 * A4 && A2 > 1.3 * A8 && bpm < 110) mul = 2;
    }
    if (mul !== this.mul) { if (mul === this.mulCand) { if (++this.mulN > 16) { this.mul = mul; this.mulN = 0; } } else { this.mulCand = mul; this.mulN = 0; } } else this.mulN = 0;
    const barHB = this.triple ? 6 : this.mul < 1 ? 16 : this.mul > 1 ? 4 : 8;
    if (barHB !== this.barHB) { this.barHB = barHB; this.phiN = 0; this.phi %= barHB; }
    // (chroma change across half-beat h: the half-beats after it against those before it; h itself straddles the change)
    // downbeat: per position in the bar, mean low accent, chroma change across it, snare-like accent (the backbeat is never
    // the downbeat; v22 third pass: the snare ring, not the mid band, which also carries the kick's and the bass's attack), peak level, and the votes of impacts and section starts
    const P = barHB, R = this.res, span = this.mul > 1 ? 1 : 2; R.fill(0);
    for (let j = 3; j < N - 2; j++) {
      const h = h1 - j, k = ((h % P) + P) % P, i = ix(h); let dot = 0, na = 0, nb = 0;
      for (let c = 0; c < 12; c++) { const u = this.hbC[ix(h + 1) * 12 + c] + (span > 1 ? this.hbC[ix(h + 2) * 12 + c] : 0), w = this.hbC[ix(h - 1) * 12 + c] + (span > 1 ? this.hbC[ix(h - 2) * 12 + c] : 0); dot += u * w; na += u * u; nb += w * w; }
      R[k * 6] += this.hbL[i] / mL; R[k * 6 + 1] += 1 - dot / (Math.sqrt(na * nb) + 1e-9); R[k * 6 + 2] += this.hbS[i] / mS; R[k * 6 + 5] += this.hbM[i] / mM; R[k * 6 + 3] += this.hbV[i]; R[k * 6 + 4] += this.hbP[i];
    }
    const z = (c, k) => { let m = 0, v = 0; for (let q = 0; q < P; q++) m += R[q * 6 + c]; m /= P; for (let q = 0; q < P; q++) v += (R[q * 6 + c] - m) ** 2; v = Math.sqrt(v / P); return v > 1e-6 ? (R[k * 6 + c] - m) / v : 0; };
    let vmax = 1e-6; for (let q = 0; q < P; q++) vmax = Math.max(vmax, R[q * 6 + 3]);
    let best = -1e9, second = -1e9, bk = 0;
    for (let k = 0; k < P; k += this.mul > 1 ? 1 : 2) { // (a downbeat is on a beat of the clock, unless the clock runs at half speed)
      const s = 0.8 * z(0, k) + 1.0 * z(1, k) - 0.6 * z(2, k) - 0.15 * z(5, k) + 0.5 * z(4, k) + (vmax > 0.5 ? 1.0 * R[k * 6 + 3] / vmax : 0) + (this.triple ? 0 : 0.25 * z(0, (k + (P >> 1)) % P));
      this.sc[k] = s; if (s > best) { second = best; best = s; bk = k; } else if (s > second) second = s;
    }
    if (this.mul <= 1 && (this.phi & 1)) this.phi = (this.phi + 1) % P;
    const cur = this.sc[this.phi % P];
    if (bk !== this.phi) { if (bk === this.phiCand) { if (++this.phiN >= 8 || best > cur + 2.5) { this.phi = bk; this.phiN = 0; } } else { this.phiCand = bk; this.phiN = 0; } } else this.phiN = 0;
    this.downConf += (clamp((best - second) / 2, 0, 1) * (bk === this.phi ? 1 : 0.3) - this.downConf) * 0.25;
    // phrases count from the bar of the last section start
    if (this.phrAnchor >= 0) { this.phrBar0 = Math.round((this.phrAnchor - this.phi) / this.barHB); this.phrAnchor = -1; }
  },
  // once per analysed frame: chroma for the beat grid, and everything continuous into FA
  frame(dt, fS, sr2, fft2, silent) {
    const dB = (p) => 4.3429448 * Math.log(p + 1e-12), floor = this.ref - 50;
    if (fS && !silent) {
      if (!this.chromaMap || this.chromaSr !== sr2 || this.chromaMap.length !== fS.length) this.setupChroma(sr2, fft2, fS.length);
      const cm = this.chromaMap, n = this.chromaN, a = this.aC; for (let i = 1; i <= n; i++) if (cm[i] >= 0) a[cm[i]] += Math.exp(fS[i] * 0.1151293);
    }
    const quiet = this.quietT > 0.3 || silent;
    FA.energy = ease(FA.energy, quiet ? 0 : clamp((dB(this.pAR) - this.ref + 30) / 30, 0, 1), dt, 0.15);
    FA.energyTrend = ease(FA.energyTrend, quiet ? 0 : clamp((dB(this.p2) - dB(this.p8)) / 10, -1, 1), dt, 0.3);
    let mn = 1e9, mx = -1e9; for (let i = 0; i < this.swN; i++) { mn = Math.min(mn, this.sw[i]); mx = Math.max(mx, this.sw[i]); }
    const L3 = Math.max(dB(this.p3), floor);
    FA.swell = ease(FA.swell, quiet || this.swN < 3 ? 0 : clamp((L3 - mn) / Math.max(mx - mn, 8), 0, 1), dt, 0.3);
    FA.swellDir = ease(FA.swellDir, quiet ? 0 : this.swDir, dt, 0.5);
    FA.tension = silent && this.tenHold <= 0 ? ease(FA.tension, 0, dt, 0.5) : this.ten;
    FA.novelty = clamp(this.nv / 2, 0, 1);
    FA.bright = ease(FA.bright, this.hN ? clamp((this.hv(14, 0) - 2) / 6, 0, 1) : 0.5, dt, 0.25); this.bright = FA.bright;
    FA.sustain = this.sustain;
    // section character, eased toward the running picture of the current section (up to its last 12 s)
    this.charT += dt;
    if (this.charT > 0.25 && this.hN > 4) {
      this.charT = 0; const n = Math.min(this.hN, Math.max(10, Math.min(240, Math.round((this.now - this.secT0) / 0.05)))), c = this.char;
      let lo = 0, mi = 0, hi = 0, fx = 0, br = 0, lv = 0;
      for (let j = 0; j < n; j++) { lo += this.hv(0, j) + this.hv(1, j) + this.hv(2, j); mi += this.hv(3, j) + this.hv(4, j) + this.hv(5, j); hi += this.hv(6, j) + this.hv(7, j) + this.hv(8, j); fx += this.hv(9, j) + this.hv(10, j) + this.hv(11, j); br += this.hv(14, j); lv += this.hv(12, j); }
      const tot = lo + mi + hi + 1e-6; c[0] = lo / tot; c[1] = mi / tot; c[2] = hi / tot; c[3] = clamp(fx / n / 1.2, 0, 1); c[4] = clamp((br / n - 2) / 6, 0, 1); c[5] = clamp((lv / n - 20) / 30, 0, 1);
    }
    const c = this.char, k = 1 - Math.exp(-dt / 0.5);
    FA.secLow += (c[0] - FA.secLow) * k; FA.secMid += (c[1] - FA.secMid) * k; FA.secHigh += (c[2] - FA.secHigh) * k; FA.secDense += (c[3] - FA.secDense) * k; FA.secBright += (c[4] - FA.secBright) * k; FA.secEnergy += (c[5] - FA.secEnergy) * k;
    // beat grid
    // Is there a pulse: the onset pattern repeats at the beat and the bar (tConf), the tempo has held for some seconds, and the
    // clock has not needed pushing about (lockE: mean phase correction, in beats). Once locked the grid free-wheels through
    // passages with nothing to hold on to (a breakdown, a short silence) for 20 s, at a confidence of .45.
    this.beatEv = ease(this.beatEv, silent || !(this.T > 0) ? 0 : clamp((this.tConf - 0.3) / 0.4, 0, 1) * clamp((0.14 - this.lockE) / 0.08, 0, 1) * clamp(this.stableT / 5, 0, 1), dt, 1);
    this.fly = this.beatEv > 0.5 ? 1 : Math.max(0, this.fly - dt / (this.quietT > 6 ? 2 : 20));
    this.beatConf = Math.max(this.beatEv, this.fly > 0 ? 0.45 : 0);
    const ok = this.beatConf > 0.4 && this.T > 0;
    FA.beatConf = this.beatConf; FA.tempo = this.T > 0 ? 6000 / this.T * this.mul : 0; FA.meter = this.triple ? 3 : 4; FA.downConf = ok ? this.downConf : 0;
    if (ok) {
      const pcNow = this.pc + Math.max(0, nowS() - this.now) / this.beatSec(), pos = (pcNow * 2 - this.phi) / this.barHB, bp = fract(pos);
      FA.barPhase = bp; FA.pulse = fract(bp * FA.meter); FA.barBeat = Math.floor(bp * FA.meter);
      FA.phrasePos = (((Math.floor(pos) - this.phrBar0) % 8 + 8) % 8 + bp) / 8;
    } else {
      FA.barPhase = FA.pulse = 0; FA.barBeat = 0;
      FA.phrasePos = this.phT > -1e8 ? clamp((nowS() - this.phT) / this.phLen, 0, 0.98) : 0;
    }
  }
};
// A drop (the old cue, unchanged) is always an impact and a downbeat. Its strength still depends on what the level did:
// a drop the level detector also saw is the biggest thing there is, one it did not see stays modest.
CUE.onDrop = function (at) {
  this.dropT = at;
  // By itself the old cue is not an impact (it also fires on bass swells in ambient and piano music). It is one when the bass
  // had really been away while the music went on (or tension had built) and the low end leapt back in a tenth of a second.
  const N = this.tN, I = this.tI; let lo0 = 1e9, lo1 = -1e9;
  for (let j = 0; j < N; j++) { const i = (I - 1 - j + CUE_TN * 2) % CUE_TN, a = this.tT[i] - at; if (a < -0.25) break; if (a >= -0.02) lo1 = Math.max(lo1, this.tLo[i]); else lo0 = Math.min(lo0, this.tLo[i]); }
  if (this.log) this.log('onDrop: thinT ' + this.thinT.toFixed(1) + ' ten ' + this.ten.toFixed(2) + ' lowLeap ' + (lo1 - lo0).toFixed(1) + ' sinceImp ' + (at - this.impLast).toFixed(2));
  if (Math.abs(at - this.impLast) < 0.45) this.raiseImpact(this.impLast, this.impLastS);
  else if ((this.thinT >= 2.5 || this.ten >= 0.4) && lo1 - lo0 >= 6) { this.impState = 0; this.raiseImpact(at, 0.6 + 0.3 * Math.max(this.ten, clamp(this.thinT / 8, 0, 1))); }
  if (this.T > 0 && this.hbCur >= 0) { // the drop is bar one of a new phrase
    const h = 2 * Math.round(this.pc - Math.max(0, this.now - at) / this.beatSec());
    this.phi = ((h % this.barHB) + this.barHB) % this.barHB; this.phiN = 0; this.phrAnchor = h; this.downConf = Math.max(this.downConf, 0.5);
    this.hbV[((h % CUE_HB) + CUE_HB) % CUE_HB] += 2;
  }
};
let cueOvHook = null; // the developer overlay (cue-overlay.js) hooks in here when it is open
// called by syncVisualFeatures: hand over every cue event that is audible now, and update what follows events
function cueDeliver(audible) {
  const V = CUE_VIS;
  F.onSection = F.onImpact = F.onDownbeat = F.onPhrase = F.onNote = false;
  while (CUE_EVENTS.length && CUE_EVENTS[0].t <= audible + 1e-4) {
    const e = CUE_EVENTS.shift();
    if (e.type === 1) { F.onSection = true; V.section++; V.secT0 = e.t0; }
    else if (e.type === 2) { if (e.up) V.impS = Math.max(V.impS * Math.exp(-Math.max(0, audible - V.impT) / 1.2), e.s); else F.onImpact = true; V.impT = e.t; V.impS = e.up ? V.impS : e.s; F.impactStrength = V.impS; }
    else if (e.type === 3) { F.onNote = true; V.noteT = e.t; V.noteS = e.s; V.notePos = e.pos; }
    else if (e.type === 4) { if (e.t - V.dbT > 0.25) { F.onDownbeat = true; V.dbT = e.t; if (e.phrase) { F.onPhrase = true; V.phrT = e.t; } } }
    else if (e.type === 5) { F.onPhrase = true; V.phrT = e.t; }
  }
  F.section = V.section; F.sectionAge = V.secT0 > -1e8 ? Math.max(0, audible - V.secT0) : 0;
  F.sectionSeed = fract(Math.sin(V.section * 127.1 + 311.7) * 43758.5453); // a fixed "random" number per section, the same on every run
  F.impact = V.impS * Math.exp(-Math.max(0, audible - V.impT) / 1.2); F.impactStrength = V.impS;
  F.note = V.noteS * Math.exp(-Math.max(0, audible - V.noteT) / 0.22); F.notePos = V.notePos;
  if (cueOvHook) cueOvHook(audible);
}

const AU = {
  ctx: null, input: null, out: null, anaF: null, anaS: null, mode: 'none',
  el: null, elSrc: null, stream: null, streamSrc: null, demo: null, list: [], idx: -1, rev: 0, hist: [], bag: null, cur: null, fails: 0, // v21 queue: rev counts edits, hist is the play history, bag the rest of a shuffled pass
 
  fS: null, fF: null, wv: null, prevF: null,
  logv: new Float32Array(NB), disp: new Float32Array(NB), gHi: 0.6, hi: new Float32Array(NB).fill(0.5), map: [],
  band: null, kickD: new Onset(90, 0.2), hitD: new Onset(90, 0.11), hatD: new Onset(60, 0.07),
  ev: { kick: -1, kickT: 0, hit: -1, hat: -1, kick2: -1 }, tickT: 0, fastTimer: 0, phist: new Float32Array(16), phaseT: 0,
  ose: new Float32Array(800), oseI: 0, oseAcc: 0, tmp: new Float32Array(800), tempoT: 0, bpmMiss: 0,
  silentT: 0, now: 0, lastKickT: -9, lowS: 0, lowPeak: 0, bdTime: 0, dropCool: 0, hitRate: 0, barOffset: 0, lastBarIdx: 0,
  taps: [],
  init() {
    if (this.ctx) { if (this.ctx.state === 'suspended') this.ctx.resume(); return true; }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) { toast('Web Audio is not available in this browser.'); return false; }
    try { if (navigator.audioSession) navigator.audioSession.type = 'playback'; } catch (e) { /* not supported */ }
    const ctx = this.ctx = new AC({ latencyHint: 'interactive' });
    // MOBILE/iOS: Web Audio unlocks only by starting a sound inside a touch; a one-sample silent buffer does it
    try { const sb = ctx.createBufferSource(); sb.buffer = ctx.createBuffer(1, 1, ctx.sampleRate); sb.connect(ctx.destination); sb.start(0); } catch (e) { /* not needed */ }
    this.input = ctx.createGain();
    // what you hear from files and the demo runs LOOK seconds behind the analysis, so drops are seen coming
    this.out = ctx.createGain(); this.out.gain.value = S.volume;
    this.look = ctx.createDelay(1); this.look.delayTime.value = LOOK;
    this.captureMix = ctx.createGain(); // stable mic/shared-audio recording bus; never monitored to speakers
    this.out.connect(this.look); this.look.connect(ctx.destination);
    this.anaF = ctx.createAnalyser(); this.anaF.fftSize = 1024; this.anaF.smoothingTimeConstant = 0;
    this.anaS = ctx.createAnalyser(); this.anaS.fftSize = 4096; this.anaS.smoothingTimeConstant = 0.5;
    this.input.connect(this.anaF); this.input.connect(this.anaS);
    this.fastTimer = setInterval(() => this.fastTick(), 10);
    this.fS = new Float32Array(this.anaS.frequencyBinCount);
    this.fF = new Float32Array(this.anaF.frequencyBinCount);
    this.prevF = new Float32Array(this.anaF.frequencyBinCount);
    this.wv = new Float32Array(this.anaS.fftSize);
    const binHz = ctx.sampleRate / this.anaS.fftSize, fLo = 28, fHi = 16000;
    this.map = [];
    for (let b = 0; b < NB; b++) {
      const f0 = fLo * Math.pow(fHi / fLo, b / NB), f1 = fLo * Math.pow(fHi / fLo, (b + 1) / NB);
      this.map.push([f0 / binHz, f1 / binHz]);
    }
    const toBin = (f) => clamp(Math.round(NB * Math.log(f / fLo) / Math.log(fHi / fLo)), 0, NB - 1);
    const mk = (a, b) => ({ b0: toBin(a), b1: Math.max(toBin(a) + 1, toBin(b)), raw: 0, lo: 0.3, hi: 0.6, env: 0 });
    this.band = { sub: mk(28, 60), bass: mk(60, 180), lowMid: mk(180, 600), mid: mk(600, 2500), high: mk(2500, 7000), air: mk(7000, 16000) };
    const fHz = ctx.sampleRate / this.anaF.fftSize;
    this.fr = {
      low: [Math.max(1, Math.round(40 / fHz)), Math.max(2, Math.round(150 / fHz))],
      mid: [Math.round(1200 / fHz), Math.round(6000 / fHz)],
      high: [Math.round(7000 / fHz), Math.min(this.fF.length - 1, Math.round(16000 / fHz))]
    };
    const el = this.el = new Audio();
    el.preload = 'auto'; el.crossOrigin = 'anonymous';
    this.elSrc = ctx.createMediaElementSource(el);
    this.elSrc.connect(this.input); this.elSrc.connect(this.out);
    el.addEventListener('ended', () => { if (this.mode === 'file') this.nextTrack(1, true); });
    el.addEventListener('play', updateTransport); el.addEventListener('pause', updateTransport);
    el.addEventListener('loadedmetadata', updateTransport);
    el.addEventListener('error', () => { if (this.mode === 'file' && this.pl === el && el.src) this.useBuffer(this.list[this.idx]); }); // v21: per track (one odd file no longer switches the whole queue to in-memory decoding)
    el.addEventListener('playing', () => { this.fails = 0; });
    this.pl = el;
    this.bp = makeBufferPlayer(ctx, [this.input, this.out], () => { if (this.mode === 'file') this.nextTrack(1, true); });
    return true;
  },
  stopAll() {
    if (this.el) { this.el.pause(); }
    if (this.bp) this.bp.stop();
    if (this.demo) { this.demo.stop(); try { this.demo.output.disconnect(); } catch (e) { /* already */ } this.demo = null; }
    if (this.stream) { this.stream.getTracks().forEach((t) => t.stop()); this.stream = null; }
    if (this.streamSrc) { try { this.streamSrc.disconnect(); } catch (e) { /* already */ } this.streamSrc = null; }
    if (this.synthSaved) { [this.anaF, this.anaS] = this.synthSaved; this.synthSaved = null; } // MOBILE: silent demo off
    this.mode = 'none';
  },
  resetAnalysis() {
    // A new track/render must not inherit the previous track or the page's idle wall-clock history.
    Object.assign(FA, mkFeatures()); Object.assign(F, mkFeatures()); FHIST.length = 0; for (const e of SPEC_RING.buf) e.t = -1e9; DROP_EVENTS.length = 0; this.dropRing = []; this.dropAudit = null; this.dropReturn = null; this.visualClockHigh = 0;
    Object.assign(this, { lowS: 0, lowF: 0, lowPeak: 0, bdTime: 0, dropCool: 3, hitRate: 0, bpmMiss: 0,
      oseI: 0, oseAcc: 0, tempoT: 0, tickT: 0, now: 0, silentT: 0, phaseT: 0, kickPeak: 0,
      lastKickT: -9, lowOnT: -9, dropKickT: -9, barOffset: 0, lastBarIdx: 0, forceBar: false });
    this.ose.fill(0); this.phist.fill(0); this.logv.fill(0); this.disp.fill(0); this.hi.fill(0.5); this.gHi = 0.6;
    if (this.prevF) this.prevF.fill(0);
    Object.assign(this.ev, { kick: -1, kickT: 0, hit: -1, hat: -1, kick2: -1 });
    CUE.reset(); // v22
    this.kickD = new Onset(90, 0.2); this.hitD = new Onset(90, 0.11); this.hatD = new Onset(60, 0.07);
    Object.values(this.band || {}).forEach((b) => { b.lo = 0.3; b.hi = 0.6; b.raw = b.env = 0; });
  },
  startDemo() {
    if (!this.init()) return;
    this.stopAll(); this.resetAnalysis();
    this.demo = createDemo(this.ctx);
    this.demo.output.connect(this.input); this.demo.output.connect(this.out);
    this.demo.start(); this.mode = 'demo';
    updateTransport();
    // MOBILE: if the browser keeps audio suspended (an embed or autoplay policy blocks it), the silent visual demo takes over
    const ctx = this.ctx;
    setTimeout(() => { if (this.mode === 'demo' && !OFF.on && ctx.state !== 'running') { this.startVisual(); toast('Sound is blocked here, so the silent visual demo is playing. Tap Demo to try sound again.'); } }, 1800);
  },
  // MOBILE: silent visual demo. Synthetic analysers replace the real ones (see makeSynthAnalyser), so the whole beat,
  // tempo, build and drop pipeline runs with no sound at all, even when the AudioContext is not running.
  startVisual() {
    if (!this.init()) return;
    this.stopAll(); this.resetAnalysis();
    const sr = this.ctx.sampleRate, t0 = nowS();
    this.synthSaved = [this.anaF, this.anaS];
    this.anaF = makeSynthAnalyser(1024, sr, t0); this.anaS = makeSynthAnalyser(4096, sr, t0);
    this.mode = 'visual'; updateTransport();
  },
  // v21 music queue. Files are added in name order (folders keep their own order), never twice; adding while a track plays
  // only extends the queue. Object URLs exist for the playing track only, so thousands of files cost nothing.
  addFiles(files) {
    const list = Array.from(files || []).filter((f) => /^audio\//.test(f.type) || /\.(mp3|wav|ogg|oga|m4a|aac|flac|opus|webm)$/i.test(f.name))
      .map((f) => ({ f, path: f.webkitRelativePath || f._path || f.name })).sort((a, b) => a.path.localeCompare(b.path, undefined, { numeric: true, sensitivity: 'base' }));
    if (!list.length) { toast('Those files are not audio. Drop MP3, WAV, OGG, M4A or FLAC files.'); return; }
    if (!this.init()) return;
    const have = new Set(this.list.map((t) => t.id)), fresh = [];
    for (const { f, path } of list) { const id = path + '|' + f.size; if (!have.has(id)) { have.add(id); fresh.push({ id, name: f.name.replace(/\.[^.]+$/, ''), url: null, file: f }); } }
    const start = this.list.length, playing = this.mode === 'file' && this.pl && !this.pl.paused;
    this.list.push(...fresh); this.rev++; if (this.bag) this.bag.push(...fresh);
    if (!fresh.length) { toast('Already in the queue'); return; }
    if (playing) { toast(fresh.length + (fresh.length > 1 ? ' tracks added' : ' track added')); updateTransport(); }
    else this.playIndex(S.plShuffle && fresh.length > 1 ? start + Math.floor(Math.random() * fresh.length) : start, true);
  },
  playIndex(i, announce) {
    const n = this.list.length; if (!n) return;
    this.stopAll(); this.resetAnalysis();
    this.idx = ((i % n) + n) % n;
    this.mode = 'file';
    const item = this.list[this.idx];
    if (this.cur && this.cur !== item && this.cur.url) { URL.revokeObjectURL(this.cur.url); this.cur.url = null; }
    this.cur = item; if (!item.url) item.url = URL.createObjectURL(item.file);
    if (this.hist[this.hist.length - 1] !== item) { this.hist.push(item); if (this.hist.length > 300) this.hist.shift(); }
    if (this.bag) this.bag = this.bag.filter((t) => t !== item);
    if (announce) toast('♪ ' + item.name, 3200);
    this.pl = this.el;
    this.el.src = item.url;
    this.el.play().catch((err) => { if (err && err.name === 'NotAllowedError') toast('Press play to start the track.'); });
    updateTransport();
  },
  useBuffer(item) {
    // fallback path: decode the whole file with Web Audio and play it from memory
    if (!item) return;
    this.el.pause();
    $('#trackName').textContent = 'Decoding ' + item.name + '...';
    item.file.arrayBuffer().then((ab) => this.ctx.decodeAudioData(ab)).then((buf) => {
      if (this.list[this.idx] !== item || this.mode !== 'file') return;
      this.fails = 0; this.bp.load(buf); this.pl = this.bp; this.bp.play(); updateTransport();
    }).catch(() => {
      if (this.list[this.idx] !== item || this.mode !== 'file') return;
      // v21: a file that cannot be played is skipped, so one bad file never stops a long queue
      if (this.list.length > 1 && ++this.fails < this.list.length) { toast('Skipped ' + item.name + ' (cannot be decoded)'); this.nextTrack(1, true, true); }
      else { toast('This file could not be decoded. Try MP3, WAV, OGG, M4A or FLAC.'); updateTransport(); }
    });
  },
  // d: +1 next, -1 previous. auto: the track ended by itself (repeat and the end of the queue apply).
  nextTrack(d, auto, skip) {
    const n = this.list.length; if (!n) return;
    if (auto && !skip && S.plRepeat !== 'off' && (S.plRepeat === 'one' || n === 1)) { this.pl.currentTime = 0; this.pl.play().catch(() => {}); return; }
    let i = this.idx + d;
    if (S.plShuffle && n > 1) {
      if (d < 0) { this.hist.pop(); const prev = this.hist.pop(); i = prev ? this.list.indexOf(prev) : -1; if (i < 0) i = this.idx - 1; }
      else { // a shuffled pass plays every track once before any comes back
        if (this.bag) this.bag = this.bag.filter((t) => this.list.includes(t) && t !== this.cur);
        if (!this.bag || !this.bag.length) { if (auto && S.plRepeat === 'off' && this.bag) { this.endQueue(); return; } this.bag = this.list.filter((t) => t !== this.cur); }
        i = this.list.indexOf(this.bag[Math.floor(Math.random() * this.bag.length)]);
      }
    } else if (auto && S.plRepeat === 'off' && i >= n) { this.endQueue(); return; }
    this.playIndex(i, true);
  },
  endQueue() { this.stopAll(); this.mode = 'none'; this.idx = 0; this.bag = null; updateTransport(); }, // the picture keeps running
  removeAt(i) {
    const item = this.list[i]; if (!item) return;
    const wasCur = this.mode === 'file' && i === this.idx;
    this.list.splice(i, 1); this.rev++; this.hist = this.hist.filter((t) => t !== item); if (this.bag) this.bag = this.bag.filter((t) => t !== item);
    if (i < this.idx) this.idx--;
    if (wasCur) {
      if (this.list.length) this.playIndex(this.idx >= this.list.length ? 0 : this.idx, true);
      else { this.stopAll(); this.mode = 'none'; this.idx = -1; }
    }
    if (item.url && this.cur !== item) { URL.revokeObjectURL(item.url); item.url = null; }
    updateTransport();
  },
  clearList() {
    if (this.mode === 'file') { this.stopAll(); this.mode = 'none'; }
    this.list.forEach((t) => { if (t.url) URL.revokeObjectURL(t.url); t.url = null; });
    this.list = []; this.idx = -1; this.rev++; this.hist = []; this.bag = null; this.cur = null;
    updateTransport();
  },
  async startCapture(kind) {
    if (!this.init()) return false;
    const md = navigator.mediaDevices;
    const constraints = { echoCancellation: false, noiseSuppression: false, autoGainControl: false };
    try {
      let stream;
      if (kind === 'mic') {
        // MOBILE/embeds: a sandboxed iframe without allow="microphone" (or plain http) can never get the mic; say so plainly
        const policy = document.permissionsPolicy || document.featurePolicy;
        if (policy && policy.allowsFeature && !policy.allowsFeature('microphone')) throw Object.assign(new Error('embed'), { name: 'EmbedError' });
        if (window.isSecureContext === false) throw Object.assign(new Error('insecure'), { name: 'InsecureError' });
        if (!md || !md.getUserMedia) throw new Error('unsupported');
        stream = await md.getUserMedia({ audio: constraints, video: false });
      } else {
        if (!md || !md.getDisplayMedia) throw new Error('unsupported');
        stream = await md.getDisplayMedia({ video: true, audio: constraints, systemAudio: 'include', selfBrowserSurface: 'exclude', surfaceSwitching: 'include' });
        stream.getVideoTracks().forEach((t) => t.stop());
        if (!stream.getAudioTracks().length) { stream.getTracks().forEach((t) => t.stop()); toast('No audio was shared. Pick a tab and switch on "Share tab audio" (or "Share system audio").'); return false; }
      }
      this.stopAll(); this.resetAnalysis();
      this.stream = stream;
      this.streamSrc = this.ctx.createMediaStreamSource(stream);
      this.streamSrc.connect(this.input);
      this.streamSrc.connect(this.captureMix);
      this.mode = kind;
      const tr = stream.getAudioTracks()[0];
      this.captureLabel = tr && tr.label ? tr.label : '';
      tr.addEventListener('ended', () => { if (this.mode === kind) { this.stopAll(); updateTransport(); toast(kind === 'mic' ? 'Microphone stopped.' : 'Audio sharing stopped.'); } });
      updateTransport();
      toast(kind === 'mic' ? 'Listening through the microphone.' : 'Capturing shared audio. Play music in that tab.');
      return true;
    } catch (err) {
      const name = err && err.name;
      if (name === 'EmbedError') toast('The microphone is blocked inside this embedded page. Use Demo, Silent or Files here, or open the page directly in Safari or Chrome for the mic.');
      else if (name === 'InsecureError') toast('The microphone needs a secure (https) page.');
      else if (MOBILE && kind === 'mic' && (name === 'NotAllowedError' || name === 'SecurityError')) toast('Microphone blocked: permission was refused or this embedded page cannot ask for it. Use Demo, Silent or Files instead.');
      else if (name === 'NotAllowedError' || name === 'SecurityError') toast(kind === 'mic' ? 'Microphone access was blocked. Allow it in the browser, or open this page directly instead of inside an embed.' : 'Screen and audio sharing was blocked here. Open this page directly in Chrome or Edge to capture tab audio.');
      else if (err && err.message === 'unsupported') toast(kind === 'mic' ? 'This browser cannot use the microphone here.' : 'This browser cannot capture tab audio. Use Chrome or Edge on desktop, or load files instead.');
      else if (name === 'NotFoundError') toast('No microphone was found.');
      else if (name !== 'AbortError') toast('Could not start ' + (kind === 'mic' ? 'the microphone' : 'audio capture') + '.');
      return false;
    }
  },
  tap() {
    const now = nowS();
    this.taps = this.taps.filter((t) => now - t < 3); this.taps.push(now);
    if (this.taps.length >= 3) {
      const iv = []; for (let i = 1; i < this.taps.length; i++) iv.push(this.taps[i] - this.taps[i - 1]);
      const avg = iv.reduce((a, b) => a + b, 0) / iv.length;
      FA.bpm = clamp(60 / avg, 60, 200); FA.conf = 1; FA.beatClock = Math.round(FA.beatClock);
      toast('Tempo set to ' + Math.round(FA.bpm) + ' BPM');
    }
  },
  live() { return OFF.on || (!!this.ctx && this.mode !== 'none' && !(this.mode === 'file' && this.pl.paused)); },
  latency() {
    // live captures are heard straight from their source; only our own output path needs compensating
    if (OFF.on) return LOOK;
    if (!this.ctx || (this.mode !== 'file' && this.mode !== 'demo')) return 0;
    return clamp((this.ctx.outputLatency || 0) + (this.ctx.baseLatency || 0), 0, 0.6) + LOOK;
  },
  bassReturn() {
    const rows=(this.dropRing||[]).filter(r=>r.t>=this.now-LOOK);
    const peak=Math.max(0,...rows.map(r=>r.p)),threshold=peak*.2;
    const high=[];for(let i=0;i<rows.length;i++)if(rows[i].p>=threshold)high.push(i);
    const end=high.length?high[high.length-1]:-1;let first=end;
    // Ignore an earlier disconnected low pickup. Bridge only one missing100Hz sample.
    for(let j=high.length-2;j>=0&&rows[first].t-rows[high[j]].t<=.025;j--)first=high[j];
    const latest=rows[rows.length-1],span=first>=0?rows[end].t-rows[first].t:0;
    const present=peak>1e-10&&!!latest&&this.now-latest.t<=.025&&latest.p>=threshold&&span>=.02-1e-6;
    let at=this.now,edge=first,reason='uncertain';
    if(present&&first>0){
      while(edge>0&&rows[edge-1].p<=rows[edge].p)edge--;
      if(edge>0&&peak>8*Math.max(1e-12,rows[edge].p)){
        const t=rows[Math.min(edge+1,first)].t-this.anaF.fftSize/(2*this.ctx.sampleRate);
        if(t>=this.now-LOOK&&t<=this.now){at=t;reason='sub-return';}
      }
    }
    return {at,reason,present,peak,latestPower:latest?.p||0,span,edge:rows[edge],crossing:rows[first]};
  },
  fastTick() {
    // ~100 Hz: onset detection and tempo envelope, independent of the render frame rate
    const now = nowS();
    const elapsed = this.tickT ? Math.min(now - this.tickT, 0.25) : 0.01;
    this.tickT = now;
    let oseVal = 0, cueOn = 0; // v22: cueOn = strength of any onset this tick, before the grid veto
    if(this.live()){
      this.anaF.getFloatFrequencyData(this.fF);
      const fF=this.fF;
      // Preserve bass returns even while the slower silence gate is still waking up.

      const subEnd=Math.max(1,Math.round(100*this.anaF.fftSize/this.ctx.sampleRate));
      let subPower=0;for(let i=1;i<=subEnd;i++)subPower+=Math.pow(10,fF[i]/10);
      const ring=this.dropRing||(this.dropRing=[]);ring.push({t:now,p:subPower});
      while(ring.length&&ring[0].t<now-.4)ring.shift();
    }
    if (this.live() && this.silentT < 0.7) {
      const fF = this.fF, pv = this.prevF, R = this.fr;
      // anaF was read above; the onset detector retains its existing silence/grid/refractory rules.
      const flux = (r) => { let s = 0; for (let i = r[0]; i <= r[1]; i++) { const v = clamp((fF[i] + 92) / 70, 0, 1.3), d = v - pv[i]; if (d > 0) s += d; } return s / (r[1] - r[0] + 1); };
      const lf = flux(R.low), mf = flux(R.mid), hf = flux(R.high);
      for (let i = 0; i < fF.length; i++) pv[i] = clamp((fF[i] + 92) / 70, 0, 1.3);
      const sens = S.reactivity;
      this.kickPeak = Math.max(lf, (this.kickPeak || 0) * Math.exp(-elapsed / 2.5));
      let k = this.kickD.push(lf, now, 1.6 / Math.sqrt(sens), 0.01 / sens);
      if (k >= 0) cueOn = 1;
      if (k >= 0) {
        const bc = FA.beatClock + Math.max(0, now - this.now) * (FA.bpm || 120) / 60, ph = fract(bc);
        // fold strong low-end onsets onto the beat grid; the histogram peak tells us where the kick really lands
        // Rejected rolling-bass candidates must not steer the quarter-note phase.
        // reject ghosts (weak versus recent kicks) and, once the tempo is locked, anything off the grid (rolling bass notes)
        const off = Math.min(ph, 1 - ph);
        if (lf >= this.kickPeak * 0.45) this.lowOnT = now; // strong low onset, on or off the grid (drop detection uses it)
        if (lf < this.kickPeak * 0.45) { k = -1; this.kickD.reject(); }
        else if (FA.conf > 0.5 && FA.bpm > 0 && off > 0.16) {
          // off the grid: a syncopated kick or a rolling bass note; show it as a softer pulse, keep it out of the beat clock
          this.ev.kick2 = Math.max(this.ev.kick2, lf / this.kickPeak);
          k = -1; this.kickD.reject();
        }
      }
      const h = this.hitD.push(mf, now, 1.9 / Math.sqrt(sens), 0.005 / sens);
      const t = this.hatD.push(hf, now, 1.9 / Math.sqrt(sens), 0.005 / sens);
      if (k >= 0) {
        const bc = FA.beatClock + Math.max(0, now - this.now) * (FA.bpm || 120) / 60, ph = fract(bc);
        if (lf > this.kickPeak * 0.4) { const bin = Math.floor(ph * 16) % 16; this.phist[bin] += lf; this.phist[(bin + 1) % 16] += lf * 0.4; this.phist[(bin + 15) % 16] += lf * 0.4; }
        this.ev.kick = Math.max(this.ev.kick, k); this.ev.kickT = now; DBG.acc = (DBG.acc || 0) + 1; }
      if (h >= 0) this.ev.hit = Math.max(this.ev.hit, h);
      if (t >= 0) this.ev.hat = Math.max(this.ev.hat, t);
      if (!cueOn) cueOn = h >= 0 ? 0.7 : t >= 0 ? 0.4 : 0;
      oseVal = lf + mf * 0.6 + hf * 0.2;
    }
    if (this.live()) CUE.tick(now, elapsed, this.fF, this.anaF.fftSize, this.ctx.sampleRate, cueOn); // v22 music structure cues
    this.oseAcc += elapsed * 100;
    while (this.oseAcc >= 1) { this.ose[this.oseI] = oseVal; this.oseI = (this.oseI + 1) % 800; this.oseAcc -= 1; }
  },
  analyze(dt) {
    this.now = nowS();
    FA.onKick = FA.onHit = FA.onDrop = FA.onBar = false;
    const live = this.live();
    const kickStr = this.ev.kick, hitStr = this.ev.hit, hatStr = this.ev.hat, kickT = this.ev.kickT, kick2 = this.ev.kick2;
    this.ev.kick = this.ev.hit = this.ev.hat = this.ev.kick2 = -1;
    if (live) {
      this.anaS.getFloatFrequencyData(this.fS);
      this.anaS.getFloatTimeDomainData(this.wv);
      const fS = this.fS, n = fS.length;
      let tot = 0;
      for (let b = 0; b < NB; b++) {
        const m = this.map[b];
        let v;
        if (m[1] - m[0] < 1) {
          const x = (m[0] + m[1]) * 0.5, i = Math.floor(x), fr = x - i;
          const a = clamp((fS[Math.min(i, n - 1)] + 92) / 70, 0, 1.3), c = clamp((fS[Math.min(i + 1, n - 1)] + 92) / 70, 0, 1.3);
          v = a + (c - a) * fr;
        } else {
          const i0 = Math.floor(m[0]), i1 = Math.min(n, Math.ceil(m[1]));
          let s = 0; for (let i = i0; i < i1; i++) s += clamp((fS[i] + 92) / 70, 0, 1.3);
          v = s / Math.max(1, i1 - i0);
        }
        tot += v;
        v += 0.26 * (b / NB);
        this.logv[b] = v;
        const hi = this.hi[b] = Math.max(v, this.hi[b] - dt * 0.035, 0.4);
        if (v > this.gHi) this.gHi = v;
        const s = 0.72 * clamp((v - (this.gHi - 0.55)) / 0.55, 0, 1) + 0.28 * clamp((v - (hi - 0.42)) / 0.42, 0, 1);
        this.disp[b] = s > this.disp[b] ? lerp(this.disp[b], s, 0.65) : ease(this.disp[b], s, dt, 0.12);
      }
      this.gHi = Math.max(0.45, this.gHi - dt * 0.03);
      // spectral centroid (timbre brightness) steers the hue a little
      let cw = 0, cs = 0;
      for (let b = 0; b < NB; b++) { const w = Math.max(0, this.logv[b] - 0.35); cw += w; cs += w * b; }
      FA.cent = ease(FA.cent, cw > 1e-3 ? cs / cw / NB : 0.45, dt, 0.6);
      this.silentT = tot / NB < 0.05 ? this.silentT + dt : 0;
      // waveform row: find a rising zero crossing for a steady trace
      const wv = this.wv; let z0 = 0;
      for (let i = 1; i < 1024; i++) { if (wv[i - 1] < 0 && wv[i] >= 0) { z0 = i; break; } }
      for (let i = 0; i < NB; i++) specBytes[NB + i] = clamp(Math.round((wv[z0 + i * 8] * 0.5 + 0.5) * 255), 0, 255);
    } else {
      this.silentT += dt;
      for (let b = 0; b < NB; b++) { this.disp[b] = ease(this.disp[b], 0, dt, 0.3); specBytes[NB + b] = 128; }
    }
    for (let b = 0; b < NB; b++) specBytes[b] = Math.round(this.disp[b] * 255);
    const silent = !live || this.silentT > 0.7;
    FA.silent = silent;
    FA.idle = ease(FA.idle, silent ? 1 : 0, dt, silent ? 1.2 : 0.25);

    // band envelopes with auto-ranging
    const out = {}, outN = {};
    if (this.band) {
      for (const k in this.band) {
        const B = this.band[k];
        let s = 0; for (let b = B.b0; b < B.b1; b++) s += this.logv[b];
        const raw = live ? s / (B.b1 - B.b0) : 0;
        B.raw = raw;
        if (live && !silent) {
          B.hi = Math.max(raw, B.hi - dt * 0.03);
          B.lo = Math.min(raw, B.lo + dt * 0.025);
          const n = clamp((raw - B.lo) / Math.max(B.hi - B.lo, 0.12), 0, 1);
          const tgt = clamp(Math.pow(n, 1.5) * S.reactivity, 0, 1.5);
          B.env = tgt > B.env ? ease(B.env, tgt, dt, 0.025) : ease(B.env, tgt, dt, 0.2);
          // v11: the same envelope without Audio sensitivity (at 2.5x the one above clips flat); realmAudio() starts from
          // it and applies the dial its own way. The engine, MUMM3 and LED 06 keep the one above.
          const tgtN = clamp(Math.pow(n, 1.5), 0, 1);
          B.envN = tgtN > (B.envN || 0) ? ease(B.envN || 0, tgtN, dt, 0.025) : ease(B.envN || 0, tgtN, dt, 0.2);
        } else { B.env = ease(B.env, 0, dt, 0.4); B.envN = ease(B.envN || 0, 0, dt, 0.4); }
        out[k] = B.env; outN[k] = B.envN;
      }
    }
    const real = {
      sub: out.sub || 0, bass: ((out.bass || 0) * 0.7 + (out.sub || 0) * 0.3),
      mid: ((out.lowMid || 0) * 0.4 + (out.mid || 0) * 0.6), high: ((out.high || 0) * 0.6 + (out.air || 0) * 0.4)
    };
    real.level = real.bass * 0.4 + real.mid * 0.35 + real.high * 0.25;

    // tempo: the 100 Hz onset envelope (filled by fastTick) is autocorrelated every 0.4 s
    this.tempoT += dt;
    if (this.tempoT > 0.4 && !silent) { this.tempoT = 0; this.estimateTempo(); }
    if (silent) FA.conf = ease(FA.conf, 0, dt, 4);

    // beat clock + phase-locked loop on kicks
    const bpmUse = FA.bpm > 0 ? FA.bpm : 120;
    FA.beatClock += dt * bpmUse / 60;
    // re-align the grid to the onset-phase histogram peak (where the kicks actually land)
    const ph16 = this.phist;
    for (let i = 0; i < 16; i++) ph16[i] *= Math.exp(-dt / 5);
    this.phaseT += dt;
    if (this.phaseT > 0.5 && FA.bpm > 0) {
      this.phaseT = 0;
      let bi = 0, sum = 0; for (let i = 0; i < 16; i++) { sum += ph16[i]; if (ph16[i] > ph16[bi]) bi = i; }
      if (sum > 0 && ph16[bi] > 2.2 * sum / 16) {
        let off = (bi + 0.5) / 16; if (off > 0.5) off -= 1;
        if (Math.abs(off) > 0.045) { FA.beatClock -= off * 0.6; for (let i = 0; i < 16; i++) ph16[i] *= 0.25; }
      }
    }
    if (kickStr >= 0 && !silent) {
      this.lastKickT = kickT;
      FA.onKick = true;
      FA.kick = Math.max(FA.kick, 0.55 + 0.45 * kickStr);
      const bc = FA.beatClock - Math.max(0, this.now - kickT) * bpmUse / 60;
      const ph = bc - Math.round(bc);
      if (FA.bpm > 0 && FA.conf > 0.15) { if (Math.abs(ph) < 0.3) FA.beatClock -= ph * 0.22; }
      else FA.beatClock = Math.round(FA.beatClock + 0.49);
    }
    if (kick2 >= 0 && !silent) FA.kick = Math.max(FA.kick, 0.2 + 0.35 * clamp(kick2, 0, 1));
    if (hitStr >= 0 && !silent) { FA.onHit = true; FA.hit = Math.max(FA.hit, 0.5 + 0.5 * hitStr); this.hitRate += 1; }
    if (hatStr >= 0 && !silent) FA.hat = Math.max(FA.hat, 0.45 + 0.55 * hatStr);
    this.hitRate *= Math.exp(-dt / 1.5);

    // idle heartbeat so the image keeps breathing without music
    const it = this.now;
    const idle = {
      sub: 0.18 + 0.12 * Math.sin(it * 0.6), bass: 0.25 + 0.2 * Math.max(0, Math.sin(it * 0.9)),
      mid: 0.25 + 0.12 * Math.sin(it * 1.3 + 1), high: 0.18 + 0.1 * Math.sin(it * 2.1 + 2)
    };
    idle.level = 0.24 + 0.08 * Math.sin(it * 0.7);
    const im = FA.idle;
    FA.sub = lerp(real.sub, idle.sub, im); FA.bass = lerp(real.bass, idle.bass, im);
    FA.mid = lerp(real.mid, idle.mid, im); FA.high = lerp(real.high, idle.high, im); FA.level = lerp(real.level, idle.level, im);
    {
      const o = outN, rn = { sub: o.sub || 0, bass: (o.bass || 0) * 0.7 + (o.sub || 0) * 0.3, mid: (o.lowMid || 0) * 0.4 + (o.mid || 0) * 0.6, high: (o.high || 0) * 0.6 + (o.air || 0) * 0.4 };
      rn.level = rn.bass * 0.4 + rn.mid * 0.35 + rn.high * 0.25;
      for (const k of ['sub', 'bass', 'mid', 'high', 'level']) FA[k + 'N'] = lerp(rn[k], idle[k], im);
    }
    const prevBeat = Math.floor(FA.beatClock - dt * bpmUse / 60);
    if (silent && Math.floor(FA.beatClock) !== prevBeat) FA.kick = Math.max(FA.kick, 0.32 * im);

    FA.kick *= Math.exp(-dt / 0.14);
    FA.hit *= Math.exp(-dt / 0.12);
    FA.hat *= Math.exp(-dt / 0.08);

    // breakdown / build / drop
    if (this.band && live && !silent) {
      const low = (this.band.sub.raw + this.band.bass.raw) * 0.5;
      this.lowS = ease(this.lowS, low, dt, 0.35);
      this.lowF = ease(this.lowF || 0, low, dt, 0.05);
      this.lowPeak = Math.max(this.lowS, this.lowPeak - dt * 0.004);
      const down = this.lowS < this.lowPeak - 0.09;
      this.bdTime = down ? this.bdTime + dt : Math.max(0, this.bdTime - dt * 4);
      FA.breakdown = ease(FA.breakdown, this.bdTime > 2 ? 1 : 0, dt, 0.8);
      this.dropCool -= dt;
      // Confirm a persistent return; a disconnected low pickup must not consume the drop cooldown.
      const returnEdge=this.bdTime>3&&this.dropCool<=0?this.bassReturn():null;
      if (this.bdTime > 3 && this.lowF > this.lowPeak - 0.07 && this.now - (this.lowOnT || -9) < 0.25 && this.dropCool <= 0 && returnEdge?.present) {
        this.dropReturn=returnEdge;this.bdTime = 0; this.dropCool = 8; FA.onDrop = true;
      }
      const buildTgt = this.bdTime > 2 ? clamp(0.15 + this.hitRate / 10 + real.high * 0.35, 0, 1) * clamp((this.bdTime - 2) / 6, 0, 1) : 0;
      FA.build = ease(FA.build, buildTgt, dt, buildTgt > FA.build ? 0.6 : 0.15);
    } else { FA.build = ease(FA.build, 0, dt, 0.4); FA.breakdown = ease(FA.breakdown, 0, dt, 1); }
    if(FA.onDrop){
      const evidence=this.dropReturn||this.bassReturn();let at=evidence.at;
      const physicalAt=at,deadline=this.now-this.latency();at=Math.max(at,deadline);
      this.dropKickT=at; // a live/no-lookahead or late callback cannot rewrite already delivered history
      // Find the clock at the event, then rebase its queued phase without copying any future spectrum.
      let left=null,right=null;for(const h of FHIST){if(h.t<=at)left=h;else{right=h;break;}}
      const basis=left?(right?lerp(left.beatClock,right.beatClock,(at-left.t)/(right.t-left.t)):left.beatClock+(at-left.t)*bpmUse/60):FA.beatClock-(this.now-at)*bpmUse/60;
      // A new downbeat starts a forward logical epoch beyond every previously exposed/queued clock.
      let priorHigh=Math.max(this.visualClockHigh||0,F.beatClock,FA.beatClock),priorIndex=F.barIndex;
      for(const h of FHIST){priorHigh=Math.max(priorHigh,h.beatClock);if(h.t<at)priorIndex=Math.max(priorIndex,h.barIndex);}
      const anchor=Math.ceil(Math.max(basis,priorHigh)-1e-9),delta=anchor-basis,index=priorIndex+1;
      this.barOffset=((anchor%4)+4)%4;
      for(const h of FHIST)if(h.t>=at){
        const age=h.t-at;h.beatClock=anchor+age*bpmUse/60;h.beat=fract(h.beatClock);h.bar=fract((h.beatClock-this.barOffset)/4);h.barIndex=index;h.onBar=false;
        h.drop=Math.exp(-age/2.2);h.kick=Math.max(h.kick,Math.exp(-age/.14));h.build=0;
      }
      const age=this.now-at;FA.beatClock=anchor+age*bpmUse/60;FA.barIndex=index;FA.onBar=false;
      this.lastBarIdx=Math.floor((FA.beatClock-this.barOffset)/4);this.forceBar=false;this.phist.fill(0);this.phaseT=0;
      FA.drop=Math.exp(-age/2.2);FA.build=0;FA.kick=Math.max(FA.kick,Math.exp(-age/.14));
      DROP_EVENTS.push({t:at,anchor,index});
      CUE.onDrop(at); // v22: a drop is always an impact, and a downbeat
      this.dropAudit={...evidence,recognizedAt:this.now,physicalAt,at,lateBy:Math.max(0,deadline-physicalAt),basis,priorHigh,anchor,delta,index};
    }else FA.drop*=Math.exp(-dt/2.2);

    FA.beat = fract(FA.beatClock);
    const barPos = (FA.beatClock - this.barOffset) / 4;
    const bi = Math.floor(barPos);
    // bars only count forward, so a phase correction pulling the clock back across a bar line cannot double-count
    if (this.forceBar || bi > this.lastBarIdx) { this.forceBar = false; this.lastBarIdx = bi; FA.onBar = true; FA.barIndex++; }
    FA.bar = fract(barPos);
    CUE.frame(dt, live ? this.fS : null, this.ctx ? this.ctx.sampleRate : 48000, this.anaS ? this.anaS.fftSize : 4096, silent); // v22
  },
  estimateTempo() {
    const N = 800, x = this.tmp, ose = this.ose;
    let mean = 0;
    for (let i = 0; i < N; i++) { x[i] = ose[(this.oseI + i) % N]; mean += x[i]; }
    mean /= N;
    let e0 = 0;
    for (let i = 0; i < N; i++) { x[i] -= mean; e0 += x[i] * x[i]; }
    if (e0 < 1e-7) return;
    e0 /= N;
    const ac = (lag) => { let s = 0; for (let i = lag; i < N; i++) s += x[i] * x[i - lag]; return s / (N - lag); };
    const sc = {};
    let best = -1e9, bl = 0;
    for (let lag = 31; lag <= 92; lag++) {
      const bpm = 6000 / lag;
      const prior = Math.exp(-0.5 * Math.pow(Math.log2(bpm / 128) / 0.6, 2));
      const v = (ac(lag) + 0.5 * ac(lag * 2)) * prior;
      sc[lag] = v;
      if (v > best) { best = v; bl = lag; }
    }
    const y0 = sc[bl - 1] !== undefined ? sc[bl - 1] : best, y2 = sc[bl + 1] !== undefined ? sc[bl + 1] : best;
    const den = y0 - 2 * best + y2;
    const lag = bl + (den !== 0 ? clamp(0.5 * (y0 - y2) / den, -0.5, 0.5) : 0);
    const cand = 6000 / lag;
    const conf = clamp((ac(bl) / e0 - 0.08) / 0.35, 0, 1);
    FA.conf = lerp(FA.conf, conf, 0.3);
    if (conf < 0.12) return;
    if (!FA.bpm) { FA.bpm = cand; return; }
    const ratio = cand / FA.bpm;
    if (Math.abs(ratio - 1) < 0.04) { FA.bpm = lerp(FA.bpm, cand, 0.25); this.bpmMiss = 0; }
    else if (Math.abs(ratio - 2) < 0.08 || Math.abs(ratio - 0.5) < 0.04) { this.bpmMiss = 0; }
    else if (++this.bpmMiss >= 3) { FA.bpm = cand; this.bpmMiss = 0; }
  }
};

