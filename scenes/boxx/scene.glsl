const R_BOXX = `
// BOXX 7 (v19): the endless dive through boxes, and every box opens onto a truly different world. Sixteen worlds with their
// own architecture, ground, sky and light: a walled castle on a green hill at sunset, a neon city at night, a giant
// toadstool forest, a clockwork yard of meshing brass gears, a crystal valley under an aurora, a candy land of lollipops,
// a moon base under a ringed planet, a lantern-lit pagoda village, a desert of pyramids and obelisks, the Rubik towers,
// a circuit-board megacity, a basalt field in a sea of lava, a coral reef, a library of giant books, sky islands above
// a cloud sea, and a snowed-in pine forest. Each stands round its own special box (a keep, a tower base, a shrine...) whose door opens on the next world
// at 1/10 scale; the levels are exactly self-similar (next = K R (this - C)), so the camera path never cuts.
// The music: the bass swells every structure, the kick sends a hop and a ring of light through the world, the mids fill
// the windows and lanterns (a whole-city equaliser), the highs light stars, sparks and rims, the snare bursts stacks,
// gears turn on the beat. One march walks through up to five nested worlds (one map call site, no recursion).
#define BX0 min(int(uTime),0)
#define BXK 10.
#define BXB .1
#define BXG -.64
#define BXC vec3(.0095885,-.54,.1824484)
#define BXCR .87758256
#define BXSR .47942554
#define BXF vec3(0.,-.6,.2)
#define BXR0 1.14
#define BXPH0 -1.5707963
#define BXTHETA .5
#define BXDW .40
#define BXDY0 -.64
#define BXDY1 .30
#define BXTH .06
#define BXN 150
#define BXLMAX 4.
#define BXWORLDS 16.
// light envelopes (JS: attack 70 ms, release 260 ms), 8 bands and the kick
#define BXB1 vec4(uM2[0],uM2[1].x)
#define BXB2 vec4(uM2[1].yz,uM2[2].xy)
#define BXKK uM2[2].z
// geometry envelopes (JS springs): bass swell, kick ring B age, hat lid, gear turn, unfold, snare burst
#define BXBASS uP2.x
#define BXRB uP2.y
#define BXHF mod(uP5.y,2.)
#define BXOC .5
#define BXTW uP2.w
#define BXUNF uP5.x
#define BXEXP uP5.w
#define BXBLD (floor(uP5.y*.5)*.01)
float bxM3(vec3 v){return max(v.x,max(v.y,v.z));}
vec3 bxRot(vec3 v){return vec3(BXCR*v.x+BXSR*v.z,v.y,-BXSR*v.x+BXCR*v.z);}
vec3 bxToC(vec3 p){return bxRot(p-BXC);}
float bxBox(vec3 p,vec3 b){vec3 q=abs(p)-b;return length(max(q,0.))+min(bxM3(q),0.);}
float bxCyl(vec3 p,float r,float h){vec2 d=vec2(length(p.xz)-r,abs(p.y-h)-h);return min(max(d.x,d.y),0.)+length(max(d,0.));}
// a cone standing on y = 0: base radius r, height h (a conservative bound)
float bxSeg(vec3 p,vec3 b,float r){return length(p-b*clamp(dot(p,b)/dot(b,b),0.,1.))-r;}
float bxCone(vec3 p,float r,float h){float l=length(vec2(r,h));return max((length(p.xz)*h+p.y*r-r*h)/l,-p.y);}
vec2 bxR2(vec2 v,float a){float c=cos(a),s=sin(a);return vec2(c*v.x-s*v.y,s*v.x+c*v.y);}
#if HD>=1
float bxIP(float x,float f){return floor(x)*f+clamp(fract(x)-.5+.5*f,0.,f);}
float bxPulse(float x,float f,float w){w=max(w,1e-4);return (bxIP(x+.5*w,f)-bxIP(x-.5*w,f))/w;}
#else
float bxPulse(float x,float f,float w){w=max(w,1e-4);return mix(clamp((.5*f-abs(fract(x)-.5))/w+.5,0.,1.),f,smoothstep(.5,1.,w));}
#endif
// the avenue along the dive path: (signed lateral offset, path parameter u, distance from the fixed point)
vec3 bxAve(vec2 xz){
  vec2 f=xz-BXF.xz;float r=max(length(f),1e-4);
  float u=log(BXR0/r)/log(BXK);
  float ph=atan(f.y,f.x)-(BXPH0+BXTHETA*u);
  ph-=TAU*floor(ph/TAU+.5);
  return vec3(r*ph,u,r);
}
vec3 bxSun(float k,float sd){float a=k*2.39996+.7+floor(mod(sd,3.))*1.9;return normalize(vec3(cos(a),.75+.4*fract(a*.37),sin(a)));}
// three lightings of every world (a world's seed picks one): its own, and two curated alternatives
const vec3 BXVS[32]=vec3[32](vec3(.98,.5,.62),vec3(.5,.3,.85),vec3(.1,.55,.5),vec3(.75,.12,.5),vec3(.55,.35,.85),vec3(.95,.6,.2),vec3(.8,.28,.18),vec3(.2,.62,.55),vec3(.75,.3,.85),vec3(.25,.8,.6),vec3(.5,.9,.75),vec3(.72,.6,1.),vec3(.03,.16,.14),vec3(.25,.07,.07),vec3(1.,.55,.65),vec3(.3,.4,.8),vec3(.7,.4,.75),vec3(.35,.75,.9),vec3(.15,.55,.7),vec3(.75,.15,.35),vec3(.1,.2,.6),vec3(.4,.12,.55),vec3(.45,.12,.4),vec3(1.,.55,.12),vec3(.12,.35,.85),vec3(.1,.7,.5),vec3(.5,.32,.16),vec3(.5,.22,.34),vec3(1.,.6,.45),vec3(.32,.2,.72),vec3(.1,.42,.6),vec3(1.,.7,.35));
float bxCs(float k){float c=.24;if(k>.5)c=.13;if(k>1.5)c=.28;if(k>2.5)c=.2;if(k>3.5)c=.13;if(k>4.5)c=.16;if(k>5.5)c=.2;if(k>6.5)c=.21;if(k>7.5)c=.26;if(k>8.5)c=.13;if(k>9.5)c=.16;if(k>10.5)c=.085;if(k>11.5)c=.15;if(k>12.5)c=.2;if(k>13.5)c=.2;if(k>14.5)c=.13;return c;}
// the tallest anything stands in a world (before the bass swell)
float bxTop(float k){float t=.2;if(k>.5)t=.62;if(k>1.5)t=.6;if(k>2.5)t=.36;if(k>3.5)t=.34;if(k>4.5)t=.24;if(k>5.5)t=.2;if(k>6.5)t=.34;if(k>7.5)t=.34;if(k>8.5)t=.32;if(k>9.5)t=.26;if(k>10.5)t=.34;if(k>11.5)t=.26;if(k>12.5)t=.34;if(k>13.5)t=.5;if(k>14.5)t=.26;return t;}
vec3 bxHz(float k){vec3 h=vec3(1.,.55,.25);if(k>.5)h=vec3(.42,.2,.62);if(k>1.5)h=vec3(.26,.75,.62);if(k>2.5)h=vec3(.85,.55,.22);if(k>3.5)h=vec3(.25,.55,.85);if(k>4.5)h=vec3(.5,.32,.92);if(k>5.5)h=vec3(.2,.08,.36);if(k>6.5)h=vec3(.95,.42,.28);if(k>7.5)h=vec3(1.,.48,.2);if(k>8.5)h=vec3(.4,.3,.75);if(k>9.5)h=vec3(.1,.5,.42);if(k>10.5)h=vec3(.42,.08,.14);if(k>11.5)h=vec3(.1,.72,.78);if(k>12.5)h=vec3(.45,.24,.12);if(k>13.5)h=vec3(1.,.42,.38);if(k>14.5)h=vec3(.3,.26,.72);return h;}
struct BxP{vec3 skyT,skyH,gnd,ba,bb,a1,a2;float cl,str;};
BxP bxPal(float k,float vr){
  BxP P;P.skyH=vr<.5?bxHz(k):BXVS[int(k)*2+int(vr)-1];
  // explicit per world: gnd, ba (main surface), a1 (accent). The rest are derived, which saves most of the table.
  P.gnd=vec3(.20,.42,.16);P.ba=vec3(.56,.53,.50);P.a1=vec3(.92,.16,.14);
  if(k>.5){P.gnd=vec3(.07,.07,.10);P.ba=vec3(.11,.13,.22);P.a1=vec3(.1,.85,1.);}
  if(k>1.5){P.gnd=vec3(.05,.2,.16);P.ba=vec3(.82,.76,.66);P.a1=vec3(.25,.95,.9);}
  if(k>2.5){P.gnd=vec3(.16,.15,.15);P.ba=vec3(.85,.62,.22);P.a1=vec3(1.,.6,.15);}
  if(k>3.5){P.gnd=vec3(.62,.78,.92);P.ba=vec3(.30,.55,.95);P.a1=vec3(.3,1.,.95);}
  if(k>4.5){P.gnd=vec3(.9,.42,.6);P.ba=vec3(1.,.25,.45);P.a1=vec3(1.,.85,.2);}
  if(k>5.5){P.gnd=vec3(.50,.50,.52);P.ba=vec3(.85,.87,.92);P.a1=vec3(1.,.55,.15);}
  if(k>6.5){P.gnd=vec3(.42,.38,.20);P.ba=vec3(.82,.18,.12);P.a1=vec3(1.,.6,.2);}
  if(k>7.5){P.gnd=vec3(.85,.52,.26);P.ba=vec3(.8,.48,.26);P.a1=vec3(1.,.8,.25);}
  if(k>8.5){P.gnd=vec3(.11,.11,.15);P.ba=vec3(.04);P.a1=vec3(1.,.2,.2);}
  if(k>9.5){P.gnd=vec3(.02,.2,.15);P.ba=vec3(.05,.05,.06);P.a1=vec3(.15,1.,.55);}
  if(k>10.5){P.gnd=vec3(.09,.07,.08);P.ba=vec3(.1,.09,.11);P.a1=vec3(1.,.42,.08);}
  if(k>11.5){P.gnd=vec3(.6,.58,.46);P.ba=vec3(.95,.34,.42);P.a1=vec3(1.,.45,.2);}
  if(k>12.5){P.gnd=vec3(.34,.17,.09);P.ba=vec3(.52,.15,.16);P.a1=vec3(1.,.74,.32);}
  if(k>13.5){P.gnd=vec3(.98,.96,1.);P.ba=vec3(.5,.42,.36);P.a1=vec3(.3,.9,.5);}
  if(k>14.5){P.gnd=vec3(.88,.92,1.);P.ba=vec3(.1,.3,.2);P.a1=vec3(1.,.72,.32);}
  // second tone: the surface rotated toward the sky's colour; the far accent complements the first; deep overhead sky
  P.a2=vec3(0.);P.bb=mix(P.ba*vec3(.6,.75,1.3),P.a2,.25)*.75;P.a2=vec3(1.,.72,.25);if(k>.5)P.a2=vec3(1.,.2,.7);if(k>1.5)P.a2=vec3(1.,.8,.3);if(k>2.5)P.a2=vec3(.2,.9,.8);if(k>3.5)P.a2=vec3(.85,.45,1.);if(k>4.5)P.a2=vec3(1.,.82,.25);if(k>5.5)P.a2=vec3(.2,.85,1.);if(k>6.5)P.a2=vec3(1.,.6,.75);if(k>7.5)P.a2=vec3(.2,.8,.75);if(k>8.5)P.a2=vec3(1.,.85,.1);if(k>9.5)P.a2=vec3(1.,.8,.35);if(k>10.5)P.a2=vec3(1.,.75,.2);if(k>11.5)P.a2=vec3(.2,.95,.9);if(k>12.5)P.a2=vec3(.95,.82,.5);if(k>13.5)P.a2=vec3(1.,.9,.6);if(k>14.5)P.a2=vec3(.4,.8,1.);if(vr>1.5){vec3 sw=P.a1;P.a1=P.a2;P.a2=sw;}P.skyT=mix(P.skyH.bgr*.2+vec3(.03,.04,.14),P.skyH*.12,.4);
  P.cl=.9;P.str=.25;
  if(k>.5){P.cl=.35;P.str=.8;}if(k>1.5){P.cl=.4;P.str=.6;}if(k>2.5){P.cl=.8;P.str=0.;}if(k>3.5){P.cl=.1;P.str=1.;}if(k>4.5){P.cl=1.;P.str=0.;}if(k>5.5){P.cl=0.;P.str=1.4;}if(k>6.5){P.cl=.5;P.str=.8;}if(k>7.5){P.cl=.3;P.str=0.;}if(k>8.5){P.cl=.2;P.str=.5;}if(k>9.5){P.cl=0.;P.str=.3;}if(k>10.5){P.cl=.5;P.str=.9;}if(k>11.5){P.cl=0.;P.str=0.;}if(k>12.5){P.cl=0.;P.str=.1;}if(k>13.5){P.cl=.7;P.str=0.;}if(k>14.5){P.cl=.3;P.str=.9;}
  // v22 every horizon deeper and more saturated: no pale skies, no pale haze
  P.skyH=clamp(mix(vec3(dot(P.skyH,vec3(.3,.59,.11))),P.skyH,1.3),0.,1.)*.9;
  return P;
}
// a frieze of ornament along a band: t 0 zigzag, 1 lozenges, 2 beads, 3 a key pattern, 4 scallops. uv.x runs along (one motif
// per unit), uv.y runs -1..1 across the band; w is the pixel in uv.y units. Fades to its average before it can shimmer.
float bxFz(vec2 uv,float t,float w){
  float x=fract(uv.x),y=uv.y,d;
  if(t<.5)d=abs(y-1.15*abs(x-.5)*2.+.6)-.32;
  else if(t<1.5)d=abs(x-.5)*1.5+abs(y)*.85-.58;
  else if(t<2.5)d=length(vec2((x-.5)*1.25,y*.8))-.46;
  else if(t<3.5)d=max(abs(y)-.72,min(.55-abs(x-.5)*1.4,abs(y-.22*sign(x-.5))-.2)+.04);
  else d=max(abs(length(vec2(x-.5,y+.75))-1.05)-.2,-y-.75);
  return mix(clamp(.5-d/(1.2*w+1e-4),0.,1.),.32,smoothstep(.3,.75,w))*step(abs(y),1.);
}
#if HD>=1
// the landmark of each world, standing twice behind the box (the left one smaller), a stepped lathe in the world's own material:
// (R, height, tiers, taper). Square in plan where it is built, round where it grows.
const vec4 BXHR[16]=vec4[16](vec4(0.),vec4(.11,.92,7.,-.78),vec4(0.),vec4(0.),vec4(.12,.9,34.,.96),vec4(.2,.4,4.,.62),vec4(.06,.68,3.,.45),vec4(.14,.68,8.45,-.62),vec4(.3,.48,13.,-.99),vec4(.18,.56,3.,-.001),vec4(.14,.38,7.,-.4),vec4(.34,.46,30.,.9),vec4(.12,.58,6.,.55),vec4(.12,.74,6.,.42),vec4(0.),vec4(.18,.88,9.5,.97));
const float BXHM[16]=float[16](0.,3.,0.,0.,5.,18.,18.,18.,18.,18.,18.,12.,18.,18.,0.,16.1);
float bxHero(vec3 p,float k,float g,out vec3 q,out vec3 h){
  vec4 b=BXHR[int(k)];
  float sg=p.x<0.?-1.:1.,sc=sg<0.?.76:1.,R=b.x*sc,Hh=b.y*sc*(.62+.56*g),N=floor(b.z),w=abs(b.w),hy=Hh/N;
  q=p-vec3(sg*.5,BXG,.6);h=vec3(R,Hh,N);
  float l=b.w<0.?max(abs(q.x),abs(q.z)):length(q.xz),y=clamp(q.y/Hh,0.,.9999)*N,ti=floor(y),tf=y-ti;
  float d=min(max(l-R*(1.-w*ti/N)*(1.+fract(b.z)*1.2*tf*tf),abs(q.y-(ti+.5)*hy)-hy*.5),max(l-R*(1.-w*max(ti-1.,0.)/N),q.y-ti*hy));
  if(w>.3)d=min(d,bxCone(q-vec3(0.,Hh,0.),R*(1.-w)*1.3,Hh*.2));
  return b.x<1e-3?1e3:max(d,-q.y)*.85;
}
#endif
float bxSpec(float x){x=clamp(x,0.,1.)*7.;return dot(BXB1,max(1.-abs(x-vec4(0.,1.,2.,3.)),0.))+dot(BXB2,max(1.-abs(x-vec4(4.,5.,6.,7.)),0.));}
float tone2(float y){return fract(sin(floor(y/.0105)*12.9898)*43758.5453);}
float bxBand(vec3 av){return clamp((abs(av.x)-.02)/(.02+.24*av.z),0.,1.);}
float bxHopE(float t){return smoothstep(0.,.15,t)*exp(-3.2*t)*(1.-smoothstep(.45,.62,t))*1.6;}
float bxLift(vec2 cc,float sd,float par){
  float x=.12*length(cc-BXC.xz);
  return (bxHopE(uP4.z-x)*par+bxHopE(BXRB-x)*(1.-par))*.03*uDose;
}
// a safe extra step limit from within a lot (the distance to the next book or tier), reset for each map evaluation
float bxL;
// v22 the dance: every height in a world rides one wave, sin(dot((ring, x, z), bxDW) + bxDP). The JS steps the phase half a
// turn on each kick (rows rise as their neighbours sink) and re-forms the wave (rings, rows, columns, diagonals) on impacts
// and section changes; bxDA is its depth (never over .34, the bound the march's height limit allows for)
vec3 bxDW;float bxDA,bxDP;
vec3 bxFm(float f){return f<.5?vec3(14.,0.,0.):(f<1.5?vec3(0.,0.,11.):(f<2.5?vec3(0.,11.,0.):(f<3.5?vec3(0.,8.,8.):vec3(7.,6.,-6.))));}
// the structures of a lot. m: 1 masonry, 2 roof tiles, 3 facade, 4 brass, 5 crystal, 6 organic, 7 candy, 8 stickers;
// the fraction says .1 round (use the angle for texture), .2 spotted cap, .3 foliage, .4 lit lantern.
float bxLot(vec3 p,float k,float sd,float cs,out float m,out vec3 lq,out vec3 lh,out vec3 hc,out float fv){
  vec2 id=floor(p.xz/cs),cc=(id+.5)*cs;
  hc=vec3(h21(id+sd),h21(id.yx*1.37+sd+3.1),h21(id*2.31+sd+7.7));
  m=1.;lq=vec3(0.);lh=vec3(1.);fv=0.;bxL=1e3;
  vec3 av=bxAve(cc);
  float emp=max(max(step(abs(av.x),.03+.14*av.z+cs*.5)*step(-.5,av.y)*step(av.y,1.4),step(length(cc-BXC.xz),BXB*1.9+cs*.5)),max(step(1.-cs*.5,max(abs(cc.x),abs(cc.y))),step(hc.z,.12)));
  if(emp>.5)return 1e3;
  float bpo=bxBand(av),lf=1.+bxDA*sin(dot(vec3(length(cc-BXC.xz),cc),bxDW)+bxDP+sd),g=(.56+.72*BXBASS)*(1.+.3*bpo)*lf,par=mod(id.x+id.y,2.),hx=hc.x*hc.x,d=1e3,a;
  vec3 q=p-vec3(cc.x,BXG+bxLift(cc,sd,par)+BXEXP*((k>1.5&&k<2.5)||(k>9.5&&k<14.5)?.085:.03)*hc.y+BXBLD*BXBLD*.18*hc.y,cc.y),e;
  hc.z=bpo;
  if(k<.5){
    // the village outside the walls: thatched cottages and round trees
    vec2 cp=bxToC(vec3(cc.x,0.,cc.y)).xz;if(max(abs(cp.x),abs(cp.y))<.62)return 1e3;
    if(hc.y<.4){
      float r=.03+.022*hc.x,tr=bxCyl(q,.006,.04*g);q.y-=.04*g+r*.55;d=length(q*vec3(1.,1.25,1.))-r;m=6.3;lq=q;lh=vec3(r);
      if(tr<d){d=tr;m=6.1;lq=q;lh=vec3(.006);}
    }else{
      e=vec3(.05+.025*hc.x,.028*g,.035+.02*hc.y);
      d=bxBox(q-vec3(0.,e.y,0.),e);m=1.;lq=q;lh=e;fv=q.y;
      vec3 rf=q-vec3(0.,2.*e.y,0.);float gb=bxCone(rf,max(e.x,e.z)*1.25,.05*g+.02);
      if(gb<d){d=gb;m=2.1;lq=rf;lh=e;}
    }
  }else if(k<1.5){
    // skyscrapers with setbacks and a mast, tallest along the avenue
    float H=(.12+.42*hx)*g*(1.+.5*(1.-bpo));e=vec3(cs*(.36+.08*hc.y),H*.5,cs*(.3+.12*hc.x));
    d=bxBox(q-vec3(0.,e.y,0.),e);lq=q-vec3(0.,e.y,0.);lh=e;fv=q.y;m=3.;
    float sb=fract(hc.x*7.3);
    if(sb>.4){vec3 t=vec3(e.x*.6,H*.18,e.z*.6);vec3 r=q-vec3(0.,H+t.y,0.);float d2=bxBox(r,t);if(d2<d){d=d2;lq=r;lh=t;fv=q.y;}}
  }else if(k<2.5){
    // the toadstool forest: towering stems with a swollen foot and a torn skirt under four kinds of cap (a pleated parasol,
    // a tall bell, tiered shelves, a hollow trumpet), a small companion at the foot, a stilt-legged sporeling that hops on
    // the kick, and a pale spore rising from each cap
    float T=(.13+.23*hc.x*hc.x+.1*hc.y)*g,R=(.082+.03*hc.y)*(1.+.2*BXBASS+.2*BXEXP),s=.014+.012*hc.y,kt=fract(hc.x*5.3);
    q.xz+=(hc.yx-.5)*.09*cs;
    d=max((length(q.xz)-s*(1.+1.7*exp(-q.y/(.16*T))-.25*smoothstep(0.,T,q.y)))*.85,max(-q.y,q.y-T));m=6.1;lq=q;lh=vec3(s);
    float e0=max(length(q.xz)-s*2.6,abs(q.y-T*.72)-.0024);if(e0<d)d=e0;
    vec3 c=q-vec3(0.,T,0.);float cp;
    if(kt<.42)cp=max((length(c*vec3(1.,2.2,1.))-R)/2.2,-c.y-R*.04);
#if HD>=1
    else if(kt>.86){cp=max(abs(length(c.xz)-(R*.24+R*.85*smoothstep(0.,R*1.3,c.y+.01)))-.0045,max(-c.y-R*.04,c.y-R*1.3))*.7;}
    else if(kt>.68){float sy=R*.62,ti=clamp(floor(c.y/sy),0.,2.);vec3 tc=vec3(c.x,c.y-(ti+.5)*sy,c.z);cp=max((length(tc*vec3(1.,3.,1.))-R*(1.-.24*ti))/3.,-tc.y-sy*.18);}
#endif
    else cp=max(length(c*vec3(1.,.72,1.))-R*.92,-c.y-R*.16);
    if(cp<d){d=cp;m=6.2;lq=c;lh=vec3(R);}
    vec3 b;
#if HD>=1
    b=q-vec3((hc.y-.5)*.13,0.,(hc.x-.5)*.13);float Ts=.04+.04*hc.y,Rs=.022+.01*hc.x;
    e0=max(length(b.xz)-.0048,max(-b.y,b.y-Ts));if(e0<d){d=e0;m=6.1;lq=b;lh=vec3(.0048);}
    b.y-=Ts;e0=max((length(b*vec3(1.,1.5,1.))-Rs)/1.5,-b.y-Rs*.06);if(e0<d){d=e0;m=6.2;lq=b;lh=vec3(Rs);}
#endif
    float an=hc.y*6.28+uTime*.13*(par*2.-1.),hop=bxHopE(uP4.z-.1*length(cc-BXC.xz))*.06+.024;
    vec3 sp=q-vec3(cos(an)*.078,hop,sin(an)*.078);
    e0=length(sp*vec3(1.,.82,1.))-.011;float lg=max(length(vec2(abs(sp.x)-.0052,sp.z))-.0013,max(-q.y,q.y-hop));
    if(lg<e0)e0=lg;if(e0<d){d=e0;m=6.4;lq=sp;lh=vec3(an,.011,.0);}
#if HD>=1
    float rs=fract(uTime*.09+hc.x*9.);b=q-vec3((hc.y-.5)*.07,T+R*.7+rs*.24,(hc.x-.5)*.07);e0=length(b)-.0032-.0026*rs;
    if(e0<d){d=e0;m=9.4;lq=b;lh=vec3(.005);}
#endif
  }else if(k<3.5){
    // clockwork: a floor of wheels with true pitch circles so neighbours mesh tooth into gap and counter-rotate, compound
    // stacks of wheel and pinion on tall axles, and among them upright flywheels on frames and piston towers pumping on the bass
    float pr=cs*.5-.004,dir=par*2.-1.,H=.074,knd=fract(hc.x*5.3),gs=1.;
    float nt=knd<.6?clamp(floor(hx*3.2+g*1.3+hc.y),0.,3.):0.,ti=clamp(floor((q.y-.02)/H+.5),0.,nt),sm=mod(ti,2.);
    float Rg=pr*(1.-sm*(.5-.16*hc.y)),Ng=sm>.5?8.:16.,yg=.02+ti*H;
    vec3 gq=q-vec3(0.,yg,0.);
    if(knd>.8){ti=0.;sm=0.;Rg=pr;Ng=16.;yg=pr*1.16;gq=vec3(q.x,q.z,q.y-yg);gs=hc.y<.5?1.:-1.;}
    float gr=length(gq.xz),th=atan(gq.z,gq.x)+BXTW*.5*dir*gs*(16./Ng),tt=smoothstep(-.3,.45,cos(Ng*th+par*3.14159265+(knd>.8?hc.y*9.:0.)));
    d=max((gr-(Rg-.0085+.0165*tt))*.42,abs(gq.y)-(sm>.5?.017:.012));
    if(sm<.5){float ws=max(abs(gr-Rg*.66)-Rg*.19,(.5-cos(th*5.))*Rg*.3);d=max(d,-ws);}
    lq=gq;lh=vec3(Rg);m=4.1;fv=yg;
    float e0=max(gr-.016,abs(gq.y)-.026);if(e0<d){d=e0;m=4.2;lq=gq;lh=vec3(.016);}
    if(knd>.8){
#if HD>=1
      // the flywheel's A-frame and axle
      vec3 f=vec3(q.x,q.y,abs(q.z)-.024);float lw=abs(f.x)-(.02+.5*max(pr*1.1-f.y,0.)*.5);
      e0=max(max(lw,abs(f.z)-.0055),max(-f.y,f.y-pr*1.3));if(e0<d){d=e0;m=4.3;lq=f;lh=vec3(.02);}
      e0=max(length(vec2(q.x,q.y-yg))-.0075,abs(q.z)-.036);if(e0<d){d=e0;m=4.2;lq=vec3(q.x,q.z,q.y-yg);lh=vec3(.0075);}
#endif
    }else if(knd>.6){
      // a piston tower: the rod runs up and down with the bass, a crosshead on top
      float pu=.045+.11*BXBASS*g;
      e0=bxCyl(q,.03,.044);if(e0<d){d=e0;m=4.3;lq=q;lh=vec3(.03,.088,.03);}
      e0=bxCyl(q,.0105,.05+pu);if(e0<d){d=e0;m=4.2;lq=q;lh=vec3(.0105);}
      vec3 ch=q-vec3(0.,2.*(.05+pu),0.);e0=bxBox(ch,vec3(.046,.0085,.016));if(e0<d){d=e0;m=4.3;lq=ch;lh=vec3(.046,.0085,.016);}
    }else{
      // the axle and a finial
      e0=bxCyl(q,.0075,.02+nt*H*.5+.014);if(e0<d){d=e0;m=4.2;lq=q;lh=vec3(.0075);}
    }
      }else if(k<4.5){
    // crystal clusters: hexagonal spires with pointed tips, the tallest toward the walls where the treble lives
    float h=(.12+.26*hx)*g*(1.+.5*bpo),r=.022+.022*hc.y;
    a=(hc.x-.5)*.5;q.xy=bxR2(q.xy,a);q.zy=bxR2(q.zy,(hc.y-.5)*.45);q.x=abs(q.x)-r*.85;
    float hexd=max(abs(q.x)*.866+abs(q.z)*.5,abs(q.z))-r*(1.-smoothstep(h*.72,h,q.y));
    d=max(hexd,max(-q.y,q.y-h))*.8;lq=q;lh=vec3(r,h,r);m=5.;fv=q.y;
  }else if(k<5.5){
    // candy land: lollipops, gumdrops and striped cane posts
    float tp=fract(hc.x*5.);
    if(tp<.5){
      float h=(.08+.12*hc.y)*g,R=.03+.018*hc.x;
      float st=bxCyl(q,.006,h);vec3 c=q-vec3(0.,h+R*.85,0.);float he=length(c)-R;
      d=st;m=7.1;lq=q;lh=vec3(.006);
      if(he<d){d=he;m=7.2;lq=c/R;lh=vec3(R);}
    }else if(tp<.8){
      float R=.04+.03*hc.y;q.y-=R*.4;d=max(length(q*vec3(1.,1.1,1.))-R,-q.y-R*.4);m=7.2;lq=q/R;lh=vec3(R);
    }else{
      d=bxCyl(q,.016,.12*g+.03*hc.y);m=7.1;lq=q;lh=vec3(.016);fv=q.y;
    }
  }else if(k<6.5){
    // moon base: domes, ringed tanks, thin antenna masts
    float R=.06+.05*hx;
    if(hc.y<.6){
      d=max(length(q)-R*g,-q.y);m=5.2;lq=q;lh=vec3(R*g);
      float rg=max(abs(length(q.xz)-R*g*.98)-.006,q.y-.018);if(rg<d){d=rg;m=4.1;lq=q;lh=vec3(R);}
    }else{
      d=bxCyl(q,.03,.05*g+.02*hc.x);m=4.1;lq=q;lh=vec3(.03);
    }
  }else if(k<7.5){
    // pagoda village: stacked tiers with flared tile roofs and lanterns, and blossom trees
    if(hc.y<.3){
      float tr=bxCyl(q,.006,.06*g);q.y-=.07*g;float R=.045+.02*hc.x;d=length(q*vec3(1.,1.2,1.))-R;m=6.3;lq=q;lh=vec3(R);
      if(tr<d){d=tr;m=6.1;lq=q;lh=vec3(.006);}
    }else{
      float T=.055*g,nt=3.+floor(hc.x*2.99),it=clamp(floor(q.y/T),0.,nt-1.),sh=1.-it*.16;
      vec3 c=vec3(q.x,q.y-(it+.5)*T,q.z);float wd=.05*sh;
      d=bxBox(c,vec3(wd,T*.5,wd));m=1.;lq=c;lh=vec3(wd,T*.5,wd);fv=q.y;
      float ed=max(abs(c.x),abs(c.z)),fl=wd*.45*smoothstep(wd*.3,wd*1.45,ed);
      float roof=max(ed*.55+c.y*.8-.5*T-wd*.7+fl*.6,max(-c.y-.02*T,ed-wd*1.5));
      if(roof<d){d=roof;m=2.;lq=c;lh=vec3(wd,T*.5,wd);}
      vec3 l=vec3(abs(c.x)-wd*1.42,c.y+T*.46,abs(c.z)-wd*1.42);float la=length(l)-.0042;if(la<d){d=la;m=9.4;lq=c;lh=vec3(.0042);}
    }
  }else if(k<8.5){
    // desert: stepped pyramids and gilded obelisks
    if(hc.y<.55){
      float h=(.09+.12*hc.x)*g,w=h*1.05;
      float nS=7.,ts=floor(clamp(q.y/h,0.,.999)*nS),hS=h/nS,l0=max(abs(q.x),abs(q.z));
      d=min(max(l0-w*(1.-ts/nS),abs(q.y-(ts+.5)*hS)-hS*.5),max(l0-w*(1.-max(ts-1.,0.)/nS),abs(q.y-(ts-.5)*hS)-hS*.5));m=1.;lq=q;lh=vec3(w,h,w);fv=q.y;
    }else{
      float h=(.14+.15*hx)*g,w=.016+.01*hc.x;
      d=bxBox(q-vec3(0.,h*.5,0.),vec3(w,h*.5,w));m=1.;lq=q;lh=vec3(w,h*.5,w);fv=q.y;
    }
  }else if(k<9.5){
    // Rubik towers: stacks of stickered cubes, a turn every second beat
    float w=cs*.34,t=BXTW*(step(.5,par)*2.-1.),tl=clamp(floor(q.y/(w*2.)),0.,floor(hx*3.+g*1.2));
    vec3 c=vec3(q.x,q.y-(tl+.5)*w*2.,q.z);c.xz=bxR2(c.xz,t*.5);
    d=bxBox(c,vec3(w-.0015))-.0015;m=8.;lq=c;lh=vec3(w);fv=tl;
  }else if(k<10.5){
    // the circuit board: chips on silver legs, can capacitors, wound coils and bar-graph LEDs on the green plain
    float tp=fract(hc.x*5.);
    if(tp<.5){
      e=vec3(cs*(.27+.13*hc.y),(.016+.05*hx)*g,cs*(.21+.1*hc.x));
      vec3 c=q-vec3(0.,e.y+.006,0.);d=bxBox(c,e);m=11.1;lq=c;lh=e;fv=q.y;
#if HD>=1
      vec3 l=vec3(mod(q.x+.0075,.015)-.0075,q.y-.004,abs(q.z)-e.z-.0065);
      float ld=max(bxBox(l,vec3(.0034,.0038,.0072)),abs(q.x)-e.x);if(ld<d){d=ld;m=11.3;lq=l;lh=vec3(.0034);}
#endif
#if HD>=1
    }else if(tp>.92){
      // a bar of LEDs on a stalk
      float h=.02+.05*hc.y;d=bxBox(q-vec3(0.,h,0.),vec3(.006,h,.042));m=11.5;lq=q-vec3(0.,h,0.);lh=vec3(.006,h,.042);fv=q.y;
#endif
#if HD>=1
    }else if(tp>.78){
      vec3 c=q-vec3(0.,.044,0.);float rr=.036+.014*hc.y;
      d=length(vec2(length(c.xz)-rr,c.y))-.019;m=11.4;lq=c;lh=vec3(rr);
#endif
    }else{
      float r=.024+.022*hc.y,h=(.04+.1*hx)*g;
      d=bxCyl(q,r,h);m=11.2;lq=q;lh=vec3(r,h*2.,r);fv=q.y;
    }
  }else if(k<11.5){
    // a field of basalt columns standing in lava, turned at random, a few rising far above the rest
    float r=cs*(.42+.07*hc.y),h=(.05+.2*hx+step(.93,hc.y)*.14)*g;
    a=hc.x*6.28;q.xz=bxR2(q.xz,a);
    d=max(max(abs(q.x)*.866+abs(q.z)*.5,abs(q.z))-r,q.y-h);m=12.;lq=q;lh=vec3(r,h,r);fv=q.y;
  }else if(k<12.5){
    // the reef: brain-coral boulders, clusters of tube sponges, branching fans, and a pair of fish circling each lot
    float tp=fract(hc.x*5.);
    if(tp<.38){
      float R=(.036+.034*hc.y)*(1.+.12*BXBASS);q.y-=R*.5;d=(length(q*vec3(1.,1.15,1.))-R)/1.15;m=13.1;lq=q;lh=vec3(R);
#if HD>=1
    }else if(tp>.72){
      vec3 f=q-vec3(0.,(.07+.05*hc.y)*g,0.);float R=.075;f.xz=bxR2(f.xz,hc.x*3.1);
      d=max(length(f.xy)-R,abs(f.z)-.0028);
      float br=sin(atan(f.y,f.x)*19.)*sin(length(f.xy)*260.);d=max(d,(br-.55)*.009);m=13.3;lq=f;lh=vec3(R);fv=f.y;
      float e0=bxCyl(q,.0065,.05*g);if(e0<d){d=e0;m=13.2;lq=q;lh=vec3(.0065);fv=q.y;}
#endif
    }else{
      // branching coral: a stem that forks three times
      float h0=(.05+.04*hc.y)*g;vec3 t=q;d=bxSeg(t,vec3(0.,h0,0.),.0085);
      t.y-=h0;t.xz=bxR2(t.xz,hc.x*6.28);t.x=abs(t.x);float e0=bxSeg(t,vec3(.036,.05,0.),.0065);if(e0<d)d=e0;
      t-=vec3(.036,.05,0.);t.xz=bxR2(t.xz,1.1);t.z=abs(t.z);e0=bxSeg(t,vec3(.012,.04,.026),.005);if(e0<d)d=e0;
      t-=vec3(.012,.04,.026);t.xz=bxR2(t.xz,.8);t.x=abs(t.x);e0=bxSeg(t,vec3(.018,.03,.004),.0036);if(e0<d)d=e0;
      m=13.2;lq=q;lh=vec3(.008,.12,.008);fv=q.y;
    }
    float an=hc.y*6.28+uTime*.42,fr=.06+.03*hc.x;vec3 c=q-vec3(cos(an)*fr,.11+.06*hc.x,sin(an)*fr);c.xz=bxR2(c.xz,an);
    float fb=(length(c*vec3(2.4,1.8,1.))-.014)/2.4,ft=max(abs(c.y)-.0015-abs(c.z+.015)*.9,max(c.z+.012,-c.z-.032));
    if(ft<fb)fb=ft;if(fb<d){d=fb;m=13.4;lq=c;lh=vec3(.014);}
  }else if(k<13.5){
    // the library: rows of giant books standing as an equaliser, lying stacks, and reading lamps
    float tp=fract(hc.x*7.);
    if(tp<.8){
      if(par>.5)q.xz=q.zx;
      float H=.078,nT=2.+floor(hc.y*2.99+g*.7),ty=clamp(floor(q.y/H),0.,nT-1.),W=cs*.41,D=cs*.17,hC=nT*H*.5;
      vec3 b=vec3(abs(q.x)-W,q.y-hC,q.z);d=bxBox(b,vec3(.0055,hC,D));
      float pl2=max(abs(mod(q.y+.0035,H)-.0035)-.0035,max(abs(q.x)-W,max(abs(q.z)-D,q.y-nT*H-.0035))),e0=bxBox(vec3(q.x,q.y-hC,q.z),vec3(W,hC,.0025));
      d=min(d,min(pl2,e0));m=14.2;lq=q;lh=vec3(W,H,D);fv=q.y;
      float tw=.0135+.008*hc.x,nb=floor(W/tw-.6),ib=clamp(floor(q.x/tw+.5),-nb,nb),cx=q.x-ib*tw,hb=h21(vec2(ib,ty+id.x*3.1)+sd);
      float bh=min(H*.5*(.6+.32*hb)*(1.+.25*bxSpec(.5+ib/(2.*nb+.01))),H*.47);
      vec3 bq=vec3(cx,q.y-ty*H-.007-bh,abs(q.z)-D*.5-BXEXP*.017*fract(hb*5.));e=vec3(tw*.44,bh,D*.43);
      e0=bxBox(bq,e);if(e0<d){d=e0;m=14.1;lq=bq;lh=e;fv=q.y;hc.y=h11(hb*97.+ib);hc.x=fract(hc.y*7.);}
      float x0=(hc.y-.5)*W*1.1,zl=q.z-D-.013-q.y*.06,hL=nT*H;vec3 l=vec3(abs(q.x-x0)-.0115,q.y,zl);
      e0=max(length(l.xz)-.0024,max(-q.y,q.y-hL));float rg=max(length(vec2(mod(q.y+.0125,.025)-.0125,zl))-.0018,max(abs(q.x-x0)-.0115,q.y-hL));
      if(rg<e0)e0=rg;if(e0<d){d=e0;m=4.2;lq=q;lh=vec3(.0024);}
      // the neighbouring book may be taller, so inside the case the step may not cross into the next slot (folded into d: a separate step limit made fxc three times slower)
      d=min(d,max(bxBox(vec3(q.x,q.y-hC,q.z),vec3(W+.003,hC+.004,D+.02)),min(tw*.5-abs(cx),H*.5-abs(q.y-(ty+.5)*H))+.004));
#if HD>=1
    }else if(tp<.93){
      float th=.022+.012*hc.y,ti=clamp(floor(q.y/th),0.,2.+floor(hc.x*3.+g)),h=h11(ti*2.3+hc.x*31.);
      vec3 c=vec3(q.x,q.y-(ti+.5)*th,q.z);c.xz=bxR2(c.xz,(h-.5)*1.1);e=vec3(cs*(.24+.1*h),th*.46,cs*(.16+.1*h));
      d=bxBox(c,e);m=14.1;lq=c.zyx;lh=e.zyx;fv=q.y;hc.y=h;hc.x=fract(h*7.);bxL=max(q.y-(3.+floor(hc.x*3.+g))*th,th*.5-abs(c.y)+.002);
#endif
    }else{
      float h=(.1+.08*hc.y)*g;d=bxCyl(q,.0055,h);m=4.2;lq=q;lh=vec3(.0055);
      vec3 c=q-vec3(0.,2.*h-.05,0.);float cd=bxCone(c,.058,.082);cd=max(cd,-c.y);if(cd<d){d=cd;m=9.4;lq=c;lh=vec3(.058);}
    }
  }else if(k<14.5){
    // sky islands: rock keels hanging over the cloud sea, a grassy top, a tree or a little tower, a waterfall off the edge
    float g0=g,R=(.055+.03*hc.y),top=(.14+.2*hc.x*hc.x)*g0;
    vec3 c=q-vec3(0.,top,0.);float ja=atan(c.z,c.x);
    float kl=bxCone(vec3(c.x,-c.y,c.z),R*(1.+.13*sin(ja*5.+hc.x*9.)+.07*sin(ja*13.+hc.y*5.)),R*1.25)*.8;
    d=kl;m=15.1;lq=c;lh=vec3(R,R*1.25,R);fv=-c.y;
    float e0=max(length(c.xz)-R*1.03,abs(c.y)-.0075);if(e0<d){d=e0;m=15.2;lq=c;lh=vec3(R);}
    vec3 w=c-vec3(0.,-R*.8,R*.96);e0=bxBox(w,vec3(.02,R*.82,.0025));if(e0<d){d=e0;m=15.3;lq=w;lh=vec3(.02,R*.82,.0025);}
    vec3 t=c-vec3((hc.y-.5)*.06,.006,(hc.x-.5)*.06);
    if(hc.y<.55){e0=bxCyl(t,.006,.018);if(e0<d){d=e0;m=6.1;lq=t;lh=vec3(.006);}t.y-=.046;e0=length(t*vec3(1.,1.2,1.))-.028;if(e0<d){d=e0;m=6.3;lq=t;lh=vec3(.034);}}
#if HD>=1
    else{float rT=.016+.008*hc.x,hT=.025+.02*hc.y;e0=bxCyl(t,rT,hT);if(e0<d){d=e0;m=1.1;lq=t;lh=vec3(rT,hT,rT);fv=t.y;}t.y-=2.*hT;e0=bxCone(t,rT*1.4,.04);if(e0<d){d=e0;m=2.1;lq=t;lh=vec3(rT);fv=t.y;}}
#endif
    if(abs(av.x)>.03+.14*av.z+cs*1.6){float sg=q.x<0.?-1.:1.;vec2 nid=id+vec2(sg,0.);float nh=h21(nid+sd);
     if(h21(nid*2.31+sd+7.7)>=.12){
       float yb=mix(top,(.14+.2*nh*nh)*g0,abs(q.x)/cs)-.0012*sin(abs(q.x)/cs*3.14159);
       e0=max(max(abs(q.z)-.0072,abs(q.y-yb)-.0024),R*.75-abs(q.x))*.8;
#if HD>=1
       {float rope=max(length(vec2(abs(q.z)-.0078,q.y-yb-.0085))-.0012,R*.75-abs(q.x));if(rope<e0)e0=rope;}
#endif
       if(e0<d){d=e0;m=15.4;lq=q;lh=vec3(.04);fv=q.y;}
     }}
  }else{
    // the snow forest: three-tiered pines with snow on every bough, log cabins with a lit window and a chimney
#if HD<1
    if(true){
#else
    if(hc.y<.74){
#endif
      float H=(.13+.14*hx)*g,R=.042+.02*hc.x,ty=clamp(floor(q.y/(H*.36)),0.,2.),sh=1.-ty*.3;vec3 c=q-vec3(0.,ty*H*.36,0.);
      d=bxCone(c,R*sh*1.45*(1.+.13*sin(atan(c.z,c.x)*11.+ty*2.+hc.x*9.)),H*.5)*.82;m=16.1;lq=c;lh=vec3(R,H*.5,sh);fv=q.y;
      float e0=bxCyl(q,.0075,.02);if(e0<d){d=e0;m=6.1;lq=q;lh=vec3(.0075);}
#if HD>=1
    }else{
      e=vec3(.05+.02*hc.x,.024*g,.035+.018*hc.y);vec3 c=q-vec3(0.,e.y,0.);d=bxBox(c,e);m=16.2;lq=c;lh=e;fv=q.y;
      vec3 r=q-vec3(0.,e.y*2.,0.);float rf=max(abs(r.z)*.7+r.y*.72-(e.z+.018)*.7,max(-r.y,abs(r.x)-e.x-.006));if(rf<d){d=rf;m=16.3;lq=r;lh=e;fv=q.y;}
      vec3 ch=q-vec3(e.x*.55,e.y*2.4,e.z*.3);float cd=bxBox(ch,vec3(.0075,.024,.0075));if(cd<d){d=cd;m=16.2;lq=ch;lh=vec3(.0075,.024,.0075);fv=q.y;}
#endif
    }
  }
  return d;
}
#if HD>=1
// extra small instances between the lots, in nested grids: each finer grid only exists once its cells are large on screen,
// and every prop grows out of the ground with its footprint so nothing pops or shimmers
float bxProps(vec3 x,float k,float sd,float cs,float fp,out float pm,out vec3 plq,out vec3 plh){
  // each world's own small things: 0 bushes and gumdrops, 1 cones (tents, shards, little firs), 2 crates, 3 lamps on posts,
  // 4 mushrooms; the sky islands have none (they would stand on the clouds)
  float dp=1e3,cc=cs/3.,kind=k<.5?1.:(k<1.5?3.:(k<2.5?4.:(k<3.5?2.:(k<4.5?1.:(k<5.5?0.:(k<6.5?3.:(k<7.5?3.:(k<8.5?2.:(k<10.5?2.:(k<11.5?1.:(k<12.5?0.:(k<13.5?2.:(k<14.5?9.:1.)))))))))))));
  pm=17.;plq=vec3(0.);plh=vec3(1.);
  if(kind>8.)return dp;
  for(int l=BX0;l<min(1+HD,4);l++){
    if(cc<fp*2.5)break;
    vec2 id=floor(x.xz/cc),c=(id+.5)*cc;float h=h21(id+sd+float(l)*3.1);
    vec3 av2=bxAve(c);
    if(h<.45&&abs(av2.x)>.03+.14*av2.z+cc&&length(c-BXC.xz)>BXB*1.9){
      float gr=smoothstep(1.,3.5,cc/(fp*2.5)),sz=cc*(.2+.5*h)*gr,d2;
      vec3 q=x-vec3(c.x+(h21(id.yx+sd)-.5)*cc*.4,BXG,c.y+(h21(id+sd+5.)-.5)*cc*.4);
      if(kind<.5)d2=length(q-vec3(0.,sz*.35,0.))-sz*.65;
      else if(kind<1.5)d2=bxCone(q,sz*.8,sz*2.2);
      else if(kind<2.5){vec3 b=q-vec3(0.,sz*.55,0.);b.xz=bxR2(b.xz,h*9.);d2=min(bxBox(b,vec3(sz*.6,sz*.55,sz*.6)),bxBox(b-vec3(sz*.25,sz*1.4,0.),vec3(sz*.32)));}
      else if(kind<3.5){d2=min(bxCyl(q,sz*.08,sz*1.3),length(q-vec3(0.,sz*2.7,0.))-sz*.3);}
      else{d2=min(bxCyl(q,sz*.16,sz*.6),max(length((q-vec3(0.,sz*1.2,0.))*vec3(1.,1.6,1.))/1.6-sz*.7,sz*1.05-q.y));}
      if(d2<dp){dp=d2;plq=vec3(h/.45,fract(h*17.),kind+.5*step(sz*2.2,q.y)*step(2.5,kind));plh=vec3(sz);}
    }
    cc*=.5;
  }
  return dp;
}
// designed relief, real displacement in the march: brick courses on masonry, overlapping tile rows on roofs, flutes on bark
// and stems, strata on rock, turned rings on brass, inset windows in the city, joints in basalt, ridges on brain coral, ribs
// on pine boughs; each one fades out as its own scale drops under a few pixels, so nothing shimmers
float bxRelief(vec3 x,float dm,vec3 lq,vec3 lh,float fp){
  float mT=floor(dm+.01),mf=floor(fract(dm)*10.+.5),xf=step(abs(lq.z)/max(lh.z,1e-4),abs(lq.x)/max(lh.x,1e-4));
  float fu=mf>.5&&mf<1.5?atan(lq.z,lq.x)*lh.x:mix(lq.x,lq.z,xf),fv=lq.y,r=0.,sc=1.,a=0.;
  if(mT<1.5){sc=.0058;vec2 bg=vec2(fu/.0105+.5*mod(floor(fv/.0058),2.),fv/.0058);vec2 e=abs(fract(bg)-.5);r=-smoothstep(.36,.5,max(e.x*.55,e.y));a=.0005;}
  else if(mT<2.5){sc=.007;r=fract(fv/.007);a=.0006;}
  else if(mT<3.5){sc=.0095;vec2 w=abs(fract(vec2(fu/.0095,fv/.0125))-.5);r=-step(w.x,.29)*step(w.y,.25);a=.0006;}
  else if(mT<4.5){sc=.012;r=abs(fract(length(lq.xz)/.012)-.5);a=.0003;}
  else if(mT<5.5){sc=.02;r=-abs(fract(fv*26.+fu*38.)-.5);a=.0004;}
  else if(mT<6.5){sc=.008;r=mf<1.5?abs(fract(fu/.008)-.5):0.;a=.0004;}
  else if(mT>11.5&&mT<12.5){sc=.036;r=-smoothstep(.42,.5,abs(fract(fv/.036)-.5));a=.0008;}
  else if(mT>12.5&&mT<13.5&&mf<1.5){sc=.01;r=dot(sin(lq*20./max(lh.x,.02)),cos(lq.yzx*20./max(lh.x,.02)))*.5;a=.0009;}
  else if(mT>14.5&&mT<15.5&&mf<1.5){sc=.01;r=sin(fv*120.+sin(fu*60.));a=.0006;}
  else if(mT>15.5&&mT<16.5&&mf<1.5){sc=.012;r=fract(fv/max(lh.y,.01)*7.);a=.0008;}
  return a*r*(1.-smoothstep(.1,.25,fp/sc));
}
#endif
// the special box: four walls hinged at their bottom edges and a lid; q is the hit piece's point in the closed box's frame
float bxShell(vec3 p,float deep,float u,out vec3 q){
  vec3 c=bxToC(p);
  float b=BXB,H=b*(1.+BXTH),t=b*BXTH,a=u*1.5;
  vec3 r=vec3(abs(c.x)-H,c.y+H,c.z);r.xy=bxR2(r.xy,a);
  float dx=bxBox(r-vec3(-t*.5,H,0.),vec3(t*.5,H,H));
  vec3 qx=vec3(sign(c.x)*(r.x+H),r.y-H,r.z);
  vec3 s=vec3(abs(c.z)-H,c.y+H,c.x);s.xy=bxR2(s.xy,a);
  vec3 qz=vec3(s.z,s.y-H,sign(c.z)*(s.x+H));
  float dz=bxBox(s-vec3(-t*.5,H,0.),vec3(t*.5,H,H));
  float dr=bxBox(vec3(qz.x,qz.y-b*(BXDY0+BXDY1)*.5,abs(qz.z)-H),vec3(b*BXDW,b*(BXDY1-BXDY0)*.5,b*mix(.4,.05,deep)));
  dz=max(dz,-dr);
  vec3 l=c-vec3(0.,H-t*.5+u*u*b*2.6,0.);
  float dl=bxBox(l,vec3(H,t*.5,H));
  vec3 ql=l+vec3(0.,H-t*.5,0.);
  float d=dx;q=qx;
  if(dz<d){d=dz;q=qz;}
  if(dl<d){d=dl;q=ql;}
  return d;
}
// the castle round the box: a square curtain wall with merlons, twelve round towers with conical roofs, four tall turrets
// on the keep, and the gate where the avenue passes through
float bxCastle(vec3 p,float g,out float m,out vec3 lq,out vec3 lh,out float fv){
  vec3 c=bxToC(p);vec2 af=abs(c.xz);if(af.x<af.y)af=af.yx;
  float y=p.y-BXG;
  float top=.105*g+.014*smoothstep(.45,.6,abs(fract(af.y*20.)-.5)*2.);
  float dW=max(max(abs(af.x-.46)-.016,y-top),-y);
  // the camera path crosses the south wall at x = -.168 (F + K^-u R^-u (p0 - F) in the box frame, u = .35): the wall is
  // open there, wider than the path's sway, and the gatehouse towers flank that gap instead of standing in it
  dW=max(dW,-max(abs(c.x+.17)-.085,c.z+.41));
  m=1.;lq=vec3(af.y,y,af.x-.46);lh=vec3(.46,top,.016);fv=y;
  vec2 tc=vec2(.46,af.y<.175?.05:(af.y<.38?.3:.46));vec3 t=vec3(af.x-tc.x,y,af.y-tc.y);
  float rT=.04,hT=(.16+.05*step(.38,af.y))*g;
  float dT=bxCyl(t,rT,hT);
  if(dT<dW){dW=dT;m=1.1;lq=t;lh=vec3(rT,hT,rT);fv=y;}
  float rf=bxCone(t-vec3(0.,hT*2.,0.),rT*1.32,.11*g);
  if(rf<dW){dW=rf;m=2.1;lq=t-vec3(0.,hT*2.,0.);lh=vec3(rT);fv=y;}
  // four tall turrets at the corners of the keep (the special box)
  vec3 kt=vec3(abs(c.x)-.142,y,abs(c.z)-.142);float rK=.026,hK=.2*g;
  float dK=bxCyl(kt,rK,hK);
  if(dK<dW){dW=dK;m=1.1;lq=kt;lh=vec3(rK,hK,rK);fv=y;}
  float rk=bxCone(kt-vec3(0.,hK*2.,0.),rK*1.4,.14*g);
  if(rk<dW){dW=rk;m=2.1;lq=kt-vec3(0.,hK*2.,0.);lh=vec3(rK);fv=y;}
  return dW;
}
vec3 bxSky(BxP P,vec3 rd,float pxa,float sd,float k){
  float y=rd.y,ayr=atan(rd.z,rd.x),mel2=.5*(BXB1.z+BXB1.w);
  vec3 L=bxSun(k,sd);
  // the base gradient: saturated, deep overhead, glowing at the horizon
  float ht=clamp(y+.06,0.,1.),gr=pow(ht,.6);
  vec3 c=mix(P.skyH,P.skyT,gr);c=mix(c,P.skyH*1.1,exp(-ht*9.)*.6);
  // the sun or moon and its halo
  float sn=max(dot(rd,L),0.);
  c+=P.skyH*(.16*pow(sn,5.)+.5*pow(sn,48.))*(1.-.5*P.str);
  float dsc=smoothstep(.9962-pxa,.9962+pxa,sn);
  c=mix(c,mix(vec3(1.,.95,.75),vec3(.92,.94,1.),step(.5,P.str)),dsc*.95);
  // v22 clouds in the world's own deep tones, lit tops and shadowed bellies, thick toward the horizon (day worlds)
  if(P.cl>.01){
    vec2 cu=rd.xz/(abs(y)+.26);float w=uTime*.012,cn=.65*vnoise(cu*2.1+vec2(w,0.)+sd)+.35*vnoise(cu*6.3-vec2(w,w*.5));
    float cov=smoothstep(.46,.74,cn)*P.cl*smoothstep(.0,.1,y);
    c=mix(c,mix(P.skyT*1.3+P.skyH*.2,mix(P.skyH,P.a2,.3)*1.1,smoothstep(.55,.85,cn)*(.6+.4*max(L.y,0.))),cov*.9);
  }
  // motes over the whole sky: stars twinkling with the highs, or rising lanterns (pagoda), embers (lava) and spores (toadstools)
  if(P.str>.01){
    float ris=k>6.5&&k<7.5?.016:(k>10.5&&k<11.5?.04:(k>1.5&&k<2.5?.01:0.));
    vec2 st=vec2(ayr*42.,y*72.-uTime*ris*72.);vec2 sid=floor(st);float sr=h21(sid+sd);
    float tw=step(.86,sr)*smoothstep(.42,.0,length(fract(st)-.5-(vec2(h21(sid+3.),h21(sid+5.))-.5)*.4));
    c+=mix(mix(P.a2,vec3(1.),.5),P.a1,step(.001,ris))*tw*smoothstep(.0,.08,y)*(.25+.9*(BXB2.z+BXB2.w)*uDose+BXHF*uDose*(.4+sr)+step(.001,ris)*mel2*uDose)*P.str;
  }
  // v22 the far plain under the horizon, and on it more boxes than can be counted, rank behind rank to the edge of the world,
  // each with one small lit window; the near rank lifts with the spectrum round the horizon
  {float hz=exp(-abs(y)*22.);vec3 fg=mix(P.gnd*.5+P.bb*.25,P.skyH*.7,hz);c=mix(c,fg,step(y,0.));
   for(int r=0;r<2;r++){float fr=1.-float(r),nA=fr<.5?70.:150.,a=ayr*nA*.15915+fr*.5,ci=floor(a),cf=fract(a)-.5,hh=h11(ci*1.37+fr*7.1+sd);
    float wd=.3+.14*hh,top=(fr<.5?.05:.022)*(.35+1.3*hh*hh)*(1.+(1.-fr)*1.4*bxSpec(abs(cos(ayr)))*uDose)-.004*fr,cw=pxa*nA*.15915;
    float bx=clamp(.5-(max(abs(cf)-wd,y-top))/(cw+pxa),0.,1.)*step(-.02,y);
    vec3 bcl=mix(P.ba,P.bb,hh)*(.32+.22*fr)+P.skyH*.12*fr;
    float dor=clamp(.5-max(abs(cf)-wd*.22,abs(y-top*.6)-top*.06)/(cw+pxa),0.,1.)*step(.3,hh);
    c=mix(c,bcl,bx);c+=mix(P.a1,P.a2,step(.5,hh))*bx*dor*(.15+.8*bxSpec(hh)*uDose+1.2*BXHF*uDose*step(.6,fract(hh*7.)))*(1.-.5*fr);}}
  // world features: the ringed planet over the moon base, the aurora over the crystal valley
  if(k>5.5&&k<6.5){
    vec3 pp=normalize(vec3(-.6,.34,.72));float dp=length(rd-pp),Rp=.26;
    c=mix(c,mix(vec3(.9,.62,.38),vec3(.5,.35,.8),.5+.5*sin(dot(rd,vec3(40.,70.,8.)))),smoothstep(Rp+pxa,Rp-pxa,dp)*.95);
#if HD>=1
    float rg=abs(length((rd-pp)/vec3(1.,.26,1.))-.42);c+=vec3(.9,.8,.6)*smoothstep(.05,.01,rg)*(1.-smoothstep(Rp-.02,Rp,dp)*step(rd.y,pp.y))*(.4+.6*BXB2.w*uDose);
#endif
  }
  if(k>2.5&&k<3.5){
    // a clock as big as the sky, its hands stepping on the beat
    vec3 pp=normalize(vec3(.62,.34,.7)),ux=normalize(vec3(pp.z,0.,-pp.x));vec2 cu=vec2(dot(rd,ux),dot(rd,cross(pp,ux)));
    float dp=dot(rd,pp),rc=length(cu),fr=.42,an=atan(cu.y,cu.x),pxr=pxa/fr;rc/=fr;
    if(dp>0.){
      float face=smoothstep(1.+pxr,1.-pxr,rc);
      vec3 fc2=mix(vec3(.96,.82,.5),vec3(.72,.46,.16),smoothstep(.75,1.,rc));
      float hr=0.,mnt=0.,hd=0.;
#if HD>=1
      float th2=fract(an*1.909859)-.5;hr=clamp(1.-(max(abs(th2)*rc*.52-.018,abs(rc-.84)-.075))/(pxr*1.4),0.,1.);
      mnt=clamp(1.-(max(abs(fract(an*9.549)-.5)*rc*.105-.004,abs(rc-.92)-.03))/(pxr*1.4),0.,1.);
      hd=max(clamp(1.-(max(abs(dot(cu/fr,vec2(sin(BXTW*.5),-cos(BXTW*.5))))-.015,max(-dot(cu/fr,vec2(cos(BXTW*.5),sin(BXTW*.5))),dot(cu/fr,vec2(cos(BXTW*.5),sin(BXTW*.5)))-.5)))/(pxr*1.4),0.,1.),clamp(1.-(max(abs(dot(cu/fr,vec2(sin(BXTW*.125),-cos(BXTW*.125))))-.022,max(-dot(cu/fr,vec2(cos(BXTW*.125),sin(BXTW*.125))),dot(cu/fr,vec2(cos(BXTW*.125),sin(BXTW*.125)))-.32)))/(pxr*1.4),0.,1.));
#endif
      fc2=mix(fc2,vec3(.1,.07,.05),max(max(hr,mnt),hd));
      c=mix(c,fc2,face);
      float rg2=clamp(1.-abs(rc-1.)/.035,0.,1.);c+=P.a1*rg2*(.25+1.2*BXB1.z*uDose+.9*BXKK*uDose);
      c+=vec3(1.,.8,.4)*hr*face*(.1+1.5*.5*(BXB2.z+BXB2.w)*uDose);
    }
  }
#if HD>=1
  if(k>11.5&&k<12.5){
    // the sea's silver ceiling seen from below, shafts of light falling with the mids
    float wv=vnoise(rd.xz/(abs(y)+.15)*7.+uTime*.1);
    c=mix(c,vec3(.75,1.,.95),smoothstep(.1,.6,y)*(.35+.65*wv));
    float sh2=pow(max(.5+.5*sin(ayr*9.+uTime*.15+wv*3.),0.),9.)*smoothstep(.75,.0,y)*smoothstep(-.1,.2,y);
    c+=vec3(.7,1.,.9)*sh2*(.18+1.1*(BXB1.z+BXB1.w)*uDose);
  }
#endif
  if(k>12.5&&k<13.5){
    // shelves to the ceiling all round the room
    float sh3=fract(y*11.+.02*floor(ayr*22.)),col2=fract(ayr*22.);
    float bw2=step(.08,fract(ayr*120.+.3*floor(y*11.)));c=mix(mix(vec3(.2,.1,.05),mix(vec3(.5,.14,.12),vec3(.75,.55,.2),fract(floor(ayr*120.)*.37+floor(y*11.)*.71)),.8)*(.45+.55*bw2),vec3(.12,.06,.03),smoothstep(.1,.0,sh3)+smoothstep(.04,.0,min(col2,1.-col2)));
    c*=.7+.5*smoothstep(-.2,.8,y);
  }
  if((k>3.5&&k<4.5)||k>14.5){
    float au=sin(ayr*7.+uTime*.2);
    float cur=exp(-max(y-.22-.08*au,0.)*7.)*smoothstep(.02,.25,y)*smoothstep(.75,.3,y);
    // the snow forest's aurora is green and violet, never the pale accents
    vec3 ac=k>14.5?mix(vec3(.05,.8,.4),vec3(.5,.12,.85),.5+.5*sin(ayr*3.+y*6.)):mix(P.a1,P.a2,.5+.5*sin(ayr*3.+y*6.));
    c+=ac*cur*(.3+1.3*(BXB1.w+BXB2.x)*uDose);
  }
  return max(c,0.);
}
// the maker's mark of the box worlds, a 5x7 pixel face (p.x 0..60, p.y 0..7)
float bxMk(vec2 p){
  if(p.x<0.||p.x>=60.||p.y<0.||p.y>=7.)return 0.;
  const ivec2 G[8]=ivec2[8](ivec2(508430,1086),ivec2(1020036,4228),ivec2(476721,17966),ivec2(583347,17969),
                            ivec2(1032734,16927),ivec2(1001009,17982),ivec2(476735,17969),ivec2(1001022,16912));
  const int W[10]=int[10](0,1,2,3,4,5,-1,6,7,4);
  int ci=int(p.x/6.),cx=int(p.x)-ci*6,g=W[ci];
  if(g<0||cx>4)return 0.;
  int r=6-int(p.y),bits=r<4?(G[g].x>>((3-r)*5))&31:(G[g].y>>((6-r)*5))&31;
  return float((bits>>(4-cx))&1);
}
// a window grid on a face: returns coverage (cw/ch cell sizes, fx/fy lit fractions), fading into the average with distance
float bxWin(float fu,float fv,float cw,float ch,float fx,float fy,float fpg,out vec2 cell){
  vec2 g=vec2(fu/cw,fv/ch),w=fpg/vec2(cw,ch);cell=floor(g);
  float cov=bxPulse(g.x,fx,w.x)*bxPulse(g.y,fy,w.y);
  return mix(cov,fx*fy,smoothstep(.12,.42,max(w.x,w.y)));
}
#if HD>=2
vec3 bxRender(vec2 sc){
#else
void realm(){
  vec2 sc=scr();
#endif
  float tf=uP1.w,pxa=2.*tf/uRes.y;
  vec3 ro=uP1.xyz,rd=normalize(uM1*vec3(sc*2.*tf,1.));
  float st=uP3.x,k=0.,cs=.15,sd=0.;
  float lev=0.,tc=0.,seg=0.,T=1.,hit=0.,m=0.,t0=1e3,ry=0.;vec3 acc=vec3(0.);
  vec3 p=ro,lq=vec3(0.),lh=vec3(1.),hc=vec3(0.);
  float dPrev=1e9,fpPrev=1.,edge=0.,eSt=0.,eT=0.,eW=1.;
  float ySc=(.56+.72*BXBASS)*1.3*1.34*(1.+BXEXP*.6);
  float ph=0.,kk=0.,ao=1.,sh=1.,ts=.003,hn=1e-5;vec3 hp=p,n=vec3(0.),Ls=vec3(0.,1.,0.);
  int nMax=BXN+32;
  bxDW=mix(bxFm(mod(uP2.z,8.)),bxFm(mod(floor(uP2.z*.125),8.)),floor(uP2.z/64.)*.01);bxDP=uP4.w;bxDA=min(.34,(.1+.3*uEnergy)*uDose);
#if HD>=1
  nMax=BXN+60+int(clamp(uDetail,1.,10.)*70.);
#endif
  for(int i=BX0;i<nMax;i++){
    vec3 x=p;
    int ki=int(kk);vec3 e4=.5773*(2.*vec3(float(((ki+3)>>1)&1),float((ki>>1)&1),float(ki&1))-1.);
    if(ph<.5){
      vec3 q=bxToC(p);
      if(step(lev,BXLMAX-.5)*step(bxM3(abs(q)),BXB)>.5){
        if(lev<.5)t0=tc;
        float fa=1.-exp(-(tc-seg)*.16);
        acc+=T*fa*(.55+.4*cos(mod(floor(st),BXWORLDS)*1.7+vec3(.4,2.,3.6)));T*=1.-fa;
        p=q*BXK;rd=bxRot(rd);tc*=BXK;seg=tc;lev+=1.;
        st=uP3.x+(uP3.y-uP3.x)*step(.5,lev)+(uP3.z-uP3.y)*step(1.5,lev)+(uP3.w-uP3.z)*step(2.5,lev)+(uP4.x-uP3.w)*step(3.5,lev);dPrev=1e9;
        if(p.y<BXG){vec3 ap=abs(p);hit=1.;m=10.;hp=p;n=mix(vec3(0.,0.,sign(p.z)),vec3(sign(p.x),0.,0.),step(ap.z,ap.x));ph=9.;break;}
      }
      if(step(1.001,bxM3(abs(p)))>.5)break;
      x=p;
    } else if(ph<1.5) x=hp+e4*hn;
#if HD>=1
    else if(ph<2.5) x=hp+n*(.006*pow(1.3,kk));
    else{x=hp+Ls*ts;if(max(step(1.,bxM3(abs(x))),step(.9,ts))>.5)break;}
#else
    else if(ph<2.5) x=hp+n*mix(.045,.012,step(kk,.5));
    else{x=hp+Ls*ts;if(max(step(1.,bxM3(abs(x))),step(.9,ts))>.5)break;}
#endif
    k=mod(floor(st),BXWORLDS);sd=fract(st)*97.;cs=bxCs(k);
    float dm,rr;vec3 a1,a2,a3;
    float d=x.y-BXG;dm=0.;a1=vec3(0.);a2=vec3(1.);a3=vec3(0.);rr=0.;
    {float mL,fv2;vec3 lq2,lh2,hc2;float db=bxLot(x,k,sd,cs,mL,lq2,lh2,hc2,fv2);if(db<d){d=db;dm=mL;a1=lq2;a2=lh2;a3=hc2;rr=fv2;}
     if(k<.5){float mC;float dc=bxCastle(x,ySc/1.3,mC,lq2,lh2,fv2);if(dc<d){d=dc;dm=mC;a1=lq2;a2=lh2;a3=vec3(.4,.5,.3);rr=fv2;}}

#if HD>=1
     else{float dh=bxHero(x,k,(ySc/1.742-.56)/.72*1.,lq2,lh2);if(dh<d){d=dh;dm=BXHM[int(k)];a1=lq2;a2=lh2;a3=vec3(.6,.5,.45);rr=lq2.y;}}
#endif
    }
#if HD>=1
    {float fpx=ph<.5?max(tc,.003)*pxa:.002,mp;vec3 lp,lh3;float dp=bxProps(x,k,sd,cs,fpx,mp,lp,lh3);if(dp<d){d=dp;dm=mp;a1=lp;a2=lh3;a3=vec3(.6,.5,.45);rr=0.;}
     if(d<.012&&dm>.5)d+=bxRelief(x,dm,a1,a2,fpx);}
#endif
    {vec3 qs;float ds=bxShell(x,step(BXLMAX-.5,lev),BXUNF*step(lev,.5),qs);if(ds<d){d=ds;dm=9.;a1=qs;a2=vec3(BXB*(1.+BXTH));}}
    if(ph<.5){
      float fp=max(tc,.003)*pxa;
#if HD>=1
      if(d<(.3/(1.+.3*float(HD)))*fp){
#else
      if(d<.3*fp){
#endif
        hit=1.;hp=p;m=dm;lq=a1;lh=a2;hc=a3;ry=rr;ph=1.;kk=0.;hn=max(fp*.6,1e-5);Ls=bxSun(k,sd);if(lev<.5)t0=tc;
      }
      else{
        if(step(dPrev,d)*step(dPrev,1.3*fpPrev)*step(edge,0.)>.5){edge=1.-smoothstep(.4,1.3,dPrev/fpPrev);eSt=st;eT=tc-seg;eW=T;}
        dPrev=d;fpPrev=fp;
        float s=d,yTop=BXG+bxTop(k)*ySc;
        if(p.y<yTop&&bxM3(abs(p))<1.){
          vec2 rs=(step(0.,rd.xz)*2.-1.)*max(abs(rd.xz),vec2(1e-5));
          vec2 cb=(floor(p.xz/cs)+step(0.,rd.xz))*cs,tx=(cb-p.xz)/rs;
          s=min(min(s,bxL),max(min(tx.x,tx.y),0.)+max(fp*.3,1e-5));
        }else if(rd.y<0.)s=min(s,(p.y-yTop)/max(-rd.y,1e-4)+max(fp*.3,1e-5));
        if(lev<BXLMAX-.5){
          vec3 cq=bxToC(p),cr=bxRot(rd);
          vec3 inv=sign(cr+vec3(1e-12))/max(abs(cr),vec3(1e-8));
          vec3 ta=(-vec3(BXB)-cq)*inv,tb=(vec3(BXB)-cq)*inv;
          vec3 tn=min(ta,tb),tx2=max(ta,tb);
          float entry=max(tn.x,max(tn.y,tn.z)),leave=min(tx2.x,min(tx2.y,tx2.z));
          if(entry>0.&&leave>entry)s=min(s,entry+1e-6);
        }
        p+=rd*s;tc+=s;
      }
    } else if(ph<1.5){n+=e4*d;kk+=1.;if(kk>3.5){n=normalize(n);ph=2.;kk=0.;
    }}
#if HD>=1
    else if(ph<2.5){float h=.006*pow(1.3,kk),nA=float(7+3*HD);ao*=mix(1.,clamp(.35+.65*d/h,0.,1.),2./nA);kk+=1.;if(kk>=nA)ph=3.;}
    else{sh=min(sh,14.*d/ts);if(sh<.02)break;ts+=clamp(d*.7,.0009,.03);}
#else
    else if(ph<2.5){float h=mix(.045,.012,step(kk,.5));ao*=clamp(.35+.65*d/h,0.,1.);kk+=1.;if(kk>1.5)ph=3.;}
    else{sh=min(sh,10.*d/ts);if(sh<.02)break;ts+=clamp(d,.004,.08);}
#endif
  }
  if(ph<1.9){if(ph<1.5)n=vec3(0.,1.,0.);else n=normalize(n);}
  k=mod(floor(st),BXWORLDS);sd=fract(st)*97.;
  float tO=0.,isO=0.,oTop=0.,fly=step(13.5,k)*step(k,14.5);
  if(hit<.5){
    // v22 the world does not end at its plate. Beyond it the ground runs on to the horizon, and on it stand more boxes, stacked
    // cube on cube into towers that climb ring on ring away from the plate, gaps between them so the sky still shows: a walk
    // over big cells with an exact box test in each, done once after the march (no march steps, no map). Each tower wears the
    // world's own material at giant scale, its top cube may have a lit door (every box is a world), rows rise and sink on the
    // dance wave, the spectrum plays round the horizon and the kick's hop arrives a moment later than in the world.
    // fxc (D3D11) is fragile here: a world-dependent branch in this walk (floating boxes over the cloud sea) made the HD 0
    // compile 10x slower; keep the walk's body world-independent.
    vec3 rs=(step(0.,rd)*2.-1.)*max(abs(rd),vec3(1e-5)),iv=1./rs;
    float tg=rd.y<0.?(BXG-p.y)*iv.y:1e3,t=0.,tb=-1.;
    for(int j=BX0;j<12;j++){
      vec2 id=floor((p.xz+rd.xz*(t+2e-4))/BXOC),cc=(id+.5)*BXOC;
      float tn=min(((id.x+step(0.,rd.x))*BXOC-p.x)*iv.x,((id.y+step(0.,rd.z))*BXOC-p.z)*iv.z),rr=max(abs(cc.x),abs(cc.y));
      vec3 av=bxAve(cc);
      if(rr>1.&&abs(av.x)>.3+.14*av.z&&h21(id+sd)>.3+.25*step(rr,1.6)){
        float h1=h21(id+sd),h2=h21(id.yx*1.37+sd+3.1),w=.1+.08*h1,bp=abs(cc.x)/length(cc),dl=length(cc-BXC.xz);
        float H=(.05+.11*(rr-1.)+.4*h2*h2*h2+step(.95,h2)*step(1.9,rr)*1.3)*(1.+2.4*bxDA*sin(dot(vec3(dl,cc),bxDW)+bxDP+sd))+w*(.1+1.2*bxSpec(bp)*uDose)+.3*BXEXP*h2+(bxHopE(uP4.z-.12*dl)+bxHopE(BXRB-.12*dl))*.07*uDose;
        vec2 of=(vec2(h1,h2)-.5)*(BXOC-2.*w-.02);vec3 bc=vec3(cc.x+of.x,BXG+H*.5,cc.y+of.y),bh=vec3(w,H*.5,w),ta=(bc-bh-p)*iv,tc2=(bc+bh-p)*iv,t0v=min(ta,tc2),t1v=max(ta,tc2);
        float te=max(t0v.x,max(t0v.y,t0v.z)),tl=min(t1v.x,min(t1v.y,t1v.z));
        if(te<tl&&te<tg&&tl>0.){
          tb=max(te,0.);vec3 q=p+rd*tb-bc;n=-sign(rs)*step(vec3(te),t0v);
          float s=2.*w,dn=bh.y-q.y,ci=floor(dn/s);lq=vec3(q.x,s-(dn-ci*s),q.z);lh=vec3(w,s*.5,w);hc=vec3(fract(h1*7.+ci*.31),fract(h2+ci*.37),bp+2.*step(ci,.5));
          ao=.5+.5*smoothstep(0.,.3,p.y+rd.y*tb-BXG);break;
        }
      }
      t=tn;if(t>tg)break;
    }
    if(tb>=0.){hit=1.;m=9.;tO=tb;isO=1.;oTop=step(1.5,hc.z);hc.z-=2.*oTop;}
    else if(tg<7.){hit=1.;m=0.;tO=tg;n=vec3(0.,1.,0.);hc=vec3(0.);}
    p+=rd*tO;tc+=tO;sh=1.;
  }
  float vr=mod(floor(mod(sd,3.))+uSection-step(uSecAge*2.4,hit>.5?length(p.xz-BXC.xz):5.+4.*rd.y),3.);BxP P=bxPal(k,vr);vec3 L=bxSun(k,sd);
  float fp=max(tc,.003)*pxa,tseg=tc-seg,voc=.5*(BXB2.x+BXB2.y),calm=mod(uP5.z,2.),hchase=floor(uP5.z*.5)*.01,lvl=.55+.45*uDose;
  float mel=.5*(BXB1.z+BXB1.w),hi=.5*(BXB2.z+BXB2.w);vec3 Nh=.55+.4*cos(mod(floor(st)+1.,BXWORLDS)*1.7+vec3(.4,2.,3.6));
  vec3 col=P.skyH;
  if(hit>.5){
    sh=clamp(sh,0.,1.);
    float vdn=max(abs(dot(n,rd)),.2),fpg=fp/vdn;
    vec3 alb=P.gnd,em=vec3(0.);
    float inkL=0.,gl=0.,matT=floor(m+.01),mf=floor(fract(m)*10.+.5);
    vec3 an=abs(n);float topF=step(max(an.x,an.z),an.y),xf=step(an.z,an.x),side=1.-topF;
    float bp=hc.z,blv=bxSpec(bp),bar=.1+1.1*blv*uDose+.45*voc*uDose+.5*BXEXP*uDose;
    // the special box wears its world's architecture
    float isP=step(8.5,m)*step(m,9.3),isPo=step(9.3,m);vec4 fzq=vec4(0.,9.,0.,1.);vec3 fzc=vec3(0.);float fzE=0.;
    if(isP>.5){float wm=1.;if(k>.5)wm=3.;if(k>1.5)wm=6.;if(k>2.5)wm=4.;if(k>3.5)wm=5.;if(k>4.5)wm=7.;if(k>5.5)wm=4.;if(k>6.5)wm=1.;if(k>7.5)wm=1.;if(k>8.5)wm=8.;if(k>9.5){wm=11.;mf=1.;if(isO>.5){wm=3.;mf=0.;}}if(k>10.5){wm=12.;mf=0.;}if(k>11.5){wm=13.;mf=2.;if(isO>.5){wm=1.;mf=0.;}}if(k>12.5){wm=14.;mf=1.;}if(k>13.5){wm=15.;mf=1.;}if(k>14.5){wm=16.;mf=2.;}matT=wm;if(isO<.5)hc=vec3(.6,.5,.45);}
    float fu=mix(lq.x,lq.z,xf),fv=mix(lq.y,lq.z,topF);
    if(mf>.5&&mf<1.5){fu=atan(lq.z,lq.x)*lh.x;fv=lq.y;}
    if(m<.5){
      // ---- ground: each world has its own floor
      vec2 g=p.xz;vec3 av=bxAve(p.xz);float W=.03+.14*av.z,onP=clamp(.5-(abs(av.x)-W)/(2.*fpg),0.,1.)*step(-.6,av.y)*step(av.y,1.2);
      // one pair of noise octaves serves every floor, at the world's own scale and drift (one pair keeps the shader small)
      float nf=k>1.5&&k<2.5?23.:(k>10.5&&k<11.5?7.:(k>11.5&&k<12.5?16.:(k>13.5&&k<14.5?7.:30.)));
      vec2 ng=g*nf+sd+vec2(uTime*.05*(1.+3.*step(11.5,k)*step(k,12.5))*step(10.5,k)*step(k,14.5),0.);
      float n1=vnoise(ng),n2=vnoise(ng*2.3-vec2(0.,uTime*.06)),nb=smoothstep(.3,1.,fpg*nf);
      vec2 cc=g/.05;float pa=bxPulse(cc.x,.92,fpg/.05)*bxPulse(cc.y,.92,fpg/.05),vN=mix(n1,.5,nb);
      // the shared floor: two tones broken by noise, plates where the world is built, scattered flecks in the accent
      float pl=step(.5,k)*step(k,1.5)+step(2.5,k)*step(k,3.5)+step(8.5,k)*step(k,10.5)+step(12.5,k)*step(k,13.5);
      alb=mix(P.gnd*(.62+.7*vN),P.gnd*(.7+.6*pa),pl);gl=.15+.3*pl;
#if HD>=1
      vec2 fc=g/.03,fid=floor(fc);float fh=h21(fid+sd),fl=smoothstep(.3,.1,length(fract(fc)-.5))*smoothstep(.7,.25,fpg/.03);
      float dots=step(.72,fh)*fl*(1.-pl);
      alb=mix(alb,mix(P.a2,P.a1,fh),dots*step(1.5,k)*step(k,7.5));
      em+=P.a1*dots*step(.86,fh)*step(1.5,k)*(.1+1.5*hi*uDose);
#endif
      // the avenue is a woven runner in the world's colours: edge bands, and chevrons that step toward the door on the beat
      float ay=av.y*26.-uBeat,wy=11.3*fpg/max(av.z,.001),cx2=abs(av.x)/W,chv=mix(step(.5,fract(ay-cx2*1.6)),.5,smoothstep(.4,1.,wy)),edg=smoothstep(.74,.82,cx2);
      vec3 ac2=k<.5?mix(vec3(.46,.4,.33),vec3(.6,.54,.45),chv):mix(P.ba*.62,mix(P.a1,P.ba,.42)*1.05,chv);
      alb=mix(alb,mix(ac2,P.a2*.88,edg*step(.5,k)),onP*.92);
      if(k<.5){
        vec3 c0=bxToC(vec3(p.x,0.,p.z));float moat=smoothstep(.04,.02,abs(max(abs(c0.x),abs(c0.z))-.56));
        alb=mix(alb,vec3(.1,.28,.55),moat);gl+=.5*moat;
        // the meadow: mown bands and scattered flowers; the road is cobbled
        vec2 fc=g/.024,fi=floor(fc);float fh=h21(fi+sd),fl=step(.72,fh)*smoothstep(.36,.2,length(fract(fc)-.5))*(1.-smoothstep(.4,.9,fpg/.024));
        alb=mix(alb*(.86+.28*sin(g.x*44.+vN*3.)),mix(vec3(1.,.35,.45),vec3(1.,.9,.3),fract(fh*9.)),fl*(1.-onP)*(1.-moat));
        vec2 cb=g/.0095;cb.x+=.5*mod(floor(cb.y),2.);float cbp=bxPulse(cb.x,.84,fpg/.0095)*bxPulse(cb.y,.84,fpg/.0095);
        alb=mix(alb,alb*(.55+.6*cbp)*(.85+.3*h21(floor(cb)+sd)),onP);
      }else if(k<1.5){
        em+=P.a1*(1.-pa)*(.03+.3*BXB1.y*uDose);
        vec2 cL=g/cs,fL=fract(cL)-.5;float road=step(.4,max(abs(fL.x),abs(fL.y)));
        float tr3=smoothstep(.09,.0,abs(fract(cL.y*3.-uTime*.5*sign(fL.x))-.5))*step(.42,abs(fL.x))+smoothstep(.09,.0,abs(fract(cL.x*3.+uTime*.5*sign(fL.y))-.5))*step(.42,abs(fL.y));
        em+=mix(vec3(1.,.85,.5),vec3(1.,.18,.2),step(0.,fL.x*fL.y))*tr3*road*(1.-smoothstep(.1,.4,fpg/cs*6.))*(.35+.9*hi*uDose);
        float dsh=step(.5,fract(av.y*30.-.8*uBeat));em+=mix(P.a2,P.a1,step(0.,av.x))*onP*dsh*(.25+.9*BXKK*uDose)*smoothstep(W*.2,W*.05,abs(abs(av.x)-W*.5));
      }else if(k>4.5&&k<9.5){
        // five designed floors: glazed candy checks, a cratered regolith, raked gravel, wind-rippled dunes, dancing tiles
        if(k<5.5){
          vec2 cg=g/.06;float chk=mod(floor(cg.x)+floor(cg.y),2.),tile=bxPulse(cg.x,.9,fpg/.06)*bxPulse(cg.y,.9,fpg/.06);
          vec2 pg=fract(cg)-.5;float gz=clamp(1.-length(pg-vec2(-.18,.2))*1.6,0.,1.);
          alb=mix(vec3(.5,.08,.32),mix(P.gnd*1.02,mix(P.ba,P.a2,.28)*1.05,chk)*(.9+.35*gz),tile);
          vec2 sg=g/.02;float sh2=h21(floor(sg)+sd),sf=step(.8,sh2)*smoothstep(.3,.16,length(fract(sg)-.5))*(1.-smoothstep(.3,.8,fpg/.02));
          alb=mix(alb,clamp(abs(fract(sh2*7.+vec3(0.,.67,.33))*6.-3.)-1.,0.,1.),sf*(1.-onP));
        }else if(k<6.5){
          vec2 cg=g/.11,cid=floor(cg);float ch=h21(cid+sd);vec2 cf=fract(cg)-.5-(vec2(h21(cid+3.),h21(cid.yx+7.))-.5)*.36;
          float cr=length(cf)/(.16+.18*ch),dk=smoothstep(1.,.82,cr)*step(.1,ch),rim=clamp(1.-abs(cr-1.08)/(.14+fpg/.11*3.),0.,1.)*step(.1,ch);
          alb=mix(mix(P.gnd*(.7+.5*vN),P.gnd*.42,dk),P.ba,rim*.72);em+=P.a2*dk*.05+P.a1*rim*(.03+.9*BXKK*uDose)*step(.72,ch);
        }else if(k<7.5){
          float rk=length(fract(g/cs)-.5)*cs,rk2=mix(.5+.5*sin(rk*430.),.5,smoothstep(.2,.7,fpg*70.));
          alb=mix(vec3(.62,.52,.36),vec3(.82,.72,.52),rk2)*(.86+.3*vN);em+=P.a2*.02*rk2;
        }else if(k<8.5){
          float du=sin(g.y*46.+sin(g.x*9.+sd)*2.3+vN*1.6),rp=mix(.5+.5*sin(g.y*380.+sin(g.x*60.)*2.),.5,smoothstep(.2,.7,fpg*60.));
          alb=mix(P.gnd*.68,P.gnd*1.14,smoothstep(-.6,.9,du))*(.84+.26*rp);
        }else{
          vec2 tg=g/.05;float th=h21(floor(tg)+sd);vec3 tc=clamp(abs(fract(floor(th*6.)/6.+vec3(0.,.67,.33))*6.-3.)-1.,0.,1.);
          alb=mix(vec3(.02),.06+.1*tc,pa);em+=tc*pa*(.03+1.3*BXKK*uDose*step(.6,fract(th*5.))+smoothstep(.75,1.,fract(uBeat*.25+th))*(.05+1.3*mel*uDose));
        }
      }else if(k<2.5){
        // the forest floor: dark moss in drifts, the mycelium's veins running with the kick and the mids
        float v2=abs(n1-.5),vb=nb;
        alb=mix(alb*.75,mix(vec3(.2,.07,.28),vec3(.04,.17,.13),vN),.5);
        em+=P.a1*mix(smoothstep(.016+fpg*8.,.0,v2),.03,vb)*(.05+1.5*BXKK*uDose+.8*mel*uDose);
      }else if(k<3.5){
        // riveted deck plates with hot seams and a moving belt of links along the avenue
        vec2 rv=fract(g/.05)-.5;float rd2=smoothstep(.18,.1,max(abs(rv.x),abs(rv.y))-.34);
        float nr=clamp(1.-(length(fract(g/.016)-.5)-.2)/(fpg/.016),0.,1.)*(1.-pa);
        alb=mix(alb,vec3(.45,.36,.2),nr);em+=P.a1*(1.-pa)*(.04+.4*BXB1.x*uDose)+P.a2*rd2*.02;
        float lnk=step(.5,fract(av.y*40.-1.5*BXTW));em+=P.a1*onP*lnk*smoothstep(W*.5,W*.35,abs(av.x))*(.06+.35*BXKK*uDose);
      }else if(k>3.5&&k<4.5){
        float cr=abs(vN-.5);alb=mix(P.gnd*.5,P.gnd*.3,smoothstep(.04,.0,cr));gl=.5;em+=mix(P.a1,P.a2,.5)*smoothstep(.02,.0,cr)*(.15+1.3*mel*uDose);
      }else if(k>9.5&&k<10.5){
        // the circuit board: copper traces, pads and vias, with packets of light running along them on the hats and mids
        vec2 tg=g/.042,tid=floor(tg),tf2=fract(tg)-.5;float ht=h21(tid+sd),tr=mix(abs(tf2.y),abs(tf2.x),step(.5,ht));
        float tw2=.09+.09*step(.7,ht),trc=clamp(.5-(tr-tw2)/(fpg/.042),0.,1.),pad=clamp(.5-(length(tf2)-.26)/(fpg/.042),0.,1.)*step(ht,.28);
        float tb=max(smoothstep(.3,.9,fpg/.042),.0);trc=mix(max(trc,pad),.28,tb);
        alb=mix(mix(vec3(.02,.2,.12),vec3(.03,.28,.17),pa),vec3(.82,.6,.22),trc);gl=.25;
        float pk=fract(tid.x*.37+tid.y*.61+mix(tf2.x,tf2.y,step(.5,ht))*.5-.7*uBeat-hchase+ht*7.);
        em+=mix(P.a1,P.a2,step(.5,ht))*trc*smoothstep(.85,.97,pk)*(.3+2.4*hi*uDose+.8*mel*uDose)*(1.-tb);
      }else if(k>10.5&&k<11.5){
        // the lava sea: dark crust breaking into bright flows that surge with the bass
        float fl3=smoothstep(.72,1.15,n1+.55*n2);
        alb=mix(vec3(.05,.04,.05),vec3(.015),fl3);
        em+=mix(vec3(1.,.13,.02),vec3(1.,.72,.2),fl3*fl3)*(.14+fl3*(.75+.8*BXB1.x*uDose+.55*BXKK*uDose));gl=.05;
      }else if(k>11.5&&k<12.5){
        // the sand: rippled, with caustic light crawling over it
        float c1=n1+n2,cu2=pow(max(1.-abs(c1-1.)*2.5,0.),4.);
        alb=mix(P.gnd*.75,P.gnd*1.1,.5+.5*sin(g.x*60.+vN*5.));
        em+=vec3(.5,1.,.95)*cu2*(.14+.8*mel*uDose+.6*BXKK*uDose);
      }else if(k>12.5&&k<13.5){
        // the library floor: dark oak boards with a long woven runner down the avenue
        float bd=bxPulse(g.x/.028,.94,fpg/.028);alb=mix(vec3(.08,.04,.02),vec3(.42,.22,.1)*(.7+.6*h21(vec2(floor(g.x/.028),floor(g.y/.18))+sd)),bd);
        float wv=step(.5,fract(av.y*18.+abs(av.x)*7./W));alb=mix(alb,mix(vec3(.45,.07,.09),vec3(.75,.55,.2),wv),onP);
      }else if(k>13.5&&k<14.5){
        // the cloud sea: heaped billows, sunlit tops, blue hollows
        float c1=n1+.5*n2;
        alb=mix(vec3(.16,.1,.4),vec3(.95,.48,.45),smoothstep(.55,1.25,c1));alb=mix(alb,vec3(.95,.72,.4),smoothstep(1.15,1.4,c1)*.5);alb*=.84+.36*n2;em+=vec3(1.,.55,.3)*.08*smoothstep(.9,1.35,c1)+vec3(.6,.3,1.)*smoothstep(.62,.5,c1)*(.04+.5*mel*uDose);
      }else if(k>14.5){
        // snow: blue-shadowed drifts with sparkle on the hats
        float sg=h21(floor(g*140.)+sd);alb=mix(vec3(.42,.56,.9),vec3(.82,.9,1.),.5+.5*vN);
        em+=vec3(.9,.95,1.)*step(.82,sg)*smoothstep(.3,.1,length(fract(g*140.)-.5))*(1.-smoothstep(.1,.5,fpg*140.))*(.2+2.4*hi*uDose+BXHF*uDose*.7);
      }
      // v22 beyond the plate the floor is laid in great slabs, one under each far tower
      {vec2 oc=p.xz/BXOC;float og=step(1.,max(abs(p.x),abs(p.z)));
       alb*=mix(1.,(.35+.45*bxPulse(oc.x,.93,fpg/BXOC)*bxPulse(oc.y,.93,fpg/BXOC))*(.65+.35*mod(floor(oc.x)+floor(oc.y),2.)),og);em*=1.-.6*og;}
      // the kick's rings run out across every floor, the avenue's chase lights tick on hats, door spill
      float rr2=length(p.xz-BXC.xz)-BXB*1.4;vec2 rg=vec2(uP4.z,BXRB);
      vec2 rgl=clamp(1.-abs(rr2-1.3*rg)/(.008+fpg),0.,1.)*exp(-rg*2.6)*(1.-smoothstep(.6,.88,rg));
      em+=P.a1*(rgl.x+rgl.y)*(.7+.5*BXB1.x)*uDose;
      float ed=abs(abs(av.x)-W*.92),chs=fract(av.y*14.-.5*uBeat-hchase),al=(chs-.5)*av.z*log(BXK)/14.;
      em+=P.a2*clamp(1.5-length(vec2(al,ed))/(.006*av.z+fpg),0.,1.)*onP*(.5+2.*BXKK*uDose+.6*hi*uDose)*(1.-.6*calm);
#if HD>=1
      vec3 qd=bxToC(p);
      em+=mix(Nh,P.a1,.5)*exp(-length((qd.xz-vec2(0.,-BXB*1.25))/vec2(BXB*.8,BXB*1.5))*2.)*step(qd.z,-BXB)*(.5+1.1*BXB2.y*uDose+.6*BXKK*uDose);
#endif
    } else if(matT<1.5){
      // ---- masonry: running-bond stone, per-block tone, mortar lines, lit slit windows that fill with the music
      vec2 bg=vec2(fu/.0105+.5*mod(floor(fv/.0058),2.),fv/.0058);vec2 bw=fpg/vec2(.0105,.0058);
      float mort=bxPulse(bg.x,.9,bw.x)*bxPulse(bg.y,.86,bw.y);
      float tone=h21(floor(bg)+sd);tone=mix(tone,.5,smoothstep(.2,.55,max(bw.x,bw.y)));
      alb=mix(P.ba,P.bb,.25*hc.y)*(.8+.6*tone)*mix(.6,1.,mort);
      // moss at the foot of the walls, warm light high up
      alb=mix(alb,P.gnd*.9,smoothstep(.05,.0,fv)*step(k,.5)*.6);
      if(side>.5){
        vec2 cl;float cov=bxWin(fu,fv,.05,.042,.2,.42,fpg,cl)*(1.-step(7.5,k)*step(k,8.5));
        float lit=step(.45,h21(cl+sd))*clamp(.5-(clamp(fv/.3,0.,1.)-bar)/.15,0.,1.);
        alb=mix(alb,vec3(.03),cov);em+=mix(P.a2,P.a1,.3)*cov*lit*(.5+2.*mel*uDose+.4*BXKK*uDose)*1.6;
        // a carved course every few rows, each lighting on its own band as the rows climb
        float bi=floor(fv/.088);fzq=vec4(fu/(k<.5?.012:.024),(fract(fv/.088)-.8)/(k<.5?.05:.1),k<.5?2.:(k<7.5?3.:1.),fpg/(k<.5?.0044:.0088));
        fzc=k<.5?P.a1*.7:mix(P.a1,P.a2,mod(bi,2.));fzE=.05+1.2*bxSpec(mod(bi,8.)/7.)*uDose;
      }
      inkL=max(inkL,side*(1.-mort)*.35*smoothstep(.5,.15,max(bw.x,bw.y)));
    } else if(matT<2.5){
      // ---- roof tiles: overlapping scallops in rows, each row slightly its own colour
      float tu=fu/.009,tv=fv/.007,row=floor(tv);tu+=.5*mod(row,2.);vec2 tb=fpg/vec2(.009,.007);
      vec2 tf2=fract(vec2(tu,tv))-.5;float sc=length(vec2(tf2.x,(tf2.y+.5)*.7));float scl=smoothstep(.56,.5,sc);
      float rt=h11(row+hc.x*37.);vec3 rc=mix(P.a1,P.bb,step(.5,hc.y));rc=mix(rc,mix(vec3(.13,.42,.38),vec3(.72,.2,.14),step(.5,hc.y)),step(6.5,k)*step(k,7.5));
      alb=mix(rc*(.75+.5*rt),rc*.42,mix(1.-scl,.3,smoothstep(.2,.55,max(tb.x,tb.y))));
      gl=.1;em+=rc*side*.03;
    } else if(matT<3.5){
      // ---- city facade: fine lit windows that climb with each tower's band, piers, floor ledges, neon crown
      vec2 cl;float cov=bxWin(fu,fv,.0095,.0125,.58,.5,fpg,cl);
      float pier=1.-bxPulse(fu/.0095,.82,fpg/.0095);
      float ch=h21(cl+sd);
      float hgt=clamp(fv/max(lh.y*2.,.001),0.,1.);
      float lit=clamp(.5-(hgt-bar)/.08,0.,1.);
      lit=mix(lit*step(.22,ch),lit*.78,smoothstep(.12,.42,fpg/.0095));
      alb=mix(P.ba,P.bb,hc.y)*(.75+.5*hc.x)*(1.-.5*pier);
      float wc=mix(1.,step(ch,.5),smoothstep(.5,.2,fpg/.0095));
      vec3 wl=mix(P.a2,P.a1,bp);wl=mix(vec3(1.,.85,.55),wl,.35+.5*step(.5,fract(hc.x*5.)));
      em+=wl*cov*side*(1.-topF)*(.17+lit*wc*(.9+.45*BXKK*uDose)*(1.-.4*calm)+step(.62,ch)*(1.1*BXHF+.8*BXEXP)*uDose);
      alb=mix(alb,vec3(.02,.03,.06),cov*side);
      gl=.3*cov*side;
      // the crown: a neon band at the top of each tower, on the highs
#if HD>=1
      float crown=smoothstep(.0,.006,lh.y-abs(lq.y)-.0)*smoothstep(.018,.0,lh.y-lq.y);
      em+=mix(P.a1,P.a2,hc.x)*crown*side*(.6+1.8*hi*uDose+BXHF*uDose);
#endif
    } else if(matT<4.5){
      // ---- brass: machined rings, rivets, a dark groove in every gear, teal glow on the highs
      vec3 bc=mix(P.ba,P.ba*vec3(.82,.55,.42),step(.55,hc.y));bc=mix(bc,vec3(.55,.58,.62),step(1.5,mf)*step(mf,2.5));if(mf>2.5)bc=vec3(.26,.2,.16)*(.8+.5*hc.y);
      float pr=length(lq.xz);float grv=bxPulse(pr/.014,.8,fpg/.014),br=mix(.75,1.,grv);
      float aq2=atan(lq.z,lq.x),bolt=pr/max(lh.x,1e-3);
      // engraving on the wheel faces: a ring of bolts, fine radial brushing, dark tooth roots, a band that fills with its frequency
      float bl=(mf>.5&&mf<1.5)?clamp(1.-(length(vec2(fract(aq2*6.*.1591+.5)-.5,(bolt-.87)*2.8))-.075)/(fpg/max(lh.x,.01)*1.4),0.,1.):0.;
      float bru=mix(.5+.5*sin(aq2*90.),.5,smoothstep(.1,.5,fpg/(lh.x+.001)*14.));
      alb=bc*br*(.72+.42*abs(n.y))*(.92+.16*bru);
      alb=mix(alb,bc*.42,smoothstep(.97,.925,bolt)*smoothstep(.85,.9,bolt)*step(.5,mf)*step(mf,1.5));alb=mix(alb,vec3(.9,.78,.45),bl*.8);
      gl=.55;
#if HD>=1
      {float fq0=fpg/max(lh.x,.001),ne=24.+8.*float(HD),nr=26.*(1.+.5*float(HD)),e3=sin(aq2*ne+sin(bolt*14.)*2.)*sin(bolt*nr);
       float en=(1.-smoothstep(.25,.9,fq0*nr))*step(.5,mf)*step(mf,1.5)*topF;
       alb*=1.+.3*en*smoothstep(-.1,.1,e3)-.18*en;
       float rr3=abs(fract(bolt*(9.+3.*float(HD)))-.5);alb=mix(alb,bc*.5,en*.6*smoothstep(.06,.02,rr3));}
#endif
      float rim=clamp(1.-abs(pr-lh.x*.9)/(.005+fpg),0.,1.),bnd=clamp(1.-abs(bolt-.42)/(.14+fpg/(lh.x+.001)),0.,1.)*step(mf,1.5)*topF;
      em+=P.a2*rim*(.08+.6*hi*uDose)+P.a1*topF*(.05+.5*BXKK*uDose)+mix(P.a1,P.a2,bp)*bnd*(.05+1.4*blv*uDose)+vec3(1.,.8,.4)*bl*(.1+1.5*hi*uDose);
    } else if(matT<5.5){
      // ---- crystal: faceted cold light, a band that climbs inside each spire with its frequency, hot rims on the highs
      float fac=mix(h21(floor(n.xz*4.+.5)+hc.xy*7.),.5,smoothstep(.002,.008,fpg));
      if(mf>1.5){
        // dome panels
        vec2 pg=lq.xz/.018;float pn=bxPulse(pg.x,.9,fpg/.018)*bxPulse(pg.y,.9,fpg/.018);
        alb=mix(P.ba,P.bb,hc.x)*mix(.55,1.,pn)*(.7+.5*fac);
        em+=P.a2*(1.-pn)*(.05+.7*hi*uDose);
      }else{
        float facl=clamp(1.-abs(abs(lq.x)*.866+abs(lq.z)*.5-abs(lq.z))/(.0014+fpg),0.,1.);
        alb=mix(P.ba,P.bb,fac)*.24;
        float hgt=clamp(fv/max(lh.y,.001),0.,1.);
        vec3 gc=mix(mix(P.a1,P.a2,bp),.5+.48*cos(6.28*(hc.x+vec3(0.,.33,.67))),.6);
        em+=gc*(1.-hgt)*(1.-hgt)*(.15+.55*fac)*(.5+1.5*blv*uDose+.7*BXKK*uDose)+gc*facl*(.3+1.4*hi*uDose);
        em+=P.skyH*pow(1.-vdn,3.)*(.3+.9*hi*uDose);
        float gb=abs(fract(lq.y*26.+lq.x*38.)-.5),gl2=(1.-smoothstep(0.,.06+fpg*26.,gb))*(1.-smoothstep(.2,.6,fpg*26.));em+=gc*gl2*(.1+.8*blv*uDose);alb*=1.+.6*gl2;
        float spk=step(.975,h21(floor(lq.xz*320.+lq.y*310.)+hc.xy))*(1.-smoothstep(.2,.7,fpg*320.));em+=mix(gc,vec3(1.),.6)*spk*(.4+3.*hi*uDose);
        gl=.35;
      }
    } else if(matT<6.5){
      if(mf>1.5&&mf<2.5){
        // a pleated cap: concentric growth bands and radial pleats in the lot's own colour, a pale rim, and underneath the
        // gills light up with the lot's frequency band
        float rn=length(lq.xz)/max(lh.x,1e-3),aa2=atan(lq.z,lq.x),under=smoothstep(.02,-.05,lq.y/lh.x),fx=fpg/lh.x;
        float fi=fract(hc.x*3.7);vec3 c0=fi<.25?vec3(.95,.58,.12):(fi<.5?vec3(.48,.14,.62):(fi<.75?vec3(.06,.6,.54):vec3(.8,.26,.14)));
        float ple=.5,bnd2=.5+.5*sin(rn*20.);
#if HD>=1
        ple=mix(.5+.5*cos(aa2*26.),.5,smoothstep(.04,.2,fx*(rn+.2)));bnd2=mix(.5+.5*sin(rn*24.+hc.y*9.),.5,smoothstep(.06,.25,fx));
#endif
       
        vec3 top2=mix(c0*(.55+.55*bnd2),c0*vec3(1.1,1.2,1.3)+.15,smoothstep(.72,1.,rn)*.8)*(.72+.42*ple);
        float gill=mix(smoothstep(.2,.8,.5+.5*cos(aa2*54.)),.5,smoothstep(.03,.14,fx*(rn+.2)));
        vec3 gc2=mix(P.a1,P.a2,bp);
        alb=mix(top2,mix(vec3(.08,.03,.12),gc2*.35,gill),under);
        em+=gc2*under*gill*(.12+1.7*blv*uDose+.7*BXKK*uDose+.7*BXEXP*uDose);
        em+=mix(c0,vec3(1.),.45)*(1.-under)*smoothstep(.72,1.,rn)*(.05+1.3*hi*uDose+1.2*BXHF*uDose+.6*BXEXP*uDose);em+=c0*(1.-under)*BXEXP*uDose*.7;
      }else if(mf>3.5){
        // a sporeling: a soft body with one big dark eye and a lit pupil that widens on the highs
        vec3 u=normalize(lq);float ey=dot(u,normalize(vec3(sin(lh.x),.18,cos(lh.x))));
        alb=mix(vec3(.82,.42,.6),vec3(.98,.8,.5),.5+.5*u.y);
#if HD>=1
        alb=mix(alb,vec3(.02,.02,.05),smoothstep(.88,.92,ey));
#endif
        em+=mix(P.a1,vec3(1.),.4)*smoothstep(.945-.03*hi*uDose,.975,ey)*(.7+2.*hi*uDose+BXKK*uDose);
      }else if(mf>2.5&&mf<3.5){
        // foliage: clumped leaves, blossoms in the pagoda world, lit by the highs
        float cl=mix(vnoise(lq.xz*90.+lq.y*70.),.5,smoothstep(.15,.6,fpg*90.));
        vec3 lf=mix(vec3(.13,.36,.12),vec3(.4,.62,.15),cl);lf=mix(lf,P.a2*vec3(.92,.5,.62),step(6.5,k)*step(k,7.5));lf=mix(lf,(.45+.42*cos(6.28*(floor(hc.x*4.)*.25+vec3(.95,.28,.62))))*.8,step(13.5,k)*step(k,14.5));
        alb=lf*(.8+.5*cl);em+=lf*hi*uDose*smoothstep(.55,.8,cl)*.9;
      }else{
        // fluted bark and stems
        alb=mix(P.ba,P.ba*.55,bxPulse(fu/.008,.6,fpg/.008))*vec3(1.,.9,.72);
      }
    } else if(matT<7.5){
      // ---- candy: glossy peppermint swirls and spirals
      vec3 c2=mix(P.ba,P.bb,step(.5,fract(hc.x*3.)));
      if(mf>1.5){
        float ang=atan(lq.z,lq.x),s=fract(ang*3./TAU+length(lq.xz)*3.);
        alb=mix(c2,P.a2,smoothstep(.45,.5,abs(s-.5)*2.));
      }else{
        alb=mix(c2,P.a2,smoothstep(.0,.08,sin((fu+fv)/.0065)));
        fzq=vec4(fu/.012,(fract(fv/.06)-.5)/.14,2.,fpg/.0084);fzc=P.a1;fzE=.05+1.2*blv*uDose;
      }
      gl=.25;em+=c2*blv*uDose*.35;
    } else if(matT<8.5){
      // ---- stickers: six colours on black, lit by the band
      vec3 uq=lq/max(lh,vec3(1e-4)),au=abs(uq);
      vec2 fc2=mix(mix(uq.xy,uq.zy,step(au.z,au.x)),uq.xz,step(max(au.x,au.z),au.y));
      vec2 g2=(fc2*.5+.5)*3.,cf=fract(g2)-.5;float fw2=fpg/lh.x*1.5;
      float cov=bxPulse(g2.x,.86,fw2)*bxPulse(g2.y,.86,fw2);
      float ch=h21(floor(g2)+hc.xy*31.),k6=floor(ch*6.);
      vec3 sc6=clamp(abs(fract(k6/6.+vec3(0.,.67,.33))*6.-3.)-1.,0.,1.)*.95+.05;
      alb=mix(vec3(.02),sc6*(1.+.25*(.5-max(abs(cf.x),abs(cf.y)))),cov);
      em+=sc6*cov*(.08+.9*blv*uDose);
    } else if(matT<9.5){
      // a lit lantern: warm, swelling with the mids
      alb=P.a1*.4;em+=P.a1*(1.+2.2*mel*uDose+1.2*BXKK*uDose);
    } else {
      if(matT<10.5){
      // the plinth of an unfolded box's world: its ground in layers
      float dy=(BXG-p.y)*9.,fy=fpg*9.;
      alb=mix(mix(P.gnd*.55,P.bb*.45,step(.5,fract(dy))),P.gnd,clamp(1.-dy/(.12+fy),0.,1.));
      }else if(matT<11.5){
        // ---- circuit parts: chips with a lit die window, printed cans, silver legs, copper coils, LED bars
        vec3 gc=mix(P.a1,P.a2,bp);
        if(mf<1.5){
          alb=mix(vec3(.05,.05,.06),vec3(.09,.09,.1),step(.5,fract(hc.y*7.)));gl=.4;
          if(side>.5){float pin=bxPulse(fu/.012,.55,fpg/.012)*step(fv,.016);alb=mix(alb,vec3(.78,.8,.86),pin);float pr2=bxPulse(fu/.05,.8,fpg/.05)*bxPulse(fv/.012,.5,fpg/.012)*step(.02,fv);alb=mix(alb,vec3(.2,.22,.24),pr2*.8);em+=gc*(1.-pr2)*step(.02,fv)*smoothstep(.08,.0,abs(fract(fv/.05)-.5))*(.02+.8*blv*uDose);}
          vec2 ch=lq.xz/lh.xz,fq=fpg/max(lh.xz,vec2(1e-3));
          float die=clamp(.5-(max(abs(ch.x),abs(ch.y))-.42)/(1.5*max(fq.x,fq.y)),0.,1.)*topF;
          float gdie=mix(step(.5,fract(ch.x*10.))*step(.5,fract(ch.y*10.)),.25,smoothstep(.04,.18,max(fq.x,fq.y)));
          em+=gc*die*(.5+.7*gdie)*(.16+2.2*blv*uDose+.5*BXKK*uDose);
          alb=mix(alb,vec3(.3,.34,.38)*gdie,die);
          float pn1=clamp(1.-(length(ch-vec2(-.72,-.6))-.1)/(2.*max(fq.x,fq.y)),0.,1.)*topF;alb=mix(alb,vec3(.5),pn1);
          float lbl=mix(step(.5,fract(ch.x*14.+h21(floor(ch.yy*5.)+hc.xy*9.)*7.))*step(.12,fract(ch.y*4.)),.3,smoothstep(.03,.12,max(fq.x,fq.y)));
          alb=mix(alb,vec3(.8),lbl*.7*topF*(1.-die)*step(.45,abs(ch.y)));
        }else if(mf<2.5){
          float s2=step(.5,fract(atan(lq.z,lq.x)*.477+.25));vec3 cc2=step(.5,fract(hc.x*5.))>.5?vec3(.05,.1,.3):vec3(.35,.08,.1);
          alb=mix(mix(cc2,vec3(.82,.84,.88),s2*.85),vec3(.72,.74,.78),topF);gl=.4;
          vec2 kc=abs(lq.xz)/lh.x;float x=max(smoothstep(.06+fpg/lh.x,.03,min(kc.x,kc.y)),0.)*topF;alb=mix(alb,vec3(.3),x);
          em+=gc*topF*smoothstep(.72,.95,length(kc))*(.1+2.*blv*uDose+.7*BXKK*uDose);
        }else if(mf<3.5){alb=vec3(.72,.74,.8);gl=.7;}
        else if(mf<4.5){
          float wnd=mix(.5+.5*sin(atan(lq.z,lq.x)*44.+length(vec2(length(lq.xz)-lh.x,lq.y))*60.),.5,smoothstep(.12,.4,fpg/lh.x*6.));
          alb=mix(vec3(.5,.22,.08),vec3(.95,.55,.25),wnd);gl=.45;em+=gc*(.02+.6*blv*uDose)*wnd;
        }else{
          float cl2=fract(lq.z/.012+.5),on=step(fract((fv+.04)/.09),clamp(blv+.3*BXKK,0.,1.));
          alb=vec3(.05,.05,.07);em+=mix(vec3(1.,.3,.5),gc,bp)*smoothstep(.45,.2,abs(cl2-.5))*smoothstep(.3,.5,fract(lq.y/.012+.5)*.999)*step(.002,abs(fv))*(.14+2.8*on);
        }
      }else if(matT<12.5){
        // ---- basalt: rough dark columns, a crust on top cracked with light, lava glow climbing from the foot
        vec2 pg=lq.xz*55.;float cr3=abs(vnoise(pg+sd)-.5);cr3=mix(smoothstep(.1,.02,cr3),.2,smoothstep(.3,1.,fpg*55.));
        float ls=vnoise(vec2(atan(lq.z,lq.x)*6.,lq.y*70.));
        alb=mix(vec3(.13,.1,.11),vec3(.34,.27,.26),ls);
        float hot=exp(-fv*16.);vec3 lava=mix(vec3(1.,.2,.04),vec3(1.,.72,.2),cr3);
        em+=lava*(cr3*topF*(.35+2.4*mel*uDose+1.2*BXKK*uDose)+(hot*.9+.1)*side*(.16+1.6*BXB1.x*uDose));
        float jn=abs(fract(fv/.036+hc.x*5.)-.5),jc=(1.-smoothstep(.0,.05+fpg/.036,jn))*side*(1.-smoothstep(.2,.6,fpg/.036));alb=mix(alb,alb*.35,jc);em+=lava*jc*(.3+1.8*mel*uDose+1.1*BXKK*uDose+2.5*BXEXP*uDose+1.2*BXHF*uDose);em+=lava*cr3*topF*2.*BXEXP*uDose;
        if(lh.z>1.5)em+=vec3(1.,.5,.1)*smoothstep(.72,1.,fv/lh.y)*(.9+1.8*BXB1.x*uDose+BXKK*uDose);
      }else if(matT<13.5){
        // ---- reef: maze-ridged brain coral, ringed tube sponges, lacy fans, striped fish
        vec3 gc=mix(P.a1,P.a2,bp);
        if(mf<1.5){
          float brn=dot(sin(lq*340./max(lh.x,.02)*.06),cos(lq.yzx*340./max(lh.x,.02)*.06));
          float rb=mix(smoothstep(-.2,.3,brn),.5,smoothstep(.2,.6,fpg*22.));
          alb=mix(vec3(.85,.2,.32),vec3(1.,.55,.3),rb);em+=gc*rb*(.05+.8*blv*uDose);
        }else if(mf<2.5){
          float rg2=mix(.5+.5*sin(fv/.012),.5,smoothstep(.2,.7,fpg/.012));alb=mix(vec3(.45,.2,.7),vec3(.95,.5,.9),rg2);em+=gc*rg2*(.04+.7*blv*uDose);
        }else if(mf<3.5){
          alb=mix(vec3(.9,.32,.1),vec3(1.,.72,.2),smoothstep(0.,lh.x,length(lq.xy)));em+=P.a2*(.05+.6*hi*uDose);
        }else{
          float st2=step(.5,fract(lq.z/.012));alb=mix(vec3(1.,.78,.1),vec3(.1,.5,.95),st2);em+=alb*(.08+1.2*hi*uDose);
          alb=mix(alb,vec3(.02),smoothstep(.0035,.0025,length(vec2(lq.z-.007,lq.y-.005)-vec2(0.,0.))));
        }
      }else if(matT<14.5){
        // ---- books: cloth covers with gilt bands and a title block on the spine, cream page edges on top
        float tn=fract(hc.y*5.);vec3 cv=tn<.2?vec3(.55,.08,.1):(tn<.4?vec3(.1,.22,.48):(tn<.6?vec3(.05,.36,.26):(tn<.8?vec3(.6,.36,.08):vec3(.32,.1,.45))));
        vec2 fc3=lq.xy/lh.xy;float sp=step(.93,abs(lq.z)/lh.z),wdt=fpg/lh.x;
        float cb=mix(.5+.5*sin(fc3.x*30.+h21(hc.xy)*9.),.5,smoothstep(.04,.2,wdt));
        alb=cv*(.75+.35*cb);
        // the cover face: a tooled border and a stamped medallion, so no book is a plain slab
        vec2 cg2=lq.zy/lh.zy;float cf2=(1.-sp)*side,bx3=max(abs(cg2.x),abs(cg2.y)),wg=fpg/lh.y;
        float bord=clamp(1.-abs(bx3-.86)/(.022+wg*1.5),0.,1.)+clamp(1.-abs(bx3-.78)/(.012+wg*1.5),0.,1.),med=clamp(1.-abs(length(cg2*vec2(1.,.72))-.32)/(.024+wg*1.5),0.,1.),rs2=clamp(1.-(length(cg2*vec2(1.,.72))-.2+.06*sin(atan(cg2.y,cg2.x)*8.))/(.03+wg*1.5),0.,1.);
        float tool=clamp(bord+med+rs2,0.,1.)*cf2*(1.-smoothstep(.2,.5,wg*3.));
        alb=mix(alb,mix(cv*1.8+.05,vec3(.95,.78,.35),.75),tool);em+=vec3(1.,.8,.35)*tool*(.03+1.*hi*uDose);alb=mix(alb,vec3(.5,.42,.3)*(.75+.35*bxPulse(lq.y/.004,.5,fpg/.004)),topF);
        float wy3=fpg/lh.y,bnd3=(smoothstep(.04+wy3*2.,.015,abs(abs(fc3.y)-.84))+smoothstep(.03+wy3*2.,.01,abs(abs(fc3.y)-.92)))*sp*side*(1.-smoothstep(.1,.3,wdt));
        alb=mix(alb,vec3(.95,.78,.35),clamp(bnd3,0.,1.));em+=vec3(1.,.8,.35)*clamp(bnd3,0.,1.)*(.06+1.1*hi*uDose);
        float tl2=step(abs(fc3.y-.3),.32)*sp*side,gx=floor((fc3.x+1.)/.34),gy=floor(fc3.y/.05);
        float glp=step(.42,h21(vec2(gx,gy)+hc.xy*9.))*smoothstep(.1,.2,fract((fc3.x+1.)/.34))*smoothstep(.1,.2,fract(fc3.y/.05))*(1.-smoothstep(.2,.5,wdt*2.));
        alb=mix(alb,vec3(.95,.8,.4),glp*tl2);em+=vec3(1.,.82,.4)*glp*tl2*(.04+1.2*mel*uDose);
        gl=.1;
        if(mf>1.5){alb=mix(vec3(.2,.11,.05),vec3(.48,.28,.13),.5+.5*sin(lq.x*320.+lq.y*40.));em=vec3(0.);}
      }else if(matT<15.5){
        // ---- sky island: strata in the rock, meadow grass and flowers on top, falling water
        if(mf<1.5){float dpk=clamp(-lq.y/max(lh.y,1e-3),0.,1.),bq=dpk*6.+vnoise(lq.xz*40.+hc.xy*9.)*1.2,bw=fpg/max(lh.y,1e-3)*6.;
          vec3 j1=.5+.42*cos(6.28*(floor(hc.x*4.)*.25+.6+vec3(0.,.33,.67))),j2=.5+.42*cos(6.28*(floor(hc.x*4.)*.25+.72+vec3(0.,.33,.67)));
          float sb=mix(smoothstep(.3,.7,abs(fract(bq)-.5)*2.),.5,smoothstep(.3,.8,bw));alb=mix(j2*.62,j1*.26,sb)*(1.-.7*dpk);
          float vn=(1.-smoothstep(.0,.06+bw,abs(fract(bq)-.5)))*(1.-smoothstep(.3,.7,bw));em+=mix(j2,vec3(1.,.85,.5),.3)*vn*(.04+1.3*blv*uDose+.5*BXKK*uDose);}
        else if(mf<2.5){float fw2=vnoise(lq.xz*110.);alb=mix(vec3(.05,.32,.2),vec3(.2,.55,.25),fw2);float fp2=step(.84,vnoise(lq.xz*190.+hc.xy*9.));alb=mix(alb,vec3(1.,.8,.3),fp2*(1.-smoothstep(.2,.5,fpg*190.)));em+=alb*fp2*hi*uDose*.9;}
        else if(mf>3.5){alb=mix(vec3(.3,.18,.09),vec3(.62,.42,.22),.5+.5*sin(lq.x*420.));}
        else{float fl4=fract(lq.y*14.+uTime*.9+sin(lq.x*260.)*.5);alb=vec3(.8,.92,1.);em+=vec3(.7,.9,1.)*(.14+.9*fl4*fl4*(.3+mel*uDose));}

#if HD>=1
      }else if(matT>17.5){
        // ---- the landmark: tiers in the world's two tones, a frieze round each, windows between, and a ring at each tier's foot;
        // the tower plays its bands from the ground up, a meter as tall as the sky
        float N3=lh.z,y2=lq.y/lh.y,tN=clamp(floor(y2*N3),0.,N3-1.),tf3=fract(y2*N3),hyT=lh.y/N3,sq2=step(BXHR[int(k)].w,0.);
        float au=sq2>.5?(abs(lq.x)>abs(lq.z)?lq.z:lq.x):atan(lq.z,lq.x)*lh.x;
        float bmp=bxSpec(clamp(tN/max(N3-1.,1.),0.,1.));vec3 gc=mix(P.a1,P.a2,mod(tN,2.));
        alb=mix(P.ba*(1.05-.2*mod(tN,2.)),P.bb*1.2,mod(tN,3.)*.5)*(.82+.3*tf3);
        float wG=bxPulse(au/.03,.5,fpg/.03)*bxPulse(tf3*2.,.55,fpg/hyT*2.)*step(.34,tf3)*step(tf3,.8)*side;
        alb=mix(alb,vec3(.03),wG);em+=gc*wG*(.1+1.6*bmp*uDose+.4*BXKK*uDose);
        fzq=vec4(au/.05,side>.5?(tf3-.14)/.1:9.,mod(tN,5.),fpg/(hyT*.1));fzc=gc*.9;fzE=.06+1.4*bmp*uDose;
        float ring=(1.-smoothstep(.0,.04+fpg/hyT*.7,tf3))+(1.-smoothstep(.0,.04+fpg/hyT*.7,1.-tf3));
        em+=gc*clamp(ring,0.,1.)*(.18+2.4*bmp*uDose+.5*BXKK*uDose);
        if(k>7.5&&k<8.5)alb=mix(alb,vec3(.95,.72,.25),step(.7,y2));
        gl=.15;
#endif
      }else if(matT>16.5){
        // ---- the small props between the lots
        vec3 pc=mix(mix(P.ba,P.gnd,.35+.4*lq.x),P.a1,step(.86,lq.y)*.8);alb=pc*(.75+.45*lq.y);em+=P.a1*step(.86,lq.y)*(.02+hi*uDose*.9);gl=.15;
        if(lq.z>3.4&&lq.z<3.6)em+=mix(P.a2,vec3(1.,.85,.5),.5)*(.8+2.*mel*uDose+BXKK*uDose);if(lq.z>4.4)alb=mix(P.a1,P.a2,lq.y)*.9;if(lq.z>2.9&&lq.z<3.1)alb=vec3(.12,.11,.12);
      }else{
        // ---- snow forest: pine boughs under snow, log walls with a lit window, thick snow on the roof
        if(mf<1.5){float sn2=smoothstep(.12,.72,n.y+.3*fract(lq.y/max(lh.y,.01)*2.5));float ndl=mix(.5+.5*sin(atan(lq.z,lq.x)*42.+lq.y*260.),.5,smoothstep(.1,.5,fpg*80.));alb=mix(mix(vec3(.03,.13,.08),vec3(.08,.24,.13),ndl),vec3(.92,.96,1.),sn2);}
        else if(mf<2.5){float lg2=bxPulse(fv/.0105,.86,fpg/.0105);alb=mix(vec3(.2,.11,.06),vec3(.52,.3,.16)*(.8+.4*tone2(lq.y)),lg2);
          if(side>.5){vec2 cl;float cov=bxWin(fu,fv,.045,.04,.34,.48,fpg,cl);alb=mix(alb,vec3(.04),cov);em+=vec3(1.,.72,.3)*cov*(.5+2.2*mel*uDose+.6*BXKK*uDose);}}
        else{alb=mix(vec3(.3,.2,.14),vec3(.96,.98,1.),smoothstep(-.1,.5,n.y));}
      }
    }
    {float fzv=bxFz(fzq.xy,fzq.z,fzq.w);alb=mix(alb,fzc,fzv);em+=fzc*fzv*(fzE+(.7*BXHF+.7*BXEXP)*uDose*step(1e-4,fzE));}
    // ink on the box edges of the built things
    if(mf<.5&&m>.5&&m<8.5){
      vec3 mg=lh-abs(lq);float e2=mg.x+mg.y+mg.z-min(mg.x,min(mg.y,mg.z))-max(mg.x,max(mg.y,mg.z));
      inkL=max(inkL,clamp(1.-e2/(.002+fpg),0.,1.)*.75);
    }
    if(isO>.5){
      // the far boxes: ink on every cube's edges and seams, and on each top cube's walls a door lit in the colour of a world
      alb*=k>11.5&&k<12.5?vec3(.3,.55,.85):vec3(1.);
      vec3 cq=vec3(lq.x,lq.y-lh.y,lq.z),mg=lh-abs(cq);float e2=mg.x+mg.y+mg.z-min(mg.x,min(mg.y,mg.z))-max(mg.x,max(mg.y,mg.z));
      inkL=max(inkL,clamp(1.-e2/(.003+fpg*1.2),0.,1.)*.85);
      float dE=max(abs(fu)-lh.x*.22,lq.y-lh.y*.95),dor=clamp(.5-dE/(1.5*fpg),0.,1.)*side*oTop*(1.-fly)*step(.5,hc.y);
      float dfr=clamp(1.-abs(dE+lh.x*.04)/(lh.x*.03+fpg),0.,1.)*side*oTop*(1.-fly)*step(.5,hc.y);
      {float mu=xf>.5?lq.z*sign(n.x):-lq.x*sign(n.z),mk=bxMk(vec2((mu/lh.x+.6)/1.2*60.,(lq.y-lh.y*1.6)/(lh.x*.14)*7.))*side*oTop*step(fract(hc.x*13.7+hc.y*5.3),.05);
       float sv=smoothstep(.2,.5,uSecAge)*(1.-smoothstep(1.3,1.8,uSecAge))*step(.5,mod(uSection,2.));alb=mix(alb,alb*.25,mk);em+=P.a2*mk*(.1+.6*hi*uDose+2.*sv);}
      vec3 dc=mix(P.a1,P.a2,step(.5,hc.x));
      alb=mix(alb,dc*.2,dor);em+=dc*dor*(.15+1.1*bxSpec(hc.z)*uDose+.6*BXKK*uDose)+P.a2*dfr*(.1+1.2*hi*uDose+1.4*BXHF*uDose*step(.5,fract(hc.y*3.+hc.x)));
    }
    if(isP>.5&&isO<.5){
      // the door: a broad lit frame in the colour of the world inside, an emblem, trims that play the spectrum
      vec3 q=lq/BXB,aq=abs(q);float b=1.+BXTH,fpq=fpg/BXB;
      float inner=step(bxM3(aq),1.+BXTH*.5);
      {float mk=bxMk(vec2((q.z*sign(q.x)+.9)/1.8*60.,(q.y+.97)/.2*7.))*step(aq.z,aq.x)*step(b-.02,aq.x);alb=mix(alb,alb*.3,mk);em+=mix(P.a2,Nh,.5)*mk*(.05+.5*hi*uDose);}
      vec3 mg=vec3(b)-aq;float e2=mg.x+mg.y+mg.z-min(mg.x,min(mg.y,mg.z))-max(mg.x,max(mg.y,mg.z));
      em+=mix(P.a2,Nh,.4)*clamp(1.-e2/(.035+fpq),0.,1.)*(.4+1.6*BXB2.x*uDose+1.5*BXKK*uDose)*(1.-.5*calm);
      float dre=max(aq.x-BXDW,max(BXDY0-q.y,q.y-BXDY1));
      float frm=clamp(.5-(abs(dre-.075)-.04)/(2.*fpq),0.,1.)*step(b-.08,aq.z);
      alb=mix(alb,P.a1,frm);em+=mix(Nh,P.a1,.5)*frm*(.35+.8*BXB2.y*uDose);
      em+=Nh*clamp(1.-abs(dre-.02)/(.022+fpq),0.,1.)*step(b-.08,aq.z)*(.9+2.2*BXB2.y*uDose+1.6*BXKK*uDose)*(1.-.5*calm);
      alb=mix(alb,Nh*.7,inner);em+=Nh*inner*.3*BXUNF*step(lev,.5);
    }
    // the castle, the night city, the lava field and the library sat too dark in their shaded parts
    alb*=k<.5?1.22:(k<1.5?1.55:((k>10.5&&k<11.5)||(k>12.5&&k<13.5)?1.22:1.));
    if(k<.5&&m>.5)em+=vec3(1.,.72,.4)*(1.-vdn)*(1.-vdn)*2.4*hi*uDose;
    float dif=max(dot(n,L),0.)*sh;
    vec3 amb=mix(P.gnd*.9+alb*.25,P.skyT*.75+P.skyH*.45,.3+.4*n.y)+vec3(.05,.06,.12)*step(.5,P.str);
    col=alb*(mix(vec3(1.),P.skyH,.25)*dif*1.5+amb*(.5+.2*n.y)*ao)+em*lvl;
    // polished surfaces catch the sky toward grazing angles
#if HD>=1
    {vec3 rd2=reflect(rd,n),rc=bxSky(P,rd2,pxa,sd,k);
#if HD>=2
     // the reflection bounce: a separate small march through coarse columns standing in for the world (ground + each lot's box)
     if(gl>.05){
       vec3 o=hp+n*(fp*3.+.003);float rt=.012,rh=0.,rv=0.;
       for(int ri=BX0;ri<40+16*HD;ri++){
         vec3 xr=o+rd2*rt;if(max(step(1.,bxM3(abs(xr))),step(.9,rt))>.5)break;
         if(xr.y<BXG){rh=1.;break;}
         vec2 idr=floor(xr.xz/cs),cr2=(idr+.5)*cs;float hr=h21(idr+sd+3.3),Hr=bxTop(k)*.55*(.2+hr*hr*1.5)*ySc/1.3;
         float dr=hr<.2?1e3:bxBox(vec3(xr.x-cr2.x,xr.y-BXG-Hr*.5,xr.z-cr2.y),vec3(cs*.33,Hr*.5,cs*.33));
         if(dr<.0015+rt*pxa){rh=2.;rv=hr;break;}
         rt+=clamp(min(dr,xr.y-BXG+.002),.003,cs*.5);
       }
       if(rh>.5){vec3 ra=rh<1.5?P.gnd*.8:mix(P.ba,P.bb,rv)*(.6+.5*fract(rv*9.));rc=mix(ra*(.5+.7*max(L.y,0.)),P.skyH,1.-exp(-rt*1.8));}
     }
#endif
     col=mix(col,rc,gl*(.14+.8*(1.-vdn)*(1.-vdn)));}
#else
    col=mix(col,P.skyH*.9,gl*(.12+.6*(1.-vdn)*(1.-vdn)));
#endif
    // ink, glinting with the highs
    col=mix(col,mix(alb*.1+vec3(.012),mix(P.a2,vec3(1.),.4)*1.3,clamp((.6*BXB2.z+.6*BXB2.w+.5*BXEXP)*uDose*(.25+1.5*smoothstep(.75,1.,fract(dot(p,vec3(7.,11.,5.))-uTime*.9)))-.08,0.,.85)),clamp(inkL,0.,1.)*.9);
  }
  vec3 sk=bxSky(P,rd,pxa,sd,k);
  col=mix(col,sk,max(step(hit,.5),step(m,.5)*smoothstep(3.,7.,tO)));
  // depth haze in the world's own colour; the far city takes the voice's colour
  col=mix(col,mix(P.skyH,P.a1,clamp(voc*uDose*.7-.1,0.,.4))*(1.-.35*step(1e-4,tO)),min(1.-exp(-tseg*.16),mix(1.,.42,step(1e-4,tO)))*hit);
  acc+=T*col;
  // silhouette ink of the nearer surface the ray grazed
  acc*=1.-edge*.75*eW*smoothstep(1.6,.6,eT)*exp(-eT*.16);
  // more chroma, and a soft shoulder so highlights roll off instead of washing out
  acc=max(mix(vec3(dot(acc,vec3(.3,.59,.11))),acc,1.25),0.)*1.32;
  acc=acc/(1.+.22*max(acc,vec3(1.))-.22);
  float fl=max(0.,1.-uP4.y/.22);acc*=1.+.3*fl*fl*uDose;
#if HD>=2
  return max(acc,0.);
}
void realm(){
  // every sample is a full march of the nested worlds: Cinema 2, Insane 3, Extreme 4, Offline 5 per pixel
  vec2 sc=scr();vec3 sum=vec3(0.);
  for(int si=BX0;si<HD;si++){vec2 j=fract(vec2(float(si)*.7548777,float(si)*.5698403)+.5)-.5;sum+=bxRender(sc+j/uRes.y);}
  fragColor=vec4(sum/float(HD),0.);
}
#else
  fragColor=vec4(max(acc,0.),0.);
}
#endif
`;
