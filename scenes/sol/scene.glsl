const R_SOL = `
// SOL 70 v7 "flower power": a superflat 70s field of original smiling flowers, packed edge to edge in five
// parallax layers (tiny at the back, big at the front), crisp ink outlines, layered rainbow petals.
// Each size class sings its own band: big flowers open their mouths to the bass, middle ones to the mids,
// small ones to the presence range, the tiny carpet twinkles with the air band. Petals turn one notch per beat
// in a wave that sweeps across the field. Families: FIELD (drifting pile), TUNNEL (log-polar rings streaming
// outward from a spectrum sun-flower), PARADE (rows of flowers and mushrooms conveyor-stepping on the beat).
// v8: a seventh (back) layer and a patterned ground fill the gaps; SPIRAL family; rainbow bridges; events: giant face
// (the field flips like a stadium card stunt into one huge winking, singing face), flower rain, mushroom conga;
// drops can burst into a kaleidoscope composition (folded field) that a second hoop later unfolds.
// v11: CHORUS LINE family (tiered flower beds of long-stemmed flowers swaying in a kick line, shuffling a quarter step
// per beat); card stunts (the field flips into a breathing mandala, an equaliser rainbow or a pumping heart; the giant
// face is now rare); two beat-locked transitions besides the hoop: a flower wave (a row of big flowers marches across
// the screen one step per beat, carrying the next scene behind it) and a paper fan (eight blades unfold the next scene
// from a rivet flower at the bottom edge, one blade per beat).
// uP1 [trav beats, mt, kick env, snare flash]   uP2 mouths [carpet(air), small(bass), mid(harmony), big(lead vocal)] (v20: fract of z = smoothed mids, of w = snare flash)
// uP3 [wipe radius or progress, build, breakdown, drop flash]   uP4 [famA+8*foldA, vsA, event+progress, colour shift]
// uP5 [famB+8*foldB, vsB, wipe mode + 4*direction, bar blink] (fam 0..4, fold 0..4; wipe mode 0 hoop, 1 wave, 2 fan)   uM1, uM2: the six palette colours (linear)
vec3 solC(float i){float k=i-6.*floor((i+.5)/6.);
  vec3 a=k<.5?uM1[0]:(k<1.5?uM1[1]:uM1[2]),b=k<3.5?uM2[0]:(k<4.5?uM2[1]:uM2[2]);return k<2.5?a:b;}
const vec3 SOLINK=vec3(.018,.008,.03);
#if HD>=1
// v19 detail range: a loop start the HLSL compiler cannot fold (uTime>=0), so nested loops are never unrolled
#define SOL0 min(int(uTime),0)
// v20: three shadow samples per unit of detail (6 at Native, 9 Cinema, 13 Insane), four at Extreme and Offline (26, 40): smoother paper shadows
#if HD>=4
#define SOLKS 4.
#else
#define SOLKS 3.
#endif
#endif
// cheap atan2 (max error ~1e-5 rad): FXC's atan2 emulation is ~23 instructions per call site
float solAt(float y,float x){float ax=abs(x),ay=abs(y),t=min(ax,ay)/max(max(ax,ay),1e-20),s=t*t;
  float r=((-.0464964749*s+.15931422)*s-.327622764)*s*t+t;r=mix(r,1.5707963-r,step(ax,ay));r=mix(r,3.1415927-r,step(x,0.));return r-2.*r*step(y,0.);}
vec4 solH(vec2 id,float L){return fract(sin(vec4(dot(id,vec2(127.1,311.7)),dot(id,vec2(269.5,183.3)),dot(id,vec2(419.2,371.9)),dot(id,vec2(113.5,271.9)))+L*7.31)*43758.545);}
float solEl(vec2 p,vec2 ab){float k0=length(p/ab),k1=length(p/(ab*ab));return k0*(k0-1.)/max(k1,1e-5);}
float solA(float d,float e){return clamp(.5-.5*d/e,0.,1.);}
float solBack(float x){x=min(x/.42,1.)-1.;return 1.+2.70158*x*x*x+1.70158*x*x;}
// flower silhouette (units of the flower radius): a core disc plus n ellipse petals that overlap their neighbours
float solSilA(float r,float a,float n,float el){
  float sec=TAU/n,aa=a-sec*floor(a/sec+.5);
  float s=sin(PI/n),pc=1./(1.+1.3*s*el),rt=pc*1.3*s;
  return min(solEl(r*vec2(cos(aa),sin(aa))-vec2(pc,0.),vec2(el*rt,rt)),r-pc);
}
float solSil(vec2 q,float n,float el,float ph){return solSilA(length(q),solAt(q.y,q.x)-ph,n,el);}
// mushroom silhouette (units of its radius): domed cap over a short stem
float solMush(vec2 q){
  vec2 c=q-vec2(0.,-.1);float cap=max(solEl(c,vec2(.93,.82)),-c.y);
  vec2 s=q-vec2(0.,-.48);vec2 b=abs(s)-vec2(.25,.36);float st=length(max(b,0.))+min(max(b.x,b.y),0.)-.08;
  return min(cap,st);
}
// rainbow character (units of its radius): a five-band arc on two clouds
float solRbw(vec2 q){
  vec2 c=q-vec2(0.,-.3),a=vec2(abs(q.x),q.y);
  float arc=max(abs(length(c)-.6)-.22,-c.y);
  float cl=min(min(length(a-vec2(.6,-.36))-.22,length(a-vec2(.38,-.44))-.15),length(a-vec2(.78,-.38))-.13);
  return min(arc,cl);
}
// rainbow shading: the five bands are a live equaliser (inner = bass ... outer = air), ink separations, white clouds
vec3 solRainbow(vec2 q,float pq,float cs,float fl){
  float w=max(.035,1.3*pq);
  vec2 c=q-vec2(0.,-.3),a=vec2(abs(q.x),q.y);
  float x=(length(c)-.38)/.088,bi=clamp(floor(x),0.,4.);
  float lv=mix(mix(mix(uB1.y,uB1.z,step(.5,bi)),uB1.w,step(1.5,bi)),mix(uB2.y,uB2.z,step(3.5,bi)),step(2.5,bi));
  vec3 col=solC(4.-bi+cs)*(.55+.9*lv)*fl;
  col=mix(col,col*1.5+.05,smoothstep(.1,.05,pq)*solA(abs(fract(x)-.28)*.088-max(.007,.5*pq),pq)*step(0.,x)*step(x,5.));   // v20: a highlight line printed in every band
  col=mix(col,SOLINK,smoothstep(.13,.07,pq)*solA(abs(fract(x+.5)-.5)*.088-w*.4,pq)*step(.5,x)*step(x,4.5));
  float cl=min(min(length(a-vec2(.6,-.36))-.22,length(a-vec2(.38,-.44))-.15),length(a-vec2(.78,-.38))-.13);
  vec3 cc=mix(vec3(2.,1.95,1.85),vec3(1.5,1.6,2.),solA(cl+.07,pq)*.5);
  cc=mix(cc,SOLINK,smoothstep(.13,.07,pq)*(1.-solA(cl+w,pq)));
  return mix(col,cc,solA(cl,pq));
}
// one petal ring for shading: x = signed distance of the visible petal, y = its index (petal k+1 lies over k)
vec3 solRing(vec2 q,float n,float el,float ph,float spa){
  float r=length(q),a=solAt(q.y,q.x)-ph,sec=TAU/n,k=floor(a/sec+.5),aa=a-k*sec;
  float s=sin(PI/n),pc=1./(1.+1.3*s*el),rt=pc*1.3*s;
  float d0=solEl(r*vec2(cos(aa),sin(aa))-vec2(pc,0.),vec2(el*rt,rt));
  float d1=solEl(r*vec2(cos(aa-sec),sin(aa-sec))-vec2(pc,0.),vec2(el*rt,rt));
  float nb=step(0.,aa)*step(d1,0.);
  return vec3(min(mix(d0,d1,nb),max(r-pc,-r)),mod(k+nb,n),a);
}
float solHeart(vec2 p){p.x=abs(p.x);vec2 q=p-.5*max(p.x+p.y,0.);
  return mix(sqrt(min(dot(p-vec2(0.,1.),p-vec2(0.,1.)),dot(q,q)))*sign(p.x-p.y),length(p-vec2(.25,.75))-.35355,step(1.,p.y+p.x));}
// smiling face in face units (radius 1). Expressions: bright eyes with glints, happy closed eyes (singing), heart eyes,
// tinted 70s round shades, a wink. Eyes blink, look around and close in breakdowns; the mouth opens with its band.
vec3 solFace(vec3 col,vec2 f,float pf,float mo,float bl,float slp,vec4 h,float lod,float eo){
  float lw=max(.075,1.25*pf),ex=eo<0.?fract(h.w*7.77+h.y*3.1):eo;
  vec2 gz=vec2(sin(uP1.y*.9+h.y*6.),cos(uP1.y*.7+h.z*6.))*.06*(1.-slp);
  bool happy=ex<.2||slp>.5,heart=!happy&&ex<.32,shades=!happy&&ex>.32&&ex<.48,wink=!happy&&ex>.9&&f.x>0.;
  // cheeks
  vec2 ck=vec2(abs(f.x)-.6,f.y+.2);
  col=mix(col,mix(col,vec3(1.6,.32,.42),.55),solA(length(ck/vec2(.17,.11))-1.,pf)*step(.3,h.w)*lod);
  // eyes
  vec2 e=vec2(abs(f.x)-.34,f.y-.14)-gz;
  float op=(1.-bl)*(1.-slp);
  float de=(length(e/vec2(.13,.19*max(op,.08)))-1.)*.13;
  vec2 ea=vec2(abs(f.x)-.34,f.y-.08);float darc=max(abs(length(ea)-.13)-lw*.5,-ea.y);
  float eye=(op>.15&&!happy&&!wink)?solA(de,pf):solA(darc,pf);
  if(heart&&op>.15){float dh=solHeart((e+vec2(0.,.14))/.27)*.27;eye=0.;
    col=mix(col,SOLINK,solA(dh-lw*.6,pf)*lod);col=mix(col,vec3(2.,.12,.35)*(1.+.6*uO2.y),solA(dh,pf)*lod);}
  if(shades){vec2 sl=vec2(abs(f.x)-.35,f.y-.13);float dl=length(sl)-.25;eye=0.;
    vec3 lc=mix(col.zxy*.3+vec3(.06,0.,.1),vec3(1.6),solA(abs(sl.x+sl.y*.9-.05)-.035,pf)*.8);
    col=mix(col,SOLINK,solA(min(dl-lw*.6,max(abs(f.y-.2)-lw*.5,abs(f.x)-.12)),pf)*lod);
    col=mix(col,lc,solA(dl,pf)*lod);}
  col=mix(col,SOLINK,eye*lod);
  float gl=solA(length(e-vec2(.045,.07))-.05,pf)*step(.3,op)*(happy||heart||shades||wink?0.:1.);
  col=mix(col,vec3(1.4),gl*lod);
#if HD>=1
  // v19 detail: freckles and eyelashes, once the face has the pixels for them
  {float ff=smoothstep(.05,.02,pf)*lod;
   if(ff>.002){vec2 cf=vec2(abs(f.x)-.6,f.y+.22)*11.,ci2=floor(cf+.5),cg=cf-ci2;
     float fr=step(abs(ci2.x)+abs(ci2.y)*.7,2.3)*step(.4,h21(ci2+h.xy*9.));
     col=mix(col,vec3(1.1,.28,.22),ff*fr*solA((length(cg)-.2)/11.,pf));
     if(op>.4&&!happy&&!wink&&!shades&&!heart){float dl=1e3;vec2 ev=e-vec2(0.,.0);
       for(int j=SOL0;j<3;j++){float an=1.15+.42*float(j);vec2 ax=vec2(cos(an),sin(an));vec2 ed=ev-ax*.17;float tl=clamp(dot(ed,ax),0.,.13);dl=min(dl,length(ed-ax*tl)-.012);}
       col=mix(col,SOLINK,ff*solA(dl,pf));}
   }}
#endif
  // mouth: a curved grin whose height follows the band envelope; red inside, pink tongue
  // closed: a thin smiling line; open: a singing grin
  float cy=-.3,ry=.022+.39*mo;vec2 m=vec2(f.x,f.y-.62*f.x*f.x-cy);
  float dm=max(solEl(m,vec2(.44,ry)),m.y-.015);
  vec3 mc=mix(vec3(.55,.02,.06),vec3(1.5,.35,.45),solA(length(m-vec2(0.,-ry))-ry*.62,pf));
  col=mix(col,mc,solA(dm,pf)*lod);
  col=mix(col,SOLINK,solA(abs(dm)-lw*.5,pf)*lod);
  return col;
}
// full flower shading (units of its radius): outer rainbow petal ring with inner tint petals, inner ring, face
vec3 solFlower(vec2 q,float pq,float n,float el,float ph,vec4 h,vec4 h2,float mo,float bl,float slp,float cs,float lod,float spa,float fl,vec4 ov){
  float w=max(.04,1.3*pq),r=length(q),sty=h2.w,ik=smoothstep(.13,.07,pq);
  vec3 o=solRing(q,n,el,ph,spa);
  // petal colour schemes: rainbow (every petal its own colour), two-tone, mono
  float ci=h.x*6.+cs+mix(o.y,mod(o.y,2.)*3.*(1.-step(.8,sty)),step(.45,sty));
  float oa=min(ov.a,1.),ob=max(ov.a-1.,0.);
  vec3 col=mix(solC(ci),ov.rgb,oa)*fl*(1.+spa*2.*(spec(fract((o.y+.5)/n+.75))-.3));
  float s=sin(PI/n),pc=1./(1.+1.3*s*el),rt=pc*1.3*s;
  col=mix(col,mix(col,vec3(1.45,1.35,1.2)*fl,.42),solA(o.x+rt*.42,pq)*lod);
  // v20 print (every tier): the flower is a printed sticker. Each petal has an inset keyline, and each flower one of four printed
  // petal patterns: a halftone that swells toward the tip, a leaf vein with side veins, contour stripes, or a tapered bar. All of it
  // is tone on tone (a deep shade of the petal colour itself, or the contrast colour of the palette at full strength), never a pale
  // wash, and each mark fades out before it would fall under a pixel. Native and up add a comic shadow hatch and a bead rim.
  {float sc=TAU/n,k0=floor(o.z/sc+.5),a0=o.z-sc*k0-sc*step(.5,abs(mod(k0,n)-o.y));
   vec2 ps=(r*vec2(cos(a0),sin(a0))-vec2(pc,0.))/rt;   // petal space in half widths: x runs out along the petal
   float pxp=pq/rt,vis=smoothstep(.3,.13,pxp)*smoothstep(0.,rt*.12,-o.x),st=fract(sty*3.+h.y*5.7);
   if(vis>.002){
     vec3 tc=mix(col,solC(ci+3.)*fl,.8),dc=col*mix(vec3(.62),col/max(max(col.r,max(col.g,col.b)),.05),.7)*.78;
     dc=mix(dc,col*col/max(max(col.r,max(col.g,col.b)),.05)*1.55,min(sqrt(fract(uP2.w))*1.15,1.));   // on the snare the print flashes from deep to a vivid bright shade of the same hue for an instant
     float e0;
     if(st<.25){vec2 gq=ps*3.4;gq.y+=.5*mod(floor(gq.x),2.);vec2 gf=fract(gq)-.5;e0=(length(gf)-.14-.24*smoothstep(-el,el,ps.x))/3.4;col=mix(col,dc,vis*solA(e0,pxp));}
     else if(st<.5){float v0=abs(ps.y)-.045,v1=abs(fract((ps.x-abs(ps.y)*.85)*2.2)-.5)/2.2-.02;e0=min(v0,v1);col=mix(col,tc,vis*.9*solA(e0,pxp));}
     else if(st<.75){float bd=-o.x/rt/.3;e0=(abs(fract(bd)-.5)-.2)*.3;col=mix(col,dc,vis*step(.95,bd)*solA(e0,pxp));}
     else{float cc=abs(ps.y)-.24*(1.-smoothstep(-el,el,ps.x));col=mix(col,tc,vis*.85*solA(cc,pxp));}
     col=mix(col,dc,vis*solA(abs(o.x/rt+.17)-max(.03,.55*pxp),pxp));            // the inset keyline
#if HD>=1
     // comic shadow hatch on the side away from the light, and a bead rim round the petal
     {float hs=smoothstep(.1,.045,pxp)*smoothstep(-.1,.35,dot(q,vec2(.7,-.7)))*vis,hl=abs(fract((q.x+q.y)*9.)-.5)/9.-.014;
      col=mix(col,dc,hs*.8*solA(hl,pq));
      float phi=solAt(ps.y,ps.x/el)*2.2281,beadD=length(vec2(-o.x/rt-.34,(fract(phi)-.5)*.5))-.05;
      col=mix(col,col*1.4+.06,vis*smoothstep(.09,.05,pxp)*solA(beadD,pxp));}
     // a line of tiny five-petal florets up the middle (two at Native, more with every tier)
     {float fm=vis*smoothstep(.075,.035,pxp);
      if(fm>.002){int nf=int(clamp(uDetail,1.,6.));
       for(int j=SOL0;j<nf;j++){float xj=mix(-.45*el,.5*el,(float(j)+.5)/float(nf)),rj=.21*mix(1.,.5,float(j)/max(float(nf)-1.,1.));
         vec2 fq=(ps-vec2(xj,0.))/rj;float sf=solSil(fq,5.,1.15,ph*3.+float(j)*1.7)*rj;
         col=mix(col,SOLINK,fm*solA(sf-.035,pxp));
         col=mix(col,solC(ci+float(j)+2.)*fl*1.15,fm*solA(sf,pxp));
         col=mix(col,vec3(1.9,1.6,.45),fm*solA(length(fq)-.3,pxp/rj));
#if HD>=4
         // pollen: a ring of specks on every floret
         {float pa3=solAt(fq.y,fq.x)*2.546479,pk=length(vec2(length(fq)-.62,(fract(pa3)-.5)*.48))-.055;col=mix(col,vec3(2.,1.9,1.6),fm*solA(pk*rj,pxp));}
#endif
       }}}
#endif
   }}
  col=mix(col,SOLINK,ik*(1.-solA(o.x+w,pq)));
  // inner ring: scalloped, offset half a petal, contrasting colour with a lighter core
  float d2=r-.64*(.78+.22*abs(sin(.5*n*o.z)));
  vec3 c2=mix(solC(h.x*6.+cs+2.+2.*step(.45,sty))*fl,ov.rgb*.8,ob);
  c2=mix(c2,mix(c2,vec3(1.3,1.2,1.05),.4),solA(d2+.07,pq)*lod);
  {float gm=min(.75*fract(uP2.z)+.6*sqrt(fract(uP2.w)),1.);c2=mix(c2,c2*c2/max(max(c2.r,max(c2.g,c2.b)),.05)*1.3,gm)*(1.+.12*gm);}   // (richer, not paler: the colour deepens and saturates)
                                                          // v20: the inner rings glow with the mids and pop on the snare
  c2=mix(c2,c2*.55,smoothstep(.07,.03,pq)*solA(abs(d2+.045)-max(.009,.5*pq),pq));   // v20: inset keyline
#if HD>=1
  {float pl=smoothstep(.05,.015,pq)*smoothstep(.0,.04,-d2);if(pl>.002){float M=3.*n,lp=abs(fract(o.z*M/TAU)-.5)*TAU/M*r-.0045;c2=mix(c2,mix(c2,SOLINK,.55),pl*solA(lp,pq));
   float dt=length(vec2(r-.53,(fract(o.z*M*.5/TAU)-.5)*TAU*.53/(M*.5)))-.012;c2=mix(c2,vec3(1.75,1.6,1.3)*fl,pl*solA(dt,pq));}}
#endif
  c2=mix(c2,SOLINK,ik*(1.-solA(d2+w,pq)));
  col=mix(col,c2,solA(d2,pq));
  // face disc
  float df=r-.4;
  vec3 fc=mix(mix(vec3(1.75,1.3,.3),vec3(2.1,2.,1.8),step(.55,h2.z)),vec3(1.9,1.05,1.15),step(.8,h2.z));
  fc=mix(fc,ov.rgb,ob*.6);
  fc=mix(fc,fc*vec3(.9,.62,.4),smoothstep(.07,.03,pq)*solA(abs(df+.04)-max(.008,.5*pq),pq));   // v20: inset keyline
#if HD>=2
  {float M2=2.*n+6.,fb=length(vec2(r-.368,(fract(o.z*M2/TAU)-.5)*TAU*.368/M2))-.013;fc=mix(fc,mix(fc,vec3(1.3,.55,.1),.75),smoothstep(.03,.012,pq)*solA(fb,pq));}
#endif
  fc=mix(fc,SOLINK,ik*(1.-solA(df+w,pq)));
  return mix(col,fc,solA(df,pq));
}
// mushroom shading (units of its radius): spotted cap, smiling stem
vec3 solShroom(vec2 q,float pq,vec4 h,float mo,float bl,float cs,float lod,float fl){
  float w=max(.04,1.3*pq);
  vec2 c=q-vec2(0.,-.1);
  vec3 cap=solC(h.x*6.+cs)*fl;
  // cap bands (concentric 70s stripes) and spots
  float bd=length(c/vec2(.93,.82));
  vec2 sp=c*rot(.3)*3.2;vec2 si=floor(sp+.5);vec2 sf=sp-si;float sd=(length(sf)-.24-.08*h21(si+h.zw))/3.2;
  cap=mix(cap,vec3(1.35,1.3,1.2),solA(sd,pq)*step(bd,.8)*lod);
  cap=mix(cap,solC(h.x*6.+cs+3.)*fl,solA((.84-bd)*.8,pq)*lod);cap=mix(cap,SOLINK,smoothstep(.1,.05,pq)*solA(abs(bd-.84)*.8-max(.012,.6*pq),pq)*lod);   // v20: rim band and keyline
  float dcap=max(solEl(c,vec2(.93,.82)),-c.y);
  cap=mix(cap,SOLINK,smoothstep(.13,.07,pq)*(1.-solA(dcap+w,pq)));
  vec2 s=q-vec2(0.,-.48);vec2 b=abs(s)-vec2(.25,.36);float dst=length(max(b,0.))+min(max(b.x,b.y),0.)-.08;
  vec3 stc=vec3(1.75,1.45,1.05);
  stc=mix(stc,vec3(1.75,1.05,.62),solA((abs(fract(s.y*4.5)-.5)-.25)/4.5,pq)*lod*step(s.y,.2));   // v20: striped stem
  stc=mix(stc,SOLINK,smoothstep(.13,.07,pq)*(1.-solA(dst+w,pq)));
  return mix(stc,cap,step(dcap,0.));
}
// Compile note: ANGLE unfolds every && / || / ?: into if-blocks, which FXC (D3D11) compiles very slowly; realm() and
// its helpers therefore use float flags with step/mix/min/max instead, and keep real branches only where they skip work.
void realm(){
  vec2 p0=scr();
  vec4 mOp=floor(uP2)*.01;   // v18: uP2 = mouth (int %) + a continuous value in the fraction
  float wr=uP3.x,wm=mod(uP5.z,4.),wact=step(1e-3,wr)*step(wr,1.6),fan=step(abs(wm-2.),.5),drip=step(2.5,wm);
  // transitions: hoop (radius wr), flower wave (front marches one eased step per beat), fan (one blade per beat)
  float wB=mix(6.,8.,step(1.5,wm)),wst=wr*wB,wpos=(floor(wst)+solBack(fract(wst)))/wB;
  float wan=floor(uP5.z/4.)*.7853982;vec2 wdir=vec2(cos(wan),sin(wan));
  float wf=mix(-1.2,1.2,wpos),ws=dot(p0,wdir),wt=dot(p0,vec2(-wdir.y,wdir.x));
  vec2 fq0=p0-vec2(0.,-.58);float fna=solAt(fq0.y,-fq0.x)*2.546479,fbk=floor(fna),fbu=fna-fbk,fbo=min(solBack(clamp(wst-fbk,0.,1.)),1.);
  // v18 melt: the next scene pours down from the top edge in paint drips, one eased step per beat (each column its own length)
  float dcw=.2,dcx=p0.x/dcw+.5*sin(wan*3.),dck=floor(dcx),dcf=(dcx-dck-.5)*dcw,dch=fract(sin(dck*12.9+wan)*437.58),dcr=dcw*(.27+.17*fract(dch*7.3));
  float dfr=mix(.62,-.68,wpos),dct=dfr-(.05+.42*dch)*min(wpos*5.,1.),dcy=min(p0.y-dct,0.),dca=length(vec2(dcf,dcy))-dcr,dcp=dfr-p0.y,dcg=.07,dcm=clamp(.5+.5*(dcp-dca)/dcg,0.,1.),dcd=-(mix(dcp,dca,dcm)-dcg*dcm*(1.-dcm));
  float inB=mix(mix(step(length(p0),wr),mix(step(ws,wf),step(fbu,fbo),fan),step(.5,wm)),step(0.,dcd),drip)*wact;
  vec4 C=mix(uP4,uP5,inB);
  float ev=floor(uP4.z),evp=fract(uP4.z),evb=evp*16.,fam=mod(C.x,8.),kf=floor(C.x/8.),vs=C.y,csN=floor(uP4.w/4.),ramp=uP4.w-4.*csN,cs=csN+step(.5,ramp),tr=uP1.x,kick=uP1.z,htA=floor(uP1.w*.5)*.01,bsS=uP1.w-2.*floor(uP1.w*.5),dnc=floor(uP3.y*.5),bld=uP3.y-2.*dnc,dnA=floor(uP3.z*.5)*.01,brk=uP3.z-2.*floor(uP3.z*.5),aiA=floor(uP3.w*.5)*.01,dfl=uP3.w-2.*floor(uP3.w*.5),hopA=floor(uP5.w*.5)*.01,blB=uP5.w-2.*floor(uP5.w*.5);
  // families as flags: field, tunnel (or spiral), parade, spiral, chorus line
  float fCh=step(3.5,fam),fSpi=step(abs(fam-3.),.5),fPar=step(abs(fam-2.),.5),fFld=1.-step(.5,fam),fTun=step(abs(fam-1.),.5)+fSpi;
  // events (16 beats): 5 giant face, 6 flower rain, 7 mushroom conga
  float eGF=step(abs(ev-5.),.5)+step(7.5,ev)*step(ev,10.5)+step(12.5,ev),eBl=step(abs(ev-11.),.5),eBn=step(abs(ev-12.),.5),pic=max(ev-7.,0.),eR=step(abs(ev-6.),.5),eC=step(abs(ev-7.),.5),emid=step(1.,evb)*step(evb,15.);
  float fRain=eR*emid,fCg=eC*emid*fFld;
  float swz=mix(1.,smoothstep(0.,1.,min(clamp(abs(evb-1.),0.,1.),clamp(abs(evb-15.),0.,1.))),max(eR,eC));
  float gs=eGF*smoothstep(0.,1.5,evb)*(1.-smoothstep(13.,15.,evb));
  // kaleidoscope compositions (drop bursts): the field is folded into kn mirrored sectors and bursts outward
  float kn=4.+2.*kf,sec=TAU/kn,fa=solAt(p0.y,p0.x)+tr*.04,fb=abs(fa-sec*floor(fa/sec)-.5*sec);
  vec2 pc=mix(p0,length(p0)*vec2(cos(fb),sin(fb))*(1.+.6*dfl),step(.5,kf));
  // v20 dances: no warp bends the field any more (v18's sway, twist, jelly and chevrons were sine waves in time and space: the
  // owner's "way too wavy"). Dances 1, 2, 4, 5 and the new 7 are rigid moves of each flower, one PUNCH a beat: out and back in
  // .42 of a beat, at rest for the remainder, alternate rows on alternate sides (dP depth, dD the beat's side). They are applied
  // per flower inside the packing loop. What still acts on the picture as a whole: the kick shockwave (one ring of pressure
  // travelling out from the centre) and dance 3, the magnifier, which now holds still for a beat and a half and darts to its
  // next spot in half a beat instead of gliding about.
  float dP=dnA*sin(PI*min(fract(tr)/.42,1.)),dD=1.-2.*mod(floor(tr),2.);
  float dK1=step(abs(dnc-1.),.5),dK2=step(abs(dnc-2.),.5),dK4=step(abs(dnc-4.),.5),dK5=step(abs(dnc-5.),.5),dK7=step(abs(dnc-7.),.5),dK8=step(abs(dnc-8.),.5);
  {float rp=length(pc),srR=fract(uP2.x)*1.,srE=fract(uP2.y)*1.,sd=rp-srR,sk=max(0.,1.-sd*sd*14.);pc-=pc/(rp+.25)*.075*srE*sk*sk;
   float d3=step(abs(dnc-3.),.5),mk=floor(tr*.5),mf=smoothstep(.75,1.,fract(tr*.5)),ms=vs*40.;
   vec2 bc=mix(vec2(.62*sin(mk*2.4+ms),.3*cos(mk*1.7+ms)),vec2(.62*sin(mk*2.4+2.4+ms),.3*cos(mk*1.7+1.7+ms)),mf)-pc;
   float be=max(0.,1.-dot(bc,bc)*5.5);pc+=d3*dnA*.48*be*be*bc;}
  float zm=uZoom*(1.+.12*bld);
  vec2 p=pc/zm;float px=1./(uRes.y*zm);
  // the tunnel is the heart of one giant flower: zoomed out, its petal rim and the flower field around it appear
  float pa=solAt(p.y,p.x),dg=1e3;
  if(fTun>.5){float da=pa-tr*.03,dk=da-TAU/12.*floor(da*12./TAU+.5);dg=length(p)-1.9*(.8+.2*sqrt(max(cos(dk*6.),0.)));fTun*=step(dg,0.);}
  fSpi*=fTun;
  float rn0=fRain*(1.-fTun);
  // per-visit variant knobs
  float c0=mix(.05,.066,fract(vs*7.31)),gr=mix(1.46,1.6,fract(vs*3.17));
  float elB=1.+.75*step(.5,fract(vs*11.7)),wvT=fract(vs*5.93),dang=vs*TAU;
  float rate=1.-.5*step(.6,fract(vs*2.71)),tw=(step(.5,fract(vs*9.1))*2.-1.)*mix(.35,.8,fract(vs*6.7));
  float bri=fFld*step(fract(vs*13.3),.5);
  vec2 ddir=vec2(cos(dang),sin(dang));
  // ---- layered packing: back (tiny) to front (big); keep the topmost covering shape, its ink rim and the rims above it.
  // Parade: field layers, then conveyor belts, then the marching characters on them.
  float tL=-9.,tn=12.,tel=1.,tph=0.,tRs=1.,tMu=0.,ink=0.,sh=0.,tdl=0.,tGs=0.,tArm=0.;
  vec2 tq=vec2(0.),tcw=vec2(0.);vec4 th=vec4(0.);
#if HD>=1
  // v19: extra carpet layers under the field (down to the pixel footprint) and real paper shadows: each shadow sample is one more
  // packing pass over the layers above this pixel's top layer, offset away from the light, each layer by its height above the receiver
  int solK=int(clamp(1.+floor(1.6*log2(max(uDetail,1.))),0.,6.)),sNS=int(clamp(uDetail*SOLKS,0.,40.)),iS=SOL0-solK;
  float tL0=-9.,occ=0.,paS=pa;vec2 pS=p;
  for(int sP=SOL0;sP<=sNS;sP++){
    float sCov=0.;vec2 sO=vec2(0.);
    if(sP>0){float sag=float(sP)*2.39996,srd=sqrt((float(sP)-.5)/float(sNS));sO=(vec2(.7,-.7)+.45*srd*vec2(cos(sag),sin(sag)))*.0065;}
  for(int i=iS;i<7+SOL0;i++){
#else
  for(int i=0;i<7;i++){
#endif
    float L=float(i)-1.;
#if HD>=1
    if(sP>0){if(L<=tL0)continue;float hg=min(L-tL0,3.);p=pS+sO*hg;pa=solAt(p.y,p.x);}
    float Lb=max(L,-1.);
#else
    float Lb=L;
#endif
    float fRow=max(fPar*step(4.5,L),max(fCg,fCh)*step(3.5,L)),fBelt=fPar*step(abs(L-4.),.5),fBrg=bri*step(abs(L-3.),.5);
    float fRB=fRow+fBelt,fx=step(1.5,L)*(1.-fRB-fBrg),rn=rn0*fx;
    vec2 u=vec2(0.),pv=vec2(0.),pid=vec2(0.);vec4 sp2=vec4(1.,0.,1.,1.);float J=1.,la=0.,roll=0.,hop=0.,lean=0.,sw=0.;
    if(fTun>.5){
      // tunnel: log-polar rings; spiral: the lattice is rotated in log-polar space so that the lattice vector
      // (N+k/2, .87k) closes one turn (conformal, round flowers; rows become k-armed spirals; k=0 is the tunnel)
      float N=floor(5.*pow(gr,5.-L)+.5),r=max(length(p),1e-6);
      float sr=mix(step(.35,fract(vs*4.3)),-.7,fSpi);
      u=vec2(pa/TAU*N+tr*(.12+.16*(1.-sr))*(fract(L*.5)*4.-1.),(log(r)-tr*.11*sr)*N/TAU);
      float k=floor(N*tw+.5)*fSpi;vec2 P=vec2(N+.5*k,.8660254*k);float pl=length(P);u*=pl/N;J=r*TAU/pl;
      sp2=vec4(P/pl,pl,max(abs(k),1.));u=vec2(sp2.x*u.x-sp2.y*u.y,sp2.y*u.x+sp2.x*u.y);
    }else if(fRB>.5){
      // belts (alternate sizes), characters march one cell per beat, alternate directions; conga: denser rows of dancers
      // chorus line: two tiers of flower beds (back tier smaller), long-stemmed flowers shuffle a quarter step per beat
      float rs=mix(mix(1.,.62,fCg),mix(.6,.85,L-4.),fCh),yy=p.y+fCg*(L-4.)*.33+fCh*(5.-L)*.2;
      float j=floor(yy/(1.05*rs)+.5),yl=yy+.12*rs-j*1.05*rs,jo=fract(j*.5)*2.,hb=mix(.34-.09*jo,.4,fCh)*rs;
      float dirR=jo*2.-1.,st=tr*rate+fract(j*.618034),sp=floor(st)+solBack(fract(st));
      float xx=p.x/hb-dirR*sp*(1.-.75*fCh)+j*.37,cx=floor(xx+.5);
      hop=sin(PI*min(fract(st)/.42,1.));lean=fCg*dirR*.3*hop;
      // kick line: every stem sways to the other side on each beat (eased overshoot), rippling down the line
      float st2=tr*rate-cx*.09*dirR;roll=.058*sin(PI*min(fract(st2)/.42,1.))*(1.-2.*mod(floor(st2),2.));   // v20: a kick out and back upright within the beat, alternate sides (was: lean over and hold = a sway)
      sw=roll*fCh;roll=mix((1.-fCg)*dirR*sp,0.,fCh);
      pv=mix(vec2(xx-cx,yl/hb),vec2(xx,(yl/hb+.44)/.13),fBelt);pid=vec2(cx*(1.-fBelt),j);J=hb;
    }else{
      // flower rain: the front layers fall one bouncy step per beat, each layer at its own speed, flowers spinning
      float cl=c0*pow(gr,L);la=.5+1.13*L;
      u=rot(la)*(p+vec2(0.,rn*(floor(tr)+solBack(fract(tr)))*(.06+.035*L)))/cl+ddir*tr*(.08+.015*L)+vec2(L*3.7,L*1.9);J=cl;
    }
    // nearest hex-lattice point (neighbour distance 1)
    vec4 hc=floor(vec4(u,u-vec2(.5,.8660254))/vec2(1.,1.7320508).xyxy)+.5;
    vec2 a=u-hc.xy*vec2(1.,1.7320508),b=u-(hc.zw+.5)*vec2(1.,1.7320508);
    vec2 v=mix(b,a,step(dot(a,a),dot(b,b))),cc=u-v;
    vec2 id=floor(vec2(cc.x*2.,cc.y/.8660254)+.5);
    // tunnel/spiral: a canonical id per lattice point, so flowers are seamless across the angle wrap
    vec2 sq=vec2(sp2.x*cc.x+sp2.y*cc.y,-sp2.y*cc.x+sp2.x*cc.y);
    id=mix(id,floor(vec2(mod(sq.x,sp2.z),sq.y)*3.+.5),fTun);
    float arm=floor(3.*mod(floor(cc.y/.8660254+.5),sp2.w)/sp2.w);
    v=mix(v,pv,fRB);id=mix(id,pid,fRB);
    id-=256.*floor(id/256.);
    vec4 h=solH(id,L+floor(vs*50.));
    // spiral arms: three colour bands wind round the vortex, flowers evenly sized so the rows read
    h.xy=mix(h.xy,vec2(arm/3.+.01,.97),fSpi);
    float fSt=fCh*fRow,Rl=mix((.5-.04*fRow)*(.68+.32*h.y)/1.07,.34+.06*h.y,fSt);
    // chorus: the head sits 1.15 cells up the stem, bobbing on the beat and swayed sideways by the stem
    vec2 vc=v;
    float frF=(1.-fRB)*(1.-fBrg),hpN=fract(tr*rate-h.y*.5-.5*mod(L,2.)),hpB=hopA*frF*(1.-fSpi),hpR=.5-Rl;
    v-=mix((.5-Rl)*(1.3-max(1.05*hpB,.75*dnA*(dK1+dK4+dK5+dK8)))*(1.-fSpi)*(h.zw-.5),mix(vec2(0.,Rl-.4-.12*hop),vec2(sw,.95+.07*hop),fCh),fRow);
    v=rot(-la)*v;
    // v20 rigid dances (rows of the lattice take turns): 1 pop rows (a hop), 5 side-step, 2 twist, 4 squash, 7 petal flex, 8 pump
    float dRow=mod(id.y,2.)*2.-1.,dq=frF*(1.-fSpi)*dP,dUp=max(dRow*dD,0.);
    v.y-=hpR*max(hpB*.95*sin(PI*min(hpN*1.6,1.))*(1.-.5*dnA*dK5),.62*dK1*dq*dUp);   // (v20: the hop lands after five eighths of a beat and the flower stands still for the remainder; it was a bob that never rested)
    v.x-=hpR*.6*dK5*dq*dRow*dD;
    // rainbow bridge: one giant equaliser rainbow arching over the middle layers, drifting slowly
    float bx=p.x+tr*.012;bx-=2.4*floor(bx/2.4+.5);
    v=mix(v,vec2(bx,p.y+.24)/1.03,fBrg);J=mix(J,1.03,fBrg);Rl=mix(Rl,1.,fBrg);
    vec2 cw=p-v*J;
    float dl=mix(length(cw)*.5,dot(cw,ddir.yx*vec2(1.,-1.))*.35+.5,step(.45,wvT));
    float scD=length(cw)*zm-fract(uP2.x),scW=max(0.,1.-scD*scD*14.);
    float blP=fract(evb*.25-dl*.8),blK=eBl*smoothstep(0.,1.,min(evb,16.-evb))*smoothstep(0.,.12,blP)*(1.-solBack(clamp((blP-.12)/.55,0.,1.)));
    Rl*=(1.+.085*kick*mix(Lb/5.,1.,fRow)+.21*bsS*(1.-Lb/5.)*(1.-fRow)+.14*fract(uP2.z)*mix(max(0.,1.-abs(L-2.5)/1.7),.6,fRow)+.07*mOp.w*step(3.5,L)+frF*.5*fract(uP2.y)*scW)*(1.-gs*step(1.5,L))*(1.-.72*frF*blK);
    Rl*=mix(1.,swz,max(fCg*fRow,eR*(1.-fTun)*fx))*(1.+dK8*dq*mix(-.24,.1,step(0.,dRow*dD)));   // v20 dance 8: rows pump big and small in turn
    Rl=max(mix(Rl,min(Rl,.5+.0*hpR),frF*(1.-fSpi)),1e-3);
    float Rs=Rl*J,Rp=Rs/px;
    vec4 h2=fract(h.yzwx*13.17+h.x*3.1);
    float n=mix(8.+2.*floor(h2.x*2.99),5.+floor(h2.x*2.99),step(fract(vs*17.3),.36)*(1.-fSpi));   // v20: in about a third of the visits the flowers are a chunky species with 5 to 7 petals
    float el=mix(elB,mix(1.5,1.,step(1.2,elB)),step(.8,h2.y));
    // beat choreography: one petal notch per beat, in a wave across the field, plus a full spin on drops
    float nt=tr*rate*(1.+bld)-dl,dirL=fract((L+floor(h.x*2.))*.5)*4.-1.;
    float ph=h.z*TAU+dirL*((floor(nt)+solBack(fract(nt)))*TAU/n+TAU*smoothstep(0.,1.,1.-dfl))-roll/Rl+rn*tr*(h.y-.5)*2.;
    float fMu=fRow*max(fCg,step(h2.z,.4)*(1.-fCh)),fRb=max(fBrg,(1.-fPar)*(1.-fTun)*(1.-fSt)*step(4.5,float(i))*step(h2.z,.1));
    ph+=dirL*TAU*smoothstep(0.,1.,clamp(evp*1.7-dl*.7,0.,1.))*step(abs(ev-4.),.5);
    ph+=dK2*dq*.45*dRow*dD;
    el*=1.+dK7*dq*.5*dUp;
    vec2 qv=rot(lean)*v/Rl*(1.+dK4*dq*.1*dD*vec2(1.,-1.));
    float d=mix(mix(solSil(qv,n,el,ph),solRbw(qv),fRb),solMush(qv),fMu)*Rs,dhd=d,dbd=1e3;
    if(fSt>.5){
      // stem (a bent stalk from the bed to the head), a leaf pair and the scalloped flower bed, in cell units
      float tt=clamp(vc.y*.5+.5,0.,1.),ax=abs(vc.x-sw*tt*tt);
      vec2 lp=vec2(ax-.17,vc.y+.2-.45*ax);
      float sc=fract(vc.x)-.5;dbd=vc.y+.65-.28*sc*sc;
      d=min(d,min(min(ax-.05,(length(lp/vec2(.19,.07))-1.)*.07),dbd)*J);dbd*=J;
    }
    // density per layer (spiral: only the carpet and one clean spiral layer; parade characters 90%, belts, bridge,
    // conga rows always); the back carpet never thins out: below a few pixels its flowers swell into a closed mosaic
    float f0=step(float(i),.5);
    float dens=mix(mix(1.,.6,clamp(L/5.,0.,1.)),4.*step(abs(L-2.),.5)-2.,fSpi);
    dens=max(mix(dens,.9,fPar*fRow),2.*max(max(f0,fBrg),max(fBelt,max(fCg,fCh)*fRow)));
#if HD>=1
    float fNeg=step(float(i),-.5);f0*=1.-fNeg;
#endif
    float pres=step(h.x,dens)*max(step(1.5,Rp),f0);d-=f0*(1.-smoothstep(1.5,4.,Rp))*Rs*1.5;
#if HD>=1
    pres*=1.-fNeg*step(Rp,4.);
#endif
    d=mix(d,(abs(v.y)-1.+gs)*.13*J,fBelt);qv=mix(qv,v,fBelt);Rs=mix(Rs,J,fBelt);
    d=mix(1e3,d,step(.5,pres));
#if HD>=1
    if(sP>0){sCov=max(sCov,solA(d,max(.12*Rs,1.5*px)));continue;}
#endif
    float w=min(max(.045*Rs,1.15*px),.3*Rs);
    if(d<0.){tArm=fSpi;tL=L;tq=qv;tn=n;tel=el;tph=ph;tRs=Rs;th=h;tdl=dl;tcw=cw;tGs=1.-fRB-fBrg;tMu=mix(mix(3.*fRb,1.,fMu),2.,fBelt);
      // chorus stalks: 4 stem / leaf, 5 flower bed (tq = cell coordinates, tph = the bed edge distance for its ink)
      float sk=fSt*step(0.,dhd);tMu=mix(tMu,4.+step(dbd,0.),sk);tq=mix(tq,vc,sk);tph=mix(tph,dbd,sk);tRs=mix(tRs,J,sk);tel=mix(tel,sw,sk);tn=mix(tn,.95+.07*hop,sk);ink=(1.-solA(d+w,.7*px))*smoothstep(3.,9.,Rp);sh=0.;}
    else{ink=max(ink,clamp(.5-d/px,0.,1.)*smoothstep(3.,9.,Rp));sh=max(sh,solA(d-.16*Rs,px)*smoothstep(6.,14.,Rp));}
  }
#if HD>=1
    if(sP==0)tL0=tL;else occ+=sCov;
    p=pS;pa=paS;
  }
  occ/=max(float(sNS),1.);
#endif
  // ---- big single flowers, one silhouette evaluation per pixel: the tunnel hero (a spectrum sun-flower at the centre,
  // petal lengths are the spectrum, bass at the bottom), or during a transition the row of big flowers riding the
  // flower-wave front (rolling as it marches) / the rivet flower holding the fan at the bottom edge (on top of the hero)
  float hero=0.,od=1e3,ovf=0.;
  float wk=floor(wt/.21+.5),orr=mix(mix(.1,.075,mod(wk,2.)),.19,fan)*(1.+.07*kick);
  vec2 oc=mix(wdir*wf+vec2(-wdir.y,wdir.x)*wk*.21,vec2(0.,-.58),fan);
  // v18 bouncing band (event 12): seven big singing flowers hop across the screen in a line, one hop per beat, each landing just after the one before
  float wO=wact*step(.5,wm)*(1.-drip),bnO=eBn*(1.-wO),bsp=(floor(evb)+solBack(fract(evb)))*.335-4.15,bk=clamp(floor((p0.x-bsp)/.62+.5),0.,5.),bht=fract(evb+bk*.2);
  orr=mix(orr,(.2+.03*mod(bk,2.))*(1.+.1*kick+.08*(1.-bht)),bnO);oc=mix(oc,vec2(bsp+bk*.62,-.3+.55*4.*bht*(1.-bht)+.05*mOp.y),bnO);wk=mix(wk,bk+2.,bnO);
  float useO=max(wO,bnO)*step(length(p0-oc),mix(orr*1.25,orr*1.02+.035,bnO));
  if(max(fTun,useO)>.5){
    float hr=max(.2*(1.+.06*kick)*(1.-gs),1e-3),R=mix(hr,orr/zm,useO),hph=mix(tr*.25+TAU*smoothstep(0.,1.,1.-dfl),mix(mix(-wf/orr*.5+wk,wst*.3927,fan),.32*sin(PI*evb+wk),bnO),useO);
    float hn=mix(16.,10.,useO),hel=mix(1.6,1.3,useO);
    vec2 hq=mix(p/hr,(p0-oc)/orr,useO);
    float dh=solSilA(length(hq),solAt(hq.y,hq.x)-hph,hn,hel)*R;od=mix(1e3,dh*zm,useO);
    if(dh<0.){hero=1.;ovf=useO;tArm=0.;tL=5.;tq=hq;tn=hn;tel=hel;tph=hph;tRs=R;th=mix(vec4(.13,.5,.5,fract(vs*7.13)),vec4(fract(wk*.37+.11+fan*.3),.6,.5,fract(wk*.53+.2)),useO);tMu=0.;tdl=0.;tGs=0.;
      ink=(1.-solA(dh+mix(.012,max(.045*R,1.2*px),useO),.7*px));sh=0.;}
    else{ink=max(ink,clamp(.5-dh/px,0.,1.)*(1.-useO));sh=max(sh,solA(dh-mix(.03,.12*R,useO),px));}
  }
  // ---- colour the top shape once
  vec3 col;
  float t=uP1.y;
#if HD>=1
  float gnd=step(tL,-8.5);
#else
  float gnd=step(tL,-5.);
#endif
  vec4 h=th,h2=fract(h.yzwx*13.17+h.x*3.1);
  h2.w=mix(h2.w,.9,tArm);
  cs=csN+step(tdl*1.2+.02,ramp);
  // macro structure: giant flowers (each petal one colour, a cream face disc with dark eyes and a red mouth that
  // sings) are painted by recolouring the small flowers whose centres fall inside them (and the ground between them).
  // The giant-face event paints one screen-filling face the same way: it winks mid-event and sings the lead.
  // giant face card stunt: every flower inside the face flips to its new colour at its own moment (staggered outward,
  // with a white flash), holds while the face winks and sings, then flips back
  float dsg=length(mix(tcw,p,gnd)*zm)/.68,gj=mix(.6*h.y,.3,gnd),fi=clamp(evb-.5-1.6*dsg-gj,0.,1.),fo=clamp(evb-12.-1.6*dsg-gj,0.,1.);
  float gfx=eGF*step(dsg,1.15)*max(tGs,gnd)*(step(.5,fi)-step(.5,fo));
  float gfl=eGF*step(dsg,1.15)*(max(0.,1.-abs(fi-.5)*5.)+max(0.,1.-abs(fo-.5)*5.));
  vec4 ov=vec4(0.);vec3 mtint=vec3(-1.);
  if(max(1.-fTun,gfx)*(1.-hero)>.5){
    vec2 mpos=mix(tcw,p,gnd);
    vec2 mu=rot(.35)*mpos/2.6+vec2(.31,.17);
    vec4 mc=floor(vec4(mu,mu-vec2(.5,.8660254))/vec2(1.,1.7320508).xyxy)+.5;
    vec2 ma=mu-mc.xy*vec2(1.,1.7320508),mb=mu-(mc.zw+.5)*vec2(1.,1.7320508);
    vec2 mq=mix(mb,ma,step(dot(ma,ma),dot(mb,mb)))/.47;
    vec2 mid=floor((mu-mq*.47)*2.+.5);
    float mw=step(h2.y*.999,mix(.9,.55,smoothstep(.45,1.2,uZoom)));
    mq=mix(mq,mpos*zm/.68,gfx);mid=mix(mid,vec2(3.,5.),gfx);
    float fdr=mix(.38,.62,gfx);
    float mn=8.+2.*floor(h21(mid)*3.),mr=length(mq),mph=tr*.06+h21(mid+.5)*6.;
    float ma2=solAt(mq.y,mq.x)-mph,mk=floor(ma2/(TAU/mn)+.5);
    float inM=step(solSilA(mr,ma2,mn,1.2),0.);
    vec3 mcol=solC(floor(h21(mid)*6.)+cs+mix(mk,3.,step(mr,fdr*mix(1.63,1.25,gfx))));
    vec2 mf=mq/fdr;
    float mopen=mix(mOp.w,max(mOp.w,.7*kick),gfx),wk=gfx*step(mf.x,0.)*smoothstep(6.5,7.5,evb)*(1.-smoothstep(9.,10.,evb));
    vec2 ef=(vec2(abs(mf.x),mf.y)-vec2(.36,.2))/vec2(.2,.3*(1.-max(blB,wk)*.92)+.02);
    float mouthM=step(length((mf-vec2(0.,-.3-.06*mopen))/vec2(.55,.06+.26*mopen)),1.)*step(mf.y,-.26+.5*mf.x*mf.x);
    vec3 faceC=mix(mix(vec3(2.,1.6,.45),vec3(1.7,.06,.12),mouthM),vec3(.05,.02,.1),step(length(ef),1.));
    mcol=mix(mcol,faceC,step(mr,fdr));
    if(pic*gfx>.5){
      // card stunts: the field becomes a breathing mandala, an equaliser rainbow or a heart on a turning sunburst
      vec2 sq=mq/.95;float sr=mr/.95,sa=ma2+mph,bt=floor(tr)+solBack(fract(tr));
      float rr=sr*5./(1.+.14*uBass),ri=floor(rr),fr2=fract(rr),nk=6.*max(ri,1.),ro=fract(ri*.5)*2.,pt=fract(sa/TAU*nk+.5*ro+(ro*2.-1.)*bt/nk);
      float pin=step(abs(pt-.5)*2.,.95*sqrt(max(0.,1.-fr2*fr2))-.08);
      // one palette lookup: each picture picks a colour index and brightness, or a fixed colour (sky, cloud, ink, heart)
      float pm=max(pin,step(ri,.5)),si=ri*2.+3.*(1.-pm),sb=mix(.4,1.1+.5*uB1.y,pm),fx=0.;vec3 fc=vec3(0.);
      vec2 rc=sq-vec2(0.,-.55);float rb=length(rc),bi=floor((rb-.42)/.11),lb=dot(vec4(1.-step(.5,bi),step(.5,bi)-step(1.5,bi),step(1.5,bi)-step(2.5,bi),step(2.5,bi)-step(3.5,bi)),vec4(uB1.yzw,uB2.y))+step(3.5,bi)*uB2.z;
      vec2 ca=vec2(abs(sq.x),sq.y);float cl=min(length(ca-vec2(.62,-.52))-.22,length(ca-vec2(.88,-.58))-.15);
      float band=step(0.,bi)*step(bi,4.)*step(-.55,rc.y),cld=step(cl,0.);
      float r4=step(5.5,pic),r2=step(abs(pic-2.),.5),r3=step(2.5,pic)*(1.-r4);
      si=mix(si,4.-bi,r2);sb=mix(sb,.5+lb,r2);fx=r2*max(1.-band,cld);fc=mix(vec3(.55,1.25,1.9),vec3(2.,1.95,1.85),cld);
      vec2 hq=sq/(.5*(1.+.1*kick))+vec2(0.,.12),hq2=hq*.86;float h1=dot(hq,hq)-1.,h2=dot(hq2,hq2)-1.;
      float hf=h1*h1*h1-hq.x*hq.x*hq.y*hq.y*hq.y,hf2=h2*h2*h2-hq2.x*hq2.x*hq2.y*hq2.y*hq2.y;
      float ray=step(.5,fract(sa/TAU*14.+bt/14.)),hin=step(hf2,0.),glt=step(length((sq-vec2(-.3,.3))/vec2(.09,.06)),1.)*step(hf,0.);
      si=mix(si,1.+3.*ray,r3);sb=mix(sb,mix(.8,1.,ray),r3);
      fc=mix(fc,mix(mix(SOLINK,vec3(2.,.12,.35)*(1.+.4*kick),step(hf,0.)),vec3(2.),glt),r3);fx=mix(fx,hin,r3);
      // v20 (event 13): an echo star: a five-point star whose bands march outward one band a beat, turning a notch as they go
      {float a5=abs(fract((sa+bt*.21)/TAU*5.)-.5)*TAU/5.,sv=sr*(cos(a5)+2.404*sin(a5))*4.3/(1.+.14*uBass)-bt,sk=floor(sv);
       si=mix(si,sk,r4);sb=mix(sb,.8+.55*uB1.y*step(.5,fract(sk*.5))+.3*kick*step(sv+bt,1.),r4);fx*=1.-r4;}
      vec3 sc=mix(solC(si+cs)*sb,fc,fx);
      mcol=mix(mcol,sc,step(sr,1.));inM=1.;
    }
    ov=vec4(mcol,inM*mix(step(.001,mw)*(1.+smoothstep(.6,.25,uZoom)),2.,gfx));
    mtint=mix(mtint,mcol,inM);
  }
  if(gnd>.5){
    // the ground: groovy wavy bands of deep palette colour pulsing with the sub, never black; inside a giant flower
    // (zoomed out, or the giant face) it takes the giant's colour so the mosaic reads as one picture
    float gb=length(pc+.03*sin(pc.yx*9.+tr*.5))*11.-tr*.5,gk=floor(gb),gw=14./uRes.y;
    col=solC(gk+cs+2.)*(.55+.25*uB1.x)*(1.-.75*solA(.5-abs(fract(gb)-.5)-.035,gw));
    {vec2 hg=rot(.5)*pc*uRes.y/9.;col*=1.-.45*solA((length(fract(hg)-.5)-.12-.3*fract(gb))*9.,1.5);}   // v20: halftone, swelling across each band
    col=mix(col,ov.rgb*.55,step(.5,ov.a)*mix(.6*smoothstep(.7,.3,uZoom),1.,gfx));
  }else if(tMu>3.5){
    // chorus line stalks: bright green stems with an ink edge, leaves with a pale vein, and the flower bed in palette
    // bands that follow its scallops
    float pq=px/tRs,tt=clamp(tq.y*.5+.5,0.,1.),ax=abs(tq.x-tel*tt*tt);
    vec2 lr=vec2(ax-.17,tq.y+.2-.45*ax);
    col=mix(vec3(.4,1.4,.22),vec3(.16,.85,.2),solA(ax-.05,pq));
    col=mix(col,vec3(.9,1.6,.55),solA(max(abs(lr.y)-.012,abs(lr.x)-.15),pq)*step(.05,ax));
    col=mix(col,SOLINK,solA(abs(ax-.05)-max(.012,.8*pq),pq)*(1.-smoothstep(.015,.04,pq)));
    float by=-tph/tRs/.12;
    vec3 bc=solC(floor(by)+floor(uP4.w/4.)+2.+3.*step(4.5,tL))*mix(.95,1.18,step(.5,fract(by)));
    bc=mix(bc,mix(bc*.3,SOLINK,.5),solA(abs(fract(by+.5)-.5)*.12-max(.008,.7*pq),pq)*step(.5,by)*(1.-smoothstep(.02,.05,pq)));
    col=mix(col,bc,step(4.5,tMu));
  }else if(abs(tMu-2.)<.5){
    // conveyor belt: rainbow ribbon with rollers that turn with the march
    float pq=px/(tRs*.13),by=tq.y;
    col=solC(floor(by*1.5+1.5)+3.*mod(th.w,2.)+cs)*mix(.85,1.15,step(.5,fract(by*.75+.5)));
    vec2 rq=vec2((fract(tq.x*1.5)-.5)*7.7,by);
    col=mix(col,vec3(1.8,1.7,1.5),solA(length(rq)-.42,pq));
    col=mix(col,SOLINK,solA(abs(length(rq)-.42)-.08,pq));
  }else{
    float ci=clamp(tL-1.,0.,3.),c1=step(.5,ci),c2=step(1.5,ci),c3=step(2.5,ci);
    float mo=mix(mix(mOp.x,mOp.y,c1),mix(mOp.z,mOp.w,c3),c2);
    mo=clamp(mo*(.6+.4*h2.x)+.3*bld,0.,1.);
    float tb=fract(t*.11+h2.y*7.);
    float bl=max(1.-smoothstep(0.,.012,abs(tb-.5)),blB);
    float on=mix(mix(uO2.w,uO1.y,c1),mix(uO2.y,max(uO2.x,uO1.w),c3),c2);
    float fl=1.+.7*on*(.5+.5*h2.y)+.25*dfl+1.2*gfl;
    float pq=px/tRs,lod=smoothstep(8.,17.,tRs/px);
    mo=mix(mo,clamp(mOp.w+.25*bld,0.,1.),hero);bl=mix(bl,blB,hero);lod=max(lod,hero);fl=mix(fl,1.+.3*uO1.x,hero);
    vec2 fq=tq/.4;float fs=.4,fm=solA(length(tq)-.4+max(.04,1.3*pq),pq);
    float act=step(tdl*.45,evp)*(1.-step(.55+tdl*.45,evp));
    float eo=mix(-1.,mix(mix(.25,.4,step(1.5,ev)),.1,step(2.5,ev)),act*step(.5,ev)*step(ev,3.5));
    if(tMu>2.5){col=solRainbow(tq,pq,cs,fl);fm=0.;}
    else if(tMu>.5){col=solShroom(tq,pq,h,mo,bl,cs,lod,fl);fq=(tq-vec2(0.,-.45))/.3;fs=.3;
      vec2 b=abs(tq-vec2(0.,-.48))-vec2(.25,.36);fm=solA(length(max(b,0.))+min(max(b.x,b.y),0.)-.08+max(.04,1.3*pq),pq)*step(tq.y,-.1);}
    else{col=solFlower(tq,pq,tn,tel,tph,h,h2,mo,bl,brk,cs,lod,hero*.55,fl,ov);}
    col=mix(col,solFace(col,fq,pq/fs,max(mo,step(0.,eo)*step(eo,.2)*(.3+.6*max(mOp.w,kick))),bl,brk,h,lod,eo),fm);
    // a sub-pixel carpet melts into the giant flowers' colours instead of shimmering
    col=mix(col,mix(mtint,col,step(mtint.x,-.5))*.75,(1.-smoothstep(2.,5.,tRs/px))*step(tL,.5));
    // atmospheric depth: back layers slightly darker (not while they form the giant face)
    col*=mix(mix(.86,1.,clamp(tL/3.,0.,1.)),1.,gfx);
  }
  col*=1.-.3*sh;
#if HD>=1
  col=mix(col,col*vec3(.55,.5,.75),.6*occ*mix(.55,1.,clamp(smoothstep(-1.6,-.6,tL)+gnd,0.,1.))*(1.-hero));   // v19: soft paper shadows from the sheets above
#endif
  // back-layer ink is a deep tint of the flower colour (crisp but never a black net); front ink stays black
#if HD>=1
  ink*=mix(.35,1.,clamp(smoothstep(-1.6,-.6,tL)+gnd,0.,1.));   // v19: the extra carpet stays colourful: its ink is thinner
#endif
  col=mix(col,mix(col*.28,SOLINK,max(gnd,smoothstep(10.,26.,tRs/px))),ink);
  col=mix(col,SOLINK,solA(abs(dg+.01)-.022,px));
  col=mix(col,vec3(2.1,2.,1.85),solA(od-.024,1./uRes.y)*eBn*step(0.,od));col=mix(col,SOLINK,solA(abs(od-.026)-.0035,1./uRes.y)*eBn);
  // ---- v13 air: a holographic sticker sheen, thin bands of light gliding diagonally over the whole field; brightness =
  // the air level and the hat activity (light only: it lifts the colour underneath, its strongest channel most, so hue and saturation stay)
  col+=.7*aiA*smoothstep(.55,1.,sin(dot(p0,vec2(2.3,1.4))*9.-uTime*2.6))*col*col/max(max(col.r,max(col.g,col.b)),.05);
  // ---- hat sparkles: four-point stars pop over the field on the hats / air onsets
  {
    vec2 sg=p0*7.;vec2 si=floor(sg);vec2 sf=sg-si-.5;vec4 sh4=fract(h21(si+floor(tr*2.)*7.13)*vec4(1.,13.7,71.3,313.1));
    sf-=(sh4.xy-.5)*.5;
    float sz=(.16+.26*sh4.z)*(1.+.5*uB2.w+.3*htA)*clamp(htA*1.3+uO2.w+1.4*uB2.w,0.,1.)*step(.45-.3*uB2.w-.1*htA,sh4.w)*(.75+.25*sin(uTime*7.+sh4.z*40.));
    vec2 aq=abs(sf);float ds=(aq.x*aq.y*30.+max(aq.x,aq.y)-sz*.75)/7.;
    float sp=solA(ds,1./uRes.y)*step(.001,sz);
    col=mix(col,mix(solC(floor(sh4.z*6.))*2.2,vec3(2.2,2.,1.6),clamp(1.-3.*max(aq.x,aq.y)/(sz*.75+1e-3),0.,1.)),sp);   // vivid arms, white core
  }
  // ---- transition edges: one five-band rainbow ribbon (ink separations) along the hoop ring, the flower-wave front
  // (under its marching flowers) or the opening fan blade; the fan also gets folded-paper shading and ink ribs
  if(wact>.5){
    float fr=length(fq0)*.3927,om=1.-ovf,fade=fan*(1.-smoothstep(.85,.98,wr));
    float re=(fna-floor(wst)-min(solBack(fract(wst)),1.))*fr+1e3*step(8.,wst);
    float bw=mix(.018,mix(.02,.014,fan),step(.5,wm)),x=mix(mix(length(p0)-wr+.09,mix(ws-wf+.05,re,fan),step(.5,wm)),dcd+.05,drip)/bw,pxw=1./(uRes.y*bw);
    col*=1.-.16*inB*step(.5,fbu)*fade;
    col=mix(col,SOLINK,solA(min(fbu,1.-fbu)*fr-1.6/uRes.y,1./uRes.y)*inB*fade*om);
    col=mix(col,solC(floor(x)+cs)*1.5,solA(abs(x-2.5)-2.5,pxw)*om);
    col=mix(col,SOLINK,smoothstep(pxw*1.5,0.,abs(fract(x+.5)-.5)-.04)*step(abs(x-2.5),3.)*om);
    col=mix(col,SOLINK,clamp(.5-od*uRes.y,0.,1.)*om);
  }
  fragColor=vec4(max(col,0.),0.);
}
`;
