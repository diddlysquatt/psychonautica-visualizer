
  {
    key:'eschr',name:'ESCHR',src:R_ESCHR,cost:2,cont:[],description:'living temple city: terraces, screws and pistons that move to the music',
    fb:{zoom:0,rot:0,decay:.05,warp:0,echo:0,droste:0,win:0,key:.05,live:.1},syms:[0,0,0,0,6,5,3,8,4,12],kalZoom:.9,
    auto:{kal:[0],kalCycle:false,kalZoom:.9,bars:40,kind:'3d',tier:1,transitions:['portal','leak'],fx:{warp:0,chroma:.06,trails:.1,bloom:.3,flashes:.2},
      notes:'v18: close up, the architecture itself moves with the music'},
    init:s=>{
      const pal=Math.floor(s[0]*ESCHR_PALS);
      return{palA:pal,palB:pal,pm:1,t:0,flow:0,cx:s[1]*4000,cy:s[2]*4000,hats:0,hatAge:1,flC:0,flP:1,bars:0,k:0,hit:0,eB:0,eM:0,eH:0,eA:0,hist:[],hi:0,ht:0,sB:0,sM:0,sH:0,gen:Math.floor(s[3]*8)+1,fr:-20,frOn:0,lastD:0,
        // v21: a beat clock of our own and the stepped clock made from it, the dance figure, the drop envelope, stature, tide, heading, the cheer, the mark
        bc:0,bi:0,stI:0,go:1,st:0,wv:s[3],fig:Math.floor(s[2]*97)%5,figW:0,phr:0,seg:-1,chP:s[3],amp:0,all:0,dT:9,sT:9,dk:Math.floor(s[0]*7)%2,stat:.4,wl:-1.3,tide:0,tideB:-99,
        bo:0,cheerT:0,hd:Math.floor(s[1]*97)%4,hx:0,hy:0,spd:1,wd:Math.floor(s[2]*7)%4,rd:0,wsp:2.3,lastR:-99,pd:1,sgA:1,sgN:Math.floor(s[0]*4),sgT:24+s[3]*16};
    },
    frame(V,F,dt){
      const c=V.c,sm=x=>x*x*(3-2*x),ex=t=>1-Math.exp(-dt/t),L=BANDS.lv;
      const follow=(cur,tg,up,dn)=>cur+(tg-cur)*(1-Math.exp(-dt/((tg>cur)?up:dn)));
      c.t+=dt*S.speed;
      c.eB=follow(c.eB,Math.max(L[0],L[1]),.07,.28);c.eM=follow(c.eM,.5*(L[2]+L[3]),.08,.3);
      c.eH=follow(c.eH,.5*(L[4]+L[5]),.07,.26);c.eA=follow(c.eA,.5*(L[6]+L[7]),.07,.26);
      c.sB=follow(c.sB||0,c.eB,1.2,1.2);c.sM=follow(c.sM||0,c.eM,1.2,1.2);c.sH=follow(c.sH||0,c.eH,1.2,1.2);
      c.flow+=dt*(.25+.9*c.eM);c.k=follow(c.k,Math.min(1,F.kick),.06,.24);c.hi=follow(c.hi||0,Math.min(1,F.hit),.06,.24);c.ht=follow(c.ht||0,Math.min(1,F.hat),.06,.22);
      const live=Math.min(1,3*Math.max(F.level,c.eB,c.eM,c.eH,c.eA,c.k,c.hi,c.ht)),pump=(x,s,on)=>Math.min(1,Math.max(0,(6*(x-s)+on)*live));
      const pB=pump(c.eB,c.sB,1.9*Math.max(0,c.k-.24)),pM=pump(c.eM,c.sM,1.5*Math.max(0,c.hi-.18)),pH=pump(c.eH,c.sH,1.5*Math.max(0,c.ht-.18));c.hit+=(Math.min(1,F.hit)-c.hit)*ex(.09);
      c.hatAge=Math.min(.999,c.hatAge+dt/.6);if(F.hat>.4&&c.hatAge>.3){c.hats=(c.hats+1)%4000;c.hatAge=0;}
      if(F.onHit&&c.flP>=1){c.flC=(c.flC+1)%4000;c.flP=0;}c.flP=Math.min(1,c.flP+dt/.8);
      c.gB=follow(c.gB||0,Math.min(1,pB+.5*c.k),.13,.45);c.gM=follow(c.gM||0,pM,.12,.42);c.gH=follow(c.gH||0,pH,.1,.38);c.hist.push([c.t,c.gB]);if(c.hist.length>220)c.hist.shift();
      const delays=[0,.09,.18,.27,.36,.45,.54,.63].map(d=>{const T=c.t-d,h=c.hist;for(let i=h.length-1;i>0;i--){if(h[i-1][0]<=T){const a=h[i-1],b=h[i],f=(T-a[0])/Math.max(b[0]-a[0],1e-5);return a[1]+(b[1]-a[1])*Math.min(1,f);}}return h[0][1];});
      // v21 the beat. This clock never runs backwards; it is pulled gently onto the beat phase the engine hears. The stepped clock st takes one eased step
      // in the first half of each beat and rests in the second: stairs, screws, chasers and walkers all move on it. It holds while the walkers cheer, and in
      // silence it steps every other beat.
      const bpm=F.bpm>40?F.bpm:110,bar=F.onBar||F.onSceneBar,drop=F.onDrop||F.drop>c.pd+.4,P=48;c.pd=F.drop;
      let db=dt*bpm/60*S.speed;if(F.conf>.15){const e=F.beatClock-(c.bc+db);db+=(e-Math.round(e))*ex(.18);}
      c.bc+=Math.max(0,db);c.cheerT=Math.max(0,c.cheerT-dt);
      const cheer=Math.min(1,c.cheerT/.7),bi=Math.floor(c.bc),bf=c.bc-bi;
      if(bi!==c.bi){c.bi=bi;c.stI+=c.go;c.go=(cheer>.2||(live<.08&&bi%2))?0:1;}
      c.st=c.stI+c.go*sm(Math.min(1,bf/.5));
      // drops: everyone dances and the walkers jump; then, in turn, the city rebuilds in a ring out of the middle of the view, or it stands up tall and the
      // camera turns down another street. The tide goes out on every drop. With no drop for a long while a calmer rebuild crosses on a diagonal.
      if(bar){c.bars++;if(F.onBar)c.bo=Math.round(c.bc)%4;}                    // bo: where the bar line falls on our beat count
      c.dT+=dt*bpm/240;c.sT+=dt*bpm/240;
      const newPal=()=>{if(c.pm>=1){c.palB=(c.palA+1+Math.floor(rand()*(ESCHR_PALS-1)))%ESCHR_PALS;c.pm=0;}};
      const wave=(rd,wd,sp)=>{c.frOn=1;c.rd=rd;c.wd=wd;c.wsp=sp;c.fr=rd?-.25:-9;c.lastR=c.t;};
      if(drop){c.lastD=c.t;c.dT=0;c.cheerT=2.4;c.tide=0;newPal();
        if(c.dk++%2===0&&c.frOn===0)wave(1,c.wd,4.6);else{c.sT=0;c.hd=(c.hd+(rand()<.5?1:3))%4;}
      }else if(c.t-c.lastD>38&&c.frOn===0){c.lastD=c.t;newPal();wave(0,(c.wd+1)%4,2.3);}
      else if(bar&&c.bars%16===0&&c.frOn===0&&c.t-c.lastR>12)wave(0,(c.wd+1+Math.floor(rand()*3))%4,2.3);
      c.pm=Math.min(1,c.pm+dt/5);if(c.pm>=1)c.palA=c.palB;
      // the front sweeps a fixed span of the city, far wider than any view; it is stately inside the part that can be seen and quick outside it.
      // A site only changes kind as the front passes over it, when it is fully down. Between rebuilds every site reads the same generation.
      const zE=Math.max(.1,PTR.zoom*(V.kz||1)),ext=clamp(.5/zE+3.2,3.5,9);
      if(c.frOn){c.fr+=dt*(Math.abs(c.fr)<ext?c.wsp:14);if(c.fr>9){c.frOn=0;c.gen=(c.gen+1)%60;}}
      const dEnv=c.dT<2?1:Math.max(0,1-(c.dT-2)/2);
      c.all+=(Math.max(dEnv,.55*F.build)-c.all)*ex(.12);
      c.stat=follow(c.stat,clamp(.4+.5*Math.max(0,1-c.sT/8)-.3*F.breakdown,0,1),.3,3);
      // the dance figure, one to a phrase of eight bars, never the same twice running: 0, 1 a wave of performers crossing on one diagonal or the other,
      // 2 soloists (a new handful of sites each bar), 3 call and answer (the sites are a chessboard; black monuments, black streets, white monuments, white
      // streets take two beats each), 4 rings out of the middle of the view.
      // Stepped figures and changes of figure pass through stillness, so nothing pops; breakdowns and silence are still.
      const phr=Math.floor(c.bars/8);if(phr!==c.phr){c.phr=phr;c.figW=1;}
      c.wv+=dt*bpm/480;let want=1;
      if(c.fig<2||c.fig===4)c.chP=c.wv%1;
      else{const n=c.fig===2?4:2,pb=c.bc-c.bo,sg=Math.floor(pb/n);
        if(pb/n-sg>1-.3/n||sg!==c.seg)want=0;
        if(sg!==c.seg&&c.amp<.06){c.seg=sg;c.chP=c.fig===3?(sg%4)*.25:rand();want=1;}}
      if(c.figW){want=0;if(c.amp<.04){c.figW=0;let f;do{f=Math.floor(rand()*5);}while(f===c.fig);c.fig=f;c.seg=-1;}}
      if(F.breakdown>.5||live<.08)want=0;
      c.amp+=(want-c.amp)*ex(want>c.amp?.09:.06);
      // the tide: in breakdowns, and for one phrase now and then, the water rises over the streets and squares and the city stands in a lagoon
      if(bar&&c.bars%8===0){if(!c.tide&&c.bars>=16&&c.bars-c.tideB>=32&&c.dT>6&&rand()<.3){c.tide=1;c.tideB=c.bars;}else if(c.tide&&c.bars-c.tideB>=8)c.tide=0;}
      {const tw=(c.tide||F.breakdown>.5)?1.34:-1.3;c.wl+=(tw-c.wl)*ex(tw>c.wl?1.6:.3);}
      // the camera walks down one of four streets and turns on some drops; it goes a little faster when the music is loud
      {const h=[[.72,.48],[-.48,.72],[-.72,-.48],[.48,-.72]][c.hd];if(c.hx===0&&c.hy===0){c.hx=h[0];c.hy=h[1];}
        c.hx+=(h[0]-c.hx)*ex(2.2);c.hy+=(h[1]-c.hy)*ex(2.2);c.spd+=(.7+.6*Math.min(1,F.level*1.4)-c.spd)*ex(1.5);}
      const v=.65*S.speed*c.spd;c.cx+=dt*v*c.hx;c.cy+=dt*v*c.hy;
      if(Math.abs(c.cx)>P*3000)c.cx-=Math.sign(c.cx)*P*3000;if(Math.abs(c.cy)>P*3000)c.cy-=Math.sign(c.cy)*P*3000;
      // the mark surfaces once or twice in a visit, on a snare or a bar line, somewhere else each time
      c.sgA=Math.min(1,c.sgA+dt/1.9);
      if(c.sgA>=1&&c.t>c.sgT&&(F.onHit||bar)&&c.frOn===0){c.sgA=0;c.sgN++;c.sgT=c.t+55+rand()*50;}
      const fd=[[.62,.78],[-.78,.62],[-.62,-.78],[.78,-.62]][c.wd],front=c.rd?c.fr:(c.cx*fd[0]+c.cy*fd[1])/P+c.fr;
      V.p1=[c.t,c.flow,c.st,c.wl];V.p2=[c.cx,c.cy,c.gen+.96*c.sgA,c.frOn?front:-5000];
      V.p3=delays.slice(0,4);V.p4=delays.slice(4,8);V.p5=[c.gB,c.gM,c.gH,c.eA];
      c.bL=c.bL||new Float32Array(8);for(let i=0;i<8;i++)c.bL[i]=follow(c.bL[i],L[i]||0,.07,.26);
      const qb=x=>Math.round(clamp(x,0,1)*4095),bl=c.bL,pk=(a,b)=>qb(a)+4096*qb(b),q8=x=>Math.round(clamp(x,0,1)*255);
      V.m1=new Float32Array([c.k*S.dose,c.hit,c.flC*2+Math.min(.999,c.flP),c.hats+c.hatAge,q8(c.chP)+256*q8(c.all)+65536*q8(c.amp),
        q8(cheer)+256*q8(c.stat)+65536*(c.fig+8*c.rd+16*c.wd+64*(c.sgN%4)),pk(bl[0],bl[1]),pk(bl[2],bl[3]),pk(bl[4],bl[5])]);
      V.m2=eschrPack(c.palA,c.palB,sm(c.pm),.12*Math.sin(c.t*.03));V.m2[8]=pk(bl[6],bl[7]);
    }
  },
