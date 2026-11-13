# BOXX 7 (`boxx`)

An endless dive through boxes. Each box stands in the middle of its own small world, and its door opens onto the next world at one tenth the scale: a castle at sunset, a neon city, a toadstool forest, a clockwork yard, a crystal valley under an aurora, a candy land, a moon base, a pagoda village, a desert of pyramids, Rubik towers, a circuit-board city, a basalt field in lava, a coral reef, a library of giant books, sky islands and a snow forest.

## How it moves with the music
- Kick: a hop and a ring of light run out through the world, and the height wave of the stacks steps half a turn, so rows that stood tall sink as their neighbours rise.
- Bass: the bassline swells and lifts every structure; builds lift the city further, breakdowns lower it.
- Mids: fill the windows and lanterns, like an equaliser spread over the whole city.
- Snare: stacks burst apart and settle again.
- Hats and highs: lids and flaps flip open, the avenue's chase lights step forward one place per hat, and stars, sparks and rims light up.
- Dive speed: about one world per four bars on the beat, faster when the music is loud, slower when it is quiet.
- Drops, strong arrivals and section changes: a drop crashes the camera through the next door and bursts everything wide; arrivals and section changes re-form the height wave into a new figure (rings, rows, columns or diagonals).

## Framings (Auto Show)
- far (`0.15`): the world sits as a plate in a city of boxes that runs to the horizon under its own sky.
- home (`0.4`): the world, its skyline and its sky.
- close (`0.9`): the fine work: windows, friezes and the details of the buildings.
- kaleidoscope: folds in about 15% of visits; best folds 12, 6; acceptable 16 and 1 (the left-right mirror). At 12 and 6 the special box becomes the centre of a mandala with the skyline as a ring. Unfolded is the main view.

## Cost
Medium (`cost: 1.6`). The shader is long and its compile on Windows (Direct3D) is fragile: small changes inside the outer march can make the base tier compile many times slower. More detail is gated behind the Native quality tier and above (`#if HD>=1`).

## Known weak points
- Every world's backdrop follows the same idea (a skyline of stacked boxes in the world's own material under its own sky), so the silhouettes repeat; the toadstool and snow worlds fit it least.
- The sky islands world is loud and busy in pink, orange and violet.
- Hats are the weakest band: they change only one or two percent of the frame.
- The circuit-board world is the darkest.
- The repaint on a section change was written but not seen landing on a real section change.
- Never hold very close (about 2.5): the view becomes a wall of the box face.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
