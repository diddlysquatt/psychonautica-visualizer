// HYPR: Escher "Circle Limit" style {p,q} tilings of the hyperbolic plane, set as jewels in a hyperbolic cathedral.
// Disk views: the screen is a giant macro tiling (eight families) with three nested levels;
// every macro tile holds a round jewel that is the next level down, and every macro vertex a rosette roundel, so
// zooming out reveals rose windows within rose windows. Jewels too small to hold their level become crisp faceted
// gems. The innermost jewels hold the micro tiling. Band and half-plane views map the screen straight into the micro
// tiling. One fold loop walks the macro levels and then the micro tiling (camera = an SU(1,1) Mobius map); the micro
// fold word is replayed through a perfect colouring so neighbours always differ.
// uP1/uP3 tiling A/B: x = p + 16q + 256 motif + 2048 model + 8192 PA + 131072 QA (macro tiling),
//   y = m + 16 x0 + 256 ord(R) + 4096 style, z/w = octal-packed H, R perms
// uP2/uP4 camera SU(1,1) (alpha, beta) for A/B
// uP5 = (wipe radius (screen; <0 none), B.R2, B.R4, snare colour flip + 1024 * deep-ground code)
// uM1 = [light angle, macro angle, B zoom (dive) | mid phase, internal zoom, spin phase | Wythoff point, flipR, kick ring]
// uM2 = [palette classes 0..5 (24-bit integers) | metal accent, A.R2, A.R4]
const R_HYPR = `
vec2 yC(vec2 a,vec2 b){return vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x);}
vec2 yD(vec2 a,vec2 b){return vec2(a.x*b.x+a.y*b.y,a.y*b.x-a.x*b.y)/max(dot(b,b),1e-24);}
vec2 yJ(vec2 a){return vec2(a.x,-a.y);}
vec2 yN(vec2 a){return a/max(length(a),1e-24);}
float yAth(float x){x=min(x,.9999995);return .5*log((1.+x)/(1.-x));}
float yHd(vec2 a,vec2 b){return 2.*yAth(length(yD(a-b,vec2(1,0)-yC(yJ(b),a))));}
// signed hyperbolic distance from z to the geodesic on the circle (c,r) orthogonal to the unit circle (+ outside)
float yGeo(vec2 z,vec2 c,float r){vec2 d=z-c;return (dot(d,d)-r*r)/(r*max(1.-dot(z,z),1e-7));}
float yLn(float d,float w,float px){float lw=max(w,px*.7);return (w/lw)*clamp((lw-abs(d))/px+.5,0.,1.);}
vec3 yQ6,yQ7;
vec3 yPc(float h){h=floor(h+.5);return vec3(floor(h/65536.),mod(floor(h/256.),256.),mod(h,256.))/255.;}
// colour class c (0..7; classes 6, 7 are metallic tints of 0, 1), branch-free select
vec3 yK(float c,float m){c=mod(c,m);vec3 d=vec3(mod(c,6.));
  return mix(yPc(dot(uM2[0],step(abs(d-vec3(0,1,2)),vec3(.5)))+dot(uM2[1],step(abs(d-vec3(3,4,5)),vec3(.5)))),yQ6,.45*step(5.5,c));}
float yTh(float x){float e=exp(2.*clamp(x,-12.,12.));return (e-1.)/(e+1.);}
// onset pulse of band b (0 sub .. 7 air)
float yOn(int b){return dot(uO1,vec4(equal(ivec4(b),ivec4(0,1,2,3))))+dot(uO2,vec4(equal(ivec4(b),ivec4(4,5,6,7))));}
int yOct(int v,int i){return (v>>(3*i))&7;}
int yRk(int x,int k,int R1,int R2,int R4){x+=(yOct(R1,x)-x)*(k&1);x+=(yOct(R2,x)-x)*((k>>1)&1);return x+(yOct(R4,x)-x)*(k>>2);}
// tiling geometry (a = pi/p, cd, cr = centre and radius of edge 0's circle, mm = edge midpoint)
vec4 yGeom(float pp,float qq){float a=PI/pp,cb=cos(PI/qq),sa=sin(a);float den=sqrt(max(cb*cb-sa*sa,1e-6));return vec4(a,cb/den,sa/den,(cb-sa)/den);}
float ySv(vec4 G){float c=G.y*cos(G.x);return c-sqrt(max(c*c-1.,0.));}
vec3 yHue(vec3 c,float h){vec3 k=vec3(.57735);float co=cos(h),si=sin(h);return c*co+cross(k,c)*si+k*dot(k,c)*(1.-co);}

// v19: real stones. A convex polytope cut (table, n crown facets, n pavilion facets) ray traced per pixel: refraction in, total
// internal reflection, out through the crown into a dark studio of lamps. The lamps are the eight frequency bands; the body
// colour is Beer-Lambert absorption along the actual path. q = stone frame (girdle inradius 1), n = fold, rt = phase of the crown,
// tl = tilt of the stone toward the viewer, Dv = unit complex turning the world into this tile's frame.
int yZ;float yHt,yFl,yJl,ySpk;
float yLv(int b){return dot(uB1,vec4(equal(ivec4(b),ivec4(0,1,2,3))))+dot(uB2,vec4(equal(ivec4(b),ivec4(4,5,6,7))));}
vec3 yEnv(vec3 d,vec2 Dv){
  vec2 w=yC(d.xy,yJ(Dv));
  float rg=uM1[0].x*.0795775,a0=atan(w.y,w.x)/TAU+rg,z=d.z;
  // three rings of softboxes; between them the studio is black, so a facet is either dark or on fire
  float tr=z<.0?-1.:(z<.48?0.:(z<.82?1.:2.));
  float a=fract(a0+tr*.0625+1.)*8.,ka=floor(a),f=a-ka-.5;
  int ib=int(ka);
  float wf=smoothstep(.34,.2,abs(f)),wz=tr<.5?smoothstep(.08,.16,z)*smoothstep(.46,.4,z):(tr<1.5?smoothstep(.52,.58,z)*smoothstep(.8,.75,z):1.);
  float lamp=wf*wz*step(-.5,tr);
  float amb=.12+.08*smoothstep(-.3,.5,z);
  float key=smoothstep(.97,.99,dot(normalize(vec3(.42,.3,.86)),vec3(w,z)));
  float g=h21(floor(w*17.+z*7.));
  vec3 c=vec3(amb+key*1.5+(.6+1.15*yLv(ib)+3.4*yOn(ib))*lamp*(tr<1.5?1.:.55));
  c+=vec3(1,.95,.9)*(step(.91,g)*step(.1,z))*(yHt*4.+.6*yFl+.9*uB2.z*uB2.z+.9*uB2.w*uB2.w)*ySpk;
  return c;
}
int ySK;
// black opal: a polished dome; cells of play-of-colour turn with the light and the tile tilt
vec3 yOpal(vec2 q,vec3 tint,float pq,vec2 tl,vec2 Dv){
  float r2=min(dot(q,q),1.);vec3 N=normalize(vec3(q,1.1*sqrt(1.-r2)+.1));
  vec3 Rr=reflect(vec3(tl,-1.),N);
  vec2 cp=q*3.6+tint.rg*17.+tint.b*5.,g=floor(cp),f=cp-g;float bd=1e3,sh=0.,hu=0.;
  for(int j=yZ-1;j<=yZ+1;j++)for(int i=yZ-1;i<=yZ+1;i++){
    vec2 o=vec2(float(i),float(j)),h=vec2(h21(g+o),h21(g+o+37.)),d=o+h-f;float e=dot(d,d);
    if(e<bd){bd=e;sh=h.x;hu=h.y;}
  }
  float ty=sh*6.283+Rr.x*3.+Rr.y*2.,lk=.5+.5*sin(ty+uTime*.25);
  vec3 play=max((.5+.5*cos(TAU*(hu*2.+Rr.xxy*1.1+vec3(0,.33,.67))))*1.5-.5,0.)*smoothstep(.55,.95,lk)*(1.+2.2*yOn(int(sh*7.99))+1.2*yLv(int(sh*7.99)));
  vec3 base_=tint*(.2*tint+.16)*(.6+.8*N.z*N.z)+play*(.45+.75*max(tint,vec3(.25)));
  return base_+yEnv(Rr,Dv)*(.04+.5*pow(1.-N.z,3.))+vec3(1)*smoothstep(.992,.999,dot(Rr,normalize(vec3(.42,.3,.86))))*1.2;
}
#if HD>=5
#define Y_SPC 7
#define Y_SS 4
#define Y_NBH 14
#elif HD>=4
#define Y_SPC 5
#define Y_SS 3
#define Y_NBH 12
#elif HD>=3
#define Y_SPC 3
#define Y_SS 3
#define Y_NBH 10
#elif HD>=2
#define Y_SPC 3
#define Y_SS 2
#define Y_NBH 8
#elif HD>=1
#define Y_SPC 1
#define Y_SS 3
#define Y_NBH 6
#else
#define Y_SPC 1
#define Y_SS 1
#define Y_NBH 4
#endif
vec3 yTrace(vec2 q,float n,float rt,vec3 A,vec3 tint,float pq,vec2 tl,vec2 Dv,float eta){
  const float sb=.5646,cb=.8253,sp=.6517,cp=.7585,TT=.3;
  const float sb2=.32,cb2=.9474,dt2=.255,sp2=.74,cp2=.6726;
  float c1=cos(TAU/n),s1=sin(TAU/n),cs=cos(rt),ss=sin(rt),ch=cos(PI/n),sh=sin(PI/n);
#if HD>=1
  float ce=cos(.5*PI/n),se=sin(.5*PI/n);
#endif
  vec3 v=normalize(vec3(tl,-1.)),o=vec3(q,2.),c=vec3(0);
  float path=0.,F=0.;
#if HD>=1
  vec3 acc=vec3(0);float wt=1.;
#endif
  int NB=yZ+(pq>.16?2:(pq>.06?3:Y_NBH+1));
  bool ex=false;
  for(int b=yZ;b<NB;b++){
    float s=b==yZ?-1.:1.,best=-1e9,dn=v.z,t;vec3 nb=vec3(0,0,1);
    if(dn*s>1e-5){best=-s*(TT-o.z)/dn;}
    vec2 e=vec2(cs,ss);
    for(int k=yZ;k<yZ+int(n);k++){
      vec2 eh=vec2(e.x*ch-e.y*sh,e.y*ch+e.x*sh);
      vec3 nc=vec3(sb*e,cb),np=vec3(sp*eh,-cp),nc2=vec3(sb2*eh,cb2),np2=vec3(sp2*e,-cp2);
      dn=dot(nc,v);if(dn*s>1e-5){t=-s*(sb-dot(nc,o))/dn;if(t>best){best=t;nb=nc;}}
      dn=dot(np,v);if(dn*s>1e-5){t=-s*(sp-dot(np,o))/dn;if(t>best){best=t;nb=np;}}
      dn=dot(nc2,v);if(dn*s>1e-5){t=-s*(dt2-dot(nc2,o))/dn;if(t>best){best=t;nb=nc2;}}
      dn=dot(np2,v);if(dn*s>1e-5){t=-s*(sp2*.97-dot(np2,o))/dn;if(t>best){best=t;nb=np2;}}
#if HD>=1
      // upper girdle facets: pairs that shave the corners between the crown mains
      vec2 g1=vec2(e.x*ce-e.y*se,e.y*ce+e.x*se),g2=vec2(e.x*ce+e.y*se,e.y*ce-e.x*se);
      vec3 ng=vec3(.68*g1,.733);dn=dot(ng,v);if(dn*s>1e-5){t=-s*(.69-dot(ng,o))/dn;if(t>best){best=t;nb=ng;}}
      ng=vec3(.68*g2,.733);dn=dot(ng,v);if(dn*s>1e-5){t=-s*(.69-dot(ng,o))/dn;if(t>best){best=t;nb=ng;}}
#endif
#if HD>=3
      vec3 nl=vec3(.82*g1,-.572);dn=dot(nl,v);if(dn*s>1e-5){t=-s*(.812-dot(nl,o))/dn;if(t>best){best=t;nb=nl;}}
      nl=vec3(.82*g2,-.572);dn=dot(nl,v);if(dn*s>1e-5){t=-s*(.812-dot(nl,o))/dn;if(t>best){best=t;nb=nl;}}
#endif
      e=vec2(e.x*c1-e.y*s1,e.y*c1+e.x*s1);
    }
    t=-s*best;
    if(b==yZ){
      o+=v*t;
      F=.04+.96*pow(1.-clamp(-dot(v,nb),0.,1.),5.);
      c=yEnv(reflect(v,nb),Dv)*F*1.4;
      v=refract(v,nb,1./eta);
    }else{
      t=max(t,0.);o+=v*t;path+=t;
      float cn=dot(v,nb),kk=1.-eta*eta*(1.-cn*cn);
      if(kk<0.)v=reflect(v,nb);
      else{
#if HD>=1
        // the ray splits: part of it leaves through this facet, the rest reflects and shows the next image
        float Fi=.1+.9*pow(1.-cn,5.);vec3 vo=refract(v,-nb,eta);
        acc+=wt*(1.-Fi)*yEnv(vo,Dv)*exp(-A*(.35+path));wt*=max(Fi,.4);v=reflect(v,nb);ex=true;
        if(wt<.07)break;
#else
        v=refract(v,-nb,eta);ex=true;break;
#endif
      }
    }
  }
#if HD>=1
  vec3 e2=(acc+(ex?vec3(0):yEnv(v,Dv)*.6*exp(-A*(.35+path))))*.85,r=c+e2*1.7+tint*tint*.04;
#else
  vec3 tr=exp(-A*(.35+path)),e2=yEnv(v,Dv)*(ex?1.:.6),r=c+e2*tr*1.7+tint*tint*.04;
#endif
#if HD<2
  // a little fake spectral fire off the exit direction (real dispersion from Cinema up)
  r+=(tint+.25)*max(e2.x-.7,0.)*(.5+.5*cos(TAU*(v.x*5.+v.y*3.+vec3(0,.33,.67))))*.8;
#endif
  return r;
}
float ySym;   // 0 when the position is also mirror-folded (vertex brooch): nothing off-centre may be drawn there
// the lamp (frequency band 0..7) that the local direction aa points at: a global property, so it agrees across the sector edges
int yBd(float aa,vec2 Dv){vec2 w=yC(vec2(cos(aa),sin(aa)),yJ(Dv));return int(fract(atan(w.y,w.x)/TAU+uM1[0].x*.0795775+1.0625)*8.);}
float yKx;   // v20: the colour class of the tile whose stone is being drawn (a mixed setting deals a kind of stone to each class)
// ---- v20: three more kinds of stone, and two mixed settings ----
// star sapphire: a polished cabochon whose silk gathers the lamp into a star. The centre of the star rides toward the lamp and with
// the tilt of the tile, and every arm is one frequency band, so the spectrum plays the star arm by arm
vec3 yStarS(vec2 q,float n,vec3 tint,float pq,vec2 tl,vec2 Dv){
  float rq=length(q),r2=min(rq*rq,1.);vec3 N=normalize(vec3(q,1.15*sqrt(1.-r2)+.08));
  vec2 Lq=yC(vec2(cos(uM1[0].x),sin(uM1[0].x)),Dv),c=(.2*Lq+1.2*tl)*ySym,d=q-c;
  // as many rays as the cut has folds (twice that for the small folds): the star then agrees with the symmetry of its tile
  float Nr=n<5.5?2.*n:n,sa=TAU/Nr,ang=atan(d.y,d.x),rr=length(d),ai=floor(ang/sa+.5),af=ang-ai*sa,dd=rr*abs(sin(af));
  int bnd=yBd(ai*sa,Dv);   // each arm takes the band of the lamp it points at
  float arm=.85+1.3*yLv(bnd)+2.6*yOn(bnd)+.8*yFl;
  // the star is drawn, not glowed: needle rays with hard edges that taper to a point (each as long as its band is loud, thicker on
  // the kick), a hair-fine second star between them, a hard core
  float len=.86+.12*min(yLv(bnd),1.),wR=(.026+.034*uKick)*max(1.-rr/len,0.)+.003,ray=clamp((wR-dd)/pq+.5,0.,1.)*step(rr,len);
  float ray2=clamp((.007*max(1.-rr/.62,0.)+.0015-rr*abs(sin(abs(af)-.5*sa)))/pq+.5,0.,1.)*step(rr,.62)*smoothstep(.03,.012,pq);
  float core=clamp((.045+.03*uKick-rr)/pq+.5,0.,1.);
  // the body: a deep, saturated dome. Growth shells as fine dark lines (alternate shells a shade deeper), and the silk as crisp
  // striations lying parallel to the arms, brightest where the star's light crosses them
  float aq0=atan(q.y,q.x),fq0=aq0-floor(aq0/sa+.5)*sa,dq0=rq*abs(sin(fq0)),hx=rq*(1.-.1*cos(aq0*Nr));
  vec3 tb=tint*(.3+.7*tint);
  vec3 body=tb*(.22+.72*N.z*N.z)*(.8+.34*mod(floor(hx*7.),2.))*(1.+.9*uKick+1.9*sqrt(yHt)*mod(floor(hx*7.),2.));   // hats light alternate growth shells
  body*=1.-.5*clamp((.07-abs(fract(hx*7.)-.5))/(pq*7.)+.5,0.,1.)*smoothstep(.05,.02,pq);
  {float F=24.,sl=clamp((.16-abs(fract(dq0*F)-.5))/(pq*F)+.5,0.,1.)*smoothstep(.45,.2,pq*F);
   body*=1.+1.1*sl*(.25+.75*exp(-dd*dd*30.))*(.7+.6*yJl);
#if HD>=2
   // Cinema and up: a second, finer set of striations
   {float F2=61.,s2=clamp((.16-abs(fract(dq0*F2+.3)-.5))/(pq*F2)+.5,0.,1.)*smoothstep(.45,.2,pq*F2);body*=1.+.6*s2*(.3+.7*exp(-dd*dd*30.));}
#endif
  }
  vec3 col=body;
#if HD>=1
  // detail range: real inclusions. Rutile needles, each one drawn as its own hairline at its own depth in the dome (so each shifts
  // by its own parallax as the stone tilts), lying along the arm directions; more of them at each tier. Hats set them glittering
  {float sil=0.,gf=smoothstep(.02,.006,pq);int NT=Y_NBH*Y_SPC*4;
   for(int j=yZ;j<yZ+NT;j++){float fj=float(j-yZ),h1=h11(fj*1.37+tint.r*31.+tint.b*7.),h2=fract(h1*61.7),h3=fract(h1*197.3);
    vec2 qp=q-c*(.1+.35*h3);float ap=atan(qp.y,qp.x),fp=ap-floor(ap/sa+.5)*sa,rp=length(qp);
    float th=h2*.5*sa,o=(floor(h3*3.)-1.)*sa;
    vec2 pl=vec2(rp*cos(fp),rp*abs(sin(fp)))-(.12+.72*sqrt(h1))*vec2(cos(th),sin(th)),dv=vec2(cos(o),sin(o));
    float tt=clamp(dot(pl,dv),-.02-.06*h2,.02+.06*h2);
    sil+=clamp((.002-length(pl-dv*tt))/pq+.5,0.,1.)*(.35+.65*h3)*(1.+2.5*yHt*step(.6,fract(h1*9.3+floor(uTime*4.)*.37)));}
   col+=mix(tint,vec3(1),.55)*sil*gf*(.5+.9*yJl);}
#endif
  vec3 sC=mix(tint,vec3(1),.8);float lw=smoothstep(.07,.03,pq);
  col=mix(col,sC*.75*arm,ray2*.7);
  col=mix(col,sC*arm,ray*lw);
  col=mix(col,vec3(1.25)*(1.+uKick),core);
  // hats: a hard little lozenge of light on the tip of every arm
  {float sz=.11*yHt+.04*yFl;col=mix(col,vec3(1.6),clamp((sz-abs(rr-.93*len)-2.5*dd)/pq+.5,0.,1.)*step(.004,sz));}
  // a crisp specular: the lamp as a hard-edged crescent on the shoulder of the dome
  {float ca=dot(q/max(rq,.01),Lq);
   col=mix(col,vec3(1.35),clamp((.022-abs(rq-.72))/pq+.5,0.,1.)*clamp((ca-.9)/(pq*1.2)+.5,0.,1.)*.92*ySym);}
  vec3 Rr=reflect(vec3(tl,-1.),N);
  col+=yEnv(Rr,Dv)*(.02+.3*pow(1.-N.z,3.));
  // the rim: a dark groove, then a polished girdle band with a hard edge that catches the lamp and flashes on the kick
  {float lam=mix(.5,max(dot(q/max(rq,.01),Lq),0.),ySym),l4=lam*lam;l4*=l4;
   col=mix(col,tb*.05,clamp((rq-.895)/pq+.5,0.,1.));
   col=mix(col,tb*(.3+.8*lam)+vec3(1.,.97,.92)*(l4*l4*.9+1.1*uKick),clamp((rq-.93)/pq+.5,0.,1.));
   // outside the girdle: the setting. A dark plate in the stone's colour, engraved with rays that light with the kick
   float fl=clamp((.14-abs(fract(aq0/TAU*Nr*3.)-.5))/(pq*Nr*3./(TAU*max(rq,.3)))+.5,0.,1.)*smoothstep(.06,.02,pq);
   col=mix(col,(tb.gbr*.3+tb*.12+tb*.6*fl*(.6+1.4*uKick+.6*yJl))*(1.+.9*uKick),clamp((rq-1.)/pq+.5,0.,1.));}
  return col;
}
// cloisonne: an n-fold rosette drawn in gold wire. x = distance to the nearest wire, y = the cell under q (0 boss, 1 inner petal,
// 2 outer petal, 3 ground, 4 border), z = the index of that petal
vec3 yClo(vec2 q,float n,float rt){
  float r=length(q),a=atan(q.y,q.x)+rt,sa=TAU/n;
  float i1=floor(a/sa+.5),f1=a-i1*sa,i2=floor(a/sa),f2=a-(i2+.5)*sa;
  float u1=clamp((r-.43)/.47,0.,1.),d1=(abs(f1)-.47*sa*pow(sin(PI*u1),.7)*(1.-.2*uKick))*r;
  float u2=clamp((r-.14)/.33,0.,1.),d2=(abs(f2)-.46*sa*pow(sin(PI*u2),.6)*(1.-.3*uKick))*r;
  float d0=r-.125,dw=min(min(abs(d1),abs(d2)),min(abs(d0),abs(r-.93)));
  float cell=d0<0.?0.:(r>.93?4.:(d2<0.?1.:(d1<0.?2.:3.)));
  return vec3(dw,cell,cell<1.5?i2:i1);
}
// enamel: translucent glass in the cells over engine-turned metal (the turning catches the lamp), gold wires standing proud,
// a row of granulation round the rim. Outer petals light with one band each, inner petals with the band of the tile, the boss on the kick
vec3 yEnam(vec2 q,float n,float rt,vec3 tint,float pq,vec2 tl,vec2 Dv){
  rt+=(mod(yKx,2.)<.5?.5:-.5)*uHit*TAU/n*.5;
  vec3 cl=yClo(q,n,rt);float r=length(q),a=atan(q.y,q.x)+rt,c=cl.y;
  if(r>1.)c=3.;   // beyond the border the ground goes on to the edge of the tile
  vec2 Lq=yC(vec2(cos(uM1[0].x),sin(uM1[0].x)),Dv);
  vec3 gold=mix(yQ6,vec3(1.,.86,.55),.4);
  int bnd=yBd((cl.z+(c<1.5?.5:0.))*TAU/n-rt,Dv);   // each petal takes the band of the lamp it points at
  // v20b: every cell a deep saturated glass (no pale tips, a gold boss); the border flashes on the kick and glitters with the hats
  vec3 tb=tint*(.3+.7*tint);
  vec3 en=c<.5?gold*1.15:(c<1.5?tb.brg:(c<2.5?tb:(c<3.5?tb.gbr*.26+tb*tb*.1:gold*(.2+1.7*uKick+.9*yHt))));
  float gu=sin(a*n*4.+1.2*sin(r*30.))*sin(r*46.+a*n);
  float gl=1.+.62*gu*smoothstep(.09,.03,pq)*(.5+.5*dot(q/max(r,.05),Lq));
  // each cell is cut deeper toward its root, so the glass runs from a dark pool to a pale tip; the ground is a diaper of gold pips
  float sa0=TAU/n,fa=a-floor(a/sa0+.5)*sa0,tp=c<1.5?clamp((r-.14)/.33,0.,1.):clamp((r-.43)/.47,0.,1.);
  en*=c<2.5&&c>.5?mix(vec3(.34),vec3(1.25),tp*tp):vec3(1.);
  {vec2 dp=vec2(a*n*3./PI,r*24.),df2=fract(dp)-.5;float pip=smoothstep(.2,.12,length(df2))*step(2.5,c)*step(c,3.5)*smoothstep(.05,.02,pq);
   en=mix(en,gold*(.5+.8*yJl+3.*yHt*step(.5,fract(h21(floor(dp))+floor(uTime*4.)*.37))+.8*yFl),pip);}
  float lit=c<.5?.9+1.6*uKick:(c<1.5?1.+.9*yJl+1.2*yOn(bnd)+2.*sqrt(yHt):(c<2.5?.9+1.*yLv(bnd)+2.2*yOn(bnd):(c<3.5?1.+.6*yJl+.9*uKick:1.)));   // hats light the inner petals
  vec3 col=en*gl*lit*(1.+.9*uKick+.75*uHit*step(c,2.5))*(.42+.58*smoothstep(0.,.09,cl.x));
  // snare: alternate outer petals pop to the other glass colour and the ground lights up, both with hard edges (they are cells)
  col=mix(col,mix(tb.gbr*1.4,tb.brg*1.5,step(mod(cl.z,2.),.5))*gl,clamp(uHit*1.7,0.,1.)*step(1.5,c)*step(c,2.5));
  col*=1.+4.5*uHit*step(2.5,c)*step(c,3.5);
  // a midrib down every outer petal, at every tier
  col=mix(col,gold*(.5+.6*yLv(bnd)+1.2*yOn(bnd)),clamp(.5-(abs(fa)*r-.004)/pq,0.,1.)*step(1.5,c)*step(c,2.5)*smoothstep(.45,.6,r)*smoothstep(.88,.8,r)*smoothstep(.04,.015,pq));
  col+=vec3(1.,.97,.9)*exp(-dot(q-.05*Lq,q-.05*Lq)*240.)*1.1*step(c,.5);
#if HD>=1
  // detail range: the wires stand above the glass and throw real shadows on it (the rosette is evaluated again along the direction
  // of the lamp, more taps per tier), every outer petal carries a midrib and veins in finer wire, the turning gains a finer cut
  {float A=a*n*4.+1.2*sin(r*30.),B=r*46.+a*n;vec2 er=q/max(r,.05),et=vec2(-er.y,er.x);
   vec3 Ng=normalize(vec3(-.02*(et*cos(A)*sin(B)*4.*n/max(r,.25)+er*sin(A)*cos(B)*46.)*smoothstep(.09,.03,pq),1.));
   float dif=0.,wsum=0.,spc=0.,rg=uM1[0].x*.0795775;int NT=Y_NBH*Y_SPC;
   for(int k=yZ;k<yZ+8;k++){
     float la=(float(k-yZ)+.5)*.7853982-rg*TAU;vec2 Lk=yC(vec2(cos(la),sin(la)),Dv);
     float Ik=.3+1.15*yLv(k-yZ)+3.4*yOn(k-yZ),sh=0.;
     for(int j=yZ;j<yZ+NT;j++){float t=(float(j-yZ)+.6)/float(NT);sh+=step(yClo(q+Lk*(.004+.05*t),n,rt).x,.012)*(1.-.7*t);}
     sh=min(sh*2.6/float(NT),1.);
     dif+=Ik*(1.-.8*sh);wsum+=Ik;
     spc+=Ik*pow(max(dot(Ng,normalize(vec3(Lk*.75,1.66))),0.),80.)*(1.-sh);}
   col*=.3+.82*dif/wsum;
   col+=mix(en,vec3(1.,.97,.9),.45)*spc*.22*step(.5,c)*step(c,3.5);}
  {float sa=TAU/n,f1=a-floor(a/sa+.5)*sa,vn=min(abs(f1)*r-.0035,abs(fract((r+abs(f1)*r*1.3)*13.)-.5)/13.-.003);
   float vm=clamp(.5-vn/pq,0.,1.)*step(1.5,c)*step(c,2.5)*smoothstep(.02,.008,pq)*smoothstep(.0,.03,cl.x);
   col=mix(col,gold*(.5+.6*yLv(bnd)+1.2*yOn(bnd)),vm*.85);
   col*=1.+.2*sin(a*n*12.+r*90.)*smoothstep(.02,.006,pq)*step(c,3.5);}
#endif
  // granulation round the rim; the hats set grains glittering
  {float nb=n*4.,ba=a/TAU*nb,bf=(fract(ba)-.5)*TAU/nb*r,bdd=length(vec2(bf,r-.967))-.024,gh=h21(vec2(floor(ba),n));
   col=mix(col,gold*(.45+.7*smoothstep(.024,0.,length(vec2(bf,r-.967)-.008*Lq))+(3.*yHt+yFl)*step(.6,fract(gh+floor(uTime*4.)*.37))),clamp(.5-bdd/pq,0.,1.)*step(3.5,c));}
  float ww=.013,wm=clamp((ww-cl.x)/pq+.5,0.,1.)*smoothstep(.07,.03,pq),wc=cl.x/ww;
  return mix(col,gold*(.42+.8*(1.-wc*wc))*(1.+.6*uKick+.9*uHit+.5*yFl+.8*yHt),wm);
}
// agate: a slice through a banded nodule. Each band is one frequency band (the rind is the sub, the heart the air), and the
// hollow at the heart is lined with crystals that glitter with the hats
// the banded body of the agate at q; d = the distance field the bands follow
vec3 yAgC(vec2 q,float n,vec3 tint,float sd,float pq,out float d){
  // qs: the position wound n times round the centre and mirrored, so the banding has the symmetry of the tile and no seams
  float r=length(q),a=atan(q.y,q.x),ca=cos(a*n),c2=cos(2.*a*n);vec2 qs=r*vec2(ca,c2)*.42+vec2(r*.9,0.)+sd;
  float wob=.09*ca*sin(sd*5.)+.04*c2*cos(sd*3.)+.2*(vnoise(qs*2.6)-.5);
#if HD>=1
  // detail range: finer and finer folds in the banding, one octave per two steps of the count of the tier
  {float am=.05,fq=6.;for(int i=yZ;i<yZ+Y_NBH/2;i++){wob+=am*(vnoise(qs*fq+float(i-yZ)*7.)-.5);am*=.55;fq*=2.1;}}
#endif
  d=r+wob*(.35+.65*r);float b=d*17.-uKick,bi=floor(b),bf=b-bi,h=h21(vec2(bi,sd)),h2=fract(h*7.31);
  int bnd=int(clamp(7.-bi*.47,0.,7.));
  vec3 tb=tint*(.3+.7*tint);
  vec3 c0=mix(tb*(.16+.84*h*h),tb.gbr*(.85+.3*h2),step(.8,h));   // v20b: the accent bands are a second saturated hue, not milk
  c0=mix(c0,mix(tb*tb,tb.brg,.25)*.16,step(h,.16));
  float fine=1.+.3*sin(b*TAU*4.)*smoothstep(.03,.01,pq);
#if HD>=2
  fine*=1.+.12*sin(b*TAU*17.+wob*30.)*smoothstep(.006,.002,pq);
#endif
  return c0*(.45+.55*smoothstep(0.,.12,bf)*smoothstep(1.,.85,bf))*fine*(.75+1.1*yLv(bnd)+2.2*yOn(bnd)+.7*uKick+step(.5,h)*(2.2*sqrt(yHt)+.8*yFl))
    +mix(tint,vec3(1),.7)*step(.7,h21(vec2(bi,mod(floor(a/TAU*n*8.),8.))+sd+floor(uTime*5.)))*step(bf,.3)*smoothstep(.04,.015,pq)*(3.2*yHt+yFl);
}
vec3 yAgate(vec2 q,float n,vec3 tint,float pq,vec2 tl,vec2 Dv){
  float sd=tint.r*17.+tint.g*29.+tint.b*5.+yKx*3.7,d;
  vec3 col=yAgC(q,n,tint,sd,pq,d);
#if HD>=1
  // detail range: the slice is translucent. The banding is seen through its depth: layers (bounces x wavelengths of the tier) lie
  // one behind the other, shifted by the tilt and the lamp, and deeper layers are dimmer
  {vec2 off=(yC(vec2(cos(uM1[0].x),sin(uM1[0].x)),Dv)*.5-tl*3.)*.03;int NT=Y_NBH*Y_SPC*3/2;vec3 ac=col*(float(NT)*.55);float aw=float(NT)*.55,d2;
   for(int j=yZ;j<yZ+NT;j++){float t=(float(j-yZ)+1.)/float(NT),w=.7*(1.-.8*t);ac+=yAgC(q+off*t*ySym,n,tint,sd,pq,d2)*w;aw+=w;}
   col=ac/aw;}
#endif
  vec2 cp=vec2(length(q)*15.,atan(q.y,q.x)/TAU*n*2.),g=floor(cp),gf=fract(cp)-.5;float gh=h21(vec2(g.x,mod(g.y,2.))+sd),tw=step(.55,fract(gh*9.7+floor(uTime*3.+gh*5.)*.37));
  vec3 dz=mix(tint*.2,tint*1.2+.12,gh)*(.3+.5*fract(gh*3.3)+tw*(1.6*yHt+.6*yFl+.8*uB2.w))*(.55+.9*smoothstep(.5,.1,max(abs(gf.x)+.6*abs(gf.y),abs(gf.y))));
  col=mix(col,dz,smoothstep(.25,.19,d));
  vec3 Rr=reflect(vec3(tl,-1.),normalize(vec3(-q*.18,1.)));
  return col*(1.+.25*smoothstep(.6,1.,dot(Rr,normalize(vec3(.42,.3,.86)))))+vec3(1)*smoothstep(.985,.999,dot(Rr,normalize(vec3(.42,.3,.86))))*.5;
}
// v20b: a stone too small to draw is a flat fill. It used to run up to three times its colour and clip pale, with nothing between
// neighbours: now it keeps its hue at full value (never beyond) and darkens to its rim, so small stones stay deep with dark leading
vec3 ySmall(vec3 c,vec2 q){float m=max(c.r,max(c.g,c.b));c*=1.2/max(m,1.2);return c*(1.-.82*smoothstep(.5,1.02,length(q)));}
vec3 yStone(vec2 q,float n,float rt,vec3 tint,float pq,vec2 tl,vec2 Dv){
  // stone kinds: 0 faceted (ray traced), 1 black opal, 2 star sapphire, 3 cloisonne enamel, 4 agate, 5 and 6 mixed by colour class
  int sk=ySK;
  if(sk>4){int kc=int(mod(yKx,3.));sk=sk==5?(kc==0?0:(kc==1?3:2)):(kc==0?3:(kc==1?4:1));}
  if(sk==1){
#if HD>=1
    // detail range: the opal has depth. Its play of colour is gathered from layers through the dome (samples x wavelengths x 9
    // of the tier), each with its own parallax and its own place inside the pixel
    vec3 ro=vec3(0);int NT=Y_SS*Y_SPC*9;
    for(int j=yZ;j<yZ+NT;j++){float h=float(j-yZ)+.5,t=h/float(NT);
      ro+=yOpal(q+(pq<.3?pq*vec2(fract(h*.7548)-.5,fract(h*.5698)-.5):vec2(0))+tl*.3*t,tint,pq,tl,Dv)*(1.-.5*t);}
    return ro/(float(NT)*.75);
#else
    return yOpal(q,tint,pq,tl,Dv);
#endif
  }
  if(sk>1){
    vec3 r2=vec3(0);ySpk=0.;
#if HD>=1
    for(int ss=yZ;ss<yZ+Y_SS;ss++){
      float h=float(ss-yZ)+.5;vec2 jq=q+(pq<.3?pq*vec2(fract(h*.7548)-.5,fract(h*.5698)-.5):vec2(0));
      if(sk==2)r2+=yStarS(jq,n,tint,pq,tl,Dv);else if(sk==3)r2+=yEnam(jq,n,rt,tint,pq,tl,Dv);else r2+=yAgate(jq,n,tint,pq,tl,Dv);
    }
    r2/=float(Y_SS);
#else
    if(sk==2)r2=yStarS(q,n,tint,pq,tl,Dv);else if(sk==3)r2=yEnam(q,n,rt,tint,pq,tl,Dv);else r2=yAgate(q,n,tint,pq,tl,Dv);
#endif
    ySpk=1.;r2*=1.3/max(max(r2.r,max(r2.g,r2.b)),1.3);
    return mix(r2,ySmall(tint*(.55+.75*yJl+1.1*uB2.z+.8*uB2.w)+tint*yFl*.6,q),smoothstep(.05,.16,pq));
  }
  vec3 A=-log(clamp(tint,.04,1.))*(.42+.3*smoothstep(.5,0.,dot(tint,vec3(.33)))),r=vec3(0);
#if HD>=2
  vec3 ws=vec3(0);
  for(int ss=yZ;ss<yZ+Y_SS;ss++){
    float h=float(ss-yZ)+.5;vec2 jq=q+(pq<.3?pq*vec2(fract(h*.7548)-.5,fract(h*.5698)-.5):vec2(0));
    for(int i=yZ;i<yZ+Y_SPC;i++){
      float t=(float(i-yZ)+.5)/float(Y_SPC);
      vec3 wl=clamp(1.-abs(vec3(.17,.5,.83)-t)*3.,0.,1.);
      r+=yTrace(jq,n,rt,A,tint,pq,tl,Dv,1.72+.06*t)*wl;ws+=wl;
    }
  }
  r/=max(ws,vec3(.01));
#elif HD>=1
  for(int ss=yZ;ss<yZ+Y_SS;ss++){
    float h=float(ss-yZ)+.5;
    r+=yTrace(q+(pq<.3?pq*vec2(fract(h*.7548)-.5,fract(h*.5698)-.5):vec2(0)),n,rt,A,tint,pq,tl,Dv,1.75);
  }
  r/=float(Y_SS);
#else
  r=yTrace(q,n,rt,A,tint,pq,tl,Dv,1.75);
#endif
  vec3 sm=tint*(.55+.75*yJl+1.1*uB2.z+.8*uB2.w)*(.78+.32*step(0.,sin(atan(q.y,q.x)*n+rt)))+tint*yFl*.6;
  sm+=mix(tint,vec3(1),.55)*(.5+.5*uKick)*exp(-dot(q+.35*vec2(.42,.3),q+.35*vec2(.42,.3))*7.)*.8;
  return mix(r,ySmall(sm,q),smoothstep(.1,.28,pq));
}

float yRimPx,yRimRel,yDim,yCam;vec3 yGlow;
vec3 yRender(vec2 p,float px,vec4 meta,vec4 cam,vec2 rr){
  int i0=int(meta.x+.5),i1=int(meta.y+.5);
  int P=i0&15,Q=(i0>>4)&15,motif=(i0>>8)&7,md=(i0>>11)&3;
  int m=i1&15,x0=(i1>>4)&15,ordR=max((i1>>8)&15,1),style=(i1>>12)&15,mo=(i1>>16)&1,vw=(i1>>17)&3;ySK=(i1>>19)&7;
  int fl=int(uP5.w+.5),dk=fl>>10;
  yQ6=yPc(uM2[2].x);yQ7=vec3(float(dk>>8),float((dk>>4)&15),float(dk&15))*.004;
  float th=uM1[0].y;
  vec4 G=yGeom(float(P),float(Q));
  float inR=2.*yAth(G.w);
  // the cathedral's macro tiling {PA,QA} (eight families)
  vec4 GA=yGeom(float((i0>>13)&15),float((i0>>17)&15));
  float iA=2.*yAth(GA.w),rhoA=yTh(.44*iA),rhoV=mo==1?ySv(GA):rhoA;
  float inRM=iA,rho=rhoV;
  float mir=0.;yDim=0.;yRimRel=9.;yCam=1e5;yJl=.45+.3*uB1.x;
  vec2 z,Dr=vec2(1,0),w;float ph;int lev=0;
  float zf=1./(px*uRes.y);
  if(vw==1){
    // tunnel: the band wrapped round the view axis (conformal log-polar). Four mirrored sectors; the band's two limit lines are
    // the spokes, and following the band is flying down the shaft
    float N=4.,c=N*.5,r0=max(length(p),1e-5);
    w=vec2(-c*log(r0),-c*atan(p.y,p.x));
    float pw=px*c/r0;
    float j=floor(w.y/PI+.5);w.y-=j*PI;
    mir=mod(j,2.);w.y*=1.-2.*mir;
    yRimPx=(abs(w.y)-1.5707963)/pw;
    w.x=clamp(w.x,-40.,40.);
    z=vec2(sinh(w.x),sin(w.y))/(cosh(w.x)+cos(w.y));ph=pw/max(cos(w.y),1e-7);
    Dr=yC(yN(vec2(1,0)-yC(z,z)),-yN(yJ(p)));
  }else if(md==2){
    // band model. Zooming out bends the frieze with a Mobius map (every horizontal line becomes a circle through one
    // point below), so the band becomes a circular frieze inside nested mirrored circular friezes, all touching there
    float kb=.075*smoothstep(1.,.2,zf);
    vec2 zt=p*3.653,g=vec2(1.+kb*zt.y,-kb*zt.x);
    w=yD(zt,g);
    float pw=px*3.653/max(dot(g,g),1e-6);
    float j=floor(w.y/PI+.5);w.y-=j*PI;
    mir=mod(j,2.);w.y*=1.-2.*mir;
    yDim=abs(j);yRimPx=(abs(w.y)-1.5707963)/pw;
    w.x=clamp(w.x,-40.,40.);
    z=vec2(sinh(w.x),sin(w.y))/(cosh(w.x)+cos(w.y));ph=pw/max(cos(w.y),1e-7);
    Dr=yC(yN(vec2(1,0)-yC(z,z)),yN(yJ(yC(g,g))));
  }else if(md==3){
    // half-plane cathedral: the horizon is the bottom of a huge disk (radius Rs on screen); zooming out shrinks the disk
    // until the whole rose window shows. T moves the screen centre to the disk centre for the camera.
    float Rs=.5*pow(max(zf,.05)/.15,2.6),Rp=Rs/zf,yhp=(-.36-.09*clamp((1.-zf)/.85,0.,1.))/zf;
    vec2 u=(p-vec2(0.,yhp+Rp))/Rp,u0=vec2(0.,-1.-yhp/Rp);
    float uu=dot(u,u);
    yRimPx=(sqrt(uu)-1.)*Rp/px;
    mir=step(1.,uu);yDim=mir;u/=max(uu,1.);
    vec2 g=vec2(1,0)-yC(yJ(u0),u);
    z=yD(u-u0,g);ph=2.*px/Rp/max(uu,1.)/max(1.-dot(u,u),1e-7);
    Dr=yN(yJ(yC(g,g)));
  }else{
    // jewel cathedral: three macro levels; each macro tile holds a round jewel, the next level down
    float Rt=(md==0?.3:.46)/(rhoV*rhoV*rhoV);
    z=p/Rt;float q2=dot(z,z);
    if(vw==2){
      // the dome: the ray from the floor centre, elevated view, reaches the hemisphere model of the plane; stereographically that
      // is the disk. Below the horizon the same ceiling is seen in the polished floor.
      // v20: pulled back, the dome used to smear into radial streaks toward the horizon; most of a pull-back is now taken out again
      vec2 pd=p*pow(min(zf,1.),.62);pd=pd/(1.+.75*length(pd));
      vec3 rd=normalize(vec3(pd.x,pd.y*.74+.67,.74-pd.y*.67));
      float hor=rd.z;mir=step(hor,0.);yDim=mir*.75;
      z=rd.xy/(1.+abs(hor));
      px=max(length(dFdx(z)),length(dFdy(z)));
      Rt=1.;q2=dot(z,z);
      Dr=yN(dFdx(z));
    }
    if(q2>1.){z/=q2;px/=q2;mir=1.;yDim=.7;q2=1./q2;}
    q2=min(q2,.999);
    ph=2.*px/Rt/(1.-q2);lev=q2>.998?9:3;
    yRimPx=(sqrt(q2)-1.)/(ph*(1.-q2)*.5);
    vec2 cl=vec2(cos(th*.35+2.1),sin(th*.35+2.1));
    z=yC(z,cl);Dr=yC(Dr,cl);
  }
  // one fold loop: macro levels (enter a jewel = next level), then the micro tiling (colour word kept as a stack)
  vec4 FG=lev>0?GA:G;
  // tp: a tracked point - the macro origin while in the cathedral, then the screen centre (camera space) in the tiling
  vec2 tp=vec2(0);
  int n=0,nM=0,n1=0,n2=0,wa=0,wb=0,wc=0;
  int nMax=int(min(30.,20.+6.*uDetail));
  bool cam0=lev==0;float kind=3.;
  // a single exit at the top: kind leaves 3 when a result is found, lev jumps to 9 when the fold gives up
  for(int i=0;i<64;i++){
    if(lev>8||kind!=3.)break;
    if(cam0){
      // entering the micro tiling: apply the camera (an SU(1,1) Mobius map)
      cam0=false;
      if(ph>1.6*inR)kind=4.;
      vec2 dq=yC(yJ(cam.zw),z)+yJ(cam.xy);
      z=yD(yC(cam.xy,z)+cam.zw,dq);Dr=yC(Dr,yN(yJ(yC(dq,dq))));
      tp=yD(cam.zw,yJ(cam.xy));
      FG=G;n=0;wa=0;wb=0;wc=0;
    }else if(lev>0&&(ph>1.3*inRM||nM>14))lev=9;
    else{
      float fk=1.+FG.w*FG.w;
      float k=floor(atan(z.y,z.x)/(2.*FG.x)+.5);
      vec2 e=vec2(cos(2.*FG.x*k),-sin(2.*FG.x*k));
      z=yC(z,e);Dr=yC(Dr,e);tp=yC(tp,e);
      vec2 dz=z-vec2(FG.y,0);
      int km=int(mod(k,float(ordR))+.5);
      if(dot(dz,dz)>=FG.z*FG.z){
        float r=length(z),ez=ph*(1.-r*r)*.5;
        vec2 zb=vec2(z.x,abs(z.y)),vtb=ySv(FG)*vec2(cos(FG.x),sin(FG.x)),ub=yD(zb-vtb,vec2(1,0)-yC(yJ(vtb),zb));
        bool inB=mo==1&&dot(ub,ub)<yTh(.11*iA)*yTh(.11*iA);
        if(lev==0)kind=0.;
        else if(mo==1?inB:r>=rho){kind=2.;yRimPx=(r-rho)/ez;yRimRel=(r-rho)/rho;}
        else{
          // enter the jewel, oriented so that the way home (the macro origin) points down
          if(mo==1){yCam=min(yCam,(yGeo(z,vec2(FG.y,0),FG.z)-.016*iA)/ph);}
          vec2 rt=mix(yC(yJ(yN(tp)),vec2(0,-1)),yJ(e),float(nM==0));
          int l3=int(lev==3);n2=n2*(1-l3)+nM*(l3+2*int(lev==2));n1+=(nM-n1)*int(lev==1);
          z=yC(z,rt)/rho;Dr=yC(Dr,rt);
          // a jewel only a few pixels across stays a crisp faceted gem (kind 5) instead of melting into a glow
          kind=rho<8.*ez?5.:3.;
          ph=2.*ez/rho/max(1.-dot(z,z),1e-6);
          lev--;nM=0;tp=vec2(0);
          float tl=mix(th*float(lev),.9-.6*th,float(lev==2));vec2 cl=vec2(cos(tl),sin(tl));
          z=yC(z,cl);Dr=yC(Dr,cl);
          cam0=lev==0;yRimPx=(length(z)-1.)/(ph*(1.-dot(z,z))*.5);
        }
      }else if(lev==0&&n>=nMax)lev=9;
      else{
        vec2 dn=vec2(fk,0)-2.*FG.w*z;
        Dr=yN(yC(Dr,-yJ(yC(dn,dn))));
        z=yD(vec2(2.*FG.w,0)-fk*z,dn);
        tp=yD(vec2(2.*FG.w,0)-fk*tp,vec2(fk,0)-2.*FG.w*tp);nM++;
        wc=(wc<<3)|((wb>>27)&7);wb=((wb<<3)&0x3fffffff)|((wa>>27)&7);wa=((wa<<3)&0x3fffffff)|km;
        n++;
      }
    }
  }
  vec3 deep=yQ7,acc=mix(yQ6,yQ6.yzx,uB2.z*.15);
  // jewel spectrum: the main jewel plays the sub, each ring of jewels outward plays a higher band
  int bi=min(kind>1.5&&kind<2.5?nM+(lev==1?0:3*(3-lev)):n1+3*n2,7);
  if(md<2)yJl=bi==0?uB1.x:(bi==1?uB1.y:clamp(spec(.08+.12*float(bi))*1.4,0.,1.));
  int jg=md<2?n1+2*n2:0;
  float lod=kind<.5?ph/inR:9.;
  // limit glow: tiles smaller than a few pixels melt into the luminous boundary
  float glowK=smoothstep(.3,1.6,lod),onJ=yOn(bi);
  float fm=float(max(m,1));vec3 jc=yK(float(jg),fm);
  vec3 glowC=mix(jc*(.3+.7*jc)*1.1,acc,.04+.1*uB2.w)*(.55+.6*yJl)*(1.+.5*uKick+.2*min(uDrop,1.));
  yGlow=glowC*(1.+1.5*onJ);
  vec3 col=glowC*(kind>3.5?1.:.35)*(1.-.5*min(yDim,1.));
  // a jewel whose tiling is too fine to draw is a turned disc: concentric cuts, dark between them, wherever they are pixels apart
  if(kind>3.5){float rz=dot(z,z);col*=mix(.75,.38+.62*smoothstep(-.3,.5,cos(rz*40.)),smoothstep(.035,.012,ph*(1.-rz)*.5));}
  float la=uM1[0].x,kick=uKick;
  vec2 Ls=vec2(cos(la),sin(la)*(1.-2.*mir));
  vec3 L=normalize(vec3(yC(Ls,yN(Dr))*.85,.62)),Hv=normalize(L+vec3(0,0,1));
  // the stone is ray traced at one call site below: each branch only says what to draw there
  float gM=0.,gN=8.,gRt=0.,gPq=1.,gG=1.;vec2 gQ=vec2(0),gTl=vec2(0);vec3 gT=vec3(.5),gF=vec3(0);
  vec3 base=vec3(0),alt=vec3(0),cO=vec3(0);
  float mg=0.,es=0.,onb=0.,ring=0.,dC=0.,dE=0.,dV=0.,lp=ph,grout=0.,hat=0.,band=0.,de=0.,fC=0.,fR=1.,b1=0.,df=0.,sp=0.;
  if(kind>1.5&&kind<2.5){
    // macro tracery between the jewels: dark stone glowing in the jewel colour (luminance-balanced), a neon rib along
    // the macro edges (bass, kick, highs), a lit bezel set with pearls (air), and a rosette roundel at every vertex
    vec3 c1=yK(float(jg+nM),fm);c1*=.3/(.1+dot(c1,vec3(.2126,.7152,.0722)));
    float r=length(z),rJ=.88*inRM,dJ=2.*yAth(r)-rJ,dE2=yGeo(z,vec2(FG.y,0),FG.z),bz=.055*inRM,bu=clamp(dJ/bz,0.,1.),pr=4.*bu*(1.-bu);
    float lt=.5+.5*dot(z/max(r,1e-6),vec2(cos(la),sin(la)));
    col=deep*2.+c1*.17*exp(-dJ/(.2*inRM));
    // gold lace in the spandrels between the jewels (rows of beaded arcs round each jewel; denser at the higher tiers)
    float lW=.09*inRM,lR=abs(mod(dJ+.5*lW,lW)-.5*lW);
    float lc=yLn(lR,.009*inRM,ph)*step(0.,dJ);
#if HD>=1
    float spk=abs(fract(atan(z.y,z.x)/(2.*FG.x)*14.+.5)-.5);lc+=yLn(spk*FG.x*.5*min(1.,r/max(rho,.01)),.006*inRM,ph)*smoothstep(.05,.2,dJ/inRM);
#endif
    col+=mix(acc,c1,.45)*lc*(.45+.8*uB2.x+.7*uKick);
    col+=mix(acc,c1,.4)*yLn(dE2,.0045*inRM,ph)*(.25+1.2*uB1.y+1.2*kick+.8*uO2.z);
    col=mix(col,mix(acc,c1,.5)*(.25+.9*pr*(.3+.8*lt))+(.6*lt*lt+1.5*uO2.y)*pr*acc,yLn(dJ-bz*.5,bz*.5,ph));
    // the vertex brooch: a large stone in a halo of small ones, each in its own gold collet, on dark enamel
    float sv=ySv(FG),cq=FG.y*sin(FG.x)/FG.z,sq=sqrt(max(1.-cq*cq,1e-4));
    vec2 vt=sv*vec2(cos(FG.x),sin(FG.x)),zz=vec2(z.x,abs(z.y));
    vec2 u=yC(yD(zz-vt,vec2(1,0)-yC(yJ(vt),zz)),-yJ(vt)/sv);
    float Ru=mo==1?yTh(.11*inRM):yTh(.36*(2.*yAth(sv)-rJ)),uu=length(u),tv=uu/Ru,ku=2.*Ru/max(1.-uu*uu,1e-4);
    float rl=lev==3?uB1.w:(lev==2?uB2.x:uB2.y),ro=yOn(6-lev);
    vec3 cv=mix(jc.gbr,acc,.1);
    float Aw=asin(sq),tht=asin(clamp(abs(u.y)/max(uu,1e-6),0.,sq)),ns=max(floor(Aw*.7/.25+.5),1.),cs=tht/Aw*ns,ci=floor(min(cs,ns-.001));
    float arc=(cs-ci-.5)*Aw/ns*.7,Rs=min(.13,.48*Aw/ns*.7),inC=step(tv,.46);
    vec2 gq=mix(vec2(arc,tv-.7)/Rs,u/(Ru*.42),inC);
    float gd=length(gq),pq=ph*max(1.-uu*uu,.02)*.5/(Ru*mix(Rs,.42,inC));
    vec3 gt=mix(mod(ci,2.)<.5?cv:mix(jc,cv,.25),jc,inC);
    vec3 gold=mix(acc,vec3(1.,.86,.55),.35);
    vec3 rc=mix(deep*1.5+cv*.05,gold*(.22+.35*rl),float(mo));
    float bd=abs(fract(cs*3.)-.5)*Aw/ns/3.*.92;
    rc=mix(rc,gold*(.5+.7*rl),smoothstep(.024,.012,length(vec2(bd,tv-.915))));
    rc=mix(rc,gold*(.35+.8*smoothstep(-.8,.9,dot(gq/max(gd,.01),Ls))),clamp((1.2-gd)/(pq*1.5)+.5,0.,1.));
    rc=mix(rc,acc*(.5+.6*rl),yLn((tv-.985)*ku,.02*inRM,ph));
    float wk=clamp((1.01-tv)*ku/ph+.5,0.,1.)*smoothstep(1.5,4.,Ru*2./ph);
    col=mix(col,rc,wk);
    gM=clamp((1.-gd)/(pq*1.5)+.5,0.,1.)*wk;gQ=gq/.92;gN=mix(6.,max(float((i0>>13)&15),6.),inC);gRt=ci*1.7*(1.-inC);gT=gt;gPq=pq/.92;yKx=mix(ci,7.,inC)+float(jg);ySym=0.;
    gTl=.15*tp;gG=(.75+.6*rl+.75*uKick+.45*uHit);gF=mix(gt,vec3(1),.6)*2.2*ro*(1.-gd*.6);
  }else if(kind<.5){
    int Hp=int(meta.z+.5),Rp=int(meta.w+.5),R2=int(rr.x+.5),R4=int(rr.y+.5);
    // replay the fold word (newest step first) through the colouring
    int x=x0;
    for(int j=0;j<30;j++){
      if(j>=n)break;
      int km=wa&7;wa=(wa>>3)|((wb&7)<<27);wb=(wb>>3)|((wc&7)<<27);wc>>=3;
      x=yRk(yOct(Hp,x),km,Rp,R2,R4);
    }
    float a=G.x,cd=G.y,cr=G.z,mm=G.w,sv=ySv(G);
    float dl=2.*yAth(length(tp));
    // snare: the colour classes step on by one, tile by tile, in a wave running out from the centre
    float fR2=mod(uM1[2].y,64.);
    int fi=(fl&1023)-int(step(fR2,dl))+jg;
    float fw=(dl-fR2)/.6;fw=exp(-fw*fw)*step(fR2,14.);
    base=yK(float(x+fi),fm)*(1.+.8*fw);alt=yK(float(x+fi+1),fm);
    band=clamp(dl/5.4,0.,1.);es=spec(.03+.9*band);onb=yOn(int(band*7.99));
    float rp=uM1[2].z;ring=(dl-floor(rp/128.)/128.)/.75;ring=exp(-ring*ring)*mod(rp,128.)/90.;
    float r2=dot(z,z),r=sqrt(r2);dC=2.*yAth(r);
    dE=yGeo(z,vec2(cd,0),cr);
    float sg=sign(z.y+1e-9);
    vec2 vt=sv*vec2(cos(a),sg*sin(a));dV=length(z-vt)*2./(1.-sv*sv);
    lp=ph;float mph=uM1[1].x;
    grout=.03*inR+.008*inR*kick;
    // v14: the hat envelope (60 ms attack / 0.3 s hold, from JS) arrives in the realm slot uQa.x
    vec4 yH4=vec4(uQa,0.);   // uniforms are read into a size-matching local first: ANGLE/D3D11 mishandles selects
    hat=clamp(yH4.x,0.,1.);
    if(motif==1){
      // STAR: interlaced hankin strapwork through every edge midpoint, stained glass between the straps.
      float tt0=.6+.06*float(style);
      vec2 P0=vec2(mm,0.),nr=vec2(cos(tt0),sin(tt0)),zz=vec2(z.x,abs(z.y));float tt=(1.-mm*mm)/(2.*mm*nr.x);
      vec2 cP=P0+tt*nr;float rP=abs(tt);
      float dP=yGeo(zz,cP,rP),dM=yGeo(zz,yJ(cP),rP),dS=yGeo(yC(vec2(cos(2.*a),sin(2.*a)),yJ(zz)),cP,rP);
      vec2 ea=vec2(cos(a),sin(a));float ec=dot(ea,cP),dP0=length(z-P0);
      bool nearM=dP0<.5*length(P0-ea*min(ec-sqrt(max(ec*ec-1.,0.)),sv));
      float cnt=step(dP,0.)+step(dM,0.);
      float gl=mix(1.,.72+.28*sin(dE/inR*70.+mph)*sin(dC/inR*46.),smoothstep(.09,.02,lp/inR));
      col=cnt<.5?base*(.75+.25*cos(dC/inR*9.-mph*2.))*(.75+1.6*es*smoothstep(.5*inR,0.,dC))+base*.9*exp(-dC/(.12*inR))*(.4+es*2.)
        :(cnt>1.5?mix(deep,acc,.35)+acc*(.35+.9*uB1.z)*exp(-dP0*2./(1.-mm*mm)/(.1*inR)):(dS<0.&&dP<0.?alt*.62*gl+alt*.6*exp(-dV/(.15*inR)):base*.62*gl+base*.35*smoothstep(.0,.3*inR,dE)));
      float sw=.075*inR,ow=.03*inR;
      // over/under: near the midpoint crossing one strap is on top, near the vertex star the other
      bool up=z.y>=0.;
      float dU=nearM?(up?dP:dM):(up?dS:dP),dO=nearM?(up?dM:dP):(up?dP:dS);
      vec3 sc=mix(acc,base,.28);
      float f=yLn(dU,sw,lp);
      col=mix(col,deep*.5,yLn(dU,sw+ow,lp));
      col=mix(col,sc*(.45+.9*sqrt(max(1.-abs(dU)/sw,0.)))*(1.+.8*kick+1.2*onb),f);
      col=mix(col,base*1.5+.2+.8*uB2.x,yLn(dU,.012*inR,lp)*f);
      f=yLn(dO,sw,lp);
      col=mix(col,deep*.5,yLn(dO,sw+ow,lp));
      col=mix(col,sc*(.45+.9*sqrt(max(1.-abs(dO)/sw,0.)))*(1.+.8*kick+1.2*onb),f);
      col=mix(col,base*1.5+.2+.8*uB2.x,yLn(dO,.012*inR,lp)*f);
      gM=step(cnt,.5)*(1.-max(yLn(dU,sw+ow,lp),yLn(dO,sw+ow,lp)));
      float nC=float(P<5?2*P:P);
      gQ=z/(mm*.92);gN=nC;gRt=mph*.3;gT=base;gPq=ph*max(1.-r2,.02)*.5/(mm*.92);yKx=float(x);
      vec2 dUq=yN(Dr);
      gTl=.14*tp+yC(vec2(cos(float(x)*2.4),sin(float(x)*2.4))*.1+vec2(.1*ring,.06*uHit),dUq);
      gG=(.92+.75*es+.3*uB1.z)*(1.+.9*onb)*(1.+.2*kick+.45*uHit);
    }else{
      // JEWEL (motif 0) and WYTHOFF (motif 3): the uniform tilings of {p,q} from the Wythoff point W in the triangle
      // (centre, edge midpoint, vertex). Centre faces are ray traced stones in the perfect colouring; vertex and edge faces
      // take a colour by their own distance from the screen centre: concentric rings that play the spectrum.
      float mp=motif==0?993.:uM1[2].x,ws=mod(mp,1024.)/1023.;vec2 ea=vec2(cos(a),sin(a)),ce=vec2(cd,0);
      vec2 W=(ce+cr*normalize(mix(vec2(-1,0),sv*ea-ce,ws)))*(1.-floor(mp/1024.)/1023.),zz=vec2(z.x,abs(z.y));
      float ww=dot(W,W)+1.,g1=ww/(2.*W.x),g2=ww/(2.*dot(W,ea)),q1=sqrt(max(g1*g1-1.,0.)),q2=sqrt(max(g2*g2-1.,0.));
      vec2 c3=vec2(1./cd,(ww*.5-W.x/cd)/max(W.y,1e-4));float r3=sqrt(max(dot(c3,c3)-1.,0.));
      float d1=yGeo(zz,vec2(g1,0),q1),d2=yGeo(zz,g2*ea,q2),d3=yGeo(zz,c3,r3);
      fC=step(0.,d1)*step(0.,d2);float fM=(1.-fC)*step(d1,0.)*step(0.,d3);
      de=mix(mix(min(abs(d2),-d3),min(-d1,d3),fM),min(d1,d2),fC);
      float rf=min(g1-q1,g2-q2);fR=2.*yAth(rf);
      float bev=smoothstep(0.,.22*inR,de);
      vec3 kn=normalize(vec3(-mix(normalize(vt),vec2(1,0),fM)*mix(.55,.4,fM),.84));
      float kd=max(dot(kn,L),0.),k4=kd*kd;k4*=k4;
      float gl=mix(1.,.75+.25*sin(de/inR*64.)*sin(dC/inR*40.+mph),smoothstep(.09,.02,lp/inR));
      cO=mix(mix(jc,acc,.35)*(.2+1.25*kd)*(.7+.3*bev)*gl+mix(acc,vec3(1),.5)*k4*k4*(1.+3.*uO2.x),mix(deep,jc,.45)*(.35+.9*kd),fM);
      b1=.13*fR;
      // the bezel: a gold wire with a bead of light rolling round it
      float u=clamp((de-grout)/(b1-grout),0.,1.)*2.2-1.1;
      vec3 nrm=normalize(vec3(sin(u),0.,cos(u)));
      df=max(dot(nrm,L),0.);sp=pow(max(dot(nrm,Hv),0.),70.);
      // v20: the wire is a twisted rope; its strands show wherever they are a few pixels wide
      {float ra=atan(z.y,z.x)/a*8.+u*1.5;df*=1.-.5*smoothstep(3.,7.,2.*a*fR/16./lp)*smoothstep(.25,.75,abs(fract(ra)-.5)*2.)*step(abs(u),1.05);}
#if HD>=1
      // milgrain beads along the gold wire; finer rows of beads at the higher tiers
      float sa=atan(z.y,z.x)/a,Nb=HD>=3?16.:(HD>=2?12.:8.),spc=2.*a*fR/Nb,mb=.5+.5*cos(sa*Nb*PI);mb*=mb;mb*=mb;
      mg=mb*smoothstep(2.5,7.,spc/lp)*smoothstep(.55,.15,abs(de-.55*b1)/max(b1,1e-3));
#endif
      float pz=ph*max(1.-r2,.02)*.5/(rf*.875);
      float nC=float(P<5?2*P:P);
      if(mod(float(x),2.)>.5&&nC<7.)nC*=2.;
      vec2 dU=yN(Dr);
      gM=fC*step(b1,de);gQ=z/(rf*.875)*(1.+.22*ring);gN=nC;gRt=mph*.3;gT=base;gPq=pz;yKx=float(x);
      gTl=.14*tp+yC(vec2(cos(float(x)*2.4),sin(float(x)*2.4))*.1+vec2(.1*ring,.06*uHit),dU);
      gG=(.92+.75*es+.3*uB1.z)*(1.+.9*onb)*(1.+.2*kick+.45*uHit);gF=base*onb*.12;
    }
  }else if(kind>4.5){
    // a stone only a few pixels across: the table flashes on its band's onset
    float pz=ph*max(1.-dot(z,z),.05)*.5;
    gM=1.;gQ=z/.97;gN=8.;gT=jc;gPq=pz/.97;yKx=float(jg);
    gG=(.85+.6*yJl+.75*uKick+.45*uHit);gF=mix(acc,vec3(1),.5)*2.5*onJ*smoothstep(.55,.2,length(z));
  }
  vec3 gC=vec3(0);
  if(gM>.002)gC=yStone(gQ,gN,gRt,gT,gPq,gTl,yN(Dr))*gG+gF;
  if(kind>1.5&&kind<2.5)col=mix(col,gC,gM);
  else if(kind>4.5)col=gC;
  else if(kind<.5){
    if(motif==1)col=mix(col,gC,gM);
    else{
      vec3 gd=mix(acc,alt,.18)*(.12+1.25*df)+vec3(1.,.95,.85)*sp*(2.2+uB2.w)+mix(acc,vec3(1),.4)*mg*(.35+.9*df+.6*hat);
      col=mix(gd,gC,gM);
      col*=1.-.75*yLn(de-b1,.012*inR,lp);
      col=mix(cO,col,fC);
      dE=mix(min(de,dE),de,fC);
    }
    float fz=smoothstep(.05,.2,lod),ge=yLn(dE,grout,lp);
    col=mix(mix(col,base*.62+acc*.05,fz),deep,ge);
    // kicks light a thin neon line inside every grout; the kick ring lights the generation it is passing
    col+=mix(acc,base,.55)*yLn(dE,.011*inR,lp)*(1.5*kick+1.4*ring+.9*uO1.y+1.*hat+.2*uB2.w)*(1.-fz*.5);
    // hats and the air band: glints at the vertices of the outer rings
    float vg=exp(-dV/(.045*inR*(1.+1.2*hat+.6*uB2.w)));
    col+=mix(acc*1.3,vec3(1),.5-.35*hat)*vg*(.25+(3.5*hat+1.6*uB2.z)*(.45+.55*smoothstep(.15,.7,band))+2.*uO2.w);
    col*=(1.-.25*smoothstep(2.,6.,2.*yAth(length(tp))))*(.72+.5*yJl);
    col=mix(col,glowC*.55+base*.4,glowK);
    if(yDim>.5)col=md==3?mix(col*.22+deep+mix(base,acc,.3)*ge*.7+acc*vg*.25,glowC*.5,glowK):col*.8/(1.+.12*yDim);
  }
  return col;
}

void realm(){
  ySK=0;yKx=0.;ySym=1.;ySpk=1.;yZ=int(step(1e9,uDetail));yHt=clamp(vec4(uQa,0.).x,0.,1.);yHt*=yHt;yFl=uO2.w;
  float zm=max(uZoom,.05)*max(uM1[1].y,.05);
  vec2 sp=scr();
  float d=length(sp);
  float uB=step(d,uP5.x);
  // the dive: inside the window the new world is drawn at its own zoom (it becomes the full view as the dive ends)
  float zb=zm*mix(1.,uM1[0].z,uB),px=1./(uRes.y*zb);
  float fd=abs(d-uP5.x)*uRes.y,front=clamp(2.5-fd*.5,0.,1.)*step(0.,uP5.x);
  vec3 col=yRender(sp/zb,px,mix(uP1,uP3,uB),mix(uP2,uP4,uB),mix(uM2[2].yz,uP5.yz,uB));
  col=mix(col,mix(yQ6,yPc(uM2[0].x),.5)*2.,min(front,1.)*.85);
  // jewel / limit rims: a crisp neon line with a short halo, brighter with the jewel's own band
  float rim=exp(-abs(yRimPx)/1.2)*.9/(1.+yDim)+(exp(-max(yRimRel,0.)/.03)*.12+exp(-max(yRimRel,0.)/.15)*.03)*step(0.,yRimPx);
  float yRimHat=clamp(vec4(uQa,0.).x,0.,1.);
  col+=yGlow*rim*(.35+.8*yJl+.4*uKick+1.1*yRimHat*yRimHat);   // v13: the hats light every jewel rim (v14: uQa.x)
  // v19 mosaic: the pane edges, a gold came with a dark line each side, lit on kicks and snares
  vec3 yAcc=mix(yQ6,vec3(1.,.86,.55),.35);
  col=mix(col,yQ7*2.,clamp(1.2-yCam,0.,1.));
  col=mix(col,yAcc*(.55+.5*uKick+.5*uHit)+yGlow*(.3+uKick),clamp(.5-yCam-1.4*abs(yCam/1.4),0.,1.));
  fragColor=vec4(max(yHue(col,sin(uHue*TAU)*.3),0.),0.);
}
`;
