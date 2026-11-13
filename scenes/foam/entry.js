  {
    key: 'foam', cont: ['k'], name: 'The OAM', src: R_FOAM, cost: 2.7, shadowRecovery: 0.6, kalZoom: 0.6,
    auto: { tier: 2, kind: '3d', kal: [6, 8, 5, 0, 12, 3, 4], kalCycle: true, kalZoom: 0.6, bars: 32, transitions: ['melt', 'vortex', 'portal'], fx: { warp: 0.35, trails: 0.5 }, notes: 'v12: calmer dive; 6/8/5 best (big rose windows), 12/3/4 good; 16 and 2 dropped (16 slices the foam into busy spokes); low warp keeps it crisp' },
    fb: { zoom: 0.002, rot: 0, decay: 0.4, warp: 0.03, echo: 0.1, droste: 0, win: 0, key: 0.178, live: 0.5 }, syms: [0, 0, 0, 6, 6, 8, 8, 5, 12, 4, 3],
    init: (s) => {
      let sd = Math.floor(s[1] * 2147483646) + 1;
      const rnd = () => { sd = (sd * 16807) % 2147483647; return sd / 2147483647; };
      // the director has its own stream, so the camera's route search is unchanged by its choices
      let sd2 = Math.floor((s[2] * 0.618 + s[3] * 0.382) * 2147483646) + 7;
      const dr = () => { sd2 = (sd2 * 48271) % 2147483647; return sd2 / 2147483647; };
      const pal = Math.floor(s[2] * 6) % 6, style = Math.floor(s[3] * 4) % 4;
      const u = dr(), sp = u < 0.55 ? 0 : u < 0.8 ? 1 : 2;
      const c = { k: 1.47 + s[0] * 0.22, push: 0, roll: (s[2] - 0.5) * 0.3, win: 0, gx: 0, gy: 0, gr: 0.3, lastTrav: null,
        palT: pal, palNow: pal, wipe: 9, wipeKind: 0, rotT: 0, rotNow: 0, snA: 9, bars: 0,
        styleT: style, styleNow: style, sp, spO: sp, route: dr() < 0.6 ? 0 : 1, rtW: null, burst: 0, dr,
        ev: 0, evA: 0, evEnd: 0, evStart: 0, nextEv: 10 + Math.floor(dr() * 16), barrel: 0, autoPull: 0 };
      oamSpc = sp; c.kNow = c.k; c.cam = oamMakeCam(c.k, rnd);
      return c;
    },
    // Endless dive: the camera threads one window of the foam after another (speed is measured in the local
    // scale, so the zoom is exponential) and is re-expressed one fractal level deeper whenever it is small enough
    // (exact self-similarity, so the picture never jumps and float precision never runs out). A director changes the
    // route every phrase (dive, cruise, rise into vast chambers, skim along a wall), the lighting style, the foam's species
    // (behind a front of light) and now and then stages a rare event.
    frame(V, F, dt) {
      const c = V.c, cam = c.cam, dr = c.dr || Math.random;
      oamSpc = c.sp;
      if (c.lastTrav === null) c.lastTrav = V.trav;
      const dtr = Math.max(0, V.trav - c.lastTrav); c.lastTrav = V.trav;
      const BL = (typeof BANDS !== 'undefined' && BANDS.lv) || [0, 0, 0, 0, 0, 0, 0, 0];
      // v11: geometry rides smoothed envelopes only (the k breathing used to follow the raw bass, a fine shimmer of the walls)
      const ms = Math.max(0, Math.min(1, S.motionSmooth ?? 0.75));
      // v12: calmer breathing: both lows through one slow spring (about 0.8 s), a smaller swing
      c.subS = Number.isFinite(c.subS) ? c.subS + (0.5 * (BL[0] + (F.bassS ?? F.bass)) - c.subS) * (1 - Math.exp(-dt * 1.25)) : BL[0];
      c.kNow = c.k + 0.006 * Math.sin(V.mt * 0.05) + 0.0028 * c.subS * S.dose;
      // v18: springs for what the music moves as shape (petals, bubbles): attack at least 120 ms, release at least 350 ms
      const spr = (v, x) => { const u = Number.isFinite(v) ? v : 0; return u + (x - u) * (1 - Math.exp(-dt / (x > u ? 0.12 + 0.1 * ms : 0.35 + 0.35 * ms))); };
      c.midP = spr(c.midP, Math.max(BL[2], BL[3]) * Math.min(1, S.dose)); c.basP = spr(c.basP, Math.max(BL[0], BL[1]) * Math.min(1, S.dose));
      const brk = F.breakdown || 0, bld = F.build || 0;
      // colour choreography: a drop snaps to the next curated palette under the hit (the old world is dark ahead of a
      // white-hot front of light that sweeps out through the foam and reveals the new one); every 16 bars the next
      // palette crossfades in behind a softer front; every 8 bars the generations rotate one entry. A species morph
      // grows a different foam out of the old one inside its own front.
      const wipeTo = (kind) => { c.palT = Math.round(c.palT) + 1; c.wipe = 0; c.wipeKind = kind; if (kind === 0) c.palNow = c.palT; };
      // a new species only if the eye stays clear of its sheets (removing a family always is)
      const trySpecies = () => {
        const n = (c.sp + 1 + (dr() < 0.5 ? 1 : 0)) % 3;
        oamSpc = n; const d = oamDE(cam.p[0], cam.p[1], cam.p[2], c.kNow, 12); oamSpc = c.sp;
        if (d < 0.5 * cam.sc) return false;
        c.spO = c.sp; c.sp = n; oamSpc = n; return true;
      };
      const pickRoute = () => {
        let r;
        if (bld > 0.3) r = 0;
        else if (brk > 0.5) r = dr() < 0.65 ? 2 : 1;
        else { const u = dr(); r = u < 0.38 ? 0 : u < 0.62 ? 1 : u < 0.82 ? 2 : 3; if (r === c.route) r = (r + 1 + Math.floor(dr() * 3)) % 4; }
        c.route = r;
      };
      if ((F.onBar || F.onSceneBar)) {
        c.bars++;
        if (c.bars % 8 === 0) { c.rotT += 0.2; pickRoute(); }
        if (c.bars % 8 === 4) c.styleT += dr() < 0.3 ? 2 : 1;
        if (c.wipe >= 9 && !F.onDrop) {
          if (c.bars % 32 === 24 && dr() < 0.75 && trySpecies()) wipeTo(2);
          else if (c.bars % 16 === 0) wipeTo(1);
        }
        // rare events: a blackout where only the lines and lanterns burn, a chase storm through the generations,
        // x-ray glass, a floating lantern ring, a barrel roll, a sudden rise out into a vast chamber
        if (!c.ev && c.bars >= c.nextEv && bld < 0.2) {
          c.ev = 1 + Math.floor(dr() * 6); if (c.ev === 5) c.ev = dr() < 0.5 ? 4 : 6;   // v11: no barrel roll
          c.evStart = c.bars; c.evEnd = c.bars + 4;
          c.nextEv = c.bars + 18 + Math.floor(dr() * 26);
          if (c.ev === 6) { c.route = 2; c.burst = Math.max(c.burst, 0.6); }
        }
        if (c.ev && c.bars >= c.evEnd) c.evEnd = -1;
      }
      if (bld > 0.35 && c.route !== 0) c.route = 0;   // a build always dives (tension)
      if (cam.level <= 0 && cam.sc > 0.06 && c.route > 0) c.route = 0;   // near the top there is nothing to rise into
      if (F.onDrop) {
        if (c.wipe < 9) c.spO = c.sp;
        if (dr() < 0.6) trySpecies();
        wipeTo(0); c.burst = 1; c.route = dr() < 0.7 ? 0 : 3;
        if (c.ev && c.ev !== 5) c.evEnd = -1;
      }
      c.burst *= Math.exp(-dt * 0.4);
      c.wipe = Math.min(9, c.wipe + dt);
      if (c.wipe >= (c.wipeKind === 1 ? 5.5 : c.wipeKind === 2 ? 3.5 : 2.6)) c.wipe = 9;
      if (c.wipe >= 9) c.spO = c.sp;
      if (c.wipeKind !== 0 || c.wipe >= 9) c.palNow += (c.palT - c.palNow) * (1 - Math.exp(-dt * (c.wipeKind === 2 ? 0.8 : 1.1)));
      // events fade in and out (light only; the geometry never jerks)
      const evOn = c.ev && c.evEnd >= 0 ? 1 : 0;
      c.evA += (evOn - c.evA) * (1 - Math.exp(-dt * (evOn ? 2.5 : 1.6)));
      if (!evOn && c.evA < 0.01) { c.ev = 0; c.evA = 0; }
      c.styleNow += (c.styleT - c.styleNow) * (1 - Math.exp(-dt * 0.5));
      if (c.styleNow > 400) { c.styleNow -= 400; c.styleT -= 400; }
      // the snare sends a shell of light out through the foam
      if (F.onHit) c.snA = 0; else c.snA = Math.min(9, c.snA + dt);
      // chase-storm event: the whole palette cascades one notch on every kick
      if (c.ev === 2 && c.evEnd >= 0 && F.onKick) c.rotT += 0.2;
      const ep = 1 - Math.exp(-dt * 2.2);
      c.rotNow += (c.rotT - c.rotNow) * ep;
      if (c.palT > 600 && c.wipe >= 9) { c.palT -= 600; c.palNow -= 600; }
      if (c.rotNow > 50) { c.rotNow -= 50; c.rotT -= 50; }
      // the route's character, eased so a change of route never jerks the camera
      // a strong zoom out turns the journey toward open space: the eye wants vast chambers to look across
      const zm = Math.max(0.1, Math.min(4, ((typeof PTR !== 'undefined' && PTR.zoom) || 1) * (V.kz ?? 1)));
      const zo = Math.max(0, Math.min(1, (1 - zm) / 0.85));
      // v13: zoom is a camera move only; it no longer steers the route toward open space
      const RT = OAM_ROUTES[c.route] || OAM_ROUTES[0];
      if (!c.rtW) c.rtW = { speed: RT.speed, roll: RT.roll, pull: RT.pull };
      for (const key of ['speed', 'roll', 'pull']) c.rtW[key] += (RT[key] - c.rtW[key]) * (1 - Math.exp(-dt * 0.7));
      cam.shrink = RT.shrink; cam.mmax = RT.mmax;
      // travel in local-scale units: about one scale per beat, locked to the music, plus kicks shove it forward
      // V.trav already includes S.speed: applying it again squared the speed setting.
      // v11: calmer: about half the old pace, no kick shove, the beat surge of V.trav averaged out (it lurched the dive on
      // every beat); the music sets the pace through the smoothed level, Motion smoothness sets how slowly it eases
      const trR = dt > 0 ? dtr / dt : 0;
      c.trS = Number.isFinite(c.trS) ? c.trS + (trR - c.trS) * (1 - Math.exp(-dt / 1.2)) : trR;
      // v12: a notch slower again and the drop burst halved ("a tad more chill")
      const wantedRate = 0.8 * (S.speed * (0.22 + 0.36 * (F.levelS ?? F.level)) + Math.min(c.trS, 4) * (.5 + .06 * F.drop))
        * (1 + .25 * bld) * c.rtW.speed * (1 + 0.18 * c.burst) * (1 - 0.5 * brk);
      if (!Number.isFinite(c.travelRate)) c.travelRate = wantedRate;
      c.travelRate += (wantedRate - c.travelRate) * (1 - Math.exp(-Math.max(0, dt) / (0.9 + 1.8 * ms)));
      const adv = c.travelRate * Math.max(0, dt);
      const wantedRoll = Math.max(-.08, Math.min(.08, c.roll * .2 + c.rtW.roll * .55 + F.drop * .03));
      if (!Number.isFinite(c.rollRate)) c.rollRate = wantedRoll;
      c.rollRate += (wantedRoll - c.rollRate) * (1 - Math.exp(-Math.max(0, dt) * 0.35));
      const roll = c.rollRate;
      oamStep(cam, c.kNow, dt, adv, { roll, bias: [PTR.x * 0.35 * PTR.inf, PTR.y * 0.35 * PTR.inf], grow: RT.grow, explore: RT.explore, noWin: RT.noWin, dive: c.route === 0, ms, turn: 1.15 });
      // barrel-roll event: one full turn about the view axis over two bars, eased in and out
      if (c.ev === 5) {
        const pr = Math.max(0, Math.min(1, (c.bars - c.evStart + (F.bar || 0)) / 2)), b = pr * pr * (3 - 2 * pr) * 2 * Math.PI, db = b - c.barrel;
        c.barrel = b;
        if (db) { cam.U = oN(oRot(cam.U, cam.W, db)); cam.V = oN(oRot(cam.V, cam.W, db)); }
      } else c.barrel = 0;
      // a build narrows the lens on the gap being threaded (tension); it springs back wide on the drop
      c.foc = Number.isFinite(c.foc) ? c.foc : .78;
      c.foc += (.78 * (1 + .2 * bld * bld) * (1 - 0.06 * brk) - c.foc) * (1 - Math.exp(-dt * (bld > .05 ? 0.7 : 0.8)));
      const foc = c.foc, X = cam.X;
      oamGapLights(cam, dt);
      const R = oamLook(c, cam, c.kNow, dt, V.mt);
      // the eye: pulled back by the zoom (below 1) and by the route's own wide shots (rise, breakdowns)
      c.autoPull += ((c.rtW.pull + 4 * brk) * (1 - bld) - c.autoPull) * (1 - Math.exp(-dt * 0.35));
      // the pull grows exponentially toward the far end of the wheel, so 0.15 stands several times further back than 0.4
      // v20: the wheel's pull saturates at about OAM_ZMAX units of the current level. Near the top of a level the local scale is
      // large, and 244 scales back stood 15 cells outside the foam: a cutaway of the bare periodic lattice (a one-colour grid with black
      // holes). Deep in a level nothing changes. The scale is eased (log), so a rebase glides instead of stepping the eye.
      const zWant = 25 * Math.pow(zo, 1.4) + 0.2 * (Math.exp(7 * zo) - 1);
      const lsc = Math.log(Math.max(cam.sc, 1e-9));
      c.zsc = Number.isFinite(c.zsc) ? c.zsc + (lsc - c.zsc) * (1 - Math.exp(-Math.max(0, dt) * 0.9)) : lsc;
      const zLu = zWant * 1.35 * Math.exp(c.zsc), zCap = zLu > 1e-6 ? OAM_ZMAX * (1 - Math.exp(-zLu / OAM_ZMAX)) / zLu : 1;
      const eye = oamPull(c, cam, R, c.kNow, dt, c.autoPull, zWant * zCap);
      let tw = 0;
      if (X) {
        const v = [X[0] - eye[0], X[1] - eye[1], X[2] - eye[2]], z = v[0] * R.W[0] + v[1] * R.W[1] + v[2] * R.W[2];
        if (z > cam.Xm * 0.5) {
          const gx = (v[0] * R.U[0] + v[1] * R.U[1] + v[2] * R.U[2]) / z * foc, gy = (v[0] * R.V[0] + v[1] * R.V[1] + v[2] * R.V[2]) / z * foc;
          const gr = Math.min(1.2, cam.Xm / z * foc);
          if (c.win < 0.05) { c.gx = gx; c.gy = gy; c.gr = gr; }
          const e = 1 - Math.exp(-dt * 12); c.gx += (gx - c.gx) * e; c.gy += (gy - c.gy) * e; c.gr += (gr - c.gr) * e;
          tw = Math.max(0, Math.min(1, 2.2 - Math.hypot(c.gx, c.gy) * 1.5)) * Math.min(1, (z / cam.Xm - 0.5) * 0.5);
        }
      }
      c.win += (tw - c.win) * (1 - Math.exp(-dt * 6));
      // parent level's absolute cell (mod 8): its sheets keep the colour they had before the descent
      const po = cam.offs.length > 1 ? cam.offs[cam.offs.length - 2] : (cam.off0 || [0, 0, 0]);
      const m8 = (x) => Math.abs(Math.round(-0.5 * x)) % 8;
      const wiping = c.wipe < 9;
      V.p1 = [c.kNow, cam.level, m8(po[0]) + 8 * m8(po[1]) + 64 * m8(po[2]) + 512 * (c.sp + 3 * (wiping ? c.spO : c.sp)), wiping ? c.wipe + 16 * c.wipeKind : 9];
      V.p2 = [eye[0], eye[1], eye[2], cam.sc];
      const o3 = cam.offs.length ? cam.off : (cam.off0 || [0, 0, 0]);
      // w = +-(focal length + 4 * near clip in 1/16 local scales), positive when the parent is valid
      const fc = foc + 4 * Math.round(Math.min(4000, (c.pb && c.pb.clip) || 0) * 16);
      V.p3 = [o3[0], o3[1], o3[2], cam.offs.length > 0 ? fc : -fc];
      const evK = c.ev >= 1 && c.ev <= 4 ? c.ev : 0, win = Math.max(0, Math.min(1, c.win));
      V.p4 = [c.gx, c.gy, c.gr, win + 2 * evK];
      const sty = ((c.styleNow % 4) + 4) % 4;
      V.p5 = [c.palNow, c.snA, Math.floor(Math.min(999, Math.exp(cam.vis) - 1)) + 0.999 * (evK ? Math.min(1, c.evA) : 0), Math.min(3.999, sty) + (cam.gapLampA ? 4 : 0) + 8 * Math.round(Math.max(0, Math.min(1, c.midP)) * 63) + 512 * Math.round(Math.max(0, Math.min(1, c.basP)) * 63)];
      V.m1 = new Float32Array([R.U[0], R.U[1], R.U[2], R.V[0], R.V[1], R.V[2], R.W[0], R.W[1], R.W[2]]);
      const lampA = cam.gapLampA || cam.p, lampB = cam.gapLampB || cam.p;
      const decay = cam.gapLampDecay || 0, mix = cam.gapLampMix || 0;
      const gainA = cam.gapLampAValid === false ? 0 : oamLanternRange(lampA, cam), gainB = cam.gapLampBValid === false ? 0 : oamLanternRange(lampB, cam);
      V.m2 = new Float32Array([...lampA, ...lampB, decay * mix * gainA, cam.gapLampB ? decay * (1 - mix) * (cam.gapLampPreviousGain || 0) * gainB : 0, c.rotNow]);
      c.dbg = 'rt' + c.route + ' sp' + c.sp + ' ev' + c.ev + ' pull' + (cam.pull || 0).toFixed(1);
    }
  },
