/* ============================ audio engine ============================ */
function mulberry(a) { return () => { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }

/* Built-in demo song, synthesised live (song v23): 128 BPM, A minor, 120 bars = 3:45, then it loops without a seam.
   Bars: intro 0 | groove 8 | build 24 | drop 32 | breakdown 48 (F G Em Am colour) | build 56 | drop two 64 (new bass, developed lead) |
   half-time bridge 80 (Dm Am F E) | build 92 | final drop 96 (lifted a tone to B minor) | outro 112 (Bm G Em E7, back home to A minor).
   Cheap to run: the drums are one-shot buffers made once (one node per hit), the synths are a fixed set of always-on voices driven by
   AudioParam automation, the reverb impulse is generated once, and nothing runs per sample in JavaScript while it plays. */
function createDemo(ctx) {
  const SR = ctx.sampleRate, BPM = 128, S16 = 60 / BPM / 4, BARS = 120, TAU = Math.PI * 2, SWING = S16 * 0.13;
  const NOTE = (m) => 440 * Math.pow(2, (m - 69) / 12); // equal temperament from MIDI note numbers
  const MIX = { master: 0.28, kick: 1.0, sub: 0.36, bass: 0.36, snare: 0.85, clap: 0.65, hat: 1.2, pad: 0.16, stab: 0.35, lead: 0.25, pluck: 0.67, fx: 0.55, rev: 0.9, dly: 0.7 };

  /* ---- one-time assets: drum hits, noise, reverb impulse (kept on the context, so a restart makes nothing again) ---- */
  const A = ctx._demo23 || (ctx._demo23 = (function () {
    const rnd = mulberry(23023), nz = () => rnd() * 2 - 1;
    const arr = (sec) => new Float32Array(Math.ceil(sec * SR));
    const noise = (sec) => { const x = arr(sec); for (let i = 0; i < x.length; i++) x[i] = nz(); return x; };
    const filt = (x, type, f, q) => { // biquad in place: 0 low-pass, 1 high-pass, 2 band-pass
      const w = TAU * Math.min(f, SR * 0.45) / SR, c = Math.cos(w), al = Math.sin(w) / (2 * q), a0 = 1 + al, a1 = -2 * c / a0, a2 = (1 - al) / a0;
      const b0 = (type === 0 ? (1 - c) / 2 : type === 1 ? (1 + c) / 2 : al) / a0, b1 = (type === 0 ? 1 - c : type === 1 ? -(1 + c) : 0) / a0, b2 = type === 2 ? -b0 : b0;
      let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
      for (let i = 0; i < x.length; i++) { const v = x[i], y = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2; x2 = x1; x1 = v; y2 = y1; y1 = y; x[i] = y; }
      return x;
    };
    const shape = (x, env, peak) => { // times an envelope, the last 12 ms faded to zero, normalised to a peak
      const n = x.length, f = Math.floor(0.012 * SR); let m = 1e-9;
      for (let i = 0; i < n; i++) { x[i] *= env(i / SR) * (i > n - f ? (n - i) / f : 1); m = Math.max(m, Math.abs(x[i])); }
      for (let i = 0; i < n; i++) x[i] *= peak / m;
      return x;
    };
    const one = () => 1;
    const buf = (chs) => { const b = ctx.createBuffer(chs.length, chs[0].length, SR); chs.forEach((c, i) => b.getChannelData(i).set(c)); return b; };
    // kick: sine with a fast pitch drop (click, knock, then a 47 Hz body), driven a little, plus a 3 ms noise click
    const k = arr(0.4), kc = filt(noise(0.03), 1, 3000, 0.7);
    for (let i = 0, ph = 0; i < k.length; i++) {
      const t = i / SR; ph += TAU * (47 + 115 * Math.exp(-t / 0.032) + 230 * Math.exp(-t / 0.005)) / SR;
      k[i] = Math.tanh(1.8 * Math.sin(ph) * Math.min(1, t / 0.0012) * Math.exp(-t / 0.095)) + (i < kc.length ? 0.28 * kc[i] * Math.exp(-t / 0.003) : 0);
    }
    shape(k, one, 1);
    // snare: high-passed noise with a short tail over a pitched body
    const sn = filt(noise(0.3), 1, 1500, 0.7);
    for (let i = 0, ph = 0; i < sn.length; i++) { const t = i / SR; ph += TAU * (176 + 120 * Math.exp(-t / 0.012)) / SR; sn[i] = 0.75 * sn[i] * Math.exp(-t / 0.085) + 0.9 * Math.sin(ph) * Math.exp(-t / 0.05); }
    shape(sn, one, 1);
    // clap: band-passed noise, three quick bursts then a tail
    const cl = shape(filt(filt(noise(0.34), 2, 1300, 1.3), 1, 700, 0.7), (t) => (t < 0.031 ? Math.exp(-(t % 0.0105) / 0.0035) : Math.exp(-(t - 0.031) / 0.07)), 1);
    // hats and crash: stereo (two independent noise channels), steep high-pass
    const hat = (sec, f, tau) => [0, 1].map(() => shape(filt(filt(noise(sec), 1, f, 0.8), 1, f, 0.8), (t) => Math.exp(-t / tau) * Math.min(1, t / 0.0004), 1));
    const cr = [0, 1].map(() => { const x = noise(2.4), y = filt(x.slice(), 2, 5600, 3); filt(x, 1, 3200, 0.7); for (let i = 0; i < x.length; i++) x[i] += 2.5 * y[i]; return shape(x, (t) => Math.min(1, t / 0.002) * (0.35 * Math.exp(-t / 0.12) + 0.65 * Math.exp(-t / 0.62)), 1); });
    const rn = Math.floor(8 * S16 * SR); // reverse crash: half a bar long, ends on the line it is placed against
    const rc = cr.map((c) => { const x = new Float32Array(rn); for (let i = 0; i < rn; i++) x[i] = c[rn - 1 - i] * Math.pow(i / rn, 1.5); return shape(x, one, 1); });
    // impact boom for the drops: a falling sub sine with a thump of low noise
    const bm = filt(noise(1.5), 0, 260, 0.7);
    for (let i = 0, ph = 0; i < bm.length; i++) { const t = i / SR; ph += TAU * (36 + 50 * Math.exp(-t / 0.08)) / SR; bm[i] = 6 * bm[i] * Math.exp(-t / 0.1) + Math.tanh(1.6 * Math.sin(ph) * Math.min(1, t / 0.002) * Math.exp(-t / 0.4)); }
    shape(bm, one, 1);
    // reverb impulse: 2.2 s of decaying noise that darkens as it decays, 12 ms pre-delay, no low end
    const ir = [0, 1].map(() => {
      const x = arr(2.2), pre = Math.floor(0.012 * SR);
      for (let i = pre, lp = 0; i < x.length; i++) { const t = (i - pre) / SR; lp += (0.1 + 0.7 * Math.exp(-t / 0.4)) * (nz() - lp); x[i] = lp * Math.exp(-t / 0.36); }
      return shape(filt(x, 1, 260, 0.7), one, 1);
    });
    return { kick: buf([k]), snare: buf([sn]), clap: buf([cl]), hatC: buf(hat(0.09, 7600, 0.014)), hatO: buf(hat(0.4, 6200, 0.085)), crash: buf(cr), rcrash: buf(rc), boom: buf([bm]), noise: buf([noise(2)]), ir: buf(ir) };
  })());

  /* ---- the fixed graph ---- */
  const keep = []; // every long-lived node, for stop()
  const N = (n) => { keep.push(n); return n; };
  const G = (v, to) => { const g = N(ctx.createGain()); g.gain.value = v; if (to) g.connect(to); return g; };
  const BQ = (type, f, q, to) => { const b = N(ctx.createBiquadFilter()); b.type = type; b.frequency.value = f; b.Q.value = q; if (to) b.connect(to); return b; };
  const PAN = (p, to) => { if (!ctx.createStereoPanner) return G(1, to); const n = N(ctx.createStereoPanner()); n.pan.value = p; n.connect(to); return n; };
  const OSC = (type, to, cents) => { const o = N(ctx.createOscillator()); o.type = type; o.detune.value = cents || 0; o.connect(to); o.start(); return o; };
  const COMP = (thr, knee, ratio, att, rel, to) => { const c = N(ctx.createDynamicsCompressor()); c.threshold.value = thr; c.knee.value = knee; c.ratio.value = ratio; c.attack.value = att; c.release.value = rel; c.connect(to); return c; };
  // master: rumble filter, a small cut around 3 kHz, a soft roll-off above 11 kHz, gentle glue compression, a limiter, a soft ceiling
  const out = G(0.94);
  const clip = N(ctx.createWaveShaper()), cv = new Float32Array(4097);
  for (let i = 0; i < 4097; i++) { const x = i / 2048 - 1, a = Math.abs(x); cv[i] = Math.sign(x) * (a < 0.6 ? a : 0.6 + 0.25 * Math.tanh((a - 0.6) / 0.25)); }
  clip.curve = cv; clip.connect(BQ('highpass', 18, 0.7, out)); // (the last filter removes the small DC the ceiling can leave)
  const lim = COMP(-3, 0, 20, 0.002, 0.09, clip), glue = COMP(-12, 6, 1.6, 0.02, 0.22, lim);
  const shelf = BQ('highshelf', 11000, 0.7, glue); shelf.gain.value = -3;
  const pres = BQ('peaking', 3200, 0.8, shelf); pres.gain.value = -1.5;
  const master = G(MIX.master, BQ('highpass', 24, 0.7, pres));
  const drums = G(1, master), duckB = G(1, master), duckM = G(1, master), fxDry = G(1, master);
  // reverb and a filtered ping-pong delay (three sixteenths), both returned through the ducked music bus so the kick stays clear
  const revIn = G(1), conv = N(ctx.createConvolver()); conv.buffer = A.ir; revIn.connect(conv); conv.connect(G(MIX.rev, duckM));
  const dIn = G(1), dL = N(ctx.createDelay(1)), dR = N(ctx.createDelay(1)), dOut = G(MIX.dly, duckM), dTap = BQ('highpass', 350, 0.5);
  dL.delayTime.value = dR.delayTime.value = S16 * 3;
  dIn.connect(dL); dL.connect(BQ('lowpass', 3400, 0.5, dTap)); dTap.connect(PAN(-0.65, dOut)); dTap.connect(G(0.6, dR)); dR.connect(PAN(0.65, dOut)); dR.connect(G(0.5, dL));
  dOut.connect(G(0.2, revIn)); // a little of the echoes into the reverb
  // drum buses: a ladder of fixed gains per drum, so a hit is a single buffer source
  const ladder = (level, to, n) => { const a = []; for (let i = 0; i < n; i++) a.push(G(level * Math.pow(0.78, i), to)); return a; };
  const snBus = G(1, drums), fxBus = G(1, fxDry); snBus.connect(G(0.16, revIn)); fxBus.connect(G(0.3, revIn));
  const kickV = ladder(MIX.kick, drums, 8), snV = ladder(MIX.snare, snBus, 8), clV = ladder(MIX.clap, snBus, 6), hatV = ladder(MIX.hat, drums, 9), fxV = ladder(MIX.fx, fxBus, 6);
  // sub (sine) and mid bass (saw + square through a resonant low-pass with a filter envelope)
  const subG = G(0, duckB), subO = OSC('sine', subG);
  const bassG = G(0, BQ('highpass', 85, 0.7, duckB)), bassF = BQ('lowpass', 400, 3.5, bassG), bassO = [OSC('sawtooth', bassF, -5), OSC('square', G(0.45, bassF), 5)];
  // pad: four notes, two detuned saws each, left and right; the same oscillators feed the chord stabs through their own filter
  const padSum = G(1), padL = PAN(-0.55, padSum), padR = PAN(0.55, padSum), padO = [];
  for (let i = 0; i < 4; i++) { padO.push(OSC('sawtooth', padL, -9 + i)); padO.push(OSC('sawtooth', padR, 9 - i)); }
  const padG = G(0, duckM), padF = BQ('lowpass', 800, 0.8, padG), padLfo = G(450); padSum.connect(padF); padG.connect(G(0.5, revIn));
  padLfo.connect(padF.detune); OSC('sine', padLfo).frequency.value = 0.09; // slow filter movement, no scheduling needed
  const stabG = G(0, duckM), stabF = BQ('lowpass', 500, 2.5, stabG); padSum.connect(stabF); stabG.connect(G(0.35, dIn)); stabG.connect(G(0.3, revIn));
  // lead: two detuned saws and a square an octave down, low-pass with an envelope, vibrato that comes in on long notes, glide
  const leadG = G(0, duckM), leadF = BQ('lowpass', 2000, 1.2, leadG), vib = G(0);
  const leadO = [OSC('sawtooth', leadF, -7), OSC('sawtooth', leadF, 7), OSC('square', G(0.3, leadF), 0)];
  OSC('sine', vib).frequency.value = 5.6; leadO.forEach((o) => vib.connect(o.detune)); leadG.connect(G(0.4, dIn)); leadG.connect(G(0.35, revIn));
  // two pluck voices (arpeggio, and melody / answers)
  const pluckVoice = (dly, rev) => { const p = PAN(0, duckM), g = G(0, p), f = BQ('lowpass', 800, 2, g); g.connect(G(dly, dIn)); g.connect(G(rev, revIn)); return { p, g, f, o: [OSC('sawtooth', f, -4), OSC('square', G(0.4, f), 4)] }; };
  const P1 = pluckVoice(0.45, 0.2), P2 = pluckVoice(0.5, 0.4);

  /* ---- instruments ---- */
  let TR = 0; // transposition of the current bar in semitones
  function done() { this.disconnect(); if (this._n) for (let i = 0; i < this._n.length; i++) this._n[i].disconnect(); }
  function hit(b, t, v, bus, rate) {
    const s = ctx.createBufferSource(); s.buffer = b; if (rate) s.playbackRate.value = rate;
    s.connect(bus[v >= 1 ? 0 : Math.min(bus.length - 1, Math.round(Math.log(Math.max(v, 0.02)) / Math.log(0.78)))]); s.onended = done; s.start(t);
  }
  function kick(t, v) { // with the sidechain: bass and music buses dip under every kick and recover before the next
    hit(A.kick, t, v, kickV);
    duckB.gain.setTargetAtTime(1 - 0.8 * v, t - 0.006, 0.004); duckB.gain.setTargetAtTime(1, t + 0.075, 0.055);
    duckM.gain.setTargetAtTime(1 - 0.55 * v, t - 0.006, 0.005); duckM.gain.setTargetAtTime(1, t + 0.085, 0.085);
  }
  function bassNote(t, m, len, v, cut) {
    const d = len * S16, f = NOTE(m + 12); let sm = m; while (sm > 39) sm -= 12; while (sm < 28) sm += 12; // the sub stays in its octave
    subO.frequency.setValueAtTime(NOTE(sm), t); subG.gain.setTargetAtTime(MIX.sub * v, t, 0.005); subG.gain.setTargetAtTime(0, t + d - 0.014, 0.012);
    bassO[0].frequency.setValueAtTime(f, t); bassO[1].frequency.setValueAtTime(f, t);
    bassF.frequency.setTargetAtTime(cut * 3.2, t, 0.003); bassF.frequency.setTargetAtTime(cut, t + 0.015, 0.045);
    bassG.gain.setTargetAtTime(MIX.bass * v, t, 0.004); bassG.gain.setTargetAtTime(0, t + d - 0.014, 0.012);
  }
  function leadNote(t, m, len, v, glide) {
    const d = len * S16, f = NOTE(m + TR);
    for (let i = 0; i < 3; i++) { const p = leadO[i].frequency, fi = i === 2 ? f / 2 : f; if (glide) p.setTargetAtTime(fi, t, 0.028); else p.setValueAtTime(fi, t); }
    leadF.frequency.setTargetAtTime(Math.min(9500, f * 7), t, 0.006); leadF.frequency.setTargetAtTime(f * 3, t + 0.04, 0.25);
    leadG.gain.setTargetAtTime(MIX.lead * v, t, 0.008); leadG.gain.setTargetAtTime(0, t + d - 0.022, 0.035);
    vib.gain.setTargetAtTime(0, t, 0.02); if (len >= 4) vib.gain.setTargetAtTime(15, t + 0.2, 0.2);
  }
  function pluckNote(P, t, m, v, bright, dec, pan) {
    const f = NOTE(m + TR);
    P.o[0].frequency.setValueAtTime(f, t); P.o[1].frequency.setValueAtTime(f, t); if (P.p.pan) P.p.pan.setValueAtTime(pan, t);
    P.f.frequency.setTargetAtTime(Math.min(10000, f * bright), t, 0.002); P.f.frequency.setTargetAtTime(f * 1.2, t + 0.01, dec * 0.6);
    P.g.gain.setTargetAtTime(MIX.pluck * v, t, 0.003); P.g.gain.setTargetAtTime(0, t + 0.012, dec);
  }
  function stab(t, v, bright, dec) {
    stabF.frequency.setTargetAtTime(bright, t, 0.003); stabF.frequency.setTargetAtTime(420, t + 0.015, dec * 0.7);
    stabG.gain.setTargetAtTime(MIX.stab * v, t, 0.004); stabG.gain.setTargetAtTime(0, t + 0.02, dec);
  }
  function sweep(t, d, lvl, up) { // riser (band-passed noise sweeping up, swelling) or downlifter (low-passed noise falling away)
    const s = ctx.createBufferSource(), f = ctx.createBiquadFilter(), g = ctx.createGain(); s.buffer = A.noise; s.loop = true;
    if (up) {
      f.type = 'bandpass'; f.Q.value = 0.8; f.frequency.setValueAtTime(450, t); f.frequency.exponentialRampToValueAtTime(9000, t + d);
      g.gain.setValueAtTime(lvl * MIX.fx * 0.01, t); g.gain.exponentialRampToValueAtTime(lvl * MIX.fx, t + d); g.gain.setTargetAtTime(0, t + d, 0.012); // a steady climb in dB
    } else {
      f.type = 'lowpass'; f.Q.value = 0.9; f.frequency.setValueAtTime(9000, t); f.frequency.exponentialRampToValueAtTime(220, t + d);
      g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(lvl * MIX.fx * 0.5, t + 0.02); g.gain.linearRampToValueAtTime(0.0001, t + d);
    }
    s.connect(f); f.connect(g); g.connect(fxBus); s._n = [f, g]; s.onended = done; s.start(t, 0.3); s.stop(t + d + 0.12);
  }

  /* ---- the song ---- */
  // chords: bass root, then four pad notes voiced so each part moves by step where it can
  const CH = {
    Am7: [33, 55, 60, 64, 69], Fmaj7: [29, 57, 60, 64, 69], C: [36, 55, 60, 64, 67], G: [31, 55, 59, 62, 67], Em: [28, 55, 59, 64, 67],
    E: [28, 56, 59, 64, 68], E7: [28, 56, 59, 62, 64], Esus: [28, 57, 59, 62, 64], F: [29, 53, 57, 60, 65], Dm: [38, 53, 57, 62, 65],
    Fmaj9: [29, 57, 60, 64, 67], G6: [31, 59, 62, 64, 67], Em7: [28, 55, 59, 62, 64], Am9: [33, 55, 59, 60, 64], Dm9: [38, 53, 57, 60, 64],
    Fs: [30, 54, 58, 61, 66], Fs7: [30, 52, 58, 61, 66], Bm7: [35, 57, 62, 66, 71], Gmaj7: [31, 59, 62, 66, 71]
  };
  const PA = ['Am7', 'Fmaj7', 'C', 'G', 'Am7', 'Fmaj7', 'C', 'Em'];
  const PROG = [].concat(PA, PA, PA, ['F', 'F', 'G', 'G', 'Am7', 'Am7', 'E', 'E7'], PA, PA, ['Fmaj9', 'G6', 'Em7', 'Am9', 'Fmaj9', 'G6', 'C', 'Esus'], ['Am9', 'Am9', 'Fmaj9', 'Fmaj9', 'G6', 'G6', 'E', 'E7'],
    PA, PA, ['Dm9', 'Am7', 'Fmaj7', 'E', 'Dm9', 'Am7', 'Fmaj7', 'E', 'Dm9', 'Am7', 'Fmaj7', 'G'], ['G', 'G', 'Fs', 'Fs7'], PA, PA, ['Bm7', 'Gmaj7', 'Bm7', 'Gmaj7', 'Em7', 'Em7', 'Esus', 'E7']);
  const SEC0 = [0, 8, 24, 32, 48, 56, 64, 80, 92, 96, 112];
  const secOf = (b) => { let i = 10; while (b < SEC0[i]) i--; return i; };
  // melodies, one array per bar: step, note, length in sixteenths
  const LEAD_A = [[0, 76, 3, 3, 74, 3, 6, 72, 2, 8, 69, 3, 11, 72, 3, 14, 74, 2], [0, 76, 6, 6, 79, 2, 8, 76, 4, 12, 74, 2, 14, 72, 2], [0, 76, 3, 3, 74, 3, 6, 72, 2, 8, 67, 3, 11, 72, 3, 14, 76, 2], [0, 74, 8, 8, 71, 4, 12, 69, 2, 14, 71, 2],
    [0, 76, 3, 3, 74, 3, 6, 72, 2, 8, 69, 3, 11, 72, 3, 14, 76, 2], [0, 81, 6, 6, 79, 2, 8, 76, 4, 12, 77, 2, 14, 76, 2], [0, 79, 3, 3, 76, 3, 6, 74, 2, 8, 72, 3, 11, 74, 3, 14, 76, 2], [0, 71, 10, 12, 74, 2, 14, 71, 2]];
  const LEAD_B = [[0, 76, 3, 3, 74, 3, 6, 72, 2, 8, 76, 2, 10, 79, 2, 12, 81, 4], [0, 84, 4, 4, 81, 2, 6, 79, 2, 8, 81, 6, 14, 79, 2], [0, 79, 3, 3, 76, 3, 6, 72, 2, 8, 79, 2, 10, 81, 2, 12, 83, 2, 14, 84, 2], [0, 86, 6, 6, 83, 2, 8, 79, 4, 12, 74, 2, 14, 79, 2],
    [0, 76, 3, 3, 74, 3, 6, 72, 2, 8, 76, 2, 10, 79, 2, 12, 81, 4], [0, 84, 4, 4, 81, 2, 6, 79, 2, 8, 77, 4, 12, 76, 2, 14, 72, 2], [0, 79, 3, 3, 76, 3, 6, 79, 2, 8, 84, 4, 12, 83, 2, 14, 79, 2], [0, 83, 8, 8, 79, 2, 10, 76, 2, 12, 71, 4]];
  const LEAD_C = [[0, 77, 6, 6, 76, 2, 8, 74, 6, 14, 72, 2], [0, 76, 8, 8, 72, 4, 12, 69, 4], [0, 69, 4, 4, 72, 4, 8, 77, 6, 14, 76, 2], [0, 76, 6, 6, 74, 2, 8, 71, 4, 12, 68, 4],
    [0, 77, 6, 6, 81, 2, 8, 79, 4, 12, 77, 2, 14, 76, 2], [0, 76, 6, 6, 79, 2, 8, 81, 8], [0, 84, 6, 6, 81, 2, 8, 79, 4, 12, 77, 4], [0, 76, 8, 8, 80, 4, 12, 83, 4],
    [0, 81, 6, 6, 77, 2, 8, 74, 8], [0, 72, 6, 6, 76, 2, 8, 81, 8], [0, 84, 8, 8, 81, 4, 12, 79, 4], [0, 79, 6, 6, 83, 2, 8, 86, 8]];
  const BRK = [[0, 72, 3, 3, 76, 3, 6, 79, 4, 10, 76, 4, 14, 74, 2], [0, 74, 3, 3, 71, 3, 6, 79, 4, 10, 74, 4, 14, 76, 2], [0, 76, 3, 3, 71, 3, 6, 79, 4, 10, 83, 4, 14, 79, 2], [0, 76, 3, 3, 72, 3, 6, 71, 2, 8, 69, 4, 12, 72, 4],
    [0, 72, 3, 3, 76, 3, 6, 79, 4, 10, 76, 4, 14, 79, 2], [0, 83, 3, 3, 79, 3, 6, 74, 4, 10, 79, 4, 14, 81, 2], [0, 84, 3, 3, 79, 3, 6, 76, 4, 10, 72, 4, 14, 76, 2], [0, 76, 4, 4, 74, 4, 8, 71, 4, 12, 69, 4]];
  const BRKL = [[0, 72, 14], [0, 74, 14], [0, 76, 8, 8, 79, 8], [0, 76, 12]];
  // arpeggio patterns: index into the chord's pad notes (4..7 = an octave up), -1 = rest
  const ARP1 = [0, 2, 3, 4, 2, 3, 4, 6, 3, 4, 6, 7, 6, 4, 3, 2], ARP2 = [4, 3, 2, 0, 5, 4, 3, 1, 6, 5, 4, 2, 7, 6, 4, 3], ARP3 = [0, -1, 2, -1, 3, -1, 4, -1, 2, -1, 3, -1, 4, -1, 6, -1];
  // bass patterns: step, semitones above the root (99 = a passing note into the next bar's root), length, velocity
  const BG = [2, 0, 2, 1, 6, 0, 2, 1, 10, 0, 2, 1, 14, 0, 2, 1], BGf = [2, 0, 2, 1, 6, 0, 2, 1, 10, 0, 1, 1, 11, 12, 1, 0.8, 14, 0, 1, 1, 15, 99, 1, 0.9];
  const BD1 = [2, 0, 1.5, 1, 6, 0, 1, 1, 7, 12, 1, 0.8, 10, 0, 1.5, 1, 13, 0, 1, 0.85, 14, 12, 1, 0.8, 15, 0, 1, 0.9], BD1f = [2, 0, 1.5, 1, 6, 0, 1, 1, 7, 12, 1, 0.8, 10, 0, 1, 1, 11, 7, 1, 0.8, 13, 0, 1, 0.85, 14, 12, 1, 0.8, 15, 99, 1, 0.9];
  const BD2 = [2, 0, 1, 1, 3, 12, 1, 0.8, 6, 0, 1, 1, 7, 12, 1, 0.8, 10, 0, 1, 1, 11, 12, 1, 0.8, 14, 0, 1, 1, 15, 7, 1, 0.8], BD2f = [2, 0, 1, 1, 3, 12, 1, 0.8, 6, 0, 1, 1, 7, 12, 1, 0.8, 10, 0, 1, 1, 11, 12, 1, 0.8, 13, 7, 1, 0.8, 14, 12, 1, 0.8, 15, 99, 1, 0.9];
  const BD3 = [1, 0, 1, 0.8, 2, 0, 1, 1, 3, 12, 1, 0.8, 6, 0, 1, 1, 7, 12, 1, 0.8, 9, 0, 1, 0.8, 10, 0, 1, 1, 11, 12, 1, 0.8, 14, 7, 1, 0.9, 15, 12, 1, 0.8];
  const BH = [0, 0, 6, 1, 10, 0, 5, 1], BHb = [0, 0, 5, 1, 7, 0, 2, 0.9, 10, 0, 4, 1, 14, 7, 2, 0.8], BB = [0, 0, 15, 0.75];
  const HV = [0.55, 0.3, 1, 0.38], PADL = [0.9, 0.55, 0.8, 0.7, 0.65, 0.8, 0.7, 0.8, 0.9, 0.8, 0.7], SECL = [0.8, 0.82, 0, 1, 0.8, 0, 1, 0.8, 0, 1.06, 0.8], STAB1 = [3, 6, 11, 14], STAB2 = [0, 3, 6], STAB3 = [0, 3, 6, 11, 14];
  const rj = mulberry(77);

  function barSetup(sec, sb, ch, t) { // chord for the pad and stabs, pad level and filter for this bar
    for (let i = 0; i < 4; i++) { const f = NOTE(ch[i + 1] + TR); padO[2 * i].frequency.setValueAtTime(f, t); padO[2 * i + 1].frequency.setValueAtTime(f, t); }
    const up = (a, b, n) => a * Math.pow(b / a, sb / n);
    const cut = sec === 0 ? up(500, 1500, 8) : sec === 1 ? (sb < 8 ? 1400 : 1900) : sec === 2 ? up(900, 5000, 7) : sec === 3 ? 2600 : sec === 4 ? 1700 : sec === 5 ? up(1000, 5500, 7) : sec === 6 ? 2900 : sec === 7 ? 1400 : sec === 8 ? up(1400, 5500, 3) : sec === 9 ? 3400 : up(2200, 500, 8);
    padF.frequency.setTargetAtTime(cut, t, 0.4); padG.gain.setTargetAtTime(MIX.pad * PADL[sec], t, sb ? 0.15 : 0.06);
    // the mix fader: sections sit at their own level, builds swell into the drops
    master.gain.setTargetAtTime(MIX.master * (sec === 2 || sec === 5 ? 0.72 + 0.04 * sb : sec === 8 ? 0.76 + 0.08 * sb : SECL[sec]), t - 0.03, sb ? 0.05 : 0.01);
  }
  function step(n, t, fresh) {
    const bar = Math.floor(n / 16) % BARS, s = n % 16, sub = s & 3, sec = secOf(bar), sb = bar - SEC0[sec], ch = CH[PROG[bar]];
    const b4 = sb % 4, b8 = sb % 8, last4 = b4 === 3, last8 = b8 === 7, sw = (s & 1) ? SWING : 0, jit = 0.85 + 0.3 * rj();
    TR = sec === 9 ? 2 : 0;
    if (s === 0 || fresh) barSetup(sec, sb, ch, t);
    const snare = (v, r) => hit(A.snare, t, v, snV, r), clap = (v) => hit(A.clap, t, v, clV), crash = (v) => hit(A.crash, t, v, fxV), rcrash = (v) => hit(A.rcrash, t, v, fxV);
    const hats = (dens, lvl, open) => { // 1: off-beat eighths, 2: eighths, 3: sixteenths; open hats take the off-beats
      if (open && sub === 2) hit(A.hatO, t, lvl * 0.75 * jit, hatV);
      else if (dens === 1 ? sub === 2 : dens === 2 ? !(s & 1) : true) hit(A.hatC, t + sw, lvl * HV[sub] * jit, hatV, 0.95 + 0.12 * rj());
    };
    const four = (v, fill) => { // kick on every beat; a fill bar gives its last beat (or last two) to a snare run
      if (sub === 0 && !(fill && s >= (fill > 1 ? 8 : 12))) kick(t, v);
      if (fill && s >= 10) { const f = [0.35, 0, 0.5, 0.45, 0.7, 0.9][s - 10]; if (f) snare(f, 1 + (s - 10) * 0.03); }
    };
    const back = (v, layered) => { if (s === 4 || s === 12) { clap(v); if (layered) snare(v * 0.8, 1); } };
    const roll = (k) => { // four bars with no kick and no bass: snare in quarters, eighths, sixteenths, thirty-seconds, then a beat of air before the drop
      const p = (k * 16 + s) / 64, v = 0.22 + 0.7 * p, r = 0.9 + 0.45 * p;
      if (k === 3 && s >= 12) { if (s === 12) padG.gain.setTargetAtTime(0, t, 0.03); return; }
      if (k === 0 ? sub === 0 : k === 1 ? !(s & 1) : true) snare(v, r);
      if (k === 3 && s >= 8) hit(A.snare, t + S16 / 2, v, snV, r);
      if (k === 3 && s === 4) rcrash(0.6);
    };
    const impact = () => { hit(A.boom, t, 0.8, fxV); crash(0.95); sweep(t, 12 * S16, 0.6, false); };
    const arp = (pat, v, bright, dec) => { const i = pat[s]; if (i >= 0) pluckNote(P1, t, ch[1 + (i & 3)] + (i > 3 ? 12 : 0), v * (sub === 0 ? 1 : 0.78), bright, dec, (s & 2) ? 0.35 : -0.35); };
    const mel = (tbl, b, fn) => { const a = tbl[b]; for (let i = 0; i < a.length; i += 3) if (a[i] === s) fn(a[i + 1], a[i + 2]); };
    const bassPat = (pat, cut, v) => {
      for (let i = 0; i < pat.length; i += 4) if (pat[i] === s) {
        let m = ch[0] + TR + pat[i + 1];
        if (pat[i + 1] === 99) { const nb = (bar + 1) % BARS, r = CH[PROG[nb]][0], pc = r % 12; m = r + (secOf(nb) === 9 ? 2 : 0) - (pc === 5 || pc === 0 ? 1 : 2); }
        bassNote(t, m, pat[i + 2], v * pat[i + 3], cut);
      }
    };
    const lead = (m, len) => leadNote(t, m, len, 1, false);
    if (sec === 0) { // intro: pad and arpeggio open up, a soft kick and bass fade in from the first bar, hats from the fifth
      if (sb === 0 && s === 0) crash(0.35);
      arp(ARP3, 0.5 + 0.06 * sb, 3 + 0.5 * sb, 0.11); four(0.2 + 0.06 * sb, sb === 7);
      bassPat(BG, 200 + 10 * sb, 0.25 + 0.08 * sb);
      if (sb >= 4) { hats(1, 0.55, false); if (sb === 7 && s === 8) rcrash(0.45); }
    } else if (sec === 1) { // groove: off-beat bass, arpeggio, the motif is first heard on a pluck
      if (b8 === 0 && s === 0) crash(sb ? 0.45 : 0.6);
      four(0.85, last8); back(0.7, false); hats(sb < 4 ? 1 : 3, 0.7, sb >= 8);
      bassPat(last4 ? BGf : BG, 320, 1); arp(sb < 8 ? ARP3 : ARP1, 0.7, 5.5 + 2.5 * (b8 / 7), 0.1);
      if (sb >= 8) mel(LEAD_A, b8, (m) => pluckNote(P2, t, m, 0.8, 5, 0.16, 0));
      if (last8 && s === 8) rcrash(0.45);
    } else if (sec === 2) { // first build: riser, the bass thins out, snare roll, a beat of air
      if (sb === 0 && s === 0) sweep(t, 124 * S16, 2, true);
      if (sb < 4) { four(0.82, false); back(0.6, false); hats(3, 0.6, false); bassPat(BG, 300 + 60 * sb, 0.9); } else roll(sb - 4);
      if (!(sb === 7 && s >= 12)) arp(ARP1, 0.6 + 0.05 * sb, 4 + sb, 0.09);
    } else if (sec === 3) { // first drop: the lead motif, then stabs and the sixteenth arpeggio join
      if (s === 0) { if (sb === 0) impact(); else if (b8 === 0) crash(0.55); }
      four(1, last8); back(0.9, true); hats(3, 0.8, true);
      bassPat(last4 ? BD1f : BD1, 520, 1); mel(LEAD_A, b8, lead);
      if (sb >= 8) { arp(b4 < 2 ? ARP1 : ARP2, 0.6, 6, 0.08); if (STAB1.indexOf(s) >= 0) stab(t, 0.9, 3200, 0.11); } else arp(ARP3, 0.5, 5, 0.1);
      if (last8 && s === 8) rcrash(0.5);
    } else if (sec === 4) { // breakdown: another chord colour, a bell-like melody, the lead answers in long notes
      if (sb === 0 && s === 0) { crash(0.6); sweep(t, 32 * S16, 0.6, false); }
      bassPat(BB, 200, 0.8); mel(BRK, sb, (m) => pluckNote(P2, t, m, 0.6, 6, 0.28, (s & 2) ? 0.25 : -0.25));
      if (sb >= 4) { mel(BRKL, sb - 4, (m, len) => leadNote(t, m, len, 0.45, true)); hats(1, 0.4, false); arp(ARP3, 0.25, 3, 0.12); if (s === 12) snare(0.3, 0.85); }
    } else if (sec === 5) { // second build: comes up out of the breakdown, claps and hats first, then the roll
      if (sb === 0 && s === 0) sweep(t, 124 * S16, 2, true);
      if (sb < 4) { bassPat(BB, 220, 0.8); hats(2, 0.3 + 0.1 * sb, false); back(0.4 + 0.1 * sb, false); mel(BRK, sb, (m) => pluckNote(P2, t, m, 0.7, 6, 0.2, 0)); } else roll(sb - 4);
      if (!(sb === 7 && s >= 12)) arp(ARP2, 0.5 + 0.06 * sb, 3 + sb, 0.09);
    } else if (sec === 6) { // second drop: bass in off-beat pairs with the octave, the lead developed and an octave higher in places
      if (s === 0) { if (sb === 0) impact(); else if (b8 === 0) crash(0.55); }
      four(1, last8 ? (sb === 7 ? 2 : 1) : 0); back(0.9, true); hats(3, 0.8, true); if (s & 1) hit(A.hatC, t + sw, 0.22 * jit, hatV, 1.45);
      bassPat(last4 ? BD2f : BD2, 430 + 30 * sb, 1); mel(LEAD_B, b8, lead);
      if ((sb < 8 ? STAB2 : STAB3).indexOf(s) >= 0) stab(t, 0.9, 3600, 0.11);
      if (sb >= 8) arp(ARP2, 0.6, 7, 0.08);
      if (last8 && s === 8) rcrash(0.5);
    } else if (sec === 7) { // bridge: half-time, the lead sings with glide, sparse arpeggio
      const odd = sb & 1;
      if (sb === 0 && s === 0) { crash(0.6); sweep(t, 16 * S16, 0.5, false); }
      if (s === 0 || s === 10 || (odd && s === 7)) kick(t, 0.9);
      if (s === 8) { snare(0.9, 0.92); clap(0.7); }
      if (odd && s === 15) snare(0.3, 1.1);
      if (odd && s === 14) hit(A.hatO, t, 0.5, hatV); else hats(2, 0.6, false);
      if (last4 && s >= 12) hit(A.hatC, t + S16 / 2, 0.3 + 0.05 * (s - 12), hatV, 1.1);
      bassPat(odd ? BHb : BH, 260, 1); mel(LEAD_C, sb, (m, len) => leadNote(t, m, len, 0.85, true));
      arp(ARP3, 0.4, 4, 0.12); if (sb >= 8) pluckNote(P2, t, ch[1 + (ARP2[s] & 3)] + 12, 0.25 + 0.04 * (sb - 8), 4 + (sb - 8), 0.07, (s & 2) ? -0.4 : 0.4);
    } else if (sec === 8) { // third build, four bars, turning to the dominant of B minor
      if (sb === 0 && s === 0) sweep(t, 60 * S16, 2, true);
      roll(sb); if (!(sb === 3 && s >= 12)) arp(ARP1, 0.6 + 0.1 * sb, 5 + 1.5 * sb, 0.08);
    } else if (sec === 9) { // final drop, a tone higher: everything, the lead doubled an octave up, both lead phrases in turn
      if (s === 0) { if (sb === 0) impact(); else if (b8 === 0) crash(0.6); }
      four(1, last8 ? (sb === 7 ? 2 : 1) : 0); back(0.95, true); hats(3, 0.85, true); if (s & 1) hit(A.hatC, t + sw, 0.22 * jit, hatV, 1.45);
      bassPat(last4 ? BD2f : BD3, 700, 1);
      mel(sb < 8 ? LEAD_A : LEAD_B, b8, (m, len) => { lead(m, len); pluckNote(P2, t, m + (sb < 8 ? 12 : 0), 0.5, 6, 0.12, 0); });
      if (STAB3.indexOf(s) >= 0) stab(t, 1, 4000, 0.11);
      arp(b4 < 2 ? ARP1 : ARP2, 0.6, 7, 0.08);
      if (last8 && s === 8) rcrash(0.5);
    } else { // outro: thins out bar by bar; the last two bars sit on the dominant with only a soft kick, bass, pad and arpeggio, like the intro they lead into
      if (sb === 0 && s === 0) { crash(0.6); sweep(t, 32 * S16, 0.5, false); }
      if (sub === 0) kick(t, 0.85 - 0.09 * sb);
      if (sb < 4) { back(0.6, false); hats(3, 0.6 - 0.08 * sb, false); } else if (sb < 6) hats(1, 0.4, false);
      bassPat(BG, 300 - 14 * sb, 0.9 - 0.08 * sb);
      arp(sb < 4 ? ARP1 : ARP3, 0.6 - 0.02 * sb, 6 - 0.4 * sb, 0.1);
      if (sb === 7 && s === 8) rcrash(0.4);
    }
  }

  /* ---- transport: a look-ahead scheduler on the audio clock ---- */
  let stepN = 0, t0 = 0, timer = 0, running = false;
  function pump() {
    const now = ctx.currentTime, ahead = (typeof document !== 'undefined' && document.hidden) ? 1.3 : 0.2; // hidden tabs get timers once a second
    let fresh = false;
    // after a main-thread stall, skip the missed steps instead of firing them all at once
    if (t0 + stepN * S16 < now - 0.05) { stepN = Math.ceil((now + 0.03 - t0) / S16); fresh = true; }
    while (t0 + stepN * S16 < now + ahead) { step(stepN, t0 + stepN * S16, fresh); fresh = false; stepN++; }
  }
  return {
    output: out, bpm: BPM,
    start() { if (running) return; running = true; stepN = 0; t0 = ctx.currentTime + 0.1; pump(); timer = setInterval(pump, 25); },
    stop() { running = false; clearInterval(timer); keep.forEach((n) => { try { if (n.stop) n.stop(); } catch (e) { /* not started */ } try { n.disconnect(); } catch (e) { /* already */ } }); },
    get running() { return running; },
    get position() { return running ? Math.max(0, ctx.currentTime - t0) : 0; }
  };
}

/* Plays a decoded AudioBuffer with the same surface as an <audio> element (paused, currentTime, duration, play, pause).
   Used when the page's sandbox refuses to stream blob: media into an <audio> element. */
function makeBufferPlayer(ctx, dests, onEnded) {
  let buf = null, src = null, startedAt = 0, offset = 0, playing = false;
  const stopSrc = () => { if (src) { src.onended = null; try { src.stop(); } catch (e) { /* not started */ } src.disconnect(); src = null; } };
  return {
    load(b) { stopSrc(); buf = b; offset = 0; playing = false; },
    get paused() { return !playing; },
    get duration() { return buf ? buf.duration : NaN; },
    get currentTime() { return playing ? Math.min(ctx.currentTime - startedAt, buf.duration) : offset; },
    set currentTime(t) { const was = playing; stopSrc(); playing = false; offset = clamp(t, 0, buf ? buf.duration : 0); if (was) this.play(); },
    play() {
      if (!buf || playing) return Promise.resolve();
      src = ctx.createBufferSource(); src.buffer = buf; dests.forEach((d) => src.connect(d));
      src.onended = () => { if (playing) { playing = false; offset = 0; onEnded(); } };
      startedAt = ctx.currentTime - offset; src.start(0, offset); playing = true; updateTransport();
      return Promise.resolve();
    },
    pause() { if (!playing) return; offset = ctx.currentTime - startedAt; playing = false; stopSrc(); updateTransport(); },
    stop() { stopSrc(); playing = false; offset = 0; }
  };
}

/* MOBILE: silent visual demo. Fake AnalyserNodes (same surface the offline renderer's fakeAnalyser uses) whose spectra
   are synthesised from a 140 BPM pattern: kick, offbeat bass, clap on 2 and 4, hats, a lead, then every 32 bars an
   8-bar breakdown (pad and a rising sweep, no kick) and a drop. Precomputed per-bin band shapes keep it cheap. */
function makeSynthAnalyser(N, sr, t0) {
  const bins = N / 2, hz = sr / N, lf = new Float32Array(bins);
  for (let i = 0; i < bins; i++) lf[i] = Math.log2(Math.max(i, 0.5) * hz);
  const band = (c, w) => { const a = new Float32Array(bins), l = Math.log2(c); for (let i = 0; i < bins; i++) { const d = (lf[i] - l) / w; a[i] = Math.exp(-d * d); } return a; };
  const KICK = band(55, 0.75), BASS = band(110, 0.6), CLAP = band(1800, 0.9), HAT = band(10000, 0.55), LEAD = band(900, 1.0), PAD = band(450, 1.3);
  const state = () => {
    const t = Math.max(0, nowS() - t0), beat = t * 140 / 60, cyc = (beat / 4) % 32, brk = cyc >= 24, ph = beat % 1, q = (beat * 4) % 1, n16 = Math.floor(beat * 4) % 4;
    return { t, brk, rise: brk ? (cyc - 24) / 8 : 0, kick: brk ? 0 : Math.exp(-ph * 9), bass: brk || n16 === 0 ? 0 : Math.exp(-q * 5),
      clap: !brk && Math.floor(beat) % 2 === 1 ? Math.exp(-ph * 14) : 0, hat: Math.exp(-((beat * 2) % 1) * 16) * (brk ? 0.4 : 1) + 0.4 * Math.exp(-q * 22),
      lead: brk ? 0 : (0.5 + 0.5 * Math.sin(t * 1.7)) * Math.exp(-q * 4) };
  };
  return {
    fftSize: N, frequencyBinCount: bins,
    getFloatFrequencyData(out) {
      const e = state(), k = 0.6 * e.kick * e.kick, b = 0.08 * e.bass, c = 0.03 * e.clap, h = 0.005 * e.hat, l = 0.008 * e.lead, pd = e.brk ? 0.012 : 0.002;
      const sweep = e.brk ? Math.log2(300 * Math.pow(8000 / 300, e.rise)) : 0, sw = 0.02 * e.rise * e.rise;
      for (let i = 0; i < Math.min(bins, out.length); i++) {
        let p = 2e-8 + k * KICK[i] + b * BASS[i] + c * CLAP[i] + h * HAT[i] + l * LEAD[i] + pd * PAD[i];
        if (sw > 0) { const d = (lf[i] - sweep) / 0.35; p += sw * Math.exp(-d * d); }
        out[i] = 10 * Math.log10(p);
      }
    },
    getFloatTimeDomainData(out) {
      const e = state();
      for (let i = 0; i < out.length; i++) { const s = e.t + i / sr; out[i] = 0.6 * e.kick * Math.sin(6.2832 * 52 * s) + 0.15 * (e.brk ? 1 : e.bass) * Math.sin(6.2832 * 110 * s); }
    }
  };
}

class Onset {
  constructor(n, minGap) { this.h = new Float32Array(n); this.i = 0; this.minGap = minGap; this.last = -9; this.filled = 0; }
  push(x, now, k, floor) {
    const h = this.h, n = h.length;
    let m = 0; for (let i = 0; i < n; i++) m += h[i]; m /= n;
    let v = 0; for (let i = 0; i < n; i++) { const d = h[i] - m; v += d * d; }
    const thr = m + k * Math.sqrt(v / n) + floor;
    h[this.i] = x; this.i = (this.i + 1) % n; if (this.filled < n) this.filled++;
    if (this.filled > 8 && x > thr && now - this.last > this.minGap) { this.prevLast = this.last; this.last = now; return clamp((x - thr) / (thr + 1e-3), 0, 1); }
    return -1;
  }
  reject() { this.last = this.prevLast; } // a vetoed onset must not start the refractory window
}

/* FA = what the analyser hears right now; F = what the visuals show, delayed by the output latency so pulses
   land when the sound leaves the speakers (matters a lot on Bluetooth). */
const mkFeatures = () => ({
  sub: 0, bass: 0, mid: 0, high: 0, level: 0, kick: 0, hit: 0, hat: 0, subN: 0, bassN: 0, midN: 0, highN: 0, levelN: 0,
  beat: 0, bar: 0, beatClock: 0, barIndex: 0, bpm: 0, conf: 0, drop: 0, build: 0,
  onKick: false, onHit: false, onDrop: false, onBar: false, silent: true, idle: 1, breakdown: 0, cent: 0.45,
  // v22 music structure cues (see CUE): continuous values, then the ones that follow delivered events
  energy: 0, energyTrend: 0, swell: 0, swellDir: 0, tension: 0, novelty: 0, bright: 0.5, sustain: 0, secLow: 0.33, secMid: 0.33, secHigh: 0.33, secDense: 0, secBright: 0.5, secEnergy: 0,
  beatConf: 0, tempo: 0, meter: 4, downConf: 0, barPhase: 0, pulse: 0, barBeat: 0, phrasePos: 0,
  impact: 0, impactStrength: 0, note: 0, notePos: 0.5, section: 0, sectionAge: 0, sectionSeed: 0, onSection: false, onImpact: false, onDownbeat: false, onPhrase: false, onNote: false
});
const FA = mkFeatures(), F = mkFeatures();
const FKEYS = ['sub', 'bass', 'mid', 'high', 'level', 'subN', 'bassN', 'midN', 'highN', 'levelN', 'kick', 'hit', 'hat', 'beat', 'bar', 'beatClock', 'barIndex', 'bpm', 'conf', 'drop', 'build', 'silent', 'idle', 'breakdown', 'cent'];
FKEYS.push('energy', 'energyTrend', 'swell', 'swellDir', 'tension', 'novelty', 'bright', 'sustain', 'secLow', 'secMid', 'secHigh', 'secDense', 'secBright', 'secEnergy', 'beatConf', 'tempo', 'meter', 'downConf', 'barPhase', 'pulse', 'barBeat', 'phrasePos'); // v22
const FEV = ['onKick', 'onHit', 'onDrop', 'onBar'];
const FHIST = [];
const DROP_EVENTS = [];
const LOOK = 0.18;
// Delayed spectrum: analysis runs LOOK ahead of what is heard, so spectrum-driven light used to brighten before each kick.
const SPEC_RING = { buf: Array.from({ length: 64 }, () => ({ t: -1e9, b: new Uint8Array(NB * 2) })), head: 0 };
function specDelay(now, audible) {
  const R = SPEC_RING, w = R.buf[R.head]; w.t = now; w.b.set(specBytes); R.head = (R.head + 1) % R.buf.length;
  if (now - audible < 1e-3) return;
  let best = null;
  for (const e of R.buf) if (e.t <= audible + 1e-4 && (!best || e.t > best.t)) best = e;
  if (best) specBytes.set(best.b);
}
function syncVisualFeatures() {
  const now=nowS(),L=AU.latency(),audible=now-L,snap={t:now};
  // the spectrum is analysed ahead of the speakers too: show the snapshot that is audible now, like the features
  specDelay(now,audible);
  for(const k of FKEYS)snap[k]=FA[k];
  for(const k of FEV)snap[k]=FA[k];
  snap.onDrop=false; // drops travel in their own event queue; continuous samples keep their capture times
  FHIST.push(snap);
  const ev={onKick:false,onHit:false,onDrop:false,onBar:false};let last=null;
  while(FHIST.length&&FHIST[0].t<=audible+1e-4){last=FHIST.shift();for(const k of FEV)ev[k]=ev[k]||last[k];}
  if(last)for(const k of FKEYS)F[k]=last[k];
  while(DROP_EVENTS.length&&DROP_EVENTS[0].t<=audible+1e-4){
    const event=DROP_EVENTS.shift();ev.onDrop=ev.onBar=true;
    // An event can fall between held feature samples. Publish its anchor, never a future clock value.
    F.beatClock=event.anchor;F.beat=F.bar=0;F.barIndex=event.index;
    F.drop=F.kick=1;F.build=0;
  }
  Object.assign(F,ev);
  cueDeliver(audible); // v22: section / impact / downbeat / phrase / note events and what follows them
  AU.visualClockHigh=Math.max(AU.visualClockHigh||0,F.beatClock);
  if(FHIST.length>240)FHIST.splice(0,FHIST.length-240);
}

