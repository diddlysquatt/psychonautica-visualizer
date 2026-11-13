// ELF EXPLORER 2: a route director through the multi-scale temple. Level-9 cells form a lattice of nodes joined by
// naves (z), aisles (x) and octagonal shafts (y); every third, ninth and 27th line is also the axis of a great nave,
// aisle or shaft 3x, 9x and 27x larger (the shader carves levels down from 243). The director strings "legs":
// processions down naves, spiral climbs and descents round shafts (a stair of light winds round the great ones),
// orbits of vast domed crossings, passes low over the bridges that span their bottomless wells, galleries along the
// walls of the colossal halls, and the recursive vault (a dive that shrinks the explorer by 3 and hops back, forever
// the same and never the same). Each junction is a weighted choice that favours unvisited places. A JS port of the
// shader's distance function validates every leg and keeps the zoomed-out camera clear of the stone.
const ELF_TOUR_SCALE=9,ELF_BEAT_DIST=1.25,ELF_R=.65*9;
const ELF_BX=[-14,14],ELF_BY=[-4,14];
const elfTourAdd=(a,b,k=1)=>a.map((x,i)=>x+b[i]*k);
const elfTourDot=(a,b)=>a.reduce((s,x,i)=>s+x*b[i],0);
const elfTourNorm=a=>{const l=Math.hypot(...a)||1;return a.map(x=>x/l);};
const elfTourCross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
function elfTourRand(c){let t=c.rng=(c.rng+0x6D2B79F5)>>>0;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return ((t^(t>>>14))>>>0)/4294967296;}
function elfTourNode(n){return [(2*n[0]+1)*9,(2*n[1]+1-.08)*9,(2*n[2]+1)*9];}
function elfNodeOf(p){return [Math.round((p[0]/9-1)/2),Math.round((p[1]/9+.08-1)/2),Math.round((p[2]/9-1)/2)];}
// the coarsest level whose axis a node coordinate lies on: 0 = 9, 1 = 27, 2 = 81, 3 = 243
function elfLvOf(k){const m=((k%27)+27)%27;return m===13?3:m%9===4?2:m%3===1?1:0;}
// ---- the shader's distance function (levels 243 .. 1; finer levels only add space, so leaving them out is safe) ----
function elfArchIn(x,y,w,f){return Math.min(2*w-Math.hypot(Math.abs(x)+w,Math.max(y,0)),y+f);}
function elfOctIn(x,z){x=Math.abs(x);z=Math.abs(z);return .2713-Math.max(x,z,(x+z)*.70711);}
function elfRibD(x,r0){x=Math.abs(x)-r0;if(x<-.06)return 1;const m=x+.1775;return Math.abs(m-.355*Math.floor(m/.355)-.1775);}
function elfDE(p){
  let d=-1,bd=1e9,s=1/243;const m=Math.max(Math.abs(p[0]),Math.abs(p[1]),Math.abs(p[2]));
  for(let i=0;i<6;i++,s*=3){
    if(m*s<=.47)continue;
    const w=x=>{const y=x*s;return y-2*Math.floor(y/2)-1;},vx=w(p[0]),vy=w(p[1]),vz=w(p[2]);
    let a=elfArchIn(vx,vy,.297,.3779),b=elfArchIn(vz,vy,.2452,.3396),c=elfOctIn(vx,vz);
    a=Math.min(a,Math.max(a-.045,elfRibD(vz,.29)-.028,-.3-vy));
    b=Math.min(b,Math.max(b-.04,elfRibD(vx,.33)-.024,-.27-vy));
    const c0=c;c=Math.min(c,Math.max(c-.035,elfRibD(vy,.36)-.022));
    d=Math.max(d,Math.max(a,b,c)/s);
    if(s<.05)bd=Math.min(bd,Math.max(Math.min(Math.abs(vx),Math.abs(vz))-.04,Math.abs(vy+.355)-.022,-c0)/s);
  }
  return Math.min(d,bd);
}
// fraction of the segment p -> p+o that keeps a clearance of clr from the stone
function elfClearFrac(p,o,clr){
  const L=Math.hypot(...o);if(L<1e-6)return 1;const dir=o.map(x=>x/L);let s=0;
  for(let i=0;i<48;i++){const dd=elfDE(elfTourAdd(p,dir,s));if(dd<clr)return Math.max(0,s-.4)/L;s+=Math.max(dd-clr*.6,.2);if(s>=L)return 1;}
  return Math.min(1,s/L);
}
// ---- route segments: densely sampled curves, evaluated with Catmull-Rom (C1) and an arc-length table ----
function elfSeg(fn,N,opt){
  const pts=[];for(let i=0;i<=N;i++)pts.push(fn(i/N));
  const cum=[0];let L=0;for(let i=1;i<=N;i++){L+=Math.hypot(pts[i][0]-pts[i-1][0],pts[i][1]-pts[i-1][1],pts[i][2]-pts[i-1][2]);cum.push(L);}
  return Object.assign({pts,cum,len:Math.max(L,1e-6),sig0:9,sig1:9},opt||{});
}
function elfSegLine(a,b,opt){const L=Math.hypot(...elfTourAdd(b,a,-1));return elfSeg(u=>a.map((x,k)=>x+(b[k]-x)*u),Math.max(1,Math.ceil(L/2)),opt);}
function elfBez(cp,t){const a=cp.map(p=>p.slice());for(let n=cp.length-1;n>0;n--)for(let i=0;i<n;i++)for(let k=0;k<3;k++)a[i][k]=a[i][k]*(1-t)+a[i+1][k]*t;return a[0];}
function elfSegBez(cp,opt){return elfSeg(u=>elfBez(cp,u),32,opt);}
function elfSegAt(seg,d){
  const f=Math.max(0,Math.min(seg.len,d)),P=seg.pts,C=seg.cum;
  let lo=0,hi=C.length-1;while(hi-lo>1){const mid=(lo+hi)>>1;if(C[mid]<=f)lo=mid;else hi=mid;}
  const t=(f-C[lo])/Math.max(C[hi]-C[lo],1e-9),p0=P[Math.max(lo-1,0)],p1=P[lo],p2=P[hi],p3=P[Math.min(hi+1,P.length-1)];
  const t2=t*t,t3=t2*t;
  return [0,1,2].map(k=>.5*(2*p1[k]+(-p0[k]+p2[k])*t+(2*p0[k]-5*p1[k]+4*p2[k]-p3[k])*t2+(-p0[k]+3*p1[k]-3*p2[k]+p3[k])*t3));
}
function elfSegsClear(segs,clr){
  for(const s of segs){const P=s.pts,k=clr*Math.min(s.sig0,s.sig1)/9;
    for(let i=0;i<P.length;i++){
      if(elfDE(P[i])<k)return false;
      if(i>0){const L=Math.hypot(P[i][0]-P[i-1][0],P[i][1]-P[i-1][1],P[i][2]-P[i-1][2]),n=Math.ceil(L/.35);
        for(let j=1;j<n;j++){const q=P[i-1].map((x,m)=>x+(P[i][m]-x)*j/n);if(elfDE(q)<k)return false;}}
    }}
  return true;
}
// ---- the director ----
const ELF_DIRS=[[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]];
function elfInB(n){return n[0]>=ELF_BX[0]&&n[0]<=ELF_BX[1]&&n[2]>=ELF_BX[0]&&n[2]<=ELF_BX[1]&&n[1]>=ELF_BY[0]&&n[1]<=ELF_BY[1];}
function elfVisit(c,n){const k=n.join(',');return c.visits.get(k)||0;}
// pass through the tail node and leave it along d; returns the segments (not yet committed)
function elfPassSegs(c,d){
  const C=elfTourNode(c.node),a=elfTourAdd(C,c.din,-ELF_R),b=elfTourAdd(C,d,ELF_R),out=[elfSegLine(c.tailEnd,a)];
  if(elfTourDot(c.din,d)>.5)out.push(elfSegLine(a,b));
  else out.push(elfSegBez([a,elfTourAdd(a,c.din,.4*ELF_R),elfTourAdd(a,c.din,.8*ELF_R),elfTourAdd(b,d,-.8*ELF_R),elfTourAdd(b,d,-.4*ELF_R),b]));
  return out;
}
// the straight run from a figure's end toward the next node must be clear too
function elfLead(node,din,tailEnd){return elfSegLine(tailEnd,elfTourAdd(elfTourNode(node),din,-ELF_R));}
function elfCommit(c,segs,node,din,tailEnd){
  for(const s of segs)c.segs.push(s);
  c.visits.set(c.node.join(','),elfVisit(c,c.node)+1);
  c.node=node;c.din=din;c.tailEnd=tailEnd;c.generated++;
}
// one grid step: through the tail node toward the best-scoring neighbour (target-seeking, straight-loving, novelty-seeking)
function elfStep(c,target,allowV){
  const cand=[];
  for(const d of ELF_DIRS){
    if(elfTourDot(d,c.din)<-.5)continue;
    if(d[1]!==0&&!allowV)continue;
    const n=elfTourAdd(c.node,d);if(!elfInB(n))continue;
    const dist=x=>target?x.reduce((s,v,i)=>s+Math.abs(v-target[i]),0):0;
    let w=(elfTourDot(d,c.din)>.5?1.5:1)*Math.exp(-elfVisit(c,n)*1.1)*(target?(dist(n)<dist(c.node)?2.2:.45):1)*(.6+.8*elfTourRand(c));
    // great lines pull the tour into the big spaces
    w*=1+.35*Math.min(elfLvOf(n[0]),elfLvOf(n[1]))+.35*Math.min(elfLvOf(n[2]),elfLvOf(n[1]))+.3*c.bigPref;
    cand.push({d,n,w});
  }
  cand.sort((a,b)=>b.w-a.w);
  for(const x of cand){
    const segs=elfPassSegs(c,x.d),b=segs[segs.length-1].pts[segs[segs.length-1].pts.length-1];
    if(elfSegsClear(segs.concat([elfLead(x.n,x.d,b)]),.6)){elfCommit(c,segs,x.n,x.d,segs[segs.length-1].pts[segs[segs.length-1].pts.length-1]);return true;}
  }
  // dead end (should not happen): turn back
  const d=c.din.map(x=>-x),segs=elfPassSegs(c,d);elfCommit(c,segs,elfTourAdd(c.node,d),d,segs[segs.length-1].pts.slice(-1)[0]);return false;
}
// helix round the vertical axis of the tail node's column: a spiral climb/descent (dy != 0) or an orbit (dy ~ 0)
// alignHalf: the great shafts carry a cross of bridges at every floor; the helix passes between their arms
function elfHelixSegs(c,dyNodes,turnsWant,dout,R,S,look){
  const C=elfTourNode(c.node),din=c.din,sg=elfTourRand(c)<.5?1:-1;
  const ang=d=>Math.atan2(-sg*d[0],sg*d[2]);
  const th0=ang(din),y0=C[1];
  const P=S>=27?S:18,thOut=ang(dout),dl=(((thOut-th0)*sg)%(2*Math.PI)+2*Math.PI)%(2*Math.PI);
  let ys=y0,dy=0,omega;
  if(dyNodes!==0){
    const sdy=Math.sign(dyNodes);
    if(S>=27){
      // the great shafts carry a cross of bridges at every floor: at the deck height the helix is 45 degrees off the arms
      const yd=S*(2*Math.round((y0/S+.355-1)/2)+1)-.355*S,kap=sg*sdy*2*Math.PI/S;
      const kc=((yd-y0)*kap-Math.PI/4+th0)/(Math.PI/2),k=Math.round(kc);
      ys=yd-(Math.PI/4+k*Math.PI/2-th0)/kap;
    }
    const n=Math.max(0,Math.round(Math.abs(dyNodes)*18/P-dl/(2*Math.PI))),turns=n+dl/(2*Math.PI);
    // great shafts keep the exact pitch (the bridges), small ones stretch it to end exactly at a node
    dy=S>=27?sdy*turns*P:dyNodes*18;omega=sg*2*Math.PI*(S>=27?turns:Math.max(turns,turns+(turns<.5?1:0)));
    if(Math.abs(dy)<9)return null;
  }else{
    const turns=Math.max(0,Math.round(turnsWant-dl/(2*Math.PI)))+dl/(2*Math.PI);omega=sg*2*Math.PI*Math.max(turns,.3);
  }
  const ye=ys+dy,axis=[C[0],0,C[2]];
  const H=u=>{const th=th0+omega*u;return [axis[0]+R*Math.cos(th),ys+dy*u,axis[2]+R*Math.sin(th)];};
  const arc=Math.hypot(Math.abs(omega)*R,dy);
  const tanAt=u=>{const th=th0+omega*u,k=omega*R;return elfTourNorm([-Math.sin(th)*k,dy,Math.cos(th)*k]);};
  // the exit node: the column node nearest the helix end
  const n1=[c.node[0],Math.round((ye/9+.08-1)/2),c.node[2]];if(!elfInB(n1))return null;
  const C1=elfTourNode(n1),a=elfTourAdd(C,din,-ELF_R),h0=H(0),h1=H(1),bd=Math.max(ELF_R,R*1.15),b=elfTourAdd(C1,dout,bd),steps=Math.ceil((bd+ELF_R+.3)/18);
  const k0=Math.min(ELF_R,Math.hypot(...elfTourAdd(h0,a,-1))*.45),k1=Math.min(ELF_R,Math.hypot(...elfTourAdd(b,h1,-1))*.45);
  const lk={look:look||null};
  const segs=[elfSegLine(c.tailEnd,a),
    elfSegBez([a,elfTourAdd(a,din,k0),elfTourAdd(h0,tanAt(0),-k0),h0],lk),
    elfSeg(H,Math.max(8,Math.ceil(arc/.8)),lk),
    elfSegBez([h1,elfTourAdd(h1,tanAt(1),k1),elfTourAdd(b,dout,-k1),b],lk)];
  return {segs,node:elfTourAdd(n1,dout,steps),din:dout,tailEnd:b};
}
// the recursive vault: from a 27x crossing C to C/3 along an axis order, while the explorer shrinks 9 -> 3; at the end
// everything is scaled back up by 3, which lands exactly on C again (the temple is invariant under x -> 3x)
function elfDiveSegs(c,order){
  const C=elfTourNode(c.node),T=C.map(x=>x/3);
  if(c.din[order[0]]*Math.sign(T[order[0]]-C[order[0]])<-.5)return null; // never a U-turn into the dive
  const pts=[C.slice()];let p=C.slice();for(const k of order){p=p.slice();p[k]=T[k];pts.push(p);}
  const segs=[];let din=c.din,prev=null;
  for(let i=0;i<3;i++){
    const A=pts[i],B=pts[i+1],d=elfTourNorm(elfTourAdd(B,A,-1)),rA=.55*9*Math.pow(3,-i*.4);
    const a=elfTourAdd(A,din,-rA),b=elfTourAdd(A,d,rA);
    segs.push(elfSegLine(i?prev:c.tailEnd,a));
    segs.push(elfSegBez([a,elfTourAdd(a,din,.4*rA),elfTourAdd(a,din,.8*rA),elfTourAdd(b,d,-.8*rA),elfTourAdd(b,d,-.4*rA),b]));
    prev=b;din=d;
  }
  // the dive ends just short of C/3, so that x3 it lands 6.5 units before C, ready for the next pass (or dive)
  segs.push(elfSegLine(prev,elfTourAdd(T,din,-6.5/3)));
  // the explorer shrinks geometrically with distance travelled: 9 at the start, exactly 3 at the hop
  const tot=segs.reduce((x,s)=>x+s.len,0);let acc=0;
  const roll=elfTourRand(c)<.5?1:-1;
  // the plunge takes 30 to 60 beats however far the crossing lies from the heart of the temple (the explorer's own
  // path length through the shrinking dive is tot * 2 / ln 3)
  const spd=Math.max(1,Math.min(5,tot*1.82/(30*ELF_BEAT_DIST)));
  if(tot*1.82/(spd*ELF_BEAT_DIST)>60)return null; // too far out: the plunge would drag on
  segs.forEach((s,i)=>{s.sig0=9*Math.pow(3,-acc/tot);acc+=s.len;s.sig1=9*Math.pow(3,-acc/tot);s.theme=4;s.dive=1;s.roll=roll;s.spd=spd;});
  segs[segs.length-1].hop=1;
  return {segs,din};
}
const ELF_LEGS=['walk','great','spiral','climb','hall','bridge','gallery','vault'];
function elfPickLeg(c){
  const w=c.legW.slice(),i0=ELF_LEGS.indexOf(c.lastLeg);if(i0>=0)w[i0]*=.35;
  const big=c.bigPref;w[1]*=1+big;w[4]*=1+2*big;w[5]*=1+2*big;w[6]*=1+2*big;
  let tot=w.reduce((a,b)=>a+b,0),q=elfTourRand(c)*tot;
  for(let i=0;i<w.length;i++){q-=w[i];if(q<=0)return ELF_LEGS[i];}
  return 'walk';
}
// nearest node on a great line/crossing of at least level L (searching outward), preferring unvisited ones
function elfFindGreat(c,L,needCross){
  let best=null,bs=1e9;
  for(let i=0;i<60;i++){
    const n=[0,0,0].map((_,k)=>{const lo=k===1?ELF_BY:ELF_BX;return Math.max(lo[0],Math.min(lo[1],c.node[k]+Math.round((elfTourRand(c)-.5)*(k===1?(L>=2?12:6):(L>=2?16:8)))));});
    // snap to the level's lattice (n = 1 mod 3, 4 mod 9 or 13 mod 27)
    const per=L===1?3:L===2?9:27,off=L===1?1:L===2?4:13;
    const sn=n.map(x=>x-((x-off)%per+per)%per+(((x-off)%per+per)%per>per/2?per:0));
    if(!elfInB(sn))continue;
    if(!needCross){const k=elfTourRand(c)<.5?0:2;sn[k]=n[k];}
    const dist=sn.reduce((s,v,k)=>s+Math.abs(v-c.node[k]),0),sc=dist*(1+1.5*elfVisit(c,sn));
    if(sc<bs&&dist>1){bs=sc;best=sn;}
  }
  return best;
}
function elfPlanLeg(c){
  const leg=elfPickLeg(c);c.lastLeg=leg;
  const horiz=()=>{const d=[[1,0,0],[-1,0,0],[0,0,1],[0,0,-1]].filter(d=>elfTourDot(d,c.din)>-.5);return d[Math.floor(elfTourRand(c)*d.length)];};
  const colL=Math.min(elfLvOf(c.node[0]),elfLvOf(c.node[2])),crossL=Math.min(colL,elfLvOf(c.node[1]));
  const S=9*Math.pow(3,colL);
  if(leg==='walk'){c.queue={target:null,moves:2+Math.floor(elfTourRand(c)*4),v:false,then:elfTourRand(c)<.4?'spiral':null};return;}
  if(leg==='climb'&&c.din[1]===0){c.queue={target:[c.node[0],Math.max(ELF_BY[0],Math.min(ELF_BY[1],c.node[1]+(elfTourRand(c)<.5?-2:2))),c.node[2]],moves:4,v:true};return;}
  if(leg==='great'){const g=elfFindGreat(c,c.bigPref>.4?2:1,false);if(g){c.queue={target:g,moves:8,v:true,then:'run'};return;}}
  if(leg==='hall'||leg==='bridge'||leg==='spiral'||leg==='vault'){
    const L=leg==='vault'?1:(leg==='spiral'?(elfTourRand(c)<.3?0:1):(elfTourRand(c)<.45+.4*c.bigPref?2:1));
    if(L===0){c.queue={target:null,moves:1,v:false,then:'spiral'};return;}
    const g=elfFindGreat(c,L,true);
    if(g){c.queue={target:g,moves:L>=2?14:11,v:true,then:leg};return;}
  }
  if(leg==='gallery'){const g=elfFindGreat(c,2,false);if(g){c.queue={target:g,moves:14,v:true,then:'gallery'};return;}}
  c.queue={target:null,moves:2+Math.floor(elfTourRand(c)*3),v:false};
}
// the special figure at the end of a leg (the tail node is where it happens)
function elfFinish(c,what){
  c.stat=c.stat||{};c.stat[what+'?']=(c.stat[what+'?']||0)+1;const ok=elfFinish2(c,what);if(ok)c.stat[what]=(c.stat[what]||0)+1;return ok;
}
function elfFinish2(c,what){
  const colL=Math.min(elfLvOf(c.node[0]),elfLvOf(c.node[2])),S=9*Math.pow(3,colL),crossL=Math.min(colL,elfLvOf(c.node[1]));
  const horiz=()=>{const d=[[1,0,0],[-1,0,0],[0,0,1],[0,0,-1]];return d[Math.floor(elfTourRand(c)*4)];};
  let r=null;
  if(c.din[1]!==0&&what!=='vault')return false;
  if(what==='spiral'){
    const span=2+Math.floor(elfTourRand(c)*(colL>0?3:4)),up=c.node[1]+span<=ELF_BY[1]&&(c.node[1]-span<ELF_BY[0]||elfTourRand(c)<.55);
    const R=colL>0?.15*S:1.0;r=elfHelixSegs(c,up?span:-span,0,horiz(),R,S,[0,up?.55:-.55,0]);
    if(r&&elfSegsClear(r.segs.concat([elfLead(r.node,r.din,r.tailEnd)]),.6)){for(const s of r.segs)s.kind='spiral';elfCommit(c,r.segs,r.node,r.din,r.tailEnd);c.legInfo='spiral '+S;return true;}
    return false;
  }
  if(what==='hall'&&crossL>=1){
    const R=.19*S;r=elfHelixSegs(c,0,.6+elfTourRand(c)*.8,horiz(),R,S,[0,.3,0]);
    if(r&&elfSegsClear(r.segs.concat([elfLead(r.node,r.din,r.tailEnd)]),.8)){for(const s of r.segs)s.kind='hall';elfCommit(c,r.segs,r.node,r.din,r.tailEnd);c.legInfo='hall '+S;return true;}
    return false;
  }
  if(what==='bridge'&&crossL>=1){
    // fly low over the bridge that spans the well, straight through the crossing
    const C=elfTourNode(c.node),d=c.din,yc=S*(2*Math.round((C[1]/S-1)/2)+1),deck=yc-.333*S+Math.max(2.2,.06*S);
    const back=Math.min(S*.45,Math.hypot(...elfTourAdd(C,c.tailEnd,-1))-.5),fwd=Math.max(ELF_R,S*.45);
    const a=elfTourAdd(C,d,-back),b=elfTourAdd(C,d,fwd),lo=k=>{const p=elfTourAdd(C,d,k);p[1]=deck;return p;};
    const segs=[elfSegLine(c.tailEnd,a),elfSegBez([a,elfTourAdd(a,d,back*.35),lo(-back*.3),lo(0),lo(fwd*.3),elfTourAdd(b,d,-fwd*.35),b],{look:[0,-.35,0],kind:'bridge'})];
    const steps=Math.ceil((fwd+ELF_R+.3)/18),nb=elfTourAdd(c.node,d,steps);
    if(S<=81&&elfInB(nb)&&elfSegsClear(segs.concat([elfLead(nb,d,b)]),.7)){elfCommit(c,segs,nb,d,b);c.legInfo='bridge '+S;return true;}
    return false;
  }
  if(what==='gallery'&&colL+0>=0){
    // a gallery along the wall of a colossal nave: step sideways toward the wall and up, run parallel, look across
    const L=Math.max(elfLvOf(c.node[0]),elfLvOf(c.node[2]));if(L<2)return false;
    const along=elfLvOf(c.node[0])>=2&&elfLvOf(c.node[1])>=2?[0,0,1]:(elfLvOf(c.node[2])>=2&&elfLvOf(c.node[1])>=2?[1,0,0]:null);
    if(!along)return false;
    const SL=9*Math.pow(3,Math.min(elfLvOf(c.node[1]),elfLvOf(along[0]?c.node[2]:c.node[0])));
    const side=along[0]?[0,0,elfTourRand(c)<.5?1:-1]:[elfTourRand(c)<.5?1:-1,0,0],k=Math.max(1,Math.round(.2*SL/18)),up=Math.max(1,Math.round(.12*SL/18));
    const sgn=elfTourRand(c)<.5?1:-1;
    c.queue={target:elfTourAdd(elfTourAdd(c.node,side,k),[0,up,0]),moves:k+up+3,v:true,then:'run',after:{runDir:along.map(x=>x*sgn),runN:4+Math.floor(elfTourRand(c)*4),look:side.map(x=>-x*.45)}};
    c.legInfo='gallery '+SL;return true;
  }
  if(what==='vault'&&crossL>=1&&elfLvOf(c.node[0])>=1&&elfLvOf(c.node[1])>=1&&elfLvOf(c.node[2])>=1){
    // any of the six axis orders will do (the great shafts carry bridges, so a vertical leg may be blocked)
    const P=[[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]];
    for(let i=5;i>0;i--){const j=Math.floor(elfTourRand(c)*(i+1));[P[i],P[j]]=[P[j],P[i]];}
    let r2=null;for(const o of P){const r=elfDiveSegs(c,o);if(r&&elfSegsClear(r.segs,.6)){r2=r;break;}}
    if(r2){
      for(const s of r2.segs)c.segs.push(s);
      // after the hop the explorer is back before C at full size, heading along the dive's last direction
      const C=elfTourNode(c.node);c.din=r2.din;c.tailEnd=elfTourAdd(C,r2.din,-6.5);
      c.dives++;c.legInfo='vault';
      if(elfTourRand(c)<.45)c.queue={target:null,moves:0,v:false,then:'vault'};
      return true;
    }
  }
  return false;
}
function elfTourAppend(c){
  if(!c.queue)elfPlanLeg(c);
  const q=c.queue;
  if(!q.target&&q.runN>0){
    // a run along a fixed direction (gallery or great line)
    q.runN--;const n=elfTourAdd(c.node,q.runDir);
    if(elfInB(n)){const segs=elfPassSegs(c,q.runDir);if(q.look)for(const s of segs)s.look=q.look;if(elfSegsClear(segs.concat([elfLead(n,q.runDir,segs[segs.length-1].pts.slice(-1)[0])]),.6)){elfCommit(c,segs,n,q.runDir,segs[segs.length-1].pts.slice(-1)[0]);return;}}
    q.runN=0;
  }
  const done=q.moves<=0||(q.target&&q.target.every((v,i)=>v===c.node[i]));
  if(done){
    c.queue=null;
    if(q.then==='run'&&q.after){c.queue=Object.assign({target:null,moves:0,v:false},q.after);return;}
    if(q.then==='run'){
      // run along the great line we have reached
      const ax=[[1,0,0],[0,0,1]].filter(d=>Math.min(...[0,1,2].filter(k=>d[k]===0).map(k=>elfLvOf(c.node[k])))>=1);
      if(ax.length){const d=ax[Math.floor(elfTourRand(c)*ax.length)].map(x=>x*(elfTourRand(c)<.5?-1:1));c.queue={target:null,moves:0,v:false,runDir:d,runN:3+Math.floor(elfTourRand(c)*4)};}
      return;
    }
    if(q.then&&elfFinish(c,q.then))return;
    // the recursive vault is worth a second try: find the nearest crossing of the 27-line and go there
    if(q.then==='vault'&&!q.retry){const g=elfFindGreat(c,1,true);if(g){c.queue={target:g,moves:11,v:true,then:'vault',retry:1};return;}}
    if(!c.queue)elfPlanLeg(c);
    return;
  }
  q.moves--;
  // junctions of the great levels tempt the explorer: orbit the domed crossing, skim its bridge or take the dive
  const cl=Math.min(elfLvOf(c.node[0]),elfLvOf(c.node[1]),elfLvOf(c.node[2]));
  if(cl>=1&&c.din[1]===0&&c.generated-(c.lastFig||-9)>3&&elfTourRand(c)<.5){
    let f=['hall','bridge','vault','hall','vault'][Math.floor(elfTourRand(c)*(cl>=1?5:4))];
    if(f===c.lastSetPiece)f=f==='hall'?'bridge':f==='bridge'?'vault':'hall';c.lastSetPiece=f;
    if(f!=="vault"||elfTourRand(c)<.8*c.legW[7]){c.lastFig=c.generated;if(elfFinish(c,f))return;}
  }
  elfStep(c,q.target,q.v);
}
function elfTourFill(c){let g=0;while(c.segs.reduce((s,x)=>s+x.len,0)-c.along<90&&g++<40)elfTourAppend(c);}
// position along the route, d ahead of the explorer; points beyond a hop are brought into the current frame (/3)
function elfTourAt(c,d){
  let f=c.along+Math.max(0,d),k=1;
  for(const seg of c.segs){if(f<=seg.len)return elfSegAt(seg,f).map(x=>x*k);f-=seg.len;if(seg.hop)k/=3;}
  const s=c.segs[c.segs.length-1];return s.pts[s.pts.length-1].map(x=>x*k);
}
function elfTourLook(c){const s=c.segs[0];return s&&s.look?s.look:null;}
function elfTourSig(c){const s=c.segs[0];if(!s||s.sig0===s.sig1)return s?s.sig0:9;return s.sig0*Math.pow(s.sig1/s.sig0,Math.max(0,Math.min(1,c.along/s.len)));}
function elfTourInit(seed){
  const pal0=Math.floor(seed[3]*6)%6;
  const c={rng:((seed[0]*4294967295)^(seed[1]*2147483647)^0x6a09e667)>>>0,hue:seed[2],age:0,beam:.5,velocity:0,along:0,
    palA:pal0,palB:pal0,palM:0,palRate:1,palBeats:0,palN:Math.floor(seed[1]*7),boost:0,boostT:0,fl:.94,lt:null,lastDrop:0,look:0,lookWant:0,lookDir:null,bank:0,
    segs:[],visits:new Map(),generated:0,queue:null,lastLeg:'',legInfo:'',dives:0,bigPref:0,sig:9,pullL:0,vast:0,vastS:0,
    thA:0,thB:0,thM:0,thRate:.33,inhabitants:[],residentClock:0};
  // each visit has its own temperament: some love spirals, some the great halls, some the dive
  const tw=()=>.5+elfTourRand(c);
  c.legW=[2.2*tw(),1.6*tw(),2.2*tw(),.8*tw(),2*tw(),1.3*tw(),1.1*tw(),1.9*tw()];
  c.themePerm=[0,1,2,3,0,1,2,3];for(let i=7;i>0;i--){const j=Math.floor(elfTourRand(c)*(i+1));[c.themePerm[i],c.themePerm[j]]=[c.themePerm[j],c.themePerm[i]];}
  c.node=[Math.floor(elfTourRand(c)*5)-2,Math.floor(elfTourRand(c)*3),Math.floor(elfTourRand(c)*5)-2];
  const hd=[[1,0,0],[-1,0,0],[0,0,1],[0,0,-1]][Math.floor(elfTourRand(c)*4)];
  c.din=hd;c.tailEnd=elfTourAdd(elfTourNode(elfTourAdd(c.node,hd,-1)),hd,ELF_R);
  elfTourFill(c);
  c.visitSeed=c.rng&0x00ffffff;
  const p=elfTourAt(c,0),ahead=elfTourAt(c,ELF_TOUR_SCALE*.8);c.forward=elfTourNorm(ahead.map((x,i)=>x-p[i]));
  const ref=Math.abs(c.forward[1])>.85?[0,0,1]:[0,1,0];c.up=elfTourNorm(elfTourAdd(ref,c.forward,-elfTourDot(ref,c.forward)));
  c.thA=c.thB=elfRegionTheme(c,p);
  elfTourResidents(c,{p,f:c.forward},true);return c;
}
function elfRegionTheme(c,p){
  const h=elfTourRoomHash(c,p.map(x=>Math.floor(x/162)));return c.themePerm[h%8];
}
// advance: path distance for this frame in units of the explorer's size (beat-locked in frame()); turn: gaze rate
function elfTourStep(c,dt,advance,turn){
  dt=Math.max(0,Math.min(.05,dt));advance=Math.max(0,Math.min(ELF_TOUR_SCALE*.5,advance));
  const speed=Math.max(.3,Math.min(4,turn));c.age+=dt;c.velocity=dt>0?advance/dt:0;
  // dives plunge faster (eased in and out over about a second)
  const sw=c.segs[0]&&c.segs[0].spd||1;c.spdS=(c.spdS||1)+(sw-(c.spdS||1))*(1-Math.exp(-dt*2.2));
  let adv=advance*c.spdS*elfTourSig(c)/9;
  for(let i=0;i<12;i++){
    const left=c.segs[0].len-c.along;
    if(adv<left){c.along+=adv;break;}
    adv-=left;const s=c.segs.shift();c.along=0;
    if(s.hop){ // the end of a dive: everything is 3x bigger again (seamlessly the same view)
      c.reinit=1;
    }
    elfTourFill(c);
  }
  elfTourFill(c);
  c.sig=elfTourSig(c);
  const sig=c.sig,p=elfTourAt(c,0);let gaze=[0,0,0];
  for(const [d,w] of [[.35,.45],[.7,.35],[1.15,.20]])gaze=elfTourAdd(gaze,elfTourAdd(elfTourAt(c,d*sig),p,-1),w);
  let target=elfTourNorm(gaze);
  // spirals look up or down the shaft, bridges down into the well, galleries across the hall
  const lb=elfTourLook(c);c.lookBias=c.lookBias||[0,0,0];
  const lw=1-Math.exp(-dt*1.2);c.lookBias=c.lookBias.map((x,i)=>x+((lb?lb[i]:0)-x)*lw);
  target=elfTourNorm(elfTourAdd(target,c.lookBias));
  target=elfTourNorm(elfTourAdd(target,[0,-.06,0])); // v11: a touch downward, toward the floor and the residents
  // gaze phrases: for part of each phrase the camera turns its head toward the nearest resident ahead
  const look=elfTourElfLook(c,p,target,dt);
  if(look>1e-3)target=elfTourNorm(target.map((x,i)=>x*(1-look)+c.lookDir[i]*look));
  const old=c.forward.slice(),dot=Math.max(-1,Math.min(1,elfTourDot(old,target))),angle=Math.acos(dot);
  const blend=angle>1e-7?Math.min(1-Math.exp(-dt*2*speed),.48*speed*dt/angle):1;
  c.forward=elfTourNorm(old.map((x,i)=>x*(1-blend)+target[i]*blend));
  let up=elfTourAdd(c.up,c.forward,-elfTourDot(c.up,c.forward));
  if(Math.hypot(...up)<.01){const ref=Math.abs(c.forward[1])>.85?[0,0,1]:[0,1,0];up=elfTourAdd(ref,c.forward,-elfTourDot(ref,c.forward));}
  up=elfTourNorm(up);
  const gravity=elfTourAdd([0,1,0],c.forward,-c.forward[1]),glen=Math.hypot(...gravity);
  if(glen>.15){const g=elfTourNorm(gravity),a=(1-Math.exp(-dt*.18))*glen*glen;up=elfTourNorm(up.map((x,i)=>x*(1-a)+g[i]*a));}
  c.up=up;const right=elfTourNorm(elfTourCross(c.forward,up));up=elfTourNorm(elfTourCross(right,c.forward));
  const yaw=dt>0?elfTourCross(old,c.forward)[1]/dt:0,bankTarget=Math.max(-.08,Math.min(.08,-yaw*.12));
  c.bank+=(bankTarget-c.bank)*(1-Math.exp(-dt*2));
  // the recursive vault: the explorer rolls once round its axis while it shrinks to a third (seamless at the hop)
  const s0=c.segs[0],dv=s0&&s0.dive?Math.max(0,Math.min(1,Math.log(9/sig)/Math.log(3))):0,rollA=(s0&&s0.roll||1)*2*Math.PI*dv*dv*(3-2*dv);
  c.diveP=dv;const cb=Math.cos(c.bank+rollA),sb=Math.sin(c.bank+rollA);
  const r=right.map((x,i)=>x*cb+up[i]*sb),u=up.map((x,i)=>x*cb-right[i]*sb);
  return {p,r,u,f:c.forward.slice(),sig};
}
// zoomed out, the camera pulls back and up behind the explorer as far as the stone allows (checked ahead in time)
function elfTourPull(c,fr,zm,dt){
  const want=Math.max(0,Math.min(7.5,1.25/Math.max(zm,.05)-1.25)),sig=fr.sig;
  // v13: the pull-back direction (back / up / side, in the explorer's frame) is the freest of a few candidates, looked
  // for four times a second and eased, so a wall right behind no longer freezes the zoom-out (it used to pin .15 = .4)
  if(!c.pdir)c.pdir=[.9,.36,0];
  c.pdT=(c.pdT||0)-dt;
  if(want>.3&&c.pdT<=0){
    c.pdT=.25;const C=[[.9,.36,0],[.35,.9,0],[.97,0,0],[.6,.3,.7],[.6,.3,-.7]];let best=null,bs=-1;
    for(const d of C){const od=elfTourAdd(elfTourAdd(fr.f.map(x=>-x*d[0]*want*sig),fr.u,d[1]*want*sig),fr.r,d[2]*want*sig);
      const sc=elfClearFrac(fr.p,od,.9*sig/9)*(d===C[0]?1.15:1);if(sc>bs){bs=sc;best=d;}}
    c.pdG=best;
  }
  if(c.pdG){const e=1-Math.exp(-dt*1.2);c.pdir=c.pdir.map((x,i)=>x+(c.pdG[i]-x)*e);}
  const pd=c.pdir,o=elfTourAdd(elfTourAdd(fr.f.map(x=>-x*pd[0]*want*sig),fr.u,pd[1]*want*sig),fr.r,pd[2]*want*sig);
  let lam=1;
  if(want>.01){
    const clr=.9*sig/9;
    lam=elfClearFrac(fr.p,o,clr);
    for(const k of [.7,1.5]){const pa=elfTourAt(c,k*sig);lam=Math.min(lam,elfClearFrac(pa,o,clr)+.15);}
  }
  const now=want>.01?elfClearFrac(fr.p,o,.75*sig/9):1;
  c.pullL+=(lam-c.pullL)*(1-Math.exp(-dt*1.6));
  if(now<c.pullL)c.pullL=now<c.pullL-.35?now:c.pullL+(now-c.pullL)*(1-Math.exp(-dt*9)); // v11: ease to the stone, snap only on a real collision
  return elfTourAdd(fr.p,o,want>.01?c.pullL:0);
}
function elfTourElfLook(c,p,path,dt){
  if(!c.lookDir)c.lookDir=path.slice();
  let best=null,score=0;
  for(const e of c.inhabitants){
    if(e.fade<.6||e.far&&!e.ev)continue;
    const d=elfTourAdd(elfTourResidentPosition(c,e,0),p,-1),l=Math.hypot(...d);
    if(l<ELF_TOUR_SCALE*.7||l>ELF_TOUR_SCALE*5)continue;
    const dir=d.map(x=>x/l),cs=elfTourDot(dir,path),s=(cs-.55)/(l/ELF_TOUR_SCALE+1);
    if(cs>.55&&s>score){score=s;best=dir;}
  }
  const a=1-Math.exp(-Math.max(0,dt)*1.6);
  const want=best?c.lookWant*Math.min(1,score*8):0;
  if(best)c.lookDir=elfTourNorm(c.lookDir.map((x,i)=>x+(best[i]-x)*a));
  c.look=(c.look||0)+(want-(c.look||0))*a;
  return c.look*.6;
}
function elfTourRoomHash(c,n){
  let h=c.visitSeed^Math.imul(n[0]+17,0x45d9f3b)^Math.imul(n[1]+31,0x119de1f3)^Math.imul(n[2]+53,0x27d4eb2d);
  h=Math.imul(h^(h>>>16),0x7feb352d);h=Math.imul(h^(h>>>15),0x846ca68b);return (h^(h>>>16))>>>0;
}
// the character (one of six designs) of the resident of a room: the same hash the shader used, so every room keeps
// the resident it had; visiting elves (processions, choirs, workers) are cast explicitly
function elfCharOf(c,p){
  const n=p.map(x=>Math.floor(x/18));
  let h=(c.visitSeed^Math.imul(n[0]+17,0x045d9f3b)^Math.imul(n[1]+31,0x119de1f3)^Math.imul(n[2]+53,0x27d4eb2d))>>>0;
  h=Math.imul(h^(h>>>16),0x7feb352d)>>>0;h=Math.imul(h^(h>>>15),0x846ca68b)>>>0;return ((h^(h>>>16))>>>0)%6;
}
function elfTourResident(c,n,far){
  const hash=elfTourRoomHash(c,n),anchor=elfTourNode(n);
  return {key:n.join(','),room:n.slice(),anchor,phase:(hash>>>4)/268435456*Math.PI*2,rate:.13+((hash>>>12)&255)/255*.11,axis:(hash>>>20)%3,fade:1,next:null,far:!!far,greet:0,
    char:elfCharOf(c,elfTourAdd(anchor,ELF_OFF,9))};
}
// a visiting elf of an encounter: anchored at an exact point (walking, or circling with its choir)
function elfEventResident(c,m){
  const h=elfTourRoomHash(c,[m.id*7+3,m.i*13+1,m.id]);
  return {key:m.key,room:null,anchor:m.pos.slice(),ev:m,phase:(h>>>4)/268435456*Math.PI*2,rate:.13+((h>>>12)&255)/255*.11,axis:(h>>>20)%3,fade:0,next:null,far:!!m.far,greet:0,char:m.char,ws:0};
}
const ELF_OFF=[.14,.23,.14];
function elfResidentOK(n){const a=elfTourAdd(elfTourNode(n),ELF_OFF,9);return elfDE(a)>1.;}
function elfLOS(a,b){
  const o=elfTourAdd(b,a,-1),L=Math.hypot(...o);if(L<1e-3)return true;const dir=o.map(x=>x/L);let s=.5;
  for(let i=0;i<64&&s<L-2;i++){const dd=elfDE(elfTourAdd(a,dir,s));if(dd<.25)return false;s+=Math.max(dd*.9,.25);}
  return true;
}
// ---- encounters: every 10-17 s an encounter is staged on the route ahead (never the same kind twice running):
// a procession walking down the nave, a choir circling round the path, elves waving from balconies, elves at work at
// their benches in the workshop, or a guard of honour lining the path through a great hall ----
const ELF_EV=['procession','choir','balcony','workers','guard'];
function elfRouteFrame(c,d){
  const p=elfTourAt(c,d),q=elfTourAt(c,d+1.5),t=elfTourNorm(elfTourAdd(q,p,-1));
  let s=elfTourCross(t,[0,1,0]);if(Math.hypot(...s)<.3)s=elfTourCross(t,[1,0,0]);s=elfTourNorm(s);
  return {p,t,s,u:elfTourNorm(elfTourCross(s,t))};
}
// a spot beside the route at distance d (side +-1): clear of the stone and visible from the route
function elfEvSpot(c,d,side,opts){
  const f=elfRouteFrame(c,d),back=elfTourAt(c,Math.max(0,d-14));
  for(const [a,b] of opts){
    const x=elfTourAdd(elfTourAdd(f.p,f.s,side*a),f.u,b);
    if(elfDE(x)>.9&&elfLOS(f.p,x)&&elfLOS(back,x))return {pos:x,f};
  }
  return null;
}
function elfEvStage(c,kind){
  const id=(c.evId=(c.evId||0)+1),ch0=Math.floor(elfTourRand(c)*6),mem=[];
  const add=(pos,o)=>mem.push(Object.assign({id,i:mem.length,key:'e'+id+'_'+mem.length,pos,char:(ch0+mem.length*(1+(id%2)*4))%6},o||{}));
  const near=[[1.5,.5],[1.2,1.3],[.9,1.8],[1.7,-.4],[0,2.1]];
  if(kind==='procession'||kind==='workers'||kind==='guard'){
    const n=kind==='workers'?2+Math.floor(elfTourRand(c)*2):3+Math.floor(elfTourRand(c)*2),gap=kind==='guard'?10:kind==='workers'?9:6.5,d0=28+elfTourRand(c)*8;
    const sd=elfTourRand(c)<.5?1:-1;
    for(let i=0;i<n;i++){
      const side=kind==='procession'?(i%2?-sd:sd):(kind==='guard'?(i%2?-1:1):sd);
      const sp=elfEvSpot(c,d0+i*gap,side,kind==='guard'?[[2.2,.8],[1.6,1.4],[1.2,1.9]]:near);if(!sp)continue;
      add(sp.pos,kind==='procession'?{walk:elfTourNorm([sp.f.t[0],0,sp.f.t[2]])}:{});
    }
    return mem.length>=2?mem:null;
  }
  if(kind==='choir'){
    // a ring of three or four elves circling round the path; the explorer passes through the ring
    const d=30+elfTourRand(c)*10,f=elfRouteFrame(c,d),C=elfTourAdd(f.p,[0,1,0],1.5),n=3+Math.floor(elfTourRand(c)*2);
    for(const r of [1.7,1.3]){
      let ok=true;for(let k=0;k<12&&ok;k++){const a=k/12*Math.PI*2;if(elfDE(elfTourAdd(C,[Math.cos(a)*r,0,Math.sin(a)*r]))<.85)ok=false;}
      if(!ok||!elfLOS(elfTourAt(c,Math.max(0,d-14)),C))continue;
      const a0=elfTourRand(c)*6.28,w=(elfTourRand(c)<.5?1:-1)*.55;
      for(let i=0;i<n;i++)add(elfTourAdd(C,[Math.cos(a0+i*6.283/n)*r,0,Math.sin(a0+i*6.283/n)*r]),{orbit:{C,r,a0:a0+i*6.283/n,w,t0:c.age}});
      return mem;
    }
    return null;
  }
  if(kind==='balcony'){
    // elves in the openings of the nave walls, waving down at the passing explorer
    for(let k=0;k<2;k++){
      const d=26+k*14+elfTourRand(c)*8,side=(k%2?-1:1)*(elfTourRand(c)<.5?1:-1);
      const opts=[[3.6,1.6],[4.6,2.6],[3.2,3.4],[5.8,1.2],[2.8,4.2],[6.5,3.2]];
      const f=elfRouteFrame(c,d);
      for(const [a,b] of opts){
        const x=elfTourAdd(elfTourAdd(f.p,f.s,side*a),f.u,b),cl=elfDE(x);
        if(cl>.8&&cl<4&&elfLOS(f.p,x)&&elfLOS(elfTourAt(c,Math.max(0,d-16)),x)){add(x,{far:true});break;}
      }
    }
    return mem.length?mem:null;
  }
  return null;
}
function elfEvents(c,fr,dt){
  c.events=c.events||[];
  if(c.diving){c.events.length=0;return;}
  // an encounter ends once the explorer has passed all of it or turned away from it (or after 18 s)
  c.events=c.events.filter(g=>{
    if(c.age-g.t0>18)return false;
    return g.members.some(m=>{const e=c.inhabitants.find(x=>x.key===m.key),p=e?elfTourResidentPosition(c,e,0):m.pos,d=elfTourAdd(p,fr.p,-1),l=Math.hypot(...d);
      return (elfTourDot(d,fr.f)>-.2*l||l<9)&&l<70;});
  });
  if(c.evNext==null)c.evNext=(c.trav||0)+6;
  if(c.events.length||(c.trav||0)<c.evNext)return;
  const w={procession:1.2,choir:1,balcony:.9,workers:0,guard:c.vastS>.25?1.4:.15};
  if((c.thB===2||c.thA===2)&&c.thM===0)w.workers=2.2;
  if(w[c.evLast])w[c.evLast]*=.25;
  let tot=0;for(const k of ELF_EV)tot+=w[k];let q=elfTourRand(c)*tot,kind='procession';
  for(const k of ELF_EV){q-=w[k];if(q<=0){kind=k;break;}}
  const mem=elfEvStage(c,kind);
  if(!mem){c.evNext=(c.trav||0)+2;c.stat=c.stat||{};c.stat.evFail=(c.stat.evFail||0)+1;return;}
  c.events.push({kind,members:mem,t0:c.age});c.evLast=kind;c.evNext=(c.trav||0)+20+elfTourRand(c)*16;
  c.stat=c.stat||{};c.stat['ev_'+kind]=(c.stat['ev_'+kind]||0)+1;
  c.residentClock=0;elfTourResidents(c,fr);
}
// residents: the nearest rooms are inhabited; in the great halls two of them stand on far balconies, tiny in the
// distance, and wave at the explorer; the elves of a staged encounter take precedence. A resident moves house only
// while out of view (it fades out and back in); an encounter may call a visible resident away.
function elfTourResidents(c,fr,initial=false){
  if(!initial&&c.age<c.residentClock)return;c.residentClock=c.age+.5;
  const n0=elfNodeOf(fr.p),near=[],far=[];
  if(!c.diving){
    for(let x=-3;x<=3;x++)for(let y=-3;y<=3;y++)for(let z=-3;z<=3;z++){
      const room=[n0[0]+x,n0[1]+y,n0[2]+z],anchor=elfTourNode(room),distance=Math.hypot(...elfTourAdd(anchor,fr.p,-1));
      if(distance<ELF_TOUR_SCALE*7&&elfResidentOK(room))near.push({room,distance,key:room.join(',')});
    }
    near.sort((a,b)=>a.distance-b.distance);
    if(c.vastS>.3){
      const cand=[];
      for(let x=-6;x<=6;x++)for(let y=-4;y<=4;y++)for(let z=-6;z<=6;z++){
        const room=[n0[0]+x,n0[1]+y,n0[2]+z],anchor=elfTourNode(room),dv=elfTourAdd(anchor,fr.p,-1),l=Math.hypot(...dv);
        if(l<ELF_TOUR_SCALE*3.5||l>ELF_TOUR_SCALE*13)continue;
        const cs=elfTourDot(dv,fr.f)/l;if(cs<.6)continue;
        const cl=elfDE(anchor);if(cl<1.2||cl>7)continue;
        // a balcony: a small room opening onto the great space in front of it
        const toward=elfTourAdd(anchor,dv,-12/l);if(elfDE(toward)<9)continue;
        cand.push({room,distance:l,key:room.join(','),score:cs+.002*l});
      }
      cand.sort((a,b)=>b.score-a.score);
      for(const x of cand){if(far.length>=2)break;if(elfLOS(fr.p,elfTourAdd(elfTourNode(x.room),ELF_OFF,9)))far.push(x);}
    }
  }
  const ev=c.diving?[]:(c.events||[]).flatMap(g=>g.members).slice(0,5).map(m=>({key:m.key,ev:m}));
  const nFar=Math.min(far.length,6-ev.length),desired=ev.concat(far.slice(0,nFar).map(x=>Object.assign({far:true},x)),near.slice(0,6-ev.length-nFar));
  const make=x=>x.ev?elfEventResident(c,x.ev):elfTourResident(c,x.room,x.far);
  if(initial){c.inhabitants=desired.slice(0,6).map(make);for(const e of c.inhabitants)e.fade=1;while(c.inhabitants.length<6){const e=elfTourResident(c,[n0[0],n0[1]+9,n0[2]]);e.fade=0;c.inhabitants.push(e);}return;}
  const want=new Map(desired.map(x=>[x.key,x])),occupied=new Set(c.inhabitants.flatMap(e=>[e.key,...(e.next?[e.next.key]:[])]));
  for(const e of c.inhabitants){
    if(e.next)continue;
    if(want.has(e.key)&&!c.diving){if(!e.ev)e.far=!!want.get(e.key).far;continue;}
    if(!c.diving&&!elfTourResidentOffscreen(c,e,fr)&&e.fade>.05)continue;
    const next=desired.find(x=>!occupied.has(x.key));
    if(next){e.next=next;occupied.add(next.key);}
    else if(c.diving)e.next={key:e.key,room:e.room||[n0[0],n0[1]+9,n0[2]]};
  }
  // the elves of an encounter must be in place in time: a resident that is not wanted gives up its slot, the
  // farthest first, even in view (it fades away)
  for(const x of desired){
    if(!x.ev||occupied.has(x.key))continue;
    let best=null,bd=-1;
    for(const e of c.inhabitants){if(e.next||want.has(e.key)||e.greet>.2)continue;const l=Math.hypot(...elfTourAdd(elfTourResidentPosition(c,e,0),fr.p,-1));if(l>bd){bd=l;best=e;}}
    if(best){best.next=x;occupied.add(x.key);}
  }
}
function elfTourResidentOffscreen(c,e,fr){
  const p=elfTourResidentPosition(c,e,0),d=elfTourAdd(p,fr.p,-1),l=Math.hypot(...d);
  return l>ELF_TOUR_SCALE*1.5&&elfTourDot(d,fr.f)<l*.35||l>ELF_TOUR_SCALE*14;
}
function elfTourResidentTick(c,fr,dt){
  elfEvents(c,fr,dt);
  elfTourResidents(c,fr);const a=1-Math.exp(-Math.max(0,dt)*2.2),ga=1-Math.exp(-Math.max(0,dt)*2.5);
  // encounters: a resident the camera approaches in view turns to it, waves and lets its glyphs fly; far residents on
  // their balconies wave whenever the explorer looks their way
  let meet=0;
  for(const e of c.inhabitants){
    // a procession walks slowly on down the nave while there is room ahead
    if(e.ev&&e.ev.walk){const nx=elfTourAdd(e.ev.pos,e.ev.walk,e.ws+dt*.8+1.2);if(elfDE(nx)>.95)e.ws+=dt*.8;}
    const d=elfTourAdd(elfTourResidentPosition(c,e,0),fr.p,-1),l=Math.hypot(...d),cs=l>1e-6?elfTourDot(d,fr.f)/l:0;
    let near=Math.max(0,Math.min(1,(1.9*ELF_TOUR_SCALE-l)/(.7*ELF_TOUR_SCALE)))*Math.max(0,Math.min(1,(cs-.5)/.25))*(e.fade>.6?1:0);
    if(e.far)near=Math.max(0,Math.min(1,(cs-.75)/.15))*(e.fade>.6?1:0);
    e.greet=(e.greet||0)+(near-(e.greet||0))*ga;if(!e.far)meet=Math.max(meet,e.greet);
  }
  c.meet=meet;
  for(let i=0;i<c.inhabitants.length;i++){
    let e=c.inhabitants[i];
    e.fade+=((e.next||c.diving?0:1)-e.fade)*a;
    if(e.next&&e.fade<.015&&!c.diving){
      const x=e.next,replacement=x.ev?elfEventResident(c,x.ev):elfTourResident(c,x.room,x.far);replacement.fade=0;c.inhabitants[i]=replacement;
    }
  }
}
// two residents per float: 8-bit fades and 4-bit greetings (24 bits, exact in a float uniform)
const elfTourQ=(x,n)=>Math.round(Math.max(0,Math.min(1,x||0))*n);
function elfTourPackFade(a,b,ga,gb){return elfTourQ(a,255)+256*elfTourQ(b,255)+65536*(elfTourQ(ga,15)+16*elfTourQ(gb,15));}
// the six characters, three bits each (18 bits, exact in a float uniform)
function elfTourPackChars(c){let s=0;for(let i=5;i>=0;i--)s=s*8+((c.inhabitants[i]&&c.inhabitants[i].char)||0);return s;}
function elfTourResidentPosition(c,e,kick){
  const t=c.age*e.rate+e.phase,offset=e.ev?[0,0,0]:ELF_OFF.slice(),a=e.axis===1?2:e.axis,b=(a+1)%3,d=(a+2)%3;
  offset[a]+=Math.sin(t)*.05;offset[b]+=Math.sin(t*.81+e.phase)*.010;offset[d]+=Math.cos(t*.67)*.015;
  // the residents dance: a hop on every beat (landing on the kick) and a sway over two beats, bigger while greeting
  const tr=c.trav||0,ph=((tr%1)+1)%1,g=e.greet||0,sw=a===0?2:0;
  offset[1]+=4*ph*(1-ph)*(.005+.013*g);
  offset[sw]+=Math.sin(tr*Math.PI*.5)*(.006+.012*g);
  let A=e.anchor;
  if(e.ev&&e.ev.orbit){const o=e.ev.orbit,an=o.a0+o.w*(c.age-o.t0);A=[o.C[0]+o.r*Math.cos(an),o.C[1],o.C[2]+o.r*Math.sin(an)];}
  else if(e.ev&&e.ev.walk)A=elfTourAdd(A,e.ev.walk,e.ws);
  return elfTourAdd(A,offset,ELF_TOUR_SCALE);
}
