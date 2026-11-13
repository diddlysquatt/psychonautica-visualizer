
const R_ESCHR = `
// ESCHR v18: the living temple city. A true isometric heightfield walked cell by cell, close up. Eight kinds of
// monument on a site grid rebuild themselves as a wavefront crosses the city. Every stone column has its height
// driven by the music: bass telescopes tiers outward as a real ripple (a delay line of the smoothed bass), mids
// drive pistons, the screw and the gates, highs raise the needles. One walk, one cell function.
vec3 cSt,cSh,cAA,cAB,cWa,cG1,cG2,cPv;
// v21 the choreography, set once per pixel in realm(): gFd the direction the rebuild front travels, gRd 1 when the front is a ring out of the middle of the
// view, gCa/gCb the dance figure (every site has a phase; sites near the figure's phase perform and the rest hold still), gAmp its strength, gSt the city's
// stature, gWl the tide, gPp/gPx the size of the walkers (they shrink away when the view is far out; every second one only comes out when you push in)
vec2 gFd;float gRd,gAmp,gSt,gWl,gPp,gPx,gCh;vec4 gCa,gCb;
float esPf(vec2 sid,float hs,float dC,float eg){
  float cp=fract(dot(sid,gCa.xy)+hs*gCa.z+dC*gCa.w+eg*gCb.x-gCb.y+.5);
  return max(gCb.z,gAmp*clamp(2.5-abs(cp-.5)*gCb.w,0.,1.));
}
// the mason's mark: a 5x7 face, cell by cell (p.x 0..60, p.y 0..7 from the foot); with ms a small cap stands after it
float esMk(vec2 p,float ms){
  float ok=step(0.,p.x)*step(p.x,71.99)*step(0.,p.y)*step(p.y,6.99);p=clamp(p,vec2(0.),vec2(71.5,6.5));
  float ci=floor(p.x/6.),cx=floor(p.x)-ci*6.,r=6.-floor(p.y);
  vec4 a=step(abs(ci-vec4(0.,1.,2.,3.)),vec4(.5)),b=step(abs(ci-vec4(4.,5.,6.,7.)),vec4(.5)),d=step(abs(ci-vec4(8.,9.,10.,11.)),vec4(.5));
  float g=dot(a,vec4(0.,1.,2.,3.))+dot(b,vec4(4.,5.,-1.,6.))+dot(d,vec4(7.,4.,-1.,8.));        // the stone that stands in each of the twelve places
  ok*=step(-.5,g)*step(cx,4.5)*max(step(g,7.5),ms);
  vec4 ga=step(abs(g-vec4(0.,1.,2.,3.)),vec4(.5)),gb=step(abs(g-vec4(4.,5.,6.,7.)),vec4(.5));float gc=step(7.5,g);
  float hi=dot(ga,vec4(508430.,1020036.,476721.,583347.))+dot(gb,vec4(1032734.,1001009.,476735.,1001022.))+gc*491199.;   // rows 0 to 3, five bits each
  float lo=dot(ga,vec4(1086.,4228.,17966.,17969.))+dot(gb,vec4(16927.,17982.,17969.,16912.))+gc*4238.;                    // rows 4 to 6
  return ok*mod(floor((r<3.5?hi:lo)/exp2((r<3.5?3.-r:6.-r)*5.+4.-cx)),2.);
}
vec4 gBa,gBb;float esBand(float i){return i<4.?dot(gBa,step(abs(i-vec4(0,1,2,3)),vec4(.5))):dot(gBb,step(abs(i-vec4(4,5,6,7)),vec4(.5)));}
vec3 esUnpack(float f){float a=floor(f/65536.),b=floor(f/256.);return vec3(a,b-256.*a,f-256.*b)/255.;}
float esS(float a,float b,float x){float t=clamp((x-a)/(b-a),0.,1.);return t*t*(3.-2.*t);}
float esB(float k){
  float x=clamp(k,0.,1.)*6.999,i=floor(x),f=x-i;vec4 m=step(abs(i-vec4(0,1,2,3)),vec4(.5)),n=step(abs(i-vec4(4,5,6,7)),vec4(.5));
  vec4 m1=step(abs(i+1.-vec4(0,1,2,3)),vec4(.5)),n1=step(abs(i+1.-vec4(4,5,6,7)),vec4(.5));
  return mix(dot(m,uP3)+dot(n,uP4),dot(m1,uP3)+dot(n1,uP4),f);
}
// v20 tessellations for flat tops, in world units: st 1 tumbling blocks (three-tone rhombille), 2 twelve-point stars set in hexagons, 3 basketweave.
// Returns the tone (0..2) and the distance to the nearest joint (world units)
float esHx(vec2 v){v=abs(v);return max(v.x,v.x*.5+v.y*.8660254);}
vec2 esTess(vec2 p,float st,float sc){
  vec2 g=p*sc;
  if(st>2.5){
    vec2 i=floor(g),f=g-i;float o=mod(i.x+i.y,2.),al=o>.5?f.x:f.y;
    return vec2(mix(o,2.,step(max(abs(f.x-.5),abs(f.y-.5)),.14)),min(min(min(f.x,1.-f.x),min(f.y,1.-f.y)),min(abs(al-.5),abs(max(abs(f.x-.5),abs(f.y-.5))-.14)))/sc);
  }
  vec4 hc=floor(vec4(g,g-vec2(.5,.8660254))/vec2(1.,1.7320508).xyxy)+.5;
  vec2 a=g-hc.xy*vec2(1.,1.7320508),b=g-(hc.zw+.5)*vec2(1.,1.7320508),v=dot(a,a)<dot(b,b)?a:b;
  float hd=esHx(v),eb=.5-hd,r=length(v);
  if(st<1.5){
    vec3 dd=vec3(dot(v,vec2(.8660254,.5)),dot(v,vec2(-.8660254,.5)),-v.y);float mx=max(dd.x,max(dd.y,dd.z)),md=dd.x+dd.y+dd.z-mx-min(dd.x,min(dd.y,dd.z));
    return vec2(dd.x>=mx?0.:(dd.y>=mx?1.:2.),min(eb,(mx-md)*.5773503)/sc);
  }
  float sd=min(hd,esHx(vec2(v.x*.8660254-v.y*.5,v.x*.5+v.y*.8660254)))-.34;
  return vec2(step(sd,0.)+step(r,.15),min(min(eb,abs(sd)),abs(r-.15))/sc);
}
// the column on cell c: x height, y material, z tier, w salt. Materials: 0 water 1 paving 2 house 3 stone 4 stair
// 5 pillar 6 gold 7 garden 8 needle
vec4 esCell(vec2 c){
  const float P=48.;
  vec2 cc=c+.5,sid=floor(cc/P),q=cc-(sid+.5)*P,aq=abs(q);
  float hs=h21(sid+uSeed.xy*91.),hb=fract(hs*17.3),hc=fract(hs*37.7);
  vec2 dS=abs(sid+.5-uP2.xy/P);float dC=max(dS.x,dS.y);                          // rings out of the middle of the view are square, like the city
  float fr=mix(dot(sid,gFd),dC,gRd)+hs*.7-uP2.w,gen=floor(uP2.z)+step(fr,0.),af=abs(fr);
  float rise=esS(0.,1.3,af)*(1.+.13*max(0.,1.-abs(af-2.)*1.5));     // a hop before it goes down and as it comes back up
  float kind=mod(floor(hs*12.)+gen*5.+floor(hb*3.)*gen,12.),r=max(aq.x,aq.y),l=length(q);
  float R=15.+hb*6.,d=R-r,h=.25,m=1.,t=0.,s=hs;
  float ang0=(abs(kind-2.)<.5||abs(kind-10.)<.5)?atan(q.y,q.x)/6.2831853+.5:0.;
  float g2=.1+.9*esPf(sid,hs,dC,step(d,0.)),sq=uP1.z*1.5707963;               // v21 only the performers move; sq is the beat-stepped clock
  float bass=esB(l/30.)*g2,eM=uP5.y*(.25+.75*g2),eH=uP5.z*g2,eA=uP5.w*g2,tall=(1.+.6*bass)*gSt;
  // the fringe of every site: houses and gardens on a street grid, each house on its own band
  vec2 blk=floor(q/3.),bq=q-blk*3.;float bh=h21(blk+sid*7.+3.),edge=step(21.5,r);
  if(r>R+1.&&edge<.5){
    float sb=step(1.,min(bq.x,bq.y));
    if(sb>.5&&bh>.2){
      float b4=mod(bh*7.,4.),lv=b4<1.?uP5.x:b4<2.?uP5.y:b4<3.?uP5.z:uP5.w;
      h=(1.+bh*5.)*(1.+.7*lv*bh*g2);m=bh>.72?7.:2.;t=floor(bh*4.);s=bh;
    }
  }
  if(edge>.5){h=-1.2;m=0.;t=0.;}
  if(r>21.5&&min(aq.x,aq.y)<2.2){h=.5;m=1.;}
  if(d>0.){
    h=1.1;m=3.;
    if(kind<.5){ // ziggurat: telescoping terraces with a central stair on each face
      float tr=floor(d/2.4);t=tr;h=(tr*2.6+2.+1.8*eM*sin(tr*1.7+sq))*tall;m=3.+step(.5,fract(tr*.5))*3.;
      if(min(aq.x,aq.y)<1.6){h=(d*1.35+1.)*tall;m=4.;}
      if(d>R-3.6){h+=4.+7.*eH;m=6.;}
    }else if(kind<1.5){ // hypostyle hall
      vec2 pq=mod(q+60.,3.2);float pillar=step(pq.x,1.)*step(pq.y,1.);t=floor((R-d)/3.);
      float ph=sin(l*.6+sq*.5+t);
      h=mix(1.6,9.+4.*ph*eM+4.*bass,pillar);m=mix(1.,5.,pillar);if(d>R-3.){h=max(h,12.+7.*bass);m=6.;}
    }else if(kind<2.5){ // the screw: a twisting helical ramp
      float ring=floor(l/3.),ang=ang0;t=ring;
      float tw=abs(2.*fract(ang+ring*.21+uP1.z*.0416667*(mod(ring,2.)*2.-1.))-1.);
      h=(3.+tw*(13.+ring*.5))*tall;m=3.+mod(ring,2.);if(l<3.){h=18.*tall;m=6.;}
    }else if(kind<3.5){ // sunken theatre with an island shrine
      float tr=floor(r/2.2);t=tr;h=(tr*1.5+1.4*eM*sin(tr*1.3-sq))*tall+.5;m=3.+step(.5,fract(tr*.5))*4.;
      if(r<4.){h=-.6;m=0.;}if(l<2.){h=11.+8.*bass;m=6.;}
    }else if(kind<4.5){ // needles
      vec2 nb=floor(q/5.),nq=q-nb*5.-2.5;float nh=h21(nb+sid*3.),rn=max(abs(nq.x),abs(nq.y)),st=floor(2.5-rn);t=st;s=nh;
      h=1.2;m=1.;if(rn<2.){float tw=(6.+nh*nh*14.)*(1.+.6*eH)*(1.+.3*bass);h=tw*(.45+st*.27)+st*1.5;m=rn<.8?8.:(rn<1.5?3.:6.);}
    }else if(kind<5.5){ // cross cathedral with corner towers
      float a=min(aq.x,aq.y),b=max(aq.x,aq.y);t=floor(a);
      h=2.;m=3.;if(a<4.5){h=(11.-a*1.4)*tall;m=5.+step(1.,a);}
      if(l<4.5){h=16.*tall;m=6.;}
      vec2 tq=aq-vec2(R*.62);if(max(abs(tq.x),abs(tq.y))<2.2){h=(14.+6.*fract(hb*5.))*tall;m=6.;}
    }else if(kind<6.5){ // hanging terraces
      float v=sin(q.x*.31+hs*6.)+sin(q.y*.27+hb*6.)+sin((q.x+q.y)*.19+hc*6.)+1.5;
      float tr=floor(v*2.5);t=tr;h=max(tr*2.4,.5)*tall;m=mod(tr,2.)<.5?7.:3.;if(v<.25){h=-.6;m=0.;}
    }else if(kind<7.5){ // concentric walls with gates that open with the mids
      float ring=floor(r/2.6);t=ring;
      float wall=step(mod(ring,2.),.5),gw=mix(1.,6.,eM);
      h=mix(1.2,(7.+ring*1.1)*tall,wall);m=mix(1.,3.,wall);
      if(min(aq.x,aq.y)<gw&&wall>.5){h=1.2;m=4.;}
      if(r<3.5){h=(12.+4.*bass);m=6.;}
    }else if(kind<8.5){ // v20 the endless stair: four flights that all climb and still close into a ring. The last landing stands 14 cells nearer and 14 higher
      // than the first, exactly on the line of sight, so in this projection it lands on it
      vec2 a=floor(q+12.);
      vec4 mk=step(vec4(0.,20.5,13.5,13.5),a.xxxx)*step(a.xxxx,vec4(23.5,23.5,23.5,16.5))*step(vec4(0.,0.,20.5,13.5),a.yyyy)*step(a.yyyy,vec4(2.5,23.5,23.5,23.5));
      vec4 sv=(clamp(vec4(a.x-2.,16.+a.y,57.-a.x,61.-a.y),vec4(0.,18.,36.,40.),vec4(18.,36.,40.,44.))+1.)*mk;
      float sA=max(max(sv.x,sv.y),max(sv.z,sv.w))-1.,lnd=min(step(abs(sA),.1)+dot(step(abs(vec4(sA)-vec4(18.,36.,40.,44.)),vec4(.1)),vec4(1.)),1.);
      float on=step(0.,sA),lo=min(a.x,a.y),hi=max(a.x,a.y);
      float pool=(1.-on)*step(3.5,lo)*step(hi,20.5)*step(lo,12.5);                                              // the pool in the court
      float bed=(1.-on)*(1.-pool)*max(step(24.5,hi),step(lo,-1.5))*step(mod(a.x+40.,4.),1.5)*step(mod(a.y+40.,4.),1.5);   // garden beds round the cloister
      float pav=step(max(abs(a.x-8.),abs(a.y-9.)),1.4);
      h=mix(mix(mix(mix(.8,1.5+.5*eM,bed),.3,pool),3.+sA*.3181818,on),4.5+2.*eH,pav);
      m=mix(mix(mix(mix(1.,7.,bed),0.,pool),mix(4.,6.,lnd),on),6.,pav);t=on*floor(sA*.25);
    }else if(kind<9.5){ // v20 stepwell: an inverted pyramid of double flights sunk into a mesa, a pool at the bottom
      float tr=min(floor(r*.5),7.),u=mix(q.x,q.y,step(aq.y,aq.x)),zz=abs(fract(u/8.+.25*tr)-.5)*2.,fl=step(1.,mod(floor(r),2.))*step(r,14.);t=tr;
      float rim=step(d,1.6),pl=1.-step(3.,r);
      h=mix((1.2+tr*1.6+fl*floor(zz*4.+.5)*.4)*(1.+.25*bass)+rim*(1.+1.5*eH),.3,pl);m=mix(mix(mix(1.,mix(3.,4.,fl),1.-step(14.,r)),3.,rim),0.,pl);
    }else if(kind<10.5){ // v20 spiral minaret: one stair winding up a cone to a gold spire, turning with the mids
      float ring=floor(l/2.4),ang=fract(ang0+uP1.z*.0125);t=ring;
      float cn=step(ring,5.5),sp2=1.-step(1.8,l);
      h=mix(mix(1.1,(3.+(5.-ring)*4.4+floor(ang*20.)*.22)*tall,cn),31.*tall,sp2);m=mix(mix(1.,4.,cn),6.,sp2);
    }else{ // v20 cube lattice: stacks of cubes in three tones stepping along the diagonal; every stack is a piston on its own band
      vec2 b=floor((q+60.)/3.);float k3=mod(b.x-b.y+60.,3.),bh2=h21(b+sid*5.);t=k3;s=bh2;
      float lv=g2*dot(uP5,step(abs(floor(mod(bh2*7.,4.))-vec4(0.,1.,2.,3.)),vec4(.5)));
      h=(2.+k3*3.+3.*step(.7,bh2))*(1.+.5*lv*bh2)*tall;m=3.+2.*step(.5,k3)+step(1.5,k3);
    }
  }
  float fl=max(gWl,.1);h=h>0.?min(h,44.):h;
  if(h<gWl){h=gWl;m=0.;}else if(h>0.)h=fl+(h-fl)*rise;                       // v21 the tide covers what stands below it; a rebuilding site sinks to the ground or the water line and keeps its own stone
  return vec4(h,m,t,s);
}
#if HD<1
#define ES_M 4.
#endif
#if HD>=1
// v19 detail tiers (HD>=1 only). Native and up: a second, finer architecture stands on the columns (crenellated parapets, hipped roofs, finials, shrubs,
// lamp posts, moored boats) walked as a second-level grid inside each column; area-sun shadow rays, hemisphere occlusion rays and a real reflection
// bounce on water (and gold from Cinema) walked through the same heightfield loop; carved stonework that follows the pixel footprint.
#if HD>=5
#define ES_M 16.
#define ES_NSH 24
#define ES_NAO 24
#define ES_NRF 4
#define ES_AA 12
#define ES_IT 2800
#elif HD>=4
#define ES_M 16.
#define ES_NSH 16
#define ES_NAO 16
#define ES_NRF 3
#define ES_AA 8
#define ES_IT 1900
#elif HD>=3
#define ES_M 8.
#define ES_NSH 12
#define ES_NAO 12
#define ES_NRF 2
#define ES_AA 8
#define ES_IT 1500
#elif HD>=2
#define ES_M 8.
#define ES_NSH 8
#define ES_NAO 8
#define ES_NRF 1
#define ES_AA 6
#define ES_IT 1100
#else
#define ES_M 4.
#define ES_NSH 4
#define ES_NAO 4
#define ES_NRF 1
#define ES_AA 4
#define ES_IT 700
#endif
#define ES_CR 1.4
#define ES_AOR 6.5
// what stands on top of column cd at sub cell s (0..M-1): x height above the column top, y kind (1 stone 2 gold 3 shrub 4 roof 5 lamp 6 hull 7 mast 8 spire)
vec2 esCrown(vec2 c,vec2 s,vec4 cd,vec4 dr,float M,float amp){
  vec2 uv=(s+.5)/M,q=uv-.5,gs=c*M+s;
  float mat=cd.y,ring=max(abs(q.x),abs(q.y))*2.,len=length(q)*2.,hc=h21(c+cd.w*37.),h=0.,k=0.;
  if(mat<.5){ // water: moored boats
    if(hc>.93){float al=step(.5,fract(hc*91.));vec2 bq=al>.5?q:q.yx;
      if(abs(bq.x)<.44&&abs(bq.y)<.17){h=.14+.1*step(abs(bq.x),.3);k=6.;}
      if(max(abs(bq.x+.05),abs(bq.y))<1.05/M){h=1.15;k=7.;}
    }
  }else if(mat<1.5){ // paving: lamp posts and urns on a street rhythm
    float pk=mod(c.x+floor(cd.w*9.),3.)+mod(c.y,3.);
    if(pk<.5&&ring<2.1/M){h=.85;k=5.;}
    else if(hc>.86&&ring<.45){h=.16+.2*(1.-ring*2.);k=3.;}
  }else if(mat<2.5){ // hipped roofs, stepped; a chimney on some
    h=max(.62*(1.-ring)+.06,0.);k=4.;
    if(hc>.7&&max(abs(q.x-.26),abs(q.y+.22))<1.05/M){h=.9;k=1.;}
  }else if(mat<4.5){ // stone: parapets, merlons along every edge that drops
    vec4 fl=vec4(1.-uv.x,uv.x,1.-uv.y,uv.y);
    float e=min(min(mix(1e3,fl.x,dr.x),mix(1e3,fl.y,dr.y)),min(mix(1e3,fl.z,dr.z),mix(1e3,fl.w,dr.w)));
    if(e<1.02/M||e<.26){float mer=step(1.,mod(floor(gs.x*.5)+floor(gs.y*.5),2.));
      h=e<1.02/M?.22+.3*mer:.2;k=1.;}
    if(mat>3.5)h=max(h,0.);
    if(hc>.9&&len<.5){h=max(h,1.25*(1.-len*1.8)+.1);k=2.;}
  }else if(mat<5.5){ // pillar capitals
    if(ring<.72){h=.2;k=1.;}if(ring<.38){h=.4;k=2.;}
  }else if(mat<6.5){ // gold: a stepped finial, a jewel on top
    h=1.3*max(1.-len*1.5,0.)+.14*step(ring,.86);k=2.;if(len<.16)k=8.;
  }else if(mat<7.5){ // gardens: shrubs of little leaf columns
    float sb=h21(gs+3.3),tuft=smoothstep(.75,.25,len+.3*h21(c+7.));
    h=(.12+.55*sb*sb)*max(tuft,.32);k=3.;
    if(hc>.62&&len<.2){h=max(h,1.15*(1.-len*3.));k=3.;}
  }else{ // needle: a spire with a lantern cap
    h=1.3*max(1.-ring*1.25,0.);k=8.;
  }
  return vec2(h*amp,k);
}
#endif
void realm(){
  int X0=min(int(uTime),0);
  vec2 s0=scr(),s=s0/uZoom;
  cSt=esUnpack(uM2[0].x);cSh=esUnpack(uM2[0].y);cAA=esUnpack(uM2[0].z);cAB=esUnpack(uM2[1].x);
  cWa=esUnpack(uM2[1].y);cG1=esUnpack(uM2[1].z);cG2=esUnpack(uM2[2].x);cPv=esUnpack(uM2[2].y);
  gBa=vec4(mod(uM1[2].x,4096.),floor(uM1[2].x/4096.),mod(uM1[2].y,4096.),floor(uM1[2].y/4096.))/4095.;gBb=vec4(mod(uM1[2].z,4096.),floor(uM1[2].z/4096.),mod(uM2[2].z,4096.),floor(uM2[2].z/4096.))/4095.;
  float vh=24.,pxW=vh/(uRes.y*uZoom);
  {float mA=uM1[1].y,mB=uM1[1].z,mi=floor(mB/65536.),fig=mod(mi,8.),dr=mod(floor(mi/16.),4.);
   vec3 ua=vec3(mod(mA,256.),mod(floor(mA/256.),256.),floor(mA/65536.))/255.;
   gFd=dr<.5?vec2(.62,.78):dr<1.5?vec2(-.78,.62):dr<2.5?vec2(-.62,-.78):vec2(.78,-.62);gRd=mod(floor(mi/8.),2.);
   gCa=fig<.5?vec4(.155,.195,.1,0.):fig<1.5?vec4(.195,-.155,.1,0.):fig<2.5?vec4(0.,0.,1.,0.):fig<3.5?vec4(.5,.5,0.,0.):vec4(0.,0.,.08,.24);
   vec2 ek=fig<1.5?vec2(.06,16.):fig<2.5?vec2(.37,14.):fig<3.5?vec2(.25,15.):vec2(.05,14.);
   gCb=vec4(ek.x,ua.x,ua.y,ek.y);gAmp=ua.z;gSt=.8+.5*mod(floor(mB/256.),256.)/255.;gWl=uP1.w;gCh=mod(mB,256.)/255.;
   gPp=esS(.125,.07,pxW);gPx=esS(1.15,1.7,uZoom);}
  float fgK=mod(floor(uM1[1].z/65536.),8.),sgA=fract(uP2.z)/.96,sgC=floor(uM1[1].z/4194304.);
  const vec3 Rv=vec3(.70710678,-.70710678,0.),Uv=vec3(-.40824829,-.40824829,.81649658),Dv=vec3(-.57735027,-.57735027,-.57735027);
  vec3 sunD=normalize(vec3(-.5,.62,.75));
  vec3 acc=vec3(0.);float nS=0.;
#if HD>=1
  vec3 sunE1=normalize(cross(sunD,vec3(0.,0.,1.))),sunE2=cross(sunD,sunE1);
  for(int ss=X0;ss<ES_AA;ss++){
#else
  for(int ss=X0;ss<4;ss++){
#endif
    float fs=float(ss-X0);
    vec2 jit=fs<.5?vec2(0.):vec2(fract(fs*.7548777)-.5,fract(fs*.5698403)-.5);
    vec2 wp=(s+jit/(uRes.y*uZoom))*vh;
    vec3 ro=vec3(uP2.xy,0.)+Rv*wp.x+Uv*wp.y,rd=Dv;
    ro+=rd*(52.-ro.z)/rd.z;
    float uf=fract(ro.x-ro.y),aaf=step(min(uf,1.-uf),1.3*pxW*1.41421356);
    vec3 cp=ro,hitP=ro,ro0=ro,roP=ro,w1=vec3(0.,0.,-99.),w2=w1;vec4 hit=vec4(0.);vec2 cell=floor(ro.xy),hcell=cell;
    float ph=0.,sh=1.,tc=0.,oT=1e6,oR=0.,tPr=1e6;vec3 oC=vec3(0.);vec2 ls=vec2(1e9);vec4 fgC=vec4(0.);
    vec3 dt=abs(1./max(abs(rd),1e-5)),sgn=sign(rd);
    vec2 nx=(cell+.5+sgn.xy*.5-ro.xy)/rd.xy;
    vec3 nrm=vec3(0,0,1);
#if HD>=1
    int rk=-1,nSh=ES_NSH,nAO=ES_NAO,nRf=0,nTot=0;float rNew=0.,cKind=0.,cTop=0.,shA=0.,aoA=0.,rLim=70.;
    vec3 rayP=vec3(0.),aoT=vec3(1.,0.,0.),aoB=vec3(0.,1.,0.),rfN=vec3(0.,0.,1.),rfA=vec3(0.);vec2 cSub=vec2(0.);
    for(int i=X0;i<ES_IT;i++){
      if(rNew>.5){rNew=0.;
        if(rk<0){
          rk=0;rayP=hitP+nrm*.035;if(ss>X0){nSh=max(ES_NSH/2,2);nAO=max(ES_NAO/2,2);}
          float hm=cKind>.5?99.:hit.y,isw=step(hm,.5)*step(.5,nrm.z);
          nRf=isw>.5?ES_NRF:0;
#if HD>=2
          if(abs(hm-6.)<.5)nRf=ES_NRF;
#endif
          nTot=nSh+nAO+nRf;
          rfN=isw>.5?normalize(vec3(.075*cos(hitP.x*2.2+hitP.y*1.7+uP1.y*3.)+.05*sin(hitP.x*7.1-uP1.y*2.),.075*cos(hitP.y*2.9-uP1.y*2.)+.05*sin(hitP.y*6.3+uP1.y*2.6),1.)):nrm;
          aoT=abs(nrm.z)<.5?normalize(cross(nrm,vec3(0.,0.,1.))):vec3(1.,0.,0.);aoB=cross(nrm,aoT);
        }
        float fk=float(rk);
        if(rk<nSh){float rr=sqrt((fk+.5)/float(nSh)),aa=fk*2.399963;
          rd=normalize(sunD+(sunE1*cos(aa)+sunE2*sin(aa))*.06*rr);rLim=70.;
        }else if(rk<nSh+nAO){float u=(fk-float(nSh)+.5)/float(nAO),aa=(fk-float(nSh))*2.399963,rr=sqrt(u);
          rd=normalize(aoT*rr*cos(aa)+aoB*rr*sin(aa)+nrm*sqrt(1.-u)+vec3(1e-3,-1.7e-3,1e-3));rLim=ES_AOR;
        }else{float u=(fk-float(nSh+nAO)+.5)/float(nRf),aa=fk*2.399963;
          rd=reflect(Dv,normalize(rfN+vec3(cos(aa),sin(aa),0.)*.03*sqrt(u)));rd.z=max(rd.z,.06);rd=normalize(rd);rLim=60.;
        }
        ro=rayP;cp=ro;tc=0.;cell=floor(ro.xy);
        sgn=sign(rd);dt=abs(1./max(abs(rd),1e-5));nx=(cell+.5+sgn.xy*.5-ro.xy)/rd.xy;
      }
#else
    for(int i=X0;i<200;i++){
#endif
      vec4 cd=esCell(cell);
      float te=min(nx.x,nx.y),zx=cp.z+rd.z*(te-tc);
      // v21 the people of the city: tiny walkers on every third row and column of paving, flagstone and stair. Here the view ray only notes the last two
      // walkable tops it skims (a walker can only be seen over a top the ray leaves less than a walker's height above); they are looked at after the walk
      if(ph+step(cd.x+.75,zx)+step(1.9,abs(cd.y-2.5))+step(abs(cd.y-2.),.5)<.5){w2=w1;w1=vec3(cell,cd.x);}
#if HD>=1
      if(ph>.5){
        bool blk=zx<cd.x,esc=zx>46.||tc>rLim;
        if(blk||esc){
          if(rk<nSh){if(!blk)shA+=1.;}
          else if(rk<nSh+nAO){if(blk){float oq=1.-clamp(tc/ES_AOR,0.,1.);aoA+=oq*oq;}}
          else{
            vec3 rc=mix(cWa*1.25+cG2*.1,cG2*.9+cAA*.2,clamp(rd.z*1.2,0.,1.));
            if(blk){
              float rm=cd.y,rz=cp.z,rwu=fract(floor(rz*.5)*.37+cell.x*.31+cell.y*.17);
              vec3 rb=mix(cSt,cAA,step(4.5,rm)*step(rm,5.5)*.8);
              rb=mix(rb,cG1*1.1,step(abs(rm-6.),.5));rb=mix(rb,cAB*.7+cSt*.3,step(abs(rm-2.),.5)*.6);rb=mix(rb,vec3(.35,.7,.28)*.5+cAB*.5,step(abs(rm-7.),.5));
              rb*=abs(tc-(nx.x-dt.x))<abs(tc-(nx.y-dt.y))?.72:.94;
              rc=mix(rb,rb*.4+mix(cG1,cG2,rwu)*(.7+.9*uP5.y),step(.55,fract(rz*.5))*step(.4,rwu)*step(3.,cd.x));
            }
            rfA+=rc;
          }
          rk++;if(rk>=nTot)break;rNew=1.;continue;
        }
      }else if(cp.z>cd.x&&zx<cd.x+ES_CR&&cd.x>-1.45){
        float t0=tc;if(cp.z>cd.x+ES_CR)t0=tc+(cd.x+ES_CR-cp.z)/rd.z;
        vec4 nbq=vec4(0.);
        for(int k=X0;k<4;k++){float fk=float(k-X0);vec2 o=fk<1.5?vec2(fk<.5?1.:-1.,0.):vec2(0.,fk<2.5?1.:-1.);nbq+=esCell(cell+o).x*step(abs(fk-vec4(0,1,2,3)),vec4(.5));}
        vec4 drq=step(nbq+.35,vec4(cd.x));
        float M=ES_M,amp=esS(.9,2.6,1./(M*pxW));
        vec3 e0=ro+rd*t0;vec2 si=clamp(floor((e0.xy-cell)*M),vec2(0.),vec2(M-1.));
        vec2 idn=abs(1./rd.xy)/M,nb2=((si+.5+sgn.xy*.5)/M+cell-ro.xy)/rd.xy;
        float tq=t0,lastX=step(abs(tc-(nx.x-dt.x)),abs(tc-(nx.y-dt.y))),hitC=0.,topC=0.,kC=0.;vec3 nC=vec3(0.,0.,1.);
        for(int m=X0;m<int(2.*M)+2;m++){
          vec2 cw=esCrown(cell,si,cd,drq,M,amp);
          float tn=min(min(nb2.x,nb2.y),te),zex=ro.z+rd.z*tn,top=cd.x+cw.x;
          if(cw.x>.003&&zex<top){
            float zen=ro.z+rd.z*tq;
            if(zen>top){tq+=(top-zen)/rd.z;nC=vec3(0.,0.,1.);}else nC=lastX>.5?vec3(1.,0.,0.):vec3(0.,1.,0.);
            topC=top;kC=cw.y;hitC=1.;break;
          }
          if(tn>=te-1e-5)break;
          if(nb2.x<nb2.y){si.x+=sgn.x;tq=nb2.x;nb2.x+=idn.x;lastX=1.;}else{si.y+=sgn.y;tq=nb2.y;nb2.y+=idn.y;lastX=0.;}
          if(si.x<0.||si.y<0.||si.x>M-.5||si.y>M-.5)break;
        }
        if(hitC>.5){
          hitP=ro+rd*tq;nrm=nC;tPr=tq;ro0=ro;hit=cd;hcell=cell;cKind=kC;cTop=topC;cSub=si;ph=1.;aaf=1.;
          rk=-1;rNew=1.;continue;
        }
      }
#endif
      if(zx<cd.x){
        if(ph<.5){
          float tp=tc;
          if(cp.z>cd.x){tp=tc+(cd.x-cp.z)/rd.z;nrm=vec3(0,0,1);aaf=max(aaf,step(abs(tp-tc)*.8165,1.3*pxW));}
          else{nrm=abs(tc-(nx.x-dt.x))<abs(tc-(nx.y-dt.y))?vec3(1,0,0):vec3(0,1,0);aaf=max(aaf,step((cd.x-cp.z)*.8165,1.3*pxW));}
          hitP=ro+rd*tp;tPr=tp;ro0=ro;hit=cd;hcell=cell;ph=1.;
#if HD>=1
          rk=-1;rNew=1.;continue;
#endif
          ro=hitP+nrm*.02+sunD*.02;rd=sunD;cp=ro;tc=0.;cell=floor(ro.xy);
          sgn=sign(rd);dt=abs(1./max(abs(rd),1e-5));nx=(cell+.5+sgn.xy*.5-ro.xy)/rd.xy;
          continue;
        }else{sh=0.;break;}
      }
      if(ph<.5)aaf=max(aaf,step(max(zx-cd.x,0.)*.8165,1.3*pxW));
      if(ph>.5&&(zx>54.||tc>70.))break;
      cp.z=zx;tc=te;
      if(nx.x<nx.y){cell.x+=sgn.x;nx.x+=dt.x;}else{cell.y+=sgn.y;nx.y+=dt.y;}
    }
    // v21 the walker the ray noted: is one standing on either of the two tops just now (the nearer top first)? It stands in the plane through its own spot
    // that faces the view. Walkers take one short step on every beat; on a drop they stop and jump with their arms up. Every second one only comes out
    // when you push in, and they all shrink away when the view is far out
    vec4 wq=vec4(0.);
    for(int k=X0;k<2;k++){
      vec3 wc=k==X0?w2:w1;vec2 lm=mod(wc.xy,3.);float ax=step(.5,lm.y),lh=h11(mix(wc.y,wc.x,ax)*.731+ax*5.3+.17);
      float vs=step(.22,fract(lh*13.7))*(step(.5,lh)*2.-1.)*(.14+.2*fract(lh*29.1)),sp=3.+floor(fract(lh*7.3)*5.);   // some rows stand and watch
      float fq=(mix(wc.x,wc.y,ax)+.5-floor(lh*97.)-vs*uP1.z)/sp,f=fract(fq)*sp;
      if(wc.z>-50.&&wq.w<.5&&min(lm.x,lm.y)<.5&&f<1.){w1=wc;wq=vec4(ax,f,floor(fq),1.+lh);}
    }
    if(wq.w>.5&&gPp>.02){
      float ax=wq.x,wi=wq.z,wh=h21(vec2(wi,mix(w1.y,w1.x,ax)+ax*77.)),s2=gPp*mix(1.,gPx,mod(wi,2.))*step(.22,fract(wh*17.3))*(.8+.45*wh)+1e-4;
      float mv=sin(3.14159*fract(uP1.z))*step(.22,fract((wq.w-1.)*13.7));
      vec2 fo=w1.xy+.5+(.5-wq.y)*vec2(1.-ax,ax)+(fract(wh*31.7)-.5)*.56*vec2(ax,1.-ax)-roP.xy;
      vec2 w=vec2(-dot(fo,Rv.xy),roP.z+Dv.z*dot(fo,vec2(1.))/(Dv.x+Dv.y)-w1.z)/s2;
      w.y-=gCh*abs(sin(3.14159*uBeat+wh*.6))*(.1+.14*wh)+.025*mv;
      float lg=mod(floor(uP1.z+.5)+wi,2.)*2.-1.,ar=abs(w.x);
      float l1=max(abs(w.x+.024+.03*mv)-.016,abs(w.y-.055-.02*mv*max(lg,0.))-.055);
      float l2=max(abs(w.x-.024-.03*mv)-.016,abs(w.y-.055-.02*mv*max(-lg,0.))-.055);
      float rb=max(ar-mix(.072,.04,clamp((w.y-.09)/.2,0.,1.)),abs(w.y-.19)-.1);
      float hd=length(w-vec2(0.,.335))-.048;
      float ht=max(ar-(.455-w.y)*.6,.36-w.y)+step(wh,.55);
      vec2 pa=vec2(ar,w.y)-vec2(.05,.26),ba=vec2(.075,.15);
      float am=length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.,1.))-.014+step(gCh,.3);
      float dd=min(min(min(l1,l2),min(rb,hd)),min(ht,am)),lw=max(.014,1.15*pxW/s2),on=step(dd,lw)*step(.06,s2);
      aaf=max(aaf,step(dd,lw+1.5*pxW/s2));
      vec3 rc=mix(mix(cAA,cAB,step(.25,wh)),mix(cG2,mix(cG1,vec3(1.),.6),step(.75,wh)),step(.5,wh))*1.2;
      vec3 kc=mix(cSh*.5+rc*.25,rc*(1.-.45*step(abs(w.y-.17),.014)),step(min(rb,am),0.));
      kc=mix(kc,cG1*1.25,step(ht,0.));kc=mix(kc,mix(cG1,vec3(1.),.6),step(hd,0.));kc=mix(kc,cSh*.22,step(0.,dd));
      fgC=vec4(kc*(1.+.35*uM1[0].x),on);
    }
#if HD>=1
    float ao=1.;vec3 rfl=vec3(0.);
    if(rk>=0){sh=shA/float(max(min(rk,nSh),1));
      if(rk>nSh)ao=1.-aoA/float(min(rk-nSh,nAO));
      if(nRf>0&&rk>nSh+nAO)rfl=rfA/float(min(rk-nSh-nAO,nRf));
    }
#endif
    // shade: heights of the four neighbours for edges, contact and ink
    vec4 nbh=vec4(0.);
    for(int k=X0;k<4;k++){
      float fk=float(k-X0);vec2 o=fk<1.5?vec2(fk<.5?1.:-1.,0.):vec2(0.,fk<2.5?1.:-1.);
      float nv=esCell(hcell+o).x;
      nbh+=nv*step(abs(fk-vec4(0,1,2,3)),vec4(.5));
    }
    vec3 p=hitP,n=nrm;float mat=hit.y,tier=hit.z,salt=hit.w,top=n.z,H=hit.x,fx=n.x;
    vec2 fc=fract(p.xy);float zd=H-p.z,bp=pxW;
    vec3 base=mix(cSt,cAA,step(4.5,mat)*step(mat,5.5)*.8);
    base=mix(base,cPv,step(abs(mat-1.),.5));
    base=mix(base,cAB*.7+cSt*.3,step(abs(mat-2.),.5)*.5);
    base=mix(base,cG1*(1.1+.45*uP5.w+.4*uP5.z),step(abs(mat-6.),.5));
    base=mix(base,cWa*.6+cAA*.4,step(abs(mat-8.),.5));
    base=mix(base,vec3(.35,.7,.28)*.5+cAB*.5,step(abs(mat-7.),.5));
    base*=.9+.2*h11(salt*13.+tier*3.);
    vec3 c=base;
#if HD>=1
    if(cKind>.5){
      float M=ES_M,k=cKind,tsalt=h21(hcell+cSub*.13+3.1);
      vec3 cb=cSt;
      if(k<1.5)cb=mix(cSt,cAA,.15+.2*tsalt);
      else if(k<2.5)cb=cG1*1.1;
      else if(k<3.5){cb=vec3(.3,.66,.26)*.55+cAB*.45;cb*=.72+.5*tsalt;}
      else if(k<4.5)cb=mix(cAA,cAB,.25+.5*fract(salt*7.));
      else if(k<5.5)cb=cSh*.5+cSt*.15;
      else if(k<6.5)cb=mix(cAB,cAA,step(.5,fract(salt*9.)));
      else if(k<7.5)cb=cSh*.4+cG1*.15;
      else cb=cG2*1.1;
      c=cb*(top>.5?1.08:(fx>.5?.66:.9));
      vec2 fq=fract(p.xy*M);
      float de=top>.5?min(min(fq.x,1.-fq.x),min(fq.y,1.-fq.y))/M:min(min(fract(fx>.5?p.y*M:p.x*M),1.-fract(fx>.5?p.y*M:p.x*M))/M,max(cTop-p.z,0.));
      if(k>2.5&&k<3.5&&top>.5&&tsalt>.8)c=mix(cG1,cG2,fract(tsalt*7.))*(1.2+1.6*uP5.z);          // blossoms open on the highs
      if(k>4.5&&k<5.5&&cTop-p.z<.2)c=mix(cG1,vec3(1.),.25)*(1.1+1.8*uP5.z+.9*uP5.w);             // lanterns
      if(k>7.5)c=mix(cG2,cG1,.4)*(1.05+1.3*uP5.z);
      c=mix(c,c*.25+cSh*.28,esS(1.25*bp+.02,.4*bp,de));                                        // crisp ink round every small block
    }else{
#endif
    if(top>.5){
      c*=1.06;
      vec4 fl=vec4(1.-fc.x,fc.x,1.-fc.y,fc.y); // dist to each side
      vec4 dr=step(nbh,vec4(H-.05));
      float drop=min(min(mix(1e3,fl.x,dr.x),mix(1e3,fl.y,dr.y)),min(mix(1e3,fl.z,dr.z),mix(1e3,fl.w,dr.w)));
      vec4 cav=step(vec4(H+.05),nbh);float near=min(min(mix(1e3,fl.x,cav.x),mix(1e3,fl.y,cav.y)),min(mix(1e3,fl.z,cav.z),mix(1e3,fl.w,cav.w)));
      vec2 tl=floor(p.xy);float flip=floor(uM1[0].z)+step(.5,fract(h21(tl+salt)*5.));
      // v20 tessellation lookups for paving and flagstones, done here once for both (one copy of the routine keeps the D3D compile down)
      float ts=floor(fract(salt*5.7+.31)*4.),tsc=mat<1.5?.5:1.;vec2 tz=vec2(0.),t2=vec2(1.,1.);
#if HD>=1
      const float e2=0.;
#else
      float e2=esS(.034,.016,bp);
#endif
      if(mat>.5&&mat<4.5&&abs(mat-2.)>.5){
        for(int k=X0;k<2;k++){float fk=float(k-X0);if(fk>.5&&e2<.01)break;if(fk<.5&&ts<.5)continue;
          vec2 rz=esTess(p.xy,fk<.5?ts:mod(ts,3.)+1.,fk<.5?tsc:4.*tsc);if(fk<.5)tz=rz;else t2=rz;}
      }
      if(mat<.5){ // water
        float wv=.5+.5*sin(p.x*2.2+p.y*1.7+uP1.y*3.)*sin(p.y*2.9-uP1.y*2.);
        c=mix(cWa,cWa*1.5+cG2*.2,wv);c+=cG2*esS(.7,1.,fract(p.x*.7+p.y*.5+uP1.x*.5))*(uP5.z+uP5.w)*.7;
        c+=cG2*uO1.x*.5*esS(.14,0.,abs(fract(length(fract(p.xy/6.)-.5)*3.-uP1.z*.5)-.5));      // v21 rings open on the water with the sub
        c=mix(c,cWa*1.7+cG2*.3,.5*max(gBa.x,gBa.y)*(.55+.45*wv));                                 // and the whole canal swells brighter with the low end
#if HD>=1
        c=mix(c,rfl*.7+cWa*.45,.5);                                  // the city, upside down in the canal
        {float rq=abs(fract(p.x*3.3+p.y*2.7+.7*sin(p.y*2.1+uP1.y*2.)-uP1.y*.5)-.5);c=mix(c,mix(cWa*.7,cG2*.9,.3),esS(.07+bp,.03,rq)*.32*esS(.05,.1,1.-bp*5.));}
#endif
      }else if(mat<1.5){ // paving: rosettes and tile rings
        if(ts>.5){ // v20 tessellated plazas; the tones turn one step on every snare
          float lw=max(.035,1.1*bp),tn=mod(tz.x+floor(uM1[0].z),3.),tf=esS(.3,.14,bp);
          c=mix(c,tn<.5?c:(tn<1.5?mix(c,cAB,.5)*.9:mix(c,cG1,.6)*(1.+.7*uM1[0].y+1.1*uP5.w+.9*uP5.z)),tf);
          c=mix(c,c*.35+cSh*.3,esS(lw+bp,lw*.4,tz.y)*tf);
        }else{
        vec2 g=abs(fract(p.xy*.5)-.5)*2.;c*=.95;float rg=max(g.x,g.y);
        c=mix(c,cAB*.7+c*.5,esS(.08+bp,.08,abs(rg-.7))*mod(tl.x+tl.y,2.));
        float rs=length(fract(p.xy*.5)-.5);c=mix(c,cG1,esS(.14+bp,.14,abs(rs-.3))*.5);
        }
        // v20 pushed in, every slab carries a second, four times finer tessellation cut into it (a different one from the slab's own)
        {if(e2>.01){float l2=max(.008,.9*bp);
          c*=1.+.07*(t2.x-1.)*e2;c=mix(c,c*.6+cSh*.14,esS(l2+bp,l2*.4,t2.y)*e2*.7);}}
#if HD>=1
        { // v19: inlaid paving: fine keyed tiles inside each slab, an eight-petal rosette in each ring
          float Tn=ES_M,lw=max(.012,.7*bp);vec2 fq=abs(fract(p.xy*Tn)-.5);float tf=esS(2.5,5.,1./(Tn*bp));
          float tg=max(fq.x,fq.y);c=mix(c,c*.72+cSh*.14,esS(.5-(lw*Tn),.48-.3*lw*Tn,tg)*tf*.55);
          vec2 cq=fract(p.xy*.5)-.5;float ra=atan(cq.y,cq.x),pet=.3+.07*cos(ra*8.),dp=abs(length(cq)-pet);
          c=mix(c,mix(cAA,cAB,mod(tl.x+tl.y,2.)),esS(lw*1.4+bp,lw*.6,dp)*.7*tf);
        }
#endif
      }else if(mat<2.5){ // roof tiles
        c=mix(c,cAA*.9,.5);float rt=esS(.45,.5,fract(p.x*3.));c*=.86+.2*rt;
      }else if(mat<4.5){ // stone top: flagstones, inlays that flip on the snare
        if(ts>.5){ // v20 tessellated flagstones: tumbling blocks, star hexagons or basketweave, by site; the tones turn one step on every snare
          float lw=max(.03,1.1*bp),tn=mod(tz.x+floor(uM1[0].z)+tier,3.),tf=esS(.22,.1,bp);
          c=mix(c,tn<.5?c*1.06:(tn<1.5?c*.62+cSh*.12:mix(cAA,cAB,mod(tier,2.))*(1.+.8*uM1[0].y+1.1*uP5.w+.9*uP5.z)),tf);
          c=mix(c,c*.3+cSh*.3,esS(lw+bp,lw*.4,tz.y)*tf);
        }else{
        vec2 f2=abs(fract(p.xy)-.5);float g2=max(f2.x,f2.y),dia=f2.x+f2.y;
        c*=.86+.18*esS(.5-bp*1.5,.44,g2);
        float pick=mod(tl.x+tl.y+tier,2.);
        float inl=esS(.3+bp,.3,dia)*pick;
        c=mix(c,mix(cAA,cAB,mod(flip,2.))*(1.+.8*uM1[0].y+1.1*uP5.w+.9*uP5.z),inl*.9);
        c=mix(c,cG1,esS(.05+bp,.05,abs(dia-.42))*.7);
        }
        // v20 pushed in, every slab carries a second, four times finer tessellation cut into it (a different one from the slab's own)
        {if(e2>.01){float l2=max(.008,.9*bp);
          c*=1.+.07*(t2.x-1.)*e2;c=mix(c,c*.6+cSh*.14,esS(l2+bp,l2*.4,t2.y)*e2*.7);}}
#if HD>=1
        { // v19: carved flagstones: a quatrefoil cut into each slab, coloured ink at limited coverage, a second octave of key lines from Cinema
          vec2 cq=fract(p.xy)-.5;float ra=atan(cq.y,cq.x),qf=.26+.05*cos(ra*4.),dq=abs(length(cq)-qf),lw=max(.011,.65*bp);
          c=mix(c,mix(cG2,cG1,mod(tl.y+tier,2.))*.95,esS(lw+bp,lw*.5,dq)*.75*esS(2.,5.,.25/bp));
#if HD>=2
          float Kf=ES_M*2.;vec2 kk=abs(fract(p.xy*Kf)-.5);float lm=(mod(floor(p.x*Kf)+floor(p.y*Kf),2.)>.5?kk.x:kk.y)-.35;c=mix(c,c*.7+cSh*.18,esS(.05,-.05,abs(lm))*.45*esS(3.,6.,1./(Kf*bp)));
#endif
        }
#endif
      }else if(mat<5.5){c=mix(c,cG1,.35);}
      else if(mat<6.5){ // gold shrine top: concentric rings pulsing with the kick
        float rr=length(fc-.5);c=mix(c,cG2*1.3,esS(.2+bp,.2,abs(fract(rr*4.-uP1.x*1.2)-.5))*(.3+uM1[0].x));
      }else if(mat<7.5){ // garden leaves
        vec2 lq=fract(p.xy*3.)-.5;float lh=h21(floor(p.xy*3.)),ld=length(lq-(vec2(lh,fract(lh*7.))-.5)*.5);
        c*=.72+.5*esS(.42,.1,ld);c=mix(c,mix(cG1,cG2,fract(lh*3.))*1.3,esS(.13+bp,.1,ld)*step(.72,fract(lh*5.))*(.35+1.2*uP5.z));
      }else{ // needle cap: lantern
        c=mix(cG1,vec3(1.),.5)*(1.+1.5*uP5.z+.8*uP5.w);
      }
      // stair treads: a chaser that climbs a flight a beat
      if(abs(mat-4.)<.5){float tq=fract(p.x+p.y);c*=.72+.28*esS(.5-bp,.5+bp,tq);float ch=fract(H/3.5-uP1.z*.25);c+=cG2*.8*esS(.2,0.,ch)*(.4+uM1[0].x);}
      c*=1.+(.3+1.3*uP5.w+.6*uP5.z+.6*uM1[0].x)*esS(.25,0.,drop);                 // bright rim; it glows with the air band
      c=mix(c,c*.2+cSh*.3,esS(1.4*bp+.03,.015,drop));   // ink at the drop
      c*=mix(.62,1.,esS(.0,.45,near));           // contact shade under taller neighbours
    }else{
      float wu=fx>.5?p.y:p.x,cu=fract(wu),nb=fx>.5?nbh.x:nbh.z;
      float lft=fx>.5?nbh.w:nbh.y,rgh=fx>.5?nbh.z:nbh.x;
      c=base*(fx>.5?.68:.92);if(abs(mat-6.)<.5){
        float rb=abs(fract(wu*2.)-.5),lz=fract(p.z*.34),rib=floor(wu*2.);float glv=esBand(mod(rib,8.));
        c*=.82+.42*esS(.08+bp,.32,rb);
        c=mix(c,c*.45+cSh*.3,esS(.09+bp,.09,abs(lz-.5))*.8);c=mix(c,cAA*1.1,esS(.05+bp,.05,abs(lz-.62)));
        c+=mix(cG2,cG1,.5)*esS(H*glv+.4,H*glv-.4,p.z)*esS(.32,.12,rb)*(.55+.9*glv);
        {float eg=esS(.07,.03,bp),lzg=abs(fract(wu*2.)-.5)*2.4+abs(fract(p.z*.68+.16)-.5)*1.5,lg2=max(.03,1.6*bp);
         c=mix(c,mix(cAA,cAB,mod(rib+floor(p.z*.68+.16),2.))*(1.+.9*glv),esS(.5,.5-lg2,lzg)*eg*.85);c=mix(c,c*.4+cSh*.3,esS(lg2,lg2*.3,abs(lzg-.5))*eg*.8);}}
      float zb=p.z-nb,cr=fract(p.z);
      c*=.92+.1*esS(.04,.09,cr);
      float by=floor(p.z*.5),bu=fract(wu*.5)*2.-1.,bvf=fract(p.z*.5)*2.-1.;
      float wmask=step(abs(mat-3.),.5)+step(abs(mat-4.),.5)+step(abs(mat-5.),.5)+step(abs(mat-2.),.5)+step(abs(mat-8.),.5)+step(abs(mat-7.),.5);
      vec2 wq=vec2(bu,bvf+.1);
      float arch=max(abs(wq.x)-.46,wq.y-.2),ad=wq.y>.2?length(wq-vec2(0.,.2))-.46:arch;
      float wid=floor(wu*.5)*3.1+by*7.7+salt,bt=h11(floor(wu*.5)*2.3+by*1.7+salt*5.);
      // the wall is an equalizer: each window bay belongs to a band, lit up to that band's level by height
      float band=mod(floor(wu*.5)+tier,8.),lv=esBand(band);
      float rel=clamp(p.z/max(H,.1),0.,1.),eq=esS(rel-.06,rel+.06,lv);
      if(abs(fgK-3.)<.5)eq=step(.5,fract((floor(wu*.5)+by+floor(uP1.z+.5))*.5))*(.3+.7*max(uM1[0].x,uM1[0].y));        // v21 call and answer: half the bays on one beat, half on the next
      else if(fgK>1.5&&fgK<4.5)eq=step(abs(fract((by+band)*.25-uP1.z*.25)-.5),.13)*(.35+.65*lv);                     // a lit storey that climbs one floor a beat
      float lit=eq*step(.2,h11(wid))+.25*uM1[0].x+1.1*step(.8,h11(wid*1.37+floor(uM1[1].x)*.713))*(1.-fract(uM1[1].x));
      vec3 wc=mix(cSh*.3,mix(cG1,cG2,fract(salt*7.+band*.13))*(1.2+1.6*lit),lit);
      float wmf=wmask*esS(.8,1.8,zd);
      float win=step(bt,.45),glyp=step(.45,bt)*step(bt,.72),pil=step(.72,bt);
      c=mix(c,wc,wmf*win*esS(bp,-bp,ad));
      c=mix(c,c*.35+cSh*.3,wmf*win*esS(.09,.0,abs(ad))); // frame
      // carved glyph panel: lights with the band of its bay
      vec2 gc=vec2(fract(wu*.5)*4.,fract(p.z*.5)*4.);vec2 gi=floor(gc);float gon=step(.5,h21(gi+by*3.+floor(wu*.5)*11.+salt));
      float pm=glyp*wmf*esS(.5,.42,max(abs(wq.x),abs(bvf)));
      c=mix(c,mix(c*.5+cSh*.2,mix(cAA,cG1,lit)*(1.+lit*1.3),gon),pm);
      // pilaster with a capital
      float ppm=pil*wmf,px0=abs(bu);c=mix(c,c*1.18,ppm*esS(.34+bp,.32,px0));c=mix(c,c*.55,ppm*esS(.04+bp,.04,abs(px0-.34)));
      c=mix(c,cG1*.9,ppm*esS(.34,.3,px0)*esS(.7,.85,bvf));
      // frieze band under the eave with glyph bits, its colour flips on the snare
      float fz=esS(1.42+bp,1.4,zd)*esS(.45-bp,.45,zd);
      { // v19: engraved masonry on every plain wall (v20: at every tier): running-bond courses and a per-stone tone, coloured ink, never lighter than the stone
        float stn=wmf*(1.-win)*(1.-step(.01,pm))*(1.-step(abs(mat-6.),.5));
        float ivyW=step(abs(mat-7.),.5);stn=max(stn,ivyW*esS(.8,1.8,zd));
        float Co=2.*ES_M,bf=esS(2.5,5.5,1./(Co*bp));
        if(bf>.01||ivyW>.5){
        float rowB=floor(p.z*Co),offB=.5*mod(rowB,2.),uB=wu*Co*.5+offB;
        vec2 fB=vec2(fract(uB),fract(p.z*Co));
        float dB=min(min(fB.x,1.-fB.x)*2.,min(fB.y,1.-fB.y))/Co,lw=max(.008,.6*bp),tn=h21(vec2(floor(uB),rowB)+salt*3.);
        c=mix(c,c*(.76+.5*tn),stn*bf);c=mix(c,mix(cAB,cAA,fract(tn*7.))*.8,step(.9,tn)*.5*stn*bf);
        c=mix(c,c*.42+cSh*.1,stn*bf*esS(lw+.6*bp,lw*.3,dB)*.8);
        if(ivyW>.5){ // ivy hangs down the garden walls, leaf by leaf, blossoms on the highs
          float Lv=ES_M*1.5;vec2 lg=vec2(wu,p.z)*Lv,li=floor(lg),lf=fract(lg)-.5;float lh=h21(li+salt*5.);
          float reach=2.+7.*h21(vec2(floor(wu*Lv/3.),salt+1.)),hang=esS(1.,.55,zd/reach),ld=length(lf-(vec2(lh,fract(lh*7.))-.5)*.42);
          vec3 lc=(vec3(.3,.66,.26)*.6+cAB*.4)*(.6+.7*lh);lc=mix(lc,mix(cG1,cG2,fract(lh*3.))*(1.1+1.4*uP5.z),step(.88,lh)*.85);
          c=mix(c,lc*(fx>.5?.76:1.),esS(.48,.26,ld)*esS(2.,4.,1./(Lv*bp))*hang);
        }
        }
#if HD>=2
        // tracery in every lit window: mullions, a transom, a rose in the arch head; dark bars over the light
        float inw=wmf*win*esS(bp,-bp,ad),mu=min(min(abs(wq.x),abs(abs(wq.x)-.23)),abs(wq.y+.25)),rs2=abs(length(wq-vec2(0.,.24))-.17);
        c=mix(c,cSh*.32+c*.28,inw*esS(.035+bp,.01,min(mu,rs2))*.85);
        // the bay's blank panels: a recessed square with a key-pattern border
        vec2 aq2=abs(vec2(bu,bvf));float pz=max(aq2.x,aq2.y);
        float pd=wmf*(1.-win)*(1.-step(.01,pm))*step(pz,.82);
        c=mix(c,c*.82+cSh*.12,pd*esS(.72+bp,.7,pz)*.5);
        float keyk=mod(floor(wu*Co*.5)+floor(p.z*Co*.5),2.);c=mix(c,mix(cAA,cG1,keyk),pd*esS(.82,.8,pz)*esS(.7,.72,pz)*.8*bf);
#endif
#if HD>=3
        // filigree on the gold ribs and on frames, from the shared footprint-cutoff fold
        if(abs(mat-6.)<.5){float of=orn(vec2(wu,p.z)*1.6,bp*1.6,salt*5.+tier*.3);c=mix(c,mix(cSh*.4,cG2*1.15,mod(floor(wu*2.),2.)),of*.62);}
#endif
      }
      float nf=floor(fract(wu+floor(uP1.z)/6.)*6.)+floor(clamp((zd-.45)/.95,0.,.999)*3.)*6.,gb=mod(floor(256174./exp2(nf)),2.);
      vec3 fcol=mix(cAA,cAB,mod(tier+floor(uM1[0].z),2.));
      c=mix(c,mix(fcol*.9,fcol*.3+cSh*.4,gb)*(1.+1.1*uP5.y+.8*uM1[0].y),fz*.85);
      { // v21 the mason's mark. A standing one: two short lines cut on one frieze stone in a few hundred, too small to read until you push in.
        // A passing one: now and then a narrow banner drops down a tall face somewhere, gilt letters on it, and furls again
        float mh=h21(hcell*1.37+7.7+fx*3.1),fh=h21(hcell*2.71+1.3+fx*5.7),cm=fx>.5?1.-cu:cu;
        float cap=step(1.5,sgC)*step(sgC,2.5),bn=step(sgA,.999)*step(8.8-1.1*cap,H-max(nb,0.))*step(fract(fh*61.+sgC*.37),.045),pq=step(.9955,mh)*step(2.5,H)*(1.-bn);
        if(bn+pq>.5){
          float ps=mix(.024,.068,bn),gx=bn>.5?(cm-.5)/ps+2.5:cm/ps-2.85,gy=(1.12-zd)/ps,l2=step(gy,7.5),ry=(zd-1.55)/ps,ci=floor(ry/8.);
          float un=esS(0.,.22,sgA)*esS(1.,.8,sgA)*(81.+15.*cap),bw=bn*step(abs(gx-2.5),4.3)*step(-1.5,ry)*step(ry,un+1.5);
          float ink=esMk(bn>.5?vec2(ci*6.+gx,7.-(ry-ci*8.)):(l2>.5?vec2(gx+33.,gy):vec2(gx,gy-9.)),cap*bn);
          ink*=bn>.5?step(0.,gx)*step(gx,5.)*step(0.,ry)*step(ry,un)*esS(ps*1.5,ps*.8,bp):step(l2*9.,gx)*step(gx,36.-9.*l2)*esS(ps*1.3,ps*.7,bp);
          c=mix(c,cSt*1.12,pq*step(abs(cu-.5),.485)*step(abs(zd-.93),.25)*esS(ps*1.3,ps*.7,bp));
          c=mix(c,cSh*.5+cAA*.12,bw);c=mix(c,cG1*1.15,bw*max(step(3.5,abs(gx-2.5)),max(step(ry,-.4),step(un+.4,ry))));
          c=mix(c,mix(cSh*.3,cG1*1.6+.2,bn),ink);
        }
      }
      c=mix(c,c*1.4+cG1*.15,esS(.3,.0,zd)*.7);
      c=mix(c,cSh*.3,esS(1.2*bp+.02,.01,zd));
      float inkL=step(lft+.02,p.z)*esS(1.4*bp+.03,.02,cu),inkR=step(rgh+.02,p.z)*esS(1.4*bp+.03,.02,1.-cu);
      c=mix(c,cSh*.3,max(inkL,inkR));
      c*=mix(.5,1.,esS(0.,2.2,zb))*(1.+.45*uM1[0].x*esS(2.,0.,zd));
      c*=1.+.6*max(gBa.x,gBa.y)*esS(4.,.3,zb);                                   // v21 the low end comes up from the street: the foot of every wall glows with it
    }
#if HD>=1
    }
#endif
    // v20 light that moves with the music on every surface: the bass ripple that telescopes each site also runs through it as light; every snare sends a bar
    // of light sweeping the city along a diagonal (the other diagonal on the next snare)
    {vec2 sq2=hcell+.5-(floor((hcell+.5)/48.)+.5)*48.;float rip=esB(length(sq2)/30.);
     float fP=fract(uM1[0].z),dg=(mod(floor(uM1[0].z),2.)>.5?p.x-p.y:p.x+p.y)/56.,sd=fract(dg-fP*1.2)-.5,sw=exp(-sd*sd*700.)*(1.-fP)*(1.-fP);
     float hsp=step(.84,h21(floor(p.xy)+floor(uM1[1].x)*.713))*(1.-fract(uM1[1].x))*top;
     vec2 sd2=floor((hcell+.5)/48.);float hs2=h21(sd2+uSeed.xy*91.);
     c*=1.+esPf(sd2,hs2,max(abs(sd2.x+.5-uP2.x/48.),abs(sd2.y+.5-uP2.y/48.)),step(15.+fract(hs2*17.3)*6.,max(abs(sq2.x),abs(sq2.y))))*(.08+.3*uM1[0].x)*(.4+.6*top);
     c*=1.+(.8*uP5.y+.3*uM1[0].y)*step(.5,fract((tier+floor(p.z*.5)*(1.-top)+floor(uP1.z))*.5));      // v21 every other tier and storey takes the mids and the snare; they trade places each beat
     c*=1.+(.66*rip+.18*uM1[0].x)*top+.3*rip*(1.-top)+.7*sw;c=mix(c,mix(cG2,cG1,.35)*1.25,sw*.5*top);c=mix(c,mix(cG1,cG2,.5)*1.3,hsp*.75);}
    c=mix(c*.55+cSh*.4,c,sh);       // cast shadow
#if HD>=1
    c=mix(c*.7+cSh*.1,c,ao);   // hemisphere occlusion, tinted by the realm's shadow colour
#if HD>=4
    {float hf=ES_M*2.,hp=fract((p.x+p.y+p.z)*hf),hq=fract((p.x-p.y+p.z*.5)*hf);float hl=min(min(hp,1.-hp),min(hq,1.-hq))/hf;
     c=mix(c,c*.45+cSh*.2,(1.-sh)*esS(1.2*bp,.4*bp,hl)*.42*esS(2.5,5.,1./(hf*bp)));}  // cross-hatching in the cast shadows
#endif
#if HD>=2
    if(nRf>0&&cKind<.5&&abs(mat-6.)<.5)c*=mix(1.,.72+.75*dot(rfl,vec3(.3,.5,.2)),.6);   // gold darkens and glints with what it faces, hue kept
#endif
#endif
    acc+=mix(c,fgC.rgb,fgC.a);nS+=1.;                                  // a walker stands in front of whatever the ray went on to find
    if(aaf<.5)break;
  }
  vec3 col=acc/nS;
  col=max(mix(vec3(dot(col,vec3(.299,.587,.114))),col,1.1),0.)*(1.1+.12*(1.-esS(.2,.6,uZoom)));
#if HD>=1
  col=max(mix(vec3(dot(col,vec3(.299,.587,.114))),col,1.05),0.)*1.08;  // occlusion and engraving take light: give it back, keep the chroma
#endif
  fragColor=vec4(col,0.);
}
`;
