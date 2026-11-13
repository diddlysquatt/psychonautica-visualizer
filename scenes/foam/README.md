# The OAM (`foam`)

An endless dive through a self-similar foam of glassy bubble sheets. The walls carry rose-window medallions, lace, jewelled hearts with bezel rings, and lanterns hanging in the gaps; the camera threads those gaps down into ever smaller levels. Three related structures (foam, lattice, lace) grow out of one another during a visit.

## How it moves with the music
- Travel: the dive is locked to the music's pace through smoothed levels; it eases rather than lurching on each beat, and slows in breakdowns.
- Bass: the bezel ring round every heart and the lantern rings ride outward on the bass; the lanterns brighten with it.
- Kick: a thin ring runs from each heart to its rim, and the lanterns' rays lengthen.
- Snare: sends a shell of light out through the foam and strikes the bezel rings.
- Mids and highs: the bezels light with the hi-mids, mids and highs; medallions read the live spectrum by their generation.
- Builds: the route always dives, and the lens narrows on the gap being threaded.
- Drops: the lens springs wide, the palette snaps to the next curated one behind a white-hot front of light that sweeps out through the foam, and often a new structure grows out of the old one.
- Phrases: every sixteen bars a palette crossfades in behind a softer front; rare events come between (a blackout where only lines and lanterns burn, a chase of colour stepping on every kick, x-ray glass, a ring of floating lanterns, a sudden rise into a vast chamber).

## Framings (Auto Show)
- far (`0.3`): the eye pulls back but stays inside the architecture; more walls and windows in view.
- home (`0.5`): the dive between the sheets, with rose windows on the walls ahead.
- close (`0.8`): nearer the walls; lace and medallions large.
- kaleidoscope: folds in about 45% of visits; best folds 12, 8; acceptable 6, 16 and 1 (the left-right mirror). Folded, the walls become large rose windows.

## Cost
Heavy (`cost: 2.7`), the highest of the built-in scenes. Native quality and above (`#if HD>=1`) add a reflection bounce, marched shadows from the gap lanterns and soft shadow and occlusion from the camera lantern; the tiers above Native supersample.

## Known weak points
- Some passages are one warm hue from edge to edge (two of the palettes close to a big wall, and their kaleidoscopes).
- Mids and snare are the weakest inputs.
- Bubbles under about 30 pixels are plain, with no motif.
- The bezel rings make every disk a ring round a dot; walls of many small disks can read as rows of eyes.
- The contrast accents arrive as many small pieces and can read as confetti on a wall of small bubbles.
- Two palettes remain mostly blue-violet.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
