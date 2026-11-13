# KN0TT (`knott`)

Living neon knotwork. Glowing tube bands weave over and under each other on square, triangle and hexagon lattices, at several scales at once: small tiles nest inside larger ones, and a giant knot made of the small weave runs through the whole picture. Round medallions frame parts of it.

## How it moves with the music
- Beat: each beat a wave of tiles turns a quarter, one group sweeping across the screen, so the knot keeps re-routing itself.
- Kick: pulses the thickness of the bands, surges the light flowing along them, and sends comets along the giant strands.
- Bass: breathes the zoom and lights the giant knot with the bassline.
- Snare: adds cascades of turning tiles and flashes the rails; over and under swap on the hit.
- Mids and vocal range: ripple echo waves off the strands and make the crossings glow.
- Hats and highs: light the beads racing along the cores as a steady glitter.
- Builds: pull back to many smaller, thinner, hotter knots, and the medallions close.
- Drops: spring back to big bold tiles in a hue-contrasting palette. Odd drops switch the tiling family behind a radial wipe, even drops re-space the medallions; every drop wipes in a new band look (neon tube, Celtic ribbon, rope braid or chain) and re-routes the giant knot.

## Framings (Auto Show)
- far (`0.2`): the giant knot shows as a woven tube of the small weave, with medallions across the field.
- home (`0.38`): dense knotwork at several scales.
- close (`0.65`): the bands large enough to show their strands, studs and fittings.
- kaleidoscope: folds in about 45% of visits; best folds 8, 12; acceptable 2 (the four-way mirror), 1 (the left-right mirror), 16. Every fold stays full of knotwork.

## Cost
Medium (`cost: 1.2`). Native quality and above (`#if HD>=1`) add fibre lines and a specular crest on each strand, yarns wound round the cords, an inlaid pinstripe down each band, tiny knots woven through the dark gaps (one more level per tier) and finer facets on the bosses.

## Known weak points
- Snare and low-mid response are low at the default zoom.
- The chain look is the plainest close up; the rope's strand pattern breaks at tile joints when very close.
- The inside of the giant band is the softest part of the picture at far zooms.
- A medallion can land on a low-contrast knot and read as a plain disc.
- On triangle lattices the flow has no single direction, so comets meet head-on at some joints.
- The plaited panels need a 1080p screen or larger to show.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
