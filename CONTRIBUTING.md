# Contributing

After reading this you can get a scene into the collection, report a bug usefully, or propose an engine
change, and you know what a reviewer will look for.

Everyone is welcome here, with or without programming experience. Plenty of scenes in this project were
written by coding agents directed by a person with an idea and an eye. What counts is the result on screen.

## Contributing a scene

1. Make it: [docs/MAKE-A-SCENE.md](docs/MAKE-A-SCENE.md). Check it: `node tools/check-scene.mjs <key>`.
2. Open ONE pull request that adds ONE folder, `scenes/<key>/`, and nothing else:

   ```
   scenes/<key>/scene.glsl     the shader (JavaScript declaring the GLSL string)
   scenes/<key>/helpers.js     JavaScript helpers (may be empty)
   scenes/<key>/entry.js       the scene object
   scenes/<key>/scene.json     key, name, description, author, license, show, auto
   scenes/<key>/README.md      what it is, how it moves with the music, framings, known weak points
   scenes/<key>/thumb.jpg      the home framing (check-out/<key>/thumb.jpg from the check tool)
   ```

   Do not include `dist/`, `check-out/` or changes to `src/`. A scene never needs an engine change; if you
   think yours does, open an issue first.
3. In the pull request, attach or paste `check-out/<key>/sheet.jpg` and the check's printed result, and say
   what you think is still weak. Honest notes make review fast.
4. A maintainer reads the code (a scene is code that runs in people's browsers, so every scene is read),
   runs the check, watches it with music, and either merges, or asks for changes with reasons.

By contributing a scene you confirm that it is your own original work and that you license it under
`AGPL-3.0-or-later`, the licence of this repository (see [NOTICE.md](NOTICE.md)). Put that value in the
`license` field of `scene.json`.

### Scenes are original work

- No copied shaders (from shader-sharing sites, tutorials, other projects), even with changes. Common
  techniques are fine; someone else's composition is not.
- No recreations of other people's art, characters, logos, album covers, films or games.
- If a coding agent wrote it for you, you are still the one vouching that it is original. Ask it.
- Credit yourself however you like in `scene.json` (`author`); a handle is fine.

### What the reviewer checks

Technical (must pass):

- [ ] `node tools/check-scene.mjs <key>` passes: no shader or page errors, no black frames, no NaN.
- [ ] The pull request touches only `scenes/<key>/`.
- [ ] The code is readable enough to review, and does nothing but draw: no network requests, no storage, no
      DOM access, no `eval`, no timers, nothing outside the scene contract.
- [ ] Follows the hard rules in [docs/SCENE-CONTRACT.md](docs/SCENE-CONTRACT.md) section 13.
- [ ] Base tier is light: compiles in reasonable time on Windows, runs on a phone.

Artistic (the reason a scene is in the collection; see [docs/ART-DIRECTION.md](docs/ART-DIRECTION.md)):

- [ ] It is its own thing: not a variation of a scene already here.
- [ ] No washout, no single hue flooding the frame, no dark or empty frames, no speckle, at every zoom and
      in its folds.
- [ ] The music is visible: bass, mids and highs each drive something; something transforms on the drop.
- [ ] It moves like dancing, and it holds up over minutes of Auto Show.

A scene that is technically fine but not yet at the bar is not a rejection: share it as a scene pack in
Discussions, keep working on it, and come back.

## Sharing without a pull request

`python tools/pack.py <key>` writes `dist/scenes/<key>.scene.js`. Post it in
[Discussions](https://github.com/diddlysquatt/psychonautica-visualizer/discussions). Anyone can add it to
their visualizer. Nothing is reviewed there, so say what it is and who you are.

## Reporting a bug

Open an [issue](https://github.com/diddlysquatt/psychonautica-visualizer/issues) with: what you saw, what
you expected, the scene's name, your browser and device, and if you can a screenshot. For a scene that
fails to appear at all, the browser console's first error helps most.

## Changing the engine

Open an issue or a discussion first and describe the change. The engine must keep working from one file,
offline, with no dependencies, and existing scenes must look the same afterwards. Engine pull requests
edit `src/` only (never the built file), and say which scenes they were tested with.

## Conduct

Be kind. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
