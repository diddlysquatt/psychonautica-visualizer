  {
  key:'kami',name:'KAMI 9',src:R_KAMI,cost:1.3,cont:[],description:'origami animal procession',
  fb:{zoom:0,rot:0,decay:.1,warp:0,echo:0,droste:0,win:0,key:.42,live:.05},syms:[0,0,0,3,3,6,6,4,8,5,2],kalZoom:.7,
  auto:{kal:[0,3,6,4,8,5,2],kalCycle:true,kalZoom:.7,transitions:['portal','kaleido','shatter'],kind:'flat',notes:'papercraft procession: diagonal paper bands of origami cranes, foxes, hares and doves; routes re-form on phrases; drops unfold the flock from paper squares'},
  init:s=>{
    const r=kamiRng(s[0]*.731+s[1]*.193+s[2]*.057+s[3]*.011);
    const A={k:[0,0,1,2,3,4,5,0][Math.floor(s[1]*8)%8],vs:r()*.998},p=Math.floor(s[2]*6)%6;
    return {r,A,B:A,wipe:2,wipeSpd:1,pA:p,pB:p,palT:1,palSpd:1,pos:[r()*40,r()*40,r()*40,r()*40],ph:[0,0,0,0],env:[0,0,0,0],
      k:0,kb:0,hH:0,bw:-1,hat:0,sw:-1,build:0,brk:0,pd:0,df:0,bars:0,ev:0,evS:0,evD:6,lt:-1,dir:s[3]<.8?1:-1,tsh:Math.floor(s[0]*4)%4,
      hp:-1,hS:0,hty:1,uf:0,flip:0};
  },
  frame(V,F,dt){
    const c=V.c,ez=(x,t,k)=>x+(t-x)*(1-Math.exp(-Math.max(0,dt)*k)),sm=(a,b,x)=>{const t=Math.min(1,Math.max(0,(x-a)/(b-a)));return t*t*(3-2*t);};
    const ms=Math.min(1,Math.max(0,(typeof S!=='undefined'&&S.motionSmooth!=null)?S.motionSmooth:.75));
    if(c.lt<0)c.lt=V.trav;const dtr=Math.max(0,Math.min(1,V.trav-c.lt));c.lt=V.trav;
    // band envelopes (geometry: >=60 ms attack, >=200 ms release, softer with the Motion smoothness dial)
    const L=BANDS.lv,tg=[Math.max(L[6],L[7]),.5*(L[3]+L[4]),L[2],Math.max(L[0],L[1])];
    for(let i=0;i<4;i++)c.env[i]=tg[i]>c.env[i]?ez(c.env[i],tg[i],12*(1-.5*ms)):ez(c.env[i],tg[i],4*(1-.5*ms));
    c.k=F.kick>c.k?ez(c.k,F.kick,14*(1-.5*ms)):ez(c.k,F.kick,4.5*(1-.5*ms));
    // hare hop height: the strongest kick of the current beat, eased (the bound starts on the ground, so a new height
    // never jumps)
    const bw=Math.floor(V.trav);if(bw!==c.bw){c.bw=bw;c.kb=0;}c.kb=Math.max(c.kb,F.kick||0);
    c.hH=ez(c.hH,c.kb,(c.kb>c.hH?10:3)*(1-.4*ms));
    c.hat=Math.max(c.hat*Math.exp(-dt*7),F.hat||0);c.hsp=ez(c.hsp||0,c.hat,8);c.spin=((c.spin||0)+dt*(.3+7*c.hsp))%62.83;
    c.build=ez(c.build,F.build,2.5);c.brk=ez(c.brk,F.breakdown||0,1.5);
    // travel (band widths per beat): cranes ride the highs, foxes the mids, hares hop one bound per beat, doves glide on the bass
    const e=c.env,boost=(1+.9*c.build)*(1-.45*c.brk);
    const fr0=(V.trav-dtr)%1,fr1=fr0+dtr,eh=x=>{const f=x%1,n=x-f;return n+f*f*(3-2*f);};
    const sp=[(.07+.5*e[0])*dtr,(.09+.45*e[1])*dtr,(.13+.3*e[2]+.2*c.hH)*(eh(fr1)-eh(fr0)),(.05+.32*e[3])*dtr];
    for(let i=0;i<4;i++){c.pos[i]=((c.pos[i]+c.dir*sp[i]*boost)%4096+4096)%4096;}
    c.ph[0]=(c.ph[0]+dtr*(.25+.8*e[0])*boost)%1000;c.ph[1]=(c.ph[1]+dtr*(.35+.75*e[1])*boost)%1000;
    c.ph[2]=(c.ph[2]+dtr)%1000;c.ph[3]=(c.ph[3]+dtr*(.25+.45*e[3]))%1000;
    // snare: a fold wave rolls along the bands (animals fold shut and open as it passes)
    if(F.onHit&&(c.sw<0||c.sw>.7))c.sw=0;if(c.sw>=0){c.sw+=dt*1.25;if(c.sw>1.3)c.sw=-1;}
    // drop: a new route sweeps in, the palette snaps, the whole procession unfolds out of paper squares, a giant
    // animal bounds through
    const drop=F.onDrop||F.drop>c.pd+.4;c.pd=F.drop;
    if(drop){kamiNext(c,true,true);c.df=1;c.hp=0;c.hS=V.trav;c.hty=c.r()<.6?1:Math.floor(c.r()*4);if(c.ev===2||c.ev===5)c.ev=0;c.uf=1;}
    if(c.hp>=0){c.hp=(V.trav-c.hS)/10;if(c.hp>1)c.hp=-1;}
    if(c.ev&&(V.trav-c.evS)/c.evD>=1){if(c.ev===3){c.dir=-c.dir;}c.ev=0;}
    if((F.onBar || F.onSceneBar)){c.bars++;
      if(!c.ev&&c.hp<0&&c.bars%8===4&&(c.r()<.6||c.bars<8))kamiStartEv(c,kamiEvPool[Math.floor(c.r()*kamiEvPool.length)],V.trav);
      if(c.bars%8===0)kamiNext(c,true,false);}
    if(c.wipe<2)c.wipe=Math.min(2,c.wipe+dt*c.wipeSpd*(c.wipe<1.6?1:4));
    if(c.wipe>=1.6)c.A=c.B;
    c.palT=Math.min(1,c.palT+dt*c.palSpd);
    c.df*=Math.exp(-dt*1.8);
    const evp=c.ev?Math.min(.999,Math.max(0,(V.trav-c.evS)/c.evD)):0;
    const bell=x=>Math.sin(Math.PI*Math.min(1,Math.max(0,x)));
    const conf=c.ev===1?Math.pow(bell(evp),.8):0,mnd=c.ev===2?sm(0,.2,evp)*(1-sm(.8,1,evp)):0;
    const flip=c.ev===3?sm(.15,.85,evp):0,fold=c.ev===4?.8*bell(evp):0;
    // unfold: 1 -> 0 over three beats after a drop; the refold event folds everything into squares and back
    c.uf=Math.max(0,c.uf-dtr/3);const ufv=c.ev===5?Math.min(1,1.25*bell(evp)):c.uf;
    const hop=(.04+.3*c.hH+.1*e[2])*(1-.5*c.brk);
    const A=c.A,B=c.B;
    V.p1=[V.trav%1000,V.mt%628.3185,c.k,c.sw];
    V.p2=[A.k+A.vs,B.k+B.vs,c.wipe>=1.6?2:c.wipe,c.palT];
    V.p3=[c.pA,c.pB,c.build,c.brk];
    V.p4=[c.ev&&c.ev<5?c.ev+evp:0,c.hp,c.hty,c.df];
    V.p5=[c.pos[0],c.pos[1],c.pos[2],c.pos[3]];
    V.m1=new Float32Array([c.ph[0],c.ph[1],c.ph[2],c.ph[3],e[0],e[1],e[2],e[3],fold]);
    V.m2=new Float32Array([hop,c.spin,c.tsh,c.dir,Math.min(1,c.hsp*1.3),conf,flip,mnd,ufv]);
  }
  },
