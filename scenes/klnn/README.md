# KLNN (`klnn`)

A flight through a Kleinian fractal tiled into an endless lattice of curling naves and shafts. The stone is set with leaded glass, enamel tiles, neon tracery and necklaces of pearls, in curated jewel palettes; near bays stand in deep colour and far bays dissolve into a glowing atmosphere. Now and then the walls draw back into a great vaulted hall.

## How it moves with the music
- Beat: travel is counted in beats, about one junction of the lattice per bar.
- Bass: the fractal itself breathes. Sub and bass swell the big forms, the rims of the rose windows and the openings in the great discs (smoothed, so walls breathe rather than jump).
- Kick: lights the bezels and the coloured linework.
- Snare: flashes alternate panes of glass and tiles.
- Mids and highs: the mids drive the linework and light their own panes; highs and air set the glass glittering. Tiles and pearls read their own frequency bands and the live spectrum.
- Phrases: a new camera shot every four bars, a new palette every sixteen. Rare surprises: a vista (the walls draw back into the great hall for eight bars) or an eclipse (one bar where the stone goes dark and only the neon burns).
- Builds: the camera winds into a slow corkscrew, then settles upright again.
- Drops: the architecture transforms through a spring in under half a second, a new palette sweeps in from the vanishing point, and the walls may blast outward into the great hall or the lattice morphs into another family.
- Breakdowns: the hall opens slowly, a calm vast space; it slams shut on the drop.

## Framings (Auto Show)
- far (`0.45`): the widest view of the naves and shafts. Zooming out further by hand opens the great hall around the camera.
- home (`0.6`): the flight through the bays, with depth dissolving into the atmosphere.
- close (`1`): the scene's own default lens, closer to the tracery and glass.
- kaleidoscope: folds in about 50% of visits; best folds 6, 8, 12; acceptable 1 (the left-right mirror), 5, 16. Every fold from 3 to 16 makes a full mandala.

## Cost
Heavy (`cost: 2.4`). Native quality and above (`#if HD>=1`) add real shadow rays toward the far light, domed glass and enamel with moving highlights, smaller figures nested inside every figure, and at the top tiers a glossy reflection.

## Known weak points
- Zoomed far out, the walls become a mosaic of flat colour blocks rather than ornament, and a wall seen edge on turns to long streaks.
- A capsule of two sky tiles sits at the vanishing point from the default lens inward.
- The far ribbed flaps of two of the structure families are plain.
- The High setting is a little pinker and brighter than Native and above.
- Several bands respond less than they once did; the audio response was judged on stills and measurements, not in live motion.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
