# ISOBAR (`flux`)

A living weather map printed like a screenprint. A scalar field (orbiting charges, liquid metaballs, rippling wave sources or a warped landscape) is cut into nested contour bands with crisp ink lines, foil index bands, stacked paper layers that cast shadows, and halftone shading. Around the music's own system lies a wider atlas of terrain and distant pressure systems.

## How it moves with the music
- Spectrum: each source owns one slice of the spectrum, from sub to air. It swells with its band and flashes its own rings on that band's onsets; the distant systems each pulse with one band too.
- Kick: a ring leaves the next source and ripples through the contours.
- Bass: swells the field as a whole (smoothed, so the contours never jitter).
- Snare: steps the colour plates and lights the ink stripes.
- Highs and hats: light and slide the nested hairlines; hi-mids sweep the foil sheen.
- Mids: alternate terraces of the fine inner maps pump with the mids.
- Phrases: every eight bars the sources regroup and a new composition glides in (full field, islands, a macro view of one source, strata under a dark sky, the atlas, a loupe or an inset map sheet). The palette changes every sixteen bars.
- Drops and breakdowns: a drop cuts to a focal composition on one source; breakdowns choose the calm, vast compositions.

## Framings (Auto Show)
- far (`0.28`): the sources inside the wider atlas of terrain and distant systems.
- home (`0.5`): the contour field of the music's own sources.
- close (`0.9`): bands wide enough to show their ornaments and the finer survey printed inside them.
- kaleidoscope: folds in about 50% of visits; best folds 6, 8, 12; acceptable 1 (the left-right mirror). Folded, the contours make flowers.

## Cost
Light (`cost: 0.9`). Native quality and above (`#if HD>=1`) add real content rather than only sharper lines: micro atlases printed inside the bands, foil that mirrors the sheet beside it, lit cut-paper walls, second-level engraving inside every ornament and longer shadow rays. Native costs several times the base tier per pixel.

## Known weak points
- The picture is dense with ink, and frame-to-frame change is higher than it used to be (not strobing in the frames watched).
- The palette change cross-fades through a brief grey instant when the two palettes are opposite in hue.
- Some macro views sit in one hue family (for example navy and blue bands at the blue end of a palette).
- On violet-on-blue palettes the islands and sea of the inner map are close in hue.
- Sub and bass response is a little lower than the other bands.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
