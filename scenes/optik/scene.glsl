const R_OPTIK = `
// OPTIK. Neon op-art: Vasarely Vega checkers (balls, pyramids, Hommage nested squares, wave-warped lattices),
// Riley stripe fields, Zebra contours and moire interference, impossible / striped cube tilings, a gallery of
// twisted square tunnels and polar zigzag checkers. The flat plane is bent by a stack of moving lenses (a big focal
// sphere on the sub/bass, four satellites on the mid bands) and, beyond the frame, by a vast two-scale field of
// lenses each tied to its own band, so zooming out reveals an endless op-art wall swelling and sinking with the
// music. Every pattern is box-filtered against its own pixel footprint (chain rule through the lens map), so
// stripes never moire. Snares invert figure/ground behind a sweeping wipe, kicks send a ripple out of the focal
// sphere, drops and phrases iris into another illusion.
vec3 oS0,oS1,oS2,oS3,oS4;vec4 oB1,oB2;
vec2 oEU;float oEW;int oZ;
#if HD>=1
#define oZi 0
#else
#define oZi oZ
#endif
float oPx,oKE,oEv,oFS,oAx,oHat,oSn;vec2 oP,oRim;
#if HD>=5
const float oDF=1.4,oSS=4.,oHK=.44;
#elif HD==4
const float oDF=1.35,oSS=3.,oHK=.5;
#elif HD==3
const float oDF=1.3,oSS=2.,oHK=.58;
#elif HD==2
const float oDF=1.25,oSS=1.5,oHK=.66;
#elif HD==1
const float oDF=1.15,oSS=1.,oHK=.78;
#else
const float oDF=1.,oSS=1.,oHK=1.;
#endif
// ten curated 5-stop palettes, precomputed (linear, dark stops lifted, stored as sqrt and packed 8:8:8 at 2x range);
// a one-hot dot product picks the palette without a branch chain
vec3 opkU(float x){return vec3(mod(x,256.),mod(floor(x/256.),256.),floor(x/65536.))*(2./255.);}
void opkLoad(float P){
  float h=.35*sin(uHue*TAU),ca=cos(h),sa=sin(h),k=.57735,o=(1.-ca)/3.;
  // small hue nudge from the global drift (a rotation about the grey axis, applied in the sqrt space)
  mat3 H=mat3(ca+o,o+k*sa,o-k*sa, o-k*sa,ca+o,o+k*sa, o+k*sa,o-k*sa,ca+o);
  vec4 o1=max(1.-abs(P-vec4(0.,1.,2.,3.)),0.),o2=max(1.-abs(P-vec4(4.,5.,6.,7.)),0.);vec2 o3=max(1.-abs(P-vec2(8.,9.)),0.);
  oS0=H*opkU(dot(o1,vec4(9701423.,11605504.,9836099.,8413440.))+dot(o2,vec4(8401920.,10625792.,6955904.,9969920.))+dot(o3,vec2(8419188.,4355072.)));
  oS1=H*opkU(dot(o1,vec4(4067195.,8417536.,2490496.,9764943.))+dot(o2,vec4(7733346.,8410624.,1720704.,8412672.))+dot(o3,vec2(8411392.,8403200.)));
  oS2=H*opkU(dot(o1,vec4(12928.,32848.,14720.,6815872.))+dot(o2,vec4(1838208.,6455296.,2324352.,1862784.))+dot(o3,vec2(11210279.,9442890.)));
  oS3=H*opkU(dot(o1,vec4(289152.,2256768.,26240.,3090560.))+dot(o2,vec4(17792.,30336.,5603363.,16512.))+dot(o3,vec2(2230400.,4922496.)));
  oS4=H*opkU(dot(o1,vec4(8415232.,6886016.,5011968.,809344.))+dot(o2,vec4(29056.,4329600.,8405283.,658048.))+dot(o3,vec2(681600.,2253184.)));
  oS0=max(oS0,0.);oS1=max(oS1,0.);oS2=max(oS2,0.);oS3=max(oS3,0.);oS4=max(oS4,0.);
}
// curated 5-stop gradient, ping-ponged so it never wraps through a muddy seam; returns linear colour
vec3 opkGrad(float t){
  float x=abs(fract(t*.5)*2.-1.)*4.;
  vec3 c=oS0+(oS1-oS0)*smoothstep(0.,1.,x)+(oS2-oS1)*smoothstep(1.,2.,x)+(oS3-oS2)*smoothstep(2.,3.,x)+(oS4-oS3)*smoothstep(3.,4.,x);
  return c*c;
}
// v20b: hue direction of a colour (unit vector across the grey axis), and the palette stop farthest in hue from a given ink
vec3 opkCh(vec3 c){c-=dot(c,vec3(.33333));return c/max(length(c),1e-3);}
vec3 opkFar(vec3 n){
  vec3 a=oS0*oS0,b=oS1*oS1,c=oS2*oS2,d=oS3*oS3,e=oS4*oS4;
  vec4 w=vec4(dot(n,opkCh(a)),dot(n,opkCh(b)),dot(n,opkCh(c)),dot(n,opkCh(d)));float w4=dot(n,opkCh(e));
  // weight by hue distance (steep, so the result is one stop, not a mix) and by the stop's own chroma (never a pale stop)
  w=max(.5-.5*w,0.);w4=max(.5-.5*w4,0.);w*=w;w*=w;w*=w;w4*=w4;w4*=w4;w4*=w4;
  w*=vec4(a.r+a.g+a.b-3.*min(a.r,min(a.g,a.b)),b.r+b.g+b.b-3.*min(b.r,min(b.g,b.b)),c.r+c.g+c.b-3.*min(c.r,min(c.g,c.b)),d.r+d.g+d.b-3.*min(d.r,min(d.g,d.b)));
  w4*=e.r+e.g+e.b-3.*min(e.r,min(e.g,e.b));
  return (a*w.x+b*w.y+c*w.z+d*w.w+e*w4)/max(w.x+w.y+w.z+w.w+w4,1e-4);
}
// box-filtered pulse train: period 1, "on" for fract(x)<d; returns the on-fraction of a pixel of width w
float opkIP(float x,float d){return floor(x)*d+min(fract(x),d);}
float opkPulse(float x,float d,float w){
  w=max(w,1e-4);float a=(opkIP(x+.5*w,d)-opkIP(x-.5*w,d))/w;
  return mix(a,d,smoothstep(.5,1.,w));
}
// a pulse train that does not melt into a blur: where its period drops below ~3 px, pairs of stripes merge into one
// (an octave coarser). on=0 keeps the plain train.
float opkPL(float x,float d,float w,float on){
  return mix(opkPulse(x,d,w),opkPulse(x*.5,d,w*.5),smoothstep(.28,.5,w)*on);
}
float opkBar(float x,float hw,float w){w=max(w,1e-4);return clamp((hw-abs(x))/w+.5,0.,1.)*min(1.,2.*hw/w);}
// v20 INK. Black paper, flat inks. Hairlines cross a gap level by level as the lens or the zoom magnifies it (a centre line,
// then quarters, then eighths), so there is line work at every scale; u runs 0..1 across the gap, gpx is the gap in screen
// pixels. Thresholds relax with the detail tier (oHK), and the lines are never thinner than half a screen pixel.
float oHr,oCt,oIv,oSw;
float opkHair(float u,float gpx){
  float wu=1./max(gpx,1e-3),wr=wu/oSS,hw=max(.5*wu,.016)*(1.+1.2*oHat+.5*oB2.w);
  float a=smoothstep(7.*oHK,11.*oHK,gpx)*opkBar(u-.5,hw,wr);
  float b=smoothstep(20.*oHK,30.*oHK,gpx)*opkBar(abs(u-.5)-.25,hw*.8,wr);
  float c=smoothstep(52.*oHK,76.*oHK,gpx)*opkBar(abs(abs(u-.5)-.25)-.125,hw*.64,wr);
  return max(a,max(b,c))*step(0.,u)*step(u,1.);
}
// a pulse train drawn in ink: returns the coverage, and leaves hairlines in its black gaps (oHr) and thin black cuts in its
// inked stripes (oCt); oIv swaps them where figure and ground are exchanged
float opkInkP(float x,float d,float w,float on){
  d=clamp(d+.08*oKE+.05*oB1.y-.05,.08,.66);
  float f=fract(x),ws=max(w*oSS,1e-4),g=1.-d,k=1.-smoothstep(.2,.4,w)*on;
  float inS=step(f,d),h=opkHair(mix((f-d)/g,f/d,inS),mix(g,d,inS)/ws)*k,sw=abs(inS-oIv);
  oHr=max(oHr,h*(1.-sw));oCt=max(oCt,h*sw);
  return opkPL(x,d,w,on);
}
float opkSeg(vec2 p,vec2 b){float h=clamp(dot(p,b)/dot(b,b),0.,1.);return length(p-b*h);}
// band i (0 sub .. 7 air): the engine's band envelope (one-hot pick, no branches)
float opkBand(float i){return dot(max(1.-abs(i-vec4(0.,1.,2.,3.)),0.),oB1)+dot(max(1.-abs(i-vec4(4.,5.,6.,7.)),0.),oB2);}
// globals shared by the stages: screen pixel in plane units, the flat (pre-lens) plane point, the kick envelope,
// the lens-storm event, and the band rim lights (x: strength, y: strength x gradient position)
// a lens: radial remap of the plane (k>0 bulge/sphere, k<0 dimple); accumulates height and its gradient (hg.xyz)
// and the shadow a bulge casts down-right, away from the key light (hg.w: crisp core, soft penumbra). lt lights a
// 1.5 px ring on the lens rim in gradient colour tb (each band its own colour)
void opkLens(inout vec2 q,inout vec4 hg,vec2 c,float R,float k,float m,float lt,float tb){
  R=max(R,1e-3);
  vec2 d=q-c;float r2=dot(d,d),R2=R*R;
  float sx=length(d-R*vec2(.13,-.17))/(R*1.04);
  hg.w=max(hg.w,(.7-.7*smoothstep(.9,1.01,sx)+.3-.3*smoothstep(.55,1.15,sx))*smoothstep(R2*.98,R2*1.05,r2)*clamp(k*1.5,0.,1.));
  float rd=(r2-R2)/(2.*R*oPx),rl=exp(-rd*rd*.45)*lt*min(abs(k)*4.,1.);
  oRim+=vec2(rl,rl*tb);
  // branch-free: outside the lens u=0, so nothing moves
  float u=max(1.-r2/R2,0.),sm=step(1.5,m),um=mix(u,u*u,sm);
  q=c+d*(1.-k*um);
  float pp=mix(.75,1.5,sm),uc=max(u,.03),su=sqrt(uc),pu=mix(inversesqrt(su),su,sm)*step(1e-9,u);
  hg.xyz+=k*vec3(-2.*pp*pu*d/R,R*pu*uc);
}
// nearest site of a unit hex lattice
vec2 opkHex(vec2 a){
  const vec2 sv=vec2(1.,1.7320508);
  vec4 hc=floor(vec4(a,a-vec2(.5,1.))/sv.xyxy)+.5;
  vec2 A=a-hc.xy*sv,B=a-(hc.zw+.5)*sv;
  return mix((hc.zw+.5)*sv,hc.xy*sv,step(dot(A,A),dot(B,B)));
}
// the wall beyond the frame: two hex lattices of lenses (giant swells and smaller bulges/dimples), each lens on its
// own band; they fade in away from the focal composition, so they only show when the view pulls back.
// Returns the lens (centre, radius, strength) for lattice j at plane point q; m: profile for this lens.
// bi returns the lens's band (0..7); the radius carries its rim light (the band's level, peaky) packed like the
// composition lenses' (radius + 2 x light in 1/100)
vec4 opkSite(vec2 q,float fj,inout float m,out float bi){
  float Ls=mix(5.2,2.1,fj)*(1.-.55*oEv);
  vec2 dr=vec2(.023,.011)*uMT*(1.-.6*(1.-fj));
  vec2 s=opkHex(q/Ls+dr),c=(s-dr)*Ls;
  float hs=h21(s*vec2(1.37,2.11)+fj*7.1+uSeed.x*13.);
  // the lens storm event pulls the wall right up to the focal composition
  float fade=smoothstep(mix(2.6,1.6,fj)*(1.-.8*oEv),mix(3.8,2.3,fj)*(1.-.75*oEv),length(c-uP2.xy*.6));
  bi=floor(fract(hs*7.13)*8.);
  float lv=opkBand(bi);
  float sg=mix(1.,-.55,step(fract(hs*3.71),.36));
  m=1.+max(step(2.5,m),step(fract(hs*9.1),.3));
  return vec4(c,Ls*(.26+.09*fract(hs*5.3))+2.*floor(10.+120.*lv*lv*lv),sg*(.22+.42*lv+.08*sin(uMT*.5+hs*40.))*oFS*fade*mix(.8,1.,fj));
}
float opkShim(vec2 id){float s=max(1.-abs(fract(uTime*.37+h21(id+uSeed.xy)*9.)-.5)*3.6,0.);return s*s*oHat*1.15;}
float opkAsp(){return uRes.x/uRes.y;}
// pulled far back, cells grow (zoom^.5) so they stay readable while the view still opens up ~7x wider; pushed in
// (v13), the pattern gets denser (zoom^.7) so the lenses grow but the cells only grow ~1.3x at 2.5: finer detail,
// never a few big flat cells
float opkZD(){return uZoom<1.?sqrt(max(uZoom,.1)):pow(min(uZoom,3.),.7);}
// Families return a colour as weights over three gradient colours and white: (C(t), C(t+o1), C(t+o2), white).
// They set the gradient position oT and offsets oO1/oO2; the gradient itself is evaluated once, after the switch.
float oT,oO1,oO2,oSp,oGlow;
// Shared cell pipeline for VEGA, STRIPES, TUNNEL and BLAZE. Each family only builds pattern coordinates U (in cells)
// with a per-axis pixel footprint W; this draws the field (md.x: 0 checker, 1 lattice of grid lines, 2 stripes of
// duty md.y, 3 rings), raised-tile bevels, and one inner decoration per cell: a lit ball, diamond, square, ring, or a
// Hommage stack of nested squares/discs (a stepped pyramid seen from above), or a peripheral-drift tile;
// stripes get a hairline down every dark stripe instead. xo >= 0 is a second grating XORed in (moire).
// md.z: figure gain, md.w: overall gain (depth fog). R maps plane directions into the cell frame.
vec4 opkCells(vec2 U,vec2 W,vec2 tk,float tb,vec4 md,float shape,float duo,float iv,vec3 hg,mat2 R){
  float lat=step(.5,md.x)*step(md.x,1.5),str=step(1.5,md.x)*step(md.x,2.5),rng=step(2.5,md.x);
  float w=max(W.x,W.y);
  vec2 id=floor(U),f=fract(U)-.5;
  float kx=mix(.5,1.,max(lat,str)),dx=mix(mix(.5,.14,lat),md.y,str);
  float ax=str>.5?opkInkP(U.x,dx,W.x,1.):opkPL(U.x*kx+lat*.07,dx,W.x*kx,0.),ay=mix(opkPulse(U.y*kx+lat*.07,dx,W.y*kx),1.,rng);
  float chk=mix(mix(.5+.5*(2.*ax-1.)*(2.*ay-1.),ax+ay-ax*ay,lat),ax,str);
  // tunnels and blazes stream their tiniest cells toward the vanishing point: fade their contrast there so the
  // moving sub-4 px checks never shimmer
  chk=mix(chk,.5,oAx*smoothstep(.16,.42,w));
  float par=mod(id.x+id.y*(1.-rng),2.);
  float fF=mix(abs(1.-par-iv),iv,lat);          // 1 on figure cells
  oT=dot(id,tk)+tb+uP5.y+hg.z*3.;oO1=.4+.15*duo;oO2=.27;
  float tw=opkShim(id);
  vec4 FIG=vec4(md.z*(1.+1.3*tw+.3*oKE+.25*oB1.y),0.,0.,0.),GND=vec4(0.,.07*duo,0.,0.),AC=vec4(0.,0.,1.28,0.)*(1.+.9*oHat)+vec4(0.,0.,0.,.25*oHat);   // hats light every cell's accent decoration
  vec4 col=mix(GND,FIG,abs(chk-iv));
  vec2 Lc=R*vec2(-.55,.6);
  // raised tiles: a bevel catches the key light on one side and falls into shade on the other
  float e=.5-max(abs(f.x),abs(f.y));
  float lod=smoothstep(.42,.18,w);
  col*=1.+smoothstep(.075+.6*w,.075-.6*w,e)*lod*2.*(1.-lat)*(1.-str)*.6*dot(f,Lc)*(2.*fF-1.);
  // v20: an inset frame line in every cell (accent hairline in the black cells, a black cut in the inked ones)
  {float fr=opkBar(e-.075,max(.011,.5*w*oSS),w)*smoothstep(.1,.05,w*oSS)*(1.-str)*(1.-rng);oHr=max(oHr,fr*(1.-fF));oCt=max(oCt,fr*fF);}
  if(str>.5){
  }else if(lod>0.){
    float rad=clamp(.2+.75*hg.z+.08*(oSp-.3)+.05*oKE+.1*oSn+.06*lat+.09*oB1.w+.04*oB1.z,.05,.45);
    float hom=step(3.5,shape);
    // Hommage level index lv, solved analytically
    float sz=.1*(.7+.75*rad),sq=step(shape,4.5);
    float lv=(4.4*sz-mix(length(f)*.94,max(abs(f.x),abs(f.y)),sq))/sz;
    float lf=length(f);
    float sd=mix(mix(lf-rad,(abs(f.x)+abs(f.y))*.7071-rad*.82,step(.5,shape)),mix(max(abs(f.x),abs(f.y))-rad*.8,abs(lf-rad*.9)-.085,step(2.5,shape)),step(1.5,shape));
    sd=mix(sd,-lv*sz,hom);
    // one box-filtered pulse: the Hommage level parity, or concentric echoes inside the shape where the lens
    // magnifies them above the pixel size (mid-band onsets brighten them)
    float pv=opkPulse(mix(-sd*11.*oDF+uP5.y*3.,min(lv,3.99)*.5,hom),mix(.42,.5,hom),mix(w*11.*oDF,w*.5/sz,hom));
    float rings=pv*mix(smoothstep(.04,.022,w)*step(sd,0.)*(1.+.6*oB1.w)*mix(.85,1.,fF),1.,hom);
    vec4 e3=vec4(0.,0.,0.,.003);
    vec4 A1=mix(mix(AC*(1.+tw),GND*1.5+e3,fF),mix(GND*1.3+e3,FIG*.95,fF),hom);
    vec4 B1=mix(mix(GND,AC,fF),mix(AC*.9,GND*1.4+e3,fF),hom);
    vec4 sc=mix(A1,B1,rings)*mix(1.,(1.+.13*clamp(lv,0.,4.))*(1.+tw),hom);
    if(shape<.5){
      // balls: each dot is a little lit sphere (a bump on ground cells, a dent in figure cells)
      vec2 nb=f/max(rad,.05),hd=nb-Lc*.42;float sg=1.-2.*fF,hl=max(1.-dot(hd,hd),0.);hl*=hl;hl*=hl;hl*=hl;
      sc=sc*(.3+.91*clamp(dot(nb*sg,Lc)+.62*sqrt(max(1.-dot(nb,nb),0.)),0.,1.))+vec4(0.,0.,0.,hl*(1.-fF)*(.35+.9*oB2.y)*smoothstep(.3,.12,w));
    }
    col=mix(col,sc,smoothstep(.75*w,-.75*w,sd)*lod*step(shape,6.5));
    // peripheral drift (Kitaoka): every tile carries the luminance run black, dark, white, light along its row or
    // ring, alternate rows reversed, so the field seems to creep and turn by itself. A snare (figure/ground)
    // reverses it, the kick flashes its contrast (flicker is what drives the illusion)
    float rc=mix(f.x,f.y,oAx)*(1.-2.*mod(mix(id.y,id.x,oAx)+iv,2.));
    float x4=(rc+.5)*4.,aw=4.*mix(W.x,W.y,oAx)+.03;
    float s1=clamp((x4-1.)/aw+.5,0.,1.),s2=clamp((x4-2.)/aw+.5,0.,1.),s3=clamp((x4-3.)/aw+.5,0.,1.);
    float fl=1.+.4*oKE;
    vec4 dc=vec4(1.3*s3*fl*(1.+tw),.3*(s2-s3),.6*(s1-s2),.003+(.6*fl+.5*tw)*(s2-s3));
    col=mix(col,mix(GND*.4,dc,smoothstep(.035-w,.035+w,e))*(1.+.4*fF),step(5.5,shape)*step(shape,6.5));
  }
  return col*md.w;
}
// ---- family 2: CUBE. rhombille tiling read as cubes: engraved contours, Vasarely Tridim striped faces, an
// impossible cube with a reversed corner nested inside each one, or a Schroeder-stair field (every other pair of
// rows lit from the other side, so the cubes read as stairs going up and down at once). Snares flip them (Necker).
vec4 opkCube(vec2 q,float pw,vec3 hg,float iv,float bits){
  float cv=mod(bits,8.);
  float zd=opkZD(),dens=uP3.x*mix(.95,.68,step(1.5,cv))*zd*sqrt(min(zd,1.));
  vec2 v=(q-uP2.xy)*dens+vec2(uP3.z,uP3.z*.577);
  float w=pw*dens;
  const vec2 sv=vec2(1.,1.7320508);
  vec4 hc=floor(vec4(v,v-vec2(.5,1.))/sv.xyxy)+.5;
  vec2 a=v-hc.xy*sv,b=v-(hc.zw+.5)*sv;
  bool ab=dot(a,a)<dot(b,b);
  vec2 h=ab?a:b,id=ab?hc.xy:hc.zw+.5;
  // nested corner: inside the inner hexagon the shading permutes, so a reversed cube sits in the corner of each one
  float inr=step(1.5,cv)*step(cv,2.5)*step(max(abs(h.x),dot(abs(h),vec2(.5,.8660254))),.25);
  h*=1.+inr;
  float hexD=max(abs(h.x),dot(abs(h),vec2(.5,.8660254)))-.5;
  float e=min(min(opkSeg(h,vec2(.5,.288675)),opkSeg(h,vec2(-.5,.288675))),min(opkSeg(h,vec2(0.,-.57735)),-hexD))/(1.+inr);
  float dT=h.y,dL=dot(h,vec2(-.866,-.5)),dR=dot(h,vec2(.866,-.5));
  float face=dT>max(dL,dR)?0.:(dL>dR?1.:2.);
  // v20b snare: the Necker flip. The snare's ring out of the focal sphere flips whole cubes as it passes (the three inks move
  // one face on), cube by cube, so the wall reverses in a crisp travelling band; the generic ink exchange is switched off here
  float flp=step(abs(length(id*sv-vec2(uP3.z,uP3.z*.577))/dens-floor(uP4.y)/100.),.4)*step(.1,fract(uP4.y));oSw=0.;
  float fs=mod(face+inr+2.*iv+flp,3.);fs=mix(fs,2.-fs,step(2.5,cv)*mod(floor(id.y),2.));
  oT=dot(id,vec2(.075,.05))+uP5.y+hg.z*3.;oO1=.4;oO2=.8;oEU=v;oEW=w;
  float tw=opkShim(id);
  // v20: three line treatments instead of three flat tones. The lit face is solid ink cut by thin black lines, the middle
  // face a grating of the second ink (its duty plays the spectrum), the dark face black paper with hairlines of the third.
  // Far away the three duties average into the classic three-tone cube; close up every face is line work.
  float isT=step(.5,cv),gl=1.+1.2*tw+.55*oKE+.45*oB1.y+.45*oB1.z*step(fs,.5);
  float X=mix(e/(.055/oDF)-uP5.y*2.,(face<.5?-h.x+1.732*h.y:2.*h.x*(face<1.5?-1.:1.))*6.*oDF+.25,isT),wX=mix(w*oDF/.055,w*12.*oDF,isT);
  float dty=fs<.5?.8:(fs<1.5?clamp(.28+.22*oSp+.2*oKE+.08*oB1.y,.2,.62):.13+.17*oKE+.1*oHat+.05*oB2.w+.3*fract(uP4.y));
  oIv=0.;float pv=opkInkP(X,dty,wX,0.);
  vec4 fc=(fs<.5?vec4(1.12,0.,0.,0.)*gl:(fs<1.5?vec4(0.,1.05,0.,0.)*(1.+.5*oB1.w+.3*oB1.z):vec4(0.,0.,.9+1.6*oHat+.5*oB2.z,0.)))*pv;
  fc+=vec4(0.,0.,(1.-pv)*step(fs,.5)*(1.6*oHat+.5*oB2.w),0.);
  // v20b kick: the wireframe fires. Every cube edge (the black seam between faces) carries a line of the first ink for the
  // length of the kick, thickest on the hit
  return fc*smoothstep(.022-w,.022+w,e)+vec4(1.5*oKE*opkBar(e,.004+.012*oKE,w),0.,0.,.25*oKE*opkBar(e,.003,w));
}
// ---- family 5 QUASI: N line families at equal angles, XORed. The parity map is an endless non-repeating mosaic of
// little polygons (or, as ring gratings around N moving sources, interference fringes). Every line family is one band
// of the spectrum: when that band sings, its whole family of lines slides, so each instrument reshuffles the tiling its own way.
vec4 opkQuasi(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,8.),N=mix(5.,7.,mod(sub,2.)),rg=step(3.5,sub),hr=mod(floor(sub*.5),2.);
  vec2 v=q-uP2.xy;float dens=uP3.x*(.8+.3*rg)*opkZD()*mix(.5,1.,smoothstep(.2,.7,uZoom)),wp=pw*dens,xr=0.,lv=0.,ed=1.;
  for(int i=oZi;i<7;i++){
    if(float(i-oZi)>=N)break;
    float fi=float(i-oZi),a=fi*PI/N+uP3.y*.5,b=opkBand(mod(fi*8./N,8.));
    vec2 dir=vec2(cos(a),sin(a));
    float s=rg>.5?length(v-dir*vec2(1.3,.8)*(1.+.14*sin(uMT*.05+fi*2.)))*dens:dot(v,dir)*dens*(1.+.07*fi);
    s+=(mod(fi,2.)*2.-1.)*uP3.z*.33+1.5*b+.3*oKE;
    float p=opkPulse(s,.5,wp);
    xr=xr+p-2.*xr*p;lv+=p;
    ed=min(ed,abs(fract(s+.5)-.5));
  }
  oT=lv*.135+uP5.y+hg.z*2.+.12*hr;oO1=.42;oO2=.77;
  oEU=v*dens*1.4;oEW=wp*1.4;
  float tw=opkShim(floor(oEU));
  vec4 FIG=vec4(1.2*(1.+.8*oB1.z+1.2*tw),0.,0.,0.),GND=vec4(0.,.015+.1*oSn,0.,0.);
  vec4 col=mix(GND,FIG,abs(xr-iv));
  return mix(col,vec4(0.,0.,1.+1.4*oHat+.5*oB2.z,.04+.6*oHat),opkBar(ed,mix(.05,.03,hr),wp)*smoothstep(.55,.2,wp));
}
// ---- family 6 QUILT: a quadtree of tiles, big ones on the low end and small ones on the highs. Tiles are Truchet arc
// bundles, concentric squares, diagonal slats or target rings, inked at every seam.
vec4 opkQuilt(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,8.),dens=uP3.x*.4*opkZD();
  vec2 v=rot(uP3.y)*(q-uP2.xy)*dens+vec2(uP3.z*.5,-uP3.z*.31);
  vec2 id=floor(v),f=v-id;
  float s=1.,lv=0.,wp=pw*dens,hs,n=2.+mod(sub,2.)+clamp(floor(log2(max(uDetail,1.))),0.,3.);
  for(int i=oZi;i<6;i++){
    if(float(i-oZi)>=n)break;
    hs=h21(id*vec2(1.27,2.13)+s*vec2(7.,3.)+uSeed.xy*11.);
    if(hs<.3+.12*float(i-oZi)||wp*s*2.>.28)break;
    id=id*2.+floor(f*2.);f=fract(f*2.);s*=2.;lv+=1.;
  }
  hs=h21(id*vec2(2.31,1.73)+s*vec2(3.,7.)+uSeed.zw*9.);
  float w=wp*s,mo=floor(fract(hs*7.13)*(sub>3.5?2.:4.)),band=lv<.5?oB1.y:(lv<1.5?oB1.w:oB2.y),x,fg=mod(lv,2.);
  vec2 g=f;if(hs>.5)g.x=1.-g.x;
  vec2 c=f-.5;
  float e=.5-max(abs(c.x),abs(c.y));
  if(mo<.5){x=min(length(g),length(1.-g))*6.;}
  else if(mo<1.5){x=e*12.;}
  else if(mo<2.5){x=(g.x+g.y)*5.;w*=1.41;}
  else{x=length(c)*12.;}
  float wx=w*mix(6.,mix(12.,mix(5.,12.,step(2.5,mo)),step(1.5,mo)),step(.5,mo));
  x*=oDF;wx*=oDF;
  float duty=.5+.22*band+.1*oKE;
  oIv=mod(iv+fg,2.);float p=opkInkP(x-uP5.y*2.-1.5*band,clamp(duty,.15,.8),wx,1.);
  oT=hs*.62+lv*.2+hg.z*2.+uP5.y;oO1=.46;oO2=.74;
  oEU=c*4.;oEW=w*4.;
  float tw=opkShim(id);
  vec4 FIG=vec4(1.2*(1.+1.2*band+1.2*tw),0.,0.,0.),GND=vec4(0.,.03*fg,0.,0.);
  vec4 col=mix(GND,FIG,abs(p-mod(iv+fg,2.)));
  return mix(col,vec4(0.,0.,.9+1.5*oHat,0.)*.9+vec4(0.,0.,0.,.03),opkBar(e,.022+.008*(1.+lv),w)*smoothstep(.6,.25,w));
}
// ---- family 7 LOOM: a real over-under weave of round ribbons, plain, twill, basket and broken twill. Every warp and weft is
// one band of the spectrum, so columns and rows of the cloth each swell and glow on their own band; threads engraved along each.
vec4 opkLoom(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,4.),dens=uP3.x*1.05*opkZD(),wp=pw*dens;
  vec2 v=rot(uP3.y*.5)*(q-uP2.xy)*dens+uP3.zz*.4;
  vec2 id=floor(v),f=v-id-.5;
  float ov=sub<.5?mod(id.x+id.y,2.):(sub<1.5?step(mod(id.x+id.y,4.),1.):(sub<2.5?mod(floor(id.x*.5)+floor(id.y*.5),2.):step(mod(id.x+2.*id.y,5.),1.)));
  float bx=opkBand(mod(id.x,8.)),by=opkBand(mod(id.y,8.)),wx=.23+.11*bx,wy=.23+.11*by;
  float cx=opkBar(f.x,wx,wp),cy=opkBar(f.y,wy,wp);
  float wa=cx*(ov+(1.-ov)*(1.-cy)),we=cy*((1.-ov)+ov*(1.-cx));
  float isW=step(we,wa),pr=isW>.5?1.-f.x*f.x/(wx*wx):1.-f.y*f.y/(wy*wy),bn=isW>.5?bx:by;
  // v20: every ribbon is a bundle of ink lines (five, more on the higher tiers) on black, shaded round
  float u=isW>.5?f.x/wx:f.y/wy,wu=wp/(isW>.5?wx:wy);
  float th=mix(.6,opkPulse(abs(u)*2.*oDF+.27,.54,wu*2.*oDF),smoothstep(.5,.2,wu*2.*oDF));
  oT=(isW>.5?id.x*.21:id.y*.17+.5)+hg.z*2.+uP5.y;oO1=.33+.2*iv;oO2=.66;
  float lg=(.4+.6*max(pr,0.))*(.75+1.*bn)*th*(1.+.4*oKE)*1.25;
  float ctr=step(abs(u)*2.*oDF,.28);
  vec4 col=vec4(lg*isW*(1.-ctr),lg*(1.-isW)*(1.-ctr),lg*ctr*1.1,0.)*max(wa+we,0.);
  float tw=opkShim(id);
  col.xy*=1.+1.1*tw;
  return col;
}
// ---- family 8 SCALES: overlapping fans in offset rows (rows swell one after another on their own band, a kick sends a crest
// up them); each fan engraved with its ribs, rim, target eye or a pointed keel. The lens bulges carry them like armour.
vec4 opkScale(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,4.),dens=uP3.x*.5*opkZD(),wp=pw*dens;
  vec2 v=rot(uP3.y*.25)*(q-uP2.xy)*dens+vec2(0.,uP3.z*.3),cc=vec2(0.);
  float jr=floor(v.y*2.)-1.,d=1.,hs=0.,jc=0.,r0=.73;
  for(int j=oZi;j<4;j++){
    float xo=mod(jr,2.)*.5;vec2 c=vec2(floor(v.x-xo+.5)+xo,jr*.5),e=v-c;
    float h=h21(c*vec2(1.3,2.7)+uSeed.xy*7.),bnd=opkBand(mod(jr,8.)),r=r0*(1.+.1*bnd+.04*oKE);
    float dd=sub>2.5?(abs(e.x)*1.2+max(e.y+.3,0.)*.7):length(e);
    if(dd<r){d=dd/r;cc=e/r;hs=h;jc=jr;break;}
    jr+=1.;
  }
  float bnd=opkBand(mod(jc,8.)),w=wp/r0;
  float isF=step(.5,sub)*step(sub,1.5);
  float pv=opkInkP(mix(d*9.*oDF-uP5.y*2.-1.5*bnd,atan(cc.x,cc.y+1.2)*14.*oDF,isF),.42,mix(w*9.*oDF,w*14.*oDF/max(d,.1),isF),0.);
  oT=hs*.3+jc*.045+hg.z*2.+uP5.y+d*.28;oO1=.46;oO2=.74;
  oEU=cc*3.;oEW=w*3.;
  float tw=opkShim(vec2(jc,floor(hs*40.)));
  vec4 FIG=vec4(1.2*(1.+1.5*bnd+tw*1.2)*(.55+.55*d),0.,0.,0.),GND=vec4(0.,.03*d,0.,0.);
  vec4 col=mix(GND,FIG,abs(pv-iv));
  col=mix(col,vec4(0.,0.,.1,0.),opkBar(d-1.,.05,w));
  if(sub>1.5&&sub<2.5){float ey=length(cc-vec2(0.,.55));
    col=mix(col,vec4(0.,1.2,0.,.05+.5*oHat),opkBar(ey,.16+.1*oB1.x,w));}
  return col;
}
// ---- family 9 ROSETTE: star-polygon medallions on a lattice (8-, 12- or 6-fold, nested star rings). Every point of each
// star belongs to one band of the spectrum, so each medallion is a tiny spectrum clock; the core blooms on mids.
vec4 opkStar(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,4.),n=sub<.5?8.:(sub<1.5?12.:(sub<2.5?6.:16.));
  float dens=uP3.x*.5*opkZD(),wp=pw*dens;
  vec2 v=rot(uP3.y*.5)*(q-uP2.xy)*dens+vec2(uP3.z*.25,0.);
  vec2 id,f;
  if(n<6.5){vec2 hv=v*.9;vec2 h=opkHex(hv);id=h;f=(hv-h)/.9;wp/=.9;}else{id=floor(v);f=v-id-.5;}
  float r=length(f)+1e-4,a=atan(f.y,f.x);
  float seg=floor((a+PI)/TAU*8.),b=opkBand(seg),a2=abs(mod(a,TAU/n)-PI/n);
  vec2 p=r*vec2(cos(a2),sin(a2));
  // star edge line from the tip (R,0) to the valley: signed distance by the edge normal
  float R=.56,vr=.3*(1.+.1*b),va=PI/n;
  vec2 ve=vec2(vr*cos(va),vr*sin(va)),ed=normalize(ve-vec2(R,0.)),nm=vec2(-ed.y,ed.x);
  float sd=dot(p-vec2(R,0.),nm);
  float lv=-sd/(.075/oDF),pv=opkInkP(lv-uP5.y*3.-1.2*b,.5,wp*oDF/.075,0.);
  float hs=h21(id*vec2(1.7,.9)+uSeed.yz*5.);
  oT=hs*.45+floor(max(lv,0.))*.06+hg.z*2.+uP5.y;oO1=.42;oO2=.76;
  oEU=f*3.5;oEW=wp*3.5;
  float tw=opkShim(id+seg);
  vec4 FIG=vec4(1.2*(1.+1.5*b+1.2*tw),0.,0.,0.),GND=vec4(0.,.02,0.,0.);
  vec4 col=mix(GND,FIG,abs(pv-iv));
  float gap=opkPulse((f.x+f.y)*8.*oDF+uP5.y*2.,.2,wp*11.*oDF);
  col=mix(col,vec4(0.,(.85+.9*oB1.w)*gap,0.,0.),step(0.,sd));oHr*=step(sd,0.);oCt*=step(sd,0.);
  col=mix(col,vec4(0.,0.,.2,0.),opkBar(sd,.016,wp));
  col=mix(col,vec4(0.,0.,1.25*(1.+oB1.w),.15*oB1.z),max(opkBar(r-.07-.09*(oB1.z+oB1.w),.02,wp),opkBar(r,.028,wp)));
  return col;
}
// ---- family 11 ROWS: courses of tiles, each course sliding by its own band (rows slam across with the music), with a
// lit mortar line (the skew illusion of misaligned rows), chevrons, or rope twists.
vec4 opkRows(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,4.),dens=uP3.x*1.25*opkZD(),wp=pw*dens;
  vec2 v=rot(uP3.y*.25)*(q-uP2.xy)*dens;
  float row=floor(v.y),bnd=opkBand(mod(row,8.)),dir=mod(row,2.)*2.-1.;
  float sl=mod(row,2.)*.5+dir*(bnd*1.05+uP3.z*.2)+.13*sin(row*2.3);
  float fy=v.y-row-.5,x=v.x+sl;
  if(sub>.5&&sub<1.5)x+=abs(fy)*1.2*dir;
  if(sub>2.5)x+=fy*.8;
  float cell=floor(x);vec2 f=vec2(x-cell-.5,fy);
  float w=wp*(sub>.5&&sub<1.5?1.8:1.),p=opkInkP(x*.5,.5,w*.5,0.),hs=h21(vec2(cell,row)*vec2(1.3,2.7)+uSeed.xy*7.);
  oT=row*.26+hs*.35+hg.z*2.+uP5.y;oO1=.45;oO2=.72;
  oEU=vec2(x,v.y)*2.;oEW=w*2.;
  float tw=opkShim(vec2(cell,row));
  vec4 FIG=vec4(1.05*(.8+.9*bnd+tw*1.2)*(1.+.25*dir*f.x),0.,0.,0.),GND=vec4(0.);
  float tn=opkPulse((x*3.+abs(fy)*2.2*(sub<1.5?1.:-1.)+row*.5)*oDF,.28,w*3.*oDF);
  vec4 col=mix(GND,FIG,abs(p-iv));
  col*=1.-.85*tn*smoothstep(.5,.2,w*3.);
  col=mix(col,col*.5+vec4(0.,0.,.6,0.),opkBar(abs(f.y)-.32,.025,wp)*smoothstep(.4,.12,wp));
  return mix(col,vec4(0.,0.,.95+.9*oB1.z+.8*oB1.w,.06*oB2.y),opkBar(fract(v.y)-.5,.04,wp)*smoothstep(.6,.2,wp));
}
// ======== v20: eight more illusions (12 SNAKES, 13 ROTO, 14 STRING, 15 RIDGE, 16 MOVE lives in opkFam, 17 PINNA, 18 ENIGMA, 19 TRIBAR)
// ---- family 12 SNAKES: discs of rings cut into segments that run black, ink, white, ink (the peripheral-drift order), alternate
// rings offset half a segment, neighbouring discs wound the other way, so the whole wall seems to turn on its own. The rings
// really do turn as well: each ring is one band and twists on it; the kick swells every disc.
vec4 opkSnake(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,4.),dens=uP3.x*.2*opkZD(),wp=pw*dens;
  vec2 v=rot(uP3.y*.25)*(q-uP2.xy)*dens+vec2(uP3.z*.04,0.);
  vec2 h=opkHex(v),f=v-h;
  float hs=h21(h*vec2(1.3,2.1)+uSeed.xy*7.),dirn=step(.5,fract(hs*5.3))*2.-1.;
  float len=length(f)+1e-5,R=len*2./(.96+.05*oKE),NR=4.+mod(sub,3.);
  float rr=pow(R,.85)*NR,k=floor(rr),fr=fract(rr),b=opkBand(mod(k+floor(hs*8.),8.));
  float NS=6.*(k+1.),a=atan(f.y,f.x)/TAU,wr=wp*2.*NR;
  float s=dirn*((a-uP3.z*.012-.03*(b-.3)*(mod(k,2.)*2.-1.))*NS+.5*mod(k,2.))+(sub>2.5?rr*.6:0.);
  float aw=4.*wp*NS/(TAU*len)+.02,x4=fract(s)*4.;
  float s1=clamp((x4-1.)/aw+.5,0.,1.),s2=clamp((x4-2.)/aw+.5,0.,1.),s3=clamp((x4-3.)/aw+.5,0.,1.),s4=clamp((4.-x4)/aw,0.,1.);
  float tw=opkShim(h+k);
  vec4 c=vec4(1.1*(s1-s2)*(1.+.9*b),1.05*s3*s4*(1.+.5*b),0.,.9*(s2-s3)*(1.+tw+.4*oHat));
  c=mix(c,vec4(.27,.26,0.,.2),smoothstep(1.6,3.2,aw));
  c*=mix(smoothstep(.06-wr,.06+wr,min(fr,1.-fr)),1.,smoothstep(.3,.6,wr));
  // hub: an accent bead with a black eye
  c=mix(c,vec4(0.,0.,(1.2+1.6*oHat)*smoothstep(.16-wr,.16+wr,rr),0.),smoothstep(.42+wr,.42-wr,rr));
  c*=smoothstep(1.+wp*2.,1.-wp*2.,R);
  oHr=max(oHr,opkBar(R-1.05,max(.016,wp*oSS),wp*2.)*smoothstep(.12,.05,wp*oSS));
  oT=hs*.6+uP5.y+hg.z*2.;oO1=.5;oO2=.28;
  return c;
}
// ---- family 13 ROTO: nested circles (or squares) whose centres slide off along a turning arm, so the flat rings read as a
// deep cone leaning out of the wall and precessing: the rotorelief, and with squares the receding corridor. The lean follows the
// bass, every ring is a band (its width), rings march outward; variants shift alternate sectors, wind into a spiral or zigzag.
vec4 opkRoto(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,8.),sq=step(3.5,sub),sv=mod(sub,4.),S=1.18/sqrt(opkZD());
  vec2 v=(q-uP2.xy)/S,id=floor(v*.5+.5),f=v-2.*id;
  float hs=h21(id*vec2(1.7,2.3)+uSeed.zw*5.),own=step(dot(id,id),.5);
  float E=(.26+.3*max(oB1.x,oB1.y)+.08*oKE)*mix(.55+.45*hs,1.,own),th=uP3.z*.35*(step(.5,hs)*2.-1.)+hs*TAU,tw=(fract(hs*7.3)-.5)*2.2;
  float t=sq>.5?max(abs(f.x),abs(f.y)):length(f);
  vec2 d=f;
  for(int i=oZi;i<6;i++){
    float a=th+tw*t;d=f-E*max(1.-t,0.)*vec2(cos(a),sin(a));
    t=sq>.5?max(abs(d.x),abs(d.y)):length(d);
  }
  float N=uP3.x*3.4*oDF,ang=atan(d.y,d.x)/TAU,X=t*N-uP3.z*1.3,k=floor(X),b=opkBand(mod(k+64.,8.));
  if(sv>.5&&sv<1.5)X+=.5*step(.5,fract(ang*12.+k*.5));
  else if(sv>1.5&&sv<2.5)X+=ang*3.;
  else if(sv>2.5)X+=.8*abs(fract(ang*6.)-.5);
  float wX=pw/S*N*(1.+2.*E);
  float p=opkInkP(X,clamp(.46+.3*(b-.35),.2,.7),wX,1.);
  oT=floor(X)*.045+hs*.4+uP5.y+hg.z*2.;oO1=.45;oO2=.72;
  float tw2=opkShim(id+k);
  vec4 col=mix(vec4(0.),vec4(1.15*(1.+.9*b+1.2*tw2),0.,0.,0.),abs(p-iv));
  // the apex: a bead at the tip of the cone
  return mix(col,vec4(0.,0.,1.3+1.5*oHat,.1),smoothstep(.035+pw/S,.035-pw/S,t)*step(t,.2));
}
// ---- family 14 STRING: string art. From every corner of a tile a fan of straight lines is stretched side to side; no curve is
// drawn, the eye makes one from the envelope. Two lines of each fan cross at every point (two inks), and a four-pointed star of
// the same construction (third ink) fills the middle. The lines slide along their envelopes with the bass and the kick and
// each line thickens on its own band, so the mesh shimmers and the moire between the fans runs.
vec4 opkString(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,4.),dens=uP3.x*(sub>2.5?.24:.15)*opkZD(),wg=pw*dens;
  vec2 v=rot(uP3.y*.5+(sub>1.5&&sub<2.5?.7854:0.))*(q-uP2.xy)*dens+uP3.zz*.02;
  vec2 id=floor(v),pt=v-id;
  float par=mod(id.x+id.y,2.),hs=h21(id*vec2(1.9,1.3)+uSeed.xy*5.),sg=par*2.-1.;
  float N=20.*oDF,off=(uP3.z*.6+.7*oB1.y+.3*oKE)*sg+hs,ai=0.,lod=smoothstep(.6,.3,N*wg*oSS);
  vec4 c=vec4(0.);
  for(int i=oZi;i<4;i++){
    int ii=i-oZi;
    // fans: corner coordinates in whole-tile units; star: centred coordinates
    vec2 g=ii<2?min(pt,1.-pt):abs(pt*2.-1.);
    float ws=ii<2?wg:wg*2.,Nn=ii<2?N:N*.4,B=1.+g.x-g.y,disc=B*B-4.*g.x;
    if(disc>0.&&(ii<2||sub<.5||sub>1.5||par>.5)){
      float a=.5*(B+(ii==0||ii==2?1.:-1.)*sqrt(disc)),bd=opkBand(clamp(a,0.,.999)*8.),o2=ii<2?off:-off*.7;
      float an=(floor(a*Nn-o2)+.5+o2)/Nn;an=clamp(an,.5/Nn,1.-.5/Nn);
      float L=g.x*(1.-an)+g.y*an-an*(1.-an),dl=abs(L)/length(vec2(1.-an,an));
      float cv=mix(.16,opkBar(dl,max(.004*(1.+1.2*bd),.55*ws*oSS),ws)*(.7+1.1*bd),lod);
      if(ii==0){c.x=cv;ai=an;}else if(ii==1)c.y=cv;else c.z=max(c.z,cv);
    }
  }
  // what is left between fans and star holds a target of fine rings (hats light it)
  if(c.x+c.y+c.z<=0.){vec2 e=min(pt,1.-pt);float rh=abs(e.x-e.y)+.6*(e.x+e.y);oHr=max(oHr,opkPulse(rh*N-uP5.y*3.,.25,wg*N*1.5)*smoothstep(.5,.2,wg*N*1.5));}
  oT=hs*.5+ai*.45+uP5.y+hg.z*2.;oO1=.4;oO2=.75;
  float tw=opkShim(id);
  return vec4(1.2*c.x*(1.+tw),1.15*c.y*(1.-.6*c.x),1.25*c.z*(1.+.8*oHat)*(1.-.5*max(c.x,c.y)),.3*c.x*c.y+.3*c.z*max(c.x,c.y));
}
// ---- family 15 RIDGE: a landscape drawn only with lines. Each line is a band of the spectrum and rises into peaks when its band
// sings; lines in front hide the ones behind (hidden-line relief), the lens bulges lift the land, pleats of fine lines hang
// under every crest. Straight ranges, mirrored ranges, or rings of ridges around the focal point.
float opkRH(float X,float j,float amp){
  float b=opkBand(abs(mod(j*.5+800.,14.)-7.)),wn=.5+.5*cos(X*2.+j*.13+uP3.z*.3);
  return amp*(.2+2.6*b)*wn*wn*(.62+.38*sin(X*5.+j*.31+uP3.z))*(1.+.4*oKE);
}
vec4 opkRidge(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,4.),dens=uP3.x*1.9*opkZD(),wp=pw*dens,X,y,amp=1.;
  vec2 v=q-uP2.xy;
  if(sub>1.5){float r=length(v)+1e-5;X=atan(v.y,v.x);y=log(r)*dens*.3-uP3.z*.5;wp=pw*dens*.3/r;amp=.8;}
  else{v=rot(uP3.y*.5)*v;X=(sub>.5?abs(v.x):v.x)*1.7;y=v.y*dens+uP3.z*.5;}
  y+=12.*hg.z;
  float j0=ceil(y-3.4),js=j0,H=0.,dn=-1.;
  for(int i=oZi;i<5;i++){
    float j=j0+float(i-oZi);H=opkRH(X,j,amp);
    if(j+H>=y){js=j;dn=j+H-y;break;}
  }
  if(dn<0.){js=ceil(y);H=opkRH(X,js,amp);dn=js+H-y;}
  float sl=(opkRH(X+.02,js,amp)-H)/.02*(sub>1.5?1./(dens*.3):1.7/dens),b=opkBand(abs(mod(js*.5+800.,14.)-7.));
  float dl=dn/sqrt(1.+sl*sl),hw=max(.055+.065*b,.6*wp*oSS);
  float ln=opkBar(dl-hw,hw,wp);
  // pleats: fine lines hanging under every crest, longer where the ridge stands taller
  float pf=sub>1.5?120.*oDF/TAU:9.*oDF,pl=opkPulse(X*pf+floor(js)*.5,.32,pf*(sub>1.5?pw/(length(v)+1e-5):1.7*pw))*smoothstep(.25+.6*H,.1,dn)*step(hw*2.,dn);
  oT=js*.07+uP5.y+hg.z*1.5;oO1=.38;oO2=.7;
  float tw=opkShim(vec2(js,floor(X*3.)));
  return vec4(1.25*ln*(1.+1.3*b+tw),1.15*pl*(.6+1.2*b),1.3*ln*smoothstep(.7,1.6,H)*(.3+1.5*oHat),0.);
}
// ---- family 17 PINNA: rings of tilted squares, each with two white edges and two inked ones. Rings lean opposite ways, so
// when anything moves the rings seem to counter-rotate; here they really do, each on its own band, while the whole
// field falls toward the focal point.
vec4 opkPinna(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,4.);
  vec2 d=q-uP2.xy;float r=length(d)+1e-5,M=28.+8.*step(.5,uSeed.y),K=M/TAU;
  float lr=log(r)*K+uP3.z*.8,j=floor(lr),b=opkBand(mod(j+400.,8.)),dj=mod(j,2.)*2.-1.;
  float sa=atan(d.y,d.x)/TAU*M+dj*(uP3.z*.25+.9*b)+(sub>1.5&&sub<2.5?lr*.5:0.);
  float ci=floor(sa),w=pw*K/r;
  vec2 u=vec2(fract(sa),fract(lr))-.5;
  float tl=(sub>.5&&sub<1.5?mod(ci+j,2.)*2.-1.:dj)*(sub>2.5?.3+1.2*b:.52);
  vec2 p=rot(tl)*u;
  float sz=.33*(1.+.2*b+.08*oKE),m=max(abs(p.x),abs(p.y)),sd=m-sz;
  float wh=abs(p.x)>abs(p.y)?step(0.,p.x):step(0.,p.y);
  float edge=opkBar(sd+.035,.035,w),ins=smoothstep(w,-w,sd+.07);
  float tw=opkShim(vec2(ci,j));
  oHr=max(oHr,opkBar(m-sz*.45,max(.012,.5*w*oSS),w)*smoothstep(.1,.04,w*oSS));
  vec4 col=vec4(0.,(.4+.7*b)*ins,0.,0.);
  col=mix(col,mix(vec4(1.2*(1.+.8*b),0.,0.,0.),vec4(0.,0.,0.,.95*(1.+tw+.4*oHat)),wh),edge);
  oT=j*.07+uP5.y+hg.z*2.;oO1=.5;oO2=.26;
  return col*smoothstep(-4.2,-2.6,log(r))*smoothstep(.75,.4,w);
}
// ---- family 18 ENIGMA: hundreds of fine rays around the focal point, broken by solid rings where the eye sees colour
// streaming. The ray count doubles at every ring so the rays stay fine all the way out; each zone of rays turns on its own band,
// opposite to its neighbours, and each ring swells on its band.
vec4 opkEnigma(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,4.);
  vec2 d=q-uP2.xy;float r=length(d)+1e-5,lb=log2(r/.17),k=floor(lb),fl=lb-k,wl=pw/(r*.693);
  float b=opkBand(mod(k+4.,8.)),b2=opkBand(mod(floor(lb+.5)+3.,8.)),dk=mod(k,2.)*2.-1.;
  float N=48.*exp2(clamp(k,-3.,5.)),an=atan(d.y,d.x)/TAU;
  float s=an*N+dk*(uP3.z*.5+1.3*b);
  if(sub>.5&&sub<1.5)s+=.45*sin(fl*TAU*2.);
  else if(sub>1.5&&sub<2.5)s+=dk*fl*2.5;
  float ws=pw*N/(TAU*r);
  float p=opkInkP(s,.5,ws,1.);
  float hwR=.05*(1.+1.1*b2),x=fract(lb+.5)-.5;
  float ring=opkBar(sub>2.5?abs(x)-hwR*.9:x,sub>2.5?hwR*.45:hwR,wl),moat=opkBar(x,hwR*(sub>2.5?1.6:1.)+.035,wl);
  oT=k*.11+uP5.y+hg.z*2.;oO1=.5;oO2=.25;
  float tw=opkShim(vec2(k,floor(an*24.)));
  vec4 col=vec4(1.12*(1.+.7*b+tw),0.,0.,0.)*abs(p-iv)*(1.-moat);
  oHr*=1.-moat;oCt*=1.-moat;
  oCt=max(oCt,opkHair(x/(2.*hwR)+.5,2.*hwR/max(wl*oSS,1e-4))*ring*step(sub,2.5));
  return mix(col,vec4(0.,1.1*(1.+.8*b2),0.,.05*oHat),ring);
}
// ---- family 19 TRIBAR: a wall of impossible triangles. Each bar turns the corner into the next and comes back in front of
// itself; the three faces are three line treatments (solid ink, a grating, white hairlines), every tribar swells on its own
// band, and the hollow in the middle holds a nest of fine triangles.
vec4 opkTribar(vec2 q,float pw,vec3 hg,float iv,float bits){
  float sub=mod(bits,4.),dens=uP3.x*.26*opkZD(),wp=pw*dens*1.3;
  vec2 v=rot(uP3.y*.5)*(q-uP2.xy)*dens+vec2(uP3.z*.05,uP3.z*.03);
  vec2 sk=vec2(v.x-v.y*.57735,v.y*1.1547),id=floor(sk),f=sk-id;
  float up=step(1.,f.x+f.y);f=mix(f,1.-f,up);
  float hs=h21((id+up*.37)*vec2(1.3,2.9)+uSeed.xy*3.),b=opkBand(floor(hs*7.99));
  vec3 D=(vec3(f.y,f.x,1.-f.x-f.y)-.045)/.865;
  float mn=min(D.x,min(D.y,D.z)),T=.125+.028*b+.01*oKE,ws=wp/.865;
  vec4 res=vec4(0.);oT=hs*.5+uP5.y+hg.z*2.;oO1=.4;oO2=.74;
  if(mn<0.||(sub>1.5&&sub<2.5&&up>.5)){
    // gaps between tribars are black; in the alternate variant the down triangles hold a target instead
    float tg=opkPulse(mn*14.*oDF-uP5.y*3.,.3,ws*14.*oDF)*step(0.,mn);
    res=vec4(0.,0.,tg*(.7+1.5*oHat),0.);
  }else{
  // each bar: the strip along its own edge, running to the tip at the next corner, plus the strip along the next edge's
  // inner side (the bend that makes it impossible)
  vec3 Dn=D.yzx,Dp=D.zxy,so=step(D,vec3(T))*(1.-step(Dp,vec3(T))),si=step(D,vec3(2.*T))*(1.-step(Dn,vec3(2.*T)))*step(T,mn);
  float pc=-1.,sd=0.,ed=1.;
  if(so.x+so.y+so.z>.5){pc=dot(so,vec3(0.,1.,2.));sd=dot(so,D);ed=dot(so,min(min(D,Dn),min(Dp-T,max(T-D,min(Dn-T,2.*T-Dn)))));}
  else if(si.x+si.y+si.z>.5){pc=dot(si,vec3(2.,0.,1.));sd=dot(si,D)-T;ed=dot(si,min(min(2.*T-D,Dn-2.*T),D-T));}
  if(pc<0.){
    oHr=max(oHr,opkPulse((mn-2.*T)*16.*oDF,.25,ws*16.*oDF)*smoothstep(.5,.2,ws*16.*oDF)*step(.03,mn-2.*T));
  }else{
  float tone=mod(pc+floor(hs*3.)+up,3.),tw=opkShim(id+up),X=sd/T*3.*oDF,wX=ws/T*3.*oDF;
  float dty=tone<.5?(sub>2.5?.7:1.):(tone<1.5?(sub>2.5?.45:1.):.2);
  float pv=dty>.99?1.:opkPulse(X+.1,dty,wX);
  vec4 fc=(tone<.5?vec4(1.15*(1.+.8*b+1.2*tw+.3*oKE),0.,0.,0.):(tone<1.5?vec4(0.,(sub>2.5?1.1:.6)*(1.+.6*b),0.,0.):vec4(0.,0.,.25,.8+.8*oHat)))*pv;
  res=fc*smoothstep(.014-ws,.014+ws,ed);
  }}
  return res;
}
vec4 opkFamC(float F,vec2 q,float pw,vec3 hg,float iv,float bits){
  vec4 r;
  if(F<12.5)r=opkSnake(q,pw,hg,iv,bits);
  else if(F<13.5)r=opkRoto(q,pw,hg,iv,bits);
  else if(F<14.5)r=opkString(q,pw,hg,iv,bits);
  else if(F<15.5)r=opkRidge(q,pw,hg,iv,bits);
  else if(F<17.5)r=opkPinna(q,pw,hg,iv,bits);
  else if(F<18.5)r=opkEnigma(q,pw,hg,iv,bits);
  else r=opkTribar(q,pw,hg,iv,bits);
  return r;
}
vec4 opkFamB(float F,vec2 q,float pw,vec3 hg,float iv,float bits){
  vec4 r;
  if(F<5.5)r=opkQuasi(q,pw,hg,iv,bits);
  else if(F<6.5)r=opkQuilt(q,pw,hg,iv,bits);
  else if(F<7.5)r=opkLoom(q,pw,hg,iv,bits);
  else if(F<8.5)r=opkScale(q,pw,hg,iv,bits);
  else if(F<9.5)r=opkStar(q,pw,hg,iv,bits);
  else r=opkRows(q,pw,hg,iv,bits);
  return r;
}
vec4 opkFam(float F,vec2 q,float pw,vec3 hg,float iv,float bits){
  vec4 r;
  if(F>4.5&&F<11.5)r=opkFamB(F,q,pw,hg,iv,bits);
  else if(F>11.5&&(F<15.5||F>16.5))r=opkFamC(F,q,pw,hg,iv,bits);
  else if(F>1.5&&F<2.5)r=opkCube(q,pw,hg,iv,bits);
  else{
  float shape=mod(bits,8.),duo=mod(floor(bits/8.),2.),lat=mod(floor(bits/32.),2.);
  vec2 U,W,tk;float tb,fr=1.;vec4 md;mat2 R;
  if(F<.5){
    // ---- VEGA: checker (or lattice) cells holding inner shapes that grow on the bulges; columns play the spectrum.
    // The checker is warped into travelling waves (op-art current) breathing with the mids; the wave relaxes on
    // steep lens rims so it never pinches cells into slivers there.
    float dens=uP3.x*opkZD();R=rot(uP3.y);
    U=R*(q-uP2.xy)*dens+uP3.zz;
    float wv=(max(step(.45,uSeed.y),lat)*.3+.07*(oB1.z+oB1.w))/(1.+.6*length(hg.xy)),ph=uP3.z*1.6;
    U+=wv*vec2(sin(U.y*.5+ph),sin(U.x*.5-ph*.7));
    W=vec2(pw*dens*(1.+wv*.5));tk=vec2(.075,.1);tb=0.;md=vec4(lat,.5,1.15,1.);oAx=0.;
  }else if(F<1.5){
    // ---- STRIPES: Riley waved stripes (a surge rides every kick), Zebra contours around drifting swells, or two
    // gratings whose interference (moire) fringes are the design; stripe thickness along x plays the spectrum
    float sv=mod(bits,8.);
    vec2 v=rot(uP3.y*.5)*(q-uP2.xy);
    float dens=uP3.x*2.3*opkZD(),s,w,t;
    if(sv<.5){
      float A1=.55+.75*oB1.y+.4*oKE,f1=3.+2.*uSeed.x,ph=uP3.z*2.;
      float a1=v.x*f1+ph,a2=v.x*f1*2.3-ph*1.4+v.y*3.;
      s=v.y*dens+A1*sin(a1)+.3*sin(a2);
      w=pw*length(vec2(A1*f1*cos(a1)+.3*f1*2.3*cos(a2),dens+.9*cos(a2)));
      t=v.x*.32;
    }else{
      // Zebra: contours of a tilted plane plus the height of every lens, so the stripes wrap into closed loops
      // around each bulge and dimple and flow as the lenses move
      vec2 gg=vec2(0.,.6)+.55*hg.xy;
      s=(v.y*.6+.55*hg.z)*dens*1.3-uP3.z;w=pw*length(gg)*dens*1.3;t=hg.z*.6+v.x*.2;
    }
    U=vec2(s,0.);W=vec2(w,0.);tk=vec2(.06,0.);tb=t;R=mat2(1.);
    md=vec4(2.,mix(clamp(.56+.15*(oSp-.4),.4,.7),.56,step(1.5,sv)),1.3,1.);duo=0.;oAx=0.;
  }else if(F>15.5){
    // ---- MOVE: a checker whose columns are squeezed toward travelling folds (in variants its rows too, or along wavy
    // folds), so the plane seems to dive into creases. The squeeze follows the bass and the kick; the folds travel.
    float dens=uP3.x*.8*opkZD(),A=clamp(.6+.3*max(oB1.x,oB1.y)+.1*oKE,0.,.93),kf=2.6,ph=uP3.z*.9;
    R=rot(uP3.y*.5);vec2 v=R*(q-uP2.xy);
    float wf=step(.5,mod(floor(bits/16.),2.)),wob=wf*.9*sin(v.y*1.4+uP3.z*.3),a1=kf*v.x-ph+wob,a2=kf*v.y+ph*.6,both=lat;
    lat=0.;
    U=dens*vec2(v.x+A/kf*sin(a1),v.y+both*A/kf*sin(a2));
    W=pw*dens*vec2(1.+A*cos(a1)+.45*wf,1.+both*A*cos(a2));tk=vec2(.05,.08);tb=0.;md=vec4(0.,.5,1.15,1.);oAx=0.;
  }else{
    // ---- TUNNEL (twisted concentric squares) and BLAZE (polar
    // zigzag checker whose sectors double every octave outward), both falling inward one ring per beat; ring
    // brightness plays the spectrum (outer rings bass, inner rings treble)
    vec2 d=q-uP2.xy;
    float K=uP3.x*.75,s,sa,wr,wa,z,ta,r,lr,rg=0.;
    if(F<3.5){
      r=length(d)+1e-6;lr=log(r);
      float tw=(uSeed.y-.5)*1.4;
      d=rot(lr*tw+uMT*.04*sign(uSeed.w-.5))*d;
      float rho=max(max(abs(d.x),abs(d.y)),1e-5);
      z=log(rho);
      float M=mix(12.,8.,step(uSeed.x,.5));
      vec2 ad=max(abs(d),1e-6);
      float Pm=abs(d.x)>=abs(d.y)?(d.x>0.?1.+d.y/ad.x:5.-d.y/ad.x):(d.y>0.?3.-d.x/ad.y:7.+d.x/ad.y);
      s=z*K-uP3.z*1.9;
      sa=Pm*M*.5+uP3.z*sign(.5-uSeed.z)*.5;
      wr=pw*K/rho*(1.+abs(tw)*.5);wa=pw*M/rho*1.2;
      ta=.3*abs(Pm-4.)/4.;rg=step(.75,uSeed.z);
    }else{
      r=length(d)+1e-6;lr=log(r);
      float an=atan(d.y,d.x+1e-7);
      // sectors double every octave beyond r=1.2, so the cells stay small all the way out
      float lb=log2(r/1.2);
      float N=mix(mix(32.,24.,step(uSeed.x,.66)),16.,step(uSeed.x,.33))*exp2(clamp(floor(lb)+1.,0.,3.));
      float tws=(uSeed.z-.5)*3.,zig=.55*step(uSeed.w,.6);
      sa=an/TAU*N+lr*tws+uMT*.035;
      z=lr;
      s=lr*K-uP3.z*1.9+zig*abs(fract(sa)-.5)*2.;
      wr=pw/r*(K+zig*N/PI+abs(tws)*.2);wa=pw/r*(N/TAU+abs(tws));
      ta=.3*cos(an-uP5.y*3.);
      fr=mix(1.,smoothstep(.01,.01+1.5*pw,abs(lb-floor(lb+.5))*r*.693),step(-.5,lb));
    }
    // depth fog, lifted wherever a lens magnifies the far cells back into view (never a big plain disc at the vanishing point)
    float fog=max(smoothstep(-3.6,-1.,z),smoothstep(.5,.2,max(wr,wa)));
    vec2 rh=d/r;R=mat2(rh.x,-rh.y,rh.y,rh.x);
    U=vec2(s,sa);W=vec2(wr,wa);tk=vec2(.07,0.);tb=ta+(1.-fog)*.45;
    md=vec4(3.*rg,.5,1.35+.5*oSp,mix(.22,1.,fog));oAx=1.;
    oGlow=exp(-r*18.)*.5;
  }
  if(F>.5&&F<1.5){oEU=vec2(U.x,tb*6.);oEW=W.x;}else{oEU=U;oEW=max(W.x,W.y);}
  vec4 col=opkCells(U,W,tk,tb,md,shape,duo,iv,hg,R);
  r=mix(vec4(0.,0.,.75+.8*oB2.z,.15),col,fr);
  }
  return r;
}
void realm(){
  vec2 sc=scr();
  // default framing a little further back than the raw screen; the zoom wheel pulls back to the whole lens wall
  oZ=int(step(1e9,uDetail));
  float Z=uZoom*.9;
  vec2 c0=uP2.xy;
  // v13: pushing in dollies toward the focal sphere (it stays where it sits at zoom 1) instead of the screen centre,
  // so the tunnels keep their vanishing point and the sphere never slides out of frame
  float zf=smoothstep(1.,1.8,uZoom)*(1.-.9/Z);
  vec2 p=sc/Z+c0*zf,sF=c0*Z*(1.-zf);
  float px=1./(uRes.y*Z);
  float bits=uM2[2][1],bits0=uM2[2][2];
  // unpacked channels: field strength + kick envelope, inversion parity + lens storm, transition type + progress
  oFS=floor(uP3.w)/512.;oKE=fract(uP3.w);oEv=floor(uP4.x*.5)/100.;
  float wT=floor(uP4.w*.5),wE=uP4.w-2.*wT;
  oPx=px;oP=uP2.zw;oRim=vec2(0.);
  {vec3 a=vec3(uP1.z,uP1.w,uP5.x),hi=floor(a/65536.),md=floor((a-hi*65536.)/256.),lo=a-hi*65536.-md*256.;
   oB1=vec4(lo.x,md.x,hi.x,lo.y)/255.;oB2=vec4(md.y,hi.y,lo.z,md.z)/255.;oHat=hi.z/255.;
   float sr=floor(uP4.y)/100.,x=(length(p-c0)-sr)/.42;oSn=fract(uP4.y)*exp(-x*x);}
  // drops and phrases change family / palette through a transition in screen space: 0 an iris out of the focal
  // sphere, 1 a sweep with a zigzag front, 2 Riley blinds (parallel bands all opening at once), 3 tiles flipping
  // outward from the focal sphere (all four are cheap; a one-hot picks one, no branches)
  vec2 cs=sc-sF,wd=vec2(cos(uP4.z+1.),sin(uP4.z+1.)),g=floor(sc*6.)+.5;float sd=dot(sc,wd);
  float dw=dot(max(1.-abs(wT-vec4(0.,1.,2.,3.)),0.),vec4(length(cs)-wE*2.6,sd+1.1+.06*abs(fract(dot(sc,vec2(-wd.y,wd.x))*5.)*2.-1.)-wE*2.4,
    (fract(sd*3.5)-wE*1.1+.03)*.28,length(g/6.-sF)*.5+h21(g+uSeed.xy*9.)*.35-wE*1.35));
  bool nw=dw<0.||wE>=1.;
  float fp=nw?uP1.x:uP1.y;float fam=floor(fp/16.),bt=nw?bits:bits0;bool ri=abs(fam-1.)<.5;
  // stripes would show the kink of a sharp lens rim, so their lenses are always smooth swells
  float prof=ri?2.:1.+mod(floor(bt/16.),2.);
#if HD>=1
  // v19 HD: each tap is a complete run of the optical path (lenses, zones, family, lighting) at one wavelength and one
  // sub-pixel position (v20: no mirror bounce). One loop body, so compile cost does not multiply.
  vec2 p0=p;float fpP=fp,famP=fam,btP=bt;bool riP=ri;vec3 colOut=vec3(0.),cSum=vec3(0.);
  int nT=int(clamp(floor(pow(uDetail,1.5)*1.9)+2.,2.,64.));
  for(int it=oZ;it<nT;it++){
    float fk=float(it-oZ),tn=(fk+.5)/float(nT);
    p=p0+(vec2(fract(fk*.75487767),fract(fk*.56984029))-.5)*px;
    fp=fpP;fam=famP;bt=btP;ri=riP;oRim=vec2(0.);
#endif
  vec2 q=p;vec4 hg=vec4(0.);float hzP=0.;   // hzP: the part of the height that is pure music pump
  // v14: a breathing pleated surface and braided torsion move the geometry between the lenses.
  float travel=uP3.z,rad=length(q-c0),angle=.03*sin(travel*.23)+.02*sin(rad*2.4-travel*.4);
  mat2 turn=mat2(cos(angle),-sin(angle),sin(angle),cos(angle));q=c0+turn*(q-c0);
  vec2 wave=vec2(sin(q.y*3.1+travel*.47),sin(q.x*2.6-travel*.36));
  float amp=(.004+.036*oB1.z+.04*oB2.x)*(.25+.75*smoothstep(.25,.8,rad));   // v18: the mids undulate the field, the sphere stays clean
  vec2 radial=(q-c0)/max(rad,.08);
  q+=amp*wave;hg.xy+=amp*vec2(2.6*cos(q.x*2.6-travel*.36),3.1*cos(q.y*3.1+travel*.47));
  hg.z+=.045*(wave.x+wave.y);
  // v18 OOMPH. Bass quilt: the whole plane is a padded op-art surface whose swells pump with the sub and bass, so the low
  // end physically lifts the field (cells magnify on the crests, colour bands surge through hg.z); relaxed near the sphere.
  {float bq=max(oB1.x,oB1.y),qA=(.01+.075*bq*bq)*uDose*smoothstep(.25,.8,rad);
   if(qA>1e-4){vec2 v=rot(.5+uP3.y*.3)*(q-c0)*4.6+vec2(travel*.21,-travel*.13);
    float vs=.72+.28*sin(v.x*.37+v.y*.23+travel*.05),cx=cos(v.x),sx=sin(v.x),cy=cos(v.y),sy=sin(v.y);
    vec2 gq=rot(-.5-uP3.y*.3)*vec2(cx*sy,sx*cy)*qA*vs;
    q-=gq;hg.xy+=gq*19.;hzP+=sx*sy*qA*vs*4.6;hg.z+=sx*sy*qA*vs*4.6;}}
  // v18: the kick punches the whole field toward the focal point (a smoothed dolly), and a drop wrings it into a twist
  {float dropS=uM2[2].x,kk=1.-.04*oKE,tw=dropS*1.9*exp(-rad*.8);
   vec2 dd=q-c0;if(tw>1e-3)dd=rot(tw)*dd;q=c0+dd*kk;}
  // kick: heavy shockwave rings run across the glass, outward from the focal sphere; three live at once so a new kick
  // never cuts off the last one
  for(int j=0;j<3;j++){
    float rk=j==0?uP5.z:(j==1?uM1[2].x:uM1[2].z),ka=j==0?uP5.w:(j==1?uM1[2].y:uM2[0].x);
    if(ka>1e-3){
      vec2 d=q-c0;float r=length(d)+1e-5,wd=.085+.06*rk,x=(r-rk)/wd,e=exp(-x*x);
      q-=d/r*ka*.105*x*e;
      hzP+=ka*.21*e;hg.z+=ka*.21*e;hg.xy-=d/r*ka*2.1*x*e;
    }
  }
  // v18 snare: the soft wave out of the focal sphere now physically lifts the cells it passes
  q+=radial*oSn*.075;hzP+=oSn*.16;hg.z+=oSn*.16;
  // the lens wall first (only when pulled back), then the focal sphere in front and the band lenses behind it
  // (the lens storm event brings the wall in at any zoom). Every lens rim lights up in its band's colour on that
  // band: sub/bass onsets ring the focal sphere, low-mid..presence onsets each ring their satellite, the wall's
  // lenses glow with their band's level
  int i0=oFS>1e-3&&(Z<1.3||oEv>.01)?0:2;
  for(int i=0;i<5;i++){
    if(i<i0)continue;
    float m=prof,tb=float(i-1)*.125*step(2.5,float(i));vec4 L;
    if(i<2){m=ri?3.:prof;L=opkSite(q,float(i),m,tb);tb*=.125;}
    else L=i==2?vec4(c0,uP2.zw):(i==3?vec4(uM1[0],uM2[1].x):vec4(uM1[1],uM2[1].y));
    float lt=floor(L.z*.5);
    opkLens(q,hg,L.xy,L.z-2.*lt,L.w,m,lt*.01,tb);
  }
  // the wall's giant lenses rise far higher than the focal sphere; their height is compressed above .3 so they
  // keep crisp, dark-grounded patterns instead of washing out into bright blobs
  hg.z=min(hg.z,.3+.25*max(hg.z-.3,0.));
#if HD>=1
  float pw=px*max(.6+.55*length(hg.xy),.6);
#else
  vec2 qx=dFdx(q),qy=dFdy(q);
  float pw=max(max(length(qx),length(qy)),px*.3);
#endif
  // v19 ZONES: most compositions split the surface into two illusions at once (window in the sphere, rings, wedges, hex
  // patches, slabs). Each side of a wipe carries its own layout, so a layout can only ever change behind a transition.
  float zsd=1.;
  {float zc=nw?uM2[0].y:uM2[0].z,zm=floor(zc/131072.);
   if(zm>.5){
    vec2 d=q-c0;float rz=length(d)+1e-4,zp=uP3.z*.2;
    if(zm<1.5)zsd=length(p-c0)-mod(uP2.z,2.)*1.02;
    else if(zm<2.5){float s=log(rz+.12)*1.5-zp;zsd=(abs(fract(s)-.5)-.26)*(rz+.12)/1.5;}
    else if(zm<3.5){float n=3.,s=(atan(d.y,d.x)/TAU+.5)*n*2.+zp*.5;zsd=(abs(fract(s)-.5)-.25)*rz*TAU/(2.*n);}
    else if(zm<4.5){vec2 a=d*.8+vec2(zp*.4,-zp*.2),h=opkHex(a);float hd=max(abs(a.x-h.x),dot(abs(a-h),vec2(.5,.8660254)));zsd=(.5-hd)/.8*(h21(h+uSeed.xy*17.)<.5?1.:-1.);}
    else if(zm<5.5){float s=dot(d,vec2(.707,.707))*.8+zp;zsd=(abs(fract(s)-.5)-.25)/.8;}
    // v20: a framed picture hung on the wall, a great checkerboard of two illusions, a lattice of portholes
    else if(zm<6.5){vec2 a=abs(p-c0)-vec2(.74,.44);zsd=max(a.x,a.y);}
    else if(zm<7.5){vec2 a=d*.6+vec2(zp*.3,zp*.15),cf=abs(fract(a)-.5);zsd=(.5-max(cf.x,cf.y))*(mod(floor(a.x)+floor(a.y),2.)*2.-1.)/.6;}
    else{vec2 a=d*.85+vec2(zp*.3,-zp*.2),h=opkHex(a);zsd=(length(a-h)-.38)/.85;}
    if(zsd<0.){float zf=mod(zc,512.);fp=zf;fam=floor(zf/16.);bt=mod(floor(zc/512.),256.);}
   }
  }
  ri=abs(fam-1.)<.5;
  // stripes read the lenses the other way round: they crowd together under a bulge instead of blowing up
#if HD>=1
  if(ri){q=p-(q-p)*.85;pw*=1.85;}
#else
  if(ri){q=p-(q-p)*.85;pw=max(max(length(vec2(1.85*px,0.)-.85*qx),length(vec2(0.,1.85*px)-.85*qy)),px*.3);}
#endif
  // spectrum: by screen column for the flat families, by depth (outer rings bass, inner rings treble) for the deep
  // ones; two taps blur neighbouring bands so a sharp peak swells the pattern instead of kinking it
  float sx=((fam>2.5&&fam<4.5)||abs(fam-13.)<.5||abs(fam-17.5)<1.)?.03+.9*clamp(-log(length(q-c0)+1e-4)/3.2,0.,1.):.05+.88*clamp(q.x/opkAsp()+.5,0.,1.);
  // (v12: read from the smoothed band envelopes, not the raw per-frame spectrum, whose jitter made cells and stripes
  // shimmer)
  oSp=opkBand(clamp(sx,0.,1.)*7.);oGlow=0.;
  // figure/ground parity belongs to each side of a transition (it only ever changes behind a wipe)
  float iv=mod(floor(bt/64.),2.);
  opkLoad(mod(fp,16.));
  // v18: the pumped height lights and lifts the cells but does not spin their colours (that read as flicker)
  vec3 hgF=vec3(hg.xy,hg.z-.85*hzP),acc=opkGrad(uP5.y+.4);
  vec3 col=vec3(0.);
#if HD>=1
  float lg=length(hg.xy);
  vec2 qs=q+hg.xy/max(lg,1e-3)*(tn-.5)*px*min(lg*1.2,1.+.6*oB2.y);float pwT=pw;
#else
  vec2 qs=q;float pwT=pw;
#endif
    oHr=0.;oCt=0.;oIv=iv;oSw=step(abs(length(p-c0)-floor(uP4.y)/100.),.11)*step(.1,fract(uP4.y));
    vec4 cw=opkFam(fam,qs,pwT,hgF,iv,bt);
    float tt=mix(uP5.y,oT,.8)+oSn*.35+.16*oB2.y+.09*oB2.x;
    vec3 c1=opkGrad(tt),c2=opkGrad(tt+oO1),c3=opkGrad(tt+oO2);
    // v20b: the second ink is a real contrast ink. If it would fall in the first ink's hue family, it is replaced by the
    // palette stop farthest in hue from the first (a narrow switch, so it is one ink or the other, never a grey mix)
    {vec3 n1=opkCh(c1);c2=mix(c2,opkFar(n1),smoothstep(.3,.5,dot(n1,opkCh(c2))));
     // snare: inside its ring the first and second inks change places (a hard-edged band of exchanged colour riding the wave)
     n1=c1;c1=mix(c1,c2,oSw);c2=mix(c2,n1,oSw);}
    // the third ink leans to the complement of the first, so every palette has a colour that pops against its main ink
    c3=mix(c3,max(c1.r,max(c1.g,c1.b))+min(c1.r,min(c1.g,c1.b))-c1,.45);
    // v20 ink model: black paper, flat saturated inks. Light never lands on the paper: the snare, the kick and the bands
    // multiply the inks, widen lines and light the hairlines, so black stays black and nothing sums toward white.
    vec3 tap=(cw.x*c1*(1.+.45*max(oB1.x,oB1.y)+.45*oKE)+cw.y*c2*(1.+.4*(oB1.z+oB1.w)+.3*oKE)+cw.z*c3*(1.+.8*oB2.z+.5*oB2.w+.7*oHat+.25*oKE))*(1.+.8*oSn+.15*oB2.x)+cw.w*(1.+.5*oSn+.3*oKE);
    tap*=.85*(1.+1.5*clamp(hzP,-.2,.4));
    // highs: a fine twill of light woven over the inks, never on the paper. High and air levels weave it, every hat flashes it,
    // and the snare lights it across the whole frame (the snare's ring still carries the big lift)
    {float snG=fract(uP4.y),tA=.3*(oB2.z+oB2.w)+.7*oHat+.5*snG;
     if(tA>.01){tap*=1.+tA*(1.6*opkPulse(dot(qs,vec2(.8,.6))/.017+uP3.z*2.,.5,pwT/.017)-.5);
      // and a crisp pinstripe on the black paper for the same instant (thin lines of the third ink; it fades out rather than
      // averaging where the pixels cannot hold it, so it is never a haze)
      float wq=pwT/.023;oHr=max(oHr,opkPulse(dot(qs,vec2(-.6,.8))/.023-uP3.z*2.,.16,wq)*smoothstep(.45,.22,wq*oSS)*min(.9*oHat+.8*snG+.2*(oB2.z+oB2.w),1.)*.6);}}
    // inks never leave the gamut: a hue-preserving ceiling, so loud passages cannot burn to one flat colour or feed the glow
    tap/=max(1.,max(tap.r,max(tap.g,tap.b))/1.55);
    tap*=1.-.92*oCt;
    vec3 hc=mix(c3,vec3(1.),.2+.6*oSn)*(.5+1.5*oHat+.45*oB2.w+.3*oB2.z);
    col=tap+hc*oHr*(1.-clamp(dot(tap,vec3(.6)),0.,1.))+acc*oGlow+hc*oCt*min(1.1*oHat,.9);
  // relief: the bulges catch a key light from the upper left and dimples sink into shade, gently, so the inks stay flat
  // and saturated; bulges cast a shadow; every lens rim is a hairline in its band's colour
  vec3 n=normalize(vec3(-hg.xy*.8,1.));
  vec3 L=normalize(vec3(-.55,.6,.6));
  col*=mix(1.,clamp(dot(n,L)/L.z,.4,1.5),.42)*(1.+.45*clamp(hg.z,-.5,.6));
  col*=1.-.6*hg.w;
  col+=opkGrad(uP5.y+oRim.y/max(oRim.x,1e-4)*1.6)*oRim.x;
  // presence and the highs push the inks away from grey (saturation only rises; nothing is added to the paper)
  {float pr=uB2.y*uDose,lq=uB2.z*uHat*uDose,m=dot(col,vec3(.3333));col=max(m+(col-m)*(1.+pr*.5+lq*.3),0.);}
  // light accents: the transition front and the snare front
  // zone seam: an ink hairline between the two illusions, flashing with the kick
  if(zsd<1.)col=mix(col,acc*(.04+1.4*oKE),clamp(1.6-abs(zsd)/max(pw,px),0.,1.)*.9);
#if HD>=1
    {vec3 sW=max(vec3(1.-2.*abs(tn-.2),1.-2.*abs(tn-.5),1.-2.*abs(tn-.8)),0.)+.08;colOut+=col*sW;cSum+=sW;}
  }
  vec3 col=colOut/max(cSum,vec3(1e-4));
#endif
  float pd=1./uRes.y;
  if(wE<1.)col*=1.-.85*clamp(1.6-abs(dw)/(pd*1.2),0.,1.)*step(wT,2.5)*(1.-wE);
  col*=1.-.16*dot(sc,sc);
  fragColor=vec4(max(col,0.),0.);
}
`;
