# SOL 70 (`sol`)

Superflat 1970s flower power: a field of original smiling flowers packed edge to edge in parallax layers, tiny at the back and big at the front, with crisp ink outlines and layered rainbow petals. The field can be a drifting pile, a tunnel of rings streaming out of a sun-flower, a spiral, a parade of flowers and mushrooms, or a chorus line of long-stemmed flowers.

## How it moves with the music
- Singing: the flowers open their mouths on vocal syllables. The front flowers sing the lead, the next layer the harmony, the small ones the bassline, and the tiny carpet at the back twinkles with the air band.
- Beat: petals turn one notch per beat in a wave that sweeps across the field; parade rows and the chorus line step on the beat.
- Kick: a shockwave ring crosses the field, one at a time.
- Bass: the bassline breathes the back layers.
- Snare: a wave of colour sweeps the field, every flower's petals stepping round by one palette colour.
- Hats: keep a field of sparkles alive through a hat pattern.
- Dances: a new kind of dance every four bars, each riding the band that suits it.
- Builds and phrases: builds call the chorus line; surprise events sweep the field (flower rain, a mushroom conga, card stunts where the field flips into a mandala, an equaliser rainbow, a pumping heart or, rarely, one giant winking face).
- Drops: a new composition and palette behind a neon ring wipe, every flower spinning a full turn; about half the drops burst into a folded, kaleidoscopic composition that a later ring unfolds.

## Framings (Auto Show)
- far (`0.25`): the whole packed field, layer behind layer.
- home (`0.55`): the field with the front flowers' faces readable.
- close (`1.1`): the big front flowers and the print on their petals; this scene takes close-ups often.
- kaleidoscope: folds in about 20% of visits; best fold 12; acceptable 16, 6 and 1 (the left-right mirror). The scene also folds itself on some drops.

## Cost
Medium (`cost: 1.25`). Native quality and above (`#if HD>=1`) add a comic shadow hatch and a bead rim on the flowers, lines of tiny florets up the petals, and more samples for smoother paper shadows.

## Known weak points
- The motion of several dances was judged from the code and from motion traces, not watched in live playback; the punchy dances may read as twitchy.
- The contour-stripe petal style is the busiest of the four and can read as rings on small flowers.
- A vertical colour seam was once reported at the widest zoom and was not investigated.
- At small sizes the steps between quality tiers are slight.
- Not tested on phones.

## Files
`scene.glsl` (shader), `helpers.js` (JavaScript helpers), `entry.js` (the scene object), `scene.json` (name, credits, Auto Show rows).
