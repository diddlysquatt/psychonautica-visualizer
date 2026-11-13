# DALA62 (`mandala`)

A fractal mandala. The camera dives along the boundary of a Mandelbrot-family set whose surroundings are leaded like stained glass: field lines, rings of panes, gems and rose windows. Now and then it pulls back to show a whole cathedral wall of medallions round the set.

## How it moves with the music
- Beat: the whole mandala turns a few degrees per beat and the rings stream outward with it.
- Bass: the set breathes (it grows sparser on the bass and condenses again), the scale swells a little, and the rings counter-rotate.
- Kick: steps the colour phase so the stripes slide, pumps the picture, and sends a ring of light through the bands; panes and jewels flash with it.
- Mids: keep the colour phase moving between kicks.
- Snare: launches a ripple from the set outward across the field lines and swings the light.
- Hats and highs: choose which satellite gems twinkle, and brighten the glints and the fine filaments.
- Spectrum: each band swells its own generations of gems.
- Breakdowns and builds: breakdowns always pull back to reveal the cathedral of medallions; builds close it back in.
- Drops: a cut, right on the beat, to a new stretch of the boundary, then a bloom outward from it.

## Framings (Auto Show)
- far (`0.4`): the set small among rings of panes and rose windows.
- home (`0.7`): the set with its near glass and field lines.
- close (`1.1`): the boundary itself, spiral by spiral.
- kaleidoscope: folds in about 50% of visits; best folds 6, 8 and 1 (the left-right mirror); acceptable 12, 5, 2 (the four-way mirror), 16. A fold centres the set as a jewel star, and the wall of medallions folds into full mandalas.

## Cost
Medium (`cost: 1.6`). Native quality and above (`#if HD>=1`) add painted linework on the glass, cabochon-cut petals and bosses that take the turning light, finer engraving and multi-sampling.

## Known weak points
- The wall of glass is dense: at small sizes a busy frame can read as pattern rather than as roses.
- Where the size of the panes changes, two lattices cross-fade and the roses double for a short stretch; on the higher-power sets the pane size jumps at each band edge.
- Views inside a slow basin follow polygon-shaped rings and are the least elegant.
- On a small canvas a basin can flatten to a plain field at Native.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
