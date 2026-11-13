const R_CATHEDRAL = `
#ifndef FILK
#define FILK 1.
#endif
#ifndef JWK
#define JWK 1.
#endif
// ELF — seeded exploration through a self-similar gothic temple with room-anchored jewelled residents.
// Every level of the fractal is the same cell: a pointed-arch nave along z, a pointed-arch aisle along x and
// an octagonal light shaft along y, with period 2, repeated at 1/3 scale per level about the origin. The temple
// is therefore exactly invariant under x -> x/3. The Explorer route visits real naves, shafts and coarser
// chapels without a fixed shrink/forward/down/left camera cycle.
// uP1 = camera pos + scale, uM1 = camera basis, uP2 = (material phase, hue, resident clock, shaft light),
// uP3..uP5 = elves 0-2 (pos + size), uM2 = elves 3-5 (pos).
#if HD>=1
#define ELLN (9+4*HD)
#endif
#if HD>=1
#define ELNS (10+8*HD)
#define ELNR (24+22*HD)
#define ELLAMP (3+2*min(HD-1,2)+2*max(HD-3,0))
#endif
float gFt,gT,gD2,gLv,gKd,gSc,gSh,gSig,gVt,gVast,gWk,gBt,gBr;
// D3D compile cost: the HLSL compiler expands every de() call site inline (cost grows faster than linearly) and
// unrolls constant-trip loops. Loops start at ELF0, a zero it cannot fold (uTime>=0), and the distance queries
// are gathered into four de() sites: march, surface taps, light visibility and reflection (the former bounce pass is gone).
// Samples, order and arithmetic of the remaining sites are unchanged.
#define ELF0 min(int(uTime),0)
// Curated jewel palettes for the architecture (the elves keep the global palette): deep stone, luminous accent
// (seams, lamps), glass (shafts, jewels, the beat ring) and gold (ribs, bezels, engraved medallions).
// uP2.x = palA*8 + palB + crossfade; uHue only turns them a little.
vec3 gStoneC,gAccC,gGlassC,gGoldC;
vec3 elfHueRot(vec3 c,float a){vec3 k=vec3(.57735);float co=cos(a);return max(c*co+cross(k,c)*sin(a)+k*dot(k,c)*(1.-co),0.);}
void elfPalette(){
  float code=floor(uP2.x),m=smoothstep(0.,1.,fract(uP2.x)),ha=.3*sin(TAU*uHue);
  // v14: the crossfade is accumulated unrotated and the two palettes are hue-rotated once at the end (the
  // rotation is linear, so this is the same colour for 1/4 of the rotate expressions -> fewer fxc instructions)
  vec3 SC=vec3(0.),AC=SC,GC=SC,OC=SC;
  for(int j=ELF0;j<2;j++){
    float id=j==0?floor(code/8.):mod(code,8.),w=j==0?1.-m:m;
    vec3 s,a,g,o;
    if(id<.5){s=vec3(.30,.07,.48);a=vec3(1.,.10,.50);g=vec3(.10,.85,1.);o=vec3(1.,.62,.18);}        // amethyst, magenta, cyan
    else if(id<1.5){s=vec3(.04,.12,.44);a=vec3(.12,.78,1.);g=vec3(1.,.50,.08);o=vec3(1.,.80,.36);}  // sapphire, ice, amber
    else if(id<2.5){s=vec3(.03,.34,.22);a=vec3(.30,1.,.35);g=vec3(1.,.10,.32);o=vec3(1.,.72,.24);}  // emerald, lime, ruby
    else if(id<3.5){s=vec3(.02,.24,.32);a=vec3(1.,.72,.06);g=vec3(1.,.18,.55);o=vec3(1.,.82,.45);}  // teal, gold, rose
    else if(id<4.5){s=vec3(.15,.06,.44);a=vec3(.62,1.,.12);g=vec3(.70,.30,1.);o=vec3(1.,.56,.14);}  // indigo, lime, violet
    else{s=vec3(.36,.02,.20);a=vec3(1.,.42,.02);g=vec3(.10,.70,1.);o=vec3(1.,.80,.30);}             // wine, orange, turquoise
    SC+=w*s;AC+=w*a;GC+=w*g;OC+=w*o;
  }
  gStoneC=elfHueRot(SC,ha);gAccC=elfHueRot(AC,ha);gGlassC=elfHueRot(GC,ha);gGoldC=elfHueRot(OC,ha);
}
// the recursive vault colours its levels in turn: accent, glass, gold, and a blend (the cycle steps every 8 beats)
vec3 elfLvC(float l){float c=mod(floor(l+.5)+floor(gBt/8.),4.);return c<.5?gAccC:(c<1.5?gGlassC:(c<2.5?gGoldC:mix(gAccC,gGlassC,.5)*1.15));}
float archIn(vec2 q,float w,float f){float h=abs(q.x);return min(2.*w-length(vec2(h+w,max(q.y,0.))),q.y+f);}
float octIn(vec2 q){q=abs(q);return .2713-max(max(q.x,q.y),(q.x+q.y)*.70711);}
float ribD(float x,float r0){x=abs(x)-r0;return x<-.06?1.:abs(mod(x+.1775,.355)-.1775);}
float de(vec3 p){
  float d=-1.,d2=-1.,s=1./243.;
  float m=max(abs(p.x),max(abs(p.y),abs(p.z)));
  float foot=max(gT,gSig*.02)*gFt,lodk=max(.75,2.2/sqrt(clamp(uDetail,.5,16.)))*clamp(uRes.y/680.,1.,1.6);
  // bridges and spiral stairs of the great levels (solid added back into the carved space)
  float bd=1e9,be=0.,bl=0.,bs=1.;
  gSh=0.;
  for(int i=ELF0;i<25;i++){
    if(m*s>.47){ // coarser levels are solid near the origin, so they are skipped there
      vec3 v=mod(p*s,2.)-1.;
      // the hole width (.6/s) against the pixel footprint: holes open smoothly once they span a couple of pixels
      float fd=clamp(.6/(s*foot*lodk)-1.,0.,1.);
      // a point well outside both the nave (|x| < .297) and aisle (|z| < .245) footprints of this level has none of
      // its space, shafts or bridges nearby: the level is skipped (about 40 % of all level evaluations)
      if(min(abs(v.x)-.297,abs(v.z)-.245)<.06){
      float a=archIn(v.xy,.297,.3779),b=archIn(v.zy,.2452,.3396),c=octIn(v.xz);
      // transverse ribs: arch-shaped bands standing proud of the vaults, flanking every crossing
      a=min(a,max(max(a-.045,ribD(v.z,.29)-.028),-.3-v.y));
      b=min(b,max(max(b-.04,ribD(v.x,.33)-.024),-.27-v.y));
      float c0=c;
      c=min(c,max(c-.035,ribD(v.y,.36)-.022));
      float sh=(1.-fd)*.32;
      float hi=max(a,max(b,c)),mi=max(min(a,b),min(max(a,b),c));
      hi=(hi-sh)/s;mi=(mi-sh)/s;
      gSh=max(gSh,smoothstep(0.,.1,c-sh)*fd);
      float li=float(i)-5.;
      // d2 = runner-up among this level and coarser ones only, so creases outline real edges, not the
      // ever-present finer pores
      if(hi>d){d2=max(d2,max(d,mi));d=hi;gLv=li;gSc=s;gKd=a>b&&a>c?0.:(b>c?1.:2.);}
      if(s<.05){
        // the great levels (27x and coarser): a cross of bridges spans every shaft well at floor height
#if HD>=2
        float cl0=min(abs(v.x),abs(v.z)),ra0=max(abs(v.x),abs(v.z)),yb0=abs(v.y+.355),pa0=fract(ra0*11.)-.5,rr0=length(v.xz);
        float arm=cl0-.04+.004*(1.-smoothstep(.006,.011,yb0)),slab=yb0-.022+.005*(1.-smoothstep(.024,.03,cl0))*smoothstep(.45,.38,abs(pa0))*smoothstep(.07,.082,rr0);
        float dk=max(max(arm,slab),mix(-1.,.0125-length(vec2(cl0,pa0/11.)),step(abs(floor(ra0*11.)-1.),.5)));
        dk=max(min(dk,max(rr0-.062+.5*max(yb0-.02,0.),yb0-.036)),-c0);
#else
        float arm=min(abs(v.x),abs(v.z))-.04,slab=abs(v.y+.355)-.022;
        float dk=max(max(arm,slab),-c0);
#endif
        float bb=dk/s;
        if(bb<bd){bd=bb;be=abs(arm-slab)/s;bl=li;bs=s;}
      }
      }
      if(fd<1.)break;
    }
    s*=3.;
  }
  gD2=d2;
  gBr=0.;if(bd<d){d=bd;gD2=bd-be;gLv=bl;gSc=bs;gKd=2.;gBr=1.;}
  return d;
}
// tetrahedron offsets k.xyy, k.yyx, k.yxy, k.xxx (k = (1,-1)) of the former nor()
vec3 elfTetra(int i){return vec3(float(((i+3)>>1)&1),float((i>>1)&1),float(i&1))*2.-1.;}
// Material hierarchy follows actual bay/arch coordinates at the camera's adjacent scales.
// Fine cells remain resolved geometry, with quieter diffuse pigment and rougher highlights.
vec3 elfStone(vec3 p,float lev,float lr0,float K,out float fine,out float trim,out float inner){
  fine=smoothstep(.5,3.5,lev+lr0);trim=0.;inner=0.;
  float coarse=floor(-lr0),phase=fract(-lr0),blend=smoothstep(0.,1.,phase);
  for(int j=ELF0;j<2;j++){
    float l=coarse+float(j),w=j==0?1.-blend:blend,scale=pow(3.,l);
    vec3 v=mod(p*scale,2.)-1.;
    float a=archIn(v.xy,.297,.3779),b=archIn(v.zy,.2452,.3396),c=octIn(v.xz);
    float hi=max(a,max(b,c)),shell=1.-smoothstep(.03,.22,abs(hi));
    // depth inside the great walls: the niches and windows cut into them are lit from within
    inner+=w*smoothstep(.10,.38,-hi);
    float rib=a>b?ribD(v.z,.29):ribD(v.x,.33);
    float raised=1.-smoothstep(.02,.06,rib);
    trim+=w*shell*raised;
  }
  // deep jewel-toned stone; finer cells recede so the great vaults read first; the transverse ribs are gilded
  // a polished, nearly neutral stone with a tint of the palette's stone colour: the coloured lights keep their
  // colour on it; the deep stone hue itself comes from the ambient fill
  vec3 stone=gStoneC*(.44-.22*fine);
  return mix(stone,gGoldC*.025,.75*trim*(1.-.7*fine));
}
vec3 elfP(int k){return k==0?uP3.xyz:k==1?uP4.xyz:k==2?uP5.xyz:k==3?uM2[0]:k==4?uM2[1]:uM2[2];}
// the residents' characters are cast in JS (three bits each in uP2.z): every room keeps the resident it always had
// (same hash as before), and the visiting elves of an encounter are cast so that a group is never six twins
float elfCharacter(int i){return min(mod(floor(uP2.z/exp2(3.*float(i))),8.),5.);}
// packet per pair of residents: fade0 + 256 fade1 (8 bits each) + 65536 (greet0 + 16 greet1) (4 bits each)
float elfFade(int i){
 float packet=i<2?uP3.w:(i<4?uP4.w:uP5.w);
 return (i%2)==0?mod(packet,256.)/255.:floor(mod(packet,65536.)/256.)/255.;
}
float elfGreet(int i){
 float g=floor((i<2?uP3.w:(i<4?uP4.w:uP5.w))/65536.);
 return (i%2)==0?mod(g,16.)/15.:floor(g/16.)/15.;
}
float elfW(int k){return (.82+.22*h11(elfCharacter(k)*7.13+1.7))*(1.+.12*clamp(uHit,0.,1.5));}
// Six room-anchored residents inhabit the recursive temple. No origin-scaled duplicate figures
// are teleported during room recycling; their original character designs remain unchanged.
vec3 elfPos(int i){return elfP(i);}
float elfR(int i){return max(.07*9.*elfW(i),1e-5);}
vec3 elfC(float fk){return pal(fk*.23+.07+uP2.y);}
// ---- a machine elf, drawn in its own billboard plane (q: body radius ~ .55, y up). rgb = light, a = cover ----
float sdStar(vec2 p,float r,float n,float m){
  float an=PI/n,en=PI/m;vec2 acs=vec2(cos(an),sin(an)),ecs=vec2(cos(en),sin(en));
  float bn=mod(atan(p.x,p.y),2.*an)-an;
  p=length(p)*vec2(cos(bn),abs(sin(bn)));p-=r*acs;p+=ecs*clamp(-dot(p,ecs),0.,r*acs.y/ecs.y);
  return length(p)*sign(p.x);
}
float sdSeg(vec2 p,vec2 a,vec2 b){vec2 pa=p-a,ba=b-a;return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.,1.));}
vec3 gemFacet(vec2 q,float r,float k,float px,out float edge){
  // a brilliant-cut jewel: 8 sectors x 3 rings, each facet lit by a slowly wheeling light
  float an=atan(q.y,q.x),lq=length(q),l=lq/r;
  float N=8.,ring=l<.34?0.:(l<.62?1.:2.);
  float off=ring==1.?.5:0.;
  float sec=floor(an/TAU*N+.5+off)-off,ac=sec/N*TAU;
  float da=abs(fract(an/TAU*N+.5+off)-.5)*TAU/N*lq;
  float dr=min(abs(l-.34),abs(l-.62))*r;
  edge=smoothstep(px*1.5,0.,min(da*step(.34,l),dr));
  float tl=ring*.42;
  vec3 n=normalize(vec3(cos(ac)*tl,sin(ac)*tl,1.));
  vec3 L=normalize(vec3(cos(uTime*.9+k*2.),sin(uTime*.7+k),1.1));
  float b=.12+.88*pow(max(dot(n,L),0.),4.)+.25*h11(sec+ring*9.+k*31.);
  return pal(k*.23+sec*.061+ring*.29+uP2.y)*b;
}
float rune(vec2 g,float h,float px);
vec4 elfDraw(vec2 q,float k,float px,float face,float greet,vec2 par,vec3 Ld,out vec2 eyeq,out float eyem){
  float hk=h11(k*7.13+1.7),kb3=mod(floor(k+.5),3.);
  q*=kb3<.5?vec2(1.):(kb3<1.5?vec2(.88,1.12):vec2(1.1,.9));   // three builds: round, squat and wide, tall and narrow
  q*=vec2(1.+.06*uKick,1.-.08*uKick);                              // the kick squashes the whole figure for an instant
  float det=smoothstep(.07,.03,px);   // small on screen: drop the fine jewellery instead of letting it fizz
  float cf=cos(face);
  q.x=(q.x-sin(face)*.12)/max(abs(cf),.35);           // turning: the figure narrows and its features slide
  float bob=sin(uTime*3.+k*2.)*.04;q.y-=bob;
  vec3 col=vec3(0.);
  float ax=abs(q.x);
  // halo: two counter-turning star polygons and a wheel of jewels, spinning with the hats
  vec2 hq=q-vec2(0.,.3)+par*.34;float hr=length(hq),ha=atan(hq.y,hq.x);   // the halo floats behind the body
  float N=5.+2.*floor(hk*4.);
  float spin=(uTime*(.4+.5*hk)+uMT*uBuild*.6)*(hk>.5?1.:-1.)+uMT*.031;
  // the two star polygons share one sdStar() expansion
  float s1=0.,s2=0.;
  for(int si=ELF0;si<2;si++){
    bool a=si==0;
    float sd=sdStar(a?rot(spin)*hq:rot(-spin*1.3+.3)*hq,a?1.22+.08*uHat:.98,a?N:N*2.,a?2.3:3.2);
    if(a)s1=sd;else s2=sd;
  }
  float halo=smoothstep(px*1.6,0.,abs(s1))+smoothstep(px*1.6,0.,abs(s2))*.55;
  float da=TAU/(N*2.),dai=floor((ha+spin*.7)/da+.5);
  vec2 dq=hq-1.06*vec2(cos(dai*da-spin*.7),sin(dai*da-spin*.7));
  float dot1=length(dq);
  // The figure's eleven palette colours share one pal() expansion. Their arguments are the original ones;
  // the body-eye sector, pupil offset and iris radius are only computed earlier.
  float bn=atan(q.y,q.x),bsec=floor(bn/TAU*8.)+.5,bac=bsec/8.*TAU;
  vec2 gzb=vec2(h11(uP2.z+k*3.1)-.5,h11(uP2.z*1.3+k*5.7)-.5);
  gzb*=1.-greet; // greeting: every eye looks straight at the visitor
  vec2 gz=gzb,eq=q-vec2(0.,.02)+par*.17,iq=eq-gz*vec2(.16,.05);   // the eye sits on the front of the ball: it slides toward the viewer's side
  float ir=length(iq);
  vec3 c50=vec3(0.),c00=c50,c25=c50,c60=c50,c40=c50,c15=c50,c30=c50,cDot=c50,cBec=c50,cBell=c50,cIris=c50;
  for(int pi=ELF0;pi<11;pi++){
    float off=pi==0?.5:(pi==1?0.:(pi==2?.25:(pi==3?.6:(pi==4?.4:(pi==5?.15:.3)))));
    float fk=k+off;
    float arg=pi<7?fk*.23+.07+uP2.y:(pi==7?k*.23+dai*.09+.3:(pi==8?k*.23+bsec*.125:(pi==9?k*.23+.9:k*.23+.45+ir*2.)));
    vec3 c=pal(arg);
    if(pi==0)c50=c;else if(pi==1)c00=c;else if(pi==2)c25=c;else if(pi==3)c60=c;else if(pi==4)c40=c;else if(pi==5)c15=c;
    else if(pi==6)c30=c;else if(pi==7)cDot=c;else if(pi==8)cBec=c;else if(pi==9)cBell=c;else cIris=c;
  }
  col+=c50*halo*(.45+.9*uHat+.6*uKick);
  col+=cDot*(smoothstep(.045+px,.045-px,dot1)*2.2+exp(-dot1*30.)*.5);
  col+=c00*exp(-hr*2.4)*.22;
  // arms: two waving tendrils with glowing hands
  // greeting: both arms wave overhead, swinging with the beat
  float wv=mix(sin(uTime*4.+k)*.5+uMid*.6,.9+.6*cos(uBeat*TAU),greet);
  vec2 aq=vec2(ax,q.y);
  float tx=clamp((ax-.45)/.75,0.,1.);
  // in the workshop the elves are at work: both arms swing up through the beat and strike down on the kick, the hands
  // flashing at the strike (a greeting elf stops work to wave)
  float work=gWk*(1.-greet),lift=work*(1.15*smoothstep(0.,.8,uBeat)*(1.-smoothstep(.86,1.,uBeat))-.3),swg=(.25+.35*wv)*(1.-work);
  float ay=.05+tx*swg*sin(tx*3.+uTime*2.+k)+tx*tx*(.4*uHit+lift);
  float arm=abs(q.y-ay)-mix(.045,.012,tx);
  float armM=step(.45,ax)*step(ax,1.2);
  vec2 hand=vec2(1.2,.05+swg*sin(3.+uTime*2.+k)+.4*uHit+lift);
  col+=c25*smoothstep(px*1.5,0.,arm)*armM*1.4;
  float hd=length(aq-hand);
  col+=c60*(smoothstep(.07+px,.07-px,hd)*3.+exp(-hd*14.)*.8*(1.+3.*work*(1.-smoothstep(0.,.25,uBeat))));
  // spinning-top point below
  float tip=sdSeg(q,vec2(0.,-.45),vec2(0.,-1.05))-mix(.12,.0,clamp((-q.y-.45)/.6,0.,1.));
  float tipM=smoothstep(px,-px,tip);
  // body: faceted gem
  float bd=length(q)-.55;
  float bM=smoothstep(px,-px,bd);
  // body and head gems share one gemFacet() expansion
  vec2 hq2=q-vec2(0.,.8)+par*.09;
  float e1=0.,e2=0.;vec3 g1=vec3(0.),g2=vec3(0.);
  for(int gi=ELF0;gi<2;gi++){
    bool a=gi==0;float eg;
    vec3 gg=gemFacet(a?q:hq2.yx,a?.55:.27,a?k:k+3.,px,eg);
    if(a){g1=gg;e1=eg;}else{g2=gg;e2=eg;}
  }
  // a wheel of small eyes on the outer facets, all looking the same way
  vec2 bc=.42*vec2(cos(bac),sin(bac)),bq=q-bc;
  bq=vec2(dot(bq,vec2(-sin(bac),cos(bac))),dot(bq,vec2(cos(bac),sin(bac))));
  float bal=length(vec2(bq.x,bq.y*1.9))-.062;
  float beM=smoothstep(px,-px,bal)*bM;
  float bpr=length(q-bc-gzb*.035);
  vec3 bec=mix(vec3(1.4,1.35,1.25),cBec*1.8,smoothstep(.04,.03,bpr))*smoothstep(.012,.02+px,bpr);
  g1=mix(g1,bec,beM*det);
  // head: smaller gem with two little eyes
  float hdd=length(hq2)-.27;
  float hM=smoothstep(px,-px,hdd);
  // cap: two curling horns with bells
  vec2 cq=vec2(ax,q.y)-vec2(.12,.98);
  float th=clamp(cq.y/.55,0.,1.);
  vec2 hc=vec2(.32*th*th+.1*sin(th*5.+uTime*2.)*th,th*.55);
  float horn=length(cq-hc)-mix(.09,.015,th);
  horn=max(horn,-cq.y-.05);
  float cM=smoothstep(px,-px,horn)*step(-.05,cq.y);
  vec2 bell=vec2(.12,.98)+vec2(.32+.1*sin(5.+uTime*2.),.55);
  float bl=length(vec2(ax,q.y)-bell);
  col+=cBell*(smoothstep(.06+px,.06-px,bl)*2.5+exp(-bl*16.)*.6)*(1.+2.*uHat);
  float cover=max(max(bM,hM),max(cM,tipM));
  // a thin ink outline round the silhouette (about 1.5 render pixels) keeps the figure crisp against bright stone and
  // through the upscale at lower render resolutions
  float od=min(min(bd,hdd),min(max(horn,-cq.y-.05),tip));
  float ink=smoothstep(px*1.25,px*.45,od)*(1.-cover);
  // (v20c) volume: both gems are balls under one light (lit side, deep shade, a hard glint), the head drops a shadow on the body's crown, the horns
  // are round in section, the tip has a lit and a dark flank
  {vec3 nb=vec3(q/.55,0.),nh=vec3(hq2/.27,0.);nb.z=sqrt(max(1.-dot(nb.xy,nb.xy),0.));nh.z=sqrt(max(1.-dot(nh.xy,nh.xy),0.));
   g1=(g1*(.42+.9*max(dot(nb,Ld),0.))+c60*.3*max(dot(nb,vec3(-Ld.xy,.2)),0.))*(1.-.5*smoothstep(.5,.24,length(q-vec2(0.,.66))))+vec3(1.,.97,.9)*pow(max(reflect(-Ld,nb).z,0.),26.)*.9*det;
   g2=g2*(.42+.9*max(dot(nh,Ld),0.))+c60*.3*max(dot(nh,vec3(-Ld.xy,.2)),0.)+vec3(1.,.97,.9)*pow(max(reflect(-Ld,nh).z,0.),26.)*.8*det;}
  vec3 body=g1*bM+c40*(.45+.75*smoothstep(0.,-.05,horn))*cM*(1.-bM)+c15*tipM*(1.-bM)*(.4+.6*clamp(-q.y-.45,0.,1.))*(.5+.8*smoothstep(-.07,.07,q.x*sign(Ld.x+1e-4)));
  body=mix(body,g2,hM);
  body+=vec3(1.,.95,.9)*(e1*bM+e2*hM)*.5*det;
  // rim light so the silhouette reads against the dark
  body+=c30*smoothstep(-.06,0.,bd)*bM*1.2+c30*smoothstep(-.04,0.,hdd)*hM;
  col=mix(col,body*1.3,cover);
  // eyes: a great almond eye in the body, two in the head; pupils dart to a new place on every hit
  float blink=step(.96,fract(uTime*.31+hk*7.));
  float ew=.3,eh=.17*(1.-blink*.9);
  // almond: intersection of two discs
  float rr=(ew*ew+eh*eh)/(2.*eh);
  float alm=max(length(eq-vec2(0.,eh-rr)),length(eq+vec2(0.,eh-rr)))-rr;
  float eM=smoothstep(px,-px,alm);
  vec3 eyeC=mix(vec3(1.,.97,.9)*1.6,cIris*2.2,smoothstep(.115+px,.115-px,ir));
  eyeC*=smoothstep(.035,.05+px,ir*(1.+.4*uKick));
  eyeC+=vec3(2.)*smoothstep(.022+px,.022-px,length(iq-vec2(.03,.03)));
  col=mix(col,eyeC,eM);
  eyeq=iq/.11;eyem=eM*smoothstep(.115+px,.115-px,ir)*smoothstep(.02,.05,ir);
  vec2 sq=vec2(ax,q.y)-vec2(.1,.82);
  float se=length(sq*vec2(1.,1.6))-.055*(1.-blink);
  float sir=length(sq-gz*.03);
  col=mix(col,mix(vec3(2.),vec3(0.),smoothstep(.03,.02,sir)),smoothstep(px,-px,se));
  // a ring of glyphs orbits a greeting elf like a comet trail; a snare throws it outward and lights it up.
  // The glyphs change on every beat (the elf is speaking).
  float gAmt=clamp(greet*.85+.8*uHit*uHit,0.,1.)*smoothstep(.06,.025,px);
  if(gAmt>.01){
    float gsp=spin*.5,cell=TAU/10.,ai=floor((atan(q.y,q.x)-gsp)/cell+.5),ac=ai*cell+gsp;
    vec2 gl=q-vec2(cos(ac),sin(ac))*(1.3+.28*uHit);
    gl=vec2(dot(gl,vec2(-sin(ac),cos(ac))),dot(gl,vec2(cos(ac),sin(ac))));
    float tail=pow(fract(ai/10.-uTime*.35*(hk>.5?1.:-1.)),2.);
    float gm=rune(gl/.12,ai+floor(uBar*4.)*7.+k*13.,px/.12*1.5)*step(max(abs(gl.x),abs(gl.y)),.13);
    col+=mix(cDot,c60,tail)*gm*(.25+1.6*tail)*gAmt*1.6;
  }
  col=mix(col,vec3(.015,.01,.03),ink*.9);
  return vec4(col,max(max(cover,eM),ink*.9));
}
// Stable far-to-near order of actual candidate billboard planes, bounded to eighteen layers.
// The insertion sort usually handles only the few figures overlapping this ray.
// v14: the plane data it already computes (depth, radius, billboard coords) is passed out in pk[] so the
// compositing loop does not have to evaluate elfPos/elfR/depth/q a second time.
int elfLayerOrder(vec3 ro,vec3 rd,vec3 ww,vec3 uu,vec3 vv,float surfaceT,out int ids[6],out vec4 pk[6]){
  float depths[6];int count=0;
  for(int i=ELF0;i<6;i++){
    if(elfFade(i)<.002)continue;
    vec3 E=elfPos(i);float R=elfR(i),depth=dot(E-ro,ww)/dot(rd,ww);
    if(depth<=0.||depth>=surfaceT)continue;
    vec3 X=ro+rd*depth-E;vec2 q=vec2(dot(X,uu),dot(X,vv))/R;
    if(dot(q,q)>=3.)continue;
    int slot=count;
    for(int j=ELF0;j<6;j++){
      if(slot<=0)break;
      if(depth<=depths[slot-1])break;
      depths[slot]=depths[slot-1];ids[slot]=ids[slot-1];pk[slot]=pk[slot-1];slot--;
    }
    depths[slot]=depth;ids[slot]=i;pk[slot]=vec4(depth,R,q);count++;
  }
  return count;
}
// a little mirror-symmetric rune: up to six strokes on a 3x3 grid, chosen by the hash h
float rune(vec2 g,float h,float px){
  g.x=abs(g.x);float d=1e3;
  for(int i=ELF0;i<6;i++){
    float fi=float(i);
    if(h11(h*7.31+fi*3.17)>.5){
      vec2 a=i==0?vec2(0.,.6):i==1?vec2(0.,0.):i==2?vec2(0.,-.6):i==3?vec2(.6,-.6):i==4?vec2(0.,-.6):vec2(0.,.6);
      vec2 b=i==0?vec2(.6,.6):i==1?vec2(.6,0.):i==2?vec2(.6,-.6):i==3?vec2(.6,.6):i==4?vec2(0.,.6):vec2(.6,-.6);
      d=min(d,sdSeg(g,a,b));
    }
  }
  return smoothstep(.09+px,.09-px,d);
}
// emission of the glowing seams at a surface point (de() must have just been called there)
// lv, d2, sc: de()'s gLv, gD2, gSc at that point
vec3 seamGlowP(float d,float t,float lr0,float K,float lv,float d2,float sc){
  float foot=gFt*t,lr=lv+lr0,ab=lv+K,e2=d-d2;
  float wpx=.6/(sc*foot);  // on-screen width of the opening, in pixels: small ones fade out instead of fizzing
  // the soft halo only on near stone: on far walls nearly coplanar faces of two levels would flood with it
  // v14 clarity: a crisper core and a weaker, tighter halo. The old wide halo was the bright veil that crossed the
  // walls between the actual creases, so the architecture reads more clearly at the same seam brightness.
  float seam=(smoothstep(foot*1.26,0.,e2)+.26*exp(-e2/(foot*2.1))*(1.-smoothstep(1.,2.5,lv+lr0))*exp(-t/gSig*.25)*(1.-gVast))*smoothstep(8.,44.,wpx);
  // each level of the fractal sings its own band of the spectrum: the great arches the bass, the fine tracery the highs
  float sp=spec(clamp((lr+1.)/6.,0.,1.));
  float wv=t/gSig-1.2-uBeat*9.;float wave=exp(-wv*wv*10.)*(1.-.6*uBeat)*smoothstep(0.,.12,uBeat);   // a pulse of light runs down the nave on every beat
  // v12: hats and the air band sparkle the fine tracery (it otherwise sits dim behind the great arches)
  // v14: the tracery responds to hats/air from one level coarser and about 45 % harder, so the highest sounds draw
  // bright line work over the fine cells instead of a barely visible shimmer
  float hierarchy=mix(1.,.07+1.15*uHat+.9*max(uB2.z+uB2.w-.6,0.),smoothstep(.35,2.8,lr));   // v13: hats/air brighter on the tracery
  hierarchy=mix(hierarchy,max(hierarchy,.55),gVt); // the recursive vault: every level of the recursion is drawn
  // the great arches are drawn in the accent colour, the fine tracery shifts toward the glass colour
  vec3 scol=mix(gAccC,gGlassC,mix(.65*smoothstep(.5,2.5,lr),step(.5,fract(lr*.5+.01)),gVt));
  // the recursive vault: every level of the recursion burns in a hue of its own and a pulse of light flows inward
  // through the levels, one level every two beats
  if(gVt>.01){scol=mix(scol,elfLvC(lv)*1.3,gVt*.85);hierarchy*=1.+gVt*(3.5*exp(-5.*fract(gBt*.5-lr*.5))+.4);}
  // onsets per band: the sub lights the great arches, the low-mids the camera's own level, the hi-mids the tracery
  float on=mix(mix(uO1.x,uO1.z,smoothstep(-.5,.5,lr)),uO2.x,smoothstep(.5,1.5,lr));
  // v12: the kick flares the great arches, the snare the middle tracery, the low-mids and mids swell the camera's
  // own level (light only; geometry never moves with the audio)
  float lA=1.-smoothstep(.3,1.3,lr),lM=smoothstep(.2,1.,lr)*(1.-smoothstep(1.8,2.8,lr));
  return scol*seam*hierarchy*(1.06+2.5*sp*sp*uDose+2.*wave*(.15+uKick)+1.2*on*uDose+3.*min(uDrop,1.)+.75*uBuild
    +3.7*uKick*lA+5.*uHit*lM+2.*max(uB1.z+uB1.w-.7,0.)*(1.-lA));
}
// v14: the analytic in-scattered elf glow (a per-ray atan integral over all six residents) is gone. It was a dim
// additive veil (5 % of a palette colour) that the engine's bloom already provides around the bright figures; A/B
// renders of the same seeds are indistinguishable apart from slightly cleaner stone, and it cost 216 fxc
// instructions. The elves still light the stone and each other (the elf light loop below is untouched).
void realm(){
  // zooming in narrows the lens; zooming out is done in JS (the camera pulls back and the lens widens, uP1.w)
  vec2 p=scr()/max(uZoom,1.);
  // the camera basis carries the explorer's scale (|forward| = scale/9, it shrinks through the recursive vault);
  // the right vector is free for the room theme, the vastness of the space and the beat count
  float ks=max(length(uM1[2]),1e-3),sig=9.*ks;gSig=sig;
  vec3 ro=uP1.xyz;
  elfPalette();
  vec3 ww=uM1[2]/ks,vv=uM1[1]/ks,uu=cross(ww,vv);
  vec3 TH=uM1[0];
  float thc=floor(TH.x),thm=smoothstep(0.,1.,fract(TH.x)),thA=floor(thc/8.),thB=mod(thc,8.);
  float wCr=(abs(thA-1.)<.5?1.-thm:0.)+(abs(thB-1.)<.5?thm:0.);   // crystal grotto
  float wWk=(abs(thA-2.)<.5?1.-thm:0.)+(abs(thB-2.)<.5?thm:0.);   // elf workshop
  float wGd=(abs(thA-3.)<.5?1.-thm:0.)+(abs(thB-3.)<.5?thm:0.);   // garden of light
  float wVt=(abs(thA-4.)<.5?1.-thm:0.)+(abs(thB-4.)<.5?thm:0.);   // recursive vault
  gVt=wVt;
  float quiet=smoothstep(.3,.8,fract(TH.y)),vast=clamp(floor(TH.y)/255.,0.,1.)*(1.-.8*wVt),beats=TH.z;gVast=vast;gWk=wWk;gBt=beats;
  vec2 lp=p+uLook*vec2(.5,.35);
  float fl=clamp(uP1.w,.5,1.6); // eased in JS: narrows through a build, opens on the drop and when zoomed out
  vec3 rd=normalize(lp.x*uu+lp.y*vv+fl*ww);
  gFt=1.25/(uRes.y*max(uZoom,1.)*fl);
  // the camera's own scale, in levels; in the great halls (and zoomed out) the light hierarchy shifts one level coarser,
  // so the hall's own architecture carries the light and the thousands of small cells on its far walls recede
  float lr0=log(sig)/log(3.)+1.1*vast;
  float det=clamp(uDetail,.5,16.),zoW=clamp((1.-uZoom)/.6,0.,1.);
  // in the great halls (and zoomed out) the view reaches much further through thinner haze
  float tmax=(16.+min(det,8.))*sig*(1.+3.*vast),t=.005*sig,d=1.,vol=0.;
  bool surface=false;
  float steps=min(90.*det*(1.+.4*vast),1536.);
  float K=0.;
  // the great halls fill with luminous coloured haze, layer behind layer: light from above, deep colour below
  // (the light that fills them is the stone's own hue, so the stone keeps its colour instead of greying under a
  // complementary light; the glass and accent colours ride in the beams, domes and lines)
  vec3 stoneH=gStoneC/max(max(gStoneC.r,gStoneC.g),max(gStoneC.b,1e-3));
  vec3 hazeV=stoneH*mix(.04,.14,smoothstep(-.6,.8,rd.y))+gGlassC*.015;
  vec3 fogc=mix(gStoneC*.012+stoneH*.022*quiet,hazeV,vast);
  // the recursive vault: the depths blaze with light and the nested arches stand against it in silhouette
  fogc=mix(fogc,elfHueRot(gGlassC,gBt*TAU/64.)*.11,wVt);
  vec3 col=fogc;
  vec3 skyC=gGlassC; // glass colour, shared by the lantern, oculi, bezels and shafts
  vec3 pos=vec3(0.),nn=vec3(0.),nw=vec3(0.),stone=vec3(0.),sg=vec3(0.),an=vec3(0.);
  vec2 suv=vec2(0.),jq=vec2(0.);
  float br=0.,lv=0.,shv=0.,lvS=0.,d2S=0.,sc=1.,kd=0.,ab=0.,lr=0.,foot=0.,oc=0.,ocW=0.,hs=0.,fineStone=0.,specHierarchy=1.,head=0.,crease=0.;
  float mqL=0.,mqC=0.,dA=0.,sAm=0.,tAm=0.,rsI=0.,gAm=0.,diL=0.,diP=0.;vec3 mqT=vec3(0.),rsC=vec3(0.);
  float pxs=0.,jr=0.,jrad=.13,jw=0.,jh=0.,rf=0.,jflat=0.,innerS=0.,trimS=0.;
  vec3 lantern=vec3(0.),lampDir=vec3(0.),bay=vec3(0.),nave=vec3(0.);float lampDist=1.,lampDif=0.;
#if HD>=1
  float shA[ELLAMP];for(int li0=ELF0;li0<ELLAMP;li0++)shA[li0]=1.;float shRes=1.,rflHit=0.,rTH=0.,rLvH=0.,rD2H=0.,rDH=0.,rBrH=0.;vec3 rDirH=vec3(0.),rPosH=vec3(0.),rnH=vec3(0.,1.,0.);
#endif
  for(int i=ELF0;i<1536;i++){
    if(float(i)>steps)break;
    gT=t;d=de(ro+rd*t);
    float st=d*.85;
    vol+=gSh*min(st,.2*sig)/sig;
    if(d<gFt*t*max(.16,.35/sqrt(det))){surface=true;break;}
    if(t>tmax)break;
    t+=st;
  }
  // a ray that ran out of steps grazing a silhouette is on that surface, not a hole into the black
  if(!surface&&t<tmax&&d<gFt*t*3.)surface=true;
  if(!surface){
#if HD>=1
    // (v20b) beyond the last arch the night is a far wall of leaded quarries in deep jewel glass, never a black hole
    vec2 e=vec2(atan(rd.z,rd.x),atan(rd.y,length(rd.xz)))*28./PI,ab2=vec2(e.x+e.y,e.x-e.y),qf=abs(fract(ab2)-.5);
    float qh=h21(floor(ab2)+floor(uP2.x)),ql=.5-max(qf.x,qf.y),qp=28.*gFt*1.5;
    vec3 qc=qh<.4?stoneH:(qh<.6?gGlassC:(qh<.8?gAccC:gGoldC));
    col=mix(fogc,qc*qc*(.07+.1*qh+.5*spec(fract(qh*7.3))*uDose*step(.6,qh))*smoothstep(.03,.03+qp,ql),(1.-vast)*(1.-wVt));
#else
    col=mix(fogc,stoneH*stoneH*.1,(1.-vast)*(1.-wVt));
#endif
  }
  if(surface){
    // the march's last de() call was at this very point (gT=t), so its globals describe the surface
    pos=ro+rd*t;
    lv=gLv;shv=gSh;sc=gSc;kd=gKd;lvS=lv;d2S=gD2;br=gBr;
    // surface taps share one de() expansion: 0-3 normal, 4-7 wide normal, 8.. occlusion
    hs=.3/sc;
    float ftn=gFt*t;vec4 nTap=vec4(0.);vec2 nE=vec2(1.,-1.);
#if HD>=1
    // v19 (Native and up): the one de() expansion of the surface taps also marches the lantern's shadow ray and a mirror ray with its own normal.
    // A small state machine advances through normal taps, occlusion, shadow, mirror, mirror normal; loop bound ELNS + ELNR grows with the tier.
    int phase=0,oK=1,ti=0,shIt=0,rIt=0,ls=0;float shT=0.,shDist=1.,shR=1.;vec3 shDir=vec3(0.),rOr=pos,rTapV=vec3(0.);vec4 rTapW=vec4(0.);
    for(int j=ELF0;j<26+(ELLAMP+1)*ELNS+ELNR;j++){
      if(phase==5)break;
      vec3 q=pos;float h=0.,w=0.;
      if(phase==0){q=pos+elfTetra(j-4*(j/4))*(j<4?ftn*.5:ftn*3.);}
      else if(phase==1){h=hs*float(oK)*.2;w=1./float(oK);q=pos+nn*h;}
      else if(phase==2){
        if(shIt==0){
          vec3 LV=ls==0?ro+(uu*.03+vv*.04)*sig-pos:(floor(pos*sc*.5)*2.+1.)/sc+(vec3(0.,.38,0.)+(kd<.5?vec3(0.,0.,1.):vec3(1.,0.,0.))*(float(ls-1)-.5*float(ELLAMP-1))*2.)/sc-pos;
          shDist=max(length(LV),1e-6);shDir=LV/shDist;shT=ftn*8.;shR=1.;
        }
        q=pos+nn*ftn*2.+shDir*shT;gT=t+shT;
      }
      else if(phase==3){q=rOr+rDirH*rTH;gT=t+rTH;}
      else{q=rPosH+elfTetra(ti)*gFt*(t+rTH)*1.5;}
      float dj=de(q);
      if(phase==0){
        int m=j-4*(j/4);
        if(m==0)nTap.x=dj;else if(m==1)nTap.y=dj;else if(m==2)nTap.z=dj;else nTap.w=dj;
        if(m==3){vec3 nj=normalize(nE.xyy*nTap.x+nE.yyx*nTap.y+nE.yxy*nTap.z+nE.xxx*nTap.w+1e-9);if(j==3)nn=nj;else nw=nj;}
        if(j==7)phase=1;
      }else if(phase==1){
        oc+=clamp(1.-dj/h,0.,1.)*w;ocW+=w;oK++;
        if(float(oK)>min(12.,3.+det))phase=2;
      }else if(phase==2){
        shR=min(shR,clamp(11.*dj/max(shT,1e-6),0.,1.));shT+=max(dj*.9,shT*.05+ftn);shIt++;
        if(dj<ftn*.3)shR=0.;
        if(dj<ftn*.3||shT>shDist*.95||shIt>=ELNS){
          if(ls==0)shRes=shR;else shA[ls-1]=shR;
          ls++;shIt=0;
          if(ls>ELLAMP){rDirH=reflect(rd,nn);rOr=pos+nn*ftn*3.;rTH=ftn*6.;phase=3;}
        }
      }else if(phase==3){
        float eR=gFt*(t+rTH)*.4;
        if(dj<eR&&rIt>0){rflHit=1.;rPosH=q;rLvH=gLv;rD2H=gD2;rDH=dj;rBrH=gBr;phase=4;}
        else{rTH+=dj*.85;rIt++;if(rTH>tmax||rIt>=ELNR)phase=5;}
      }else{
        if(ti==0)rTapW.x=dj;else if(ti==1)rTapW.y=dj;else if(ti==2)rTapW.z=dj;else rTapW.w=dj;
        ti++;
        if(ti==4){rnH=normalize(nE.xyy*rTapW.x+nE.yyx*rTapW.y+nE.yxy*rTapW.z+nE.xxx*rTapW.w+1e-9);phase=5;}
      }
    }
#else
    for(int j=ELF0;j<20;j++){
      vec3 tp=vec3(0.),q;float h=0.,w=0.;
      if(j<8){tp=elfTetra(j-4*(j/4));q=pos+tp*(j<4?ftn*.5:ftn*3.);}
      else{int k=j-7;if(float(k)>min(12.,3.+det))break;h=hs*float(k)*.2;w=1./float(k);q=pos+nn*h;}
      float dj=de(q);
      if(j<8){int m=j-4*(j/4);if(m==0)nTap.x=dj;else if(m==1)nTap.y=dj;else if(m==2)nTap.z=dj;else nTap.w=dj;if(m==3){vec3 nj=normalize(nE.xyy*nTap.x+nE.yyx*nTap.y+nE.yxy*nTap.z+nE.xxx*nTap.w+1e-9);if(j==3)nn=nj;else nw=nj;}}
      else{oc+=clamp(1.-dj/h,0.,1.)*w;ocW+=w;}
    }
#endif
    // the surface frame: crease, occlusion, material, lantern direction, inlay coordinates
    crease=smoothstep(.01,.15,1.-dot(nn,nw));
    ab=lv+K;lr=lv+lr0;foot=gFt*t;
    oc=clamp(1.-oc/max(ocW,1e-6),0.,1.);
    // a physical lantern stays within the camera path's proven clearance; it is thrown forward down the path
    lantern=ro+(uu*.03+vv*.04)*sig;
    stone=elfStone(pos,lv,lr0,uP2.x,fineStone,trimS,innerS);trimS*=1.-.7*fineStone;
    specHierarchy=mix(1.,.45,fineStone);
    head=max(dot(nn,-rd),0.);
    vec3 toLantern=lantern-pos;lampDist=max(length(toLantern),foot);lampDir=toLantern/lampDist;
    lampDif=max(dot(nn,lampDir),0.);
    // self-similar bay lamps hang in real scene coordinates at the scale of the level that made the surface
    bay=(floor(pos*sc*.5)*2.+1.)/sc;
    nave=kd<.5?vec3(0.,0.,1.):vec3(1.,0.,0.);
    an=abs(nn);
    vec3 q3=pos*sc*3.;
    suv=an.x>an.y&&an.x>an.z?q3.yz:(an.y>an.z?q3.xz:q3.xy);
    pxs=foot*sc*3./max(abs(dot(nn,rd)),.25);
    jq=mod(suv+1.,2.)-1.;jr=length(jq);
    jflat=smoothstep(.96,.995,max(an.x,max(an.y,an.z)));
    jw=smoothstep(jrad+.035+pxs,jrad+.035-pxs,jr)*smoothstep(.1,.035,pxs)*jflat;
    jh=h21(floor((suv+1.)*.5)+ab*7.);
    jw*=step(.4,jh)*(1.-br);
    // polished obsidian floors mirror the seams and the elves' light
    rf=smoothstep(.8,.97,nn.y)*(.3+.6*pow(max(1.-head,0.),4.))*(1.-jw);
    // (v20) marquetry: every flat cell of the explorer's own masonry is an inlaid panel. An eight-point star of lighter stone frames the jewel node,
    // a gilt hairline runs round it, the panel joints are cut grooves and the corners hold small tesserae that play the presence band and the hats.
    { float lk=clamp(log(.03/max(pxs,1e-5))*.91024,0.,5.),m0=floor(lk),mf=smoothstep(.15,.85,lk-m0),mq=jflat*(1.-smoothstep(1.4,2.3,lr))*(1.-.6*fineStone)*(1.-br);
      float sA=0.,gA=0.,tA=0.;
      for(int j=ELF0;j<2;j++){
        float k=pow(3.,m0+float(j)),px=pxs*k,fz=smoothstep(.09,.04,px)*(j==0?1.-mf:mf)*mq;
        vec2 qk=suv*k+1.,q=mod(qk,2.)-1.,ja=abs(q);float r=length(q),th=h21(floor(qk*.5)+ab*7.+k);
        float s8=min(max(ja.x,ja.y),(ja.x+ja.y)*.70711)-.46,cd=(2.-ja.x-ja.y)*.70711-.15,gv=1.-max(ja.x,ja.y);
        float sIn=smoothstep(px,-px,s8)*smoothstep(.2-px,.2+px,r);
        sA+=fz*sIn;gA+=fz*smoothstep(.035+px,.012,gv);tA+=fz*(th-.5);
        mqL+=fz*max(smoothstep(.02+px,.006,abs(s8)),.8*smoothstep(.014+px,.004,abs(r-.2)));
        float cm=fz*smoothstep(px,-px,cd);mqC+=cm;
        mqT+=cm*mix(gAccC,gGlassC,step(.5,fract(th*7.7)))*(1.+1.5*uHat*step(.45,fract(th*3.3))+1.1*uB2.y*uDose+.7*uO2.y);
#if HD>=1
        // (v20b) ROSE WINDOWS. Every block of three by three panels may hold a leaded rose: a gold hub, eight inner and eight outer panes in the
        // palette's three pure colours, black leads between them. On walls they are the windows the night cathedral is lit by, on floors the light
        // they throw. Each pane burns steadily and plays its own band of the spectrum on top.
        { vec2 qw=suv*k/3.+1.,w2=mod(qw,2.)-1.;float wr=length(w2),wp=px/3.,wh=h21(floor(qw*.5)+ab*3.+k*.37);
          float ring=step(.5,wr),af=atan(w2.y,w2.x)/TAU*8.+.5*ring,pi2=floor(af),pf=.5-abs(fract(af)-.5);
          float lead=min(min(abs(wr-.2),abs(wr-.5)),min(abs(wr-.82),pf*.785*wr+step(wr,.2)));
          float on=fz*step(.34,wh)*smoothstep(.85+wp,.85-wp,wr),pane=smoothstep(.016+.4*wp,.022+1.6*wp,lead);
          float ci=mod(pi2+ring+floor(wh*9.),3.),bn=spec(fract((pi2+ring*8.)/16.+wh)*.8+.1);
          vec3 pc=wr<.2?gGoldC:(ci<.5?gAccC:(ci<1.5?gGlassC:gGoldC));
          // Native and up: every pane of a rose is leaded into quarries, each a shade of its own, and the hub carries a ring of eight pips
          { float f2=smoothstep(.03,.01,wp);vec2 rq=vec2(af*2.+wr*13.,af*2.-wr*13.);
            pane*=1.-.5*f2*step(.2,wr)*smoothstep(.09+wp*14.,.03,min(abs(fract(rq.x)-.5),abs(fract(rq.y)-.5)));
            pane*=1.+.5*f2*(h21(floor(rq)+wh*9.)-.5);
            pane*=1.-.6*f2*smoothstep(.035+wp,.02,length(vec2(wr-.12,(fract(af)-.5)*.785*wr))); }
          rsC+=on*pane*pc*(.5+.5*smoothstep(.2,.8,wr)+1.5*bn*bn*uDose+.6*uKick*step(wr,.2)+1.6*uHit*step(.5,fract(wh*5.)));rsI+=on*(1.-pane); }
#endif
#if HD>=1
        // Native and up: a second, finer order inside each star (a ring of sixteen darts) and a beaded joint
        { float fl2=smoothstep(.05,.018,px)*fz,a16=abs(fract(atan(q.y,q.x)*8./PI)-.5)*2.,dr=abs(r-.3)-.05*(1.-a16);
          dA+=fl2*sIn*smoothstep(px,-px,dr);
          mqL+=.6*fl2*sIn*smoothstep(.008+px,.002,abs(dr));
          gA+=.5*fl2*step(gv,.07)*step(.5,fract((ja.x>ja.y?q.y:q.x)*12.));
          // (v20b) the painted ground of every panel is diapered: a lozenge lattice in ink with a pip of light in each lozenge
          { vec2 dq=vec2(q.x+q.y,q.x-q.y)*4.,df=abs(fract(dq)-.5);float dg=fl2*(1.-sIn)*step(.1,gv);
            diL+=dg*smoothstep(.44-px*5.,.48,max(df.x,df.y));diP+=dg*smoothstep(.13+px*4.,.07,length(df)); } }
#endif
      }
      // the star is the lighter stone, alternate panels are a shade apart, the joints are cut grooves
      stone=mix(stone,stone*2.+gGlassC*.014,sA);sAm=sA;tAm=tA;gAm=max(min(gA,1.),min(rsI,1.));
      stone*=(1.+.5*tA)*(1.-.55*min(gA,1.))*(1.-.7*min(rsI,1.));
#if HD>=1
      stone*=1.-.45*min(dA,1.);
#endif
    }
    // (light visibility at extreme detail was dropped: its de() expansion paid for the bridges of the great halls)
  }
  if(surface){
    // A low indirect fill keeps the huge vaults readable between music transients.
    // crystal grotto: the stone turns to dark glass of the palette's glass colour
    stone=mix(stone,gGlassC*.06+stone*.3,wCr);
    col=stone*(.13+.13*max(nn.y,0.)+.25*head*exp(-t/sig*.7)*smoothstep(.1*sig,.7*sig,t))*(.25+.75*oc);
    col+=stoneH*(.026+.07*pow(1.-head,2.))*(.35+.65*oc);
    // workshop: warm forge light pools on the floors; garden: a soft glow of moss light
    col+=(gGoldC*.07*wWk+mix(gAccC,gGlassC,.5)*.09*wGd)*smoothstep(.3,1.,nn.y)*oc+mix(gGlassC,gAccC,.3)*.035*wGd*oc;
    // the great halls are lit from above: glass-coloured skylight down the shafts falls on the upward faces and
    // a dim accent bounce on the walls, so the colossal spaces read as volumes and not as a black void
    col+=vast*mix(stoneH,gGlassC,.15)*(.07*smoothstep(-.2,1.,nn.y)+.03)*(.35+.65*oc)*(.6+.4*uB1.x);
    if(vast>.02){
      // the vaults overhead glow like gilded domes, a mosaic of tiles breathing with the sub
      float dn=smoothstep(-.15,-.75,nn.y),tl=min(abs(fract(suv.x*.5)-.5),abs(fract(suv.y*.5)-.5));
      float tile=mix(1.,.45+.55*smoothstep(pxs*.5,pxs*1.5,tl-.02),smoothstep(.25,.08,pxs));
      col+=vast*gAccC*dn*tile*(.12+.22*uB1.x+.3*uO1.x)*(.35+.65*oc);
      // the deep openings of the colossal walls are lit galleries: thousands of small warm lights
      col+=vast*gAccC*innerS*smoothstep(.5,.12,oc)*(.3+.6*uB1.z+.5*uO1.z);
    }
    // the elf workshop is lit by warm forge light
    vec3 lampColour=mix(mix(vec3(1.),skyC,.12),mix(gGoldC,vec3(1.),.2),.85*wWk);
    // the lantern follows the level and the sub; it dims through a build so the lines carry the tension
    // v12: the snare flares the lantern down the path
    float lampEnergy=(.30+.14*quiet*(1.-vast)+1.05*uLevel+1.1*uSub*uSub*uDose+.35*uB1.x+1.05*uHit)*(1.-.4*uBuild);
    // the lantern throws its light down the path: walls brushing past the camera stay dim, the corridor ahead glows
    float lampAtt=(.2+.8*smoothstep(.2*sig,1.2*sig,lampDist))/(1.+lampDist*lampDist/(sig*sig*2.))*(.2+.8*smoothstep(.3,.85,dot(-lampDir,ww)));
#if HD>=1
    lampAtt*=mix(.18,1.,shRes);
#endif
    vec3 rfl=reflect(rd,nn);
    float lampSpec=pow(max(dot(rfl,lampDir),0.),28.);
    // gilded trim is metal: little diffuse, a broad gold sheen
    float metal=trimS*(1.-fineStone);
    col+=lampColour*lampEnergy*lampAtt*(stone*lampDif*1.3+lampSpec*.10*specHierarchy+gGoldC*gGoldC*metal*(pow(max(dot(rfl,lampDir),0.),8.)*.6+.22*pow(1.-head,3.))); 
    // lit windows: the recesses deep inside the great walls glow in the glass colour, breathing with the mids
    float winGlow=innerS*smoothstep(.6,1.3,lr)*(1.-smoothstep(1.7,2.3,lr))*smoothstep(.8,.35,oc);
    col+=mix(gGlassC,gAccC,.25)*winGlow*(.12+.6*uB1.w*uDose+.3*uHigh+1.5*max(uB1.z+uB1.w-.7,0.));
    // daylight falling down the oculi pools on the floors beneath them
    col+=skyC*.25*smoothstep(0.,1.,nn.y)*shv*oc*(.3+uP2.w)*(1.-.8*smoothstep(-1.5,-2.5,lv));
    // the elves light the stone
    for(int i=ELF0;i<6;i++){
      vec3 E=elfPos(i),L=E-pos;float ld=max(length(L),1e-6),es=elfR(i)*10.;
      float att=elfFade(i)/(1.+ld*ld/(es*es*.05));
      float dif=max(dot(nn,L/ld),0.);
      float spc=pow(max(dot(rfl,L/ld),0.),40.);
      {float eh=dot(L,nn),el=length(L-nn*eh),eR=es*.1;col*=1.-.6*elfFade(i)*smoothstep(eR*1.25,eR*.3,el)*smoothstep(eR*6.,eR*.7,eh)*step(0.,eh);}
      col+=elfC(elfCharacter(i))*(dif*.65+spc*1.2*specHierarchy)*att*(.5+.35*uHit);
    }
    // coloured lamps reflect partly in their own colour (a polished, slightly neutral stone)
    vec3 stoneN=mix(stone,vec3(max(stone.r,max(stone.g,stone.b))*.8),.5);
#if HD>=1
    for(int lamp=ELF0;lamp<ELLAMP;lamp++){
      float li=float(lamp)-.5*float(ELLAMP-1);
#else
    for(int lamp=ELF0;lamp<3;lamp++){
      float li=float(lamp)-1.;
#endif
      vec3 source=bay+(vec3(0.,.38,0.)+nave*li*2.)/sc;
      vec3 toL=source-pos;float ld=max(length(toL),1e-6);vec3 L=toL/ld;
      float att=1./(1.+ld*ld*sc*sc*4.);
#if HD>=1
      att*=mix(.22,1.,shA[lamp]);
#endif
      float dif=max(dot(nn,L),0.);
      float band=spec(clamp((lr+1.)/6.+.12*float(lamp),0.,1.));
      // only some bays are lit (a hash per lamp), so the vaults fall into pools of light and deep shadow;
      // the low-mids swell the pools
      float lh=h11(dot(floor(source*sc+.5),vec3(1.71,9.37,4.13))+ab*3.1);
      float energy=(.14+.14*quiet*(1.-vast)+.6*uLevel+1.6*band*band*uDose+.3*uB1.z+.35*min(uDrop,1.)+.9*uKick)*(1.-.7*fineStone)*(.1+.9*smoothstep(.35,.55,lh));
      vec3 lc=lamp==1?gGlassC:gAccC;
      float glossy=pow(max(dot(rfl,L),0.),32.);
      col+=lc*att*energy*(stoneN*dif*2.6+glossy*.22*specHierarchy)+gGoldC*gGoldC*mix(lc,vec3(1.),.5)*att*energy*metal*sqrt(glossy)*1.4;
      // crystal grotto: the stone is dark glass, every lamp leaves a sharp glassy highlight
      col+=wCr*lc*att*energy*pow(max(dot(rfl,L),0.),12.)*.8;
    }
    // a thin ring of glass-coloured light runs down the nave on every beat (the bass sets its strength)
    float rv=t/sig-1.2-uBeat*9.,ringL=exp(-rv*rv*90.)*(1.-.7*uBeat)*smoothstep(0.,.12,uBeat);
    col+=mix(gGlassC,vec3(1.),.15)*ringL*(.03+.2*uKick+.15*uB1.y+.12*min(uDrop,1.))*(.3+.7*head)*(1.-.6*fineStone);
    // (v20b) NO DARK STONE. The temple is painted: floors, walls and vaults each carry a deep jewel colour of their own, alternate marquetry
    // panels a second one, the ribs are striped in gold. It is laid in where the lamps leave the stone dark and held back where they already
    // light it, so the quiet passages glow like a night cathedral lit from within and the blazing halls keep their look. Creases, joints and
    // leads stay black: the ink between the colours.
    { float lumA=max(col.r,max(col.g,col.b)),need=(1.-mix(.94,.82,quiet)*smoothstep(.03,mix(.26,.45,quiet),lumA))*(1.-.6*vast)*max(quiet,.2),need2=(1.-.7*smoothstep(.05,.45,lumA))*(1.-.6*vast);
      vec3 jw3=mix(stoneH,gAccC,.12),jf=mix(stoneH,gGlassC,.6),jv=mix(stoneH,gAccC,.55);
      vec3 fc=mix(mix(jw3,jf,smoothstep(.5,.9,nn.y)),jv,smoothstep(-.15,-.7,nn.y));
      // every bay of every level is a chapel of its own colour (the change of colour lies under the rib between two bays)
      float hb=h11(dot(floor(pos*sc*.5),vec3(1.71,9.37,4.13))+ab*1.7);
      fc=mix(fc,hb<.6?mix(gGlassC,stoneH,.08):(hb<.8?mix(gAccC,stoneH,.08):mix(gGoldC,stoneH,.06)),step(.4,hb)*.92*smoothstep(4.,12.,2./(sc*foot)));
      fc=mix(fc,mix(gGlassC,gAccC,smoothstep(.5,.9,nn.y)),clamp(tAm*5.,0.,1.)*.5);
      float shd=.5+.5*dot(nn,vec3(.42,.74,.52)),ink=(.3+.7*oc)*(1.-.85*gAm);
      #if HD>=1
      ink*=(1.-.5*min(diL,1.))*(1.+.55*min(diP,1.));
#endif
      float pbS=hb<.4?uB1.x:(hb<.6?max(uB1.z,uB1.w):(hb<.8?uB1.y:max(uB2.x,uB2.y)));
      float pb=.4*min(pbS*uDose,1.)+min((hb<.4?1.2*uKick:(hb<.6?.6*uO1.z:(hb<.8?1.3*uKick:1.1*uHat)))+2.2*uHit*step(.5,fract(hb*13.)),1.6);
      // deep jewel, whatever the hue: the bright families (gold, lime, ice, rose) are laid in darker so every chapel weighs the same
      fc*=(.15+.85*fc)*pow(min(1.,.26/max(dot(fc,vec3(.2126,.7152,.0722)),.05)),.75);
      col+=fc*ink*((.17+.24*shd)*need*(1.+.6*wCr)*(1.+.9*uKick+.8*uHit)+(.13+.12*shd)*pb*need2*quiet*smoothstep(4.,12.,2./(sc*foot)))*(1.-.5*wVt);
      // painted ribs: gold and accent stripes
      col+=mix(gGoldC,gAccC,step(.5,fract(dot(pos,vec3(1.))*sc*13.5)))*trimS*(.16+.3*uHat)*need*(.3+.7*oc);
      // the roses and the stars burn by themselves
      col+=(rsC*.3*need+mix(gAccC,gGlassC,step(0.,tAm))*sAm*.1*need)*(.25+.75*oc)*(1.-wGd*.6); }
    col*=1.-.25*wCr;
    // the bridges of the great wells: decks of dark polished stone with two rails of light and a dashed centre line;
    // on every beat a pulse runs out along the arms from the crossing
    if(br>.5){
      // (v20c) THE BRIDGES are jewelled reliquaries now. Top and underside: three panels an arm between gilt kerbs set with a chain of small
      // stones. Panel one is pierced (a gilt collar round the hole), panel two holds an eight-point star with a cabochon in relief, corner tesserae
      // in every panel. The crossing carries a boss: an eight-petalled rosette, an eye stone that fires on the kick and eight studs that play the
      // spectrum. The sides are a frieze of faceted lozenges between gilt fillets. The beat's pulse runs out along the arms through all of it.
      // Glass stars above, accent stars below, so the underside is as worked as the deck. Inlay takes the light of the stone it is set in.
      vec3 bv=mod(pos*sc,2.)-1.;float bpx=foot*sc/max(abs(dot(nn,rd)),.2);
      float cl=min(abs(bv.x),abs(bv.z)),ra=max(abs(bv.x),abs(bv.z)),rr=length(bv.xz),yb=bv.y+.355;
      float fT=smoothstep(.45,.75,nn.y),fU=smoothstep(.45,.75,-nn.y),fS=clamp(1.-fT-fU,0.,1.);
      float pi3=floor(ra*11.),pf=fract(ra*11.)-.5,odd=step(abs(pi3-1.),.5)*step(fS,.5),ppx=bpx/.03;
      float run=exp(-7.*fract(ra*2.5-uBeat)),bnd=spec(fract(pi3*.137)*.8+.1),bL=clamp(dot(col,vec3(.2126,.7152,.0722))*5.,0.,1.),bLt=.3+.7*bL;
      vec3 gnd=mix(stoneH*(.25+.75*stoneH),gGlassC*gGlassC,.3*fU)*(.05+.2*bL)+col*.3,bc=gnd;
      vec2 q=vec2(mix(cl/.03,yb/.0235,step(.5,fS)),pf*2.),ja=abs(q);float r=length(q);
      float s8=min(max(ja.x,ja.y),(ja.x+ja.y)*.70711)-.6,bed=smoothstep(1.+ppx,1.-ppx,ja.x);
      {vec2 dq=vec2(q.x+q.y,q.x-q.y)*2.5,df=abs(fract(dq)-.5);float fd=smoothstep(.09,.035,ppx)*bed;
       bc=mix(bc,bc*.4,smoothstep(.43-ppx*2.5,.48,max(df.x,df.y))*fd);
#if HD>=1
       bc=mix(bc,gGoldC*(.2+.6*bLt+.9*uHat*step(.5,fract(floor(dq.x)*.37+floor(dq.y)*.61))),smoothstep(.13+ppx*2.5,.06,length(df))*fd*.85);
#endif
       bc=mix(bc,gGoldC*(.15+.6*bLt),smoothstep(.035+ppx,.01,abs(ja.x-.88))*bed*.8);
#if HD>=1
       float a16=abs(fract(atan(q.y,q.x)*8./PI)-.5)*2.,dr=abs(r-.78)-.1*(1.-a16);
       bc=mix(bc,mix(gAccC,gGoldC,step(.5,fract(floor(atan(q.y,q.x)*8./PI)*.5)))*(.25+.5*bL+1.1*run*(.2+uKick)),smoothstep(ppx,-ppx,dr)*odd*bed);
       bc=mix(bc,vec3(0.),smoothstep(ppx*2.,0.,abs(dr)-.012)*odd*bed*.9);
#endif
      }
      bc=mix(bc,mix(gGlassC,gAccC,fU)*(.16+.3*bL+.55*run*(.3+uKick)+.6*bnd*bnd*uDose),smoothstep(ppx,-ppx,s8)*bed*(1.-odd));
      bc=mix(bc,gGoldC*(.2+.7*bLt),smoothstep(.05+ppx,.015,abs(s8))*bed*.85*(1.-odd));
      float dome=sqrt(max(1.-r*r/.09,0.));
      bc=mix(bc,vec3(0.),smoothstep(ppx*2.,0.,abs(r-.3)-.03)*(1.-odd)*bed);
      bc=mix(bc,mix(gGoldC,gAccC,fU)*(.25+.75*dome)*(.3+.5*bL+1.6*bnd*bnd*uDose+1.2*run*(.2+uKick))+vec3(.5)*smoothstep(.1,0.,length(q-vec2(-.1,.12)))*bLt,smoothstep(.3+ppx,.3-ppx,r)*(1.-odd));
      bc=mix(bc,gGoldC*(.25+.8*bLt+.8*run*uKick),smoothstep(ppx*1.5,0.,abs(length(vec2(cl,pf/11.))/.03-.56)-.07)*odd*bed);
#if HD<2
      bc=mix(bc,vec3(0.),smoothstep(ppx,-ppx,length(vec2(cl,pf/11.))/.03-.44)*odd*bed);   // High and Native: the piercing is painted (it is cut for real from Cinema up)
#endif
      {vec2 tq=ja-vec2(.78,.8);bc=mix(bc,mix(gAccC,gGlassC,odd)*(.2+.5*bL+1.5*uHat*odd+.9*uB2.y*uDose),smoothstep(ppx,-ppx,abs(tq.x)+abs(tq.y)-.13)*bed);}
      bc=mix(bc,gGoldC*(.12+.5*bLt),smoothstep(.9-ppx,.96,abs(pf)*2.)*bed*.9);
      {float ki=floor(ra*33.),kpx=bpx/.005,kerb=smoothstep(1.-ppx,1.+ppx,ja.x);vec2 kq=vec2((cl-.035)/.005,(fract(ra*33.)-.5)*6.);float kr=length(kq);
       bc=mix(bc,gGoldC*gGoldC*(.06+.3*bLt)*(1.-.55*step(.5,fract(ra*66.+cl*100.))*smoothstep(.5,.2,kpx)),kerb);
       bc=mix(bc,mix(gAccC,gGlassC,step(.5,fract(ki*.5)))*(.35+.65*sqrt(max(1.-kr*kr/.64,0.)))*(.3+.5*bL+1.5*exp(-7.*fract(ki/33.*2.5-uBeat))*(.3+uKick)+1.2*uHat*step(.5,fract(ki*.31))),
          smoothstep(.8+kpx,.8-kpx,kr)*smoothstep(.5,.2,kpx)*kerb);}
      {float bz=smoothstep(.066+bpx,.066-bpx,rr),ba=atan(bv.z,bv.x),pet=.03+.022*abs(cos(4.*ba)),bi=floor(ba/TAU*8.+.5),er=rr/.016,ep=bpx/.016;
       vec3 bo=gGoldC*gGoldC*(.08+.3*bLt);
       bo=mix(bo,mix(gAccC,gGlassC,fU)*(.2+.4*bL+.8*uKick),smoothstep(bpx,-bpx,rr-pet));
       bo=mix(bo,vec3(0.),smoothstep(bpx*2.,0.,abs(rr-pet)-.0015));
#if HD>=1
       float sb=spec(fract(bi/8.+.06)*.84+.08);
       bo=mix(bo,gGlassC*(.3+.5*bL+2.5*sb*sb*uDose),smoothstep(.006+bpx,.006-bpx,length(vec2(rr-.056,(fract(ba/TAU*8.+.5)-.5)*TAU/8.*rr))));
#endif
       bo=mix(bo,vec3(0.),smoothstep(ep*2.,0.,abs(er-1.)-.12));
       bo=mix(bo,mix(gGoldC,vec3(1.),.3)*(.3+.7*sqrt(max(1.-er*er,0.)))*(.4+.4*bL+2.2*uKick+.8*uB1.x),smoothstep(1.+ep,1.-ep,er));
       bc=mix(bc,bo,bz*(1.-fS));}
      col=mix(col*.6+gnd*.5,bc,smoothstep(.02,.006,bpx));   // far away the inlay melts into its mean
    }
  }
  // (the floor's reflection march was retired in v8: its de() expansion paid for the light of the great halls; the
  // polished floors keep a glossy sheen of the haze and the lamps' highlights)
  if(surface)sg=seamGlowP(d,t,lr0,K,lvS,d2S,sc)*crease;
  if(surface){
    // workshop: the great seams are conduits, energy runs along them in dashes that tick with the beat
    vec3 cw=pos/sig;float dash=step(.45,fract(dot(cw,nave)*.8+cw.y*.37-beats*.25-.25*smoothstep(0.,.3,uBeat)));
    sg*=mix(1.,.25+1.5*dash,wWk*(1.-smoothstep(.5,2.,lr)));
    col+=sg; // intrinsic seam emission is independent of ambient occlusion
    // v14: one polar angle of the inlay coordinates serves the garden flowers, the seal runes and the cog teeth
    float jAng=atan(jq.y,jq.x);
    float medR=.64,medT=mix(.7,.4,wWk);
    // engraved gold seals on some jewel nodes of the flat walls and floors (in the workshop: turning cogs, more of them)
    float sealSel=jflat*step(medT,fract(jh*5.31))*smoothstep(.11,.04,pxs);
    float medM=smoothstep(medR+pxs,medR-pxs,jr)*sealSel;
    float lumC=dot(col,vec3(.2126,.7152,.0722));
    // (v20) the marquetry's gilt hairlines are ink in the gilding's colour (never added light); the corner tesserae are small lights for the highs
    col=mix(col,gGoldC*(.05+.55*lumC+.2*oc),mqL*.55*(1.-wGd*.6));
    col=mix(col,mqT/max(mqC,1e-3)*(.07+.5*lumC),min(mqC,1.)*.8);
    col+=(mix(gAccC,gGlassC,step(0.,tAm))*sAm*(.7*uKick+.2*uB1.x*uDose)+gGoldC*min(mqL,1.)*(.45*uHit+(.55*uHat+.5*max(uB2.z+uB2.w-.5,0.))*step(0.,tAm)))*(.3+.7*oc)*(1.-wGd*.6);
    // jewel inlays on the nodes that stay solid at every finer level: cabochons with a gold bezel
    vec3 jc=mix(gGlassC,gAccC,step(.5,fract(jh*3.7)));
    float core=smoothstep(jrad+pxs,jrad-pxs,jr);
    float dome=sqrt(max(1.-jr*jr/(jrad*jrad),0.));
    vec2 hl=jq-vec2(-.035,.04);
    float jbr=(.15+.85*dome)*(.25+1.6*spec(.15+jh*.75)*uDose+1.2*uHat*step(.6,jh)+.8*uB2.w)+2.5*smoothstep(.035,.0,length(hl));
    vec3 bez=gGoldC*.3*(.3+.7*head);
    col=mix(col,JWK*mix(bez,jc*jbr*1.5,core),jw*(1.-wGd));
    // garden of light: the nodes bloom into five-petalled flowers that open with the mids, joined by swaying vines
    if(wGd>.01){
      float fa=jAng,open=.75+.45*uB1.w;
      float pr=jr-(.14+.26*open*pow(abs(cos(fa*2.5+jh*6.)),.6));
      float pet=smoothstep(pxs,-pxs,pr)*jflat*step(.12,jh)*smoothstep(.16,.06,pxs);
      vec3 fc=mix(gAccC,gGlassC,smoothstep(.0,.35,jr))*(1.+1.4*uB1.w+.8*uO1.w);
      fc=mix(fc*(.6+.6*smoothstep(.0,.35,jr)),vec3(1.,.95,.8)*2.,smoothstep(.07+pxs,.07-pxs,jr));
      col=mix(col,fc,pet*wGd);
      // curtains of light: luminous strands hang down the walls in rows, leaves alternating along them (filled almonds
      // with a lighter midrib and an ink rim), drops of light sliding down them; they sway with the mids. On far walls
      // the curtains melt into their mean glow instead of fizzing.
      float wallF=1.-smoothstep(.45,.75,abs(nn.y));
      float gk=9./(sig*1.05);vec2 vq=vec2(an.x>an.z?pos.z:pos.x,pos.y)*gk;
      float vpx=foot*gk/max(abs(dot(nn,rd)),.25),si=floor(vq.x),sh=h11(si*3.71+floor(vq.y*.07)*1.3);
      float lx=fract(vq.x)-.5-.07*sin(vq.y*.8+uTime*1.2+sh*6.)*(1.+.6*uB1.w);
      float yi=floor(vq.y*2.6),sd=lx>0.?1.:-1.,lh=h11(yi*1.31+si*7.7+sd);
      float hang=step(.1,sh)*step(.12,fract(vq.y*.06+sh*3.1));
      vec2 lv0=vec2(lx-sd*.15,vq.y-(yi+.5)/2.6),lp=vec2(.66*lv0.x-sd*.751*lv0.y,sd*.751*lv0.x+.66*lv0.y);
      const float ew=.2,eh=.08;
      float ld=max(length(lp+vec2(0.,.2088)),length(lp-vec2(0.,.2088)))-.2888;
      float lm=smoothstep(vpx,-vpx,ld)*step(.06,lh)*hang;
      float rim=smoothstep(vpx*1.6,vpx*.4,abs(ld+vpx*.6));
      float rib=smoothstep(vpx*1.1,vpx*.2,abs(lp.y))*step(abs(lp.x),ew*.8);
      float dropL=exp(-14.*fract(vq.y*.25+uTime*.55+sh*7.));
      vec3 leafC=mix(gGlassC,gAccC,step(.55,sh)*.85+.1*lh)*(.25+.45*(1.-abs(lp.y)/eh)*smoothstep(-ew,ew*.3,lp.x*sd)+.25*rib)*(.45+.75*uB1.w+.5*uO1.w)*(1.+.8*dropL);
      leafC=mix(leafC,vec3(.008,.012,.01),rim*.8);
      float nearF=smoothstep(.08,.03,vpx),fol=nearF*wGd*(1.-pet)*wallF;
      float stem=smoothstep(vpx*1.2,vpx*.2,abs(lx)-.007)*(1.-lm)*hang*smoothstep(.07,.03,vpx);
      col=mix(col,leafC,lm*fol);
      col+=mix(gGlassC,gGoldC,.35)*stem*fol*(.2+.5*uB1.w+1.4*dropL*(.4+uO1.w));
      col+=gGlassC*.05*(.5+1.2*uB1.w)*(1.-nearF)*wGd*(1.-pet)*wallF*(.4+.6*oc);
    }
    // crystal grotto: facet glints that twinkle with the high band, and finer cells glowing like geodes
    // v14: the glints now exist on the stone of every theme (sparser and weaker outside the grotto), so the high band
    // and the hats are visible all along the journey and not only in one of the five regions
    {
      vec2 gq=suv*2.,gi=floor(gq);float gh=h21(gi+ab*3.);
      vec2 gf=fract(gq)-.5;float star=min(abs(gf.x)+abs(gf.y)*6.,abs(gf.y)+abs(gf.x)*6.);
      float gp=pxs*2.,gsh=smoothstep(.14+gp,.16-gp,star)*smoothstep(.3,.06,gp);
      float airW=.11+.85*uHat+.7*max(uB2.z+uB2.w-.9,0.);
      col+=mix(gGlassC,vec3(1.),.4)*(smoothstep(.6,1.,gh)*gsh*(.6+3.*uB2.z*uDose+2.5*uO2.z+3.*uHat)*wCr
        +smoothstep(.82,1.,gh)*gsh*airW*(1.-wCr))*(.4+.6*head);
      col+=gGlassC*(.06*fineStone+.12*innerS*smoothstep(.5,1.5,lr))*(.4+uB2.y)*wCr*oc;
    }
    vec2 rg=vec2(0.);float rh=0.,rpx=1.,rAmt=0.,rj=0.,rMode=0.;
    if(medM>0.){
      float ra=mod(jAng+PI/8.,PI/4.)-PI/8.;
      rg=(vec2(sin(ra),cos(ra))*jr-vec2(0.,.4))/.13;rh=floor(jh*16.)+ab*5.;rpx=pxs/.13*1.5;rAmt=medM;rMode=1.;
    }
    if(nn.y>.9&&kd<1.5){
      vec3 cv=mod(pos*sc,2.)-1.;
      vec2 fq2=kd<.5?cv.xz:cv.zx;
      float tile=.125,tw=tile/sc/(foot/max(nn.y*abs(rd.y),.15));
      if(abs(fq2.x)<tile*.5&&tw>3.){
        rj=floor((fq2.y+1.)/tile);
        rg=vec2(fq2.x,mod(fq2.y+1.,tile)-tile*.5)/(tile*.5)*1.15;rh=rj+ab*16.;rpx=2.4/tw;rAmt=smoothstep(3.,8.,tw);rMode=2.;
      }
    }
    // seals and rune strips belong to the explorer's own scale: on the colossal walls they would be giant shards
    rAmt*=smoothstep(-1.2,-.4,lr);
    if(rMode>0.&&rAmt>0.){
      float rn=rune(rg,rh,rpx)*rAmt;
      if(rMode<1.5){
        float fil=max(rn*step(abs(rg.y),1.),smoothstep(pxs*1.5,0.,abs(jr-medR+.035)-.012)*medM);
        col+=FILK*gGoldC*fil*(.04+1.1*lumC+1.1*uHit*uHit+.6*uB2.x*wWk);
      }else{
        float band=spec((rj+.5)/16.);
        col+=mix(gAccC,gGlassC,rj/15.)*rn*(.1+2.8*band*band*band*uDose);
      }
    }
    if(wWk>.01){
      // workshop cogs round the seals: sixteen trapezoid teeth with sloped flanks and rounded roots, drawn as a
      // one-pixel gold outline over a polished body with a rim track and rivets; they tick round with the beat
      float cogM=smoothstep(medR+.14+pxs,medR+.14-pxs,jr)*sealSel*smoothstep(-1.2,-.4,lr);
      float can=jAng,ca=can+(beats+smoothstep(0.,.35,uBeat))*PI/8.*(fract(jh*9.1)>.5?1.:-1.);
      float fa=fract(ca/TAU*16.),tr=min(fa-.1,.9-fa)/.22,tp=clamp(tr,0.,1.);
      float kk=step(0.,tr)*step(tr,1.)*.065/.22*16./(TAU*max(jr,.1)),gd=(jr-medR-.05-.065*tp)/sqrt(1.+kk*kk);
      float edge=smoothstep(pxs*1.2,pxs*.2,abs(gd));
      float body=smoothstep(pxs*.6,-pxs*.6,gd)*step(medR+.004,jr);
      // v14: the polished body is a flat dark gold now (the wheel sheen and the rim track were below a pixel of
      // contrast at the cog's one-pixel line weight)
      col=mix(col,gGoldC*gGoldC*(.05+.13*lumC),body*cogM*wWk*.85);
      col+=gGoldC*edge*cogM*wWk*(.18+1.2*lumC+.8*uB2.x+.9*uO1.y);
    }
#if HD>=1
    // v19: engraved filigree on the flat masonry, in the gilding's own colour at limited coverage (ink, never added light), one finer pass from Insane
    if(jflat>.5&&lr>-.4&&br<.5){
      float cf=smoothstep(-.4,.4,lr)*(1.-jw)*(1.-.5*fineStone);
      vec2 ou=mod(suv*1.5+1.,2.)-1.;float opx=pxs*1.5;
      for(int oi=ELF0;oi<(HD>=3?2:1);oi++){
        if(opx>.08)break;
        float ol=orn(ou*1.9+jh*vec2(.3,.7),opx*1.9,jh+float(oi)*.37);
        vec3 inkC=(oi==0?gGoldC:mix(gGlassC,gGoldC,.4))*(.05+.32*oc+.55*lumC+.5*uB2.x*step(.5,fract(jh*2.3)));
        col=mix(col,inkC,ol*cf*(oi==0?.5:.35));
        ou=mod(ou*3.1+.5,2.)-1.;opx*=3.1;
      }
    }
#endif
#if HD>=1
    // v19: the mirror ray's landing point, shaded in light: its stone, its lantern pool and its seams, in the palette's own colours (never white)
    {
      float fres=pow(1.-head,4.),rw=max(rf,(.05+.55*fres)*(1.-.75*fineStone)*(1.-jw));
      if(rflHit>.5){
        float rt=t+rTH,rft=gFt*rt,rlr=rLvH+lr0,rhd=max(dot(rnH,-rDirH),0.);
        vec3 toL=ro+(uu*.03+vv*.04)*sig-rPosH;float ldL=max(length(toL),1e-6);
        vec3 rc=gStoneC*(.2+.3*rhd)+stoneH*.12*max(dot(rnH,toL/ldL),0.)/(1.+ldL*ldL/(sig*sig*2.))*(.3+1.05*uLevel+1.05*uHit);
        float e2R=rDH-rD2H,seamR=smoothstep(rft*2.,0.,e2R)*(1.-smoothstep(.2,1.2,rlr-1.));
        vec3 sc2=mix(gAccC,gGlassC,.65*smoothstep(.5,2.5,rlr));
        rc+=sc2*seamR*(.9+2.2*spec(clamp((rlr+1.)/6.,0.,1.))*uDose+1.6*uKick+1.4*uHit);
        rc=mix(rc,fogc,1.-exp(-rTH/sig*.25));
        col=mix(col,col*.65+rc,clamp(rw,0.,.75)*(.45+.55*oc));
      }else{
        col+=fogc*rw*.5*oc;
      }
    }
#endif
    col+=(fogc+mix(gGlassC,gAccC,.3)*.04)*rf*oc;
    // aerial perspective: in the great halls distant walls fall back into luminous haze, layer behind layer
    // the recursive vault: dark stone, every surface rimmed in the hue of its level of the recursion
    // and a wave of light washes over one level after the next, inward, every two beats
    vec3 lvc=elfLvC(lv);float lvPulse=exp(-3.*fract(gBt*.5-lr*.5));
    col=col*(1.-.6*wVt)+wVt*lvc*(pow(1.-head,3.)*.45+lvPulse*(.08+.18*uB1.y+.22*uO1.y)*(.3+.7*head))*(.4+.6*oc);
    col=mix(col*1.7,fogc,1.-exp(-t/sig*mix(.09/(1.+3.5*vast),mix(.05,.02,vast),quiet)));
#ifdef DBGV
    col=DBGV;
#endif
  }
#if HD>=1
  // (v20) THE LANTERNS. The bay lamps that light the stone were invisible; now each one is a jewelled cage lantern hanging under the apex of its
  // crossing, at the explorer's own scale and the two finer ones, so every nave is a receding avenue of lights. They are real points of the temple
  // (the lattice of cell centres, which is always open space), hidden by the stone in front of them, and each burns with its own bay's light:
  // its level's band of the spectrum, the kick, the snare. Analytic spheres: no distance queries.
  {
    float lg=log(sig)/log(3.),lf=-lg,l0=floor(lf);
    for(int j=ELF0;j<3;j++){
      float l=l0+float(j),x=l-lf,w=smoothstep(-1.,-.55,x)*(1.-smoothstep(1.35,2.,x)),s=pow(3.,l),R=.03/s;
      if(w>.001)for(int k=ELF0;k<ELLN;k++){
        float ts=(float(k)+.55)*1.55/s;
        if(ts>t+.3/s)break;
        vec3 P=(ro+rd*ts)*s,C=floor(P*.5)*2.+1.;C.y=floor((P.y-.38)*.5)*2.+1.38;
        vec3 oc3=C/s-ro;float b=dot(oc3,rd),d2=dot(oc3,oc3)-b*b,h=sqrt(max(d2,0.))/R;
        if(b>0.&&b<t&&h<3.2){
          float px=gFt*b/R,lh=h11(dot(floor(C+.5),vec3(1.71,9.37,4.13))+l*3.1),lit=.12+.88*smoothstep(.35,.55,lh);
          float band=spec(clamp((x+1.)/6.+.12*fract(lh*5.),0.,1.));
          float en=lit*(.3+.6*uLevel+1.9*band*band*uDose+1.*uKick+.8*uHit*step(.5,fract(lh*3.)))/(1.+.8*uDrop);
          vec3 lc=fract(lh*7.3)<.5?gGlassC:gAccC;
          float th=b-sqrt(max(R*R-d2,0.));vec3 N=(ro+rd*th-C/s)/R;
          float ang=atan(N.z,N.x),mer=abs(fract(ang*4./PI)-.5)*2.,lat=abs(N.y),fac=max(dot(N,-rd),0.);
          float fine=smoothstep(.5,.15,px);
          float rib=max(max(smoothstep(.8-px,.93,mer),smoothstep(.07+px,.02,abs(lat-.46))),step(.84,lat))*fine;
          vec3 pane=mix(lc,mix(lc,gGoldC,.5),step(.5,fract(floor(ang*4./PI)*.5)))*(.16+min(en,2.2)*(.35+1.1*fac*fac));
#if HD>=1
          // each pane is leaded into a little lattice of quarries
          { float f2=smoothstep(.2,.06,px);vec2 qd=vec2(ang*8./PI+N.y*5.,ang*8./PI-N.y*5.);
            pane*=1.-.45*f2*smoothstep(.1,.03,min(abs(fract(qd.x)-.5),abs(fract(qd.y)-.5)));
            pane*=1.+.3*f2*(h21(floor(qd)+lh*9.)-.5); }
#endif
          vec3 body=mix(pane,gGoldC*gGoldC*(.1+.5*fac)*(.35+.3*min(en,1.5)),rib);
          float nf=smoothstep(.25/s,.8/s,b),fg=exp(-b/sig*.09/(1.+3.5*vast)),vis=w*nf*smoothstep(2.6,.9,px)*smoothstep(.05,.028,1.25/(px*uRes.y));
          float mask=smoothstep(1.+px,1.-px,h);
          col=mix(col,mix(fogc,body,fg),mask*vis);
          // a tight halo and, on the hats, a four-ray glint
          vec3 q3=oc3-rd*b;float qx=dot(q3,uu)/R,qy=dot(q3,vv)/R;
          col+=lc*fg*vis*(1.-mask)*en*(.16*exp(-(h-1.)*2.6)+.5*uHat*step(.5,lh)*exp(-abs(qx*qy)*30.)*exp(-h*1.1));
        }
      }
    }
  }
#endif
  // the great halls: stained light falls down the great shaft in coloured curtains, a rose window of sixteen panes
  // each singing its own band of the spectrum, a pulse of light falling on every beat. The hall is the coarsest of the
  // three levels above the explorer whose shaft holds the camera; the ray's chord through it is sampled evenly (no
  // noise, no new distance queries), and the last sample is the surface itself, which the light pools on.
  if(vast>.02){
    vec3 beams=vec3(0.),pool=vec3(0.);
    float mR=max(abs(ro.x),max(abs(ro.y),abs(ro.z))),s=1./(3.*sig),hl=0.;
    for(int L=ELF0;L<2;L++){float s2=s/3.;vec2 v2=mod(ro.xz*s2,2.)-1.;if(mR*s2>.47&&length(v2)<.27){s=s2;hl+=1.;}}
    vec2 ax=(floor(ro.xz*s*.5)*2.+1.)/s,o=ro.xz-ax,dd=rd.xz;
    float R=.26/s,qa=dot(dd,dd),qb=dot(o,dd),qc=dot(o,o)-R*R,disc=qb*qb-qa*qc,t0=0.,t1=-1.;
    if(disc>0.&&qa>1e-6){float sq=sqrt(disc);t0=max((-qb-sq)/qa,0.);t1=min((-qb+sq)/qa,t);}
    for(int j=ELF0;j<17;j++){
      bool sf=j==16;
      if(sf&&!surface||!sf&&t1<=t0)continue;
      vec3 P=sf?pos:ro+rd*mix(t0,t1,(float(j)+.5)/16.);
      vec2 v=mod(P.xz*s,2.)-1.;float r=length(v)/.2713;
      float sf16=atan(v.y,v.x)/TAU*16.,si=floor(sf16),fy=P.y*s*.5;
      float lit=step(.36,h11(si*1.7+floor(fy)*5.3+hl*11.));
      float wedge=smoothstep(sf?.31:.34,sf?.25:.12,abs(fract(sf16)-.5));
      float band=spec(fract(si/16.)*.84+.08);
      float ci=mod(si+hl,4.);
      vec3 bc=ci<.5?gAccC:(ci<1.5?gGlassC:(ci<2.5?gAccC*vec3(1.,.8,.8)+gGoldC*.2:gGlassC*vec3(.8,1.,1.)));
      vec3 e=bc*lit*wedge*(.35+1.4*band*band*uDose)*(1.+1.8*exp(-9.*fract(fy+uBeat)))*(.45+.55*min(r,1.))*(sf?1./(1.+4.*max(r-1.,0.)*max(r-1.,0.)):step(r,1.)*(t1-t0)*s/16.);
      if(sf)pool=e;else beams+=e;
    }
    col+=vast*(beams*3.4*(1.-.6*zoW)+pool*(.02+.32*stone)*(.4+.6*oc));
  }
  // light pouring down the shafts, scattered by the incense in the air
  col+=skyC*(1.-exp(-vol*.05*(.4+uP2.w+.6*uBass+.4*uB1.x)))*(.5+.8*max(rd.y,0.))*1.1*(1.-.55*zoW);
  // v12: motes of light hang in the incense (two shells round the camera, cells fixed in the world, so they drift
  // past with parallax): the hats strike them, the air band keeps them twinkling. Light only, dark in silence.
  // v14: the air band (the top two bands) now lifts them as hard as the hats do and the core is a little broader, so
  // the highest sounds are visible as drifting sparks rather than a faint shimmer
  {float hz=1.35*uHat+.95*max(uB2.z+uB2.w-.8,0.);
#if HD>=1
   if(hz>.01)for(int m=ELF0;m<2+2*HD;m++){
#else
   if(hz>.01)for(int m=ELF0;m<2;m++){
#endif
     float ts=sig*(1.1+1.7*float(m)),cs=sig*.16;
     if(ts<t){vec3 P=(ro+rd*ts)/cs,ci=floor(P),f=fract(P)-.5;float hh=h11(dot(ci,vec3(1.71,9.37,4.13)));
#if HD>=1
      if(m>=2&&hh<.95)hh=0.;
#endif
       float dm=length(f-rd*dot(f,rd)),pxm=gFt*ts/cs;
#if HD>=1
       col+=gGlassC*step(.8,hh)*(.95*smoothstep(.055+pxm,.055-.5*pxm,dm)+.3*exp(-dm/(.04+pxm)))*smoothstep(.3,.06,pxm)*hz*(m>=2?.7:1.9)*(1.+.3*sin(uMT*7.+hh*60.));}}}
#else
       col+=mix(gGlassC,vec3(1.),.3)*step(.8,hh)*(.95*smoothstep(.055+pxm,.055-.5*pxm,dm)+.3*exp(-dm/(.04+pxm)))*smoothstep(.3,.06,pxm)*hz*(1.9+.55*sin(uMT*7.+hh*60.));}}}
#endif
  // the engine brightens the whole frame on a drop (and a little through a build); the stone takes that back so
  // the drop reads as blazing coloured lines on dark stone instead of a washed-out flash
  col*=1./(1.+2.2*uDrop*uDrop+.3*uBuild);
  // jewel tones: the many coloured lights of the brighter halls would otherwise mix toward pastel on the stone
  // (pastel tones are lifted most, colours that are already pure hardly at all)
  {float pm=min(col.r,min(col.g,col.b)),px2=max(col.r,max(col.g,col.b)),pk=.62*smoothstep(.3,.75,pm/max(px2,1e-4))*smoothstep(.12,.5,px2);
   col=(col-pm*pk)*(px2/max(px2-pm*pk,1e-4));}
  float cmx=max(col.r,max(col.g,col.b)),csat=(cmx-min(col.r,min(col.g,col.b)))/max(cmx,1e-4);
  col=max(mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,mix(2.62,1.48,csat)),0.)*1.1;
#if HD>=1
  // supersampled multi-hue tracery averages toward grey and lifts the blacks: the higher tiers keep the saturation and the darks of High
  col=max(mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.+.03*float(HD)),0.);
  {float vm=max(col.r,max(col.g,col.b));col*=smoothstep(.004,.03+.006*float(HD),vm);}
#endif
  // the elves themselves, composited by depth rather than character identity
  float win=0.;vec2 wq=vec2(0.);int layerIds[6];vec4 layerPk[6];
  int layerCount=elfLayerOrder(ro,rd,ww,uu,vv,t,layerIds,layerPk);
  for(int layer=ELF0;layer<6;layer++){
    if(layer>=layerCount)break;
    int i=layerIds[layer],k=i-6*(i/6);
    float fk=elfCharacter(i);
    // v14: depth, billboard radius and billboard coords come straight out of the sort (they were already computed
    // there, and its filters guarantee 0 < tE < t and dot(q,q) < 3)
    vec4 pkl=layerPk[layer];
    float tE=pkl.x,R=pkl.y;vec2 q=pkl.zw;
    float px=tE*gFt/R;
    float greet=elfGreet(i);
    float face=sin(uMT*.5+fk*2.4)*1.1*(1.-smoothstep(0.,.35,uHit))*(1.-greet);
    vec2 eq;float em;
    // (v20c) each elf has a way of flying: every other beat it darts to a new spot beside its place (fast out, then it hangs there), and now and
    // then it tumbles once right round through a beat. Greeting elves hold still.
    vec3 EP=elfPos(i)-ro;vec2 par=clamp(vec2(dot(EP,uu),dot(EP,vv))/max(dot(EP,ww),1e-5),-.7,.7);
    float bh=h11(fk*3.7+float(i)*1.3),bn=gBt*.5+bh,bf=fract(bn),bi0=floor(bn);
    q-=mix(vec2(h11(bi0*1.7+fk*9.1),h11(bi0*2.3+fk*4.7)),vec2(h11(bi0*1.7+1.7+fk*9.1),h11(bi0*2.3+2.3+fk*4.7)),1.-pow(1.-bf,4.))*.4*(1.-greet)-.2*(1.-greet);
    float tumA=TAU*smoothstep(0.,.75,fract(gBt))*step(.82,h11(floor(gBt)*5.3+fk*2.9))*(1.-greet)*(bh>.5?1.:-1.);
    q=rot(tumA)*q;
    vec3 Lw=vec3(.3,.9,.25),Ld=normalize(vec3(rot(tumA)*vec2(dot(Lw,uu),dot(Lw,vv)),max(-dot(Lw,ww),.3)));
    vec4 e=elfDraw(q,fk,px,face,greet,par,Ld,eq,em);
    float residentFade=elfFade(i);e.rgb*=residentFade;e.a*=residentFade;em*=residentFade;
    float fog=exp(-tE/sig*.08);
    col=mix(col,e.rgb*fog,e.a)+e.rgb*(1.-e.a)*fog;
    win*=1.-clamp(e.a,0.,1.); // a nearer opaque figure also hides a farther eye window
    if(i==0&&px<.02){win=max(win,em);wq=eq;}
  }
  // the far end of the nave opens onto the whole image again (nested window)
  float far=smoothstep(.55,1.,t/tmax);
  if(far>win&&dot(ww,rd)>.0){win=far*.85;wq=lp/.35;}
  fragColor=vec4(col,win);fragWin=vec4(wq*.5+.5,0.,1.);
}`;
