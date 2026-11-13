# Testing a scene

After reading this you can check a scene with one command on Windows, macOS or Linux, read every line of
the result, and know what the tool cannot tell you.

## Setup (once)

```
npm install                      # installs Playwright, the only dependency
npx playwright install chromium  # only if the check says no browser could be started
```

Node 18 or newer. The check builds with Node, so Python is not needed for it. If Playwright has no browser
of its own the tool tries an installed Chrome or Edge; `VISUALIZER_CHROME=/path/to/chrome` picks one by hand.

## The command

```
node tools/check-scene.mjs <key>                       # a scene in scenes/<key>/
node tools/check-scene.mjs _template                   # the template: run this first to test your setup
node tools/check-scene.mjs path/to/thing.scene.js      # a scene pack file
```

Options: `--gl swiftshader|hardware|vulkan`, `--seconds N`, `--size WxH`, `--quick`, `--out DIR`.
The exit code is 0 when it passed (warnings may still be printed), 1 when it failed, 2 when it could not run.
Results go to `check-out/<key>/`: `sheet.jpg`, `thumb.jpg`, `report.json`, and the small build
`<key>.html` you can open yourself.

By default the browser renders in software (`--gl swiftshader`). It works on any machine, including one
with no GPU and CI runners, but it is slow and its compile time means nothing. `--gl hardware` uses your
GPU: do this at least once on Windows, where shaders compile through Direct3D and compile time is real.

## What it does and how to read it

**1. files.** Mistakes visible without running anything: a backtick or `${` in the shader, no
`void realm()`, WebGL1 names, `Math.random()`, an entry without `init` / `frame` or not ending in `},`,
top-level names without the key prefix, a missing `scene.json` field. These fail fast.

**2. load and compile.** Builds a visualizer with only your scene, opens it, prepares it. Any shader error,
page error or console error fails the check, and the message is printed. `compile + first draw` is the time
from starting to compile your shader to its first finished draw.

**3. health run.** Plays a built-in 24-second test track (128 BPM: a quiet intro, a groove, a build with no
kick, a drop) through the real audio analysis with the Auto Show on, frame by frame at 30 fps.
- `V.p1..p5, V.m1, V.m2 finite on every frame`: no NaN or Infinity left your `frame()`.
- `no black passages`: fails when 5 sampled frames in a row have under 2% of the picture lit (after the
  first two seconds).
- `picture over the run`: mean brightness, lit share, **ink** (share of dark pixels: you want a good
  quarter) and **pale** (share of bright, unsaturated pixels: washout; you want it near zero). Warnings, not
  failures.
- `cues the engine found`: how many kicks, section changes, impacts and drops it heard in the test track.
  Expect kicks and at least one section change and impact. This tells you the cues your scene could have
  used during the run.

**4. response to each part of the music.** For each of six inputs (sub and bass, mids, highs, kick, snare,
hats) the scene is run again over the same clock with ONLY that input present, and its frames are compared
with the frames of a run with no input at all. Printed: the share of the picture that changed, mean and
peak. Under 0.5% means the scene does not visibly answer that input: a warning. Higher is not better by
itself (a scene that redraws everything on every hat is strobing); what you want is each input clearly
above zero and the inputs different from each other. Use it before and after a change: the numbers must not
fall. Skipped with `--quick`.

**5. contact sheet.** `sheet.jpg`: the zoom ladder (0.15, far, home, close, 2.5 at the same moment), home
in the first fold of your `show` row, then eight frames of the Auto Show tour from step 3 with their time
and zoom. `thumb.jpg` is the home framing: use it as the scene's thumbnail.

## What the tool cannot tell you

- Whether the scene is good. Open the sheet and look, small and at full size, against `ART-DIRECTION.md`.
- How it moves. Stills hide sway, jerks and strobing. Open `check-out/<key>/<key>.html`, play music, watch
  several minutes with the Auto Show on.
- How it behaves with real music. The test track is short and simple. Try three genres of your own.
- Compile time on Windows, unless you ran it there with `--gl hardware`.
- Speed. Watch the frame rate in the real page at 1080p (the menu shows the render size; press H for the
  controls). If the picture goes soft a few seconds into your scene, the engine has lowered the resolution
  because the scene is slow.

## Useful addresses

Add these to the address of any build:

| Parameter | Effect |
|---|---|
| `?realm=<key>` | open on that scene |
| `?cues=1` | overlay of every music cue, live (also Ctrl+Shift+Y) |
| `?mobile=1` / `?mobile=0` | force the phone defaults on or off |
| `?clean=1` | hide the interface |

## Testing the whole visualizer

`python tools/build.py . dist/psychonautica-visualizer.html` builds everything; open it and let the Auto
Show run. After changing anything in `src/`, run the check on a few scenes of different kinds (a flat one,
a 3D one, the template) and watch a full cycle.

Round trip (only for maintainers who still have the single-file original): `tools/split.py` cuts a
visualizer file into `src/` and `scenes/`; `tools/build.py . out.html --verify original.html` must print
`IDENTICAL`.
