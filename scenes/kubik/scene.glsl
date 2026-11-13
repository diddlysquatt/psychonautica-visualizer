const R_KUBIK = `
// KUB1K v18: a city of hand-made cubes, each with its own character (speakers, faces, lit windows, truchet tiles,
// harlequin, dice, gems, basket weave, flowers), in curated lacquer palettes. One cube (or pillar) per cell of an endless
// grid, traced exactly: a 2D DDA walks the columns and tests one rotated box per column. Nothing in the geometry follows
// raw audio: every movement is a smooth function of a beat-locked phase, event ages in beats and smoothed band levels.
float kuPh,kuS,kuSc,kuLift,kuYaw,kuBass,kuK,kuRoll,kuPix,kuHop,kuCT,kuSq,kuAct,kuSA,kuSM,kuMid;
vec2 kuDir;vec3 kuRo;
// v19: the event channels the cubes answer. Ages are in beats, counters are integers.
// kuKA/kuKB kick hop (two halves of the city), kuSnA snare, kuHatA hat, kuDA drop blast, kuCrA crater (kick impact at kuCr)
float kuCamY,kuFA,kuFB,kuCA,kuCB,kuKA,kuKB,kuKC,kuSnA,kuSnC,kuHatA,kuHatC,kuDA,kuDS,kuCrA,kuActI,kuActW,kuBW,kuPat,kuTk,kuYT,kuPalA;
vec2 kuCr,kuPatV,kuArm,kuLV;
float kuMi,kuAi,kuSu,kuPr,kuLM,kuLR,kuLD,kuLMir,kuLBl,kuLA,kuLB,kuLW,kuWP,kuWS,kuWA,kuWC,kuWG;
vec3 kuGnd,kuInk6,kuCream,kuHor,kuL;
// v11: smoothed band springs (sub..air) and per-band onset pops (JS springs), unpacked once per pixel
vec4 kuB0,kuB1,kuP0,kuP1;
#define KU_FLOOR -3.2

// curated inks (sRGB) per palette: five inks, ground, outline, cream
// v18: seven lacquer palettes, softened away from pure primaries: five inks, ground, outline, cream
const vec3 KUP[56]=vec3[56](
  vec3(1.000,0.420,0.357),vec3(0.949,0.714,0.196),vec3(0.122,0.659,0.627),vec3(0.969,0.659,0.722),vec3(0.239,0.247,0.659),vec3(0.165,0.106,0.290),vec3(0.086,0.051,0.149),vec3(1.000,0.953,0.863),
  vec3(0.827,0.125,0.306),vec3(0.071,0.659,0.455),vec3(0.165,0.357,0.843),vec3(0.961,0.651,0.137),vec3(0.608,0.302,0.859),vec3(0.082,0.094,0.227),vec3(0.039,0.043,0.118),vec3(1.000,0.945,0.816),
  vec3(0.169,0.702,0.604),vec3(0.851,0.643,0.255),vec3(0.659,0.196,0.290),vec3(0.937,0.498,0.353),vec3(0.114,0.435,0.549),vec3(0.063,0.188,0.184),vec3(0.024,0.094,0.102),vec3(1.000,0.973,0.906),
  vec3(1.000,0.467,0.663),vec3(0.373,0.890,0.753),vec3(1.000,0.878,0.400),vec3(0.392,0.710,1.000),vec3(0.655,0.482,0.953),vec3(0.169,0.133,0.376),vec3(0.082,0.063,0.227),vec3(1.000,0.980,0.941),
  vec3(0.910,0.271,0.173),vec3(0.961,0.604,0.180),vec3(0.118,0.498,0.361),vec3(0.173,0.290,0.604),vec3(0.839,0.329,0.549),vec3(0.118,0.086,0.220),vec3(0.063,0.039,0.125),vec3(0.984,0.937,0.851),
  vec3(0.310,0.839,0.910),vec3(0.541,0.361,0.941),vec3(0.886,0.310,0.706),vec3(0.659,0.890,0.290),vec3(0.184,0.482,0.910),vec3(0.059,0.118,0.290),vec3(0.024,0.047,0.141),vec3(0.949,0.984,1.000),
  vec3(0.851,0.396,0.231),vec3(0.929,0.745,0.420),vec3(0.184,0.710,0.690),vec3(0.910,0.416,0.541),vec3(0.420,0.227,0.549),vec3(0.173,0.082,0.220),vec3(0.090,0.039,0.118),vec3(1.000,0.941,0.855));
vec3 kuInk(float pal,float i){vec3 c=KUP[int(pal+.5)*8+int(i+.5)];return c*c;}
vec3 kuHueRot(vec3 r){float h=.12*sin(uHue*TAU),ch=cos(h),sh=sin(h);vec3 k=vec3(.57735);return max(r*ch+cross(k,r)*sh+k*dot(k,r)*(1.-ch),0.);}

float kuEase(float x){x=clamp(x,0.,1.);return x*x*x*(x*(x*6.-15.)+10.);}
// ease-in, then out-back: starts from rest, lands with a ~10% overshoot and settles
float kuBack(float x){x=clamp(x,0.,1.);x=x*x*(3.-2.*x);float e=x-1.;return 1.+2.70158*e*e*e+1.70158*e*e;}
// one beat pulse: rises over .15 beat, settles with a soft springy dip, back to rest before the next cycle
float kuPulse(float u){u=fract(u);float v=max(u-.22,0.);return smoothstep(0.,.22,u)*exp(-4.*v)*cos(5.*v)*smoothstep(1.,.75,u);}
// smoothed band (JS springs), x 0 = sub .. 1 = air
vec4 kuT0(float x){return max(1.-abs(clamp(x,0.,1.)*7.-vec4(0.,1.,2.,3.)),0.);}
vec4 kuT1(float x){return max(1.-abs(clamp(x,0.,1.)*7.-vec4(4.,5.,6.,7.)),0.);}
float kuBand(float x){return dot(kuB0,kuT0(x))+dot(kuB1,kuT1(x));}
float kuPopB(float x){return dot(kuP0,kuT0(x))+dot(kuP1,kuT1(x));}
// raw per-band onsets (light only)
float kuOnB(float x){return dot(uO1,kuT0(x))+dot(uO2,kuT1(x));}
float kuLvB(float x){return dot(uB1,kuT0(x))+dot(uB2,kuT1(x));}

// the pictures the cube tops paint (ink index 0..4 per cell)
float kuImg(float id,vec2 q){
  float r=length(q),a=atan(q.y,q.x),v;
  if(id<.5)v=floor(max(abs(q.x),abs(q.y))/2.);
  else if(id<1.5)v=floor(r/2.3);
  else if(id<2.5)v=floor((q.x+q.y)/2.5);
  else if(id<3.5)v=floor(q.x/3.)+2.*floor(q.y/3.);
  else if(id<4.5)v=floor(a/TAU*5.+r*.17);
  else if(id<5.5)v=mod(floor(a/TAU*12.+.5),2.)*2.+floor(r/7.);
  else if(id<6.5){
    // smiling daisies, one per 20 cells
    vec2 ti=floor((q+10.)/20.),t=q-ti*20.;float rt=length(t),at=atan(t.y,t.x),pi=floor(h21(ti+3.1)*5.);
    vec2 e=vec2(abs(t.x)-1.25,t.y-.9);
    if(rt<3.6)v=(length(e)<.8||(abs(length(t-vec2(0,.5))-1.9)<.6&&t.y<-.3))?pi+4.:pi+2.;
    else if(rt<6.6+1.6*cos(8.*at))v=pi;
    else v=pi+3.+mod(floor(t.x/2.)+floor(t.y/2.),2.);
  }
  else{vec2 ti=floor((q+7.)/14.),t=q-ti*14.;v=floor((abs(t.x)+abs(t.y))/2.)+ti.x+2.*ti.y;}
  return mod(v,5.);
}
vec3 kuCol(float code,vec2 q){return kuInk(floor(code/8.),kuImg(mod(code,8.),q));}

// formation heights: 0 diagonal swell, 1 ripple pond, 2 checker pump, 3 ziggurats (pillars), 4 equalizer rows
// (pillars), 5 spiral, 6 egg crate; v11 wow formations: 7 skyline towers (pillars), 8 cube cloud, 9 grand stepped
// pyramid (pillars). The beat-clock motion is scaled by the music's activity (calm in silence).
float kuForm(float f,vec2 q,float hc){
  float r=length(q),b=(.55+.75*kuBass)*kuAct,P=kuTk*PI*.5,h;
  if(f<.5)h=(1.+b)*sin(.42*(q.x+q.y)-P)+.45*sin(.31*(q.x-q.y)+P*.5);
  else if(f<1.5)h=(1.+1.2*b)*sin(.62*r-P)*1.2/(1.+.03*r);
  else if(f<2.5){float g=mod(floor(q.x)+floor(q.y),2.);h=-.5+(1.15+1.15*b)*kuPulse(kuPh*.5-g*.5-r*.012);}
  else if(f<3.5){vec2 t=mod(q+12.,24.)-12.;float n=floor(max(abs(t.x),abs(t.y))/1.5);h=max(7.-n,0.)*.62-1.6+(.35+.9*b)*kuPulse(kuPh-n*.07);}
  else if(f<4.5){float bi=abs(mod(abs(q.x)+.5,16.)-8.)/8.;h=-2.+5.6*pow(kuBand(1.-bi),1.15)+.5*sin(q.y*.45-P);}
  else if(f<5.5)h=(1.+b)*sin(3.*atan(q.y,q.x)+.5*r-kuTk*PI*.25);
  else if(f<6.5)h=1.8*b*sin(.5*q.x-P)*cos(.5*q.y+P*.5);
  else if(f<7.5){
    // skyline: a sparse city of towers, each tuned to one band (its height breathes with that band), low plinths between
    float hb=fract(hc*7.31),tw=step(hb,.24);
    h=mix(-1.7+.6*b*kuPulse(kuPh*.5-r*.02),(1.6+11.*hb/.24)*(.55+.6*kuBand(fract(hc*3.7)))*(1.+1.4*kuLift),tw);
  }
  else if(f<8.5){
    // cube cloud: every cube floats at its own height and bobs slowly
    float hb=fract(hc*5.13);
    h=.8+11.5*hb*hb+1.3*sin(kuTk*PI*.25+hc*TAU)*(.4+.6*kuAct)+.8*b*sin(.3*r-P);
  }
  else if(f<9.5){
    // grand stepped pyramid with a pulse climbing its steps
    vec2 t=mod(q+30.,60.)-30.;float n=floor(max(abs(t.x),abs(t.y))*.9);
    h=max(15.-n,0.)*.68-1.7+(.3+.7*b)*kuPulse(kuPh*.5-n*.06);
  }
  else if(f<10.5){
    // Terraced square citadels with an open courtyard; waves climb the four parapets.
    vec2 z=mod(q+13.,26.)-13.;float e=max(abs(z.x),abs(z.y));
    h=-1.7+8.*smoothstep(4.,7.,e)*(1.-smoothstep(10.,12.,e))+.75*b*sin(e-kuTk*.6872);
  }else if(f<11.5){
    // Interlaced helical ribbons of floating Rubik cubes.
    float an=atan(q.y,q.x),ph=an*2.+r*.32-kuTk*.2945;
    h=3.5+4.2*sin(ph)+1.1*cos(r*.4+kuTk*.1963);
  }
  if(f>11.5&&f<12.5){
    // Aztec terraces wrapped around luminous circular amphitheatres.
    vec2 z=mod(q+18.,36.)-18.;float rr=length(z);
    float seats=clamp(floor((16.-rr)*.8),0.,8.);
    h=-1.8+seats*.85*smoothstep(2.,5.,rr)+.4*b*sin(rr*.65-kuTk*.3927);
  }else if(f>12.5){
    // Two crossing cube waves weave over and under one another like a living basket.
    float lane=mod(floor(q.x/3.)+floor(q.y/3.),2.);
    h=3.2+3.8*sin(mix(q.x,q.y,lane)*.38-kuTk*.2945)+1.4*cos((q.x-q.y)*.24+kuTk*.1963);
  }
  return h;
}
float kuIsPil(float f){return step(2.5,f)*step(f,4.5)+step(6.5,f)*step(f,7.5)+step(8.5,f)*step(f,10.5)+step(11.5,f)*step(f,12.5);}
float kuIsCl(float f){return step(7.5,f)*step(f,8.5);}
// v11 spectrum map: which band (0 sub .. 1 air) a cell plays; mode in kuSM
float kuBx(vec2 c){
  // one band per row of cubes, mirrored (sub .. air .. sub) so all eight bands sit side by side across the screen
  vec2 q=c/kuSq;
  if(kuSM<.5)return abs(mod(q.x+8.,16.)-8.)/7.5;
  if(kuSM<1.5)return abs(mod(length(q)+8.,16.)-8.)/7.5;
  if(kuSM<2.5)return abs(mod((q.x+q.y)*.7071+8.,16.)-8.)/7.5;
  return abs(mod(max(abs(q.x),abs(q.y))+8.,16.)-8.)/7.5;
}
float kuRing(float code,float r){
  float a=mod(code,64.),A=floor(code/64.)*.01,rr=a*6.*kuSq,d=(r-rr)/(1.9*kuSq);
  return A*smoothstep(0.,.25,a)*exp(-1.6*a)*smoothstep(1.3,.7,a)*exp(-d*d)*1.45;
}

// snare row wave (two in flight): a band of raised cubes sweeping across the rows, gone within a beat
float kuSnare(float code,vec2 c){
  float sa=mod(code,128.),sd=mod(floor(code/128.),4.);
  vec2 sv=sd<.5?vec2(1.,0.):(sd<1.5?vec2(0.,1.):(sd<2.5?vec2(-1.,0.):vec2(0.,-1.)));
  float xs=(dot(c,sv)-(sa*12.-7.)*kuSq)/(2.2*kuSq);
  return .75*smoothstep(0.,.12,sa)*smoothstep(1.,.55,sa)*exp(-xs*xs);
}
// v19 motion shapes, all continuous in the age. kuArc is the leap (a soft take-off into a parabola), kuLand the squash
// after it comes down, kuTri a triangle wave for the marching stairs.
float kuArc(float x){x=clamp(x,0.,1.);return 4.*x*(1.-x)*min(x*7.,1.);}
float kuLand(float y){y=clamp(y,0.,1.);return 4.*y*(1.-y)*(1.-y);}
float kuTri(float x){return abs(fract(x)-.5)*2.;}
// what each kind of cube does to the music: nine rows (speaker, face, tower, pipes, harlequin, dice, gem, weave, flower).
// One row per kind is read from this table, so the whole instrument code is a single straight line for the D3D compiler.
//   x y z w of row 0: leap on kick, snare, hat, mids          row 1: leap on air, presence, sub, squash on landing
//   row 2: grow on snare, air, sub, presence                  row 3: stretch on kick, snare, mids, whole flip on the kick
//   row 4: full twirl on hat, on snare, on snare (half the flock), sub pancake
const vec4 KUK[45]=vec4[45](
  vec4(2.3,0.,0.,0.),vec4(0.,0.,0.,.9),vec4(0.),vec4(.45,0.,0.,0.),vec4(0.),
  vec4(0.,2.7,0.,0.),vec4(0.),vec4(.2,0.,0.,0.),vec4(0.,.65,0.,0.),vec4(0.),
  vec4(0.,0.,0.,3.6),vec4(0.),vec4(0.),vec4(0.,0.,1.1,0.),vec4(0.),
  vec4(0.,0.,.8,0.),vec4(0.),vec4(0.),vec4(0.),vec4(1.,0.,0.,0.),
  vec4(0.,.9,0.,0.),vec4(0.),vec4(0.),vec4(0.),vec4(0.,1.,0.,0.),
  vec4(1.9,0.,0.,0.),vec4(0.),vec4(0.),vec4(0.,0.,0.,1.),vec4(0.),
  vec4(0.),vec4(2.,0.,0.,0.),vec4(0.,.25,0.,0.),vec4(0.),vec4(1.,0.,0.,0.),
  vec4(0.),vec4(0.,0.,-.5,0.),vec4(0.,0.,.42,0.),vec4(0.),vec4(0.,0.,0.,.8),
  vec4(0.),vec4(0.,2.1,0.,0.),vec4(0.,0.,0.,.5),vec4(0.),vec4(0.,0.,1.,0.));
struct KuC{vec3 cen,he;float yaw,th,ax,rs,p,pil,bx,sel,sp,mh,ms,hc,tp;};
KuC kuCell(vec2 cell,bool lite){
  KuC C;
  vec2 c=cell+.5,q=c/kuSc;
  float r=length(c),hc=h21(mod(cell,512.)*1.37+.7);
  // formation morph: a staggered wave out from the centre, smootherstep per cube
  float w=kuEase((uP4.z-min(r*kuK,2.))/1.5);
  // morph: each cube settles onto the floor and rises into the new formation as the staggered front passes (one
  // formation evaluated per cube, which halves the D3D compile of the formation code)
  float fS=w<.5?kuFA:kuFB,sk=abs(2.*w-1.);sk=sk*sk*(3.-2.*sk);
  float h=mix(-2.7,kuForm(fS,q,hc)*pow(kuSc,.75),sk),pil=kuIsPil(fS);
  // v11: the grid plays the spectrum. Each cell belongs to one band (rows, rings, diagonals or patches); its cube rides
  // that band's smoothed envelope, and a few chosen cubes per band pop up on that band's onsets (smoothed pops).
  float bx=kuBx(c),bv=kuBand(bx),sel=step(fract(hc*13.7),.2);
  h=h*(1.-.45*min(kuSA,1.))+kuSA*(4.6*bv*sqrt(bv)-.9)*pow(kuSc,.75)+sel*kuPopB(bx)*2.5*pow(kuSc,.75);
  C.bx=bx;C.sel=sel;
  // kick ripples (three in flight), the snare row wave, builds float the cubes up to staggered heights
  h+=kuRing(uP3.y,r)+kuRing(uP3.z,r)+kuRing(uP3.w,r);
  h+=kuSnare(uM1[2][2],c)+kuSnare(uM2[2][2],c);
  // v19: the bass swell is a travelling thump now (a pulse per beat), not a sine sway
  h+=1.1*kuBass*kuPulse(kuPh*.5-r*.05/kuSq)*(1.-.6*pil)*kuSq;
  h+=kuLift*(1.2+3.6*hc*hc);
  float ps=pow(kuSc,.75),hc1=fract(hc*3.7),hc3=fract(hc*9.1);
  float sqz=0.,stc=0.,gro=0.,twirl=0.,flip=0.,ga=1.;
  // lite is the copy compiled for shadow and reflection rays: dance heights and rotations, plus the routines, are skipped there
  if(!lite){
  // v19: EVERY cube is an instrument. Its kind (the same kind its face is painted with, so a district of speakers is a
  // district that plays the kick) sets which sound it answers and how.
  float hs1=h21(mod(floor((cell+.5)/5.),512.)+13.3),hs2=h21(mod(cell,512.)+41.7);
  float kind=floor(mod((hs2<.3?hs2*30.:hs1*9.),9.));
  C.sp=kind;
  // the two halves of the city take alternate kicks; the split between them changes with the music
  float si=mod(floor(cell.x*kuPatV.x)+floor(cell.y*kuPatV.y),2.);
  float ka=(si<.5?kuKA:kuKB)-.07*hc1,sa=kuSnA-.07*hc1,ha=kuHatA-.06*hc1,hKick=kuArc(ka/.72),hSn=kuArc(sa/.8);
  float lnd=kuLand((ka-.72)/.42);
  float eH=kuEase(ha/.52),eS=kuEase(sa/.85),aH=kuArc(ha/.52);
  float dirH=hc3<.5?-1.:1.,dirS=mod(cell.x+cell.y,2.)<.5?-1.:1.;
  int ki=int(kind)*5;
  vec4 K0=KUK[ki],K1=KUK[ki+1],K2=KUK[ki+2],K3=KUK[ki+3],K4=KUK[ki+4];
  h+=(.42*hKick+K0.x*hKick+K0.y*hSn+K0.z*aH+K0.w*kuMi+K1.x*kuAi+K1.y*kuPr+K1.z*kuSu)*ps;
  sqz=K1.w*lnd+K4.w*kuSu;stc=K3.x*hKick+K3.y*hSn+K3.z*kuMi;gro=K2.x*hSn+K2.y*kuAi+K2.z*kuSu+K2.w*kuPr;
  twirl=K4.x*eH*dirH+K4.y*eS*dirS+K4.z*eS*step(.5,hc3);flip=K3.w*kuEase(ka/.72);
  // v19: the choreography. One routine at a time runs across the whole city (the weights are set once per pixel in realm):
  // a leap that runs along some ordering of the city, pistons, marching stairs, a ticking clock arm, craters, or the gasp.
  float aw=kuActW,rw0=mod(floor(dot(c,kuLV)),kuLM);
  float ord=mix(mix(rw0,abs(rw0-kuLM*.5),kuLMir),floor(h21(mod(floor(c/6.),256.)+7.7)*16.),kuLBl);
  float agl=mod(kuPh*kuLR-ord,kuLM);
  h+=aw*kuLW*ps*(kuLA+kuLB*kuBand(mix(min(1.,ord/(15.-7.5*kuLMir)),hc1,kuLBl)))*kuArc(agl/kuLD);
  h+=aw*kuWP*ps*(1.-2.*mod(rw0,2.))*(.9+1.7*kuBass)*kuPulse(kuPh*2.-hc1*.04);
  h+=aw*kuWS*ps*(kuTri((floor((c.x+c.y)*.5)+kuTk)/8.)*4.6-2.1);
  if(kuWA>.5){float da=dot(c,kuArm),arm=step(0.,da)*step(abs(dot(c,vec2(kuArm.y,-kuArm.x))),1.6*kuSq);h+=aw*ps*arm*(1.3+3.*kuBass)*min(da*.25,1.);}
  {float d=length(c-kuCr)/kuSq,a2=clamp(kuCrA/1.25,0.,1.),e=(d-a2*9.)/1.5;h+=aw*kuWC*ps*smoothstep(0.,.1,a2)*(1.-a2)*(1.-a2)*(5.*exp(-e*e)-4.5*exp(-d*d*.2));}
  ga=mix(1.,.66+.34*smoothstep(.1,.86,min(kuKA,kuKB)),aw*kuWG);
  // v19: a build sends the cubes into a drum roll that doubles as it climbs
  {float u=smoothstep(.45,.85,kuBW),p2=kuPulse(kuPh*2.-hc1*.06),p8=kuPulse(kuPh*8.-hc1*.2);h+=kuBW*(mix(.9*p2,.65*p8,u)*(1.-.5*pil))*ps;}
  // v19: the drop detonates the city: everything is thrown skyward at its own height and spin, then rains back and lands
  {
    float x=clamp((kuDA-1.2*hc3)/(3.2+1.6*hc1),0.,1.4);
    h+=kuArc(x)*(1.-.55*pil)*min((7.+15.*hc1)*ps,max(kuCamY-h-1.8,0.));
    flip+=2.*step(.5,hc3)*kuEase(x)*(1.-pil);twirl+=(hc1<.5?-2.:2.)*kuEase(x)*(1.-pil);
    sqz=max(sqz,.9*kuLand((x-1.)*3.));
  }
  }
  // cascade: each cube rolls a quarter turn (ease-out-back) when the front reaches it, hopping as it goes
  float ct=mod(kuCT,4.);
  float dl=ct<.5?r*kuK:(ct<1.5?(dot(c,kuDir)+18.*kuSq)*kuK*.55:(ct<2.5?hc*1.7:(abs(c.x)+abs(c.y))*kuK*.8));
  float p=clamp((uP4.w-min(dl,2.))/.9,0.,1.);
  C.p=p;
  vec2 rv=ct<.5||ct>2.5?(abs(c.x)>abs(c.y)?vec2(sign(c.x),0.):vec2(0.,sign(c.y))):(ct<1.5?kuDir:(hc<.25?vec2(1.,0.):(hc<.5?vec2(-1.,0.):(hc<.75?vec2(0.,1.):vec2(0.,-1.)))));
  C.ax=abs(rv.x)>.5?0.:1.;C.rs=rv.x+rv.y;
  C.th=PI*.5*kuBack(p)*kuRoll;
  // v19 flip is a whole number of turns, so a cube always lands on its own face. Pillars stand firm.
  C.th+=TAU*flip*(1.-pil);
  float hs=sin(PI*p);h+=kuHop*hs*hs;
  C.yaw=kuYaw*(1.-2.*mod(cell.x+cell.y,2.))*(1.-pil);
  if(lite){C.th=0.;C.yaw=0.;}
  // v14: the mid band shears the field; v19: a quick twitch on the mid onsets, checker-opposed, instead of a sine sway
  // v20: the checker twitch on mid onsets is gone: it shivered every cube a few degrees many times a bar and read as jitter, not as a move
  C.yaw+=TAU*twirl;
  // the cloud's cubes tumble slowly, each at its own angle
  float cl=kuIsCl(fS)*sk;
  C.yaw+=cl*(hc*TAU+kuPh*(floor(hc*5.)-2.)*.09817);
  // the cube shrinks a little while turned so it never leaves its cell
  if(lite){C.th=0.;C.yaw=0.;}
  float ry=abs(cos(C.th))+abs(sin(C.th)),cy=abs(cos(C.yaw)),sy=abs(sin(C.yaw));
  float ex=max(ry*cy+sy,ry*sy+cy);
  // v14: the smoothed bass swells the whole field by 12%; the plaza paving is laid tight so the courtyard reads as a floor
  // v19: squash and stretch keep the volume readable; it can never leave its cell
  // v20: mid onsets pump the size of alternate cubes (a punch in place of the old twitch)
  gro+=.3*kuPopB(.45)*mod(cell.x+cell.y,2.)*(1.-pil);
  float s=min(kuS*(1.+.14*kuBass)*ga*(1.+gro),.485/ex);
  float sy2=s*(1.+stc)*(1.-.62*sqz*(1.-pil)),sx=min(s*(1.-.3*stc+.42*sqz*(1.-pil)),.485/ex);
  h=max(h,KU_FLOOR+sy2+.25);
  float bot=mix(h-sy2,KU_FLOOR,pil),top=h+sy2;
  C.cen=vec3(c.x,(top+bot)*.5,c.y);C.he=vec3(sx,(top-bot)*.5,sx);C.pil=pil;
  // v19 popcorn: every hat, a new fifth of the cubes spit a little cube out of their tops; it arcs and falls back in
  {float pa=kuHatA-.1*hc1,x=clamp(pa/.6,0.,1.),on=step(fract(hc*53.1+kuHatC*.381),.23)*step(.001,x)*step(x,.999);
   // v20: the popcorn grows out of the top and shrinks back in (it used to appear and vanish at full size), and is not thrown where it would be under about two pixels:
   // far away it was a field of single bright pixels blinking, most of this realm's measured flicker that was not a cube actually jumping
   C.ms=on*.15*sqrt(ps)*(1.-.35*x)*smoothstep(0.,.15,x)*smoothstep(1.,.8,x)*(1.-smoothstep(.3,.6,length(vec3(c.x-kuRo.x,kuRo.y,c.y-kuRo.z))*kuPix/(.15*sqrt(ps))));C.mh=top+C.ms+.05+4.2*kuArc(x)*ps;C.hc=hc;C.tp=top;}
  return C;
}

vec2 kuRot(vec2 v,float a){float c=cos(a),s=sin(a);return vec2(c*v.x-s*v.y,s*v.x+c*v.y);}
// world -> cube-local (inverse yaw, then inverse roll)
vec3 kuToLocal(vec3 v,KuC C){
  v.xz=kuRot(v.xz,-C.yaw);
  float b=C.rs*C.th;
  if(C.ax<.5)v.xy=kuRot(v.xy,b);else v.zy=kuRot(v.zy,b);
  return v;
}
vec3 kuToWorld(vec3 v,KuC C){
  float b=-C.rs*C.th;
  if(C.ax<.5)v.xy=kuRot(v.xy,b);else v.zy=kuRot(v.zy,b);
  v.xz=kuRot(v.xz,C.yaw);
  return v;
}
float kuLine(float d,float w,float px){return 1.-smoothstep(w-px*.6,w+px*.6,d);}
// v19 detail range: each level of engraving appears only where its lines are wider than a pixel, so more pixels reveal more of it
// v20: the ladder moved down a tier. Level 1 (ribs, irises, mullions, star cuts, threads, veins) is now part of the phone picture
float kuD1(float px){return 1.-smoothstep(.03,.08,px);}
float kuD2(float px){return 1.-smoothstep(.012,.035,px);}
float kuD3(float px){return 1.-smoothstep(.005,.015,px);}

// v18: the character of each cube. Nine kinds of hand-made face, chosen per cell (districts of one kind, with strays).
// Everything here is light and paint on the face, so it can answer the music directly without moving any geometry.
vec3 kuArt(float sp,vec2 uv,float px,vec3 base,vec3 fc,vec3 c2,vec3 c3,vec3 cream,vec3 ink,float bl,float bo,float hc,float fid,vec2 cell){
  float r=length(uv),ax=abs(uv.x),ay=abs(uv.y);
  vec3 c=base;
  if(sp<.5){
    // loudspeaker: the cone rings run outward and the dust cap swells and glows with this cube's band
    float R=.74;
    c=mix(c,ink*1.6+fc*.16,kuLine(r,R,px));
    float rr=fract(r*5.5-bl*1.6);
    c+=fc*.5*kuLine(abs(rr-.5),.18,px*5.5)*step(.3,r)*kuLine(r,R,px)*(.4+bl);
    c=mix(c,c2*1.1,kuLine(abs(r-R),.05,px));
    float cap=.2+.13*bl+.1*bo;
    c=mix(c,fc*(1.+1.6*bl)+cream*.5*bo,kuLine(r,cap,px));
    // v19: each kick sends a shock ring out across the cone
    {float k0=min(kuKA,kuKB)/.5;if(k0<1.)c+=cream*.9*(1.-k0)*kuLine(abs(r-(.2+.55*k0)),.035,px);}
    // the rubber surround is ribbed; the four corner bolts have slots
    {float d1=kuD1(px),rib=smoothstep(R-.17,R-.12,r)*(1.-smoothstep(R-.02,R,r));
     c*=1.-.2*rib*d1*(.5+.5*cos(r*70.));
     vec2 bq=vec2(ax,ay)-.82;
     c=mix(c,ink*1.4,kuLine(abs(bq.x+bq.y)*.7,.009,px)*step(length(bq),.06)*d1);
#if HD>=1
     // a perforated mesh over the dust cap and pressed lines in the cone
     float d2=kuD2(px),a0=atan(uv.y,uv.x),ms=length(fract(uv*24.)-.5);
     c=mix(c,ink*1.5,smoothstep(.34,.22,ms)*d2*kuLine(r,cap*.92,px)*.75);
     c*=1.+.09*d2*cos(a0*48.)*step(cap,r)*step(r,R-.17);
#if HD>=2
     c*=1.+.06*kuD3(px)*cos(a0*260.+r*90.)*step(cap,r)*step(r,R);
#endif
#endif
    }
    c=mix(c,cream*.8,kuLine(length(vec2(ax,ay)-.82),.06,px));
  }else if(sp<1.5){
    // a little character: eyes that wander and blink, cheeks, and a mouth that opens with its band
    float bk=smoothstep(0.,.04,abs(fract(kuPh*.25+hc*5.3)-.5)-.03);
    // v19: a snare startles the whole crowd, eyes wide and mouth open, and every eye snaps to the same spot, a new one per kick
    float sn=exp(-max(kuSnA,0.)*3.6);bk=max(bk,sn);
    vec2 gs=vec2(sin(kuKC*2.4),cos(kuKC*3.7))*.1;
    vec2 gz=vec2(sin(kuPh*.2945+hc*21.),cos(kuPh*.1963+hc*11.))*.07;
    gz=mix(gz,gs,min(1.,sn*2.));
    float ew=.24*(1.+.28*sn);
    vec2 e=vec2(ax-.33,(uv.y-.2)/max(bk,.08));
    c=mix(c,cream*1.1,kuLine(length(e),ew,px));
    vec2 pu=vec2(ax-.33,uv.y-.2)-gz;
    c=mix(c,ink,kuLine(length(pu),.12,px)*bk);
    c=mix(c,c2,kuLine(length(vec2(ax-.6,uv.y+.14)),.14,px)*.75);
    float mh=.05+.27*bl+.1*bo+.26*sn;
    vec2 m=vec2(uv.x/.36,(uv.y+.42)/mh);
    float md=(length(m)-1.)*min(.36,mh);
    c=mix(c,ink*1.4+c3*.1,kuLine(md,0.,px));
    // an iris and a catch light, brows that jump with the snare, teeth in the open mouth
    {float d1=kuD1(px),pr=length(pu);
     c=mix(c,c3,kuLine(abs(pr-.17),.04,px)*bk*d1);
     c=mix(c,cream*1.25,kuLine(length(pu-vec2(.05)),.035,px)*bk*d1);
     vec2 br=vec2(ax-.33,uv.y-.53-.09*sn-.05*sin(ax*5.));
     c=mix(c,ink*1.3,kuLine(max(abs(br.y)-.012,abs(br.x)-.2),.02,px)*d1);
     float inm=step(md,0.);
     c=mix(c,cream,inm*step(.1,m.y)*step(abs(fract(m.x*3.5)-.5),.42)*smoothstep(.04,.14,mh)*d1);
#if HD>=1
     // lashes and freckles
     float d2=kuD2(px),ang=atan(uv.y-.2,ax-.33);
     if(length(vec2(ax-.33,uv.y-.2))<ew*1.35&&uv.y>.2)c=mix(c,ink*1.2,step(.72,fract(ang*9.))*step(ew,length(vec2(ax-.33,uv.y-.2)))*d2*bk);
     vec2 fc2=vec2(ax-.6,uv.y+.14)*9.;
     c=mix(c,ink*1.5,step(length(fract(fc2)-.5),.16)*step(length(vec2(ax-.6,uv.y+.14)),.14)*d2*.6);
#if HD>=2
     c*=1.+.05*kuD3(px)*sin(uv.x*170.)*sin(uv.y*170.);
#endif
#endif
    }
  }else if(sp<2.5){
    // a tower block: four rows of windows; how many are lit follows the band
    vec2 g=(uv*.5+.5)*4.,id=floor(g),f=abs(fract(g)-.5);
    float h=h21(id+cell*.37+fid*7.3+floor(kuKC*.25)*.77),on=smoothstep(h-.1,h+.1,.12+.95*bl),w=kuLine(max(f.x,f.y),.32,px*2.);
    c=mix(c,fc*.3+ink*.5,step(max(ax,ay),.98)*.65);
    c=mix(c,mix(c*.5,(h>.5?c2:cream)*(1.25+.8*bo),on),w);
    // mullions and a stone sill on every window
    {float d1=kuD1(px);
     c=mix(c,ink*1.5,w*kuLine(min(f.x,f.y),.012,px*2.)*d1);
     c=mix(c,cream*.7,kuLine(abs(f.y-.33)+max(f.x-.32,0.),.009,px*2.)*step(fract(g.y)-.5,0.)*d1);
#if HD>=1
     // a figure or a curtain inside the lit windows
     float d2=kuD2(px);vec2 w2=vec2(fract(g.x)-.5,fract(g.y)-.5);
     float fig=step(length(vec2(w2.x,w2.y-.08)),.09)+step(max(abs(w2.x)-.09,w2.y+.02),0.);
     c=mix(c,ink*1.2,on*w*d2*step(.4,h)*step(h,.7)*min(fig,1.));
     c=mix(c,fc*.65,on*w*d2*step(h,.3)*step(.0,w2.x-.08*sin(w2.y*30.)));
#if HD>=2
     c=mix(c,ink*1.5,(1.-w)*kuD3(px)*.5*kuLine(abs(fract(uv.y*20.)-.5)+min(abs(fract((uv.x+.5*floor(uv.y*20.))*10.)-.5),.2)*.5,.03,px*20.));
#endif
#endif
    }
  }else if(sp<3.5){
    // truchet tiles: one unbroken pipe wandering over the face, with a bright core
    vec2 g=(uv*.5+.5)*3.,id=floor(g),f=fract(g);
    if(h21(id+cell*.53+fid+floor(kuHatC*.25)*.61)>.5)f.x=1.-f.x;
    float d=min(abs(length(f)-.5),abs(length(f-1.)-.5));
    c=mix(c,c2*1.05,kuLine(d,.17,px*1.5));
    // the pipe has a rim, a bright core and (closer) rivets running along it
    {float d1=kuD1(px);
     c=mix(c,ink*1.4,kuLine(abs(d-.17),.018,px*1.5)*d1);
     c=mix(c,mix(c2,cream,.55),kuLine(d,.035,px*1.5)*d1);
#if HD>=1
     float d2=kuD2(px),a0=atan(f.y,f.x);if(length(f-1.)<length(f))a0=atan(1.-f.y,1.-f.x);
     c=mix(c,cream,step(abs(fract(a0*12.)-.5),.2)*kuLine(abs(d-.1),.02,px*1.5)*d2);
#if HD>=2
     vec2 g2=f*5.;float dd=min(abs(length(fract(g2))-.5),abs(length(fract(g2)-1.)-.5));
     c=mix(c,c3,kuLine(dd,.06,px*7.)*kuD3(px)*smoothstep(.2,.3,d));
#endif
#endif
    }
  }else if(sp<4.5){
    // harlequin diamonds with a stud on each crossing
    vec2 g=vec2(uv.x+uv.y,uv.x-uv.y)*1.5,id=floor(g),f=abs(fract(g)-.5);
    c=mix(c,mod(id.x+id.y+kuSnC,2.)>.5?c2:c3,.9);
    c=mix(c,ink*1.3,kuLine(.5-max(f.x,f.y),.05,px*2.));
    c=mix(c,cream*(.8+1.1*bo),kuLine(length(.5-f),.1,px*2.));
    // a second diamond inside each diamond
    {float d1=kuD1(px),m0=max(f.x,f.y);
     c=mix(c,ink*1.1,kuLine(abs(m0-.26),.012,px*2.)*d1);
#if HD>=1
     float d2=kuD2(px);
     c=mix(c,cream*.8,kuLine(abs(m0-.14),.01,px*2.)*d2);
     c=mix(c,mod(id.x+id.y+kuSnC,2.)>.5?c3:c2,kuLine(m0,.08,px*2.)*d2*.9);
#if HD>=2
     vec2 h2=f*7.;float d3=kuD3(px);
     c=mix(c,cream,step(length(fract(h2)-.5),.14)*d3*.5*smoothstep(.16,.2,m0));
#endif
#endif
    }
  }else if(sp<5.5){
    // dice: every face has its own pips, which fire on the kick
    float n=mod(fid+kuKC+floor(hc*6.)-1.,6.)+1.,d=1e3;
    if(mod(n,2.)>.5)d=r;
    if(n>1.5){vec2 q=abs(uv);if(n<3.5&&uv.x*uv.y<0.)q=vec2(9.);d=min(d,length(q-.46));}
    if(n>5.5)d=min(d,length(vec2(ax-.46,uv.y)));
    c=mix(c*.8+cream*.25,c,.2);
    c=mix(c,ink*1.3+fc*(.3+2.2*kuBass),kuLine(d,.17,px));
    // pips are drilled, with a light lip; closer up, the ivory has flecks and each pip holds a tiny die of its own
    {float d1=kuD1(px);
     c=mix(c,cream*1.1,kuLine(abs(d-.17),.012,px)*d1*.7);
#if HD>=1
     float d2=kuD2(px);
     c*=1.+.1*d2*(h21(floor(uv*40.))-.5);
     if(d<.17){vec2 pq=uv*6.;c=mix(c,cream,step(length(fract(pq)-.5),.22)*d2*.8);}
#if HD>=2
     if(d>.17){vec2 q2=uv*16.;c=mix(c,ink*1.2,step(length(fract(q2)-.5),.1)*kuD3(px)*.45);}
#endif
#endif
    }
  }else if(sp<6.5){
    // a cut gem: four bevelled facets around a bright table, and the table flashes on this band's onsets
    float cb=max(ax,ay),f=ax>ay?(uv.x>0.?.55:1.2):(uv.y>0.?1.45:.8);
    float sw=.5+.5*sin(kuPh*.5+hc*12.+f*4.);
    c=mix(mix(c2,cream,.15)*(.85+.5*sw),fc*f*1.05,smoothstep(.40,.40+px,cb));
    c=mix(c,cream*(1.+1.8*bo),kuLine(abs(cb-.4),.02,px)*.8);
    // a star cut: eight table facets and a ring of bezel lines
    {float d1=kuD1(px),a0=atan(uv.y,uv.x),sec=floor(a0/TAU*8.+.5);
     vec2 sd2=uv*mat2(cos(sec*TAU/8.),-sin(sec*TAU/8.),sin(sec*TAU/8.),cos(sec*TAU/8.));
     c=mix(c,c*(.7+.6*step(0.,sd2.y)),d1*step(cb,.4)*.8);
     c=mix(c,cream*.8,kuLine(abs(sd2.y),.006,px)*d1*step(cb,.4));
#if HD>=1
     float d2=kuD2(px);
     c=mix(c,cream*1.1,kuLine(abs(cb-.62),.006,px)*d2);
     c=mix(c,c*1.25,step(.5,fract(cb*12.))*d2*smoothstep(.42,.5,cb)*.6);
#if HD>=2
     c+=cream*step(.94,h21(floor(uv*60.)+floor(kuPh*4.)))*kuD3(px)*(.5+bo);
#endif
#endif
    }
  }else if(sp<7.5){
    // basket weave: four ribbons over and under, each with a rounded shade across its width
    vec2 g=(uv*.5+.5)*4.,id=floor(g),f=fract(g);
    float ov=mod(id.x+id.y+floor(kuKC*.5),2.),wv=ov>.5?f.x:f.y;
    c=mix(c,ov>.5?c2:c3,.92)*(.68+.55*sin(PI*wv));
    c=mix(c,ink*1.2,kuLine(min(wv,1.-wv),.05,px*2.)*.7);
    // the ribbons are spun of threads
    {float d1=kuD1(px),along=ov>.5?f.y:f.x;
     c*=1.-.14*d1*step(.55,fract(wv*7.));
#if HD>=1
     float d2=kuD2(px);
     c*=1.-.12*d2*step(.6,fract(along*18.+step(.5,fract(wv*7.))*.5));
#if HD>=2
     c*=1.+.08*kuD3(px)*sin(wv*190.)*sin(along*170.);
#endif
#endif
    }
  }else{
    // a turning flower: its petals open wider with the band
    float a=atan(uv.y,uv.x)+kuPh*.09817*(hc>.5?1.:-1.),n=6.+floor(hc*5.)*2.;
    float pr=.46+.26*bl+.14*cos(n*a);
    c=mix(c,c2,kuLine(r,pr,px));
    c=mix(c,c3*(1.+bl),kuLine(r,.2,px));
    // veins down each petal and a ring of stamens
    {float d1=kuD1(px),pv=abs(fract(a*n/TAU)-.5);
     c=mix(c,ink*1.2,kuLine(pv,.02,px*n/max(r,.2))*step(.2,r)*step(r,pr)*d1*.8);
#if HD>=1
     float d2=kuD2(px),sr0=abs(fract(a*16./TAU)-.5);
     c=mix(c,cream,step(length(vec2((r-.13)*16.,sr0*2.)),.5)*d2);
     c=mix(c,ink*1.1,kuLine(abs(r-pr*.86),.006,px)*d2*.6);
#if HD>=2
     c+=c2*.25*step(.82,h21(floor(uv*48.)))*kuD3(px)*step(r,pr);
#endif
#endif
    }
  }
  return c;
}

float kuTr=0.;   // distance already travelled before this ray (footprint of reflections)
#if HD>=2
// what a reflection sees: a cube's colour, shading, band glow and ink outline, without the painted art (one inline copy of the
// full surface shader per pass would cost several times the compile for detail nobody can read in a lacquer reflection)
vec3 kuLite(vec3 rd,KuC C,vec2 cell,float tH,vec3 lv,vec3 lw,vec3 lt,out vec3 nh,out float tp){
  vec3 nl=-sign(lw)*step(lt.yzx,lt)*step(lt.zxy,lt),q=(lv+lw*tH)/C.he;
  nh=kuToWorld(nl,C);tp=step(.5,nh.y);
  vec2 qc=(cell+.5)/kuSc;
  vec3 fc=mix(kuCol(kuCA,qc),kuCol(kuCB,qc),kuEase(C.p));
  float hc2=h21(mod(cell,512.)*1.37+.7);fc*=.84+.3*fract(hc2*17.3);
  if(C.sp<0.)fc=mix(fc,kuCream,.45)*1.25;
  vec3 an=abs(nl);vec2 uv=an.x>.5?q.zy:(an.y>.5?q.xz:q.xy);
  float tone=(.4+.6*max(dot(nh,kuL),0.))/(.4+.6*max(kuL.y,.01));
  float cb=max(abs(uv.x),abs(uv.y)),px=(tH+kuTr)*kuPix/(C.he.x*max(abs(dot(nh,rd)),.25));
  vec3 base=fc*min(tone,1.15)*(1.+.35*tp*uO1.x);
  base+=fc*kuLine(abs(cb-.8),.045,px)*(.2+.8*kuBand(C.bx));
  return mix(base,kuInk6,kuLine(1.-cb,max(.065,px*1.1),px)*mix(1.,.45,smoothstep(.15,.45,px)));
}
#endif
#if HD>=5
#define KU_NM 9
#elif HD>=4
#define KU_NM 7
#elif HD>=3
#define KU_NM 5
#elif HD>=2
#define KU_NM 3
#elif HD>=1
#define KU_NM 2
#endif
// v19: the column walk, shared by the camera ray and (at HD>=1) every shadow, occlusion and reflection ray.
#define KU0 min(int(uTime),0)
#if HD>=1
#define KU_MS 640
#else
#define KU_MS 220
#endif
bool kuTrace(vec3 ro,vec3 rd,float tMax,float NF,out KuC C,out vec2 cell,out float tH,out vec3 lv,out vec3 lw,out vec3 lt,out float steps,bool wi,out vec3 li,out vec3 ln,out float ltp,bool mi,bool lt1){
  float t0=0.,t1=tMax;
  bool any=true;
  if(abs(rd.y)>1e-5){float tA=(KU_FLOOR-ro.y)/rd.y,tB=(kuYT-ro.y)/rd.y;t0=max(0.,min(tA,tB));t1=min(max(tA,tB),tMax);if(t1<0.)any=false;}
  else if(ro.y>kuYT)any=false;
  C.cen=vec3(0);C.he=vec3(.3);C.yaw=0.;C.th=0.;C.ax=0.;C.rs=1.;C.p=0.;C.pil=0.;C.bx=0.;C.sel=0.;C.sp=0.;C.mh=0.;C.ms=0.;C.hc=0.;C.tp=0.;
  cell=vec2(0);tH=1e9;steps=0.;lv=vec3(0);lw=vec3(0);lt=vec3(0);li=vec3(0);ln=vec3(0,1,0);ltp=0.;
  bool hit=false;
  if(any&&t1>t0){
    vec3 ps=ro+rd*(t0+1e-4);
    vec2 sg=vec2(rd.x>=0.?1.:-1.,rd.z>=0.?1.:-1.),ia=1./max(abs(rd.xz),vec2(1e-6));
    cell=floor(ps.xz);
    vec2 tM=t0+(cell+max(sg,0.)-ps.xz)*sg*ia;
    float tc=t0;
    int NI=int(NF);
    for(int i=KU0;i<KU_MS;i++){
      if(i>=NI||tc>=t1)break;
      steps+=1.;
      float tn=min(min(tM.x,tM.y),t1);
      C=kuCell(cell,lt1);
      // cheap reject: the ray's height over this column against the cube's vertical reach (and any popcorn above it)
      float ya=ro.y+rd.y*tc,yb=ro.y+rd.y*tn,ext=C.he.y+(1.-C.pil)*.5*C.he.x+(HD>=1?.5:0.),up=C.ms>0.?C.mh+C.ms-C.cen.y:ext;
      if(max(ya,yb)>C.cen.y-ext&&min(ya,yb)<C.cen.y+max(ext,up)){
        vec3 v=kuToLocal(ro-C.cen,C),w=kuToLocal(rd,C);
        w+=vec3(1e-7)*step(abs(w),vec3(1e-7));
        vec3 m=1./w,nn=m*v,k=abs(m)*C.he,a1=-nn-k,a2=-nn+k;
        float tN=max(max(a1.x,a1.y),a1.z),tF=min(min(a2.x,a2.y),a2.z);
        if(tN<tF&&tN>0.){tH=tN;lv=v;lw=w;lt=a1;hit=true;}
        if(mi&&C.ms>0.){
          // the popcorn cube is axis aligned and always in this column
          vec3 v2=ro-vec3(C.cen.x,C.mh,C.cen.z),w2=rd+vec3(1e-7)*step(abs(rd),vec3(1e-7));
          vec3 m2=1./w2,nn2=m2*v2,k2=abs(m2)*C.ms,b1=-nn2-k2,b2=-nn2+k2;
          float t2=max(max(b1.x,b1.y),b1.z),tf2=min(min(b2.x,b2.y),b2.z);
          if(t2<tf2&&t2>0.&&t2<tH){
            tH=t2;lv=v2;lw=w2;lt=b1;hit=true;
            C.cen=vec3(C.cen.x,C.mh,C.cen.z);C.he=vec3(C.ms);C.yaw=0.;C.th=0.;C.rs=1.;C.ax=0.;C.pil=0.;C.sel=1.;C.sp=-1.;
          }
        }
#if HD>=1
        // residents: small cubes standing on the top, each bouncing with its own band. They only exist where they are wider
        // than a couple of pixels and while their cube is not tumbling, so they never shimmer and never float.
        if(mi&&C.sp>=0.&&abs(sin(C.th))<.04&&C.pil<.5&&tc*kuPix<.05){
          float yw=C.yaw,cy2=cos(yw),sy3=sin(yw);
          for(int m=KU0;m<14;m++){
            if(m>=KU_NM+KU0)break;
            float mi=float(m),hm=fract(C.hc*7.13+mi*.618),aa=mi*2.39996+C.hc*6.,rr=C.he.x*(.25+.5*fract(mi*.381+hm));
            float sz=C.he.x*(.11+.09*hm),hop=(.5*kuBand(hm)+.9*kuArc((kuHatA-.05*mi)/.5))*sz*3.;
            vec2 oo=vec2(cos(aa),sin(aa))*rr;oo=vec2(oo.x*cy2-oo.y*sy3,oo.x*sy3+oo.y*cy2);
            vec3 ce=vec3(C.cen.x+oo.x,C.tp+sz+hop,C.cen.z+oo.y);
            vec3 v3=ro-ce,w3=rd+vec3(1e-7)*step(abs(rd),vec3(1e-7)),m3=1./w3,nn3=m3*v3,k3=abs(m3)*sz,c1=-nn3-k3,c2=-nn3+k3;
            float t3=max(max(c1.x,c1.y),c1.z),tf3=min(min(c2.x,c2.y),c2.z);
            if(t3<tf3&&t3>0.&&t3<tH){tH=t3;lv=v3;lw=w3;lt=c1;hit=true;C.cen=ce;C.he=vec3(sz);C.yaw=0.;C.th=0.;C.rs=1.;C.ax=0.;C.pil=0.;C.sel=0.;C.sp=-2.;C.ms=hm;}
          }
        }
#endif
#if HD>=2
        if(hit&&wi){li=kuLite(rd,C,cell,tH,lv,lw,lt,ln,ltp);}
#endif
        if(hit)break;
      }
      if(tM.x<tM.y){cell.x+=sg.x;tM.x+=ia.x;}else{cell.y+=sg.y;tM.y+=ia.y;}
      tc=tn;
    }
  }
  return hit;
}

// shade a hit: the whole character of a cube
vec3 kuSurf(vec3 ro,vec3 rd,KuC C,vec2 cell,float tH,vec3 lv,vec3 lw,vec3 lt,out vec3 nw,out float top){
  vec3 nl=-sign(lw)*step(lt.yzx,lt)*step(lt.zxy,lt),q=(lv+lw*tH)/C.he;
  nw=kuToWorld(nl,C);
  vec2 qc=(cell+.5)/kuSc;
  vec3 cA=kuCol(kuCA,qc),cB=kuCol(kuCB,qc);
  float pe=kuEase(C.p),hc2=h21(mod(cell,512.)*1.37+.7);
  vec3 fc;
  vec2 rv=C.ax<.5?vec2(C.rs,0.):vec2(0.,C.rs);
  float dn=dot(nl.xz,rv);
  // each cube is one colour at rest; while it rolls, the face coming up turns to the next picture first and the
  // old top last, so the field is fully repainted when it lands
  if(kuRoll<.5||C.pil>.01)fc=mix(cA,cB,pe);
  else fc=mix(cA,cB,nl.y>.5?smoothstep(.55,1.,C.p):(dn<-.5?smoothstep(0.,.3,C.p):pe));
  vec3 an=abs(nl);
  // v18: no two neighbours quite the same tone, and one cube in nine wears a stray ink, so a colour region is a mosaic
  {float iv=fract(hc2*17.3);fc*=.84+.3*iv;fc=mix(fc,kuInk(kuPalA,floor(fract(hc2*7.7)*5.)),step(fract(hc2*29.1),.11)*.92);}
  // v20: every snare sends a square ring of swapped colour racing out across the city (each cube inside it shows another of the palette's inks)
  {float sr=max(abs(cell.x+.5),abs(cell.y+.5))/kuSq,e=sr-kuSnA*16.;fc=mix(fc,kuInk(kuPalA,mod(floor(hc2*5.)+2.,5.))*1.12,exp(-e*e*.4)*smoothstep(1.2,.6,kuSnA)*step(kuSnA,1.2));}
  // v19 popcorn is a bright little cube in its parent's colour
  if(C.sp<0.)fc=C.sp<-1.5?kuInk(kuPalA,floor(C.ms*5.))*1.15:mix(fc,kuCream,.45)*1.25;
  vec2 uv=an.x>.5?q.zy:(an.y>.5?q.xz:q.xy);
  // tall pillars are drawn as stacks of cubes: an outline every cube height down from the top, darker lower down
  float dTop=(C.he.y-(lv.y+lw.y*tH))/C.he.x,tall=step(C.he.x*1.05,C.he.y)*step(an.y,.5)*C.pil;
  if(tall>.5)uv.y=mod(dTop,2.)-1.;
  float px=(tH+kuTr)*kuPix/(C.he.x*max(abs(dot(nw,rd)),.25)),fd=1.-smoothstep(.06,.2,px);
  float tone=(.4+.6*max(dot(nw,kuL),0.))/(.4+.6*max(kuL.y,.01));tone*=1.+.12*step(.5,nw.y);
  // sides lean toward the palette's ground hue as they turn away from the light
  vec3 base=fc*mix(vec3(1.),normalize(kuGnd+.02)*1.75,.34*(1.-tone))*min(tone,1.15)*mix(1.,.62+.38*exp(-dTop*.15),tall);
  top=step(.5,nw.y);
  float cb=max(abs(uv.x),abs(uv.y));
  // v18: paint the cube's character on it. Fades with the face's footprint, so far cubes stay calm and melt into their colour.
  if(C.sp>=0.){
    float sp=C.sp;
    float fid=an.y>.5?(nl.y>.5?1.:6.):(an.x>.5?(nl.x>.5?2.:5.):(nl.z>.5?3.:4.));
    float ipc=mod(floor(h21(mod(cell,512.)+5.5)*5.)+1.,5.);
    vec3 c2=kuInk(kuPalA,ipc),c3=kuInk(kuPalA,mod(ipc+2.,5.));
    if(length(c2-fc)<.12)c2=kuCream*.9;
    // v20: a tall tower is a stack of different storeys: each floor has its own dice, windows and residents, and every third floor is another kind of cube
    if(tall>.5){float fl=floor(dTop*.5);fid=mod(fid+fl,6.)+1.;if(mod(fl+floor(hc2*3.),3.)<.5)sp=mod(sp+1.+floor(hc2*7.),9.);}
    vec3 ar=kuArt(sp,uv,px,base,fc,c2,c3,kuCream,kuInk6,kuBand(C.bx),kuPopB(C.bx),hc2,fid,cell);
    float fa=1.-smoothstep(.16,.42,px);
    base=mix(base,ar*mix(min(tone,1.),1.,.55+.45*top),fa);
    // a real chamfer just inside the outline, lit from above, and the sides darken toward the floor (contact shade)
    float bev=smoothstep(.80,.88,cb)*(1.-smoothstep(.965,1.,cb));
    base*=1.+.34*bev*fa*(.45+.55*max(dot(nw,kuL),0.));
    // the air band makes every top bevel gleam (highs are a different, chrome channel from the mid twist)
    base+=kuCream*kuLine(abs(cb-.885),.030,px)*top*min(uB2.w,1.5)*.5;
    base*=mix(1.,mix(.66,1.,smoothstep(-.95,.25,uv.y)),(1.-top)*(1.-tall));
  }
  // light: the kick flashes the tops; every cube glows with its own band, its bevel flashes on that band's onsets,
  // and the chosen pop cubes light up white-hot on their band's hits
  float bl=kuBand(C.bx),bo=kuOnB(C.bx);
  base*=1.+top*(.28*uO1.x+.12*uB1.x)+(.1+.6*top)*bl*bl*min(kuSA,1.);
  base+=fc*kuLine(abs(cb-.8),.045,px)*fd*(.25+.9*bl+.8*bo)*(.4+.6*top);
  base=mix(base,kuCream*1.4,C.sel*top*min(bo,1.)*.45*fd);
  // hats: a sparkle cross on a scatter of tops (v12: a new scatter every sixteenth, twice as many, the top glows too)
  float sp2=step(h21(mod(cell,512.)*.71+(kuHatC+floor(kuPh*2.))*.123),.12)*top*max(uHat,uO2.z);
  base+=kuCream*sp2*kuLine(min(abs(uv.x),abs(uv.y))*(1.+cb*2.),.08,px)*2.5+fc*sp2*.35;
  // v12: and every hat rings the inset bevel of half the cubes (a different half each sixteenth), white-hot in their own colour
  float hb=uHat*step(.5,fract(h21(mod(cell,512.)*.53+2.1)+(kuHatC+floor(kuPh*2.))*.618));
  base=mix(base,fc*1.9+kuCream*.25,hb*kuLine(abs(cb-.8),.07,px)*fd*.9);
  // v13: hats also glaze the whole top of 40% of the cubes (a new 40% each sixteenth) with a glossy sheen in their own
  // colour; the air band runs a shimmer of light across the tops of the field, as wide as the air is loud
  float hE=max(.5*uHat,uO2.z)*step(.6,fract(h21(mod(cell,512.)*.37+7.3)+(kuHatC+floor(kuPh*2.))*.382));
  base=mix(base,base*1.35+fc*.4,top*hE*.7);
  float airS=max(uB2.w-.35,0.)*2.4,sw=.5+.5*sin(dot(cell,vec2(.23,.17))*1.3-kuPh*PI*.5);
  base+=(fc*.55+kuCream*.25)*top*airS*sw*sw*sw;
  // ink outline on every cube edge (a pixel wide at least; it greys into the fill when tiny)
  float ow=max(.065,px*1.1),ol=kuLine(1.-cb,ow,px)*mix(1.,.45,smoothstep(.15,.45,px));
  return mix(base,kuInk6,ol*mix(1.,.6,tall));
}

// the ground under a ray that found no cube: a soft shadow from the cube above, a pool of its colour, seams the bass lights
vec3 kuGrd(vec3 ro,vec3 rd,KuC C,vec2 cell,float tg){
  vec3 g=ro+rd*tg;
  vec2 gc=g.xz-floor(g.xz)-.5;
  vec2 dc=g.xz-C.cen.xz;
  float sh=0.;
  if(floor(g.xz)==cell){float hh=C.cen.y-C.he.y-KU_FLOOR,bl=.06+.05*hh,dd=max(abs(dc.x),abs(dc.y));sh=(1.-smoothstep(C.he.x-bl,C.he.x+bl,dd))*(.55/(1.+.12*hh));}
  float gpx=(tg+kuTr)*kuPix/max(abs(rd.y),.08);
  float dot0=kuLine(length(gc),.06,gpx)*(1.-smoothstep(.1,.3,gpx));
  vec3 pool=kuCol(kuCA,(floor(g.xz)+.5)/kuSc);
  float rg=length(g.xz),rw=kuRing(uP3.y,rg)+kuRing(uP3.z,rg)+kuRing(uP3.w,rg);
  vec2 ga=abs(gc);float seam=kuLine(.5-max(ga.x,ga.y),.03,gpx)*(1.-smoothstep(.12,.4,gpx));
  float inset=kuLine(abs(max(ga.x,ga.y)-.36),.012,gpx)*(1.-smoothstep(.08,.25,gpx));
  // the paving is inlaid: a mitred border on each tile, corner studs, and (closer) a fine diamond grain
  float gd1=kuD1(gpx),edge=max(ga.x,ga.y);
  inset+=gd1*(.6*kuLine(abs(edge-.42),.008,gpx)+kuLine(length(ga-.36),.03,gpx));
#if HD>=1
  {float gd2=kuD2(gpx);vec2 dg=abs(fract(vec2(gc.x+gc.y,gc.x-gc.y)*7.)-.5);
   inset+=gd2*.35*kuLine(abs(max(dg.x,dg.y)-.42),.02,gpx*7.);
#if HD>=2
   inset+=kuD3(gpx)*.3*step(length(fract(g.xz*24.)-.5),.14);
#endif
  }
#endif
  // v20: every paving tile is inlaid with an eight-point star (a square over a lozenge) with an ink rim; alternate stars answer alternate kicks
  float stK=mod(floor(g.x)+floor(g.z),2.),stD=min(max(ga.x,ga.y)-.2,(ga.x+ga.y)*.7071-.2),stF=kuLine(stD,0.,gpx)*gd1,stL=kuLine(abs(stD-.035),.012,gpx)*gd1;
  float stA=exp(-3.*(stK<.5?kuKA:kuKB));
  vec3 star=mix(kuInk(kuPalA,3.),pool,.45)*stF*(.16+.2*stK+.9*stA)+kuCream*stL*(.07+.25*stA);
  return star+(kuGnd*2.7+kuInk(kuPalA,4.)*.05+kuInk(kuPalA,1.)*.5*rw)*(1.+.55*uB1.x)*(1.-sh)+pool*(.16+.5*kuBass*kuBass)*exp(-3.2*dot(dc,dc))*(1.-.4*sh)+pool*.14*inset+kuCream*dot0*(.10+.4*uO1.x)+(kuInk(kuPalA,2.)*.22+pool*.25)*seam*(.35+.9*kuBass);
}
#if HD>=1
#if HD>=5
#define KU_NS 36
#define KU_NA 30
#define KU_NB 3
#elif HD>=4
#define KU_NS 20
#define KU_NA 16
#define KU_NB 2
#elif HD>=3
#define KU_NS 10
#define KU_NA 10
#define KU_NB 2
#elif HD>=2
#define KU_NS 10
#define KU_NA 12
#define KU_NB 1
#else
#define KU_NS 7
#define KU_NA 10
#define KU_NB 0
#endif
// sun direction samples, a tight golden-angle disc
vec3 kuJit(float i,float n,float rot){float a=i*2.39996+rot,r=sqrt((i+.5)/n)*.11;vec3 t=normalize(cross(kuL,vec3(.23,.97,.11))),b=cross(kuL,t);return normalize(kuL+(t*cos(a)+b*sin(a))*r);}
// occlusion directions over the hemisphere of n
vec3 kuHem(vec3 n,float i,float c,float rot){float a=i*2.39996+rot,r=sqrt((i+.5)/c);vec3 t=normalize(abs(n.y)<.9?cross(n,vec3(0.,1.,0.)):cross(n,vec3(1.,0.,0.))),b=cross(n,t);return normalize(n*(.35+.65*(1.-r))+(t*cos(a)+b*sin(a))*r);}
#endif
vec3 kuSky(vec3 rd){float hy=max(rd.y,0.);return mix(kuHor,kuGnd*1.4+kuInk(kuPalA,4.)*.25,smoothstep(0.,.35,hy));}

void realm(){
  kuPh=uP3.x;
  kuBass=uM2[0][0];kuLift=uM2[0][1];kuYaw=uM2[0][2];kuS=uM2[1][0];kuSc=uM2[1][2];kuK=uM2[2][0];kuHop=uM2[2][1];
  kuSq=sqrt(kuSc);kuRoll=0.;
  kuAct=floor(uM2[1][0])/1000.;kuS=fract(uM2[1][0]);
  kuSM=mod(uP5.z,4.);kuSA=floor(uP5.z/4.)/100.;
  {vec3 a=floor(uM1[0]*.25),b=floor(uM1[1]*.25);vec2 d=floor(uM1[2].xy*.25);
   kuB0=vec4(uM1[0]-4.*a,uM1[1].x-4.*b.x);kuB1=vec4(uM1[1].yz-4.*b.yz,uM1[2].xy-4.*d);
   kuP0=vec4(a,b.x)/250.;kuP1=vec4(b.yz,d)/250.;}
  // v19 event channels, see kubikFrame for the packing
  {float v=uP4.x;kuFA=mod(v,16.);v=floor(v/16.);kuHatA=mod(v,1024.)/200.;kuHatC=floor(v/1024.);
   v=uP4.y;kuFB=mod(v,16.);v=floor(v/16.);kuSnA=mod(v,1024.)/200.;kuSnC=floor(v/1024.);
   v=uP5.x;kuCA=mod(v,64.);v=floor(v/64.);kuDA=mod(v,1024.)/100.;kuDS=floor(v/1024.);
   v=uP5.y;kuCB=mod(v,64.);v=floor(v/64.);kuKC=mod(v,64.);v=floor(v/64.);kuActI=mod(v,16.);kuPat=floor(v/16.);
   v=uP5.w;kuCT=mod(v,32.);v=floor(v/32.);kuCrA=mod(v,256.)/128.;v=floor(v/256.);kuCr=vec2(floor(v/32.),mod(v,32.))-16.;
   v=uM2[1][1];kuKA=floor(v/1024.)/200.;kuKB=mod(v,1024.)/200.;
   kuActW=floor(uM1[2][2]/512.)/63.;kuBW=floor(uM2[2][2]/512.)/63.;}
  kuRoll=step(15.5,kuCT);
  {float p5=mod(kuPat,5.);kuPatV=p5<.5?vec2(1.,1.):(p5<1.5?vec2(0.,1.):(p5<2.5?vec2(1.,0.):(p5<3.5?vec2(.5,.5):vec2(.25,.5))));}
  {float k=floor(kuPh*2.)+kuBack(fract(kuPh*2.)/.5);kuArm=vec2(cos(k*TAU/16.),sin(k*TAU/16.));}
  // the routine's parameters: 1 sequencer, 6 block party, 7 row leaps are the same running leap with different numbers
  {float ai=kuActI;kuLV=mod(kuPat,2.)<.5?vec2(1.,0.):vec2(0.,1.);
   kuLM=16.;kuLR=2.;kuLD=1.7;kuLMir=0.;kuLBl=0.;kuLA=1.2;kuLB=3.8;kuLW=0.;kuWP=0.;kuWS=0.;kuWA=0.;kuWC=0.;kuWG=0.;
   if(ai<1.5){kuLW=step(.5,ai);kuLR=4.;kuLD=2.2;}
   else if(ai<2.5)kuWP=1.;
   else if(ai<3.5)kuWS=1.;
   else if(ai<4.5)kuWA=1.;
   else if(ai<5.5)kuWC=1.;
   else if(ai<6.5){kuLW=1.;kuLBl=1.;kuLA=2.9;kuLB=1.7;}
   else if(ai<7.5){kuLW=1.;kuLMir=1.;kuLD=1.5;kuLA=1.5;kuLB=2.6;}
   else kuWG=1.;}
  // v19: formation waves take a hard step on each beat, so the field punches instead of swaying
  kuTk=mix(kuPh,floor(kuPh)+kuBack(fract(kuPh)/.42),.72);
  kuMid=kuBand(.45);kuMi=kuPopB(.42);kuAi=kuPopB(.9);kuSu=kuPopB(.05);kuPr=kuPopB(.62);
  float dI=mod(floor(kuCT/4.),4.);
  kuDir=dI<.5?vec2(1.,0.):(dI<1.5?vec2(-1.,0.):(dI<2.5?vec2(0.,1.):vec2(0.,-1.)));
  vec2 p=scr();
  vec3 ro=uP1.xyz,ta=uP2.xyz,fw=normalize(ta-ro),rt=normalize(cross(fw,vec3(0,1,0))),up=cross(rt,fw);
  float cr=cos(uP2.w),sr=sin(uP2.w);
  vec3 rt2=rt*cr+up*sr;up=up*cr-rt*sr;
  vec3 rd=normalize(p.x*rt2+p.y*up+uP1.w*fw);
  kuPix=1./(uRes.y*uP1.w);kuCamY=ro.y;kuRo=ro;
  kuPalA=floor(kuCA/8.);
  kuGnd=kuInk(kuPalA,5.);kuInk6=kuInk(kuPalA,6.);kuCream=kuInk(kuPalA,7.);
  // light from the upper left of the view, so the two visible sides always read as two tones
  kuL=normalize(-rt*.55+vec3(0,1.,0)-fw*.25);
  kuHor=mix(kuInk(kuPalA,0.),kuCream,.25)*(1.1+.5*uB1.x);
  float wow=max(max(kuIsPil(kuFA)*step(6.5,kuFA),kuIsPil(kuFB)*step(6.5,kuFB)),max(kuIsCl(kuFA),kuIsCl(kuFB)));
  float pz=pow(kuSc,.75);
  kuYT=(4.8+kuSA*3.6+2.4+wow*13.*(1.+1.4*kuLift))*pz+6.5+5.*kuLift+1.6*kuHop+3.*kuPopB(.3);
  // v19: head room for the leaps; the drop blast only claims it while it flies
  kuYT+=(3.9+5.5*kuActW+.9*kuBW)*pz;
  kuYT=max(kuYT,kuDA<7.9?min(kuYT+22.*pz,ro.y+2.):0.);
  float N=60.+50.*uDetail;
  KuC C;vec2 cell;float tH,steps;vec3 lv,lw,lt;
  vec3 u1,u2;float u3;
  bool hit=kuTrace(ro,rd,1e5,N,C,cell,tH,lv,lw,lt,steps,false,u1,u2,u3,true,false);
  vec3 col=kuSky(rd);
  float tEnd=-1.,fn=1.;
  vec3 avg=mix(kuCol(kuCA,(cell+.5)/kuSc),kuGnd,.22)*(.8+.42*fract(h21(mod(cell,512.)*1.37+.7)*17.3));
  vec3 nw=vec3(0.,1.,0.);float top=1.;
  if(hit){
    col=kuSurf(ro,rd,C,cell,tH,lv,lw,lt,nw,top);
    tEnd=tH;fn=max(abs(dot(nw,rd)),.15);
  }else if(rd.y<0.){
    float tg=(KU_FLOOR-ro.y)/rd.y;
    col=kuGrd(ro,rd,C,cell,tg);
    tEnd=tg;fn=max(abs(rd.y),.15);
  }
#if HD>=1
  // v19 detail range: real light. Shadow, occlusion and reflection rays share one call of kuTrace, in its light form: the
  // cubes at their dance heights but unrotated (a lit edge cannot tell), with no routines to compile a second time.
  // A surface is committed once its shadow and occlusion rays are in, then its reflection ray (if any) brings the next one.
  if(tEnd>0.&&tEnd*kuPix/fn<.6){
    vec3 acc=vec3(0.),Cs=col,Nn=hit?nw:vec3(0.,1.,0.),Pp=ro+rd*tEnd,Vv=rd;
    float Tt=1.,vis=0.,ao=0.,tr0=tEnd,rot=HD>=3?fract(dot(gl_FragCoord.xy,vec2(.7549,.5698)))*TAU:0.;
    float kr=hit?top*(.07+.5*pow(1.-max(dot(nw,-rd),0.),5.)):(.16+.6*pow(1.-max(-rd.y,0.),5.));
    vec3 shd=mix(vec3(.74),normalize(kuGnd+.02)*1.25,.35);
    int nu=KU0,bn=KU0;
    float NFs=min(N,50.+25.*uDetail),NFr=max(60.,N*.45);
    for(int j=KU0;j<300;j++){
      int ty;vec3 dd;float tM=1e5,NF=NFs;
      if(nu>=KU_NS+KU_NA){
        acc+=Tt*Cs*mix(shd,vec3(1.),vis/float(KU_NS))*mix(.76,1.,ao/max(float(KU_NA),1.));
        if(bn>=KU_NB||kr<.01){Tt=0.;break;}
        ty=1;dd=reflect(Vv,Nn);NF=NFr;
      }else if(nu<KU_NS){ty=0;dd=kuJit(float(nu),float(KU_NS),rot);}
      else{ty=2;dd=kuHem(Nn,float(nu-KU_NS),float(KU_NA),rot);tM=2.5;}
      if(ty!=1&&dot(dd,Nn)<=0.){
        // below the surface: this face's own tone already says it is turned from the light, so it counts as unshadowed
        if(ty==0)vis+=1.;else ao+=1.;
        nu++;
      }else{
        KuC Ci;vec2 cei;float tHi,sti;vec3 lvi,lwi,lti,lci,lni;float lpi;
        vec3 org=Pp+Nn*.016;
        bool hi=kuTrace(org,dd,tM,NF,Ci,cei,tHi,lvi,lwi,lti,sti,ty==1,lci,lni,lpi,false,true);
        if(ty==0){vis+=hi?0.:1.;nu++;}
        else if(ty==2){ao+=hi?0.:1.;nu++;}
        else{
#if HD>=2
          Tt*=kr;vis=0.;ao=0.;nu=KU0;bn++;Vv=dd;
          if(hi){Cs=lci;Pp=org+dd*tHi;Nn=lni;tr0+=tHi;kr=lpi*(.07+.5*pow(1.-max(dot(lni,-dd),0.),5.));}
          else if(dd.y<0.){float tg=(KU_FLOOR-org.y)/dd.y;Cs=kuGnd*2.7+kuCol(kuCA,(cei+.5)/kuSc)*.22;Pp=org+dd*tg;Nn=vec3(0.,1.,0.);tr0+=tg;kr=.16+.6*pow(1.-max(-dd.y,0.),5.);}
          else{Cs=kuSky(dd);nu=KU_NS+KU_NA;kr=0.;vis=float(KU_NS);ao=float(KU_NA);}
#endif
        }
      }
    }
    col=acc;
  }
#endif
  if(tEnd>0.){
    // far cubes a few pixels wide melt into the picture's colour; distance haze toward the horizon light
    float fp=tEnd*kuPix/fn;
    // v12: far cubes melt into the picture's colour, but the music keeps playing on that giant mosaic: kick ripples
    // run out across it as bright rings, every cell glows with its band, and hats glitter single cells cream
    vec2 fcl=hit?cell:floor((ro+rd*tEnd).xz);
    float rgF=length(fcl+.5),rwF=kuRing(uP3.y,rgF)+kuRing(uP3.z,rgF)+kuRing(uP3.w,rgF);
    float blF=hit?kuBand(C.bx):0.,spF=step(h21(mod(fcl,512.)*.71+(kuHatC+floor(kuPh*2.))*.123),.07)*max(uHat,uO2.z);
    col=mix(col,avg*(1.+1.1*rwF+.8*blF*blF*min(kuSA,1.)+.35*uO1.x)+avg*spF*1.4,smoothstep(.12,.45,fp)*.8);
    col=mix(col,kuHor*.8,(1.-exp(-tEnd*.006/kuSq))*.6*smoothstep(.9,.3,abs(rd.y)));
  }
  if(steps>=N-.5&&!hit)col=mix(avg,kuHor*.8,.4);
  // a touch more chroma before the tone map keeps the inks as saturated as the flat colours they are
  col=max(mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.32),0.)*(1.62+.35*uDrop);
  fragColor=vec4(kuHueRot(max(col,0.)),0.);
}
`;
