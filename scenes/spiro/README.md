# GUILL0 (`spiro`)

An uncut sheet of neon banknotes. Hundreds of crisp engraved lines form guilloche medallions, borders, friezes and bands on black paper; the hubs hold engraved emblems (a turning globe, a faceted star), microtext runs round the rims, and strips of holographic foil cross the notes.

## How it moves with the music
- Spectrum: eight bands drive the lobes of the rings, bass at the inside and treble at the outside; the crown of teeth round a medallion is a live equaliser, and each zone's light follows its own band.
- Kick: a ring of light and a slight bulge ride out from the hub, and the line weight swells.
- Snare: a counter-rotation jolt of the rings, with a flash on the engraving.
- Hats and highs: glints on the lines, and the foil strips shimmer.
- Vocals and leads: latent images hidden in the engraving (a star, discs, a quatrefoil, diamonds) surface when the vocal range stands out.
- Builds: the camera pushes in, the tiles tighten, and the rings flash on a pulse that subdivides as the build rises.
- Breakdowns: the camera pulls back over the sheet.
- Drops: a radial wipe into a new layout and palette, with the camera returning quickly. Every eight bars a new variation sweeps in.

## Framings (Auto Show)
- far (`0.35`): the sheet: notes of every layout in blocks of three by three between wide engraved bands.
- home (`0.5`): one note with the sheet showing at its edges.
- close (`0.95`): the medallion and its emblem, line by line.
- kaleidoscope: folds in about 50% of visits; best folds 8, 12, 4; acceptable 2 (the four-way mirror), 6, 16.

## Cost
Light (`cost: 1`). Line weights are held in display pixels, so a higher tier (`#if HD>=1`) adds new lines between the old ones rather than thickening them: finer pitches, more rings on the big medallions and a further hairline.

## Known weak points
- Very close up at the High setting the medallion zones are busy: crisp, but not calm.
- Where a band rosette sits on a crossing, its two halves meet along a visible diagonal.
- At the two highest tiers a faint red veil remains on the paper of medallion notes.
- On the plainest layout the tiers differ only by cleaner, finer lines.
- Zoomed far out on a small canvas the notes are too small to read and turn to speckle.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
