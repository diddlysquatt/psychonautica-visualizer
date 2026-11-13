# KAMI 9 (`kami`)

A procession of origami animals. Folded-paper cranes, foxes, hares and doves travel along bands of patterned paper, among pennants, blossoms, stars and butterflies, in a flat cut-paper style.

## How it moves with the music
- Each animal has its own part: cranes ride the highs, foxes the mids, doves glide on the bass, and hares hop one bound per beat, as high as the strongest kick of that beat.
- Snare: a fold wave rolls along the bands; the animals fold shut and open again as it passes, and the blossoms pop a little larger.
- Spectrum: facets and ornaments of the paper read the live spectrum.
- Drops: a new route sweeps in behind a page-turn crease, the palette snaps, and the whole procession unfolds out of paper squares over about three beats, with a giant animal.
- Phrases: between drops the route changes behind a softer page turn, and occasional events pass through: confetti, a mandala of wheeling animals, a turnaround, a refold of everything into squares and back.

## Framings (Auto Show)
- far (`0.3`): the bands multiply and the animals stay readable.
- home (`0.6`): the procession across the frame.
- close (`0.95`): single animals and the paper ornament round them.
- kaleidoscope: folds in about 30% of visits; best folds 2 (the four-way mirror) and 1 (the left-right mirror); acceptable 6.

## Cost
Medium (`cost: 1.3`). Native quality and above (`#if HD>=1`) print traditional paper patterns on the bands and facets and add stitching; the step from High to Native is large, and the tiers above add cleaner lines and smoother shadows only.

## Known weak points
- A kaleidoscope fold that lands on the sky band is mostly one cyan with small pieces; it depends on which band crosses the centre.
- The snare is the weakest input.
- At Native, the bands with plain ring patterns look less finished than those with printed patterns.
- At the High setting the printed patterns on facets need a very close zoom, so they are rarely seen.
- Not tested on phones.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
