  {
  key:'merc',name:'BOOMB0X',src:R_MERC,cost:1.1,cont:[],description:'kawaii sound-system wall: every band lights its own tiles like a giant level meter, a shockwave runs out on every kick, everyone hops on the snare, mouths sing the vocals',
  fb:{zoom:0,rot:0,decay:.04,warp:0,echo:0,droste:0,win:0,key:.6,live:.05},syms:[0,0,0,0,8,12,6,16],kalZoom:.7,
  auto:{kal:[0,8,12,6,16],kalCycle:true,kalZoom:.7,transitions:['portal','kaleido','vortex'],kind:'flat',fx:{bloom:.42,chroma:.22},notes:'unfolded is the hero view (stepping wall / marching parade / ring mandala round the woofer face / log-polar tunnel; zoomed out the tiles form a giant picture); 8 and 12 make ring mandalas of gear, 6 and 16 fine rosettes (the TUNNEL formation is best folded); 2/3 look lopsided, 4/5 grid-busy'},
  init:s=>{
    const r=boomRng(s[0]*.731+s[1]*.193+s[2]*.057+s[3]*.011+.0123);
    const fam=[0,1,2,0,1,2,3][Math.floor(s[1]*7)%7],A={fam,vs:r()*.98},pid=Math.floor(s[2]*boomNP)%boomNP;
    return {r,A,B:A,wipe:2,wspd:1,wty:0,bars:0,pd:0,k:0,b:[0,0,0,0,0,0,0,0],mo:0,build:0,brk:0,df:0,csN:0,ramp:-1,sn:0,
      ev:0,evS:0,evD:8,evQ:0,ext:0,spin:0,lt:-1,pid,pal:boomPals[pid].map(c=>c.slice()),palT:1};
  },
  frame(V,F,dt){
    const c=V.c,ez=(x,t,k)=>x+(t-x)*Math.min(1,dt*k);
    const ms=Math.min(1,Math.max(0,(typeof S!=='undefined'&&S.motionSmooth!=null)?S.motionSmooth:.5));
    // band envelopes drive geometry (woofers, needles, hops): attack ~70-120 ms, release ~270-400 ms
    // (v13) the engine's band levels are auto-ranged against their own recent peak, so on a dense mix they sit near 1
    // all the time and nothing seemed to move. Each band now plays its dynamics: (level / peak)^3 plus its rise over the
    // last ~0.4 s, so the bass bounces on the kicks, the mids breathe with the chords, the highs pulse with the hats
    const BB=BANDS,L=[0,1,2,3,4,5,6,7].map(i=>{const h=Math.max(BB.hi[i]||0,.15),r=(BB.fast[i]||0)/h;return Math.min(1,Math.max(0,r*r*r+1.2*((BB.fast[i]||0)-(BB.slow[i]||0))/h));}),ka=9*(1-.45*ms),kr=3.6*(1-.45*ms);
    for(let i=0;i<8;i++){const t=Math.min(1,L[i]||0);c.b[i]=t>c.b[i]?ez(c.b[i],t,ka):ez(c.b[i],t,kr);}
    c.k=F.kick>c.k?ez(c.k,F.kick,ka):ez(c.k,F.kick,kr);
    c.build=ez(c.build,F.build,2.5);c.brk=ez(c.brk,F.breakdown||0,1.5);
    // singing: the lead range (mid / hi-mid) opens the mouths
    const voc=Math.max(L[3]||0,L[4]||0,.8*(L[5]||0)),mt=Math.min(1,Math.max(0,(voc-.15)*1.6))*(1-.5*c.brk);
    c.mo=mt>c.mo?ez(c.mo,mt,20):ez(c.mo,mt,7);
    // extra scroll: builds and the spin storm push every row further (continuous speed, never a jump)
    if(c.lt<0)c.lt=V.trav;const dtr=Math.max(0,Math.min(1,V.trav-c.lt));c.lt=V.trav;
    c.spin=ez(c.spin,c.ev===4?1:0,1.5);
    c.ext=(c.ext+dtr*(1.1*c.build*c.build+1.6*c.spin))%960;
    // snare: every other snare a colour step sweeps outward from the centre
    // snare scratch and hat pop envelopes (light, for the records and tweeters)
    c.sne=Math.max((c.sne||0)*Math.exp(-dt*4),F.onHit?1:0);c.hte=Math.max((c.hte||0)*Math.exp(-dt*7),Math.min(1,F.hat||0));
    // (v13) the snare hop is geometry: a smoothed envelope (attack ~60 ms); the kick's age drives its shockwave ring
    c.hop=(c.hop||0)+(c.sne-(c.hop||0))*Math.min(1,dt*16*(1-.4*ms));c.kAge=F.onKick?0:Math.min(2,(c.kAge??2)+dt);
    // (v20b) the groove clock: reels, records and badges really turn with the level (integrated in beats, so a change of level never jumps an angle;
    // exact at any dt, it stands still at zero dt). The snare's age drives its travelling flash.
    { const lv=Math.min(1,.5*(c.b[1]+c.b[2])+.35*c.k);c.grv=((c.grv||0)+dtr*(.22+.95*lv))%1;c.sAge=F.onHit?0:Math.min(1.99,(c.sAge??1.99)+Math.max(0,dt)); }
    if(F.onHit){c.sn++;if(c.sn%2===0){if(c.ramp>=0)c.csN=(c.csN+1)%6;c.ramp=0;}}
    if(c.ramp>=0){c.ramp+=dt*2.4;if(c.ramp>=2){c.csN=(c.csN+1)%6;c.ramp=-1;}}
    // drop: a new formation bursts in, new palette, light flash; often a giant boombox or a stadium wave follows
    const drop=F.onDrop||F.drop>c.pd+.4;c.pd=F.drop;
    if(drop){boomNext(c,true,true);c.df=1;if(!c.ev&&c.r()<.6)c.evQ=[3,1,2][Math.floor(c.r()*3)];}
    if(c.ev&&(V.trav-c.evS)/c.evD>=1){c.ev=0;}
    if(!c.ev&&c.build>.55&&c.wipe>=2)boomStartEv(c,4,V.trav);
    if(!c.ev&&c.evQ&&c.wipe>=2){boomStartEv(c,c.evQ,V.trav);c.evQ=0;}
    if(F.onBar){c.bars++;
      if(!c.ev&&c.bars%8===5&&c.r()<.65)boomStartEv(c,boomEvPool[Math.floor(c.r()*boomEvPool.length)],V.trav);
      if(c.bars%8===0)boomNext(c,c.bars%16===0,false);}
    if(c.wipe<2)c.wipe=Math.min(2,c.wipe+dt*c.wspd);
    if(c.wipe>=2)c.A=c.B;
    c.df*=Math.exp(-dt*1.8);
    const P=boomPals[c.ev===5?9:c.pid];c.palT=Math.min(1,c.palT+dt*.8);
    const kp=c.palT>=1?Math.min(1,dt*2):Math.min(1,dt*(1.5+6*c.df));
    for(let i=0;i<6;i++)for(let j=0;j<3;j++)c.pal[i][j]+=(P[i][j]-c.pal[i][j])*(c.df>.6?1:kp);
    const A=c.A,B=c.B,pl=c.pal,tr=V.trav%3840,evp=c.ev?Math.min(.999,Math.max(0,(V.trav-c.evS)/c.evD)):0;
    V.p1=[tr,c.ext,c.k,c.csN*4+Math.max(c.ramp,0)];
    V.p2=c.b.slice(0,4);V.p3=c.b.slice(4,8);
    V.p4=[A.fam+A.vs,B.fam+B.vs,Math.min(c.wipe,1.9995)+4*c.wty+(c.wipe>=2?.0005:0),Math.min(c.mo,.999)+2*Math.floor(Math.min(c.hop,.99)*64)+256*Math.floor(Math.min(c.hte,.99)*64)];
    V.p5=[Math.min(c.build,.999)+2*Math.min(479,Math.floor(c.kAge*240)),Math.min(Math.max(c.brk,0),.999)+2*Math.floor(c.sAge*120),Math.min(Math.max(c.df,0),.999)+2*Math.floor(c.grv*2048),c.ev?c.ev+evp:0];
    V.m1=new Float32Array([...pl[0],...pl[1],...pl[2]]);
    V.m2=new Float32Array([...pl[3],...pl[4],...pl[5]]);
  }
  },
