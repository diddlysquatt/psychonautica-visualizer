  {
    key: 'lattice', cont: ['er', 'fa'], name: 'LED 06', src: R_LATTICE, cost: 2.4,
    fb: { zoom: 0.0018, rot: 0.0004, decay: 0.7, warp: 0.2, echo: 0.45, droste: 0, win: 0.75, key: 0.3, live: 0.5 },
    // Auto folds about one visit in six: 6 and 8 turn the starburst vertices into star mandalas
    syms: [0, 0, 0, 0, 0, 0, 0, 0, 6, 8, 5, 12], kalZoom: 0.7,
    auto: { kal: [0], kalCycle: false, kalZoom: 0.7, transitions: ['melt', 'portal'], notes: 'v12: calmer flight, LED programs, palette families and honeycomb reboots; 0 first (the protected look), 6/8/5 star mandalas best, 12/4/3 good; 16 busy, 2 plain' },
    init: (s) => {
      // compact honeycombs (finite cells and vertices) and paracompact ones whose vertices sit on the sphere at
      // infinity, where the LED tubes converge into endless starbursts
      const c = { L: LED6.rot([s[2] - 0.5, s[3] - 0.5, 0.3], s[1] * 6.283), er: 0.0055 + s[2] * 0.004, fa: 0.8 + s[3] * 0.5, hb: (s[0] * 7.31) % 1, fov: -0.8 - s[3] * 1.2, rip: 9, tgt: null, lt: null, roll: (s[2] - 0.5) * 0.1, faNow: 1, kAmp: 0 };
      // v12: the visit's own director (seeded stream): LED programs, palette families, honeycomb reboots, set pieces
      let sd = Math.floor((s[0] * 0.37 + s[1] * 0.63) * 2147483646) + 11;
      c.dr = () => { sd = (sd * 48271) % 2147483647; return sd / 2147483647; };
      latticeSetHC(c, Math.floor(s[0] * 8), s[1]);
      c.prog = Math.floor(c.dr() * LED6_PROGS); c.progB = c.prog; c.progT = 1; c.bars = 0;
      c.spread = 0.12; c.spreadNow = c.spread; c.hbT = c.hb; c.hbNow = c.hb;   // a visit opens in the classic look
      c.boot = 1; c.bootT = 1; c.reboot = 0; c.nextReboot = 24 + Math.floor(c.dr() * 16);
      c.ev = 0; c.evA = 0; c.evEnd = 0; c.nextEv = 12 + Math.floor(c.dr() * 20);
      c.log = { prog: 0, pal: 0, reboot: 0, ev: 0 };
      return c;
    },
    frame(V, F, dt) {
      const c = V.c, M = LED6, dr = c.dr || Math.random;
      if (c.lt === null) c.lt = V.trav;
      const dTr = clamp(V.trav - c.lt, 0, 0.5); c.lt = V.trav;
      // v12: the engine's beat surge of V.trav is averaged out (1.4 s), so the flight glides instead of lurching on every
      // beat, and it is slower: about a quarter of a cell per beat instead of a half
      const trR = dt > 0 ? dTr / dt : 0;
      c.trS = Number.isFinite(c.trS) ? c.trS + (Math.min(trR, 6) - c.trS) * (1 - Math.exp(-dt / 1.4)) : Math.min(trR, 6);
      // --- director: every 8 bars the next LED program fades in over a bar; every 16 bars a palette family; now and then
      // the honeycomb reboots (the lights go out from far to near, a new tiling boots up from near to far); rare set pieces
      if ((F.onBar || F.onSceneBar)) {
        c.bars++;
        if (c.bars % 8 === 0 && c.progT >= 1) {
          let n = Math.floor(dr() * (LED6_PROGS - 1)); if (n >= c.prog) n++;
          if (F.build > 0.3) n = 1;   // a build turns every diode into an equaliser
          if (n !== c.prog) { c.progB = c.prog; c.prog = n; c.progT = 0; c.log.prog++; }
        }
        if (c.bars % 16 === 4) { c.hbT += 0.18 + dr() * 0.3; c.spread = [0.12, 0.04, 0.22, 0.12][Math.floor(dr() * 4)]; c.log.pal++; }
        if (!c.reboot && c.bars >= c.nextReboot && F.build < 0.2) { c.reboot = 1; c.bootT = 0; c.nextReboot = c.bars + 32 + Math.floor(dr() * 32); c.log.reboot++; }
        if (!c.ev && c.bars >= c.nextEv && F.build < 0.2 && !c.reboot) { c.ev = 1 + Math.floor(dr() * 3); c.evEnd = c.bars + 4; c.nextEv = c.bars + 20 + Math.floor(dr() * 28); c.log.ev++; }
        if (c.ev && c.bars >= c.evEnd) c.evEnd = -1;
      }
      if (F.onDrop && !c.reboot && dr() < 0.5) { c.reboot = 1; c.bootT = 0; c.log.reboot++; }
      c.progT = Math.min(1, c.progT + dt / 1.7);
      // reboot: lights fade out (far first), the new honeycomb is swapped in while dark, then boots up near to far
      if (c.reboot === 1) { c.boot = Math.max(0, c.boot - dt / 0.9); if (c.boot <= 0) { latticeSetHC(c, Math.floor(dr() * 8), dr()); c.reboot = 2; } }
      else if (c.reboot === 2) { c.boot = Math.min(1, c.boot + dt / 2.2); if (c.boot >= 1) c.reboot = 0; }
      const evOn = c.ev && c.evEnd >= 0 ? 1 : 0;
      c.evA += (evOn - c.evA) * (1 - Math.exp(-dt * (evOn ? 1.5 : 1)));
      if (!evOn && c.evA < 0.01) { c.ev = 0; c.evA = 0; }
      c.hbNow += (c.hbT - c.hbNow) * (1 - Math.exp(-dt / 5));
      c.spreadNow += (c.spread - c.spreadNow) * (1 - Math.exp(-dt / 4));
      const H = c.H;
      const msm = clamp(Number(S.motionSmooth) || 0, 0, 1), bassL = clamp(Number(F.bassS ?? F.bass) || 0, 0, 1), lvlL = clamp(Number(F.levelS ?? F.level) || 0, 0, 1);
      { const paceT = 0.5 + 0.25 * bassL * bassL + 0.15 * lvlL + 0.3 * clamp(F.build || 0, 0, 1) - 0.2 * clamp(F.breakdown || 0, 0, 1);
        if (!Number.isFinite(c.pace) || !Number.isFinite(c.paceV)) { c.pace = paceT; c.paceV = 0; }
        if (F.onKick) c.paceV += 7 * (0.6 + 0.4 * Math.min(1, F.kick || 0)) * (1 - 0.35 * msm);   // peaks about half a pace unit above the glide a fifth of a second later, then eases
        const w = 5.5 - 2 * msm, dd = c.pace - paceT, tmp = (c.paceV + w * dd) * dt, e = Math.exp(-w * dt);
        c.pace = clamp(paceT + (dd + tmp) * e, 0.3, 2.2); c.paceV = clamp((c.paceV - w * tmp) * e, -12, 12);
        // a twist about the gaze on every other bar (alternating sides) and a bigger one on a drop: an impulse that eases away (exact exponential), never a steady spin
        if (!Number.isFinite(c.twist)) c.twist = 0;
        if ((F.onBar || F.onSceneBar) && c.bars % 2 === 0) c.twist += (c.bars % 4 === 0 ? 1 : -1) * (0.35 + 0.5 * lvlL) * (1 - 0.6 * msm);
        if (F.onDrop) c.twist += (c.twist >= 0 ? 1 : -1) * 0.9 * (1 - 0.6 * msm);
        c.twist = clamp(c.twist * Math.exp(-dt * 1.8), -1.6, 1.6); }
      const ds = c.trS * dt * H.dCell * 0.26 * c.pace + dt * 0.03 * S.speed;
      let L = c.L, Li = M.inv(L);
      const camDir = (X) => { const y = M.toBall(M.apply(Li, X)); return v3.norm(y); };
      // v18: the flight rides the rail through the open cells (see LED6.railMk); the view looks along it about a second ahead
      if (!c.rail) {
        const f0 = H.faces[Math.floor(dr() * H.faces.length) % H.faces.length];
        c.rail = { q: [M.railMk(H, M.id(), f0, dr)], u: 0.12 };
        // set on arrival (lights are out at a reboot, and the first frame of a visit has no past): on the rail, looking along it
        const p0 = M.toBall(M.apply(Li, M.railAt(H, c, 0, dr))), r0 = Math.hypot(p0[0], p0[1], p0[2]);
        if (r0 > 1e-6) L = M.mul(L, M.boost(v3.norm(p0), 2 * Math.atanh(Math.min(r0, 0.999))));
        const a0 = M.toBall(M.apply(M.inv(L), M.railAt(H, c, 0.9, dr))), an = v3.norm(a0), g0 = Math.acos(clamp(an[2], -1, 1));
        if (g0 > 1e-3) L = M.mul(L, M.rot(v3.cross([0, 0, 1], an), g0));
        Li = M.inv(L); c.om = null;
      }
      const look = 0.9, d = camDir(M.railAt(H, c, look, dr)), ang = Math.acos(clamp(d[2], -1, 1));
      let wv = [0, 0, 0];
      if (ang > 1e-4) { const ax = v3.norm(v3.cross([0, 0, 1], d)), g = Math.min(ang * 2.2, 1.3); wv = [ax[0] * g, ax[1] * g, ax[2] * g]; }
      c.roll += (((F.midS ?? F.mid) - 0.35) * 0.04 + PTR.x * 0.08 * PTR.inf - c.roll) * (1 - Math.exp(-dt * 0.4));
      // banks into the turns, so the rounding of a corner reads as going around
      const bankT = clamp(-d[0] * 1.2, -0.5, 0.5);
      c.bank = Number.isFinite(c.bank) ? c.bank + (bankT - c.bank) * (1 - Math.exp(-dt / 0.8)) : bankT;
      wv[2] += c.roll * 0.5 + 0.04 * Math.sin(V.mt * 0.07) + c.bank * 0.55 + c.twist;   // v20b: banks harder into the turns; the bar twist
      if (!c.om) c.om = wv.slice();
      const ke = 1 - Math.exp(-dt / (0.35 + 0.35 * clamp(Number(S.motionSmooth) || 0, 0, 1)));
      c.om = c.om.map((x, i) => x + (wv[i] - x) * ke);
      const oml = Math.hypot(c.om[0], c.om[1], c.om[2]);
      if (oml > 1e-6) L = M.mul(L, M.rot(c.om, oml * dt));
      M.railAdv(H, c, ds, dr);
      { const p1 = M.toBall(M.apply(M.inv(L), M.railAt(H, c, 0, dr))), r1 = Math.hypot(p1[0], p1[1], p1[2]);
        if (r1 > 1e-7) L = M.mul(L, M.boost(v3.norm(p1), 2 * Math.atanh(Math.min(r1, 0.999)))); }
      const G = M.renorm(H, M.toBall([L[3], L[7], L[11], L[15]]));
      if (G) { L = M.mul(G, L); for (const s of c.rail.q) s.T = M.mul(G, s.T); }
      c.L = L = M.orth(L);
      c.rip += dt * (2.4 + 3 * F.build) * S.speed; if (F.onKick) { c.rip = 0; c.kAmp = (0.45 + 0.3 * Math.min(1, F.kick)) * (0.3 + 0.7 * S.flashes); }
      // membranes thin out on a drop so the view bursts open, thicken through a build
      c.faNow += ((1 + 0.5 * F.build - 0.5 * F.drop) - c.faNow) * (1 - Math.exp(-dt * 1.2));
      // v13 wheel zoom-in: the view dollies forward along the gaze (up to ~half a cell at 2.5) while the lens narrows, so
      // the next cell's tubes, diodes and glass come close with their full detail (only the rendered camera moves)
      { const zi = Math.min(1, Math.max(0, Math.log(Math.max(PTR.zoom || 1, 1)) / Math.log(2.5)));
        if (zi > 0) { // v18: the dolly slides along the rail, not straight down the gaze: it can no longer drive into a tube
          const D = 0.5 * H.dCell * zi * (2 - zi), pd = M.toBall(M.apply(M.inv(L), M.railAt(H, c, D, dr))), rd = Math.hypot(pd[0], pd[1], pd[2]);
          if (rd > 1e-7) L = M.mul(L, M.boost(v3.norm(pd), 2 * Math.atanh(Math.min(rd, 0.999))));
          const aim = v3.norm(M.toBall(M.apply(M.inv(L), M.railAt(H, c, D + look, dr)))), ga = Math.acos(clamp(aim[2], -1, 1));
          if (ga > 1e-3) L = M.mul(L, M.rot(v3.cross([0, 0, 1], aim), ga * zi));
        } }
      V.m1 = new Float32Array([L[0], L[4], L[8], L[1], L[5], L[9], L[2], L[6], L[10]]);
      V.p1 = [c.HC[0], c.HC[1], c.HC[2], c.fov];
      V.p2 = [c.rip, F.beat, c.fa * c.faNow, c.er]; // y: a light pulse runs along every LED strip once per beat
      const LL = latticeLens(V, c.fov);
      V.p3 = [c.ps[0], c.ps[1], Math.min(0.99, c.kAmp || 0) + 2 * Math.round(LL[1] * 400), c.hbNow + V.mt * 0.004]; // z: kick comet strength (fraction) + 2 x the wide lens amount (0..400)
      V.p4 = [L[3], L[7], L[11], L[15]];
      V.p5 = [L[12], L[13], L[14], Math.min(c.evA, 0.999) + 2 * (c.ev || 0)];   // w: set piece (amount + 2 x kind)
      // lights only: per-band onsets above the broadband onset, in four pairs (sub+bass .. high+air) for ledOn()
      const o = BANDS.on, om = (o[0] + o[1] + o[2] + o[3] + o[4] + o[5] + o[6]) / 7, oq = (a, b) => Math.max(0, Math.max(o[a], o[b]) - om);
      const pt = c.progT * c.progT * (3 - 2 * c.progT);
      // v20b neurons: a band pair's onset fires a pulse (rate-limited, so pulses stay apart); its age runs in half-edges of travel, faster when the music is loud
      if (!c.na) c.na = [9, 9, 9, 9];
      for (let k = 0; k < 4; k++) { c.na[k] = Math.min(7.99, c.na[k] + dt * (1.5 + 0.9 * lvlL));
        if ((Math.max(o[2 * k], o[2 * k + 1]) > 0.45 || (k === 0 && F.onKick) || (k === 3 && (F.hat || 0) > 0.7)) && c.na[k] > 0.6) c.na[k] = 0; }
      const nP = (a, b) => Math.floor(clamp(a, 0, 7.99) * 128) + 1024 * Math.floor(clamp(b, 0, 7.99) * 128);
      V.m2 = new Float32Array([oq(0, 1), oq(2, 3), oq(4, 5), oq(6, 7), LL[0], nP(c.na[0], c.na[1]), nP(c.na[2], c.na[3]),
        c.progB * 8 + c.prog + Math.min(pt, 0.999), Math.round(c.boot * 63) + Math.min(0.99, c.spreadNow * 4)]);
      c.dbg = 'p' + c.prog + ' hc' + c.HC.join('') + ' ev' + c.ev + ' b' + c.boot.toFixed(2);
    }
  },
