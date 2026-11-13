# VOID 9 (`void9`)

An endless stained-glass cathedral, and you are an ant in it. Colossal naves run in a grid and meet at crossings; the blocks between them hold pier forests, light-wells, rotundas and rose-window walls. The cathedral is stacked in levels joined by lantern towers and wells, and its top level is a citadel of open courts under a psychedelic sky.

## How it moves with the music
- Beat: the camera passes one bay (one gilded arch) per beat. Every two bars it reaches a crossing and goes straight on, turns, climbs a lantern into the level above or dives a well into the level below.
- Spectrum: the clerestory windows play the mids, the tiny lamps of the galleries play the presence band, and each transverse arch carries an equaliser of lamps with bass at the floor and treble at the apex.
- Sub and bass: pour shafts of coloured light down through the windows.
- Kick and snare: each sends a wave of light along the nave.
- Hats and highs: sparkle the stars and jewels of the sky and the fine lamps.
- Builds: the route climbs and the light shafts thicken.
- Breakdowns: the route dives, and the stone goes half dark so that glass, lamps and shafts carry the picture.
- Drops: the glass changes, the shafts blaze, and the camera plays one of three moves in turn (a barrel roll, a sideways sweep, a rise to the vault).
- Phrases: a new camera shot every four bars and a new glass palette every eight; now and then a blackout nave, a storm of shafts, a rainbow cascade along the arches, or a flight out over the roofs.

## Framings (Auto Show)
- far (`0.2`): the camera rises above a cutaway of the building and tilts down, so most of the cathedral is in view.
- home (`0.5`): pulled back along the nave and up toward the vault, with a wider lens.
- close (`0.8`): near the scene's own ride down the nave.
- kaleidoscope: folds in about 30% of visits; best folds 1 (the left-right mirror) and 8; acceptable 2 (the four-way mirror), 6, 12.

## Cost
Heavy (`cost: 2.2`), with one of the longest shaders of the built-in scenes; first draw at the base tier on Windows (Direct3D) is near the project's limit and varies a lot. The shader has many blocks gated behind the higher tiers (`#if HD>=1`), including miniature ornament on the citadel's towers at the top tiers.

## Known weak points
- Warm palettes fill the frame with red and orange.
- The rose-window wall on a close pass at a snare is a large red field.
- The wide view over the citadel is busy from frame to frame.
- Compile time on Direct3D is near the limit and noisy.
- Camera clearance past the great keeps and the floating castles was reasoned from the geometry, not traced.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
