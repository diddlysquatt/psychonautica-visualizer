// KNOTT palettes (sRGB hex, five band colours + deep background), compiled into the shader as linear RGB.
const knottPals = [
  ['ff2a6d', 'ff7b00', 'ffd23f', '00e5ff', '8a2bff', '0b0322'],
  ['c6ff00', '00ffa3', '00b3ff', 'ff00e5', 'ffe600', '020e12'],
  ['ff4d6d', 'ffb703', '4cc9f0', '9d4edd', 'ff70a6', '15041f'],
  ['1e3cff', '00e0ff', '9dff6a', 'ff8a00', 'ff2e4c', '02061a'],
  ['00e676', 'ffd600', 'ff3d7f', '8c1eff', '00e5ff', '02100a'],
  ['5b7cff', 'ffd23f', 'ff2e93', '00f0c0', 'a24dff', '0a0124']
];
const R_KNOTT = `
// KNOTT. Living multi-scale Truchet knotwork: neon tube bands on square, triangle and hex lattices. Square and
// triangle tiles connect at the thirds of every edge, which is self-similar under halving, so a quadtree can split
// any cell into four finer tiles whose bands still meet the coarse ones. Each beat a wave of tiles turns a quarter
// (one group of a cycle sweeps across the screen), snares add cascades, light pulses flow along the bands.
// uniforms: uP1 = (tiles per screen height, pan x, pan y, flip counter), uP2 = (flow phase, family+4*epoch now + .9*lens,
// family+4*epoch before the wipe, wipe 0..1), uP3 = (kick, hats/2, build, bassline light), uP4 = eight
// smoothed spectrum bands packed in pairs, uP5 = (giant knot presence, giant knot turn counter, medallion spacing,
// medallion opening), uM1/uM2 columns = the five palette colours + background (blended and hue-rotated in JS).
#define KN_RING (.1+.25*fract(uSeed.z*5.7))
#define KN_PIN (KN_RING+.25+.3*fract(uSeed.w*3.3))
// hats (fraction of uP3.y, from JS): the high/air band envelopes and their onsets light the beads racing along the cores
#define KN_HAT (fract(uP3.y)*2.)
// kick: light envelope (snappy, fraction of uP3.x) and geometry envelope (smoothed >=80 ms attack, integer part / 999)
#define KN_KL fract(uP3.x)
#define KN_KG (floor(uP3.x)/999.)
// v20b snare counter (integer part of uP3.z; the build is its fraction): every snare flips the over/under of every crossing
#define KN_SN floor(uP3.z)
vec3 kc0,kc1,kc2,kc3,kc4,kbg;
vec4 kBa,kBb;
float kGlow,kMinD,kOut,kPr,kMd,kFz,kPl,kEd,kPn=0.;
// eight smoothed spectrum bands, packed two per component of uP4 (even bands in the integer part / 999)
float knB(float x){
  float i=clamp(x,0.,1.)*7.;vec4 kBa=floor(uP4)/999.,kBb=fract(uP4);
  return dot(kBa,max(1.-abs(i-vec4(0.,2.,4.,6.)),0.))+dot(kBb,max(1.-abs(i-vec4(1.,3.,5.,7.)),0.));
}
// medallion lattice in lens space u (screen units at zoom 1): a hex lattice of spacing uP5.z; the centre site is the
// focal lens, the others are smaller medallions that open in a ripple (uP5.w) on about 60% of the sites. Each frames
// one knot of the tapestry at about 1.3x scale. Returns the lens radius (0 = closed), lv = offset from the site.
float knLens(vec2 u,out vec2 lv,out vec2 lid){
  float D=max(uP5.z,.5);vec2 hs=vec2(1.,1.7320508)*D,a=mod(u,hs)-.5*hs,b=mod(u-.5*hs,hs)-.5*hs;
  lv=dot(a,a)<dot(b,b)?a:b;lid=floor((u-lv)/(D*vec2(.5,.8660254))+.5);
  float h=h21(lid*.731+3.1),so=clamp(uP5.w*1.7-h*.7,0.,1.);
  so=so*so*(3.-2.*so)*step(h,.5);
  return dot(lid,lid)<.5?(.17+.01*sin(uMT*.37))*fract(uP2.y)/.9:(.15+.12*h)*so*min(D/1.25,1.);
}
// palette lookup between neighbouring entries (eased weights of the five entries, wrapping); mid-blend chroma is pushed
// back up so it never passes through grey
vec3 knPal(float t){
  vec3 d=smoothstep(1.,0.,abs(mod(t-vec3(0.,1.,2.)+2.5,5.)-2.5));vec2 e=smoothstep(1.,0.,abs(mod(t-vec2(3.,4.)+2.5,5.)-2.5));
  vec3 m=uM1*d+uM2*vec3(e,0.);float f=max(max(d.x,d.y),max(d.z,max(e.x,e.y))),l=dot(m,vec3(.3333));
  return max(l+(m-l)*(1.+1.6*f*(1.-f)),0.);
}
float kRot;
float knPulse(float x){float c=fract(x),t=min(c*1.087,1.);t*=t;t*=t;return t*t*smoothstep(1.,.92,c);}
// position (0..1) of a screen point inside the sweep of flip group g of cycle k
float knSweep(vec2 sp,float g,float k){
  // (low-discrepancy sequences over group and cycle instead of hashes: cheaper to compile)
  float hh=fract(g*.618034+k*.381966+uSeed.x*13.),st=fract(fract(k*.754878+g*.569840+uSeed.y*7.)*.7+fract(uSeed.w*7.31));
  // linear sweep in one of eight directions, ripple out from the centre, implode, or twin parallel fronts
  float a=floor(hh*8.)*PI*.25,r=clamp(length(sp)*1.05,0.,1.),l=dot(sp,vec2(cos(a),sin(a)));
  return st<.4?clamp(l*.55+.5,0.,1.):(st<.65?r:(st<.8?1.-r:fract(l*1.1+.5)));
}
// flip state of a cell: x = cycle index (completed turns), y = progress of this cycle's turn
vec2 knFlip(vec2 id,float L,vec2 sp){
  float M=8.,c=uP1.w,k=floor(c);
  float g=floor(h21(id*.7311+vec2(L*31.7+k*1.618,k*.917+L*5.3))*M);
  float s=knSweep(sp,g,k);
  return vec2(k,clamp((c-k-(g+s*.4)*.88/M)*M/.95,0.,1.));
}
// arc around centre V: start direction e, radius r, counter-clockwise sweep S, v = point - V; round caps past the ends.
// returns (distance to the centreline, 0..1 along the arc)
// arctangent (polynomial, error ~1e-5 rad): far fewer instructions than atan(y,x) on D3D
float knAt(float y,float x){
  float ax=abs(x),ay=abs(y),m=min(ax,ay)/max(max(ax,ay),1e-6),q=m*m;
  float r=((-.0464965*q+.1593142)*q-.3276228)*q*m+m;
  r=ay>ax?1.5707963-r:r;r=x<0.?PI-r:r;return y<0.?-r:r;
}
float kSd;
vec2 knArc(vec2 v,vec2 e,float r,float S){
  vec2 l=vec2(dot(v,e),e.x*v.y-e.y*v.x);
  float a=knAt(l.y,l.x+1e-6);
  if(a>=0.&&a<=S){kSd=length(l)<r?-1.:1.;return vec2(abs(length(l)-r),a/S);}
  float d0=length(l-vec2(r,0.)),d1=length(l-r*vec2(cos(S),sin(S)));
  return d0<d1?vec2(d0,0.):vec2(d1,1.);
}
// straight hex bar from x=.5 (u=0) to x=-.5 (u=1)
vec2 knBar(vec2 q){float x=clamp(q.x,-.5,.5);kSd=q.y<0.?-1.:1.;return vec2(length(vec2(q.x-x,q.y)),.5-x);}
// palette index (0..4) of a band end: a world-space colour field, softly quantised (flat steps joined by short
// ramps), sampled at the band's end points. Connection points are shared by the two tiles that meet there, so each
// tube is one pure palette colour inside a colour region and blends to the next colour over one segment where it
// crosses a region border; 4-5 palette colours share the frame. A turning tile carries its colours round smoothly.
float kEp;
// (two points at once; the regions grow when zooming out, about the camera centre)
vec2 knCI(vec2 a,vec2 b){float z=sqrt(clamp(uZoom,.15,1.));vec2 o=uP1.yz*(1.-z)+kEp*vec2(13.7,-7.9);mat2 W=mat2(a*z+o,b*z+o);
  vec2 f=vec2(.43,.24)*W+1.9*sin(vec2(.69,.4)*W)+1.5*sin(vec2(-.34,.75)*W+2.),i=floor(f);return i+smoothstep(.85,1.,f-i);}
// palette coordinate along a band from end colour a to b, wrapping the short way round the palette
float knT(float a,float b,float u){return a+(mod(b-a+2.5,5.)-2.5)*u;}
// band slot i of a tile. Square (q centred, unit size; thirds): rings = four inner arcs, pinwheel = four crossing outer
// arcs (a woven square knot), nests = inner + outer arcs at two opposite corners. Triangle (q centred on the
// centroid, unit side; thirds): three inner arcs, triskele weave, nest + bump. Hex (unit width; midpoints): three
// arcs, or a straight bar with two arcs. Outputs the arc (V,e,r,S), pulses per segment n, weave height terms
// (h = hs*(u-.5)+hc) and the flow-direction bit; returns 1 for the hex bar, -1 for an empty slot.
float knSlot(float fam,float ty,float i,float b0,out vec2 V,out vec2 e,out vec4 rs,out vec3 hb){
  bool rg=ty<KN_RING,wv=!rg&&ty<KN_PIN,ns=!rg&&!wv,sq=fam<.5,tr=!sq&&fam<1.5,t0=ty<KN_RING+.25;
  // square: corner k (A,B,C,D counter-clockwise), arcs sweep a quarter turn from the edge direction e
  float k=ns?floor(i*.5)*2.:i;
  float r=rg?.33333:(wv?.66667:(mod(i,2.)<.5?.33333:.66667));
  // triangle: vertex kt (centroid-relative), sixth-turn arcs; the nest's third slot is the bump on edge V1V2
  bool bump=ns&&i>1.5;
  float kt=ns?0.:i,rt=bump?.166667:(ns?(i<.5?.33333:.66667):(wv?.66667:.33333));
  // hex: arc around vertex kh joining edges kh and kh+1, a third of a turn
  float kh=t0?2.*i:(i<1.5?1.:4.);
  // every lattice is rotationally symmetric: slot geometry = the first corner's turned by the slot's index
  float an=sq?k*1.5707963:(tr?kt*2.0943951:kh*1.0471976),ca=cos(an),sa=sin(an);
  mat2 Rk=mat2(ca,sa,-sa,ca);
  V=Rk*(sq?vec2(-.5):(tr?vec2(-.5,-.2886751):vec2(.5,.2886751)));
  e=Rk*(sq||tr?vec2(1.,0.):vec2(-.8660254,.5));
  if(tr&&bump){V=vec2(.25,.1443376);e=vec2(-.5,.8660254);}
  float R=sq?r:(tr?rt:.288675);
  rs=vec4(R,sq?1.5707963:(tr?(bump?PI:1.0471976):2.0943951),R>.5?2.:(sq||tr?1.:2.),0.);
  hb=vec3(sq?(wv?-1.:0.):(tr&&wv?1.:0.),sq&&ns?(i==1.?.2:(i==3.?-.2:0.)):0.,
          sq?abs(mod(k,2.)-b0):(tr?0.:((!t0&&i<1.5)?1.-b0:b0)));
  if(!sq&&!tr&&!t0&&i<.5){hb.z=1.-b0;rs.z=3.;}
  return (!sq&&!tr&&!t0&&i<.5)?1.:((!sq&&i>2.5)?-1.:0.);
}
#if HD>=1
// v19 detail tiers. Ceilings by tier; runtime counts from uDetail; loops start at a zero the HLSL compiler cannot fold.
#define KN_H0 min(int(uTime),0)
#if HD>=5
#define KN_HR 64
#define KN_HB 24
#define KN_HE 5
#define KN_HL 7
#elif HD>=4
#define KN_HR 40
#define KN_HB 15
#define KN_HE 4
#define KN_HL 6
#elif HD>=3
#define KN_HR 26
#define KN_HB 9
#define KN_HE 4
#define KN_HL 5
#elif HD>=2
#define KN_HR 20
#define KN_HB 8
#define KN_HE 3
#define KN_HL 5
#else
#define KN_HR 14
#define KN_HB 5
#define KN_HE 3
#define KN_HL 5
#endif
#endif
float kPh,kSpk,kFl;
// phrase look of the bands (kSty, from the phrase epoch, so a new look wipes in with each phrase): 0 neon tube,
// 1 Celtic ribbon (flat band, double border lines), 2 rope braid (plaited strands), 3 chain (alternating links).
// kBL: light of the joint beads (vocal range: hi-mid/presence envelopes and onsets, spread by the screen-region band)
float kSty,kBL;
vec3 knTube(float ds,float w,float px,float u,float n,float bm,vec3 C,vec3 C2,float bld,float len){
  float d=abs(ds),vs=clamp(ds/w,-1.,1.),v=min(d/w,1.),pw=px/w*.75,lod=smoothstep(.5,.15,pw);
  float body=sqrt(max(1.-v*v,0.));
  // along-band coordinate in band widths; an integer number of stripes/links per segment keeps the pattern continuous
  // across the tile joints
  float lw=len/w,kS=max(1.,floor(lw*(kSty>2.5?.36:.5)+.5)),ph=u*kS,aw=pw*kS/lw+.02,ja=min(u,1.-u)*lw;
  // graphic cross-section: hot core, dark pinstripe, glossy body, bright rim line, dark shoulder, black outline.
  // A build widens the white-hot core (tension), the drop releases it.
  float cw=.2+.18*bld;
  vec4 ea=smoothstep(vec4(cw,cw+.03,.27+.06*bld,.68)-pw,vec4(cw,cw+.03,.27+.06*bld,.68)+pw,vec4(v));
  vec4 eb=smoothstep(vec4(.76,.88,.93,.8)-pw,vec4(.76,.88,.93,.8)+pw,vec4(v));
  vec4 bnd=vec4(1.-ea.x,ea.y-ea.z,ea.w-eb.x,eb.x-eb.y)*lod;
  vec3 hot=mix(C2,vec3(1.),(.35+.2*bld)*smoothstep(.26,.1,pw));
  C=mix(C,vec3(dot(C,vec3(.333))*1.3),.1*bld);
  vec3 c=C*(.5+.68*body);
  c=mix(c,hot*(1.55+.7*uHit),bnd.x);
  c=mix(c*(1.-.8*bnd.y),C2.brg*1.7+.05,bnd.y*min(.9*kMd,1.));
  c=mix(c,C2*(1.38+.9*kPr)+C*.2,bnd.z);
  c=mix(c,C*(.5+1.5*min(kPr,1.)),bnd.w);
  // neon look: two fine light filaments run inside the glass body, so the tube reads as lit cable, not a flat noodle
  if(kSty<.5){
    float f2=smoothstep(.025+pw,.025-pw,abs(v-.45))*lod,f3=0.;
    c+=(C2*.8+C*.5)*(f2*.22+f3*.2)*body;
  }
  if(kSty>.5){
    if(kSty<1.5){
      // Celtic ribbon: flat lacquer fill, a bright double border line, crisp black edge
      vec2 ln=smoothstep(vec2(.08)+pw,vec2(.08)-pw,abs(v-vec2(.55,.72)));
      c=C*(.8+.3*body)+(C2*1.2+.25)*(ln.x+.7*ln.y)*lod;
    }else if(kSty<2.5){
      // rope: two strands twisted at about 45 degrees (one strand per band width along the band), each strand a
      // rounded cylinder lit along its crest, a dark crease between the strands, the whole rope shaded round
      // v20b a plaited cord: two columns of strands meeting in a chevron down the middle (mirror symmetric, so the lay never breaks at a tile joint), every third strand a
      // tracer in the neighbouring hue that lights with the mids, an ink crease between strands and down the seam
      float kR=3.*max(1.,floor(lw*.25+.5)),tt=mix(u,1.-u,bm)*kR+abs(vs)*.75,t=fract(tt),r3=sqrt(max(1.-(2.*t-1.)*(2.*t-1.),0.));
      float st=smoothstep(0.,max(.1,(pw*kR/lw+.02)*1.8),min(t,1.-t))*smoothstep(.015,.03+max(pw*1.5,.05),abs(vs));
      vec3 Cs=mix(C,mix(C2.gbr,C2,.25)*(1.05+.9*min(kMd,1.2)),step(mod(floor(tt),3.),.5));
      // (the strands need ~8 px per half band width to read; on smaller bands the plain neon tube stays)
      c=mix(c,mix(C*.1,Cs*(.35+.75*body*r3)+C2*.9*pow(r3,6.)*body,st),smoothstep(.3,.12,pw));
    }else{
      // chain: flat oval links (a rounded metal ring, the dark ground through the hole) alternating with links seen
      // edge-on (a narrow rounded bar); the links overlap a little, so the chain reads continuous
      float P=lw/kS,x=(fract(ph)-.5)*P,lp=mod(floor(ph),2.),e=length(vec2(x/(.56*P),v)),
        rp=lp<.5?1.-abs(e-.68)/.3:1.-abs(vs)/.34,ri=smoothstep(-aw,aw,rp)*step(abs(x),.62*P+.3);
      // v20b the links alternate two enamels (the edge-on links take the neighbouring hue and light with the mids), ink through the holes
      vec3 Cl=(lp<.5?C:mix(C,C2.gbr,.65)*(.8+.5*min(kMd,1.)))*(1.-.6*smoothstep(.09,.03,abs(rp-.42))*smoothstep(.07,.035,pw)*step(lp,.5));
      c=mix(c,mix(C*.1,Cl*(.6+.75*sqrt(clamp(rp,0.,1.)))+(C2*.9+.2)*pow(clamp(rp,0.,1.),5.),ri),smoothstep(.3,.12,pw));
    }
  }
  // cord bindings (neon and ribbon looks): the knot is lashed with neon cord every couple of band widths, so the
  // tubes read as bound cable instead of a smooth noodle, and every tile joint (where two tubes meet) gets a lashing.
  // A binding is a slightly diagonal lit wrap with a dark groove beside it; it lights with its band: the vocal range
  // (hi-mid/presence) and the light pulse passing through the joint
  // v20 the core of a neon tube or a Celtic ribbon is a two-strand twist once the band is wide enough on screen: one strand in the hot core colour (so
  // from afar it still reads as the lit core), one in the neighbouring hue, over and under each other once per band width, crossing at the tile joints.
  if(kSty<1.5){
#if HD>=1
    float pl=smoothstep(.07,.046,pw)*lod;
#else
    float pl=smoothstep(.062,.042,pw)*lod;
#endif
    if(pl>.01){
      float tA=.3,hw=.15,sa=sin(TAU*ph),ca=cos(TAU*ph),sl=tA*TAU*kS/max(lw,1e-3)*ca,sq=inversesqrt(1.+sl*sl);
      float d0=abs(vs-tA*sa)*sq,d1=abs(vs+tA*sa)*sq,pe=pw*1.2;
      float e0=smoothstep(hw+pe,hw-pe,d0),e1=smoothstep(hw+pe,hw-pe,d1),k0=smoothstep(hw+.1+pe,hw+pe,d0),k1=smoothstep(hw+.1+pe,hw+pe,d1);
      vec3 s0=hot*(1.3+.7*uHit)*(.5+.65*sqrt(max(1.-d0*d0/(hw*hw),0.))),s1=mix(C2,C2.gbr,.6)*(1.15+.6*kMd)*(.5+.75*sqrt(max(1.-d1*d1/(hw*hw),0.)));
#if HD>=1
      // Native up: a fine dark fibre line along the flank of each strand and a specular crest
      {float f2=smoothstep(.04,.022,pw);s0*=1.-.4*f2*smoothstep(.02+pe,.02,abs(d0-.09));s1*=1.-.4*f2*smoothstep(.02+pe,.02,abs(d1-.09));
       s1+=vec3(.5)*f2*smoothstep(.035+pe,.01,d1)*(.4+.6*abs(ca));}
#endif
      float ov=step(0.,ca);
      vec3 cc=C*(.34+.3*body);
      cc=mix(cc*(1.-.75*mix(k0,k1,ov)),mix(s0,s1,ov),mix(e0,e1,ov));
      cc=mix(cc*(1.-.75*mix(k1,k0,ov)),mix(s1,s0,ov),mix(e1,e0,ov));
      float lim=kSty>.5?.5:.62;
      c=mix(c,cc,smoothstep(lim+pw,lim-pw,v)*pl);
    }
  }
  float T=uP2.x-kPh,x1=n*mix(u,1.-u,bm)-T;
  float pf=knPulse(x1);
  if(kSty<1.5){
    float lb=smoothstep(.34,.13,pw),hw=.075+.01*kPl+.1*min(.6*(uB1.z+uB1.w),1.),bp=fract(ja*mix(.34,.22,kPl)-vs*.13),wd=abs(bp-.5);
    float wg=smoothstep(hw+pw*1.2,hw-pw*1.2,wd)*lb,g1=smoothstep(hw+.06+pw,hw+.004-pw,wd)*lb;
    c*=1.-.8*max(g1-wg,0.);
    // (the cord is a lit wrap with a dark groove beside it: the knot reads as bound cable, not a smooth noodle; it
    // brightens with the vocal range and its own light pulse, both slow enough that the wrap never strobes)
    // v20b the mids own the lashings: each low-mid/mid hit throws them into the hue a third of the way round from their band
    c=mix(c,mix((C*1.45+C2*.3)*.66,C2.brg*1.9+.06,min(1.25*max(uO1.z,uO1.w),1.))*(.55+.45*body),wg*.78);
  }
  // v20b kick: a comet of light runs along every strand on the beat clock (a segment per beat, a hard head and a short tail), lit by the kick alone: nothing in silence.
  // Its core burns in the strand's hot colour, the rest of the strand under it brightens in its own colours, so no detail is painted over.
  {float pk=knPulse(n*mix(u,1.-u,bm)-uBeat+2.*kPh),kq=min(pk*(1.5*KN_KL+1.1*KN_KG),1.)*lod;
   c=mix(c*(1.+.9*kq),(C2*2.2+C*.35)*(.5+.5*body),kq*smoothstep(.5,.24,v));}
  c*=1.-eb.z*lod;
  // bm (flow direction) is 0 or 1: pulses run from the start or from the end of the band
  float b3=body*body*body;
  c+=(C2*1.1+C*.4+.12*pf*pf)*pf*(.05+b3)*(.4+1.05*kMd);
  c=mix(c,(C2.brg*1.8+.05)*(.5+.5*body),pf*pf*min(.75*kMd,.9)*smoothstep(.8,.5,v)*lod);
  // (the light pulses swell with the low-mid and mid bands)
  // hats: small white beads racing along the core
  float y1=.5+.5*cos(TAU*(3.*x1-4.*T));
  y1*=y1;y1*=y1;y1*=y1;y1*=y1;
  c+=mix(C2*1.6,vec3(1.,.96,.9),.5)*y1*KN_HAT*6.*smoothstep(.45,.05,v)*lod*kSpk;
#if HD>=1
  // v19: the tube is engraved: scales along the band, cross-hatched finer at each level, cut in a deeper tone of the band's own colour with a coloured edge
  {float eF=1.,eC=clamp(1.-eb.z,0.,1.)*lod;
   for(int e=KN_H0;e<KN_HE;e++){
     float ef=lw*eF*1.5,gP=lw/(pw*max(ef,1.)),fd=clamp(gP*.16-.6,0.,1.);
     if(fd<=0.)break;
     float sq=fract(ph*max(1.,floor(ef/kS+.5))+.5*floor(vs*eF*2.+.5))-.5,sv=fract(vs*eF*2.)-.5;
     float sd=abs(length(vec2(sq,sv*.75))-.42);
     float ln=clamp(1.-sd/(.11+pw*eF*1.4),0.,1.)*fd*eC;
     c=mix(c,c*.66,.3*ln);
     c+=C2*.1*fd*eC*clamp(1.-abs(sd-.13)/(.1+pw*eF),0.,1.);
     eF*=2.;
   }
  }
#endif
  return c;
}
// v20b a three-strand plait in three palette enamels on ink. bt = phase along (a full cycle per TAU), bv = across (-1..1), pe = a pixel in bv units, sl = slope of a strand at
// its steepest, bs = +-1 swaps over and under (the snare), tg = tighten (the kick pulls the strands to the middle and fattens them), lit = crest light (the bassline).
// Strand i runs at bA*sin(bt+i*TAU/3) with height sin(2*(bt+i*TAU/3)): where two strands meet their heights are opposite, so every crossing has a clear over and under.
vec3 knBraid(float bt,float bv,float pe,float sl,float bs,float tg,float lit){
  float bA=.5-.1*tg,bh=.3+.04*tg;
  vec3 ph=bt+vec3(0.,2.0943951,4.1887902),s3=sin(ph),c3=cos(ph);
  vec3 d3=abs(bv-bA*s3)*inversesqrt(1.+sl*sl*c3*c3),cv=smoothstep(bh+pe,bh-pe,d3),m3=step(.02,cv),zc=s3*c3*bs*m3-9.*(1.-m3);
  float zt=max(zc.x,max(zc.y,zc.z));
  vec3 tp=step(zt-1e-5,zc)*m3,q3=clamp(d3/bh,0.,1.),r3=sqrt(1.-q3*q3);
  // each strand: a rounded enamel body, an ink keyline inside its edge, a crest line that the bassline lights
  vec3 sh=(.3+.85*r3)*(1.-.88*smoothstep(.6-pe,.92,q3))+(.25+lit)*smoothstep(.22+pe,.1,q3);
#if HD>=1
  // Native up: the lay of each strand, fine yarns wound round it
  sh*=1.-.38*smoothstep(.2,.08,abs(fract(ph*2.5/TAU*4.+q3*sign(bv-bA*s3)*.9)-.5))*smoothstep(.07,.035,pe)*step(q3,vec3(.6))*step(vec3(.16),q3);
#endif
  float at=dot(tp,cv),dT=dot(tp,d3)+9.*(1.-min(dot(tp,vec3(1.)),1.));
  mat3 K=mat3(kc0,kc2,kc3);
  return mix(K*((1.-tp)*cv*sh)*(1.-.75*smoothstep(bh*2.2,bh,dT)),K*(tp*sh),at);
}
float knRegion(vec2 sp){return knB(uSeed.z<.5?sp.x*uRes.y/uRes.x+.5:length(sp)*1.15);}
#define KN_MINPX 24.
#if HD>=1
vec2 kNr=vec2(0.,1.);float kGw=0.;
float fL0(){return .5+.5*uB2.z;}
// the coarse knot layer at a world point (the same lattice, slots and colours as the layer loop): rgb = its band colour, a = cover.
// Shadow, occlusion and reflection rays all come here, from one call site in a runtime-bounded loop.
vec4 knField(vec2 pp,vec2 s0,vec2 p0,float px,float fam,float ep,float drift){
  const float TS=1.3,HS=1.2;
  vec2 id,q;float ms,w=.08;
  if(fam<.5){id=floor(pp);q=pp-id-.5;ms=1.;}
  else if(fam<1.5){ms=TS;vec2 tp=pp/ms;tp.x-=.57735027*tp.y;tp.y*=1.1547005;id=floor(tp);tp-=id;bool up=tp.x+tp.y<1.;tp=up?tp:1.-tp;q=vec2(tp.x+.5*tp.y,.8660254*tp.y)-vec2(.5,.2886751);id.x=id.x*2.+(up?0.:1.);ms=up?ms:-ms;}
  else{vec2 hp=pp/HS,hs=vec2(1.,1.7320508),ha=mod(hp,hs)-hs*.5,hb2=mod(hp-hs*.5,hs)-hs*.5;q=dot(ha,ha)<dot(hb2,hb2)?ha:hb2;id=floor((hp-q)*2.+.5);ms=HS;w=.095;}
  vec2 cen=pp-ms*q,sp=s0+rot(-kRot)*(cen-p0)/(px*uRes.y);
  vec2 fl=knFlip(id,0.,sp);
  float hb=h21(id+vec2(ep*3.3,7.7)),ty=h21(id*.731+vec2(ep*1.37,11.1));
  if(kSty>.5&&kSty<1.5&&fam<1.5&&fract(ty*7.31)<.6)ty=KN_RING+.02+.2*fract(ty*3.17);
  float nR=fam<.5?4.:(fam<1.5?3.:6.),sg=fract(hb*7.)<.5?-1.:1.,oj=floor(hb*nR)+fl.x+step(1.,fl.y);
  mat2 Rt=rot(-sg*oj*TAU/nR);
  float b0=fam<.5?mod(id.x+id.y+oj,2.):mod(oj,2.);
  vec2 qq=Rt*q;
  w*=(.85+.35*fract(uSeed.y*9.1))*(1.+.34*KN_KG)*(1.-.28*fract(uP3.z));
  float best=1e3;vec3 cb=vec3(0.);
  for(int j=KN_H0;j<4;j++){
    vec2 V,ev;vec4 rs;vec3 hk;
    float kind=knSlot(fam,ty,float(j),b0,V,ev,rs,hk);
    if(kind<-.5)continue;
    bool bar=kind>.5;
    vec2 a=bar?knBar(qq):knArc(qq-V,ev,rs.x,rs.y);
    if(a.x<best){
      best=a.x;
      vec2 E0=bar?vec2(.5,0.):V+rs.x*ev,E1=bar?vec2(-.5,0.):V+rs.x*(cos(rs.y)*ev+sin(rs.y)*vec2(-ev.y,ev.x));
      vec2 ci=knCI(cen+(E0*Rt)*ms,cen+(E1*Rt)*ms);
      cb=knPal(knT(ci.x,ci.y,a.y)+drift);
    }
  }
  float cv=clamp((w-best)/(px/abs(ms)*1.5)+.5,0.,1.);
  return vec4(cb*cv,cv);
}
#endif
void realm(){
  kc0=uM1[0];kc1=uM1[1];kc2=uM1[2];kc3=uM2[0];kc4=uM2[1];kbg=uM2[2];kRot=.1*sin(uMT*.031);
  
  // lens space follows the square root of the zoom when zooming out: the medallions shrink slower than the tapestry, so
  // far out they become jewels, each still framing one whole knot, set into a vast field of small knots
  float zl=sqrt(uZoom);
  // the focal lens never sits on the centre: its site drifts slowly on an ellipse (>= .26 screen units out, lens radius
  // .17), so the middle of the frame (and of a kaleidoscope) always shows the knotwork itself
  float la=uMT*.045+uSeed.x*6.2832;
  vec2 s=scr(),u=(s-vec2(.46*cos(la),.27*sin(la)))/zl,lv,lid;
  // medallions: the focal lens in the centre (opens and closes with phrases, uP2.y fraction) and a lattice of smaller
  // ones that appear when zooming out; each frames one knot at about 1.3x, slowly counter-rotating, its bezel hides
  // the seam
  float lR=knLens(u,lv,lid);
  float rS=length(lv)/max(lR,1e-3);bool inL=rS<1.;
  if(inL)kRot-=.05*uMT*(mod(lid.y,2.)<.5?1.:-1.);
  float wr=length(s)/1.05,wp=uP2.w;
  bool nw=wr<wp;
  float fe=floor(nw?uP2.y:uP2.z),fam=mod(fe,4.),ep=floor(fe*.25);kEp=ep;
  // band look of this phrase (neon twice as likely as each other look)
  kSty=max(floor(fract(ep*.618034+uSeed.z*3.7)*5.)-1.,0.);
  // plait style of this phrase (how tightly the giant cable is woven; 0 tight, 1 loose), also swings the cord
  // bindings on the small knots
  kPl=fract(ep*.381966+uSeed.w*2.7);
  kBL=.3+1.7*(.5*uB2.x+.5*uB2.y)*(.4+knRegion(s))+1.2*max(uO2.x,uO2.y);
  // the lens is anchored on one tile centre of the current lattice (it frames one whole knot, which turns on the beat)
  vec2 kO=inL?(fam<.5?vec2(37.5,-18.5)+vec2(5.,3.)*lid:(fam<1.5?vec2(.65,.375)+1.3*vec2(23.+3.*lid.x+lid.y,-12.124356+1.7320508*lid.y)
    :1.2*vec2(31.+2.*lid.x,-15.588457+1.7320508*lid.y))):uP1.yz;
  float fz=smoothstep(.85,.35,uZoom),scale=inL?uP1.x/zl*.78*(fam>1.5?1.+(dot(lid,lid)<.5?0.:.6)+1.2*fz:1.+1.1*fz):uP1.x/uZoom;
  vec2 p=rot(kRot)*(inL?lv*zl:s)*scale+kO;
  float px=scale/uRes.y,bld=fract(uP3.z);
  // vocal range (hi-mid/presence) and low-mid/mid light terms, envelopes plus onsets
  kPr=.5*(uB2.x+uB2.y)+.9*max(uO2.x,uO2.y);kMd=.6*(uB1.z+uB1.w)+.9*max(uO1.z,uO1.w);kFz=fz;
  // macro knot: a classic Truchet of giant bands (MS world units per tile, ~8 knot tiles) with woven crossings; the
  // knots inside the giant bands shine, the ones between them recede into shadow in a shifted colour, so zooming out
  // shows enormous knots made of the small ones. Phrases re-route the giant tiles (medallion turns, own counter uP5.y).
  kOut=0.;float mMul=1.,mR=0.,mRb=0.,mRc=0.,mG=0.,mP=0.,mX=0.,mB=0.,mW=0.,dS=9.,pm=1.,mBc=0.,mBg=0.,mH=0.,mLe=0.,kRib=0.,mKey=0.,mBw=0.,mIn=0.;vec3 mBr=vec3(0.);
  if(!inL&&uP5.x>.002){
    float MS=7.+3.*fract(uSeed.x*3.7),cM=uP5.y,k=floor(cM),q=uP5.x;pm=px/MS;
    vec2 mq=p/MS,mid=floor(mq),mf=mq-mid-.5;
    float mh=h21(mid*.913+vec2(ep*2.7,5.1)),g=floor(fract(mh*13.7+k*.618)*4.);
    // about a fifth of the giant tiles are woven crossings: a straight giant band passing OVER another one (they keep
    // their weave when the others re-route)
    bool cr=fract(mh*7.31)<.2+.14*fz;
    // re-routing: each cycle of the counter flips the four groups in order (a short hash stagger inside a group). A
    // flipping giant tile morphs between its two Truchet states (a blend of the two distance fields): both states agree
    // on the whole tile border, so the giant bands pinch and reconnect inside the tile with no seam
    float fp=cr?0.:clamp((cM-k-g*.25-.08*fract(mh*5.3))*5.,0.,1.),tq=fp<1.?fp:0.,tw=sin(PI*tq);
    float da=abs(length(mf-(mf.x+mf.y>0.?.5:-.5))-.5),db=abs(length(mf-(mf.x>mf.y?vec2(.5,-.5):vec2(-.5,.5)))-.5);
    vec2 cq=fract(mh*3.1)<.5?mf:mf.yx;
    float sel=abs(mod(floor(mh*2.)+k+step(1.,fp),2.)-tq*tq*(3.-2.*tq));
    float d1=cr?abs(cq.y):mix(da,db,sel),dU=cr?abs(cq.x):9.,W=clamp(.06+.01*scale,.09,.15);
    // along-strand coordinate (0..1 per giant tile), oriented by the checkerboard so the flow is continuous from tile to
    // tile: even tiles run from their horizontal-edge joints to their vertical-edge ones, odd tiles the other way. A woven
    // crossing's straight bands become a source (or a sink) at the hub.
    float par=mod(mid.x+mid.y,2.);vec2 vv=abs(mf-(sel<.5?(mf.x+mf.y>0.?vec2(.5):vec2(-.5)):(mf.x>mf.y?vec2(.5,-.5):vec2(-.5,.5))));
    float ua=knAt(vv.y,vv.x)*.63661977;bool inD=d1<dU,sw=fract(mh*3.1)>=.5;
    float uu=cr?(((inD!=sw)==(par<.5))?.5+abs(inD?cq.x:cq.y):.5-abs(inD?cq.x:cq.y)):(par<.5?ua:1.-ua);
    // music pulses along the giant strands: one comet per giant tile rides the beat clock (a tile per beat), lit by the
    // kick (slow-release geometry envelope + the snappy light one); far out they are the strongest motion in the frame
    mP=knPulse(uu-uBeat)*(.2+1.5*KN_KG+.7*KN_KL)*mix(.2,1.,fz);
    // glowing crossings: the hub where a giant band passes over another glows with the vocal range (hi-mid/presence)
    mX=cr?smoothstep(W*1.25+pm,W*.25,length(cq))*(.25+1.6*kPr):0.;
    // (the giant bands are a little narrower when few knots are on screen, so at the default framing a whole band, both
    // its rails, crosses the frame as one ribbon)
    float dm=min(d1,dU);dS=dm;
    kOut=clamp((dm-W)/pm+.5,0.,1.)*q;
    // ribbon rails: a tube just inside each edge of a giant band (dark groove outside it); the under band's rails stop
    // short of the over band, which casts a shadow across it
    float RW=max(.044,3.*pm),G=max(.01,1.5*pm),e=W-d1,eu=W-dU;
    float c1=clamp(min(e+G,RW-e)/pm+.5,0.,1.),cu=clamp(min(eu+G,RW-eu)/pm+.5,0.,1.)*clamp((d1-W-G)/pm+.5,0.,1.);
    // (round tube profile with a crisp 1 px black outline inside both rail edges)
    float ue=cu>c1?eu:e,x=clamp(ue/RW,0.,1.);
    mR=max(c1,cu)*smoothstep(.2,.65,q)*(1.-tw);mRb=sqrt(4.*x*(1.-x))*clamp(min(ue,RW-ue)/pm-1.,0.,1.);
    // v20b the rails are a three-strand plait once they are wide on screen (a plain bar before): three palette enamels on ink, crawling with the flow, tightened by the kick,
    // crests lit by the bassline, over and under swapped by the snare
    {float rpx=RW/pm;mBw=smoothstep(9.,20.,rpx);
     if(mBw>.002){float rN=max(floor(.26/RW),1.);
       mBr=knBraid(TAU*(rN*uu-uP2.x),2.*x-1.,2.2/rpx,1.8*rN*RW,mod(KN_SN,2.)<.5?1.:-1.,KN_KG,.5*(uP3.w-1.))*clamp(min(ue,RW-ue)/pm-1.,0.,1.);}}
    // the rail's core is the inlay line, lit by the bassline (sub/bass envelopes, flashes on their onsets)
    mRc=uP3.w*clamp((.13*RW-abs(ue-.5*RW))/pm+.5,0.,1.);
    // the tapestry between the giant bands recedes (darker; shifted colour in the layer loop); inside, the giant band reads
    // as a broad glass tube (brighter along its middle); a re-routing tile flashes softly while it morphs
    // (the giant bands cast a soft shadow on the tapestry beside them, the over band across the under band)
    float sd=clamp((dm-W)/.05,0.,1.),gs=1.-dm/W;
    // (at the default framing the tapestry outside the bands only shifts colour and dims a little: the frame stays luminous)
    mMul=(1.-mix(.06,.28,fz)*kOut)*(1.+mix(.08,.2,fz)*q*(1.-kOut)*gs+.4*q*tw*(1.-kOut))*(1.-.35*q*kOut*(1.-sd)*(1.-sd))
      *(1.-.5*q*float(cr)*step(W,d1)*clamp((W+.08-d1)*12.5,0.,1.)*step(dU,W));
    // a glassy tint across the giant band (in the gaps between its knots), brightest along its middle: it reads as one
    // broad ribbon at any zoom
    mG=q*(1.-kOut)*gs*(1.-tw);
    mIn=q*(1.-clamp((dm-W)/pm+.5,0.,1.))*(1.-tw)*(1.-.45*fz);
    // the giant band is one big tube woven of the small knots: shaded round across its width (body mB)
    mB=sqrt(max(1.-(1.-gs)*(1.-gs),0.))*q*(1.-kOut)*(1.-tw);
    // the giant band is a RIBBED CABLE: dark binding grooves ring it every ~30 px (the rings bow as they wrap round the
    // tube, so the band reads as a rounded cable instead of a flat glass wash), each rib has a crisp lit leading edge
    // and a soft bulge between grooves. The rings crawl slowly along the strand; broad bands only (far out, the strand
    // is knots). A sharp comet head rides the beat clock along the strand (mH, a narrow head over the broad light mP).
    float bpx=2.*W/max(pm,1e-4),pl=smoothstep(40.,140.,bpx),fqA=clamp(MS/max(pm,1e-4)/mix(30.,44.,kPl),1.5,40.);
    // (the rings crawl slowly, and the groove/edge bands are kept a couple of px wide, so nothing strobes at low
    // render scales)
    float rp=fract(uu*fqA-uP2.x*.28+gs*gs*.17),rw=abs(rp-.5);
    float w1=smoothstep(.145,.045,rw)*pl,w2=smoothstep(.17,.31,rw)*pl,le=max(smoothstep(.215,.17,rw)-smoothstep(.15,.105,rw),0.)*pl;
    mBc=w2*q*(1.-kOut)*(1.-tw);mBg=w1*q*(1.-kOut)*(1.-tw);mLe=le*q*(1.-kOut)*(1.-tw);kRib=pl;
    // a black keyline outside the cable's rails: the band gets a graphic ink edge against the tapestry, so it reads as
    // one bold object at any zoom
    mKey=smoothstep(W-1.5*pm,W+.5*pm,dm)*(1.-smoothstep(0.,(3.2-1.4*fz)*pm,max(dm-W,0.)))*q*(1.-tw);
    mH=pow(knPulse(uu-uBeat),2.)*(.2+1.4*KN_KG+.7*KN_KL)*mix(.3,1.,fz);
    // low-mid/mid: echo waves ripple outward from the giant strands over the tapestry (op-art offset curves)
    float wo=max(dm-W,0.),wv=.5+.5*cos(TAU*(wo*7.-uP2.x*3.));
    mW=q*kOut*wv*wv*wv*exp(-wo*5.)*kMd;
  }
  // zoomed out, the knots inside a giant strand take the other material (neon <-> Celtic ribbon): the strand reads as
  // one big tube woven of a different small weave
  if(fz>.3&&kOut<.5&&mR<.5)kSty=kSty<.5?1.:0.;
  kGlow=0.;kMinD=1e3;
  // pulse phase offset and the drifting sparkle field that gates the hat beads (smooth sine fields: cheap to compile)
  kPh=.35+.35*sin(p.x*.37+1.3)*sin(p.y*.29+.4)+.12*(p.x-p.y);
  kSpk=smoothstep(-.1,.5,sin(kPh*11.+p.x*.9+uTime*2.3));
  // slow global colour drift: every band steps through its palette neighbours over time
  float drift=uMT*.04;
  // drop / phrase wipe: a ring opens from the centre, the new tiling inside it
  // deep background
  vec3 col=kbg*(1.1-.5*length(s));
  // hex cell (width HS); triangle side TS (the triangle quadtree, midpoint subdivision, is just the triangle lattice at
  // half the side, so every level is found directly in the loop)
  const float TS=1.3,HS=1.2;
  vec2 hp=p/HS,hs=vec2(1.,1.7320508),ha=mod(hp,hs)-hs*.5,hb2=mod(hp-hs*.5,hs)-hs*.5,hq=dot(ha,ha)<dot(hb2,hb2)?ha:hb2,hid=floor((hp-hq)*2.+.5);
  // zoomed out, inside a medallion the quadtree goes one level deeper and finer (to ~14 px tiles): a rose window of knots within knots
#if HD>=1
  float maxL=fam>1.5?0.:min((inL?1.+step(.01,fz):1.)+floor(log2(max(uDetail,1.))*1.4),float(KN_HL-1)),mpx=(inL?14.:KN_MINPX)*(fam>.5?1.4:1.)*.72/sqrt(max(uDetail,1.));
#else
  float maxL=fam>1.5?0.:min((inL?1.+step(.01,fz):1.)+floor(log2(max(uDetail,1.))),3.),mpx=(inL?14.:KN_MINPX)*(fam>.5?1.4:1.);
#endif
  // far out the hex family settles into a clean lace: whole tiles of three arcs whose rings close around every other
  // lattice vertex (the giant bands take the other set, so their edges read as meandering strands)
  float far=inL?0.:smoothstep(.6,.3,uZoom);
  // Finer knot layers grow in the gaps beneath the coarse knot where the spectrum band of their screen region is
  // loud. The growth field is smooth per pixel, so fine tubes taper in and out instead of being cut at cell edges;
  // the layers are composited front to back (coarse on top, fine underneath in its shadow).
  // (zoomed out, a medallion's split field is radial: the knot's arcs stay whole at the rim and split into ever finer knots
  // toward the middle, a jewel of knots within knots)
  float Ep=inL&&fz>0.?mix(knRegion(s),1.25-.95*rS,fz):knRegion(s/max(uZoom,1.));
  // (zoomed in, the split layer is only half a tile finer than the knot on screen, so the two would read as a soft
  // double image: it fades out above zoom ~1.15 and the knot stays crisp and bold instead)
  float zk=1.-smoothstep(1.15,1.7,uZoom);
  vec3 A=vec3(0.);float al=0.,fcur=1.,sz=1.;kFl=0.;
#if HD>=1
  for(int L=KN_H0;L<KN_HL;L++){
#else
  for(int L=0;L<4;L++){
#endif
    float fL=float(L);
    if(fL>maxL||fcur<.02||(fL>0.&&sz/px<mpx))break;
    float thN=.4+.12*fL+(fam>.5?.1:0.)+.15+.15*sin(p.x*.53+fL*2.1)*sin(p.y*.47-fL*1.3)-.2*bld;
    float fnext=(fL+1.<=maxL&&sz*.5/px>mpx)?fcur*smoothstep(thN,thN+.2*max(uZoom,1.),Ep)*zk:0.;
    // cell id, tile-local position q (unit tile, centred) and the tile's world scale ms (world = cen + ms*q)
    vec2 id,q;float ms,w=.08,ln=0.;
    if(fam<.5){id=floor(p/sz);q=p/sz-id-.5;ms=sz;}
    else if(fam<1.5){ms=TS*sz;vec2 tp=p/ms;tp.x-=.57735027*tp.y;tp.y*=1.1547005;id=floor(tp);tp-=id;
      // (a down triangle is the up one turned half round)
      bool up=tp.x+tp.y<1.;tp=up?tp:1.-tp;q=vec2(tp.x+.5*tp.y,.8660254*tp.y)-vec2(.5,.2886751);
      id.x=id.x*2.+(up?0.:1.);ms=up?ms:-ms;}
    else{id=hid;q=hq;ms=HS;w=.095;}
    vec2 cen=p-ms*q;float pt=px/abs(ms);
    // screen position of the cell centre (from this pixel's own screen and world positions)
    vec2 sp=s+rot(-kRot)*(cen-p)/(px*uRes.y);
    if(fam>1.5)ln=smoothstep(.32,.62,Ep)*smoothstep(.045,.025,pt);
    // flip state: one turn per cycle, swept across the screen in this cell's group. The whole tile turns as a unit
    // (eased angle, a slight shrink at mid-turn), like a dial clicking round, and re-connects when it lands.
    vec2 fl=knFlip(id,fL,sp);
    float hb=h21(id+vec2(fL*13.1+ep*3.3,7.7));
    float ty=h21(id*.731+vec2(fL*2.9+ep*1.37,11.1));
    // hats/air: a third of the tiles twinkle (a bright flick with a soft tail), stronger when zoomed out where the beads are too small
    float kTw=KN_HAT*3.2*pow(.5+.5*sin(6.2831853*(uTime*1.7+hb*5.7)),4.)*step(.3,fract(hb*11.3))*mix(.7,1.,kFz);
    // Celtic ribbon phrases weave: most square/triangle tiles become crossing knots (pinwheel / triskele, over-under)
    if(kSty>.5&&kSty<1.5&&fam<1.5&&fract(ty*7.31)<.6)ty=KN_RING+.02+.2*fract(ty*3.17);
    bool coh=fam>1.5&&fract(hb*3.7)<far;
    // (a coherent hex tile turns by thirds, so it lands on the same lace)
    float nR=fam<.5?4.:(fam<1.5?3.:(coh?3.:6.)),sg=fract(hb*7.)<.5?-1.:1.;ty=coh?0.:ty;
    // settled orientation (once this cycle's turn has landed it counts), turn progress, eased angle, mid-turn bump
    float o0=floor(hb*nR)+fl.x+step(1.,fl.y);
    bool flp=fl.y>0.&&fl.y<1.;
    float tq=flp?fl.y:0.,we=tq*tq*(3.-2.*tq),tw=sin(PI*tq);
    if(L==0)kFl=tw;
    // wipe reveal: tiles just inside the opening ring light up (a crisp band of freshly lit knots behind the seam)
    // A turning tile is a round medallion: inside a disc just short of the connection points the content turns as a
    // unit; outside it (only the short stubs at the connection points, which every orientation shares) the tile keeps
    // the old orientation until mid-turn, then the new one. A neon ring in a dark groove hides the seam.
    // A turning tile re-ties its knot: the old routes thin away while the new ones swell in (both share the tile's
    // connection points, so the knot stays joined to its neighbours throughout; no seam, no ring)
    float oA=flp?o0-1.:o0,aM=we*1.5707963;
    w*=(.85+.35*fract(uSeed.y*9.1))*(1.+.34*KN_KG)*(1.-.28*bld)*(fL>0.?.5+.5*smoothstep(0.,.6,fcur):1.)*(1.-.3*fnext);
    float pS=pt,scl=1.,xs=mod(KN_SN+floor(hb*2.),2.)<.5?1.:-1.,xd=1e3;
    float h1=-9.,shD=1e3,shH=-9.,shW=w,t1=0.;vec4 r1=vec4(0.);vec4 x1=vec4(w,1.,1.,1.);
    for(int j=0;j<8;j++){
      if(j>3&&!flp)break;
      float mN=j>3?1.:0.,oj=oA+mN;
      mat2 Rt=rot(-sg*oj*TAU/nR-(coh?step(.5,kOut)*1.0471976:0.));
      float b0=fam<.5?mod(id.x+id.y+oj,2.):mod(oj,2.);
      vec2 qq=Rt*q;
      vec2 V,ev;vec4 rs;vec3 hk;
      float kind=knSlot(fam,ty,float(j)-4.*mN,b0,V,ev,rs,hk);
      if(kind<-.5)continue;
      bool bar=kind>.5;
      kSd=1.;vec2 a=bar?knBar(qq):knArc(qq-V,ev,rs.x,rs.y);
      float wj=w*(flp?(mN>.5?sin(aM):cos(aM)):1.);
      a.x=abs(a.x-wj*.55*ln);wj*=1.-.45*ln;
      float h=xs*(hk.x*(a.y-.5)+hk.y)+(flp?mN*(we-.5)*3.:0.);
      float dW=(a.x-wj)*scl*px/pt;
      kMinD=min(kMinD,dW);
      if(a.x<wj+pS){
        // band end points (tile space) -> lattice connection points (world) -> palette colours
        vec2 E0=bar?vec2(.5,0.):V+rs.x*ev,E1=bar?vec2(-.5,0.):V+rs.x*(cos(rs.y)*ev+sin(rs.y)*vec2(-ev.y,ev.x));
        vec2 ci=knCI(cen+(E0*Rt)*(ms*scl),cen+(E1*Rt)*(ms*scl));float tc=knT(ci.x,ci.y,a.y)+drift+fL*2.+2.*kOut;
        vec4 xr=vec4(wj,1.+.5*tw*mN,bar?1.:rs.x*rs.y,kSd);
        if(h>h1){if(h1>-8.)xd=min(xd,r1.x-x1.x);h1=h;r1=vec4(a,rs.z,hk.z);x1=xr;t1=tc;
#if HD>=1
          if(L==0){kNr=(bar?vec2(0.,kSd):(qq-V)/max(length(qq-V),1e-4)*kSd)*Rt;float nv=clamp(a.x/max(wj,1e-4),0.,1.);kGw=.08+.42*nv*nv*nv;}
#endif
        }else xd=min(xd,a.x-wj);
      }else if(a.x-wj<shD-shW){shD=a.x;shH=h;shW=wj;}
    }
    if(L==0){kGlow=exp(-max(kMinD,0.)/(.13*sz+px));
      kEd=fam<.5?.5-max(abs(q.x),abs(q.y)):(fam<1.5?(.2886751-max(-q.y,dot(abs(q),vec2(.8660254,.5))))*TS:(.5-max(abs(q.x),dot(abs(q),vec2(.5,.8660254))))*HS);}
    vec3 lc=vec3(0.);float la=0.;
    // (only the highest covering band is shaded: a band passing under it shows only in its 1 px edge fringe, where the
    // top band's black outline hides the difference; beside the crossing the under band is the top band of its pixels,
    // in the over band's contact shadow)
    if(h1>-8.){
      float cv=smoothstep(x1.x+pS,x1.x-pS,r1.x);
      // C2 (core, rim and pulse light): the band colour pushed toward its neighbour hue, a touch more saturated
      vec3 Ct=knPal(t1)*(1.+.3*fL),C2=max(mix(Ct,Ct.gbr,.22)*1.25-.06*dot(Ct,vec3(.333)),0.);
      vec3 ct=knTube(r1.x*x1.w,x1.x,pS,r1.y,r1.z,r1.w,Ct,C2,bld,x1.z)*x1.y*(shH>h1+.01?mix(.2,1.,smoothstep(shW*.95,shW*2.,shD)):1.);
      // (the hat twinkle turns the tile toward its saturated rim colour: light without washing to white)
      {float fw=smoothstep(.004,.012,pt);ct=mix(ct*(1.+1.1*min(kTw,1.)*(1.-fw)),C2*1.8,min(kTw,.85)*fw);}
      {float xm=smoothstep(pS,-pS,xd)*(flp?0.:1.);ct=mix(ct*(1.+.22*xm),C2*2.1+.1,xm*min(1.4*uHit,.95));}
      lc=mix(lc,ct,cv);la=mix(la,1.,cv);
    }
    // finer knots lie on top of the coarser ones, which recede beneath them
    if(L>0){float fa=smoothstep(0.,.14,fcur);la*=fa;lc*=fa;A*=1.-.9*smoothstep(0.,.22,fcur);}
    A=lc+(1.-la)*A;al=la+(1.-la)*al;
    fcur=fnext;sz*=.5;
  }
  // gaps: op-art echo outlines around every band in the colour of the local colour region (rippling outward with the
  // flow), neon glow, outlines of turning tiles
  // (echo, glow and the giant rails take a slowly drifting blend of two palette colours, chroma kept up)
  vec3 Cn=mix(kc1,kc4,.5+.5*sin(dot(p,vec2(.11,.07))+drift*2.));float lN=dot(Cn,vec3(.3333));Cn=max(lN+(Cn-lN)*1.5,0.);
  float sc=.085,pu=px/sc,ce=abs(fract(kMinD/sc-uP2.x*2.)-.5);
  float cl=smoothstep(1.4*pu,.4*pu,ce)*exp(-kMinD*4.)*step(0.,kMinD)*smoothstep(.3,.12,pu)*(1.-kFl);
  {float em=smoothstep(-.03,.03,kEd-kMinD);cl*=em;
   float sc2=sc/3.,pu2=px/sc2,ce2=abs(fract(kMinD/sc2-uP2.x*2.)-.5),m3=abs(fract(kMinD/sc-uP2.x*2.)-.5);
   float cl2=smoothstep(1.3*pu2,.4*pu2,ce2)*exp(-kMinD*4.)*step(0.,kMinD)*smoothstep(.2,.09,pu2)*(1.-kFl)*em*step(.2,m3);
   col+=knPal(drift+3.+2.5*(KN_SN+floor(kMinD/sc-uP2.x*2.)))*.3*cl2*(1.+.8*kMd+1.2*uHit);}
  col+=mix(Cn,knPal(drift+1.5+2.5*(KN_SN+floor(kMinD/sc-uP2.x*2.))),.75)*.6*cl*(1.+1.4*min(kMd,1.4)+.3*uB1.y+.9*uHit)+Cn*kGlow*.09*(1.+.8*KN_KL);
  col*=1.-.9*mIn;
  // v20b plait panels: the middle of every gap that is large enough on screen holds a small panel of Celtic plaitwork (two sets of bands at 45 degrees, over and under
  // like a chessboard) in two palette colours a few steps from the knots round it, on ink, inside the first echo ring. Sized in pixels: it appears as you zoom in or
  // raise the resolution, never as speckle. The mids light it.
  {float pq=.066,ppx=pq/px,pv=smoothstep(9.5,13.,ppx);
   if(pv>.01){
     kPn=smoothstep(.128,.128+2.5*px,kMinD)*smoothstep(-.03,.03,kEd-kMinD)*pv*(1.-kFl);
     if(kPn>.003){
       vec2 g=vec2(p.x+p.y,p.x-p.y)*(.70710678/pq),gi=floor(g),dd=abs(g-gi-.5);
       float par=mod(gi.x+gi.y,2.),bw=.3,e=1.3/ppx,dT=par<.5?dd.y:dd.x,dB=par<.5?dd.x:dd.y;
       float gc=knCI(p,p).x+drift+2.*kOut;
       vec3 P1=knPal(gc+2.5),P2=knPal(gc+3.75),cT=par<.5?P1:P2,cB=par<.5?P2:P1;
       vec2 qd=clamp(vec2(dT,dB)/bw,0.,1.),sh=(.42+.58*sqrt(1.-qd*qd))*(1.-.85*smoothstep(.62-e,.95,qd));
#if HD>=1
       // Native up: an inlaid pinstripe down each band
       sh*=1.-.5*smoothstep(.07,.03,e)*smoothstep(.1+e,.1-e,abs(qd-.3));
#endif
       vec3 pc=mix(cB*sh.y*smoothstep(bw+e,bw-e,dB)*(1.-.7*smoothstep(bw*2.,bw,dT)),cT*sh.x,smoothstep(bw+e,bw-e,dT));
       col=mix(col,pc*(.62+.55*min(kMd,1.3)),kPn);
     }
   }
  }
#if HD>=1
  {
    // v19 filigree: tiny Truchet knots woven through the dark gaps, a level per tier, each half the size, in the palette's own colours at limited coverage
    float fS=.34,fN=min(float(KN_HE),1.+log2(max(uDetail,1.))*1.3);
    for(int fl=KN_H0;fl<KN_HE;fl++){
      if(float(fl)>=fN)break;
      float pC=fS/px,fd=clamp(pC*.09-.7,0.,1.);
      if(fd<=0.)break;
      vec2 g=p/fS+float(fl)*vec2(7.3,3.1),id=floor(g),f=g-id;
      float h=h21(id*.77+float(fl)*vec2(2.1,5.3)+ep);
      if(h<.5)f.x=1.-f.x;
      float d=min(abs(length(f)-.5),abs(length(f-1.)-.5))*fS,wd=.075*fS,lc2=clamp(1.-(d-wd)/(px*1.2),0.,1.)*fd;
      vec3 fc=knPal(fract(h*3.7)*5.+drift+float(fl)*1.3);
      col=mix(col,fc*(.5+.3*fL0()),lc2*.72*(1.-kPn)*(1.-.85*mIn));
      col=mix(col,kbg*.5,clamp(1.-abs(d-wd)/(px*1.1),0.,1.)*fd*.22);
      fS*=.5;
    }
    // rays through the coarse knot: shadow toward the light (soft from several distances along the ray), occlusion on a spiral around the point, reflection off the tube's own curvature
    int nS=min(int(2.+uDetail*6.),KN_HR),nR=min(int(.6+uDetail*2.4),KN_HB),nT=nS+nR;
    const vec2 Ld=vec2(.6,.8);
    float occ=0.,ao=0.;vec3 rfl=vec3(0.);float nAO=0.;
    for(int r=KN_H0;r<nT;r++){
      float fr=float(r);vec2 rp;
      if(r<nS){
        if(mod(fr,2.)<.5){rp=p+Ld*(.05+.14*fr/float(nS));}
        else{float a=fr*2.399963,dd=.06+.17*sqrt(fr/float(nS));rp=p+vec2(cos(a),sin(a))*dd;}
      }else{
        float a=fr*2.399963;rp=p+(kNr*1.+.05*vec2(cos(a),sin(a)))*(.3+.07*(fr-float(nS))/float(nR));
      }
      vec4 fv=knField(rp,s,p,px,fam,ep,drift+2.*kOut);
      if(r<nS){if(mod(fr,2.)<.5)occ+=fv.a;else{ao+=fv.a;nAO+=1.;}}
      else rfl+=fv.rgb*(.25+.75*fv.a);
    }
    float sh=clamp(occ/max(float(nS)*.5,1.)*1.4,0.,1.);
    float aoV=nAO>0.?clamp(ao/nAO*1.2,0.,1.):0.;
    col*=(1.-.3*sh)*(1.-.18*aoV);
    if(nR>0){vec3 rc=rfl/float(nR);float rl=dot(rc,vec3(.3333));rc=max(rl+(rc-rl)*1.5,0.);A=mix(A,rc*1.2*max(al,.001),clamp(kGw,0.,.42)*al);}
    A*=1.-.08*aoV;
  }
#endif
  // v20 bosses: every arc of the knot curls round a lattice vertex, and each vertex now carries a jewelled rosette (a collar ring, petals, a cabochon).
  // It lies under the bands, takes the colour two steps round the palette from the bands of its region, lights with the spectrum band of its screen region,
  // swells on the kick, and its cabochon flicks on the hats. Sized in pixels: far out it is a ringed stud, then nothing.
  {
    vec2 bzv;float bzR=.175,bzK=6.;
    if(fam<.5){bzv=p-floor(p+.5);bzR=.13;bzK=8.;}
    else if(fam<1.5){vec2 bts=vec2(1.,1.7320508)*TS,bza=mod(p+bts*.5,bts)-bts*.5,bzb=mod(p,bts)-bts*.5;bzv=dot(bza,bza)<dot(bzb,bzb)?bza:bzb;}
    else{float ban=(floor(knAt(hq.y,hq.x)/1.0471976)+.5)*1.0471976;bzv=(hq-.57735027*vec2(cos(ban),sin(ban)))*HS;}
    bzR*=1.+.2*KN_KG;
    float bpx=bzR/px,bvis=smoothstep(2.5,6.,bpx),br=length(bzv)/bzR,bap=1./bpx;
    if(bvis>.01&&br<1.+bap){
      vec2 bsite=p-bzv,bsp=s-rot(-kRot)*bzv/(px*uRes.y);
      float bci=knCI(bsite,bsite).x,bh=h21(bsite*.37+vec2(ep*1.3,2.2)),blb=knRegion(bsp);
      float btw=KN_HAT*2.4*pow(.5+.5*sin(6.2831853*(uTime*1.3+bh*7.1)),4.)*step(.4,fract(bh*5.3));
      float bg=floor(fract(bh*9.7)*4.),bfi=dot(vec4(max(uO1.x,uO1.y)+.6*KN_KL,max(uO1.z,uO1.w),max(uO2.x,uO2.y),max(uO2.z,uO2.w)+.5*KN_HAT),step(abs(vec4(0.,1.,2.,3.)-bg),vec4(.5)));
      vec3 bcR=knPal(bci+drift+2.5+2.*kOut+1.25*bg),bcP=knPal(bci+drift+1.25+2.*kOut+1.25*bg);
      float ba=knAt(bzv.y,bzv.x)+mod(floor(bh*2.)+KN_SN,2.)*PI/bzK,bpc=abs(cos(ba*bzK*.5)),brp=.42+.34*bpc,bfine=smoothstep(7.,13.,bpx);
      // a cut stone in the collar: a ring of outer facets, a star of inner facets turned half a step, a table. Every facet is one flat tone from its own
      // direction to the light, with dark keylines between, so it reads as a gem and never as a flower.
      float bof=mod(floor(bh*2.)+KN_SN,2.)*PI/bzK,bfa=ba*bzK/TAU,bff=fract(bfa),bzz=2.*abs(bff-.5),brb=.38+.16*bzz;
      float blo=.5+.5*cos((floor(bfa)+.5)*TAU/bzK-bof-.93),bli=.5+.5*cos(floor(bfa+.5)*TAU/bzK-bof-.93);
#if HD>=1
      // Native up: every outer facet is split in two and the star facets carry a second, smaller star
      {float bf2=smoothstep(11.,20.,bpx);blo=mix(blo,clamp(blo+(bff<.5?-.22:.22),0.,1.),bf2);bli=mix(bli,clamp(bli+(br<brb*.72?.25:-.12),0.,1.),bf2);}
#endif
      vec3 bgO=bcP*(.22+1.0*blo*blo)*(.75+.8*blb+1.7*bfi),bgI=mix(bcP,bcR,.55)*(.4+1.0*bli)*(.75+.8*blb+1.7*bfi);
      vec3 bc=mix(bcP*(.6+1.2*bfi),mix(bgI,bgO,smoothstep(brb-bap,brb+bap,br)),bfine);
      {float bde=min(bff,1.-bff)*TAU/bzK*br,bdi=abs(bff-.5)*TAU/bzK*br,bkl=br>brb?bde:bdi;
#if HD>=1
       bkl=min(bkl,mix(9.,br>brb?bdi:abs(br-brb*.72),smoothstep(11.,20.,bpx)));
#endif
       bc*=1.-.7*bfine*max(smoothstep(1.6*bap,.5*bap,bkl),smoothstep(1.8*bap,.5*bap,abs(br-brb)));}
      // table
      float bcr=.19,bq=br/bcr;
      bc=mix(bc,mix(bcR*1.25,vec3(1.),.06+.4*min(btw,1.))*(.7+.5*sqrt(max(1.-bq*bq,0.)))*(1.+1.3*btw+.6*blb+1.2*bfi),smoothstep(bcr+bap,bcr-bap,br));
      bc*=1.-.75*bfine*smoothstep(2.*bap,.6*bap,abs(br-bcr));
      // a glint toward the light
      bc+=vec3(1.,.97,.9)*smoothstep(.09+bap,.03,length(bzv/bzR-vec2(.26,.34)))*(.35+.9*btw)*bfine;
      // collar ring
      float brc=(br-.88)/.12;
      vec3 bring=bcR*(.5+.85*sqrt(max(1.-brc*brc,0.)))*(.7+.7*blb+1.6*uHit+1.2*bfi);
#if HD>=1
      {float bfb=(fract(ba*bzK/PI+.5)-.5)*PI/bzK*.88,bbd=length(vec2(bfb,br-.88));
       bring=mix(bring,mix(bcP,vec3(1.),.3)*(1.2+1.5*btw),smoothstep(.07+bap,.07-bap,bbd)*smoothstep(11.,20.,bpx));}
#endif
      bc=mix(bc,bring,smoothstep(.76-bap,.76+bap,br));
      bc*=1.-.85*smoothstep(1.-2.2*bap,1.-.4*bap,br);
      col=mix(col,bc,smoothstep(1.+bap,1.-bap,br)*bvis);
    }
  }
  col=A+(1.-al)*col;
  // macro knot shading (computed before the layer loop)
  // giant knot: the tapestry recedes outside the giant bands, and the bands' ribbon rails lie over it (a neon tube along
  // each edge in a dark groove; its core is the bassline's inlay line)
  {
    // giant cable shading (zoomed out mostly), its comets, the crossing hubs, the mid ripples on the tapestry
    float gz=fz;
    vec3 Ch=Cn*1.4;
    // (the band shines: brighter than the tapestry behind it, and far out - where it is the subject - as bright as ever;
    // close up the lift is smaller so the knots inside keep their saturation instead of washing to white)
    float bq=mB/max(uP5.x,.01),gm=mix(.36+.8*bq,.34+.74*bq,fz);
    col*=mix(1.,gm,step(.001,mB)*gz)*(1.+mix(.35,1.,fz)*mW);
    // the ribbed cable: dark binding grooves ring the band (the rings bow round the tube), each rib gets a crisp lit
    // leading edge and the bulge between grooves catches the light, so the broad band reads as a rounded cable at any
    // zoom. The comet rides the cable and lights the ribs and groove edges it sweeps past (a bright travelling ring)
    // and only barely the knots themselves, so the cable never fogs; the bassline lights the bulges.
    col*=1.-.9*mKey;
    col+=Cn*mLe*(.3+.3*fz)*(.5+.4*mH+.3*mP+.3*uP3.w)*(1.-al);
    // (the comet and the snare touch the knots only lightly at close zoom; far out, where the band is a thin strand of
    // knots, the comet still runs along it as bright moving light. Colours stay saturated at every zoom)
    // v20b close up the comet, the snare and the crossing hubs lift the knots in their own colours (a multiply) instead of adding the rail colour over them
    col*=1.+.8*mB*min(mH*(.6+.6*fz)+mP*(.25+.3*fz)+.45*uHit,1.)+.5*min(mX,1.)*(1.-mR);
    col+=fz*Ch*mB*(.03+.97*al)*(mH*.3+mP*.12+.06*uHit);
    // a crisp neon spine down the middle of every giant strand: its bright head rides the beat clock (a narrow head
    // with a soft tail behind it, not a broad halo)
    col=mix(col,Ch*(.3+2.6*mH+.5*mP),clamp((max(.012,1.2*pm)-dS)/pm+.5,0.,1.)*mB*step(.5,bq)*(.5+.5*fz));
  }
  // rails: the band edge is a tube sitting in a dark groove (a crisp black separation from the cable); its core is the
  // bassline's inlay line, and the snare flashes the rail body
  col=mix(col*mMul+Cn*.19*(1.-kRib)*mG*(1.-al)*(1.-fz),mix(Cn*(.05+1.35*mRb)+(Cn*.75+.25)*mRc+(Cn*1.45+.12)*mRb*(1.1*uHit+.7*mH),mBr*(1.+1.2*uHit+1.*mH),mBw),mR);
  // the wipe front: a thin crisp seam with a short dark gap just ahead of it; the spinning-in tiles do the reveal
  if(wp<1.){
    float dpx=(wr-wp)*1.05*uRes.y,on=smoothstep(1.,.92,wp)*smoothstep(0.,.02,wp);
    col*=1.-.75*on*smoothstep(-1.5,.5,dpx)*exp(-max(dpx,0.)/(8.+uRes.y*.006));
    col+=mix(kc2,vec3(1.),.35)*1.2*on*smoothstep(2.2,.8,abs(dpx));
  }
  // lens bezel: a dark groove with an inner and an outer neon line and a ring of 48 beads lit by the spectrum (bass at
  // the bottom, treble at the top, mirrored), a soft shadow outside and a glassy rim highlight inside
  {
    // lens space u: every width scales with the medallion's size and the zoom, lines stay at least a pixel wide
    float rS=length(lv),kz=clamp(lR/.3,.4,1.),lo=min(lR*16.,1.);
    float pxs=1./(uRes.y*zl),dl=rS-lR,ad=abs(dl);
    // bead angle from the bottom (0) to the top (pi) of the lens, on either side (a cheap arctangent); beads sit at 1/24
    // turn steps along the ring
    float ta=knAt(abs(lv.x),-lv.y)/PI,fb=fract(ta*24.+.5)-.5;
    float bd=length(vec2(fb*.1308997*lR,dl)),lb=knB(ta),br=(.0065+.003*lb)*kz;
    vec3 bc2=mix(kc0,kc3,ta);
    vec4 m=smoothstep(vec4(.06*kz,.019*kz+pxs,1.3*pxs,1.3*pxs),vec4(0.,.019*kz-pxs,.3*pxs,.3*pxs),vec4(dl,ad,abs(dl+.014*kz),abs(dl-.014*kz)));
    // the bezel is solid as soon as the lens starts to open; a soft vignette pulls the eye to the focal lens
    col*=1.-.55*lo*m.x*step(0.,dl);
    // a faint palette glow inside the glass lifts the lens over the field; the vocal range (hi-mid, presence) lights the
    // glass and the inner neon line, the onsets of that range flash it, the kick pulses the outer line
    col+=(kc1+kc3)*(.012+.035*uB2.y)*lo*step(dl,0.)*(1.-.5*rS/max(lR,.01));
    col=mix(col,kbg*.3,m.y*lo)+((kc1+.25*kz*kz)*(1.1+1.2*uB2.y+.8*uB2.x+2.2*uO2.y)*m.z+(kc3+.25*kz*kz)*(1.3+1.5*KN_KL)*m.w)*lo*kz;
    col=mix(col,bc2*(.35+2.4*lb*lb)+.15,smoothstep(br+pxs,br-pxs,bd)*lo*smoothstep(.5,1.4,br/pxs));
  }
  // the engine flashes the whole frame on a drop; keep the new tiling legible under it
  col*=1.-.25*uDrop;
  // (a touch more chroma and light overall: the frame stays as vivid as before with the rings and satellites gone)
#if HD>=1
  float lq=dot(col,vec3(.2126,.7152,.0722));col=max(lq+(col-lq)*(1.17+.15*kFz+.05+.012*float(HD)),0.)*1.02;
#else
  float lq=dot(col,vec3(.2126,.7152,.0722));col=max(lq+(col-lq)*(1.17+.15*kFz),0.)*1.01;
#endif
  fragColor=vec4(max(col,0.),0.);
}
`;
