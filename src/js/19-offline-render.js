/* ========================= offline (music video) rendering =========================
   Frame-by-frame, independent of real time: the decoded track is analysed on a virtual clock by an FFT that
   mimics the AnalyserNodes, each frame renders at whatever quality was asked for (however slow), and frames are
   encoded in the page with WebCodecs. Driven by scripts/render-viszualizerrr.mjs. */
function makeFFT(N) {
  const lev = Math.log2(N) | 0, rev = new Uint32Array(N), cos = new Float32Array(N / 2), sin = new Float32Array(N / 2), win = new Float32Array(N);
  for (let i = 0; i < N; i++) { let r = 0; for (let b = 0; b < lev; b++) r |= ((i >> b) & 1) << (lev - 1 - b); rev[i] = r; }
  for (let i = 0; i < N / 2; i++) { cos[i] = Math.cos(2 * Math.PI * i / N); sin[i] = -Math.sin(2 * Math.PI * i / N); }
  for (let i = 0; i < N; i++) win[i] = 0.42 - 0.5 * Math.cos(2 * Math.PI * i / N) + 0.08 * Math.cos(4 * Math.PI * i / N); // Blackman, as AnalyserNode
  const re = new Float32Array(N), im = new Float32Array(N);
  return (x, mag) => {
    for (let i = 0; i < N; i++) { re[rev[i]] = x[i] * win[i]; im[rev[i]] = 0; }
    for (let size = 2; size <= N; size <<= 1) {
      const half = size >> 1, stepT = N / size;
      for (let i = 0; i < N; i += size) for (let j = 0; j < half; j++) {
        const k = j * stepT, a = i + j, b = a + half, tr = re[b] * cos[k] - im[b] * sin[k], ti = re[b] * sin[k] + im[b] * cos[k];
        re[b] = re[a] - tr; im[b] = im[a] - ti; re[a] += tr; im[a] += ti;
      }
    }
    for (let i = 0; i < N / 2; i++) mag[i] = Math.hypot(re[i], im[i]) / N;
  };
}
function fakeAnalyser(N, smoothing) {
  const fft = makeFFT(N), buf = new Float32Array(N), mag = new Float32Array(N / 2), sm = new Float32Array(N / 2);
  const take = () => { const end = Math.round(OFF.clock * OFF.sr); for (let i = 0; i < N; i++) { const j = end - N + i; buf[i] = j >= 0 && j < OFF.pcm.length ? OFF.pcm[j] : 0; } };
  return {
    fftSize: N, frequencyBinCount: N / 2,
    getFloatFrequencyData(out) { take(); fft(buf, mag); for (let i = 0; i < N / 2; i++) { sm[i] = smoothing * sm[i] + (1 - smoothing) * mag[i]; out[i] = sm[i] > 0 ? 20 * Math.log10(sm[i]) : -200; } },
    getFloatTimeDomainData(out) { take(); out.set(buf.subarray(0, out.length)); }
  };
}
const OFFLINE = {
  async load(bytes, opts) {
    opts = opts || {};
    // frame-by-frame renders may visit any realm: wait until every realm is prepared (normally already true)
    while (glReady && !realmsSettled() && !PREPARE.error) await new Promise((r) => setTimeout(r, 30));
    if (!AU.init()) throw new Error('no audio');
    const ab = bytes instanceof ArrayBuffer ? bytes : bytes.buffer;
    const buf = await AU.ctx.decodeAudioData(ab.slice(0));
    const pcm = new Float32Array(buf.length);
    for (let c = 0; c < buf.numberOfChannels; c++) { const d = buf.getChannelData(c); for (let i = 0; i < d.length; i++) pcm[i] += d[i] / buf.numberOfChannels; }
    AU.stopAll(); clearInterval(AU.fastTimer); AU.resetAnalysis(); CUE_VIS.section = 0; CUE.secCount = 0;
    OFF.on = true; OFF.pcm = pcm; OFF.sr = buf.sampleRate; OFF.clock = 0; OFF.tick = 0;
    AU.anaF = fakeAnalyser(1024, 0); AU.anaS = fakeAnalyser(4096, 0.5); AU.mode = 'offline';
    rand = mulberry(opts.seed ?? 1234567);
    journeyRand=mulberry((opts.seed ?? 1234567)^0x51f15e7d);
    Object.assign(D, { cur: null, nxt: null, upcoming: null, queue: null, peek: null, mix: 0, history: [], bag: [], cycle: 0,
      spin: 0, spinT: 0, mutN: 0, tc: [0, 0], barsIn: 0, timeIn: 0, realmBars: 0, realmTime: 0,
      lastMut: 0, phraseBase: 0, symRot: 0, symRotT: 0, hue: rand(), palFrom: 0, palTo: 0,
      palFromObj: null, palT: 1, palDur: 4, barCount: 0, lastStyle: -1, hurry: false });
    D.cur = makeVisit(0); resetRealmBag(0); WAVES.length = 0; HOLE.fill(0);
    Object.assign(PTR, { x: 0, y: 0, tx: 0, ty: 0, px: 0, py: 0, vx: 0, vy: 0, lx: 0, ly: 0,
      sx: 0, sy: 0, hold: 0, inf: 0, press: 0, active: 0, down: false, downT: 0, lastMove: -99,
      lastTap: -9, latched: false, dragged: false, pinch0: 0, zoom0: .8, zoom: .8, zoomT: .8, grav: 0 });
    PTR.pts.clear();
    // Feedback and exposure are state too. A repeat render with the same seed must start from black.
    for (const target of [RT.A, RT.B, RT.N, ...RT.fb, ...RT.down, ...RT.up, RT.hi]) if (target) clearTarget(target);
    for (const target of RT.expo) { gl.bindFramebuffer(gl.FRAMEBUFFER, target.fbo); gl.clearColor(0.47, 0, 0, 1); gl.clear(gl.COLOR_BUFFER_BIT); }
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    hideSplash(); setMinimal(true); document.body.classList.add('clean-embed-mode');
    $('#splash').style.display = 'none';
    viewMotionReset(); smoothReset(); FLOW.t = 0; FLOW.breath = 0; FOLD.visit = null; AUTO.fx = null; PULSE_LP.x = PULSE_LP.y = 0;
    // Offline sessions are independent performances, including camera springs and continuous-route custody.
    ZOOMS.v=0;ZOOMS.push=0;ZOOMS.pushT=-9;
    autoZoomReset();
    VOID9_J=null;
    TIME = 0; RTIME = 0; FHIST.length = 0; for (const e of SPEC_RING.buf) e.t = -1e9; Object.assign(EXPO_FAST, { until: -1e9, ref: false, was: false, end: -1e9, w: 0 });
    return buf.duration;
  },
  // render frame n of a video at fps; analysis runs LOOK ahead of the frame, exactly as in live playback
  frame(n, fps, analyseOnly) {
    OFF.skip = !!analyseOnly;
    const target = n / fps + LOOK;
    while (OFF.tick + 0.01 <= target + 1e-9) { OFF.tick += 0.01; OFF.clock = OFF.tick; AU.fastTick(); }
    OFF.clock = target;
    step(1 / fps);
    return { realm: D.cur ? D.cur.R.name : '', bpm: +F.bpm.toFixed(1), drop: F.onDrop };
  },
  enc: null, chunks: [], err: '',
  async startEncoder(o) {
    if (!glReady) throw new Error('Prepare the visualizer before starting an encoder');
    resize(); // size explicitly, without advancing audio, travel or feedback
    if (!window.VideoEncoder) throw new Error('WebCodecs VideoEncoder is not available');
    const cfg = { codec: o.codec, width: canvas.width, height: canvas.height, bitrate: o.bitrate, framerate: o.fps, latencyMode: 'quality' };
    if (/^avc1/.test(o.codec)) cfg.avc = { format: 'annexb' };
    const sup = await VideoEncoder.isConfigSupported(cfg);
    if (!sup.supported) throw new Error('encoder config not supported: ' + o.codec);
    this.chunks = []; this.err = '';
    this.enc = new VideoEncoder({ output: (ch) => { const d = new Uint8Array(ch.byteLength); ch.copyTo(d); this.chunks.push({ key: ch.type === 'key', ts: ch.timestamp, d }); }, error: (e) => { this.err = String(e); } });
    this.enc.configure(cfg);
    return { width: cfg.width, height: cfg.height };
  },
  async encode(n, fps) {
    const vf = new VideoFrame(canvas, { timestamp: Math.round(n * 1e6 / fps), duration: Math.round(1e6 / fps) });
    this.enc.encode(vf, { keyFrame: n % (fps * 2) === 0 }); vf.close();
    while (this.enc.encodeQueueSize > 6) await new Promise((r) => setTimeout(r, 2));
    if (this.err) throw new Error(this.err);
  },
  async finish() { await this.enc.flush(); this.enc.close(); },
  // hand encoded chunks to the driver (base64 keeps the CDP transfer simple)
  take() {
    const out = this.chunks.map((c) => { let s = ''; const d = c.d; for (let i = 0; i < d.length; i += 0x8000) s += String.fromCharCode.apply(null, d.subarray(i, i + 0x8000)); return { key: c.key, ts: c.ts, b64: btoa(s) }; });
    this.chunks = []; return out;
  }
};

