const R_SCRIBE = `
/* GL1PH (scribe), v21: an illuminated manuscript in a script nobody can read, written stroke by stroke by the music.
   A wall of leaves of dark vellum (murex, indigo, oxblood, verdigris), each a page of an invented script in gold and pigment: ruled text lines,
   a giant initial on a tooled lapis panel ringed with red dots, a headline in the big hand, interlinear and marginal gloss in the small hand,
   line-fillers where a line ends early, an interlace border with bosses at the corners, a colophon at the foot.
   Nothing is displayed: every stroke is drawn by a broad nib (thick and thin from the stroke's direction against the nib angle, ink pooling
   at the ends) whose bright edge you can see moving. A page is never blank: it is a palimpsest, rewritten pass after pass; just ahead of
   each pen the last pass is scraped away, just behind it the new ink is wet and gleams.
   The hands: the bass writes the headline (one stroke a kick) and the initials, the mids write the text (a burst of letters on every beat,
   more when it is loud, a line ends on the bar line and the rest of it gets a filler), the highs write the gloss. The whole wall writes at once.
   Section changes turn the page (a new script, layout, palette or border spreads from the initial); impacts flood the strokes with gold. */
#define SC0 min(int(uTime),0)
// wave 3: the great book is SC_GS library books across and SC_TH of its scale thick; camera focal length and distance at zoom 1; library rings
#define SC_GS 6.
#define SC_TH .12
#define SC_DIP .035
#define SC_F 1.2
#define SC_D0 7.6
#define SC_LB 1.4
#define SC_R1 8.3
#define SC_SL .38
#define SC_RW 2.5
#define SC_BW 3.36
#define SC_R0 8.6
#define SC_LP .076
#define SC_XH .029
#define SC_GB .014
#define SC_CW .034
#define SC_CWG .0085
#define SC_XHG .0068
// wave 3 switches (compile budget): the quill of the main hand; the marginal serpents; the turning leaf's shadow ray; the fragments' second plane
// and their shadow ray
#define SC_QUILL 1
#define SC_SERP 1
#define SC_LSH 1
#if HD>=1
#define SC_FR2 1
#define SC_FSH 1
#else
#define SC_FR2 0
#define SC_FSH 0
#endif
#if HD>=5
#define SC_SS 24
#elif HD>=4
#define SC_SS 14
#elif HD>=3
#define SC_SS 9
#elif HD>=2
#define SC_SS 7
#elif HD>=1
#define SC_SS 4
#else
#define SC_SS 1
#endif
uint scH(uint x){x^=x>>16;x*=0x7feb352du;x^=x>>15;x*=0x846ca68bu;x^=x>>16;return x;}
uint scHH(uint a,uint b){return scH(a^scH(b+0x9e3779b9u));}
float scU(uint h){return float(h>>8)*5.9604645e-8;}
// palettes, seven colours each (linear): vellum, desk, text ink, rubric, panel, second pigment, gold
const vec3 SCQ[70]=vec3[70](
  vec3(.40,.05,.34),vec3(.30,.07,.05),vec3(1.,.72,.22),vec3(1.,.15,.03),vec3(.05,.18,.95),vec3(.05,.62,.30),vec3(1.,.70,.20),
  vec3(.06,.19,.58),vec3(.34,.05,.06),vec3(1.,.74,.24),vec3(1.,.13,.03),vec3(.78,.04,.20),vec3(.05,.62,.30),vec3(1.,.70,.20),
  vec3(.46,.04,.05),vec3(.12,.08,.26),vec3(1.,.74,.24),vec3(.15,.42,1.),vec3(.03,.50,.25),vec3(1.,.75,.10),vec3(1.,.70,.20),
  vec3(.03,.30,.17),vec3(.32,.06,.12),vec3(1.,.76,.26),vec3(1.,.14,.03),vec3(.45,.05,.65),vec3(.08,.26,1.),vec3(1.,.70,.20),
  vec3(.24,.07,.48),vec3(.08,.20,.14),vec3(1.,.74,.24),vec3(1.,.40,.05),vec3(.05,.55,.35),vec3(.82,.09,.26),vec3(1.,.70,.20),
  vec3(.50,.03,.17),vec3(.06,.10,.28),vec3(1.,.74,.24),vec3(.12,.36,1.),vec3(.05,.16,.85),vec3(.05,.62,.30),vec3(1.,.70,.20),
  vec3(.13,.13,.52),vec3(.30,.10,.03),vec3(1.,.82,.28),vec3(1.,.13,.04),vec3(.80,.05,.15),vec3(.05,.55,.48),vec3(1.,.70,.20),
  vec3(.02,.27,.31),vec3(.28,.04,.10),vec3(1.,.74,.24),vec3(.92,.10,.14),vec3(.40,.05,.60),vec3(1.,.78,.12),vec3(1.,.70,.20),
  vec3(.50,.12,.04),vec3(.05,.12,.26),vec3(1.,.86,.40),vec3(.12,.36,1.),vec3(.03,.45,.30),vec3(.42,.10,.72),vec3(1.,.70,.20),
  vec3(.03,.22,.46),vec3(.30,.06,.04),vec3(1.,.74,.24),vec3(1.,.50,.05),vec3(.78,.05,.18),vec3(.05,.62,.30),vec3(1.,.70,.20));
// the maker's seal: ten marks five by seven (two ints a mark: rows 0 to 3, then 4 to 6)
float scSeal(vec2 p){
  const ivec2 G[8]=ivec2[8](ivec2(508430,1086),ivec2(1020036,4228),ivec2(476721,17966),ivec2(583347,17969),
                            ivec2(1032734,16927),ivec2(1001009,17982),ivec2(476735,17969),ivec2(1001022,16912));
  const int Wm[10]=int[10](0,1,2,3,4,5,-1,6,7,4);
  float ok=step(0.,p.x)*step(p.x,59.5)*step(0.,p.y)*step(p.y,6.5);
  p=clamp(p,vec2(0.),vec2(59.,6.));
  int ci=int(p.x/6.),cx=int(p.x)-ci*6,gi=Wm[ci];
  ok*=float(gi>=0)*float(cx<=4);gi=max(gi,0);cx=min(cx,4);
  int r=6-int(p.y),bx=(G[gi].x>>(max(3-r,0)*5))&31,by=(G[gi].y>>((6-r)*5))&31;
  return float((int(mix(float(by),float(bx),float(r<4)))>>(4-cx))&1)*ok;
}
// NOTE ON STYLE (p13): the D3D11 compiler's time grows steeply with nested ifs, else-if ladders, early returns and the ?: operator (ANGLE unfolds every ?: into an
// if / else). So: one exit a function, selections by mix() with 0 / 1 masks, flat ifs on region masks, one call site for each heavy function.
// ---------------- the page being drawn (set by scSetup)
int gFam,gLay,gPal,gBor,gSty,gBand;bool gIni;vec2 gE0,gE1;uint gAl,gPg,gIs;bool gCen;
float gPx,gPress,gWT,gWH,gSlant,gLt,gMain;vec2 gNib;
// writing state: main hand line / cell / pass / filler (-1 while the line is open); headline strokes / pass; gloss cells / pass; initial progress
float gL,gC,gP,gF,gHd,gHp,gGl,gGp,gIp;
float gGoldK,gInkK,gRk,gSn,gHw,gFp,gTen;int gMode;vec2 gCC,gOrg;bool gBig;
// wave 3: the 3D world (page turn progress, ring rotation in books, leaf scale; the camera)
float gTurn,gTurnR,gRot,gSc;vec3 gCam,gFw,gRt,gUp;
#define SB(c) float(c)
vec3 kV,kD,kI,kR,kP,kS,kG;   // this page's palette: vellum, desk, text ink, rubric, panel, second pigment, gold
float scM(mat3 m,int i){vec3 c=m[0]*SB(i<3)+m[1]*SB(i>=3)*SB(i<6)+m[2]*SB(i>=6);int k=i-3*(i/3);return dot(c,vec3(SB(k==0),SB(k==1),SB(k==2)));}
// script families: 0 cursive, 1 square, 2 wheels, 3 wedges, 4 hanging: nib angle, slant, nib width, hairline
const float SCNA[5]=float[5](.62,1.1,.95,0.,.79);
const float SCSL[5]=float[5](.24,0.,.08,0.,0.);
const float SCWT[5]=float[5](.3,.32,.26,0.,.3);
const float SCWH[5]=float[5](.05,.07,.05,.2,.05);
void scFam(int f){gFam=f;float na=SCNA[f];gNib=vec2(cos(na),sin(na));gSlant=SCSL[f];gWT=SCWT[f];gWH=SCWH[f];}
// ---------------- the broad nib. A stroke is the path swept by the nib's edge (half length n, at the nib angle) plus a hairline: thick and thin come from
// the stroke's direction against the nib, and every stroke begins and ends on the nib's own slanted cut. tp > 0: a pressed wedge (a nail: heavy flat head, thin tail).
// Returns (edge distance, across -1..1, half width).
vec3 scSeg(vec2 p,vec2 a,vec2 b,float s,float tp,float wm,inout vec2 tip){
  vec2 c=b-a;float L=max(length(c),1e-4);vec2 dir=c/L,w=p-a;tip=a+c*s;
  float al=dot(w,dir),pe=dir.x*w.y-dir.y*w.x,n=.5*gWT*wm*gPress,hr=.5*gWH*gPress;
  float hwW=(hr+.35*n)*mix(1.9,.32,smoothstep(0.,.5,al/L)),dW=max(abs(pe)-hwW,max(-al,al-s*L));
  float cr=dir.x*gNib.y-dir.y*gNib.x,acr=abs(cr),hwN=n*acr+hr;
  float dN=length(w-dir*clamp(al,0.,s*L))-hr,okp=step(.04,acr)*step(1e-4,n);
  float u=(w.x*gNib.y-w.y*gNib.x)/mix(1.,cr,okp);
  dN=min(dN,mix(1e3,max(abs(pe)-n*acr,max(-u,u-s*L)*acr),okp));
  float wd=step(1e-6,tp),hw=mix(hwN,hwW,wd);
  return vec3(mix(dN,dW,wd),clamp(pe/hw,-1.,1.),hw);
}
vec3 scArc(vec2 p,vec2 o,float r,float a0,float sw,float s,float wm,inout vec2 tip){
  float sg=mix(1.,-1.,SB(sw<0.)),as=abs(sw),n=.5*gWT*wm*gPress,hr=.5*gWH*gPress;
  vec2 v=p-o;float lv=max(length(v),1e-5);
  float rel=mod(sg*(atan(v.y,v.x)-a0),TAU),ae=a0+sw*s;
  vec2 e0=o+r*vec2(cos(a0),sin(a0)),e1=o+r*vec2(cos(ae),sin(ae)),T=vec2(-gNib.y,gNib.x);tip=e1;
  float full=SB(as*s>TAU-.02),in1=max(SB(rel<=as*s),full);
  float fA=mix(SB(TAU-rel<rel-as*s),SB(length(p-e0)<length(p-e1)),in1);
  vec2 e=mix(e1,e0,fA);float an=mix(ae,a0,fA);vec2 dout=sg*(1.-2.*fA)*vec2(-sin(an),cos(an)),we=p-e;
  vec2 dir=sg*vec2(-v.y,v.x)/lv;float hwI=n*abs(dir.x*gNib.y-dir.y*gNib.x)+hr,offI=lv-r,dI=abs(offI)-hwI;
  float al=dot(we,dout),offO=dout.x*we.y-dout.y*we.x,hwO=n*abs(dout.x*gNib.y-dout.y*gNib.x)+hr,dO=max(abs(offO)-hwO,al-n-hr);
  float d=mix(dO,dI,in1),off=mix(offO,offI,in1),hw=mix(hwO,hwI,in1);
  float tc=dot(T,dout),cut=(1.-full)*step(.12,abs(tc))*SB(dot(we,we)<(1.8*n+hr)*(1.8*n+hr));
  d=max(d,mix(-1e3,dot(we,T)*sign(tc)-.5*hr,cut));
  return vec3(d,clamp(off/hw,-1.,1.),hw);
}
// ---------------- the script. Every glyph is drawn stroke by stroke in one loop (one copy of the stroke code for every family).
// stems (cursive 0, hanging 4): one to three heavy stems joined at head, waist or foot, then a bowl, a flag or a foot; square (1): the same grammar turned on
// its side, so a stack of two or three heavy bars joined by thin uprights and diagonals; wheels (2): a ring and radial ticks; wedges (3): the same grammar pressed as nails. The alphabet (gAl) fixes what each of 16 glyphs is.
// which of twenty: how many stems a glyph of this alphabet has (one hash, shared by the glyph and the cell widths)
uint scR20(uint id){return scH(gAl+id*0x9e3779b9u)%20u;}
void scU4(inout vec4 b,vec3 r,float k,float m){b=mix(b,vec4(r,k),SB(r.x<b.x)*m);}
// joins between stems by kind: start height, end height, bow
const float SCJA[8]=float[8](.76,.76,.24,.24,0.,.5,1.,.5);
const float SCJB[8]=float[8](.76,.76,.24,.24,1.,.5,0.,.5);
const float SCJK[8]=float[8](.42,.42,-.42,-.42,0.,0.,0.,.3);
// jn: bit 1 joined on the left, bit 2 on the right (words). Returns (edge distance, across, half width, stroke); tip = (pen, active)
vec4 scGlyph(vec2 p,uint id,float gw,float prog,int jn,out vec3 tip){
  uint h=scHH(gAl,id),hd=scH(h+101u),r20=scR20(id),ex=(h>>12)&7u;
  vec4 b=vec4(1e3,0.,.1,0.);tip=vec3(0.);
  p.x-=gSlant*(p.y-.5);
  vec2 tp=vec2(0.),o=vec2(gw*.5,.5);
  float f0=SB(gFam==0),f1=SB(gFam==1),f2=SB(gFam==2),f3=SB(gFam==3),f4=SB(gFam==4),fS=max(f0,f4),ini=SB(gIni);
  // strokes a glyph
  int nt=1+int((h>>5)%3u);
  float fT=fS+f1+f3;                            // the stem grammar. The square script is the same turned on its side (bars for stems, uprights for joins);
                                                // the wedge script is the same pressed as nails (heavy flat head, thin tail)
  int ns=int(mix(float(max(1+int(r20>6u)+int(r20>15u),int(f1)+1)),float(2+int((h>>3)&1u)),ini));
  ex=uint(mix(float(ex),float(ex&3u),ini*fT));
  int n=int(f2*float(nt+1)+fT*float(2*ns-1+int(ex<5u)));
  float rr=.34+.06*scU(h^7u),ra0=floor(scU(h)*8.)*.7854,rsw=mix(TAU,TAU*.78,SB((h&16u)!=0u))*mix(-1.,1.,SB((h&32u)!=0u));
  float fn=float(n),sp=gw/float(ns);
  for(int i=SC0;i<7;i++){
    float fi=float(i),s=clamp(prog*fn-fi,0.,1.),on=SB(i<n),isJ=SB(i==6),even=SB((i&1)==0);
    int kk=i/2;uint hk=(hd>>(4*kk))&15u;float fk=float(kk);
    // wheels: the ring, then radial ticks
    int t=max(i-1,0);float an=floor(scU(scH(h+uint(t)*31u))*8.)*.7854+.3927;vec2 dv2=vec2(cos(an),sin(an));float ow=float((hd>>t)&1u);
    vec2 a2=o+dv2*rr*mix(.2,1.,ow),e2=o+dv2*mix(rr*.8,rr+.4,ow);float ring=f2*SB(i==0);
    // stems: a stem, a join to the next, then the bowl / flag / foot
    float x=sp*(fk+.5),isX=SB(i==2*ns-1),ev0=even*(1.-isX);
    float yt=mix(mix(mix(1.,.55,SB(hk==3u)*SB(ns>1)),1.62,SB(hk==0u)),1.,max(f4,ini));
    float yb=mix(mix(mix(0.,-.62,SB(hk>=1u)*SB(hk<3u)),0.,ini),mix(mix(0.,.38,SB(hk<8u)),-.55,SB(hk<4u)),f4);
    float kS=mix(-.12,.12,float((hk>>3)&1u))*mix(.6,1.,f0);
    uint jk=(hd>>(12+3*kk))&7u;int ji=int(jk)+2*int(f4)*int(jk<2u);
    float xl=sp*(float(ns)-.5),x0=sp*.5,kq=min(.5,(sp*.5-.03)/.55);
    float x0e=SB(ex==0u),x1e=SB(ex==1u),x2e=SB(ex==2u),x3e=SB(ex==3u),x4e=SB(ex>=4u);
    vec2 aX=vec2(xl,.56)*x0e+vec2(xl,1.)*(x1e+x2e)+vec2(x0,.56)*x3e+vec2(x0,0.)*x4e;
    vec2 eX=vec2(xl,0.)*x0e+vec2(xl,.44)*x1e+vec2(xl+sp*.42,.9)*x2e+vec2(x0,0.)*x3e+vec2(x0-sp*.42,.1)*x4e;
    vec2 a0=mix(mix(vec2(x,SCJA[ji]),vec2(x,yt),ev0),aX,isX),e0=mix(mix(vec2(x+sp,SCJB[ji]),vec2(x,yb),ev0),eX,isX);
    float k0=mix(mix(SCJK[ji],kS,ev0),kq*(x0e+x1e-x3e)-.2*(x2e+x4e),isX);
    // joins (stroke 6): the cursive runs on a baseline hairline, the hanging script hangs from a bar
    float jl=float(jn&1),jr=float((jn>>1)&1);
    vec2 aJ=vec2(mix(gw*mix(.1,.16,f0),0.,jl),mix(1.08,0.,f0)),eJ=vec2(mix(gw*mix(.9,.84,f0),gw,jr),aJ.y);
    // this stroke
    vec2 a1=vec2((clamp(a0.y,-.1,1.1)*.8+.1)*gw,1.-a0.x/gw),e1=vec2((clamp(e0.y,-.1,1.1)*.8+.1)*gw,1.-e0.x/gw);
    vec2 a=mix(a0*(fS+f3)+a1*f1+a2*f2,aJ,isJ),e=mix(e0*(fS+f3)+e1*f1+e2*f2,eJ,isJ);
    float k=k0*fS*(1.-isJ),tpr=(.5*f2+f3)*(1.-isJ),wm=mix(mix(1.,mix(1.6,1.,ev0),f1),0.,isJ),dx=.035*f4*isJ;
    on=mix(on,fS,isJ);s=mix(s,clamp(prog*mix(2.,1.5,f0),0.,1.),isJ);ring*=1.-isJ;
#if HD>=1
    gE0=mix(gE0,a,SB(i==0));gE1=mix(gE1,e,on*(1.-isJ));
#endif
    // a bowed stroke is an arc through a and e (sagitta / chord = k)
    float bow=SB(abs(k)>=.03)*(1.-ring),kb=mix(.25,k,bow);
    vec2 c=e-a;float L=max(length(c),1e-4);vec2 nn=vec2(-c.y,c.x)/L;float sg=kb*L,arB=(L*L*.25+sg*sg)/(2.*abs(sg));
    vec2 m=(a+e)*.5,acB=m-nn*sign(sg)*(arB-abs(sg));float aaB=atan(a.y-acB.y,a.x-acB.x),aswB=2.*asin(min(1.,.5*L/arB));
    vec2 ap=m+nn*sg-acB,ab=a-acB;aswB*=mix(1.,-1.,SB(ab.x*ap.y-ab.y*ap.x<0.));
    float live=on*step(1e-6,s),arc=max(ring,bow);
    vec3 r=vec3(1e3,0.,.1);
    if(live*arc>.5)r=scArc(p,mix(acB,o,ring),mix(arB,rr,ring),mix(aaB,ra0,ring),mix(aswB,rsw,ring),s,wm,tp);
    if(live*(1.-arc)>.5)r=scSeg(p,a,e,s,tpr,wm,tp);
    r.x-=dx;
    scU4(b,r,fi,live);
    tip=mix(tip,vec3(tp,1.),live*SB(s<1.)*(1.-isJ));
  }
  // points: inside a wheel, in a square glyph, a diacritic once the glyph is done
  float rd=.1*gPress;scU4(b,vec3(length(p-o)-rd,0.,rd),6.,f2*SB((h&0x400u)!=0u)*SB(prog*fn>=1.));
  rd=.11*gPress;scU4(b,vec3(length(p-vec2(gw*.5,mix(.34,.5,SB(ns==2))))-rd,0.,rd),6.,f1*SB((h&0x300u)==0u)*SB(prog>.5));
  uint dk=(h>>27)&3u;
  rd=.095*gPress;scU4(b,vec3(length(p-vec2(gw*.5,mix(-.42,1.5,SB(dk==0u))))-rd,0.,rd),5.,SB(dk<2u)*SB(prog>=1.));
  return b;
}
// ---------------- inks: relief and gloss. Gold is raised and burnished (a crisp line of light that moves with the light), wet ink gleams; all by scaling, never adding white
vec2 gW;
vec3 scShade(vec3 ink,float ac,float gold,float wet){
  float sp=exp(-(ac-gLt)*(ac-gLt)*22.);
  vec3 c=ink*(.6+.4*sqrt(max(1.-ac*ac,0.)));
#if HD>=1
  {float pp=.0021,vis=smoothstep(2.5,6.,pp/gPx);
   vec2 wt=gW/gSc,f=fract(wt/pp+vec2(.5*floor(wt.y/pp),0.))-.5;float pn=smoothstep(.3,.18,length(f));c*=1.-vis*(gold*.32*pn);
   float st=.5+.5*cos(ac*PI*5.);c*=1.-vis*(1.-gold)*.16*st;}
#endif
  return c*(1.+(.75*gold+.55*wet)*sp);
}
float scAA(float d,float hw,float pu){float h2=max(hw,.5*pu);return clamp((h2-d-hw)/pu+.5,0.,1.)*(hw/h2);}
float scAC(float d,float hw,float pu){return clamp((hw-d)/pu+.5,0.,1.);}
float scBox(float x,float a,float b,float pu){return clamp((min(x+.5*pu,b)-max(x-.5*pu,a))/pu,0.,1.);}
// ---------------- text lines
uint scCode(uint ps,int l,int j){return scH(ps+uint(l*97+j+11)*0x9e3779b9u);}
uint scId(uint c){return uint(floor(pow(scU(c),1.75)*16.));}
float scWd(uint c){uint r20=scR20(scId(c));return mix(.62+.38*SB(r20>6u)+.4*SB(r20>15u),.7+.6*scU(c*0x2545f491u),SB(gFam>=1)*SB(gFam<=2));}
float scCand(uint ps,int l,int j,float pr){return SB(scU(scH((ps^0x5bd1e995u)+uint(l*97+j)*0x85ebca6bu))<pr);}
// a space: an odd cell inside the line, by its hash (so two never touch)
float scSp(uint ps,int l,int j,int len){return SB(j>0)*SB(j<len-1)*float(j&1)*scCand(ps,l,j,.36);}
int scCell(float xr,uint ps,int l,int C,out float f,out float wc){
  int pr=int(floor(xr*.5));float g=xr-2.*float(pr),lone=SB(2*pr+1>=C);
  float w0=scWd(scCode(ps,l,2*pr)),w1=scWd(scCode(ps,l,2*pr+1)),s=2.*w0/(w0+w1),sec=(1.-lone)*SB(g>=s);
  wc=mix(mix(s,2.-s,sec),1.,lone);f=mix(mix(g/s,(g-s)/(2.-s),sec),g,lone);
  return 2*pr+int(sec);
}
uint scPs(float pass){return scHH(gPg,uint(pass+4096.));}
int scLen(int l,int C,float pass){
  int a=min(C,(int(scM(uM1,l/4))>>(5*(l-4*(l/4))))&31),b=C-int(scU(scHH(scPs(pass),uint(l)+77u))*float(C)*.45);
  return int(mix(float(b),float(a),SB(gCen)));
}
// a line-filler from cell x0 of the line (xr in cells), drawn up to fp: a wave, a lozenge chain, dots or a zigzag. Glyph units.
vec3 scFill(vec2 g,float xr,float x0,float fp,float cwu,uint fh){
  float xf=xr-x0,in1=step(0.,xf)*step(xf,fp),u=xf*cwu,xs=xf-gFp*2.,k=PI/cwu,ph=u*k*1.3-gFp*TAU*2.;
  float d0=abs(g.y-(.48+.3*sin(ph)))/sqrt(1.+pow(.39*k*cos(ph),2.))-.055;
  float lx=(fract(xs)-.5)*cwu,d1=abs(abs(lx)*.75+abs(g.y-.5)-.3)-.05;
#if HD>=1
  float t=float(fh&3u);
  float d2=length(vec2(lx,g.y-.5+.18*sign(fract(xs*.5)-.5)))-.12;
  float d3=abs(g.y-(.15+.7*abs(fract(u*.9-gFp*2.)-.5)*2.))*.7-.05;
  float d=mix(mix(mix(d3,d2,step(t,2.5)),d1,step(t,1.5)),d0,step(t,.5));
  return vec3(mix(1e3,d,in1),0.,mix(mix(.05,.12,step(1.5,t)*step(t,2.5)),.055,step(t,.5)));
#else
  float t=float(fh&1u);
  return vec3(mix(1e3,mix(d0,d1,t),in1),0.,mix(.055,.05,t));
#endif
}
// pen at the tip: the nib's own bright edge at the nib angle, and a wet point
vec4 scPen(vec2 g,vec3 tip,vec3 ink,float pu){
  vec2 d=g-tip.xy;float al=dot(d,gNib),ac=dot(d,vec2(-gNib.y,gNib.x));
  float nib=length(vec2(max(abs(al)-gWT*.5-.04,0.),ac))-.035;
  float c=scAC(nib+.035,.035,pu),dot1=scAC(length(d),.08,pu);
  float a=max(c,dot1);float halo=exp(-dot(d,d)*6.)*.35;
  return vec4(min(ink*1.9,vec3(1.6))*a+ink*halo*(1.-a),max(a,halo*.6))*step(.5,tip.z);
}
vec4 scOver(vec4 under,vec4 top){return vec4(top.rgb+under.rgb*(1.-top.a),top.a+under.a*(1.-top.a));}
// ---------------- the one glyph of this pixel. A page region (text line, gloss, headline, initial) only sets the job up; scPage draws the glyph once and finishes it.
int jK,jJn,jL;vec2 jG,jLq;uint jId;float jGw,jProg,jPu,jLt,jOldA,jWet,jGold,jBar,jDim,jCw,jPen,jLine;vec3 jInk,jInk0;vec4 jFx;
// one line of main text at lq (l: slot, W wide, C cells): sets the glyph job (jK = 1), or returns what there is without one (the filler, the flourishes)
vec4 scLine(vec2 lq,int l,float W,int C,vec3 ink0,vec3 rub){
  float cw=W/float(C),xr=lq.x/cw,cwu=cw/SC_XH,pu=gPx/SC_XH,gy=lq.y/SC_XH;
  int iL=int(gL);float fl=float(l),cur=SB(l==iL);
  // a snare whips a hairline across the line being written
  float sa=uP4.w,yv=1.42+.16*sin(lq.x*60.+fl*1.7),m1=step(lq.x,W*min(sa/.16,1.))*(1.-smoothstep(.3,1.3,sa))*cur;
  float cv1=scAC(abs(gy-yv)*SC_XH,.0011+.0016*m1,gPx)*m1;vec4 fx=vec4(rub*1.15*cv1,cv1);
  float inB=step(-.9,gy)*step(gy,1.9);
  jLine=1.;jLq=lq;jL=l;jCw=cw;jInk0=ink0;
  // this line: written (earlier lines, or the current one once it is closed and its filler runs), being written, or still the last pass
  float fill=cur*step(0.,gF),wr=max(SB(l<iL),fill),op=cur*(1.-fill),later=SB(l>iL),fp=mix(1.,gF,fill);
  int pr=int(floor(xr*.5));
  float nw=max(wr,op*SB(float(2*pr)<gC)),pass=gP-1.+nw;uint ps=scPs(pass);
  int len=int(mix(float(scLen(l,C,pass)),ceil(gC),op*nw));
  float f,wc;int j=scCell(xr,ps,l,C,f,wc);float fj=float(j);
  float ahead=mix(mix(fj-gC,-1.,nw),(fl-float(iL))*20.+fj-gC,later);
  float age=mix(99.,mix((gL-fl)*20.+gC-fj,gC-fj,op),nw);
  float oldA=max(nw,smoothstep(.7,4.5,ahead)),wet=exp(-max(age,0.)/9.),prog=mix(1.,clamp(gC-fj,0.,1.),op*nw),lt=smoothstep(1.4,3.,SC_XH/gPx);
  // the line-filler after the last glyph
  float isF=SB(j>=len),fpF=mix(fp,1.,op*(1.-nw))*float(C-len),fok=isF*(1.-op*nw);
  vec3 r=scFill(vec2(0.,gy),xr,float(len),fpF,cwu,scHH(ps,uint(l)+5u));
  float cvF=(scAA(r.x,r.z,pu)*lt+(1.-lt)*.3*scBox(gy,.2,.8,pu)*step(float(len),xr)*step(xr,float(len)+fpF))*fok*oldA;
  vec4 res=scOver(vec4(rub*.9*cvF,cvF),fx);
  // the glyph: its word (back to the word's first cell: rubric words, joins)
  float gok=inB*step(1e-5,oldA)*(1.-isF)*(1.-scSp(ps,l,j,len));
  int o1=j-1-(j&1);float n1=1.-scSp(ps,l,o1,len),n2=n1*(1.-scSp(ps,l,o1-2,len)),n3=n2*(1.-scSp(ps,l,o1-4,len));
  int ws=max(o1+1-2*int(n1+n2+n3),0);
  float wu=scU(scHH(ps,uint(l*131+ws))),rubw=SB(wu<.13),bluw=SB(wu>.93),vers=SB(j==0)*SB(scU(scHH(ps,uint(l)+919u))<.42);
  vec3 blu=mix(mix(kS,kS*.6,SB(gBand==3)),kR,SB(gBand==2));
  vec3 ink=mix(mix(mix(ink0,blu,bluw),rub,rubw),mix(kP*1.25,rub,SB((l&1)==0)),vers);
  float gold=(1.-max(rubw,bluw))*(1.-SB(gBand==3))*(1.-vers)*gMain;
  float jl=SB(j>0)*(1.-scSp(ps,l,j-1,len)),jr=SB(j<len-1)*(1.-scSp(ps,l,j+1,len)),gw=wc*cwu;
  if(gok>.5){
    jK=1;jG=vec2(f*gw,gy);jId=scId(scCode(ps,l,j));jGw=gw;jProg=prog;jJn=int(jl)+2*int(jr);jPu=pu;jLt=lt;jOldA=oldA;jWet=wet*nw;jGold=gold;jInk=ink;
    jBar=.72*scBox(gy,0.,1.,pu)*scBox(f*gw,.12*gw,.88*gw+jr*.12*gw,pu)*prog;jDim=mix(.82,1.,nw);jPen=op*nw;jFx=fx;
    gPress=mix(1.+.3*(uP5.w-1.),uP5.w,wet)*(1.+.45*vers);
  }
  return res*inB*(1.-gok);
}
// gloss in the small hand (interlinear above line l: band yt-SC_GB .. yt; margins; colophon): sets the glyph job (jK = 2) where there is a glyph
void scGloss(vec2 lq,int l,float row,float stride,float W,vec3 ink,uint salt,float gl,float gp){
  float pu=gPx/SC_XHG,gy=(lq.y+SC_GB-.0045)/SC_XHG,xr=lq.x/SC_CWG,gw=SC_CWG/SC_XHG;
  int C=int(W/SC_CWG),j=int(floor(max(xr,0.)));float idx=row*stride+float(j),nw=SB(idx<gl);
  uint ps=scHH(scPs(gp-1.+nw),salt);
  int grp=j/9,gj=j-grp*9;float mid=SB(gj>1)*SB(gj<7);
  float oldA=max(nw,smoothstep(.8,9.,idx-gl));
  float ok=step(-.8,gy)*step(gy,1.75)*step(0.,xr)*SB(xr<float(C))*SB(scU(scHH(ps,uint(l*37+grp)))<=.42)*SB(gj>0)*SB(gj<8)*(1.-scCand(ps,l+50,j,.2)*mid)*step(1e-5,oldA);
  if(ok>.5){
    jK=2;jG=vec2((xr-float(j))*gw,gy);jId=scId(scCode(ps,l,j));jGw=gw;jProg=mix(1.,clamp(gl-idx,0.,1.),nw);jJn=3*int(mid);jPu=pu;jLt=smoothstep(1.3,2.8,SC_XHG/gPx);
    jOldA=oldA;jWet=nw*exp(-max(gl-idx,0.)/30.);jGold=0.;jInk=ink;jBar=.36*scBox(gy,0.,1.,pu)*jProg;jDim=1.;jPen=nw;jFx=vec4(0.);gPress=1.;
  }
}
// ---------------- the giant initial on its tooled panel (R: x0,y0,x1,y1)
#if HD>=1
// an archimedean spiral of gold round c (radius rr): distance to its line
float scSpiral(vec2 p,vec2 c,float rr,float sg){
  vec2 d=p-c;float rho=length(d),th=atan(d.y,d.x)*sg+PI,k=rr/(2.2*TAU);
  float n=floor((rho/k-th)/TAU+.5),dd=abs(rho-k*(th+TAU*clamp(n,0.,1.)));
  return mix(dd,1e3,SB(rho>rr*1.05));
}
#endif
vec3 iCol;float iSd,iOa,iClip,iFr,iOld,iGoldG;
// part one: the tooled panel; sets the glyph job (jK = 4)
void scIniA(vec2 q,vec4 R,float circ){
  vec2 c=(R.xy+R.zw)*.5,hs=(R.zw-R.xy)*.5,d=abs(q-c)-hs;float sd=mix(max(d.x,d.y),length(q-c)-hs.x,circ);
  vec3 P=kP,Gd=kG,S2=kS;
  iGoldG=SB((gIs&2u)==0u);
  // ground: burnished gold tooled with punched points and a fine lozenge, or pigment with a gold diaper
  float s=.024;vec2 dq=(q-c)/s;
  float l1=abs(fract((dq.x+dq.y)*.5)-.5),l2=abs(fract((dq.x-dq.y)*.5)-.5),pu=gPx/s,dl=min(l1,l2)*1.414;
  float di=smoothstep(.06+pu,.06,dl)*smoothstep(1.5,4.,s/gPx);
  vec2 pf=fract((q-c)/.008)-.5;float pn=scAC(length(pf*.008),.0017,gPx)*smoothstep(2.,4.,.008/gPx);
  vec3 cg=mix(Gd*(.78+.22*vnoise((q-c)*60.))*(1.-.35*pn),Gd*.45,di*.55);
  vec3 cp=mix(mix(P*.62,Gd*.8,di*.8),S2,scAC(length(vec2(l1,l2)),.12,pu)*smoothstep(1.5,4.,s/gPx));
  iCol=mix(cp,cg,iGoldG);iSd=sd;iFr=max(scBox(sd,-.006,0.,gPx),scBox(sd,-.013,-.0095,gPx));
  // the letter: a heavy glyph of the script, its body woven of two pigments, a gold edge, a dark outline, spirals at its ends
  float xh=2.*hs.y/1.62;
  iOld=SB(gIp<.15);iOa=mix(1.,1.-gIp/.15,iOld);iClip=smoothstep(-.012,-.02,sd);
  jK=4;jG=vec2(q.x-R.x,q.y-(R.y+.31*xh))/xh;jId=15u;jGw=2.*hs.x/xh;jProg=mix((gIp-.15)/.85,1.,iOld);jJn=0;jPu=gPx/xh;jLt=1.;jInk=Gd;jPen=(1.-iOld)*SB(gIp<1.);gPress=1.;
}
// part two: the letter over the panel
vec4 scIniB(vec4 b,vec4 pn){
  vec3 P=kP,Gd=kG,Ru=kR,S2=kS,K=kD*.35,col=iCol;
  vec2 g=jG;float pug=jPu,oa=iOa;
  b.x=mix(1.,b.x,iClip);
  // red dots round the letter (on a pigment ground) or a dark halo (on gold)
  vec2 dg=fract(g/.13)-.5;float dd=length(dg*.13);
  float band=step(.06,b.x)*step(b.x,.16)*smoothstep(1.,2.5,.13/pug);
  col=mix(col,mix(Ru,K,iGoldG),scAC(dd,.032,pug)*band*oa);
  // spiral terminals
#if HD>=1
  float sp=mix(min(scSpiral(g,gE0,.42,1.),scSpiral(g,gE1,.36,-1.)),1e3,iOld);
  float spl=scAC(sp,.05,pug)*iClip,spo=scAC(sp,.09,pug)*iClip;
  col=mix(col,K,spo*oa);col=mix(col,mix(Gd,Ru,iGoldG),spl*oa);
#endif
  float ol=scAA(b.x-.06,b.z+.06,pug),cv=scAA(b.x,b.z,pug),inn=scAA(b.x+.07,max(b.z-.07,.01),pug);
  // the woven body
  vec2 uv=vec2(g.x+g.y,g.x-g.y)*.7071/.2;
  float na=floor(uv.y),nb=floor(uv.x),da=abs(fract(uv.y)-.5)*.2,db=abs(fract(uv.x)-.5)*.2,aT=SB(mod(na+nb,2.)<.5);
  float si=mod(b.w,3.),s0=SB(si<.5),s1=SB(si>=.5)*SB(si<1.5),s2=SB(si>=1.5),pk=.8+.2*max(uB2.x,uB2.y);
  vec3 c1=(Ru*s0+S2*s1+P*1.2*s2)*pk,c2=(S2*s0+P*1.2*s1+Ru*s2)*pk;
  float rw=.062,dt=mix(db,da,aT),dbb=mix(da,db,aT);
  vec3 body=K;
  body=mix(body,mix(c1,c2,aT)*.8,scAC(dbb,rw,pug));
  body=mix(body,K,scAC(dt,rw*1.45,pug));
  body=mix(body,mix(c2,c1,aT)*.92,scAC(dt,rw,pug));
  body=mix((c1+c2)*.45,body,smoothstep(1.,3.,rw/pug));
  col=mix(col,K,ol*oa);
  col=mix(col,scShade(Gd,b.y,1.,0.),cv*oa);
  col=mix(col,body,inn*oa);
  col=col*(1.-pn.a)+pn.rgb;
  col=mix(col,Gd*.93,iFr);
  return vec4(col,smoothstep(.004,0.,iSd));
}
// a vine for the margins: stem, gold curls, leaves, berries; transparent elsewhere. u along, v across, bw half width
vec4 scVine(float u,float v,float bw,float grow){
  vec3 Gd=kG,Ru=kR,S2=kS;
  float k=PI/(bw*2.4),A=bw*.4,th=u*k,s1=A*sin(th),sl=sqrt(1.+pow(A*k*cos(th),2.));
  float n=floor(th/PI),uc=(n+.5)*PI/k,sg=mix(-1.,1.,SB(mod(n,2.)<.5));
  vec2 pp=vec2(u,v),cc=vec2(uc+bw*.12,-sg*A*.55);
  float an=mod(atan(pp.y-cc.y,pp.x-cc.x)*sg,TAU);
  float curl=abs(length(pp-cc)-bw*.3*(.55+.45*an/TAU))+SB(an<.6);
  vec2 lc=vec2(n*PI/k+bw*.05,sg*A*.95),lq=pp-lc;lq=vec2(lq.x*.8+lq.y*.6*sg,-lq.x*.6*sg+lq.y*.8);
  float leaf=length(lq/vec2(1.,.42))-bw*.26,ber=length(pp-vec2(uc-bw*.35,sg*A*.2))-bw*.07;
  vec4 o=vec4(0.);
  float a1=scAC(abs(v-s1)/sl,bw*.1,gPx);o=scOver(o,vec4(kD*.3*a1,a1));
  float a2=scAC(abs(v-s1)/sl,bw*.065,gPx);o=scOver(o,vec4(S2*a2,a2));
  float a3=scAC(curl,bw*.05,gPx);o=scOver(o,vec4(Gd*a3,a3));
  float a4=scAA(leaf,bw*.03,gPx);o=scOver(o,vec4(mix(kD*.3,Ru,smoothstep(0.,-bw*.04,leaf))*a4,a4));
  float a5=scAA(ber,bw*.02,gPx);o=scOver(o,vec4(Gd*a5,a5));
  o.rgb*=.72+.28*max(uB2.z,uB2.w);   // the highs light the vines
  return o*step(u,grow);
}
// the border: a band of interlace (a two-strand cable, over and under; or a ground for the vine) between gold rules, bosses at the corners
vec4 scBorder(vec2 q,vec2 B,float bw){
  float dx=abs(q.x)-B.x,dy=abs(q.y)-B.y;
  float side=SB(abs(dx)<bw)*SB(abs(q.y)<B.y+bw),top=SB(abs(dy)<bw)*SB(abs(q.x)<B.x+bw);
  vec3 P=kP,Gd=kG,Ru=kR,S2=kS,K=kD,base=P*.5,gl=scShade(Gd,0.,1.,0.);
  // corner boss
  vec2 cq=vec2(dx,dy);float r=length(cq),ring=scAC(abs(r-bw*.62),bw*.13,gPx),lob=abs(length(abs(cq)-bw*.3182)-bw*.3);
  vec3 cb=mix(base,Ru*.85,smoothstep(bw*.5,bw*.45,r));cb=mix(cb,gl,max(ring,scAC(lob,bw*.08,gPx)));cb=mix(cb,S2,scAC(r,bw*.16,gPx));
  float u=mix(q.x,q.y,side),v=mix(dy,dx,side);
  // a cable of two strands; the one with the larger depth is on top
  float k=PI/(bw*1.6),A=bw*.48,rw=bw*(.2+.1*max(uB2.x,uB2.y)),gB=SB(gBor==1);
  float pr=.78+.22*max(uB2.x,uB2.y);vec3 c1=mix(S2*pr,Gd,gB),c2=Ru*pr;   // the presence band lights the pigment strands
  float th=u*k+PI*gSn,s1=A*sin(th),z1=cos(th),sl=sqrt(1.+pow(A*k*cos(th),2.));
  float d1=abs(v-s1)/sl,d2=abs(v+s1)/sl,one=SB(z1>0.);
  float dt=mix(d2,d1,one),db=mix(d1,d2,one),gb=mix(.3,1.,gB),zt=abs(z1);
  vec3 ct=mix(c2,c1,one),cu=mix(c1,c2,one),sc=base;
  sc=mix(sc,K,scAC(db,rw*1.45,gPx));
  sc=mix(sc,scShade(cu,clamp(mix(v-s1,v+s1,one)/rw,-1.,1.),gb,0.)*(.72-.2*zt),scAC(db,rw,gPx));
  sc=mix(sc,K,scAC(dt,rw*1.45,gPx));
  sc=mix(sc,scShade(ct,clamp(mix(v+s1,v-s1,one)/rw,-1.,1.),gb,0.)*(.72+.28*zt),scAC(dt,rw,gPx));
  sc=mix(mix(base,mix(c1,c2,.5)*.7,.62),sc,smoothstep(1.2,3.5,rw/gPx));
  vec3 col=mix(sc,base,SB(gBor==2));   // the vine border: its vine is drawn by the page's one vine call
  // gold rules both sides
  col=mix(col,gl*.9,max(scBox(abs(v),bw*.86,bw,gPx),scBox(abs(v),bw*.78,bw*.82,gPx)*.6));
  return vec4(mix(col,cb,side*top),max(side,top));
}
// the carpet page: a cross of pigment between quadrants of over-and-under weave, kicks run light along the ribbons
vec4 scCarpet(vec2 q,vec4 R){
  vec2 c=(R.xy+R.zw)*.5,hs=(R.zw-R.xy)*.5,d=abs(q-c)-hs;float sd=max(d.x,d.y);
  vec3 P=kP,Gd=kG,Ru=kR,S2=kS,K=kD;
  vec2 p=q-c;float S=.042,rw=S*.29;
  vec2 uv=vec2(p.x+p.y,p.x-p.y)*.7071/S;
  float na=floor(uv.y),nb=floor(uv.x),da=abs(fract(uv.y)-.5)*S,db=abs(fract(uv.x)-.5)*S,aT=SB(mod(na+nb,2.)<.5);
  float ia=mod(na,3.),ib=mod(nb+1.,3.);
  vec3 ca=mix(mix(Gd,S2,SB(ia>.5)*SB(ia<1.5)),Ru,SB(ia<.5)),cb=mix(mix(Gd,S2,SB(ib>.5)*SB(ib<1.5)),Ru,SB(ib<.5));
  float pa=.75+.55*exp(-pow(fract(uv.x*.0625-uP4.z)-.5,2.)*60.),pb=.75+.55*exp(-pow(fract(uv.y*.0625-uP4.z*.7)-.5,2.)*60.);
  vec3 col=P*.35;
  float dt=mix(db,da,aT),dbb=mix(da,db,aT);vec3 ct=mix(cb*pb,ca*pa,aT),cbt=mix(ca*pa,cb*pb,aT);
  vec3 w=col;
  w=mix(w,K*.4,scAC(dbb,rw*1.4,gPx));w=mix(w,scShade(cbt,0.,.3,0.),scAC(dbb,rw,gPx));
  w=mix(w,K*.4,scAC(dt,rw*1.4,gPx));w=mix(w,scShade(ct,clamp((mix(fract(uv.x),fract(uv.y),aT)-.5)*S/rw,-1.,1.),.4,0.),scAC(dt,rw,gPx));
  col=mix(mix(col,(Ru+S2+Gd)*.22,.6),w,smoothstep(1.,3.,rw/gPx));
  // the cross and its rules
  float arm=min(min(abs(p.x),abs(p.y))-.028,length(p)-.15);
  col=mix(col,K*.5,scAA(arm-.004,.004,gPx));
  col=mix(col,P*.55,step(arm,0.));
  col=mix(col,Gd,scBox(arm,-.006,-.002,gPx));
  col=mix(col,Gd*.95,max(scBox(sd,-.006,0.,gPx),scBox(sd,-.013,-.0095,gPx)));
  return vec4(col,1.);
}
// ---------------- marginal beasts (the great book only): two knotwork serpents chase each other round the border, lunge a step on every kick and
// the kick throws each one's head up off the border in a leap. u along the border loop (P long), v out from its middle line
float gGrow,gFrH,gFrS,gFrA,gFrZ,gFrX;
vec4 scSerp(float u,float v,float P,float uh,float bw,vec3 c1,vec3 c2){
  float s=mod(uh-u,P),sh=s-P*SB(s>P-.15),Lb=.9;
  float ka=uP3.w,lp=bw*1.9*exp(-sh*sh*12.)*sin(clamp(ka/.45,0.,1.)*PI);
  float hw=bw*.42*mix(1.,.1,smoothstep(.12,Lb,sh)),dv=v-(bw*.34*sin(sh*30.-uTime*2.6)*smoothstep(-.02,.08,sh)+lp);
  // body: a plait of two strands over a dark ground; head: gold, an eye, a curl at the jaw
  float th=sh*72.,s1=hw*.5*sin(th),one=SB(cos(th)>0.),d1=abs(dv-s1),d2=abs(dv+s1),dt=mix(d2,d1,one),db=mix(d1,d2,one),rw=hw*.34;
  vec3 K=kD*.22,col=K;
  col=mix(col,mix(c2,c1,one)*.72,scAC(db,rw,gPx));col=mix(col,K,scAC(dt,rw*1.5,gPx));col=mix(col,mix(c1,c2,one)*1.05,scAC(dt,rw,gPx));
  col=mix(mix(c1,c2,.5)*.8,col,smoothstep(.8,2.5,rw/gPx));
  float dB=mix(1e3,abs(dv)-hw,SB(sh>=0.)*SB(sh<=Lb)),hy=dv-lp*.15,dH=(length(vec2((sh+.055)/.07,hy/(bw*.5)))-1.)*bw*.5;
  float eye=scAC(length(vec2(sh+.075,hy-bw*.17)),bw*.1,gPx),curl=scAC(abs(length(vec2(sh+.03,hy+bw*.28))-bw*.2),bw*.05,gPx)*SB(sh>-.03);
  float isH=SB(dH<dB);
  vec3 hc=c1*(.8+.35*smoothstep(bw*.5,-bw*.3,hy));hc=mix(hc,K,eye);hc=mix(hc,kR,eye*scAC(length(vec2(sh+.075,hy-bw*.17)),bw*.045,gPx));
  col=mix(col,hc,isH);col=mix(col,c2,curl);
  float d=min(dB,dH),aO=scAC(d,bw*.09,gPx),aI=scAC(d,0.,gPx);
  col=mix(K,col,aI/max(aO,1e-4));
  return vec4(col*aO,aO);
}
vec4 scBeast(vec2 q,vec2 B,float bw){
  vec2 a=abs(q)-B;float sv=SB(a.x>a.y),v=mix(a.y,a.x,sv),P=4.*(B.x+B.y);
  float u=mix(mix(4.*B.y+3.*B.x+q.x,2.*B.y+B.x-q.x,SB(q.y>0.)),mix(2.*B.y+2.*B.x+B.y-q.y,q.y+B.y,SB(q.x>0.)),sv);
  float uh=mod(.05*uTime+.055*gRot+scU(gPg)*P,P),hf=SB(mod(uh-u+.15,P)>=P*.5);   // which of the two (half a loop apart): one call draws both
  return scSerp(u,v,P*.5,uh,bw,mix(kG,kS*1.15,hf),mix(kR,kG,hf));
}
// ---------------- the page
vec3 scPage(vec2 q,vec2 pid){
  vec3 G=kV,ink=kI,rub=kR*(.74+.26*max(uB2.x,uB2.y)),Gd=kG;
  // vellum: a fine follicle grain and darker edges
  float gr=sin(q.y*900.+3.*sin(q.x*31.+q.y*7.))*smoothstep(4.,14.,.007/gPx);
  float mo=vnoise(q*7.+vec2(float(gPg&255u)));
  vec3 col=G*(1.1+.38*mo+.06*gr)*(1.-.2*smoothstep(.25,.0,min(.5-abs(q.x),.68-abs(q.y))*2.));
  {float sD=.026;vec2 f=abs(fract(vec2(q.x+q.y,q.x-q.y)/sD*.5)-.5);float vis=smoothstep(2.5,6.,sD/gPx);   // a tone-on-tone diaper in the ground
   float hi=max(uB2.z,uB2.w),on=max(uO2.z,uO2.w),pr0=.085+.075*hi,pt=smoothstep(pr0+gPx/sD,pr0,length(f-.5));
   float bd=fract((gW.x*.8+gW.y*.6)*.55-gHw);bd=exp(-(bd-.5)*(bd-.5)*26.);
   col*=1.+vis*(.24*smoothstep(.05+gPx/sD,.05,min(f.x,f.y))+(.22+.55*hi)*pt);
   col=mix(col,Gd*1.1,vis*pt*clamp(bd*(.75+.6*on),0.,1.));
#if HD>=1
   {float rv=smoothstep(8.,16.,sD/gPx);col*=1.+rv*.3*smoothstep(.03,.01,abs(length(f-.5)-.2));
    col*=1.-rv*.3*smoothstep(.05,.03,length(f-.5));}
#endif
   col*=1.+(1.-vis)*(.3*hi+.5*bd*(.3+.5*on));}
  col=mix(col,Gd*.5,scBox(min(.5-abs(q.x),.68-abs(q.y)),.0,.0035,gPx));
  vec4 o=vec4(0.);
  float L0=SB(gLay==0),L1=SB(gLay==1),L2=SB(gLay==2),L3=SB(gLay==3),ax=abs(q.x),ay=abs(q.y);
  vec4 IR=vec4(-.33,.008,-.05,.38)*L0+vec4(-.33,.152,-.185,.38)*L1+vec4(-.118,-.088,.118,.148)*L2+vec4(-.142,-.18,.142,.104)*L3;
  IR=mix(IR,vec4(-.33,-.5,.33,.38)*(L0+L1)+vec4(-.33,-.3,.33,.36)*L2+vec4(-.33,-.368,.33,.292)*L3,gGrow*SB(gSc>3.));   // an impact grows the initial over the page
  float X0=-.33,X1=.33,Y0=.38;
  vec2 BB=vec2(.392,.603);float bw=.034;
  jK=0;jJn=0;jL=0;jG=vec2(0.);jLq=vec2(0.);jId=0u;jGw=1.;jProg=0.;jPu=1.;jLt=0.;jOldA=0.;jWet=0.;jGold=0.;jBar=0.;jDim=1.;jCw=1.;jPen=0.;jLine=0.;jInk=vec3(0.);jInk0=vec3(0.);jFx=vec4(0.);
  float gq=0.,vq=0.,vOver=0.,gRow=0.,gStr=1.,gWd=1.,gGlv=0.,vu=0.,vv=0.,vbw=.03,vgr=0.,vK=1.;vec2 gLq=vec2(0.);int gLl=0;vec3 gInkC=vec3(0.);uint gSalt=0u;
  // which region of the page this is (masks, in order of priority)
  float fB=max(SB(abs(ax-BB.x)<bw)*SB(ay<BB.y+bw),SB(abs(ay-BB.y)<bw)*SB(ax<BB.x+bw)),rest=1.-fB;
  float fI=rest*SB(q.x>=IR.x-.005)*SB(q.x<=IR.z+.005)*SB(q.y>=IR.y-.005)*SB(q.y<=IR.w+.005)*max(L0+L1,SB(length(q-(IR.xy+IR.zw)*.5)<(IR.z-IR.x)*.5+.004));rest*=1.-fI;
  float fH=rest*SB(q.y>.39)*SB(q.y<.562)*SB(ax<.335);rest*=1.-fH;
  float fT=rest*SB(ax<.335)*SB(q.y<=Y0)*SB(q.y>-.57);rest*=1.-fT;
  float fM=rest*SB(ax>.432)*SB(ax<.494)*SB(ay<.56);rest*=1.-fM;
  float fV=rest*SB(ay>.644)*SB(ay<.674)*SB(ax<.42)*max(SB(q.y>0.),SB(ax>.18));rest*=1.-fV;
  float fC=rest*SB(q.y<-.62)*SB(q.y>-.665)*SB(ax<.16);
  if(fB>.5)o=scBorder(q,BB,bw);
  {float sd=SB(abs(ax-BB.x)<bw)*SB(ay<BB.y+bw),tp=SB(abs(ay-BB.y)<bw)*SB(ax<BB.x+bw);
   if(fB*SB(gBor==2)*(1.-sd*tp)>.5){vq=1.;vOver=1.;vu=mix(q.x,q.y,sd)+gSn*bw*2.4;vv=mix(ay-BB.y,ax-BB.x,sd);vbw=bw;vgr=1e3;}}
  if(fI>.5)scIniA(q,IR,L2+L3);
  // headline: the big hand, in a cartouche
  {vec2 hb=abs(q-vec2(0.,.476))-vec2(.334,.083);float hsd=max(hb.x,hb.y);
   col=mix(col,mix(kP,kS,SB(gSty==2))*.62*(.8+.35*mo),step(hsd,0.)*fH);
   col=mix(col,Gd*.85,max(scBox(hsd,-.0035,0.,gPx),scBox(hsd,-.0085,-.0068,gPx))*fH);
   float cwh=.66/7.,xh=.05,pu=gPx/xh,fk=clamp(floor((q.x+.33)/cwh),0.,6.);
   float st=fk*3.,ahead=st-gHd,nw=SB(ahead<0.);
   uint ps=scHH(scPs(gHp-1.+nw),909u);
   float oldA=max(nw,smoothstep(.5,4.,ahead)),prog=mix(1.,clamp((gHd-st)/3.,0.,1.),nw),wet=nw*exp(-max(gHd-st,0.)/9.),gw=1.45,odd=mod(fk,2.);
   vec2 g=vec2((q.x+.33-fk*cwh)/xh-(cwh/xh-gw)*.5,(q.y-.418)/xh);
   if(fH*step(1e-5,oldA)>.5){
     jK=3;jG=g;jId=scId(scCode(ps,0,int(fk)));jGw=gw;jProg=prog;jJn=0;jPu=pu;jLt=smoothstep(1.2,2.5,xh/gPx);jOldA=oldA;jWet=wet;jGold=odd;
     jInk=mix(rub,Gd,odd);jBar=.4*scBox(g.y,0.,1.,pu)*scBox(g.x,.2,gw-.2,pu)*prog;jDim=mix(.82,1.,nw);jPen=nw;gPress=1.+.25*wet;}}
  // the text: which line slot is here, in line-local coordinates (lx along, ly from the top of the line's band)
  float fl=-1.,lx=0.,ly=0.,W=1.,carp=0.;
  {// rota: rings round the medallion, three lines below, gloss in the spandrels
   vec2 d=q-vec2(0.,.03);float rho=length(d),rg=SB(rho>.128)*SB(rho<.356),lw=(1.-rg)*SB(q.y<-.335)*SB(q.y>-.335-3.*SC_LP),sd=(1.-rg)*(1.-lw)*SB(rho>=.362)*SB(q.y>-.33);
   float ri=floor(max(rho-.128,0.)/SC_LP),yt=.128+(ri+1.)*SC_LP,rb=yt-SC_GB-1.7*SC_XH,th=atan(d.y,d.x),hh=SB(d.y<0.);
   float rl=floor(max(-.335-q.y,0.)/SC_LP);
   float lx2=mix((q.x+.33)*lw,mix(PI-th,-th,hh)*rb,rg),ly2=mix((q.y+.335+rl*SC_LP)*lw,rho-yt,rg),W2=mix(.66,PI*rb,rg),fl2=mix(mix(-1.,6.+rl,lw),ri*2.+hh,rg);
   float ml=floor((Y0-q.y)/.021);
   if(fT*L2*sd>.5){gq=1.;gLq=vec2(q.x+.33,q.y-(Y0-ml*.021));gLl=int(ml)+60;gRow=ml;gStr=80.;gWd=.66;gInkC=kS;gSalt=3u;gGlv=gGl*.6;}
   // carpet page: two lines above the carpet, three below
   float r=floor((Y0-q.y)/SC_LP),yr=Y0-r*SC_LP,tx=max(SB(r<2.),SB(r>=9.));
   carp=fT*L3*(1.-tx);
   float fl3=mix(-1.,mix(r-7.,r,SB(r<2.)),tx);
   // one column (the first five lines beside the initial) or two
   float c2=L1*SB(q.x>0.),xs=mix(mix(X0,-.03,SB(r<5.)),mix(mix(X0,-.17,SB(r<3.)),.015,c2),L1),xe=mix(X1,mix(-.015,X1,c2),L1);
   float fl0=mix(-1.,r+12.*c2,SB(r<12.));
   fl=fl2*L2+fl3*L3+fl0*(L0+L1);lx=lx2*L2+(q.x+.33)*L3+(q.x-xs)*(L0+L1);ly=ly2*L2+(q.y-yr)*(L3+L0+L1);W=W2*L2+.66*L3+(xe-xs)*(L0+L1);}
  if(carp>.5)o=scCarpet(q,vec4(-.33,Y0-9.*SC_LP+.006,.33,Y0-2.*SC_LP-.006));
  float inL=fT*SB(fl>=0.)*SB(lx>=0.)*SB(lx<W),ybl=-SC_GB-1.7*SC_XH,isG=inL*SB(ly>-SC_GB);
  int l=int(max(fl,0.)),C=max(1,int(W/SC_CW));
  {// the dry-point ruling; the line lies on a band of pigment between gold rules; a snare steps the bands one line down; the line being written is lit
   col=mix(col,rub*.5,scBox(ly,ybl-.0006,ybl+.0006,gPx)*.22*inL);
   float bs=max(uB1.x,uB1.y),by=ly-ybl,b0=(-.34-.16*bs)*SC_XH,b1=(1.3+.3*bs)*SC_XH,bx=scBox(by,b0,b1,gPx)*inL,sf=smoothstep(.1,.9,fract(gSn));int sp=int(floor(gSn));
   float cur=SB(l==int(gL)),md=max(uB1.z,uB1.w),hl=cur*min(.35+.6*md+.3*max(uO1.z,uO1.w),1.),sty=SB(gSty>0);
   int lb=int(mix(float(l),float(l/2),L2*SB(l<6)));
   float pa=SB(((lb+sp)&1)==0),pb=1.-pa,s1=SB(gSty==1),s2=SB(gSty==2),s3=SB(gSty==3);
   vec3 P=kP,alt=(P*.4*s1+kS*.55*s2+Gd*vec3(.92,.8,.5)*s3)*(.66+.34*max(uB2.x,uB2.y)),   // the presence band lights every second band
   cA=mix(alt,P*.68,pa),cB=mix(alt,P*.68,pb);
   float kA=mix(mix(float(gSty),1.,s1),1.,pa),kB=mix(mix(float(gSty),1.,s1),1.,pb);
   gBand=int(mix(kB,kA,SB(sf<.5))*sty*inL+.5);
   vec3 bcol=mix(cA,cB,sf)*(.8+.35*mo)*(1.+.45*hl);
#if HD>=1
   {float ts=.0042,tv=smoothstep(2.5,6.,ts/gPx);vec2 tq=vec2(lx,by)/ts;tq.x+=.5*floor(tq.y);vec2 tf=fract(tq)-vec2(.5,0.);   // tooling: a fine scale pattern
    bcol*=1.+tv*(.2*smoothstep(.09,.03,abs(length(tf)-.5))-.1*smoothstep(.2,.1,length(tf-vec2(0.,.25))));}
#endif
   float g3=SB(gBand==3);
   col=mix(col,bcol,bx*sty);
   col=mix(col,mix(Gd*.85,kD*.5,g3),max(scBox(by,b0-.0013,b0,gPx),scBox(by,b1,b1+.0013,gPx))*.9*sty*inL);
   ink=mix(ink,P*.5,g3);rub=mix(rub,kR*.8,g3);
   col=mix(col,G*(1.5+.5*mo),bx*min(hl,1.)*(1.-sty));}
  if(isG>.5){gq=1.;gLq=vec2(lx,ly);gLl=l;gRow=float(l);gStr=90.;gWd=W;gInkC=kS;gSalt=0u;gGlv=gGl;}
  if(inL*(1.-isG)>.5)o=scLine(vec2(lx,ly-ybl),l,W,C,ink,rub);
  // the margins: a vine; gloss over it in the outer one
  {float outer=SB((q.x>0.)==(mod(pid.x,2.)>.5)),ml=floor((.56-q.y)/.021);
   uint mh=scHH(scPs(gGp),uint(max(ml,0.)/5.)+313u);
   float mg=fM*outer*SB(scU(mh)<.3+.5*gTen);
   if(fM>.5){vq=1.;vu=.56-q.y;vv=ax-.463;vbw=.03;vgr=1.13;}
   if(mg>.5){vK=.35;gq=1.;gLq=vec2(q.x-mix(-.494,.434,SB(q.x>0.)),q.y-(.56-ml*.021));gLl=int(ml)+30;gRow=ml;gStr=8.;gWd=.06;gInkC=rub*.9;gSalt=1u;gGlv=gGl*.5;}}
  if(fV>.5){vq=1.;vu=q.x+.42;vv=ay-.659;vbw=.015;vgr=.84;}
  // colophon: gloss in gold; on one leaf in seven a maker's mark, found by zooming in (drawn with the glyph below: one seal call a page)
  float mk=fC*SB((scH(gPg^0x51u)%7u)==0u)*SB(ax<.06);
  if(fC*(1.-mk)>.5){gq=1.;gLq=vec2(q.x+.16,q.y+.62);gLl=40;gRow=0.;gStr=40.;gWd=.32;gInkC=kG*.85;gSalt=2u;gGlv=1e5;}
  // a vine grows down the margin from the initial
  if(L0*SB(q.y<IR.y)*SB(abs(q.x+.344)<.017)>.5){vq=1.;vOver=1.;vK=1.;vu=IR.y-q.y;vv=q.x+.344;vbw=.016;vgr=.15+.45*gIp;}
  vec4 vn=vec4(0.);
  if(vq>.5)vn=scVine(vu,vv,vbw,vgr);
  if(gq>.5)scGloss(gLq,gLl,gRow,gStr,gWd,gInkC,gSalt,gGlv,gGp);
  // the glyph of this pixel, once
  int fm=gFam;uint sal=gAl;float k2=SB(jK==2),k3=SB(jK==3),k4=SB(jK==4),live=SB(jK>0)*step(1e-5,jLt);
  gAl=sal^(0x2545f491u*uint(jK==2));
  if(k4>.5){scFam(int(mix(float(fm),0.,max(SB(fm==2),SB(fm==3)))));gWH=.1;gIni=true;gAl=scHH(sal,gIs-uint(iOld));}
  gWT=mix(mix(gWT,gWT*1.2,k3),.3,k4);
  vec3 tip=vec3(0.);
  vec4 b=scGlyph(jG,jId,jGw,jProg*live,jJn,tip);
  vec4 pn=scPen(jG,tip,jInk,jPu)*jPen*live;
  gIni=false;gAl=sal;scFam(fm);
  if(k4>.5)o=scIniB(b,pn);
  {float cv=mix(jBar,scAA(b.x,b.z,jPu),jLt);vec3 c=mix(jInk*.9,scShade(jInk,b.y,jGold,jWet),jLt)*jDim;
   c=mix(c,kG*(.85+.3*max(b.y,0.)),jWet*jWet*(.3+.5*exp(-uP3.w*2.5))*SB(jK!=4));   // fresh strokes bloom in gold, more on the kick
   vec4 r=vec4(c*cv*jOldA,cv*jOldA);
   // the seal: for a moment a span of a finished line resolves into two words in the same pen, then sinks back
   float sv=uM2[2][0];int si=int(floor(max(sv,1.)))-1;float t=fract(sv)*3.;
   vec2 sp=mix(vec2(jLq.x-float(si-64*(si/64))*jCw,jLq.y+.0004)/.0027,(q-vec2(-.033,-.6505))/.0011,mk),cp=floor(sp),f2=sp-cp-.5;
   float seal=scSeal(cp);
   float sok=jLine*SB(gCen)*step(1.,sv)*SB(si/64==jL)*step(-1.,sp.x)*step(sp.x,61.)*step(-1.,sp.y)*step(sp.y,8.)*(1.-mk);
   float al=(1.-smoothstep(1.9,2.5,t))*sok,rv=t/.5*66.;
   r*=1.-al*step(sp.x,rv);o*=1.-al*step(sp.x,rv);
   float dd=length(vec2(max(abs(dot(f2,gNib))-.2,0.),dot(f2,vec2(-gNib.y,gNib.x))));
   float cv2=scAC(dd,.36,gPx/.0027)*seal*step(cp.x,rv-6.)*al;r=scOver(r,vec4(jInk0*1.6*cv2,cv2));
   // the colophon mark in gold points, on half of those leaves with a small mushroom
   vec2 mm=sp-vec2(65.5,0.);
   float mu=SB((gPg&8u)!=0u)*(step(length(mm-vec2(0.,3.4)),3.)*step(2.6,mm.y)+step(abs(mm.x),.9)*step(0.,mm.y)*step(mm.y,3.));
   float cvm=max(seal*scAC(length(f2),.38,gPx/.0011),mu*smoothstep(0.,1.,.0011/gPx))*mk;
   o=scOver(o,vec4(kG*.95*cvm,cvm));
   float kt=SB(jK>0)*(1.-k4);
   o=scOver(scOver(o,scOver(r,pn)*max(kt,sok)),jFx*kt);}
  o=mix(scOver(vn*vK,o),scOver(o,vn),vOver);
#if SC_SERP
  {vec2 ab=abs(q)-BB;if(SB(gSc>3.)*SB(abs(max(ab.x,ab.y))<bw*2.6)>.5)o=scOver(o,scBeast(q,BB,bw));}
#endif
  // impact: gold floods along every stroke in a wave from the central initial outward, then sinks back (ink only, by scaling)
  {float ia=uP4.x,dv=length(gW-gOrg),Rr=ia*(4.+5./max(uZoom,.15));
   float fl2=(exp(-pow((dv-Rr)/(.06+.04*Rr),2.))+smoothstep(Rr,Rr-.3,dv)*exp(-ia*.9))*uP4.y;
   float lum=max(o.r,max(o.g,o.b));o.rgb=mix(o.rgb,Gd*lum*1.3/max(Gd.r,.01),clamp(fl2,0.,1.));}
  // a kick stamps the headline: a ring of ink opens round the big pen
  {float ka=min(uP3.w,1.4);vec2 kc=vec2(-.33+(floor(gHd/3.)+.5)*.66/7.,.445);float Rr=.012+.13*pow(ka,.6),fa=1.-ka/1.4;
   float kv=scAC(abs(length(q-kc)-Rr),.0009+.0022*fa,gPx)*fa;o=scOver(vec4(rub*kv,kv),o);}
  // vertical bounding rules of the text block
  float vr=max(scBox(ax,.343,.3445,gPx),scBox(ax,.3465,.348,gPx))*step(abs(q.y+.07),.46)*(L0*SB(q.x>=0.)+L1);
  col=mix(col,Gd*.45,vr*.6);
  return (col*(1.-o.a)+o.rgb)*(1.+.25*(1.-smoothstep(1.,3.5,SC_XH/gPx)));
}
void scSetup(vec2 pid,uint ph,bool cen,float form,float alpha,bool frozenB){
  uint fm=uint(form);
  gCen=cen;float fc=SB(cen);
  int fam=int(fm&7u),lay=int((fm>>3)&7u),pal=int((fm>>6)&15u),bor=int((fm>>10)&3u);
  uint dl=((fm>>14)&511u)*0x9e3779b1u,al=uint(alpha);
  gAl=al;
  uint pgC=scH(al^0x9e37u^dl),pgW=scHH(al^dl,ph);
  if(cen)gPg=pgC;
  if(!cen){gPg=pgW;
    uint r=scH(ph^al^dl);float left=SB(mod(pid.x,2.)<.5),big=SB(gBig);
    fam=int(mix(float(fam),float((r>>8)%5u),SB(scU(r)<.5)));
    pal=int(mix(float(pal),float((r>>12)%10u),SB(scU(r^1u)<.6)));
    float layW=mix(float((r>>16)&3u),float(2u+((r>>20)&1u)),left*SB(scU(r^5u)<.4));
    float layB=mix(2.*float((r>>22)&1u),float(3u-((r>>21)&1u)),left);
    lay=int(mix(layW,layB,big));bor=int((r>>18)%3u);
    gAl=scHH(al,uint(fam)*7u+(ph&255u)*uint(scU(r^2u)>=.5));}
  scFam(fam);gLay=lay;gPal=pal;gBor=bor;gIni=false;gBand=0;
  {int b=pal*7;kV=SCQ[b];kD=SCQ[b+1];kI=SCQ[b+2]*gInkK;kR=SCQ[b+3];kP=SCQ[b+4];kS=SCQ[b+5];kG=SCQ[b+6]*gGoldK;}
  // the leaf's line bands: 1 one pigment, 2 two pigments, 3 pigment and gold (every leaf has bands: a plain leaf read dull)
  {uint sh=scH(gPg^0x77u)%20u;int st=1+int(sh>=7u)+int(sh>=14u);gSty=int(mix(float(st),float(1u+scH(gPg^0x99u)%3u),fc*SB(st==0)));}
  gMain=1.;
  if(cen){gL=uP1.x;gC=uP1.y;gP=floor(uP1.z);gF=uP1.w;
    if(frozenB){float v=uM2[2][2];gL=floor(v/64.);gC=v-64.*gL;gP-=1.;gF=-1.;}
    gHd=uP2.x;gHp=floor(uP2.y);gGl=uP2.z;gGp=floor(uP2.w);gIp=uP3.y;gIs=uint(uM2[2][1])&63u;}
  if(!cen){
    float L0=SB(gLay==0),L1=SB(gLay==1),L2=SB(gLay==2),L3=SB(gLay==3),cap=(12.*L0+24.*L1+9.*L2+5.*L3)*20.;
    float tc=uP3.x*(.8+.4*scU(ph^3u))+scU(ph^4u)*cap*4.;
    gP=floor(tc/cap);float rem=tc-gP*cap;gL=floor(rem/20.);gC=rem-gL*20.;gF=-1.;
    float fl=gL;
    int C=int(L0*(19.-9.*SB(fl<5.))+L1*(9.-5.*SB(fl<3.))+L2*mix(19.,13.+7.*floor(fl*.5),SB(fl<6.))+L3*19.);
    float len=float(scLen(int(gL),C,gP)),past=SB(gC>=len);
    gF=mix(-1.,clamp((gC-len)/max(20.-len,1.),0.,1.),past);gC=mix(gC,len,past);
    float hd=uP2.x+scU(ph^5u)*21.*3.;gHp=floor(hd/21.);gHd=hd-gHp*21.;
    float gl=uP2.z*(.7+.6*scU(ph^6u))+scU(ph^7u)*8000.;gGp=floor(gl/1100.);gGl=gl-gGp*1100.;
    gIp=1.;gIs=(ph>>9)^uint(alpha);
  }
}
// one leaf: page id, page-local q, which form (0 by the library's rearrangement wave, 1 the new form A, 2 the old form B), the wave's edge
vec3 scLeaf(vec2 q,vec2 pid,uint ph,bool cen,int fm){
  float tr=uP5.x,dv=length(gW)-SC_R0+.6*vnoise(gW*.5),act=SB(tr>0.)*SB(fm==0);
  float uB=mix(act*SB(dv>tr),SB(fm==2),SB(fm>0));
  float edge=act*(1.-smoothstep(0.,.05+1.5*gPx*gSc,abs(dv-tr)));
  scSetup(pid,ph,cen,mix(uM2[0][0],uM2[0][1],uB),mix(uM2[0][2],uM2[1][0],uB),uB>.5);
  vec3 col=scPage(q,pid);
  return mix(col,kG*1.1,edge*.7);
}
vec3 scLeather(vec2 w,int pal){
  // the floor: book leather blind- and gold-tooled with an interlaced lattice
  vec3 D=SCQ[pal*7+1],Gd=SCQ[pal*7+6];
  vec2 t=w*9.;float l1=abs(fract(t.x+t.y)-.5),l2=abs(fract(t.x-t.y)-.5);
  float vis=smoothstep(1.5,4.,.11/gPx);
  float tl=smoothstep(.06+gPx*9.,.06,min(l1,l2))*vis,t2=smoothstep(.03+gPx*9.,.03,abs(min(l1,l2)-.14))*vis;
  vec2 cq=vec2(fract(t.x+t.y)-.5,fract(t.x-t.y)-.5);float ro=scAC(abs(length(cq)-.22),.035,gPx*9.)*vis;
  // the leather warms with the bass; the gilt tooling catches the presence band; a glint runs over it, a step a hat
  float gl=fract((w.x*.8+w.y*.6)*.08-gHw*.125);gl=exp(-(gl-.5)*(gl-.5)*26.)*(.35+.65*min(1.5*max(uB2.z,uB2.w),1.));
  vec3 c=D*(1.08+.48*max(uB1.x,uB1.y)+.4*vnoise(w*7.));
  c=mix(c,D*.6,t2);c=mix(c,Gd*(.66+.42*max(uB2.x,uB2.y))*(1.+.7*gl),max(tl,ro)*.9);
  return c;
}
// the leaf the page code draws for this pixel (set by scLib, or by the turning leaf)
vec2 lQ,lId;uint lH;bool lCen;float lMul,lPx,lOn,gDist,gFrB;int lFm;
// the library floor round the great book (and the great book's own top, gb = 1): open books in rings, in a grid or along a spiral (the dance mode
// of the form on this side of the rearrangement wave), every one dancing on the kick
vec3 scLib(vec2 w,float gb){
  gW=w;
  int pal0=int(uint(uM2[0][0])>>6&15u);
  float tr=uP5.x,rr=length(w),dv=rr-SC_R0+.6*vnoise(w*.5),uB=SB(tr>0.)*SB(dv>tr),ka=uP3.w;
  gMode=int((uint(mix(uM2[0][0],uM2[0][1],uB))>>12)&3u);
  float M0=SB(gMode==0),M1=SB(gMode==1),M2=SB(gMode==2),isR=1.-M1;
  // the grid, great books in the place of four
  vec2 bp=vec2(2.24,1.58)*SC_LB,Bi=floor((w-bp*.5)/(2.*bp)+.5),ci=floor(w/bp+.5);
  uint Bh=scHH(uint(int(Bi.x)+4057),uint(int(Bi.y)+4057));
  float big=SB((Bh%100u)<34u)*M1;
  vec2 gcen=mix(ci*bp,Bi*2.*bp+bp*.5,big),gcell=mix(ci,Bi*2.+.5,big);
  uint ghS=scHH(uint(int(ci.x)+2048),uint(int(ci.y)+2048)),gh=ghS^((ghS^Bh)*uint(big>.5));
  float gok=1.-SB(abs(gcen.x)<SC_GS*1.085+(1.1+big*1.1)*SC_LB)*SB(abs(gcen.y)<SC_GS*.715+(.8+big*.8)*SC_LB);
  // rings round the great book (alternate rings turn the other way, a step a kick), or one spiral arm flowing out from under it
  float th=atan(w.y,w.x)+PI,sr=(rr-mix(SC_R0,2.,M2))/SC_RW,k=floor(sr-M2*th/TAU),phi=th+TAU*k;
  float rcR=SC_R0+(k+.5)*SC_RW,rcS=2.+SC_RW*(phi/TAU+.5),nk=max(floor(TAU*rcR/SC_BW),1.);
  float dir=mix(1.,-1.,mod(k,2.))*mix(1.,.5,SB(k>2.));
  float a=mix(th/TAU*nk+gRot*dir,((2.+.5*SC_RW)*phi+SC_RW*phi*phi/(2.*TAU))/SC_BW-gRot*.5,M2),cl=floor(a+.5);
  vec2 rsw=vec2((a-cl)*mix(TAU*rcR/nk,SC_BW,M2),rr-mix(rcR,rcS,M2));
  float rid=mix(mod(cl,nk),cl,M2);
  uint rh=scHH(uint(int(rid)+9000),uint(int(k*(1.-M2))+77));
  vec2 cellv=mix(gcell,vec2(rid,k),isR),bid=mix(mix(ci,Bi*2.+vec2(900.,0.),big),vec2(rid+2000.*M2,k+300.),isR);
  uint bh=gh^((gh^rh)*uint(isR>.5));
  float okB=mix(gok,SB(k>=0.),isR)*(1.-gb);
  big*=1.-gb;
  gBig=big>.5||gb>.5;
  // the dance: books rock (rings), hop (grid), or a swell runs out from the great book (spiral)
  float par=mix(-1.,1.,SB(mod(cellv.x+cellv.y,2.)<.5)),amp=.6+.8*scU(bh^21u),dn=par*amp*cos(PI*gRk*mix(1.,.5,big));
  float ang=(scU(bh)-.5)*.07,zs=mix(.95+.08*scU(bh^9u),2.,big),e=ka*7.-(rr-SC_R0)*.3;
  vec2 sw=mix(w-gcen,rsw,isR);
  {float sa=uP4.w,se=rr-SC_R0+3.-sa*38.;sw.y-=.2*exp(-se*se*.08)*exp(-sa*2.);}   // a snare sends a shock ring out through the library: each book hops as it passes
  ang+=.09*dn*M0;sw.y-=.1*SC_LB*dn*(1.+.9*big)*M1;zs/=1.+.12*amp*exp(-e*e*.6)*exp(-ka*.7)*M2;
  zs*=SC_LB;
  vec2 s=mix(rot(ang)*sw/zs,w/SC_GS,gb);
  float sc=mix(zs,SC_GS,gb);
  bid=mix(bid,vec2(7000.,0.),gb);
  vec2 cd=abs(s)-vec2(1.085,.715);float csd=mix(1.,max(cd.x,cd.y),max(okB,gb));
  lCen=false;lOn=0.;lMul=1.;lPx=gPx/sc;lQ=vec2(0.);lId=vec2(0.);lH=0u;lFm=0;gSc=sc;
  vec3 col=vec3(0.);
  if(csd<0.){
    float side=SB(s.x>=0.);vec2 q=s-vec2(mix(-.535,.535,side),0.);
    vec2 pq=abs(q)-vec2(.5,.68);float psd=max(pq.x,pq.y),px=gPx/sc;
    int pl=int(mix(float(scH(bh^77u)%10u),float(pal0),gb));
    vec3 L=SCQ[pl*7+1],Gb=SCQ[pl*7+6];
    // a leaf; the gutter: the leaves curve down into the spine
    lQ=q;lId=vec2(bid.x*2.+side,bid.y);lH=scHH(uint(int(lId.x)+4096),uint(int(lId.y)+4096));lCen=gb*side>.5;
    lFm=int(mix(0.,mix(mix(1.,2.,gTurnR*(1.-side)),mix(1.,2.,gFrX),gFrB),gb));   // fragments: the live opening while tension lifts them, the old one once a drop has thrown them
    lMul=.8+.2*smoothstep(.035,.11,abs(s.x));lOn=SB(psd<0.);
    if(psd>=0.&&abs(s.x)<.035){
      // the spine: the sewing, a cord of silks between gold kettle stitches
      float u=s.y*46.,st=fract(u),kk=floor(u),cs=mod(kk,3.);
      vec3 sc3=mix(mix(SCQ[pl*7+5],Gb,SB(cs<1.5)),SCQ[pl*7+3],SB(cs<.5));
      col=sc3*(.55+.45*sin(st*PI))*(.6+.4*cos(s.x/.035*1.5708));
      col=mix(col,L*.45,smoothstep(.36,.5,abs(st-.5))*smoothstep(1.5,3.,1./(46.*px)));
      col=mix(col,(SCQ[pl*7+3]+Gb+SCQ[pl*7+5])*.3,1.-smoothstep(.6,1.6,1./(46.*px)));
    }
    if(psd>=0.&&abs(s.x)>=.035){
      // the boards and the edges of the page block
      float csd2=max(cd.x,cd.y);
      col=L*(1.25+.45*vnoise(s*9.))*(1.-.3*smoothstep(-.02,0.,csd2));
      col=mix(col,Gb*.85,max(scBox(csd2,-.022,-.017,px),scBox(csd2,-.012,-.010,px)));
      float blk=step(abs(s.x),1.05)*step(abs(s.y),.69);
      col=mix(col,Gb*(.42+.32*max(uB2.x,uB2.y)+.22*step(.5,fract(max(pq.x,pq.y)/.0035))),blk);   // the gilt edges of the page block, leaf by leaf
    }
  }
  if(csd>=0.){
    // between the books: loose leaves at another angle, in their shadow
    float shade=mix(.62,1.,smoothstep(0.,.07*sc,csd*sc));
    vec2 lw=rot(.19)*(w-vec2(.61,.79))/SC_LB;lw.x+=.035*cos(PI*gRk*.5)*mix(-1.,1.,SB(mod(floor(lw.y/1.62+.5),2.)<.5))*SB(gMode<2);
    vec2 lp=vec2(1.2,1.62),li=floor(lw/lp+.5),lq=lw-li*lp;
    uint lh=scHH(uint(int(li.x)+6000),uint(int(li.y)+6000));
    lq=rot((scU(lh)-.5)*.2)*lq;
    vec2 lpq=abs(lq)-vec2(.5,.68);float lsd=max(lpq.x,lpq.y);
    gBig=false;
    lQ=lq;lId=li+vec2(5000.,0.);lH=lh;lMul=.92*shade;lOn=SB(lsd<0.);lPx=gPx/SC_LB;gSc=SC_LB;
    col=scLeather(w,pal0)*mix(.6,1.,smoothstep(0.,.04,lsd))*shade;
  }
  return col;
}
// the turning leaf of the great book: three hinged panels from the spine (.3, .35, .35 of the leaf) going from flat on the right (0) to flat on the
// left (PI); the outer edge leads as it lifts and trails as it lands. Returns (distance, along the leaf, y, -1 front = the old right page / +1 back = the new left page)
vec4 scTurnHit(vec3 ro,vec3 rd,out vec3 nn){
  float e=sin(TAU*gTurn);
  vec3 th=PI*smoothstep(0.,1.,clamp(gTurn+vec3(-.06,.05,.13)*e,0.,1.)),W=vec3(.3,.35,.35)*SC_GS;
  vec4 r=vec4(1e9,0.,0.,0.);nn=vec3(0.,0.,1.);
  vec3 B=vec3(.035*SC_GS,0.,SC_TH*SC_GS),d,n,P;float dn,t,u,ok;
  d=vec3(cos(th.x),0.,sin(th.x));n=vec3(-d.z,0.,d.x);dn=dot(rd,n);dn=mix(dn,1e-6,SB(abs(dn)<1e-6));t=dot(B-ro,n)/dn;P=ro+rd*t;u=dot(P-B,d);
  ok=SB(t>.01)*SB(u>=0.)*SB(u<=W.x)*SB(abs(P.y)<=.68*SC_GS)*SB(t<r.x);r=mix(r,vec4(t,u,P.y,sign(dn)),ok);nn=mix(nn,n,ok);B+=d*W.x;
  d=vec3(cos(th.y),0.,sin(th.y));n=vec3(-d.z,0.,d.x);dn=dot(rd,n);dn=mix(dn,1e-6,SB(abs(dn)<1e-6));t=dot(B-ro,n)/dn;P=ro+rd*t;u=dot(P-B,d);
  ok=SB(t>.01)*SB(u>=0.)*SB(u<=W.y)*SB(abs(P.y)<=.68*SC_GS)*SB(t<r.x);r=mix(r,vec4(t,u+W.x,P.y,sign(dn)),ok);nn=mix(nn,n,ok);B+=d*W.y;
  d=vec3(cos(th.z),0.,sin(th.z));n=vec3(-d.z,0.,d.x);dn=dot(rd,n);dn=mix(dn,1e-6,SB(abs(dn)<1e-6));t=dot(B-ro,n)/dn;P=ro+rd*t;u=dot(P-B,d);
  ok=SB(t>.01)*SB(u>=0.)*SB(u<=W.z)*SB(abs(P.y)<=.68*SC_GS)*SB(t<r.x);r=mix(r,vec4(t,u+W.x+W.y,P.y,sign(dn)),ok);nn=mix(nn,n,ok);
  return mix(vec4(1e9,0.,0.,0.),r,SB(gTurn>0.));
}
// the page flying apart (a real drop): fragments of the old opening, two glyph cells by a line, rise on two planes over the great book, spread out
// from the written leaf, spin and shrink away; under tension they lift a little first. Returns (distance, place on the opening (s units), hit)
vec4 scFrag1(vec3 ro,vec3 rd,float H,float S,float par){
  float t=(SC_TH*SC_GS+H*SC_GS-ro.z)/rd.z;
  vec2 s=(ro.xy+rd.xy*t)/SC_GS,c0=vec2(.3,.05),s0=c0+(s-c0)/S,TS=vec2(.068,.076),ti=floor(s0/TS),tc=(ti+.5)*TS;
  uint th=scHH(uint(int(ti.x)+700),uint(int(ti.y)+700));
  vec2 lc=rot((scU(th)-.5)*gFrA)*(s-(c0+(tc-c0)*S));float sz=.5*gFrZ*(.75+.4*scU(th^5u));
  float ok=SB(t>.01)*SB(abs(lc.x)<TS.x*sz)*SB(abs(lc.y)<TS.y*sz)*SB(abs(tc.x)<1.035)*SB(abs(tc.x)>.035)*SB(abs(tc.y)<.68)*max(SB(par<0.),SB(mod(ti.x+ti.y,2.)==par));
  return vec4(mix(1e9,t,ok),tc+lc,ok);
}
vec4 scFragHit(vec3 ro,vec3 rd){
#if SC_FR2
  vec4 a=scFrag1(ro,rd,gFrH,gFrS,0.),b=scFrag1(ro,rd,gFrH*1.7+.01,1.+(gFrS-1.)*1.5,1.);a=mix(a,b,SB(b.x<a.x));
#else
  vec4 a=scFrag1(ro,rd,gFrH,gFrS,-1.);   // one plane carries every fragment
#endif
  return mix(vec4(1e9,0.,0.,0.),a,SB(gFrH>.002));
}
#if SC_QUILL
// ---------------- the quill of the main hand, as tall as a mast over the great book: its nib stands on the letter being written, it rocks with every
// letter, races along the line on the beat and swoops back at the line's end; it lifts away when the leaf turns or the page flies apart.
// A billboard round its own axis (gQT the nib, gQA the axis, gQL its length). Returns premultiplied colour and coverage; tq = distance along the ray
vec3 gQT,gQA;float gQL;
vec4 scQuill(vec3 ro,vec3 rd,int pal,out float tq){
  vec3 n=normalize(gFw-gQA*dot(gFw,gQA)),b=cross(gQA,n);
  float dn=dot(rd,n);dn=mix(dn,-1e-5,SB(abs(dn)<1e-5));
  tq=dot(gQT-ro,n)/dn;
  vec3 P=ro+rd*tq-gQT,qD=SCQ[pal*7+1],qR=SCQ[pal*7+3],qP=SCQ[pal*7+4],qS=SCQ[pal*7+5],qG=SCQ[pal*7+6];
  float u=dot(P,gQA)/gQL,v=dot(P,b)/gQL,pu=max(tq,.01)/(uRes.y*SC_F*gQL),av=abs(v);
  float vn=clamp((u-.24)/.76,0.,1.),wv=.135*pow(max(sin(PI*pow(vn,.62)),0.),.7)*mix(1.,.7,SB(v<0.));   // the vane, fuller on one side
  float inU=SB(u>0.)*SB(u<1.),inV=SB(u>.24)*inU,aV=scAC(av,wv,pu)*inV,aO=scAC(av,wv+.009,pu)*inV;
  float hs=max(.016*(1.-.55*u)*min(u/.07,1.),1e-4),aS=scAC(av,hs,pu)*inU,aSo=scAC(av,hs+.006,pu)*inU;
  // barbs (fine slanted lines), chevron bands of two pigments, a gilt rim, a peacock eye near the top
  float bb=abs(fract(u*52.-av*40.)-.5)*2.,bv=smoothstep(1.2,3.,1./(52.*pu));
  vec3 c=mix(qS,qP,smoothstep(.42,.58,abs(fract(u*3.4-av*3.+gHw*.5)-.5)*2.))*(.66+.44*mix(.5,bb,bv));
  c=mix(c,qG*.95,scAC(abs(av-wv),.0055,pu));
  vec2 e=vec2((u-.78)/.085,v/.05);float er=length(e),pe=pu/.05;
  c=mix(c,qG,scAC(er,1.,pe));c=mix(c,qR,scAC(er,.78,pe));c=mix(c,qD*.3,scAC(er,.5,pe));c=mix(c,qG,scAC(er,.2,pe));
  vec3 K=qD*.16,col=mix(K,c,aV/max(aO,1e-4));
  col=mix(col,K,aSo*(1.-aS));
  col=mix(col,qG*(.7+.5*(1.-clamp(av/hs,0.,1.)))*mix(1.,.35,scAC(av,.0018,pu)*SB(u<.06)),aS);
  float a=max(aO,aSo)*SB(tq>.01);
  return vec4(col*a,a);
}
#endif
// one ray: the great book's block (its top, its gilt sides), the turning leaf, or the library floor; the page code runs once for whatever is hit
vec3 scView(vec2 p){
  vec3 ro=gCam,rd=normalize(gFw*SC_F+gRt*p.x+gUp*p.y);
  rd.z=min(rd.z,-.03);rd=normalize(rd);
  vec3 Ld=normalize(vec3(-.5,.42,.76));
  int pal0=int(uint(uM2[0][0])>>6&15u);
  vec3 bx=vec3(1.085*SC_GS,.715*SC_GS,SC_TH*SC_GS),rq=mix(rd,vec3(1e-6),vec3(lessThan(abs(rd),vec3(1e-6)))),ta=(vec3(-bx.xy,0.)-ro)/rq,tb=(bx-ro)/rq,tn=min(ta,tb),tf=max(ta,tb);
  float tN=max(max(tn.x,tn.y),tn.z),tF=min(min(tf.x,tf.y),tf.z),onB=SB(tN<tF)*SB(tF>0.),topF=SB(tn.z>=max(tn.x,tn.y));
  // the top: once more onto the curve of the leaves down into the gutter
  vec3 P1=ro+rd*tN;float zt=bx.z-SC_DIP*SC_GS*exp(-abs(P1.x)/SC_GS*9.),tTop=mix(tN,max((zt-ro.z)/rd.z,tN),topF),tFl=-ro.z/rd.z;
  // the library floor rises as a bowl round the great book (an amphitheatre of books): flat inside SC_R1, a cone outside it
  float onC;
  {vec2 o=ro.xy,d=rd.xy;float s2=SC_SL*SC_SL,A=ro.z+SC_SL*SC_R1,qa=rd.z*rd.z-s2*dot(d,d),qb=2.*(A*rd.z-s2*dot(o,d)),qc=A*A-s2*dot(o,o);
   qa=mix(qa,1e-7,SB(abs(qa)<1e-7));float sq=sqrt(max(qb*qb-4.*qa*qc,0.)),t1=(-qb-sq)/(2.*qa),t2=(-qb+sq)/(2.*qa);
   float v1=SB(t1>0.)*SB(A+rd.z*t1>=0.)*SB(length(o+d*t1)>=SC_R1),v2=SB(t2>0.)*SB(A+rd.z*t2>=0.)*SB(length(o+d*t2)>=SC_R1);
   float tc=min(mix(1e9,t1,v1),mix(1e9,t2,v2)),tf0=mix(1e9,tFl,SB(length(o+d*tFl)<SC_R1)*SB(tFl>0.));
   onC=SB(tc<tf0);tFl=min(tc,tf0);}
  vec3 nl;vec4 lh=scTurnHit(ro,rd,nl),fh=scFragHit(ro,rd);
  float tS=mix(tFl,tTop,onB),onL=SB(lh.x<tS+.002)*SB(lh.x<fh.x),onF=SB(fh.x<min(tS,lh.x)),side=onB*(1.-topF)*(1.-onL)*(1.-onF);
  float t=mix(mix(tS,lh.x,onL),fh.x,onF);
  vec3 P=ro+rd*t;
  vec3 ns=-sign(rd)*vec3(SB(tn.x>=max(tn.y,tn.z)),SB(tn.y>tn.x)*SB(tn.y>=tn.z),0.);
  vec3 nf=mix(vec3(0.,0.,1.),normalize(vec3(-SC_SL*P.xy/max(length(P.xy),1e-3),1.)),onC*(1.-onB));
  vec3 nrm=mix(mix(mix(nf,ns,side),nl*(-lh.w),onL),vec3(0.,0.,1.),onF);
  gPx=t/(uRes.y*SC_F)/pow(max(abs(dot(rd,nrm)),.04),.7);
  gFrB=onF;
  vec3 col=scLib(mix(P.xy,fh.yz*SC_GS,onF),max(onB*topF*(1.-onL),onF));
  // the turning leaf: its front is the old right page (form B, the written leaf frozen), its back the new left page (form A)
  {float fr=SB(lh.w<0.),U=lh.y/SC_GS;
   if(onL>.5){lQ=vec2(mix(.5-U,U-.5,fr),lh.z/SC_GS);lId=vec2(14000.+fr,0.);lH=scHH(uint(int(lId.x)+4096),4096u);lCen=fr>.5;lFm=int(1.+fr*gTurnR);
     lOn=1.;lPx=gPx/SC_GS;gSc=SC_GS;gBig=true;gW=lQ*SC_GS;lMul=.6+.5*max(dot(nrm,Ld),0.);}}
  // the sides of the block: gilt and gauffered page edges over the boards
  {vec3 Lc=SCQ[pal0*7+1],Gb=SCQ[pal0*7+6];float zz=P.z/bx.z,al=mix(P.x,P.y,SB(abs(ns.x)>.5));
   float gf=smoothstep(.3,.2,abs(fract(al*.8)-.5)+abs(zz-.6)*1.2)*SB(zz>.24);
   vec3 sc=mix(Lc*1.25,Gb*(.55+.2*step(.5,fract(P.z*60.))),SB(zz>.22));sc=mix(sc,SCQ[pal0*7+3]*.8,gf*.6);
   sc*=.55+.6*max(dot(ns,Ld),0.);
   col=mix(col,sc,side);lOn*=1.-side;}
  // shadows: the turning leaf's (on the book and the floor), the block's on the floor, and its contact darkening
  {
#if SC_LSH
   vec3 n2;vec4 sh=scTurnHit(P+nrm*.03,Ld,n2);
#else
   vec4 sh=vec4(1e9);
#endif
#if SC_FSH
   vec4 fs=scFragHit(P+nrm*.03,Ld);
#else
   vec4 fs=vec4(1e9);
#endif
   float fl=(1.-onB)*(1.-onL)*(1.-onF),shd=(1.-.45*SB(sh.x<1e8)*(1.-onL))*(1.-.4*SB(fs.x<1e8)*(1.-onF)*(1.-onL));
   vec3 Q=P+Ld*(bx.z/Ld.z);vec2 bq=abs(Q.xy)-bx.xy,b0=abs(P.xy)-bx.xy;float bs=max(bq.x,bq.y),bz=max(b0.x,b0.y);
   shd*=1.-fl*(.4*smoothstep(.25,-.25,bs)+.22*exp(-max(bz,0.)*1.2));
#if SC_QUILL
   {vec2 s0=gQT.xy-Ld.xy*((gQT.z-bx.z)/Ld.z),ba=(gQA.xy-Ld.xy*(gQA.z/Ld.z))*gQL,pa=P.xy-s0;   // the quill's shadow on the great book
    float h=clamp(dot(pa,ba)/max(dot(ba,ba),1e-4),0.,1.),wq=gQL*(.016+.105*sin(PI*clamp((h-.24)/.76,0.,1.)));
    shd*=1.-.42*(1.-smoothstep(wq-.03,wq+.14,length(pa-ba*h)))*onB*topF*(1.-onL)*(1.-onF);}
#endif
   float px0=gPx;gPx=lPx;vec3 lc=scLeaf(lQ,lId,lH,lCen,lFm)*lMul;gPx=px0;
   col=mix(col,lc,lOn)*shd*mix(1.,.8+.32*max(dot(nrm,Ld),0.),onC*(1.-onB)*(1.-onL)*(1.-onF));}
#if SC_QUILL
  {float tq;vec4 qc=scQuill(ro,rd,pal0,tq);float qv=SB(tq<t+.02);col=col*(1.-qc.a*qv)+qc.rgb*qv;}
#endif
  // a pool of lamplight on the great book and the rings nearest it; the far library sinks into the leather's own deep tone (never pale)
  {float bs=max(uB1.x,uB1.y),sa=uP4.w,se=length(P.xy)-SC_R0+3.-sa*38.;   // the pool widens with the bass; the snare's shock ring is a ring of light too
   col*=(.6+.4*exp(-dot(P.xy,P.xy)/(900.*(1.+1.5*bs))))*(1.+.3*exp(-se*se*.05)*exp(-sa*2.2));}
  col=mix(col,SCQ[pal0*7+1]*.55,smoothstep(gDist*1.3,gDist*4.5,t)*.5);
  return col;
}
void realm(){
  vec2 p=scr();
  float z=max(uZoom,.05);
  gPx=1./(uRes.y*z);gLt=.55*sin(uP3.z);gPress=1.;gE0=vec2(0.);gE1=vec2(0.);gSc=1.;
  float dk=1.-.3*clamp(uDrop,0.,1.);gGoldK=.74+.26*max(uB1.x,uB1.y)*dk;gInkK=min(.76+(.2*max(uB1.z,uB1.w)+.1*max(uO1.z,uO1.w))*dk,1.);gRk=fract(uP2.w)*8.;gSn=fract(uP2.y)*2.;gHw=fract(uP1.z)*8.;gFp=floor(uP5.z)/512.;gTen=fract(uP5.z);gMode=int((uint(uM2[0][0])>>12)&3u);
  gCC=vec2(0.);gOrg=vec2(0.);gTurn=abs(uP5.y);gTurnR=SB(uP5.y>0.);gRot=scM(uM1,8);
  // impacts: a strong arrival grows the initial over the page; a real drop throws the old opening up in fragments (tension lifts them first)
  {float ia=uP4.x,cls=uP4.y*exp(.35*min(ia,6.)),ex=SB(cls>1.5)*SB(ia<3.),te=clamp(ia/2.6,0.,1.),tE=1.-(1.-te)*(1.-te),tn=smoothstep(.3,1.,gTen);
   gGrow=SB(cls>.7)*SB(cls<1.5)*smoothstep(0.,.8,ia)*smoothstep(7.,4.,ia);gFrX=ex;
   gFrH=mix(.05*tn,.04+1.1*tE,ex)*max(ex,SB(tn>0.));gFrS=mix(1.+.02*tn,1.+1.9*tE,ex);gFrA=mix(.1*tn,6.*tE,ex);gFrZ=mix(.96,1.-te*te,ex);}
  // the camera orbits a point on the great book: distance from the zoom, elevation and azimuth from the scene
  {float az=scM(uM1,6),el=scM(uM1,7);gDist=SC_D0/min(z,.6)*pow(.6/min(z,.6),-.58)*min(.6/z,1.);
   vec3 tg=vec3(uM2[1][1],uM2[1][2],SC_TH*SC_GS);
   gCam=tg+gDist*vec3(sin(az)*cos(el),-cos(az)*cos(el),sin(el));
   gFw=normalize(tg-gCam);gRt=normalize(cross(gFw,vec3(0.,0.,1.)));gUp=cross(gRt,gFw);}
#if SC_QUILL
  // the quill: its nib on the main hand's pen (packed by the scene), leaning to the right of the view, rocking with every letter; it lifts away
  // for a turning leaf and for flying fragments
  {uint pk=uint(uM2[2][1]);vec2 pn=vec2(float((pk>>6)&511u),float((pk>>15)&511u))/511.*vec2(.8,1.04)-vec2(.4,.62);
   float up=max(gTurnR*smoothstep(0.,.14,gTurn)*(1.-smoothstep(.88,1.,gTurn)),smoothstep(.06,.3,gFrH)),rk=uP1.y*TAU;
   gQT=vec3(SC_GS*(.535+pn.x),SC_GS*pn.y,SC_TH*SC_GS+10.*up);gQL=4.6;
   gQA=normalize(vec3(0.,0.,1.)+gRt*(.46+.13*sin(rk))+vec3(normalize(gFw.xy),0.)*(.16+.07*cos(rk)));}
#endif
#if SC_SS>1
  vec3 acc=vec3(0.);
  for(int ss=SC0;ss<SC_SS;ss++){
    float fs=float(ss)+.5,a0=fs*2.399963;vec2 po=vec2(cos(a0),sin(a0))*sqrt(fs/float(SC_SS))*.7/uRes.y;
    acc+=scView(p+po);
  }
  vec3 col=acc/float(SC_SS);
#else
  vec3 col=scView(p);
#endif
  // a drop raises every band at once and the engine adds its own flash: hold the page back a little so the flash does not wash it pale
  {float dr=clamp(uDrop,0.,1.);col=max(col,0.)*(1.-.3*dr*dr);}   // the engine's flash goes as the drop squared: so does this
  col*=min(1.,1./max(max(col.r,col.g),max(col.b,1e-3)));   // cap with the hue kept: colour stays colour
  fragColor=vec4(col,0.);
}
`;
