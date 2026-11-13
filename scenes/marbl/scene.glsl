const R_MARBL = `
// MARBL: analytic paper marbling (Turkish ebru / Japanese suminagashi) played by the music.
// Every pixel is traced back through a bath's history (newest first): ink drops (exact area-preserving radial
// pushes, r^2 -> r^2 + A), many-ringed suminagashi / agate drops, sprinkled stone and gall drops (compact pushes),
// gold leaf, comb and stylus strokes (shears along tine lines), wave combs, swirls, ring styluses (roses) and
// radial styluses (flowers, birds). Every step is an exact inverse, so the pattern stays crisp at any age. The
// Jacobian of the inverse map is carried along, which gives each ink edge its true distance in pixels: analytic
// anti-aliasing, hairline veins and level-of-detail for rings squeezed below a pixel.
// Zoomed out, the live bath is one sheet in a gallery of prints that are all being marbled on the beat (their
// ops come from a hash, not from uniforms), and a collage tears other prints over the live one.
// uP1 = (N + 64*q12(prog0), q12(prog1) + 4096*q12(prog2), gallery clock (beats), collage amount + 256*seed)
// uP2 = (palCur + 16*palPrev + 256*styleCur + 1024*stylePrev + 4096*q8(build), hat clock, splash A,
//        q12(view zoom) + 4096*q12(bass swell / 1.5))
// uP3..uP5, uM1, uM2[0..1], uM2[2].x = op words 0..27 (24-bit integers), newest first.
// uM2[2].y = splash B, uM2[2].z = the lifted sheet (angle, hinge side, ghost, alpha, flooded).
// splash word: grid x + 64 * grid y + 2048 * q(age beats + .5, 1/48) + 2^19 * ink + 2^22 * size
// value noise with exactly vnoise()'s hash and fade, vectorised: the four corner hashes of a point in one vec4 (mbVn),
// or two / four points at once (mbVn2, mbVn4). Each inlined scalar vnoise cost the D3D compiler ~0.1 s at the first draw.
vec4 mbH4(vec4 x,vec4 y){vec4 qx=fract(x*.1031),qy=fract(y*.1031),d=qx*(qy+33.33)+qy*(qx+33.33)+qx*(qx+33.33);qx+=d;qy+=d;return fract((qx+qy)*qx);}
float mbVn(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);vec4 h=mbH4(i.x+vec4(0.,1.,0.,1.),i.y+vec4(0.,0.,1.,1.));return mix(mix(h.x,h.y,f.x),mix(h.z,h.w,f.x),f.y);}
vec4 mbVn4(vec4 X,vec4 Y){vec4 ix=floor(X),iy=floor(Y),fx=fract(X),fy=fract(Y);fx=fx*fx*(3.-2.*fx);fy=fy*fy*(3.-2.*fy);
  return mix(mix(mbH4(ix,iy),mbH4(ix+1.,iy),fx),mix(mbH4(ix,iy+1.),mbH4(ix+1.,iy+1.),fx),fy);}
vec2 mbVn2(vec2 a,vec2 b){vec4 i=floor(vec4(a,b)),f=fract(vec4(a,b));f=f*f*(3.-2.*f);
  vec4 ha=mbH4(i.x+vec4(0.,1.,0.,1.),i.y+vec4(0.,0.,1.,1.)),hb=mbH4(i.z+vec4(0.,1.,0.,1.),i.w+vec4(0.,0.,1.,1.));
  return vec2(mix(mix(ha.x,ha.y,f.x),mix(ha.z,ha.w,f.x),f.y),mix(mix(hb.x,hb.y,f.z),mix(hb.z,hb.w,f.z),f.w));}
// inks: 14 palettes x 8 inks (sRGB hex); a constant table (an if-chain here cost FXC ~0.7 s at the first draw;
// a switch compiles slower and runs slower)
const ivec4 MBPAL[28]=ivec4[28](
  ivec4(1784478,3108080,1685705,16036890),ivec4(14692911,16181968,15913572,658460),
  ivec4(675704,1022896,1160074,11985466),ivec4(14885757,15267583,15783016,133389),
  ivec4(5900846,13113162,16732038,16763096),ivec4(1026208,16773866,15914618,1180682),
  ivec4(4854472,9055231,16723610,16747039),ivec4(16771402,1700054,16178278,458767),
  ivec4(1843768,3820152,7048396,15222330),ivec4(15921126,12175068,14541548,328968),
  ivec4(409647,756318,3134362,13172708),ivec4(16732058,15400858,15520866,68874),
  ivec4(4004490,8007632,12991144,16743001),ivec4(16765806,4708351,16046704,525082),
  ivec4(670336,37088,3137736,16734826),ivec4(14352374,10476799,15915640,135455),
  ivec4(1184280,2046584,5929640,13647918),ivec4(14866626,16249316,15257706,328967),
  ivec4(4852758,10100522,1916786,13799978),ivec4(15782544,16314075,15783010,787717),
  ivec4(3806726,10499610,14839850,16757866),ivec4(6990048,16773346,16047232,919043),
  ivec4(1839704,4861104,12856464,16738874),ivec4(16762954,16773320,16178288,525850),
  ivec4(797776,2910384,9225456,15661311),ivec4(5216850,13625000,14870770,200732),
  ivec4(797294,2123464,14951982,16751258),ivec4(3055182,16248540,15913572,526868));
int mbHex(int pal,int i){ivec4 q=MBPAL[min(pal,13)*2+(i>>2)];int j=i&3;return j==0?q.x:(j==1?q.y:(j==2?q.z:q.w));}
float mbWord(int i){   // (one exit: early returns are costly for the D3D compiler)
  // (one-hot dot products: exact, a single non-zero term)
  ivec3 g=ivec3(i>>2)-ivec3(0,1,2);float a=dot(uP3*float(g.x==0)+uP4*float(g.y==0)+uP5*float(g.z==0),vec4(equal(ivec4(i&3),ivec4(0,1,2,3))));
  int j=max(i-12,0),cl=int(uint(j)/3u),r=j-cl*3;   // (i < 12 takes a; unsigned division is one instruction)
  vec3 v=cl==0?uM1[0]:(cl==1?uM1[1]:(cl==2?uM1[2]:(cl==3?uM2[0]:(cl==4?uM2[1]:uM2[2]))));
  return i<12?a:dot(v,vec3(equal(ivec3(r),ivec3(0,1,2))));
}
uint mbH(uint x){x^=x>>16;x*=0x7feb352du;x^=x>>15;x*=0x846ca68bu;x^=x>>16;return x;}
vec2 mbPos(int w){return vec2((float((w>>3)&63)/63.*2.-1.)*1.3,(float((w>>9)&31)/31.*2.-1.)*.8);}
float mbSpace(int k){return k==1?.5:(k==2?.34:(k==3?.23:(k==4?.155:(k==5?.105:(k==6?.07:.047)))));}
float mbWave(int k){return k==0?1.5:(k==1?1.05:(k==2?.74:(k==3?.52:(k==4?.37:(k==5?.26:(k==6?.18:.125))))));}
float mbArea(int k){return k==0?.0045:(k==1?.008:(k==2?.0135:.022));}
// ring colour sequences (ink index per ring, from the outside in), packed 3 bits per ring + period << 18
const int MBSEQ[16]=int[16](100845192,100711184,67112280,100764321,100772448,83912328,67111696,100751181,33554479,67111528,100842479,100842796,137701952,146458971,145394257,139760453);
int mbSeq(int pt){return MBSEQ[clamp(pt,0,15)];}
int mbRing(int sq,int m){return (sq>>(3*int(uint(m)%uint(sq>>24))))&7;}   // m >= 0: unsigned modulo is one instruction
// ---- gallery prints: a bath of 12 ops per print (a flood, then drops and strokes by the print's family)
// hb: the bath's hash (family, base angle, palette, vein style); op j of bath b
uint mbBath(int sd,int b){return mbH(uint(sd)*747796405u+uint(b)*2891336453u+1u);}
int mbDropW(uint hb,int j,int fam){
  uint h=mbH(hb^uint(j*40503+7));
  int x=8+int((h&63u)*3u/4u),y=4+int(((h>>6)&31u)*3u/4u),cA=int((h>>11)%6u),cB=int((h>>14)%6u);
  if(cB==cA)cB=(cA+3)%6;
  int r=(x<<3)|(y<<9)|(int((h>>17)&3u)<<14)|(cA<<16)|(cB<<19)|(int(1u+(h>>19)%3u)<<22);
  if(fam==1||(fam==5&&j==1))r=4|(x<<3)|(y<<9)|(int((h>>17)&7u)<<14)|((fam==1?int((h>>20)%3u):4+int((h>>21)&3u))<<18)|(int(2u+(h>>22)%4u)<<21);
  else if(fam==2)r=6|((j>2?1:0)<<3)|(min(j>>1,4)<<5)|(int((h>>17)&31u)<<8)|(cA<<13)|(cB<<16)|(int((h>>22)&3u)<<19)|(int(3u+(h>>9)%4u)<<21);
  return r;
}
int mbGen(int sd,int k){
  int b=int(uint(k)/13u),j=k-b*13,j3=int(uint(j)%3u),jq=int(uint(j)/3u);
  uint hb=mbBath(sd,b),h=mbH(hb^uint(j*40503+7));
  int fam=int((hb>>8)%7u),a0=int((hb>>12)&15u),x=int(h&63u),y=int((h>>6)&31u),al=(j&1)*2-1;
  // strokes; local ones act on the newest drop (one mbDropW call site, one exit: each inlined copy / return is costly for FXC)
  bool isd=j<3||j3==1;
  int jd=isd?j:((j3==2||j==3)?j-1:j-2),dw=mbDropW(hb,jd,fam),dx=(dw>>3)&63,dy=(dw>>9)&31,r;
  if(j==0)r=5|(x<<3)|(y<<9)|(int((h>>11)&15u)<<14)|(int((h>>15)&7u)<<18)|(int((h>>18)&7u)<<21);
  else if(isd)r=dw;
  else if(fam==0||(fam==6&&j<7))       // gel-git, then nonpareil: back-and-forth combs, offset by half a tine, finer each pass
    r=1|(((a0+8*((j>>1)&1))&15)<<3)|(min(2+jq,6)<<7)|((15+13*al)<<10)|((((j&1)*64+j*23)&127)<<15)|(1<<22);
  else if(fam==1)r=(j&1)==0?(3|(dx<<3)|(dy<<9)|((15+al*int(7u+(h>>11)%6u))<<14)|(int(2u+(h>>14)%3u)<<19))
                         :(2|(int((h>>11)&15u)<<3)|(int(1u+(h>>15)%3u)<<7)|((15+5*al)<<10)|(int((h>>18)&127u)<<15));
  else if(fam==2)r=2|(((a0+8*(j&1))&15)<<3)|(int(1u+(h>>15)%2u)<<7)|((15+4*al)<<10)|(int((h>>18)&127u)<<15);
  else if(fam==3)r=7|(dx<<3)|(dy<<9)|(int((h>>11)%6u)<<14)|((7+al*int(4u+(h>>14)%4u))<<17)|(int((h>>17)&3u)<<21)|(int((h>>19)&1u)<<23);
  else if(fam==4)r=2|(((a0+8*((j>>1)&1))&15)<<3)|(min(2+jq,5)<<7)|((15+15*al)<<10)|(int((h>>18)&127u)<<15)|(1<<22);
  else if(fam==5)r=3|(dx<<3)|(dy<<9)|((15+al*int(9u+(h>>11)%6u))<<14)|(int(1u+(h>>14)%3u)<<19)|(int((h>>17)&1u)<<22);
  else r=2|(((a0+8*(j&1))&15)<<3)|(int(5u+(h>>15)%2u)<<7)|((15+9*al)<<10)|(int((h>>18)&127u)<<15);
  return r;
}
// supersample offsets: centre, a rotated grid of four, then four hashed (h11(s*3.1), h11(s*7.7) - .5) * .9, as constants
#if HD>=1
#define MBSN (9+int(HD>=2)*4+int(HD>=3)*3+int(HD>=4)*8+int(HD>=5)*8)
#else
#define MBSN 9
#endif
#define MBGL (2+(HD>=2?2:(HD>=1?1:0)))
const vec2 MBSS[9]=vec2[9](vec2(0.,0.),vec2(-0.375,-0.125),vec2(0.125,-0.375),vec2(0.375,0.125),vec2(-0.125,0.375),vec2(-0.0696533173,0.332446277),vec2(-0.0887695253,-0.318823248),vec2(0.329946905,0.242523193),vec2(-0.248565674,-0.0394958481));
vec3 mbInk(int code,int pc,int pp){
  int pal=(code>>3)==0?pc:pp,hx=mbHex(pal,code&7);vec3 s=vec3(float(hx>>16),float((hx>>8)&255),float(hx&255))/255.;
  return pow(s,vec3(2.1))*1.32;          // sRGB -> linear HDR
}
// ---- HD tiers (Native and up): the ink is never flat. Every ink carries a marbled figure of its own, in its own flowed
// coordinates (material coordinates: it rides exactly with the ink, so it cannot swim or shimmer): generations of stones
// dropped one inside another, each pushing the finer ones aside into hairline rims (the same exact compact pushes as the
// bath), and between generations a fine wave comb. Each generation fades before it can alias; the loop runs to a ceiling
// set by the tier and stops early once a generation is smaller than the pixel.
// v20: line weight follows size on screen (every big stone carries a full rim, of the fine ones six in ten do, so a dark ink stays dark);
// stones are domed (pigment gathers at the rim) and some are tiger eyes (a core and fine rays).
// (High and below do not call this: three generations in the dark inks were tried in v20 and read as doodles on the black)
#define MBGEN (HD>=1?7+2*HD:3)
// the square root of the render pixels per screen pixel at this tier (1, 1.5, 2, 3, 4 across). Rims are drawn that many
// render pixels wide and stones are kept down to that size: on the screen a tier's lines are finer by this factor and its
// smallest stones smaller by it, so the ink a figure covers stays the same from tier to tier (a dark ink stays dark, nothing
// sums to a haze) while the detail it is drawn with doubles from Native to Offline
#define MBPQ (HD>=5?2.:(HD>=4?1.732:(HD>=3?1.414:(HD>=2?1.225:1.))))
// out: x tone (1 = untouched), y accent amount, z rim, w highest generation seen (0..1)
vec4 mbFigure(vec2 u,float fp,float sd,out float gf){
  float s=.19,v=1.,acc=0.,rim=0.,gd=0.;gf=0.;
  for(int l=int(min(uTime,0.));l<MBGEN;l++){
    if(fp>s*.8)break;
    float fl=float(l),th=fl*2.4+sd*5.;
    vec2 wd=vec2(cos(th),sin(th)),wn=vec2(-wd.y,wd.x);
    float L=s*3.1,A=.17*s,ph=dot(wn,u)*TAU/L+fl*2.7+sd*9.;
    u+=wd*A*sin(ph);fp*=1.+abs(A*TAU/L*cos(ph));
    if((l&1)==1){                                  // every other generation a fine comb is drawn through: feathers
      float cs=s*2.6,dc=dot(wn,u),dd=cs*(fract(dc/cs+fl*.37+sd)-.5),lam=s*.07,Az=s*.62*(mod(fl,4.)>2.?-1.:1.),ga=lam+abs(dd);
      u-=wd*Az*lam/ga;fp*=1.+abs(Az*lam/(ga*ga));
    }
    mat2 Rm=rot(fl*1.9+sd);
    vec2 wg=Rm*u/s+sd*37.3+fl*7.7,ci=floor(wg),f=wg-ci-.5;
    vec4 h=mbH4(ci.x+vec4(1.7,5.3,9.1,2.9)+fl,ci.y+vec4(3.1,.7,7.7,4.3)+fl);
    if(h.z<.6){
      vec2 d=f-(h.xy-.5)*.34;float R=.13+.23*h.w,Rc=.46,q2=dot(d,d),r=sqrt(q2),pu=fp/s;
      if(r<Rc){
        if(r<R+.6*pu){
          float a=clamp((R-r)/pu+.5,0.,1.),rp=R/pu,fd=smoothstep(.25,1.,rp),tn=fract(h.w*7.13+fl*.31),rs=rp/MBPQ,lw=(fract(h.w*23.1+fl*.7)<.62+.38*smoothstep(2.5,9.,rs)?1.:.1+.9*min(.3*(uB2.z+uB2.w)+uO2.z+uO2.w,1.))*smoothstep(.3,1.1,rs),af=a*fd;   // (line weight: every large stone carries a full rim, of the fine ones six in ten do, at full strength: the black between them is what keeps a dark ink dark; the hidden ones flash in on the hats and the air)
          v*=mix(1.,(.62+.8*tn)*(1.12-.34*q2/(R*R)),af);                    // domed: paler at the crown, deeper toward the rim
          if(tn>.78)acc=max(acc,af);
          if(fract(h.w*13.7+fl*.21)<.38&&rs>5.){                           // a tiger eye: a core and fine rays
            float rr=r/R,nr=7.+floor(h.x*8.),ag=atan(d.y,d.x)/TAU*nr+h.y*3.+(h.x-.5)*2.2*rr,arc=TAU*r/(nr*pu),sl=.5+.5*fract(sin(floor(ag)*12.9898+h.w*40.)*43758.5453);   // rays of uneven length, drawn with a slight twist
            float ry=(1.-smoothstep(.45*MBPQ,1.25*MBPQ,abs(fract(ag)-.5)*arc))*smoothstep(2.5*MBPQ,5.*MBPQ,arc)*smoothstep(.22,.4,rr)*(1.-.5*rr)*(1.-smoothstep(sl-.08,sl,rr));
            float co=1.-smoothstep(-.6,.6,(r-.17*R)/pu);
#if HD>=3
            co=max(co,(1.-smoothstep(0.,1.2*MBPQ,abs(r-.8*R)/pu))*.7);   // (Insane and up: an inner rim, like a struck coin)
#endif
            rim=max(rim,max(ry*.6,co*.8)*af*smoothstep(5.,9.,rs));
          }
#if HD>=2
          float br=fract(r/R*(2.+float(HD)+3.*h.w)+tn*3.),bpx=(2.+float(HD)+3.*h.w)*pu/R;                 // suminagashi rings inside the stone
          v*=1.-.2*af*(1.-smoothstep(0.,max(bpx*1.2,.12),min(br,1.-br)))*(1.-smoothstep(.25,.8,bpx));
#endif
#if HD>=3
          if(tn<.02+.006*float(HD)&&rs<5.)gf=max(gf,af*smoothstep(.4,1.2,rs));                                                       // a fleck of gold leaf
#endif
          rim=max(rim,(1.-smoothstep(0.,1.5*MBPQ,abs(R-r)/pu))*fd*lw);
          gd=max(gd,fd*(fl+1.)/float(MBGEN));
          u=d*s;                       // the stone's inside is a new bath: the next generation lands in it
        }else{
          float T=R*R,s1=1./(1.-T/(Rc*Rc)),k=sqrt(max(s1*(1.-T/q2),1e-8));
          u+=transpose(Rm)*(d*(k-1.))*s;fp*=max(1.,s1/k);
        }
      }
    }
    s*=.62;
  }
  return vec4(clamp(v,.42,1.7),acc,rim,gd);
}
// the pixel's footprint in sheet coordinates (set by realm(): isotropic when the camera looks straight down)
mat2 mbJ;
// the maker's chop: a 5x7 stencil face, ten characters and (m) a small cap-and-stem mark; p.x 0..66, p.y 0..7 from the foot. 1 on ink
float mbChop(vec2 p,float m){
  const ivec2 G[9]=ivec2[9](ivec2(508430,1086),ivec2(1020036,4228),ivec2(476721,17966),ivec2(583347,17969),ivec2(1032734,16927),ivec2(1001009,17982),ivec2(476735,17969),ivec2(1001022,16912),ivec2(491492,4238));
  const int W[11]=int[11](0,1,2,3,4,5,-1,6,7,4,8);
  int ci=clamp(int(p.x/6.),0,10),cx=int(p.x)-ci*6,g=W[ci],r=clamp(6-int(p.y),0,6),gi=max(g,0);
  bool ok=p.x>=0.&&p.x<66.&&p.y>=0.&&p.y<7.&&g>=0&&cx<=4&&(ci<10||m>.5);
  int bits=r<4?(G[gi].x>>((3-r)*5))&31:(G[gi].y>>((6-r)*5))&31;
  return ok?float((bits>>(4-cx))&1):0.;
}
// p0: sheet coordinates, px: pixel size, gal: a gallery print (seed sd) instead of the live bath
vec3 mbSample(vec2 p0,float px,bool gal,int sd,float build,out float res,out float old){
  // a gallery print is either its own bath (gen: a hashed recipe of a random family, 12 ops per bath, one op every
  // beat or two) or the live bath seen through a scramble: every op keeps its kind and timing but lands at a
  // different place and angle, with its own palette, vein style and a lag of up to two ops behind the live one
  uint hs=gal?mbH(uint(sd)*2246822519u+3u):0u;
  bool gen=gal&&(hs&48u)!=0u;
  int N=int(mod(uP1.x,64.)+.5),lag=int(hs%3u),xm=int((hs>>2)&0x3ffff8u),pk=int(mod(uP2.x,4096.)+.5),ps=gal?1+int((hs>>16)%10u):0,K=0;
  float pr0=mod(floor(uP1.x/64.),4096.)/4095.*2.-1.,pr1=mod(uP1.y,4096.)/4095.*2.-1.,pr2=floor(uP1.y/4096.)/4095.*2.-1.;
  int palC=((pk&15)+ps)%14,palP=(((pk>>4)&15)+ps)%14,styC=((pk>>8)&3)^int((hs>>26)&3u),styP=((pk>>10)&3)^int((hs>>26)&3u);
  if(gen){
    // every print keeps its own time: a tempo multiple (1, 1/2, 3/4) or, for one in four, free-running clock time,
    // and its own fractional phase, so the wall never steps together: it shimmers op by op like a living museum
    float t=((hs>>14)&3u)==0u?uTime*(.7+.08*float((hs>>3)&7u)):uP1.z*((hs&1u)==0u?1.:((hs&2u)==0u?.5:.75));
    t+=float((hs>>6)&255u)*.2734+64.;
    K=int(t);float f=min(fract(t)*(1.3+.12*float((hs>>22)&7u)),1.);pr0=1.-(1.-f)*(1.-f)*(1.-f);pr1=1.;pr2=1.;lag=0;
    int b=int(uint(K)/13u),j=K-b*13;N=(j==0&&pr0<1.)?14:j+1;
    uint h1=mbBath(sd,b),h0=mbBath(sd,b-1);
    palC=int((h1>>20)%14u);palP=int((h0>>20)%14u);styC=int((h1>>27)&3u);styP=int((h0>>27)&3u);
  }
  // ---- hat spatter (live bath): tiny droplets bloom on top, push the ink aside, then dissolve (not history)
  vec2 p=p0;float spA=0.,spM=0.;int spR=5,spK=0;
  if(!gal){
    float gs=.075;vec2 cid=floor(p0/gs);
    float h1=h21(cid+11.3),h2=h21(cid*1.7+3.1),h3=h21(cid*2.3+7.7);
    float P=6.,a=mod(uP2.y-h1*P,P),bh=floor(uP2.y-a+.5);
    vec2 bc=vec2(h11(bh*.731)*1.7-.85,h11(bh*1.37+.3)*.9-.45);
    vec2 cc=(cid+.35+.30*vec2(h3,fract(h3*13.7)))*gs;
    float near=1.-smoothstep(.12,.42,length((cc-bc)*vec2(.75,1.))+.1*(h2-.5));
    float R=gs*.16*near*(.35+.65*h2*h2)*smoothstep(0.,.35,a)*(1.-smoothstep(P*.35,P*.7,a)),Rc=R*2.1;
    if(R>1e-5){
      vec2 v=p0-cc;float q2=dot(v,v),r=sqrt(q2);
      if(q2<R*R)p=cc;
      else if(q2<Rc*Rc){float u=(q2-R*R)/(1.-R*R/(Rc*Rc));p=cc+v*sqrt(max(u,0.)/max(q2,1e-12));}
      spA=smoothstep(.6,-.6,(r-R)/px)*(1.-smoothstep(P*.25,P*.55,a));
      spR=h11(bh*5.1)<.45?6:5;spK=int(h11(bh*2.9)*4.99);spM=smoothstep(-.6,.6,(r-R*.55)/px);
    }
  }
  // ---- trace back through the bath
  mat2 J=mbJ;
  float sw=floor(uP2.w/4096.)/4095.*1.5;
  if(build>.01&&!gal){  // build: the whole bath is wound tighter and tighter around the centre (it unwinds on release)
    float S=-2.4*build*build,r2=dot(p,p),an=S*exp(-r2/.36),da=-an/.36;
    vec2 w2=rot(-an)*p;J=(rot(-an)-2.*da*outerProduct(vec2(-w2.y,w2.x),p))*J;p=w2;
  }
  {  // the bath is never quite still: a slow, bass-swollen drift of the water surface
    float fa=.004+.012*sw,a1=p.y*4.7+uTime*.6,a2;
    p.x+=fa*sin(a1);J=mat2(1.,0.,fa*4.7*cos(a1),1.)*J;
    a2=p.x*3.9-uTime*.45;p.y+=fa*sin(a2);J=mat2(1.,fa*3.9*cos(a2),0.,1.)*J;
  }
  int slot=0,C0=0,C1=-1,baseC=0,eCol=-1,bestCol=-1;
  bool hit=false,sh=false,lfh=false,lsv=false;
#if HD>=1
  vec2 eDir=vec2(0.),eDirM=vec2(0.);
#endif
  float eMin=1e4,bestE=1e4,fr=.5,wpx=1e3;vec2 tl=vec2(0);
  int nl=28+int(min(uTime,0.));
  // no continue and a single break per op in this loop: every early exit / early return cost the D3D compiler time
  bool dn=false;
  for(int i0=0;i0<28;i0++){
    int i=i0+lag;                                  // (the first lag ops are skipped)
    if(i>=N||i>=nl||dn)break;
    int w=gen?mbGen(sd,K-i):int(mbWord(i)),ty=w&7;
    if(!gen)w^=ty==1||ty==2?xm&0x3f8078:(ty==6?xm&0x1f00:xm&0x3ff8);
    float pr=i==0?pr0:(i==1?pr1:(i==2?pr2:1.));
    vec2 cw=mbPos(w);                              // the op's site (polar strokes and drops; one inlined copy)
    // if/else, not switch (a switch measured slower with FXC; D3D11 HLSL also rejects continue inside a switch)
    if(ty==1||ty==2){                              // comb / stylus / wave: shear along the stroke direction
      float th=float((w>>3)&15)*(PI/16.);vec2 m=vec2(cos(th),sin(th)),nn=vec2(-m.y,m.x);
      int spk=(w>>7)&7,lk=(w>>22)&3;
      float amp=float(((w>>10)&31)-15)/15.*pr,off=float((w>>15)&127)/128.,d=dot(nn,p),z,dz;
      if(ty==1){
        float s=spk==0?1e3:mbSpace(spk),lam=spk==0?.016*exp2(float(lk)):s*.06*exp2(float(lk));
        float dd=spk==0?d-(off*1.3-.65):s*(fract(d/s-off+.5)-.5),ad=abs(dd),A=amp*(spk==0?.45:s*1.25);
        z=A*lam/(lam+ad);dz=-A*lam/((lam+ad)*(lam+ad))*sign(dd);
      }else{
        float L=mbWave(spk),A=amp*.2*sqrt(L),ph=TAU*(d/L+off),k=TAU/L,sn=sin(ph),cs=cos(ph);
        // triangle-ish (lk 1: asin of a sine) or a plain sine (lk 0) with a third (2) or second (3) harmonic
        float u=.94*sn,q=sqrt(max(1.-u*u,1e-4));
        float hn=lk==2?3.:2.,ha=lk==0?0.:(lk==2?.28:.45),hd=lk==0?0.:(lk==2?.84:.9),hs=lk==0?1.:(lk==2?.85:.8);
        bool tr=lk==1;
        z=mix(A*(sn+ha*sin(hn*ph))*hs,A*asin(u)*.82,tr);dz=mix(A*(cs+hd*cos(hn*ph))*hs*k,A*.94*cs/q*.82*k,tr);
      }
      p-=z*m;
      if(!sh)J=(mat2(1.)-dz*outerProduct(m,nn))*J;
    }else if(ty==3||ty==7){                        // polar strokes: swirl, ring stylus (rose), radial stylus
      // inverse map p = c + rot(-an(r)) * (r - z(r,th)) * e_r: a rotation that depends on the radius (swirls and
      // roses) and a pull along the radius that depends on the angle (petals, wings); both are exact bijections
      vec2 c=cw,v=p-c;float r=length(v)+1e-7,an=0.,da=0.,z=0.,zr=0.,zt=0.;
      if(ty==3){
        float S=float(((w>>14)&31)-15)/15.*2.8*pr,sg=.07*exp2(float((w>>19)&7)*.45);
        float aG=S*exp(-r*r/(sg*sg)),d=r-sg*.8,l=.03,aR=S*.32*l/(l+abs(d));bool rg=((w>>22)&1)==0;
        an=mix(aR,aG,rg);da=mix(-aR/(l+abs(d))*sign(d),-2.*r*aG/(sg*sg),rg);
      }else{
        int ns=3+((w>>14)&7),md=(w>>21)&3;
        float th=atan(v.y,v.x),Rw=.15,A=float(((w>>17)&15)-7)/7.*pr*.085;
        float f=th/TAU*float(ns)+.5*float((w>>23)&1),dth=(fract(f+.5)-.5)*TAU/float(ns);
        if(md==2){float b=atan(v.x,v.y);dth=-(abs(b)-1.05)*sign(b);A=abs(A)*1.15;}
        if(md==3&&(int(floor(f+.5))&1)==1)A*=-.55;
        float lam=md==1?.03:.011,ad=abs(dth)*Rw,pf=lam/(lam+ad),x=r/Rw,ex=exp(.5-.5*x*x);
        z=A*pf*x*ex;zr=A*pf*(1.-x*x)*ex/Rw;zt=-z/(lam+ad)*Rw*sign(dth);
      }
      vec2 er=v/r,et=vec2(-er.y,er.x);float rho=r-z;mat2 Rt=rot(-an);
      if(!sh)J=Rt*((1.-zr)*outerProduct(er,er)+outerProduct(rho*et-zt*er,et)/r-da*rho*outerProduct(et,er))*J;
      p=c+Rt*(er*rho);
    }else{                                         // drops: 0 site, 4 many-ringed, 5 flood (new bath), 6 sprinkle
      bool fl=ty==5,leaf=false,go=true;            // go: this op still acts on the point
      vec2 c;int n=1,sq=0;float T,R=0.,gm=1.,a0=0.,a=0.,Rc2=1e30,dl=0.,ex=0.;
      if(ty==6){
        int md=(w>>3)&3,sdd=(w>>8)&31;float gs=.3*pow(.72,float((w>>5)&7)),an=float(sdd)*.61;
        mat2 Rm=rot(an);vec2 u=Rm*p/gs+float(sdd)*.37,ci=floor(u);
        float hA=h21(ci+float(sdd)*.13),hB=h21(ci*1.31+5.7),hC=h21(ci*.71+9.1),hD=h21(ci*2.13+1.9);
        float rf=(.2+.035*float((w>>21)&7))*(.6+.4*hB);
        if(md==2)rf*=.4;
        float rc=min(rf*1.5,.48),jr=.5-rc;
        vec2 cu=ci+.5+jr*(vec2(hA,hC)*2.-1.);
        c=transpose(Rm)*((cu-float(sdd)*.37)*gs);
        go=!(hD>.45+.18*float((w>>19)&3)||(md==3&&hD>.27));
        R=rf*gs;Rc2=rc*rc*gs*gs;T=R*R*max(pr,0.);
        int cA=(w>>13)&7,cB=(w>>16)&7;
        if(md==3){                                 // gold leaf: a torn flake, laid on the bath (no push)
          leaf=true;vec2 lv=rot(hA*6.28)*(u-cu);
          dl=(max(abs(lv.x)-rf*(.45+.45*hC),abs(lv.y)-rf*(.22+.3*hB))+dot(vec2(rf*.5,rf*.15),mbVn2(lv*9./rf+hD*40.,lv*31./rf)-.5)+.03*(1.-pr))*gs;
        }else if(md==1){n=2;a0=T*.8;a=T*.2;sq=cA|(cB<<3)|(2<<24);}
        else{int k=hB>.5?cA:cB;a0=T;sq=k|(k<<3)|(2<<24);}
      }else{
        c=cw;
        if(fl){n=10+((w>>14)&15);sq=mbSeq((w>>18)&7);gm=.55+.13*float((w>>21)&3);R=(2.4+length(c))*max(pr,0.);T=R*R;}
        else if(ty==4){n=6+2*((w>>14)&15);int sf=(w>>18)&7;sq=mbSeq(sf+8);float Rf=.07*pow(1.3,float((w>>21)&7));T=Rf*Rf*max(pr,0.);a=T/float(n);a0=a;
          if(sf>3)ex=1.1+.25*float((w>>3)&3)+.2*float((w>>9)&1);}
        else{n=((w>>14)&3)+1;sq=((w>>16)&7)|(((w>>19)&7)<<3)|(2<<24);a=mbArea((w>>22)&3);a0=a*max(pr,0.);
          if(i==0&&!gal)a0+=a*.85*sw;
          T=a*float(n-1)+a0;}
      }
      vec2 v=p-c;float q2=dot(v,v),r=sqrt(q2);
      go=go&&q2<Rc2;
      vec2 nr=r>1e-7?v/r:vec2(1,0);
      if(go&&leaf){
        go=false;
        float g=.5*(length(J[0])+length(J[1])),e=dl/g;
        if(e<0.){
          if(sh){C1=slot*8+6;dn=true;}
          else{
            C0=slot*8+6;hit=true;lfh=true;lsv=((w>>13)&7)==7;wpx=6.;tl=v*2.;fr=.5;
            if(-e<min(eMin,2.)){bestE=-e;sh=true;}
            else{bestE=eMin;bestCol=eCol;dn=true;}
          }
        }else if(!sh&&e<eMin){eMin=e;eCol=slot*8+6;}
      }
      int outC=mbRing(sq,0);                       // outermost ring colour (the first ink dropped)
      float s=1./max(1.-T/Rc2,1e-4);
      if(go&&q2<T){
        go=false;
        float rlo,rhi,be=1e4,beG=1.,w0b=0.;int rc,inC=-1,ouC=-1,bxC=0;bool bin=false;
        if(fl){
          // rings are poured from the centre and stream outward at fixed widths: ring 0 is the front
          float Rf=2.4+length(c);
          int m=min(int(floor(float(n)*pow(max(R-r,0.)/Rf,1./gm))),n-1);
          rhi=R-Rf*pow(float(m)/float(n),gm);rlo=m==n-1?0.:max(R-Rf*pow(float(m+1)/float(n),gm),0.);
          rc=mbRing(sq,m);if(m<n-1)inC=mbRing(sq,m+1);if(m>0)ouC=mbRing(sq,m-1);
          fr=(r-rlo)/max(rhi-rlo,1e-6);
          if((m&1)==1&&m<n-1){                     // every other ring carries a thin stripe of a later ink
            float w0=rhi-rlo,sa=rlo+w0*.66,sb=rlo+w0*.76;int st=mbRing(sq,m+2);
            if(r>=sb){inC=st;rlo=sb;}else if(r>=sa){inC=rc;ouC=rc;rc=st;rlo=sa;rhi=sb;}else{ouC=st;rhi=sa;}
            fr=(r-rlo)/max(rhi-rlo,1e-6);
          }else if(((w>>23)&1)==1&&m>1&&m<n-1&&!sh&&rhi-rlo>8.*length(nr*J)){   // only where the ring is wide on screen   // a patterned pour: a necklace of beads (large, small) in the ring
            float w0=rhi-rlo,rm=rlo+.5*w0,nb=max(5.,floor(TAU*(rm+Rf-R)/(w0*2.3)));
            float ci=floor(atan(v.y,v.x)/TAU*nb+.5),bt=ci*TAU/nb;vec2 bv=v-rm*vec2(cos(bt),sin(bt));
            float bl=length(bv),br=w0*(mod(ci,2.)<.5?.3:.17),dd=bl-br;int bi=mbRing(sq,m+3);
            if(bi==rc)bi=6;
            beG=max(length((bv/max(bl,1e-7))*J),1e-7);
            if(dd<0.){bxC=rc;rc=bi;inC=-1;ouC=-1;be=-dd/beG;fr=1.+dd/br;bin=true;w0b=br;}else{be=dd/beG;bxC=bi;}
          }
        }else{
          int m;float lo2,hi2;
          if(ex>0.){                               // agate: bands of irregular width (a monotone warp of the ring index)
            float js=float(w>>3)*.37,x=float(n)*q2/T,xw=x+.34*sin(x*ex+js),f=fract(xw),dr=2.*r*float(n)/T*(1.+.34*ex*cos(x*ex+js));
            m=min(int(xw),n-1);float r0=r-f/max(dr,1e-6),r1=r+(1.-f)/max(dr,1e-6);lo2=max(r0,0.);lo2*=lo2;hi2=r1*r1;
          }else if(q2<a0){m=0;lo2=0.;hi2=a0;}else{float k=min(floor((q2-a0)/max(a,1e-12)),float(n-2));m=1+int(k);lo2=a0+k*a;hi2=lo2+a;}
          int j=n-1-m;rc=mbRing(sq,j);
          if(m>0)inC=mbRing(sq,j+1);if(j>0)ouC=mbRing(sq,j-1);
          rlo=sqrt(lo2);rhi=sqrt(hi2);fr=(q2-lo2)/max(hi2-lo2,1e-9);
        }
        if(!sh){
          float g=max(length(nr*J),1e-7),ei=inC>=0?(r-rlo)/g:1e4,eo=(rhi-r)/g;
#if HD>=1
          vec2 gv=nr*J/g;eDir=eDirM;
#endif
          C0=slot*8+rc;hit=true;wpx=(rhi-rlo)/g;tl=v;
          bestE=eMin;bestCol=eCol;
          if(ei<bestE){bestE=ei;bestCol=slot*8+inC;}
          bool need=false;
          if(eo<bestE){bestE=eo;if(ouC>=0)bestCol=slot*8+ouC;else{bestCol=-1;need=true;}}
          if(be<bestE){bestE=be;bestCol=slot*8+bxC;need=false;}
          if(bin)wpx=2.*w0b/beG;
#if HD>=1
          if(bestE==ei)eDir=-gv;else if(bestE==eo)eDir=gv;
#endif
          if(need&&bestE<2.){                     // colour just outside this drop: trace on from there
            sh=true;vec2 v1=nr*(sqrt(T)+g*.8);float q1=dot(v1,v1);
            p=c+v1*(q1<Rc2?sqrt(max(s*(1.-T/q1),0.)):1.);
            if(fl){baseC=slot*8+outC;slot++;}
          }else dn=true;
        }else{C1=slot*8+rc;dn=true;}
      }
      if(go){
        if(!sh){
          float g=max(length(nr*J),1e-7),e=(r-sqrt(T))/g;
          if(e<eMin){eMin=e;eCol=slot*8+outC;
#if HD>=1
            eDirM=-nr*J/g;
#endif
          }
        }
        float k=sqrt(max(s*(1.-T/max(q2,1e-12)),1e-10));
        if(!sh)J=(k*mat2(1.)+(s*T/(k*q2*q2+1e-20))*outerProduct(v,v))*J;
        p=c+v*k;
        if(fl){baseC=slot*8+outC;slot++;}
      }
    }
  }
  if(!hit){C0=baseC;bestE=eMin;bestCol=eCol;}
  if(sh)bestCol=C1>=0?C1:baseC;
  if(bestCol<0){bestCol=C0;bestE=1e4;}
  // ---- inks
  // all ink lookups go through one call site (each inlined palette lookup is costly for the D3D compiler)
  vec3 i0,i1,gold,sR,sK;
  vec3 isib;int pal0=(C0>>3)==0?palC:palP;
#define MBNK 6
  int nk=MBNK+int(min(uTime,0.));
  for(int k=0;k<MBNK;k++){
    if(k>=nk)break;
    vec3 v=mbInk(k==0?C0:(k==1?bestCol:(k==2?((C0&~7)|6):(k==3?spR:(k==4?spK:((C0&~7)|((C0+3)&7)))))),palC,palP);
    if(k==0)i0=v;else if(k==1)i1=v;else if(k==2)gold=v;else if(k==3)sR=v;else if(k==4)sK=v;else isib=v;
  }
  if(!gal){   // colour wells: every ink is fed by its own band (deep inks by the bass ... pale inks by the air)
    int ik=C0&7;vec4 e1=vec4(equal(ivec4(ik),ivec4(0,1,2,3))),e2=vec4(ik>=6,ik==4,0.,0.);
    float lv=dot(uB1,e1)+dot(uB2,e2)+(ik==5?.5*(uB2.z+uB2.w):0.),
          on=dot(uO1,e1)+dot(uO2,e2)+(ik==5?max(uO2.z,uO2.w):0.);
    i0*=.94+.22*lv+.2*on;
  }
  // ---- the ink tide: every ink is fed by its own band (deep inks by the sub and bass ... pale inks by the
  // air), so each frequency range lights and saturates its own family of inks across the whole print
  {int ik=C0&7;vec4 e1=vec4(equal(ivec4(ik),ivec4(0,1,2,3))),e2=vec4(ik>=6,ik==4,0.,0.);
   float tl2=dot(uB1,e1)+dot(uB2,e2)+(ik>=4?.5*(uB2.z+uB2.w):0.),tn=dot(uO1,e1)+dot(uO2,e2)+(ik==5?max(uO2.z,uO2.w):0.);
   float tq2=clamp(tn*.45,0.,1.)*.8;i0=mix(i0,i0*i0*1.35+.03,tq2);i1=mix(i1,i1*i1*1.35+.03,tq2);
   i0*=.9+.34*tl2;i1*=.9+.34*tl2;}
  int sty=(C0>>3)==0?styC:styP;
  float lodR=smoothstep(.6,2.5,wpx);
  // ink body: denser toward the drop's rim, faint growth lines inside wide rings (low-mids deepen them)
  float body=.8+.32*pow(clamp(fr,0.,1.),1.6);
  float gl1=min(abs(fr-.333),abs(fr-.667))*wpx;
  body-=(.1+.12*uB1.z)*(1.-smoothstep(.4,1.4,gl1))*smoothstep(7.,16.,wpx);
  // ink texture in the drop's own coordinates (combing stretches it into veins along the flow): mottle, then
  // fine pigment granulation that gathers toward the rim, each octave fading before it would alias
  float jn=max(length(J[0]),length(J[1]));
  vec2 tq=rot(.62)*tl;
  if(jn<.0131){                                    // (every octave below has faded out beyond this footprint)
  vec2 n0=tq*44.+float(C0)*7.3,n1=tl*131.+3.1,n2=tq*430.+9.7,n3=tq*23.+float(C0);
  vec4 nz=mbVn4(vec4(n0.x,n1.x,n2.x,n3.x),vec4(n0.y,n1.y,n2.y,n3.y));
  float mt=(nz.x-.5)*(1.-smoothstep(.15,.45,44.*jn))+.6*(nz.y-.5)*(1.-smoothstep(.15,.45,131.*jn));
  float gr=(nz.z-.5)*(1.-smoothstep(.12,.4,430.*jn));
  float vk=abs(nz.w-.5),vw=23.*jn*1.2+.012;  // pigment veins: wandering iso-lines in wide rings
  body*=1.+.13*mt+.4*gr*(.4+fr)-.08*(1.-smoothstep(0.,vw,vk))*(1.-smoothstep(.08,.3,23.*jn));
  }
#if HD>=2
  if(jn<.0025){                                    // the finest pigment floc: two more octaves that only exist once a pixel is small enough
    vec2 gra=mbVn2(tq*860.+3.3,tq*1720.+11.7);
    body*=1.+.26*(gra.x-.5)*(1.-smoothstep(.12,.4,860.*jn))+.22*(gra.y-.5)*(1.-smoothstep(.12,.4,1720.*jn));
  }
#endif
  vec3 c0=i0*mix(1.,body,lodR);
  // ---- the combed frill: fine ridging along the ink's own flow, brought out by the mids and highs
  {float fw=62.+70.*uB2.y,fp=fract(tq.y*fw+tl.x*fw*.55+uTime*.35);
   float fc=.5+.5*cos(TAU*fp),amp=(.10+.16*uB1.w+.20*uB2.x+.22*uO2.x)*(1.-smoothstep(.004,.012,jn));
   float fm=amp*(fc-.5);c0*=(1.+fm);}

  if((C0&7)==6){                                   // metallic ink / gold leaf: sheen that is combed with the ink
    float sf=1.-smoothstep(.2,.6,11.*jn),sv=.5+.5*sin(dot(tl,vec2(.8,.6))*11.+fr*2.5-uTime*.6)*sf;
    vec2 fq=tl*90.,fi=floor(fq);float fl=h21(fi+5.3);       // sparse glints carried by the flow: stars on the highs
    vec2 fv=(fq-fi-.25-.5*vec2(fl,fract(fl*17.3)))/max(90.*jn,1e-4);float fd=length(fv),hon=uO2.z+uO2.w,rl=1.5+5.*hon;
    float st=smoothstep(1.6,.4,fd)+.7*(smoothstep(.9,.15,abs(fv.y))*max(0.,1.-abs(fv.x)/rl)+smoothstep(.9,.15,abs(fv.x))*max(0.,1.-abs(fv.y)/rl));
    float tw=step(lfh?.84:.93,fl)*st*(.5+.5*sin(uTime*4.+fl*60.))*(.3+uB2.z+uB2.w+1.6*hon)*(1.-smoothstep(.15,.4,90.*jn));
    c0=i0*(.75+.75*sv*sv)*mix(1.,body,.5)*(1.+.35*uB2.y)+vec3(1.,.9,.7)*(pow(sv,10.)*(.45+.5*uO2.y)+tw*lodR*1.5);
    if(lfh){                                       // gold leaf: crinkled facets catching the light, hairline cracks
      vec3 nz=vec3(mbVn2(tl*28.,tl*70.),mbVn(tl*45.+3.));
      float fd2=1.-smoothstep(.15,.45,70.*jn),cr=mix(.5,nz.x*.6+nz.y*.4,fd2);
      float ck=(1.-smoothstep(0.,.03+70.*jn*.6,abs(nz.z-.5)))*fd2;
      // bright yellow gold (green kept near .8 of red at every tone, so it never drifts to copper) or silver
      c0=mix(lsv?vec3(.16,.17,.19):vec3(.46,.38,.08),lsv?vec3(1.35,1.4,1.5):vec3(1.75,1.52,.42),smoothstep(.2,.68,cr))*(1.+.5*uB2.y+.9*uO2.y)*(1.-.6*ck)*(.45+.55*smoothstep(.5,2.5,bestE))
        +(lsv?vec3(.9,.95,1.):vec3(1.,.93,.6))*tw*2.5;
    }
  }
#if HD>=1
  if(!lfh){
    float wg=smoothstep(4.,20.,wpx);
    if(wg>0.){
      // footprint: between the longest stretch and the area footprint, so ink that a comb has drawn out keeps its figure
      // as long fine streaks along the flow (the 9+ samples a pixel resolve their thin side)
      float gf;vec4 fg=mbFigure(hit?tl:p,sqrt(jn*sqrt(abs(determinant(J))+1e-12)),float(C0)*.173+float(pal0)*.61,gf);
      float st=wg*.72,ly=dot(i0,vec3(.3,.59,.11)),dk=1.-smoothstep(.04,.26,ly),br=1.-dk;
      float hi=uB2.z+uB2.w+uO2.z+uO2.w,bl=mix(uB1.w+.4*uB1.z+.5*uB2.x+uO2.x,hi,fg.w);       // big stones ride the mids, fine ones the highs
      // tone on tone: a deep shade of the ink itself (darker and more saturated, never greyer), so a figured ink still reads
      // as one colour from across the room
      vec3 nc=c0/max(max(c0.r,max(c0.g,c0.b)),1e-3),deep=c0*mix(vec3(.6),nc,.75)*.8;
      c0=mix(c0,deep,st*br*clamp(max(1.-fg.x,0.)*1.7,0.,1.));
      c0*=mix(1.,max(fg.x,1.),st)*(1.+st*.85*max(fg.x-1.,0.)*bl);
      c0*=1.-st*br*.46*fg.z;
      c0=mix(c0,isib*(.8+.5*min(fg.x,1.3))*(1.+.25*hi),st*mix(.68,.055,dk)*fg.y);
      {float sl=dot(isib,vec3(.3,.59,.11));c0+=isib*min(max(1.,.2/max(sl,1e-3)),6.)*st*dk*fg.z*(.26+.7*bl);}   // (a dark sibling ink is lifted to a visible lace, hue kept)
#if HD>=3
      c0=mix(c0,gold*(1.1+1.4*(uB2.w+uO2.w+uO2.z))+vec3(.3,.26,.1)*(uO2.w+uO2.z),gf*st);
#endif
    }
  }
#endif
  float cov=.5*(1.-smoothstep(0.,1.,bestE));
  vec3 col=mix(c0,i1*mix(1.,.95,lodR),cov);
  col=mix(.5*(c0+i1),col,lodR);                    // rings squeezed below a pixel melt into their mix
  // veins: hairlines along every ink edge (none, sumi dark, gold, pearl); the mids and the lead light them
  float vn=(1.-smoothstep(.25,1.15,bestE))*smoothstep(1.5,6.,wpx),lt=.6*uB1.w+.5*uB2.x+1.2*uO2.y;
  if(sty==1)col=mix(col,col*.18,vn*.8);
  else if(sty==2)col=mix(col,gold*(1.3+.8*build+uDrop+lt),vn*.9);
  else if(sty==3)col=mix(col,vec3(1.25,1.22,1.15)*(1.+.4*lt),vn*.7);
  col+=(gold*.35)*(1.-smoothstep(0.,3.,bestE))*(.25*build+.5*uDrop+.4*lt);
  col+=vec3(1.,.93,.8)*vn*(.32*(uB2.z+uB2.w)+.3*(uO2.z+uO2.w));  // the highs run along the hairlines between inks
  // ---- purfling: an inlaid hairline that follows every ink edge at a fixed distance on the sheet (dark in a bright ink,
  // luminous in a dark one); it fades out before it would crowd the edge or the far side of a narrow band. Every tier.
  {float d0=.0062/px,pf=(1.-smoothstep(.45,1.15,abs(bestE-d0)))*smoothstep(2.6,4.,d0)*smoothstep(d0*2.6,d0*4.,wpx)*lodR;
   float ly=dot(i0,vec3(.3,.59,.11)),dk=1.-smoothstep(.04,.26,ly);
   float hq=uB2.z+uB2.w+1.5*(uO2.z+uO2.w);                        // (the highs run along the inlay too: the dark line turns to light on a hat)
   col=mix(col*(1.-.42*pf*(1.-dk)*(1.-min(hq*.5,1.)))+vec3(1.,.95,.84)*pf*(1.-dk)*min(.2*hq,.5),col+i1*(.3+.5*(uB2.x+uO2.y)+.3*hq),pf*dk*.8);}
#if HD>=1
  // ---- the wet ink stands up from the bath: each edge is a meniscus catching the studio light from the top left
  {float bev=exp(-bestE/(1.1+.25*float(HD))),nd=dot(eDir,vec2(-.58,.81))*lodR;
   col*=1.+(.3+.05*float(HD))*nd*bev;
   col+=vec3(1.,.97,.92)*(.1+.05*float(HD))*max(nd,0.)*max(nd,0.)*exp(-(bestE-.8)*(bestE-.8)/.8)*(1.+uB2.z+uO2.z);}
#endif
  // hat spatter on top
  col=mix(col,mix(sK,sR*(spR==6?1.6:1.3),spM),spA);
  res=wpx;old=float(C0>>3);
  return col;
}
void realm(){
  vec2 s0=scr();
  float zm=uZoom*.86*clamp(mod(uP2.w,4096.)/4095.,.2,1.);   // default framing a little further back
  // ---- the camera (v21). It hangs over the bath at height 1/zm and looks straight down at the live print. For a walk through
  // the gallery it leans forward (pitch), turns its head (yaw) and travels over the endless floor of prints: one physical
  // camera, every value a critically damped spring in JS. The op list keeps all its 28 words; the camera rides in the two
  // spare components of the visit's seed vector (this shader never used uSeed; frame() rewrites them every frame) and in
  // bits that were free:  uSeed.z = q12(pitch) + 4096 * q12(yaw)   uSeed.w = q17(y) + 2^17 * (rows travelled / 2) + 2^22 * twin row code
  //   uM2[2].z: + 8192 * q11(x, finer near zero)   uP1.x: + 2^18 * (rows slid 0..15 + 16 * re-pour count)   uP1.w, uP2.x: + 2^20 * a nibble each of the slide's fraction
  // With pitch, yaw, x, y all zero this is exactly the old flat view (p = s0 / zm, the same pixel footprint).
  int c26=int(uSeed.z),c27=int(uSeed.w),c25=int(floor(uP1.x/262144.));
  float cth=float(c26&4095)/4095.*1.2,cya=float(c26>>12)/4096.*1.6-.8,snT=sin(cth),csT=cos(cth);
  // rows that would fall under about three pixels are not allowed to: there the floor curls up toward the lens (a smooth
  // lower bound on the ray's slope), so the far gallery never turns to speckle at any zoom or resolution
  float Dn=csT-s0.y*snT,Dm=min(sqrt(1.6/(zm*uRes.y)),.7),De=Dn-Dm,Dr=sqrt(De*De+.2*Dm*Dm*snT*snT),Dc=Dn+.5*(Dr-De),Dw=.5+.5*De/Dr;
  float px=1./(uRes.y*zm*Dc),nv=s0.y*csT+snT;
  mat2 cR=rot(cya);
  float lwf=uM2[2].z,cxq=floor(lwf/8192.)/1024.-1.;
  vec2 cpos=vec2(3.*cxq*abs(cxq),float(c27&131071)/131072.*32.-24.),p=cR*(vec2(s0.x,nv)/(zm*Dc))+cpos;
  // the pixel's footprint on the floor (sheet units per pixel, a 2x2 matrix: far rows are squeezed in depth only)
  mat2 J0=cR*mat2(px,0.,s0.x*snT*Dw/Dc*px,(csT*Dc+nv*snT*Dw)/Dc*px);
  px=max(px,length(J0[1]));
  float build=mod(floor(uP2.x/4096.),256.)/255.;
  const vec2 SH=vec2(1.42,.88),PP=2.*SH+.13;
  // ---- a print is pulled (uM2[2].z = q48(beats since the pull began) + 1024*hinge side + 4096*flooded):
  // the sheet glows as it rises and leaves a pale ghost of the print on the bath
  float lw=mod(lwf,8192.),la=mod(lw,1024.)/48.,lsd=mod(floor(lw/1024.),4.),gsl=floor(lw/4096.);
  float pghost=0.;
  if(lw>0.){
    pghost=clamp((la-.4)/1.2,0.,1.)*(1.-clamp((la-9.5)/1.5,0.,1.));
    pghost=pghost*pghost*(3.-2.*pghost);            // (eased, so it never switches on as a step)
  }
  // ---- where am I: the live sheet, a gallery print (some cells hold 2x2 smaller prints, some of those 2x2 again),
  // or the dark bath between them. Rows are laid like bricks; the odd rows slide along the wall, a whole print at a step,
  // on the snares of a build and on drops. The gallery is endless: after a flight the camera settles on the live print's
  // twin a few rows on (same bath, drawn twice while both can be seen), and the row count carries on from there.
  float ry=floor(p.y/PP.y+.5),sx=mod(ry,2.)*(.5+float(c25&15)+(floor(uP1.w/1048576.)*16.+floor(uP2.x/1048576.))/256.)*PP.x,rx=floor((p.x-sx)/PP.x+.5);
  vec2 q=p-vec2(rx*PP.x+sx,ry*PP.y);
  bool gal=rx!=0.||(ry!=0.&&ry!=float((c27>>22)*2+6)-6.*step(float(c27>>22),.5));
  int sd=0;float lpx=px,band=0.,wvf=0.;
  if(gal){
    // a drop re-pours the whole gallery: a front runs out from under the camera (as the drop's own envelope falls away)
    // and every print it passes becomes another
    float wr=uDrop>.004?48.*(1.-uDrop):1e3,wd=length(vec2(rx*PP.x+sx,ry*PP.y)-cpos);
    wvf=exp(-abs(wd-wr)*.7)*min(uDrop*3.,1.);
    uint hc=mbH(uint(rx+512.)*73856093u^uint(ry+float(((c27>>17)&31)*2)+512.)*19349663u^uint(((c25>>4)+(wd>wr?3:0))&3)*2654435761u);sd=int(hc&0xffffu);
    band=mod(rx+3.,8.);
    bool sp=true;
    for(int l=0;l<MBGL;l++){
      sp=sp&&((hc>>(17+l*3))%3u)==0u&&lpx<.11;   // (a print is only cut into four where the four are still some eight pixels tall: far rows keep whole prints)
      if(sp){vec2 s=step(0.,q);q=(q-(s-.5)*(SH+.065))*2.;lpx*=2.;sd=sd*4+int(s.x+2.*s.y)+1;}
    }
  }
  mbJ=J0*(lpx/px);
  float dB=max(abs(q.x)-SH.x,abs(q.y)-SH.y)+.006*(mbVn(q*23.)-.5);    // deckled sheet edge
  // (edge width in pixels along the edge's own normal: under the tilt a far edge is many times softer in depth than across)
  float lE=length((abs(q.x)-SH.x>abs(q.y)-SH.y?vec2(1.,0.):vec2(0.,1.))*mbJ);
  float shm=smoothstep(.5,-.5,dB/lE),dB0=dB;
  vec2 qF=q;float pxF=lE;                          // (the print's own frame, before a collage lays torn prints over it)
  vec3 col=vec3(0);
  // ---- collage: torn prints laid over the live one (amount and seed from JS)
  float cAmt=mod(uP1.w,256.)/255.,tear=0.,tsh=0.;
  if(!gal&&cAmt>0.&&dB<.05){
    float cs=mod(floor(uP1.w/256.),4096.);
    for(int k=0;k<3;k++){
      float hk=h11(cs*.37+float(k)*.71),am=clamp(cAmt*1.7-float(k)*.35,0.,1.);
      if(am>0.){                                 // (am falls with k: no break needed)
        vec2 nk=vec2(cos(hk*TAU),sin(hk*TAU));
        float o=mix(2.,.12+.38*h11(hk*9.1)+.03*sin(uTime*.4+hk*9.),am*am*(3.-2.*am)),al=dot(p,vec2(-nk.y,nk.x));
        float d=dot(p,nk)-o+dot(vec2(.035,.012),mbVn2(vec2(al*9.,hk*50.),vec2(al*41.,hk*20.))-.5);
        if(d>0.){
          float zs=1.1+.5*h11(hk*3.3);
          gal=true;sd=int(cs)*7+k+1;tear=1.-smoothstep(.006,.013+px,d);tsh=0.;
          q=rot(hk*4.)*(p-nk*o)*zs;lpx=px*zs;mbJ=rot(hk*4.)*J0*zs;band=float(k*3);
        }else tsh=max(tsh,smoothstep(-.06,0.,d)*am);
      }
    }
  }
  float b=band,lv,on;
  if(gal){
    int bi=clamp(int(b+.5),0,7);vec4 e1=vec4(equal(ivec4(bi),ivec4(0,1,2,3))),e2=vec4(equal(ivec4(bi),ivec4(4,5,6,7)));
    lv=dot(uB1,e1)+dot(uB2,e2);on=dot(uO1,e1)+dot(uO2,e2);
  }else{lv=uB1.y;on=uO1.x;}
  // ---- ink drops landing in the live bath send ripples across the surface (refraction and crest light)
  // (only the ripples, which bend the view of the print, are traced before the sampling; the falling bead, its
  // shadow and the crown are drawn after it, from the same unrippled point q0)
  vec2 rq=vec2(0),q0=q;float crest=0.;
  if(!gal){
    for(int k=0;k<2;k++){
      int iw=int(k==0?uP2.z:uM2[2].y);
      float ag=float((iw>>11)&255)/48.-.5,sz=float(iw>>22);
      if(iw>0&&ag>=0.&&ag<=3.){                  // (no continue: early exits are costly for the D3D compiler)
        vec2 c=vec2((float(iw&63)/63.*2.-1.)*1.3,(float((iw>>6)&31)/31.*2.-1.)*.8),v=q-c;float d=length(v);
        // ripples: three crests expanding from the landing point, fading over three beats
        float A=.0055*exp(-ag*1.3)*(.6+.25*sz);
        for(int i=0;i<3;i++){
          float ri=.03+.36*ag-.055*float(i),x=(d-ri)/.014,g=exp(-x*x)*(1.-.28*float(i));
          rq+=v/max(d,1e-5)*A*x*g;crest+=g*A*90.*smoothstep(-.02,.02,ri);
        }
      }
    }
    q+=rq;
  }
  float t1=0.,oldA=0.;
  if(shm>0.){
    {
      // one sample at the pixel centre; where rings are squeezed below ~1.6 px (fine feathering) or at higher detail,
      // a rotated-grid set of extra samples resolves the sub-pixel veining instead of letting it speckle
      int ns=1,sb=MBSN+int(min(uTime,0.));
      for(int s=0;s<MBSN;s++){
        if(s>=ns||s>=sb)break;
        
#if HD>=1
        vec2 o=s<9?MBSS[s]:(fract(vec2(.5)+float(s)*vec2(.7548777,.5698403))-.5)*.9;
#else
        vec2 o=MBSS[s];
#endif
        float res,old;
        col+=mbSample(q+mbJ*o,lpx,gal,sd,build,res,old);oldA+=step(gsl-.5,old);
#if HD>=1
        if(s==0)ns=(res<(gal?1.1:1.6)||uDetail>1.5)?min(MBSN,int(uDetail*4.)+1):1;
#else
        if(s==0)ns=(res<(gal?1.1:1.6)||uDetail>1.5)?(uDetail>3.?9:(gal&&lpx>.006?3:5)):1;
#endif
      }
      col/=float(ns);oldA/=float(ns);
      {float l=dot(col,vec3(.299,.587,.114));col=max(l+(col-l)*1.1,0.);}
    }
    // paper: tooth and laid fibres in sheet coordinates, each scale fading in only once it is wider than a pixel
    if(lpx<.0024){
    // (the four noises in one vectorised call: tooth, two layers of laid fibres, fine tooth)
    vec2 f0=rot(.9)*q*vec2(30.,560.),f1=rot(.9+1.9)*q*vec2(30.,560.)+17.;
    vec4 nz=mbVn4(vec4(q.x*260.,f0.x,f1.x,q.x*1100.),vec4(q.y*260.,f0.y,f1.y,q.y*1100.));
    t1=nz.x*(1.-smoothstep(.2,.6,260.*lpx));
    float fb=(smoothstep(.58,.82,nz.y)+smoothstep(.58,.82,nz.z))*(1.-smoothstep(.15,.5,560.*lpx));
    col*=.97+.06*t1-.09*fb+.05*(1.-smoothstep(.1,.4,1100.*lpx))*(nz.w-.5);
    }else col*=.97;
    // the gallery wall plays the spectrum: each column of prints is lit by its own band (bass left, air right)
    if(gal)col*=.78+.4*lv+.25*on;
    if(tear>0.)col=mix(col,vec3(.93,.9,.84)*(.9+.12*mbVn(q*180.)),tear);   // torn edge: the white paper core
    if(pghost>0.&&!gal){                          // what the pulled sheet left behind: a pale ghost of the print
      float g=pghost*oldA;
      col=mix(col,.55*col+vec3(.5,.48,.45)*(.9+.2*t1),g*.55);
    }
    // ---- the maker's chop, as on any sheet that leaves a marbler's workshop: a small vermilion seal in the corner of some
    // prints (too small to read until the print is seen large), and a larger one pressed onto a sheet as it is pulled
    {float hk=h11(mod(uP2.x,4096.)*.0137+lsd*.31+.2),cA=0.,cC=.0022,cV=0.,cM=0.;vec2 cO=vec2(SH.x-.105,.05-SH.y);
     if(gal){cA=step(.9,fract(float(sd)*.6180339));cM=step(.5,fract(float(sd)*.377));}
     else if(pghost>0.){cA=smoothstep(1.3,1.5,la)*(1.-smoothstep(4.2,4.8,la));cC=.003*(1.+.25*(1.-smoothstep(1.3,1.6,la)));
       cO=vec2((hk<.5?-1.:1.)*(.35+.75*fract(hk*7.3)),(fract(hk*3.1)<.5?-1.:1.)*(.2+.5*fract(hk*5.7)));cV=step(.6,fract(hk*11.3));cM=step(.5,fract(hk*13.7));}
     else cA=step(.72,fract(mod(uP2.x,16.)*.6180339));
     if(cA>0.){
       vec2 cp=q-cO;if(cV>.5)cp=vec2(cp.y,-cp.x);cp=cp/cC+vec2(33.,3.5);
       float cw=cC/lpx,bd=max(abs(cp.x-33.)-37.5,abs(cp.y-3.5)-6.5),bk=smoothstep(.5,-.5,bd*cw)*smoothstep(1.,2.5,13.*cw);
       col=mix(col,mix(vec3(.92,.07,.025),vec3(1.12,1.03,.86),max(mbChop(cp,cM)*smoothstep(.6,1.3,cw),smoothstep(-1.5,-1.,bd))),bk*cA);   // (a paper margin, so the seal reads on any ink)
     }}
  }
  col*=1.-.55*tsh;
  // the bath between the sheets: deep water, sheet shadows, slow rings spreading from the live sheet
  {
    float rr=length(p/vec2(1.6,1.)),rg=.5+.5*sin(rr*7.-uTime*1.2-6.*uB1.x);
    vec3 bath=vec3(.006,.008,.014)*(1.+.8*rg*smoothstep(.5,3.,rr))*(1.+.7*uB1.y);
    bath*=.35+.65*smoothstep(0.,.12,dB0-.02);
    col=mix(bath,col,shm);
    // a hairline of light along each print's edge when zoomed out, flashing with its band
    float rim=exp(-abs(dB0)/(1.5*lpx))*(1.-.7*shm)*smoothstep(.8,.5,zm/.86);
    col+=rim*vec3(1.,.86,.62)*(.04+.35*on);
    // every print is mounted with a gilded fillet in the gutter: a rule, a row of pearls, a finer rule; each fades out
    // before it would fall under a pixel, and the whole mount flashes with the print's own band
    {vec2 a=abs(qF)-SH;float d=max(a.x,a.y),al=a.x>a.y?qF.y:qF.x;
     float v1=smoothstep(.35,1.,.0036/pxF),v2=smoothstep(.9,2.2,.011/pxF);
     float r1=(1.-smoothstep(.0018,.0018+pxF,abs(d-.017)))*v1,r2=(1.-smoothstep(.0011,.0011+pxF,abs(d-.05)))*v2;
     vec2 bv=vec2((fract(al/.03)-.5)*.03,d-.034);float bl=length(bv),pe=(1.-smoothstep(-.5,.5,(bl-.0062)/pxF))*v2;
     float sh=.55+.75*clamp(dot(bv,vec2(-.58,.81))/.0062,-1.,1.)*.5+.6*smoothstep(.0035,.0005,length(bv-vec2(-.0019,.0026)));
     col+=vec3(1.,.8,.4)*(r1*.5+r2*.36+pe*.62*sh)*(.4+.45*lv+.9*on+1.4*wvf)*(1.-shm)*step(0.,d);}   // (the re-pour front lights every mount it passes)
  }
  if(!gal){                                      // the falling drops and the crown over the bath, ripple crests
    col+=vec3(1.,.97,.9)*crest*.5*(.6+.4*uB1.y);
    for(int k=0;k<2;k++){
      // ink drops falling into the live bath: the bead falls (it shrinks toward its landing point while its shadow
      // closes in), lands and throws a crown of droplets
      float aS=0.,aA=0.,aH=0.;
      int iw=int(k==0?uP2.z:uM2[2].y);
      float ag=float((iw>>11)&255)/48.-.5,sz=float(iw>>22);
      if(iw>0&&ag>=-.3&&ag<.5){
        vec2 c=vec2((float(iw&63)/63.*2.-1.)*1.3,(float((iw>>6)&31)/31.*2.-1.)*.8),v=q0-c;
        float Rl=.022+.009*sz;
        if(ag<0.){
          float h=min(-ag/.25,1.),rb=Rl*(1.+1.6*h);vec2 bc=c*(1.+.3*h);
          float ds=length(q0-c-vec2(.07,-.09)*h)-Rl*(1.+.4*h);
          aS=.55*(1.-.5*h)*smoothstep(.006+.03*h,-.004,ds);
          float db=length(q0-bc)/rb;
          aA=smoothstep(1.,1.-1.5*px/rb,db);
          aH=sqrt(max(1.-db*db,0.));
        }else{
          // the crown: droplets thrown out of the landing point that fall back within half a beat
          float th=atan(v.y,v.x),ci=floor(th/TAU*11.+.5),hh=h11(ci*7.1+sz+float(iw&2047)*.013),ta=ci*TAU/11.+.25*(hh-.5);
          float rr=Rl*1.2+(.07+.06*hh)*sin(min(ag/.5,1.)*PI*.5)*(1.+sz*.3),rd=Rl*.28*(1.-ag/.5)*(.6+.6*hh);
          float dc=length(v-rr*vec2(cos(ta),sin(ta)))/max(rd,1e-5);
          aA=smoothstep(1.,1.-1.5*px/max(rd,1e-5),dc);aH=sqrt(max(1.-dc*dc,0.));
        }
      }
      col*=1.-aS;
      // the drop's ink (live palette; black off the sheet, as before)
      vec3 ik=shm>0.?mbInk((iw>>19)&7,(int(mod(uP2.x,4096.)+.5)&15)%14,0):vec3(0);
      col=mix(col,ik*(.3+.8*aH)+vec3(.9)*pow(aH,14.),aA);
    }
  }
  // ---- the bass lifts the print from underneath: only inks with headroom take the light, so nothing washes out
  {float lum=dot(col,vec3(.299,.587,.114));col*=1.+(.05+.32*(uB1.y*.55+uB1.x*.45))*(1.-smoothstep(.35,1.,lum));}
  vec2 sp=s0;
  col*=1.-.2*smoothstep(.4,1.2,length(sp*vec2(.85,1.15)));
  float ha=.22*sin(TAU*uHue);vec3 kx=vec3(.57735);
  col=col*cos(ha)+cross(kx,col)*sin(ha)+kx*dot(kx,col)*(1.-cos(ha));
  fragColor=vec4(max(col,0.),0.);
}
`;
