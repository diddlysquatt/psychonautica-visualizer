const REALMS = [
//@scene entry gate
//@scene entry lattice
//@scene entry cathedral
//@scene entry foam
//@scene entry mandala
//@scene entry void9
//@scene entry merc
//@scene entry klnn
//@scene entry boxx
//@scene entry kubik
//@scene entry tess
//@scene entry swarm
//@scene entry chroma
//@scene entry flux
//@scene entry knott
//@scene entry sol
//@scene entry spiro
//@scene entry velvet
//@scene entry optik
//@scene entry hypr
//@scene entry cyma
//@scene entry abyss
//@scene entry marbl
//@scene entry eschr
//@scene entry umi
//@scene entry hoshi
//@scene entry kami
//@scene entry petri
//@scene entry tykes
//@scene entry scribe
];

// Default fb.live per realm: crisp vector realms keep the engine's global live warp and kick zoom low.
const REALM_EVOLVES = new Set(['petri', 'kami', 'hoshi', 'umi', 'hypr', 'cyma', 'eschr', 'abyss', 'marbl', 'kubik', 'tess', 'swarm', 'chroma', 'flux', 'knott', 'sol', 'spiro', 'velvet', 'optik', 'merc']);
const REALM_LIVE = { chroma: .15, flux: .3, knott: .2, sol: .15, spiro: .2, velvet: .25, optik: .2, tess: .4, kubik: .6, swarm: .7 };

