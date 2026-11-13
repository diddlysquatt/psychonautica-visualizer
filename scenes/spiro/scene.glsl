const R_SPIRO = `
// GUILL0 (spiro): an uncut sheet of neon banknotes. Every line family is the iso-line set of an explicit polar
// (medallions) or linear (borders, friezes, bands) field, so hundreds of crisp lines cost a few sines per pixel.
// Coverage is measured in pixels (analytic partials of each family times the screen derivatives of the zone
// coordinates): a family whose spacing drops under ~2.5 px melts into its mean tone (no aliasing, no moire). Hubs hold
// engraved emblems (a turning globe, a faceted star) whose tone comes from line WIDTH; microtext runs
// around rims, frames and gutters; latent images (a hidden star, discs, a quatrefoil, diamonds) surface in the
// engraving with the vocal range; holographic foil strips shimmer with the highs. Zooming out reveals the sheet:
// notes of every layout in 3x3 blocks between wide engraved bands, detail continuing to the pixel.
// Music: 8 bands (smoothed in JS for geometry, raw for light) drive ring lobes inside-out bass..treble; kick = a ring of
// light riding outward; snare = counter-rotation jolt; hats/air = glints on lines and foil; build = camera push-in and
// ring pulses; breakdown = the camera pulls back over the sheet; drop = a radial wipe into a new design.
// Structure for fast D3D compiles: layouts only compute geometry; one medallion call, one zone loop, one emblem, one
// microtext and one foil evaluation per pixel; derivatives are taken once, outside any flow control.
vec3 spc0,spc1,spc2,spc3,spc4;
float spLW,spPx,spHat,spHp,spLA,spKW,spHS,spPump=1.,spPS,spDt=1.,spFM=0.,spSd=0.;vec3 spPC;
// (v19) detail range. SPK0 is a zero the compiler cannot fold, so runtime-bounded loops are not unrolled by fxc.
#define SPK0 min(int(uTime),0)
#if HD>=5
#define SPNF 22
#define SPNP 48
#define SPNL 12
#define SPNS 40
#define SPNT 8
#define SPNH 8
#elif HD==4
#define SPNF 14
#define SPNP 28
#define SPNL 9
#define SPNS 32
#define SPNT 8
#define SPNH 7
#elif HD==3
#define SPNF 10
#define SPNP 20
#define SPNL 7
#define SPNS 28
#define SPNT 6
#define SPNH 6
#elif HD==2
#define SPNF 8
#define SPNP 14
#define SPNL 5
#define SPNS 24
#define SPNT 6
#define SPNH 5
#elif HD==1
#define SPNF 6
#define SPNP 9
#define SPNL 3
#define SPNS 16
#define SPNT 6
#define SPNH 5
#else
#define SPNF 0
#define SPNP 0
#define SPNL 0
#define SPNS 1
#define SPNT 1
#define SPNH 0
#endif
// render scale of each tier relative to the display: pitches and line weights are held in DISPLAY pixels, so a higher tier adds
// structure the eye can see rather than lines thinner than a pixel that average into a pale tone
#if HD>=5
#define SPSS 4.
#define SPFL 10.
#elif HD==4
#define SPSS 3.
#define SPFL 7.8
#elif HD==3
#define SPSS 2.
#define SPFL 5.4
#elif HD==2
#define SPSS 1.5
#define SPFL 4.4
#elif HD==1
#define SPSS 1.
#define SPFL 3.5
#else
#define SPSS 1.
#define SPFL 4.
#endif
#define SPQ pow(SPSS,.8)
struct SpG{float v,X,wid,circ,band,toff,psA,psB,fade,cy,ds,lt;int zi;float sd;};
SpG spG0(){return SpG(.5,0.,.1,1.,0.,0.,0.,0.,0.,1.,1.,0.,0,0.);}
// atan(y,x) to ~.002 rad, cheaper than the built-in
float spAt(float y,float x){vec2 a=abs(vec2(x,y));float t=min(a.x,a.y)/max(max(a.x,a.y),1e-6),r=.7854*t-t*(t-1.)*(.2447+.0663*t);
  r=a.y>a.x?1.5708-r:r;r=x<0.?PI-r:r;return y<0.?-r:r;}
float spH(float a,float b){return fract(sin(a*91.3458+b*47.2317)*24634.6345);}
// the 5 palette colours of both designs arrive packed as 8-bit sRGB triplets (JS: spiroPal; hue nudge applied there)
vec3 spU(float f){f=floor(f+.5);vec3 c=vec3(floor(f/65536.),mod(floor(f/256.),256.),mod(f,256.))/255.;return pow(c,vec3(2.2));}
void spSetPal(bool nw){
  spc0=spU(nw?uM2[0][0]:uM2[1][2]);spc1=spU(nw?uM2[0][1]:uM2[2][0]);spc2=spU(nw?uM2[0][2]:uM2[2][1]);
  spc3=spU(nw?uM2[1][0]:uM2[2][2]);spc4=spU(nw?uM2[1][1]:uP5.w);
}
// branchless cyclic blend of the 5 palette colours (smoothstep weights sum to 1)
vec3 spCol(float t){
  float f=fract(t)*5.;vec4 d=abs(f-vec4(0,1,2,3));d=min(d,5.-d);vec4 w=max(1.-d,0.);w=w*w*(3.-2.*w);
  float e=abs(f-4.);e=min(e,5.-e);e=max(1.-e,0.);e=e*e*(3.-2.*e);
  return spc0*w.x+spc1*w.y+spc2*w.z+spc3*w.w+spc4*e;}
// 8 band envelopes smoothed in JS (geometry); uB1/uB2/uO1/uO2 are used raw for light
float spBand(float i){
  int k=int(clamp(i,0.,7.)+.5);
  return dot(uM1[0],vec3(equal(ivec3(k),ivec3(0,1,2))))+dot(uM1[1],vec3(equal(ivec3(k),ivec3(3,4,5))))+dot(uM1[2].xy,vec2(equal(ivec2(k),ivec2(6,7))));}
vec3 spPick(float i){float k=mod(i,5.);vec4 w=vec4(equal(vec4(k),vec4(0,1,2,3)));return spc0*w.x+spc1*w.y+spc2*w.z+spc3*w.w+spc4*step(3.5,k);}
float spCov(float d){return 1.-smoothstep(spLW*.5-.5,spLW*.5+.6,d);}
// u: line index field (lines at integers), w: index units per pixel. Dense families fade to their mean coverage.
float spLine(float u,float w){
  w=max(w,1e-5);
  float d=abs(fract(u+.5)-.5)/w;
  return mix(min(spLW*w,1.)*.2,spCov(d),smoothstep(1.5,3.3,1./w));   // (v19) no glow tail above HD 0: the paper between lines stays black
}
// (v19) hairline: one crisp ~1 px line per unit of u; vanishes (never melts to a tone) when the pixels cannot hold it,
// so fine families appear continuously as the footprint shrinks and nothing shimmers
float spHair(float u,float w){w=max(w,1e-5);float d=abs(fract(u+.5)-.5)/(w*sqrt(SPSS));return (1.-smoothstep(.15,.95,d))*smoothstep(1.6,2.7,1./(w*pow(SPSS,.75)));}
// (v19) one fine guilloche family over zone coordinates: N lines across v, a wave of n lobes (relative amplitude A), shear c
float spFL(float v,float X,float N,float n,float A,float ph,float c,vec4 J){
  float a=n*X+ph+c*v,s=sin(a),k=cos(a);
  return spHair(N*(v+A*s),length(N*(1.+A*k*c)*J.xy+N*A*k*n*J.zw));
}
// (v19) an ornament row through a zone between two rules: pearls, lozenges or clover. rgb to add, .a = how much of the
// line work underneath it knocks out. Cells count whole around the ring, so it never pops; the pearls glint with the hats.
vec4 spOrn(float v,float X,float wid,float circ,float z,float sd,float bd,float tc){
  float ho=spH(sd,z*5.31+1.7),h=min((.17+.05*ho)*wid,.0205);
  float fm=smoothstep(4.5,8.5,h/spPx);
#if HD<1
  if(fm<.003||ho<.16)return vec4(0.);
#endif
  float M=max(6.,floor(circ/(2.3*h))),c=circ/M,cu=X/TAU*M,ci=floor(cu+.5);
  float x=(fract(cu+.5)-.5)*c,y=(v-.5)*wid;
  int ty=int(ho*2.999);
  float hc=fract(ci*.618+sd*5.),ax=abs(x),ay=abs(y);
  float d=length(vec2(x,y))-h*.68;
  if(ty==1)d=(ax/(c*.52)+ay/h-.92)*min(c*.52,h)*.72;
  if(ty==2)d=min(length(vec2(ax-h*.36,y)),length(vec2(x,ay-h*.36)))-h*.34;
  float fill=smoothstep(spPx,-spPx,d),edge=1.-smoothstep(.2,1.3,abs(d)/(spPx*pow(SPSS,.5)));
  vec3 cl=spPick(floor(z+ho*5.)),co=cl*edge*1.3;
  // inside: a jewel (pearl: a lit sphere; lozenge: an inner lozenge rule; clover: a centre dot)
  float inr=length(vec2(x+h*.2,y-h*.24))/(h*.68);
  co+=fill*(ty==0?(spCol(tc+hc)*(.2+1.15*exp(-inr*inr*3.))+.22*exp(-inr*inr*14.)):vec3(0.));
  co+=fill*(1.-float(ty==0))*(spCov(abs(d+h*.28)/spPx)*.75*cl+.32*cl);
  co*=(1.+.8*bd+.9*uB2.z+.7*uB2.x)*(1.+4.*spHat*step(hc,.34));
  float rail=spCov(abs(ay-h)/spPx)*.75*(1.+1.3*uB2.w);
  co+=rail*spCol(tc);
#if HD>=1
  // a chain of seed pearls riding each rule, and tiny dots in every interval
  float N2=max(20.,floor(circ/max(.0042,3.2*spPx))),cu2=X/TAU*N2,x2=(fract(cu2+.5)-.5)*circ/N2;
  float d2=length(vec2(x2,ay-h))-max(.0011,.7*spPx);
  co+=(1.-smoothstep(-spPx*.6,spPx*.6,d2))*cl*(.8+1.4*spBand(6.));
#endif
  return vec4(co*fm,fm*max(fill*.9,step(ay,h)*.28));
}
// one zone: two families (the second where the pixels allow), each drawn as two strands. J = screen derivatives of
// the zone coordinates (dv/dx, dv/dy, dX/dx, dX/dy); each family supplies its analytic partials du/dv, du/dX.
vec3 spZone(SpG g,vec4 J){
  float z=float(g.zi),sd=g.sd;
  float h1=spH(sd,z*7.31+2.2),h2=spH(sd,z*3.77+5.9),h3=spH(sd,z*1.93+8.3),h4=spH(sd,z*6.11+.4);
  // (v19) finer pitch at every tier; Native and above may run down to ~3 px and scale with the detail level
  float sp0=.0046*g.ds/pow(spDt,.7),sp=max(sp0,SPFL*spPx);
  int t1=int(h1*4.999),t2=int(mod(float(t1)+1.+floor(h2*4.),5.));   // 0 woven, 1 lace, 2 knurl, 3 rope, 4 rose engine
  float N=clamp(floor(g.wid/sp),3.,HD>=1?240.:64.);
  float n1=clamp(floor(g.circ/(g.wid*(1.4+2.6*h2))),2.,48.),n2=mix(n1+1.,n1*2.,step(h3,.5));
  float bd=spBand(g.band);
  float w2=smoothstep(2.1,3.4,sp0/spPx);   // a second family only when the pixels allow
  float G=1.+step(.5,h4);
  float phA=G*g.psA+h3*TAU,phB=-G*g.psB+h1*TAU;
  vec3 o=vec3(0.);float cs=0.;
  float v=g.v,X=g.X,sv=sin(PI*v),cv=PI*cos(PI*v);
  float Al=.5+.45*bd,s=(v-.5)/(.5*Al),sc=clamp(s,-.9999,.9999),al=asin(sc),sq1=sqrt(1.-sc*sc);
  float a0k=floor(g.circ/(3.2*sp))/TAU,Nk=max(1.,floor(N*.4)),out1=step(1.,abs(s));
  for(int k=0;k<4;k++){
    int f=k/2,st=k-2*f;
    float ff=float(f),stf=float(st),sg=1.-2.*stf;
    int ty=f==1?t2:t1;
    float n=mix(n1,n2,ff),lcf=float(ty==1),kn=float(ty==2),rs=float(ty==4),wv=float(ty==0),rp=float(ty==3)+rs;
    float I=mix(1.25,.9*w2,ff)*(1.-.18*stf)*g.fade*(1.-lcf*out1);
    float M=max(5.,floor(g.circ/(n*2.4*sp))),kl=M/TAU,ul=(mix(al,PI-al,stf)-n*X-phA)*kl;
    // rope and the rose-engine barleycorn share the twisted formula (the barleycorn flips phase every line)
    float A=wv*(.1+.18*bd)+kn*(.08+.2*bd)+(rp-rs)*(.05+.13*bd)+rs*(.42+.3*bd)/N;
    float a0=kn*a0k,Nn=mix(N,sg*Nk,kn),ph=mix(phA,mix(phA,phB,stf),wv+rp),c=((rp-rs)*TAU+rs*PI*N)*sg;
    float aa=n*X+ph+c*v,sa=sin(aa),ca=cos(aa),E=rp+(kn-wv)*sv,Ed=(kn-wv)*cv,ug=a0*X+Nn*(v+A*E*sa);
    float lf=g.lt*(1.-ff);   // latent image: the main family shifts half a line inside the mask
    float u=mix(ug,ul,lcf)+(.14+.36*min(spLA,1.))*lf;   // the shift grows as the image surfaces
    float fv=mix(Nn*(1.+A*(Ed*sa+E*ca*c)),sg*kl/(.5*Al*sq1),lcf);
    float fX=mix(a0+Nn*A*E*ca*n,-n*kl,lcf);
    float t=g.toff+stf*.09+ff*.3+mix(mix(ug*.004,v*.15,kn),.12*sin(ul*TAU/M),lcf);
    float cv2=spLine(u,length(fv*J.xy+fX*J.zw));
    float gg=smoothstep(.74,1.,cos(3.*X-spHp+floor(u+.5)*2.39996));
    float la=lf*spLA;
    cs+=cv2*min(I,1.);cv2*=I*(1.+.9*la);
    o+=cv2*mix(spCol(t+g.cy*sin(X+uP3.y*TAU)),spc4*1.2+.08,.6*min(la,1.))*(1.+spHat*4.*gg);
  }
  o/=max(1.,.4+.6*cs);   // crossings stay saturated instead of adding up to white
  o*=1.+.48*bd+.4*uP2.w+.5*spHat+.3*uB2.x+.25*uB2.y;   // (v19) each zone's light follows its own band; the snare, hats and vocal range light every zone
  // (v19) hairlines: a family three times finer in the gaps between the main lines (it arrives with the pixels: zoom in, or
  // run a higher tier, and new lines appear between the old ones instead of the same lines getting wider)
  float ht=1.-.7*min(cs,1.),h5=fract(h1*3.7+h2);
  o=mix(o,spCol(g.toff+.02)*min(g.fade,1.)*(.55+.45*bd+.9*uB2.z+.8*uB2.w+.5*uB2.x+.5*uB2.y)*(1.+1.6*uP2.w+2.2*spHat),spFL(v,X,N*3.,2.*n1+floor(h5*5.),.025+.05*h5,phA*2.+h3*TAU,0.,J)*ht*.6);
  {float h9=spFL(v,X,N*9.,3.*n1+2.+floor(h5*7.),.012+.02*h5,-phA*3.+h2*TAU,(h5-.5)*2.,J);
   o=mix(o,spCol(g.toff+.3)*min(g.fade,1.)*(.5+.5*bd+uB2.w+.8*uB2.z+2.*spHat),h9*ht*.5);}
#if HD>=1
  // (v19) extra guilloche families, alternating light and ink so they enrich the zone and never wash it out
  for(int k=SPK0;k<SPNF;k++){
    float fk=float(k),hk=spH(sd+fk*.17,z*2.+fk*1.3),odd=step(.5,mod(fk,3.));   // two of every three families are dark ink
    float Ni=N*(2.1+fk*.62+.7*hk),ni=floor(n1*(.5+1.5*hk))+fk+1.,Ai=.018+.06*fract(hk*5.3)/(1.+.4*fk),ci=(.7+fk*.5)*(hk<.5?-1.:1.);
    float li=spFL(v,X,Ni,ni,Ai,(fk+1.)*(1.-2.*odd)*phA+hk*TAU,ci,J);
    o=mix(mix(o,spCol(g.toff+.03*hk)*min(g.fade,1.),li*ht*.55),o*(1.-li*.78),odd);
  }
#endif
  // (v19) the ornament row
  if(g.fade>.02){
    vec4 orn=spOrn(g.v,g.X,g.wid,g.circ,z,sd,bd,g.toff);
    o=o*(1.-orn.a)+orn.rgb*min(g.fade,1.);
  }
  return o;
}
// (v18) one spirograph pen: a braided rose curve around a medallion (two strands, opposite phase). rho/a/A in radii, px = radii per pixel
vec2 spPen(float rho,float th,float a,float A,float n,float ph,float px,float wp){
  float ag=n*th+ph,s=sin(ag),dr=A*n*cos(ag)/max(rho,.12);
  float d=min(abs(rho-a-A*s),abs(rho-a+A*s))/(px*sqrt(1.+dr*dr));
  float rail=1.-smoothstep(.45,1.25,abs(d-wp)),mid=(1.-smoothstep(.3,1.,d))*step(2.4,wp);
  return vec2(max(rail,mid*.8),1.-smoothstep(wp+.9,wp+1.9,d));   // (v20: rails and a centre hairline, dark ink under the whole ribbon)
}
// double line with a bead chain between; dy in screen units, f = bead phase (beads at integers), pitch in screen units,
// Ll = light direction in the separator's (along, across) frame: the beads are lit little spheres
float spSep(float dy,float f,float pitch,float o,vec2 Ll){
  float l=spCov(abs(abs(dy)-o)/spPx);
  float br=max(.0019,.85*spPx)*(1.+.9*spBand(6.));
  vec2 bo=vec2((fract(f+.5)-.5)*pitch,dy)/br;float b=length(bo);
  float sh=.4+.9*max(dot(vec3(bo,sqrt(max(1.-b*b,0.))),vec3(Ll*.75,.66)),0.);
  return l+(1.-smoothstep(1.-spPx*.8/br,1.+spPx*.8/br,b))*1.2*sh;
}
// zone boundary j of a medallion: wavy circle
float spBnd(float sd,float c0,int j,int Z,float th,float ps,out float base){
  float fj=float(j),fZ=float(Z),h=spH(sd,fj*3.17+.71),h2=fract(h*7.13+.31),isZ=float(j==Z),is0=float(j==0);
  base=mix(c0,1.,fj/fZ+(h-.5)*.3/fZ*(1.-isZ-is0));
  float bdj=spBand(clamp(fj*1.6,0.,7.));   // (v18) the ring lifts and flares with its band
  float m=floor(mix(4.+h2*16.,14.+h2*22.,isZ));
  float amp=mix((.006+.014*h)*(1.-.4*is0),.011,isZ);
  return base+amp*(1.+2.5*bdj)*sin(m*th+(1.-2.*mod(fj,2.))*ps+h*TAU)+.04*bdj*(1.-isZ);
}
// medallion geometry: draws ring separators and spectrum teeth; returns the zone the pixel lies in through g
// (g.zi<0: the hub, where g.wid carries the emblem radius) and the microtext ring coordinates through mt
vec3 spMedGeo(vec2 q,float th,float R,float sd,float dir,float halo,float hubK,out SpG g,out float occ,out vec3 mt,out vec4 rs,out vec3 rc){
  g=spG0();mt=vec3(0.,-1.,1.);
  float r=length(q)+1e-5,rho0=r/R;
  float kb=uP2.y*exp(-pow((rho0-uP2.x)/.1,2.));
  float rho=rho0-.06*kb,R0=R/spPump;
  float Rz=min(R0,R0*.00093*uRes.y*uP1.w);   // ring count follows the medallion's size in pixels at the realm camera (v13: not the user zoom, so zooming never re-partitions the rings)
  // (v19) one more ring on the big medallions at every tier, and more again from Native up
  int Z=2+int(step(.055,Rz)+step(.1,Rz)+step(.2,Rz)*floor(spH(sd,5.1)*1.999)+step(.26,Rz)+min(float(HD),3.)*step(.14,Rz)+step(4.5,float(HD))*step(.2,Rz)+.5);
  float psA=uP1.x*dir,c0=mix(.19+.09*spH(sd,1.37),.4+.08*spH(sd,1.37),hubK);
  float cl=0.,cu=halo,bl=0.,bu=halo;int zi=Z;
  for(int j=SPK0;j<11;j++){
    if(j>Z)break;
    cu=spBnd(sd,c0,j,Z,th,psA,bu);
    if(rho<cu){zi=j-1;break;}
    cl=cu;bl=bu;
  }
  float isH=float(zi<0),isR=float(zi==Z);
  cu=mix(cu,halo,isR);bu=mix(bu,halo,isR);
  occ=1.-isR;
  float kl=1.+2.8*kb;
  // ring separator: the nearer boundary (distance in screen units from the radial distance)
  float up=float(zi<0||(zi<Z&&cu-rho<rho-cl)),c=mix(cl,cu,up),base=mix(bl,bu,up);int j=zi+int(up);
  float isZ=float(j==Z),dy=(rho-c)*R,Nb=floor(TAU*base*R0/max(.0105,4.5*spPx*SPQ));
  rs=vec4(dy,(th*Nb-psA)/TAU,TAU*base*R/max(Nb,1.),max(mix(.0027,.0042,isZ),1.4*spPx));
  float l=isZ*spCov(abs(abs(dy)-max(.0085,3.*spPx))/spPx)*.8;
  float ci=mod(float(j)+floor(spH(sd,9.7)*5.),5.);   // each ring takes one palette colour
  vec4 cw=vec4(equal(vec4(ci),vec4(0,1,2,3)));
  rc=mix(spc0*cw.x+spc1*cw.y+spc2*cw.z+spc3*cw.w+spc4*float(ci>3.5),vec3(1.),.3)*1.5*(1.+2.2*uP2.w);
  vec3 o=rc*l;
  float D=max(cu-cl,1e-3),v=(rho-cl)/D;
  // outside the rim: engraved teeth whose length is the spectrum (bass at the top, treble at the bottom, mirrored),
  // then a microtext ring, then a halo zone that fades out
  float tb=spBand(abs(th)/PI*7.),tN=floor(TAU*R0/max(.0062,3.6*spPx*SPQ)),td=(rho-cl)*R,tl0=.013+.014*spec(abs(th)/PI*.9+.05)+R*.2*tb;   // (v18) the crown of teeth is a real equaliser
  float tl=spLine(tN*th/TAU,tN/TAU/r*spPx)*smoothstep(tl0+.003,tl0,td)*smoothstep(.007,.011,td);
  o+=isR*tl*mix(spc1,spc4,tb)*(.6+1.1*tb);
  float mh=max(.0105,.026*R0),mr=.03+.006*step(.2,R0);
  if(isR>.5&&R0>.12){float nc=max(10.,floor(TAU*(R0+mr)/(mh*.667)/10.)*10.);mt=vec3(fract(th/TAU+.5)*nc*mh*.667,td-mr,mh);}
  float fade=mix(1.-isH,step(1.01,halo)*pow(max(1.-v,0.),1.6)*.55,isR);
  // the medallion plate is a shallow dome lit from the upper left
  float dome=.6+.55*dot(normalize(vec3(q/R*.5,1.)),vec3(-.48,.6,.64));
  // latent image hidden in the zones (by seed): a five-point star or a ring of eight discs
  float li=step(.5,spH(sd,8.8)),an=mix(TAU/5.,TAU/8.,li),aa=mod(th-PI*.5+an*.5,an)-an*.5;
  vec2 s2=rho0*vec2(cos(aa),abs(sin(aa)))-vec2(mix(.9,.68,li),0.);
  float ld=mix(s2.x*.3777+s2.y*.926,length(s2)-.15,li);
  g.lt=smoothstep(spPx/R,-spPx/R,ld)*(1.-isR);
  g.v=v;g.X=th;g.wid=mix((bu-bl)*R0,c0*R*.97,isH);g.circ=TAU*(bu+bl)*.5*R0;g.band=mix(clamp(float(zi)*1.6+1.,1.,7.),7.,isR);
  g.toff=float(zi)*.2+spH(sd,9.7);g.psA=psA;g.psB=uP1.y*dir;g.fade=fade*kl*dome;g.cy=.17;g.zi=zi;g.sd=sd;
  rc*=kl*mix(1.,dome,occ);
  // (v18) the spirograph pens: three neon braids drawn over the engraving, one per register (bass: few fat lobes, mids:
  // a tighter star, highs: a fine fast crown), plus a burst of spokes from the hub on the snare
  float pb=spBand(1.),pm=spBand(3.),ph=spBand(6.),px=pow(SPSS,.5)*spPx/R,sn=uP2.w,hp1=spH(sd,12.7),hp2=spH(sd,14.1),dfp=fract(uP5.x);
  float pk=(1.-isH)*smoothstep(1.34,1.1,rho0)*step(.09,R);
  vec2 p1=spPen(rho0,th,.66+.06*pb,.02+.24*pb+.05*dfp,3.+floor(hp1*4.),psA*.6+hp1*TAU,px,1.6+3.4*pb);
  vec2 p2=spPen(rho0,th,.72,.015+.17*pm+.04*dfp,7.+2.*floor(hp2*4.),-uP1.y*dir+hp2*TAU,px,1.3+2.4*pm);
  vec2 p3=spPen(rho0,th,.92,.008+.09*ph+.03*dfp,17.+3.*floor(hp1*5.),psA*2.3,px,1.+1.4*ph);
  float nS=floor(8.+hp2*9.),aS=(fract(nS*th/TAU+psA*.3+.5)-.5)/nS*TAU*rho0;
  float spoke=(1.-smoothstep(.8,2.,abs(aS)/px))*smoothstep(mix(.5,1.2,1.-sn*sn),.3,rho0)*smoothstep(.0,.25,rho0-c0);
  // composited back to front: each pen has an ink outline, so it reads on top of the engraving without washing it out
  float g1=.4+.75*pb,g2=.36+.75*pm,g3=.3+.85*ph;   // (at rest they recede)
  vec3 pc=spc4*1.5*p1.x*g1;float ps=p1.y*g1;
  pc=pc*(1.-p2.y*g2)+spc1*1.5*p2.x*g2;ps=1.-(1.-ps)*(1.-p2.y*g2);
  pc=pc*(1.-p3.y*g3)+spc3*1.55*p3.x*g3;ps=1.-(1.-ps)*(1.-p3.y*g3);
  spPC=pc*pk+spoke*sn*1.8*spc2*pk;spPS=clamp(ps,0.,1.)*pk*.82;
#if HD>=1
  // (v19) a whole set of fine spirograph pens: thin rose curves laid as opaque ink, one palette hue each (every third pen is
  // dark), on its own band. Total pen coverage is capped so they never fill the medallion, and each is resolved at sub-pixel taps.
  float tpx=px*.82,pT=spPx/R;
  for(int k=SPK0;k<SPNP;k++){
    float fk=float(k),hk=spH(sd+fk*.13,fk*2.3+4.1),bp=spBand(mod(fk*1.7,8.)),aP=.34+.58*fract(hk*3.17+fk*.37),nP=5.+floor(hk*13.)*(1.+floor(fk*.34));
    float aA=.012+.07*fract(hk*9.1)+.16*bp*fract(hk*5.7),pPh=(mod(fk,2.)*2.-1.)*psA*(.7+fk*.25)+hk*TAU,cvP=0.;
    for(int t=SPK0;t<SPNT;t++){
      float ft=float(t)+.5;
      cvP+=spPen(rho0+(fract(ft*.7548)-.5)*pT,th+(fract(ft*.5698)-.5)*pT/max(rho0,.08),aP,aA,nP,pPh,tpx*1.6,0.).x;
    }
    float al=cvP/float(SPNT)*pk*(.42+.38*bp)*(1.-smoothstep(.26,.5,spPS));
    vec3 cP=step(mod(fk,3.),1.5)*spPick(floor(hk*5.))*(.85+.9*bp);
    spPC=spPC*(1.-al)+cP*al;spPS=1.-(1.-spPS)*(1.-al);
  }
#endif
  return o*kl*mix(1.,dome,occ);
}
// engraved emblem (a banknote vignette). Tone comes from the WIDTH of the engraved lines (lit = wide), never from
// blur; the relief normal and line widths come from screen derivatives, so this runs at the top level for every pixel
// (masked by the caller). e: emblem coords (outline near |e|=.9), th: its angle. ty < .34: a turning globe (latitude
// lines; meridians cross-hatch the lit side); .34-.67: the note's mascot, a grinning SUN engraved in guilloche
// (spSun); otherwise a faceted N-point star over a sunburst (facets hatched along their axis and parallel to their
// edges). All are computed and selected (no flow control).
// one engraved line family: u in line units, wl line width (fraction of the spacing), pxu line units per pixel;
// lines too fine for the pixels melt into their mean tone
// the mascot: a superflat sun face engraved in lines. Its two line families come from the emblem's shared engraving
// (c.x: wavy guilloche rings, width = the lit dome; c.y: hatching along each ray); here they are masked and coloured:
// a gold face, twelve alternating rays (turning with the music phase), a bold ink outline, happy eyes with sparkles,
// rosy cheeks and a big open grin whose mouth opens with the mids. f: -1..1 over the cameo, px: f units per pixel.
vec3 spSun(vec2 f,float px,vec2 c,float ri,float af){
  float r=length(f)+1e-5,Rf=.6;
  vec3 gold=vec3(1.,.74,.16),blush=vec3(1.,.3,.56),ink=mix(spc4,vec3(1.),.65);
  float hw=.13*clamp((.98-r)/.36,0.,1.),sdR=max(r*abs(af)-hw,Rf+.03-r);
  vec3 col=smoothstep(px,-px,sdR)*c.y*mix(spc0,spc2,mod(ri,2.))*1.6;
  vec2 e1=vec2(abs(f.x)-.2,f.y-.1);float sdE=(length(e1/vec2(.068,.1))-1.)*.068;
  float mo=.07+.13*spBand(3.);vec2 m=f-vec2(0.,-.1);
  float sdM=max((length(m/vec2(.3,mo))-1.)*mo,m.y),sdT=max(length(m-vec2(0.,-mo))-.13,sdM);
  float ck=smoothstep(px,-px,length(vec2(abs(f.x)-.36,f.y+.06))-.09);
  spFM=max(smoothstep(px,-px,sdE),smoothstep(px,-px,sdM));   // (v19) eyes and mouth stay clean of the hairlines
  float face=smoothstep(px,-px,r-Rf)*(1.-spFM);
  col+=face*((1.-ck)*c.x*gold*1.25+ck*blush*.85);
  col+=(smoothstep(1.5*px,.2*px,abs(sdE))+smoothstep(1.6*px,.2*px,abs(sdM)))*ink+smoothstep(px,-px,sdT)*blush*.8
      +smoothstep(px,-px,length(e1-vec2(-.025*sign(f.x),.035))-.027);
  return col+smoothstep(.014+px,.014-px,abs(r-Rf))*ink*1.2;   // the bold ink outline
}
// (v19) the boss the emblem sits on: engine-turned sunburst rays and rose rings, in the dark parts only
vec3 spBoss(vec2 e,float th,float pu,float sd){
  float r=length(e)+1e-4;vec2 er=e/r;vec4 Jr=vec4(er*pu,vec2(-er.y,er.x)*pu/r);
  float hs=spH(sd,3.9),Nr=floor(5.+hs*4.)*24.,Rn=floor(4.+hs*5.);
  // two counter-wound spirals crossing in an engine-turned lattice, and lobed rose rings over them
  float s1=.26+.1*hs,u1=th/TAU+s1*r,u2=th/TAU-s1*r+uP1.x*.02;
  float ra=spHair(Nr*u1,Nr*length(Jr.zw/TAU+s1*Jr.xy))+spHair(Nr*u2,Nr*length(Jr.zw/TAU-s1*Jr.xy));
  float ri=spFL(r,th,20.,Rn*2.,.016+.02*hs,-uP1.y,0.,Jr);
  vec3 o=(ra*mix(spc3,spc4,.3)*.2+ri*mix(spc2,spc1,.5)*.2);
#if HD>=1
  for(int k=SPK0;k<SPNF+2;k++){
    float fk=float(k),hk=spH(sd+fk,fk+1.3);
    float rk=spFL(r,th,20.*(2.+fk*1.1),Rn*(fk+2.),.0035/(1.+.5*fk),(mod(fk,2.)*2.-1.)*uP1.x*(.4+fk*.2)+hk*TAU,0.,Jr);
    o+=rk*spCol(hk+fk*.17)*.11;
  }
#endif
  return o*smoothstep(.885,.915,r)*(1.+.9*uO1.x+.8*uB1.x+.9*uB2.z+.8*uO2.w);   // only the band outside the disc: the disc stays black
}
vec3 spEmb(vec2 e,float th,float ty,float a,float sd){
  float r=length(e)+1e-5,pu=max(length(vec2(dFdx(e.x),dFdy(e.x))),1e-5),sp=max(3.6*pu,.04),g0=step(ty,.34),gS=step(.34,ty)*step(ty,.67);
  vec2 s=e/.88;float nz=sqrt(max(1.-dot(s,s),.004));vec3 n0=vec3(s,nz);
  float i=floor(fract(sd*7.13)*2.999),sa=TAU/(5.+i+step(1.5,i));   // 5, 6 or 8 points
  float th2=th+a*.25,aa=th2-floor(th2/sa+.5)*sa;
  vec2 lp=r*vec2(cos(aa),abs(sin(aa)))-vec2(.9,0.),dd=normalize(.42*vec2(cos(sa*.5),sin(sa*.5))-vec2(.9,0.));
  float sdd=lp.x*dd.y-lp.y*dd.x;
  // relief height, outline (m > 0 inside) and the two engraved fields (the sun reuses the globe's disc outline)
  float g1=max(g0,gS),h=mix(max(-sdd,0.)*1.6,nz*.88,g1),m=mix(-sdd,.88-r,g1);
  float u1=mix(r*sin(aa)/sp,asin(clamp(dot(n0,vec3(.26,.93,.26)),-1.,1.))*max(3.,floor(.88/sp)),g0);
  float u2=mix(sdd/sp,(atan(dot(n0,vec3(.963,-.269,0.)),dot(n0,vec3(.0699,.2504,-.9655)))+a)*clamp(floor(2.75/sp)*2.,6.,48.)/TAU,g0);
  float kS=th*1.9099+a*.12,afS=(fract(kS)-.5)*.5236;   // the sun: wavy face rings and ray hatching
  u1=mix(u1,r/sp+.22*sin(th*9.+a*.3),gS);u2=mix(u2,r*afS/(sp*.75),gS);
  vec3 n=normalize(vec3(-dFdx(h)/pu,-dFdy(h)/pu,1.)),L=vec3(-.48,.6,.64);
  float sh=clamp(dot(n,L),0.,1.);
  vec2 w=vec2(length(vec2(dFdx(u1),dFdy(u1))),length(vec2(dFdx(u2),dFdy(u2))));
  vec2 d=abs(fract(vec2(u1,u2)+.5)-.5),lw=vec2(mix(.08+.14*gS,.58+.2*gS,sh),mix(.62*smoothstep(.5,.95,sh),.62,gS));
  vec2 c=mix(lw,smoothstep(lw*.5+w*.7,lw*.5-w*.7,d),smoothstep(.36,.22,w));
  float inm=smoothstep(-pu,pu,m);
  vec3 col=inm*(c.x*mix(spc3,spc1,sh)*1.2+c.y*mix(spc2,vec3(1.),.35))*(1.+.8*uO1.x+.5*uB1.x*sh*sh);
  col=mix(col,inm*spSun(e/.88,pu/.88,c,floor(kS),afS)*(1.+.6*uO1.x),gS);
  // (v19) a hairline a third of the pitch, engraved in the dark gaps once the pixels allow (zoom in: the emblem keeps going)
  float hgap=(1.-max(c.x,c.y))*(1.-smoothstep(.04,.26,dot(col,vec3(.33))))*(1.-gS*spFM);vec2 hd=abs(fract(vec2(u1,u2)*3.+.5)-.5),wh=w*3.;
  vec2 hc=(vec2(1.)-smoothstep(vec2(.05),wh*1.15+.05,hd))*smoothstep(vec2(.36),vec2(.16),wh);
  col+=inm*hgap*(hc.x*mix(spc3,spc1,sh)+hc.y*spc2)*.26*(1.-.4*gS);
#if HD>=1
  // a further hairline, nine to the pitch, in Native and above
  vec2 hd9=abs(fract(vec2(u1,u2)*9.+.5)-.5),wh9=w*9.;
  vec2 hc9=(vec2(1.)-smoothstep(vec2(.05),wh9*1.2+.05,hd9))*smoothstep(vec2(.36),vec2(.16),wh9);
  col+=inm*hgap*(hc9.x*spc1+hc9.y*spc3)*.09;
#endif
  return col+spCov(abs(m)/pu)*mix(spc4,vec3(1.),.3)*1.3;
}
// micro-ornament (v20: pattern, not text): 3x5 cell glyphs along a baseline; m.x along, m.y up from the baseline (0..m.z)
float spMicro(vec3 m){
  float u=m.z/6.,pxu=u/spPx,cx=m.x/(4.*u),ci=floor(cx),k=mod(ci,10.);
  vec2 gp=vec2((cx-ci)*4.,m.y/u-.5),c=floor(gp);
  float code=dot(vec4(12282.,21845.,10773.,23405.),vec4(equal(vec4(k),vec4(0,1,2,3))))
            +dot(vec4(9682.,19956.,128.,6105.),vec4(equal(vec4(k),vec4(4,5,6,7))))
            +dot(vec2(20613.,32447.),vec2(equal(vec2(k),vec2(8,9))));
  float b=(4.-c.y)*3.+c.x,on=mod(floor(code/exp2(14.-b)),2.)*step(c.x,2.)*step(0.,c.y)*step(c.y,4.);
  vec2 f=gp-c-.5;float d=max(abs(f.x),abs(f.y))-.43;
  return mix(.22,on*smoothstep(.6/pxu,-.6/pxu,d),smoothstep(1.,1.9,pxu));
}
// holographic foil: a diffraction rainbow with a fine grating and embossed motifs; it shimmers with the highs and a
// glint runs along it on hat/air onsets. f.x across (-1..1), f.y along (screen units), fw: half width
vec3 spFoil(vec2 f,float fw){
  float my=f.y/(fw*2.3),mi=floor(my+.5);vec2 mq=vec2(f.x,(my-mi)*2.3);
  float mr=length(mq)+1e-4,cx=mq.y/mr,st=mr-(.56+.16*cx*(16.*cx*cx*cx*cx-20.*cx*cx+5.));   // cos 5a as a polynomial
  float mo=spCov(abs(st)*fw/spPx);
  float t=f.y*1.7+f.x*.35+uP3.z*.07+.2*sin(f.y*6.+uP3.y*TAU)+.5*step(st,0.);
  vec3 rb=.5+.5*cos(TAU*(t+vec3(0.,.33,.67)));rb*=rb*1.3;
  float gsp=max(.0045,3.2*spPx*SPQ),gr=spLine((f.y+f.x*fw*.8)/gsp,spPx*1.3/gsp);
  float gl=exp(-pow((fract(f.y*.45-uP3.z*.16)-.5)/.03,2.))*(.5*uHat+1.3*uO2.w+.7*uO2.z);
  return rb*((.3+1.2*uB2.z)*(.55+.7*gr)+mo*(.6+.6*uB2.w))+gl*mix(vec3(1.),rb,.4)*2.2;
}
float gl0(float b){return .6+.9*b;}
// (v19) islands of finer printing in the paper; everywhere else it stays black
float spPrint(vec2 p){float s=sin(p.x*9.+spSd*9.)+sin(p.y*13.+spSd*5.)+.5*sin((p.x+p.y)*17.+spSd*13.);return smoothstep(HD>=1?.45:.95,HD>=1?.75:1.25,s);}
#if HD>=1
// (v19) an under-plate: a lattice of small rosettes printed under everything on the paper, one layer per tier, each finer and
// turned against the last (the same zone engine as the top print, one zone per pixel). Analytic Jacobian (loop-safe).
vec4 spUnder(vec2 p,float P,float sd,float ks){
  vec2 c=floor(p/P+.5),q=p-c*P;float hc=spH(c.x+c.y*17.1+sd*9.,ks+1.7),R=P*(.40+.09*hc),r=length(q)+1e-5,rho=r/R;
  if(rho>1.04||R<16.*spPx*SPSS)return vec4(0.);
  float th=spAt(q.y,q.x),zn=clamp(floor(R/(spPx*pow(SPSS,.75))/6.5),2.,7.),zf=rho*zn,zi=floor(zf),v=zf-zi;
  float ps=uP1.x*(1.-2.*mod(c.x+c.y,2.))*(.6+ks*.15);
  vec4 J=vec4(q/r*zn/R*spPx,vec2(-q.y,q.x)/(r*r)*spPx);
  float a=0.;
  if(rho<1.){
    for(int i=SPK0;i<SPNH;i++){   // hairline families per ring: thin ink, one hue per rosette
      float fi=float(i),h=spH(hc+fi*.7,zi+ks*2.3),N=7.+floor(h*12.),circ=TAU*(zi+.5)/zn*R,n=max(2.,floor(circ/(.026+.02*h)))+fi*3.;
      a=max(a,spFL(v,th,N,n,.06+.11*h,(1.-2.*mod(fi,2.))*ps*(fi+1.)+h*TAU,(fi-1.)*1.6,J));
    }
    a*=smoothstep(1.,.92,rho)*smoothstep(0.,.1,rho);
  }
  float sep=spHair(zf,zn/R*spPx*1.1);
  return vec4(spPick(floor(hc*5.+ks)),max(a,max(sep*.8*step(rho,1.),spHair((rho-1.)*R/spPx,1.)*step(rho,1.02))));
}
#endif
vec3 spBg(vec2 p){
  vec3 base=mix(spc3,spc0,.5+.5*sin(p.x*.9+p.y*.4))*.012;   // faint iris printing
  float bgb=spBand(1.),k=TAU/.21,a=.026*(1.+2.5*bgb),sp=max(HD>=2?.0175:.0125,5.*spPx*SPQ);
  float l=spLine((p.y+a*sin(p.x*k+uP1.x))/sp,spPx*length(vec2(a*k*cos(p.x*k+uP1.x),1.))/sp);
  vec3 pc=mix(spc2,spc4,.5+.5*sin(p.x*1.1+p.y*.6+uP3.y*TAU));
  vec3 c=base+l*(.3+.18*bgb)*smoothstep(.0034,.0018,spPx)*pc;
  // (v19) paper: a second, widely spaced wave family crossing the first. The paper stays black between the lines; finer ground
  // printing is confined to islands (spPrint), so large areas of deep black always remain, at every tier.
  float k2=TAU/.35,a2=.02*(1.+1.8*spBand(3.)),l2=spHair((p.x+a2*sin(p.y*k2-uP1.y))/.0135,spPx*length(vec2(a2*k2*cos(p.y*k2-uP1.y),1.))/.0135);
  float pm=spPrint(p);
  c=mix(c,spc3*(1.+1.1*uB1.x),l2*.3*pm);
  float k3=TAU/.17,a3=.008,l3=spHair((p.x+p.y*.6+a3*sin((p.y-p.x)*k3+uP1.x))/.0052,spPx*1.17/.0052);
  c=mix(c,pc*(1.+1.5*spBand(6.)+2.*spHat),l3*.3*pm);
#if HD>=1
  for(int k4=SPK0;k4<SPNF;k4++){
    if(pm<.003)break;
    float fk=float(k4),hk=spH(fk,7.7),ki=TAU/(.11+.2*hk),dd=(.0058/(1.+.25*fk))+.0002,ai=.012*(1.+hk),an=(fk+1.)*1.13,ca=cos(an),sa=sin(an);
    float pa=ca*p.x+sa*p.y,pb=-sa*p.x+ca*p.y;
    float li=spHair((pb+ai*sin(pa*ki+(mod(fk,2.)*2.-1.)*uP1.x))/dd,spPx*length(vec2(ai*ki*cos(pa*ki+uP1.x),1.))/dd);
    c=mix(c,spPick(floor(hk*5.)),li*.3*pm);
  }
#endif
  return c;
}
void realm(){
  // realm camera (JS): uP1.w zoom (pulls back over the sheet in breakdowns and tours, pushes in on builds),
  // uP2.z drift phase along a path over the sheet while pulled back
  float cz=uP1.w,Zm=uZoom*cz,pull=clamp((.88-cz)*2.6,0.,1.);
  vec2 sc0=scr();
  float ax=.5*uRes.x/uRes.y,dw=length(sc0)/length(vec2(ax,.5));
  float dfl=uP5.x-2.*floor(uP5.x*.5);
  vec2 p=rot(-uP5.z)*sc0/Zm+pull*vec2(1.75*sin(uP2.z),1.*sin(.71*uP2.z+1.));
  float pk5=floor(uP5.x*.5);spKW=mod(pk5,64.)/63.;spHS=floor(pk5/64.+.001);
  spDt=clamp(uDetail,1.,16.);spPx=1./(uRes.y*Zm);spLW=(1.2+.55*spKW)*pow(SPSS,.5);spHat=max(uHat,uO2.w)*.8;spHp=uP3.z;spLA=clamp(uM1[2][2]+.5*uO2.x*uM1[2][2]+.25*uO2.x,0.,1.2);
  // the wipe that sweeps a new design in: radial, a left-to-right press, or venetian blinds
  float wt=floor(uP3.x/16.),wr=uP3.x-16.*wt;
  dw=mix(dw,mix((sc0.x+ax)/(2.*ax),fract((sc0.x+sc0.y)*2.2)*.45+(sc0.x+ax)/(2.*ax)*.55,step(1.5,wt)),step(.5,wt));   // radial, press, blinds
  bool nw=dw<wr;
  float sd=nw?uP4.y:uP4.x,code=nw?uP4.w:uP4.z;
  float lay=floor(code/64.+.001),sub=mod(floor(code/16.+.001),4.);
  spSetPal(nw);
  // the uncut sheet: notes (1.8 x 1 with gutters) in 3x3 blocks, blocks separated by wide engraved bands
  const vec2 NP=vec2(1.8,1.);const float BW=.34;
  vec2 SP=3.*NP+BW,si=floor(p/SP+.5),xs=p-si*SP,ni=clamp(floor(xs/NP+.5),-1.,1.),q=xs-ni*NP,cell=si*3.+ni;
  float ch=h21(cell+vec2(fract(sd*7.7)*31.,7.3)),isC=step(dot(cell,cell),.5);
  lay=mix(floor(ch*5.999),lay,isC);sub=mix(floor(fract(ch*13.1)*2.999),sub,isC);
  float nsd=mix(fract(sd+ch*.618),sd,isC),side=step(.5,fract(ch*5.3+sd*3.1))*2.-1.;
  spSd=sd;vec3 col=spBg(p);float so=0.,soT=0.,sDy=1.,sF=0.,sP=1.,sO=0.,sI=0.;vec2 sL=vec2(0.,1.);
  float br=uP1.z;
  vec2 aq=abs(q),sq=step(0.,q)*2.-1.,ab=abs(xs)-1.5*NP;
  bool mOn=false;vec2 mq=q;float mR=.1,msd=nsd,mdir=1.,mh=1.,mhub=0.,mP=1.;
  // strip zone parameters: v across (0..1), X along (radians), width, period, band, colour offset, fade, design scale
  float zv=.5,zX=0.,zw=.1,zc=1.,zb=0.,zt=0.,zf=0.,zds=1.,zcy=.12,zps=1.;int zz=20;
  vec3 mt=vec3(0.,-1.,1.);
  const float W=.878,H=.478;
  float fx=9.,fw=.034,inN=0.,kbS=0.,upM=1.;vec3 nl=vec3(0.);
  if(max(ab.x,ab.y)>0.){
    // wide band between blocks: a symmetric woven frieze running around the block
    float hz=step(ab.x,ab.y),ed=mix(ab.x,ab.y,hz),al=mix(xs.y,xs.x,hz);
    zv=ed/(BW*.5);zX=al*TAU/.24+uP3.w*TAU*(1.-2.*hz);zw=BW*.5;zc=.24;zb=3.;zt=spH(sd,2.3);zf=.9;zcy=.15;zds=1.4;zz=23;nsd=sd;
    so=(spCov(abs(ed-.004)/spPx)+spCov(abs(ed-.009)/spPx))*1.1;soT=al*.3;
    {float bP=mix(1.67/4.,2.87/7.,hz),bc=floor(al/bP+.5),bpz=1.+.22*spBand(mod(bc+8.,8.));vec2 bq=vec2(al-bc*bP,BW*.5-ed);
     if(length(bq)<.132*bpz){mOn=true;mq=bq;mR=.118*bpz;mP=bpz;msd=fract(sd+.13+mod(bc+8.,3.)*.21);mdir=1.-2.*mod(bc+8.,2.);mh=1.1;mhub=0.;}}
  }else if(aq.x>W||aq.y>H){
    // gutter: crop marks and plate microtext
    vec2 gq=aq-vec2(W,H);float rr=min(gq.x,gq.y);
    so=spCov(abs(gq.x)/spPx)*step(.003,gq.y)*step(gq.y,.012)+spCov(abs(gq.y)/spPx)*step(.003,gq.x)*step(gq.x,.012);
    soT=.3;
    if(rr<0.)mt=gq.y>0.?vec3(q.x+cell.x*1.3+4.,gq.y-.0055,.011):vec3(q.y+cell.y*.9+4.,gq.x-.0055,.011);
  }else{
    inN=1.;
    float e=min(W-aq.x,H-aq.y),hz=step(H-aq.y,W-aq.x),al=mix(-q.y*sq.x,q.x*sq.y,hz);
    const float b0=.009,bw=.05,mt0=.066,mth=.0125,fi=.087;
    vec2 cq=q-sq*vec2(W-.035,H-.035);
    kbS=uP2.y*exp(-pow((aq.x/W-uP2.x*.7)/.06,2.));
    if(length(cq)<.094){float pc=1.+.25*spBand(3.5+1.5*sq.x+sq.y);mP=pc;mOn=true;mq=cq;mR=.07*pc;msd=fract(nsd+.71);mdir=sq.x*sq.y;mh=1.;}
    else if(e<fi){
      // frame: outer rules, a guilloche border whose waves circulate around the note, a microtext band
      vec2 nO=mix(vec2(sq.x,0.),vec2(0.,sq.y),hz);float bev=.8+.32*dot(nO,vec2(-.6,.75));
      so=(spCov(abs(e-.0028)/spPx)+spCov(abs(e-.006)/spPx)*.7+spCov(abs(e-mt0+.0028)/spPx)+spCov(abs(e-mt0-mth-.0028)/spPx))*bev;
      soT=al*.5;
      if(e>=b0&&e<b0+bw){zv=(e-b0)/bw;zX=al*TAU/.2+uP3.w*TAU;zw=bw;zc=.2;zb=4.;zt=spH(nsd,3.3);zf=bev;zcy=.15;zds=1.2;zz=20;}
      if(e>mt0&&e<mt0+mth)mt=vec3(al+3.,mt0+mth-e,mth);
    }else if(lay>3.5){
      // SPIROGRAPH GARDEN: a row of five nested-petal rosettes, each blooming open with its own band (bass at the left ..
      // air at the right), turning in alternate directions, over a ground of wave rings around the note's centre
      col*=.2;upM=0.;
      float fsp=max(.0105,4.4*spPx*SPQ),fk=clamp(floor(q.x/.33+.5),-2.,2.),bnd=spBand(fk+3.);
      vec2 da=q-vec2(fk*.33,.07*(mod(fk,2.)*2.-1.)*(1.+.9*bnd));float ra=length(da)+1e-4,ta=spAt(da.y,da.x);
      // nested petal outlines u = N r / Rf(theta), two strands half a petal apart
      float Rg=.165*br,e=.25+.6*bnd,kg=4.+floor(spH(nsd+fk,3.3)*5.),Ng=floor(.165/fsp),ct=cos(kg*(ta+uP1.x*(1.-2.*mod(fk,2.))));
      float R1=Rg*(1.-.5*e+.5*e*ct),R2=Rg*(1.-.5*e-.5*e*ct),g1=Ng*ra/R1,g2=Ng*ra/R2,inF=step(ra,Rg*1.12),rq=length(q);
      float lA=spLine(mix(rq/fsp+.3*sin(q.x*9.+q.y*5.+uTime*.2),g1,inF),mix(1.05,Ng*1.15*fsp/R1,inF)*spPx/fsp)*mix(1.,step(g1,Ng+.5),inF);
      float lB=spLine(g2,Ng/R2*spPx*1.15)*step(g2,Ng+.5)*inF;
      float fade=smoothstep(.02,.06,min(W-aq.x,H-aq.y)-fi),kb=(ra/Rg-uP2.x)*8.3;
      // (v19) filigree: a finer petal family between the petals and fine rings on the ground around them
      float kf=kg*2.+1.,ctf=cos(kf*(ta-uP1.x*.5)),Rf=Rg*(.74+.26*ctf*(.55+.45*bnd)),uf=Ng*2.*ra/Rf,lfi=spHair(uf,Ng*2.3/Rf*spPx*1.15)*step(uf,Ng*2.+.5)*inF;
      float lgr=spHair(rq/(.5*fsp)+.5*sin(q.x*14.-q.y*9.-uTime*.13),spPx/(.5*fsp)*1.05)*(1.-inF);
      float rv=(ra-Rg*1.1)/(Rg*.13),rm=step(0.,rv)*step(rv,1.),Mr=floor(TAU*Rg*1.16/max(.0075,3.8*spPx*SPQ));
      float reed=spLine(ta/TAU*Mr+rv*(1.+2.5*bnd)*(1.-2.*mod(fk,2.)),Mr/TAU/ra*spPx*1.25)*rm;
      lA*=1.-rm*(1.-inF);lgr*=1.-rm;
      nl+=(reed*spPick(fk+3.)*(.45+1.1*bnd)+spCov(abs(ra-Rg*1.245)/spPx)*.55*spc4)*fade;
      nl+=(lfi*spPick(fk+1.)*(.5+.5*bnd)*gl0(bnd)+lgr*.2*spc3)*fade;
      float gl=mix(.6,.55+.9*bnd+1.2*uP2.y*max(1.-kb*kb*.4,0.),inF);   // the kick ring rides out through each flower
      nl+=(lA*mix(mix(spc2,spc3,.5+.5*sin(rq*5.-uTime*.1)),spPick(fk+2.),inF)+lB*spPick(fk+4.))*fade*gl*1.05;
      // the hubs: a jewel per flower, and a fine stem ring under each
      nl+=(spCov(abs(ra-Rg*1.08)/spPx)*.6*spc4+smoothstep(.02,.012,ra)*mix(spc4,vec3(1.),.4)*(1.+2.*uO1.x))*fade;
    }else if(lay<.5){
      // one grand medallion holding an emblem, two satellite rosettes counter-rotating beside it
      mOn=true;mR=.355*br;mP=br;mh=1.26;mhub=1.;fx=.6*side;
      vec2 sq2=q-vec2(sq.x*.63,0.);
      if(length(q)>mR*1.03&&length(sq2)<.18){float ps2=br*(1.+.3*spBand(4.+2.*side*sq.x));mP=ps2;mq=sq2;mR=.135*ps2;msd=fract(nsd+.61);mdir=-1.;mh=1.08;mhub=0.;}
    }else if(lay<1.5){
      // tiled medallions: rows slide in opposite directions, neighbours counter-rotate like gears.
      // sub 0: big and small alternate; sub 1: a hero emblem medallion holds the centre and the passing satellites
      // shrink around it; sub 2: both. The tile scale breathes per phrase (uP5.y).
      float ts=uP5.y,py=.4*ts,pp=.46*ts,row=floor(q.y/py+.5),rd=1.-2.*step(.5,mod(row,2.));
      float off=rd*uP3.w*pp+(.5-.5*rd)*.5*pp,xo=q.x+off,cc=floor(xo/pp+.5);
      float tb2=spBand(mod(cc+row*3.,8.));   // (v18) every tile rides its own band, columns bob opposite ways on the bass
      mq=vec2(xo-cc*pp,q.y-row*py+(mod(cc,2.)*2.-1.)*.28*(br-1.)*ts);mh=1.12;
      float tR=.163*br*ts,sz=1.-.4*float(sub!=1.)*step(.5,mod(cc+row,2.));
      float hR=.33*br,hd=length(vec2(cc*pp-off,row*py));
      sz*=mix(1.,smoothstep(hR*1.1,hR*1.1+tR*1.6,hd-tR*.2),step(.5,sub));
      mR=tR*sz*(1.+.3*tb2);
      msd=fract(nsd+mod(cc+row*2.,3.)*.318);mdir=1.-2.*step(.5,mod(cc+row,2.));
      mOn=mR>.012&&length(mq)<mR*1.13;
      float hz2=step(.5,sub)*step(length(q),hR*1.16);   // inside the hero (exact selects: msd feeds hashes)
      mOn=mOn||hz2>.5;mq=mix(mq,q,hz2);mP=mix(br*(1.+.3*tb2),br,hz2);mR=mR*(1.-hz2)+hR*hz2;mh=1.12+.04*hz2;msd=msd*(1.-hz2)+fract(nsd+.43)*hz2;mdir=mdir*(1.-hz2)-hz2;mhub=hz2;
      fx=.43*side;
    }else{
      // banknote (2): a ribbon between engraved panels, a portrait medallion, a rosette left, foil right
      // triptych (3): one engraved field, the portrait medallion between two counter-rotating rosettes
      float tri=step(2.5,lay),yi=H-fi,pn=step(.125,aq.y);
      zv=mix(mix((q.y+.125)/.25,(aq.y-.125)/(yi-.125),pn),(q.y+yi)/(2.*yi),tri);
      zX=mix(mix(q.x*TAU/.3-uP3.w*PI,q.x*sq.y*TAU/.16+uP3.w*TAU,pn),q.x*TAU/.26+uP3.w*TAU,tri);
      zw=mix(mix(.25,yi-.125,pn),2.*yi,tri);zc=mix(mix(.3,.16,pn),.26,tri);zb=mix(mix(2.,6.,pn),5.,tri);
      zt=spH(nsd,4.4+pn*1.1+tri*2.);zf=mix(mix(.55,.24,pn),.36,tri)*(1.+1.5*kbS);zcy=.1;zds=mix(mix(1.7,2.3,pn),2.1,tri);zz=21+int(pn)+2*int(tri);
      float rp=max(.012,4.5*spPx*SPQ);sDy=aq.y-.125;sF=q.x/rp;sP=rp;sO=.0025;sI=.9*(1.-tri);sL=vec2(-.48,.6*sq.y);
      float Rc=.3*br,sx=mix(-.6,.58*sq.x,tri),ds=length(vec2(q.x-sx,q.y));fx=mix(.6,.3*side,tri);
      if(length(q)<Rc*1.24){mOn=true;mR=Rc;mP=br;mh=1.22;mhub=1.;}
      else if(ds<.2){mOn=true;mq=vec2(q.x-sx,q.y);mR=mix(.15,.17,tri)*br;msd=fract(nsd+.37+.2*step(0.,q.x));mdir=mix(-1.,-sq.x,tri);mh=1.18;mP=br;}
    }
  }
  SpG gs=SpG(zv,zX,zw,zc,zb,zt,uP1.x*zps,uP1.y*zps,zf,zcy,zds,0.,zz,nsd);
  // strips carry a latent row of diamonds
  gs.lt=smoothstep(.06,0.,abs(fract(zX/TAU*.5)-.5)*1.7+abs(zv-.5)*1.6-.62);
  vec3 o=vec3(0.),rc=vec3(0.);float occ=0.;SpG gm=spG0();vec3 mtm=vec3(0.,-1.,1.);vec4 rs=vec4(1.);
  float thq=atan(mq.y,mq.x);
  spPump=mP;spPC=vec3(0.);spPS=0.;
  if(mOn){o+=spMedGeo(mq,thq,mR,msd,mdir,mh,mhub,gm,occ,mtm,rs,rc);if(mtm.y>=0.)mt=mtm;}
  // one bead-chain separator per pixel: the medallion's ring or the strip's, whichever is nearer
  float ur=float(mOn&&(sI<=0.||abs(rs.x)<abs(sDy)));
  float sl=spSep(mix(sDy,rs.x,ur),mix(sF,rs.y,ur),mix(sP,rs.z,ur),mix(sO,rs.w,ur),mix(sL,vec2(.48*sin(thq)+.6*cos(thq),.6*sin(thq)-.48*cos(thq)),ur));
  sl*=1.+.7*(uB2.z+uB2.w)+1.4*spHat;o+=sl*ur*rc;so+=sl*(1.-ur)*sI;
  // the medallion plate sits above the paper and casts a soft shadow to the lower right
  float shd=mOn?smoothstep(1.08,.96,length(mq/mR-vec2(.035,-.05)))*(1.-occ):0.;
  // one zone evaluation per pixel (keeps the D3D compile small): the medallion wins inside its rim and in the
  // inner part of its halo; where a strip lies under the halo, the halo fades out by mid-way and the strip takes over
  SpG g=gs;
  if(mOn&&gm.fade>.003&&(occ>.5||gs.fade<.003||gm.v<.5)){
    if(occ<.5&&gs.fade>.003)gm.fade*=smoothstep(.5,.15,gm.v);
    g=gm;
  }
  // derivatives in uniform control flow: zone coordinates (angle wrapped) and the emblem
  vec2 dX=vec2(dFdx(g.X),dFdy(g.X));dX-=TAU*floor(dX/TAU+.5);
  float hub=step(float(gm.zi),-.5)*float(mOn);   // the hub is the emblem's dark boss: no strip shows through
#if HD>=1
  // (v19) the top zone is evaluated at many analytic sub-pixel taps from Native up: crossing hairlines and ornament resolve cleanly
  vec4 Jg=vec4(dFdx(g.v),dFdy(g.v),dX);vec3 zs=vec3(0.);
  for(int si=SPK0;si<SPNS;si++){
    float fi=float(si)+.5;vec2 t0=vec2(fract(fi*.7548)-.5,fract(fi*.5698)-.5);SpG g2=g;g2.v+=dot(t0,Jg.xy);g2.X+=dot(t0,Jg.zw);
    zs+=spZone(g2,Jg);
  }
  o+=zs/float(SPNS)*step(.003,g.fade)*(1.-hub);
#else
  o+=spZone(g,vec4(dFdx(g.v),dFdy(g.v),dX))*step(.003,g.fade)*(1.-hub);
#endif
  float ety=spH(msd,6.6);ety=mix(ety,.5,step(1.5,lay)*step(lay,3.5)*mhub*step(.25,ety));   // banknote/triptych heroes: mostly the sun mascot
  vec3 emb=spEmb(mq/max(gm.wid,1e-3),thq,ety,uP1.y*mdir*.7,msd)*(1.+.25*uB1.x+.7*uO1.x);
  o+=hub*emb;
  o+=hub*spBoss(mq/max(gm.wid,1e-3),thq,spPx/max(gm.wid,1e-3),msd)*(1.-smoothstep(.02,.22,dot(emb,vec3(.33))));
  o=o*(1.-spPS)+spPC;
  col=col*(1.-.8*occ)*(1.-.6*shd)+so*(1.-occ)*spCol(soT+uP3.y)*(1.+1.6*uP2.w+1.6*uP2.y)+o+nl*(1.+1.2*uP2.w);
  // (v12) zoomed out, each 3x3 block of notes carries a giant guilloche rosette engraved over it: two rose-engine line
  // families crossing in lace, their lobes blooming with the band of their sector (bass at the top .. air at the
  // bottom, mirrored), turning with the snare jolt, lit by the air band, with the kick ring riding out through it.
  // It is engraved into the paper between the notes' own lines, so the block reads as one big composition of small notes.
  float fz=smoothstep(.34,.16,Zm);
  if(fz>.001){
    float rb=length(xs)+1e-4,tb=spAt(xs.y,xs.x),Rb=1.62,sg=max(.07,11.*spPx*SPQ),sx=abs(tb)/PI*7.;
    vec3 tw0=max(1.-abs(sx-vec3(0.,1.,2.)),0.),tw1=max(1.-abs(sx-vec3(3.,4.,5.)),0.);vec2 tw2=max(1.-abs(sx-vec2(6.,7.)),0.);
    float bl=dot(uM1[0],tw0)+dot(uM1[1],tw1)+dot(uM1[2].xy,tw2),am=(.2+1.*bl)*min(rb/Rb*1.6,1.),kk=floor(8.+5.*spH(sd,2.9));
    float ph=uP1.x*.5,r1=rb/sg,wq=spPx*length(vec2(1./sg,am*kk/rb));
    // (crisp 1.2 px lines with no glow halo; they vanish rather than melt into a haze when too dense)
    float wi=1./max(wq,1e-5),lk=smoothstep(2.5,5.,wi),l1=spCov(abs(fract(r1+am*sin(kk*tb+ph)+.5)-.5)*wi)*lk,l2=spCov(abs(fract(r1+am*sin(kk*tb-ph+PI)+.5)-.5)*wi)*lk;
    float msk=smoothstep(.2,.3,rb/Rb)*smoothstep(1.02,.94,rb/Rb),kr=uP2.y*exp(-pow((rb/Rb-uP2.x*.3)/.07,2.));
    vec3 lc=(spCol(rb*.35+uP3.y+.5)*l1*(.5+.5*bl+.5*uB2.z+.4*uB2.w+1.2*kr)+spc4*l2*min(2.*kr,1.))*(1.-inN);
    col=max(col,lc*fz*msk*.95);   // (max: the rosette fills the paper between the notes' lines, never washes them)
    // the rosette's rim: a rule that flashes on the kick
    col+=fz*spCov(abs(rb-Rb)/spPx)*spc4*(1.2+2.5*uP2.y);
  }
  if(mt.y>=0.&&mt.y<=mt.z)col+=spMicro(mt)*mix(spc1,vec3(1.),.3)*(.8+1.6*uB2.y);
#if HD>=1
  // (v19) the under-plates: rosette lattices printed in the dark of the paper. Paid per pixel, shown only where the print
  // above leaves the paper dark, so the top print stays clean.
  float pmU=spPrint(p)*(1.-occ)*upM,cvU=0.;vec3 uP0=vec3(0.);
  if(pmU>.003){
    for(int ul=SPK0;ul<SPNL;ul++){
      float fl=float(ul);vec4 u=spUnder(rot(.35+fl*1.13)*p+vec2(.13,.09)*(fl+1.),.5*pow(.72,fl),sd,fl);
      float al=u.a*(1.-smoothstep(.3,.6,cvU));   // total ink coverage is capped
      uP0=uP0*(1.-al)+u.rgb*al;cvU=1.-(1.-cvU)*(1.-al);
    }
    float aU=pmU*(1.-smoothstep(.015,.17,dot(col,vec3(.2126,.7152,.0722))));
    col=col*(1.-cvU*aU)+uP0*aU*.8;
  }
#endif
  // holographic foil strip laid over the note
  float fd=abs(q.x-fx);
  if(inN>.5&&fd<fw+spPx*2.){
    float fm=smoothstep(fw+spPx,fw-spPx,fd),fe=spCov(abs(fd-fw)/spPx);
    col=mix(col,spFoil(vec2((q.x-fx)/fw,q.y),fw),.62*fm)+fe*vec3(.9,.85,.8)*.6;
  }
  // (v18) the kick: a soft wave of light crossing the whole note (a moving ring, never a full-frame flash)
  col*=1.+(.12+.3*smoothstep(.2,.7,Zm))*uP2.y*exp(-pow((length(q)/.9-uP2.x*.28)/.16,2.));
  // (v18) hats: four-point stars twinkling on a seeded lattice; each hat lights a different fifth of the cells
  float stS=max(.09,14.*spPx);vec2 stI=floor(p/stS),stF=p/stS-stI-.5;
  float stH=spH(stI.x+stI.y*57.13,spHS+1.3),stH2=spH(stI.y,stI.x+3.1);
  vec2 stD=abs(stF-(vec2(stH2,fract(stH2*7.7))-.5)*.5)*stS/spPx;
  float stL=(4.+uRes.y*.03)*(.5+.8*uHat);
  float star=exp(-stD.x/stL*2.2-stD.y*.9)+exp(-stD.y/stL*2.2-stD.x*.9)+.8*exp(-dot(stD,stD)*.25);
  col+=star*step(.8,stH)*(uHat+.7*uO2.w)*mix(spc4,vec3(1.),.65)*1.6;
  // the drop wipe: a bright engraving front sweeping the new design in
  float fr=step(wr,1.6)*exp(-pow((dw-wr)/.012,2.));
  col+=fr*(mix(spc1,spc3,.5+.5*sin(dw*TAU+uP3.y*TAU))*2.5+.4);
  col*=(1.+dfl*.3)*.8;float lqc=dot(col,vec3(.2126,.7152,.0722));col=max(lqc+(col-lqc)*(HD>=1?1.38+.04*float(HD):1.46),0.);
  fragColor=vec4(col,0.);
}
`;
