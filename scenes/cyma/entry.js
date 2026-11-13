  {
  key:'cyma',name:'CYMA',src:R_CYMA,cost:1,cont:[],description:'a temple of singing sand, crossed by travelling sound waves',kalZoom:.7,
  fb:{zoom:0,rot:0,decay:.22,warp:0,echo:.04,droste:0,win:0,key:.09,live:.15},syms:[0,0,6,6,8,12,4,16,3,5],
  auto:{kal:[6,8,5,4,12],kalCycle:true,kalZoom:.7,transitions:['kaleido','vortex','melt','portal'],notes:'v14: ring k draws band 7-k as a spectrum rose (petals = the band pitch, size = its level and onsets), so the eight rings are the eight bands as shapes, with a perimeter highlight (light) pointing at whichever band is loudest, backward wavefronts rolling in across the floor from the rim as the mid bands build, and the low bands carving grooves into the floor; the reshuffled material roles put liquid metal into every visit; folded, the field nodes and the low harmonic lines keep the mandala changing; 6/8/5/4/12 full and changing, 2/3/16 busier'},
  init:s=>{
    // layout family x shape set x palette x material set x world arrangement/spokes x camera tilt
    const lay=Math.floor(s[0]*5),sv=Math.floor(s[2]*8),pal=Math.floor(s[1]*8);
    const mat=cymaMatPick(s[3]);
    const bs=[];for(let b=0;b<7;b++){const k=1+b+(b===6?3:0),v=Math.floor((s[3]*8+b*3))%8;bs.push({a:k*8+v,b:k*8+v,t:1});}
    const o={L:lay+10*sv,LB:lay+10*sv,wipe:1,mat,matB:mat,pal,palB:pal,palT:1,bs,en:[0,0,0,0,0,0],ce:[.5,.5,.5,.5,.5,.5],pitch:.4,
      lt:null,kc:0,lastKick:9,beatF:0,hop:0,spark:0,sseed:1,flash:0,buildS:0,bassS:.3,midS:.3,dropK:0,pd:0,since:0,
      mph:s[2]*6,wv:Math.floor(s[1]*7)%4+4*(Math.floor(s[0]*13)%4),wvB:0,tt:0,spin:0,spinT:0,tilt:.55,tiltT:cymaTilts[Math.floor(s[2]*13)%4],az:s[0]*6.28,azV:.05,kT:9,drift:s[1]*40,flow:0,scroll:0,scrollT:0,scroll0:0,scP:1,
      rs:[{n:1.6,ph:.3},{n:1.9,ph:1.1},{n:2.3,ph:2.4},{n:2.7,ph:3.1},{n:3.2,ph:4.4},{n:3.7,ph:5.2},{n:4.3,ph:6.1},{n:5.,ph:7.2}],roseT:0,roseDir:0};
    o.wvB=o.wv;o.tilt=o.tiltT;return o;
  },
  frame(V,F,dt){
    const c=V.c,dz=S.dose;
    if(c.lt===null)c.lt=V.trav;
    const dT=clamp(V.trav-c.lt,0,.5);c.lt=V.trav;
    cymaAnalyse(c);
    c.buildS=ease(c.buildS,F.build,dt,.35);
    c.bassS=ease(c.bassS,F.bass,dt,.12);
    c.midS=ease(c.midS,F.mid,dt,.25);
    c.dropK=Math.max(0,c.dropK-dt/20);
    const fast=c.buildS>.45;
    // kick: the whole plate jumps; one pair of bands (in turn) and, every other kick, the pitch plate re-figure
    if(F.onKick){
      c.kc++;c.lastKick=0;c.kT=0;c.hop=Math.max(c.hop,(.68+.46*Math.min(1,F.kick))*dz);
      const j=c.kc%3;cymaRetarget(c,j);cymaRetarget(c,j+3);
      if(c.kc%2===0||fast)cymaRetarget(c,6);
    }
    c.lastKick+=dT;
    // no kicks: re-figure on the beat instead
    const bf=Math.floor(V.trav);
    if(bf!==c.beatF){c.beatF=bf;if(c.lastKick>2){c.kc++;c.hop=Math.max(c.hop,.3*dz);const j=c.kc%3;cymaRetarget(c,j);cymaRetarget(c,j+3);if(c.kc%2===0)cymaRetarget(c,6);}}
    c.hop*=Math.exp(-dt/.13);
    c.kT=Math.min(9,c.kT+dt);
    const bd=F.breakdown||0;
    c.drift+=dt*(.3+1.6*c.buildS+.5*F.level)*(1-.6*bd)*S.speed;if(c.drift>1e4)c.drift-=1e4;
    c.flow+=dt*(.5+1.2*F.level+2*c.hop)*(1-.5*bd)*S.speed;if(c.flow>1e4)c.flow-=1e4;
    // transitions: resettle over ~0.6 beat (faster in a build)
    const dur=fast?.4:.65;
    for(const s of c.bs)s.t=Math.min(1,s.t+Math.max(dT/dur,dt/2.5));
    // snare: glints shatter off the lines
    if(F.onHit){c.spark=1;c.sseed=(c.sseed+1)%997;}
    c.spark*=Math.exp(-dt/.32);
    c.flash*=Math.exp(-dt/.5);
    // layout change through an iris from the centre
    const relayout=(keep)=>{
      if(c.wipe<1){c.L=c.LB;c.mat=c.matB;}
      const lay=keep?c.L%10:cymaPick(5,c.L%10),sv=cymaPick(8,Math.floor(c.L/10));
      c.wv=c.wvB;c.LB=lay+10*sv;c.matB=cymaMatPick(rand());c.wipe=0;c.since=0;c.tt=rand()<.4?1:0;
      if(!keep||rand()<.5)c.wvB=cymaPick(4,c.wv%4)+4*Math.floor(c.wv/4);
      if(!keep||rand()<.6)c.wvB=c.wvB%4+4*cymaPick(4,Math.floor(c.wv/4));
    };
    // w4: the graded impact cue: a real arrival (>= .6) counts as a drop (new plate set, new energy scheme, the rings spin)
    const imp=F.onImpact?(F.impactStrength??.5):0;
    const dropEdge=F.onDrop||(F.drop>.85&&c.pd<.5)||(imp>=.6&&c.since>4);c.pd=F.drop;
    if(dropEdge){
      relayout();
      if(c.palT<1)c.pal=c.palB;
      c.palB=cymaPick(8,c.pal);c.palT=0;
      c.flash=1;c.hop=1.5*dz;c.dropK=1;c.spinT+=(rand()<.5?-1:1)*(22+18*rand());c.tiltT=cymaPick(4,cymaTilts.indexOf(c.tiltT));c.tiltT=cymaTilts[c.tiltT];c.azV=(rand()<.5?-1:1)*(.03+.06*rand());
      for(let b=0;b<7;b++)cymaRetarget(c,b,true);c.pT=0;
    }
    // w4: a modest impact is a punch: the board jumps, every figure re-forms at once, the rings turn a notch
    if(imp>0&&!dropEdge){c.hop=Math.max(c.hop,(.7+1.2*imp)*dz);c.flash=Math.max(c.flash,.4+imp);c.spinT+=(rand()<.5?-1:1)*(6+14*imp);for(let b=0;b<7;b++)cymaRetarget(c,b,true);}
    // w4: a new section is a new chapter: a new plate set irises in, in a new energy scheme, seen from a new angle
    if(F.onSection&&!dropEdge&&c.since>1.5){c.secT=0;relayout();if(c.palT<1)c.pal=c.palB;c.palB=cymaPick(8,c.pal);c.palT=0;c.pT=0;c.flash=Math.max(c.flash,.6);
      c.tiltT=cymaTilts[cymaPick(4,cymaTilts.indexOf(c.tiltT))];c.azV=(rand()<.5?-1:1)*(.03+.05*rand());}
    c.pT=(c.pT??0)+dt;c.secT=(c.secT??99)+dt;
    c.since+=dt;
    if((F.onBar || F.onSceneBar)&&!dropEdge){
      const bi=(F.sceneBarIndex ?? F.barIndex)|0;
      c.scrollT+=1;c.scroll0=c.scroll;c.scP=0;
      if(bi%4===0){for(let b=0;b<7;b++)cymaRetarget(c,b);c.gI=cymaPick(cymaGreat.length,c.gI??0);c.gAT=cymaGreat[c.gI][0];c.gBT=cymaGreat[c.gI][1];}
      if(bi%8===0&&c.palT>=1&&c.pT>40){c.palB=cymaPick(8,c.pal);c.palT=0;c.pT=0;}   // w4: the energy scheme belongs to the section; without one it still turns after 40 s
      // every 8 bars a new plate set irises in (a new layout family every 16)
      if(bi%8===4&&c.wipe>=1&&c.since>12&&(c.secT??99)>26)relayout(bi%16!==12);   // w4: only when the song gives no sections
      // phrases: the viewpoint drifts to a new angle and orbit speed
      if(bi%8===0&&rand()<.7){c.tiltT=cymaTilts[cymaPick(4,cymaTilts.indexOf(c.tiltT))];c.azV=(rand()<.5?-1:1)*(.02+.05*rand());}
    }
    c.wipe=Math.min(1,c.wipe+Math.max(dT/2.5,dt/6));
    if(c.wipe>=1){c.L=c.LB;c.mat=c.matB;c.wv=c.wvB;}
    c.palT=Math.min(1,c.palT+Math.max(dT/3,dt/8));
    if(c.palT>=1){c.pal=c.palB;}
    c.scP=Math.min(1,c.scP+Math.max(dT/.8,dt/3));
    const sE=c.scP*c.scP*c.scP*(c.scP*(c.scP*6-15)+10);
    c.scroll=c.scroll0+(c.scrollT-c.scroll0)*sE;
    if(c.scrollT>4096){c.scrollT-=4096;c.scroll-=4096;c.scroll0-=4096;}
    // the figures' degenerate-mode weights slide with the mids and glide whenever the melody moves
    const pS=c.pS??c.pitch;c.pS=ease(pS,c.pitch,dt,.18);
    c.mph+=dt*(.25+1.4*c.midS*dz)*S.speed+Math.min(.3,Math.abs(c.pS-pS)*30);if(c.mph>6283)c.mph-=6283;
    // camera: tilt eases over ~3 s, the orbit slows in breakdowns and quickens in builds; the drop spin eases in
    c.tilt=ease(c.tilt,c.tiltT,dt,1.4);c.az=(c.az+dt*c.azV*(1+1.5*c.buildS)*(1-.6*bd)*S.speed)%(Math.PI*2);if(c.az<0)c.az+=Math.PI*2;
    c.spin=ease(c.spin,c.spinT,dt,.45);if(Math.abs(c.spinT)>1e4){c.spinT=0;c.spin=0;}
    const calm=1-.5*(F.breakdown||0),air=(c.hop+.1*c.buildS)*calm;   // breakdowns: the sand barely stirs
    const enc=s=>s.a*1024+s.b;
    V.p1=[c.L,c.LB,c.wipe,c.mat+8*c.matB+64*c.tt];
    // v13: hats as a held envelope (60 ms attack, 0.3 s release) so their light is large and steady, never a strobe
    c.hatT=Math.max((c.hatT||0)*Math.exp(-dt/.3),Math.min(1,(F.hat||0)*1.2),BANDS.on[6]*.9,BANDS.on[7]);c.hatE=(c.hatE||0)+(c.hatT-(c.hatE||0))*(1-Math.exp(-dt/.06));
    V.p2=[air,c.spark*dz,c.sseed+1000*(c.wv+16*c.wvB),c.hatE*dz];
    const pe=c.palT*c.palT*(3-2*c.palT);
    const hue=(typeof D!=='undefined'&&Number.isFinite(D.hue)?D.hue:0)+((F.cent??.45)-.45)*.35;
    const pk=cymaPrep(cymaPals[c.pal],cymaPals[c.palB],pe,hue%1000,c.pk||(c.pk=[0,0,0,0,0]));
    V.p3=[pk[0],pk[1],pk[2],Math.round(clamp(c.tilt,0,1)*1000)+Math.min(.9999,c.az/(Math.PI*2))];
    V.p4=[V.trav%64,c.mph,.25+.9*c.midS*dz,c.flash*dz];
    // v18: the eight bands, smoothed for geometry (70 ms attack, 260 ms release), and the low-end field's strength
    const BL=BANDS.lv;const ls=c.ls||(c.ls=[0,0,0,0,0,0,0,0]);
    for(let b=0;b<8;b++){const x=clamp(BL[b]||0,0,1);ls[b]+=(x-ls[b])*Math.min(1,dt/(x>ls[b]?.07:.26));}
    const lf=clamp((BL[0]||0)*.7+(BL[1]||0)*.5+.3*(c.bassS||0),0,1);
    c.farA=(c.farA||0)+(lf-(c.farA||0))*Math.min(1,dt/(lf>c.farA?.08:.45));
    // the sound field's three sources (bass, mids, highs) wander across the temple, each faster as its band rises;
    // folded, the view glides off-centre (fold strength eases in over ~2 s)
    const nf=(typeof effectiveSym==='function'?effectiveSym(V):V.sym)||0;
    c.fs=ease(c.fs||0,nf>1?1:0,dt,.9);
    if(!c.sp)c.sp=[c.drift*.7,c.drift*.3+2,c.drift*.5+4];
    const ev=[.5*(BL[0]+BL[1]),.5*(BL[2]+BL[3]),.5*(BL[4]+BL[5])];
    const sP=[];for(let i=0;i<3;i++){c.sp[i]=(c.sp[i]+dt*S.speed*(.05+.12*ev[i])*(i===1?-1:1))%6283.1853;
      const a=c.sp[i],rr=(1.2+.9*i)*(1+.35*Math.sin(a*1.7+i));
      sP.push(cymaPack(clamp(rr*Math.cos(a+i*2.1)/12+.5,0,1),clamp(rr*Math.sin(a*1.3+i*2.1)/12+.5,0,1)));}
    const B=c.bs,P2=cymaPack,q8=x=>Math.min(255,Math.round(clamp(x,0,1)*255)),fr2=(a,b)=>(a+b/256)/256;
    // v18: every value has its own slot again. The smoothed bands ride in the fractions of integer-valued uniforms
    V.p1=[c.L+fr2(q8(ls[0]),q8(ls[1])),c.LB+fr2(q8(ls[2]),q8(ls[3])),c.wipe,c.mat+8*c.matB+64*c.tt+fr2(q8(ls[4]),q8(ls[5]))];
    V.p2[0]=P2(Math.min(air/4,.999),ls[7]);
    V.p4[3]=P2(Math.min(c.flash*dz/4,.999),c.farA);
    // v18: the great figure in the floor glides between mode pairs
    c.gA=(c.gA??3)+((c.gAT??3)-(c.gA??3))*Math.min(1,dt/.9);c.gB=(c.gB??5)+((c.gBT??5)-(c.gB??5))*Math.min(1,dt/.9);
    V.p2[3]=P2(Math.min(c.hatE*dz/2,.999),c.gA/12);V.p4[2]=P2(Math.min((.25+.9*c.midS*dz)/4,.999),c.gB/12);
    // v19: a quiet passage (the music's overall level, smoothed over about a second so kicks never pump it) fills in the
    // resting light of the glass and the floor. Carried in the fraction of the bass slot, the bass in its integer part
    const qT=clamp((.58-F.level)/.4,0,1);c.qS=(c.qS??0)+(qT-(c.qS??0))*Math.min(1,dt/(qT>(c.qS??0)?.25:1.4));
    V.p5=[Math.floor(Math.min(c.bassS*dz,3.9)*1024)+Math.min(c.qS,.999),c.scroll,(V.trav/48)%(Math.PI*40),pk[3]];
    V.m1=new Float32Array([enc(B[0]),enc(B[1]),enc(B[2]),enc(B[3]),enc(B[4]),enc(B[5]),enc(B[6]),P2(B[0].t,B[1].t),P2(B[2].t,B[3].t)]);
    V.m2=new Float32Array([P2(B[4].t,B[5].t),P2(B[6].t,c.fs),sP[0],sP[1],sP[2],P2(c.kT/10,ls[6]),pk[4],c.drift+c.spin,c.flow]);
  }
  },
