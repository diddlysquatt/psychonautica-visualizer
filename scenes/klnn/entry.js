  {
    key: 'klnn', cont: ['S', 'R', 'e', 'sa'], name: 'KLNN', src: R_KLNN, cost: 2.4, kalZoom: 0.72,
    fb: { zoom: 0.003, rot: 0, decay: 0.36, warp: 0.08, echo: 0.08, droste: 0, win: 0, key: 0.2 }, syms: [0, 0, 0, 0, 3, 4, 5, 6, 6, 8, 12, 12, 16],
    auto: { kal: [6, 8, 0, 12, 4, 5, 16, 3], kalCycle: true, kalZoom: 0.72, transitions: ['vortex', 'kaleido'], bars: 32, tier: 2, kind: '3d',
      notes: 'v12 re-checked (v12/b0_kal, 3 seeds x 2 times): every fold 3-16 is a full mandala, 6/8/12 richest; 2 good but plainer; the automatic route alternates hall vistas and intimate fractal passages' },
    init: (s) => ({
      box: KLNN_BOX[Math.floor(s[0] * KLNN_BOX.length)], S: 0.66 + s[1] * 0.16, R: 0.86 + s[2] * 0.2, e: 0.04 + s[3] * 0.05,
      hu: s[0] * 0.3 - 0.15, wk: s[3] < 0.7 ? 0 : 1, hd: s[2] < 0.5 ? 1 : -1, w: null, lt: null, fw: null, bl: null, sj: 0, roll: 0,
      // structure family (twist / shifted inversion), spatial drift of the architecture, palette pair
      kv: klnnFamily(Math.floor(s[0] * KLNN_BOX.length), (s[1] * 7.31 + s[3] * 3.17) % 1), sa: 0.035 + s[1] * 0.05, ph: s[3] * 6.28,
      pi: Math.floor(s[2] * 8) % 8, pn: klnnNextPal(Math.floor(s[2] * 8) % 8, (s[1] * 3.7 + s[0]) % 1), pm: 0, pgo: 0,
      // camera shots: the visit opens on a seed-chosen composition, not always the centred nave
      shot: Math.floor(((s[0] * 5.13 + s[2] * 2.71) % 1) * 8), ks: 0,
      // the great hall's style: section width/height (gothic, barrel, slender) and rib rhythm (48 or 64 pearls, a major arch every 3rd or 4th)
      hsty: Math.floor(((s[1] * 4.7 + s[3] * 1.3) % 1) * 6), asp: KLNN_ASP[Math.floor(((s[2] * 3.3 + s[0] * 7.1) % 1) * 3)], sn: 0, ht: 0, fl: 0, lastBar: -1
    }),
    frame(V, F, dt) {
      const c = V.c;
      if (!c.w) c.w = klnnWalker(c.box, c.hd);
      const w = c.w;
      if (c.kv === undefined) c.kv = 0;
      if (c.shot === undefined) c.shot = 0;
      // envelopes: lights may snap, geometry and camera only follow these smoothed versions
      const env = (v, x, a, r) => v + (x - v) * (1 - Math.exp(-dt / (x > v ? a : r)));
      c.ks = env(c.ks || 0, F.kick, 0.08, 0.3);
      c.sn = env(c.sn || 0, F.hit, 0.02, 0.28);
      c.hi = env(c.hi || 0, F.high, 0.05, 0.3);
      // per-band envelopes for geometry: sub+bass breathe the big forms, the mids drive the linework
      c.bs = env(c.bs || 0, 0.65 * F.bass + 0.35 * BANDS.lv[0] * BANDS.lv[1], 0.12, 0.35);
      c.md = env(c.md || 0, 0.5 * F.mid + 0.5 * BANDS.lv[2] * BANDS.lv[3], 0.05, 0.25);
      // phrases: every 4 bars a new camera shot; every 16 bars (or on a drop) a new palette
      const dropEdge = F.onDrop || (F.drop > 0.85 && (c.prevDrop || 0) < 0.5); c.prevDrop = F.drop;
      // the next palette always comes from the other temperature family, so a visit swings between warm and cool
      const newPal = () => { c.pn = klnnNextPal(c.pi, rand()); };
      // the centred nave (0) is one shot of eight and never comes twice in a row
      const nextShot = (bold) => { let n; do { n = Math.floor(rand() * 8); } while (n === c.shot || (bold && n === 0)); c.shot = n; };
      // a new structure family (the lattice itself morphs over a few seconds): trumpets and feathers need boxes 2/3 for 2
      const famOK = (f) => f < 2 || c.box === KLNN_BOX[2] || c.box === KLNN_BOX[3];
      const newFam = () => { let f; do { f = Math.floor(rand() * 3); } while (f === c.kv || !famOK(f)); c.kv = f; };
      if (c.kf === undefined) c.kf = c.kv;
      if ((F.onBar || F.onSceneBar) && (F.sceneBarIndex ?? F.barIndex) !== c.lastBar) {
        c.lastBar = (F.sceneBarIndex ?? F.barIndex);
        if ((F.sceneBarIndex ?? F.barIndex) % 4 === 0 && F.build < 0.3) nextShot(false);
        if ((F.sceneBarIndex ?? F.barIndex) % 16 === 8 && c.pgo === 0 && c.pm < 0.05) c.pgo = 1;
        // hall events count down in bars
        if (c.evB > 0 && --c.evB === 0) c.hev = 0;
        if (c.eclB > 0) c.eclB--;
        if ((F.sceneBarIndex ?? F.barIndex) % 32 === 24 && rand() < 0.6) newFam();
        // a long-held hall slowly changes its section at a phrase (the walls glide to the new width)
        if ((F.sceneBarIndex ?? F.barIndex) % 32 === 0 && (c.hA || 0) > 0.3 && rand() < 0.7) c.asp = KLNN_ASP[(KLNN_ASP.indexOf(c.asp) + 1 + Math.floor(rand() * 2)) % 3];
        // rare phrase surprises (not in a build): a vista (the walls draw back into a great hall for 8 bars) or an
        // eclipse (one bar where the stone goes dark and only the neon burns)
        if ((F.sceneBarIndex ?? F.barIndex) % 16 === 0 && F.build < 0.3 && !(c.evB > 0)) {
          const r = rand();
          if (r < 0.18) newFam();
          else if (r < 0.3) c.eclB = 2;
        }
      }
      // a breakdown opens the hall slowly, a calm vast space
      if ((F.breakdown || 0) > 0.5) c.bdH = 1;
      else if (c.bdH && (F.breakdown || 0) < 0.3) c.bdH = 0;
      if (dropEdge) {
        // the inversion leaps on a drop through a spring (the architecture transforms in ~0.4 s, never in one frame)
        c.pgo = 2; c.fl = 1; nextShot(true); c.sjT = (rand() < 0.5 ? -1 : 1) * (0.018 + rand() * 0.022);
        // every other drop (seeded) blasts the walls outward into the great hall for 8 bars; otherwise it may morph
        // the lattice into another family. A breakdown hall slams shut on the drop instead.
        c.bdH = 0; c.evB = 0; c.hev = 0;
        if (rand() < 0.6) newFam();
      }
      c.kf1 = ease(c.kf1 ?? c.kf, c.kv, dt, 0.6); c.kf = ease(c.kf, c.kf1, dt, 0.6);
      const eT = c.eclB > 0 ? 1 : c.bdH ? 0.45 : 0; c.ecl = ease(c.ecl || 0, eT, dt, eT > (c.ecl || 0) ? 0.12 : 0.5);
      c.fl = env(c.fl || 0, 0, 0.01, 0.6);
      // palette: a drop (fast) or a phrase change (slow) sweeps the next palette in from the vanishing point
      c.pm = c.pgo ? Math.min(1, c.pm + dt / (c.pgo === 2 ? 0.8 : 4)) : 0;
      if (c.pgo && c.pm >= 1) { c.pi = c.pn; c.pm = 0; c.pgo = 0; newPal(); }
      // shots: [gaze yaw, gaze pitch, offset across the nave, offset up, roll]. Big offsets hug a wall so the
      // vanishing point leaves the centre; yaw ~70 deg tracks sideways past the rose windows; pitch looks into the vault
      const SH = [[0, 0, 0, 0, 0], [-0.42, -0.06, 0.52, 0.14, 0.16], [0.5, 0.1, -0.5, -0.22, -0.2], [1.22, 0.04, -0.42, 0.04, 0.04],
        [0.16, 0.98, 0.1, -0.42, 0.12], [-0.2, -0.88, -0.22, 0.42, -0.1], [-0.26, -0.3, 0.46, 0.34, 0.52], [-1.3, -0.12, 0.4, -0.12, -0.06]];
      const sT = SH[c.shot] || SH[0];
      // two-stage easing gives an S-curve dolly (~2 s) instead of a snap
      if (!c.shm || c.shm.length !== 5) { c.shm = sT.slice(); c.shv = sT.slice(); }
      for (let i = 0; i < 5; i++) { c.shm[i] = ease(c.shm[i], sT[i], dt, 0.7); c.shv[i] = ease(c.shv[i], c.shm[i], dt, 0.7); }
      // a build winds the camera into a slow corkscrew; afterwards it settles to the nearest upright view
      c.spin = (c.spin || 0) + dt * F.build * F.build * 0.9;
      if (F.build < 0.2) c.spin = ease(c.spin, Math.round(c.spin / Math.PI) * Math.PI, dt, 0.9);
      // travel is counted in beats: 0.4 units per beat, so the camera passes about one junction per bar
      if (c.lt === null || c.lt === undefined) c.lt = V.trav;
      klnnAdvance(w, clamp(V.trav - c.lt, 0, 0.5) * 0.4); c.lt = V.trav;
      const a = klnnAt(w, w.s), b = klnnAt(w, w.s + 0.8), g = klnnAt(w, w.s + 1.1), a2 = klnnAt(w, w.s + 0.35);
      const t = a.t, side = [0, 0, 1], mt = V.mt;
      // zoom: the wheel (and the kaleidoscope pull-back) widens the view down to ~0.72 (GLSL); below that the great hall
      // opens around the nave and the camera rises into it, an ant under a vault of a thousand rose windows
      // (v11: only the wheel zoom opens it, from 0.6 down; the kaleidoscope pull-back and phrase events no longer do)
      const zm = clamp(PTR.zoom || 1, 0.1, 4), zu = clamp((0.6 - zm) / 0.42, 0, 1);
      // v13: no realm-side lag on the wheel (the engine's spring already smooths it): the hall follows the hand
      c.hU = zu * zu * (3 - 2 * zu);
      c.hE = ease(c.hE || 0, c.hev || 0, dt, (c.hev || 0) > (c.hE || 0) ? (c.hup || 1) : 1.4);
      const hallT = Math.max(zu, c.hev || 0);
      c.hA = Math.max(c.hU, c.hE);
      const hR = c.hA > 0.004 ? 21 * Math.pow(c.hA, 1.4) : 0;
      // each time the hall opens from closed it is another building: new section and rib rhythm
      if (hR < 0.05 && hallT > 0.02 && !c.hOpen) { c.hOpen = 1; c.hsty = Math.floor(rand() * 6); c.asp = KLNN_ASP[Math.floor(rand() * 3)]; c.aspE = c.asp; c.hSide = rand() < 0.5 ? -1 : 1; }
      if (hR < 0.01 && hallT < 0.01) c.hOpen = 0;
      if (c.aspE === undefined) c.aspE = c.asp || 0.65;
      c.aspE = ease(c.aspE, c.asp || 0.65, dt, 2.5);
      w.noDive = hallT > 0.02 || c.hA > 0.02;
      // the hall's axis follows the camera's nave (a shaft descent glides it down); lattice-period shifts are invisible
      const Py = 4 * c.box[1];
      if (c.hY === undefined) c.hY = a.p[1];
      c.hY += Math.round((a.p[1] - c.hY) / Py) * Py; c.hY = ease(c.hY, a.p[1], dt, 0.8);
      const hall = [hR, c.hY, c.aspE];
      // heading follows the path (not the offset camera), so off-axis shots look parallel to the nave
      const k = 1 - Math.exp(-dt * 5);
      const fwT = v3.norm(v3.add(b.p, v3.sc(a.p, -1)));
      c.fw = c.fw ? v3.norm(v3.add(c.fw, v3.sc(v3.add(fwT, v3.sc(c.fw, -1)), k))) : fwT;
      // in the hall the light and the far glow sit at the end of the hall, whatever the path ahead does
      const hw = clamp(hR / 6, 0, 1), blT = v3.norm(v3.add(v3.sc(g.t, 1 - hw), [w.hd * hw, 0, 0]));
      c.bl = c.bl ? v3.norm(v3.add(c.bl, v3.sc(v3.add(blT, v3.sc(c.bl, -1)), 1 - Math.exp(-dt * 2.2)))) : blT;
      let fw = c.fw;
      const kd = clamp(-fw[1], 0, 1);
      const up = [w.hd * kd, Math.sqrt(1 - kd * kd), 0];
      // the in-plane normal, oriented to the camera's up so "up" offsets always rise on screen
      let nrm = [-t[1], t[0], 0]; if (v3.dot(nrm, up) < 0) nrm = v3.sc(nrm, -1);
      // near a corner the up/down offset shrinks so the inner radius of the turn never folds back on itself
      const q0 = w.pcs[0], q1 = w.pcs[1];
      const turning = (q0 && q0.k === 1) || (q1 && q1.k === 1 && q0.len - w.s < 0.6);
      c.ns = ease(c.ns === undefined ? 1 : c.ns, turning ? 0.35 : 1, dt, 0.5);
      const sw = 0.09 * Math.sin(mt * 0.31 + c.hu * 9) + c.shv[2] + PTR.x * 0.08 * PTR.inf;
      const sv = (0.07 * Math.sin(mt * 0.23 + 1) + c.shv[3]) * c.ns + PTR.y * 0.06 * PTR.inf;
      // in the hall the camera rises toward the vault and drifts slowly across it (hall frame: y up, z across)
      const hOff = [0, 0.3 * hR * (up[1] < 0 ? -1 : 1), 0.1 * hR * Math.sin(mt * 0.071 + 2)];
      // the inversion breathes with the bass and leaps on a drop, so the architecture itself transforms
      c.sjT = ease(c.sjT || 0, 0, dt, 7); c.sj1 = ease(c.sj1 || 0, c.sjT, dt, 0.18); c.sj = ease(c.sj || 0, c.sj1, dt, 0.18);
      const dose = S.dose;
      // the openings in the great discs: their bars' half-width, breathing with the bass (a smoothed envelope: geometry)
      const kBq = Math.round(2000 * (0.018 + 0.05 * c.bs * c.bs * dose)), kBr = kBq * 0.0005;
      const S0 = clamp(c.S + 0.05 * Math.sin(mt * 0.11) + 0.03 * Math.sin(mt * 0.043 + 2) + c.sj, 0.6, 0.86) + 0.014 * c.bs * dose;
      // bass swells the rose-window rims (smoothed, so the walls breathe rather than jump)
      const R0 = (c.R + 0.05 * Math.sin(mt * 0.083 + 1)) * (1 + 0.11 * c.bs * dose);
      // clearance: the largest share of the shot's offset that keeps the camera (and the view just ahead) off the walls
      const TAU = 2 * Math.PI, wrap = (x) => ((x % TAU) + TAU) % TAU, ph0 = c.ph + mt * 0.05;
      const ph = [wrap(ph0 + 0.43 * (w.ox || 0) + 0.31 * (w.oy || 0)), wrap(0.7 * ph0 + 0.27 * (w.ox || 0) - 0.37 * (w.oy || 0))];
      const clear = (s) => {
        const o = v3.add(v3.add(v3.sc(side, sw * s), v3.sc(nrm, sv * s)), v3.sc(hOff, s));
        return Math.min(klnnDE(v3.add(a.p, o), c.box, S0, c.sa, ph, R0, c.e, c.kf, hall, kBr), klnnDE(v3.add(a2.p, o), c.box, S0, c.sa, ph, R0, c.e, c.kf, hall, kBr));
      };
      let sc = 1;
      for (const s of [1, 0.8, 0.6, 0.4, 0.2, 0]) { sc = s; if (clear(s) > 0.28) break; }
      c.cs = ease(c.cs === undefined ? sc : c.cs, sc, dt, sc < c.cs ? 0.25 : 1.2);
      const offT = v3.add(v3.add(v3.sc(side, clamp(sw,-.24,.24) * c.cs), v3.sc(nrm, clamp(sv,-.2,.2) * c.cs)), v3.sc(hOff, c.cs));
      // (v11) the camera's offset from the path and its orientation follow critically damped springs, stiffness set
      // by Motion smoothness (0 snappy .. 1 glide): no velocity step anywhere (shot changes, corners, the hall opening)
      const om = 13 - 8 * clamp(Number(S.motionSmooth) || 0, 0, 1), sdt = Math.min(dt, 0.1);
      if (!c.oX) { c.oX = offT.slice(); c.oV = [0, 0, 0]; }
      klnnSpring(c.oX, c.oV, offT, om, sdt);
      // Check the sprung offset too: the moving fractal can close around an otherwise safe shot target.
      const free=klnnDE(v3.add(a.p,c.oX),c.box,S0,c.sa,ph,R0,c.e,c.kf,hall);
      if(free<.24){
        const eye=v3.add(a.p,c.oX),eps=.035,gradient=[0,1,2].map(i=>{const q=eye.slice();q[i]+=eps;return klnnDE(q,c.box,S0,c.sa,ph,R0,c.e,c.kf,hall)-free;});
        const length=Math.hypot(...gradient);
        if(length>1e-8){const push=Math.min(dt*.9,.24-free);for(let i=0;i<3;i++){c.oX[i]+=gradient[i]/length*push;c.oV[i]*=Math.exp(-dt*8);}}
        else{const k=1-Math.exp(-dt*12);for(let i=0;i<3;i++){c.oX[i]*=1-k;c.oV[i]*=1-k;}}
      }
      const off = c.oX, pos = v3.add(a.p, off);
      let uu = v3.norm(v3.cross(fw, up));
      let vv = v3.cross(uu, fw);
      // the shot's gaze: yaw across the nave, then pitch toward the vault or the floor
      // zoomed out in the great hall the gaze turns across it, onto the wall of a thousand rose windows (looking down
      // its axis showed the arches as one giant ringed porthole)
      const hy = (c.hA || 0) * 1.22 * (c.hSide || 1), yw = c.shv[0] * (1 - 0.6 * (c.hA || 0)) + hy, pt = c.shv[1] * (1 - 0.6 * (c.hA || 0)) + 0.1 * (c.hA || 0);
      const cy = Math.cos(yw), sy = Math.sin(yw), cp = Math.cos(pt), sp = Math.sin(pt);
      const f1 = v3.add(v3.sc(fw, cy), v3.sc(uu, sy)); uu = v3.add(v3.sc(uu, cy), v3.sc(fw, -sy));
      fw = v3.norm(v3.add(v3.sc(f1, cp), v3.sc(vv, sp))); vv = v3.norm(v3.add(v3.sc(vv, cp), v3.sc(f1, -sp)));
      uu = v3.norm(v3.cross(fw, vv)); vv = v3.cross(uu, fw);
      const turnRate = v3.dot(v3.cross(t, b.t), side);
      c.roll = ease(c.roll, -turnRate * 0.15 * w.hd + 0.06 * Math.sin(mt * 0.07), dt, 0.5);
      const rollAll = c.roll + c.shv[4] + c.spin;
      const cr = Math.cos(rollAll), sr = Math.sin(rollAll);
      [uu, vv] = [v3.add(v3.sc(uu, cr), v3.sc(vv, sr)), v3.add(v3.sc(vv, cr), v3.sc(uu, -sr))];
      const qT = [fw[0], fw[1], fw[2], vv[0], vv[1], vv[2]];
      if (!c.qX) { c.qX = qT.slice(); c.qV = [0, 0, 0, 0, 0, 0]; }
      klnnSpring(c.qX, c.qV, qT, om * 1.15, sdt);
      fw = v3.norm(c.qX.slice(0, 3)); uu = v3.norm(v3.cross(fw, c.qX.slice(3, 6))); vv = v3.cross(uu, fw);
      // v13 zoom in: the lens narrows (GLSL) and the gaze leans toward the nearer wall, so the rose windows and their
      // tracery fill the frame instead of a longer view down the same nave (applied after the springs: no lag)
      { const zi = clamp(Math.log(Math.max(PTR.zoom || 1, 1)) / Math.log(2.5), 0, 1), zq = zi * zi * (3 - 2 * zi);
        c.zSd = ease(c.zSd === undefined ? 1 : c.zSd, v3.dot(off, uu) < 0 ? -1 : 1, dt, 2);
        const za = 0.55 * zq * c.zSd, ca = Math.cos(za), sa = Math.sin(za);
        [fw, uu] = [v3.add(v3.sc(fw, ca), v3.sc(uu, sa)), v3.add(v3.sc(uu, ca), v3.sc(fw, -sa))]; }
      // middle row: the hall (radius, axis y, lantern level + 2 x section width/height in 200ths); the shader rebuilds camera-up as right x forward
      const lantL = clamp((c.hA - 0.15) / 0.3, 0, 1);
      V.m1 = new Float32Array([uu[0], uu[1], uu[2], hR, c.hY, Math.min(lantL * (0.6 + 0.4 * S.dose), 1) + 2 * Math.round(c.aspE * 200), fw[0], fw[1], fw[2]]);
      V.p1 = [c.box[0], c.box[1], c.box[2], S0];
      V.p2 = [pos[0], pos[1], pos[2], c.e];
      const bd = F.breakdown || 0;
      // uP3.z: the visit's hue offset plus the structure family as its integer part (the hue only reads the fraction)
      V.p3 = [R0, 8 * c.wk + ph[1], c.hu + (c.hsty || 0), (0.085 - 0.04 * F.build + 0.03 * bd) / (1 + 0.09 * hR)];
      // the drop no longer pumps the atmosphere (that was the orange wash): it lights the coloured linework instead
      V.p4 = [c.bl[0], c.bl[1], c.bl[2], (0.75 + 0.4 * c.bs * dose + 0.3 * F.build + 0.15 * F.drop) * (0.7 + 0.3 * dose) * (1 - 0.35 * bd)];
      V.p5 = [(0.65 + 0.25 * F.kick * dose) * (1 + 0.15 * F.drop) * (1 - 0.3 * bd), 0.3 + (1.4 * c.sn + 0.65 * c.md + 0.55 * c.hi) * dose + 0.35 * F.drop, 0.35 + 2.0 * c.hi * dose, (0.25 + 1.1 * F.kick) * dose + 0.35 * F.drop];
      // uM2: [palettes pi + 8 pn, eclipse, sweep], [snare, smoothed kick, structure family], [S drift, phase, flash]
      V.m2 = new Float32Array([c.pi + 8 * c.pn, c.ecl, c.pm, c.sn * dose, c.ks * dose, c.kf, c.sa, ph[0], c.fl + 2 * kBq]);
    }
  },
