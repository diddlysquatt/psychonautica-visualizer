  {
  key:'sol',name:'SOL 70',src:R_SOL,cost:1.25,cont:[],description:'superflat flower power',
  auto:{kal:[0,6,8,0,12,5,16],kalCycle:false,kalZoom:.75,tier:1,kind:'flat',bars:48,transitions:['shatter','melt','kaleido'],fx:{chroma:.25,bloom:.74},
    notes:'v12: folds re-rendered on 3 seeds (5 added: full flower star). v11: unfolded is the hero view (the realm runs its own hoop / flower-wave / fan transitions and card stunts); 6/8/12 make flower mandalas, 16 a fine rosette; 2/3/5 crop the big front flowers'},
  fb:{zoom:0,rot:0,decay:.1,warp:0,echo:0,droste:0,win:0,key:.08,live:.05},syms:[0,0,0,6,6,8,8,12,16,4],kalZoom:.75,
  init:s=>{
    const r=solRng(s[0]*.731+s[1]*.193+s[2]*.057+s[3]*.011);
    const A=solComp(r,Math.floor(s[1]*5)%5,0),pid=Math.floor(s[2]*solPals.length)%solPals.length;
    return {r,A,B:A,wipe:2,wipeSpd:1,bars:0,pd:0,k:0,sn:0,build:0,brk:0,df:0,csN:0,ramp:-1,blT:9,ev:0,evS:0,evD:8,evQ:0,unf:-1,
      mo:[0,0,0,0],wm:0,wmL:-1,wd:0,wT0:0,wt:0,wB:8,wpr:0,trv:0,syl:0,sylH:0,sylB:0,act:0,actH:0,pv:0,ph:0,pvT:0,phT:0,pid,pal:solPals[pid].map(c=>c.slice()),palT:1};
  },
  frame(V,F,dt){
    const c=V.c;c.trv=V.trav;
    // rare giant smiley face: per visit (engine realm time, which reseeds do not reset) and across visits (SOL clock)
    const G=solGF,Dg=typeof D!=='undefined'?D:null,cur=!Dg||V===Dg.cur;
    if(cur){G.clock+=dt;const rt=Dg?Dg.realmTime:G.clock;if(rt<G.rt-.5){G.done=false;G.thr=170+100*c.r();}G.rt=rt;}
    const ez=(x,t,k)=>x+(t-x)*Math.min(1,dt*k),sm=(a,b,x)=>{const t=Math.min(1,Math.max(0,(x-a)/(b-a)));return t*t*(3-2*t);};
    c.k=F.kick>c.k?ez(c.k,F.kick,30):ez(c.k,F.kick,7);
    c.build=ez(c.build,F.build,2.5);c.brk=ez(c.brk,F.breakdown||0,1.5);
    // singing: mouths open on syllables (band onsets with the broadband hits removed) and close to a smile between
    // phrases (a phrase gate that decays ~2 s after the last syllable). Front flowers sing the lead (low-mid..presence),
    // the next layer the harmony (presence/high), the small ones the bassline, the carpet twinkles with the air.
    const L=BANDS.lv,O=BANDS.on;let om=0;for(let i=0;i<8;i++)om+=O[i];om/=8;
    const dr=Math.max(O[0],O[1],Math.min(O[2],O[6],O[7])),vo=Math.max(0,Math.max(O[3],O[4])-.9*dr-.3*om),vh=Math.max(0,O[5]-.9*dr-.3*om),vb=Math.max(0,O[1]-.8*om);
    // a syllable candidate waits ~70 ms and is dropped if a drum onset (sub/bass/high/air) follows: kicks and snares
    // light the mid bands a frame before their low/high bands
    if(dr>.45){c.pv=0;c.ph=0;}
    if(vo>.18&&!c.pvT){c.pv=vo;c.pvT=.07;}if(vh>.18&&!c.phT){c.ph=vh;c.phT=.07;}
    if(c.pvT){c.pvT=Math.max(0,c.pvT-dt);if(!c.pvT&&c.pv>0){c.syl=Math.max(c.syl,.5+.5*Math.min(1,c.pv*1.6));c.act=Math.min(1.4,c.act+.4);}}
    if(c.phT){c.phT=Math.max(0,c.phT-dt);if(!c.phT&&c.ph>0){c.sylH=Math.max(c.sylH,.45+.5*Math.min(1,c.ph*1.6));c.actH=Math.min(1.4,c.actH+.4);}}
    if(vb>.25)c.sylB=Math.max(c.sylB,.4+.5*Math.min(1,vb*1.5));
    const e1=Math.exp(-dt*5.5);c.syl*=e1;c.sylH*=e1;c.sylB*=Math.exp(-dt*7);c.act*=Math.exp(-dt*1.1);c.actH*=Math.exp(-dt*1.1);
    const g=sm(.15,.55,c.act),gH=sm(.15,.55,c.actH),voc=Math.max(L[3],L[4],L[5]);
    const tg=[.6*L[7],c.sylB,gH*Math.max(c.sylH,.22*L[5]),g*Math.max(c.syl,.25*voc)];
    for(let i=0;i<4;i++){const t=Math.min(1,tg[i])*(1-.5*c.brk);c.mo[i]=t>c.mo[i]?ez(c.mo[i],t,25):ez(c.mo[i],t,12);}
    // snare: a wave of colour steps sweeps the field (every flower's petals step round by one palette colour)
    if(F.onHit){c.sn=1;if(c.ramp>=0)c.csN=(c.csN+1)%6;c.ramp=0;}
    if(c.ramp>=0){c.ramp+=dt*2.6;if(c.ramp>=2){c.csN=(c.csN+1)%6;c.ramp=-1;}}
    c.sn*=Math.exp(-dt*7);
    // drops: new composition and palette, revealed by a neon ring wipe; flowers spin a full turn; kaleidoscope burst or giant face
    const drop=F.onDrop||F.drop>c.pd+.4;c.pd=F.drop;
    if(drop){solNext(c,true,true);c.df=1;}
    // phrases: new palette/variant every 8 bars, new family every 16, a synchronised blink every 4.
    // Surprise events sweep the field; builds call the chorus; giant faces arrive on phrases and after drops.
    if(c.ev&&(V.trav-c.evS)/c.evD>=1)c.ev=0;
    if(!c.ev&&c.build>.55&&c.wipe>=1.6)solStartEv(c,3,V.trav);
    if(!c.ev&&c.evQ&&c.wipe>=1.6){solStartEv(c,c.evQ,V.trav);c.evQ=0;}
    if((F.onBar || F.onSceneBar)){c.bars++;
      if(!c.ev&&cur&&!G.done&&G.rt>=G.thr&&G.clock-G.last>=480&&c.wipe>=1.6&&c.bars%4===1){solStartEv(c,5,V.trav);G.done=true;G.last=G.clock;}
      else if(!c.ev&&c.bars%8===5&&(c.r()<.6||c.bars<8)){const P=solEvPool[c.B.fam];solStartEv(c,P[Math.floor(c.r()*P.length)],V.trav);}
      else if(!c.ev&&c.bars%16===10&&c.r()<.45)solStartEv(c,[8,9,10,13][Math.floor(c.r()*4)],V.trav);
      if(c.bars%8===0)solNext(c,c.bars%16===0,false);else if(c.unf>=0&&c.bars>=c.unf&&c.wipe>=1.6)solUnfold(c);
      if(c.bars%4===3)c.blT=0;}
    // the hoop runs on its own clock; the flower wave and the fan are beat-locked (one step / one blade per beat), with a
    // time fallback so they still finish when the music stops
    if(c.wipe<2){if(c.wm){c.wt+=dt;c.wpr=Math.min(1,Math.max((V.trav-c.wT0)/c.wB,c.wt/(c.wB*.9)));c.wipe=c.wpr>=1?2:1.6*c.wpr;}
      else c.wipe=Math.min(2,c.wipe+dt*c.wipeSpd);}
    if(c.wipe>=1.6)c.A=c.B;
    c.df*=Math.exp(-dt*1.6);
    c.blT+=dt;const bl=c.blT<.22?Math.sin(Math.PI*c.blT/.22):0;
    // palette: ease toward the target colours (a drop snaps it under the flash)
    const P=solPals[c.pid];c.palT=Math.min(1,c.palT+dt*.8);
    const kp=c.palT>=1?1:Math.min(1,dt*(1.5+6*c.df));
    for(let i=0;i<6;i++)for(let j=0;j<3;j++)c.pal[i][j]+=(P[i][j]-c.pal[i][j])*(c.df>.5?1:kp);
    const w=Math.min(1,c.wipe),wr=c.wipe>=1.6?0:(1-(1-w)*(1-w))*1.35;
    const A=c.A,B=c.B,pl=c.pal;
    // v12: the bassline breathes the back layers (smoothed: >= 80 ms attack, 260 ms release, slower with Motion smoothness)
    {const ms=Math.min(1,Math.max(0,S.motionSmooth!=null?S.motionSmooth:.75)),bt=Math.min(1,Math.max(L[0],L[1]));c.bs=c.bs||0;c.bs=ez(c.bs,bt,(bt>c.bs?12:3.8)*(1-.4*ms));}
    // hat activity: each hat adds, a 0.45 s release keeps the sparkle field alive through a hat pattern (light only)
    c.ha=Math.max((c.ha||0)*Math.exp(-dt/.45),Math.min(1,(F.hat||0)*1.2,1),O[6]*.9,O[7]);
    V.p1=[V.trav%3840,V.mt%628.3185,c.k,2*Math.round(Math.min(1,c.ha)*100)+Math.min(c.bs,.999)];
    // v18 smooth drivers (exact exponential steps, stable at any dt): mids, kick, the dance fade, the kick shockwave
    const ex=(x,t,k)=>x+(t-x)*(1-Math.exp(-dt*k)),ms2=Math.min(1,Math.max(0,S.motionSmooth!=null?S.motionSmooth:.75)),slow=1-.4*ms2;
    c.mS=ex(c.mS||0,Math.min(1,Math.max(L[2],L[3])),(Math.max(L[2],L[3])>(c.mS||0)?12:3.8)*slow);
    c.kS=ex(c.kS||0,Math.min(1,F.kick),(F.kick>(c.kS||0)?14:4.5)*slow);
    // dance: a new kind every 4 bars (fades out, swaps, fades in), its depth rides the band that suits it (5 kinds + 6 hop-along)
    const dPick=b=>1+Math.floor((Math.sin((b+1)*91.73+c.A.vs*417)*43758.5453%1+1)%1*8);if(c.dn==null){c.dn=dPick(0);c.dN=c.dn;c.dF=0;c.dB=-1;}
    if(c.bars!==c.dB){c.dB=c.bars;if(c.bars%4===0){let n=dPick(c.bars);if(n===c.dn)n=1+n%8;c.dN=n;}}
    c.dF=ex(c.dF,c.dN===c.dn?1:0,c.dN===c.dn?2.2:5);if(c.dN!==c.dn&&c.dF<.03){c.dn=c.dN;c.dF=0;}
    const dk=c.dn,dEn=dk===2||dk===3?c.bs||0:dk===4||dk===7||dk===8?Math.max(c.kS,.35*(c.bs||0)):c.mS;
    const dAm=Math.min(1,c.dF*(.45+.75*dEn)*(1-.7*c.brk));   // v20: every dance is a punch now (no sway), so they all rest at the same depth
    c.hpA=ex(c.hpA||0,Math.min(1,(.3+.5*(c.bs||0))*(1-.7*c.brk)+(dk===6?.55*c.dF:0)),3);
    // kick shockwave: one ring at a time; its strength is a sin^2 of its travel, so it is born and dies at zero
    const SR=.95;c.sr=c.sr==null?SR:c.sr;c.sr=Math.min(SR,c.sr+dt*2.1);if(F.onKick&&c.sr>=.82*SR){c.sr=0;c.sA=Math.max(.45,Math.min(1,F.kick));}
    const sE=(c.sA||0)*Math.pow(Math.sin(Math.PI*c.sr/SR),2)*(1-.7*c.brk);
    V.p2=[Math.round(c.mo[0]*100)+Math.min(.999,c.sr),Math.round(c.mo[1]*100)+Math.min(.999,sE),Math.round(c.mo[2]*100)+Math.min(.999,c.mS),Math.round(c.mo[3]*100)+Math.min(.999,c.sn)];   // v20: fractions carry the smoothed mids and the snare flash
    c.dnP=[c.dn,dAm];
    {const at=Math.min(1,Math.max(BANDS.lv[7],.8*(c.ha||0)));c.ai=c.ai||0;c.ai+=(at-c.ai)*Math.min(1,dt*(at>c.ai?9:2.8));}   // v13: smoothed air + hat activity for the big light effects
    V.p3=[c.wipe>=1.6?0:Math.max(c.wm?c.wpr:wr,1e-4),2*c.dnP[0]+Math.min(c.build,.999),2*Math.round(c.dnP[1]*100)+Math.min(c.brk,.999),2*Math.round(Math.min(1,c.ai)*100)+Math.min(Math.max(c.df,0),.999)];
    V.p4=[A.fam+8*(A.kf||0),A.vs,c.ev?c.ev+Math.min(.999,Math.max(0,(V.trav-c.evS)/c.evD)):0,c.csN*4+Math.max(c.ramp,0)];
    V.p5=[B.fam+8*(B.kf||0),B.vs,c.wm+4*c.wd,2*Math.round(c.hpA*100)+Math.min(bl,.999)];
    V.m1=new Float32Array([...pl[0],...pl[1],...pl[2]]);
    V.m2=new Float32Array([...pl[3],...pl[4],...pl[5]]);
  }
  },
