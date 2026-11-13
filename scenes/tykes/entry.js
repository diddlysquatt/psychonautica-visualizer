  {
  key:'tykes',name:'TYK3S',src:R_TYKES,cost:1.4,cont:[],evolves:true,description:'the machine elf overlay: interlocking clockwork elves, laughing',
  fb:{zoom:0,rot:0,decay:.1,warp:0,echo:0,droste:0,win:0,key:.06,live:.06},syms:[0,0,0,0,8,6,5,12,16],kalZoom:.7,
  auto:{kal:[0,0,8,6,5,12,16],kalCycle:true,kalZoom:.7,zoom:[.22,1.3],transitions:['shatter','kaleido','portal'],kind:'flat',notes:'v22. unfolded is the hero view (the figures leaving their tiles and landing in each other\'s only read whole); 8, 6 and 5 fold it into mandalas of laughing faces; 12 and 16 only pulled back (the wedge is narrower than a figure at home); the mirrors (1, 2), 3 and 4 cut the faces in half, leave them out. Self-similar every factor of 4 in zoom: the largest figures are always between .4 and 1.6 of the frame height; home .6'},
  init:(s)=>{
    const r=tykesRng(fract(Math.sin(s[0]*12.9898+s[1]*78.233+s[2]*37.719+s[3]*11.13)*43758.5453));
    const c={rnd:r,D:0,DT:0,Dv:0,slots:[],pal:Math.floor(r()*12),palB:0,kq:0,lol:0,sw:r()*6,sway:0,swayv:0,swT:0,shk:0,shA:0,shP:0,bn:0,waves:[[0,0,-1],[0,0,-1]],
      kicks:0,bars:0,sK:0,hK:0,kgap:9,idle:0,evGap:0,lastEv:-1,mode:Math.floor(r()*4),dir:1,layA:0,layB:0,layBars:0,wipe:0,wipeOn:false,wty:0,shB:0,wPark:0,
      mpos:0,mrun:0,mdir:1,mpark:0,mend:14,wflip:0,flip:0,pour:0,pourv:0,pourT:0,build:0,pd:0,hatP:0,sgC:0,sgA:0,sgT:-1,sgArm:0,sgGap:30+30*r(),
      top:0,mv:{ty:0,st:0,u:0,dur:.3},calm:0,amp:1,ampv:0,ampT:1,pop:0,popT:0,chain:0,chainT:0,chainB:0,look:0,lookT:0,hyst:.3,hystB:0,deal:[-1,-1,-1],snr:0,noteGap:9,impGap:9,hgap:9,mK:0,mph:0};
    const f0=Math.floor(r()*3),sh=r()<.5?1:2;
    for(let i=0;i<3;i++)c.slots.push(tykesSlot(r,(f0+i*sh)%3));
    c.layA=tykesLay(r,-1);c.palB=c.pal;
    for(let f=0;f<3;f++)c.deal[f]=tykesDeal(r,f,-1);c.snr=Math.floor(r()*3);
    // (wave 3) the journey: the legs this visit was dealt, the stage under way (js) and the ones queued (jq)
    // (its own random stream, so that with the camera held the scene draws exactly the numbers it drew before the journey existed)
    c.rj=tykesRng(fract(Math.sin(s[0]*41.17+s[1]*7.31+s[2]*93.7+s[3]*27.9)*24634.6345));
    Object.assign(c,{jdeck:tykesJDeck(c.rj),ji:0,jq:[],js:null,jW:0,jHold:9,jSec:0,jg:0,jN:0,jLeg:'',dbN:0,hF:.42,hTop:.42});
    return c;
  },
  frame(V,F,dt){
    const c=V.c,bps=(F.bpm>0?F.bpm:120)/60,L=typeof BANDS!=='undefined'?BANDS.lv:null,r=c.rnd;
    dt=Math.max(0,Number.isFinite(dt)?dt:0);
    const sm=clamp(Number(F.smooth)||0,0,1),wS=22/(1+sm),dose=clamp(Number(S.dose)||0,0,1.5),spd=clamp(Number(S.speed)||0,0,2.5);
    const flat=(c.layA&3)===0&&!c.wipeOn;if(flat)c.lastFlat=c.layA;c.rugAge=(c.rugAge==null?99:c.rugAge)+dt;
    const P=((Math.round(c.DT)%3)+3)%3,sP=c.slots[P],sG=c.slots[(P+2)%3],sF=c.slots[(P+1)%3];
    const ten=clamp(Number(F.tension)||0,0,1);
    c.kgap+=dt;c.evGap+=dt;c.noteGap+=dt;c.impGap+=dt;c.hgap+=dt;
    // which level holds the characters (the figures with faces, the ones that leave their tiles): the largest level on screen (the
    // same rule as the shader), or the one below it when that one is so large that it is only a body made of small figures
    const zz=clamp(typeof realmZoom==='function'?realmZoom(V):1,.05,4),h0=.7*zz;
    let l0=Math.ceil(c.D+Math.log(h0/1.6)/Math.log(4)-1e-5);const lTop=l0;
    c.hTop=h0/(Math.pow(4,l0-c.D)*TYKES_FAM[c.slots[((l0%3)+3)%3].fam].fsc);
    if(c.hTop>.74)l0++;
    c.hF=h0/(Math.pow(4,l0-c.D)*TYKES_FAM[c.slots[((l0%3)+3)%3].fam].fsc);
    const topI=(c.layA&3)===0?((l0%3)+3)%3:0;
    const still=!c.mv.ty&&!c.mrun&&!c.pop&&Math.abs(Math.abs(c.amp)-1)<.01&&Math.abs(c.ampT)===1;
    if(topI!==c.top&&still&&!c.wipeOn){c.slots[c.top].flip=c.amp<0?1:0;c.top=topI;c.amp=c.ampT=c.slots[topI].flip?-1:1;c.ampv=0;c.calm=0;}
    const sT=c.slots[c.top],famT=sT.fam;
    // half the frame height in the largest level's own tile units
    const hhT=.5*2.5/zz*Math.pow(4,l0-c.D)*TYKES_FAM[famT].fsc,asp=typeof innerWidth==='number'&&innerHeight>0?clamp(innerWidth/innerHeight,1,2.4):1.78;
    let tick=0;
    if(F.onKick&&F.kick>.3&&c.kgap>.16){tick=1;c.kgap=0;c.kq=Math.min(1,.55+.6*F.kick)*Math.min(1,dose);}
    else if(c.kgap>1.4){c.idle+=dt*bps*.5*spd;if(c.idle>=1){c.idle-=Math.floor(c.idle);tick=.5;}}
    // a move in the air runs to its landing, then the figures have changed places for good
    if(c.mv.ty){c.mv.u+=dt/c.mv.dur;if(c.mv.u>=1){const t=c.mv.ty;if(famT===1||t===1)sT.nH=(sT.nH+1)&255;else if(t===2)sT.nV=(sT.nV+1)&255;c.mv.ty=0;c.mv.u=0;}}
    const canFly=flat&&still&&famT<2&&ten<.3&&dose>.3&&sT.awA>.98&&sT.awB>.98&&sT.morph<.01;
    let calmT=0;
    if(tick>0){
      c.kicks++;const k=c.kicks,st=TYKES_FAM[sP.fam].step;
      // what this kick is: one of the eight moves this visit was dealt (re-dealt at every new section)
      const ent=canFly||c.mv.ty?TYKES_DEAL[famT][c.deal[famT]][k%8]:0;
      const giant=c.top!==P;
      if(ent&&canFly&&!(giant&&k%2)){
        const ty=famT===1?1:(ent&7),sty=ent>>3,beat=1/bps,slow=famT===0?(sty&4?1.5:1):(sty&1?1.5:1.1);
        c.mv.ty=ty;c.mv.st=sty;c.mv.u=0;c.mv.dur=clamp(.44*beat,.2,.33)*slow*(giant?1.5:1)/Math.max(.4,spd);
      }
      // the mechanism ticks: four ways of counting (the largest level waits while its figures are in the air)
      if(!ent||sT!==sP){
        if(c.mode===0)sP.thT+=c.dir*st;
        else if(c.mode===1)sP.thT+=(k&1?1:-1)*st;
        else if(c.mode===2){if(!(k&1))sP.thT+=2*c.dir*st;}
        else sP.thT+=c.dir*st*(k%4===3?2:1)*(k%4===0?0:1);
      }else sP.thT+=.35*c.dir*st*(sP.fam===0?1:0);
      sF.thT-=c.dir*TYKES_FAM[sF.fam].step;
      if(k%4===0)sG.thT+=c.dir*TYKES_FAM[sG.fam].step;
      if(c.mode!==1||tick<1)c.swT=c.swT>0?-1:1;
      if(!flat&&k%2===0)c.pourT+=c.dir;
    }
    // the edges hold still while this stretch of the pattern is flown, and dance through the stretches that tick
    {const D8=TYKES_DEAL[famT][c.deal[famT]],k=c.kicks;calmT=(c.mv.ty||(canFly&&(D8[k%8]||D8[(k+1)%8])))?1:0;}
    c.calm+=(calmT-c.calm)*(1-Math.exp(-dt*(calmT>c.calm?26:9)));
    const ring=(i,x,y)=>{const w=c.waves[i];w[0]=x;w[1]=y;w[2]=0;};
    if(F.onHit){
      c.sK=(c.sK+1)%8;c.hystB=Math.min(.32,c.hystB+.02);
      if(c.mode===1)c.swT=c.swT>0?-1:1;
      ring(0,(r()-.5)*1.7*hhT*asp,(r()-.5)*1.6*hhT);
      // the snare has its own move on some visits: the board does a somersault, one half and then the other
      if(c.snr===1&&canFly&&!c.mv.ty&&famT===0&&c.top===P){c.mv.ty=3;c.mv.st=1+(c.sK&1);c.mv.u=0;c.mv.dur=clamp(.45/bps,.22,.34)/Math.max(.4,spd);}
    }
    // a note of the tune sets one figure off, high notes high in the picture
    if(F.onNote&&c.noteGap>.3&&(c.waves[1][2]<0||c.waves[1][2]>.5)){c.noteGap=0;ring(1,(r()-.5)*1.7*hhT*asp,((Number(F.notePos)||.5)-.5)*1.7*hhT);}
    if((F.onHat||((F.hat||0)>.5&&c.hatP<.3))&&c.hgap>.17){c.shA=1;c.hK=(c.hK+1)%8;c.hgap=0;}
    c.hatP=F.hat||0;
    c.shA*=Math.exp(-dt*8);c.shP=(c.shP+dt*40)%(2*Math.PI);c.shk=Math.sin(c.shP)*c.shA*Math.min(1,dose);
    c.kq*=Math.exp(-dt*5.5);c.lol*=Math.exp(-dt*.9);
    for(const s of c.slots){tykesSpr(s,'th',s.thT,wS,dt);tykesSpr(s,'lag',s.th,(c.mode===3?.3:.5)*wS,dt);}
    tykesSpr(c,'sway',c.swT*(.6+.5*Math.min(1,dose)),wS*.8,dt);
    tykesSpr(c,'pour',c.pourT,wS*.5,dt);
    const mid=L?0.5*(L[2]+L[3]):(F.mid||0),bass=L?Math.max(L[0],L[1]):(F.bass||0);
    c.sw=(c.sw+dt*(.8+5*mid)*spd)%(Math.PI*2);
    // the mids click the stripes round: up to five quarter-stripes a second
    c.mph+=dt*6.5*Math.max(0,mid-.12)*spd;if(c.mph>=1){c.mph-=Math.floor(c.mph);c.mK=(c.mK+1)%8;}
    // the bass leans on the mechanism: strips creep and wheels turn while it sounds
    for(const s of c.slots)s.thT+=dt*bps*(s===sP?.5:.2)*bass*bass*Math.min(1,dose)*c.dir*(s===sF?-1:1)*TYKES_FAM[s.fam].step;
    c.bn=ease(c.bn,bass*bass*Math.min(1,dose),dt,bass*bass>c.bn?.05:.2);
    c.build=ease(c.build,F.build||0,dt,.3);
    for(const w of c.waves)if(w[2]>=0){w[2]+=dt;if(w[2]>8)w[2]=-1;}
    // drift: each level slides slowly on its own; a ring layout turns instead
    c.slots.forEach((s,i)=>{const a=i*2.1+.4,v=.05*spd*(flat?1:.5);s.pan[0]+=dt*v*Math.cos(a);s.pan[1]+=dt*v*Math.sin(a)*(flat?1:0);});
    // the fit of laughter: louder music and every snare feed it, a new section starts it again, an arrival sets everyone off
    {const en=clamp(Number(F.energy)||0,0,1),base=.12+.4*en+c.hystB;c.hyst=ease(c.hyst,base,dt,c.hyst>base?2.2:.8);}
    // --- the rug gets pulled: on arrivals (graded by how hard they land), on new sections, and now and then on a phrase line when
    // neither comes: one thing about the picture turns out to be something else
    const bar=F.onBar||F.onSceneBar;
    c.layT=(c.layT||0)+dt;if(bar){c.bars++;c.layBars++;if(c.bars%2===0&&c.mode!==1)c.dir=-c.dir;if(c.bars%4===0)c.mode=(c.mode+1+Math.floor(r()*3))%4;}
    const drop=F.onDrop||((F.drop||0)>.85&&c.pd<.5);c.pd=F.drop||0;
    const imp=F.onImpact?clamp(Number(F.impactStrength)||0,0,1):0,sec=!!F.onSection;
    const settled=(Math.abs(c.D-c.DT)<.03||!!c.js)&&!c.wipeOn&&!c.mrun&&!c.pop;
    if(sec){for(let f=0;f<3;f++)c.deal[f]=tykesDeal(r,f,c.deal[f]);c.snr=Math.floor(r()*3);c.hystB=0;c.mode=(c.mode+1+Math.floor(r()*3))%4;}
    if(imp>0&&c.impGap>.6){c.impGap=0;c.hyst=Math.max(c.hyst,.75+.85*imp);c.kq=1;ring(1,0,0);}
    // folded twelve or sixteen times a figure at home is wider than the wedge: the scene answers with rings of that many figures
    const fold=V.kal&&S.autoShow&&V.kal.seq?(+V.kal.seq[V.kal.i]||0):(+S.symmetry||0),ringN=fold===16?13:(fold===12?12:0);
    // (wave 3) the journey runs unless the camera is held or someone zoomed by hand in the last 25 s; a new section is the journey's
    // when it is free to take it (the next leg goes at once: a dive, a climb, the rings or a seam), otherwise the old chapter rug-pull
    const userZ=typeof AUTOZ!=='undefined'&&typeof TIME!=='undefined'&&TIME-AUTOZ.userT<25;
    c.jOn=S.cameraMode!=='hold'&&!userZ;
    c.age=(c.age||0)+dt;
    const jFree=c.jOn&&c.age>8&&!c.js&&!c.jq.length&&flat&&!c.wipeOn&&!c.mrun&&!c.pop&&!ringN&&c.evGap>1.2;
    const big=(drop||imp>=.8)&&c.evGap>1.5,med=!big&&imp>=.45&&c.evGap>2.5,jTake=!big&&!med&&sec&&jFree,chap=!big&&!med&&sec&&c.evGap>3.5&&!jTake;
    if(sec&&!jTake&&c.jOn)c.jSec=1;
    const idle=!big&&!med&&!chap&&!jTake&&bar&&c.bars%8===0&&c.evGap>18&&ten<.3&&(F.drop||0)<.3;
    const ringOk=ringN>0&&((c.wipeOn?c.layB:c.layA)===1+4*ringN);
    // (the journey's rings stay 12 s by the clock, then go on the next bar: 14 bars was 26 s at 128 BPM)
    const stale=!flat&&!c.wipeOn&&(c.ringL>8?c.layT>=12:c.layBars>=8)&&bar&&c.evGap>(c.ringL>8?1.5:3)&&!ringN;
    const toB=(wty)=>{c.wty=wty;c.wipeOn=true;c.wipe=1e-3;c.lol=.8;c.flip=0;c.palB=(c.pal+1+Math.floor(r()*10))%12;};
    // one thing about the picture turns out to be something else (lean: the flat layout a seam or a fold brings, when the journey chose it)
    const fire=(ev,lean)=>{
      c.lastEv=ev;if(c.sgT<0&&c.sgGap>70&&r()<.35)c.sgArm=1;
      c.hyst=Math.max(c.hyst,.95);c.chainT=0;
      if(ev===0||ev===1){c.rugD=ev?1:-1;c.rugAge=0;}
      if(ev===0){c.DT-=1;c.lol=1;c.flip=0;}                                   // out: the whole tiling turns out to be the bodies of larger figures
      else if(ev===1){c.DT+=1;c.lol=1;c.flip=0;}                              // in: every figure is made of figures
      else if(ev===2){c.flip=(c.flip+1+(r()<.3?1:0))%3;if(!c.flip)c.flip=1;c.flipB=c.bars;}  // figure and ground change places
      else if(ev===3){c.mrun=1;c.mdir=r()<.5?-1:1;c.mend=flat?hhT*(asp+.6)+4.2:10.5;c.mpos=-c.mend*c.mdir;c.mpark=r()<.3?1:0;c.wflip=famT===0&&flat?1:0;c.palB=(c.pal+1+Math.floor(r()*10))%12;}   // a wave of cog blocks crosses the plane; the tower comes out of it on its hands
      else if(ev===4){c.ringL=8;c.layB=ringN?1+4*ringN:tykesLay(r,c.layA);if(stale){while(c.layB&3)c.layB=tykesLay(r,c.layA);if(c.jOn&&c.lastFlat)c.layB=0;}c.shB=0;toB(0);}   // a new layout opens from the middle
      else if(ev===5){for(const s of c.slots)s.cw=(s.cw+1+Math.floor(r()*2))%4;}                        // every figure changes its colours
      else if(ev===6){c.layB=lean!=null?lean:tykesFlat(r);c.shB=1+Math.floor(r()*2);toB((V.R&&V.R.hd)>=1?1:0);}                             // the plane folds like a paper fortune-teller into another family
      else if(ev===7){c.pop=1e-3;c.popT=clamp(.9/bps,.3,.7);c.ampT=0;}                                   // everyone folds into their cog (five faces in its windows) and unfolds changed
      else if(ev===8){c.chainT=1;c.chainB=c.bars;}                                                       // the outlines are chains of tiny figures holding hands
      else{c.layB=lean!=null?lean:(flat&&r()<.5?c.layA:tykesFlat(r));c.shB=1+Math.floor(r()*2);toB(2);c.palB=r()<.5?c.pal:c.palB;c.wPark=chap&&lean==null&&r()<.5?1:0;}   // metamorphosis: a seam crosses, one family goes in and another comes out
    };
    if(!ringN&&!c.wipeOn&&(c.layA&3)===1&&((c.layA>>2)&15)>=12)c.layBars=Math.max(c.layBars,8);
    if(ringN&&!ringOk&&!c.wipeOn&&settled&&c.evGap>.8){c.evGap=0;c.lastEv=4;c.layB=1+4*ringN;c.shB=0;toB(0);}
    else if(c.wipeOn&&c.wPark&&(big||med||chap||c.wPark<0)){c.wPark=0;c.evGap=0;}
    else if(imp>0&&imp<.45&&c.evGap>1.5){for(const s of c.slots)s.cw=(s.cw+1)%4;}
    else if(big||med||chap||idle||stale){
      c.evGap=0;
      let opts;
      if(stale)opts=[4];
      else if(big)opts=flat&&settled?[0,0,1,4,6,6,7,7]:(settled?[4,4,6]:[5]);
      else if(med)opts=flat&&settled?[7,7,2,8,3,3,5]:(settled?[3,8,5]:[5]);
      else if(chap)opts=flat&&settled?[9,9,6,3,4,2,8,0,1]:(settled?[4,4,3,6]:[5]);
      else opts=flat&&settled?[3,2,8,5,9]:(settled?[3,5,8]:[5]);
      if(!((V.R&&V.R.hd)>=1))opts=opts.map(o=>o===8?5:o);   // (the chains of tiny figures are drawn from Native up)
      if(c.sgT>=0)opts=opts.filter(o=>o===5||o===8||o===2).concat([5]);
      if(ringN)opts=opts.map(o=>o===6||o===9?4:o);
      let ev;do{ev=opts[Math.floor(r()*opts.length)];}while(ev===c.lastEv&&opts.some(o=>o!==c.lastEv));
      if(big&&flat&&settled&&c.lastEv!==0&&c.lastEv!==1&&drop)ev=r()<.6?0:1;
      // (wave 3) a dive or a pull-back that lands while a leg is travelling goes the leg's way: the two add up, never cancel (a leg
      // of two levels would come out on the family it left: everyone folds into their cogs instead); with no leg running, and
      // one family well ahead this visit, it goes towards the family seen less
      if((ev===0||ev===1)&&c.js&&c.js.dD)ev=Math.abs(c.js.dD)>=2?(c.lastEv===7?5:7):(c.js.dD>0?1:0);
      else if(c.jOn&&(ev===0||ev===1)&&c.fT){const fS=c.fT[0]+c.fT[1]+c.fT[2],sh=(d)=>c.fT[c.slots[(((l0+d)%3)+3)%3].fam];if(fS>30&&sh(ev?1:-1)>sh(ev?-1:1)+.08*fS)ev=1-ev;}
      fire(ev);
    }
    // --- (wave 3) THE JOURNEY. A visit never hovers at one framing: on every phrase line (eight bars, and the half phrase), at once on a
    // new section, and after at most eight seconds more without a line, the next leg it was dealt: down into the elves a figure is made
    // of, up to the giants it is part of (each level brings the next family to the top), a stop at the big characters or at the giants
    // made of elves, a long pan across the plane, the rings, a seam to a diagonal (or back upright) and another family. Each stage is
    // an eased glide of the scene's own depth (and pan), added to whatever the rug-pulls do; the engine's zoom waits while it runs.
    {
      const rj=c.rj;
      if(F.onPhrase)c.dbN=0;else if(F.onDownbeat)c.dbN++;
      const beat=1/bps,T=(Number(F.beatConf)||0)>.35?clamp(16*beat,7,10):8.5;
      const line=(Number(F.downConf)||0)>.3?(F.onPhrase||(F.onDownbeat&&c.dbN%2===0)):(bar&&c.bars%2===0);
      c.lnAge=line?0:(c.lnAge||0)+dt;   // a leg waits for a line as long as there are lines (none for 8 s: the clock)
      // (never on the frame a rug-pull fired: a drop's dive and a leg would land together)
      // (the engine's own excursion to close or far is waited for; its small drift round home is not)
      const eng=typeof AUTOZ!=='undefined'&&AUTOZ.dur>0&&Math.abs(Math.log(Math.max(AUTOZ.to,.01)/zz))>.15,rugD=c.rugAge<12?c.rugD:0,fired=c.evGap<1.2||c.rugAge<4;if(jTake&&fired)c.jSec=1;
      // time each family has been on top this visit: a leg that keeps the family waits behind one that changes it when one has had too much
      if(flat){c.fT=c.fT||[0,0,0];c.fT[famT]+=dt;}
      if(c.js){
        const s=c.js;s.t+=dt;const u=Math.min(1,s.t/s.dur),g=u*u*u*(u*(u*6-15)+10),dg=g-s.g;s.g=g;
        c.DT+=s.dD*dg;
        if(s.pan&&flat){const k=dg*s.pan*2.5/zz;c.camX=(c.camX||0)+dg*s.pan*s.ca;c.camY=(c.camY||0)+dg*s.pan*s.sa;for(let i=0;i<3;i++){const sl=c.slots[i],li=lTop+(((i-lTop)%3)+3)%3,q=k*Math.pow(4,li-c.D)*TYKES_FAM[sl.fam].fsc;sl.pan[0]+=q*s.ca;sl.pan[1]+=q*s.sa;}}
        if(u>=1){c.js=null;c.jW=0;c.jHold=s.hold;}
      }else{
        c.jW+=dt;
        if(c.jq.length){if(c.jW>=c.jHold&&(!eng||c.jW>c.jHold+6)&&!c.wipeOn)c.js=Object.assign(c.jq.shift(),{t:0,g:0});}
        else if(!fired&&(jTake||(jFree&&!eng&&c.jW>=(c.jSec?Math.min(c.jHold,1.2):c.jHold)&&(line||c.lnAge>8)))){
          // a section asks for a leg that changes something big: the next dive, climb, rings or seam in the deck comes forward
          const fS=c.fT?c.fT[0]+c.fT[1]+c.fT[2]:0,hog=fS>40&&c.fT[famT]>.38*fS;
          if(jTake||c.jSec||(hog&&['pan','close','far','ring'].includes(c.jdeck[c.ji])))for(let n=0;n<c.jdeck.length-c.ji;n++){const L=c.jdeck[c.ji+n];if(L!=='pan'&&L!=='close'&&L!=='far'&&!(hog&&L==='ring')){c.jdeck.splice(c.ji+n,1);c.jdeck.splice(c.ji,0,L);break;}}
          // a leg never undoes a rug-pull's dive or pull-back of the last twelve seconds: a stop that goes the other way waits its
          // turn, a dive or a climb turns round and goes the rug-pull's way
          if(rugD){const opp=rugD>0?['far']:['close'];if(opp.includes(c.jdeck[c.ji]))for(let n=1;n<c.jdeck.length-c.ji;n++)if(!opp.includes(c.jdeck[c.ji+n])){const L=c.jdeck.splice(c.ji+n,1)[0];c.jdeck.splice(c.ji,0,L);break;}}
          let L=c.jdeck[c.ji++];if(c.ji>=c.jdeck.length){c.jdeck=tykesJDeck(rj);c.ji=0;}
          // down one level and up one level lead to the two other families: after half a minute the leg turns towards the one
          // this visit has seen less of (never against a fresh rug-pull)
          {const FL={in:'out',out:'in',deep:'high',high:'deep'},dDo={in:1,out:-1,deep:2,high:-2},o=FL[L];
            if(o&&rugD){if((dDo[L]>0)!==(rugD>0))L=o;}
            else if(o&&fS>30){const sh=(x)=>c.fT[c.slots[(((l0+dDo[x])%3)+3)%3].fam]/fS;if(sh(L)>sh(o)+.08)L=o;}}
          c.jLeg=L;c.jN++;c.jSec=0;c.jW=0;
          const a=rj()*Math.PI*2,ca=Math.cos(a),sa=Math.sin(a),gap=2+2.5*rj(),h8=clamp(8*beat,3.5,6.5);
          const st=(dD,dur,pan,hold)=>({dD,dur,pan,hold,ca,sa});
          if(L==='in'||L==='out')c.jq.push(st(L==='in'?1:-1,T,.25,gap));
          else if(L==='deep'||L==='high')c.jq.push(st(L==='deep'?2:-2,1.7*T,.35,gap));
          else if(L==='close'){const on=rj()<.5;c.jq.push(st(.3,.6*T,.1,h8),st(on?.7:-.3,(on?.75:.6)*T,.1,gap));}
          else if(L==='far'){const on=rj()<.5;c.jq.push(st(-.5,.65*T,.15,h8),st(on?-.5:.5,.65*T,.15,gap));}
          else if(L==='pan')c.jq.push(st(0,.9*T,1.2,gap));
          else{c.evGap=0;c.jHold=gap;if(L==='ring'){fire(4);c.ringL=14;}else fire((V.R&&V.R.hd)>=1&&rj()<.4?6:9,tykesLean(rj,c.layA));}
          if(c.jq.length)c.js=Object.assign(c.jq.shift(),{t:0,g:0});
        }
      }
      c.jg=c.js||c.jq.length?1:0;
    }
    if(c.chainT&&c.bars-c.chainB>=6)c.chainT=0;
    if(c.flip&&c.bars-(c.flipB||0)>=4)c.flip=0;
    c.chain+=(c.chainT-c.chain)*(1-Math.exp(-dt*3.5));
    if(c.lookT>0){c.lookT-=dt;c.look+=((c.lookT<2.6&&c.lookT>.4?1:0)-c.look)*(1-Math.exp(-dt*7));}else c.look*=Math.exp(-dt*7);
    // the cogs: fold in, hold a beat, unfold (the tower the other way up)
    if(c.pop){c.pop+=dt;if(c.pop>c.popT&&c.ampT===0){c.ampT=famT===0&&flat?(sT.flip?1:-1):(sT.flip?-1:1);if(famT===0&&flat)sT.flip=sT.flip?0:1;for(const s of c.slots)s.cw=(s.cw+1+Math.floor(r()*2))%4;c.pal=c.palB=(c.pal+1+Math.floor(r()*10))%12;}
      if(c.ampT!==0&&Math.abs(c.amp-c.ampT)<.01){c.amp=c.ampT;c.ampv=0;c.pop=0;}}
    tykesSpr(c,'amp',c.ampT,wS*.55,dt);
    // the maker's stamp: after a reveal has settled, one figure near (never at) the middle shows it for a second or two
    c.sgGap+=dt;
    if(c.sgT>=0){c.sgT+=dt;const u=c.sgT;c.sgA=u<.25?u/.25:(u<1.5?1:Math.max(0,1-(u-1.5)/.5));if(u>2){c.sgT=-1;c.sgA=0;}}
    else if(c.sgArm>0&&settled&&flat&&famT<2&&!c.mv.ty&&c.evGap>1.2&&tick>=1){c.sgArm=0;
      const ox=(r()<.5?-1:1)*(.3+.5*r())*hhT*asp,oy=(r()-.5)*hhT,m8=(x)=>((x%256)+256)%256;let cx,cy;
      const ev2=(x)=>((x%2)+2)%2<.5;
      if(famT===0){const px=Math.floor(sT.pan[0]+ox),py=Math.floor((sT.pan[1]+oy)/1.3),y0=ev2(py+sT.nV)?py-sT.nV:py+sT.nV,cn=ev2(y0)?Math.ceil(sT.nH/2):Math.floor(sT.nH/2);cx=ev2(px-cn+y0)?px-cn:px+cn;cy=y0;}
      else{const ks=Math.floor((sT.pan[1]+oy)/3.25),cn=sT.nH,iw=Math.floor(sT.pan[0]+ox-sT.th*(ev2(ks)?1:-1)),mp=2*iw+1,m0=ev2(mp-cn)?mp+cn:mp-cn;cx=Math.floor(m0/2);cy=2*ks+(ev2(m0)?1:0);}
      c.sgC=(((cx%128)+128)%128)+256*m8(cy);c.sgT=0;c.sgGap=0;}
    tykesSpr(c,'D',c.DT,wS*.4,dt);
    if(c.DT>=6&&c.D>=6){c.DT-=3;c.D-=3;}
    if(c.DT<=-6&&c.D<=-6){c.DT+=3;c.D+=3;}
    if(c.wipeOn){
      // a ring opens faster and faster; a fold takes a second; a seam takes two beats (and may stop half way for a few bars)
      if(c.wty===0)c.wipe+=dt*(1.6+2.2*c.wipe);else if(c.wty===1)c.wipe+=dt*1.15;
      else{if(c.wPark>0&&c.wipe>=.6){c.wPark+=dt*bps;if(c.wPark>17)c.wPark=-1;}else c.wipe+=dt*bps*.6;}
      if(c.wipe>(c.wty===0?1.25:1.2)){
        c.layA=c.layB;c.pal=c.palB;c.wipe=0;c.wipeOn=false;c.wPark=0;c.layBars=0;c.layT=0;
        if(c.shB){c.slots[c.top].flip=c.amp<0?1:0;for(let i=0;i<c.shB;i++)c.slots.push(c.slots.shift());c.amp=c.ampT=c.slots[c.top].flip?-1:1;c.ampv=0;c.calm=0;c.shB=0;}
      }
    }
    // figure/ground: 0 all awake, 1 one half asleep, 2 the other
    {const tA=c.flip===1?0:1,tB=c.flip===2?0:1,k=1-Math.exp(-dt*7);sT.awA+=(tA-sT.awA)*k;sT.awB+=(tB-sT.awB)*k;
     for(const s of c.slots)if(s!==sT){s.awA+=(1-s.awA)*k;s.awB+=(1-s.awB)*k;}}
    // the wave of blocks: in from one edge of the frame, out at the other in about four beats
    if(c.mrun>0){c.mpos+=dt*bps*c.mend*.5*c.mdir*(c.mpark&&Math.abs(c.mpos)<1.5?.06:1);sT.morph=Math.min(1,sT.morph+dt*14);
      if(Math.abs(c.mpos)>c.mend&&c.mpos*c.mdir>0){c.mrun=0;c.pal=c.palB;if(c.wflip){c.amp=c.ampT=-c.amp;sT.flip=c.amp<0?1:0;c.wflip=0;sT.morph=0;}}}
    else sT.morph=Math.max(0,sT.morph-dt*14);
    for(const s of c.slots)if(s!==sT)s.morph=0;
    if(c.dbg){const d=c.dbg;c.slots.forEach((s,i)=>{if(d.fam!=null)s.fam=Array.isArray(d.fam)?d.fam[i]:d.fam;if(d.single!=null)s.single=d.single;if(d.aw)[s.awA,s.awB]=d.aw;if(d.morph!=null)s.morph=d.morph;if(d.th!=null){s.th=s.thT=s.lag=d.th;}if(d.pan)s.pan=d.pan.slice();if(d.nH!=null)s.nH=d.nH;if(d.nV!=null)s.nV=d.nV;});
      if(d.D!=null)c.D=c.DT=d.D;if(d.kq!=null)c.kq=d.kq;if(d.pal!=null)c.pal=c.palB=d.pal;if(d.palB!=null)c.palB=d.palB;if(d.lay!=null)c.layA=d.lay;if(d.layB!=null)c.layB=d.layB;if(d.wipe!=null)c.wipe=d.wipe;if(d.mpos!=null)c.mpos=d.mpos;if(d.sway!=null)c.sway=d.sway;if(d.sgC!=null){c.sgC=d.sgC;c.sgA=d.sgA;}
      if(d.mv){c.mv.ty=d.mv[0];c.mv.st=d.mv[1];c.mv.u=d.mv[2];c.calm=1;}if(d.amp!=null)c.amp=c.ampT=d.amp;if(d.chain!=null)c.chain=d.chain;if(d.look!=null)c.look=d.look;if(d.hyst!=null)c.hyst=d.hyst;if(d.wty!=null)c.wty=d.wty;if(d.shB!=null)c.shB=d.shB;if(d.calm!=null)c.calm=d.calm;if(d.wflip!=null)c.wflip=d.wflip;if(d.deal!=null)c.deal=[d.deal,d.deal,0];}
    const Dm=((c.D%3)+3)%3;
    V.p1=[c.slots[0].th,c.slots[1].th,c.slots[2].th,Dm];
    V.p2=[c.slots[0].lag,c.slots[1].lag,c.slots[2].lag,Math.min(1,c.kq+.5*c.lol)];
    V.p3=[c.sway,Math.min(1.2,c.bn+.5*c.build),c.shk,c.sw];
    V.p4=[tykesWp(c.waves[0]),c.waves[0][2],tykesWp(c.waves[1]),c.waves[1][2]];
    V.p5=[c.pal+16*c.palB+256*c.sK+2048*c.hK+16384*c.mK,
      Math.round(clamp(c.mv.ty?c.mv.u:0,0,1)*4095)+4096*(c.mv.ty&7)+32768*(c.mv.st&7)+262144*c.top+1048576*Math.round(clamp(c.calm,0,1)*15),
      Math.round(clamp(c.chain,0,1)*63)+64*Math.round(clamp(c.look,0,1)*63)+4096*Math.round(clamp(c.hyst/1.6,0,1)*63),c.wipe];
    const m1=new Float32Array(9),m2=new Float32Array(9);
    tykesPack(c.slots[0],m1,0,0);tykesPack(c.slots[1],m1,4,1);tykesPack(c.slots[2],m2,0,2);
    m1[8]=c.layA+64*c.layB+4096*c.wty+16384*c.shB;m2[4]=clamp(c.amp,-1,1)+1+4*(c.mrun&&c.wflip?1:0)+8*(c.mdir>0?1:0);m2[5]=c.mpos;m2[6]=c.pour;m2[7]=c.sgC;m2[8]=c.sgA;
    V.m1=m1;V.m2=m2;
  }
  },
