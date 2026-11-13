  {
    key: 'gate', cont: ['tw', 'rot', 'hue', 'fh', 'fa', 'fb'], name: 'MUMM3', src: R_GATE, cost: 1.4,
    fb: { zoom: 0.0045, rot: 0, decay: 0.72, warp: 0.45, echo: 0.45, droste: 0, win: 0.85, key: 0.22 },
    // Auto folds a quarter of visits into a jewelled mandala (6, 8, 5 were the best folds; the mirror doubles the core)
    syms: [0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 8, 5], kalZoom: 0.7,
    // v12 Auto Show: every fold 5-16 is a full jewelled mandala at kalZoom .7 on all seeds (v12/b0_kal); 2-4 copy the
    // core portal off-centre, so they stay out. Unfolded first: the funnel is the hero
    auto: { tier: 1, kind: 'tunnel', kal: [0, 6, 8, 5, 12, 16], kalCycle: true, kalZoom: 0.7, bars: 32, transitions: ['portal', 'vortex'],
      notes: 'v12: unfolded hero; 6/8/5 jewelled mandalas, 12/16 rose windows; 2/3/4 duplicate the core' },
    init: (s) => {
      // two lattices: golden-angle phyllotaxis (Fibonacci parastichies) or staggered petal rings
      const phy = s[2] < 0.6;
      const fib = [[8, 13], [13, 21], [13, 21], [21, 34]][Math.floor(s[0] * 4)];
      return {
        N: [13, 16, 18, 21, 21, 24, 26, 34][Math.floor(s[0] * 8)], tw: (s[1] - 0.5) * 0.45, stag: phy ? -1 : (s[3] < 0.5 ? 0.5 : 0.381966), fib,
        rot: s[3] * 6.283, hue: s[2] * 0.3, D: 0.34 + s[1] * 0.12, wx: s[3] * 100, bloom: 0, shock: 1, flash: 0, arm: 0,
        // colour family from the visit's seeded randoms (no extra rand() call, so the engine's random stream is untouched)
        ...gateFam(s)
      };
    },
    // one crown rises out of the core per beat (V.trav counts beats); drops bloom the whole flower open
    frame(V, F, dt) {
      const c = V.c;
      c.wx += dt * 0.05 * S.speed;
      c.tourT=(c.tourT||0)+dt*S.speed;
      c.rot+=dt*(.035+.025*Math.sin(c.tourT*.071))*S.speed;
      if (F.onDrop || F.drop > (c.pd || 0) + 0.4) { if (c.shock > 0.5) { gateDropFamily(V); c.cT = (c.cT || 0) + 1; } c.shock = 0; }
      c.pd = F.drop;
      c.shock = Math.min(1, c.shock + dt * 0.55);
      c.bloom += (Math.max(F.drop, 0) - c.bloom) * Math.min(1, dt * 3);
      if (F.onHit) c.sn = ((c.sn || 0) + 1) % 4096;   // v20b: snare counter (which crown in four the hit lights)
      c.flash = F.onHit ? 1 : c.flash * Math.exp(-dt * 7);
      const tw = c.tw + Math.sin(V.mt * 0.05) * 0.12 + PTR.x * 0.2 * PTR.inf + F.build * 0.25;
      const camx = 0.16 * Math.sin(c.wx * 1.3) + 0.06 * Math.sin(c.wx * 3.1) + PTR.x * 0.08 * PTR.inf;
      const camy = 0.11 * Math.cos(c.wx * 1.1) + PTR.y * 0.08 * PTR.inf;
      // v13: the wheel also turns the flower a little (about 20 deg per halving or doubling of the zoom), so zooming
      // spirals in and out of the funnel instead of matching its own outward flow; exactly c.rot at zoom 1
      const zr = typeof PTR !== 'undefined' && PTR.zoom > 0 ? Math.log(PTR.zoom) : 0;
      V.p1 = [c.N, tw, c.hue, zr === 0 ? c.rot : c.rot + 0.5 * zr];
      V.p2 = [V.trav % 65536, c.D * (1 - 0.08 * c.bloom) * (1+.12*Math.sin(c.tourT*.11)), 4, 10 + 5 * S.detail];
      V.p3 = [camx, camy, c.stag, 0.04 + 0.08 * F.build];
      V.p4 = [c.bloom, F.build, c.shock, c.flash];
      // spiral arms sweep slowly, jump a third of a turn on every snare and race during builds
      c.armT=(c.armT??c.arm)+dt*(.12+.9*F.build)*S.speed+(F.onHit?.22:0);
      c.arm+=(c.armT-c.arm)*(1-Math.exp(-dt*5));
      V.p5 = [c.fib[0], c.fib[1], c.arm, 0];
      // lights only: the kick's broadband spectrum surge measured against its own running average (G), so the shader
      // can take the common surge out while each band keeps its shape; a beat-smoothed level; the colour family
      const m = gateBroad(), E = 0.3 + 1.5 * m * m * S.dose;
      c.eS = c.eS === undefined ? E : c.eS + (E - c.eS) * (1 - Math.exp(-dt / 0.8));
      c.lv = c.lv === undefined ? F.level : c.lv + (F.level - c.lv) * (1 - Math.exp(-dt / 0.35));
      const G = Math.min(1.35, Math.max(0.5, Math.pow(c.eS / Math.max(E, 0.05), GATE_SQUASH)));
      if (c.fT) { // the drop's family change lands within about a beat
        const k = 1 - Math.exp(-dt / 0.45);
        c.fh += (c.fT.fh - c.fh) * k; c.fa += (c.fT.fa - c.fa) * k; c.fb += (c.fT.fb - c.fb) * k;
        if (Math.abs(c.fT.fh - c.fh) < 0.5 && Math.abs(c.fT.fa - c.fa) + Math.abs(c.fT.fb - c.fb) < 0.01) c.fT = null;
      }
      if (c.fa + c.fb > 0.001 || c.ts !== undefined) { // follow the family's palette position (eased: no colour pops)
        const hue = typeof D !== 'undefined' && Number.isFinite(D.hue) ? (D.hue + ((F.cent || 0.45) - 0.45) * 0.35) % 1000 : 0;
        const T = gateFamPos(c, hue);
        if (c.ts === undefined) c.ts = T;
        else c.ts += ((((T - c.ts) % 1) + 1.5) % 1 - 0.5) * (1 - Math.exp(-dt / 0.8));
        c.ts = ((c.ts % 1) + 1) % 1;
      }
      V.p5[3] = c.ts || 0;
      // v13 wheel zoom (the user's zoom only, so the kaleidoscope pull-back keeps its jewelled mandalas): zooming out pulls
      // the camera back out of the funnel (dz, up to 5.5 at .15) with only part of it as a plain scale (uz^.6); v21: the
      // funnel turns out to be the heart of one endless flower, ring after ring of ever larger petals (the shader's corolla).
      // Zooming in leans into the funnel (dz down to -.42 at 2.5) on top of the scale. Exactly 0 and 1 at zoom 1.
      const uz = typeof PTR !== 'undefined' && PTR.zoom > 0 ? PTR.zoom : 1;
      const zu = uz < 1 ? Math.min(1, -Math.log(uz) / Math.log(1 / 0.15)) : 0;
      const dz = uz < 1 ? 5.5 * Math.pow(zu, 1.3) : uz > 1 ? -0.42 * Math.min(1, Math.log(uz) / Math.log(2.5)) : 0;
      // v21 beat swells: each kick sends a swell out through the corolla, four rings to the beat (two can be on their way at once).
      // Packed per swell: how far it has travelled (in rings, below 100) + 100 * its strength in twentieths.
      if (!c.swx) { c.swx = [99, 99]; c.swa = [0, 0]; c.swi = 0; c.swg = 9; }
      {
        const dT = V.trav - (c.swt === undefined ? V.trav : c.swt); c.swt = V.trav;
        const adv = Math.min(1.5, Math.max(dT > 0 && dT < 2 ? dT * 4 : 0, dt * 4 * S.speed));
        c.swx[0] = Math.min(99, c.swx[0] + adv); c.swx[1] = Math.min(99, c.swx[1] + adv); c.swg += dt;
        if (F.onKick && c.swg > 0.2) { c.swg = 0; c.swi = 1 - c.swi; c.swx[c.swi] = 0; c.swa[c.swi] = Math.round(Math.min(1.2, 0.6 + 0.6 * (F.kick || 0)) * 20); }
      }
      V.m2 = new Float32Array([G, c.lv, Math.max(0, c.fa), Math.max(0, c.fb), dz, uz < 1 ? Math.pow(uz, 0.4) : 1, c.sn || 0, c.swx[0] + 100 * c.swa[0], c.swx[1] + 100 * c.swa[1]]);
      // v21 the corolla dances: every drop throws it one place outward (c.cT counts, c.cE follows within a beat), every snare turns its rings a notch (c.sT, c.sR)
      if (c.cE === undefined) { c.cE = c.cT || 0; c.sT = 0; c.sR = 0; }
      if (F.onHit) c.sT += 1;
      c.cE += ((c.cT || 0) - c.cE) * (1 - Math.exp(-dt / 0.2));
      c.sR += (c.sT - c.sR) * (1 - Math.exp(-dt / 0.11));
      { // a whole turn of the rings is 8 notches a petal: taken off both, so the numbers stay small for ever
        const per = 8 * (c.stag < 0 ? (c.fib[0] < 10 ? 16 : c.fib[0] < 17 ? 13 : 21) : (c.N > 22.5 ? Math.floor(c.N * 0.5 + 0.5) : c.N));
        if (c.sR > per) { c.sR -= per; c.sT -= per; }
      }
      V.m1 = new Float32Array([c.cE, c.sR, c.cT || 0, 0, 0, 0, 0, 0, 0]);
    }
  },
