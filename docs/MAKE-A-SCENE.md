# Make a scene

After reading this you can take an idea ("a scene that does X") from an empty folder to a tested scene, a
scene pack other people can add, and a pull request. It takes one sitting. No engine code changes, ever.

You need: Python 3.8+ or Node 18+ to build, Node 18+ and `npm install` to test. Run every command from the
repository root.

## 0. The five-minute version

```
python tools/new-scene.py aurora "AURORA" --author "your name" --description "curtains of light"
node tools/build.mjs . dist/aurora.html --scenes aurora      # or: python tools/build.py . dist/aurora.html --scenes aurora
# open dist/aurora.html in a browser (double click), press play, and look
node tools/check-scene.mjs aurora                             # checks + check-out/aurora/sheet.jpg
python tools/pack.py aurora                                   # dist/scenes/aurora.scene.js, the file you share
```

`new-scene.py` copies `scenes/_template/`: a small, complete, commented scene (an endless flower whose rings
each listen to one frequency band). Build it and run the check once BEFORE changing anything, so you know
the tools work on your machine. Then replace the template's idea with yours, keeping what it demonstrates:
the zoom contract, anti-aliasing by pixel size, smoothed motion, a transformation on the music cues.

## 1. The smallest scene that works

This is a whole scene. Three files (the fourth, `scene.json`, is metadata):

`scenes/dots/scene.glsl`
```js
const R_DOTS = `
void realm(){
  vec2 p=scr()/uZoom;                       // centred, height = 1, zoom contract
  vec2 g=fract(p*6.)-.5;                    // a grid of cells
  float band=spec(fract(floor(p.x*6.)*.13+.5)); // each column reads one place in the spectrum
  float r=.12+.3*band+.1*uKick;             // the dot grows with its band and with the kick
  float px=6./(uRes.y*uZoom);               // one pixel, in cell units
  float m=smoothstep(r+px,r-px,length(g)); // 1 inside the dot, anti-aliased edge
  fragColor=vec4(pal(p.x*.3+uP1.x)*m*(.4+1.2*band),0.);
}`;
```

`scenes/dots/helpers.js` (may be empty)
```js
function dotsInit(s){ return { drift: s[0] }; }
```

`scenes/dots/entry.js`
```js
  {
  key:'dots',name:'DOTS',src:R_DOTS,description:'a grid of dots, one column per pitch',cost:0.6,
  fb:{zoom:0,rot:0,decay:.2,warp:0,echo:.04,droste:0,win:0,key:.08,live:.2},syms:[0,0,6,8],
  init:(s)=>dotsInit(s),
  frame(V,F,dt){ const c=V.c; c.drift=(c.drift+dt*.05*S.speed)%1; V.p1=[c.drift,0,0,0]; }
  },
```

What the engine needs from you is exactly this: a shader with `void realm()` that writes `fragColor`, and an
object with `key`, `name`, `src`, `fb`, `syms`, `init`, `frame`. Everything else is optional.
It is also a poor scene: it is flat, it does nothing on a drop, and zoomed out it turns to speckle.
The rest of this page is how to make a good one.

## 2. Design before code

Write these down first (keep them as a comment at the top of `scene.glsl`; reviewers read it):

1. **The idea in one sentence**, and why it looks like nothing already in `scenes/`.
2. **Scale.** What does zoom 0.15 show? It should be the same world, vast: more of it, not a small thing in
   black. What does zoom 2.5 show? Finer work, not blur. Structures that repeat at every scale (log-polar
   rings, tilings, fractals, cities) make this easy.
3. **Colour.** Which material is this: neon, stained glass, engraved metal, tapestry, paper, fire-lit stone?
   Saturated colour with dark ink between it. `pal()` gives the engine's drifting palette; a scene may
   bring its own curated palettes too.
4. **The music map**, each line a different visible thing:
   bass / sub; kick; snare; hats and the top bands; mids; the spectrum (frequency mapped legibly to position:
   row, ring, radius, angle; never to a random hash); a build (`F.tension`: tightening, winding up);
   the arrival (`F.onImpact`: a transformation of structure, scaled by `F.impactStrength`);
   a new section (`F.onSection`: a new formation, palette region, camera mode or material).
