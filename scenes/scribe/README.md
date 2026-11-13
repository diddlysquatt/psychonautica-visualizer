# GL1PH (`scribe`)

An illuminated manuscript in a script nobody can read, written stroke by stroke by the music. A wall of open books of dark vellum, each page ruled with text lines in gold and pigment, a giant initial on a tooled panel, a headline, glosses in a small hand, an interlace border and a colophon. Nothing is displayed ready-made: every stroke is drawn by a broad nib whose bright edge you can see moving, and a page is rewritten pass after pass.

## How it moves with the music
- Kick and bass: the big hand writes the headline, one stroke per kick, and redraws the giant initial; the bass pushes it on. On every kick the books dance: each tips the other way from its neighbours, or hops, or a swell runs out from the book being written.
- Mids: the main hand writes the text, a burst of letters on every beat and more when the music is loud. A line ends on the bar line and the rest of it gets a line-filler.
- Hats and highs: the small hand writes the gloss, in runs on the hats; the highs light the vines and the gold points.
- Builds: more letters per beat as tension rises.
- Impacts: gold floods the strokes; a strong one also brings a new initial, and a real drop re-inks the whole wall and sends the camera to another book.
- Section changes: the page turns. A new script, layout, palette or border spreads out from the initial. A finished page turns too, keeping its script until the section changes.

## Framings (Auto Show)
- far (`0.2`): the dancing wall of books.
- home (`0.6`): one open book, with the edges of its neighbours.
- close (`1.4`): the pen at work; the camera follows it along the line.
- kaleidoscope: folds in about 40% of visits; best folds 8, 6, 12; acceptable 2 (the four-way mirror), 4 and 1 (the left-right mirror). Folds make symmetric carpet pages of the wall.

## Cost
Medium (`cost: 1.1`). Native quality and above (`#if HD>=1`) add gold spiral terminals on the giant initial and fine tooling and punch-work patterns on the gold and the panels.

## Known weak points
- Every view is the same kind of picture: rectangles laid edge to edge and seen square-on, with no depth, perspective or shadow.
- The writing is small at home zoom, and its motion is hard to see at small sizes.
- The dance of the books is small (a tip of a couple of degrees, a short hop) and can read as jitter.
- The page turn is a dissolve behind a gold edge and the impact a gold tint: nothing physically transforms.
- Blue and violet palettes read darker than the others; the square script looks repetitive.
- Highs and hats are the weakest bands at home zoom.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
