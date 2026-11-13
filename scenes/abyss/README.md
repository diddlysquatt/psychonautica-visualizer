# ABYSS (`abyss`)

A deep-sea scene: one leviathan jellyfish wider than the frame hangs over a spiralling court of smaller jellies, with a hero jelly, a neon octopus, comb jellies, lantern-fish schools and plankton in the water between. The camera lives in one of three depth zones: blue twilight, a lightless midnight, and a vent garden with coral and kelp.

## How it moves with the music
- Kick: every bell contracts, a ring of light spreads from the leviathan's crown and out through the court, and a pulse runs down its curtain of tentacles.
- Bass: a wave of bioluminescence rolls up through the water on each bass onset, and the garland colony pulses along its length.
- Snare: a wave of light rolls through the swarm from a random point, the fish school startles outward, and the octopus snaps to a new posture.
- Hats and highs: lights step along the tentacles, rim lights chase round every bell, half the court blinks with each hat, and the leviathan's curtain shimmers with the air band.
- Mids: tentacle and arm ripple speed follows the mids; the octopus skin ripples with them.
- Builds: the court's spiral arms wind tighter and brighten, and the fish gather into a fast spinning ball.
- Drops and section changes: a strong arrival plunges or lifts the camera to another depth zone, swapping creatures and palette in flight. A medium one bursts the court into a new figure and may put the lights out for a few bars. With no arrivals at all, a dive still comes after a long stretch in one zone.

## Framings (Auto Show)
- far (`0.2`): the whole leviathan, with the court under it and the floor below.
- home (`0.45`): the leviathan's vault spans the frame; the hero jelly and the octopus read at medium size.
- close (`0.95`): under the vault, among the near creatures; visited briefly.
- kaleidoscope: folds in about 50% of visits; best folds 8, 6, 12; acceptable 4 and 1 (the left-right mirror). At 6, 8 and 12 the leviathan's dome folds into a rose window. Folded pictures look best around home zoom; the Auto Show waits while a dive is in flight.

## Cost
Heavy (`cost: 2`). The shader is slow to compile on Windows (Direct3D): the first draw can take ten seconds or more. Frame cost at 720p is modest. Native quality and above (`#if HD>=1`) add finer tentacle curtains, more cell-net detail on the bells, far garlands, deeper field layers and marched water with light shafts.

## Known weak points
- The dive between zones is fast (the old creatures leave the frame in about half a second); it may read as a hard cut rather than a plunge.
- At a strong arrival the leviathan's vault brightens for about a third of a second and can still read as a flash.
- Builds are subtle at small sizes: the drop reads far more than the build-up.
- The midnight zone stays in one magenta / violet family for a whole chapter.
- The vent garden's floor is two repeated coral forms with kelp, the weakest zone close up.
- Very close zooms (about 2.5) are busy; compile time on Direct3D is over the project's own target.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
