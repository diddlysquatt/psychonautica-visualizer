const R_UMI = `
// UMI POP: a superflat smiling ocean. Seven parallax layers of original kawaii sea characters (fish, octopi,
// pufferfish, starfish, bubbles) packed edge to edge over a seigaiha wave ground, all crisp ink-outlined 2D SDFs.
// Each size class sings its own band; fish swim one stroke per beat, octopi jet on the beat, puffers inflate on
// the kick, starfish turn one notch per beat. Families: REEF (layers drift in opposite directions), SCHOOLS (lanes
// of fish swimming alternate ways), WHIRLPOOL (log-polar rings circling a spectrum octopus-sun whose 8 arms are the
// 8 bands), RISE (everything jets upward in bouncy beat steps). Zoomed out, schools of giant fish made of fish swim
// by; the giant-octopus event flips the whole field like a stadium card stunt into one waving, singing octopus.
// uP1 [swim beats (trav + build extra), mt, kick env, snare flash]   uP2 mouths [carpet(air), small(bass), mid(harmony), big(lead)]
// uP3 [wave front x (9 = none), build, breakdown, drop flash]   uP4 [famA, vsA, event+progress, colour shift]
// uP5 [famB, vsB, trav, bar blink]   uM1, uM2: the six palette colours (linear)
#if HD>=1
// v19 detail tiers (HD>=1 only): finer layers of characters behind the seven (the sea is crowded further down), screentone and print ornament on every body,
// finer wave engraving on the ground, chromatophores on the squid, and several full picture samples per pixel. Ornament is coloured ink at limited coverage.
#if HD>=5
#define UM_X 6
#define UM_AA 13
#elif HD>=4
#define UM_X 5
#define UM_AA 8
#elif HD>=3
#define UM_X 4
#define UM_AA 5
#elif HD>=2
#define UM_X 4
#define UM_AA 4
#else
#define UM_X 3
#define UM_AA 3
#endif
int umZ;
#endif
vec3 umiC(float i){float k=i-6.*floor((i+.5)/6.);
  vec3 a=k<.5?uM1[0]:(k<1.5?uM1[1]:uM1[2]),b=k<3.5?uM2[0]:(k<4.5?uM2[1]:uM2[2]);return k<2.5?a:b;}
const vec3 UMINK=vec3(.012,.01,.035);
float umiAt(float y,float x){float ax=abs(x),ay=abs(y),t=min(ax,ay)/max(max(ax,ay),1e-20),s=t*t;
  float r=((-.0464964749*s+.15931422)*s-.327622764)*s*t+t;r=mix(r,1.5707963-r,step(ax,ay));r=mix(r,3.1415927-r,step(x,0.));return r-2.*r*step(y,0.);}
vec4 umiH(vec2 id,float L){return fract(sin(vec4(dot(id,vec2(127.1,311.7)),dot(id,vec2(269.5,183.3)),dot(id,vec2(419.2,371.9)),dot(id,vec2(113.5,271.9)))+L*7.31)*43758.545);}
float umiEl(vec2 p,vec2 ab){float k0=length(p/ab),k1=length(p/(ab*ab));return k0*(k0-1.)/max(k1,1e-5);}
float umiA(float d,float e){return clamp(.5-.5*d/e,0.,1.);}
float umiBack(float x){x=min(x/.42,1.)-1.;return 1.+2.70158*x*x*x+1.70158*x*x;}
// ---- silhouettes (units of the character radius)
float umiStar(vec2 p){
  const vec2 k1=vec2(.809016994,-.587785252),k2=vec2(-.809016994,-.587785252);
  p.x=abs(p.x);p-=2.*max(dot(k1,p),0.)*k1;p-=2.*max(dot(k2,p),0.)*k2;p.x=abs(p.x);p.y-=.86;
  vec2 ba=.5*vec2(-k1.y,k1.x)-vec2(0.,1.);float h=clamp(dot(p,ba)/dot(ba,ba),0.,.86);
  return length(p-ba*h)*sign(p.y*ba.x-p.x*ba.y)-.09;
}
// fish facing +x: round body, forked tail that wags about its joint, a dorsal fin
float umiTail(vec2 q,float wag){vec2 t=rot(wag)*(q+vec2(.42,0.));
  float tl=max(max((abs(t.y)+t.x*1.05-.07)*.69,-t.x-.52),t.x-.1);return max(tl,((-t.x-.36)*1.3-abs(t.y))*.61);}
float umiFish(vec2 q,float wag){
  float b=umiEl(q-vec2(.1,0.),vec2(.64,.46));
  float fn=umiEl(rot(.45)*(q-vec2(-.04,.4)),vec2(.3,.13));
  return min(min(b,umiTail(q,wag)),fn);
}
// octopus: domed head and four wavy tentacles that flare out when it jets
vec3 umiOctoT(vec2 q,float fl,float ph){
  float y=-q.y+.02,sp=1.+(.3+.55*fl)*clamp(y,0.,1.);
  float xs=q.x/sp,k=clamp(floor(xs/.29+2.),0.,3.);
  float lx=(xs-(k-1.5)*.29-.07*sin(y*7.-ph+k*1.9)*y)*sp,len=.74+.12*fl;
  return vec3(length(vec2(lx,y-clamp(y,0.,len)))-.13*(1.-.5*clamp(y/len,0.,1.)),lx,y);
}
float umiOcto(vec2 q,float fl,float ph){return min(umiEl(q-vec2(0.,.24),vec2(.6,.54)),umiOctoT(q,fl,ph).x);}
// pufferfish: round, 14 spikes that grow when it puffs up on the kick, a little tail
float umiPuff(vec2 q,float pf){
  float r=length(q),s=1.-abs(fract(umiAt(q.y,q.x)*2.2282)-.5)*2.;
  float d=(r-.6-.08*pf-(.05+.17*pf)*s*s*s)*.8;
  return min(d,umiEl(q-vec2(-.74-.06*pf,0.),vec2(.17,.25)));
}
float umiSil(vec2 q,float ty,float wag,float fl,float ph,float pf,float sa){
  float d=umiFish(q,wag);
  d=mix(d,umiOcto(q,fl,ph),step(.5,ty));
  d=mix(d,umiPuff(q,pf),step(1.5,ty));
  d=mix(d,umiStar(rot(sa)*q),step(2.5,ty));
  return mix(d,length(q)-.7,step(3.5,ty));
}
float umiHeart(vec2 p){p.x=abs(p.x);vec2 q=p-.5*max(p.x+p.y,0.);
  return mix(sqrt(min(dot(p-vec2(0.,1.),p-vec2(0.,1.)),dot(q,q)))*sign(p.x-p.y),length(p-vec2(.25,.75))-.35355,step(1.,p.y+p.x));}
// kawaii face in face units: two eyes (front) or one big side eye (sd=1, fish); big glossy eyes with two glints,
// happy closed arcs (singing / sleepy), heart eyes, a wink; cheeks; a smile that opens into a round singing "o"
vec3 umiFace(vec3 col,vec2 f,float pf,float mo,float bl,float slp,vec4 h,float lod,float eo,float sd){
  float lw=max(.075,1.25*pf),ex=eo<0.?fract(h.w*7.77+h.y*3.1):eo;
  vec2 gz=vec2(sin(uP1.y*.9+h.y*6.),cos(uP1.y*.7+h.z*6.))*.05*(1.-slp);
  float happy=max(step(ex,.18),step(.5,slp)),heart=(1.-happy)*step(ex,.3),wink=(1.-happy)*step(.9,ex)*step(0.,f.x)*(1.-sd);
  float es=1.+.35*sd;
  vec2 ck=vec2(mix(abs(f.x)-.6,f.x+.05,sd),f.y+.2);
  col=mix(col,mix(col,vec3(1.7,.3,.45),.6),umiA(length(ck/vec2(.17,.11))-1.,pf)*step(.25,h.w)*lod);
  vec2 e=vec2(mix(abs(f.x)-.36,f.x,sd),f.y-.14)/es-gz;
  float op=(1.-bl)*(1.-slp);
  float de=(length(e/vec2(.14,.2*max(op,.08)))-1.)*.14*es;
  vec2 ea=vec2(mix(abs(f.x)-.36,f.x,sd),f.y-.08)/es;float darc=max(abs(length(ea)-.13)-lw*.5/es,-ea.y)*es;
  float cl=max(max(happy,wink),step(op,.15));
  float eye=mix(umiA(de,pf),umiA(darc,pf),cl);
  float hh=heart*step(.15,op);
  float dh=umiHeart((e+vec2(0.,.15))/.3)*.3*es;
  col=mix(col,UMINK,mix(eye,umiA(dh-lw*.6,pf),hh)*lod);
  col=mix(col,vec3(2.,.12,.35)*(1.+.6*uO2.y),umiA(dh,pf)*hh*lod);
  float gl=max(umiA(length(e-vec2(.045,.08))-.055,pf/es),umiA(length(e-vec2(-.05,-.08))-.028,pf/es))*step(.3,op)*(1.-cl)*(1.-hh);
  col=mix(col,vec3(1.5),gl*lod);
  // mouth: closed = small smile; open = round singing "o" with a tongue
  vec2 m=vec2(f.x-.5*sd,f.y+.3+.04*sd);
  float om=smoothstep(.1,.25,mo),ry=.03+.25*mo;
  float dm=umiEl(m,vec2(.13+.09*mo,ry));
  float ds=max(abs(length(m-vec2(0.,.2))-.24)-lw*.5,m.y-.12);
  vec3 mc=mix(vec3(.6,.02,.08),vec3(1.6,.4,.5),umiA(length(m-vec2(0.,-ry*.7))-ry*.55,pf));
  col=mix(col,UMINK,umiA(ds,pf)*(1.-om)*lod);
  col=mix(col,mc,umiA(dm,pf)*om*lod);
  col=mix(col,UMINK,umiA(abs(dm)-lw*.5,pf)*om*lod);
  return col;
}
// ---- v18 the big squid: a world creature, not an overlay. Local units: mantle centre (0,.3), arms hanging below.
// returns distance, arm coordinate (0 on the mantle, >0 along an arm), arm lateral, arm index
float umiSqP(vec2 q){return length(q-vec2(0.,clamp(q.y,-.8,.62)))-.74;}
vec4 umiSquid(vec2 q,float fl,float ph,float wv,float bs){
  float dM=min(umiEl(q-vec2(0.,.3),vec2(.6+.07*fl+.04*bs,.62)),umiEl(q-vec2(0.,.8),vec2(.86+.06*fl,.23)));
  float y=-(q.y+.12),sp=1.+(.16+.5*fl)*clamp(y,0.,1.4),xs=q.x/sp,k=clamp(floor(xs/.19+4.),0.,7.),kc=k-3.5;
  float lx=(xs-kc*.19-(.06+.11*wv)*sin(y*5.-ph+k*1.7)*y)*sp,len=mix(.98,1.24,1.-abs(kc)/3.5)+.1*fl+.08*wv;
  float wd=.11*(1.-.55*clamp(y/len,0.,1.));
  float dA=min(length(vec2(lx,y-clamp(y,0.,len)))-wd,length(vec2(lx,y-len))-.12);
  return vec4(min(dM,dA),step(dA,dM)*step(0.,y)*y,lx,k);
}
// v20 print textures (line distance in body units): 0 scales, 1 shippo (interlocking circles), 2 uroko (triangle lattice), 3 yagasuri (arrow chevrons)
float umiPrint(vec2 q,float k,float n){
  vec2 g=q*n;
  if(k<.5){float rw=floor(g.y);return abs(length(vec2(fract(g.x+.5*rw)-.5,fract(g.y)))-.5)/n-.004;}
  if(k<1.5){vec2 f=fract(g*.6)-.5;return min(abs(length(f)-.5),abs(length(abs(f)-.5)-.5))/(n*.6)-.0035;}
  if(k<2.5){vec2 t=g*.8;return min(min(abs(fract(t.y)-.5),abs(fract(t.x*.8660254+t.y*.5)-.5)),abs(fract(t.x*.8660254-t.y*.5)-.5))/(n*.8)-.0035;}
  vec2 a=g*.7;return abs(fract(a.y+abs(fract(a.x)-.5))-.5)/(n*.7)-.006;
}
// the giant fishes' macro cell at world position m: xy = the fish's own coordinates, z = its hash
vec3 umiGq(vec2 m,float gd,float tr){
  vec2 mu=rot(.42)*(m-vec2(gd*tr*.03,0.))/2.4+vec2(.31,.17);
  vec4 mc=floor(vec4(mu,mu-vec2(.5,.8660254))/vec2(1.,1.7320508).xyxy)+.5;
  vec2 ma=mu-mc.xy*vec2(1.,1.7320508),mb=mu-(mc.zw+.5)*vec2(1.,1.7320508);
  vec2 mq=mix(mb,ma,step(dot(ma,ma),dot(mb,mb)));
  vec2 mid=floor((mu-mq)*2.+.5);mq=rot(-.42)*mq/.44*vec2(gd,1.);
  return vec3(mq,h21(mid));
}
#if HD>=1
vec3 umiPic(vec2 p0){
#else
void realm(){
  vec2 p0=scr();
#endif
  float xf=uP3.x+.045*sin(p0.y*11.+uP1.y*4.)+.16*p0.y,eW=p0.x-xf;
  vec4 C=mix(uP4,uP5,step(eW,0.));
  float ev=floor(uP4.z),evp=fract(uP4.z),evb=evp*16.,fam=C.x,vs=C.y,csN=floor(uP4.w/4.),ramp=uP4.w-4.*csN;
  float tr=uP1.x,tb=uP5.z,kick=uP1.z,lmA=floor(uP1.w/256.)*.0101,hw0=uP1.w-256.*floor(uP1.w/256.),htA=floor(hw0*.5)*.01,bsS=hw0-2.*floor(hw0*.5),bld=uP3.y,brk=uP3.z,aiA=floor(uP3.w*.5)*.01,dfl=uP3.w-2.*floor(uP3.w*.5),mt=uP1.y;
  float fSch=step(abs(fam-1.),.5),fWh=step(abs(fam-2.),.5),fRise=step(abs(fam-3.),.5),fReef=1.-fSch-fWh-fRise;
  float eG=step(abs(ev-4.),.5),eT=step(abs(ev-2.),.5),gs=eG*smoothstep(0.,1.5,evb)*(1.-smoothstep(13.,15.,evb));
  float zm=uZoom*(1.+.1*bld);
  vec2 p=p0/zm;float px=1./(uRes.y*zm);
  float pa=umiAt(p.y,p.x),rr=length(p);
  // the whirlpool is a bounded vortex: zoomed out, the reef and its giant fish swim around it
  float dW=rr-2.1;fWh*=step(dW,0.);
  float c0=mix(.048,.06,fract(vs*7.31)),gr=mix(1.45,1.57,fract(vs*3.17));
  float rate=1.-.5*step(.72,fract(vs*2.71)),gd=step(.5,fract(vs*4.1))*2.-1.;
  // swim clock: a stroke per beat (eased with overshoot) plus the build's extra distance
  float sw=floor(tb)+umiBack(fract(tb))+tr-tb,fl0=sin(PI*min(fract(tb)/.5,1.));fl0*=fl0;
  // cast weights per family: thresholds on a hash give fish / octopus / puffer / star / bubble
  vec4 T=vec4(.5,.62,.76,.88)*fReef+vec4(1.01,1.02,1.03,1.04)*fSch+vec4(.72,.8,.92,1.01)*fWh+vec4(.18,.46,.7,.74)*fRise;
  // ---- v18 the big squid: one per staggered world cell, so zooming out shows a flock; it swims its own slow path
  float sqR0=floor(p.y/1.7+.5),sqX=1.2*(sqR0-2.*floor(sqR0*.5)),sqCi=floor((p.x-sqX)/2.4+.5),sqH=h21(vec2(sqCi,sqR0)+3.7);
  float sqVis=1.-gs,sqS=step(.5,fract(sqH*5.3))*2.-1.,famW=step(abs(fam-2.),.5)*step(abs(sqCi),.5)*step(abs(sqR0),.5);
  vec2 sqC=vec2(sqCi*2.4+sqX,sqR0*1.7+.035+.03*kick)+mix(vec2(.38*sin(mt*.31+sqH*TAU),.07*sin(mt*.47+sqH*9.)),vec2(sqS*(.62+.05*sin(mt*.31)),.06*sin(mt*.47)),famW);
  float sqR=max(.32*sqVis*(1.+.05*kick+.04*bsS),.001);
  mat2 sqM=rot(.2*sin(mt*.29+sqH*6.)+.06*sin(mt*.83)+.08*kick*sqS);
  vec2 sqQ=(sqM*(p-sqC))/sqR;
  float tL=-9.,tTy=0.,tRs=1.,tWag=0.,tFl=0.,tPh=0.,tPf=0.,tSa=0.,ink=0.,sh=0.,tdl=0.;
  vec2 tq=vec2(0.),tcw=vec2(0.);vec4 th=vec4(0.);
#if HD>=1
  for(int i=umZ;i<7+UM_X;i++){
    float L=float(i-umZ)-1.-float(UM_X),cl=c0*pow(gr,L),dirL=fract(L*.5)*4.-1.;
#else
  for(int i=0;i<7;i++){
    float L=float(i)-1.,cl=c0*pow(gr,L),dirL=fract(L*.5)*4.-1.;
#endif
    float hopL=dirL*(.1+.3*clamp(L/5.,0.,1.))*kick*(1.-gs);
    float fLane=fSch*step(.5,L),flip=dirL,J=cl,N=0.;
    vec2 u,v,id;
    if(fLane>.5){
      // lanes: every lane swims its own way (alternating) at its own speed, one stroke per beat
      float lh=.64,yy=p.y/cl+L*.37-hopL,j=floor(yy/lh+.5),dj=fract(j*.5)*4.-1.;
      float xx=p.x/cl-dj*sw*(.7+.3*fract(j*.618))*rate+j*.37,cx=floor(xx+.5);
      v=vec2(xx-cx,yy-j*lh);id=vec2(cx,j);flip=dj;u=vec2(0.);
    }else{
      if(fWh>.5){
        // whirlpool: log-polar rings; each ring swims round its own way and the rings drain slowly inward
        N=floor(6.*pow(gr,5.-L)+.5);
        u=vec2(pa/TAU*N-dirL*sw*.35*rate,(log(max(rr,1e-6))+tb*.03)*N/TAU);J=rr*TAU/N;
      }else{
        vec2 dv=mix(vec2(dirL*(.3+.05*L),0.),vec2(.06*dirL,-(.28+.07*L)),fRise);
        u=p/cl-dv*sw*rate+vec2(L*3.7,L*1.9);
      }
      u.y-=hopL;
      vec4 hc=floor(vec4(u,u-vec2(.5,.8660254))/vec2(1.,1.7320508).xyxy)+.5;
      vec2 a=u-hc.xy*vec2(1.,1.7320508),b=u-(hc.zw+.5)*vec2(1.,1.7320508);
      v=mix(b,a,step(dot(a,a),dot(b,b)));vec2 cc=u-v;
      id=floor(vec2(cc.x*2.,cc.y/.8660254)+.5);
      id.x=mix(id.x,mod(id.x,2.*max(N,1.)),fWh);
    }
    id-=256.*floor(id/256.);
    vec4 h=umiH(id,L+floor(vs*50.));
    h=mix(h,vec4(fract(id.y*.618+L*.31),fract(id.y*.377+L*.53)*.9,.6+.4*fract(id.y*.71),h.w),fLane*vec4(1.,step(.15,h.y),1.,0.));
    float ty=dot(step(T,h.yyyy),vec4(1.));
    float fish=step(ty,.5);
    float Rl=(.5+.08*fish)*(.74+.26*h.z)*mix(1.,.92,fLane);
    v-=(.5-Rl)*1.1*(h.zw-.5)*(1.-fLane);
    v.y+=fLane*.05*sin(TAU*(tb*.5+h.x));
    Rl*=(1.+.06*kick*clamp(L/5.,0.,1.)+.16*bsS*(1.-clamp(L/5.,0.,1.))+.2*lmA*clamp(1.-abs(L-3.)/1.6,0.,1.))*(1.+.22*uHit*step(3.5,ty)*step(ty,4.5));
    vec2 cw=p-mix(v*J,v*cl,fLane);
    // v18: the big characters step aside for the squid (continuous shrink as they drift near it), the small ones stay
    if(L>2.5){float sqP=umiSqP((sqM*(cw-sqC))/sqR)*sqR;Rl*=mix(1.,smoothstep(-.02,.06+Rl*J,sqP),sqVis);}
    if(L>3.5&&gs>.01){vec2 o2=cw*zm/.62+vec2(0.,-.12);
      float oP=min(umiEl(o2-vec2(0.,.24),vec2(.6,.54)),length(vec2(o2.x,o2.y-clamp(o2.y,-.8,0.)))-.72)*.62/zm;Rl*=mix(1.,smoothstep(-.02,.06+Rl*J,oP),gs);}
    Rl=max(Rl,1e-3);
    float Rs=Rl*J,Rp=Rs/px;
    float dl=length(cw)*.5;
    // turnaround event: the fish flip round like cards in a wave from the centre, and flip back
    float ta=eT*(clamp(evb*.7-dl*2.,0.,1.)-clamp(evb*.7-8.-dl*2.,0.,1.));
    float fx=cos(PI*smoothstep(0.,1.,ta));fx=sign(fx)*max(abs(fx),.08);
    float spin=dirL*TAU*smoothstep(0.,1.,1.-dfl); spin+=.13*sin(PI*tb+h.x*3.)*(.4+.6*kick);
    vec2 qv=rot(spin)*(v/Rl)*vec2(flip/fx,1.);
    float wag=.3*sin(TAU*(tb*2.*rate+h.z))+.12*sin(mt*3.+h.w*6.);
    float fl=fl0*(.6+.4*h.w)+.15*sin(mt*2.+h.x*6.);
    float ph=mt*2.5+h.z*6.,pf=clamp(kick*(.6+.6*h.w),0.,1.);
    float sa=dirL*(floor(tb*rate)+umiBack(fract(tb*rate)))*TAU/5.+h.z*TAU;
    float d=umiSil(qv,ty,wag,fl,ph,pf,sa)*Rs*min(abs(fx),1.);
    // density per layer; the back carpet never thins out: below a few pixels its characters swell into a mosaic
#if HD>=1
    float f0=step(float(i-umZ),.5);
#else
    float f0=step(float(i),.5);
#endif
    float dens=max(mix(mix(1.,.6,clamp(L/5.,0.,1.)),.97,fLane),f0);
    float pres=step(h.x,dens)*max(step(1.5,Rp),f0);d-=f0*(1.-smoothstep(1.5,4.,Rp))*Rs*1.5;
    d=mix(1e3,d,step(.5,pres));
    float w=min(max(.04*Rs,1.05*px),.3*Rs);
    if(d<0.){tL=L;tq=qv;tTy=ty;tRs=Rs;th=h;tdl=dl;tcw=cw;tWag=wag;tFl=fl;tPh=ph;tPf=pf;tSa=sa;ink=(1.-umiA(d+w,.7*px))*smoothstep(3.,9.,Rp);sh=0.;}
    else{ink=max(ink,clamp(.5-d/px,0.,1.)*smoothstep(3.,9.,Rp));sh=max(sh,umiA(d-.16*Rs,px)*smoothstep(6.,14.,Rp));}
  }
  // ---- whirlpool hero: an octopus sun at the centre whose eight arms are the eight bands (sub ... air, clockwise)
  float hero=0.,hk=0.;vec2 hq=vec2(0.);
  if(fWh>.5){
    float hr=max(.15*(1.+.08*kick)*(1.-gs),1e-3);hq=p/hr;
    float r=length(hq),ha=pa+tb*.12,k=floor(ha/(TAU/8.)+.5),aa=ha-k*TAU/8.;hk=mod(k,8.);
    float lv=dot(uB1,step(abs(vec4(hk)-vec4(0.,1.,2.,3.)),vec4(.5)))+dot(uB2,step(abs(vec4(hk)-vec4(4.,5.,6.,7.)),vec4(.5)));
    float tl=1.5+1.6*lv,y=r*aa-.22*sin(r*2.2-mt*3.+hk)*max(r-.9,0.);
    float dt=length(vec2(y,r-clamp(r,.6,tl)))-.26*(1.-.6*clamp((r-.8)/tl,0.,1.));
    float dh=min(r-1.,dt)*hr;
    if(dh<0.){hero=1.;tL=5.;tq=hq;tTy=5.;tRs=hr;th=vec4(.13,.5,.5,fract(vs*7.13));tdl=0.;ink=1.-umiA(dh+.012,.7*px);sh=0.;}
    else{ink=max(ink,clamp(.5-dh/px,0.,1.));sh=max(sh,umiA(dh-.03,px));}
  }
  // ---- colour the top shape once
  vec3 col;
#if HD>=1
  float gnd=step(tL,-8.5);
#else
  float gnd=step(tL,-5.);
#endif
  vec4 h=th,h2=fract(h.yzwx*13.17+h.x*3.1);
  float cs=csN+step(tdl*1.2+.02,ramp);
  // giant-octopus card stunt: every character inside it flips to its new colour at its own moment (staggered
  // outward with a white flash), holds while the octopus waves, winks and sings, then flips back
  vec2 mpos=mix(tcw,p,gnd);
  float dsg=length(mpos*zm)/.62,gj=mix(.6*h.y,.3,gnd),fi=clamp(evb-.5-1.6*dsg-gj,0.,1.),fo=clamp(evb-12.-1.6*dsg-gj,0.,1.);
  float gfx=eG*step(dsg,1.25)*(1.-hero)*(step(.5,fi)-step(.5,fo));
  float gfl=eG*step(dsg,1.25)*(max(0.,1.-abs(fi-.5)*5.)+max(0.,1.-abs(fo-.5)*5.));
  // macro structure: schools of giant smiling fish (and the giant octopus) are painted by recolouring the small
  // characters whose centres fall inside them, and the ground between them
  vec4 ov=vec4(0.);
  if(max(1.-fWh,gfx)*(1.-hero)>.5){
    vec3 G0=umiGq(mpos,gd,tr);vec2 mq=G0.xy;float gh=G0.z,gwag=.25*sin(mt*2.2+gh*6.);
    // inside tests only (no distances needed): body ellipse, wagging forked tail, dorsal fin
    float inB=step(length((mq-vec2(.15,0.))/vec2(.64,.46)),1.);
    vec2 gt=mq+vec2(-.05+.42,0.);gt.y-=gwag*gt.x;
    float ins=step(abs(gt.y),.07-gt.x*1.05)*step(-.52,gt.x)*step(gt.x,.1)*step((-gt.x-.36)*1.3,abs(gt.y))*(1.-inB);
    float inF=max(max(inB,ins),step(length((rot(.45)*(mq-vec2(.01,.4)))/vec2(.3,.13)),1.));
    // a giant clownfish-style body: one colour, two cream bands, contrasting tail and fin, a big eye
    vec3 fc=umiC(floor(gh*6.)+cs);
    fc=mix(fc,vec3(1.9,1.8,1.6),step(abs(abs(mq.x+.02)-.3),.07)*step(abs(mq.y),.5));
    fc=mix(fc,fc.brg,max(ins,step(.36,mq.y)*step(abs(mq.x+.04),.32)));
    // the event octopus: a screen-filling head and waving arms, cream eyes, pink cheeks, a singing mouth
    vec2 oq=mpos*zm/.62+vec2(0.,-.12);
    float inO=step(min(length((oq-vec2(0.,.24))/vec2(.6,.54))-1.,umiOctoT(oq,.4+.4*fl0,mt*2.).x),0.);
    vec2 of=(oq-vec2(0.,.22))/.42;
    float wk=step(of.x,0.)*smoothstep(6.5,7.5,evb)*(1.-smoothstep(9.,10.,evb));
    vec2 oe=(vec2(abs(of.x),of.y)-vec2(.36,.15))/vec2(.17,.24*(1.-max(uP5.w,wk)*.92)+.02);
    float omo=max(uP2.w,.7*kick);
    vec3 oc=umiC(cs+1.);
    float mw=step(gh,mix(.95,.6,smoothstep(.45,1.2,uZoom)));
    ov=mix(vec4(fc,inF*mw*mix(.75,1.,smoothstep(.65,.3,uZoom))),vec4(oc,1.),gfx*inO);
    ov.a*=step(.5,max(gfx*inO,1.-eG*step(dsg,1.25)*step(.5,fi)));
  }
  if(gnd>.5){
    // the ground: seigaiha, overlapping fans of concentric wave rings; every ring ripples outward one band per beat
    // and the colours flow diagonally; inside a giant fish (zoomed out, or the octopus) it takes the giant's colour
    vec2 g=p*sqrt(max(zm,.05))/.13+vec2(tr*.05*gd,0.);
    float gR=9.;vec2 gid=vec2(0.);
    for(int k=0;k<5;k++){float j=floor((g.y+1.)*2.)-float(k),xo=fract(j*.5)*2.;
      float cx=floor((g.x-xo)*.5+.5)*2.+xo,dd=length(g-vec2(cx,j*.5)),ins=step(dd,1.);gR=mix(gR,dd,ins);gid=mix(gid,vec2(cx,j),ins);}
    float gpx=px*sqrt(max(zm,.05))/.13,x=gR*4.-tb*.5,bi=floor(x);
    col=umiC(bi+gid.y*.5+gid.x*.25+cs)*(.52+.3*uB1.x+.25*uO1.x*step(abs(bi-floor(-tb*.5)-1.),.5));
    float gk=smoothstep(.35,.12,gpx*4.);
    col=mix(col,col*.25,umiA(.5-abs(fract(x)-.5)-.06,gpx*4.)*gk);
    col=mix(col,UMINK,umiA(1.-gR-.05,gpx)*gk);
#if HD>=1
    {float xf=gR*float(8+4*HD)-tb*.5,lf=abs(fract(xf)-.5);float k2=smoothstep(.2,.07,gpx*float(8+4*HD));
     col=mix(col,umiC(bi+gid.y*.5+2.)*.72,umiA(lf-.13,gpx*float(8+4*HD))*k2*.5);}
#endif
    col=mix(col,ov.rgb*.6,step(.5,ov.a)*mix(.6*smoothstep(.7,.3,uZoom),1.,gfx));
  }else{
    float ci=clamp(tL-1.,0.,3.),c1=step(.5,ci),c2=step(1.5,ci),c3=step(2.5,ci);
    float mo=mix(mix(uP2.x,uP2.y,c1),mix(uP2.z,uP2.w,c3),c2);
    mo=clamp(mo*(.6+.4*h2.x)+.3*bld,0.,1.);
    float tbl=fract(mt*.11+h2.y*7.);
    float bl=max(1.-smoothstep(0.,.012,abs(tbl-.5)),uP5.w);
    float on=mix(mix(uO2.w,uO1.y,c1),mix(uO2.y,max(uO2.x,uO1.w),c3),c2);
    float fl=1.+.7*on*(.5+.5*h2.y)+.25*dfl+1.2*gfl+.3*lmA*clamp(1.-abs(tL-3.)/1.6,0.,1.);
    float pq=px/tRs,lod=smoothstep(8.,17.,tRs/px),w=max(.04,1.3*pq),ik=smoothstep(.13,.07,pq);
    mo=mix(mo,clamp(uP2.w+.25*bld,0.,1.),hero);lod=max(lod,hero);fl=mix(fl,1.+.3*uO1.x,hero);
    float act=step(tdl*.45,evp)*(1.-step(.55+tdl*.45,evp));
    float eo=mix(mix(-1.,.6,hero),mix(.25,.1,step(2.5,ev)),act*step(.5,ev)*step(ev,3.5)*(1.-eT));
    vec3 base=mix(umiC(h.x*6.+cs),ov.rgb,min(ov.a,1.))*fl;
    vec3 acc=umiC(h.x*6.+cs+2.+floor(h2.w*3.))*fl,lite=mix(base,vec3(1.6,1.5,1.35)*fl,.45);
    vec2 q=tq,fq=q/.42;float sd=0.,fm=1.,fs=.42,sty=h2.w;
    if(tTy<.5){
      // fish: tail and fin in the accent colour with fan lines, body with stripes, scales or a belly, a big side eye
      float db=umiEl(q-vec2(.1,0.),vec2(.64,.46));
      vec2 t=rot(tWag)*(q+vec2(.42,0.));
      col=mix(acc,acc*.6,umiA(abs(fract(length(t)*7.)-.5)-.32,pq*7.)*lod)*(1.+.4*uB2.x+.25*uB2.y);
      col=mix(col,UMINK,ik*umiA(abs(db)-w*.5,pq));
      vec3 bc=base;
      float sx=abs(fract(q.x*2.3+.25)-.5)-.13-.07*lmA;          // the cream bands fatten with the chords
      bc=mix(bc,vec3(1.8,1.75,1.6)*fl,umiA(sx,pq*2.3)*step(sty,.34)*step(q.x,.45));
      bc=mix(bc,UMINK,umiA(abs(sx)-w*.6,pq*2.3)*step(sty,.34)*step(q.x,.45)*ik);
      float gy=q.y*6.5,row=floor(gy),gx=q.x*6.5+.5*row;
      float sc=abs(length(vec2(fract(gx)-.5,fract(gy)))-.5)/6.5;
      bc=mix(bc,mix(bc,acc,.7),umiA(sc-.012,pq)*step(.34,sty)*step(sty,.67)*step(q.x,.32)*lod);
      bc=mix(bc,lite,umiA(-q.y-.14+.06*q.x,pq)*.7*step(.34,sty));
      bc=mix(bc,vec3(1.7,1.65,1.5)*fl,umiA(length((q-vec2(-.1,.24))/vec2(.2,.07))-1.-.6*uB2.y,pq*5.)*.6*lod);
      // v20: a gill line and a pectoral fin that flaps on the kick
      {float ga=abs(length(q-vec2(.36,.02))-.34)-w*.35;bc=mix(bc,UMINK,umiA(ga,pq)*step(q.x,.1)*step(abs(q.y-.02),.2)*ik*lod);
       vec2 pv=rot(.75+.55*kick)*(q-vec2(.1,-.1));float dpf=length(vec2(pv.x+.12,abs(pv.y)+.11))-.163;
       bc=mix(bc,mix(acc,lite,.35),umiA(dpf,pq)*lod);bc=mix(bc,UMINK,umiA(abs(dpf)-w*.35,pq)*ik*lod);}
      col=mix(col,bc,umiA(db+w*.5,pq));
      fq=(q-vec2(.34,.04))/.36;fs=.36;sd=1.;fm=umiA(db+w,pq);
    }else if(tTy<1.5){
      // octopus: tentacles with cream suckers, a domed head with spots or stripes and a shine
      vec3 o=umiOctoT(q,tFl,tPh);
      float dh=umiEl(q-vec2(0.,.24),vec2(.6,.54));
      col=base*(.8+.36*uB2.x+.2*uB2.y);
      vec2 su=vec2(o.y,fract(o.z*6.)-.5);
      col=mix(col,vec3(1.7,1.55,1.35)*fl,umiA(length(su/vec2(1.,.9))-(.06+.05*htA)*(1.-.5*o.z),pq)*step(.25,o.z)*lod);
      col=mix(col,UMINK,ik*umiA(abs(dh)-w*.5,pq));
      vec3 hc=base;
      vec2 sp=(q-vec2(0.,.24))*5.;vec2 si=floor(sp+.5);
      hc=mix(hc,mix(hc,acc,.75),umiA((length(sp-si)-.22-.1*h21(si+h.zw))/5.,pq)*step(sty,.5)*step(q.y,.62)*lod);
      hc=mix(hc,acc,umiA(abs(fract(q.y*3.5)-.5)-.2,pq*3.5)*step(.5,sty)*step(q.y,.2)*lod);
      hc=mix(hc,vec3(1.8,1.75,1.65)*fl,umiA(length((q-vec2(-.24,.52))/vec2(.13,.08))-1.-.6*uB2.y,pq*7.)*lod);
      col=mix(col,hc,umiA(dh+w*.5,pq));
      fq=(q-vec2(0.,.12))/.4;fs=.4;fm=umiA(dh+w,pq);
    }else if(tTy<2.5){
      // pufferfish: spikes in the accent colour, creamy belly, spots, round face
      float r=length(q),db=r-.6-.08*tPf;
      col=mix(acc,acc*.55,umiA(-q.x-.7,pq))*(1.+.4*uB2.x+.25*uB2.y);
      col=mix(col,UMINK,ik*umiA(abs(db)-w*.5,pq));
      vec3 bc=mix(base,lite,umiA(-q.y-.22+.1*sin(q.x*9.),pq));
      vec2 sp=q*rot(.4)*6.;vec2 si=floor(sp+.5);
      bc=mix(bc,mix(bc,acc,.8),umiA((length(sp-si)-.16-.1*bsS)/6.,pq)*step(-.15,q.y)*lod);
      bc=mix(bc,vec3(1.8,1.75,1.65)*fl,umiA(length((q-vec2(-.25,.3))/vec2(.13,.07))-1.-.6*uB2.y,pq*7.)*lod);
      col=mix(col,bc,umiA(db+w*.5,pq));
      fq=q/.48;fs=.48;fm=umiA(db+w,pq);
    }else if(tTy<3.5){
      // starfish: lighter inner star, bumpy dots
      vec2 sq=rot(tSa)*q;float ks=1.6-.42*lmA,di=umiStar(sq*ks)/ks;   // the inner star swells with the chords, the bumps with the hats
      col=mix(base,lite,umiA(di,pq));
      col=mix(col,UMINK,umiA(abs(di)-w*.35,pq)*ik*.6);
      vec2 dp=sq*7.;vec2 di2=floor(dp+.5);
      col=mix(col,vec3(1.75,1.6,1.4)*fl,umiA((length(dp-di2)-.18-.14*htA)/7.,pq)*step(0.,di)*lod);
      fq=q/.36;fs=.36;
    }else if(tTy<4.5){
      // bubble: a glassy tinted disc with a ring, a curved shine and (sometimes) a tiny face
      float r=length(q);
      col=mix(mix(base,vec3(1.3,1.6,1.9),.35),mix(base,vec3(1.8,1.9,2.),.6),umiA(abs(r-.62)-.06,pq));
      col=mix(col,vec3(2.2,2.2,2.1)*(1.+.8*uO2.z),umiA(max(abs(r-.48)-.05,q.x+q.y-.1),pq)*umiA(-q.y-q.x*.2-.05,pq)*lod);
      col=mix(col,vec3(2.1,2.1,2.),umiA(abs(r-.62+.34*uHit)-.02-.05*uHit,pq)*min(uHit*1.5,1.));   // v20: every snare pops the bubbles (they swell, a white ring runs out)
      fq=q/.32;fs=.32;fm=step(h2.z,.45);
    }else{
      // octopus sun: arms in alternating colours with suckers (each arm brightens with its band onset), big face
      float r=length(tq),onk=dot(uO1,step(abs(vec4(hk)-vec4(0.,1.,2.,3.)),vec4(.5)))+dot(uO2,step(abs(vec4(hk)-vec4(4.,5.,6.,7.)),vec4(.5)));
      col=umiC(hk+cs)*(1.+.8*onk);
      col=mix(col,vec3(1.8,1.6,1.4),umiA(abs(fract(r*2.5)-.5)-.18,pq*2.5)*step(1.1,r)*.6);
      col=mix(col,UMINK,umiA(abs(r-1.)-w*.6,pq));
      col=mix(col,mix(base.brg,vec3(1.9,1.8,1.6),.25)*(1.+.25*uO1.x),umiA(r-1.+w*.6,pq));
      fq=tq/.82;fs=.82;fm=umiA(r-1.,pq);
    }
    // v13 zoom-in ornament: a fine print that only resolves on big characters (from ~55 px radius, full at ~110 px, so
    // zooming in reveals it): fish get a net of tiny scales, the others rings of seed dots
    // (v20: each character wears one of four prints, chosen by its hash, and they show from a little smaller)
    float mz=smoothstep(44.,90.,tRs/px)*(1.-hero),pk=floor(h2.z*4.);
    if(mz>.002){
      float fsh=step(tTy,.5),prn=umiPrint(q,pk,15.);
      if(pk<.5)prn=mix(length(fract(q*vec2(13.,11.)+vec2(.5*floor(q.y*11.),0.))-.5)/13.-.011,prn,fsh);
      col=mix(col,mix(col*1.35+acc*.18,col*.55+acc*.3,fsh),umiA(prn,pq)*mz*.8);
    }
#if HD>=1
    if(hero<.5){ // v19 print work on every body, from a size where it resolves: a screentone in the accent colour on the shadow side, a finer scale or seed net, a hem line
      float Rpx=tRs/px;
      float st=smoothstep(10.,22.,Rpx);
      if(st>.002){
        float dq=18.+float(HD)*5.;vec2 tg=rot(.6)*q*dq;vec2 ti=floor(tg+.5);float shade=clamp(.5-q.y*.9-q.x*.25,0.,1.);
        float td=(length(tg-ti)-.46*sqrt(shade))/dq;
        vec3 dc=col*col/max(max(col.r,max(col.g,col.b)),.05);col=mix(col,dc*.8,umiA(td,pq)*.6*st*step(.12,shade));
      }
      float ng=smoothstep(24.,48.,Rpx);
      if(ng>.002){
        float gn=26.+float(HD)*8.,scl=umiPrint(q,mod(pk+1.,4.),gn)-.002;
        vec3 dn=col*col/max(max(col.r,max(col.g,col.b)),.05);col=mix(col,mix(dn*.7,acc*.8,.25),umiA(scl,pq)*ng*.5*step(tTy,2.5));
      }
#if HD>=3
      float mg=smoothstep(40.,80.,Rpx);
      if(mg>.002){float gm=60.+float(HD)*14.;vec2 g=q*gm,gi=floor(g+.5);float dd=(length(g-gi)-.2)/gm;col=mix(col,mix(col,base*1.25,.6),umiA(dd,pq)*mg*.45*step(.5,mod(gi.x+gi.y,2.)));}
#endif
    }
#endif
    col=mix(col,umiFace(col,fq,pq/fs,max(mo,step(0.,eo)*step(eo,.2)*(.3+.6*max(uP2.w,kick))),bl,brk,h,lod,eo,sd),fm);
    // v13 zoomed out: characters smaller than a few pixels take the colour of broad rainbow currents (chosen by their
    // own centre, so the current is a mosaic of whole characters), keeping their own light: the confetti becomes
    // flowing bands with the giant fish swimming over them. Cross-fades in from zoom .75 to .35.
    {float cz=max((1.-smoothstep(2.5,7.,tRs/px))*smoothstep(.75,.35,uZoom),(1.-smoothstep(3.,12.,tRs/px))*smoothstep(.5,.2,uZoom));
     vec2 cm=mpos*.42;float cu=cm.y+.6*sin(cm.x*.8+.3*sin(cm.y*1.3)+mt*.15)-tb*.0625;
     vec3 cc=umiC(floor(cu)+cs)*clamp(dot(col,vec3(.3,.5,.2))/max(dot(base,vec3(.3,.5,.2)),.05),.55,1.3);
     col=mix(col,cc,cz*.85);}
    // a sub-pixel carpet melts into the giant fishes' colours instead of shimmering
    col=mix(col,mix(col,ov.rgb*.8,min(ov.a,1.)),(1.-smoothstep(2.,5.,tRs/px))*step(tL,.5));
    // zoomed out (or inside the giant octopus) the whole character takes the giant's colour, keeping its own light and ink
    col=mix(col,ov.rgb*clamp(dot(col,vec3(.3,.5,.2))/max(dot(base,vec3(.3,.5,.2)),.05),.45,1.35),min(ov.a,1.)*max(smoothstep(.75,.3,uZoom)*.85,gfx*.8));
    col*=mix(mix(.92,1.,clamp(tL/3.,0.,1.)),1.,gfx);
  }
  col*=1.-.2*sh;
  // back-layer ink is a deep tint of the character colour (crisp but never a black net); front ink stays black
  col=mix(col,mix(col*.5,UMINK,max(gnd,smoothstep(14.,34.,tRs/px))),ink);
  // whirlpool rim: a rainbow wave ring around the vortex
  float wx=(dW+.06)/.024,wOn=step(rr,2.3)*step(abs(fam-2.),.5),wp=step(uP3.x,5.),xw=(eW+.11)/.022;
  vec3 bandC=umiC(floor(mix(wx,xw,wp))+cs);
  col=mix(col,bandC*1.3,umiA(abs(wx-2.5)-2.5,px/.024)*wOn);
  col=mix(col,UMINK,umiA(abs(fract(wx+.5)-.5)-.06,px/.024)*step(abs(wx-2.5),3.)*wOn);
  // ---- v20 pulled back, the giant fish are drawn, not only implied: everything inside a giant's ink line keeps its own character and light but takes the
  // giant's colours (as with the squid); cream bands, a contrasting tail and fin, a keyline, a big eye that blinks with the sea and a mouth that sings the lead
  {float zo2=smoothstep(.72,.45,uZoom)*(1.-gs)*(1.-fWh);
   if(zo2>.01){
     vec3 G=umiGq(p,gd,tr);vec2 mq=G.xy;float gh=G.z,gA=zo2*step(gh,mix(.95,.6,smoothstep(.45,1.2,uZoom)));
     float dG=umiFish(mq-vec2(.05,0.),.25*sin(mt*2.2+gh*6.))*1.056;
     if(gA>.01&&dG<.1){
       float ol=max(.014,1.7*px),stk=max(.011,1.4*px),lum=clamp(dot(col,vec3(.3,.5,.2))/.42,.1,1.35),U=1.056;
       vec3 fc=umiC(floor(gh*6.)+cs);fc=mix(fc,umiC(floor(gh*6.)+cs+1.+floor(th.y*2.)),step(.6,th.x)*.7);
       float dB=umiEl(mq-vec2(.15,0.),vec2(.64,.46))*U,bd=(abs(abs(mq.x+.02)-.3)-.07)*U;
       vec3 bc=mix(fc.brg,mix(fc,vec3(1.9,1.8,1.6),umiA(bd,px)),umiA(dB,px));
       col=mix(col,vec3(1.9,1.85,1.7),umiA(abs(dG-ol-stk*.5)-stk*.5,px)*gA);
       col=mix(col,bc*lum*(1.+.2*kick),umiA(dG,px)*gA*.5);
#if HD>=1
       col=mix(col,col*.62,umiA(umiPrint(mq,0.,9.)*U,px)*umiA(dB+.03,px)*step(mq.x,.2)*gA*.55);   // Native and up: the giant wears a net of scales
#endif
       col=mix(col,UMINK,max(umiA(abs(dG+ol*.5)-ol*.5,px),max(umiA(abs(dB)-ol*.35,px),umiA(abs(bd)-ol*.3,px)*umiA(dB,px))*umiA(dG,px))*gA);
       vec2 ef=(mq-vec2(.4,.1))/.15;float eu=.15*U,blk=1.-uP5.w*.92,mo=uP2.w;
       float dE=(length(ef/vec2(1.25,1.25*blk+.05))-1.)*1.25*eu,dP=(length((ef-vec2(.2,0.))/vec2(.66,.86*blk+.03))-1.)*.66*eu;
       col=mix(col,vec3(1.95,1.9,1.8),umiA(dE,px)*gA);col=mix(col,UMINK,max(umiA(abs(dE)-ol*.5,px),umiA(dP,px))*gA);
       col=mix(col,vec3(2.1),max(umiA((length(ef-vec2(.42,.36))-.24)*eu,px),umiA((length(ef-vec2(-.02,-.34))-.11)*eu,px))*step(.3,blk)*gA);
       col=mix(col,mix(col,vec3(1.9,.35,.5),.65),umiA((length((mq-vec2(.36,-.2))/vec2(.1,.06))-1.)*.06*U,px)*gA);
       float dM=umiEl(mq-vec2(.68,-.13),vec2(.05+.02*mo,.02+.1*mo))*U;
       col=mix(col,vec3(1.5,.05,.14),umiA(dM,px)*gA);col=mix(col,UMINK,umiA(abs(dM)-ol*.35,px)*gA);
     }
   }}
  // ---- v18 the big squid, painted into the sea: everything inside its ink line keeps its own character (ink, faces,
  // light) but takes the squid's colours, so its body is a crowd of little characters. Kick pumps the mantle and flares
  // the arms, the chords swing the arms, hats light the photophores, the lead sings through its mouth.
  if(sqVis>.01){
    vec4 sa=umiSquid(sqQ,kick,mt*2.2+sqH*6.,lmA,bsS);
    float dS=sa.x*sqR,qpx=px/sqR;
    if(dS<.05){
      float bA=umiA(dS,px),ol=max(.008,1.8*px),lum=clamp(dot(col,vec3(.3,.5,.2))/.42,.08,1.4);
      float stk=max(.009,1.6*px);
      float arm=step(.001,sa.y),hu=floor(sqH*6.);
      lum=mix(lum,1.,.72*arm);
      float band=step(.5,fract(sqQ.y*1.55+.1*sin(sqQ.x*6.+mt)));
      vec3 c1=umiC(hu+cs),c2=umiC(hu+cs+2.),bc=mix(mix(c1,c2,band),mix(c2,c1,.25+.5*band),arm);
      bc=mix(bc,umiC(hu+cs+1.+floor(th.y*2.)),step(.62,th.x)*.75);
      vec3 sc=bc*lum*(1.08+.3*kick+.25*uO1.x);
      float su=umiA(length(vec2(sa.z*9.,fract(sa.y*7.)-.5))-.16,qpx*9.)*arm*step(.28,sa.y);
      sc=mix(sc,vec3(1.8,1.6,1.4),su*.9);
      vec2 pg=sqQ*8.;vec2 pi2=floor(pg+.5);float phA=step(.5,length(sqQ-vec2(0.,.25)))*(1.-arm);
      float pr=.08+.26*max(htA,max(uO2.z,uO2.w));
      sc=mix(sc,mix(vec3(2.1,2.,1.7),c2*2.,.35),umiA((length(pg-pi2)-pr)/8.,qpx)*phA*step(mod(pi2.x+pi2.y,2.),.5));
#if HD>=1
      {float cn=30.+6.*float(HD);vec2 cg=sqQ*cn;vec2 ci=floor(cg+.5);float chh=h21(ci+sqH*17.),cr=.16+.3*chh*(.45+.55*max(kick,uO1.x));
       float cd2=(length(cg-ci-(vec2(chh,fract(chh*7.))-.5)*.4)-cr)/cn;
       sc=mix(sc,mix(c1,c2,step(.5,fract(chh*5.)))*(.7+.6*lum),umiA(cd2,qpx)*.62*(1.-.7*arm)*smoothstep(.0,.12,1.-qpx*cn*.8));
       float rg=abs(fract(sa.y*18.)-.5)/18.;sc=mix(sc,sc*.6,umiA(rg-.006,qpx)*arm*.55);}
#endif
      col=mix(col,mix(vec3(1.9,1.85,1.7),c2*1.7,.65),umiA(abs(dS-ol-stk*.5)-stk*.5,px));
      sc=max(mix(vec3(dot(sc,vec3(.2126,.7152,.0722))),sc,1.22),0.);
      col=mix(col,sc,bA*.94);
      col=mix(col,UMINK,umiA(abs(dS+ol*.5)-ol*.5,px));
      col=mix(col,vec3(2.,1.95,1.8),umiA(length((sqQ-vec2(-.26,.66))/vec2(.17,.07))-1.,qpx/.17)*.75*(1.-arm)*bA);
      vec2 fq=(sqQ-vec2(0.,.25))/.72;float fpx=qpx/.72;
      vec2 ee=vec2(abs(fq.x)-.36,fq.y-.14);float sE=length(ee/vec2(.27,.34))-1.;
      float opS=(1.-uP5.w)*(1.-brk);
      col=mix(col,vec3(1.9,1.85,1.75),umiA(sE*.27,fpx)*bA*opS);
      col=mix(col,UMINK,umiA(abs(sE*.27)-max(.012,fpx),fpx)*bA*opS);
      float eoS=mix(mix(.6,.25,step(abs(ev-1.),.5)),.1,step(abs(ev-3.),.5));
      float moS=clamp(max(uP2.w,.55*kick)+.3*bld,0.,1.);
      col=mix(col,umiFace(col,fq,fpx,moS,uP5.w,brk,vec4(.5,.5,.5,.8),1.,eoS,0.),bA*umiA(length(fq)-1.3,fpx));
    }
  }
  // v18 joy: hearts drift up off the squid in a stream, one column per squid, pumped by the kick, in the squid's colours
  if(sqVis>.01){
    float hy=sqQ.y+tb*.3,hc=floor(hy/.62+.5),hs=hy-hc*.62;
    float hrise=clamp((sqQ.y+.35)/1.5,0.,1.),hA=step(abs(abs(sqQ.x)-1.08),.3)*step(-.35,sqQ.y)*(1.-smoothstep(.75,1.,hrise))*step(.15,fract(hc*.37+sqH));
    if(hA>.001){
      float hx=abs(sqQ.x)-1.08-.09*sin(hc*2.4+mt*1.2)*(1.+hrise),hz=.2*(.7+.3*sin(hc*1.7))*(1.+.35*kick);
      float dH=umiHeart(vec2(hx,hs+.05)/hz)*hz*sqR,hsc=hz*sqR;
      col=mix(col,UMINK,umiA(dH-.14*hsc,px)*hA);
      col=mix(col,umiC(floor(sqH*6.)+cs+1.)*(1.4+.5*uO1.x),umiA(dH+.02*hsc,px)*hA);
      col=mix(col,vec3(2.,1.9,1.9),umiA(length(vec2(hx+.07,hs-.1)/hz*1.6)/1.6-.13,px/hz/sqR)*hA);
    }
  }
  // v18 giant octopus: its eyes were coarse black mosaics of characters; paint them crisp, white backed, on the same screen spot
  if(eG>.5){
    float eyA=smoothstep(1.,3.,evb)*(1.-smoothstep(12.,13.5,evb));
    {vec2 oq=p*zm/.62+vec2(0.,-.12);vec3 oT=umiOctoT(oq,.4+.4*fl0,mt*2.);float U=.62/zm;
     float dHd=umiEl(oq-vec2(0.,.24),vec2(.6,.54))*U,dAr=oT.x*U,dO=min(dHd,dAr);
     if(dO<.1*U){
       float ol=max(.016*U,1.8*px),stk=max(.014*U,1.5*px),lum=clamp(dot(col,vec3(.3,.5,.2))/.42,.1,1.35),arm=step(dAr,dHd)*step(0.,dHd);
       vec3 c1=umiC(cs+1.),c2=c1.gbr,oc=mix(c1,mix(c2,c1,step(.5,fract(oT.z*3.2-.1+.5*floor(oq.x/(.29*(1.+.6*clamp(-oq.y,0.,1.)))+2.)))),arm);oc=mix(oc,umiC(cs+2.+floor(th.y*2.)),step(.6,th.x)*.7);
       float su=umiA(length(vec2(oT.y,(fract(oT.z*6.4)-.5)/6.4))-.03,px/U)*arm*step(.2,oT.z);
       oc=mix(oc*lum*(1.05+.25*kick+.2*uO1.x),vec3(1.8,1.6,1.4),su*.9);
       col=mix(col,vec3(1.9,1.85,1.7),umiA(abs(dO-ol-stk*.5)-stk*.5,px)*eyA);
       col=mix(col,oc,umiA(dO,px)*eyA*.88);
       col=mix(col,UMINK,max(umiA(abs(dO+ol*.5)-ol*.5,px),umiA(abs(dHd)-ol*.4,px)*umiA(dAr,px))*eyA);
       col=mix(col,vec3(2.,1.95,1.8),umiA(length((oq-vec2(-.26,.6))/vec2(.16,.07))-1.,px/U/.07)*.75*eyA);
       vec2 of=(oq-vec2(0.,.22))/.42;float omo=max(uP2.w,.7*kick),fu=.42*U;
       float dCk=(length((vec2(abs(of.x),of.y)-vec2(.62,-.1))/vec2(.16,.1))-1.)*.1*fu;
       col=mix(col,vec3(2.,.5,.7),umiA(dCk,px)*eyA);
       float dMo=umiEl(of-vec2(0.,-.33),vec2(.14+.08*omo,.05+.22*omo))*fu;
       col=mix(col,mix(vec3(.6,.02,.08),vec3(1.7,.45,.55),umiA((length(of-vec2(0.,-.4-.17*omo))-.1-.06*omo)*fu,px)),umiA(dMo,px)*eyA);
       col=mix(col,UMINK,umiA(abs(dMo)-ol*.4,px)*eyA);
     }}
    vec2 ofE=(p*zm/.62+vec2(0.,-.12)-vec2(0.,.22))/.42,eeE=vec2(abs(ofE.x)-.36,ofE.y-.15);
    float wkE=step(ofE.x,0.)*smoothstep(6.5,7.5,evb)*(1.-smoothstep(9.,10.,evb));
    float opE=1.-max(uP5.w,wkE)*.94,pxE=px*zm/(.62*.42);
    float dS2=(length(eeE/vec2(.27,.36*opE+.02))-1.)*.27,dPu=length((eeE-vec2(.03*sin(mt*.9),-.02))/vec2(.15,.22*opE+.015))-1.;
    col=mix(col,vec3(1.95,1.9,1.8),umiA(dS2,pxE)*eyA);
    col=mix(col,UMINK,umiA(abs(dS2)-.025,pxE)*eyA);
    col=mix(col,UMINK,umiA(dPu*.15,pxE)*eyA);
    col=mix(col,vec3(2.1),umiA(length((eeE-vec2(.08,.1))/vec2(1.,1.2))-.05,pxE)*step(.3,opE)*eyA);
    col=mix(col,vec3(2.1),umiA(length(eeE-vec2(-.07,-.08))-.025,pxE)*step(.3,opE)*eyA);
  }
  // ---- v13 air / hats: sunlight caustics, a rippling web of light over the whole sea; brightness = air level and hat
  // activity (light only: it lifts the colour underneath, its strongest channel most, so hue and saturation stay)
  {float ca=clamp(aiA*1.5,0.,1.);
   if(ca>.01){vec2 cq=p0*mix(4.,7.,smoothstep(1.,.3,uZoom))+vec2(.15*mt,.1*mt);
     float cv=sin(cq.x*1.9+1.5*sin(cq.y*1.3+mt*.7))+sin(cq.y*2.1+1.5*sin(cq.x*1.2-mt*.6));
     float cl=clamp(1.-abs(cv)*3.,0.,1.);col+=1.1*ca*cl*cl*col*col/max(max(col.r,max(col.g,col.b)),.05);}}
  // ---- hat glints: four-point sparkles pop over the water on the hats / air onsets
  {
    vec2 sg=p0*7.;vec2 si=floor(sg);vec2 sf=sg-si-.5;vec4 sh4=fract(h21(si+floor(tb*2.)*7.13)*vec4(1.,13.7,71.3,313.1));
    sf-=(sh4.xy-.5)*.5;
    float sz=(.16+.26*sh4.z)*clamp(htA*1.3+uO2.w+uB2.w,0.,1.)*step(.45-.15*uB2.w,sh4.w)*(.75+.25*sin(uTime*7.+sh4.z*40.));
    vec2 aq=abs(sf);float ds=(aq.x*aq.y*30.+max(aq.x,aq.y)-sz*.75)/7.;
    col=mix(col,mix(umiC(floor(sh4.z*6.))*2.2,vec3(2.2,2.1,1.8),clamp(1.-3.*max(aq.x,aq.y)/(sz*.75+1e-3),0.,1.)),umiA(ds,1./uRes.y)*step(.001,sz));
  }
  // ---- drop / phrase wipe: a rainbow wave front with a foam crest rolls across the screen, the new sea behind it
  if(uP3.x<5.){
    float x=xw,pw=1./(uRes.y*.022);
    col=mix(col,bandC*1.5,umiA(abs(x-2.5)-2.5,pw));
    col=mix(col,UMINK,umiA(abs(fract(x+.5)-.5)-.05,pw)*step(abs(x-2.5),3.));
    vec2 fo2=vec2(eW-.035,(fract(p0.y*9.+mt*.6)-.5)/9.);float dfo=length(fo2)-.034-.012*sin(p0.y*40.);
    col=mix(col,UMINK,umiA(dfo-.008,1./uRes.y));
    col=mix(col,vec3(2.1,2.15,2.2),umiA(dfo,1./uRes.y));
  }
  // v14: a touch more chroma so the added light (caustics, chord lift) never pales the sea
  col=mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.08);
#if HD>=1
  return max(col,0.);
}
void realm(){
  umZ=min(int(uTime),0);
  vec2 p0=scr();vec3 acc=vec3(0.);
  for(int s=umZ;s<UM_AA;s++){
    float fs=float(s-umZ);
    vec2 j=fs<.5?vec2(0.):(vec2(fract(fs*.7548777),fract(fs*.5698403))-.5);
    acc+=min(umiPic(p0+j/uRes.y),vec3(12.));
  }
  acc/=float(UM_AA);acc=max(mix(vec3(dot(acc,vec3(.2126,.7152,.0722))),acc,1.04),0.)*1.05;
  fragColor=vec4(acc,0.);
}
#else
  fragColor=vec4(max(col,0.),0.);
}
#endif
`;
