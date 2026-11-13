const R_KAMI = `
const float KPL[168]=float[168](16737070.,16754015.,16774113.,16629152.,16773848.,2827368.,16398624.,1778010.,2326125.,16737568.,14170657.,16508099.,1645646.,4444073.,5755569.,1535841.,16511196.,12574158.,16773848.,2698094.,11241713.,8473566.,13283578.,13215226.,9989355.,16773860.,3022191.,16746283.,16607130.,16756681.,16774135.,16299468.,16773848.,3415636.,16134506.,2299987.,8337815.,16757028.,15559708.,16773322.,1839942.,16738473.,2080460.,1335681.,16774886.,12314088.,16773848.,2175077.,16746677.,3751595.,9938941.,10204927.,6387439.,16773622.,1776996.,16761143.,16757785.,16769131.,16777203.,16636311.,16773848.,3940445.,16732974.,540057.,2518247.,16732961.,15348506.,16771275.,533601.,16765476.,16738464.,13841274.,16774120.,16761814.,16773848.,5118306.,2806271.,637050.,9696454.,13828072.,7789999.,16777200.,609599.,16746012.,230281.,3389609.,15794168.,10018000.,16773848.,470845.,16737617.,2886978.,7415412.,16746029.,14700579.,16770492.,1771822.,3205306.,15773498.,11560977.,16775139.,16177057.,16773848.,3941662.,9525238.,13580654.,16684472.,16760792.,15492249.,16773617.,5181233.,3071446.,5487615.,12708351.,16773848.,13427711.,16773848.,2371443.,16738473.,16733819.,16751280.,16767285.,16555798.,16774865.,7474498.,6965247.,10914047.,14141183.,16774399.,14864895.,16773848.,3874955.,16756263.,3136946.,10549729.,15728632.,9824975.,16773848.,545354.,16733819.,16075807.,16748110.,16773338.,16429703.,16773848.,4068914.,16765220.,1261877.,2457174.,16750363.,15097373.,16771264.,796448.,16732974.,16367932.,13732123.,16774879.,15651740.,16773848.,5122331.,3515239.,6236021.,10969792.,14394871.,10774231.,16773076.,2886714.,16746029.);

const vec4 KMS[68]=vec4[68](vec4(8424602.,9217247.,9211148.,262400.),vec4(6584880.,7080197.,8421377.,459008.),vec4(6195800.,8132770.,5932052.,131584.),vec4(5146786.,8813726.,8421376.,8.),vec4(5146786.,8813164.,8421376.,8.),vec4(9733840.,11413528.,9995545.,66048.),vec4(14004788.,2654336.,9995546.,328192.),vec4(14333660.,11400879.,9995544.,459776.),vec4(13744398.,950400.,9995546.,459776.),vec4(6327442.,9195236.,8031492.,196608.),vec4(9604174.,14977742.,8031492.,196608.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(10779824.,4988428.,10779657.,262400.),vec4(5799482.,5382668.,5799441.,262400.),vec4(3447724.,4511360.,5410326.,131072.),vec4(1746504.,3462784.,5410358.,524800.),vec4(8161224.,5801088.,8421378.,0.),vec4(10780760.,5275776.,8421378.,66048.),vec4(5667920.,3965056.,5931022.,196608.),vec4(5667888.,5512204.,5931021.,196608.),vec4(11041996.,5381132.,11041797.,196608.),vec4(11443902.,10793680.,11179032.,393478.),vec4(12362448.,10537428.,11179032.,393222.),vec4(12691148.,10864838.,11179032.,590336.),vec4(11053804.,9222264.,11179032.,327700.),vec4(12357618.,9222258.,11179064.,459276.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(11707038.,14556180.,11704857.,393472.),vec4(10385578.,5645848.,10385417.,262400.),vec4(6718616.,8421504.,8421378.,131072.),vec4(9210000.,6326400.,8421378.,0.),vec4(10912324.,4751488.,8421378.,66048.),vec4(6451242.,6435360.,6451213.,262400.),vec4(4297260.,2916480.,8421378.,524800.),vec4(10648250.,5776920.,10648069.,196608.),vec4(12622436.,4749184.,11704858.,328192.),vec4(12363442.,14949908.,11704857.,393728.),vec4(12365491.,14487049.,11704857.,590848.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(10010802.,8363728.,3379128.,197640.),vec4(13248169.,8399401.,2339423.,197898.),vec4(3830136.,12246194.,6902376.,197128.),vec4(16653675.,11782100.,3905792.,197392.),vec4(9082530.,10002136.,9869324.,262400.),vec4(6063638.,10360940.,5669396.,131328.),vec4(9070226.,5377032.,8421377.,459776.),vec4(8290512.,8160384.,8421378.,0.),vec4(10650208.,6324352.,8421378.,66048.),vec4(12361282.,4358272.,11572762.,328192.),vec4(13148873.,10082973.,11572760.,459776.),vec4(5936274.,9853156.,7902724.,196608.),vec4(9606744.,14979280.,7902724.,196608.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.),vec4(0.,0.,3.,0.));

// KAMI 9: a papercraft procession. Origami cranes, foxes, hares and doves stream through diagonal paper bands
// (each band a strip of coloured paper laid over the one above it, with a scalloped deckle edge that pulses with that
// band's slice of the spectrum). Every animal is folded paper: angular parts split into fan facets, each lit by its
// own tilt (light / shadow per facet), with ink creases; facets hold flower mosaics, feather veins and smaller animals
// (animals inside animals); heads stay smooth cream with a face.
// Bands: crane = highs/air (wing flaps), fox = mids (gallop), hare = kick + low-mids (hop), dove = bass (swell, beat).
// uP1 [trav, mt, kick env, snare fold wave]      uP2 [route A, route B, wipe, palette blend]
// uP3 [palette A, palette B, build, breakdown]   uP4 [event+progress, hero progress, hero type, drop flash]
// uP5 band travel per type (crane, fox, hare, dove)
// uM1 [phase crane, fox, hare | dove, env crane, env fox | env hare, env dove, fold]
// uM2 [hop height, sparkle spin, type shift | direction, hat twinkle, confetti | flip, mandala, unfold]
const vec3 KMINK=vec3(.010,.008,.030);
// v20 detail scale: close-up ornament appears by pixel footprint; Native and up resolve it sooner (KZ, KY, KW widen the gates)
#if HD>=1
#define KZ 2.
#define KY 1.5
#define KW 4.
#else
#define KZ 1.
#define KY 1.
#define KW 1.
#endif
vec2 kmF6(vec2 p){p=abs(p);const vec2 k=vec2(-.8660254,.5);p-=2.*min(dot(k,p),0.)*k;return p;}
vec4 kmH(vec2 id,float s){return fract(sin(vec4(dot(id,vec2(127.1,311.7)),dot(id,vec2(269.5,183.3)),dot(id,vec2(419.2,371.9)),dot(id,vec2(113.5,271.9)))+s*7.31)*43758.545);}
int kmPid=0;
// palette colour; near-white paper (creams) is lifted into HDR so it reaches the screen as warm cream, not grey
vec3 kmP(float b,float k){int v=int(KPL[kmPid*28+int(b)*7+int(k)]);vec3 c=vec3(ivec3(v>>16,v>>8,v)&255)*(.97/255.);
  return c*(1.+1.1*smoothstep(.55,.92,min(min(c.r,c.g),c.b)));}
vec4 kmOh(float t){return vec4(equal(vec4(t),vec4(0.,1.,2.,3.)));}
float kmA(float d,float e){return clamp(.5-d/e,0.,1.);}
float kmBloom(vec2 p,float r){p=abs(p);const vec2 k=vec2(-.8660254,.5);p-=2.*min(dot(k,p),0.)*k;return length(p-vec2(0.,r*.6))-r*.42;}
float kmLeaf(vec2 p,float r,float d){p=abs(p);float b=sqrt(r*r-d*d);return ((p.y-b)*d>p.x*b)?length(p-vec2(0.,b)):length(p-vec2(-d,0.))-r;}
// gait tables per type: group amplitudes (near limb / wing, far limb / wing, tail, head), phase offsets, frequency
const mat4 KGA=mat4(.62,.55,.12,.10,.62,.62,.22,.07,.55,-.70,.12,.20,.66,.55,.16,.08);
const mat4 KGO=mat4(0.,.08,.2,.35,0.,.38,.13,0.,0.,0.,.1,.17,0.,.05,.18,0.);
const mat4 KGF=mat4(1.,1.,1.,1.,1.,1.,1.,2.,1.,1.,1.,1.,1.,1.,1.,2.);
float kmTri(vec2 p,vec2 p0,vec2 p1,vec2 p2){
  vec2 e0=p1-p0,e1=p2-p1,e2=p0-p2,v0=p-p0,v1=p-p1,v2=p-p2;
  vec2 q0=v0-e0*clamp(dot(v0,e0)/max(dot(e0,e0),1e-9),0.,1.);
  vec2 q1=v1-e1*clamp(dot(v1,e1)/max(dot(e1,e1),1e-9),0.,1.);
  vec2 q2=v2-e2*clamp(dot(v2,e2)/max(dot(e2,e2),1e-9),0.,1.);
  float s=step(0.,e0.x*e2.y-e0.y*e2.x)*2.-1.;
  vec2 d=min(min(vec2(dot(q0,q0),s*(v0.x*e0.y-v0.y*e0.x)),vec2(dot(q1,q1),s*(v1.x*e1.y-v1.y*e1.x))),vec2(dot(q2,q2),s*(v2.x*e2.y-v2.y*e2.x)));
  return -sqrt(d.x)*(step(0.,d.y)*2.-1.);
}
float kmEl(vec2 p,vec2 r){float k0=length(p/r),k1=length(p/(r*r));return k0*(k0-1.)/max(k1,1e-5);}
// folded-paper body: a hexagon pointed along x (front / back tips, flat top and belly) in the part's ellipse frame
float kmHex(vec2 p){const vec3 k=vec3(-.8660254,.5,.5773503);p=abs(p);p-=2.*min(dot(k.xy,p),0.)*k.xy;p-=vec2(clamp(p.x,-k.z*.88,k.z*.88),.88);return length(p)*sign(p.y);}
// tapered capsule from a (radius ra) to b (radius rb)
float kmCap(vec2 p,vec2 a,vec2 b,float ra,float rb){
  vec2 ax=b-a;float h=max(length(ax),1e-4);ax/=h;p-=a;p=vec2(abs(dot(p,vec2(-ax.y,ax.x))),dot(p,ax));
  float bb=(ra-rb)/h,aa=sqrt(max(1.-bb*bb,0.)),k=dot(p,vec2(-bb,aa));
  return mix(mix(dot(p,vec2(aa,bb))-ra,length(p-vec2(0.,h))-rb,step(aa*h,k)),length(p)-ra,step(k,0.));
}
// painter accumulation: x union distance, y top part, w its tone; tc = part centre, part-local pixel
void kmPut(inout vec4 r,inout vec4 tc,float d,float id,float tone,vec2 cen,vec2 lq){if(d<0.){r.yzw=vec3(id,-d,tone);tc=vec4(cen,lq);}r.x=min(r.x,d);}
// one origami animal (0 crane, 1 fox, 2 hare, 3 dove), facing +x, about 2.2 x 1.6 units, from a few clean shapes:
// paper parts are angular (triangles, tapered capsules, hexagon bodies), the head is a smooth cream oval.
// Parts: 0 body, 1 chest / neck, 2 tail / haunch, 3 near limb or wing, 4 far limb or wing, 5 head, 6 ear,
// 7 muzzle / beak / legs, 8 tail tip, 9 inner ear. Returns x union distance, y part, w tone (0 main, 1 shade,
// 2 cream, 3 dark, 4 accent).
vec4 kmAnim(vec2 q,int ty,vec4 ga,float pw,out vec4 tc,float mx){
  vec4 r=vec4(1e3,-1.,0.,0.);tc=vec4(0.,0.,q);
  mat2 Mx=rot(-ga.x),Mxn=rot(ga.x),My=rot(-ga.y),Myn=rot(ga.y),Mz=rot(-ga.z),Mw=rot(-ga.w);
  float dp=1e3;int n=16+int(min(uZoom,0.))+int(min(1.,mx));
  for(int k=0;k<n;k++){
    vec4 P=KMS[ty*16+k];
    ivec3 i0=ivec3(int(P.x))>>ivec3(16,8,0)&255,i1=ivec3(int(P.y))>>ivec3(16,8,0)&255,i2=ivec3(int(P.z))>>ivec3(16,8,0)&255,i3=ivec3(int(P.w))>>ivec3(16,8,0)&255;
    int st=i2.z&3,gr=(i2.z>>2)&7;if(st==3)break;
    vec2 A=vec2(i0.xy-128)*.01,B=vec2(ivec2(i0.z,i1.x)-128)*.01,C=vec2(i1.yz-128)*.01,pv=vec2(i2.xy-128)*.01;
    mat2 M=gr==1?Mx:(gr==2?Mxn:(gr==3?My:(gr==4?Myn:(gr==5?Mz:(gr==6?Mw:mat2(1.))))));
    vec2 lq=pv+M*(q-pv),cen=A;float d;
    if(st==0){d=kmTri(lq,A,B,C);cen=(A+B+C)/3.;}
    else if(st==1){d=kmCap(lq,A,B,max(float(i1.y)*.0025,pw),max(float(i1.z)*.0025,pw*.85));cen=(A+B)*.5;}
    else{vec2 e=rot(-C.x*PI)*(lq-A),rr=vec2(ivec2(i0.z,i1.x))*.0025;d=i3.x==5?kmEl(e,rr):kmHex(e/rr)*min(rr.x,rr.y);}
    d-=float(i3.z)*.0025;d=mix(d,max(d,dp),float((i2.z>>5)&1));dp=d;
    kmPut(r,tc,d,float(i3.x),float(i3.y),cen,lq);
  }
  return r;
}
// band coordinates for route rid (0 diagonal, 1 river, 2 chevron, 3 spiral, 4 rings, 5 sunburst), variant vs.
// returns (u along, v across, J = band units per world unit), all in band widths
vec3 kmRoute(vec2 p,float rid,float vs,float W,float mt){
  float an=mix(.17,.36,fract(vs*7.13)),sg=step(.3,fract(vs*3.71))*2.-1.;
  vec2 d=vec2(cos(an),sg*sin(an)),n=vec2(-d.y,d.x);
  float u=dot(p,d),v=dot(p,n);
  v+=mix(.035,.17,step(.5,rid))*step(rid,1.5)*sin(u*mix(2.3,1.55,step(.5,rid))/W*.3+mt*.12+vs*6.)*W/.3;
  vec2 cv=vec2(p.x,p.y-mix(.42,.62,fract(vs*5.3))*sqrt(p.x*p.x+.02)+.12);
  float ch=step(1.5,rid)*step(rid,2.5);u=mix(u,cv.x,ch);v=mix(v,cv.y,ch);
  float J=1./W;
  if(rid>2.5){
    float f=step(.5,fract(vs*2.9)),Nc=mix(mix(3.,8.,step(3.5,rid)),0.,step(4.5,rid))+f*mix(1.,2.,step(3.5,rid))*step(rid,4.5);
    float mc=mix(1.,3.,step(4.5,rid))*(1.-step(3.5,rid)*step(rid,4.5));
    float A=Nc*2.4/TAU,B=4.*mc/TAU;
    float r=max(length(p),1e-4),L=log(r),a=atan(p.y,p.x)+mt*.01;
    u=B*L+A*a;v=-A*L+B*a+.5;J=length(vec2(A,B))/r;
    return vec3(u,v,J);
  }
  return vec3(u/W,v/W,J);
}
// v20 wagara: the classic printed papers as regular lattices (one cell = 1), each returned as the distance to its ink:
// 0 asanoha (hemp-leaf stars), 1 shippo (linked circles), 2 kikko (tortoise-shell hexagons with a seed at every corner),
// 3 tatewaku (rising steam: paired wavy lines), 4 uroko (scales: alternate triangles filled), 5 yagasuri (arrow feathers)
float kmSeg(vec2 p,vec2 b){return length(p-b*clamp(dot(p,b)/dot(b,b),0.,1.));}
float kmWag(vec2 q,float k,float lw){
  if(k<2.5||(k>3.5&&k<4.5)){
    if(k>.5&&k<1.5)return min(abs(length(fract(q)-.5)-.5),abs(length(fract(q+.5)-.5)-.5))-lw;
    // triangular lattice (side 1): skew coordinates, which half of the rhombus, offset from that triangle's centroid
    vec2 sk=vec2(q.x-q.y*.57735,q.y*1.1547),f=fract(sk);float up=step(1.,f.x+f.y);
    vec2 d=f-mix(vec2(1./3.),vec2(2./3.),up);d=vec2(d.x+d.y*.5,d.y*.8660254)*(1.-2.*up);d.x=abs(d.x);
    float de=.288675-max(-d.y,.8660254*d.x+.5*d.y);
    if(k<.5)return min(de,min(kmSeg(d,vec2(.5,-.288675)),kmSeg(d,vec2(0.,.57735))))-lw;
    if(k>3.5)return mix(lw-de,de+lw,up);
    return min(min(kmSeg(d,vec2(0.,-.288675)),kmSeg(d,vec2(.25,.144338)))-lw,min(length(d-vec2(.5,-.288675)),length(d-vec2(0.,.57735)))-.13);
  }
  if(k<3.5){float i=floor(q.x+.5);return abs(q.x-i-.2*sin(PI*q.y)*(mod(i,2.)*2.-1.))*.85-lw;}
  float sx=fract(q.x)-.5,v=q.y+abs(sx)*1.2*(mod(floor(q.x),2.)*2.-1.);
  return min((abs(fract(v)-.25)-.25)*.6,abs(sx)-lw);
}
#if HD>=1
// V19 DETAIL RANGE (Native and up; HD 0 never sees any of this)
// chiyogami printing: octaves of small motifs (scattered blossoms, asanoha stars, seigaiha scales) that double in frequency and
// appear only when each cell is several pixels wide; coloured ink only, coverage capped, cells missing at random, rotated per octave
vec3 kmPrint(vec3 col,vec2 q,float pq,float sd,vec3 a1,vec3 a2,float amt){
  int nO=1+HD+int(min(uZoom,0.));
  for(int o=int(min(uZoom,0.));o<nO;o++){
    float fo=float(o),so=16.*pow(2.,fo),fad=smoothstep(3.,7.5,1./(so*pq));
    if(fad<.004)break;
    vec2 g=rot(.73*fo+sd*5.)*q*so;g.x+=.5*mod(floor(g.y),2.);
    vec2 id=floor(g),f=fract(g)-.5;float hh=h21(id+fo*19.+sd*83.),m3=mod(fo,3.);
    float d=mix(mix(kmBloom(f,.34),abs(length(f)-.34)-.06,step(.5,m3)),max(abs(f.x)+abs(f.y)-.3,-max(abs(f.x),abs(f.y))+.12),step(1.5,m3))/so;
    col=mix(col,mix(a1,a2,step(.5,fract(hh*5.+fo*.5))),kmA(d,pq)*fad*step(hh,.7)*amt*(.85-.08*fo));
  }
  return col;
}
#endif
void realm(){
  vec2 p0=scr();
  float tr=uP1.x,mt=uP1.y,kick=uP1.z,bld=uP3.z,brk=uP3.w,dfl=uP4.w,swv=uP1.w;
  float ev=floor(uP4.x),evp=fract(uP4.x);
  float zm=uZoom*(1.+.05*bld);
  vec2 p=p0/zm;float px=1./(uRes.y*zm);
  // ---- route wipe: a diagonal page-turn crease sweeps across; behind it the new route
  float wp=uP2.z,sd=dot(p0,vec2(.93,.37))+.2*sin(p0.y*5.+wp*3.),fr=wp*2.4-1.25,useB=step(sd,fr)*step(wp,1.59);
  float RR=mix(uP2.x,uP2.y,useB),rid=floor(RR),vs=fract(RR);
  float sdP=dot(p0,vec2(-.9,.42))+.035*sin(p0.x*7.-p0.y*3.),frP=uP2.w*2.7-1.35;
  kmPid=int(mix(uP3.x,uP3.y,step(sdP,frP)));
  // zoomed out, the bands widen (in world units) faster than the view shrinks them: more bands and many more animals
  // fill the frame while every animal stays big enough to read
  float W=mix(.27,.36,fract(vs*5.31))*pow(min(zm,1.),-.48)*pow(max(zm,1.),-.22);
  // bass: the whole sheet of paper rolls, a slow travelling swell whose height is the smoothed bass envelope
  {float bph=uM1[1].x*TAU*.5,ba=.006+.026*uM1[2].y;p+=ba*vec2(sin(p0.y*3.1+bph),sin(p0.x*2.7-bph*.8))/zm;}
  vec3 rt=kmRoute(p,rid,vs,W,mt);
  float u=rt.x,v=rt.y,pxb=px*rt.z,spir=step(2.5,rid);
  float f2=step(.5,fract(vs*2.9)),Nc=mix(mix(3.,8.,step(3.5,rid)),0.,step(4.5,rid))+f2*mix(1.,2.,step(3.5,rid))*step(rid,4.5);
  float mc=mix(1.,3.,step(4.5,rid))*(1.-step(3.5,rid)*step(rid,4.5));
  float perA=mix(240.,Nc,spir*step(.5,Nc)),perD=perA*4.,perBand=mix(256.,4.*mc,spir*step(.5,mc));
  float tsh=uM2[0].z,dirS=uM2[1].x;
  vec4 envs=vec4(uM1[1].y,uM1[1].z,uM1[2].x,uM1[2].y);
  vec4 ons=vec4(max(uO2.z,uO2.w),max(uO1.w,uO2.x),max(uO1.z,kick*.6),max(uO1.x,uO1.y));
  // ---- which band: the band below is in front; its top edge is a scalloped deckle that rises with its band's
  // envelope (bump to bump variation = its slice of the spectrum, in light)
  float b=floor(v),fv=v-b;
  float tyB=mod(tsh-b+1.,4.);
  vec4 ohB=kmOh(tyB);
  float flo=dot(ohB,vec4(.70,.45,.24,.0)),fhi=dot(ohB,vec4(1.,.70,.45,.24));
  float uS=u*2.6,cS=floor(uS),xS=fract(uS)*2.-1.;
  float fq=mix(flo,fhi,abs(fract(cS/24.)*2.-1.)),sq0=spec(fq);
  float sn=step(0.,swv)*exp(-max(swv,0.)*5.);
  float bmp=(.03+.15*dot(ohB,envs)*(.6+.4*fract(cS*.618))+.05*sn)*sqrt(max(1.-xS*xS,0.));
  float rimB=0.;
  if(fv<bmp){b-=1.;fv+=1.;rimB=1.;}
  float ty=mod(tsh-b,4.);
  vec4 oh=kmOh(ty);
  float pos=dot(oh,uP5),env=dot(oh,envs);
  float bandOn=dot(oh,ons);
  float bH=mod(b,perBand);
  // ---- band paper: colour, soft light, fibres
  vec3 bg=kmP(ty,0.),dc=kmP(ty,1.),cLt=kmP(ty,4.),cDk=kmP(ty,5.),cAc=kmP(ty,6.);
  float pxl=pxb,dlod=smoothstep(.05,.015,pxl);
  float zo=smoothstep(.0036*KZ,.0026*KZ,pxl);
  vec3 col=bg*(1.1-.1*fv+.1*bandOn);
  col*=1.+.05*(vnoise(vec2(u,fv)*38.)-.5)*smoothstep(.03,.012,pxl);
  // washi detail, static in band coordinates (it never shimmers): the strip is pleated (alternate light / shade
  // panels between soft creases), and zooming in shows a faint printed kanoko pattern
  float zd=smoothstep(.013,.005,pxl);
  {float pu=u*.5+.42*fv+.3*b,pf=fract(pu),pd=min(pf,1.-pf)/.5;float side=step(.5,fract(pu*.5));
   col*=1.+.065*(side*2.-1.)*smoothstep(0.,.08,abs(pf-.5)*2.)-.09*kmA(abs(pf-.5)*2.-.006,pxl*3.)*side+.08*kmA(abs(pf-.5)*2.-.006,pxl*3.)*(1.-side);
   vec2 kq=vec2(u*7.+.5*mod(floor(fv*7.),2.),fv*7.),kg=fract(kq)-.5;
   float hbW=fract(bH*.37+ty*.21+.11);
#if HD>=1
   float wgt=zo;
#else
   float wgt=zd*smoothstep(1.05,1.7,zm);
#endif
   col=mix(col,mix(col,dc,.55),wgt*.5*kmA(abs(length(kg)-.26)-.06,pxl*7.)*step(hbW,.4));
   // v20: the other bands are printed with a wagara of their own
   if(hbW>.4&&wgt>.003)col=mix(col,mix(col,dc,.55),wgt*.5*kmA(kmWag(vec2(u,fv)*10.,floor((hbW-.4)*9.999),.035)*.1,pxl));}
  // seigaiha: a printed wave-scale pattern over the band paper; the mids run a band of light along it
  if(pxl<.03){vec2 sq=vec2(u-pos*.12,fv)*7.;float rw=floor(sq.y),sd=9.;
   for(int j=0;j<3;j++){float ry=rw+1.-float(j),oe=mod(ry,2.)*.5;vec2 c=vec2(floor(sq.x+oe)+.5-oe,ry-.1);float d=length(sq-c);if(d<.72)sd=d;}
   float ri=abs(fract(sd*4.)-.5)/4.,sa=step(sd,1.)*smoothstep(.03,.012,pxl);
   float wv=.5+.5*sin(u*1.7-uM1[0].y*TAU+b*2.);
   col*=1.+sa*kmA(ri-.01,pxl*7.)*(-.07+.4*envs.y*wv*wv);}
  // kirigane: foil flecks in the paper of every band; they glint with the highs/air and a changing half of them
  // twinkles with the hats
  {vec2 fq=vec2(u,fv)/.085,fg=floor(fq);vec4 hk=kmH(fg+b*13.,29.);
   vec2 fl=rot(hk.z*6.28)*(fract(fq)-.5-(hk.xy-.5)*.5);float fs=.13+.12*hk.w;
   float dd=(abs(fl.x)+abs(fl.y)*1.7-fs)*.085;
   float hsp=uM2[1].y,tw=step(.5,fract(hk.w*5.3+floor(tr*4.)*.5));
   float gl=.1+1.6*envs.x*(.55+.45*sin(hk.x*20.+mt*.6))+3.*hsp*tw;
   col=mix(col,mix(mix(cAc,vec3(1.3,.95,.35),.6),cLt*1.15,step(.6,hk.y))*(.8+gl),kmA(dd,pxl*1.2)*step(hk.z,.36)*smoothstep(.022,.009,pxl)*min(1.,.12+gl*.55));}
#if HD>=1
  {int nF=min(HD,3)+int(min(uZoom,0.));
   for(int fi=int(min(uZoom,0.));fi<nF;fi++){float ff=float(fi),cs=.052*pow(.62,ff);
    vec2 fq=vec2(u,fv)/cs+ff*7.3,fg=floor(fq);vec4 hk=kmH(fg+b*13.+ff*31.,37.);
    vec2 fl=rot(hk.z*6.28)*(fract(fq)-.5-(hk.xy-.5)*.5);
    float dd=(abs(fl.x)+abs(fl.y)*1.7-(.14+.1*hk.w))*cs,gl=.2+1.4*envs.x*(.55+.45*sin(hk.x*20.+mt*.6))+2.2*uM2[1].y*step(.5,fract(hk.w*5.3+floor(tr*4.)*.5));
    col=mix(col,mix(mix(cAc,vec3(1.3,.95,.35),.6),mix(cAc,dc,.5),step(.6,hk.y))*(.85+gl),kmA(dd,pxl*1.2)*step(hk.z,.14-.02*ff)*smoothstep(1.2,4.,cs/pxl)*min(1.,.2+gl*.5));}}
#endif
  float isCl=oh.x+oh.w;
  // sun (sky band): concentric paper rings, rays = spectrum
  {vec4 hs=kmH(vec2(bH,7.),1.);
   vec2 sc=vec2(hs.x*3.-1.5-pos*.04,.6);vec2 sq=vec2(u,fv)-sc;float L=length(sq);
   float ang=atan(sq.y,sq.x),af=ang/TAU*20.+.5,ai=floor(af),sv=spec(.05+.9*abs(fract(ai/20.)*2.-1.));
   float ray=L-(.33+.16*sv+.04*kick)*(1.-.55*abs(fract(af)*2.-1.));
   float m1=oh.x*step(abs(sq.x),1.);
   col=mix(col,mix(cAc,dc,.3),kmA(ray,pxl*1.5)*m1*.9);
   col=mix(col,dc*1.1,kmA(L-.3,pxl*1.5)*m1);
   float rg=fract(L*16.-tr*.5);col=mix(col,mix(dc,cLt,.5),kmA(L-.3,pxl*1.5)*m1*smoothstep(.45,.55,rg)*smoothstep(1.,.9,rg)*.55*dlod);}
  // bottom frieze: layered cloud scallops (crane, dove) or leafy sprigs with blossoms (fox, hare), drifting slowly
  {float fu=u-pos*.3;
   for(int ly=0;ly<2;ly++){float fl=float(ly),cw=mix(.3,.22,fl),fc0=floor(fu/cw);float best=1e3;
     for(int k=-1;k<=1;k++){float ck=fc0+float(k);vec4 hk=kmH(vec2(mod(ck,perD),bH+fl*31.),3.);
       vec2 cc=vec2((ck+.5+(hk.x-.5)*.5)*cw,mix(.1,.0,fl)+.05*hk.y);best=min(best,length(vec2(fu,fv)-cc)-mix(.085,.065,fl)-.035*hk.z-.05*envs.w);}
     best=min(best,fv-mix(.08,.02,fl));
     vec3 fcl=mix(mix(bg,cLt,.2),mix(dc,cLt,.15),fl);
     col=mix(col,fcl,kmA(best,pxl*1.5)*isCl);
     col=mix(col,mix(fcl,bg,.45),kmA(abs(best+.022)-.005,pxl*1.5)*isCl*dlod);
     col=mix(col,mix(fcl,bg,.45),kmA(min(abs(best+.046),abs(best+.068))-.0022,pxl)*isCl*zo*.8);}
   float pw=.3,pc0=floor(fu/pw);
   for(int k=-1;k<=1;k++){float ck=pc0+float(k);vec4 hk=kmH(vec2(mod(ck,perD),bH),4.);
     float ht=.16+.24*hk.y,bx=(ck+.5+(hk.x-.5)*.5)*pw;vec2 l=vec2(fu-bx,fv-.02);
     l.x-=.06*sin(l.y*6.+hk.z*6.)*l.y/ht+.03*sin(tr*PI*.5+hk.w*6.)*l.y;
     float st=max(abs(l.x)-.007,max(-l.y,l.y-ht));
     float lf=1e3;for(int j=0;j<5;j++){float fj=float(j),sg=mod(fj,2.)*2.-1.;vec2 lp=l-vec2(0.,ht*(.2+.17*fj));lp=rot(sg*(1.05-.1*fj))*lp;lp.y-=.05;lf=min(lf,kmLeaf(lp,.07,.05)*1.);}
     vec3 pcl=mix(dc,cDk,.25+.4*step(.5,hk.w));
     col=mix(col,pcl,kmA(min(st,lf),pxl*1.4)*(1.-isCl));
     col=mix(col,mix(pcl,cLt,.35),kmA(max(abs(l.x)-.003,abs(l.y-ht*.55)-ht*.45),pxl*1.4)*(1.-isCl)*dlod*.7);
     vec2 bl=l-vec2(0.,ht+.02);float rB=(.05+.05*envs.w)*(1.+.4*sn),pr=length(bl),pet=kmBloom(rot(tr*.2)*bl,rB);
     float hb=step(.4,hk.z)*(1.-isCl);col=mix(col,cAc*(1.+.5*sn),kmA(pet,pxl*1.3)*hb);col=mix(col,cLt,kmA(pr-.013,pxl*1.3)*hb);
     col=mix(col,mix(cAc,cDk,.5),kmA(abs(pet+rB*.17)-.0017,pxl)*hb*zo);
     col=mix(col,cLt,kmA(length(kmF6(rot(tr*.2)*bl)-vec2(0.,rB*.46))-.0036,pxl)*hb*zo);
     col=mix(col,mix(cAc,cDk,.3),kmA(pr-.0055,pxl)*hb*zo);}}
  // free deco: sparkles (spin with the hats: a twirl, not a flash), leaves and blossoms in the gaps, parallax
  {float hat=uM2[1].y;vec2 dq=vec2(u-pos*.5,fv)/.4,dcl=floor(dq);vec4 hd=kmH(vec2(mod(dcl.x,perD*1.5),bH+dcl.y*17.),5.);
   vec2 l=(fract(dq)-.5-(hd.yz-.5)*.45)*.4;float k=hd.x;
   vec2 al=abs(rot(uM2[0].y*(step(.5,hd.w)*2.-1.)+hd.w*6.)*l);float spk=(sqrt(al.x)+sqrt(al.y))-sqrt(.06+.17*hat*(.5+hd.w)+.1*sn);
   col=mix(col,mix(cLt,vec3(1.8,1.6,1.15),.55*hat),kmA(spk*.12,pxl*1.2)*step(k,.33)*dlod);
   col=mix(col,mix(cLt,dc,.3),kmA(min(al.x,al.y)-.0011,pxl)*step(spk*.12,-.007)*step(k,.33)*zo*.8);
   col=mix(col,mix(cAc,vec3(1.3,.95,.35),.6)*(1.+.8*hat),kmA(abs(spk*.12+.0048)-.0013,pxl)*step(k,.33)*zo);
   // pinwheels: folded four-blade windmills, spun by the mids phase, swelling with the mids
   if(k>.33&&k<.47){vec2 pv=rot((uM1[0].y*TAU*.7+hd.w*6.)*(step(.5,hd.w)*2.-1.))*l;float pa=atan(pv.y,pv.x)/(PI*.5),pf=fract(pa),pl=length(pv);
    float prd=(.07+.04*envs.y)*mix(1.,.34,pf);
    vec3 pc=mix(mix(cAc,dc,step(.5,fract(hd.w*5.))),cLt,step(pf,.5))*(1.+.35*envs.y);
    col=mix(col,KMINK*2.,kmA(pl-prd-.007,pxl*1.2)*dlod);col=mix(col,pc,kmA(pl-prd,pxl*1.2)*dlod);col=mix(col,KMINK,kmA(pl-.01,pxl*1.2)*dlod);col=mix(col,vec3(1.7,1.6,1.4),kmA(length(pv-vec2(-.003,.003))-.0035,pxl)*zo);}
   vec2 sl=rot((hd.w-.5)*2.4)*l;
   float lf=min(min(kmLeaf(sl-vec2(0.,.05),.1,.072),kmLeaf(rot(1.1)*(sl+vec2(.03,.02)),.085,.062)),kmLeaf(rot(-1.)*(sl+vec2(-.035,.01)),.075,.055));
   float isL=step(.47,k)*step(k,.62);
   col=mix(col,mix(dc,cDk,.3*step(.5,fract(hd.w*7.))),kmA(lf,pxl*1.2)*isL*dlod);
   col=mix(col,mix(cLt,dc,.45),kmA(abs(lf+.011)-.0015,pxl)*isL*zo*.85);
   float rF=.075*(1.+.4*sn),pr=length(l),pet=kmBloom(rot(tr*.15+hd.w*3.)*l,rF);
   float isB=step(.62,k)*step(k,.8);
   col=mix(col,cAc*(1.+.5*sn),kmA(pet,pxl*1.2)*isB*dlod);
   col=mix(col,cLt,kmA(pr-.019,pxl*1.2)*isB*dlod);
   // v20: a close look finds the blossom's inset petal line, six stamens and its eye; the snare pops every blossom open
   col=mix(col,mix(cAc,cDk,.5),kmA(abs(pet+rF*.16)-.0018,pxl)*isB*zo);
   col=mix(col,cLt,kmA(length(kmF6(rot(tr*.15+hd.w*3.)*l)-vec2(0.,rF*.45))-.0042,pxl)*isB*zo);
   col=mix(col,mix(cAc,cDk,.3),kmA(pr-.008,pxl)*isB*zo);}
  // paper butterflies: they flutter along every band, wings beat on the highs phase, they open out with the highs and
  // catch the hats
  {float hat=uM2[1].y;vec2 bq=vec2(u-pos*.85,fv)/.6,bc=floor(bq);vec4 hb=kmH(vec2(mod(bc.x,perA*4.),bH+bc.y*11.),41.);
   vec2 lb=(fract(bq)-.5-(hb.yz-.5)*.45)*.6+.018*vec2(sin(tr*1.3+hb.x*9.),cos(tr*1.7+hb.y*9.));
   float sz=(.03+.04*hb.w)*smoothstep(hb.x*.8,hb.x*.8+.3,envs.x+.3*hat)*step(hb.y,.7);
   if(sz>.004&&dot(lb,lb)<sz*sz*5.){lb=rot(hb.z*1.6-.8)*lb;float fl=.28+.72*abs(sin(TAU*(uM1[0].x*1.3+hb.w)));
    vec2 wq=vec2(abs(lb.x)/fl,lb.y)/sz;float wd=min(length(wq-vec2(.58,.22))-.52,length(wq-vec2(.42,-.42))-.36)*sz*fl;
    wd=min(wd,max(abs(lb.x)-sz*.07,abs(lb.y)-sz*.62));
    vec3 wc=mix(mix(cAc,cLt,step(.5,hb.z)),kmP(mod(ty+1.,4.),6.),step(.7,hb.w))*(1.+.5*envs.x+.9*hat);
    col=mix(col,KMINK,kmA(wd-.006,pxl*1.2));col=mix(col,wc,kmA(wd,pxl*1.2));
    col=mix(col,mix(KMINK,wc,.5),kmA(abs(wd+sz*.15)-max(sz*.03,.0013),pxl)*zo);}}
  // bunting: paper pennants strung under each band's top edge; the mids swing them and pull them long, the spectrum lights them
  {float bw=.2,ru=u-pos*.15,ci=floor(ru/bw),lu=ru-(ci+.5)*bw;vec4 hf=kmH(vec2(mod(ci,perA*12.),bH),47.);
   float xn=lu/(bw*.5),ys=.95-.035*(1.-xn*xn),sw=(.012+.05*envs.y)*sin(TAU*uM1[0].y*.8+ci*1.3),L=.04+.07*envs.y+.015*hf.x+.035*sn;
   float fd=kmTri(vec2(lu,fv),vec2(-.075,ys),vec2(.075,ys),vec2(sw,ys-L));
   vec3 fcl=mix(mix(cAc,cLt,step(.5,hf.y)),cDk,step(.8,hf.y))*(1.+.8*spec(.04+.9*fract(ci*.137))+1.1*uM2[1].y*step(.5,fract(ci*.5)));
   col=mix(col,KMINK,kmA(fd-.004,pxl*1.2)*dlod);col=mix(col,fcl,kmA(fd,pxl*1.2)*dlod);
   col=mix(col,fcl*.68,kmA(abs(fract((ys-fv)/.022+.25)-.5)*.022-.0035,pxl)*zo*step(fd,-.005)*step(.5,hf.z));
   col=mix(col,fcl*.68,kmA(abs(fd+.012)-.0017,pxl)*zo*step(hf.z,.5));
   col=mix(col,KMINK*2.,kmA(abs(fv-ys)-.0035,pxl*1.2)*dlod);
   // stitches along the string (the hats light them)
   col=mix(col,vec3(1.7,1.6,1.4)*(.65+.9*uM2[1].y),kmA(max(abs(fv-ys)-.0015,abs(fract(ru/.02)-.5)*.02-.005),pxl)*zo);}
  // shadow of the front band's paper edge, and the front band's rim lit by its spectrum slice
  col*=1.-.32*exp(-(fv-bmp)/.05)*step(fv,1.);
  col=mix(col,mix(cLt,vec3(1.7,1.55,1.3),.4+.4*envs.x)*(.9+.8*sq0+.6*envs.x),kmA(abs(fv-1.-bmp+.014)-.007-.004*envs.x,pxl*1.2)*rimB*min(1.,.25+.75*sq0+.6*envs.x));
  // snare fold wave: a crease of light sweeps along every band, the paper lifting ahead of it
  float uF=mix(-6.,6.,swv/1.2);
  {float du=u-uF-.7*b;col*=1.+.42*step(0.,swv)*exp(-du*du*1.5);}
  // mandala event: three thin scalloped paper garlands behind the wheeling animals; the scene stays visible between them
  {float mnd=uM2[2].y;if(mnd>0.){float md=max(mnd*.55,.03),rr=length(p)/md,an=atan(p.y,p.x);
    float rg=abs(fract(rr/.3)-.5)*.3-.0035-.006*cos(an*24.);
    col=mix(col,mix(cLt,vec3(1.6,1.45,1.1),.4),kmA(rg,px/md*1.2)*step(rr,.9)*smoothstep(.02,.12,mnd));}}
  // ---- procession: the band is a row of slots 2.4 band widths apart: a hero animal in each slot and, in the gap
  // between two heroes, an upper and a lower follower (mid-size or small), so no two animals of a band overlap.
  // Candidates: 0-1 the nearest gap's lower / upper follower (behind), 2 the nearest hero, 3 the front band's nearest
  // hero poking up into this band, 4 the drop hero / mandala, 5 the small animals inside the top facet
  vec4 tTc=vec4(0.);float tId=0.,tT=-1.,tTone=0.,tTy=0.,tPq=1.,tI=-1.,tAx=0.,tLo=.02,tFold=0.,tOn=0.;vec4 tH=vec4(0.);
  float inCov=0.,inIn=0.;
  float hp=uP4.y,hty=uP4.z,hero=step(0.,hp),uf=uM2[2].z,hat=uM2[1].y;
#if HD>=1
  int nX=HD==1?2:HD==2?3:HD==3?4:HD==4?5:7;
#else
  int nX=0;
#endif
  int nA=8+nX+int(min(uZoom,0.));
  for(int i=0;i<nA;i++){
    float fi=float(i)-2.-float(nX);
    float isSm=step(fi,-.5),isG=step(-.5,fi)*step(fi,1.5),isL=step(1.5,fi)*step(fi,2.5),isFr=step(2.5,fi)*step(fi,3.5),isH=step(3.5,fi)*step(fi,4.5),isI=step(4.5,fi);
    float kk=fi;
    float bb=b-isFr,tyC=mod(tsh-bb,4.);
    vec4 ohC=kmOh(tyC);
    float posC=dot(ohC,uP5),envC=dot(ohC,envs);
    // slot width 2.4 band widths: whole slots per spiral turn keep the spirals seamless
    float slot=mix(2.4,.8,isSm),off=.5*(fi+2.)*isSm,x=(u-posC)/slot+off,c=floor(x+.5),gi=c+step(c,x),cell=mix(c,gi,isG),per=mix(perA,perA*3.,isSm);
    vec4 h=kmH(vec2(mod(cell,per),mod(bb,perBand)),1.+3.*isG+kk);
    // a gap follower is mid-size (55%) or small; small ones sit a little off the gap centre
    float isF=isG*step(.55,h.z),isM=isG-isF;
    float uc=mix((c+(h.y-.5)*.04)*2.4,(gi-.5)*2.4+(h.y-.5)*mix(.1,.5,isF),isG)*(1.-isSm)+isSm*(c-off+(h.y-.5)*.3)*.8+posC;
    float cm=mod(cell,per),ph=dot(ohC,vec4(uM1[0].x,uM1[0].y,uM1[0].z,uM1[1].x))-(cm*.15+kk*.3*isG)*(1.-ohC.z);
    // hares: one bound per beat, all together, as high as the kick
    float hop=uM2[0].x*ohC.z*max(sin(PI*fract(ph)),0.)*mix(1.,.55,isG+isSm);
    float vc=mix(mix(mix(.46,.5,ohC.x),mix(.28,.73,kk)+.04*(h.w-.5),isG),mix(.2,.86,fi+2.)+.05*(h.w-.5),isSm)+hop+.04*ohC.x*sin(TAU*ph+1.6)+(.09*isL+.05*isG+.03*isSm)*kick*(1.-ohC.z)+.1*envC*ohC.x*(1.-isG-isSm);
    float sc=mix(mix(.64*(1.+.1*step(.6,h.w)),mix(.29+.03*h.w,.18+.03*h.w,isF),isG),.115+.035*h.w,isSm)*(1.+.3*envC*ohC.w+.2*envC*ohC.x+.16*kick*isL);
#if HD>=1
    if(fi<-2.5){vc=.13+.74*fract(-fi*.381+mod(bb,7.)*.19)+hop;sc*=.82-.05*(-fi-3.);}
#endif
    vec2 q=vec2(u-uc,fv+isFr-vc)/sc;
    float pq=pxb/sc,typ=tyC,pres=step(h.x,mix(mix(.95,.82,isG),.75,isSm));
#if HD>=1
    if(fi<-2.5)pres*=step(h.y,.6-.05*(-fi-3.));
#endif
    if(isH>.5){vec2 hc=vec2(dirS*mix(-1.9,1.9,hp),-.12+.2*abs(sin(PI*tr)));q=(p-hc)/.44;pq=px/.44;typ=hty;pres=hero;
      float mnd=uM2[2].y;if(mnd>0.){
        // mandala: three rings of animals (cranes, then foxes, then hares) wheel round the centre, alternate rings
        // counter-rotating, each animal facing along its ring
        float rr=length(p)/max(mnd*.55,.03),rk=clamp(floor(rr/.3),0.,2.),Nr=4.+4.*rk,sN=TAU/Nr;
        float an=atan(p.y,p.x)+(mod(rk,2.)*2.-1.)*tr*.12,am=mod(an+sN*.5,sN)-sN*.5;
        vec2 pr=rr*vec2(cos(am),sin(am))-vec2((rk+.55)*.3,0.);q=vec2(pr.y,-pr.x)/(.155+.02*rk);pq=px/max(mnd*.55,.03)/(.155+.02*rk);
        pres=step(.02,mnd)*step(rr,.9);typ=rk;}}
    if(isI>.5){float cs=.36;vec2 g0=floor(tTc.zw/cs);vec4 hi=kmH(g0+tT*7.+tId,9.);q=(tTc.zw-(g0+.5)*cs-(hi.yz-.5)*.05)/.14;pq=tPq/.14;typ=mod(tTy+step(.7,hi.x),4.);
      pres=step(0.,tT)*step(.5,abs(tT-5.))*step(.5,abs(tT-7.))*step(.5,abs(tT-9.))*step(hi.w,.85);ph=tr*.5+hi.w;}
    if(dirS<0.&&isI<.5)q.x=-q.x;
    // snare fold wave (the animal folds shut along its vertical crease as the wave passes) and the turnaround event
    // (every animal flips over like a card); past 90 degrees the paper back shows
    float fo=1.2*step(0.,swv)*smoothstep(2.6,0.,abs(uF+.7*bb-uc))*(1.-isH);
    float cf=cos((PI*uM2[2].x+fo)*(1.-isI));q.x=q.x/max(abs(cf),.06)*sign(cf+1e-4);
    // tiny animals (zoomed out) fade into flat colour instead of aliasing
    float lod=smoothstep(.13,.07,pq);
    if(pres*lod<.5||dot(q,q)>2.4)continue;
    vec4 ohT=kmOh(typ);int ity=int(typ);
    // gait amplitude follows each band's own range: cranes flap with the highs, foxes gallop with the mids, doves beat
    // with the bass (the hares' hop is above)
    vec4 ga=(KGA*ohT)*sin(TAU*(ph*(KGF*ohT)+KGO*ohT))*dot(ohT,vec4(.18+1.35*envC,.3+1.05*envC,1.,.25+1.2*envC))*(1.-.5*isF);
    vec2 ef=vec2(uM2[1].z*ohT.x*(1.-isI-isH),clamp(uM1[2].z*1.5-.5*fract(cm*.17+kk*.31),0.,1.)*(1.-isI));
    // fold event: the animal flips over like a card (showing the paper back); confetti: the crane is cut into
    // squares that tumble apart and fly back together
    float cfl=cos(PI*ef.y),bk=max(step(cfl,0.),step(cf,0.));q.y=.2+(q.y-.2)/(sign(cfl+1e-4)*max(abs(cfl),.04));
    if(ef.x>0.){vec2 gc=floor(q*2.6);vec4 hs=kmH(gc,13.);vec2 cc=(gc+.5)/2.6;
      q=cc+rot((hs.x-.5)*9.*ef.x)*(q-cc)-(cc*1.3+vec2(hs.y-.5,hs.z+.2))*ef.x*1.3+vec2(0.,1.1*ef.x*ef.x);}
    // unfold (drops, refold event): a folded paper square turns edge-on like a card and the animal opens out of it,
    // staggered along the procession
    float sqA=clamp(uf*1.7-.7*fract(h.w*7.3+cm*.13),0.,1.)*(1.-isI)*(1.-isH),sqS=abs(1.-2.*sqA);
    q.x/=max(mix(1.,sqS,step(.001,sqA)),.05);
#if HD>=1
    if(isI<.5&&sqA<=.5&&pq<.06&&dot(q,q)<3.2){int nSd=int(float(HD==1?10:HD==2?16:HD==3?22:HD==4?30:44)*clamp(uDetail/float(HD==1?2.:HD==2?3.:HD==3?4.5:HD==4?6.5:10.),.5,1.6));float shS=0.;
      for(int sI=int(min(uZoom,0.));sI<nSd;sI++){float fs=float(sI)+.5,ra=sqrt(fs/float(nSd)),an=fs*2.39996;
        vec4 tcS;vec4 aS=kmAnim(q-(vec2(.1,.15)+vec2(cos(an),sin(an))*ra*.06),ity,ga,pq*1.1,tcS,1.);
        shS+=kmA(aS.x,max(pq*1.2,.012));}
      shS/=float(nSd);
      col=mix(col,col*.5+vec3(.012,.01,.04),.6*shS);}
#endif
    vec4 tc;vec4 a=kmAnim(q,ity,ga,pq*1.1,tc,1.);
    if(sqA>.5){vec2 bq=rot(.785)*(q-vec2(0.,.25));a=vec4(max(abs(bq.x),abs(bq.y))-.4,0.,0.,0.);tc=vec4(0.,.25,q);}
    if(isI>.5){inCov=kmA(a.x,pq);inIn=kmA(a.x+max(.035,pq*.9),pq);continue;}
    float cov=kmA(a.x,pq*1.2);if(cov<=0.)continue;
    float onB=dot(ohC,ons)*(1.-isH);
    vec3 fc=mix(kmP(typ,2.+a.w),vec3(1.9,1.8,1.62),.55*bk)*(1.+.3*onB+.3*hat*isG);
    // Printed washi paper: broad diagonal stripes and star-fold inlays remain readable on tiny animals.
    float paper=sin((tc.z+tc.w)*20.+typ*2.1),paperLod=1.-smoothstep(.025,.08,pq);
    fc=mix(fc,kmP(typ,4.)*.8,.18*paperLod*smoothstep(.25,.75,paper));
    float lo=max(.016,pq*1.1);
    fc=mix(fc,mix(fc*.62,mix(KMINK,fc*.2,.42),smoothstep(.05,.02,pq)),kmA(-a.x-lo,pq));
    col=mix(col,fc,cov);
    if(cov>.5){tTc=tc;tT=a.y;tTone=a.w;tTy=typ;tPq=pq;tI=fi;tId=fi+mod(cell,97.)*.137;tAx=a.x;tLo=lo;tH=h;tFold=bk+ef.x;tOn=onB+.45*hat*isG;}
  }
  // ---- the top animal's paper: angular parts fold into a fan of facets around an off-centre fold point; each facet
  // is lit by its own tilt (a band onset swings the light, so the facets flash and seem to fold open), ink creases
  // between them; dark facets hold a blossom-and-leaf mosaic or small animals, light ones feather veins, a diamond
  // lattice, a leaf mosaic or small animals. Heads, muzzles and inner ears stay smooth paper with a face.
  if(tT>=0.){
    float pq=tPq,part=tT,smo=step(4.5,part)*step(part,5.5)+step(6.5,part)*step(part,7.5)+step(8.5,part);
    vec2 tP=tTc.zw;vec4 hf=kmH(vec2(part,tId*3.+tH.x*17.),19.);
    vec2 o=tP-tTc.xy-(hf.xy-.5)*.14;
    float N=mix(6.,4.,step(2.5,part)),ro=hf.z*6.28,swd=TAU/N,an=atan(o.y,o.x)+ro,si=floor(an/swd),loc=an-(si+.5)*swd;
    float crs=length(o)*sin(.5*swd-abs(loc));
    vec4 hs=kmH(vec2(si+7.,part+tId*7.),23.);
    float shd=.8+.34*cos((si+.5)*swd-ro-2.3-mt*.03-2.6*tOn)+.1*(hs.z-.5);
    float tone=tTone;
    if(smo<.5&&tone<.5)tone=(hs.x<.3&&part<2.5)?3.:(hs.x>.86?4.:(hs.x>.62?1.:0.));
    float dark=step(2.5,tone)*step(tone,3.5);
    float wing=step(2.5,part)*step(part,4.5)*(step(tTy,.5)+step(2.5,tTy));
    float fk=mix(hs.y,.3+.12*hs.y,wing*(1.-dark)),tiny=step(fk,mix(.12,.42,dark))*(1.-smo);
    vec3 cS=kmP(tTy,3.),cL=kmP(tTy,4.),cA=kmP(tTy,6.),cM=kmP(tTy,2.),cD=kmP(tTy,5.);
    vec3 f=mix(mix(mix(mix(cM,cS,step(.5,tone)),cL,step(1.5,tone)),cD,step(2.5,tone)),cA,step(3.5,tone));
    f=mix(f,mix(cA,vec3(1.,.55,.62),.45),step(8.5,part));
    float cs=.11;vec2 g=floor(tP/cs),l=tP-(g+.5)*cs;vec4 hm=kmH(g+si*3.+tId,11.);
    float isLf=step(.72,hm.y),fl=smoothstep(4./KY,8./KY,cs/pq);
    vec2 lr=rot(hm.w*6.28)*l;
    float m=kmA(mix(kmBloom(lr,cs*.42),kmLeaf(lr,cs*.42,cs*.31),isLf),pq*1.2),ctr=kmA(length(l)-cs*.1,pq*1.2)*(1.-isLf);
    vec3 pc=mix(mix(cA,cL,step(.33,hm.x)),cM,step(.66,hm.x));pc=mix(pc,mix(cS,cA,.35),isLf);
    vec3 mos=mix(mix(f,pc,m),cD,ctr);
    f=mix(f,mix(mix(f,pc,.22),mos,fl),dark*(1.-tiny));
    vec3 lpc=mix(mix(cA,mix(cD,cA,.35),step(.5,hm.x)),mix(cS,cD,.55),isLf);
    f=mix(f,mix(f,lpc,m*fl*.9),step(.62,fk)*step(fk,.86)*(1.-dark)*(1.-smo));
    float an2=fract(si*.61+tH.z)*3.14;vec2 dr=vec2(cos(an2),sin(an2));
    float st=dot(tP,dr)*15.+abs(dot(tP,vec2(-dr.y,dr.x)))*9.,ln=abs(fract(st)-.5)/15.;
    float isV=step(.25,fk)*step(fk,.45)*(1.-dark)*(1.-smo),fv2=smoothstep(4./KY,8./KY,.067/pq);
    float lnw=max(.006,pq*.8);f=mix(f,mix(cS,cA,.55),kmA(ln-lnw,pq)*isV*fv2*.006/lnw);
    vec2 dg=abs(fract(rot(.785)*tP*11.)-.5);
    f=mix(f,mix(cS,cA,.55),kmA((dg.x+dg.y-.22)/11.,pq)*step(.45,fk)*step(fk,.6)*(1.-dark)*fv2*.85*(1.-smo));
    // small animals inside the facet: cream with an accent outline on dark paper, dark ink ones on light paper
    f=mix(f,mix(cA,cD,1.-dark),inCov*tiny);f=mix(f,mix(cL,mix(cD,cS,.25),1.-dark),inIn*tiny);
    // folded paper: per facet light, the crease between facets, a soft cast of the head fold, fibre grain
    {float wz=smoothstep(.0045*KW,.003*KW,pq)*(1.-smo)*(1.-tiny)*(1.-dark)*(step(.86,fk)+step(.6,fk)*step(fk,.62));
     if(wz>.003)f=mix(f,mix(f,mix(cS,cA,.5),.6),kmA(kmWag(rot(hs.w*6.28)*tP/.055,floor(hs.z*5.999),.04)*.055,pq)*wz);}
    f*=mix(shd,1.,smo*.75)*(1.+.3*tOn);
    f*=mix(1.,.95+.1*step(0.,dot(o,vec2(.5,-.86))),step(4.5,part)*step(part,5.5));
    float lw=max(.005,pq*.75);f=mix(f,f*.7,kmA(crs-lw,pq)*.85*min(1.,.006/lw)*(1.-smo));
    f*=1.+.06*(vnoise(tP*55.)-.5)*smoothstep(.02,.008,pq);
    // zoomed in, the paper shows itself: a fine printed chiyogami pattern on plain facets and a light ridge beside
    // each crease (the mountain fold catches the light)
    float zq=smoothstep(.014*KY,.005*KY,pq);
    if(zq>0.){
      float c2=.06;vec2 g2=floor(tP/c2),l2=tP-(g2+.5)*c2;vec4 h2=kmH(g2+si,31.);
      float pr2=mix(kmBloom(rot(h2.x*6.28)*l2,c2*.34),length(l2)-c2*.12,step(.55,h2.y));
      f=mix(f,mix(f,mix(cL,cS,step(.5,tone)*.6),.55),kmA(pr2,pq)*zq*(1.-dark)*(1.-smo)*step(h2.z,.7)*step(fk,.25));
      f=mix(f,f*1.28+.05,kmA(abs(crs-lw*2.6)-lw*.7,pq)*zq*(1.-smo)*.8);
    }
    col=mix(col,f,kmA(tAx+tLo,pq));
    // the cut paper edge catches a thin highlight just inside the ink outline when zoomed in
    col=mix(col,col*1.2+.04,kmA(abs(tAx+tLo+pq*2.)-pq*.8,pq)*zq*.75);
    // face: a glossy eye with a glint, cheek blush, nose and a small smile (fox, hare)
    vec4 ohF=kmOh(tTy);float onH=step(4.5,part)*step(part,7.5)*step(tFold,.05)*step(tI,8.);
    vec2 ep=vec2(dot(ohF,vec4(.86,.71,.72,.655)),dot(ohF,vec4(.52,.25,.31,.345))),np=vec2(dot(ohF,vec4(0.,1.07,.885,0.)),dot(ohF,vec4(0.,.12,.215,0.)));
    float er=dot(ohF,vec4(.038,.05,.05,.042));
    col=mix(col,mix(col,vec3(1.,.45,.55),.55),kmA(length((tP-ep-vec2(-.035,-.1))/vec2(1.,.62))-.055,pq*1.5)*onH*(1.-ohF.x));
    col=mix(col,KMINK,kmA(length(tP-ep)-er,pq)*onH);
    col=mix(col,vec3(1.6),kmA(length(tP-ep-vec2(.015,.018))-er*.38,pq)*onH);
    float nf=ohF.y+ohF.z;
    col=mix(col,KMINK,kmA(length((tP-np)/vec2(1.,.8))-.028,pq)*onH*nf);
    vec2 sp=tP-np-vec2(-.06,-.05);float sm=max(abs(length(sp)-.05)-max(.006,pq*.5),sp.y);
    col=mix(col,mix(KMINK,col,.3),kmA(sm,pq)*onH*nf);
  }
  // ---- the wipe: a page-turn crease with the cream back of the paper
  {float dw=(sd-fr)/max(zm,.3);float pg=step(wp,1.59);
   col=mix(col,col*.55,smoothstep(.06,0.,dw)*step(0.,dw)*pg);
   col=mix(col,vec3(1.,.95,.88),kmA(abs(dw+.012)-.012,.002)*pg);
   col=mix(col,KMINK,kmA(abs(dw)-.0015,.002)*pg);}
  col=mix(col,vec3(1.1,1.05,.95),kmA(abs(sdP-frP)-.002,.003)*step(uP2.w,.999)*step(.001,uP2.w));
  col*=1.035+.35*dfl;
  // paper should glow to the corners: offset most of the composite's vignette
  col*=1./max(1.-.3*dot(p0,p0),.5);
  // global hue nudge
  float hu=.08*sin(TAU*uHue),ch=cos(hu),shh=sin(hu);vec3 kq=vec3(.57735);
  col=col*ch+cross(kq,col)*shh+kq*dot(kq,col)*(1.-ch);
  // a little extra saturation: the procession is denser now, and its cream paper must not wash the bands out
  col=max(mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.38),0.);
  fragColor=vec4(col,0.);
}
`;
