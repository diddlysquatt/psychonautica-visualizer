function solRng(seed){let x=Math.floor((seed%1)*2147483646)+1;return()=>{x=(x*16807)%2147483647;return(x-1)/2147483646;};}
// curated six-colour palettes (sRGB hex), linearised once; every palette holds warm and cool accents
const solPals=[
  ['ff2d95','ff8a00','ffe600','5fe000','19b8ff','8c4bff'], // candy shop
  ['ff3b1f','ff9a00','ffd400','ff4fa3','b8ff2e','00c2a8'], // tequila
  ['00e0ff','00c48c','9cff3f','ff5fa2','ffd23f','6a5cff'], // lagoon
  ['b14bff','ff3dcf','ff7a59','ffd447','3dd6ff','2bff88'], // grape soda
  ['c6ff00','00ff9c','00c8ff','ff00c8','ffea00','ff5a00'], // acid
  ['ff6f91','ff9671','ffc75f','f9f871','00c9a7','c493ff'], // sherbet
  ['ff1744','ffea00','2979ff','00e676','ff9100','d500f9'], // primary pop
  ['ff4e00','ff9e00','ffcf3f','e83f6f','9c2fff','2bd9c8']  // sunset 70
].map(p=>p.map(hx=>[0,2,4].map(i=>{const v=parseInt(hx.substr(i,2),16)/255;return 1.12*(v<=.04045?v/12.92:Math.pow((v+.055)/1.055,2.4));})));
// one composition: family (0 field, 1 tunnel, 2 parade, 3 spiral, 4 chorus line), variant seed, style seed, kaleidoscope fold (0 none, 1..4 -> 6..12 sectors)
function solComp(r,fam,kf){return {fam,vs:r(),sty:r(),kf:kf||0};}
// drops: 55% burst into a folded kaleidoscope composition (a later hoop unfolds it), otherwise a card-stunt picture
// (mandala, rainbow or heart) follows the wipe. Phrase changes arrive by one of three transitions: the rainbow hoop,
// a flower wave (a marching row of big flowers sweeps the next scene in, one step per beat) or a paper fan (eight
// blades unfold the next scene from the bottom edge, one blade per beat).
function solNext(c,newFam,isDrop){
  c.A=c.wipe<1.6?c.B:c.A;
  const fam=newFam?(c.B.fam+1+Math.floor(c.r()*4))%5:c.B.fam;
  const kf=(isDrop?c.r()<.55:c.r()<.1)?1+Math.floor(c.r()*4):0;
  c.B=solComp(c.r,fam,kf);c.wipe=0;c.wipeSpd=isDrop?1.9:.8;c.unf=kf?c.bars+(isDrop?4:2):-1;
  // transition style: drops and folded bursts keep the fast hoop; phrase changes pick hoop / wave / fan, never the
  // same one twice running
  let wm=0;if(!isDrop&&!kf){wm=Math.floor(c.r()*4);if(wm===c.wmL)wm=(wm+1+Math.floor(c.r()*3))%4;}
  c.wm=wm;c.wmL=wm;c.wd=Math.floor(c.r()*8);c.wT0=Math.round(c.trv||0);c.wt=0;c.wB=wm===1?6:8;
  if(isDrop&&!kf&&!c.ev&&c.r()<.7)c.evQ=[8,9,10,13][Math.floor(c.r()*4)];
  let pid=Math.floor(c.r()*solPals.length);if(pid===c.pid)pid=(pid+1+Math.floor(c.r()*(solPals.length-1)))%solPals.length;
  c.pid=pid;c.palT=isDrop?0:.35;
}
// unfold a kaleidoscope composition: the same field, unfolded, revealed by a slower hoop (no palette change)
function solUnfold(c){c.A=c.wipe<1.6?c.B:c.A;c.B=Object.assign({},c.B,{kf:0});c.wipe=0;c.wipeSpd=.9;c.unf=-1;c.wm=0;}
// surprise events per family (ids: 1 heart eyes, 2 shades, 3 chorus, 4 spin storm, 5 giant face, 6 flower rain,
// 7 mushroom conga, 8..10 card stunts: 8 breathing mandala, 9 equaliser rainbow, 10 pumping heart, v18: 11 bloom pop, 12 bouncing band). The giant smiley
// face (5) is not in any pool: it is a rare treat scheduled by solGF (at most once per visit, never in the first
// ~3 minutes of a visit, and at least 8 minutes of SOL watch time apart).
const solEvPool=[[1,2,3,4,6,6,7,7,8,9,10,11,11,12,12,13],[1,2,3,4,8,9,10,11,12,12,13],[1,2,3,4,6,6,8,9,10,11,11,12,12,13],[1,2,3,4,8,10,11,12,12,13],[1,2,4,6,6,8,9,10,11,12,12,13]],solEvDur=[8,8,8,8,8,16,16,16,16,16,16,16,16,16];   // v20: 13 echo star
function solStartEv(c,e,trav){c.ev=e;c.evS=trav;c.evD=solEvDur[e];}
// rare giant-face scheduler, shared by every SOL visit and reseed (reseeds re-run init, so this cannot live in V.c)
const solGF={clock:0,last:-1e9,rt:1e9,done:false,thr:200};
