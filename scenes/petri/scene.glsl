const R_PETRI = `
// DIAT0M: a living psychedelic microscope slide. Darkfield microbiology drawn as superflat folk art: pennate diatoms
// with ribbed cream frames and a row of jewel chloroplasts, lace-lattice radiolarians with pin-tipped spines,
// stained-glass centric diatoms, ciliates fringed with beating hairs, chain colonies, flower clusters, star
// radiolarians and dotted micro-rosettes, all crisp cream-outlined over a deep stain ground sprinkled with tiny jewels.
// Families: SLIDE (a parallax collage drifting in alternating directions), MANDALA (a Victorian arranged slide:
// log-polar rings of identical organisms, alternate rings counter-rotating, flowing outward from a spectrum rosette),
// CURRENT (lanes of swimmers streaming in alternate directions; round folk roll along).
// Every organism is alive: cytoplasm and organelles stream (mids), membranes breathe and swell (bass) and squash as
// they swim, colonies and contractile vacuoles contract on the kick, cilia beat and spines sparkle with the hats,
// axopods and pseudopods extend and retract, nuclei boil with chromatin and go through mitosis on phrase wipes and
// division blooms, the snare sends a burst wave; a free swimmer cruises over the slide and defocused cells drift on a
// deeper focal plane behind it.
// uP1 [travel beats (+build extra), cilia phase, kick env, cytoplasm stream phase (mids)]  uP2 [stain ground rgb,
// outline code]  uP3 [wipe radius, bass env, spine reach (highs + build), drop flash]
// uP4 [famA+vsA, hat env, event+progress, colour shift*4 + snare wave]  uP5 [famB+vsB, presence env, beat clock, magn.]
// uM1, uM2: six jewel colours (linear)
// jewel colour i (cyclic; the six stain jewels arrive pre-mixed from JS)
vec3 diC(float i){float k=floor(i+.5);k-=6.*floor(k/6.);
  return k<2.5?(k<.5?uM1[0]:k<1.5?uM1[1]:uM1[2]):(k<3.5?uM2[0]:k<4.5?uM2[1]:uM2[2]);}
float diAt(float y,float x){float ax=abs(x),ay=abs(y),t=min(ax,ay)/max(max(ax,ay),1e-20),s=t*t;
  float r=((-.0464964749*s+.15931422)*s-.327622764)*s*t+t;r=mix(r,1.5707963-r,step(ax,ay));r=mix(r,3.1415927-r,step(x,0.));return r-2.*r*step(y,0.);}
vec4 diH(vec2 id,float L){return fract(sin(vec4(dot(id,vec2(127.1,311.7)),dot(id,vec2(269.5,183.3)),dot(id,vec2(419.2,371.9)),dot(id,vec2(113.5,271.9)))+L*7.31)*43758.545);}
// a cheap 4-channel hash (no trig)
vec4 diQ(vec2 i){vec4 p=fract(i.xyxy*vec4(.1031,.103,.0973,.1099));p+=dot(p,p.wzxy+33.33);return fract((p.xxyz+p.yzzw)*p.zywx);}
float diA(float d,float e){return clamp(.5-.5*d/e,0.,1.);}
float diBack(float x){x=min(x/.42,1.)-1.;return 1.+2.70158*x*x*x+1.70158*x*x;}
float diBand(float b){b-=8.*floor(b/8.);return dot(uB1,step(abs(vec4(b)-vec4(0.,1.,2.,3.)),vec4(.5)))+dot(uB2,step(abs(vec4(b)-vec4(4.,5.,6.,7.)),vec4(.5)));}
float diOn(float b){b-=8.*floor(b/8.);return dot(uO1,step(abs(vec4(b)-vec4(0.,1.,2.,3.)),vec4(.5)))+dot(uO2,step(abs(vec4(b)-vec4(4.,5.,6.,7.)),vec4(.5)));}
float diEl(vec2 p,vec2 ab){float k0=length(p/ab),k1=length(p/(ab*ab));return k0*(k0-1.)/max(k1,1e-5);}
// lens (vesica) along x: half-length 1, half-width w
float diVes(vec2 p,float w){float R=(1.+w*w)/(2.*w),dd=R-w;p=abs(p.yx);
  return (p.y-1.)*dd>p.x?length(p-vec2(0.,1.)):length(p-vec2(-dd,0.))-R;}
// nearest point of a hex lattice (neighbour distance 1): xy = offset, zw = id
vec4 diHex(vec2 u){vec4 hc=floor(vec4(u,u-vec2(.5,.8660254))/vec2(1.,1.7320508).xyxy)+.5;
  vec2 a=u-hc.xy*vec2(1.,1.7320508),b=u-(hc.zw+.5)*vec2(1.,1.7320508),v=mix(b,a,step(dot(a,a),dot(b,b)));
  return vec4(v,floor(vec2((u-v).x*2.,(u-v).y/.8660254)+.5));}
// the ciliate's body frame: an egg bent into a leaf / paisley curve; the bend flexes as it swims
vec2 diCe(vec2 q,float t){return vec2(q.x,q.y+(.16+.1*sin(t*1.3))*(q.x*q.x-.25));}
// a spine / arm length: radiolarian axopods extend and retract in a wave running round the cell (longer with the highs);
// the star's arms are pseudopods that flow in and out (longer with the presence band)
float diSpk(float k,float sp,float ty,float t){float wv=sin(k*2.1-t*1.4);
  return ty<1.5?mix(.66+.2*sp+.07*wv,.53+.03*wv,mod(k,2.)):.54+.2*sp+.09*wv+.1*uP5.y;}
// a flower-cluster cell's offset: the cells bulge in a wave round the cluster and pull together on the kick
float diPet(float k,float kp,float t){return .5-.07*kp+.045*sin(k*2.1-t*1.4);}
// the ciliate's leaf body: round at the back, drawn to a point at the front (approximate distance)
float diLeaf(vec2 e){return diEl(vec2(e.x,e.y*(1.6+.75*e.x)),vec2(.82,.52))*.72;}
// is a candidate centre c (with radius rb) blocked by an already placed organism (centre S.xy, semi-axes S.zw along
// its direction D)? Keeps the slide a composed poster: big organisms first, smaller ones only in the gaps
// free space between a candidate centre c and a placed organism (approximate gap to its footprint ellipse)
float diGap(vec2 c,vec4 S,vec2 D){vec2 d=c-S.xy;d=vec2(dot(d,D),dot(d,vec2(-D.y,D.x)));
  float l=max(length(d),1e-5);return mix(1e3,l-1./length(d/l/max(S.zw,1e-4)),step(1e-5,S.z));}
float diBlk(vec2 c,vec4 S,vec2 D,float rb){vec2 d=c-S.xy;d=vec2(dot(d,D),dot(d,vec2(-D.y,D.x)));
  return step(length(d/(S.zw+rb)),1.)*step(1e-5,S.z);}
// unit silhouettes (radius <= 1): 0 pennate diatom, 1 radiolarian, 2 centric diatom, 3 ciliate (incl. hair zone),
// 4 chain colony (incl. bristles), 5 flower cluster, 6 star radiolarian, 7 micro rosette (incl. dot sunburst)
float diSil(vec2 q,float ty,float w,float n,float sp,float kp,float t,float rp){
  float an=diAt(q.y,q.x),k=floor(an*n/TAU+.5),r=length(q),d=r-.9;vec2 s=rot(-k*TAU/n)*q;
  float ln=diSpk(k,sp,ty,t),tl=clamp(s.x/ln,0.,1.);
  if(ty<.5)d=diVes(q,w);
  else if(ty<1.5)d=min(min(r-.44,length(vec2(s.x-clamp(s.x,.4,ln),s.y))-.011),length(s-vec2(ln,0.))-mix(.05,.044,mod(k,2.)));
  else if(ty<2.5)d=r-.9;
  else if(ty<3.5)d=diLeaf(diCe(q,t))-.13;
  else if(ty<4.5)d=length(vec2(q.x-clamp(q.x,-.66,.66),q.y))-.31;
  else if(ty<5.5)d=min(length(s-vec2(diPet(k,kp,t),0.))-.36,r-.3);
  else if(ty<6.5)d=min(min(length(vec2(s.x-ln*tl,s.y))-mix(.17,.06,tl),r-.3),length(s-vec2(ln+.04,0.))-.06);
  return d+rp*sin(an*7.+t*3.);
}
// jewel layers of each organism (up to four, drawn by one loop): A = (mode: 0 ring, 1 row, 2 grid, 3 none; radius or
// spacing; count (0 = the organism's own count, -.5 = half of it); colour offset (.5 alternates, .75 follows the
// index, <0 = outline colour)), B = (size along, size across (<0 = fit the pennate), brightness source, alternate
// radius (rings) / division (rows) / tilt (grids)); E = spine reach (rings) or row spacing (grids); Fl = cytoplasmic
// streaming speed (rings orbit, grid rows flow in opposite directions round the cell)
void diLay(float ty,float j,out vec4 A,out vec4 B,out float E,out float Fl){
  A=vec4(3.,0.,1.,0.);B=vec4(.05,.05,0.,0.);E=0.;Fl=0.;
  if(ty<.5){if(j<.5){A=vec4(1.,.22,8.,.75);B=vec4(.09,-1.,9.,.35);Fl=.3;}}           // chloroplasts = 8 bands, conveyor
  else if(ty<1.5){
    if(j<.5){A=vec4(0.,.7,0.,2.75);B=vec4(.043,.043,3.,-.15);E=.22;}                    // spine pins, hats
    else if(j<1.5){A=vec4(0.,.31,-.5,4.5);B=vec4(.15,.04,1.,0.);}                       // petal kites, presence
    else if(j<2.5){A=vec4(0.,.172,12.,.5);B=vec4(.026,.026,4.,0.);Fl=.35;}}             // core bead ring, bass
  else if(ty<2.5){
    if(j<.5){A=vec4(0.,.805,24.,1.5);B=vec4(.042,.042,4.,0.);}                           // rim beads, bass
    else if(j<1.5){A=vec4(0.,.44,0.,.75);B=vec4(.04,.04,9.,0.);Fl=-.45;}                 // plastids stream, equaliser
    else if(j<2.5){A=vec4(0.,.175,9.,-1.);B=vec4(.022,.022,0.,0.);Fl=.3;}}
  else if(ty<3.5){
    if(j<.5){A=vec4(2.,.15,7.,3.5);B=vec4(.075,.034,7.,.6);E=1.75;Fl=.5;}}              // cyclosis chloroplasts
  else if(ty<4.5){
    if(j<.5){A=vec4(1.,.34,5.,3.5);B=vec4(.155,.155,2.,.55);}                           // colony cells divide, kick
    else if(j<1.5){A=vec4(1.,.34,5.,1.);B=vec4(.05,.05,10.,0.);}}                       // contractile vacuoles
  else if(ty<5.5){
    if(j<.5){A=vec4(0.,0.,1.,5.);B=vec4(.3,.3,2.,0.);}
    else if(j<1.5){A=vec4(0.,.205,8.,-1.);B=vec4(.028,.028,0.,0.);Fl=.3;}}
  else if(ty<6.5){
    if(j<.5){A=vec4(0.,.62,0.,4.75);B=vec4(.06,.06,3.,0.);E=.24;}
    else if(j<1.5){A=vec4(0.,.21,10.,1.);B=vec4(.033,.033,1.,0.);Fl=-.35;}}
  else{
    if(j<.5){A=vec4(0.,.8,16.,1.5);B=vec4(.065,.065,8.,0.);Fl=.12;}                     // dot sunburst, twinkle
    else if(j<1.5){A=vec4(0.,.42,10.,3.5);B=vec4(.06,.06,7.,0.);Fl=-.3;}
    else if(j<2.5){A=vec4(0.,0.,1.,2.);B=vec4(.2,.2,8.,0.);}}
}
// the footprint of an organism (semi-axis across, in units of its radius) for the poster spacing
float diAy(float ty,float w){float isL=step(ty,.5)+step(abs(ty-3.),.5)+step(abs(ty-4.),.5);
  return step(ty,.5)*(w*1.2+.04)+step(abs(ty-3.),.5)*.72+step(abs(ty-4.),.5)*.5+(1.-isL)*mix(1.,.6,step(abs(ty-1.),.5)+step(abs(ty-6.),.5));}
// one organism candidate of layer L at point x (F = families + variant, G = scales + clocks, H = beat clocks): its
// unit coordinates q, centre, hash, type, radius, orientation, pennate width, count, presence, band and centre distance
void diOrg(vec2 x,float L,float px,vec4 F,vec4 G,vec4 H,out vec2 q,out vec2 cC,out vec4 h,out float ty,out float Rs,
  out float ang,out float w,out float n,out float pres,out float bnd,out float dist){
  float fSl=F.x,fMan=F.y,fCur=F.z,vs=F.w,cl=G.x*exp2(L-4.),dirL=mod(L,2.)*2.-1.,sw=G.z,rate=G.w,nt=H.x,mt=H.y;
  float J=cl,flip=1.,lane=0.,roll=0.;dist=0.;
  vec2 v,id;
  if(fMan<.5){
    // the slide pans as one rigid sheet under the objective (one eased stroke per beat); in the current every
    // giant-height stream carries everything inside it at its own speed. Layer cells nest exactly (each layer halves
    // the one above), so every organism lies inside its ancestors' cells: the poster spacing below stays exact.
    float sT=mix(G.x,max(G.x,cl),fCur),rT=floor(x.y/sT+.37),dT=mod(rT,2.)*2.-1.;
    vec2 pan=mix(vec2(H.z,.35*sin(vs*9.))*sw*.03,vec2(dT*sw*(.05+.03*fract(rT*.618))*rate,0.),fCur);
    vec2 u=(x-pan+.37*sT)/cl;id=floor(u);v=u-id-.5;flip=dT;lane=fCur;roll=-dT*sw*(.05+.03*fract(rT*.618))*rate/cl;
  }else{
    // the arranged slide: log-polar rings of N organisms; alternate rings counter-rotate one notch per beat and the
    // whole arrangement flows slowly outward from the centre rosette
    float rr=max(length(x),1e-6),N=floor(7.*pow(G.y,4.-L)+.5),lh=.85;
    float yy=(log(rr)-H.w*.02)*N/TAU/lh,j=floor(yy+.5),dj=mod(j,2.)*2.-1.;
    float xx=diAt(x.y,x.x)/TAU*N+dj*H.z*nt*min(.5,.09*N/TAU)+j*.5,cx=floor(xx+.5);
    v=vec2(xx-cx,(yy-j)*lh);id=vec2(cx-N*floor(cx/N),j);J=rr*TAU/N;lane=1.;
    dist=rr*exp(-v.y*TAU/N);
  }
  id-=256.*floor(id/256.);
  float Lh=L+floor(vs*50.);
  h=diH(id,Lh);vec4 hr=diH(vec2(id.y,9.),Lh),hs=diH(vec2(floor((x.y/G.x+.37)),5.),floor(vs*50.));
  // mandala rings: one organism type, size and colour per ring, colours alternating round the ring
  h=mix(h,vec4(hr.x,hr.y,hr.z,hr.w+.5*mod(id.x,2.)*step(.5,fract(hr.x*7.))),fMan);
  h.y=mix(h.y,hs.y,fCur*step(3.5,L)*step(.35,fract(h.x*5.1)));
  float f3=floor(h.y*3.),t8=floor(h.y*8.);ty=floor(h.y*7.);
  // slide heroes are the reference's cast (pennate, lace radiolarian, paisley ciliate, stained-glass wheel); the big
  // layer mixes everyone
  ty=mix(ty,t8<1.5?0.:t8<3.5?1.:t8<4.5?3.:t8<6.5?2.:6.,step(3.5,L)*fSl);
  ty=mix(ty,t8<.5?0.:t8<1.5?1.:t8<2.5?2.:t8<3.5?3.:t8<4.5?4.:t8<5.5?5.:t8<6.5?6.:2.,step(2.5,L)*step(L,3.5)*fSl);
  // the current carries swimmers (pennates, ciliates, chains) in its bigger layers
  ty=mix(ty,mix(mix(0.,3.,step(.5,f3)),mix(4.,0.,step(3.5,L)),step(1.5,f3)),fCur*step(3.5,L));
  // the fine layers hold small round folk: micro rosettes, centric wheels, flower clusters, radiolarians
  float sm=step(L,1.5);
  float sm0=step(L,.5);
  ty=mix(ty,7.,sm0*step(abs(ty),.5));ty=mix(ty,2.,sm*step(abs(ty-3.),.5));
  ty=mix(ty,5.,sm*step(abs(ty-4.),.5));ty=mix(ty,7.,sm0*step(abs(ty-6.),.5));
  float isL=step(ty,.5)+step(abs(ty-3.),.5)+step(abs(ty-4.),.5);
  float Rl=mix(mix(mix(.38+.1*h.z,.42+.06*h.z,step(2.5,L)),.45+.03*h.z,step(3.5,L)),.4*(.82+.18*h.z),fMan);
  Rl=mix(Rl,.3+.14*h.z,fCur*step(3.5,L));
  vec2 off=v-(.46-Rl)*2.*(h.zw-.5)*(1.-fMan)-vec2(0.,.3*(h.w-.5))*fCur*step(3.5,L);
  Rs=Rl*J;cC=x-off*cl;
  if(fMan<.5)dist=length(cC);
  // per-type counts and the pennate's width
  n=mix(mix(16.+4.*floor(fract(h.w*7.7)*3.),8.+2.*floor(fract(h.w*5.3)*3.),step(1.5,ty)),5.+floor(fract(h.w*3.9)*2.),step(4.5,ty));
  n=mix(n,8.,step(abs(ty-2.),.5)*fMan*step(3.5,L));
  w=.27+.07*fract(h.z*5.3);
  // orientation: round folk tick one notch per beat (with overshoot); long ones glide and turn slowly, point
  // outward in the mandala, along the lane in the current (round folk roll)
  float sdir=step(.5,fract(h.z*9.1))*2.-1.;
  ang=h.z*TAU*7.+sdir*nt*PI/max(n,5.)*(1.-isL)+isL*.45*sin(mt*.13+h.w*6.);
  ang=mix(ang,mix(sdir*nt*PI/max(n,5.),PI*.5,isL),fMan);
  ang=mix(ang,mix(roll/Rl,.5*PI-flip*.5*PI+.1*sin(mt*2.+h.w*6.)+.4*(fract(h.x*3.7)-.5),isL),fCur);
  q=rot(-ang)*off/Rl;
  q.y-=step(ty,.5)*(fract(h.w*3.3)-.5)*.5*w*sin(PI*q.x);
  float dens=mix(mix(mix(.2,.52,step(.5,L)),mix(.7,.9,step(2.5,L)),step(1.5,L)),mix(mix(.92,.7,clamp(L/4.,0.,1.)),mix(.24,.72,clamp(L/4.,0.,1.)),fCur),max(fMan,fCur));
  dens=mix(dens,.5,fCur*step(4.5,L));
  pres=mix(step(h.x,dens),step(fract(hr.x*7.),.82),fMan)*step(1.5,Rs/px);
  bnd=mix(floor(h.w*8.),id.y,fMan);
}
// V18 POND LIFE: planes of free swimmers (far = tiny, near = large) in sliding rows that stream past each other, each its
// own depth, zoom parallax and direction. One body formula with type parameters: 0 paramecium (beating cilia), 1 euglena
// (whipping flagellum), 2 spirillum (corkscrew), 3 volvox (a sphere of beads holding daughter colonies), 4 amoeba
// (flowing pseudopods), 5 rotifer (two spinning crowns), 6 vorticella (bell on a coiled stalk that snaps shut on the
// kick), 7 mitochondrion (folded cristae). rgb + alpha. Geometry follows smoothed envelopes only.
const float PA[8]=float[8](1.,.75,.04,.92,.82,.72,.46,.95),PB[8]=float[8](.42,.24,.04,.92,.82,.3,.42,.42),PX[8]=float[8](0.,.32,1.,0.,0.,.12,.5,0.);
const float PT[8]=float[8](0.,1.25,2.,0.,0.,.55,1.45,0.),PF[8]=float[8](0.,.16,.2,0.,0.,.03,.1,0.),PR[8]=float[8](9.,9.,10.,9.,9.,7.,16.,9.);
const float PW[8]=float[8](.03,.022,.075,.03,.03,.07,.03,.03),PP[8]=float[8](0.,0.,0.,0.,.085,0.,0.,0.),PE[8]=float[8](.12,.1,0.,0.,0.,.08,0.,.05);
#if HD>=1
float gPG=1.;
#define DZ (HD==1?.5:HD==2?.6:HD==3?.7:HD==4?.9:1.1)
#else
#define DZ 1.
#endif
// v20 areolae: the shell's own regular rows of pores, tone on tone (a deeper shade of the stain underneath; the kick opens
// them to light). Rings of pores on the round folk, a hex field on the long ones. An octave appears once its pores are several
// pixels wide; a finer octave only fills the gaps the coarser one left
vec3 diAre(vec3 col,vec2 q,float dr0,float lng,float pu,float amt,float kk){
  float cov=0.;
#if HD>=1
  for(int o=int(min(uZoom,0.));o<1+HD;o++){
    float dr=dr0*exp2(-float(o)),fad=smoothstep(5.*DZ,8.*DZ,dr/pu)*amt;
    if(fad<.004)break;
#else
  {float dr=dr0,fad=smoothstep(5.,8.,dr/pu)*amt;
#endif
    float r=length(q),ir=floor(r/dr),rc=(ir+.5)*dr,n=max(floor(TAU*rc/dr),1.);
    vec2 dP=vec2((fract(diAt(q.y,q.x)*n/TAU+.37*ir)-.5)*TAU*rc/n,r-rc);
    float d=mix(length(dP),length(diHex(q/dr).xy)*dr,lng)-(.27+.1*kk)*dr,m=diA(d,pu)*fad*(1.-cov);
    float mx=max(max(col.r,max(col.g,col.b)),.05);
    col=mix(col,mix(col*col/mx*.6,col*1.3+.04,kk),m);cov=max(cov,diA(d-dr*.25,pu));
  }
  return col;
}
vec4 diPond(vec2 p0,float P,float zm,float vs,vec3 OC,vec3 BG){
  vec4 po=vec4(0.);
  float zP=exp2(log2(max(zm,.01))*mix(.55,1.,P/5.)),g=.11*exp2(P*.5),kp=uP1.z,ht=uP4.y,bs=uP3.y,stm=uP1.w,mt=uMT;
  vec2 u=rot(P*2.4+vs*6.)*p0/(zP*g);float row=floor(u.y),hr=fract(row*.618+P*.37),sd=(mod(row,2.)*2.-1.)*(.5+.6*hr);
  u.x+=uP1.x*sd*.16+hr*9.+stm*sd*.05;
  vec2 id=floor(u);vec4 h=diQ(id+vec2(P*17.,P*31.));
#if HD>=1
  if(h.x<mix(.9,.26,P/5.)*gPG){
#else
  if(h.x<mix(.9,.26,P/5.)){
#endif
    float R=mix(.17,.3,h.y),ty=floor(h.z*8.),T=mt*(.7+.6*h.w)+h.w*TAU,dr=sign(sd),px=1./(uRes.y*zP*g),pu=px/R;
    vec2 v=fract(u)-.5;v.y-=.09*sin(T*.7)*(1.-R*2.);v.x*=-dr;
    float tilt=(h.w-.5)*1.1+.25*sin(T*.9);vec2 q=rot(-tilt)*v/R;
    int tyI=int(ty);
    float a=PA[tyI],b=PB[tyI],bx=PX[tyI],tl=PT[tyI],A=PF[tyI],fr=PR[tyI],th=PW[tyI],rp=PP[tyI]*(1.+.6*bs),hl=step(ty,.5)*.2,bd=PE[tyI];
    A+=step(abs(ty-1.),.5)*.12*ht;
    float vc=step(abs(ty-6.),.5);tl*=1.-.42*kp*vc;A+=.14*kp*vc;fr+=10.*kp*vc;
    vec2 e=q-vec2(bx,0.);e.y+=bd*sin(q.x*1.7+T);float sw=1.+.16*bs+.05*sin(T*1.4);
    float dB=diEl(e,vec2(a,b)*sw)+rp*(sin(e.x*6.+T*1.8)+.8*sin(e.y*7.5-T*1.3));
    float tx=clamp(bx-a-q.x,0.,tl),dT=length(q-vec2(bx-a-tx,A*sin(fr*tx-T*5.-uP1.y*TAU)*smoothstep(0.,.3,tx)))-th*(1.-.6*tx/max(tl,.01));
    float dd=min(dB,mix(1e3,dT,step(.01,tl))),lodp=smoothstep(10.,28.,1./pu);
    // crown wheels of the rotifer, cilia fringe of the paramecium: drawn outside the body
    vec2 cw=vec2(q.x-bx-a*.86,abs(q.y)-.3);float dC=mix(1e3,length(cw)-.2,step(4.5,ty)*step(ty,5.5));
    dd=min(dd,dC);
    float al=diA(dd,pu);
    vec3 jc=diC(floor(h.w*6.)+P),c=jc;
    float lw=max(.05,1.3*pu),dep=-dd/max(b,.1),t=clamp(dep,0.,1.);
    c=jc*mix(1.3,.72,t)*(.82+.55*bs);

    if(ty<3.5&&ty>2.5){vec2 lb=fract(e/.24+.5*step(.5,fract(e.y/.48)))-.5;
      c=mix(c,diC(floor(h.w*6.)+2.)*(1.1+1.2*bs),diA(length(lb)*.24-.05,pu)*lodp*step(dd,-.07));
      vec2 ld=rot(stm*.12)*e;ld.x=abs(ld.x)-.36;c=mix(c,OC,diA(length(ld)-.22,pu));c=mix(c,diC(floor(h.w*6.)+3.)*1.25,diA(length(ld)-.17,pu));}
    else if(ty>6.5){float cr=abs(fract(q.x*4.5+.35*sin(q.y*8.))-.5);c=mix(c,OC*.85,diA(cr/4.5-.022,pu)*lodp*step(dd,-.07));}
    else if(ty<2.5&&ty>1.5)c=mix(jc*1.4,OC,.5+.5*sin(q.x*16.));
    else{float nd=length(e-vec2(.14*a,0.));c=mix(c,OC,diA(nd-.3*b-.05,pu)*lodp);c=mix(c,diC(floor(h.w*6.)+2.)*(1.2+.9*bs),diA(nd-.3*b,pu)*lodp);}
    c=mix(c,OC*(1.05+.6*kp),diA(abs(dd+lw*.5)-lw*.5,pu));
    // hairs round the cell: amplitude and length from the hats
    if(hl>.0&&dd>0.&&lodp>.01){float ha=abs(fract(e.x*8.+(.3+.8*ht)*sin(e.x*5.-uP1.y*TAU))-.5)/8.;
      al=max(al,diA(ha-.011,pu)*(1.-smoothstep(hl*(.45+.5*ht),hl*(.7+.5*ht),dd))*lodp);c=mix(OC*.95,c,step(dd,0.));}
#if HD>=1
    float dpth=mix(.5,1.,max(P,0.)/3.5);po=vec4(mix(BG*.7,c,min(dpth,1.))*mix(.6,1.,min(max(P,0.)/3.,1.))*(.9+.5*max(uO2.w,ht)*step(.7,h.w)),al*step(1.5,R*zP*g*uRes.y)*mix(.9,.5,step(3.5,P))*(1.-.4*step(P,0.)));
#else
    float dpth=mix(.5,1.,P/3.5);po=vec4(mix(BG*.7,c,min(dpth,1.))*mix(.6,1.,min(P/3.,1.))*(.9+.5*max(uO2.w,ht)*step(.7,h.w)),al*step(1.5,R*zP*g*uRes.y)*mix(.9,.5,step(3.5,P)));
#endif
  }
  return po;
}
#if HD>=1
// V19 DETAIL RANGE (Native and up; HD 0 never sees any of this)
// micro-anatomy: octaves of pores, areolae and striae that double in frequency and appear only when each cell is several pixels
// wide; coloured stain only, coverage capped, cells missing at random and rotated per octave so it never reads as a grid
vec3 diPrint(vec3 col,vec2 q,float pu,float sd,vec3 a1,vec3 a2,float amt){
  int nO=1+HD+int(min(uZoom,0.));
  for(int o=int(min(uZoom,0.));o<nO;o++){
    float fo=float(o),so=13.*pow(2.,fo),fad=smoothstep(3.,7.5,1./(so*pu));
    if(fad<.004)break;
    vec2 g=rot(.67*fo+sd*5.)*q*so;g.x+=.5*mod(floor(g.y),2.);
    vec2 id=floor(g),f=fract(g)-.5;float hh=h21(id+fo*13.+sd*71.),m3=mod(fo,3.);
    float d=mix(mix(length(f)-.2,abs(length(f)-.3)-.06,step(.5,m3)),max(abs(f.y)-.07,abs(f.x)-.34),step(1.5,m3))/so;
    col=mix(col,mix(a1,a2,step(.5,fract(hh*5.+fo*.5))),diA(d,pu)*fad*step(hh,.72)*amt*(.85-.08*fo));
  }
  return col;
}
#endif
void realm(){
  vec2 p0=scr();
  float wr=uP3.x,dc=length(p0),inB=step(dc,wr);
  float C=mix(uP4.x,uP5.x,inB);
  float ev=floor(uP4.z),evp=fract(uP4.z),fam=floor(C),vs=fract(C),csN=floor(uP4.w/4.),ramp=uP4.w-4.*csN;
  float tr=uP1.x,kick=uP1.z,bass=uP3.y,sp=uP3.z,aiA=floor(uP3.w*.5)*.01,dfl=uP3.w-2.*floor(uP3.w*.5),tb=uP5.z,mt=uMT,hat=uP4.y,stm=uP1.w;
  float fMan=step(abs(fam-1.),.5),fCur=step(abs(fam-2.),.5),fSl=1.-fMan-fCur;
  float zm=uZoom*uP5.w;
  // V18 liquid warp: the slide is seen through moving water; the (smoothed) bass pushes a radial swell through it
  vec2 lw0=vec2(sin(p0.y*3.1+mt*.35+1.3*sin(p0.x*1.7-mt*.2)),sin(p0.x*2.7-mt*.28+1.1*sin(p0.y*2.3+mt*.17)));
  vec2 pw=p0+lw0*(.012+.028*bass)+p0*(.05*bass*sin(dc*7.-mt*1.6));
  vec2 p=pw/zm;float px=1./(uRes.y*zm);
  float rr=max(length(p),1e-6);
  float c0=mix(.88,.98,fract(vs*7.31)),gr=mix(1.8,1.92,fract(vs*3.17));
  float rate=1.-.5*step(.75,fract(vs*2.71)),gd=step(.5,fract(vs*4.1))*2.-1.;
  float nt=floor(tb*rate)+diBack(fract(tb*rate)),sw=nt+(tr-tb)*rate;
  // events: 1 a giant ciliate swims through, 2 division bloom (every organism divides in a wave from the centre and
  // the daughters fuse back), 3 a giant radiolarian rises, 4 a giant pennate glides across
  float eDiv=step(abs(ev-2.),.5),evb=evp*mix(16.,8.,eDiv),eRad=step(abs(ev-3.),.5);
  float eHero=step(.5,ev)*(1.-eDiv),hTy=mix(mix(3.,1.,step(2.5,ev)),0.,step(3.5,ev));
  vec2 hp=mix(vec2(mix(-1.6,1.6,evp),.12*sin(evp*5.+ev)),vec2(.35*sin(evp*4.),mix(-1.35,1.35,evp)),eRad);
  float hR=mix(.56,.46,eRad),hang=mix(.1875*cos(evp*5.+ev),nt*TAU/12.,eRad);
  // no event: a free swimmer (ciliate, chain or pennate) cruises a curved path across the slide, propelled by its
  // beating cilia, on its own focal plane above the slide
  float cr=1.-eHero,th0=tb*.05+vs*40.,cT=floor(fract(vs*13.7)*3.);
  vec2 cp=vec2(1.3*sin(th0),.3*sin(1.7*th0+vs*9.)),cv=vec2(1.3*cos(th0),.51*cos(1.7*th0+vs*9.));
  hp=mix(hp,cp,cr);hR=mix(hR,mix(.16,.2,step(.5,cT)),cr);hang=mix(hang,diAt(cv.y,cv.x),cr);
  hTy=mix(hTy,cT<.5?3.:cT<1.5?4.:0.,cr);
  vec2 hq=rot(-hang)*(p0/uZoom-hp)/hR;
  vec2 tC=vec2(0.);float tL=-9.,tTy=0.,tRs=1.,tD=1.,tW=.3,tN=8.,tBand=0.,tDist=0.,tHero=0.,halo=0.;
  vec2 tq=vec2(0.);vec4 th=vec4(0.);float tM=0.,tBu=0.,dNear=1e3;
  vec4 FF=vec4(fSl,fMan,fCur,vs),GG=vec4(c0,gr,sw,rate),HH=vec4(nt,mt,gd,tb);
  vec4 S1=vec4(0.),S2=S1,S3=S1,S4=S1;vec2 D1=vec2(1.,0.),D2=D1,D3=D1,D4=D1;
  // ---- one loop with one silhouette call, big to small (the first hit is on top): iteration 0 is the event hero,
  // then the giant, big, mid, small and tiny layers. On the slide and in the current a candidate is rejected if it
  // would touch one of its ancestors (the organisms of the enclosing bigger cells, already decided in this same pass):
  // heroes stand alone with navy around them and small folk fill only the gaps, with no cut-off shapes.
  // zoomed out, the slide grows giant organisms above the usual cast (up to two layers, each twice the size of the
  // one below): ever bigger cells with the whole field of smaller life packed round them
  float ex=clamp(ceil(-log2(max(zm,.01))-.05),0.,2.);
  int nA=6+int(ex);
#if HD>=1
  float sDrop=0.;int nSd=int(float(HD==1?14:HD==2?20:HD==3?28:HD==4?36:56)*clamp(uDetail/float(HD==1?2.:HD==2?3.:HD==3?4.5:HD==4?6.5:10.),.5,1.6));
#endif
  for(int i=0;i<nA;i++){
    float fi=float(i),isH=step(fi,.5),L=max(5.+ex-fi,0.);
    vec2 q,cC;vec4 h;float ty,Rs,ang,w,n,pres,bnd,dist;
    diOrg(p,L,px,FF,GG,HH,q,cC,h,ty,Rs,ang,w,n,pres,bnd,dist);
    // poster spacing (not for the mandala's rings or the hero)
    // poster packing: a candidate next to a bigger organism shrinks to fit the free space (folk-art nestling);
    // if less than 45% of it would fit it is left out
    float re=mix(mix(.95,.6,step(abs(ty-1.),.5)+step(abs(ty-6.),.5)),.55,step(ty,.5)+step(abs(ty-3.),.5)+step(abs(ty-4.),.5));
    float gp=min(min(diGap(cC,S1,D1),diGap(cC,S2,D2)),min(diGap(cC,S3,D3),diGap(cC,S4,D4)))-.006;
    pres*=1.-step(4.5,L)*fMan;
    float fit=mix(clamp(gp/(Rs*re*1.05),0.,1.),1.,max(fMan,isH));
    pres*=step(.3,fit);Rs*=fit;q/=max(fit,.01);
    // v13: a giant layer added below zoom 2^-(L-4) grows in over a zoom span (each organism at its own moment)
    float zA=.966*exp2(4.-L),gz=mix(1.,smoothstep(zA,zA*.6,zm*(.85+.3*h.x)),step(4.5,L)*(1.-isH));
    pres*=step(.02,gz);Rs*=gz;q/=max(gz,.01);
    vec4 Sn=vec4(cC,Rs*mix(1.,.6,step(abs(ty-1.),.5)+step(abs(ty-6.),.5)),Rs*diAy(ty,w))*pres*(1.-isH)*(1.-fCur*step(4.5,L));vec2 Dn=vec2(cos(ang),sin(ang));
    float k4=step(3.5,L)*(1.-isH),k3=step(abs(L-3.),.5),k2=step(abs(L-2.),.5),k1=step(abs(L-1.),.5);
    S4=mix(S4,Sn,k4);D4=mix(D4,Dn,k4);S3=mix(S3,Sn,k3);D3=mix(D3,Dn,k3);
    S2=mix(S2,Sn,k2);D2=mix(D2,Dn,k2);S1=mix(S1,Sn,k1);D1=mix(D1,Dn,k1);
    float dd=dist*zm;
    // the event hero replaces the generator in the first iteration
    q=mix(q,hq,isH);ty=mix(ty,hTy,isH);Rs=mix(Rs,hR*uZoom/zm,isH);w=mix(w,.3,isH);n=mix(n,16.,isH);dd*=1.-isH;
    h=mix(h,vec4(0.,.5,.5,fract(vs*5.7)),isH);pres=mix(pres,step(1.5,hR*uZoom/zm/px),isH);
    // mitosis: ahead of a phrase wipe, in the division bloom and on drops the cell divides into two daughters
    float mF=smoothstep(wr+.85,wr+.05,dd)*step(1e-4,wr)*(1.-inB);
    float ph1=clamp((evb-1.-2.2*dd)/1.6,0.,1.),ph2=clamp((evb-5.-2.2*dd)/1.6,0.,1.);
    float m=max(mF,eDiv*smoothstep(0.,1.,ph1)*(1.-smoothstep(0.,1.,ph2)))*(1.-isH);
    float born=mix(1.,smoothstep(wr-.02,wr-.3,dd),inB*step(1e-4,wr)*(1.-isH));
    float sc=(1.-.38*m)*mix(.45,1.,born),fy=step(ty,.5)+step(abs(ty-4.),.5);
    // (the first third of a division is the nucleus alone: prophase, metaphase; then the body pinches in two)
    vec2 qa=mix(q,q.yx,fy);qa.x=abs(qa.x)-.47*smoothstep(.3,1.,m);q=mix(qa,qa.yx,fy)/sc;
    // living bodies (the glass diatoms excepted): they breathe with their own clock and swell big with the bass,
    // squash and stretch as they swim, the colonies contract on the kick, and the membrane ripples (harder with the
    // bass, a sharp shiver when the snare's burst wave passes)
    float tO=mt*(.5+.4*h.x)+h.w*TAU,soft=1.-step(ty,.5)-step(abs(ty-2.),.5)-.6*step(abs(ty-1.),.5),rip=step(4.5,ty);
    float bu=clamp(1.-abs(ramp-dd*1.2-.02)*5.,0.,1.)*step(ramp,2.5)*(1.-isH);
    float kp=kick*step(3.5,ty)*step(ty,5.5),sq=soft*sin(tO*1.7),bb=(1.+(.2*soft+.07)*bass+.03*sq)*(1.-.12*kp-.07*kick*soft);
    Rs*=sc*bb;q*=vec2(1.+.07*sq,1.-.07*sq)/bb;
    pres*=step(.02,sc);
    float d=diSil(q,ty,w,n,sp,kick,tO,rip*(.012+.025*bass+.06*bu))*Rs;
    d=mix(1e3,d,pres);dNear=min(dNear,d);
#if HD>=1
    if(pres>.5&&Rs/px>3.&&d<Rs*1.5){float sS=0.;
      for(int sI=int(min(uZoom,0.));sI<nSd;sI++){float fs=float(sI)+.5,ra=sqrt(fs/float(nSd)),an=fs*2.39996;
        float dS=diSil(q-(vec2(.11,.17)+vec2(cos(an),sin(an))*ra*.07),ty,w,n,sp,kick,tO,rip*(.012+.025*bass+.06*bu));
        sS+=diA(dS*Rs,px*1.5);}
      sDrop=max(sDrop,sS/float(nSd));}
#endif
    if(tL<-8.){
      if(d<0.){tC=cC;tL=mix(L,8.,isH);tq=q;tTy=ty;tRs=Rs;tD=d;th=h;tW=w;tN=n;tDist=dd;tBand=bnd;tM=m;tBu=bu;}
      else halo=max(halo,.75*diA(d-max(.014*Rs,1.1*px),px)*smoothstep(2.,6.,Rs/px)*(1.-.8*step(2.5,ty)*step(ty,4.5)));
    }
  }
  // the mandala's centre rosette: a centric wheel whose eight segments are the eight bands
  float cR=.15*(1.+.06*kick);vec2 cq=rot(-nt*TAU/16.*gd)*p/cR;
  float dcr=mix(1e3,(length(cq)-.9)*cR,fMan);
  if(dcr<0.){tL=7.;tq=cq;tTy=2.;tRs=cR;tD=dcr;th=vec4(.5,.5,.5,fract(vs*3.3));tN=8.;tDist=0.;tHero=1.;halo=0.;tM=0.;tBu=0.;}
  else halo=max(halo,diA(dcr-max(.035*cR,1.2*px),px));
  // ---- shading
  vec3 BG=uP2.rgb*(1.32+.18*uB1.x),INK=BG*.42+vec3(.001,.001,.004);
  vec3 OC=mix(vec3(1.95,1.85,1.55),diC(floor(uP2.w))*1.2+.4,fract(uP2.w))*(1.+.2*dfl);
  vec3 col=BG,pF=vec3(0.);float fA=0.;int nSh=2+int(uRes.x<0.),nTi=3+int(uRes.x<0.),nP=6+int(uRes.x<0.);
  // V18 LIVING TISSUE: the slide lies on a sheet of real cells (Voronoi): gel walls in shifting interference colours with
  // beaded channels, each cell with its own stain, granules streaming round a nucleus that beats with the bass. A deep
  // second sheet sits behind it at a slower parallax.
  {float tz=sqrt(max(zm,.05));
#if HD>=1
   nSh+=HD==1?2:HD==2?3:HD==3?4:HD==4?5:6;
   for(int sh=int(min(uZoom,0.));sh<nSh;sh++){float fs=float(sh),ts=fs<1.5?mix(.62,.3,fs):.3*pow(.62,fs-1.);
#else
   for(int sh=0;sh<nSh;sh++){float fs=float(sh),ts=mix(.62,.3,fs);
#endif
    vec2 tp=(pw/tz)/ts+vec2(tr*.016*gd*mix(.5,1.,fs),sin(mt*.05+fs)*.4+fs*5.3),tCm=vec2(0.);tp+=.2*sin(tp.yx*2.1+mt*.14+fs*2.)+.08*sin(tp.yx*5.3-mt*.2);vec2 tI=floor(tp),tF=tp-tI;float d1=9.,d2=9.;vec3 hC=vec3(0.);
    for(int tj=0;tj<nTi;tj++)for(int ti=0;ti<nTi;ti++){vec2 og=vec2(float(ti),float(tj))-1.;vec4 qg=diQ(tI+og+fs*37.);
      vec2 rc=og+.5+.38*sin(qg.xy*6.283+mt*.22*(.5+qg.z))-tF;float dt=dot(rc,rc);
      if(dt<d1){d2=d1;d1=dt;tCm=rc;hC=qg.yzw;}else if(dt<d2)d2=dt;}
    d1=sqrt(d1);d2=sqrt(d2);float ed=(d2-d1),pxT=ts*2./(uRes.y*tz),hb=1.+.32*bass+.08*sin(mt*(.6+hC.y)+hC.z*6.3);
    vec3 cCy=diC(floor(hC.z*6.)+fs*2.),cFilm=.5+.5*cos(6.283*(ed*2.2+mt*.06+hC.x+stm*.05+vec3(0.,.33,.67)));
#if HD>=1
    vec3 tc=mix(BG*.85,cCy*.34,mix(1.,.2,min(fs,1.)))*mix(1.2,.3,clamp(d1*1.6,0.,1.));
#else
    vec3 tc=mix(BG*.85,cCy*.34,mix(1.,.2,fs))*mix(1.2,.3,clamp(d1*1.6,0.,1.));
#endif
        // granules stream round the nucleus (the mids drive the phase)
    {float gx=stm*.32*(hC.x-.5);vec2 gq=fract(rot(gx)*tCm/.11)-.5;tc=mix(tc,cCy*.55,diA(length(gq)*.11-.014,pxT)*smoothstep(.72,.5,d1)*step(.12,d1));}
    // nucleus
    float nd=d1-.13*hb;
    tc=mix(tc,cFilm*.8+.1,diA(abs(nd)-.01,pxT));
    tc=mix(tc,diC(floor(hC.z*6.)+3.)*(.5+1.05*bass),diA(nd+.012,pxT));
    // v20: a close look resolves the nucleus (an inner envelope, a ring of chromatin beads the hats sparkle, a nucleolus), and
    // the kick sends a thin ring of light out of every nucleus toward its cell wall
    if(fs<.5){float nS=.13*hb,nzo=smoothstep(62.*DZ,86.*DZ,.13*ts*tz*uRes.y);
      if(nzo>.003){vec2 nv=rot(stm*.2*(hC.x-.5))*tCm/nS;float nvr=length(nv),nk=floor(diAt(nv.y,nv.x)*12./TAU+.5);
        vec2 nb=rot(-nk*TAU/12.)*nv-vec2(.7,0.);
        tc=mix(tc,BG*.4,diA((abs(nvr-.42)-.035)*nS,pxT)*nzo);
        tc=mix(tc,cFilm*(.7+1.3*uP4.y*mod(nk,2.))+.15,diA((length(nb)-.11)*nS,pxT)*nzo);
        tc=mix(tc,cCy*1.25+.1,diA((length(nv-vec2(.1,.08))-.2)*nS,pxT)*nzo);}
      tc=mix(tc,cFilm*1.1+.25,diA(abs(d1-.17*hb-.36*(1.-kick))-.01,pxT)*kick*smoothstep(0.,.06,ed));}
    // wall: a bright gel seam with moving beads (the hats sparkle them)
    float wg=smoothstep(.0,.05,ed-pxT);
    vec3 wc=cFilm*(.55+.3*hC.x);
    float bk=abs(fract((tp.x+tp.y)*5.+stm*.2)-.5);
    tc=mix(mix(tc,wc,.55+.45*step(.25,bk))*(.9+.9*uP4.y*step(.5,bk)),tc,wg);
    tc=mix(tc,BG*.5,diA(abs(ed-.07)-.012,pxT)*.5);
#if HD>=1
    tc=diPrint(tc,tp,pxT,hC.x+fs,cCy*.75,cFilm*.7,.26);
    // v20: reticulum: dashed membranes wrapped round the nucleus in two to four shells, each turning its own way with the mids
    if(fs<.5){float era=diAt(tCm.y,tCm.x);
      for(int e=int(min(uZoom,0.));e<min(HD+1,4);e++){float fe=float(e),er=.215+.058*fe,ne=10.+4.*fe,ea=era*ne/TAU+stm*.12*(mod(fe,2.)*2.-1.)+hC.x*7.;
        tc=mix(tc,mix(cFilm,cCy,.5)*(.75+.5*uB1.z),diA(max(abs(d1-er*hb)-.007,(abs(fract(ea)-.5)-.3)*er*TAU/ne),pxT)*smoothstep(3.,6.,.007/pxT)*smoothstep(.03,.09,ed));}}
#endif
#if HD>=1
    tc*=1.+.55*uB1.x;wc*=1.;col=mix(col,tc,fs<.5?1.:(fs<1.5?smoothstep(.55,.1,d1)*.55:smoothstep(.5,.15,d1)*.16));
#else
    tc*=1.+.55*uB1.x;wc*=1.;col=mix(col,tc,fs<.5?1.:smoothstep(.55,.1,d1)*.55*(1.-step(.03,ed)*0.)+wg*0.);
#endif
   }
   // the planes of swimmers behind the organisms
#if HD>=1
   gPG=.11;{int nX=HD+2+int(min(uZoom,0.));for(int ip=int(min(uZoom,0.));ip<nX;ip++){vec4 po=diPond(p0,-.6-.22*float(ip),zm,vs,OC,BG);col=mix(col,po.rgb,po.a);}}gPG=1.;
#endif
   for(int ip=0;ip<nP;ip++){float Pi=float(ip);vec4 po=diPond(p0,Pi,zm,vs,OC,BG);
#if HD>=1
     if(Pi<3.5){int nPS=int(float(HD==1?16:HD==2?28:HD==3?36:HD==4?56:96)*clamp(uDetail/float(HD==1?2.:HD==2?3.:HD==3?4.5:HD==4?6.5:10.),.5,1.6));float sA=0.;
       for(int sI=int(min(uZoom,0.));sI<nPS;sI++){float fs=float(sI)+.5,ra=sqrt(fs/float(nPS)),an=fs*2.39996;
         vec2 off=(vec2(.0045,.007)+vec2(cos(an),sin(an))*ra*.0028)*exp2(Pi*.5);
         sA+=diPond(p0-off,Pi,zm,vs,OC,BG).a;}
       col=mix(col,col*.5+BG*.06,.55*sA/float(nPS));}
#endif
     if(Pi<3.5)col=mix(col,po.rgb,po.a);else{pF=pF*(1.-po.a)+po.rgb*po.a;fA=1.-(1.-fA)*(1.-po.a);}}
  }
#if HD>=1
  col=mix(col,col*.5+BG*.08,.62*sDrop);
#endif
  // the stain ground: tiny jewels sprinkled everywhere (they twinkle with the air band)

  if(tL>-8.){
    vec2 q=tq;float Rs=tRs,pu=px/Rs,dep=-tD/Rs,r=length(q),a=diAt(q.y,q.x),ty=tTy;
    vec4 h=th;float cs=floor((csN+floor(fract(h.z*7.3)*3.)+step(tDist*1.2+.02,ramp)*step(ramp,2.5))/3.),tO=mt*(.5+.4*h.x)+h.w*TAU;
    float ci=floor(h.w*6.)+cs,lw=max(.024,1.1*pu),ow=max(.025,.9*pu),lod=smoothstep(4.,14.,1./pu);
    vec3 J0=diC(ci),J1=diC(ci+1.),J2=diC(ci+2.),J3=diC(ci+3.),J4=diC(ci+4.),J5=diC(ci+5.);
    vec3 oc=mix(J1*1.3,OC,smoothstep(5.,18.,1./pu));
    float bnd=tBand,on=diOn(bnd),lv=diBand(bnd),w=tW,gmask=1.,mid=max(uB1.z,uB1.w);
    float k=floor(a*tN/TAU+.5);vec2 s=rot(-k*TAU/tN)*q,gq=q;
    float pfz=smoothstep(9.*DZ,14.*DZ,lw/pu);vec3 pfc=mix(INK*1.6,J2*1.7,kick);
    if(ty<.5){
      // PENNATE DIATOM: a dense comb of cream ribs inside the double outline, a pink seam, a beaded teal band, cool
      // dotted cytoplasm and a fine raphe
      float R0=(1.+w*w)/(2.*w),hw=max(sqrt(max(R0*R0-q.x*q.x,0.))-(R0-w),1e-3),fb=.44*w;
      float nr=mix(38.,46.,h.z),rr2=smoothstep(1.5,3.,1./(nr*pu)),rib=diA(abs(fract(q.x*nr)-.5)/nr-.2/nr,pu)*rr2+.4*(1.-rr2);
      col=mix(oc,mix(INK*1.5,J4*1.3,hat*smoothstep(.2,1.,sin(q.x*7.-uP1.y*TAU))),rib*step(lw*2.6,dep));  // hats glint along the comb
      col=mix(col,J2*1.4,diA(fb-dep,pu));
      vec3 tb2=J4*1.1;float bx=fract(q.x/.034)-.5;
      tb2=mix(tb2,oc,diA(length(vec2(bx*.034,dep-fb-.09*w))-.007,pu)*lod);
      col=mix(col,tb2*(.6+.8*uB2.y),diA(fb+.04*w-dep,pu));
      vec3 body=J3*mix(1.15,.6,abs(q.y)/hw)*(.7+1.*mid);
      vec2 g=fract(vec2(q.x-stm*.09*sign(q.y),q.y)/.05)-.5;body=mix(body,body*1.5+.1+.5*mid,diA(length(g)*.05-.007-.004*mid,pu)*lod);
      col=mix(col,oc,diA(fb+.14*w-dep,pu));
      col=mix(col,body,diA(fb+.14*w+lw*.6-dep,pu));
      col=mix(col,oc*.85,diA(length(vec2((fract((q.x-stm*.07)/.03)-.5)*.03,q.y))-.008,pu)*step(abs(q.x),.9)*lod);
    }else if(ty<1.5){
      // RADIOLARIAN: long pin-tipped spines (longer with the highs; pins flash on the air band) alternating with a
      // crown of short ones, a white lace of round holes in rings, a star of jewel kites, a two-ring beaded core
      float ln=diSpk(k,sp,1.,tO);
      if(r>.455){
        col=oc*.95;
        col=mix(col,diC(ci+k)*(1.1+1.6*hat),diA(abs(s.y)-.005-.005*hat,pu)*step(s.x,ln-.06)*(1.-mod(k,2.))*lod);
        // granules stream out along the axopods
        float ax=(fract((s.x-stm*.12)/.075)-.5)*.075;
        col=mix(col,diC(ci+k+2.)*(1.3+1.2*hat)+.15,diA(length(vec2(ax,s.y))-.014,pu)*step(s.x,ln-.07)*(1.-mod(k,2.))*lod);
      }else{
        float ri=floor((r-.2)/.085),rc=.2+(ri+.5)*.085,nh=max(floor(TAU*rc/.08),6.),kh=floor(a*nh/TAU+.5);
        vec2 hq=rot(-kh*TAU/nh)*q-vec2(rc,0.);float hrd=.026+.004*ri,res=smoothstep(1.,2.5,hrd/pu);
        col=mix(oc,mix(INK*1.6,diC(ci+ri+4.)*1.2,.75*hat*step(.5,fract(kh*.37+ri*.5))),(diA(length(hq)-hrd,pu)*res+.42*(1.-res))*step(.2,r));
        // bead rings round the holes swell and glow with the bass
        col=mix(col,diC(ci+ri+2.)*(.45+1.3*uB1.y),diA(abs(length(hq)-hrd*1.42)-hrd*(.14+.12*uB1.y),pu)*res*step(.2,r));
        {float lz=smoothstep(8.*DZ,13.*DZ,hrd/pu)*step(.2,r),lh=length(hq);
         col=mix(col,oc*.92,diA(abs(lh-hrd*.56)-hrd*.085,pu)*lz);
         col=mix(col,diC(ci+ri+1.)*(1.+1.6*max(uB2.z,uB2.w)),diA(lh-hrd*.24,pu)*lz);}
        col=mix(col,oc,diA(r-.205,pu));
        col=mix(col,J5*(.5+.9*mid),diA(r-.205+lw,pu));
        col=mix(col,oc,diA(abs(r-.135)-lw*.3,pu)*lod);
      }
    }else if(ty<2.5){
      // CENTRIC DIATOM: a stained-glass wheel; segments alternate colours behind cream spokes and rows of dots. It
      // blooms on its band's onset (the mandala rosette: segment k = band k)
      float bk=mix(bnd,k,tHero),bl=mix(1.,.55+.9*diBand(bk),tHero)+1.3*diOn(bk)+(.3*lv+.45*uB2.y)*(1.-tHero);
      col=INK*1.2+J5*.12;
      // two stained-glass bands per segment, cream-and-navy leading between the panels, a cream ring between bands
      float ob=step(.5,r);
      vec3 sa=mix(J3,J4,mod(k,2.))*bl*(.4+1.15*uB1.y)*mix(1.05,.8,clamp((r-.22)/.28,0.,1.)),sb=mix(J1,J5,mod(k,2.))*bl*(.55+.95*uP5.y)*mix(1.15,.8,clamp((r-.5)/.26,0.,1.));
      vec3 sc=mix(sa,sb,ob);
      col=mix(col,oc,diA(r-.76,pu));col=mix(col,sc,diA(r-.76+lw,pu));
      vec2 dq=vec2(s.x-mix(.36,.63,ob),mix(s.y,abs(s.y)-.075*r/.63*(10./tN),ob));
      col=mix(col,oc,diA(length(dq)-mix(.045,.036,ob)-.008*bl,pu)*step(r,.74));
      col=mix(col,sc*.6,diA(length(dq)-mix(.022,.017,ob),pu)*step(r,.74)*lod);
      float sd=abs(s.x*sin(PI/tN)-abs(s.y)*cos(PI/tN)),rl=abs(r-.5);
      col=mix(col,INK*1.2,diA(min(sd,rl)-lw*1.1,pu)*step(.2,r)*step(r,.76));
      col=mix(col,oc,diA(min(sd,rl)-lw*.4,pu)*step(.2,r)*step(r,.76));
      col=mix(col,oc,diA(r-.22,pu));col=mix(col,J2*.8,diA(r-.22+lw,pu));
    }else if(ty<3.5){
      // CILIATE: a paisley leaf cell. Hairs fringe it in a metachronal wave (faster with the hats), a comb rim of cream
      // ribs, a pink bead line, a lime body with a pink bead midrib and tilted leaf chloroplasts lit by the mids
      vec2 e=diCe(q,tO);float dB=diLeaf(e),ea=diAt(e.y/.52,e.x/.82);
      gq=vec2(e.x,e.y-.05*sin(e.x*4.));gmask=step(dB,-.14);
      if(dB>0.){
        float t=dB/.13,hs=4./96.,hl=.62+.25*sp+.35*hat;
        float hx=fract(ea*96./TAU+t*t*(.8+1.5*hat)*sin(ea*5.-uP1.y*TAU))-.5;
        col=mix(col,oc*(.85+.6*hat),diA(abs(hx)*hs-max(.0045,.45*pu),pu)*(1.-smoothstep(hl-.25,hl,t))*smoothstep(1.,2.5,hs/pu));
      }else{
        float de=-dB,res=smoothstep(1.5,3.,.036/pu),rib=diA((abs(fract(ea*90./TAU)-.5)-.2)*.036,pu)*res+.4*(1.-res);
        col=J3*mix(1.15,.65,clamp(de/.3,0.,1.))*(.7+.9*mid);
        col=mix(col,mix(J5*.9,oc,rib),diA(de-.085,pu));
        col=mix(col,oc,diA(abs(de-.09)-lw*.3,pu));
        float eb=ea-stm*.25,kb=floor(eb*44./TAU+.5);vec2 bq=vec2((eb-kb*TAU/44.)*.55,de-.115);
        col=mix(col,J2*(1.+1.4*uP5.y),diA(length(bq)-.016-.008*uP5.y,pu)*lod);
        col=mix(col,oc,diA(de-lw,pu));
        col=mix(col,pfc,diA(abs(de-lw*.5)-lw*.11,pu)*pfz);
        col=mix(col,J2*(1.+1.2*uP5.y),diA(abs(de-lw*1.45)-lw*.35,pu)*lod);
      }
    }else if(ty<4.5){
      // CHAIN COLONY: a jelly sheath of cells that pulse on the kick, bristles at every junction
      float dB=length(vec2(q.x-clamp(q.x,-.66,.66),q.y))-.23;gmask=step(dB,0.);
      if(dB>0.){
        float xj=(floor(q.x/.34)+.5)*.34;
        col=mix(col,oc*(.9+.5*hat),diA(abs(q.x-xj-dB*(.6+2.*hat)*sin(uP1.y*TAU+xj*4.))-max(.008,.5*pu),pu)*step(abs(xj),.6)*(1.-smoothstep(.05,.075,dB))*lod);
      }else{
        col=J3*.3;
        col=mix(col,oc,diA(-dB-lw,pu));
        col=mix(col,pfc,diA(abs(-dB-lw*.5)-lw*.11,pu)*pfz);
      }
    }else if(ty<5.5){
      // FLOWER CLUSTER: petal cells pressed together, each with a dotted fill; they spread and glow on the kick
      vec2 pq=s-vec2(diPet(k,kick,tO),0.);float dp=length(pq)-.36;
      vec3 pc=diC(ci+k)*(.7+.5*kick+.7*mid);
      vec2 g=fract((pq-vec2(stm*.08,0.))/.07)-.5;
      col=mix(pc*mix(1.15,.7,length(pq)/.36),pc*.5+1.,diA(length(g)*.07-.012,pu)*lod);
      float th2=PI/tN,dsec=s.x*sin(th2)-abs(s.y)*cos(th2);
      col=mix(col,oc,max(diA(dsec-lw*.5,pu),diA(-dp-lw,pu))*step(.3,r));
    }else if(ty<6.5){
      // STAR RADIOLARIAN: jewel arms with bead lines, pin tips, a dotted core
      float ln=diSpk(k,sp,6.,tO),fx=s.x-stm*.06,tbd=fx-floor(fx/.13+.5)*.13;
      col=mix(J2,J3,mod(k,2.))*mix(1.1,.65,clamp(s.x/ln,0.,1.))*(.65+.8*mid);
      col=mix(col,oc,diA(length(vec2(tbd,s.y))-.032*(1.-.5*s.x/ln),pu)*step(.3,r)*step(s.x,ln-.03)*lod);
      col=mix(col,oc,diA(r-.3,pu));col=mix(col,J4,diA(r-.3+lw,pu));
    }else{
      // MICRO ROSETTE: a jewel ringed with tiny beads and a sunburst of dots; twinkles on the air band
      col=J0*mix(1.15,.7,r/.62)*(.6+.8*uB2.y+.6*hat);
      col=mix(col,oc,diA(.62-lw-r,pu));col=mix(col,BG,diA(.62-r,pu));
    }
    {float mxc=max(max(col.r,max(col.g,col.b)),.05),sat=1.-min(col.r,min(col.g,col.b))/mxc;
     col=diAre(col,gq,.0143,step(ty,.5)+step(abs(ty-3.),.5)+step(abs(ty-4.),.5),pu,smoothstep(.3,.6,sat)*smoothstep(lw*2.,lw*3.5,dep),kick);}
    // jewel layers (rings, rows, grids), one loop for every type
    for(int j=0;j<6;j++){
      vec4 A,B;float E,Fl;diLay(ty,float(j),A,B,E,Fl);
      if(A.x>2.5)break;
      // rings orbit (organelles streaming round the cell), grid rows flow in opposite directions (cyclosis)
      float n=mix(A.z,tN*(1.+A.z),step(A.z,0.)),fph=Fl*stm/max(A.y,.15),kb=floor((a-fph)*n/TAU+.5),kr=0.;
      float rdi=mix(A.y+B.w*mod(kb,2.),diSpk(kb,sp,ty,tO)+.04*step(5.5,ty),step(.01,E)*step(ty,6.5));
      vec2 lq=rot(-kb*TAU/n-fph)*gq-vec2(rdi,0.);
      float of=.5-.5*mod(n,2.),hn=(n-1.)*.5,sA=max(A.y,.01),gfr=Fl*stm*.6,cx=floor((gq.x-gfr)/sA+.5-of)+of;
      cx=mix(clamp(cx,-hn,hn),cx,step(.001,abs(Fl)));float cxp=cx*A.y+gfr;cx=mod(cx+hn,n)-hn;
      float cgy=clamp(floor(gq.y/(sA*E))+.5,-.5,.5),gfo=Fl*stm*.6*sign(cgy),cgx=floor((gq.x-gfo)/sA+.5);
      vec2 cg=vec2(cgx,cgy);
      lq=mix(lq,gq-vec2(cxp,0.),step(.5,A.x));kb=mix(kb,cx,step(.5,A.x));
      lq=mix(lq,rot(-sign(cg.y)*B.w)*(gq-cg*vec2(A.y,A.y*E)-vec2(gfo,0.)),step(1.5,A.x));kb=mix(kb,cg.x,step(1.5,A.x));kr=(cg.y+.5)*step(1.5,A.x);
      // brightness sources: 0 steady, 1 presence, 2 kick, 3 hats, 4 bass, 5 sub onset, 6 own onset, 7 mid band
      // by column, 8 twinkle, 9 equaliser (bead k = band k), 10 contractile vacuole (empties on the kick)
      float bs=B.z,eqb=kb+hn+mix(0.,2.,step(6.5,bs)*step(bs,7.5)),eql=diBand(eqb),eqo=diOn(eqb);
      float br=bs<.5?1.:bs<1.5?.7+1.2*uP5.y:bs<2.5?.7+1.1*kick:bs<3.5?.9+2.*hat:bs<4.5?.6+1.2*uB1.y:bs<5.5?1.+.8*uO1.y:
        bs<6.5?.9+.8*on:bs<7.5?.5+.8*mid+.5*eql+.7*eqo:bs<8.5?1.+1.5*max(uO2.w,hat)*step(.6,h.y):bs<9.5?.4+1.1*eql+.9*eqo:1.2+1.2*kick;
      vec2 sz=vec2(B.x,B.y<0.?max(.6*w*(.62-cxp*cxp),.012):B.y)*(1.+.14*clamp(br-1.,-.5,1.2))*(1.-.5*kick*step(9.5,bs));
      // rows: each cell (colony cell, chloroplast) jostles and now and then divides into two and fuses back
      float dv=B.w*step(.5,A.x)*step(A.x,1.5)*pow(max(0.,sin(tO*.7-kb*1.3)),4.);
      lq.x=mix(lq.x,abs(lq.x-.03*B.w*sin(tO*1.3+kb*1.9))-dv*sz.x*.55,step(.5,A.x)*step(A.x,1.5));sz.x*=1.-.35*dv;
      float cw=floor(A.w)+mix(0.,mod(kb,2.),step(.4,fract(A.w)))+mix(0.,kb+kr-mod(kb,2.),step(.7,fract(A.w)));
      vec3 jc=A.w<0.?oc:diC(ci+cw)*br;
      float dj=diEl(lq,sz);dj=mix(1e3,dj,gmask);
      float rad=min(sz.x,sz.y);vec2 nq=lq/sz;
      col=mix(col,oc,diA(dj,pu));
      vec3 jf=jc*(1.2-.45*length(nq-vec2(-.35,.4)));
#if HD>=1
      if(rad/pu>24.*DZ&&A.w>=0.)jf=diAre(jf,lq,rad*.16,0.,pu,smoothstep(.62,.5,length(nq)),kick);
#endif
      col=mix(col,jf,diA(dj+ow*step(0.,A.w),pu));
      // v20: a close look finds an engraved inner rim in every jewel (a deeper shade of the jewel itself)
      col=mix(col,jc*jc/max(max(jc.r,max(jc.g,jc.b)),.05)*.62,diA((abs(length(nq)-.68)-.04)*rad,pu)*smoothstep(20.*DZ,32.*DZ,rad/pu)*step(0.,A.w)*step(dj+ow*2.,0.));
      vec2 dq=vec2(nq.x-clamp(floor(nq.x*2.2+.5),-1.,1.)/2.2,nq.y*.8);
      col=mix(col,jc*.45+1.1,diA(length(dq)-.15,pu/rad)*step(dj+ow*2.,0.)*smoothstep(7.,14.,rad/pu)*step(0.,A.w));
      col=mix(col,jc*.4+1.6,diA(length(nq-vec2(-.38,.42))-.2,pu/rad)*smoothstep(3.,6.,rad/pu)*step(dj+ow,0.));
      // v20 millgrain: and its cream setting milled into a ring of grains; one in five is lit and they run round with the hats
      {float mgz=smoothstep(8.*DZ,12.*DZ,ow/pu)*step(0.,A.w)*step(abs(dj+ow*.5),ow*.7);
       if(mgz>.003){float ja=diAt(nq.y,nq.x),jN=max(floor(TAU*rad/(ow*1.3)),8.),jk=floor(ja*jN/TAU+.5);
         col=mix(col,mix(INK*1.5,diC(ci+cw+2.)*1.7,step(mod(jk-floor(uP1.y*6.),5.),.5)*min(1.,.25+hat)),diA(length(vec2((ja-jk*TAU/jN)*rad,dj+ow*.5))-ow*.27,pu)*mgz);}}
    }
    if(abs(ty-3.)<.5){
      // the ciliate's two contractile vacuoles: star-shaped, they fill between kicks and empty on the kick (the
      // radiating canals swell as they collect the water again)
      vec2 vq=vec2(abs(gq.x)-.43,gq.y-.03);float vr=length(vq),vk=.07*(1.-.75*kick)*(.85+.4*bass)+.012;
      vec2 va=abs(vq);float cnl=min(min(va.x,va.y),abs(va.x-va.y)*.707);
      col=mix(col,J4*1.3+.2,diA(cnl-(.008+.022*kick)*(1.-vr/.17),pu)*step(vr,.17)*lod);
      col=mix(col,oc,diA(vr-vk,pu));col=mix(col,J4*(1.3+.8*kick)+.15,diA(vr-vk+lw*.8,pu));
      col=mix(col,vec3(2.),diA(length(vq-vec2(-.3,.35)*vk)-.22*vk,pu));
    }
    // Vesicles circulate inside each membrane; coherent orbits, no random frame-to-frame jitter.
    // NUCLEUS (every cell but the colonies and rosettes): granules of chromatin boil inside a cream envelope round a
    // jewel nucleolus. In mitosis (phrase wipes, division blooms) the envelope dissolves, the chromatin condenses into
    // chromosomes that line up on the plate under cream spindle fibres, then part with the daughters. The snare's
    // burst wave flashes it.
    float nR=ty<.5?.085:ty<1.5?.12:ty<2.5?.13:ty<3.5?.14:ty<4.5?0.:ty<6.5?.14:0.;
    if(nR>0.){
      vec2 nq=(gq-vec2(mix(0.,-.05,step(abs(ty-3.),.5)),0.))/nR;nq.y*=mix(1.,1.5,step(abs(ty-3.),.5));
      float m=tM,env=1.-smoothstep(.06,.2,m)*(1.-smoothstep(.85,1.,m)),mch=smoothstep(.04,.26,m)*(1.-smoothstep(.88,1.,m));
      float nb=1.+.06*sin(tO*1.7)+.1*bass+.2*tBu,nr=length(nq),nd=(nr-nb)*nR;
      col=mix(col,oc,diA(nd,pu)*env);
      col=mix(col,mix(J4*.5+.1,J2*.6+.15,.5+.5*sin(tO+nr*4.))*(1.+1.2*tBu),diA(nd+lw*1.1,pu)*(.25+.75*env));
      vec2 gg=nq/.26+vec2(0.,tO*.15),gc=fract(gg)-.5,gi=floor(gg);float gh=fract(dot(gi,vec2(.37,.71))*7.3);
      col=mix(col,mix(J5,J0,step(.5,gh))*(1.2+1.5*tBu)+.1,diA((length(gc)-.13-.12*sin(tO*2.3+gh*6.))*.26*nR,pu)*step(nr,nb-.18)*(1.-mch)*lod);
      vec2 no=nq-vec2(.3,.22);col=mix(col,J1*1.5,diA((length(no)-.27*(1.+.15*bass))*nR,pu)*(1.-mch));
    }
    if(ty<.5)col=mix(col,oc*.9,diA(abs(fract(a*12./TAU)-.5)*r*TAU/12.-.006,pu)*step(.11,r)*step(r,.15)*lod);
    // cream membrane outline on the silhouette (types whose silhouette is the body)
    float gen=1.-step(abs(ty-3.),.5)-step(abs(ty-4.),.5)-step(abs(ty-7.),.5);
    col=mix(col,oc,diA(dep-lw,pu)*gen);
    // v20 purfling: a close look finds a groove inlaid down every cream membrane; the kick fills it with light
    col=mix(col,pfc,diA(abs(dep-lw*.5)-lw*.11,pu)*gen*pfz);
    // and jewel granules streaming out along the radiolarian's spines (mids move them, hats light them)
    if(abs(ty-1.)<.5&&r>.455){float ax=(fract((s.x-stm*.12)/.05)-.5)*.05;
      col=mix(col,diC(ci+k+2.)*(1.+1.6*hat),diA(length(vec2(ax,s.y))-.0045,pu)*step(s.x,diSpk(k,sp,1.,tO)-.07)*smoothstep(1.6*DZ,2.6*DZ,.0045/pu));}
    float gen2=gen*(1.-step(abs(ty-1.),.5)-step(abs(ty-6.),.5))*smoothstep(10.,24.,1./pu);
    col=mix(col,J2*(1.2+1.4*kick),diA(abs(dep-lw*1.5)-lw*(.42+.3*kick),pu)*gen2);
    col=mix(col,oc,diA(abs(dep-lw*2.25)-lw*.3,pu)*gen2);
    // v13: a beaded border just inside the membrane (cream and jewel beads that glint with the hats); it resolves on
    // bodies above ~45 px radius, so heroes carry it at the default framing and zooming in reveals it on more cells
    float bz=smoothstep(45.*DZ,95.*DZ,1./pu)*gen*(1.-step(abs(ty-1.),.5)-step(abs(ty-6.),.5));
    if(bz>.002){float bu=mix(a*max(r,.2),q.x,step(ty,.5))*44.,bk=floor(bu+.5);
      float db=length(vec2((bu-bk)/44.,dep-lw*3.6))-.0085;
      col=mix(col,mix(oc,J4*1.5,mod(bk,2.))*(1.+.9*hat*step(.5,fract(bk*.37+tO*.1))),diA(db,pu)*bz);}
    // V18 volume: a glassy dome light on each body, a darkfield rim that runs through interference colours (the mids move
    // it), and a hot specular that catches the highs
    {float dmF=clamp(dep/.4,0.,1.);dmF=sqrt(dmF*(2.-dmF));float rf=1.-dmF;vec2 lq=q-vec2(-.34,.42);
     col*=mix(.72,1.12,dmF);
     col+=(.5+.5*cos(6.283*(rf*1.1+a*.16+stm*.08+h.w+vec3(0.,.33,.67))))*rf*rf*rf*(.12+.38*mid)*smoothstep(12.,40.,1./pu);
     col+=vec3(1.3,1.25,1.1)*(.16+.75*hat)*exp(-dot(lq,lq)*18.)*step(0.,dep);}
  }
  // V18 Becke fringes: every organism rings the water round it with rainbow interference (bass pushes them outward)
  if(tL<-8.&&dNear<.3){float dd=dNear*zm;
    col+=(.5+.5*cos(6.283*(dd*5.5-mt*.09-stm*.06+vec3(0.,.33,.67))))*(.18+.7*bass)*.26*exp(-dd*14.)*smoothstep(0.,.008,dd)*(.55+.45*cos(dd*150.-bass*4.-mt*1.3));}
  if(tL<-8.&&dNear<.3)col=mix(col,OC*1.1,diA(abs(dNear*zm-.006-.035*(1.-kick))-.0016,1./uRes.y)*kick*.85);
  col=mix(col,INK,halo);
  // the near pond planes swim over the slide
  col=col*(1.-fA)+pF;
  // the stain front: a cream membrane sweeps outward with every new slide
  float wm=step(1e-4,wr)*step(wr,1.3);
  col=mix(col,OC*1.3,diA(abs(dc-wr)-.009,1./uRes.y)*wm);
  col*=1.+.1*dfl;
  // V18 hue wash: colour runs over the slide in slow continents; the mids push it along, drops surge it
  {float hA=1.7*(sin(p0.x*1.1+stm*.08+mt*.05)+sin(p0.y*1.6-mt*.07+.9*sin(p0.x*.8+stm*.06)))*.5+1.4*dfl,hc=cos(hA),hs=sin(hA);
   col=max(col*hc+cross(vec3(.57735),col)*hs+vec3(.57735)*dot(vec3(.57735),col)*(1.-hc),0.);}
  // v13 air / hats: polarised-light shimmer, a slowly flowing web of interference light over the slide; brightness = the air level and
  // the hat activity (light only: it lifts the colour underneath, its strongest channel most, so hue and saturation stay)
  {vec2 sq=p0*6.;float iv=sin(sq.x*1.3+1.4*sin(sq.y*1.1+uTime*.5))+sin(sq.y*1.5+1.4*sin(sq.x*.9-uTime*.45)),il=clamp(1.-abs(iv)*2.5,0.,1.);
   col+=.7*aiA*il*il*col*col/max(max(col.r,max(col.g,col.b)),.05);}
  // V18: the additive light above greys the jewels a little; push chroma back so the slide stays stained-glass vivid
  {float gy=dot(col,vec3(.2126,.7152,.0722));col=max(mix(vec3(gy),col,1.42),0.);}
  fragColor=vec4(col,0.);
}
`;
