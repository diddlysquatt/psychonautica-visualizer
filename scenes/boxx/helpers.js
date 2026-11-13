/* ---- BOXX 7 v12 helpers: the self-similar box dive, now played by the music ----
   Level n+1 lives inside level n's special box: x(n+1) = K R (x(n) - C), K = 10, R = yaw by TH. The camera's level
   phase u in [0,1) puts it at p(u) = F + K^-u R^-u (p0 + w - F) (F the fixed point), so at u = 1 it stands exactly
   where u = 0 of the next level puts it: the swap is invisible. w (sway) and the look-around are windowed to zero at
   the doors. Constants match the shader's BX* defines.
   v12: eleven world kinds; geometry envelopes for the shader (bass swell, two kick hop rings, hat lids, Rubik twist,
   snare burst, the unfolding box); the dive speed swells with the energy; drops crash through (plunge, burst, the
   box ahead unfolds, confetti); phrase set pieces (pull-outs that show the world was inside a box, unfolding boxes). */
const BOXX_K = 10, BOXX_TH = 0.5, BOXX_F = [0, -0.6, 0.2], BOXX_P0 = [0, -0.22, -0.94], BOXX_NS = 16;
function boxxRotY(v, a) { const c = Math.cos(a), s = Math.sin(a); return [c * v[0] + s * v[2], v[1], -s * v[0] + c * v[2]]; }
function boxxHash(x) { const s = Math.sin(x * 12.9898 + 78.233) * 43758.5453; return s - Math.floor(s); }
function boxxSS(a, b, x) { const t = Math.min(1, Math.max(0, (x - a) / (b - a))); return t * t * (3 - 2 * t); }
// world kind of level n: ten truly different worlds in seeded shuffled blocks (a block never starts with the kind that
// ended the last), so every world comes round once per ten. The fraction is the world's own layout seed.
function boxxStyle(c, n) {
  n = Math.max(0, n);
  const N = BOXX_NS, m = Math.floor(n / N);
  c.perm = c.perm || [];
  for (let j = c.perm.length; j <= m; j++) {
    const p = c.order.slice();
    for (let i = N - 1; i > 0; i--) { const r = Math.floor(boxxHash(c.k + j * 9.7 + i * 1.3) * (i + 1)); [p[i], p[r]] = [p[r], p[i]]; }
    if (j > 0 && p[0] === c.perm[j - 1][N - 1]) p.push(p.shift());
    c.perm.push(p);
  }
  return c.perm[m][n % N] + Math.min(0.99, boxxHash(n * 7.13 + c.k));
}
function boxxInit(s) {
  const k = Math.floor(s[0] * 997) + s[1] * 13;
  const order = Array.from({ length: BOXX_NS }, (_, i) => i);
  for (let i = BOXX_NS - 1; i > 0; i--) { const j = Math.floor(boxxHash(k + i * 1.7) * (i + 1)); [order[i], order[j]] = [order[j], order[i]]; }
  return {
    k, order, s: 3 + s[2] * 0.6, v: 0.14, lag: 0, lagT: 0, lt: null, bars: 0, plunge: 0, win: 0, calm: 0, build: 0, en: 0.5,
    sw: [0, 0], swV: [0, 0], look: [0, 0], lookV: [0, 0], roll: 0, reveal: 0, revealL: 0.42, lastLev: null, tgt: [0, 0, 0, 0], zk: 1, tf: 0.53,
    ra: 9, rb: 9, dAge: 99, bassG: [0.4], bassV: [0], lid: [0], lidV: [0], tw: [0], twV: [0], twT: 0, ex: [0], exV: [0], exT: 0,
    unf: 0, unfLev: -1, unfE: 0, lastBeat: null,
    dp: [0], dpV: [0], dpT: 0, dpAge: 9, dBi: null, fmA: Math.floor(boxxHash(k * 3.3) * 5), fmB: Math.floor(boxxHash(k * 3.3) * 5), fm: [1], fmV: [0], fmN: 0
  };
}
// critically damped spring toward g (x, v arrays), time constant tau
function boxxSpring(x, v, g, dt, tau) {
  const w=1/Math.max(tau,.02),e=Math.exp(-w*dt);
  for(let i=0;i<x.length;i++){const d=x[i]-g[i],q=v[i]+w*d;x[i]=g[i]+(d+q*dt)*e;v[i]=(v[i]-w*q*dt)*e;}
}
function boxxFrame(V, F, dt) {
  const c = V.c, dz = S.dose, ms = clamp(Number(S.motionSmooth ?? 0.75) || 0, 0, 1);
  dt = Math.min(Math.max(dt, 0), 0.1);
  if (c.lt === null) c.lt = V.trav;
  const dTr = clamp(V.trav - c.lt, 0, 0.5); c.lt = V.trav;
  // v22: a real arrival (F.onImpact at drop strength) crashes through exactly as a detected drop does, in any genre
  const imp = F.onImpact ? (F.impactStrength || 0) : 0;
  const dropEv = (F.onDrop || (F.drop > 0.85 && (c.prevDrop || 0) < 0.5) || imp >= 0.8) && !(c.dAge < 1.2); c.prevDrop = F.drop;
  const BL = (typeof BANDS !== 'undefined' && BANDS.lv) ? BANDS.lv : [0, 0, 0, 0, 0, 0, 0, 0];
  const BO = (typeof BANDS !== 'undefined' && BANDS.on) ? BANDS.on : [0, 0, 0, 0, 0, 0, 0, 0];
  // v13: the band levels sit near 1 all through a dense mix (they are auto-ranged), so on their own they make the
  // city glow steadily instead of playing. Each band's drive is now its level above its own recent mean (1.6 s): a
  // part that comes in, swells or hits shows; a part that just sits there settles to a calm base.
  c.m8 = c.m8 || new Float32Array(8).fill(0.5); c.dv = c.dv || new Float32Array(8);
  for (let i = 0; i < 8; i++) {
    const L = BL[i] || 0; c.m8[i] += (L - c.m8[i]) * (1 - Math.exp(-dt / 1.6));
    c.dv[i] = clamp(0.28 * L + 0.95 * clamp((L - c.m8[i]) / Math.max(0.1, 1 - c.m8[i]), 0, 1), 0, 1);
  }
  const DV = c.dv;
  c.calm = ease(c.calm, F.breakdown || 0, dt, 1.2);
  c.build = ease(c.build, Math.max(F.build || 0, F.tension || 0), dt, 0.8);
  c.en = ease(c.en, clamp(F.levelS ?? F.level ?? 0.5, 0, 1.2), dt, 1.4);
  if (dropEv) { c.plunge = 1; c.win = 1; c.lagT = 0; c.reveal = 0; c.dAge = 0; c.exT = 1.5; c.unfDrop = true; }
  c.plunge = Math.max(0, c.plunge - dt / 3.4);
  c.win = Math.max(0, c.win - dt / 2.2);
  c.dAge += dt;
  // phrase set pieces: on some 8-bar lines the camera pulls right out (half a level, or a whole one: the world you
  // were in turns out to be inside a box) and then dives again
  if ((F.onBar || F.onSceneBar)) {
    c.bars++;
    if (c.bars % 8 === 0 && !c.reveal && c.zo < 0.1 && boxxHash(c.bars * 0.37 + c.k) < 0.35) {
      c.reveal = 2 * 4 * 60 / Math.max(60, F.bpm || 120);
      c.revealL = boxxHash(c.bars * 1.91 + c.k) < 0.5 ? 1.12 : 0.45;
    }
  }
  if (c.reveal > 0) c.reveal = Math.max(0, c.reveal - dt);
  // dive speed: one level per four bars on the beat clock, swelling with the energy (0.55x quiet .. 1.5x loud), a drop
  // plunges; a critically damped spring keeps it smooth (the Motion smoothness dial slows the spring)
  const beatRate = dt > 0 ? dTr / dt : 0;
  // (v13: about 0.7x the v12 speed; the fast dive made the dense worlds shimmer)
  const vT = 0.64 * Math.max(beatRate, 1.1) / 16 * (0.55 + 0.95 * clamp(c.en, 0, 1)) * (1 + 1.6 * c.plunge * c.plunge) * (1 - 0.35 * c.calm) * (0.6 + 0.4 * (S.speed ?? 1));
  c.v += (vT - c.v) * (1 - Math.exp(-dt / (0.5 + 1.2 * ms)));
  // v15: the zoom is a camera move inside the current world again -- pulled out you rise off the avenue until the world
  // stands as a diorama on its plinth among a field of box-worlds, and pushed in you drop to street level between the
  // lots. It never steers the dive: travel runs on the music alone (the showcase pull-back below is a timed camera move
  // of its own). Only a viewer who pulls right out holds the dive, so the world under the far camera cannot change
  // under them mid-look.
  const zk=clamp((PTR.zoom||1)*(V.kz??1),.1,4);c.zk=zk;
  c.tourTime=(c.tourTime||0)+dt*S.speed;
  const overview=.5-.5*Math.cos(c.tourTime*Math.PI/24);
  // The engine's own showcase tour glides PTR.zoom between 0.6 and 1.35 all the time. That is its framing move, not the
  // viewer asking to be pulled out, so the camera's zoom move starts OUTSIDE that range: the tour only changes the lens
  // (exactly as in the merged base), and a real wheel/pinch past 0.6 or 1.35 is what lifts the camera off the avenue or
  // drops it to street level. This keeps the zoom camera and removes a permanent dolly from normal playback.
  const zoU=clamp(Math.log(.6/zk)/Math.log(4.),0.,1.15),ziU=clamp(Math.log(zk/1.35)/Math.log(2.5/1.35),0.,1.0);
  const zo=zoU,zi=ziU;c.zo=zo;
  // the hold only applies while the pull-back is actually open (it closes over a door passage), so a dive through a door
  // always finishes and the far view arrives a moment later. (computed from c.s directly: the lagged u comes later)
    c.s+=Math.max(.065*(S.speed??1),c.v)*dt*(S.speed>0?1:0);
  c.lagT = 0.28 * c.build * dz + (c.reveal > 0 ? c.revealL : 0);
  c.lag += (c.lagT - c.lag) * (1 - Math.exp(-dt / ((c.lagT > c.lag ? 1.6 : 0.7) * (0.6 + 0.6 * ms)))) * 1;
  const sc = c.s - c.lag, n = Math.floor(sc), rawU = sc - n;
  // Periodic speed easing: equal endpoint derivatives preserve the self-similar doorway identity.
  const u=rawU-.055*Math.sin(2*Math.PI*rawU);
  c.uP = u;
  if (c.lastLev !== n || ((F.onBar || F.onSceneBar) && c.bars % 4 === 0)) {
    if (c.lastLev !== n) {
      // the box of this level unfolds (about one in three, and the one a drop lands on); decided while the level
      // starts, where the unfold window is still closed, so nothing pops
      const want = c.unfDrop || boxxHash(n * 2.17 + c.k * 0.3) < 0.34;
      if (c.unfLev !== n) { c.unfLev = n; c.unf = want ? 1 : 0; if (u < 0.3) c.unfE = c.unf; c.unfDrop = false; }
    }
    c.lastLev = n; const h = (j) => boxxHash(n * 5.3 + c.bars * 0.11 + j + c.k);
    c.tgt = [(h(1) - 0.5) * 0.9, (h(2) - 0.5) * 0.22, (h(3) - 0.5) * 0.14, (h(4) - 0.5) * 0.08];
  }
  if (c.unfDrop && u < 0.55) { c.unf = 1; c.unfDrop = false; }
  if (c.reveal > 0 && c.revealL > 1) c.unf = 1;
  c.unfE = ease(c.unfE, c.unf, dt, 0.5);
  const tau = 1.1 + 1.6 * ms;
  const bass = F.bassS ?? F.bass, high = F.highS ?? F.high;
  boxxSpring(c.look, c.lookV, [c.tgt[0], c.tgt[1] - 0.04 * bass * dz + 0.03 * high * dz], dt, tau);
  boxxSpring(c.sw, c.swV, [c.tgt[2], c.tgt[3]], dt, tau * 1.3);
  const a = boxxSS(0.03, 0.3, u) * (1 - boxxSS(0.6, 0.92, u));
  const F0 = BOXX_F, P0 = BOXX_P0, K = BOXX_K;
  // zoomed in, the camera rides lower down the avenue (street level between the boxes; the path still threads the
  // door, every level the same, so the swaps stay invisible) and looks a little further up the facades
  const zin = boxxSS(0, 1, zi) + 0.15 * Math.max(0, zi - 1);
  const relY = P0[1] - F0[1] - 0.25 * zin;
  const rel = [P0[0] - F0[0] + c.sw[0] * a, relY + c.sw[1] * a, P0[2] - F0[2]];
  const ku = Math.pow(K, -u), r = boxxRotY(rel, -BOXX_TH * u);
  let pos = [F0[0] + ku * r[0], F0[1] + ku * r[1], F0[2] + ku * r[2]];
  const d0 = v3.norm([0, -relY + 0.09 * zin, F0[2] - P0[2]]);
  const t0 = v3.norm([0.57, -0.875, 2.625]);
  let f = v3.norm([d0[0] + t0[0], d0[1] + t0[1], d0[2] + t0[2]]);
  f = boxxRotY(f, -c.look[0] * a);
  { const hz = Math.hypot(f[0], f[2]), el = Math.atan2(f[1], hz) + c.look[1] * a;
    f = [f[0] / hz * Math.cos(el), Math.sin(el), f[2] / hz * Math.cos(el)]; }
  f = boxxRotY(f, -BOXX_TH * u);
  // v18: zoomed out the dive still runs at every zoom. Pulled out, each level becomes an arc: the camera rises high over
  // the world soon after its door, looks down on the whole place, then swoops back to thread the next door, so the box
  // dive never stops (the arc is zero at both doors, so the level swap stays invisible).
  const la = boxxSS(0, 1, zoU), arcW = boxxSS(0.02, 0.32, u) * (1 - boxxSS(0.7, 0.97, u));
  const bo = la * arcW;
  if (bo > 0) {
    // the rise is scaled by the camera's distance to the door (ku), so by the time it reaches the door the arc has closed
    const ar = Math.pow(Math.min(1, ku * 2.2), 0.7);
    pos = [pos[0] + (F0[0] - pos[0]) * 0.3 * bo * ar, pos[1] + (0.42 + 0.52 * la) * bo * ar, pos[2] + (F0[2] - pos[2]) * 0.3 * bo * ar];
    const P = [BOXX_F[0], -0.5, BOXX_F[2]], fo = v3.norm([P[0] - pos[0], P[1] - pos[1], P[2] - pos[2]]);
    f = v3.norm(f.map((x, i) => x + (fo[i] - x) * bo * ar));
  }
  const mt = 0;
  const rollT = (0.05 + 0.5 * c.lookV[0] * a) * (1 - bo);
  c.roll += (rollT - c.roll) * (1 - Math.exp(-dt / (0.4 + 0.6 * ms)));
  let rt = v3.norm(v3.cross([0, 1, 0], f)); let up = v3.cross(f, rt);
  const cr = Math.cos(c.roll), sr = Math.sin(c.roll);
  const rt2 = [rt[0] * cr + up[0] * sr, rt[1] * cr + up[1] * sr, rt[2] * cr + up[2] * sr];
  up = [up[0] * cr - rt[0] * sr, up[1] * cr - rt[1] * sr, up[2] * cr - rt[2] * sr];
  // the lens: a little wider zoomed out, a little longer zoomed in (no smoothing here: the engine's spring is enough)
  // the lens: a little longer when the viewer pushes in, a little wider when pulled out, but never a fisheye (the far
  // view is a camera move, so it does not need a 120-degree lens to fill the frame)
  const ziL = Math.min(ziU, 1), zoL = Math.min(zoU, 1);
  c.tf = Math.min(0.92, 0.53 * (1 + 0.42 * zoL) / ((1 + 0.16 * ziL) * Math.pow(zk, .42)));
  // ---- the music's geometry (springs: attack >= 60 ms, release >= 200 ms; light may snap, shapes never do)
  // kick: two hop rings take turns, so a wave always runs out to the end before its ring restarts
  const bon = Math.max(BO[0], BO[1]), kickOn = F.onKick || (bon > 0.6 && (c.bon || 0) <= 0.6); c.bon = bon;
  if (kickOn && Math.max(c.ra, c.rb) > 0.3) { if (c.ra >= c.rb) { if (c.ra > 0.9) c.ra = 0; } else if (c.rb > 0.9) c.rb = 0; }
  c.ra += dt; c.rb += dt;
  // bass swell: the bassline lifts the whole city (builds lift it, breakdowns lower it)
  const bl = Math.max(DV[0], DV[1]) * dz;
  boxxSpring(c.bassG, c.bassV, [clamp(0.35 + 0.75 * bl + 0.3 * c.build - 0.25 * c.calm, 0, 1.25)], dt, bl > c.bassG[0] ? 0.13 : 0.32);
  // hats: lids and flaps flip open (the hat envelope or the top bands' onsets)
  const hat = clamp(Math.max(F.hat || 0, 0.8 * Math.max(BO[6], BO[7])) * dz, 0, 1.2);
  c.lidT = Math.max((c.lidT || 0) - dt * 5, hat);
  boxxSpring(c.lid, c.lidV, [c.lidT], dt, 0.055);
  // snare: stacks burst apart and settle; a drop bursts everything wide
  if (F.onHit) c.exT = Math.max(c.exT, 0.75 * clamp(F.hit || 0.8, 0.5, 1) * dz);
  c.exT = Math.max(0, c.exT - dt * (c.exT > 0.8 ? 0.9 : 2.6));
  boxxSpring(c.ex, c.exV, [c.exT], dt, 0.07);
  // v22 the dance. Every kick steps the height wave half a turn: the rows that stood tall sink as their neighbours rise
  // (a 60 ms spring: a punch, not a sway). With no kick to follow, the beat clock steps it; in silence it rests.
  // Impacts and section changes re-form the wave (rings round the box, rows, columns, two diagonals), and a strong
  // impact bursts the stacks as the snare does.
  c.dpAge += dt;
  { const bi = Math.floor((F.conf > 0.45 && !F.silent) ? F.beatClock : V.trav), beatS = 60 / Math.max(60, F.bpm || 120);
    if (c.dBi === null) c.dBi = bi;
    if (kickOn && c.dpAge > 0.2) { c.dpT += Math.PI; c.dpAge = 0; }
    else if (bi !== c.dBi && c.dpAge > 0.9 * beatS && !F.silent && c.en > 0.06) { c.dpT += Math.PI; c.dpAge = 0.25; }
    c.dBi = bi; }
  if (c.dpT > 60) { c.dpT -= 20 * Math.PI; c.dp[0] -= 20 * Math.PI; }
  boxxSpring(c.dp, c.dpV, [c.dpT], dt, 0.06);
  if ((imp >= 0.45 || F.onSection) && c.fm[0] > 0.9) {
    c.fmN++; c.fmA = c.fmB; c.fmB = (c.fmB + 1 + Math.floor(boxxHash(c.fmN * 4.7 + c.k + (F.sectionSeed || 0) * 31) * 4)) % 5; c.fm[0] = 0; c.fmV[0] = 0;
  }
  if (imp >= 0.45) c.exT = Math.max(c.exT, 1.1 * imp * dz);
  boxxSpring(c.fm, c.fmV, [1], dt, 0.11);
  // Rubik / toy towers twist a quarter turn every second beat
  const bq = Math.floor(((F.conf > 0.45 && !F.silent) ? F.beatClock : V.trav) / 2); if (c.lastBeat === null) c.lastBeat = bq; if (bq !== c.lastBeat) { c.twT += Math.PI / 2; c.lastBeat = bq; }
  if (c.twT > 60) { c.twT -= 20 * Math.PI; c.tw[0] -= 20 * Math.PI; }
  boxxSpring(c.tw, c.twV, [c.twT], dt, 0.075);
  V.p1 = [pos[0], pos[1], pos[2], c.tf];
  V.m1 = new Float32Array([...rt2, ...up, ...f]);
  const hon = Math.max(BO[6], BO[7]), hatOn = (hat > 0.5 && (c.hatP || 0) <= 0.5) || (hon > 0.6 && (c.hon || 0) <= 0.6); c.hatP = hat; c.hon = hon;
  c.hf = Math.max((c.hf || 0) * Math.exp(-dt / 0.16), hatOn ? 1 : 0);
  V.p2 = [clamp(c.bassG[0], 0, 1.3), c.rb, c.fmA + 8 * c.fmB + 64 * Math.round(clamp(c.fm[0], 0, 1) * 100), c.tw[0]];
  V.p3 = [boxxStyle(c, n), boxxStyle(c, n + 1), boxxStyle(c, n + 2), boxxStyle(c, n + 3)];
  V.p4 = [boxxStyle(c, n + 4), c.dAge, c.ra, c.dp[0]];
  // the unfold opens over the approach and is fully shut whenever the level swaps (u = 0 and u = 1 are both closed
  // for the next box, which only opens in its own level)
  const U = c.unfE * boxxSS(0.28, 0.72, u);
  // hats tick the avenue's chase lights forward one step each (eased over ~70 ms); packed with calm into p5.z
  if (hatOn) c.chT = (c.chT || 0) + 0.5;
  c.chP = (c.chP || 0) + ((c.chT || 0) - (c.chP || 0)) * (1 - Math.exp(-dt / 0.035));
  if (c.chT > 64) { c.chT -= 64; c.chP -= 64; }
  const chF = c.chP - Math.floor(c.chP);
  V.p5 = [U, clamp(c.hf * dz, 0, 1.98) + 2 * Math.round(clamp(c.build * dz, 0, 0.99) * 100), c.calm * 0.8 + 2 * Math.min(99, Math.round(chF * 100)), clamp(c.ex[0], 0, 1.8)];
  // light envelopes: 8 bands and the kick, attack 70 ms, release 260 ms
  c.bl = c.bl || new Float32Array(9);
  for (let i = 0; i < 9; i++) {
    const x = i < 8 ? DV[i] : (F.kick || 0);
    c.bl[i] += (x - c.bl[i]) * (1 - Math.exp(-dt / (x > c.bl[i] ? 0.07 : 0.3)));
  }
  V.m2 = new Float32Array(c.bl); V.m2[8] *= 1 - 0.6 * mt; // far out the kick shows in the hops more than the light
}
