// TEMPLATE helpers. This code shares one scope with the engine and every other scene, so EVERY top-level name
// starts with the scene key ("template..."). Use the engine's rand() / pick() for randomness, never Math.random():
// the engine swaps rand for a seeded generator in offline renders and tests, which makes a scene reproducible.
const templateCounts = [5, 6, 7, 8, 9, 10, 12];

// init(seed): called at the start of every visit with four random numbers 0..1. Return the visit's state.
// All state lives in this object (it becomes V.c). Never keep state in top-level variables: frame() runs for
// several visits of the same scene at once (the one on screen, the next one during a crossfade, a warm-up draw).
function templateInit(s) {
  return {
    n: templateCounts[Math.floor(s[0] * templateCounts.length) % templateCounts.length], // petals per ring now
    nNext: 0,        // petal count the flower is changing to
    swap: 1,         // 0..1 progress of a change of petal count (1 = at rest)
    twist: s[1],     // rotation of the rings, in petal cells
    hue: s[2],       // palette offset of this visit
    open: 0.6,       // how open the petals are (eased)
    kickAge: 9       // seconds since the last kick
  };
}

// frame(V, F, dt): called every frame for every live visit. V.c is the state from init, F the audio features
// (see docs/SCENE-CONTRACT.md), dt the seconds since the last frame (0 during the warm-up draw: nothing here may
// divide by dt). Its job: turn the music into a few smooth numbers and put them in V.p1 .. V.p5 (four numbers each;
// they arrive in the shader as uP1 .. uP5). Never write NaN or Infinity.
function templateFrame(V, F, dt) {
  const c = V.c;
  // Smoothed levels for anything that MOVES (F.bassS, F.midS ...: they follow the Smoothness setting); raw
  // F.kick / F.hit / F.hat and the on... events for LIGHT. The ?? fallbacks cover the very first (warm-up) call.
  const bass = F.bassS ?? F.bass ?? 0, mid = F.midS ?? F.mid ?? 0, tension = F.tensionS ?? F.tension ?? 0;

  // kick: restart the ripple the shader draws
  if (F.onKick) c.kickAge = 0;
  c.kickAge = Math.min(c.kickAge + dt, 9);

  // mids turn the rings; S.speed is the person's Speed setting
  c.twist = (c.twist + dt * (0.03 + 0.3 * mid) * S.speed) % 1;

  // bass opens the petals; a build-up (F.tension rises before a drop) tightens them, so the drop can burst open
  const target = (0.5 + 0.5 * bass) * (1 - 0.45 * tension);
  c.open = ease(c.open, target, dt, 0.1 + 0.25 * (F.smooth ?? 0.75));

  // THE TRANSFORMATION. F.onSection fires when the song moves to a new section; F.onImpact on a big arrival
  // (F.impactStrength 0..1 says how big). The flower closes, changes its petal count and palette region, and opens
  // again: a change of structure, not a flash. Land your scene's own transformations on these two cues.
  if ((F.onSection || (F.onImpact && F.impactStrength >= 0.45)) && c.swap >= 1) {
    do { c.nNext = pick(templateCounts); } while (c.nNext === c.n);
    c.swap = 0;
    c.hue = (c.hue + 0.17 + 0.2 * rand()) % 1;
  }
  let closing = 1;
  if (c.swap < 1) {
    c.swap = Math.min(1, c.swap + dt / 0.7);
    if (c.swap >= 0.5) c.n = c.nNext;
    closing = Math.pow(Math.cos(Math.PI * c.swap), 2); // 1 -> 0 -> 1: the count changes while the petals are shut
  }

  // V.trav counts beats travelled (exactly 1 per beat once the tempo is known; it follows loudness when there is
  // no beat). One ring flows by every four beats. The modulo keeps the number small for ever: the shader only
  // needs it modulo 8 rings.
  V.p1 = [(V.trav * 0.25) % 8, c.twist, c.n, c.hue];
  V.p2 = [c.kickAge, c.open * closing, 0, 0];
}
