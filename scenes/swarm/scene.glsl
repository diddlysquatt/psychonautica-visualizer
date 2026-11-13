const R_SWARM = `
// SWARM. Pointillist particle sculptures: tens of thousands of glowing dots forming large 3D figures (tori, knots,
// harmonic blobs, a sphere of rings, a galaxy, a DNA helix, a lotus, a murmuration, a vortex, rippling wave sheets, a
// dancing figure), alone or split into twins, quartets and rings of eight, hanging in a universe of smaller swarms
// (tilted, tumbling 3D discs: galaxies, flowers, rings, bursts) under titanic sculptures in the far sky.
// Rendering: the ray walks a 3D grid of cells (DDA). Every cell owns at most one particle: a jittered point that
// exists when it lies within a thin band of the figure's surface (or inside a volume figure, by density). Each
// particle adds an analytic dot (crisp core + compact halo) by closest approach to the ray, front to back with a
// little occlusion. Empty space is skipped with the figure's distance bound, so huge particle counts stay cheap.
// The grid itself can flow (rigid screw about the figure axis), so dots stream through the figure while the
// figure, its colour field and its spectrum mapping stay put.
// uP1 x,y = figure A/B (split*16 + id + prm*.98), z = morph 0..1, w = world scale
// uP2 x = flow angle, y = flow height (helix screw), z = vista (48ths, integer part) + orbit rings amount, w = kick ripple
// uP3 x = explosion envelope, y = shock shell radius, z = build, w = bounding radius
// uP4 x = colour wave position, y = palette+offset behind, z = palette+offset ahead, w = wave direction seed
// uP5 xyz = camera position (zoom 1), w = universe gain; uM1[0],[1] = camera right/up, uM1[2] = (mid ripple, dust,
// dance phase); uM2 = world->object rotation
// v22: the sea of pearls under the figure is switched off (the owner: it blocks the background). 1 brings it back as it was in v21.
#define SW_SEA 0
#if HD>=1
// v19 detail tiers (HD>=1 only): denser figures, a marched light ray per dot (the sculpture shades itself), more far swarms with more dots each, extra star-dust
// octaves and fine nebula filaments. New light is coloured and divided per layer, so added dots never sum toward white.
#if HD>=5
#define SW_CE .56
#define SW_IE .78
#define SW_OCC 12
#define SW_FAR 120
#define SW_FN 4.
#define SW_DUST 5
#define SW_NEB 6
#define SW_AA 3
#define SW_LAT 4
#elif HD>=4
#define SW_CE .54
#define SW_IE .72
#define SW_OCC 8
#define SW_FAR 90
#define SW_FN 3.4
#define SW_DUST 4
#define SW_NEB 5
#define SW_AA 2
#define SW_LAT 4
#elif HD>=3
#define SW_CE .5
#define SW_IE .66
#define SW_OCC 6
#define SW_FAR 72
#define SW_FN 2.8
#define SW_DUST 4
#define SW_NEB 4
#define SW_AA 2
#define SW_LAT 3
#elif HD>=2
#define SW_CE .48
#define SW_IE .62
#define SW_OCC 5
#define SW_FAR 60
#define SW_FN 2.2
#define SW_DUST 3
#define SW_NEB 3
#define SW_AA 2
#define SW_LAT 3
#else
#define SW_CE .42
#define SW_IE .55
#define SW_OCC 2
#define SW_FAR 44
#define SW_FN 1.6
#define SW_DUST 2
#define SW_NEB 2
#define SW_AA 1
#define SW_LAT 1   // v22b: Native = one finer lattice (cost x1.25 of base, was x2.1); Cinema and up keep 3-4
#endif
vec3 swL;
#endif
vec3 swDcA,swDcB,swNU;float swM,swBand,swB0,swEx,swShR,swRing,swCo,swRip,swDust,swDance,swVoc,swGr,swHx;
vec3 swLv;float swGain,swPl;
float swBu,swCw;   // v21: build amount (fract of uP3.z) and the small code word riding with it (floor)
float swV,swQv,swS,swQs,swQc,swSl,swPit,swCoL;   // v20: a second surface coordinate (turns) of the last figure evaluated and whether it is a string, the same for the winning particle; string mode and pitch
// v18 formations (split id): polar count, polar radius, body scale, grid kind (1 grove, 2 totem)
int swZ; // always 0, but not constant-foldable: keeps the HLSL compiler from unrolling and inlining loop bodies
// v22 CHOREOGRAPHIES (split id). The old formations were crowds of small bodies standing in a ring. Now a formation is two to four LARGE bodies
// that move around each other: 0 one colossal body, 1 a binary (two bodies orbiting each other on a leaning ellipse), 2 a weave of four (two pairs
// circling opposite ways and passing inside and outside each other, like a maypole), 3 three bodies chasing each other round a figure-eight,
// 4 a core with three moons on three leaning orbits, 5 a comet train (four bodies, each smaller than the last, coiling round the frame).
// Their places are worked out once per pixel (swSet) from the carousel phase, which steps on the beat; a build draws them in tight.
vec4 swA0,swA1,swA2,swA3,swC0,swC1,swC2,swC3;   // (no arrays: dynamic indexing spilled to slow memory and cost x4) body centres (xyz, in figure units) and scale (w; 0: no body) of the outgoing and the incoming formation
// bounding radius per family at scale 1 (the same table as SWARM_RB in the helpers)
const float SWRB[16]=float[16](1.32,1.25,1.32,1.22,1.6,3.6,1.75,1.42,1.9,1.9,1.3,1.6,2.65,1.6,2.05,2.05);
void swSet(float md,float ph,float tg,out vec4 b0,out vec4 b1,out vec4 b2,out vec4 b3){
  b0=vec4(0.,0.,0.,1.);b1=vec4(0.);b2=vec4(0.);b3=vec4(0.);
  float c=cos(ph),s=sin(ph),c2=cos(2.*ph),s2=sin(2.*ph);
  if(md<.5)return;
  if(md<1.5){ // binary
    vec3 o=vec3(1.32*c,.42*s,1.05*s)*tg;b0=vec4(o,.62);b1=vec4(-o,.62);
  }else if(md<2.5){ // weave of four
    float ro=(1.5+.44*s2)*tg,ri=(1.5-.44*s2)*tg;
    b0=vec4(ro*c,.3*s2,ro*s,.45);b1=vec4(-ro*c,.3*s2,-ro*s,.45);
    b2=vec4(-ri*s,-.3*s2,-ri*c,.45);b3=vec4(ri*s,-.3*s2,ri*c,.45);
  }else if(md<3.5){ // three on a figure-eight
    for(int k=swZ;k<3;k++){float u=ph+float(k-swZ)*2.0944;vec4 b=vec4(vec3(1.62*sin(u),.34*cos(u),.8*sin(2.*u))*tg,.52);if(k==0)b0=b;else if(k==1)b1=b;else b2=b;}
  }else if(md<4.5){ // a core and three moons
    b0=vec4(0.,0.,0.,.64);
    b1=vec4(vec3(1.5*c,.5*s,1.5*s)*tg,.33);
    b2=vec4(vec3(-1.7*c2,1.1*s2,.95*s2)*tg,.29);
    b3=vec4(vec3(.5*sin(3.*ph+2.),-1.3*cos(3.*ph+2.),1.45*sin(3.*ph+2.)).zyx*tg,.25);
  }else{ // comet train
    for(int k=swZ;k<4;k++){float fk=float(k-swZ),u=ph-fk*(.95-.07*fk);vec4 b=vec4(vec3(1.5*cos(u),.5*sin(2.*u+.6),1.5*sin(u))*tg,.58-.07*fk);if(k==0)b0=b;else if(k==1)b1=b;else if(k==2)b2=b;else b3=b;}
  }
}
vec3 swH3(vec3 p){p=fract(p*vec3(.1031,.1030,.0973));p+=dot(p,p.yxz+33.33);return fract((p.xxy+p.yzz)*p.zyx);}
// atan(y,x) to ~.002 rad, cheaper than the built-in
float swAt(float y,float x){vec2 a=abs(vec2(x,y));float t=min(a.x,a.y)/max(max(a.x,a.y),1e-6),r=.7854*t-t*(t-1.)*(.2447+.0663*t);
  r=a.y>a.x?1.5708-r:r;r=x<0.?PI-r:r;return y<0.?-r:r;}
float swCap(vec3 p,vec3 a,vec3 b,float r){vec3 pa=p-a,ba=b-a;return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.,1.))-r;}
// six hand-picked four-stop loops: electric blue/magenta/rose/amber, lime/cyan/azure/violet, hot pink/orange/gold/orchid,
// cyan/cobalt/pink/pearl, ultraviolet/red/orange/lemon, mint/azure/lavender/coral
const vec3 SWP[24]=vec3[24](
  vec3(.04,.28,1.),vec3(.8,.08,1.),vec3(1.,.12,.36),vec3(1.,.6,.05),
  vec3(.42,1.,.06),vec3(0.,1.,.78),vec3(.08,.42,1.),vec3(.62,.12,1.),
  vec3(1.,.06,.42),vec3(1.,.42,.04),vec3(1.,.86,.2),vec3(.9,.16,.95),
  vec3(0.,.88,1.),vec3(.18,.26,1.),vec3(1.,.16,.72),vec3(1.,.82,.7),
  vec3(.36,.04,1.),vec3(1.,.02,.28),vec3(1.,.5,0.),vec3(1.,.95,.18),
  vec3(0.,1.,.5),vec3(0.,.62,1.),vec3(.72,.26,1.),vec3(1.,.36,.56));
vec3 swStop(float id,float i){return SWP[clamp(int(id)*4+(int(i)&3),0,23)];}
vec3 swPal(float id,float t){
  float x=fract(t)*4.,f=fract(x);f*=f*(3.-2.*f);
  vec3 a=swStop(id,x),b=swStop(id,x+1.),m=mix(a,b,f);
  float lm=dot(m,vec3(.3333));
  m=lm+(m-lm)*(1.45+1.9*f*(1.-f)*length(a-b));    // keep (and enrich) chroma through the blend: no grey midpoints
  return max(m+cross(vec3(.57735),m)*(sin(uHue*TAU)*.3),0.);   // the global colour drift nudges the hues a little
}
// figure families. returns x: distance to the particle band (Lipschitz-safe), y: density, z: spectrum coordinate 0..1, w: tag
vec4 swFig(float id,float pr,vec3 p){
  float l=length(p),rho=length(p.xz),az=swAt(p.z,p.x),cy=clamp(p.y/max(l,1e-4),-1.,1.),th=sqrt(1.-abs(cy))*(1.5707-.2121*abs(cy));th=cy<0.?PI-th:th;
  vec4 g;swV=az*.159155;swS=0.;
  switch(int(id)){
  case 0:{ // TORUS: two nested tubes (or a horn torus wrapped around its own core)
    float hn=step(.55,pr),r1=.43+.21*hn,lq=length(vec2(rho-.82+.22*hn,p.y)),d1=abs(lq-r1),d2=abs(lq-r1*.56);
    swV=swAt(p.y,rho-.82+.22*hn)*.159155;
    g=vec4(min(d1,d2),1.,abs(az)/PI,step(d2,d1));break;
  }
  case 1:{ // KNOT: hollow tube around a (P,Q) torus knot
    float Q=3.+2.*floor(pr*4.),s0=az*.5,s1=s0+PI;vec2 q=vec2(rho-.8,p.y);
    float d0=length(q-.36*vec2(cos(Q*s0),sin(Q*s0))),d1=length(q-.36*vec2(cos(Q*s1),sin(Q*s1)));
    g=vec4(abs(min(d0,d1)-.15)*.7,1.,(d0<d1?s0:s1)/TAU,0.);break;
  }
  case 2:{ // BLOB: spherical harmonic shell around a dense glowing nucleus
    float k=floor(pr*4.),M=5.-k;
    float e1=abs(l-.95-.27*sin((3.+k)*th)*cos(M*az)-.06*cos(2.*th))*.6,e2=max(l-.24,0.);
    g=e2<e1?vec4(e2,.55,.15,1.):vec4(e1,1.,th/PI,0.);break;
  }
  case 3:{ // RINGS: a sphere built from stacked dotted tori, one per band of the spectrum
    float N=11.+4.*step(.5,pr),bi=clamp(floor(th/PI*N),0.,N-1.),ti=(bi+.5)/N*PI;
    g=vec4(abs(length(vec2(rho-1.12*sin(ti),p.y-1.12*cos(ti)))-.05),1.,1.-bi/(N-1.),mod(bi,2.));break;
  }
  case 4:{ // GALAXY: a volume of stars in logarithmic spiral arms around a bulge
    float hg=.05+.2*exp(-rho*rho*9.);
    float sp=pow(.5+.5*cos((2.+floor(pr*3.))*(az-log(rho+.04)*1.9)+.4*sin(rho*9.)),5.);
    float dens=((sp*1.3+.05)*clamp(2.2-1.43*rho,0.,1.)+1.4*exp(-rho*rho*14.))*exp(-p.y*p.y/(hg*hg*1.2));
    g=vec4(max(max(abs(p.y)-hg*1.6,rho-1.55),0.),dens,clamp(rho/1.45,0.,1.),0.);
    if(swSl>.5){   // v20: the galaxy as string art: three threads to every arm, wound on the same logarithmic spiral, around a bulge
      float m=(2.+floor(pr*3.))*3.,dsp=abs(fract(m*(az-log(rho+.04)*1.9)*.159155+.5)-.5)*TAU*rho/m*.466;
      float e=max(length(vec2(p.y,dsp))*.8,rho-1.55),eb=max(l-.2,0.);
      g=eb<e?vec4(eb,.6,0.,1.):vec4(e,1.,clamp(rho/1.45,0.,1.),0.);swS=1.;swV=log(rho+.04)*.8;
    }
    break;
  }
  case 5:{ // HELIX: two hollow strands and base-pair rungs
    float k=TAU/1.7,ps0=mod(az-k*p.y+PI,TAU)-PI,ps1=mod(az-k*p.y-2.3+PI,TAU)-PI,sk=rho/sqrt(1.+k*k*rho*rho);
    float d0=length(vec2(rho-.55,ps0*sk)),d1=length(vec2(rho-.55,ps1*sk));
    float nn=floor(p.y/.17),ta=k*(nn+.5)*.17+1.15;vec2 u=vec2(cos(ta),sin(ta));
    float er=max(length(vec3(p.y-(nn+.5)*.17,dot(p.xz,u)-.204,max(abs(dot(p.xz,vec2(-u.y,u.x)))-.456,0.)))-.022,0.)*.7;
    float e=abs(min(d0,d1)-.06)*.85,f=clamp(.5+p.y*.22,0.,1.);
    g=er<e?vec4(er,1.,f,2.+floor(fract(nn*.618)*4.)):vec4(e,1.,f,step(d1,d0));break;
  }
  case 8:{ // LOTUS: pointed dotted petals in a flaring cup around a glowing seed pod
    float N=5.+floor(pr*4.),s=TAU/N;
    vec3 q=p-vec3(0.,.42,0.);float lq=length(q),cq=q.y/max(lq,1e-4),u=clamp((.5-cq)/1.5,0.,1.);
    float a=mod(az+s*.5,s)-s*.5,w=s*.8*sqrt(min(u*1.3,1.)*(1.-min(u*1.3,1.)));   // a pointed leaf: thin at the tip and the base
    float e=max(max(abs(lq-1.12*(1.+.45*(1.-u)*(1.-u)))*.8,(abs(a)-w)*length(q.xz)),(cq-.5));   // tips flare outward
    float ep=max(length(p-vec3(0.,-.05,0.))-.26,0.)*1.4;
    swV=a/s;
    g=ep<e?vec4(ep,.7,.1,3.):vec4(e,1.,1.-u,step(.6,abs(a)/w));break;
  }
  case 10:{ // VORTEX: an hourglass tornado of dots, spiral bands racing up its wall
    float sp=pow(.5+.5*cos(4.*az+6.*p.y-uTime*2.5),3.);
    g=vec4(max(max(abs(rho-.16-.62*p.y*p.y-.05*sin(p.y*5.+uTime*1.3))-.05,0.)*.62,abs(p.y)-1.15),.3+.9*sp,clamp(.5+p.y*.43,0.,1.),step(.5,sp));break;
  }
  case 6:{ // TREE: a pointillist tree whose whorls of branches grow level by level (growth: the build) and blossom
    // into clouds of bright leaf dots at the tips; height is the spectrum (roots = bass, crown = air)
    float G=swGr,kf=clamp(floor((p.y+.62-.36*rho)/.36+.5),0.,4.),yk=-.62+.36*kf,s=TAU/5.;
    float a=mod(az+kf*1.9+s*.5,s)-s*.5;vec2 bp=vec2(rho*cos(a),p.y-yk);
    float L=(1.12-.19*kf)*clamp(G*5.-kf*.85,0.,1.),bz=rho*sin(a);
    float tb=clamp(dot(bp,vec2(.84,.54))/max(L,1e-3),0.,1.);
    float db=length(vec3(bp-tb*L*vec2(.84,.54),bz))-.055*(1.-.6*tb)-.03*step(L,.01);
    float dt=max(rho-.125+.065*clamp((p.y+1.3)*.41,0.,1.),max(-1.3-p.y,p.y+1.3-2.45*clamp(G*1.25,.12,1.)));
    vec2 tp=L*vec2(.84,.54)+vec2(.06,.04);float rl=(.27-.025*kf)*clamp(G*5.-kf*.85-.35,0.,1.);
    float dl=max(length(vec3(bp-tp,bz))-rl,0.)*.8;
    float e=abs(min(db,dt))*.75;
    g=dl<e?vec4(dl,.62,clamp(.62+.09*kf,0.,1.),1.):vec4(e,1.,clamp((p.y+1.3)*.4,0.,1.),0.);break;
  }
  case 13:{ // HEART: a puffed hollow heart of dots (kicks make it beat); the spectrum runs out from its centre
    vec2 hp=vec2(abs(p.x),p.y+1.15)/2.2;
    vec2 c1=hp-vec2(.25,.75),c2=hp-vec2(0.,1.),c3=hp-.5*max(hp.x+hp.y,0.);
    float d2=mix(sqrt(min(dot(c2,c2),dot(c3,c3)))*sign(hp.x-hp.y),length(c1)-.35355,step(1.,hp.x+hp.y))*2.2;
    float th=.5*sqrt(clamp(-d2*1.8,0.,1.)),dz=abs(p.z)-th;
    float d=length(max(vec2(d2,dz),0.))+min(max(d2,dz),0.);swV=swAt(p.y+.1,p.x)*.159155;
    g=vec4(abs(d)*.62,1.,clamp(length(p.xy+vec2(0.,.1))/1.35,0.,1.),step(.5,fract(p.y*2.2+.25)));break;
  }
  case 14:{ // v22 FLIGHT: not one butterfly but a flock of them, wheeling together on three rings that turn against each other (the middle
    // ring flies the other way), every one flapping once a beat on its own phase and bobbing on its own; fore and hind wings, veins, eye spots,
    // a dotted body. The spectrum runs from the bodies out to the wing tips, ring by ring
    vec3 R0=vec3(1.3,-.42,7.),R1=vec3(.78,.2,5.),R2=vec3(1.62,.62,9.);
    float e0=length(vec2(rho-R0.x,p.y-R0.y)),e1=length(vec2(rho-R1.x,p.y-R1.y)),e2=length(vec2(rho-R2.x,p.y-R2.y));
    float ri=e1<min(e0,e2)?1.:(e0<e2?0.:2.),dir=1.-2.*step(abs(ri-1.),.5);vec3 Rg=ri<.5?R0:(ri<1.5?R1:R2);
    float sN=TAU/Rg.z,a0=az-(dir-1.)*uP2.x-ri*1.3,ia=floor(a0/sN+.5),a=a0-ia*sN,hi=fract(ia*.37+ri*.21+pr);
    const float kb=.36;
    vec3 q=vec3(abs(rho-Rg.x),dir*a*Rg.x,p.y-Rg.y-.1*sin(uTime*.9+hi*40.))/kb;
    float f=.12+.85*(.5+.5*sin(TAU*(uBeat+hi))),cf=cos(f),sf=sin(f);
    vec2 w=vec2(q.x*cf+q.z*sf,q.y);float wz=-q.x*sf+q.z*cf;
    vec2 a1=w-vec2(.62,.34);a1=mat2(.94,.34,-.34,.94)*a1;vec2 a2=w-vec2(.44,-.42);
    float s1=(length(a1/vec2(.66,.44))-1.)*.44,s2=(length(a2/vec2(.42,.37))-1.)*.37,sh=min(s1,s2);
    float vn=pow(.5+.5*cos(swAt(w.y+.05,w.x)*15.),3.),es=abs(length(a1-vec2(.17,.03))-.13);
    float dw=max(length(vec2(max(sh,0.),wz))-.012,max(-w.x,0.))*.8;
    float db=min(swCap(q,vec3(0.,-.62,0.),vec3(0.,.38,0.),.075),min(length(q-vec3(0.,.5,0.))-.1,swCap(q,vec3(.04,.56,.02),vec3(.27,1.02,.12),.018)));
    swV=w.y*.5;
    g=abs(db)<dw?vec4(abs(db)*.85,1.,ri*.3+.03,1.+ia*.45):vec4(dw,.55+.45*vn+step(es,.04),clamp(ri*.3+.36*w.x,0.,1.),step(es,.045)+2.*step(sh,-.1)*step(.6,vn)+ia*.45);
    g.x*=kb*.8;break;
  }
  case 7:{ // v20 ARMILLARY: four nested gimbal rings around a nucleus. Each beat of the bar one ring flips half a turn about
    // its own diameter (and lands on itself), so the instrument ticks like clockwork; each ring is one band
    float bb=uBar*4.,dm=1e9,wi=0.,wv=0.;
    for(int i=swZ;i<4;i++){
      float fi=float(i-swZ),a=PI*smoothstep(0.,.42,clamp(bb-fi,0.,1.))+.5*fi+.2*sin(uTime*.11+fi),ca=cos(a),sa=sin(a);
      vec3 q=p;
      if(i==1)q=q.yzx;else if(i==2)q=q.zxy;else if(i==3)q=vec3(.7071*(q.x+q.y),.7071*(q.y-q.x),q.z);
      q.xy=vec2(ca*q.x-sa*q.y,sa*q.x+ca*q.y);    // the flip: about the ring's own z diameter
      float R=1.22-.27*fi+.07*dot(swLv,vec3(equal(vec3(min(fi,2.)),vec3(0.,1.,2.)))),d=length(vec2(abs(length(q.xz)-R)-.035,q.y));
      if(d<dm){dm=d;wi=fi;wv=swAt(q.z,q.x)*.159155;}
    }
    float en=max(l-.21,0.);
    swV=wv;swS=1.;
    g=en<dm?vec4(en,.62,.5,5.):vec4(dm*.85,1.,.08+.28*wi,wi);break;
  }
  case 15:{ // v20 FOUNTAIN: three tiers of dotted jets (bass, mids, treble) arcing out of a basin; each tier's height is its band
    float y0=-1.02,dm=1e9,wi=0.,wu=0.;
    for(int i=swZ;i<3;i++){
      float fi=float(i-swZ),n=6.+3.*fi,s=TAU/n,b=.08+.2*fi,en=.95+.3*fi;
      float H=(.4+(1.45-.3*fi)*dot(swLv,vec3(equal(vec3(fi),vec3(0.,1.,2.)))))*(1.-.22*fi);
      float u=clamp((rho-b)/(en-b),0.,1.),yj=y0+4.*H*u*(1.-u),sl=4.*H*(1.-2.*u)/(en-b);
      float d=length(vec2(rho-clamp(rho,b,en),(p.y-yj)*inversesqrt(1.+sl*sl)));
      float da=mod(az+(fi-1.)*uTime*.07+s*.5,s)-s*.5;
      d=length(vec2(d,rho*sin(da)));
      if(d<dm){dm=d;wi=fi;wu=u;}
    }
    float rim=abs(length(vec2(rho-1.62,p.y-y0))-.05),pool=length(vec2(max(rho-1.5,0.),p.y-y0+.04));
    float dn=.25+.75*pow(.5+.5*sin(rho*13.-uTime*2.2),2.);
    swV=wu*1.5;swS=1.;
    g=vec4(dm*.7,1.,.08+.38*wi+.1*wu,wi);
    if(rim<g.x){g=vec4(rim,1.,.5,4.);swV=az*.159155;}
    if(pool<g.x){g=vec4(pool,dn*.5,.3,5.);swS=0.;}
    break;
  }
  case 9:{ // v22 SERPENT: a dragon of dots coiling round the frame. Its spine is a coil wound three or five times round a great ring; the body
    // (a hollow tube: a head, a neck, a long taper to the tail tip) slides along that coil chasing its own tail, as fast as the mids flow; banded like
    // a coral snake, its scales pearls in rows; head = bass, tail = treble
    float Q=3.+2.*step(.5,pr),u=mod(uP2.x-az,TAU)/4.5;
    float d=length(vec2(rho-1.22-.4*cos(Q*az),p.y-.4*sin(Q*az))),uc=min(u,1.);
    float r=.19*pow(1.-uc,.55)*smoothstep(-.004,.03,uc)+.085*exp(-(uc-.042)*(uc-.042)*1300.);
    float e=max(abs(d-r)*.68,min(u-1.,1.3963-u)*4.5*rho*.6);
    swV=uc*3.;swS=1.;
    g=vec4(e,1.,uc,mod(floor(uc*26.),2.));break;
  }
  case 11:{ // sheets. 9 MURMURATION: one thick sheet of birds folding and heaving inside a soft envelope, density
    // waves running through it. 11 WAVES: three stacked sheets rippling outward like cymatic plates (amplitude: the mids)
    float fl=0.,A=(.06+1.6*swRip)*(1.-fl);
    vec3 q=p+fl*.22*sin(p.y*2.1+p.x*1.3+uTime*.31)*vec3(1.,.5,-.8);
    float li=clamp(floor(q.y/.42+.5),-1.,1.)*(1.-fl),y=q.y-li*.42,rq=length(q.xz);
    float h=A*sin(rq*7.-uTime*3.-li*1.3)*clamp(1.1-.69*rq,0.,1.)+fl*.55*sin(q.x*1.7+uTime*.45)*cos(q.z*1.4-uTime*.35);
    float es=abs(y-h)/(1.+A*7.),env=mix(rq-1.45,length(q*vec3(.72,1.,.95))-1.2,fl),e;
    if(swSl>.5){   // v20: the sheets as string art: the flock in rows (or a net), the cymatic plates in rings (or rings and spokes)
      float hp=swPit*1.5,sx=TAU/16.;
      float cx=abs(fract(q.x/hp+.5)-.5)*hp,cz=abs(fract(q.z/hp+.5)-.5)*hp,cq=abs(fract(rq/hp+.5)-.5)*hp,ck=rq*abs(sin(mod(az+sx*.5,sx)-sx*.5));
      float net=step(2.5,swSl),cut=mix(mix(cq,min(cq,ck),net),mix(cx,min(cx,cz),net),fl);
      e=max(length(vec2(es,cut))*.8,env)*mix(1.,.5,fl);swS=1.;swV=mix(swV,q.z*.5,fl);
    }else{float rb=max(abs(fract(q.x/.4+.5)-.5)*.4-.11,0.)*fl;e=max(length(vec2(max(es-.04*fl,0.),rb)),env)*mix(1.,.45,fl);}   // v20: the solid murmuration flies as ribbons of birds, not one slab
    float dn=.3+.7*pow(.5+.5*sin(dot(q,vec3(3.1,1.2,-2.))-uTime*1.6),2.);
    g=vec4(e,mix(1.,dn,fl),mix(clamp(rq/1.45,0.,1.),clamp(.5+.4*q.x,0.,1.),fl),mix(li+1.,step(.6,dn),fl));break;
  }
  default:{ // v22 CHAIN (id 12): great rings threaded on each other. A hoop as wide as the figure; on it, opposite each other, two rings ride
    // like beads on a wire and slide round it with the flow; on each of those a smaller ring rides the other way, a quarter turn per beat.
    // Hollow tubes of dots (half the time ribbed like a coiled spring). The great hoop is the bass, the riders the mids, the small ones the treble
    float c1=cos(uP2.x),s1=sin(uP2.x),RA=1.2+.1*swLv.x,RB=.74+.07*swLv.y,RC=.42+.06*swLv.z;
    vec3 q=vec3(c1*p.x+s1*p.z,p.y,-s1*p.x+c1*p.z);if(q.x<0.)q.xz=-q.xz;
    vec3 pb=q-vec3(RA,0.,0.);
    float bb=uBar*4.,f2=-2.*uP2.x+1.5708*(floor(bb)+smoothstep(0.,.4,fract(bb))),c2=cos(f2),s2=sin(f2);
    vec3 pc=pb-RB*vec3(c2,s2,0.);float uu=pc.x*c2+pc.y*s2,nn=-pc.x*s2+pc.y*c2;
    float dA=abs(length(vec2(rho-RA,p.y))-.13),dB=abs(length(vec2(length(pb.xy)-RB,pb.z))-.1),dC=abs(length(vec2(length(vec2(uu,pc.z))-RC,nn))-.075);
    float vA=az*.159155,vB=swAt(pb.y,pb.x)*.159155,vC=swAt(pc.z,uu)*.159155;
    float wi=dA<min(dB,dC)?0.:(dB<dC?1.:2.),dm=min(dA,min(dB,dC)),vv=wi<.5?vA:(wi<1.5?vB:vC),Lr=TAU*(wi<.5?RA:(wi<1.5?RB:RC));
    swV=vv;
    if(pr>.5){float hp=swPit*1.25,nr=floor(Lr/hp);dm=length(vec2(dm,abs(fract(vv*nr+.5)-.5)*Lr/nr));swS=1.;}
    g=vec4(dm*.8,1.,.08+.36*wi+.1*abs(vv),wi+step(.5,fract(vv*6.)));
  }}
  // v20 STRING ART. A shell figure can be drawn as strings of dots instead of a dusted surface: hoops (the shell cut by
  // level planes), meridians (cut by planes through the axis), a cage of both, one spiral winding, or a net of two
  // opposite windings. The strings are true thin bands (distance to the shell combined with distance to the cut), so
  // they stay crisp, the far side shows through, and a finer lattice (higher detail tiers) draws more of them.
  if(swSl>.5&&(id<.5||abs(id-2.)<.5||abs(id-8.)<.5||abs(id-10.)<.5||abs(id-13.)<.5)){
    float h=swPit*(swSl<2.5?1.15:swSl<3.5?1.75:swSl<4.5?1.25:1.9),N=clamp(floor(5.2/h),6.,40.),s=TAU/N;
    float eh=abs(fract(p.y/h+.5)-.5)*h,em=rho*abs(sin(mod(az+s*.5,s)-s*.5));
    float tw=p.y/h-az*.159155*floor(1.+3.*fract(pr*7.7)),e1=abs(fract(tw+.5)-.5)*h*.8,e2=abs(fract(p.y/h+az*.159155*2.+.5)-.5)*h*.8;
    float e=swSl<1.5?eh:swSl<2.5?em:swSl<3.5?min(eh,em):swSl<4.5?e1:min(e1,e2);
    float alt=swSl<2.5?step(1.5,swSl):swSl<3.5?step(em,eh):swSl<4.5?0.:step(e2,e1);
    if(alt>.5&&swSl<3.5)swV=p.y*.45;
    g.x=length(vec2(g.x,e))*.72;g.w+=2.6*alt;swS=1.;
  }
  return g;
}
// every particle component at object point p. returns the skip margin; inf = (weight, spectrum coord, tag, kind)
float swField(vec3 p,float rr,out vec4 inf){
  float mg=1e9,best=0.,lp=length(p),lip=1.+swRip*(1.+8.*lp);inf=vec4(0.,0.,0.,-1.);
  vec3 pw=p*(1.+swRip*sin(lp*8.-uTime*4.))*(1.-.2*uB1.x*uDose-.06*uKick*uDose);   // v22b: the sub and the kick swell the bodies at once            // mids: a ripple runs outward through the figure
  for(int j=0;j<2+swZ;j++){
    float fj=float(j),mw=mix(1.-swM,swM,fj);
    if(mw<=0.)continue;
    vec3 dc=mix(swDcA,swDcB,fj);
    float sc=mix(1.+.55*swM*swM,.55+.45*swM,fj),ms=1.;    // the old figure blows outward, the new one condenses inward
    float bd=swBand*(1.+2.2*mix(swM,1.-swM,fj))*(1.+2.4*swDust)*(1.+1.3*uKick*uDose+.8*uHit*uDose);   // v22b: kick and snare scatter the members off the surface, then they snap back. and both are clouds while they pass through each other
    vec3 q=pw/sc;
    // Nine bodies form a living grove/reef. Each responds at a different phase and height.
    // v18: the swarm has formations. One huge sculpture, twins, a quartet, a carousel of eight, a trio, a totem, the grove,
    // or an atom (a big core with satellites); every morph can change the arrangement as well as the family
    // v22: the nearest body of this formation (its centre and scale); the others only bound the step
    float rbf=SWRB[clamp(int(dc.y),0,15)]*1.32;
    vec4 bb=fj<.5?swA0:swC0,B1=fj<.5?swA1:swC1,B2=fj<.5?swA2:swC2,B3=fj<.5?swA3:swC3;float bn=0.,m1=length(q-bb.xyz)-bb.w*rbf,m2=1e9,dk;
    if(B1.w>0.){dk=length(q-B1.xyz)-B1.w*rbf;if(dk<m1){m2=m1;m1=dk;bb=B1;bn=1.;}else m2=min(m2,dk);}
    if(B2.w>0.){dk=length(q-B2.xyz)-B2.w*rbf;if(dk<m1){m2=m1;m1=dk;bb=B2;bn=2.;}else m2=min(m2,dk);}
    if(B3.w>0.){dk=length(q-B3.xyz)-B3.w*rbf;if(dk<m1){m2=m1;m1=dk;bb=B3;bn=3.;}else m2=min(m2,dk);}
    q-=bb.xyz;
    float population=h21(vec2(bn*1.7+dc.y*3.17,dc.z*7.+bn)),part=step(bb.w,.7);
    // each body answers its own band: bass, mids or treble swell a third of the bodies each (on the smoothed levels)
    float bi=mod(bn,3.);
    { float hb=fract(uBeat+.5*step(.5,population));q.y-=part*(.03+.2*swLv.x)*4.*hb*(1.-hb)*bb.w; }   // v20: the bodies hop on the beat (half of them on the off-beat), as high as the bass is loud
    ms=bb.w*(1.+part*.3*dot(swLv,step(abs(vec3(0.,1.,2.)-bi),vec3(.5))));q/=ms;
    q.xz=rot(bn*1.7+.22*sin(uTime*.08+population*7.))*q.xz;
    swSl=dc.x>7.5&&bb.w>.44?floor(dc.x*.125):0.;if(abs(dc.y-8.)<.5&&swSl>3.5)swSl-=2.;swPit=swB0*7.4/(sc*ms);   // v20: strings only on bodies big enough to carry them; the lotus keeps to hoops, meridians and the cage
    vec4 g=swFig(dc.y,fract(dc.z+population*.6+bn*.18),q);g.x*=sc*ms/lip;
    float co=swLv.z*1.7*swB0*swCoL;                 // v20: the treble fizzes off the silhouette: a corona of sparks as deep as the highs are loud
    mg=min(mg,min(g.x,(m2-.2)*sc/lip)-bd-co);
    float w=clamp((bd-g.x)/(.55*bd),0.,1.)*clamp((mw*g.y*swBand/bd*1.15*(1.-.45*step(abs(g.w-1.),.5)*step(dc.y,.5))-rr)*6.+.5,0.,1.);
    if(w<=0.&&g.x<bd+co){float uc=(g.x-bd)/co,wc=.8*mw*step(.91+.09*uc,fract(rr*13.7+fj*.37));
      if(wc>best){best=wc;inf=vec4(wc,g.z,0.,4.);swQv=0.;swQs=0.;swQc=0.;}}
    if(w>best){best=w;inf=vec4(w,g.z,g.w+bn*.45,fj);swQv=swV;swQs=swS;swQc=clamp(1.-g.x/bd,0.,1.);}
  }
  if(swEx>.01){ // the drop: an expanding shell of sparks (v22: the tilted plane of orbit rings round the figure is gone)
    float es=abs(lp-swShR),bd=swBand*1.6;mg=min(mg,es-bd);
    float w=clamp((bd-es)/(.6*bd),0.,1.)*step(rr,.5)*swEx;
    if(w>best){best=w;inf=vec4(w,fract(rr*7.3),0.,2.);swQv=0.;swQs=0.;swQc=clamp(1.-es/bd,0.,1.);}
  }
  return mg;
}
// v21: the maker's constellation: a 5x7 dot face, ten characters and (m) a small cap-and-stem mark; p.x 0..66, p.y 0..7. 1 on a pearl
float swCst(vec2 p,float m){
  const ivec2 G[9]=ivec2[9](ivec2(508430,1086),ivec2(1020036,4228),ivec2(476721,17966),ivec2(583347,17969),ivec2(1032734,16927),ivec2(1001009,17982),ivec2(476735,17969),ivec2(1001022,16912),ivec2(491492,4238));
  const int W[11]=int[11](0,1,2,3,4,5,-1,6,7,4,8);
  int ci=clamp(int(p.x/6.),0,10),cx=int(p.x)-ci*6,g=W[ci],r=clamp(6-int(p.y),0,6),gi=max(g,0);
  bool ok=p.x>=0.&&p.x<66.&&p.y>=0.&&p.y<7.&&g>=0&&cx<=4&&(ci<10||m>.5);
  int bits=r<4?(G[gi].x>>((3-r)*5))&31:(G[gi].y>>((6-r)*5))&31;
  return ok?float((bits>>(4-cx))&1):0.;
}
float swPc(){return mix(uP4.y,uP4.z,step(0.,uP4.x));}
float swOp(float p){p=floor(p);return p<.5?1.:p<1.5?2.:p<2.5?5.:p<3.5?4.:p<4.5?3.:2.;}   // v22: the palette opposite (the worlds wear it, so the figure's hue never floods the sky)
vec3 swSky(vec3 rd,vec3 ro,float pixA,float pc){
  float dc=dot(rd,-ro)>0.?length(cross(ro,rd)):length(ro);
  // nebula: luminous aurora-like ribbons over the whole sky (ridges of domain-warped sines), slowly drifting;
  // the background dust gathers inside it, so the backdrop is made of the same dots as the figure
  float w1=sin(dot(rd,vec3(2.1,1.3,-.7))*1.6+uTime*.05);
  float w2=sin(dot(rd,vec3(-1.1,2.4,1.6))*1.4-uTime*.04);
  float n=.5*sin(dot(rd,vec3(1.7,-.9,2.3))*2.2+2.2*w1)+.5*sin(dot(rd,vec3(-2.,1.4,.8))*2.7+1.8*w2);
  float n2=.5+.5*sin(dot(rd,vec3(.9,2.2,-1.5))*1.8+1.5*w1*w2);
  float cl=smoothstep(.45,.95,1.-abs(n))*smoothstep(.15,.6,n2);
  { // v18: the sky has moods, one per palette step. 0 aurora ribbons, 1 a sunburst of rays out of the swarm, 2 slow halos
    // rippling outward around it
    float sm=mod(floor(pc)+floor(uSeed.x*3.),3.);
    vec3 hd=normalize(-ro),ea=normalize(cross(hd,vec3(.2,1.,.1))),eb=cross(hd,ea);
    float ca=dot(rd,hd),ra=sqrt(max(1.-ca,0.));
    float ang=swAt(dot(rd,eb),dot(rd,ea));
    float ry=pow(.5+.5*cos(ang*(11.+floor(uSeed.y*5.)*2.)+1.4*n+uTime*.12),6.)*smoothstep(1.3,.35,ra)*smoothstep(.12,.42,ra)*(.5+.5*n2)*(.45+1.1*swLv.x);
    float hl=.42*pow(.5+.5*sin(ra*34.-uTime*.9+1.5*n),3.)*smoothstep(1.3,.25,ra)*smoothstep(.12,.36,ra)*(.5+1.*swLv.y);
    cl=mix(cl,mix(ry,hl,step(1.5,sm)),step(.5,sm));
  }
#if HD>=1
  { // fine nebula filaments: ridged octaves that cut into the ribbons (they only ever remove or concentrate light), fading before they alias
    float am=.5,fq=6.,fil=0.,tot=0.;
    for(int o=swZ;o<SW_NEB;o++){float fo=float(o-swZ);
      float vis=clamp(.35/(fq*pixA)-.5,0.,1.);
      vec3 dq=vec3(1.7+fo*.7,-1.1+fo*1.3,2.3-fo*.9);
      float rn=1.-abs(sin(dot(rd,dq)*fq+1.7*n+fo*2.1+uTime*.03*(1.+fo)));
      fil+=am*vis*rn*rn;tot+=am*vis;am*=.62;fq*=2.03;}
    if(tot>.001)cl*=.55+.9*fil/tot;
  }
#endif
  float bnd=exp(-pow(dot(rd,swNU)*4.,2.));   // the band of swarms
  // the sky swaps palette halfway through a colour wave, hidden in a brief dip
  float swp=1.-step(.5,abs(floor(uP4.z)-floor(uP4.y)))*smoothstep(.7,.05,abs(uP4.x));
  float kx=fract(fract(pc)+.35+.3*cl+.25*n2)*4.;
  vec3 k0=mix(swStop(floor(pc),kx),swStop(floor(pc),kx+1.),fract(kx));k0=max(k0+(k0-dot(k0,vec3(.3333)))*.6,0.);   // the nebula walks along the palette
  k0.g*=1.-.35*clamp(k0.r-k0.b,0.,1.);                   // dim yellows read as olive: warm them toward amber
  vec3 ks=max(k0-.5*min(k0.r,min(k0.g,k0.b)),0.);   // saturated
  vec3 c=ks*((.04+.06*cl*cl+.03*n2+.03*bnd)*(.85+.3*uBass)*(1.+.5*swBu)+exp(-dc*dc*.4)*(.025+.07*uBass)
    +exp(-dc*dc*.06)*(.015+.03*uBass)*clamp(1.35-1.35*uZoom,0.,1.))*swp;   // v14: zoomed out a wide soft halo seats the reef in the nebula
  { // dust: star dots gathered into the nebula ribbons and the band (a few big soft bokeh motes); hats and air twinkle them
    vec3 q=rd*56.,ci=floor(q),hh=swH3(ci);
    float d=length(q-normalize(ci+.3+.4*hh)*56.),pw=56.*pixA,vz=clamp(floor(uP2.z)/48.,0.,1.),rad=pw*(.35+.9*hh.z*hh.z*hh.z)*(1.+1.1*cl+2.*vz)+.12*step(.93,hh.z)*hh.x;
    float s=step(1.-mix(.46+.4*bnd+.3*vz,.8,cl),hh.y)*smoothstep(rad+pw,rad*.2,d)*(.2+.7*hh.x*hh.x*hh.x)*(1.+1.5*cl)*(1.+1.6*vz)*(pw+.02)/(rad+pw)
           *(1.+2.*(uHat+uO2.w)*step(.82,hh.x)+1.5*uB2.w*step(.6,fract(hh.z*13.)))*(1.+1.8*fract(uP2.z));   // v22b: the lift (thin figure) brings the stars up
    c+=s*mix(k0,k0.zxy,hh.x*hh.x);
  }
#if HD<1
#define SW_DUST 1
#endif
  { // finer star dust, one octave at High and one more per tier: each octave has more stars and proportionally less light
    float Fq=112.,gn=.72;
    for(int o=swZ;o<SW_DUST;o++){
      vec3 q=rd*Fq+float(o-swZ)*3.7,ci=floor(q),hh=swH3(ci);
      float d=length(q-normalize(ci+.3+.4*hh)*Fq),pw=Fq*pixA,rad=pw*(.3+.7*hh.z*hh.z*hh.z);
      float vz=clamp(floor(uP2.z)/48.,0.,1.);rad*=1.+.8*cl+1.2*vz;
      float s=step(1.-mix(.2+.3*bnd+.3*vz,.7,cl),hh.y)*smoothstep(rad+pw,rad*.2,d)*(.12+.5*hh.x*hh.x*hh.x)*(1.+1.2*cl+1.2*vz)*(pw+.02)/(rad+pw)*(1.+1.6*(uHat+uO2.w)*step(.86,hh.x));
      c+=s*gn*mix(k0,k0.zxy,hh.x*hh.x);
      Fq*=2.;gn*=.68;
    }
  }
  { // v21: a few of the far stars hang in rows (fixed in the sky of this visit, low over the horizon; not there at all until the view is enlarged: they come in once a star of the row is about two screen pixels apart from the next)
    float az=uSeed.w*6.283+2.,el=.3+.35*uSeed.z;
    vec3 D=vec3(cos(el)*sin(az),sin(el),cos(el)*cos(az)),ex=normalize(cross(D,vec3(0.,1.,0.))),ey=cross(ex,D);
    vec2 cp=vec2(dot(rd,ex),dot(rd,ey))/.0011+vec2(33.,3.5);
    if(dot(rd,D)>.9&&abs(cp.x-33.)<34.&&abs(cp.y-3.5)<4.5){
      float cw=.0011/pixA,dd=length(fract(cp)-.5);
      c+=(k0*1.3+vec3(.9,.86,.8)*smoothstep(.3,.05,dd))*swCst(cp,step(.5,fract(uSeed.x*7.3)))*smoothstep(.46,.46-.6/max(cw,.6),dd)*smoothstep(1.5,2.1,cw)*.7*(1.2+.8*uHat);
    }
  }
  return c;
}
#if SW_SEA
// v21 THE SEA. Under the sculpture lies a world of pearls: a sphere so large that from the low camera it is a
// sea with a curved horizon. Its pearls sit on dotted rings on a logarithmic lattice (every ring holds the same number of dots and
// is a fixed ratio wider than the last), so it looks the same at every scale, from the pearls sliding under the lens to the limb.
// The rings are drawn as a lotus as wide as the world: tier on tier of petals around the figure, each tier 1.55 times the last
// (outlines, a vein, a dim filling; dark water between). It is what gives the figure its size: something to stand in the heart of
// and loom over. The rings step one slot per beat in opposite directions; thirds of them swell with bass, mids and treble; the
// spectrum is laid out along the radius; every kick sends a ring of light out to the horizon; on a drop the whole pattern changes
// behind a front that runs outward (the lotus, spiral arms, a twill of spokes, a woven check). It wears the palette opposite the
// figure's, so the figure never floods the frame with its own hue.
// In a breakdown, while the figure loosens into dust, the sea fills in (every other ring lights along its whole length) and glows:
// the quiet passage is the sea's.
// returns rgb and the distance along the ray (0: the ray misses the sea)
// the pattern at ring k, angle aw, in mode md: x how large the pearl is (0: dark water), y which of the two inks, z the ring's colour step
vec3 swSeaP(float aw,float k,float md,float th){
  float m=md<1.5?5.:(md<2.5?12.:72.),w=md<1.5?.26:(md<2.5?1.047:PI);
  float pt=.5+.5*cos(m*aw+w*k);vec3 o=vec3(smoothstep(.4,.88,pt),step(.6,pt),mod(k,3.));
  if(md<.5){ // the lotus: tiers of ten rings, twelve petals a tier (every other tier turned half a petal), wide at the base, pointed at the tip
    float tk=k*.1,f=fract(tk),ti=floor(tk),pa=abs(fract(aw*12./TAU+.5*mod(ti,2.))-.5)*2.,e=sqrt(1.-f)*.96-pa;
    float ol=step(0.,e)*step(e,.22*th),vn=step(pa,.09*th)*step(f,.75)*step(.15,f);
    o=vec3(max(max(ol,.62*vn),(.16+.42*(1.-f)*(1.-pa))*step(.22*th,e)),max(ol,vn),mod(ti,2.)+vn);   // outline, vein, and a filling of smaller pearls that thins toward the tip and the edge
  }
  o.x=max(o.x,min(swDust*1.6,.75)*step(.5,fract(k*.5+.25)));
  return o;
}
vec4 swSea(vec3 ro,vec3 rd,float pixA,float pc){
  const float RP=240.,SY=1.7,LG=.04363,CN=144.;
  vec3 o=vec3(0.);float tp=0.;
  vec3 oc=ro+vec3(0.,SY+RP,0.);
  float b=dot(oc,rd),hq=b*b-dot(oc,oc)+RP*RP;
  float pid=floor(pc),spl=pid<.5?1.:pid<1.5?2.:pid<2.5?5.:pid<3.5?4.:pid<4.5?3.:2.;   // the opposite palette: warm figure, cool sea
  if(hq>0.&&b<0.){
    tp=-b-sqrt(hq);
    vec3 nr=(oc+rd*tp)/RP;
    float sn=length(nr.xz),r=RP*asin(min(sn,1.)),ad=clamp(-dot(rd,nr),.03,1.);
    vec2 Ph=nr.xz/max(sn,1e-5),P=r*Ph;
    float u=log(max(r,.2)/.9)/LG,k=floor(u+.5),rk=.9*exp(k*LG),s=rk*LG,dir=mod(k,2.)*2.-1.;
    float px=tp*pixA;
    float spin=dir*(smoothstep(0.,.35,uBeat)*TAU/CN+uTime*.006*(1.+4./(1.+.075*max(k,0.))));
    vec2 vq=dot(rd,vec3(nr.y*Ph.x,-sn,nr.y*Ph.y))*Ph+dot(rd,vec3(-Ph.y,0.,Ph.x))*vec2(-Ph.y,Ph.x),vd=vq/max(length(vq),1e-5);   // the ray, laid into the map of the sea
    // A pearl is round to the eye however low the lens is. So the lower the ray skims the sea, the more pearls each ring carries
    // (and the smaller they are): the lattice stays square on the screen from under the lens out to the limb, never dashes or
    // bars. Between one count and its double the in-between pearls grow in from nothing while the others give way.
    float Lf=clamp(-log2(ad),0.,5.),L=floor(Lf),lf=Lf-L,c2=CN*exp2(L),sL=s/exp2(L),ang=(swAt(Ph.y,Ph.x)-spin)/TAU*c2;
    float fr=uDrop>.004?.9*exp(7.5*(1.-uDrop)):1e6,md=r<fr?mod(swCw,4.):mod(floor(swCw*.25),4.);   // the mode in force inside the drop's front, the one before it outside
    float lv=dot(swLv,vec3(equal(vec3(mod(k+30.,3.)),vec3(0.,1.,2.))));
    float uk=uP2.w*16.4,kb=exp(-(u-uk)*(u-uk)*.0075)*step(uP2.w,8.9);            // the kick's ring of light, racing out to the horizon
    float sw=1.+.4*lv+.4*kb;
    // each pearl owns a share of the ring as wide as it is large, so none is cut by its neighbour
    float j0=floor(ang+.5),pk=step(.5-.25*lf,abs(ang-j0)),jn=mix(j0,floor(ang)+.5,pk),aw=jn/c2*TAU+spin;
    vec3 pp=swSeaP(aw,k,md,exp2(-.55*Lf));   // (lines of the lotus stay a pearl or two wide however fine the pearls)
    vec2 dv=P-rk*vec2(cos(aw),sin(aw));
    float dd=length(dv-vd*dot(dv,vd)*(1.-ad)),qq=(.1+.19*pp.x)*sw*step(.12,pp.x+kb)*mix(1.-.5*lf,.5*lf,pk);
    float r0=sL*qq,rr=max(r0,px*.75),cov=clamp((rr-dd)/px+.5,0.,1.)*r0*r0/(rr*rr),jj=jn*exp2(6.-L);
    float fd=clamp(min(s*ad,sL)/px*.5-.6,0.,1.);                                       // rings closer than a few pixels melt into their mean (a thin line of light on the limb)
    cov=mix(2.6*qq*qq*(1.+pk),cov,fd);
    float x2=dd*dd/(rr*rr),big=clamp(rr/px*.4-1.,0.,1.)*fd;
    vec3 cc=swStop(spl,fract(pc)*4.+pp.z+2.*pp.y)*mix(1.,1.25-.9*min(x2,1.),big);
    cc=mix(cc,swStop(spl,fract(pc)*4.+pp.z+2.*pp.y+2.)*1.2,big*smoothstep(.45,.3,sqrt(x2))*pp.y);   // a pearl seen large has a heart of the other stop
    float fq=clamp(u*.008,0.,1.),spv=spec(.04+.88*fq);
    float hh=fract(sin(k*12.9898+jj*.78233)*43758.5453),tw=step(.78,hh)*(uHat+uO2.w+.6*uB2.w)*uDose;   // hats: one pearl in five flashes white
    float hiS=1.+2.2*(uB2.z+uB2.w+uO2.z)*uDose*step(hh,.4);                                              // highs and air: two in five glitter in their own colour
    // the figure's light lies on the sea as a path of glitter toward the lens (the mirrored ray from this pearl meets the figure), in the figure's own colours
    vec3 Xw=nr*RP-vec3(0.,SY+RP,0.),rm=reflect(rd,nr);float gb=dot(Xw,rm),gh=gb*gb-dot(Xw,Xw)+uP3.w*uP3.w*uP1.w*uP1.w*.5;
    float glit=gb<0.?smoothstep(0.,1.5,gh):0.;
    cc=mix(cc,swStop(pid,fract(pc)*4.+pp.z),.3*glit);   // (a tint only: at .7 a large near figure turned the sea under it its own colour and the whole frame went one hue)
    float nearF=smoothstep(.3,.9,r)*clamp(tp*.7-.25,0.,1.);
    float lit=(.44+1.6*spv*spv+.45*lv+.8*glit+2.2*swDust)*(1.+2.6*kb+.4*uKick)*hiS*nearF*exp(-tp*.0022)*swGain*clamp(2.-rr/(px*36.),0.,1.);   // (a pearl that would cover a tenth of the frame beside the lens fades out: no plain discs)
    o=(cc*lit+vec3(1.,.95,.9)*tw*2.6*nearF)*cov;
  }
  o*=1.-.9*swPl;                        // the water around the spray of pearls goes dark, a pool with soft edges
  return vec4(o,tp);
}
#endif
// once or twice a visit, for a second or two, a spray of pearls gathers out of the far dust into rows (uP4.w carries where, in its 8s: a
// place on a sphere round the figure; the code word how brightly), facing the lens, then scatters again
vec3 swRow;
void swMark(vec3 ro,vec3 rd,float pixA,float pc){
  swRow=vec3(0.);swPl=0.;
  float cA=floor(uP4.w*.125),al=mod(floor(swCw*.0625),16.)/15.;
  if(al>0.){
    float pid=floor(pc),spl=pid<.5?1.:pid<1.5?2.:pid<2.5?5.:pid<3.5?4.:pid<4.5?3.:2.;
    float pa=mod(cA,128.)*.0490874,pe=(floor(cA/128.)-16.)*.0654;
    vec3 A=40.*vec3(cos(pe)*cos(pa),sin(pe),cos(pe)*sin(pa))-ro,D=normalize(A),ex=normalize(uM1[0]-D*dot(uM1[0],D)),ey=cross(ex,D);
    float cw=max(.0011*uRes.x,2.2),pit=cw*pixA/1.2;
    vec2 cp=vec2(dot(rd,ex),dot(rd,ey))/(max(dot(rd,D),.2)*pit)+vec2(33.,2.5+3.*(1.-al)*(1.-al));
    float bx=length((cp-vec2(33.,3.5))/vec2(47.,9.));
    if(bx<1.){
      float dd=length(max(abs(fract(cp)-.5)-.1,0.)),mk=smoothstep(1.,.75,bx)*al;
      float pr=swCst(cp,step(.5,fract(uSeed.x*7.3+cA*.37)))*(1.-smoothstep(.36-.9/cw,.36,dd));
      swPl=smoothstep(1.,.45,bx)*al;
      swRow=(swStop(spl,fract(pc)*4.+1.)*.75+vec3(.95,.9,.82)*(.15+.25*(1.-smoothstep(.05,.3,dd))))*pr*mk*(.8+.5*uHat);   // v22: in open sky it read too plainly: fainter, coloured
    }
  }
}
// the universe of swarms: six titanic sculptures in the far sky, then a coarse world grid whose cells along swirling
// filaments of a band (through the main figure) hold smaller sculptures receding to the horizon. Each is a pointillist
// disc (m arms or petals, wound into a spiral or straight, or shells; plus a core) tilted in 3D and slowly tumbling
// (never edge-on), playing one band.
vec3 swFar(vec3 ro,vec3 rd,float pixA,float pc){
  const float G=8.;
  vec3 e1=normalize(cross(swNU,vec3(.3,.1,1.))),e2=cross(swNU,e1);
  vec3 st=step(0.,rd)*2.-1.,rS=rd+1e-6*st,td=abs(G/rS),ce=floor(ro/G),tn=((ce+step(0.,rd))*G-ro)/rS;
  float shk=(uP3.y-.3)*48.,lro=length(ro),pf=fract(pc)*4.,zf=clamp(max(max(1.3-1.3*uZoom,floor(uP2.z)/48.),max(fract(uP2.z)/.99,1.4*swDust)),0.,1.);   // v22b: while the figure is a morph cloud or breakdown dust, the universe fills in and carries the frame   // zf: zoomed out (or a vista), the universe fills in
  vec3 acc=vec3(0.);float cov=0.;
#if HD>=1
  for(int i=0;i<SW_FAR+4+swZ;i++){
#else
  for(int i=0;i<34+swZ;i++){
#endif
    // the first six are titans: colossal sculptures around the band, far out; then the grid cells along the ray
    float ti=step(float(i),9.5),an=float(i)*.62832+uSeed.z*6.3,tfd=1.;
    if(ti>.5){   // v22: no world stands in the cone behind the figure (the owner's "big circular thing" behind and below the swarm): the ten are spread
      // over the rest of the circle, out to the sides of the frame, and one passing through the cone fades out on its way across
      float va=swAt(-ro.z,-ro.x),d=mod(an-va+PI,TAU)-PI,ad=abs(d);an=va+sign(d)*(.5+ad*(PI-.5)/PI);tfd=smoothstep(.03,.3,ad);}
    vec3 h=swH3(mix(ce+vec3(17.3,-41.,9.7)*(1.+floor(uSeed.w*7.)),vec3(float(i)*3.1,uSeed.w*50.,7.),ti));
    vec3 C=mix((ce+.5+(h-.5)*.55)*G,vec3(cos(an),.18+.7*h.z,sin(an))*320.,ti);C+=(1.-ti)*swNU*1.5*uKick;   // v22b: the far swarms hop on the kick. v22: the worlds hang in the sky round the figure, none below it
    // v14: the universe is composed rather than scattered. When the view widens, the small swarms gather into two
    // logarithmic spiral arms winding around the reef, with a dark lane between them and the six titans standing in a
    // crown around it; at the default framing the older wavy band still holds them, so the background never empties
    float lc=length(C),y=dot(C,swNU),q1=dot(C,e1),q2=dot(C,e2),rr=length(vec2(q1,q2));
    float band=.5+.5*sin(.085*q1+.06*abs(q2)+uSeed.z*6.3),band2=band*band;
    float spi=.5+.5*cos(2.*(swAt(q2,q1)-1.45*log(rr+7.))+uSeed.z*6.3),spi2=spi*spi;
    float zz=clamp(zf*1.35,0.,1.),dp=mix(.26+.62*band2,.22+.78*spi2,zz);   // keep probability along the arms
    float R=mix(G*(.05+.12*h.y*h.y+.2*zf*(.2+h.y*h.y))*clamp(lc/25.,.4,1.2),(84.+72.*h.y)*(.62+.2*zf*zf),ti),n=mix(14.+14.*h.z,56.,ti);
#if HD>=1
    n=floor(n*SW_FN);
#endif
    // v14: zoomed out, the far swarms dim inside a clearing a few reef radii wide, so the colony reads as the bright
    // subject of a composed picture; the clearing only exists while the view is widened (the default framing keeps its
    // full background)
    vec3 cr=cross(C,ro);float crl=length(cr),bimp=crl*inversesqrt(max(dot(C-ro,C-ro),1e-3));
    float ok=max(step(h.x,(.86+.4*floor(uP2.z)/48.)*dp*max(1.-y*y*.0016,0.))*step(5.5,lc)*step(3.*lro,crl),ti);
    vec3 m=step(tn,tn.yzx)*step(tn,tn.zxy)*(1.-ti);ce+=m*st;tn+=m*td;
    vec3 v=C-ro;float tc=dot(v,rd);vec3 w=rd*tc-v;
    if(ti<.5&&tc<3.2*R)ok=0.;   // v13: no grid swarm swells into a giant soft disc beside the lens
    float gl=ti*step(.01,tfd),kbw=0.,hw=0.,rgo=0.;
    if(ok>.5&&tc>.5&&dot(w,w)<R*R*(1.+3.6*gl)){
      // the disc's plane: a slowly tumbling world direction, biased toward the viewer so it is never edge-on
      float ta=h.z*6.3+uTime*(.04+.08*h.x),tb=(h.x-.5)*3.+uTime*(.02+.03*h.y);
      vec3 nS=normalize(mix(vec3(cos(ta)*cos(tb),sin(tb),sin(ta)*cos(tb))-1.1*rd,-v,gl));
      float sg=nS.z>=0.?1.:-1.,a=-1./(sg+nS.z),b=nS.x*nS.y*a,tp=dot(v,nS)/min(dot(rd,nS),-.05);
      vec3 pp=rd*tp-v;
      vec2 q=vec2(dot(pp,vec3(1.+sg*nS.x*nS.x*a,sg*b,-sg*nS.x)),dot(pp,vec3(b,sg+nS.y*nS.y*a,-nS.y)))/R;
      // v20: every far swarm is a mandala of dots on a polar lattice (rings of evenly spaced dots, the count on each ring a
      // multiple of the swarm's symmetry), drawn in dot size: petals, alternating rings, a core. The rings step one slot per
      // beat in opposite directions, so the dots march through the petals like chaser lights; two palette stops per swarm.
      float px=tp*pixA/R,nr=max(floor(n*.5),3.),s=1./nr;
      float r=length(q),k=min(floor(r*nr),nr-1.),rk=(k+.5)*s;
      float sy=3.+floor(h.z*5.99),cnt=sy*max(1.,floor(TAU*rk*nr/sy*.8+.5));
      float spin=(mod(k,2.)*2.-1.)*smoothstep(0.,.35,uBeat)*TAU/cnt;
      float aw=floor((swAt(q.y,q.x)-spin)/TAU*cnt+.5)/cnt*TAU+spin;
      vec2 cp=rk*vec2(cos(aw),sin(aw));
      float pet=.5+.5*cos(sy*aw+(floor(fract(h.y*3.7)*3.)-1.)*r*5.+uTime*(.6*h.y-.3)),alt=step(.5,fract(k*.5+.25));
      float S=mix(pet*pet,(.3+.7*alt)*(.45+.55*pet),step(.55,fract(h.y*5.3)))*clamp(2.1-2.1*r,0.,1.)+exp(-r*r*26.);
      float vis=step(r,1.);
      if(gl>.5){
        // v21: two in three of the titans are worlds: a globe of dots on lines of latitude (bands and petals in dot size, turning in
        // beat steps), most of them wearing rings of dots, leaning and slowly nodding. q is the view of it from the lens.
        float a1=(h.x-.5)*1.6,a2=.3+.2*sin(uTime*.03+h.z*6.3);
        vec3 ay=normalize(vec3(sin(a1),cos(a1)*cos(a2),cos(a1)*sin(a2))),bx=normalize(cross(ay,vec3(0.,0.,1.))),cz=cross(bx,ay);
        float nl=nr*3.,nq=max(floor(nr*.5),3.),sR=.74/nq;
        vec2 rc=vec2(q.x*cz.y-q.y*cz.x,bx.x*q.y-bx.y*q.x)/(bx.x*cz.y-bx.y*cz.x);   // where the ring plane is met: (rho cos, rho sin)
        float rho=length(rc),zr=dot(rc,vec2(bx.z,cz.z));
        float kq=min(floor((rho-1.38)/sR),nq-1.),rq=1.38+(kq+.5)*sR,cq=floor(TAU*rq/sR*.9);
        float lq=floor((swAt(rc.y,rc.x)-(mod(kq,2.)*2.-1.)*smoothstep(0.,.35,uBeat)*TAU/cq)/TAU*cq+.5)/cq*TAU+(mod(kq,2.)*2.-1.)*smoothstep(0.,.35,uBeat)*TAU/cq;
        float rg=step(.45,fract(h.y*7.7))*step(1.38,rho)*step(rho,2.12)*max(step(1.,r),step(0.,zr));rgo=rg;
        vec3 Sg=vec3(q,sqrt(max(1.-r*r,0.)));
        float sl=clamp(dot(Sg,ay),-1.,1.),kl=clamp(floor((swAt(sl,sqrt(1.-sl*sl))/PI+.5)*nl),0.,nl-1.),ph=((kl+.5)/nl-.5)*PI;
        float cg=sy*max(1.,floor(cos(ph)*nl*1.6/sy+.5)),sp2=(mod(kl,2.)*2.-1.)*smoothstep(0.,.35,uBeat)*TAU/cg+uTime*.05*(h.y-.5);
        float lg=floor((swAt(dot(Sg,cz),dot(Sg,bx))-sp2)/TAU*cg+.5)/cg*TAU+sp2;
        vec3 Pd=cos(ph)*(bx*cos(lg)+cz*sin(lg))+ay*sin(ph);
        float pg=.5+.5*cos(sy*(lg-sp2)+(floor(fract(h.y*3.7)*3.)-1.)*ph*4.),ag=step(.5,fract(kl*.25+.125));
        float Sgl=mix(pg*pg,(.3+.7*ag)*(.45+.55*pg),step(.55,fract(h.y*5.3)));
        cp=mix(Pd.xy,rq*(bx.xy*cos(lq)+cz.xy*sin(lq)),rg);s=mix(PI/nl,sR,rg);k=mix(kl,kq,rg);
        alt=mix(ag,step(.5,fract(kq*.5+.25)),rg);pet=mix(pg,.4,rg);
        S=mix(Sgl,(.35+.65*alt)*step(.5,abs(kq-floor(nq*.45))),rg);vis=max(vis,rg);
        { float uw=mix(kl/nl,kq/nq,rg)-uP2.w*.42;kbw=exp(-uw*uw*40.)*step(uP2.w,2.8);     // v22: every kick sends a band of light across each world, pole to pole (it used to run out over the sea)
          hw=fract(sin(k*12.9898+floor(mix(lg,lq,rg)*40.)*.78233+h.x*9.)*43758.5453); }
      }
      float r0=s*(.06+.3*min(S,1.))*(1.-.22*gl)*(1.+.55*dot(swLv,vec3(equal(vec3(mod(k,3.)),vec3(0.,1.,2.))))+.3*uKick+.45*kbw+.5*uBass*gl+1.2*uBass*rgo)*mix(1.,.6,ti)*(1.5-.5*clamp((s/px-1.)*.333,0.,1.)),ra=max(r0,px*.75);
      float ci=pf+floor(h.y*4.)+alt+2.*step(.62,pet)*step(.5,fract(h.x*7.3));
      float lit=(3.05+7.*spec(.04+.88*fract(h.x*13.7)))*swGain*(.7+.3*zf)*(1.-.5*gl)*(1.+2.6*kbw+1.5*swDust*ti)*(1.+1.6*(uB2.z+uB2.w+uO2.z)*uDose*step(hw,.4)*gl+2.6*(uB2.x+uB2.y+uO2.x)*uDose*step(.4,hw)*step(hw,.8)*gl)*(1.+1.2*uHit+(1.4*uBass+.9*uKick)*gl)   /* v22: the worlds breathe with the bass and the kick */*(i<10?.42+.3*zf:clamp(tp*.29-.14,0.,1.)*(.22+.78*exp(-tp*.0055)))
               *(1.+5.*uP3.x*exp(-(length(C)-shk)*(length(C)-shk)*.0123))       // each plays one band; the drop's shock front lights them as it passes
               // v12: and each flares on its own band's onsets and swells with that band's level; kicks pulse them all
               // (fully when zoomed out, where they are the picture; a quarter of that at the default framing)
               *(1.+(1.+.3*clamp((1.-uZoom)*1.7,0.,1.))*min(2.2*uKick+1.2*uHit+1.6*dot(fract(h.y*5.3)<.5?uO1:uO2,vec4(equal(vec4(floor(fract(h.y*9.7)*4.)),vec4(0.,1.,2.,3.))))+2.6*max(dot(fract(h.y*5.3)<.5?uB1:uB2,vec4(equal(vec4(floor(fract(h.y*9.7)*4.)),vec4(0.,1.,2.,3.))))-.45,0.),2.2))
               *(1.-max(.4*(.25+.75*clamp(2.6-2.6*uZoom,0.,1.))*(1.-fract(uP2.z)),.4*clamp(zf*2.,0.,1.)*(1.-fract(uP2.z)))*(1.-smoothstep(2.5+3.*zf,4.5+6.*zf,bimp)));   // v14: the clearing dims the deep field around the reef (the arms and the reef stay bright)
      vec3 wk=swStop(gl>.5||fract(h.y*3.3)<.4?swOp(pc):floor(pc),ci);wk=max(wk-.5*min(wk.r,min(wk.g,wk.b)),0.)*1.3;   // v22b: saturated (the pearl stop read white at loud drops)
      vec3 wc=wk*(lit+step(.8,hw)*(uHat+uO2.w+.6*uB2.w)*uDose*1.4*gl);wc*=min(1.,7./max(max(wc.r,wc.g),max(wc.b,1e-3)));   // v22b: hue-kept ceiling (pale world cores at loud drops)
      acc+=tfd*wc*clamp((ra-length(q-cp))/px+.5,0.,1.)*r0*r0/(ra*ra)*vis*(.64+.36*zf)*(1.-cov);   // v22: hats flash one dot in five of every world
      if(ti<.5)cov=max(cov,.9*step(r,1.));   // v20: a nearer mandala hides the ones behind it (no interleaved lattices, no pastel sums)
    }
  }
  return acc;
}
#if HD>=1
vec3 swPic(vec2 sp){
#else
void realm(){
  swZ=min(int(uTime),0);
#endif
  // zoom out: the camera pulls back and the view widens (at .15 about 88 degrees across: no fisheye); the hero stays
  // readable while the universe opens up around it
  // v13: zoomed out the camera keeps backing away (x2.3 at .15) while the view widens less, so every step of the wheel
  // shrinks the hero into a larger universe; zoomed in it glides toward the figure and the lens narrows
  float zIn=max(uZoom,1.),zOut=min(uZoom,1.);
  float zw=pow(zOut,-.17)*pow(zIn,-.4),fl=1.35,pixA=1.2*zw/(uRes.y*fl);   // v22: a wider lens, nearer (1.75 before): the figure towers over the lens
#if HD>=1
  vec3 ro=uP5.xyz*pow(zIn,-.7)*pow(zOut,-.2),rd=normalize(mat3(uM1[0],uM1[1],cross(uM1[1],uM1[0]))*vec3(sp*zw,fl));
#else
  vec3 ro=uP5.xyz*pow(zIn,-.7)*pow(zOut,-.2),rd=normalize(mat3(uM1[0],uM1[1],cross(uM1[1],uM1[0]))*vec3(scr()*zw,fl));
#endif
  swBu=fract(uP3.z);swCw=floor(uP3.z);
  swLv=uM2[2];swGain=floor(uP5.w)/256.;
  swRip=uM1[2].x;swDust=uM1[2].y;swDance=fract(uM1[2].z);swVoc=floor(uM1[2].z*.5)/63.;
  swGr=uP2.y>60.?uP2.y-100.:1.;
  swNU=normalize(vec3(sin(uSeed.x*6.3),.5+.3*cos(uSeed.y*6.3),cos(uSeed.x*6.3)));   // v21: the band stands 50 to 80 degrees from the sea
  float pc=swPc();
  vec3 col=swSky(rd,ro,pixA,pc),far=swFar(ro,rd,pixA,pc);
  swMark(ro,rd,pixA,pc);far+=swRow;   // v22: the spray hangs behind the figure (it was laid over it)
#if SW_SEA
  vec4 sea=swSea(ro,rd,pixA,pc);float seaF=0.;
  if(sea.w>0.){col*=.5;far*=.4;}   // the sea is dark water: what lies below its horizon shows only faintly
#endif
  float lift=fract(uP2.z)/.99;   // v22b: the figure is thin on screen: the universe carries the frame
  col*=(1.+.8*(1.-zOut))*(1.+1.1*swDust+.6*lift);far*=(1.+.6*(1.-zOut))*(1.+.8*swDust+2.*lift);   // v22: a breakdown lifts the sky and the far swarms (the sea did that)   // v13: the wider the view, the brighter the nebula and the far swarms (no dark voids)
#if HD>=1
  col*=.86;   // the extra dust and filaments are paid for out of the nebula, so the black share of the frame holds
#endif
  swDcA=vec3(floor(uP1.x/16.),mod(floor(uP1.x),16.),fract(uP1.x));swDcB=vec3(floor(uP1.y/16.),mod(floor(uP1.y),16.),fract(uP1.y));
  swM=uP1.z;swHx=step(abs(swDcA.y-5.),.5);
  { float ph=fract(uP5.w)*TAU/.999,tg=1.-.3*swBu;   // the choreography's phase (it steps on the beat); a build draws the bodies in
    swSet(mod(swDcA.x,8.),ph,tg,swA0,swA1,swA2,swA3);swSet(mod(swDcB.x,8.),ph,tg,swC0,swC1,swC2,swC3); }
  swEx=uP3.x;swShR=uP3.y;
  swCo=1.8*(1.-.3*swBu)+.7*uP3.x;
  float sc=max(uP1.w,.1);
  mat3 Rm=mat3(uM2[0],uM2[1],cross(uM2[0],uM2[1]));vec3 roO=(Rm*ro)/sc,rdO=Rm*rd;
#if HD>=1
  swL=normalize(Rm*(uM1[1]*.7-uM1[0]*.45-cross(uM1[1],uM1[0])*.55));   // v20: toward a light above, left of and behind the camera
#endif
  float det=clamp(uDetail,.5,16.),cs=.03/pow(det,.33);   // v22: a finer lattice (.046 before): about twice the members on every surface, each smaller
  swBand=.62*cs;swB0=swBand;swCoL=1.;
  float Rb=uP3.w,b=dot(roO,rdO),h=b*b-dot(roO,roO)+Rb*Rb;
  if(h>0.){
    float t=max(-b-sqrt(h),0.),t1=-b+sqrt(h);
#if SW_SEA
    seaF=step(sea.w,t*sc);                           // the sea's pearls between the lens and the figure are not hidden by it
#endif
    mat3 Rt=mat3(.92106,.38942,0.,-.38942,.92106,0.,0.,0.,1.)*mat3(1.,0.,0.,0.,.95534,.29552,0.,-.29552,.95534); // fixed tilt of the lattice
    float ca=cos(uP2.x),sa=sin(uP2.x);
    mat3 mG=Rt*mat3(ca,0.,-sa,0.,1.,0.,sa,0.,ca),mGi=transpose(mG);
    vec3 hv=vec3(0.,uP2.y>60.?0.:uP2.y,0.),roG=mG*(roO-hv),rdG=mG*rdO;
    vec3 sgn=step(0.,rdG),ird=1./(rdG+sgn*2e-6-1e-6);
    float wdA=mod(uP4.w,8.);vec3 wdir=normalize(vec3(cos(wdA),.55*sin(wdA*1.7),sin(wdA)));
    float wOn=step(uP4.x,1.69),T=1.,oc=1.,bt=4.+8.*swBu;
    vec3 acc=vec3(0.);float lro0=length(ro);
    vec3 exG=mG*(Rm*uM1[0]),eyG=mG*(Rm*uM1[1]);   // the camera's right and up in lattice space: every bead has a screen-plane frame
#if HD>=1
    float maxIt=(SW_LAT>1?135.:110.)*pow(det,SW_IE);
    float t00=t,cs0=cs;
    // more lattices of dots through the same figure: each one finer and offset, with its share of the light
    for(int lat=swZ;lat<SW_LAT;lat++){
    float latF=float(lat-swZ);t=t00;cs=cs0*(1.-.26*latF);swBand=.62*cs;swCoL=step(latF,.5);   // the treble corona belongs to the first lattice only: the finer ones keep to the forms
    float latG=1./(1.+.75*latF);vec3 roG0=roG+latF*vec3(.0171,.0093,.0137);
#else
    float maxIt=65.*pow(det,.45);   // v22: the dots are nearly opaque now, so a ray is done sooner (cost at High)
    const float latF=0.;vec3 roG0=roG;
#endif
    for(int i=0;i<1200;i++){
      if(float(i)>=maxIt||t>t1||T<.04)break;
      vec3 pG=roG0+rdG*t,cell=floor(pG/cs),hc=swH3(cell+latF*7.1);
      vec3 sG=(cell+.5+(hc-.5)*.7)*cs,sP=mGi*sG+hv;
      float rr=fract(hc.x*7.31+hc.y*3.17+hc.z*1.93);
      vec4 inf;
      float mg=swField(sP,rr,inf);
      vec3 tx=((cell+sgn)*cs-roG0)*ird;
      if(inf.x>.003){
        oc*=1.-.6*inf.x;   // the figure's dot cloud screens what lies behind it
        vec3 v=sG-roG0;float tp=dot(v,rdG);vec3 off=v-rdG*tp;
        float dist=length(off),pw=max(tp,.05)*pixA;
        float fq=inf.y,kind=inf.w,isk=step(abs(kind-2.),.5);   // isk: a spark of the drop's shock shell
        float spv=spec(.03+.9*fq);
        // v13: zoomed in, dots shrink in the world as the camera nears them, so the figure opens into crisp separate
        // points (and the dots behind show through) instead of swelling into soft blobs
        // v14: and their halos are cut as the camera flies in, while the cores carry the energy: sculpted points, not a wash
        float zi=clamp((zIn-1.)*.8,0.,1.),zi2=clamp((zIn-1.)*.8-.1,0.,1.);
        float side=dot(sP,wdir)-uP4.x,lr=length(sP);
        float pc=mix(uP4.z,uP4.y,step(0.,side)),pid=floor(pc),pof=fract(pc);                // the snare wave leaves the next colour step behind it
        // v20 BEADWORK. The dots are no longer all alike. Along a string-art figure's strings (and the orbit rings) they swell
        // into pearls at regular stations, so every hoop is a necklace and the pearls of neighbouring hoops line up in rows;
        // in a solid figure a few scattered dots are pearls among the seed beads. The mids pump the pearls.
        float md=clamp(swLv.y*1.5,0.,1.),own=step(kind,1.5);
        float hs=fract((pid+1.)*(.37+.61*uSeed.z)),nv=mix(12.+4.*floor(hs*4.),16.+8.*floor(fq*4.6),step(2.5,kind));
        float cr=.5+.5*cos(TAU*(swQv*nv-smoothstep(0.,.3,uBeat))),rq=fract(rr*9.7),str=max(swQs*own,step(2.5,kind)),ln=mix(rq*rq*rq*rq*rq,(.5+.5*cr*cr*cr)*sqrt(swQc),str);
        float jm=max(abs(hc.x-.5),max(abs(hc.y-.5),abs(hc.z-.5))),cap=.5-.7*jm;   // the largest bead that still fits inside this particle's own cell
        float pearl=ln*(.5+.5*md+.3*uKick);
        float rs=(.058+.045*hc.z)*(1.-.2*str)*(1.+.3*spv+.2*uKick+.25*uBass*uDose+.2*md)*sqrt(clamp(tp*sc/lro0,.3,1.));   // v22: smaller, and a dot close to the lens is held back so the near side of the figure is fine grain too
        float rad=cs*min(mix(mix(rs,.3,zi2),mix(.31,.46,zi2),pearl),cap)*pow(zIn,-.1);   // v22: pearls are smaller (.47 of a cell before); flown into, every dot grows into a bead that can be read
        float r=max(rad,pw*.7),en=rad*rad/(r*r);
        float core=clamp((r-dist)/pw+.5,0.,1.);
        float halo=exp(-dist*dist/(r*r*1.6))*clamp(2.-dist/(.06*cs),0.,1.)*(1.-.4*zi);
        if(core+halo>.002){
          float dep=dot(sP-vec3(0.,sP.y*swHx*step(kind,1.5),0.),rdO);   // depth from the figure's centre (the helix: its axis)
          float pt=fq*.72+pof+inf.z*.19+.09*dep;                  // each ornament line: one palette stop; depth still walks the hue a little
          vec3 cc=swPal(pid,pt);
          // v20: a bead that covers a few pixels is drawn as one: limb, glint, and for some a moat around a heart of the opposite
          // colour or a rosette of smaller dots (a dot made of dots). Small ones stay plain points.
          float rp=r/pw,big=clamp(rp*.62-.95,0.,1.);   // v22: designs come in on smaller beads (zoom 2.5 was plain dots)
          if(big>0.){
            vec2 o2=vec2(dot(off,exG),dot(off,eyG))/r;float x2=dot(o2,o2),xr=sqrt(x2),aa=1.2/rp,ty=fract(hc.x*5.71+hc.z*3.3);
            vec3 cB=swPal(pid,pt+.5);vec2 sd=o2-vec2(-.34,.38);float an2=swAt(o2.y,o2.x),big2=clamp(rp*.5-1.2,0.,1.);
            vec3 bead=cc*(1.22-.9*x2);
            if(ty<.38){   // ringed eye
              bead=mix(bead,cB*1.3,smoothstep(.36+aa,.36-aa,xr))*(1.-.9*smoothstep(.36,.36+aa,xr)*smoothstep(.64,.64-aa,xr));
            }else if(ty<.62){   // rosette: six or eight petals of dots around a heart
              float N=6.+2.*step(.5,fract(hc.y*9.1)),sec=TAU/N;
              float af=mod(an2+hc.z*6.+sec*.5,sec)-sec*.5;
              float ds=length(xr*vec2(cos(af),sin(af))-vec2(.7,0.));
              vec3 ro2=cc*1.15*smoothstep(.26+aa,.26-aa,ds)+cB*1.3*smoothstep(.3+aa,.3-aa,xr);
              bead=mix(bead,ro2,big2);
            }else if(ty<.82){   // v21 pinwheel: five to seven arms of the other colour winding out of a heart
              float pwh=cos((5.+floor(hc.y*2.99))*an2+xr*(hc.z<.5?-5.:5.)+hc.x*40.);
              bead=mix(bead,mix(bead,cB*1.25,smoothstep(-aa*2.,aa*2.,pwh)*smoothstep(.2,.3,xr)*smoothstep(.97,.9,xr))+cB*1.2*smoothstep(.2+aa,.2-aa,xr),big2);
            }else{   // v21 target: rings of the two colours
              bead=mix(bead,mix(bead,cB*1.25,smoothstep(-aa*3.,aa*3.,cos(xr*15.7))*smoothstep(.97,.9,xr)),big2);
            }
            { // a bead that fills many pixels wears a lace collar: a ring of seed dots around a smaller body (more pixels, more ornament)
              float lace=clamp(rp*.25-1.5,0.,1.)*step(.12,abs(ty-.5))*step(ty,.62);
              if(lace>0.){float Nl=10.+4.*floor(hc.z*3.),sl=TAU/Nl,al=mod(an2-hc.x*6.+sl*.5,sl)-sl*.5;
                float dl=length(xr*vec2(cos(al),sin(al))-vec2(.88,0.));vec2 oi=o2/.74;float xi=dot(oi,oi);
                vec3 inner=bead*step(xi,1.);   // the body, drawn again at three quarters size
                bead=mix(bead,inner*smoothstep(1.,1.-aa*2.,sqrt(xi))+cB*1.2*smoothstep(.1+aa,.1-aa,dl),lace);}
            }
            // hats and air: a four-point glint crosses the pearls
            float gl4=(exp(-abs(o2.x)*7.-abs(o2.y)*1.1)+exp(-abs(o2.y)*7.-abs(o2.x)*1.1))*(uHat+uO2.w+.7*uB2.w)*uDose*step(.7,fract(hc.y*31.7));
            cc=mix(cc,bead+vec3(1.,.96,.9)*(.3*exp(-dot(sd,sd)*18.)+1.1*gl4),big);
          }
          // per band: every dot belongs to one band (its region of the figure, dithered); that band's onset flashes it
          float bnd=clamp(floor(fq*8.+(hc.z-.5)*3.),0.,7.);vec4 bm=step(abs(bnd-4.*step(3.5,bnd)-vec4(0.,1.,2.,3.)),vec4(.5));float onb=dot(bnd<3.5?uO1:uO2,bm)*step(.62,fract(hc.y*23.1));
          // v12: and every band's level lights its own region of the figure (loud vocals glow the presence region)
          float lvb=dot(bnd<3.5?uB1:uB2,bm);
          float kd=(lr-uP2.w)*5.,rpl=.5+.5*sin(lr*8.+fq*6.*swBu-uTime*bt);   // kick: a shell of light races outward through the figure; rpl: the mid-ripple rings
          float br=(.9+1.8*spv*spv*uDose+.8*uBass*uDose)*(1.+1.35*uKick+1.6*uHit)*(1.+.8*swBu)
                  *(1.+step(2.5,kind)*(2.2*uHigh+2.4*uO2.z)*uDose)*(1.+3.*onb*uDose)*(1.+(1.5+1.5*step(5.5,bnd))*max(lvb-.5,0.)*uDose+1.8*max(uO2.x,uO2.y)*smoothstep(.4,.75,fq)*uDose)   // treble lights the orbit rings; vocal attacks the upper figure
                  *(1.+3.2*exp(-kd*kd)*max(1.-uP2.w*.45,0.)*uDose)*(1.5-1.28*clamp(dep*.4545+.4545,0.,1.))   // depth: the far side recedes
                  *(1.-.6*swBu+(6.*swRip+4.*swBu)*rpl*rpl*rpl*rpl)   // the mid ripple is also a ring of light; builds: rings race outward ever faster
                  *(1.+6.*uB1.x*uDose*exp(-pow((fract(fq*2.-uTime*.45)-.5)*5.,2.)))   // v22b: the sub runs a ring of lit members along every body
                  *(1.+1.1*zi);   // v14: zoomed in the cores carry the energy the cut halo used to
          float tph=uTime*2.4+hc.z*11.,tf=1.-abs(2.*fract(tph)-1.);float tw=(uHat+.8*uB2.w+uO2.z)*uDose*step(.89-.05*uB2.z-.1*uHat,fract(hc.y*17.3+floor(tph)*.618))*tf*tf*(4.2+6.5*fq);  // hats/air: a fresh few % of the dots flash white
          cc*=1.+1.6*isk*swEx;   // v22: the burst lights its sparks in their own colour (it used to add white: a pale peach cloud)
          { float isc=step(3.5,kind);cc=mix(cc,vec3(1.,.9,.72),.5*isc)*(1.-isc*(.8-.8*tf*tf)); }   // corona sparks: pale gold, each fading in and out
          float fr=wOn*exp(-side*side*90.);
          cc*=br+5.*fr+.25*onb+1.3*swEx*swEx;
          cc*=min(1.,mix(3.2,1.25,big)/max(cc.r,max(cc.g,cc.b)));   // v22b: 2.9 (3.2): the burst and loud drops glared whitish     // v20: a hue-preserving ceiling per bead, so loud passages saturate instead of bleaching
          cc+=mix(vec3(1.,.95,.9),cc/max(max(cc.r,max(cc.g,cc.b)),.05),.3)*(tw*1.4+.3*fr)*(1.-.6*big);   // v22b: twinkles carry a third of the bead's own colour   // v22b: twinkles in the bead's own colour (white added up to pale cores)
#if HD>=1
          { // a light ray marched through the sculpture from this dot: the far side of every form falls into its own coloured shade
            float lt=.8;
            if(T>.1&&core>.03&&latF<.5){   // v22: only the first lattice marches its light (the finer ones take its shade); cost
              float occ=0.,stp=cs*2.2;
              for(int o=swZ;o<SW_OCC;o++){float fo=float(o-swZ)+1.;vec4 oi;
                float mo=swField(sP+swL*stp*fo*(1.+.45*fo),.5,oi);occ+=clamp(1.-mo/(cs*1.3),0.,1.)/sqrt(fo);}
              lt=exp(-occ*.5);
            }
            float lm=dot(cc,vec3(.3333));
            cc=mix(max(lm+(cc-lm)*1.3,0.)*.38,cc*1.18,lt);
          }
          cc*=latG;halo*=latF>.5?.3:1.;
#endif
          float a=(core+.13*halo)*en*inf.x*clamp(tp*sc*3.1-.25,0.,1.);   // fade dots that brush the lens
          acc+=T*cc*a;
          T*=1.-.8*core*en*inf.x;   // v22: a dot hides what is behind it (it let half through: dense clouds summed toward pale)
        }
      }
      // every ray point within (field margin - 1.5 cells) of here lies in a cell whose particle is absent;
      // monotonic even when rounding puts pG in the previous cell
      t=max(max(min(min(tx.x,tx.y),tx.z),t)+cs*1e-3,t+(mg-length(sG-pG)-1.5*cs)*.92);
    }
#if HD>=1
    }
#endif
    { float am=max(acc.r,max(acc.g,acc.b));if(am>1.)acc*=(1.+(am-1.)/(1.+.7*(am-1.)))/am; }
    col=col*T+acc;far*=T*oc*oc;   // the figure hides the far swarms behind it
#if SW_SEA
    sea.rgb*=mix(T*oc*oc,1.,seaF);
#endif
  }
#if SW_SEA
  far+=sea.rgb;
#endif
#if HD>=1
  return col+far;
}
void realm(){
  swZ=min(int(uTime),0);
  vec2 p0=scr();vec3 acc=vec3(0.);
  for(int s=swZ;s<SW_AA;s++){
    float fs=float(s-swZ);
    acc+=min(swPic(p0+(fs<.5?vec2(0.):(vec2(fract(fs*.7548777),fract(fs*.5698403))-.5))/uRes.y),vec3(12.));
  }
  fragColor=vec4(acc/float(SW_AA),0.);
}
#else
  fragColor=vec4(col+far,0.);
}
#endif
`;
