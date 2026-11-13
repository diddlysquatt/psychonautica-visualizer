<!-- Adding a scene? Fill this in. Changing the engine or docs? Delete the checklist and describe the change. -->

## New scene: `<key>` (NAME)

What it is, in one or two sentences:

How it moves with the music (what bass, mids, highs, kick, snare do; what transforms on a drop or a new section):

What I think is still weak:

**Attach `check-out/<key>/sheet.jpg` and paste the printed result of `node tools/check-scene.mjs <key>` below.**

```
(check-scene output)
```

- [ ] This pull request adds only `scenes/<key>/` (scene.glsl, helpers.js, entry.js, scene.json, README.md, thumb.jpg)
- [ ] `node tools/check-scene.mjs <key>` passes, and I looked at the contact sheet at thumbnail size and at full size
- [ ] I watched it for several minutes with music and the Auto Show on
- [ ] The scene only draws: no network requests, storage, DOM access, timers or `eval`
- [ ] This scene is my own original work (no copied shaders, no recreations of other people's art), and I license it under AGPL-3.0-or-later, the licence of this repository
