// SWARM helpers: seeded rng, family table, morph/colour-wave triggers, phrase director
// families: 0 torus 1 knot 2 blob 3 rings 4 galaxy 5 helix 6 tree 7 armillary 8 lotus 9 serpent 10 vortex 11 waves 12 chain
// 13 heart 14 flight 15 fountain (v22: 9 was the murmuration slab, 12 the dancer doing jumping jacks, 14 the single butterfly)
const SWARM_RB = [1.32, 1.25, 1.32, 1.22, 1.6, 3.6, 1.75, 1.42, 1.9, 1.9, 1.3, 1.6, 2.65, 1.6, 2.05, 2.05]; // bounding radius per family at scale 1
const SWARM_TILT = [0.5, 0.45, 0.1, 0.25, 1.0, 0.0, 0.08, 0.3, 0.35, 0.4, 0.1, 0.55, 0.45, 0.0, 0.42, 0.16];  // how much each family leans toward the camera
const SWARM_SIZE = [1, 1, 1.02, 1, 1.3, 1.0, 1.0, 1.0, 1.05, 1.0, 1.0, 1.05, 1.0, 1.0, 1.05, 0.95];   // world scale per family
const SWARM_ROLL = [0, 0, 0, 0, 0, 0.75, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];   // screen-plane lean (the helix crosses the frame diagonally)
const SWARM_UPR = [0, 0, 0, 0, 0, 1, 1, 0, 0.4, 0, 0.8, 0, 0, 1, 0.2, 1];   // keep the axis upright and in the screen plane
const SWARM_FR = [1.4, 1.3, 1.45, 1.25, 1.45, 1.7, 1.5, 1.1, 1.6, 1.62, 1.3, 1.4, 1.95, 1.38, 1.75, 1.95];
// figures that turn to face the viewer (the dancer, the face, the heart; the butterfly mostly)
const SWARM_FACE = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]; // framing radius: what should fill the frame height
// v22 choreographies (0 one body): [bodies, how far out their centres go, body scale, core scale]: binary, weave of four, three on a figure-eight,
// core and three moons, comet train (the same numbers as swSet in the shader)
const SWARM_MD = [[1, 0, 1, 0], [2, 1.35, 0.62, 0], [4, 1.98, 0.45, 0], [3, 1.66, 0.52, 0], [4, 1.8, 0.33, 0.64], [4, 1.6, 0.58, 0], [1, 0, 1, 0], [1, 0, 1, 0]];
const SWARM_FL = 1.35;   // the lens (the shader's fl)
// a random split for figure f (the totem never stacks the tall figures)
function swarmForm(c, f) {
  // v18: the next formation, from a shuffled bag (never the same one twice running; tall figures never stack)
  for (let i = 0; i < 6; i++) {
    if (!c.fb || !c.fb.length) c.fb = swarmShuffle([0, 0, 0, 1, 1, 2, 3, 3, 4, 5], c.r);
    const m = c.fb.pop(); if (m !== c.mdB && !(m > 1 && (f === 5 || f === 12)) && !(m > 0 && f === 14) && !((m === 2 || m === 4 || m === 5) && (f === 6 || f === 15 || f === 14))) return m;   // v22: the tallest and widest sculptures only alone or as a binary
  }
  return 0;
}
// v20: the next string-art mode, from a shuffled bag (0 solid surface, 1 hoops, 2 meridians, 3 cage, 4 one spiral winding, 5 a net of two)
function swarmSlice(c) {
  if (!c.sb || !c.sb.length) c.sb = swarmShuffle([0, 0, 0, 0, 1, 1, 2, 3, 3, 4, 5, 5], c.r);
  return c.sb.pop();
}
function swarmRng(s) { let a = Math.floor(s * 2147483646) + 1; return () => { a = (a * 16807) % 2147483647; return a / 2147483647; }; }
function swarmShuffle(arr, r) { for (let i = arr.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [arr[i], arr[j]] = [arr[j], arr[i]]; } return arr; }
function swarmMul(a, b) { const o = new Float32Array(9); for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) o[j * 3 + i] = a[i] * b[j * 3] + a[3 + i] * b[j * 3 + 1] + a[6 + i] * b[j * 3 + 2]; return o; }
function swarmAxis(u, a) {
  const c = Math.cos(a), s = Math.sin(a), t = 1 - c, [x, y, z] = u;
  return new Float32Array([t * x * x + c, t * x * y + s * z, t * x * z - s * y, t * x * y - s * z, t * y * y + c, t * y * z + s * x, t * x * z + s * y, t * y * z - s * x, t * z * z + c]);
}
function swarmT(m) { return new Float32Array([m[0], m[3], m[6], m[1], m[4], m[7], m[2], m[5], m[8]]); }
// radius of family f under split behaviour md (the copies sit on a ring)
function swarmRad(arr, f, md) { const m = SWARM_MD[md]; return md ? Math.max(m[1] + arr[f] * m[2] * 1.32, arr[f] * m[3]) : arr[f]; }
// what should fill the frame: a choreography is framed tighter than its full reach, so its bodies stay large and swing out of the frame and back
function swarmFrR(f, md) { const m = SWARM_MD[md]; return md ? Math.max(m[1] * 0.7 + SWARM_FR[f] * m[2], SWARM_FR[f] * m[3] * 1.5) : SWARM_FR[f]; }
// morph to figure fig (default: the next in the playlist) with split behaviour md
function swarmMorph(c, dur, ex, fig, md) {
  if (fig == null) { c.si = (c.si + 1) % c.seq.length; fig = c.seq[c.si]; c.prm[fig] = c.r(); }
  c.figB = fig; c.mdB = md == null ? swarmForm(c, fig) : md; c.slB = swarmSlice(c); c.mt = 0; c.mDur = dur;
  c.ex = Math.max(c.ex, ex); c.shR = 0.3; c.exMax = c.ex;
  if (c.r() < 0.5) c.ring = 1 - c.ring;
}
function swarmLog(c, n) { c.sp = n; c.spN = (c.spN || 0) + 1; }
function swarmWave(c, palTo, offTo, speed) {
  if (c.wp < 1.7) { c.palF = c.palT; c.offF = c.offT; }
  c.palT = palTo; c.offT = ((offTo % 1) + 1) % 1; c.wp = -1.7; c.wv = speed; c.wd = c.r() * 6.283;
}
// v21: exact critically damped spring step (stable at any dt); and the dance moves of a phrase: 0 nod (the figure dips toward the
// lens on each kick and comes back), 1 spin step (it turns a notch on every snare), 2 lean (it leans left, right, on the beat),
// 3 shiver (its dots jump along their flow on every hat), 4 swell (it puffs up on every snare), 5 ripple (every kick sends a deep
// ripple out through it). One or two at a time, chosen with weights from running tallies of this music's kicks, snares, bass
// weight and hats, so two songs do not get the same dance; a new phrase and every drop deal again.
function swarmSpr(s, tgt, w, dt) { const d = s.x - tgt, e = Math.exp(-w * dt), u = (s.v + w * d) * dt; s.x = tgt + (d + u) * e; s.v = (s.v - w * u) * e; }
function swarmDancePick(c) {
  const m = c.mu, w = [0.3 + m[0], 0.25 + m[1], 0.25 + m[2], 0.15 + m[3], 0.2 + m[1], 0.2 + m[0], 0.3], r = c.r2;
  let x = r() * w.reduce((a, v) => a + v, 0), k = 0; while (k < 6 && (x -= w[k]) > 0) k++;
  c.dn = k > 5 ? [] : r() < 0.45 ? [k, (k + 1 + Math.floor(r() * 5)) % 6] : [k];
}
function swarmFrame(V, F, dt) {
  const c = V.c, sp = S.speed, dose = S.dose;
  dt = Math.min(Math.max(dt, 0), 0.1);
  if (c.lt === null) c.lt = V.trav;
  if (!c.r2) c.r2 = swarmRng((V.seed[0] * 0.731 + V.seed[1] * 0.419 + 0.137) % 1);   // v21: a private generator for everything new, so the visit's own sequence is undisturbed
  const dtr = clamp(V.trav - c.lt, 0, 0.5); c.lt = V.trav;
  let drop = F.onDrop;
  // review hooks (unused in normal play): SWARM_FORCE pins a family (SWARM_MDF its split), SWARM_DROP fires a drop
  // after N beats, SWARM_EV forces the next phrase event ('vista','nova','dust','dancer','fly','skim','crown','drift')
  const W = typeof window !== 'undefined' ? window : {};
  if (W.SWARM_FORCE != null && c.mt >= 1) { c.figA = c.figB = W.SWARM_FORCE; c.mdA = c.mdB = W.SWARM_MDF || 0; if (W.SWARM_PRM != null) c.prm[c.figA] = W.SWARM_PRM; }
  if (W.SWARM_TOUR) { if (W.SWARM_T0 == null) W.SWARM_T0 = V.trav; W.SWARM_FORCE = Math.floor((V.trav - W.SWARM_T0) / W.SWARM_TOUR) % 16; }
  if (W.SWARM_FORM != null && c.mt >= 1) c.mdA = c.mdB = W.SWARM_FORM;
  if (W.SWARM_SL != null && c.mt >= 1) c.slA = c.slB = W.SWARM_SL;
  if (W.SWARM_DROP != null) { c.tDrop = W.SWARM_DROP; W.SWARM_DROP = null; }
  if (c.tDrop != null && V.trav >= c.tDrop) { drop = true; c.tDrop = null; W.SWARM_FORCE = null; }
  if ((F.onBar || F.onSceneBar)) { c.bars++; if (c.vis > 0) c.vis--; if (c.fly > 0) c.fly--; if (c.skim > 0) c.skim--; if (c.crown > 0) c.crown--; }
  const B = typeof BANDS !== 'undefined' ? BANDS.lv : null;
  // v22 MUSIC STRUCTURE CUES. An impact (the graded "bam") bursts the swarm: a real arrival (>= .45, or the old drop) blows it into a cloud that
  // re-forms as the next sculpture in a new choreography, palette and camera mode, as hard as the impact is strong; a modest one bursts it and lets
  // it fall back into the same sculpture. A new section changes the formation (and half the time the sculpture too), the palette region, the aim
  // and the dance. Tension (below, with the old build) draws everything in tight until the impact lets it go.
  c.tTr = (c.tTr ?? 9) + dt;
  const imp = (W.SWARM_IMP != null ? W.SWARM_IMP : F.onImpact ? F.impactStrength || 0.5 : 0); if (W.SWARM_IMP != null) W.SWARM_IMP = null;
  const sec = !!(F.onSection || W.SWARM_SEC); W.SWARM_SEC = null;
  let dropS = drop ? 1 : 0;
  if (!drop && imp >= 0.45) { drop = true; dropS = 0.5 + 0.5 * imp; }
  else if (!drop && imp > 0 && c.tTr > 1.5) {   // a punch: burst and fall back
    c.ex = Math.max(c.ex, 0.3 + 0.7 * imp); c.shR = 0.3; c.exMax = c.ex; c.kv += 10 + 10 * imp;
    if (c.mt >= 1 && !c.spA) { swarmMorph(c, 1.2, 0.3 + 0.7 * imp, c.figA, c.mdA); c.tTr = 0; swarmLog(c, 'punch'); }
  }
  if (!drop && sec && c.mt >= 1 && !c.spA && c.tTr > 2.5) {   // a new chapter: the formation changes
    const same = (F.sectionSeed ?? c.r2()) < 0.5; swarmMorph(c, 2.0, 0.3, same ? c.figA : null); c.tTr = 0;
    c.pi = (c.pi + 1) % c.pals.length; swarmWave(c, c.pals[c.pi], c.r(), 3.2);
    c.sw += (c.r() < 0.5 ? -1 : 1) * (0.8 + 0.6 * c.r()); c.elT = (c.r() - 0.5) * 0.7; c.bars = 0; c.rollT = (c.r() - 0.5) * 0.44;
    c.cyT = 0.1 + 0.65 * c.r2(); c.cxT = (c.r2() - 0.5) * 0.9; if (c.mu) swarmDancePick(c);
    { const u = c.r2(); if (u < 0.3) { c.crown = 4; c.skim = 0; } else if (u < 0.5) { c.skim = 4; c.crown = 0; } else if ((F.secEnergy ?? 0.5) < 0.3) c.vis = 4; }   // a quiet chapter may open wide
    c.lastEv = 'section'; swarmLog(c, 'section');
  }
  if (drop) { c.tTr = 0;
    // the drop: the figure explodes into a cloud that condenses into the next family (sometimes already split into
    // twins/trio/ring), a shock shell of sparks races outward through the whole universe, the palette flips behind
    // a fast colour front and the camera swoops; every third drop also pulls the camera back for a phrase
    // set-pieces resolve on the drop: the collapsing vortex bursts into a galaxy (or the next figure), the grown tree
    // blossoms in place (full crown, spark shell) and holds into the next phrase
    if (c.spA === 'growth' && c.figB === 6) { c.ex = 1; c.shR = 0.3; c.bloom = 1; c.kv += 10; swarmLog(c, 'blossom'); }
    else if (c.mt >= 0.7) {
      swarmMorph(c, 1.4, dropS, c.spA === 'collapse' ? (c.r() < 0.35 ? 4 : null) : null);
      if (c.spA === 'collapse') { c.kv += 16; swarmLog(c, 'burst'); }
    }
    else c.ex = Math.max(c.ex, dropS), c.shR = 0.3;
    c.spA = null;
    c.pi = (c.pi + 1) % c.pals.length; swarmWave(c, c.pals[c.pi], c.r(), 5.5);
    c.sw += (c.r() < 0.5 ? -1 : 1) * (1.4 + c.r()); c.elT = (c.r() - 0.5) * 0.7; c.bars = 0;
    c.cyT = 0.25 + 0.5 * c.r2(); c.cxT = (c.r2() - 0.5) * 0.7; c.seaP = c.seaM || 0; c.seaM = ((c.seaM || 0) + 1 + Math.floor(c.r2() * 3)) % 4; if (c.mu) swarmDancePick(c);
    { const u = c.r2(); if (u < 0.4) { c.crown = 4; c.skim = 0; } else if (u < 0.7) { c.skim = 4; c.crown = 0; } }   // v21: the drop also sets the camera's mode for the phrase: under the figure looking up, a low skim, or as it was   // v21: the drop re-aims the lens and re-patterns the sea (behind a front, in the shader)
    c.drops++; if (c.drops % 3 === 0) c.vis = 6;
  } else if (c.bars >= 8 && c.mt >= 1 && c.spA && c.bu > 0.15) {
    c.bars = 0;   // a set-piece holds its figure through the whole build
  } else if (c.bars >= 8 && c.mt >= 1) {
    // phrase: a new figure, often with a rarer event riding on it
    c.bars = 0; c.sw += (c.r() < 0.5 ? -1 : 1) * (0.7 + 0.5 * c.r());
    let ev = W.SWARM_EV || null, x = c.r(); W.SWARM_EV = null;
    if (!ev) ev = x < 0.09 ? 'vista' : x < 0.17 ? 'nova' : x < 0.25 ? 'dust' : x < 0.3 ? 'reform' : x < 0.37 ? 'fly' : x < 0.45 ? 'skim' : x < 0.53 ? 'crown' : x < 0.58 ? 'drift' : x < 0.74 ? 'reform' : 'morph';
    if (ev === 'nova') { c.ex = 1; c.shR = 0.3; c.kv += 14; c.pi = (c.pi + 1) % c.pals.length; swarmWave(c, c.pals[c.pi], c.r(), 4); }
    else if (ev === 'skim') { c.skim = 6; c.sw += (c.r() < 0.5 ? -1 : 1) * (0.7 + 0.5 * c.r()); c.zT = 0.92 + 0.16 * c.r(); }   // a low skim past the reef
    else if (ev === 'crown') { c.crown = 6; c.sw += (c.r() < 0.5 ? -1 : 1) * (0.5 + 0.4 * c.r()); c.zT = 0.95 + 0.18 * c.r(); }   // climb and look down on the colony
    else if (ev === 'drift') { c.zT = 1.02 + 0.2 * c.r(); }   // no morph: the music does the work while the camera drifts
    else if (ev === 'fly') { c.fly = 6; c.sw += (c.r() < 0.5 ? -1 : 1) * 1.1; }   // glide into the figure as it is (no morph: a close-up cloud strobes)
    else if (ev === 'dust') { c.dustE = 1; swarmMorph(c, 3.2, 0.1); }
    else if (ev === 'reform') swarmMorph(c, 2.4, 0.25, c.figA);   // v18: the same sculpture rearranges itself
    else { if (ev === 'vista') c.vis = 8; swarmMorph(c, 2.2, 0.45); }
    c.rollT = (c.r() - 0.5) * 0.44; c.lastEv = ev;
    c.cyT = 0.1 + 0.65 * c.r2(); c.cxT = (c.r2() - 0.5) * 0.9; if (c.mu) swarmDancePick(c);   // v21: where the figure hangs in the frame this phrase
  }
  else if ((F.onBar || F.onSceneBar) && c.bars === 4) {
    c.pi = (c.pi + 1) % c.pals.length; swarmWave(c, c.pals[c.pi], c.offT + 0.1, 2.4);
    c.sw += (c.r() < 0.5 ? -1 : 1) * (0.6 + 0.5 * c.r()); c.elT = (c.r() - 0.5) * 0.6; c.zT = 0.85 + 0.3 * c.r();
    // mid-phrase: the reef re-poses (a new dutch tilt and a fresh roll target) instead of the old no-op split
    if (!c.spA && c.mt >= 1 && c.r() < 0.3) { c.rollT = (c.r() - 0.5) * 0.5; c.sw += (c.r() < 0.5 ? -1 : 1) * 0.3; }
    if (!c.spA && c.mt >= 1 && c.r() < 0.3) swarmMorph(c, 2.2, 0.2, c.figA);   // v18: and sometimes changes formation mid-phrase
  }
  else if ((F.onBar || F.onSceneBar) && (c.bars === 2 || c.bars === 6)) { c.sw += (c.r() < 0.5 ? -1 : 1) * 0.35; c.zT = 0.85 + 0.3 * c.r(); }
  else if (F.onHit) swarmWave(c, c.palT, c.offT + 0.16, 6.5);
  if (c.wp < 1.7) { c.wp += dt * c.wv; if (c.wp >= 1.7) { c.palF = c.palT; c.offF = c.offT; c.wp = 9; } }
  if (c.mt < 1) { c.mt = Math.min(1, c.mt + dt / c.mDur); if (c.mt >= 1) { c.figA = c.figB; c.mdA = c.mdB; c.slA = c.slB; } }
  // the tree grows: whorl by whorl as it condenses (about 5 s), or with the build in the growth set-piece; it blossoms
  // to its full crown on the drop
  const treeOn = c.figA === 6 || (c.mt < 1 && c.figB === 6);
  if (!treeOn) c.grow = 0;
  else { c.bloom = (c.bloom || 0) * Math.exp(-dt * 0.8); const gT = c.spA === 'growth' ? 0.1 + 0.85 * c.bu : 1; c.grow = ease(c.grow || 0, Math.max(gT, c.bloom > 0.05 ? 1 : 0), dt, c.bloom > 0.05 ? 0.35 : 1.6); }
  const mm = c.mt < 1 ? c.mt * c.mt * (3 - 2 * c.mt) : 0;
  c.ex *= Math.exp(-dt * 1.25); c.shR = Math.min(2.6, c.shR + dt * (1.2 + 2.6 * c.ex));
  // kick: an underdamped spring, so the dots burst outward and bounce back
  if (F.onKick) { c.kv += (9 + 7 * F.kick) * (0.5 + 0.5 * dose); c.kr = 0; }
  c.kr = Math.min(9, c.kr + dt * 3.6);
  { const w = 2 * Math.PI * 2.2, z = 0.34, wd = w * Math.sqrt(1 - z * z), e = Math.exp(-z * w * dt), co = Math.cos(wd * dt), si = Math.sin(wd * dt), a = z * w / wd, x0 = c.kx, v0 = c.kv;
    c.kx = e * (x0 * (co + a * si) + v0 * si / wd); c.kv = e * (v0 * (co - a * si) - x0 * (w * w / wd) * si); }
  // per band (smoothed for geometry): sub+bass breathe the whole figure, low-mid+mid drive the flow and the ripples
  const lo = B ? Math.max(B[0], B[1]) : F.bass, mi = B ? 0.5 * (B[2] + B[3]) : F.mid;
  c.bass = ease(c.bass, lo, dt, 0.16); c.mid = ease(c.mid, mi, dt, 0.25);
  // v18: per-body band levels (attack 70 ms, release 260 ms): geometry stays on smoothed signals
  { const tr = (o, v) => ease(o, v, dt, v > o ? 0.07 : 0.26), hi = B ? Math.max(B[5], B[6], B[7]) : F.high;
    c.lv0 = tr(c.lv0 || 0, lo); c.lv1 = tr(c.lv1 || 0, mi); c.lv2 = tr(c.lv2 || 0, hi);
    // the carousel is pushed along by the bass
    // v20: the carousel turns in steps on the beat (bigger steps when the bass is loud), over a slow drift that bass and builds speed up
    // v22: this phase now drives the choreographies (bodies orbiting, weaving and chasing each other). It steps on every beat (the engine has no
    // F.onBeat: a beat is where its beat phase wraps), a larger step the louder the bass, over a slow drift that builds wind up
    { const onB = !F.silent && (F.beat || 0) < (c.bq || 0) - 0.3; c.bq = F.beat || 0; if (onB) c.carT = (c.carT || 0) + (Math.PI / 14) * (0.5 + 0.9 * c.bass * dose) * c.fdir; }
    c.carS = ease(c.carS || 0, c.carT || 0, dt, 0.11);
    c.carD = (c.carD == null ? c.car || 0 : c.carD) + dt * (0.05 + 0.16 * c.bass * dose + 0.9 * c.bu) * sp * c.fdir;
    c.car = c.carD + c.carS; }
  const fbuild = W.SWARM_BUILD != null ? W.SWARM_BUILD : F.build;
  c.tn = ease(c.tn || 0, F.silent ? 0 : (F.tension || 0), dt, (F.tension || 0) > (c.tn || 0) ? 0.6 : 0.2);   // v22: tension draws the swarm in tight (its bodies close in, it contracts) and an impact lets it go
  const bT = Math.max(c.bu, 0.8 * c.tn);
  c.bu = ease(c.bu, fbuild, dt, fbuild > c.bu ? 0.5 : 0.25);
  c.calm = ease(c.calm, F.breakdown || 0, dt, 1);
  // build set-pieces (once per build): the swarm becomes a vortex that tightens and spins up until the drop bursts it,
  // or a sapling that grows whorl by whorl with the build and blossoms on the drop
  if (c.bu > 0.1 && !c.spDone && c.mt >= 1 && !drop) {
    c.spDone = 1; const x = W.SWARM_SP === 'growth' ? 0.6 : W.SWARM_SP === 'collapse' ? 0 : c.r();   // SWARM_SP: review hook
    if (x < 0.42) { c.spA = 'collapse'; swarmMorph(c, 2.6, 0.25, 10, 0); swarmLog(c, 'collapse'); }
    else if (x < 0.8) { c.spA = 'growth'; swarmMorph(c, 2.6, 0.2, 6, 0); c.grow = 0.08; swarmLog(c, 'growth'); }
  }
  if (c.bu < 0.05) { c.spDone = 0; if (c.spA && !drop) c.spA = null; }
  c.ringS = ease(c.ringS, c.ring, dt, 1.2);
  // dust: the figure loosens into a drifting cloud in breakdowns and on 'dust' phrases (and reassembles)
  c.dustE *= Math.exp(-dt / 1.6);
  c.dust = ease(c.dust, Math.max(0.45 * c.calm, Math.min(1, 1.4 * c.dustE)) * (1 - c.bu), dt, 0.5);
  c.rip = ease(c.rip, (0.006 + 0.05 * c.mid * dose + 0.012 * c.bu) * (1 - 0.6 * c.calm), dt, 0.2);
  // vista: the camera pulls far back (breakdowns, rare phrases, every third drop) to show the universe of swarms
  c.visS = ease(c.visS, Math.max(c.vis > 0 ? 1 : 0, 0.15 * c.calm), dt, 1.6);   // v20: a breakdown pulls back less far (it went dark)
  // mids drive the flow of dots through the figure; builds spin them up
  const da = dt * (0.14 + 0.85 * c.mid * dose) * (1 + 2.5 * c.bu) * (1 - 0.5 * c.calm) * sp * c.fdir;
  c.al = (c.al + da) % (2 * Math.PI);
  // helix screw offset: kept small (float precision of the lattice walk), reset whenever the helix is not on screen
  if (c.figA === 5 || (c.mt < 1 && c.figB === 5)) { c.h += da * 1.7 / (2 * Math.PI); if (Math.abs(c.h) > 24) c.h -= Math.sign(c.h) * 24; } else c.h = 0;
  const fA = c.figA, fB = c.mt < 1 ? c.figB : c.figA, dA = c.mdA, dB = c.mt < 1 ? c.mdB : c.mdA;
  { const SP = [0, 0, 0, 0, .2, .1, 0, .6, .3, .4, .1, .3, .2, 0, .6, .2], spr = Math.max(SP[fA] || 0, SP[fB] || 0) + (dA ? .15 : 0);
    c.lift = ease(c.lift || 0, Math.min(1, Math.max(c.mt < 1 ? 1 : 0, 1.5 * c.dust, spr)), dt, (c.mt < 1 ? 0.25 : 0.9) * 1); }
  const sA = 1 + 0.55 * mm * mm, sB = 0.55 + 0.45 * mm;
  const size = SWARM_SIZE[fA] * (1 - mm) + SWARM_SIZE[fB] * mm;
  const swell = c.mt < 1 ? Math.sin(Math.PI * c.mt) * (c.mDur < 2.5 ? 0.22 : 0.1) : 0;
  const wF = (f) => (fA === f ? 1 - mm : 0) + (fB === f ? mm : 0);
  // the heart beats harder on the kick; the vortex collapses inward through a build; the growing tree is not squeezed
  const scl = size * (1 + 1.6 * (c.pm ? c.pm.x : 0)) * (1 + (0.16 + 0.12 * wF(13)) * c.kx + 0.18 * c.bass * dose + swell) * (1 - 0.36 * bT * (1 - 0.8 * wF(6)) - (c.spA === 'collapse' ? 0.26 * c.bu * wF(10) : 0));
  let Rb = Math.max(swarmRad(SWARM_RB, fA, dA) * (c.mt < 1 ? sA : 1), c.mt < 1 ? swarmRad(SWARM_RB, fB, dB) * sB : 0);
  const ripX = c.rip + 0.02 * (c.rp || 0);
  Rb = Rb * (1 + 0.04 * c.dust + 0.08 * ripX / 0.03) + 0.06;
  if (c.ex > 0.01) Rb = Math.max(Rb, c.shR + 0.08);
  Rb += 0.13 * (c.lv2 || 0) * dose;   // v20: room for the treble corona
  // object: slow tumble, leaning each family toward the camera
  c.oy += dt * (0.06 + 0.35 * c.bu * (1 + (c.spA === 'collapse' ? 2.2 : 0)) + 0.3 * c.ex) * sp;
  const tilt = SWARM_TILT[fA] * (1 - mm) + SWARM_TILT[fB] * mm;
  const hx = SWARM_UPR[fA] * (1 - mm) + SWARM_UPR[fB] * mm;   // upright figures keep their axis in the screen plane
  const pitch = (c.op + 0.22 * Math.sin(V.mt * 0.05)) * (1 - 0.95 * hx), roll = 0.16 * Math.sin(V.mt * 0.037 + 1) * (1 - 0.7 * hx);
  // camera: beat-locked orbit (speed smoothed so it never lurches), swoops on drops, pulls back in vistas
  const ms = clamp(Number(S.motionSmooth ?? 0.75) || 0, 0, 1), km = 0.55 + 0.6 * ms;   // motion smoothness scales the camera springs
  c.azV = ease(c.azV, dt > 0 ? dtr / dt : 0, dt, 0.6 * km);
  c.az += dt * (0.025 + 0.1 * c.azV) * sp * (1 - 0.5 * c.calm) * (1 + 0.35 * (c.skimS || 0));
  c.swS = ease(c.swS, c.sw, dt, 0.5 * km * (1 + 0.6 * (c.flyS || 0))); c.elS = ease(c.elS, c.elT, dt, 0.8 * km);
  const az = c.az + c.swS + PTR.x * 0.3 * PTR.inf;
  // zoomed out, the camera also rises so the band of swarms recedes across the whole frame below and behind the figure
  const zm = clamp(((typeof PTR !== 'undefined' && PTR.zoom) || 1) * (V.kz ?? 1), 0.1, 4), zo = clamp((1 - zm) / 0.85, 0, 1);
  c.zoS = zo * zo * (3 - 2 * zo);   // v13: no realm-side lag (the engine already smooths the wheel)
  // v21: the camera stays low. It lives between the sea of pearls (1.7 below the figure's centre) and the figure's waist and looks up at the
  // figure, so the figure looms; wide views (the wheel, vistas, breakdowns) sink closer to the sea instead of climbing above
  // everything. "crown" is now a pass underneath, looking almost straight up. Folded, it sits level so the fold centre is the figure.
  const fold = typeof effectiveSym === 'function' ? (effectiveSym(V) > 1 ? 1 : 0) : (V.kz ?? 1) < 0.99 ? 1 : 0;
  c.foldS = ease(c.foldS ?? fold, fold, dt, 1.2 * km);
  // v22: lower still, and nothing under it any more (the sea is gone): the lens rests about 27 degrees below the figure looking up at it, between
  // almost level (a skim) and nearly underneath (the "crown" pass); the wide lens, close in, makes whatever is nearest loom
  const elRaw = -0.47 + (0.3 * c.el0 + 0.4 * c.elS + 0.14 * Math.sin(c.az * 0.41 + 1) + 0.05 * Math.sin(V.mt * 0.13)) * (1 - 0.6 * hx)
    - 0.08 * c.visS - 0.06 * c.zoS + 0.2 * (c.skimS || 0) - 0.25 * (c.crownS || 0) + PTR.y * 0.2 * PTR.inf;
  let el = clamp(lerp(elRaw, 0.1 * elRaw + 0.02, c.foldS), -0.92, 0.06);
  // framing from the figure radius (zoom target varies per phrase), eased so it never jerks
  const fr = Math.max(swarmFrR(fA, dA) * (1 - mm) + swarmFrR(fB, dB) * mm, 1.2) * size;
  c.zS = ease(c.zS, c.zT, dt, 1.2 * km);
  // fly-through: for a phrase the camera glides in until the sculpture's dots stream past the lens, then back out
  c.flyS = ease(c.flyS || 0, c.fly > 0 ? 1 : 0, dt, 2.2 * km);
  c.skimS = ease(c.skimS || 0, c.skim > 0 ? 1 : 0, dt, 2.0 * km); c.crownS = ease(c.crownS || 0, c.crown > 0 ? 1 : 0, dt, 2.0 * km);
  c.rollS = ease(c.rollS || 0, c.rollT || 0, dt, 1.6 * km);
  c.soloS = ease(c.soloS == null ? (dA === 0 ? 1 : 0) : c.soloS, dB === 0 && dA === 0 ? 1 : 0, dt, 0.9 * km); const fdT = (0.85 - 0.15 * c.soloS) * fr * SWARM_FL / 0.45 * 1.1 * c.zS * (1 + 0.4 * c.visS) * (1 - 0.48 * c.flyS * (1 - c.visS) * (1 - 0.55 * c.soloS)) * lerp(0.82, 0.86, c.foldS);   // v21: the framing radius now fills more than the frame height (it filled ~80%)
  c.fd = c.fd == null ? fdT : ease(c.fd, fdT, dt, 0.8 * km);
  const dist = c.fd * (1 + 0.05 * Math.sin(V.mt * 0.09));   // no lean-in on builds: the figure visibly contracts
  const pos = [dist * Math.cos(el) * Math.sin(az), dist * Math.sin(el), dist * Math.cos(el) * Math.cos(az)];
  // v21 composition: the lens aims below the figure's centre (more the lower it is), so the figure hangs in the upper frame and runs
  // out of it, with the sea and its horizon underneath; the aim moves to a new place every phrase. Folded, it aims at the centre.
  c.cyS = ease(c.cyS ?? 0.3, c.cyT ?? 0.3, dt, 1.4 * km); c.cxS = ease(c.cxS ?? 0, c.cxT ?? 0, dt, 1.6 * km);
  const cmp = (1 - c.foldS) * (1 - 0.6 * c.flyS), low = clamp(-el / 0.5, 0, 1);
  const tg = [0.12 * Math.sin(V.mt * 0.07) + cmp * c.cxS * fr * Math.cos(az), 0.08 * Math.sin(V.mt * 0.05 + 2) + cmp * fr * (0.06 - c.cyS * (0.2 + 0.14 * low)), -cmp * c.cxS * fr * Math.sin(az)];
  const fw = v3.norm(v3.add(tg, v3.sc(pos, -1)));
  let rt = v3.norm(v3.cross(fw, [0, 1, 0])), up = v3.cross(rt, fw);
  const rl = 0.07 * Math.sin(V.mt * 0.061) + (c.rollS || 0), cr = Math.cos(rl), sr = Math.sin(rl);   // v14: a different dutch tilt every phrase
  [rt, up] = [v3.add(v3.sc(rt, cr), v3.sc(up, sr)), v3.add(v3.sc(up, cr), v3.sc(rt, -sr))];
  // uM1 = camera right, up (the shader rebuilds forward) and (mid ripple, dust, dance phase: one swing per two beats)
  // z packs the dance phase (fract) with the smoothed vocal range (the face's lips), 64 steps in the even integers
  const voT = B ? Math.max(B[3], 0.8 * B[4], 0.6 * B[5]) : F.mid;
  c.voc = ease(c.voc || 0, voT, dt, voT > (c.voc || 0) ? 0.08 : 0.25);
  V.m1 = new Float32Array([...rt, ...up, ripX, c.dust, ((V.trav * 0.5) % 1 + 1) % 1 + 2 * Math.round(clamp(c.voc * dose, 0, 1) * 63)]);
  // spin about the figure's own axis first, then lean that axis toward the camera (so a galaxy is seen face-on)
  const lean = SWARM_ROLL[fA] * (1 - mm) + SWARM_ROLL[fB] * mm;
  // the dancer turns to face the camera (swaying a little either side)
  const dW = SWARM_FACE[fA] * (1 - mm) + SWARM_FACE[fB] * mm, yT = (W.SWARM_YS || 1) * az + (W.SWARM_YO || 0) + 0.5 * (1 - 0.8 * wF(7) - 0.5 * wF(13)) * Math.sin(V.trav * 0.39);
  const yaw = c.oy + dW * ((((yT - c.oy) % 6.283) + 9.425) % 6.283 - 3.1416);
  // v21: the dance (see swarmDancePick). Everything is a punch into a critically damped spring: on the beat, then loose.
  if (!c.mu) { c.mu = [1, 1, 1, 1]; c.dn = []; c.nd = { x: 0, v: 0 }; c.spn = { x: 0, v: 0 }; c.ln = { x: 0, v: 0 }; c.shv = { x: 0, v: 0 }; c.pm = { x: 0, v: 0 }; c.rp = 0; c.spT = 0; c.spD = c.fdir; c.lnT = 0; c.shT = 0; c.hp = 0; swarmDancePick(c); }
  { const live = !F.silent, dk = Math.exp(-dt / 10), hatOn = (F.hat || 0) - c.hp > 0.15, on = (k) => live && c.dn.includes(k), kw = 1 / km, m = c.mu; c.hp = F.hat || 0;
    m[0] = m[0] * dk + (F.onKick && live ? 0.05 : 0); m[1] = m[1] * dk + (F.onHit && live ? 0.1 : 0); m[2] += ((F.bass || 0) * 1.6 - m[2]) * (1 - dk); m[3] = m[3] * dk + (hatOn && live ? 0.02 : 0);
    if (F.onKick && on(0)) c.nd.v += 3.3 * (0.6 + 0.4 * F.kick) * kw;
    if (F.onHit && on(1)) { if ((F.onBar || F.onSceneBar) && c.r2() < 0.35) c.spD = -c.spD; c.spT += c.spD * 0.32; } else if (F.onHit && live) c.spT += c.spD * 0.2;
    const onBt = (F.beat || 0) < (c.bp || 0) - 0.3; c.bp = F.beat || 0;   // (the engine has no F.onBeat: a beat is where its beat phase wraps)
    if (onBt) c.lnT = on(2) ? (c.lnT > 0 ? -0.09 : 0.09) : 0;
    if (hatOn && on(3)) c.shT += 0.1 * c.fdir;
    if (F.onHit && on(4)) c.pm.v += 1.5 * kw;
    if (F.onKick && on(5)) c.rp = 0.6 + 0.4 * F.kick;
    c.rp *= Math.exp(-dt / 0.16);
    swarmSpr(c.nd, 0, 11 * kw, dt); swarmSpr(c.spn, c.spT, 10 * kw, dt); swarmSpr(c.ln, c.lnT, 9 * kw, dt); swarmSpr(c.shv, c.shT, 20 * kw, dt); swarmSpr(c.pm, 0, 12 * kw, dt);
    if (Math.abs(c.shT) > 50) { c.shT -= Math.sign(c.shT) * 6.2832 * 7; c.shv.x -= Math.sign(c.shv.x) * 6.2832 * 7; } }
  const R = swarmMul(swarmMul(swarmAxis(fw, lean + c.ln.x), swarmAxis(rt, tilt + 0.9 * c.nd.x)), swarmMul(rotMat3(pitch, 0, roll), rotMat3(0, yaw + c.spn.x, 0)));
  V.m2 = swarmT(R); V.m2[6] = c.lv0 * dose; V.m2[7] = c.lv1 * dose; V.m2[8] = c.lv2 * dose;   // z column: per-body bands (the shader rebuilds it from a cross product)
  const enc = (f, md, sl) => (sl || 0) * 128 + md * 16 + f + c.prm[f] * 0.98;   // v20: string-art mode in the 128s
  V.p1 = [enc(fA, dA, c.slA), enc(fB, dB, c.mt < 1 ? c.slB : c.slA), mm, scl];
  // y: the helix screw offset, or (100 + growth) while the tree is on screen
  V.p2 = [c.al + (c.shv ? c.shv.x : 0), c.h !== 0 || !treeOn ? c.h : 100 + clamp(c.grow, 0, 1), Math.floor(c.visS * 48) + Math.min(c.lift, 1) * 0.99, c.kr];   // z: vista amount (48ths) + rings amount
  // v21: a spray of pearls stands up off the sea in rows for a second or two, once or twice a visit, on a bar line, low in a corner
  // of the frame of that moment (it then stays where it is on the sea while the camera drifts on)
  c.cnT = (c.cnT ?? -1) < 0 ? -1 : c.cnT + dt;
  if ((F.onBar || F.onSceneBar) && c.bars % 2 === 1 && c.cnT < 0 && (c.cnN || 0) < 2 && !F.silent && (W.SWARM_CST || ((c.cnB = (c.cnB || 0) + 1) > 5 + 9 * (c.cnN || 0) && c.r2() < 0.3))) {
    W.SWARM_CST = null; c.cnN = (c.cnN || 0) + 1; c.cnT = 0;
    // on the sea, where a ray through the lower part of the frame will meet it once the camera has got where it is heading (bar
    // lines are also where it starts its swings); if that ray misses the sea, nothing appears this time
    const zf = Math.pow(Math.max(zm, 1), -0.7) * Math.pow(Math.min(zm, 1), -0.2), zw = Math.pow(Math.min(zm, 1), -0.17) * Math.pow(Math.max(zm, 1), -0.4);
    const azT = c.az + c.sw + 1.1 * (0.025 + 0.1 * c.azV) * sp * (1 - 0.5 * c.calm), pT = [dist * zf * Math.cos(el) * Math.sin(azT), dist * zf * Math.sin(el), dist * zf * Math.cos(el) * Math.cos(azT)];
    const fT = v3.norm(v3.add(tg, v3.sc(pT, -1 / zf))), rT = v3.norm(v3.cross(fT, [0, 1, 0])), uT = v3.cross(rT, fT);
    let ok = false;   // a ray through a lower corner of the frame, out to a sphere of radius 40 round the figure (the lens is always inside it)
    for (let i = 0; i < 3 && !ok; i++) {
      const sx = (c.r2() < 0.5 ? -1 : 1) * (0.3 + 0.25 * c.r2()) * zw, sy = -(0.2 + 0.14 * c.r2()) * zw, d = v3.add(v3.add(v3.sc(rT, sx), v3.sc(uT, sy)), v3.sc(fT, SWARM_FL));
      const dn = v3.norm(d), bq = v3.dot(pT, dn), tq = -bq + Math.sqrt(Math.max(bq * bq - v3.dot(pT, pT) + 1600, 0)), X = v3.add(pT, v3.sc(dn, tq));
      const ei = Math.round(Math.asin(clamp(X[1] / 40, -1, 1)) / 0.0654) + 16;
      if (tq > 0 && ei >= 0 && ei <= 23) { ok = true; c.cnA = (Math.round(((Math.atan2(X[2], X[0]) / 6.2832 % 1) + 1) % 1 * 128) % 128) + 128 * ei; }
    }
    if (!ok) { c.cnT = -1; c.cnN--; }
  }
  if (c.cnT > 2.1) c.cnT = -1;
  const cnAl = c.cnT < 0 ? 0 : Math.round(15 * clamp(Math.min(c.cnT / 0.3, (2.1 - c.cnT) / 0.5), 0, 1));
  V.p3 = [c.ex, c.shR, Math.min(bT, 0.999) + (c.seaM || 0) + 4 * (c.seaP || 0) + 16 * cnAl, Rb];
  V.p4 = [c.wp, c.palF + c.offF * 0.98, c.palT + c.offT * 0.98, (((c.wd % 6.2832) + 6.2832) % 6.2832) + 8 * (c.cnA || 0)];
  const gain = (1 + 0.6 * c.visS + 0.5 * c.zoS + 0.5 * c.bass * dose) * (1 - 0.3 * c.bu);
  V.p5 = [pos[0], pos[1], pos[2], Math.floor(gain * 256) + (((c.car / 6.283185) % 1 + 1) % 1) * 0.999];   // w: universe gain (256ths) + carousel phase
}
