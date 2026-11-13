  {
    key: 'void9', name: 'VOID 9', src: R_VOID9, cost: 2.2, cont: [], continuousJourney: true,
    description: 'endless stained-glass cathedral', kalZoom: 0.62,
    fb: { zoom: 0, rot: 0, decay: 0.16, warp: 0, echo: 0, droste: 0, win: 0.85, key: 0.1 }, syms: [0, 0, 0, 0, 4, 5, 6, 6, 8, 8, 12, 3],
    auto: { kal: [0, 8, 6, 4, 12, 3, 5], kalCycle: true, kalZoom: 0.62, transitions: ['portal', 'leak'], bars: 32, tier: 2, kind: '3d',
      // (v15b flicker) the engine's hands-off framing tour stays gentle here. This realm's zoom moves the CAMERA
      // (trail back along the route + rise over the cutaway + cut plane), so a tour that swept 0.65..1.3 scrubbed the
      // camera up to 8 beats along its own route and magnified the nave every 12 s, which measures as flicker.
      // The user's wheel still owns the full 0.15..2.5 range; only the automatic tour is bounded.
      zoom: [0.78, 1.12],
      notes: 'v12: 8/6/4 best, 12/3/5 good; 16 and 2 dropped (16 goes dark at the centre, 2 cuts the nave diagonally); the journey continues through reseeds' },
    init: (s) => {
      const fam = Math.floor(s[0] * 4) % 4, f = VOID9_FAM[fam], pal = Math.floor(s[1] * 6) % 6;
      const shot = Math.floor(s[2] * 9) % 9, side = s[3] < 0.5 ? 1 : -1, rv = f.k * 2;
      const at = f.ya + Math.sqrt(Math.max(0.5 * f.ka - 0.25, 0)), apex = f.ys + Math.sqrt(rv * rv - (rv - 2) * (rv - 2));
      const c = { fam, famA: fam, famB: fam, fmT: 1, mood: 0, nextMorph: 20 + Math.floor(s[3] * 16), ev: 0, evA: 0, evB: 0, ya: f.ya, ys: f.ys, rv, ka: f.ka, t0: at + 0.25, apex, Ly: VOID9_LY, seed: Math.floor(s[2] * 3) % 3,
        side, pet: [12, 16, 8, 12][Math.floor(s[3] * 4) % 4], legs: [], b0: 0, mode: 0,
        palA: pal, palB: pal, pm: 1, bars: 0, shot, shotT: 1, shotN: 0, hold: -1, dropN: Math.floor(s[0] * 3) % 3,
        mvA: 1, mvDir: 1, grow: 0, burst: 0, burstT: 0, kick: 0, hitW: 9, kickW: 9, glass: 0.6, spin: s[0] * 6.283, pd: 0, lastLeg: null };
      c.air=0;c.airV=0;
      const t = void9Shot(c, 0);
      c.cam = t.slice(); c.camV = [0, 0, 0, 0, 0, 0];
      return c;
    },
    // one bay (one gilded transverse arch) per beat; a crossing every 2 bars where the route goes straight on, turns
    // left or right, climbs a lantern into the level above or dives a well into the level below (builds climb,
    // breakdowns dive, drops climb when they can); every 4 bars a new camera shot; drops swap the glass and play one
    // of three moves (barrel roll, sideways sweep, vault rise). Zooming out pulls the camera back along the nave and up
    // toward the vault and widens the lens.
    frame(V, F, dt) {
      const c = V.c, bps = (F.bpm > 0 ? F.bpm : 120) / 60, inf = Number.isFinite(PTR.inf) ? PTR.inf : 0, B = V.trav;
      c.grow = ease(c.grow, F.build, dt, F.build > c.grow ? 0.6 : 1.5);
      c.mode = F.build > 0.45 ? 1 : F.breakdown > 0.6 ? 2 : 0;
      const dropEdge = F.onDrop || (F.drop > 0.85 && c.pd < 0.5); c.pd = F.drop;
      // (v11) a new shot only changes the target: the pose follows it through a spring (an interrupted change used to
      // restart from a standstill, which stopped the camera dead in one frame)
      const newShot = (k) => { c.shot = k; c.shotN++; };
      if (!c.cont0) { c.cont0 = 1; void9Continue(c, B); }
      void9Leg(c, B);
      if (dropEdge) {
        c.shB = 4;
        c.burstT = 1; c.palB = (c.palA + 1 + Math.floor(rand() * 5)) % 6; c.pm = 0;
        c.mvA = 0; c.mvDir = rand() < 0.5 ? -1 : 1; c.dropN = (c.dropN + 1) % 3; c.mvUp = c.cam[3] > 0.6 ? -0.6 : 1;
        newShot(void9Next(c));
        // re-plan the next leg that has not begun: climb a lantern if there is one, otherwise turn
        const i = c.legs.findIndex((L) => L.tb > B);
        if (i > 0) { c.legs.length = i; c.legs.push(void9MakeLeg(c, c.legs[i - 1], rand() < 0.75 ? 'U' : (rand() < 0.5 ? 'L' : 'R'))); }
      }
      c.burstT *= Math.exp(-dt * 1.4);
      c.burst = ease(c.burst, c.burstT, dt, 0.08);
      c.kick = Math.max(F.kick * S.dose, c.kick * Math.exp(-dt * 6));
      c.hitW = F.onHit ? 0 : Math.min(c.hitW + dt * 2.2, 9);
      c.kickW = F.onKick ? 0 : Math.min(c.kickW + dt, 9);
      c.glass = ease(c.glass, 0.35 + 0.9 * F.mid, dt, 0.18);
      // (v11) light shafts: sub and bass (levels and onsets) pour coloured light down through the windows; builds thicken
      // them, phrase events and drops make them blaze. Light only, so it may hit fast (60 ms attack, 350 ms release).
      const bl = 0.5 * ((BANDS.lv[0] || 0) + (BANDS.lv[1] || 0)), bon = Math.max(BANDS.on[0] || 0, BANDS.on[1] || 0);
      c.evSh = ease(c.evSh || 0, c.shB > 0 ? 1 : 0, dt, 0.8);
      const shT = ((0.1 + 1.25 * bl * bl + 0.7 * bon) * (1 + 0.8 * c.evSh) + 0.5 * c.grow + 0.8 * c.burst) * S.dose;
      c.sh = ease(c.sh || 0, shT, dt, shT > (c.sh || 0) ? 0.06 : 0.35);
      // blackout (a phrase event, and half of one in breakdowns): the stone and haze go dark, only glass, lamps and
      // shafts burn; the rainbow cascade spins the arches' rainbow along the nave for two bars
      c.bk = ease(c.bk || 0, c.bkB > 0 ? 0.7 : F.breakdown > 0.6 ? 0.35 : 0, dt, 0.35);
      c.rc = (c.rc || 0) + dt * bps * 0.25 * (c.rcB > 0 ? 1 : 0) * (0.5 + 0.5 * F.kick);
      // phrases: a new glass palette every 8 bars (and on every new level), a new camera shot every 4 bars
      if ((F.onBar || F.onSceneBar)) {
        c.bars++;
        if (c.bkB > 0) c.bkB--; if (c.shB > 0) c.shB--; if (c.rcB > 0) c.rcB--; if (c.airB > 0) c.airB--;
        if (c.bars % 64 === 36 && F.build < 0.3 && !(c.airB > 0) && void9Mod(Math.sin(c.bars * 12.9898 + c.seed * 78.233) * 43758.5453, 1) < 0.5) c.airB = 4;   // (own hash: the route's random stream is untouched)
        // (v11) phrase events, every 8 bars outside builds: a blackout nave, a shaft storm or a rainbow cascade
        if (c.bars % 8 === 4 && F.build < 0.3) { const r = rand(); if (r < 0.16) c.bkB = 2; else if (r < 0.38) c.shB = 4; else if (r < 0.56) c.rcB = 2; }
        if (c.bars % 8 === 0 && c.pm >= 1) { c.palB = (c.palA + 1 + Math.floor(rand() * 5)) % 6; c.pm = 0; }
        if (c.bars % 4 === 0 && !dropEdge) newShot(void9Next(c));
        // (v12) a new route mood every 16 bars; the nave morphs into another family every 24-40 bars (over 4 bars)
        if (c.bars % 16 === 8) c.mood = Math.floor(rand() * 4);
        if (c.bars >= (c.nextMorph ?? 1e9) && (c.fmT ?? 1) >= 1 && F.build < 0.3) { c.famA = c.famB ?? c.fam; c.famB = (c.famA + 1 + Math.floor(rand() * 3)) % 4; c.fmT = 0; c.nextMorph = c.bars + 24 + Math.floor(rand() * 16); }
        // (v12) set pieces, 4 bars: 1 procession (the windows ignite bay by bay down the nave), 2 gold ascension (bands of
        // gold light rise up the whole elevation), 3 negative nave (the stone glows as glass, the glass goes dark)
        if (c.evB > 0) c.evB--;
        if (c.bars % 8 === 0 && !c.evB && !c.bkB && !c.shB && !c.rcB && F.build < 0.3 && rand() < 0.42) { c.ev = 1 + Math.floor(rand() * 3); c.evB = 4; }
      }
      if (dropEdge && !c.evB && rand() < 0.35) { c.ev = 1 + Math.floor(rand() * 3); c.evB = 4; }
      // (the set piece comes on phrases only: a drop already has its own moves)
      c.evA = ease(c.evA || 0, c.evB > 0 ? 1 : 0, dt, c.evB > 0 ? 0.5 : 0.7);
      if (!(c.evB > 0) && c.evA < 0.01) c.ev = 0;
      if ((c.fmT ?? 1) < 1) c.fmT = Math.min(1, c.fmT + dt * bps / 16);
      void9Fam(c);
      if (c.hold >= 0 && c.shot !== c.hold) newShot(c.hold);
      c.onTop = void9At(c, B).p[1] > -0.5;
      if (F.breakdown > 0.6 && c.shot !== 3 && c.shot !== 1 && c.shot !== 7 && !c.onTop) newShot(3);
      // smoothed heading: yaw and pitch averaged over a beat so turns ease in and out
      let yaw = 0, pitch = 0;
      // zoom: below 1 the camera trails further back along its own route (up to 22 bays: the same view the route had
      // that many beats ago, so it is always inside the cathedral and turns smoothly), rises to gallery height and
      // widens the lens; above 1 the lens narrows. The trail is eased so a fast wheel never whips the camera.
      // (v13 zoom contract) every zoom term is applied after the springs, straight from the engine's zoom spring, so the
      // picture stops when the hand stops. Below ~0.5 a second stage begins: the vault is sliced away by a cut plane
      // that descends from above, the camera rises through it and tilts down, and at 0.15 the whole building is seen
      // from above as a glowing cutaway plan (naves, crossings, lantern shafts and wells into the levels below).
      // a very short critically damped pre-filter (settles in ~0.1 s) only rounds off the engine spring's start, whose
      // acceleration step would otherwise jolt a camera that moves 20 bays over the zoom range
      // (v15) the wheel owns the wide view again: below 1 the camera trails back along its own route and rises over the
      // cutaway plan, above 1 the lens goes telephoto. Every term is applied after the springs, so the picture stops when
      // the hand stops (the v14 build had made zoom optical only, which left the framing almost unchanged on a zoom
      // gesture: the sweep measured 67 % of zoom steps with no visible change).
      const zl = Math.log(clamp((PTR.zoom || 1) * (V.kz ?? 1), 0.1, 4));
      if (c.zl == null || !Number.isFinite(c.zl)) { c.zl = zl; c.zv = 0; }
      { const zx = [c.zl], zv = [c.zv]; void9Spring(zx, zv, [zl], 40, Math.min(dt, 0.1)); c.zl = zx[0]; c.zv = zv[0]; }
      const zm = Math.exp(c.zl), zU = clamp((1 - zm) / 0.85, 0, 1);
      // (v13) set piece "over the roofs": now and then (a phrase or a drop) the camera itself rises out through the
      // opened vault for 4 bars, sees the glowing plan of the cathedral from above and dives back in. It uses the same
      // continuous pose as the zoom-out (the realm's own move, independent of the user's zoom; the trail stays the user's)
      c.tourT=(c.tourT||0)+dt*S.speed;
      // (v15) the roof tour is a rare set piece, not the home view. The old schedule spent about two thirds of every
      // visit above the roofs or descending through them, where the realm reads as a tiled model and none of the
      // arches, glass or light is on screen. A visit now opens inside the nave and climbs out once every 170 s
      // (a 4 s rise, 7 s above the roofs, a 4 s dive back in; all boundaries are still C2 smooth).
      const ss=(a,b,x)=>{const u=clamp((x-a)/(b-a),0,1);return u*u*u*(u*(6*u-15)+10);};
      const tp=((c.tourT-40)%110+110)%110, roof=ss(0,4,tp)*(1-ss(13,17,tp));
      { const x = [c.air || 0], v = [c.airV || 0]; void9Spring(x, v, [roof], 1.3, Math.min(dt, 0.1)); c.air = clamp(x[0], 0, 1); c.airV = v[0]; }
      const zo = 1 - (1 - zU) * (1 - 0.97 * c.air);   // (a smooth union: a max() kinked the camera when the two crossed)
      const wC = void9Smooth((zo - 0.62) / 0.18), uB = clamp((zo - 0.7) / 0.3, 0, 1), sB = uB * uB * (2 - uB), sP = void9Smooth((zo - 0.66) / 0.26) * 0.75 + 0.25 * uB * uB, zs = void9Smooth(zo);
      c.trail = 22 * Math.pow(zU, 1.2) * (1 - 0.55 * sB);
      const Bc = Math.max(B - c.trail, c.legs[0].tb + 0.6), yw = 0.25 * (1 + 2.5 * zs);
      for (let k = -2; k <= 2; k++) { const a = void9At(c, Bc + k * yw); yaw += a.yaw / 5; pitch += a.pitch / 5; }
      const A = void9At(c, Bc), L = A.L;
      if (L !== c.lastLeg) { if (c.lastLeg && (c.lastLeg.kind === 'U' || c.lastLeg.kind === 'D') && c.pm >= 1) { c.palB = (c.palA + 1 + Math.floor(rand() * 5)) % 6; c.pm = 0; } c.lastLeg = L; }
      if (c.pm < 1) { c.pm = Math.min(1, c.pm + dt * bps / (c.burstT > 0.3 ? 1 : 4)); if (c.pm >= 1) c.palA = c.palB; }
      const ms = clamp(Number(S.motionSmooth) || 0, 0, 1), sdt = Math.min(dt, 0.1);
      const tg = void9Shot(c, B);
      // (v19) the shots over the wall tops are for the top level only: cap their height (and steer away from them) from a few beats
      // before the route leaves it until a little after it is back
      let opn = true;
      for (let k = -2; k <= 7; k++) { const a = void9At(c, Bc + k), v = a.L.kind === 'U' || a.L.kind === 'D'; if (a.p[1] < -0.5 || (v && a.s > a.L.sA - 3 && a.s < a.L.sB + 3)) { opn = false; break; } }
      if (!opn) { tg[1] = Math.min(tg[1], c.ys - 1.0); tg[3] = Math.min(tg[3], 0.4); }
      // (v13) a high shot never rides a climb or dive into a level whose arch tunnels would then have to pull it down
      // fast (the rare lurch): near a vertical leg its height target stays under the tunnels' opening
      if (!c.camV) c.camV = [0, 0, 0, 0, 0, 0];
      void9Spring(c.cam, c.camV, tg, 5.5 - 3 * ms, sdt);
      let [lat, hgt, yawO, pitO, foc, roll] = c.cam;
      // lateral offsets fade out round turns and shafts; the camera stays in the nave or in the shaft
      const att = void9Smooth(A.away / 2);
      lat *= att;
      // drop move over 6 beats: barrel roll, sideways sweep or vault rise (in turn)
      c.mvA = Math.min(1, c.mvA + dt * bps / 6);
      const mv = void9Smooth(c.mvA), arc = Math.sin(Math.PI * mv);
      let rollD = 0;   // (v11) a whole barrel roll, added after the zoom scaling (scaled, it left 1.9 rad that snapped at the next drop)
      if (c.dropN === 0) rollD = c.mvDir * 6.2832 * mv;
      else if (c.dropN === 1) yawO += c.mvDir * 1.2 * arc;
      else { pitO += 0.9 * arc * (c.mvUp ?? 1); foc *= 1 - 0.2 * arc; }   // (v11) direction fixed at the drop (it flipped mid-move)
      roll += 0.04 * Math.sin(B * Math.PI / 16);
      // (v15) bank into the corners: the camera leans into a quarter turn like a bird instead of sliding round flat.
      // The bank is a smooth bump over the arc (zero at both ends of every leg), and it rides the same view spring as
      // the rest, so it can never step. Light and view angles only; the path itself is untouched.
      const bank = Math.sin(Math.PI * clamp(A.p[3], 0, 1)) * (A.L.dyaw > 0 ? 1 : A.L.dyaw < 0 ? -1 : 0) * 0.3;
      roll += bank * (1 - 0.7 * zs);
      // now and then, passing straight under a lantern, the camera gazes up the shaft and turns a full circle
      let spinY = 0;   // (v11) a whole turn, added after the zoom scaling below (scaled, it left a fraction of a turn that snapped back)
      // (v13) the spin is an event in time: it is read at the route's present (B), never at the zoom trail, so zooming
      // can never replay or scrub it
      const A0 = Bc === B ? A : void9At(c, B), L0 = A0.L;
      if (L0.spin) { const u = clamp((A0.s - 0.3) / 7.4, 0, 1), bump = Math.pow(Math.sin(Math.PI * u), 2) * (1 - zs); pitO += (1.45 - pitO) * bump; spinY = L0.spin * 6.2832 * void9Smooth(u); lat *= 1 - bump; }
      hgt += 0.8 * c.grow;
      // rise a little over the balustrade of a lantern well
      if (L.lant) hgt = Math.max(hgt, 0.35 + 0.45 * void9Smooth(2.4 - Math.hypot(A.p[0] - L.C[0], A.p[2] - L.C[2])));
      const pv = Math.abs(A.pitch) / (Math.PI / 2), tf = A.L.kind === 'S' ? 0 : A.p[3];
      const pull = 0;
      const hd = VOID9_DIR[tf < 0.5 ? L.d : L.g];
      const vert = pv > 0.5, sg = L.kind === 'D' ? -1 : 1;
      // far out the camera hangs centred at gallery height, so the whole elevation from the mirror floor to the vault
      // fills the wide lens and the nave runs away into the haze
      yawO += spinY; roll += rollD;
      const cy = A.yaw;   // right vector from the unsmoothed heading keeps offsets inside the nave
      const P = A.p;
      let x = P[0] - Math.cos(cy) * lat, y = P[1] + hgt, z = P[2] + Math.sin(cy) * lat;
      if (vert) y -= sg * pull; else { x -= hd[0] * pull; z -= hd[1] * pull; }
      // inside an arch tunnel the camera stays within the arches' opening. The cap is continuous in time: it is the
      // tunnel's top plus 1.6 units per beat of route time to the nearest tunnel entry ahead or exit behind (found by
      // sampling the camera's own future and past positions and bisecting the boundary), so the camera glides down
      // before a tunnel and back up after it
      { // absolute cap height for the camera at route time b (none while the route climbs or dives)
        // (v11) a sample's cap is carried over relative to its own route point, with the height difference to the camera's
        // route point taken modulo the world's 8-level period: samples beyond the level wrap (or across a climb) used to
        // return another level's cap, which pulled the camera ~12 units up into a vault for a few frames
        const per = 8 * c.Ly, wrapD = (d) => d - per * Math.round(d / per);
        const capAt = (a, px, pz) => { if (a.p[4] > 0) return 1e3; const lv = Math.round(a.p[1] / c.Ly), top = void9TunCap(c, px, pz, lv); const dh = wrapD(a.p[1] - A.p[1]); return top > 999 || Math.abs(dh) > 0.9 * c.Ly ? 1e3 : A.p[1] + dh + lv * c.Ly - a.p[1] + top + 0.6 * Math.max(0, Math.abs(dh) - 1); };
        const latC = lat * (1 - zs);   // (v13) the cap is found where the camera will really be (centred when zoomed out)
        const camAt = (b) => { const a = void9At(c, b), t = a.p[3] < 0.5 ? a.L.d : a.L.g, h = VOID9_DIR[t];
          return capAt(a, a.p[0] - Math.cos(a.yaw) * latC - h[0] * pull, a.p[2] + Math.sin(a.yaw) * latC - h[1] * pull); };
        const lim = A.p[1] + 30;
        let cap = Math.min(vert ? 1e3 : capAt(A, P[0] - Math.cos(cy) * latC, P[2] + Math.sin(cy) * latC), lim);
        for (const dir of [1, -1]) {
          let lo = 0, hi = -1, top = lim;
          for (let k = 1; k <= 24; k++) { const b = Bc + dir * k * 0.25; if (b < c.legs[0].tb) break; const v = camAt(b); if (v < 1e3) { hi = k * 0.25; top = v; break; } lo = k * 0.25; }
          if (hi > 0) { for (let it = 0; it < 6; it++) { const m = (lo + hi) / 2, v = camAt(Bc + dir * m); if (v < 1e3) { hi = m; top = v; } else lo = m; } cap = Math.min(cap, top + 1.6 * (hi < 1 ? hi * hi / 2 : hi - 0.5)); }
        }
        // eased (rounds the kink between leaving one tunnel and approaching the next), never more than 0.3 above the cap
        c.capS = Math.min(c.capS == null || Math.abs(c.capS - cap) > 20 ? cap : ease(c.capS, cap, dt, 0.15), cap + 0.3);
        if (y > c.capS - 2.1) y = c.capS - 1.1 - Math.exp(-(y - c.capS + 2.1));
        // (v11) the camera's offset from its route point follows a spring (the route itself is exact and smooth); the
        // tunnel cap is applied to the sprung height as well, so the camera never enters an arch
        const oT = [x - P[0], y - P[1], z - P[2]];
        if (!c.oX) { c.oX = oT.slice(); c.oV = [0, 0, 0]; }
        // near the cap the vertical spring stiffens smoothly (up to x3), so a descending cap never catches the camera
        const omO = 9 - 5 * ms, nearC = clamp((P[1] + c.oX[1] - (c.capS - 3)) / 2, 0, 1);
        const hx = [c.oX[0], c.oX[2]], hv = [c.oV[0], c.oV[2]], yx = [c.oX[1]], yv = [c.oV[1]];
        void9Spring(hx, hv, [oT[0], oT[2]], omO, sdt); void9Spring(yx, yv, [oT[1]], omO * (1 + 2 * nearC * nearC * (3 - 2 * nearC)), sdt);
        c.oX = [hx[0], yx[0], hx[1]]; c.oV = [hv[0], yv[0], hv[1]];
        // (v13) the zoomed-out pose is blended in after the spring: centred over the route point at gallery height, then
        // rising through the cut to just under the next floor (the cut below it); the tunnel cap is released once the
        // tunnel rings have thinned away (shader, same zoom span)
        const tfT = void9Smooth((P[1] + 0.9 * c.Ly) / (0.7 * c.Ly));
      const hZ = c.t0 + 1.4 + (22 + 20 * tfT - c.t0 - 1.4) * sB, cR = void9Smooth((zo - 0.7) / 0.18);
        x = P[0] + c.oX[0] * (1 - zs); y = P[1] + c.oX[1] + (hZ - c.oX[1]) * zs; z = P[2] + c.oX[2] * (1 - zs);
        { const m = c.capS - 0.35, u = (m - y) / 0.3, yc = m - 0.3 * (u > 30 ? u : Math.log1p(Math.exp(u))); y = yc + (y - yc) * cR; } }   // smooth soft-min: no kink
      const pitA = pitch + 0.1 * (1 - pv) - 0.08 * c.grow + PTR.y * inf * 0.04;
      pitch = pitch + pitO * (1 - pv) - 0.08 * c.grow + PTR.y * inf * 0.04;
      foc = (foc * (zm > 1 ? zm : 1) * (1 - 0.5 * zo + 0.2 * sB)) * (1 + 0.25 * c.grow) * (1 - 0.12 * c.burst);
      c.spin = (c.spin + dt * bps * 0.05 * (1 + 3 * c.burst)) % 6.2832;
      const mix = c.pm < 1 ? void9Smooth(c.pm) : 0;
      // (v11) view angles through a spring too; targets are unwrapped to the spring's own turn so a completed barrel roll
      // or lantern spin (a whole turn) never unwinds
      const TAU = 6.283185307, aT = [yaw + yawO + PTR.x * inf * 0.12, clamp(pitch, -1.5, 1.5), roll];
      if (!c.aX) { c.aX = aT.slice(); c.aV = [0, 0, 0]; }
      for (const i of [0, 2]) aT[i] += TAU * Math.round((c.aX[i] - aT[i]) / TAU);
      void9Spring(c.aX, c.aV, aT, 10 - 5.5 * ms, sdt);
      // (v13) zoomed-out view angles, unsprung: the route's heading (averaged over a wider window), pitch tilting down
      // onto the cutaway plan in the second stage; blended in after the spring
      const tfV = void9Smooth((P[1] + 0.9 * c.Ly) / (0.7 * c.Ly));
      const aZ = [yaw + spinY + PTR.x * inf * 0.12, pitA + (-1.12 + 0.55 * tfV - pitA) * sP, rollD], aF = [0, 0, 0];
      // unwrapped against their own previous values (both are continuous; a completed spin or roll restarts at 0)
      if (!c.aZ) c.aZ = [aZ[0] + TAU * Math.round((c.aX[0] - aZ[0]) / TAU), 0, aZ[2] + TAU * Math.round((c.aX[2] - aZ[2]) / TAU)];
      for (const i of [0, 2]) { aZ[i] += TAU * Math.round((c.aZ[i] - aZ[i]) / TAU); c.aZ[i] = aZ[i]; }
      for (let i = 0; i < 3; i++) aF[i] = c.aX[i] + (aZ[i] - c.aX[i]) * zs;
      V.p1 = [x, y, z, foc];
      V.p2 = [aF[0], clamp(aF[1], -1.55, 1.55), aF[2], zm > 1 && zo < 0.01 ? -Math.min(1, (zm - 1) / 1.5) : zo];   // (v13) negative: zoomed in
      V.p3 = [c.grow, c.burst, c.hitW, c.kick];
      // rainbow phase: per palette, eased through palette fades, drifting slowly along with the global hue
      const rp = [0.0, 0.62, 0.05, 0.45, 0.9, 0.3], ra = rp[c.palA], rb = rp[c.palB], rd = ((rb - ra + 1.5) % 1) - 0.5;
      // uP4.w: rainbow phase (fraction) + 60 x blackout (integer part; the shader only reads the phase through fract)
      V.p4 = [c.rv, c.ya, c.ys, (((ra + rd * mix) + 0.05 * Math.sin(B * Math.PI / 64) + c.rc) % 1 + 1) % 1 + Math.round(60 * clamp(c.bk, 0, 1)) + 64 * (c.ev || 0) + 256 * Math.round(31 * clamp(c.evA || 0, 0, 1))];   // (v12) + set piece kind and amount
      // (v13) uP5.w: the cut plane's height (1e4 = none); the level height is a shader constant now
      { const cut = P[1] + 3 * c.Ly + (c.ys + 0.4 - 3 * c.Ly) * wC, tfC = void9Smooth((P[1] + 0.9 * c.Ly) / (0.7 * c.Ly)), cutT = cut + (120 - cut) * tfC;
        V.p5 = [c.kickW, c.spin, c.glass, wC > 0 && cutT < 119 ? cutT : 1e4]; }
      const pc = void9Colour(c.palA, c.palB, mix, 0.3 * Math.sin(((typeof D !== 'undefined' && Number.isFinite(D.hue)) ? D.hue : 0) * 6.2832));
      // the engine brightens the whole frame on a drop: hold this realm's colours back so the flash stays coloured, not white
      const dk = 1 / (1 + 0.5 * F.drop * F.drop);
      for (let i = 0; i < 15; i++) pc[i] *= dk;
      V.m1 = pc.subarray(0, 9);
      // uM2[2]: aisle vault ratio, route seed + 4 x rose petals, light shaft gain
      // (v18) smoothed bass: the one signal geometry may follow (attack 120 ms, release 400 ms), packed in the seed's fraction
      { const sb = clamp(Math.max(F.bass * 0.85, F.kick), 0, 1); c.smB = ease(c.smB || 0, sb, dt, sb > (c.smB || 0) ? 0.12 : 0.4); }
      V.m2 = new Float32Array([pc[9], pc[10], pc[11], pc[12], pc[13], pc[14], c.ka, c.seed + 4 * c.pet + clamp(c.smB * 0.98, 0, 0.98), c.sh]);
      c.dbg = 'f' + (c.famA ?? c.fam) + '>' + (c.famB ?? c.fam) + ' m' + (c.mood || 0) + ' ev' + (c.ev || 0) + ' sh' + c.shot;
      // (v11) the live journey, for a reseeded visit to pick up (void9Continue)
      if (!VOID9_J || VOID9_J.c === c || void9Tick() - VOID9_J.fc > 3) VOID9_J = { c, B, fc: void9Tick() };
    }
  },
