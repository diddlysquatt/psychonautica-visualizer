# TYK3S (`tykes`)

A tiling of interlocking clockwork elves, laughing. The figures fit together with no gaps, as towers of acrobats, strips of head-to-toe gnomes, or wheels of gnomes that mesh like gears. The pattern is nested: the clothes of each figure are printed with the next level down, and pulled back the figures turn out to be the masses of giants.

## How it moves with the music
- Kick: each kick is one of eight moves dealt to the visit. Either the mechanism ticks (hats swing, strips slide, wheels turn one figure round) or figures leave their tiles: neighbours leapfrog, roll or flip past each other, rows change places, pairs cartwheel along a strip. Every move starts and ends in a perfect fit.
- Bass: leans on the mechanism; strips creep and wheels turn while it sounds.
- Snare: starts a ring of laughter from one figure and feeds the general fit of laughter; on some visits the board does a somersault, one half and then the other.
- Mids: click the stripes of the clothes round.
- Hats and highs: step a small flourish and brighten the metal trim.
- Melody notes: a ring of laughter from a figure at the note's height.
- Laughter: louder music grows it from a grin to a giggle to a belly laugh to tears. Tension clamps the mouths shut with puffed cheeks and trembling outlines; an arrival sets everyone off at once.
- Impacts and drops: the rug gets pulled. A big arrival pulls back to show the tiling was the print on giants, or dives in, or folds the board like a paper fortune-teller into another family. A medium one swaps figure and ground, sends a wave of blocks or changes the colours.
- Section changes: the moves are dealt again and one family turns into another along a seam.

## Framings (Auto Show)
- far (`0.28`): giants made of elves, with heavy outlines and coloured masses of small figures.
- home (`0.6`): the characters, a few rows or wheels with their neighbours meshing.
- close (`0.9`): big characters with their tools, keys and faces; short, because further in the characters give way to the next level.
- kaleidoscope: folds in about 40% of visits; best folds 8, 6, 5; acceptable 12, 16, which the scene answers itself with rings of that many figures. The mirrors and low folds are left out because they cut faces in half. The Auto Show waits while a rug-pull is running.

## Cost
Medium (`cost: 1.4`). From Native quality up (`#if HD>=1`) the whole picture is sampled several times per pixel (3 at Native, more above), and the top three tiers draw a fourth level of figures. The base tier is at its compile limit on Windows (Direct3D), estimated at seven to eight seconds on an idle machine.

## Known weak points
- The scene is dense: at small sizes it reads as rich pattern, and as characters only from about 600 pixels wide.
- In the wheels family no figure ever leaves its tile, and a giant wheel's outline can show as a bare ring.
- A sliding move for the tower columns was designed but not built.
- Folded 12 or 16 times, whole figures per wedge appear only when the fold lines up with the ring; otherwise half figures are mirrored.
- The kick response measures lower than it used to.
- Every judgement was made from still frames, not from real-time playback.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
