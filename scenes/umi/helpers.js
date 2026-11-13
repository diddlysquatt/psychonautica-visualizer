function umiRng(seed){let x=Math.floor((seed%1)*2147483646)+1;return()=>{x=(x*16807)%2147483647;return(x-1)/2147483646;};}
// curated six-colour sea-pop palettes (sRGB hex), linearised once; every palette holds warm and cool accents
const umiPals=[
  ['00c8ff','ff4f9a','ffd400','28e07a','ff7a1a','8a5cff'], // lagoon pop
  ['ff3d6e','ff9f1c','ffe14d','2ec4ff','12e2a3','b85cff'], // coral reef
  ['ff5fcf','7a6bff','36d6ff','7dff6b','fff35c','ff8a3d'], // bubblegum sea
  ['ff2e2e','ff8c00','ffd23f','00b4ff','00e0b0','ff6fb5'], // koi pond
  ['00f0d0','00a2ff','c35bff','ff4fa0','ffb02e','d6ff3d'], // neon tide
  ['ff7eb3','ffb36b','fff07a','8af5c0','6ec8ff','b58cff'], // sherbet surf
  ['ff4d00','ffc400','ff2f86','1ad0ff','30f27a','8f4bff'], // sunset surf
  ['3dffb5','00d2ff','2b6bff','ff3ca6','ff9a3c','fff04d']  // reef glow
].map(p=>p.map(hx=>[0,2,4].map(i=>{const v=parseInt(hx.substr(i,2),16)/255;return 1.12*(v<=.04045?v/12.92:Math.pow((v+.055)/1.055,2.4));})));
// one composition: family (0 reef, 1 schools, 2 whirlpool, 3 rise) and a variant seed
function umiComp(r,fam){return {fam,vs:r()};}
// phrase / drop change: a new composition rolls in behind a rainbow wave front; drops often bring the giant octopus
function umiNext(c,newFam,isDrop){
  c.A=c.wipe<1?c.B:c.A;
  const fam=newFam?(c.B.fam+1+Math.floor(c.r()*3))%4:c.B.fam;
  c.B=umiComp(c.r,fam);c.wipe=0;c.wipeSpd=isDrop?1.25:.45;
  if(isDrop&&!c.ev&&c.r()<.6)c.evQ=4;
  let pid=Math.floor(c.r()*umiPals.length);if(pid===c.pid)pid=(pid+1+Math.floor(c.r()*(umiPals.length-1)))%umiPals.length;
  c.pid=pid;c.palT=isDrop?0:.35;
}
// surprise events (ids: 1 heart eyes, 2 turnaround wave, 3 chorus, 4 giant octopus)
const umiEvPool=[1,2,2,3,4,4],umiEvDur=[8,8,16,8,16];
function umiStartEv(c,e,trav){c.ev=e;c.evS=trav;c.evD=umiEvDur[e];}
