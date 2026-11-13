/* ============================== pointer =============================== */
const PTR = { inf: 0, x: 0, y: 0, tx: 0, ty: 0, px: 0, py: 0, vx: 0, vy: 0, press: 0, down: false, downT: 0, active: 0, lastMove: -99, zoom: 0.8, zoomT: 0.8, lx: 0, ly: 0, pts: new Map(), pinch0: 0, zoom0: 1 };
const WAVES = [];
const HOLE = [0, 0, 0, 0]; // pointer singularity: x, y, horizon radius, strength
const WAVE_BUF = new Float32Array(24);
function addWave(x, y, amp, speed) { WAVES.push({ x, y, t: 0, amp, speed: speed || 0.9 }); if (WAVES.length > 6) WAVES.shift(); }

/* ============================== director ============================== */
// v11: RTIME is the realms' uTime: it runs at the Speed dial (identical to TIME at 1x), so realms that animate on
// uTime speed up and slow down with Speed like the ones that animate on uMT / travel
let TIME = 0, MT = 0, RTIME = 0;
const DBG = { raw: false, kicks: 0, log: [] };
function dlog(type, extra) { DBG.log.push(Object.assign({ t: +TIME.toFixed(2), type }, extra || {})); if (DBG.log.length > 400) DBG.log.shift(); }
const D = { spin: 0, spinT: 0, mutN: 0, tc: [0, 0], peek: null, cur: null, nxt: null, mix: 0, dur: 2, style: 0, barsIn: 0, timeIn: 0, realmBars: 0, realmTime: 0, lastMut: 0, phraseBase: 0, symRot: 0, symRotT: 0, hue: Math.random(), palFrom: 0, palTo: 0, palT: 1, palDur: 4, barCount: 0, history: [], bag: [], cycle: 0 };
let journeyRand=mulberry(Math.floor(Math.random()*4294967296));
function makeVisit(ri) {
  const R = REALMS[ri];
  const seed = [rand(), rand(), rand(), rand()];
  const V = { ri, R, seed, c: R.init(seed), mt: rand() * 60, trav: rand() * 8, rate: 1, sym: pick(R.syms), p1: [0, 0, 0, 0], p2: [0, 0, 0, 0], p3: [0, 0, 0, 0], p4: [0, 0, 0, 0], p5: [0, 0, 0, 0], m1: rotMat3(0, 0, 0), m2: rotMat3(0, 0, 0) };
  V.kal = autoKalPlan(V); // Auto Show's kaleidoscope plan for this visit (its own seeded generator: rand() draws unchanged)
  return V;
}
// Previewing reserves a visit without consuming it. Only a visible family change consumes the bag.
function refillRealmBag(except) {
  D.bag = scnBag(REALMS.map((_,i)=>i)); // ENGINE v24: only the scenes that are on (the same array when all are)
  for(let i=D.bag.length-1;i>0;i--){const j=Math.floor(journeyRand()*(i+1));[D.bag[i],D.bag[j]]=[D.bag[j],D.bag[i]];}
  // MOBILE: lighter realms (by their cost field) come up first in each cycle (the bag is read from its end); all still play
  if(MOBILE){const w=new Map(D.bag.map(i=>[i,(REALMS[i].cost||2)*(.7+.6*journeyRand())]));D.bag.sort((a,b)=>w.get(b)-w.get(a));}
  favouriteFilterBag(); // the person's "Favourites only" choice (works with and without Auto Show)
  if (S.autoShow) autoOrderBag(); // Auto Show: a curated running order instead of a plain shuffle (also for next/swipe)
  if(D.bag.length>1 && D.bag[D.bag.length-1]===except) [D.bag[0],D.bag[D.bag.length-1]]=[D.bag[D.bag.length-1],D.bag[0]];
  if (scnSeq()) D.bag = scnSeqList(except).reverse(); // ENGINE v24: sequence mode: the bag is what follows, in list order
  D.cycle++;
}
function consumeRealm(ri) {
  const at=D.bag.indexOf(ri); if(at>=0) D.bag.splice(at,1);
  D.history.push(ri); if(D.history.length>REALMS.length*2) D.history.shift();
}
function resetRealmBag(ri) { D.bag=[];D.cycle=0;D.history=[];refillRealmBag(ri);consumeRealm(ri); }
// Only prepared realms are picked (realms still preparing in the background keep their place in the bag);
// -1 means no other realm is ready yet.
function pickRealm(except) {
  if (scnChanged()) { if (scnSeq()) return scnSeqPick(except); const p = scnPlayable(); if (p.length === 1 && p[0] === except) return -1; } // ENGINE v24
  if(!D.bag.length) refillRealmBag(except);
  for(let i=D.bag.length-1;i>=0;i--) if(D.bag[i]!==except && realmReady(D.bag[i])) return D.bag[i];
  if(D.bag.some(i=>i!==except && !REALMS[i].failed)) return -1; // the rest of this cycle is still preparing
  // A manual jump can leave only the current family in the bag. It already counts as visited.
  consumeRealm(except);refillRealmBag(except);
  for(let i=D.bag.length-1;i>=0;i--) if(D.bag[i]!==except && realmReady(D.bag[i])) return D.bag[i];
  return -1;
}
// Auto Show (when it owns the realm length) spreads the same journey total unevenly: show-stoppers stay longer and
// lighter realms shorter (autoHoldWeight). The weights sum to the realm count, so the no-repeat promise still holds.
function realmHoldSeconds(V) {
  const own = scnHold(V || D.cur); if (own) return own; // ENGINE v24: this scene's own length (sequence mode, a link's secs)
  if(S.sceneDuration==='bars')return Number(S.switchBars)*4*60/Math.max(40,F.bpm||120);
  return Number(S.sceneDuration)>0?Number(S.sceneDuration):Infinity;
}
function realmChangeDue() {
  if (scnStay()) return false; // ENGINE v24: a set of one scene stays
  const own = scnHold(D.cur); if (own) return D.realmTime+1e-6>=own;
  if(S.sceneDuration==='bars')return D.realmBars>=Number(S.switchBars);
  return D.realmTime+1e-6>=realmHoldSeconds();
}
// CORE_SMOOTH1: no realm shader, route, audio clock or protected camera changes.
const VIEW_MOTION={zoom:null,rotation:null,curl:null};
function viewMotionProtected(V){const R=V&&(V.R||V);return !!R&&R.key==='gate';}
function viewMotionAmount(A,B,peek){
  if(!A||viewMotionProtected(A)||viewMotionProtected(B)||viewMotionProtected(peek))return 0;
  return clamp(Number(S.motionSmooth)||0,0,1);
}
function viewMotionReset(){VIEW_MOTION.zoom=VIEW_MOTION.rotation=VIEW_MOTION.curl=null;}
function viewMotionIntegral(target,dt,amount,channel='zoom'){
  let z=VIEW_MOTION[channel];
  if(!z)z=VIEW_MOTION[channel]={x:target,v:0};
  const w=4/(.05+.95*calmStretch(amount)),d=z.x-target,q=z.v+w*d,e=Math.exp(-w*dt);
  const one=-Math.expm1(-w*dt),A=one/w,B=(one-w*dt*e)/(w*w);
  const integral=target*dt+d*A+q*B;
  z.x=target+(d+q*dt)*e;z.v=(z.v-w*q*dt)*e;
  return integral;
}
// Preserve the old style RNG draw/count. Numeric goRealm styles remain explicit.
function viewVisitStyle(kind){const value=pickStyle(kind);return E.transition==='auto'?{viewAuto:value}:value;}


