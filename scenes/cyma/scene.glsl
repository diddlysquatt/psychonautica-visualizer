const R_CYMA = `
// CYMA. Cymatics: sound made visible, as a temple of resonators seen from a slowly orbiting, tilting viewpoint. The
// sanctum (centre) holds the hero composition (one great plate, nested jewel plates, a carillon of bells, or a porthole
// onto a conveyor of plates), floating on its stem over an engraved floor whose grooves light with the spectrum, ringed
// by a dais that is an eight-band meter. Round it, eight rings of gongs, water bowls and liquid-metal plates (one ring
// per band: inner rings = air/highs .. outer great gongs = sub) step one slot per bar, hover and rock with their band,
// and are joined by rails carrying their band's waveform as light. On drops the rings spin like a combination lock and
// flip edge-on into a new arrangement as the front passes. Spokes carry the sub, every kick sends a sound wave out
// across the floor, and rosettes of engraved sacred geometry fill the gaps. Every plate keeps the real physics: Chladni
// eigenmodes chosen by the music with heaped, lit sand on the nodal lines, Faraday standing waves shown as chromatic
// caustics, or a mirror surface heaving through the mode's cycle.
//
// v14 (this pass). Each ring now draws its OWN band as a polar spectrum rose (petal count and depth are that band's
// pitch and level), the sanctum gets a ROSETTE layout that is such a rose for all eight bands at once, sand is beaded
// and crisp (strings of beads and crystal flecks; a sharp line where there are grains to spare), the glass shows
// drifting antipodal standing-wave nodes (R-CHLADNI Twinkle), the reseeded figure leaves a sand trail, liquid metal
// appears inside the four material sets, and a low harmonic field draws the ripple lines in from beyond the temple.
//
// v22 wave 4 (restyle, same scene). The board, its rings of plates, their figures and their motion are unchanged; what
// changed is what they are made of. The plates are sacred artifacts now: thick slabs of bronze, dark gold, lapis, jade and
// basalt floating over a floor of cut stone, each with a heavy rim carrying a band of insignia, a side wall and a cast
// shadow. The figure is carved into the slab in relief and the sound's ENERGY runs in its channels: two hue families per
// scheme (cymaPals: the energy and its accent), bright and saturated on dark material, every light soft-capped with its hue
// kept. The full-frame vibration waves are thin accents. No plate outgrows its cell (cyWorld: fit), so nothing is cut off.
vec3 cyS0,cyS1,cyS2,cyS3,cyS4;
float cyEnv,cySdl;   // cySdl: the plate outline's SDF in local units (star plates warp their modes by it)   // set by cyFig: 0 in a circular mode's evanescent core (no sand heap where the spokes converge)
vec4 cyLA,cyLB;float cyHop,cyFlash,cyFar,cyKT,cyHat,cyMo,cyGA,cyGB,cyBs,cyQ;   // v18: the bands smoothed for geometry (cyLA = sub..mid, cyLB = hi-mid..air), unpacked once per pixel
float cyFlo;         // w4: the energy flow phase (advances with the music level and every hop)
float cySr;          // v14: 0..1, how much of the current plate's shape is its band's spectrum rose
// the five palette stops are blended, hue-rotated and prepared in JS (cymaPrep), packed 8 bits per channel
vec3 cyUnpack(float v){return mod(floor(v/vec3(1.,256.,65536.)),256.)*(2./255.);}
float cyNrm(vec3 s){return sqrt(pow(min(1.,.42/max(dot(s*s,vec3(.2126,.7152,.0722)),.05)),.7));}
void cyLoad(){
  cyBs=floor(uP5.x)/1024.;cyQ=fract(uP5.x);   // v19: smoothed bass and the 'quiet passage' fill (see the entry)
  cyS0=cyUnpack(uP3.x);cyS1=cyUnpack(uP3.y);cyS2=cyUnpack(uP3.z);cyS3=cyUnpack(uP5.w);cyS4=cyUnpack(uM2[2][0]);
  vec3 f1=fract(vec3(uP1.xy,uP1.w))*256.;
  cyLA=vec4(floor(f1.x),fract(f1.x)*256.,floor(f1.y),fract(f1.y)*256.)/255.;
  vec2 a0=vec2(floor(uP2.x)/4096.,fract(uP2.x)),a1=vec2(floor(uP4.w)/4096.,fract(uP4.w)),a2=vec2(floor(uM2[1][2])/4096.,fract(uM2[1][2]));
  cyLB=vec4(floor(f1.z)/255.,fract(f1.z)*256./255.,a2.y,a0.y);
  cyHop=a0.x*4.;cyFlash=a1.x*4.;cyFar=a1.y;cyKT=a2.x*10.;
  cyHat=floor(uP2.w)/2048.;cyGA=fract(uP2.w)*12.;cyMo=floor(uP4.z)/1024.;cyGB=fract(uP4.z)*12.;
  cyFlo=uM2[2][2];
  // w4: the schemes' hues differ in luminance (a green is twice a violet): the bright ones come down, so no scheme floods
  cyS0*=cyNrm(cyS0);cyS1*=cyNrm(cyS1);cyS2*=cyNrm(cyS2);cyS3*=cyNrm(cyS3);cyS4*=cyNrm(cyS4);
}
// curated 5-stop gradient, ping-ponged so it never wraps through a muddy seam; mixed in sqrt space, returns linear
vec3 cyG(float t){
  // branchless: linear hat weights over the five stops (they sum to 1)
  float x=abs(fract(t*.5)*2.-1.)*4.;
  vec4 w=max(1.-abs(x-vec4(0,1,2,3)),0.);float w4=max(x-3.,0.);
  vec3 c=cyS0*w.x+cyS1*w.y+cyS2*w.z+cyS3*w.w+cyS4*w4;return c*c;
}
float cySdHex(vec2 p,float r){const vec3 k=vec3(-.866025404,.5,.577350269);p=abs(p);p-=2.*min(dot(k.xy,p),0.)*k.xy;p-=vec2(clamp(p.x,-k.z*r,k.z*r),r);return length(p)*sign(p.y);}
float cySdStarA(vec2 p,float r,float n,float m,float at){
  float an=PI/n,en=PI/m;vec2 acs=vec2(cos(an),sin(an)),ecs=vec2(cos(en),sin(en));
  float bn=mod(at,2.*an)-an;
  p=length(p)*vec2(cos(bn),abs(sin(bn)));p-=r*acs;p+=ecs*clamp(-dot(p,ecs),0.,r*acs.y/ecs.y);
  return length(p)*sign(p.x);
}
float cySdStar(vec2 p,float r,float n,float m){return cySdStarA(p,r,n,m,atan(p.x,p.y));}
float cySdBox(vec2 p,float b){vec2 d=abs(p)-b;return length(max(d,0.))+min(max(d.x,d.y),0.);}
// boundary of a plate shape in local units (shape "radius" 1)
float cyShapeSd(float shp,vec2 q,float th){
  if(shp<.5)return cySdBox(q,.82);
  if(shp<1.5||shp>3.5)return length(q)-1.;
  if(shp<2.5)return cySdHex(q,.866);
  return cySdStarA(q,1.,5.,2.4,1.5707963-th);
}
// amplitude-normalised Bessel J_n(x) from the WKB (Debye) phase: exact nodal circles without the 1/sqrt(x) envelope
float cyBes(float n,float x){
  x=max(x,1e-3);
  if(x>n){
    float s=sqrt(x*x-n*n),u=clamp(n/x,0.,1.);
    float ac=sqrt(1.-u)*(1.5707288+u*(-.2121144+u*(.074261-.0187293*u)));   // acos (Abramowitz-Stegun)
    return cos(s-n*ac-.7854);
  }
  float u=n-x;return .7071*exp(-u*u*1.5/max(n,1.));                 // evanescent tail (sand is suppressed there anyway)
}
// circular plate mode with n nodal diameters and m nodal circles inside radius 1
float cyCirc(float th,float r,float n,float m,float ph){
  float be=(m+n*.5+.25)*PI+.45;
  cyEnv=min(cyEnv,smoothstep(n*.55,n*.9+.6,be*r));
  return cyBes(n,be*r)*cos(n*th+ph);
}
float cyHash(float a,float b){return fract(sin(a*12.9898+b*78.233)*43758.5453);}
// w4: the artifacts' materials (linear albedo): bronze, dark gold, lapis, jade, basalt
vec3 cyMatC(float i){i=mod(floor(i+.01),5.);return i<.5?vec3(.36,.18,.07):i<1.5?vec3(.47,.31,.08):i<2.5?vec3(.05,.13,.4):i<3.5?vec3(.05,.28,.17):vec3(.17,.155,.19);}
// w4: one carved insignia in a square cell (g in -1..1, y up): distance to its strokes. Eight sacred forms drawn with rings,
// arcs, loops and serifed stems: sol, luna, venus, mercury, sulphur, ankh, the algiz rune, the vesica eye
float cySeg(vec2 p,vec2 a,vec2 b){vec2 pa=p-a,ba=b-a;return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.,1.));}
float cyGlyph(vec2 g,float t){
  float ax=abs(g.x);
  float stem=min(min(cySeg(g,vec2(0,.02),vec2(0,-.86)),cySeg(g,vec2(-.34,-.5),vec2(.34,-.5))),cySeg(g,vec2(-.17,-.86),vec2(.17,-.86)));
  float d;
  if(t<1.)d=min(abs(length(g)-.66),max(length(g)-.15,0.));
  else if(t<2.)d=max(max(length(g)-.7,.52-length(g-vec2(.34,.16))),0.)*.8;
  else if(t<3.)d=min(abs(length(g-vec2(0,.36))-.36),stem);
  else if(t<4.)d=min(min(abs(length(g-vec2(0,.24))-.3),stem),max(abs(length(g-vec2(0,.86))-.3),g.y-.86));
  else if(t<5.)d=min(abs(max(ax*.866+(g.y-.3)*.5,-(g.y-.3))-.25),stem);
  else if(t<6.)d=min(min(abs(length((g-vec2(0,.46))*vec2(1.45,1.))-.36)*.75,cySeg(g,vec2(-.58,.06),vec2(.58,.06))),min(cySeg(g,vec2(0,.06),vec2(0,-.86)),cySeg(g,vec2(-.2,-.86),vec2(.2,-.86))));
  else if(t<7.)d=min(min(cySeg(g,vec2(0,-.86),vec2(0,.86)),cySeg(vec2(ax,g.y),vec2(0,.06),vec2(.56,.76))),min(cySeg(g,vec2(-.2,-.86),vec2(.2,-.86)),cySeg(vec2(ax,g.y),vec2(.42,.86),vec2(.7,.66))));
  else d=min(abs(max(length(g-vec2(0,-.5)),length(g+vec2(0,-.5)))-.86),max(length(g)-.15,0.));
  return max(d,0.);
}
// w4: the maker's hallmark, cut into the stone: p.x 0..60 (ten cells of 6), p.y 0..7; 1 on a stroke
float cyMkr(vec2 p){
  if(p.x<0.||p.x>=60.||p.y<0.||p.y>=7.)return 0.;
  const ivec2 G[8]=ivec2[8](ivec2(508430,1086),ivec2(1020036,4228),ivec2(476721,17966),ivec2(583347,17969),
                            ivec2(1032734,16927),ivec2(1001009,17982),ivec2(476735,17969),ivec2(1001022,16912));
  const int W[10]=int[10](0,1,2,3,4,5,-1,6,7,4);
  int ci=int(p.x/6.),cx=int(p.x)-ci*6,g=W[ci];
  if(g<0||cx>4)return 0.;
  int r=6-int(p.y),bits=r<4?(G[g].x>>((3-r)*5))&31:(G[g].y>>((6-r)*5))&31;
  return float((bits>>(4-cx))&1);
}
// v14: one band drawn as a polar spectrum rose: petals = the band's pitch (1..8), the flower's size = how loud the band
// is (with its onset), so low bands are solid flowers and high bands fine sunbursts. The rose fades to zero at the plate
// rim through the plate's outline distance sd, so the plate keeps its silhouette. D = (petals, rotation, depth, unused);
// returns the displacement and its wavenumber, capped by km against pixel footprint.
float cyRose(vec2 q,float th,float sd,vec3 D,float rkm,float km,float spPx,out float kap){
  float R0=.86,np=floor(D.x+.5),RL=3.4+2.1*D.x;
  float f=sin(RL*length(q)-np*th-D.y);
  float u=min(sd,R0-length(q));
  float w=smoothstep(R0-.34,R0-.1,length(q))*(.5+.5*smoothstep(-.16,.04,u));
  kap=RL;
  return f*w*mix(.55,1.,clamp(D.z,0.,1.))*mix(.24,1.,clamp(rkm,0.,1.))*mix(.35,1.,smoothstep(1.6,5.,spPx))*(1.+1.4*smoothstep(14.,30.,spPx));
}
// one figure: code = mode*8 + variant; returns the plate displacement (about -1..1) and the local wavenumber
float cyFig(float shp,vec2 q,float th,float code,float sd,float ko,float km,float sc,out float kap){
  float k=floor(code/8.+.01),v=code-8.*k;
  cyEnv=1.;
  // the plate's nodal count rises with zoomed-in size (cz grows by log2 of the plate size in local units)
  k=clamp(k+ko+(sc<.6?floor((.6-sc)*6.):0.),1.,shp>2.5?km*mix(.4,.75,smoothstep(.3,1.,sc)):km);
  float hv=cyHash(v+1.,sd+3.1),mo=cyMo*sin(uP4.y+sd*2.3+v);   // mids morph the superposition weights
  if(shp<.5){
    // square plate (free edges): cos(n x)cos(m y) +- cos(m x)cos(n y); the mids slide the +- weight
    float s=k+2.,n0=s>4.5?1.:0.,n=n0+floor(hv*(floor((s+1.)*.5)-n0)),m=s-n;
    vec2 u=(q*1.2195+1.)*.5*PI;
    float sg=(mod(v,2.)<.5?1.:-1.)*cos(mo*1.2);
    kap=m*PI*.6;
    return .5*(cos(n*u.x)*cos(m*u.y)+sg*cos(m*u.x)*cos(n*u.y));
  }
  if(shp>3.5){
    float r=length(q),r0=.68;
    float n=6.+2.*floor(hv*(k*.7+2.)),m=1.+floor(fract(hv*7.3)*min(k*.25+1.,4.));
    float u=clamp((r-r0)/(1.-r0),0.,1.)*PI;
    float w2=.7*cos(mo);
    kap=max(n,m*PI/(1.-r0));
    return .6*(cos(n*th)*cos(m*u)+w2*cos((n+(mod(v,2.)<.5?2.:4.))*th+v)*cos((m+1.)*u));
  }
  if(shp<1.5||shp>2.5){
    float r=length(q),P=1.;
    if(shp>2.5){r=r/max(r-cySdl,.05);P=5.;}
    float n=P>1.?P*floor(hv*(min(k,20.)*.25+1.)+.5):(k>3.?1.:0.)+floor(hv*(min(k,13.)+.5)*.62),m=max(0.,floor((k+1.-n/P*(P>1.?2.5:1.))*.5+.5));
    if(n+m<.5)m=1.;
    // degenerate partner mode: turns rings and spokes into the curly classic circular figures
    float w2=(mod(v,3.)<.5&&P<1.5?0.:.75)*cos(mo);
    float n2=n+P*(mod(v,2.)<.5?1.:2.),m2=max(0.,m-1.);
    float f=0.;
    for(int j=0;j<2;j++){
      bool b=j==1;
      f+=(b?w2:1.)*cyCirc(th,r,b?n2:n,b?m2:m,b?v:0.);
    }
    f/=1.+abs(w2)*.6;
    kap=(m+n*.5+1.)*PI;
    return f;
  }
  // hexagonal plate: standing plane waves on two shells of the hexagonal lattice
  float K=PI*(.9+.42*k),s2=mod(v,4.),R2=s2<1.5?1.7320508:(s2<2.5?2.:3.);
  float a2=s2<1.5||s2>2.5?.5236:0.;
  float f=0.;
  for(int j=0;j<3;j++){
    float a=1.5708+float(j)*2.0944;
    f+=cos(K*dot(q,vec2(cos(a),sin(a))));
    float b=a+a2;
    f+=(.8*cos(mo))*(mod(v,2.)<.5?1.:-1.)*cos(K*R2*dot(q,vec2(cos(b),sin(b))));
  }
  kap=K*R2*.75;
  return f*.3;
}
// Faraday water: a quasi-crystal of N standing plane waves (2N-fold) plus the bowl's ring wave; height, gradient, Hessian
void cyWave(vec2 q,float code,float sd,float ko,float km,float w,inout float h,inout vec2 g,inout vec3 H,inout float kap){
  float k=floor(code/8.+.01),v=code-8.*k;
  k=clamp(k+ko,min(4.,km),km);
  float N=min(3.+floor(k*.3+cyHash(v,sd)*1.6),9.),K=6.+2.4*k,ra=v*.4+uP5.z*.4;
  float wn=w/(N+1.2);
  vec2 e=vec2(cos(ra),sin(ra));mat2 Rj=rot(-PI/N);
  for(int j=0;j<9;j++){
    if(float(j)>=N)break;
    if(j>0)e=Rj*e;
    float ph=K*dot(e,q),c=cos(ph),s=sin(ph);
    h+=wn*c;g-=wn*K*s*e;H-=wn*K*K*c*vec3(e.x*e.x,e.y*e.y,e.x*e.y);
  }
  // ring wave from the rim
  float r=max(length(q),1e-3),wr=wn*(mod(v,2.)<.5?1.:.45)*smoothstep(.05,.4,r);vec2 er=q/r;   // no singular focus at the centre
  float c=cos(K*r),s=sin(K*r);
  h+=wr*c;g-=wr*K*s*er;
  float d2=-wr*K*K*c,d1=-wr*K*s/r;   // Hessian of f(r): f'' e e^T + f'/r (I - e e^T)
  H+=vec3(d2*er.x*er.x+d1*(1.-er.x*er.x),d2*er.y*er.y+d1*(1.-er.y*er.y),(d2-d1)*er.x*er.y);
  kap=max(kap,K);
}
// band state: mode codes (A*1024+B) and transition progress per band (0..5 spectrum bands, 6 = dominant pitch)
float cyAB(float b){return b<.5?uM1[0][0]:b<1.5?uM1[0][1]:b<2.5?uM1[0][2]:b<3.5?uM1[1][0]:b<4.5?uM1[1][1]:b<5.5?uM1[1][2]:uM1[2][0];}
// two 0..1 values packed in one float by JS (12-bit integer part + fraction)
vec2 cyUp(float v){return vec2(floor(v)/4096.,fract(v));}
float cyTau(float b){vec2 t=cyUp(b<1.5?uM1[2][1]:b<3.5?uM1[2][2]:b<5.5?uM2[0][0]:uM2[0][1]);return b>5.5?t.x:mod(b,2.)<.5?t.x:t.y;}
float cyBandSpec(float b){float x=.05+b*.145;return (spec(x)+spec(x+.05)+spec(x+.1))/3.;}
// the plate's hue: the eight bands' curated hues interpolated (JS keeps the same list in cymaHue)
float cyHueT(float b){
  // teal, cyan, blue, violet, magenta, orange, gold, green
  vec4 h0=vec4(.46,.53,.66,.78),h1=vec4(.9,1.07,1.14,1.34);
  float i=clamp(floor(b),0.,6.),u=clamp(b-i,0.,1.);
  vec4 s=vec4(equal(vec4(mod(i,4.)),vec4(0,1,2,3))),t=vec4(equal(vec4(mod(i+1.,4.)),vec4(0,1,2,3)));
  float hA=dot(i<3.5?h0:h1,s),hB=dot(i+1.<3.5?h0:h1,t);
  return hA+(hB-hA)*u;
}
// a hue as RGB whose largest channel is 1, so it can be used as a grey level and keep its saturation
vec3 cyHueC(float h){return clamp(abs(fract(h+vec3(0.,.6666667,.3333333))*6.-3.)-1.,0.,1.);}
vec3 cyHue8(float b){return cyHueC(cyHueT(b));}
// v14: the eight bands' relative (share-weighted) levels, from the fractions of uB1/uB2 (see cymaContrast)
float cySm(float b){b=clamp(floor(b+.5),0.,7.);vec4 e=vec4(equal(vec4(mod(b,4.)),vec4(0,1,2,3)));return dot(b<3.5?cyLA:cyLB,e);}
float cyRel8(float b){
  float mx=max(max(cyLA.x,cyLA.y),max(max(cyLA.z,cyLA.w),max(max(cyLB.x,cyLB.y),max(cyLB.z,cyLB.w))));
  return clamp((cySm(b)-.5*mx)*1.8,0.,1.)*smoothstep(.12,.42,dot(cyLA+cyLB,vec4(.125)));
}
#if HD>=5
#define CYSS 4.
#elif HD>=4
#define CYSS 3.
#elif HD>=3
#define CYSS 2.
#elif HD>=2
#define CYSS 1.5
#elif HD>=1
#define CYSS 1.
#endif
#if HD>=1
// ---- v19 detail range. Everything below exists only at Native and above. Loops start at a zero the compiler cannot fold.
// One order of fine filigree: the nodal lines of a pair of high plate modes, with the exact gradient, so the line width
// is true in pixels. Square and hex plates use the Chladni square-mode pair, round and star plates the curly circular pair.
float cyFil(vec2 q,float r,float th,float shp,float n,float m,float v,float ppx){
  float g0,gx,gy;
  if(shp<.5||(shp>1.5&&shp<2.5)){
    float c0=cos(v),s0=sin(v),S=1.571;vec2 u=vec2(c0*q.x+s0*q.y,c0*q.y-s0*q.x)*S;
    float a1=n*u.x,a2=m*u.y,a3=m*u.x,a4=n*u.y,cA=cos(a1),sA=sin(a1),cB=cos(a2),sB=sin(a2),cC=cos(a3),sC=sin(a3),cD=cos(a4),sD=sin(a4);
    g0=cA*cB-cC*cD;gx=(-n*sA*cB+m*sC*cD)*S;gy=(-m*cA*sB+n*cC*sD)*S;
  }else{
    float R0=max(r,.003),n2=n+2.,k=m*PI,k2=(m+1.)*PI;
    float ca=cos(n*th+v),sa=sin(n*th+v),cr=cos(k*R0),sr=sin(k*R0),ca2=cos(n2*th-v),sa2=sin(n2*th-v),cr2=cos(k2*R0),sr2=sin(k2*R0);
    g0=ca*cr+.7*ca2*cr2;gx=-k*ca*sr-.7*k2*ca2*sr2;gy=(-n*sa*cr-.7*n2*sa2*cr2)/R0;
  }
  float d=abs(g0)/(length(vec2(gx,gy))+1e-4)*ppx;
  return exp(-d*d*1.1);
}
// one layer of crystal sand: four cells, grains showing where the figure's density reaches them
float cyGrL(vec2 q,float G3,float px,float D,float sd){
  vec2 gq=q/G3,gi=floor(gq-.5);float wg=px/G3,cov=0.;
  for(int j=0;j<4;j++){
    vec2 id=gi+vec2(float(j&1),float(j>>1));
    float h1=h21(id+sd),h2=fract(h1*137.13+.3),h3=fract(h1*251.7+.7);
    vec2 c=id+.5+(vec2(h1,h2)-.5)*.6;
    float rg=.2+.2*h3,a=smoothstep(rg+wg*.6,rg-wg*.6,length(gq-c));
    float th2=.06+.88*fract(h1*71.31+.1);
    cov=max(cov,a*smoothstep(th2-.1,th2+.1,D)*(.55+.75*h3));
  }
  return cov;
}
#endif
// v20b: a ring's place in the palette: even rings sit at one end (stops 0-1), odd rings at the other (stops 3-4)
float cyHbZ(float z){return (mod(z,2.)<.5?.5:1.5)+.05*sin(z*2.4);}
#if HD>=1
// what a plate reflects: the temple floor's glass tiles under it (palette only, no music, so a mirror bounce stays cheap)
vec3 cyFlr(vec2 p,float px){
  float r=max(length(p),.02),th=atan(p.y,p.x),lr=log(r),tN=84.,tv=lr*tN/TAU;
  vec2 tu=vec2(tv,th*tN/TAU+mod(floor(tv),2.)*.5),ti=floor(tu),tf=fract(tu)-.5;
  float tsz=r*TAU/tN/px,hT=h21(vec2(ti.x,mod(ti.y,tN))),e=max(abs(tf.x),abs(tf.y));
  vec3 tc=vec3(.2,.19,.22)+cyS1*cyS1*.5*step(.72,fract(hT*7.13));
  return tc*(.2+.8*hT*hT)*mix(.65,1.,smoothstep(.5,.5-min(1.5/tsz,.3),e));
}
#endif
// ---- the temple. Plates (hero composition in the sanctum, rings of gongs and bowls outside) share one record
struct CyP{vec4 Z;vec2 q,c,sh;float sc,shp,band,bd,id,dim,ang,kx,lv,on,zone,sl,wat,rr,ra,rn,us,fl;};
CyP cyMk(vec2 p,vec2 c,float sc,float ang,float shp,float band,float id){
  CyP P;P.q=rot(ang)*(p-c)/sc;P.c=c;P.sc=sc;P.shp=shp;P.band=band;P.id=id;P.dim=1.;P.ang=ang;P.kx=0.;P.bd=-1.;
  P.lv=0.;P.on=0.;P.zone=-1.;P.sl=0.;P.wat=0.;P.rr=0.;P.ra=0.;P.rn=1.;P.us=1.;P.fl=0.;P.sh=vec2(0);P.Z=vec4(1);return P;
}
const float CYZ0=2.5;     // default framing: the sanctum plus the first rings of resonators round it
// eight rings ("zones") at geometric radii 1.35*1.5^k, in four arrangements (a drop or a phrase flips the rings from
// one into another): plates per row, plate radius, rows, row spacing
vec4 cyZone(float k,float a){
  mat4 M=k<.5?mat4(16,.25,1,0, 12,.27,1,0, 24,.12,2,.24, 16,.19,1,0)
    :k<1.5?mat4(18,.27,1,0, 12,.34,1,0, 36,.13,2,.32, 24,.15,2,.38)
    :k<2.5?mat4(24,.3,1,0, 16,.48,1,0, 48,.15,3,.34, 24,.3,1,0)
    :k<3.5?mat4(36,.26,2,.62, 24,.5,1,0, 72,.16,3,.5, 36,.26,2,.62)
    :k<4.5?mat4(36,.42,1,0, 24,.8,1,0, 72,.24,3,.7, 36,.42,1,0)
    :k<5.5?mat4(72,.3,3,.75, 48,.55,2,1.25, 144,.18,4,.6, 72,.3,3,.75)
    :k<6.5?mat4(96,.36,2,1.1, 64,.6,1,0, 144,.28,3,.8, 96,.32,2,1.)
    :mat4(144,.38,3,1.3, 96,.62,2,1.5, 216,.3,4,1., 144,.36,3,1.3);
  return M*vec4(equal(vec4(a),vec4(0,1,2,3)));
}
float cyZR(float k){return 1.35*pow(1.5,k);}
// v14: the eight bands' spectrum-rose codes, 8*petals + rotation out of 80 (see cymaRoses). The upper bands' onsets
// are unused in CYMA, so the four low bands' codes ride there outright; the rest ride in transition fractions.
// level and onset of any of the eight bands (0 = sub .. 7 = air)
// each ring listens to one of the eight bands: innermost = air .. outermost great gongs = sub
// (level, onset) of ring k's band
vec2 cyZB(float k){vec4 m=vec4(equal(vec4(3.-mod(k,4.)),vec4(0,1,2,3)));return k<3.5?vec2(dot(uB2,m),dot(uO2,m)):vec2(dot(uB1,m),dot(uO1,m));}
float cyTrackHalf(vec4 Z){return (Z.z-1.)*.5*Z.w+Z.y*1.35;}
// material of a plate: 0 sand, 1 water, 2 liquid metal (par = 0/1 alternates)
float cyMat(float m,float par){return m<.5?0.:m<1.5?1.:m<2.5?par:m<3.5?2.*par:2.-par;}
// v14: the two roles inside a material set: sand and water are the pair, but the rare role (water / metal) goes to the
// inner plates or, on alternate cycles of the scene counter, to the outer ones, so metal shows without a new material
float cyRare(float wat,float par){return floor(uVar.y*40.)+floor(uVar.w*40.)<1.0?wat:2.-wat;}
// ---- sanctum layouts (radius < 1.04). 0 SOLO: one great plate. 1 JEWEL: nested plates (rim = bass, core =
// treble) in a bass pond. 2 CARILLON: five bells from bass to treble over a bass plate. 3 PORTHOLE: a window into
// the machine, columns = bands scrolling up / down a plate per bar. 4 ROSETTE (v14): eight petals round a core, the
// k-th drawing band 7-k: all eight spectra as one mandala of flowers.
CyP cyLayout(float L,vec2 p){
  float lay=mod(L,10.),sv=floor(L/10.+.01),rp=uP5.z;
  vec2 c=vec2(0);float sc=1.,ang=0.,shp=0.,band=6.,id=0.,ex=-1e3,useS=1.,dim=1.,kx=0.;
  if(lay<.5){
    shp=mod(sv,4.);sc=shp<.5?.8:(shp<2.5?.9:.93);ang=rp*.15;
  }else if(lay<1.5){
    float g=.026,r=length(p);
    float s0=cySdStar(rot(-rp*.9)*p/.1,1.,5.,2.4)*.1;
    float c1=r-.165;
    float a2=.7854+rp*.4,s2=cySdBox(rot(a2)*p,.215);
    float a3=-rp*.3+mod(sv,2.)*.5236,s3=cySdHex(rot(a3)*p,.345);
    float c4=r-.485;
    useS=0.;
    if(s0<g*.5){sc=.1;ang=-rp*.9;shp=3.;band=5.;id=1.;ex=s0;}
    else if(c1<g*.5){sc=.165;ang=rp*.6;shp=1.;band=4.;id=2.;ex=max(c1,g-s0);}
    else if(s2<g*.5){sc=.215/.82;ang=a2;shp=0.;band=3.;id=3.;ex=max(s2,g-c1);}
    else if(s3<g*.5){sc=.345/.866;ang=a3;shp=2.;band=2.;id=4.;ex=max(s3,g-s2);}
    else if(c4<g*.5){sc=.485;ang=rp*.2;shp=4.;band=1.;id=5.;ex=max(c4,g-s3);}
    else{sc=.93;ang=rp*.1;shp=mod(sv,4.)<2.?1.:2.;band=0.;id=6.;ex=g-c4;dim=.75;kx=6.;useS=1.;}
  }else if(lay<2.5){
    float best=1e3,bi=0.,x=-.86,bR=1.;vec2 bc=vec2(0);
    for(int i=0;i<5;i++){
      float fi=float(i),R=.205-.026*fi;
      x+=R;
      vec2 cc=vec2(x,.06*cos(fi*.9-.6)-.03+.018*sin(uP4.x*1.5707963+fi*1.3));
      float d=length(p-cc)-R;
      if(d<best){best=d;bi=fi;bc=cc;bR=R;}
      x+=R+.05;
    }
    shp=mod(sv+bi,4.);c=bc;sc=bR/(shp<.5?.82:1.);ang=(mod(bi,2.)<.5?1.:-1.)*rp*.5;band=bi+1.;id=bi+1.;
  }else if(lay<3.5){
    float ts=.3,cx=clamp(floor((p.x+.9)/ts),0.,5.);
    float dir=mod(cx,2.)<.5?1.:-1.;
    float y=p.y/ts+dir*uP5.y+.5,row=floor(y);
    c=vec2((cx+.5)*ts-.9,(row+.5-dir*uP5.y-.5)*ts);
    shp=mod(sv+mod(row+cx,2.)*(mod(sv,3.)+1.),4.);
    sc=ts*.4/(shp<.5?.82:1.)*max(smoothstep(.97,.85,length(c)+ts*.4),.004);band=cx;id=10.+cx*7.+mod(row,61.)*3.;ex=length(p)-.94;   // w4: a plate shrinks away as it nears the window edge, never cut by it
  }else{
    // ROSETTE: the sanctum is the spectrum itself. Eight wedges, one per band (the k-th clockwise from up is band k),
    // each a plate at a radius that breathes with its band; every plate draws ITS band as the spectrum rose (petals =
    // that band's pitch, size = its level and onsets), so all eight ranges are legible as eight different flowers.
    float a=atan(p.y,p.x)+rp*.2;
    float pk=TAU*.125,ia=floor(a/pk+.5),aa=ia*pk;
    float kb=ia-8.*floor(ia*.125);
    float relk=.05+.2*cyRel8(kb);
    float ac=abs(a-aa),rad=length(p);
    vec2 cw=vec2(cos(aa-rp*.2),sin(aa-rp*.2))*.63;   // w4 fix: the petal sits in the middle of its (turning) wedge; it used to slide out and be cut in half
    float dcw=length(p-cw)-.21,dc=rad-.32;
    if(dcw<.0){c=cw;sc=.21;shp=1.;band=kb;id=20.+kb;ex=dcw;ang=aa-rp*.2;useS=1.0;dim=.8+.5*relk;}
    else if(dc<0.){c=vec2(0.,0.);sc=.32;shp=mod(sv+1.0,4.0);band=6.;id=8.;ex=dc;}
    else{shp=1.;c=vec2(0.,0.);sc=.93;ang=rp*.08;band=0.;id=9.;ex=max(rad-.93,-min(dcw,dc));useS=0.;dim=.72;kx=4.;}
  }
  // (the plate outline itself is evaluated once, in realm())
  float hr=lay>1.5&&lay<2.5?length(p-c)-sc*(shp<.5?1.16:1.)-.022:-1.;
  if(hr>0.){
    // between the bells: the big bass plate underneath, with a round mount cut round every bell
    shp=1.;c=vec2(0);sc=.93;ang=uP5.z*.05;band=0.;id=7.;ex=max(-hr,length(p)-.93);useS=0.;dim=.75;kx=3.;
  }
  CyP P=cyMk(p,c,sc,ang,shp,band,id);
  P.bd=ex;P.us=useS;P.dim=dim;P.kx=kx;
  return P;
}
// ---- the rings of resonators round the sanctum: every ring steps one slot per bar (alternate directions), its
// plates face the centre, hover on drive stems (higher with their band), rock like struck coins, and flip edge-on
// into a new arrangement when a drop's front passes over them
CyP cyWorld(vec2 p,float r,float th,float sv,vec2 mats,vec2 wvs,float wr,vec2 lift){
  float k=clamp(floor(log(r)*2.4663-.7402+.5),0.,7.),R=cyZR(k);
  float pr=uP1.z<.999?clamp((wr-R)/(.3*R+.2)+.5,0.,1.):1.,nn=step(.5,pr);
  vec4 Z=cyZone(k,floor(mix(wvs.x,wvs.y,nn)/4.));
  float Rc=k<.5?1.378:R*1.0206;   // w4: the rows sit in the middle of the zone's annulus (the zone edges are geometric means)
  float j=clamp(floor((r-Rc)/max(Z.w,1e-3)+(Z.z-1.)*.5+.5),0.,Z.z-1.);
  float Rj=Rc+(j-(Z.z-1.)*.5)*Z.w;
  float kp=mod(k,2.),dir=1.-2.*kp,sa=TAU/Z.x;
  float ra=dir*(uP5.y*sa+uM2[2][1]*.06/(1.+k))+mod(j,2.)*.5*sa;
  float s=floor((th-ra)/sa+.5),a=s*sa+ra,sN=mod(s,Z.x);
  vec2 zb=cyZB(k);float lv=zb.x,m=mix(mats.x,mats.y,nn),wat=cyMat(m<.5?2.:m,(m>1.5&&m<2.5)||m>3.5?mod(sN+j,2.):kp);
  wat=cyRare(wat,(m>1.5&&m<2.5)||m>3.5?mod(sN+j,2.):kp);
  float shp=wat>.5&&wat<1.5?1.:mod(sv+k+j+mod(sN,2.)*kp,4.);
  float lS=cySm(7.-k),ks=mod(cyKT,10.),bump=exp(-abs(Rj-1.04-ks*(5.5+.3*Rj))/(.3+.1*Rj))*exp(-ks*1.3)*smoothstep(0.,.07,ks);
  // w4 fit: the room a plate has in its cell (to its neighbours round the ring, to the next row, to the edge of its zone). The
  // slab floats up to .3 of its radius above the floor, which shows as a shift of that much times the view's tilt, so the
  // largest radius that can never touch the cell edge is fit; a plate rests a little smaller and grows into it with its band
  float rIn=j<.5?Rj-max(R*.8165,1.1):Z.w*.5,rOut=j>Z.z-1.5?R*1.2247-Rj:Z.w*.5;
  float fit=min(PI*Rj/Z.x,min(rIn,rOut))/(1.+.3*length(lift))*.97,sc0=min(Z.y,fit*.8);
  float grow=min(.3*lS+.26*bump,fit/sc0-1.);
  vec2 sh=-lift*sc0*(.1+.12*lS+.08*bump);   // parallax: the slab hovers above its shadow
  CyP P=cyMk(p+sh,Rj*vec2(cos(a),sin(a)),sc0*(1.+grow),-a,shp,(7.-k)*.72,300.+k*97.+sN+j*41.);
  // the plate rocks like a struck coin: foreshortened along a slowly turning axis, deeper with its band
  float tp=uTime*1.3+sN*2.4+k,tl=(.06+.22*lS)*(.6+.4*sin(tp*.7));
  vec2 td=vec2(cos(tp),sin(tp));
  P.q+=tl*dot(P.q,td)*td;
  // the flip: the ring's plates turn edge-on as the front passes and come back in the new arrangement
  float fs=abs(cos(PI*pr));P.q.y/=max(fs,.03);P.fl=sin(PI*pr);
  P.bd=-1e3;P.sh=sh;P.Z=Z;
  P.lv=lv;P.on=zb.y;P.zone=k;P.sl=sN+j*.37;P.wat=wat;P.rr=Rj;P.ra=ra;P.rn=Z.x;P.dim=1.;
  return P;
}
#if HD>=1
// v19: what the polished floor shows of the plate hovering over point p (colour, coverage), a light copy of the plate shader
vec4 cyMirS(vec2 p,float px,float sv,vec2 mats,vec2 wvs,float wr,vec2 lift){
  float r=length(p);
  if(r<1.1)return vec4(0.);
  CyP P=cyWorld(p,r,atan(p.y,p.x),sv,mats,wvs,wr,lift);
  float rq=length(P.q),ang=atan(P.q.y,P.q.x);
  cySdl=cyShapeSd(P.shp,P.q,ang);
  if(cySdl*P.sc>0.)return vec4(0.);
  float AB=cyAB(floor(P.band+.5)),cB=AB-1024.*floor(AB/1024.+.0001),kap=1.;
  float f=cyFig(P.shp,P.q,ang,cB,P.id,0.,max(2.,floor(P.sc/px/7.5)-1.),P.sc,kap);
  float hb=cyHbZ(P.zone),line=smoothstep(.16,.0,abs(f));
  vec3 c=cyMatC(P.zone*3.)*(.3+.3*max(f,0.))+(mod(P.zone,2.)<.5?cyS1*cyS1:cyS3*cyS3)*line*(.3+.8*P.lv+.8*P.on);
  return vec4(c,1.);
}
#endif
void realm(){
  cyLoad();
  vec2 s0=scr();
  // camera: the temple floor seen from a tilting, slowly orbiting viewpoint (straight down .. ~36 degrees off)
  float cw=uP3.w,E=1.5708-.62*floor(cw)*.001,se=sin(E),ce=cos(E),caz=fract(cw)*TAU;
  float w=max(se-s0.y*ce*.8,.2),zs=CYZ0/uZoom;
  mat2 cR=rot(caz);
  vec2 p=cR*(vec2(s0.x*se,s0.y)/w)*zs;
  // kaleidoscope: the view glides off-centre through the rings (JS eases the fold strength in), so every fold sweeps
  // across plates, rails and travelling waves instead of mirroring the round sanctum onto itself
  float fsk=cyUp(uM2[0][1]).y;
  p+=fsk*vec2(cos(uTime*.043),sin(uTime*.031))*(1.9+.8*sin(uTime*.017));
  float px=zs/uRes.y*se/(w*sqrt(w));
#if HD>=1
  float spx=px*CYSS;   // the footprint of one displayed pixel: Cinema and up render more pixels than they show
#endif
  vec2 lift=cR*vec2(0,ce/se);   // a raised point shows over the floor point this far "up" the view
  float r=length(p),th=atan(p.y,p.x);
  // drop / phrase transition: an iris front runs out from the centre; inside it the new layout and world. The rings
  // flip as it passes; in flip mode the sanctum plate itself turns over like a coin
  float wr=uP1.z*2.4*CYZ0/min(uZoom,1.),dw=r-wr;bool nw=uP1.z<.999&&dw<0.;
  float mp=mod(floor(uP1.w),64.),tt=floor(uP1.w/64.+.01);
  vec2 mats=vec2(mod(mp,8.),floor(mp/8.+.01));
  float wvc=floor(uP2.z/1000.);vec2 wvs=vec2(mod(wvc,16.),floor(wvc/16.+.01));
  float wv=mod(nw?wvs.y:wvs.x,4.);   // spoke count and spiral twist
  float ps=uP1.z<.999?clamp(uP1.z*2.5,0.,1.):1.;
  bool hn=tt>.5?ps>.5:nw;
  float L=floor(hn?uP1.y:uP1.x);
  CyP P;
  bool hero=r<1.04;
  vec2 po=p;
  if(hero){
    // the sanctum plate floats on its stem and rocks slowly with the bass
    vec2 sh=-lift*(.05+.06*cyBs);
    float ta=uTime*.31,fsH=tt>.5?abs(cos(PI*ps)):1.;vec2 td=vec2(cos(ta),sin(ta));
    po=p+sh;po+=(1./max(fsH,.03)-1.+(.03+.08*cyBs)*(.6+.4*sin(uTime*.83)))*dot(po,td)*td;
    po*=1.+.07*(1.-cyLA.y)+.04*(1.-cyLA.x);
    P=cyLayout(L,po);P.sh=sh;
    float m=hn?mats.y:mats.x;P.wat=cyMat(m,mod(P.id+1.,2.));
    if(mod(L,10.)>.5)P.wat=cyRare(P.wat,mod(P.id+1.,2.));
    float bs=cyBandSpec(min(P.band,5.));P.lv=P.band>5.5?uLevel:bs;P.on=mix(uO1.y,uO2.y,clamp(P.band*.2,0.,1.));
  }else{P=cyWorld(p,r,th,floor(L/10.+.01),mats,wvs,wr,lift);po=p+P.sh;}
  float ang=atan(P.q.y,P.q.x);
  cySdl=cyShapeSd(P.shp,P.q,ang);
  P.bd=P.us>.5?max(cySdl*P.sc,P.bd):P.bd;
  bool water=P.wat>.5&&P.wat<1.5;
  float AB=cyAB(floor(P.band+.5)),tau=clamp(cyTau(floor(P.band+.5)),0.,1.);
  float cA=floor(AB/1024.+.0001),cB=AB-1024.*cA;
  if(!hero){
    // a ring re-figures as a wave running round it; neighbours sing different variants of the same mode
    tau=clamp(tau*1.8-.8*fract(P.sl/P.rn+.13*P.zone),0.,1.);
  }
  float hb=hero?.5+.015*P.band:cyHbZ(P.zone);   // v20b: plates alternate between the two ends of the palette
  float f=0.,kap=1.;cyEnv=1.;
  float ko=floor(max(0.,log2(P.sc/.11))*2.2)+P.kx,km=max(2.,floor(P.sc/px/7.5)-1.);
  float wh=0.;vec2 wg=vec2(0);vec3 wH=vec3(0);
  float hop=cyHop,cc=0.;vec3 dt3=vec3(1);float sdV=0.;
  float rq=length(P.q),fr=tau*1.6,code=rq<fr?cB:cA;
  float near=exp(-pow((rq-fr)*P.sc/.028,2.))*(1.-smoothstep(.8,1.,tau));
  // v14: does this plate draw its own band as a spectrum rose? A ring plate does (ring k draws band 7-k, with that
  // band's pitch, level and onset), and so does each ROSETTE petal; the rose fades in with the re-figure front so it
  // never pops. Petal rotation and depth come straight from the bar stream.
  cySr=step(1.05,P.band)*P.us*clamp(tau*2.2,0.,1.);
  // v18: the petal count follows the plate's mode code, so a rose re-draws itself behind the same re-figure front
  float rl0=P.zone<-.5?cySm(P.band):cySm(7.-P.zone);
  vec3 rD=vec3(2.+mod(floor(code/8.+.01),6.),uTime*(.3+.08*P.band)+P.id,clamp(rl0,0.,1.));
  float rkm=mix(3.,max(5.,floor(P.sc/px/1.2)),1.);
  if(water){
    float kmW=max(1.,(TAU*P.sc/px/21.-6.)/2.4);
    cyWave(P.q,code,P.id,ko,kmW,1.,wh,wg,wH,kap);
#if HD>=1
    {int kW=int(step(1e9,uDetail));float kW2=kap;   // (kW2: the extra octaves must not change the caustic normalisation)
     for(int i=kW;i<HD;i++){float ww=float(i)+1.;cyWave(rot(.7*ww)*P.q*(1.+.55*ww)+vec2(.3*ww),code+8.*ww,P.id,ko+2.*ww,kmW,.11/((1.+.55*ww)*(1.+.55*ww)),wh,wg,wH,kW2);}}   // v19: finer families of standing waves, one per tier
#endif
    float amp=(.84+.16*cos(PI*uP4.x))*(1.+.3*hop)*(.85+.3*P.lv)*(1.+.3*near);
    float spW=PI/max(kap,.1)*P.sc/px;
    cc=clamp(1.2*spW,8.,28.)/(kap*kap)*amp;
    vec3 c3=cc*vec3(.9,.95,1.);
    dt3=(1.+c3*wH.x)*(1.+c3*wH.y)-c3*c3*wH.z*wH.z;
  }else{
    f=cyFig(P.shp,P.q,ang,code,P.id,ko,km,P.sc,kap);
    if(cySr>.01){
      float kap2=1.;
      float frz=cyRose(P.q,ang,cySdl,rD,rkm,km,PI/max(kap,0.1)*P.sc/px,kap2);
      f=mix(f,frz,cySr*.92);kap=mix(kap,kap2,cySr*.92);
    }
  }
  vec2 gpx=vec2(dFdx(f),dFdy(f));
  float fwd=fwidth(dt3.y);
  float gl=max(length(gpx),1e-6);
  float spPx=PI/max(kap,.1)*P.sc/px;
  float lodL=smoothstep(2.5,6.,spPx);
  float bandE=P.lv;
  float kts=cyKT;
  // v14: the plate's hue also moves with its band's level, so the temple's colours follow the music
  float tint=cyRel8(P.band);
  // v14: the glass also carries the plate's band as a slow standing-wave sheen (a light term, so it may follow the band
  // directly; the wave is smooth and low, so it reads as depth without flicker)
  // w4: two hue families only. Even rings (and even sanctum plates) carry the scheme's energy and are trimmed with its
  // accent, odd ones the reverse. cE the energy, cEd its deep tone, cEh its hot core, cTr the trim
  float par=hero?mod(P.id,2.):mod(P.zone,2.);
  vec3 eD=cyS0*cyS0,eF=cyS1*cyS1,eH=cyS2*cyS2,aF=cyS3*cyS3,aD=cyS4*cyS4;
  vec3 cE=par<.5?eF:aF,cEd=par<.5?eD:aD,cEh=par<.5?eH:mix(aF,vec3(1.,.96,.9)*max(aF.r,max(aF.g,aF.b)),.35),cTr=par<.5?aF:eF;
  // the slab's material and its rim's metal (bronze or dark gold)
  float mi=hero?P.id+floor(L/10.+.01):P.zone*3.+mod(floor(P.sl+.01),2.)*2.+floor(L/10.+.01);
  float ri=mod(floor(mi+.01)+(hero?0.:P.zone),3.);
  vec3 mt=cyMatC(mi),rc=ri<.5?vec3(.5,.33,.1):ri<1.5?vec3(.4,.21,.085):vec3(.3,.31,.35);   // rims: dark gold, bronze, pewter
  if(P.dim<.8)mt=vec3(.2,.16,.14);                       // the great ground plates behind the small ones: dark basalt
  vec3 col=vec3(0),cpos=cE,cneg=mix(cEd,cE,.3);
  // the plate's energy: its band's level and onsets through a soft knee, so a loud band fills the channels without flooding
  float eK=.22+.4*cyQ+3.4*P.lv+2.*P.on+1.3*tint+.5*cyFlash;eK=eK*1.4/(1.+.25*eK);
  // w4: a heavy rim (the sanctum's composite layouts keep a slim one: their plates nest and share edges)
  float bw=hero&&mod(L,10.)>.5?clamp(.06*P.sc,2.5*px,.035):clamp(.12*P.sc,2.2*px,.09);
  float inner=smoothstep(px,-px,P.bd+bw);
  float air=clamp(hop*.62+1.1*near+(hero?0.:.35*P.on+1.4*P.fl),0.,1.6);
  if(water){
    vec3 I=1./sqrt(dt3*dt3+fwd*fwd*.8+.0025);
    float lodW=smoothstep(5.,12.,spPx);
    // too small for caustics: the bowl shows a standing wave (rings x lobes, breathing through its cycle)
    float rN=clamp(floor(P.sc/px/9.),1.,6.),sw0=cos(rq*rN*TAU)*(.45+.55*cos((2.+mod(P.id,4.))*ang+P.id))*(.62+.38*cos(uTime*4.+P.id));
    I=mix(vec3(.3+3.6*sw0*sw0*(.7+.5*cyQ)),min(I,vec3(9.)),lodW);
    float il=dot(I,vec3(.333));
    vec3 dA=cE*min(.7,.17/max(dot(cE,vec3(.2126,.7152,.0722)),.05))+vec3(.025,.045,.06),lc=mix(cE,cEh,clamp(.25+.1*il,0.,.7));   // every scheme's water is equally deep
    vec3 deep=dA*(.44+.4*cyQ+.1*(1.-rq*rq)+.3*(wh*.5+.5)*(.6+bandE));
    deep*=1.2/(1.+.6*max(deep.r,max(deep.g,deep.b)));   // v20: the deep water keeps headroom, so the light on it always reads
    vec3 lit=lc*mix(I*.42,max(I-.62,0.)*1.7,lodW)*(1.-.6*near)*(.5+.9*bandE+.6*P.on+.3*cyQ);lit*=1.5/(1.+.6*max(lit.r,max(lit.g,lit.b)));
    vec3 nn=vec3(-wg*cc*.9,1.);
    float spc=exp(220.*(dot(nn,vec3(.2885,.4533,.8243))*inversesqrt(dot(nn,nn))-1.))*lodW;
    {float crest=smoothstep(-.12,.3,wh);deep=mix(deep*.72,deep*.5+lc*(.16+.3*bandE+.14*cyQ+.3*P.on),crest);}
    col=deep*(1.-.75*clamp(max(lit.r,max(lit.g,lit.b))*.8,0.,1.))+max(lit,0.)*.8+dA*spc*1.6;
    {float wg2=max(length(vec2(dFdx(wh),dFdy(wh))),1e-5),cSp=1./(wg2*9.),cD=abs(fract(wh*9.+.5)-.5)*cSp;
     col+=dA*exp(-cD*cD*.8)*smoothstep(2.4,5.5,cSp)*(.16+.5*bandE+.4*P.on)*(1.-.5*near);}   // v19: the water's height lines, engraved like the sand plates'
    float fd=(rq-fr)*P.sc,fo=1.-smoothstep(.8,1.,tau);
    col+=lc*(exp(-fd*fd/(.0045*.0045+px*px*2.))*.65+near*.1)*fo;
  }else{
    float d=abs(f)/gl*px;
    // sand streams into the new figure behind the re-figure front: wide and loose, then settling into crisp lines
    float st=rq<fr?1.+2.2*smoothstep(.45,0.,fr-rq)*(1.-smoothstep(.85,1.,tau)):1.;
    float W=(.003+.0012*cyBs)*(1.+.35*air)*st;W=max(W,1.6*px);
    float core=exp(-d*d/(W*W))*mix(.12,1.,cyEnv);
    float Ws=W*(2.+3.5*air);
    float spray=exp(-d*d/(Ws*Ws))*mix(.12,1.,cyEnv);
    float D=core*(1.-.55*min(air,1.))+spray*.42*min(air,1.2);
    D=mix(.1,D,lodL);
    float G=max(.0027,2.*px),gpw=px/G;
    vec2 gq=P.q*P.sc/G;
    vec2 gi=floor(gq-.5);
    float cov=0.,glt=0.,GS=max(uP2.y,max(.6*cyHat,.55*cyLB.z));   // snare (and hats, smaller): grains flare into sparks
    vec2 lft=vec2(-.35,.55)*(.1+air*1.1);
    for(int j=0;j<4;j++){
      vec2 id=gi+vec2(float(j&1),float(j>>1));
      float h1=h21(id),h2=fract(h1*137.13+.3),h3=fract(h1*251.7+.7);
      vec2 c=id+.5+(vec2(h1,h2)-.5)*.62;
      float rg=.27+.17*h3;
      float th2=.06+.88*fract(h1*71.31+.1);
      float vis=smoothstep(th2-.1,th2+.1,D);
      float sk=step(fract(h1*19.7+floor(uP2.z)*.618),GS*.3),rgs=rg*(1.+.9*sk);
      float a=smoothstep(rgs+gpw*.6,rgs-gpw*.6,length(gq-c-lft*h1))*vis;
      cov=max(cov,a*(.7+.6*h3));glt=max(glt,a*sk);
    }
    float gres=smoothstep(1.3,2.6,1./gpw);
    float sand=mix(D*.7,max(cov,core*(1.-.55*min(air,1.))*.42),gres);
    // v14 beaded sand: another grain layer cut into a string of beads and isometric flecks; and wherever there are
    // grains to spare, a crisp line along the nodal ridge itself
    float G2=max(.0022,1.75*px),g2w=px/G2,gp2=g2w*g2w;
    vec2 gq2=P.q*P.sc/G2,gi2=floor(gq2-.5);
    float cov2=0.,glt2=0.;
    for(int j=0;j<4;j++){
      vec2 id=gi2+vec2(float(j&1),float(j>>1));
      float h1=h21(id),h2=fract(h1*137.13+.3),h3=fract(h1*251.7+.7);
      vec2 c2=id+.5+vec2((h1-.5)*.22,(h2-.5)*.22);
      float bd=length(gq2-c2),br=.11+.045*h3;
      float ba=smoothstep(br+gp2*.5,br-gp2*.5,bd)*(.55+.45*fract(h3*3.3));
      float qd=max(abs(gq2-c2).x,abs(gq2-c2).y)*.62;
      float fk=smoothstep(.115+gp2*.5,.115-gp2*.5,qd)*(.5+.5*fract(h3*5.1));
      float th2=.06+.88*fract(h1*71.31+.1);
      float vis=smoothstep(th2-.1,th2+.1,D);
      float sk=step(fract(h1*19.7+floor(uP2.z)*.618),GS*.3);
      cov2=max(cov2,max(ba,fk)*(1.+2.2*sk)*vis);glt2=max(glt2,ba*sk);
    }
    float gres2=smoothstep(1.5,3.2,1./g2w);
    float bres=smoothstep(.35,2.2,1./gp2);
    sand=max(sand,mix(D*.6,max(cov2,core*.3),gres2)*(.9+.35*lodL));
    // the ridge line: as crisp as the plate's edges, narrowed with zoom, only where the sand is dense
    float lw2=max(W*.42,1.05*px);
    float cr=exp(-d*d/(lw2*lw2))*smoothstep(.5,.12,lw2/(.002+.0012*cyBs))*mix(.35,1.,cyEnv);
    sand=max(sand,cr*.95)*bres;
#if HD>=1
    // v19: ever finer crystal sand. Each order is 34% smaller than the last and appears only once a grain covers real
    // pixels, so higher tiers and larger renders reveal sand that was not there before
    {
      int kG=int(step(1e9,uDetail));float nG=float(HD)*1.6+clamp(uDetail,.5,16.),G3=max(G2,1.3*spx),fineS=0.;
      for(int i=kG;float(i)<nG;i++){
        fineS=max(fineS,cyGrL(P.q*P.sc,G3,px,D*D*(.9+.3*air),float(i)*.71+3.1));
        G3=max(G3*.84,1.2*spx);
      }
      sand=max(sand,fineS*bres*smoothstep(.0,.25,D)*.8);
    }
#endif
    float am=clamp(abs(f),0.,1.);
    // w4: the plate is a carved artifact, not lit glass. Its body is a dark rich material; the figure is cut into it in relief
    // (the antinodes stand proud, the nodal lines are channels), lit from the top left; the sound's energy runs in the channels
    // and its light pools on the material beside them
    vec2 rs2=sign(f)*gpx/px*(.05*P.sc)*lodL;
    vec3 rN=normalize(vec3(-rs2,1.));
    float dl=max(dot(rN,vec3(-.46,.6,.655)),0.),spR=pow(max(dot(rN,vec3(-.253,.33,.909)),0.),26.);
    float occ=mix(.85,.5+.5*smoothstep(.02,.5,am),lodL);          // the channels lie in shadow
    vec3 mtl=mt*.75+.035;
    vec3 base=mt*(.78+.45*cyQ+1.5*dl)*occ*(.82+.18*(1.-rq*rq));
    base+=mtl*cE*eK*mix(.24,.17+.8*exp(-am*2.8),lodL);           // the energy's light on the material, strongest beside the channels
    base+=mix(vec3(1.,.93,.8),mt/max(mt.r,max(mt.g,mt.b)),.5)*spR*(.3+.3*bandE+1.1*cyLB.w+.6*cyHat)*lodL;
    base*=1.15/(1.+.3*max(base.r,max(base.g,base.b)));
    // v14 Twinkle: the material between the channels shows drifting antipodal standing-wave nodes, moving with the plate's mode
    float tp=sin(dot(P.q,P.q)*11.-uTime*1.6+P.sl*2.)*sin(rq*kap*.5-uTime*.9+P.id);
    base*=1.+.3*tp*tp*tp;
    base*=1.-.2*min(D*1.5,1.)*gres;   // the heaped sand shades the slab under it
    // v19: the plate's own height field, engraved. Contour lines of the vibrating figure (the plate's topography) sit
    // between the nodal lines, in two weights, so the glass reads as an etched instrument instead of a coloured fill
    {
      float dF=1.-exp(-3.*abs(f));                       // brighter contours climbing the antinodes
      float cSp=1./(gl*5.),cA=smoothstep(2.4,5.5,cSp);    // contour spacing in pixels; off where they would crowd
      float cD=abs(fract(f*5.+.5)-.5)*cSp;float etch=exp(-cD*cD*.8)*cA;
      float cSp2=1./(gl*14.),cA2=smoothstep(2.4,5.5,cSp2);
      float cD2=abs(fract(f*14.+.5)-.5)*cSp2;etch+=.55*exp(-cD2*cD2*.8)*cA2;
      base*=1.-.32*min(etch,1.)*lodL;                         // w4: engraved hairlines: cut dark, then filled by the energy
      base+=cE*etch*(.05+.16*dF+.5*bandE+.45*P.on+.12*cyQ+.8*cyLB.w+.5*cyLB.z+.6*cyHat)*lodL*mix(1.,.4,step(1.5,P.wat));
    }
#if HD>=1
    // v20 guilloche: the glass inside every antinode is engine-turned, pairs of fine wavy rings crossing each other (a rose-engine
    // figure). Native cuts one pair, Cinema a second, finer pair, Insane and up a third; each appears only where its lines are pixels apart
    {int kq=int(step(1e9,uDetail));float gpx2=P.sc/spx,acc=0.;
     for(int i=kq;i<kq+2*min(HD,3);i++){
       float fi=float(i-kq),pr2=floor(fi*.5),sg=mod(fi,2.)<.5?1.:-1.,N=20.*(1.+.9*pr2),M=10.+6.*pr2+2.*mod(P.id,3.);
       float sp2=gpx2/N;if(sp2<3.)break;
       float tt2=rq*N+sg*1.5*sin(ang*M+P.id+sg*uP5.z*.5),dd=abs(fract(tt2)-.5)*sp2;
       acc=max(acc,exp(-dd*dd*.9)*smoothstep(3.,6.,sp2)/(1.+.4*pr2));}
     base+=cTr*acc*(.06+.3*bandE+.3*P.on+.08*cyQ)*lodL*smoothstep(.15,.6,abs(f))*mix(1.,.3,step(1.5,P.wat));}
#endif
    if(P.wat>1.5){
      // liquid metal: the figure is the shape of a mirror surface heaving through its standing-wave cycle; it
      // reflects the temple's light, with hot specular glints and glowing antinodes, and only a seam of sand
      vec2 sl=gpx/px*(.06*P.sc*(1.+.5*air)*(.35+.65*cos(PI*uP4.x+P.sl)));
      vec3 nn=normalize(vec3(-sl,1.)),rf=vec3(2.*nn.z*nn.xy,2.*nn.z*nn.z-1.);
      float up=smoothstep(-.35,.95,rf.y-.35*rf.x),fz=1.-nn.z;
      vec3 gm=vec3(.52,.34,.1);                              // w4: a polished mirror of dark gold that picks up the energy at grazing angles
      vec3 env=gm*(.12+.95*up*up)+mix(gm,cE,.65)*fz*sqrt(fz)*1.3*(.4+eK)+cE*.03;
      float spk=pow(max(dot(rf,vec3(-.42,.55,.72)),0.),30.);
      base=env*(.8+.45*bandE)+vec3(1.,.9,.72)*spk*(.8+.6*bandE)+cE*am*am*(.06+.3*bandE)*lodL;
      sand*=.4;
    }
#if HD>=1
    // v19 mirror bounce: the glass (and much more the liquid metal) reflects the floor tiles under it, bent by the figure
    // and blurred with several samples, more at each tier
    {
      int kR=int(step(1e9,uDetail));float nR=float(HD)*float(HD)*3.5+float(HD)*5.+2.,ir=0.;vec3 rs3=vec3(0);
      vec2 slR=gpx/px*.08*P.sc;
      for(int i=kR;float(i)<nR;i++){
        float a=float(i)*2.3999632+rq*3.,rad=.018*sqrt((float(i)+.5)/nR);
#if HD>=3
        vec2 ofsR=po+slR+rad*vec2(cos(a),sin(a));   // Insane and up: the glass disperses, three channels through three slightly different paths
        rs3+=vec3(cyFlr(ofsR-.07*slR,px).r,cyFlr(ofsR,px).g,cyFlr(ofsR+.07*slR,px).b);ir+=1.;
#else
        rs3+=cyFlr(po+slR+rad*vec2(cos(a),sin(a)),px);ir+=1.;
#endif
      }
      rs3/=max(ir,1.);
      float fres=.18+.55*smoothstep(.1,.9,length(slR));
      base=base*(1.-.2*fres)+rs3*rs3*(P.wat>1.5?.5:.14)*fres*(.65+.45*bandE)*(.7+.3*cos(rq*PI));
    }
#endif
    sdV=sand;
    vec3 sc=mix(cE,cEh,.25+.2*sin(P.q.x*2.+P.q.y*1.3+cyFlo));
    float hot=core*core*(.35+.4*bandE);
    // heaped sand: the ridge along each nodal line is lit from the top left (bright flank, shaded flank)
    float pile=1.+.9*clamp(d/W*core*dot(sign(f)*gpx/gl,vec2(.6,-.8))*2.,-1.,1.)*lodL;
    float flw=.78+.22*sin(kap*rq*.7-cyFlo*3.+ang*2.);                   // the energy flows along the channels
    vec3 sandC=mix(sc,cEh,hot*.5+.5*max(glt,glt2))*(.14+.62*eK+.7*uP2.y)*pile*flw*(1.+2.4*max(glt,glt2)*GS);
    col=base*(1.-.85*clamp(sand,0.,1.))+sandC*sand*(1.+.35*air+1.4*cyHat+.6*cyLB.w);
    col+=cE*spray*(.04+.09*eK+.3*uP2.y+.12*min(cyHop,1.5))*lodL*(1.-clamp(sand,0.,1.));              // a close halo round the channels, never a wash
    col+=sc*near*.3;
    // the drive stem: a glowing boss at the plate's heart, lit with the plate's band
    float bR=rq*P.sc/(.055*P.sc+px);
    // v20: the boss sits in an eight-petal rosette of the sand's colour, outlined, opening with the plate's band
    {float pe2=bR-(1.75+.55*cos(8.*ang+P.id)+.5*bandE),pw2=1./(.055*P.sc/px+1.),big=step(5.*px,.055*P.sc);
     col=mix(col,rc*.16+cTr*(.12+.6*bandE+.8*P.on)*smoothstep(0.,-1.4,pe2),smoothstep(pw2,-pw2,pe2)*big*.85);
     col+=cTr*smoothstep(2.*pw2,0.,abs(pe2))*big*(.3+.9*P.on);}
    col=mix(col,cTr*(.4+1.1*bandE+.9*P.on)*smoothstep(.75,.35,bR)+rc*.3,smoothstep(1.,.85,bR)*step(2.*px,.055*P.sc));
  }
    // v19: the great plates behind the small ones (bell mounts, the jewel's pond, the rosette's ground) were big dark
    // discs: their glass is now engine-turned, a rose-engine figure of fine lines in the palette's light
  if(P.dim<.8){
      float rW=clamp(P.sc/px/42.,0.,1.);
      float rt=rq*30.+1.6*sin(ang*(P.band>.5?8.:12.)+rq*7.-uP5.z*2.);
      float rD=abs(fract(rt)-.5)*P.sc/px/30.,rL=exp(-rD*rD*.7);
      float rt2=rq*30.-1.6*sin(ang*(P.band>.5?8.:12.)-rq*7.+uP5.z*2.);
      float rD2=abs(fract(rt2)-.5)*P.sc/px/30.;rL=max(rL,exp(-rD2*rD2*.7));
      col+=mix(cE,cTr,step(0.,sin(ang*3.+rq*5.+uP5.z)))*rL*rW*(.08+.3*bandE+.35*P.on);
    }
#if HD>=1
  // v19 filigree: higher and higher plate modes, each drawn as nodal lines one pixel wide where it has room to be read.
  // Higher tiers run more orders and larger renders show the finer ones; they share the plate's mode code, so a re-figure
  // redraws them with the sand
  {
    float hv2=h21(vec2(P.id+code,3.7)),ppx=P.sc/spx,sgn=mod(P.id,2.)<.5?1.:-1.;
    float nF=float(HD)*3.+1.5*clamp(uDetail,.5,16.),fl=0.;vec3 fc2=vec3(0);
    int kF=int(step(1e9,uDetail));
    for(int i=kF;float(i)<nF;i++){
      float fi=float(i),n=floor(7.+hv2*6.)+2.*fi,m=floor(11.+hv2*8.)+3.*fi+mod(fi,2.);
      float spx=ppx/(.5*(n+m)*1.6);
      if(spx<3.2)break;
      float ln=cyFil(P.q,rq,ang,P.shp,n,m,hv2*6.283+fi*1.37+sgn*uP5.z*.3*fi/nF,ppx)*smoothstep(3.2,7.,spx);
      float wL=ln/(1.+fi*.3);
      if(wL>fl){fl=wL;fc2=mod(fi,2.)<.5?cE:cTr;}
    }
    col+=fc2*fl*(.05+.26*bandE+.34*P.on+.2*cyHat)*(1.-.6*smoothstep(.2,1.,sdV))*lodL;
  }
#endif
  // v20: every plate wears a collar inside its bezel: a ring of pearls that fills round like a meter with the plate's band (all of
  // them flash on its onset), a fluted band the hats light, and a fine line closing the figure. Sized in pixels: small plates carry
  // fewer, larger pearls, and the smallest none
  if(P.dim>.8){
    float ct=(-P.bd-bw)/P.sc,cpx=px/P.sc,cRp=P.sc/px,cwd=.135*smoothstep(14.,30.,cRp);
    if(ct<cwd+2.*cpx&&cwd>.01){
      float nP=2.*floor(clamp(TAU*cRp/11.,10.,72.)*.5),pa=ang*nP/TAU+.5,pid=floor(pa),pf=(fract(pa)-.5)*TAU/nP*rq;
      float pr=min(.42*TAU/nP*rq,.036),pc=.016+pr,dP=length(vec2(pf,ct-pc))-pr;
      float lvl=clamp(1.25*bandE+.2+.25*cyQ,0.,1.),pon=step(fract(pid/nP+.25),lvl);
      float f0=2.*pc+.012,ft=(ct-f0)/max(cwd-f0,1e-3),flt=abs(fract(ang*nP/TAU*2.)-.5)*2.;
      float flu=smoothstep(.15,.5,flt)*step(0.,ft)*step(ft,1.)*smoothstep(3.,6.,TAU*cRp/(nP*2.));
      vec3 kc=rc*(.2+.08*cyQ)+rc*flu*(.3+.55*ft)+cTr*flu*(.08+.3*ft)*(2.4*cyHat+1.2*cyLB.w+1.2*cyLB.z+.45*bandE+.2*cyQ);
      vec2 pn=vec2(pf,ct-pc)/pr;float pm=clamp(.5-dP/cpx,0.,1.),phl=max(1.-dot(pn-vec2(-.3,.35),pn-vec2(-.3,.35))*1.6,0.);
      vec3 pC=mix(rc*.5,cTr*(.75+.8*P.on+.4*bandE+.5*cyLB.z),pon)*(.4+.6*(1.-dot(pn,pn)))+vec3(1.,.95,.86)*phl*phl*(.14+.3*pon+.3*P.on+.4*cyHat+.3*cyLB.w);
      kc=mix(kc,pC,pm);
#if HD>=1
      // detail range: milgrain (a row of tiny beads) along the closing line; Cinema a hairline down every flute and a second
      // milgrain row under the pearls; Insane an engraved scale (ticks, every fifth long) on the lip
      {float nM=nP*3.,mf=(fract(ang*nM/TAU)-.5)*TAU/nM*rq,rM=min(.4*TAU/nM*rq,.009),sM=smoothstep(1.2,2.4,rM*P.sc/spx);
       kc=mix(kc,rc*(.5+1.4*bandE+1.2*P.on+.8*cyHat),clamp(.5-(length(vec2(mf,ct-cwd+.016))-rM)/cpx,0.,1.)*sM);
#if HD>=2
       kc+=rc*smoothstep(1.2*cpx,0.,abs(flt-.5)*TAU/(nP*4.)*rq)*step(0.,ft)*step(ft,1.)*.5*smoothstep(4.,8.,TAU*cRp/(nP*2.)/CYSS);
       kc=mix(kc,cTr*(.4+1.*P.on),clamp(.5-(length(vec2(mf,ct-f0+.004))-rM*.8)/cpx,0.,1.)*sM);
#endif
#if HD>=3
       {float nT=nP*5.,tk=abs(fract(ang*nT/TAU)-.5)*TAU/nT*rq,lng=step(abs(fract(ang*nT/TAU/5.)-.5),.1);
        kc+=rc*smoothstep(1.1*cpx,0.,tk)*step(ct,.006+.008*lng)*.7*smoothstep(2.5,5.,TAU*cRp/nT/CYSS);}
#endif
      }
#endif
      kc+=cE*smoothstep(1.3*cpx,0.,abs(ct-cwd))*(.2+.8*bandE+1.*P.on+.6*cyHat);
      col=mix(col,kc,smoothstep(cwd+cpx,cwd-cpx,ct));
    }
  }
  col*=inner*P.dim;
  float rimM=smoothstep(px,-px,P.bd);
  vec2 nrm=normalize(po-P.c+vec2(1e-5,0.));
  // ---- bezel: polished metal ring, bevel-lit from the top left, bolted, its inner lip glowing with the band
  if(rimM-inner>.001){
    float t=clamp(-P.bd/bw,0.,1.);
    // w4: a heavy rim of bronze or dark gold: a rounded outer lip (milled), a sunk band of insignia that the energy fills
    // (every fourth one lights in turn with the hats, stepping on the half beat), and an inner lip glowing with the band
    float nr=t<.22?1.-t/.22:(t>.82?-(t-.82)/.18:0.),bev=dot(nrm,vec2(-.6,.8))*nr;
    float nTk=clamp(floor(TAU*P.sc/px/7.),12.,180.),tkP=abs(fract(ang*nTk/TAU)-.5)*2.;
    bev+=.4*smoothstep(.3,.75,tkP)*smoothstep(.02,.1,t)*smoothstep(.22,.16,t)*step(.44*bw/px,TAU*P.sc/px/nTk);
    float sunk=step(.22,t)*step(t,.82);
    vec3 met=rc*(.6+.85*bev)*(1.-.4*sunk)+vec3(1.,.92,.76)*pow(max(bev,0.),4.)*.5;
    met+=rc*smoothstep(1.5*px,0.,min(min(t,1.-t),min(abs(t-.22),abs(t-.82)))*bw)*.5;   // crisp edges
    float bu=(t-.22)/.6;
    if(sunk>.5){
      float bn=.6*bw/P.sc,cir=TAU*(1.-.5*bw/P.sc),M=2.*floor(clamp(cir/(bn*1.7),6.,90.)*.5),ga=fract(ang/TAU+.5)*M,ci=floor(ga);
      float asp=cir/M/bn,cpx=px/(bn*P.sc*.5);
      vec2 g=vec2((fract(ga)*2.-1.)*asp,1.-bu*2.);
      float gd=min(cyGlyph(g,floor(cyHash(ci+P.id*3.,P.id)*8.)),max(length(vec2(asp-abs(g.x),g.y))-.13,0.));
      float cut=(1.-smoothstep(.1,.1+cpx*.8,gd))*smoothstep(.8,.25,cpx);
      float seq=step(mod(ci-floor(uP4.x*2.),4.),.5);
      met=mix(met,rc*.1,cut);
      met+=cE*cut*(.16+.25*cyQ+.7*bandE+.8*P.on+2.6*seq*cyHat+.6*cyHat+.4*cyFlash);
      met+=cTr*seq*cyHat*.22*smoothstep(1.,.4,abs(g.y))*(1.-cut);
      // too small for insignia: the band reads as a row of studs
      met+=rc*.5*smoothstep(.25,.8,cpx)*smoothstep(.5,.2,abs(fract(ga)-.5))*smoothstep(.9,.3,abs(g.y));
    }
    met+=cE*smoothstep(.8,.97,t)*(.08+1.2*bandE+1.5*P.on+1.9*cyHat+.8*cyLB.w);   // the lit inner lip
    met*=1.+1.*uP2.y+.35*min(cyHop,1.5)+.6*cyHat+.4*cyLB.w;                    // the snare rings every rim; kicks, hats and the air glint on the metal
    col+=met*(rimM-inner)*P.dim*(1.+.3*cyFlash);
  }
  // ---- the temple floor
  float outs=1.-rimM;
  if(outs>.001){
    float lr=log(max(r,.02));
    // v20b: the floor's hue is set against the glass of the ring it lies under (hbF is that ring's place in the palette)
    float hbF=hero?1.5:cyHbZ(P.zone);
    vec3 gc=hero?eF:cE,stn=vec3(.105,.098,.108)+.014*aD;   // w4: the floor is dark cut stone; gc is the energy of the ring above it
    // multi-scale dot lattice: ~25 px spacing at every zoom, two octaves crossfading so it never pops
    // v14 (with the taller event horizon) the floor lattice is denser and brighter so pulled-back views never look empty
    // v14: pulled back, the lattice lengthens again (it otherwise shrinks to nothing and the far floor goes dark)
    float oc=log2(max(px,pow(min(uZoom,1.),.6)*.0008)/.0008),o0=floor(oc),dots=0.;
    for(int i=0;i<2;i++){
      float sp=.03*exp2(o0+float(i));vec2 gp=p/sp;gp.x+=mod(floor(gp.y),2.)*.5;
      float rad=max(.055*sp,1.1*px);   // w4: the lattice is small studs, not discs
      dots+=(i==0?1.-(oc-o0):1.)*(.5+.5*smoothstep(.4,.1,length(fract(gp)-.5)))*smoothstep(rad+px,rad-px,length(fract(gp)-.5)*sp);
    }
    // the kick's sound wave runs out across the temple
    float tk=mod(kts,10.),rs=1.04+tk*(5.5+.3*r),shk=exp(-tk*1.3),wk=exp(-abs(r-rs)/(.05+.06*rs))*shk;
    vec3 cS=mix(eF,eH,.5);
    vec3 F=stn*(.55+.3*cyQ)+gc*dots*(.03+.06*cyQ+.2*wk+.12*uB1.x);
    F+=cS*exp(-pow((r-rs)/(.006+.006*rs+px),2.))*shk*.8;   // w4: the kick's ring is a thin accent
    // ---- v18: the floor is a lit mosaic. Log-polar glass tiles (self-similar, so they read at every zoom) carrying one
    // great Chladni figure across the whole temple: tiles on its nodal lines blaze. Bass pumps the figure, mids roll the
    // hue through the tiles, highs and hats throw star glints off them.
    {
      float tN=84.,tv=lr*tN/TAU;vec2 tu=vec2(tv,th*tN/TAU+mod(floor(tv),2.)*.5),ti=floor(tu),tf=fract(tu)-.5;
      float tsz=r*TAU/tN/px,hT=h21(vec2(ti.x,mod(ti.y,tN))),edge=max(abs(tf.x),abs(tf.y));
      float sh2=smoothstep(2.5,8.,tsz);
      float lead=mix(.82,smoothstep(.5,.5-min(1.5/tsz,.3),edge),sh2);
      vec2 gq2=rot(.35)*p/3.1;float gf=cos(cyGA*gq2.x)*cos(cyGB*gq2.y)-cos(cyGB*gq2.x)*cos(cyGA*gq2.y);
      float gN=exp(-gf*gf*16.);
      float tb=mix(.5,.2+.8*hT*hT,sh2);
      // w4: the tiles are cut stone (basalt, one in four of lapis, jade, bronze or dark gold); the ring's band lights them with
      // its energy, and the tiles on the great figure's nodal lines carry it across the whole temple
      float acT=step(.72,fract(hT*7.13))*sh2;
      vec3 tS=mix(stn*(.45+1.1*tb)*(.75+.8*cyQ+.6*cyLB.x+.45*cyLB.y+.3*min(cyHop,1.5)),cyMatC(floor(hT*40.))*(.2+.4*tb)*(.8+.5*cyQ+1.*cyLB.w+.6*cyLB.z+.4*cyHat),acT);   // the stone answers too: basalt to the upper mids, jewel tiles to the highs (material light, capped)
      vec3 tc=(tS*.8+.02)*gc*1.05;
      // one tile in several hundred carries the hallmark, engraved small across it
      if(tsz>48.&&fract(hT*913.7)>.9955){float hm=cyMkr(vec2((tf.y+.423)*71.,3.5-tf.x*71.));tS=mix(tS,tS*.25+gc*.4,hm);}
      float inl=0.,gem=0.;
      if(tsz>9.){float dia=abs(tf.x)+abs(tf.y),aa=1.1/tsz;inl=smoothstep(aa,0.,abs(dia-.3))+smoothstep(aa,0.,abs(dia-.16))*.7;gem=smoothstep(.1+aa,.1-aa,length(tf))*step(.55,hT);}
      float lP=mix(.25,smoothstep(.55,.9,hT),sh2);
      float lit=tb*(.06+.43*(hero?uLevel:P.lv)+.36*P.on)+gN*(.2+.8*cyQ+1.25*cyBs+(.85*uB1.x+.85*uB1.y)*gN*gN+1.2*wk+.4*cyFlash)*mix(.4,1.,tb);
      lit=lit*1.15/(1.+.42*lit)*(1.+.5*acT);   // v19: the same knee on the floor, so loud passages keep the dark leading and the tile contrast
      F+=tS*lead*1.15*sh2+tc*lead*lit*(hero?.5:1.);
      // v19: the resting light sits on the lit tiles only, in the palette's neighbouring hue: the gaps and leading stay dark
      F+=tc*lead*mix(lP,.35+.65*lP,cyQ)*tb*(.06+.35*cyQ)*(hero?.95:1.);
      F+=(gc*inl*(.04+.1*cyQ+gN*(.3+.9*cyBs+.5*uB1.y)+.3*wk+.2*cyHat+.9*cyLA.w+.5*uO1.w)+cTr*gem*(.12+.7*P.on+.5*cyHat))*lead*(hero?.8:1.)*sh2;   // every tile is inlaid: the inlay carries the energy
#if HD>=1
      // v19 micro-mosaic: each tile splits into quarters, again and again, with its own leading and gems, as far as there
      // are pixels to show it. Each tier goes deeper
      if(tsz>10.){
        int kM=int(step(1e9,uDetail));
        float nM=float(HD)+2.+.5*clamp(uDetail,.5,16.),cP=tsz/CYSS,mh=hT,mLn=0.,mGm=0.,mGh=0.;vec2 mu=tf+.5;
        for(int i=kM;float(i)<nM;i++){
          mu*=2.;vec2 mid=floor(mu);mu-=mid;cP*=.5;
          if(cP<4.)break;
          mh=fract(mh*51.31+mid.x*.37+mid.y*.73+.13+float(i)*.11);
          float e2=min(min(mu.x,1.-mu.x),min(mu.y,1.-mu.y))*cP,wL=1.2;
          mLn=max(mLn,smoothstep(wL+.8,wL-.3,e2)*smoothstep(4.,8.,cP));
          if(mh>.68){float rr2=length(mu-.5)*cP,gs=cP*.26;float gg=smoothstep(gs+.8,gs-.5,rr2);if(gg>mGm){mGm=gg;mGh=mh;}}
        }
        F+=(tc+gc*.06)*mLn*(.3+.5*wk+.4*cyHat)*lead*sh2*(hero?.8:1.);
        F+=(fract(mGh*7.3)<.5?cE:cTr)*mGm*(.12+.7*P.on+.5*cyHat+.3*wk)*lead*sh2*(hero?.8:1.);
      }
#endif
      // highs: 4-ray stars thrown off one tile in a few, a new set as the phase turns over
      float gh=fract(hT*91.7),tw=fract(gh*37.+uTime*1.7);
      if(tsz>9.&&!hero){
        float Rg=clamp(tsz*.3,1.5,6.)*(1.+1.1*cyLB.z);vec2 gd=tf*tsz;
        float star=exp(-abs(gd.y)/1.1)*exp(-abs(gd.x)/Rg)+exp(-abs(gd.x)/1.1)*exp(-abs(gd.y)/Rg);
        F+=mix(cEh,vec3(1.,.97,.9),.35)*star*step(.95-.13*cyLB.z,gh)*smoothstep(.2,.9,sin(tw*PI))*min(.08+3.*cyHat+2.6*cyLB.w+2.4*cyLB.z,2.6);
      }
      // mids: a crown of petals round the sanctum that opens with the mids
      if(r>1.08&&r<2.6){
        float nP=16.,amC=.25+.95*cyLA.w,pa=abs(cos(th*nP*.5+uP5.z*2.)),rC=1.3+amC*pa*(.75+.25*cyLA.z);
        vec3 cM=aF;
        float dC=abs(r-rC)/sqrt(1.+pow(amC*nP*.5*sqrt(max(1.-pa*pa,0.))/max(r,.1),2.));
        F+=cM*smoothstep(1.2*px+.002,.0,dC)*(.12+2.*cyLA.w+1.2*uO1.w);
        F+=cM*step(r,rC)*(.008+.04*cyLA.w)*smoothstep(1.08,1.4,r);
      }
    }
    // v13 hats: the whole floor lattice lights up in rings of light rolling outward while the hats play
    F+=gc*.55*dots*(cyHat+.5*cyLB.w+.5*cyLB.z)*(1.05+.8*sin(r*5.-uTime*3.));   // w4: the hats' studs twinkle, they no longer sweep the floor
    F+=eF*(.04+.05*uLevel)*exp(-max(r-1.04,0.)*1.4);   // the sanctum's light spills over the floor
    // radiant spokes (sub-bass), straight or spiral
    float spA=TAU/(wv<.5?12.:wv<1.5?24.:wv<2.5?6.:12.),sd=abs(fract((th+(wv>2.5?1.1:wv>1.5?-.8:0.)*(lr-.04))/spA+.5)-.5)*spA*r,sw2=max(1.1*px,.0022*(1.+r*.5));
    F+=cS*(smoothstep(sw2+px,sw2-px,sd)+.3*exp(-sd/(sw2*3.5)))*(.08+1.9*uB1.x+.7*cyBs+1.*wk)*(.72+.28*sin(lr*16.-cyFlo*4.))*step(1.1,r);   // the sub runs out along the spokes
    if(hero){
      // the sanctum floor is engraved like a record: its grooves light with the spectrum (bass at the rim,
      // treble at the heart), and each plate's glow pools around it
      float gN=r*45.,gsp=1./(45.*px),gx=.05+.9*(1.-r),gs2=spec(gx);
      F+=gc*(.12+1.*gs2)*(.34*smoothstep(2.,5.,gsp)*smoothstep(.3,.1,abs(fract(gN)-.5))+.01);
      F+=gc*exp(-max(P.bd,0.)/(.012+.02*P.sc))*(.1+.14*bandE)+gc*(.015+.03*uLevel);
    }else{
      vec4 Z=P.Z;float R=cyZR(P.zone),hz=cyTrackHalf(Z),bhb=cyHbZ(P.zone);
      vec3 cZ=cE;
      // the track the ring runs in: raised stone with engraved edges
      float Rt=P.zone<.5?1.378:R*1.0206,dtr=abs(r-Rt)-hz,tw=max(1.2*px,.0025*R);
      float trk=smoothstep(px,-px,dtr);
      F+=stn*trk*.22+cZ*trk*(.008+.04*P.lv);
      F+=cZ*(smoothstep(tw+px,tw-px,abs(dtr))*(.22+.8*P.lv+1.2*P.on));
      // rail between the plates: the band's waveform as a beam of light (treble rings: tight fast waves,
      // bass rings: long slow swells)
      float S=TAU*P.rr/P.rn,u=(th-P.ra)*P.rr,uu=mod(u,S),vv=r-P.rr;
      float gs=clamp((uu-Z.y)/max(S-2.*Z.y,1e-3),0.,1.),env=sin(PI*gs)*(1.-.8*P.fl);
      float cyc=floor(9.-P.zone),Kw=TAU*cyc/S,dir=mod(P.zone,2.)<.5?1.:-1.;
      float amp=Z.y*(.03+.24*cySm(7.-P.zone))*env,ph=Kw*uu-dir*uTime*(2.+P.zone*.25)*PI*(1.+uBuild);
      float yv=amp*sin(ph),dl=abs(vv-yv)/sqrt(1.+pow(amp*Kw*cos(ph),2.));
      float wl=max(1.1*px,.0035*Z.y/.2);
      F+=cZ*(smoothstep(wl+px,wl-px,dl)*(.16+.8*P.lv+1.2*P.on)+exp(-dl/(wl*3.))*(.02+.08*P.lv))*env;
#if HD>=1
      // v19: small gongs line the rail on both sides (more rows per tier), each a tiny Chladni figure singing the ring's band
      {
        int kS=int(step(1e9,uDetail));float nS=2.*float(HD)+2.;
        for(int i=kS;float(i)<nS;i++){
          float fi=float(i),row=floor(fi*.5),side=mod(fi,2.)<.5?1.:-1.;
          float yo=side*Z.y*(.72+.46*row);
          float uu2=uu-S*.5*(mod(row,2.)<.5?1.:.56+.44*step(.5,side));
          float rS=Z.y*(.24-.03*row),dS=length(vec2(uu2,vv-yo)),sd2=dS-rS;
          if(sd2<px){
            float s2N=rS/spx,a2=atan(vv-yo,uu2),rho=clamp(dS/rS,0.,1.),n3=2.+mod(P.zone+row,5.),m3=1.+mod(P.zone*.5+row,3.);
            float fm=cos(n3*a2+P.sl*2.)*cos(m3*PI*rho),gR=-m3*PI*cos(n3*a2+P.sl*2.)*sin(m3*PI*rho),gA=-n3*sin(n3*a2+P.sl*2.)*cos(m3*PI*rho)/max(rho,.05);
            float d3=abs(fm)/(length(vec2(gR,gA))+.001)*s2N,sandL=exp(-d3*d3*.7);
            float a3=clamp(.5-sd2/px,0.,1.),bez=smoothstep(1.3,.3,abs(sd2+1.2*px)/px);
            vec3 sB=cyMatC(P.zone+row+1.)*(.45+.3*P.lv)+cE*sandL*(.3+.9*P.lv+1.2*P.on+.6*cyHat)*step(5.,s2N);
            F=mix(F,sB,a3);F+=(rc*.7+cZ*(.1+.5*P.on))*bez*step(4.,s2N);
          }
        }
      }
#endif
      // either side of every track: a row of engraved rosettes (flower of life)
      bool ou=r>Rt;
      float gIn=ou?Rt+hz:max(R*.8165,1.1),gOut=ou?R*1.2247:Rt-hz,spc=gOut-gIn;
      if(spc>.04){
        float mid=(gIn+gOut)*.5,ro=spc*.44,nR=6.*max(1.,floor(TAU*mid/(spc*1.05)/6.)),cA2=TAU/nR;
        vec2 w2=vec2(r-mid,(fract(th/cA2+.5)-.5)*cA2*mid)/ro;
        vec2 wf=abs(w2);
        float dpt=abs(length(wf-vec2(.5,0.))-.5);
        float lw=1.1*px/ro,ros=smoothstep(lw*1.5,0.,min(dpt,abs(length(w2)-1.)))*step(length(w2),1.04);
        float rl2=exp(-abs(r-rs)/(.3+.1*rs))*shk;
        F+=cTr*2.4*ros*(.1+.3*uB1.x+.5*P.lv+.7*rl2+.9*cyLA.z)*smoothstep(4.,10.,ro/px);
      }
    }
    // v14: the sanctum wall is the living spectrum. A dais ring, eight arcs (one per band, each in that band's own
    // hue); when a band plays, its arc erupts into that band's spectrum rose while the rest stays polished stone, so every
    // range is legible as a shape at the heart of the temple, and the loudest band's flower glows brightest.
    float dr=r-1.04,dsm=smoothstep(.026+px,.026-px,abs(dr-.022));
    if(dsm>0.){
      float u8=fract(th/TAU+.3125)*8.,kb2=floor(u8),fu=fract(u8);
      vec2 bB=cyZB(kb2);float aw=px*8./(TAU*1.06);
      float fill=clamp((.06+.88*bB.x-fu)/aw+.5,0.,1.)*clamp(min(fu-.04,.98-fu)/aw+.5,0.,1.);
      float rl8=cyRel8(7.-kb2),rn2=2.+mod(kb2,5.);
      float pr2=sin(th*TAU*(1.5+rn2*.5)+(r-1.048)*900.*(1.+rn2*.3)-uTime*(.6+.2*kb2));
      float rosF=exp(-abs(pr2)*5.5*rl8)*(.6+1.8*rl8);
      vec3 cB2=mod(kb2,2.)<.5?eF:aF;                           // w4: the dais is dark gold, its eight arcs alternate energy and accent
      F=mix(F,vec3(.3,.2,.07)*(.45+.5*abs(dr-.022)/.026)+cB2*(.03+fill*(.8+1.3*bB.y))+cB2*rosF*.5,dsm);
      // the hallmark surfaces on the dais, at the foot of the view, while one new plate set in five irises in
      if(uP1.z<.999&&mod(floor(uP1.y)*7.,5.)<1.){
        float ha=mod(th-caz+PI*1.5,TAU)-PI;
        vec2 hp=vec2(ha*1.062/.0056+30.,3.5-(dr-.022)/.0056);
        float hwn=smoothstep(.18,.32,uP1.z)*smoothstep(.85,.65,uP1.z)*dsm;
        F*=1.-.75*hwn*step(abs(hp.x-30.),33.);
        F+=eH*1.3*cyMkr(hp)*hwn;
      }
    }
    // the plate's shadow on the floor: it lifts with kicks (sanctum) or its band (rings)
    vec2 so=vec2(.55,-.75)*(.03+.08*(hero?hop:P.lv))*P.sc+P.sh;float lo=length(so);
    float bdS=P.bd-dot(nrm,so);
    F*=1.-.82*smoothstep(lo*.9+px,-lo*.3,bdS);
    F+=gc*.3*(exp(-max(P.bd,0.)/(bw*.5))*.1+exp(-max(P.bd,0.)/min(.2*P.sc,hero?.035:.07))*(.06+.14*bandE+.16*P.on))*(1.+bandE);   // each plate pools its light on the floor
#if HD>=1
    // v19 polished floor: the plates hovering above are mirrored in the glass, softened with more samples at each tier
    if(!hero){
      int kM2=int(step(1e9,uDetail));float nMr=float(HD)*float(HD)*3.+float(HD)*5.+2.,aAcc=0.;vec3 mAcc=vec3(0);
      vec2 mOff=-lift*(.2+.1*P.Z.y);
      for(int i=kM2;float(i)<nMr;i++){
        float a=float(i)*2.3999632+r*.7,rad=.03*sqrt((float(i)+.5)/nMr);
        vec4 ms=cyMirS(p+mOff+rad*vec2(cos(a),sin(a)),px,floor(L/10.+.01),mats,wvs,wr,lift);
        mAcc+=ms.rgb;aAcc+=ms.a;
      }
      mAcc/=nMr;aAcc/=nMr;
      F=F*(1.-.2*aAcc)+mAcc*.3;
    }
#endif
    F*=1.1/(1.+.16*max(F.r,max(F.g,F.b)));
    // w4: every plate is a platform: a thick slab floating over the floor. Below its top face the side wall shows (more of it
    // the lower the view), with a channel of energy cut round it
    if(P.us>.5){
      float thk=hero?.05:.1*P.sc;vec2 q2=P.q+rot(P.ang)*lift*thk/P.sc;
      float bdB=cyShapeSd(P.shp,q2,atan(q2.y,q2.x))*P.sc,wall=smoothstep(px,-px,bdB)*step(-.5,-P.fl);
      float wt=clamp(P.bd/max(thk*length(lift),1e-4),0.,1.),wl2=.5+.5*dot(nrm,cR*vec2(-.8,.6));
      vec3 wC=rc*(.14+.55*wl2*wl2)*(1.-.45*wt)+cE*smoothstep(.16,.02,abs(wt-.5))*(.1+.5*bandE+.7*P.on+.2*cyQ);
      F=mix(F,wC*P.dim,wall);
    }
    col+=F*outs;
  }
  // iris front: a ring of airborne sand
  if(uP1.z<.999){
    float iw=.035*wr+px,fr2=exp(-dw*dw/(iw*iw)),fc=exp(-dw*dw/(iw*iw*.07));
    col=col*(1.-.6*fr2)+mix(cyS2*cyS2,vec3(1.,.95,.88),.25)*(fc*1.25+fr2*.3)*(1.-uP1.z*.5);
  }
  // ---- the sound field: three wandering sources (bass, mids, highs) sing travelling waves across the whole temple;
  // where the waves cancel, glowing sand gathers on the moving nodal lines, coloured by the band that dominates there,
  // grains dancing on them with the hats; every kick rings out from each source, the snare flares the lines
  {
    vec2 S1=(cyUp(uM2[0][2])-.5)*12.,S2=(cyUp(uM2[1][0])-.5)*12.,S3=(cyUp(uM2[1][1])-.5)*12.;
    // v13: pulled back, the waves lengthen (zoom^.6) so the moving nodal lines stay readable lines instead of a fine mush
    vec3 dS=vec3(length(p-S1),length(p-S2),length(p-S3))*pow(min(uZoom,1.),.6),aS=vec3(uB1.y+.4*uB1.x,uB1.w+.72*uB1.z,uB2.y+.5*uB2.z+.4*uB2.x)+.08;
    vec3 cSf=cos(dS*vec3(5.,9.,15.)-uTime*vec3(2.2,3.1,4.3)*(1.+uBuild));
    float wf=dot(aS,cSf),ln=abs(wf)/max(fwidth(wf),1e-4),tk=mod(cyKT,10.);
    vec3 kr=exp(-pow((dS-tk*4.)*3.,vec3(2.)))*exp(-tk*1.5);
    float zo=1.-min(uZoom,1.),nl=exp(-ln*ln*.8*(1.-.55*zo))*(1.+.5*zo)*(.12+mix(1.65,1.25,fsk)*dot(aS,vec3(.333))+1.8*uP2.y);   // w4: hairlines
    vec3 ac=aS*abs(cSf);ac*=ac;ac*=ac;ac+=1e-4;
    vec3 fc=(cyG(1.)*ac.x+cyG(.625)*ac.y+cyG(.25)*ac.z)/dot(ac,vec3(1.));
    fc=max(mix(vec3(dot(fc,vec3(.333))),fc,2.),0.);   // pure band colours (the blend alone turns pastel)
    // grains on the nodal lines, jittering with the hats
    vec2 gq=p/(6.*px),gi=floor(gq);float gh=h21(gi);
    float gr=smoothstep(.3,.12,length(fract(gq)-.5-.3*vec2(sin(uTime*5.+gh*30.),cos(uTime*4.+gh*20.))*(.3+.7*uB2.w)))*smoothstep(.15,.45,nl);
    float fw=mix(.05,.45,fsk)*mix(1.,hero?.08:.22,rimM);        // w4: the travelling waves are an accent, the vibration lives in the plates
    float lcv=min(1.,(nl*.8+gr*(.25+3.*cyHat)+dot(kr,aS)*.3)*fw);
    col=col*(1.-.6*lcv)+fc*lcv*1.3;   // the lines replace what is under them (no additive wash)
    // v14 the low harmonic field (the low bands' energy, cyBs's fraction): six standing waves from beyond the temple
    // whose nodal lines draw in towards the centre as the low end rises, coloured by the low band that dominates
    float vF=cyFar;
    if(vF>.01){
      float Kf=mix(2.2,5.6,vF)/max(pow(min(uZoom,1.),.55),.12),wv5=0.;
      for(int j=0;j<4;j++){
        float a=float(j)*1.5708+.35+.35*vF*sin(uTime*.11+float(j)*1.3);
        float ph=Kf*dot(vec2(cos(a),sin(a)),p)+float(j)*1.7-uTime*(.5+.12*float(j))*(1.+uBuild);
        wv5+=sin(ph)*(j<2?.45+uB1.x:(.45+uB1.z+uB2.y));
      }
      wv5/=(1.+vF*.8);
      float ln2=abs(wv5)/max(fwidth(wv5),1e-4);
      float nz=exp(-ln2*ln2*.45)*smoothstep(.03,.2,vF);
      float fwm=mix(.04,.5,fsk)*mix(.25,1.,smoothstep(.2,1.2,uZoom));
      float lc2=nz*fwm*.85;
      vec3 cH=cyG(.12+.19*clamp(vF,0.,1.)+.05*sin(uTime*.2));
      col=col*(1.-.4*lc2)+cH*lc2;
    }
  }
  col*=(1.-.22*dot(s0,s0))*.76;
  col=max(mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.16),0.);   // w4: the energy is already pure; the materials keep their own tone
  fragColor=vec4(max(col,0.),0.);
}
`;
