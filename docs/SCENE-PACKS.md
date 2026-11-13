# Scene packs

After reading this you can turn a scene into ONE file that anyone can add to their visualizer, add someone
else's scene to yours, and write a pack by hand or by script.

## What a pack is

A text file named `<key>.scene.js` holding one call: `HyperVisualizer.registerScene({ ... })`. It carries
everything a scene folder holds: the shader, the helpers, the scene object, the two Auto Show rows, and who
made it.

**A scene pack is code.** It runs inside the visualizer page with the page's full rights. Only add packs
from a source you trust. The app says so before it adds one. This is also why scenes in the repository are
contributed by pull request: every one is read by a reviewer.

## Add a pack to your visualizer

Controls > Scenes > Edit > "+ Scene", choose the `.scene.js` file (or drop the file on the page). The app
shows the name, author, licence and description, and the warning above, before it runs anything. Then it
compiles the scene first in line; if the shader fails or a field is missing you get a readable error and
nothing is added. An added scene is stored in that browser (IndexedDB) and is there again next time; the
× on its row removes it. If its key is the key of a built-in scene, the app asks whether to replace the
built-in in this browser (removing the pack brings the built-in back).

## Make a pack from a scene folder

```
python tools/pack.py aurora                      # writes dist/scenes/aurora.scene.js
python tools/pack.py aurora my.scene.js --author "your name" --license "AGPL-3.0-or-later"
node tools/check-scene.mjs dist/scenes/aurora.scene.js
```

Author and licence default to the values in `scenes/aurora/scene.json`.

## The format

```js
HyperVisualizer.registerScene({
  format: 1,
  key: 'aurora',
  name: 'AURORA',
  author: 'Your name',
  license: 'AGPL-3.0-or-later',
  description: 'curtains of light that lean into the bass',
  glsl: String.raw`
void realm(){ vec2 p=scr()/uZoom; fragColor=vec4(pal(length(p)+uTime*.1)*(.2+uKick),0.); }
`,
  helpers: String.raw`
function auroraInit(seed){ return { t: seed[0] * 10 }; }
`,
  entry: String.raw`{
  cost: 1, cont: [], syms: [0, 6, 8],
  fb: { zoom: 0, rot: 0, decay: .2, warp: 0, echo: .04, droste: 0, win: 0, key: .08 },
  init(seed) { return auroraInit(seed); },
  frame(V, F, dt) { const c = V.c; c.t += dt * (.3 + F.bass); V.p1 = [c.t, F.kick, 0, 0]; }
}`,
  show: { z: [.35, .6, 1], c: .35, w: .55, k: { p: .4, s: [6, 8], o: [12], z: .9 } },
  auto: { tier: 3, kind: 'flat', kal: [0, 6, 8], bars: 32, tr: ['melt', 'leak'], fx: {} }
});
```

| Field | Required | Meaning |
|---|---|---|
| `format` | yes | `1` |
| `key` | yes | 2 to 24 lowercase letters / digits, starting with a letter. The scene's identity: file name, playlists, links, storage. |
| `name` | yes | The name shown in the menu (1 to 40 characters). |
| `author` | no | Shown before the scene is added. |
| `license` | no | Shown before the scene is added. Scenes in this repository use `AGPL-3.0-or-later`. |
| `description` | no | One line: shown before adding and as the tooltip. |
| `glsl` | yes | The shader text: what is between the backticks in `scene.glsl`. Must define `void realm()`. |
| `helpers` | no | JavaScript source: the contents of `helpers.js`. May be empty. |
| `entry` | yes | JavaScript source of ONE object literal: the contents of `entry.js`. A trailing comma is allowed. |
| `show` | no | The scene's framing and fold row, as a real JavaScript object (it may hold the functions `hold` and `k.ok`). |
| `auto` | no | The scene's running-order and effect row. |

Rules:

- The six metadata fields (`format` to `description`) come first, in this order, each a plain quoted string
  (no template literal, no concatenation). The app reads them WITHOUT running the file.
- `glsl`, `helpers` and `entry` are strings of source code, written as `String.raw` template literals so
  that backslashes stay as typed. Inside one, write a backtick as `${'`'}` and the two characters `${` as
  `${'$'}{`. (`tools/pack.py` does this for you. A plain JSON string literal is equally valid.)
- The engine evaluates the pack inside its own scope, once:

  ```js
  const R = (function (GLSL) {
    <helpers>
    return [ <entry> ][0];
  })(def.glsl);
  ```

  So `helpers` and `entry` see exactly what a built-in scene sees (`rand`, `pick`, `ease`, `clamp`, `S`,
  `BANDS`, `F` ...: `SCENE-CONTRACT.md` section 5), names declared in `helpers` are private to the pack, and
  the shader text is available as the constant `GLSL`.
- `entry.src` may be left out (the engine uses `glsl`). `entry.key`, if present, must equal `key`. The
  pack's `name` and `description` win over the entry's. Missing `fb`, `syms`, `cont`, `cost` get defaults.
- A NEW scene has no rows in the engine's per-scene tables, so it sets its own tuning in its entry when it
  needs any: `react`, `fb.live`, `motionLP`, `evolves` (`SCENE-CONTRACT.md` section 4).
- The shader is compiled exactly like a built-in scene's, once per quality tier in use. The compile check at
  "Add scene" runs at the current tier only: test your `#if HD>=1` branches yourself
  (`node tools/check-scene.mjs` builds the base tier; open the build and choose Resolution: Native).

## From a script

`HyperVisualizer.registerScene(def, options)` returns a Promise.

- It resolves with `{ key, name, index }` once the scene has compiled and joined the scene list and the
  rotation. Called before the visualizer has been started, it resolves after the start.
- It rejects with an `Error` whose `message` is readable, and adds nothing, when: a required field is
  missing or has the wrong type; `format` is not 1; the key is malformed; `helpers` or `entry` do not parse;
  `entry` has no `init` / `frame`; the shader does not compile or link (the message quotes the compiler's
  first errors, with line numbers counted in `glsl`); `init` or the first `frame` throws.
- `options.replace: true` allows the key of a built-in scene. `options.persist: true` stores the pack in
  this browser. `options.verify: false` skips the compile check.
- Also: `HyperVisualizer.addSceneText(text, options)` (takes the text of a pack file),
  `HyperVisualizer.removeScene(key)`, `HyperVisualizer.scenes` (the list with `key, name, on, added, author,
  license, description, index`), `HyperVisualizer.scenesRestored` (a Promise: stored packs are registered).

## Older packs

Files named `.realm.js` (a `// @realm-pack {json}` header line followed by the three marker regions) are
the previous format. They still load through the same "+ Scene" button. New packs should use format 1.
