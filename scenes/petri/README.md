# DIAT0M (`petri`)

A living psychedelic microscope slide. Darkfield microbiology drawn as superflat folk art: diatoms with ribbed cream frames and jewel chloroplasts, lace-lattice radiolarians with pin-tipped spines, ciliates fringed with beating hairs, chain colonies and star clusters, all cream-outlined over a deep stain ground. It comes as a drifting collage, an arranged Victorian slide of counter-rotating rings, or lanes of swimmers in a current.

## How it moves with the music
- Bass: membranes, nuclei and vacuoles breathe and swell with the bassline.
- Kick: colonies and contractile vacuoles contract, and the central rosette pumps.
- Snare: a wave sweeps outward from the centre and every organism steps one jewel colour.
- Mids: the cytoplasm and organelles stream, faster as the mids rise.
- Hats and highs: the cilia beat with the hats, and the radiolarian spines extend and sparkle with the highs.
- Vocals and leads: the presence band lights the outer panels of the wheels and extends the star pseudopods.
- Builds: the drift speeds up and the spines reach further.
- Drops and phrases: a new slide spreads from the centre behind a cream membrane front, and the cells just ahead of the front divide. Drops also re-stain the slide and often send a giant organism through or set off a bloom of cell division.

## Framings (Auto Show)
- far (`0.45`): giant organisms appear over the field of small ones, so the wide view keeps a hierarchy.
- home (`0.68`): the slide with its organisms at reading size.
- close (`1.15`): single organisms and their inner anatomy.
- kaleidoscope: folds in about 40% of visits; best folds 12, 8, 16; acceptable 6, 2 (the four-way mirror), 1 (the left-right mirror). When folded, the scene strongly prefers the arranged ring slide, the one that still reads as organisms.

## Cost
Medium (`cost: 1.3`). Native quality and above (`#if HD>=1`) add micro-anatomy: octaves of pores and fine striations that appear only when a cell is several pixels wide. The visible step is from High to Native; the tiers above mostly give cleaner edges.

## Known weak points
- The background water at Native is busy.
- In the current family, the giants float over the shoals without much spacing; small swimmers pass underneath.
- The kick is the weakest input; hats and air are weak at small sizes.
- Not tested on phones; compile times on Windows (Direct3D) varied a lot between runs.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
