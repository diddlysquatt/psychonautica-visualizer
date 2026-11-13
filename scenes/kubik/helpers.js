// KUB1K v10 choreography. Everything that moves geometry is continuous: a beat-locked phase (a soft PLL onto the
// engine's beat clock), event ages in beats (kicks, snares, cascades, morphs), and springs. Raw audio only reaches
// light and colour in the shader.
// camera modes: elevation, distance, focal length (long lens = near-isometric), orbit rate (radians per beat), target
// height, roll
const KUBIK_CAM = {
  iso: { el: 0.62, dist: 22, foc: 4.4, azR: 0.035, ty: 0, roll: 0 },
  isoL: { el: 0.5, dist: 19, foc: 3.4, azR: -0.05, ty: 0.5, roll: 0.05 },
  top: { el: 1.42, dist: 26, foc: 3.9, azR: 0.03, ty: 0, roll: 0 },
  high: { el: 1.0, dist: 23, foc: 3.6, azR: 0.06, ty: 0, roll: 0 },
  low: { el: 0.4, dist: 18, foc: 1.9, azR: 0.05, ty: 1.5, roll: 0.07 },
  swoop: { el: 0.8, dist: 19, foc: 2.5, azR: 0.1, ty: 0, roll: 0.04 },
};
const KUBIK_CAMS = ['iso', 'isoL', 'top', 'high', 'low', 'swoop'];
const KUBIK_PIL = f => f === 3 || f === 4 || f === 7 || f === 9 || f === 10 || f === 12;
// v11 wow formations (phrase events, builds, drops): 7 skyline towers, 8 cube cloud, 9 grand stepped pyramid
const KUBIK_WOW = [7, 8, 9, 10, 11, 12, 13];
// formations: 0 swell, 1 ripple, 2 checker pump, 3 ziggurats, 4 equalizer rows, 5 spiral, 6 egg crate
const KUBIK_FORMS = [0, 1, 2, 3, 4, 5, 6];
const KUBIK_IMGS = 8, KUBIK_PALS = 7;
// spring with damping ratio z (1 = critically damped, below 1 overshoots and settles)
function kubikSpring(o, k, target, w, dt, z) {
  z = z === undefined ? 1 : z;
  // v19: the exact solution of the spring over dt, so it cannot blow up at any frame rate
  const x0 = o[k] - target, v0 = o[k + 'V'] || 0;
  if (z >= 0.999) {
    const e = Math.exp(-w * dt), c = v0 + w * x0, x = (x0 + c * dt) * e;
    o[k] = target + x; o[k + 'V'] = (c - w * (x0 + c * dt)) * e;
  } else {
    const wd = w * Math.sqrt(1 - z * z), e = Math.exp(-z * w * dt), co = Math.cos(wd * dt), si = Math.sin(wd * dt), B = (v0 + z * w * x0) / wd, x = e * (x0 * co + B * si);
    o[k] = target + x; o[k + 'V'] = e * (-z * w * (x0 * co + B * si) + wd * (B * co - x0 * si));
  }
}
function kubikZoom(V) { return clamp((PTR.zoom || 1) * (V.kz === undefined ? 1 : V.kz), 0.1, 4); }
function kubikInit(s) {
  let sd = Math.floor(s[1] * 2147483646) + 1;
  const rnd = () => (sd = (sd * 16807) % 2147483647) / 2147483647;
  const form = s.length > 4 ? s[4] : [0, 1, 3, 5, 2, 4, 6, 0, 1][Math.min(8, Math.floor(s[0] * 9))];
  const pal = Math.min(KUBIK_PALS - 1, Math.floor(s[2] * KUBIK_PALS)), img = Math.floor(rnd() * KUBIK_IMGS);
  const mode = s.length > 5 ? s[5] : ['iso', 'isoL', 'high', 'iso', 'swoop'][Math.floor(rnd() * 5)];
  const M = KUBIK_CAM[mode];
  const c = {
    ph: null, fA: form, fB: form, mAge: 99, casc: null, want: null,
    codeA: img + 8 * pal, codeB: img + 8 * pal, codeP: ((img + 3) % KUBIK_IMGS) + 8 * ((pal + 2) % KUBIK_PALS),
    rings: [{ t: -99, a: 0 }, { t: -99, a: 0 }, { t: -99, a: 0 }], sn: [{ t: -99, d: 0 }, { t: -99, d: 0 }], lastK: -99,
    be: new Array(8).fill(0), bs: new Array(8).fill(0), bass: 0, act: 0.3,
    pop: new Array(8).fill(0), popV: new Array(8).fill(0), popT: new Array(8).fill(0), lastOn: new Array(8).fill(-9),
    sm: Math.floor(rnd() * 4), smT: 0, sa: 0, bTow: false, wowBar: -99, lift: 0, yaw: 0, yawT: 0,
    S: 0.315 + 0.012 * Math.floor(rnd() * 4), face: s[3] < 0.5 ? 0.3 : 0, faceT: s[3] < 0.5 ? 0.3 : 0, K: 0.09, hop: 0.35, hat: 0,
    mode, bars: 0, modeBar: 0, cascN: 0, pd: 0, bdn: 0,
    // v19 events: ages are in beats and start far past the end of every animation
    kA: 9, kB: 9, kN: 0, snA: 9, snN: 0, hatA: 9, hatN: 0, dA: 9, dS: 0, crA: 9, crX: 0, crZ: 0, pat: 0, actI: 0, actT: 1 + Math.floor(s[3] * 7.77 % 1 * 8), actW: 0, bW: 0, actBar: 0,
    el: M.el, dist: M.dist, foc: M.foc, ty: M.ty, roll: 0, az: rnd() * 6.283, tx: 0, tz: 0,
  };
  c.azT = c.az; c.er = (sd * 48271) % 2147483647 || 1; // v19: the routines draw from their own stream, so the palettes and shots stay as they were
  if (s.length > 6) c.codeA = c.codeB = s[6];
  return c;
}
function kubikPickCam(c, forceHigh) {
  let cand = KUBIK_CAMS.filter(m => m !== c.mode);
  // after a low view always go high; breakdowns look down on the whole picture
  if (forceHigh || c.mode === 'low') cand = cand.filter(m => KUBIK_CAM[m].el > 0.7);
  c.mode = cand[Math.floor(rand() * cand.length)]; c.modeBar = c.bars;
  // a swing of the orbit as the new shot settles
  c.azT += (rand() < 0.5 ? -1 : 1) * (0.4 + 0.6 * rand());
}
// visible radius (cells) for the stagger of cascades and morphs: the front crosses the screen in about two beats
function kubikVis(c) { return Math.max(8, (c.distE || c.dist) / (c.focE || c.foc) * 1.1); }
function kubikCascade(c, o) {
  // o: { img, pal, type, big }
  const rollOK = !KUBIK_PIL(c.fA) && !KUBIK_PIL(c.fB);
  const type = o.type !== undefined ? o.type : [0, 1, 3, 2, 0, 1][c.cascN % 6];
  c.cascN++;
  const img = o.img !== undefined ? o.img : (c.codeA % 8 + 1 + Math.floor(rand() * (KUBIK_IMGS - 1))) % KUBIK_IMGS;
  const pal = o.pal !== undefined ? o.pal : Math.floor(c.codeA / 8);
  c.codeB = img + 8 * pal;
  c.casc = { age: 0, type, dir: Math.floor(rand() * 4), roll: rollOK ? 1 : 0 };
  if (c.mAge >= 99) c.K = 1.8 / kubikVis(c);
  c.hopT = o.big ? 1.5 : 0.35;
}
function kubikMorph(c, f) {
  if (f === c.fA) return;
  c.fB = f; c.mAge = 0; if (!c.casc) c.K = 1.8 / kubikVis(c);
  // the wow formations bring their own shot: look up at towers and into the cloud, down onto the pyramid
  if (f === 7 || f === 8) { c.mode = rand() < 0.5 ? 'low' : 'isoL'; c.modeBar = c.bars; c.azT += (rand() < 0.5 ? -1 : 1) * 0.6; }
  else if (f === 9 || f === 10 || f === 12) { c.mode = rand() < 0.5 ? 'iso' : 'high'; c.modeBar = c.bars; }
}
function kubikNextForm(c, wow) {
  if (wow) { let f = KUBIK_WOW[Math.floor(rand() * KUBIK_WOW.length)]; if (f === c.fA) f = KUBIK_WOW[(KUBIK_WOW.indexOf(f) + 1) % KUBIK_WOW.length]; return f; }
  let f = KUBIK_FORMS[Math.floor(rand() * KUBIK_FORMS.length)];
  if (f === c.fA) f = (f + 1 + Math.floor(rand() * 6)) % 7;
  return f;
}
function kubikNewPal(c) { const p = Math.floor(c.codeA / 8); return (p + 1 + Math.floor(rand() * (KUBIK_PALS - 1))) % KUBIK_PALS; }
function kubikFrame(V, F, dt) {
  const c = V.c;
  dt = Math.min(Math.max(dt, 0), 0.1);
  const bpm = F.bpm > 40 ? F.bpm : 120, bps = bpm / 60;
  const ms = clamp(Number(S.motionSmooth) || 0, 0, 1), sm = 1.45 - ms; // spring speed: 0 snappy .. 1 very smooth
  // beat-locked phase: advances at the tempo, pulled softly onto the engine's beat clock (never jumps)
  const bc = F.beatClock || 0;
  if (c.ph === null) c.ph = bc;
  c.ph += dt * bps * S.speed;
  const e = bc - c.ph;
  if(F.conf>.25&&!F.silent){if (Math.abs(e) > 6) c.ph = bc; else c.ph += e * Math.min(1, dt * 1.5);}
  // bands: fast-ish attack (70 ms), slow release (260 ms), then a spring so heights never step
  const BL = (typeof BANDS !== 'undefined' && BANDS.lv) ? BANDS.lv : null, BF = BL && BANDS.fast ? BANDS.fast : null;
  // v11: the auto-ranged envelopes say how a band moves, not how much of it there is; weight each by the band's share
  // of the spectrum (its level against the loudest band) so a bassline lifts the bass rows and hats the air rows, and
  // gate everything by the engine's silence detector
  const idle = clamp(F.idle || 0, 0, 1);
  let fm = 1e-3; if (BF) for (let i = 0; i < 8; i++) fm = Math.max(fm, BF[i] * (1 + 0.12 * i));
  for (let i = 0; i < 8; i++) {
    const sh = BF ? clamp(BF[i] * (1 + 0.12 * i) / fm, 0, 1) : 1;
    const t = (BL ? BL[i] : 0) * (0.2 + 0.8 * Math.pow(sh, 1.3)) * (1 - idle);
    c.be[i] = ease(c.be[i], t, dt, t > c.be[i] ? 0.07 : 0.26);
    const o = { x: c.bs[i], xV: (c.bsV || (c.bsV = new Array(8).fill(0)))[i] };
    kubikSpring(o, 'x', c.be[i], 15 * sm, dt); c.bs[i] = o.x; c.bsV[i] = o.xV;
  }
  // v11 per-band onset pops: an impulse per onset (one per .3 beat per band), smoothed by a spring with a ~70 ms rise so
  // the chosen cubes jump crisply but never step
  const ON = (typeof BANDS !== 'undefined' && BANDS.on) ? BANDS.on : null;
  for (let i = 0; i < 8; i++) {
    // v20: the retrigger gate was .3 beat: a pop could fire again before the cube had finished the last one, which read as shivering
    const o = ON ? ON[i] : 0;
    if (o > 0.6 && c.ph - c.lastOn[i] > 0.5) { c.lastOn[i] = c.ph; c.popT[i] = Math.min(1.1, 0.55 + 0.5 * o) * (i >= 6 ? 0.6 : i >= 4 ? 0.85 : 1); }
    c.popT[i] *= Math.exp(-dt / 0.2);
    const q = { x: c.pop[i], xV: c.popV[i] };
    kubikSpring(q, 'x', c.popT[i], 11 * sm, dt, 1); c.pop[i] = q.x; c.popV[i] = q.xV;
  }
  // activity: how much music there is (the beat-clock choreography calms right down in silence)
  const lvl = Math.max(F.levelS !== undefined ? F.levelS : F.level || 0, 0.8 * Math.max(c.be[0], c.be[1], c.be[3]));
  c.act = ease(c.act, lerp(clamp(0.22 + 1.5 * lvl, 0.22, 1), 0.2, idle), dt, 0.6);
  c.bass = ease(c.bass, Math.max(c.be[0], c.be[1]) * (0.6 + 0.6 * S.dose) * (1 - 0.5 * c.bdn), dt, 0.18 + 0.2 * ms);
  // phrase structure
  const dropEdge = F.onDrop || (F.drop > 0.85 && c.pd < 0.5); c.pd = F.drop;
  const bdOn = F.breakdown > 0.6 && F.drop < 0.3;
  c.bdn = ease(c.bdn, bdOn ? 1 : 0, dt, bdOn ? 1.2 : 0.5);
  if ((F.onBar || F.onSceneBar)) c.bars++;
  if (dropEdge) {
    // drops: a big formation change, usually into a wow formation, and a new spectrum map
    c.want = { form: kubikNextForm(c, rand() < 0.65), casc: { pal: kubikNewPal(c), type: 0, big: true } };
    c.smT = (c.sm + 1 + Math.floor(rand() * 3)) % 4; c.bTow = false;
    kubikPickCam(c, false);
    if (rand() < 0.5) c.faceT = c.faceT > 0 ? 0 : 0.3;
  } else if ((F.onBar || F.onSceneBar)) {
    if (c.bars % 4 === 0 && !c.want) c.want = { casc: { pal: c.bars % 8 === 0 ? kubikNewPal(c) : undefined } };
    if (c.bars % 16 === 10 && !c.want) c.want = { form: kubikNextForm(c, c.bars - c.wowBar >= 24 && rand() < 0.45) };
    // a wow formation is an event: after 8 bars it gives way to a regular one
    if ((c.fA === 7 || c.fA === 8 || c.fA === 9) && c.mAge >= 99 && c.bars - c.wowBar >= 8 && F.build < 0.4 && !c.want) c.want = { form: kubikNextForm(c, false) };
    if (c.bars % 8 === 4) c.smT = (c.sm + 1 + Math.floor(rand() * 3)) % 4;
    // rare surprise: every cube turns half a round, neighbours the opposite way
    if (c.bars % 8 === 6 && F.build < 0.25 && rand() < 0.15) c.yawT += Math.PI;
    if (c.bars - c.modeBar >= (c.mode === 'low' ? 4 : 6) || (bdOn && KUBIK_CAM[c.mode].el < 0.7)) kubikPickCam(c, bdOn);
  }
  // builds raise the skyline: towers grow with the build (lift), then the drop changes formation
  if (F.build > 0.4 && F.drop < 0.3 && !c.bTow && c.fA !== 7 && c.fB !== 7 && !c.want) { c.want = { form: 7 }; c.bTow = true; }
  if (F.build < 0.1 && !dropEdge && F.drop < 0.3) c.bTow = false;
  if ((c.fB === 7 || c.fB === 8 || c.fB === 9) && c.mAge < 0.1) c.wowBar = c.bars;
  // spectrum map: fade out, switch mode, fade back in (never jumps); breakdowns play it softly, every fourth phrase
  // is an all-out equalizer city
  const saT = c.sm === c.smT ? (c.bdn > 0.5 ? 0.35 : (c.bars % 32 < 8 ? 1 : 0.62)) * (0.5 + 0.5 * Math.min(1.5, S.dose)) : 0;
  c.sa = ease(c.sa, saT, dt, 0.35 + 0.3 * ms);
  if (c.sm !== c.smT && c.sa < 0.03) c.sm = c.smT;
  // v19: the events every cube answers. A slot still mid-air is never retriggered, so no cube can jump.
  const db0 = dt * bps;
  c.kA += db0; c.kB += db0; c.snA += db0; c.hatA += db0; c.dA += db0; c.crA += db0;
  const r2 = () => (c.er = (c.er * 16807) % 2147483647) / 2147483647;
  if (F.onKick) {
    const slot = c.kN % 2 === 0 ? 'kA' : 'kB';
    if (c[slot] > 1.14) { c[slot] = 0; c.kN = (c.kN + 1) % 64; }
    if (c.crA > 1.3) { const R = Math.min(15, kubikVis(c) * 0.7); c.crA = 0; c.crX = Math.round(clamp((r2() * 2 - 1) * R, -16, 15)); c.crZ = Math.round(clamp((r2() * 2 - 1) * R, -16, 15)); }
  }
  if (F.onHit && c.snA > 0.95) { c.snA = 0; c.snN = (c.snN + 1) % 64; }
  const hatOn = (F.hat || 0) > 0.5 || (ON && (ON[6] > 0.6 || ON[7] > 0.6));
  if (hatOn && c.hatA > 0.62) { c.hatA = 0; c.hatN = (c.hatN + 1) % 64; }
  if (dropEdge) { c.dA = 0; c.dS = Math.floor(r2() * 64); }
  // the routine: a new one every four bars and on every drop, faded out before it changes; breakdowns only hint at it
  if (dropEdge || ((F.onBar || F.onSceneBar) && c.bars - c.actBar >= 4)) {
    c.actBar = c.bars; c.pat = Math.floor(r2() * 5);
    c.actT = 1 + (c.actT + Math.floor(r2() * 7)) % 8;
  }
  c.actW = ease(c.actW, c.actI === c.actT ? (c.bdn > 0.5 ? 0.3 : 1) * clamp(c.act * 1.4, 0, 1) : 0, dt, 0.16);
  if (c.actI !== c.actT && c.actW < 0.02) c.actI = c.actT;
  c.bW = ease(c.bW, F.build > 0.25 && F.drop < 0.3 ? F.build * Math.min(1.2, S.dose) : 0, dt, 0.2);
  // start queued work when nothing it could clash with is running (a morph never starts under rolling cubes)
  if (c.want) {
    const W = c.want;
    if (W.form !== undefined && c.mAge > 3.6 && !(c.casc && c.casc.roll)) { kubikMorph(c, W.form); delete W.form; }
    if (W.casc && !c.casc && (W.form === undefined || c.mAge < 3.6)) { kubikCascade(c, W.casc); delete W.casc; }
    if (W.form === undefined && !W.casc) c.want = null;
  }
  c.tourT=(c.tourT||0)+dt*S.speed;
  if(c.tourT>13&&!c.want&&c.mAge>=99&&!c.casc){c.tourT=0;c.want={form:kubikNextForm(c,true),casc:{pal:kubikNewPal(c),big:true}};}
  const db = dt * bps;
  if (c.mAge < 99) { c.mAge += db; if (c.mAge > 3.6) { c.fA = c.fB; c.mAge = 99; } }
  if (c.casc) {
    c.casc.age += db;
    if (c.casc.age > 2.95) { c.codeP = c.codeA; c.codeA = c.codeB; c.casc = null; }
  }
  c.hop = ease(c.hop, c.casc ? c.hopT : 0.35, dt, 0.3);
  // kicks launch ripples (at most one per .4 beat, three in flight); snares send a row wave across the field
  if (F.onKick && c.ph - c.lastK > 0.45) {
    c.lastK = c.ph; c.rings.pop(); c.rings.unshift({ t: c.ph, a: Math.min(1.27, (0.55 + 0.75 * Math.min(1, F.kick)) * (0.5 + 0.5 * S.dose)) });
  }
  if (F.onHit && c.ph - c.sn[0].t > 0.5) { c.sn.pop(); c.sn.unshift({ t: c.ph, d: (c.sn[0].d + 1 + (rand() < 0.5 ? 2 : 0)) % 4 }); }
  // builds float the cubes up and spin them (counter-rotating checker); afterwards they settle onto a quarter turn
  // with an overshoot
  const liftT = F.drop > 0.3 ? 0 : F.build * S.dose * 0.9;
  c.lift = ease(c.lift, liftT, dt, liftT > c.lift ? 0.8 : 0.45);
  if (F.build > 0.25 && F.drop < 0.3) c.yawT += dt * bps * 0.5 * F.build;
  else c.yawT = Math.round(c.yawT / (Math.PI / 2) + (c.yawT > c.yaw + 0.3 ? 0.49 : 0)) * Math.PI / 2;
  kubikSpring(c, 'yaw', c.yawT, 5 * sm, dt, 0.55);
  c.face = ease(c.face, c.faceT, dt, 0.6);
  // camera: springs toward the mode; orbit is continuous; zoom-out backs off, rises and widens the picture
  const M = KUBIK_CAM[c.mode], Z = kubikZoom(V), zo = clamp((1 - Z) / 0.85, 0, 1), zs = zo * zo * (3 - 2 * zo);
  const W = 1.5 * sm;
  c.azT += M.azR * db * S.speed * (1 + F.build) * (0.4 + 0.6 * c.act);
  kubikSpring(c, 'az', c.azT + PTR.x * 0.3 * (PTR.inf || 0), W, dt);
  // v12: far out (below .5) the camera climbs further toward a top-down view, so the giant picture reads flat-on
  // instead of as grazing streaks of tiny cubes
  const zf = clamp((0.5 - Z) / 0.35, 0, 1);
  // v13: the springs carry only the shot (mode, lift, breakdown); the wheel zoom is applied on top without a spring (the
  // engine already smooths it), so the picture moves with the hand and stops when it stops
  kubikSpring(c, 'el', Math.min(1.45, M.el + 0.3 * c.lift + (bdOn ? 0.15 : 0)), W, dt);
  // low shots rise while the spectrum map plays, so the near rows never hide the far ones
  // (and tall pillar formations, the equaliser rows, ziggurats, skyline and pyramid, lift them further, so the camera
  // looks down the rows instead of into the first one)
  c.elS = ease(c.elS || 0, c.mode === 'low' || c.mode === 'isoL' ? 0.16 * clamp(c.sa, 0, 1) + (KUBIK_PIL(c.fA) || KUBIK_PIL(c.fB) ? 0.32 : 0) : 0, dt, 0.8);
  const elB = c.el + c.elS, elE = Math.min(1.45, elB + (Math.max(elB, 0.8 + 0.4 * zf * zf * (3 - 2 * zf)) - elB) * zs);
  // wow formations need room: back off for the pyramid and the skyline
  const wd = Math.max(c.fA === 9 || c.fB === 9 ? 1.55 : 1, c.fA === 7 || c.fB === 7 ? 1.3 : 1);
  c.wd = ease(c.wd || 1, wd, dt, 1.2);
  kubikSpring(c, 'dist', c.wd * M.dist * (1 + 0.25 * c.lift + 0.15 * c.bdn) * (1 + 0.02 * c.bass), W, dt);
  kubikSpring(c, 'foc', M.foc, W, dt);
  // zoom in: half dolly, half longer lens (the camera stays above the cubes, the tops' stickers and bevels fill the frame)
  c.distE = c.dist * Math.pow(Z, Z < 1 ? -1.15 : -0.45); c.focE = c.foc * (Z > 1 ? Math.pow(Z, 0.55) : 1);
  kubikSpring(c, 'ty', M.ty + 5 * c.lift, W, dt);
  kubikSpring(c, 'roll', M.roll * Math.sin(V.mt * 0.13 + 1.7), 1.2 * sm, dt);
  // the target drifts slowly around the centre of the picture
  const tx = 2.5 * Math.sin(c.ph * 0.031), tz = 2.5 * Math.cos(c.ph * 0.023);
  const sc = Math.max(1, Math.pow(Z, -0.55));
  const ce = Math.cos(elE), T = [tx, c.ty, tz];
  const cp = [T[0] + c.distE * ce * Math.cos(c.az), T[1] + c.distE * Math.sin(elE), T[2] + c.distE * ce * Math.sin(c.az)];
  // towers: keep the camera above the skyline
  const tw = (c.fA === 7 ? 1 : 0) + (c.fB === 7 ? 1 : 0);
  c.camY = ease(c.camY || 0, tw ? 5 + 9 * c.lift : 0, dt, 0.8);
  V.p1 = [cp[0], Math.max(cp[1], 10 + 6 * c.lift + c.camY), cp[2], c.focE];
  V.p2 = [T[0], T[1], T[2], c.roll];
  const ring = r => Math.floor(Math.min(1.27, r.a) * 100) * 64 + Math.min(63, Math.max(0, c.ph - r.t));
  V.p3 = [c.ph % 64, ring(c.rings[0]), ring(c.rings[1]), ring(c.rings[2])];
  // v19 packing (whole numbers in the high bits): see the unpacking at the top of realm()
  const A200 = a => Math.min(799, Math.floor(clamp(a, 0, 4) * 200)), A100 = a => Math.min(799, Math.floor(clamp(a, 0, 8) * 100)), A128 = a => Math.min(255, Math.floor(clamp(a, 0, 2) * 128));
  V.p4 = [c.fA + 16 * (A200(c.hatA) + 1024 * c.hatN), c.fB + 16 * (A200(c.snA) + 1024 * c.snN), c.mAge, c.casc ? c.casc.age : 99];
  V.p5 = [c.codeA + 64 * (A100(c.dA) + 1024 * c.dS), c.codeB + 64 * (c.kN + 64 * (c.actI + 16 * c.pat)), c.sm + 4 * Math.round(clamp(c.sa, 0, 1.5) * 100),
    (c.casc ? c.casc.type + 4 * c.casc.dir + 16 * c.casc.roll : 0) + 32 * (A128(c.crA) + 256 * ((c.crX + 16) * 32 + (c.crZ + 16)))];
  const snc = o => o.d * 128 + Math.min(127, Math.max(0, c.ph - o.t));
  // bands and pops packed: floor(pop*250)*4 + band (band < 4)
  const pk = i => Math.round(clamp(c.pop[i], 0, 1.2) * 250) * 4 + clamp(c.bs[i], 0, 3.99);
  V.m1 = new Float32Array([pk(0), pk(1), pk(2), pk(3), pk(4), pk(5), pk(6), pk(7), snc(c.sn[0]) + 512 * Math.round(clamp(c.actW, 0, 1) * 63)]);
  V.m2 = new Float32Array([c.bass, c.lift, c.yaw, Math.round(clamp(c.act, 0, 1) * 1000) + clamp(c.S, 0, 0.999), A200(c.kA) * 1024 + A200(c.kB), sc, c.K, c.hop, snc(c.sn[1]) + 512 * Math.round(clamp(c.bW, 0, 1) * 63)]);
}
