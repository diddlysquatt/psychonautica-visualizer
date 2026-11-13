const REALM_MAIN = `
void main(){fragWin=vec4(.5,.5,0.,0.);realm();}`;

/* ============================== realms =============================== */
/* Realm contract additions (ENGINE v10):
   - Motion smoothness: S.motionSmooth (0 snappy .. 1 glide, default .75) is also F.smooth in frame() and the uniform
     uSmooth in GLSL (0 for MUMM3). If you add camera or geometry motion of your own, scale your spring
     stiffness / easing time by it. Smoothed audio for motion: F.kickS F.hitS F.hatS F.subS F.bassS F.midS F.highS
     F.levelS (attack and release grow with the dial); keep raw F.kick etc. for light and colour.
   - R.motionLP (0..1, optional): how strongly the engine low-passes this realm's inputs above 75% smoothness (frame()
     then sees smoothed F, BANDS and specBytes; the shader smoothed uKick/uHit/uHat/levels/uB/uO). Default 1 for the 3D
     realms in MOTION_3D, .7 for the rest; MUMM3 and LED 06 are never touched.
   - R.auto (optional) feeds the Auto Show: { kal: [folds best first, 0 = unfolded], kalCycle: true|false (cycle 2-4
     folds per visit), kalZoom, transitions: ['portal','vortex','melt','shatter','leak','kaleido','mosh'], bars, tier: 1..3,
     kind: 'flat'|'3d'|'tunnel', fx: { trails, warp, bloom, chroma, flashes, colorSpeed }, notes }. Without
     it the engine uses AUTO_REALM[key], then derives one from syms and fb.live. See AUTO SHOW below.
   Realm contract additions (ENGINE v11, see AUDIO RESPONSE below):
   - Audio sensitivity now reaches everything a realm hears: frame() gets F levels / F.kick-hit-hat, BANDS.lv, BANDS.on
     and specBytes, the shader uSub..uLevel, uB1/uB2, uO1/uO2, uKick/uHit/uHat, all scaled by one per-realm gain
     (F.react carries it). Levels keep their average and move more or less; transients scale under a soft ceiling.
   - R.react (number, optional, default from REALM_REACT or 1): this realm's calibration so it pulses about as hard as
     the others at the default settings. Leave it out unless you measured with work/engine11/levels.cjs.
   - Never re-create the engine's onset detectors from specBytes yourself: read BANDS.on / F.kick so the gain and the
     flicker guard apply. */
