  {
  key:'scribe',name:'GL1PH',src:R_SCRIBE,cost:1.1,cont:[],evolves:true,description:'an illuminated book the size of a cathedral floor, in a script nobody can read, written stroke by stroke by the music',
  fb:{zoom:0,rot:0,decay:.1,warp:0,echo:0,droste:0,win:0,key:.05,live:.05},syms:[0,0,0,0,8,6,12,4,2],kalZoom:.8,
  auto:{kal:[0,0,0,2,4,8,6],kalCycle:true,kalZoom:.8,zoom:[.2,1.6],transitions:['kaleido','melt','portal'],kind:'flat',fx:{bloom:.3,chroma:.1,flashes:.5,trails:.3,warp:.15},notes:'v22 wave 3 (GL1PH). A camera orbits the great book in an amphitheatre of library books; the quill writes on the beat, the leaf turns on sections, a drop throws the opening up in fragments.'},
  init:(s)=>{
    const r=scribeRng(fract(Math.sin(s[0]*12.9898+s[1]*78.233+s[2]*37.719+s[3]*11.13)*43758.5453));
    const A=scribeForm(r,null);
    const c={rnd:r,A,B:A,turnR:0,bcur:0,line:0,cell:0,cT:0,fill:-1,pass:3,lineT:0,burst:4,lens:new Array(36).fill(0),
      hd:0,hdT:0,hdP:5,gl:0,glT:0,glP:2,wall:r()*400,ip:1,is:1+Math.floor(r()*1000),kickA:9,kgap:9,impA:9,impS:0,impK:0,snA:9,noteA:9,
      ten:0,press:1,kq:0,kp:0,cc:[0,0],cb:[0,0],cbv:[0,0],pgs:0,done:false,sinceGo:20,kc:0,rk:0,sc:0,sn:0,hc:0,hw:0,fp:0,hgap:9,sgap:9,sigT:-1,sigGap:25+30*r(),sigV:0,lt:r()*6,cam:[0,0],camv:[0,0],pp:0,bp:0,phr:0,secGap:0,sinceTurn:0,sig:0,hatP:0,
      az:(r()<.5?-1:1)*(.5+.5*r()),el:.9,azO:(r()<.5?-1:1)*(.45+.55*r()),elO:0,ph1:r()*6.3,ph2:r()*6.3,camT:0,rot:0,rotq:0,pt:0,ptD:2,pend:false};
    c.azv=0;c.elv=0;c.fk=0;c.fkv=0;c.fkq=0;c.pen=[0,.3];c.penv=[0,0];
    {const Ly=SCRIBE_LAY[A.lay];for(let l=0;l<36;l++){const C=l<Ly.n?Ly.C(l):19;c.lens[l]=Math.max(2,C-Math.floor(r()*C*.35));}}
    c.line=Math.floor(r()*4);c.cell=c.cT=Math.floor(r()*Math.min(6,SCRIBE_LAY[A.lay].C(c.line)));
    return c;
  },
  frame(V,F,dt){
    const c=V.c,r=c.rnd;
    dt=clamp(Number.isFinite(dt)?dt:0,0,.25);
    const L=typeof BANDS!=='undefined'?BANDS.lv:null,bps=clamp((F.bpm>0?F.bpm:120)/60,.5,4),bs=1/bps;
    const dose=clamp(Number(S.dose)||0,0,1.5),spd=clamp(Number(S.speed)||0,0,2.5);
    const bass=L?Math.max(L[0],L[1]):(F.bass||0),mid=L?.5*(L[2]+L[3]):(F.mid||0),high=L?Math.max(L[5],L[6],L[7]):(F.high||0);
    const zoom=typeof PTR!=='undefined'?clamp(PTR.zoom,.15,2.5):1;
    // the beat: where the cue clock's pulse wraps (or the old beat phase when there is no confident pulse)
    let onBeat=false;
    if((F.beatConf||0)>.3){const pl=F.pulse||0;if(pl<c.pp-.5)onBeat=true;c.pp=pl;}else{const b=F.beat||0;if(b<c.bp-.3)onBeat=true;c.bp=b;}
    const down=F.onDownbeat||(((F.downConf||0)<.25)&&(F.onBar||F.onSceneBar));
    c.ten=ease(c.ten,F.tension||0,dt,.4);
    const lay=SCRIBE_LAY[c.A.lay];
    // ---- the main hand (mids): a burst of letters on every beat, more when loud; the line ends on the bar line
    const C=lay.C(c.line),c0=c.cell;
    if(c.fill<0){
      if(onBeat){const k=Math.max(1,Math.round((1.4+4.2*Math.pow(mid,.8)+2.2*c.ten)*Math.min(1,.4+dose)*C/19));c.cT=Math.min(C,c.cT+k);c.burst=Math.max(2,k/(.42*bs));}
      c.cT=Math.min(C,c.cT+dt*(.02+.9*mid*mid)*spd);
      c.cell=Math.min(c.cT,c.cell+dt*c.burst*spd);
      c.lineT+=dt;
      if((down&&c.cell>=3)||(c.cell>=C-.001&&c.lineT>6.4*bs)||c.lineT>9){const len=Math.min(C,Math.max(1,Math.ceil(c.cell-.001)));c.cell=c.cT=len;c.lens[c.line]=len;c.fill=0;}
      c.wall+=Math.max(0,c.cell-c0);
    }else{
      const fl=dt/.32;c.fill+=fl;c.wall+=fl*Math.max(0,20-c.lens[c.line]);
      if(c.fill>=1){c.fill=-1;c.line++;c.cell=c.cT=0;c.lineT=0;if(c.line>=lay.n){c.line=0;c.pass++;c.done=true;}else if(c.sinceTurn>24)c.done=true;}
    }
    // ---- the big hand (bass): a stroke of the headline on every kick, the bass itself pushes on
    c.kgap+=dt;c.kickA+=dt;
    if(F.onKick&&(F.kick||0)>.3&&c.kgap>.14){c.kgap=0;c.kickA=0;c.hdT+=1;c.kq+=.25;c.kc+=1;c.rotq+=1;c.fkq=Math.max(c.fkq||0,.05+.06*clamp(F.kick||0,0,1));}
    c.fkq=(c.fkq||0)*Math.exp(-dt*7);scribeSpr(c,'fk',c.fkq,16,dt);
    scribeSpr(c,'rot',c.rotq,11/(1+.6*(F.smooth||0)),dt);
    scribeSpr(c,'rk',c.kc,15/(1+.5*(F.smooth||0)),dt);if(c.kc>=8&&c.rk>=8){c.kc-=8;c.rk-=8;}
    scribeSpr(c,'kp',c.kq,9/(1+(F.smooth||0)),dt);
    c.hdT+=dt*bass*bass*.5*spd;
    c.hd=Math.min(c.hdT,c.hd+dt*8*spd);
    if(c.hd>=21){c.hd-=21;c.hdT-=21;c.hdP++;}
    // ---- the small hand (highs): gloss, runs of it on the hats
    c.hgap+=dt;if(F.onHat||((F.hat||0)>.5&&c.hatP<.3)){c.glT+=5;if(c.hgap>.07){c.hgap=0;c.hc+=.5;}}
    scribeSpr(c,'hw',c.hc,20/(1+.5*(F.smooth||0)),dt);if(c.hc>=8&&c.hw>=8){c.hc-=8;c.hw-=8;}
    c.hatP=F.hat||0;
    c.glT+=dt*(.4+30*Math.pow(high,1.3)+22*c.ten)*spd*Math.min(1,.4+dose);
    c.gl=Math.min(c.glT,c.gl+dt*45);
    {const gcap=lay.n*90;if(c.gl>=gcap){c.gl-=gcap;c.glT-=gcap;c.glP++;}}
    // ---- the initial: redrawn by the big hand after an impact or a turn
    if(c.ip<1)c.ip=Math.min(1,c.ip+dt*(.3+.9*bass)*spd);
    // ---- impacts: gold floods the strokes; strong ones also bring a new initial, a real drop re-inks the wall
    c.impA+=dt;c.snA+=dt;c.noteA+=dt;c.sinceTurn+=dt;c.secGap+=dt;
    let imp=F.onImpact?(F.impactStrength||.5):0;
    if(!imp&&F.onDrop&&c.impA>.6)imp=.85;
    let turn=null,go=false;
    if(imp>0){c.impA=0;c.impS=imp>=.8?2:(imp>=.45?1:.45);if(imp>=.45&&c.ip>=1){c.is++;c.ip=0;}
      if(imp>=.8&&c.pt<=0){turn={fam:0,lay:0,pal:1,bor:.6,mode:.8,drop:true};go=true;}}
    c.sgap+=dt;if(F.onHit){c.snA=0;if(c.sgap>.12){c.sgap=0;c.sc+=1;}}
    scribeSpr(c,'sn',c.sc,13/(1+.5*(F.smooth||0)),dt);if(c.sc>=2&&c.sn>=2){c.sc-=2;c.sn-=2;}
    c.fp=(c.fp+dt*(.02+.9*(L?Math.max(L[4],L[5]):(F.high||0)))*spd)%1;
    if(F.onNote)c.noteA=0;
    // ---- sections turn the page: a new script, layout, palette or border spreads out from the initial
    if(F.onSection&&c.secGap>4&&c.pt<=0&&!(c.impS>1.5&&c.impA<2.8)&&!turn){c.secGap=0;const lo=F.secLow||0,hi=F.secHigh||0;turn={fam:1,lay:lo>.45?.7:.35,pal:hi>.35?.8:.5,bor:.4,mode:.85};go=true;}
    // a finished page turns: a new layout, palette or border (the script stays until the section changes); every third one the camera moves on
    if(c.done){c.done=false;c.pend=true;}
    if(F.onPhrase){c.phr++;if(c.sinceTurn>14)c.pend=true;}
    if(c.pend&&(down||c.sinceTurn>40)&&c.pt<=0&&c.turnR<=0&&!turn&&c.sinceTurn>6){c.pend=false;turn={fam:0,lay:.85,pal:.65,bor:.5,mode:.3};c.pgs++;if(c.pgs%3===0)go=true;}
    // the camera travels to another book at most every 16 s (sections can come seconds apart in a build); a real drop always travels
    c.sinceGo+=dt;if(go&&(c.sinceGo>12||imp>=.8)){c.azO=(c.azO>0?-1:1)*(.45+.6*r());c.elO=-.12+.3*r();c.sinceGo=0;}
    if(turn){c.B=c.A;c.A=scribeForm(r,c.A,turn);c.bcur=c.line*64+Math.floor(c.cell);c.turnR=.001;c.sinceTurn=0;if(!turn.drop){c.pt=.001;c.ptD=clamp(4*bs,1.3,2.6);}
      c.pass++;c.line=0;c.cell=c.cT=0;c.fill=-1;c.lineT=0;if(c.ip>=1){c.is++;c.ip=0;}}
    if(c.pt>0){c.pt+=dt/c.ptD;if(c.pt>=1)c.pt=0;}
    if(c.turnR>0){c.turnR+=dt*(1.5+3/zoom);if(c.turnR>3+16/zoom&&c.pt<=0&&!(c.impS>1.5&&c.impA<2.8)){c.turnR=0;c.B=c.A;}}
    // ---- the seal: once in a while, on a bar line, a span of a line just finished resolves into the owner's two words for two seconds
    c.sigGap+=dt;
    if(c.sigT>=0){c.sigT+=dt;if(c.sigT>2.6){c.sigT=-1;c.sigV=0;}}
    else if(c.sigGap>70&&c.turnR<=0&&c.fill>=0&&c.fill<.2&&c.line>0&&c.A.lay!==1&&r()<.5){const l=c.line-1,len=c.lens[l];
      if(len>=8){const st=r()<.5?0:Math.max(0,len-6);c.sigL=l;c.sigC=st;c.sigT=0;c.sigGap=0;}}
    if(c.sigT>=0)c.sigV=1+c.sigL*64+c.sigC+Math.min(c.sigT/3,.999);
    // ---- pressure and light
    c.press=ease(c.press,.85+.45*mid+.25*(F.energy||0)+.25*c.ten,dt,.08);
    c.lt=(c.lt+dt*(.12+1.1*mid)*spd)%(Math.PI*2);
    // ---- the camera stays on the page; closer in it follows the main pen
    {const Ly=SCRIBE_LAY[c.A.lay],l=Math.min(c.line,Ly.n-1),pn=Ly.pen(l,clamp(c.cell/Ly.C(l),0,1)),GS=6;
     const f=scribeSS(1,2.3,zoom)*.85,g=scribeSS(.62,1,zoom),tx=GS*(.3*g+(.535+pn[0])*f),ty=GS*(pn[1]+.02)*f-GS*.12*(1-g);   // the written leaf is the right-hand leaf of the great book
     for(let i=0;i<2;i++){const o={x:c.cam[i],xv:c.camv[i]};scribeSpr(o,'x',i?ty:tx,2.2/(1+(F.smooth||0)),dt);c.cam[i]=o.x;c.camv[i]=o.xv;}
     // the quill follows the main pen on a quick spring (it races along the line on the beat and swoops back at the line's end)
     for(let i=0;i<2;i++){const o={x:c.pen[i],xv:c.penv[i]};scribeSpr(o,'x',pn[i],15/(1+.5*(F.smooth||0)),dt);c.pen[i]=o.x;c.penv[i]=o.xv;}
     // the orbit: higher far out, low over the page close in; the azimuth drifts and swings to a new side on sections and drops
     c.camT+=dt*(.4+.6*spd);const zf=scribeSS(.2,1.6,zoom),sw=.8/(1+(F.smooth||0));
     const elT=clamp(1.08-.5*zf+c.elO+.07*Math.sin(c.camT*.07+c.ph1),.5,1.3),azT=c.azO+.3*Math.sin(c.camT*.045+c.ph2)+.08*Math.sin(c.camT*.13);
     scribeSpr(c,'az',azT,sw,dt);scribeSpr(c,'el',elT,sw,dt);}
    if(c.dbg){const d=c.dbg;if(d.cam){c.cam=d.cam.slice();c.camv=[0,0];}if(d.cc){c.cc=d.cc.slice();c.cb=[d.cc[0]*2.24,d.cc[1]*1.58];c.cbv=[0,0];}if(d.A)Object.assign(c.A,d.A);if(d.B)Object.assign(c.B,d.B);for(const k of ['line','cell','cT','fill','pass','hd','hdT','gl','glT','ip','turnR','impA','impS','sigV','snA','noteA','kickA','pt','az','el','rot'])if(d[k]!=null)c[k]=d[k];}
    // ---- uniforms
    const m1=new Float32Array(9);for(let i=0;i<6;i++){let v=0;for(let k=0;k<4;k++)v+=(c.lens[i*4+k]&31)*Math.pow(32,k);m1[i]=v;}
    const fr=(x,m)=>{const v=x/m;return clamp(v-Math.floor(v),0,.9995);};
    V.p1=[c.line,c.cell,c.pass+fr(c.hw,8),c.fill];
    V.p2=[c.hd,c.hdP+fr(c.sn,2),c.gl,c.glP+fr(c.rk,8)];
    V.p3=[c.wall,c.ip,c.lt,c.kickA];
    V.p4=[c.impA,c.impA<6?c.impS*Math.exp(-c.impA*.35):0,c.kp,c.snA];
    V.p5=[c.turnR,c.pt>0?c.pt:(c.turnR<=0?-clamp(c.fk||0,0,.2):0),Math.floor(c.fp*512)+clamp(c.ten,0,.999),c.press];
    m1[6]=c.az;m1[7]=c.el;m1[8]=c.rot;V.m1=m1;
    V.m2=new Float32Array([scribePack(c.A),scribePack(c.B),c.A.al,c.B.al,c.cam[0],c.cam[1],c.sigV,(c.is%64)+64*(Math.round(clamp((c.pen[0]+.4)/.8,0,1)*511)+512*Math.round(clamp((c.pen[1]+.62)/1.04,0,1)*511)),c.bcur]);
  }
  },
