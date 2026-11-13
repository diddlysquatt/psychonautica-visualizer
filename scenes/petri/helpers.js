function petriRng(seed){let x=Math.floor((seed%1)*2147483646)+1;return()=>{x=(x*16807)%2147483647;return(x-1)/2147483646;};}
// slide stains: a ground colour, an outline code (jewel index + tint amount; 0 = cream) and six jewels in role order
// (warm, gold, rose, green, cool, blue). Darkfield navy is the reference look; the others re-stain the same slide.
const petriLin=hx=>[0,2,4].map(i=>{const v=parseInt(hx.substr(i,2),16)/255;return v<=.04045?v/12.92:Math.pow((v+.055)/1.055,2.4);});
const petriStains=[
  ['0c3f8e',0,['ff9a1f','ffd83a','ff4f7b','86d93a','1fd0b8','45b5ff']],   // darkfield navy (the reference)
  ['2a1a96',3.35,['ff3fd2','f4ff3a','ff3a5c','3dff6a','00f0ff','5a6bff']], // fluorescence: GFP / RFP / DAPI on indigo
  ['0c6378',1.4,['ff8a2a','ffd34d','ff6f61','b5e655','3fe0c5','5ac8ff']],  // phase-contrast gold on deep petrol
  ['521c88',2.25,['ff7a45','ffc93c','ff3d7f','c86bff','4de1d2','7d8bff']], // gram stain: crimson and violet on plum
  ['1240a8',0,['ff8c69','ffe066','ff5fa2','9cf06b','5ef2ff','b3c7ff']],    // cyanotype: prussian blue, ice and coral
  ['0f507a',1.3,['ff9e00','ffee32','ff4d8d','70e000','00d4aa','4cc9f0']],  // lugol: lemon outlines on green-navy
  ['2e1e98',0,['ff7b39','ffc145','ff4fa0','a6e22e','38d9c8','8f7bff']],    // sunset darkfield: violet navy
  ['561a78',2.15,['ff5c8a','ffbe3d','ff2e7e','b04dff','3fe0ff','6a4dff']]   // H&E: eosin and haematoxylin on aubergine
].map(([bg,oc,j])=>({bg:petriLin(bg).map(v=>v*1.7),oc,j:j.map(h=>petriLin(h).map(v=>v*1.3+.03))}));
// one composition: family (0 slide, 1 mandala, 2 current) and a variant seed
function petriComp(r,fam){return {fam,vs:r()};}
// phrase / drop change: a new slide spreads from the centre behind a cream membrane front; the cells just ahead of the
// front divide. Drops re-stain the slide and often send a giant organism through.
// folded (kaleidoscope on), the arranged MANDALA slide is the one that reads as organisms, so it is strongly favoured
function petriFold(V){try{return typeof effectiveSym==='function'?(effectiveSym(V)||0):0;}catch(e){return 0;}}
function petriNext(c,newFam,isDrop,fold){
  c.A=c.wipe<1.6?c.B:c.A;
  let fam=newFam?(c.B.fam+1+Math.floor(c.r()*2))%3:c.B.fam;
  if(fold>1&&c.r()<.8)fam=1;
  c.B=petriComp(c.r,fam);c.wipe=0;c.wipeSpd=isDrop?1.5:.55;
  if(isDrop||c.r()<.6){let sid=Math.floor(c.r()*petriStains.length);if(sid===c.sid)sid=(sid+1+Math.floor(c.r()*(petriStains.length-1)))%petriStains.length;c.sid=sid;c.palT=isDrop?0:.3;}
  if(isDrop&&!c.ev&&c.r()<.8)c.evQ=[2,2,1,3,4][Math.floor(c.r()*5)]; // drops: often a division bloom
}
// surprise events: 1 giant ciliate swims through, 2 division bloom, 3 giant radiolarian rises, 4 giant pennate glides
const petriEvPool=[1,1,2,2,3,3,4,4],petriEvDur=[8,16,8,16,16];
function petriStartEv(c,e,trav){c.ev=e;c.evS=trav;c.evD=petriEvDur[e];}