/* Realm contract additions (ENGINE v22): MUSIC STRUCTURE CUES (the CUE engine, see "ENGINE v22: MUSIC STRUCTURE CUES").
   What the song is doing over bars and sections, for any kind of music, so a scene can transform "bam" on drops and
   section changes and dance loose but on the beat. Everything old is unchanged: F.onKick / onHit / onDrop / onBar, beat,
   bar, bpm, barIndex, conf, breakdown, build keep their exact values (proved frame by frame and pixel by pixel in
   work/engine22/NOTES-V22.md). The cues are computed at 100 Hz on the analysis spectrum, so live playback, mic / tab
   capture and the offline renderer give the same cues; Audio sensitivity does not change structure. Events land on
   their own musical time (found a moment late, they are scheduled, like drops). Per-genre numbers below are from
   the 12-track synthetic test set (work/engine22/wav, scored by tools/score.cjs, report/final.md); real music is
   messier: treat the percentages as "how it behaves", not guarantees.

   HOW TO USE THEM (the short version)
   - F.onSection is THE dependable transformation cue: change formation, structure, palette region, camera mode or
     material on it. Fires in every genre, with or without a beat (37 of 39 real section changes found, 1 false).
     F.sectionSeed gives each section its own fixed random number; F.secLow / secMid / secHigh / secBright say what
     the new section sounds like (choose WHICH transformation from them).
   - F.onImpact with F.impactStrength is the graded "bam": the arrival itself (a drop, the band coming back, a return
     from silence, horns and a crash over the groove). 20 of 20 found, 0 false on the test set: a false bam is worse
     than a missed one and the detector is tuned that way. >= .8 is a real drop: go big. .45 .. .8 a strong arrival.
     Under .45 a modest one (a punch, not a rebuild). A strong impact (>= .6) is also a section start in the same frame.
   - F.onDrop (old) stays a bonus that may never come: it needs a bass dropout and fires only in some dance music.
   - Dance on F.onDownbeat (the musical "one") and F.barPhase / F.pulse; phrase moves on F.onPhrase / F.phrasePos;
     loosen it when F.beatConf or F.downConf are low (rubato, ambient: then onDownbeat simply does not fire).
   - Build anticipation on F.tension (it rises BEFORE the impact and is cut to 0 by it).

   CONTINUOUS (every frame; also smoothed twins F.impactS, F.noteS, F.tensionS, F.energyS for motion)
   - F.energy 0..1: absolute loudness against the loudest the track has been (unlike F.level, which is auto-ranged and
     reads high in quiet passages). A quiet verse really reads low. F.energyTrend -1..1: 2 s level against 8 s.
   - F.swell 0..1: slow (3 s) envelope against its own last 40 s; F.swellDir -1..1 rising / falling. For music with
     no beat this is the motion source (ambient swell direction right 67 %).
   - F.tension 0..1: a build is happening (riser in the top band, a roll of onsets, the bass thinning out, a
     crescendo), only where there is a pulse. Builds reached (peak >= .5) 7 of 7; 3 s above .5 outside builds over the
     whole set (in ambient). Held through the silence before a drop (up to 4 s); falls to 0 at the impact.
   - F.novelty 0..1: how different the last bars are from the section so far (the section detector's own measure).
   - F.bright 0..1 spectral brightness; F.sustain 0..1 held notes / pads present.
   - F.secLow, secMid, secHigh (shares, sum 1), secDense 0..1 (onset density), secBright 0..1, secEnergy 0..1: the
     running character of the CURRENT section (last 12 s of it), eased. Read them on onSection to pick a look.
   - F.section (counter, never resets except at an offline render start), F.sectionAge (s since the section began, from
     the estimated change point, not the moment it was recognised), F.sectionSeed 0..1 fixed per section.
   - F.impact 0..1: decays (1.2 s) from the strength of the last impact; F.impactStrength: that strength.
   - F.note 0..1 (decays .22 s) melodic / chordal onsets (tonal peaks 240 Hz .. 4 kHz); F.notePos 0..1 their pitch
     height. Follows Audio sensitivity like kick / hit / hat. Good on piano and lead lines, noisy on dense mixes.
   - F.beatConf 0..1: is there a pulse (tempo repeats at beat and bar, held for seconds, clock steady). Ambient .12,
     solo piano .06, all grooves ~1. Free-wheels at .45 for up to 20 s through a breakdown or a short silence.
   - F.tempo BPM of the CUE clock (its own clock; F.bpm is the old one). It may read the notated tempo or the felt
     half-time pulse and says which by itself: DnB reads 174 (100 %), half-time trap reads 70 or 140 (both counted
     right, 78 %; its first ~35 s read 93, a 3:2 error). 0 when there is no pulse.
   - F.meter 3 or 4: 3/4 read as 3 (waltz 98 % of the time), every 4/4 track 100 % as 4.
   - F.downConf 0..1: how sure the bar line is. F.barPhase 0..1 position in the musical bar (0 = the one),
     F.barBeat 0..meter-1 which beat of the bar, F.pulse 0..1 position within that beat, F.phrasePos 0..1 position
     in the 8-bar phrase (counted from the last section start); without a pulse phrasePos follows the energy contour.

   EVENTS (true for one frame)
   - F.onSection: a new section (a change of texture, density or loudness that lasts, or a strong impact). Lands on
     the beat after the change is clear: median delay about 1.5 s (16 ms when it comes with an impact). Never in the
     middle of a build. Misses (test set): a trap verse after the hook is seen 6 s late (counted missed + false);
     a solo-piano "loud to quiet" phrase is not seen (without a pulse only a clear change of texture counts).
   - F.onImpact: an arrival; F.impactStrength graded 0..1 (see above). Timing error median 7 .. 50 ms (funk 50).
   - F.onDownbeat: the musical "one" (where the low-band accent, the chord change and the bar's peak are; the snare
     backbeat never). Separate from the old F.onBar (which still counts fours from where tracking began). Precision
     on the true one: house 98 %, rock 98, buildup 98, steady 98, silence-cuts 100, falsedrop 95, waltz 94, dnb 72,
     trap 70 (right from 50 s on; wrong while its tempo resolves), FUNK 0 % (its clock sits on the off-beats: a
     syncopated groove whose off-beats are louder than its beats; the bar is then half a beat off throughout).
     In music with no beat it can still fire for a while after a false lock (ambient: 11 in 126 s, piano: 3): check
     F.beatConf / F.downConf before making anything big of it there.
   - F.onPhrase: on the first downbeat of a section and every 8 bars after it (fires together with onDownbeat); without
     a pulse, at each new rise of the energy contour.
   - F.onNote: a melodic onset (see F.note).

   SHADER UNIFORMS (float): uImpact (smoothed impact), uTension, uEnergy, uSecAge (s), uSection (counter mod 4096),
   uBarPh (bar phase), uPhrase (phrase position), uNote (smoothed note x the realm's reaction gain), uSwell.

   DEVELOPER OVERLAY: open the page with ?cues=1, or press Ctrl+Shift+Y, to watch every cue live against real music. */
