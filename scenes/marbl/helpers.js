// MARBL: the bath is a list of operations (newest first) that the shader inverts per pixel.
// Op kinds: site (concentric ink drop rings), comb (tine rake / single stylus), wave (sine/triangle comb),
// vort (swirl), flood (a giant multi-ring drop that becomes a fresh bath and lets older ops be pruned),
// multi (many-ringed drop), spr (sprinkled brushful / gold or silver leaf), rad (radial stylus: petals, wings).
const marblCAP = 28;
// ---- the camera (v21): one physical camera, every value on an exact critically damped spring (stable at any dt).
// Watching, it hangs straight over the live print. Now and then it goes for a walk in the gallery: it leans forward,
// travels over the rows of prints in step with the beat (pushing in on the bass, easing off on quiet bars), turns its
// head at uneven moments, and comes down on a print further on (the live bath's twin), or it only leans out over the
// wall, looks around and comes back. How long, how far, how low and which way are drawn fresh every time.
function marblSpr(s, tgt, w, dt) { const d = s.x - tgt, e = Math.exp(-w * dt), u = (s.v + w * d) * dt; s.x = tgt + (d + u) * e; s.v = (s.v - w * u) * e; if (Math.abs(s.x - tgt) < 1e-7 && Math.abs(s.v) < 1e-7) { s.x = tgt; s.v = 0; } }
function marblCamNew(s) {
  const r = marblRng([s[2], s[0], s[3], s[1]]), sp = () => ({ x: 0, v: 0 });
  return { r, mode: 0, w: 0, minW: 10 + 14 * r(), maxW: 55 + 40 * r(), th: sp(), ya: sp(), px: sp(), py: sp(), z: { x: 1, v: 0 }, sl: sp(), slT: 0, slD: r() < 0.5 ? -1 : 1,
    yT: 0, O: 0, dup: 0, ep: 0, pd: 0, P: null, t: 0, b: 0, wi: 0, tp: false, tr: null, n: 0 };
}
function marblCamPlan(cm, force) {
  const r = cm.r, flight = force ? force === 1 : r() < 0.84, P = { flight, sg: r() < 0.5 ? -1 : 1, wp: [] };
  if (flight) { P.th = 0.78 + 0.18 * r(); P.z = 0.3 + 0.26 * r(); P.st = 0.2 + 0.22 * r(); P.K = Math.max(8, Math.min(12, 2 * Math.round((32 + 40 * r()) * P.st / 3.78))); P.len = P.K * 1.89; }
  else { P.th = 0.6 + 0.26 * r(); P.z = 0.42 + 0.24 * r(); P.back = 0.4 + 0.8 * r(); P.len = 22 + 24 * r(); P.K = 0; }
  P.wT = 0.34 + 0.16 * r(); P.dx = 0.06 + 0.07 * r();   // how briskly it leans in; the sideways drift of a lean (prints a beat)
  // head turns and side drift at uneven moments (fractions of the way); mostly the head swings back the other way
  let f = 0.1 + 0.2 * r(), s = P.sg; const n = (flight ? 2 : 1) + Math.floor(r() * 2);
  for (let i = 0; i < n; i++) {
    const lo = r() < 0.4 ? 0.12 + 0.2 * r() : (r() - 0.5) * 0.14;   // (now and then it comes down low over the prints, then rises again)
    P.wp.push({ f, ya: s * (0.07 + 0.2 * r()), x: s * (0.3 + 1.1 * r()) * (flight ? 1 : 0.5), th: (r() - 0.5) * 0.2 - 0.25 * Math.max(lo, 0), z: lo }); f += 0.17 + 0.25 * r(); s = r() < 0.75 ? -s : s; }
  return P;
}
// zE: the engine's zoom times the realm's .86; db: beats travelled this frame; sm: Motion smoothness; busy: nothing may start now
function marblCam(c, F, dt, db, zE, sm, busy) {
  const cm = c.cam, drop = (F.drop || 0) > 0.5 && (cm.pd || 0) <= 0.5, kw = 1 / (0.55 + 0.6 * sm), zW = c.bdT > 12 ? 0.55 : 1;
  let thT = 0, yaT = 0, xT = 0, zT = zW, w = [0.5, 0.7, 0.6, 0.5, 0.55];   // spring rates: pitch, yaw, x, y, height
  if (cm.mode === 0) {
    cm.w += dt;
    const want = c.camReq || c.xcam || (cm.w > cm.maxW && F.onBar);
    if (want && (c.xcam || (cm.w > cm.minW && !busy))) {
      cm.P = marblCamPlan(cm, c.xcam || 0); cm.mode = 1; cm.t = 0; cm.b = 0; cm.wi = 0; cm.tp = false; cm.n++;
      cm.dup = cm.P.flight ? cm.P.K : 0; cm.yT = cm.py.x; cm.xD = 0;
    }
    c.camReq = 0; c.xcam = 0;
  }
  if (cm.mode === 1) {
    const P = cm.P; cm.t += dt; cm.b += db;
    const ramp = Math.min(1, cm.t / 5), rs = ramp * ramp * (3 - 2 * ramp), H = 1 / Math.max(zE * cm.z.x, 0.02), sn = Math.sin(cm.th.x), cs = Math.cos(cm.th.x);
    let prog;
    if (P.flight) {
      cm.yT += P.st * db * rs;
      // the live print has passed out of the bottom of the frame: from here its twin, K rows on, is the live print
      if (!cm.tp && cm.th.x > 0.5 && cm.py.x + H * (sn - 0.5 * cs) / (cs + 0.5 * sn) - 1.3 > 1.1 || (!cm.tp && cm.yT > P.len - 3)) {
        cm.tp = true; cm.py.x -= P.len; cm.yT -= P.len; cm.O = (cm.O + P.K) % 64; cm.dup = 0; }
      prog = (cm.yT + (cm.tp ? P.len : 0)) / P.len;
      // near the end: come down on the print ahead (the spring must be able to stop in the distance that is left)
      if (cm.tp && -cm.py.x < Math.max(1.7, 1.5 * cm.py.v / (0.5 * kw))) cm.mode = 2;
    } else { prog = cm.b / P.len; if (cm.b > P.len) cm.mode = 2; }
    while (cm.wi < P.wp.length && prog >= P.wp[cm.wi].f) cm.wi++;
    const q = cm.wi > 0 ? P.wp[cm.wi - 1] : { ya: 0.03 * P.sg, x: 0, th: 0, z: 0 };
    const quiet = F.silent || (F.level || 0) < 0.12 ? 1 : 0;
    thT = Math.min(1, P.th + q.th + 0.04 * Math.min(1, c.sw)); yaT = q.ya; xT = q.x;
    cm.lv = (cm.lv ?? 0.4) + ((F.level || 0) - (cm.lv ?? 0.4)) * (1 - Math.exp(-dt / 2.5));   // (loudness over a couple of bars: it pushes in as the music fills out and eases back as it thins)
    zT = Math.min(0.85, (P.z + q.z) * (1 + 0.16 * Math.min(1, c.sw) + 0.3 * (cm.lv - 0.4) - 0.07 * quiet));
    if (!P.flight) { cm.yT = -P.back * rs; cm.xD = Math.max(-2.6, Math.min(2.6, (cm.xD || 0) + P.sg * P.dx * db * rs)); xT += cm.xD; }   // (leaning out, it drifts slowly along the wall)
    w = [P.wT, 0.5, 0.4, 1.6, 0.45];
  }
  if (cm.mode === 2) {      // coming back: everything eases to the watching pose; the walk is over once it has all but settled
    cm.yT = 0;
    if (Math.abs(cm.th.x) < 0.02 && Math.abs(cm.py.x) < 0.02 && Math.abs(cm.z.x - zW) < 0.02) { cm.mode = 0; cm.w = 0; cm.minW = 32 + 40 * cm.r(); cm.maxW = 80 + 50 * cm.r(); }
  }
  marblSpr(cm.th, thT, w[0] * kw, dt); marblSpr(cm.ya, yaT, w[1] * kw, dt); marblSpr(cm.px, xT, w[2] * kw, dt);
  marblSpr(cm.py, cm.yT, w[3] * kw, dt); marblSpr(cm.z, zT, w[4] * kw, dt);
  // the wall dances: while the camera is out, the odd rows slide a whole print along the wall on every snare of a build,
  // on some bar lines, and two the other way on a drop (a punchy spring: each step lands on its beat and stops)
  if (cm.mode > 0 || cm.z.x < 0.8) {
    let st = 0;
    if (drop) { cm.slD = -cm.slD; st = 2; } else if (F.onHit && c.bE > 0.3) st = 1; else if (F.onBar && cm.r() < 0.18) st = 1;
    if (st && c.tr - (cm.slB ?? -9) > 0.45) { cm.slB = c.tr; if (cm.slT + cm.slD * st > 15 || cm.slT + cm.slD * st < 0) cm.slD = -cm.slD; cm.slT += cm.slD * st; }
  }
  marblSpr(cm.sl, cm.slT, 9 * kw, dt);
  // a drop re-pours the whole gallery (the front runs out with the engine's own drop envelope, the same value the shader sees)
  if (drop) cm.ep = (cm.ep + 1) & 3; cm.pd = F.drop || 0;
}
function marblRng(s) {
  let a = (Math.floor(s[0] * 1e9) ^ Math.floor(s[1] * 7e8) ^ Math.floor(s[2] * 3e8) ^ Math.floor(s[3] * 5e8)) >>> 0;
  return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
}
function marblGrid(x, y) {
  return [Math.max(0, Math.min(63, Math.round((x / 1.3 + 1) / 2 * 63))), Math.max(0, Math.min(31, Math.round((y / 0.8 + 1) / 2 * 31)))];
}
function marblXY(g) { return [(g[0] / 63 * 2 - 1) * 1.3, (g[1] / 31 * 2 - 1) * 0.8]; }
function marblWord(o, ampScale) {
  const g = o.g || [32, 16];
  switch (o.k) {
    case 'site': return (g[0] << 3) | (g[1] << 9) | ((o.n - 1) << 14) | (o.cA << 16) | (o.cB << 19) | (o.sz << 22);
    case 'comb': case 'wave': {
      const a = Math.max(-15, Math.min(15, Math.round(o.amp * (ampScale ?? 1))));
      return (o.k === 'comb' ? 1 : 2) | (o.ang << 3) | (o.sp << 7) | ((a + 15) << 10) | (o.off << 15) | (o.lam << 22);
    }
    case 'vort': { const s = Math.max(-15, Math.min(15, Math.round(o.amp * (ampScale ?? 1)))); return 3 | (g[0] << 3) | (g[1] << 9) | ((s + 15) << 14) | (o.sg << 19) | ((o.ring ? 1 : 0) << 22); }
    // flood: ring count 10+nr, sequence pat, growth profile gm (2 bits), bead necklaces in the rings (bit 23)
    case 'flood': return 5 | (g[0] << 3) | (g[1] << 9) | (o.nr << 14) | (o.pat << 18) | ((o.gm & 3) << 21) | ((o.bead ? 1 : 0) << 23);
    // many-ringed drop: ring count 6+2*nr, ring sequence seq+8 (0..2 suminagashi, 3 sun, 4..7 agate), size .07*1.3^sz
    case 'multi': return 4 | (g[0] << 3) | (g[1] << 9) | (o.nr << 14) | (o.seq << 18) | (o.sz << 21);
    // sprinkle: a whole brushful of drops at once (stone, gall rings, micro-droplets) or leaf flakes (cA 6 gold, 7 silver)
    case 'spr': return 6 | (o.md << 3) | (o.sc << 5) | (o.sd << 8) | (o.cA << 13) | (o.cB << 16) | (o.dens << 19) | (o.rad << 21);
    // radial stylus through a drop: petals (daisy, carnation, alternating) or a bird's wings
    case 'rad': { const a = Math.max(-7, Math.min(7, Math.round(o.amp * (ampScale ?? 1)))); return 7 | (g[0] << 3) | (g[1] << 9) | (o.ns << 14) | ((a + 7) << 17) | (o.md << 21) | (o.ph << 23); }
  }
  return 0;
}
const marblEase = {
  out: t => 1 - Math.pow(1 - t, 3),
  pour: t => 1 - Math.pow(1 - t, 4),
  io: t => t * t * (3 - 2 * t)
};
function marblProg(o, tr) {
  if (o.done) return 1;
  if (o.rock) return o.val;
  const t = Math.max(0, Math.min(1, (tr - o.t0) / o.dur));
  return marblEase[o.ease](t);
}
// spectral centroid -> ink index (dark inks for dark sounds, light inks for bright ones), relative to recent range
function marblInk(c, F, avoid) {
  const x = F.cent ?? 0.45, lo = c.cLo, hi = Math.max(c.cHi, c.cLo + 0.06), b = (x - lo) / (hi - lo);
  c.ci = (c.ci || 0) + 1;
  const half = b > 0.5 ? 3 : 0;
  let i = half + (c.ci % 3);
  if (i === avoid) i = half + ((c.ci + 1) % 3);
  return i;
}
// a falling drop: it is seen in the air for a quarter beat, lands, splashes; two splash slots, the oldest is reused
function marblSplash(c, g, ink, sz) {
  const s = c.spl[0].t < c.spl[1].t ? 0 : 1;
  c.spl[s] = { g, t: c.tr + 0.25, ink: ink & 7, sz: Math.max(0, Math.min(3, sz)) };
}
// the bath is busy (a pour still streaming, or a sheet being pulled): drops only splash, nothing is written
function marblBusy(c) {
  if (c.lift && !c.lift.flooded) return true;
  for (let i = 0; i < 3 && i < c.ops.length; i++) { const o = c.ops[i]; if (o.k === 'flood' && !o.done && marblProg(o, c.tr) < 0.97) return true; }
  return false;
}
function marblSitePos(c, R) {
  const f = c.form, k = c.fk++;
  let x, y;
  if (f === 0) {           // phyllotaxis bloom around a focus
    const r = 0.075 * Math.sqrt(k + 0.6), a = k * 2.39996 + c.fa;
    x = c.fc[0] + 1.35 * r * Math.cos(a); y = c.fc[1] + r * Math.sin(a);
    if (Math.abs(x) > 0.85 || Math.abs(y) > 0.47) { c.fk = 1; c.fc = [(R() - 0.5) * 0.9, (R() - 0.5) * 0.45]; c.fa = R() * 6.28; x = c.fc[0]; y = c.fc[1]; }
  } else if (f === 1) {    // serpentine rows, like a stone (battal) ground laid down drop by drop
    const i = k % 21, row = Math.floor(i / 7); let col = i % 7; if (row % 2) col = 6 - col;
    x = -0.75 + col * 0.25 + (R() - 0.5) * 0.06; y = -0.3 + row * 0.3 + (R() - 0.5) * 0.06;
  } else if (f === 2) {    // one bull's-eye: every drop lands in the same place (agate hops to a new nodule now and then)
    if (c.recipe === 8 && k > 0 && k % (2 + (c.ang0 & 1)) === 0) c.fc = [(R() - 0.5) * 1.3, (R() - 0.5) * 0.6];
    x = c.fc[0]; y = c.fc[1];
  } else if (f === 3) {    // scattered, but never on top of the last few
    let best = null, bd = -1;
    for (let t = 0; t < 8; t++) {
      const px = (R() - 0.5) * 1.6, py = (R() - 0.5) * 0.85; let d = 9;
      for (const q of c.recent) d = Math.min(d, Math.hypot(px - q[0], py - q[1]));
      if (d > bd) { bd = d; best = [px, py]; }
    }
    [x, y] = best;
  } else if (f === 5) {    // colour wells: one per band group, left (bass) to right (air); drops land in their well
    const w = c.wellNext ?? 0, q = c.wells[w];
    x = q[0] + (R() - 0.5) * 0.03; y = q[1] + (R() - 0.5) * 0.03;
  } else if (f === 6) {    // a bouquet: flower spots around a loose arc
    const q = c.bq[c.bqI++ % c.bq.length]; x = q[0]; y = q[1];
  } else if (f === 7) {    // a fantasy landscape: a sun, then trees along the horizon, then birds in the sky
    const n = c.nS - 1;
    if (n === 0) { x = c.sun[0]; y = c.sun[1]; }
    else if (n < 7 || n % 3) { x = -0.9 + ((c.tree++ * 0.618 + c.fa) % 1) * 1.8; y = -0.36 + (R() - 0.5) * 0.12; }
    else { x = (R() - 0.5) * 1.6; y = 0.15 + R() * 0.35; }
  } else {                 // orbit of drops around the centre, with the hub refreshed every lap
    const a = c.fa + k * 2.6928;
    if (k % 7 === 6) { x = c.fc[0]; y = c.fc[1]; } else { x = c.fc[0] + 0.52 * Math.cos(a); y = c.fc[1] + 0.3 * Math.sin(a); }
  }
  const g = marblGrid(x, y); c.recent.unshift(marblXY(g)); if (c.recent.length > 4) c.recent.pop();
  return g;
}
function marblPush(c, o) {
  if (c.ops[0] && c.ops[0].dance) c.ops.splice(1, 0, o); else c.ops.unshift(o);   // (a dancer stays on top: new ink lands under it and dances with it)
  // ops leaving the 3 live slots are frozen at their current shape
  for (let i = 3; i < c.ops.length; i++) {
    const q = c.ops[i]; if (q.done) continue;
    if (q.k === 'comb' || q.k === 'wave' || q.k === 'vort' || q.k === 'rad') q.amp = Math.round(q.amp * marblProg(q, c.tr));
    q.done = true; q.rock = false;
  }
  // (v21: when the list overflows, the oldest stroke goes, never a bath's pour: a bath without its pour shows as a dark sheet)
  while (c.ops.length > marblCAP) { let j = c.ops.length - 1; while (j > 0 && c.ops[j].k === 'flood') j--; c.ops.splice(j, 1); }
}
// freeze everything at its current shape (before a sheet is pulled)
function marblSettle(c) {
  for (const q of c.ops) {
    if (q.done) continue;
    if (q.amp !== undefined) q.amp = Math.round(q.amp * marblProg(q, c.tr));
    if (q.rock) { q.amp = Math.round((q.a0 ?? 15) * q.val); q.rock = false; }
    q.done = true;
  }
}
// well: undefined for a kick in an ordinary bath, or the band group 0..5 of a colour well
function marblSite(c, F, R, auto, well) {
  const dz = c.ops[0] && c.ops[0].dance ? 1 : 0, top = c.ops[dz], rc = c.recipe;
  const busy = marblBusy(c) || c.ops.length >= marblCAP - 1;
  if (busy) {               // the drop still falls and splashes, but dissolves into the pour
    const q = c.recent[0] || [(R() - 0.5) * 1.4, (R() - 0.5) * 0.7];
    if (!c.lift || c.lift.flooded) marblSplash(c, marblGrid(q[0] + (R() - 0.5) * 0.6, q[1] + (R() - 0.5) * 0.4), marblInk(c, F, -1), 1);
    else marblSplash(c, marblGrid((R() - 0.5) * 2, (R() - 0.5) * 1.1), marblInk(c, F, -1), 1);
    return;
  }
  const tr = c.tr + 0.25;   // the ink lands a quarter beat after the hit: until then it is seen falling
  const nS = c.nS++;
  if (c.form === 5) {
    const w = well ?? (c.wellK = (c.wellK + 1) % 2);
    // the well's drop is still live: the new drop lands inside it (one more ring of its bull's-eye); a band drop into
    // a well that is not live only splashes (it is seen and rippled, but the print is not rewritten every half beat)
    const st = c.ops.find((q, i) => i < 3 && q.k === 'site' && q.well === w && !q.done);
    if (st && st.n < 4) { st.n++; st.t0 = tr; st.dur = 0.42; marblSplash(c, st.g, st.n % 2 ? st.cA : st.cB, st.sz); return; }
    if (well !== undefined && w > 1 && c.tr - (c.wellNew || -9) < 2.5) { marblSplash(c, marblGrid(c.wells[w][0], c.wells[w][1]), w, 1); return; }
    if (w > 1) c.wellNew = c.tr;
    c.wellNext = w;
    const sz = Math.max(0, Math.min(3, (w < 2 ? 2 : 1) + ((F.kick || 0) > 0.85 && w < 2 ? 1 : 0) - (auto ? 1 : 0)));
    const o = { k: 'site', g: marblSitePos(c, R), n: 1, cA: w, cB: w === 5 ? 0 : 5, sz, well: w, t0: tr, dur: 0.42, ease: 'out' };
    marblPush(c, o); marblSplash(c, o.g, w, sz); return;
  }
  if (rc === 6 || rc === 8) {
    // suminagashi / agate: a many-ringed drop; agate varies band count, size and sequence and hops between nodules
    const sumi = rc === 6, thick = !sumi && nS % 2 === 1;
    const o = { k: 'multi', g: marblSitePos(c, R), nr: sumi ? 2 + Math.floor(R() * 8) : (thick ? Math.floor(R() * 3) : 3 + Math.floor(R() * 8)),
      seq: sumi ? Math.floor(R() * 3) : 4 + ((c.agS + nS) % 4),
      sz: Math.max(2, Math.min(7, (sumi ? 3 : 3 + (thick ? 1 : 0)) + Math.floor(R() * 3) + ((F.kick || 0) > 0.85 ? 1 : 0) - (auto ? 1 : 0))), t0: tr, dur: 0.6, ease: 'out' };
    marblPush(c, o); marblSplash(c, o.g, sumi ? 0 : 5, 3); return;
  }
  if (rc === 7 && nS < 5 + c.form % 2) {
    // stone (battal): brushfuls of drops sprinkled in layers, coarse to fine, the last with gall (pale rings)
    const L = [[0, 0], [0, 1], [1, 1], [0, 2], [2, 3], [1, 2]][nS], ink = marblInk(c, F, -1);
    marblPush(c, { k: 'spr', md: L[0], sc: L[1] + c.sz0 - 1, sd: Math.floor(R() * 32), cA: L[0] === 1 ? 7 : ink, cB: L[0] === 1 ? 5 : (ink + 3) % 6,
      dens: 1 + Math.floor(R() * 3), rad: L[0] === 1 ? 6 + Math.floor(R() * 2) : 3 + Math.floor(R() * 4), t0: tr, dur: 0.6, ease: 'out' });
    marblSplash(c, marblGrid((R() - 0.5) * 1.4, (R() - 0.5) * 0.7), ink, 0);
    return;
  }
  if (rc === 13 && nS === 0) {   // landscape: the sun first
    const o = { k: 'multi', g: marblSitePos(c, R), nr: 2 + Math.floor(R() * 3), seq: 3, sz: 4 + Math.floor(R() * 2), t0: tr, dur: 0.8, ease: 'out', sun: true };
    marblPush(c, o); marblSplash(c, o.g, 4, 3); return;
  }
  const maxN = c.form === 2 || c.form === 6 ? 4 : 2;
  // the newest site, or the one just under the newest stroke, takes the next kick as a new inner ring
  const st = top && top.k === 'site' ? top : (c.ops[dz + 1] && c.ops[dz + 1].k === 'site' && top && top.k !== 'flood' && !top.rock ? c.ops[dz + 1] : null);
  if (st && st.n < maxN && c.tr - st.t0 < (c.form === 2 || c.form === 6 ? 5 : 2.2) && !(rc === 13 && st.tree)) {
    // the next drop lands inside the last one: it becomes a ring of the bull's-eye
    const c2 = rc === 11 ? (st.n % 2 ? st.cA : (st.n === 1 ? 5 : st.cB)) : marblInk(c, F, st.n % 2 ? st.cB : st.cA);
    if (st.n === 1) st.cB = c2;
    st.n++; st.t0 = tr; st.dur = 0.42; st.done = false;
    marblSplash(c, st.g, c2, st.sz);
    return;
  }
  let ink = marblInk(c, F, -1);
  let sz = c.sz0 + ((F.kick || 0) > 0.85 ? 1 : 0) + ((F.bass || 0) > 0.7 ? 1 : 0) - (auto ? 1 : 0) - (c.sk >= c.gN ? 1 : 0);
  sz = Math.max(0, Math.min(3, sz));
  let metal = R() < 0.12, cB = (ink + 3) % 6;
  if (rc === 11) { ink = [4, 2, 3, 1][nS % 4]; cB = 5; metal = false; sz = Math.max(1, sz); }   // tulips: reds and roses
  const tree = rc === 13 && c.form === 7 && (nS < 7 || nS % 3);
  if (rc === 13) { metal = false; sz = tree ? 0 : 0; ink = tree ? (R() < 0.6 ? 0 : 1) : 0; cB = tree ? 4 : 0; }
  const o = { k: 'site', g: marblSitePos(c, R), n: 1, cA: metal ? 6 : ink, cB, sz, t0: tr, dur: 0.42, ease: 'out', tree: rc === 13 && tree, bird: rc === 13 && !tree };
  marblPush(c, o); marblSplash(c, o.g, o.cA, sz);
}
// a stylus worked locally on the newest drop: tulip/heart pull (s), swirl (v), rose ring (r), flower (f), bird (b),
// carnation (c), tree (u: a pull straight up)
function marblLocal(c, R, j, kinds) {
  const last = c.recent[0] || [0, 0], a0 = c.ang0, kind = kinds[j % kinds.length];
  if (kind === 'v' || kind === 'r') return { k: 'vort', g: marblGrid(last[0], last[1]), amp: (j % 2 ? -1 : 1) * Math.round(9 + 6 * R()), sg: kind === 'r' ? 1 + Math.floor(R() * 3) : 1 + Math.floor(R() * 2), ring: kind === 'r' };
  if (kind === 'f' || kind === 'b' || kind === 'c') {
    const md = kind === 'b' ? 2 : (kind === 'c' ? 1 : [0, 0, 1, 3][Math.floor(R() * 4)]);
    return { k: 'rad', g: marblGrid(last[0], last[1]), ns: kind === 'c' ? 4 + Math.floor(R() * 4) : Math.floor(R() * 6), amp: (md === 1 && kind !== 'c' && R() < 0.5 ? -1 : 1) * (5 + Math.floor(R() * 3)), md, ph: Math.floor(R() * 2) };
  }
  const up = kind === 'u';
  const ang = up ? 8 : (a0 + (j % 2) * 8 + (R() < 0.35 ? 4 : 0)) % 16, th = ang * Math.PI / 16, d0 = -Math.sin(th) * last[0] + Math.cos(th) * last[1];
  return { k: 'comb', ang, sp: 0, amp: up ? 6 + Math.floor(R() * 3) : (j % 2 ? -1 : 1) * Math.round(14 * (0.75 + 0.25 * R())), off: Math.max(0, Math.min(127, Math.round((d0 + 0.65) / 1.3 * 128))), lam: up ? 0 : 1 + Math.floor(R() * 2) };
}
// a Turkish tulip: three stylus pulls fanned through the newest flower (the middle one deepest)
function marblTulip(c, R) {
  const last = c.recent[0] || [0, 0], ang = (8 + (R() < 0.5 ? -1 : 1) * Math.floor(R() * 2)) % 16, th = ang * Math.PI / 16;
  const d0 = -Math.sin(th) * last[0] + Math.cos(th) * last[1], sgn = R() < 0.7 ? -1 : 1, w = 0.05 + 0.03 * R();
  for (let i = 0; i < 3; i++) {
    const d = d0 + (i - 1) * w, o = { k: 'comb', ang, sp: 0, amp: sgn * (i === 1 ? 9 : 6), off: Math.max(0, Math.min(127, Math.round((d + 0.65) / 1.3 * 128))), lam: 1 };
    o.t0 = c.tr + [0.15, 0, 0.3][i]; o.dur = 0.7; o.ease = 'io'; marblPush(c, o);
  }
}
function marblStroke(c, F, R) {
  if (c.ops.length >= marblCAP - 3 || (c.lift && !c.lift.flooded)) return;
  const k = c.sk++, rc = c.recipe, a0 = c.ang0, alt = k % 2 ? -1 : 1, tr = c.tr;
  const amp = (A) => alt * Math.round(A * (0.75 + 0.25 * R()));
  let o;
  if (c.gold && k === c.gold) {
    // gold (or silver) leaf laid on the bath, to be combed into the pattern by the next strokes
    const ag = c.silver ? 7 : 6;
    o = { k: 'spr', md: 3, sc: 2 + Math.floor(R() * 3), sd: Math.floor(R() * 32), cA: ag, cB: ag, dens: Math.floor(R() * 3), rad: 4 + Math.floor(R() * 4), t0: tr, dur: 0.7, ease: 'out' };
    marblPush(c, o); return;
  }
  if (rc === 6) {          // suminagashi: breath and fan: soft waves, swirls and rose rings, never a comb
    if (k % 3 === 2) o = marblLocal(c, R, k, ['r', 'v']);
    else o = { k: 'wave', ang: Math.floor(R() * 16), sp: 1 + Math.floor(R() * 3), amp: amp(7), off: Math.floor(R() * 128), lam: 0 };
  } else if (rc === 7) {   // stone: a gentle shawl wave now and then, a flower or rose in the stones
    if (k % 3 === 2) o = marblLocal(c, R, k, ['f', 'r']);
    else o = { k: 'wave', ang: (a0 + 8 * (k % 2)) % 16, sp: 2 + Math.floor(R() * 3), amp: amp(5), off: Math.floor(R() * 128), lam: 0 };
  } else if (rc === 8) {   // agate: bands bent by slow waves, swirls, rose rings and fortification zig-zags
    const last = c.recent[0] || c.fc || [0, 0], s = k % 4;
    if (s === 1) o = { k: 'vort', g: marblGrid(last[0], last[1]), amp: alt * Math.round(6 + 5 * R()), sg: 3 + Math.floor(R() * 3) };
    else if (s === 3) o = R() < 0.5 ? marblLocal(c, R, k, ['r']) : { k: 'wave', ang: Math.floor(R() * 16), sp: 4 + Math.floor(R() * 2), amp: amp(10), off: Math.floor(R() * 128), lam: 1 };
    else o = { k: 'wave', ang: Math.floor(R() * 16), sp: 1 + Math.floor(R() * 3), amp: amp(11), off: Math.floor(R() * 128), lam: R() < 0.3 ? 3 : 0 };
  } else if (rc === 13) {  // landscape: mountain ranges, then cypresses pulled up from the trees, birds in the sky
    if (k === 0) o = { k: 'wave', ang: 8, sp: Math.floor(R() * 2), amp: 11 + Math.floor(R() * 4), off: Math.floor(R() * 128), lam: 2 + Math.floor(R() * 2) };
    else if (k === 1) o = { k: 'wave', ang: 8, sp: 2 + Math.floor(R() * 2), amp: -(6 + Math.floor(R() * 4)), off: Math.floor(R() * 128), lam: 1 };
    else {
      const nw = c.ops.find(q => q.k === 'site' || q.k === 'multi');
      o = marblLocal(c, R, k, nw && nw.bird ? ['b'] : (nw && nw.sun ? ['r'] : ['u']));
    }
  } else if (rc === 12) {  // peacock: gel-git, the cross pass, nonpareil, then the serpentine pass that draws the eyes
    const s = Math.min(k, 7);
    if (s < 2) o = { k: 'comb', ang: a0, sp: c.sp0, amp: amp(13), off: s % 2 ? 64 : 0, lam: 1 };
    else if (s < 4) o = { k: 'comb', ang: (a0 + 8) % 16, sp: c.sp0, amp: amp(13), off: s % 2 ? 64 : 0, lam: 1 };
    else if (s === 4) o = { k: 'comb', ang: a0, sp: 6, amp: 12, off: 32, lam: 1 };
    else if (s === 5) { c.pkOff = Math.floor(R() * 128); o = { k: 'wave', ang: (a0 + 8) % 16, sp: 2 + (c.sp0 > 2 ? 1 : 0), amp: 13, off: c.pkOff, lam: 0 }; }
    else if (s === 6) o = { k: 'wave', ang: (a0 + 8) % 16, sp: 2 + (c.sp0 > 2 ? 1 : 0), amp: -13, off: (c.pkOff + 64) % 128, lam: 0 };
    else o = marblLocal(c, R, k, ['f', 'v', 's']);
  } else if (rc === 11) {  // tulips and carnations: a stirred ground, then each new flower is pulled into a tulip or a carnation
    if (k === 0) o = { k: 'wave', ang: a0, sp: 1, amp: amp(8), off: Math.floor(R() * 128), lam: 0 };
    else if (k % 3 !== 2) { marblTulip(c, R); return; }
    else o = marblLocal(c, R, k, ['c', 'f']);
  } else if (k < 2 && rc !== 0 && rc !== 5) {
    // every other bath starts like a marbler's: one gel-git pass, back and forth, over the fresh ground
    o = { k: 'comb', ang: c.ang0, sp: c.sp0, amp: amp(13), off: k % 2 ? 64 : 0, lam: 1 };
  } else if (rc === 9) {   // flower garden (cicekli): petals pulled through the newest drops, tulips, roses
    o = marblLocal(c, R, k, ['f', 's', 'c', 'r']);
  } else if (rc === 10) {  // birds: wings pulled out of the newest drops, with stylus leaves between
    o = marblLocal(c, R, k, ['b', 's', 'b', 'f']);
  } else if (k >= c.gN && rc !== 2) {
    // the ground is combed: from here snares work locally on the newest drops, so the bath keeps flowering
    // instead of being shredded into noise
    o = marblLocal(c, R, k - c.gN, ['s', 's', 'v', 'f', 'c']);
  } else if (rc === 0) {   // gel-git, then nonpareil: back-and-forth combs, offset by half a tine, finer each pass
    const ph = Math.floor(k / 2), sp = Math.min(6, c.sp0 + (ph >= 2 ? 1 : 0));
    o = { k: 'comb', ang: (a0 + 8 * (ph % 2)) % 16, sp, amp: amp(13), off: (k % 2 ? 64 : 0) + (ph * 23) % 64, lam: 1 };
  } else if (rc === 1) {   // bouquet: gel-git ground, then fine waves across it
    if (k < 4) o = { k: 'comb', ang: a0, sp: c.sp0, amp: amp(14), off: k % 2 ? 64 : 0, lam: 1 };
    else o = { k: 'wave', ang: (a0 + 8) % 16, sp: Math.min(7, 3 + Math.floor((k - 4) / 2)), amp: amp(12), off: Math.floor(R() * 128), lam: 0 };
  } else if (rc === 2) {   // tulips and hearts: a single stylus dragged through the newest drops
    o = marblLocal(c, R, k, ['s', 's', 'v', 's', 's', 'f']);
  } else if (rc === 3) {   // hatip: swirls and stylus pulls worked locally on the newest drops, over the gel-git ground
    o = marblLocal(c, R, k, ['v', 's', 'r', 's']);
  } else if (rc === 4) {   // chevrons: triangle-wave combs alternating across each other, getting finer
    const ph = Math.floor(k / 2);
    o = { k: 'wave', ang: (a0 + 8 * (ph % 2)) % 16, sp: Math.min(5, 2 + ph), amp: amp(15), off: Math.floor(R() * 128), lam: 1 };
  } else {                 // shell: gel-git both ways, then a fine wave comb
    const s = k % 6;
    if (s < 4) o = { k: 'comb', ang: (a0 + (s < 2 ? 0 : 8)) % 16, sp: c.sp0, amp: amp(13), off: s % 2 ? 64 : 0, lam: 1 };
    else o = { k: 'wave', ang: (a0 + (s === 4 ? 0 : 8)) % 16, sp: 5 + Math.floor(R() * 2), amp: amp(9), off: Math.floor(R() * 128), lam: 0 };
  }
  o.t0 = tr; o.dur = o.k === 'vort' ? 1.2 : (o.k === 'wave' ? 1 : (o.k === 'rad' ? 1.1 : 0.8)); o.ease = 'io';
  marblPush(c, o);
}
// recipes: 0 gel-git/nonpareil, 1 bouquet, 2 tulips/hearts, 3 hatip, 4 chevrons, 5 shell, 6 suminagashi, 7 stone,
// 8 agate, 9 flower garden, 10 birds, 11 Turkish tulips & carnations, 12 peacock, 13 fantasy landscape
const marblRecipes = [0, 0, 1, 2, 3, 4, 4, 5, 6, 6, 7, 7, 8, 8, 9, 10, 11, 11, 12, 12, 13, 13];
function marblNewBath(c, R, first, want) {
  let p = c.palC; while (p === c.palC) p = Math.floor(R() * 14);
  if (!first) { c.palP = c.palC; c.styP = c.styC; }
  c.recipe = want ?? marblRecipes[Math.floor(R() * marblRecipes.length)];
  const rc = c.recipe, pick = a => a[Math.floor(R() * a.length)];
  if (rc === 6 && R() < 0.7) p = R() < 0.6 ? 8 : 4;          // suminagashi wants sumi on washi
  if (rc === 8) p = pick([10, 10, 5, 12, 1, 2, 9]);            // agate, malachite, blue lace, peacock, rose, sard
  if (rc === 11 && R() < 0.6) p = pick([13, 13, 0, 9]);
  if (rc === 13) p = R() < 0.55 ? 11 : pick([0, 1, 3, 6, 7, 12]);
  if (p === c.palC) p = (p + 1 + Math.floor(R() * 13)) % 14;
  c.palC = p; c.styC = Math.floor(R() * 4);
  if (rc === 6) c.styC = R() < 0.5 ? 0 : 1;
  if (rc === 13) c.styC = R() < 0.5 ? 0 : 3;
  if (first) { c.palP = p; c.styP = c.styC; }
  c.form = Math.floor(R() * 7); if (c.form === 6) c.form = 5;   // 5: colour wells (twice as likely)
  if (rc === 6 && R() < 0.5) c.form = 2;
  if ((rc === 6 || rc === 8 || rc === 7) && c.form === 5) c.form = 3;
  c.ang0 = Math.floor(R() * 16); c.sp0 = 2 + Math.floor(R() * 3); c.sz0 = 1 + Math.floor(R() * 2); c.gN = 4 + Math.floor(R() * 4); c.nS = 0;
  if (rc === 4 || rc === 12) { c.sz0 = 0; c.form = 1; }   // chevrons and peacock want a striped ground: small drops in rows
  if (rc === 11) { c.form = 6; c.sz0 = 2; }
  if (rc === 13) { c.form = 7; c.tree = 0; c.sun = [(R() < 0.5 ? -1 : 1) * (0.35 + 0.3 * R()), 0.32 + 0.12 * R()]; }
  c.gold = (c.styC === 2 || R() < 0.25) && rc !== 6 && rc !== 13 ? 2 + Math.floor(R() * 3) : 0;
  c.silver = p === 4 || p === 8 || p === 12 || R() < 0.3;
  c.bathLen = [6, 8, 8, 8, 12][Math.floor(R() * 5)];
  c.fk = 0; c.fa = R() * 6.28; c.fc = c.form === 2 ? [(R() - 0.5) * 0.5, (R() - 0.5) * 0.25] : [(R() - 0.5) * 0.4, (R() - 0.5) * 0.2];
  c.agS = Math.floor(R() * 4);
  // colour wells: six spots across the sheet, a gentle zig-zag; bouquet: flower spots around a loose arc
  const wy = (R() - 0.5) * 0.2, wz = 0.1 + 0.12 * R();
  c.wells = [0, 1, 2, 3, 4, 5].map(w => [-1.0 + w * 0.4, wy + (w % 2 ? wz : -wz)]); c.wellK = 0;
  const sp = [[-0.55, 0.05], [0.05, 0.22], [0.6, 0.0], [-0.25, -0.3], [0.32, -0.32], [-0.85, -0.2], [0.85, 0.28]];
  c.bq = sp.map(q => [q[0] + (R() - 0.5) * 0.12, q[1] + (R() - 0.5) * 0.1]); c.bqI = Math.floor(R() * 3);
  if (c.xform !== undefined) c.form = c.xform;
  if (c.xgold) { c.gold = 1; c.silver = c.xgold === 2; }
  c.sk = 0; c.bathBars = 0; c.held = 0;
  // the bath's dancer (v21): which move, and on which bar it joins in. The choice leans on what this music is made of
  // (kicks, snares, bass weight, hats: running rates kept in c.mu), so two songs do not get the same dances.
  if (c.cam) {
    const r = c.cam.r, m = c.mu || [1, 1, 1, 1], w = [0.9, 0.3 + m[0], 0.3 + m[1], 0.4 + m[0], 0.3 + m[2], 0.2 + m[3]];
    if (rc === 6 || rc === 13) { w[1] = w[2] = w[4] = w[5] = 0; w[0] = 2; } if (rc === 11) w.fill(0, 1); if (rc === 4 || rc === 12) w[4] = 0;
    let x = r() * w.reduce((a, v) => a + v, 0), k = 0; while (k < 5 && (x -= w[k]) > 0) k++;
    c.dnKind = c.xdn ?? k; c.dnBar = first ? 3 : Math.floor(r() * 2);
  }
}
// kinds: 1 shimmy (a wave that steps side to side on the kick), 2 twist (a swirl wound a notch on every snare), 3 bloom (petals
// that open on the kick and ease back), 4 chevron pump (zig-zags as deep as the bassline), 5 shiver (a fine comb flicked by the hats)
function marblDanceStart(c) {
  const r = c.cam.r, k = c.dnKind, last = c.recent[0] || c.fc || [0, 0], g = marblGrid(last[0], last[1]), rnd = n => Math.floor(r() * n);
  let o;
  if (k === 1) o = { k: 'wave', ang: (c.ang0 + 4 + rnd(9)) % 16, sp: 3 + rnd(2), amp: 7 + rnd(4), off: rnd(128), lam: 0 };
  else if (k === 2) o = { k: 'vort', g, amp: 11, sg: 4 + rnd(3) };
  else if (k === 3) o = { k: 'rad', g, ns: rnd(6), amp: 6, md: [0, 1, 3][rnd(3)], ph: rnd(2) };
  else if (k === 4) o = { k: 'wave', ang: (c.ang0 + 8 * rnd(2)) % 16, sp: 2, amp: 10, off: rnd(128), lam: 1 };
  else o = { k: 'comb', ang: (c.ang0 + 8) % 16, sp: 6, amp: 6, off: rnd(128), lam: 1 };
  Object.assign(o, { rock: true, dance: true, val: 0, a0: o.amp, t0: c.tr, dur: 1, ease: 'io' });
  marblPush(c, o); c.dn = { op: o, k, s: { x: 0, v: 0 }, tgt: k === 3 ? 0.35 : 0, dir: r() < 0.5 ? -1 : 1, env: 0 };
}
function marblDanceStop(c) {
  const d = c.dn; if (!d) return; c.dn = null;
  if (!d.op.done) { d.op.amp = Math.round(d.op.a0 * d.op.val); d.op.done = true; } d.op.rock = false; d.op.dance = false;
}
// one frame of the dance. ev: kick, hit and hat onsets this frame
function marblDance(c, F, dt, kw, ev) {
  const d = c.dn, o = d.op;
  if (o.done || c.ops[0] !== o) { marblDanceStop(c); return; }
  let w = 12;
  if (d.k === 1) { if (ev.kick) { d.dir = -d.dir; d.tgt = d.dir; } w = 15; }
  else if (d.k === 2) { if (ev.hit) { if (Math.abs(d.tgt + d.dir * 0.24) > 1) d.dir = -d.dir; d.tgt += d.dir * 0.24; } if (ev.bar && c.cam.r() < 0.3) d.dir = -d.dir; w = 10; }
  else if (d.k === 3) { if (ev.kick) d.env = 1; d.env *= Math.exp(-dt * 3.2); d.tgt = 0.3 + 0.7 * d.env; w = 18; }
  else if (d.k === 4) { d.tgt = 0.12 + 0.88 * Math.min(1, c.sw * 1.2); w = 9; }
  else { if (ev.hat) { d.dir = -d.dir; d.tgt = d.dir * (0.55 + 0.45 * Math.min(1, F.hat || 0)); } w = 22; }
  marblSpr(d.s, d.tgt, w * kw, dt); o.val = Math.max(-1, Math.min(1, d.s.x));
}
function marblFlood(c, R, drop, want, from) {
  if (c.ops[0] && c.ops[0].k === 'flood' && !c.ops[0].done) return;
  marblNewBath(c, R, false, want);
  let x = 0, y = 0;
  if (c.recipe === 13) { x = (R() - 0.5) * 0.6; y = -0.8; }        // a landscape is poured from below the horizon
  else if (from !== undefined) { x = from[0]; y = from[1]; }
  else if (drop) { x = (R() - 0.5) * 0.5; y = (R() - 0.5) * 0.3; }
  else { const e = Math.floor(R() * 4); x = e < 2 ? (e ? 1.25 : -1.25) : (R() - 0.5) * 1.6; y = e < 2 ? (R() - 0.5) * 0.6 : (e === 2 ? 0.78 : -0.78); }
  const land = c.recipe === 13;
  const o = { k: 'flood', g: marblGrid(x, y), nr: land ? 4 + Math.floor(R() * 6) : Math.floor(R() * 16), pat: c.recipe === 6 ? 2 + 4 * Math.floor(R() * 2) : (land ? (R() < 0.6 ? 0 : 5) : Math.floor(R() * 8)),
    gm: Math.floor(R() * 4), bead: !land && c.recipe !== 6 && R() < 0.6, t0: c.tr, dur: drop ? 1.1 : 2.6, ease: 'pour', phrase: !drop };
  c.ops.unshift(o);
  for (let i = 1; i < c.ops.length; i++) { const q = c.ops[i]; if (!q.done) { if (q.amp !== undefined) q.amp = Math.round(q.amp * marblProg(q, c.tr)); q.done = true; q.rock = false; } }
  c.recent = [];
  // the marbler works the pour at once: the bath's first stroke rides the streaming rings, so a fresh bath is never
  // a field of plain circles
  const n = c.ops.length; marblStroke(c, {}, R);
  if (c.ops.length > n) { const s = c.ops[0]; s.t0 = c.tr + (drop ? 0.25 : 0.15); s.dur = drop ? 1.5 : 2.6; s.pour = true; }
  c.lastHit = c.tr;
}
// a print is pulled: the sheet lifts off the bath about one edge and turns over, the bath is left with a ghost of the
// print, then a fresh bath is poured from the hinge side
function marblLift(c, R) {
  if (c.lift) return;
  marblSettle(c);
  const side = c.xls ?? (R() < 0.6 ? 2 : Math.floor(R() * 2));   // mostly hinged at the top: the gallery recedes upward
  c.lift = { t0: c.tr, side, flooded: false }; c.lastLift = c.tr;
}
// a mature bath for the first frame of a visit: a flood combed and dropped into by the bath's own recipe
function marblPrepare(c, R) {
  marblNewBath(c, R, true);
  const tr = c.tr;
  c.ops = [{ k: 'flood', g: marblGrid((R() - 0.5) * 0.6, c.recipe === 13 ? -0.8 : (R() - 0.5) * 0.3), nr: 6 + Math.floor(R() * 10), pat: c.recipe === 13 ? 0 : Math.floor(R() * 8), gm: Math.floor(R() * 4), bead: R() < 0.4, done: true }];
  const F0 = { cent: 0.45, kick: 0.7, bass: 0.5 };
  const steps = 8 + Math.floor(R() * 6);
  for (let i = 0; i < steps; i++) {
    c.tr = tr - 40 + i;
    if (i % 3 === 2 || i === 0) marblStroke(c, F0, R);
    else { F0.cent = c.cLo + R() * (c.cHi - c.cLo); marblSite(c, F0, R, false, c.form === 5 ? Math.floor(R() * 6) : undefined); }
    for (const q of c.ops) q.done = true;
  }
  c.tr = tr; c.spl = [{ g: [0, 0], t: -99, ink: 0, sz: 0 }, { g: [0, 0], t: -99, ink: 0, sz: 0 }];
}
