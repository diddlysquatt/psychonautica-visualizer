  {
  key:'cathedral',continuousJourney:true,cont:['hue'],name:'Elf',src:R_CATHEDRAL,cost:2.6,kalZoom:.8,
  fb:{zoom:0,rot:0,decay:.24,warp:.02,echo:.06,droste:0,win:.45,key:.2,live:.6},syms:[0,0,0,0,0,6,8,12,8,6,4,5],
  // v12 Auto Show (v12/b0_kal, 3 seeds x 2 times at kalZoom .8): 6/8 are full stained-glass rose windows on every seed,
  // 12/5/4/16 good, unfolded is the journey with the elves; 2 slices the corridors, 3 is uneven
  auto:{kal:[6,8,0,12,5,4,16],kalCycle:true,kalZoom:.8,tier:2,kind:'3d',bars:32,transitions:['portal','leak'],fx:{trails:.66,bloom:.9},
    notes:'v12: great in kaleidoscope; 6/8 best, 12/5/4/16 good, unfolded keeps the elves and the journey'},
  init:seed=>elfTourInit(seed),
  // test hooks (route fast-forward for review renders)
  tools:{tick:(c,fr,dt)=>elfTourResidentTick(c,fr,dt),step:(c,dt,a,t)=>elfTourStep(c,dt,a,t),de:p=>elfDE(p),at:(c,d)=>elfTourAt(c,d)},
  frame(V,F,dt){
    const c=V.c,ed=Math.max(0,dt);
    // Travel is locked to the beat: V.trav already runs double-time after a drop, half-time in breakdowns and
    // faster through a build; on top, each beat gives a smooth forward surge (velocity peaks just after the kick).
    if(c.lt==null)c.lt=V.trav;
    const dtr=Math.max(0,Math.min(.5,V.trav-c.lt));c.lt=V.trav;
    const calm=Math.max(0,Math.min(1,Number(S.motionSmooth)||0));
    const surge=1+.1*(1-.6*calm)*Math.cos(2*Math.PI*((F.beat||0)-.12))*Math.min(1,(F.conf||0)*1.5);
    if(F.drop>.6&&c.lastDrop<=.6){
      // the drop: a burst of speed down the nave and a new jewel palette, while the lamps flare in its colours
      c.boostT=1;if(c.palM>0)c.palA=c.palB;c.palN++;c.palB=(c.palA+1+c.palN%4)%6;c.palM=.001;c.palRate=2.2;c.palBeats=0;
    }
    c.lastDrop=F.drop;
    c.boostT*=Math.exp(-ed/1.6);c.boost+=(c.boostT-c.boost)*(1-Math.exp(-ed*3.5));
    c.palBeats+=dtr;
    if(c.palBeats>80&&c.palM===0){c.palN++;c.palB=(c.palA+1+c.palN%4)%6;c.palM=.001;c.palRate=.25;c.palBeats=0;}
    if(c.palM>0){c.palM+=ed*c.palRate;if(c.palM>=1){c.palA=c.palB;c.palM=0;}}
    // the user's zoom: zoomed out, the director prefers the great halls and the camera pulls back and up
    const zm=Math.max(.1,Math.min(4,((typeof PTR!=='undefined'&&PTR.zoom)||1)*(V.kz??1)));
    c.bigPref=.3+.3*(.5+.5*Math.sin(V.trav*.017+V.seed[2]*6.28));   // v13: zoom no longer steers the route toward the great halls (zoom is a camera move only)
    c.diving=!!(c.segs[0]&&c.segs[0].dive);
    // meeting a resident, the explorer slows down to look (the beat lock is kept: only the rate dips); in the great
    // halls it glides faster, so a crossing of the colossal spaces still takes only a few bars
    const advRaw=ELF_BEAT_DIST*dtr*surge*(1+1.4*c.boost)*(1-.22*(c.meet||0))*(1+.9*c.vastS);
    // v11: the speed is low-passed per second (tempo changes, drops and meetings glide instead of lurching) and a
    // cruise floor keeps the explorer moving through quiet passages and when the beat clock stalls
    const vWant=Math.max(ed>0?advRaw/ed:0,ELF_BEAT_DIST*.9*(1+.9*c.vastS));
    c.vS=c.vS==null?vWant:c.vS+(vWant-c.vS)*(1-Math.exp(-ed*(2-1.3*calm)));
    const adv=c.vS*ed;
    // gaze phrases: in the second half of every eight bars the camera looks toward the nearest resident ahead
    const ph=(V.trav/32)%1;c.lookWant=Math.max(.85*(c.meet||0),Math.max(0,Math.min(1,Math.min((ph-.45)*8,(.97-ph)*8))));c.trav=V.trav;
    c.buildS=(c.buildS||0)+((F.build||0)-(c.buildS||0))*(1-Math.exp(-ed*1.5));
    const fr=elfTourStep(c,dt,adv,S.speed*(1+1.4*c.boost)*(1+.6*c.buildS));
    // v11: ride lower in the corridors (it hugged the ceiling), only where the stone below leaves room
    {const lw=1-Math.min(1,Math.abs(fr.f[1])*1.4),d0=elfDE(fr.p),q=[fr.p[0],fr.p[1]-.11*fr.sig,fr.p[2]],ok=elfDE(q)>=.6*d0?1:0;
     c.low=(c.low||0)+(lw*ok-(c.low||0))*(1-Math.exp(-ed*.8));fr.p=[fr.p[0],fr.p[1]-.11*fr.sig*c.low,fr.p[2]];}
    if(c.reinit){c.reinit=0;c.camS=null;elfTourResidents(c,{p:fr.p,f:fr.f},true);for(const e of c.inhabitants)e.fade=0;}
    // how vast the space around the explorer is (in its own size): from the naves (0) to the colossal halls (1)
    const vs=Math.max(0,Math.min(1,(elfDE(fr.p)/fr.sig-.45)/2.2));c.vastS+=(vs-c.vastS)*(1-Math.exp(-ed*.8));
    const camRaw=elfTourPull(c,fr,zm,ed);
    // v11: a critically damped spring on the camera position rounds the corners of the route (no kinks); it resets
    // at a dive hop (the world is re-expressed 3x bigger) or any jump larger than the explorer's own size
    if(!c.camS||Math.hypot(camRaw[0]-c.camS[0],camRaw[1]-c.camS[1],camRaw[2]-c.camS[2])>fr.sig){c.camS=camRaw.slice();c.camV=[0,0,0];}
    {const w=13-5*calm,h=Math.min(ed,.05);for(let i=0;i<3;i++){c.camV[i]+=(w*w*(camRaw[i]-c.camS[i])-2*w*c.camV[i])*h;c.camS[i]+=c.camV[i]*h;}}
    const cam=c.camS.slice();
    // a build narrows the lens (tension), the drop throws it wide; zooming out widens it a little (never a fisheye)
    // the recursive vault throws the lens wide (the rabbit hole)
    c.diveW=(c.diveW||0)+((c.diving?1:0)-(c.diveW||0))*(1-Math.exp(-ed*1.2));
    c.fl+=(.94+.34*c.buildS-.16*c.boost-.22*c.diveW-c.fl)*(1-Math.exp(-ed*2.5));
    c.beam+=(.35+.7*F.build+.4*F.drop+.4*F.sub-c.beam)*(1-Math.exp(-ed*3));
    // (v20b) how quiet the passage is (exact exponential steps, stable at any dt): it comes up within a tenth of a second when the level falls,
    // as fast as the lamps go down, and leaves over most of a second when the music returns. The painted fill of the stone follows it, so no
    // passage is dark. The raw level stays above about .5 between the kicks of a loud passage, so the fill does not pump against the beat.
    { const lv=F.level??0,qT=1-Math.min(1,Math.max(0,(lv-.4)/.2));if(c.quiet===undefined)c.quiet=1;c.quiet+=(qT-c.quiet)*(1-Math.exp(-ed*(qT>c.quiet?8:1.5))); }
    const zl=zm<1?Math.pow(zm,.22):1;
    V.p1=[...cam,Math.max(.53,c.fl*zl)];
    // the room theme: crystal grotto, elf workshop, garden of light per region of the temple, the vault while diving
    const seg=c.segs[0],tt=seg&&seg.theme!=null?seg.theme:elfRegionTheme(c,fr.p);
    if(c.thM===0&&tt!==c.thB){c.thA=c.thB;c.thB=tt;c.thM=.001;}
    if(c.thM>0){c.thM+=ed*.4;if(c.thM>=1){c.thA=c.thB;c.thM=0;}}
    const vastU=Math.max(0,Math.min(1,c.vastS+.6*(1-Math.min(zm,1)))),ks=fr.sig/9;
    // the camera basis carries the explorer's scale; its right vector (rebuilt in the shader) carries the theme,
    // the vastness of the space and the beat count
    V.m1=new Float32Array([c.thA*8+c.thB+Math.min(c.thM,.999),Math.floor(vastU*255)+.001+.998*Math.min(1,Math.max(0,c.quiet)),(V.trav%256+256)%256,...fr.u.map(x=>x*ks),...fr.f.map(x=>x*ks)]);
    elfTourResidentTick(c,fr,dt);
    const pos=c.inhabitants.map(e=>elfTourResidentPosition(c,e,F.kick));
    const fade=c.inhabitants.map(e=>e.fade),gr=c.inhabitants.map(e=>e.greet||0);
    V.p3=[...pos[0],elfTourPackFade(fade[0],fade[1],gr[0],gr[1])];V.p4=[...pos[1],elfTourPackFade(fade[2],fade[3],gr[2],gr[3])];V.p5=[...pos[2],elfTourPackFade(fade[4],fade[5],gr[4],gr[5])];
    V.m2=new Float32Array([...pos[3],...pos[4],...pos[5]]);
    V.p2=[c.palA*8+c.palB+Math.min(c.palM,.999),c.hue,elfTourPackChars(c),c.beam];
  }
},
