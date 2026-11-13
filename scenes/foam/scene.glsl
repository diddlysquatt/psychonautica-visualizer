const R_FOAM = `
// k=uP1.x, level=uP1.y, uP1.z = parent cell (|x|+8|y|+64|z|, mod 8) + 512*(species new + 3*species old),
// uP1.w = palette wipe age + 16*kind (0 drop, 1 soft phrase change, 2 species morph; age 9 = none);
// cam pos=uP2.xyz, local scale=uP2.w;
// parent offset=uP3.xyz (w = +-focal length, positive when the parent is valid); gap window on screen=uP4 (xy centre, z radius,
// w = weight + 2*event kind); basis=uM1
// uP5 = (palette a + blend to a+1, seconds since snare, visibility range + .999*event amount, style (0..4, blends) + 4*gap lamps on)
// Species (which sheet families exist): 0 FOAM = planes y,z; 1 LATTICE = x,y,z; 2 LACE = y only. A morph swaps them inside a
// front of light that rides out from the camera, so the new species grows out of the old one around the eye.
// uM2 = gap lamp A, gap lamp B, (weight A, weight B, colour rotation)
float gN,gB,gFoot;vec3 gQ,gSurfN;float gSB,gTr,gCr,gZF,gSH;vec2 gSpF;   // gSpF = (z family on, x family on) for the current sample
// The absolute lattice cell a sheet was born in (unchanged by refolds and self-similar rebases). Colour hashes use
// its absolute value: a sphere that straddles a cell face is two mirror halves whose deeper cell indices differ only in
// sign. They are periodic in 8 cells, so the parent level's cell travels packed in uP1.z (style*512 + |x| + 8|y| + 64|z|, mod 8)
vec3 gC0,gC1,gC2,gC3,gC4,gCX;   // gCX (v20b): the palette's contrast accent, from the far side of the wheel
// D3D compile cost: the HLSL compiler expands every call site inline and unrolls constant-trip loops. Loops start
// at FO0, a zero it cannot fold (uTime>=0), so shared loops keep one expansion of their body.
#define FO0 min(int(uTime),0)
// v20: the tiers above Native supersample (1.5x to 4x) and the screen shows the average. Detail whose size follows the RENDER pixel
// therefore fell under a screen pixel at the top of the range and averaged to a pale haze (Offline lost the dark glass between the
// lace entirely). OAM_SS is the tier's supersampling; lace and ornament now resolve down to about half a SCREEN pixel (OAM_PM render
// pixels) and the foam's geometry to about a third of one (OAM_GF), so the extra samples draw the same marks cleanly instead of
// drawing finer ones nobody can see. Exported frames keep lines two pixels wide.
#if HD>=5
#define OAM_SS 4.
#elif HD==4
#define OAM_SS 3.
#elif HD==3
#define OAM_SS 2.
#elif HD==2
#define OAM_SS 1.5
#else
#define OAM_SS 1.
#endif
#define OAM_PM max(1.,.7*OAM_SS)
#define OAM_GF (OAM_SS>1.2?.3*OAM_SS:0.)
// distance to the sheet families of this species (the y family always exists)
float oamSh(vec3 p){vec3 a=abs(p);return min(a.y,min(max(a.z,1e9*(1.-gSpF.x)),max(a.x,1e9*(1.-gSpF.y))));}
vec2 oamSpF(float s){return vec2(step(s,1.5),step(abs(s-1.),.5));}
// Apollonian sheet families (planes through the cell centre), repeatedly box-folded and sphere-inverted.
float map(vec3 p){
  float si=1.,k=uP1.x;
  for(int i=FO0;i<36;i++){
    if(float(i)>=gN)break;
    p=-1.+2.*fract(.5*p+.5);
    float r2=max(dot(p,p),1e-9),q=k/r2;
    p*=q;si/=q;
    if(si<max(1e-24,gFoot*.4))break;
  }
  return oamSh(p)*si;
}
// Six hand-curated jewel palettes (linear values of sRGB picks), five entries each: entry 0 is the deep tone.
// Order matters: pk() blends neighbours, so every adjacent pair is a clean hue step (no warm/cool mud). Each set walks
// 180 degrees or more of the wheel in clean steps, so every visit has warm and cool members; drops step to the next
// set, and the sets alternate cool and warm. A const table (an immediate constant buffer in D3D) instead of a branchy
// chain: it compiles far faster.
const vec3 OAM_PAL[30]=vec3[30](
  vec3(0.,.02,.1),vec3(0.,.72,1),vec3(.04,.12,1),vec3(.42,0.,1),vec3(1,.02,.3),      // ABYSS: cyan, blue, violet, rose
  vec3(.03,0.,.08),vec3(.03,.35,1),vec3(.4,.02,1),vec3(1,.01,.35),vec3(1,.35,0.),    // SUNSET: azure, violet, pink, tangerine
  vec3(0.,.05,.04),vec3(0.,.75,.22),vec3(0.,.6,1),vec3(.3,.03,1),vec3(1,0.,.55),     // JADE: emerald, cyan, violet, magenta
  vec3(.07,.004,0.),vec3(0.,.3,1),vec3(.85,0.,.55),vec3(1,.02,.03),vec3(1,.5,0.),    // EMBER: azure, magenta, red, gold (entry 1 tints the haze: never a yellow, which darkens to olive)
  vec3(0.,.01,.07),vec3(.35,.8,1),vec3(0.,.38,1),vec3(.4,.04,1),vec3(1,0.,.5),       // OPAL: ice, sky, violet, magenta
  vec3(.035,0.,.1),vec3(.35,0.,1),vec3(1,.03,.4),vec3(1,.3,0.),vec3(1,.6,.03));      // ACID: violet, pink, orange, gold
// (v20b) Each set walks one arc of the wheel, so close to a big wall a visit could be one warm (or one cool) hue from edge to edge. Every set now
// has a contrast accent from the far side of its arc. It is never blended along the arc (that would be mud): it is given whole things, one sheet
// class in three, one medallion class in three, the hearts of the others, the harlequin of the small bubbles and the colour of deep shade.
const vec3 OAM_CX[6]=vec3[6](
  vec3(1.,.42,0.),      // ABYSS (cyan, blue, violet, rose): tangerine
  vec3(0.,.8,.45),      // SUNSET (azure, violet, pink, tangerine): sea green
  vec3(1.,.48,0.),      // JADE (emerald, cyan, violet, magenta): amber
  vec3(0.,.78,.62),     // EMBER (azure, magenta, red, gold): teal
  vec3(1.,.55,.03),     // OPAL (ice, sky, violet, magenta): gold
  vec3(.05,.85,.5));    // ACID (violet, pink, orange, gold): mint
// branch-free select (ANGLE turns every ?: into an if, and pk() is expanded at three sites)
vec3 oamSel(float i){vec4 s=step(vec4(.5,1.5,2.5,3.5),vec4(i));return gC0+(gC1-gC0)*s.x+(gC2-gC1)*s.y+(gC3-gC2)*s.z+(gC4-gC3)*s.w;}
// palette set uP5.x (uniform: the GPU computes this once per wave), crossfading on phrase changes; drops snap
void oamPalette(){
  float P=uP5.x,pa=mod(floor(P),6.),pb=mod(pa+1.,6.),f=smoothstep(0.,1.,fract(P));
  // global hue drift nudges the curated set a little around the grey axis (never far enough to lose it)
  float a=.32*sin(uHue*TAU),ca=cos(a),sa=sin(a);vec3 ax=vec3(.57735),A;
  for(int i=FO0;i<5;i++){
    A=OAM_PAL[int(pa)*5+i];vec3 C=OAM_PAL[int(pb)*5+i];
    vec3 m=mix(A,C,f);
    // keep chroma through a palette crossfade so it never greys out
    float lA=dot(A,vec3(.3333)),lB=dot(C,vec3(.3333)),lm=dot(m,vec3(.3333));
    m=max(lm+(m-lm)*min(mix(length(A-lA),length(C-lB),f)/max(length(m-lm),1e-3),3.),0.);
    m=m*ca+cross(ax,m)*sa+ax*dot(ax,m)*(1.-ca);m=max(m,0.);
    if(i==0)gC0=m;else if(i==1)gC1=m;else if(i==2)gC2=m;else if(i==3)gC3=m;else gC4=m;
  }
  {vec3 m=mix(OAM_CX[int(pa)],OAM_CX[int(pb)],f);gCX=max(m*ca+cross(ax,m)*sa+ax*dot(ax,m)*(1.-ca),0.);}
}
// cyclic palette lookup: neighbouring entries blend, so colours stay clean (no muddy cross-wheel mixes)
vec3 pk(float t){
  // the palettes are ordered so every neighbour pair is a clean hue step; transitions stay short
  t=fract(t)*5.;float i=floor(t),f=smoothstep(.25,.75,t-i);
  return mix(oamSel(i),oamSel(mod(i+1.,5.)),f);
}
// shading pass at the hit: the iteration where this sheet was born (its plane first appears) gives
// colour and surface coordinates that are the same before and after a level hand-off
// the face is the nearest family's plane (0 = y, 1 = z, 2 = x); gQ = (in-plane u, normal, in-plane v)
void oamSurface(vec3 p,float sc,mat3 B){
  vec3 a=abs(p)+vec3(1e9*(1.-gSpF.y),0.,1e9*(1.-gSpF.x));
  vec3 m=step(a,vec3(min(a.x,min(a.y,a.z))));m.z*=1.-m.y;m.x*=(1.-m.y)*(1.-m.z);   // one-hot, branch-free
  gQ=p*m.y+p.xzy*m.z+p.zxy*m.x;gSB=sc;gZF=m.z+2.*m.x;
  gSurfN=normalize(B*m*(gQ.y<0.?-1.:1.));
}
// gSH packs two colour classes (0..2 each, one register): sheet = the plane's index along its normal, medallion = the
// medallion under the point, from its lattice id in half cells (corner disks are shared by four cells: they take the corner's)
void oamCell(vec3 a){
  vec3 aq=a*step(gZF,.5)+a.xzy*step(abs(gZF-1.),.5)+a.zxy*step(1.5,gZF);
  float sh=floor(fract(abs(aq.y)*.375+.5*step(abs(gZF-1.),.5)+.25*step(1.5,gZF))*3.);   // y/z classes as before
  vec2 q=gQ.xz+vec2(.13,.07),li=floor(q*.5+.5),c=q-2.*li,M=2.*(aq.xz+li)+sign(c)*step(1.,dot(c,c));
  gSH=sh+3.*floor(fract(dot(abs(M),vec2(.1875,.3125)))*3.);
}
void born(vec3 p,float dh){
  float s=1.,k=uP1.x;gB=-2.;gTr=1e3;gCr=1e9;mat3 B=mat3(1.);
  float pc=mod(uP1.z,512.);vec3 pcv=vec3(mod(pc,8.),mod(floor(pc/8.),8.),floor(pc/64.));gSH=4.;
  if(uP3.w>0.){
    vec3 a=p-uP3.xyz;float r2=max(dot(a,a),1e-9),sa=k/r2;
    vec3 pa=a*sa,v=a*inversesqrt(r2);mat3 PB=mat3(1.);
    if(dot(a,a)>1e-9)PB-=2.*outerProduct(v,v);
    if(oamSh(pa)<min(dh*1.5*sa,.35)){gB=-1.;oamSurface(pa,sa,PB);oamCell(floor(.5*pa+.5)+pcv);}
  }
  for(int i=FO0;i<36;i++){
    if(float(i)>=gN)break;
    vec3 cl=floor(.5*p+.5);
    p-=2.*cl;
    float r2=max(dot(p,p),1e-9);
    float sh=oamSh(p);
    // the first fold works in the camera's shifted frame (uP3.xyz = its accumulated even offset); deeper ones are absolute
    if(gB<-1.5&&sh<min(dh*1.5*s,.35)){gB=float(i);oamSurface(p,s,B);oamCell(cl-.5*uP3.xyz*step(float(i),.5));}
    // distance to the sheets of earlier generations = the crease where this bubble cap meets its parent
    if(gB<-1.5)gCr=min(gCr,sh/s);
    // Transposed inversion Jacobian: scale times a Householder reflection (analytic surface frame).
    vec3 v=p*inversesqrt(r2);
    if(dot(p,p)>1e-9)B-=2.*outerProduct(B*v,v);
    float q=k/r2;p*=q;s*=q;
    if(s>1e24||1./s<gFoot*.4)break;
  }
  if(gB<-1.5){gB=gN;oamSurface(p,s,B);}
  gTr=dot(gQ,gQ);
}
// A true 2D Apollonian gasket in each sheet's own coordinates (unit medallions on the cell lattice, small ones in the
// corners). Kleinian iteration: invert through the four dual circles until the point rests in one of the three base
// disks; the inversion count is the disk's generation. Footprint-limited so tiny disks fade to their mean colour.
// x = rim line coverage, y = generation, z = normalized radius inside the disk (0 centre .. 1 rim), w = resolved weight
float oamHm(vec2 p){
  if(p.x<0.||p.x>=60.||p.y<0.||p.y>=7.)return 0.;
  const ivec2 G[8]=ivec2[8](ivec2(508430,1086),ivec2(1020036,4228),ivec2(476721,17966),ivec2(583347,17969),
                            ivec2(1032734,16927),ivec2(1001009,17982),ivec2(476735,17969),ivec2(1001022,16912));
  const int W[10]=int[10](0,1,2,3,4,5,-1,6,7,4);
  int ci=int(p.x/6.),cx=int(p.x)-ci*6,gi=W[ci];
  if(gi<0||cx>4)return 0.;
  int r=6-int(p.y),bits=r<4?(G[gi].x>>((3-r)*5))&31:(G[gi].y>>((6-r)*5))&31;
  return float((bits>>(4-cx))&1);
}
vec2 gDv;float gDp;   // v18: the resting disk's own coordinates (unit disk) and the pixel footprint in them
float gPn,gPr,gPw;   // the enclosing (parent) disk: generation, normalized radius, fade-in of its content
vec4 oamGasket(vec2 q,float px,float det){
  vec2 c=q-2.*floor(q*.5+.5);
  float s=1.,n=0.,res=1.,cov=0.,nest=0.,rho=1.,done=0.;
  gPn=0.;gPr=.8;gPw=1.;gDv=vec2(1.,0.);gDp=1.;
  if(dot(c,c)>1.){c=(c-sign(c))/.41421356;s=2.41421356;n=1.;}
  float gap=smoothstep(1.,1.08,dot(c,c));
  const float R=.4641016;
  for(int i=FO0;i<48;i++){
    if(float(i)>=14.+6.*det)break;
    float pl=px*s;
    vec2 d0=c-vec2(0.,.5358984),d1=c-vec2(-R,-.2679492),d2=c-vec2(R,-.2679492);
    float l0=length(d0),l1=length(d1),l2=length(d2),l=min(l0,min(l1,l2)),r0=dot(c,c);
    // resting in a base disk (three inner ones, or the outer one = the inscribed disk of a central gap)
    bool inner=l<R,outer=r0>1.;
    if(inner||outer){
      float rim=inner?R-l:sqrt(r0)-1.;
      rho=inner?l/R:inversesqrt(r0);
      gDv=inner?(l==l0?d0:(l==l1?d1:d2))/R:c/r0;gDp=inner?pl/R:pl/r0;
#if HD>=1
      cov=max(cov,(1.-smoothstep(.03-pl,.03+pl,rim))*smoothstep(.12,.03,pl)*(nest<2.5?1.:max(.32,1.-.24*(nest-2.))));
#else
      cov=max(cov,(1.-smoothstep(.03-pl,.03+pl,rim))*smoothstep(.12,.03,pl));
#endif
      // every disk holds a whole medallion of its own, down to the pixel footprint; the blend below hides
      // the nested content smoothly where it would be unresolved
      // the content fades in over a range of footprints, so the switch to a deeper level is never a hard seam
#if HD>=1
      if(nest<5.+2.*float(HD)&&pl<.024){
#else
      if(nest<5.&&pl<.024){
#endif
        gPn=n;gPr=rho;gPw=smoothstep(.024,.009,pl);
        c=gDv;s/=inner?R:r0;
        n+=1.;nest+=1.;continue;
      }
      done=1.;break;
    }
    if(pl>.12){res=0.;done=1.;break;}
    // otherwise it lies in a curvilinear gap: invert through that gap's dual circle
    vec2 a=c-vec2(1.7320508,1.),b=c-vec2(-1.7320508,1.),e=c-vec2(0.,-2.);
    float f;
    if(r0<.0717968){f=.0717968/max(r0,1e-9);c*=f;}
    else if(dot(a,a)<3.){f=3./dot(a,a);c=vec2(1.7320508,1.)+a*f;}
    else if(dot(b,b)<3.){f=3./dot(b,b);c=vec2(-1.7320508,1.)+b*f;}
    else{f=3./max(dot(e,e),1e-9);c=vec2(0.,-2.)+e*f;}
    s*=f;n+=1.;
  }
  // a point that never came to rest sits in a cusp next to a tangency (slow parabolic convergence): show the
  // enclosing disk there instead of a stale half-iterated colour, which drew wedge-shaped shards
  float wres=res*done*smoothstep(.12,.04,px*s)*gPw;
  cov*=done;
  return vec4(cov*(1.-gap),n,rho,wres*(1.-gap));
}
// 8 bands: sub/bass move the big structure's light smoothly, mids the rims and lace, highs and air the glints
#define bSub (uB1.x*1.08)
#define bBass uB1.y
#define bLM (uB1.z*1.04)
#define bMid (uB1.w*1.04)
#define bHM uB2.x
#define bPr uB2.y
#define bHi (uB2.z*1.09)
#define bAir uB2.w
// event amounts (blackout, chase storm, x-ray, lantern ring)
vec4 oamEv(){float k=floor(uP4.w*.5);return fract(uP5.z)/.999*step(abs(vec4(1.,2.,3.,4.)-k),vec4(.5));}
// style table: (lace, face, iridescence, lamps) for stained glass / pearl / neon wire / lantern; the style blends per phrase
const vec4 OAM_STY[4]=vec4[4](vec4(1.,.85,1.,1.),vec4(.55,1.15,1.7,1.),vec4(1.35,.4,1.2,1.),vec4(.85,.8,.9,1.8));
// the lighting style (blending per phrase) as (lace, face, iridescence, lamps)
vec4 oamSW(){float f=mod(uP5.w,4.),s0=floor(f);int i0=int(s0)&3;return mix(OAM_STY[i0],OAM_STY[(i0+1)&3],smoothstep(0.,1.,f-s0));}
// a full-spectrum hue (x-ray glass, the lantern halo): cheap, no palette lookup
vec3 oamSpec(float h){return .5+.5*cos(TAU*(h+vec3(0.,.33,.67)));}
#if HD>=1
// v19 tiers: anti-aliased ink line of half width w at distance d, footprint f
float oamLn(float d,float w,float f){return 1.-smoothstep(w,w+1.6*f,d);}
// a ring of n round beads at radius r, in the unit disk's polar coordinates: x = coverage, y = bead index
vec2 oamBd(float rh,float an,float r,float n,float s,float f){float b=TAU/n,i=floor(an/b+.5);return vec2(1.-smoothstep(s-f,s+f,length(vec2(rh-r,(an-b*i)*rh))),i);}
#endif
void realm(){
  // zoom out = the JS pulls the eye back along a free path (collision-safe) and the lens widens, capped near 120 degrees
  float zo=clamp((1.-uZoom)/.85,0.,1.),zf=uZoom<1.?mix(1.,.66,pow(zo,.8)):uZoom;
  vec2 p=scr()/zf;
  vec3 ro=uP2.xyz;float sc=uP2.w;
  vec2 lp=p+uLook*vec2(.5,.35);
  // A wide lens keeps the enclosing architecture in view while entering each gap.
  float fq=floor(abs(uP3.w)*.25),foc=max(abs(uP3.w)-4.*fq,.5);   // narrows during a build (the view tightens on the gap)
  float clipT=fq*sc/16.;   // zoomed far out the eye may stand behind foam: the march starts on this sphere (a carved hall)
  vec3 rd=normalize(lp.x*uM1[0]+lp.y*uM1[1]+foc*uM1[2]);
  float pix=1.2/(uRes.y*zf*foc);
  float det=clamp(uDetail,.5,16.);
  gN=min(36.,floor(9.+2.*det));
  float pixelFactor=max(max(.22,.5/sqrt(det)),OAM_GF);
  float vis=floor(uP5.z);
  float fogL=sc*clamp(vis*.65,30.,240.)*(1.+.3*sqrt(det)+.25*uBuild)*(1.+2.5*zo+5.*zo*zo*zo),maxT=max(fogL*7.,sc*900.*(1.+3.*zo));
  // species of each sample: inside the morph front (log depth frL around the eye) the new one, outside the old one
  float spN=mod(floor(uP1.z/512.),3.),spO=floor(uP1.z/1536.);
  float wT0=mod(uP1.w,16.),wK0=floor(uP1.w*.0625);
  float frT=sc*exp(min(.7-1.2*step(.5,wK0)*step(wK0,1.5)+wT0*(wK0<.5?3.2+1.5*wT0:wK0<1.5?1.2+.3*wT0:2.+.8*wT0),40.));
  if(wT0>8.5)frT=1e30;
  vec2 fN=oamSpF(spN),fO=oamSpF(spO);
  float tt=sc*.01+clipT,hit=0.,gw=0.,gz=0.,e0=clipT>0.?clipT*1.04+sc:0.;   // no grazing glow or outline on the carved cut itself
  int MS=int(70.+58.*det+50.*zo);
  float hitMap=0.;
  // silhouette finder: the closest local approach of the ray to a surface it then passed (hole rims, bubble limbs)
  float pd=1e9,ppd=1e9,pe=1.,pt=0.,edge=1e9,edgeT=0.;
  for(int i=FO0;i<1024;i++){
    if(i>=MS)break;
    gFoot=max(sc*1e-7,pix*tt*pixelFactor);
    gSpF=tt<frT?fN:fO;
    float dm=map(ro+rd*tt),d=dm*.35;hitMap=dm;
    float eps=max(sc*1e-7,pix*tt*pixelFactor);
    // light hugging every surface the ray grazes; its colour is set by depth after the march
    float w=exp(-d/(sc*.025))*min(d,sc*.1)/sc*exp(-tt/fogL*.8);
    w*=step(e0,tt);gw+=w;gz+=w*tt/fogL;
    if(pd<ppd&&d>pd&&pd/pe<edge&&pt>e0){edge=pd/pe;edgeT=pt;}
    ppd=pd;pd=d;pe=eps;pt=tt;
    if(d<eps){hit=1.;break;}
    tt+=d;
    if(tt>maxT)break;
  }
  gSpF=tt<frT?fN:fO;
  // phrase events: kind in uP4.w (above the window weight), amount in the fraction of uP5.z (re-derived where used, so
  // nothing is held live through the loops)
  float win=uP4.w-2.*floor(uP4.w*.5),lampsOn=step(4.,mod(uP5.w,8.)),rotC=uM2[2].z;
  float bP=floor(uP5.w*.125),midS=mod(bP,64.)/63.,basS=floor(bP/64.)/63.;   // v18: mid and bass through slow springs (shapes move only on these)
  float fog=exp(-tt/fogL*.55);
  // the palette change rides a front of light out from the camera through the depth of the foam (log depth, so it reaches
  // the far shells in a couple of seconds): uP1.w = seconds since it began + 16*kind, 9 = none
  oamPalette();
  float dl=0.;
  // the depths are lit, never dead black: deep jewel haze that brightens toward the threaded gap
  vec2 gc=uP4.xy;float gr=max(uP4.z,.05);
  float gd=length(lp-gc)/gr;
  vec2 nq=lp*1.3+vec2(uMT*.02,0.);
  float neb=vnoise(nq*2.3+sin(nq.yx*1.7-uMT*.04)*.6)*.8+.2*(.5+.5*sin(nq.x*5.1+sin(nq.y*4.3)*2.));
  neb=smoothstep(.25,.9,neb);
  // D3D expands every pk() call site, so the colours this pixel needs are fetched in two shared loops
  float gzz=gz/max(gw,1e-6);
  vec3 lampCol=vec3(0.),mistC=vec3(0.),rimCol=vec3(0.),glowC=vec3(0.),camCol=vec3(0.);
  for(int j=FO0;j<5;j++){
    vec3 v=pk(rotC+(j==0?.6+.2*uMid:j==1?.4+.3*neb:j==2?.45+edgeT/fogL*.8:j==3?.15+gzz*.7:.8));
    if(j==0)lampCol=mix(v,vec3(1.),.15);      // gap lanterns: warm entries, drifting with the mids
    else if(j==1)mistC=v;else if(j==2)rimCol=v;else if(j==3)glowC=v;else camCol=mix(v,vec3(1.),.72-.3*zo);   // zoomed out, the light keeps more colour (far fills would read grey)
  }
  vec3 mist=(1.-.85*oamEv().x)*gC0*(.07+.14*neb)*(1.+.5*uBuild+.3*bSub)+mistC*neb*neb*.035*(1.+zo)
           +lampCol*exp(-gd*gd*.5)*.22*win*(1.+.4*uKick+.8*uBuild);
  vec3 col=mist;
  float snA=uP5.y;
  // snare: a shell of light sweeps outward from the camera through the nested foam
  float waveR=sc*(1.+26.*snA),waveW=sc*(.6+3.*snA);
  float wave=exp(-snA*2.4)*step(snA,2.);
  vec3 shC=vec3(0.);   // the drop front's light, added after the gamut knee so it can blaze
  float aKx=0.;vec3 kL=vec3(0.);    // v11: the onset light (kicks and per-band onsets), also added after the knee, so the hits read
  if(hit>.5){
    vec3 pos=ro+rd*tt;
    float eps=max(sc*1e-7,pix*tt*pixelFactor);
    born(pos,max(eps*2.,hitMap));
    vec3 geomN=gSurfN;
    if(dot(geomN,-rd)<0.)geomN=-geomN;
    float surfacePx=max(pix*tt*gSB*.55*OAM_PM,1e-6);
    vec3 nn=geomN;
#if HD>=1
    float lb=uP1.y+min(gB,11.);                // v19: generations beyond High's reach (gN 11) keep its deepest palette class
#else
    float lb=uP1.y+gB;                         // absolute birth level (generation) of this sheet
#endif
    vec2 sq=gQ.xz;                             // the sheet's own coordinates
    float ndv=clamp(dot(nn,-rd),0.,1.);
    float sz=log2(1./(gSB*sc));                // size class relative to the view: walls high, fine foam low
    float big=smoothstep(-1.,3.,sz);           // the big shells (they ride the sub and bass)
    // v14: the bass drives VALUE, not brightness: the big shells' faces sink and their rims thicken as the low end
    // rises. The auto-exposure keeps the mean, so a level-driven brightness lift is invisible; a redistribution is not.
    float bassB=bBass*big;
    // spectrum by generation: the biggest shells ride the sub/bass, each finer generation a higher band
    float sp=spec(clamp(.40-sz*.085,.02,.95));
    float sp2=sp*sp*uDose;
    // generation colour: neighbouring generations take neighbouring palette entries, so nested shells read
    // neighbouring sheets of one generation (the planes of successive cells: chains of sibling bubbles) lean one
    // palette entry apart, so bubble chains alternate instead of running as single-colour bands
    float shK3=mod(gSH,3.),cxS=step(1.5,shK3);   // (v20b) one sheet class in three is the contrast family, the other two sit two palette entries apart
    float ht=rotC+lb*.2+.04*log2(1.+gTr)+.2*shK3-.2;
    // camera lantern inside the clear sphere around the eye
    vec3 lamp=ro+sc*(uM1[0]*.10+uM1[1]*.14-uM1[2]*.03);
    vec3 toLamp=lamp-pos;float lampD=max(length(toLamp),sc*1e-6);
    float lit=max(1./(1.+lampD*lampD/(fogL*fogL*.35)),.3*zo);   // v20: .5 -> .3 (the eye no longer stands 15 cells outside, and the flat fill washed the nearer view pale)   // the far halls stay lit when zoomed out
    vec3 L1=toLamp/lampD;
    float dif=clamp(dot(nn,L1),0.,1.);
    // occlusion probes, scaled to this sheet's own cell size, so every bubble finds its own seams (the lantern shadow
    // march that only ran above detail 2 is gone: it cost D3D compile time for an effect invisible at normal detail)
    float aoS=min(sc,.5/gSB),aoOcc=0.,aoWeight=0.,shadow=1.;
    for(int j=FO0;j<12;j++){
      float fj=float(j+1);
      if(fj>min(12.,3.+det))break;
      float st=aoS*(.025*fj+.0125*fj*fj);
      gFoot=eps;float sd=map(pos+geomN*st);
      aoOcc+=clamp(1.-sd/st,0.,1.)/fj;aoWeight+=1./fj;
    }
    float ao=clamp(1.-aoOcc/max(aoWeight,1e-6),0.,1.);
#if HD>=1
    // v19: a hanging key lantern, off to one side of the eye (the camera lantern sits at the eye, so it casts no visible shadow)
    vec3 kP=ro+sc*(uM1[0]*1.5-uM1[1]*1.0+uM1[2]*.6),kTo=kP-pos;float kD=max(length(kTo),sc*1e-6);vec3 kL1=kTo/kD;float kDif=clamp(dot(nn,kL1),0.,1.),shK=1.;
    {
      // v19: real light transport from Native up. A soft shadow marched toward the camera lantern, and an occlusion gather over a cone of
      // directions (the probes above only look along the normal). Both only darken, so the picture gains contrast and keeps its colour.
      float sT=aoS*.03,sE=min(kD*.96,fogL*1.2),res=1.;
      int sN=int(14.+11.*det);
      for(int j=FO0;j<140;j++){
        if(j>=sN||sT>=sE)break;
        gFoot=max(eps,sT*pix*pixelFactor);
        float sd=max(map(pos+geomN*eps*2.+kL1*sT),sT*.002);
        res=min(res,9.*sd/sT);
        if(res<.015)break;
        sT+=sd*.7;
      }
      shK=smoothstep(0.,1.,res);shadow=mix(.45,1.,shK);
      vec3 oT=normalize(cross(geomN,abs(geomN.y)<.7?vec3(0.,1.,0.):vec3(1.,0.,0.))),oB=cross(geomN,oT);
      float oc=0.,ow=0.,nD=min(3.+floor(.7*det),8.),nR=min(4.+floor(.35*det),7.);
      for(int d=FO0;d<8;d++){
        if(float(d)>=nD)break;
        float oa=float(d)*2.399963+.7;
        vec3 od=normalize(geomN+.85*(oT*cos(oa)+oB*sin(oa)));
        for(int j=FO0;j<7;j++){
          if(float(j)>=nR)break;
          float fj=float(j+1),st=aoS*.1*fj;
          gFoot=eps;float sd=map(pos+od*st);
          oc+=clamp(1.-sd/st,0.,1.)/fj;ow+=1./fj;
        }
      }
      ao*=1.-.3*smoothstep(.15,.85,oc/max(ow,1e-6));
    }
#endif
    dif*=shadow;
    float sky=.5+.5*dot(nn,uM1[1]);
    float viewLight=max(dot(nn,-rd),0.)/(1.+tt*tt/(fogL*fogL*2.));
    // every sheet carries an Apollonian medallion (and disks large on screen hold medallions of their own)
    // the medallion lattice must keep the sheet's period (2), or every fold plane cuts the disks with a straight seam
    vec4 ga=oamGasket(sq+vec2(.13,.07),surfacePx,det);
    float gen=mix(gPn,ga.y,ga.w);
    vec4 EV=oamEv(),SW=oamSW();float laceW=SW.x,faceW=SW.y,iridW=SW.z,lampW=SW.w,evBlack=EV.x,evChase=EV.y;
    float gsp=spec(clamp(.04+gen*.09,.02,.95));             // medallion generation -> spectrum band (outer = bass)
    float gsp2=gsp*gsp*uDose;
    // unresolved nested disks blend back to their enclosing disk, so no level ever pops
    float grho=mix(gPr,ga.z,ga.w);
    // v14: the bass makes every disk's dome breathe: rings and heart slide outward and back, a radial redistribution of
    // the same light (so it survives auto-exposure)
    float grhoB=grho+(.24*bBass)*grho*(1.-grho);
    // medallions belong to the big walls; small bubbles stay clean jewels whose rims read as spheres
    float cellPx=1./max(gSB*pix*tt*OAM_PM,1e-9);   // this sheet's cell size on screen, in pixels (v20: in OAM_PM render pixels)
    // zoomed far out, the carved cut through a foam wall shows the wall's own rose-window lace (projected through it)
    float cutM=clipT>0.?1.-smoothstep(pix*tt*.5,pix*tt*4.,tt-clipT):0.;
    float mw=max(smoothstep(5.-2.*zo,26.-8.*zo,cellPx),cutM);   // zoomed out, even far shells carry their rose windows
    // thin-film phase; on the medallion walls the film follows each disk's dome (Newton's rings) instead of striping
    float th=2.+3.*gTr+mw*1.6*grhoB*grhoB+uMT*.04;
    // each medallion of a resolved wall takes its own lead colour (rose windows of different glass, not rows of clones)
    float mO=(.2*floor(gSH/3.)-.2)*smoothstep(15.,45.,cellPx);
    float dg=mO+.09*gen+.05;
    // six lookups: creases share the next generation's colour, the film shares the iridescence
    vec3 body,nextC,diskC,heartC,lineC,irid;
    for(int j=FO0;j<6;j++){   // one shared pk() expansion (D3D inlines every call site)
      vec3 v=pk(ht+(j==0?0.:j==1?.3:j==2?dg:j==3?dg+.4:j==4?.2*gen+.3:.3+.45*(1.-ndv)+th*.03));
      if(j==0)body=v;else if(j==1)nextC=v;else if(j==2)diskC=v;else if(j==3)heartC=v;else if(j==4)lineC=v;else irid=v;
    }
    // (v20b) THREE FAMILIES IN EVERY VIEW. Whole things take whole colours: a contrast sheet is the accent with the palette's own disks and hearts;
    // on a palette sheet one medallion class in three is an accent window and the hearts of another are accent jewels. Nothing is blended across.
    {float mdK=floor(gSH/3.),cool=smoothstep(-.2,.2,gCX.b-gCX.r);
     vec3 cxB=gCX*mix(.82,1.,cool);
     body=mix(body,cxB*min(dot(body,vec3(.2126,.7152,.0722))/max(dot(cxB,vec3(.2126,.7152,.0722)),.05),1.),cxS);
     diskC=mix(diskC,mix(cxB*min(dot(diskC,vec3(.2126,.7152,.0722))/max(dot(cxB,vec3(.2126,.7152,.0722)),.05),1.),diskC,cxS),step(1.5,mdK));          // accent windows on palette sheets (on an accent sheet the windows stay palette)
     {vec3 hA=mix(gCX,gC4,cxS);float hR=dot(heartC,vec3(.2126,.7152,.0722))/max(dot(hA,vec3(.2126,.7152,.0722)),.05);heartC=mix(heartC,hA*mix(hR,max(hR,1.),clamp(3.*bHM+2.*uO2.x,0.,1.)),step(mdK,.5));}             // accent hearts in another class (palette's warm end on accent sheets)
     }
    vec3 creaseC=nextC,filmC=irid;
    // v14: a three-step value ladder on the birth generation (hue untouched): nested generations take deep, middle and
    // high values (mean 1), so the onion shells of the dive separate by value even when every palette entry is warm
    // and equally bright. The neon line colours are not laddered, so the dark shells keep bright contours.
    float vlad=.8+.2*mod(lb,3.);
    body*=vlad;diskC*=vlad;heartC*=vlad;
    // the classic FOAM species burns with jewel fire: about half of its sheets (whole sheets, so nothing blends to mud)
    // take a hot red-orange drawn from the palette's warm end, with a gold heart
    float wsel=gSpF.x*(1.-gSpF.y)*step(.68,fract(lb*.37+mod(gSH,3.)*.29+.11));   // v11: about a third of the sheets (was half): less red-orange mass
    vec3 W=mix(vec3(1.,.05,.06),gC4,.3);   // crimson-red: in shade it deepens to wine, never to brown
    body=mix(body,W,wsel);diskC=mix(diskC,mix(W,gC4,.45),wsel);heartC=mix(heartC,vec3(1.,.55,.08),wsel*.8);nextC=mix(nextC,W,wsel*.6);
    // the drop: a white-hot shell rides the front; ahead of it the old world sinks dark, behind it the new one blooms
    // (re-derived from uP1.w in a different form, so the compiler does not keep the early values live through the loops)
    float wT=mod(uP1.w,16.),wK=floor(uP1.w*.0625),wS=step(.5,wK)*step(wK,1.5),wM=step(1.5,wK),wOn=1.-step(8.5,wT),wD=wOn*(1.-wS-wM);
    float ldL=log(max(tt,1e-30))-log(sc),frL=.7-1.2*wS+wT*(wK<.5?3.2+1.5*wT:wK<1.5?1.2+.3*wT:2.+.8*wT);
    float wB=wOn*smoothstep(frL+.35,frL-.35,ldL);   // the wipe mask again (recomputed: cheaper than holding it)
    float shell=wOn*exp(-pow((ldL-frL)*2.5,2.))*(1.-.8*wS-.3*wM)*exp(-wT*.35);
    float hbP=.5+.5*cos(TAU*(ldL*.28-uBar*2.));hbP=hbP*hbP*hbP;
    float fillK=1.-wD*smoothstep(0.,.15,wT)*(.72*(1.-wB)-.25*wB*exp(-wT*1.2));
    fillK*=(1.-.96*evBlack*(1.-.45*uKick*uKick))*(1.-.45*evChase);   // v12: the blackout's kick strikes softer      // blackout event: black world, white-hot line art; each kick strikes it back like lightning
    dl=(wD+.5*wM)*wB*exp(-wT*.8);   // the freshly recoloured world, just behind the drop front
    float accW=mw*mix(step(1.5,mod(floor(gPn+.5)+floor(gSH/3.),3.)),step(1.5,mod(floor(ga.y+.5)+floor(gSH/3.),3.)),smoothstep(.35,.65,ga.w));   // the enclosing disk's class until the nested one resolves: no pop
    vec3 accG=mix(gCX,gC4,cxS);
    vec3 accB=mix(body,diskC,.5*mw);
    diskC=mix(diskC,accG*min(dot(diskC,vec3(.2126,.7152,.0722))/max(dot(accG,vec3(.2126,.7152,.0722)),.05),1.),accW);
    vec3 alb=mix(1.,1.-.33*basS,1.-hbP)*mix(accB,accG*min(dot(accB,vec3(.2126,.7152,.0722))/max(dot(accG,vec3(.2126,.7152,.0722)),.05),1.),accW)*.5*fillK*(.88+.4*bSub*big+.2*bBass+.38*zo)*(1.-.30*bassB)*(1.-.35*(1.-gSpF.x)-.2*gSpF.y);
    alb=mix(vec3(dot(alb,vec3(.2126,.7152,.0722))),alb,mix(.55,1.,max(accW,cxS)));
    // a big wall seen edge-on (its medallions are unresolved there) sinks darker instead of a smeared sheet of colour
    alb*=mix(1.,.4+.6*smoothstep(.04,.4,ndv),big);   // v11: fills a step less saturated, so the lines and lights carry the colour   // lace and lattice show more open sheet: a little less fill
    alb*=1.-.3*smoothstep(2.5,-1.,sz);   // v12: the fine foam is a field of jewels on a darker ground, not a flat sheet of colour
#if HD>=1
    alb*=1.-.5*smoothstep(-.5,-3.,sz);
#endif
    alb=mix(gC0*.3,alb,smoothstep(.3,.95,ao));   // crevices sink into the palette's deep tone
    float dome=mix(1.,.18+.85*pow(grho,2.),mw);
#if HD>=1
    // v20: a nested medallion that High could not resolve sits inside its parent's dome (dark at the heart, lit toward the rim) instead
    // of bringing a fresh, brighter dome of its own. The deeper levels of the upper tiers used to fill every dark heart with mid-tone
    // glass, which is where the top of the range lost its contrast.
    float hdDeep=ga.w*mw*(1.-smoothstep(.024,.009,gDp*.59*OAM_SS/OAM_PM));
    dome*=mix(1.,min(1.,(.18+.85*gPr*gPr)*1.3),hdDeep);
#endif
    float lightK=(.04+.06*sky)*ao*ao+1.25*dif*lit+.3*viewLight*(.4+.6*ao);
    vec3 c=alb*faceW*dome*lightK*camCol;
#if HD>=1
    c+=alb*faceW*dome*.8*kDif*shK*lit*(.45+.55*ao)*mix(camCol,gC2,.35);
#endif
    if(lampsOn>.5){
      // the gap lanterns light the foam as one weighted lamp (during a hand-off it glides from the old gap to the new one)
      float wA=uM2[2].x,wB=uM2[2].y,weight=wA+wB;
      if(weight>.002){
        vec3 toGap=(uM2[0]*wA+uM2[1]*wB)/weight-pos;float gapDistance=max(length(toGap),sc*1e-6);
        vec3 gapDir=toGap/gapDistance;float gapDiffuse=max(dot(nn,gapDir),0.);
        float gapRange=sc*max(6.,min(vis,26.));
        float gl=weight*lampW*(1.+.8*bBass+.35*uKick+.8*uO1.y)/(1.+gapDistance*gapDistance/(gapRange*gapRange));
#if HD>=1
        {
          // v20: the gap lanterns cast real shadows from Native up: a soft shadow marched from the sheet toward the lantern, so the foam
          // between them and the light falls into shade and the shadows swing as the lantern drifts. It only darkens.
          float sT=aoS*.03,sE=gapDistance*.96,res=1.;
          int sN=int(12.+10.*det);
          for(int j=FO0;j<140;j++){
            if(j>=sN||sT>=sE)break;
            gFoot=max(eps,sT*pix*pixelFactor);
            float sd=max(map(pos+geomN*eps*2.+gapDir*sT),sT*.002);
            res=min(res,8.*sd/sT);
            if(res<.015)break;
            sT+=sd*.7;
          }
          gl*=mix(.22,1.,smoothstep(0.,1.,res));
        }
#endif
        c+=alb*mix(vec3(1.),lampCol,.35)*gapDiffuse*gl*2.*dome;
        c+=lampCol*pow(clamp(dot(reflect(rd,nn),gapDir),0.,1.),40.)*gl*1.5;
      }
    }
    // inner light: each disk glows toward its rim with its generation's band; one generation per beat is chased
    // (the chase-storm event sharpens it into a strobe that runs through the generations on every beat)
    float chase=exp(-(5.+12.*evChase)*abs(fract(uBar*(1.+3.*evChase)-gen*.25+.5)-.5))*(1.+3.*evChase)*(1.+2.*evChase*uLevel);
    c+=mw*diskC*pow(grhoB,3.)*(.03+.3*gsp2+.2*chase*uLevel+.25*bLM+.55*wave)*faceW*(.3+.7*ao)*fillK;   // v12: the snare also blooms every rose window (a 0.4 s swell)
    // and a glowing heart in every disk: the jewel lit from within, on its band (hi-mids: voices and leads)
    c+=mw*heartC*exp(-grhoB*grhoB*5.)*(.04+.5*gsp2+.35*chase*uLevel+.6*dl+1.1*bHM)*(.4+.6*ao)*(1.-.85*evBlack*(1.-uKick));
    // v20: every heart sits in a bezel: a crisp ring round the glow, drawn wherever the disk is wide enough to hold it. The soft
    // heart alone read as a blurred dot on every disk too small for its petals; the ring gives each one an edge. It rides the bass
    // spring outward (shape on the spring only) and the snare strikes it (light only, after the knee below).
    float bzR=.3+.07*basS,bzF=max(mix(gPw>.5?gDp:.2,gDp,ga.w),1e-4);
    float bzL=(1.-smoothstep(.022,.022+1.5*bzF,abs(grhoB-bzR)))*smoothstep(.2,.07,bzF)*mw;
    c=c*(1.-.55*bzL)+mix(heartC,lineC,.5)*bzL*(.3+.9*gsp2+.8*bHM+.9*bMid+1.2*bHi*smoothstep(1.5,4.,gen)+.5*chase*uLevel)*(.35+.65*ao)*fillK;
#if HD>=1
    {
      // v20 tiers: the bezel is set like a jeweller's: claws round it from Native, a milled outer edge from Cinema, a hairline inner
      // collet from Insane. Each appears only where its own marks are a pixel wide, in the disk's own colours, never toward white.
      float zA=atan(gDv.y,gDv.x),zG=floor(ga.y+.5),zN=8.+4.*mod(zG,3.),zW=ga.w*mw,zV=(.35+.65*ao)*fillK;
      vec2 cl=oamBd(grhoB,zA,bzR+.045,zN,.03,bzF);float clL=cl.x*smoothstep(.06,.022,bzF)*zW;
      c=c*(1.-.6*clL)+mix(heartC,lineC,.3)*clL*(.5+.9*bHM+.7*bMid)*zV;
#if HD>=2
      float mlN=zN*6.,mlL=step(.5,fract(zA*mlN/TAU))*oamLn(abs(grhoB-bzR-.105),.012,bzF)*smoothstep(.03,.012,bzF)*zW;
      c=c*(1.-.5*mlL)+lineC*mlL*.55*zV;
#endif
#if HD>=3
      float coL=oamLn(abs(grhoB-bzR+.07),.004,bzF)*smoothstep(.016,.006,bzF)*zW;
      c=c*(1.-.45*coL)+heartC*coL*.7*zV;
#endif
    }
#endif
    // lace: the mids, flashing on a mid onset; hats and the high band ignite the finest rims; the snare sweeps a wave
    float lineE=laceW*(.22+1.1*gsp2+.6*chase*(.4+uLevel)+1.9*bMid+1.7*wave*(.5+uHit)+1.2*dl+3.*shell+4.*wD*exp(-wT*7.)
      +(1.52*uHat+1.4*bHi)*mix(.42,1.,smoothstep(1.5,4.,gen))+3.*evBlack);
    lineE*=mix(.6,1.,smoothstep(18.,60.,cellPx));   // v20: the rose windows on the smaller bubbles (new this round) burn steadier: more detail, no more flashing
    float lx=ga.x*mw;lineC=mix(lineC,vec3(1.),.3*evBlack);
    c=c*(1.-.8*lx)+lineC*lx*lineE*(.35+.65*ao);
    {
      // fleeting: at the turn of every sixteen-bar phrase one class of windows (a different class each phrase) wears the legend in light for
      // about a bar, where a bead is two to three and a half screen pixels. hidden: one class in twenty-seven carries it for good, etched small
      // near the rim, readable only on a window zoomed to fill a good part of the frame.
      float hA=atan(gDv.y,gDv.x),hG=floor(ga.y+.5),hK=mod(gSH,9.),hPh=(uBar+5.)/16.,hF=fract(hPh);
      float hT=smoothstep(0.,.012,hF)*smoothstep(.062,.048,hF)*step(abs(hK-mod(floor(hPh)*4.+2.,9.)),.5)*step(abs(mod(hG,3.)-1.),.5);
      float hH=step(abs(hK-4.),.5)*step(abs(mod(hG+lb,3.)-2.),.5)*(1.-step(.001,hT));
      float hSel=max(hT,hH)*ga.w*mw;
      if(hSel>.003){
        float hh=hT>.001?.12:.055,r0=hT>.001?.55:.80,pw=hh/7.,sp=gDp*1.82*OAM_SS/OAM_PM,pp=pw/max(sp,1e-6);
        float vis=smoothstep(1.9,2.3,pp)*mix(1.,smoothstep(4.,3.3,pp),step(.001,hT));
        float up=step(0.,gDv.y),ha=mix(hA+1.5708,1.5708-hA,up);
        vec2 hp=vec2(30.+ha*(r0+.5*hh)/pw,(ga.z-r0)/pw);
        float ground=step(-2.,hp.x)*step(hp.x,62.)*step(-1.5,hp.y)*step(hp.y,8.5),ink=oamHm(hp);
        c*=1.-.8*ground*vis*hSel;
        c+=mix(lineC,vec3(1.),.25)*ink*vis*hH*ga.w*mw*(.5+.5*ao)*fillK*.9;
        kL+=mix(heartC,vec3(1.),.45)*ink*vis*hT*ga.w*mw*fillK*1.3;
      }
    }
    // v18: every resolved disk is a rose window: a slowly turning petal tracery that opens with the mids, inside a string of
    // pearls lit by the highs. Value only: the lines are near white and the petals darken or lift the glass already there.
    float trW=ga.w*mw*smoothstep(.09,.03,gDp),trL=0.,beadL=0.,beadH=0.;
    if(trW>.003){
      float gI=floor(ga.y+.5),rN=6.+2.*mod(gI,3.),rh=ga.z;
      float an=atan(gDv.y,gDv.x)+(mod(gI,2.)-.5)*uMT*.07;
      float aA=(.34+.46*midS),cA=cos(.5*rN*an),sA=sin(.5*rN*an);
      float rp=aA*abs(cA),rq=aA*.6*abs(sA),gr1=max(rh,.06);
      float dp=abs(rh-rp)/sqrt(1.+pow(aA*.5*rN*sA/gr1,2.)),dq=abs(rh-rq)/sqrt(1.+pow(aA*.3*rN*cA/gr1,2.));
      float pIn=smoothstep(rp+gDp,rp-gDp,rh);
      float pl1=1.-smoothstep(.011,.011+1.6*gDp,dp),pl2=1.-smoothstep(.007,.007+1.6*gDp,dq);
      trL=max(pl1,.7*pl2)*trW;
      c*=1.-trW*(.34*(1.-pIn)*(1.-rh*rh*.5)-.1*pIn)*(.55+.45*midS);
      c=c*(1.-.75*trL)+mix(heartC,vec3(1.),.45)*trL*(.1+1.2*midS+.4*wave*(.5+uHit)+.12*uKick)*(.4+.6*ao)*fillK;
      c+=mix(heartC,vec3(1.),.3)*pIn*trW*exp(-rh*rh*3.)*.35*midS*(.4+.6*ao)*fillK;
#if HD>=1
      {
        // v19: engraving by tier, in coloured ink at limited coverage: every layer bites the glass darker and draws its line in the disk's own
        // heart or lead colour, never toward white. Each layer appears only where its own line would be at least about a pixel wide.
        vec3 inkA=heartC*.9,inkB=mix(lineC,diskC,.5);float gv=.35+.65*ao;
        float cF=max(gDp,1e-4),bAn=rN*2.;
        // Native: a two-strand braid between the petals and the pearls, and flutes round the dome
        float brW=smoothstep(.03,.012,cF),bAm=.022;
        float b1=abs(rh-.74-bAm*sin(bAn*an)),b2=abs(rh-.74+bAm*sin(bAn*an));
        float brL=max(oamLn(b1,.0055,cF),.75*oamLn(b2,.0055,cF))*brW;
        float flW=smoothstep(.022,.009,cF),fN=rN*6.,fA=abs(fract(an*fN/TAU)-.5)*TAU/fN*rh;
        float flL=oamLn(fA,.0035,cF)*smoothstep(.3,.36,rh)*smoothstep(.62,.56,rh)*flW;
        c=c*(1.-.5*brL*trW)+inkA*brL*trW*(.28+.5*midS)*gv*fillK;
        c=c*(1.-.45*flL*trW)+inkB*flL*trW*.4*gv*fillK;
#if HD>=2
        // Cinema: a dentil ring and a seed bead between each pair of petals
        float dnW=smoothstep(.014,.006,cF),dnN=rN*14.,dnA=fract(an*dnN/TAU),dnL=step(.5,dnA)*oamLn(abs(rh-.665),.009,cF)*dnW;
        c=c*(1.-.5*dnL*trW)+inkB*dnL*trW*.5*gv*fillK;
        float sA=TAU/rN,sI=floor(an/sA)+.5,sD=length(vec2(rh-.2-.42*(.34+.46*midS),(an-sA*sI)*rh));
        float sL=(1.-smoothstep(.016-cF,.016+cF,sD))*smoothstep(.03,.012,cF);
        c=c*(1.-.6*sL*trW)+inkA*sL*trW*.9*gv*fillK;
#endif
#if HD>=3
        // Insane: fine hatching across the shadow side of the dome (a drawn shadow, the way an engraver would shade it)
        float hW=smoothstep(.0085,.0035,cF),hP=.022,hL=oamLn(abs(fract((gDv.x*.7071+gDv.y*.7071)/hP)-.5)*hP,.0045,cF)*hW;
        float hS=smoothstep(.15,-.5,dot(gDv,normalize(vec2(.8,.6))));
        c*=1.-.42*hL*hS*trW*(1.-.5*rh*rh);
        vec2 mcd=oamBd(rh,an,.4,rN*7.,.012,cF);
        c=c*(1.-.45*mcd.x*trW*smoothstep(.01,.004,cF))+inkB*mcd.x*trW*smoothstep(.01,.004,cF)*.6*gv*fillK;
#endif
#if HD>=4
        // Extreme and Offline: cross hatching, and a hairline scallop chain inside the pearls
        float h2W=smoothstep(.0052,.0022,cF),h2P=.013,h2L=oamLn(abs(fract((gDv.x*.7071-gDv.y*.7071)/h2P)-.5)*h2P,.0026,cF)*h2W;
        c*=1.-.3*h2L*hS*trW*(1.-.5*rh*rh);
        float scN=rN*18.,scA=abs(fract(an*scN/TAU)-.5)*TAU/scN,scD=abs(length(vec2(rh-.815,scA*rh))-.0115);
        float scL=oamLn(scD,.002,cF)*smoothstep(.0052,.0022,cF);
        c=c*(1.-.45*scL*trW)+inkA*scL*trW*.75*gv*fillK;
#endif
      }
#endif
      float bM=floor(rN*3.5),bs=TAU/bM,bi=floor(an/bs+.5),bd=length(vec2(rh-.875,(an-bs*bi)*rh));
      beadL=(1.-smoothstep(.03-gDp,.03+gDp,bd))*trW*smoothstep(.035,.014,gDp);
      c*=1.-.5*beadL;
      float bid=mod(bi,bM),tw2=fract(bid*.618+gI*.37);
      beadH=exp(-5.*fract(uBar*2.-bid/bM))*bHi+1.1*bHi*bHi+2.7*uHat*step(.5,tw2)+1.6*uO2.w*step(tw2,.5);
    }
    c+=mix(body,vec3(1.),.35)*evChase*.9*exp(-9.*abs(fract(uBar*2.-lb*.25-mod(gSH,3.)*.334)-.5))*(.3+.7*ao);
    // glowing seams: where bubbles meet their neighbours the crease lights up with the generation's band
    float seam=smoothstep(.12,.55,1.-ao);
    vec3 pw3=vec3(1.-smoothstep(-1.,1.,sz),0.,smoothstep(1.5,3.5,sz));pw3.y=1.-pw3.x-pw3.z;   // fine / middle / big
    float poreB=dot(pw3,vec3(bHi,bMid,bBass)),poreO=dot(pw3,vec3(uO2.z,uO1.w,uO1.y));
    c+=mix(creaseC,vec3(1.),.15)*seam*(.05+.4*sp2+1.1*poreB*poreB)*(.4+.6*fog)*fillK;
    // glowing sphere rims: each bubble cap's rim, where it meets the sheet it sits on, is a neon ring (low mids)
    float cr=gCr/max(pix*tt,1e-9);
    float creaseL=(1.-smoothstep(1.,3.5,cr/(1.+.22*bassB)))+.4*exp(-cr/9.);   // v14: the bass thickens the neon crease
    // (tiny bubbles are all crease: their rings would flood the whole jewel with the next colour, so the band light
    // rides the rings of the larger caps only)
    float crB=smoothstep(-1.,2.5,sz);
    c+=creaseC*creaseL*(.24+1.4*sp2+(.1+1.2*bLM)*crB+.8*dl+.4*uBuild+1.8*evBlack)*(.4+.6*ao);
    // glowing rims: iridescent Fresnel light at every curved silhouette; the big shells' rims ride the bass
    float fres=pow(1.-ndv,2.4-.65*bassB);
    c+=irid*fres*iridW*((.18+1.3*sp2)*(1.-.6*big)+1.35*bBass*big+.4*uBuild+.6*dl)*(.3+.7*ao);
    // small bubbles are jewels: they glow from inside with their slice of the spectrum
    float jw=smoothstep(2.5,-1.,sz);
#if HD>=1
    c+=nextC*jw*(.06+.5*sp2+1.02*bHi+.25*zo)*(.25+.75*ndv)*fillK*(1.-.6*smoothstep(-.5,-3.,sz));
#else
    c+=nextC*jw*(.06+.5*sp2+1.02*bHi+.25*zo)*(.25+.75*ndv)*fillK;
#endif
    c+=W*wsel*(.04+.08*ndv*ndv+.15*bSub*big)*(.5+.5*ao)*fillK;   // stained glass lit from within
    // thin-film fringes flowing over the sheets: the presence band brightens them, hats sharpen them
    float ph=th*(1.+1.4*ndv*(1.-.8*mw))*TAU*2.;
    float band=pow(.5+.5*cos(ph),12.+10.*uHat);
    c+=filmC*band*(.04+.35*fres)*(.4+.45*bPr*bPr+1.*uHat)*(.3*ao+.7*lit);
    // specular glints: the lantern's highlight; the highs make the fine foam sparkle, and the air band sets tiny
    // star points on the smallest bubbles (each sheet its own twinkle phase)
    vec3 reflected=reflect(rd,nn);
    float spc=pow(clamp(dot(reflected,L1),0.,1.),mix(30.,90.,jw));
    float tw=fract(gTr*7.31+lb*.37);
    c+=camCol*spc*(.45+.9*jw*(.3+.25*bHi+1.6*uHat))*lit;
    float sp4=spc*spc;sp4*=sp4;   // tight star glints (the broad lobe would wash the jewels grey)
    c+=mix(camCol,nextC,.35)*sp4*jw*(.8*bAir+(.6*bHi+3.*uO2.w)*step(.5,tw)+3.*uO2.z*step(tw,.5))*2.*lit;
    // snare shell sweeping through depth
    float wv=exp(-pow((tt-waveR)/waveW,2.))*wave;
    c+=mix(nextC,vec3(1.),.2)*wv*(.12+2.2*lx+.8*creaseL)*(.4+.6*ndv)*1.1*(.5+uHit);
    // the palette front: a shell of white-hot light in the new colours, tracing every rim and lace line it crosses
    shC=mix(nextC,vec3(1.),.3)*shell*(.15+1.7*lx+1.*creaseL+1.1*fres+.4*seam)*(.3+.7*fog);
#if HD>=1
    {
      // v19: one true reflection bounce on the glass: the ray continues from the sheet and takes the colour of the sheet it finds.
      // v20: from Native up (it was Cinema up; Native was 8 ms a frame at 1080p), and from Cinema up the reflected sheet shows its own
      // rose-window lace and domes instead of a flat colour.
      float sSH=gSH,sDp=gDp;
      // Fresnel-weighted mix (not an add), so it replaces the fill at grazing angles and can never sum toward white.
      vec3 rR=reflect(rd,nn),rO=pos+nn*eps*3.;
      float rT=max(eps*5.,aoS*.03),rE=min(tt*1.2+fogL*.8,maxT),rH=0.,rV=0.;
      int rS=int(12.*det);
      for(int j=FO0;j<200;j++){
        if(j>=rS||rT>rE)break;
        gFoot=max(eps,pix*(tt+rT)*pixelFactor);
        rV=map(rO+rR*rT);
        if(rV*.4<gFoot){rH=1.;break;}
        rT+=rV*.4;
      }
      float rfF=1.-ndv;rfF=.06+.62*rfF*rfF*rfF;
      vec3 rC=mix(gC0,gC1,.25)*.25;
      if(rH>.5){
        vec3 rP=rO+rR*rT;
        born(rP,max(rV,gFoot*2.));
        vec3 rN2=gSurfN;if(dot(rN2,rR)>0.)rN2=-rN2;
        float rB=uP1.y+gB;
        float rK3=mod(gSH,3.);vec3 rb=pk(rotC+rB*.2+.04*log2(1.+gTr)+.2*rK3-.2);rb=mix(rb,gCX,.88*step(1.5,rK3));
        float rFog=exp(-rT/fogL*1.1);
#if HD>=2
        {vec4 rg=oamGasket(gQ.xz+vec2(.13,.07),max(pix*(tt+rT)*gSB*.55,1e-6),det);
         float rmw=smoothstep(5.,26.,1./max(gSB*pix*(tt+rT),1e-9));
         rb*=mix(1.,(.3+.8*rg.z*rg.z)*(1.-.7*rg.x)+2.4*rg.x,rmw);}
#endif
        rC=mix(rC,rb*(.22+.8*max(dot(rN2,-rR),0.))*(.8+.2*mod(rB,3.)),rFog);
      }
      {float rL=dot(rC,vec3(.2126,.7152,.0722));rC=max(rL+(rC-rL)*1.2,0.);}
      c=mix(c,rC*(.35+.65*ao)*fillK,rfF*(.55+.45*mw));
      gSH=sSH;gDp=sDp;
    }
#endif
    // distant shells are never dead: they keep a soft glow of their own generation colour
    c+=body*.08*(1.-exp(-tt/fogL*1.5))*(.6+.8*sp2);
    // depth: nearer shells keep their colour, distant ones dissolve into the jewel haze
    float xr=EV.z;
    if(xr>.001){
      float xh=fract(ldL*.16-uMT*.3+gen*.07);vec3 sg=mix(oamSpec(.62*(1.-abs(2.*xh-1.))),vec3(1.),.12);   // red, magenta, violet, blue, cyan and back: never the olive side
      vec3 xg=sg*(.36+.7*fres+.2*ndv)*(1.-.85*lx)*(1.-.7*clamp(creaseL,0.,1.))+vec3(1.)*pow(fres,3.)*.6;
      c=mix(c,xg,xr);
    }
    // onset light: each hit lights its own part (kick = rims, lace and pores; bass onset = big rims and pores; low mid =
    // crease rings; mid = lace and middle pores; hi-mid = medallion hearts; high = jewels and fine pores)
    kL=(lineC*lx*laceW*(1.1*uO1.w+.56*uKick)+creaseC*creaseL*crB*1.1*uO1.z+irid*fres*iridW*(.4*uKick+.7*uO1.y*big)
       +mix(creaseC,vec3(1.),.2)*seam*(1.1*poreO+.1*uKick)+mw*heartC*exp(-grhoB*grhoB*5.)*1.1*uO2.x+nextC*jw*.8*uO2.z*(.25+.75*ndv)
       +mix(body,vec3(1.),.25)*(.008*uKick+.05*uO1.y*big)*(.4+.6*ndv))
       *(.35+.65*ao)*fog*fillK*(1.-.6*xr);
    // v14: a thin white-hot lace and crease-core line layer after the gamut knee: the fine structure keeps a fixed
    // brightness over the fills, so the fractal reads even in a warm palette of one value. Mostly white (value, not
    // chroma), and the crease term uses the crisp core only: a broad halo would lift the darks and flatten the frame.
    kL+=mix(lineC,vec3(1.),.78)*beadL*(.12+.75*beadH)*(.35+.65*ao)*fog*fillK;
    kL+=mix(heartC,vec3(1.),.35)*bzL*(.5*min(snA*16.,1.)*exp(-snA*5.)*(.5+uHit)+.2*uO1.z+(.4*uHat+.55*bHi*bHi+.25*uO2.z)*step(fract(ga.y*.37+gSH*.29),.5))*(.35+.65*ao)*fog*fillK;   // v20: the snare strikes every bezel
    // v20: the kick drops a ripple into every rose window: one thin ring runs from each heart out to its rim while the pulse decays
    // (its radius is the pulse itself, and it is dark at both ends, so nothing pops or strobes)
    {float kr=1.-uKick,kRing=(1.-smoothstep(.035,.035+1.5*bzF,abs(grho-.08-.86*kr)))*uKick*kr*4.*mw*smoothstep(.2,.07,bzF);
     kL+=mix(heartC,vec3(1.),.3)*kRing*.3*(.35+.65*ao)*fog*fillK;}
    // v18: hats and highs read at every distance: a pin of light in each resolved disk (half the generations on the hats, half on
    // the air onsets) and the lace lines themselves, after the knee so they are not compressed away
    float pS=max(.11,1.4*gDp),pinL=ga.w*mw*step(gDp,.5)*exp(-ga.z*ga.z/(pS*pS)),pT=fract(ga.y*.37+gSH*.29);
    kL+=mix(lineC,vec3(1.),.75)*pinL*(.1+.95*uHat*step(.5,pT)+.6*uO2.w*step(pT,.5)+.5*bHi*bHi)*(.35+.65*ao)*fog*fillK;
#if HD>=1
    kL+=mix(lineC,vec3(1.),.2)*lx*laceW*(.22*uHat+.25*bHi*bHi)*(.35+.65*ao)*fog*fillK;
#else
    kL+=mix(lineC,vec3(1.),.6)*lx*laceW*(.22*uHat+.25*bHi*bHi)*(.35+.65*ao)*fog*fillK;
#endif
    // v18: a heartbeat: on the bass a band of light goes out through the depth of the foam every two beats, lighting the
    // rims and seams it passes while the shells between sink (a redistribution, so the auto-exposure cannot cancel it)
    kL+=1.12*(irid*fres*.55+creaseC*creaseL*.38+lineC*lx*.2)*hbP*basS*fog*(.35+.65*ao)*fillK;
#if HD>=1
    kL+=(mix(lineC,vec3(1.),.15)*lx*laceW*.1+creaseC*(1.-smoothstep(1.2,2.8,cr))*.14)*(.35+.65*fog)*fillK*(.35+.65*ao);
#else
    kL+=(mix(lineC,vec3(1.),.72)*lx*laceW*.14+creaseC*(1.-smoothstep(1.2,2.8,cr))*.2)*(.35+.65*fog)*fillK*(.35+.65*ao);
#endif
    // v14: zoomed far out the gaps between the shells went almost black; the haze floor grows with the pull (zoom 1 unchanged)
    aKx=max(accW,cxS)*fog;
  vec3 haze=mix(gC0,gC1,.12+.25*neb)*.2*(1.+.3*uBuild+.2*bSub)*(1.+1.25*zo)*(1.-.85*evBlack);
    col=mix(haze,c,mix(fog,sqrt(fog),wsel));   // the fire keeps its colour deeper into the haze (red + teal haze = mud)
    // where the carved hall cuts a sheet, its section is a thin bright line (a cutaway, drawn on purpose)
    // the cut faces sink dark behind one crisp bright section line, so the cutaway reads sharp instead of as soft bands
    col+=cutM*(heartC*.25*exp(-grhoB*grhoB*4.)+lineC*lx*.4)*fog;
  }
  vec4 EV=oamEv();float evBlack=EV.x,evRing=EV.w,sF=mod(uP5.w,4.),lampW=1.+.8*(smoothstep(2.,3.,sF)-smoothstep(3.,4.,sF));   // the lantern style (3) has the brightest lamps
  // neon outlines on every rim the view slips past, coloured by depth, pulsing with the bass
  float rimL=(1.-smoothstep(1.2,6.,edge))*exp(-edgeT/fogL*.5)*step(edgeT,tt);
  vec3 rimC=rimCol*rimL*(.3+.8*uKick+1.*bBass+.5*uO1.y+.7*dl+.2*uBuild+2.*evBlack)*uDose/(1.+.5*uBuild+.9*uDrop);
  // the grazing glow is soft by nature: kept low (it blurred the foam) and handed to the sub, so it swells with the bass
  col+=(glowC*(1.-.7*evBlack)+oamSpec(gzz*.7-uMT*.3)*EV.z)*gw*(.07+.05*uKick+.4*bSub*bSub+.25*uBuild+.3*EV.z)*uDose;
  // soft gamut knee: saturated fills stop short of clipping after exposure (dark hues such as blue, violet and red
  // reach the screen's limit sooner than cyan or gold); it also absorbs the engine's build exposure and drop flash,
  // so only the thin outlines and lanterns added after it flare
  col/=(1.+.3*uBuild)*(1.+.6*uDrop*uDrop);
  // a gentle chroma lift keeps the jewels saturated (more when zoomed out, where far fills would otherwise read grey)
  {float L=dot(col,vec3(.2126,.7152,.0722));col=max(L+(col-L)*(.70+.2*zo),0.);}   // v14: a small notch less chroma, keeping saturation below the old level
#if HD>=1
  {float cL=dot(col,vec3(.2126,.7152,.0722));col=max(cL+(col-cL)*(1.+.014*float(HD)+.034*step(1.5,float(HD))),0.);}   // v20: Cinema up measured .03 to .04 under High in saturation
#endif
  float cm=max(col.r,max(col.g,col.b));
  float kn=mix(.28,.57,smoothstep(.07,.7,dot(col,vec3(.2126,.7152,.0722))/max(cm,1e-4)))/((1.+.6*uBuild)*(1.+.7*uDrop));kn*=1.-.2*aKx;
  col*=cm>kn?(kn+.6*kn*(1.-exp(-(cm-kn)/(.6*kn))))/cm:1.;
  {float cl=dot(col,vec3(.2126,.7152,.0722));col=max(cl+(col-cl)*(1.+.42*aKx),0.);}
  col+=rimC/(1.+.6*dot(rimC,vec3(.3333)));
  col+=shC/(1.+.5*dot(shC,vec3(.3333)));
  kL*=1.15;col+=kL*uDose/(1.+.8*dot(kL,vec3(.3333)));   // v12: hits light softer (they were jolts)
  // the gap lanterns are visible: glowing orbs hanging in the gaps, breathing with the bass, flaring on its onsets
  if(lampsOn>.5){
    for(int l=FO0;l<2;l++){
      float weight=l==0?uM2[2].x:uM2[2].y;if(weight<.002)continue;
      vec3 v=(l==0?uM2[0]:uM2[1])-ro;
      float along=dot(v,rd),tc=clamp(along,0.,maxT);
      float dd=length(v-rd*tc);
      float R=sc*.035*(1.+.5*bBass+.4*uKick+.4*uBuild);
      float g=R*R/(dd*dd+R*R);
      float behind=(hit>.5&&along>tt?.15:1.)*smoothstep(sc*.4,sc*2.5,along);   // no blinding blob as a lantern passes the lens
      col+=lampCol*weight*lampW*behind*(g*g*4.+g*.08)*(1.+.3*uKick+1.*bBass+.4*uO1.y+.4*uDrop+evBlack)*(along>0.?1.:0.);
      // v20: each lantern is a made thing, not a blur: a crisp core in a ring that rides the bass spring, and eight slow rays that
      // lengthen on the kick. Drawn only where it is large enough on screen to resolve.
      {vec3 pv=v-rd*tc;float la=atan(dot(pv,uM1[1]),dot(pv,uM1[0])+1e-9),lr=dd/R,lf=pix*max(tc,sc*.2)/R,lR=1.75+.35*basS;
       float lRing=1.-smoothstep(.07,.07+1.5*lf,abs(lr-lR)),lCore=1.-smoothstep(.6-lf,.6+lf,lr);
       float lRay=pow(abs(cos(4.*la+uMT*(l==0?.2:-.2))),30.)*smoothstep(lR+1.6+2.2*uKick,lR+.2,lr)*step(lR,lr);
       col+=mix(lampCol,vec3(1.),.25)*weight*lampW*behind*(lRing*.8+lCore*.9+lRay*.7)*smoothstep(.3,.1,lf)*(.6+.5*bBass+.4*uO1.y)*(along>0.?1.:0.);}
      // v18: soap bubbles adrift round the lantern: real spheres in the world, swelling on the bass spring. Only their film and
      // rims are drawn, so the foam shows through them; the presence band runs the film, the highs set a star on each
#if HD>=1
      for(int b=FO0;b<7+6*HD;b++){
#else
      for(int b=FO0;b<7;b++){
#endif
        float h0=float(b)+float(l)*7.,h1=fract(h0*.618+.13),h2=fract(h0*.382+.71),h3=fract(h0*.271+.37);
        float oa=h1*TAU+uMT*(.05+.05*h2),oe=(h2-.5)*2.4+.35*sin(uMT*.09+h0);
        vec3 ov=vec3(cos(oa)*cos(oe),sin(oe),sin(oa)*cos(oe));
        vec3 bc=v+sc*(.35+1.5*h3)*ov;
        float br=sc*(.05+.17*h2*h2+.06)*(1.+.3*basS+.04*sin(uMT*.4+h0*2.));
        float bb=dot(bc,rd),bh=bb*bb-dot(bc,bc)+br*br;
        if(bh>0.){
          float bt=bb-sqrt(bh);
          if(bt>0.&&(hit<.5||bt<tt)){
            vec3 bn=(rd*bt-bc)/br;float bv=clamp(-dot(bn,rd),0.,1.),bF=1.-bv;
            float fr=bF*bF*bF,edgeA=smoothstep(0.,pix*bt*2.5/br,bv);
            vec3 fm=mix(oamSpec(fr*1.4+bn.y*.35+uMT*.06+h1),vec3(1.),.16);   // v20: the film keeps its colour (it was half white: pale rings over the scene)
            float bk=weight*edgeA*smoothstep(sc*.3,sc*1.4,bt)*exp(-bt/fogL*.8);
            col*=1.-bk*.3*fr;
            col+=fm*fr*bk*(.75+1.1*bPr*bPr+.3*basS);
            float sg=pow(max(dot(bn,normalize(uM1[1]-uM1[2]*.4-rd*.2)),0.),160.);
            col+=vec3(1.)*sg*bk*(.5+2.4*bHi+2.*uHat);
          }
        }
      }
    }
  }
  // build: a ring of lanterns closes around the gap being threaded, spinning faster and pulsing on the eighths
  // (centred on the threaded gap when one is in view, else on the view axis)
  // on the drop the ring bursts: the lanterns fly outward off the screen and fade; the ring event floats one in a phrase
  float dX=step(uP1.w,8.5),burst=dX*exp(-uP1.w*2.2);   // a drop wipe is running when uP1.w < 8.5 (it is its age)
  float bw=max(max(smoothstep(.05,.35,uBuild),burst),evRing);
  if(bw>.001){
    vec2 dg=lp-gc*win;float ra=length(dg);
    float rr=mix(.5,clamp(gr,.12,.6),win)*mix(2.,.8,smoothstep(0.,1.,max(uBuild,step(.001,burst))))*(1.+dX*min(uP1.w,3.)*(4.+8.*min(uP1.w,3.)))
      ;
    rr=mix(rr,.34*(1.+.12*bBass),evRing*(1.-uBuild));
    float an=atan(dg.y,dg.x)+uMT*(.4+2.2*uBuild)-evRing*uBar*TAU*.25;
    float sec=TAU/14.,li=floor(an/sec+.5),ai=an-sec*li;
    vec2 bq=vec2(ra-rr,ai*rr);
    float br=rr*.04*(1.+.5*bBass)*(1.+.6*evRing),bl=length(bq)/br,bpx=pix/br;
    float pulse=.55+.45*pow(1.-fract(uBeat*2.),3.);
    // each lantern: a crisp jewel disk with a bright rim and a soft halo
    float jewel=smoothstep(1.+bpx,1.-bpx,bl)*(.35+.65*bl*bl)+.5*exp(-abs(bl-1.)/(bpx+.05));
    float ch=exp(-6.*fract(uBeat*.5+uBar*.5-li/14.));   // the ring event chases round on the beat
    vec3 lc=mix(lampCol,mix(oamSpec(li/14.+uMT*.05),vec3(1.),.2),evRing);
    col+=lc*bw*(1.5*jewel+.12/(1.+bl*bl))*mix(pulse,1.,burst)*(1.+.5*uBuild+burst+.5*uO2.y+evRing*(2.*ch-.3))*uDose;
    col+=lc*evRing*exp(-abs(ai)*ra/(pix*1.5+.006*ra))*smoothstep(.05,1.,ra/rr)*step(ra,rr)*(.4+1.4*ch)*(1.-uBuild);
    // a faint halo line joins the lanterns
    col+=lampCol*bw*.35*exp(-abs(ra-rr)/(rr*.012+pix))*max(uBuild,.5*evRing);
  }
#if HD>=2
  // v20: the screen shows the average of OAM_SS squared samples, and averaging thin bright lace with the dark glass beside it costs
  // chroma. A last per-sample chroma step by tier holds the downsampled picture at High's saturation.
  {float eL=dot(col,vec3(.2126,.7152,.0722));col=max(eL+(col-eL)*(1.+.028*OAM_SS),0.);}
#endif
  fragColor=vec4(col,0.);fragWin=vec4(.5,.5,0.,1.);
}
`;
