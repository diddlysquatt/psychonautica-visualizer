  {
  key:'optik',name:'OPTIK',src:R_OPTIK,cost:0.9,cont:['dens'],description:'neon op-art lens illusions',kalZoom:.75,
  fb:{zoom:0,rot:0,decay:.12,warp:0,echo:.03,droste:0,win:0,key:.22},syms:[0,0,0,4,6,6,8,8,12,3,5,16],
  auto:{kal:[0,6,8,4,12,5,3,16],kalCycle:true,kalZoom:.75,transitions:['vortex','kaleido','melt'],notes:'v12: satellites are only the field swelling (no discs): at most two, presence and air, rising with their band and the snare and sinking away when quiet; presence/air/snare also roll a slow bend through the whole field; band-driven sizes read the smoothed bands (no raw-spectrum shimmer); folds 4/5/6/8/12 rechecked; v11: no snare sweep bar or figure/ground flash; smoothed band envelopes; eyes decoration; every fold makes a lens mandala'},
  init:s=>{
    // five illusion families (with sub-variants) x ten curated palettes; the focal sphere sits on a third
    const fam=optikFams[Math.floor(s[0]*optikNF)%optikNF],pal=Math.floor(s[1]*10);
    const ai=Math.floor(s[2]*5),an=optikAnchors[ai];
    const sub=Math.floor(s[3]*28)%optikSubs[fam],duo=s[2]>.62?1:0,prof=s[1]>.5?2:1,lat=(fam===0&&s[2]<.3)||(fam===16&&s[2]<.45)?1:0;
    const rot=[0,0,Math.PI/4,Math.PI/2][Math.floor(s[3]*4)];
    const c={fam,pal,fam0:fam,pal0:pal,sub,duo,prof,lat,dens:7+s[3]*4,ax:an[0],ay:an[1],ai,fx:an[0],fy:an[1],mv:1,fold:0,sg:null,
      rot,rotT:rot,sgn:s[0]>.5?[1,-1,1,-1]:[1,1,-1,1],wipe:1,inv:0,invF:2,invA:s[1]*6.28,kAge:9,kAmp:0,kEnv:0,
      rings:[[9,0],[9,0],[9,0]],bassS:.3,bassV:.3,bands:[.3,.3,.3,.3],bandV:[.3,.3,.3,.3],b8:[.3,.3,.3,.3,.3,.3,.3,.3],b8V:[.3,.3,.3,.3,.3,.3,.3,.3],rimS:[0,0,0,0,0],rimV:[0,0,0,0,0],hatS:0,hatV:0,kV:0,vS:0,rotV:0,snA:9,snK:0,lastSn:-9,dropP:0,ph:s[1]*4,orb:s[2]*6.28,lt:null,nAct:2,buildS:0,pd:0,since:0,
      cm:Math.floor(s[3]*7)%6,cm0:0,cmB:1,ev:0,evT:0,evK:0,fieldS:1,wt:0};
    c.cm0=c.cm;c.bits0=optikBits(c);
    c.f2=optikFams[(optikFams.indexOf(fam)+1+Math.floor(s[2]*(optikNF-1)))%optikNF];while(optikCentred(c.f2)||c.f2===fam)c.f2=optikFams[(optikFams.indexOf(c.f2)+1)%optikNF];c.p2=(pal+3)%10;c.b2=Math.floor(s[3]*8)%optikSubs[c.f2]+16*prof;c.zm=Math.floor(s[0]*97+s[3]*41)%3===0?0:1+Math.floor(s[1]*53)%8;c.zOld=optikZonePack(c);
    return c;
  },
  frame(V,F,dt){
    const c=V.c,dz=S.dose,TAU=Math.PI*2,BL=BANDS.lv,BO=BANDS.on;
    if(c.lt===null)c.lt=V.trav;
    // OPTIK v11: every audio input that moves geometry goes through a two-pole low-pass (attack >= 60 ms, release
    // >= 200 ms, slower with Motion smoothness); light envelopes too, so nothing strobes at any sensitivity
    const msm=clamp(Number(S.motionSmooth)||0,0,1),sr=1.45-.75*msm,ex=r=>1-Math.exp(-dt*r*sr);
    const lp2=(o,k,kv,t,ra,rr)=>{const a=ex(t>o[kv]?ra:rr);o[kv]+=(t-o[kv])*a;o[k]+=(o[kv]-o[k])*a;};
    const lpA=(A,AV,i,t,ra,rr)=>{const a=ex(t>AV[i]?ra:rr);AV[i]+=(t-AV[i])*a;A[i]+=(AV[i]-A[i])*a;};
    const c1=x=>clamp(Number.isFinite(x)?x:0,0,1);
    const raw=clamp(V.trav-c.lt,0,1);c.lt=V.trav;
    c.vS+=(raw/Math.max(dt,1e-4)-c.vS)*ex(3);c.vS=clamp(c.vS||0,0,8);
    const dT=Math.min(.5,c.vS*dt);c.tv=(c.tv??V.trav)+dT;
    const beatS=F.bpm>0&&F.conf>.3?60/F.bpm:.45;
    // geometry follows smoothed band envelopes: sub+bass drive the focal sphere, low-mid..presence the satellites
    lp2(c,'bassS','bassV',c1(.5*c1(F.bass)+.25*(BL[0]+BL[1])),9,3);
    for(let i=0;i<4;i++)lpA(c.bands,c.bandV,i,c1(BL[2+i]),10,3);
    for(let i=0;i<8;i++)lpA(c.b8,c.b8V,i,c1(BL[i]),6,2.2);   // v12: a little slower (no shimmer)
    c.buildS=ease(c.buildS,F.build,dt,.4);
    lp2(c,'kEnv','kV',c1(F.kick),14,3.5);
    lp2(c,'hatS','hatV',c1(Math.max(c1(F.hat)*.8,BO[6]*.8,BO[7])),14,3);
    // band rim lights: smoothed onsets (sub/bass on the focal sphere, low-mid..presence on the satellites)
    for(let i=0;i<5;i++)lpA(c.rimS,c.rimV,i,c1((i?BO[1+i]:Math.max(BO[0],BO[1]))*1.3),14,3.2);
    // kick: a lens ripple leaves the focal sphere (rate-limited; it fades in, never pops)
    // v18: three rings live at once (a new kick no longer cuts the previous ring off), rate-limited to keep them apart
    if(F.onKick&&c.rings[0][0]>Math.max(.32,beatS*.55)){c.rings.pop();c.rings.unshift([0,.6+.4*Math.min(1,F.kick)]);}
    for(const r of c.rings)r[0]+=dt;c.kAge=c.rings[0][0];c.kAmp=c.rings[0][1];
    const ringA=r=>r[1]*Math.exp(-r[0]*2.1)*Math.min(1,r[0]*12)*dz;
    // snare: a soft wave rolls out of the focal sphere (cells swell, eyes blink as it passes); no figure/ground
    // flash and no sweeping bar any more
    if(F.onHit&&c.tv-c.lastSn>.9){c.lastSn=c.tv;c.snA=0;c.snK=.55+.45*c1(F.hit);}
    c.snA+=dt/Math.max(.2,beatS);
    // v12: only two satellites, and only when their band sings: one rides the hi-mids/presence, one the high/air; each
    // swells out of the field as its band rises (and on the snare) and sinks back into it when quiet (150 ms in, 0.6 s out)
    {const sn=c.snK*Math.exp(-c.snA*2.2)*Math.min(1,c.snA*8);if(!c.sat)c.sat=[0,0];
     const tg=[c1((Math.max(c.b8[4],c.b8[5])-.4)/.45+.6*sn),c1((Math.max(c.b8[6],c.b8[7])-.4)/.45+.6*sn)];
     for(let i=0;i<2;i++)c.sat[i]+=(tg[i]-c.sat[i])*(1-Math.exp(-dt/(tg[i]>c.sat[i]?.15:.6)));}
    // an iris from the focal sphere into another family (drops, every 16 bars) or another variant of this one
    const sw=(drop,same)=>{
      c.fam0=c.fam;c.pal0=c.pal;c.bits0=optikBits(c);if(rand()<.35)c.inv++;c.invA=(c.invA+1.3+rand()*2.4)%TAU;
      c.zOld=optikZonePack(c);
      if(!same)c.fam=optikNextFam(c);
      if(drop||rand()<(same?.25:.4))c.pal=optikPickOther(10,c.pal);
      const ns=optikSubs[c.fam];c.sub=same&&ns>1?optikPickOther(ns,c.sub):Math.floor(rand()*ns);
      if(same&&ns<2)c.duo=1-c.duo;else c.duo=rand()<.35?1:0;
      c.prof=rand()<.5?2:1;c.lat=(c.fam===0&&rand()<.3)||(c.fam===16&&rand()<.45)?1:0;
      if(same&&c.fam===0&&rand()<.4)c.lat=1-c.lat;
      // v19: most compositions run two illusions at once; each side of the wipe keeps its own layout
      c.zm=rand()<.28?0:1+Math.floor(rand()*8);c.f2=optikPickFam(c.fam);c.p2=optikPickOther(10,c.pal);c.b2=Math.floor(rand()*optikSubs[c.f2])+16*(rand()<.5?1:0)+64*(rand()<.4?1:0);
      // the transition itself: drops open an iris or flip tiles, phrases use any of the four
      c.wt=drop?(rand()<.5?0:3):Math.floor(rand()*4);
      c.wipe=0;c.since=0;
      c.fx=c.cxB??c.ax;c.fy=c.cyB??c.ay;c.ai=optikPickOther(optikAnchors.length,c.ai);c.mv=0;
      c.rotT+=Math.PI/4*(rand()<.5?-1:1);
      c.cm0=c.cm;c.cm=optikPickOther(6,c.cm);c.cmB=0;
    };
    const dropEdge=F.onDrop||(F.drop>.85&&c.pd<.5);c.pd=F.drop;
    if(dropEdge){sw(true,false);c.dropT=1;}
    c.since+=dt*S.speed;
    if(c.since>17&&c.wipe>=1)sw(false,false); // every visit explores multiple illusion families, including quiet music
    const newMode=()=>{c.cm0=c.cm;c.cm=optikPickOther(6,c.cm);c.cmB=0;};
    if((F.onBar || F.onSceneBar)&&!dropEdge){
      const bi=(F.sceneBarIndex ?? F.barIndex)|0;
      if(bi%8===0&&c.wipe>=1&&c.since>beatS*12)sw(false,false);
      else if(bi%16===8&&c.wipe>=1&&rand()<.6)sw(false,true);      // half-way through a phrase: a new variant
      else if(bi%8===4)c.rotT+=Math.PI/4*(rand()<.5?1:-1);            // squares <-> diamonds, stripes swing
      // every 4-bar phrase (offset from the rotations) the focal sphere rolls to another seat, eased over 1.25 beats
      if(bi%4===2&&c.wipe>=1){c.fx=c.cxB??c.ax;c.fy=c.cyB??c.ay;c.ai=optikPickOther(optikAnchors.length,c.ai);c.mv=0;}
      // every 8 bars the satellites may change dance (crossfaded over two beats)
      if(bi%8===6&&rand()<.55)newMode();
      // rare events, two bars each: the focal sphere swells to a giant or sinks into a deep crater, or a lens storm
      // brings the whole wall of band lenses in around the composition
      if(bi%16===12&&c.ev<=0&&rand()<.45){const r=rand();c.ev=1;c.evT=0;c.evK=r<.4?(optikCentred(c.fam)?-1:1):(r<.65?-1:2);}
      // every bar one satellite swaps between bulge and dimple
      const j=bi&3;c.sgn=c.sgn.slice();c.sgn[j]=-c.sgn[j];
    }
    if(dropEdge&&c.ev<=0&&rand()<.35){c.ev=1;c.evT=0;c.evK=2;}
    if(dropEdge){c.fx=c.cxB??c.ax;c.fy=c.cyB??c.ay;c.ai=optikPickOther(optikAnchors.length,c.ai);c.mv=0;if(rand()<.6)newMode();}
    c.mv=Math.min(1,c.mv+dT*.8);
    const sst=x=>x*x*x*(x*(x*6-15)+10);
    const mE=sst(c.mv),an=optikAnchors[c.ai];
    c.ax=c.fx+(an[0]-c.fx)*mE;c.ay=c.fy+(an[1]-c.fy)*mE;
    c.cmB=Math.min(1,c.cmB+dT*.5);
    let evE=0;
    if(c.ev>0){c.evT+=dT;evE=Math.sin(Math.PI*clamp(c.evT/8,0,1));evE*=evE;if(c.evT>=8)c.ev=0;}
    const stE=c.evK===2?evE:0;evE-=stE;
    // kaleidoscope folds: the focal sphere settles on the fold centre so the fold mirrors a whole sphere
    const folds=typeof effectiveSym==='function'?effectiveSym(V):0;
    c.fold=ease(c.fold,folds>1.5?1:0,dt,.35);
    if(!c.sg)c.sg=c.sgn.slice();
    for(let i=0;i<4;i++)c.sg[i]=ease(c.sg[i],c.sgn[i],dt,beatS*.45);
    c.wipe=Math.min(1,c.wipe+dt/(beatS*1.5));
    const wE=1-Math.pow(1-c.wipe,3);
    c.dropT=(c.dropT||0)*Math.exp(-dt*1.3);c.dropV=c.dropV||0;lp2(c,'dropP','dropV',c.dropT,8,3);
    {const a=ex(5);c.rotV+=(c.rotT-c.rotV)*a;c.rot+=(c.rotV-c.rot)*a;}
    if(Math.abs(c.rotT)>TAU*8){const k=Math.round(c.rotT/TAU)*TAU;c.rot-=k;c.rotT-=k;c.rotV-=k;}
    const calm=1-.45*(F.breakdown||0);
    const dens=c.dens*(1+.6*c.buildS)*(1-.12*c.dropP);
    c.orb+=dT*TAU/32*(1+1.5*c.buildS)+dt*.02;
    c.nAct=ease(c.nAct,clamp(2+2*c.buildS+(F.drop>.3?2:0)+(c.cm===2||c.cm===3?2:0),0,4),dt,.3);
    c.ph+=dt*(.025+.14*.5*(c.b8[2]+c.b8[3])*dz)*S.speed;if(c.ph>1000)c.ph-=1000;
    const t=V.mt;
    const cxB=c.ax+.05*Math.sin(t*.13)+.03*Math.sin(t*.31),cyB=c.ay+.04*Math.cos(t*.11);c.cxB=cxB;c.cyB=cyB;
    const cx=cxB*(1-c.fold)+PTR.x*.05*PTR.inf,cy=cyB*(1-c.fold)+PTR.y*.05*PTR.inf;
    const R0=(.47+.15*c.bassS*dz+.07*c.kEnv*dz+.06*c.dropP)*(1+.55*evE*(c.evK>0?1:.4));
    let k0=clamp((.34+.42*c.bassS*dz+.2*c.kEnv*dz+.25*c.dropP)*calm,-.9,.86);
    // tunnels and blazes: the focal lens becomes a crater at the vanishing point, so the tunnel reads deeper
    c.deepS=ease(c.deepS??0,c.fam>2&&c.fam<5&&c.wipe>.3?1:0,dt,.25);
    k0+=(-(.3+.3*c.bassS*dz+.12*c.kEnv*dz)*calm-k0)*c.deepS;
    // v20: illusions built around the focal point itself (ROTO, PINNA, ENIGMA) keep it nearly flat there, so their own geometry reads
    c.flatS=ease(c.flatS??0,(c.fam===13||c.fam===17||c.fam===18)&&c.wipe>.3?1:0,dt,.25);k0*=1-.8*c.flatS;
    k0=k0+(c.evK>0&&!optikCentred(c.fam)?(.84-k0)*.7:(-.46-k0))*evE;
    const L=[],mB=sst(c.cmB);
    for(let i=0;i<4;i++){
      const A=optikSat(c.cm,i,c.orb,t),B=mB<1?optikSat(c.cm0,i,c.orb,t):A;
      const x=B[0]+(A[0]-B[0])*mB,y=B[1]+(A[1]-B[1])*mB,rs=B[2]+(A[2]-B[2])*mB,ks=B[3]+(A[3]-B[3])*mB;
      // a satellite is the field itself swelling (no disc): radius and bulge grow with its band and vanish when quiet;
      // the bulge stays under ~.5 so the centre never blows up into one flat colour
      const g=i<2?c.sat[i]*Math.min(1,dz*1.2):0,gs=g*g*(3-2*g);
      const R=(.17+.15*gs)*rs*(1-.4*evE*(c.evK>0?1:0));   // v20: never a droplet: a quiet satellite is a wide, shallow swell
      const k=clamp(c.sg[i]*.5*gs*calm*ks,-.44,.5);
      // its thin rim rings in the band's colour on that band's onsets, only while it is up
      L.push(cx+x,cy+y,R+2*Math.floor(100*(.9*c.rimS[1+i]*dz*gs)),k);
    }
    c.fieldS=ease(c.fieldS,calm*(1+.35*c.dropP+.25*c.buildS)*(c.fam>2&&c.fam<5?.55:1),dt,.3);
    const q8=x=>Math.round(c1(x)*255),B8=c.b8;
    V.p1=[c.fam*16+c.pal,c.fam0*16+c.pal0,q8(B8[0])+256*q8(B8[1])+65536*q8(B8[2]),q8(B8[3])+256*q8(B8[4])+65536*q8(B8[5])];
    V.p2=[cx,cy,R0+2*Math.floor(100*(.035+.9*c.rimS[0]*dz)),k0];
    V.p3=[dens,c.rot,(c.tv*.25)%256,Math.round(c.fieldS*512)+Math.min(.99,c.kEnv*dz)];
    const snR=c.snA*1.6,snE=c.snK*Math.exp(-c.snA*.9)*Math.min(1,c.snA*6)*dz;
    V.p4=[2*Math.round(stE*100),Math.floor(Math.min(snR,9.9)*100)+Math.min(.99,snE),c.invA,c.wt*2+wE];
    V.p5=[q8(B8[6])+256*q8(B8[7])+65536*q8(c.hatS*dz),c.ph,R0*1.02+c.rings[0][0]*1.7,ringA(c.rings[0])];
    // the two unused satellite slots now carry the older kick rings and the drop twist
    const r1=c.rings[1],r2=c.rings[2];
    V.m1=new Float32Array([L[0],L[1],L[2],L[4],L[5],L[6],R0*1.02+r1[0]*1.7,ringA(r1),R0*1.02+r2[0]*1.7]);
    V.m2=new Float32Array([ringA(r2),optikZonePack(c),c.zOld,L[3],L[7],0,c.dropP*dz,optikBits(c),c.bits0]);
  }
  },
