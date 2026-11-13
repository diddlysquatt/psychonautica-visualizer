const R_TESS = `
// TESS4. Neon line art of four-dimensional polytopes: tesseract, 16-cell, 24-cell, 5-cell, duoprisms (6-6, 4-9, 3-12,
// 8-8 Clifford-torus grid), six of the 600-cell's Hopf great circles and Hopf keyrings (linked great circles on two
// tori).
// Vertices and edges are enumerated procedurally, rotated by a 4D rotation integrated in JS (rotation planes change
// on phrases; bass drives the speed, kicks deliver smoothed impulses), projected 4D -> 3D -> 2D in perspective and
// drawn as analytic lines anti-aliased against the pixel footprint (never thinner than 1.5 px, so they stay crisp
// when upscaled). Edge families light with the mid bands, vertices throw crisp sparks on highs/air onsets.
// Formations: NEST (endless zoom of nested shells), CORE (hero with an inner shell and a satellite ring;
// centred / mirrored twins / off-centre), GRID (columns scrolling up and down, column = frequency) and FLY (a
// honeycomb fly-through: lattice planes of polytopes rushing at the camera).
// Behind everything: a colossal lattice of giant polytopes with light trains on their edges (revealed when the view
// pulls back: mouse zoom below 1, breakdowns and vista phrases), a parallax constellation field with lattice lines,
// nebula, stars, light beams and a spectrum ring.
// uP1 + uM1 = the global 4D rotation G (columns 0-2; column 3 rebuilt)
// uP2 (types a+16b+256c+4096d, form, heroX, heroY) | uP3 (breathe,explode,build,-) | uP4 (snareT,flash,hatPh,1000*kick+shrink)
// uP5 (colours 0-2 packed, travel) | uM2 (src xyz, view zoom, dW, twin, layout+2*ringN, colour 3 packed, pulse)
mat4 tsR,tsG;vec2 tsP,tsQ,tsH;
float tsHotK,tsVrK,tsSpread,tsS,tsDW,tsLW,tsI,tsT,tsEx,tsPx,tsVR,tsSnT,tsFl,tsHp,tsHat,tsHz,tsHzK,tsMir,tsTA,tsTB,tsTC,tsTD,tsForm,tsTw,tsZs,tsPulse,
  tsBst,tsBK,tsAB,tsAM,tsAH,tsAmp,tsHatE,tsRingN,tsLay,tsGc,tsCd,tsSd,tsFlip,tsShr,tsBeadN,tsVRm,tsKH,tsZE,tsLz,tsSpk,tsKick,tsUnf,tsUsc;
vec4 tsSrc,tsBand,tsBOn,tsUA,tsUsh,tsLo,tsKS;vec3 tsAcc,tsLatC;vec2 tsWF,tsWA;
float tsSq(float x){return x*x;}
// how strongly a kick shockwave front is passing over the point c right now (light and a smoothed size swell)
float tsWv(vec2 c){float l=length(c-tsH);return exp2(-tsSq((l-tsWF.x)*6.))*tsWA.x+exp2(-tsSq((l-tsWF.y)*6.))*tsWA.y;}
// one of the eight shaped bands by index (0 sub, 1 bass, 2-5 low-mid .. presence, 6 high, 7 air): each satellite
// listens to its own band, so the field shows the spectrum, not only the hero
float tsBandOf(float k){k=mod(floor(k),8.);vec4 a=vec4(equal(vec4(k),vec4(0,1,2,3))),b=vec4(equal(vec4(k),vec4(4,5,6,7)));
  return dot(a,vec4(tsLo.xy,tsBand.xy))+dot(b,vec4(tsBand.zw,tsLo.zw));}
vec4 tsE(int i){return vec4(equal(ivec4(i),ivec4(0,1,2,3)));}
vec3 tsHex(int h){vec3 c=vec3(float((h>>16)&255),float((h>>8)&255),float(h&255))/255.;return c*c;}
// the visit's palette (four hand-curated colours, cross-faded and turned by the visit hue and the engine's global hue
// drift in JS) arrives packed as 24-bit ints
vec3 tsK0,tsK1,tsK2,tsK3;mat4x3 tsKM;
void tsPalInit(){
  tsK0=tsHex(int(uP5.x));tsK1=tsHex(int(uP5.y));tsK2=tsHex(int(uP5.z));tsK3=tsHex(int(uM2[2].y));tsKM=mat4x3(tsK0,tsK1,tsK2,tsK3);
}
// cyclic gradient through the four colours: smooth hat weights times the palette matrix (cheap, no indexing),
// with a little chroma lift so the half-way blends never grey out
vec3 tsGrad(float t){
  vec4 w=smoothstep(0.,1.,max(1.-abs(fract(t-vec4(0,.25,.5,.75)+.5)*4.-2.),0.));
  vec3 m=tsKM*w;return max(m+(m-dot(m,vec3(.3333)))*(.15+2.4*(w.x*w.y+w.y*w.z+w.z*w.w+w.w*w.x)),0.);
}
mat4 tsRot(vec4 g){
  vec4 c=cos(g),s=sin(g);
  mat4 D1=mat4(c.x,0,0,s.x, 0,c.y,s.y,0, 0,-s.y,c.y,0, -s.x,0,0,c.x);
  mat4 D2=mat4(c.z,s.z,0,0, -s.z,c.z,0,0, 0,0,c.w,s.w, 0,0,-s.w,c.w);
  return D1*D2;
}
// 4D perspective (eye on +w) -> 3D perspective -> screen. xy local screen, z depth 0..1, w 4D depth
vec4 tsProj(vec4 v){
  vec4 r=tsR*v;
  vec3 q=r.xyz*(tsDW/(tsDW-r.w));
  return vec4(q.xy*(4./(4.-q.z)),clamp(.5+.2*q.z+.32*r.w,0.,1.),r.w);
}
// vertex ring and spark: drawn by every incident edge (at its nearer endpoint) at 1/degree strength, so the sum
// equals one (and they fly apart with their edges in an explosion); no separate vertex loop
void tsVert(vec2 c,float vz,vec3 col,float fl){
  vec2 dq=(tsQ-c)*tsS;float d=length(dq);
  float rr=tsVR*(.45+.9*vz)*(1.+.35*tsHatE);
  float rd=abs(d-rr),w=tsLW*.55;
  float ring=clamp((w-rd)/tsPx+.5,0.,1.);
  // crisp four-point spark (highs / air): two thin crossed lines
  float spk=clamp((tsPx*.7-min(abs(dq.x),abs(dq.y)))/tsPx+.5,0.,1.)*tsSq(max(0.,1.-d/(rr*(1.5+3.5*tsSpk))))*tsSpk;
  float nd=0.;
  if(rr>tsPx*4.5&&d<rr*1.9){float na=atan(dq.y,dq.x)/TAU*8.-(floor(uP5.w)+smoothstep(0.,.3,fract(uP5.w)))*.5;
    nd=clamp((w*.8-abs(d-rr*1.55))/tsPx+.5,0.,1.)*smoothstep(.3,.2,abs(fract(na)-.5))+clamp((rr*.28-d)/tsPx+.5,0.,1.)*.7;}
  tsAcc+=col*tsI*tsVrK*((.25+vz)*ring*(.8+2.*fl+3.*tsHatE)+spk*2.2+nd*(.3+.5*vz)*(.5+3.2*tsSpk+1.5*fl));
}
void tsEdge(vec4 a,vec4 b,float fam){
  vec4 A=tsProj(a),B=tsProj(b);
  vec2 M=(A.xy+B.xy)*.5;A.xy=mix(A.xy,M,tsShr);B.xy=mix(B.xy,M,tsShr);
  vec2 ex=M*(tsEx+tsBst*tsBK);
  vec2 pa=tsQ-A.xy-ex,ba=B.xy-A.xy;
  float h=clamp(dot(pa,ba)/max(dot(ba,ba),1e-9),0.,1.);
  // every edge is elastic: the low end bows it, its own mid band bends it into a slow S; the amplitudes come from
  // smoothed envelopes and vanish at the vertices, so the polytope always stays a polytope
  float lb=length(ba),bel=sin(3.14159*h),sg0=mod(fam,2.)*2.-1.;
  vec4 sel=vec4(equal(vec4(mod(fam,4.)),vec4(0.,1.,2.,3.)));
  float bo=dot(tsBOn,sel),fb=dot(tsBand,sel);
  vec2 v0=pa-ba*h-vec2(-ba.y,ba.x)/max(lb,1e-4)*lb*bel*(sg0*tsAB+tsAM*fb*cos(3.14159*h)*sin(uTime*2.3+fam*1.7));
  float dl=length(v0),d=dl*tsS;
  // edge density: summed over the body it becomes a soft luminous fill
  tsHz+=exp2(-dl*dl*34.);
  float z=mix(A.z,B.z,h);
  // the family's own band sets how thick this edge is, so a band that comes in visibly fattens its own edges
  float w=max(tsLW*(.35+1.25*z*z),tsPx*.75);
  if(d>max(w*4.,tsVrK>0.?tsVR*(2.9+4.8*tsSpk):0.)+tsPx*2.5)return;
  float casc=.5-.25*dot(a+b,tsSrc),fe=tsFl*exp2(-tsSq((tsSnT-casc)*7.));
  float t=tsT+tsSpread*(fam*.25+.42*mix(A.w,B.w,h));
  vec3 col=tsGrad(t),hot=mix(col,vec3(1.),.55*tsHotK);
  if(tsVrK>0.){bool s=h<.5;tsVert((s?A.xy:B.xy)+ex,s?A.z:B.z,mix(col,vec3(1.),.35*tsHotK),fe);}
  float core=clamp((w-d)/tsPx+.5,0.,1.);
  // v19: engraved edges. A line wide enough to hold it becomes a hollow double rail (a dark groove down its middle); from Cinema up, ruler ticks stand beside it
  // v20: the rail at every tier
  {
    float wPx=w/tsPx;
    core*=1.-.72*(1.-smoothstep(w*.2,w*.2+tsPx,d))*smoothstep(2.,3.4,wPx);

    float Lx=max(lb*tsS,1e-5),NT=floor(Lx/max(tsPx*7.,w*3.)),tk=abs(fract(h*NT)-.5)*Lx/max(NT,1.);
    float tkL=(1.-smoothstep(tsPx*.5,tsPx*1.3,tk))*smoothstep(w*3.2,w*2.2,d)*smoothstep(w,w*1.3,d)*step(1.,NT);
    tsAcc+=tsGrad(tsT+tsSpread*fam*.25+.5)*tkL*tsI*(.06+.28*z)*smoothstep(1.2,2.2,wPx);
  }
  float halo=exp2(-d*d/(w*w*4.5));
  // kicks flash one edge family at a time (it moves on with every kick), the others only a little
  float fl=fe*2.2+tsFl*.15+tsKH*dot(sel,tsKS);
  float I=tsI*(1.+2.5*tsShr)*(.18+1.05*z)*(.56+1.25*sqrt(fb))*(1.+.9*bo);
  // light trains run along every edge (one bead on polytopes, many on the colossal lattice); hats/air make them blaze
  float L=length(ba)*tsS,pp=fract(tsHp+casc*1.37+fam*.29);
  float al=(fract(h*tsBeadN-pp+.5)-.5)*L/tsBeadN;
  float bead=exp2(-(d*d+al*al)/(w*w*5.))*(.12+3.8*tsHat);
  tsAcc+=col*I*(core*(.85+fl)+halo*.12)+hot*(I*core*(fl*1.3+bo*.9)+bead*tsI*(.6+z));
}
// ---- polytopes enumerated by index (one tsEdge call site keeps the D3D compile small) ----
// types: 0 tesseract, 1 16-cell, 2 24-cell, 3 6-6 duoprism, 4 5-cell, 7 600-cell Hopf fibres, 8 Hopf keyrings,
// 9 8-8 duoprism, 10 tesseract unfolding into its net (the 4-9 and 3-12 duoprisms were cut for compile budget)
int tsNE(int ty){return ty==0?32:ty==1?24:ty==2?96:ty==4?10:ty==7?120:ty==3?72:128;}
// quaternion product (x,y,z = i,j,k; w = real)
vec4 tsQm(vec4 p,vec4 q){return vec4(p.w*q.xyz+q.w*p.xyz+cross(p.xyz,q.xyz),p.w*q.w-dot(p.xyz,q.xyz));}
// unordered axis pair p (0..5) -> (i,j)
ivec2 tsPair(int p){return ivec2(p<3?0:p<5?1:2,p<3?p+1:p<5?p-1:3);}
void tsEdgeOf(int ty,int e,out vec4 a,out vec4 b,out float fam){
  if(ty==4||ty==3||ty==9){
    // two-angle points (cos u, sin u, cos v, sin v)/sqrt2 on the Clifford torus: duoprism rings, and the 5-cell as
    // the torus-knot pentagon + pentagram (the five points (k, 2k) of a 5-5 grid form a regular simplex)
    vec4 an;
    if(ty==4){float k=float(e<5?e:e-5),s=e<5?1.:2.;an=vec4(k,2.*k,k+s,2.*(k+s))/5.;fam=e<5?0.:2.;}
    else{float n=ty==3?6.:8.;vec2 pq=vec2(n);int c=e>>1;float fi=floor((float(c)+.5)/n),fj=float(c)-fi*n;bool ra=(e&1)==0;
      an=vec4(fi,fj,fi+(ra?1.:0.),fj+(ra?0.:1.))/pq.xyxy;fam=ra?mod(fj,2.):2.+mod(fi,2.);}
    an*=TAU;a=vec4(cos(an.x),sin(an.x),cos(an.y),sin(an.y))*.7071;b=vec4(cos(an.z),sin(an.z),cos(an.w),sin(an.w))*.7071;
  }else{
    // circles, point = W + cos t U + sin t V: tesseract = 8 squares, 16-cell = 6 great squares, 24-cell = 16 great
    // hexagons (cosets of the order-6 Hurwitz units), 600-cell fibres = 6 of its 12 Hopf great circles (over
    // icosahedron vertices, drawn smooth), keyrings = 4 smooth Hopf fibres over each of two latitude circles (two nested tori of linked rings)
    vec4 U,V,W=vec4(0.);float t;
    if(ty==0){int q=e>>2,k=e&3,h=q>>2;U=tsE(2*h)*.7071;V=tsE(2*h+1)*.7071;
      W=(vec4(float(q&1),float((q>>1)&1),float(q&1),float((q>>1)&1))-.5)*(h==0?vec4(0,0,1,1):vec4(1,1,0,0));
      t=.7854+float(k)*1.5708;fam=float(2*h+(k&1));}
    else if(ty==1){ivec2 P=tsPair(e>>2);U=tsE(P.x);V=tsE(P.y);t=float(e&3)*1.5708;fam=float(P.x+P.y+(e&1));}
    else if(ty==2){int s=(e*2731)>>16,r=e-s*24,c=(r*10923)>>16;
      U=c==0?vec4(0,0,0,1):tsE(c-1);V=tsQm(U,vec4(s==0?vec3(1,1,1):s==1?vec3(1,-1,-1):s==2?vec3(-1,1,-1):vec3(-1,-1,1),0.)*.57735);
      t=float(r-c*6)*1.0472;fam=float(s);}
    else{
      // fibre f over the direction (th, ph): 600-cell = the icosahedron's pole + its upper ring of five, 20 segments;
      // keyrings = four fibres on each of two latitudes, 16 segments (no nested branches)
      bool sx=ty==7;float K=sx?20.:16.,f=floor((float(e)+.5)/K),k=float(e)-f*K,r=floor(f*.25);
      float th=sx?(f<.5?0.:1.1071487):(r<.5?1.05:2.2),ph=sx?TAU*(f-1.)/5.:TAU*mod(f,4.)*.25+r*.785;
      vec3 n=vec3(sin(th)*cos(ph),sin(th)*sin(ph),cos(th));t=TAU*k/K;fam=sx?mod(f,4.):r*2.+mod(f,2.);
      U=vec4(-n.y,n.x,0.,1.+n.z)/sqrt(max(2.+2.*n.z,1e-4));V=tsQm(U,vec4(0,0,1,0));
    }
    // the next vertex is the same circle turned by the type's constant step (cos/sin precomputed per polytope)
    float c=cos(t),s=sin(t);a=c*U+s*V+W;b=(c*tsCd-s*tsSd)*U+(s*tsCd+c*tsSd)*V+W;
  }
}
void tsNet(int e0,inout vec4 a,inout vec4 b,out float fam){
    // the tesseract unfolding into its net (the Dali cross): every edge is drawn once for each of its three cells,
    // moved with that cell. The base cell (w=-1/2) stays; the six cells around it swing about their shared faces from
    // the w direction into 3D; the w=+1/2 cell rides on the z+ cell and swings twice as far, topping the column
    int j=((e0>>3)&2)+(e0&1)+1+(e0>>5)&3;vec4 m=tsE(j);float sg=sign(dot(a,m));
    vec4 k=vec4(0,0,0,tsUA.y-1.)+sg*tsUA.x*m;
    if(j<3){a+=(a.w+.5)*k;b+=(b.w+.5)*k;}
    else if(sg>0.){a.zw=tsUA.xy+vec2(.5,-.5)+(.5-a.z)*tsUA.zw;b.zw=tsUA.xy+vec2(.5,-.5)+(.5-b.z)*tsUA.zw;}
    a=(a+tsUsh)*tsUsc;b=(b+tsUsh)*tsUsc;fam=mod(float(j)+sg+1.,4.);
  }
// draw one polytope: type, rotation offset angles, centre, scale (screen units per unit radius), half line width,
// intensity, hue offset (globals: tsFlip 0 = G, 1 = G transposed (counter-rotating), 2 = own slow rotation only;
// tsMir mirrors it left/right, tsHzK sets the strength of its luminous fill)
void tsDraw(float type,vec4 off,vec2 C,float S,float lw,float I,float T,bool vr,float spread){
  tsSpread=spread;lw*=tsLz;
  int ty=int(type+.5);
  // exact reach of a unit-radius polytope after both perspective divides: max over w of sqrt(1-w^2)*dW/(dW-w)
  float f4=tsDW/sqrt(max(tsDW*tsDW-1.,.1)),bound=f4*4./(4.-min(f4,3.))*(1.+tsEx+tsBst*tsBK+tsAmp)*S*(ty==10?1.25:1.04)+lw*8.+tsPx*3.;
  if(length(tsP-C)>bound||I<.004)return;
  tsS=S;tsQ=(tsP-C)/S;tsQ.x*=tsMir;
  tsR=(tsFlip<.5?tsG:tsFlip<1.5?transpose(tsG):mat4(1.))*tsRot(off);
  float spx=S/tsPx;int ne=ty==10?96:tsNE(ty),z0=min(int(uTime),0);float dtT=ty==2?1.0472:ty==7?.314159:ty==8?.392699:1.5708;tsCd=cos(dtT);tsSd=sin(dtT);
  tsLW=max(lw,tsPx*.75);tsI=(ty==10?mix(.34,1.,smoothstep(0.,.25,tsUnf)):1.)*I*sqrt(min(1.,lw/tsLW))*mix(min(1.,sqrt(40./float(ne))),1.,smoothstep(25.,90.,spx));tsT=T;tsVR=lw*tsVRm;tsHz=0.;tsHzK*=smoothstep(15.,70.,spx);
  tsVrK=vr&&tsVR>tsPx*(ty>6&&ty<9?6.:2.5)?(ty==1?1./6.:ty==2?.125:ty==7||ty==8?.5:ty==10?mix(.25,.34,tsUnf):.25):0.;
  int tyE=ty==10?0:ty,em=ty==10?31:255;
  float big=smoothstep(22.,90.,spx);tsHotK=.25+.75*big;vec3 acc0=tsAcc;
#if HD>=1
  // v19: ruled faces. Between two edges that meet at a vertex, a fan of straight strings joins points along them (string art: the envelope is a curve). Each corner
  // takes the strongest string only (max, not a sum) and is drawn in its family's palette colour, so the fans read as coloured ink and cannot add up to white.
  float rulF=(ty!=7&&ty!=8&&ty!=10&&spx>70.&&S<.9)?(1.-smoothstep(.05,.25,tsEx))*(1.-smoothstep(.0,.03,tsShr)):0.;
  int nStr=int(clamp(2.+2.4*uDetail,0.,26.));vec4 pA=vec4(0.),pB=vec4(0.);float wStr=max(tsLW*.22,tsPx*.55);vec3 strA=vec3(0.);
#endif
  for(int e=z0;e<128;e++){
    if(e>=ne)break;
    vec4 a,b;float fam;tsEdgeOf(tyE,e&em,a,b,fam);if(ty==10)tsNet(e,a,b,fam);
    tsEdge(a,b,fam);
#if HD>=1
    if(rulF>.002&&e>0){
      vec4 d1=a-pB,d2=a-pA;float c1=dot(d1,d1),c2=dot(d2,d2);
      if(c1<1e-4||c2<1e-4){
        vec4 P0=tsProj(c1<1e-4?pA:pB),P1=tsProj(c1<1e-4?pB:pA),P2=tsProj(b);
        vec2 mC=(P0.xy+P1.xy+P2.xy)/3.;
        float rC=max(length(P0.xy-mC),max(length(P1.xy-mC),length(P2.xy-mC)));
        if(length(tsQ-mC)<rC+wStr/tsS+tsPx/tsS*2.){
          float cv=0.;
          for(int k=z0;k<26;k++){
            if(k>=nStr)break;
            float u=(float(k)+1.)/(float(nStr)+1.);
            vec2 s0=mix(P0.xy,P1.xy,u),s1=mix(P1.xy,P2.xy,u),qa=tsQ-s0,qb=s1-s0;
            float hh=clamp(dot(qa,qb)/max(dot(qb,qb),1e-9),0.,1.),dd=length(qa-qb*hh)*tsS;
            cv=max(cv,clamp((wStr-dd)/tsPx+.5,0.,1.));
          }
          strA+=tsGrad(tsT+tsSpread*(fam*.25+.42*P1.w)+.12)*cv*(.1+.5*P1.z);
        }
      }
    }
    pA=a;pB=b;
#endif
  }
#if HD>=1
  tsAcc+=strA/(1.+1.4*dot(strA,vec3(.3333)))*tsI*rulF*.85;
#endif
  float lq=length(tsQ);
  tsAcc+=mix(mix(tsK0,tsK2,.5+.5*cos(TAU*(T+.3*lq))),tsK1,.3)*(tsHz*tsHzK*tsI/(4.+.25*float(ne)))*smoothstep(1.6,.5,lq)*.2*min(1.,1./(tsZE*tsZE));
  { vec3 dA=tsAcc-acc0;float lm=dot(dA,vec3(.3333));dA=max(lm+(dA-lm)*mix(1.45,1.08,big),0.);
    float mA=max(dA.r,max(dA.g,dA.b)),lim=mix(.8,3.,big);if(mA>lim)dA*=(lim+(mA-lim)/(1.+1.3*(mA-lim)))/mA;tsAcc=acc0+dA; }
}
// designed backdrop: palette wash, drifting nebula, stars, hero bloom and light beams, guide ring, spectrum ring,
// the spectral corona (a big audio sun: filaments = the spectrum, iris = the mids), the bass shockwave and the
// high glitter
vec3 tsBg(vec2 p,float form,float R0,float sx,float hud){
  float px=tsPx;
  // hero frame (mirrored twins fold it so each twin gets its own bloom, beams, corona and rings)
  vec2 pc=p-tsH;pc.x=abs(pc.x)-sx;
  float r=length(pc),a=atan(pc.y,pc.x),N=72.,ai=fract(a/TAU+.25),id=floor(ai*N);
  // the eight shaped bands: tsLo = sub, bass, high, air; tsBand = low-mid, mid, hi-mid, presence
  float bsw=clamp(.55*tsLo.x+1.15*tsLo.y,0.,1.3);                          // the low end
  float mv=clamp(.34*tsBand.x+.5*tsBand.y+.5*tsBand.z+.3*tsBand.w,0.,1.);  // the middle
  float hgh=clamp(.55*tsLo.z+.7*tsLo.w+1.05*tsHat,0.,1.2);                 // the top (bands and the hat envelope)
  // far layers move less with the view zoom (parallax), so pulling back reveals more of them without shrinking to mush
  vec2 ps=p*tsZE,pn=p*pow(tsZE,.8);
  vec3 c1=mix(tsK1,tsK2,.35),c2=mix(tsK3,tsK0,.4),c3=mix(tsK2,tsK3,.45);
  vec3 col=mix(c1,c2,smoothstep(-1.,1.,ps.y*.9+ps.x*.4))*.05+c3*.02*smoothstep(0.,-.7,ps.y);   // v20: the wash is a fifth of what it was: the ground is dark, the lines carry the colour
  // nebula: cheap domain-warped sine clouds (no hashing keeps the compile small)
  vec2 q=pn*2.3+vec2(.05,.03)*uTime;q+=.55*sin(q.yx*1.7+vec2(1.3,.4)-.04*uTime);
  float n=.5+.25*(sin(q.x*1.9+sin(q.y*2.3))+sin(q.y*2.1-1.1+sin(q.x*1.6+.7)));
  float n2=.5+.5*sin(q.x*.8-q.y*.9+2.);
  col+=mix(c3,c1,smoothstep(.25,.75,n2))*smoothstep(.26,.8,n)*(.05+.07*tsKick+.06*tsLo.x+.1*tsFl+.05*mv+.05*smoothstep(.8,.3,tsZE))*(1.-.6*exp(-r*r*7./(tsZs*tsZs)));
#if HD>=1
  // v19: nebula filaments: more ridged octaves of the same warped field, each one stopping where its wavelength reaches the pixel
  {vec2 f=q;float amp=.5,fq=1.,rg=0.,wA=0.;int oN=int(clamp(2.+1.3*uDetail,0.,14.));
   for(int o=min(int(uTime),0);o<14;o++){
     if(o>=oN)break;
     f=mat2(1.6,1.2,-1.2,1.6)*f+vec2(.7,1.3);f+=.3*sin(f.yx*1.7);fq*=2.;
     float wf=smoothstep(.34,.1,px*fq*2.3);
     rg+=amp*wf*(1.-abs(sin(f.x)*cos(f.y)));wA+=amp;amp*=.62;
   }
   rg=rg/max(wA,1e-3);
   col+=mix(c3,c1,smoothstep(.3,.8,n2))*pow(clamp(rg,0.,1.),5.)*(.16+.12*mv)*smoothstep(.2,.7,n)*(1.-.6*exp(-r*r*7./(tsZs*tsZs)));}
#endif
  // sparse stars, twinkling with the hats
  float sk=38.*pow(tsZE,.7);vec2 sg=p*sk,si=floor(sg);float sh=h21(si+7.3),spx=px*sk;
  vec2 so=.25+.5*vec2(sh,fract(sh*7.13));
  col+=mix(c2,vec3(1),.5)*smoothstep((1.3+.6*tsHatE)*spx,.2*spx,length(fract(sg)-so))*step(.84,sh)*(.3+(1.6*tsHat+1.2*tsHatE)*tsSq(fract(sh*31.7))+.7*tsLo.w+.3*tsLo.z);
#if HD>=1
  // v19: more star layers, each finer, faded out where a star would fall below a pixel; lit by the top end like the first layer
  {int nL=int(clamp(1.+.9*uDetail,0.,10.));
   for(int L=min(int(uTime),0);L<10;L++){
     if(L>=nL)break;
     float fL=float(L)+1.,sk2=38.*pow(tsZE,.7)*pow(1.62,fL);vec2 sg2=p*sk2+vec2(fL*3.1,fL*1.7),si2=floor(sg2);
     float s2=h21(si2+fL*11.),sp2=px*sk2;vec2 so2=.25+.5*vec2(s2,fract(s2*7.13));
     col+=mix(c1,c2,fract(s2*3.3))*smoothstep(1.1*sp2,.15*sp2,length(fract(sg2)-so2))*step(.88,s2)*smoothstep(.42,.14,sp2)*(.16+.9*tsHat*tsSq(fract(s2*31.7))+.3*tsLo.w);
   }}
#endif
  // v20 PENTAGRID. Behind everything, a quasicrystal: five families of parallel lines (de Bruijn's pentagrid, the plane slice of a
  // five-dimensional cubic lattice, so it belongs with the polytopes). Each family is one band (bass, low-mid, mid, high-mid,
  // presence) and brightens with it; on each beat of the bar one family hops a whole cell and lands on itself; dashes of light run
  // along the lines on the highs; the rhombic tiles between the lines carry a faint two-tone parity tint that the mids deepen.
  // It sits deeper than the hero (parallax), is infinite (a pulled-back view is never empty) and is dimmed behind the hero.
  {
    float kp=3.3*pow(tsZE,.55),bb=uBar*4.,keep=1.-.8*exp(-r*r*4.5/(tsZs*tsZs)),par=0.,edge=1e9;
    vec2 pg=p*kp+tsH*.3;vec3 pgc=vec3(0.);
#if HD>=1
    int nSc=HD>=3?3:2;
#else
    const int nSc=1;
#endif
    for(int sc=min(int(uTime),0);sc<nSc;sc++){
      float fs=float(sc),ksc=pow(1.618034,fs),vis=fs<.5?1.:smoothstep(.4,.12,px*kp*ksc*3.)*.6/fs;   // finer copies (higher tiers), each a golden ratio smaller, stop at the pixel
      for(int j=min(int(uTime),0);j<5;j++){
        float fj=float(j),an=fj*1.2566371+.3+uP5.w*.003+fs*.31;
        vec2 e=vec2(cos(an),sin(an));
        float hop=fj<3.5?smoothstep(0.,.4,clamp(bb-fj,0.,1.)):fract(uP5.w*.125);
        float x=dot(pg,e)*ksc+.2+.17*fj+hop*(1.-min(fs,1.)),y=dot(pg,vec2(-e.y,e.x))*ksc;
        float fx=floor(x+.5),d=abs(x-fx)/(kp*ksc);
        float bv=tsBandOf(fj+1.),hsh=fract(sin(fx*12.9898+fj*78.233+fs*3.7)*43758.5453);
        float ln=smoothstep(px*1.25,0.,d-px*.3);
        float run=smoothstep(.2,.03,abs(fract(y*.3-tsHp*.22*(hsh-.5)*2.+hsh*7.)-.5))*step(.3,hsh);
        pgc+=tsGrad(fj*.2+.08*hsh+.5)*ln*vis*(.07+.6*bv*bv+.6*tsWv(p))+mix(tsGrad(fj*.2+.08*hsh+.5),vec3(1.),.3)*smoothstep(px*2.2,0.,d-px*.6)*vis*run*hgh*3.6;
        if(sc==0){par+=fx;edge=min(edge,d);}
      }
    }
    // the tiles (stained glass): the cells between the lines light in concentric bands around the hero, every third band at a time, and
    // the lit bands step one band outward on every beat; inside a band the cells alternate two palette colours by the parity of their
    // five strip indices. The mids set how bright. Flat colour, inset from the lines, never under the hero.
    float bt=uP5.w,bnd=floor(r*3.4/tsZs),cls=mod(bnd-floor(bt),3.),sm=smoothstep(0.,.25,fract(bt));
    float lit=(cls<.5?sm:cls>1.5?1.-sm:0.),ins=smoothstep(px*2.,px*5.,edge);
    col+=(pgc+tsGrad(.15+.5*mod(par,2.)+bnd*.09)*ins*(.01+(.03+.58*mv)*lit))*keep*(.55+.45*hud);
  }
  col+=tsLatC;
  // ring tick = frequency (bass at the bottom)
  float x=1.-abs((id+.5)/N*2.-1.),sv=spec(.03+x*.9);
  // hero bloom: the low end swells it wider and brighter
  col+=c1*(.03+.07*tsKick+.06*bsw+.26*tsFl)*exp(-r*r*(10.-3.*bsw-2.5*tsKick)/(tsZs*tsZs))*(form>1.5?.5:1.);
  {
    // volumetric light beams from the hero, brightness by the four mid/high bands, turning slowly with the beat
    float NR=16.,ra=a/TAU*NR+uP5.w*.0625,ri=mod(floor(ra),NR),rf=fract(ra)-.5;
    float bs=dot(tsBand,max(1.-abs(3.*(1.-abs((ri+.5)/NR*2.-1.))-vec4(0,1,2,3)),0.));
    {float rw=abs(rf)*TAU/NR*r;   // v20: each beam is a crisp ray with a faint core of glow, not a fat wedge of haze
     col+=mix(c1,c2,fract(ri*.37))*(smoothstep(px*1.6,0.,rw-px*.6)*.8+exp2(-rf*rf*26.)*.14)*smoothstep(.06,.4,r)*exp(-r*1.3)*(.06+.95*bs+.09*tsKick+.08*bsw)*hud;}
    // guide ring at the spectrum ring's base (the finer concentric guides were cut for compile budget)
    col+=c1*.25*smoothstep(px*1.5,0.,abs(r-R0+.006))*hud;
    // spectrum ring: bold segmented bars, mirrored left/right, bass at the bottom; a loud bin reaches far out
    float sv3=clamp((sv-.1)*1.25,0.,1.),len=.012+.3*sv3*sv3,ta=abs(fract(ai*N)-.5)*TAU/N*r,seg=abs(fract((r-R0)/.021)-.5)*.021;
    col+=mix(tsGrad(x*.5),vec3(1.),.25*smoothstep(R0,R0+len,r))*smoothstep(px*1.1,0.,ta-.0042*r/R0)*smoothstep(px,0.,seg-.0085)*smoothstep(px,0.,R0-r)*smoothstep(px,0.,r-R0-len)*(.35+1.5*sv3)*hud;
  }
  // ---- kick shockwaves: a crisp polygon front (the ring's symmetry) leaves the hero on every kick, with a soft wake
  // behind it, and lights whatever it passes (satellites, tsWv). Light only.
  {float nw=max(tsRingN,5.),an=a+uP5.w*.2,rp=r*cos(mod(an,TAU/nw)-3.14159/nw)/cos(3.14159/nw);
   for(int i=0;i<2;i++){float f=i==0?tsWF.x:tsWF.y,am=i==0?tsWA.x:tsWA.y;
     float dw=rp-f;
     float dash=smoothstep(-.25,.25,sin(an*nw*5.));
     col+=mix(c1,vec3(1.),.6)*am*dash*smoothstep(px*1.8,0.,abs(dw)-px*.7)*1.3;
     col+=mix(c1,c2,.5)*am*.3*exp(min(dw,0.)*9.)*step(dw,0.);}}
  // ---- high glitter: fine crossed dust (screen space, so it never blurs) that only the highs light
  if(hgh>.02){
    vec2 gq=scr()*46.*pow(tsZE,.12),gi=floor(gq),gf=fract(gq)-.5;
    vec2 dg=gf-(vec2(fract(gi.x*7.13+gi.y*3.71),fract(gi.x*3.71-gi.y*7.13))-.5)*.62;
    float gd=length(dg),tw=.55+.45*sin(uTime*(1.1+1.7*fract(gi.x*.37+gi.y*.73))+gi.x*.7+gi.y*1.3);
    float cr0=smoothstep(.11,0.,min(abs(dg.x),abs(dg.y)))*smoothstep(.34,0.,gd)*step(.6,fract(gi.x*1.7+gi.y*.9));
    col+=mix(tsK0,tsK2,fract(gi.x*.31+gi.y*.17))*(smoothstep(.17,0.,gd)*.85+cr0*1.1)*smoothstep(.05,.8,hgh)*tw*(.5+.5*hud)*1.4;
  }
  // ---- hat sparks: short radial dashes streaming out of the hero, lit only by the top end
  if(hgh>.02){
    float ag=(a/TAU+.5)*44.,ai2=floor(ag),rw=log(r+.05)*5.2-tsHp*.55+fract(ai2*.37)*9.,ri2=floor(rw),hs=h21(vec2(ai2,ri2)+3.1);
    float cd=abs(fract(ag)-.5-(hs-.5)*.55)*TAU/44.*r,ad=abs(fract(rw)-.5);
    col+=mix(tsGrad(hs),vec3(1.),.35)*step(.68,hs)*smoothstep(px*1.3,px*.3,cd)*smoothstep(.34,.12,ad)*smoothstep(.1,.28,r)*(.1+3.3*hgh);
  }
  return col;
}
// per-pixel instances chosen once before the job loop, two slots per formation (x = near layer, y = far layer):
// type, angles, centre, scale, intensity, hue, line width, vertex rings, colour spread, fill strength
vec2 tsXty,tsXS,tsXI,tsXT,tsXlw,tsXvr,tsXsp,tsXhz,tsXfl;vec4 tsXan0,tsXan1,tsXC;
vec2 tsCC;vec4 tsCan;float tsCT,tsCI;
void tsPrep(float form){
  vec2 p=tsP;float br=uP3.x;
  // the colossal lattice: giant polytopes far bigger than the frame, turning slowly on their own, with light trains
  // on their edges and large vertex nodes; it fades in as the view pulls back
  vec2 g=vec2(8.2,7.),ci=floor((p-tsH*.5)/g+.5);float cid=ci.x+7.*ci.y;
  tsCC=ci*g+tsH*.5;tsCan=uP5.w*vec4(.019,.031,.013,.025)+cid*vec4(.9,.4,1.3,.2);tsCT=.5+cid*.13;
  tsCI=1.45*smoothstep(.97,.4,tsZE)*(1.-.3*step(.5,abs(ci.x)+abs(ci.y)))*(.85+.4*tsLo.y);
  tsXlw=vec2(.0013,.001);tsXvr=vec2(1,0);tsXsp=vec2(.45,.35);tsXhz=vec2(.3,.2*tsZE);tsXfl=vec2(0.);tsLatC=vec3(0.);
  if(form>1.5&&form<2.5){
    // GRID: a backdrop of large crisp wireframes framing the hero: columns scroll alternately up and down, column =
    // frequency (centre bass, edges treble); cells fade out as they pass behind the hero. Pulled back, cells grow
    // (deeper than the colossal lattice), so the grid never shrinks to mush.
    float cs=tsGc,ci=floor(p.x/cs),dir=mod(ci,2.)<.5?1.:-1.;
    float yo=p.y+dir*uP5.w*.5*cs+(tsLay>.5?mod(ci,2.)*.5*cs:0.);
    float cj=floor(yo/cs+.5);
    vec2 l=vec2(p.x-(ci+.5)*cs,yo-cj*cs);
    float x=clamp((abs(ci+.5)-.5)/3.,0.,1.),sv=spec(.04+x*.82);
    tsXC.xy=p-l;tsXty.x=mod(ci+cj,2.)<.5?tsTB:tsTC;
    tsXfl.x=dir<0.?1.:0.;tsXan0=vec4(ci*.6,cj*.45,(ci-cj)*.3,ci*.2);
    tsXS.x=cs*.3*br*(.86+.22*sv);tsXlw.x=.0019;tsXhz.x=.12;tsXsp.x=.75;
    tsXI.x=(.7+1.*sv+1.3*tsWv(tsXC.xy))*smoothstep(.5*cs,.44*cs,max(abs(l.x),abs(l.y)))*smoothstep(.3,.5,length(tsXC.xy-tsH)/tsZs);
    tsXT.x=x*.5+cj*.23+ci*.11;
  }
  // far constellation field: a brick grid of dim polytopes at several depths drifting slowly upward, kept clear of the
  // hero; it sits deeper than the hero, so it moves less with the view zoom (parallax). Pulled back, lattice lines
  // join its cells into a honeycomb.
  float fc=.21*pow(min(tsZE,1.),-.6),kz=pow(tsZE,.5);vec2 q0=p*kz,q=q0+vec2(0.,uP5.w*.03)-tsH*.12;
  float rr=floor(q.y/fc+.5);q.x+=mod(rr,2.)*.5*fc;float cc=floor(q.x/fc+.5);
  vec2 l=q-vec2(cc,rr)*fc;
  float hh=h21(vec2(cc,rr)+17.),h2=fract(hh*7.31+.17),dep=fract(hh*13.7);
  tsXC.zw=(q0-l)/kz;tsXty.y=h2<.45?0.:h2<.8?1.:4.;
  tsXfl.y=hh<.5?0.:1.;tsXan1=vec4(hh,h2,dep,hh*h2)*6.28;
  float bvF=tsBandOf(hh*64.);tsXS.y=fc*(.1+.12*dep)*br/kz*(.92+.28*bvF);tsXT.y=.5+hh*.6;
  vec2 hc=tsXC.zw-tsH;hc.x=abs(hc.x)-.42*tsTw;
  float clr=form<.5?smoothstep(.12,.4,length(tsXC.zw)):smoothstep(.3,.5,length(hc)/tsZs);
  tsXI.y=step(.3,hh)*(.1+.36*dep*dep)*(.55+1.5*bvF+2.*tsWv(tsXC.zw))*clr*(form>1.5&&form<2.5?.6:1.)*(1.4-.4*smoothstep(.2,.85,tsZE))*smoothstep(.5*fc,.4*fc,max(abs(l.x),abs(l.y)));
  float lat=smoothstep(.85,.4,tsZE),ld=min(abs(l.x),abs(l.y))/kz;
  tsLatC=tsK1*lat*(.07+.1*tsBand.x)*clr*smoothstep(tsPx*1.4,0.,ld-tsPx*.25)*smoothstep(.2*fc,.32*fc,length(l));
  if(form>1.5&&form<2.5){}else if(form<.5){
    // NEST side columns: mirrored constellations rising on the left and falling on the right
    float sd=p.x<0.?-1.:1.,cs=.25,yo=p.y+sd*uP5.w*.25*cs,cj=floor(yo/cs+.5);
    tsXC.xy=vec2(sd*.76,cj*cs-sd*uP5.w*.25*cs);tsXty.x=mod(cj,2.)<.5?tsTC:tsTB;
    tsXfl.x=sd<0.?1.:0.;tsXan0=vec4(cj*.7,0.,cj*.4,0.);tsXS.x=.06*br;
    tsXI.x=.8*(.55+1.1*tsBandOf(cj*3.+step(0.,sd)))*smoothstep(.5*cs,.42*cs,abs(yo-cj*cs))*smoothstep(.3,.75,tsZE);tsXT.x=.5+cj*.23;tsXlw.x=.0016;tsXhz.x=.15;
  }else{
    // CORE/FLY constellation ring around the hero: the nearest copy by angular sector on an ellipse, orbiting
    // with the beat and breathing on a beat-locked pulse (smooth, never a raw kick)
    vec2 pc=p-tsH;float bc=1.-.22*uP3.z,rx=(.66+.08*tsTw)*bc,ry=.475*bc;
    float N=tsRingN,off=uP5.w*.25*TAU/N,sec=mod(floor((atan(pc.y*rx/ry,pc.x)-off)/TAU*N+.5),N),ac=sec*TAU/N+off;
    tsXty.x=tsTC;tsXfl.x=mod(sec,2.);tsXan0=sec*vec4(.9,.5,.3,.7);tsXC.xy=tsH+vec2(cos(ac)*rx,sin(ac)*ry)*(1.+.14*tsBandOf(sec*3.+1.));
    float bvR=tsBandOf(sec*3.+1.);float wR=tsWv(tsXC.xy);tsXS.x=.05*br*(1.+.22*tsPulse)*(.72+.95*bvR+.45*wR);tsXI.x=form>2.5?0.:.95*(.55+1.1*bvR+1.6*wR);tsXT.x=.25+sec*.11;
  }
}
// draw job j of the current formation; returns false when there are no more jobs
bool tsJob(int j,float form,out float ty,out vec4 an,out vec2 C,out float S,out float lw,out float I,out float T,out float vr,out float sp){
  float br=uP3.x,bu=uP3.z;
  vr=0.;C=vec2(0.);ty=tsTA;an=vec4(0.);T=0.;sp=1.;lw=.0016;I=0.;S=.1;tsMir=1.;tsHzK=0.;tsFlip=0.;tsBeadN=1.;tsVRm=3.2;tsKH=0.;tsBK=.4;
  if(j<2){
    // the two per-pixel slots: 0 far layer, 1 near layer
    bool y=j==0;
    ty=y?tsXty.y:tsXty.x;an=y?tsXan1:tsXan0;C=y?tsXC.zw:tsXC.xy;S=y?tsXS.y:tsXS.x;I=y?tsXI.y:tsXI.x;T=y?tsXT.y:tsXT.x;
    lw=y?tsXlw.y:tsXlw.x;vr=y?tsXvr.y:tsXvr.x;sp=y?tsXsp.y:tsXsp.x;tsHzK=y?tsXhz.y:tsXhz.x;tsFlip=y?tsXfl.y:tsXfl.x;
    return true;
  }
  if(j==2){
    // the colossal lattice (placed in tsPrep)
    tsBK=0.;C=tsCC;ty=tsTD;tsFlip=2.;an=tsCan;S=2.5*(1.+.03*tsLo.x);lw=.0034;vr=1.;sp=.28;tsBeadN=12.;tsVRm=4.5;tsHzK=.45;T=tsCT;I=tsCI;
    return true;
  }
  if(form<.5||form>2.5&&j>3){
    // NEST: shells born at the centre every two beats, growing outward, alternating polytope families.
    // FLY: the same endless zoom, but every shell is a lattice plane of polytopes (alternate cells counter-rotate, each
    // plane lit by its own band), so the camera flies through a honeycomb (branch-free)
    float z=uP5.w*.5,fz=fract(z),id=floor(z)-float(j-3),fy=step(2.5,form);
    S=.018*pow(2.1,float(j-3)+fz)*br;
    float m3=mod(id,3.),g=S*6.;ty=m3<.5&&fy<.5?tsTA:m3<1.5?tsTB:tsTC;
    vec2 cl=floor((tsP-tsH)/g+.5)*fy;C=tsH+cl*g;
    tsFlip=mod(cl.x+cl.y+id,2.);an=id*vec4(.7,.4,1.1,.3)+cl.xyxy*vec4(.7,.5,.3,.9);
    lw=.0011+.006*S;T=id*.17;sp=.8;
    I=(1.1+.4*tsKick)*(1.-fy*.0+(1.-fy)*(.75*dot(tsBand,vec4(equal(vec4(mod(id,4.)),vec4(0.,1.,2.,3.))))-.3))*smoothstep(mix(.025,.03,fy),mix(.08,.07,fy),S)*smoothstep(mix(.68,.7,fy),mix(.36,.3,fy),S)
      *(1.+fy*(.6*dot(tsBand,vec4(equal(vec4(mod(id,4.)),vec4(0,1,2,3))))-.45))
      *mix(1.,smoothstep(.25,.45,length(C-tsH)/tsZs)*smoothstep(3.4,2.4,length(cl)),fy);
    vr=step(.06,S)*step(S,.5);tsHzK=.25*smoothstep(.6,.15,S);
    return S<mix(.68,.7,fy);
  }
  // CORE / GRID: 3 hero, 4 inner shell; FLY: 3 hero. Mirrored twins: each pixel draws the twin on its own
  // side (the hero frame is folded like the backdrop)
  if(j>4)return false;
  float S0=.285*br*(1.-.06*bu)*tsZs,sd=tsTw>.5&&tsP.x<tsH.x?-1.:1.;
  C=tsH+vec2(sd*.42*tsTw,0.);tsMir=sd;
  if(j==3){S=S0;lw=.0034;I=1.15+.35*tsKick;vr=1.;tsBK=1.;tsHzK=.5-.2*tsTw+.8*tsFl;tsKH=.9*max(uO1.x,uO1.y);}
  else{
    // the inner shell is the mids' instrument: it swells and brightens with the mid bands
    float md=.5*(tsBand.x+tsBand.y);
    ty=tsTB;tsFlip=1.;an=vec4(.5,1.,0.,2.);S=S0*(.3+.42*md);tsBK=1.;lw=.0024;I=(.5+.9*md)*(1.-uP3.w);T=.5;tsHzK=(.5-.3*tsTw)*(.6+.6*md);}
  return true;
}
#if HD>=1
// v19: extra instances per tier, drawn by the same loop. The first ones: a nest of thin companion polytopes round the hero (more of them per tier). Everything else: further constellation
// layers, each finer and deeper than the last, with the same keep-clear of the hero as the first layer
void tsJobX(int x,float form,out float ty,out vec4 an,out vec2 C,out float S,out float lw,out float I,out float T,out float vr,out float sp){
  float fx=float(x),br=uP3.x;
  vr=0.;sp=.7;lw=.0011;tsMir=1.;tsHzK=0.;tsBeadN=1.;tsVRm=3.2;tsKH=0.;tsBK=.25;tsFlip=mod(fx,2.);
  float nSh=floor(clamp(3.+1.6*uDetail,0.,18.));
  if(fx<nSh){
    // the nest of companions: thin polytopes of every type at stepped scales through and beyond the hero, each on its own rotation and band
    float S0=.285*br*(1.-.06*uP3.z)*tsZs,sd=tsTw>.5&&tsP.x<tsH.x?-1.:1.,m3=mod(fx,3.);
    C=tsH+vec2(sd*.42*tsTw,0.);tsMir=sd;
    ty=m3<.5?tsTC:(m3<1.5?tsTB:tsTA);an=vec4(1.1,.4,2.,.7)*(fx+1.);
    S=S0*(.62+.13*fx);T=.2+.17*fx;lw=.0009;I=.14*(.6+.8*tsBandOf(fx+2.))/(1.+.1*fx);
    return;
  }
  float L=fx-nSh+1.,fc=.21*pow(min(tsZE,1.),-.6)*pow(.84,L),kz=pow(tsZE,.5+.06*L);
  vec2 q0=tsP*kz,q=q0+vec2(0.,uP5.w*(.03+.008*L)*(mod(L,2.)*2.-1.))-tsH*max(.12-.015*L,0.);
  float rr=floor(q.y/fc+.5);q.x+=mod(rr,2.)*.5*fc;float cc=floor(q.x/fc+.5);
  vec2 l=q-vec2(cc,rr)*fc;
  float hh=h21(vec2(cc,rr)+17.+L*9.),h2=fract(hh*7.31+.17),dep=fract(hh*13.7);
  C=(q0-l)/kz;ty=h2<.5?0.:(h2<.85?1.:4.);tsFlip=hh<.5?0.:1.;an=vec4(hh,h2,dep,hh*h2)*6.28;
  S=fc*(.14+.14*dep)*br/kz;T=.5+hh*.6+L*.11;lw=.0009;
  vec2 hc=C-tsH;hc.x=abs(hc.x)-.42*tsTw;
  float clr=form<.5?smoothstep(.12,.4,length(C)):smoothstep(.3,.5,length(hc)/tsZs);
  // a polytope only a few pixels wide piles all its edges onto the same pixels and sums to white: each layer appears only once its polytopes are large enough to read
  I=step(.35,hh)/(1.+.1*L)*(.05+.17*dep*dep)*(.55+1.1*tsBandOf(hh*64.)+1.2*tsWv(C))*clr*smoothstep(.5*fc,.4*fc,max(abs(l.x),abs(l.y)))*smoothstep(13.,34.,S/tsPx);
}
#endif
void realm(){
  tsZE=uZoom*uM2[1].x;tsGc=.34/pow(tsZE,.72);
  vec2 p=scr()/tsZE;
  tsPx=1./(uRes.y*tsZE);tsP=p;tsPalInit();tsLz=pow(tsZE,-.45);
  // edge families = low-mid, mid, high-mid, presence; their onsets flash them
  // shaped bands from JS (spectrum share x envelope, zero in silence), 6 bits each
  {float a=uM1[2].z,b=uM2[1].y;
   vec4 A=mod(floor(a/vec4(1.,64.,4096.,262144.)),64.)/63.,B=mod(floor(b/vec4(1.,64.,4096.,262144.)),64.)/63.;
   tsBand=vec4(A.xyz,B.x);tsLo=vec4(B.w,A.w,B.yz);}
  tsBOn=vec4(uO1.z,uO1.w,uO2.x,uO2.y);
  // vertex sparks: the highs and air (envelopes) plus their onsets
  tsSpk=clamp(.5*tsLo.z+1.1*max(uO2.z,uO2.w)+.6*tsLo.w+(.55+.45*uP3.z)*uHat,0.,1.3);
  tsSrc=vec4(uM2[0],0.);tsSrc.w=sqrt(max(1.-dot(tsSrc.xyz,tsSrc.xyz),0.));tsDW=floor(uM2[2].x/32.)/1000.;
  vec4 g0=uP1,g1=vec4(uM1[0],uM1[1].x),g2=vec4(uM1[1].yz,uM1[2].xy);
  tsG=mat4(g0,g1,g2,vec4(-dot(g0.yzw,cross(g1.yzw,g2.yzw)),dot(g0.xzw,cross(g1.xzw,g2.xzw)),-dot(g0.xyw,cross(g1.xyw,g2.xyw)),dot(g0.xyz,cross(g1.xyz,g2.xyz))));
  tsSnT=uP4.x;tsFl=uP4.y;tsHp=uP4.z;tsKick=mod(floor(uP4.w),1000.)*.001;tsShr=fract(uP4.w);tsHat=max(uHat*(.85+.4*tsLo.w),.8*tsLo.w);tsKS=.2+1.5*vec4(equal(vec4(floor(floor(uP4.w)/1000.)),vec4(0.,1.,2.,3.)));tsEx=uP3.y;
  tsTA=mod(uP2.x,16.);tsTB=mod(floor(uP2.x/16.),16.);tsTC=mod(floor(uP2.x/256.),16.);tsTD=mod(floor(uP2.x/4096.),16.);tsHatE=floor(uP2.x/65536.)/63.;tsForm=uP2.y;
  {float tw=uM2[1].z,sk=floor(tw*.5);tsTw=mod(tw,2.);vec2 age=vec2(mod(sk,2048.),floor(sk/2048.))/2047.;
    tsWF=(.1+2.1*age*(2.-age))/max(sqrt(tsZE),.4);tsWA=vec2(tsSq(1.-age.x),tsSq(1.-age.y));}
  float lr=mod(uM2[2].x,32.);tsLay=mod(lr,2.);tsRingN=floor(lr*.5);tsPulse=mod(uM2[2].z,1024.)/1023.;tsBst=.2*floor(uM2[2].z/1024.)/1023.;
  float form=tsForm,exFade=1./(1.+tsEx*1.5);
  tsH=form>.5?uP2.zw:vec2(0.);tsUnf=uP3.w;
  {float th=tsUnf*1.5708,sm=tsUnf*tsUnf*(3.-2.*tsUnf);tsUA=vec4(sin(th),cos(th),-cos(2.*th),sin(2.*th));tsUsh=vec4(0,0,-.5,.5)*sm;tsUsc=1./(1.+.75*sm);}if(form<.5||form>2.5)tsTw=0.;
  tsZs=mix(1.,.6,tsTw)*(1.-.3*min(length(tsH),.5));
  // string amplitudes: bass/kick bow, mids ripple, highs shiver (fractions of the edge length)
  tsAB=.035*clamp(.6*tsLo.x+.9*tsLo.y,0.,1.)+.075*tsBst/.2;tsAM=.018;tsAH=0.;tsAmp=.2*(tsAB+.5);
  tsAcc=vec3(0.);tsPrep(form);
#if HD>=1
  float xg=0.;int jx=0,nX=int(clamp(2.+1.5*uDetail,0.,20.));
  for(int j=min(int(uTime),0);j<29;j++){
#else
  for(int j=min(int(uTime),0);j<9;j++){
#endif
    float ty,S,lw,I,T,sp,vr;vec4 an;vec2 C;
#if HD>=1
    if(xg<.5&&!tsJob(j,form,ty,an,C,S,lw,I,T,vr,sp))xg=1.;
    if(xg>.5){if(jx>=nX)break;tsJobX(jx,form,ty,an,C,S,lw,I,T,vr,sp);jx++;}
#else
    if(!tsJob(j,form,ty,an,C,S,lw,I,T,vr,sp))break;
#endif
    tsDraw(ty,an,C,S,lw,I*(j==2?1.:exFade),T,vr>.5,sp);
  }
  float hud=1.-.75*smoothstep(0.,.5,tsEx);
  vec3 col=tsBg(p,form,.46*uP3.x*tsZs,.42*tsTw,hud)+tsAcc*1.25;
  // keep overlaps of different hues from washing toward white: a gentle saturation lift
  {float mC=max(col.r,max(col.g,col.b));col*=mC>1.25?(1.25+.4*(1.-exp(-(mC-1.25)/.4)))/mC:1.;}
#if HD>=1
  fragColor=vec4(max(mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.42+.02*float(HD)),0.),0.);
#else
  fragColor=vec4(max(mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.42),0.),0.);
#endif
}
`;
