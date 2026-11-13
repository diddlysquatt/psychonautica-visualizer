# OPTIK (`optik`)

Neon op-art on black paper: checkers that bulge into balls and pyramids, nested squares, stripe fields, zebra contours, moire, impossible cube tilings, twisted square tunnels and zigzag checkers. The flat pattern is bent by a stack of moving lenses, and beyond the frame by a vast field of smaller lenses, so the wall swells and sinks with the music.

## How it moves with the music
- Sub and bass: drive the big focal sphere at the centre of the picture.
- Mid bands: four satellite lenses, one each from low-mid to presence. A satellite swells out of the field as its band rises and sinks back when it is quiet; its thin rim rings in the band's colour on that band's onsets.
- Kick: a lens ripple leaves the focal sphere; up to three rings travel at once.
- Snare: a soft wave rolls out of the focal sphere; cells swell and eyes blink as it passes.
- Hats and highs: a fine paper pinstripe lights across the pattern, and the colour gains a little extra saturation with presence.
- Far field: each lens of the wall beyond the frame is tied to its own band.
- Drops and phrases: on a drop, and every sixteen bars, the picture irises out of the focal sphere (or flips tile by tile) into another illusion; between those it changes to another variant of the same one.

## Framings (Auto Show)
- far (`0.25`): an op-art wall of many lenses; zones and structure read, single illusions do not.
- home (`0.5`): the focal sphere and its satellites bending one illusion.
- close (`1`): the pattern near the focal sphere, line by line.
- kaleidoscope: folds in about 50% of visits; best folds 6, 12 and 1 (the left-right mirror); acceptable 16, 2 (the four-way mirror), 4.

## Cost
Light (`cost: 0.9`); in one frame-time measurement it cost about half as much as CHROMA, itself a light scene. The higher tiers (`#if HD>=1`) supersample and draw each ribbon with more ink lines; the visible difference between Native and the top tiers is modest.

## Known weak points
- Snare and hats are the weakest inputs; the cube tiling responds less than the other illusions.
- On the all-warm palette a loud passage is red-dominant when zoomed out.
- Zoomed far out the picture is dense.
- The hats' pinstripe is everywhere at once, and on two of the illusions it crosses the main lines as short dashes.
- Checked with a demo song and synthetic test signals only.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
