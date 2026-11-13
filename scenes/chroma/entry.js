  {
  key:'chroma',name:'CHROMA',src:R_CHROMA,cost:0.95,cont:[],description:'living plumage of enamel scales pouring through whorls of pure colour',
  fb:{zoom:0,rot:0,decay:.12,warp:0,echo:.02,droste:0,win:0,key:.05},syms:[0,0,0,0,8,6,12,16,8,6],kalZoom:.6,
  auto:{kal:[0,8,6,12,16,5],kalCycle:true,kalZoom:.6,transitions:['kaleido','portal','vortex'],kind:'flat',notes:'v20 rebuild'},
  init:(s)=>{
    const r=chromaRng(fract(Math.sin(s[0]*12.9898+s[1]*78.233+s[2]*37.719+s[3]*11.13)*43758.5453));
    return { rnd:r, A:chromaForm(r,null), B:null, w:0, wst:0, st:0, stT:0, stv:0, pour:0, kqv:0, kq:0, bu:0, sa:s[2]*6.28, waves:[9,9,9,9], sn:[9,9], K:0, shot:0, wgap:9, bars:0, turn:-1, wb:1, sK:0, hK:0, gl:0, hatP:0, hiS:0, hiE:0, bandz:new Float32Array(9) };
  },
  frame(V,F,dt){
    const c=V.c, bpm=F.bpm>0?F.bpm:120, bps=bpm/60, L=typeof BANDS!=='undefined'?BANDS.lv:null;
    const db=dt*bps, kdose=(0.4+0.6*S.dose);
    for(let i=0;i<4;i++)c.waves[i]+=dt; for(let i=0;i<2;i++)c.sn[i]+=dt;
    c.wgap=(c.wgap||9)+dt; if(F.onKick&&F.kick>.45&&c.wgap>(F.build>.5?.45:.85)){ c.wgap=0; const v=Math.max(...c.waves)>0.5?c.waves.indexOf(Math.max(...c.waves)):0; c.K=(c.K+1)%12; c.waves[v]=-0.001; } if(F.onKick){ c.kqv+=9*Math.min(1.2,.5+F.kick)*S.dose; c.stT+=Math.min(1,0.45+(L?Math.max(L[0],L[1]):F.bass)*0.8)*kdose; }
    if(F.onHit){ const v=c.sn[0]>c.sn[1]?0:1; c.sn[v]=-0.001; c.sK=(c.sK+1)%6; }
    { const ht=F.hat||0; if(F.onHat||(ht>0.45&&ht>c.hatP+0.2)) { c.hK=(c.hK+1)%64; c.gl+=0.23; } c.hatP=ht; const hi=L?Math.max(L[6],L[7]):(F.high||0), O=typeof BANDS!=='undefined'?BANDS.on:null; c.gl=(c.gl+dt*(0.1+1.5*hi)*S.speed)%64;
      c.hiS=ease(c.hiS,hi,dt,1.5); const tg=clamp(Math.max(O?2*Math.max(O[6],O[7]):0,(hi-c.hiS)*3,0.6*ht)+0.16*hi,0,1)*Math.min(S.dose,1.5); c.hiE=ease(c.hiE,tg,dt,tg>c.hiE?.02:.28); }
    chromaSpr(c,'kq',0,2*Math.PI*2.4,dt); c.kq=clamp(c.kq,-1.2,1.2);
    { const sb=L?Math.max(L[0],L[1]):Math.max(F.sub,F.bass); c.stT+=db*1.1*sb*sb*Math.min(S.dose,1.5); }   // the bass pours the rows; kicks add whole steps on top
    chromaSpr(c,'st',c.stT,12,dt);
    if(c.st>128&&c.stT>128){c.st-=128;c.stT-=128;}
    const sub=L?Math.max(L[0],L[1]):F.sub, mid=L?0.5*(L[2]+L[3]):F.mid;
    c.bu=ease(c.bu,sub*sub*S.dose,dt,sub>c.bu?.05:.22);
    c.pour=(c.pour+dt*(0.08+0.5*mid)*S.speed)%6;
    c.sa=(c.sa+dt*(.2+1.7*mid)*S.speed)%(2*Math.PI);
    if(c.turn>=0){c.turn+=dt; if(c.turn>1.6){c.A.pal=c.A.palB;c.A.palB=(c.A.pal+1+Math.floor(c.rnd()*12))%14;c.turn=-1;}}
    if(F.onDrop||F.drop>.85&&(c.pd||0)<.5){ if(c.B)c.A=c.B; c.B=chromaForm(c.rnd,c.A); c.w=0; c.wb=1.5; c.wst=Math.floor(c.rnd()*3); c.bars=0; }
    c.pd=F.drop;
    if(F.onBar||F.onSceneBar){ c.bars++;
      if(!c.B&&c.bars%8===0){ if(c.bars%16===0&&c.rnd()<.55){ c.B=chromaForm(c.rnd,c.A); c.w=0; c.wb=2.5; c.wst=Math.floor(c.rnd()*3);} else if(c.turn<0) c.turn=0; }
    }
    if(c.B){ c.w+=db/c.wb; if(c.w>=1){c.A=c.B;c.B=null;c.w=0;} }
    c.shot=ease(c.shot,mid,dt,.08);
    V.p1=[c.waves[0],c.waves[1],c.waves[2],c.waves[3]];
    V.p2=[c.st,c.pour,c.K,c.B?Math.max(c.w,1e-4):0];
    c.vz=ease(c.vz||0,F.build*(.5+.5*Math.min(S.dose,1)),dt,F.onDrop?.05:.5); if(F.drop>.5)c.vz*=Math.exp(-dt*9);
    V.p3=[c.kq,c.bu,c.sa,c.vz];
    { const hm=L?Math.max(L[4],L[5]):F.high; c.hm=ease(c.hm||0,hm*Math.min(S.dose,1.5),dt,hm>(c.hm||0)?.04:.18); }
    V.p4=[c.sn[0],c.sn[1],c.shot,c.hm];
    V.p5=[c.turn,c.sK,c.hK,c.gl];
    const m=new Float32Array(9); chromaPack(c.A,m,0); chromaPack(c.B||c.A,m,4); m[8]=c.wst; V.m1=m;
    for(let k=0;k<8;k++){ const v=L?L[k]:(k<2?F.bass:k<5?F.mid:F.high); c.bandz[k]=ease(c.bandz[k],v,dt,v>c.bandz[k]?.07:.25); } c.bandz[8]=c.hiE; V.m2=new Float32Array(c.bandz);
  }
  },
