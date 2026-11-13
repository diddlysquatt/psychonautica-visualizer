# Architecture in one page

After reading this you know how the visualizer is put together, where each part lives in `src/`, and where
to look when you want to understand or change engine behaviour. To make a scene you do not need any of it:
read `SCENE-CONTRACT.md` instead.

## The shape of it

The visualizer is ONE HTML file with no dependencies: raw WebGL2 for the picture, Web Audio for the sound.
It works from a double click. That file is built from small files:

```
src/manifest.json     the order of the parts
src/shell-*.html      the page (markup for the splash screen, the menu, the dock)
src/style.css         all CSS
src/js/NN-name.js     the engine, one script cut at its section headers (the files are parts of ONE
                      function body: they are not modules and cannot be loaded on their own)
scenes/<key>/         one folder per scene: three code files and scene.json
dist/                 the built visualizer
```

`tools/build.py` (or `build.mjs`) concatenates the parts in manifest order and fills the scene
placeholders (`//@scene glsl|helpers|entry <key>` lines, `/*@scene show|auto <key>*/` table values) from
the scene folders. Everything runs in one strict-mode scope.

In the code a scene is called a **realm** (`REALMS`, `goRealm`, `R`). A **visit** (`V`) is one stay in a
scene, with its own seed and state.

## The engine parts (`src/js/`)

| File | What is in it |
|---|---|
| `00-core.js` | Small helpers (`clamp`, `lerp`, `ease`, `rand`), phone detection, the settings `S` and their storage, `E` (the settings actually in effect while the Auto Show is choosing), the built-in palettes. |
| `01-shader-common.js` | `COMMON`: the GLSL header every scene shader gets (uniforms, `pal`, `spec`, `scr`, hashes, `orn`). |
| `02-`, `04-scene-shaders-*.js` | Where the scenes' GLSL goes (placeholders), plus one shared tunnel shader. |
| `03-post-shaders.js` | The shared passes: feedback / compose (trails, liquid warp, kaleidoscope, the transitions between scenes), bloom down / up, upscale, composite (tone map, saturation), exposure. |
| `05-scene-contract-and-helpers.js` | The contract comments, shared JavaScript helpers for scenes (`rotMat3`, `v3`, the fly-through camera), and where the scenes' helpers go. |
| `06-scene-table.js` | `const REALMS = [ ... ]`: where the scene objects go, and two small per-scene tables. |
| `07-webgl-core.js` | Context, programs, render targets, quality tiers (`HD`), and scene preparation: compiling in the background, the warm-up draw, the lazy path for phones. |
| `08-audio.js` | Audio sources (files, queue, microphone / tab capture, the built-in song), the analysers, levels, kick / snare / hat detection, tempo and bar tracking, drops and builds. `FA` = what is heard now, `F` = what the visuals show (delayed by the output latency). |
| `09-music-cues.js` | The music-structure engine: sections, impacts, tension, downbeats and phrases, energy and swell, melodic onsets; the built-in song generator. |
| `10-director-and-transitions.js` | The pointer, the director `D` (current / next / upcoming visit, the shuffle bag), `makeVisit`, `goRealm`, transition styles, mutation, palette changes. |
| `11-auto-show.js` | The Auto Show: per-scene profiles (`AUTO_REALM`), framing and fold rules (`SHOW`), the kaleidoscope director, running order. |
| `12-motion-and-audio-response.js` | The Smoothness dial, per-scene audio gain and flicker guard, `realmFrame` (what calls a scene's `frame()`), fold changes. |
| `13-quality.js` | Resolution tiers and the Auto quality controller. |
| `14-rendering.js` | Zoom (wheel, pinch, the Auto Show's camera moves), `renderRealm` (sets a scene's uniforms and draws it), the 8-band envelopes, `render()` (the whole frame). |
| `15-frame-loop.js` | `frame()` / `step()`: the order of everything per frame; preparation of the display passes; a GPU self-test. |
| `16-ui.js` | The menu (built from one table, `CONTROLS`), scene chips, the music queue, toasts, recording. |
| `17-input.js` | Keyboard, wheel, touch gestures, the developer overlay for the music cues. |
| `18-boot.js` | Start-up order. |
| `19-offline-render.js` | Frame-by-frame rendering on a virtual clock (used by the tests and for making videos). |
| `20-scene-packs.js` | Loading scenes at run time (the older pack loader). |
| `NN-scene-manager.js` | Present once the engine has the scene manager: the scene set, playlists, link parameters, `registerScene`, the scene editor. |
| `NN-automation-api.js` | `window.HyperVisualizer`, the object tools and scripts talk to. |

File names and numbers come from `tools/split.py`; they can shift when the engine grows.

## One frame

`step(dt)` in `15-frame-loop.js`:

1. `AU.analyze` reads the analysers; `syncVisualFeatures` publishes `F` (delayed to match what is heard) and
   delivers the music cues.
2. `bandsUpdate`, `smoothFeatures`: the 8-band envelopes and the smoothed twins (`F.kickS` ...).
3. `autoUpdate`, `autoZoomUpdate`: the Auto Show decides effect levels, the fold plan and camera moves.
4. `directorUpdate`: palette, scene changes, mutation.
5. For the current, the next and the upcoming visit: advance `V.trav` and `V.mt`, then `realmFrame(V, dt)`
   calls the scene's `frame(V, F, dt)` with the audio that scene is meant to hear.
6. `render(dt)`: `renderRealm` draws the scene (two during a crossfade) into off-screen targets; the
   feedback pass composes them with trails, warp, the fold and the transition; bloom; upscale; composite
   with auto-exposure.

## The automation object

`window.HyperVisualizer` exposes what tools need: `S` (settings), `F` (audio features), `D` (director),
`REALMS`, `prepare()`, `ready` / `allReady`, `goRealm(index)`, `showOf(R)`, `setAutoShow(on)`,
`offline.load(arrayBuffer, { seed })` and `offline.frame(n, fps)` for deterministic frame-by-frame runs,
`preparation` (compile timings). `tools/check-scene.mjs` is a worked example of driving it.

## Principles the engine keeps

- One file, no dependencies, no network. It must keep working from a double click, offline.
- A scene never needs an engine change, and the engine never names a new scene.
- Phones are first-class: the base tier is always light, scenes compile lazily.
- The same seed and the same audio give the same frames (that is what the offline renderer and the tests
  rely on): randomness goes through `rand()`.
