  {
  key:'umi',name:'UMI POP',src:R_UMI,cost:1.2,cont:[],description:'superflat singing sea',
  fb:{zoom:0,rot:0,decay:.1,warp:0,echo:0,droste:0,win:0,key:.08,live:.05},syms:[0,0,0,12,12,8,8,6,16,3],kalZoom:.7,
  auto:{kal:[0,12,8,6,16,5],kalCycle:true,kalZoom:.7,transitions:['kaleido','portal','vortex'],notes:'v12: 5 replaces 3 (3 splits the big front characters; 5 makes a full reef star). Unfolded is the hero view (schools, giant fish made of fish when zoomed out); 12 makes a bubble-ring mandala, 8/6 full reef mandalas, 16 a fine fish rosette in the whirlpool; 2/4/5 crop the big front characters'},
  init:s=>{
    const r=umiRng(s[0]*.731+s[1]*.193+s[2]*.057+s[3]*.011);
    const A=umiComp(r,Math.floor(s[1]*4)%4),pid=Math.floor(s[2]*umiPals.length)%umiPals.length;
    return {r,A,B:A,wipe:2,wipeSpd:1,bars:0,pd:0,k:0,sn:0,build:0,brk:0,df:0,csN:0,ramp:-1,blT:9,ev:0,evS:0,evD:8,evQ:0,ext:0,lt:-1,
      mo:[0,0,0,0],syl:0,sylH:0,sylB:0,act:0,actH:0,pv:0,ph:0,pvT:0,phT:0,pid,pal:umiPals[pid].map(c=>c.slice()),palT:1};
  },
  frame(V,F,dt){
    const c=V.c,ez=(x,t,k)=>x+(t-x)*Math.min(1,dt*k),sm=(a,b,x)=>{const t=Math.min(1,Math.max(0,(x-a)/(b-a)));return t*t*(3-2*t);};
    const ms=Math.min(1,Math.max(0,(typeof S!=='undefined'&&S.motionSmooth!=null)?S.motionSmooth:.5));
    // kick envelope drives geometry (puffers, front scale): >=60 ms attack, >=200 ms release, softer with motion smoothing
    c.k=F.kick>c.k?ez(c.k,F.kick,16*(1-.5*ms)):ez(c.k,F.kick,5*(1-.5*ms));
    c.build=ez(c.build,F.build,2.5);c.brk=ez(c.brk,F.breakdown||0,1.5);
    // builds swim faster: extra distance accumulates continuously (never a jump)
    if(c.lt<0)c.lt=V.trav;const dtr=Math.max(0,Math.min(1,V.trav-c.lt));c.lt=V.trav;c.ext=c.ext+dtr*1.2*c.build;
    // singing: mouths open on syllables (band onsets with the broadband drum hits removed) and close to a smile
    // between phrases. Front characters sing the lead, the next layer the harmony, small ones the bassline, the carpet the air.
    const L=BANDS.lv,O=BANDS.on;let om=0;for(let i=0;i<8;i++)om+=O[i];om/=8;
    const dr=Math.max(O[0],O[1],Math.min(O[2],O[6],O[7])),vo=Math.max(0,Math.max(O[3],O[4])-.9*dr-.3*om),vh=Math.max(0,O[5]-.9*dr-.3*om),vb=Math.max(0,O[1]-.8*om);
    if(dr>.45){c.pv=0;c.ph=0;}
    if(vo>.18&&!c.pvT){c.pv=vo;c.pvT=.07;}if(vh>.18&&!c.phT){c.ph=vh;c.phT=.07;}
    if(c.pvT){c.pvT=Math.max(0,c.pvT-dt);if(!c.pvT&&c.pv>0){c.syl=Math.max(c.syl,.5+.5*Math.min(1,c.pv*1.6));c.act=Math.min(1.4,c.act+.4);}}
    if(c.phT){c.phT=Math.max(0,c.phT-dt);if(!c.phT&&c.ph>0){c.sylH=Math.max(c.sylH,.45+.5*Math.min(1,c.ph*1.6));c.actH=Math.min(1.4,c.actH+.4);}}
    if(vb>.25)c.sylB=Math.max(c.sylB,.4+.5*Math.min(1,vb*1.5));
    const e1=Math.exp(-dt*5.5);c.syl*=e1;c.sylH*=e1;c.sylB*=Math.exp(-dt*7);c.act*=Math.exp(-dt*1.1);c.actH*=Math.exp(-dt*1.1);
    const g=sm(.15,.55,c.act),gH=sm(.15,.55,c.actH),voc=Math.max(L[3],L[4],L[5]);
    const tg=[.6*L[7],c.sylB,gH*Math.max(c.sylH,.22*L[5]),g*Math.max(c.syl,.25*voc)];
    for(let i=0;i<4;i++){const t=Math.min(1,tg[i])*(1-.5*c.brk);c.mo[i]=t>c.mo[i]?ez(c.mo[i],t,25):ez(c.mo[i],t,12);}
    // snare: a wave of colour steps sweeps out from the centre (every character steps one palette colour)
    if(F.onHit){c.sn=1;if(c.ramp>=0)c.csN=(c.csN+1)%6;c.ramp=0;}
    if(c.ramp>=0){c.ramp+=dt*2.6;if(c.ramp>=2){c.csN=(c.csN+1)%6;c.ramp=-1;}}
    c.sn*=Math.exp(-dt*7);
    // drops: a new sea rolls in behind a fast wave front, everything spins a full turn, often the giant octopus
    const drop=F.onDrop||F.drop>c.pd+.4;c.pd=F.drop;
    if(drop){umiNext(c,true,true);c.df=1;}
    // phrases: new palette/variant every 8 bars, new family every 16, a synchronised blink every 4; events
    if(c.ev&&(V.trav-c.evS)/c.evD>=1)c.ev=0;
    if(!c.ev&&c.build>.55&&c.wipe>=1)umiStartEv(c,3,V.trav);
    if(!c.ev&&c.evQ&&c.wipe>=1){umiStartEv(c,c.evQ,V.trav);c.evQ=0;}
    if((F.onBar || F.onSceneBar)){c.bars++;
      if(!c.ev&&c.bars%8===5&&(c.r()<.65||c.bars<8))umiStartEv(c,umiEvPool[Math.floor(c.r()*umiEvPool.length)],V.trav);
      else if(!c.ev&&c.bars%16===10&&c.r()<.5)umiStartEv(c,4,V.trav);
      if(c.bars%8===0)umiNext(c,c.bars%16===0,false);
      if(c.bars%4===3)c.blT=0;}
    if(c.wipe<2)c.wipe=Math.min(2,c.wipe+dt*c.wipeSpd);
    if(c.wipe>=1)c.A=c.B;
    c.df*=Math.exp(-dt*1.6);
    c.blT+=dt;const bl=c.blT<.22?Math.sin(Math.PI*c.blT/.22):0;
    const P=umiPals[c.pid];c.palT=Math.min(1,c.palT+dt*.8);
    const kp=c.palT>=1?1:Math.min(1,dt*(1.5+6*c.df));
    for(let i=0;i<6;i++)for(let j=0;j<3;j++)c.pal[i][j]+=(P[i][j]-c.pal[i][j])*(c.df>.5?1:kp);
    const w=Math.max(0,Math.min(1,c.wipe)),we=w*w*(3-2*w),xf=c.wipe>=1?9:-1.45+2.9*we;
    const A=c.A,B=c.B,pl=c.pal,tr=V.trav%3840;
    // v12: the bassline breathes the back schools (smoothed: >= 80 ms attack, 260 ms release, slower with Motion smoothness)
    {const bt=Math.min(1,Math.max(L[0],L[1]));c.bs=c.bs||0;c.bs=ez(c.bs,bt,(bt>c.bs?12:3.8)*(1-.4*ms));}
    // hat activity: each hat adds, a 0.45 s release keeps the sparkle field alive through a hat pattern (light only)
    c.ha=Math.max((c.ha||0)*Math.exp(-dt/.45),Math.min(1,(F.hat||0)*1.2),O[6]*.9,O[7]);
    // v13: the chords (low-mid / mid) swell and lift the middle layers (smoothed: >= 90 ms attack, 300 ms release)
    {const lt=Math.min(1,1.3*Math.max(L[2],L[3]));c.lm=c.lm||0;c.lm=ez(c.lm,lt,(lt>c.lm?11:3.3)*(1-.4*ms));}
    V.p1=[tr+c.ext,V.mt%628.3185,c.k,256*Math.round(Math.min(1,c.lm)*99)+2*Math.round(Math.min(1,c.ha)*100)+Math.min(c.bs,.999)];
    V.p2=c.mo.slice();
    {const at=Math.min(1,Math.max(BANDS.lv[7],.6*(c.ha||0)));c.ai=c.ai||0;c.ai+=(at-c.ai)*Math.min(1,dt*(at>c.ai?9:2.8));}   // v13: smoothed air + hat activity for the big light effects
    V.p3=[xf,c.build,c.brk,2*Math.round(Math.min(1,c.ai)*100)+Math.min(Math.max(c.df,0),.999)];
    V.p4=[A.fam,A.vs,c.ev?c.ev+Math.min(.999,Math.max(0,(V.trav-c.evS)/c.evD)):0,c.csN*4+Math.max(c.ramp,0)];
    V.p5=[B.fam,B.vs,tr,bl];
    V.m1=new Float32Array([...pl[0],...pl[1],...pl[2]]);
    V.m2=new Float32Array([...pl[3],...pl[4],...pl[5]]);
  }
  },
