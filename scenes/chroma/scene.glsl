const R_CHROMA = `
/* CHROMA v20 (v21: the great plumes are part of the lattice): the realm where colour itself is the subject. One continuous PLUMAGE covers the frame: rows of overlapping plumes, each with a
   combed vane and an enamel eye of three zones that step round the palette. The plume lattice is carried through a conformal map with no critical
   point (the logarithm of a Mobius map, or a Mobius map), so rows pour out of whorls and round each other and a plume is never distorted, only resized;
   wherever the map has stretched the lattice fourfold, the next finer lattice grows over it, so plumes stay a legible size at every zoom. The field colour
   is a curated ramp read along the map, so the big picture is bands and pinwheels of pure colour and the small picture is craft.
   Audio: kicks send swell waves through the plumes and step every colour, each kick also pours the rows one step; sub swells the light and opens the gaps;
   snares flash the eyes of alternate plumes; mids roll the colour and the raking light (the eye zones are iridescent to it); highs fire the cores and glints;
   every row of plumes is a band of the spectrum and its eyes breathe with it. */
// palettes: six ramp stops, the cloison metal, the gem (linear)
const vec3 CHQ[112]=vec3[112](
  vec3(0.0232,0.0908,1.0000),vec3(0.0802,0.0296,1.0000),vec3(0.2542,0.0091,1.0000),vec3(1.0000,0.0052,0.4342),vec3(1.0000,0.0176,0.0648),vec3(1.0000,0.4342,0.0000),vec3(1.0000,0.6514,0.1441),vec3(1.0000,0.8148,0.3916),
  vec3(0.0000,0.3916,0.5776),vec3(0.0000,0.5776,0.2789),vec3(0.0000,0.4342,0.0802),vec3(0.0284,0.2051,1.0000),vec3(0.1946,0.0648,1.0000),vec3(0.0000,0.3140,1.0000),vec3(1.0000,0.6240,0.1070),vec3(1.0000,0.1022,0.0144),
  vec3(1.0000,0.0343,0.0052),vec3(1.0000,0.1441,0.0000),vec3(1.0000,0.4072,0.0000),vec3(1.0000,0.0284,0.1946),vec3(0.7454,0.0000,0.2747),vec3(0.2542,0.0144,0.8070),vec3(1.0000,0.7454,0.2542),vec3(0.0091,0.8714,1.0000),
  vec3(1.0000,0.0232,0.1946),vec3(0.7454,0.0103,0.3515),vec3(0.4342,0.0144,0.7454),vec3(0.0000,0.5906,0.3515),vec3(0.0000,0.3916,0.1441),vec3(0.0000,0.4342,0.6308),vec3(1.0000,0.8714,0.4342),vec3(1.0000,0.6308,0.0000),
  vec3(0.7454,0.0052,0.0296),vec3(1.0000,0.0685,0.0052),vec3(1.0000,0.3515,0.0000),vec3(0.0000,0.3515,0.2789),vec3(0.0052,0.2462,0.9387),vec3(0.0685,0.1070,1.0000),vec3(0.9131,0.5395,0.0802),vec3(1.0000,0.8714,0.5271),
  vec3(0.1441,0.0052,0.6308),vec3(0.3515,0.0052,0.5271),vec3(0.7454,0.0052,0.2542),vec3(1.0000,0.4342,0.0000),vec3(1.0000,0.1946,0.0000),vec3(1.0000,0.6867,0.0513),vec3(1.0000,0.7454,0.3515),vec3(0.0296,1.0000,0.7454),
  vec3(0.6724,0.0103,1.0000),vec3(1.0000,0.0103,0.5271),vec3(1.0000,0.0103,0.1441),vec3(1.0000,0.1022,0.0423),vec3(1.0000,0.3515,0.0296),vec3(0.3231,0.0091,1.0000),vec3(1.0000,0.6867,0.2789),vec3(0.0296,1.0000,0.6308),
  vec3(0.0000,0.6308,0.7454),vec3(0.0000,0.3916,0.8714),vec3(0.0284,0.2051,1.0000),vec3(0.1946,0.0648,1.0000),vec3(0.0000,0.6867,0.3231),vec3(0.0395,0.8070,0.5271),vec3(1.0000,0.7454,0.2789),vec3(1.0000,0.0423,0.1441),
  vec3(0.5776,0.8714,0.0000),vec3(0.1170,0.7454,0.0144),vec3(0.0000,0.6308,0.1620),vec3(0.1946,0.0212,1.0000),vec3(0.4342,0.0091,0.7454),vec3(0.1022,0.0513,1.0000),vec3(1.0000,0.8714,0.5271),vec3(1.0000,0.0232,0.2542),
  vec3(0.3916,0.8714,0.0000),vec3(0.0513,0.7454,0.0296),vec3(0.0000,0.5776,0.2159),vec3(0.0000,0.4342,0.5271),vec3(1.0000,0.6867,0.0000),vec3(0.8070,0.3916,0.0000),vec3(1.0000,0.8714,0.5271),vec3(1.0000,0.0232,0.2542),
  vec3(0.0232,0.2159,1.0000),vec3(0.0000,0.3916,0.8714),vec3(0.0000,0.6308,0.6308),vec3(1.0000,0.1946,0.0052),vec3(1.0000,0.0685,0.0144),vec3(1.0000,0.4342,0.0144),vec3(1.0000,0.7454,0.3515),vec3(1.0000,0.0232,0.1620),
  vec3(1.0000,0.0232,0.1620),vec3(1.0000,0.1022,0.2542),vec3(1.0000,0.2542,0.1022),vec3(0.0000,0.4793,0.4342),vec3(0.0000,0.2789,0.5271),vec3(0.0144,0.6867,0.3515),vec3(1.0000,0.8070,0.5271),vec3(1.0000,0.8714,0.0000),
  vec3(1.0000,0.5776,0.0000),vec3(1.0000,0.0423,0.0513),vec3(1.0000,0.3231,0.0000),vec3(1.0000,0.0232,0.2159),vec3(1.0000,0.7454,0.0513),vec3(1.0000,0.1441,0.0052),vec3(1.0000,0.8714,0.5271),vec3(0.0091,0.6308,1.0000),
  vec3(0.1441,0.0212,0.8714),vec3(0.2542,0.0091,1.0000),vec3(0.5271,0.0091,1.0000),vec3(1.0000,0.0091,0.5776),vec3(1.0000,0.0423,0.2542),vec3(0.0578,0.0802,1.0000),vec3(0.2542,0.8070,1.0000),vec3(1.0000,0.8714,0.0000));
#define CH0 min(int(uTime),0)
#define CH_BIG .85
#define CH_BIGT 1.
#if HD>=3
#define CH_SL 3
#else
#define CH_SL 2
#endif
#if HD>=5
#define CH_NL 6
#define CH_RL 4
#define CH_SR 26
#elif HD>=4
#define CH_NL 6
#define CH_RL 4
#define CH_SR 12
#elif HD>=3
#define CH_NL 5
#define CH_RL 4
#define CH_SR 8
#elif HD>=2
#define CH_NL 5
#define CH_RL 3
#define CH_SR 5
#elif HD>=1
#define CH_NL 4
#define CH_RL 3
#define CH_SR 3
#else
#define CH_NL 3
#define CH_RL 2
#define CH_SR 0
#endif
vec2 chMul(vec2 a,vec2 b){return vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x);}
vec2 chDiv(vec2 a,vec2 b){return vec2(a.x*b.x+a.y*b.y,a.y*b.x-a.x*b.y)/max(dot(b,b),1e-9);}
vec3 chHR(vec3 c,float a){const vec3 k=vec3(.57735);float cs=cos(a);return max(c*cs+cross(k,c)*sin(a)+k*dot(k,c)*(1.-cs),0.);}
// the colour ramp: eased between stops. Curated stops sit next to each other in hue so the mix keeps its chroma
vec3 chRamp(int p,float t){
  t=mod(t,6.);float f=fract(t);int i=int(t);f=f*f*(3.-2.*f);
  vec3 a=CHQ[p*8+i],b=CHQ[p*8+(i+1)%6],m=mix(a,b,f);
  float la=dot(a,vec3(.3333)),lb=dot(b,vec3(.3333)),lm=dot(m,vec3(.3333)),ca=length(a-la),cb=length(b-lb),cm=length(m-lm);
  return max(lm+(m-lm)*min(mix(ca,cb,f)/max(cm,1e-3),2.5),0.);
}
// the maker's seal: ten marks, five by seven (two ints a mark: rows 0 to 3, then 4 to 6)
float chSeal(vec2 p){
  if(p.x<0.||p.x>=60.||p.y<0.||p.y>=7.)return 0.;
  const ivec2 G[8]=ivec2[8](ivec2(508430,1086),ivec2(1020036,4228),ivec2(476721,17966),ivec2(583347,17969),
                            ivec2(1032734,16927),ivec2(1001009,17982),ivec2(476735,17969),ivec2(1001022,16912));
  const int Wm[10]=int[10](0,1,2,3,4,5,-1,6,7,4);
  int ci=int(p.x/6.),cx=int(p.x)-ci*6,gi=Wm[ci];
  if(gi<0||cx>4)return 0.;
  int r=6-int(p.y),bits=r<4?(G[gi].x>>((3-r)*5))&31:(G[gi].y>>((6-r)*5))&31;
  return float((bits>>(4-cx))&1);
}
// plume outlines in lattice units, tip toward +x: x = signed distance, y = nesting coordinate (0 centre .. 1 edge)
vec2 chTile(vec2 q,int k){
  float r=length(q);
  if(k==0)return vec2(r-.52,r/.52);                                                                 // round scale
  if(k==1){vec2 a=vec2(q.x,abs(q.y)+.2);float dd=length(a)-.76;return vec2(dd,1.+dd/.56);}          // ogee
  if(k==2){vec2 a=vec2(abs(q.y),q.x+.16);float kk=dot(a,vec2(-.6098,.7926));                         // drop: round at the root, drawn out to a point
    float dd=kk<0.?length(a)-.5:(kk>.65?length(a-vec2(0.,.82)):dot(a,vec2(.7926,.6098))-.5);return vec2(dd,1.+dd/.5);}
  if(k==3){float dd=r-.47-.05*abs(cos(atan(q.y,q.x)*2.5));return vec2(dd,1.+dd/.5);}                 // shell: a fan with a scalloped edge
  if(k==4){vec2 a=vec2(q.x-.08,abs(q.y)+.3);float dd=length(a)-.84;return vec2(dd,1.+dd/.53);}     // feather
  {vec2 a=vec2(abs(q.x)+.16,abs(q.y)+.42);float dd=length(a)-.92;return vec2(dd,1.+dd/.5);}        // lancet
}
vec2 chLog(vec2 d){return vec2(.5*log(max(dot(d,d),1e-12)),atan(d.y,d.x));}
// the conformal maps. Every one is the logarithm of a Mobius map (of z, or of exp(iz)), so its derivative is never zero and it has no pole:
// there is no saddle anywhere, a plume is a plume everywhere. Residues are lattice vectors, so there is no seam.
vec2 chFar(float al){return (1.08+.3*fract(al*5.3))*vec2(cos(al),sin(al));}
vec2 chMap(vec2 z,int lay,float al,float N,vec2 cR,out vec2 fp,out float flp){
  flp=1.;
  vec2 L=vec2(0.),dL=vec2(1.,0.);const vec2 one=vec2(1.,0.);
  if(lay==0){vec2 d=z-.3*vec2(cos(al),.6*sin(al));L=chLog(d);dL=chDiv(one,d);}                                   // one whorl
  else if(lay==1){float a=.8+.3*fract(al*3.7);vec2 d1=z-vec2(a,0.),d2=z+vec2(a,0.);L=chLog(d1)-chLog(d2);dL=chDiv(one,d1)-chDiv(one,d2);}   // source and sink
  else if(lay==2){float k=min(.8+.2*fract(al*3.7),1.2*max(uZoom,.05));vec2 zz=z*k;float y0=zz.y;zz.y=2.3-abs(mod(zz.y+2.3,9.2)-4.6);flp=abs(zz.y-y0)>1e-3?-1.:1.;float ch=cosh(zz.y),sh=sinh(zz.y);        // a chain of alternating whorls (mirrored far from its axis)
    vec2 s=vec2(sin(zz.x)*ch,cos(zz.x)*sh),c=vec2(cos(zz.x)*ch,-sin(zz.x)*sh);L=chLog(s)-chLog(c);dL=k*(chDiv(c,s)+chDiv(s,c));}
  else{vec2 d=z-chFar(al);L=chLog(d);dL=chDiv(one,d);}                                                            // a great fan: the whorl stands outside the frame
  fp=N*chMul(cR,dL);
  return N*chMul(cR,L);
}
// distance to the nearest pole of the layout: kick and snare waves leave the poles
float chPole(vec2 z,int lay,float al){
  if(lay==1){float a=.8+.3*fract(al*3.7);return min(length(z-vec2(a,0.)),length(z+vec2(a,0.)));}
  if(lay==2){float k=min(.8+.2*fract(al*3.7),1.2*max(uZoom,.05));vec2 zz=z*k;zz.y=2.3-abs(mod(zz.y+2.3,9.2)-4.6);return length(vec2(abs(mod(zz.x+.7854,1.5708)-.7854),zz.y))/k;}
  if(lay==3)return .55*max(length(z-chFar(al))-.25,0.);
  return length(z-.3*vec2(cos(al),.6*sin(al)));
}
// one formation: decode, map, pick the lattice level from the map's local scale, draw that level, the next one growing over it, the levels embossed in it,
// v21: the great plumes are plumes of the same lattice (see the row loop); nothing is laid over the plumage any more. Returns colour.
vec3 chWall(vec2 p,vec4 M,vec3 under,float wipe){
  int c0=int(M.x+.5);
  int lay=c0&7,tile=(c0>>3)&7,orn=(c0>>6)&3,rim=(c0>>8)&3,gemM=(c0>>10)&3,pal=(c0>>12)&15,spiral=((c0>>16)&3)-1,bandK=1+((c0>>18)&3),armI=(c0>>20)&3,nw=(c0>>22)&1;
  int m1=int(M.y/16.),palB=m1&15,tileH=(m1>>4)&7;
  float zm=max(uZoom,.05),H=.433,dens=M.y-16.*float(m1);
  float ang=M.z,al=M.w,N=(nw==1&&lay!=2)?128.:64.;if(lay==2)dens*=.88;
  // kick punch on the camera: a quick scale pump, never a sway
  float kq=uP3.x;
  vec2 z=rot(ang)*p/zm/(1.+.018*kq+.22*uP3.w);
  vec2 Lr=vec2(float(spiral)*2.*H,1.),cR=vec2(Lr.y,-Lr.x)/TAU;
  vec2 fp;float flp;vec2 w=chMap(z,lay,al,N,cR,fp,flp);
  float px=1./(uRes.y*zm),fpl=max(length(fp),1e-6),pxw=px*fpl;
  // level: the lattice is redrawn four times finer or coarser wherever the map has stretched it, so plumes stay a legible size everywhere
  float u=log2(dens*pow(zm,.85)/fpl)*.5+.5;
  float nf=clamp(floor(u),-2.,5.),f=clamp(u-nf,0.,1.),mulA=exp2(2.*nf);
  w.x-=uP2.x*H;
  w=vec2(mod(w.x,128.*H),mod(w.y,N));
  float bf=3.*float(bandK<3?1:2)/N,af=6.*float(armI<2?1:0)/N;
  // ground under the plumes (seen when bass opens the gaps and when a new formation grows in)
  vec3 gc=chRamp(pal,uP2.y+float(bandK)*.5+3.)*.85;
  {float lm=dot(gc,vec3(.2126,.7152,.0722));gc*=mix(1.,.24/max(lm,1e-3),step(lm,.24)*.8);}
  vec3 col=under.x>=0.?under:gc;
  float bodyM=0.,mul=mulA;
  float bu=uP3.y;
  float sa=uP3.z;vec3 Lg=normalize(vec3(cos(sa),sin(sa),.9));
  float hh=max(max(uO2.z,uO2.w),uHat),hiA=clamp(uM2[2][2],0.,1.);
  int pcB=pal;
#if HD>=3
  float psi0=chPole(z,lay,al)*zm*1.5;
#endif
#if HD>=1
  float rowT=-1e6,tT=0.,frT=0.,mulM=mulA,pxM=pxw*mulA,glT=0.;vec3 NT=vec3(0.,0.,1.);
#endif
  int nL=min(3+int(log2(max(uDetail,1.))+.01),CH_NL);
  bool dead=false;
  for(int L=CH0;L<nL;L++){
    float pxl=pxw*mul,lvI=nf+float(L);
    if(L>0&&(pxl>.5||mul>5000.))dead=true;if(dead)continue;
    float fadeE=smoothstep(.1,.035,pxl)*(L==CH_RL?1.-smoothstep(.7,1.,f):1.);
    if(L>0&&L==nL-1)fadeE*=smoothstep(0.,.3,f);
    float cover=smoothstep(.6,.9,f),fadeN=smoothstep(.16,.06,pxl)*smoothstep(0.,.3,f);
    vec2 wl=w*mul;
    float row0=floor(wl.x/H+.5);
    vec3 acc=col;float accB=bodyM,accT=0.;
    // v21 the great plumes. Hierarchy of size is grown inside the lattice itself: the plumes that stand on the sites of the next coarser lattice (one site in
    // sixteen, a staggered array through the rows) are great plumes. They have the outline, rows, shading and ink of their neighbours and are painted in row
    // order with them, so the rows behind lie under them and the rows in front lie over them; only their size differs (up to 1.85 times while the plumes of this
    // level are still small, easing back to their neighbours' size as the level grows large, and the next level's great plumes grow as it takes over: the
    // frame never falls to one size of plume, and nothing floats over the flow).
    bool emb=L>=CH_RL;
    float gS=emb?0.:(L==0?1.-smoothstep(.3,.75,f):(L==1?smoothstep(.62,.97,f):0.))*smoothstep(6.,14.,N*mul)*CH_BIG;
#if HD>=3
    // how large a plume near this pixel can be at this moment (a bound, used only to skip plumes that cannot reach the pixel): a kick wave swells plumes only in
    // the band it is passing, a snare only for half a second
    float dps=3.8*zm*px/max(pxl,1e-6);
    vec4 wq=uP1-psi0*1.4;float fmB=any(lessThan(abs(wq-.16),vec4(.17+1.4*dps)))?1.:0.;
    vec2 xq=uP4.xy-psi0*.1;float snB=max(step(-.1*dps,xq.x)*exp(-5.5*max(xq.x-.1*dps-.03,0.)),step(-.1*dps,xq.y)*exp(-5.5*max(xq.y-.1*dps-.03,0.)));
    float sBd=(1.+.42*fmB+.3*snB)*(.92+.2*bu)*1.02;
    // From Insane up every plume is walked from every row it can cover at its largest (as many as eight rows under a kick wave), and both neighbours of a row
    // are walked: two plumes of one row that swell overlap like petals (the ones the snare pops lie on top) instead of meeting along a straight line.
    float kTip=emb?2.:ceil(1.2*sBd/H-.5),kTail=(emb||sBd<1.25)?1.:2.;bool farOn=!emb&&L<2&&sBd>1.06;
#else
    // High, Native and Cinema walk five rows (the old four and one more toward the tips) and holds a swollen plume inside them (CH_CAP), so no plume is cut along a row
    const float fmB=1.,snB=1.;float sBd=1.72*(.92+.2*bu)*1.02;
    float kTip=emb?2.:3.,kTail=1.;const bool farOn=false;
#endif
    float iS=1./sBd,iG=1./min((1.+(.42*fmB+.3*snB)*.5)*(.92+.2*bu)*1.02*(1.+gS*(1.+.12*uP3.w)),2.07);
    float gTip=emb?0.:ceil(1.2/(iG*H)-.5),tl=emb?1.:2.;
    float rowHi=row0+tl;int nRow=int(max(kTip,gTip)+tl+1.5);
    // Rows are walked back to front, in one flat loop (a nested one costs a fifth more on the GPU). Each row takes its turns: its plumes (from Insane up the
    // plumes of even place, then those of odd place), then its great plume.
    for(int r=CH0;r<CH_SL*nRow;r++){
      int ri=r/CH_SL,sl=r-CH_SL*ri;bool bg=sl==CH_SL-1,farC=false;
      float row=rowHi-float(ri),dr=row0-row;
      float pr=mod(row,2.),jo=mod(row,8.)<2.?0.:2.;
      bool prow=!emb&&mod(row,4.)<.5;                          // a row that holds great plumes (every fourth; their places step two along on alternate ones)
      float j;
      if(bg){if(!(prow&&dr<=gTip))continue;j=4.*floor((wl.y-jo)*.25+.5)+jo;}
      else{if(!(dr>=-kTail&&dr<=kTip))continue;
#if HD>=3
        float jn=floor(wl.y+.5-.5*pr);j=floor(wl.y-.5*pr);if(abs(mod(row+j,2.)-float(sl))>.5)j+=1.;farC=abs(j-jn)>.5;if(farC&&!farOn)continue;
#else
        j=floor(wl.y+.5-.5*pr);
#endif
        if(prow&&abs(mod(j-jo+2.,4.)-2.)<.5)continue;}
      vec2 q=vec2(wl.x-row*H,wl.y-j-.5*pr);
      // out of reach of this plume even at the largest it can be here and now
#if HD>=3
      if(!emb)
#else
      if(bg)
#endif
      {vec2 qb=q*(bg?iG:iS);if(qb.x>1.2||qb.x<-1.05||abs(qb.y)>.84||chTile(qb,tile).x>.26)continue;}
      float jm=mod(j,4.),rm=mod(row,8.);
      vec2 hv=vec2(rm,jm)+lvI*37.+floor(M.z*17.);
      float h=h21(hv),h2=h21(hv+13.7);
      // the levels below the real ones are embossed into the body of the plume above them, tone on tone
      if(emb){
        if(fadeE>0.){
          vec2 sh=chTile(q,tile);
          if(sh.x<.1){
            float aE=smoothstep(pxl,-pxl,sh.x);
            vec2 nq=q/max(length(q),1e-3);float ee=min(sh.y*sh.y,1.);
            float tone=(.9+.26*dot(normalize(vec3(nq*ee*1.5,1.)),Lg))*(1.-.25*smoothstep(.1+pxl,.1-pxl,-sh.x))*(.93+.14*h2);
            acc*=1.-.3*smoothstep(.1,-.02,sh.x)*(1.-aE)*accB*fadeE;
            acc*=mix(1.,tone,aE*fadeE*accB);
          }
        }
        continue;
      }
      // kick waves and snare waves reach each plume in turn
      vec2 zo=chDiv(q/mul,fp);zo.y*=flp;vec2 zc=z-zo;float psi=chPole(zc,lay,al)*zm*1.5,psiT=length(zc)*zm*1.1+h*.14;
      // the second level is real plumes too: nested in the vane of the plume above, and taking over where that one has grown too large
      float covT=smoothstep(0.,.08,f-.55-.3*h);float vis=smoothstep(.35,.6,bodyM*fadeN);vis=L==0?1.:(L==1?max(covT,vis):vis*(1.-smoothstep(.7,1.,f)));if(vis<=.003)continue;
      vec4 e4=clamp((uP1-psi*1.4-h*.1)/.22,0.,1.);
      vec4 s4=e4*e4*(3.-2.*e4);
      float fl=s4.x+s4.y+s4.z+s4.w+uP2.z,steps=floor(fl+.5);
      vec4 b4=sin(PI*e4);float fm=max(max(b4.x,b4.y),max(b4.z,b4.w));
      // the snare is everywhere at once: a hard pop that rings down
      vec2 xs=uP4.xy-psi*.1-h*.03;vec2 b2=clamp(xs/.05,0.,1.)*exp(-max(xs,0.)*5.5);
      float snA=max(b2.x,b2.y),alt=bg?1.:mod(rm+jm,2.),snp=alt*snA;
      float big=L==0?1.-cover:(L==1?covT:0.);
      float sc0=(1.+(.42*fm+.3*snp)*(.4+.6*big)*(bg?.5:1.))*(.92+.2*bu*big);
      if(bg)sc0=min(sc0*(1.+gS*(1.+.12*uP3.w)),2.05);        // a build swells the great plumes a little more (never past the rows this loop walks: no cut edges)
#if HD<3
      if(!bg)sc0=min(sc0,tile==4?1.6:1.95);
#endif
      if(wipe>0.){float wg=clamp((wipe*1.4-psiT)/.13,0.,1.);if(wg>=1.)continue;sc0*=1.-wg;}
      vec2 q2=q/sc0;float pg=pxl/sc0;
      int tk=tile;
      vec2 sh=chTile(q2,tk);
      float d=sh.x,e=sh.y;
      if(d>.26)continue;
      float farS=farC?smoothstep(1.02,1.3,sc0):1.;
      float a=smoothstep(pg,-pg,d)*vis;
      float lod=smoothstep(.18,.5,pg);
      // ink: every plume throws a deep shadow on the ones beneath it
      float ao=smoothstep(.26,-.02,d);
      acc*=1.-.62*ao*ao*(1.-lod)*accT*vis*farS;
      if(a<=0.)continue;
      float tipx=clamp(.5+q2.x*.95,0.,1.);
      int pc=pal;if(uP5.x>=0.&&psiT<uP5.x)pc=palB;
      pcB=pc;
      float sC=(row-2.*float(spiral)*(j+.5*pr))/mul,yC=(j+.5*pr)/mul;
      float t=sC*bf+yC*af+uP2.y+.5*steps;
      // broad zones of one hue each travel across the plumage; a plume only leans a little away from its zone. Heroes wear the contrast
      t=floor(t)+smoothstep(.36,.64,fract(t))+(h-.5)*.2+.2*bu+.45*uP4.z;
      if(orn==1)t+=.35*pr;else if(orn==2)t+=.35*mod(j,2.);else if(orn==3)t+=.5*step(2.,mod(row,4.));
      if(bg)t+=CH_BIGT;
      vec3 c=chRamp(pc,t),c1=chRamp(pc,t+1.);
      {float lm=dot(c,vec3(.2126,.7152,.0722));c*=mix(1.,.2/max(lm,1e-3),step(lm,.2)*.75);}
      vec2 nq=q2/max(length(q2),1e-3);
      float ee=min(e*e,1.);
      vec3 Nn=normalize(vec3(nq*ee*1.5,1.));
      float dif=mix(.78+.42*dot(Nn,Lg),1.,lod),spc=pow(max(dot(Nn,normalize(Lg+vec3(0.,0.,1.))),0.),26.);
      float fres=pow(1.-Nn.z,3.);
      vec3 deep=chHR(c,-.6)*.34,lite=chHR(c,.45)*1.2;
      // the vane: deep at the root, luminous at the tip, combed with barbs that fan out of the root
      vec3 en=mix(deep*.8,c,smoothstep(-.05,.34,tipx));
      en=mix(en,lite,smoothstep(.35,.95,tipx)*.7);
      en=mix(en,lite*(bg?1.4:1.25),snp*.85);en=mix(en,lite*1.3,fm*.45);
      en*=1.-.46*snA*(1.-alt);
      en=mix(en,c1*1.15,smoothstep(.4,.95,tipx)*.7*hiA);   // highs: the tips fire in the next colour of the palette

      vec2 rv=q2+vec2(.62,0.);float ba=atan(rv.y,rv.x),br=length(rv);
      float K=bg?30.:22.,bw=pg*K/max(br,.05),bx=ba*K,bl=abs(fract(bx)-.5),bm=(1.-smoothstep(.25,.6,bw))*(1.-lod);
      float bar=smoothstep(.1-bw*.5,.28+bw*.5,bl);
      {
       en*=mix(1.,mix(.7,1.12,bar),bm);
       // barring: bands of the deep tone cross the vane, stepped from barb to barb
       {float fb=fract(br*4.5+h*5.+.14*mod(floor(bx),2.)),bb=pg*4.5;en=mix(en,deep*1.6,.38*smoothstep(.5-bb,.5+bb,fb)*(1.-smoothstep(.84-bb,.84+bb,fb))*(1.-smoothstep(.08,.25,bb)));}
#if HD>=2
       // pearled barbs: a bead of light at every step along each barb
       {float pb=abs(fract(br*16.-h*3.)-.5);en*=1.+.55*smoothstep(.3,.12,pb)*smoothstep(.3,.45,bl)*bm*(1.-smoothstep(.12,.3,pg*16.));}
#endif
#if HD>=1
       // shot silk: alternate barbs lean to either side of the vane's hue
       en=mix(en,chHR(en,(mod(floor(bx),2.)-.5)*.9),bm*.85);
       // barbules: a second, finer comb between the barbs
       float K2=K*5.,bw2=pg*K2/max(br,.05),bl2=abs(fract(ba*K2)-.5);
       en*=mix(1.,mix(.8,1.08,smoothstep(.1,.35,bl2)),(1.-smoothstep(.2,.5,bw2))*(1.-lod));
#endif
#if HD>=3
       float K3=K*25.,bw3=pg*K3/max(br,.05),bl3=abs(fract(ba*K3+br*40.)-.5);
       en*=mix(1.,mix(.84,1.06,smoothstep(.1,.35,bl3)),(1.-smoothstep(.2,.5,bw3))*(1.-lod));
#endif
      }
      // the enamel: cells nested inside the plume, stepping round the palette toward a gem at the heart, breathing with the row's band of the spectrum
      float lvS=uM2[int(rm/3.)][int(mod(rm,3.))];
      float R,re;vec2 ev=q2;
      if(gemM==1){R=.385;re=max(e,0.)*1.3;}                                                  // the cells follow the plume's own outline
      else if(gemM==0){float sg=.62*(.85+.3*lvS)*(1.+.25*bu);ev=q2-vec2(.13,0.);R=.5*sg;re=max(chTile(ev/sg,tk==0?2:tk).y,0.);}   // a smaller plume set toward the tip
      else{float sg=.36*(.8+.5*lvS)*(1.+.4*bu);ev=q2-vec2(.2,0.);R=.5*sg;re=max(chTile(ev/sg,5).y,0.);}   // a navette jewel in a bezel
      re=re/(1.+.35*uP4.w)+3.*lod;                                                            // presence opens the cells
      float pr2=pg/R,phi=atan(ev.y,ev.x);
      if(orn>=2||(tk==0&&gemM==1))re+=.06*abs(cos(phi*(bg?5.5:3.5)))*smoothstep(.4,1.,re)*(1.-smoothstep(.03,.1,pg));   // scalloped cells
      float iri=.5*dot(Nn.xy,Lg.xy)+.6*uP4.z;
      float body=1.;
      if(re<1.3){
        float nz=(gemM==2?2.:3.)+(bg?2.:0.);
        float zf=(1.-re)*nz,zi=clamp(floor(zf+.5),0.,nz-1.),db=zf-zi,aw=pr2*nz;
        float lvH=max(uO2[int(mod(row,4.))],hh*(.4+.6*h));
        float tz=t+.6+iri+uP5.y;
        // the heart: a rosette of gem petals on a deep ground with a bead of metal at its centre (a flat gem when it is too small to cut)
        vec3 gem=CHQ[pc*8+7]*(.9+.5*lvH)+lite*.9*lvH*lvH+mix(lite,vec3(1.),.3)*1.5*snA,met=CHQ[pc*8+6]*(.7+.5*dif)*(1.+1.5*hiA);
        // a cut star: long and short points by turns, every point split into a lit and a shaded facet
        float fa=phi*(bg?6.:4.)/PI,tri=abs(fract(fa+.5)-.5)*2.,par=mod(floor(fa+.5)+uP5.z,2.),rc0=nz-zf,cut=1.-smoothstep(.12,.4,aw);
        float pet=rc0-(.4+.58*pow(1.-tri,1.15))*(.76+.24*par);
        vec3 ptl=((bg||h2<.3)?gem:c1*1.15+.5*gem*lvH)*mix(.72,1.18,step(.5,fract(fa+.5)))*(1.2-.4*rc0);
#if HD>=4
        ptl*=.82+.36*step(.5,fract(fa*4.+rc0*3.));   // the facets are cut again
#endif
        vec3 core=mix(ptl*.9,mix(ptl,mix(c1,gem,.15)*.62,smoothstep(-aw,aw,pet)),cut);
#if HD>=1
        // a second, smaller star of metal lies on the first, turned half a point
        {float tr2=abs(fract(fa)-.5)*2.;core=mix(core,met*mix(.7,1.25,step(.5,fract(fa))),smoothstep(aw,-aw,rc0-(.14+.34*pow(1.-tr2,1.3)))*cut);}
#endif
        core=mix(core,met*1.2,smoothstep(.16+aw,.16-aw,rc0)*cut);
        vec3 cO=en,cI=core;
        if(zi>.5)cO=chRamp(pc,tz+.7*mod(zi-1.,2.)+(zi<1.5?1.4*uP4.w:0.))*(.84+.4*clamp(1.+db,0.,1.))*(1.+.5*lvH*zi/nz);
        if(zi<nz-1.5)cI=chRamp(pc,tz+.7*mod(zi,2.)+(zi<.5?1.4*uP4.w:0.))*(.84+.4*clamp(db,0.,1.))*(1.+.5*lvH*(zi+1.)/nz);
#if HD>=1
        // guilloche hairlines turned into every cell
        {float gz=zf*5.,gw=aw*5.,gm=1.-smoothstep(.2,.5,gw);
#if HD>=2
         // rose-engine work: the hairlines wave, and a second set crosses them
         float gs=.24*sin(phi*(bg?36.:24.));gz+=gs;
#endif
         float gv=mix(1.,mix(.6,1.1,smoothstep(.16,.4,abs(fract(gz)-.5))),gm);
#if HD>=2
         gv*=mix(1.,mix(.66,1.08,smoothstep(.16,.4,abs(fract(gz-2.*gs+.5)-.5))),gm);
#endif
         cO*=zi>.5?gv:1.;cI*=zi<nz-1.5?gv:1.;}
#endif
        vec3 zc=mix(cO,cI,smoothstep(-aw,aw,db));
        // basse-taille: the barbs are engraved on through the enamel
        zc*=mix(1.,mix(.74,1.08,bar),bm*step(zi+step(0.,db),nz-.5));
        // every cell is parted from the next by a wire of metal in a bed of ink (ink alone when the wire is too fine to see)
        float dq=abs(db)*R/nz,fine=1.-smoothstep(.005,.014,pg),iw=.02;
        zc=mix(zc,deep*.08,smoothstep(iw+pg,iw-pg,dq)*(1.-smoothstep(.05,.2,pg)));
        zc=mix(zc,met,smoothstep(.006+pg,.006-pg,dq)*fine*.92);
#if HD>=1
        // granulation: a row of metal grains soldered along the inside of every wire
        {float rl=max(length(ev),.03),ng=max(floor(TAU*R*(1.-zi/nz)/.034),6.),gr=.009,ph2=phi*ng/TAU;
#if HD>=2
         // and a second row along its outside, half a grain out of step
         ph2+=db<0.?.5:0.;float sd=zi>.5?1.:step(0.,db);
#else
         float sd=step(0.,db);
#endif
         vec2 gv=vec2((fract(ph2)-.5)*TAU/ng*rl,abs(db)*R/nz-.034);
         float gmk=smoothstep(gr+pg,gr-pg,length(gv))*(1.-smoothstep(.003,.01,pg))*sd;
         {vec3 gc2=mix(zc*1.8+.04,met,.3);gc2/=max(max(gc2.r,max(gc2.g,gc2.b)),1.);zc=mix(zc,gc2*(.7+.55*dot(normalize(vec3(gv/gr,.7)),Lg))+.3*pow(max(1.-length(gv/gr-vec2(-.3,.35)),0.),3.),gmk);}}
#if HD>=3
        // a diaper of tiny scales chased into the enamel, tone on tone
        {vec2 sv=vec2(phi*floor(40.*R*re+4.)/TAU,zf*4.);sv.x+=.5*floor(sv.y);vec2 sf=fract(sv)-.5;float sl=abs(length(vec2(sf.x,sf.y+.5))-.62);
         zc*=mix(1.,.72,smoothstep(.1,.03,sl)*(1.-smoothstep(.12,.3,aw*4.))*step(zi+step(0.,db),nz-.5));}
#endif
#endif
        en=zc;
        body=smoothstep(1.,1.1,re);
      }
      // the maker's seal: on a rare great plume a small plate of ink with a line of metal marks is set beside the shaft, toward the tip (it only resolves on a
      // large plume); when the palette turns, one great plume in twenty shows its marks in the gem colour for a second
      if(bg&&pg<.0048){
        float hs=h21(vec2(row*.37+1.3,j*.61+lvI*17.));
        float sfl=uP5.x>=0.?step(.95,fract(hs*13.7+float(palB)*.37))*smoothstep(0.,.3,uP5.x)*smoothstep(1.6,1.1,uP5.x):0.;
        if(hs>.9||sfl>0.){
          vec2 sq=(q2-vec2(.1,.04))/.0062;float sv=smoothstep(.0048,.0031,pg);
          vec2 pb=abs(sq-vec2(30.,3.5))-vec2(31.5,5.);
          en=mix(en,deep*.06,smoothstep(.6,-.6,max(pb.x,pb.y))*.88*sv);
          en=mix(en,mix(CHQ[pc*8+6]*1.45,CHQ[pc*8+7]*1.5,sfl),chSeal(sq)*sv);
        }
      }
      // the shaft
      {float sm=step(q2.x,.05)*step(1.,re);en=mix(en,deep*.08,smoothstep(.03+pg,.03-pg,abs(q2.y))*sm*(1.-smoothstep(.05,.2,pg)));en=mix(en,mix(lite,CHQ[pc*8+6],.5),smoothstep(.012+pg,.012-pg,abs(q2.y))*sm*(1.-smoothstep(.04,.14,pg))*.9);}
      // highs fire the iridescence: the comb stands up (grooves go to ink, ridges brighten in their own hue) and alternate barbs swing to either side of their hue
      // (alternate plumes where the barbs are too fine to see); a thin glint of metal runs out along every plume
      {float gph=fract(br*.9-uP5.w+h),gl=smoothstep(0.,.03,gph)*smoothstep(.11,.04,gph)*smoothstep(.3,.04,abs(ba));
       en*=mix(1.,mix(.5,1.25,bar),bm*hiA*.85);
       en=chHR(en,.66*hiA*((mod(floor(bx),2.)*2.-1.)*bm+(alt*2.-1.)*(1.-bm)));
       en=mix(en,CHQ[pc*8+6]*1.1,gl*hiA*.8*(1.-lod));}
#if HD>=2
      // thin-film interference across the glaze, five wavelengths through the film's thickness
      {vec3 fm2=vec3(0.),wsum=vec3(0.);float th=.9+1.5*e*e+.3*h+.4*uP4.z;
       for(int k=CH0;k<5;k++){float lam=.43+.065*float(k),I=.5+.5*cos(TAU*2.*th/lam);vec3 sp=clamp(vec3(1.-abs((lam-.6)/.09),1.-abs((lam-.535)/.075),1.-abs((lam-.45)/.08)),0.,1.);fm2+=I*sp;wsum+=sp;}
       en*=mix(vec3(1.),.7+.6*fm2/max(wsum,vec3(1e-3)),(.25+.3*body)*(1.-lod));}
#endif
      en*=dif*(.98+.3*bu)*(1.+.4*fm);
      en+=c1*fres*.5;
      en+=mix(lite,vec3(1.),.12)*spc*.6;
      float rw=.045;
      float rimM=smoothstep(rw+pg,rw-pg,-d)*(1.-smoothstep(.04,.26,pg));
      vec3 rc;
      if(rim==0||bg)rc=CHQ[pc*8+6]*(.65+.6*dif);
      else if(rim==1)rc=deep*.7;
      else rc=chRamp(pc,t+3.)*(.8+.5*dif);
      float an=atan(q2.y,q2.x);
#if HD<1
      if(bg)
#endif
      // a chain of metal beads set along the edge
      {float rr=length(q2),stp=TAU/(bg?34.:26.),al2=(fract(an/stp)-.5)*stp*rr;vec2 bv=vec2(al2,d+rw*.5);float bR=rw*.5,bm=smoothstep(bR+pg,bR-pg,length(bv))*(1.-smoothstep(.02,.07,pg));vec2 bn=bv/bR;
       rc=mix(rc*.6,lite*(.85+.45*dot(normalize(vec3(bn,.7)),Lg))+mix(lite,vec3(1.),.3)*.6*pow(max(1.-length(bn-vec2(-.3,.35)),0.),3.),bm);}
      rc*=1.+1.6*uP4.w+1.5*snp;
      // hats: dashes of the edge fire in turn
      rc=mix(rc,CHQ[pc*8+7]*(.85+.9*hh),step(fract((floor(an*2.55+8.)+uP5.z)*.25),.2));
      vec3 sc=mix(en,rc,rimM);
      sc=mix(sc,deep*.06,max(smoothstep(.016+pg,.016-pg,abs(d+rw)),smoothstep(-.014-pg,-.014+pg,d))*(1.-smoothstep(.05,.2,pg)));   // ink either side of the edge
      body*=1.-rimM;
      sc*=.94+.3*lvS*lvS;
      {float mx=max(sc.r,max(sc.g,sc.b));sc*=mx>1.?(1.+.12*log(mx))/mx:1.;}   // loud passages get brighter without any channel clipping toward white
      if(mod(rm*3.+jm*5.,5.)<2.&&pg<.16){float sp=length(q2-vec2(.1,.12));float st=clamp(1.-abs(q2.x-.1)*abs(q2.y-.12)*260.-sp*6.,0.,1.)*(1.5*hiA+1.5*hh);sc+=st*st*c1*1.2;}
      acc=mix(acc,sc,a);accT=max(accT,a);
      accB=mix(accB,body*(1.-lod)*smoothstep(.9,.55,tipx),a);
#if HD>=1
      if(a>.5){rowT=bg?-1e6:row;tT=t;frT=fres;NT=Nn;glT=1.;mulM=mul;pxM=pg;}
#endif
    }
    col=acc;bodyM=accB;mul*=4.;
  }
#if HD>=1
  // real shadow rays over the plumage: walk toward the raking light in lattice space; a plume from a row above this pixel's covers it
  {int nS=min(1+int(uDetail*1.5),CH_SR);float occ=0.;vec2 wm=w*mulM;
   for(int k=CH0;k<nS;k++){
     vec2 ws=wm+Lg.xy*(float(k)+.6)/float(nS)*.3;float rs=floor(ws.x/H+.5);
     for(int r=CH0;r<3;r++){float row=rs+float(r)-1.;float pr=mod(row,2.);float j=floor(ws.y+.5-.5*pr);vec2 q=vec2(ws.x-row*H,ws.y-j-.5*pr);
       if(row<rowT-.5&&chTile(q/(1.-.15*bu),tile).x<0.){occ+=1.;break;}}
   }
   col*=1.-.3*clamp(occ/float(nS)*1.6,0.,1.)*(1.-smoothstep(.04,.2,pxM));}
  // gloss: the glaze reflects the plumage's colour field around it, several rays across the lobe
  if(glT>.5){int nG=min(int(uDetail*1.5),CH_SR);vec3 rfl=vec3(0.);
    for(int k=CH0;k<nG;k++){float a0=float(k)*2.399963;rfl+=chRamp(pcB,tT+.9*dot(NT.xy,vec2(cos(a0),sin(a0)))+float(k)*.17);}
    col=mix(col,rfl/max(float(nG),1.),.22*frT*(1.-smoothstep(.04,.2,pxM)));}
#endif
  float lum=dot(col,vec3(.2126,.7152,.0722));
  col=max(lum+(col-lum)*1.18,0.);
  {float mx=max(col.r,max(col.g,col.b));col*=mx>1.?1./mx:1.;}
  return col;
}

void realm(){
  vec2 p=scr();
  vec4 MA=vec4(uM1[0][0],uM1[0][1],uM1[0][2],uM1[1][0]),MB=vec4(uM1[1][1],uM1[1][2],uM1[2][0],uM1[2][1]);
  float wp=uP2.w;
  // one chWall call site; the loop runs the formations under a wipe and, at the top tiers, the sub-pixel samples
  bool needB=wp>0.&&length(p)<wp*1.4+.14;
  int nP=wp>0.?2:1;
#if HD>=1
  // sub-pixel samples of the whole picture: Native 4, Cinema 5, Insane 7, Extreme 10, Offline 15 (at the tier's own Detail)
  int nSS=clamp(int(uDetail*1.4+1.25),1,HD>=5?16:(HD>=4?10:(HD>=3?7:(HD>=2?5:4))));
#else
  int nSS=1;
#endif
  vec3 acc=vec3(0.);
  for(int ss=CH0;ss<nSS;ss++){
    float fs=float(ss)+.5,a0=fs*2.399963;vec2 po=nSS>1?vec2(cos(a0),sin(a0))*sqrt(fs/float(nSS))*.7/uRes.y:vec2(0.);
    vec3 col=vec3(-1.);
    for(int k=CH0;k<nP;k++){
      if(k==0&&nP>1&&!needB)continue;
      col=chWall(p+po,(k==0&&nP>1)?MB:MA,col,k==0?0.:wp);
    }
    acc+=col;
  }
  vec3 col=acc/float(nSS);
#if HD>=1
  // averaging fine wire, ink and enamel inside a pixel greys it a little: give the chroma back so the detail tiers stay as saturated as High
  {float lm=dot(col,vec3(.2126,.7152,.0722));col=max(lm+(col-lm)*(HD>=2?1.12:1.07),0.);float mx=max(col.r,max(col.g,col.b));col*=mx>1.?1./mx:1.;}
#endif
  float hr=.13*sin(uHue*TAU),hc=cos(hr),hs=sin(hr),h3=(1.-hc)/3.,hq=hs*.57735;
  fragColor=vec4(max(mat3(hc+h3,h3+hq,h3-hq,h3-hq,hc+h3,h3+hq,h3+hq,h3-hq,hc+h3)*col,0.),0.);
}
`;
