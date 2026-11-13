const R_MERC = `
// BOOMB0X: a superflat kawaii sound system. A wall of ink-outlined characters that ARE the hi-fi: speaker cabinets
// with faces on their dust caps, cassettes whose reels are eyes, spinning records with smiling labels, boomboxes with
// googly speaker eyes and a live spectrum display, VU amps whose needles and knobs swing with their band, and hopping
// music notes. Every object plays one frequency band (the wall is a spectrum: bass on the left, air on the right, or
// bass at the bottom / inner rings / spokes in the other formations).
// Formations: WALL (column pairs step up / down on the beat, some pillars hold still), PARADE (rows step left /
// right), RINGS (counter-rotating rings of characters round a giant woofer face), TUNNEL (log-polar: an endless
// conformal tunnel of characters flowing out of the vanishing point). Sizes nest 2x2 / 1 / 1/2 / 1/4 cells.
// The tile backgrounds form a giant mosaic picture (stadium cards): a giant smiling face, a bullseye, a heart or a
// sunburst, which reads as one enormous composition when zoomed out.
// uP1 [beat clock, extra scroll, kick env, snare colour wave csN*4+ramp]   uP2/uP3 smoothed bands 0..7
// uP4 [comp A fam+vs, comp B fam+vs, wipe progress + 4*wipe type, sing + 2*floor(snare hop*64) + 256*floor(hat*64)]
// uP5 [build + 2*floor(kick age*240), breakdown + 2*floor(snare age*120), drop flash + 2*floor(groove clock*2048), event+prog]
// uM1, uM2: six palette colours (linear)
const vec3 BXK=vec3(.018,.008,.04);
#define BMSING mod(uP4.w,2.)
#define BMSN (mod(floor(uP4.w*.5),128.)/64.)
#define BMHAT (floor(uP4.w/256.)/64.)
#define BMGRV (floor(uP5.z*.5)/2048.)
#define BMSNA (floor(uP5.y*.5)/120.)
vec3 bxC(float i){float k=floor(i+.5);k-=6.*floor(k/6.);
  return uM1*clamp(1.-abs(k-vec3(0.,1.,2.)),0.,1.)+uM2*clamp(1.-abs(k-vec3(3.,4.,5.)),0.,1.);}
float bxA(float d,float e){return clamp(.5-.5*d/max(e,1e-5),0.,1.);}
vec4 bxH(vec2 p,float L){vec4 q=fract(vec4(p.xyxy+L*vec4(.13,.71,.37,.53))*vec4(.1031,.1030,.0973,.1099));
  q+=dot(q,q.wzxy+33.33);return fract((q.xxyz+q.yzzw)*q.zywx);}
float bxBox(vec2 p,vec2 b,float r){vec2 q=abs(p)-b+r;return length(max(q,0.))+min(max(q.x,q.y),0.)-r;}
float bxSeg(vec2 p,vec2 a,vec2 b){vec2 pa=p-a,ba=b-a;return length(pa-ba*clamp(dot(pa,ba)/max(dot(ba,ba),1e-6),0.,1.));}
float bxBand(float b){return dot(uP2,step(abs(vec4(b)-vec4(0.,1.,2.,3.)),vec4(.5)))+dot(uP3,step(abs(vec4(b)-vec4(4.,5.,6.,7.)),vec4(.5)));}
float bxOn(float b){return dot(uO1,step(abs(vec4(b)-vec4(0.,1.,2.,3.)),vec4(.5)))+dot(uO2,step(abs(vec4(b)-vec4(4.,5.,6.,7.)),vec4(.5)));}
// ink outline (outside the fill, width lw) then the fill
vec3 bxL(vec3 c,float d,vec3 f,float lw,float pf,float ik){c=mix(c,BXK,bxA(d-lw,pf)*ik);return mix(c,f,bxA(d,pf));}
// stepped beat motion: one step per beat, eased with continuous velocity; the Motion smoothness dial blends toward a
// constant glide
float bxEase(float t,float sm){float f=fract(t),x=clamp(f/.72,0.,1.),e=x*x*x*(x*(x*6.-15.)+10.);return mix(floor(t)+e,t,sm);}
// mouth in face units (origin at the mouth): a closed smile, or a round singing "o" with a tongue
vec3 bxMouth(vec3 col,vec2 m,float pf,float mo,float lw,float lod){
  float om=smoothstep(.08,.24,mo),rx=.12+.08*mo,ry=.03+.24*mo,dm=(length(m/vec2(rx,ry))-1.)*min(rx,ry);
  col=mix(col,mix(vec3(.55,.02,.09),vec3(1.9,.42,.6),bxA(length(m-vec2(0.,-ry*.8))-ry*.6,pf)),bxA(dm,pf)*om*lod);
  float ds=max(abs(length(m-vec2(0.,.17))-.22)-lw*.5,m.y-.07);
  return mix(col,BXK,bxA(mix(ds,abs(dm)-lw*.5,om),pf)*lod);
}
// kawaii face in face units (radius ~1): glossy eyes looking around (or happy ^^ arcs), cheeks, mouth
vec3 bxFace(vec3 col,vec2 f,float pf,float mo,float bl,float md,float lod,float sd,float ey){
  lod*=1.-smoothstep(.05,.11,pf);
  if(lod<=0.)return col;
  float lw=max(.07,1.1*pf);
  if(ey>.5){
  col=mix(col,mix(col,vec3(2.1,.5,.75),.55),bxA((length(vec2(abs(f.x)-.6,f.y+.2)/vec2(.19,.12))-1.)*.12,pf)*lod);
  vec2 lk=.05*vec2(sin(uTime*.83+sd*9.),cos(uTime*.61+sd*7.));
  vec2 e=vec2(abs(f.x)-.36,f.y-.1);float op=max(1.-bl,.08);
  float dO=(length((e-lk)/vec2(.14,.2*op))-1.)*.14*op;
  vec2 ea=e+vec2(0.,.05);float dH=max(abs(length(ea)-.13)-lw*.5,-ea.y);
  col=mix(col,BXK,bxA(mix(dO,dH,md),pf)*lod);
  col=mix(col,vec3(1.9),bxA(length(e-lk*1.6-vec2(.045,.075))-.052,pf)*(1.-md)*step(.5,op)*lod);
  }
  return bxMouth(col,f-vec2(0.,-.33),pf,mo,lw,lod);
}
// tile background patterns (stripes, dots, rings, rays, checker), faded to their mean colour below the pixel footprint
vec3 bxTile(vec2 q,float pf,float k,vec3 a,vec3 b){
  float d,fq;
  if(k<1.){fq=5.;d=(abs(fract((q.x+q.y)*fq)-.5)-.2)/fq;}
  else if(k<2.){fq=5.;vec2 g=fract(q*fq)-.5;d=(length(g)-.2)/fq;}
  else if(k<3.){fq=6.;d=(abs(fract(length(q)*fq)-.5)-.2)/fq;}
  else if(k<4.){fq=8.;float an=atan(q.y,q.x);d=(abs(fract(an/TAU*12.)-.5)-.2)*length(q)*TAU/12.;}
  else{fq=4.;vec2 g=fract(q*fq)-.5;d=min(abs(g.x),abs(g.y))*sign(g.x*g.y)/fq;}
  float w=1.-smoothstep(.15,.4,pf*fq);
  // (v13/v14) pop-art Ben-Day dots printed over every pattern, revealed as you zoom in; fewer and fatter than v13 so
  // they read at 960 px as well as 1080p
  vec2 bd=fract(mat2(.7071,.7071,-.7071,.7071)*q*12.)-.5;float dw=1.-smoothstep(.1,.22,pf*12.);
  return mix(mix(a,b,.3),mix(a,b,bxA(d,pf)),w)*(1.-.34*dw*bxA(length(bd)-.25,pf*12.));
}
// v19 detail range (HD>=1 only). All of it costs the phone tiers nothing. Every term fades out before its period reaches a pixel.
#define BM0 min(int(uTime),0)
#if HD>=5
#define BMSS 4.
#elif HD==4
#define BMSS 3.
#elif HD==3
#define BMSS 2.
#elif HD==2
#define BMSS 1.5
#else
#define BMSS 1.
#endif
float bxFade(float pf,float per){return 1.-smoothstep(.22,.5,pf/max(per,1e-5));}
float bxDots(vec2 q,float fq,float r,float pf){vec2 g=vec2(1.,1.732),a=mod(q*fq,g)-.5*g,b=mod(q*fq+.5*g,g)-.5*g;
  return bxA((sqrt(min(dot(a,a),dot(b,b)))-r)/fq,pf)*bxFade(pf,1./fq);}
float bxPrint(vec2 q,float rows,float pf,float sd){float w=bxFade(pf,1./rows);if(w<=0.)return 0.;float y=q.y*rows,r=floor(y),sx=q.x*rows*.9+sd*9.+r*3.3,
  sg=step(.32,fract(sx*.7+.3*fract(r*.37)))*step(.18,fract(sx*2.3+r));return w*sg*bxA((abs(fract(y)-.5)-.17)/rows,pf);}
// the characters. q: object units (cell = [-.5,.5]^2, up = +y), pf: pixel in q units, e: band envelope (smooth,
// geometry), on: band onset (light), c1 body, c2 accent, c3 detail, ik: ink weight (fades when far), rnd: round hero
vec3 bxObj(vec3 col,vec2 q,float ty,float pf,float e,float on,vec3 c1,vec3 c2,vec3 c3,float lod,float ik,float mo,
           float bl,float md,float sd,float tb,float rnd){
  float lw=max(.022,1.1*pf),l2=1.-smoothstep(.03,.07,pf);
  vec3 sh=col*mix(.4,.75,smoothstep(.03,.1,pf)),W=vec3(1.8,1.75,1.65)*(1.-.3*smoothstep(.015,.07,pf));vec2 so=vec2(.03,-.036),fq=vec2(9.);float fs=1.,ey=1.;
  float isS=step(ty,.5),isB=step(abs(ty-3.),.5);
  // ---- shared cabinet: drop shadow, ink-outlined body, bevel highlight (all but the notes)
  if(ty<4.5||ty>5.5){
    if(isB>.5){vec2 hq=q-vec2(0.,.255);col=bxL(col,max(abs(bxBox(hq,vec2(.27,.085),.075))-.026,-hq.y),c3,lw*.8,pf,ik);}
    vec3 bb=ty<.5?vec3(.36,.42,.07):(ty<1.5?vec3(.42,.28,.045):(ty<2.5?vec3(.42,.42,.03):(ty<3.5?vec3(.45,.26,.06):(ty<4.5?vec3(.4,.41,.05):(ty<6.5?vec3(.43,.34,.05):(ty<7.5?vec3(.4,.4,.06):vec3(.44,.28,.045)))))));
    vec2 bq=q-vec2(0.,-.06*isB);
    float db=mix(bxBox(bq,bb.xy,bb.z),length(q)-.46,rnd);
    col=mix(col,sh,bxA(mix(bxBox(bq-so,bb.xy,bb.z),length(q-so)-.46,rnd),pf));
    col=bxL(col,db,c1,lw,pf,ik);
    col=mix(col,c1*1.5,bxA(abs(db+.04)-lw*.35,pf)*l2*(isS+isB+step(5.5,ty)));
#if HD>=1
    // cabinet covering: pebbled vinyl, one octave per tier
    if(db<-lw&&isS+isB>.5){float wf=1.,fq=70.,t=0.,a=1.;for(int i=BM0;i<HD+1;i++){wf=bxFade(pf,6.283/fq);t+=a*wf*(sin(q.x*fq+1.3*float(i))*sin(q.y*fq*1.07));fq*=2.37;a*=.72;}
      col*=1.+.12*t*min(ik,1.);}
#endif
  }
  // ---- shared woofer: the speaker's (one, face on the dust cap) and the boombox's googly pair; pumps with the band,
  // the surround flashes on the band's onsets
  if(isS+isB>.5){
    vec2 wq=mix(q-vec2(0.,-.075*(1.-rnd)),vec2(abs(q.x)-.25,q.y+.1),isB);
    float ke=uP1.z,R=mix(mix(.25,.37,rnd),.13,isB)*(1.+.22*e+.26*ke),rw=length(wq),cr=R*.78;
    // the kick fires a shockwave ring out of every cone
    col=mix(col,c2*1.9+c1*.2,bxA(abs(rw-R*(1.15+1.1*(1.-ke)))-lw*.7,pf)*smoothstep(.05,.5,ke)*ke*ik);
    col=bxL(col,rw-R,mix(c2*.2,c2*2.4+.3,on),lw*mix(1.,.8,isB),pf,ik);
    col=bxL(col,rw-cr,c2,lw*.6,pf,ik);
    float rl=abs(fract(rw/cr*3.5)-.5)*cr/3.5;
    col=mix(col,c2*.6,bxA(rl-lw*.22,pf)*l2*step(rw,cr-lw)*step(cr*.6,rw));
    col=mix(col,c2*1.45+.08,bxA(length(wq-vec2(-.42,.42)*cr)-cr*.26,pf)*.55*l2*step(rw,cr)*isS);
    float cap=cr*mix(.52,.6,isB)*(1.+.2*ke);
    col=bxL(col,rw-cap,mix(c3,W,isB),lw*.6,pf,ik);
    vec2 lk=isB*.42*cap*vec2(sin(uTime*.9+sd*6.),.6*cos(uTime*.7+sd*5.));
    col=mix(col,BXK,bxA(length(wq-lk)-cap*.52,pf)*isB);
    col=mix(col,mix(c3*1.4+.1,vec3(1.9),isB),bxA(length(wq-lk-cap*mix(vec2(-.4,.45),vec2(.18,.2),isB))-cap*mix(.22,.15,isB),pf)*l2);
    fq=wq/cap;fs=cap;
    if(rw<R&&rw>cr)col=mix(col,BXK,bxDots(wq/R,26.,.24,pf/R)*.5*ik);
#if HD>=1
    if(isS>.5&&rnd<.5&&rw>R){float an=atan(wq.y,wq.x);vec2 bq2=vec2((fract(an/TAU*8.+.0625)-.5)*TAU/8.*rw,rw-R*1.1);
      float fb2=bxFade(pf,.035);col=mix(col,BXK,bxA(length(bq2)-.015,pf)*fb2);col=mix(col,c1*1.9+.1,bxA(length(bq2-vec2(-.003,.004))-.0075,pf)*fb2);
      col=mix(col,BXK,bxA(bxSeg(bq2,vec2(-.007,-.007),vec2(.007,.007))-.0015,pf)*bxFade(pf,.012));}
    if(rw<R&&rw>cr){float an=atan(wq.y,wq.x),sd2=abs(fract(an/TAU*36.)-.5)*TAU/36.*rw;
      col=mix(col,c2*1.6+.1,bxA(max(sd2-.0035,abs(rw-(R+cr)*.5)-.0016),pf)*bxFade(pf,rw*TAU/36.)*.8);}
#endif
    if(rw<cr&&rw>cap){float an=atan(wq.y,wq.x),pl=abs(fract(an/TAU*48.)-.5)*TAU/48.*rw;
      col=mix(col,c2*.45,bxA(pl-.0035,pf)*bxFade(pf,rw*TAU/48.)*.7*ik);
#if HD>=2
      pl=abs(fract(rw/cr*18.)-.5)/18.*cr;col=mix(col,c2*.7,bxA(pl-.0015,pf)*bxFade(pf,cr/18.)*.6*ik);
#endif
    }
  }
  if(ty<.5){
    // SPEAKER CABINET: tweeter (air) and corner screws
    if(rnd<.5){vec2 sq=abs(q)-vec2(.29,.355);col=mix(col,BXK,bxA(length(sq)-.02,pf)*l2);
    vec2 tq=q-vec2(0.,.29);float tr=.06*(1.+.35*bxBand(7.)+.9*BMHAT);
    vec2 sa=q-vec2(.29,.355)*vec2(sign(q.x+1e-4),sign(q.y+1e-4));col=mix(col,c1*2.,bxA(bxSeg(sa,vec2(-.012),vec2(.012))-.0025,pf)*bxFade(pf,.018));
    {vec2 lq=vec2(abs(q.x)-.2,q.y-.29);float li=clamp(floor(lq.x/.06+.5),-1.,1.);lq.x-=li*.06;
     float lon=smoothstep(0.,.1,e-(.2+.26*(li+1.))),dl=bxBox(lq,vec2(.017,.026),.007);
     col=mix(col,BXK,bxA(dl-lw*.4,pf)*ik*l2);col=mix(col,mix(c1*.28,mix(vec3(.3,1.9,.6),vec3(2.,.45,.2),(li+1.)*.5),lon),bxA(dl,pf)*l2);}
    col=bxL(col,length(tq)-tr,c3,lw*.8,pf,ik);
    col=mix(col,mix(BXK,c2*1.8+.15,max(bxOn(7.),BMHAT)),bxA(length(tq)-tr*.42,pf)*l2);}
  }else if(ty<1.5){
    // CASSETTE: the reels are its eyes and spin with the low mids, a mouth on the label
    vec2 lq=q-vec2(0.,.035);float dl=bxBox(lq,vec2(.355,.18),.03);
    col=bxL(col,dl,c2,lw*.6,pf,ik);
    col=mix(col,c3,bxA(max(dl,.1-lq.y),pf));
    col=mix(col,BXK,bxA(abs(lq.y-.1)-lw*.3,pf)*l2*step(dl,0.));
    if(dl<0.&&lq.y>.02&&lq.y<.09)col=mix(col,BXK*2.5,.8*bxPrint(lq*vec2(1.2,1.),34.,pf,sd));
    float dw=bxBox(q,vec2(.22,.075),.07);
    col=bxL(col,dw,c3*.15+vec3(.03,.02,.07),lw*.6,pf,ik);
    if(dw<0.)col*=1.-.4*bxA(abs(fract(q.y*26.)-.5)/26.-.012,pf)*bxFade(pf,1./26.);
    vec2 rq=vec2(abs(q.x)-.13,q.y);float rr=length(rq);
    float tpk=abs(fract(tb/96.+sd)*2.-1.);
    col=mix(col,vec3(.5,.22,.12)*(1.+c2*.3),bxA(rr-.06-.03*mix(tpk,1.-tpk,step(0.,q.x))-.008*e,pf)*step(dw,0.));
    {vec2 mb=vec2(lq.x+.3,lq.y-.142);float si=clamp(floor(mb.x/.06),0.,9.),dsg=bxBox(vec2(mb.x-(si+.5)*.06,mb.y),vec2(.021,.015),.004);
     col=mix(col,mix(BXK,mix(c2,vec3(2.,.4,.25),step(7.5,si))*1.5+.1,step(si+.5,e*10.5)),bxA(dsg,pf)*l2*step(dl,-.01));}
    col=bxL(col,rr-.058,W,lw*.5,pf,ik);
    float cx=(rot(-TAU*BMGRV*(1.+floor(fract(sd*5.3)*3.)))*vec2(rq.x*sign(q.x+1e-4),rq.y)).x/max(rr,1e-4),c2x=cx*cx;
    col=mix(col,BXK,bxA(abs(rr-.03)-.009+.008*smoothstep(.55,.95,((32.*c2x-48.)*c2x+18.)*c2x-1.),pf)*l2);
    vec2 bq=q-vec2(0.,-.235);
    col=bxL(col,bxBox(bq,vec2(.23,.045),.015),c1*.75,lw*.6,pf,ik);
    col=mix(col,BXK,bxA(min(length(vec2(abs(bq.x)-.11,bq.y)),length(abs(q)-vec2(.385,.245)))-.017,pf)*l2);
    fq=(q-vec2(0.,-.112))/.09+vec2(0.,-.33);fs=.09;ey=0.;
  }else if(ty<2.5){
    // RECORD on a striped sleeve: grooves, a sheen that turns a quarter per beat, a smiling label
    float st=(abs(fract((q.x-q.y)*4.)-.5)-.17)/4.;
    col=mix(col,c3,bxA(st,pf)*bxA(bxBox(q,vec2(.42,.42),.03)+lw,pf)*(1.-smoothstep(.1,.25,pf*4.)));
    float rr=length(q),dr=rr-.4;
    col=bxL(col,dr,vec3(.04,.028,.07)+c2*.07,lw,pf,ik);
    float gl=abs(fract(rr*44.)-.5)/44.;
    col=mix(col,c2*.3+.05,bxA(gl-.003,pf)*(1.-smoothstep(.2,.45,pf*44.))*step(.17,rr)*bxA(dr+.02,pf)*.75);
#if HD>=1
    if(rr>.165&&rr<.395){float bd=abs(fract((rr-.17)/.225*4.)-.5)/4.*.225;col=mix(col,c2*.1+.03,bxA(bd-.003,pf)*bxFade(pf,.01));
      float gq=110.;for(int i=BM0;i<HD;i++){float gw=abs(fract(rr*gq)-.5)/gq;col=mix(col,c2*(.22-.03*float(i))+.04+.2*spec(rr*2.-.34)*c2,bxA(gw-.0018/(1.+float(i)),pf)*(1.-smoothstep(.2,.45,pf*gq))*.55);gq*=2.5;}}
#endif
    float cx=(rot(-TAU*BMGRV*(1.+floor(fract(sd*3.1)*2.))+BMSN*sin(BMSN*14.)*1.4)*q).x/max(rr,1e-4),c2x=cx*cx,sn=c2x*c2x*c2x*c2x*c2x;
    col=mix(col,c2*1.2+.18,sn*.5*step(.165,rr)*bxA(dr+.012,pf));
    col=bxL(col,rr-.155,c2,lw*.6,pf,ik);
    col=mix(col,c3,bxA(abs(rr-.138)-.01,pf)*l2);
#if HD>=1
    if(rr<.125&&rr>.06){vec2 lr=rot(-TAU*BMGRV*(1.+floor(fract(sd*3.1)*2.)))*q;col=mix(col,BXK*2.,.75*bxPrint(vec2(atan(lr.y,lr.x)*.11,rr),30.,pf,sd));}
#endif
    if(l2>0.){float ta=mix(.06,.6,fract(tb/64.+sd))+.035*uP1.z;vec2 pv=vec2(.37,.37),tip=pv+.36*vec2(-sin(ta),-cos(ta));
      float da=bxSeg(q,pv,tip)-.013,dh=bxBox(rot(-ta)*(q-tip),vec2(.03,.045),.012),dp=length(q-pv)-.055;
      col=mix(col,sh,bxA(bxSeg(q-so*.6,pv,tip)-.013,pf)*l2*.7);
      col=mix(col,BXK,bxA(min(da,min(dh,dp))-lw*.5,pf)*ik*l2);
      col=mix(col,vec3(1.3,1.27,1.36),bxA(da,pf)*l2);col=mix(col,c3,bxA(min(dh,dp),pf)*l2);
      col=mix(col,BXK,bxA(length(q-pv)-.02,pf)*l2);}
    fq=q/.12;fs=.12;
  }else if(ty<3.5){
    // BOOMBOX: a live spectrum display, the tape door is its mouth
    vec2 dq=q-vec2(0.,.11);
    col=bxL(col,bxBox(dq,vec2(.27,.058),.02),vec3(.02,.03,.06)+c3*.08,lw*.6,pf,ik);
    float bi=clamp(floor((dq.x+.25)*24.),0.,11.),bx=(bi+.5)/12.,hb=.012+.085*clamp(spec(.03+bx*.9),0.,1.);
    float dbar=bxBox(vec2(dq.x+.25-(bi+.5)/24.,dq.y+.046-hb*.5),vec2(.013,hb*.5),.004);
    col=mix(col,mix(c2,c3,bx)*1.7+.1,bxA(dbar,pf)*l2*step(abs(dq.x),.255));
    if(abs(dq.x)<.265&&abs(dq.y)<.052)col=mix(col,BXK,bxA(abs(fract(dq.y*96.)-.5)/96.-.0014,pf)*bxFade(pf,1./96.)*.85);
    vec2 mq=q-vec2(0.,-.115);
    col=bxL(col,bxBox(mq,vec2(.07,.07),.02),c3,lw*.5,pf,ik);
#if HD>=1
    {vec2 hv=vec2(abs(q.x)-.27,q.y-.2);float fr2=bxFade(pf,.03);col=mix(col,BXK,bxA(length(hv)-.014,pf)*fr2);col=mix(col,c3*1.6+.1,bxA(length(hv)-.009,pf)*fr2);
     float ti=clamp(floor((q.x+.075)/.03),0.,4.);vec2 tk=vec2(q.x+.075-(ti+.5)*.03,q.y-.027);float dt2=bxBox(tk,vec2(.011,.012),.003),ft2=bxFade(pf,.03);
     col=mix(col,BXK,bxA(dt2-.003,pf)*ft2);col=mix(col,mix(c2,c1*1.6,step(1.5,ti))*1.2,bxA(dt2,pf)*ft2);
     col=mix(col,BXK,bxA(length(tk)-.0042,pf)*bxFade(pf,.01)*.8);}
#endif
    {vec2 kq=vec2(abs(q.x)-.045,q.y+.262);float kr=length(kq),ka=(-2.2+4.4*clamp(e,0.,1.))*sign(q.x+1e-4);
     col=mix(col,BXK,bxA(kr-.028-lw*.4,pf)*ik*l2);col=mix(col,c2,bxA(kr-.028,pf)*l2);
     col=mix(col,BXK,bxA(bxSeg(kq,vec2(0.),vec2(sin(ka),cos(ka))*.022)-.007,pf)*l2);}
    fq=mq/.075+vec2(0.,-.33);fs=.075;ey=0.;
  }else if(ty<4.5){
    // VU AMP: the needle swings with its band, knob eyes turn with it, a strip of band LEDs, a grin
    vec2 vq=q-vec2(0.,.15);float dv=bxBox(vq,vec2(.31,.16),.05);
    col=bxL(col,dv,mix(vec3(1.75,1.6,1.25),c3,.2),lw*.7,pf,ik);
    vec2 pv=q-vec2(0.,-.03);float ra=length(pv),aa=atan(pv.x,pv.y);
    float inA=step(abs(aa),.85)*step(dv,0.)*l2;
    vec3 tc=mix(BXK,vec3(2.,.12,.18),step(.42,aa));
    float tk=min(max(abs(fract(aa*5.625+.5)-.5)/5.625*ra-.006,abs(ra-.24)-.03),abs(ra-.215)-.005);
    col=mix(col,tc,bxA(tk,pf)*inA);
    {float ft=abs(fract(aa*22.5+.5)-.5)/22.5*ra;col=mix(col,tc,bxA(max(ft-.0025,abs(ra-.232)-.014),pf)*inA*bxFade(pf,ra/22.5));
     vec2 pq=q-vec2(0.,-.17);if(dv>0.&&abs(pq.x)<.3&&abs(pq.y)<.035)col=mix(col,BXK*1.8,.6*bxPrint(pq,30.,pf,sd));}
#if HD>=1
    {vec2 sv=abs(vq)-vec2(.275,.125);float fs2=bxFade(pf,.03);col=mix(col,BXK,bxA(length(sv)-.013,pf)*fs2);col=mix(col,vec3(1.5,1.45,1.3),bxA(length(sv)-.009,pf)*fs2);
     col=mix(col,BXK,bxA(bxSeg(sv,vec2(-.006,-.006),vec2(.006,.006))-.0015,pf)*bxFade(pf,.012));
     col=mix(col,col*1.25+.1,bxA(abs(vq.x+vq.y*.6+.12)-.012,pf)*step(dv,-.02)*bxFade(pf,.05)*.5);}
#endif
    float na=-.82+1.64*clamp(e,0.,1.);
    col=mix(col,vec3(.9,.05,.08),bxA(bxSeg(pv,vec2(0.),vec2(sin(na),cos(na))*.27)-.009,pf)*step(dv,0.));
    col=bxL(col,ra-.04,c2,lw*.5,pf,ik*step(dv,0.));
    float li=clamp(floor((q.x+.3)/.075),0.,7.);vec2 lq=vec2(q.x+.3-(li+.5)*.075,q.y+.085);
    col=bxL(col,length(lq)-.022,mix(c1*.35,mix(vec3(.25,2.,.7),vec3(2.3,.35,.25),li/7.)+.2,smoothstep(.15,.65,bxBand(li))),lw*.4,pf,ik*l2);
    vec2 kq=vec2(abs(q.x)-.2,q.y+.25);
    col=bxL(col,length(kq)-.075,c3,lw*.6,pf,ik);
    float ka=(-2.2+4.4*clamp(e,0.,1.))*sign(q.x+1e-4);
    {float kr=length(kq),kan=atan(kq.y,kq.x);if(kr<.075&&kr>.05){float rg=abs(fract(kan/TAU*30.)-.5)*TAU/30.*kr;col=mix(col,BXK,bxA(rg-.0018,pf)*bxFade(pf,kr*TAU/30.)*.7);}}
    col=mix(col,BXK,bxA(bxSeg(kq,vec2(0.),vec2(sin(ka),cos(ka))*.058)-.014,pf)*l2);
    fq=(q-vec2(0.,-.27))/.075+vec2(0.,-.33);fs=.075;ey=0.;
  }else if(ty<5.5){
    // MUSIC NOTES: a chubby eighth note (or a beamed pair) that hops with its band, a face on the note head
    q.y+=.04-.08*e;
    float two=step(.5,fract(sd*3.7)),sc=mix(1.,.82,two);
    vec2 h1=mix(vec2(-.09,-.17),vec2(-.19,-.2),two),h2=vec2(.15,-.135);
    vec2 hf=mix(h1,h2,two*step(length(q-h2),length(q-h1)));
    vec2 a1=rot(.4)*(q-hf);
    float x1=h1.x+.15*sc,x2=h2.x+.15*sc,sR=two*step(.5*(x1+x2),q.x);
    vec2 hs=mix(h1,h2,sR);float xs=mix(x1,x2,sR),ytop=.29+.04*sR;
    float dsm=bxBox(q-vec2(xs,(hs.y+ytop)*.5),vec2(.024,(ytop-hs.y)*.5),.02);
    float fl=mix(min(bxSeg(q,vec2(x1,.29),vec2(x1+.13,.13)),bxSeg(q,vec2(x1+.13,.13),vec2(x1+.1,.03)))-.032,bxSeg(q,vec2(x1,.27),vec2(x2,.31))-.045,two);
    float dn=min((length(a1/(vec2(.17,.125)*sc))-1.)*.125*sc,min(dsm,fl));
    col=mix(col,sh,bxA((length((rot(.4)*(q-so-hf))/(vec2(.17,.125)*sc))-1.)*.12,pf));
    col=bxL(col,dn,c2,lw,pf,ik);
    col=mix(col,c2*1.5+.1,bxA(length(a1-vec2(-.07,.06)*sc)-.03*sc,pf)*l2);
    fq=rot(.15)*(q-hf)/(.12*sc);fs=.12*sc;
  }else if(ty<6.5){
    // (v20b) MIXER: five faders ride their bands (bass on the left) over engraved scales, a clip lamp over each, a grin under the panel
    float fi=clamp(floor((q.x+.375)/.15),0.,4.),fx0=q.x+.375-(fi+.5)*.15,fbn=floor(fi*1.7+.5),fl=clamp(bxBand(fbn),0.,1.);
    vec2 sq=vec2(fx0,q.y-.08);
    col=mix(col,BXK,bxA(bxBox(sq,vec2(.009,.17),.007),pf)*l2);
    {float tk=abs(fract(sq.y*20.+.5)-.5)/20.;col=mix(col,c1*.3,bxA(max(tk-.004,max(abs(abs(sq.x)-.036)-.013,abs(sq.y)-.165)),pf)*bxFade(pf,.05));}
    float fy=-.15+.3*fl,dc=bxBox(vec2(sq.x,sq.y-fy),vec2(.047,.028),.01);
    col=mix(col,sh,bxA(bxBox(vec2(sq.x,sq.y-fy)-so*.5,vec2(.047,.028),.01),pf)*l2);
    col=bxL(col,dc,c2,lw*.6,pf,ik);col=mix(col,W,bxA(abs(sq.y-fy)-.005,pf)*step(dc,-.008)*l2);
    col=bxL(col,length(vec2(fx0,q.y-.295))-.02,mix(c1*.25,mix(vec3(.3,1.9,.6),vec3(2.,.45,.2),step(2.5,fi))+.1,smoothstep(.1,.5,max(max(bxOn(fbn),fl-.7),max(.9*uP1.z,BMHAT*step(2.5,fi))))),lw*.4,pf,ik*l2);
    fq=(q-vec2(0.,-.215))/.085+vec2(0.,-.33);fs=.085;ey=0.;
  }else if(ty<7.5){
    // (v20b) PAD SEQUENCER: sixteen pads; a step light runs through them in eighths of the beat, the programmed pads fire with their band
    vec2 g=clamp(floor((q+.34)/.17),0.,3.),pq=q+.34-(g+.5)*.17;float n=g.x+4.*(3.-g.y),pb=mod(g.y*2.+floor(sd),8.);
    float prog=step(.5,bxH(g+floor(sd*3.),23.).x),run=step(abs(n-mod(floor(tb*2.+sd*16.),16.)),.5),hit=max(prog*clamp(bxOn(pb)+smoothstep(.55,.9,bxBand(pb)),0.,1.),max(step(g.y,.5)*smoothstep(.25,.7,uP1.z),step(2.5,g.y)*step(.5,fract(n*.37+sd))*BMHAT)),dp=bxBox(pq,vec2(.067),.018);
    vec3 pc=mix(mix(mix(BXK+c3*.16,c3*.42,prog),mix(c3,c2,g.y/3.)*1.5+.1,hit),W,run);
    col=mix(col,sh,bxA(bxBox(pq-so*.4,vec2(.067),.018),pf)*l2);
    col=bxL(col,dp,pc,lw*.5,pf,ik);
    col=mix(col,pc*1.4+.06,bxA(abs(dp+.02)-.004,pf)*l2);
    col=mix(col,mix(BXK,vec3(2.,.4,.25),run),bxA(length(pq-vec2(.04,.04))-.009,pf)*bxFade(pf,.03));
  }else{
    // (v20b) SYNTH: eight keys pressed by the spectrum (a pressed key sinks and takes the accent colour), black keys between, a face on the panel
    float ki=clamp(floor((q.x+.4)/.1),0.,7.),kx=q.x+.4-(ki+.5)*.1,kp=smoothstep(.3,.6,spec(.04+ki*.11));
    vec2 kq=vec2(kx,q.y+.125+.014*kp);
    col=bxL(col,bxBox(kq,vec2(.044,.105),.012),mix(W,c2*1.35+.1,kp)*(1.-.35*uP1.z*step(ki,2.5))*(1.+.25*BMHAT*step(4.5,ki)),lw*.5,pf,ik);
    float bi=clamp(floor((q.x+.35)/.1),0.,6.),hasB=1.-step(abs(bi-2.),.5)-step(abs(bi-6.),.5);
    col=mix(col,BXK,bxA(bxBox(vec2(q.x+.35-(bi+.5)*.1,q.y+.07),vec2(.027,.062),.008),pf)*hasB*l2);
    {vec2 dq=vec2(abs(q.x)-.3,q.y-.14);float kr=length(dq),ka=(-2.2+4.4*clamp(e,0.,1.))*sign(q.x+1e-4);
     col=bxL(col,kr-.05,c3,lw*.5,pf,ik*l2);col=mix(col,BXK,bxA(bxSeg(dq,vec2(0.),vec2(sin(ka),cos(ka))*.04)-.009,pf)*l2);
     if(kr<.05&&kr>.034){float rg=abs(fract(atan(dq.y,dq.x)/TAU*24.)-.5)*TAU/24.*kr;col=mix(col,BXK,bxA(rg-.0016,pf)*bxFade(pf,kr*TAU/24.)*.7);}}
    fq=(q-vec2(0.,.135))/.085;fs=.085;
  }
  return bxFace(col,fq,pf/fs,mo,bl,md,lod,sd,ey);
}
// the giant mosaic picture behind the wall (stadium cards): palette index for a cell centre w, mode m
// palettes are sorted by luminance in JS (0 darkest .. 5 lightest). fx = 1 where the picture keeps fixed colours,
// ink = 1 where the cell must be pure ink (outlines, pupils, mouth), so the picture reads as a drawing at any zoom
float bxMacro(vec2 w,float m,float tb,float au,out float dk,out float fx,out float ink){
  // (v13/v14) zoomed out the giant pictures play too: the face sings and blinks, the bullseye's rings are pushed out by
  // the bass, the heart beats on the kick, the sunburst swings on the snare (au = the zoom-out weight: at zoom 1 nothing
  // moves)
  float bb=.5*(uP2.x+uP2.y)*au;
  dk=0.;fx=0.;ink=0.;float r=length(w),k;
  if(m<1.){
    // giant kawaii face: a light disc with an ink rim, two big blinking eyes with glints, cheeks, a singing mouth;
    // rainbow rings run out from it
    k=1.+mod(floor(r*1.6-tb*.125-1.5*bb),4.);
    if(r<2.32){
      fx=1.;k=5.;
      float bl=smoothstep(.05,0.,abs(fract(tb*.021)-.5));
      vec2 e=vec2(abs(w.x)-.87,w.y-.42-.08*bb);
      float ey=length(e/vec2(.5,.62*(1.-.9*bl)));
      if(ey<1.){k=5.;dk=.45;
        if(ey<.62){ink=1.;if(length(e-vec2(-.16,.18))<.24){ink=0.;k=5.;}}}
      if(abs(ey-1.)<.11)ink=1.;
      if(length(vec2(abs(w.x)-1.62,w.y+.3)/vec2(.44,.3))<1.)k=3.;
      float so=au*BMSING;
      vec2 mq=vec2(w.x,w.y+.74-.3*so);
      float mm=length(mq/vec2(.62+.32*so,.17+.5*so));
      if(mm<1.){ink=1.;if(mq.y<-.22){ink=0.;k=3.;}}
      if(r>2.2)ink=1.;
    }
  }else if(m<2.){
    k=floor(r*2.-tb*.25-2.*bb);
  }else if(m<3.){
    vec2 p=w/(2.6*(1.+.18*uP1.z*au))+vec2(0.,.45);p.x=abs(p.x);vec2 qh=p-.5*max(p.x+p.y,0.);
    float dh=mix(sqrt(min(dot(p-vec2(0.,1.),p-vec2(0.,1.)),dot(qh,qh)))*sign(p.x-p.y),length(p-vec2(.25,.75))-.35355,step(1.,p.y+p.x));
    fx=step(dh,0.);
    k=dh<0.?(dh<-.09?4.:0.):1.+mod(floor((w.x+w.y)*1.2-tb*.125),2.);
  }else{
    k=floor(atan(w.y,w.x)/TAU*14.+r*.35-tb*.0625+.6*BMSN*au);
    if(r<.9){k=5.;fx=1.;}
  }
  return k;
}
vec3 bxScene(vec2 p0){
  float tb=uP1.x,ext=uP1.y,kick=uP1.z,kA=floor(uP5.x*.5),bld=uP5.x-2.*kA,brk=mod(uP5.y,2.),dfl=mod(uP5.z,2.);kA/=240.;
  float ev=floor(uP5.w),evp=fract(uP5.w),csN=floor(uP1.w/4.),ramp=uP1.w-4.*csN;
  float wty=floor(uP4.z/4.),wp=uP4.z-4.*wty,asp=uRes.x/uRes.y,px0=1./uRes.y;
  // ---- transition between compositions A (outside / before) and B: circle burst, curtain drop, diagonal sweep
  float dW;
  if(wty<.5)dW=length(p0)-wp*.75;
  else if(wty<1.5){float sx=floor(p0.x*8.+50.);dW=(.62-(wp*.75-.12*h11(sx+3.))*1.6)-p0.y+.025*cos(fract(p0.x*8.)*TAU);}
  else dW=dot(p0,vec2(.6,.8))+1.05-wp*1.15;
  float useB=wp>=1.999?1.:step(dW,0.);
  float C=mix(uP4.x,uP4.y,useB),fam=floor(C),vs=fract(C);
  float vsI=floor(vs*97.),sm=max(clamp(uSmooth,0.,1.)*.6,.85*mod(uP5.y,2.));
  float bb=.5*(uP2.x+uP2.y);
  float zm=uZoom*(1.+.08*bld+.04*bb+.022*kick);
  vec2 p=(p0-vec2(0.,.022*bb-.012*uP1.z))/zm;float px=px0/zm;
  // a drop blows the outgoing formation outward and spins it away while the new one wipes in
  float blow=(1.-useB)*min(dfl*1.6,1.)*wp;p*=1./(1.+1.6*blow*blow);p=rot(blow*1.2)*p;
  // (v14) the wall is a physical surface, not a picture: the bass barrels it toward the viewer, every kick sends a
  // ripple running out through the chips, and the mids twist it
  float rw=length(p),wsc=1.+.055*bb*exp(-rw*rw*2.6)+.04*kick*exp(-rw*rw*1.7);
  p*=wsc+.022*kick*sin(rw*20.-uTime*13.)*exp(-rw*1.3);
  p=rot(.045*(bxBand(3.)-.5)*exp(-rw*rw*2.)*exp(-rw*1.2))*p;
  // (v14) the wall's scale is part of the composition: some visits are big chunky characters, some are fine dense mosaic
  float G=.25;
  // ---- layout: cell-local q, cell world size s, hash h, size level, cell centre cw, band
  vec4 h=vec4(0.);vec2 qc=vec2(0.),cw=vec2(0.),u=vec2(0.),id=vec2(0.);float s=G,ss=G,lvl=1.,band=0.,hero=0.,march=0.,sc=0.,off=0.,N=1.;
  // (v14) how many 2x2 hero characters this composition has is part of its look: 6-30% of the wall is giant
  float gP=(.06+.24*fract(vs*3.1))*step(fam,1.5),sP=(.3+.32*fract(vs*5.7))*(1.-.3*step(2.5,fam)),sP2=(.22+.25*fract(vs*8.3))*step(fam,2.5);
  float r=max(length(p),1e-5),th=atan(p.y,p.x),R0=.3;
  if(fam<1.5){
    // WALL (column pairs step up / down) or PARADE (row pairs march left / right)
    u=p/G;if(fam>.5)u=u.yx;
    float pc=floor(u.x*.5);vec4 hc=bxH(vec2(pc,vsI),1.);
    float rate=hc.x<.2?.25:(hc.x<.55?.5:1.),dir=mod(pc,2.)*2.-1.;
    march=step(.5,fam);rate=max(rate,.5*march);
    sc=dir*(mix(bxEase(tb*rate,sm),tb*rate,march)+ext*rate);
    u.y+=sc;id=floor(u);
  }else if(fam<2.5){
    // RINGS: counter-rotating rings of characters (inner = bass) round a giant woofer face
    float k=floor((r-R0)/G);hero=step(k,-.5);
    N=max(6.,floor(TAU*(R0+(k+.5)*G)/G+.5));
    float rate=bxH(vec2(k,vsI),1.).x<.3?.5:1.,dir=mod(k,2.)*2.-1.;
    off=dir*(bxEase(tb*rate,sm)+ext*rate);
    u=vec2(th/TAU*N+off,(r-R0)/G);id=vec2(mod(floor(u.x),N),k);
  }else{
    // TUNNEL: conformal log-polar tunnel, rows flow outward, alternate rows step round, spokes = bands
    N=floor(8.+6.*fract(vs*7.3));
    u=vec2(-th/TAU*N,log(r)*N/TAU-tb*.25-ext);
    u.x+=(mod(floor(u.y),2.)*2.-1.)*bxEase(tb*.5,sm);
    id=vec2(mod(floor(u.x),N),floor(u.y));ss=r*TAU/N;
  }
  // shared cell lookup: a 2x2 giant (wall only), else the cell, split into quarters and sixteenths by hash
  qc=fract(u)-.5;h=bxH(id,3.+vsI);s=ss;
  vec2 sb=floor(u*.5);vec4 hs=bxH(sb+vec2(17.,0.),2.+vsI);
  if(hs.x<gP){qc=u*.5-sb-.5;s=2.*ss;h=hs;lvl=0.;}
  else if(h.x<sP&&ss/px>28.){vec2 g=step(0.,qc);qc=qc*2.-(g-.5);s*=.5;id=id*2.+g;h=bxH(id,5.+vsI);lvl=2.;
    if(h.x<sP2&&ss/px>56.){g=step(0.,qc);qc=qc*2.-(g-.5);s*=.5;h=bxH(id*2.+g,7.+vsI);lvl=3.;}}
  vec2 uc=u-qc*(s/ss);
  if(fam<1.5){uc.y-=sc;cw=(fam>.5?uc.yx:uc)*G;if(fam>.5)qc=qc.yx;
    band=clamp(floor(mix((cw.x*zm/asp+.5),(cw.y*zm+.5),fam)*8.),0.,7.);}
  else if(fam<2.5){qc.x=-qc.x;float tc=(uc.x-off)/N*TAU;cw=(R0+uc.y*G)*vec2(cos(tc),sin(tc));band=mod(floor(uc.y),8.);}
  else{cw=p/r*exp((uc.y+tb*.25+ext)*TAU/N);band=mod(floor(uc.x),8.);}
  float rowI=floor(uc.y);
  // hero (decided before colouring): the giant woofer face in the rings, or the giant boombox event
  float gg=step(abs(ev-3.),.5)*smoothstep(0.,.1,evp)*(1.-smoothstep(.9,1.,evp))*step(fam,1.5);
  float S=max(1.25*gg,.01);vec2 qh=(p-vec2(0.,-.03+.02*sin(PI*tb)))/S;
  vec2 hq=qh-vec2(0.,.255);
  float giant=step(.01,gg)*step(min(bxBox(qh-vec2(0.,-.06),vec2(.45,.26),.06),max(abs(bxBox(hq,vec2(.27,.085),.075))-.026,-hq.y)),.07),hz=max(hero,giant);
  if(hero>.5){h=bxH(vec2(vsI,1.),9.);band=0.;cw=vec2(0.);}
  float pf=px/s;
  // ---- tile colours: palette index from the giant mosaic (or the hash), stepped by the snare colour wave
  float dsc=length(cw*zm),shift=csN+step(dsc,ramp*1.1)*step(.001,ramp);
  float dk=0.,fx=0.,ikm=0.,mi=bxMacro(cw/wsc,floor(fract(vs*4.7)*4.),tb,1.-smoothstep(.2,.55,zm),dk,fx,ikm);
  dk*=1.-smoothstep(.3,.7,zm);
  float ci=fam>2.5?mod(rowI,6.):mi;
  float mz=(1.-smoothstep(.2,.55,zm))*step(fam,2.5);
  mz*=1.-hero;dk*=1.-hero;
  ci=mix(mix(ci,floor(h.z*6.),step(.82+.2*mz,h.w)*(1.-dk)*(1.-fx*mz))+shift*(1.-fx*mz),shift+2.,hero);
  float c2o=floor(h.w*3.);c2o=1.+c2o+step(1.5,c2o);
  vec3 c1=bxC(ci),c2=bxC(ci+c2o),c3=bxC(ci+5.-floor(h.y*2.)*step(c2o,3.5));
  vec3 bgA=mix(bxC(ci+3.)*.9,c1*.85,mz)*mix(1.,.35,dk),bgB=mix(bxC(ci+2.+floor(h.y*3.))*.58,c1*.8,mz)*mix(1.,.35,dk);
  {float vd=step(.42,fract(h.x*7.31+h.y*3.17));c1=mix(c1,mix(c1*.26+BXK,mix(c1,vec3(1.12),.62),vd),.85*mz);}
  if(dk>.5){c1=c1*.25+BXK;c2*=.35;c3*=.4;}
  if(giant>.5){float cj=csN+step(.001,ramp)+4.;c1=bxC(cj);c2=bxC(cj+2.);c3=bxC(cj+4.);band=1.;}
  float night=step(abs(ev-5.),.5)*smoothstep(0.,.06,evp)*(1.-smoothstep(.94,1.,evp));
  bgA*=1.-.45*night;
  // kick: the background breathes light outward from the centre
  bgA*=1.+.55*uO1.x*exp(-dsc*1.5)+.33*kick;
  // (v13) the whole wall is a level meter: every band lights its own tiles from the bass end up to its level (WALL:
  // columns rise from the floor, PARADE: rows run in from the left, RINGS: each ring fills up like a cup,
  // TUNNEL: each spoke lights outward from the centre), with a white-hot cap on top; unlit tiles sink back
  float lvB=bxBand(band),mv=fam<1.5?mix(cw.y*zm,cw.x*zm/asp,fam)+.5:(fam<2.5?.5+.5*cw.y/max(length(cw),1e-3):dsc*.85),thr=.04+lvB;
  float tsz=mix(G*zm,.07,step(1.5,fam)),lit=clamp((thr-mv)/tsz+.5,0.,1.)*(1.-hero),cap=lit*clamp(1.5-(thr-mv)/tsz,0.,1.);
  // (v14) the kick's shockwave is a wide ring of light that crosses the whole frame in screen space, and every block
  // it passes swells out of the wall
  float kd=length(p0),kx=(kd-.05-.62*kA)*6.5,kw=exp(-kx*kx)*exp(-kA*1.6)*step(kA,1.99)*min(1.,kA/.07);
  vec3 lc=bxC(band+shift+1.)*1.8;
  bgA*=1.+.7*cap+.6*kw;bgB*=1.+.6*cap+.5*kw;
  float ik=1.-smoothstep(.07,.26,pf)*(.2+.2*mz),lod=1.-smoothstep(.03,.06,pf);
  // (v14) RELIEF: every tile is an extruded block standing in the wall. The level meter lifts it, the kick's
  // shockwave rolls through as a swell, a slow wave travels over the wall with the low mids, the snare bounces it,
  // and a drop blows the whole wall out into a cloud of floating blocks.
  float wv=sin(dot(cw,vec2(1.6,1.0))-tb*1.9+vs*6.2832)*(1.+bxBand(2.));
  float burst=min(dfl*1.6,1.)*wp*(.2+.8*h.w);
  float lift=clamp(.9*lit+.85*kw+.17*(wv*.5+.5)+.3*BMSN+2.3*burst,0.,2.4);
  float gap=min(max(.03*(1.-.3*min(lift,1.5)),1.15*pf),.1),kq=.5/max(.5-gap,1e-3);
  vec2 qv=qc*kq;float pv=pf*kq;
  vec3 col=bxTile(qv,pv,floor(h.y*5.),bgA,mix(bgA,bgB,.72));
  // (v14) the block is a rounded chip: its face is a rounded square, the seam and the corners are the dark wall behind
  float dgv=-bxBox(qv,vec2(.5),.05);
  // the seam: the dark wall behind, lit from the top left and in shadow at the bottom right of each block
  float sl2=clamp(.5+.75*(qc.y-qc.x),0.,1.);
  col=mix(col,mix(BXK*.55,BXK*1.5+c1*.035,sl2),1.-smoothstep(-pf*.8,pf*.5,dgv));
  // the lip: a wide lit bevel on the top and left edges, a narrow dark one on the bottom and right; both grow as the
  // block stands out of the wall, which is what makes the level meter read as depth rather than as brightness
  float bev=min(.034+.062*min(lift,1.5),.075),bw=bev*.72,sl=clamp(.5+.9*(qv.y-qv.x),0.,1.);
  vec3 lipL=bgA*1.16+bgB*.16+lc*.08*kw+cap*.42,lipD=bgA*.14+BXK*.45;
  col=mix(col,mix(lipD,lipL,sl)*(1.+.1*lift+.35*kw),1.-smoothstep(bw,bw+pv*1.2,dgv));
  // (the meter's leading edge gets a white-hot lip: see lipL below)
  float pvT=pv,pfT=pf,lodT=lod,sT=s,colK=1.;   // the tile's own values (the hero branch below overwrites pv, pf, lod and s)
  // ---- the object in this cell
  float tyR=fract(h.y*7.31+h.z*3.1),pr=floor(fract(vs*11.3)*9.);
  float ty=lvl<.5?(tyR<.4?0.:(tyR<.7?3.:(tyR<.87?2.:6.))):(lvl<1.5?floor(tyR*9.):(tyR<.24?5.:(tyR<.4?1.:(tyR<.56?0.:(tyR<.68?2.:(tyR<.78?4.:(tyR<.9?7.:8.)))))));
  ty=mix(ty,pr,step(h.w,.22)*step(lvl,1.5)*step(.5,lvl));
  float e=clamp(bxBand(band)+kick*.45*step(band,1.5),0.,1.3),on=bxOn(band);
  // events: 1 stadium wave, 2 chorus, 3 giant boombox, 4 spin storm, 5 night
  float wave=0.;
  if(abs(ev-1.)<.5){float wx=mix(-1.4,1.4,fract(evp*2.))*asp*.5;wave=exp(-pow((cw.x*zm-wx)*3.5,2.));}
  float chorus=step(abs(ev-2.),.5)*smoothstep(0.,.08,evp)*(1.-smoothstep(.9,1.,evp));
  float mo=max(max(BMSING*step(.35,h.y),smoothstep(.4,.95,e)*.75*step(h.y,.35)),max(wave,chorus*max(BMSING,.45)));
  float md=max(step(.93,h.x),max(step(.5,wave),chorus*step(.5,h.z)));
  float ph=fract(uTime*.21+h.w*13.),bl=1.-smoothstep(0.,.025,abs(ph-.5));
  vec2 q=qv;float rnd=0.,sd=h.z*7.+h.w;
  // (v20b) THE CHASE. On every beat a hop runs through the formation like a running light: round each ring (four hops a turn, alternate rings the other
  // way), up the wall's columns, along the parade's rows, out along the tunnel. The row's own band sets how high they jump, so a ring bounces like a level
  // meter. A hop is a punch (up in a thirtieth of a beat, back down within the beat), not a sway.
  float chU=fam<1.5?(mix(cw.y,cw.x,fam)*zm+.5)*2.5:(fam<2.5?(uc.x-off)/N*4.*(mod(rowI,2.)*2.-1.):uc.y*.25),chF=fract(tb-chU);
  float chase=min(chF*30.,1.)*exp(-5.5*chF)*(.3+.7*clamp(lvB,0.,1.))*(1.-.6*brk)*(1.-hz);
  // (v20b) THE SNARE TRAVELS. Each snare sends a crisp flash through the tiles, one tile after the next: from the middle column outward on the wall, from
  // the middle row on the parade, from the top round both sides in the rings and the tunnel. A tile it reaches stands out of the wall and its lip lights.
  float sAg=BMSNA,snU=fam<1.5?abs(mix(cw.x*zm/asp,cw.y*zm,fam))*2.:acos(clamp(cw.y/max(length(cw),1e-3),-1.,1.))/PI;
  float snF=exp(-pow((snU-sAg*2.6)*5.,2.))*exp(-sAg*2.2)*step(sAg,1.9)*(1.-hero);
  q.y+=-.06*wave-march*.07*pow(sin(PI*(tb+h.x)),2.);q=q/(1.+.08*wave+.06*e*step(ty,4.5));
  // every character squashes on the kick (wider, shorter) and springs back
  q*=vec2(1.-.08*uP1.z,1.+.11*uP1.z);
  // (v13) every character hops on the snare (a smoothed envelope) and swells as the kick's ring passes
  q.y-=.11*BMSN*(1.-.5*step(4.5,ty))+.12*chase;q/=1.+.16*kw+.07*chase+.1*snF;
  if(hz>.5){sd=1.7;q=mix(p/.624,qh,giant);s=mix(.624,S,giant);pf=px/s;pv=pf;ty=3.*giant;rnd=hero;e=clamp(bxBand(band)+kick*.5,0.,1.3);
    on=bxOn(band)+hero*bxOn(1.);lod=1.;ik=1.;mo=max(BMSING,mix(smoothstep(.3,.9,bxBand(3.))*.8,.3,giant));md=chorus*hero;colK=mix(.5,1.,giant);}
  {
#if HD>=1
    // each collage level is two offset lattices, so the little characters overlap as a printed collage; tone on tone, so the tile's main icon stays clear
    int nL=dgv>bw?2*int(min(float(HD),1.+1.3*log2(max(uDetail,1.)))):0;float mcOff=0.,mSd=h.z+h.y*3.,mE=bxBand(band);
#else
    int nL=0;
#endif
#if HD>=1
    for(int i=BM0;i<nL+1;i++){
#else
    {const int i=0;   // High: no loop at all (a run-time loop round the character function took the HD 0 compile from 2 s to 28 s)
#endif
      vec2 oq=q;float oty=ty,opf=pv,oe=e,oon=on,olod=lod,oik=ik,omo=mo,obl=bl,omd=md,osd=sd,otb=tb,ornd=rnd,vis=0.;vec3 o1=c1,o2=c2,o3=c3;
#if HD>=1
      if(i<nL){
        if(mcOff>.5)continue;
        float lev=floor(float(i)*.5),lay=float(i)-2.*lev,n=6.*pow(4.,lev),ppf=pvT*n,mpx=8.+6.*float(HD);vis=1.-smoothstep(.75,1.25,ppf*mpx);
        if(vis<=0.){mcOff=1.;continue;}
        vec2 cell=(qv+.5)*n+(lay*.5+.13*lev)*vec2(1.,.7),id2=floor(cell);
        vec4 hm=bxH(id2+mSd*37.+lay*5.,11.+float(i));
        if(hm.x>=mix(.62,.4,lay))continue;
        float sc2=mix(.84,.66,lay);
        oq=(cell-id2-.5)/sc2;oty=floor(hm.y*9.);opf=ppf/sc2;oe=mE;oon=0.;o1=mix(bgA,bgB,hm.z)*1.12+.02;o2=bgA*1.55+.05;o3=bgB*1.45+.04;
        olod=0.;oik=.75;omo=0.;obl=0.;omd=0.;osd=hm.z*7.;otb=tb*(.5+hm.w);ornd=step(.75,hm.w);
      }else
#endif
      {
        // hats: twinkles on the tile corners (bigger), and the lips glint
        vec2 tq=qv-vec2(.36,.36)*sign(h.zw-.5);float tw=max(bxOn(6.+step(.5,h.z)),1.15*BMHAT)*step(.3,h.y)+.12*step(.9,h.y);
        float stD=(sqrt(abs(tq.x))+sqrt(abs(tq.y))-sqrt(.13*tw))*.35;
        col=mix(col,vec3(2.2,2.1,1.6),bxA(stD,pvT)*step(.01,tw)*lodT);
        // (v19) where this tile meets a tile of another colour field (mosaic ring, heart, ray, tunnel row) the edge gets a heavier
        // ink line, so the rings read as separate shapes. Decided per edge from the neighbour's centre.
        {float mzE=max(mz,.8*step(2.5,fam));
         if(mzE>.01){vec2 aq=abs(qc);float axs=step(aq.y,aq.x),dNb=.5-max(aq.x,aq.y),rB;
          if(fam>2.5)rB=1.-axs;
          else{vec2 nd=axs>.5?vec2(sign(qc.x),0.):vec2(0.,sign(qc.y)),nc;
           if(fam<1.5)nc=cw+nd*sT;
           else{float cr=max(length(cw),1e-3);vec2 er=cw/cr;nc=cw+(er*nd.y-vec2(-er.y,er.x)*nd.x)*sT;}
           float a0,a1,a2,na=bxMacro(nc/wsc,floor(fract(vs*4.7)*4.),tb,1.-smoothstep(.2,.55,zm),a0,a1,a2);
           rB=step(.5,abs(mod(floor(mi+.5)-floor(na+.5)+3.,6.)-3.));}
          col=mix(col,BXK*.5,rB*mzE*bxA(dNb-max(.03,1.4*pfT),pfT));}}
        col*=colK;
      }
      vec3 o=bxObj(col,oq,oty,opf,oe,oon,o1,o2,o3,olod,oik,omo,obl,omd,osd,otb,ornd);
      if(i<nL){o=mix(o,bgA*(.3+1.25*dot(o,vec3(.2126,.7152,.0722))),.72);col=mix(col,o,vis*.9);}else col=o;
    }
  }
  // (v20b) RING METERS. In the rings every seam between two rings is a circular level meter for the ring inside it: a chain of lamps that fills from
  // twelve o'clock down both sides as that ring's band rises (green, amber, red at the bottom), with a white-hot peak lamp at the tip. One band per
  // ring, so the whole formation reads as a spectrum. Crisp lamps on ink, no glow; drawn where a lamp is at least a few pixels across.
  if(fam>1.5&&fam<2.5){
    float rbv=(r-R0)/G,kb=floor(rbv+.5),drb=(rbv-kb)*G,vm=(1.-smoothstep(.0034,.0052,px*BMSS))*step(.5,kb);
    if(vm>0.&&abs(drb)<.03){
      float rB=R0+kb*G,nb=2.*floor(PI*rB/.046+.5),ab=atan(p.x,p.y)/TAU*nb,bi=floor(ab+.5),bp=abs(bi)/(nb*.5),lvM=clamp(bxBand(mod(kb-1.,8.)),0.,1.)*1.04;
      vec2 mq=vec2((ab-bi)*TAU*rB/nb,drb);float dm=length(mq)-.0105,onM=step(bp,lvM),tipM=onM*step(lvM-2.2/nb,bp);
      vec3 mc=mix(mix(vec3(.25,1.8,.55),vec3(2.,1.35,.15),smoothstep(.45,.62,bp)),vec3(2.1,.3,.2),smoothstep(.72,.86,bp));
      col=mix(col,BXK,bxA(dm-max(.0045,1.2*px),px)*vm);
      col=mix(col,mix(mix(mc*.13+BXK,mc,onM),vec3(2.2,2.1,1.9),tipM),bxA(dm,px)*vm);
      col=mix(col,vec3(2.2),bxA(length(mq-vec2(-.003,.0035))-.0028,px)*vm*onM*.8);
    }
  }
#if HD>=2
  // (v20b) Cinema and up: every chip is screwed to the wall: a slotted screw in each corner of its face
  if(hz<.5&&dgv>bw){vec2 cs=abs(qv)-vec2(.435);float fsc=bxFade(pv*BMSS,.07),cr2=length(cs);
    col=mix(col,BXK,bxA(cr2-.024,pv)*fsc);col=mix(col,mix(bgA,vec3(1.6,1.55,1.4),.6),bxA(cr2-.017,pv)*fsc);
    vec2 cr3=rot(h.x*6.+h.y*3.*sign(qv.x))*cs;col=mix(col,BXK,bxA(abs(cr3.y)-.0035,pv)*step(abs(cr3.x),.013)*bxFade(pv,.02));
    col=mix(col,vec3(2.),bxA(length(cs-vec2(-.006,.007))-.004,pv)*bxFade(pv,.02)*.7);}
#endif
#if HD>=1
  // (v20b) Native and up: BADGES. Between every two characters of a ring (a column, a row, a spoke) a small part of the rig is riveted over the seam:
  // a jewel lamp that fires with its band, a knob that turns with it, a mini record on the groove clock, a cross-head bolt. They belong to the seam, not
  // to either tile, so their colour and band come from the seam's own hash. Drawn only where one is at least a dozen pixels across.
  if(hz<.5){
    vec2 bu=fam<1.5?vec2(fract(u.x)-.5,fract(u.y+.5)-.5):vec2(fract(u.x+.5)-.5,fract(u.y)-.5),bid=floor(fam<1.5?vec2(u.x,u.y+.5):vec2(u.x+.5,u.y));
    float pb=px/ss,vb=(1.-smoothstep(.014,.024,pb*BMSS))*(1.-step(lvl,.5)*step(.5,mod(bid.y,2.)));
    vec4 hb4=bxH(fam>1.5?vec2(mod(bid.x,N),bid.y):bid,13.+vsI);
    vb*=step(hb4.x,.86);
    if(vb>0.){
      float rb=.115+.03*hb4.w,bk=floor(hb4.y*4.),bb2=floor(hb4.z*8.),dbd=length(bu)-rb,lwb=max(.011,1.1*pb),lv2=clamp(bxBand(bb2),0.,1.),fine=1.-smoothstep(.006,.012,pb);
      vec3 cb=bxC(floor(hb4.w*6.)+csN),cb2=bxC(floor(hb4.w*6.)+csN+3.);
      col=mix(col,col*.4,bxA(length(bu-vec2(.014,-.018))-rb,pb)*vb);
      col=mix(col,BXK,bxA(dbd-lwb,pb)*vb);
      vec3 bc;
      if(bk<.5){
        // jewel lamp in a collar: fires on its band's onsets, holds while the band is high; a facet ring and a glint
        float lit2=max(bxOn(bb2),smoothstep(.55,.9,lv2));
        bc=mix(cb2*.9,mix(cb*.22+BXK,cb*2.1+.15,lit2),bxA(dbd+rb*.3,pb));
        bc=mix(bc,BXK,bxA(abs(dbd+rb*.3)-lwb*.4,pb));
        bc=mix(bc,mix(bc*1.5,vec3(2.),lit2),bxA(length(bu-vec2(-.25,.3)*rb)-rb*.16,pb));
        bc=mix(bc,bc*.6,fine*bxA(abs(length(bu)-rb*.42)-.004,pb)*.7);
      }else if(bk<1.5){
        // knob: a pointer that turns with its band, a knurled rim
        float ka=-2.3+4.6*lv2;
        bc=cb;
        bc=mix(bc,cb*1.5+.08,bxA(abs(dbd+rb*.22)-lwb*.35,pb));
        bc=mix(bc,BXK,bxA(bxSeg(bu,vec2(0.),vec2(sin(ka),cos(ka))*rb*.62)-rb*.11,pb));
        bc=mix(bc,BXK,fine*.7*bxA(abs(fract(atan(bu.y,bu.x)/TAU*20.)-.5)*TAU/20.*rb-.0022,pb)*step(rb*.8,length(bu)));
      }else if(bk<2.5){
        // mini record: grooves, a label, a sheen that turns on the groove clock
        float rr=length(bu),cx=(rot(-TAU*BMGRV*(1.+floor(hb4.z*3.)))*bu).x/max(rr,1e-4),c2x=cx*cx;
        bc=vec3(.04,.028,.07)+cb*.08;
        bc=mix(bc,cb*.4+.05,fine*.7*bxA(abs(fract(rr/rb*7.)-.5)*rb/7.-.0016,pb)*step(rb*.42,rr));
        bc=mix(bc,cb*1.2+.2,c2x*c2x*c2x*c2x*.55*step(rb*.42,rr));
        bc=mix(bc,cb2,bxA(rr-rb*.4,pb));bc=mix(bc,BXK,bxA(rr-rb*.09,pb));
      }else{
        // cross-head bolt on a washer
        bc=mix(cb,vec3(1.5,1.45,1.35),.55);
        bc=mix(bc,bc*.55,bxA(abs(dbd+rb*.36)-lwb*.35,pb));
        vec2 br=rot(hb4.z*3.)*bu;
        bc=mix(bc,BXK,bxA(min(abs(br.x),abs(br.y))-rb*.085,pb)*step(max(abs(br.x),abs(br.y)),rb*.5));
        bc=mix(bc,vec3(1.9),bxA(length(bu-vec2(-.3,.36)*rb)-rb*.1,pb)*.8);
      }
      col=mix(col,bc,bxA(dbd,pb)*vb);
    }
  }
#endif
  // (v13/v14) tiles above their band's level sit flat in the wall and dim; tiles below it stand out and shine
  col*=mix(mix(.78,1.,hz),1.07,lit)*(1.+.13*lift)*(1.+.05*kick)*(1.+.16*chase+.7*snF);   // (v19) the beat's light is multiplied into each tile instead of glowing over its neighbours
  // ---- transition hoop: an ink-edged rainbow band on the boundary
  if(wp<1.999){float bw=.022,dB=abs(dW+bw)-bw;
    col=mix(col,BXK,bxA(dB-max(.004,px0),px0));
    col=mix(col,bxC(floor((dW+2.*bw)/(2.*bw)*3.)+shift)*1.5+.15,bxA(dB,px0));}
  col*=1.+.15*dfl;
  col=mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.14);   // (v13/v14) keeps the chroma up under the meter's light and the bevels
  col=mix(col,col*vec3(.9,.95,1.15),.3*brk);
  // (v19) the exposure is pinned high (fb.key), so this gain leaves the final picture the same while every plain
  // saturated fill sits under the engine's bloom threshold: only real highlights glow, colours stop washing into each other
  col=max(col,0.);col/=max(1.,max(col.r,max(col.g,col.b))/2.05);
  return col*.67;
}
void realm(){
#if HD>=1
  // from Native up every pixel is sampled several times inside its own footprint: the art-print tiers
  int nS=HD>=5?9:HD+1;vec3 acc=vec3(0.);
  for(int i=BM0;i<nS;i++){vec2 o=fract(vec2(.7548776662,.56984029)*(float(i)+.5))-.5;acc+=bxScene(scr()+o/uRes.y);}
  fragColor=vec4(acc/float(nS),0.);
#else
  fragColor=vec4(bxScene(scr()),0.);
#endif
}
`;
