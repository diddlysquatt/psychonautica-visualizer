# ESCHR (`eschr`)

A living temple city drawn as an isometric heightfield: terraces, ziggurats, a great screw, pistons, gates, needles, canals and bridges, with tiny robed walkers on the paving and stairs. Every stone column has its height driven by the music, and the monuments rebuild themselves as a wavefront crosses the city.

## How it moves with the music
- Bass and kick: the bass telescopes the tiers outward as a real ripple; rings open on the water with sub onsets, and the canals and the foot of every wall glow with the low end.
- Mids and snare: drive the pistons, the screw and the gates; every other tier and storey lights with the mids and the snare, trading places each beat.
- Highs and hats: raise the needles.
- Beat: stairs, screws, chaser lights and walkers all move on one stepped beat clock (a step in the first half of each beat, rest in the second), so the city walks rather than sways.
- Phrases: only part of the city performs at a time. Five dance figures, one per eight-bar phrase: waves crossing on a diagonal, soloists, call and answer on a chessboard of sites, and rings out of the middle of the view.
- Breakdowns and builds: breakdowns are still, and the tide can rise so the city stands in a lagoon; a build brings the whole city in gradually.
- Drops: everyone dances for two bars, the walkers stop and jump with their arms up, the palette changes and the tide runs out. Then, in turn, the city rebuilds in a ring out of the middle of the view, or it stands up taller and the camera turns down another street. With no drop for a long while, a calmer rebuild crosses on a diagonal.

## Framings (Auto Show)
- far (`0.22`): the endless city.
- home (`0.42`): a district of monuments, streets and canals.
- close (`1.5`): short visits among single monuments; the walkers are clear here and the second half of the crowd comes out.
- kaleidoscope: folds in about 25% of visits; best fold 1 (the left-right mirror); acceptable 2 (the four-way mirror). Other folds are left out; the kaleidoscope was not studied closely for this scene.

## Cost
Heavy (`cost: 2`). In one measurement it cost about ten times as much per frame as CHROMA (a light scene) at the same quality setting; most of that is edge supersampling and the sun-shadow walk. Low, Medium and High run the same shader at different render scales. Native quality and above (`#if HD>=1`) add a second, finer architecture on the columns (parapets, hipped roofs, finials, shrubs), reflections and moored boats.

## Known weak points
- Too slow on modest GPUs and phones without dropping to the Low setting.
- The sustained low end moves less than the kick, snare, mids, highs and hats do.
- In the obsidian palette the pink needle field can fill a close frame with one hue.
- At Native and above the moored boats on flooded streets read as dark posts with a hull.
- Compile time on Windows (Direct3D) is noticeable, especially at Native.
- Not checked on phones or in live playback by eye.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
