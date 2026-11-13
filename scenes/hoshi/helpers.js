function hoshiRng(seed){let x=Math.floor((seed%1)*2147483646)+1;return()=>{x=(x*16807)%2147483647;return(x-1)/2147483646;};}
// curated six-colour cosmic-pop palettes (sRGB hex), linearised once; every palette is bright, warm plus cool accents
const hoshiPals=[
  ['ff3d9a','ffb000','fff04a','35e0ff','7b5cff','3dff8f'], // cosmic candy
  ['ff5e3a','ffd23f','ff3dcf','00d9ff','a45cff','7dff4d'], // solar flare
  ['00f5d4','00bbf9','9b5de5','f15bb5','fee440','ff8c42'], // nebula pop
  ['ff4d6d','ff9e00','ffe66d','4dffbe','3a86ff','c77dff'], // rocket fuel
  ['b8ff3d','00ffc8','00a8ff','ff4fd8','ffd000','ff6a3d'], // acid galaxy
  ['ff8fd8','ffc46b','fff59e','8cf5ff','9f9bff','6bffb0'], // milky sherbet
  ['ff2e63','ffd166','06d6a0','1fb6ff','b14bff','ff7b00'], // space race
  ['ffea00','ff006e','8338ec','3a86ff','00f5a0','ff9100']  // disco cosmos
].map(p=>p.map(hx=>[0,2,4].map(i=>{const v=parseInt(hx.substr(i,2),16)/255;return 1.12*(v<=.04045?v/12.92:Math.pow((v+.055)/1.055,2.4));})));
// deep space uses each palette's coolest colour (blue / violet / teal, never a darkened warm colour)
const hoshiCool=hoshiPals.map(p=>{let b=0,bs=-9;p.forEach((c,i)=>{const s=c[2]-.7*c[0]-.2*c[1];if(s>bs){bs=s;b=i;}});return b;});
// one composition: family (0 orrery, 1 galaxy, 2 parade) and a variant seed
function hoshiComp(r,fam){return {fam,vs:r()};}
// phrase / drop change: a new cosmos bursts out of the centre behind a big-bang hoop; drops often bring a flyby or
// the giant planet
function hoshiNext(c,newFam,isDrop){
  c.A=c.wipe<1.6?c.B:c.A;
  const fam=newFam?(c.B.fam+1+Math.floor(c.r()*2))%3:c.B.fam;
  c.B=hoshiComp(c.r,fam);c.wipe=0;c.wipeSpd=isDrop?1.9:.8;
  if(isDrop&&!c.ev&&c.r()<.75)c.evQ=[4,5,6,6][Math.floor(c.r()*4)];
  let pid=Math.floor(c.r()*hoshiPals.length);if(pid===c.pid)pid=(pid+1+Math.floor(c.r()*(hoshiPals.length-1)))%hoshiPals.length;
  c.pid=pid;c.palT=isDrop?0:.35;
}
// surprise events (ids: 1 star eyes, 2 spin storm, 3 chorus, 4 giant planet, 5 comet shower, 6 rocket parade,
// 7 the big bounce: every character leaps in a wave rolling round the system, 8 saucer squadron with tractor beams)
const hoshiEvPool=[1,2,2,4,4,5,5,6,6,7,7,8,8],hoshiEvDur=[8,8,8,8,16,8,8,12,8];
function hoshiStartEv(c,e,trav){c.ev=e;c.evS=trav;c.evD=hoshiEvDur[e];}
