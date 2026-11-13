# VELVET (`velvet`)

A satin ribbon loom. Families of flat satin ribbons cross over and under each other in real weaves (plain, twill, basket, satin, herringbone and more), each ribbon with its sheen, ribs, embroidery and stitched edges. Over the loom runs a trellis of much broader ribbons that tie themselves, at every crossing, into figures of looped ribbon: bows, rosettes, roses, knots, braided wreaths, mandalas.

## How it moves with the music
- Kick: a ring of swelling ribbons runs out from the focal point in about one beat, the great ribbons light, and the loops of the figures breathe out and spring back.
- Sub and bass: the sub lifts the satin of the great ribbons; the low end turns the figure.
- Snare: the over/under order flips in a cascade that sweeps across the loom, and the loops get a tug.
- Mids: rows and columns slide in opposite directions, surging on every beat.
- Hats and highs: the glints re-roll on each hat, and the sheen, damask and sequins shimmer with the air band.
- Builds and breakdowns: a build races the sliding weave, opens the light and pulls every loop tight; a breakdown narrows the light to a spotlight on the focal point.
- Drops, arrivals and section changes: the loom is re-threaded with a new weave, palette and embroidery, each ribbon pulled out while the new one follows on its heels. On every other drop the whole loom swings to another setting (square, tilted, on the bias). A new section unties the figure and ties the next kind; an arrival snaps a flower open out of the knot.

## Framings (Auto Show)
- far (`0.22`): the whole trellis of tied figures on the woven ground.
- home (`0.42`): one figure whole in the middle, with runs of broad satin between it and its neighbours.
- close (`1`): the loops and stitches at full size, with their damask, embroidery and sequins; brief.
- kaleidoscope: folds in about 35% of visits; best folds 8, 6; acceptable 12, 5, 4. The folded picture is framed wider than home.

## Cost
Light per frame by its entry (`cost: 0.9`), but slow to compile on Windows (Direct3D): the first draw at the base tier took around twelve seconds on a busy machine, and over twenty at Native. The detail tiers (`#if HD>=1`) add traced light, thread and brocade levels, rows of seed pearls, a couched diamond lattice over the plain field and twisted cords.

## Known weak points
- Compile time on Direct3D is over the project's own guide; phones would wait longer for the first frame.
- Below about zoom 0.2 the figures become a repeat, like wallpaper.
- One hue family often holds most of the lit pixels in a frame.
- The weave travels with the mids; on mid-heavy music this may read as constant motion.
- Hats and air response are at the edge of what the dark ground allows.
- In the teal and silver palette a pale steel strand is the lightest thing in the frame; the wreath's free run through its centre reads as a dark bar close up.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
