  {
  key:'petri',name:'DIAT0M',src:R_PETRI,cost:1.3,motionLP:1,cont:[],description:'psychedelic living microscope slide',
  fb:{zoom:0,rot:0,decay:.1,warp:0,echo:0,droste:0,win:0,key:.08,live:.05},syms:[0,0,0,12,12,16,16,8,6],kalZoom:.7,
  auto:{kal:[0,12,16,8,6],kalCycle:true,kalZoom:.7,transitions:['portal','kaleido','melt'],kind:'flat',notes:'unfolded is the hero view (a living slide: streaming cytoplasm, beating cilia, dividing cells, a free swimmer); when a fold turns on the realm re-arranges into its MANDALA family, rose windows of whole organisms at 12 and 16 (best), 8 and 6; 2-5 cut organisms and the swimmer at the wedge edge'},
  init:s=>{
    const r=petriRng(s[0]*.731+s[1]*.193+s[2]*.057+s[3]*.011);
    const A=petriComp(r,Math.floor(s[1]*3)%3),sid=Math.floor(s[2]*petriStains.length)%petriStains.length,P=petriStains[sid];
    return {r,A,B:A,wipe:2,wipeSpd:1,bars:0,pd:0,k:0,hi:0,ht:0,hph:0,sn:0,build:0,brk:0,df:0,csN:0,ramp:-1,ev:0,evS:0,evD:8,evQ:0,
      ext:0,lt:-1,mag:1,md:0,sph:0,bs:0,pr:0,magV:0,magT:1,sid,palT:1,bg:P.bg.slice(),oc:P.oc,pal:P.j.map(c=>c.slice())};
  },
  frame(V,F,dt){
    const c=V.c,ez=(x,t,k)=>x+(t-x)*(1-Math.exp(-dt*k));
    const ms=Math.min(1,Math.max(0,(typeof S!=='undefined'&&S.motionSmooth!=null)?S.motionSmooth:.5));
    const L=BANDS.lv,O=BANDS.on;
    // kick envelope (colony pulse, rosette pump): >=60 ms attack, >=200 ms release, softer with Motion smoothness
    c.k=F.kick>c.k?ez(c.k,F.kick,16*(1-.5*ms)):ez(c.k,F.kick,5*(1-.5*ms));
    // high envelope extends the radiolarian spines (geometry, so smoothed like the kick)
    const ht=Math.min(1,Math.max(L[6],L[7]));c.hi=ht>c.hi?ez(c.hi,ht,10*(1-.5*ms)):ez(c.hi,ht,3*(1-.5*ms));
    c.build=ez(c.build,F.build,2.5);c.brk=ez(c.brk,F.breakdown||0,1.5);
    // cilia: the hats beat them (a smooth phase, never a jump; the beat amplitude and the spine sparkle follow the
    // hat envelope)
    const hv=Math.min(1,F.hat||0);c.ht=hv>c.ht?ez(c.ht,hv,16):ez(c.ht,hv,5);c.hph=(c.hph+dt*(.3+2.4*c.ht)*(1-.5*c.brk))%1000;
    // the bassline swells membranes, nuclei and vacuoles; the presence band (vocals, leads) lights the wheels'
    // outer panels and extends the star pseudopods; the mids stream the cytoplasm (a phase that runs faster with them)
    const sm=1-.5*ms,bv=L[1],pv=Math.max(L[4],L[5]),mv=Math.max(L[2],L[3]);
    c.bs=bv>c.bs?ez(c.bs,bv,14*sm):ez(c.bs,bv,4*sm);c.pr=pv>c.pr?ez(c.pr,pv,12*sm):ez(c.pr,pv,3.5*sm);
    c.md=mv>c.md?ez(c.md,mv,10):ez(c.md,mv,3);c.sph=(c.sph+dt*(.12+1.5*c.md)*(1-.4*c.brk))%1000;
    // builds drift faster: extra distance accumulates continuously
    if(c.lt<0)c.lt=V.trav;const dtr=Math.max(0,Math.min(1,V.trav-c.lt));c.lt=V.trav;c.ext=(c.ext+dtr*1.2*c.build)%3840;
    // snare: a colour-step wave sweeps outward from the centre (every organism steps one jewel colour)
    if(F.onHit){c.sn=1;if(c.ramp>=0)c.csN=(c.csN+1)%18;c.ramp=0;}
    if(c.ramp>=0){c.ramp+=dt*2.6;if(c.ramp>=2){c.csN=(c.csN+1)%18;c.ramp=-1;}}
    c.sn*=Math.exp(-dt*7);
    // drops: a new stain floods the slide behind a fast membrane front (the cells ahead of it divide)
    const drop=F.onDrop||F.drop>c.pd+.4;c.pd=F.drop;
    const fold=petriFold(V);
    if(drop&&c.wipe>=1.6){petriNext(c,true,true,fold);c.wipeSpd=.55;c.df=.5;}
    // a fold switched on: the slide re-arranges itself into the mandala within a beat or two
    if(fold>1&&c.B.fam!==1&&c.wipe>=1.6&&!c.fw){c.fw=1;c.B={fam:1,vs:c.r()};c.wipe=0;c.wipeSpd=.9;}
    if(fold<=1)c.fw=0;
    if(c.ev&&(V.trav-c.evS)/c.evD>=1)c.ev=0;
    if(!c.ev&&c.evQ&&c.wipe>=1.6){petriStartEv(c,c.evQ,V.trav);c.evQ=0;}
    // phrases: new slide every 8 bars (family every 16), a magnification change (focus pull) every 8 bars offset by 4,
    // a surprise event about every 8 bars
    if((F.onBar || F.onSceneBar)){c.bars++;
      if(!c.ev&&c.bars%8===5&&(c.r()<.7||c.bars<8))petriStartEv(c,petriEvPool[Math.floor(c.r()*petriEvPool.length)],V.trav);
      if(c.bars%8===0)petriNext(c,c.bars%16===0,false,fold);
      if(c.bars%8===4){const M=[.72,.9,1.12,1.32];let t=M[Math.floor(c.r()*4)];if(Math.abs(t-c.magT)<.05)t=M[(M.indexOf(t)+2)%4];c.magT=t;}}
    if(c.wipe<2)c.wipe=Math.min(2,c.wipe+dt*c.wipeSpd);
    if(c.wipe>=1.6)c.A=c.B;
    c.df*=Math.exp(-dt*1.6);
    // magnification: a critically damped spring (the focus pull), stiffer when Motion smoothness is low
    const wM=1.9*(1.25-.5*ms),mT=c.magT*(1+.06*c.build),err=c.mag-mT,j=c.magV+wM*err,dec=Math.exp(-wM*dt);
    c.mag=mT+(err+j*dt)*dec;c.magV=(c.magV-wM*j*dt)*dec;
    const P=petriStains[c.sid];c.palT=Math.min(1,c.palT+dt*.8);
    const kp=c.palT>=1?1:Math.min(1,dt*(1.5+6*c.df));
    for(let i=0;i<6;i++)for(let j=0;j<3;j++)c.pal[i][j]+=(P.j[i][j]-c.pal[i][j])*(c.df>.5?1:kp);
    for(let j=0;j<3;j++)c.bg[j]+=(P.bg[j]-c.bg[j])*(c.df>.5?1:kp);
    if(c.palT>.5||c.df>.5)c.oc=P.oc;
    const w=Math.min(1,c.wipe),wr=c.wipe>=1.6?0:(1-(1-w)*(1-w))*1.35;
    c.driftRate=ez(c.driftRate??1.2,Math.min(4,dtr/Math.max(dt,.001)),2);
    c.drift=(c.drift??V.trav)+c.driftRate*dt;
    const A=c.A,B=c.B,pl=c.pal,tr=c.drift%3840;
    V.p1=[tr+c.ext,c.hph,c.k*(1-.4*c.brk),c.sph];
    V.p2=[c.bg[0],c.bg[1],c.bg[2],c.oc];
    {const at=Math.min(1,Math.max(BANDS.lv[7],.8*(c.ht||0)));c.ai=c.ai||0;c.ai+=(at-c.ai)*Math.min(1,dt*(at>c.ai?9:2.8));}   // v13: smoothed air + hat activity for the big light effects
    V.p3=[c.wipe>=1.6?0:Math.max(wr,1e-4),c.bs,Math.min(c.hi+.7*c.build,1.2),2*Math.round(Math.min(1,c.ai)*100)+Math.min(Math.max(c.df,0),.999)];
    V.p4=[A.fam+A.vs*.999,c.ht,c.ev?c.ev+Math.min(.999,Math.max(0,(V.trav-c.evS)/c.evD)):0,c.csN*4+(c.ramp>=0?c.ramp:3)];
    V.p5=[B.fam+B.vs*.999,c.pr,tr,c.mag];
    // (each jewel is lifted a touch toward its own grey here, once, instead of per lookup in the shader)
    const jw=i=>{const x=pl[i],g=.04*.33*(x[0]+x[1]+x[2])+.02;return [x[0]*.95+g,x[1]*.95+g,x[2]*.95+g];};
    V.m1=new Float32Array([...jw(0),...jw(1),...jw(2)]);
    V.m2=new Float32Array([...jw(3),...jw(4),...jw(5)]);
  }
  },
