function boomRng(seed){let x=Math.floor((seed%1)*2147483646)+1;return()=>{x=(x*16807)%2147483647;return(x-1)/2147483646;};}
// curated six-colour sound-system palettes (sRGB hex, linearised once); index 9 is the UV night palette
const boomPals=[
  ['ff3b6b','ffb800','fff35c','2ee6d6','3d7bff','b45cff'], // candy stack
  ['ff006e','fb5607','ffbe0b','3a86ff','8338ec','06d6a0'], // block party
  ['f72585','ff9e00','4cc9f0','4361ee','b5179e','c6ff3d'], // club neon
  ['ff595e','ffca3a','8ac926','1982c4','a463ff','ff924c'], // fruit crate
  ['00f5d4','fee440','f15bb5','9b5de5','00bbf9','ff7b00'], // pop tape
  ['ff477e','ff9e00','fcf300','38d000','00b4d8','9d4edd'], // rainbow rig
  ['ff2a6d','05d9e8','fff0a8','ff9f1c','7700ff','01ff89'], // arcade
  ['ff5d8f','ffd23f','5ef38c','3bceac','ee4266','8f5cff'], // bubblegum
  ['ff7a00','ffd60a','e71d36','2ec4b6','5b5bff','ff4fd8'], // sunset system
  ['ff00c8','00ffe1','fff700','7a00ff','ff5400','00a2ff']  // UV night (event)
].map(p=>p.map(hx=>[0,2,4].map(i=>{const v=parseInt(hx.substr(i,2),16)/255;return 1.22*(v<=.04045?v/12.92:Math.pow((v+.055)/1.055,2.4));})).sort((a,b)=>(.2126*a[0]+.7152*a[1]+.0722*a[2])-(.2126*b[0]+.7152*b[1]+.0722*b[2])));
const boomNP=9;
// formations: 0 WALL, 1 PARADE, 2 RINGS, 3 TUNNEL (drops favour the tunnel and the rings)
function boomFam(r,cur,isDrop){
  const w=isDrop?[.15,.1,.3,.45]:[.36,.28,.24,.12];let f=cur;
  for(let t=0;t<6&&f===cur;t++){let x=r(),i=0;while(i<3&&x>w[i]){x-=w[i];i++;}f=i;}
  return f;
}
function boomNext(c,newFam,isDrop){
  c.A=c.wipe<2?c.B:c.A;
  c.B={fam:newFam?boomFam(c.r,c.B.fam,isDrop):c.B.fam,vs:c.r()*.98};
  c.wipe=0;c.wspd=isDrop?1.6:.75;c.wty=Math.floor(c.r()*3);
  let pid=Math.floor(c.r()*boomNP);if(pid===c.pid)pid=(pid+1+Math.floor(c.r()*(boomNP-1)))%boomNP;
  c.pid=pid;c.palT=isDrop?0:.3;
}
// surprise events: 1 stadium wave, 2 chorus, 3 giant boombox, 4 spin storm, 5 UV night (length in beats)
const boomEvPool=[1,1,2,3,3,4,5],boomEvDur=[8,16,8,16,8,16];
function boomStartEv(c,e,trav){c.ev=e;c.evS=trav;c.evD=boomEvDur[e];}
