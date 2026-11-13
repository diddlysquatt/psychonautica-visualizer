# L1M1T (`hypr`)

Tilings of the hyperbolic plane in the style of Escher's "Circle Limit", set as jewels in a hyperbolic cathedral. Every large tile holds a round jewel that is the next tiling down, and every corner a rosette, so the picture is rose windows within rose windows. The tiles are filled with faceted stones, black opal, star sapphires, cloisonne enamel or agate.

## How it moves with the music
- Beat: the camera glides through the tiling at a speed counted in tiles per beat, surging just after every beat.
- Kick: a ring of light runs out through the generations of tiles; outlines, girdles and engraved settings flash with it.
- Snare: the colour classes cycle one step, in a wave running out from the centre.
- Hats and highs: set the jewels glittering, light the grout and the points of the stars, and brighten alternate shells of the stones.
- Spectrum: the rays of each star stone are as long as their frequency band is loud.
- Builds: the camera leans in, the travel accelerates, and the picture wipes to a finer tiling.
- Drops: a new tiling, motif and palette wipe in (sometimes a new view), with a rush of speed; the colour snaps rather than blends. Some drops dive straight into a jewel.
- Breakdowns: the travel floats, and the camera may pull far back into the cathedral.

## Framings (Auto Show)
- far (`0.5`): several levels at once: rose windows inside rose windows.
- home (`0.68`): the large tiling with its jewels and rosettes.
- close (`1.1`): single jewels and the tiling inside them.
- kaleidoscope: folds in about 45% of visits; best folds 6, 8; acceptable 4, 5 and 1 (the left-right mirror). Folded, the jewels form mandalas.

## Cost
Light (`cost: 0.9`). Native quality and above (`#if HD>=1`) add veins and finer wire on the petals, cast shadows of the wires, finer banding in the agate and more inclusions in the stones; the largest visible step is from High to Native.

## Known weak points
- Hats, and the kick on some of the tile fillings, respond weakly at the default zoom.
- Star sapphires are the softest filling: a glowing dome with a star, less crisp than the others.
- In the band view, enamel in stretched tiles becomes an ellipse.
- With the pastel palette and small mosaic panes the dome view is a pale frame.
- The black opal has faint seams between sectors.
- The same seed and time can give a slightly different camera position from run to run; the cause was not found.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
