# Pitfalls: what breaks, what is slow, and what to do instead

After reading this you can write a shader that compiles quickly on every platform (Windows is the hard one),
stays fast, never produces a blank frame, and runs on a phone. Every item here was learned the hard way on
the built-in scenes.

## 1. The template string

The shader is text inside a JavaScript template string.

- A backtick anywhere in it (also in a comment) ends the string. `${` starts an interpolation. Either one
  breaks the whole page, not just your scene. `tools/check-scene.mjs` catches both.
- In a scene pack (`String.raw`), see `SCENE-PACKS.md` for how to escape them if you really need the characters.

## 2. Windows compiles your GLSL through Direct3D (ANGLE + fxc)

Chrome, Edge and Firefox on Windows translate GLSL to HLSL and compile it with Microsoft's `fxc`. It is
stricter than GLSL and much slower to compile, and it is where most people will run the visualizer.
A shader can pass on macOS, Linux and software rendering and still fail, or freeze the page for a minute, at
its first draw on Windows.

### Things that fail to compile

- `continue` inside a `switch`. Use `if / else`.
- `sign()` mixed with an int literal in a constructor: write `vec2(sign(x), 0.)`, not `vec2(sign(x), 0)`.
  Prefer float literals everywhere (`1.`, not `1`).
- WebGL1 names (`texture2D`, `gl_FragColor`, `varying`). This is GLSL ES 3.00.
- Loops without a constant upper bound, and `while` loops. Write
  `for (int i = 0; i < 32; i++) { if (float(i) >= n) break; ... }`.

### Things that compile, but slowly (seconds to minutes)

fxc inlines every function call and likes to unroll loops and flatten branches. Compile cost grows much
faster than code size (roughly the third power on one of the built-in scenes), so the shape of the code
matters more than its length.

| Pattern | Why it hurts | Do this instead |
|---|---|---|
| A big function called from many places | Every call site is a full inlined copy. 14 copies of one glyph routine once ran past four minutes and crashed the page. | Give each heavy function ONE call site: set up a "job" in variables, call once. |
| Arrays indexed by a loop variable or any run-time index | ANGLE turns `const` arrays into mutable static arrays; indexed reads become slow, branchy code. | Pack small tables into `vec4` / `mat4` constants and select with masks (`dot(table, step(abs(vec4(0.,1.,2.,3.) - i), vec4(.5)))`), or decode from one packed number with arithmetic. |
| Long `?:` chains, `&&` / `||` chains, `else if` ladders | ANGLE turns each `?:` into an if / else block; nested ones multiply. | Select with arithmetic: `mix(a, b, step(...))`, masks of 0 and 1. Keep flat, separate `if`s on region masks. |
| Nesting (ifs in loops in ifs), early `return`s in the middle of a function | Each level multiplies the work of the flattener. | One exit per function. Flat code. |
| A loop around a large body | fxc tries to unroll it. | Keep loop bodies small; move the big work out of the loop; make the bound depend on a uniform so it cannot be unrolled (`uDetail` in the break test). |
| Wrapping straight-line code in a one-pass loop "to share it" | Measured 1.7x to 4x slower to compile. | Leave straight-line code straight. |
| No `if` at all around heavy calls (everything evaluated, then masked) | fxc then optimises one giant expression: one scene ran past 300 s this way. | Keep a plain `if` around each big block. |
| `fwidth()` / `dFdx()` inside loops or branches | Derivatives force the compiler to flatten the control flow around them. | Compute the pixel footprint analytically (`1. / (uRes.y * uZoom)` scaled by your mapping) or take derivatives once, outside. |

What is cheap: straight-line arithmetic. A long run of `mix`, `step`, `smoothstep`, `dot` costs almost
nothing to compile.

Rules of thumb that held across thirty scenes:

- Measure compile time back to back against a known scene on the same machine (it varies a lot with load):
  `node tools/check-scene.mjs <key> --gl hardware` on Windows prints the first-draw time.
- Budgets for the first draw on Direct3D 11: about 8 s at `HD 0` (phones compile this tier too), 20 s at
  `HD 1`, 45 s at `HD 5`. Under 3 s is normal for a flat scene.
- Put what is truly large under `#if HD>=1`: it then costs the base tier nothing.
- Tried on built-in scenes and found slower or no better: dispatch through a `switch`, loop hints, "opaque"
  loop bounds, precomputed arrays of words, `switch`-based palette tables. Results differ from shader to
  shader, so measure your own change rather than trusting a rule blindly.

