# SWARM (`swarm`)

A murmuration of light. Tens of thousands of glowing dots form large three-dimensional sculptures (tori, knots, a galaxy, a helix, a lotus, a vortex, wave sheets, a dancing figure), alone or split into groups of bodies that orbit, weave and chase each other, in a universe of smaller swarms and ringed worlds.

## How it moves with the music
- Kick: the dots burst outward and bounce back on a spring, and the bodies swell with the sub and the kick.
- Bass: sub and bass breathe the whole figure; a carousel of bodies turns in steps on the beat, bigger steps when the bass is loud.
- Mids: drive the flow of dots through the figure and the ripples across it.
- Snare: sends a wave of colour through the swarm and scatters its members a little.
- Hats and highs: single pearls flash white and the star dust twinkles.
- Dances: one or two at a time (a lens punch on the kick, a spin step on the snare, a lean on the beat, a shiver on the hats, a swell, a ripple), chosen from running tallies of what this music is made of, so two songs do not get the same dance.
- Builds: tension draws the swarm in tight. Some builds are set pieces: a vortex that tightens and spins up, or a sapling that grows whorl by whorl.
- Impacts and drops: a strong arrival blows the sculpture into a cloud that re-forms as the next one, with a new choreography, palette and camera mode; a modest one bursts it and lets it fall back. The vortex bursts and the tree blossoms on the drop.
- Section changes: a new formation (and often a new sculpture), palette region and dance. Breakdowns pull the camera far back over the universe of swarms.

## Framings (Auto Show)
- far (`0.3`): the figure among the band of smaller swarms and the ringed worlds.
- home (`0.55`): the sculpture and its bodies, seen from a low camera.
- close (`1.2`): the bodies fill the frame and their dots read.
- kaleidoscope: folds in about 30% of visits; best folds 6, 8, 5; acceptable 4, 12. The mirrors and 16 are left out; the scene is unfolded most of the time, and the low looking-up view only exists unfolded.

## Cost
Heavy (`cost: 2.6`). Native quality and above (`#if HD>=1`) add denser figures on a finer lattice, a marched light ray per dot so the sculpture shades itself, more far swarms and extra star dust.

## Known weak points
- Breakdowns and morphs can leave a small figure in a mostly dark frame for a moment.
- The butterfly flock does not read as butterflies at home zoom, and the serpent reads only as coils.
- A ringed world often sits low in a corner of the frame.
- Very close up most beads are still plain.
- Sub, low-mid and snare respond less than before on some test seeds.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
