# The scene contract

After reading this you know everything a scene receives from the engine, everything it must do, and how the
Auto Show will frame, fold and time it, so that a new scene fits into the visualizer like a puzzle piece.
Every name below was checked against the engine source in `src/js/`. If this file and the code ever disagree,
the code wins: search `src/js/` for the name.

One word first: the docs say **scene**. The code says **realm** for the same thing (`REALMS`, `goRealm`,
`// BEGIN NEWREALM` markers, `?realm=<key>`). Nothing else differs.

Contents: [1 The three parts of a scene](#1-the-three-parts-of-a-scene) ·
[2 How a frame is made](#2-how-a-frame-is-made) · [3 The shader](#3-the-shader) ·
[4 The scene object](#4-the-scene-object) · [5 A visit: state and per-frame code](#5-a-visit-state-and-per-frame-code) ·
[6 The music](#6-the-music) · [7 Zoom](#7-zoom) · [8 Kaleidoscope folds](#8-kaleidoscope-folds) ·
[9 The Auto Show rows](#9-the-auto-show-rows) · [10 Quality tiers](#10-quality-tiers) ·
[11 Transitions and the life of a visit](#11-transitions-and-the-life-of-a-visit) · [12 Phones](#12-phones) ·
[13 Hard rules](#13-hard-rules)

## 1. The three parts of a scene

A scene is a folder `scenes/<key>/`:

| File | What it is |
|---|---|
| `scene.glsl` | JavaScript that declares the fragment shader as a template string: ``const R_<KEY> = `...`;`` |
| `helpers.js` | Optional top-level JavaScript (functions, tables). Every top-level name starts with the key. |
| `entry.js` | The scene object `{ key, name, src, fb, syms, init, frame, ... },` (it ends with a comma: it is one element of the engine's scene list). |
| `scene.json` | `key`, `name`, `description`, `author`, `license`, and the scene's two Auto Show rows `show` and `auto` (section 9), written as JavaScript source text inside a JSON string. |
| `README.md`, `thumb.jpg` | For people and the gallery. The engine never reads them. |

`tools/build.py` (or `tools/build.mjs`) pastes the three code files into the engine between marker comments
(`// BEGIN NEWREALM GLSL: <key>` and so on) and the two rows into the engine's `SHOW` and `AUTO_REALM` tables.
All scenes and the engine end up in ONE strict-mode script with ONE shared scope. That is why JavaScript names
need the key as a prefix. GLSL names do not: each scene is its own shader program.

The same three parts, as strings, make a scene pack (`<key>.scene.js`, see `SCENE-PACKS.md`).

## 2. How a frame is made

```
your shader  ->  feedback / compose pass  ->  bloom  ->  upscale + sharpen  ->  tone map + auto-exposure  ->  screen
(one program     (trails, liquid warp, the     (glow)
 per scene)       kaleidoscope fold, the
                  crossfade between scenes)
```

- Your shader draws the scene into an off-screen target. Its size is the screen size times the resolution scale
  (section 10), so `uRes` is NOT the screen size.
- Everything after it is shared. You do not write trails, glow, kaleidoscope or transitions: you choose how much
  of the trails your scene wants (`fb`, section 4) and which folds suit it (section 9).
- The picture is tone-mapped and auto-exposed. Judge your colours on the final image (the contact sheet from
  `tools/check-scene.mjs`), never on the numbers the shader writes.

## 3. The shader

The engine compiles `COMMON + your string + main`. `COMMON` (in `src/js/01-shader-common.js`) declares
`#version 300 es`, `precision highp float`, the uniforms and helpers below. Your string must define
`void realm()` and write `fragColor`. Do not add `#version`, `precision` or your own uniforms.

### Outputs

| Output | Meaning |
|---|---|
| `fragColor.rgb` | Linear HDR colour. About 0.3 to 1.6 reads as a lit surface; above that it glows. |
| `fragColor.a` | Window mask, 0..1. Write 0 unless you use windows (`fb.win`, section 4). |
| `fragWin` | Window coordinates. Leave it alone unless you use windows (the engine pre-sets it). |

### Uniforms

| Uniform | Type | Value |
|---|---|---|
| `uRes` | vec2 | Size of the render target in pixels. |
| `uTime` | float | Seconds, running at the person's Speed setting (wraps at 36000). |
| `uMT` | float | This visit's "motion time": advances faster with loudness, bass, builds and drops. Good clock for flow. |
| `uZoom` | float | The framing. 1 = the scene's own default, below 1 = further out, above 1 = closer (section 7). |
| `uDose` | float | The Energy setting, 0..2, default 1. |
| `uHue` | float | A slow global colour drift. Already inside `pal()`; add it to your own palettes if you want them to drift. |
| `uDetail` | float | Detail multiplier: 1 normally, lower when the GPU is behind, up to 16 at the top tiers (section 10). |
| `uSmooth` | float | The Smoothness setting 0..1 (0 = snappy, default 0.75). Ease your own motion by it. |
| `uSub uBass uMid uHigh uLevel` | float | Smoothed levels of four frequency ranges and overall loudness, 0..1, auto-ranged. |
| `uKick uHit uHat` | float | Kick, snare and hi-hat envelopes: jump on the hit, decay within a fraction of a second. Already scaled by the Energy and Flashes settings. |
| `uBeat uBar` | float | Phase within the beat / the bar, 0..1 (0 = on the beat / on the bar line). |
| `uDrop` | float | 1 at a drop, decaying over a couple of seconds. Only some dance music produces drops: see `uImpact`. |
| `uBuild` | float | 0..1, rises during a build-up. |
| `uImpact` | float | Decays from the strength (0..1) of the last big arrival in the music (section 6). |
| `uTension` | float | 0..1, rises before an arrival, cut to 0 by it. |
| `uEnergy` | float | Absolute loudness 0..1 against the loudest the track has been (a quiet verse really reads low). |
| `uSecAge` | float | Seconds since the current section of the song began. |
| `uSection` | float | Section counter (modulo 4096). |
| `uBarPh uPhrase` | float | Position in the musical bar / in the 8-bar phrase, 0..1. |
| `uNote` | float | Envelope of melodic onsets (piano, lead lines). |
| `uSwell` | float | Slow (seconds) loudness envelope 0..1: the motion source for music without a beat. |
| `uB1 uB2` | vec4 | Eight log-spaced frequency bands, 28 Hz to 16 kHz, auto-ranged 0..1. `uB1` = sub, bass, low-mid, mid. `uB2` = high-mid, presence, high, air. |
| `uO1 uO2` | vec4 | Onset pulses of the same eight bands: 1 on a sharp rise in that band, decaying over about 0.15 s. |
| `uSpec` | sampler2D | 256 x 2 texture. Row 0 = the log spectrum (read it with `spec(x)`, x 0..1 = 28 Hz..16 kHz). Row 1 = the waveform (`textureLod(uSpec, vec2(x, .75), 0.).r`). |
| `uSeed` | vec4 | The four random numbers of this visit (the same four `init` received). |
| `uVar` | vec4 | Four very slow sines, 0..1 (periods of minutes), for long-term drift. |
| `uP1 .. uP5` | vec4 | Yours. Whatever `frame()` puts in `V.p1 .. V.p5`. |
| `uM1 uM2` | mat3 | Yours. `V.m1`, `V.m2` (nine numbers each: a camera basis, a palette, anything). |
| `uPa uPb uPc uPd uQa uQb uQc uQd uPalT` | vec3, float | The engine's current palette pair. Use `pal()` instead of reading these. |
| `uMouse uLook` | vec2 | Smoothed pointer position; slow "look" offset. Keep any effect gentle. |
| `uMouseV` | vec4 | Always zero now (pointer distortion moved to the compose pass). |

### Helpers in COMMON

| Helper | |
|---|---|
| `PI`, `TAU` | constants |
| `mat2 rot(float a)` | 2D rotation |
| `float h11(float)`, `float h21(vec2)` | hashes 0..1 |
| `float vnoise(vec2)` | value noise |
| `vec3 pal(float t)` | the engine's live cosine palette (it drifts with `uHue` and changes with the music; chroma is kept during a change) |
| `float spec(float x)` | the spectrum at x = 0 (28 Hz) .. 1 (16 kHz) |
| `vec2 scr()` | centred pixel coordinates with the screen HEIGHT = 1: `(gl_FragCoord.xy - .5*uRes) / uRes.y` |
| `float orn(vec2 p, float px, float sd)` | shared anti-aliased filigree: line coverage 0..1 at surface point `p`, pixel size `px` (in `p` units), seed `sd` |
| `vec2 cmul(vec2, vec2)`, `cdiv(vec2, vec2)` | complex multiply / divide |
| `HD` | compile-time quality tier 0..5 for `#if HD>=1` (section 10) |

## 4. The scene object

The smallest complete one is `scenes/_template/entry.js`. Fields the engine reads:

| Field | Required | Meaning |
|---|---|---|
| `key` | yes | 2 to 24 lowercase letters / digits, starting with a letter. Folder name, link id, name prefix. |
| `name` | yes | What people see. Short and stylised (MUMM3, LED 06, KUB1K). |
| `src` | yes | The GLSL string (`R_<KEY>`). |
| `init(seed)` | yes | Called when a visit starts, with four random numbers 0..1. Returns the visit's state. Different seeds should give clearly different variants. |
| `frame(V, F, dt)` | yes | Called every frame for every live visit (section 5). |
| `fb` | yes | The feedback profile, below. |
| `syms` | yes | Kaleidoscope folds for this scene, e.g. `[0,0,6,8]` (0 = unfolded; repeat to weight). One is drawn per visit; the Auto Show uses the `show` row instead when there is one. |
| `description` | no | A few words for the scene list. |
| `cost` | no | Rough GPU cost against other scenes (about 0.8 light .. 2.6 heavy). Phones show light scenes first; the engine prepares the cheapest scene first. |
| `kalZoom` | no | Framing while folded, as a multiple of the unfolded framing (default 0.7 = pulled back). Superseded by `show.k.z` when the scene has a `show` row. |
| `cont` | no | Names of numeric fields (numbers or arrays of numbers) in the state. Every other mutation (section 11) the engine morphs these toward a fresh `init()` over about 2.5 s instead of cross-fading. Default `[]`. |
| `evolves` | no | `true`: the scene changes its own formation on the music, so the engine never mutates it. |
| `continuousJourney` | no | `true`: the scene travels through one seeded world; a mutation only changes the palette. |
| `react` | no | A number (default 1): this scene's audio gain so that it pulses about as hard as the others. Leave it out unless you measured. |
| `motionLP` | no | 0..1: how strongly the engine low-passes this scene's audio inputs when Smoothness is above 75% (default 0.7). |
| `screenMotion` | no | 0..1 (default 1): scales the feedback pass's own zoom / rotation for this scene. |
| `shadowRecovery` | no | 0..1: lets the final pass lift crushed shadows (a few dark 3D scenes use it). |
| `auto` | no | The scene's own Auto Show hints. Use the `show` and `auto` rows of `scene.json` instead (section 9). |

### `fb`: how the feedback pass treats your picture

| Key | Effect |
|---|---|
| `decay` | Trail persistence, 0 .. about 0.9. Crisp line work: 0.1 to 0.3. The Trails setting adds to it. |
| `zoom`, `rot` | Trail zoom / rotation per frame (the trails drift inward and turn). 0 for flat graphic scenes. |
| `warp` | Liquid warp of the trails. |
| `echo` | Glow echo of the previous frame. Leave the key out and you get 0.7; write a small number such as `.04` for almost none. |
| `droste` | Strength of a recursive copy of the picture in the centre. |
| `win` | Window strength: where your shader writes `fragColor.a > 0` the engine shows a nested copy of the picture, using `fragWin` as coordinates. 0 = off. Advanced; the template does not use it. |
| `key` | The brightness the auto-exposure aims for (about 0.05 to 0.3; lower = darker picture). |
| `live` | 0..1, default 1: scales the engine's own live effects (kick zoom, prism split, snare spin, drop flash) for this scene. Graphic scenes use 0.1 to 0.3. |

During a crossfade the two scenes' profiles are blended.

## 5. A visit: state and per-frame code

Each time a scene comes up the engine makes a **visit** `V`:

| Field | |
|---|---|
| `V.c` | Your state: what `init(seed)` returned. Keep ALL mutable state here. |
| `V.seed` | The four seeds. |
| `V.trav` | Beats travelled. With a confident tempo it grows by exactly 1 per beat (surging on each beat), half speed in breakdowns, double after a drop; with no tempo it follows loudness. Starts at a random 0..8. Lock choreography to it. |
| `V.mt` | Motion time (the uniform `uMT`). Starts at a random 0..60. |
| `V.sym` | The fold drawn from `syms` for this visit. |
| `V.p1 .. V.p5` | Write arrays of four finite numbers every frame. They arrive as `uP1 .. uP5`. |
| `V.m1`, `V.m2` | Write a `Float32Array(9)` (column-major 3x3), or leave the identity. |
| `V.R` | Your scene object. |

`frame(V, F, dt)`:

- `dt` is the seconds since the last frame, at most 0.1. It is **0 in the warm-up call** the engine makes once
  when it prepares the scene: never divide by `dt`, and cope with `F` fields that are still missing there
  (`F.bassS ?? F.bass ?? 0`).
- `frame` runs for **several visits of the same scene at once**: the one on screen, the next one during a
  crossfade, a prepared upcoming visit that is not on screen yet, the warm-up. State in a top-level variable
  would be shared by all of them. Put it in `V.c`.
- It must never write `NaN` or `Infinity` into `V.p*` / `V.m*`. One bad number can blank the scene.
- Randomness: `rand()` and `pick(array)` only, never `Math.random()`. The engine swaps `rand` for a seeded
  generator in tests and offline renders; that is what makes a scene reproducible.

Engine names a scene's JavaScript may use (same scope): `rand()`, `pick(arr)`, `mulberry(seed)` (a seeded
generator factory), `clamp(x,a,b)`, `lerp(a,b,t)`, `fract(x)`, `ease(cur, target, dt, tau)` (exponential
smoothing with time constant `tau` seconds, safe at `dt = 0`), `v3` (`add sc dot len norm cross` on arrays),
`rotMat3(ax, ay, az)` (a `Float32Array(9)`), `makeFlyer / flyStep / march` (an autonomous 3D fly-through over a
JavaScript distance function), and read-only: `F` (audio), `BANDS` (`BANDS.lv[0..7]` = the eight band levels,
`BANDS.on[0..7]` = their onset pulses), `S` (the person's settings: `S.dose` Energy 0..2, `S.speed` 0..2.5,
`S.motionSmooth` 0..1), `PTR` (pointer). Read them; do not write engine state.

## 6. The music

`F` (the argument of `frame`) is what the visuals show: it is delayed by the audio output latency, so a pulse
lands when the sound is heard.

### Levels and hits (always available)

| Field | |
|---|---|
| `F.sub F.bass F.mid F.high F.level` | 0..1 smoothed levels, auto-ranged |
| `F.kick F.hit F.hat` | 0..1 envelopes of kick, snare, hi-hat |
| `F.onKick F.onHit` | true on exactly the frame of a kick / a snare |
| `F.kickS F.hitS F.hatS F.subS F.bassS F.midS F.highS F.levelS` | smoothed twins that follow the Smoothness setting. **Motion uses these; light and colour use the raw ones.** |
| `F.smooth` | the Smoothness setting itself, 0..1 |
| `F.beat F.bar` | phase in the beat / bar, 0..1 |
| `F.bpm F.conf` | tempo (0 until known) and how sure it is, 0..1 |
| `F.beatClock F.barIndex` | beats since the start (continuous); bar counter |
| `F.onBar` | true on the frame a bar starts |
| `F.onSceneBar` | true about every 2.5 s when there has been no bar line for 6 s (silence, music without a beat), so bar-driven choreography keeps moving. Treat it like `onBar`. |
| `F.build F.drop F.onDrop F.breakdown` | build-up 0..1; drop envelope and event; breakdown 0..1. Drops need a bass drop-out and fire only in some dance music. |
| `F.silent F.idle` | no audio; idle envelope 0..1 |
| `F.cent` | spectral centroid (brightness), about 0.45 typical |

The band levels are auto-ranged: under a single instrument, or near silence, several bands can read high.
To tell a bass line from hats, weigh a band by its share of the total.

### Music structure cues

What the song is doing over bars and sections, for any kind of music. These are what let a scene transform
"bam" exactly when the music does.

| Cue | Meaning | Timing |
|---|---|---|
| `F.onSection` | A new section of the song (a change of texture, density or loudness that lasts). **The dependable cue for a transformation**: change formation, structure, palette region, camera mode or material on it. Fires in every genre, with or without a beat. | lands on the beat about 1.5 s after a gradual change is clear; within milliseconds when it comes with an impact |
| `F.sectionSeed` | a fixed random number 0..1 for the current section | |
| `F.section`, `F.sectionAge` | section counter; seconds since it began | |
| `F.secLow F.secMid F.secHigh` (sum 1), `F.secDense`, `F.secBright`, `F.secEnergy` | what the current section sounds like. Read them on `onSection` to choose WHICH transformation. | eased over the last 12 s |
| `F.onImpact`, `F.impactStrength` | The arrival itself: a drop, the band coming back in, a return from silence. Graded 0..1: 0.8 and up is a real drop (go big), 0.45 to 0.8 a strong arrival, below 0.45 a punch, not a rebuild. An impact of 0.6 or more is also a section start in the same frame. Tuned to prefer a missed impact over a false one. | within about 10 to 50 ms |
| `F.impact` | decays (about 1.2 s) from the strength of the last impact | |
| `F.tension` | 0..1: a build is happening (a riser, a roll, the bass thinning out). Rises BEFORE the impact, is held through the silence before a drop, and is cut to 0 by the impact. | |
| `F.energy`, `F.energyTrend` | absolute loudness 0..1 against the track's loudest so far; its direction -1..1 | |
| `F.swell`, `F.swellDir` | slow envelope 0..1 and its direction: the motion source for music with no beat | 3 s envelope |
| `F.onDownbeat` | the musical "one" of the bar | |
| `F.barPhase`, `F.barBeat`, `F.pulse` | position in the bar 0..1; which beat of the bar; position within that beat 0..1 | |
| `F.onPhrase`, `F.phrasePos` | first downbeat of a section and every 8 bars after it; position in the phrase 0..1 | |
| `F.beatConf`, `F.downConf` | is there a pulse at all (ambient and solo piano read near 0, grooves near 1); how sure the bar line is. Loosen beat-locked motion when these are low. | |
| `F.tempo`, `F.meter` | tempo of the cue clock (0 with no pulse); 3 or 4 | |
| `F.onNote`, `F.note`, `F.notePos` | melodic onsets, their envelope, their pitch height 0..1. Good on piano and lead lines, noisy on dense mixes. | |
| `F.bright`, `F.sustain`, `F.novelty` | spectral brightness; held notes / pads present; how different the last bars are from the section so far | |

Smoothed twins for motion: `F.impactS`, `F.noteS`, `F.tensionS`, `F.energyS`.

How to use them, in short: dance on `onDownbeat`, `barPhase` and `pulse`; build anticipation with `tension`;
land the big change on `onImpact` scaled by `impactStrength`; change chapter on `onSection`; when there is no
beat (`beatConf` low) move with `swell` instead. Keep `onDrop` as a bonus that may never come.
To watch every cue live against real music, open the visualizer with `?cues=1` (or press Ctrl+Shift+Y).

The Sensitivity setting and the per-scene gain (`react`) are applied by the engine to everything a scene hears
(`F` levels and hits, `BANDS`, the shader's level, band and hit uniforms). Do not rebuild onset detectors of
your own from the spectrum: read `F.onKick` / `BANDS.on`, so the gain and the flicker guard apply.

## 7. Zoom

`uZoom` is the camera distance, and it is a contract:

- 1 = the scene's own default framing; below 1 = further out (a wider view); above 1 = closer.
  Typical use: `vec2 p = scr() / uZoom;` for a flat scene, a camera pull-back for a 3D one.
- A person's wheel or pinch covers **0.15 to 2.5**. The Auto Show moves between your `far`, `home` and
  `close` (section 9). While a fold is active the engine also pulls back by `show.k.z` (or `kalZoom`).
- Zoom is a camera move inside the current world. It never triggers travel, a dive or a change of content.
- Every step of the range visibly changes the framing: no dead zones.
- **Nothing goes dark, blurry, empty or to speckle anywhere in 0.15 .. 2.5.** Zoomed out must show MORE of the
  world (this is where the feeling of enormous scale comes from), not a small object in black. Zoomed in must
  show finer work, not a blur. If a nested world swaps in, cross-fade it over a span of zoom.
- Fine structure that becomes smaller than a pixel must fade to its average colour, not alias: measure your
  pixel size (`1. / (uRes.y * uZoom)` in `scr()/uZoom` units) and anti-alias with it. The template shows how.

## 8. Kaleidoscope folds

The fold happens in the compose pass, not in your shader: the engine mirrors your finished picture into
wedges around the screen centre (your render target repeats mirrored at its edges). Your scene only notices
that it is framed wider while folded. Fold numbers: `0` unfolded, `1` a plain left-right mirror, `2` a
four-way mirror, `3 4 5 6 8 12 16` the kaleidoscope counts.

What this means for a scene: a fold shows a wedge of your picture near the centre many times. A scene whose
centre is empty, or whose interest sits at the edges, folds badly; a scene with a rich centre and structure
at every scale folds well. Look at your scene folded (the contact sheet has one fold) and list only the
folds that look good in your `show` row. Odd counts (3, 5) and 4 look lopsided in many scenes.

The Auto Show opens every visit unfolded and keeps it so for a good stretch (14 to 30 s), folds only in a
share of visits, changes fold on a musical moment (a drop, a phrase line, a lift in energy) with a slow morph,
and never changes fold more often than every 16 bars.

## 9. The Auto Show rows

The Auto Show is the product: a person presses play and never touches a control. Two rows per scene tell it
how to present your scene. In the repository they live in `scenes/<key>/scene.json` as JavaScript source text;
in a scene pack they are the `show` and `auto` objects.

### `show`: framing and folds

```js
{ z: [.3, .6, 1.2], c: .4, w: .6, k: { p: .3, s: [6, 8, 12], o: [5, 16], z: .9 } }
```

| Field | Meaning |
|---|---|
| `z: [far, home, close]` | Effective zoom values (what your shader gets as `uZoom`), ascending. **home**: the framing the show lives at and every visit arrives at; it is shown for 12 to 21 s before anything else. Choose the zoom where the whole scene reads, with a little to spare. **far**: the widest view worth a visit (beyond it the scene repeats, thins or turns to speckle); visits go 45 to 100% of the way there. **close**: the closest framing worth a SHORT visit (held 4 or 8 beats, then back home); visits go 50 to 100% of the way. `far = home = close` means the engine never moves the camera (a scene that flies itself). |
| `c` | Appetite for close-ups, 0 (never) .. 1 (at most one every 26 s). |
| `w` | Appetite for the far view, 0 .. 1. |
| `k.p` | Share of visits that fold at all at the default "Auto folds: Some" (0 = never fold). |
| `k.s` | Superb folds, best first (the first is the likeliest). |
| `k.o` | Acceptable folds (rarely used). A fold in neither list is never used. |
| `k.z` | Framing while folded, as a multiple of home (0.9 = 10% wider). |
| `k.cyc` | `true`: a folded visit may glide on into a second fold. |
| `k.ok(V, fold)` | Optional function: return false to keep that fold out right now. |
| `no` | Transition styles the Auto Show never uses with this scene, as indices into `portal 0, vortex 1, melt 2, shatter 3, leak 4, kaleido 5, mosh 6, cut 7, dissolve 8`. The dissolve takes their place. |
| `hold(V)` | Optional function: return true while your scene is in the middle of something (a dive, a set piece) and the director should not start a zoom move or a fold change. `V.c` is your state. |

A scene with no `show` row gets home 0.6, far 0.35, close 1 and its `syms` as folds in 40% of visits.
The standing rule for home: never too close for too long, always show the full scene.

### `auto`: place in the running order and effect levels

```js
{ tier: 2, kind: 'flat', kal: [0, 6, 8, 12], bars: 32, tr: ['melt', 'leak'], fx: {} }
```

| Field | Meaning |
|---|---|
| `tier` | 1 show-stopper, 2 strong (default), 3 lighter. The running order spreads the tiers evenly and opens a cycle with a tier 1 scene. A new scene is 3 until people say otherwise. |
| `kind` | `'flat'` (2D graphic), `'3d'`, or `'tunnel'`. Sets the default effect levels and keeps two scenes of one kind from following each other. |
| `kal` | Folds, best first (0 = unfolded). Only used when the scene has no `show` row. |
| `bars` | Scene length in bars when the person chose "bars" as the scene length (8 .. 64, default 32). |
| `tr` | Transition styles this scene likes to arrive with, by name: `portal vortex melt leak kaleido dissolve`. |
| `fx` | Overrides of the shared effect levels while this scene is on: `{ trails, warp, bloom, chroma, flashes, colorSpeed }` (defaults for a flat scene: trails 0.48, warp 0.32, bloom 0.78, chroma 0.32, flashes 0.75, colorSpeed 0.7). Lower `bloom` if your scene washes out. |

## 10. Quality tiers

Two separate dials reach your shader.

**`HD`, a compile-time constant.** The engine compiles your source once per tier with `#define HD n`:

| Resolution setting | `HD` | resolution scale | `uDetail` at Detail 1x |
|---|---|---|---|
| Auto | 0 | adapts to the frame rate | 1 (lowered when the GPU is behind) |
| Low / Medium / High | 0 | 0.42 / 0.58 / 0.78 | 1 |
| Native | 1 | 1 | 2 |
| Cinema 1.5x | 2 | 1.5 (supersampled) | 3 |
| Insane 2x | 3 | 2 | 4.5 |
| Extreme 3x | 4 | 3 | 6.5 |
| Offline 4x | 5 | 4 | 10 |

Every phone is always `HD 0`. Code under `#if HD>=1` costs the lower tiers nothing, in compile time or on the
GPU. So:

- **`HD 0` is the scene.** It must be complete, beautiful and light. It is what phones and most people see.
- `#if HD>=1` (Native): finer ornament, a second layer of detail, more samples. Things that make the same
  picture richer, never things the picture needs.
- `#if HD>=2` and up: what only pays off at very high resolution or in an offline video render.

**`uDetail`, a run-time number.** Scale loop counts and nesting depth with it: a constant upper bound and an
early `break`, as `orn()` in `COMMON` does (`if (float(i) >= 8. + 4.*log2(max(uDetail, 1.))) break;`).
The Detail slider (0.5x .. 16x) multiplies the table's value (capped at 16); Auto lowers it, but never below
half, before it lowers the resolution further.

Budgets (Windows, where Chrome compiles through Direct3D 11, is the slow case; see `PITFALLS.md`): the first
draw of the `HD 0` shader should take under about 8 s, `HD 1` under 20 s, `HD 5` under 45 s. Frame time at
1080p, High: comparable to the built-in scenes (most are 3 to 9 ms on a mid-range desktop GPU).

## 11. Transitions and the life of a visit

1. **Preparation.** Scenes compile in the background after the app opens (on a phone: only the scene that is
   next). A scene is drawn once into a tiny target with a seeded `rand` and `frame(V, F, 0)`; only then is it
   "ready" and eligible. A shader that fails to compile simply never appears.
2. **Arrival.** The engine cross-fades from the previous scene with one of its transition styles (portal,
   vortex, melt, light leak, kaleido fold, dissolve; shatter, datamosh and hard cut only by hand). During the
   crossfade both scenes render every frame, so cost doubles for a second or two. Your scene arrives standing
   at its own `home` framing from its first frame.
3. **The stay.** Default 90 s per scene (the person can choose 30 s to 5 min, a number of bars, or "stay").
   The camera lives at home with short visits to close and far; folds come and go (section 8); the palette
   changes every few bars; your own transformations land on the cues.
4. **Mutation.** Every 8 bars, a scene that is not `evolves` is refreshed by the engine: alternately a morph
   of its `cont` fields toward a fresh `init()`, and a crossfade into a fresh visit of the same scene (new
   seed). A scene with real transformations of its own should set `evolves: true`.
5. **Leaving.** On a phrase line when the stay is over, or on a drop. The next scene is already prepared
   (`frame` has been running for it off screen).

With a scene list and playlists (`PLAYLISTS.md`) a person decides which scenes play, in what order and for
how long; the life of a single visit is the same.

## 12. Phones

- Always `HD 0`, a capped pixel ratio (1.5) and a lower starting resolution: keep the base tier light.
- Shaders compile slowly on phones, often on the page's own thread. Compile time is part of the cost.
- Only a few scene programs are kept in memory; lighter scenes (by `cost`) come first in each cycle.
- There is no pointer hover; taps change the fold and bring the controls back. A scene must be complete with
  no interaction at all.
- `highp` everywhere is assumed (the engine sets it). Avoid precision cliffs: keep coordinates small (wrap
  travel with a modulo in `frame()`, as the template does) so hours of running do not degrade the picture.

## 13. Hard rules

1. The shader string contains no backtick and no `${` (not even in a comment): it lives inside a JavaScript
   template string.
2. `rand()` / `pick()` only, never `Math.random()`.
3. All mutable state in `V.c`. Top-level JavaScript names start with the scene key.
4. No `NaN` / `Infinity`, at `dt = 0`, in silence, before the tempo is known, and after hours of running.
5. Loops have constant upper bounds. Scale them with `uDetail` by an early `break`.
6. Motion follows smoothed signals (attack at least about 60 ms, release at least about 200 ms, stiffness
   scaled by `F.smooth` / `uSmooth`); positions and directions are continuous from frame to frame. Only light
   and colour may snap to a transient.
7. Nothing dark, empty, blurry or speckled anywhere in zoom 0.15 .. 2.5.
8. The base tier (`HD 0`) stays light; extra cost goes under `#if HD>=1` and up.
9. A scene edits only its own folder. It never needs a change to the engine.
10. It is original work (see `CONTRIBUTING.md`).
