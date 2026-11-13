# KUB1K (`kubik`)

A city of hand-made cubes dancing in formation. Each cube has its own character (speakers, faces, lit windows, tiles, harlequin, dice, gems, basket weave, flowers) in lacquer palettes, one cube or pillar per cell of an endless grid. Nothing follows raw audio directly: every movement is a smooth function of a beat-locked clock, so the cubes dance rather than twitch.

## How it moves with the music
- Kick: the cubes hop, the two halves of the city taking turns, and each kick launches a ripple across the field.
- Snare: sends a wave along the rows and a ring of colour through the city.
- Hats: small pops and flips on a scattering of cubes and tiles.
- Spectrum: rows are mapped to frequency bands, so a bassline lifts the bass rows and hats lift the air rows; each band's onsets pop its own cubes.
- Routines: a new dance routine every four bars, faded out before it changes; breakdowns only hint at it.
- Builds: the skyline rises as towers grow, and the cubes float up and spin in a counter-rotating checker, settling on a quarter turn afterwards.
- Drops: a blast and a big change of formation, often into a showpiece (skyline towers, a cube cloud, a grand stepped pyramid), with a new mapping of the spectrum.

## Framings (Auto Show)
- far (`0.25`): the city wide; the kick ripples and the snare's ring of colour cross the whole field.
- home (`0.42`): the formation whole, cubes still readable as characters.
- close (`0.85`): the faces of single cubes and their painted detail.
- kaleidoscope: folds in about 70% of visits; best folds 2 (the four-way mirror) and 1 (the left-right mirror); acceptable 12, 6, 8. This scene is at its best mirrored, which is why it folds so often.

## Cost
Medium (`cost: 1.2`). From Native quality up (`#if HD>=1`) the cubes cast real shadows and occlusion through the same column walk the camera uses; reflections start at the Cinema tier.

## Known weak points
- Zoomed very far out the city is a colour field: the ripples read but no characters do.
- Reflections carry no painted art and only exist at the top tiers.
- Frame-to-frame flicker is no lower than in earlier builds.
- The snare colour ring was checked in stills, not judged in motion.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
