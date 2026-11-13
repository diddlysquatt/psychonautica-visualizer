// ABYSS: curated neon palettes as four hues each, three per depth zone (index = zone*3 + k): twilight (magenta, cyan, amber
// on ultramarine ink), midnight (electric cyan, red, violet, a lime accent on wine-black), the vent garden (ember, gold, teal,
// hot pink on black-teal); two hues are packed per uniform float (floor(a*4096)+b)
const ABYSS_PALS=[[.9,.5,.11,.84],[.98,.52,.14,.6],[.86,.47,.07,.55],[.5,.99,.78,.3],[.47,.02,.72,.56],[.52,.95,.3,.66],[.06,.13,.48,.93],[.03,.46,.12,.9],[.1,.5,.97,.17]];
function abyssZPal(z,cur){const k=z*3+Math.floor(rand()*3)%3;return k===cur?z*3+(k-z*3+1+Math.floor(rand()*2)%2)%3:k;}
function abyssPack(a,b){a=Math.max(0,Math.min(.9999,a||0));b=Math.max(0,Math.min(.9995,b||0));return Math.floor(a*4096)+b;}
// ABYSS: bell pulse envelope (mirrors abPulseAt in the shader) and ensemble changes
function abyssPulse(t){if(t<0)return 0;const x=Math.min(1,t/.08);return x*x*(3-2*x)*Math.exp(-Math.max(t-.08,0)*4.5);}
function abyssPick(n,cur){let k=Math.floor(rand()*n)%n;if(k===cur)k=(k+1+Math.floor(rand()*(n-1)))%n;return k;}
// families: 0 jelly bloom, 1 glass garden, 2 comb carnival, 3 siphonophore drift, 4 mixed, 5 reef, 6 open ocean
// (jelly-led families are weighted up: the jellies are the heart of the realm)
function abyssFam(cur){const w=[3,1,1,2,2,2,2];let t=0;for(let i=0;i<7;i++)if(i!==cur)t+=w[i];let r=rand()*t;for(let i=0;i<7;i++){if(i===cur)continue;r-=w[i];if(r<=0)return i;}return 0;}
// start a wipe from the centre: kind 0 = palette only, .6 = new species (metamorphosis), 1 = drop burst
function abyssWipe(c,kind,newFam,newPal){
  if(c.bR<8){c.famA=c.famB;c.palA=c.palB;c.sdA=c.sdB;}
  c.famB=newFam?abyssFam(c.famA):c.famA;
  c.palB=newPal?abyssZPal(c.zone||0,c.palA):c.palA;
  c.sdB=newFam?Math.floor(rand()*997)/10:c.sdA;
  c.bR=0;c.bK=kind;c.bSp=kind>=1?1.5:.95;
  // a reef family brings the floor and its kelp up into view; open water lets it sink away
  if(newFam){if(c.famB===5)c.kelp=1;else if(c.famB===6||rand()<.3)c.kelp=rand()<.3?1:0;}
}
// ABYSS v22: begin a dive to depth zone nz (0 twilight, 1 midnight, 2 the vent garden); the ensemble swaps in flight (see frame)
function abyssDive(c,nz){c.dvA=c.dv;c.dvB=nz;c.dvP=0;c.dvDur=Math.abs(nz-c.dv)>1.5?2.6:1.9;c.zone=nz;c.plCool=7;c.swapped=false;c.loEv=0;c.since=0;}
// ABYSS: a deterministic hash for event placement (keeps the seeded rand() sequence for ensembles and palettes)
function abyssHash(x){const s=Math.sin(x*12.9898+78.233)*43758.5453;return s-Math.floor(s);}
