{
  key:'spiro',name:'GUILL0',src:R_SPIRO,cost:1,cont:['spd'],description:'an engraved neon banknote sheet',
  fb:{zoom:0,rot:0,decay:.06,warp:0,echo:.02,droste:0,win:0,key:.34,live:.15},syms:[0,0,0,6,6,8,12,16,4,5],kalZoom:.6,
  auto:{kal:[0,6,8,12,16,4,5],kalCycle:true,kalZoom:.6,transitions:['kaleido','portal','shatter'],notes:'v12: zoomed out (and in tours) each 3x3 block of notes carries a giant two-family guilloche rosette whose lobes bloom with the band of their sector, lit by the air band, kick ring riding out through it; kick lights every note frame, air/hats glitter the bead chains and line glints. v11: unfolded is the hero (5 layouts incl. the spirograph garden, a grinning engraved sun mascot, four wipe styles, grand-tour events); 6/8/12 turn the notes into rosette clusters, 16 a fine doily; 2/3 crop the notes'},
  init:s=>{
    const lay=[0,1,2,3,5,2][Math.floor(s[0]*6)%6],pal=Math.floor(s[1]*9)%9,sd=s[2],sub=Math.floor(s[3]*7)%3;
    return {lay,pal,sd,sub,tsc:1,tsT:1,old:{sd,lay,pal,sub},wp:1,wd:1,pa:s[3]*6.283,pb:s[1]*6.283,spd:.7+s[3]*.6,kr:5,ka:0,jv:0,js:0,sn:0,br:0,hp:0,fl:s[1],sc:0,df:0,bars:0,ts:0,lt:null,pd:0,dropReq:0,
      kp:0,bn:0,bv:0,kw:0,hc:0,hp2:0,la:0,cz:.96,czR:.7,s0:s[0]*6.283,tour:0,bt:0,wt:0,loupe:0,lpS:0};
  },
  frame(V,F,dt){
    const c=V.c;dt=Math.min(Math.max(dt||0,0),.1);
    const ex=r=>1-Math.exp(-dt*r),TAU=6.283185307;
    spiroBands(c,dt);
    const bd=F.conf>.4&&F.bpm>0?60/F.bpm:.5,bk=F.breakdown||0;
    if(c.lt===null)c.lt=V.trav;const dtr=Math.max(0,Math.min(.5,V.trav-c.lt));c.lt=V.trav;
    // kick: a ring of light (and a slight bulge) rides out from the hub
    if(F.onKick){c.kr=0;c.ka=Math.min(1.2,.6+.5*F.kick)*(.6+.4*S.dose);}
    c.kr=Math.min(c.kr+dt*1.7/(.6*bd),9);c.ka*=Math.exp(-dt*2.2);
    // (v18) bass pump: a critically damped spring on bass + a kick pulse; line weight swells with the kick; hats step a counter
    if(F.onKick)c.kp=1;c.kp*=Math.exp(-dt*5);
    {const w=26-14*(S.motionSmooth==null?.75:S.motionSmooth),T=Math.min(1.4,.5*(c.b[0]+c.b[1])*.9+.75*c.kp);const x=c.bn-T,e=Math.exp(-w*dt),j=(c.bv+w*x)*dt;c.bv=(c.bv-w*j)*e;c.bn=T+(x+j)*e;}   // exact critically damped step: stable at any dt
    c.kw+=(Math.min(1,.9*c.kp+.35*c.b[1])-c.kw)*ex(c.kp>c.kw?16:5);
    {const h=F.hat||0;if(h>.55&&(c.hp2||0)<.35)c.hc=(c.hc+1)%64;c.hp2=h;}
    // snare: counter-rotation jolt (impulse -> smoothed velocity), plus a flash on the engraved rings
    if(F.onHit){c.jv=Math.min(2.5,c.jv+1.1);c.sn=1;}
    c.jv*=Math.exp(-dt*3.2);c.js+=(c.jv-c.js)*ex(10);c.sn*=Math.exp(-dt*6);
    const spin=c.spd*(.45+1.8*F.build+.35*c.b[3])*(1-.5*bk);
    c.pa=(c.pa+dt*(spin+3.2*c.js)*S.speed)%TAU;
    c.pb=(c.pb+dt*(spin*.8+3.2*c.js)*S.speed)%TAU;
    c.br+=((.65*c.b[1]+.35*c.b[0])-c.br)*ex(5);
    c.hp=(c.hp+dt*(2.5+9*F.high)*S.speed)%(TAU*40);
    c.fl=(c.fl+dt*(.03+.07*F.level)*S.speed)%1;
    c.sc=(c.sc+dtr*.25*(1+F.build)+dt*.02*S.speed)%6;
    // drop: radial wipe into a new layout and palette; every 8 bars a new seed sweeps in
    if(c.dropIn>0){c.dropIn-=dt;if(c.dropIn<=0)c.dropReq=1;} // test hook: schedule a drop
    const drop=F.onDrop||F.drop>(c.pd||0)+.4||c.dropReq;c.pd=F.drop;c.ts+=dt;
    if(drop){c.dropReq=0;if(c.wp<1)c.old=spiroOld(c);spiroReconf(c,true);c.df=1;c.tour=0;c.czR=3.5;c.la=1;}
    else if((F.onBar || F.onSceneBar)){
      c.bars++;
      if(c.bars%8===0&&c.wp>=1)spiroReconf(c,c.bars%16===0||spiroRand()<.3);

      // rare surprise: a grand tour, the camera pulls far back over the sheet for 8 bars and drifts
      if(c.bars%16===4&&F.build<.2&&c.tour<=0&&(spiroRand()<.3||c.bars<8))c.tour=32;
    }
    else if(c.ts>40&&F.conf<.3&&c.wp>=1)spiroReconf(c,false);
    c.df*=Math.exp(-dt*1.8);
    if(c.wp<1){c.wp=Math.min(1,c.wp+dt/(c.wd*bd*2));if(c.wp>=1)c.old=spiroOld(c);}
    const wr=c.wp>=1?9:(1-Math.pow(1-c.wp,2.2))*1.35;
    // realm camera: a little back from the note by default (the sheet shows at the edges), pushes in through a build,
    // pulls back over the sheet in breakdowns and tours, returns quickly (but smoothly) on a drop
    c.bt+=(F.build-c.bt)*ex(2);
    if(c.tour>0)c.tour-=dtr;
    if(c.loupeIn){c.loupe=32;c.loupeIn=0;}   // test hook
    if(c.loupe>0)c.loupe-=dtr;c.lpS+=((c.loupe>0&&c.tour<=0?1:0)-c.lpS)*ex(1.2);
    let czT=c.tour>0?.36:(.96-.36*Math.min(1,bk*1.4));
    czT*=1+.2*c.bt;
    c.czR+=(.7-c.czR)*ex(.8);
    c.cz+=(czT-c.cz)*ex(c.czR);
    const pz=(typeof PTR!=='undefined'&&PTR.zoom)||1,cz=Math.max(c.cz,.11/pz),pull=Math.max(0,Math.min(1,(.95-cz)*2.2));
    c.s0=(c.s0+dt*.09*pull*S.speed)%(TAU*100);
    V.p1=[c.pa,c.pb,1+Math.max(-.02,.15*c.bn)*S.dose,cz];
    // build: the engraved rings flash on a pulse that subdivides as the build rises (1, 2, then 4 per beat)
    const bsub=F.build>.7?4:(F.build>.35?2:1),bp=F.build*Math.pow(.5+.5*Math.cos(TAU*V.trav*bsub),6);
    V.p2=[c.kr,c.ka,c.s0,Math.max(c.sn,.75*bp)];
    V.p3=[wr+16*(c.wt||0),c.fl,c.hp,c.sc];
    c.tsc+=((c.tsT||1)*(1-.14*c.bt)-c.tsc)*ex(.5+2*c.bt);   // tiles tighten as a build rises
    V.p4=[c.old.sd,c.sd,(c.old.lay*4+(c.old.sub||0))*16+c.old.pal,(c.lay*4+(c.sub||0))*16+c.pal];
    const hue=(typeof D!=='undefined'?D.hue:0)+((F.cent||.45)-.45)*.35,pn=spiroPal(c.pal,hue),po=spiroPal(c.old.pal,hue);
    const lv=(typeof REALM_LIVE!=='undefined'&&REALM_LIVE.spiro!=null)?REALM_LIVE.spiro:1,spn=(typeof D!=='undefined'&&D.spin)||0;
    V.p5=[Math.min(c.df,.999)+2*(Math.round(Math.max(0,Math.min(1,c.kw))*63)+64*c.hc),c.tsc,spn*(.25+.75*lv),po[4]];
    V.m1=new Float32Array([c.b[0],c.b[1],c.b[2],c.b[3],c.b[4],c.b[5],c.b[6],c.b[7],c.la]);
    V.m2=new Float32Array([pn[0],pn[1],pn[2],pn[3],pn[4],po[0],po[1],po[2],po[3]]);
  }
  },