function rotMat3(ax, ay, az) {
  const cx = Math.cos(ax), sx = Math.sin(ax), cy = Math.cos(ay), sy = Math.sin(ay), cz = Math.cos(az), sz = Math.sin(az);
  // R = Rz * Ry * Rx, stored column-major
  const m00 = cz * cy, m01 = cz * sy * sx - sz * cx, m02 = cz * sy * cx + sz * sx;
  const m10 = sz * cy, m11 = sz * sy * sx + cz * cx, m12 = sz * sy * cx - cz * sx;
  const m20 = -sy, m21 = cy * sx, m22 = cy * cx;
  return new Float32Array([m00, m10, m20, m01, m11, m21, m02, m12, m22]);
}
function foamDE(x, y, z, k0) {
  let s = 1;
  for (let i = 0; i < 8; i++) {
    x = -1 + 2 * fract(0.5 * x + 0.5); y = -1 + 2 * fract(0.5 * y + 0.5); z = -1 + 2 * fract(0.5 * z + 0.5);
    const r2 = Math.max(x * x + y * y + z * z, 1e-6), k = k0 / r2;
    x *= k; y *= k; z *= k; s *= k;
  }
  return 0.25 * Math.abs(y) / s;
}
const v3 = {
  add: (a, b) => [a[0] + b[0], a[1] + b[1], a[2] + b[2]], sc: (a, s) => [a[0] * s, a[1] * s, a[2] * s],
  dot: (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2], len: (a) => Math.hypot(a[0], a[1], a[2]),
  norm: (a) => { const l = Math.hypot(a[0], a[1], a[2]) || 1; return [a[0] / l, a[1] / l, a[2] / l]; },
  cross: (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
};
/* Autonomous fly-through: probes a cone of directions with sphere tracing and steers toward open space. */
function makeFlyer(de, start) {
  let best = null, bd = -1;
  for (let i = 0; i < 400; i++) {
    const q = [start[0] + (rand() - 0.5) * start[3], start[1] + (rand() - 0.5) * start[3], start[2] + (rand() - 0.5) * start[3]];
    const d = de(q[0], q[1], q[2]);
    if (d > bd) { bd = d; best = q; }
  }
  return { pos: best, dir: v3.norm([rand() - 0.5, rand() - 0.5, rand() - 0.5]), up: [0, 1, 0], wander: rand() * 100, free: 1 };
}
function march(de, o, d, maxD) {
  let t = 0;
  for (let i = 0; i < 28 && t < maxD; i++) { const h = de(o[0] + d[0] * t, o[1] + d[1] * t, o[2] + d[2] * t); if (h < 0.002) return t; t += h * 0.9; }
  return Math.min(t, maxD);
}
function flyStep(f, de, dt, speed, probe) {
  f.wander += dt * 0.15;
  const w = f.wander;
  const wv = v3.norm([Math.sin(w * 1.3), Math.sin(w * 0.9 + 1) * 0.6, Math.cos(w * 1.1)]);
  const side = v3.norm(v3.cross(f.dir, Math.abs(f.dir[1]) > 0.95 ? [1, 0, 0] : [0, 1, 0])), upv = v3.cross(side, f.dir);
  let bestD = f.dir, bestS = -1e9, ahead = 0;
  for (let i = 0; i < 9; i++) {
    const a = i === 0 ? 0 : (i - 1) / 8 * Math.PI * 2, r = i === 0 ? 0 : 0.42;
    const d = v3.norm(v3.add(f.dir, v3.add(v3.sc(side, Math.cos(a) * r), v3.sc(upv, Math.sin(a) * r))));
    const free = march(de, f.pos, d, probe);
    if (i === 0) ahead = free;
    const s = free + 0.25 * probe * v3.dot(d, f.dir) + 0.12 * probe * v3.dot(d, wv);
    if (s > bestS) { bestS = s; bestD = d; }
  }
  f.free = ahead;
  const turn = 1 - Math.exp(-dt * (ahead < probe * 0.35 ? 5 : ahead < probe * 0.6 ? 2.6 : 1.2));
  f.dir = v3.norm(v3.add(f.dir, v3.sc(v3.add(bestD, v3.sc(f.dir, -1)), turn)));
  const stepLen = speed * dt * clamp(ahead / probe, 0.15, 1);
  f.pos = v3.add(f.pos, v3.sc(f.dir, stepLen));
  const d0 = de(f.pos[0], f.pos[1], f.pos[2]);
  if (d0 < probe * (f.clear || 0.03)) {
    const e = 1e-3, g = v3.norm([de(f.pos[0] + e, f.pos[1], f.pos[2]) - d0, de(f.pos[0], f.pos[1] + e, f.pos[2]) - d0, de(f.pos[0], f.pos[1], f.pos[2] + e) - d0]);
    f.pos = v3.add(f.pos, v3.sc(g, probe * (f.clear || 0.03) - d0));
  }
  let up = v3.add(f.up, v3.sc([Math.sin(w * 0.7), 1, Math.cos(w * 0.5) * 0.3], dt * 0.2));
  up = v3.add(up, v3.sc(f.dir, -v3.dot(up, f.dir)));
  if (v3.len(up) < 1e-3) up = v3.cross(f.dir, [1, 0, 0]);
  f.up = v3.norm(up);
  const ww = f.dir, uu = v3.norm(v3.cross(ww, f.up)), vv = v3.cross(uu, ww);
  return new Float32Array([uu[0], uu[1], uu[2], vv[0], vv[1], vv[2], ww[0], ww[1], ww[2]]);
}





























//@scene helpers cathedral

//@scene helpers lattice

//@scene helpers klnn

//@scene helpers boxx

//@scene helpers mandala



//@scene helpers foam

//@scene helpers merc

//@scene helpers kubik

//@scene helpers tess

//@scene helpers swarm

//@scene helpers chroma

//@scene helpers flux

//@scene helpers knott

//@scene helpers sol

//@scene helpers spiro

//@scene helpers velvet

//@scene helpers optik

//@scene helpers void9

//@scene helpers gate

//@scene helpers hypr

//@scene helpers cyma

//@scene helpers abyss

//@scene helpers marbl

//@scene helpers eschr

//@scene helpers umi

//@scene helpers hoshi

//@scene helpers kami

//@scene helpers petri
//@scene helpers tykes
//@scene helpers scribe

