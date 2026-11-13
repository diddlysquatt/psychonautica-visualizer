const R_TYKES = `
#define TY_NPAL 12
const vec3 TYQ[96]=vec3[96](
  vec3(0.0110,0.0052,0.0369),vec3(0.8070,0.0194,0.0437),vec3(0.0086,0.3663,0.1022),vec3(0.9301,0.4564,0.0116),vec3(0.0232,0.0908,0.7454),vec3(1.0000,0.8714,0.6038),vec3(0.8879,0.4678,0.0232),vec3(0.2542,0.0048,0.0273),
  vec3(0.0232,0.0030,0.0130),vec3(1.0000,0.0356,0.0176),vec3(1.0000,0.2542,0.0060),vec3(0.0065,0.5210,0.3813),vec3(0.1946,0.0319,0.8879),vec3(1.0000,0.8963,0.7011),vec3(0.9216,0.5395,0.0423),vec3(0.1946,0.0040,0.0423),
  vec3(0.0070,0.0030,0.0513),vec3(1.0000,0.0273,0.2462),vec3(0.0000,0.4793,0.9131),vec3(1.0000,0.6584,0.0000),vec3(0.1946,0.0452,1.0000),vec3(1.0000,0.8879,0.7454),vec3(1.0000,0.5841,0.0452),vec3(0.1441,0.0030,0.0685),
  vec3(0.0018,0.0194,0.0452),vec3(1.0000,0.1022,0.0137),vec3(0.0000,0.4342,0.2502),vec3(1.0000,0.7529,0.0742),vec3(0.7454,0.0152,0.2542),vec3(1.0000,0.9047,0.6724),vec3(0.9301,0.5841,0.0648),vec3(0.2542,0.0052,0.0296),
  vec3(0.0033,0.0052,0.0343),vec3(0.0467,0.1022,0.9911),vec3(0.0000,0.6939,0.4793),vec3(1.0000,0.0782,0.3663),vec3(1.0000,0.4508,0.0000),vec3(0.9047,0.8714,1.0000),vec3(1.0000,0.6376,0.1329),vec3(0.1022,0.0030,0.1119),
  vec3(0.0423,0.0018,0.0080),vec3(1.0000,0.0086,0.0578),vec3(0.0000,0.3813,0.1812),vec3(1.0000,0.2747,0.4397),vec3(0.0130,0.2462,0.7835),vec3(1.0000,0.9216,0.8550),vec3(0.9047,0.5583,0.0545),vec3(0.1946,0.0030,0.0194),
  vec3(0.0080,0.0018,0.0452),vec3(0.3916,0.8714,0.0000),vec3(1.0000,0.0000,0.5776),vec3(0.0000,0.6867,1.0000),vec3(1.0000,0.1946,0.0000),vec3(0.9647,1.0000,0.7454),vec3(1.0000,0.7529,0.0685),vec3(0.1119,0.0030,0.1441),
  vec3(0.0242,0.0060,0.0024),vec3(0.6939,0.0648,0.0048),vec3(0.8879,0.3968,0.0000),vec3(0.0284,0.3419,0.0578),vec3(0.2307,0.1119,0.9301),vec3(1.0000,0.8796,0.6240),vec3(0.8148,0.4621,0.0423),vec3(0.1946,0.0075,0.0052),
  vec3(0.0012,0.0137,0.0331),vec3(0.0000,0.3916,0.8070),vec3(1.0000,0.1470,0.0356),vec3(0.9301,0.6308,0.0006),vec3(0.2705,0.0262,0.7605),vec3(0.8228,0.9734,1.0000),vec3(1.0000,0.6584,0.1022),vec3(0.1946,0.0052,0.0513),
  vec3(0.0168,0.0030,0.0452),vec3(0.5395,0.0091,0.1046),vec3(0.2016,0.0742,1.0000),vec3(0.0000,0.5210,0.3763),vec3(1.0000,0.4072,0.0000),vec3(1.0000,0.8714,0.9216),vec3(1.0000,0.6240,0.1022),vec3(0.1022,0.0030,0.0423),
  vec3(0.0052,0.0103,0.0685),vec3(1.0000,0.0467,0.0000),vec3(1.0000,0.6724,0.0000),vec3(0.0000,0.5776,0.0865),vec3(0.6654,0.0000,0.9473),vec3(1.0000,0.9387,0.7529),vec3(1.0000,0.5906,0.0212),vec3(0.2542,0.0030,0.0130),
  vec3(0.0030,0.0232,0.0232),vec3(1.0000,0.0742,0.1529),vec3(0.0273,0.5520,0.4678),vec3(1.0000,0.5210,0.0000),vec3(0.1144,0.0048,0.3467),vec3(0.8796,1.0000,0.9216),vec3(0.9216,0.5841,0.0595),vec3(0.1946,0.0048,0.0423));
#define TY0 min(int(uTime),0)
#define TY_S 4.
#define TY_H 1.3
#if HD>=3
#define TY_NL 4
#elif HD>=1
#define TY_NL 3
#else
#define TY_NL 2
#endif
#if HD>=5
#define TY_SS 14
#elif HD>=4
#define TY_SS 8
#elif HD>=3
#define TY_SS 6
#elif HD>=2
#define TY_SS 4
#elif HD>=1
#define TY_SS 3
#else
#define TY_SS 1
#endif
#define TY_K 16
// The edge curves, as (along, across) on the straight edge they replace. Every tile of a family is cut by the same curves under that
// family's matching rule (translation, half turn, rotation about the hub), so each figure's outline IS its neighbours' outline.
// 1 tower top (the hat is the notch between the legs above), 2 tower side (the left hand is the hole under the right arm),
// 3 zip hat side (its own half turn: point symmetric), 4 gnome side, 5 wheel spoke (hub to rim)
const vec2 TYT[5*TY_K]=vec2[5*TY_K](
  vec2(0.,0.),vec2(.07,-.03),vec2(.2,-.035),vec2(.27,-.01),vec2(.3,.03),vec2(.34,.12),vec2(.39,.23),vec2(.44,.33),
  vec2(.475,.385),vec2(.49,.44),vec2(.54,.455),vec2(.565,.41),vec2(.55,.36),vec2(.6,.2),vec2(.68,.03),vec2(1.,0.),
  vec2(0.,0.),vec2(.03,-.07),vec2(.055,-.115),vec2(.085,-.1),vec2(.1,-.04),vec2(.17,-.005),vec2(.27,.03),vec2(.37,.065),
  vec2(.46,.06),vec2(.54,.01),vec2(.6,-.06),vec2(.68,-.1),vec2(.76,-.115),vec2(.84,-.085),vec2(.92,-.02),vec2(1.,0.),
  vec2(0.,0.),vec2(.04,.035),vec2(.09,.085),vec2(.15,.1),vec2(.22,.085),vec2(.3,.055),vec2(.4,.025),vec2(.5,0.),
  vec2(.6,-.025),vec2(.7,-.055),vec2(.78,-.085),vec2(.85,-.1),vec2(.91,-.085),vec2(.96,-.035),vec2(.985,-.01),vec2(1.,0.),
  vec2(0.,0.),vec2(.04,-.06),vec2(.08,-.1),vec2(.12,-.085),vec2(.15,-.03),vec2(.24,.0),vec2(.34,.04),vec2(.44,.06),
  vec2(.54,.04),vec2(.62,-.02),vec2(.7,-.07),vec2(.78,-.09),vec2(.86,-.06),vec2(.92,-.02),vec2(.97,-.005),vec2(1.,0.),
  vec2(0.,0.),vec2(.1,.004),vec2(.2,.012),vec2(.3,.02),vec2(.38,.012),vec2(.44,-.012),vec2(.5,-.03),vec2(.56,-.022),
  vec2(.62,.012),vec2(.68,.034),vec2(.74,.03),vec2(.78,.006),vec2(.8,-.006),vec2(.9,0.),vec2(.95,0.),vec2(1.,0.));
const vec2 TYBB[5]=vec2[5](vec2(-.06,.62),vec2(-.19,.16),vec2(-.19,.19),vec2(-.17,.14),vec2(-.07,.08));
// an edge point under what the edge is doing: a.x leans or wags it, a.y stretches or pumps it, a.z scales the whole cut (0 = a straight
// edge: the figure has turned into a plain block). Each rule keeps the family's symmetry.
vec2 tyPt(int tab,int k,vec3 a){
  vec2 e=TYT[(tab-1)*TY_K+k];
  if(tab==1){float n=max(e.y,0.);e.x+=a.x*n*n*1.7*a.z;e.y*=1.+a.y*step(.05,n);}
  else if(tab==2||tab==4){float w=clamp(1.4-abs(e.x-.74)*6.,0.,1.),h=clamp(1.4-abs(e.x-.36)*6.,0.,1.);e.x+=a.y*.085*w*a.z;e.y+=a.x*.065*h;}
  else if(tab==3){e.y=e.y*(1.+.5*a.y)+a.x*.07*sin(TAU*e.x);}
  else{e.y+=a.x*.035*sin(PI*min(e.x/.8,1.))*smoothstep(.1,.4,e.x);}
  e.y*=a.z;
  return e;
}
// one edge from A to B: does a ray toward +x from p cross it an odd number of times, how near is it, and how far along it
// (sa: arc length from the middle of the edge to the nearest point, for the chain of little figures the outline can turn into)
void tyEdge(vec2 p,vec2 A,vec2 B,int tab,float sg,vec3 a,inout float par,inout float dm,inout float sa){
  vec2 ex=B-A;float L=length(ex);vec2 et=ex/L,en=sg*vec2(-et.y,et.x),l=p-A;
  float ls=dot(l,et),ln=dot(l,en);
  bool cx=((A.y>p.y)!=(B.y>p.y))&&(p.x<A.x+(p.y-A.y)*(B.x-A.x)/(B.y-A.y));
#if HD>=1
  if(tab==0||a.z<.004){if(cx)par=1.-par;float lc=clamp(ls,0.,L),dd=length(l-et*lc);if(dd<dm){dm=dd;sa=lc-.5*L;}}
#else
  if(tab==0||a.z<.004){if(cx)par=1.-par;dm=min(dm,length(l-et*clamp(ls,0.,L)));}
#endif
  else{
    vec2 bb=TYBB[tab-1];
    // outside the curve's box the curve can be replaced by its chord (the two close a loop that lies inside the box)
    float o=max(max(bb.x-ln,ln-bb.y),max(-.14*L-ls,ls-1.14*L));
    // (beside the hat the tower's top edge is nearly flat: the box there is only as high as the shoulder)
    if(tab==1&&ln>.06){float dx=.352*a.x*a.z;o=max(o,min(ln-.06,max(.25+min(dx,0.)-ls,ls-.71-max(dx,0.))));}
    if(o>0.&&cx)par=1.-par;
    if(o<dm){
      vec2 q0=A;bool cr=false;
#if HD>=1
      float al=0.,sb=0.,db=dm;
#endif
      for(int k=TY0+1;k<TY_K;k++){
        vec2 e=tyPt(tab,k,a),q1=A+ex*e.x+en*e.y;
        if((q0.y>p.y)!=(q1.y>p.y)){if(p.x<q0.x+(p.y-q0.y)*(q1.x-q0.x)/(q1.y-q0.y))cr=!cr;}
#if HD>=1
        vec2 pa=p-q0,ba=q1-q0;float b2=max(dot(ba,ba),1e-8),h=clamp(dot(pa,ba)/b2,0.,1.),dd=length(pa-ba*h),sl=sqrt(b2);
        if(dd<db){db=dd;sb=al+h*sl;}
        al+=sl;q0=q1;
#else
        vec2 pa=p-q0,ba=q1-q0;float h=clamp(dot(pa,ba)/max(dot(ba,ba),1e-8),0.,1.);dm=min(dm,length(pa-ba*h));
        q0=q1;
#endif
      }
#if HD>=1
      if(db<dm){dm=db;sa=sb-.5*al;}
#endif
      if(o<=0.&&cr)par=1.-par;
    }
  }
}
#define TYA(d) clamp(.5-(d)/px,0.,1.)
#define TYF(d) clamp(.5-(d)/pf,0.,1.)
// the maker's stamp: two rows of marks, five by seven beads each (two ints a mark: rows 0 to 3, then 4 to 6), six over three,
// and sometimes a seven by seven toadstool beside them. p: x 0..36 (..45 with the toadstool), y 0..16
float tyPlate(vec2 p,float msh){
  const ivec2 G[8]=ivec2[8](ivec2(508430,1086),ivec2(1020036,4228),ivec2(476721,17966),ivec2(583347,17969),
                            ivec2(1032734,16927),ivec2(1001009,17982),ivec2(476735,17969),ivec2(1001022,16912));
  const int Wm[10]=int[10](0,1,2,3,4,5,-1,6,7,4);
  const int Ms[7]=int[7](28,62,107,127,28,28,28);
  float on=0.;
  if(p.x>=0.&&p.x<36.&&p.y>=0.&&p.y<16.){
    bool tp=p.y>=9.;float py=tp?p.y-9.:p.y,qx=tp?p.x:p.x-9.;
    if(py<7.&&qx>=0.&&qx<(tp?36.:18.)){
      int ci=int(qx/6.),cx=int(qx)-ci*6,gi=Wm[tp?ci:ci+7];
      if(gi>=0&&cx<=4){int r=6-int(py),bits=r<4?(G[gi].x>>((3-r)*5))&31:(G[gi].y>>((6-r)*5))&31;on=float((bits>>(4-cx))&1);}
    }
  }
#if HD>=1
  else if(msh>.5&&p.x>=38.&&p.x<45.&&p.y>=4.&&p.y<11.){
    on=float((Ms[10-int(p.y)]>>(6-(int(p.x)-38)))&1);
  }
#endif
  return on;
}
float tySeg(vec2 p,vec2 a,vec2 b){vec2 pa=p-a,ba=b-a;return length(pa-ba*clamp(dot(pa,ba)/max(dot(ba,ba),1e-8),0.,1.));}
// where the parts of a figure sit in its tile (figure coordinates: x from the middle, y up from the soles)
// hc/hr head, yb brim height, hw hat half width at the brim, tip, hy1 (above it the tile itself is the hat's edge), bc/br belly cog,
// sh shoulder, hd hand, hem, legs (0 long stockings round the hat below, 1 short legs on a floor, 2 one pointed stocking, 3 none),
// look: bits 0-1 hat pattern, 2 beard, 3 toadstool badge, 4 toadstool by the stamp, 5-6 face (googly, spectacles, monocle and
// moustache, long nose), 7-8 tool on the belt (none, wrench, oil can, hammer), 9 wind-up key, 10-11 hat tip (bobble, bell, star, cog),
// 12-13 where the stamp is (a dark plate, a label in the hat, engraved brass)
// mk: the stamp (middle, width; 0 = none), mq: x how brightly it is lit just now, y 1 a stamp is always there
struct TyL{vec2 hc;float hr;float yb;float hw;vec2 tip;float hy1;vec2 bc;float br;vec2 sh;vec2 hd;float hem;int legs;int look;vec3 mk;vec2 mq;};
// the figure drawn inside its tile. The tile outline is the silhouette; this is the drawing that explains it.
// CA = hat, tunic, skin; CB = trim, metal, cream. Returns flat enamel; ink = line coverage. mo: 0 figure .. 1 the cog has taken the tile.
// an: cog angle, hand pump, head tilt, glance; an2: stripe ratchet, hat count, hands up, sparkle;
// an3: 1 = too large to have a face, holding the laugh in, hat pulse, hat count (whole)
vec3 tyDraw(vec2 t,float px,TyL Y,float laugh,float hs,mat3 CA,mat3 CB,vec3 mouthC,vec4 an,vec4 an2,vec4 an3,float mo,float dmE,out float ink,out float fab){
  float wf=clamp(.011,.6*px,4.*px*uRes.y/700.),fd=1.-smoothstep(.02,.05,px),fd2=1.-smoothstep(.008,.02,px),fp=1.-smoothstep(.03,.07,px);
  float fg=1.-smoothstep(.0,.8,mo);
  ink=0.;fab=1.;
  vec3 col=CA[1];
  float sx=abs(t.x),sd=t.x<0.?-1.:1.;
#if HD>=1
  // the enamel is engraved: a fine hatch in the tunic, a second one across it from Cinema up, a row of stitches inside the outline
  {float hw2=clamp(.0035,.5*px,.006),e1=abs(fract((t.x+t.y)*26.)-.5)/26.,k1=TYA(e1-hw2)*(1.-smoothstep(.006,.014,px));
   col*=1.-.16*k1;
#if HD>=2
   float e2=abs(fract((t.x-t.y)*26.+.5)-.5)/26.;col*=1.-.1*TYA(e2-hw2)*(1.-smoothstep(.005,.011,px));
#endif
  }
#endif
  if(t.y<Y.hem+.05&&fg>0.){
    vec3 lc=col;float li=0.;
    if(Y.legs==0){
      // long striped stockings either side of the hat below, boots with a cuff
      lc=mix(CB[2],CA[0],mix(.5,step(.5,fract(t.y*7.5+.2+an2.x*sd)),fp));
      float db=t.y-.17-.03*(.5-sx);lc=mix(lc,CB[0],TYA(db));li=max(li,TYA(abs(db)-wf));
#if HD>=1
      float dc=abs(t.y-.2-.03*(.5-sx))-.028;lc=mix(lc,CB[2],TYA(dc)*fd);li=max(li,TYA(abs(dc)-wf*.8)*fd);
#endif
    }else if(Y.legs==1){
      // short legs on a floor: striped stockings, a pair of boots with turned-up toes
      float bh=.42*Y.hem;
      lc=mix(CB[2],CA[0],mix(.5,step(.5,fract(t.y/Y.hem*2.6+.1+an2.x*sd)),fp));
      float db=t.y-bh-.25*bh*smoothstep(.2,.02,sx);lc=mix(lc,CB[0],TYA(db));li=max(li,TYA(abs(db)-wf));
#if HD>=1
      float dq=length(vec2(sx-.4,t.y-bh*.55))-bh*.3;lc=mix(lc,CB[1],TYA(dq)*fd);li=max(li,TYA(abs(dq)-wf*.8)*fd);
#endif
      li=max(li,TYA(sx-wf*.9));
    }else if(Y.legs==2){
      lc=mix(CB[2],CA[0],step(.5,fract(t.y*6.+.2+an2.x)));
    }
    col=mix(col,lc,fg);ink=li*fg;
  }
  // tunic hem: a zigzag over the legs
  if(Y.legs<3){float hem=t.y-Y.hem-.035*abs(fract(t.x*6.)-.5)*2.;float m=TYA(-hem);col=mix(col,CA[1],m);ink=max(ink*(1.-m),TYA(abs(hem)-wf)*fg);}
  // collar: a ruff of points under the chin
  {vec2 c=t-Y.hc;float a=atan(c.x,-c.y),r=length(c);float dc=r-Y.hr*(1.34+.28*an2.z+(.2+.25*an2.z)*abs(fract(a*2.2)-.5)*2.)*step(abs(a),1.25);
   col=mix(col,CB[2],TYA(dc)*fg);ink=max(ink,TYA(abs(dc)-wf)*fg*step(abs(a),1.25));}
  // belly cog: as the figure turns into a block the cog grows to fill the tile. Each of its five windows has a small face looking out.
  {vec2 bc=mix(Y.bc,vec2(0.,.62),mo);float br=mix(Y.br,.44,mo)*(1.+(.28*uP3.y+.14*uP2.w)*(1.-mo));
   float bl=smoothstep(.45,.8,laugh),ca=an.x+.13*bl*sin(uTime*17.+hs*9.);
   vec2 b=(t-bc)/br;float r=length(b),a0=atan(b.y,b.x),a=a0+ca;
   float rg=.86+.12*clamp(cos(a*9.)*2.5,-1.,1.),dg=(r-rg)*br;
   float ah=mod(a+PI/5.,TAU/5.)-PI/5.;vec2 wv=r*vec2(cos(ah),sin(ah))-vec2(.52,0.);float dh=(length(wv)-.17)*br,dhub=(r-.24)*br;
   // when the cog is the whole tile it sits in a brass frame
   {float mf=TYA(dmE-.075)*mo;col=mix(col,CB[1],mf);ink=max(ink,TYA(abs(dmE-.075)-wf)*mo);
#if HD>=1
    col=mix(col,CB[2],mf*TYA((length(fract(t*6.)-.5)-.17)/6.)*fd);
#endif
   }
   col=mix(col,mix(CB[2],vec3(1.,.97,.8),.5),TYA(dh)*TYA(dg)*min(an2.w*1.2+.5*uHat,1.));
   float m=TYA(max(dg,-dh));col=mix(col,CB[1],m);fab*=1.-TYA(dg)*(1.-mo);
   col=mix(col,CB[1]*.7,TYA(dhub));
#if HD>=1
   float dsl=max(abs(b.x*cos(ca*2.)+b.y*sin(ca*2.))-.035,r-.15)*br;
   col=mix(col,CB[2],TYA((r-.1)*br)*fd);
   ink=max(ink,max(TYA(abs(dg)-wf),max(TYA(abs(dh)-wf*.8)*fd,max(TYA(abs(dhub)-wf*.8),TYA(dsl)*fd)*fd)));
#else
   ink=max(ink,max(TYA(abs(dg)-wf),max(TYA(abs(dh)-wf*.8)*fd,TYA(abs(dhub)-wf*.8)*fd)));
#endif
#if HD>=1
   {float fw=1.-smoothstep(.018,.03,px/br),pw=px/br,wl=min(.8*wf/br,.011),lg=clamp(laugh*1.3+.25+.5*mo,0.,1.);
    float wh=fract(hs*7.13+floor((a+PI/5.)/(TAU/5.))*.377);
    vec3 fc=mix(CA[2],mix(CA[0],CB[0],step(.67,wh)),.45*step(.34,wh));
    float dfc=length(wv)-.128,mw=clamp(.5-dfc/pw,0.,1.)*fw;
    vec2 ev=vec2(wv.x-.035,abs(wv.y)-.052),mc=vec2(wv.x+.03,wv.y);
    float de=mix(length(ev)-.021,max(abs(length(ev+vec2(.012,0.))-.026)-wl,-.012-ev.x),step(.6,lg));
    float dmo=max(length(mc*vec2(1./(.35+.75*lg),1.))-.062,mc.x);
    col=mix(col,fc,mw);col=mix(col,mouthC,clamp(.5-dmo/pw,0.,1.)*mw);
    ink=max(ink*(1.-mw),max(clamp(.5-(abs(dfc)-wl)/pw,0.,1.)*fw*step(dfc,wl),max(clamp(.5-de/pw,0.,1.),clamp(.5-(abs(dmo)-wl)/pw,0.,1.))*mw));}
#else
   {float fw=1.-smoothstep(.018,.03,px/br),pw=px/br,dfc=length(wv)-.128,mw=clamp(.5-dfc/pw,0.,1.)*fw;
    float dft=min(length(vec2(wv.x-.035,abs(wv.y)-.052))-.022,max(length(vec2(wv.x+.03,wv.y))-.062,wv.x+.03));
    float wl=min(.8*wf/br,.011);col=mix(col,CA[2],mw);ink=max(ink*(1.-mw),max(clamp(.5-(abs(dfc)-wl)/pw,0.,1.)*fw*step(dfc,wl),clamp(.5-dft/pw,0.,1.)*mw));}
#endif
#if HD>=1
   // the top end strikes sparks off the teeth
   {float am=mod(a0+an3.w*.9+hs*6.,TAU/3.)-PI/3.;vec2 sv=abs(r*vec2(cos(am),sin(am))-vec2(1.24,0.));
    float st=(max(sv.x,sv.y)+2.6*min(sv.x,sv.y)-.3*an3.z+.03)*br;col=mix(col,vec3(1.,.98,.8),TYA(st)*fd*(1.-mo));}
#endif
#if HD>=1
   // rivets between the windows, a ring of fine teeth round the hub, a planet wheel riding the rim, engraved rings in the brass
   {float ar=mod(a,TAU/5.)-PI/5.;float dv=(length(r*vec2(cos(ar),sin(ar))-vec2(.52,0.))-.045)*br;
    col=mix(col,CB[2],TYA(dv)*fd2);ink=max(ink,TYA(abs(dv)-wf*.6)*fd2);
    float rt=.3+.02*clamp(cos(a*24.-ca*3.)*2.,-1.,1.),dt2=abs(r-rt)*br;ink=max(ink,TYA(dt2-wf*.5)*fd2*step(r,.4));
    float er=abs(abs(r-.78)-.035)*br;col=mix(col,col*.7,TYA(er-wf*.3)*fd2*m);
    vec2 pc=bc+br*1.22*vec2(cos(.7),sin(.7));vec2 pb=(t-pc)/(br*.3);float pr=length(pb),pa=atan(pb.y,pb.x)-ca*3.;
    float pg=(pr-.82-.16*clamp(cos(pa*7.)*2.5,-1.,1.))*br*.3;float pm=TYA(pg)*fd*fg;
    col=mix(col,CB[1]*.85,pm);col=mix(col,CB[2],TYA((pr-.3)*br*.3)*fd*fg);ink=max(ink*(1.-pm),max(TYA(abs(pg)-wf*.7),TYA(abs(pr-.3)*br*.3-wf*.5))*fd*fg);}
#endif
  }
  if(fg>0.){
  vec3 c0=col;float i0=ink;
#if HD>=1
  // a wind-up key in the back, turning with the mechanism; a tool hanging from the belt on the other side
  {float ks=fract(hs*29.3)<.5?-1.:1.;
   if((Y.look&512)!=0&&sd==ks){
     vec2 kc=vec2(ks*(Y.br+.2),Y.bc.y+.02);float cw=max(abs(cos(an.x*1.5)),.22);
     float dst=max(abs(t.y-kc.y)-.017,abs(t.x-kc.x+ks*.07)-.075);
     vec2 kb=vec2(t.x-kc.x-ks*.035,abs(t.y-kc.y)-.05*cw);float dk=(length(kb/vec2(.048,.048*cw))-1.)*.048*cw;
     float dky=min(dst,dk),m=TYA(dky)*fd;col=mix(col,CB[1],m);col=mix(col,c0,TYA(dk+.02)*fd);
     ink=max(ink*(1.-m),TYA(abs(dky)-wf*.8)*fd);fab*=1.-m;
   }
   int tk=(Y.look>>7)&3;
   if(tk>0&&sd==-ks){
     vec2 ta=vec2(-ks*(Y.br+.15),Y.bc.y+.15);float u=ta.y-t.y,v=t.x-ta.x;
     float dtl=max(abs(v)-.018,abs(u-.09)-.09);
     if(tk==1){float rr=length(vec2(u-.22,v));dtl=min(dtl,max(abs(rr-.05)-.024,-max(abs(v)-.024,.22-u)));}
     else if(tk==2){dtl=min(max(abs(v)-.085*(1.-(u-.05)/.2),.05-u),max(abs(v)-.012,abs(u-.27)-.03));
       float fl=fract(an.x*.159);dtl=min(dtl,length(vec2(v,u-.31-.16*fl))-.02*(1.-fl));}
     else dtl=min(dtl,max(abs(u-.22)-.04,abs(v)-.085));
     float m=TYA(dtl)*fd;col=mix(col,tk==2?CB[0]:CB[1],m);ink=max(ink*(1.-m),TYA(abs(dtl)-wf*.8)*fd);fab*=1.-m;
   }}
#endif
  // sleeves from the shoulders to the mittens (shoulders shake with the giggles)
  {float gg=smoothstep(.2,.45,laugh)*(1.-smoothstep(.75,.95,laugh))*.015*sin(uTime*19.+hs*20.);
   vec2 s=vec2(sd*Y.sh.x,Y.sh.y+gg),h=vec2(sd*(Y.hd.x+.03*an2.z),Y.hd.y+.035*an.y*sd+.07*an2.z+gg);
   float da=tySeg(t,s,h)-.085;
   float m=TYA(da);col=mix(col,CB[0],m);
   vec2 dv=h-s;float dl=length(dv);float st=dot(t-s,dv)/(dl*dl);
   col=mix(col,CB[0]*.6,m*step(.5,fract(st*3.5-an2.x))*fp);
   ink=max(ink*(1.-m),TYA(abs(da)-wf));
   vec2 hp=h+dv/dl*.06;
   float dh=length(t-hp)-.11*(1.+.3*an2.z);m=TYA(dh);col=mix(col,CA[2],m);ink=max(ink*(1.-m),TYA(abs(dh)-wf));fab*=1.-m;
   float dcf=abs(st-.86)-.07;col=mix(col,CB[2],TYA(max(da,dcf))*fd);
  }
  // head: thrown back when the laugh takes it, rolling from side to side when it cannot stop, shaking when it is held in
  {float ti=.5*an.z+1.3*smoothstep(.86,1.,laugh)*sin(uTime*7.+hs*40.),cs=cos(ti),sn=sin(ti);
   vec2 f0=t-Y.hc-vec2(.0,(.03*abs(an.z)-.2*uP2.w)*Y.hr/.195)-.009*an3.y*vec2(sin(uTime*23.+hs*30.),cos(uTime*19.+hs*11.));
   vec2 f=vec2(cs*f0.x+sn*f0.y,-sn*f0.x+cs*f0.y)/(Y.hr/.195);float pf=px/(Y.hr/.195);
   float se=f.x<0.?-1.:1.;int fv=(Y.look>>5)&3;
   float de=tySeg(f,vec2(se*.16,.0),vec2(se*.31,.075))-mix(.06,.012,clamp((abs(f.x)-.16)/.15,0.,1.));
   float m=TYF(de);col=mix(col,mix(CA[2],CA[0],.2),m);ink=max(ink*(1.-m),TYF(abs(de)-wf));fab*=1.-m;
   float dhd=length(f)-.195;m=TYF(dhd);fab*=1.-m;
   col=mix(col,CA[2],m);ink=max(ink*(1.-m),TYF(abs(dhd)-wf));
   if(dhd<.02){
     float open=clamp(.2+.8*laugh,0.,1.)*(1.-.9*an3.y);
     float blink=an3.z*step(fract(hs*3.3+an3.w*.371),.34);
     float shut=max(max(smoothstep(.3,.6,laugh),smoothstep(.25,.6,uHit)),max(an3.y,smoothstep(.3,.6,blink)));
     col=mix(col,mix(CA[2],CA[0],.5+.3*an2.z+.3*an3.y),TYF(length(vec2(abs(f.x)-.125,f.y+.03))-.036*(1.+.6*an2.z+.8*an3.y))*fd);
     vec2 ev=vec2(abs(f.x)-.075,f.y-.05);
     float gz=1.+(fract(hs*41.3)-.5)*.5*se;
     float dey=length(ev)-.048*gz;
     float gx=an.w+(fract(hs*13.7)-.5)*1.5*(1.-abs(an.w));
     col=mix(col,CB[2],TYF(dey)*(1.-shut));col=mix(col,vec3(.01,.005,.03),TYF(length(ev-vec2(.008,-.008)+.014*vec2(-se*gx,0.))-.023*gz)*(1.-shut));
#if HD>=1
     col=mix(col,vec3(1.),TYF(length(ev-vec2(-.008,.014))-.009)*(1.-shut)*fd);
#endif
     ink=max(ink,TYF(abs(dey)-wf*.8)*(1.-shut));
     float da=max(abs(length(ev+vec2(0.,.024))-.047)-wf,-(ev.y+.024));ink=max(ink,TYF(da)*shut);
     // spectacles, or a monocle on one eye
#if HD>=1
     if(fv==1||(fv==2&&se>0.)){float dg=abs(length(ev)-.068)-wf*.9;ink=max(ink,TYF(dg)*fd);
       if(fv==1)ink=max(ink,TYF(max(abs(f.y-.055)-wf*.8,abs(f.x)-.012))*fd);}
#endif
     vec2 mc=vec2(f.x,f.y+.045);float mr=.078+.042*open,sq=.38+.82*open,dm=max(length(mc*vec2(1.,1./sq))-mr,mc.y);
     float inm=TYF(dm);col=mix(col,mouthC,inm);
     float tb=-mc.y-.022-.008*open;col=mix(col,CB[2],inm*TYF(tb));
#if HD>=1
     col=mix(col,mix(mouthC,CA[0],.6)+.12,inm*TYF(length(mc+vec2(0.,mr*sq))-mr*.6)*fd);
#endif
     // the lower teeth come up on every tick of the hats: chattering
     {float tb2=mc.y+mr*sq*(1.-.6*an3.z)-.014;col=mix(col,CB[2],inm*TYF(tb2)*step(.3,open)*fd);ink=max(ink,inm*TYF(abs(tb2)-wf*.5)*step(.3,open)*fd*an3.z);}
#if HD>=1
     ink=max(ink,inm*TYF(abs(fract(f.x*20.+.5)-.5)/20.-wf*.4)*TYF(tb)*fd2);
#endif
     ink=max(ink,TYF(abs(dm)-wf));
#if HD>=1
     float dn=fv==3?tySeg(f,vec2(0.,.012),vec2(.085*(hs<.5?-1.:1.),-.012))-.02:length(f-vec2(0.,.008))-.024;
#else
     float dn=length(f-vec2(0.,.008))-.024;
#endif
     col=mix(col,mix(CA[2],CA[0],.45),TYF(dn)*fd);ink=max(ink,TYF(abs(dn)-wf*.7)*fd);
#if HD>=1
     if(fv==2){float du=length(vec2(abs(f.x)-.055,(f.y+.02)*1.8))-.046;float mu=TYF(du)*fd;col=mix(col,CB[2],mu);ink=max(ink*(1.-mu),TYF(abs(du)-wf*.7)*fd);}
#endif
     if((Y.look&4)!=0){
       // a beard: a bib of points under the grin
       float bd=max(length(vec2(f.x,(f.y+.1)*.8))-.2+.03*abs(fract(f.x*9.)-.5),f.y+.03+.05*open-.9*f.x*f.x);
       float mb=TYF(bd)*(1.-inm);col=mix(col,CB[2],mb);ink=max(ink*(1.-mb),TYF(abs(bd)-wf)*(1.-inm));
     }
     // crying with it: two streams down the cheeks
     {float cr2=smoothstep(.66,.85,laugh);col=mix(col,vec3(.25,.8,1.),TYF(max(abs(abs(f.x)-.118)-.012,abs(f.y+.06)-.07))*cr2*fd);}
   }
   // (a figure too large to have a face keeps a plain head; the small figures on it cover it as they wake)
   {float hm=TYF(dhd+1.5*wf)*an3.x;col=mix(col,CA[2],hm);ink*=1.-hm;}
   // tears of laughter fly off either side
   {float tl=smoothstep(.42,.85,laugh);
    if(tl>0.){vec2 tp=vec2(abs(f.x)-.25-.07*tl,f.y-.06-.1*tl*tl);
#if HD>=1
     float dtr=min(length(tp)-.03*tl,length(tp-vec2(.07,.11))-.019*tl);
#else
     float dtr=length(tp)-.03*tl;
#endif
     float mt2=TYF(dtr)*fd;col=mix(col,vec3(.25,.8,1.),mt2);
#if HD>=1
     col=mix(col,vec3(1.),TYF(length(tp-vec2(-.008,.01))-.009)*fd*tl);
#endif
     ink=max(ink*(1.-mt2),TYF(abs(dtr)-wf*.8)*fd);fab*=1.-mt2;}}
  }
  // hat: everything above the brim in the column under the tip
  {float hl=Y.tip.y-Y.yb,tt=(t.y-Y.yb)/hl;float ax=mix(Y.hc.x,Y.tip.x,tt*tt);
   float hw=mix(Y.hw,0.,clamp(tt,0.,1.))+.02;
   float dh=max(Y.yb-t.y,abs(t.x-ax)-hw-3.*step(Y.hy1,t.y));
   float m=TYA(dh);
   int hk=Y.look&3;float ux=(t.x-ax)/max(hw,.03);
   // (the pattern on the hat ratchets: half a stripe on every hat and on every tick of the mechanism; it never scrolls)
   float hp2=an2.y*.25+an2.x;
   float pat=hk==0?step(.5,fract(tt*4.+.25-hp2)):hk==1?step(.5,fract(tt*3.+abs(ux)*.45+.2-hp2)):hk==2?step(length(vec2(fract(ux*1.1+.5*floor(tt*4.2)+hp2)-.5,fract(tt*4.2)-.5)),.27+.1*an2.w):step(.5,fract(tt*2.5-ux*.6+.2-hp2));
   vec3 h2c=hk==2?CB[1]:hk==1?CB[1]*.8:hk==3?CB[0]*.55:CB[0];
   // (the second colour of a hat is another enamel or brass, never cream; the highs push it brighter, not paler)
   vec3 hcol=mix(CA[0],mix(h2c,min(h2c*1.7+.12,1.),an2.w),mix(.4,pat,fp)*step(.16,tt));
   float rcf=(Y.look&16384)!=0?1.:0.;
   hcol=mix(mix(hcol,CA[0],rcf),mix(CB[0],vec3(1.,.96,.9),rcf),step(tt,.16));
   // the tip: a bobble, a bell that swings on the hats, a star, a little cog
#if HD>=1
   int tp=(Y.look>>10)&3;vec2 tv=t-Y.tip+vec2(.03*an.y*(tp==1?1.:0.),.035);float rp=.05*(1.+.5*an2.w+.5*min(uHat,1.));
   float dp=tp==2?max(abs(tv.x),abs(tv.y))+1.7*min(abs(tv.x),abs(tv.y))-rp*1.6:(tp==3?length(tv)-rp*(1.+.22*clamp(cos(atan(tv.y,tv.x)*6.+an.x*2.)*2.,-1.,1.)):length(tv)-rp);
   hcol=mix(hcol,mix(mix(CB[1],vec3(1.,.97,.92),rcf),vec3(1.,.98,.8),max(an2.w,an3.z*(tp==1?1.:.4))),TYA(dp));
#else
   vec2 tv=t-Y.tip+vec2(.03*an.y,.035);float rp=.05*(1.+.5*an2.w+.5*min(uHat,1.)),dp=length(tv)-rp;
   hcol=mix(hcol,mix(mix(CB[1],vec3(1.,.97,.92),rcf),vec3(1.,.98,.8),max(an2.w,an3.z)),TYA(dp));
#endif
#if HD>=1
   hcol=mix(hcol,vec3(1.),TYA(length(tv+vec2(.015,-.015))-.014)*fd);
#endif
   col=mix(col,hcol,m);fab=mix(fab,1.,m);
   ink=max(ink*(1.-m),TYA(abs(dh)-wf));
   ink=max(ink,m*TYA(abs(tt-.16)*hl-wf*.8));
   ink=max(ink,m*TYA(abs(dp)-wf*.8));
#if HD>=1
   ink=max(ink,m*TYA(max(abs(tv.y+.012)-wf*.6,abs(tv.x)-rp*.65))*fd*(tp==1?1.:0.));
#endif
#if HD>=1
   if((Y.look&8)!=0){
     // a toadstool badge on the band
     vec2 b=vec2(t.x-ax,t.y-Y.yb-.08*hl)/(.42*.16*hl);float dc=max(length(b-vec2(0.,-.1))-.8,-.1-b.y),ds=max(abs(b.x)-.26,abs(b.y+.5)-.42);
     col=mix(col,CB[2],m*TYA(ds*.42*.16*hl)*fd);col=mix(col,CA[0],m*TYA(dc*.42*.16*hl)*fd);
     col=mix(col,CB[2],m*TYA((length(vec2(abs(b.x)-.36,b.y-.25))-.15)*.42*.16*hl)*fd2);
     ink=max(ink,m*TYA(abs(min(dc,ds))*.42*.16*hl-wf*.7)*fd);
   }else{float bk=max(abs(t.x-ax)-.04,abs(tt-.08)*hl-.03);col=mix(col,CB[1],m*TYA(bk)*fd);ink=max(ink,m*TYA(abs(bk)-wf*.7)*fd);}
#else
   {float bk=max(abs(t.x-ax)-.04,abs(tt-.08)*hl-.03);col=mix(col,CB[1],m*TYA(bk)*fd);ink=max(ink,m*TYA(abs(bk)-wf*.7)*fd);}
#endif
  }
#if HD>=1
  // glints on the head and the mittens, stitches inside the outline
  {vec2 g=t-Y.hc;float gr=length(g),ga=atan(g.y,g.x);float dgl=max(abs(gr-Y.hr*.8)-Y.hr*.035,abs(ga-2.35)-.32);col=mix(col,vec3(1.),.7*TYA(dgl)*fd2*step(gr,Y.hr));
   float st=abs(dmE-.045)-.006;col=mix(col,col*.55,TYA(st)*step(.5,fract((t.x-t.y)*11.))*fd2);}
#endif
#if HD>=1
  // brass stars studded in the cloth: the top end lights them one after another
  {vec2 gs=vec2(2.6,2.2),g=t*gs+hs*7.,gi=floor(g);float gh=h21(gi+hs*31.);
   vec2 dv=abs(fract(g)-.5-.36*(vec2(gh,fract(gh*7.3))-.5))/gs;
   float lit=mod(floor(gh*4.)+an3.w,4.)<.5?an3.z:0.,sr=(.02*fd+.1*an2.w*(.4+.6*fract(gh*9.1))+.075*lit)*step(.55,fract(gh*5.7))-.004;
   float st=max(dv.x,dv.y)+2.5*min(dv.x,dv.y)-sr;col=mix(col,mix(CB[1],vec3(1.),max(an2.w,lit)),TYA(st)*fd*fab);}
#endif
  // the maker's stamp, set in beads
  if(Y.mk.z>0.&&(Y.mq.x>.003||Y.mq.y>.5)){
    int pfm=(Y.look>>12)&3;
    float cw=Y.mq.x>.003?clamp(Y.mk.z/38.,1.45*px,1.9*px):min(Y.mk.z*.5/38.,2.6*px);vec2 mp=(t-Y.mk.xy)/cw+vec2(18.,8.);
    float ms=(Y.look&16)!=0?1.:0.,x1=37.5+9.*ms;
    float pv=max(Y.mq.x,Y.mq.y)*smoothstep(.75,1.3,cw/px);
    float dpl=max(max(-1.5-mp.x,mp.x-x1),abs(mp.y-8.)-9.6)*cw;
    float pm=TYA(dpl)*pv;
    col=mix(col,pfm==0?mouthC*.3:(pfm==1?CB[2]:CB[1]),pm);ink=max(ink*(1.-pm),TYA(abs(dpl)-wf*.7)*pv);fab*=1.-pm;
    float bd=tyPlate(floor(mp)+.5,ms)*clamp(.5-(length(fract(mp)-.5)-.43)*cw/px,0.,1.);
    col=mix(col,pfm==0?mix(CB[2],vec3(1.,.96,.7),Y.mq.x):vec3(.03,.012,.05),bd*pm);
  }
  col=mix(c0,col,fg);ink=mix(i0,ink,fg);
  }
  return col;
}
// how much of its cut an edge at x keeps: 1 the figure, 0 a straight edge (the figure is a plain block), below 0 the cut mirrored
// (the tower stands on its hands). mv: x where the wave of blocks is, y how strong, z the level's own state, w 0 a plain wave,
// +-1 a wave that leaves the figures the other way up behind it (the sign is the way it travels)
float tyAmp(float xw,vec4 mv){
  float d=xw-mv.x,W=smoothstep(1.2,3.2,abs(d));
  return mv.z*mix(1.,mv.w==0.?W:(d*mv.w>0.?W:-W),mv.y);
}
// what an edge is doing right now, found from the edge's own name, so every tile that shares it agrees. id.z: kind of edge
// (0 tower top, 1 tower side, 2 zip hat side, 3 spoke, 4 gnome side); cq: x 1 = the edges dance, 0 = they hold still while the
// figures are in the air; y how hard the outlines tremble with a laugh that is being held in
vec3 tyEA(vec3 id,vec4 mv,vec2 cq){
  // (one return only: fxc cannot keep a loop as a loop when a function called inside it returns early)
  float h=h21(id.xy*3.7+id.z*17.3+5.);
  float kd=id.z;
  float xw=kd<1.5?id.x+(kd<.5?.5:0.):(kd<2.5?id.x*.5+.25:(kd<3.5?id.x*3.:id.x));
  float amp=tyAmp(xw,mv);
  float bi=mod(abs(id.y),8.);vec4 bv=bi<4.?uB1:uB2;float bj=mod(bi,4.);float bl=bj<.5?bv.x:(bj<1.5?bv.y:(bj<2.5?bv.z:bv.w));
  float sx=mod(id.x,2.)<.5?1.:-1.,sy=mod(id.y,2.)<.5?1.:-1.,w1=sin(uP3.w+h*TAU),w2=sin(uP3.w*2.+h*TAU);
  vec3 r=vec3(uP3.x*sx,w2*.5+uP3.z,amp);
  if(kd<.5)r=vec3(uP3.x*sy+.22*w1,.22*uP3.y+.3*bl*bl,amp);
  else if(kd>1.5&&kd<2.5)r=vec3(uP3.x*sx*.7+.3*w1,.5*uP3.y+.5*bl*bl,amp);
  else if(kd>2.5&&kd<3.5)r=vec3(w1*.7+uP3.x,0.,amp);
  r.xy*=cq.x;
  r.x+=cq.y*.14*sin(uTime*21.+h*40.);
  return r;
}
// a ring of laughter starts here (packed: quarter tiles either side of the level's own middle)
vec2 tyWp(float v){float a=floor(v+.5),y=floor(a/4096.);return (vec2(a-y*4096.,y)-2048.)*.25;}
// who stands on cell c of the tower after nH sideways exchanges and nV exchanges of rows. Sideways the figures weave: those that
// began on even squares always go one way, the others the other way, and the rows take turns (every other row moves while the rows
// between stand still), so a row has moved cn times; rows pass through each other the same way.
// Returns the figure's first square (x mod 128, y mod 256) and in .z how often its row has moved
vec3 tyOrg0(vec2 c,float nH,float nV){
  float y0=mod(c.y+nV,2.)<.5?c.y-nV:c.y+nV;
  float cn=mod(y0,2.)<.5?ceil(nH*.5):floor(nH*.5);
  float x0=mod(c.x-cn+y0,2.)<.5?c.x-cn:c.x+cn;
  return vec3(mod(x0,128.),mod(y0,256.),cn);
}
// one level of the tessellation. X: tile coordinates, px: the same units per pixel. fm: family and switches, exchanges so far, drift.
// hub>0: this pixel is in the mainspring at the pole of a ring layout (X is then hub coordinates).
// lv: x 1 = a level of the flat plane (the one the director names can have its figures leave their tiles), y how much of the cut this
// pixel keeps (the band of blocks beside a seam), z how much of a giant's outline is left (it thins away, it never greys), w 1 = this
// figure is too large to have a face
// own: how far the figures of this level have come out of the print on the level above: each wakes whole, one after another.
// ex: x the outline's share of the ink, y 1 where this figure has woken into its own colours
vec3 tyLevel(vec2 X,float px,vec4 fm,float th,float thL,int pl,vec3 T,float wT,float own,float hub,vec4 lv,out float ink,out float fab,out vec2 ex){
  int code=int(fm.x+.5),fam=code&3,sn=(code>>20)&3;
  float awB=float((code>>3)&63)/63.,awA=float((code>>9)&63)/63.;
  int cwT=(code>>15)&3,lookB=(code>>17)&7;
  int mq=int(fm.y+.5);float morph=float(mq&255)/255.,nH=float((mq>>8)&255),nV=float((mq>>16)&255);
  int mc=int(uP5.y+.5),mty=(mc>>12)&7,mst=(mc>>15)&7;
  bool act=((mc>>18)&3)==sn;
  float mu=float(mc&4095)/4095.,calm=act?float((mc>>20)&15)/15.:0.;
  float ampS=((code>>22)&1)!=0?-1.:1.,wmode=0.;
  if(act){float aA=uM2[1][1];ampS=mod(aA,4.)-1.;wmode=mod(floor(aA/4.),2.)*(aA>=8.?1.:-1.);}
  if(fam!=0)ampS=abs(ampS);
  vec4 mv=vec4(uM2[1][2]+fm.z,morph,ampS,wmode);
  int rvc=int(uP5.z+.5);float chn=float(rvc&63)/63.,hyst=float((rvc>>12)&63)/63.*1.6;
  float sup=smoothstep(.2,.55,uTension);
  vec2 cq=vec2(1.-calm,sup*(1.-calm));
  float dm=1e3,dmS=1e3,sA=0.,sR=0.;
  vec2 fO=vec2(0.),tq=vec2(0.);float fS=1.;vec2 cell=vec2(0.);
  vec2 EA[5],EB[5];int ET[5];float ES[5];vec3 EI[5];
  vec3 eT=vec3(0.,0.,9.),eB=vec3(0.,0.,9.);
  TyL Y;
  bool star=false;float rim=1e3,sub=0.,xw=0.;
  // --- frames
  vec2 Xl=X;float h1=1.2,hh=.85,S=2.*h1+hh,kS=0.,sl=0.;
  float nW=8.,dW=TAU/nW,Rw=.5*(1.-.04*uP2.w),sgw=1.,angW=0.;vec2 cw=vec2(0.),uW=vec2(0.);
  if(fam==1){kS=floor(X.y/S);sl=mix(th,thL,h11(kS*7.3+2.))*(mod(kS,2.)<.5?1.:-1.);Xl=vec2(X.x-sl,X.y-kS*S);}
  if(fam==2){
    X/=3.;px/=3.;
    cw=floor(X+.5);vec2 v=X-cw;float r=length(v);
    if(r<Rw){
      float pr=mod(cw.x+cw.y,2.);sgw=1.-2.*pr;angW=sgw*mix(th,thL,h21(cw*1.7+3.))+pr*.5*dW;
      float cs=cos(angW),sn2=sin(angW);uW=vec2(cs*v.x+sn2*v.y,-sn2*v.x+cs*v.y);
      rim=Rw-r;sR=atan(v.y,v.x)*Rw;
    }else star=true;
  }
  // figures in the air are looked for first (the largest level only), then the tiles under them
  int ns=0;
  if(lv.x>.5&&act&&mty>0&&fam<2)ns=fam==0?15:8;
  int nc=fam==0?9:(fam==1?6:3);
  if(hub>0.){nc=0;ns=0;star=false;}
  bool spr=false;float sS=1.;
  if(!star)for(int ci=TY0;ci<ns+nc;ci++){
    bool sp=ci<ns;int cj=sp?ci:ci-ns;
    float par=0.,d=1e3,dS=1e3,s1=0.,s2=0.,scl=1.;int ne=4;
    vec2 q=Xl;bool skip=false;
    if(fam==0){
      vec2 c0=floor(vec2(X.x,X.y/TY_H)),cc,Xc=X;
      {int c5=cj/5;float i5=float(cj-c5*5)-2.,j3=1.-float(c5);
       vec2 o=cj==0?vec2(0.):cj==1?vec2(0.,-1.):cj==2?vec2(-1.,0.):cj==3?vec2(1.,0.):cj==4?vec2(0.,1.):cj==5?vec2(-1.,-1.):cj==6?vec2(1.,-1.):cj==7?vec2(-1.,1.):vec2(1.,1.);
       cc=c0+(sp?(mty==2?vec2(j3,i5):vec2(i5,j3)):o);}
      vec3 o3=tyOrg0(cc,nH,nV);
      if(sp){
        vec2 Cc=vec2(cc.x+.5,cc.y*TY_H+.65+.2*ampS),dd=vec2(0.);float ang=0.;
        float rm=mod(cc.x-o3.z+o3.y,2.)<.5?1.:-1.,um=mod(cc.y+nV,2.)<.5?1.:-1.,mvr=mod(o3.y+nH,2.)<.5?1.:0.;
        float u1=mu;
        if((mst&4)!=0){float pk=mty==2?cc.x:(rm>0.?cc.x:cc.x-1.)+3.*cc.y;u1=clamp(mu*2.-fract(pk/8.),0.,1.);}
        float e=u1*u1*(3.-2.*u1),arc=4.*e*(1.-e);int st=mst&3;
        if(mty==1){
          // neighbours change places: one leaps over with a somersault while the other slides under; both roll; they pass
          // through each other; both flip
          bool lead=(mod(o3.z,2.)<.5)==(rm>0.);
          float hop=st==0?(lead?.62:0.):(st==1?.1:(st==2?0.:(lead?.7:.34)));
          float rt=st==0?(lead?1.:0.):(st==2?0.:1.);
          float stay=(1.-mvr)*arc;e*=mvr;arc*=mvr;
          dd=vec2(rm*e,hop*arc+.11*stay);ang=-rm*rt*TAU*e;scl=1.-(st==2&&!lead?.16:.08)*arc-.05*stay;
        }else if(mty==2){
          // rows change places: each figure climbs round the one above while that one comes down the other side
          float sw2=um*(mod(cc.x,2.)<.5?1.:-1.);
          dd=vec2(.4*sw2*arc,um*TY_H*e);ang=st==0?0.:-sw2*TAU*e;scl=1.-.1*arc;
        }else{
          // a somersault on the spot: everyone, or one half of the board and then the other
          float ev2=mod(cc.x+cc.y,2.)<.5?1.:-1.,on=st==0?1.:((ev2>0.)==(st==1)?1.:0.);
          dd=vec2(0.,.42*arc*on);ang=ev2*TAU*e*on;scl=1.-.1*arc*on;
        }
        vec2 w=X-Cc-dd;
        if(dot(w,w)>1.12*scl*scl)skip=true;
        float cs=cos(ang),sn2=sin(ang);
        Xc=Cc+vec2(cs*w.x+sn2*w.y,-sn2*w.x+cs*w.y)/scl;
      }
      q=Xc-vec2(cc.x,cc.y*TY_H);
      EA[0]=vec2(0.);EB[0]=vec2(1.,0.);ET[0]=1;ES[0]=1.;EI[0]=vec3(cc,0.);
      EA[1]=vec2(0.,TY_H);EB[1]=vec2(1.,TY_H);ET[1]=1;ES[1]=1.;EI[1]=vec3(cc+vec2(0.,1.),0.);
      EA[2]=vec2(0.);EB[2]=vec2(0.,TY_H);ET[2]=2;ES[2]=-1.;EI[2]=vec3(cc,1.);
      EA[3]=vec2(1.,0.);EB[3]=vec2(1.,TY_H);ET[3]=2;ES[3]=-1.;EI[3]=vec3(cc+vec2(1.,0.),1.);
      vec2 og=o3.xy;
      cell=og;fO=vec2(cc.x+.5,cc.y*TY_H);fS=1.;tq=q-vec2(.5,0.);sub=mod(og.x+og.y,2.);xw=cc.x+.5;
      eT=EI[1];eB=EI[0];
    }else if(fam==1){
      vec2 Xc=Xl;bool up;float i0;
      if(sp){
        // pairs of gnomes (one upright, one head down) turn half round the point between them, like two-bladed gears;
        // next time each turns with its other neighbour, so everyone cartwheels along the strip
        float cz=nH,mvz=1.;
        float pn=mod(cz+1.,2.),ma=floor(2.*Xl.x-.5),mb=ma-mod(ma-pn,2.);
        float m=mb+2.*float(cj/2)-2.;
        vec2 P=vec2(.5*m+.25,.5*S);
        float hm=floor(m*.5),ph=mod(hm,2.),sg2=(ph<.5?1.:-1.)*(mod(kS,2.)<.5?1.:-1.);
        float u1=(mst&1)!=0?clamp(mu*2.-ph,0.,1.):mu,e=u1*u1*(3.-2.*u1)*mvz,arc=4.*e*(1.-e);
        float ang=sg2*PI*e;scl=1.-.17*arc;
        vec2 w=Xl-P;
        if(dot(w,w)>3.7*scl*scl)skip=true;
        float cs=cos(ang),sn2=sin(ang);
        Xc=P+vec2(cs*w.x+sn2*w.y,-sn2*w.x+cs*w.y)/scl;
        float mtl=m+float(cj-(cj/2)*2);
        up=mod(mtl,2.)>.5;i0=up?(mtl-1.)*.5:-mtl*.5;
      }else{
        up=cj<3;if(Xl.y>.5*S)up=!up;
        int ck=cj<3?cj:cj-3;float o=ck==0?0.:(ck==1?-1.:1.);
        i0=floor(up?Xl.x:.5-Xl.x)+o;
      }
      vec2 qq=up?Xc:vec2(.5-Xc.x,S-Xc.y);
      q=qq-vec2(i0,0.);
      float iw=up?i0:-i0;
      float rw=kS*2.+(up?0.:1.);
      EA[0]=vec2(0.);EB[0]=vec2(1.,0.);ET[0]=0;ES[0]=1.;EI[0]=vec3(0.);
      EA[1]=vec2(0.,h1);EB[1]=vec2(.5,h1+hh);ET[1]=3;ES[1]=1.;EI[1]=vec3(2.*iw,kS,2.);
      EA[2]=vec2(1.,h1);EB[2]=vec2(.5,h1+hh);ET[2]=3;ES[2]=-1.;EI[2]=vec3(up?2.*iw+1.:2.*iw-1.,kS,2.);
      EA[3]=vec2(0.);EB[3]=vec2(0.,h1);ET[3]=4;ES[3]=-1.;EI[3]=vec3(up?iw:iw+.5,rw,4.);
      EA[4]=vec2(1.,0.);EB[4]=vec2(1.,h1);ET[4]=4;ES[4]=-1.;EI[4]=vec3(up?iw+1.:iw-.5,rw,4.);
      ne=5;
      // who stands here: places along the strip count in halves (upright figures on the odd ones); those that began on an odd
      // place always travel one way, the others the other way
      float cz2=nH;
      float mp=up?2.*iw+1.:2.*iw,m0=mod(mp-cz2,2.)>.5?mp-cz2:mp+cz2,od=mod(m0,2.);
      cell=vec2(mod(floor(m0*.5),128.)+(od>.5?0.:.37),kS*2.+(od>.5?0.:1.));
      fS=1.;tq=q-vec2(.5,0.);sub=od>.5?0.:1.;xw=up?iw+.5:iw;
      fO=vec2(xw+sl,kS*S+(up?.6:S-.6));
      eT=EI[1];eB=eT;
    }else{
      float a0=atan(uW.x,uW.y),m0=floor(a0/dW+.5)+(cj==0?0.:(cj==1?-1.:1.));
      float am=m0*dW,cs=cos(am),sn2=sin(am);
      q=vec2(cs*uW.x-sn2*uW.y,sn2*uW.x+cs*uW.y);
      float hx=1.25*Rw*sin(.5*dW),hy=1.25*Rw*cos(.5*dW);
      float mi=mod(m0,nW);
      EA[0]=vec2(-hx,hy);EB[0]=vec2(hx,hy);ET[0]=0;ES[0]=1.;EI[0]=vec3(0.);
      EA[1]=vec2(0.);EB[1]=vec2(-hx,hy);ET[1]=5;ES[1]=1.;EI[1]=vec3(cw.x,cw.y*13.+mi*.37,3.);
      EA[2]=vec2(0.);EB[2]=vec2(hx,hy);ET[2]=5;ES[2]=1.;EI[2]=vec3(cw.x,cw.y*13.+mod(mi+1.,nW)*.37,3.);
      ne=3;
      cell=vec2(cw.x*3.+mi,cw.y*5.+mi*2.);
      fS=2.*Rw*sin(.5*dW);tq=vec2(-q.x,Rw-q.y)/fS;fO=cw*3.;sub=0.;xw=cw.x*3.;
      // (eT keeps its first value, z 9 = no top edge. Do NOT assign it here again: with that one redundant assignment fxc
      // gives up on every loop round this one, error X3511 forced to unroll loop, found by bisecting the HLSL in v22)
    }
    if(!skip){
      for(int e=TY0;e<ne;e++){
        bool same=(fam==1&&e>=3)||(fam==2&&e>=1);
        vec3 ea=ET[e]==0?vec3(0.,0.,1.):tyEA(EI[e],mv,cq);
        ea.z*=lv.y;
        vec2 A=EA[e],B=EB[e];float sg=ES[e];
        // a mirrored cut: the same curve on the other side of the edge (the side edges run the other way)
        if(ea.z<0.){ea.z=-ea.z;sg=-sg;if(ET[e]==2){A=EB[e];B=EA[e];}}
        float dd=same?dS:d,sa=same?s2:s1;tyEdge(q,A,B,ET[e],sg,ea,par,dd,sa);if(same){dS=dd;s2=sa;}else{d=dd;s1=sa;}
      }
      if(par>.5||(!sp&&cj==nc-1)){dm=d;dmS=dS;sA=dS<d?s2:s1;spr=sp;sS=scl;break;}
    }
  }
  float hs=h21(cell*1.37+9.1+float(fam)*3.3);
  vec3 mk=vec3(0.);
  float ampT=1.;bool flp=false;int pfm=0;
  float h2=h21(cell*2.31+71.3+float(fam));
  if(star){
    // the plate between four wheels is a figure too: hat up one horn, hands out along two, one pointed stocking down the last
    vec2 s0=floor(X)+.5,w=X-s0;
    for(int j=TY0;j<4;j++){vec2 cn=s0+vec2(j<2?-.5:.5,(j&1)==0?-.5:.5);float rr=length(X-cn)-Rw;if(rr<rim){rim=rr;sR=atan(X.y-cn.y,X.x-cn.x)*Rw;}}
    cell=s0*2.+31.;hs=h21(cell);h2=h21(cell*2.31+71.3+float(fam));fS=.5;tq=w/fS;sub=1.;fO=s0*3.;xw=s0.x*3.;
    mk=vec3(0.,-.31,.3);
    Y=TyL(vec2(0.,.0),.13,.12,.19,vec2(0.,.99),.12,vec2(0.,-.4),.12,vec2(.15,-.12),vec2(.56,-.01),-.6,2,(int(hs*4.)&3)|(int(fract(hs*53.1)*4.)<<5)|(int(fract(hs*71.9)*4.)<<10),vec3(0.),vec2(0.));
  }else if(hub>0.){
    cell=vec2(77.+float(pl)*3.+float(cwT),33.);hs=h21(cell*1.37+9.1+float(fam)*3.3);tq=X;fS=1.;sub=0.;dm=1.-length(X);sA=atan(X.y,X.x);
    // (the mainspring at the pole is a cog with five small faces looking out of its windows: no big face in the middle)
    Y=TyL(vec2(0.,30.),.01,39.,.1,vec2(0.,42.),39.,vec2(0.),.74,vec2(9.,29.),vec2(9.2,29.),-9.,3,0,vec3(0.),vec2(0.));
  }else{
    float aS=tyAmp(xw,mv);flp=aS<0.&&fam==0;
    vec3 eU=flp?eB:eT,aT=eU.z>8.?vec3(0.,0.,1.):tyEA(eU,mv,cq);
    aT.z=abs(aT.z)*lv.y;
    ampT=fam==2?abs(aS)*lv.y:aT.z;
    int lk=(int(hs*8.)&3)|(lookB&4)|(fract(hs*37.7)<.085?8:0)|(int(fract(hs*53.1)*4.)<<5)|(int(fract(hs*71.9)*4.)<<10);
    if(fam<2)lk|=(fract(hs*19.3)<.4?512:0)|(fract(hs*47.3)<.5?(1+int(fract(hs*91.7)*3.))<<7:0);
    pfm=int(fract(h2*5731.)*3.);
    if(fam==0){Y=TyL(vec2(-.02*aT.x,.99),.2,1.135,.235,vec2(.025+.33*aT.x*aT.z,TY_H+.44*(1.+aT.y)*aT.z),TY_H,vec2(0.,.63),.19,vec2(.2,.8),vec2(.37,1.1),.44,0,lk,vec3(0.),vec2(0.));
      mk=pfm==0?vec3(.27,.3,.3):(pfm==1?vec3(.012,1.265,.25):vec3(0.,.63,.21));}
    else if(fam==1){Y=TyL(vec2(0.,.84),.23,1.07,.6,vec2(.0,h1+hh*aT.z),h1,vec2(0.,.36),.19,vec2(.28,.58),vec2(.42,.86),.2,1,lk,vec3(0.),vec2(0.));
      mk=pfm==2?vec3(0.,.36,.2):vec3(0.,1.28,.36);if(pfm==0)pfm=1;}
    else{Y=TyL(vec2(0.,.63),.165,.8,.3,vec2(0.,1.306),.8,vec2(0.,.33),.14,vec2(.17,.5),vec2(.3,.3),.16,1,lk,vec3(0.),vec2(0.));
      mk=vec3(0.,.33,.17);pfm=2;}
  }
  // the stamp: on one figure in three hundred and fifty for good, and for a second or two on the one the music picks
  {vec2 sc=vec2(uM2[2][1],uM2[2][2]);float sy=floor(sc.x/256.),sx2=sc.x-sy*256.;vec2 ic=mod(floor(cell),256.);
   float lit=(lv.x>.5&&fam<2&&!star&&abs(ic.x-sx2)<.3&&abs(ic.y-sy)<.3)?sc.y:0.;
   Y.mk=mk;Y.mq=vec2(lit,h2<.0028?1.:0.);Y.look|=pfm<<12;if(fract(h2*9173.)<.3&&pfm==0)Y.look|=16;}
  // behind a wave of blocks the figures unfold in the next palette
  int pcx=int(uP5.x+.5),plu=pl;
  if(act&&morph>0.&&(xw-mv.x)*(uM2[1][1]>=8.?1.:-1.)<0.)plu=((pcx>>4)&15)%TY_NPAL;
  bool hole=ns>0&&!spr;
  float aw=hole?0.:mix(awA,awB,sub);
  // (a lit stamp needs a figure that is awake)
  if(Y.mq.x>0.&&!hole)aw=max(aw,Y.mq.x);
  int sK=(pcx>>8)&7,hK=(pcx>>11)&7;
  int kk=int(mod(cell.x+2.*cell.y+float(cwT)+(fract(hs*11.3)<.5?float(sK):0.),4.));
  vec3 c1=TYQ[plu*8+1+kk],c2=TYQ[plu*8+1+((kk+2)&3)],c3=TYQ[plu*8+1+((kk+1)&3)],cr=TYQ[plu*8+5],mt=TYQ[plu*8+6],mo=TYQ[plu*8+7];
  // six skins: peach, rose, goblin green, sky, lemon, lilac; a quarter of the fourth enamel folded in so each palette owns them
  int ski=int(fract(hs*23.7)*6.);
  vec3 sk=ski==0?vec3(1.,.5,.24):ski==1?vec3(1.,.3,.4):ski==2?vec3(.42,.78,.14):ski==3?vec3(.2,.6,1.):ski==4?vec3(1.,.76,.08):vec3(.6,.36,1.);
  sk=mix(sk,TYQ[plu*8+1+((kk+3)&3)],.22);
  // (the cog at the pole of a ring layout sits on a deep disc)
  c2*=1.-.6*step(.5,hub);
  // red caps with a white band and a white bobble on about a third of them (that is their thing), every other colour on the rest
  {float rc=step(fract(hs*77.7),.34);c1=mix(c1,vec3(.84,.03,.05),rc);Y.look|=int(rc)*16384;}
  // the negative of a figure (asleep, or the hole a figure has just left): its second enamel pushed deep and pure, never toward grey
  vec3 cN=c2*c2;cN=cN/max(max(cN.r,max(cN.g,cN.b)),.02);
  {float hiF=clamp(max(max(uO2.z,uO2.w),uHat)*(.35+.65*hs)+.5*uB2.w*uB2.w*fract(hs*5.3),0.,1.);
   mt=mix(mt,vec3(1.,.97,.72),.6*hiF);cr=mix(cr,vec3(1.),.4*min(uHit,1.)*(sub<.5?1.:.5));
   c1=min(c1*(1.+.3*min(uKick,1.)*(fract(hs*3.1)<.5?1.:.5)),1.);c1=mix(c1,min(c1*1.5+.14,1.),.7*min(uHat,1.)*(fract(hs*17.)<.6?1.:.25));c3=mix(c3,min(c3*2.+.14,1.),max(uB2.x,uB2.y)*max(uB2.x,uB2.y));c2=min(c2*(.6+.55*min(uP3.y,1.)),1.);sk=mix(sk,min(sk*1.25,1.),uB2.x*uB2.x);}
  // (own + 4 where the giant under this pixel is skin, mitten or brass: there the small figures keep their own tunics, so a giant's head
  // and hands dissolve into many-coloured figures and never stand as one pale disc)
  float nf=step(3.5,own);own-=4.*nf;
  float hw3=fract(hs*61.7),oi=wT>0.?smoothstep(hw3-.05,hw3+.05,min(own,1.)*1.1-.05):1.;
  if(wT>0.){
    // a figure on a larger figure wears that figure's colour: its own enamels fold toward the enamel under it
    float tmx=max(T.r,max(T.g,T.b)),tmn=min(T.r,min(T.g,T.b));
    // small, it is a print in that enamel (two tones of it, never a blend of two colours); as the giant grows past the frame the
    // printed figures wake one by one, each whole and at once, into their own colours
    float sat=smoothstep(.15,.6,(tmx-tmn)/max(tmx,.05));vec3 Tb=T+.03,Td=mix(Tb*Tb*1.1,Tb*.7,.7);
    // (awake, a small figure still wears the giant's colour in its tunic: the giant's hat, sleeves, tunic and head stay coloured masses
    // made of small figures, each with its own hat and face)
    float wA=wT*(1.-oi),wB=wA,wC=wA,wD=max(wA,wT*(1.-clamp(own-1.,0.,1.))*(1.-nf));
    c1=mix(c1,Td,wA);c3=mix(c3,mix(Tb,Td,.5),wB);sk=mix(sk,min(Tb*1.2+.04*sat,1.),wC);mt=mix(mt,Tb*1.08,wB);cr=mix(cr,min(Tb*1.25+.05,1.),wC);mo=mix(mo,Td*.7,wC);
    c2=mix(c2,Tb,wD);c3=mix(c3,Tb*.72,wD-wA);cN=mix(cN,Tb,wD);
  }
  // laughter. Every kick opens the mouths; a snare (or a note) starts a ring that runs out across the plane from one figure; and
  // the fit itself spreads: it starts in a few places and takes the figures round them as it grows, until everyone has it
  float lw=0.,ldir=0.;
  for(int j=TY0;j<2;j++){vec2 wc=fm.zw+tyWp(j==0?uP4.x:uP4.z);float wa=j==0?uP4.y:uP4.w;vec2 dv=fO-wc;float dd=length(dv)-wa*3.4,g=exp(-dd*dd*1.1)*exp(-wa*.6)*step(0.,wa);if(g>lw){lw=g;ldir=dv.x<0.?-1.:1.;}}
  vec2 gq=fO/7.+vec2(uSection*.37+3.,uSection*.61);vec2 gi=floor(gq);
  float thr=.12+1.25*length(fract(gq)-.5-.3*(vec2(h21(gi),h21(gi+7.7))-.5));
  float Lb=clamp((hyst*1.3-thr)*1.6,0.,1.);
  float laugh=clamp(.06+Lb+(.25+.3*Lb)*uP2.w+lw,0.,1.)*(1.-.85*sup)*(1.-lv.w);
  float mo1=1.-ampT;
  vec4 an=vec4((th+hs*6.)*(fam==2?2.:1.)+uP3.w*.3,uP3.z,(lw*.9+.25*uP2.w+.55*smoothstep(.45,.75,laugh))*(hs<.5?-1.:1.),ldir*step(.05,lw));
  float fi=0.;
  if(rim<min(dm,dmS))sA=sR;
  dm=min(dm,rim);
  float prs=max(uB2.x,uB2.y),hiL=max(uB2.z,uB2.w);
  // stripes ratchet (they do not scroll): a quarter of a stripe a hat and at a rate the mids set; hat patterns also on every tick of the
  // mechanism. Hands and collars fly up with the
  // presence band and on every onset of the mids
  vec4 an2=vec4(.25*float(hK+((pcx>>14)&7))*(fract(hs*5.7)<.5?1.:-1.),float(hK)*(fract(hs*17.)<.6?1.:0.)+2.*floor(th/(fam==2?.7854:1.)+.5),max(prs*prs,.8*max(uO1.z,uO1.w)),clamp(hiL*hiL*1.3,0.,1.));
  vec4 an3=vec4(lv.w,sup,clamp(uHat*1.3,0.,1.),float(hK));
  an2.w*=1.-step(.5,hub);
  vec2 tqd=tq;if(flp)tqd.y=TY_H-tqd.y;
  vec3 col=tyDraw(tqd,px/(fS*sS),Y,laugh,hs,mat3(c1,c2,sk),mat3(c3,mt,cr),mo,an,an2,an3,(star||hub>0.)?0.:(hole?1.:mo1),min(dm,dmS)/fS,fi,fab);
  // asleep, a tile is its own negative: deep enamel, the drawing in bright wire. So is the hole a figure has just jumped out of.
  if(aw<.999){float lm=dot(col,vec3(.3,.5,.2));
   vec3 nb=cN*(.66+.3*smoothstep(.1,.7,lm));
   vec3 neg=mix(nb,min(mix(cr,mt,.5)*1.1,1.),fi);
   col=mix(neg,col,smoothstep(.3,.9,aw));fi*=mix(.0,1.,smoothstep(.2,.8,aw));}
  float wb=clamp(.02*fS,.6*px,7.*px*uRes.y/700.)*lv.z;
  float awO=max(awA,awB),dO=min(dm,dmS)*sS;
  float io=max(clamp(.5-(dm*sS-wb)/px,0.,1.)*mix(.4,1.,awO),clamp(.5-(dmS*sS-wb)/px,0.,1.)*mix(.35,1.,max(aw,hole?1.:0.)))*smoothstep(0.,.12,lv.z);
  ink=max(fi,io);
  // the highs run a bright wire just inside every outline (the ink itself stays ink)
  {float hiW=max(uB2.z,uB2.w),g=clamp(hiW*hiW*.85+.7*max(uO2.z,uO2.w),0.,1.)*mix(.55,1.,fract(hs*7.7));
   float dw=abs(dO-3.1*wb)-.75*wb;col=mix(col,mix(mt,vec3(1.),.5),clamp(.5-dw/px,0.,1.)*g*aw*(1.-smoothstep(.03,.07,px/fS)));}
  // the outlines themselves turn out to be chains of tiny figures holding hands
#if HD>=1
  {float wc=wb*(1.+2.6*chn),sp=wc*2.5+1e-5,Lc=TAU*Rw;
    sp=(dm<=rim+1e-5&&rim<900.)?Lc/max(1.,floor(Lc/sp+.5)):sp;
    float v=sA/sp,ib=abs(floor(v+.5)),f=(fract(v+.5)-.5)*sp,f2=(fract(v)-.5)*sp;
    float dh=length(vec2(f,dO))-wc*.8,hm=clamp(.5-dh/px,0.,1.)*chn;
    float dh2=length(vec2(f2,dO))-wc*.36,hm2=clamp(.5-dh2/px,0.,1.)*chn;
    float t3=mod(ib,3.);vec3 hc=t3<.5?TYQ[plu*8+5]:(t3<1.5?vec3(1.,.5,.24):vec3(.42,.78,.14));
    col=mix(col,TYQ[plu*8+6],hm2);col=mix(col,hc,hm);
    float ie=clamp(.5-(length(vec2(abs(f)-.3*wc,dO))-.15*wc)/px,0.,1.);
    ink=max(ink*(1.-max(hm,hm2)),max(ie*hm,max(clamp(.5-(abs(dh)-.3*wb)/px,0.,1.),clamp(.5-(abs(dh2)-.25*wb)/px,0.,1.))*chn));
  }
#endif
  // small figures carry lighter line work, so a print of them stays colour, not ink
  float lf=mix(1.,.5,smoothstep(.012,.05,px/fS));
  ink*=lf;ex=vec2(io*lf,oi);
  return col;
}
// the layouts: where a pixel is on the plane of tiles, and how many tile units one frame height covers there
vec2 tyLog(vec2 d){return vec2(.5*log(max(dot(d,d),1e-12)),atan(d.y,d.x));}
vec2 tyMap(vec2 z,float lc,float hr,out float J,out float hubR,out vec2 hubP){
  int code=int(lc+.5),lay=code&3,ai=(code>>2)&15;
  float ang=float(ai)*TAU/16.;
  hubR=0.;hubP=vec2(0.);
  const float B=2.5;
  if(lay==0){J=B;return rot(ang)*z*B;}
  // (a ring layout with its pole in the middle and twelve or sixteen figures a ring: one whole figure in every wedge of the
  // kaleidoscope when that is folded twelve or sixteen times)
  bool cen=lay==1&&ai>=12;
  float N0=cen&&ai==13?16.:12.,c=N0/TAU;
  if(lay==1){
    vec2 po=cen?vec2(0.):.12*vec2(cos(ang),sin(ang));vec2 d=z-po,L=tyLog(d);
    J=c/max(length(d),1e-5);hubP=po;hubR=hr;
    return vec2(L.y*c,L.x*c);
  }
  // two poles: the rings pour out of one and into the other
  float a=.62;vec2 dr=vec2(cos(ang),sin(ang)*.6),d1=z-a*dr,d2=z+a*dr;
  vec2 L=tyLog(d1)-tyLog(d2);
  vec2 i1=vec2(d1.x,-d1.y)/max(dot(d1,d1),1e-9),i2=vec2(d2.x,-d2.y)/max(dot(d2,d2),1e-9);
  J=c*length(i1-i2);
  if(dot(d1,d1)<dot(d2,d2)){hubP=a*dr;}else{hubP=-a*dr;}
  hubR=min(hr,.8*a*length(dr));
  return vec2(L.y*c,L.x*c);
}
vec4 tySlot(int s){return s==0?vec4(uM1[0][0],uM1[0][1],uM1[0][2],uM1[1][0]):s==1?vec4(uM1[1][1],uM1[1][2],uM1[2][0],uM1[2][1]):vec4(uM2[0][0],uM2[0][1],uM2[0][2],uM2[1][0]);}
float tyFsc(vec4 fm,int lay){int fq=int(fm.x+.5)&3;return lay==0?(fq==1?1.1:1.):1.;}
// everything for one layout: levels from large to small, each wearing the one above.
// sh: which family leads (0 on this side of a seam, 1 or 2 on the far side); af: how much of the cut this pixel keeps
vec3 tyScene(vec2 p,float lc,int pl,float sh,float af,out float inkA){
  float zm=max(uZoom,.05),D=uP1.w;
  int lay=int(lc+.5)&3;
  float J,hubR;vec2 hubP;
  vec2 z=p/zm/(1.+.018*uP2.w);
  float hst=max(.062,40./uRes.y);
  vec2 Xb=tyMap(z,lc,hst*1.0913/zm,J,hubR,hubP);
  J/=zm;
  // figure height on screen at level 0
  float h0=1.75/J;
  if(lay!=0)D=0.;
  // the largest level is the first whose figures are no taller than 1.6 frames
  float l0f=ceil(D+log(h0/1.6)/log(TY_S));
  if(lay!=0)l0f=max(l0f,0.);
  vec3 T=vec3(0.);float wT=0.;inkA=0.;vec3 col=vec3(0.);
  float hubM=0.,fabP=1.,ownP=0.,inkT=0.,inkO=0.;int plk=pl;
  if(hubR>0.){float rr=length(z-hubP)/hubR;hubM=rr<1.?1.:0.;}
  for(int k=TY0;k<TY_NL;k++){
    float l=l0f+float(k),u=l-D,sc=pow(TY_S,u);
    int slot=int(mod(l+300.+sh,3.));
    vec4 fm=tySlot(slot);
    float th=slot==0?uP1.x:slot==1?uP1.y:uP1.z,thL=slot==0?uP2.x:slot==1?uP2.y:uP2.z;
    float fsc=tyFsc(fm,lay);
    float h=h0/(sc*fsc);
    #if HD>=3
    float vis=smoothstep(.012,.022,h)*smoothstep(44.,52.,h*uRes.y),
#elif HD>=1
    float vis=smoothstep(.03,.055,h)*smoothstep(44.,52.,h*uRes.y),
#else
    float vis=smoothstep(.05,.085,h)*smoothstep(44.,52.,h*uRes.y),
#endif
      // (wave 3) a giant is outlined only while it is a drawn figure: its line thins away over exactly the span in which the elves
      // printed on it wake into their own colours and cover its drawing (.7 to .78 frames). Past that it is a body made of elves and
      // nothing else (colour masses to 1.55): never a rim, spokes or wavy seams drawn over figures that do not show it
      giant=1.-smoothstep(.7,.78,h);
    if(k==0)vis=1.;
    if(k>0&&(vis<=0.||hubM>0.))break;
    if((int(fm.x+.5)&4)!=0&&k>0)break;
    vec2 X=(Xb+(lay!=0?vec2(0.,uM2[2][0]*1.3):vec2(0.)))*sc*fsc+fm.zw;
    float ik,fb;vec3 c;vec2 ex;
    bool hb=hubM>0.;
    // (wave 3: the face goes between .7 and .77, was .72 to .8, with the waking of the elves: no see-through face left over them)
    // no face ever takes the frame: a figure taller than about .7 of the frame loses its face, the figures printed on it wake one
    // by one into their own colours and cover its drawing (a body made of small figures); last its outline thins away
    vec4 lv=vec4(lay==0&&sh<.5?1.:0.,af,k==0?giant:1.,k==0?smoothstep(.7,.77,h):0.);
    c=tyLevel(hb?(z-hubP)/hubR:X,hb?1./(uRes.y*zm*hubR):J*sc*fsc/uRes.y,fm,th,thL,plk,T,hb?0.:wT,k==1?ownP+4.*step(fabP,.5):ownP,hubM,lv,ik,fb,ex);
    if(k==0&&mod(floor(fm.y+.5),256.)>0.&&(X.x-uM2[1][2]-fm.z)*(uM2[1][1]>=8.?1.:-1.)<0.)plk=((int(uP5.x+.5)>>4)&15)%TY_NPAL;
    if(hb){col=c;inkA=ik;break;}
    // (ownP: 0 to 1 the small figures wake; 1 to 2 they stop wearing the giant's colour in their tunics, just before the giant goes)
    // (wave 3: they wake between .7 and .77 of the frame, was .74 to .84; nothing changes below .7, so zoom 1 is as it was: a figure that large with its face going was a frame of
    // plain enamel with tone-on-tone prints, the one framing where colour hid the drawing; now the elves and their lines are there)
    if(k==0){col=c;inkT=ik;inkO=ex.x;inkA=ik;wT=1.;fabP=fb;ownP=smoothstep(.7,.77,h)+smoothstep(1.3,1.55,h);}
    else{float wE=wT*(1.-ex.y);c=mix(c,mix(TYQ[pl*8],T*.58,.88*wE),ik*mix(1.,.72,wE));float al=vis*mix(fabP,1.,ex.y);col=mix(col,c,al);
      if(k==1)inkA=max(inkO,inkT*(1.-vis*ex.y));
      wT=1.;fabP=fb;ownP=0.;}
    T=c;
  }
  return col;
}
void realm(){
  vec2 p0=scr();
  int pc=int(uP5.x+.5)&255;
  int lcode=int(uM1[2][2]+.5),wty=(lcode>>12)&3;
  float la=float(lcode&63),lb=float((lcode>>6)&63),shB=float((lcode>>14)&3),wp=uP5.w;
  float asp=uRes.x/uRes.y,pxs=1.5/uRes.y;
  // sub-pixel samples of the whole picture at the detail tiers: Native 3, Cinema 4, Insane 6, Extreme 8, Offline 14
  int nSS=clamp(int(uDetail*1.5+.2),1,TY_SS);
  vec3 acc=vec3(0.);
  for(int ss=TY0;ss<nSS;ss++){
    float fs=float(ss)+.5,a0=fs*2.399963;
    vec2 p=p0+(nSS>1?vec2(cos(a0),sin(a0))*sqrt(fs/float(nSS))*.62/uRes.y:vec2(0.));
    // one picture turns into another three ways: a ring opening from the middle; the four corners folding in like a paper
    // fortune-teller, the new picture on their backs; a seam crossing the frame with the figures on both sides of it turned to
    // blocks (one family goes in, another comes out)
    bool inB=false;vec2 ps=p;float af=1.,shade=1.,seam=1e3,crs=1e3,inkA;
    if(wp>0.){
      if(wty==0){float rw=length(p);inB=rw<wp;seam=abs(rw-wp);af=smoothstep(.02,.26,seam);}
      else if(wty==2){vec2 dr=normalize(vec2(1.,(pc&1)==0?.22:-.22))*((pc&2)==0?1.:-1.);float s=dot(p,dr),s0=mix(-1.08,1.08,wp/1.2);
        inB=s<s0;seam=abs(s-s0);af=smoothstep(.02,.34,seam);}
#if HD>=1
      else{
        vec2 hf=vec2(.5*asp,.5),uv=abs(p)/hf,sg=vec2(p.x<0.?-1.:1.,p.y<0.?-1.:1.);
        float c=cos(PI*clamp(wp/1.2,0.,1.)),s=uv.x+uv.y-1.;c=c<0.?min(c,-1e-3):max(c,1e-3);
        float s0=s/c;vec2 u0=uv+.5*(s0-s);bool on=s0>0.&&u0.x<=1.&&u0.y<=1.;
        if(c>0.){
          if(s>0.){if(on){ps=sg*u0*hf;shade=.72+.28*c;crs=min(1.-u0.x,1.-u0.y)*.5*c;}else inB=true;}
        }else{
          if(s<0.){if(on){inB=true;ps=sg*(uv-.5*(s0+s))*hf;shade=.72-.28*c;crs=min(1.-u0.x,1.-u0.y)*.5*(-c);}}
          else inB=true;
        }
        crs=min(crs,abs(s)*.35);
      }
#endif
    }
    int pl=(inB?(pc>>4):(pc&15))%TY_NPAL;
    vec3 inkC=TYQ[pl*8];
    vec3 col=tyScene(ps,inB?lb:la,pl,inB?shB:0.,af,inkA);
    col=mix(col,inkC,inkA)*shade;
    if(wp>0.){
      // the seam is a brass rail between two lines of ink; a fold is a crease of ink
      col=mix(col,TYQ[pl*8+6],clamp(.5-(seam-.012)/pxs,0.,1.));col=mix(col,inkC,clamp(.5-(abs(seam-.012)-.004)/pxs,0.,1.));
#if HD>=1
      col=mix(col,inkC,clamp(.5-(crs-.004)/pxs,0.,1.));
#endif
    }
    acc+=col;
  }
  vec3 col=acc/float(nSS);
#if HD>=1
  // averaging fine line work inside a pixel greys it a little: give the chroma back so the detail tiers stay as saturated as High
  {float lm=dot(col,vec3(.2126,.7152,.0722));col=max(lm+(col-lm)*(HD>=2?1.1:1.06),0.);}
#endif
  float hr=.13*sin(uHue*TAU),hc=cos(hr),hsn=sin(hr),h3=(1.-hc)/3.,hq=hsn*.57735;
  fragColor=vec4(max(mat3(hc+h3,h3+hq,h3-hq,h3-hq,hc+h3,h3+hq,h3+hq,h3-hq,hc+h3)*col,0.),0.);
}
`;
