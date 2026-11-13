# MARBL (`marbl`)

Paper marbling (Turkish ebru and Japanese suminagashi) played live by the music. Ink drops land in a bath and are raked by combs and styluses into veins, roses, flowers and birds; every step is computed exactly, so the pattern stays crisp however old it is. Zoomed out, the live bath is one sheet in a gallery of prints that are all being marbled on the beat.

## How it moves with the music
- Kick: an ink drop falls, lands and splashes in the bath.
- Snare: a comb or stylus stroke is pulled through the inks.
- Band onsets: a sharp onset in any band from low-mid to air drops that band's ink into its own colour well; a sharp low-mid accent (a bass stab, a tom, a chord) pulls a flower or a rose through the newest drop.
- Hats: each hat sprinkles droplets, more when the air band is busy; gold leaf and fine stones glitter with the highs.
- Tone: the choice of ink follows how bright or dark the track is.
- Builds: a fine comb rocks back and forth on every snare, harder as the build rises; in the gallery, rows of prints slide along the wall on each snare.
- Drops: a fresh bath (new palette, recipe and formation) is poured over the old one, sometimes with a torn-paper collage on top, and the whole gallery is re-poured.
- Quiet music: with no kicks the marbler keeps working slowly on the beat grid.
- The camera sometimes walks through the gallery in step with the beat.

## Framings (Auto Show)
- far (`0.2`): a wall of many prints.
- home (`0.42`): the live print among its neighbours.
- close (`1.05`): the live print fills the frame; brief, since any closer less than half of it is in view.
- kaleidoscope: folds in about 30% of visits; best folds 6, 8, 12; acceptable 2 (the four-way mirror, used only during a gallery walk) and 16. Folds turn a gallery walk into stars of receding prints. The Auto Show waits during the first seconds of a walk and while it lands.

## Cost
Medium (`cost: 1.3`). From Native quality up (`#if HD>=1`) the ink is never flat: every ink carries a marbled figure of its own, and the detail it is drawn with doubles between Native and the top tier.

## Known weak points
- The curl of the far gallery floor shows as a bowl when zoomed far out or on a small canvas.
- The dancing motions of the sheet move the whole print and may read as sway.
- Far-field shimmer was judged on stills, not on video.
- The gallery re-pour on a drop was seen on a single drop only.
- The lean-in camera moves are quieter than the gallery flights.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
