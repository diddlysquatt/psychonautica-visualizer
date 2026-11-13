  {
  key:'hoshi',name:'HOSHI 88',src:R_HOSHI,cost:1.5,cont:[],description:'superflat smiling cosmos',
  fb:{zoom:0,rot:0,decay:.1,warp:0,echo:0,droste:0,win:0,key:.08,live:.05},syms:[0,0,0,8,8,12,12,6,16,5],kalZoom:.7,
  auto:{kal:[0,8,12,6,16,5],kalCycle:true,kalZoom:.7,transitions:['portal','kaleido','vortex'],kind:'flat',notes:'v12: all folds re-rendered on 3 seeds; orrery and galaxy fold into full ring mandalas at every listed fold, the parade folds into rainbow spokes (good, less rich). unfolded is the hero view (depth-sorted orrery / galaxy / parade, giant ringed planets made of characters when zoomed out); 8 and 12 make orbit-ring mandalas, 6 and 16 fine star rosettes, 5 a flower; 2/3/4 crop the sun and look lopsided'},
  init:s=>{
    const r=hoshiRng(s[0]*.731+s[1]*.193+s[2]*.057+s[3]*.011);
    const A=hoshiComp(r,Math.floor(s[1]*3)%3),pid=Math.floor(s[2]*hoshiPals.length)%hoshiPals.length;
    return {r,A,B:A,wipe:2,wipeSpd:1,bars:0,pd:0,k:0,sn:0,build:0,brk:0,df:0,csN:0,ramp:-1,blT:9,ev:0,evS:0,evD:8,evQ:0,ext:0,lt:-1,
      mo:[0,0,0,0],syl:0,sylH:0,sylB:0,act:0,actH:0,pv:0,ph:0,pvT:0,phT:0,pid,pal:hoshiPals[pid].map(c=>c.slice()),palT:1};
  },
  frame(V,F,dt){
    const c=V.c,ez=(x,t,k)=>x+(t-x)*Math.min(1,dt*k),sm=(a,b,x)=>{const t=Math.min(1,Math.max(0,(x-a)/(b-a)));return t*t*(3-2*t);};
    const ms=Math.min(1,Math.max(0,(typeof S!=='undefined'&&S.motionSmooth!=null)?S.motionSmooth:.5));
    // kick envelope drives geometry (planet pump, sun pump, rocket flames): >=60 ms attack, >=200 ms release, softer
    // with the Motion smoothness dial
    c.k=F.kick>c.k?ez(c.k,F.kick,16*(1-.5*ms)):ez(c.k,F.kick,5*(1-.5*ms));
    c.build=ez(c.build,F.build,2.5);c.brk=ez(c.brk,F.breakdown||0,1.5);
    // builds spin the orbits faster: extra distance accumulates continuously (never a jump)
    if(c.lt<0)c.lt=V.trav;const dtr=Math.max(0,Math.min(1,V.trav-c.lt));c.lt=V.trav;c.ext=(c.ext+dtr*1.2*c.build)%3840;
    // singing: the lead (big characters, the sun) opens on vocal syllables (band onsets minus broadband drum hits)
    const L=BANDS.lv,O=BANDS.on;let om=0;for(let i=0;i<8;i++)om+=O[i];om/=8;
    const dr=Math.max(O[0],O[1],Math.min(O[2],O[6],O[7])),vo=Math.max(0,Math.max(O[3],O[4])-.9*dr-.3*om),vh=Math.max(0,O[5]-.9*dr-.3*om),vb=Math.max(0,O[1]-.8*om);
    if(dr>.45){c.pv=0;c.ph=0;}
    if(vo>.18&&!c.pvT){c.pv=vo;c.pvT=.07;}if(vh>.18&&!c.phT){c.ph=vh;c.phT=.07;}
    if(c.pvT){c.pvT=Math.max(0,c.pvT-dt);if(!c.pvT&&c.pv>0){c.syl=Math.max(c.syl,.5+.5*Math.min(1,c.pv*1.6));c.act=Math.min(1.4,c.act+.4);}}
    if(c.phT){c.phT=Math.max(0,c.phT-dt);if(!c.phT&&c.ph>0){c.sylH=Math.max(c.sylH,.45+.5*Math.min(1,c.ph*1.6));c.actH=Math.min(1.4,c.actH+.4);}}
    if(vb>.25)c.sylB=Math.max(c.sylB,.4+.5*Math.min(1,vb*1.5));
    const e1=Math.exp(-dt*5.5);c.syl*=e1;c.sylH*=e1;c.sylB*=Math.exp(-dt*7);c.act*=Math.exp(-dt*1.1);c.actH*=Math.exp(-dt*1.1);
    const g=sm(.15,.55,c.act),gH=sm(.15,.55,c.actH),voc=Math.max(L[3],L[4],L[5]);
    const tg=[.6*L[7],gH*Math.max(c.sylH,.22*L[5]),c.sylB,g*Math.max(c.syl,.25*voc)];
    for(let i=0;i<4;i++){const t=Math.min(1,tg[i])*(1-.5*c.brk);c.mo[i]=t>c.mo[i]?ez(c.mo[i],t,25):ez(c.mo[i],t,12);}
    // snare: a wave of colour steps sweeps outward from the sun (every character steps one palette colour)
    if(F.onHit){c.sn=1;if(c.ramp>=0)c.csN=(c.csN+1)%6;c.ramp=0;}
    if(c.ramp>=0){c.ramp+=dt*2.6;if(c.ramp>=2){c.csN=(c.csN+1)%6;c.ramp=-1;}}
    c.sn*=Math.exp(-dt*7);
    // drops: big bang. A new cosmos bursts out of the centre, everything spins a full turn, often a flyby or giant planet
    const drop=F.onDrop||F.drop>c.pd+.4;c.pd=F.drop;
    if(drop){hoshiNext(c,true,true);c.df=1;}
    // phrases: new palette/variant every 8 bars, new family every 16, a synchronised blink every 4; events
    if(c.ev&&(V.trav-c.evS)/c.evD>=1)c.ev=0;
    if(!c.ev&&c.build>.55&&c.wipe>=1.6)hoshiStartEv(c,3,V.trav);
    if(!c.ev&&c.evQ&&c.wipe>=1.6){hoshiStartEv(c,c.evQ,V.trav);c.evQ=0;}
    if((F.onBar || F.onSceneBar)){c.bars++;
      if(!c.ev&&c.bars%8===5&&(c.r()<.7||c.bars<8))hoshiStartEv(c,hoshiEvPool[Math.floor(c.r()*hoshiEvPool.length)],V.trav);
      else if(!c.ev&&c.bars%16===10&&c.r()<.5)hoshiStartEv(c,4,V.trav);
      if(c.bars%8===0)hoshiNext(c,c.bars%16===0,false);
      if(c.bars%4===3)c.blT=0;}
    if(c.wipe<2)c.wipe=Math.min(2,c.wipe+dt*c.wipeSpd);
    if(c.wipe>=1.6)c.A=c.B;
    c.df*=Math.exp(-dt*1.6);
    c.blT+=dt;const bl=c.blT<.22?Math.sin(Math.PI*c.blT/.22):0;
    const P=hoshiPals[c.pid];c.palT=Math.min(1,c.palT+dt*.8);
    const kp=c.palT>=1?1:Math.min(1,dt*(1.5+6*c.df));
    for(let i=0;i<6;i++)for(let j=0;j<3;j++)c.pal[i][j]+=(P[i][j]-c.pal[i][j])*(c.df>.5?1:kp);
    const w=Math.min(1,c.wipe),wr=c.wipe>=1.6?0:(1-(1-w)*(1-w))*1.35;
    const A=c.A,B=c.B,pl=c.pal,tr=V.trav%3840;
    // v12: the chords / vocal range (low-mid, mid) swell their own orbits (smoothed: >= 80 ms attack, 300 ms release)
    {const mt=Math.min(1,Math.max(L[2],L[3]));c.ms=c.ms||0;c.ms=ez(c.ms,mt,(mt>c.ms?11:3.3)*(1-.4*ms));}
    // hat activity: each hat adds, a 0.45 s release keeps the sparkle field alive through a hat pattern (light only)
    c.ha=Math.max((c.ha||0)*Math.exp(-dt/.45),Math.min(1,(F.hat||0)*1.2),O[6]*.9,O[7]);
    // v13: the vocal range (hi-mid / presence) lights every conveyor belt and the planet rings (smoothed: 90 ms / 300 ms)
    {const pt=Math.min(1,1.3*Math.max(L[4],L[5]));c.pr=c.pr||0;c.pr=ez(c.pr,pt,(pt>c.pr?11:3.3)*(1-.4*ms));}
    V.p1=[tr+c.ext,V.mt%628.3185,c.k,256*Math.round(Math.min(1,c.pr)*99)+2*Math.round(Math.min(1,c.ha)*100)+Math.min(c.ms,.999)];
    {const bt=Math.min(1,Math.max(L[0],L[1]));c.bsE=c.bsE||0;c.bsE=ez(c.bsE,bt,(bt>c.bsE?14:4)*(1-.4*ms));
     c.snE=c.snE||0;c.snE=ez(c.snE,c.sn,(c.sn>c.snE?20:6)*(1-.4*ms));}
    // v18: the smoothed bass and snare envelopes ride in the fraction of p2.x (palette index is read by rounding, so it stays unchanged)
    V.p2=[hoshiCool[c.pid]+.49*Math.min(.999,(Math.round(c.bsE*63)+Math.min(1,c.snE)*.99)/64),c.mo[1],c.mo[2],c.mo[3]];
    {const at=Math.min(1,Math.max(BANDS.lv[7],.8*(c.ha||0)));c.ai=c.ai||0;c.ai+=(at-c.ai)*Math.min(1,dt*(at>c.ai?9:2.8));}   // v13: smoothed air + hat activity for the big light effects
    V.p3=[c.wipe>=1.6?0:Math.max(wr,1e-4),c.build,c.brk,2*Math.round(Math.min(1,c.ai)*100)+Math.min(Math.max(c.df,0),.999)];
    V.p4=[A.fam,A.vs,c.ev?c.ev+Math.min(.999,Math.max(0,(V.trav-c.evS)/c.evD)):0,c.csN*4+Math.max(c.ramp,0)];
    V.p5=[B.fam,B.vs,tr,bl];
    V.m1=new Float32Array([...pl[0],...pl[1],...pl[2]]);
    V.m2=new Float32Array([...pl[3],...pl[4],...pl[5]]);
  }
  },
