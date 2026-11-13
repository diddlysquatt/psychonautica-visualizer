# BOOMB0X (`merc`)

A superflat kawaii sound system. A wall of ink-outlined characters that are the hi-fi itself: speaker cabinets with faces on their dust caps, cassettes whose reels are eyes, spinning records with smiling labels, boomboxes with a live spectrum display, VU amps and hopping music notes. Every object plays one frequency band, so the whole wall is a giant level meter.

## How it moves with the music
- Spectrum: each character lights and moves with its own band (bass on the left and air on the right in the wall; inner rings, rows or spokes in the other formations). Needles, knobs and spectrum displays read the live levels.
- Beat: columns or rows step on the beat.
- Kick: a shockwave ring runs out across the wall and the bass speakers bounce.
- Snare: everyone hops, a flash travels through the wall, the records scratch, and on every other snare a colour step sweeps outward from the centre.
- Hats: the tweeters pop.
- Vocals: the characters' mouths sing.
- Builds: every row scrolls further and faster.
- Drops: a new formation bursts in (wall, parade, counter-rotating rings round a giant woofer face, or an endless tunnel) with a new palette and a flash; often a giant boombox or a stadium wave follows.

## Framings (Auto Show)
- far (`0.25`): the tile backgrounds join into one giant mosaic picture (a smiling face, a bullseye, a heart or a sunburst).
- home (`0.45`): the wall of characters, each readable.
- close (`0.8`): single characters and their working parts.
- kaleidoscope: folds in about 30% of visits; best folds 12, 8; acceptable 6 and 1 (the left-right mirror).

## Cost
Medium by its entry (`cost: 1.1`), and cheap per frame: it is a flat 2D drawing. Native quality and above (`#if HD>=1`) add a pebbled covering on the cabinets, small badges riveted over the seams between characters, and several samples per pixel. At those tiers the shader is slow to compile on Windows (Direct3D), sometimes over twenty seconds on a busy machine.

## Known weak points
- The higher tiers are crisper rather than visibly richer.
- The ring meters exist in the rings formation only; wall, parade and tunnel have the chase and the snare flash but no meter chain.
- At Native the badges give a wall of small tiles a regular dot rhythm.
- White keys, pads and lamp glints raise the share of pale pixels; no washed frame was seen, but it is the number to watch.
- The newer working parts were judged on still sequences, not in motion.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
