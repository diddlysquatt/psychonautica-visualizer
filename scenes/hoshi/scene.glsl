const R_HOSHI = `
// HOSHI 88: a superflat smiling cosmos. Original kawaii space characters (ringed planets with banded bodies, chubby
// layered stars, ray-crowned suns, rainbow-tailed comets, porthole rockets) with crisp ink outlines and glossy eyes.
// Unlike SOL / UMI (flat parallax packing) the cosmos has real depth: characters are depth-sorted billboards.
// Families: ORRERY (a tilted solar system: every orbit is a rainbow conveyor belt carrying tiny star-folk, planets
// step one slot per beat, alternate orbits counter-rotate, the front half of each orbit passes in front of a singing
// spectrum sun), GALAXY (a more face-on spiral: every orbit turns the same way with Kepler speeds through rigidly
// turning colour arms, a star-faced core), PARADE (perspective rows on a cosmic checker floor marching left/right in
// alternate rows toward a giant spectrum sun sinking on the horizon). Orbit / row k sings band k mod 8 (orbit 0 = sub).
// Zoomed out, giant smiling ringed planets made of hundreds of characters float over the system.
// uP1 [trav beats (+build extra), mt, kick env, snare flash]   uP2 mouths [air, harmony, low lead, lead vocal]
// uP3 [wipe radius, build, breakdown, drop flash]   uP4 [famA, vsA, event+progress, colour shift]
// uP5 [famB, vsB, trav, bar blink]   uM1, uM2: the six palette colours (linear)
vec3 hoC(float i){float k=floor(i+.5);k-=6.*floor(k/6.);
  return uM1*clamp(1.-abs(k-vec3(0.,1.,2.)),0.,1.)+uM2*clamp(1.-abs(k-vec3(3.,4.,5.)),0.,1.);}
const vec3 HOINK=vec3(.014,.006,.04);
const vec3 HOCR=vec3(1.95,1.85,1.65);
float hoAt(float y,float x){float ax=abs(x),ay=abs(y),t=min(ax,ay)/max(max(ax,ay),1e-20),s=t*t;
  float r=((-.0464964749*s+.15931422)*s-.327622764)*s*t+t;r=mix(r,1.5707963-r,step(ax,ay));r=mix(r,3.1415927-r,step(x,0.));return r-2.*r*step(y,0.);}
vec4 hoH(vec2 id,float L){return fract(sin(vec4(dot(id,vec2(127.1,311.7)),dot(id,vec2(269.5,183.3)),dot(id,vec2(419.2,371.9)),dot(id,vec2(113.5,271.9)))+L*7.31)*43758.545);}
float hoEl(vec2 p,vec2 ab){float k0=length(p/ab),k1=length(p/(ab*ab));return k0*(k0-1.)/max(k1,1e-5);}
float hoA(float d,float e){return clamp(.5-.5*d/e,0.,1.);}
float hoBack(float x){x=min(x/.42,1.)-1.;return 1.+2.70158*x*x*x+1.70158*x*x;}
float hoBand(float b){return dot(uB1,step(abs(vec4(b)-vec4(0.,1.,2.,3.)),vec4(.5)))+dot(uB2,step(abs(vec4(b)-vec4(4.,5.,6.,7.)),vec4(.5)));}
float hoOn(float b){return dot(uO1,step(abs(vec4(b)-vec4(0.,1.,2.,3.)),vec4(.5)))+dot(uO2,step(abs(vec4(b)-vec4(4.,5.,6.,7.)),vec4(.5)));}
// five-point star pointing up, outer radius r, inner ratio rf
float hoStar(vec2 p,float r,float rf){
  const vec2 k1=vec2(.809016994,-.587785252),k2=vec2(-.809016994,-.587785252);
  p.x=abs(p.x);p-=2.*max(dot(k1,p),0.)*k1;p-=2.*max(dot(k2,p),0.)*k2;p.x=abs(p.x);p.y-=r;
  vec2 ba=rf*vec2(-k1.y,k1.x)-vec2(0.,1.);float h=clamp(dot(p,ba)/dot(ba,ba),0.,r);
  return length(p-ba*h)*sign(p.y*ba.x-p.x*ba.y);
}
// tapered capsule along +y from radius r1 at 0 to r2 at h
float hoUCap(vec2 p,float r1,float r2,float h){
  p.x=abs(p.x);float b=(r1-r2)/h,a=sqrt(max(1.-b*b,0.)),k=dot(p,vec2(-b,a));
  return mix(mix(dot(p,vec2(a,b))-r1,length(p-vec2(0.,h))-r2,step(a*h,k)),length(p)-r1,step(k,0.));
}
// nearest point of a hex lattice (neighbour distance 1): xy = offset, zw = id
vec4 hoHex(vec2 u){vec4 hc=floor(vec4(u,u-vec2(.5,.8660254))/vec2(1.,1.7320508).xyxy)+.5;
  vec2 a=u-hc.xy*vec2(1.,1.7320508),b=u-(hc.zw+.5)*vec2(1.,1.7320508),v=mix(b,a,step(dot(a,a),dot(b,b)));
  return vec4(v,floor(vec2((u-v).x*2.,(u-v).y/.8660254)+.5));}
float hoHeart(vec2 p){p.x=abs(p.x);vec2 q=p-.5*max(p.x+p.y,0.);
  return mix(sqrt(min(dot(p-vec2(0.,1.),p-vec2(0.,1.)),dot(q,q)))*sign(p.x-p.y),length(p-vec2(.25,.75))-.35355,step(1.,p.y+p.x));}
// a planet's tilted ring (annulus of an ellipse), gradient-corrected distance
float hoRingD(vec2 q,float a){vec2 rq=rot(a)*q;float e=length(rq/vec2(1.,.3)),g=length(vec2(rq.x,rq.y/.09))/max(e,1e-4);
  return (abs(e-.86)-.13)/max(g,.3);}
#if HD>=1
#define HG .5
#else
#define HG 1.
#endif
#if HD>=1
float notchF(float z,float tb){return (step(.5,z)*2.-1.)*tb*TAU/5.+z*TAU;}
#endif
float hoSunD(vec2 q,float n,float ln){float r=length(q),t=1.-2.*abs(fract(hoAt(q.y,q.x)*n/TAU+.5)-.5);
  return min(r-.56,(r-.6-ln*t)*mix(.5,.45,step(.5,ln)));}
// unit silhouettes (movers face +x): 0 ringed planet, 1 star, 2 sun, 3 comet, 4 rocket
float hoSil(vec2 q,float ty,float rg,float sa,float aux,float nr,float ln){
  float d=min(length(q)-.6,mix(1e3,hoRingD(q,sa),rg));
  d=mix(d,hoStar(rot(sa)*q,.95,.5)-.08,step(.5,ty));
  d=mix(d,hoSunD(q,nr,ln),step(1.5,ty));
  vec2 tq=vec2(q.y-.06*sin(q.x*5.-uP1.y*4.)*(.32-q.x),.32-q.x);
  d=mix(d,min(length(q-vec2(.32,0.))-.5,hoUCap(tq,.44,.07,1.3)),step(2.5,ty));
  vec2 f=rot(-.7)*vec2(q.x+.42,abs(q.y)-.3);
  float rk=min(min(hoEl(q-vec2(.06,0.),vec2(.8,.36)),hoEl(f,vec2(.26,.12))),hoEl(q-vec2(-.78-.12*aux,0.),vec2(.24+.14*aux,.15)));
  d=mix(d,rk,step(3.5,ty));
  // v18 saucer: dome, disc and a tractor beam that the bass pumps longer
  float us=min(min(length(q-vec2(0.,.2))-.33,hoEl(q-vec2(0.,-.1),vec2(.98,.34))),max(abs(q.x)-(.22-(q.y+.2)*.5),max(q.y+.2,-q.y-.45-.5*aux)));
  return mix(d,us,step(5.5,ty));
}
// kawaii face in face units: big glossy eyes with two glints, happy closed arcs (singing / sleepy), heart eyes,
// star eyes, a wink; cheeks; a smile that opens into a round singing "o" with a tongue
vec3 hoFace(vec3 col,vec2 f,float pf,float mo,float bl,float slp,vec4 h,float lod,float eo){
  float lw=max(.075,1.25*pf),ex=mix(fract(h.w*7.77+h.y*3.1),eo,step(0.,eo)),op=(1.-bl)*(1.-slp);
  float happy=max(step(ex,.16),step(.5,slp)),star=(1.-happy)*step(ex,.36)*step(.15,op),cl=max(happy,step(op,.15));
  col=mix(col,mix(col,vec3(1.9,.35,.6),.62),hoA(length(vec2(abs(f.x)-.58,f.y+.2)/vec2(.17,.11))-1.,pf)*step(.2,h.w)*lod);
  vec2 e=vec2(abs(f.x)-.34,f.y-.14)-vec2(sin(uP1.y*.9+h.y*6.),cos(uP1.y*.7+h.z*6.))*.05*(1.-slp);
  vec2 ea=vec2(abs(f.x)-.34,f.y-.08);
  // one eye distance: glossy oval, happy closed arc (singing / sleepy) or a star eye (events)
  float dE=mix(mix((length(e/vec2(.14,.2*max(op,.08)))-1.)*.14,max(abs(length(ea)-.13)-lw*.5,-ea.y),cl),hoStar(e,.22,.5)-.025-lw*.6,star);
  col=mix(col,HOINK,hoA(dE,pf)*lod);
  col=mix(col,vec3(2.2,1.8,.25)*(1.+.6*uO2.y),hoA(dE+lw*.6,pf)*star*lod);
  col=mix(col,vec3(1.6),hoA(length(e-vec2(.045,.08))-.055,pf)*step(.3,op)*(1.-cl)*(1.-star)*lod);
  // mouth: a closed smile, or a round singing "o" with a tongue
  vec2 m=vec2(f.x,f.y+.3);
  float om=smoothstep(.1,.25,mo),ry=.03+.25*mo,dm=hoEl(m,vec2(.13+.09*mo,ry));
  col=mix(col,mix(vec3(.6,.02,.08),vec3(1.7,.4,.55),hoA(length(m-vec2(0.,-ry*.7))-ry*.55,pf)),hoA(dm,pf)*om*lod);
  col=mix(col,HOINK,hoA(mix(max(abs(length(m-vec2(0.,.2))-.24)-lw*.5,m.y-.12),abs(dm)-lw*.5,om),pf)*lod);
  return col;
}
#if HD>=1
// V19 DETAIL RANGE (Native and up; HD 0 never sees any of this)
// Per-frame scene values the shadow generator needs (a second, shading-free pass over the same billboards)
float gRho0,gSp,gTilt,gYh,gH,gRw,gLg,gZ0,gSw,gTb,gTr,gRate,gGd,gFGal,gFPar,gVsI,gKick,gBsS,gSnE,gBrk,gEBig,gPx,gRh;
vec4 gT,gBE;vec2 gSc;
// is world point p under a character standing above depth zT? 1 = covered. Same generator as the main loop, one hoSil call site
float hoCast(vec2 p,float zT){
  vec2 q=p-gSc,P=vec2(q.x,q.y/gTilt);float rho=length(P),phi=hoAt(P.y,P.x),kp=(rho-gRho0)/gSp,uH=gYh-p.y;
  float kmin=max(ceil(log(max((gH-2.85*gRw)/max(uH,1e-5)/gZ0,1e-9))/gLg),-16.),kmax=floor(log(max(gH/max(uH,1e-5)/gZ0,1e-9))/gLg);
  float best=max(hoA(length(p-gSc)-gRh*.62,gPx)*step(zT+1e-3,0.)*(1.-gFPar),0.);
  int n=18+int(min(uZoom,0.));
  for(int i=int(min(uZoom,0.));i<n;i++){
    float fi=float(i),ci=floor(fi*.5),par=fi-2.*ci;
    float kk=floor(kp+.5)-4.+ci;vec4 hr=hoH(vec2(kk,3.),gVsI);
    float rc=gRho0+gSp*kk,Ro=gSp*mix(mix(.27,.38,hr.y),mix(.5,.62,hr.y),step(.42,hr.x))*min(1.,.6+.2*max(kk,0.));
    float N=max(3.,floor(TAU*max(rc,.01)/(Ro*1.85))),dirO=mix(gGd*(1.-2.*mod(kk,2.)),gGd,gFGal);
    float ak=dirO*gSw*TAU/N+hr.z*TAU,xo=(phi-ak)*N/TAU,jo=floor(xo+.5);jo+=par*(step(jo,xo)*2.-1.);
    float ph=jo*TAU/N+ak;vec2 cs2=vec2(cos(ph),sin(ph));
    float k=kmin+ci,Zk=gZ0*exp(gLg*k),dirR=gGd*(mod(k,2.)*2.-1.),st=gTb*gRate+fract(k*.618)+(gTr-gTb)*gRate,W=2.3*gRw;
    float hop=sin(PI*min(fract(st)/.42,1.)),off=dirR*W*(floor(st)+hoBack(fract(st))),xr=(p.x*Zk-off)/W,jr=floor(xr+.5);
    jr+=par*(step(jr,xr)*2.-1.);
    float Rr=gRw/Zk,bnd=mod(mix(kk,k,gFPar),8.);vec4 gs4=step(abs(vec4(floor(bnd*.5))-vec4(0.,1.,2.,3.)),vec4(.5));
    float phB=fract(gTb*dot(vec4(1.,1.,1.,2.),gs4)+dot(vec4(0.,.5,.25,.25),gs4)-mix(kk,k,gFPar)*.06+gEBig*ph/TAU);
    float hopB=4.*phB*(1.-phB)*dot(gBE,gs4)*(1.-.7*gBrk),A=Ro*(.5+.3*gEBig)*hopB*(1.-.45*gs4.w);
    vec2 cen=mix(gSc+vec2(cs2.x,cs2.y*gTilt)*(rc+A*mix(1.,clamp(cs2.y*3.,-1.,1.),abs(cs2.y))),vec2((jr*W+off)/Zk,gYh-gH/Zk+Rr*(1.+(.18*hop+.32*hopB)*(1.-gBrk))),gFPar);
    float band=bnd,z=mix(-cs2.y*rc,-Zk,gFPar);
    float R=mix(Ro*(1.-.36*cs2.y)*(1.+.12*gKick*step(band,1.5)+.04*gKick+.2*gBsS*step(abs(band-2.5),1.)+.1*hopB+.05*gSnE),Rr*(1.+.06*gKick+.1*gBsS),gFPar);
    float ok=mix(step(-.5,kk),step(k,kmax)*step(0.,uH)*step(2.5,Rr/gPx),gFPar)*step(zT+1e-3,z)*step(1.,R/gPx);
    if(ok<.5)continue;
    vec2 dv=mix(vec2(-cs2.y,cs2.x*gTilt)*dirO,vec2(dirR,0.),gFPar),id=mix(vec2(mod(jo,N),kk),vec2(mod(jr,256.),k),gFPar);id-=256.*floor(id/256.);
    vec4 h=hoH(id,band+gVsI*.37);float ty=dot(step(gT,h.yyyy),vec4(1.));ty=mix(ty,6.,step(3.5,ty)*step(.5,h.z));
    vec2 v=(p-cen)/max(R,1e-5);
    float mv=step(2.5,ty)*step(ty,4.5),sx=step(0.,dv.x)*2.-1.;
    vec2 qv=rot(-clamp(hoAt(dv.y,abs(dv.x)),-1.1,1.1)*mv)*(v*vec2(mix(1.,sx,mv),1.));
    float sa=mix((h.w-.5)*.9,(step(.5,h.z)*2.-1.)*gTb*TAU/5.+h.z*TAU,step(.5,ty)*step(ty,1.5));
    float d=hoSil(qv,ty,step(.42,h.z),sa,.35+.65*gKick,12.,.34)*R;
    best=max(best,hoA(d,gPx*1.4));
  }
  return best;
}
// printed fine art inside a character (or along a belt): coloured ink in the character's own frame, octaves doubling in
// frequency, each appearing only once its cells are several pixels wide. Staggered, rotated per octave and with cells
// missing at random so it never reads as a screen-door grid. Coverage per octave is capped; the colours are palette inks.
vec3 hoEngrave(vec3 col,vec2 q,float pq,float sd,vec3 a1,vec3 a2,float amt){
  int nO=1+HD+int(min(uZoom,0.));
  for(int o=int(min(uZoom,0.));o<nO;o++){
    float fo=float(o),so=11.*pow(2.,fo),fad=smoothstep(3.2,8.,1./(so*pq));
    if(fad<.004)break;
    vec2 g=rot(.61*fo+sd*5.)*q*so;g.x+=.5*mod(floor(g.y),2.);
    vec2 id=floor(g),f=fract(g)-.5;float hh=h21(id+fo*17.+sd*91.),mt3=mod(fo,3.);
    float d=mix(mix(length(f)-.2,hoStar(f,.42,.5),step(.5,mt3)),max(abs(length(f)-.3)-.05,-f.y-.1),step(1.5,mt3))/so;
    float a=hoA(d,pq)*fad*step(hh,.72)*amt*(.8-.09*fo);
    col=mix(col,mix(a1,a2,step(.5,fract(hh*7.+fo*.5))),a);
  }
  return col;
}
// a far plane of tiny star-folk behind the system: ink-outlined stars, ringed planets and sunbursts with faces once they are big enough
vec3 hoFolk(vec3 col,vec2 p,float L,float px,float cs,float arm,float vsI,float tb){
  float sc=.125*exp(-.40*L);
  vec2 u=(p+vec2(L*.37,L*.23))/sc;vec4 hx=hoHex(u),h=hoH(hx.zw+L*91.,vsI+L);
  if(h.y>.46-.05*L)return col;
  float R=sc*(.13+.13*h.x)*(1.+.25*hoBand(mod(hx.z+L,8.)));if(R/px<1.5)return col;
  vec2 q=(hx.xy-(h.zw-.5)*.3)*sc/R;
  float t=floor(h.w*3.),d=mix(mix(hoStar(rot(notchF(h.z,tb))*q,.95,.5)-.05,min(length(q)-.62,hoRingD(q,h.z*2.-1.)),step(.5,t)),hoSunD(q,9.,.34),step(1.5,t));
  float dep=mix(1.,.72,L/6.);
  vec3 c=hoC(h.x*6.+cs+arm+L)*dep*(1.+.5*hoOn(mod(hx.z+L,8.)));
  float alp=mix(.92,.55,L/6.);
  col=mix(col,mix(HOINK,c*.3,min(L/4.,1.)),hoA(d*R,px)*alp);
  col=mix(col,c,hoA((d+.13)*R,px)*alp);
  if(R/px>7.){float pq=px/R;
    col=mix(col,HOINK,hoA(length(vec2(abs(q.x)-.25,q.y-.1))-.085,pq));
    col=mix(col,HOINK,hoA(max(abs(length(q-vec2(0.,.1))-.2)-.03,q.y+.02),pq));
    if(R/px>16.)col=mix(col,vec3(1.8),hoA(length(vec2(abs(q.x)-.21,q.y-.13))-.03,pq));}
  return col;
}
#endif
void realm(){
  vec2 p0=scr();
  float wr=uP3.x;
  vec4 C=mix(uP4,uP5,step(length(p0),wr));
  float ev=floor(uP4.z),evp=fract(uP4.z),evb=evp*16.,fam=C.x,vs=C.y,csN=floor(uP4.w/4.),ramp=uP4.w-4.*csN;
  float tr=uP1.x,mt=uP1.y,kick=uP1.z,prA=floor(uP1.w/256.)*.0101,hw0=uP1.w-256.*floor(uP1.w/256.),htA=floor(hw0*.5)*.01,bsS=hw0-2.*floor(hw0*.5),bld=uP3.y,brk=uP3.z,aiA=floor(uP3.w*.5)*.01,dfl=uP3.w-2.*floor(uP3.w*.5),tb=uP5.z;
  float fPar=step(1.5,fam),fGal=step(.5,fam)-fPar;
  // events: 1 heart eyes, 2 spin storm, 3 chorus, 4 giant planet, 5 comet shower, 6 rocket parade
  float eG=step(abs(ev-4.),.5),eSp=step(abs(ev-2.),.5),eRk=step(abs(ev-6.),.5),eUfo=step(abs(ev-8.),.5),eFly=max(max(step(abs(ev-5.),.5),eRk),eUfo);
  float eBig=step(abs(ev-7.),.5)*smoothstep(0.,1.5,evb)*(1.-smoothstep(13.,16.,evb));
  // v18 bounce: orbit / row groups dance to their own range. Bass groups leap on the beat, mid groups on the off-beat,
  // presence and air groups in double time; every envelope is the smoothed one the JS side already computes
  float eF=fract(uP2.x)/.49,bas=floor(eF*64.)/63.,snE=fract(eF*64.);
  vec4 bE=max(vec4(max(kick,bas),bsS,prA,min(1.,aiA*1.35)),vec4(eBig));
  float gs=eG*smoothstep(0.,1.5,evb)*(1.-smoothstep(13.,15.,evb));
  float fly=eFly*smoothstep(0.,2.,evb)*(1.-smoothstep(13.,16.,evb));
  float zm=uZoom*(1.+.1*bld);
  vec2 p=p0/zm;float px=1./(uRes.y*zm);
  float vsI=floor(vs*50.);
  float tilt=mix(mix(.4,.52,fract(vs*7.31)),mix(.6,.72,fract(vs*7.31)),fGal)*(1.+.06*sin(mt*.11));
  float sp=mix(mix(.16,.19,fract(vs*3.17)),mix(.13,.15,fract(vs*3.17)),fGal);
  float rate=1.-.5*step(.75,fract(vs*2.71)),gd=step(.5,fract(vs*4.1))*2.-1.;
  float yh=mix(.04,.16,fract(vs*5.3));
  float sw=floor(tb*rate)+hoBack(fract(tb*rate))+(tr-tb)*rate,notch=floor(tb)+hoBack(fract(tb));
  vec2 sc=vec2(0.,mix(.02,yh,fPar));
  vec2 q=p-sc,P=vec2(q.x,q.y/tilt);float rho=length(P),phi=hoAt(P.y,P.x),rho0=.25,kp=(rho-rho0)/sp;
  float uH=yh-p.y,H=.36,Rw=.105,lg=.22314,Z0=.8;
  float kmin=max(ceil(log(max((H-2.85*Rw)/max(uH,1e-5)/Z0,1e-9))/lg),-16.);
  float kmax=floor(log(max(H/max(uH,1e-5)/Z0,1e-9))/lg);
  // cast thresholds on a hash: planet / star / sun / comet / rocket
  vec4 T=vec4(.44,.64,.73,.87)*(1.-fGal-fPar)+vec4(.3,.67,.72,.9)*fGal+vec4(.34,.56,.67,.73)*fPar;
  float faceM=0.;
  float tz=-1e9,tTy=0.,tR=1.,tBand=0.,topInk=0.,rimC=0.,rimZ=-1e9,shC=0.,shZ=-1e9,hero=0.,heroSv=0.,tdU=0.;
  vec2 tq=vec2(0.),tc=vec2(0.);vec4 th=vec4(0.);
  // ---- per-pixel candidates that do not depend on the loop: the parade sky floater (drifting planets, stars, suns
  // and comets behind the sun, bobbing on the beat), the event flyby (comet shower / rocket parade: big movers sweep
  // diagonally across the front) and the hero (a spectrum sun; in the parade huge and sinking on the horizon; the
  // galaxy's star-faced core)
  vec2 fdir=mix(vec2(-.89,-.45),vec2(.45,.89),eRk);
  vec4 hx=hoHex((p-vec2(gd*tr*.02,0.))/.22),hS=hoH(hx.zw+50.,vsI);
  float tyS=floor(hS.y*3.99);tyS=mix(tyS,3.,step(2.5,tyS));
  vec2 cenS=p-(hx.xy-(hS.zw-.5)*.25-vec2(0.,(.06+.1*kick)*sin(PI*(tb+hS.x*2.))))*.22;
  vec2 fu=vec2(dot(p0,fdir),dot(p0,vec2(-fdir.y,fdir.x)));
  float lane=floor(fu.y/.36+.5),fx=fu.x-tr*.5-lane*.71,cxf=floor(fx/1.5+.5);
  vec4 hF=hoH(vec2(cxf,lane),77.);
  vec2 lo=vec2(fx-cxf*1.5+(hF.w-.5)*.4,fu.y-lane*.36-(hF.y-.5)*.08)/zm,cenF=p-fdir*lo.x-vec2(-fdir.y,fdir.x)*lo.y;
  float Rh=mix(mix(.14,.12,fGal),.27,fPar)*(1.+.2*kick)*(1.-.5*gs),nrH=mix(16.,20.,fPar);
  float acH=floor(hoAt(q.y,q.x)*nrH/TAU+.5)*TAU/nrH,svH=spec(.02+.78*(1.-abs(mod(acH+PI*.5,TAU)-PI)/PI));
  // ---- depth-sorted billboards in one loop with one silhouette call: iterations 0..17 are the two nearest slots on the
  // 9 orbits (or parade rows) around the pixel's own, 18 the sky floater, 19 the flyby, 20 the hero. The generator is
  // branch-free and the bound comes from a uniform (always 21): both keep the D3D11 compile small.
  int nA=21+int(min(uZoom,0.));
  for(int i=0;i<nA;i++){
    float fi=float(i),ci=floor(fi*.5),par=fi-2.*ci,isSky=step(17.5,fi)*step(fi,18.5),isFly=step(18.5,fi)*step(fi,19.5),isHero=step(19.5,fi),isA=step(fi,17.5);
    // orbit kk: a tilted circle of N slots; the whole orbit steps one slot per beat (eased, with overshoot)
    float kk=floor(kp+.5)-4.+ci;
    vec4 hr=hoH(vec2(kk,3.),vsI);
    float rc=rho0+sp*kk,Ro=sp*mix(mix(.27,.38,hr.y),mix(.5,.62,hr.y),step(.42,hr.x))*min(1.,.6+.2*max(kk,0.));
    float N=max(3.,floor(TAU*max(rc,.01)/(Ro*1.85))),dirO=mix(gd*(1.-2.*mod(kk,2.)),gd,fGal);
    float ak=dirO*sw*TAU/N+hr.z*TAU,xo=(phi-ak)*N/TAU,jo=floor(xo+.5);jo+=par*(step(jo,xo)*2.-1.);
    float ph=jo*TAU/N+ak;vec2 cs2=vec2(cos(ph),sin(ph));
    // parade row k on the floor plane (perspective, rows spaced geometrically), marching one cell per beat
    float k=kmin+ci,Zk=Z0*exp(lg*k),dirR=gd*(mod(k,2.)*2.-1.),st=tb*rate+fract(k*.618)+(tr-tb)*rate,W=2.3*Rw;
    float hop=sin(PI*min(fract(st)/.42,1.)),off=dirR*W*(floor(st)+hoBack(fract(st))),xr=(p.x*Zk-off)/W,jr=floor(xr+.5);
    jr+=par*(step(jr,xr)*2.-1.);
    float Rr=Rw/Zk;
    // v18: a ballistic leap, the phase delayed orbit by orbit so each kick ripples outward through the system
    float bnd=mod(mix(kk,k,fPar),8.);vec4 gs4=step(abs(vec4(floor(bnd*.5))-vec4(0.,1.,2.,3.)),vec4(.5));
    float phB=fract(tb*dot(vec4(1.,1.,1.,2.),gs4)+dot(vec4(0.,.5,.25,.25),gs4)-mix(kk,k,fPar)*.06+eBig*ph/TAU);
    float hopB=4.*phB*(1.-phB)*dot(bE,gs4)*(1.-.7*brk)*isA;
    float A=Ro*(.5+.3*eBig)*hopB*(1.-.45*gs4.w);
    vec2 cen=mix(sc+vec2(cs2.x,cs2.y*tilt)*(rc+A*mix(1.,clamp(cs2.y*3.,-1.,1.),abs(cs2.y))),vec2((jr*W+off)/Zk,yh-H/Zk+Rr*(1.+(.18*hop+.32*hopB)*(1.-brk))),fPar);
    float band=mod(mix(kk,k,fPar),8.),z=mix(-cs2.y*rc,-Zk,fPar);
    float R=mix(Ro*(1.-.36*cs2.y)*(1.+.12*kick*step(band,1.5)+.04*kick+.2*bsS*step(abs(band-2.5),1.)+.1*hopB+.05*snE),Rr*(1.+.06*kick+.1*bsS),fPar);
    vec2 dv=mix(vec2(-cs2.y,cs2.x*tilt)*dirO,vec2(dirR,0.),fPar),id=mix(vec2(mod(jo,N),kk),vec2(mod(jr,256.),k),fPar);
    float ok=mix(step(-.5,kk),step(k,kmax)*step(0.,uH)*step(2.5,Rr/px),fPar),dl=mix(rc,length(cen-sc),fPar);
    id-=256.*floor(id/256.);
    vec4 h=hoH(id,band+vsI*.37);
    float ty=dot(step(T,h.yyyy),vec4(1.));ty=mix(ty,6.,step(3.5,ty)*step(.5,h.z));   // v18: half the rockets are saucers
    // select the extra candidates
    h=h*isA+hS*isSky+hF*isFly+vec4(.13,.5,.5,fract(vs*7.13))*isHero;
    ty=ty*isA+tyS*isSky+mix(mix(3.,4.,eRk),6.,eUfo)*isFly+mix(2.,1.,fGal)*isHero;
    band=band*isA+mod(hx.z,8.)*isSky+7.*isFly;
    R=R*isA+.22*(.26+.12*hS.z)*(1.+.08*hoBand(mod(hx.z,8.)))*isSky+.12*(.8+.4*hF.x)*fly/zm*isFly+Rh*isHero;
    cen=cen*isA+cenS*isSky+cenF*isFly+sc*isHero;
    z=z*isA-2e6*isSky+1e6*isFly+mix(0.,-1e6,fPar)*isHero;
    ok=ok*isA+fPar*step(hS.x,.72)*isSky+step(.001,fly)*step(hF.z,.62)*isFly+isHero;
    dv=mix(dv,fdir,isFly);dl=dl*isA+length(cen-sc)*isSky;
    vec2 v=(p-cen)/max(R,1e-5);
    // movers (comets, rockets) point along their motion; mirrored, never upside down; drops and the spin storm spin the rest
    float mv=step(2.5,ty)*step(ty,4.5),sx=step(0.,dv.x)*2.-1.;
    vec2 qv=rot(-clamp(hoAt(dv.y,abs(dv.x)),-1.1,1.1)*mv)*(v*vec2(mix(1.,sx,mv),1.));
    float spn=TAU*(smoothstep(0.,1.,1.-dfl)+eSp*isA*smoothstep(0.,1.,clamp(evb*.45-dl*2.,0.,1.)))*(1.-isHero)*(1.-isFly);
    qv=rot(spn*(1.-mv)*(step(.5,h.z)*2.-1.))*qv;
    // v18: the mids rock everyone side to side (a head-bob on the two-beat), squash on landing and stretch at the top of a leap
    float rk=((.04+.24*bsS)*sin(PI*tb+step(.5,h.x)*PI)+.12*aiA*step(abs(ty-1.),.5)*sin(TAU*tb*2.+h.y*TAU))*(1.-.75*isHero)*(1.-isFly)*(1.-mv);
    float sq=(.1*(2.*hopB-dot(bE,gs4)*isA)+.1*snE*isA)*(1.-mv);
    qv=(rot(rk)*qv)/vec2(1.-.6*sq,1.+sq);
    float sa=mix((h.w-.5)*.9,mix((step(.5,h.z)*2.-1.)*notch*TAU/5.+h.z*TAU,gd*notch*TAU/5.,isHero),step(.5,ty)*step(ty,1.5));
    float rg=step(.42,h.z)*(1.-isFly),aux=.35+.65*kick;
    float d=hoSil(qv,ty,rg,sa,aux,mix(12.,nrH,isHero),mix(.34,(.12+.9*svH)*(1.+.5*bld+.4*kick),isHero))*R;
    d=max(d,mix(-1e3,uH,max(isSky,isHero*fPar)));
    d=mix(1e3,d,ok*step(1.,R/px));
    float w=mix(min(max(.045*R,1.1*px),.3*R),max(.0035,1.3*px),isHero),fade=max(smoothstep(3.,9.,R/px),isHero);
    if(step(d,0.)*step(tz,z)>.5){tz=z;tTy=ty;tR=R;tBand=band;tq=qv;tc=mix(cen,p,isFly);th=h;hero=isHero;tdU=d/max(R,1e-5);topInk=(1.-hoA(d+w,.7*px))*fade;}
    else{float rc2=clamp(.5-d/px,0.,1.)*fade;if(step(.01,rc2)*step(rimZ,z)>.5){rimZ=z;rimC=rc2;}
      float s=hoA(d-.14*R,px)*smoothstep(6.,14.,R/px)*(1.-isHero);if(step(.01,s)*step(shZ,z)>.5){shZ=z;shC=s;}}
  }
  heroSv=svH;
  // contrails behind the flybys: a five-band rainbow ribbon (comets) or a chain of puffy smoke clouds (rockets)
  {
    float RF=.12*(.8+.4*hF.x)*fly/zm;vec2 qv=vec2(lo.x,lo.y*sign(fdir.x))/max(RF,1e-5);
    float wv=qv.y+.12*sin(qv.x*1.3+mt*5.)*clamp(-qv.x*.3,0.,1.),pc=floor(qv.x/.75+.5);
    vec2 pq2=vec2(qv.x-pc*.75,qv.y+.08*sin(pc*2.3+mt*2.));
    float dT=mix(max(abs(wv)-.3,max(qv.x+.5,-qv.x-9.)),max(length(pq2)-(.3+.08*sin(pc*1.7))*(1.+.04*pc),max(qv.x+1.,-qv.x-9.)),eRk)*RF;
    dT=mix(1e3,dT,step(.001,fly)*step(hF.z,.62)*step(1.,RF/px)*(1.-eUfo));
    if(step(dT,0.)*step(tz,1e6-1.)>.5){tz=1e6-1.;tTy=5.;tR=RF;tBand=7.;tq=qv;tc=p;th=hF;hero=0.;tdU=dT/max(RF,1e-5);topInk=1.-hoA(dT+max(.045*RF,1.1*px),.7*px);}
    else{float rc2=clamp(.5-dT/px,0.,1.);if(step(.01,rc2)*step(rimZ,1e6-1.)>.5){rimZ=1e6-1.;rimC=rc2;}}
  }
  // per-character values recomputed from the hash and type (fewer values carried through the loop)
  vec4 h0=th;
  float tdl=length(tc-sc),tRg=step(.42,h0.z),tAux=mix(.35+.65*kick,eRk,step(abs(tTy-5.),.5));
  float tSa=mix((h0.w-.5)*.9,mix((step(.5,h0.z)*2.-1.)*notch*TAU/5.+h0.z*TAU,gd*notch*TAU/5.,hero),step(.5,tTy)*step(tTy,1.5));
  // ================= colour the top shape once =================
  vec3 col;
  float gnd=step(tz,-1e8);
  vec4 h=th,h2=fract(h.yzwx*13.17+h.x*3.1);
  float dls=mix(tdl,length(p-sc),gnd),cs=csN+step(dls*1.1+.02,ramp);
  // galaxy colour arms: two arms turning rigidly (the stars travel through them at their own Kepler speed)
  vec2 Pc=mix(tc-sc,q,gnd)/vec2(1.,tilt);
  float arm=fGal*2.*floor(2.*fract((hoAt(Pc.y,Pc.x)-2.4*log(max(length(Pc),.02))+mt*.06)/TAU));
  // ---- giant smiling ringed planets made of the characters: the ground and the characters inside one take its
  // colours (band, ring, face); zoomed out they read as giant figures. The giant-planet event paints one centred
  // giant the same way, card-stunt style (every character flips at its own moment, staggered outward)
  vec2 mpos=mix(tc,p,gnd);
  float dsg=length(mpos*zm)/.8,gj=mix(.6*h.y,.3,gnd),fi=clamp(evb-.5-1.6*dsg-gj,0.,1.),fo=clamp(evb-12.-1.6*dsg-gj,0.,1.);
  float gfx=eG*step(dsg,1.15)*(1.-hero)*(step(.5,fi)-step(.5,fo));
  float gfl=eG*step(dsg,1.15)*(max(0.,1.-abs(fi-.5)*5.)+max(0.,1.-abs(fo-.5)*5.));
  vec4 ov=vec4(0.);
  {
    vec2 mu=rot(.3)*mpos/2.3+vec2(.31,.17);
    vec4 mc=floor(vec4(mu,mu-vec2(.5,.8660254))/vec2(1.,1.7320508).xyxy)+.5;
    vec2 ma=mu-mc.xy*vec2(1.,1.7320508),mb=mu-(mc.zw+.5)*vec2(1.,1.7320508);
    vec2 mq=mix(mb,ma,step(dot(ma,ma),dot(mb,mb)));
    vec2 mid=floor((mu-mq)*2.+.5);
    vec2 gq=mix(rot(-.3)*mq/.47,mpos*zm/.8,gfx);
    float gh=mix(h21(mid),.37,gfx),gr=length(gq),ga=-.35+.15*sin(mt*.3+gh*6.);
    vec2 rq=rot(ga)*gq;float ge=length(rq/vec2(1.,.3));
    float inB=step(gr,.6),inR=step(hoRingD(gq,ga),0.)*max(1.-inB,step(rq.y,0.));
    float yb=floor(gq.y*3.4+.15*sin(gq.x*5.+mt*.4)+.5);
    vec3 gc=hoC(floor(gh*6.)+yb*(1.+step(.5,fract(gh*7.)))+cs+arm);
    gc=mix(gc,vec3(1.9,1.8,1.6),inR);
    float zo=max(smoothstep(.5,.3,uZoom),gfx);
    vec2 gf=(gq-vec2(0.,-.02))/.42;
    float mopen=max(uP2.w,.6*kick*gfx);
    vec2 ef=(vec2(abs(gf.x),gf.y)-vec2(.36,.16))/vec2(.17,.24*(1.-uP5.w*.92)+.02);
    float eyeM=step(length(ef),1.),glM=step(length(ef-vec2(.3,.4)),.38);
    float mouthM=step(length((gf-vec2(0.,-.3))/vec2(.24+.06*mopen,.08+.22*mopen)),1.)*step(gf.y,-.3+.5*mopen+.2*gf.x*gf.x);
    vec3 fcol=mix(mix(gc,vec3(1.8,.06,.18),mouthM),mix(vec3(.04,.02,.09),vec3(2.),glM),eyeM);
    gc=mix(gc,fcol,inB*zo);
    float mw=step(h21(mid+h.xy*7.),.95*smoothstep(.55,.3,uZoom));
    ov=vec4(gc,max(inB,inR)*mix(mw,1.,gfx));
  }
  if(gnd>.5){
    // one ground for all families: a band coordinate u (orbit / floor row / sky ring) whose bands are ribbons in the
    // band's colour (brightness = its band level, flash on its onset), over deep space (orbit plane), a cosmic checker
    // floor (parade) or a sunburst sky, with star dust twinkling with the air band
    float mO=1.-fPar,mF=fPar*step(p.y,yh),mS=fPar-mF,Z=H/max(uH,1e-5);
    float u=mO*kp+mF*log(max(Z/Z0,1e-6))/lg+mS*(length(q)*7.-tb*.5),fw=max(fwidth(u),1e-4);
    float ki=floor(u+.5),fk=u-ki+.04*mF,band=mod(ki,8.),lv=hoBand(band),on=hoOn(band);
    float dir=mix(gd*(1.-2.*mod(ki,2.)),gd,fGal)*mO+gd*(mod(ki,2.)*2.-1.)*mF;
    // background: deep space (+ galaxy arms), checker floor, sunburst sky
    float sa=(phi-2.4*log(max(rho,.02))+mt*.06)/TAU*2.,af=fract(sa),afw=max(min(fwidth(sa),fwidth(hoAt(-P.y,-P.x)/TAU*2.))*7.,1e-4);
    vec3 gc=mix(hoC(uP2.x),hoC(uP2.x+3.),.12)*(.95+.25*uB1.x);
    vec3 ac=hoC(floor(af*7.)+cs+3.*mod(floor(sa),2.))*(.8+.4*hoBand(mod(floor(af*7.)*2.,8.)));
    gc=mix(gc,ac,fGal*hoA(-min(af*7.,3.-af*7.),afw));

    vec2 tl=vec2(p.x*Z/(Rw*1.15),u*2.);
    float far=smoothstep(.15,.4,fw*2.5);
    vec3 fc=mix(hoC(ki+cs+1.),hoC(ki+cs+4.),mod(floor(tl.x)+floor(tl.y),2.))*(.8+.15*uB1.x);
    vec2 tf=abs(fract(tl)-.5);
    fc=mix(fc,mix(fc,vec3(.06,.02,.16),.6),hoA(.5-max(tf.x,tf.y)-.03,fw*2.5)*(1.-far));
    fc=mix(fc,hoC(ki+cs)*(.9+.5*lv),far);
    vec3 sk=hoC(ki+cs+2.)*mix(.68,.92,mod(floor((hoAt(q.y,q.x)+mt*.03)*16./TAU),2.))*(.85+.25*lv);
    gc=mix(mix(gc,fc,mF),sk,mS);
    // ribbons: orbits are conveyor belts with cream pinstripes and tiny star-folk stepping with the orbit; floor rows are
    // rainbow belts with rollers turning with the march
    vec4 gb=step(abs(vec4(floor(band*.5))-vec4(0.,1.,2.,3.)),vec4(.5));
    float phG=fract(tb*dot(vec4(1.,1.,1.,2.),gb)+dot(vec4(0.,.5,.25,.25),gb)-ki*.06);
    float bw=(mO*mix(.24,.1,fGal)+mF*.2)*(.85+.5*4.*phG*(1.-phG)*dot(bE,gb)),belt=hoA(abs(fk)-bw,fw)*(1.-mS);
    vec3 bc=hoC(ki+cs+arm+mF*clamp(floor((fk+.2)/.1),0.,3.))*(.9+.5*lv+.8*on+.55*prA);

    float rc=max(rho0+sp*ki,.02),N2=floor(TAU*rc/(sp*.3)),ua=mix(phi*N2/TAU,p.x*Z/(Rw*.6),mF)-dir*mix(sw,2.*(floor(tb*rate+fract(ki*.618))+hoBack(fract(tb*rate+fract(ki*.618)))),mF)+ki*.37,cl=floor(ua+.5);
    vec2 lu=vec2((ua-cl)*mix(TAU*rc/N2,Rw*.6/Z,mF),fk*mix(sp,.35/Z,mF))/(mix(sp,.35/Z,mF)*.1);
    float lw=fw/.1,lr=length(lu),lt=1.-2.*abs(fract(hoAt(lu.y,lu.x)*5./TAU+.25-dir*notch*.2)-.5);
    float ds=mix((lr-.5-.45*lt)*.6,lr-.45,mF);
    float tiny=smoothstep(.5,.15,lw)*step(h21(vec2(cl,ki)),.85)*(1.-fGal)*(1.-mS);
    vec3 sfc=mix(mix(hoC(cl+ki+cs+3.)*1.4,HOCR,.4)*(1.+.8*on),HOCR,mF);
    bc=mix(bc,mix(HOINK,sfc,hoA(ds+.18,lw)),hoA(ds,lw)*tiny);
    bc=mix(bc,HOINK,hoA(length(vec2(abs(lu.x)-.2,lu.y-.05))-.09,lw)*tiny*smoothstep(.2,.08,lw)*mO);
#if HD>=1
    bc=hoEngrave(bc,vec2(ua*.3,u),fw,h21(vec2(ki,3.)),hoC(ki+cs+arm+2.)*(.95+.3*lv),hoC(ki+cs+arm+4.)*(.95+.3*lv),.6);
#endif
    col=mix(gc,bc,belt);
    col=mix(col,mix(col*.35,vec3(.06,.02,.16),.6),max(hoA(abs(abs(fk)-bw)-.012,fw)*smoothstep(.1,.04,fw)*(1.-mS),hoA((.5-abs(fract(u)-.5))/7.-.0025,px)*mS));
    col=mix(col,ov.rgb*.8,step(.5,ov.a)*mix(.85*smoothstep(.5,.28,uZoom),1.,gfx));
    // star dust (orbit plane and sky)
    vec2 sg=mix(P*26.,p*16.,fPar);vec2 si=floor(sg);vec2 sf=sg-si-.5;float sh=h21(si+7.);
    float tw=step(.75-.2*uB2.w,sh)*(.3+.9*clamp(uB2.w*1.3+uO2.w+.6*uHat,0.,1.))*(1.-mF*(1.-step(.5,ov.a)))*(1.-belt);
    vec2 aq=abs(sf-(fract(sh*vec2(17.,31.))-.5)*.4);
    float dst=(aq.x*aq.y*30.+max(aq.x,aq.y)-(.2+.12*uB2.w)*tw)/mix(26.,16.,fPar);
    col=mix(col,vec3(2.1,2.,1.8),hoA(dst,mix(px/tilt,px,fPar))*step(.01,tw));
#if HD>=1
    if((1.-mF)*(1.-belt)>.5){int nFL=HD+1+int(min(uZoom,0.));
      for(int fl=int(min(uZoom,0.));fl<nFL;fl++)col=hoFolk(col,p,float(fl),px,cs,arm,vsI,tb);}
#endif
  }else{
    float mo=clamp(1.7*(hoBand(tBand)-.4),0.,1.)*.7+.6*hoOn(tBand);
    mo=max(mo*(.6+.4*h2.x),uP2.w*step(.55,h2.z)*step(.08,tR));
    mo=clamp(mo+.3*bld,0.,1.)*(1.-.5*brk);
    float tbl=fract(mt*.11+h2.y*7.);
    float bl=max(1.-smoothstep(0.,.012,abs(tbl-.5)),uP5.w);
    float fl=1.+.7*hoOn(tBand)*(.5+.5*h2.y)+.25*dfl+1.2*gfl;
    float pq=px/tR,lod=smoothstep(7.,15.,tR/px),w=max(.04,1.3*pq),ik=smoothstep(.13,.07,pq);
    mo=mix(mo,clamp(uP2.w+.25*bld+.3*kick,0.,1.),hero);lod=max(lod,hero);fl=mix(fl,1.+.3*uO1.x,hero);
    float act=step(tdl*.3,evp)*(1.-step(.55+tdl*.3,evp));
    float eo=mix(mix(-1.,.6,hero),mix(.22,.1,step(2.5,ev)),act*step(.5,ev)*step(ev,3.5)*(1.-eSp)*step(.5,ev));
    vec3 base=mix(hoC(h.x*6.+cs+arm),ov.rgb,min(ov.a,1.))*fl;
    vec3 acc=hoC(h.x*6.+cs+arm+2.+floor(h2.w*3.))*fl,acc2=hoC(h.x*6.+cs+arm+4.+floor(h2.z*2.))*fl,cr=HOCR*fl;
    vec2 q=tq,fq=q/.4;float fs=.4,fm=1.,sty=h2.w;
    float r=length(q);
#if HD>=1
    float zz=smoothstep(120.*HG,210.*HG,tR/px);
#else
    float zz=smoothstep(120.,210.,tR/px)*mix(1.,smoothstep(1.3,2.,uZoom),hero);
#endif
    // nested layers that follow the silhouette inward (three colours with ink seams): the layered rings inside every
    // character come from the silhouette distance the depth pass already found
    float lu=-tdU/.14,lk=floor(lu);
    vec3 lay=mix(mix(base,acc,step(.5,lk)),mix(cr*.92,acc2,step(.5,sty)),step(1.5,lk));
    lay=mix(lay,mix(lay,HOINK,.8),hoA(abs(fract(lu+.5)-.5)*.14-w*.3,pq)*step(.5,lu)*lod*ik);
    // every character type is shaded (straight-line code compiles far faster on D3D11 than a branch chain), then selected
    vec3 cA=vec3(0.);vec2 fqA=vec2(0.);float fsA=0.,fmA=0.;
    {float wT=step(tTy,.5);vec3 col=vec3(0.);vec2 fq=q/.4;float fs=.4,fm=1.;
      // ringed planet: wavy latitude bands (rainbow or two-tone), a ringed storm eye, a shine; a three-band ring that
      // passes behind the body on the far side
      float yb=q.y*3.6+.16*sin(q.x*8.+mt*1.1+h.z*6.)+.5,bi=floor(yb);
      vec3 bc=mix(hoC(h.x*6.+cs+arm+bi)*fl,mix(base,acc,mod(bi,2.)),step(.4,sty));
      bc=mix(bc,mix(bc,HOINK,.8),hoA((.5-abs(fract(yb)-.5))/3.6-w*.3,pq)*lod*ik);
      bc=mix(bc,bc*bc/max(max(bc.r,max(bc.g,bc.b)),.05)*.55,hoA(length(vec2((fract(q.x*9.+.5*bi)-.5)/9.,(fract(yb)-.5)/3.6))-.015,pq)*zz);
      float sd=length((q-vec2(.2,-.22))/vec2(.17,.1));
      bc=mix(bc,mix(acc2,cr,step(.5,fract(sd*2.))),hoA((sd-1.)*.1,pq)*lod*step(h2.y,.55));
      bc=mix(bc,cr,hoA(length((q-vec2(-.24,.3))/vec2(.17,.08))-1.,pq*6.)*.8*lod);
      vec2 rq=rot(tSa)*q;float e=length(rq/vec2(1.,.3)),dR=hoRingD(q,tSa);
      vec3 rcl=mix(mix(cr*.95,acc,step(.82,e)),acc2,step(.91,e))*(1.+.7*prA);
      rcl=mix(rcl,rcl*rcl/max(max(rcl.r,max(rcl.g,rcl.b)),.05)*.6,hoA(abs(fract(e*36.)-.5)/36.-.0035,pq)*zz);
      {float ra=hoAt(rq.y/.3,rq.x),rk2=floor(ra*30./TAU+.5);
       rcl=mix(rcl,HOCR*(1.+1.2*prA)*fl,hoA(length(vec2((ra-rk2*TAU/30.)*.865,(e-.865)*.6))-.013,pq)*zz);}
      rcl=mix(rcl,HOINK,ik*hoA(abs(dR)-w*.5,pq));
      float ringOn=hoA(dR-w*.5,pq)*tRg*max(step(.6,r),step(rq.y,0.));
      col=mix(bc,rcl,ringOn);
      fs=.4;fm=hoA(r-.6+w,pq)*(1.-ringOn);
      cA+=col*wT;fqA+=fq*wT;fsA+=fs*wT;fmA+=fm*wT;}
    {float wT=step(abs(tTy-1.),.5);vec3 col=vec3(0.);vec2 fq=q/.4;float fs=.4,fm=1.;
      // chubby star: nested star layers, cream tip dots that glint with the hats
      vec2 sq=rot(tSa)*q;float kt=floor(hoAt(sq.x,sq.y)*5./TAU+.5)*TAU/5.;
      {float sa5=hoAt(q.y,q.x),sk5=floor(sa5*56./TAU);
       lay=mix(lay,cr*(.95+1.1*uHat*mod(sk5,2.)),hoA(max(abs(fract(lu)-.5)*.14-.0055,(abs(fract(sa5*56./TAU)-.5)-.27)*r*TAU/56.),pq)*zz*step(lu,2.5));}
      col=mix(lay,cr*(1.+1.5*uO2.z+.8*uHat),hoA(length(sq-vec2(sin(kt),cos(kt))*.68)-.075,pq)*lod);
      fs=.34;
      cA+=col*wT;fqA+=fq*wT;fsA+=fs*wT;fmA+=fm*wT;}
    {float wT=step(abs(tTy-2.),.5);vec3 col=vec3(0.);vec2 fq=q/.4;float fs=.4,fm=1.;
      // sun: rays in alternating colours with a light spine (the hero's rays are the spectrum), a banded disc rippling
      // outward one band per beat, a golden face disc
      float a=hoAt(q.y,q.x),n=mix(12.,mix(16.,20.,fPar),hero),kr=floor(a*n/TAU+.5);
      col=mix(base,acc,mod(kr,2.))*(1.+1.3*heroSv*hero);
      col=mix(col,mix(col,cr,.45),hoA(abs(a-kr*TAU/n)*r-.025*r,pq)*step(.6,r));
      col=mix(col,cr*(1.+.9*uHat),hoA(length(vec2((a-kr*TAU/n)*r,(fract(r*11.-tb*.5)-.5)/11.))-.011,pq)*step(.62,r)*zz);
      float rb=(.56-r)/.07+tb*.5,rk=mod(floor(rb),2.);
      vec3 dc=mix(mix(acc2,cr*.9,rk),mix(base,acc2,rk),step(.5,sty));
      dc=mix(dc,mix(dc,HOINK,.8),hoA((.5-abs(fract(rb)-.5))*.07-w*.25,pq)*lod);
      col=mix(col,dc,hoA(r-.56,pq));
      col=mix(col,mix(vec3(2.,1.55,.3),vec3(2.1,1.9,1.55),step(.6,h2.z))*fl,hoA(r-.38,pq));
      col=mix(col,HOINK,ik*max(hoA(abs(r-.38)-w*.5,pq),hoA(abs(r-.56)-w*.4,pq)*step(.5,r)));
      col=mix(col,mix(HOINK,acc2,.35),hoA(length(vec2((fract(a*32./TAU)-.5)*TAU/32.*.345,r-.345))-.009,pq)*zz);
      fs=.36;fm=hoA(r-.38,pq);
      cA+=col*wT;fqA+=fq*wT;fsA+=fs*wT;fmA+=fm*wT;}
    {float wT=step(abs(tTy-3.),.5);vec3 col=vec3(0.);vec2 fq=q/.4;float fs=.4,fm=1.;
      // comet: a five-band rainbow tail with travelling sparkles, a ringed glowing head
      vec2 c=q-vec2(.32,0.);float rh=length(c);
      float hw=mix(.44,.07,clamp((.32-q.x)/1.3,0.,1.)),xb=((q.y-.06*sin(q.x*5.-mt*4.)*(.32-q.x))/hw+1.)*2.5;
      col=hoC(clamp(floor(xb),0.,4.)+cs+h.x*6.)*fl*1.1;
      col=mix(col,mix(col,HOINK,.7),hoA(abs(fract(xb+.5)-.5)/2.5*hw-w*.25,pq)*step(.5,xb)*step(xb,4.5)*lod);
      col=mix(col,cr*1.3,hoA(length(vec2(fract(q.x*2.5+mt*1.5+h.z)-.5,(xb-2.5)*.1))-.07,pq*2.5)*lod);
      float hu=(.5-rh)/.12;
      vec3 hc=mix(mix(acc,base,step(1.,hu)),cr*.92,step(2.,hu));
      hc=mix(hc,mix(hc,HOINK,.8),hoA(abs(fract(hu+.5)-.5)*.12-w*.3,pq)*step(.5,hu)*lod);
      col=mix(col,hc,hoA(rh-.5,pq));
      col=mix(col,HOINK,ik*hoA(abs(rh-.5)-w*.5,pq)*step(q.x,.32));
      fq=c/.3;fs=.3;fm=hoA(rh-.26,pq);
      cA+=col*wT;fqA+=fq*wT;fsA+=fs*wT;fmA+=fm*wT;}
    {float wT=step(abs(tTy-4.),.5);vec3 col=vec3(0.);vec2 fq=q/.4;float fs=.4,fm=1.;
      // rocket: three-layer flame, fins, a two-tone body with a red nose seam, a porthole with the face inside
      vec2 f=rot(-.7)*vec2(q.x+.42,abs(q.y)-.3);float dfn=hoEl(f,vec2(.26,.12)),db=hoEl(q-vec2(.06,0.),vec2(.8,.36));
      float fr=length((q-vec2(-.78-.12*tAux,0.))/vec2(.24+.14*tAux,.15));
      col=mix(mix(hoC(cs+1.)*1.6,vec3(2.3,1.9,.6),hoA((fr-.7)*.15,pq)),vec3(2.6,2.4,2.),hoA((fr-.38)*.15,pq))*(1.+.7*uO2.z+.4*uHat);
      col=mix(col,acc2,hoA(dfn,pq));
      vec3 bc=mix(base,acc,step(.5,q.x));
      bc=mix(bc,cr,step(abs(q.x+.27),.06));
      bc=mix(bc,HOINK,max(hoA(abs(abs(q.x+.27)-.06)-w*.3,pq),hoA(abs(q.x-.5)-w*.3,pq))*ik*lod);
      bc=mix(bc,cr*1.05,hoA(length(vec2(q.x-.42,(fract(q.y*10.)-.5)/10.))-.012,pq)*zz);
      vec2 pc=q-vec2(.12,.02);float pr=length(pc);
      bc=mix(bc,mix(cr,mix(vec3(.6,1.5,2.1),cr,.25)*fl,hoA(pr-.21,pq)),hoA(pr-.27,pq));
      bc=mix(bc,HOINK,ik*max(hoA(abs(pr-.27)-w*.4,pq),hoA(abs(pr-.21)-w*.35,pq)));
      bc=mix(bc,mix(HOINK,acc2,.3),hoA(length(vec2((fract(hoAt(pc.y,pc.x)*12./TAU)-.5)*TAU/12.*.24,pr-.24))-.008,pq)*zz);
      col=mix(col,bc,hoA(db,pq));
      col=mix(col,HOINK,ik*max(hoA(abs(db)-w*.5,pq),hoA(abs(dfn)-w*.5,pq)*step(0.,db)));
      fq=pc/.2;fs=.2;fm=hoA(pr-.21,pq);
      cA+=col*wT;fqA+=fq*wT;fsA+=fs*wT;fmA+=fm*wT;}
    {float wT=step(abs(tTy-5.),.5);vec3 col=vec3(0.);vec2 fq=q/.4;float fs=.4,fm=1.;
      // contrail: rainbow ribbon with ink seams and travelling sparkles, or puffy cream smoke clouds
      float wv=q.y+.12*sin(q.x*1.3+mt*5.)*clamp(-q.x*.3,0.,1.),xb=(wv/.3+1.)*2.5,bi=clamp(floor(xb),0.,4.);
      vec3 rb=hoC(bi+cs)*1.25*(1.+.6*hoOn(bi+3.));
      rb=mix(rb,mix(rb,HOINK,.75),hoA(abs(fract(xb+.5)-.5)*.12-w*.25,pq)*step(.5,xb)*step(xb,4.5));
      rb=mix(rb,HOCR*1.4,hoA(length(vec2(fract(q.x*.8+mt*3.)-.5,wv*1.5))-.07,pq*.8)*step(.5,fract(q.x*.4+h.x)));
      col=mix(rb,mix(HOCR*.95,mix(HOCR,vec3(.7,1.,1.9),.35),hoA(tdU+.12,pq)),tAux);fm=0.;
    
      cA+=col*wT;fqA+=fq*wT;fsA+=fs*wT;fmA+=fm*wT;}
    {float wT=step(5.5,tTy);vec3 col=vec3(0.);vec2 fq=q/.4;float fs=.4,fm=1.;
      // saucer: striped beam, a disc with a ring of lights that chase on the hats, a glass dome with the pilot face
      float bx=abs(q.x)/max(.2-(q.y+.2)*.45,.02),bs=fract(q.y*7.+mt*5.);
      col=mix(mix(hoC(cs+3.),cr,.5),cr*1.2,step(.5,bs))*(.8+.7*kick);
      col=mix(col,mix(col,HOINK,.75),hoA(abs(bx-1.)*.2-w*.4,pq)*lod);
      float dD=hoEl(q-vec2(0.,-.1),vec2(.98,.34));
      vec3 dsc=mix(base,acc,step(q.y,-.08));
      float la=floor((q.x+.95)/.19),lx=(fract((q.x+.95)/.19)-.5)*.19;
      dsc=mix(dsc,mix(hoC(la+cs),cr*1.3,step(.5,fract(la*.5+tb*2.)))*(1.+1.4*uO2.z+uHat),hoA(length(vec2(lx,q.y+.16))-.06,pq)*lod);
      col=mix(col,dsc,hoA(dD,pq));
      col=mix(col,HOINK,ik*hoA(abs(dD)-w*.5,pq));
      float dG=length(q-vec2(0.,.2))-.33;
      col=mix(col,mix(acc2,mix(vec3(.55,1.4,2.),cr,.3),.75),hoA(dG,pq));
      col=mix(col,HOINK,ik*hoA(abs(dG)-w*.5,pq)*step(-.02,q.y-.1));
      fq=(q-vec2(0.,.2))/.24;fs=.24;fm=hoA(dG+.06,pq);
      cA+=col*wT;fqA+=fq*wT;fsA+=fs*wT;fmA+=fm*wT;}
    col=cA;fq=fqA;fs=max(fsA,.05);fm=fmA;faceM=fm*lod;
#if HD>=1
    {float fmask=1.-fm*(1.-smoothstep(.85,1.1,length(fq)))*lod;
     col=mix(col,hoEngrave(col,q,pq,h.y,acc,acc2,.7),fmask*(1.-hero));
     // printed trim: a thin line of the accent colour just inside the outline
     col=mix(col,acc2,hoA(abs(tdU+.11)-max(.012,pq*.6),pq)*smoothstep(10.,22.,tR/px)*.75*fmask*(1.-hero));}
#endif
#if HD<1
    col=mix(col,acc2,hoA(abs(tdU+.11)-max(.012,pq*.6),pq)*zz*.75*(1.-fm*(1.-smoothstep(.85,1.1,length(fq)))*lod)*(1.-hero)*step(tTy,4.5));
#endif
    // v13 zoom-in ornament: on big characters (from ~55 px radius, full at ~110 px) a fine print of glitter dots in the
    // character's own colours resolves, so zooming in reveals more detail instead of a magnified fill
    float mz=smoothstep(55.*HG,110.*HG,tR/px)*(1.-hero)*step(tTy,4.5);
    if(mz>.002){vec2 g=q*vec2(14.,12.)+vec2(.5*floor(q.y*12.),0.);float dg=length(fract(g)-.5)/14.-.012;
      col=mix(col,col*1.4+acc2*.12,hoA(dg,pq)*mz*.75);}
    // v13 zoomed out (orrery / galaxy): characters smaller than a few pixels take their orbit's colour, so the system
    // reads as rainbow rings made of star-folk instead of confetti (cross-fades in from zoom .55 to .25)
    col=mix(col,hoC(tBand+cs+arm)*(.95+.5*hoBand(tBand))*clamp(dot(col,vec3(.3,.5,.2))/max(dot(base,vec3(.3,.5,.2)),.05),.6,1.3),
      (1.-smoothstep(3.,11.,tR/px))*(1.-hero)*(1.-fPar)*smoothstep(.55,.25,uZoom)*.9);
    col=mix(col,hoFace(col,fq,pq/fs,max(mo,step(0.,eo)*step(eo,.2)*(.3+.6*max(uP2.w,kick))),bl,brk,h,lod,eo),fm);
    // zoomed out (or inside the giant planet) the whole character takes the giant's colour, keeping its light and ink
    col=mix(col,ov.rgb*clamp(dot(col,vec3(.3,.5,.2))/max(dot(base,vec3(.3,.5,.2)),.05),.5,1.35),min(ov.a,1.)*max(smoothstep(.5,.28,uZoom)*.95,gfx*.8));
    col=mix(hoC(tBand+cs)*(.9+.5*hoBand(tBand)),col,mix(1.,smoothstep(3.,10.,tR/px),fPar*(1.-hero)));
  }
  // drop shadows and ink: small, far characters get a deep indigo seam (never a brown net), big ones black ink
  col=mix(col,col*.55+vec3(.02,.01,.06),.6*shC*step(tz,shZ));
#if HD>=1
  {gRho0=rho0;gSp=sp;gTilt=tilt;gYh=yh;gH=H;gRw=Rw;gLg=lg;gZ0=Z0;gSw=sw;gTb=tb;gTr=tr;gRate=rate;gGd=gd;gFGal=fGal;gFPar=fPar;gVsI=vsI;gKick=kick;gBsS=bsS;gSnE=snE;gBrk=brk;gEBig=eBig;gPx=px;gRh=Rh;gT=T;gBE=bE;gSc=sc;
   float rcv=1.-gnd*fPar*step(yh,p.y);
   float hsR=mix(clamp(tR,.02,.12),mix(.055,Rw/max(H/max(uH,1e-5),1.),step(p.y,yh)*fPar),gnd);
   int nS=int(float(HD==1?5:HD==2?8:HD==3?12:HD==4?20:34)*clamp(uDetail/float(HD==1?2.:HD==2?3.:HD==3?4.5:HD==4?6.5:10.),.5,1.6));
   float sh=0.;
   if(rcv>.5&&tz<9e5){
     vec2 L=vec2(.62,.78);
     for(int i=int(min(uZoom,0.));i<nS;i++){float fi=float(i)+.5,ra=sqrt(fi/float(nS)),an=fi*2.39996;
       vec2 off=(L+vec2(cos(an),sin(an))*ra*.22)*hsR*.42;
       sh+=hoCast(p+off,tz);}
     sh/=float(nS);
   }
   col=mix(col,col*.5+vec3(.02,.01,.06),.62*sh*(1.-.75*faceM));}
#endif
  float ink=max(topInk,rimC*step(tz,rimZ));
  col=mix(col,mix(mix(col,vec3(.07,.025,.2),.75),HOINK,smoothstep(10.,26.,tR/px)*(1.-gnd)),ink);
  // ---- v13 air / hats: a holographic sticker sheen, thin bands of light gliding diagonally over the cosmos; brightness =
  // the air level and the hat activity (light only: it lifts the colour underneath, its strongest channel most, so hue and saturation stay)
  col+=1.3*aiA*smoothstep(.55,1.,sin(dot(p0,vec2(2.3,-1.4))*9.-uTime*2.6))*col*col/max(max(col.r,max(col.g,col.b)),.05);
  // ---- hat sparkles: four-point stars pop over the cosmos on the hats / air onsets
  {
    vec2 sg=p0*7.;vec2 si=floor(sg);vec2 sf=sg-si-.5;vec4 sh4=fract(h21(si+floor(tb*2.)*7.13)*vec4(1.,13.7,71.3,313.1));
    sf-=(sh4.xy-.5)*.5;
    float sz=(.16+.26*sh4.z)*(1.+.5*uB2.w+.3*htA)*clamp(htA*1.3+uO2.w+1.4*uB2.w,0.,1.)*step(.45-.3*uB2.w-.1*htA,sh4.w)*(.75+.25*sin(uTime*7.+sh4.z*40.));
    vec2 aq=abs(sf);float ds=(aq.x*aq.y*30.+max(aq.x,aq.y)-sz*.75)/7.;
    col=mix(col,mix(hoC(floor(sh4.z*6.))*2.2,vec3(2.2,2.1,1.8),clamp(1.-4.5*max(aq.x,aq.y)/(sz*.75+1e-3),0.,1.)),hoA(ds,1./uRes.y)*step(.001,sz)*(1.-.9*faceM));
  }
  // ---- drop / phrase wipe: a big-bang hoop of rainbow bands with a ring of star spikes on its leading edge
  if(step(1e-3,wr)*step(wr,1.6)>.5){
    float e=length(p0)-wr,x=(e+.1)/.02,pw=1./(uRes.y*.02);
    col=mix(col,hoC(floor(x)+cs)*1.5,hoA(abs(x-2.5)-2.5,pw));
    col=mix(col,HOINK,smoothstep(pw*1.5,0.,abs(fract(x+.5)-.5)-.04)*step(abs(x-2.5),3.));
  }
  // v13: a touch more chroma so the added light (sheen, sparkles, lit belts) never pales the cosmos
  col=mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.1)*1.06;
  fragColor=vec4(max(col,0.),0.);
}
`;
