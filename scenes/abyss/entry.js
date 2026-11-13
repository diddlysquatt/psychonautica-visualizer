  {
  key:'abyss',name:'ABYSS',src:R_ABYSS,cost:2,cont:[],description:'a leviathan jellyfish wider than the frame over a court of spiralling jellies; drops plunge the camera between twilight, lightless midnight and a vent garden',kalZoom:.85,
  fb:{zoom:0,rot:0,decay:.34,warp:0,echo:.04,droste:0,win:0,key:.1,live:.2},syms:[6,6,8,4,12,5],
  auto:{kal:[0,8,6,12,4,1],kalCycle:true,kalZoom:.85,transitions:['kaleido','melt','leak','portal'],tier:1,kind:'3d',bars:48,fx:{bloom:.6,trails:.55,warp:.3},notes:'v22: the far giant is now a permanent leviathan (whole at zoom .15 to .3, its vault fills the frame at .5, we are under it at 1); the scene reads F.onImpact / onSection / tension / onDownbeat and dives between three depth zones by itself; folds 6, 8 and 12 turn the leviathan dome into rose windows (superb), 4 good, 1 (mirror) good, 2 (four-way) and 3 and 5 messy; v13: zooming in dollies through the water (near giants grow, the far crowd stays dense), bells and mantles show clustered photophores (rim and margin) that sparkle with hats and air; core glow lifts when pushed in; v12: rechecked 0/2/3/4/5/6/8/12/16 on 2 seeds with the new mantas, bass light waves, snow streams and school formations: 4/5/6/8/12 full and rich, 16 dense rings, 2 and 3 messy; giant jelly bells fold into mandalas; low warp keeps the bells crisp; on Auto the realm itself walks four of 6/8/4/12/5 (16 bars each, one 8-bar unfolded look at the giants mid-visit), stepping on drops; the hero lies on its side along the folded wedge so its tentacles become the mandala rays; 2 and 3 are messy, 16 is busy'},
  init:s=>{
    const famA=[0,0,0,1,2,3,3,4,4,5,5,6,6][Math.floor(s[0]*13)%13],zone=[0,0,0,1,0,2,0,1][Math.floor(s[2]*8)%8],palA=zone*3+Math.floor(s[1]*3)%3,sd=Math.floor(s[2]*997)/10;
    const kelp=famA===5||(famA!==6&&s[3]>.72)?1:0;
    return {famA,famB:famA,palA,palB:palA,sdA:sd,sdB:sd,bR:9,bK:0,bSp:1,swim:s[3]*64,kT:9,kAmp:0,carry:0,
      bass:0,mid:0,high:0,hat:0,lvl:0,build:0,brk:0,ball:0,spin:s[1]*6,pushT:9,bars:0,tp:0,cp:0,ch:0,glow:0,flash:0,
      w:[[0,0,4,0],[0,0,4,0]],wi:0,bu:[[0,0,4,0],[0,0,4,0]],bi:0,buCool:0,pd:0,camT:s[2]*40,
      hx:(s[3]<.5?-1:1)*(.3+.1*s[0]),hy:.08,hxT:(s[3]<.5?-1:1)*(.3+.1*s[0]),hyT:.08,htl:0,cwx:(s[3]<.5?1:-1)*(.3+.1*s[0]),cwy:-.12,fold:false,kq:null,ki:0,kb:0,kt:0,
      kelp:zone===2?1:kelp,hf:zone===2?.75:zone===1?3.4:kelp?1.5:2.6,reef:zone===2?1:0,reefV:0,octo:(famA===5||s[2]>.25)?1:0,ink:99,sch:s[0]*50,swd:famA>=5?1:.3,
      schF:9,schS:0,schT:0,ol:0,olT:99,olCool:30,olAge:0,
      side:s[3]<.5?-1:1,comp:1,hp:0,bw:[.999,.999],bwi:0,bwCool:0,shA:Math.floor(s[1]*6.99),shB:Math.floor(s[1]*6.99),shT:1,bloom:0,
      zone,dv:zone,dvA:zone,dvB:zone,dvP:1,dvDur:1.6,swapped:true,plCool:3,lo:zone===1?1:0,loEv:0,lvT:3.9,lvA:0,arms:2+Math.floor(s[0]*2.99),burst:0,gath:0,
      deal:Math.floor(s[2]*251)%256,post:0,evN:0,since:0,mk:0,mkT:9,mkN:0};
  },
  frame(V,F,dt){
    const c=V.c,ez=(x,t,k)=>x+(t-x)*Math.min(1,dt*k),sp=S.speed||1,B=BANDS.lv,O=BANDS.on;
    c.bass=ez(c.bass,F.bass,5);c.mid=ez(c.mid,.55*F.mid+.45*B[2],4);c.high=ez(c.high,F.high,7);
    c.hat=F.hat>c.hat?ez(c.hat,F.hat,30):ez(c.hat,F.hat,8);
    c.lvl=ez(c.lvl,F.level,3);c.build=ez(c.build,F.build,2);c.brk=ez(c.brk,F.breakdown||0,1.2);
    // kick: every bell contracts (an analytic envelope the shader evaluates per creature with a tiny delay)
    c.kT=Math.min(c.kT+dt,9.99);
    const pulseNow=Math.max(c.kAmp*abyssPulse(c.kT),c.carry*Math.exp(-4.5*c.kT));
    if(F.onKick){c.carry=Math.min(pulseNow,1.49);c.kT=0;c.kAmp=Math.min(1.15,.45+.75*F.kick)*(1-.4*c.brk);}
    // swim strokes: the drift advances with each contraction (per-creature speeds are integers/64; the field layers
    // scroll by 1/16 of a cell per unit, so wrapping at 4096 never shows)
    const still=Math.max(0,1-c.ball*8);
    c.swim=(c.swim+dt*sp*(.22*(1-.5*c.brk)+4.2*pulseNow)*still)%4096;
    // snare: a wave of light rolls through the swarm from a random point, and the school startles outward
    if(F.onHit){c.wi=1-c.wi;c.w[c.wi]=[(rand()-.5)*1.3,(rand()-.5)*.7,0,Math.min(1.3,.55+.8*F.hit)];c.schT=Math.min(1,.35+.4*F.hit);}
    for(const w of c.w){w[2]=Math.min(w[2]+dt*1.05,3.99);w[3]*=Math.exp(-dt*1.1);}
    c.schT*=Math.exp(-dt*5);c.schS=ez(c.schS,c.schT,9);
    // plankton bursts on low-mid and hi-mid onsets (a blooming ring of light somewhere in the water)
    c.buCool-=dt;
    if(c.buCool<=0&&(O[2]>.9||O[4]>.9)&&!F.onKick){c.bi=0;c.bn=(c.bn||0)+1;const hb=abyssHash(c.bn+c.sdA);c.bu[c.bi]=[(hb-.5)*1.5,(abyssHash(hb*91.7)-.5)*.8,0,Math.min(1.45,.7+.6*Math.max(B[2],B[4]))*(1-.5*c.brk)];c.buCool=.45;}
    for(const b of c.bu){b[2]=Math.min(b[2]+dt,3.99);}
    // hats: the light runs on every tentacle step on with each hat (and fade when the hats stop)
    c.hatS=F.hat>(c.hatS||0)?ez(c.hatS||0,F.hat,12):ez(c.hatS||0,F.hat,3); // smooth hat level for light (no chatter)
    c.hp=(c.hp+dt*sp*(.12+1.8*c.hatS))%1000;
    // bass: a bioluminescent wave rolls up through the water on each bass onset (two slots, alternating directions)
    c.bwCool-=dt;
    if(c.bwCool<=0&&(O[1]>.85||O[0]>.9)){c.bwi=1-c.bwi;c.bw[c.bwi]=0;c.bwCool=.55;}
    for(let i=0;i<2;i++)c.bw[i]=Math.min(.999,c.bw[i]+dt*sp*.42);
    // the school swirls into a new formation every 8 bars (3 s morph)
    c.shT=Math.min(1,c.shT+dt/3);
    // lantern-fish school: a flash wave on presence onsets
    c.schF=Math.min(c.schF+dt,9);if(O[5]>.9&&c.schF>.3)c.schF=0;
    // build: gather into a spiral bait-ball that spins faster and faster; drop: burst outward + new ensemble,
    // and the octopus fires a burst of glowing ink
    const drop=F.onDrop||F.drop>c.pd+.4;c.pd=F.drop;
    c.ball=ez(c.ball,Math.min(1,Math.max(c.build*1.25,(F.tension||0)*1.15))*(c.pushT<1.5?0:1),c.build>c.ball?1.6:2.2);
    c.spin=(c.spin+dt*sp*(.12+2.4*c.ball*c.ball+.4*c.build))%(Math.PI*400);
    // v22 music structure. A strong arrival (F.onImpact >= .6, or the old drop) plunges or lifts the camera a depth zone: 0 the
    // twilight under the leviathan, 1 midnight (lights out, living light only), 2 the vent garden on the floor. Everything rushes
    // past and the new ensemble rises into frame; the swap happens while the frame is in flight. A section change without one
    // either dives too or re-forms the court and the species; a medium impact bursts the court into a new figure and may put the
    // lights out for a few bars; every one of them deals the dance again. Tension winds the court tight before the drop.
    const imp=F.onImpact?Math.max(.1,F.impactStrength||0):(drop?.85:0),sec=!!F.onSection&&imp<.6;
    c.plCool-=dt;c.loEv=Math.max(0,c.loEv-dt);
    if(imp>0||sec){
      c.evN++;const h1=abyssHash(c.evN*.731+c.sdA*.17),h2=abyssHash(c.evN*1.37+c.sdA*.29),big=imp>=.6;
      c.deal=Math.floor(h2*251)%256;c.burst=Math.min(1,.45+.6*Math.max(imp,sec?.6:0));c.gath=0;
      c.arms=1+(c.arms+Math.floor(h1*3.99))%5;c.lvT=0;c.lvA=Math.min(.99,.6+.5*imp);
      if(big){c.bw=[.999,.999];c.bwCool=.9;c.pushT=0;c.de=1;c.flash=1;c.ball*=.8;c.ink=0;}
      if(((big&&c.plCool<4.5)||(sec&&h1<.55&&c.plCool<=0&&!((F.tension||0)>.3)&&V.mt>4))&&c.dvP>=1){
        // which zone: the other two by hash; a quiet section prefers midnight, a loud bright one leaves it
        const o=[0,1,2].filter(z=>z!==c.zone);let nz=o[h2<.5?0:1];const en=F.secEnergy??.5;
        if(sec&&en<.3&&c.zone!==1)nz=1;
        abyssDive(c,nz);
      }else if(big)abyssWipe(c,1,true,true);
      else if(sec)abyssWipe(c,.6,true,true);
      else if(imp>=.35){abyssWipe(c,0,false,true);if(c.zone!==1&&h1<.5)c.loEv=7;c.de=Math.max(c.de||0,.6);}
      else c.de=Math.max(c.de||0,.35);
    }
    // steady music with no arrivals: the dive still comes, on a 16-bar line once a zone has been home for 40 s (70 s with no bars at all, never in silence)
    c.since+=dt;
    if(c.dvP>=1&&((c.since>40&&(F.onBar||F.onSceneBar)&&(c.bars+1)%16===0)||(c.since>70&&c.lvl>.06))){c.evN++;const o=[0,1,2].filter(z=>z!==c.zone);
      abyssDive(c,o[abyssHash(c.evN*1.37+c.sdA*.29)<.5?0:1]);c.burst=.8;c.arms=1+(c.arms+1)%5;c.deal=Math.floor(abyssHash(c.evN*.731+c.sdA)*251)%256;c.de=Math.max(c.de||0,.6);}
    if(c.dvP<1){c.dvP=Math.min(1,c.dvP+dt/c.dvDur);const q=1-c.dvP;c.dv=c.dvA+(c.dvB-c.dvA)*(1-Math.pow(q,2.4));
      if(!c.swapped&&Math.abs(c.dv-c.dvA)>=.5){c.swapped=true;abyssWipe(c,.3,true,true);c.bSp=6;c.kelp=c.zone===2?1:c.kelp;}}
    // (v22b: on a dive INTO midnight the lights go out on the impact itself, not after the swap)
    {const loOn=c.zone===1||c.loEv>0;c.lo=ez(c.lo,loOn?1:0,loOn?14:2.5);}
    // the leviathan contracts on the musical one (the bar line when the downbeat is unsure; a slow breath when there is no beat)
    c.lvT=Math.min(c.lvT+dt,3.99);
    if(c.lvT>.9&&((F.onDownbeat&&(F.downConf??0)>.25)||(!((F.downConf??0)>.25)&&F.onBar)||c.lvT>3.9)){c.lvT=0;c.lvA=Math.min(.99,.35+.55*(F.energy??c.lvl));}
    c.gath=ez(c.gath,Math.max(F.tension||0,.8*c.build),(F.tension||0)>c.gath?2.5:1.2);c.burst*=Math.exp(-dt*.9);
    // the octopus snaps to a new posture on the snare
    if(F.onHit)c.post=(c.post+1+Math.floor(abyssHash(c.bars*.61+c.wi+c.sdA)*2.99))%4;
    // now and then, on the one, a short row of photophores lights on the leviathan's dome for a moment
    c.mkT+=dt;if(c.mkT>(c.mkN?46:20)+22*abyssHash(c.mkN*.77+c.sdA)&&c.lvT<.05&&c.dvP>=1&&c.lo<.5){c.mkT=0;c.mkN++;}
    c.mk=c.mkT<.3?c.mkT/.3:c.mkT<1.5?1:Math.max(0,1-(c.mkT-1.5)/.5);
    c.pushT+=dt;c.ink=Math.min(c.ink+dt,99);c.de=(c.de||0)*Math.exp(-dt*.35);
    const pt=c.pushT,push=(1-Math.exp(-pt*10))*Math.exp(-pt*1.3)*.9;
    // phrases: palette wave every 8 bars, species metamorphosis every 16; now and then the octopus inks on a phrase,
    // and now and then the camera sinks to visit a neon coral reef for 16 bars
    if((F.onBar || F.onSceneBar)&&(c.bars+1)%8===2){c.shA=c.shB;c.shB=(c.shB+1+Math.floor(abyssHash(c.bars*.13+c.sdA)*5.99))%7;c.shT=0;}
    // jelly blooms: some phrases fill the water with small jellies that all flash together on the kick
    const bloomOn=c.famB===0?(c.bars%16)<8:((c.bars%32)>=16&&(c.bars%32)<24&&abyssHash(Math.floor(c.bars/32)+c.sdA*.3)<.6);
    c.bloom=ez(c.bloom,bloomOn?1:0,.6);
    if((F.onBar || F.onSceneBar)){c.bars++;if(c.dvP<1){}else if(c.bars%16===0)abyssWipe(c,.6,true,true);else if(c.bars%8===0)abyssWipe(c,0,false,true);
      if(c.bars%32===24&&rand()<.35)c.ink=0;
      }
    if(c.bR<8){c.bR+=dt*c.bSp;if(c.bR>2.4){c.bR=9;c.famA=c.famB;c.palA=c.palB;c.sdA=c.sdB;}}
    // the floor rises into view for reef visits (kelp towers, coral) and sinks away for open water
    const reefOn=c.zone===2;
    c.hf=ez(c.hf,reefOn?.75:c.zone===1?3.4:c.kelp?1.5:2.6,reefOn?1.6:.5);c.swd=ez(c.swd,c.famB>=5?1:.3,.3);c.reef=ez(c.reef,reefOn?1:0,reefOn?1.5:.6);
    // kaleidoscope on Auto: the realm walks through four of its best folds (16 bars each, one 8-bar unfolded look at the giants
    // mid-visit), stepping on to the next fold on a drop; the order comes from a hash so the seeded rand() is untouched
    // (the Auto Show's own plan, built from R.auto, takes over when it runs the kaleidoscope)
    const engKal=typeof autoActive==='function'&&autoActive('symmetry')&&V.kal;
    if(!engKal&&(typeof E!=='undefined'&&E.symmetry?E.symmetry:S.symmetry)==='auto'){
      if(!c.kq){const o=[6,8,4,12,5].map((k,i)=>[abyssHash(c.sdA*.731+c.famA*3.1+i*1.37)-(i<2?.25:0),k]).sort((x,y)=>x[0]-y[0]).map(x=>x[1]);
        c.kq=[o[0],o[1],0,o[2],o[3]];c.ki=0;c.kb=0;c.kt=0;}
      c.kt+=dt;if((F.onBar || F.onSceneBar))c.kb++;
      const len=c.kq[c.ki]?16:8;
      if(((F.onBar || F.onSceneBar)&&c.kb>=len)||c.kt>len*2.6||(drop&&c.kb>=4)){c.ki=(c.ki+1)%c.kq.length;c.kb=0;c.kt=0;}
      V.sym=c.kq[c.ki];
    }
    const nf=(typeof effectiveSym==='function'?effectiveSym(V):V.sym)||0,folded=nf>1,
      asp=typeof innerWidth!=='undefined'&&innerHeight>0?innerWidth/innerHeight:16/9;
    // hero: every 8 bars it picks a new spot and swims there in strokes (moves on each contraction), leaning into the
    // swim. Folded, the kaleidoscope samples the wedge just above the +x axis (0..180/n degrees), so the hero turns on
    // its side with its tentacles streaming along the middle of that wedge: every 8 bars it alternates between its
    // bell over the centre (a rosette with rays of tentacles) and a ring of n jellies round the centre (a flower)
    if(((F.onBar || F.onSceneBar)&&c.bars%8===4)||folded!==c.fold){c.fold=folded;const sd=(c.hx>0?-1:1)*((F.onBar || F.onSceneBar)&&c.bars%16===12?-1:1);
      c.hxT=(folded?sd:c.side)*(.33+.13*rand());c.hyT=.03+.12*rand();if(folded)c.kRing=!c.kRing;}
    let tl=0;
    if(folded){const phi=Math.PI/(2*nf),r0=c.kRing?.3:.04;
      c.hxT=r0*Math.cos(phi)/(asp*.5);c.hyT=r0*Math.sin(phi);tl=phi+Math.PI/2;}
    const mv=dt*((folded?.6:.05)+1.6*pulseNow)*sp,dx=(c.hxT-c.hx)*mv,dy=(c.hyT-c.hy)*mv;
    c.hx+=dx;c.hy+=dy;
    // the counterweight (usually the octopus) keeps to the opposite side on a smooth spring (folded: out on the wedge)
    const cws=1.4*(1-.6*(Number(F.smooth??S.motionSmooth)||0)),cr=folded?.62:0,ph2=folded?Math.PI/(2*nf):0;
    c.cwx=ez(c.cwx,folded?cr*Math.cos(ph2)/(asp*.5):-c.hx*1.12,cws);c.cwy=ez(c.cwy,folded?cr*Math.sin(ph2)-.05:-c.hyT*.7-.07,cws);
    c.htl=ez(c.htl,folded?tl:Math.max(-.5,Math.min(.5,-dx/Math.max(dt,1e-3)*4)),folded?1.5:2.5);
    c.glow=ez(c.glow,.6*c.bass+.5*c.lvl,4);
    // tentacle / arm ripple speed rides the mids, comb-row rainbow, octopus skin and margin pinwheel ride the hats
    c.tp=(c.tp+dt*sp*(.35+1.6*c.mid)*(1-.4*c.brk))%(Math.PI*20);
    c.cp=(c.cp+dt*sp*(.5+3.5*c.hat+.8*c.high))%(Math.PI*20);
    c.ch=(c.ch+dt*sp*(.6+5*c.hat+1.5*c.build))%(Math.PI*2);
    // lantern-fish schools swirl with the presence band and tighten into a fast ball on builds
    c.sch=(c.sch+dt*sp*(.22+.5*B[5]+1.4*c.build))%1000;
    c.camT+=dt*sp*.25;
    const inf=Number.isFinite(PTR.inf)?PTR.inf:0;
    const cx=.05*Math.sin(c.camT*.37)+PTR.x*.06*inf,cy=.035*Math.sin(c.camT*.23+1)+PTR.y*.04*inf;
    const P=abyssPack,u=v=>Math.max(0,Math.min(1,v/3+.5)),rg=(x,y,r,a)=>[P(u(x),u(y)),Math.floor(Math.min(r,3.99)*1024)+Math.min(Math.max(a,0),1.49)/1.5],
      wp=w=>rg(w[0],w[1],w[2],w[3]),bp=b=>rg(b[0],b[1],.06+.5*Math.sqrt(b[2]),b[3]*Math.exp(-b[2]*2.2));
    V.p1=[c.swim,V.mt%628.3185,P(c.kT/10,c.carry/1.5),P(c.lo,c.bloom)];
    V.p2=[P(c.ink/100,Math.min(c.mid,1)),P(c.gath,Math.min(1,1.5*c.hatS)),c.sch,c.dv];
    V.p3=[...wp(c.w[0]),...wp(c.w[1])];V.p4=[...bp(c.bu[0]),P(c.lvT/4,c.lvA),P(c.arms/8,c.burst)];
    const PA=ABYSS_PALS[c.palA],PB=ABYSS_PALS[c.palB];
    // v22b impact envelope: 1 at a strong arrival, gone in half a second; the shader dips the picture by it (and cancels the engine's drop exposure with uDrop)
    c.ik=c.pushT<1.6?Math.exp(-c.pushT*3.5)*(.45+.55*Math.min(1,c.pushT/.12)):0;
    V.p5=[P(c.ball,c.hp%1),c.spin,c.bR+Math.round(c.bK*10)*100+Math.floor(c.ik*15)*10000,P(PA[0],PA[1])];
    V.m1=new Float32Array([c.famA*1000+c.sdA,c.famB*1000+c.sdB,(c.hf<1.8?1:0)+2*c.octo+4*(c.shA*8+c.shB)+256*c.deal+65536*c.post+Math.min(.98,Math.max(0,c.mk)),P(c.reef,c.swd),P(PA[2],PA[3]),P(PB[0],PB[1]),
      P(Math.min(c.glow,1.99)/2,c.brk),P(c.hf/4,(c.htl+1)/5),P(c.schF/9.99,c.shT)]);
    c.comp=ez(c.comp,folded?0:1,2.5);
    V.m2=new Float32Array([P(cx+.5,cy+.5),P((c.de||0)*.7*(1-.6*c.brk)/.75,c.bw[0]),Math.floor(Math.min(c.kAmp,4)*1000)+Math.min(c.comp,.999),P(c.hx/2+.5,c.hy/2+.5),P(c.schS,c.bw[1]),c.tp,c.cp,P(PB[2],PB[3]),P(c.cwx/2+.5,c.cwy/2+.5)]);
  }
  },
