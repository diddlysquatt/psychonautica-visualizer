  {
  key:'flux',name:'ISOBAR',src:R_FLUX,cost:0.9,screenMotion:.12,cont:['K0','warp0'],description:'Liquid screenprint contour fields',
  fb:{zoom:0,rot:0,decay:.32,warp:0,echo:0,droste:0,win:0,key:.3,live:.035},syms:[0,0,0,0,6,6,8,8,12,4,5,3,16,2],kalZoom:.65,
  auto:{fx:{warp:.12,trails:.6,chroma:.12,bloom:.55},kal:[6,0,8,5,12,4,16,3],kalCycle:true,kalZoom:.65,transitions:['melt','leak','kaleido'],notes:'v12: re-rendered all folds on 3 seeds: 6, 8 and 5 make the strongest contour flowers, 12/4/16/3 also full; unfolded stays in the cycle. v11: all audio motion low-passed and level-robust (no flicker at any sensitivity); every fold reads as a contour mandala'},
  init:s=>{
    const fam=Math.floor(s[0]*4)%4, st=Math.floor(s[1]*4)%4, pal=(s[0]*s[3]*13.1)%1<0.34?8+Math.floor(s[2]*4)%4:Math.floor(s[2]*8)%8;
    const vort=fam===0&&s[3]<0.6?1:0, P=s[3]*7%1<0.5?8:16;
    const Ms=vort?(P===8?[8]:[8,16]):[7,8,9,10,11];
    const M=Ms[Math.floor((s[1]*13.7)%1*Ms.length)];
    const n=2+Math.floor((s[2]*11.3)%1*5);
    const cfg=s[0]*91.7%97, comp=[0,1,2,3,4,1,5,0,6,8,9,10,7,0][Math.floor((s[3]*29.3)%1*14)], cm=fluxCOMP[comp].slice();
    const ish=fluxISH[comp]>=0?fluxISH[comp]:(s[1]*5.3%1<0.5?0:1);
    return { fam, st, pal, vort, P, M, K0:[10,10,9,21][fam]*(0.85+0.3*s[3]), warp0:0.4+s[1]*0.55,
      cfgA:cfg, cfgB:cfg, nA:n, nB:n, mo:1, moDur:4, moRate:1, pend:0,
      palC:fluxPalLab(pal), palT:fluxPalLab(pal), palRate:1, foil:[1,2,0,1,3,2,1,2][Math.floor(s[2]*37.1%1*8)],
      clk:s[3]*40, dir:s[0]<0.5?1:-1, dirS:s[0]<0.5?1:-1, ph:0, colT:0, colS:0, swK:0,
      bE:0, sw:0, hph:0, fsw:s[1]*6, fswT:s[1]*6, comp, cmS:cm, cmV:cm.slice(), cmRate:0.55, fa:0, fb:0, ft:1, iSh:ish, iShT:ish, iAm:cm[4], iSty:s[0]*3.7%1<0.5?0:1,
      tl:fluxTILT[comp], tlx:0, dm:Math.floor(s[2]*23.9%1*4), dn:2+Math.floor(s[3]*17.3%1*3), dmNext:s[0]*5.7%1<0.5?Math.floor(s[2]*23.9%1*4):-1, dnNext:2+Math.floor(s[3]*17.3%1*3), dmA:0, dmV:0, tx:Math.floor(s[1]*41.3%1*10), txNext:s[3]*9.1%1<0.85?Math.floor(s[1]*41.3%1*10):-1, txA:0, chs:0, ev:null, r1:{i:0,age:9,a:0}, r2:{i:0,age:9,a:0}, spS:[0,0,0,0,0,0], spV:[0,0,0,0,0,0], spH:[.3,.3,.3,.3,.3,.3], onS:[0,0,0,0,0,0], onV:[0,0,0,0,0,0], mid:0, midV:0, swV:0, vS:0, hitK:0, hitE:0, hitV:0, lastHit:-9, hatE:0, hatV:0, colD:0, ha:null, rn:0, bars:0, bdS:0, lt:null, K:0, sws:0, xb:0, xd:0 };
  },
  frame(V,F,dt){
    const c=V.c; dt=Math.min(Math.max(dt,0),0.1);
    if(c.lt===null)c.lt=V.trav;
    const ex=r=>1-Math.exp(-dt*r);
    // ISOBAR v11 (no flicker): every audio input that moves contours or plates goes through a two-pole low-pass
    // (attack >= 60 ms, release >= 200 ms, slower with Motion smoothness) and is clamped, so the realm behaves the
    // same at any input level or sensitivity. The beat-surging travel clock is smoothed into a steady flow too.
    const msm=Math.min(1,Math.max(0,Number(S.motionSmooth)||0)), sr=1.45-0.75*msm;
    const lp2=(o,k,kv,t,ra,rr)=>{const r=(t>o[kv]?ra:rr)*sr, a=ex(r); o[kv]+=(t-o[kv])*a; o[k]+=(o[kv]-o[k])*a;};
    const cl1=x=>Math.min(1,Math.max(0,Number.isFinite(x)?x:0)), soft=x=>1-Math.exp(-1.7*Math.max(0,x));
    const raw=Math.max(0,Math.min(V.trav-c.lt,1)); c.lt=V.trav;
    c.vS+=(raw/Math.max(dt,1e-4)-c.vS)*ex(3*sr); if(!(c.vS>=0)||c.vS>8)c.vS=Math.min(8,Math.max(0,c.vS||0));
    const dtr=Math.min(1,c.vS*dt);
    const B=typeof BANDS!=='undefined'?BANDS:{lv:[0,0,0,0,0,0,0,0],on:[0,0,0,0,0,0,0,0]};
    const build=Math.max(F.build||0,c.xb||0), bd=F.breakdown||0;
    c.bE+=(build-c.bE)*ex(build>c.bE?2:0.7);
    c.bdS+=(bd-c.bdS)*ex(1);
    lp2(c,'sw','swV',soft(cl1(F.bass)*0.75+cl1(F.sub)*0.5),7,2.6);
    if(c.xdAt&&V.trav>=c.xdAt){c.xdAt=0;c.xd=1;}
    if(F.onDrop||c.xd){c.xd=0;fluxDrop(c);}
    if((F.onBar || F.onSceneBar)){
      c.bars++;
      if(c.bars%8===0){fluxNewCfg(c,8,false);fluxNewDom(c,0.5);}
      if(c.bars%16===12){let p=c.pal;while(p===c.pal)p=Math.floor(rand()*fluxPALS.length);c.pal=p;c.palT=fluxPalLab(p);c.palRate=2.6;if(rand()<0.4)c.foil=Math.floor(rand()*4);}
      if(c.ev&&c.bars>=c.ev.end){c.comp=c.ev.back;c.cmRate=0.7;c.ev=null;}
      if(c.bars%8===4){c.ev=null;fluxNewComp(c,c.bdS>0.5?2:0);fluxNewDom(c,0.6);}
      // rare surprises between phrase changes: a quick flight out over the atlas, or a loupe passing over a source
      else if(!c.ev&&c.bars%8===0&&(rand()<0.55||c.bars<16)){const back=c.comp,fly=rand()<0.5;
        c.comp=fly?(rand()<0.5?6:7):(rand()<0.5?8:9);c.cmRate=fly?0.9:1.2;fluxFocus(c);if(fluxISH[c.comp]>=0)c.iShT=fluxISH[c.comp];
        c.ev={back,end:c.bars+(fly?2:3)};}
      else if(fluxCOMP[c.comp][4]>0.5&&(c.ev||c.bars%4===2))fluxFocus(c);   // the loupe hops to another source
    }
    // composition glides over a few beats (faster on drops)
    {const T=fluxCOMP[c.comp],k=1-Math.exp(-(dtr+dt*0.08)*c.cmRate); const k2=1-Math.exp(-(dtr+dt*0.08)*c.cmRate*1.8); for(let j=0;j<6;j++)if(j!==4){c.cmV[j]+=(T[j]-c.cmV[j])*k2;c.cmS[j]+=(c.cmV[j]-c.cmS[j])*k2;}
     // the inset closes before it changes shape
     const it=c.iSh!==c.iShT?0:T[4]; c.iAm+=(it-c.iAm)*(1-Math.exp(-(dtr+dt*0.08)*Math.max(c.cmRate,0.9)));
     if(c.iSh!==c.iShT&&c.iAm<0.02){c.iSh=c.iShT;c.iAm=0;}
     c.tl+=(Math.min(0.85,Math.max(fluxTILT[c.comp],c.ev?0:c.tlx))-c.tl)*k;}
    // v19 the fold and the cell texture: exact critically damped glides, the fold closes before it changes kind
    {const hid=c.dmNext<0, same=c.dmNext===c.dm&&c.dnNext===c.dn, goal=hid||!same?0:1, w=1.5, dd=c.dmA-goal, tmp=(c.dmV+w*dd)*dt, e=Math.exp(-w*dt);
     c.dmA=goal+(dd+tmp)*e; c.dmV=(c.dmV-w*tmp)*e;
     if(!hid&&!same&&Math.abs(c.dmA)<0.01&&Math.abs(c.dmV)<0.02){c.dm=c.dmNext;c.dn=c.dnNext;c.dmA=0;c.dmV=0;}
     // the texture fades while the sources split or merge: a field line count that changes must never pop on screen
     const mg=c.mo<1&&c.nA!==c.nB?0:1, sm=c.txNext===c.tx, tt=(c.txNext<0||!sm)?0:mg, kr=ex(2.4);
     c.txA+=(tt-c.txA)*kr; if(c.txNext>=0&&!sm&&c.txA<0.02){c.tx=c.txNext;}}
    if(F.onBeat)c.chs=(c.chs+1)%16;
    c.ft=Math.min(1,c.ft+(dtr*0.3+dt*0.02));
    // topology morph advances with the beat
    if(c.mo<1){c.mo=Math.min(1,c.mo+(dtr+dt*0.05)/c.moDur*c.moRate); if(c.mo>=1&&c.pend){const d=c.pend===2;c.pend=0;fluxNewCfg(c,d?1.5:6,d);}}
    const pk=ex(c.palRate);
    for(let i=0;i<6;i++)for(let j=0;j<3;j++)c.palC[i][j]+=(c.palT[i][j]-c.palC[i][j])*pk;
    c.dirS+=(c.dir-c.dirS)*ex(1.6);
    c.clk+=(dtr*(0.08+0.1*c.bE)*(1-0.4*c.bdS)+dt*0.02)*c.dirS*S.speed;
    c.ph+=(dtr*0.07+dt*0.012)*S.speed;
    const bps0=F.conf>0.5&&F.bpm>0?F.bpm/60:2.2, now=V.trav;
    if(F.onHit&&now-c.lastHit>0.45){c.lastHit=now;c.hitK=1;}
    c.hitK*=Math.exp(-dt*2.2);
    lp2(c,'hitE','hitV',c.hitK,9,2.5);
    c.colT+=dt*(0.045+0.22*c.hitE)*Math.min(1.6,bps0/2.2);
    c.colS+=(c.colT-c.colS)*ex(2.2*sr);
    const wr=c.P*c.M*16; if(c.colT>wr){c.colT-=wr;c.colS-=wr;}
    // kick: a ring leaves the next source and ripples through the contours
    const bps=bps0;
    c.r1.age+=dt*bps; c.r2.age+=dt*bps;
    if(F.onKick&&c.r1.age>0.55){c.r2=c.r1; c.r1={i:(c.rn++)%Math.max(1,Math.round(c.mo>0.5?c.nB:c.nA)),age:0,a:1};}
    const rg=r=>{const R=0.02+r.age*0.38, at=Math.min(1,r.age/0.3), A=0.72*r.a*Math.exp(-r.age*1.2)*at*at*(3-2*at)*(0.6+0.4*Math.min(1.5,S.dose));return [R,A];};
    const g1=rg(c.r1), g2=rg(c.r2);
    const nEff=c.nA+(c.nB-c.nA)*c.mo;
    const Kt=c.K0*(1+0.55*c.bE)*(1-0.15*bd)*(c.fam===3?1:1.12-0.05*nEff);
    c.K=c.K?c.K+(Kt-c.K)*ex(1.5):Kt;
    c.swK*=Math.exp(-dt*0.9);
    const swt=(0.35+0.85*c.bE)*c.dirS+c.swK;
    c.sws+=(swt-c.sws)*ex(2);
    // highs slide the nested hairlines; hi-mids sweep the foil sheen (their onsets kick it along)
    lp2(c,'hatE','hatV',cl1(F.hat),10,3);
    c.hph+=dt*(0.15+1.2*c.hatE+0.5*c.spS[4]+0.6*c.spS[5]);
    c.fswT+=dt*(0.25+1.1*c.spS[3]+0.6*c.bE+2.5*c.onS[3]);
    c.fsw+=(c.fswT-c.fsw)*ex(8);
    lp2(c,'mid','midV',soft(cl1(F.mid)),4,1.6);
    // each source listens to its own slice of the log spectrum (sub ... air), smoothed so geometry never jitters,
    // and flashes its rings on that band's onsets
    const SB=[0,2,3,4,6,7];
    for(let i=0;i<6;i++){
      const x=0.06+0.16*i, b0=Math.floor((x-0.025)*NB), b1=Math.ceil((x+0.025)*NB);
      let a=0,n=0; for(let b=Math.max(0,b0);b<=Math.min(NB-1,b1);b++){a+=specBytes[b];n++;}
      a=n?a/n/255:0; c.spH[i]=Math.max(a,c.spH[i]-dt*0.05,0.18);
      // v12: the engine's auto-ranged band level for this source too, so each source answers its band at any mix
      const t=Math.max(Math.pow(cl1((a/c.spH[i]-0.2)/0.8),1.2),0.9*Math.pow(cl1(B.lv[SB[i]]),1.15));
      {const r=(t>c.spV[i]?8:2.6)*sr,k=ex(r); c.spV[i]+=(t-c.spV[i])*k; c.spS[i]+=(c.spV[i]-c.spS[i])*k;}
      {const o=cl1(Math.max(B.on[SB[i]]*1.4,i>=4?1.3*cl1(F.hat):0)),r=(o>c.onV[i]?16:3.4)*sr,k=ex(r); c.onV[i]+=(o-c.onV[i])*k; c.onS[i]+=(c.onV[i]-c.onS[i])*k;}
    }
    const mo=c.mo*c.mo*(3-2*c.mo);
    const q=(x,n)=>Math.round(Math.min(1,Math.max(0,x))*n), cz=c.cmS[0]*c.cmS[0]*(3-2*c.cmS[0]), ca=c.cmS[3]*c.cmS[3]*(3-2*c.cmS[3]);
    const ia=c.iAm*c.iAm*(3-2*c.iAm);
    const code=c.fam+4*c.st+16*c.M+256*(c.P===16?1:0)+512*c.vort+1024*c.iSh+2048*c.iSty+4096*c.foil+16384*q(ia,255)+4194304*c.dm;
    const rq=g=>Math.round(Math.min(3.99,Math.max(0,g[0]))*4096)+16384*q(g[1]/2.5,1023);
    const M=[];
    for(let i=0;i<6;i++){
      let a=fluxSrc(c.cfgA,i,c.nA,c.clk);
      if(mo>0.001){const b=fluxSrc(c.cfgB,i,c.nB,c.clk); a=a.map((v,j)=>v+(b[j]-v)*mo);}
      // v13: the two top sources' onset light (hats / air) also lights the band shimmer: one more gentle low-pass so it
      // swells with the hats instead of pulsing at their rate (no strobing)
      // (4-bit packing with hysteresis: a value hovering on a step boundary must not dither the light up and down)
      if(i>=4){if(!c.onW){c.onW=[0,0];c.onQ=[0,0];}const k=i-4;c.onW[k]+=(c.onS[i]-c.onW[k])*ex(3.5);
        const v=Math.min(1,Math.max(0,c.onW[k]))*15;if(Math.abs(v-c.onQ[k])>0.85)c.onQ[k]=Math.round(v);}
      M.push(a[0],a[1],4096*q(a[2]/2,4095)+16*q(c.spS[i],255)+(i>=4?c.onQ[i-4]:q(c.onS[i],15)));
    }
    V.m1=new Float32Array(M.slice(0,9)); V.m2=new Float32Array(M.slice(9,18));
    const hue=(typeof D!=='undefined'&&Number.isFinite(D.hue)?D.hue:0)+((F.cent||0.45)-0.45)*0.35, ht=0.22*Math.sin((hue%1000)*6.2832);
    c.ha=c.ha===null||c.ha===undefined?ht:c.ha+(ht-c.ha)*ex(1.2); const ha=c.ha;
    const ccs=Math.cos(ha), sa=Math.sin(ha), k=0.57735;
    const G=c.palC.map(L=>{const v=fluxGam(L), d=k*(v[0]+v[1]+v[2])*(1-ccs);
      const r=[v[0]*ccs+k*(v[2]-v[1])*sa+k*d, v[1]*ccs+k*(v[0]-v[2])*sa+k*d, v[2]*ccs+k*(v[1]-v[0])*sa+k*d].map(x=>q(x,255));
      return r[0]*65536+r[1]*256+r[2];});
    const TAU=6.283185307;
    const wv=c.warp0*(1+0.5*c.mid);
    V.p1=[c.clk,Math.min(c.K,63.9)+64*q(c.tl+0.07*c.sw*(c.tl>0.05?1:0),255),c.ph%(c.P*c.M*4),c.colS];
    // the focus (macro / inset) glides between two sources
    const fa=Math.min(c.fa,5),fb=Math.min(c.fb,5),ft=c.ft*c.ft*(3-2*c.ft);
    let fx=M[fa*3]+(M[fb*3]-M[fa*3])*ft, fy=M[fa*3+1]+(M[fb*3+1]-M[fa*3+1])*ft;
    {const sa=Math.max(-5,Math.min(5,c.sws)), an=-sa*Math.exp(-(fx*fx+fy*fy)*1.6), cs=Math.cos(an), sn=Math.sin(an); [fx,fy]=[cs*fx-sn*fy, sn*fx+cs*fy];}   // roughly undo the centre swirl
    const fq=(v,x)=>Math.min(16383,Math.max(0,Math.round((v+1)*8192)))+16384*x;
    fx=fq(fx,q(Math.max(0,c.dmA),1023)); fy=fq(fy,q(Math.max(0,c.txA),63)+64*(c.tx&3)+256*Math.min(3,c.dn-2));
    V.p2=[q(c.cmS[2],1023)+1024*(q(c.cmS[5],255)+256*c.chs)+4194304*(c.tx>>2),q(c.sws/10+0.5,4095)+4096*q((cz-ca+1)/2,4095),4096*q(wv/2,4095)+q(c.sw/2,4095),fy];
    V.p3=[code,rq(g1),rq(g2),c.r1.i+8*c.r2.i+64*q(c.bE,255)+16384*q(c.cmS[1],511)];
    V.p4=[Math.min(4095,Math.floor((c.hph%1)*4096))+4096*q(((c.fsw%TAU)+TAU)%TAU/TAU,4095),G[0],G[1],G[2]];
    V.p5=[G[3],G[4],G[5],fx];
  }
  },