5. **The transformation.** What does the scene turn INTO on a drop? At least two or three distinct states and
   a way of moving between them that never passes through an empty or dark frame.
6. **Framing.** Home (the whole scene, with a little to spare), far, close: three numbers for the `show` row.

## 3. Write it

Work in small steps: change, rebuild the small file, look.

- **Shader** (`scene.glsl`): start from `vec2 p = scr() / uZoom;`. Use the audio uniforms for light and
  colour directly (`uKick`, `uHit`, `uHat`, `uB1`, `uB2`, `uO1`, `uO2`, `spec()`), and `uP1 .. uP5` for
  anything that needs memory or smoothing. Anti-alias every edge with the pixel size. Read `PITFALLS.md`
  before you write loops, arrays or long `?:` chains.
- **State and motion** (`helpers.js`, called from `entry.js`): `init(seed)` returns the visit's state;
  `frame(V, F, dt)` advances it and writes `V.p1 .. V.p5`. Motion from the smoothed features (`F.bassS`,
  `F.midS` ...) through `ease()`; events (`F.onKick`, `F.onSection`, `F.onImpact`) start things. `V.trav`
  counts beats travelled: lock steps and travel to it and they stay on the beat.
- **Rows** (`scene.json`): `show` and `auto`, see `SCENE-CONTRACT.md` section 9. Start with the template's
  rows and tune home / far / close by looking at the contact sheet.
- **Higher tiers**: when the base scene is good, add finer ornament under `#if HD>=1`.

The full list of what a scene receives is `SCENE-CONTRACT.md`. What makes a scene belong here is
`ART-DIRECTION.md`. Both are short; read them before a second pass.

## 4. Look, then measure

```
node tools/check-scene.mjs aurora
```

Open `check-out/aurora/sheet.jpg`. First two rows: the zoom ladder (0.15, far, home, close, 2.5) and one
fold. The rest: a tour through an Auto Show visit over the test track (quiet intro, groove, build, drop).
Look at it small (does it read as a scene, or as texture?) and at full size (is the detail crisp?).

Then the printed numbers: errors, black frames, the share of the picture that answers to each part of the
music, pale and dark shares, compile time. `TESTING.md` explains each line. A number is never proof that a
scene is good; it can only tell you that something is broken.

Also run it for real: open the built file, play your own music (three different genres), turn the Auto Show
on and watch several minutes. Try `?cues=1` to see the music cues the engine finds.

## 5. Share it

- **As a pack** (anyone can add it to their visualizer, nothing to install):
  `python tools/pack.py aurora` writes `dist/scenes/aurora.scene.js`. Post it in the Discussions forum, or
  attach it anywhere. See `SCENE-PACKS.md`.
- **Into the collection** (reviewed, shown in the gallery, playable from a link): a pull request that adds
  ONE folder `scenes/<key>/` with `scene.glsl`, `helpers.js`, `entry.js`, `scene.json`, `README.md` and
  `thumb.jpg` (the check tool writes `check-out/<key>/thumb.jpg`: copy it). See `CONTRIBUTING.md`.

## Checklist

- [ ] The idea is new here, and the work is your own.
- [ ] `node tools/check-scene.mjs <key>` passes; you read every warning.
- [ ] Sheet, small and at full size: no washout, no flood of one hue, no dark or empty frame, no speckle,
      at every rung of the zoom ladder and in the fold.
- [ ] Bass, mids and highs each visibly drive something different; kick and snare are distinct.
- [ ] Something transforms on `F.onImpact` / `F.onSection`, and it lands on the moment.
- [ ] It moves like dancing: loose, on the beat, never jerky, never a slow aimless sway.
- [ ] With no music playing, and with music that has no beat, it is still alive and still lit.
- [ ] `show` row: home shows the whole scene; far and close are worth a visit; only folds that look good.
- [ ] Base tier is light (first draw on Windows under about 8 s; runs on a phone with `?mobile=1`).
- [ ] No backtick or `${` in the shader, no `Math.random()`, all state in `V.c`, every top-level name
      starts with the key.
- [ ] `scene.json` has name, description, author, license; `README.md` says what it is, how it moves with
      the music, its framings and its known weak points, honestly.
