function kamiRng(seed){let x=Math.floor((seed%1)*2147483646)+1;return()=>{x=(x*16807)%2147483647;return(x-1)/2147483646;};}
// a route (0 diagonal, 1 river, 2 chevron, 3 spiral, 4 rings, 5 sunburst) and its variant seed (band angle, width, waves)
const kamiRoutePool=[0,0,0,1,1,2,3,3,4,5];
function kamiRoute(r,prev){let k=kamiRoutePool[Math.floor(r()*kamiRoutePool.length)];if(prev!=null&&k===prev)k=kamiRoutePool[Math.floor(r()*kamiRoutePool.length)];return {k,vs:r()*.998};}
// phrase / drop change: the next route sweeps in behind a page-turn crease, a new palette fades (snaps on drops)
function kamiNext(c,newRoute,isDrop){
  if(newRoute){c.A=c.wipe<1.6?c.B:c.A;c.B=kamiRoute(c.r,c.A.k);c.wipe=0;c.wipeSpd=isDrop?1.6:.45;}
  if(c.palT>=1)c.pA=c.pB;
  let p=Math.floor(c.r()*6);if(p===c.pB)p=(p+1+Math.floor(c.r()*5))%6;
  c.pB=p;c.palT=0;c.palSpd=isDrop?3:.35;
  if(c.r()<.3)c.tsh=(c.tsh+1+Math.floor(c.r()*3))%4;
}
// events: 1 crane confetti, 2 crane mandala, 3 turnaround (every animal flips like a card), 4 fold wave, 5 refold
// (the whole procession folds back into paper squares and opens out again)
const kamiEvPool=[1,1,3,3,4,4,2,5,5],kamiEvDur=[0,6,12,3,6,6];
function kamiStartEv(c,e,trav){c.ev=e;c.evS=trav;c.evD=kamiEvDur[e];}
