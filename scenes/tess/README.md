# TESS4 (`tess`)

Neon line art of four-dimensional shapes: the tesseract, the 16-cell, the 24-cell, the 5-cell, duoprisms and linked great circles. They turn in four dimensions and are projected down to the screen as crisp glowing wireframes, nested in shells, standing as a hero with satellites, scrolling in a grid, or rushing past in a fly-through. Behind them stands a colossal lattice of giant polytopes.

## How it moves with the music
- Bass: drives the speed of the 4D rotation and breathes the 4D perspective, so the inner cell swells through the outer one.
- Kick: a smoothed rotation impulse, alternating between two rotation planes, plus a body pulse and shockwaves of light.
- Snare: a flash front sweeps across the 4D body from a random direction.
- Mids: each family of edges lights with its own mid band.
- Hats and highs: vertices throw crisp sparks on high and air onsets, and the beads of the light trains swell with the hats.
- Spectrum: in the grid formation each column is a frequency; a spectrum ring sits in the background.
- Beat: the nest grows one shell every two beats (faster in builds), and the grid scrolls half a cell per beat.
- Builds and breakdowns: builds accelerate the rotation and push in a touch; breakdowns calm it and pull the view back so the colossal lattice comes into view.
- Drops: the shape explodes (half the time into a cloud of vertex sparks) and the formation, polytopes, palette and rotation planes all change. Rotation planes also change on phrases.

## Framings (Auto Show)
- far (`0.3`): the colossal lattice of giant polytopes behind the figure, with light trains on its edges.
- home (`0.5`): the formation whole.
- close (`0.9`): the hero polytope and its edge detail.
- kaleidoscope: folds in about 55% of visits; best folds 6, 8, 12; acceptable 16, 1 (the left-right mirror), 2 (the four-way mirror).

## Cost
Heavy (`cost: 2`). The higher tiers (`#if HD>=1`) draw extra instances with the same loop: a nest of thin companion polytopes round the hero, further constellation polytopes, and finer copies of the shapes.

## Known weak points
- At Native and above the hero's interior is a dense web of companions and strings; it is cleaner at the High setting.
- The grid formation zoomed out is a busy crossing of wireframes with little hierarchy.
- The stained-glass rings behind the lines are bold; at loud mids a lit band is a strong shape.
- The background cells are irregular polygons, so a single cell looks like a shard.
- Bass, mids and kick change less of the frame's area than they once did; silence is fairly dark.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
