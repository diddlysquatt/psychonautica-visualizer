# MUMM3 (`gate`)

An endless funnel of neon chrysanthemum crowns, the heart of one colossal flower. Each crown is a ring of petals; crowns are stacked down the throat with parallax and depth fog, and every petal holds a rosette of smaller petals round its eye. Pull back and the flower's corolla keeps going outward.

## How it moves with the music
- Beat: one new crown rises out of the glowing core per beat.
- Kick: nudges every crown and sends a swell out through the corolla, four rings to the beat.
- Snare: lights one crown in four, jumps the spiral arms a third of a turn, and turns the corolla's rings a notch.
- Spectrum: mapped by radius, a concentric equaliser with bass at the rim and treble at the core.
- Hats and highs: sparkle the pollen light in the throat.
- Builds: the spiral arms race.
- Drops: the whole flower blooms open behind a shockwave, the corolla jumps one ring outward, and the flower moves to a contrasting colour family within about a beat.

## Framings (Auto Show)
- far (`0.2`): the size of the flower reads here: the heart small at the centre of a corolla that keeps going.
- home (`0.85`): the funnel of crowns, the scene's signature view.
- close (`1.4`): leaning into the throat and the nearest petals.
- kaleidoscope: folds in about 35% of visits; best folds 6, 8, 12; acceptable 5, 16 and 1 (the left-right mirror). Unfolded stays the most common view.

## Cost
Medium (`cost: 1.4`). Everything in the detail tiers is Native quality and above (`#if HD>=1`), none of it compiled at the base tier: engraved relief on every petal, cast shadows from the crowns above, a mirror bounce in the lacquer, gold cloisonne lines and more layers of pollen light in the throat.

## Known weak points
- The snare turn moves most of a pulled-back frame at once and may read as busy.
- Corolla petals are all one outline and one count per visit; there is no second, larger tier further out.
- At Native and above a pulled-back frame is dense and bright with few true blacks, less "neon on black" than the High setting.
- The swell, the snare turn and the drop jump were judged from still frames, not watched live with sound.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
