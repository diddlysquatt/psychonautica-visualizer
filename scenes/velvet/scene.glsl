const R_VELVET = `
// VELVET. A satin ribbon loom. Two or three families of flat satin ribbons cross with an explicit over/under
// draft (plain, twill, basket, satin, herringbone, diamond, pinwheel, rib, crows-foot, random dobby; or a
// triaxial kagome). Each ribbon is a cupped satin strip: its sheen band rides the over/under undulation, the
// travelling waves and the kick pulses; its face carries grosgrain ribs, an embroidered motif and stitched
// selvages, and a travelling twist shows its reverse side. A reweave pulls every ribbon out with a swallowtail
// end while the new one follows on its heels.
// w4: ONE weave that folds into figures. Chosen crossings are BROKEN: the two bands do not cross, each turns a rounded corner onto the other
// line (the knotwork rule), so a band that arrives along a row leaves along a column; chains of corners are loops, curls and knots, and
// every band of a figure runs on into the cloth. Over-under stays strictly alternating (plain weave under any break pattern).
// Written mostly branch-free (step/mix instead of ?: and &&) because
// ANGLE turns every ternary into an if/else block and the D3D compile time grows with them.
float vBz,vMph,vPr,vAir,vWz,vFP,vIkOn,vIk,vMd,vCw,vIPx,vICut,vTri,vS,vPx,vExt,vGap,vK,vWT,vWA,vWM,vTT,vSl,vHN,vFn,vFf,vLt,vA1,vRing;
vec2 vPp,vFd,vN0,vN1,vN2;int vN3;mat3 vvHM;
vec4 vEsd,vEq;vec3 vEtA,vEtB;float vEc,vEpf,vErh,vEbd,vEsh,vEcp;
// d15: the beat underband's onsets (uO1.zw, uO2.xy: sub, low, low-mid, mid, high-mid, presence)
// v18: vFt = slope of the cloth's drape toward the light (-1..1), vMi = smoothed mids (medallion bloom), vSp = spotlight
vec4 vWc;float vGp,vFt,vMi,vSp,vKn,vWo,vZc,vQt;
// v21: vSt the beat-stepped clock (one eased step in the first half of every beat), vGd the gilding, vLa/vLc the woven label's age and place,
// vEdr the way the top ribbon runs, vCin how tight the snare's sweep pulls the threads here
float vSt,vGd,vLa,vLc,vEdr,vCin;
// w4: vRho the roundness of the corners at a broken crossing (0 a mitred fold, 1 a full quarter circle), vSm the ink along the seam of two
// corners, vHB the break bits in force for the traced light
float vRho,vSm;vec3 vHB;
vec3 vP0,vP1,vP2,vP3,vP4,vQ0,vQ1,vQ2,vQ3,vQ4;
// v19 detail range, per tier: traced light rays, thread levels, carpet levels, brocade levels, pearl rows
#if HD>=5
#define VV_RAYS 14
#define VV_TL 7
#define VV_CL 5
#define VV_DL 5
#define VV_ORN 5
#elif HD>=4
#define VV_RAYS 9
#define VV_TL 6
#define VV_CL 4
#define VV_DL 4
#define VV_ORN 4
#elif HD>=3
#define VV_RAYS 7
#define VV_TL 5
#define VV_CL 4
#define VV_DL 3
#define VV_ORN 3
#elif HD>=2
#define VV_RAYS 6
#define VV_TL 4
#define VV_CL 3
#define VV_DL 3
#define VV_ORN 3
#else
#define VV_RAYS 3
#define VV_TL 3
#define VV_CL 2
#define VV_DL 2
#define VV_ORN 2
#endif
#if HD>=1
#define VV_FK .45
float vVd,vHw,vHg,vHf,vHi;int vZ;   // vZ is a runtime zero: it keeps these loops rolled in HLSL
#else
#define VV_FK 1.
#endif
float vvMod(float x,float n){return x-n*floor((x+.5)/n);}
// v21 the sett: which colour ribbon i of family f carries in generation g. Warp and weft each have their own order of eight (dealt in JS: checks,
// houndstooth, glen, log cabin, pin stripes of metal, tartans, ombre...). 0 in the order is the metal thread
float vvSet(float f,float i,float g){
  float st=mix(mix(uM1[1][1],uM2[1][1],g),floor(mix(uM1[0][0],uM2[0][0],g)*.125),min(f,1.)),d=mod(floor(st/exp2(2.*vvMod(i,8.))),4.);
  return mix(d+4.*step(d,.5),1.+vvMod(f+mod(mix(uM1[1][1],uM2[1][1],g),4.),3.),vTri);
}
// the weaver's label: a 5x7 face, cell by cell (p.x 0..60, p.y 0..7 from the foot); with ms a small cap stands after it
float vvLb(vec2 p,float ms){
  float ok=step(0.,p.x)*step(p.x,71.99)*step(0.,p.y)*step(p.y,6.99);p=clamp(p,vec2(0.),vec2(71.5,6.5));
  float ci=floor(p.x/6.),cx=floor(p.x)-ci*6.,r=6.-floor(p.y);
  vec4 a=step(abs(ci-vec4(0.,1.,2.,3.)),vec4(.5)),b=step(abs(ci-vec4(4.,5.,6.,7.)),vec4(.5)),d=step(abs(ci-vec4(8.,9.,10.,11.)),vec4(.5));
  float g=dot(a,vec4(0.,1.,2.,3.))+dot(b,vec4(4.,5.,-1.,6.))+dot(d,vec4(7.,4.,-1.,8.));
  ok*=step(-.5,g)*step(cx,4.5)*max(step(g,7.5),ms);
  vec4 ga=step(abs(g-vec4(0.,1.,2.,3.)),vec4(.5)),gb=step(abs(g-vec4(4.,5.,6.,7.)),vec4(.5));float gc=step(7.5,g);
  float hi=dot(ga,vec4(508430.,1020036.,476721.,583347.))+dot(gb,vec4(1032734.,1001009.,476735.,1001022.))+gc*491199.;
  float lo=dot(ga,vec4(1086.,4228.,17966.,17969.))+dot(gb,vec4(16927.,17982.,17969.,16912.))+gc*4238.;
  return ok*mod(floor((r<3.5?hi:lo)/exp2((r<3.5?3.-r:6.-r)*5.+4.-cx)),2.);
}
float vvW(float k,float n){return max(0.,1.-abs(k-n));}   // 1 when integer k == n
// eight curated jewel palettes (linear rgb): 0 backing, 1-3 ribbon colours, 4 metal thread
void vvPalSet(float p,out vec3 c0,out vec3 c1,out vec3 c2,out vec3 c3,out vec3 c4){
  vec4 wa=max(1.-abs(p-vec4(0.,1.,2.,3.)),0.),wb=max(1.-abs(p-vec4(4.,5.,6.,7.)),0.);
  c0=mat4x3(0.0029,0.0001,0.0066,0.0001,0.0003,0.0104,0.0017,0,0.0012,0.0012,0.0001,0.0078)*wa+mat4x3(0,0.0008,0.0046,0.0012,0,0,0,0.0008,0.0017,0.0003,0,0.0046)*wb;
  c1=mat4x3(1,0.0029,0.259,0.0046,0.0824,1,0.7519,0.0003,0.0511,0.259,0.009,1)*wa+mat4x3(0,0.5234,0.4535,0.7818,0.0017,0.0055,1,0.0582,0.1166,0,0.0619,0.7227)*wb;
  c2=mat4x3(0,0.5356,0.1636,1,0.2674,0.0055,0.0008,0.0582,0.68,1,0.36,0.0)*wa+mat4x3(0.021,0.017,0.8122,0,0.48,0.3,0,0.68,0.5234,0.86,0,0.3)*wb;
  c3=mat4x3(1,0.5,0.02,0.5605,0.3021,1,0.02,0.78,0.3,0,0.6661,0.5234)*wa+mat4x3(1,0.1573,0.4098,0.42,0.04,1,1,0.5605,0.017,0.15,0.6,0.02)*wb;
  c4=mat4x3(1,0.7519,0.2674,1,0.68,0.28,1,0.5605,0.0915,0.7,0.86,1)*wa+mat4x3(1,0.5605,0.0478,1,0.6253,0.1166,0.8,0.92,1,0.7818,0.8751,1)*wb;
}
vec3 vvPick(float g,float k){
  vec3 w=vec3(vvW(k,1.),vvW(k,2.),vvW(k,3.));float w0=vvW(k,0.),w4=vvW(k,4.);
  return mix(vP0*w0+vP1*w.x+vP2*w.y+vP3*w.z+vP4*w4,vQ0*w0+vQ1*w.x+vQ2*w.y+vQ3*w.z+vQ4*w4,g);
}
// weave draft: an 8x8 bit matrix packed into three 24-bit floats (rows 0-2, 3-5, 6-7), built in JS
float vvBit(vec3 W,float i,float j){
  float r=vvMod(i,8.),c=vvMod(j,8.);
  float wd=dot(W,vec3(step(r,2.5),step(2.5,r)*step(r,5.5),step(5.5,r)));
  return mod(floor(wd/exp2(vvMod(r,3.)*8.+c)),2.);
}
// 1 when family fa's ribbon ia lies over family fb's ribbon ib (fa<fb), including the snare cascade parity
float vvOv(float fa,float ia,float fb,float ib,float g,float tri){
  float wv=mix(uM1[0][1],uM2[0][1],g);
  float rt=abs(step(fb-fa,1.5)-step(.5,wv)*step(wv,1.5)*vvMod(ia+ib,2.)-step(1.5,wv)*vvMod(floor(ia*.5)+floor(ib*.5),2.));
  float r=mix(mix(vvBit(mix(uM1[2],uM2[2],g),ia,ib),vvMod(ia+ib,2.),step(65535.5,wv)),rt,tri);
  vec2 na=mix(vN0,vN1,fa),nb=mix(vN1,vN2,fb-1.);
  float ja=ia+.5*tri*vvW(fa,1.),jb=ib+.5*tri*vvW(fb,1.);
  vec2 xc=vS*vec2(ja*nb.y-jb*na.y,jb*na.x-ja*nb.x)/(na.x*nb.y-na.y*nb.x);
  return abs(r-vvMod(vFn+1.+step(dot(xc,vFd),vFf),2.));
}
struct VR{float i,d,hw,hw0,at,gen,cov,e,tp,v,sl,sp,gr,ft;};
VR vvFam(vec2 p,float f){
  float ang=f*vA1;
  vec2 t=vec2(cos(ang),sin(ang)),n=vec2(-t.y,t.x);
  float a=dot(p,t),pe=dot(p,n);
  float i0=floor(pe/vS+.5);
  VR R;R.e=1e9;R.i=i0;R.d=0.;R.hw=.01;R.hw0=.01;R.at=0.;R.gen=1.;R.cov=0.;R.tp=-1.;R.v=0.;R.sl=0.;R.sp=0.;R.gr=0.;R.ft=0.;
  float fs=1.-2.*vvW(f,1.),po=.5*vTri*vvW(f,1.);
  float wcap=mix(.985,.33,vTri),vwcap=wcap,isv=2./(vS*min(max(uM1[1][0],uM2[1][0])*vWM,wcap));
  for(int k=0;k<3;k++){            // (unrolled by the D3D compiler: cheaper to compile than the rolled loop)
    float i=i0+float(k-1);
    float dir=1.-2.*vvMod(i+f,2.);
    float pc=(i+po)*vS;
    float sp=spec(.03+.92*clamp(.5+pc*.62,0.,1.));
    float al=a*dir;
    // travelling wave, coherent across the family so neighbours ripple together
    float wph=a*vK-vWT*fs+i*.42+f*2.1;
    float amp=vS*vWA*(.65+.35*sp);
    float disp=amp*sin(wph),sl=amp*vK*cos(wph);
    float d=pe-pc-disp;
    // reweave front: the old ribbon is pulled out ahead of it, the new one follows behind; both ends are cut on the bias
    float u=clamp((vTT-abs(pc)*1.15-f*.4)/1.6,0.,1.);u=u*u*(3.-2.*u);
    float E=mix(-vExt,vExt,u);
    float sv=clamp(d*isv,-1.,1.);
    float cut=E-.4*vS*sv;
    float gen=step(al,cut);
    float mk=mix(uM1[0][1],uM2[0][1],gen),ft=step(65535.5,mk)*mod(floor(mk/exp2(mix(8.+vvMod(i,8.),vvMod(-i,8.),min(f,1.)))),2.)*(1.-vTri);
    sp=mix(sp,.55,ft);
    float wsc=vWM*(1.+.11*vRing)*(.93+.14*sp)*(1.-.09*vCin);
    // d15: a beat underband (sub, low, low-mid, mid, high-mid, presence), keyed to the ribbon's position across the loom,
    // makes its own group of ribbons swell and light up on that band's pulse. The spectrum already shades every ribbon
    // continuously; this puts a legible rhythm of width and light on it, band by band, so each one is easy to point at
    float wb=floor(clamp(.5+pc*.62,0.,.999)*6.);float hb=mix(h11(wb*31.7+1.3),.5,ft);
    float pw18=1.+.62*hb*(.5*vWc.x+.42*vWc.y+.3*vWc.z+.24*vWc.w+.16*vWc.z*vWc.w);
    float grn=(1.-hb)*(.22*vWc.z+.18*vWc.w)+hb*(.3*vWc.x+.2*vWc.y)+.1*vWc.w*vWc.z;
    vGp=max(vGp,pw18-1.);
    float hw0=.5*vS*min(mix(uM1[1][0],uM2[1][0],gen)*wsc,vwcap)/pw18;
    float hw=hw0,vv=d/hw;
    float tip=mix(al-cut,cut-al,gen)-.5*vGap;
    float e=max(abs(d)-hw,-tip);
    if(e<R.e){R.e=e;R.i=i;R.d=d;R.hw=hw;R.hw0=hw0;R.at=al-vSl;R.gen=gen;R.tp=-tip;R.v=vv*mix(1.,dir,ft);R.sl=sl;R.sp=sp;R.gr=grn;R.ft=ft;}
  }
  R.cov=clamp(.5-R.e*vIPx*.5,0.,1.);
  return R;
}
// what a ribbon of colour slot s in generation seed gs is embroidered with:
// x medallion family (0 rosette, 1 paisley, 2 kilim diamond, 3 onion ogee, 4 eight-point star, 5 pearl medallion),
// y variant, z border row (0 runes, 1 beads, 2 sequins, 3 kilim zigzag, 4 vine), w stitch (0 satin, 1 cross-stitch, 2 beadwork)
vec4 vvSlot(float gs,float s){
  float h=h11(gs*917.3+s*31.7),h2=fract(h*613.17+s*.37),h3=fract(h*271.93+h2*.5);
  return vec4(floor(h*8.),h2,floor(h3*4.),floor(fract(h3*7.31)*2.6));
}
// embroidery on one tile of a ribbon face. q in [-.5,.5]^2 (x along, y across), X = position along in tiles,
// pw = pixel size in q units. Returns x = metal thread, y = coloured thread, z = dark halo, w = glint / lit glyphs.
// Written for a small D3D instruction count: linear AA ramps, one shared template, no loops.
vec4 vvEmb(vec2 q,vec4 sd,float pw,float X,float rh){
  float sub=sd.y,ip=.5/pw;
  vec4 W=max(1.-abs(sd.x-vec4(0.,1.,2.,3.)),0.),W2=max(1.-abs(sd.x-vec4(4.,5.,6.,7.)),0.);
  vec2 m=q/(1.+.24*vMi*(.6+.4*sin(rh*7.3)));   // v18: mids bloom every medallion, staggered per ribbon
  vec2 a=abs(m);float r=length(m),dia=a.x+a.y;
  // rosettes fold into an 8- or 16-fold wedge; petals sit on the wedge edge or its middle, dots on the other
  vec2 f=vec2(max(a.x,a.y),min(a.x,a.y)),n16=vec2(-.38268,.92388);
  float s16=step(.55,fract(sub*5.3)),kp=step(.35,fract(sub*2.9));
  f-=2.*s16*max(dot(f,n16),0.)*n16;
  vec2 mid=mix(vec2(.92388,.38268),vec2(.98079,.19509),s16),dr=mix(vec2(1.,0.),mid,kp),dd=mix(mid,vec2(1.,0.),kp);
  float pwd=.034+.034*fract(sub*7.1);
  vec2 pe=(vec2(dot(f,dr),f.y*dr.x-f.x*dr.y)-vec2(.12+.03*sub,0.))/vec2(.1+.045*sub,pwd);
  // paisley: a curled teardrop, turned 180 degrees on alternate tiles
  vec2 P=(1.-2.*vvMod(floor(X),2.))*m+vec2(.07,0.);P.y+=(1.6+1.6*sub)*max(P.x,0.)*max(P.x,0.)*(1.-P.x);
  float dS=dot(W,vec4(min((length(pe)-1.)*pwd,r-.065),min(length(P)-.15,max(dot(vec2(P.x-.4,abs(P.y)),vec2(.375,.927)),.056-P.x)),
                      min(dia-.3,max(f.y-.04,f.x-.37)),a.x*.45+a.y-.19))
          +dot(W2,vec4(min(dia*.7071,f.x)-.22,r-.27,length(vec2(f.x-.17,f.y))-.125,min(abs(dia-.27)-.035,max(f.y-.035,f.x-.33))));   // v21: 6 quatrefoil, 7 lozenge and cross
  float dDot=mix(length(f-.235*dd)-.022-.03*W.z,length(P)-.045,W.y);
  // a little symbol between the medallions: a mirrored glyph built from a 3x5 grid of strokes and dots, its own per tile
  vec2 sq=vec2(.65-abs(q.x),q.y)*vec2(18.,13.),si=clamp(floor(sq+.5),vec2(0.,-2.),vec2(1.,2.)),sl=abs(sq-si);
  float hy=h11(floor(X+.5)*1.37+si.x*3.1+si.y*7.7+sub*17.);
  float dSym=(mix(mix(max(sl.y-.2,sl.x-.5),max(sl.x-.2,sl.y-.5),step(.4,hy)),length(sl)-.3,step(.75,hy))+step(.9,hy)*9.)/15.;
  // the template: outline, inner outline, then a fill of satin, nested contours or seed beads
  float lw=.021,sp=.042,ft=fract(sub*11.);
  float dF=max(dS+2.*sp,step(.45,ft)*(abs(fract(dS/sp*1.25)-.5)-.2)*sp*.8);
  float dA=min(abs(dS)-lw,dDot),dB=min(min(abs(dS+sp)-lw*.7,dF),dSym);
  vec2 dM=mix(vec2(dA,dB),vec2(dB,dA),step(.6,fract(sub*13.)));
  float lodM=clamp(2.-pw*33.,0.,1.);
  vec4 m0=vec4(clamp(.5-dM*ip,0.,1.),clamp(1.-min(dM.x,dM.y)/(pw*2.+.025),0.,1.),0.)*lodM;
  // v20: bullion. Every stitched stroke is a raised cord: dark where it rolls under at its edges, bright along its crown
  {float pA=clamp(-min(dM.x,dM.y)/lw,0.,1.),lodC=clamp(lw/pw*.33-.6,0.,1.)*max(m0.x,m0.y);
   vEcp=mix(1.,(.6+.62*pA)*(1.+.7*pA*pA*pA*vEbd),lodC);}
  // ---- border rows between the medallions and the selvages, ten cells per tile
  vec3 B=max(1.-abs(sd.z-vec3(0.,1.,2.)),0.);
  float cid=floor(X*13.),hv=h11(cid*.61803+step(0.,q.y)*17.3+rh*131.);
  vec2 lb=vec2(fract(X*13.)-.5,(abs(q.y)-.375)*10.);
  // code row: a random telegraph of dashes and dots
  float dRun=mix(max(abs(lb.x)-.32,abs(lb.y)-.11),length(lb)-.17,step(.45,hv));
  float yw=.3*(abs(fract(X*6.5)-.5)*4.-1.);
  float dL=B.x*dRun+(B.y+B.z)*(abs(length(lb)-.3*B.z)-.36+.24*B.z)
          +(1.-B.x-B.y-B.z)*(abs(lb.y-yw)*.8-.07);
  float lodL=clamp(2.-pw*20.,0.,1.),lbG=0.;
  { // v21 the weaver's label, woven into the bead row: a standing one on one tile in several hundred, two and a half beads long, and a passing one,
    // five beads long, that a few tiles carry for a moment in bright thread
    float th=h11(floor(X)*7.13+rh*91.7),hid=step(.9972,th),fl=step(fract(th*61.+vLc*.37),.05)*smoothstep(0.,.15,vLa)*smoothstep(1.,.75,vLa)*(1.-hid);
    float n=mix(5.,2.5,hid),u=mix(10.-fract(X)*13.,fract(X)*13.-4.,step(0.,vEdr))/n,tv=.5+lb.y*1.1,on=max(hid,fl)*step(0.,q.y)*step(0.,u)*step(u,1.2)*step(abs(lb.y),.5);
    float ink=vvLb(vec2(u*60.,tv*7.),hid*step(.5,fract(th*977.)))*clamp(1.6-pw*n*13.,0.,1.);
    dL=mix(dL,.5-ink,on);lbG=ink*on*fl;
  }
  float cL=clamp(.5-dL*ip*.1,0.,1.)*step(abs(lb.y),.5)*lodL;
  // runes light with the vocal range, beads twinkle on the hi-mids, sequins catch the highs and the hats
  float glint=cL*step(h11(hv*97.+vHN),dot(B,vec3(.85*uB2.y,.1+.5*uB2.x,.12+.45*uB2.z))+.35*uHat)*(.4+1.4*uB2.z+uO2.y+2.5*max(uO2.z,uO2.w)+2.*uHat);glint=max(glint,lbG*cL*1.3);
  float alt=mix(1.,vvMod(cid,2.),B.y+B.z);
  // couched metal selvage: a gold thread tied down with coloured stitches
  float ys=abs(abs(q.y)-.455);
  vec2 cS=clamp(.5-vec2(ys-.011,max(ys-.03,abs(fract(X*21.)-.5)*.0625-.006))*ip,0.,1.);
  cS*=clamp(2.2-pw*18.,0.,1.);
  vec4 o=vec4(max(cL*vec2(alt,1.-alt),cS),clamp(1.-dL/(pw*20.+.25),0.,1.)*lodL*.6,glint);
#if HD>=1
  // v19 detail range: seed-pearl rows follow the medallion outline, one more row per tier, each row finer; from Cinema up a diaper of
  // tiny stitches fills the medallion
  {float th=atan(m.y,m.x),R0=.26,pr=0.;
   for(int k=vZ;k<vZ+VV_ORN;k++){float kf=float(k-vZ),of=.034+.03*kf,sz=.0095*pow(.82,kf);if(sz<pw*1.1)break;
    float cl=(fract(th*R0/(sz*3.2)+.25*kf)-.5)*sz*3.2*(max(r,.02)/R0),dp2=length(vec2(dS+of,cl))-sz;pr=max(pr,clamp(.5-dp2/pw,0.,1.)*lodM);}
   o.x=max(o.x,pr);
   // each tier adds a whole order of ornament at a size that reads at normal viewing: Native a couched diamond lattice over the plain field
   {float lod=clamp(2.-pw*44.,0.,1.),inF=step(.018,dS)*step(abs(q.y),.355);
    float pt=.111;vec2 lg=vec2(X*1.3+q.y,X*1.3-q.y)/pt,ld=abs(fract(lg)-.5)*pt;
    float dsh=smoothstep(.1,.22,abs(fract(ld.x<ld.y?lg.y*3.:lg.x*3.)-.5));   // couched in short coloured stitches, not a solid net
    o.y=max(o.y,clamp(.5-(min(ld.x,ld.y)-.0036)/pw,0.,1.)*inF*lod*dsh*.82);
#if HD>=2
    // Cinema: a ring of embroidered leaves inside every medallion
    {vec2 lfq=(f-vec2(.165,0.))*vec2(1.,2.5);float lf=length(lfq)-.05;o.y=max(o.y,step(dS,-.018)*clamp(.5-lf/pw,0.,1.)*lodM);o.x=max(o.x,step(dS,-.018)*clamp(.5-(abs(lf)-.006)/pw,0.,1.)*lodM);}
#endif
#if HD>=3
    // Insane: a running vine with paired leaves down both sides of the ribbon, inside the border rows
    {float vy=abs(q.y)-.3,wv=.022*sin(X*TAU*2.+rh*3.),dv=abs(vy-wv)-.0048,lc=fract(X*9.);
     float lfd=length(vec2((lc-.5)*.111,(vy-wv-.018*sign(sin(X*TAU*9.)))*1.1))-.016;
     o.y=max(o.y,clamp(.5-min(dv,lfd)/pw,0.,1.)*step(abs(q.y),.355)*step(.02,dS)*lod);}
#endif
#if HD>=4
    // Extreme: little star flowers at every lattice crossing, each with a bright centre
    {vec2 sc=(fract(lg+.5)-.5)*pt;float ac=atan(sc.y,sc.x),rs=length(sc),st=rs-.0125-.005*cos(ac*4.);
     o.y=max(o.y,clamp(.5-st/pw,0.,1.)*inF*lod);o.x=max(o.x,clamp(.5-(rs-.0052)/pw,0.,1.)*inF*lod);}
#endif
#if HD>=5
    // Offline: a seed-pearl trim on both selvages, every pearl with its own highlight
    {float py=abs(abs(q.y)-.442),pc=(fract(X*34.)-.5)/34.*1.3,pd=length(vec2(pc,py))-.011;o.x=max(o.x,clamp(.5-pd/pw,0.,1.)*clamp(2.-pw*60.,0.,1.));
     o.w=max(o.w,step(length(vec2(pc-.0035,py-.0035)),.0035)*.9);}
#endif
   }
#if HD>=2
   {float pz=.022;if(pz*.5>pw){float dd=abs(fract((m.x+m.y)/pz)-.5)*pz,de=abs(fract((m.x-m.y)/pz)-.5)*pz;
     o.y=max(o.y,step(dS,-.05)*clamp(.5-(min(dd,de)-.0028)/pw,0.,1.)*lodM*.7);}}
#endif
  }
#endif
  return vec4(max(o.xyz,m0.xyz),o.w);
}
float tilt0(float sl,float hy){float ty=(sl+vS*.13*hy+.55*vFt)*2.2;return ty*inversesqrt(1.+ty*ty)*1.3;}
vec3 vvShade(VR r,float f,vec2 hd,float tri){
  float g=r.gen,i=r.i;
  vec3 M0=mix(uM1[0],uM2[0],g),M1=mix(uM1[1],uM2[1],g);   // (pal, weave, motif), (width, colour sequence, thread)
  float slot=vvSet(f,i,g),ir=i,fk=f*(1.-r.ft);
  i=mix(i,40.+slot,r.ft);   // w4: a feature band is one band through every corner: its hashes come from its colour, not from the line it lies on
  vec3 C=vvPick(g,slot),metal=vvPick(g,4.);
  vec3 ec=vvPick(g,vvMod(slot+1.,3.)+1.);
  // w4: a feature band is space-dyed: long reaches of it are dipped in the palette's next colour (slow ombre stripes on the bias of the cloth, so the dye runs
  // unbroken round every corner and a figure of one band still shows two colours)
  {vec2 dq=vPp*(.55/vS);float dy=sin(dq.x*.9+dq.y*.43+slot*2.);
   C=mix(C,vvPick(g,vvMod(slot+1.,3.)+1.),r.ft*smoothstep(.1,.8,dy)*.8);ec=mix(ec,vvPick(g,vvMod(slot,3.)+1.),r.ft*smoothstep(.1,.8,dy));}
  C=mix(C,ec,clamp(vFt*1.5-.25,0.,.62));   // v18: shot silk
  // ikat: a giant figure dyed into the ribbons before weaving. Its edge is feathered thread by thread (stepped across
  // the ribbon, smeared along it) the way resist-dyed warps shift on the loom; it reads best zoomed far out
  // v13: finer threads (7 per ribbon), half the step, and a continuous (triangle) smear along the ribbon: the old saw
  // tooth and 3.5 coarse threads left hard-edged stepped blocks that read as pixel patches
  float hth=h11(floor(r.v*7.)+i*1.7+fk*5.3),ifw=1./(1.5*vPx);
  // d15: slub. Resist-dyed yarn is thick and thin, so the dye front itself wanders: a slow smooth wobble along the
  // ribbon, plus an occasional fat slub pulled in from the side. It turns the hard stair-steps of the ikat (still the
  // bane of some draws at zoom 1) into soft, organic thread edges, at zero compile cost (the clip below is reused)
  float slb=sin(r.at*1.3+i*2.1+fk*.7)*.55+sin(r.at*.41-i*1.9)*.45;
  float slk=step(.8,h11(floor(r.at/(vS*.6))+i*3.7+fk*11.))*(h11(floor(r.at/(vS*.6))+i*9.1)*.6+.6);
  float ife=(r.v>.4?-slk:.15*slk)+.0035*slb+.004*(hth-.5);
  C=mix(C,ec*.92+metal*.06,clamp(.5-(vIk+ife+(1.-vWz)*(.03*(hth-.5)+.03*abs(fract(r.at/(vS*.9)+hth*7.)*2.-1.)))*vFP*.5*ifw,0.,1.)*vIkOn);
  // v21 the pattern on every ribbon steps along it on the beat: a quarter or half a tile a beat, some one way, some the other, some not at all
  float stp=h11(i*5.71+fk*3.3+.4),dirn=1.-2.*vvMod(ir+f,2.);
  float tile=mix(2.6*r.hw0,vS/sin(vA1),r.ft),X=r.at/tile+vSt*floor(stp*4.-1.)*.25,tu=fract(X)-.5,pw=vPx/(2.*r.hw);
  // v20: damask. The ribbon's ground is a jacquard figure in its own colour: figure and ground are opposite satins, so they
  // trade light and dark as the sheen band crosses them. Three figure families, dealt per colour slot
  {float dh=h11(M0.z*3.7+slot*5.3+fk*1.9),s1=1.25*step(.5,dh),s2=.25+.4*fract(dh*7.3);
   vec2 da=vec2(X*TAU*2.,r.v*PI*1.5);
   float F=cos(da.x+s1*sin(da.y))*cos(da.y)-s2*cos(2.*da.x)*cos(2.*da.y)+.12,aw=14.*pw;
   float fig=clamp(.5+F/aw,0.,1.),ln=clamp(1.-(abs(fract(F*2.5+.5)-.5)*.4-.028)/aw,0.,1.)*clamp(.05/pw-1.,0.,1.)*(.35+.65*fig);
   float dl=clamp(.083/pw-1.,0.,1.)*smoothstep(.74,.6,abs(r.v));
   float xb=tilt0(r.sl,hd.y),flp=clamp(exp(-(xb-vLt)*(xb-vLt)*9.)*1.5,0.,1.),tone=mix(fig,1.-fig,flp);
#if HD>=1
   // detail range: the two satins show their floats (fine twill lines, opposite hands in figure and ground); from Cinema a second,
   // smaller figure is woven into the ground; from Extreme a third
   {float hN=34.,hf=clamp((1./(hN*pw*2.)-1.2)/1.6,0.,1.),hs=abs(fract((X*2.6+mix(-r.v,r.v,fig))*hN*.5)-.5)*2.;
    tone+=(hs-.5)*.42*hf;}
#if HD>=2
   {vec2 d2=da*3.;float F2=cos(d2.x)*cos(d2.y)-.4*cos(2.*d2.x+d2.y),f2=clamp(.5+F2/(aw*3.),0.,1.),l2=clamp(.028/pw-1.,0.,1.);
    tone+=(f2-.5)*.34*l2*(1.-fig);ln+=clamp(1.-(abs(F2-.3)-.06)/(aw*3.),0.,1.)*.5*l2*(1.-fig);}
#endif
#if HD>=4
   {vec2 d3=da*9.;float F3=cos(d3.x+sin(d3.y))*cos(d3.y),l3=clamp(.0093/pw-1.,0.,1.);tone+=(clamp(.5+F3/(aw*9.),0.,1.)-.5)*.3*l3*fig;}
#endif
#endif
   C*=mix(1.,mix(.74-.3*vAir,1.2+.46*vAir,tone)+.3*ln,dl);}
  // v20: an ink line shadows the carpet's couched gold on both sides, so the great figure stays drawn at every distance
  C*=1.-.62*clamp(.5-(vMd+ife-.008-1.5*vPx/vFP)*vFP*.5*ifw,0.,1.);
  C=mix(C,metal*(.8+.3*hth)*(1.+1.1*vRing*vWz),clamp(.5-(vMd+ife*(1.-.8*vZc)+.02*(hth-.5)*(1.-vWz)*(1.-.85*vZc))*vFP*.5*ifw,0.,1.)*.9);
  float v=clamp(r.v,-1.,1.);
  float tilt=tilt0(r.sl,hd.y);   // a cheap atan
  float band=exp(-(tilt-vLt)*(tilt-vLt)*22.);
  float broad=.5+.5*cos(tilt*1.7-vLt);
  float cup=1.-.6*v*v*v*v;
  float xs=v-.35,xh=exp(-xs*xs*2.6);
  // shadows deepen in saturation instead of greying (keeps gold from turning olive)
  vec3 Ce=mix(mix(C*C,C,.42),C,clamp(broad*cup*1.8-.1,0.,1.));
  // v22: the satin's own light is modest and its lights are contrast, not a stack: the body sits deep, only the sheen band and the pulses climb
  vec3 col=Ce*(.13+.55*broad*cup+.22*(1.+.8*hd.x))*(.7+.5*r.sp)*(1.+(3.8+.9*vZc)*vRing)*(1.+1.5*uB1.x+.25*uB1.y+.35*vPr+.42*uKick);
  // v19: the pile. Velvet is brightest where the light grazes it, so the turned-away side glows in its own colour, crushed by hand
  float pl0=1.-broad*cup,crs=vnoise(vPp/vS*1.9+vec2(i*3.1,fk*7.7));
  col+=C*pl0*pl0*(.12+.1*r.sp+.16*crs*crs)*(.7+.6*cup);
  float gl=1.+2.4*uHat+.5*vZc*vAir;   // v13: hats sweep the satin sheen harder
  float streak=band*(.25+1.1*xh)*cup*(1.+.35*uDrop+.5*uB1.z)*(1.-.8*vWz);
  // v22: the core of the sheen is the ribbon's own hue at full strength with a breath of the metal thread, never white
  vec3 Ch=mix(C/max(max(C.r,max(C.g,C.b)),.05),metal,.2);
  col+=gl*streak*(C*(1.2+.5*uBuild)+Ch*streak*xh*.7*(1.-vWz));
  col*=1.+2.3*r.gr;
  col=mix(col,mix(metal,metal*metal,.6)*(.3+.75*broad*cup)*(1.+1.6*vRing+.9*r.gr+.5*vPr+.8*uHat+.5*vAir+.5*uKick),r.ft*clamp(.5+(.055-abs(abs(v)-.7))/(2.*pw),0.,1.)*.92);   // d15: this ribbon's band pulse lights it
  // the embroidery is drawn once, after the layer loop, for the top layer only: remember its inputs here
  float lit=(.35+1.7*band+.5*xh+.5*broad)*(1.+.6*vRing);
  // v21 colour runs through the weave on the beat: a length of each ribbon takes its neighbour colour and moves on one pitch a beat
  {float rn=abs(fract(r.at/(vS*8.)-vSt*.125*dirn+stp*5.)-.5),rw=.05+.15*vMi,run=smoothstep(rw+.025,rw,rn)*(.35+.4*vMi+.5*smoothstep(.2,.9,r.sp+uKick));   // the mids pay out more of it
   col=mix(col,(ec*1.25+metal*.2)*(.45+.6*broad*cup),run*.7*(1.-r.ft));}
  vEq=vec4(tu*1.3,v*.5,X,pw);vEsd=vvSlot(M0.z,slot+7.*vvMod(floor(X),2.)*(1.-r.ft));vErh=i*.37+fk*5.1;vEbd=band;vEdr=dirn;   // v21: odd tiles carry a motif of their own
  vEtA=metal*lit*(.66+.6*uB1.w+.5*vMi+.8*vPr);vEtB=mix(ec,metal,vGd)*lit*(.7+1.7*vPr+.6*vMi);
  // the fold crease of a twist, the shadowed bias cut at a ribbon end and the rolled-off edges
  vEpf=(1.-clamp(abs(v)*2.3-1.8,0.,.5))*(.45+.55*clamp(-r.tp*vICut,0.,1.));
  col*=vEpf*(1.-.7*smoothstep(.8,1.,abs(v)))*.57*mix(1.,mix(mix(.64,.48,vWz),1.1,r.ft),step(65535.5,M0.y));   // w4: under a figure the ground bands sit a little deeper than the bands that tie it
  return col;
}
// undulation: raised (+1) where this ribbon passes over family g's nearest ribbon, sunk (-1) where under,
// easing to 0 halfway between crossings; y = slope along this ribbon (for the sheen)
vec2 vvUnd(VR g,float s0,float rate){
  float t=clamp(abs(g.d)/(.5*vS),0.,1.),a=s0*2.-1.;
  return vec2(a*(.5+.5*cos(PI*t)),a*.5*PI*sin(PI*t)*sign(g.d)*rate/(.5*vS));
}
float vvShd(VR r,vec2 off,vec2 n,float sw,float k){
  float es=max(abs(r.d+dot(off,n))-r.hw,r.tp);
  return 1.-k*clamp((sw-es)/(1.3*sw),0.,1.);
}
// w4: one broken crossing. u = offset from the column's centre line toward +t0, v = offset from the row's centre line, already mirrored by the
// crossing's parity so that the two corners are (west arm to north arm) and its point mirror. Returns x = signed distance to the band's centre
// line (a rounded L, positive on the outside of the turn), y = how far along the corner (0 at the row's end of the cell, 1 at the column's),
// z = distance to the seam between the two corners, w = 1 when the pixel belongs to the mirrored corner
vec4 vvKn(float u,float v){
  float fl=step(v,u);u=mix(u,-u,fl);v=mix(v,-v,fl);
  float hS=.5*vS,rr=hS*vRho;vec2 q=vec2(u+rr,rr-v);
  float dL=length(max(q,0.))+min(max(q.x,q.y),0.)-rr;
  float s=min(u,-rr)+hS+rr*atan(max(q.x,0.),max(q.y,1e-5))+max(v-rr,0.);
  return vec4(dL,clamp(s/(2.*hS-.4292*rr),0.,1.),(v-u)*.7071,fl);
}
#if HD>=1
// ---- v19 detail range: the real weave as a height field, so light can be traced across it ----
// nearest ribbon of family f at p: signed edge distance, its index and its offset across the ribbon
float vvLite(vec2 p,float f,out float ii,out float dd){
  vec2 n=mix(vN0,vN1,clamp(f,0.,1.));if(f>1.5)n=vN2;
  float a=dot(p,vec2(n.y,-n.x)),pe=dot(p,n),i0=floor(pe/vS+.5),fs=1.-2.*vvW(f,1.),po=.5*vTri*vvW(f,1.),best=1e9;ii=i0;dd=0.;
  for(int k=vZ;k<vZ+3;k++){
    float i=i0+float(k-vZ-1),pc=(i+po)*vS,d=pe-pc-vS*vWA*.88*sin(a*vK-vWT*fs+i*.42+f*2.1),e=abs(d)-vHw;
    if(e<best){best=e;ii=i;dd=d;}
  }
  return best;
}
// top of the weave at p (0 = the backing): over/under from the draft, undulation at the crossings; vHf/vHi name the ribbon on top
float vvHgt(vec2 q){
  float i0,d0,i1,d1,i2=0.,d2=0.,e2=1e9;
  float e0=vvLite(q,0.,i0,d0),e1=vvLite(q,1.,i1,d1);
  if(vTri>.5)e2=vvLite(q,2.,i2,d2);
  if(vvBit(vHB,-i1,i0)>.5){e0=abs(vvKn(-d1,(2.*vvMod(i0+i1,2.)-1.)*d0).x)-vHw;e1=1e9;d0=vS;d1=vS;}   // w4: a broken crossing is one flat corner
  float o=vvOv(0.,i0,1.,i1,vHg,vTri);
  float u0=(2.*o-1.)*(.5+.5*cos(PI*clamp(abs(d1)/(.5*vS),0.,1.))),u1=(1.-2.*o)*(.5+.5*cos(PI*clamp(abs(d0)/(.5*vS),0.,1.)));
  float z0=step(e0,0.)*(.5+.45*u0),z1=step(e1,0.)*(.5+.45*u1),z2=step(e2,0.)*.62,z=max(z0,max(z1,z2));
  vHf=0.;vHi=i0;
  if(z1>z0&&z1>=z2){vHf=1.;vHi=i1;}
  if(z2>z0&&z2>z1){vHf=2.;vHi=i2;}
  return z;
}
vec3 vvRibC(float f,float i,float g){
  return vvPick(g,vvSet(f,i,g));
}
#endif
// v20: needle lace across a hole. hq = hole-centred position in hole radii, Ns spokes, pwL = pixel size in the same units.
// Returns the distance to the cords; dBd = distance to the beads, id = (spoke, web ring), rt = (radius, angle)
float vvLace(vec2 hq,float Ns,float pwL,out float dBd,out vec2 id,out vec2 rt){
  float rr=length(hq),th=atan(hq.y,hq.x),si=floor(th*Ns/TAU+.5),sa=th-si*TAU/Ns;
  float dSp=max(abs(sa)*rr-.02,.2-rr);
  float sag=.06*cos(th*Ns),rk=(rr-.5-sag)/.27,ki=max(floor(rk+.5),0.),wg=clamp(1.+3.5*uB2.x+2.*uO2.x-ki,0.,1.);
  float dW=abs(rk-ki)*.27-.017+(1.-wg)*.05;
  float Np=Ns*.5,tp=th+vMph*TAU/Np,pa=tp-floor(tp*Np/TAU+.5)*TAU/Np;
  float dPt=abs(length(vec2((rr-.25)/.16,pa*rr/.085))-1.)*.085-.014,dBs=abs(rr-.07)-.022;
  float dLc=min(min(dSp,dW),min(dPt,dBs));
  vec2 bq=vec2(sa*rr,(rk-ki)*.27-.06*(1.-cos(sa*Ns)));dBd=length(bq)-.05*wg;
#if HD>=1
  // detail range: Native twists every cord and adds a hair-fine cobweb between the webs; Cinema a second spoke set; Insane
  // seed beads strung along the spokes; Extreme picots on every web
  {float cb=abs(fract(rk*3.+.5)-.5)*.09-.003+.04*(step(rk,-.4)+step(2.6,rk));dLc=min(dLc,cb+clamp(pwL*40.-.4,0.,1.)*.05);}
#if HD>=2
  {float s2=th-(floor(th*Ns/TAU)+.5)*TAU/Ns;dLc=min(dLc,max(abs(s2)*rr-.009,.66-rr));}
#endif
#if HD>=3
  {float bs=length(vec2(sa*rr,(fract(rr*9.)-.5)/9.))-.026;dBd=min(dBd,max(bs,.3-rr)+clamp(pwL*30.-.5,0.,1.)*.05);}
#endif
#if HD>=4
  {float pk=abs(length(vec2((fract(th*Ns*3./TAU)-.5)*TAU/(Ns*3.)*rr,(rk-ki)*.27-.035))-.022)-.006;dLc=min(dLc,pk+(1.-wg)*.05+clamp(pwL*50.-.5,0.,1.)*.05);}
#endif
#endif
  id=vec2(si,ki);rt=vec2(rr,th);
  return dLc;
}
void realm(){
  // loop counts come from a uniform so the D3D compiler keeps the loops rolled (fast first compile)
  vN3=3+int(step(1e9,uDetail));
  vec2 sc=scr(),p=sc/uZoom;
  vPx=1./(uRes.y*uZoom);   // v19: close up, the beat lights push harder
#if HD>=1
  vZ=int(step(1e9,uDetail));vVd=clamp(uDetail,1.,16.);
#endif
  float lay=floor(uP1.w);
  vS=uP1.x;{float zq=uZoom*vS/.26;vWz=smoothstep(.5,.15,zq);vZc=smoothstep(1.,2.5,zq);}   // w4: the far-view simplification follows the size of a band on screen
  vA1=mix(PI/3.,PI*.5,fract(uP1.w)/.9);float tri=vvW(lay,2.);vTri=tri;      // v21: the angle between the families is live (the loom can shear)
  vSt=uP5.w;vGd=fract(uP4.w)/.99;vLa=mod(floor(uP4.w*.5),64.)/63.;vLc=floor(uP4.w/128.);vEdr=1.;
  // a focal point drifts with the bars (light pool and kick ring, in screen space: the loom itself stays flat)
  vec2 lq=sc-(vec2(mod(uP1.z,4096.),floor(uP1.z/4096.))/4095.-.5);float lr2=dot(lq,lq);
  // kick: a ring of swelling, brightening ribbons runs out from the focal point
  float lr=sqrt(lr2);
  float re1=exp(-(lr-uP3.x)*(lr-uP3.x)*30.),re2=exp(-(lr-uP3.z)*(lr-uP3.z)*30.);
  vRing=uP3.y*re1+uP3.w*re2;
  // v18: the kick ring also shoves the cloth outward as it runs (eased in over the ring's first ~70 ms: geometry never snaps)
  p-=lq*inversesqrt(lr2+.012)*(.017/uZoom)*(uP3.y*re1*smoothstep(0.,.45,uP3.x)+uP3.w*re2*smoothstep(0.,.45,uP3.z));   // v21: less than half the shove, eased in longer
  vN0=vec2(0.,1.);vN1=vec2(-sin(vA1),cos(vA1));vN2=vec2(-sin(2.*vA1),cos(2.*vA1));
  vQt=floor(uP1.y*.1)/99.;p=rot(-mod(uP1.y,10.))*p;   // v20: p1.y also carries the quiet fill (slow, 0 in loud music)
  // v18: the drape. Two sets of long folds travel across the loom and the smoothed bass lifts them, so the whole cloth
  // billows on the low end; p slides along the fold slope (the weave really bends) and the slope lights the satin below
  float bzS=floor(mod(uP4.x*.5,1000.))/999.;vKn=floor(uP4.x/2000.);
  float dra=uSeed.y*TAU,drp=.45+1.1*fract(uSeed.z*7.3);
  vec2 d1=vec2(cos(dra),sin(dra))*5.03,d2=vec2(cos(dra+drp),sin(dra+drp))*7.85;
  float ph1=dot(p,d1)+uMT*.2+uSeed.x*9.,ph2=dot(p,d2)-uMT*.14+uSeed.w*9.;
  vec2 gF=.62*cos(ph1)*d1/5.03+.38*cos(ph2)*d2/7.85;
  float dAmp=(.008+.036*bzS)*(1.-.8*vWz),hF=.62*sin(ph1)+.38*sin(ph2);
  p+=gF*dAmp*(1.+.25*hF);
  vPx*=1.+dAmp*(3.1*abs(cos(ph1))+3.*abs(cos(ph2)));
  vFt=clamp(dot(gF,normalize(vec2(.62,.78)))*1.45,-1.,1.)*(.42+.58*bzS)*(1.-.45*vWz);
  vPp=p;
  vSl=uP2.x;vWT=uP2.y;vWA=uP2.z;
  vWM=1.+mod(uP2.w,256.)/255.*.12;
  vFn=mod(uP4.x,2.);
  vTT=uP5.x;vHN=floor(uP5.y);vLt=.32*sin(uMT*.11)+.14*sin(uMT*.29+1.);
  // d15: the beat underband (onsets only, so nothing dims between beats)
  vWc=vec4(uO1.z,uO1.w,uO2.x,uO2.y);
  // v12: smoothed bass (geometry: the carpet medallions breathe), the mid-driven turn of the carpet petals, and the
  // vocal-range / air light terms (envelopes + onsets)
  vBz=bzS;vMph=fract(uP5.y);vSp=fract(uP4.z)/.999;vMi=floor(uP4.z)/255.;
  vPr=.5*(uB2.x+uB2.y)+.9*max(uO2.x,uO2.y);vAir=.5*(uB2.z+uB2.w)+.8*max(uO2.z,uO2.w)+1.1*uHat;
  vExt=1.25/min(uZoom,1.)+vS;
  vFd=normalize(vec2(1.,.62))*(1.-2.*vFn);vFf=mix(-1.25,1.25,uP4.y)/min(uZoom,1.);
  {float cf=dot(p,vFd)-vFf;vCin=exp(-cf*cf*30.)*(1.-uP4.y*uP4.y);}
  vRho=clamp(uP5.z-.35*vCin,0.,1.);   // w4: the corners are drawn tight where the snare's sweep passes                      // v21 the threads pull tight where the snare's sweep is passing
  vGap=vS*.3;vIPx=1./vPx;vICut=11.1/vS;vK=TAU/(vS*5.3);
  // global hue drift: a small rotation about the grey axis, applied to the curated palettes
  {float h=.12*sin(uHue*TAU),co=cos(h),si=sin(h),k=(1.-co)/3.,q=si*.57735;
   vvHM=mat3(co+k,k+q,k-q, k-q,co+k,k+q, k+q,k-q,co+k);}
  vvPalSet(mod(uM1[0][0],8.),vP0,vP1,vP2,vP3,vP4);vvPalSet(mod(uM2[0][0],8.),vQ0,vQ1,vQ2,vQ3,vQ4);
  vP4*=mix(vec3(1.),vP4*vP4*.9,step(.6,min(vP4.r,min(vP4.g,vP4.b))));vQ4*=mix(vec3(1.),vQ4*vQ4*.9,step(.6,min(vQ4.r,min(vQ4.g,vQ4.b))));   // v22: silver is steel, never white   // old and new generation palettes
  VR r0,r1,r2;
  vGp=0.;vEc=0.;vEq=vec4(0.,0.,0.,1.);vEsd=vec4(0.);vEtA=vec3(0.);vEtB=vEtA;vEpf=1.;vErh=0.;vEbd=0.;vEsh=1.;vEcp=1.;
  int nF=2+int(tri);
  r0=vvFam(p,0.);r1=vvFam(p,1.);r2=r1;
  if(nF>2)r2=vvFam(p,2.);
  if(nF<3){r2=r1;r2.cov=0.;r2.e=1e9;r2.tp=1e9;}
  // w4: THE KNOT. Where this crossing is broken the row and the column do not cross: the pixel belongs to one of two rounded corners, each one
  // band that arrives on the row and leaves on the column. Built from the two ribbons' own offsets, so it rides every wave and ripple of the cloth
  vSm=1.;float bkc=0.;
  {float g=max(r0.gen,r1.gen);
   bkc=step(65535.5,mix(uM1[0][1],uM2[0][1],g))*vvBit(mix(uM1[2],uM2[2],g),-r1.i,r0.i)*(1.-tri);
   if(bkc>.5){
    float d0=1.-2.*vvMod(r0.i,2.),sv=2.*vvMod(r0.i+r1.i,2.)-1.;
    vec4 kn=vvKn(-r1.d,sv*r0.d);
    float su=1.-2.*kn.w;sv*=su;
    float w=kn.y,eta=d0*su,isa=1./sin(vA1),T=vS*isa,hS=.5*vS;
    // along the band: the row's own measure at its end of the cell, the column's at the other, one pitch of pattern in between
    float A0=r0.at+eta*(su*r1.d-hS)*isa,dl=r1.at+eta*(hS-sv*r0.d)*isa-eta*T-A0;dl-=T*floor(dl/T+.5);
    VR L=r0;
    L.at=A0+eta*w*T+w*dl;
    L.hw0=mix(r0.hw0,r1.hw0,w);L.hw=mix(r0.hw,r1.hw,w)*(1.-.7*vRho*w*(1.-w));   // the ribbon gathers a little where it turns
    L.d=-sv*kn.x;L.v=d0*L.d/L.hw;
    L.tp=max(r0.tp,r1.tp);L.e=max(abs(kn.x)-L.hw,L.tp);L.cov=clamp(.5-L.e*vIPx*.5,0.,1.);
    L.sl=mix(r0.sl,r1.sl,w);L.sp=mix(r0.sp,r1.sp,w);L.gr=mix(r0.gr,r1.gr,w);L.gen=g;L.ft=1.;
    r0=L;r1.cov=0.;r1.e=1e9;r1.tp=1e9;
    vSm=.22+.78*clamp(kn.z/(.035*vS+1.5*vPx),0.,1.);   // ink where the two corners lie against each other
   }}
  // over/under at this pixel's crossings and the neighbouring crossings (for the undulation), per family pair
  float o01=1.,o02=1.,o12=1.;
  vec2 h0=vec2(0.),h1=vec2(0.),h2=vec2(0.);
  {float o=vvOv(0.,r0.i,1.,r1.i,max(r0.gen,r1.gen),tri),rt=sin(vA1);
   o01=o;h1+=vvUnd(r0,1.-o,rt)*(1.-bkc);h0+=vvUnd(r1,o,-rt)*(1.-bkc);}
  if(tri>.5){float o=vvOv(0.,r0.i,2.,r2.i,max(r0.gen,r2.gen),tri),rt=sin(2.*vA1);
   o02=o;h2+=vvUnd(r0,1.-o,rt);h0+=vvUnd(r2,o,-rt);
   o=vvOv(1.,r1.i,2.,r2.i,max(r1.gen,r2.gen),tri);rt=sin(vA1);
   o12=o;h2+=vvUnd(r1,1.-o,rt);h1+=vvUnd(r2,o,-rt);}
  float hs=1.-.5*tri;h0*=hs;h1*=hs;h2*=hs;
  // backing: dark damask glowing through the holes of the weave with the spectrum
  float vgq=step(.5,r0.gen);   // d15: the palette in force here, as a float (vvPick and the palettes are all float maths)
  // the carpet: a vast medallion carpet dyed and brocaded across the whole loom (10-24 pitches a cell): an eight-petal
  // medallion, a field, shared corner medallions, all outlined in couched gold. Up close the medallion shows as ikat
  // (its ribbons dyed the next colour, the edge feathered thread by thread in vvShade); pulled out, all its colours
  // take over the ribbons and the loom reads as one enormous carpet
  vec3 Mg=mix(uM1[1],uM2[1],vgq);
  float fam=floor(Mg.z/256.),fz=Mg.z-256.*fam,fk=floor(fz*.0625);vFP=vS*(2.*(fz-16.*fk)+1.);vIkOn=0.;
  {vec2 mu=(fract(vPp/vFP+.5)-.5)*2.,ma=abs(mu);
   vec2 m8=vec2(max(ma.x,ma.y),min(ma.x,ma.y));m8-=2.*max(dot(m8,vec2(-.38268,.92388)),0.)*vec2(-.38268,.92388);
   // (v12) the medallion's petals turn with the mids, every medallion breathes with the bass (smoothed)
   vec2 mr=rot(vMph*.78539816)*mu,ar=abs(mr),m8r=vec2(max(ar.x,ar.y),min(ar.x,ar.y));m8r-=2.*max(dot(m8r,vec2(-.38268,.92388)),0.)*vec2(-.38268,.92388);
   float bb=1.+.1*vBz;
   float zM=min(length(mu)-.3*bb,length(m8r-vec2(.4,.0)*bb)-.13*bb),zC=min(length(vec2(1.)-ma)-.42,length(m8-vec2(.68,.68))-.1);
   { // v21 the great figure comes in five families (0 the eight-petal medallion, 1 an ogee, 2 a lozenge with an eye, 3 a stepped kilim diamond,
     // 4 an eight-point star), and the panels of the carpet are a chessboard of two of them
     vec2 pc=floor(vPp/vFP+.5),s5=floor(ma*5.+.5)*.2;float fa=vvMod(fam+mod(pc.x+pc.y,2.)*(2.+mod(fam,2.)),5.),dz=ma.x+ma.y;
     float zO=ma.y-.6*bb*(.5+.5*cos(min(ma.x*1.15,1.)*PI)),dl=dz-.8*bb,zL=min(max(dl,-dl-.2),dl+.52);
     float zK=min(s5.x+s5.y-.62*bb,max(abs(ma.x-ma.y)-.08,dz-.98)),z8=min(max(ma.x,ma.y)-.44*bb,dz*.7071-.44*bb);z8=min(max(z8,-z8-.15),length(mu)-.16);
     zM=zM*vvW(fa,0.)+zO*vvW(fa,1.)+zL*vvW(fa,2.)+zK*vvW(fa,3.)+z8*vvW(fa,4.);}
   vIk=min(zM,zC);
   // v22: the far-view carpet panels are gone (the wide view belongs to the great ribbons); the great figure stays dyed into the loom as ikat,
   // outlined in couched gold
   vMd=1e3;
  }
  vec3 bg=vvPick(vgq,0.);
  float qh=min(r0.e,min(r1.e,r2.e));
  float gh=max(.5*vS-max(r0.hw0,r1.hw0),.006);
  float hole=clamp(qh/(gh*.6),0.,1.);
  float sb=.5*(r0.sp+r1.sp),lv=min(.72+1.5*sb+1.2*uKick+2.2*vRing+.8*uDrop+.8*uB1.x+1.1*uHat,3.2);   // v13: the hats flash the holes
  vec3 mt=vvPick(vgq,4.),gc=vvPick(vgq,1.5+.5*sin(sb*3.+uTime*.3));gc=mix(gc*gc*1.2,gc,.34);
  float ins=vS*.035,Rh=.5*vS*max(1.-min(mix(uM1[1][0],uM2[1][0],vgq)*vWM,mix(.985,.33,tri)),.02);
  if(qh>-2.*vPx){
   // v20: the lining. Under the loom lies a second cloth, cut on the bias: a tartan of narrow satin tapes in the palette's own
   // colours (a mirrored sett, dealt per generation), each tape cupped and dipping under its neighbours. No hole is ever black
   float L=vS/11.,lpx=vPx/L,gsd=mix(uM1[0][2],uM2[0][2],vgq);
   vec2 lg=rot(.7854)*vPp/L,lc=floor(lg),lf=fract(lg)-.5,l2=1.-4.*lf*lf;
   float lo=mod(lc.x+lc.y,2.),lfd=clamp((1./lpx-2.5)/3.5,0.,1.);
   vec2 kk=abs(vec2(vvMod(lc.x,10.),vvMod(lc.y,10.))-5.),hk=vec2(h11(kk.x*7.31+gsd*91.7),h11(kk.y*7.31+gsd*91.7));
   vec3 cw=mix(vvPick(vgq,1.+floor(hk.x*2.999)),mt,step(.82,fract(hk.x*17.3))),cf=mix(vvPick(vgq,1.+floor(hk.y*2.999)),mt,step(.82,fract(hk.y*17.3)));
   float lcy=mix(l2.y,l2.x,lo),lal=mix(l2.x,l2.y,lo);
   // close up, every float of a tape carries a bird's-eye: a small diamond of the crossing tape's colour with a metal pip
   float be=abs(lf.x)+abs(lf.y),bf=clamp((1./lpx-9.)/9.,0.,1.);
   vec3 lcol=mix(mix(cf,cw,lo),mix(cw,cf,lo)*1.15,clamp(.5-(abs(be-.25)-.05)/lpx,0.,1.)*bf);
   lcol=mix(lcol,mt,clamp(.5-(be-.07)/lpx,0.,1.)*bf);
   vec3 lin=mix(.5*(cf+cw),lcol*(.5+.72*lcy)*(.66+.36*lal),lfd);
#if HD>=1
   // detail range: every tape shows its twill, then (Cinema) a pin stripe of metal down its middle, then (Extreme) its threads
   {float ac=mix(lf.y,lf.x,lo),al=mix(lf.x,lf.y,lo),tf=clamp((1./(lpx*9.)-1.2)/1.6,0.,1.);
    lin*=1.+(abs(fract((al+ac)*4.5)-.5)*2.-.5)*.5*tf*lfd;
#if HD>=2
    lin=mix(lin,mt*(.5+.7*lcy),clamp(.5-(abs(ac)-.035)/lpx,0.,1.)*step(.5,fract(hk.x*5.3+hk.y*3.1))*tf*.8);
#endif
#if HD>=4
    {float t2=clamp((1./(lpx*36.)-1.2)/1.6,0.,1.);lin*=1.+(abs(fract(ac*18.)-.5)*2.-.5)*.4*t2*lfd;}
#endif
   }
#endif
   // it is lit by everything that lit the old glow: spectrum, kick, kick ring, drop, hats, and the underband that opens the gaps
   bg=lin*(.06+.075*lv+.1*vQt)+gc*hole*(.04*lv+(.26+.6*hole)*vGp);
   // v20: needle lace. A gold wheel is worked across every hole: a boss, spokes that run out under the ribbons, a rose of petals
   // that turns with the mids, scalloped webs that are added ring by ring by the hi-mids, and a bead where web meets spoke
   // that the hats and the air band light. It is anchored to the loom, so it breathes as the ribbons swell over it
   {float pwL=vPx/Rh,lodL=clamp(1.7-pwL*24.,0.,1.);
    if(lodL>0.){
     float c0=(fract(dot(vPp,vN0)/vS)-.5)*vS,c1=(fract(dot(vPp,vN1)/vS-.5*tri)-.5)*vS;
     vec2 hq=vec2((cos(vA1)*c0-c1)/sin(vA1),c0)/Rh;
     float Ns=mix(8.,12.,step(1.5,lay)),dBd;vec2 lid,lrt;
     float dLc=vvLace(hq,Ns,pwL,dBd,lid,lrt),rr=lrt.x,th=lrt.y;
     float hb=h11(lid.x*3.17+lid.y*7.7+dot(floor(vPp/vS),vec2(1.3,5.9))+vHN*.37),lit=step(1.-.2-.75*min(vAir,1.),hb);
#if HD>=1
     // detail range: the lace stands off the lining and throws a real shadow on it (the wheel is traced again from the light's side;
     // from Cinema a soft penumbra of three taps, from Extreme five)
     {float sdw=0.,d2;vec2 i2,r2;
#if HD>=4
      for(int k=vZ;k<vZ+5;k++){float o=.07+.022*float(k-vZ);
#elif HD>=2
      for(int k=vZ;k<vZ+3;k++){float o=.075+.03*float(k-vZ);
#else
      for(int k=vZ;k<vZ+1;k++){float o=.09;
#endif
       float dl=vvLace(hq+vec2(-.515,.857)*o,Ns,pwL,d2,i2,r2);sdw+=clamp(.5-min(dl,d2)/(pwL+.012),0.,1.);}
#if HD>=4
      sdw*=.2;
#elif HD>=2
      sdw*=.3333;
#endif
      bg*=1.-.62*sdw*lodL;}
#endif
     float cv=clamp(.5-dLc/pwL,0.,1.)*lodL,crown=clamp(-dLc/.016,0.,1.),cb2=clamp(.5-dBd/pwL,0.,1.)*lodL;
#if HD>=1
     crown*=1.-.45*clamp(.012/pwL-1.,0.,1.)*step(.5,fract(rr*42.+th*Ns*.955));
#endif
#if HD>=1
     bg*=1.-.3*clamp(1.-min(dLc,dBd)/.04,0.,1.)*lodL;
#else
     bg*=1.-.55*clamp(1.-min(dLc,dBd)/.075,0.,1.)*lodL;
#endif
     bg=mix(bg,mt*(.3+.75*crown)*(.6+.25*lv+.7*vPr),cv);
     bg=mix(bg,mix(mt,gc,.35)*(.5+.6*clamp(-dBd/.03,0.,1.))*(.7+3.2*lit*(.4+vAir)),cb2);}}
   // a picot edging hangs from every ribbon into the hole: a couched cord with a row of loops, sliding with its ribbon
   {float ea=mix(mix(r0.at,r1.at,step(r1.e,r0.e)),r2.at,step(r2.e,min(r0.e,r1.e))),pp=vS*.05,pr=vS*.019;
    float dE=min(abs(qh-ins)-vS*.0045,abs(length(vec2((fract(ea/pp)-.5)*pp,qh-ins-pr))-pr)-vS*.003+step(qh,ins)*vS);
    float ring=clamp(.5-dE/(vPx*1.2),0.,1.)*clamp(gh/ins-1.2,0.,1.)*clamp(vS*.006*vIPx,0.,1.);
    bg=mix(bg,mix(mt,gc,.3)*(.45+.3*lv+1.6*vAir),ring);}
  }
  float hsc=clamp(Rh/(vS*.14),.3,1.);vec2 off=vec2(.45,-.75)*vS*.16,o2=off*.6;float sw2=vS*.07;
  float sk=1.-.4*vWz;
  vec3 col=bg*vvShd(r0,off*hsc,vN0,vS*.12*hsc,.62*sk*VV_FK)*vvShd(r1,off*hsc,vN1,vS*.12*hsc,.62*sk*VV_FK)*mix(1.,vvShd(r2,off*hsc,vN2,vS*.12*hsc,.62*sk*VV_FK),tri);
  // layer order among the ribbons that actually cover this pixel
  float a0=step(0.,vPx-r0.e),a1=step(0.,vPx-r1.e),a2=tri*step(0.,vPx-r2.e);
  float z0=o01*a1+o02*a2,z1=(1.-o01)*a0+o12*a2,z2=mix(9.,(1.-o02)*a0+(1.-o12)*a1,tri);
  float k0=z0*4.,k1=z1*4.+1.,k2=z2*4.+2.;
  float q0=step(k1,k0)+step(k2,k0),q1=step(k0,k1)+step(k2,k1),q2=step(k0,k2)+step(k1,k2);
  // which family lies above which here: rank order when both cover, the weave order otherwise
  float u10=mix(1.-o01,step(q0,q1),a0*a1),u20=mix(1.-o02,step(q0,q2),a0*a2),u21=mix(1.-o12,step(q1,q2),a1*a2);
  // contact shadows each family casts on whatever passes beneath it
  float sh0=vvShd(r0,o2,vN0,sw2,.62*sk*VV_FK),sh1=vvShd(r1,o2,vN1,sw2,.62*sk*VV_FK),sh2=mix(1.,vvShd(r2,o2,vN2,sw2,.62*sk*VV_FK),tri);
  for(int rk=0;rk<vN3;rk++){
    if(rk>=nF)break;
    float fr=float(rk);
    VR r=r0;float f=0.;vec2 hd=h0;float sh=mix(1.,sh1,u10)*mix(1.,sh2,u20);
    if(abs(q1-fr)<.5){r=r1;f=1.;hd=h1;sh=mix(1.,sh0,1.-u10)*mix(1.,sh2,u21);}
    if(abs(q2-fr)<.5){r=r2;f=2.;hd=h2;sh=mix(1.,sh0,1.-u20)*mix(1.,sh1,1.-u21);}
    if(r.cov>0.){col=mix(col,vvShade(r,f,hd,tri)*sh,r.cov);vEc=r.cov;vEsh=sh;}
  }
  col*=vSm;
  // embroidery on the top layer: threads, halo, glints; the reverse of a twist shows only the back of the stitching
  if(vEc>0.){vec4 em=vvEmb(vEq.xy,vEsd,vEq.w,vEq.z,vErh)*vEc*(1.-.5*vWz);float spk=1.-.85*vWz;
   // w4 (kept from wave 2): the hats' running stitch. Metal beads couched along both edges of the band on top; each hat lights a new half of them
   {float sa=vEq.z*9.,row=abs(abs(vEq.y)-.415),dS=length(vec2((fract(sa)-.5)*.1444,row))-.026;
    float on=step(.5,h11(floor(sa)*1.37+vErh*7.1+sign(vEq.y)*3.3+vHN*.53)),a=clamp(.5-dS/vEq.w*.5,0.,1.)*vEc*clamp(.035/vEq.w-.3,0.,1.);
    col=mix(col,mix(vP4,vQ4,vgq)*(.22+.14*on+(4.4*uHat+1.3*vAir+.5*vPr)*on)*vEsh,a);}
   float stx=1.-.44*abs(fract((vEq.x+vEq.y)*55.)-.5)*clamp(2.25-vEq.w*250.,0.,1.),tc=vEsh*vEpf*stx*vEcp;
   col*=1.-(.72-.2*vWz)*em.z;
   col=mix(mix(col,vEtB*tc,em.y),vEtA*tc,em.x);
   col+=mix(vP4,vQ4,vgq)*1.25*em.w*(1.+1.2*vGd+vEbd)*vEsh*spk;   // v22: glints are the metal thread's own colour
   // v18: spangles. A sewn field of sequins across the ribbon: the air band and hats decide how many catch the light
   vec2 sg=vec2(vEq.z*1.3,vEq.y)/.17+vec2(vErh*3.,0.),sid=floor(sg),sf=fract(sg)-.5;
   float sh=h11(sid.x*1.73+sid.y*7.31+vErh*13.7),sq2=length(sf)*.17;
   float slit=smoothstep(-.05,.05,vAir*.6*(1.-.85*vWz)-fract(sh*91.7+floor(uMT*.25+sh)*.618))*step(abs((sid.y+.5)*.17),.3);
   // v19: hats fire gold shuttles down a chosen set of ribbons; every hat re-deals which ribbons carry one
   float shS=h11(vErh*17.3+vHN*.371),shP=fract(vEq.z*.16-uTime*(1.2+1.1*shS)+shS*7.);
   col+=mix(vP4,vQ4,vgq)*1.5*step(.62,shS)*pow(shP,10.)*(.25+2.4*uHat+.9*vAir)*(exp(-vEq.y*vEq.y*900.)+.5*exp(-vEq.y*vEq.y*90.))*(1.-.7*vWz)*vEc*vEsh*spk;
   float scs=exp(-abs(sf.x)*26.)*exp(-abs(sf.y)*6.)+exp(-abs(sf.y)*26.)*exp(-abs(sf.x)*6.);
#if HD>=1
   // v19 detail range: the ribbon's own cloth, level by level: warp and weft threads with a true over/under, then the plied yarn,
   // then the fibres. Each level fades in by its footprint in pixels, so extra pixels reveal it and nothing shimmers
   {float tl=1.,ts=0.,N=46.;vec2 tq=vec2(vEq.x+.65,vEq.y);float tid=floor(vEq.z);
    for(int k=vZ;k<vZ+VV_TL;k++){
     float Nx=floor(1.3*N+.5)/1.3,fd=clamp((1./(N*vEq.w)-1.25)/1.5,0.,1.);if(fd<=0.)break;
     vec2 tg=tq*vec2(Nx,N),ci=floor(tg),tf=fract(tg)-.5;
     float ov=mod(ci.x+ci.y+float(k-vZ),2.),cyl=mix(1.-4.*tf.x*tf.x,1.-4.*tf.y*tf.y,ov),ha=h21(ci+vec2(tid,float(k-vZ)*7.+vErh*3.));
     float am=pow(.7,float(k-vZ));
     tl*=mix(1.,(.62+.55*cyl)*(.94+.12*ha),fd*am);ts+=pow(max(cyl,0.),6.)*(.55+.9*ha)*fd*am*.22;
     N*=2.37;}
    col*=mix(1.,tl,vEc);col+=vEtA*ts*(.55+vEbd)*vEc*vEsh;}
#else
   // v20: close up, the phone picture shows the cloth too: one level of warp and weft with a true over/under
   {float N=46.,fd=clamp((1./(N*vEq.w)-1.3)/1.7,0.,1.);vec2 tg=vec2(vEq.x+.65,vEq.y)*vec2(46.154,N),ci=floor(tg),tf=fract(tg)-.5;
    float ov=mod(ci.x+ci.y,2.),cyl=mix(1.-4.*tf.x*tf.x,1.-4.*tf.y*tf.y,ov);
    col*=mix(1.,.66+.52*cyl,fd*vEc);}
#endif
   {float sR=max(.05,vEq.w*1.3),sd=clamp(.025/vEq.w-1.,0.,1.),su=sq2/sR,sm=clamp((sR-sq2)/vEq.w,0.,1.)*slit*vEc;
    vec2 sn=sf/max(length(sf),.01),sL=vec2(cos(sh*40.+vEbd*2.),sin(sh*40.+vEbd*2.));
    float cupS=.5+.5*dot(sn,sL)*smoothstep(.15,.9,su),rimS=smoothstep(.78,.9,su),holeS=smoothstep(.2,.14,su);
    vec3 sC=mix(mix(vP4,vQ4,vgq),vEtB,.5+.5*step(.5,fract(sh*7.7)));
    vec3 sq=sC*(.35+1.5*cupS*cupS+.5*rimS)*(1.-.8*holeS)*(.6+(.8+.8*vZc)*vAir)*vEsh;
    col=mix(col,sq,sm*sd*.92);
    col+=(.45*mix(vP4,vQ4,vgq)+.55*vEtB)*slit*(2.3*clamp((sR-sq2)/vEq.w,0.,1.)*(1.-sd)+1.25*scs*(1.-smoothstep(.3,.5,length(sf))))*(.4+(1.2+1.4*vZc)*vAir)*vEc*vEsh*spk;}}
#if HD>=1
  // v19 detail range: real light. Rays leave the surface toward an area light and march across the weave's height field: true cast
  // shadows (soft, from a fan of rays) in place of the fixed-offset contact shadows; from Cinema up, satin reflection rays and ambient occlusion
  {float lm=1.;vHg=max(r0.gen,r1.gen);vHB=mix(uM1[2],uM2[2],vHg)*step(65535.5,mix(uM1[0][1],uM2[0][1],vHg))*(1.-tri);vHw=.5*vS*min(mix(uM1[1][0],uM2[1][0],vHg)*vWM*(1.+.11*vRing)*(1.-.09*vCin),mix(.985,.33,tri));
   float z0=vvHgt(p),sT=0.,fp=clamp(vS*.06*vIPx-.7,0.,1.);int Mr=int(clamp(4.+2.2*vVd,4.,32.));vec2 Ld=vec2(.515,-.857);
   for(int ry=vZ;ry<vZ+VV_RAYS;ry++){
    vec2 L2=rot((float(ry-vZ)+.5)/float(VV_RAYS)*1.1-.55)*Ld;float s=0.;
    for(int k=vZ;k<vZ+Mr;k++){float t=(float(k-vZ)+.6)/float(Mr),zr=z0+.1+t*.95,h=vvHgt(p+L2*t*vS*.46);s=max(s,clamp((h-zr)/.14,0.,1.)*(1.-.4*t));if(s>.98)break;}
    sT+=s;}
   sT/=float(VV_RAYS);
   // occlusion: a ring of height samples tells how far the surface sits in a valley of the weave
   {float ao=0.;for(int k=vZ;k<vZ+8;k++){float an=float(k-vZ)*.7854+.39;ao+=clamp((vvHgt(p+vec2(cos(an),sin(an))*vS*.15)-z0-.06)/.4,0.,1.);}col*=1.-.42*(ao/8.)*fp*lm;}
   // reflection bounce: skimming satin rays pick up the colour of the ribbon that stands in their way
   if(vEc>0.){vec3 rc=vec3(0.);
    for(int b=vZ;b<vZ+VV_RAYS;b++){vec2 dR=rot((float(b-vZ)+.5)/float(VV_RAYS)*1.6-.8)*vec2(-.515,.857);
     for(int k=vZ;k<vZ+Mr;k++){float t=(float(k-vZ)+.6)/float(Mr);if(vvHgt(p+dR*t*vS*.55)>z0+.08+.7*t){rc+=vvRibC(vHf,vHi,vHg)*(1.-.5*t);break;}}}
    col+=rc/float(VV_RAYS)*(.16+.55*vEbd)*vEsh*vEc*(.3+.7*fp);}
   col*=1.-.55*sT*fp*lm;}
#endif
  // v19: the carpet plays the kick like a step sequencer: every kick lights a different scatter of medallion cells
  {float cL=step(fract(h21(floor(vPp/vFP+.5)+vec2(11.,7.))*9.+vKn*.382),.3),mk=clamp(.5-vIk*vFP*.5*vIPx,0.,1.)*cL*uKick;
   col=col*(1.+1.9*mk*(.35+.65*vWz))+vvPick(vgq,3.)*mk*.1*(.5+.5*vWz);}
  // the snare cascade is a sweeping band of light; the crossings flip exactly under it
  float fd=dot(p,vFd)-vFf;
  float swp=exp(-fd*fd*90.)*(1.-uP4.y*uP4.y);
  col*=1.+(1.5+2.4*vZc+1.3*vEc)*swp;col+=mix(vP4,vQ4,vgq)*swp*(.1+.4*vZc);
  // v18: the folds light the whole cloth: shaded troughs, and crests that catch a satin highlight lifted by the bass
  col*=(1.+.38*vFt)*(1.+exp(-(vFt-.72)*(vFt-.72)*14.)*(.25+.6*vBz));
  // the pool of light on the cushion gives the frame a focal point; the edges fall into the dark
  col*=mix(.88-.24*vSp,1.12+.2*vSp,exp(-lr2*(2.6+6.*vSp)));
  // (v12: a touch more chroma, so the added band light never pales the satin)
  col*=1.+.4*vQt;
  col=vvHM*col;float lqv=dot(col,vec3(.2126,.7152,.0722));
  col=max(lqv+(col-lqv)*1.32,0.);
  // v22: no light may push a colour out of its hue. The brightest channel is rolled off above a knee and the whole vector is scaled with it
  // (a channel is never clamped), so the loudest frame is the deepest colour the screen has, not a paler one
  {float m=max(col.r,max(col.g,col.b)),k=.6,c2=1.04;col*=mix(1.,(k+(c2-k)*(1.-exp(-(m-k)/(c2-k))))/max(m,1e-3),step(k,m));}
  fragColor=vec4(col,0.);
}
`;
