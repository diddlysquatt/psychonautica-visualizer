  {
  key:'marbl',name:'MARBL',src:R_MARBL,cost:1.3,cont:[],description:'Liquid marbling played live',kalZoom:.45,
  fb:{zoom:0,rot:0,decay:.12,warp:0,echo:.02,droste:0,win:0,key:.2,live:.12},syms:[0,0,0,0,0,6,6,8,12,4,16,5],
  auto:{kal:[0,12,8,6,16],kalCycle:true,kalZoom:.78,tier:2,kind:'flat',transitions:['melt','leak'],fx:{warp:.25},notes:'v12: folds rendered at kalZoom .45 and .68 on 3 seeds; at .45 the print frame cuts the folds into black-leaded polygons, from ~.7 the fold stays inside the marbled print (only the corners touch the frame), so Auto folds at .78; 12/8/6/16 make full marbled rosettes, 2-5 show the frame'},
  init:s=>{
    const R=marblRng(s);
    const c={ops:[],tr:0,lt:null,palC:-1,palP:0,styC:0,styP:0,recipe:0,form:0,ang0:0,sp0:3,sz0:1,fk:0,fa:0,fc:[0,0],sk:0,nS:0,gold:0,
      bathBars:0,bathLen:8,recent:[],cLo:0.3,cHi:0.6,H:s[3]*20,Hs:s[3]*20,hp:0,sw:0,bE:0,rockT:0,rockS:0,lastKick:-9,lastHit:-9,lastLM:-9,lastBand:-9,autoB:0,xd:0,xb:0,
      clIn:-99,clOut:-99,zv:1,zIn:-99,zOut:-99,zLast:0,cam:marblCamNew(s),camReq:0,xcam:0,dn:null,dnKind:0,dnBar:9,mu:[1,1,1,1],clSeed:Math.floor(s[2]*4000),bdT:0,bars:0,lift:null,lastLift:0,
      spl:[{g:[0,0],t:-99,ink:0,sz:0},{g:[0,0],t:-99,ink:0,sz:0}],wells:[[0,0]],bq:[[0,0]],sun:[0,0],tree:0,agS:0,wellK:0};
    marblPrepare(c,R);
    s[2]=2048*4096;s[3]=98304;   // (v21: the camera's two words live here; the generators above have taken what they need from the seed)
    return c;
  },
  frame(V,F,dt){
    const c=V.c,R=rand;dt=Math.min(Math.max(dt,0),0.1);
    const tr=V.trav;if(c.lt===null){c.lt=tr;const d=tr-c.tr;for(const o of c.ops)if(o.t0!==undefined)o.t0+=d;for(const q of c.spl)q.t+=d;c.lastLift+=d;}c.lt=tr;c.tr=tr;
    const ex=r=>1-Math.exp(-dt*r);
    const build=Math.max(F.build||0,c.xb||0),bd=F.breakdown||0;
    c.bE+=(build-c.bE)*ex(build>c.bE?2:0.8);
    c.bdT=bd>0.5?c.bdT+dt:0;
    const B=typeof BANDS!=='undefined'?BANDS:null;
    // running range of the spectral centroid, so ink choice follows what is bright or dark in this track
    const ce=F.cent??0.45;c.cLo=Math.min(ce,c.cLo+dt*0.01);c.cHi=Math.max(ce,c.cHi-dt*0.01);
    // a collage: torn prints from the gallery laid over the live bath for a few bars, then lifted away
    const collage=(hold)=>{if(tr>c.clOut+1.5){c.clSeed=(c.clSeed+1+Math.floor(R()*50))%4000;c.clIn=tr;c.clOut=tr+hold;}};
    // a reveal: now and then the view pulls far back to show the whole gallery of prints marbling along, then
    // glides back in (eased over beats, never a jump)
    const reveal=(hold)=>{if(tr>c.zOut+3){c.zIn=tr;c.zOut=tr+hold;c.zLast=tr;c.zDep=0.6+0.22*R();c.camReq=1;}};
    // drops: a fresh bath (new palette, recipe, formation) poured over the old one; sometimes a collage on top
    if((F.onDrop||c.xd)&&!c.lift){const xc=c.xd===2,xz=c.xd===3,xl=c.xd===4;c.xd=0;
      if(xl)marblLift(c,R);
      else{const xr=c.xrec;marblFlood(c,R,true,xr);c.xrec=undefined;const u=xr!==undefined&&!xc&&!xz?0.5:R();if(xc||(!xz&&u<0.3))collage(8+4*Math.floor(R()*2));else if(xz||u>0.85)reveal(6+2*Math.floor(R()*2));}}
    if((F.onBar || F.onSceneBar)){c.bathBars++;c.bars++;
      const fi=c.ops.findIndex(o=>o.k==='flood'),used=fi>=0?fi+1:c.ops.length;   // ops in this bath (older ones go when its pour lands)
      if((c.bathBars>=c.bathLen||used>=marblCAP-5)&&c.bE<0.3&&!c.lift){
        // now and then the finished print is pulled off the bath first; a long breakdown pours a quiet suminagashi bath
        // (v21: a print is only pulled when the camera is free to walk off into the gallery while the next bath is poured)
        const pull=R()<0.3||tr-c.lastLift>480;
        if(pull&&c.cam.mode===0&&c.cam.w>c.cam.minW&&tr>c.clOut+1.5)marblLift(c,R);
        else if(pull&&used<marblCAP-5&&!c.held){c.held=1;c.bathLen=c.bathBars+2;}   // (no pull now: the bath is worked two bars longer, as it was while a sheet was being lifted)
        else{c.held=0;marblFlood(c,R,false,c.bdT>4&&R()<0.7?6:undefined);
          const u=R();if(u<0.12)collage(4+4*Math.floor(R()*2));else if(u>0.9||tr-c.zLast>600)reveal(8);}
      }}
    // the pull: settle, turn the sheet over (about 3 beats), let it go, then pour the next bath from the hinge side
    let lw=0;
    if(c.lift){const L=c.lift,la=tr-L.t0;
      if(la>=7.2&&!L.flooded){L.flooded=true;const e=[[-1.25,0],[1.25,0],[0,0.78],[0,-0.78]][L.side];marblFlood(c,R,false,undefined,e);}
      lw=Math.max(1,Math.min(1023,Math.round(la*48)))+1024*L.side+4096*(L.flooded?1:0);
      if(la>11.2)c.lift=null;}
    // a finished flood hides everything older: prune it
    {const i=c.ops.findIndex(o=>o.k==='flood');
     if(i>=0){const o=c.ops[i];
       // a phrase bath gets its return pass as the pour lands (its first stroke already rode the pour)
       if(o.phrase&&!o.combed&&marblProg(o,tr)>0.8){o.combed=true;if(i<=1&&c.bE<0.3){c.lastHit=tr;marblStroke(c,F,R);}}
       if(o.done||marblProg(o,tr)>=1){o.done=true;c.ops.length=c.ops.indexOf(o)+1;c.palP=c.palC;c.styP=c.styC;}
       else{const j=c.ops.findIndex((q,k)=>k>i&&q.k==='flood');if(j>=0)c.ops.length=j+1;}}}
    // build: a fine comb rocks back and forth on every snare, harder as the build rises
    if(c.bE>0.3&&c.dn)marblDanceStop(c);
    const top=c.ops[0];
    if(c.bE>0.3&&!(top&&top.rock)&&c.ops.length<marblCAP-2&&!marblBusy(c)){
      const ang=((c.ops.find(o=>o.k==='comb'||o.k==='wave')||{ang:c.ang0}).ang+8)%16;
      marblPush(c,{k:'comb',ang,sp:6,amp:15,off:Math.floor(R()*128),lam:1,rock:true,val:0,t0:tr,dur:1,ease:'io'});
      c.rockT=0;c.rockS=0;
    }
    const rk=c.ops[0]&&c.ops[0].rock&&!c.ops[0].dance?c.ops[0]:null;
    if(F.onKick&&!F.silent){c.lastKick=tr;if(!rk)marblSite(c,F,R,false,c.form===5?(B&&B.lv[0]>B.lv[1]?0:1):undefined);}
    if(F.onHit&&!F.silent){if(rk)c.rockT+=1;else if(tr-c.lastHit>1.5){c.lastHit=tr;marblStroke(c,F,R);}}
    // colour wells: a sharp onset in the low-mid ... air bands drops that band's ink into its own well
    if(B&&c.form===5&&!rk&&!F.silent&&tr-c.lastBand>0.9&&tr-c.lastKick>0.2){
      let bb=-1,bv=0.8;for(let b=2;b<8;b++){const v=B.on[b]*(0.6+0.4*B.lv[b]);if(v>bv){bv=v;bb=b;}}
      if(bb>=0){c.lastBand=tr;marblSite(c,F,R,false,Math.min(5,bb===7?5:bb-(bb>4?1:0)));}
    }
    // a sharp low-mid accent (a bass stab, a tom, a chord) pulls a flower or a rose through the newest drop
    if(B&&!rk&&!F.silent&&c.form!==5&&B.on[2]>0.85&&B.lv[2]>0.6&&tr-c.lastLM>6&&tr-c.lastHit>0.75&&c.ops.length<marblCAP-3&&c.recent.length&&c.recipe!==4&&c.recipe!==13&&!marblBusy(c)){
      c.lastLM=tr;const o=marblLocal(c,R,c.bars,['f','r','f','b']);o.t0=tr;o.dur=o.k==='vort'?1.2:1.1;o.ease='io';marblPush(c,o);}
    // no kicks (silence, breakdowns, ambient tracks): the marbler keeps working on the beat grid, slowly
    const ab=Math.floor(tr/2);
    if(ab!==c.autoB){c.autoB=ab;if(tr-c.lastKick>3&&!rk){if(ab%2===0)marblSite(c,F,R,true,c.form===5?Math.floor(R()*6):undefined);else if(ab%4===1&&tr-c.lastHit>3)marblStroke(c,F,R);}}
    if(rk){
      c.rockS+=(c.rockT-c.rockS)*ex(9);
      const A=0.35+0.65*Math.min(1,c.bE);
      const tgt=c.bE>0.15?A*Math.sin(c.rockS*Math.PI/2+0.0001):0;
      rk.val+=(tgt-rk.val)*ex(6);
      if(c.bE<0.15&&Math.abs(rk.val)<0.004){c.ops.shift();}
    }
    // hats: a sprinkle of droplets each (more when the air band is busy)
    const h=F.hat||0,hatOn=h-c.hp>0.15;if(hatOn)c.H+=1;c.hp=h;
    // the dancer (v21): joins in a bar or more into the bath and dances until the next pour; what the music is made of is tallied
    {const kw=1/(0.55+0.6*(F.smooth??0.75)),m=c.mu,dk=Math.exp(-dt/10),live=!F.silent;
     m[0]=m[0]*dk+(F.onKick&&live?0.05:0);m[1]=m[1]*dk+(F.onHit&&live?0.1:0);m[2]+=((F.bass||0)*1.6-m[2])*(1-dk);m[3]=m[3]*dk+(hatOn&&live?0.02:0);
     if(c.dn)marblDance(c,F,dt,kw,{kick:F.onKick&&live,hit:F.onHit&&live,hat:hatOn&&live,bar:F.onBar});
     else if(c.dnKind>0&&!c.xnd&&c.bathBars>=c.dnBar&&c.bE<0.3&&!c.lift&&live&&c.ops.length<marblCAP-5&&!marblBusy(c)&&!(c.ops[0]&&c.ops[0].rock)&&tr-c.lastKick<4)marblDanceStart(c);}
    if(B&&B.on[7]>0.9&&B.lv[7]>0.7)c.H+=dt*6;
    if(F.silent||F.idle>0.5)c.H+=dt*0.8;
    c.Hs+=(c.H-c.Hs)*ex(14);
    {const t=(F.bass||0)*0.7+(F.sub||0)*0.4;c.sw+=(t-c.sw)*ex(t>c.sw?7:2.5);}
    // the camera (v21): see marblCam. A pulled print or a reveal asks for a walk in the gallery; the camera goes when it is free.
    {const cm=c.cam;if(c.lift&&tr-c.lift.t0<0.5)c.camReq=1;
     marblCam(c,F,dt,Math.max(0,Math.min(2,tr-(cm.tr??tr))),(typeof PTR!=='undefined'?PTR.zoom:1)*(V.kz||1)*0.86,F.smooth??0.75,tr<c.clOut+1.5);
     cm.tr=tr;c.zv=cm.z.x;}
    // pack
    const N=Math.min(c.ops.length,marblCAP),W=new Array(30).fill(0),pr=[1,1,1];
    for(let i=0;i<N;i++){const o=c.ops[i];W[i]=marblWord(o);if(i<3)pr[i]=marblProg(o,tr);}
    const q12=v=>Math.round((Math.max(-1,Math.min(1,v))*0.5+0.5)*4095);
    const pk=c.palC+16*c.palP+256*c.styC+1024*c.styP+4096*Math.round(Math.min(1,c.bE)*255);
    const ca=Math.max(0,Math.min(1,(tr-c.clIn)/1.5,(c.clOut+1.5-tr)/1.5));
    const sp=q=>{const ag=tr-q.t;if(ag<-0.3||ag>3)return 0;return q.g[0]+64*q.g[1]+2048*Math.max(0,Math.min(255,Math.round((ag+0.5)*48)))+524288*q.ink+4194304*q.sz;};
    const zq=Math.round(Math.max(0,Math.min(1,c.zv))*4095),sq=Math.round(Math.max(0,Math.min(1,c.sw*S.dose/1.5))*4095);
    // the camera's words (see the shader): the op list keeps all 28 of its own
    const cm=c.cam,sl=Math.max(0,Math.min(15.999,cm.sl.x)),si=Math.floor(sl),sf=Math.min(255,Math.floor((sl-si)*256)),qi=(v,lo,span,n)=>Math.max(0,Math.min(n-1,Math.round((v-lo)/span*n)));
    V.p1=[N+64*q12(pr[0])+262144*(si+16*cm.ep),q12(pr[1])+4096*q12(pr[2]),(tr%3600+3600)%3600+400,Math.round(ca*255)+256*c.clSeed+1048576*(sf>>4)];
    V.p2=[pk+1048576*(sf&15),c.Hs%7000,sp(c.spl[0]),zq+4096*sq];
    V.p3=W.slice(0,4);V.p4=W.slice(4,8);V.p5=W.slice(8,12);
    W[28]=sp(c.spl[1]);
    {const u=Math.sign(cm.px.x)*Math.sqrt(Math.min(1,Math.abs(cm.px.x)/3));
     W[29]=lw+8192*Math.max(0,Math.min(2047,Math.round((u+1)*1024)));
     if(V.seed){V.seed[2]=Math.max(0,Math.min(4095,Math.round(cm.th.x/1.2*4095)))+4096*qi(cm.ya.x,-0.8,1.6,4096);
       V.seed[3]=qi(cm.py.x,-24,32,131072)+131072*(cm.O/2)+4194304*(cm.dup?cm.dup/2-3:0);}}
    V.m1=new Float32Array(W.slice(12,21));V.m2=new Float32Array(W.slice(21,30));
  }
  },
