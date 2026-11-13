# UMI POP (`umi`)

A superflat smiling ocean. Seven parallax layers of original kawaii sea characters (fish, octopi, pufferfish, starfish, bubbles) are packed edge to edge over a ground of Japanese wave pattern, all in crisp ink outline. The sea can be a drifting reef, lanes of schooling fish, a whirlpool circling an octopus-sun, or a rise where everything jets upward.

## How it moves with the music
- Singing: each size class sings its own band on vocal syllables. The front characters sing the lead, the next layer the harmony, the small ones the bassline, and the tiny carpet the air band.
- Beat: fish swim one stroke per beat, octopi jet on the beat, and starfish turn one notch per beat.
- Kick: the pufferfish inflate.
- Bass: the bassline breathes the schools at the back.
- Snare: a wave of colour sweeps out from the centre, every character stepping one palette colour.
- Hats: keep a field of sparkles alive through a hat pattern.
- Spectrum: in the whirlpool, the eight arms of the octopus-sun are the eight bands.
- Builds: everything swims faster.
- Drops and phrases: a new sea rolls in behind a wave front (a fast one on a drop), everything spins a full turn, and often the whole field flips like a stadium card stunt into one giant waving, singing octopus.

## Framings (Auto Show)
- far (`0.32`): schools of giant fish, themselves made of fish, swim by.
- home (`0.6`): the packed sea with the front characters' faces readable.
- close (`1.05`): the big front characters and the print on their bodies; this scene takes close-ups often.
- kaleidoscope: folds in about 20% of visits; best fold 12; acceptable 16 and 1 (the left-right mirror).

## Cost
Medium (`cost: 1.2`). Native quality and above (`#if HD>=1`) add finer layers of characters behind the seven, screentone and print ornament on every body, finer wave engraving on the ground, and several samples of the whole picture per pixel. First draw at Native takes around ten seconds on Windows (Direct3D).

## Known weak points
- Folded and pulled far back, a giant fish's eye can fold into a ring of big eyes with a plain, low-contrast centre.
- The giants' cream bands lay a light stripe over the characters under them, so a frame with several giants is a little pale.
- The giant octopus's head is still a crowd of characters rather than a drawn surface, and its arms are plain banded tubes.
- Very close up, big bodies are large flat shapes (which is the look, but nothing new resolves).
- Not watched in live playback.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
