{
  key:'tess',name:'TESS4',src:R_TESS,cost:2.0,cont:['dW','hueN'],description:'neon four-dimensional wireframes',kalZoom:.7,
  fb:{zoom:0,rot:0,decay:.28,warp:0,echo:.06,droste:0,win:0,key:.12,live:.2},syms:[0,0,0,6,6,8,8,12,16,5,4,3],
  auto:{kal:[6,8,0,12,5,4,16],kalCycle:true,kalZoom:.7,tier:2,kind:'3d',bars:32,transitions:['kaleido','vortex'],fx:{warp:.3},notes:'v12 re-checked (v12/b0_kal, 3 seeds x 2 times): every fold 3-16 is a full neon mandala; 6/8/12 best, 5/4/16 good, 3 fine; 2 lopsided; unfolded shows the 4D motion best'},
  // formations: 0 NEST, 1 CORE, 2 GRID, 3 FLY (honeycomb fly-through)
  init:(s)=>{
    const h=(k)=>{const x=Math.sin((s[0]*12.9898+s[1]*78.233+s[2]*37.719+s[3]*4.581+k*1.618)*43758.5453);return x-Math.floor(x);};
    const pal=tessPalW[Math.floor(s[2]*tessPalW.length)%tessPalW.length];
    const M=[1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1];for(let i=0;i<6;i++)tessGivens(M,i,h(30+i)*6.283);
    const mode=Math.floor(h(4)*tessModes.length)%tessModes.length;
    return {
      form:[0,1,1,2,3,1,0,3][Math.floor(s[0]*8)%8],set:tessSets[Math.floor(s[1]*tessSets.length)%tessSets.length],pal,palB:pal,pm:1,
      dW:1.75+s[3]*.6,hueN:(h(1)-.5)*.5,ringN:[5,6,6,8][Math.floor(h(2)*4)],layout:h(3)<.5?0:1,
      M,mode,sg:[0,1,2,3,4,5].map(i=>h(5+i)<.3?-1:1),rs:.85+.35*h(11),rt:tessModes[mode].r.slice(),kp:[0,0],kn:0,oc:0,
      colT:[0,2,1,7,0,2,8][Math.floor(h(12)*7)%7],
      tw:[(h(16)-.5)*.9,h(17)*6.283],tu:0,ke:0,snT:9,fl:0,hp:0,exT:9,exAmp:0,pend:null,cloud:0,nz:h(18)*8,gs:0,br:1,bu:0,lt:null,
      lay:Math.floor(h(19)*3)%3,side:h(20)<.5?-1:1,hx:0,hy:0,twin:0,zI:1,vista:0,wp:0,bE:0,
      src:[.5,.5,.5,.5],dbg:0,dbgB:0,uT:99,unf:0,fP:0
    };
  },
  frame(V,F,dt){
    const c=V.c,BL=(typeof BANDS!=='undefined')?BANDS.lv:null;
    // v11 music: the auto-ranged bands say how a band moves, not how much of it there is, and read full in silence.
    // Each is weighted by its share of the spectrum and gated by the engine's silence detector, then smoothed
    // (70 ms attack, 250 ms release): sb[0..7] = sub .. air. Bass turns the 4D rotation and breathes the 4D
    // perspective, mids light the nested shells, highs/air throw the vertex sparks and light trains.
    const idle=clamp(F.idle||0,0,1),BF=BL&&BANDS.fast?BANDS.fast:null;
    if(!c.sb)c.sb=new Array(8).fill(0);
    let fm=1e-3;if(BF)for(let i=0;i<8;i++)fm=Math.max(fm,BF[i]*(1+.12*i));
    for(let i=0;i<8;i++){const sh=BF?clamp(BF[i]*(1+.12*i)/fm,0,1):1,t=(BL?BL[i]:0)*(.2+.8*Math.pow(sh,1.3))*(1-idle);c.sb[i]=ease(c.sb[i],t,dt,t>c.sb[i]?.07:.25);}
    const b0=.55*c.sb[0]+.45*c.sb[1];
    // v18: the shaped bands sit near their ceiling all song (p50 .85, p90 .91 on the demo), so anything they drive looked
    // constant. What the eye reads is the movement: sx = each band's excursion above its own 1.8 s average, re-centred,
    // gated on the average so silence stays at zero.
    if(!c.sM){c.sM=new Array(8).fill(0);c.sx=new Array(8).fill(0);}
    for(let i=0;i<8;i++){c.sM[i]=ease(c.sM[i],c.sb[i],dt,1.8);const x=clamp(.42+2.6*(c.sb[i]-c.sM[i]),0,1)*clamp(c.sM[i]*5,0,1);c.sx[i]=ease(c.sx[i],x,dt,x>c.sx[i]?.08:.26);}
    c.act=ease(c.act===undefined?.3:c.act,lerp(clamp(.2+1.5*(F.levelS!==undefined?F.levelS:F.level||0),.2,1),.15,idle),dt,.6);
    // CORE layout targets: 0 centred hero (gentle drift), 1 mirrored twins, 2 off-centre hero; FLY drifts its vanishing point
    const layT=()=>c.form===2?[.035*Math.sin(V.trav*.06),.025*Math.sin(V.trav*.08+2),0]:c.form===3?[.07*Math.sin(V.trav*.05),.05*Math.sin(V.trav*.07+1),0]:
      [c.lay===2?.27*c.side+.03*Math.sin(V.trav*.09):c.lay===0?.045*Math.sin(V.trav*.11):0,c.lay===1?0:.03*Math.sin(V.trav*.07+1),c.lay===1?1:0];
    if(c.lt===null){c.lt=V.trav;const t=layT();c.hx=t[0];c.hy=t[1];c.twin=t[2];}
    const dTr=clamp(V.trav-c.lt,0,.5);c.lt=V.trav;
    const bps=(F.bpm>0?F.bpm:120)/60,TAU=6.283185;
    c.bu=ease(c.bu,Math.max(F.build||0,c.dbgB||0),dt,.5);
    const calm=F.breakdown||0;
    // bass (sub + bass bands, smoothed) drives the 4D rotation speed and the breathing; builds accelerate, breakdowns calm
    c.bE=ease(c.bE,b0,dt,.12);
    const uOn=c.uT<11.5&&c.form!==0,spin=(1+2.4*c.bu)*(1-.5*calm)*(.15+.3*c.act+1.25*c.bE)*(uOn?Math.max(0,1-c.uT/1.5)*(1-c.unf):1);
    // the 4D rotation is integrated as a matrix, so a phrase can change the rotation planes without any jump:
    // the plane rates ease to the new choreography over about a beat
    const md=tessModes[c.mode],pend=md.pend?Math.cos(V.trav*Math.PI/8):1;
    for(let i=0;i<6;i++){c.rt[i]=ease(c.rt[i],md.r[i]*c.sg[i]*c.rs*pend,dt,.6/bps);tessGivens(c.M,i,dTr*c.rt[i]*spin);}
    // kick: a smoothed rotation impulse, alternating between the choreography's two kick planes
    if(F.onKick){c.kp[c.kn++%2]+=.3+.22*Math.min(1,F.kick||1);c.ke=1;c.kf=(c.kf===undefined?0:c.kf+1+(rand()<.3?1:0))%4;}
    // two cascaded smoothings: the kick's rotation speed ramps up over ~70 ms instead of jumping (no jerk)
    const kf=1-Math.exp(-dt*9),kr=1-Math.exp(-dt*14);if(!c.kq)c.kq=[0,0];
    for(let q=0;q<2;q++){const m=c.kp[q]*kr;c.kp[q]-=m;c.kq[q]+=m;const d=c.kq[q]*kf;c.kq[q]-=d;tessGivens(c.M,md.k[q],d*c.sg[md.k[q]]);}
    // unfold: the w axis settles back onto the eye axis (the classic cube-in-cube view), so the net opens flat in 3D and
    // turns there; it keeps a gentle 3D spin while it is open
    if(uOn){tessUntwist(c.M,1-Math.exp(-dt*bps*1.6));tessGivens(c.M,1,dTr*.22*c.unf);tessGivens(c.M,3,dTr*.13*c.unf);}
    if(++c.oc>=30){c.oc=0;tessOrtho(c.M);}
    c.ke*=Math.exp(-dt*7);
    // snare: a flash front sweeps across the 4D body from a random direction
    if(F.onHit){c.snT=-.15;c.fl=1;const v=[rand()-.5,rand()-.5,rand()-.5,rand()-.5],l=Math.hypot(...v)||1,sg=v[3]<0?-1:1;c.src=v.map(x=>sg*x/l);}
    c.snT=Math.min(c.snT+dt*bps*2.4,9);c.fl*=Math.exp(-dt*3.2);
    c.hp=(c.hp+dTr*2)%1000;
    // bass breathes the 4D perspective (a nearer 4D eye swells the inner cell through the outer one), spring-smoothed
    {const tg=c.dW*(1-.22*c.bE*(1-.5*calm)),w=7,v=c.dWv||0,x=(c.dWe??c.dW)-tg;
      const e=Math.exp(-w*dt),j=v+w*x;c.dWe=tg+(x+j*dt)*e;c.dWv=(v-w*j*dt)*e;}
    c.br=ease(c.br,1+.16*(.55*c.sx[0]+.45*c.sx[1])-.06*c.bu,dt,.1);
    // v18 kick body: each kick loads an envelope (140 ms decay, 200+ ms settled through the spring) that a critically damped spring follows (attack ~80 ms),
    // so the whole polytope pumps and its edges burst apart on the beat and settle smoothly; exact step, stable at any dt
    if(F.onKick)c.kB=Math.max(c.kB||0,.55+.45*Math.min(1,F.kick||1));c.kB=(c.kB||0)*Math.exp(-dt/.14);
    tessSpring(c,'kS',c.kB,lerp(36,18,clamp(S.motionSmooth??.75,0,1)),dt);
    // two kick shockwaves in flight (light only); age 0..1 over about 0.9 s
    if(!c.sk){c.sk=[1,1];c.skn=0;}if(F.onKick)c.sk[c.skn++%2]=0;c.sk[0]=Math.min(1,c.sk[0]+dt/.9);c.sk[1]=Math.min(1,c.sk[1]+dt/.9);
    const pickPal=()=>{c.pal=c.pm<1?c.palB:c.pal;let n;do{n=tessPalW[Math.floor(rand()*tessPalW.length)];}while(n===c.pal);c.palB=n;c.pm=0;};
    const pickForm=()=>{let f;do{f=[1,1,1,0,3,3,2][Math.floor(rand()*7)];}while(f===c.form);c.form=f;c.fP=c.phr|0;};
    const newMode=()=>{let m;do{m=Math.floor(rand()*tessModes.length);}while(m===c.mode);c.mode=m;for(let i=0;i<6;i++)if(rand()<.35)c.sg[i]=-c.sg[i];};
    // drop: explode (half the time into a cloud of vertex sparks), swap formation, polytopes, palette and rotation planes
    // at the peak, re-assemble with a whip of rotation
    if(F.onDrop||c.dbg){c.dbg=0;c.exT=0;c.exAmp=1;c.pend='drop';c.cloud=rand()<.5?1:0;c.vista=0;}
    // phrases (16 beats travelled, robust without bar detection): new rotation planes most phrases; every 8 bars a
    // polytope swap (every 16 bars a formation change); on the in-between phrases a rare event: the view pulls back to
    // reveal the colossal lattice, a half-turn whip through the w axis turns every polytope inside out, or the bodies
    // burst into a cloud of vertex sparks and re-assemble
    const phr=Math.floor(V.trav/16);if(c.phr===undefined){c.phr=phr;c.fP=phr;}
    if(phr!==c.phr){c.phr=phr;
      if(rand()<.75)newMode();
      // CORE layout change; into or out of the mirrored twins it happens at the peak of a small burst (the hero splits)
      if(c.form===1){const nl=(c.lay+1+Math.floor(rand()*2))%3;c.side=-c.side;
        if((nl===1)!==(c.lay===1)&&c.exT>1.5){c.exT=0;c.exAmp=.45;c.pend='lay';c.nl=nl;c.cloud=0;}else c.lay=nl;}
      const unfOK=c.form!==0&&c.uT>90&&c.exT>1.5;
      if(c.form===2&&phr-c.fP>=2&&c.exT>1.5){c.exT=0;c.exAmp=.8;c.pend='drop';c.cloud=0;}
      else if(phr%2===0){if(c.exT>1.5){c.exT=0;c.exAmp=phr%4===0?.8:.4;c.pend=phr%4===0?'drop':'phrase';c.cloud=rand()<.3?1:0;}}
      else if(c.vista<=0&&c.exT>1.5){const r=rand();
        if(r<.24&&unfOK)tessUnfold(c);else if(r<.48)c.vista=16;else if(r<.68)c.wp+=Math.PI*(rand()<.5?-1:1);else if(r<.86){c.exT=0;c.exAmp=.55;c.cloud=1;c.pend=null;}}
    }
    if(c.dbgEv){if(c.dbgEv==='unf'){c.uT=99;tessUnfold(c);}else if(c.dbgEv==='whip')c.wp+=Math.PI;else if(c.dbgEv==='cloud'){c.exT=0;c.exAmp=.55;c.cloud=1;c.pend=null;}else c.vista=16;c.dbgEv=0;}
    if(c.dbgLay!==undefined)c.lay=c.dbgLay;
    if(c.exT<1.5){
      c.exT+=dt*bps/(c.exAmp>.5?1.6:1.2);
      if(c.pend&&c.exT>=.45){
        if(c.pend==='lay'){c.pend=null;c.lay=c.nl;c.twin=c.lay===1?1:0;}
        else if(c.pend==='unf'){c.pend=null;c.set=[0,c.set[1]===0?1:c.set[1],c.set[2]];c.uT=0;}
        else{
        const drop=c.pend==='drop';c.pend=null;
        if(drop){pickForm();c.lay=Math.floor(rand()*3);newMode();c.kp[0]+=.7;if(rand()<.4)c.colT=[0,2,1,7,8][Math.floor(rand()*5)];}
        c.set=tessSets[Math.floor(rand()*tessSets.length)];c.uT=99;
        if(drop||rand()<.5)pickPal();
        c.ringN=[5,6,6,8][Math.floor(rand()*4)];
        c.twin=c.form===1&&c.lay===1?1:0;}
      }
    }
    c.uT=Math.min(c.uT+dTr,99);
    {const u=c.uT;c.unf=u>=12?0:clamp(u/2.2,0,1)*(1-clamp((u-8.5)/2.5,0,1));c.unf=c.unf*c.unf*(3-2*c.unf);}
    if(c.pm<1){c.pm=Math.min(1,c.pm+dt*bps*.9);if(c.pm>=1)c.pal=c.palB;}
    const lt=layT(),lk=.55/Math.max(bps,.5);
    c.hx=ease(c.hx,lt[0],dt,lk);c.hy=ease(c.hy,lt[1],dt,lk);c.twin=lt[2];
    const u=clamp(c.exT,0,1),ex=c.exT<1?Math.pow(Math.sin(Math.PI*u),1.5)*c.exAmp*(c.cloud?1.6:1.3):0;
    const shr=c.cloud&&c.exT<1?.92*Math.min(1,Math.sin(Math.PI*u)*1.8):0;
    // whip: a half turn in the XW plane delivered over about two beats (eased), turning every polytope inside out
    {const d=c.wp*(1-Math.exp(-dt*bps*1.3));c.wp-=d;tessGivens(c.M,2,d);}
    // the view pulls back (the colossal lattice comes into view) on vista phrases and in breakdowns, pushes in a touch in builds
    c.vista=Math.max(0,c.vista-dTr);
    c.zI=ease(c.zI,c.vista>0?.46:calm>.5?.56:1+.06*c.bu,dt,.9);
    // the nest grows one shell per two beats (faster in builds); the grid scrolls half a cell per beat
    c.nz=(c.nz+dTr*(1+.8*c.bu))%6000;c.gs=(c.gs+dTr*(1+.5*c.bu))%6000;
    c.tu+=dt*(.05+.12*(F.mid||0))*S.speed;
    const tw=c.tw[0]+.25*Math.sin(V.mt*.043)+PTR.y*.12*PTR.inf;
    const T3=rotMat3(tw,c.tw[1]+c.tu+PTR.x*.12*PTR.inf,.15*Math.sin(V.mt*.031)),M=c.M,G=new Array(16);
    for(let k=0;k<4;k++){for(let r=0;r<3;r++)G[k*4+r]=T3[r]*M[k*4]+T3[3+r]*M[k*4+1]+T3[6+r]*M[k*4+2];G[k*4+3]=M[k*4+3];}
    // beat-locked breathing for the satellites: smooth cosine peaking just after each beat
    const ph=V.trav-Math.floor(V.trav),pulse=Math.pow(.5+.5*Math.cos(TAU*(ph-.12)),2)*(1-.6*calm);
    // the Hopf ring types read best large: the grid's small cells get a crisp polytope instead
    const gs=(t)=>c.form===3?(t===2?1:t===7?0:t===8||t===9?4:t):c.form===2&&(t===7||t===8)?(t===7?2:0):t;
    const ss=t3(c.uT<12&&c.set[0]===0&&c.form!==0?10:c.set[0],gs(c.set[1]),gs(c.set[2]));
    function t3(a,b,d){return a+16*b+256*d+4096*c.colT;}
    // hats as a smoothed envelope (100 ms up, 550 ms down): the light trains' beads swell with it (geometry, no strobe)
    c.hE=ease(c.hE||0,Math.min(1,(F.hat||0)*1.2),dt,(F.hat||0)>(c.hE||0)?.1:.55);
    V.p1=[G[0],G[1],G[2],G[3]];
    V.p2=[ss+65536*Math.round(clamp(c.hE,0,1)*63),c.form,c.hx,c.hy];
    V.p3=[c.br*(1+.62*clamp(c.kS||0,0,1.2)),ex,c.bu,c.form===0?0:c.unf];
    V.p4=[c.snT,c.fl,c.hp,Math.floor(Math.min(c.ke,1)*999)+1000*(c.kf||0)+Math.min(shr,.999)];
    const gh=typeof D!=='undefined'&&Number.isFinite(D.hue)?(D.hue+((F.cent||.45)-.45)*.35)%1000:0,hr=c.hueN+.35*Math.sin(gh*TAU);
    const pc=(k)=>tessCol(c.pal,c.palB,c.pm,k,hr);
    V.p5=[pc(0),pc(1),pc(2),c.form===2?c.gs:c.nz];
    // shaped bands packed 6 bits each: m1[8] = low-mid, mid, high-mid, bass; m2[4] = presence, high, air, sub
    const q6=(x)=>Math.round(clamp(x,0,1)*63),sb=[c.sx[0],c.sx[1],c.sx[2],c.sx[3],c.sx[4],c.sx[5],c.sb[6],c.sb[7]];
    V.m1=new Float32Array([G[4],G[5],G[6],G[7],G[8],G[9],G[10],G[11],q6(sb[2])+64*q6(sb[3])+4096*q6(sb[4])+262144*q6(sb[1])]);
    V.m2=new Float32Array([c.src[0],c.src[1],c.src[2],c.zI,q6(sb[5])+64*q6(sb[6])+4096*q6(sb[7])+262144*q6(sb[0]),c.twin+2*(Math.round(c.sk[0]*2047)+2048*Math.round(c.sk[1]*2047)),c.layout+2*c.ringN+32*Math.round(clamp(c.dWe||c.dW,1.2,3)*1000),pc(3),Math.round(clamp(pulse,0,1)*1023)+1024*Math.round(clamp(c.kS||0,0,1)*1023)]);
  }
  },
