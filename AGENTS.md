# AGENTS.md

You are a coding agent and someone has asked you for a scene ("make me a scene that does X"), or to change
this project. This page is the map. It is short on purpose: read it all, then the two docs it points to.

## What this is

The Psychonautica visualizer: an audio-reactive WebGL2 music visualizer that runs from ONE HTML file with no
dependencies (`dist/psychonautica-visualizer.html`, works from a double click). It travels through
**scenes**: full-screen GLSL shaders, each with a small JavaScript part that turns the music into smooth
numbers. Its Auto Show runs everything hands-off: which scene, for how long, the camera distance, the
kaleidoscope, the transitions. People add scenes of their own; that is what this repository is for.

The single file is BUILT from small files, so you never need to open anything large.
In the code a scene is called a "realm" (`REALMS`, `goRealm`); it is the same thing.

## Map

```
AGENTS.md                 this page
docs/SCENE-CONTRACT.md    everything a scene receives and must do  <- read before writing scene code
docs/MAKE-A-SCENE.md      walk-through, smallest example, checklist  <- read first
docs/ART-DIRECTION.md     what makes a scene belong here, what gets it sent back
docs/PITFALLS.md          what fails or compiles slowly (Windows!), NaN, washout, phones
docs/TESTING.md           the check tool, line by line
docs/SCENE-PACKS.md       one-file scenes people can add; docs/PLAYLISTS.md  scene sets, order, links
docs/ARCHITECTURE.md      the engine in one page (only needed for engine work)
scenes/<key>/             one folder per scene: scene.glsl, helpers.js, entry.js, scene.json, README.md, thumb.jpg
scenes/_template/         a small complete commented scene: copy it (tools/new-scene.py does)
src/                      the engine in parts (manifest.json, shell-*.html, style.css, js/NN-name.js)
tools/                    new-scene.py, build.py / build.mjs, check-scene.mjs, pack.py, gallery.py, split.py
dist/                     built output (do not edit by hand)
```

## The five rules

1. **A scene lives in its own folder and nowhere else.** Never edit `src/` or another scene to make yours
   work. A scene never needs an engine change.
2. **Follow the contract exactly** (`docs/SCENE-CONTRACT.md`): the shader defines `void realm()`, contains no
   backtick and no `${`; all state in `V.c`; `rand()` never `Math.random()`; every top-level JavaScript name
   starts with the scene key; no NaN; divide your coordinates by `uZoom` and stay full and lit from zoom
   0.15 to 2.5; the base quality tier stays light, extras go under `#if HD>=1`.
3. **The music must be visible, and the scene must transform with it.** Bass, mids and highs each drive
   something different; something changes structure on `F.onImpact` / `F.onSection`; motion is smooth and
   on the beat.
4. **Look at what you made.** Run the check, open the contact sheet image, and judge it against
   `docs/ART-DIRECTION.md` (washout, one hue flooding, dark frames, speckle and sway are the usual
   failures). A passing check is not a good scene. Say honestly what is still weak.
5. **Original work only.** No copied shaders, no recreations of other people's art, characters or games.

## Commands (run from the repository root)

```
python tools/new-scene.py <key> "NAME" --author "..." --description "..."   # start from the template
node tools/build.mjs . dist/<key>.html --scenes <key>     # small build with one scene (or: python tools/build.py ...)
node tools/check-scene.mjs <key>                          # checks + check-out/<key>/sheet.jpg   (needs: npm install)
python tools/pack.py <key>                                # dist/scenes/<key>.scene.js, the shareable pack
node tools/build.mjs . dist/psychonautica-visualizer.html # the whole visualizer
python tools/gallery.py                                   # gallery/index.html from scenes/*/scene.json
```

Python 3.8+ or Node 18+ builds; the check needs Node 18+ and `npm install` (Playwright is the only
dependency). The key is 2 to 24 lowercase letters / digits, starting with a letter.

## The loop

1. Read `docs/MAKE-A-SCENE.md`, then `docs/SCENE-CONTRACT.md`. Look at `scenes/_template/` and at one or
   two built-in scenes near your idea (each has a `README.md`; small ones to read: `chroma`, `optik`, `sol`).
2. `new-scene.py`, build, run the check once before changing anything.
3. Write down the design (idea, scale, colour, music map, transformation, framing), then code in small steps.
4. Check, LOOK at `check-out/<key>/sheet.jpg`, fix, repeat. Compare the response numbers before and after
   each change: they must not fall.
5. Fill in `scene.json` and `README.md`, copy `check-out/<key>/thumb.jpg` into the scene folder, make the pack.
6. To contribute: one pull request adding one folder `scenes/<key>/` (`CONTRIBUTING.md`).

## Engine work

Only when asked for it. Read `docs/ARCHITECTURE.md`; edit the part in `src/js/`; rebuild; run the check on
several scenes of different kinds and watch a full Auto Show cycle. The single-file build must keep working
offline from a double click, with no dependencies.
