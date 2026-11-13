const R_FLUX = `
float fluxSmooth(float a,float b,float x){float d=b-a;if(abs(d)<1e-7)return step(a,x);float t=clamp((x-a)/d,0.,1.);return t*t*(3.-2.*t);}

// ISOBAR. A living scalar field (orbiting charges / vortices, liquid metaballs, rippling wave sources, or a
// domain-warped landscape) cut into finely nested contour bands and printed like a screenprint / paper-cut atlas:
// crisp ink separation lines, bold index bands in flat, metallic or holographic foil, stacked paper layers that
// cast real shadows, halftone shading, an overprinted second contour map at another scale, and beyond the music's
// own system a whole atlas of terrain and distant pressure systems with a graticule. Each source owns one slice of
// the spectrum (source 0 = sub ... 5 = air), swells with it and flashes its own rings on that band's onsets; kicks
// fire rings through the contours; snares step the colour plates; highs light nested hairlines; hi-mids sweep the
// foil; distant systems each pulse with one band. A loupe or an inset map sheet magnifies one source.
vec2 gR1,gR2;
vec3 gC0,gC1,gC2,gC3,gC4,gC5;
vec4 gFo;
float gRb,gRgl;
float gFam,gP,gVort,gK,gPh,gFt,gWph,gStr,gF,gSw,gT,gOn,gWt,gGh,gGb,gGd;
vec4 gRg,gO1,gO2,gB1,gB2;
vec2 gSD;float gZm,gTg;
float fxWind(float i){float h=fract(sin(i*12.9898+uSeed.x*78.233)*43758.5);return mix(mix(1.-2.*step(.38,h),2.,step(.76,h)),-2.,step(.9,h));}
// source i: position, base weight, spectrum level and onset come from JS (uM1/uM2 rows: x, y,
// weight*4096 + level*16 + onset). Hidden sources sit on their parent with zero weight, so a change of the source
// count splits / merges them.
vec2 fxU(float v,float d){float h=floor(v/d+.5/d);return vec2(v-h*d,h);}   // v: a non-negative integer (+-.4)
vec4 fxS(float i){
  vec3 a=max(1.-abs(i-vec3(0,1,2)),0.),b=max(1.-abs(i-vec3(3,4,5)),0.),m=uM1*a+uM2*b;
  vec2 a1=fxU(m.z,16.),a2=fxU(a1.y,256.);
  float sp=a2.x/255.,z=a2.y/4095.*2.;
  gOn=a1.x/15.;
  float sg=mix(1.-2.*step(fract(sin(i*7.13+uSeed.y*31.7)*43758.5),.3)*step(.5,i),1.,gFo.y);
  return vec4(m.xy,z*sg*(1.+.3*gSw+.45*sp),sp);
}
float fxNz(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
  vec4 h=fract(sin(dot(i,vec2(1.,57.))+vec4(0.,1.,57.,58.))*43758.545);return mix(mix(h.x,h.y,f.x),mix(h.z,h.w,f.x),f.y);}
float fxFbm(vec2 q,int oct,float gn){
  float a=.5,s=0.;mat2 m=mat2(1.6,1.2,-1.2,1.6);
  for(int i=0;i<16;i++){if(i>=oct)break;s+=a*fxNz(q);q=m*q+vec2(1.7,9.2);a*=gn;}
  return s;
}
// the landscape: frequency rises in macro views, so a close look never lands on a featureless slope
float fxTer(vec2 q,int oct){return fxFbm(q*mix(.46,.62,gFo.w)*(1.+1.4*gZm)+vec2(.3+gFt*.05,.3+.12*sin(q.x*1.3+gFt*.2)),oct,gTg);}
// atan2 (polynomial, ~1e-5 rad): much cheaper on D3D than the emulated atan
float fxAt(float y,float x){vec2 a=abs(vec2(x,y));float t=min(a.x,a.y)/max(max(a.x,a.y),1e-9),s=t*t;
  float r=((-.0464965*s+.1593142)*s-.3276228)*s*t+t;r=mix(r,1.5707963-r,step(a.x,a.y));r=mix(r,3.1415927-r,step(x,0.));return r*sign(y+1e-20);}
float gFA,gFC,gRip,gPsi,gFlt;
// v19 the flow net: gPsi counts whole turns around the sources (integer windings, so it has no seam) and runs across the contours
// v19 domain folds, applied after the warp: 0 inkblot mirror, 1 mirrored wallpaper of the whole system, 2 n-fold angle multiplication (z^n/r^(n-1)), 3 tectonic slip strips
vec2 fxDom(vec2 q,float m,float n,float a){
  if(m<.5)return vec2(mix(q.x,abs(q.x)-.12*a,a),q.y);
  if(m<1.5){vec2 s=vec2(1.5,1.14),g=abs(mod(q+s*.5,2.*s)-s)-s*.5;return mix(q,g,a);}
  if(m<2.5){vec2 z=q;float r=max(length(q),1e-4);for(int i=1;i<4;i++){if(float(i)>=n)break;z=vec2(z.x*q.x-z.y*q.y,z.x*q.y+z.y*q.x)/r;}return mix(q,z,a);}
  vec2 c=vec2(q.x*.94+q.y*.34,q.y*.94-q.x*.34)*1.25+vec2(.37,.11);
  float j=floor(c.y),h=fract(sin(j*12.9898+uSeed.x*53.1)*43758.5);
  gFlt=(.5-abs(c.y-j-.5))/1.25;
  return q+vec2(.94,-.34)*a*(h*2.-1.)*(.16+.2*fract(h*7.3));
}
vec2 fxT(vec2 q,vec4 s,float i){
  vec2 d=q-s.xy;float r2=dot(d,d);
  float rb=.12+.05*fract(i*.618+uSeed.y),r=sqrt(r2);
  r+=gRip*sin(30.*r-gWph+i*1.7)*exp(-r*1.4)*fluxSmooth(0.,.08,r);  // pressure waves leave each source
  float ang=fxAt(d.y,d.x+1e-7);gPsi+=step(.001,abs(s.z))*sign(s.z)*ang/TAU;
  return vec2(mix(-gFA*s.z*log((r*r+gFC)/(1.+r*r*.5)),s.z*rb*rb/(r2+rb*rb),gFo.y),gVort*fxWind(i)*gP/TAU*ang);
}
// v20b: small pressure systems for the inner map, one per cell of a grid (compact, so cells never seam): a high or a low with its own reach; gSyH: the hash of the system here
float gSyH;
float fxSys(vec2 g){
  vec2 ci=floor(g),cf=g-ci-.5;
  float hs=fract(sin(dot(ci,vec2(12.99,78.23))+uSeed.x*37.)*43758.5);
  vec2 o=(vec2(hs,fract(hs*7.13))-.5)*.14;
  float bm=max(1.-dot(cf-o,cf-o)*mix(5.6,8.,fract(hs*5.37)),0.);
  if(bm>0.)gSyH=hs;
  return bm*bm*mix(1.,-.85,step(fract(hs*3.1),.42));
}
// one of the 8 band values (k = 0 sub ... 7 air)
float fxBand(vec4 a,vec4 b,float k){return dot(a,max(1.-abs(k-vec4(0,1,2,3)),0.))+dot(b,max(1.-abs(k-vec4(4,5,6,7)),0.));}
// finish the field in band units (u): integer crossings are contour lines. t = summed source terms.
float fxFin(vec2 t,vec2 q){
  float f=t.x*(1.-.35*gStr);
  // strata: a tilted linear gradient replaces the radial falloff, so the sources bend stacked layers
  float sy=dot(q,gSD)+.045*sin(q.x*2.3+gFt*.9);
  float r=length(q*vec2(.75,1.));
  f-=(gFo.x+gFo.z)*mix(1.3*r/(1.+.75*r),2.3*sy+.35,gStr);
  f=mix(f,log(max(f*(1.-.3*gStr),0.)+.018)-gStr*3.4*sy,gFo.y);
  // the atlas: beyond the music's own system the field becomes a landscape with distant pressure systems,
  // one per 2.2-unit cell (compact, so cells never seam), each listening to one band
  gWt=fluxSmooth(.5,1.6,r);
  vec2 cq=q/2.2+.5,ci=floor(cq),cf=cq-ci-.5;
  float hs=fract(sin(dot(ci,vec2(12.99,78.23))+uSeed.x*91.)*43758.5);
  vec2 o=(vec2(hs,fract(hs*7.13))-.5)*.3;
  // v13: far out (zoom < .5) the systems thin out one by one (a smooth fade, never a pop), so the .15 atlas is calmer
  float zfar=(1.-fluxSmooth(.15,.5,uZoom)),thS=.22+.4*zfar;
  float bm=max(1.-dot(cf-o,cf-o)*mix(6.,22.,fract(hs*5.37)),0.);bm*=bm*bm*step(.5,length(ci))*fluxSmooth(thS,thS+.1,fract(hs*9.13));
  gGh=bm;gGb=floor(fract(hs*13.7)*8.);gGd=length(cf-o)*2.2;
  f+=mix(gWt*((2.1-1.05*zfar)*(gT-.45)+mix(2.1,-1.7,step(fract(hs*3.1),.45))*bm),1.25*gT-gStr*1.1*sy,gFo.w);
  gF=f;
  return gK*f+t.y+gPh+.4*gRb;
}
#define FX0 min(int(uTime),0)
vec4 gSrc[6];
// re-evaluate the field somewhere else, with no side effects on the current pixel (stations, real shadow and occlusion rays, foil dispersion, the under-sheet)
float fxEv(vec2 q,int oct){
  float s0=gGh,s1=gGb,s2=gGd,s3=gWt,s4=gT,s5=gF,s6=gPsi;
  vec2 a=vec2(0.);
  for(int i=FX0;i<6;i++){a+=fxT(q,gSrc[i],float(i));}
  gT=fxTer(q,oct);
  float u2=fxFin(a,q);
  gGh=s0;gGb=s1;gGd=s2;gWt=s3;gT=s4;gF=s5;gPsi=s6;
  return u2;
}
#if HD>=1
// v19 detail tiers: loop ceilings by HD (runtime counts come from uDetail), loops start at a zero the HLSL compiler cannot fold
#if HD>=5
#define FX_SHM 200
#define FX_AOM 120
#define FX_HLM 7
#define FX_SS 4.
#define FX_MIC 3
#elif HD>=4
#define FX_SHM 110
#define FX_AOM 64
#define FX_HLM 6
#define FX_SS 3.
#define FX_MIC 3
#elif HD>=3
#define FX_SHM 64
#define FX_AOM 36
#define FX_HLM 5
#define FX_SS 2.
#define FX_MIC 3
#elif HD>=2
#define FX_SHM 40
#define FX_AOM 24
#define FX_HLM 4
#define FX_SS 1.5
#define FX_MIC 2
#else
#define FX_SHM 24
#define FX_AOM 16
#define FX_HLM 3
#define FX_SS 1.
#define FX_MIC 1
#endif
#endif
vec3 fxCol(float v){v+=.01;float a=floor(v/65536.),b=floor(v/256.);return vec3(a,b-a*256.,floor(v)-b*256.)/255.;}
// colour ramp (gamma space). st 0: ping-pong ramp, 1: stripes on ink, 2: neon, 3: sawtooth with index bands
vec3 fxRamp(float t,float st){
  float tt=fract(t/gP)*gP,x=mix(4.-abs(4.-tt/gP*8.),min(tt/(gP-1.)*4.,4.*(gP-tt)),step(2.5,st));
  return gC0+(gC1-gC0)*clamp(x,0.,1.)+(gC2-gC1)*clamp(x-1.,0.,1.)+(gC3-gC2)*clamp(x-2.,0.,1.)+(gC4-gC3)*clamp(x-3.,0.,1.);
}
vec3 fxSrgb(vec3 c){return c*(.8+.2*c);}
float fxBox(vec2 p,vec2 b,float r){vec2 d=abs(p)-b+r;return length(max(d,0.))+min(max(d.x,d.y),0.)-r;}
float s8f(float x){x*=x;x*=x;x*=x;return x*x*x;}
float fxSeg(vec2 p,vec2 a,vec2 b){vec2 pa=p-a,ba=b-a;return length(pa-ba*clamp(dot(pa,ba)/max(dot(ba,ba),1e-8),0.,1.));}
// v20 ornaments printed in a flow-net cell, in pixels: g along and across the band (-.5 to .5), cell size c by by. Returns colour and coverage.
vec4 fxStrand(float d,float hw,vec3 c,vec3 ink,float rs){
  float t=clamp(d/max(hw,.01),-1.,1.),sh=.58+.62*sqrt(1.-t*t);
#if HD>=1
  {float hl=abs(fract(d/max(hw,.01)*2.5+.25)-.5)*hw/2.5,cl=clamp(.45*rs-hl+.5,0.,1.)*clamp(hw/(3.*rs)-.8,0.,1.);c=mix(c,c*.72,cl*.75);}
#endif
  return vec4(mix(c*sh,ink,clamp(1.05*rs-(hw-abs(d))+.5,0.,1.)*.9),clamp(hw-abs(d)+.5,0.,1.));
}
float fxBit(float v,float c){return mod(floor(v/exp2(c)+.01),2.);}
float fxMeander(float r,float c){c=mod(c,6.);return fxBit(r<.5?63.:r<1.5?1.:r<2.5?29.:r<3.5?17.:r<4.5?31.:0.,c);}
vec4 fxOrn(float k,vec2 g,float c,float by,float hh,float lit,vec3 c0,vec3 c1,vec3 ink,vec3 acc,vec3 lite,float rs){
  vec2 P=g*vec2(c,by);float s=min(c,by);
  if(k<4.5){   // strung pearls
    float R=.45*s,d=length(P),n=d/max(R,.01),sh=sqrt(max(1.-n*n,0.));
    vec2 l=P/max(R,.01)+vec2(.36,-.36);
    vec3 C=c0*(.42+.82*sh)*(1.+1.1*lit)+vec3(1.,.97,.92)*.85*pow(max(1.-dot(l,l)*3.4,0.),3.);
#if HD>=1
    {float rg=abs(fract(n*5.+.5)-.5)*R/5.,ca=clamp(.4*rs-rg+.5,0.,1.)*clamp(R/(5.*rs)-.7,0.,1.);C=mix(C,C*1.45+vec3(1.,.97,.92)*.08,ca*.65);}
#endif
    return vec4(mix(C,ink,clamp(1.05*rs-(R-d)+.5,0.,1.)*.92),clamp(R-d+.5,0.,1.));
  }
  if(k<5.5){   // a two-strand rope: the over strand swaps half way between crossings
    float A=.25*by,hw=.22*by,ph=g.x*TAU,y1=A*sin(ph),sl=1./sqrt(1.+pow(A*TAU/max(c,.01)*cos(ph),2.));
    vec4 a=fxStrand((P.y-y1)*sl,hw,mix(acc,c0,.2)*(1.+.9*lit),ink,rs),b=fxStrand((P.y+y1)*sl,hw,mix(lite,c0,.3),ink,rs);
    if(cos(ph)>0.){vec4 t=a;a=b;b=t;}
    return vec4(mix(a.rgb,b.rgb,b.a),max(a.a,b.a));
  }
  if(k<6.5){   // basket weave, three strands to a band
    vec2 h=vec2((g.x+.5)*2.,(g.y+.5)*3.),i=floor(h),f=h-i-.5;
    float ov=mod(i.x+i.y,2.),t=mix(f.y,f.x,ov),e=mix(f.x,f.y,ov),pT=mix(by/3.,c*.5,ov);
    float sh=.6+.55*(1.-4.*t*t)-.34*pow(2.*abs(e),5.);
    vec3 C=mix(c0,mix(acc,lite,step(.5,fract(hh*3.7))),ov*.85)*sh*(1.+.8*lit*ov);
#if HD>=1
    {float th=abs(fract(t*5.+.25)-.5)*pT/5.,cl=clamp(.4*rs-th+.5,0.,1.)*clamp(pT/(5.*rs)-.7,0.,1.);C=mix(C,C*.7,cl*.8);}
#endif
    return vec4(mix(C,ink,clamp(1.05*rs-(.5-abs(t))*pT+.5,0.,1.)*.85),1.);
  }
  if(k<7.5){   // an eight-point star on every cell, with a jewelled octagon inside
    vec2 a=abs(P);float m=max(a.x,a.y),dm=(a.x+a.y)*.7071,R=.44*s,d=min(m,dm)-R,d2=max(m,dm)-R*.52;
    vec3 C=mix(c0*(1.+1.1*lit),mix(acc,lite,step(.5,fract(hh*3.7)))*1.1,clamp(.5-d2,0.,1.));
#if HD>=1
    {float d3=max(m,dm)-R*.28,d4=abs(fract(length(P)/max(R,.01)*7.)-.5)*R/7.;C=mix(C,mix(lite,vec3(1.,.97,.92),.5)*1.25,clamp(.5-d3,0.,1.));C=mix(C,C*.72,clamp(.35*rs-d4+.5,0.,1.)*clamp(R/(5.*rs)-.8,0.,1.)*clamp(-d2-1.,0.,1.));}
#endif
    C=mix(C,ink,max(clamp(1.05*rs-abs(d)+.5,0.,1.),clamp(.75*rs-abs(d2)+.5,0.,1.))*.9);
    return vec4(C,clamp(.5-d,0.,1.));
  }
  if(k<8.5){   // Greek key: a 6 by 5 meander, a bit per block
    vec2 h=vec2((g.x+.5)*6.,(g.y+.5)*5.),i=floor(h),f=h-i-.5;
    float v=fxMeander(i.y,i.x),vx=fxMeander(i.y,i.x+sign(f.x+1e-4)),vy=fxMeander(i.y+sign(f.y+1e-4),i.x);
    float cx=c/6.,cy=by/5.,ex=(.5-abs(f.x))*cx,ey=(.5-abs(f.y))*cy;
    float cov=mix(.5*(v+vx),v,clamp(ex*2.,0.,1.));cov=mix(.5*(cov+vy),cov,clamp(ey*2.,0.,1.));
    vec3 kc=mix(ink,mix(acc,lite,step(.5,fract(hh*3.7)))*1.15,.12+.88*lit);
#if HD>=1
    {float e0=min(ex,ey),cl=clamp(.42*rs-abs(e0-.32*min(cx,cy))+.5,0.,1.)*clamp(min(cx,cy)/(3.2*rs)-.8,0.,1.);kc=mix(kc,mix(acc,lite,.5)*1.3,cl*.85);}
#endif
    return vec4(kc,cov*.95);
  }
  // herringbone: chevrons at 45 degrees, in two inks
  float v=(P.y+abs(P.x)*(mod(floor(hh*2.),2.)*2.-1.))/max(by/3.,.01)+7.,n=floor(v),d=(.5-abs(fract(v)-.5))*by/3.;
  vec3 C=mix(c0,mix(acc,c1,fract(n*.25)),step(.5,fract(n*.5)))*(1.+.8*lit*step(.5,fract(n*.5)));
#if HD>=1
  {float cc=abs(fract((P.x-P.y)/max(by/9.,.01))-.5)*by/9.;C=mix(C,C*.74,clamp(.4*rs-cc+.5,0.,1.)*clamp(by/(9.*3.*rs)-.7,0.,1.)*.8);}
#endif
  return vec4(mix(C,ink,clamp(.95*rs-d+.5,0.,1.)*.7),1.);
}
// one ornament layer along a band: the cell count follows the band's own width, cross-faded between two counts
vec4 fxOrnLayer(float k,float b,float fr,float bpx,float pw,float co,float st,vec3 ink,vec3 acc,vec3 lite,float rs,float txA,int nL){
  if(k<0.)return vec4(0.);
  float Nk0=12.*exp2(mod(b,3.)),cp0=1./(pw*Nk0),Lr=log2(max(cp0/(1.25*bpx),.2)),L0=floor(Lr),Lf=clamp((Lr-L0-.4)/.3,0.,1.);
  vec4 o=vec4(0.);
  for(int i=0;i<2;i++){if(i>=nL-4)break;
    float w=mix(1.-Lf,Lf,float(i));
    if(w>.02){
    float Nn=Nk0*exp2(L0+float(i)),v=gPsi*Nn+.5*mod(b,2.),j=floor(v),f=v-j;
    float hh=h21(vec2(mod(b,64.)+float(i)*17.,mod(j,Nn))),cp=1./(pw*Nn);
    float lit=fxBand(gO1,gO2,floor(fract(hh*13.)*8.));
    vec3 c0=fxSrgb(fxRamp(b+co+floor(hh*5.)*gP/8.,st)),c1=fxSrgb(fxRamp(b+co+gP*.5,st));
    vec4 t=fxOrn(k,vec2(f-.5,fr-.5),cp,bpx,hh,lit,c0,c1,ink,acc,lite,rs);
    t.a*=clamp(cp/(5.*rs)-.5,0.,1.)*clamp((txA*1.25-hh)*7.,0.,1.);
    o+=w*vec4(t.rgb*t.a,t.a);}
  }
  return vec4(o.rgb/max(o.a,1e-4),o.a);
}
void realm(){
  float clk=uP1.x;
  float tq=floor(uP1.y/64.);gK=uP1.y-64.*tq;gPh=uP1.z;float co=uP1.w;
  // unpack (integer fields, low bits first)
  vec2 k1=fxU(uP2.y,4096.),k2=fxU(uP2.z,4096.);
  float swirl=(k1.x/4095.-.5)*10.,zs=k1.y/4095.*2.-1.,zm=max(zs,0.),za=max(-zs,0.);
  gSw=k2.x/4095.*2.;float warp=k2.y/4095.*2.;
  vec2 c1=fxU(uP3.x,4.),c2=fxU(c1.y,4.),c3=fxU(c2.y,16.),c4=fxU(c3.y,2.),c5=fxU(c4.y,2.),c6=fxU(c5.y,2.),c7=fxU(c6.y,2.),c8=fxU(c7.y,4.);
  gFam=c1.x;float st=c2.x,M=c3.x;gP=8.+8.*c4.x;gVort=c5.x;
  vec2 c9=fxU(c8.y,256.);
  float iShape=c6.x,iSty=c7.x,foil=c8.x,iam=c9.x/255.,dmM=c9.y;
  // composition (eased per phrase in JS): zm = macro zoom onto the focus, za = atlas pull-back,
  // isl = islands on a dark sea, gStr = stacked strata / horizon, ovp = overprinted second contour map
  vec2 nq=fxU(uP2.x,1024.),r1=fxU(uP3.w,8.),r2=fxU(r1.y,8.),r3=fxU(r2.y,256.),h1=fxU(uP4.x,4096.);
  vec2 nq2=fxU(nq.y,256.);
  vec2 nq3=fxU(nq2.y,16.);
  float chs=nq3.x,txH=nq3.y;
  float isl=nq.x/1023.,ovp=nq2.x/255.,r1i=r1.x,r2i=r2.x,bE=r3.x/255.;gStr=r3.y/511.;
  float hph=h1.x/4096.,fsw=h1.y/4095.*TAU;
  float tl=.2*sin(clk*.23+uSeed.w*6.3);gSD=vec2(sin(tl),cos(tl));
  {vec2 a=fxU(uP3.y,16384.),b=fxU(uP3.z,16384.);gRg=vec4(a.x/4096.,a.y/1023.*2.5,b.x/4096.,b.y/1023.*2.5);}
  int nL=6+int(min(uTime,0.));   // opaque bound: keeps the HLSL compiler from unrolling the loops
  vec4 fo=max(1.-abs(gFam-vec4(0,1,2,3)),0.);gFo=fo;   // family one-hot
  // view: the focus (glides between two sources), macro zoom in, atlas pull-back, the user's zoom
  vec2 fx1=fxU(uP5.w,16384.),fy1=fxU(uP2.w,16384.),tp1=fxU(fy1.y,64.),tp2=fxU(tp1.y,4.);
  vec2 fF=vec2(fx1.x,fy1.x)/8192.-1.;
  float dmA=fx1.y/1023.,txA=tp1.x/63.,txK=tp2.x+4.*txH,dmN=tp2.y+2.;
  float A=mix(1.,.34,zm)*(1.+1.6*za)*1.12/uZoom;   // screen -> map scale
  vec2 off=zm*(fF-vec2(.22,.05)*A);
  vec2 p0=scr();
  float tk=tq/255.*.8*min(1.,.45+uZoom);
  vec2 fS=(fF-off)/A;   // focus on screen (through the paper tilt)
  fS.y=fS.y*(1.-.5*tk)/max(1.+tk*fS.y,.05);fS.x*=1.-tk*(fS.y+.5);
  // the loupe: a lens over the focus that magnifies it (frame: metal bezel or a paper ring)
  float iR=.19*(.72+.28*min(uZoom,2.5))*iam;
  vec2 iL=p0-fS;
  float iD=length(iL)-iR,iMg=2.5+.5*gSw;
  float inI=step(iD,0.)*step(.002,iam);
  // the paper tilt: the sheet leans back, so the map recedes towards a far horizon at the top
  float ps=1./(1.-tk*(p0.y+.5));
  vec2 p=mix(p0*ps*A+off,fF+iL*A/iMg,inI);
  float px=max(A*ps/uRes.y/mix(1.,iMg,inI),1e-6);
  gK*=(1.+inI*(.62*iMg-1.))*(1.+.2*zm);
  st=mix(st,mix(2.,3.*fo.x,max(1.-abs(st-2.),0.)),inI*iSty);   // the inset prints in a contrasting style
  vec4 so=max(1.-abs(st-vec4(0,1,2,3)),0.);       // style one-hot
  float nf=so.z;
  float la=uSeed.z*TAU+.05*uMT;
  gFt=clk*.35+uTime*.02;{float pm=gP*M*4.;gWph=gPh*TAU*floor(.33*pm+.5)/pm+clk*2.;}
  gFA=dot(fo,vec4(.5,.32,.32,.16));gFC=dot(fo,vec4(.0035,.004,.004,.006));gRip=.022*fo.z;
  gC0=fxCol(uP4.y);gC1=fxCol(uP4.z);gC2=fxCol(uP4.w);gC3=fxCol(uP5.x);gC4=fxCol(uP5.y);gC5=fxCol(uP5.z);
  // flowing domain: a slow liquid warp and a swirl that tightens towards the centre
  vec2 q=p;
  {float wf=1.+1.8*fo.y;
   q+=(warp*.05+.028*fo.y)*vec2(sin(q.y*1.9*wf+gFt*1.3+(.6+fo.y)*sin(q.x*2.3*wf-gFt*1.7)),sin(q.x*1.5*wf-gFt*1.1+1.+(.6+fo.y)*sin(q.y*2.1*wf+gFt*1.9)));}
  q=rot(swirl*exp(-dot(q,q)*1.6))*q;
  gFlt=1.;
  if(dmA>.002)q=fxDom(q,dmM,dmN,dmA);
  // the landscape under everything (terrain family, the atlas, the overprinted map)
  {int oc=int(clamp(5.+.5*log2(max(uDetail,1.)),3.,6.));
   gZm=zm;gTg=mix(.4,.5,fo.w);
#if HD>=1
   oc=max(oc,int(clamp(log2(.5/(px*mix(.46,.62,fo.w)*(1.+1.4*zm)))-.5,float(oc),float(9+HD))));
#endif
   gT=fxTer(q,oc+1-int(fo.w));}
  // one pass over the sources: field terms, ring origins, jewels, each source's onset light
  vec2 tA=vec2(0.),jV=vec2(0.);float jD=0.,jR=0.,jG=0.,jS=0.,jz=sqrt(A/1.12),oL=0.,jLv=0.,jO=0.,jSg=1.;
  gR1=vec2(0.);gR2=vec2(0.);gPsi=0.;
  for(int i=0;i<6;i++){
    if(i>=nL)break;
    float fi=float(i);
    vec4 sc=fxS(fi);
    gSrc[i]=sc;
    if(abs(fi-r1i)<.5)gR1=sc.xy;
    if(abs(fi-r2i)<.5)gR2=sc.xy;
    tA+=fxT(q,sc,fi);
    float lv=clamp(abs(sc.z)*2.,0.,1.);
    float d=length(q-sc.xy),rj=(.006+.02*sc.w*sc.w+.003*gSw)*lv*jz;
    float disc=clamp((rj-d)/px+.5,0.,1.);
    if(disc>jD){jV=q-sc.xy;jR=rj;jLv=sc.w;jO=gOn;jSg=sign(sc.z+1e-6);}
    jD=max(jD,disc);jS=max(jS,disc*(sc.w+gOn));
    oL+=gOn*lv*exp(-d*d/(.012+.03*sc.w));   // a smooth light swell around the source on its band's onsets
  }
  // smoothed (JS) band levels / onsets of the six sources stand in for the raw uB / uO uniforms (sources sit on
  // bands 0,2,3,4,6,7; the two gaps interpolate)
  {vec3 za=vec3(uM1[0].z,uM1[1].z,uM1[2].z),zb=vec3(uM2[0].z,uM2[1].z,uM2[2].z);
   vec3 ra=floor(za/16.+.03),rb=floor(zb/16.+.03),na=(za-16.*ra)/15.,nb=(zb-16.*rb)/15.,sa=(ra-256.*floor(ra/256.+.002))/255.,sb=(rb-256.*floor(rb/256.+.002))/255.;
   gB1=vec4(sa.x,.5*(sa.x+sa.y),sa.yz);gB2=vec4(sb.x,.5*(sb.x+sb.y),sb.yz);
   gO1=vec4(na.x,.5*(na.x+na.y),na.yz);gO2=vec4(nb.x,.5*(nb.x+nb.y),nb.yz);}
  // kick rings: a travelling bulge in the contours, a glide of the colour plates and a thin bright crest
  gRb=0.;gRgl=0.;
  for(int k=0;k<2;k++){if(k>=nL-4)break;float kf=float(k);
    vec2 rr=mix(gRg.xy,gRg.zw,kf);float d=length(q-mix(gR1,gR2,kf))-rr.x,x=d/(.07+.07*rr.x),ex=exp(-x*x);
    gRb+=rr.y*ex;gRgl+=rr.y*ex*(1.-.3*kf);}
  float u=fxFin(tA,q),fP=gF;
  // gradient in band units per pixel (wrapped: vortex branch cuts jump by whole ramp periods)
  float dx=dFdx(u),dy=dFdy(u);
  dx-=gP*floor(dx/gP+.5);dy-=gP*floor(dy/gP+.5);
  vec2 g=vec2(dx,dy);float w=max(length(g),1e-5);
  vec2 gn=g/w;
  float b=floor(u),fr=u-b;
  float hf0=step(.5,fr);
  float e=fr-hf0;
  float nb=b-1.+2.*hf0;
  float dpx=abs(e)/w;
  // the kick ring: a travelling wave that bulges the contours and steps the colour plates as it passes
  float rg=gRgl;
  float cr=floor(co+.5);
  co+=min(rg,1.2)*.45;
  float lod=fluxSmooth(.09,.32,w); // early pixel-footprint filtering prevents contour shimmer
  vec3 ink=fxSrgb(gC0)*.18+vec3(.004,.002,.008);
  vec3 acc=fxSrgb(gC5)*1.25,lite=fxSrgb(gC4);
  float isA0=step(fract(b/M),.5/M);   // index bands stay on their contours (the plates flow under them)
  float cov=clamp(.5-dpx,0.,.5);
  vec3 col,rA=vec3(0.),sRaw=vec3(0.);
  float mb=step(.25,fract(b*.5)),ev=b-mb+2.*mb*step(b,nb);
  for(int k=0;k<2;k++){
    if(k>=nL-4)break;
    float kf=float(k);
    vec3 r=fxSrgb(fxRamp(mix(mix(b+(nb-b)*cov,ev,so.y),u-.5,kf)+co,st*(1.-so.y)));
    rA+=r*(1.-kf);sRaw+=r*kf;
  }
  vec2 fc=gl_FragCoord.xy;
  float rs=uRes.y/1080.,hpch=max(4.6,5.6*rs);
  vec2 hc=rot(.26)*fc/hpch;float hd=length(fract(hc)-.5)*hpch;
  // neon fills: ink, and out in the atlas lowlands the deep plate colour (luminous, never muddy)
  vec3 dpl=fxSrgb(mix(gC0,gC1,.35));
  vec3 inkS=mix(ink*1.6,fxSrgb(fxRamp(ev+co+gP*.5,0.))*.5,fluxSmooth(150.,430.,1./w/rs)*so.y);
  col=mix(mix(rA,mix(rA*1.1,inkS,mix(mb,1.-mb,cov)),so.y),ink*1.4+rA*.24+dpl*(.42+.3*gWt),nf);
  vec3 smoothC=mix(mix(sRaw,mix(ink*1.6,sRaw,.5),so.y),ink*1.4+sRaw*.5+dpl*.2,nf);
  // accent (index) bands: a bold stripe of accent ink inside the band, framed by hairlines
  float inS=abs(fr-.5)/w;float halfS=min(.26/w,(9.+60.*(1.-gWt))*rs);
  float ast=isA0*clamp((halfS-inS)*.8+.5,0.,1.)*(1.-lod);
  col=mix(col,smoothC,lod);
  // v19 a very wide band (a calm stretch of the field, a macro view) never sits flat or on the dark end of the ramp:
  // its fill terraces into sub-bands of the ramp, each cross-faded in by width, and the darkest plate lifts to a midtone
  float bw0=1./w/rs;
  if(bw0>170.){
    float wd=fluxSmooth(170.,520.,bw0),sk=max(log2(bw0/110.),1.),s0=floor(sk),sf=sk-s0;
    vec3 tA=vec3(0.);
    for(int k=0;k<2;k++){if(k>=nL-4)break;float sn=exp2(s0+float(k));tA+=mix(1.-sf,sf,float(k))*fxSrgb(fxRamp(b+co+floor(fr*sn)/sn*mix(2.2,3.,so.y),st*(1.-so.y)));}
    float yL=dot(col,vec3(.3,.59,.11)),dk=wd*fluxSmooth(.3,.06,yL);
    col=mix(col,tA,wd*(.55+.45*nf));
    col=mix(col,max(col,fxSrgb(mix(gC1,gC2,.6))*.85),dk);
  }
  // v20 the inner map: a band wide enough to hold it carries a finer survey of its own, printed in terraces of the ramp's neighbouring inks with its own contour line.
  // Scale follows the view by whole octaves (cross-faded), so zooming in keeps finding new ground; alternate terraces pump on the mids.
  {float imA=fluxSmooth(34.,84.,bw0)*(1.-lod);
   if(imA>.003){
     float lvI=log2(1.12/A),l0=floor(lvI),lf=clamp((lvI-l0-.3)/.4,0.,1.),tv=0.,sy=0.;gSyH=0.;
     for(int k=0;k<2;k++){if(k>=nL-4)break;
       float F=9.*exp2(l0+float(k)),wg=mix(1.-lf,lf,float(k));
       if(wg>.01){
#if HD>=1
       int oIm=int(clamp(4.+.7*uDetail,4.,9.));
#else
       int oIm=3;
#endif
       tv+=wg*fxFbm(q*F+vec2(3.1+float(k),-1.7),oIm,.44);
       // v20b: systems on two staggered grids, a few across the frame; they take over from the fbm as the band widens
       sy+=wg*(fxSys(q*F*.1+vec2(.37,.21))+.85*fxSys(rot(.9)*q*F*.1*1.31+vec2(5.5,2.5)));}}
     float wdI=fluxSmooth(170.,700.,bw0),wdS=fluxSmooth(240.,760.,bw0);
     tv=tv*(1.-.66*wdS)+1.15*wdS*sy;
     tv=tv*(8.+4.*wdI)+fr*2.+b*.37;
     float tb=floor(tv),tw=max(length(vec2(dFdx(tv),dFdy(tv))),1e-4),tf=(.5-abs(tv-tb-.5))/tw,imF=clamp(.45/tw-.25,0.,1.)*imA;
     vec3 tc=fxSrgb(fxRamp(b+co+(mod(tb,4.)-1.5)*(.55+.75*wdI)*(1.+.9*wdS*(1.-so.w))*gP/8.,st*(1.-so.y)));
     tc*=1.+.75*max(gO1.z,gO1.w)*step(mod(tb,3.),.5);
     // v20b: islands on a deep sea. Inside a system the rings are four inks (one of them deep ink), ruled in bold ink, and each system flashes on its own band's
     // onsets; outside them the ground sinks to two deep tones of the map's own plate, with a lit shoreline between
     float sa=abs(sy),sw=max(length(vec2(dFdx(sy),dFdy(sy))),1e-5),shore=clamp((sa-.05)/sw+.5,0.,1.);
     tc=mix(tc,inkS*(.72+.5*step(.5,fract(tb*.5)))*(1.+1.7*uHit),so.y*mix(mb,1.-mb,cov)*.9*fluxSmooth(110.,260.,bw0));
     tc=mix(tc,ink*1.7+tc*.22,wdS*step(mod(tb,4.),.5));
     tc*=1.+1.1*wdS*fxBand(gO1,gO2,floor(gSyH*7.99));
     tc=mix(tc,mix(mix(ink*1.9+dpl*.3,ink*1.2+dpl*.62,step(.5,fract(tb*.5))),tc,shore),wdS);
     col=mix(col,tc,imF*mix(.66+.26*wdI,1.,wdS)*(1.-.6*nf));
     col=mix(col,ink*1.15+col*.3,clamp((.62+.7*wdS)*rs-tf+.5,0.,1.)*imF*mix(.8,.95,wdS));
     col=mix(col,lite*1.15,clamp(1.1*rs-abs(sa-.05)/sw+.5,0.,1.)*wdS*imF*(1.-.6*nf));
#if HD>=1
     // finer soundings of the same ground, one more ring of lines inside each terrace
     {float t3=tv*3.+.5,tb3=floor(t3+.5),tw3=tw*3.,c3=clamp(.5*rs-abs(t3-tb3)/tw3+.5,0.,1.)*clamp(.3/tw3-.35,0.,1.);
      col=mix(col,dot(col,vec3(.3,.59,.11))>.42?col*.62+ink*.3:col*1.35+lite*.12,c3*imF*.55*step(.5,fract(tb3*.5+.25)));}
#endif
   }}
  // stacked paper: every higher layer casts a soft shadow away from the light (analytic: the next three layer
  // edges up the slope, at (k-fr)/w px), an occlusion crease at each cliff foot and a lit or shaded cut edge
  vec2 L=vec2(cos(la),sin(la));
  float cL=dot(gn,L);
  float shA=dot(so,vec4(1.,.55,.35,.8))*(1.-lod);
  float shd=0.,rim=0.;
  {float Sh=clamp(.5/w,2.*rs,24.*rs)*(.7+.75*gSw+.5*bE);
   float ic=1./max(cL,.08);
   for(int k=1;k<4;k++){float kk=float(k);shd=max(shd,clamp((Sh*kk-(kk-fr)/w*ic)/(.8*Sh*kk),0.,1.)*(1.-.22*kk));}
   shd*=step(0.,cL);
   shd=max(shd,.45*max(1.-(1.-fr)/w/Sh,0.));
   rim=clamp(1.5-fr/w/max(1.,rs),0.,1.);}
  float aoV=0.;
#if HD>=1
  // v20 the cut wall of each sheet is a surface of its own: its width comes from the band gradient, it takes the side light, and its edge is deckled by a fine tear
  if(lod<.95){
    float sr=fxNz(vec2(gPsi*170.,b*7.))*.6+fxNz(vec2(gPsi*410.,b*3.))*.4;
    float wW=clamp(.32/w,1.2*rs,5.*rs)*(.75+.8*sr);
    float d0=fr/w,d1=(1.-fr)/w;
    float wl=clamp((wW-d0)/max(wW,.01),0.,1.)*clamp(1.2-d0/wW,0.,1.);
    float side=.5-.5*cL;
    col=mix(col,col*mix(.42,1.5,side)+lite*.06*side,wl*(1.-lod));
    col*=1.-.32*clamp(1.-d1/(2.2*wW),0.,1.)*(1.-lod);
  }
#endif
#if HD>=1
  // v19 real rays over the paper stack (the analytic shadow above is the phone picture): the field is re-read along the light and around the pixel,
  // each sheet higher than this one casts a shadow it can actually reach; ray counts rise with detail
  if(lod<.98&&bw0>1.2){
    float Smu=clamp(.5/w,2.*rs,24.*rs)*(.7+.75*gSw+.5*bE)*px,occ=0.;
    int nS=int(clamp(14.*uDetail,4.,float(FX_SHM)));
    for(int k=FX0;k<FX_SHM;k++){if(k>=nS)break;
      float th=(float(k)+.5)/float(nS)*3.2,du=fxEv(q+L*th*Smu,3)-u;du-=gVort*gP*floor(du/gP+.5);
      float hh=floor(u+du)-b;
      if(hh>0.)occ=max(occ,clamp((hh-th)*1.6,0.,1.)*(1.-.12*th));
    }
    shd=max(shd*.55,occ);
    int nA=int(clamp(9.*uDetail,6.,float(FX_AOM)));float aoS=0.;
    for(int k=FX0;k<FX_AOM;k++){if(k>=nA)break;
      float a=TAU*(float(k)+.5)/float(nA)+.7,rr=Smu*(.5+1.3*fract(float(k)*.618));
      float du=fxEv(q+vec2(cos(a),sin(a))*rr,3)-u;du-=gVort*gP*floor(du/gP+.5);
      aoS+=clamp(floor(u+du)-b,0.,2.)*.5;
    }
    aoV=aoS/float(nA)*(1.-lod);
  }
#endif
  float dotT=0.;
  if(shA>0.){
    if(so.w+so.y>.5){
      // riso: the shadows print as a rotated halftone screen
      float rr=hpch*.62*sqrt(clamp(shd*.85+.12*fr,0.,1.))*(.85+.35*gB1.z);
      dotT=clamp((rr-hd)*.7+.5,0.,1.)*shA;
      col=mix(col,col*.32+ink*.5,dotT);
    }else col*=1.-shA*.62*shd;
    col+=shA*col*rim*(1.3*max(-cL,0.)-.5*max(cL,0.));
  }
#if HD>=1
  {col=mix(col,col*.62+fxSrgb(mix(gC1,gC2,.4))*.1,min(aoV*1.1,.8));   // occlusion is tinted with the map's own plates, never black
#if HD>=2
   // shaded slopes are engraved: a second, counter-rotated halftone screen and hatching that runs along the field lines
   float pdxH=dFdx(gPsi),pdyH=dFdy(gPsi);pdxH-=floor(pdxH+.5);pdyH-=floor(pdyH+.5);
   float pwH=max(length(vec2(pdxH,pdyH)),2e-6),lh=max(log2(1./(pwH*7.*rs)),1.);
   float tn=max(shd,aoV)*(1.-lod);
   if(tn>.02){float hk=floor(lh),hf=lh-hk,hc=0.;
     for(int k=FX0;k<2;k++){float nh=exp2(hk+float(k)),v=gPsi*nh,dl=abs(v-floor(v+.5))/(pwH*nh);hc+=mix(1.-hf,hf,float(k))*clamp(.55*rs+.5-dl,0.,1.);}
     col=mix(col,ink*1.1+col*.35,min(hc,1.)*tn*.6);
     vec2 hc2=rot(-.72)*fc/(hpch*.72);float hd2=length(fract(hc2)-.5)*hpch*.72,rr2=hpch*.42*sqrt(clamp(tn,0.,1.));
     col=mix(col,col*.45+ink*.4,clamp((rr2-hd2)*.7+.5,0.,1.)*.75*tn);}
#endif
  }
#endif
  col*=1.-.55*fo.w*clamp(fr*1.6-.6,0.,1.)*(1.-lod);
  // index bands: flat accent ink, metallic foil or holographic foil; the hi-mids sweep the sheen
  {vec2 fd=vec2(cos(fsw),sin(fsw)),g2=vec2(gn.x*gn.x-gn.y*gn.y,2.*gn.x*gn.y);
   float sh=.5+.5*dot(gn,fd),s2=sh*sh,s4=s2*s2,spec=s4*s4*(1.+3.4*gO2.x+gB2.w)*clamp(min(w*uRes.y/18.-.5,1.5-w*uRes.y/180.),0.,1.);
   float h1=dot(g2,fd),h2=dot(g2,vec2(-fd.y,fd.x));vec3 hol=.5+.5*vec3(h1,h2,-.7*h1-.7*h2);
   vec3 met=mix(mix(acc*(.25+1.1*s2),hol*hol*(.5+.9*sh),step(1.5,foil)),mix(acc,lite,.5)*(.3+s2),step(2.5,foil));
   vec3 fa=mix(acc*(1.-.1*nf),met+vec3(1.,.97,.9)*spec*(.65+2.2*gB2.x),step(.5,foil));
#if HD>=1
   if(ast>.01&&foil>.5){   // the foil mirrors the sheet: a real read of the map one band to the side, in its own ink, across the sheen
     float mu=fxEv(q+reflect(vec2(cos(hph*TAU),sin(hph*TAU)),gn)*min(.6/w*px,.1),4);
     vec3 mc=fxSrgb(fxRamp(floor(mu+.5)+co,st*(1.-so.y)));
     fa=mix(fa,mc*(.65+1.2*sh)+vec3(1.,.97,.9)*spec*.5,.45);}
#endif
#if HD>=2
   if(ast>.01){   // true dispersion: the foil re-reads the field at three offsets, one per channel, so its rainbow is the map's own contour geometry
     vec3 dsp=vec3(0.);float sp2=.55*px/w;
     for(int k=FX0;k<3;k++){float kk=float(k)-1.;dsp[k]=.5+.5*cos(fxEv(q+gn*kk*sp2,4)*TAU*.5+hph*TAU);}
     fa=mix(fa,fa*(.85+.75*dsp)+dsp*(.12+spec*.9),step(.5,foil)*.85);
   }
#endif
   col=mix(col,fa,ast);}
#if HD>=1
  // etched index bands: banknote rosette lines run along each band, phase-locked to the field lines, on the footprint of the pixel
  if(ast>.01){
    float pdxE=dFdx(gPsi),pdyE=dFdy(gPsi);pdxE-=floor(pdxE+.5);pdyE-=floor(pdyE+.5);
    float pwE=max(length(vec2(pdxE,pdyE)),2e-6);
    float rr=2.*floor(1.+min(10.,uDetail)),amp=clamp(.09/(pwE*rr*2.)-.3,0.,1.),gv1=fr*2.+.18*amp*sin(gPsi*TAU*rr*2.+hph*TAU)+.05*amp*amp*sin(gPsi*TAU*rr*4.-hph*TAU),gwd=sqrt(pow(w*2.,2.)+pow(pwE*TAU*rr*2.*.36*amp,2.));
    float gl=abs(fract(gv1*3.+.5)-.5)/(gwd*3.)-.4*rs;
    col=mix(col,mix(ink*1.3,lite*1.2,step(1.5,foil)),clamp(.5-gl,0.,1.)*clamp(.3/(gwd*3.)-.4,0.,1.)*ast*.8);
  }
#endif
  // v19 the flow net: every band is cut across by the field lines into cells (the cell count doubles as they spread, cross-faded),
  // printed as 0 mosaic, 1 hachure ticks, 2 scales or 3 weather fronts. Each cell belongs to one band of the spectrum and lights on its onsets.
  float bpx=1./w;
  float pdx=dFdx(gPsi),pdy=dFdy(gPsi);pdx-=floor(pdx+.5);pdy-=floor(pdy+.5);
  float pw=max(length(vec2(pdx,pdy)),2e-6);
  if(txA>.01&&lod<.99){
    float Nk=12.*exp2(mod(b,3.)),vv=gPsi*Nk+.5*mod(b,2.),j=floor(vv),f=vv-j,hh=h21(vec2(mod(b,64.),mod(j,Nk))),cpx=1./(pw*Nk);
    float fade=(txK>3.5?clamp(bpx/(5.*rs)-.5,0.,1.)*clamp((360.*rs-bpx)/(120.*rs),0.,1.)*(1.-lod):clamp(min(bpx,cpx)/(5.*rs)-.5,0.,1.)*clamp((txA*1.2-hh)*7.,0.,1.)*(1.-lod)),lit=fxBand(gO1,gO2,floor(fract(hh*13.)*8.));
    if(fade>.003){
      vec4 t=vec4(0.);
      if(txK>3.5){   // v20 ornaments: on alternate bands, in two kinds
        float m4=mod(b,4.);
        t=fxOrnLayer(m4<.5?txK:(m4>1.5&&m4<2.5?4.+mod(txK+3.,6.):-1.),b,fr,bpx,pw,co,st*(1.-so.y),ink,acc,lite,rs,txA,nL);
      }else if(txK<.5){   // mosaic
        float ed=min(min(fr,1.-fr)*bpx,min(f,1.-f)*cpx),gr=clamp(1.4*rs-ed+.5,0.,1.);
        vec3 c=fxSrgb(fxRamp(b+co+floor(hh*5.)*gP/8.,st*(1.-so.y)))*(.82+.55*fract(hh*7.)+1.2*lit);
        t=vec4(mix(c,ink,gr*.9),1.);
      }else if(txK<1.5){   // hachure: short strokes hanging off every contour on its downhill side, length by the band's own level
        float y2=fract(vv*3.),dl=abs(y2-.5)*cpx/3.,L=(.3+.35*fract(hh*5.))*(1.+.5*gB2.z);
        t=vec4(mix(ink*.8,acc*1.6,lit),clamp(.8*rs+.5-dl,0.,1.)*clamp((L-fr)*bpx+.5,0.,1.));
      }else if(txK<2.5){   // scales: overlapping arcs
        float yy=(f-.5)*cpx,rr=length(vec2(fr*bpx,yy)),R0=.52*max(cpx,1.),ins=clamp(R0-rr+.5,0.,1.);
        float rg2=abs(fract(rr/R0*3.5)-.5)*R0/3.5;
        vec3 c=fxSrgb(fxRamp(b+co+fract(hh*3.)*gP*.2,st*(1.-so.y)))*(1.+.9*lit);
        t=vec4(mix(c,mix(ink,lite,.25+.75*lit),clamp(1.1*rs-rg2+.5,0.,1.)),ins*.92);
      }else{   // weather fronts: teeth along every 4th contour, triangles and half discs alternating band by band
        float idx=step(mod(b,4.),.5),yy=(fract(vv*2.)-.5)*cpx*.5,xx=fr*bpx,hw=.26*cpx;
        float sdt=mix(max(xx-(hw-abs(yy))*1.3,-xx),length(vec2(xx,yy))-hw,step(.5,fract(b*.125)));
        t=vec4(mix(acc*1.25,lite*1.3,step(.5,fract(b*.125)))*(1.+1.2*lit),clamp(.5-sdt,0.,1.)*idx);
      }
      col=mix(col,t.rgb,t.a*fade*(1.-.85*ast));
    }
  }
  // v19 the chase: each beat steps a lit ring of bands one contour further out
  {float cz=mod(b+chs,8.),bf=1.-fract(uBeat);col*=1.+(.22+.55*gO1.x)*bf*bf*step(cz,.5)*(1.-lod)*step(gVort,.5);}
  // v13: hats and the air band: alternate contour bands brighten with the smoothed onset light of the two top sources
  // (their bands' onsets and the hats feed it), a shimmer across the whole map instead of a fine hairline only.
  // (Levels are auto-ranged near 1 all through a song, so only the onset light carries the rhythm.)
  float hiS=clamp((max(uB2.z,uB2.w)-.2)/.75,0.,1.);
  {float hz=clamp(1.7*max(gO2.z,gO2.w)-.1+1.2*uHat+.55*hiS,0.,1.);
   col*=1.+.5*hz*(.5+.5*cos(3.14159*u))*(1.-.4*lod);}   // a soft swell across every other band (no new hard edges to shimmer)
  // ink line plate, slightly misregistered
  float lw=max(1.,uRes.y/760.);
  vec2 mis=vec2(.8,-.55)*max(1.,uRes.y/540.)*(1.-nf);
  float ul=u+dot(g,mis);
  // where contours crowd below ~3 px, only every 2nd / 4th / 8th line survives (index contours, like a topo map)
  float lv=max(log2(w/.15),0.),lk=min(floor(lv),3.),ldf=clamp(lv*1.43-lk*1.43-.43,0.,1.);
  float s1=exp2(lk);
  float u1=ul/s1,n1=floor(u1+.5),el=u1-n1;
  float E=n1*s1;
  float dlp=abs(el)*s1/w;
  float line=clamp(lw*.5-dlp+.5,0.,1.)*(1.-ldf*step(.25,fract(n1*.5)))*clamp(6.6-lv*1.66,0.,1.);
  vec3 lcE=rA;
  // each source's own rings light up on its band's onsets; distant systems pulse with theirs
  float gOnB=fxBand(gO1,gO2,gGb),gLvB=fxBand(gB1,gB2,gGb);
  float fl=min(oL+gGh*gWt*(.25*gLvB+gOnB),1.5);
  {vec3 lc=mix(mix(lcE,sRaw,step(.5,lk))*2.,acc*2.4+.15,.75*min(fl,1.));
   float glow=max(1.-dlp*.25,0.)*clamp(1.5-w*5.,0.,1.);
   col=mix(mix(col,mix(ink,acc*1.2,min(fl,1.)),line*(.85+.07*so.w)),col+lc*(line+.35*glow)*(1.+1.5*fl),nf);}
  col*=1.+.42*min(fl,1.);   // a light hit: the source's own bands flare (crisp, no colour smudge)
  // fine line layers, one loop: 0 an overprinted contour map of the landscape (finer interval, another ink),
  // 1-2 a graticule that subdivides with scale (odd lines fade as you pull back), 3 nested hairlines inside the
  // bands (the highs light them, their onsets flash them)
  {float gtw=max(length(vec2(dFdx(gT),dFdy(gT))),1e-6),K2=gK*2.4;
   float oA=min(max(ovp,inI)*(.75+.6*gB1.w+1.6*gO1.w)+.3*gWt,1.)*(1.-fo.w)*(.55+.15*nf);
   float gv=clamp(.6*A-.9+.8*za+inI,0.,1.)*.36+.55*fluxSmooth(1.1,2.3,uZoom);   // v13: zoomed in, the survey grid (subdividing with scale) surfaces: fine detail and a clear sense of the zoom
   float lg=log2(A*.9),gs=exp2(floor(lg))*.25,gfr=fract(lg);
   float hz2=clamp(1.7*max(gO2.z,gO2.w)-.1+1.5*uHat,0.,1.),hTop=max(max(gB2.z,gB2.w),clamp((max(uB2.z,uB2.w)-.2)/.75,0.,1.)),hA=clamp(.2+max(gB2.z,hTop)*1.25+.3*gB2.w+.3*bE+1.2*gO2.z+1.5*uHat+.6*inI,0.,2.2)*.5*(1.-line);   // v18: the 12-to-a-band engraving at every detail setting; each level fades on its own footprint
   vec4 LV=vec4(gT*K2,p/gs,u*12.+4.*hph),LW=vec4(gtw*K2,px/gs,px/gs,w*12.),LA=vec4(oA,gv,gv,hA),LO=vec4(0.,gfr,gfr,0.);
   vec4 LD=vec4(.75*max(1.,rs)-.5,.6*lw,.6*lw,.2),LF=vec4(.25,9.,9.,.105);
   vec3 gc=mix(ink*1.2+lite*.12,lite*.55,nf);
   mat4x3 LC=mat4x3(mix(gC2*.5,lite*.9,nf)*(1.+.8*gO1.w),gc,gc,mix(lite*1.3+.05,acc*1.5+.05,.55*hz2));
   for(int k=0;k<4;k++){if(k>=nL-2)break;
     vec4 oh=max(1.-abs(float(k)-vec4(0,1,2,3)),0.);
     float v=dot(LV,oh),wv=max(dot(LW,oh),1e-6),n=floor(v+.5),ff=dot(LF,oh);
     float m2=step(.25,fract(n*.5)),m4=step(.25,fract(n*.25)),lr=mix(1.,mix(.21875,mix(.5,1.,m2),m4),oh.w);   // lr: this line's level spacing (every 4th = major, then halves)
     float cv=clamp(dot(LD,oh)-abs(v-n)/wv+.5,0.,1.)*(1.-dot(LO,oh)*step(.25,fract(n*.5)))*clamp(2.-wv*lr/ff,0.,1.)*dot(LA,oh)*mix(1.,mix(.85+.6*hTop,mix(.42+1.05*hTop+.5*hz2,.28+.9*hTop+.6*hz2,m2),m4),oh.w);
     col=mix(col,LC*oh,cv);}
#if HD>=1
   // v19 the engraving goes on as the print gets finer: 24, 48, 96 ... lines to a band, each level fading on its own footprint
   {float eL=dot(col,vec3(.3,.59,.11));vec3 eC=mix(col*1.5+lite*.18+.03,col*.34+ink*.6,fluxSmooth(.38,.6,eL));float rate=12.;
    for(int k=FX0;k<FX_HLM;k++){if(float(k)>=min(uDetail*.7,float(FX_HLM)))break;
      rate*=2.;float v=u*rate+4.*hph,n=floor(v+.5),wp=w*rate,sp=1./wp;
      float cv=clamp(.42*max(1.,rs)-abs(v-n)/wp+.5,0.,1.)*step(.25,fract(n*.5))*clamp(sp/(2.1*pow(FX_SS,.8))-.8,0.,1.);
      col=mix(col,eC,cv*(.2+.55*hTop+.5*hz2)*(1.-line)*(.85-.1*float(k)));}
#if HD>=1
    // micro atlases: the same field re-read at finer scales and printed tone on tone inside the bands, one more scale per tier
    {float mz=3.2;mat2 mr=rot(1.1);vec2 qm=q;
     for(int k=FX0;k<FX_MIC;k++){qm=mr*qm*mz+vec2(2.7,-1.9);
       float mi=fxEv(qm,4)*.7,miw=max(length(vec2(dFdx(mi),dFdy(mi))),1e-5),nm=floor(mi+.5);
       float cvm=clamp(.38*max(1.,rs)-abs(mi-nm)/miw+.5,0.,1.)*clamp(1./(miw*2.4*FX_SS)-.7,0.,1.);
       col=mix(col,eC,cvm*(.34-.06*float(k))*(.6+.8*hTop)*(1.-line));}}
#endif
   }
#endif
   }
  // tectonic strips: each slip line is printed as a bright cut in the sheet
  if(dmM>2.5&&dmA>.002){float fc=clamp(1.+.6*rs-gFlt/px,0.,1.)*min(dmA*4.,1.);col=mix(col,mix(ink,lite*1.2,.15+.85*min(rg,1.)),fc);}
  // islands: outside the coast the field sinks into a dark sea where only every 4th contour is drawn
  float coast=0.;
  float fw=max(length(vec2(dFdx(fP),dFdy(fP))),1e-5);
  if(isl>.001){
    float thF=dot(fo,vec4(1.,-.95,.45,.95))-gStr*(1.5+.5*fo.x)-.35*gSw+.35*bE-.9*zm-2.*za-1.6*max(1.-uZoom,0.);
    float thr=thF-4.5*(1.-isl)*(1.-isl);
    float sd=(fP-thr)/fw;
    float ins2=clamp(sd+.5,0.,1.);
    float shw=exp(min(sd,0.)/(30.*rs));
    float dep=max(thr-fP,0.),wl=clamp(.5+.5*cos(dep*TAU*2.2-gFt*1.5),0.,1.),tnt=floor(dep*1.6);
    vec3 seaT=fxSrgb(mix(gC1,mix(gC0,gC2,.5+.5*cos(tnt*2.4)),.35+.3*sin(tnt*1.3)))*(.7+.55*shw)+ink*.5;
    seaT=mix(seaT,lite*.9+acc*.15,.32*smoothstep(.62,.95,wl)*clamp(fw*12.+.2,0.,1.)*clamp(2.5-dep*.35,0.,1.));
    seaT*=1.+.6*uKick*step(.5,fract(tnt*.5));
    {float wv=dep*2.2-gFt*.24,wn=abs(fract(wv+.5)-.5)/max(fw*2.2,1e-5),wf=clamp(.11/max(fw*2.2,1e-5)-.5,0.,1.);
     seaT=mix(seaT,lite*1.25+acc*.3+.04,clamp(.7*max(1.,rs)-wn+.5,0.,1.)*wf*clamp(.12+.95*hiS+1.4*uHat+1.1*max(gO2.z,gO2.w),0.,1.));}
#if HD>=1
    if(ins2<.99){   // the sea is a window onto another sheet: its own map, at another scale, drawn through the water
      float um=fxEv(q*.62+vec2(1.3,-.7),5);float umw=max(length(vec2(dFdx(um),dFdy(um))),1e-5),fu=fract(um+.5)-.5;
      float uc=clamp(.75-abs(fu)/umw,0.,1.)*clamp(.18/umw,0.,1.);
      seaT=mix(seaT,mix(seaT*1.3+lite*.2,acc*.9+.05,step(fract(floor(um+.5)*.25),.1)),uc*.8);
    }
#endif
    vec3 sea=mix(seaT,acc*(.75+.3*shw+.8*gO1.z+.9*uHit),.8*clamp((hpch*(.1+.3*shw+.12*gB1.z+.2*uHit)-hd)*.7+.5,0.,1.))+lcE*(1.+.6*nf)*line*step(fract(E*.5),.1)*.9;
    sea*=.5+1.15*min(dot(col,vec3(.3,.59,.11)),1.1);
    col=mix(sea,col,ins2);
    coast=clamp(1.3*lw-abs(sd-1.2*lw)+.5,0.,1.);
    col=mix(col,acc*1.15,coast);
  }
  // the kick ring: a thin bright crest rides on the bulge
  col=col*(1.+.45*min(rg,1.2))+acc*.07*min(rg,1.2);   // a soft swell of light rides out on the kick wave
  col+=acc*isA0*gO1.w*.3*(1.-lod);
  col=mix(col,acc*1.5+lite*.35,clamp(uHit*.95,0.,.9)*ast);col*=1.+(.36+.9*gStr)*uHit*step(.5,fract(b*.5))*(1.-.45*lod);
  {float qb=fract(b*.25);col*=1.+(.2*max(uO2.x,uO2.y)*step(qb,.125)+.24*max(uO1.z,uO1.w)*step(.5,qb)*step(qb,.625))*(1.-lod);}   // v19 the snare stamps every index band in accent ink
  // distant systems: a small light at each centre (a scale cue in the atlas)
  col=mix(col,acc*(1.2+3.*gOnB)+lite*.3,clamp((max(1.6*px,.006)-gGd)/px+.5,0.,1.)*gWt*step(.001,gGh));
  // each source is a jewel lit by its slice of the spectrum
  // v20 the sources are faceted pressure medallions, not discs: a table, eight crown facets in two inks, lead lines, an outer collar of ticks that lights on the source's own band
  {float rn=length(jV)/max(jR,1e-5);
   if(jD>.002||rn<1.8){
    float an=fxAt(jV.y,jV.x),af=fract(an/TAU*12.+.5),sn=floor(an/TAU*12.+12.5),pxj=px/max(jR,1e-5);
    float tick=abs(fract(an/TAU*16.)-.5)*16.,col0=step(1.18,rn)*step(rn,1.6);
    vec3 fc=mix(acc*1.35,mix(acc,lite,.35)*1.05,.5+.5*sin(sn*2.4+an*.0));
    vec3 cr=fc*(.55+1.8*min(af,1.-af))*(1.+.6*jLv+1.8*jO);
    float tab=clamp((.46-rn)/pxj+.5,0.,1.);
    vec3 mj=mix(cr,mix(lite*1.25,vec3(1.,.98,.93),.25+.6*jO)*(1.1+1.1*jO),tab);
    float lead=max(clamp(.7-abs(af-.5)*TAU/12.*rn/pxj,0.,1.)*(1.-tab),clamp(.9-abs(rn-.46)/pxj,0.,1.));
    mj=mix(mj,ink*.9,lead*.85);
    mj=mix(mj,ink,clamp(1.2-(1.-rn)/pxj,0.,1.));
    col=mix(col,mj,jD);
    float tk=col0*clamp(1.-tick,0.,1.)*clamp(.5/(pxj*16.)-.1,0.,1.)*(.5+.5*jLv);
    col=mix(col,mix(ink,fc*1.3,clamp(jLv+2.*jO,0.,1.)),clamp(tk*3.,0.,1.)*step(.002,jR));
   }}
  col+=acc*uDrop*(.4*ast+.5*coast);
  // inset frame: the loupe's graduated metal bezel, or the sheet's paper border with a graduated neatline;
  // both cast a shadow on the map, and the sheet's region is marked on the map with leader lines
  if(iam>.002){
    float ipx=1./uRes.y,bw=.13*iR,t=clamp((iD+bw)/max(bw,1e-6),-1.,2.);   // t: 0 inner .. 1 outer edge of the frame (bounded: see met)
    col*=1.-.6*clamp(1.-(iD-.006)/.034,0.,1.)*step(0.,iD);   // shadow on the map
    float met=clamp(.5+.5*dot(iL,L)/max(iR,1e-4),0.,1.);
    vec3 fc2=mix(mix(gC1*.4+.03,lite*1.1+.1,met)*(.65+2.*t*(1.-t))+vec3(1.,.95,.9)*s8f(met)*(1.+2.*gO2.y),mix(acc,lite,.6),iShape);
    fc2=mix(fc2,ink,clamp(1.-min(abs(iD),abs(iD+bw))/ipx,0.,1.));
    col=mix(col,fc2,step(0.,t)*step(t,1.));
    // v20 the bezel is graduated: minute ticks, a longer tick each five, an index tooth that follows the foil sweep; inside, a fine reticle with a scale bar
    {float ang=fxAt(iL.y,iL.x)/TAU,tk1=fract(ang*60.),tkE=(.5-abs(tk1-.5))/60.*TAU*(iR+bw*.5)/ipx,maj=step(fract(ang*12.+1./120.),1./60.+.002);
     float tkL=mix(.34,.72,maj),tc=step(0.,t)*step(t,tkL+.1);
     col=mix(col,mix(ink,lite*1.3,step(.5,iShape)),clamp(1.-tkE,0.,1.)*tc*.9);
     float idx=abs(fract(ang-fsw/TAU+.5)-.5)*TAU*(iR+bw*.5)/ipx;
     col=mix(col,acc*1.6,clamp(3.-idx,0.,1.)*step(.3,t)*step(t,1.));
     if(iD<0.){vec2 rl=iL/ipx;float rm=clamp(.7-min(abs(rl.x),abs(rl.y)),0.,1.)*step(iR*.72/ipx,max(abs(rl.x),abs(rl.y)));
       float bar=clamp(.7-abs(rl.y+iR*.62/ipx),0.,1.)*step(abs(rl.x),iR*.3/ipx);
       float tb=clamp(.7-abs(fract(rl.x/(iR*.15/ipx)+.5)-.5)*(iR*.15/ipx),0.,1.)*step(abs(rl.x),iR*.31/ipx)*step(abs(rl.y+iR*.62/ipx),4.*rs);
       col=mix(col,dot(col,vec3(.3,.59,.11))>.4?ink:lite*1.2,max(max(rm,bar),tb)*.85);}
    }
    // inside: an inner shadow under the frame; the glass glows on the presence onsets
    col*=(1.-.45*inI*clamp((iD+bw+.12*iR)/(.12*iR),0.,1.))*(1.+.25*gO2.y*inI);
  }
  // Broad relief shading reveals hills and saddles beneath the contour ink. Derivatives are screen filtered.
  vec2 slope=vec2(dFdx(fP),dFdy(fP))/max(px,.00001);
  slope=slope/(1.+length(slope)*.24);
  vec3 reliefN=normalize(vec3(-slope*.45,1.));
  float relief=.64+.55*max(dot(reliefN,normalize(vec3(-.55,.65,.8))),0.);
  float terrace=.5+.5*sin(fP*2.4-clk*.12);
  col=col*relief+acc*.12*pow(terrace,6.)*(.4+.6*gB1.w);
  // v20 weather stations: a chart's wind barbs, one per occupied cell, riding the map. The barb lies along the field at its own centre (three field reads), its feathers count
  // the level of the slice of the spectrum it was given, and its ring lights on that slice's onsets. Cells live on a doubling grid, so zooming thins and refills them smoothly.
  {float lgS=log2(A*.9),gsS=exp2(floor(lgS))*.125,gfS=fract(lgS);vec2 giS=floor(q/gsS);
   float hS=h21(giS+vec2(11.3,5.1)+uSeed.xy*37.),evS=step(mod(giS.x,2.),.5)*step(mod(giS.y,2.),.5);
   float shS=step(hS,.5)*mix(1.-gfS,1.,evS)*(1.-.92*lod)*min(1.,.25+uZoom*2.);
   if(shS>.01){
     vec2 cS=(giS+.5+(vec2(fract(hS*17.3),fract(hS*29.1))-.5)*.32)*gsS,qX=dFdx(q),qY=dFdy(q),d0=q-cS;
     float det=qX.x*qY.y-qX.y*qY.x;
     vec2 dv=vec2(qY.y*d0.x-qY.x*d0.y,qX.x*d0.y-qX.y*d0.x)/(abs(det)>1e-12?det:1e-12)/rs;   // back to true screen pixels: the map's warp and swirl must not stretch the glyph
     if(dot(dv,dv)<1296.){
#if HD>=1
       vec3 E=vec3(0.);float eS=gsS*.18;
       for(int k=FX0;k<3;k++){E[k]=fxEv(cS+vec2(k==1?eS:0.,k==2?eS:0.),3);}
       vec2 gS=E.yz-E.xx;gS-=gP*floor(gS/gP+.5);
       gS=vec2(dot(qX,gS),dot(qY,gS));vec2 nS=gS/max(length(gS),1e-9),tS=vec2(-nS.y,nS.x);
#else
       vec2 nS=gn,tS=vec2(-gn.y,gn.x);   // phones: the barb follows the pixel's own gradient, no extra field reads
#endif
       float xs=dot(dv,tS),ys=dot(dv,nS),bdS=floor(fract(hS*13.7)*8.),lvS=fxBand(gB1,gB2,bdS),onS=clamp(fxBand(gO1,gO2,bdS)*1.3,0.,1.);
       float Ls=30.,dg=length(vec2(max(abs(xs-Ls*.5-3.)-Ls*.5,0.),ys)),rg0=length(dv),dc=abs(rg0-4.2),fs=clamp(1.1-dg,0.,1.);
       for(int k=FX0;k<5;k++){float kk=float(k),ak=clamp((.12+lvS*.88)*5.-kk,0.,1.);if(ak<.01)break;
         float x0=Ls+3.-kk*5.2;fs=max(fs,ak*clamp(1.1-fxSeg(vec2(xs,ys),vec2(x0,0.),vec2(x0+4.2,11.5)),0.,1.));}
       fs=max(fs,clamp(1.05-dc,0.,1.));
       float fd=clamp(3.2-rg0,0.,1.)*step(.5,fract(hS*7.7));
       float eL=dot(col,vec3(.3,.59,.11));
       vec3 iS=mix(eL>.36?ink*1.05:lite*1.2,acc*1.5+.08,onS);
       col=mix(col,iS,max(fs,fd)*shS);
#if HD>=1
       // the station's reading, in a tiny 3 by 5 figure beside the ring: three digits from the cell's own hash
       {vec2 tp=(dv-vec2(6.5,-10.))/1.65;vec2 td=floor(tp/vec2(4.,6.));
        if(td.y==0.&&td.x>=0.&&td.x<3.){vec2 cf=tp-td*vec2(4.,6.);float dg1=fract(hS*(97.3+td.x*31.7));
         float fnt=dg1<.1?31599.:dg1<.2?9362.:dg1<.3?29671.:dg1<.4?29391.:dg1<.5?23497.:dg1<.6?31183.:dg1<.7?31215.:dg1<.8?29330.:dg1<.9?31727.:31695.;
         vec2 ci=floor(cf);float bit=mod(floor(fnt/exp2(ci.x+3.*(4.-ci.y))+.01),2.)*step(ci.x,2.)*step(ci.y,4.)*step(0.,ci.x)*step(0.,ci.y);
         col=mix(col,iS,bit*shS*clamp(1.65*rs*.9,0.,1.));}}
#endif
       float rg1=abs(rg0-4.2-15.*(1.-onS))-.5;
       col=mix(col,acc*1.5+lite*.3,clamp(.75-rg1,0.,1.)*onS*onS*shS*.8);
     }
   }}
  // v19 sparks: hats and air fire 4-point stars across a grid riding the map, independent of contours, folds and prints; the highs level sets how many
  // and how big they are, each half beat picks a new scatter (light only: nothing moves)
  {float hiL=clamp((max(uB2.z,uB2.w)-.2)/.75,0.,1.),spk=clamp(max(max(uHat*1.5,1.3*max(gO2.z,gO2.w)),.78*hiL),0.,1.);
   if(spk>.02){
     float cs=.042*uRes.y,beat2=floor(uBeat*2.),bf2=1.-fract(uBeat*2.);vec2 gc2=p/(A*.042),gi=floor(gc2),gf=gc2-gi;
     float hs=h21(gi+vec2(3.1,7.7)),hs2=fract(hs*47.3+beat2*.37);
     if(hs2<.04+.44*spk){
       float hs3=fract(hs*91.7+beat2*.71);vec2 jt=(vec2(fract(hs*17.3),fract(hs*29.1))-.5)*.34,dv=(gf-.5-jt)*cs;
       float R0=min((2.5+11.*spk*(.35+.65*hs3))*rs*(.7+.5*bf2*bf2),cs*.4);
       float sdS=sqrt(abs(dv.x))+sqrt(abs(dv.y))-sqrt(R0);
       float sC=clamp(.5-sdS*sqrt(R0)*1.7,0.,1.),coreS=clamp(R0*.32-length(dv)+.5,0.,1.);
       vec3 sc0=mix(mix(acc*1.6,lite*1.5,step(.5,fract(hs*5.))),vec3(1.,.97,.9),.45);
       col=mix(col,sc0*(1.1+1.3*spk),sC*(.55+.45*bf2));col=mix(col,vec3(1.3,1.25,1.15),coreS);
     }
   }}
  // A singular contour must never poison exposure/feedback and turn the entire realm black.
  if(any(isnan(col))||any(isinf(col)))col=fxSrgb(mix(gC1,gC3,.5+.5*sin(p0.x*3.+clk*.12)));
  fragColor=vec4(clamp(col,vec3(0.),vec3(12.)),0.);
}
`;
