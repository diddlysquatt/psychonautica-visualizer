const R_MANDALA = `
// palette with its coefficients blended once per pixel: during a palette change the cosine palette itself morphs
// (a hue sweep, never grey), and each lookup costs one cosine; outside a change it equals pal()
vec3 gPa,gPb,gPc,gPd;
vec3 dlS(vec3 c){float mx=max(c.r,max(c.g,c.b)),mn=min(c.r,min(c.g,c.b));float s=(mx-mn)/(mx+1e-5);return mx-(mx-c)*min(max(s,.80)/max(s,1e-3),3.);}
vec3 dlP(float t){return dlS(max(gPa+gPb*cos(TAU*(gPc*t+gPd+uHue)),0.));}
// orbit accumulators shared by the deep (perturbation) phase and the plain phase
float gSt,gSt0,gTr,gTrD,gHit,gHitI;vec2 gW,gWd;
#if HD>=1
// v19: High's render pixel relative to this tier's (High is .78x, the tiers 1, 1.5, 2, 3, 4x): the field's light falloffs use distance in High's pixels, so every tier keeps High's light
float dlK(){return HD<2?.78:(HD==2?.52:(HD==3?.39:(HD==4?.26:.195)));}
// the distance estimate (in pixels) at another point of the plane, for the self-shadow rays: the same two-phase orbit as dlShade, nothing else
float dlQ(vec2 dl,vec2 dz,float px,float mx2){
  float n=floor(uP1.x+.001),D=min(uP3.z,64.),P=max(mod(floor(uP3.w+.001),16.),1.),m2=0.,dzs=0.;
  vec2 c=uP2.xy,z=uP4.xy+dl;
  for(int i=min(int(uTime),0);i<1200;i++){
    float fi=float(i);
    if(fi>=mx2)break;
    bool dp=fi<D;
    vec2 zr=vec2(0.),a=z;
    if(dp){float k=fi-P*floor((fi+.5)/P);zr=k<.5?uP4.xy:(k<1.5?uP4.zw:(k<2.5?uP5.xy:uP5.zw));a=zr+dl;}
    m2=dot(a,a);
    if(m2>1e4){
      float lde=log(.25*sqrt(m2)*log(m2))-log(length(dz)+1e-30)-dzs*2.302585;
      return exp(clamp(lde-log(px),-30.,30.));
    }
    if(dp){
      vec2 S=vec2(1.,0.),bm=vec2(1.,0.),am=vec2(1.,0.);
      for(int m=1;m<8;m++){if(float(m)>=n)break;bm=cmul(bm,zr);am=cmul(am,a);S=cmul(a,S)+bm;}
      dz=n*cmul(am,dz);
      dl=cmul(dl,S);
      if(fi+1.>=D){float k2=D-P*floor((D+.5)/P);z=(k2<.5?uP4.xy:(k2<1.5?uP4.zw:(k2<2.5?uP5.xy:uP5.zw)))+dl;}
    }else{
      vec2 zn1=z;
      for(int j=0;j<7;j++){if(float(j)>=n-2.)break;zn1=cmul(zn1,z);}
      dz=n*cmul(zn1,dz);
      float d2=dot(dz,dz);if(d2>1e16){dz*=1e-8;dzs+=8.;}else if(d2<1e-16){dz*=1e8;dzs-=8.;}
      z=cmul(zn1,z)+c;
    }
  }
  return 0.;
}
#endif
void dlAcc(vec2 z,vec2 dz,float sd,float ph,float rho,float rhoJ,float it){
  gSt0=gSt;gSt=mix(gSt,.5+.5*sin(sd*atan(z.y,z.x)+ph),.32);
  float l=length(z),dl=max(length(dz),1e-30);
  // ring trap measured in screen units (distance in z_k divided by |dz_k|), so its lines stay one pixel sharp at every depth
  float rt=max(rho*1.9,.35),t=abs(l-rt)/dl;
  if(t<gTr){gTr=t;gTrD=rt/dl;}
  // critical-point trap: the first time the orbit falls into the disc round 0 marks a pulled-back copy of that disc
  if(gHit<.5&&l<rhoJ){gHit=1.;gHitI=it;gW=z/rhoJ;gWd=dz/rhoJ;}
}
// hue rotation about the grey axis (the drop's hue sweep); fixed accents use channel swaps, a 120 degree turn about grey
vec3 dlRot(vec3 c,float a){const vec3 k=vec3(.57735);float cs=cos(a),sn=sin(a);return max(c*cs+cross(k,c)*sn+k*dot(k,c)*(1.-cs),0.);}
// v20 glass colour: the palette with a floor. A band whose palette phase fell on a black stretch of the palette made a black moat round the set
vec3 dlPg(float t){vec3 c=dlP(t),d=dlP(t+.37).brg;float m=max(c.r,max(c.g,c.b));c=mix(d,c,smoothstep(.1,.5,m));m=max(c.r,max(c.g,c.b));return c*(max(m,.55)/max(m,.05));}
// v20 a leaded-glass pane lattice with a rose in every pane. gc: lattice coordinates, upx: lattice units per pixel. Pane size follows the pixel footprint by halves
// (two levels cross-faded), so there is always a rose of about the same size on screen, at every zoom and tier. Returns the glass colour at unit light; ld = lead coverage.
// One call per pixel (the far field, the basins and the gem tables only hand it different coordinates), so D3D compiles one copy.
// the pane is the same size on screen at every tier (a smaller pane at Native made the wall read finer but darker: more lead per area); the tiers add work inside it
#define DL_PT 66.
vec3 dlPane(vec2 gc,float upx,float sd,out float ld){
  float rs=clamp(uRes.y/1080.,.5,4.),lv=max(log2(1./(max(upx,1e-7)*DL_PT*rs)),0.),L0=floor(lv),wf=smoothstep(.55,.95,lv-L0);
  vec3 o=vec3(0.);ld=0.;
  for(int k=min(int(uTime),0);k<2;k++){
    float w=k==0?1.-wf:wf;
    if(w>.01){
      float sc=exp2(L0+float(k)),pxl=1./(upx*sc),fd=smoothstep(5.,13.,pxl),big=smoothstep(30.,52.,pxl);
      vec2 g=gc*sc,id=floor(g),fc=g-id-.5;
      float h=h21(id*.37+vec2(sd*3.1+sc*.17,sd*1.7)),K=4.+2.*floor(fract(h*7.3)*3.);
      float r=length(fc),a=atan(fc.y,fc.x),sn=abs(sin(a*K*.5+floor(h*2.)*1.5708)),cp=1.-sn,rp=.13+.27*cp;
      float d1=r-rp,d2=r-.085,d3=.5-max(abs(fc.x),abs(fc.y)),rv=length(abs(fc)-.5),d4=rv-.19,d5=abs(r-.455);
      float t0=h*.14+.13+sd*.085,jw=step(.9,fract(h*13.7));
      vec3 cA=dlPg(t0),gd=cA*(.2+.3*smoothstep(.5,.1,r)),pt=dlPg(t0+.22+.3*jw)*(.5+.75*(1.-r/max(rp,.05))),sp=dlPg(t0+.55).brg*(.35+.5*smoothstep(-.19,0.,d4)),ct=mix(dlPg(t0+.7),vec3(1.),.35)*1.25;
      // the rose: outer petals with a lit rim and a vein, a second ring of petals turned half a step, a boss with its own eye at every lattice vertex
      pt*=1.+.45*clamp(1.+d1*pxl*.4,0.,1.)*big;
      float d6=r-rp*.52*(.6+.4*sn),lv2=0.;
      pt=mix(pt,dlPg(t0+.47)*(.75+.5*cp),clamp(.5-d6*pxl,0.,1.)*big);
      lv2=max(clamp(.9-abs(d6)*pxl,0.,1.)*.8,clamp(1.-r*sn*(2./K)*pxl*1.4,0.,1.)*step(rp*.56,r)*step(d1,-1.5/pxl)*.7)*big;
      sp=mix(sp,ct*.9,clamp(.5-(rv-.06)*pxl,0.,1.)*big);
      lv2=max(lv2,clamp(1.-abs(rv-.115)*pxl,0.,1.)*.7*big);
#if HD>=1
      // Native up: painted linework on the glass, and the petals, the bosses and the eye of the rose are cut as cabochons that take the realm's turning light
      {float e=orn(fc*3.2+h*9.,3.2/pxl,h*4.+sd);pt*=.8+.55*e;gd*=.75+.9*e;
       vec3 L3=normalize(vec3(cos(uM1[0].y),sin(uM1[0].y),.75));
       vec2 dv=fc-sign(fc)*.5;
       vec3 nP=normalize(vec3(fc/max(r,1e-3)*smoothstep(-.75*rp,0.,d1)*1.3,1.)),nB=normalize(vec3(dv/.19*1.2,1.)),nC=normalize(vec3(fc/.085*1.1,1.));
       float gP=pow(max(dot(reflect(-L3,nP),vec3(0.,0.,1.)),0.),18.),gB=pow(max(dot(reflect(-L3,nB),vec3(0.,0.,1.)),0.),26.),gC=pow(max(dot(reflect(-L3,nC),vec3(0.,0.,1.)),0.),20.);
       pt=pt*(.62+.6*max(dot(nP,L3),0.))+mix(pt,vec3(1.),.45)*gP*.55*(1.+1.2*uHat)*big;
       sp=sp*(.6+.65*max(dot(nB,L3),0.))+mix(sp,vec3(1.),.5)*gB*.7*(1.+1.2*uHat)*big;
       ct=ct*(.7+.5*max(dot(nC,L3),0.))+vec3(1.)*gC*.5*big;}
#endif
#if HD>=2
      // Cinema up: beads strung along the came, and a hairline halo of rays between the pearls and the rose
      {float bw=smoothstep(40.,70.,pxl),bq=fract((abs(fc.x)>abs(fc.y)?fc.y:fc.x)*12.)-.5;
       float ry=abs(fract(a*K*3./TAU)-.5)*TAU/(K*3.)*r,rz=smoothstep(.3,.33,r)*(1.-smoothstep(.36,.38,r))*step(0.,d1);
       lv2=max(lv2,clamp(1.-ry*pxl*1.3,0.,1.)*rz*bw*.75);gd*=1.+.7*rz*bw;
       gd=mix(gd,dlPg(t0+.55).brg*.7,clamp(.5-(length(vec2(bq/12.,d3-.035))-.017)*pxl,0.,1.)*bw*step(d3,.07));}
#endif
      vec3 c=mix(gd,sp,clamp(.5-d4*pxl,0.,1.));
      {float K2=K*2.,bx=(fract(a*K2/TAU)-.5)*TAU/K2*.4,bd=length(vec2(bx,r-.4))-.032;   // a ring of pearls round each rose
       c=mix(c,dlPg(t0+.7)*(.45+.55*smoothstep(0.,-.03,bd)),clamp(.5-bd*pxl,0.,1.)*smoothstep(22.,40.,pxl));}
      c=mix(c,pt,clamp(.5-d1*pxl,0.,1.));
      c=mix(c,ct*(1.+.8*jw),clamp(.5-d2*pxl,0.,1.));
      c*=1.+.7*jw*uHat;
      c=mix(cA*.3,c,fd);
      float l=max(max(clamp(1.1-abs(d1)*pxl,0.,1.),clamp(1.-abs(d2)*pxl,0.,1.)),max(clamp(1.-abs(d4)*pxl,0.,1.),clamp(.7-d5*pxl,0.,1.)*.6));
      l=max(max(l,lv2),clamp(1.2*rs+.5-d3*pxl,0.,1.));
      o+=w*c;ld=max(ld,w*l*fd);
    }
  }
  return o;
}
// mirror visits: n-fold mirror about the screen centre; the wedge turns (fract of uP1.w) to face the set's filaments
vec2 dlFold(vec2 v){float FN=floor(uP1.w);if(FN>1.5){float r=length(v),a=atan(v.y,v.x);float seg=TAU/FN;a=mod(a,seg);a=abs(a-seg*.5)+fract(uP1.w)*TAU;v=r*vec2(cos(a),sin(a));}return v;}
// cathedral: beyond the oculus (radius R0) the plane becomes a rose window. log(z) tiles it into rings of square
// cells (conformal, so every cell is a true square however far out), and each cell holds a medallion that is a
// copy of the whole set; rings counter-rotate, stagger and stream outward. z,dz: point and d/dv in the set's plane,
// replaced by the copy's; cx = (ring, cell along the ring, ring centre's distance from the oculus in rings)
float dlCell(inout vec2 z,inout vec2 dz,out vec2 cu,out vec3 cx){
  float R0=uM2[0].x,rz=length(z);cu=vec2(0.);cx=vec3(0.);
  if(rz<=R0)return 0.;
  float M=uM2[0].y,h=TAU/M,xr=log(rz/R0)/h-uM2[0].z,crg=floor(xr),par=mod(crg,2.);
  float ya=atan(z.y,z.x)/h-(par<.5?uM2[1].x:uM2[1].y)-uM2[1].z*crg;
  cx=vec3(crg,floor(ya),crg+.5+uM2[0].z);cu=vec2(fract(xr),fract(ya))-.5;
  vec2 e=vec2(cos(uM2[2].y),sin(uM2[2].y))*uM2[2].x;
  if(par>.5)e*=uM2[2].z;   // alternate rings hold close-ups of the set instead of the whole of it
  float mr=.45*smoothstep(-.4,.9,cx.z),g=.8+.2*min(dot(cu,cu)/(mr*mr+1e-4),1.);   // dome lens: the centre is magnified
  dz=g*cmul(e,cdiv(dz,z))/h;z=cmul(e,cu*g)+(par>.5&&uM2[2].z<.99?uP4.xy:vec2(0.));   // close-ups sit on the dive's cycle point
  if(dot(cu,cu)>.25)z=vec2(1e3);   // outside the medallion: the lead and tracery need no orbit
  return 1.;
}
// dl: deviation from the repelling cycle we are diving into; dz: dz/dv (both prepared per sample in realm())
vec3 dlShade(vec2 dl,vec2 dz,float px,out float win,out vec2 wl){
  float n=floor(uP1.x+.001),SD=uP1.y,PH=uP1.z;
  // v14: the dive's re-anchor is a self-similar coordinate change (Z -= lnL): the orbit moves by one
  // period, so every orbit-step-based pattern must count unwrapped steps. floor(uP3.w) = period + 16 *
  // re-anchors, so P*Wc added to an orbit step is invariant across the wrap (and unchanged elsewhere).
  float Pw=floor(uP3.w+.001),Wc=floor(Pw/16.);
  // v11: jewel bloom per band (smoothed in JS, packed in the fractions): bass, mids, highs each swell their own
  // generations of the nested critical jewels (generation = orbit step mod 3), so the gems breathe with the music
  vec3 JB=vec3(fract(uP3.w),fract(uP1.x),fract(uM1[2].x));
  vec2 c=uP2.xy;
  float rho=uM1[1].x;
  float D=uP3.z,P=max(mod(Pw,16.),1.);
  gSt=.5;gSt0=.5;gTr=1e9;gTrD=0.;gHit=0.;gHitI=0.;gW=vec2(0.);gWd=vec2(1.);
#if HD>=1
  vec2 dlS0=dl,dzS0=dz;
#endif
  float it=0.,m2=0.,esc=0.,dzs=0.,ld60=0.;vec2 d60=vec2(1.,0.);
  vec2 z=uP4.xy+dl,zp=vec2(0.);
  float Dd=min(D,64.),mx=Dd+160.+160.*clamp(uDetail,.5,16.);
  // one loop, two phases (a single inlined copy of the orbit accumulators keeps the D3D compile small):
  // deep phase (i<D): z = zr + dl with zr re-anchored on the stored cycle every step, so precision is relative to dl;
  // then the plain escape iteration
  for(int i=0;i<2784;i++){
    float fi=float(i);
    // an orbit whose derivative has collapsed by iteration 60 sits in an attracting basin and will never escape
    if(fi>=mx||(fi>Dd+60.5&&ld60<-12.))break;
    bool dp=fi<Dd;
    vec2 zr=vec2(0.),a=z;
    if(dp){float k=fi-P*floor((fi+.5)/P);zr=k<.5?uP4.xy:(k<1.5?uP4.zw:(k<2.5?uP5.xy:uP5.zw));a=zr+dl;}
    m2=dot(a,a);if(m2>1e4){z=a;esc=1.;break;}
    if(fi==Dd+60.){ld60=log(length(dz)+1e-30)+dzs*2.302585;d60=dz;}
    dlAcc(a,dz,SD,PH,rho,uM1[2].y,it);
    if(dp){
      vec2 S=vec2(1.,0.),bm=vec2(1.,0.),am=vec2(1.,0.);
      for(int m=1;m<8;m++){if(float(m)>=n)break;bm=cmul(bm,zr);am=cmul(am,a);S=cmul(a,S)+bm;}
      dz=n*cmul(am,dz);
      dl=cmul(dl,S);
      // leaving the deep phase: carry on from the cycle point reached
      if(fi+1.>=Dd){float k2=Dd-P*floor((Dd+.5)/P);z=(k2<.5?uP4.xy:(k2<1.5?uP4.zw:(k2<2.5?uP5.xy:uP5.zw)))+dl;}
    }else{
      vec2 zn1=z;
      for(int j=0;j<7;j++){if(float(j)>=n-2.)break;zn1=cmul(zn1,z);}
      dz=n*cmul(zn1,dz);
      float d2=dot(dz,dz);if(d2>1e16){dz*=1e-8;dzs+=8.;}else if(d2<1e-16){dz*=1e8;dzs-=8.;}   // keep |dz| in float range
      z=cmul(zn1,z)+c;
    }
    it+=1.;zp=a;
  }
  if(esc<.5&&gHitI>Dd+60.5)gHit=0.;
  float cntOff=uM1[0].x,la=uM1[0].y,bloom=uM1[0].z;
  vec3 L=normalize(vec3(cos(la),sin(la),.75));
  vec3 lw=vec3(.2126,.7152,.0722);
  vec3 col=vec3(0.);win=0.;wl=vec2(0.);
  float ldz=ld60,fwl=min(fwidth(ldz)*.35,1.);   // derivative taken in uniform control flow
  // escape-time footprint: where the smooth iteration count changes by more than a band per pixel the dust is
  // sub-pixel, so its per-band hue/stripe variation is replaced by its average instead of aliasing into speckle
  float snA=esc>.5?it-log(max(log(max(m2,1.0001))*.5/log(100.),1e-6))/log(n):it;
  float fsn=fwidth(snA),dAA=smoothstep(.7,3.,fsn);
#if HD>=1
  vec2 eZ=z/max(length(z),1e-20);float fZa=(abs(dFdx(eZ.x))+abs(dFdx(eZ.y))+abs(dFdy(eZ.x))+abs(dFdy(eZ.y)))/TAU;
#endif
  float q,snn;vec3 N=vec3(0.,0.,1.);
  // v20 leaded glass. The far field is a rose-window wall: the escape plane in log-polar coordinates (arg z, log|z|) is cut into panes, a whole number round the set
  // and a whole number of rows to each escape band, so the lattice follows the set's own geometry and only moves with the dive (the map is conformal: the footprint is
  // analytic). A basin is glazed in its own ring coordinates (arg dz, log|dz|): five rows of panes to each of its rings, riding with them. A gem far from the set holds
  // a rose of its own in the gem's log-polar coordinates. Whichever applies, the lattice is evaluated once.
  vec2 pG=vec2(0.);float pU=1.,pS=0.,pA=0.,pJ=0.,pLd=0.;vec3 pC=vec3(0.);
  if(esc>.5){
    float qE=exp(clamp(log(.25*sqrt(m2)*log(m2))-log(length(dz)+1e-30)-dzs*2.302585-log(px),-30.,30.));
    // The lattice is laid in log(z) of the step before escape, not of the escaped z: log|z| there runs over (4.6/n, 4.6], so the panes change size by n across a band
    // and never by more. In the escaped z's own coordinates a power-7 set crowded each band's outer part with sub-pixel panes and the wall broke into black moats.
    float Yq=log(max(length(zp),1e-6)),bh=4.6052*(1.-1./n),Ms=max(floor(TAU*3./bh+.5),2.),hh=TAU/Ms,Rw=3.;
    pG=vec2(atan(zp.y,zp.x)/hh+Ms*.5,(Yq-4.6052/n)/bh*Rw);pU=.25*log(max(m2,1.0001))/max(qE,1e-3)/(n*hh);
    pA=smoothstep(2.5,9.,qE)*(1.-dAA)*smoothstep(.1,.045,pU)*step(.5,it);pS=it+P*Wc+uSeed.x*7.;
    if(gHit>.5){
      float gjP=mod(gHitI+P*Wc,3.),gsP=.84+.16*dot(vec3(step(gjP,.5),step(abs(gjP-1.),.5),step(1.5,gjP)),JB);
      float fwP=max(px*length(gWd)/gsP,1e-8),rrP=max(length(gW)/gsP,1e-4),rpP=1./fwP;
      if(rrP<.9){
        if(rpP>12.){float hj=TAU/(2.*n+2.);pG=vec2(atan(gW.y,gW.x)/hj+n+1.,log(rrP)/hj);pU=fwP/rrP/hj;pS=floor(gHitI+P*Wc)+3.;
          pA=smoothstep(3.,16.,qE)*smoothstep(12.,24.,rpP)*smoothstep(.9,.7,rrP);pJ=1.;}
        else pA*=1.-smoothstep(7.,12.,rpP);
      }
    }
  }else{
    float lrP=ldz*.35-uMT*.2,hb=TAU/11.;
    pG=vec2(atan(d60.y,d60.x)/hb+5.5,lrP*5.);pU=fwl*3.85;
    pA=smoothstep(.017,.0065,fwl)*smoothstep(9.,5.,ld60);pS=floor(lrP)*1.37+5.+floor(uSeed.z*9.);
  }
  if(pA>.003)pC=dlPane(pG,pU,pS,pLd);
  if(esc>.5){
    snn=snA-cntOff;
    float fr=fract(snA);
    float lde=log(.25*sqrt(m2)*log(m2))-log(length(dz)+1e-30)-dzs*2.302585;
    q=exp(clamp(lde-log(px),-30.,30.));
#if HD>=1
    float qL=q*dlK();
#endif
    // Only the quotient direction is needed: z*conj(dz), without dividing by |dz|^2.
    // Scale both operands first so zero/overflowing derivative magnitudes cannot poison lighting.
    vec2 za=z/max(max(abs(z.x),abs(z.y)),1e-20);
    vec2 da=dz/max(max(abs(dz.x),abs(dz.y)),1e-20);
    vec2 grad=cmul(za,vec2(da.x,-da.y));
    vec2 u=grad/max(length(grad),1e-20);       // direction of steepest potential = away from the set
    float stp=mix(gSt0,gSt,fr);
    float lod=smoothstep(.7,3.,q)*(1.-dAA);
    stp=mix(.5,stp,lod);
    // snare: a ripple runs from the set outward across the field lines (a raised ring in the relief plus light)
    float snT=uM1[1].y,snP=27.-snT*58.;
    float rip=exp(-pow((snn-snP)/1.7,2.))*uM1[1].z*exp(-snT*2.2)*(1.-dAA);
    // emboss: the set is a ridge, the stripe ribbons are low welts on the slope
#if HD>=1
    float near=1./(1.+qL*.04);
#else
    float near=1./(1.+q*.04);                 // light lives next to the set; the far basin sinks to black
#endif
    // v12: zoomed out, the far field keeps a share of the light, so the field-line ribbons fill the frame round the set
    float nearO=max(near,.42*smoothstep(.95,.2,uZoom));   // v13: a little more far light, from earlier in the pull
    // v12: the vocal / lead range (presence onsets above the bass onsets, and the presence level when it runs high)
    // lights the field-line ribbons out across the dark basin
    float prs=max(max(uO2.x,uO2.y)-.4*(uO1.x+uO1.y),0.)+.9*max(uB2.x+uB2.y-.9,0.);
#if HD>=1
    float slope=1.5*exp(-qL*.07)+.5*(stp-.5)*near+1.1*rip;
#else
    float slope=1.5*exp(-q*.07)+.5*(stp-.5)*near+1.1*rip;
#endif
    N=normalize(vec3(u*slope,1.));
    float dif=max(dot(N,L),0.);
    float spc=pow(max(dot(reflect(-L,N),vec3(0.,0.,1.)),0.),40.);
    float rib=stp*stp*stp;
    vec3 alb=dlP(stp*.8+snn*.02+.1);
    alb=mix(alb,alb.brg,smoothstep(.62,.92,stp)*lod);   // stripe crests glint in a complementary hue
    col=alb*(.012+rib*(.065+1.45*nearO*(.85+.3*uB2.x+.9*prs)*(1.-.4*bloom)+.35*prs*(1.-near)))*(.35+.9*dif);   // field-line welts: presence (held back under the drop flash, which turned them into a soft halo)
    col+=mix(alb,vec3(1.),.4)*spc*near*(.5+1.5*rib)*(.8+uHat*1.4+.6*uB2.w);   // glints: hats and air
    float bandW=1./(q*log(n)+1e-3);
    // spectrum on the escape bands: outer rings are the bass, rings hugging the set the treble
    float bx=clamp((snn-1.)/26.,0.,1.);
    float sp=spec(bx);
    float bl=abs(fract(snn)-.5);
    float line=smoothstep(1.6*bandW,0.,.5-bl)*smoothstep(.3,.08,bandW);
    vec3 bc=dlP(bx*.7+.55);
    col+=bc*line*(.06+.8*sp*sp*uDose)*(.3+.7*(1.-near));
    col*=1.+line*line*line*(.34+1.0*sp*sp*uDose)*(.25+.75*(1.-near));   // v14: a multiplicative crisp core keeps the wide field linework without washing out its colour
    col+=bc*sp*sp*sp*.14*uDose*exp(-(.5-bl)/(bandW*5.+.004))*smoothstep(.3,.08,bandW);  // each ring glows with its slice of the spectrum
    // a kick launches a wave of light from the far rings into the set
    float kd=(snn-(2.+26.*(1.-uKick)))/(.1+2.*bandW);
    col+=bc.gbr*exp(-kd*kd)*uKick*uDose*.55*smoothstep(.4,.1,bandW);
    col+=bc.brg*rip*(.25+1.4*line)*smoothstep(.5,.1,bandW);
    // filaments hugging the dust
#if HD>=1
    float fil=exp(-qL*.6);
#else
    float fil=exp(-q*.6);
#endif
    // sub-pixel dust: hue and glow follow the escape time, so dense dust reads as a glittering nebula, not a sheet
    float gl=.55+.45*cos(snn*.8-uMT*1.5);
    gl=mix(gl*gl,.4,dAA);
    col+=dlP(.62+.1*sin(uMT*.3)+.3*sin(snn*.11)+.3*(gSt-.5)*(1.-dAA))*fil*(.25+.9*gl)*(.7+.6*uB2.z+.7*uO2.z);   // filaments: highs
    // v20 the glass wall goes in under the neon field lines; each band's slice of the spectrum lights its panes and the kick wave passes through them
    if(pJ<.5&&pA>.003){
      float fb=fract(snA),eb=min(fb,1.-fb)/max(fsn,1e-5),gld=max(pLd,clamp(1.8-eb,0.,1.));   // the band's own edge is a lead line
      col+=pC*(.5+.8*sp*sp*uDose+.9*exp(-kd*kd)*uKick*uDose+.35*rip)*(1.-.93*gld)*pA*.7*(1.-min(dot(col,lw)*1.5,1.));
    }
#if HD>=1
    {
      // v19 engraving on the field: guilloche lines that follow the external rays of the set, and finer contour lines between the escape bands.
      // Coloured ink: each line first bites the field darker, then adds a palette colour at limited coverage. Each level appears only once its lines
      // sit more than a few pixels apart, so higher tiers show finer engraving and nothing shimmers.
      float phi=atan(z.y,z.x)/TAU+.5;
      for(int j=min(int(uTime),0);j<2+HD;j++){
        float fj=float(j),M=pow(n,fj+2.),gd=abs(fract(phi*M+.5)-.5)/M,fw=max(fZa,1e-6);
        float cl=smoothstep(.22,.08,fw*M)*(1.-smoothstep(1.,1.8,gd/fw));
        cl*=smoothstep(2.5,12.,q)*(1.-dAA)*(.55+.45*stp);
        vec3 ink=dlP(.28+fj*.21+snn*.02);
        col*=1.-.38*cl;
        col+=ink*cl*(.05+.2*nearO)*(1.+.8*uB2.y);
      }
      float cM=2.;
      for(int j=min(int(uTime),0);j<1+HD/2;j++){
        float fsp=max(fsn*cM,1e-5),gc=abs(fract(snA*cM+.5)-.5),cn=smoothstep(.2,.07,fsp)*(1.-smoothstep(.9,1.7,gc/fsp));
        cn*=smoothstep(1.,6.,q)*(1.-dAA);
        col*=1.-.32*cn;
        col+=dlP(.55+.2*float(j)+snn*.03)*cn*(.04+.16*nearO);
        cM*=2.;
      }
    }
#endif
#if HD>=1
    {
      // v19: real relief shadow. The relief above is a height field (the set is a ridge, slope 1.5 exp(-.07 q)); a ray is marched toward the light across it,
      // each step re-iterating the orbit at that point. Light only falls away (never adds), so filaments stand up off the field with crisp cast shadows.
      float det=clamp(uDetail,.5,16.),H0=21.4*exp(-min(qL,300.)*.07),kP=px/dlK(),res=1.,tE=L.z/max(length(L.xy),1e-3);
      int ns=int(2.+2.6*det);
      vec2 Ld=normalize(L.xy);
      float tMax=max(H0/tE*1.15,3.);
      for(int j=min(int(uTime),0);j<28;j++){
        if(j>=ns)break;
        float f=(float(j)+.6)/float(ns),ts=1.2+(tMax-1.2)*pow(f,1.6);
        float qS=dlQ(dlS0+cmul(dzS0,Ld*ts*kP),dzS0,px,Dd+60.+30.*det);
        float hS=21.4*exp(-min(qS*dlK(),300.)*.07),over=hS-H0-ts*tE;
        res=min(res,1.-smoothstep(-.4,1.1+.1*ts,over));
        if(res<.02)break;
      }
      col*=mix(.45,1.,res);
    }
#endif
  }else{
    // never escaped: right on the set (or deep in an attracting basin)
    float bsn=smoothstep(9.,5.,ld60);vec3 colS=dlP(.62+.1*sin(uMT*.3)+.3*sin(it*.11))*(.3+.4*gSt);
    if(bsn>.001){
      // attracting basin: dz vanishes on every preimage of the critical point, so log|dz| and arg dz draw
      // a flower of nested rings and n-1 petals round each of those hearts; the basin becomes stained glass,
      // and each ring is a pane that looks back into the whole last frame (log-polar Droste nesting)
      float ld=ldz;
      float ad=atan(d60.y,d60.x);
      float fw=fwl;                             // fade the rings and petals once they crowd below a pixel
      float lr=ld*.35-uMT*.2;
      float rings=mix(fract(lr),.5,smoothstep(.15,.5,fw));
      float pet=mix(.5+.5*cos(ad*2.+ld*.6),.5,smoothstep(.2,.6,fw));
      float pane=floor(lr);
      vec3 b=dlP(.55+pet*.12+fract(pane*.37)*.3);
      b=b*b*1.4;
      float lead=smoothstep(.0,.06,rings)*smoothstep(1.,.94,rings);    // dark lead between the panes
      float glow=smoothstep(.0,.7,rings);                               // each pane brightens toward its inner edge
      col=b*(.02+.45*glow*glow*glow)*lead*(.5+.7*pet)+dlP(.75+pet*.2)*pow(pet,10.)*.35*lead*glow;
      if(pA>.003)col=mix(col,pC*(.8+.5*uB1.y+.9*uKick)*(1.-.93*pLd)*lead,pA*.92);   // a ring pane wider than about 80 px was a flat field: it is glazed, five rows of panes to the ring
      col+=dlP(.15+pane*.11)*(1.-lead)*1.1*(1.+uKick+.5*uB1.w);
      float rr=exp(-(1.-rings)*1.6);
      wl=rr*vec2(cos(ad),sin(ad));
      win=.3*lead*glow*(1.-smoothstep(.2,.6,fw))*(1.-.8*pA)*bsn;
      col=mix(colS,col,bsn);
    }else{
      // on the set itself (or a slow parabolic orbit): the same filament glow as the dust next to it, not a flat sheet
      col=colS;
    }
    q=0.;snn=it+P*Wc;   // v14: unwrapped so the re-anchor cannot shift on-set colour
  }
  // ring trap: pulled-back circles around every grain of dust
  float tpx=gTr/px,tsz=gTrD/px;
  col+=dlP(.15+gSt*.4).brg*smoothstep(1.6,.2,tpx)*smoothstep(1.5,5.,tsz)*(.2+.6*uB1.z+1.*uO1.z);   // ring traps: low mids
  // critical jewels: every pulled-back copy of the disc round 0 becomes a domed gem whose heart is a window
  // in glass visits the attracting basin is tiled the same way: every basin orbit falls into the disc at last, so its
  // panes become nested generations of jewels (large hearts, rings of smaller gems toward the filaments)
  if(gHit>.5){
    // critical jewels: every pulled-back copy of the disc round 0 is a cut gem (table, crown facets, girdle)
    // whose table is a window onto the whole last frame, so the mandala nests inside its own jewels forever
    // v11: each generation of gems (orbit step mod 3) blooms with its band: bass, mids, highs (smoothed in JS); at rest
    // the cut gem is a little smaller than its trap disc, so the bloom grows it into the disc and never past it
    float gj=mod(gHitI+P*Wc,3.);vec3 gsel=vec3(step(gj,.5),step(abs(gj-1.),.5),step(1.5,gj));
    float gsc=.84+.16*dot(gsel,JB);gW/=gsc;gWd/=gsc;
    float fw=max(px*length(gWd),1e-8);                 // pixel size in jewel units
    float rpx=1./fw;
    float rr=length(gW),ja=atan(gW.y,gW.x);
    float edge=smoothstep(1.,1.-2.*fw,rr);
    float vis=smoothstep(2.,7.,rpx);
    vec3 jn=normalize(vec3(gW*1.15,sqrt(max(1.-rr*rr,0.))+.08));
    // The escape-potential gradient already describes true Julia filaments.
    // Use that relief inside the large facets instead of leaving a smooth dome.
    float orbitRelief=(1.-smoothstep(.68,.92,rr))*(1.-smoothstep(.8,4.,q))*vis;
    jn=normalize(jn+vec3(N.xy*orbitRelief*.55,0.));
    float jd=max(dot(jn,L),0.),js=pow(max(dot(reflect(-L,jn),vec3(0.,0.,1.)),0.),70.);
    // v14: dispersive fire in the outer crown: the fresnel rim splits into a second, hue-shifted band
    float dsp=smoothstep(.3,.98,rr)*(.25+.75*abs(sin(ja*3.+rr*7.)));
    float fres=pow(1.-jn.z,2.);
    vec3 jc=dlP(.45+rr*.3+snn*.015)*(.06+.7*jd)*(1.-.6*smoothstep(.6,.2,rr))+dlP(.8+rr*.5).gbr*fres*1.2+vec3(1.)*js*(1.5+2.5*uHat)*(.35+.65*esc);
    jc+=dlP(.72+rr*.6+.1*sin(ja*3.))*(.10+.9*fres)*dsp*.75;   // v14: dispersive rim fire
    // The large jewel faces are engraved rather than empty smooth domes. The same
    // inversion-fold ornament resolves into finer self-similar inlays as pixels permit.
    float jewelDetail=orn(gW*3.6+vec2(.17,.31),fw*3.6,.13*snn+uSeed.y);
    float annulus=smoothstep(.16,.3,rr)*(1.-smoothstep(.78,.95,rr));
    float facetCuts=1.-smoothstep(.025,.025+max(fw*2.,.002),abs(sin(ja*(2.*n+2.)+rr*5.)));
    // v14: a second, finer crown generation: an inner inlay bezel and a star burst inside the table, so a
    // large gem reads as a cut stone with several tiers instead of one smooth bevel
    float inlay2=smoothstep(2.2*fw+.012,0.,abs(rr-.62));
    float star2=pow(.5+.5*cos(ja*(4.*n+4.)+rr*11.),8.);
    vec3 engraving=dlP(.14+snn*.013+rr*.27);
    jc+=engraving*jewelDetail*annulus*(.18+.65*spec(clamp(rr,0.,1.))*uDose+.25*uHit+.3*uB1.w);   // medallion engraving: mids
    jc+=engraving*facetCuts*annulus*(.03+.45*uHat+.35*uO2.w);   // hats and air make the facets sparkle
    jc*=1.+inlay2*annulus*(.10+.26*uB2.z+.20*uO2.w);             // v14: inner bezel inlay (multiplicative: keeps the gem colour)
    jc*=1.+star2*annulus*(.06+.35*uHat);                         // v14: star burst in the crown
#if HD>=1
    {
      // v19: the large gems get a real brilliant cut: table, star and bezel facets, each with its own plane normal, shading and palette colour, with fine dark lead
      // on the facet edges. Replaces the smooth dome by a mix (never an add), so it keeps the gem's colour. Higher tiers split the crown facets further.
      float cutV=smoothstep(10.,34.,rpx),ring=smoothstep(.1,.16,rr)*(1.-smoothstep(.9,.97,rr));
      if(cutV*ring>.002){
        float fmA=2.*n+2.;
#if HD>=2
        fmA*=2.;
#endif
        float zone=rr<.5?0.:(rr<.74?1.:2.),fm=fmA*(zone<.5?.5:1.);
        float cc=ja/TAU*fm+.25*zone,ci=floor(cc),cf=fract(cc)-.5,angC=(ci+.5-.25*zone)/fm*TAU;
        float tilt=zone<.5?.2:(zone<1.5?.6:1.05),seedF=fract(ci*.618+zone*.37);
        vec3 fN=normalize(vec3(cos(angC)*tilt,sin(angC)*tilt,1.));
        float fD=max(dot(fN,L),0.),fS=pow(max(dot(reflect(-L,fN),vec3(0.,0.,1.)),0.),24.);
        vec3 fC=dlP(.1+.13*zone+.5*seedF+snn*.013)*(.12+1.05*fD)+dlP(.72+.2*zone).gbr*fS*(.5+1.5*uHat+.8*uO2.w);
        float eS=(.5-abs(cf))*TAU/fm*rr,eZ2=min(abs(rr-.5),abs(rr-.74)),eM=min(eS,eZ2),eW=max(fw*1.6,.004),eL=1.-smoothstep(eW*.4,eW*1.4,eM);
        jc=mix(jc,fC,.72*ring*cutV);
        jc*=1.-.75*eL*ring*cutV;
#if HD>=3
        // a fine star inside the table, drawn with the same dark lead
        float tA=abs(fract(ja/TAU*fm*2.)-.5)*TAU/(fm*2.)*rr,tL=(1.-smoothstep(eW*.4,eW*1.3,tA))*smoothstep(.12,.18,rr)*(1.-smoothstep(.42,.5,rr))*smoothstep(.0035,.0018,fw);
        jc*=1.-.55*tL*cutV;
#endif
      }
    }
#endif
    // Preserve the resolved Julia orbit in the jewel table rather than replacing
    // it wholesale with smooth glass. The outer bevel still supplies its form.
    if(pJ>.5)col=mix(col,pC*(.75+.5*dot(gsel,JB)+.8*dot(gsel,vec3(max(uO1.x,uO1.y),max(uO1.z,uO1.w),max(uO2.y,uO2.z))))*(1.-.93*pLd),pA*.6);
    float tableCoverage=smoothstep(.86,.55,rr)*vis;
    jc=mix(jc,jc*.32+col*.95,tableCoverage*.65);
    float girdle=smoothstep(2.5*fw+.012,0.,abs(rr-.93));
    jc+=dlP(.15+snn*.02)*girdle*(.4+1.8*uKick+.6*uO1.w);
    // each generation of gems flares on its own band's onsets (bass / mids / highs, as their size breathes in JS)
    float ob=dot(gsel,vec3(max(uO1.x,uO1.y),max(uO1.z,uO1.w),max(uO2.y,uO2.z))),lb=dot(gsel,vec3(uB1.y,uB1.w,uB2.z));
    jc*=1.+.8*ob+.25*lb;jc+=mix(engraving,vec3(1.),.3)*girdle*1.2*ob;
    // The table shows genuine Julia potential/filaments; only its outer bevel
    // strongly replaces the field with glass. Native detail must remain visible.
    float materialCoverage=.12+.68*smoothstep(.43,.86,rr);
    col=mix(col,jc*(1.+.4*bloom),edge*vis*materialCoverage*(.55+.45*esc));
    if(esc<.5)col=dlS(col);   // basin jewels tile whole basins: their glass stays in full colour
    win=smoothstep(.8,.7,rr)*vis*smoothstep(8.,24.,rpx)*.28;
    wl=gW/.75;
    // hats: satellites too small to cut (1-7 px) twinkle; each hat lights a different generation of them
    float tw=step(.62,h11((gHitI+P*Wc)*7.13+floor(uM1[2].x)*1.618));
    col+=mix(engraving,vec3(1.),.4)*smoothstep(.7,1.6,rpx)*(1.-vis)*(1.-rr*rr)*(.15+tw*uHat*2.6*uDose);
  }
  // the engine already flashes the drop; the realm eases off for that instant so the hit stays in colour, not white
  return col*(1.+uKick*.2*uDose)*(1.-.3*bloom*bloom);
}
// the cathedral's glass and tracery, drawn once per pixel over the averaged orbit samples
vec3 dlCathedral(vec3 col,float cat,vec2 cu,vec3 cx,float cpu,float oc){
  float par=mod(cx.x,2.),sd=step(0.,cu.x),bn=cx.x+sd,pb=mod(bn,2.);
  vec3 rc=dlS(max(gPa+gPb*cos(TAU*(gPc*(.12+.33*par+.05*cx.x)+gPd+uHue)),0.))*1.2;rc=par>.5?rc.gbr:rc;
  // medallions open like irises as their ring leaves the oculus; each is a glass dome, darker toward its rim (deep
  // black between the copy's filaments); mids light the rims, a kick flashes the ring its wave has reached. Between
  // them: leading on the cell edges and a jewel where the cells meet (hats make them glint)
  vec2 ac=abs(cu);
  float r=length(cu),em=smoothstep(-.4,.9,cx.z),mr=.45*em,rd=abs(r-mr-.012);
  // corner jewels sit on a ring boundary: both halves take the outer ring's cell lattice and the boundary's own
  // colour and size, so each jewel is one whole gem
  vec2 jq=vec2(cu.x+.5-sd,fract(cu.y+.5+sd*((par<.5?uM2[1].x-uM2[1].y:uM2[1].y-uM2[1].x)-uM2[1].z))-.5);
  float cj=length(jq),jr=.08*smoothstep(-.4,.9,bn+.5+uM2[0].z);
  vec3 jc=dlS(max(gPa+gPb*cos(TAU*(gPc*(.12+.33*pb+.05*bn)+gPd+uHue)),0.))*1.2;jc=pb>.5?jc.brg:jc.gbr;
  float kw=cx.z-1.-5.*(1.-min(uKick,1.)),jin=smoothstep(jr+cpu,jr-cpu,cj);
  vec3 add=(rc+.2)*smoothstep(.008+cpu,.008-cpu*.5,rd)*em*(.25+.7*uB1.w+uO1.w+1.4*exp(-kw*kw)*uKick)
          +jc*jin*(.15+.85*smoothstep(jr,0.,cj))*(.5+.6*uB2.y+1.5*uHat)
          +mix(jc,vec3(1.),.3)*jin*smoothstep(.45*jr+cpu,0.,length(jq+jr*vec2(.38,-.3)))*(.6+1.5*uHat)
          +rc*smoothstep(cpu*1.5,0.,.5-max(ac.x,ac.y))*.3*em;
  // glass depth: the dome catches the rose's light on its oculus side (a broad sheen and a fine crescent) and its
  // far rim falls into shadow
  vec2 hp=cu+mr*vec2(.42,-.22);
  float ins=smoothstep(mr+cpu,mr-cpu,r),cres=smoothstep(cpu*2.+.006,0.,abs(r-.88*mr))*smoothstep(.1,-.6,cu.x/(r+1e-4));
  vec3 gl=rc*(exp(-dot(hp,hp)/(.05*mr*mr+1e-5))*.22+cres*.55)*em*ins;
  // v14: the large medallion glass was the flattest area in the wide and folded views. Add nested analytic
  // tracery (radial flutes, concentric inlay rings, a bead filigree) anti-aliased against the cell-space
  // footprint cpu, so it fades to its average when sub-pixel and costs no extra loop.
  float ca=atan(cu.y,cu.x),cr=length(cu);
  float fl=pow(.5+.5*cos(ca*uM2[0].y*1.5-cx.x*2.1+uMT*.04),6.);
  float ri=pow(.5+.5*cos(cr*24./max(mr,.05)-cx.x*1.3),4.);
  vec2 bp=vec2(ca*uM2[0].y*2.5,cr*18./max(mr,.02)),bf=fract(bp)-.5;
  float bd=smoothstep(.11,.045,dot(bf,bf))*step(.62,h21(floor(bp)+cx.xx));
  float aa=smoothstep(.007,.0018,cpu),rim=smoothstep(mr*.35,mr*.9,r);
  // v14: the tracery is applied multiplicatively (a brightness/hue modulation of the glass), so it adds
  // visible inlay without washing the saturation out of a large dome; only the crests add a little colour.
  float tra=(.55*fl+.5*ri+.45*bd)*aa*ins*rim;
  add+=rc*tra*.30;
  col=mix(col,(col*ins*(.7+.3*em)*(.45+.55*smoothstep(mr,.4*mr,length(cu+mr*vec2(.18,0.))))+gl+add)*(1.+1.35*tra),cat);
  // the oculus: a fine double ring where the central rose meets the cathedral (the bass breathes in it)
  return col+rc*(smoothstep(1.4,.3,oc)+.5*smoothstep(1.2,.2,abs(oc-4.)))*(.35+.9*uB1.x+.8*uO1.x)*step(uM2[0].x,9e3);
}
void realm(){
  gPa=mix(uPa,uQa,uPalT);gPb=mix(uPb,uQb,uPalT);gPc=mix(uPc,uQc,uPalT);gPd=uPd+(fract(uQd-uPd+.5)-.5)*uPalT;   // phases take the short way round
  vec2 v=dlFold(scr()/uZoom);
  float px=1./(uRes.y*uZoom);
  // the pixel's point in the set's plane; in the cathedral it is replaced by the medallion copy's point, found once
  // per pixel (sub-samples step along the copy's own derivative). The deep phase is an exact identity for any
  // deviation, so a copy simply rides it as dl = z - cycle point.
  vec2 dl0=cmul(uP2.zw,v)+uP3.xy,z=uP4.xy+dl0,dz=uP2.zw,cu;vec3 cx;
  float oc=abs(length(z)-uM2[0].x)/(length(dz)*px);
  float cat=dlCell(z,dz,cu,cx),cpu=px*length(dz)/(uM2[2].x*(mod(cx.x,2.)>.5?uM2[2].z:1.));
  if(cat>.5)dl0=z-uP4.xy;
  // Structural quality extends the escape orbit to 2720 iterations. Sub-pixel dust is filtered against the pixel
  // footprint inside dlShade; supersampling comes from the engine's Cinema..Offline resolutions (a per-pixel probe
  // loop here doubled the D3D compile time, which the cathedral needed instead).
#if HD>=1
#if HD>=5
#define DL_NS 4
#elif HD>=3
#define DL_NS 3
#else
#define DL_NS 2
#endif
  float win=0.;vec2 wl=vec2(0.);vec3 col=vec3(0.);
  for(int s=0;s<DL_NS;s++){
#if DL_NS==2
    vec2 so=s==0?vec2(.25,.25):vec2(-.25,-.25);
#elif DL_NS==3
    vec2 so=s==0?vec2(-.3,-.12):(s==1?vec2(.08,.32):vec2(.24,-.22));
#else
    vec2 so=s==0?vec2(.125,.375):(s==1?vec2(-.375,.125):(s==2?vec2(.375,-.125):vec2(-.125,-.375)));
#endif
    float w1;vec2 l1;
    col+=dlShade(dl0+cmul(dz,so*px),dz,px,w1,l1);win+=w1;wl+=l1;
  }
  col/=float(DL_NS);win/=float(DL_NS);wl/=float(DL_NS);
#else
  float win;vec2 wl;
  vec3 col=dlShade(dl0,dz,px,win,wl);
#endif
  col=dlCathedral(col,cat,cu,cx,cpu,oc);
#if HD>=1
  {float cL=dot(col,vec3(.2126,.7152,.0722));col=max(cL+(col-cL)*(1.+.02*float(HD)),0.);}
#endif
  // the engine's instant hue jump on a drop arrives here as a hue sweep over ~half a second instead of a cut
  if(abs(uM1[2].z)>.002)col=dlRot(col,uM1[2].z*TAU);
  fragWin=vec4(wl*.5+.5,0.,1.);
  fragColor=vec4(col,win);
}
`;
