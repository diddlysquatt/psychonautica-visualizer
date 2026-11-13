const R_LATTICE = `
// LED 06: flying THROUGH a hyperbolic {p,q,r} honeycomb in the Poincare ball. The camera sits at the ball's
// centre; JS moves the world past it with a Lorentz matrix (renormalised by exact honeycomb symmetries, so the
// flight never ends). Cells are folded back to the central cell with the Coxeter mirrors (3 planes + 1 sphere);
// edges are LED tubes, vertices LED bulbs, faces stained-glass membranes that carry their own nested {Ps,Qs}
// hyperbolic tiling. Cells shrink toward the sphere at infinity: an endless regress in every direction.
vec3 hA,hB,hC,hF,hS,hV,hP1,hP2,hE1,hE2,hCp;float hRho,hRc,hRin;
float sCx,sRr,sInr;vec2 sN,sV;
// D3D compile cost: the HLSL compiler expands every call site inline and unrolls constant-trip loops. Loops start
// at LED0, a zero it cannot fold (uTime>=0); the membrane shading and the normal taps each use one expansion.
// The normal keeps its original expression; only the four map values are gathered in the loop.
#define LED0 min(int(uTime),0)

vec3 mtr(vec3 x,vec3 a){float ax=dot(a,x),x2=dot(x,x),a2=dot(a,a);return ((1.+2.*ax+x2)*a+(1.-a2)*x)/(1.+2.*ax+a2*x2);}
void hcon(float p,float q,float r){
  hA=vec3(1,0,0);hC=vec3(0,0,1);
  float cp=cos(PI/p),cq=cos(PI/q);
  hB=vec3(-cp,sqrt(max(1.-cp*cp-cq*cq,1e-5)),-cq);
  hF=normalize(cross(hA,hB));if(dot(hF,hC)>0.)hF=-hF;
  vec3 ve=normalize(cross(hB,hC));if(dot(ve,hA)>0.)ve=-ve;
  vec3 me=normalize(cross(hA,hC));if(dot(me,hB)>0.)me=-me;
  float k=abs(dot(hF,hC)),cr=cos(PI/r);
  float D=cr/sqrt(max(cr*cr-k*k,1e-6));hRho=sqrt(D*D-1.);hS=hF*D;
  float e=dot(ve,hS);hV=ve*(e-sqrt(max(e*e-1.,0.)));
  float h=dot(hS,hC);hCp=hS-h*hC;hRc=sqrt(max(hRho*hRho-h*h,0.));
  hP2=hF*(D-hRho);
  float m=dot(me,hS);vec3 P1=me*(m-sqrt(max(m*m-1.,0.)));hP1=P1;
  hE1=normalize(P1-dot(P1,hF)*hF);hE2=cross(hF,hE1);
  hRin=length(mtr(P1,-hP2));
}
void tcon(float P,float Q){
  float A=PI/P,sA=sin(A),cA=cos(A),cB=cos(PI/Q);
  sRr=sA/sqrt(max(cB*cB-sA*sA,1e-4));sCx=sqrt(sRr*sRr+1.);sN=vec2(-sA,cA);sInr=sCx-sRr;
  float t=sCx*cA-sqrt(max(sCx*sCx*cA*cA-1.,0.));sV=vec2(cA,sA)*t;
}
// v14: warm-started Coxeter fold. Along a ray the honeycomb symmetry that carries a sample into the central
// chamber changes only when the ray crosses a cell wall, so the group element is cached in gG (a Lorentz
// matrix, one per pixel) and each sample is mapped by it first. Usually the mapped point is already inside
// the chamber and the loop exits after one test; the few reflections still needed are composed into gG, so
// the cache stays exact - folding any image of w lands on the same chamber point.
mat4 gG;
vec3 gApply(vec3 w){
  float r2=dot(w,w),o=1.+r2;
  vec3 b=gG[3].xyz,c=vec3(gG[0].w,gG[1].w,gG[2].w);
  return (2.*(mat3(gG)*w)+b*o)/max((1.-r2)+2.*dot(c,w)+gG[3].w*o,1e-9);
}
void gComp(vec4 N,vec4 e){ // gG <- R gG, R = I - 2 N transpose(e) (a plane or the face sphere; N.e = 1)
  gG[0]-=2.*N*dot(e,gG[0]);gG[1]-=2.*N*dot(e,gG[1]);gG[2]-=2.*N*dot(e,gG[2]);gG[3]-=2.*N*dot(e,gG[3]);
}
vec3 hFold(vec3 w,float pxs,float pmax,out float bail){
  float x0d=max(1.-dot(w,w),1e-7);bail=0.;
  vec3 x=gApply(w);
  for(int i=LED0;i<144;i++){
    if(float(i)>=48.+6.*clamp(uDetail,.5,16.))break;
    float done=1.,d;
    // the two axis mirrors are exact sign flips (hA = x, hC = z): compose them without a matrix product
    if(x.x>0.){x.x=-x.x;done=0.;gG[0].x=-gG[0].x;gG[1].x=-gG[1].x;gG[2].x=-gG[2].x;gG[3].x=-gG[3].x;}
    d=dot(x,hB);if(d>0.){x-=2.*d*hB;done=0.;gComp(vec4(hB,0.),vec4(hB,0.));}
    if(x.z>0.){x.z=-x.z;done=0.;gG[0].z=-gG[0].z;gG[1].z=-gG[1].z;gG[2].z=-gG[2].z;gG[3].z=-gG[3].z;}
    vec3 v=x-hS;float l2=dot(v,v);
    if(l2<hRho*hRho){x=hS+v*(hRho*hRho/max(l2,1e-18));done=0.;gComp(vec4(hS/hRho,1./hRho),vec4(hS/hRho,-1./hRho));
      if(pxs*(1.-dot(x,x))/x0d>pmax){bail=1.;break;}}
    if(done>.5)break;
  }
  return x;
}
vec2 foldS(vec2 z,float pxs,float pmax,out float par,out float bail){
  float z0d=max(1.-dot(z,z),1e-7);par=0.;bail=0.;
  for(int i=LED0;i<112;i++){
    if(float(i)>=32.+5.*clamp(uDetail,.5,16.))break;
    float done=1.;
    if(z.y<0.){z.y=-z.y;par+=1.;done=0.;}
    float dn=dot(z,sN);
    if(dn>0.){z-=2.*dn*sN;par+=1.;done=0.;}
    vec2 v=z-vec2(sCx,0.);float l2=dot(v,v);
    if(l2<sRr*sRr){z=vec2(sCx,0.)+v*(sRr*sRr/max(l2,1e-18));par+=1.;done=0.;
      if(pxs*(1.-dot(z,z))/z0d>pmax){bail=1.;break;}}
    if(done>.5)break;
  }
  return z;
}
vec3 iso(vec3 x){
  float x2=dot(x,x),iv=1./max(1.-x2,1e-6);
  vec3 X=2.*x*iv;float W=(1.+x2)*iv;
  vec3 Y=uM1*X+uP4.xyz*W;float Wy=dot(uP5.xyz,X)+uP4.w*W;
  return Y/max(1.+Wy,1e-8);
}
float gDe,gDv,gDf;
float hMap(vec3 xf,float rE,float rV){
  float h=dot(xf,hC);vec3 xp=xf-h*hC;
  float lr=length(xp-hCp)-hRc;gDe=sqrt(h*h+lr*lr);
  gDv=length(xf-hV);
  gDf=length(xf-hS)-hRho;
  return min(gDe-rE,gDv-rV);
}
// v14: the four normal taps sit within a pixel of the hit point, inside the same cell, so the cached group
// element is exact for them: map them with gApply instead of folding each one (four fewer inlined fold loops).
float fullMap(vec3 x,float rE,float rV){vec3 xf=gApply(iso(x));return hMap(xf,rE,rV)*max(1.-dot(x,x),1e-7)/max(1.-dot(xf,xf),1e-7);}
#if HD<1
float gMK=1.;
#endif
float eK1,eK2,eK3,bootF;   // v12 set pieces (1 rainbow wave, 2 blackout chase, 3 starfield) and the reboot front, set once in lpInit()
#if HD>=1
// v19 detail tiers (Native and up): more remembered membranes, a nested micro lattice in every tile, a marched reflection bounce off
// the tube glass, far diodes glittering in the foam. LATMF membranes are shaded per ray; each generation of micro tiling is one
// loop pass of the same foldS expansion.
#define LATMF (3+2*HD)
#define LATMN (2*HD+1)
// supersampled multi-hue detail averages toward grey: the final chroma lift grows with the tier so the higher tiers stay as saturated as High
#define LATCH (1.07+.11*float(HD))   // v20: was .14 and .04: measured on the ladder, Offline overshot High
float gMK=1.;   // the deep membranes keep the micro lattice as a whisper: stacked generations of diodes would turn to confetti
// a mirror bounce: the honeycomb seen in the glass at ball point x. The first three loop passes are normal taps (the distance to the
// face sphere, gDf), the rest march the mirror ray; one hFold expansion serves both. gG is saved and restored, the later taps need it.
float shellHue(float dh);
vec3 latMirror(vec3 x,vec3 rdIn,float pxT,float rE,float rV,float bl,float rC,int nSteps,int nShadow,float dhIn,bool tube,out float cosI,out float shad){
  mat4 gS=gG;cosI=1.;shad=1.;
  vec3 rr=rdIn,y=x,nn=vec3(0.,0.,1.),tap=vec3(0.),col=vec3(0.),Lg=normalize(vec3(.46,.72,-.52));
  float tr=0.,eps0=max(pxT*3.,2e-5),e0=eps0*3.,d0=0.,glo=0.,hitC=0.,dhH=0.;int mode=0;
  for(int j=LED0;j<4+nSteps+nShadow;j++){
    vec3 p=x;
    if(j==1)p=x+vec3(e0,0.,0.);else if(j==2)p=x+vec3(0.,e0,0.);else if(j==3)p=x+vec3(0.,0.,e0);
    else if(j>3)p=y+rr*tr;
    float r2=dot(p,p);
    if(j>3&&(r2>rC*rC||tr>(mode==0?2.:.6))){if(mode==0){hitC=2.;mode=1;y=x;rr=Lg;tr=eps0*4.;continue;}break;}
    vec3 w=iso(p);float xd=max(1.-r2,1e-7),bl2;
    float pf=pxT*(1.+tr*30.),pxs=(j<4?1e-9:pf)*max(1.-dot(w,w),1e-7)/xd;
    vec3 xf=hFold(w,pxs,j<4?1e9:bl,bl2);
    float sc=xd/max(1.-dot(xf,xf),1e-7),d=hMap(xf,rE,rV);
    if(j==0){d0=tube?d:gDf;continue;}
    if(j<3){if(j==1)tap.x=(tube?d:gDf)-d0;else tap.y=(tube?d:gDf)-d0;continue;}
    if(j==3){tap.z=(tube?d:gDf)-d0;nn=normalize(tap+1e-12);cosI=abs(dot(rdIn,nn));rr=reflect(rdIn,dot(rdIn,nn)>0.?-nn:nn);y=x+rr*eps0*4.;tr=eps0*3.;continue;}
    float dc=d*sc,epsR=pf*1.3;
    if(mode==0){
      if(bl2>.5||pf/sc>bl){hitC=2.;mode=1;y=x;rr=Lg;tr=eps0*4.;continue;}
      float gg=max(gDe-rE,0.)/(rE*2.);glo+=1./(1.+gg*gg*(1.+gg))*min(d/max(rE,1e-5),3.)*.02;
      if(dc<epsR&&tr>eps0*5.){hitC=1.;dhH=2.*atanh(min(length(p),.99999));mode=1;y=x;rr=Lg;tr=eps0*4.;continue;}
      tr+=max(dc*.85,epsR*.4);
      if(j>=3+nSteps){mode=1;y=x;rr=Lg;tr=eps0*4.;}
    }else{
      if(bl2>.5)break;
      shad=min(shad,clamp(12.*dc/max(tr,1e-5),0.,1.));
      if(dc<epsR*.5){shad=0.;break;}
      tr+=max(dc*.9,epsR*.6);
    }
  }
  gG=gS;
  if(hitC>.5&&hitC<1.5)col=pal(shellHue(dhH)+.08)*(.5+2.*spec(clamp(dhH/8.,0.,1.))+1.4*uHit)*exp(-dhH*.14);
  else if(hitC>1.5)col=pal(uP3.w+.1)*.05;
  col+=pal(uP3.w+.3+dhIn*.05)*glo*.12;
  return col;
}
#endif
// v20: an LED globe: diodes on the cube-sphere grid of direction n, K to a face edge; f = pixel footprint in cells.
// x = diode coverage, y = the number of the diode (0..1), z = how well the grid is resolved
vec3 ledGlobe(vec3 n,float K,float f){
  vec3 a=abs(n);float m=max(a.x,max(a.y,a.z));vec3 q=n/m;
  vec2 uv=a.x>=m?q.yz:(a.y>=m?q.zx:q.xy);float fid=(a.x>=m?1.:(a.y>=m?2.:3.))*(dot(n,step(vec3(m),a))>0.?1.:-1.);
  vec2 g=uv*K*.5,gi=floor(g),gf=fract(g)-.5;
  float w=smoothstep(.5,.2,f);
  return vec3(smoothstep(.3+f,.3-f,length(gf))*w,h21(gi+fid*17.3),w);
}
float gDr;
float shellHue(float dh){return uP3.w+dh*fract(uM2[2].z)*.25+eK1*.5*sin(dh*.9-uTime*1.3)+gDr;}
// v12 reboot: lights go out from far to near and boot up from near to far (uM2[2].z integer part = 0..63)
float bootM(float dh){return clamp((bootF-dh)*.7,0.,1.);}
// v12 LED programs (one per 8 bars, crossfading over a bar): the brightness of a diode at position u (0..1) along its
// column k (strips: depth; faces: angle), id = the diode's own number. lpH returns a hue offset.
float lpH;vec3 wa,wb;   // program weights, set once per pixel in realm()
void lpInit(){
  float ek=floor(uP5.w*.5),ea=fract(uP5.w);eK1=step(abs(ek-1.),.1)*ea;eK2=step(abs(ek-2.),.1)*ea;eK3=step(abs(ek-3.),.1)*ea;bootF=floor(uM2[2].z)/63.*16.;
  float y=uM2[2].y,A=floor(y*.125),B=mod(floor(y),8.),bl=fract(y);
  wa=vec3(equal(vec3(A),vec3(0.,1.,2.)))*(1.-bl)+vec3(equal(vec3(B),vec3(0.,1.,2.)))*bl;
  wb=vec3(equal(vec3(A),vec3(3.,4.,5.)))*(1.-bl)+vec3(equal(vec3(B),vec3(3.,4.,5.)))*bl;
}
float ledProg(float u,float k,float id){
  float lev=spec(clamp(.06+k*.11,0.,1.))*.95;
  float eq=.15+1.6*smoothstep(lev+.05,lev-.05,u);                                   // equaliser columns
  float rp=.1+1.6*pow(.5+.5*cos(k*2.6+u*9.-uTime*2.4),6.)*(.7+.6*uB1.y);             // ripples running outward
  float cc=floor(u*14.-uTime*5.);
  float tx=.22+1.4*step(.42,h11(cc*1.37+floor(k*2.)*7.1))*step(mod(cc,5.),3.5);       // a ticker of characters
  float sk=.08+1.8*pow(.5+.5*sin(uTime*1.6+h11(id)*40.),10.)*(.6+.8*uB2.z);          // slow sparkle
  lpH=wa.y*u*.3+wb.x*fract(u*1.5+k*.15-uTime*.4);                                    // meter gradient / colour chase
  float ev2=eK2,ev3=eK3;
  return mix(mix(dot(wa,vec3(1.,eq,rp))+dot(wb,vec3(1.,tx,sk)),.1+1.6*pow(.5+.5*cos(u*9.-uTime*7.),8.),ev2),sk,ev3);
}
// per-band onset at log-spectrum position x (same axis as spec()): four band pairs (sub+bass, low-mid+mid,
// hi-mid+presence, high+air), each minus the broadband onset (from JS in uM2), so a kick that lifts every band does
// not flash everything: only the band that rises above the rest lights its own diodes. Zero in silence.
float ledOn(float x){return dot(max(1.-abs(x*3.-vec4(0.,1.,2.,3.)),0.),vec4(uM2[0],uM2[1].x));}
// Colour guard for the broad light (membrane glass, halos, foam, tube glass). The palette's warm arc
// red -> orange -> yellow -> chartreuse -> green (where blue is the smallest channel, and where dim glass turns
// olive, khaki, mustard or brown) is replaced by the cool arc travelled backwards: orange -> crimson,
// yellow -> violet, chartreuse -> azure. Red and green are fixed points, so the map is continuous, and
// emerald, teal, cyan, blue, violet, magenta and pink pass unchanged. Diodes, gems and filaments keep the palette
// hue, so a visit on the yellow-green arc holds two clear hues instead of sinking into olive.
#define LATSS (HD>=5?4.:(HD==4?3.:(HD==3?2.:(HD==2?1.5:1.))))
float sq(float x){return x*x;}
// v13: the palette crossfade without its chroma guard (cheap to compile): the orb's sky and faint tints in the march
vec3 palQ(float t){return mix(uPa+uPb*cos(TAU*(uPc*t+uPd+uHue)),uQa+uQb*cos(TAU*(uQc*t+uQd+uHue)),uPalT);}
vec3 lgF(vec3 c){
  float mn=min(c.r,min(c.g,c.b)),ch=max(c.r,c.g)-mn;
  float u=c.b<=min(c.r,c.g)&&ch>1e-5?clamp(.5+.5*(c.g-c.r)/ch,0.,1.):0.,bw=4.*u*(1.-u);
  c-=mn*(.4+.4*bw); // greyed glass (khaki, brown, dusty pink) loses its grey: deeper, cleaner tone
  // u*(.6+.4u): orange -> crimson, yellow -> violet, chartreuse -> azure (well clear of the lime diodes)
  float a=-TAU*u*(.6+.4*u),ca=cos(a),sa=sin(a);vec3 k=vec3(.57735);
  return max(c*ca+cross(k,c)*sa+k*dot(k,c)*(1.-ca),0.)*(1.+.4*bw); // blue reads darker than the yellow it replaces
}
// stained-glass membrane on a cell face: the face's own hyperbolic plane holds a nested {Ps,Qs} tiling
vec4 facePat(vec3 xf,float pxf,float dh,float rip,out float heart,out vec2 hl,out vec3 fill){
  vec3 y=mtr(xf,-hP2);vec2 u=vec2(dot(y,hE1),dot(y,hE2));
  float pu=pxf*1.6*max(1.-dot(y,y),1e-6)/max(1.-dot(xf,xf),1e-6);
  float ru=length(u)/hRin;
  float kS=.9;
  vec2 v=u/(hRin*kS);float vd=max(1.-dot(v,v),1e-6),pv=pu/(hRin*kS);
  float par2,bail2;
  vec2 z2=foldS(v,pv,sInr*.5,par2,bail2);
  float p2l=pv*max(1.-dot(z2,z2),1e-6)/vd/sInr;
  float lod2=(bail2>.5?0.:smoothstep(.3,.08,p2l))*step(ru,kS);
  float dE2=(length(z2-vec2(sCx,0.))-sRr)/sInr;
  float rc2=length(z2)/sInr;
  float dV2=length(z2-sV)/sInr;
  float vr=length(v);                                   // radius inside the face: centre = bass, rim = treble
  float spr=spec(clamp(.1+vr*.85,0.,1.)),onF=ledOn(clamp(.1+vr*.85,0.,1.)); // LED matrix: centre diodes = bass onsets, rim = treble
  float hu=shellHue(dh)+.33;
  float f2=mod(par2,2.);
  float wedge=atan(z2.y,z2.x)/(PI/uP3.x);
  vec3 jc=pal(hu+.1*f2+rc2*.15);
  // faint faceted glass
  float fac=.25+.75*pow(abs(fract(wedge*.5+.5*f2)-.5)*2.,1.5);
  // the glass itself goes out separately as 'fill' (colour-guarded once, in realm()); bw = its remaining weight
  vec3 base=jc*jc*fac*(.09+.11*uMid+.14*uB1.w),c=vec3(0);float bw=1.;
  float a=.04+.05*fac;
  float ln=smoothstep(p2l*1.3*LATSS+.02,0.,dE2);
  vec3 lnc=pal(hu+.5); // shared by the sub-tile lines and the face rim (one palette expansion)
  c=mix(c,lnc*(.12+.6*spr+1.5*rip+.7*uB2.y+.9*uHit)*(1.+1.5*eK2),ln*lod2*.7);bw*=1.-ln*lod2*.7;a=mix(a,.2,ln*lod2);
  // LED matrix: a diode at every sub-vertex, a jewel at every sub-tile heart; brightness plays the spectrum
  float dr=(.06+.03*spr)*(1.+.9*eK3);
  float led=smoothstep(dr+p2l*1.2*LATSS,dr*.5,dV2)+exp(-dV2*dV2*80.)*.2;
  float tw=step(.55,h11(par2*1.7+floor(dh*4.)+floor(uTime*2.)*.37));
  float fpm=ledProg(v.y*.5+.5,v.x*4.+4.,par2+floor(dh*4.)*13.);   // the face is an LED panel: columns across, rows up
  vec3 lc=mix(pal(hu+.6+vr*.4+lpH),vec3(1),.1+.3*spr);
  c+=lc*led*((.4+3.*spr*spr)*fpm+2.*uHat*tw+2.*rip+3.*onF)*lod2;a=max(a,led*lod2*.8);
  float hr=.3+.06*uBass;
  float hg=smoothstep(hr+p2l+.02,hr*.5,rc2);
  float hb=smoothstep(p2l*1.3+.03,0.,abs(rc2-hr));
  vec3 hc=pal(hu+.85+lpH);
  float gk=abs(fract(wedge)-.5)*2.,tab=smoothstep(hr*.45,hr*.4,rc2);
  float gem=mix(.25+.75*gk*gk,1.3,tab)*(1.-.5*rc2/hr);
  {float rj=rc2/hr,pj=p2l/hr,cutF=smoothstep(.2,.07,pj)*1.,gk2=abs(fract(wedge*2.+.5)-.5)*2.;
   // (brightness-neutral: the star facets average 1, only the two thin rings darken, so the jewel answers its band as before)
   gem*=mix(1.,mix(1.,.72+.84*gk2*gk2,step(.6,rj))*(1.-.5*smoothstep(.05+pj,0.,abs(rj-.6)))*(1.-.4*smoothstep(.04+pj,0.,abs(rj-.27))),cutF);}
  c=mix(c,hc*gem*(.5+.3*uKick+1.5*spr+rip+1.4*uB2.x)*(.5+.5*fpm)*(1.-.85*eK2-.55*eK3),hg*lod2);   // v12: the jewels play the LED program toobw*=1.-hg*lod2;
  c+=hc*hb*(.8+1.5*uHit)*lod2;a=max(a,max(hg*.7,hb)*lod2);
  c+=pal(hu+.2)*orn(z2/sInr*1.3+vec2(.25,.1),p2l*1.3,uSeed.y+f2*.3)*(.06+.5*uHigh+.6*uB2.w+.9*uHat+.4*uBuild)*lod2*smoothstep(hr,hr+.25,rc2);
  // v19: the tile itself holds a smaller {Ps,Qs} lattice of diodes (Native up), and from Insane a third generation inside that:
  // the micro lines and diodes are drawn in the tile's own hyperbolic coordinates, so they travel with it and stop at the pixel
  // v20: High and below get one generation too, but only on tiles that are large on screen (a close membrane, or zoomed in),
  // so the normal view is as it was and the plain glass of a near pane now holds a fine lattice of diodes
#if HD>=1
  const float PGM=.22,MQA=1.;
#else
  const float PGM=.062,MQA=.3;   // MQA: at High the micro diodes burn steadily (detail, not more flashing)
#endif
  if(lod2>.02&&rc2>hr+.02&&p2l*.9<PGM){
    vec2 zg=z2/sInr*.9;float pg=p2l*.9,wg=gMK*lod2*smoothstep(hr+.02,hr+.16,rc2)*smoothstep(.0,.05,dE2);
#if HD>=1
    int gens=2+(HD>=3?1:0)+(HD>=5?1:0);
#else
    int gens=1;wg*=.65*smoothstep(PGM,PGM*.55,pg);
#endif
    for(int g=LED0;g<gens;g++){
      if(pg>PGM)break;
      float par3,bail3;
      vec2 z3=foldS(zg,pg,sInr*.45,par3,bail3);
      if(bail3>.5)break;
      float p3l=pg*max(1.-dot(z3,z3),1e-6)/max(1.-dot(zg,zg),1e-6)/sInr;
      float d3E=(length(z3-vec2(sCx,0.))-sRr)/sInr,d3V=length(z3-sV)/sInr,rg=length(z3)/sInr;
      float lod3=smoothstep(.26,.08,p3l)*(1.-.45*float(g));
      float ln3=smoothstep(p3l*1.4+.012,0.,d3E);
      float dot3=smoothstep(.13+.7*p3l,.06,d3V);
      float cap3=smoothstep(.32+p3l,.3-p3l,rg);
      float bn3=spec(clamp(.08+.8*vr*(1.+float(g)*.2),0.,1.));
      vec3 cm3=pal(hu+.12+float(g)*.27+.22*rc2+mod(par3,2.)*.1);
      float cov3=clamp(wg*lod3*max(ln3*.65,dot3*.95),0.,.8);
      c=mix(c,cm3*(.3+1.3*bn3*MQA+.6*rip*MQA+.5*uB2.y*MQA)+cm3*dot3*(.4+1.2*bn3*bn3*MQA+uHat*MQA)*(1.-.45*float(g)),cov3);
      a=max(a,wg*lod3*max(ln3*.35,dot3*.7));
      zg=z3/sInr*.86;pg=p3l*.86*max(1.-dot(z3,z3),1e-6);wg*=lod3*(.5+.5*cap3);
    }
  }
  // v20: a spectrum iris round every jewel: a ring of ticks that lights from each mirror line outward as the band of this tile rises
  // (the ring is full when the band is), and flashes on the onsets of that band. Drawn only where a tick is wider than a pixel.
  {float tkN=4.,tkw=wedge*tkN,tkf=abs(fract(tkw)-.5),tkG=smoothstep(.05,.022,p2l)*lod2;
   float tk=smoothstep(.34+p2l*10.,.24,tkf)*smoothstep(.034+p2l,.02,abs(rc2-hr-.09))*tkG;
   float tkL=smoothstep(-.12,.12,.12+1.1*spr-(floor(tkw)+.5)/tkN);   // eased: a tick fades up as the level passes it, it does not blink
   c=mix(c,hc*(.12+1.1*tkL*(.45+spr)+.25*onF),tk*.8);a=max(a,tk*.6);}
  // (v13: the recursive micro-lattice inside every tile heart, seen only at detail settings above about 1.5, is retired:
  // its compile budget (a second foldS expansion) pays for the zoomed-out orb and its sky)
  heart=smoothstep(hr+p2l+.02,hr-p2l-.02,rc2)*lod2*step(par2,.5);
  hl=z2/(sInr*hr);
  vec3 avg=pal(hu+.4)*(.06+.35*spr)*.5;
  c*=lod2;fill=base*bw*lod2+avg*(1.-lod2);a=mix(.08,a,lod2);
  c+=lnc*smoothstep(.015+pu/hRin,0.,abs(ru-kS))*(.2+spr+1.6*uHit+.6*uB2.z)*.4;   // v12: the face rim rings on the snare
  return vec4(c,a);
}
float glassLayer(float depth){return mix(.38,1.,smoothstep(.10,.50,depth));}
vec3 faceCol(vec4 A,vec4 B,out float heart,out vec2 hl,out vec3 fill){
  // A = folded hit point + pixel footprint, B = (hyperbolic depth, transmittance before it, ripple, ray t)
  vec4 fc=facePat(A.xyz,A.w,B.x,B.z,heart,hl,fill);
  float k=fc.a*uP2.z*smoothstep(.02,.26,B.w)*B.y*1.5*exp(-B.x*.22)*glassLayer(B.w)*bootM(B.x);
  fill*=k*(1.-.8*eK2-.6*eK3);return fc.rgb*k;
}
void realm(){
  // v13: the lens zoom (uM2[1].y, from JS) is the kaleidoscope pull-back times the wheel's zoom-in only: the wheel's
  // zoom-out backs the camera out of the ball instead (below). (The v8 stereographic wide lens is retired: its compile
  // budget pays for the orb.)
  float zL=max(uM2[1].y,.05);
  vec2 p=scr()/zL;p=lens(p);
  hcon(uP1.x,uP1.y,uP1.z);tcon(uP3.x,uP3.y);lpInit();
  float fl=1.15+.2*uP1.w-.012*uKick*uDose;   // v12: a smaller kick lens punch
  vec2 pl=p+uLook*vec2(.4,.3);vec3 rd=normalize(vec3(pl,fl));
  // v20b: pulled back, the lens bends from rectilinear toward equidistant (a fisheye), so a very wide view keeps its cells round to the corners instead of smearing them
  float wide=floor(uP3.z*.5)/400.;
  if(wide>.001){float rl=length(pl),th=mix(atan(rl/fl),rl/fl,wide);rd=vec3(pl/max(rl,1e-5)*sin(th),cos(th));}
  gDr=.34*dot(rd,vec3(.62,.57,.54));
  float pix=1./(uRes.y*zL*fl);
  float rE=uP2.w*.66*(1.+.22*uBass)*(1.-.2*wide),rV=rE*2.1*(1.+.2*uHit);   // v20b: pulled back, the tubes thin, so more of the honeycomb shows through
  // v13 wheel zoom-out: the camera backs straight out of the Poincare ball (Euclidean distance cb behind its centre,
  // uM2[1].z) and the honeycomb is cut at radius rC: the infinite universe of LED cells becomes a crystal orb, cells
  // shrinking toward its rim. At cb = 0 (zoom 1 and in) every expression below is the original one.
  float cb=wide*0.;vec3 ro=vec3(0.,0.,-cb);gG=mat4(1.);   // v20b: the camera backs toward the rim but never leaves the ball (uM2[1].z now carries neuron pulses)
  vec3 acc=vec3(0.);float T=1.,t=.004,glow=0.,glowT=0.,gV=0.;
  float skipF=0.,nF=0.;
  vec4 fA0=vec4(0),fB0=vec4(0),fA1=vec4(0),fB1=vec4(0),fA2=vec4(0),fB2=vec4(0);
#if HD>=1
  vec4 fAx[LATMF-3],fBx[LATMF-3];
#endif
  float hitK=0.,hitT=0.,hitDh=0.,hitV=0.,hitTr=0.,hitPx=0.;vec3 hitX=vec3(0);
  float det=clamp(uDetail,.5,16.);
  float maxS=48.+56.*det;
  float farEdge=1.-max(2e-7,5e-4/(det*det));
  float orb=0.,rC=mix(farEdge,.8,orb),fT=-1.,fTr=0.;   // v20b: the honeycomb is never cut into an orb
  // far out, the sky around the orb is full of other crystal universes: on a coarse grid of directions, rays that miss
  // the orb but fall inside a smaller orb's disc are handed to a copy of the honeycomb (turned its own way) by moving
  // the ray into that copy's frame. The one march below renders them all (no extra shader code per orb).
  float skyO=0.;vec3 skH=vec3(0.);
  if(false){   // v20b: no satellite orbs, ever
    float b0=dot(ro,rd);
    if(b0*b0-dot(ro,ro)+rC*rC<0.){
      // v20: the directions are gridded on the faces of a cube (4 x 4 a face). The old 3D grid put the centre of some orbs outside
      // their own cell, which cut those orbs into wedges and squares.
      vec3 ad=abs(rd);float am=max(ad.x,max(ad.y,ad.z));vec3 fq=rd/am;
      float fax=ad.x>=am?1.:(ad.y>=am?2.:3.),fsg=dot(rd,step(vec3(am),ad))>0.?1.:-1.;
      vec2 fuv=fax<1.5?fq.yz:(fax<2.5?fq.zx:fq.xy),fci=floor(fuv*2.+2.);
      vec3 gc=vec3(fci,fax*fsg),gh=fract(gc*vec3(.1031,.1030,.0973)+.213);gh+=dot(gh,gh.yxz+33.33);gh=fract((gh.xxy+gh.yzz)*gh.zyx);
      vec2 fcu=(fci+.5+.16*(gh.xy-.5))*.5-1.;
      vec3 od=normalize(fax<1.5?vec3(fsg,fcu):(fax<2.5?vec3(fcu.y,fsg,fcu.x):vec3(fcu,fsg)));float sa=.042+.032*gh.z;skH=gh;
      if(gh.x>.15&&dot(rd,od)>sqrt(1.-sa*sa)){
        float a=gh.y*TAU,c=cos(a),s2=sin(a),b=gh.z*3.,cb2=cos(b),sb=sin(b);mat3 Rr=mat3(c,0.,-s2,0.,1.,0.,s2,0.,c)*mat3(1.,0.,0.,0.,cb2,sb,0.,-sb,cb2);
        ro=-(Rr*od)*(rC/sa);rd=normalize(Rr*rd);skyO=1.;
      }
    }
  }
  float k1=2.*dot(rd,ro),k2=dot(ro,ro);
  // the ray's interval inside the cut ball (from the centre the ray starts inside and leaves at rC)
  float bq=dot(ro,rd),cq=dot(ro,ro)-rC*rC,hq=bq*bq-cq,tIn=-bq-sqrt(max(hq,0.)),tOut=-bq+sqrt(max(hq,0.));
  bool inOrb=hq>0.&&tOut>.004;t=max(t,tIn);float tEnd=inOrb&&skyO<.5?tOut:-1.;   // v20: the small orbs of the sky are not marched (see the globes below)
  // inside the ball near the camera (while it backs out) the cells around the lens are cut away, like a near plane
  t=max(t,.75*cb*(1.-orb)*step(cq,0.));
  if(skyO<.5&&cb>0.)t=max(t,.55*smoothstep(0.,.5,cb)/max(rd.z,.2));
  float ripD=uP2.x,faB=.07*uP2.z;
  float bl=rE*1.2*clamp(sqrt(det),.7,4.); // LOD: cells melt into the foam once edges drop below this
  float orbL=0.;bl*=1.+7.*orbL+24.*skyO;   // v13: seen from outside the orb, tubes stay as fine pixel lines
  for(int i=LED0;i<944;i++){
    if(float(i)>=maxS||T<.03||t>tEnd)break;
    vec3 x=ro+rd*t;
    vec3 w=iso(x);
    float bail;
    float xd=max(1.-(t*(t+k1)+k2),1e-7);
    float pxs=pix*t*max(1.-dot(w,w),1e-7)/xd;
    vec3 xf=hFold(w,pxs,bl,bail);
    float sc=xd/max(1.-dot(xf,xf),1e-7);
    float pxf=pix*t/sc;
    if(bail>.5||pxf>bl){
      // the honeycomb has melted below the pixel scale: the glittering foam of the sphere at infinity
      fT=t;fTr=T;T=0.;break;   // (its colour is added after the march)
    }
    float d=hMap(xf,rE,rV);
    float dc=d*sc,dfc=gDf*sc;
    // LED halos (Lorentzian), measured in folded (hyperbolic) units so far LEDs get proportionally small halos
    float ge=max(gDe-rE,0.)/(rE*2.),gv=max(gDv-rV,0.)/rV;
    ge=T/(1.+ge*ge*(1.+ge));gv=T/(1.+gv*gv*(1.+gv));
#if HD>=1
    float eps=pix*t*(.82-.05*float(HD));
#else
    float eps=pix*t*1.2;
#endif
    if(skipF>.5&&dfc>eps*5.)skipF=0.;
    float st=dc;if(skipF<.5)st=min(st,max(dfc,eps*.5));
    bool faceCrossing=skipF<.5&&dfc<eps;
    float segment=faceCrossing?eps*2.:max(st*.85,eps*.3);
    if(!faceCrossing&&dc<eps)segment=0.;
    segment=max(0.,min(segment,tEnd-t));
    // Integrate halo density along the travelled ray, in local tube-radius units.
    // Extra tracing steps improve geometry rather than inflating foreground bloom.
    float ew=min(segment/max(sc*rE,eps),8.),vw=min(segment/max(sc*rV,eps),8.);
    glow+=ge*ew;glowT+=ge*ew*t;gV+=gv*vw;
    if(skipF<.5&&dfc<eps){
      // membrane crossing: remember it (the pattern is shaded after the march), tint what lies behind
      float dh=2.*atanh(min(t,.99999));   // (exact depth and ripple of the three kept membranes: after the march)
      vec4 fa=vec4(xf,pxf),fb=vec4(0.,T,0.,t);
      if(nF<.5){fA0=fa;fB0=fb;}else if(nF<1.5){fA1=fa;fB1=fb;}else if(nF<2.5){fA2=fa;fB2=fb;}
#if HD>=1
      else if(nF<float(LATMF)-.5){fAx[int(nF)-3]=fa;fBx[int(nF)-3]=fb;}
#endif
      else acc+=T*faB*palQ(shellHue(dh)+.4)*.25*exp(-dh*.22);
      nF+=1.;T*=1.-faB*smoothstep(.0,.06,t)*glassLayer(t);
      skipF=1.;t+=eps*2.;continue;
    }
    if(dc<eps){hitK=1.;hitT=t;hitX=xf;hitPx=pxf;hitTr=T;hitV=step(gDv-rV,gDe-rE);T=0.;break;}
    t+=max(st*.85,eps*.3);
  }
  // v13: seen from outside, a ray that crosses the cut orb without meeting a tube ends on its far shell, which glows with
  // the foam of the sphere at infinity (as the far background does from inside), so the orb is a lit glass ball
  if(cb>.0&&inOrb&&skyO<.5&&T>.03&&fT<0.&&hitK<.5){fT=tEnd;fTr=T;T=0.;}
  if(fT>0.){
    // the honeycomb melted below the pixel scale: the glittering foam of the sphere at infinity
    float dh=2.*atanh(min(length(ro+rd*fT),.99999)),dr=(dh-ripD)*2.2;
    float shD=0.;
    if(orbL>.001&&skyO<.5&&fT>tEnd-1e-4){
      // v20: seen from outside, the far skin of the orb is an LED globe: a grid of diodes that fills like an equaliser and twinkles on the hats
      vec3 lg=ledGlobe(normalize(ro+rd*fT),44.,pix*fT/rC*28./max(sqrt(max(hq,0.))/rC,.3));
      float bn=spec(clamp(.05+.9*lg.y,0.,1.));
      // (quieter from inside the ball, at zoom 0.4, where it is the backdrop and not the subject)
      shD=lg.x*(.25+2.4*bn*bn+2.2*uHat*step(.75,lg.y)+1.2*uDose/(1.+dr*dr))*orbL*mix(.25,1.,smoothstep(.75,1.3,cb));
    }
    acc+=fTr*pal(shellHue(dh)+.1)*(.2+.1*spec(clamp(dh/8.,0.,1.))+.1*uDose/(1.+dr*dr)+shD);
#if HD>=2
    // v19: at Cinema and up, the foam of the sphere at infinity resolves into diodes (one finer shell of cells per tier)
    {vec3 frd=rd;float gl=0.;
     for(int s=LED0;s<HD;s++){float cs=70.*pow(1.9,float(s));vec3 g3=frd*cs,gi=floor(g3),gf=fract(g3)-.5;
       vec3 hh=fract(gi*vec3(.1031,.1030,.0973)+float(s)*.37);hh+=dot(hh,hh.yxz+33.33);hh=fract((hh.xxy+hh.yzz)*hh.zyx);
       if(hh.x>.72){float dd=length(gf+(hh.yzx-.5)*.3);float prj=pix*cs*1.3;gl+=smoothstep(.17+prj,.05,dd)*(.3+.7*hh.y)*(.45+1.2*uHat*step(.5,hh.z)+.7*uB2.w*step(.85,hh.y));}}
     acc+=fTr*min(gl,1.)*.45*pal(shellHue(dh)+.1);}
#endif
  }
  if(hitK>.5)hitDh=2.*atanh(min(length(ro+rd*hitT),.99999));
  // so far acc holds only broad light (foam, far membranes): it joins the fill that is colour-guarded at the end
  vec3 accF=acc*bootM(9.);acc=vec3(0.);
  float win=0.,heart;vec2 wl=vec2(0),hl;vec3 fFill;
#if HD>=1
  // v19 mirror pass: one latMirror expansion serves the first panes and the tube glass, through this loop. Each result is kept for the shading below.
  vec3 mcA[LATMN];float msA[LATMN],csA[LATMN];
  for(int mk=LED0;mk<LATMN;mk++){
    mcA[mk]=vec3(0.);msA[mk]=1.;csA[mk]=1.;
    bool tb=mk==LATMN-1;
    if(tb?hitK<.5:!(nF>float(mk)+.5))continue;
    vec4 fbv=mk==0?fB0:(mk==1?fB1:(mk==2?fB2:(tb?vec4(0.):fBx[mk-3])));
    float tm=tb?hitT:fbv.w,dhm=2.*atanh(min(length(ro+rd*tm),.99999));
    float fpm=tb?1.:fbv.y*glassLayer(tm)*exp(-dhm*.22)*bootM(dhm);
    if(fpm>.02){
      float cI,sh2;
      vec3 mc=latMirror(ro+rd*tm,rd,pix*max(tm,1e-3),rE,rV,bl,rC,tb?40+28*HD:40+28*HD,tb?0:24+52*HD,dhm,tb,cI,sh2);
      mcA[mk]=mc*fpm;msA[mk]=sh2;csA[mk]=cI;
    }
  }
#endif
  // the (up to) three remembered membranes, nearest first, share one faceCol() expansion
#if HD>=1
  float occ=1.;
  for(int k=LED0;k<LATMF;k++){
    if(!(nF>float(k)+.5))break;
    vec4 fa=k==0?fA0:(k==1?fA1:(k==2?fA2:fAx[k-3])),fb=k==0?fB0:(k==1?fB1:(k==2?fB2:fBx[k-3]));
    gMK=k==0?1.:(k==1?.55:(k==2?.3:.12));
#else
  for(int k=LED0;k<3;k++){
    if(!(nF>float(k)+.5)||(k==2&&!(uDetail>.75)))break;
    vec4 fa=k==0?fA0:(k==1?fA1:fA2),fb=k==0?fB0:(k==1?fB1:fB2);
    gMK=k==0?1.:(k==1?.55:.3);
#endif
    fb.x=2.*atanh(min(length(ro+rd*fb.w),.99999));fb.z=uDose/(1.+sq((fb.x-ripD)*2.2));
#if HD>=1
    // a nearer pane's ink covers the panes behind it (occ), so stacked membranes never sum toward white; the first panes take the mirror and
    // shadow results of the pass above
    vec3 fcC=vec3(0.),fcM=vec3(0.);float lShad=1.;
    if(k<2*HD){lShad=msA[k];fcM=mcA[k]*(.03+.75*pow(1.-csA[k],4.))*(.9+.5*uB2.w);}
    fcC=faceCol(fa,fb,heart,hl,fFill);
    float lsh=mix(1.,lShad,.72);
    acc+=(fcC*lsh+fcM)*occ;accF+=fFill*occ*mix(1.,lShad,.55);occ*=1.-clamp(dot(fcC,vec3(.3333))*2.6,0.,.9);
#else
    acc+=faceCol(fa,fb,heart,hl,fFill);accF+=fFill;
#endif
    if(k==0&&fB0.y>.5&&fB0.w>.05){win=heart*fB0.y*glassLayer(fB0.w)*smoothstep(.1,.3,fB0.w);wl=hl;}
  }
  if(hitK>.5){
    // LED tube or bulb: neon core, glassy sheath
    vec3 x=ro+rd*hitT;float dh=hitDh,eps=pix*hitT*.6;
    vec2 nE=vec2(1,-1)*eps;vec4 nTap=vec4(0.);
    for(int j=LED0;j<4;j++){vec3 ek=j==0?nE.xyy:(j==1?nE.yyx:(j==2?nE.yxy:nE.xxx));float f=fullMap(x+ek,rE,rV);if(j==0)nTap.x=f;else if(j==1)nTap.y=f;else if(j==2)nTap.z=f;else nTap.w=f;}
    vec3 n=normalize(nE.xyy*nTap.x+nE.yyx*nTap.y+nE.yxy*nTap.z+nE.xxx*nTap.w);
    float fr=clamp(dot(n,-rd),0.,1.),f2=fr*fr,f4=f2*f2; // powers by squaring: cheaper to compile than pow()
    float sp=spec(clamp(dh/8.,0.,1.)),rd2=(dh-ripD)*2.2,rip=uDose/(1.+rd2*rd2),onT=ledOn(clamp(dh/8.,0.,1.)); // strips: near = bass onsets, far = treble
    vec3 c,pv=pal(shellHue(dh)+.5);
    // v20b neurons: the age of this shell's pulse (JS, in half-edges of travel), a little later with depth; it fades over a few hops
    vec4 nAg=vec4(mod(uM2[1].z,1024.),floor(uM2[1].z/1024.),mod(uM2[2].x,1024.),floor(uM2[2].x/1024.))/128.;
    float nT=dot(nAg,vec4(equal(vec4(mod(floor(dh*1.7),4.)),vec4(0.,1.,2.,3.))))-.07*dh,nAm=step(0.,nT)*exp(-.5*max(nT,0.))*step(nT,7.4)*uDose;
    if(hitV>.5){
      c=mix(pv,vec3(1.),.08+.18*uHit)*(1.+2.*uHit+1.5*rip)*(.16+.84*f4*fr);
      {vec3 dv=normalize(hitX-hV);float vpx=hitPx/max(rV,1e-6);
       float a1=acos(clamp(dot(dv,normalize(hP1-hV)),-1.,1.))*3.2,a2=acos(clamp(dot(dv,normalize(hCp-hV)),-1.,1.))*2.4;
       float w1=vpx*3.2,w2=vpx*2.4,l1=smoothstep(.1+w1*1.5,.03,abs(fract(a1)-.5))*smoothstep(.3,.1,w1),l2=smoothstep(.09+w2*1.5,.03,abs(fract(a2)-.5))*smoothstep(.3,.1,w2);
       float fct=step(.5,fract(a1*.5))*smoothstep(.3,.1,w1);
       c*=(1.-.6*1.*max(l1,l2))*(1.+.3*1.*(fct-.5))*(1.+.14*1.*smoothstep(.3,.1,w1));
       // the pulse fires the node as it leaves and as it lands: its rings light outward from the tube
       float nF=nAm*exp(-sq(min(mod(nT,2.),2.-mod(nT,2.))*3.2-.25*floor(a1)));
       c+=mix(pal(shellHue(dh)+.5+.17*mod(floor(dh*1.7),4.)),vec3(1),.2)*nF*(.5+1.6*f4)*(1.-.5*max(l1,l2))*1.5*1.;}
    }else{
      // LED strip: diodes along the edge, a pulse chasing from the edge midpoints to the vertices every beat
      vec3 xf=hitX;float h=dot(xf,hC);vec3 vv=normalize(xf-h*hC-hCp);
      vec3 v1=normalize(hP1-hCp),v0=normalize(hV-hCp);
      float a01=acos(clamp(dot(v0,v1),-1.,1.)),s=acos(clamp(dot(vv,v1),-1.,1.))/max(a01,1e-4);
      float N=5.+floor(2.*sqrt(det)),arc=a01*hRc,dl=smoothstep(.6,.15,hitPx*N/max(arc,1e-4));
      float g=abs(fract(s*N+.5)-.5)*2.;
      float diode=mix(1.,.12+2.1*smoothstep(.28,.065,g),dl);
      // v20: the strip is a made thing when seen close: a pair of contact rings at every joint between diodes and fine ribs on the dark
      // glass between them. Both appear only where they are wider than a pixel, so the thin tubes of the normal view are unchanged.
      float gpx=hitPx*N*2./max(arc,1e-4),tbW=smoothstep(.2,.085,hitPx/max(rE,1e-6)),jr=smoothstep(.05+gpx,.02,abs(g-.8))*smoothstep(.4,.15,gpx)*tbW;   // tbW: the tube is at least about ten pixels thick
      float rbx=s*N*9.,rb=smoothstep(.25+gpx*4.5,.12,abs(fract(rbx)-.5))*smoothstep(.16,.055,gpx)*smoothstep(.36,.5,g)*(1.-jr)*tbW;
      float cd=(s-uP2.y)*5.,ch=exp(-cd*cd)*(.6+.3*uKick);
      float spm=ledProg(1.-s,dh,floor(s*N)+17.*floor(dh*3.));
      vec3 ec=pal(shellHue(dh)+.08*floor(s*N)+lpH);
      float f8=f4*f4,core=f8*f8,rf=1.-fr;rf*=rf;
      // A thin emissive filament sits inside a dark glass sheath. Segment gaps expose its depth.
      accF+=hitTr*exp(-dh*.18)*(ec*(.018+.035*sp)+pv*rf*rf*.22*(1.+1.6*uHit)); // the dark glass sheath (v12: it glows up on the snare)
      float catchLight=core*core*f8*f2*(.08+.15*uHigh);
      float filament=core*(.065+.09*sp+.06*rip);
      // The kick is a comet: it leaves the starburst (s=1) and runs out along the diodes to the strip's middle,
      // so the hit travels through the tubes instead of flashing the whole frame
      // ripD counts the ring's travel since the kick (about one unit per beat); far strips launch a little later
      float q=ripD-.03*dh,dq=s-(1.-2.4*q);
      float comet=mod(uP3.z,2.)*uDose*step(0.,q)*exp(-1.5*q)*(exp(-dq*dq*260.)+step(0.,dq)*exp(-dq*5.)*.35);
      // v20b neurons: the pulse of this shell's band. nt counts half-edges travelled (s runs 1 at the node to 0 at the middle of the tube, so the point is at |1 - nt mod 2|)
      float nPk=mod(floor(dh*1.7),4.),nM=mod(nT,2.),nS=abs(1.-nM),nD=(s-nS)*(nM<1.?1.:-1.);
      float nPu=nAm*(exp(-nD*nD*240.)+step(0.,nD)*exp(-nD*7.)*.3);
      c=ec*(filament+core*((.35+1.25*sp)*spm+.9*rip+ch+2.*uHit*dl*mod(floor(s*N),2.)+1.6*onT)*diode+catchLight // snare: every other diode
           +(jr*(.1+.5*sp+1.6*onT+.5*rip)+rb*(.16+.35*sp+.6*ch+.5*onT))*(.2+.8*f2))   // v20: rings flash on the onsets of their own band, the beat pulse runs through the ribs
        +mix(pv,vec3(1),.3)*comet*(core*16.+4.*f2*fr)*mix(1.,diode,.6)
        +mix(pal(shellHue(dh)+.5+.17*nPk),vec3(1),.1)*nPu*(core*15.+4.*f2*fr)*mix(1.,diode,.5)*1.;
    }
#if HD>=1
    // v19: the reflection bounce of the tube glass (marched in the mirror pass above)
    {
      float F=pow(1.-fr,5.);
      c+=mcA[LATMN-1]*(hitV>.5?.35:1.)*(.1+.9*F)*(.55+.5*fr);
    }
#endif
    acc+=hitTr*c*exp(-dh*.18)*bootM(dh);
  }
  float gt=glowT/max(glow,1e-6),gdh=2.*atanh(min(length(ro+rd*gt),.99999)),gdr=(gdh-ripD)*2.2;
  accF+=pal(shellHue(gdh)+.1)*glow*.035*(.8+.6*spec(clamp(gdh/8.,0.,1.))+.5*uDose/(1.+gdr*gdr)+.7*uB1.x)*bootM(gdh)*(1.-.7*eK2);
  acc+=mix(pal(uP3.w+.6),vec3(1),.4)*gV*.07*(1.+1.5*uHit+1.2*uHat)*bootM(1.);
  float cellA=dot(accF+acc,vec3(.2126,.7152,.0722));accF+=pal(shellHue(2.4)+.06+.12*rd.y+.1*uB1.w)*(.17+.18*uB1.x+.08*uB1.y)*bootM(3.)*(1.-.7*eK2)/(1.+12.*cellA)*(1.-.85*wide);   // v20b: pulled back, the fill wash steps down
  accF*=1.-.5*eK3;
  acc+=lgF(accF); // all broad light (glass, sheaths, halos, foam) is colour-guarded once
  // v13: seen from outside: a glass rim and an aura on the orb (and on every small orb of the sky), and far diodes
  // twinkling with the hats and the air band between them
  if(orbL>.001){
    vec3 pA=palQ(uP3.w),pB=palQ(uP3.w+.5);
    float bq0=dot(ro,rd),hq0=bq0*bq0-dot(ro,ro)+rC*rC,miss=step(hq0,0.),rim=hq0>0.?sq(sq(1.-sqrt(hq0)/rC)):exp(-max(-hq0,0.)*40./max(dot(ro,ro)*.2,1.));
    vec3 dir=rd*70.,hh=fract(floor(dir)*vec3(.1031,.1030,.0973));hh+=dot(hh,hh.yxz+33.33);hh=fract((hh.xxy+hh.yzz)*hh.zyx);
    float star=step(.7,hh.x)*smoothstep(.3,.08,length(fract(dir)-.5))*(.4+.6*hh.y)*(1.+3.*uHat*step(.6,hh.z)+2.*uB2.w*step(.85,hh.y));
    float nb=min(sq(sin(dot(rd,vec3(2.3,1.1,-1.7))+uTime*.03)*sin(dot(rd,vec3(-.9,3.1,1.3))+1.))*1.5,1.);   // a faint glowing nebula of LED light (v20: capped, the mix ran past its end into a black hole)
    // v20: the sky is deep and saturated (colour-guarded like all broad light; it was a pale khaki wash), the aura hugs the orb, and the
    // limb glows on both sides of the edge, so the outline of the orb is smooth instead of a hard dark cut
    if(hq0>0.)rim=sq(rim)*(1.-sqrt(hq0)/rC);
    vec2 nq=rd.xy/max(rd.z,.25)*2.2;float nf=1.-abs(2.*vnoise(nq*2.+2.5*vnoise(nq*1.3+uTime*.02))-1.);nf*=nf;   // v20: the nebula is filaments, not a flat flood
    vec3 skyC=mix(pA,pB,clamp(nb+.5*nf-.25,0.,1.))*(.05+.32*nb*nb*(.2+1.3*nf*nf))*(1.+.6*uB1.x)*miss+mix(pA,pB,skyO)*exp(-max(-hq0,0.)*8.)*(.08+.1*uB1.x)*miss;
    acc+=(lgF(skyC)+mix(pA,pB,hh.z)*star*.35*miss)*T*orbL+lgF(mix(pA,pB,skyO))*rim*(.4+.6*uB1.x)*(1.-.4*skyO)*(1.+1.5*uKick*skyO)*orbL;
    if(skyO>.5&&hq0>0.){
      // v20: each small orb is an LED globe that plays one band of the spectrum: its diodes fill like an equaliser, the hats twinkle on it
      float mu=sqrt(hq0)/rC;vec3 gn=(ro+rd*(-bq0-sqrt(hq0)))/rC;
      float ga=uTime*.12*(skH.x-.5),gcs=cos(ga),gsn=sin(ga);gn.xz=mat2(gcs,gsn,-gsn,gcs)*gn.xz;
      vec3 lg=ledGlobe(gn,6.,pix*length(ro)/rC*3.8/max(mu,.3));
      float bn=spec(clamp(.04+.9*skH.y,0.,1.)),lit=step(lg.y,.12+1.2*bn);
      vec3 gcl=pal(uP3.w+skH.z+.22*lg.y);
      acc+=gcl*(lg.x*(.7+1.5*lit*(.35+bn)+1.8*uHat*step(.8,lg.y))+(.07+.14*bn)*(1.-.6*lg.z)+.5*sq(sq(1.-mu)))*(.3+.7*mu)*orbL;
    }
  }
#if HD>=1
  acc=max(mix(vec3(dot(acc,vec3(.2126,.7152,.0722))),acc,LATCH),0.)/(1.+.03*float(HD*HD));
#else
  acc=max(mix(vec3(dot(acc,vec3(.2126,.7152,.0722))),acc,1.07),0.);   // v15: the chroma lift can go negative, clamp it
#endif
  fragColor=vec4(acc,win*.7);
  fragWin=vec4(clamp(wl*.5+.5,0.,1.),0.,1.);
}
`;