// Preserve smooth journeys through automatic mutations and queued/drop-accelerated fades.
const TRANSITION_MOTION={visit:null,x:0,v:0};
function transitionAdvance(dt){
  const calm=viewMotionAmount(D.cur,D.nxt,D.peek),base=1/D.dur;
  if(!(calm>0)){TRANSITION_MOTION.visit=null;return D.hurry?dt/.25:dt/D.dur*(!OFF.on&&dt>1/35?1.7:1);}
  const z=TRANSITION_MOTION;
  if(z.visit!==D.nxt){z.visit=D.nxt;z.x=base;z.v=0;}
  const target=D.hurry?4:base,w=4/(.05+.95*calmStretch(calm)),d=z.x-target,q=z.v+w*d,e=Math.exp(-w*dt);
  const one=-Math.expm1(-w*dt),A=one/w,B=(one-w*dt*e)/(w*w),integral=target*dt+d*A+q*B;
  z.x=target+(d+q*dt)*e;z.v=(z.v-w*q*dt)*e;
  return integral;
}
function motionDamping(V) { return V && V.R.key==='gate' ? 0 : S.motionSmooth; }
// Motion smoothness response. Up to the default (75%) the established behaviour is unchanged; above it the easing
// times stretch up to ~3.7x and kick/snare camera pulses fade almost out, so the top of the dial visibly glides.
// Below the default the live image's kick pulse also grows (up to 1.6x at 0), so the bottom of the dial visibly snaps.
const calmStretch = (a) => a <= 0.75 ? a : 0.75 + (a - 0.75) * 8;
const calmGain = (a) => a <= 0.75 ? 0.2 + 0.8 * (1 - a) * (1 - a) : lerp(0.25, 0.05, (a - 0.75) / 0.25);
const calmPulse = (a) => a <= 0.75 ? 1 + (0.75 - a) * 0.8 : lerp(1, 0.06, (a - 0.75) / 0.25); // v10: the top of the dial all but removes it (and render() low-passes what is left)
// Transition styles (index = uStyle in the compose shader). Auto picks by context: drops cut or explode,
// phrase changes morph, mutations leak and melt.
const TRANS = [['portal', 'Portal'], ['vortex', 'Vortex'], ['melt', 'Melt'], ['shatter', 'Shatter'], ['leak', 'Light leak'], ['kaleido', 'Kaleido fold'], ['mosh', 'Datamosh'], ['cut', 'Hard cut'], ['dissolve', 'Dissolve']];
// v21: what Auto picks from. Shatter (3) and Datamosh (6) are no longer picked automatically: a honeycomb of flipping tiles
// and a block glitch read as slideshow effects (both stay in the Transition menu for anyone who wants them). A reseed of
// the scene on screen (mutate) is always the soft dissolve: the old pool sent the same scene down a whirlpool or through a
// folded smear and back, which is the "collapses into a design and returns" the owner reported.
const TRANS_AUTO_OFF = [3, 6];
const TRANS_POOL = { drop: [7, 7, 0, 1, 5], phrase: [1, 2, 8, 4, 5, 0], mutate: [8], manual: [0, 1, 2, 8, 4, 5] };
function pickStyle(kind) {
  if (E.transition !== 'auto') { const i = TRANS.findIndex((t) => t[0] === E.transition); if (i >= 0) return i; }
  let pool = TRANS_POOL[kind] || TRANS_POOL.manual;
  // Auto Show: phrase and manual changes prefer the styles the incoming realm looks best arriving through
  if (autoActive('transition') && (kind === 'phrase' || kind === 'manual')) { const ap = D.upcoming ? autoProfile(D.upcoming.R) : null; if (ap && ap.tr.length) pool = ap.tr.concat(ap.tr, pool); }
  let st = pick(pool);
  if (st === D.lastStyle && pool.length > 1) st = pick(pool);
  return (D.lastStyle = st);
}
function beatsDur(beats, fallback) { return F.conf > 0.5 && F.bpm > 0 && !F.silent ? beats * 60 / F.bpm : fallback; }
function nextRealmIndex() { return D.upcoming ? D.upcoming.ri : pickRealm(D.cur ? D.cur.ri : 0); }
function goRealm(ri, dur, style, quiet, visit) {
  if (!(ri >= 0 && ri < REALMS.length)) return;
  // A realm still preparing in the background is queued: it jumps the preparation queue and opens once ready.
  if (!realmReady(ri)) {
    if (REALMS[ri].failed) { if (!quiet) toast(REALMS[ri].name + ' could not be prepared on this GPU.'); return; }
    RP.want = { ri, dur, style }; markRealmStates();
    if (!quiet) toast(REALMS[ri].name + ' is still loading · it opens as soon as it is ready');
    return;
  }
  // mid-crossfade: finish the current one quickly, then start this one (promoting it at once would pop)
  if (D.nxt) { D.queue = [ri, dur, style, quiet, visit]; D.hurry = true; markRealmChips(ri); return; }
  if (!visit) D.peek = null;
  const changing = !D.cur || D.cur.ri !== ri;
  if (!visit && changing && D.upcoming && D.upcoming.ri === ri) visit = D.upcoming;
  if (visit && visit === D.upcoming) D.upcoming = null;
  const byHand = style === undefined; // v21: no style given: a jump the person asked for
  if (style === undefined) style = viewVisitStyle('manual');
  const pickedAuto=style&&typeof style==='object'&&typeof style.viewAuto==='number';
  if(pickedAuto){
    const chosen=style.viewAuto, calm=viewMotionAmount(D.cur,visit||{R:REALMS[ri]},D.peek);
    style=calm>=.65?([0,1,2,8,4,5,8,8][chosen]??chosen):chosen; // v21: calm motion turns shatter, mosh and the hard cut into the dissolve; the rebuilt kaleido is smooth enough to stay
    if(calm>=.65)dur=Math.max(1.6,Number(dur)||0);
    const noA=D.cur&&SHOW[D.cur.R.key]&&SHOW[D.cur.R.key].no,noB=SHOW[REALMS[ri].key]&&SHOW[REALMS[ri].key].no;
    if((noA&&noA.includes(style))||(noB&&noB.includes(style)))style=8; // v21: see SHOW no
  }
  D.nxt = visit || makeVisit(ri); D.mix = 0.0001; D.style = style;
  if (!visit && D.cur && D.cur.ri === ri && D.cur.kal && D.nxt.kal) D.nxt.kal = D.cur.kal; // a reseed keeps the visit's fold plan
  D.dur = style === 7 ? 0.15 : style === 6 ? Math.max(0.8, dur * E.transTime) : style === 5 && !byHand ? Math.max(2.4, dur * E.transTime) : dur * E.transTime;
  // Family clocks and shuffle history change when the new visit becomes visible, below.
  if (!quiet) announceRealm(ri);
  markRealmChips(ri);
}
function setPalette(idx, dur) {
  // an interrupted fade restarts from whichever palette dominated
  D.palFromObj = (D.palT < 0.5 && D.palFromObj) ? D.palFromObj : PALETTES[D.palTo];
  D.palTo = idx; D.palT = 0; D.palDur = dur;
}
function palPair() {
  const to = PALETTES[D.palTo];
  if (D.palT >= 1 || !D.palFromObj) return { A: to, B: to, t: 0 };
  return { A: D.palFromObj, B: to, t: D.palT * D.palT * (3 - 2 * D.palT) };
}
function nextPalette(dur) { let i; do { i = Math.floor(rand() * PALETTES.length); } while (i === D.palTo && PALETTES.length > 1); setPalette(i, dur); }
// v21: Automatic is always the fold director's plan for the visit (with the Auto Show on or off); a number holds that fold
function effectiveSym(V) { if (E.symmetry === 'auto') return V.kal && V.kal.fold !== undefined ? V.kal.seq[V.kal.i] : V.sym; return Number(E.symmetry) || 0; }
function triggerDrop(manual, stay) {
  if(manual){FA.drop = 1; FA.kick = 1;}
  addWave(0, 0, 0.75, 2.3); // a softer shock ring: the full-strength one washed whole frames out half a second after every drop
  D.hue += 0.18 + rand() * 0.3;
  if (E.palette === 'auto') nextPalette(manual ? 0.6 : 0.9);
  if (D.nxt && D.nxt.ri !== D.cur.ri) D.hurry = true; // already on the way to a new realm: land it on the drop
  else if ((manual && !stay) || (!stay && E.autopilot && realmChangeDue())) {
    if (D.nxt) { D.nxt = null; D.queue = null; D.hurry = false; } // a reseed was fading in: the drop overrides it
    D.tc = [0, 0]; goRealm(nextRealmIndex(), beatsDur(1.5, 0.6), viewVisitStyle('drop'));
  }
  else if (D.cur) { D.cur.sym = pick(D.cur.R.syms); autoKalAdvance(D.nxt || D.cur, 'drop'); } // (D.nxt here: a reseed of this realm fading in)
}
// Mutations alternate: a smooth morph of the continuous parameters toward a new variation (no crossfade),
// then a full crossfade into a fresh seed (new symmetry, counts and layout).
function morphVisit(V) {
  if (!V || !V.R.cont || !V.R.cont.length) return false;
  const n = V.R.init([rand(), rand(), rand(), rand()]);
  V.tgt = {}; V.R.cont.forEach((k) => { if (n[k] !== undefined) V.tgt[k] = n[k]; });
  return true;
}
function mutate() {
  if (!D.cur) return;
  D.lastMut = D.realmTime;
  // New worlds already develop seeded rooms along their route; preserve that continuous journey.
  if((D.cur.R.continuousJourney===true&&!['gate','lattice'].includes(D.cur.R.key)) && motionDamping(D.cur)>0){ if(E.palette==='auto')nextPalette(6);return; }
  // realms that change formation/palette on their own phrases only get a fresh seed every 32 bars
  if (REALM_EVOLVES.has(D.cur.R.key)) return;
  if (FOLD.t < 1 || (D.cur.kal && D.cur.kal.fold !== undefined && D.cur.kal.t < 6)) return; // v21: never on top of a fold change (next chance in 8 bars)
  if (D.mutN++ % 2 === 0 && morphVisit(D.cur)) return;
  goRealm(D.cur.ri, beatsDur(8, 3.6), viewVisitStyle('mutate'), true);
}
function easeVisit(V, dt) {
  if (!V.tgt) return;
  const k = 1 - Math.exp(-dt / 2.5);
  for (const key in V.tgt) {
    const t = V.tgt[key], c = V.c[key];
    if (Array.isArray(t)) V.c[key] = c.map((x, i) => x + (t[i] - x) * k);
    else if (typeof t === 'number') V.c[key] = c + (t - c) * k;
  }
}
function directorUpdate(dt) {
  D.hue += dt * E.colorSpeed * 0.035 * (0.6 + F.level) + (F.onHit ? 0.004 * E.colorSpeed : 0);
  if (D.palT < 1) D.palT = Math.min(1, D.palT + dt / D.palDur);
  if (D.nxt) {
    D.mix += transitionAdvance(dt); // offline frame rate is a chosen clock, not evidence of GPU struggle
    if (D.mix >= 1) {
      const changed=!D.cur || D.cur.ri!==D.nxt.ri;
      D.cur = D.nxt; D.nxt = null; D.mix = 0; D.barsIn = 0; D.timeIn = 0; D.hurry = false;
      if(changed){consumeRealm(D.cur.ri);D.realmBars=0;D.realmTime=0;D.lastMut=0;}
      if (D.queue) { const q = D.queue; D.queue = null; goRealm(q[0], q[1], q[2], q[3], q[4]); }
    }
  }
  D.timeIn += dt; D.realmTime += dt;
  if (F.onKick) DBG.kicks++;
  if (F.onDrop) { dlog('drop', { bpm: +F.bpm.toFixed(1), pos: AU.demo ? +(AU.demo.position - AU.latency()).toFixed(3) : undefined, beat: +F.beat.toFixed(2) }); D.phraseBase = F.barIndex; triggerDrop(false); }
  if (F.onBar) {
    D.barsIn++; D.realmBars++; D.barCount++;
    // each bar the kaleidoscope clicks round by half a segment and the colour takes a small step
    D.symRotT += Math.PI / Math.max(2, effectiveSym(D.cur) || 4)*(1-0.94*motionDamping(D.cur));
    D.hue += 0.02 * E.colorSpeed;
    // Color flow also sets the auto palette cadence: every 8 bars at the default 0.6x, every bar at 4.8x and up
    const palBars = E.colorSpeed > 0 ? clamp(Math.round(8 * 0.6 / E.colorSpeed), 1, 64) : 0;
    if (E.palette === 'auto' && palBars && D.barCount % palBars === 0) nextPalette(Math.min(4.5, 0.56 * palBars));
  }
  // Smooth travel independently of the lights; keep MUMM3/LED06's established motion unchanged.
  const calm=motionDamping(D.cur), snap=1-0.94*calm;
  if (F.onHit && F.hit > 0.6) { D.spinT += (rand() < 0.5 ? -1 : 1) * 0.07 * S.dose * (0.4 + 0.6 * E.flashes)*snap; D.symRotT += Math.PI / Math.max(2, effectiveSym(D.cur) || 4) * 0.5*snap; }
  D.spinT *= Math.exp(-dt / 6);
  D.spin = ease(D.spin, D.spinT, dt, 0.07+0.55*calmStretch(calm));
  D.symRot = ease(D.symRot, D.symRotT, dt, 0.18+0.8*calmStretch(calm)) + dt * 0.03;
  D.symRotT += dt * 0.03;
  if(E.autopilot&&!D.nxt){
    if(realmChangeDue())goRealm(nextRealmIndex(),beatsDur(4,1.8),viewVisitStyle('phrase'));
    else if(F.onBar&&D.barsIn>=8&&D.realmBars%8===0)mutate();
  }
  if (E.palette !== 'auto' && D.palTo !== Number(E.palette)) setPalette(Number(E.palette), 1.5);
  if (!D.upcoming && !D.nxt && D.cur && REALMS.length > 1) { const ri = pickRealm(D.cur.ri); if (ri >= 0) D.upcoming = makeVisit(ri); }
  if (D.upcoming && D.cur && D.upcoming.ri === D.cur.ri) D.upcoming = null;
}

