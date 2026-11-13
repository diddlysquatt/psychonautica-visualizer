const R_GATE = `
// MUMM3. An endless funnel of neon chrysanthemum crowns, the heart of one colossal flower (v21: pull back and the corolla keeps going). Each crown is a log-polar band of petals; crowns are
// stacked down the throat with parallax, golden-angle offsets and depth fog, and one new crown rises out of the
// glowing core per beat. Every petal holds a rosette of smaller petals around its eye, which holds another, and a
// large eye is a window onto the whole frame. The spectrum is mapped by radius: rim = bass, core = treble.
float lensD(vec2 f,float hw){float R=(.2209/hw+hw)*.5;vec2 g=vec2(f.x,abs(f.y));return length(g+vec2(0.,R-hw))-R;}
vec2 lensG(vec2 f,float hw){float R=(.2209/hw+hw)*.5;vec2 g=normalize(vec2(f.x,abs(f.y))+vec2(0.,R-hw));return vec2(g.x,f.y<0.?-g.y:g.y);}
float sq2(float x){return x*x;}
// v20: above Native the screen shows the average of several render samples (1.5x to 4x each way). Detail sized by the RENDER pixel fell
// under a screen pixel there and averaged into mottle and speckle: at Offline the petals read as noise and the nested rosettes were
// gone. GTPM is the footprint the ornament resolves to, in render pixels: about .6 of a SCREEN pixel at every tier (1 at High and Native).
#if HD>=5
#define GTPM 2.4
#elif HD==4
#define GTPM 1.8
#elif HD==3
#define GTPM 1.2
#else
#define GTPM 1.
#endif
// Per-visit colour family: every palette lookup is drawn toward the palette position whose colour is nearest the
// visit's family hue (uP5.w, found and eased in JS), and for two-pole families also toward the position half a cycle
// on. The colours stay the palette's own vivid colours; only how often each appears changes. uM2[0].z = pull toward
// the family, uM2[1].x = pull toward family and complement (their sum stays below 1, so the remap is monotonic).
// With no pull the lookup is untouched.
vec3 gp(float t){float q=TAU*(t-uP5.w),s=sin(q);return pal(t-s*(uM2[0].z+uM2[1].x*cos(q))*(1./TAU));}
// the maker's seal: ten marks of seed pearls, five by seven (two ints a mark: rows 0 to 3, then 4 to 6)
float seal(vec2 p){
  if(p.x<0.||p.x>=60.||p.y<0.||p.y>=7.)return 0.;
  const ivec2 G[8]=ivec2[8](ivec2(508430,1086),ivec2(1020036,4228),ivec2(476721,17966),ivec2(583347,17969),
                            ivec2(1032734,16927),ivec2(1001009,17982),ivec2(476735,17969),ivec2(1001022,16912));
  const int Wm[10]=int[10](0,1,2,3,4,5,-1,6,7,4);
  int ci=int(p.x/6.),cx=int(p.x)-ci*6,gi=Wm[ci];
  if(gi<0||cx>4)return 0.;
  int r=6-int(p.y),bits=r<4?(G[gi].x>>((3-r)*5))&31:(G[gi].y>>((6-r)*5))&31;
  return float((bits>>(4-cx))&1);
}
// v21 the corolla. Pulled back out of the funnel, the camera finds that the funnel was the heart of one colossal flower: ring after ring of the same petals,
// each ring larger than the last (a log spiral, so it never ends), each lying over the one inside it as the crowns of the funnel do. Every ring is a crown like
// any other and goes through the same petal code. The rings creep outward (one place every eight beats; a new ring opens round the heart), and every kick
// sends a swell out through them, four rings to the beat: the ring it passes widens, fattens its petals and lights its rims. Every snare turns the rings an
// eighth of a petal, odd rings one way and even rings the other; every drop throws the whole corolla one place outward.
#define GCS0 1.04
#define GCS1 .95
#define GCSH .2
#define GCROT(n) ((mod(n,2.)<.5?gcSn:-gcSn))
float gcA,gcSig,gcFc,gcId,gcN,gcRs,gcRr,gcW,gcStag,gcFade,gcSn;vec2 gcC0,gcCk,gcWx,gcWa;
// ring j (0 = the newest, round the heart): log of its inner radius, identity, opacity, centre, beat swell, petal width factor
void gRing(float j,out float a,out float n,out float al,out vec2 c,out float sw,out float hwf){
  float xi=j+gcFc;
  vec2 dq=(vec2(xi)-gcWx)*.9;
  sw=dot(gcWa,exp(-dq*dq));
  a=gcA+gcSig*(xi-1.)+.06*sw;
  n=j-gcId;
  float born=smoothstep(0.,.85,xi);
  al=gcFade*born;
  hwf=1.08*(1.+.28*sw)*(.55+.45*born);
  c=gcC0-gcCk*exp(a);
}
#if HD>=1
// v19 detail tiers (Native and up only, nothing below is compiled at HD 0). Every petal gets engraved relief with more octaves
// per tier, cast shadows from HD crowns above it, a mirror bounce of the crown above in its lacquer, gold cloisonne lines,
// and from Cinema up dew drops. Each new loop starts at GT0, a zero the HLSL compiler cannot fold.
#define GT0 min(int(uTime),0)
float gtPh,gtNb,gtD,gtW,gtW0,gtDz,gtDzP,gtRot,gtSpin,gtN,gtTw,gtStag,gtRs,gtRr,gtFa,gtFb,gtKf,gtPinv,gtHb,gtBs;
vec2 gtCam;bool gtPhy;mat2 gtBi;
// the petal of crown L at point p (the same arithmetic as the crown loop), so a shadow or mirror ray can ask what lies above
float gtCrown(vec2 p,float L,float cj,out vec2 g,out float hc){
  float dl=L-gtPh,n=gtNb+L,zv=1.,zl,W=gtW,hwf=1.;vec2 pl;bool cor=cj>-.5;
  if(cor){float a,al,sw;vec2 c;gRing(cj,a,n,al,c,sw,hwf);pl=p-c;zl=al<.01?-1e9:log(length(pl)+1e-6)-a-uKick*.04;W=gcW;}
  else if(gtDz==0.){pl=p-gtCam*(1.-exp(-gtD*dl));zl=log(length(pl)+1e-6)+gtD*dl-uKick*.04;}
  else{zv=max(exp(gtD*dl)+gtDzP,1e-3);pl=p-gtCam*(1.-1./zv);zl=zv<.08?-1e9:log(length(pl)+1e-6)+log(zv)-uKick*.04;}
  g=vec2(0.);hc=0.;
  if(zl<-.02||zl>W+.02)return 9.;
  float ang=atan(pl.y,pl.x)+fract(n*.381966)*TAU+gtRot+uMT*gtSpin*(.6+.8*h11(fract(n*.0137)*91.+.3))+(cor?GCROT(n):0.);
  float hw=gtHb*(1.+.1*uBass+.15*sin(uMT*.12+n*.73))*hwf,ch=fract(n*.0731)*113.,d=9.;
  if(gtPhy&&!cor){
    vec2 P=vec2(zl,ang/TAU+zl*gtTw*.19),uv=gtBi*P,i0=floor(uv+.5);
    float bn=1e9;
    for(int j=GT0;j<9;j++){
      vec2 cc=i0+vec2(float(j-3*(j/3))-1.,float(j/3)-1.);
      float jn=gtFa*cc.x+gtFb*cc.y,jz=jn*gtKf;
      if(jz<0.||jz>gtW)continue;
      vec2 df=P-vec2(jz,jn*.381966011-floor(jn*.381966011));df.y-=floor(df.y+.5);
      vec2 e=vec2(df.x,df.y*TAU)*gtPinv;
      float sz=mix(1.25,.92,min(jz/gtW0,1.))*gtBs,dj=lensD(e*sz,hw);
      if(dj<0.&&jn<bn){bn=jn;d=dj;g=e*sz;hc=h11(fract(jn*.61803399)*97.+ch);}
      else if(bn>1e8&&dj<d){d=dj;g=e*sz;hc=h11(fract(jn*.61803399)*97.+ch);}
    }
  }else{
    float rsl=cor?gcRs:gtRs,Nl=cor?gcN:gtN,ul=clamp(floor(zl*rsl)/max((cor?gcRr:gtRr)-1.,1.),0.,1.);
    vec2 q=vec2(zl*rsl,ang/TAU*Nl);float row=floor(q.x);q.y+=q.x*gtTw+row*(cor?gcStag:gtStag);
    vec2 cid=vec2(row,mod(floor(q.y),Nl)),f=fract(q)-.5;
    g=f*(cor?mix(GCS0,GCS1,ul):mix(1.3,.95,ul))*gtBs;d=lensD(g,hw);hc=h21(cid+vec2(ch,fract(n*.0377)*71.));
  }
  return d;
}
// engraved relief: ridged octaves that stop at the pixel, so a finer tier reveals finer chasing
float gtRelief(vec2 q,float px){
  float v=0.,a=.5,f=1.;
  for(int i=GT0;i<4+2*HD;i++){
    float fp=px*f;if(fp>.3)break;
    float n=vnoise(q*f+float(i)*7.3);n=1.-abs(2.*n-1.);n*=n;
    v+=a*n*smoothstep(.3,.1,fp);a*=.55;f*=2.17;q=mat2(.8,.6,-.6,.8)*q+3.1;
  }
  return v;
}
// the abyss behind the crowns: filaments of pollen light stacked down the throat (more layers and octaves per tier). Each pixel shows
// one filament, the strongest, in its own palette colour, so the layers never sum toward white and the black between them stays black.
vec3 gtAbyss(vec2 pv,float r0,float z0,float a0,float tr,float hue,float px){
  vec3 ink=vec3(0.);float best=0.,ax=a0/TAU+.5;
  int NS=26+14*HD+2*(HD-1)*(HD-1);
  float th=.92+.02*float(HD);
  for(int s=GT0;s<NS;s++){
    float fs=float(s),gc=16.+fs*1.2,zz=z0*(2.5+.05*fs)-tr*(.42+.008*fs)-fs*.37;
    vec2 q0=vec2(zz,ax*gc),q1=vec2(zz,ax*gc-gc);
    float nv=0.,na=.6,f=1.;
    for(int o=GT0;o<4+HD;o++){   // v20: was 4+2*HD: fourteen octaves at Offline were grain, not filaments
      float rd=1.-abs(2.*mix(vnoise(q0*f+float(o)*3.7+fs),vnoise(q1*f+float(o)*3.7+fs),ax)-1.);
      nv+=na*rd*rd*rd;na*=.5;f*=2.13;
    }
    float fade=exp(-fs*2.4/float(NS)),fil=smoothstep(th,th+.2,nv)*fade;
    vec3 tint=gp(zz*.05+fs*.043+hue+.55);
    if(fil>best){best=fil;ink=tint*(.55+1.1*spec(fract(.06+fs*.1))*uDose);}
    float gs=110.+fs*9.;vec2 g0=vec2(zz*11.,ax*gs),gi=floor(g0),gf=fract(g0)-.5;
    float ha=h21(gi+fs*7.3);
    if(ha>.95){   // v20: half as many specks, and none under a screen pixel (they clustered into speckle)
      gf-=.18*(vec2(h21(gi+.21),h21(gi+1.91))-.5);
      float sr=length(gf)*1.5,rp=px/max(r0,.02)*gs*2.2/TAU*GTPM;
      float sp=smoothstep(.09+rp,.09-rp*.5,sr)*(.5+.5*sin(uMT*2.+ha*40.))*fade*(.3+1.4*uHat+.7*uB2.w)*smoothstep(.22,.07,rp);
      if(sp>best){best=sp;ink=tint*1.4;}
    }
  }
  return ink*min(best,1.)*.3;
}
#endif
void realm(){
  float uLevel=uM2[0].y;                                  // level smoothed over a beat (it otherwise pumps with every kick)
  float lift=1.-smoothstep(.18,.62,uLevel);                // 1 in a quiet passage, 0 when the music is loud
  float G=uM2[0].x;                                       // broadband gain: the common surge of a kick is compressed, band shapes stay
  vec2 p0=scr()/uZoom;
  float px=1.25/(uRes.y*uZoom);
  float N=uP1.x,tw=uP1.y,hue=uP1.z,rot0=uP1.w;
  // v13 wheel zoom (JS, uM2[1].yz; both exactly 0 / 1 at zoom 1, so the default framing is untouched): dz pulls the
  // camera back out of the funnel (dz > 0: the near crowns shrink faster than the deep ones, the throat flattens and
  // the whole flower comes into view) or leans into it (dz < 0: the near crowns swell past the lens); zoomed out only
  // a share of the zoom is a plain scale (uM2[1].z), the rest is that perspective pull.
  float dz=uM2[1].y;
  if(dz>0.){p0*=uM2[1].z;px*=uM2[1].z;}
  float tr=uP2.x,D=uP2.y,deep=uP2.w;
  float Rr=floor(uP2.z+min(uDetail,12.));                // real rows continue growing in extreme modes
  vec2 cam=uP3.xy;float stag=uP3.z,spin=uP3.w;
  float bloom=uP4.x,close=uP4.y,shock=uP4.z,flash=uP4.w;
  float NL=clamp(2.+floor(uDetail*1.01),1.,16.);   // v20: one level deeper at every tier (a level only draws where it is resolved)          // nested petals down to their actual pixel footprint
  float rs=N/TAU*1.2,W=Rr/rs;
  bool phy=stag<0.;
  float Fa=max(uP5.x,1.),Fb=max(uP5.y,1.),kf=TAU/(2.236068*Fa*Fb);       // phyllotaxis: floret spacing in log r
  mat2 Bi=inverse(mat2(Fa*kf,Fa*.381966011-floor(Fa*.381966011+.5),Fb*kf,Fb*.381966011-floor(Fb*.381966011+.5)));
  float pinv=1./(sqrt(kf*TAU*1.155)*.88);               // isotropic units -> petal units
  float mg=.02;
  if(phy){W=Rr*1.3/rs;mg=.75/pinv;}
  // zoomed out (below ~.6) the crowns grow more outer rows so the flower runs past the screen edge; rows keep their
  // default size and shading (W0), so the default framing is untouched
  float W0=W;if(dz<=0.)W+=max(0.,-log(uZoom*1.6));
  float dzP=dz>0.?dz*clamp(exp(W0)/3.5,1.,3.):dz;          // flowers with more rows pull further, so every visit ends as a bouquet
  // v21: pulled back, the flower does not end and nothing else stands beside it: the corolla (see gRing) carries it past every edge of the screen.
  // zE = how far the screen edge has moved out in log radius (0 at zoom 1); the spectrum, the core light and the beat ring stretch with it.
  float zE=0.,eE=1.,kc=0.,jT=0.,ornZ=0.,pbZ=0.;bool kHero=true;
  if(dz>0.){
    zE=-1.5*log(uM2[1].z);eE=exp(-zE);ornZ=smoothstep(.04,.35,dz);pbZ=ornZ*(1.+.7*smoothstep(.8,3.,dz));
    gcN=phy?(Fa<10.?16.:(Fa<17.?13.:21.)):(N>22.5?floor(N*.5+.5):N);
    gcRs=gcN/TAU*1.05;gcRr=5.;gcW=gcRr/gcRs;gcSig=.7/gcRs;gcStag=phy?.381966:stag;
    float zvT=.8+dzP;
    gcA=W0-log(zvT)-.55;{float cr=tr*.125+uM1[0].x;gcFc=fract(cr);gcId=floor(cr);}gcSn=uM1[0].y*TAU/gcN*.125;gcFade=smoothstep(0.,.2,dz);
    gcC0=cam*(1.-1./zvT);gcCk=cam*.6;
    vec2 wv=vec2(uM2[2].y,uM2[2].z);gcWx=mod(wv,100.);gcWa=floor(wv*.01)*.05*exp(-gcWx*.1);
    float zh=log(length(p0-gcC0)+1e-6);
    jT=floor((zh+.25-gcA)/gcSig+1.-gcFc)+1.;               // the outermost ring that can reach this pixel; the rings inside it follow
    kc=clamp(jT+1.,0.,10.);
    kHero=zh<W0-log(.5+dzP)+.3;                            // beyond the heart's rim only rings are walked
  }
  float ph=fract(tr),nb=floor(tr);
  float zc=max(log(length(p0)+1e-6),log(length(p0-cam)+1e-6));  // nearest crowns are centred, deepest at the vanishing point
  float Ls,K;
  if(dz==0.){
  Ls=floor(ph-(zc+mg)/D)-1.;
  K=min(ceil((W+2.*mg)/D)+2.,64.);
  }else{Ls=floor(ph-1.6);K=kHero?min(deep+4.,64.):0.;}   // v13: the pulled perspective walks every visible crown (none between the bouquet's flowers)
  vec3 coreC=gp(.04+hue*.5),ringC=gp(.1+hue),shockC=gp(.3+hue);
  float pr=.045*(1.+.25*uSub+.5*shock*(1.-shock));        // radius of the portal at the bottom
  vec3 col=vec3(0.);float T=1.,sh=1.;float win=0.;vec2 wl=vec2(0.);
  // light: a key light circling above, and the core light deep below
  vec3 Lk=normalize(vec3(cos(uMT*.07+1.),sin(uMT*.07+1.),1.4));
  float ringZ=-3.4+fract(uBeat)*(3.8+1.5*zE);                      // a ring of light rides out of the core on every beat
  float shZ=-4.+shock*(5.5+1.5*zE);                                 // drop shockwave
  float armPh=uP5.z;
  float onM=(dot(uO1,vec4(1.))+dot(uO2.xyz,vec3(1.)))*(1./7.);   // broadband onset (a kick or crash lifts every band; air left out)
  float presO=max(max(uO2.x,uO2.y)-onM,0.);                // v12: presence (vocal / lead) attack above the broadband onset
  float midO=max(max(uO1.z,uO1.w)-onM,0.);                  // v20b: mid attack above the broadband onset
  float airX=max(.5*(uB2.z+uB2.w)-.45,0.)*2.4;            // v12: air band above its usual level (hiss, rides, shimmer)
#if HD>=1
  gtPh=ph;gtNb=nb;gtD=D;gtW=W;gtW0=W0;gtDz=dz;gtDzP=dzP;gtRot=rot0;gtSpin=spin;gtN=N;gtTw=tw;gtStag=stag;gtRs=rs;gtRr=Rr;gtFa=Fa;gtFb=Fb;gtKf=kf;gtPinv=pinv;
  gtHb=.25*(1.+.4*bloom-.35*close);gtBs=(1.08-.1*uBass)*(1.-.12*bloom);gtCam=cam;gtPhy=phy;gtBi=Bi;
#endif
  for(int k=0;k<64;k++){
    if(float(k)>=K+kc||T<.015)break;
    bool cor=float(k)<kc;
    float L=Ls+float(k)-kc,dl=L-ph,n=nb+L;
    if(!cor&&dl>deep)break;
    float sL,r,zs,zl,zv=1.,Wl=W,mgl=mg,aC=1.,swl=0.,hwf=1.,cjl=-1.;vec2 pl;
    if(cor){
      // v21 a ring of the corolla: its own scale, centre, identity and beat swell; from here on it is a crown like the others
      cjl=jT-float(k);float ca;vec2 cc;gRing(cjl,ca,n,aC,cc,swl,hwf);
      dl=-.5;pl=p0-cc;r=length(pl)+1e-6;zs=log(r);zl=zs-ca-uKick*.04;zv=exp(-ca);Wl=gcW;mgl=.02;
    }else if(dz==0.){
    sL=exp(-D*dl);
    pl=p0-cam*(1.-sL);                                     // parallax: deeper crowns slide toward the vanishing point
    r=length(pl)+1e-6;
    zs=log(r);
    zl=zs+D*dl-uKick*.04;
    }else{                                                 // v13: the crown's distance with the camera pulled
      zv=max(exp(D*dl)+dzP,1e-3);sL=1./zv;pl=p0-cam*(1.-sL);r=length(pl)+1e-6;zs=log(r);zl=zv<.08?-1e9:zs+log(zv)-uKick*.04;
    }
    float snS=step(mod(n-uM2[2].x+.5,4.),1.);
    float eZ=(dz>0.&&!cor)?smoothstep(W+mg,W-.12,zl):1.;      // (pull-back only) no hard row edge at the heart's rim
    if(zl<-mgl||zl>Wl+mgl||aC<.004)continue;
    vec2 rad=pl/r,tng=vec2(-rad.y,rad.x);
    float apl=atan(pl.y,pl.x);
    float ang=apl+fract(n*.381966)*TAU+rot0+uMT*spin*(.6+.8*h11(fract(n*.0137)*91.+.3))+(cor?GCROT(n):0.);
    float hw=.25*(1.+.4*bloom-.35*close)*(1.+.1*uBass+.15*sin(uMT*.12+n*.73))*hwf;
    float bs=(1.08-.1*uBass)*(1.-.12*bloom);
    vec2 g;float d,a2,zcen,h,u,arm,armN;
    float ch=fract(n*.0731)*113.;
    if(phy&&!cor){
      // golden-angle phyllotaxis in log-polar space: floret j sits at z = j*kf, angle = j * 137.5 deg.
      // The lattice is reduced with the consecutive Fibonacci pair (Fa,Fb); the top petal is the innermost cover.
      vec2 P=vec2(zl,ang/TAU+zl*tw*.19);
      vec2 uv=Bi*P;vec2 i0=floor(uv+.5);
      float bn=1e9,bd=1e9,bz=0.;vec2 be=vec2(0.);
      for(int j=0;j<9;j++){
        vec2 cc=i0+vec2(float(j-3*(j/3))-1.,float(j/3)-1.);
        float jn=Fa*cc.x+Fb*cc.y;
        float jz=jn*kf;
        if(jz<0.||jz>W)continue;
        vec2 df=P-vec2(jz,jn*.381966011-floor(jn*.381966011));
        df.y-=floor(df.y+.5);
        vec2 e=vec2(df.x,df.y*TAU)*pinv;
        float sz=mix(1.25,.92,min(jz/W0,1.))*bs;
        float dj=lensD(e*sz,hw);
        if(dj<.5*px/r*pinv*sz){ if(jn<bn){bn=jn;bd=dj;be=e*sz;bz=jz;} }
        else if(bn>1e8&&dj<bd){bd=dj;be=e*sz;bz=jz;}
      }
      g=be;d=bd;zcen=bz;u=clamp(bz/W0,0.,1.);
      a2=px/r*pinv*mix(1.25,.92,u)*bs;
      h=h11(fract(bn*.61803399)*97.+ch);
      arm=mod(bn,Fa);armN=Fa;
    }else{
      float rsl=cor?gcRs:rs,Nl=cor?gcN:N;
      vec2 q=vec2(zl*rsl,ang/TAU*Nl);
      float row=floor(q.x);
      q.y+=q.x*tw+row*(cor?gcStag:stag);
      vec2 cid=vec2(row,mod(floor(q.y),Nl));
      vec2 f=fract(q)-.5;
      u=clamp(row/max((cor?gcRr:Rr)-1.,1.),0.,1.);
      h=h21(cid+vec2(ch,fract(n*.0377)*71.));
      arm=cid.y;armN=Nl;
      float sz=(cor?mix(GCS0,GCS1,u):mix(1.3,.95,u))*bs;
      g=f*sz;a2=px/r*rsl*sz;d=lensD(g,hw);zcen=(row+.5)/rsl;
    }
    float row=zcen*3.3;
    float ins=smoothstep(a2,-a2,d);
    float far=smoothstep(.22,.7,a2);
    // spectrum by radius: the petal's screen radius picks its band (rim = bass, core = treble)
    float zrow;
    if(dz==0.)zrow=zcen-D*dl;else zrow=zcen-log(zv);
    float tb=cor?fract(n*.381966+.13):clamp(-zrow/3.,0.,1.);
    float sp=spec(.03+.8*tb);
    float spx=cor?sp:spec(.03+.8*clamp(-zs/3.,0.,1.));          // per-pixel band: concentric equaliser rings
    // per-band onsets by the same radius map: outer rows flash to the bass, middle rows to the low-mids and mids,
    // inner rows to the presence and highs (rims and veins only: light, never geometry; zero in silence)
    float bz=cor?3.*tb:clamp(-zrow,0.,3.);
    float onB=mix(mix(uO1.y,uO1.w,smoothstep(.4,1.2,bz)),mix(uO2.y,uO2.z,smoothstep(2.,2.8,bz)),smoothstep(1.2,2.,bz));
    onB=max(onB-onM,0.);                                    // only what rises above the broadband onset: no kick strobe
    float fg=exp(-max(dl,0.)*.17); // separate distant crowns from the foreground silhouette
    vec3 dpc=gp(h*.4+row*.06+n*.093+hue);
    vec3 tip=gp(h*.4+row*.06+n*.093+hue+.12+.1*u);
    // light floor (this pass): in a quiet passage the flower used to go dark (a third of the frame black), because
    // every petal term is proportional to the spectrum. The floor is keyed to the smoothed level and added, not
    // clamped, so it eases in and out with the music (no kink), loud frames keep their full spectrum response and
    // only quiet ones are lifted (by .52); the concentric equaliser rings and the onset flashes keep their range.
    float en=(.3+.52*lift+1.5*sp*sp*uDose)*G*(1.+.6*bloom)*(1.+.35*flash*(mod(n,2.)));
    // halo around the petal edge (neon glow on the gap behind)
    float halo=exp(-max(d,0.)/(.05+a2))*(1.-ins)*(1.-far);
    col+=T*gp(h*.4+.45+n*.093)*halo*(.05+.06*uHit)*en*fg*eZ*aC;
    if(ins<=.001&&far<.01)continue;
    // shading from the petal SDF: a rounded body with a creased midrib and fine striations
    float s=clamp(-d/hw,0.,1.);
    vec2 gd=lensG(g,hw);
    float slope=(1.-s)/sqrt(max(s*(2.-s),.03));
    float lodS=smoothstep(.12,.03,a2);
    vec2 nxy=gd*slope*1.1-vec2(0.,sign(g.y))*.45*exp(-abs(g.y)*30.)+vec2(0.,cos(g.y*70.)*.25*lodS);
    vec3 nrm=normalize(vec3(nxy,1.));
    vec3 Ll=vec3(dot(Lk.xy,rad),dot(Lk.xy,tng),Lk.z);
    float dk=max(dot(nrm,Ll),0.);
    float spc=pow(max(dot(nrm,normalize(Ll+vec3(0,0,1))),0.),40.);
    float dc=max(dot(nrm,normalize(vec3(-1.,0.,-.25)))+.45,0.)/1.45;
    float fres=sq2(1.-nrm.z);
    float grad=smoothstep(-.5,.48,g.x);
    float big=cor?smoothstep(.02,.005,a2):0.;
    vec3 c=mix(dpc*.09,tip,grad*grad)*en*(.45+.75*dk)*(1.-.45*big);
    c+=coreC*dc*.35*en*exp(-r*eE*2.)*(1.+uSub);              // light from the core catches inner slopes
    c+=(mix(tip,vec3(1.),.4)*(.35+.5*uHigh)+tip*(.6*uHigh*pbZ+2.*airX*(1.+.8*pbZ)))*spc*lodS*en;    // lacquer highlight (v12: the air band polishes it)
    c+=tip*sq2(sq2(1.-s))*(.25+.5*uLevel)*exp(-r*eE*1.5)*en;    // subsurface glow through thin edges
    float rid=abs(fract(d*11.-uMT*.6)-.5);
    c+=tip*smoothstep(.12,.0,rid)*.3*grad*en*smoothstep(.5,.15,a2*11.)*(1.+(1.2*uB1.z+2.6*midO)*(1.+1.2*ornZ));
    // v20b: and every mid attack fills the tip half of four petals in ten with their own tip colour (a different set each half beat)
    c+=tip*grad*grad*midO*step(.6,fract(h*5.13+floor(tr*2.)*.618))*1.7*en*(1.-.5*big);
    c+=gp(h*.4+.62)*orn(g*vec2(2.4,4.)+vec2(.3,0.),a2*4.,h)*grad*en*(.35+1.1*uHat+.6*lift);
    float vein=abs(g.y)*(1.+abs(g.x)*2.);
    c+=gp(.5+h*.2)*smoothstep(.02+a2,0.,vein)*grad*.7*en*(1.+1.5*uHit+1.6*onB+.95*lift+2.*flash*snS+1.6*swl);
    float rimL=smoothstep(a2*2.,0.,abs(d+.015))+.55*big*smoothstep(a2*1.5,0.,abs(d+.075));
    c+=gp(h*.4+.45)*(rimL+fres*.5)*(.3+.8*lift+1.4*spx*spx*uDose*G+.35*uHit+.25*uKick+1.1*onB+2.2*flash*snS+1.3*swl);
    // nested rosettes: the petal's eye is the heart of a smaller chrysanthemum whose petals fill this one,
    // each of those has its own eye and rosette, and so on down to the pixel
    const vec2 E=vec2(-.27,0.);const float ER=.085;
    vec2 ge=(g-E)*vec2(1.,1.25);float er=length(ge);
    vec3 nc=vec3(0.);
    {
      vec2 ff=g;float fa=a2,wgt=1.,lvh=h;
      for(int lv=0;lv<16;lv++){
        if(float(lv)>=NL)break;
        vec2 gg=(ff-E)*vec2(1.,1.25);float rr=length(gg)+1e-5;
        float N2=10.+floor(lvh*4.),rs2=N2/TAU*1.2;
        float aq=fa*rs2/rr*GTPM;
        if(aq>.4)break;
        vec2 q2=vec2(log(rr/ER)*rs2-tr*.5,atan(gg.y,gg.x)/TAU*N2);
        float rw=floor(q2.x);q2.y+=rw*.5;
        vec2 f3=(fract(q2)-.5)*1.12;
        float d3=lensD(f3,.24);
        float lodq=smoothstep(.4,.12,aq)*smoothstep(ER,ER*1.4,rr);
        float line=smoothstep(aq*1.5,0.,abs(d3));
        float fil=smoothstep(aq,-aq,d3)*smoothstep(-.5,.5,f3.x);
        float e3=length((f3-E)*vec2(1.,1.25));
        vec3 lc=pal(lvh*.3+.62+float(lv)*.17+hue);
        nc+=lc*(line*(1.4+.9*big)+fil*(.3-.2*big)+smoothstep(ER*.8+aq,ER*.8-aq,e3)*(.5+1.2*sp))*lodq*wgt;
        if(d3>0.)break;
        ff=f3;fa=aq*1.12/GTPM;wgt*=.8;lvh=fract(lvh*7.13+rw*.31);
      }
    }
    // v12: vocal / lead attacks (presence onsets above the broadband onset) flare the nested rosettes inside every petal
    c+=nc*smoothstep(0.,-.05,d)*(.25+grad)*en*(.5+(.8*uMid+2.2*presO)*(1.+.8*pbZ)+.8*lift)*(1.+.18*float(min(HD,4)));   // nested rosettes take the family once, after the loop
    // v20b petal-surface ornament, drawn in the petal's own coordinates and sized by the pixel. At High it is held back until the wheel zooms in (the default framing
    // at High is the look the owner loves and is untouched); from Native up it is there at zoom 1 wherever a petal is large enough. In the realm's own language:
    // single palette colours on the dark lacquer, no white. Pinnate veins sweep from the midrib toward the tip, a second set between them as the petal grows; then
    // cross veins close cells, a third of them glazed like stained glass; the rim line becomes a string of pearls, every third one a larger pearl, all in the rim's own colour.
    {
#if HD>=1
      float oa=a2*GTPM,ov=smoothstep(.0125,.0068,oa);
#else
      float oa=a2,ov=smoothstep(.0125,.0068,oa)*max(smoothstep(1.05,1.55,uZoom),ornZ);
#endif
      if(ov>.003&&ins>.01){
        float ov2=smoothstep(.0066,.0036,oa),ov3=smoothstep(.0056,.003,oa);
        float ay=abs(g.y),vv=(g.x-1.3*ay)*7.5,vf=abs(fract(vv)-.5),vg=.5-vf,body=smoothstep(.025,.11,-d)*smoothstep(ER*1.25,ER*1.9,er);
        vec3 Cv=gp(.5+h*.2);
        float vl=max(smoothstep(oa*1.2+.0016,0.,vf*.0813),ov2*.8*smoothstep(oa*1.2+.0011,0.,vg*.0813))*smoothstep(.01,.03,ay)*body;
        c+=Cv*vl*(.8+.7*big)*en*(.35+.65*grad)*ov*(1.+1.6*onB+1.2*flash*snS+1.2*swl);
        if(ov3>.003){
          float v2=vv*2.,ck=floor(v2),cy=ay*24.+ck*.37,cf=abs(fract(cy)-.5),hcl=h21(vec2(ck,floor(cy))+h*31.+sign(g.y)*7.);
          c+=Cv*smoothstep(oa*1.2+.001,0.,cf*.0417)*.3*en*grad*ov3*body;
          // glazed cells: the air band and the hats light them, cell by cell
          c+=gp(h*.4+.62+hcl*.22+hue)*step(.66,hcl)*smoothstep(.46,.3,max(abs(fract(v2)-.5),cf))*body*ov3*en*(.3+.5*airX+1.5*uHat*step(.88,hcl));
        }
        float Rb=(.2209/hw+hw)*.5,bt=atan(g.x,ay+Rb-hw)*Rb/.056,bi=floor(bt),big=step(mod(bi,3.),.5),br=.0125+.0065*big;
        float bd=length(vec2((bt-bi-.5)*.056,d+.02)),bq=clamp(bd/br,0.,1.);
        vec3 bc=gp(h*.4+.45+.09*big)*(.35+1.2*sqrt(1.-bq*bq))*(.2+1.05*en)*(1.+.5*big)*(1.+1.8*uHat*big*step(.5,fract(bi*.381966+h*5.))+.9*onB);
        c=mix(c,bc,smoothstep(br+oa,br-oa,bd)*ov*.92);
      }
    }
    // the maker's seal: on a rare petal a line of seed pearls is set beside the midrib (too fine to read until the camera comes close); after a drop one petal's
    // seal catches the light for a moment, a different petal every time
    {
      float sfl=step(abs(h-fract(uM1[0].z*.618+.21)),.012)*smoothstep(.02,.2,shock)*smoothstep(.9,.55,shock);
      if((sfl>0.||h>.982)&&ins>.01){
        float cs=cor&&sfl<=0.?.008:.0095,la=a2/cs,slod=smoothstep(1.6,1.,la);
        if(slod>.003){
          vec2 sq=(g-vec2(-.17,.014))/cs;
          float ink=seal(sq)*smoothstep(.62,.3,length(fract(sq)-.5));
          c=mix(c,mix(gp(h*.4+.45+.08*sfl),vec3(1.),.3)*(1.+1.5*sfl+.6*en),ink*slod*(.85+.15*sfl)*smoothstep(-.012,-.03,d));
        }
      }
    }
    float ew=smoothstep(ER+a2,ER-a2,er);
    float eg=clamp(er/ER,0.,1.);
    vec3 jc=gp(h+.55)*(.3+1.6*sp)*(1.-.8*eg*eg);                       // the eye: a cut jewel
    jc+=gp(h+.85)*smoothstep(.62,.86,eg)*smoothstep(1.,.88,eg)*(.8+1.5*uHat);
    jc+=vec3(1.)*smoothstep(.32,.0,length(ge/ER-vec2(-.3,.38)))*(.4+.6*uHigh+1.3*uHat);   // hats glint in the eye jewels
    c=mix(c,jc,ew);
    c+=vec3(1.)*smoothstep(.022,0.,er)*(.3+1.2*uKick);
    // v12 treble glitter (light only, zero in silence): every hat sixteenth outlines a new third of the petals and
    // strikes a star at their tips; the air band keeps another third of the tips twinkling
    {vec2 gt=(g-vec2(.21,0.))*vec2(1.,1.5);float sr=length(gt),pw2=max(a2,.002);
     float star=exp(-sr*sr*260.)+.5*exp(-sr*5.)*(exp(-abs(gt.y)/pw2*.6)+exp(-abs(gt.x)/pw2*.6));
     float selH=step(.64,fract(h*7.31+floor(tr*4.)*.382)),selA=step(.5,fract(h*3.17+.5))*(.55+.45*sin(uMT*5.+h*47.));
     float hz=selH*uHat,az=selA*airX;
     c+=mix(tip,vec3(1.),.3)*(star*(1.8*hz+1.3*az)*lodS+rimL*1.1*hz+smoothstep(.12,.0,rid)*grad*.9*az*smoothstep(.5,.15,a2*11.))*(.5+en)*(1.+.6*pbZ);}
    // beat ring and drop shockwave light the petals they pass
    c+=ringC*exp(-sq2((zs-ringZ)*3.))*(.15+.9*uKick)*en;
    // spiral arms (one parastichy family) light up and sweep round: snares fire them, builds speed them up
    float armA=zs*2.2*sign(tw+1e-3)-armPh*TAU;
    float armL=smoothstep(.35,1.,cos(3.*apl+armA))*(.6+.4*cos(TAU*arm/armN*2.));
    float arm1=smoothstep(.45,.95,cos(apl+armA/3.));  // the snare whitens one arm of the three, not the frame
    c+=mix(tip,vec3(1.),(.3+.45*arm1*flash)*(cor?.2:1.))*armL*(.05+(.7+1.9*arm1)*flash+.6*uBuild)*(.3+grad)*en*(cor?.5:1.);
    c+=mix(shockC,vec3(1.),.5)*exp(-sq2((zs-shZ)*2.5))*shock*(1.-shock)*4.;
#if HD>=1
    if(T>.04&&ins>.01&&far<.95){
      float lof=1.-far;
      // engraved relief, more octaves per tier; the pixel footprint decides how many actually exist
      vec2 qr=g*vec2(5.,14.)+h*vec2(37.,91.);float qp=a2*14.*GTPM,re=max(qp*.6,.02);
      float r0=gtRelief(qr,qp),rx=gtRelief(qr+vec2(re,0.),qp),ry=gtRelief(qr+vec2(0.,re),qp);
      vec3 nb=normalize(vec3(nxy-vec2(rx-r0,ry-r0)/re*.34*lof,1.));
      float dkb=max(dot(nb,Ll),0.),spb=pow(max(dot(nb,normalize(Ll+vec3(0.,0.,1.))),0.),40.);
      c*=mix(1.,.86+.38*r0,.75*lof);
      c+=mix(dpc*.09,tip,grad*grad)*en*.75*(dkb-dk)*lof+(mix(tip,vec3(1.),.4)*(.35+.5*uHigh)+tip*2.*airX)*(spb-spc)*lodS*en*lof;
      // gold cloisonne lines following the petal outline, one more line per tier
      float bv=-d/.016,bk=floor(bv+.5);
      float bl=smoothstep(a2*1.4*GTPM+.0018,0.,abs(bv-bk)*.016)*step(1.,bk)*step(bk,float(2+HD))*smoothstep(.05,.014,a2*GTPM);
      c=mix(c,mix(tip,vec3(1.,.82,.45),.55)*(.5+.5*spb)*(1.+.8*uMid)*en*1.2+c*.3,bl*.9*(.4+.6*grad));
      // cast shadows from the crowns above (one caster per tier) and, last pass of the loop, a mirror bounce in the lacquer:
      // both are the same petal query, so the crown test is expanded once
      float shadow=1.;vec3 mirror=vec3(0.);vec2 scr0=rad*nb.x+tng*nb.y;
      for(int j=GT0;j<=2+HD;j++){
        bool mir=j==2+HD;
        float above=mir?1.:float(j+1),cl=L-above,dla=cl-ph,fA=cor?1.:smoothstep(-1.6,-.5,dla);
        vec2 gc;float hc;
        vec2 pq=p0+r*(mir?scr0*.3:Lk.xy*(.1+.075*above));
        float dc=gtCrown(pq,cl,cor?cjl+above:-1.,gc,hc);
        if(mir){
          float cov=smoothstep(.0,-.05,dc)*fA;
          vec3 rc=gp(hc*.4+.45+(cor?n+above:n-above)*.093+hue);
          mirror=(rc*(.4+.8*smoothstep(-.3,.45,gc.x))*.5+rc*smoothstep(.025,0.,abs(dc+.015))*.7)*cov;
        }else{
          float soft=.018+.012*above+a2*1.5;
          shadow*=1.-.2*fA*(1.-smoothstep(-soft,soft,dc))*pow(.72,above-1.);
        }
      }
      c*=shadow;
      float rflk=(fres*1.6+.1)*smoothstep(.12,.04,a2);
      c+=mirror*rflk*(.6+en)*(.8+.5*uHigh);
#if HD>=1
      // dew: droplets standing on the petal, each with a refracted core and a sun glint; a finer cell per tier
      for(int j=GT0;j<HD+1;j++){
        float cell=24.*pow(1.85,float(j)),cp=a2*cell*GTPM;if(cp>.2)break;
        vec2 qd=g*vec2(1.,1.3)*cell+h*37.+float(j)*11.,id=floor(qd),fd=fract(qd)-.5;
        float hd=h21(id+float(j)*5.7+h*9.);
        if(hd>.74){
          fd-=.22*(vec2(h21(id+.37),h21(id+1.7))-.5);
          float rr=.15+.24*(hd-.74)/.26,l=length(fd)/rr;
          if(l<1.25){
            float cov=smoothstep(1.+cp/rr*1.2,1.-cp/rr*1.2,l),dome=sqrt(max(1.-min(l*l,1.),0.));
            vec3 nd=normalize(vec3(fd/rr,dome+.03));
            float glint=pow(max(dot(nd,normalize(Ll+vec3(0.,0.,1.))),0.),120.),rimd=sq2(sq2(1.-nd.z));
            vec3 bent=mix(tip,dpc,.3+.4*dome)*(1.1+1.4*dome);
            c=mix(c,bent*en*.8+c*.35,cov*.82)+(mix(tip,vec3(1.),.3)*glint*(1.2+1.8*uHat+1.2*airX)+tip*rimd*.4)*cov*(.4+en);
          }
        }
      }
#endif
#if HD>=4
      // thin-film colour on the lacquer: the engraved relief shifts the film thickness
      c+=gp(fres*2.2+r0*1.3+h*.7+hue)*sq2(fres)*(.4+.55*uMid)*en*lof;
#endif
    }
#endif
    // distance: sub-pixel petals collapse to their average colour, deep crowns sink into the glowing haze
    c=mix(c,dpc*.3*en+tip*.12*en,far);
    float a=mix(ins,.55,far)*.94*smoothstep(-1.6,-.5,dl)*smoothstep(deep,deep-3.,dl)*smoothstep(pr*.8,pr*1.5,length(p0-cam))*eZ*aC;
    vec3 haze=coreC*(.005+.3*exp(-r*9.))*(.68+.55*uLevel);
    c*=cor?mix(1.,GCSH,smoothstep(.0,.5,u)):mix(1.,.35,smoothstep(.1,1.,u))*(1.+.7*smoothstep(1.15,1.8,zcen/W0));   // outer rows lie in the shadow of the crown above (rows grown when zoomed out catch more light)
    c=c*fg+haze*(1.-fg);
    float wv=ew*smoothstep(.03,.012,a2)*a*T;
    if(wv>win){win=wv;wl=ge/ER;}
    col+=T*a*c*sh;T*=1.-a;sh*=1.-.85*a;                     // layers seen through gaps lie in the shadow of those above
  }
  // the abyss behind every crown: core glow, god rays, nebula
  vec2 pv=p0-cam;float r0=length(pv)+1e-6,z0=log(r0),a0=atan(pv.y,pv.x);
  float ax=a0/TAU+.5;vec2 nz=vec2(z0*2.6-tr*.6,0.);
  float neb=mix(vnoise(nz+vec2(0.,ax*20.)+vnoise(nz*1.5+vec2(0.,ax*20.)+uMT*.1)*2.),vnoise(nz+vec2(0.,ax*20.-20.)+vnoise(nz*1.5+vec2(0.,ax*20.-20.)+uMT*.1)*2.),ax);
  vec3 bg=gp(z0*.12+.55+neb+hue)*(.008+.042*neb*neb);
  float rays=.5+.5*sin(a0*13.+uMT*.3+z0)*sin(a0*7.-uMT*.21);rays=rays*rays*rays*exp(-r0*3.);
  bg+=coreC*(exp(-r0*16.)*(.6+.8*uLevel+.6*uKick)+rays*exp(-r0*4.)*(.05+.2*uBass));
  bg+=ringC*exp(-sq2((z0-ringZ)*3.))*(.06+.35*uKick)*uDose;
  bg+=.0025/(r0*r0+.0025)*(.3+.5*uKick)*mix(coreC,vec3(1.),.5);
  // Orbiting filigree halos in the gaps: parallax gives the blossom a second architectural scale.
  float haloR=length(p0-cam),haloA=atan((p0-cam).y,(p0-cam).x);
  float halo=exp(-abs(haloR-(.46+.045*sin(haloA*8.+uMT*.13)))*uRes.y*.65);
  bg+=gp(haloA/TAU+uMT*.014+hue)*halo*(.12+.3*uMid);
  float laceR=.69+.055*sin(haloA*13.-uMT*.09)+.035*cos(haloA*5.+uMT*.12);
  float lace=exp(-abs(haloR-laceR)*uRes.y*.5);
  bg+=gp(haloA/TAU-uMT*.009+hue+.4)*lace*(.12+.24*uMid);
#if HD>=1
  if(T>.02)bg+=gtAbyss(pv,r0,z0,a0,tr,hue,px)*min(1.,.45+.55*uLevel+.3*lift);
#endif
  col+=T*bg;
  // at the bottom of the throat, a small portal onto the realm that comes next
  float wk=0.;
  float pw=smoothstep(pr,pr*.7,r0)*T;
  if(pw>win){win=pw;wl=pv/pr;wk=1.;}
  col+=T*mix(coreC,vec3(1.),.6)*smoothstep(.006,0.,abs(r0-pr))*(.4+1.2*uKick);
  // the tone curve eats chroma as a frame gets brighter, so the quiet-passage lift is given its colour back:
  // a chroma scale about the luminance (hue untouched), only where the lift is active
  col=max(mix(vec3(dot(col,vec3(.3333))),col,1.+.3*lift),0.);   // v15: the chroma lift can go negative, clamp it
#if HD>=1
  {float gL=dot(col,vec3(.3333));col=max(mix(vec3(gL),col,1.+.085*sqrt(float(HD))+.02*float(HD)),0.)/(1.+.04*float(max(HD-3,0)));}   // v20
  // the extra rows and veils of the high tiers must not lift the blacks: a black point, in colour-preserving form (a scale, not a subtraction)
  {float vm=max(col.r,max(col.g,col.b));float xb=float(max(HD-2,0));col*=smoothstep(.016+.02*xb,.09+.006*float(HD)+.035*xb,vm);}
#endif
  fragColor=vec4(col,win);fragWin=vec4(clamp(wl,-1.,1.)*.5+.5,wk,1.);
}`;
