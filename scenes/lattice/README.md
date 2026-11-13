# LED 06 (`lattice`)

A flight through a hyperbolic honeycomb. The edges of the cells are LED tubes, the corners are bulbs, and the faces are stained-glass membranes that carry their own smaller tilings. The cells shrink toward a sphere at infinity, an endless regress in every direction, and the flight never ends.

## How it moves with the music
- Kick: the flight surges forward, and a ripple of light restarts from the kick and runs outward along the tubes.
- Snare: flashes the lines of the membranes and the hub bulbs.
- Hats and highs: twinkle the diodes and brighten the ornament in the glass.
- Spectrum: the LED matrices on the membranes read the live spectrum, and each of four band pairs fires its own lights on its onsets.
- Bars: a twist about the line of sight on every other bar, alternating sides, as an impulse that eases away rather than a steady spin.
- Builds: every diode becomes an equaliser, the ripples run faster and the membranes thicken.
- Drops: the membranes thin out so the view bursts open, with a bigger twist; about half the drops reboot the honeycomb into a new one.

## Framings (Auto Show)
- far, home and close are all `0.55`: the Auto Show never zooms this scene. It flies itself along a rail that threads the open cells.
- kaleidoscope: folds in about 25% of visits; best folds 6, 12; acceptable 1 (the left-right mirror), 2 (the four-way mirror), 8. Folded, the starburst corners become star mandalas; unfolded is the main look.

## Cost
Heavy (`cost: 2.4`). Native quality and above (`#if HD>=1`) add more remembered membranes, a nested micro lattice of diodes in every tile and a marched reflection bounce; from the Cinema tier the foam at the sphere at infinity resolves into diodes.

## Known weak points
- A kaleidoscope fold at the default zoom can land on a patch of plain near glass or open-cell light and leave a mostly empty frame.
- The ring of ticks round the largest jewels (a spectrum iris) is a visible addition to an otherwise settled look.
- Folded and zoomed far out, the nebula filaments are large and brighter than intended.
- The globes are simple: a diode grid on a dark ball.
- The reboot and the set pieces were not filmed with the newest elements on screen.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
