# CHROMA (`chroma`)

A scene where colour itself is the subject. One continuous plumage covers the frame: rows of overlapping plumes, each with a combed vane and an enamel eye, pouring out of whorls and round each other. The big picture is bands and pinwheels of pure colour; the small picture is the craft of each plume.

## How it moves with the music
- Kick: sends a swell wave through the plumes, steps every colour one place round the palette, and pours the rows one step along.
- Sub and bass: swell the light, open the gaps between plumes, and keep the rows pouring between kicks.
- Snare: flashes the eyes of alternate plumes.
- Mids: roll the colour along the rows and turn the raking light that the eye zones shimmer in.
- Hats and highs: fire the cores of the eyes and set glints running; each hat moves the glints on.
- Spectrum: every row of plumes is one band of the spectrum, and its eyes breathe with that band.
- Drops and phrases: a drop wipes in a new formation of whorls; without drops, every eight bars the palette turns or (less often) a new formation wipes in.

## Framings (Auto Show)
- far (`0.25`): many whorls at once; finer plumes grow in where the pattern stretches, so the field stays legible rather than turning to speckle.
- home (`0.6`): a whole whorl with its arms running off the frame.
- close (`1.1`): often a single arm of a whorl, plume by plume.
- kaleidoscope: folds in about 35% of visits; best folds 8, 6; acceptable 12, 16. Folds are strongest between zoom 0.6 and 1; the flow is the subject, so the scene stays unfolded most of the time.

## Cost
Light by its entry (`cost: 0.95`), though measurements put the base tier nearer the middle of the range. From the Native tier up (`#if HD>=1`) the whole picture is supersampled (4 samples at Native, more above), and the top three tiers walk more rows per pixel and cost roughly three times as much again; they are not real-time tiers.

## Known weak points
- The base tier's per-pixel cost is at the limit the project set for it.
- At High, Native and Cinema two swollen neighbouring plumes of one row can still meet on a straight line for a moment.
- Under busy treble the barbs show two-tone stripes; the chain layout with the shell tile is the busiest combination.
- The snare response is slightly weak when zoomed far out.
- A formation change passes through a soft yellow-green band with a few dark gaps near the whorl.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
