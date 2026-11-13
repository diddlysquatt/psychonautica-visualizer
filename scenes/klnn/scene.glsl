const R_KLNN = `
// KLNN. Flight through Knighty's pseudo-Kleinian group, tiled into an endless lattice of curling naves and shafts.
// Look: curated jewel palettes (deep / body / edge A / edge B / atmosphere), luminous aerial depth (near bays in
// deep body tones, far bays dissolving into a glowing atmosphere), emissive silhouette halos coloured by depth,
// fresnel rims, neon tracery and spectral pearl necklaces. The inversion size and rim radius vary across space so
// successive bays are different buildings rather than one repeated sheet.
float knSquarePortable(float x){return x*x;}
vec2 kQ;vec4 kTr;float kDF,kFoot,kIt,kLod,kRr,kSl,kBr,kCd,kCb;vec3 kP;
vec3 kc0,kc1,kc2,kc3,kc4;float kRs;
// per-visit inversion structure: a twist (cos,sin) and a shift applied after every inversion (both isometries)
vec3 kSh=vec3(0.);
// D3D compile cost: the HLSL compiler expands every call site inline and unrolls constant-trip loops. Loops start
// at KN0, a zero it cannot fold (uTime>=0); surface taps and the three shadow rays each share
// one expansion.
#define KN0 min(int(uTime),0)
#define KSKY (2+HD)
// the great hall (zoomed out, breakdown vistas, drop blasts): an elliptic barrel vault carved along x through the lattice
// (smooth everywhere: the old pointed vesica showed a hard crease along its ridge), its axis on the camera's nave
// (y = uM1[1].y, z = C.z), half-height kHB, half-width kHA: each opening of the hall picks a section (gothic, barrel,
// slender) and a rib rhythm, and a long-held hall glides from one section to another. The vault is convex, so a ray
// from inside leaves it once: kHall returns that distance, the march starts there and the hall costs nothing in the loop.
float kHA,kHB,kXA,kXP,kXR;vec3 kHO;
// the ray's interval inside an elliptic cylinder (o, d in its section plane, semi-axes ab); empty = (1e9,-1e9)
vec2 kEll(vec2 o,vec2 d,vec2 ab){
  o/=ab;d/=ab;float A=max(dot(d,d),1e-8),B=dot(o,d),D=B*B-A*(dot(o,o)-1.);
  return mix(vec2(1e9,-1e9),(vec2(-B,-B)+vec2(-1.,1.)*sqrt(max(D,0.)))/A,step(0.,D));
}
float kHall(vec3 ro,vec3 rd){
  vec3 o=ro-vec3(0.,uM1[1].y,uP1.z);kHO=o;
  float t=kEll(o.zy,rd.zy,vec2(kHA,kHB)).y;
  vec3 e=o+rd*t;
  // v13: crossings. Every kXP along the hall a domed transept crosses it: an ellipsoid as tall as the hall, kXA wide
  // along the hall and reaching 2.4 hall half-widths out to each side, where it ends in a rounded apse. Where the ray
  // leaves the hall inside a transept it carries on to the transept's vault, so the long barrel opens into side halls
  // with their own walls of rose windows. (Both are convex and the transepts are disjoint: one hand-over.)
  if(kXA>.05){
    float xc=floor(e.x/kXP+.5)*kXP;vec3 ab3=vec3(kXA,kHB,kXR*kHA),q=vec3(e.x-xc,e.yz)/ab3;
    if(dot(q,q)<1.){
      vec3 o3=vec3(o.x-xc,o.yz)/ab3,d3=rd/ab3;float A=max(dot(d3,d3),1e-8),B=dot(o3,d3),D=B*B-A*(dot(o3,o3)-1.);
      t=max(t,(-B+sqrt(max(D,0.)))/A);
    }
  }
  return t;
}
// atan(y,x) to ~1e-5 rad (a minimax polynomial: the emulated atan2 cost ~26 instruction slots per use)
float kAt(float y,float x){
  vec2 a=abs(vec2(x,y));float m=min(a.x,a.y)/max(max(a.x,a.y),1e-12),q=m*m;
  float r=((-.0464964749*q+.15931422)*q-.327622764)*q*m+m;
  r=mix(r,1.5707963-r,step(a.x,a.y));r=mix(r,3.1415927-r,step(x,0.));return y<0.?-r:r;
}
float kdeR(vec3 p){
  vec3 C=uP1.xyz;
  // the architecture drifts across space: neighbouring bays differ, the far end of the nave is another building
  float w=sin(dot(p,vec3(.43,.31,.19))+uM2[2].y);
  float S=clamp(uP1.w+uM2[2].x*w,.6,.885);kSl=S;
  kRr=uP3.x+.06*cos(dot(p,vec3(.27,-.37,.21))+uP3.y-8.*step(8.,uP3.y)); // uP3.y: rim drift phase + 8 x window kind
  p=C-abs(mod(p+C,4.*C)-2.*C); // the box reflections tile space: fold into one cell
  float DF=1.;vec4 tr=vec4(1e3);vec2 qm=vec2(1.,0.);
  for(int i=KN0;i<32;i++){
    if(float(i)>=kIt)break;
    p=2.*clamp(p,-C,C)-p;
    float r2=max(dot(p,p),1e-6);
    qm=mix(qm,p.xy,step(r2,tr.w)); // v20: where the orbit came closest: with r2 it gives conformal coordinates for the enamel
    tr=min(tr,vec4(abs(p),r2));
    float k=max(S/r2,1.);
    p*=k;DF*=k;
    p+=kSh;
    if(DF*kFoot>kLod)break; // LOD: stop once the next level of detail would be under a pixel
  }
  kTr=tr;kDF=DF;kP=p;kQ=qm;
  float e=uP2.w,rxy=length(p.xy);
  float radial=rxy-kRr,slab=(abs(rxy*p.z)-e)/sqrt(dot(p,p)+e);
  float base=max(radial,slab);
  // (the carved relief that only showed at detail >= 1.25 was retired: its compile budget now pays for the great hall,
  // its neon arches and pearl necklaces, which every zoomed-out view, breakdown and drop blast shows)
  // v18: the great discs are pierced. Every wall-sized plate is the fundamental annulus carried out by the group, so an
  // opening cut in the folded coordinates lands on all of them as conformal, ring-following lace: bars stay, the panes
  // between them are gone and the view carries on through into the next nave. Only the biggest images open (the fine
  // crust keeps its density), and the bass breathes the width of the bars.
  float aN=fract(kAt(p.y,p.x)*2.5464791+.5),dBar=abs(aN-.5)*.3926991*rxy,big=(1.-smoothstep(2.6+.8*float(HD),6.+2.2*float(HD),DF))*(1.-smoothstep(.25*kLod,.6*kLod,DF*kFoot)); // v20: from Native up, smaller discs are pierced as well: real lace, not paint
  float cut=min(dBar-kBr,kRr-.03-rxy)-(1.-big)*.4;kCd=cut;kCb=base;
  return max(base,cut)/DF;
}


// ---- curated palettes: deep, body, edge A, edge B, atmosphere (linear-ish sRGB picks, squared on load)
// (a constant table: the D3D compiler turns it into an immediate constant buffer, one read per colour, where the old
// if-chain cost ~50 instruction slots per palette)
const vec3 KPAL[40]=vec3[40](
  vec3(.14,.05,.40),vec3(.56,.24,1.),vec3(0.,.92,1.),vec3(1.,.18,.62),vec3(1.,.34,.80),     // amethyst / cyan / pink, orchid light
  vec3(.02,.14,.16),vec3(0.,.80,.62),vec3(.80,.40,1.),vec3(1.,.26,.62),vec3(.62,.46,1.),    // malachite, violet and pink, violet light
  vec3(.18,0.,.24),vec3(.92,.06,.34),vec3(1.,.84,.34),vec3(.15,.92,1.),vec3(1.,.50,.78),    // ruby cathedral, gold and turquoise, plum depths, rose-orchid light
  vec3(0.,.06,.30),vec3(.10,.36,1.),vec3(.60,.97,1.),vec3(1.,.26,.80),vec3(1.,.62,.46),     // sapphire, ice and magenta, peach light
  vec3(.14,0.,.34),vec3(.90,.10,.60),vec3(1.,.60,.05),vec3(0.,.90,1.),vec3(.58,.40,1.),     // synth sunset, orange and cyan, violet light
  vec3(0.,.18,.26),vec3(.10,.84,.90),vec3(1.,.36,.46),vec3(1.,.60,.16),vec3(1.,.42,.62),    // jade and coral, rose light
  vec3(.02,.16,.10),vec3(.50,.95,.10),vec3(1.,.20,.80),vec3(.20,.70,1.),vec3(.25,.95,1.),   // acid: lime, magenta and azure, aqua light
  vec3(.16,.04,0.),vec3(1.,.48,.06),vec3(.35,.75,1.),vec3(1.,.16,.40),vec3(.70,.50,1.));    // copper, sky and crimson, lilac light
#if HD>=1
float hh1(vec3 p){return fract(sin(dot(floor(p*17.),vec3(12.9898,78.233,37.719)))*43758.55);}
#endif
vec3 kMixP(vec3 a,vec3 b,float m){vec3 c=mix(a,b,m);return c*c;}
// rotate a colour's hue about the grey axis (keeps saturation, so face gradients never pass through grey)
// (by +-1 rad: the constants are cos 1 and sin 1)
vec3 kRot(vec3 v,float h){float ca=.540302,sa=.841471*h,k=.57735,o=(1.-ca)/3.;
  return max(mat3(ca+o,o+k*sa,o-k*sa, o-k*sa,ca+o,o+k*sa, o+k*sa,o-k*sa,ca+o)*v,0.);}
void kLoadPal(float m){
  // uM2[0].x packs the current palette and the next one (pi + 8 pn)
  float pA=mod(uM2[0].x,8.),pB=floor(uM2[0].x/8.+.01);
  int ia=5*int(min(pA+.5,7.)),ib=5*int(min(pB+.5,7.));
  // small hue rotation from the global hue drift and the visit's offset
  float h=.2*sin((uHue+uP3.z)*TAU),ca=cos(h),sa=sin(h),k=.57735,o=(1.-ca)/3.;
  mat3 H=mat3(ca+o,o+k*sa,o-k*sa, o-k*sa,ca+o,o+k*sa, o+k*sa,o-k*sa,ca+o);
  kc0=max(H*kMixP(KPAL[ia],KPAL[ib],m),0.);kc1=max(H*kMixP(KPAL[ia+1],KPAL[ib+1],m),0.);kc2=max(H*kMixP(KPAL[ia+2],KPAL[ib+2],m),0.);
  kc3=max(H*kMixP(KPAL[ia+3],KPAL[ib+3],m),0.);kc4=max(H*kMixP(KPAL[ia+4],KPAL[ib+4],m),0.);
  // which way the face interiors turn in hue, per palette (bits 1,3,5,6 = +): always away from olive yellow
  kRs=mod(floor(106./exp2(m<.5?pA:pB)),2.)*2.-1.;
}
// position t in 0..1 along deep>body>edgeA>edgeB (never through grey)
vec3 kRamp(float t){
  t=clamp(t,0.,1.)*3.;
  return t<1.?mix(kc0,kc1,t):(t<2.?mix(kc1,kc2,t-1.):mix(kc2,kc3,t-2.));
}
// v20: the drawn ornament inside one pane. q runs -1..1 across the pane's short side, kd picks one of six figures, e is one pixel in
// q units. Returns (line, fill): an ink line and a second-tone fill, both antialiased, so a pane is a designed piece of glass at any size.
vec2 kMotif(vec2 q,float kd,float e){
  float d,d2=1e3;vec2 a=abs(q);
  if(kd<1.){ // rosette of eight petals
    float r=length(q),th=kAt(q.y,q.x);d=r-(.56+.26*abs(cos(th*4.)));d2=abs(r-.2);
  }else if(kd<2.){ // nested lozenges
    float m=a.x+a.y;d=abs(m-.62)-.2;d2=abs(m-.2);
  }else if(kd<3.){ // quatrefoil
    float m=min(length(vec2(a.x-.4,a.y)),length(vec2(a.x,a.y-.4)));d=m-.38;d2=abs(length(q)-.15);
  }else if(kd<4.){ // eight-point star
    float th=abs(fract(kAt(q.y,q.x)*1.2732395+.5)-.5)*.7853982,r=length(q);d=r*cos(th-.3927)-.3-.34*cos(th*2.);d2=abs(r-.13);
  }else if(kd<5.){ // an eye: a vesica with an iris
    float m=length(vec2(a.x,a.y+.72))-1.12;d=m;d2=abs(length(q)-.24);
  }else if(kd>5.5){ // v20b second pass: a ringed disc (far blocks)
    float r=length(q);d=r-.74;d2=abs(r-.42);
  }else{ // fish scales, two courses
    vec2 g=q*1.5;g.x+=.5*step(0.,g.y);vec2 c=fract(g+.5)-.5;float m=length(c-vec2(0.,-.4))-.62;d=m/1.5;d2=abs(m)/1.5;
  }
  float lw=.035+e*.7;
  float line=1.-smoothstep(lw-e,lw+e,min(abs(d),d2));
  return vec2(line,1.-smoothstep(-e,e,d));
}
void realm(){
  // zoom: the view widens to ~117 deg at most (never a fisheye); below that the hall opens and the camera rises (JS)
  float zf=max(uZoom,.72);
  vec2 p=scr()/zf;
  // structure family of this visit (packed as the integer part of uP3.z; the hue only uses the fraction)
  // structure family, morphing continuously between the classic nave (0), ribbed trumpets (1) and feather rims (2)
  float kv=uM2[1].z;
  kSh=mix(vec3(0.,0.,.14*kv),vec3(.07*(kv-1.),0.,.14-.06*(kv-1.)),step(1.,kv));
  // uM1 rows: camera right, hall (radius, axis y, lantern level), camera forward; up = right x forward
  vec3 ro=uP2.xyz,cu=uM1[0],cw=uM1[2],cv=cross(cu,cw);
  float hR=uM1[1].x;
  kBr=floor(uM2[2].z*.5)*.0005;
  // the hall's style: uM1[1].z packs the arch level (fraction) and the section's width/height (2 x 200ths);
  // the integer part of uP3.z (the hue only reads its fraction) packs the rib rhythm
  float aq=floor(uM1[1].z*.5),lant=uM1[1].z-2.*aq,hsty=floor(uP3.z+.5);
  kHB=.9*hR;kHA=kHB*aq/200.;
  float P=4.*uP1.x;
  kXP=10.*P;kXA=.8*kHA*smoothstep(3.,8.,hR);
  // v20b: the widest halls have no transepts, and on the way there they narrow and grow shallow. A ray grazing the wall into one crossed the whole chamber, so its far
  // side stood three times farther off than the wall around its mouth: far-field scale inside a hard round outline, which read as a giant ball let into the wall
  kXA*=1.-smoothstep(9.,17.,hR);kXR=mix(2.4,1.4,smoothstep(8.,14.,hR));
  vec2 lp=p+uLook*vec2(.5,.35);
  float kS=uM2[1].y,snr=uM2[1].x,hat=uHat*uDose,flash=mod(uM2[2].z,2.),ecl=uM2[0].y;
  float fo=.75-.03*kS+.1*uBuild;
  vec3 rd=normalize(lp.x*cu+lp.y*cv+fo*cw);
  float det=clamp(uDetail,.5,16.);
  float px=1.1/(uRes.y*zf*fo);
  kIt=floor(min(32.,4.5+2.*det));
  kLod=.9*sqrt(det);
#if HD>=1
  kIt=min(32.,kIt+float(HD)*1.5);kLod*=1.+.18*float(HD);
#endif
  float FAR=30.+2.*max(det-2.,0.)+3.*hR,t=.09,d=1.,glow=0.,glowT=0.;bool hit=false;
  float nst=50.+50.*det;
  // inside the hall the march starts where the ray leaves it. v19: the hall is a void and never a surface. The march used
  // to stop on the cut wherever the vault sliced solid stone and shaded it with the vault's own smooth normal: that was the
  // giant plain pink or blue wall. Now a ray that starts inside stone passes straight through to open space (thr) and goes on
  // to the real fractal behind. The void also ends: a ray running down the axis rejoins the lattice at .55 FAR, so the far
  // end of the hall is more fractal and no longer a hard-edged oval of sky (the "ball" at the vanishing point).
  float tHr=hR>.02?kHall(ro,rd):0.,tH=min(tHr,.55*FAR);t=max(t,tH);
  bool thr=tH>0.;
  for(int i=KN0;i<850;i++){
    if(float(i)>=nst)break;
    kFoot=px*t;
    d=kdeR(ro+rd*t);
    float tol=px*t*.6/sqrt(det),stp=.85*d;
    if(thr&&d<tol)stp=max(-d,0.)+max(1.5*tol,.004);
    else{
      thr=false;
      float segment=max(0.,min(stp,FAR-t));
      float g=exp(-max(d,0.)*90.)*segment/(1.+t*.35);
      glow+=g;glowT+=g*t;
      if(d<tol){hit=true;break;}
    }
    if(t>FAR)break;
    t+=stp;
  }
  // a ray still boring through dense stone when the step budget ran out counts as having met it
  hit=hit||(thr&&t<FAR);
  // a palette change arrives from the vanishing point and sweeps toward the camera, a glowing front between them
  // the front moves at a steady pace in log depth, so near walls (side shots) see it as clearly as the far nave
  float pW=(1.3*FAR+10.)*pow(.24/(1.3*FAR+10.),uM2[0].z),tW=hit?t:FAR+2.;
  kLoadPal(smoothstep(pW*.85,pW*1.2,tW));
  float front=uM2[0].z>.001&&uM2[0].z<.999?exp(-knSquarePortable((tW-pW)/(.05*pW+.025))):0.;
  float hz=uP3.z;
  vec3 BL=uP4.xyz;
  float vf=max(dot(rd,BL),0.);
  float ce=60.-36.*uBuild;
  // the far end of the nave: a luminous atmosphere with a white-hot core, tinted deep away from the axis
  // (in the great hall the far end is a long coloured glow; its white-hot core shrinks so the haze keeps its hue)
  float hzA=smoothstep(3.,15.,hR);
  // v19: no pale disc at the vanishing point (with the porthole gone this tight white-hot spot read as a small plain ball):
  // the far light is the atmosphere's own colour, broken into rays that turn slowly, so the end of the nave stays lit but is never one flat shape
  vec3 rpv=rd-BL*vf;float rv0=max(length(rpv),1e-4),spkS=.5+.5*cos(kAt(dot(rpv,cv)/rv0,dot(rpv,cu)/rv0)*14.+uMT*.35);
  vec3 core=kc4*(1.1*pow(vf,ce)+.45*pow(vf,9.))*(.72+.45*spkS)+mix(kc4,vec3(1.),.22-.1*hzA)*pow(vf,ce*2.2)*(.55-.3*hzA)*(.35+1.3*spkS*spkS);
  float kFH=smoothstep(1.,5.,hR);
  vec3 sky=(kc0*.55+kc1*(.34-.14*kFH)+kc4*(.14-.08*kFH+.6*exp(-(1.-vf)*22.)))+core*(1.-.3*hzA);
  // eclipse (a rare graphic pause): the stone and the atmosphere go dark, only the neon linework and the pearls burn
  sky*=uP4.w*(1.-.8*ecl);
  vec3 col=sky;
  // v19: where a ray escapes down the nave the view used to end in one flat hard-edged shape of sky (a square or a ball, sitting
  // exactly at the vanishing point): the nave now carries on forever as a receding mosaic in log-polar tiles, flowing toward
  // the camera, each tile a jewel with a lit bezel (bass lifts the bezels, treble the jewels). Its size in pixels sets how much
  // of it is drawn: where the tiles get too small to resolve it dissolves into the atmosphere glow, so the centre never shimmers
  float rs=max(rv0/max(vf,.2),1e-3),w0=log(rs)*5.73+uMT*.85,fw0=fwidth(w0);
  if(vf>.5){
    float an2=kAt(dot(rpv,cv)/rv0,dot(rpv,cu)/rv0)/TAU+.5;
    float nA=18.;
    vec3 mo=vec3(0.);float mA=0.;
    for(int k=KN0;k<KSKY;k++){
      float sc=exp2(float(k));
      vec2 uw=vec2(an2*nA*sc,w0*sc+float(k)*.37),cell=floor(uw),cl=fract(uw)-.5;
      float hsh=fract(sin(dot(cell,vec2(12.9898,78.233))+float(k)*5.1)*43758.55),fw=fw0*sc;
      float vis=1.-smoothstep(.16,.42,fw);
      if(vis<.003)break;
      float dq=length(cl*vec2(1.,.82));
      float jewel=1.-smoothstep(.34-fw,.34+fw,dq),bez=1.-smoothstep(.03,.05+fw,abs(dq-.39));
      vec3 jc=mix(mix(kc1,kc2,step(.5,hsh)),mix(kc3,kc4,.4),step(.72,hsh));
      vec3 lay=mix(kc0*.55,jc*(.55+.9*uB2.y*uB2.y+1.2*uO2.y*step(.5,fract(hsh*7.))+(1.2*uB1.z*uB1.z+1.2*uO1.z)*step(fract(hsh*5.),.5)),jewel)+mix(kc2,vec3(1.),.15)*bez*(.45+1.5*uB1.y*uB1.y+.9*uP5.w+1.2*snr*step(.5,fract(hsh*3.)));
      // v20: a tile big enough to see holds a figure, so the far end is never a plain patch
      if(k==0&&fw<.12){vec2 fg=kMotif(cl*2.9,mod(floor(hsh*11.),6.),fw*2.9);lay=mix(lay,mix(lay*.35,kRot(jc,kRs)*1.2,fg.y)+mix(kc4,vec3(1.),.2)*fg.x*.9,jewel*(1.-smoothstep(.06,.12,fw)));}
      mo+=lay*vis/sc;mA+=vis/sc;
    }
    mo/=max(mA,1e-4);
    // the unresolved middle is a fine starburst of the deep and atmosphere colours, never one flat fill
    float sf=.5+.5*cos(an2*TAU*40.+uMT*.5),fanW=spkS*spkS*(.45+.55*sf);
    vec3 fan=mix(kc0*.6,kc4*.85,fanW);
    col=mix(col,mix(fan,mo,min(mA*1.4,1.))*uP4.w*(1.-.8*ecl)+core*.3,smoothstep(.5,.88,vf));
  }
  // v20b: THE FAR FIELD. From far out, or along a wall at a grazing angle, a bay of the lattice is only a few pixels across. Up to there every bay still reads as a
  // bold block in its own edge colour; past it the blocks became pixel noise. So the mosaic carries on at the scale that is still visible: blocks of 1, 2, 4.. bays
  // take one colour (each axis picks its own size from its own footprint on the vault where the ray left the hall, so a block is 3.5 to 7 percent of the frame height
  // on screen at any resolution, squeezed walls included). A block keeps the colour of its first bay, so the far mosaic is the near one seen coarser, with no seam and
  // no new shapes: it only chooses colours, the fractal still draws every edge. (Sizes are measured on the vault itself, which runs on smoothly to the vanishing point.)
  float kFD=0.,kFS=0.;vec3 kFl=vec3(0.),kFu=vec3(1.),kFa=vec3(0.,0.,1.);
  if(hR>1.){
    vec3 eH=ro+rd*min(tHr,8.*FAR),fH=max(max(abs(dFdx(eH)),abs(dFdy(eH))),1e-6),aB3=2.*uP1.xyz/fH;
    kFD=kFH*(1.-smoothstep(6.,12.,min(aB3.x,min(aB3.y,aB3.z))));
    vec3 kf=clamp(log2(.03*uRes.y/aB3),-1.,14.);kFl=smoothstep(.75,1.,fract(kf));kFu=exp2(floor(kf)+1.);
    // v20b second pass: the axis the wall is seen along (largest footprint) is the one a block's figure ignores, so every cut through a block shows the whole figure
    kFa=step(max(fH.yzx,fH.zxy),fH);
    // how edge-on the wall is: the two screen directions' footprints on that axis. Past about 5:1 a block is a streak, not a block
    {vec3 gx=abs(dFdx(eH)),gy=abs(dFdy(eH));float ax=dot(gx,kFa),ay=dot(gy,kFa);kFS=kFH*smoothstep(5.,14.,max(ax,ay)/max(min(ax,ay),1e-7));}
  }
  // depth of the ray's near-miss halo: colours the silhouette glow by how far it is (edge A near, atmosphere far)
  float gd=glowT/max(glow,1e-5);
  if(hit&&t<FAR){
    vec3 pos=ro+rd*t;
    vec2 tq=kQ;vec4 tr=kTr;float DF=kDF,Rr=kRr,Sl=kSl,cd=kCd,cb=kCb;vec3 fp=kP;
    float lg=log(DF);
    float ne=max(px*t*.7,2e-5);
    vec3 n=vec3(0.);
    // eleven taps through one inlined DE: 4 for the normal, 4 for ambient occlusion along it, then 3 cone samples
    // toward the far light (soft directional occlusion in place of marched shadow rays: the D3D compiler paid ~20% of
    // the realm's compile time for the nested shadow loop)
    float ao=0.,w=1.,aw=0.,sh=1.,bias=max(px*t*2.,.0015);
    for(int j=KN0;j<11;j++){
      // taps 0-3: a tetrahedron around the hit (normal); 4-7 along the normal (AO); 8-10 toward the far light
      float fj=float(j),ty=step(1.5,fj)*2.-1.,tz=mod(fj,2.)*2.-1.,iN=step(fj,3.5),iA=step(3.5,fj)*step(fj,7.5),iS=step(7.5,fj);
      float h=mix(.05*exp2(1.6*(fj-8.)),.015*(fj-3.)*(fj-3.),iA);
      vec3 hk=ne*vec3(ty*tz,ty,tz),nn=normalize(n+1e-9);
      vec3 q=mix(pos+nn*bias+BL*h,mix(pos+nn*h,pos+hk,iN),iN+iA);
      float dj=kdeR(q);
      n+=hk*dj*iN;
      ao+=clamp(1.-dj/h,0.,1.)*w*iA;aw+=w*iA;w*=mix(1.,.6,iA);
      sh=min(sh,mix(1.,clamp(3.*dj/h,0.,1.),iS));
    }
    n=normalize(n+1e-9);
    // inside the great hall the uncarved lattice would shadow every wall: the vault is lit by its own glow instead
    if(hR>1.5)sh=1.;
#if HD>=1
    // real shadow ray toward the far light (the cone taps above estimate this cheaply at the phone tier)
    if(hR<1.5){
      float su=max(bias,.004)+.012,ssh=1.,nSh=18.+8.*float(HD)+3.*det;
      vec3 so=pos+n*bias*1.5;
      for(int j=KN0;j<300;j++){
        if(float(j)>=nSh)break;
        kFoot=px*t+su*.015;
        float dj=kdeR(so+BL*su);
        ssh=min(ssh,12.*dj/su);
        su+=clamp(dj*.9,.006+.014*su,.42);
        if(ssh<.03||su>6.)break;
      }
      ssh=clamp(ssh,0.,1.);sh=min(sh,ssh*ssh*(3.-2.*ssh));
    }
#endif
    ao=clamp(1.-ao/max(aw,1e-4),0.,1.);
#if HD>=1
    // occlusion rays over the hemisphere (a golden spiral around the normal, short to long, one sample at each radius)
    {
      vec3 tA=normalize(abs(n.y)<.9?cross(n,vec3(0.,1.,0.)):cross(n,vec3(1.,0.,0.))),tB=cross(n,tA);
      float oc=0.,ow=0.,nOc=10.+6.*float(HD);
      for(int j=KN0;j<48;j++){
        if(float(j)>=nOc)break;
        float fj=float(j)+.5,a=fj*2.399963,rr=sqrt(fj/nOc),cz=sqrt(max(1.-rr*rr,0.)),dO=.018*exp2(.7*fj*(8./nOc));
        vec3 hd=(tA*cos(a)+tB*sin(a))*rr+n*cz;
        kFoot=px*t+dO*.02;
        float dj=kdeR(pos+n*bias+hd*dO);
        float wO=1./(1.+.12*fj);
        oc+=clamp(1.-dj/(dO*cz+.0005),0.,1.)*wO;ow+=wO;
      }
      ao=clamp(ao*mix(1.,1.-oc/max(ow,1e-4),.75),0.,1.);
    }
#endif
    float pf=px*t*DF;
    float fine=smoothstep(1.5,4.5,lg);
    float sl=clamp(lg/7.,0.,1.);
    float sp=spec(.04+.9*sl);
    float rxy=length(fp.xy);
    float dA=(abs(rxy*fp.z)-uP2.w)/sqrt(dot(fp,fp)+uP2.w),dB=rxy-Rr;
    float onB=smoothstep(-pf,pf,dB-dA);
    // Indra's pearls: a necklace of beads around every rose window; bead i is spectrum band i/24
    // the last active inversion mirrors the face about |fp|=sqrt(S): a necklace near that seam shows every bead twice
    // (the "8" links), so a necklace close to it is centred on it instead, where each bead is its own reflection
    float rM=sqrt(max(Sl-fp.z*fp.z,.04)),rN=Rr-.19;
    float dM=rM-rN,r0=mix(rM,rN,max(smoothstep(.08,.1,dM),smoothstep(.12,.16,-dM))),ang=kAt(fp.y,fp.x)/TAU,bn=floor(ang*24.),cl=TAU*r0/24.;
    vec2 bq=vec2(rxy-r0,(fract(ang*24.)-.5)*cl);
    float bd=length(bq)/(cl*.25);
    // small beads are filled jewels; close up they open into crisp rings around a bright centre (no soft blobs)
    float bE=pf/(cl*.25),bR=clamp(4.*bE,.14,1.);
    float bShape=max(smoothstep(1.-bR-bE,1.-bR+bE,bd),1.-smoothstep(.24-bE,.24+bE,bd));
    float eng=smoothstep(1.+bE,1.-bE,bd)*bShape*(1.-onB)*smoothstep(.1,.025,pf)*(1.-smoothstep(.22,.45,sl));
    float bf=fract((bn+12.)/24.),bsp=spec(.04+.9*bf);
    vec3 L=ro+cw*.3+cv*.22;
    vec3 ld=L-pos;float ll=max(length(ld),1e-5);ld/=ll;
    float att=uP5.x/(1.+ll*ll*2.);
    float dif=max(dot(n,ld),0.);
    float bdif=max(dot(n,BL),0.);
    float ndv=max(dot(n,-rd),0.);
    float fre=pow(1.-ndv,3.);
    vec3 rf=reflect(rd,n);
    // a lamp glows in the node of every cell (its light falls off toward the cell's walls)
    vec3 C2=2.*uP1.xyz,dn=(pos-C2*(floor(pos/C2)+.5))/uP1.xyz,q3=max(1.-dn*dn,0.);
    float lamp=q3.x*q3.y*q3.z;lamp*=lamp*uP5.x;
    // each bay of the nave gets its own accent: a hash of the cell picks a position on the palette ramp
    vec3 cid=floor((pos+uP1.xyz)/(2.*uP1.xyz));
    float ch=fract(sin(dot(cid,vec3(7.13,157.1,113.7)))*43758.55);
    // pigment: the big structural levels carry the body colour, fine crust sinks to the deep tone
    vec3 body=mix(kc1,kRamp(.25+.5*ch),.3);
    // rose-window faces: the body colour at the rim turns ~57 deg in hue inside the face (a second hue on every
    // big face, so a single-hue palette such as sapphire never reads as one flat colour, folded or not)
    vec3 bAlt=kRot(body,kRs);
    float fIn=smoothstep(.03,.24,Rr-rxy)*(1.-onB)*(1.-smoothstep(.15,.45,sl));
    // (v14) STAINED GLASS. Inside every rim the face is a leaded mosaic, not one flat hue: five radial rings by
    // twenty pie sectors, each pane a jewel tone of this palette (a small hue turn of the body colour, so the visit
    // keeps its colour identity), separated by dark leading, the outer ring set deeper. The panes are backlit by the
    // sub and bass, the leading network glows with the mids, and the highs make single panes sparkle white.
    vec3 gBase=mix(kc1,bAlt*.85,.45);
    float rq=clamp(rxy/max(Rr,.04),0.,.999),prg=floor(rq*5.),psg=floor(ang*20.);
    // v20: a pane can be resolved along one direction and not the other (long ribbed faces at a distance): measure the two separately, so a far face keeps its sector stripes
    float fwS=fwidth(ang*20.),fwR=fwidth(rq*5.),fwP=min(fwS,fwR);if(fwR>.45)prg=2.;
    float pj=mod(ch*6.4+prg*2.3+mod(psg,4.)*1.5,6.);
    vec3 glass=kRot(gBase,(pj-2.5)*.46)*(.58+.80*fract(pj*.37));
    // keep the panes' chroma: the glass is pigment, so it never greys as the hue turns
    glass=mix(vec3(dot(glass,vec3(.2126,.7152,.0722))),glass,1.38);
    // v18: a pane is no longer one flat fill: each is a jewel, deep at its leading and lit at its heart (on a wall-sized
    // image a pane is the size of a hand, and a flat one read as a block of plain colour)
    vec2 cel=vec2(fract(ang*20.)-.5,fract(rq*5.)-.5);float heart=1.-smoothstep(.05,.62,length(cel));
    glass*=mix(.62,1.08,heart*heart);
    float dRg=min(min(min(abs(rq-.2),abs(rq-.4)),abs(rq-.6)),abs(rq-.8))*Rr,dSg=abs(fract(ang*20.)-.5)*TAU*rxy/20.;
    float lead=1.-smoothstep(.005,.005+pf*1.4,min(dRg,dSg));
    glass=mix(glass,glass*.16,lead);glass=mix(glass,glass*.5,step(.8,rq));
    // v20: every pane is drawn. It takes one of six figures (kind set by its ring and the sector's parity, so each window has a real radial
    // design) in two jewel tones with an ink line; a long pane repeats its figure along its length instead of stretching it. The snare swaps
    // the two tones, the bass lights the fill, the mids the lines, the air the centres.
    float wP=TAU*max((prg+.5)/5.*Rr,.03)/20.,hP=Rr/5.,pS=min(wP,hP),nP=floor(max(wP,hP)/pS+.5);
    vec2 mq=2.*(wP>hP?vec2(fract((cel.x+.5)*nP)-.5,cel.y):vec2(cel.x,fract((cel.y+.5)*nP)-.5));
    float mE=2.*pf/pS,mKd=mod(prg*2.+floor(ch*6.)+mod(psg,2.)*3.,6.);
    // v20: the walls of the openings cut in the discs (the tall striped pillars): on these the angle is constant, so their pattern is laid out along the wall (rings) and across it (z)
    float bSide=step(cb,cd),bHz=uP2.w/max(rxy,.08);
    if(bSide>.5){mq=vec2(clamp(fp.z/bHz,-1.,1.),2.*(fract(rq*5.)-.5));mE=max(pf/bHz,pf/(.1*Rr));}
    float mVis=1.-smoothstep(.1,.3,mE);
    vec2 mf=mVis>.003?kMotif(mq,mKd,mE):vec2(0.);
    float mSw=step(.3,snr)*mod(psg+prg,2.);
    vec3 pA=glass,pB=kRot(glass,mod(prg+psg,2.)*2.-1.)*1.25;
    if(bSide>.5)glass=mix(gBase,kRot(gBase,mod(prg,2.)*2.-1.),.55)*(.75+.5*fract(pj*.37));
    glass=mix(glass,mix(mix(pB,pA,mSw),mix(pA,pB,mSw),1.-mf.y),mVis);
    glass=mix(glass,mix(kc2,kc4,mod(psg,2.))*1.15,mf.x*mVis*(1.-lead));
#if HD>=1
    // from Native up the fill of every figure holds a smaller figure, and at the top tiers a third order inside that, each only where it is resolved
    {
      vec2 q2=mq;float sc2=1.,e2=mE;
      for(int o=KN0;o<1+HD;o++){
        q2=2.*(fract((q2+1.)*1.5)-.5);sc2*=3.;e2*=3.;
        float v2=1.-smoothstep(.12,.36,e2);if(v2<.003)break;
        vec2 f2=kMotif(q2,mod(mKd+float(o)*2.+1.,6.),e2);
        vec3 c2=kRot(glass,mod(float(o),2.)*2.-1.)*1.1;
        glass=mix(glass,mix(glass,c2,f2.y*.75)+mix(kc2,kc4,.5)*f2.x*.5,v2*mf.y*mVis*(1.-lead));
      }
    }
#endif
    // v20: a pane squeezed flat by the view is resolved in only one direction, and showed as a plain colour field. There it is pinstriped along whichever direction survives: four fine lines per pane, in the other tone
    {float pS1=abs(fract(ang*80.+.5)-.5),pR1=abs(fract(rq*20.+.5)-.5),wS=max(fwS*4.,.02),wR=max(fwR*4.,.02);
     float pin=(1.-smoothstep(wS*.6,wS*1.5,pS1))*(1.-smoothstep(.08,.22,fwS*4.)),pin2=(1.-smoothstep(wR*.6,wR*1.5,pR1))*(1.-smoothstep(.08,.22,fwR*4.));
     glass=mix(glass,kRot(glass,mod(psg,2.)*2.-1.)*1.2,max(pin,pin2)*(1.-mVis)*(1.-lead));}
    // the mosaic fades back into the plain face once a pane is under a couple of pixels (no colour noise far away)
    float gtile=fIn*(.30+.70*(1.-smoothstep(.2,.55,fwP))*(1.-smoothstep(.09,.3,pf*.3))*1.);
    body=mix(body,glass,gtile);
    // v20: big surfaces that are not window faces (the ribbed flaps and trumpets of the other families, the outer margin of a face) had no pattern of their own and
    // showed as large plain fields. They are tiled in their own coordinates (along z and the log radius, turned by the angle) with the same figures, in two tones of the body.
    {float oW=(1.-fIn)*(1.-onB)*(1.-smoothstep(.15,.4,sl));
     if(oW>.003){
       vec2 ouv=vec2(fp.z*9.+ang*20.,log(max(rxy,.02))*9.-fp.z*5.);float oE=2.*max(fwidth(ouv.x),fwidth(ouv.y)),oV=1.-smoothstep(.12,.4,oE);
       if(oV>.003){vec2 oc=floor(ouv),of=kMotif(2.*(fract(ouv)-.5),mod(oc.x+oc.y*2.+floor(ch*6.),6.),oE);
         float oT=mod(oc.x+oc.y,2.);vec3 oA=mix(body,kc0,.35),oB=kRot(body,oT*2.-1.)*1.15;
         body=mix(body,mix(oA,oB,abs(of.y-step(.3,snr)*oT))+mix(kc2,kc4,oT)*of.x*(.5+1.2*uB1.w*uB1.w+1.2*uB1.z*uB1.z),oW*oV);}
     }}
    // per-pane glitter: each pane has its own hash phase and its own twinkle rate, so the highs read as glass
    // catching light rather than as a uniform glow
    float pgh=fract(sin(dot(vec2(pj,prg),vec2(12.9898,78.233))+ch*37.7)*43758.55);
    float pglit=pow(fract(pgh*7.31+uTime*(.10+.26*pgh)),14.);
    float kRip=exp(-knSquarePortable((rq-fract(uBeat)*1.15)*5.))*uP5.w*1.3;
    float glassE=(1.-lead)*gtile*(.16+.9*kRip+.34*uB1.y*uB1.y*(.6+.8*mf.y)+.09*uB1.x);
    float glassG=(1.-lead)*gtile*pglit*(.20+2.6*uB2.z*uB2.z+2.2*uO2.z);
    // the fine crust is stained glass: orbit-trap bands walk the dark half of the ramp, never the complementary edge
    // (deep to body only: body to edge A can cross complementary hues and turn grey)
    vec3 crust=mix(kc0,kc1,.5+.5*fract(log2(max(tr.w,1e-6))*.35+ch*.5));
    // crust tops catch a dusting of the atmosphere colour (a lighter hue of the same family), crevices keep the deep
    // tone: dense crust reads as two-tone filigree with value contrast instead of a dark blue-violet mat
    vec3 kdir=normalize(cv*.8+cu*.5-cw*.3);
    float kTop=max(dot(n,kdir),0.);
    vec3 crustA=mix(mix(crust,body,.5)*1.25,kc4*.9,.4*smoothstep(.15,.75,kTop)*ao*(1.-.75*smoothstep(3.,15.,hR)));
    // v20: ENAMEL. The orbit's closest approach gives conformal polar coordinates on every fractal surface (the angle and the log radius at that
    // moment), which the old colouring only used as black-and-colour stripes. Now they are rings of tiles: each ring a figure and a ground of its
    // own, set in with a bright cloison line, staggered like masonry, and every ring plays one of the eight spectrum bands.
    float tL=.5*log(max(tr.w,1e-6))+ch,tAn=kAt(tq.y,tq.x);
    vec2 tuv=vec2(tAn,tL)*2.8647890;  // 18 tiles around, square in the conformal metric
    float tRow=floor(tuv.y);tuv.x+=.5*mod(tRow,2.);
    float tE=2.*fwidth(tL)*2.8647890,tVis=(1.-smoothstep(.06,.17,tE))*smoothstep(.1,.3,sl),tNear=1.-smoothstep(.05,.16,tE);
    vec2 tq2=2.*(fract(tuv)-.5),tF=tVis>.003?kMotif(tq2,mod(tRow,6.),tE):vec2(0.);
    float tTone=mod(tRow+floor(ch*3.),3.),tBi=mod(tRow,8.);
    vec3 tGnd=tTone<1.?mix(kc0,kc1,.42):(tTone<2.?mix(kc0,kc1,.8):mix(kc0,kRot(kc1,kRs),.72)),tFig=mix(mix(kc1,kRot(kc1,-kRs),.5)*1.25,tTone<1.?kc2*.85:(tTone<2.?kc3*.85:mix(kc2,kc4,.5)*.8),tNear);
    vec4 tOh=vec4(equal(vec4(mod(tBi,4.)),vec4(0.,1.,2.,3.)));
    float tLv=dot(mix(uB1,uB2,step(4.,tBi)),tOh),tOn=dot(mix(uO1,uO2,step(4.,tBi)),tOh);
    // the snare turns alternate rings inside out: figure and ground swap colours (a colour punch, not a brightness wash)
    float tSw=step(.3,snr)*step(.5,mod(tRow+floor(uBeat),2.));
    crustA=mix(crustA,mix(tGnd,tFig,abs(tF.y-tSw))*(.85+.55*tLv),tVis);
    // v18: engraved faces: fine conformal chasing (ribs across, rings along) cut into every big face, fading once a line is
    // under about a pixel, so a near face is never a block of plain colour
    float chA=cos(ang*TAU*72.),chB=cos((rxy-Rr)*70.),chF=(1.-smoothstep(.012,.05,pf))*(1.-onB);
    body*=mix(1.,.5+.5*smoothstep(-.2,.75,chA*chB),chF);
#if HD>=1
    // finer chased lace on the faces: octaves of conformal engraving, each one only where its line spacing is resolved
    float filg=0.;
    {
      vec2 lc=vec2(ang*TAU,log(max(rxy,.03)));float f=46.,amp=1.;
      for(int o=KN0;o<14;o++){
        if(float(o)>=1.+float(HD)*1.6)break;
        float spc=TAU*max(rxy,.03)/max(f,1.);
        float vis=(1.-smoothstep(.22*spc,.6*spc,pf))*(1.-onB);
        if(vis<.003)break;
        vec2 uvq=lc*f;
        float a1=abs(sin(uvq.x+.5*sin(uvq.y))),a2=abs(sin(uvq.y+.5*sin(uvq.x+1.)));
        float ln=1.-smoothstep(.0,.16,min(a1,a2));
        filg+=ln*vis*amp;
        lc=vec2(lc.x*.7071-lc.y*.7071,lc.x*.7071+lc.y*.7071);f*=1.92;amp*=.72;
      }
      filg=clamp(filg,0.,1.);
    }
    body*=1.-.3*filg;
#endif
    vec3 alb=mix(body*.65,crustA,smoothstep(.12,.55,sl))*(1.-.6*eng);
    // lights on pigment stay near-white (pigment x complementary light = grey); colour lives in pigment and emission
    vec3 lantC=mix(vec3(1.),kc2,.55),wl=mix(vec3(1.),kc1,.3);
    // a soft camera-space key from above-right models every form, even far from the lamps
    float Ld=lamp*1.9+bdif*1.05*sh*uP4.w+(.38*kTop+.15+.24*fine)*mix(1.,ao,.75-.35*fine);
    col=alb*(wl*Ld+lantC*dif*att*2.)*(1.-.88*ecl);
    // v20b: the bands that lost their flood pump the figures instead. Near-white light on the pigment (hue and saturation kept), only where the pigment is a bright tone
    // and the surface is open and already lit (fgK, Ld): every deep ground, every shadow and every crevice stays as dark as it was, so a hit raises figure against ground instead of filling the frame.
    // Peaks of the low-mids take alternate bays, the snare the bays between, the kick all of them briefly; peaks of the air band catch the facets that face the key light.
    // (Tried and removed, by eye and by the share of deep darks in real music: lifts of whole tiles or tops, a glow in the crevices, coloured rims. Each matched base's
    // numbers and each washed the crust pink or pale.)
    {float bq=mod(cid.x+cid.y+cid.z,2.),fgK=ao*ao*smoothstep(.25,.6,max(alb.r,max(alb.g,alb.b)));
     col+=.5*alb*wl*(.4+.75*min(Ld,1.3))*fgK*(bq*(1.4*max(uB1.z-.5,0.)+.5*uO1.z)+(1.-bq)*.85*snr+.15*max(uP5.w-.25,0.)+smoothstep(.25,.75,kTop)*(2.5*max(uB2.w-.5,0.)+.8*uO2.w))*(1.-.88*ecl);}
    // backlit glass: the panes glow from behind with the sub/bass, the leading network pulses with the mids, and the
    // mosaic's own sparkle (highs) sits on top. Pane emission is the bass's own visible register.
    col+=glass*glassE*.75*uP4.w*(.6+.4*sqrt(ao))*(1.-.88*ecl);
    // v20: the snare, mids and highs used to reach far faces through ring lines that had merged into a flat flood. They now light the panes themselves, in each pane's own
    // colour and in a checker that swaps every beat, so the response is as broad but stays a crisp mosaic
    {float pk=max(uP5.y-.3,0.),pc=mod(psg+prg+floor(uBeat),2.);
     col+=glass*(1.-lead)*gtile*pk*(.1+.42*pc)*(.6+.4*sqrt(ao))*(1.-.88*ecl);
     col+=tFig*tF.y*tVis*pk*.3*step(.5,mod(tRow+floor(uBeat),2.))*sqrt(ao)*(1.-.88*ecl);}
    // v20b: low-mids light the figures of alternate panes (the other half from the snare's checker), the kick flashes alternate rings of panes
    col+=glass*(1.-lead)*gtile*mf.y*mVis*(.9*snr+.6*uO2.w+(.9*uB1.z*uB1.z+.9*uO1.z)*mod(psg+prg+1.,2.))*(1.-.88*ecl)*.8;
    col+=glass*(1.-lead)*gtile*.4*max(uP5.w-.25,0.)*mod(prg,2.)*(.6+.4*sqrt(ao))*(1.-.88*ecl);
    col+=mix(kc2,vec3(1.),.12)*lead*gtile*(.03+.5*uB1.w*uB1.w)*uP4.w*(1.-.88*ecl);
    // v20b: the ink line of every pane figure is a wire: low-mids burn it in the edge colours on one half of the panes, the air band on the other half (the kick's ring passes along all of them)
    {float pc2=mod(psg+prg,2.);
     col+=mix(mix(kc2,kc3,pc2),vec3(1.),.15)*mf.x*mVis*(1.-lead)*gtile*(pc2*(1.3*uB1.z*uB1.z+1.6*uO1.z)+(1.-pc2)*(1.2*uB2.w*uB2.w+1.2*uO2.w)+.8*kRip)*(.6+.4*sqrt(ao))*(1.-.88*ecl);}
    col+=mix(glass,vec3(1.),.2)*glassG*.8*uP4.w;
#if HD>=1
    // the chased lace catches the neon: gold-leaf lines on the body, brighter with the mids and highs
    col*=1.+filg*(.25+.9*uB1.w*uB1.w+.9*uB2.y*uB2.y)*(1.-.88*ecl);
#endif
#if HD>=2
    // inside each pane a small rose: one ring and eight spokes, resolved only where the pane is many pixels wide
    {
      float pSz=min(TAU*max(rxy,.03)/20.,Rr/5.),vis=(1.-smoothstep(.045*pSz,.14*pSz,pf))*gtile;
      if(vis>.003){
        vec2 cq=vec2(cel.x*TAU*max(rxy,.03)/20.,cel.y*Rr/5.)/pSz;
        float cr=length(cq),ca=kAt(cq.y,cq.x);
        float rg=abs(cr-.3),spk8=abs(fract(ca*1.2732395+.5)-.5)*.7854*cr;
        float lw=.012+.7*pf/pSz;
        float rl2=max(1.-smoothstep(lw*.5,lw*1.4,rg),(1.-smoothstep(lw*.4,lw*1.2,spk8))*step(cr,.3));
#if HD>=3
        float rg3=abs(cr-.17);rl2=max(rl2,.7*(1.-smoothstep(lw*.5,lw*1.3,rg3)));
#endif
        col+=mix(glass,mix(kc2,kc3,step(.5,pgh)),.6)*rl2*vis*(.35+1.8*uB2.x*uB2.x+2.5*uO2.y)*uP4.w*(1.-.88*ecl);
      }
    }
#endif
#if HD>=1
    // real material from Native up: the leaded glass and the enamel are domed; their relief bends a highlight from the far light and the camera lamp that slides across each pane and tile as the view moves
    {
      float hB=(1.-lead)*gtile*(.7*heart+.3*mf.y)+tF.y*tVis*.5,gK=.5*pf;
      vec3 dX=dFdx(pos),dY=dFdy(pos),r1=cross(dY,n),r2=cross(n,dX);float dt=dot(dX,r1);
      vec3 gB=(dt<0.?-1.:1.)*(dFdx(hB)*r1+dFdy(hB)*r2)/max(abs(dt),1e-7);float gL=length(gB)*gK;
      vec3 nB=normalize(n-gB*gK*min(1.,.8/max(gL,1e-5)));
      vec3 rfB=reflect(rd,nB);float sA2=pow(max(dot(rfB,BL),0.),48.),sB2=pow(max(dot(rfB,ld),0.),28.),sV=(1.-smoothstep(.04,.12,pf));
      vec3 hTn=alb/max(max(alb.r,max(alb.g,alb.b)),.02);
      col+=mix(hTn,vec3(1.),.3)*(sA2*uP4.w+sB2*att*.7)*(.5+2.4*uB2.z*uB2.z+2.*uO2.z)*sV*(1.-.88*ecl)*.55;
    }
#endif
    // (the stone is matte: its specular terms were under 5% of the light and are retired; the sheen toward the far
    // light stays)
    float rv=max(dot(rf,BL),0.);
    col+=kc4*(.011+.137*pow(rv,10.))*(.05+.5*fre)*ao*uP4.w*(1.-fine*.5);
    // luminous rims: grazing faces glow with the atmosphere; a snare flips them to edge B and flares them
    vec3 rimC=mix(kc4,mix(kc4,vec3(1.),.45),snr);
    col+=rimC*fre*(.22+1.2*snr+.3*max(uP5.z-.3,0.)+.9*uO2.w+.7*uO1.w+.5*uO2.z)*sqrt(ao)*(1.-.45*fine)*(.5+.5*uP4.w);
    // the drop flares the rims in the bay's own edge colour (never the atmosphere: that was a flat orange wash)
    col+=mix(mix(kc2,kc3,step(.5,ch)),vec3(1.),.35)*fre*fre*.7*flash*sqrt(ao);
    // each beat a ring of light runs away from the camera down the nave (two per beat in a build)
    float bp=uBuild>.5?fract(uBeat*2.):uBeat;
    // measured along the nave (not along the ray), so in side and vault shots it sweeps across the walls as a band
    float ta=dot(pos-ro,BL),tb=1.+bp*12.;
    float band=exp(-knSquarePortable((ta-tb)*2.))*uP5.w*smoothstep(.6,1.5,ta);
    float beatBody=.6*dif+.4*bdif*sh;
    col+=mix(kc2,vec3(1.),.2)*band*(alb*(.45+1.9*beatBody)+.3*fre+eng*.8)*ao;
    // pearls: each bead glows with its spectrum band, coloured from edge B (bass) to edge A (treble)
    vec3 cE=(bf<.5?kc3:kc2)*1.4;
    // presence onsets flash the pearls white-hot
    col+=cE*eng*(.08+(.15+2.2*bsp*bsp*bsp)*uP5.z*(1.-.7*bd*bd)+.6*uO2.y);
    // vesica frames: a pointed-oval bezel around every pearl (two scalloped lines meeting in cusps between beads),
    // each frame lit by the highs in its own treble band; the mirror seam completes them into closed ovals
    float vA=.4*cl,vs=abs(sin(PI*24.*ang));
    float vsl=vA*PI*24.*sqrt(max(1.-vs*vs,0.))/(TAU*max(rxy,.1));
    float vd=abs(abs(rxy-r0)-vA*vs)/sqrt(1.+vsl*vsl);
    float vw=.0035+.012*cl;
    float foil=(1.-smoothstep(max(vw-pf,0.),vw+pf,vd))*(1.-smoothstep(.006,.02,pf))*(1.-onB)*(1.-smoothstep(.22,.45,sl));
    // hi-mid band: its level lights the frames, its onsets flash them
    float fsp=spec(.5+.45*bf),hiW=max(uP5.z-.3,0.),hiE=hiW+.2*uB2.x*uB2.x*uDose+.6*uO2.x;
    // drawn in the atmosphere colour: the fifth palette stop now also lives on the near faces (peach on sapphire,
    // mint on acid), so faces carry a third hue
    col+=mix(kc4,vec3(1.),.15+.4*hiW*fsp)*foil*(.1+hiE*(.3+1.8*fsp*fsp))*sqrt(ao);
    // dense crust is lit from within: its crevices glow softly in edge A, like light through stained glass
    col+=mix(kc2,kc1,.5)*.15*(1.-.5*ao)*smoothstep(.3,.7,sl)*(.6+.4*uP4.w);
    // v20: the cloison lines burn in their ring's band; each band's onset flashes its whole ring of figures
    col+=mix(kc2,kc3,mod(tRow,2.))*tF.x*tVis*(.05+.25*tNear+1.6*tLv*tLv+1.6*tOn+.6*uB1.w*uB1.w+.9*uB1.z*uB1.z+.9*uB2.w*uB2.w+.9*snr)*uP5.y*.55*sqrt(ao)*(1.-.88*ecl);
    float tRun=exp(-knSquarePortable((fract(tuv.x/18.-uBeat)-.5)*14.))*uP5.w*step(.5,mod(tRow,2.));
    col+=tFig*tF.y*tVis*(.04+.7*tOn+1.6*tRun+.6*max(uP5.w-.25,0.)*step(mod(tRow,2.),.5)+1.5*snr*step(.5,mod(tRow+floor(uBeat),2.))+.6*uO2.w)*sqrt(ao)*(1.-.88*ecl);
    // jewel crust in the crevices; hats make it twinkle white-hot
    float hh=fract(sin(dot(floor(fp*3.),vec3(12.9898,78.233,37.719)))*43758.55);
    float twp=pow(fract(hh*7.13+uTime*(.5+hh)),6.),tw=twp*hat*4.5;
    float jw=smoothstep(.012,.002,tr.w)*fine*(.02+uP5.z*(.15*sp*sp+.9*tw+1.6*twp*uO2.z));
    col+=mix(kc3,vec3(1.),.3*tw)*jw*ao*1.4;
    // neon tracery: a ring inset on every rose-window face plus the rim band's centre line, at every scale
    float lod=smoothstep(.05,.018,pf)*(1.-smoothstep(.18,.42,sl)); // v20: was .14 to .03: by then the soft ring line was wider than the face and lit all of it flat
    float ring=smoothstep(.013+pf,0.,abs(rxy-Rr+.07))*(1.-onB);
    float rl=max(ring,.6*smoothstep(.01+pf,0.,abs(fp.z))*onB)*lod;
    // the spectrum is laid along the nave: bass lights the near bays, treble the far ones
    float sd=spec(.04+.9*clamp(t/12.,0.,1.));
    // a snare swaps the two edge colours; after a drop they also alternate in bands that rush toward the camera
    bool cf=((ch<.5)!=(snr>.3))!=(flash>.04&&fract(t*.7+flash*3.)>.5);
    // the drop burns the linework white-hot for a moment (a saturated magenta or orange flood clips into a flat peak)
    vec3 cC=mix(cf?kc2:kc3,vec3(1.),.15+.5*flash);
    // v12: every hat sixteenth lights the neon rings of a different half of the rose windows
    float hatW=hat*step(.5,fract(ch*7.13+floor(uBeat*4.)*.382));
    col+=mix(cC,vec3(1.),.08*hatW)*rl*uP5.y*(.5+2.2*sd*sd+2.5*band+4.5*hatW)*(1.3+1.2*uBuild)*(1.+.8*ecl);
    // (v14) the neon really glows: a wide soft halo around every tracery ring and rim band. The line itself stays
    // crisp - this is light around it, not blur - so the walls read as lit neon tubing rather than printed linework,
    // and the whole hall gains a luminous layer that beats with the same spectrum as the lines.
    // v20: the halo's edges were reversed once a pixel covered more than .016 here: it then lit the whole face flat in the edge colour, which was the big plain red and blue fields on far faces
    float halF=1.-smoothstep(.008,.02,pf),halo=halF*max((1.-smoothstep(pf*2.,.032,abs(rxy-Rr+.07)))*(1.-onB),.55*(1.-smoothstep(pf*2.,.026,abs(fp.z)))*onB);
    col+=mix(cC,vec3(1.),.05)*halo*uP5.y*(.26+.38*sd*sd+.30*band)*(1.3+1.2*uBuild)*(1.+.8*ecl)*0.34;
    // v18: the openings' edges are neon. Bass burns them all, each rib plays its own spectrum band, hats flash half the ribs
    float eW=.004+pf*.8,ed=(1.-smoothstep(eW*.4,eW,max(abs(cd),abs(cb))))*(1.-smoothstep(2.6,6.,DF))*(1.-smoothstep(.008,.03,pf));
    float secB=spec(.04+.9*fract(ang*16.+ch));
    col+=mix(cC,vec3(1.),.12)*ed*uP5.y*.8*(.7+2.6*uB1.y*uB1.y*uDose+1.6*secB*secB+3.*band+4.*hat*step(.5,fract(ch*5.+floor(uBeat*4.)*.618)))*(1.+.8*ecl);    // far LOD: once a window is too small for its tracery, its whole rim glows as one crisp neon circle, so distant
    // walls stay a lattice of tiny rings (detail to the pixel) instead of dissolving into speckle
    float farW=smoothstep(.07,.16,pf)*(1.-smoothstep(.5,1.1,pf))*(1.-smoothstep(.18,.42,sl));
    // v12: zoomed out (the hall's thousand windows) those rims carry the hats and the vocal / lead range too
    // (v14) and every window keeps its own jewel hue, so a distant wall of a thousand windows is a mosaic of
    // coloured rings instead of two alternating edges: the stained glass reads at every distance
    float prW=max(uO2.x,uO2.y)+.8*max(uB2.x+uB2.y-.9,0.);
    vec3 farC=cf?kc2:kc3;
    col+=mix(farC,vec3(1.),.06*hatW)*onB*farW*uP5.y*(.45+1.2*sd*sd+2.*band+3.*hatW+1.8*prW+1.3*uB1.z*uB1.z+1.2*max(uP5.w-.25,0.))*sqrt(ao);
    // (the carved orn() inlays were retired: the vesica frames carry the face detail, and the D3D compile budget
    // they used now pays for the frames, the mirror-centred pearls and the two-hue faces)
    float stoneFoot=pf/max(abs(dot(n,rd)),.3);
    // (v14) ROSE-WINDOW TRACERY: twelve radial spokes and two concentric rings inside every face, drawn in the
    // tracery colour and riding the tracery light. This is what makes a round window a rose window.
    float spk=abs(fract(ang*12.)-.5)*TAU*rxy/12.;
    float spkL=(1.-smoothstep(.005,.005+pf*1.6,spk))*step(.06,rq);
    float rg2=min(abs(rq-.42),abs(rq-.72))*Rr;
    float rg2L=(1.-smoothstep(.005,.005+pf*1.6,rg2))*step(.06,rq);
    // v20: once a far face's spoke or ring line grew wider than the gap between lines the tracery lit the whole face flat in the edge colour (the big plain red and blue
    // fields): each fades out before its lines can merge
    spkL*=1.-smoothstep(.25,.6,(.005+pf*1.6)/max(.26*rxy,1e-4));rg2L*=1.-smoothstep(.2,.5,(.005+pf*1.6)/max(.15*Rr,1e-4));
    float roseT=max(spkL,rg2L)*fIn;
    col+=mix(cC,vec3(1.),.1)*roseT*uP5.y*(.35+1.2*sd*sd+1.6*band)*(1.+.8*ecl)*(1.3+1.2*uBuild)*1.25;
    // radial flutes on the big curved rims: a circular analyser around every rim
    float rimPhase=ang+.5;
    float rimFoot=stoneFoot/max(rxy,.1)/TAU*48.;
    float flute=(1.-smoothstep(.04,.04+rimFoot,abs(fract(rimPhase*48.)-.5)))*onB;
    flute*=1.-smoothstep(.12,.3,rimFoot);
    float rimBand=spec(abs(rimPhase*2.-1.));
    // low-mid onsets strike the flutes like a plucked string; hats, the air band and its onsets flash them white-hot
    // (the scattered star glints they used to light are retired: the flutes carry the hats on every rim instead)
    col+=mix(kc2,vec3(1.),.45*hat)*flute*(.08+.7*rimBand*rimBand+.4*snr+1.1*uO1.z+2.2*hat+.8*uB2.w*uB2.w+2.*uO2.w)*sqrt(ao);
    // v20: the rim of every disc is a jewelled band: 48 oval cabochons set between two rails, each playing a band of the spectrum in turn around the
    // circle (a disc seen edge-on used to be a long plain brown spindle)
    {
      float rcId=floor(rimPhase*48.),rcBi=mod(rcId,8.),rcH=max(uP2.w/max(Rr,.2),.02);
      vec2 rcq=vec2((fract(rimPhase*48.)-.5)*2.,fp.z/rcH);
      float rcE=max(rimFoot*2.,pf/rcH),rcVis=onB*(1.-smoothstep(.2,.6,rcE));
      vec4 rcOh=vec4(equal(vec4(mod(rcBi,4.)),vec4(0.,1.,2.,3.)));
      float rcLv=dot(mix(uB1,uB2,step(4.,rcBi)),rcOh),rcOn=dot(mix(uO1,uO2,step(4.,rcBi)),rcOh);
      float rcD=length(rcq*vec2(1.,1.3))-.58,rcFill=1.-smoothstep(-rcE,rcE,rcD),rcLn=1.-smoothstep(.05,.05+2.*rcE,abs(rcD));
      float rcRail=1.-smoothstep(.04,.04+2.*rcE,abs(abs(rcq.y)-.82));
      vec3 rcG=mix(kc1,kc3,.25)*.42*(.8+.4*sqrt(ao)),rcC=mix(mix(kc2,kc3,mod(rcId,2.)),kc4,step(5.5,rcBi));
      float rcP=max(uP5.y-.3,0.);
      vec3 rcCol=rcG*(1.+.8*rcP)+rcC*rcFill*(.35+1.7*rcLv*rcLv+2.6*rcOn+.55*rcP*mod(rcId+floor(uBeat*2.),2.))+mix(kc2,vec3(1.),.1)*max(rcLn*(1.-rcFill),rcRail)*(.3+.9*uB1.w*uB1.w+1.3*rcP);
      col=mix(col,rcCol*(1.-.88*ecl),rcVis);
    }
#if HD>=1
    // a real reflection bounce: the glass and the big faces mirror the fractal around them. One march, run for a few jittered
    // directions at the top tiers (a glossy reflection), each lit by the orbit colours of what it found.
    {
      float glossW=(fIn*.75+.14)*(.22+.78*fre)*(1.-.5*fine)*(.45+.55*ao);
      if(glossW>.01){
        vec3 tA=normalize(abs(rf.y)<.9?cross(rf,vec3(0.,1.,0.)):cross(rf,vec3(1.,0.,0.))),tB=cross(rf,tA),rSum=vec3(0.);
        float nGl=2.+float(HD),gi=hh1(fp)*TAU;
        for(int g=KN0;g<9;g++){
          if(float(g)>=nGl)break;
          float fg2=float(g),a=gi+fg2*2.399963,sprd=fg2>.5?.018*sqrt(fg2):0.;
          vec3 rr=normalize(rf+(tA*cos(a)+tB*sin(a))*sprd),rp=pos+n*bias*2.;
          float rt=bias*3.,rFar=9.+float(HD)*3.,nR=26.+float(HD)*12.+4.*det;bool rh=false;
          for(int j=KN0;j<200;j++){
            if(float(j)>=nR)break;
            kFoot=px*(t+rt)*1.2;
            float dj=kdeR(rp+rr*rt);
            if(dj<max(kFoot*.7,6e-4)){rh=true;break;}
            rt+=.9*dj;if(rt>rFar)break;
          }
          vec3 rc=kc0*.55+kc4*(.12+.75*pow(max(dot(rr,BL),0.),6.))*uP4.w;
          if(rh){
            float rLg=clamp(log(kDF)/7.,0.,1.),rf2=fract(log2(max(kTr.w,1e-6))*.35);
            vec3 ra=mix(mix(kc1,kc2,.3*rf2),mix(kc0,kc1,rf2),rLg);
            float nE=1.-smoothstep(0.,.06,abs(kCb));
            ra+=mix(kc2,kc3,rf2)*nE*uP5.y*1.4;
            ra*=.6+.5*exp(-rt*.25);
            rc=mix(ra,rc,1.-exp(-rt*.09));
          }
          rSum+=rc;
        }
        // the glass reflects in its own colour: a white-pink sum over cyan or orange panes was what paled every tier above High
        vec3 rTint=alb/max(max(alb.r,max(alb.g,alb.b)),.02);
        col+=rSum/nGl*glossW*rTint*(1.1-.9*ecl);
      }
    }
#endif
    // v20: FAR LOD. A window too far away for its panes (under about 60 pixels across) becomes one bold disc of its bay's edge colour with a dark ink rim, lit by the
    // snare, mids, highs and the beat ring. Before v20 this look came by accident from ring lines that had merged into a flood; removing the flood without this left distant
    // walls as dark speckle under the haze, with the palette's two edge hues averaged away.
    float fDisc=smoothstep(0.,.05,Rr-rxy)*(1.-onB)*(1.-smoothstep(.15,.4,sl));
    // v20b: the block colour of the far field (see above): the two edge colours, one block in six the rose tone; the snare swaps the edge colours, every block plays its own
    // band of the spectrum
    vec3 kBl=cf?kc2:kc3;vec4 kFg=vec4(0.);float kFn=0.;
    if(hR>1.){
      vec3 qb=(pos+uP1.xyz)/(2.*uP1.xyz),iA=floor(qb/kFu)*kFu,iB=floor(qb*.5/kFu)*2.*kFu,wB=vec3(0.);
      for(int k=KN0;k<8;k++){
        vec3 sl3=vec3(mod(float(k),2.),mod(floor(float(k)*.5),2.),floor(float(k)*.25)),w3=mix(1.-kFl,kFl,sl3);
        float wk=w3.x*w3.y*w3.z;
        if(wk<.004)continue;
        float h=fract(sin(dot(mix(iA,iB,sl3),vec3(7.13,157.1,113.7)))*43758.55),bj=floor(fract(h*13.7)*7.99);
        vec4 oh=vec4(equal(vec4(mod(bj,4.)),vec4(0.,1.,2.,3.)));
        float lv=dot(mix(uB1,uB2,step(4.,bj)),oh),on=dot(mix(uO1,uO2,step(4.,bj)),oh);
        bool sw=((fract(h*2.38)<.5)!=(snr>.3))!=(flash>.04&&fract(t*.7+flash*3.)>.5);
        wB+=wk*(h>.85?mix(kc1,kc4,.5)*1.15*(.9+.9*uB2.x*uB2.x+1.3*uO2.y):(sw?kc2:kc3)*(.9+.8*lv*lv+1.2*on));
        // v20b second pass: a bold two-ink figure in every block (rosette, nested lozenge, quatrefoil or eight-point star: the panes' own figures), drawn in the
        // block's own coordinates across the two axes the wall is not seen along. Figure in the other edge colour, ruled in ink; its band's onset flashes it
        // (the figure is laid out on the screen around the block's own centre and sized by the block's width there: a point's position inside a block scatters
        // with its depth along the ray, which smeared a figure drawn in the block's own coordinates into radial streaks)
        vec3 bs=kFu*(1.+sl3),c3=(mix(iA,iB,sl3)+.5*bs)*2.*uP1.xyz-uP1.xyz-ro,ex3=bs*2.*uP1.xyz+1e9*kFa;
        float cz=max(dot(c3,cw),1e-3),fR=.5*min(ex3.x,min(ex3.y,ex3.z))/cz;
        vec2 fo2=vec2(dot(rd,cu),dot(rd,cv))/max(dot(rd,cw),.05)-vec2(dot(c3,cu),dot(c3,cv))/cz;
        vec2 fg=kMotif(fo2/fR*1.05,fract(h*37.7)<.34?1.:(fract(h*37.7)<.67?3.:6.),px/fR*1.05)*step(.01,dot(c3,cw))*smoothstep(4.,8.,fR/px)*smoothstep(30.,30.*.6,fR/px);
        kFg+=wk*vec4((h>.85?kc2:(sw?kc3:kc2))*(1.+.9*lv*lv+1.6*on)*fg.y,fg.y);kFn+=wk*fg.x;
      }
      kBl=mix(kBl,wB,kFH);
      // edge-on walls: the streaks are calmed toward the hall's deep rose tone (they keep a quarter of their contrast), and carry no figure
      kBl=mix(kBl,mix(kc1,kc4,.5)*.8,kFS*.5);
    }
    {float fF=smoothstep(.02,.045,pf)*fDisc*kFH;
     if(fF>.003){vec3 fcl=kBl*(1.25+.7*max(uP5.y-.3,0.)+1.4*band+.8*hatW+.4*sd*sd)*(1.-.85*smoothstep(.84,.95,rq))*(.6+.4*sqrt(ao));
       col=mix(col,fcl*(1.-.88*ecl),fF);}}
    // v20: the long plain brown spindles were the hyperboloid's spines (where rxy goes to 0 the slab |rxy z| = e runs out along z, and every pattern here pinched
    // to nothing). A spine has its own coordinates, around it and along log|z|, so it becomes a jewelled spear: courses of chevrons in the edge colours, each
    // course lit by its own band of the spectrum, ruled by crisp dark lines, with a pearl in the middle of every other chevron.
    {
      // v20b: a spear too far away for its courses fell back to the mean of the two edge colours, which for orange and cyan is pale grey: that was the pale speckle of
      // every distant wall (and what the hall's atmosphere then tinted lilac). It now hands over to the bay's bold flat colour at the same distance as the windows do
      float spn=(1.-onB)*smoothstep(.15,.3,abs(fp.z))*(1.-smoothstep(.2,.42,sl))*(1.-kFH*smoothstep(.02,.045,pf));
      if(spn>.003){
        float sb=log(max(abs(fp.z),.02))*10.,sA=fract(ang*8.),sc=abs(sA-.5)*2.,sf=sb+.7*sc,sid=floor(sf),sfw=max(fwidth(sb),.002);
        float sT=mod(sid,3.),sBi=mod(sid,8.);
        vec3 sC=sT<1.?kc2:(sT<2.?kc3:mix(kc2,kc4,.6));
        vec4 sOh=vec4(equal(vec4(mod(sBi,4.)),vec4(0.,1.,2.,3.)));
        float sLv=dot(mix(uB1,uB2,step(4.,sBi)),sOh),sOn=dot(mix(uO1,uO2,step(4.,sBi)),sOh);
        float sFade=1.-smoothstep(.3,.75,sfw),sRule=(1.-smoothstep(0.,.08+sfw,abs(fract(sf)-.5)-.38))*sFade;
        float sMid=abs(fract(sf)-.5),sDot=(1.-smoothstep(.12,.16+sfw,length(vec2((sA-.5)*.5,sMid*.35))))*step(.5,mod(sid,2.))*sFade;
        // inside each course a second, finer line of chevrons and a row of lozenges, so a spear close to the camera is never a plain band
        float sF2=fract(sf*3.),sL2=(1.-smoothstep(.0,.06+3.*sfw,abs(sF2-.5)-.22))*(1.-smoothstep(.1,.28,sfw));
        float sLz=abs(fract(ang*24.+sb*.5)-.5)+abs(fract(sf)-.5)*.9,sLzL=(1.-smoothstep(.17,.2+3.*sfw,sLz))*(1.-smoothstep(.08,.22,sfw));
        sC=mix(mix(kc2,kc3,.5),sC,sFade);sLv=mix(.5*(uB1.y+uB2.y),sLv,sFade);sOn*=sFade;
        vec3 sCol=sC*(.46+.16*mod(sid,2.)+1.3*sLv*sLv+2.2*sOn)*(1.-.8*sRule)*(1.-.55*sL2)+mix(kc4,vec3(1.),.25)*sDot*(.5+1.5*uB2.y*uB2.y+2.5*uO2.y)+kRot(sC,kRs)*sLzL*(.45+1.2*uB2.x*uB2.x+1.5*uO2.x);
        col=mix(col,sCol*(1.+.45*max(uP5.y-.3,0.)*mod(sid,2.))*uP4.w*(.55+.45*sqrt(ao))*(1.-.8*ecl),spn);
      }
    }
    // where a bay is under about ten pixels everything in it takes its block's colour (ground, rims and spears too: at that size they were only noise of other hues)
    col=mix(col,kBl*(1.25+.7*max(uP5.y-.3,0.)+.4*sd*sd)*(.5+.5*sqrt(ao))*.62*uP4.w*(1.-.85*ecl),kFD*(1.-smoothstep(.02,.045,pf)*fDisc));
    // v20b second pass: the block's figure goes on last, over discs, spears and ground alike: ground deepens around it, the figure is the second ink, its rule is ink
    {float wM=max(kFD,kFH*smoothstep(.02,.045,pf))*(1.-kFS)*1.;
     if(wM>.003){col*=mix(1.,.7,wM*(1.-kFg.w));
       col=mix(col,kFg.rgb/max(kFg.w,1e-3)*1.4*(.6+.4*sqrt(ao))*uP4.w*(1.-.85*ecl),wM*kFg.w);
       col*=1.-.8*wM*kFn;}}
    // aerial depth: near layers keep their body colour, far layers dissolve into the luminous atmosphere
    float fg=exp(-t*uP3.w);
    float focus=exp(-(1.-vf)*11.);
    // the mid-ground haze keeps a little body colour, so dense crust reads as tinted glass, not black speckle
    // in the great hall the far walls dissolve into luminous haze layers (scale), not into dark speckle
    float hzW=hzA;
    vec3 fogC=(kc0*.55+kc1*.07*smoothstep(1.5,7.,t)+kc4*(.05+.8*focus+.11*hzW)*smoothstep(2.,16.,t))*uP4.w*(1.-.8*ecl);
    // v20b: in the great hall the air is clear. Its fog laid the atmosphere colour over half of every wall beyond the nearest (the lilac or magenta veil over the windows)
    fg=mix(fg,max(pow(fg,.4),.7),smoothstep(1.,5.,hR));
    col=col*fg+fogC*(1.-fg);
  }
  // silhouette halos: every edge the rays graze glows, near halos in edge A, far ones in the atmosphere colour
  vec3 gC=mix(kc1*1.4,kc4,smoothstep(1.,12.,gd));
  col+=gC*(glow/(1.+.7*glow))*(.10+.10*kS)*(.7+.3*uLevel);
  // (v14) SHAFTS OF LIGHT. The air is dusty and the high windows lay broad shafts down the nave. A shaft is a
  // cylinder of light: the ray's chord through it is the volumetric amount of lit dust along that view line, so the
  // beams have real depth, have soft edges, slide past as the walker flies, and are cut where stone stands. Three
  // axes on the lattice period, no loop over the march, no extra draw.
  {
    float P2=2.*uP1.x,shB=0.;
    vec3 SD=normalize(vec3(.44,-1.,.16));
    float bSD=dot(rd,SD);
    vec3 rdp=rd-SD*bSD;float a=max(dot(rdp,rdp),1e-4);
    for(int k=KN0;k<3+2*HD;k++){
      float fk=float(k);
      float xk=(floor(ro.x/P2)+1.+fk)*P2;
      vec3 S=vec3(xk,uM1[1].y+1.05,uP1.z+(mod(fk,2.)*2.-1.)*.38);
      vec3 w=ro-S;float wd=dot(w,SD);vec3 wp=w-SD*wd;
      float b=dot(wp,rdp),c=dot(wp,wp)-.105;                // .105 = a shaft radius of about .32
      float disc=b*b-a*c;
      float sq=sqrt(max(disc,0.));
      float t0=max((-b-sq)/a,0.),t1=min((-b+sq)/a,min(t,FAR));
      float len=max(t1-t0,0.);
      // axial fade: the shaft starts at the high window and thins as it reaches the floor
      float u=wd+t0*bSD;
      shB+=len*exp(-max(u,0.)*.30)*smoothstep(-.15,.30,u)*(1.-smoothstep(1.4,2.6,u));
    }
    shB*=1.-.55*smoothstep(.4,6.,hR);                       // the great hall's own arches take over its light
    vec3 shC=mix(mix(kc4,vec3(1.),.35),vec3(1.,.86,.63),.45);
    col+=shC*shB*(.10+.12*uB1.y*uB1.y)*(.7+.3*uP4.w)*(1.-.55*ecl);
  }
  // the great hall's neon arches: every lace rib of the vault carries a ring of neon and a necklace of pearls, the
  // KLNN tracery at cathedral scale. Arches light as the beat ring passes them; every pearl is one of the 8 frequency
  // bands (its level sets the glow, its onset flashes it white). All rings lie on one elliptic cylinder just inside the
  // vault, and a ray's section radius grows monotonically near where it leaves that cylinder, so the arch plane nearest
  // that exit is the only one it can touch: one analytic evaluation, no loop over arches.
  if(hR>.02&&lant>.002){
    float wa=.03+.0035*hR,st=TAU/(48.+16.*mod(hsty,2.)),mp=3.+mod(floor(hsty*.5),2.);
    vec2 ab=vec2(kHA,kHB)*(1.-.3*min(.3,.3*P/hR)),o=kHO.zy;
    float tx=kEll(o,rd.zy,ab).y;
    float rx=(rd.x<0.?-1.:1.)*max(abs(rd.x),.02);
    float n=floor((ro.x+rd.x*tx)/P),ta=((n+.5)*P-ro.x)/rx;
    vec2 cn=(o+rd.zy*ta)/ab;
    float lc=max(length(cn),1e-4),dl=abs(lc-1.)*lc/max(length(cn/ab),1e-6);
    // pearls around the ring (48 or 64): position along the ring from the angle, arc length from the section
    float th=kAt(cn.y,cn.x),j=floor(th/st+.5);
    float db=length(vec2(dl,(th-j*st)*length(vec2(ab.x*cn.y,ab.y*cn.x))/lc)),rb=1.9*wa;
    // pixel footprints from screen derivatives (the branch is uniform, so they are well defined)
    float fl=max(fwidth(dl),1e-4),fb=max(fwidth(db),1e-4);
    float vis=step(.4,ta)*step(ta,t)*exp(-ta*uP3.w*.4)*smoothstep(4.,10.,ta);
    // (v11) rays running down the hall's axis would see every arch as one ring of a giant bullseye (the "big circle"):
    // the arches only show as arcs across the walls and the vault
    vis*=1.-smoothstep(.42,.7,abs(rd.x));
    // in the widest halls every third or fourth arch is a major one (pearls, full neon); those between fade to lines
    float maj=step(mod(n,mp),.5),wide=smoothstep(12.,26.,hR);
    float line=(1.-smoothstep(wa-fl,wa+fl,dl))*min(1.,wa/fl);
    float pe=fb/rb,pr=db/rb,pearl=(1.-smoothstep(1.-pe,1.+pe,pr))*(1.25-.7*pr)*min(1.,rb/fb);
    float bi=mod(n*3.+j*5.,8.);
    vec4 oh=vec4(equal(vec4(mod(bi,4.)),vec4(0.,1.,2.,3.)));
    float lvB=dot(mix(uB1,uB2,step(4.,bi)),oh),onB=dot(mix(uO1,uO2,step(4.,bi)),oh);
    float bpA=uBuild>.5?fract(uBeat*2.):uBeat;
    float ring=exp(-knSquarePortable(abs(n-floor(ro.x/P-.5))-.5-bpA*7.)*.8)*uP5.w;
    col+=vis*(mix(kc2,kc3,mod(n,2.))*line*(.35+.5*uB1.w+1.6*ring)*mix(1.,.35+.65*maj,wide)+mix(mix(kc3,kc4,step(2.5,bi)),vec3(1.),.25+.5*onB)*pearl*(.3+1.4*lvB+2.5*onB)*mix(1.,maj,wide))*lant*1.7;
  }
  // the palette front: a glowing band between the old palette and the new one as it sweeps toward the camera
  col+=mix(mix(kc2,kc3,.5+.5*sin(tW*1.3)),vec3(1.),.3)*front*.45;
  // the engine brightens the whole frame on a drop: hold the fill back so the hit is carried by coloured light, not clipping
  col/=1.+.75*uDrop*uDrop;
  // soft knee on the brightest channel (hue kept): the engine's drop flash on hot magenta or orange never clips flat
  // during a drop the knee is hue-aware: dark hues (violet, blue, red) meet the screen's limit at a lower level than
  // cyan or gold after the engine's drop exposure, so they are held back further (the blasted hall's violet haze used to
  // clip a quarter of the frame)
  {float cm=max(col.r,max(col.g,col.b)),dk=max(min(uDrop*2.,1.),hzA)*(1.-.6*pow(vf,400.)),kn=mix(1.5,mix(.12,.6,smoothstep(.07,.7,dot(col,vec3(.2126,.7152,.0722))/max(cm,1e-4))),dk)/(1.+.5*uDrop);
   float kw=mix(.8,.3,dk)*kn;col*=cm>kn?(kn+kw*(1.-exp(-(cm-kn)/kw)))/cm:1.;
   // and the hottest violets and blues (whose blue channel is several times their luminance) lean a little toward
   // lavender at the same luminance, so a blasted hall's glowing haze stays colour instead of a clipped flat blue
   float L=dot(col,vec3(.2126,.7152,.0722)),rr=max(col.r,max(col.g,col.b))/max(L,1e-4);
   col=mix(col,mix(vec3(L),col,min(1.,1.5/max(rr-1.,1e-3))),dk*smoothstep(.04,.12,L));}
  // a touch of extra chroma, so the band flashes (which push colours up into the tone curve's shoulder) stay vivid
  col=max(mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.27+.3*hzA),0.)*(1.03+.08*hzA);   // (v11) the hall keeps the light the porthole glow carried
  fragColor=vec4(col,0.);
}`;
