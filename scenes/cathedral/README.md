# Elf (`cathedral`)

A flight through a self-similar gothic temple: naves, aisles and octagonal light shafts that repeat at one third the scale, level after level. A route director strings together processions down naves, spiral climbs round shafts, orbits of domed crossings, low passes over bridges and dives into a smaller copy of the temple. Six jewelled elves live in the rooms and greet the camera as it passes.

## How it moves with the music
- Beat: travel is locked to the beat clock, with a smooth forward surge on each beat; it runs faster through a build and after a drop, slower in breakdowns.
- Kick: the elves hop on every beat and land on the kick, their figures squash with it, and a wave of light runs along the seams of the stone.
- Snare: the elves throw their arms up and their greeting glints flare.
- Hats and highs: the elves' halos, bells and stars brighten, and the finest seams of the architecture light with the hats and the air band.
- Spectrum: the glowing seams read the live spectrum, so different levels of the stonework answer different frequencies.
- Builds: the lens narrows and the light beams in the shafts grow.
- Drops: a burst of speed down the nave, the lens opens wide, and the temple changes to a new jewel palette while the lamps flare in its colours.
- Quiet passages: the painted colour of the stone comes up as the lamps go down, so a breakdown shows a patchwork of coloured chapels rather than a dark nave.

## Framings (Auto Show)
- far (`0.3`): the camera pulls back and up from the route and the lens widens a little, showing more of the hall around it.
- home (`0.55`): the default view of the journey, with the elves in their rooms.
- close (`1`): the scene's own default lens, riding the route through the naves.
- kaleidoscope: folds in about 40% of visits; best folds 1 (the left-right mirror), 12, 8; acceptable 2 (the four-way mirror), 6, 4. Folded, the vaults read as stained-glass rose windows; unfolded keeps the journey and the elves.

## Cost
Heavy (`cost: 2.6`), among the most expensive built-in scenes. It is also slow to compile on Windows (Direct3D): the first draw can take well over ten seconds on a busy machine. Rose windows, the far wall of leaded panes and finer star ornament are Native quality and above (`#if HD>=1`); the bridges are modelled in depth only from the Cinema tier up and are painted below it.

## Known weak points
- The elves are flat figures facing the camera, shaded and layered but not modelled solids; at their usual small size the shading is subtle.
- Compile time on Direct3D is the main risk of this scene.
- Quiet passages are a strong look (bold patches of chapel colour); neighbouring bays can share a colour, so a big wall can be one colour for a while.
- The star that lights the floor on a kick is the same ornament everywhere, so a long flat floor reads as a repeated star.
- At the highest tiers on a small canvas the fine tracery turns to dense gold and blue speckle.
- Sub, bass, low-mid and presence respond less than the other bands.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
