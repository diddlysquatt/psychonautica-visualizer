{
  key:'velvet',name:'VELVET',src:R_VELVET,cost:0.9,cont:[],description:'satin ribbons weave and reweave',
  fb:{zoom:0,rot:0,decay:.22,warp:0,echo:.04,droste:0,win:0,key:.1},syms:[0,0,0,6,6,8,8,12,5,4,16,3],kalZoom:.95,
  auto:{kal:[8,6,12,5,4,16,0],kalCycle:true,kalZoom:.95,zoom:[.2,1],transitions:['kaleido','melt','portal'],fx:{bloom:.6,trails:.42},notes:'w4: one weave of broad satin bands, each with its own damask, embroidery and trim. In places the bands leave the straight over-under grid: at chosen crossings they turn a rounded corner onto each other instead of crossing, so the same bands wind into curls, loops and four-fold knots and run on into the cloth (strict over-under throughout; nothing spins). A new section re-threads the cloth into another figure, an arrival snaps the corners open out of a weave that looked plain, a build and the snare draw them tight, the kick sends a ripple down every band, the hats light a running stitch of beads. Far (.2) the whole cloth and its figures as a design, home (.42) five to eight broad bands and one or two figures, close (1) thread, stitch and embroidery. Glow is kept low: satin, not neon.'},
  // layouts: 0 square loom, 1 bias trellis (45 deg, open), 2 triaxial kagome (three families), 3 lozenge (60 deg)
  init:(s)=>{
    const lay=s[0]<.42?0:s[0]<.72?1:3;   // w4: the triaxial loom is retired (its three families cannot carry the knot)
    let x=Math.floor(s[1]*233280);const R=()=>(x=(x*9301+49297)%233280)/233280;
    const g=velvetGen(lay,null,R);g.pal=Math.floor(s[2]*8)%8;
    const SR=[[.125,.16],[.12,.15],[.12,.15],[.14,.17]][lay],fm=velvetForm(-1,R),FM=VELVET_FORMS[fm];
    return {lay,S:SR[0]+(SR[1]-SR[0])*s[3],
      rot:lay===1?Math.PI/4:lay===2?(s[3]<.5?0:Math.PI/2):lay===3?Math.PI/3:(s[3]<.5?0:.12),
      A1:lay>=2?Math.PI/3:Math.PI/2,nF:lay===2?3:2,g0:g,g1:g,tT:60,pend:false,
      sl:0,wt:s[1]*20,wa:.25,wm:1,bu:0,ba:0,mi:0,lv:0,
      p1:3,p1a:0,p2:3,p2a:0,fm,Sm:FM[0],sp:0,gd:0,gT:0,lph:s[2]*6.28,fN:0,fT:3,hN:0,hOn:false,since:0,lt:null,
      // v21: a beat clock of our own and the stepped clock made from it, the loom's turn (springs), the drop counter, the label
      bc:0,bi:0,stI:0,go:1,st:0,rotT:null,rotV:0,A1T:null,A1V:0,dk:Math.floor(s[2]*7)%2,pd:1,sgA:1,sgN:Math.floor(s[0]*4),sgT:22+s[3]*16,
      // w4 the roundness of the corners at broken crossings (a spring: 0 a mitred fold, 1 open loops), the snare's tug on it
      rho:1,rhoV:0,tgS:0,kAge:9};
  },
  frame(V,F,dt){
    const c=V.c,bd=60/clamp(F.bpm||120,60,200),e=(r)=>1-Math.exp(-dt*r);
    if(c.lt===null)c.lt=V.trav;
    const dTr=clamp(V.trav-c.lt,0,.5);c.lt=V.trav;
    c.bu+=(F.build-c.bu)*e(2.5);c.ba+=(Math.max(F.bass,F.sub*.85)-c.ba)*e(5.5);   // v21: the low end moves the cloth with more weight
    // v22 fix: since v21 the next two updates sat inside the comment above, so the mids and the level never reached the scene
    c.mi+=(F.mid-c.mi)*e(4);c.lv+=(F.level-c.lv)*e(3);
    // reweave: a drop re-threads the loom with a new weave, palette and embroidery; phrases change weave + motif
    c.since+=dt;c.tT=Math.min(c.tT+dTr+dt*.25,60);
    // v21 the beat: a clock that never runs backwards, pulled gently onto the beat the engine hears; st takes one eased step in the first half of each
    // beat and rests in the second (patterns step along the ribbons on it, colour runs through the weave on it). In silence it steps every other beat.
    {const bpm=F.bpm>40?F.bpm:110;let db=dt*bpm/60*S.speed;if(F.conf>.15){const er=F.beatClock-(c.bc+db);db+=(er-Math.round(er))*e(5.5);}
     c.bc+=Math.max(0,db);const bi=Math.floor(c.bc),bf=c.bc-bi,u=Math.min(1,bf/.5);
     if(bi!==c.bi){c.bi=bi;c.stI+=c.go;c.go=((F.silent||c.div===2)&&bi%2)?0:1;}
     c.st=(c.stI+c.go*u*u*(3-2*u))%4096;}
    // v21 the loom turns: on every other drop the whole loom swings to another setting (square, tilted, on the bias, sheared to sixty degrees) on a
    // critically damped spring, while the reweave runs through it
    if(c.rotT===null){c.rotT=c.rot;c.A1T=c.A1;}
    const drop=F.onDrop||F.drop>c.pd+.4||(F.onImpact&&F.impactStrength>=.8);c.pd=F.drop;
    if(drop&&c.dk++%2===0){
      const O=c.lay===2?[[0,1],[Math.PI/6,1],[Math.PI/2,1],[Math.PI/3,1]]:[[0,0],[.12,0],[Math.PI/4,0],[Math.PI/3,1],[0,1],[Math.PI/6,1],[.9,0]];
      let k,n=0;do{k=O[Math.floor(rand()*O.length)%O.length];}while(Math.abs(k[0]-c.rotT)<.05&&n++<8);
      c.rotT=k[0];c.A1T=k[1]?Math.PI/3:Math.PI/2;}
    {const sp=(x,v,t,w)=>{const d=x-t,q=v+w*d,E=Math.exp(-w*dt);return[t+(d+q*dt)*E,(v-w*q*dt)*E];};
     let r=sp(c.rot,c.rotV,c.rotT,3.6);c.rot=r[0];c.rotV=r[1];r=sp(c.A1,c.A1V,c.A1T,3.6);c.A1=r[0];c.A1V=r[1];}
    // the label surfaces once or twice in a visit, on a snare or a bar line
    c.sgA=Math.min(1,c.sgA+dt/1.9);
    if(c.sgA>=1&&c.since>3&&V.mt>c.sgT&&(F.onHit||F.onBar)){c.sgA=0;c.sgN++;c.sgT=V.mt+50+rand()*50;}
    if(F.onDrop||(F.onImpact&&F.impactStrength>=.6)||F.onSection)c.pend=2;   // v22: arrivals and new sections re-thread the loom too
    else if(!c.pend&&(((F.onBar || F.onSceneBar)&&(F.sceneBarIndex ?? F.barIndex)%8===0&&c.since>10)||c.since>28))c.pend=1;
    if(c.pend&&c.tT>3.8){
      const ng=velvetGen(c.lay,c.g1);
      if(c.pend===1&&rand()<.6)ng.pal=c.g1.pal;
      if(c.pend===2||rand()<.7)c.fm=velvetForm(c.fm,rand);
      c.g0=c.g1;c.g1=ng;c.tT=0;c.since=0;c.pend=false;c.div=rand()<.3?2:1;   // v21: some phrases step in half time
    }
    // kick: a ring of swelling ribbons runs out from the focal point in about one beat; the cushion breathes
    if(F.onKick){c.kN=(c.kN||0)+1;c.p2=c.p1;c.p2a=c.p1a;c.p1=0;c.p1a=.6+.5*Math.min(F.kick,1.2);}
    c.p1=Math.min(c.p1+dt/(bd*.8),3);c.p2=Math.min(c.p2+dt/(bd*.8),3);c.p1a*=Math.exp(-dt*1.2);c.p2a*=Math.exp(-dt*1.2);
    // breakdowns narrow the light to a spotlight on the focal point; builds open it up
    c.sp+=(clamp(F.breakdown-.6*c.bu,0,1)-c.sp)*e(1.5);
    // phrase framing: loom scale and cushion depth ease to the current form
    const FM=VELVET_FORMS[c.fm];c.Sm+=(FM[0]-c.Sm)*e(.8);   // v21: a change of scale is a slow glide, not a pump
    // rare surprise: the gilding. For two bars every coloured thread turns to metal and the sequins blaze
    if((F.onDrop&&rand()<.3)||((F.onBar || F.onSceneBar)&&!F.breakdown&&rand()<.012))c.gT=8;
    c.gT=Math.max(c.gT-dTr,0);c.gd+=((c.gT>0?1:0)-c.gd)*e(c.gT>0?3:1.2);
    // snare: the over/under order flips in a cascade sweeping across the loom
    if(F.onHit){c.fN++;c.fT=0;}
    c.fT=Math.min(c.fT+dt/(bd*.55),3);
    const ft=clamp(c.fT,0,1),fe=ft*ft*(3-2*ft);
    // hats: glints re-roll on each hat
    if(F.hat>.45&&!c.hOn){c.hN=(c.hN+1)%997;c.hOn=true;}if(F.hat<.25)c.hOn=false;
    // rows and columns slide in opposite directions, surging on every beat and racing in a build
    c.sl=(c.sl+(dTr*(.25+.4*c.bu)+dt*.03*S.speed)*c.S*c.Sm)%200;   // v21: gentler surges
    c.wt=(c.wt+dt*S.speed*(1.1+2.4*c.bu+1.1*c.mi)+dTr*.9)%6283;
    const waT=clamp((.035+.1*c.mi+.05*c.lv)*(1-.5*F.breakdown)*(.6+.4*S.dose),.02,.11);
    c.wa+=(waT-c.wa)*e(3);
    c.wm=1+.07*c.ba+.03*c.bu;   // v21: the ribbons swell less than half as far with the low end
    // w4 the knot's own motion. The corners of every broken crossing are a spring: an arrival folds them shut (the cloth looks plainly woven) and
    // lets them snap open, harder the bigger it is; a build draws them tight as it climbs, the snare tugs them, every kick makes them breathe.
    {const imp=F.onImpact?(F.impactStrength||.5):0;c.kAge+=dt;
     if((imp>=.45||F.onDrop)&&c.kAge>.6){c.rho=Math.min(c.rho,.06);c.rhoV=5+5*Math.max(imp,.6);c.kAge=0;}
     else if(imp>0)c.rhoV-=2+3*imp;
     if(F.onKick&&c.rho>.5)c.rhoV-=1.3;
     c.tgS*=Math.exp(-dt/.16);if(F.onHit)c.tgS=Math.min(1,.5+.5*Math.min(F.hit||0,1));
     const T=clamp(1-.72*Math.pow(clamp(F.tension||0,0,1),1.2)-.3*c.tgS,.1,1),n=Math.max(1,Math.ceil(dt/.02)),h=dt/n,w=11,z=.42;
     for(let i=0;i<n;i++){c.rhoV+=(-w*w*(c.rho-T)-2*z*w*c.rhoV)*h;c.rho=clamp(c.rho+c.rhoV*h,0,1.25);}}
    // v12: geometry bass for the carpet medallions (eased by Motion smoothness) and the mid-driven turn of their petals
    const ms=clamp(Number(S.motionSmooth)||0,0,1);
    c.bz=(c.bz||0)+(c.ba-(c.bz||0))*e(5*(1-.5*ms));c.mph=((c.mph||0)+dt*S.speed*(.02+.45*c.mi))%1;
    const lit=.32*Math.sin(V.mt*.11)+.14*Math.sin(V.mt*.29+1);
    const lx=.36*Math.sin(Math.PI*2*V.trav/32+c.lph),ly=.14*Math.sin(Math.PI*2*V.trav/24+c.lph*1.7);
    // v20: quiet fill. A slow follower of how quiet the music is (0 in loud passages) lifts the whole cloth, so soft passages and silence are never dark
    c.qt=(c.qt||0)+(clamp(1-F.level/.3,0,1)-(c.qt||0))*e(.8);
    const q12=x=>Math.round(clamp(x,0,1)*4095);
    V.p1=[c.S*c.Sm*(1-.09*c.bu),clamp(c.rot,0,9.9)+10*Math.floor(clamp(c.qt,0,1)*99),q12(lx+.5)+4096*q12(ly+.5),c.lay+.9*clamp((c.A1-Math.PI/3)/(Math.PI/6),0,1)];
    V.p2=[c.sl,c.wt,c.wa/Math.pow(c.Sm,.6),Math.round(clamp((c.wm-1)/.12,0,1)*255)];
    V.p3=[c.p1*1.25,c.p1a,c.p2*1.25,c.p2a];
    V.p4=[c.fN%2+2*Math.floor(clamp(c.bz,0,1)*999)+2000*((c.kN||0)%128),fe,clamp(c.sp,0,1)*.999+Math.floor(clamp(c.mi,0,1)*255),clamp(c.gd,0,1)*.99+2*Math.floor(c.sgA*63)+128*(c.sgN%4)];
    V.p5=[c.tT,c.hN+Math.min(c.mph,.9999),clamp(c.rho,0,1),c.st];   // w4: p5.z is the roundness of the knot's corners
    V.m1=velvetPack(c.g0);V.m2=velvetPack(c.g1);
  }
  },