## 3. Frame cost

- The base tier must hold 60 fps at 1080p on a mid-range desktop GPU and stay usable on a phone. The engine
  lowers resolution (and then `uDetail`) when a scene is slow, which blurs YOUR scene, so cost is a visual
  problem, not just a technical one.
- During a crossfade two scenes render at once. A scene that only just fits will stutter on arrival.
- Ray marching: bound the step count, scale it with `uDetail`, exit early, and take fewer steps where the
  pixel footprint is large (far away, zoomed out).
- Level of detail by pixel footprint everywhere: when a feature is smaller than about a pixel, stop
  computing it and use its average colour. This is both the speed fix and the anti-speckle fix.
- Texture reads: there is only `uSpec` (256 x 2). Reading it per pixel a few times is fine; in a loop it adds up.

## 4. NaN, Infinity and black frames

One non-finite number anywhere in a pixel's colour can blank that pixel, and through the feedback and bloom
passes, large parts of the frame. Typical sources:

- `log(0.)`, `1. / 0.`, `sqrt()` or `pow()` of a slightly negative number (`sqrt(max(x, 0.))`,
  `pow(max(x, 0.), k)`), `normalize(vec3(0.))`, `atan(0., 0.)`, `mod(x, 0.)`, `acos` / `asin` outside -1..1.
- A sheen or specular term that overflows: `pow(x, 200.)` of something above 1, `exp()` of a large number.
- JavaScript: dividing by `dt` (it is 0 in the warm-up call), by `F.bpm` before the tempo is known (it is 0),
  reading `F.somethingS` in the warm-up call (`undefined` becomes `NaN` in arithmetic), an accumulator that
  grows without bound until `sin()` of it loses precision.
- A scene that is fine with a beat can still produce a bad number in silence, or before tempo lock. Test both
  (the check tool's run starts quiet).

Keep big numbers small: wrap phases and travel distances with a modulo in `frame()`; a visualizer runs for hours.

Black that is not NaN: an auto-exposure `fb.key` that is too low for a dark scene; a scene that is empty at
some zoom or some seed; a transformation that passes through an empty state (close the petals, do not delete
them). The project's rule: no dark passages, ever.

## 5. Washout (the most common reason a scene is sent back)

- Additive stacks of light sum toward white. Composite detail OVER ink instead of adding; cap by scaling the
  whole colour vector (keeps the hue), never by clamping each channel (turns everything pale).
- Remember what comes after your shader: trails (`fb.decay`, `fb.echo`) and bloom add light. A scene that
  looks right raw can wash out on screen. Lower `fb.echo`, `fb.decay`, `fb.live`, and `fx.bloom` in the
  `auto` row before you dim the scene itself.
- If you need more light, raise the light sources. Never scale the final colour under a cap: that flattens the
  audio response.
- Judge loud passages, not one calm frame. The check tool reports the share of pale and of dark pixels.

## 6. Aliasing, speckle, "texture"

- Anything periodic that shrinks with distance or zoom (grids, rings, fractal detail) becomes noise once it
  is finer than a pixel. Fade it out by footprint. Zoomed-out views (0.15, 0.4) are where this shows.
- Thin lines need analytic anti-aliasing: `smoothstep(w + px, w - px, d)` with `px` the pixel size in the same
  units as `d`.
- A field of small identical marks reads as texture, not as a scene. Design ornament at several scales.

## 7. Phones

- Mobile GPUs compile slowly (sometimes on the page's thread: the page freezes while your shader compiles)
  and have less fill rate. The base tier is all they ever get.
- Some mobile drivers are fragile with integer bit tricks, large loops and deep expression trees. Simple
  float maths is the safe path.
- Precision: `highp` is on, but keep coordinates within a few thousand units; do not rely on exact float
  equality; hashes on huge inputs repeat visibly.
- Test with `?mobile=1` in the address bar (forces the phone defaults on a desktop browser).

## 8. Scope and state

- All scenes and the engine share one JavaScript scope. A helper called `rng` or `palette` will collide with
  another scene's or the engine's. Prefix every top-level name with your key.
- `frame()` runs for several visits of your scene at once. Module-level state will be shared between them and
  the scene will fight itself during a crossfade. Keep state in `V.c`.
- `Math.random()` makes a scene unreproducible in tests and offline video renders. Use `rand()`.
