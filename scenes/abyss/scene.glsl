const R_ABYSS = `
/* ABYSS v10: a cathedral of giant jellyfish. One colossal hero jelly (five species: atolla, moon, sea nettle, crystal,
   lion's mane) fills the frame with a translucent layered bell (halo, outer gel sheet, inner light, radial canals,
   four glowing gonad loops, a pinwheel of marginal lights) and long flowing tentacles; a second giant and a few
   mid-size jellies rise behind it, with rainbow comb jellies and the neon octopus as company, a sparse far field for
   depth, lantern-fish schools and plankton clouds, and kelp or neon coral on reef visits. The bells are strong radial
   forms built to fold into mandalas under the kaleidoscope. Every shape is analytic and filtered against its pixel
   footprint. Every kind shares one creature routine inside the one creature loop (D3D compile cost), species come
   from a table, the school is a mode of the plankton loop, and the palette hues come from JS. */
int abZ;
#if HD<1
#define AB0 0
#define AB_FL 1
#define AB_CH 2
#endif
#if HD>=1
// v19 detail tiers. Ceilings by tier; runtime counts come from uDetail; loops start at a zero the HLSL compiler cannot fold.
#define AB0 min(int(uTime),0)
#if HD>=5
#define AB_VOL 150
#define AB_CH 5
#define AB_OC 4
#define AB_LT 14
#define AB_EX 4
#define AB_SN 10
#define AB_FL 5
#define AB_TN 5
#elif HD>=4
#define AB_VOL 100
#define AB_CH 4
#define AB_OC 4
#define AB_LT 9
#define AB_EX 3
#define AB_SN 7
#define AB_FL 4
#define AB_TN 4
#elif HD>=3
#define AB_VOL 80
#define AB_CH 4
#define AB_OC 3
#define AB_LT 6
#define AB_EX 3
#define AB_SN 5
#define AB_FL 4
#define AB_TN 3
#elif HD>=2
#define AB_VOL 90
#define AB_CH 3
#define AB_OC 3
#define AB_LT 6
#define AB_EX 2
#define AB_SN 4
#define AB_FL 3
#define AB_TN 3
#else
#define AB_VOL 48
#define AB_CH 3
#define AB_OC 2
#define AB_LT 3
#define AB_EX 2
#define AB_SN 3
#define AB_FL 2
#define AB_TN 2
#endif
// 3D value noise for the marched water volume
float abVn(vec3 p){vec3 i=floor(p),f=p-i;f=f*f*(3.-2.*f);
  vec4 a=fract(sin(vec4(0.,57.,113.,170.)+dot(i,vec3(1.,57.,113.)))*43758.5453),b=fract(sin(vec4(0.,57.,113.,170.)+dot(i+vec3(1.,0.,0.),vec3(1.,57.,113.)))*43758.5453);
  vec4 m=mix(a,b,f.x);vec2 r=mix(m.xz,m.yw,f.y);return mix(r.x,r.y,f.z);}
#endif
#define abT uP1.y
#define abTp uM2[1].z
#define abCp uM2[2].x

float abHz,abHk,abGlow,abPulse,abAA,abSpin,abH2,abZf,abD,abKT,abInk,abLion,abHP,abHat,abSoft,abLev,abPost,abRT,abImp;
vec3 abC1,abC2,abC3;
vec3 abP0,abP1,abP2,abP3;
mat4x3 abPM;
// layer scale: a layer at depth z (1 = default framing) maps screen coords to its own coords; zooming out pulls the
// camera back by abD and widens the field of view by 1/abZf, so near layers shrink much more than far ones
float abG(float z){return (1.+abD/z)/abZf;}
vec3 abBow(float h){vec3 c=clamp(abs(fract(h+vec3(0.,2.,1.)/3.)*6.-3.)-1.,0.,1.);return c*c*(3.-2.*c);}
// palette colour k (0..3) of the current wipe mix (computed once per pixel from the curated neon hues sent by JS)
mat4x3 abPal(vec4 h){
  vec4 r=clamp(abs(fract(h)*6.-3.)-1.,0.,1.),g=clamp(abs(fract(h+2./3.)*6.-3.)-1.,0.,1.),b=clamp(abs(fract(h+1./3.)*6.-3.)-1.,0.,1.);
  r=r*r*(3.-2.*r);g=g*g*(3.-2.*g);b=b*b*(3.-2.*b);
  return mat4x3(vec3(r.x,g.x,b.x),vec3(r.y,g.y,b.y),vec3(r.z,g.z,b.z),vec3(r.w,g.w,b.w));}
vec3 abCol(float k){return abPM*vec4(equal(vec4(mod(floor(k),4.)),vec4(0.,1.,2.,3.)));}
// anti-aliased line coverage; sub-pixel lines keep their energy instead of shimmering
float abLine(float d,float w,float aa){float ia=1./aa;return clamp((max(w,aa*.5)-d)*ia+.5,0.,1.)*min(w*2.*ia,1.);}
float abDot(float d,float r,float aa){float ia=1./aa,k=min(r*1.667*ia,1.);return clamp((max(r,aa*.6)-d)*ia+.5,0.,1.)*k*k;}
float abEll(vec2 p,vec2 r){float k0=length(p/r),k1=length(p/(r*r));return k0*(k0-1.)/max(k1,1e-5);}
float abPulseAt(float t){return smoothstep(0.,.08,t)*exp(-max(t-.08,0.)*4.5);}
// two values in 0..1 packed in one uniform float by JS (12 bits integer part, fraction)
vec2 abUp(float v){return vec2(floor(v)/4096.,fract(v));}

// rows of photophores in a 5 x 7 lattice, ten groups of 6 columns (p.x 0..60, p.y 0..7 from the bottom): 1 where a light sits
float abSeal(vec2 p){
  const float C[60]=float[60](49.,73.,73.,73.,70.,0.,64.,64.,127.,64.,64.,0.,62.,65.,65.,65.,62.,0.,127.,32.,16.,8.,127.,0.,127.,73.,73.,73.,65.,0.,127.,65.,65.,65.,62.,0.,0.,0.,0.,0.,0.,0.,63.,72.,72.,72.,63.,0.,127.,72.,72.,72.,48.,0.,127.,73.,73.,73.,65.,0.);
  float v=C[int(clamp(p.x,0.,59.))];
  return mod(floor(v*exp2(-floor(clamp(p.y,0.,6.)))),2.)*step(0.,p.x)*step(p.x,59.999)*step(0.,p.y)*step(p.y,6.999);
}
// One filament of a hanging family (jelly tentacles, comb-jelly tentacles, octopus arms). The nearest filament is
// found analytically from the angle around the body, so there is no loop. Light beads (suckers on the octopus)
// stream down; on the kick a bright pulse runs from the body to the tips, where a knot of stinging cells glows.
vec3 abTentacle(vec2 q,float wm,float bb,float e,float L,float nt,float amp,float fr,float h,float sprd,float wid,float fe){
  float v0=-bb-q.y;
  float t0=clamp(v0/L,0.,1.);
  float a=amp*(.3+abH2+abLev*.7*uB1.y)*sqrt(t0),arg=v0*fr-abTp*3.+h*6.;   // (v22b: the leviathan's curtain sways wider with the bass)
  float u=clamp((q.x-a*sin(arg))/(wm*.96*(1.+sprd*t0)),-1.,1.);
  float pf=asin(u);
  float st=TAU/nt,k=floor((pf-abSpin)/st);
  float ph=(k+.5)*st+abSpin,sp=sin(ph),cp=cos(ph);
  vec2 rt=vec2(wm*.96*sp,-bb+e*cp);
  float v=rt.y-q.y,Lk=L*(.7+.3*fract(sin(k*12.9+h*50.)*43.7));
  float msk=step(0.,v)*step(v,Lk)*step(.05,L);
  float t=clamp(v/Lk,0.,1.),ag=v*fr-abTp*3.+h*6.+ph*.7;
  float xk=rt.x*(1.+sprd*t)+a*sin(ag)+abLev*(.02*uB2.w+.012*uB2.z+.006*abHat)*sin(v*34.-abT*9.+ph*3.)*t;   // (v22b: and shivers with the air band)
  float dx=sprd*rt.x/max(L,.5)+a*fr*cos(ag);
  float d=abs(q.x-xk)/sqrt(1.+dx*dx);
  float ww=wid*mix(1.,.3,t);
  // v20: once a filament is several pixels wide it is a banded tube, not a flat ribbon: alternating colour bands with dark
  // joints, a bright wall, a darker lumen and a luminous canal down the middle
  float bg=smoothstep(2.5,6.,ww/abAA),an=v/(wid*3.6)+h*3.,jd=abs(fract(an*2.)-.5),aj=abAA/(wid*1.8);
  ww*=1.-.24*bg*smoothstep(.2,.5,jd);                      // every segment pinches at its joints: a string of beads
  float cov=abLine(d,ww,abAA),pr=min(d/max(ww,1e-5),1.);
  float shd=mix(1.,(.3+.7*pr*pr)*smoothstep(.5,.47-aj,jd)+.9*abLine(d,ww*.1,abAA),bg);
  vec3 tcl=mix(abC1,abC2,smoothstep(.5-aj,.5+aj,abs(fract(an)-.5)*2.)*.6*bg);
  float bc=.5+.5*cos(v*(7.+110.*max(wid-.02,0.))-abTp*5.+ph),bc2=bc*bc,bc4=bc2*bc2;
  float kp=(t-abKT*1.3)*5.;
  // hats: runs of light stream down every filament (the phase steps on with each hat, they brighten with the hats)
  float hr=.5+.5*cos((t*3.-abHP)*TAU);hr*=hr;hr*=hr;hr*=hr;
  // v22b: on an impact (abImp) a hard-edged band of light drops down the leviathan's curtain from the margin to the tips in under a second
  float kp2=(t-abRT*1.1)*4.,kp3=(t-abKT*2.4)*6.;
  float bead=min(bc4*bc4*bc2*(1.-fe)+exp(-kp*kp-abKT*1.5)+abLev*(exp(-kp2*kp2-abRT*1.3)+abImp*clamp(1.5-abs(kp3)*1.5,0.,1.)*exp(-abKT*2.))+hr*(abHat+1.6*uB2.w+uB2.z)*.8,1.);
  // a soft glow sheath around each filament (thinner for the hair-fine curtains)
  float sh=exp(-d/(wid*2.5/abHz+abAA))*(1.-t)*min(1.,10./nt)*(1.-.7*bg)*abSoft*(1.-abLev);
  return (mix(tcl,abC3,bead)*(cov*(.7+2.2*bead)*shd+sh*(.3+1.2*hr*abHat))*sqrt(1.-.9*t)*msk)*step(.05,L);
}
// The whole bestiary in one parameterised routine (one copy inside the creature loop keeps the D3D compile cheap):
// ty 0 = bell jelly (five species), 1 = comb jelly, 2 = octopus.
vec4 abCreature(vec2 q,float ty,float h){
  float aa=abAA,P=abPulse;
  vec3 tv=vec3(equal(vec3(ty),vec3(0.,1.,2.)));
  float tj=tv.x,tc=tv.y,to=tv.z;
  // jelly species, one-hot: atolla saucer (pinwheel alarm lights), moon jelly (long oral arms, bold gonad loops), sea
  // nettle (tall bell, very long tentacles), crystal jelly (many canals) and the lion's mane (a curtain of hair)
  float lm=abLion;
  vec4 o=vec4(equal(vec4(floor(fract(h*5.71)*4.)),vec4(0.,1.,2.,3.)))*(1.-lm);
  // species table (columns: atolla, moon, nettle, crystal; the lion's mane is its own column)
  // J1: bell half-width, bell height, canals, tentacles; J2: tentacle length, oral arms, marginal lights, margin
  // ellipse; J3: tentacle sway, sway frequency, gonad loops
  vec4 J1=mat4(1.12,.5,16.,18., 1.08,.6,16.,32., .8,1.,12.,10., .98,.68,28.,16.)*o+vec4(1.3,.5,24.,72.)*lm;
  vec4 J2=mat4(3.4,0.,1.6,.24, 2.4,3.4,.4,.22, 7.,3.6,.5,.17, 5.,1.6,1.1,.2)*o+vec4(8.6,4.4,.3,.2)*lm;
  vec3 J3=mat4x3(.22,2.4,.45, .14,3.,1., .5,1.2,.35, .32,1.8,.7)*o+vec3(.55,1.,.25)*lm;
  float jnt=mix(J1.w,44.,abLev),arm=J2.y*tj,mar=max(J2.z*tj,abLev);
  float R0=.5+.25*fract(h*3.3),ctent=step(.45,fract(h*8.1));
  // body of revolution: jelly = bell over a thin margin ellipse (contracts on the kick), comb = egg, octopus =
  // bulbous mantle (squeezes on the kick: jet propulsion)
  float wm=dot(tv,vec3(J1.x*(1.-(.2+.2*abLev)*P)*(1.+.1*abLev*uB1.x),R0,.62*(1.-.14*P)));
  float bt=dot(tv,vec3(J1.y*(1.+.12*P),1.3,.9*(1.+.12*P)));
  float bb=tj*.12*(1.-.4*P);
  float e=J2.w*wm;
  float bbot=dot(tv,vec3(e,1.3,.42));
  vec2 eq=vec2(q.x,q.y+bb);
  float up=step(0.,eq.y),ry=mix(bbot,bt,up);
  float yn=clamp(eq.y/ry,-1.,1.);
  float egg=1.+.16*tc*yn+.22*to*yn-.12*tj*yn*yn*up;
  vec2 rr=vec2(wm*egg,ry);
  float dB=abEll(eq,rr),k0=length(eq/rr);
  float sw=max(wm*egg*sqrt(max(1.-yn*yn,0.)),.05);
  float xn=clamp(q.x/sw,-1.,1.);
  float inb=clamp(.5-dB/aa,0.,1.);
  float nz=sqrt(max(1.-k0*k0,0.)),fres=(1.-nz)*(1.-nz);
  // octopus skin drifts between the palette's neons
  vec3 bc=mix(abC1,mix(abC1,abC3,.5+.5*sin(abCp*.5+yn*2.+h*6.)),to);
  float cg=1.+.7*(abHz-1.);   // v13: pushed in, the body glow lifts (the halo outside stays tight)
  float lg=mix(1.,.4,smoothstep(110.,380.,1./aa));           // v20: a bell that fills the frame keeps its glow tight
  // v22: abSoft is 1 in lit water and falls toward 0 when the lights go out (bodies, halos and inner glows fade; rims, canals,
  // photophores and lures stay); abLev marks the leviathan, which carries no halo at all (it would be a frame-wide haze)
  vec3 em=bc*inb*(dot(tv,vec3(.06,.03,.12))*cg+dot(tv,vec3(.62,.45,.6))*fres*lg*(1.-.8*abLev))*mix(.14,1.,abSoft)*(1.-.5*abLev);
  float al=inb*(dot(tv,vec3(.26,.3,.82))-.12*fres);
  // a crisp neon rim, never thinner than about a pixel, so every silhouette reads at any size
  em+=bc*abLine(abs(dB),max(.01,aa*.55),aa)*dot(tv,vec3(1.5,.9,1.2));
  // jelly glow layers: a halo of light around the bell (swells on the kick and with the bass), the outer gel sheet
  // (a second, fainter skin just outside the bell) and the light inside the bell
  float dO=max(dB,0.),gel=step(dB,.07)*(1.-inb);
  em+=tj*(bc*(exp(-dO*15.*abHz/lg)*.12*sqrt(abHz)*(1.+abGlow+1.2*P+.9*abHat+.6*uB2.w)+exp(-dO*5.*abHz)*.02*(1.+P)*lg)*(1.-inb)*abHk*lg*abSoft*(1.-abLev)
     +abC3*(abLine(abs(dB-.07),max(.005,aa*.5),aa)*.55+gel*.07)*up*(1.+1.6*uB2.x+1.5*uO2.x)
     +mix(abC2,abC3,.5+.5*yn)*inb*(1.-k0)*(1.-k0)*(.06+.25*P+.1*uB1.y)*cg*abSoft*(1.-.92*abLev));
  // surface: meridian lines (jelly canals, comb rows) on the back and front sheets; octopus chromatophores
  float pf=asin(xn),fp=aa/max(sqrt(1.-xn*xn),.12);
  float n=tj*J1.z+tc*8.,lw=tj*(.006+.006*(1.-yn))+tc*.04;
  float smask=inb*mix(1.,up,tj)*mix(1.,smoothstep(.92,.8,abs(yn)),tc);
  float fm=mix(1.,smoothstep(0.,.25,yn)*(1.-.5*yn),tj);
  float pl=fract(eq.y*11.-abCp*2.),plate=smoothstep(.0,.15,pl)*smoothstep(.7,.45,pl);
  vec2 lb=(vec2(PI-pf,pf)-abSpin)/TAU*n+.5,ld=abs(fract(lb)-.5)*TAU/max(n,1.)*sw;
  float sbk=abLine(ld.x,lw,fp),sfr=abLine(ld.y,lw,fp);
  vec3 cf=abBow(eq.y*.9-abCp*.6+floor(lb.y)*.11+h);
  // v22: the octopus's skin is a display, not polka dots: bands of colour ripple across the mantle with the mids (a passing-cloud
  // display), rows of chromatophores swell inside the bright bands, and every snare snaps the pattern to a new direction (abPost)
  vec2 og=vec2((pf-abSpin*.3)*4.77,yn*11.+11.);og.x+=.5*mod(floor(og.y),2.);
  float opa=abPost*.7854,ow=sin(dot(vec2(pf*2.6,yn*3.4),vec2(cos(opa),sin(opa)))*2.2+1.5*sin(yn*2.2+abTp*.7)-abTp*1.6+h*6.),ost=smoothstep(-.3,.3,ow);
  float od=length((fract(og)-.5)*vec2(.21*sw,.091*ry)),spt=(abDot(od,.012+.026*ost,fp)+abLine(abs(ow)*.05*ry,.011,fp))*to*(1.+3.*exp(-abInk*1.5));
  // canals: a light pulse runs from the apex to the margin on every kick; the mids brighten them
  float kp=(1.-yn-abKT*2.4)*4.,hc=.5+.5*cos((yn*1.5+abHP)*TAU);hc*=hc;hc*=hc;float kq=(1.-yn-abRT*2.2)*3.5,cpul=1.+2.4*exp(-kp*kp-abKT*1.2)+3.*abLev*exp(-kq*kq-abRT*1.3)+.6*uB1.w+.6*hc*abHat;
  vec3 cc=mix(mix(abC1,abC2,.5),abC3,hc*abHat)*cpul;
  // octopus chromatophores flicker through neon hues with the hi-mids
  vec3 spot=mix(abC2,abC3,ost)*(.8+1.2*uB2.x+.8*abH2);
  em=em*(1.-.35*spt*smask)*(1.-.62*to*(1.-ost))+smask*(tj*(abC2*.4*sbk*fm*cpul+cc*1.3*sfr*fm)+tc*((cf*1.9+vec3(.15))*(sfr+.25*sbk)*(.3+1.6*plate)*(1.+1.4*uO2.w+.6*uB2.w))+spt*spot);
  // v13: photophores, clustered like a real jelly's: thick along the bell rim and the tentacle roots, a few scattered
  // over the dome. Jittered cells, every light its own size and brightness (most dim, a few bright). They only appear
  // once the creature is large on screen (zoomed in, close giants), so pushing in reveals finer detail; they sparkle
  // with the hats and shimmer with the air band
  {
    vec2 mq=vec2(pf*wm,eq.y)*20.,mi=floor(mq);
    float mh=fract(sin(dot(mi,vec2(12.9898,78.233))+h*7.)*43758.5);vec3 mo=fract(mh*vec3(37.13,91.71,13.37));
    float mb=mo.x*mo.y,md=length(fract(mq)-.2-.6*mo.xy)-.08-.22*mb;
    em+=mix(abC3,abC2,mo.y)*clamp(.5-md*.05/aa,0.,1.)*(.5+2.6*mb)*step(mo.z,.12+.75*min(fres*2.+smoothstep(.45,0.,yn)*tj,1.))
       *smoothstep(3.5,7.,.05/aa)*inb*mix(1.,up,tj)*(tj+to)*(.35+(.55+.45*sin(abT*2.+mh*40.))*(.35+2.4*abHat+1.6*uB2.w));
  }
  // v20: ornament on the dome once the bell is large on screen: herringbone veins between the canals, latitude rings with a pearl
  // on every canal, and a lace trim of arches along the margin; kick pulses and the mids light them
  {
    float o1=smoothstep(40.,100.,1./aa)*tj*inb*up;
    if(o1>.01){
      float cu=abs(fract(lb.y)-.5),nn=max(n,1.),hb=abs(fract(yn*7.-cu*2.4)-.5)/7.*ry;
      float ly=abs(fract(yn*4.)-.5)*.25*ry,arw=.5*TAU/nn*sw,la=abs(length(vec2((.5-cu)*TAU/nn*sw,eq.y-.004))-arw*.92);
      em+=o1*fm*(abC2*abLine(hb,.0035,aa)*.34*smoothstep(.02,.1,cu)*(mix(cpul,1.+.3*(cpul-1.),abLev)+abLev*(4.6*uB2.w+2.8*uB2.z))
        +abC3*(abLine(ly,.003,aa)*.3+abDot(length(vec2(ld.y,ly)),.013,aa)*1.5*(.6+.9*hc*abHat+.8*uB1.w+1.6*uB2.w)))
        +o1*abC3*abLine(la,.004,aa)*.8*step(eq.y,arw*1.2)*(1.+1.5*P);
#if HD>=1
      em+=o1*fm*(abC3*abLine(abs(fract(yn*21.-cu*7.2)-.5)/21.*ry,.0016,aa)*.2*smoothstep(110.,260.,1./aa)*smoothstep(.03,.1,cu)*cpul
        +abC2*abDot(length(vec2(ld.y,abs(fract(yn*12.)-.5)/12.*ry)),.0055,aa)*1.3*smoothstep(90.,200.,1./aa)*(.6+2.*uB2.w+abHat));
#endif
    }
  }
  // v19: the mesogloea is alive with detail (from v20 the first level shows at every tier). Each level is a finer net of cells or branching canals, faded in by its pixel footprint, drawn in the
  // creature's own colours at limited coverage so the bell stays translucent and saturated; then one reflection ray to the rippling light ceiling.
  if(inb>.01&&(tj+to)>.5){
    vec2 cq0=vec2(pf*wm,eq.y);float cS=26.,nL=min(float(AB_FL),1.+log2(max(uDetail,1.))*1.3);
    for(int cl=AB0;cl<AB_FL;cl++){
      if(float(cl)>=nL)break;
      float cpx=1./(cS*aa),fd=clamp(cpx*.11-.55,0.,1.);
      if(fd<=0.)break;
      vec2 cg2=cq0*cS+float(cl)*vec2(3.7,1.9),ci2=floor(cg2),cf2=cg2-ci2;
      float ch=fract(sin(dot(ci2,vec2(12.9898,78.233))+h*7.)*43758.5);
      vec2 co2=.25+.5*fract(ch*vec2(37.13,91.71));
      float cd2=length(cf2-co2),rim2=abs(cd2-.34-.12*ch);
      vec3 cc2=mix(abC2,abC3,fract(ch*5.3))*(.55+1.3*abHat*step(.8,ch)+.5*uB2.w);
      em+=cc2*clamp(1.-rim2/(.05+1.5/cpx),0.,1.)*fd*inb*mix(.34,.17,to)*mix(1.,up,tj)*mix(.5,1.,fres+.35)*(1.-.7*abLev);
      em+=abC3*clamp(1.-cd2/(.09+1./cpx),0.,1.)*fd*inb*.45*step(.72,ch)*(.35+1.8*abHat+uB2.w);
      cS*=2.3;
    }
#if HD>=1
    // reflection: the bell's normal sends the ray up to the caustic ceiling; the ceiling's net of light is read there
    vec3 rn=vec3(eq.x/max(rr.x,.05),eq.y/max(ry,.05),nz);rn=normalize(rn+vec3(0.,0.,1e-3));
    vec3 rd=reflect(vec3(0.,0.,-1.),rn);
    if(rd.y>.05){
      float dst=2.5/rd.y;vec2 wr=rd.xz*dst+vec2(abT*.12,abT*.08);
      float v2=sin(wr.x*2.3+sin(wr.y*1.9+abT*.5)+abT*.3)+sin(wr.y*2.6+sin(wr.x*1.4-abT*.4)-abT*.2);
      float nt2=1.-smoothstep(.1,.5,abs(v2));
      em+=mix(abC1,abC3,.6)*nt2*inb*up*(.05+.55*fres)*(.6+.8*uB1.y)*(1.-.8*abLev);
    }
#endif
  }
  // gonads: four glowing horseshoe loops round the top of the bell (the four-fold heart of the jelly; they glow with
  // the low-mids and flash on low-mid onsets)
  float gk=floor((pf-abSpin)/1.5708+.5)*1.5708+abSpin;
  vec2 gq=vec2(q.x-sw*sin(gk),(eq.y-.4*ry)*1.25);
  float gd=abs(length(gq)-.15*wm);
  em+=abC3*(abLine(gd,.022*wm,aa)+.25*exp(-gd/(.05*wm)))*smoothstep(0.,.45,cos(gk))*smoothstep(-.1*wm,.02*wm,gq.y+.04*wm)*inb*up*tj*J3.z*(1.1+1.4*uB1.z+2.*uO1.z);
  // manubrium (jelly), pharynx (comb); the jelly's hollow inner bell (subumbrella) seen through the dome
  vec2 cq=(q-vec2(0.,mix(-.1,bt*.22-bb,tj)))/vec2(mix(.13*R0,.32*wm,tj),mix(.75,.42*bt,tj));
  {float cr2=dot(cq,cq),cr1=sqrt(cr2),ros=mix(1.,.3+.7*smoothstep(-.3,.5,cos(4.*atan(cq.y,cq.x)+abSpin))*(.55+.45*smoothstep(.3,.1,abs(fract(cr1*3.5-abKT*.6)-.5))),tj*smoothstep(25.,60.,1./aa));
   em+=abC2*exp(-cr2*mix(2.,4.,tj))*inb*(tj*(.45+.8*P+.4*uB1.w)*lg+tc*.5)*ros*mix(.2,1.,abSoft)*(1.-.85*abLev)
     +abC3*abLine(abs(cr1-.42)*.3*wm,.004,aa)*inb*tj*smoothstep(25.,60.,1./aa)*(.5+P+.6*uB1.w);}
  // v20: the bell's ring muscles, concentric bands seen through the dome; a ring of light runs outward through them on the kick
  // (the leviathan's rings answer every kick: a ring of light spreads from its crown to the margin, abRT is the kick clock)
  {float mr=(k0*1.4-abRT*2.2)*5.;em+=abC2*abLine(abs(fract(k0*7.)-.5)/7.*min(rr.x,rr.y),.0035,aa)*smoothstep(30.,80.,1./aa)*inb*tj*(.22+(.9+3.6*abLev)*exp(-mr*mr-abRT)+.3*uB1.y)*smoothstep(.12,.3,k0);}
  vec2 ib=vec2(q.x,eq.y+.07*bt)/vec2(wm*.8,bt*.7);
  em+=abC2*abLine(abs(length(ib)-1.)*min(wm*.8,bt*.7),.007,aa)*.6*inb*up*tj;
  // jelly: marginal lights, a pinwheel of light chasing around the rim
  {
    float ph=mix(PI-pf,pf,step(0.,q.y+bb));
    float st=TAU/jnt,pd=ph-(fract((ph-abSpin)/st)-.5)*st,cq2=cos(pd);
    float dd=length(q-vec2(wm*sin(pd),-bb+e*cq2));
    // v22: the rim lights chase round the margin with the hats (a run of light steps on with every hat)
    float mch=.5+.5*cos(pd*3.-abHP*TAU);mch*=mch;mch*=mch;
    em+=abC3*(abDot(dd,.04,aa)*1.6+exp(-dd*16.)*.35*abSoft*(1.-abLev))*mix(.35,1.,smoothstep(-.3,.3,cq2))*mar*(1.+mch*(8.*abHat+2.*uB2.w));
  }
  // hanging filaments: jelly tentacles, the comb jelly's two feathery tentacles, or the octopus's eight arms that
  // fan out, sway and curl harder as the mids rise, suckers glowing along them
  {
    float L=tj*J2.x+tc*3.4*ctent+to*(1.55+.35*abH2)+.001;
    float tw=max(wm*tj+tc*.3*R0/.96+to*.42*(1.+.5*P),.05),tbb=tj*bb+tc*.15+to*.3,te=tj*e+to*.12;
    float tnt=max(tj*jnt+tc*2.+to*8.,2.),tamp=tj*J3.x+tc*.25+to*(.25+.14*abPost),tfr=tj*J3.y+tc*1.3+to*2.4+1.5*abLev,spr=tj*.3+tc*4.+to*(.7+.45*abPost+.8*P)+.5*abLev;
    float tw0=tj*(.018-.01*lm)*(1.-.5*abLev)+tc*.018+to*.085;
    em+=abTentacle(q,tw,tbb,te,L,tnt,tamp,tfr,h,spr,tw0,tc)*(1.-.35*abLev)*(1.+abLev*(3.2*uB2.w+1.6*uB2.z+1.*abHat));
#if HD>=1
    // v19: further curtains of hair-fine filaments between the main ones (more instances, each set finer and shorter)
    {float nX=min(float(AB_TN),log2(max(uDetail,1.))*1.5);
     for(int tn=AB0;tn<AB_TN;tn++){
       float ft=float(tn)+1.;
       if(ft>nX||tj<.5)break;
       em+=.6/ft*abTentacle(q,tw*(1.-.06*ft),tbb,te,L*(.92-.09*ft),tnt*(1.+ft),tamp*(1.+.15*ft),tfr*(1.+.1*ft),fract(h+ft*.317),spr,tw0*max(.42-.07*ft,.14),1.);
     }}
#endif
  }
  // jelly: four frilly oral arms hanging from the centre (parallel family: nearest ribbon by rounding)
  {
    float v=-bb-q.y;
    float am=step(0.,v)*step(v,arm)*step(.01,arm);
    float t=clamp(v/max(arm,.01),0.,1.),arg=v*2.1-abTp*1.6;
    float wave=.22*(.4+abH2)*t*sin(arg),spc=.11*wm*(1.+1.4*t);
    float fk=clamp(floor((q.x-wave)/spc+2.),0.,3.);
    float xa=(fk-1.5)*spc+wave;
    float wd=.085*(1.-.65*t)*(1.+.4*sin(v*17.+fk*2.));
    float sl=.462*t*cos(arg);
    float d=abs(q.x-xa)/sqrt(1.+sl*sl);
    float fill=clamp((wd-d)/aa+.5,0.,1.);
    em+=abC2*(fill*.06*(1.-abLev)+abLine(abs(d-wd),.008,aa)*(1.1+abLev*(2.2*uB2.x+1.6*uB2.y)))*(1.-t*.6)*am;
    al+=fill*.16*am;
  }
  // octopus eyes: big and glowing with slit pupils that wander
  {
    vec2 ep=vec2(abs(q.x)-.29,q.y+.12);
    float de=length(ep)-.15;
    vec2 lk=.045*vec2(sin(abT*.31+h*4.),.6*cos(abT*.23+h*2.));
    float eye=clamp(.5-de/max(aa,.01),0.,1.)*to;
    float pup=clamp(.5-(length((ep-lk)*vec2(1.,2.2))-.08)/aa,0.,1.);
    float er=length(ep)/.15;
    em=mix(em,(abC3*(.4+.9*smoothstep(.35,.92,er)*(.7+.3*cos(atan(ep.y,ep.x)*14.)))+abC2*.5*abDot(length(ep-lk-vec2(.03,.035)),.02,aa))*(1.-pup),eye);
    al=max(al,eye*.95);
  }

  return vec4(em,clamp(al,0.,.92));
}

/* ---------- particles ---------- */
// sparse soft dots in a drifting grid (marine snow, plankton, bokeh, fish). Returns (coverage*brightness, cell hash).
// el: elongation of the dots along x (lantern-fish streaks).
vec2 abDots(vec2 p,float sc,vec2 drift,float seed,float px,float blur,float dens,float el){
  vec2 g=p*sc+drift+seed*17.;
  vec2 id=floor(g),f=fract(g)-.5;
  float hh=h21(id+seed);
  vec2 o=(fract(hh*vec2(57.31,91.73))-.5)*.5/vec2(el,1.);
  float d=length((f-o)*vec2(1.,el));
  float r=.035+.07*fract(hh*13.),aa=px*sc*blur*el,bg=smoothstep(2.5,5.,r/aa)*step(el,1.5);
  vec2 e=abs(f-o);
  float life=mix(abLine(abs(d-r*.74),r*.17,aa)+abDot(d,r*.26,aa),abDot(d+2.4*min(e.x,e.y),r*1.15,aa)+abDot(d,r*.3,aa),step(.5,fract(hh*71.)));
  return vec2(mix(abDot(d,r,aa),life,bg)*step(hh,dens),fract(hh*31.7));
}

void realm(){
  abZ=int(step(1e9,uDetail));
  float zm=max(uZoom,.05);
  // v13: pushing in is a dolly through the water, not a narrower lens: the camera swims forward (abD < 0) while the
  // view narrows only a little, so the near giants grow ~zoom-fold while the far field stays a dense crowd of small
  // jellies behind them (more of the ocean, never a few big flat shapes)
  abZf=zm<1.?pow(zm,.47):pow(zm,.3);
  abD=zm<1.?.6*(abZf/zm-1.):.62*(pow(zm,-.7)-1.);abHz=pow(max(zm,1.),.6);
  float asp=uRes.x/uRes.y;
  vec2 s=scr();
  float pxs=1./uRes.y;
  // uniforms from JS (pairs of 0..1 values are packed two per float, see abyssPack)
  vec2 olb=abUp(uP1.w);float swim=uP1.x,lo=olb.x,bloom=olb.y;
  vec2 kc=abUp(uP1.z),im=abUp(uP2.x);
  float kT=kc.x*10.,carry=kc.y*1.5,ink=im.x*100.;abH2=im.y;
  vec2 oh=abUp(uP2.y),bh=abUp(uP5.x);abHat=oh.y;abHP=bh.y;
  // v22: the leviathan. A lion's mane wider than the frame at the default view (we live under its bell) and whole when pulled
  // back; it hangs behind everything, drifts slowly, and contracts on the musical one (levP); over the vent garden it rides high
  float gL=abG(9.);
  // v22: dv is the dive coordinate (0 twilight under the leviathan, 1 midnight, 2 the vent garden); between zones everything
  // rushes past: wrapping layers scroll with dv, the big creatures leave by one edge and their successors arrive by the other
  vec2 hfp=abUp(uM1[2].y),lvu=abUp(uP4.z),aru=abUp(uP4.w);
  float gath=oh.x,schPh=uP2.z,dv=uP2.w,Hf=hfp.x*4.,htl=hfp.y*5.-1.,Hs=2.5;
  vec3 zw=clamp(1.-abs(dv-vec3(0.,1.,2.)),0.,1.);
  float zfr=fract(dv),dwr=(zfr<.5?zfr:zfr-1.)*2.;
  float lvT=lvu.x*4.,lsn=smoothstep(.85,.95,lvu.y),levD=lvu.y*smoothstep(0.,mix(.2,.06,lsn),lvT)*exp(-max(lvT-.2,0.)*1.5),armK=floor(aru.x*8.+.5),burst=aru.y;
  vec2 gp0=vec2(.2*sin(abT*.023+uSeed.x*6.),.3+.7*zw.z+.04*sin(abT*.05+uSeed.y*5.));
  // v22b: ik is the impact envelope (1 at a strong arrival, gone in half a second)
  float ik=floor(uP5.z/10000.)/15.,bKR=uP5.z-floor(uP5.z/10000.)*10000.,ball=bh.x,spin=uP5.y,bK=floor(bKR/100.)*.1,bR=bKR-floor(bKR/100.)*100.;
  float famA=floor(uM1[0].x/1000.),sdA=uM1[0].x-famA*1000.,famB=floor(uM1[0].y/1000.),sdB=uM1[0].y-famB*1000.;
  float flg=floor(uM1[0].z),kelp=mod(flg,2.),octo=step(1.5,mod(flg,4.)),shc=mod(floor(flg*.25),64.),deal=mod(floor(flg/256.),256.),post=floor(flg/65536.),mkT=fract(uM1[0].z);
  vec2 rf=abUp(uM1[1].x);float reef=rf.x,swimD=rf.y;
  // curated neon palette hues for the two ensembles (two hues packed per float), nudged by the global hue drift
  vec4 pk=vec4(uP5.w,uM1[1].y,uM1[1].z,uM2[2].y),pf4=fract(pk);
  float hn=.05*sin(uHue*TAU);
  vec2 gc=abUp(uM1[2].x),sf=abUp(uM1[2].z),dw2=abUp(uM2[0].y),sb=abUp(uM2[1].y);float glow=gc.x*2.,calm=gc.y,schF=sf.x*9.99;
  vec2 cam=abUp(uM2[0].x)-.5;float de=dw2.x*.75,kAmp=floor(uM2[0].z)/1000.,comp=fract(uM2[0].z);
  vec2 hero0=(abUp(uM2[1].x)*2.-1.)*vec2(asp*.5,1.);
  abGlow=glow;
  float bass=uB1.y,hat=max(uB2.w,uHat*.6);
  float pulse0=max(kAmp*abPulseAt(kT),carry*exp(-4.5*kT));
  // v22b: the leviathan also answers every kick with a (smaller) contraction, and snaps to a full one on an impact
  float levP=max(levD,.85*pulse0);gp0.y+=.05*levP;abImp=lsn;
  // mid-depth reference frame: the palette wipe ring, snare waves, bursts, the vortex and the ocean light live here
  float g15=abG(1.5);
  vec2 p=s*g15;
  float bd=length(p),bang=atan(p.y,p.x);
  float fx=(bd-bR)*16.,front=exp(-fx*fx)*step(bR,3.),dg=bK*bK*(1.-smoothstep(1.4,2.8,bR))+de;   // drop afterglow + drop energy
  // v20: the wipe mixes the two palettes' colours across a soft scalloped front (a wave of colour, never a hard-edged disc)
  {float wk=smoothstep(bR+.3,bR-.3,bd*(1.+.07*sin(6.*bang+abT*.3)+.04*sin(17.*bang-abT*.2)));
   abPM=abPal(vec4(floor(pk.x)/4096.,pf4.x,floor(pk.y)/4096.,pf4.y)+hn)*(1.-wk)+abPal(vec4(floor(pk.z)/4096.,pf4.z,floor(pk.w)/4096.,pf4.w)+hn)*wk;
   abP0=abPM[0];abP1=abPM[1];abP2=abPM[2];abP3=abPM[3];}
  vec3 wc=(abP0*.022+vec3(0.,.005,.022))*(2.6-1.6*min(abZf,1.));   // the open ocean glows a little more when zoomed out
  // light rings: snare waves rolling through the swarm (slots 1-2) and plankton bursts blooming on low-mid / hi-mid
  // onsets (slots 3-4); JS sends centre, radius and strength
  vec3 rx=vec3(uP3.x,uP3.z,uP4.x),ry=vec3(uP3.y,uP3.w,uP4.y),rr=floor(ry)/1024.;
  vec3 dx=p.x-(floor(rx)/4096.-.5)*3.,dy=p.y-(fract(rx)-.5)*3.,dd=sqrt(dx*dx+dy*dy),re=(dd-rr)*12.;
  vec3 ring=fract(ry)*1.5*(exp(-re*re)+.12*clamp(1.-dd/max(rr,.01),0.,1.));
  float wv=ring.x+ring.y,bst=ring.z;
  // the ocean lights up (rare, on some drops): a front of bioluminescence races outward and every light in the sea
  // blooms behind it (it rides the same glow terms as the drop), then slowly fades
  float dw=dg;
  // bass: bioluminescent waves (launched on bass onsets) roll up through the water as sinuous curtains of milky light
  // that light every plankton they pass, with a fading wake; they burn brighter with the bass
  vec2 bwp=vec2(dw2.y,sb.y);
  vec2 wy=vec2(p.y,dot(p,vec2(-.5,.866)))-mix(vec2(-.9,-1.2),vec2(1.3,1.5),bwp)-.13*sin(p.x*vec2(2.1,1.7)+abT*vec2(.3,-.25)+vec2(0.,2.))-.05*sin(p.x*vec2(5.3,4.1)-abT*.5);
  vec2 wg=(1.-bwp)*step(bwp,vec2(.99))*(exp(-wy*wy*45.)+.3*exp(wy*4.)*step(wy,vec2(0.)));
  float bwv=(wg.x+wg.y)*(.4+1.2*bass);

  /* water: the surface far above (a rippling ceiling of light seen in perspective) and the floor far below;
     zooming out brings both into view */
  vec2 pw=s*abG(4.);
  float gy=clamp(pw.y+.5,0.,1.);
  // v18: the water itself glows (broad palette-tinted bands of light), stronger when pulled back, on dark palettes
  // and with the bass, so no passage of the visit falls to black
  float pall=dot(abP0+abP1,vec3(.2126,.7152,.0722))*.5,pgn=1.+clamp(.5-pall,0.,.4)*3.,zb=1.-min(abZf,1.);
  float wbn=.5+.5*sin(pw.x*1.1+1.3*sin(pw.y*.9+abT*.06)+abT*.09);
  // v22: true deep-sea ink between the colours, one scheme per zone: ultramarine in the twilight, wine-violet at midnight,
  // black-teal over the vent garden with the glow of the vents rising from the floor
  vec3 wink=(zw.x*vec3(.01,.036,.2)+zw.y*vec3(.075,0.,.12)+zw.z*vec3(0.,.075,.095))*(1.1+.35*bass+.5*uB1.x);
  vec3 col=wc*(.3+.5*gy)+abP1*.03*dw
    +mix(abP1,vec3(.55,1.,.9),.15)*bwv*.1*(1.-ik)
    +wink*(.5+.7*smoothstep(-.9,.8,pw.y))+zw.z*vec3(.3,.06,0.)*smoothstep(.1,-1.1,pw.y)*(.6+.5*bass)
    +mix(abP0,abP1,wbn)*(.035+.02*bass+.015*calm)*(.45+.55*wbn)*(.55+.45*smoothstep(-.9,.7,pw.y))*(1.-.8*lo)*(1.-.8*ik);
  // v20: the water is deep colour, never black. Its hue follows the palette (teal through ultramarine to violet), lighter toward the
  // surface; ribbons of current are engraved in it as fine flowing contour lines, every fourth one heavier; the bass waves light
  // the lines they pass, the hats send glints along them
  float wh=.58+.13*sin(TAU*(mix(floor(pk.x),floor(pk.z),smoothstep(0.,2.2,bR))/4096.+hn+.2));
  vec3 wA=mix(abBow(wh),abP0,.5),wB=mix(abBow(wh+.14),abP1,.5);
  {
    // v22: the currents are no longer a wallpaper of parallel waves: they are the streamlines of the court, a whirlpool of spiral
    // arms turning under the leviathan (the small jellies ride the same arms, see the field layers)
    vec2 cvw=(s*gL-gp0+vec2(0.,1.15))*vec2(1.,1.8);float crw=length(cvw)*(1.-.45*burst),caw=atan(cvw.y,cvw.x),wnd=3.2+3.*gath;
    float aph=armK*caw-wnd*log(crw+.1)+spin*.3,f=aph*(4./TAU),fw=max(length(vec2(armK,wnd))/max(crw,.06)*gL*pxs*1.5*(4./TAU),1e-4);
    float rib=smoothstep(mix(.5,.8,gath),mix(.8,.97,gath),.5+.5*cos(aph))*smoothstep(3.6,2.4,crw)*smoothstep(.05,.3,crw);
    float l1=1.-smoothstep(.5,1.5,abs(fract(f*2.)-.5)/(fw*2.)),l4=1.-smoothstep(.9,2.1,abs(fract(f*.5)-.5)/(fw*.5));
    float gl=.5+.5*cos(caw*3.+crw*5.-abHP*TAU);gl*=gl;gl*=gl;gl*=gl;
    // v22b: the sub, the bass, the kick and the air band light the streamlines BETWEEN the arms too (the whole whirlpool answers, as line-work)
    float ribA=max(rib,min(.58*uB1.x+.3*uB1.y+.34*uB2.w+.14*uB2.z+.12*abHat+.8*pulse0,.95)*smoothstep(3.6,2.4,crw)*smoothstep(.05,.3,crw));
    // lead v22c: the lit streamlines keep their hue (peak capped, never a pale core) so loud passages stay colour on ink
    vec3 sl=mix(wA,wB,.5+.5*sin(f*.7))*(l1*.15+l4*.3)*(rib+2.*(ribA-rib))*(1.+2.5*gath+.6*burst)*(1.+5.*bwv+2.6*bass+4.6*uB1.x+2.2*pulse0+3.4*uB1.z+2.*uB1.w+1.5*uB2.w+11.*gl*(abHat+1.5*uB2.w+uB2.z)+36.*(1.-.5*burst)*kAmp*exp(-(crw-kT*2.6)*(crw-kT*2.6)*5.-kT))*smoothstep(1.,3.,1./(fw*2.));
    col+=sl*(.8/max(max(sl.r,max(sl.g,sl.b)),.8));
#if HD>=1
    // finer current lines between the engraved ones, more levels by tier, each faded in by its pixel spacing
    {float fs=8.;int nW=min(1+int(log2(max(uDetail,1.))),4);
     for(int wl=AB0;wl<nW;wl++){
       float sp=1./(fw*fs);if(sp<8.)break;
       col+=mix(wB,wA,.5+.5*sin(f*.7+float(wl)))*(1.-smoothstep(.4,1.3,abs(fract(f*fs)-.5)/(fw*fs)))*.065*rib*smoothstep(8.,18.,sp)*(1.+3.*bwv+2.*uB1.z+3.*gl*(abHat+1.5*uB2.w));
       fs*=4.;}}
#endif
  }
  {
    float up=step(0.,s.y),dist=mix(Hf,Hs,up)*abZf/max(abs(s.y),1e-3);
    vec2 w=vec2(s.x*dist/abZf+cam.x*3.,dist);
    float at=exp(-dist*mix(.4,.26,up));
    float v=sin(w.x*2.3+sin(w.y*1.9+abT*.5)+abT*.3)+sin(w.y*2.6+sin(w.x*1.4-abT*.4)-abT*.2);
    // crisp caustic lines about a pixel wide at any distance on luminous coloured sand
    float net=1.-smoothstep(.4,1.5,abs(v)/max(fwidth(v),1e-4));
    col+=at*(wc*mix(2.5,7.,up)+mix(mix(abP1,abP2,at)*(.14+.06*reef)+abP1*net*.27*(1.+2.*uB1.x+3.*uO1.x+2.*dg+4.*uB2.w+2.5*uB2.z+2.*abHat),
      vec3(0.),up));
    // light shafts from the surface
    vec2 dv=pw-vec2(.4*sin(abT*.031)-cam.x*.3,1.7),rs=.5+.5*sin(vec2(dv.x/(-dv.y))*vec2(31.,17.)+vec2(abT*.13,1.-abT*.09)),r2=rs*rs;
    col+=mix(wc*vec3(1.6,2.6,3.2),abP1*.1,.6)*(r2.x*r2.x*.6+r2.y*r2.y*r2.y)*smoothstep(-.7,.55,pw.y)*(.5+.6*calm+.4*bass+3.4*uB2.w+1.2*uB2.z+1.4*abHat)*.8*zw.x*(1.-lo)*(1.-ik)*smoothstep(.2,.5,zm);
  }
  /* a manta ray glides across at mid depth (a pass every ~23 s, alternating near and far) seen from below: swept
     wings that beat with the swim strokes (so on the kick), a luminous belly, chevrons of light behind the leading edge
     that a run sweeps along with the hats and the hi-mids set ablaze */
  {
    float pn=abT/23.2711+uSeed.z,mp=fract(pn),pi=floor(pn),fm=step(.5,fract(pi*.5)),zm=mix(1.9,3.4,fm),gm=abG(zm);
    float dr=step(.5,fract(pi*.618))*2.-1.,span=mix(.29,.18,fm)*(.9+.2*fract(pi*.37)),xr=asp*.5*gm+span*1.4;
    vec2 q=(s*gm+cam*.5/zm-vec2(dr*(mp*2.-1.)*xr,mix(.14,-.2,fm)+.25*(fract(pi*.71)-.5)+.07*sin(mp*TAU+fm*3.)))/span;
    if(dot(q,q)<1.6){
      q=rot(.3*dr+.5*.07*TAU/xr*cos(mp*TAU+fm*3.)+.1*sin(abT*.4+fm))*q;
      float aa=gm*pxs/span,fl=swim*1.5708+fm*2.+.4*sin(abT*.3),ax=abs(q.x)/(.8+.2*cos(fl)),y=q.y+.16*sin(fl)*ax*ax,ia=max(1.-ax,0.),a2=ax*ax*sqrt(ax);
      float d=min(max(max(y-.42+.62*a2,-.3+.1*ax+.55*ax*ia*ia-y),ax-1.)*.8,max(abs(q.x)-.01*(1.+2.*q.y),abs(q.y+.64)-.33));
      float m=clamp(.5-d/aa,0.,1.),v=y-.42+.62*a2,run=.5+.5*cos(v*7.*TAU*.25+abHP*TAU);
      vec3 c1=abP2*(1.+dg);
      col=col*(1.-.85*m)+(c1*(abLine(abs(d),.01,aa)*1.6+m*(.16+.3*ia*ia+.25*exp(-abs(q.x)*7.)))
        +mix(abP3,vec3(.8,.95,1.),.3)*(.5+run*(.6+2.*abHat)+1.8*uB2.x+2.5*uO2.x)*abLine(abs(fract(v*7.)-.5)/7.,.006,aa)*smoothstep(.98,.6,ax)*m)*(1.+.6*glow+2.*wv+bst);
    }
  }

  /* bioluminescent clouds: drifting swarms with dark water between; they set where the plankton gathers and tint it */
  vec2 hq=pw*1.4+vec2(abT*.012,abT*.007)-cam*.4;
  float n=.5+.5*sin(hq.x*2.1+sin(hq.y*1.7)*1.5)-.3*abs(sin(hq.y*1.3-hq.x*.5));
  float swarm=smoothstep(.62,.95,n);
  vec3 ct=mix(abP1,abP2,.5+.5*sin(hq.x*1.3-hq.y*.9));
  col+=ct*swarm*(.03+.04*bass)*(1.-.4*gy);
  /* the floor garden: three depth layers of kelp towers and, on reef visits, neon coral (sea fans and anemones)
     standing on the floor; kelp and coral sway with the low-mids, kelp leaves and coral ridges glow with the sub,
     anemone tips sparkle with the hi-mids */
  for(int l=0;l<3+abZ;l++){
    float lf=float(l),dz=4.6-1.3*lf,fd=.5+.25*lf;
    float g=(dz+abD)/abZf,kx=g*pxs;
    vec2 kp=s*g-cam*1.3/dz;
    float id=floor(kp.x/.75+.5),hk=h11(id*7.31+sdA*.01+lf*1.37);
    float v=kp.y+Hf;
    float cor=step(fract(hk*3.3),reef*.8);
    float H=(Hf+Hs)*(.3+.65*fract(hk*7.7))*mix(.45,1.,kelp),t=clamp(v/H,0.,1.);
    float ok=step(hk,mix(.22,.55,kelp))*step(v,H)*step(-.02,v)*(1.-cor);
    if(ok>.5){
      float x0=id*.75+(fract(hk*13.)-.5)*.34+(.1+.08*hk+.04*uB1.z)*sin(v*1.1-abT*.45+hk*6.)*t;
      // a stalk with leaves bulging out to alternating sides; the leaves glow with the sub
      float lv=fract(v/.24),leaf=lv*(1.-lv)*4.;leaf*=leaf;
      float k=abLine(abs(kp.x-x0-(mod(floor(v/.24),2.)*2.-1.)*.04*leaf),.01+.026*leaf*(1.-.5*t),kx);
      // a light run climbs every stalk on the kick
      float kr=(t-kT*1.7)*5.;
      col=col*(1.-k*.45)+fd*(1.+.6*glow)*mix(abP1*.4,abP3*(.15+.5*uB1.x+.7*uO1.x+.5*dw),leaf)*k*(1.+2.5*exp(-kr*kr)*kAmp);
    }
    // neon coral (sea fans and anemones); bands of light rise through each colony on the kick and each colony glows
    // with its own slice of the spectrum
    if(cor>.5&&v<.5&&v>-.05){
      float R=.22+.2*fract(hk*5.1),ex=kx/R,an=step(.5,fract(hk*17.3)),nr=3.+1.5*an;   // sea fan or anemone
      vec2 cq=(kp-vec2(id*.75+(fract(hk*13.)-.5)*.3,-Hf))/R;
      float r=length(cq),cy=cq.y+.5,a=cq.x/max(cy,.05)+(.05+.1*uB1.z)*sin(abT*.6+hk*6.)*r+an*.12*sin(r*7.-abT*2.5);
      float m=clamp(.5-max(r-1.,(abs(a)-1.5)*cy*.7)/ex,0.,1.),ra=abs(fract(a*nr)-.5)/nr*cy,cr=(r-kT*2.)*5.;
      col=col*(1.-.55*m)+m*fd*(1.+.6*glow+dg)*(mix(abP1,abP3,fract(hk*7.))*.08
        +mix(abP2,abP0,an)*abLine(min(min(ra,abs(fract(r*5.)-.5)*.2+an),1.-r),.028,ex)*(.42+.5*uB1.x+.8*uO1.x+1.3*uB2.w+.8*uB2.z+an*(1.5*uB2.x+2.*uO2.x)*step(.8,r)
          +2.2*exp(-cr*cr)*kAmp+1.3*spec(.06+.8*fract(hk*7.31))));
    }
  }
  /* plankton: three depth layers gathered in the clouds and tinted with them, and a lantern-fish school (3); the
     vortex twists them on builds; snare waves, onset bursts, the drop ring and the ocean light flash them */
  mat2 trm=rot(ball*(spin*.25+1.1/(bd+.25)));
  // the school moves as one body: a fish tornado that breathes with the bass, squeezes on the kick, startles outward
  // on the snare, with a flash wave rippling round it on presence onsets (tiled far apart for zooming out)
  vec2 sq=s*abG(2.2)-cam*.8,cid=floor(sq/vec2(3.3,2.5)+.5);
  float hs=h21(cid+sdA*.1);
  vec2 dq=sq-cid*vec2(3.3,2.5)-vec2(.3*sin(abT*.05+hs*6.),.1*sin(abT*.04+hs*4.));
  float sr=length(dq),sR=(.4+.1*hs)*(1.-.4*uBuild)*(1.+.25*bass-.12*pulse0+.7*sb.x);
  float ad=dq.y/(abs(dq.x)+abs(dq.y)+1e-4),an=(dq.x<0.?2.-ad:ad+4.*step(dq.y,0.))*.25;
  // formations: every 8 bars the school swirls from one shape into the next, the whole figure turning slowly; the
  // fish ride the outline
  // (rose curves r = 1 + A cos(k th) with k = 0 ring, 1 heart, 2 figure of eight, 3 trefoil, 4 four-leaf, 5 star,
  // 6 flower; A shrinks as k grows; th is the cheap diamond angle, which only bends the lobes a little)
  float th=(an-schPh*.0025+hs)*TAU;
  vec2 kk=vec2(floor(shc*.125),mod(shc,8.)),AA=.9*min(kk,1.)*pow(max(kk,1.),vec2(-.6));
  float Rr=sR*mix(1.+AA.x*cos(kk.x*th),1.+AA.y*cos(kk.y*th),smoothstep(0.,1.,sf.y));
  float sx=max(step(hs,mix(.55,.95,swimD)),step(dot(cid,cid),.5)),sw=smoothstep(.17,.08,abs(sr-Rr))*sx,sy=(sr-Rr)*14.;

  vec2 sp=vec2(an*TAU*sR-schPh/(sr+.15),sr-Rr);
  float fu=(fract(an-schF*1.6+.5)-.5)*7.,sfl=exp(-fu*fu-schF*1.2);
  // the formation glows as a ribbon of light, so its shape reads from afar
  col+=abP3*exp(-sy*sy*2.)*sx*(.05+.1*uB2.y+.25*sfl);
  float pB=min(.004+.16*swarm*swarm+.6*wv+1.2*front*bK+1.2*bst+.05*dg+.5*bwv,.8),pb=(.03+.06*swarm*(1.+bass))*(1.+abHat)+uB2.z*.12,pfl=wv*2.+front*bK*3.+bst*3.+dg*.15+bwv*2.5;
  // (v13: the lantern-fish school is drawn once after the plankton loop instead of as a branch-free fourth layer inside
  // it; loop bodies dominate the D3D compile)
  for(int l=0;l<3+abZ;l++){
    float lf=float(l),gl=abG(4.6-1.1*lf);
    // marine snow falls in slow winding streams (denser ribbons of light that glint with the highs and the hats)
    vec2 sl=s*gl;float st=smoothstep(.62,.97,.5+.5*sin(sl.x*1.6+1.2*sin(sl.y*.8+abT*.07+lf)+lf*2.1+abT*.05));
    vec2 k=abDots(trm*sl,30.-5.*lf,cam*(1.+lf)*1.5+vec2(0.,-abT*(.1+.05*lf)-dv*(9.+3.*lf)),lf*3.7+1.,gl*pxs,1.6-.3*lf,pB+.3*st,1.);
    vec3 pc=mix(ct,abP3,step(.85,k.y));
    // plankton (twinkling with the air band)
    col+=ct*st*(.008+.035*abHat+.025*uB2.z)+k.x*pc*(pb+hat*1.5*step(.8,k.y)+pfl*(1.+.4*lf)+st*(.05+(1.2*uB2.w+abHat)*step(.6,k.y)));
  }
#if HD>=1
  // v19: more depth layers of marine snow, deeper and finer than the base three, plus fine motes close to the lens
  {int nSn=min(int(1.+uDetail*.9),AB_SN);
   for(int l=AB0;l<nSn;l++){
     float lf=float(l),zl=mod(lf,3.)<2.?7.+3.2*lf:1.05+.12*lf,gl=abG(zl);
     vec2 sl=s*gl;
     vec2 k=abDots(trm*sl,44.+13.*lf,cam*(2.+lf)+vec2(0.,-abT*(.05+.02*lf)),lf*5.3+31.,gl*pxs,1.,.42+.3*swarm,1.);
     col+=k.x*mix(ct,abP3,step(.8,k.y))*(.16+.5*pb+hat*step(.9,k.y)+pfl*.5)*(.65+.35*sin(abT*.7+lf));
   }
  }
#endif
  // lantern fish: silver streaks with neon photophores that flash with the presence band and in the school's flash wave
  {vec2 k=abDots(sp,24.,vec2(0.),20.1,abG(2.2)*pxs,1.,.95,3.6);
   col+=k.x*mix(vec3(.6,.8,1.),abP3,.8)*(.8+3.*sfl+(1.2+2.*uB2.y+3.*uO2.y)*step(.85,fract(k.y*11.+schPh*.1)))*sw;}
  // the snare's wave front and the bursts themselves: faint rings of light rolling through the water
  col+=mix(abP1,vec3(.7,.9,1.),.5)*wv*.27+abP2*bst*.06;
  /* v20: siphonophore garlands. Colonies many body-lengths long wind through the water behind the jellies: a stem strung with
     swimming bells on alternating sides, a cluster of gonophores opposite each, and a fishing thread with a glowing lure under
     every node. They glide along their own curve in strokes with the kick; a bolt of light runs down the stem on each kick and the
     bells clench as it passes; the hats chase lights from bell to bell, the mids light the nuclei, the snare flashes the lures */
  {
#if HD>=1
    int nCh=min(2+int(uDetail*.55),AB_CH);
#else
    const int nCh=1;
#endif
    for(int ci=AB0;ci<nCh;ci++){
      float fc=float(ci),far=step(1.5,fc),zc=mix(6.-2.2*fc,5.+1.6*fc,far),gz=abG(zc),sc=mix(.55+.3*fc,.62-.12*fc,far),dir=1.-2.*mod(fc,2.),sdc=sdA*.37+fc*2.4,y0=mix(.2-.3*fc,1.26-.42*fc,far)+dwr*3.;
      vec2 pc=rot(.42-.2*fc)*(s*gz+cam*.5/zc)/sc;pc.x*=dir;
      float a1=pc.x*1.6+sdc+abT*.011,a2=pc.x*3.7+sdc*1.7-abT*.007,A1=.26,A2=.09;
      float F=A1*sin(a1)+A2*sin(a2)+y0,dF=A1*1.6*cos(a1)+A2*3.7*cos(a2),inv=inversesqrt(1.+dF*dF),dy=pc.y-F,dn=dy*inv;
      if(dy>.16||dy<-.75)continue;
      float W=.13,aa=gz*pxs/sc,sh=swim*1.2,u=(pc.x+dn*dF*inv)/W-sh,id=floor(u),sg=mod(id,2.)*2.-1.;
      vec2 l=vec2((fract(u)-.5)*W/inv,dn);
      float kp=(fract(id/24.)-kT*1.6)*7.,kw=exp(-kp*kp)*kAmp,chs=.5+.5*cos((id*.11-abHP)*TAU);chs*=chs;chs*=chs;chs*=chs;
      float ck=floor(id/3.)+fc;
      vec3 cA=abCol(ck),cB=abCol(ck+1.),cC=abCol(ck+2.);
      // the swimming bell (its own frame: +y away from the stem), its inner bell and nucleus; gonophores opposite; the stem
      vec2 lq=vec2(l.x,l.y*sg-.016),br=vec2(.044*(1.-.3*kw),.056*(1.+.15*kw));
      float dB=max(abEll(lq,br),-lq.y),inb=clamp(.5-dB/aa,0.,1.),rim=abLine(abs(dB),max(.0035,aa*.6),aa);
      float mer=abs(lq.x)/sqrt(max(1.-lq.y*lq.y/(br.y*br.y),.02)),in2=(abLine(abs(mer-br.x*.55),.002,aa)+abLine(abs(lq.x),.002,aa))*inb;
      float rb=abLine(abs(abEll(lq,br*.55)),.002,aa)*inb,nuc=abDot(length(vec2(l.x,l.y*sg-.006)),.0085,aa);
      float gon=abDot(length(vec2(abs(l.x)-.022,l.y*sg+.016)),.006,aa)+abDot(length(vec2(l.x,l.y*sg+.026)),.008,aa);
      float stem=abLine(abs(dn),.005,aa);
      // the fishing thread under each node hangs straight down, beads streaming along it, a lure at the tip
      float ix=floor(pc.x/W-sh),xn=(ix+.5+sh)*W,Fn=A1*sin(xn*1.6+sdc+abT*.011)+A2*sin(xn*3.7+sdc*1.7-abT*.007)+y0;
      float hx=h11(ix*.371+sdc),Lt=.12+.36*hx*hx,ty=Fn-pc.y,tm=step(0.,ty)*step(ty,Lt),tx=pc.x-xn-.012*sin(ty*26.-abTp*3.+ix)*ty/Lt;
      float thr=abLine(abs(tx),.0022,aa)*tm,tb=abDot(length(vec2(tx,(fract(ty/.03-abHP*2.-hx)-.5)*.03)),.0055,aa)*tm;
      float dl=length(vec2(tx,ty-Lt)),lure=abDot(dl,.009,aa)+.14*exp(-dl*140.);
      // v22: the colony pulses down its length with the bass line (a travelling wave of light, node after node)
      float bsw=.5+.5*cos(id*.42-abT*5.);bsw*=bsw;
      float lit=(1.+.6*glow+2.*wv+bst+dg)*(.62+.38*min(fc,1.))*(.6+.9*spec(.2+.25*fc))*(1.+bsw*(5.5*bass+3.2*uB1.x));
      col=col*(1.-.45*inb)+lit*(cA*(rim*(1.1+2.2*chs*abHat+2.5*kw)+inb*.1+(in2+rb)*(.55+2.2*uB2.x+1.2*uO2.x))+cB*(nuc*(1.2+2.*uB1.w+2.5*kw)+gon*(.9+1.5*uB1.z))
        +mix(cA,vec3(1.),.3*kw)*stem*(.7+3.*kw)+cC*(thr*.5+tb*(.8+1.6*abHat+2.*uB2.y))+cB*lure*(1.+3.*uB2.w+3.*wv+2.*abHat*chs));
    }
  }
  /* creatures, far to near: the far giant (a colossal lion's mane every ~105 s), three sparse field layers (cells of
     small jellies that fill the ocean to the horizon however far you zoom out; columns rise with the swim strokes),
     six mid-size jellies rising in pulses, then the second giant, the counterweight (usually the octopus) and the
     colossal hero jelly in front */
  // comb-jelly share per family: 0 jelly bloom, 1 giants' bloom (lion's manes), 2 comb carnival, 3 crystal drift,
  // 4 mixed, 5 reef, 6 open ocean (everything else is a bell jelly; a rare small octopus)
  vec4 TA=vec4(.9,.94,.45,.88);vec3 TB=vec3(.72,.8,.84);
  vec4 foA=vec4(equal(vec4(famA),vec4(0.,1.,2.,3.))),foB=vec4(equal(vec4(famB),vec4(0.,1.,2.,3.)));
  float thA=dot(TA,foA)+dot(TB,vec3(equal(vec3(famA),vec3(4.,5.,6.)))),thB=dot(TA,foB)+dot(TB,vec3(equal(vec3(famB),vec3(4.,5.,6.))));
  // loop invariants: hero / counterweight hover (the octopus jets upward when it inks), the giant's patrol
  float g15z=abG(.58);
  vec2 hp0=hero0+vec2(.04,.05)*(uVar.xy-.5)+vec2(0.,.06*pulse0*min(g15z,1.));
  vec2 cp0=(abUp(uM2[2].z)*2.-1.)*vec2(asp*.5,1.)+vec2(.06,.06)*(uVar.zw-.5)+vec2(0.,.06*pulse0*min(g15z,1.)+.2*octo*(1.-exp(-ink*2.))*exp(-ink*.35));

  float xs=.5*asp+.12;abPost=post;
  // the halos stay crisp through the drop and wave flashes (the creatures' gain below would turn them into haze)
  abHk=1.3/(1.3+2.6*wv+front*bK+bst+dg);
  // v22: two short rows of photophores on the leviathan's vault, in its own bell coordinates (the construction abCreature uses), drawn before
  // the creatures so everything nearer covers them: one lights for a second or two on a downbeat now and then, somewhere else each time
  // (mkT); one is always there, low on the dome, too small to read until the vault is pushed in on
  {float h0=fract(uSeed.z*.3093);h0*=h0+33.33;h0*=h0+h0;h0=fract(h0);
   vec2 lq=rot(-.032*sin(abT*(.07+.06*h0)+h0*9.))*(s*gL+cam*.0556-gp0)/1.08;
   float lbt=.5*(1.+.12*levP),ly=(lq.y+.12*(1.-.4*levP))/lbt,lwm=1.3*(1.-.2*levP)*(1.-.12*ly*ly);
   if(ly>0.&&ly<.45&&abs(lq.x)<lwm){
     float lsw=max(lwm*sqrt(1.-ly*ly),.05),lpf=asin(clamp(lq.x/lsw,-1.,1.)),laa=gL*pxs/1.08,ca=.16/60.*lsw/laa,cb=.1/60.*lsw/laa;
     vec2 ma=vec2((lpf-(fract(deal*.618)-.5)*1.5)/.16+.5,(ly-.13)/.05)*vec2(60.,7.),mb=vec2((lpf+.42)/.1+.5,(ly-.21)/.03)*vec2(60.,7.);
     float ina=step(abs(ma.y-3.5),3.5)*step(abs(ma.x-30.),30.),cq=mix(cb,ca,ina);vec2 mq=mix(mb,ma,ina);
     col+=mix(mix(abP1,mix(abP0,abP2,.5),zw.x),vec3(1.),.7)*abSeal(mq)*clamp(.5-(length(fract(mq)-.5)-.36)*cq,0.,1.)*smoothstep(1.1,1.9,cq)*mix(smoothstep(.0026,.0034,cb*pxs)*2.4,mkT*4.,ina);
   }}
#if HD>=1
  // v19: extra deep field layers of small jellies come first (furthest), then the usual thirteen
  int abXT=min(int(.5+uDetail*.75),AB_EX);
  for(int ii=-abXT+AB0;ii<13+abZ;ii++){
    if(uDetail<.75&&(ii==1||ii==4||ii==6))continue;
    float fi=float(ii),abDp=step(fi,-.5),gi=step(fi,.5)*(1.-abDp),fl=max(step(.5,fi)*step(fi,3.5),abDp),ind=1.-gi-fl;
#else
  for(int ii=0;ii<13+abZ;ii++){
    if(uDetail<.75&&(ii==1||ii==4||ii==6))continue;
    float fi=float(ii),gi=step(fi,.5),fl=step(.5,fi)*step(fi,3.5),ind=1.-gi-fl;
#endif
    float ckr=0.;
    float big=step(9.5,fi),hf=step(11.5,fi),cf=step(10.5,fi)-hf,co=big-cf-hf;
#if HD>=1
    float z=gi*9.+fl*mix(7.3-1.3*fi,8.+2.6*(-fi-1.),abDp)+ind*mix(mix(2.6,1.05,(fi-4.)*.2),.9-.16*(fi-10.),big),iz=1./z;
#else
    float z=gi*9.+fl*(7.3-1.3*fi)+ind*mix(mix(2.6,1.05,(fi-4.)*.2),.9-.16*(fi-10.),big),iz=1./z;
#endif
    float g=abG(z);
    vec2 pz=s*g+cam*iz*.5;
    vec4 hv=fract((fi*vec4(.618,1.31,2.17,.93)+uSeed*vec4(7.,5.,3.,9.))*.1031);hv*=hv+33.33;hv*=hv+hv;hv=fract(hv);
    vec2 pd;float vis,sz,hh=0.;
    if(fl>.5){
      // field layers: one small creature per cell (most cells empty); columns rise with the swim strokes
      vec2 WH=vec2(1.25*iz),hq=fract((floor(pz/WH)*vec2(.37,.71)+fi*vec2(7.1,3.3))*.1031);
      hq*=hq+33.33;hq*=hq+hq;hq=fract(hq);
      vec2 off=vec2(0.,(swim*(1.+floor(hq.x*3.))*.0625+dv*5.)*WH.y);
      vec2 cid=floor((pz-off)/WH);
      hh=h21(mod(cid,vec2(64.,256.))+fi*13.7+sdA*.1);
      sz=WH.y*.1*(.7+.3*fract(hh*7.))*(1.+.5*pulse0)*mix(1.,1.55,step(.86,fract(hh*23.)));
      pd=(cid+vec2(.5,0.))*WH+off+vec2((fract(hh*31.)-.5)*(WH.x-5.6*sz)*.8,WH.y-1.8*sz-fract(hh*17.)*max(WH.y-8.8*sz,0.));
#if HD>=1
      vis=step(hh,mix(.5+.3*(1.-min(abZf,1.))+.3*bloom,.16+.05*bloom,abDp));
#else
      vis=step(hh,.5+.3*(1.-min(abZf,1.))+.3*bloom);
#endif
      // v22: the court. The small jellies gather in spiral arms that turn under the leviathan's bell (a tilted disc, ink between
      // the arms); tension winds the arms tighter and narrower, an impact bursts them and they re-form with another number of arms
      {vec2 cv=(pd/g*gL-gp0+vec2(0.,1.15))*vec2(1.,1.8);float cr=length(cv)*(1.-.45*burst),ca=atan(cv.y,cv.x);
       float arm=.5+.5*cos(armK*ca-(3.2+3.*gath)*log(cr+.1)+spin*.3);
       float cm=smoothstep(mix(.5,.8,gath),mix(.8,.97,gath),arm)*smoothstep(3.4,2.3,cr)*smoothstep(.0,.25,cr);
       vis*=smoothstep(0.,.3,mix(cm,.55,burst)-fract(hh*91.3)*.7);
       // a ring of living light spreads outward through the court from every kick
       ckr=(1.-.5*burst)*kAmp*exp(-(cr-kT*2.6)*(cr-kT*2.6)*5.-kT);}
      hv.xzw=fract(hh*vec3(9.1,3.7,5.9));
    }else{
      // mid-size jellies: columns spread by the golden ratio, rising in pulses (their tentacles trail far below);
      // the second giant rises slowly behind; the counterweight and the hero hover where JS steers them; the far
      // giant patrols behind everything
      sz=mix(.115*iz*(.8+.4*hv.w),dot(vec3(co,cf,hf),vec3(.21,.21,.37))*(.9+.2*hv.w),big);
      float ph=fract(hv.y+swim*mix(2.+floor(hv.z*4.),1.,co)/64.);
      pd=vec2((fract(fi*.618034+uSeed.x)*2.-1.)*xs+.05*sin(abT*(.05+.05*hv.w)+hv.w*6.),-.5-2.6*sz+(1.+13.6*sz)*ph+.05*abH2*co+.07*abH2*(1.-big));
      vis=clamp(min(ph,1.-ph)*33.,0.,1.);
      pd=mix(mix(mix(pd,hp0,hf),cp0,cf),gp0,gi);vis=max(vis,hf+cf+gi);
      // v18 composition: the big creatures stop piling up in the middle. The hero keeps one side of the frame, the
      // octopus mirrors it, the second giant takes the far side lane, and the mid-size jellies rise in lanes across the
      // free water beside the hero; pulled back, every near creature keeps its place on screen instead of collapsing
      // to the centre. comp is 0 when folded (kaleidoscope), which keeps its own wedge layout
      {
        float isMid=ind*(1.-big)*(1.-gi),isCo=big-cf-hf;
        float spr=max(g,1.);
        float hs=hero0.x,hd=clamp(hs/.2,-1.,1.);
        float uu=fract(fi*.618034+uSeed.x+hv.w*.1);
        float xm=mix(hs-hd*.46,-hd*xs,uu)+.03*sin(abT*(.07+.05*hv.w)+hv.w*6.);
        float xg=-hd*.8+.03*sin(abT*.06+hv.z*5.);
        vec2 at=vec2(mix(mix(pd.x,xm,isMid),xg,isCo),pd.y);
        pd=mix(pd,at*mix(1.,spr,1.-gi),comp);
      }
      pd.y+=dwr*(.62*g+9.5*sz+.3)*(1.-gi);
    }
    // which ensemble: the wipe ring swaps species as it passes the creature's centre
    float useB=step(length(pd)*g15/g,bR),sd=mix(sdA,sdB,useB);
    vec4 fo=mix(foA,foB,useB);
    vec3 hc=fract((fi*vec3(5.3,7.9,3.7)+sd*vec3(23.1,3.3,11.)+hh*vec3(91.,53.,5.))*.1031);hc*=hc+33.33;hc*=hc+hc;hc=fract(hc);
    // type: comb jelly above the family's threshold, a rare small octopus among the mid-size ones; the hero is always a
    // bell jelly, the second giant too except in the comb carnival; the counterweight is the octopus when present
    float ty=step(mix(thA,thB,useB),hc.x)+step(.97,hc.x)*ind;
    ty=mix(mix(ty,fo.z*co,big-cf),2.*octo,cf)*(1.-gi);
    // bait-ball (builds): the mid-size jellies are drawn in toward the centre, where the plankton vortex spins
    // (v13: a plain pull instead of per-creature spiral seats and tilts, to pay for the zoom-in detail)
    float bi=clamp(ball*1.5-hv.x*.5,0.,1.)*ind*(1.-big);
    vec2 pos=pd*(1.-.42*bi*bi);
    vis=max(vis,bi*bi);
    // v18: the small crowd thins out where the hero's bell and tentacles are, so the hero reads alone
    {vec2 hsc=(pos/g-hp0/min(abG(.58),1.))*vec2(1.,.7);vis*=mix(1.,mix(.28,1.,smoothstep(.4,.8,dot(hsc,hsc)*2.5)),fl*comp);}
    vec3 tyo=vec3(equal(vec3(ty),vec3(0.,1.,2.)));
    float cs=mix(sz*dot(tyo,vec3(1.,.75,1.1)),1.08,gi);
    abLion=max((hf+co)*tyo.x*max(step(fract(sd*.37+co*.5),.3),fo.y),gi);
    abInk=mix(99.,ink,cf*octo);
    // early out: a conservative circle around the creature (tentacles hang far below; the octopus's ink spreads)
    vec2 dlt=pz-pos+vec2(0.,4.5*cs);
    if(vis<.002||dot(dlt,dlt)>cs*cs*(49.+12.*abLion+60.*step(abInk,12.)+40.*gi))continue;
    float tilt=mix(.08*sin(abT*(.07+.06*hv.z)+hv.z*9.)*(1.-.6*gi)+.3*(hv.z-.5)*pulse0*(1.-gi),htl,hf);
    vec2 q=rot(-tilt)*(pz-pos)/cs;
    // v22 dance deal: the bells contract in unison, or in canon (far to near, left to right, or as a ripple) by the visit's deal
    {float dly=dot(vec4(equal(vec4(mod(deal,4.)),vec4(0.,1.,2.,3.))),vec4(0.,.05*min(z,7.),clamp(pos.x/g+.9,0.,1.8)*.2,.3*hc.y)),kd=kT-dly*(1.-hf);
     abPulse=mix(max(kAmp*abPulseAt(kd),carry*exp(-4.5*kT)),levP,gi);abKT=mix(mix(kd,9.,step(kd,0.)),lvT*.45,gi);abRT=mix(abKT,kT,gi);}
    abLev=gi;abSoft=(1.-.9*lo)*(1.-.8*ik);
    abAA=g*pxs*(1.+.25*max(z-2.,0.)*(1.-gi))/cs;
    abSpin=(abT*(.1+.15*hv.w)+hv.x*6.)*(1.-.6*gi);
    vec4 c1=vec4(equal(vec4(floor(hc.z*4.)),vec4(0.,1.,2.,3.)));
    abC1=abPM*c1;abC2=abPM*mix(c1.wxyz,c1.zwxy,step(.5,fract(hc.z*7.)));abC3=abPM*c1.yzwx;
    // the leviathan wears the zone's contrast colours against its ink (magenta and amber in the twilight, cyan and violet at midnight, ember and teal over the garden)
    abC1=mix(abC1,abP0,gi);abC2=mix(abC2,abP2,gi);abC3=mix(abC3,mix(abP1,mix(abP0,abP2,.5),zw.x),gi);
    vec4 cr=abCreature(q,ty,hc.y);
    // spectrum by depth: near (big) creatures sing the bass, far (small) ones the treble; the giant hums with the sub
    float fz=smoothstep(1.,6.,z);
    // v22: the summed event gains pass a soft knee, so loud passages brighten the line-work without inflating the soft body fills into blobs
    float eg=(.45+1.1*spec(clamp(1.02-z*.14,.05,.82)))*(1.+.6*glow)*mix(1.,.55,fz*min(abZf,1.))*mix(1.,.7+.5*uB1.x+.5*uO1.x,gi)
      *(1.+(3.1*wv+front*bK+bst+.15*dg+.5*bwv*(1.-big))*(1.-.65*gi))*(1.+.35*big+big*(1.3*pulse0+.9*uB1.x+.6*uB1.y)+fl*(1.8*pulse0+11.*ckr+3.6*abHat*step(.5,fract(hh*5.+floor(abHP*2.)*.37))+bloom*(.6+3.*pulse0)+.7*uB1.x+.6*uO1.x+.7*uB2.y+.9*uB2.w+1.*uB1.z+1.6*gath))*(1.+.75*zb)*(1.+.6*(pgn-1.));
    vec3 e=cr.rgb*3.2*(1.-exp(-eg/3.2));
    // the leviathan's gain is its own and bounded (the sum of the event gains above would flood a frame-wide body with one colour)
    {float lx=.55*uB1.x+.45*uB1.y+.4*uO1.x+.15*glow+.1*dg+1.6*wv+.3*bst+.25*uB1.w+.4*uB2.x+2.5*pulse0;
     e=mix(e,cr.rgb*(.6+1.9*(1.-exp(-lx*.6))),gi);}
#if HD>=1
    e*=1.-abDp*(1.-.45*min(abZf,1.));
#endif
    // v22 lights out: waves of living light sweep from creature to creature (and along the leviathan), every one in its own colour
    // the leviathan is far: a majestic backdrop at the default view (the near creatures read in front of it), the subject when pulled back
    e*=1.-gi*(1.-min(mix(.34+.14*lo+.45*uB1.x+.2*uB1.y+.6*pulse0+.45*uB2.w+.3*abHat,.9,smoothstep(.8,.2,zm)),.95)*(1.-.35*zw.z));
    {vec2 wp2=mix(pos/g,s,max(gi,hf*.5));float sw1=.5+.5*cos(dot(wp2,vec2(5.,2.6))-abT*1.9+hc.x*1.5),sw2=.5+.5*cos(dot(wp2,vec2(-2.2,4.4))-abT*1.3);
     sw1*=sw1;sw1*=sw1;sw2*=sw2;sw2*=sw2;e*=1.+lo*(2.4*sw1+1.6*sw2+.3)*(1.-.5*gi);}
    // the leviathan's total gain (music x zoom x lights-out sweeps) passes one more knee: at a drop it brightens, it never floods the frame
    {float m1=max(max(e.r,e.g),e.b),mm=m1/max(max(max(cr.r,cr.g),cr.b),1e-4),k1=1.3*(1.-exp(-mm/1.3))/max(mm,1e-4),m2=m1*k1,k2=1.15*(1.-exp(-m2/1.15))/max(m2,1e-4);e*=mix(1.,k1*k2,gi);}
    col=col*(1.-min(cr.a*(1.+1.4*big),.92)*vis*mix(1.,.5,fz))+e*vis;
  }

#if HD>=1
  // v19: real volumetric light. March the view ray through the water: at each depth the light shafts are read at that depth's parallax, and each sample
  // sends a shadow test toward the surface against the hero's bell (the bell really blocks its shafts). Added as coloured light, limited, compressed below.
  {
    int nV=min(int(3.+uDetail*18.),AB_VOL);
    float vs=0.,vh=0.,jt=.5,vd=0.;int nOc=min(2+int(log2(max(uDetail,1.))),AB_OC),nLt=min(1+int(uDetail*1.4),AB_LT);
    float hgS=abG(.58);vec2 hc0=hp0/max(hgS,1e-3)*min(hgS,1.);float hR=.37*hgS;
    for(int v=AB0;v<nV;v++){
      float fv=(float(v)+jt)/float(nV),dz=mix(1.2,9.,fv*fv),gv=abG(dz);
      vec2 pv=s*gv-cam*.5/dz,dv=pv-vec2(.4*sin(abT*.031),2.1);
      vec2 rs=.5+.5*sin(vec2(dv.x/(-dv.y))*vec2(29.,13.)+vec2(abT*.11+dz*.05,1.-abT*.08-dz*.04));
      float sh=rs.x*rs.x*rs.x*.7+rs.y*rs.y*.5;
      sh*=smoothstep(-1.4,.9,pv.y)*exp(-dz*.13);
      // shadow ray: straight up from this sample in the bell's own plane; a bell above the sample blocks the shaft
      vec2 bv=s*hgS-hc0;float ax=bv.x/max(hR*1.15,.01);
      float blk=(1.-smoothstep(.75,1.15,abs(ax)))*smoothstep(-.02,.2,-bv.y)*smoothstep(.8,3.2,dz);
      vs+=sh*(1.-.72*blk);
      // the water itself: drifting turbid sheets marched at this depth, each lit by a short shadow ray climbing toward the surface
      {
        vec3 pv3=vec3(pv*1.5+vec2(abT*.02,-abT*.015),dz*.45+abT*.025);
        float den=0.,amp=.55,fq=1.;
        for(int o=AB0;o<nOc;o++){den+=amp*abVn(pv3*fq);fq*=2.03;amp*=.5;}
        den=smoothstep(.42,.86,den);
        if(den>.01){
          float od=0.;vec3 lp=pv3;
          for(int k=AB0;k<nLt;k++){lp+=vec3(.06,.26,.02);od+=abVn(lp*1.15);}
          float tr=exp(-1.5*od/float(nLt))*(1.-.6*blk);
          vd+=den*tr*exp(-dz*.09);
        }
      }
      vh+=sh*sin(dz*2.3-abT*.3)*.5;
    }
    float iv=1./float(nV);
    float vzf=smoothstep(.3,.95,abZf);
    {float vq=min(max(vs*iv-.17,0.)*2.6,.62)*vzf;col+=mix(abP1,abP2,.5+.5*vh*iv)*vq*vq*(.42+.55*calm+.45*bass+1.7*uB2.w)*.26*zw.x*(1.-lo);}
    {float vq=max(vd*iv-.12,0.)*3.*vzf;col+=mix(abP2,abP1,.5+.5*sin(abT*.07))*vq*vq*(.34+.5*bass+.35*calm+.7*uB2.w)*.09*(1.-.7*lo);}
  }
#endif
  // drop / phrase ring: a shock front of plankton light
  col+=mix(abP0,abP1,.5)*(front*(.04+.5*bK)+bK*bK*.2*smoothstep(bR,bR-.5,bd))*(1.-smoothstep(.8,2.4,bR));
  float vg=dot(s*vec2(.8,1.1),s*vec2(.8,1.1));
  col*=1.-.35*vg*sqrt(sqrt(vg));
  // overlapping neons are compressed along their own hue (never clipped to white), with a touch more chroma
  // v22b: at an impact the picture does not flash: it dips (ink darker round the lines), which also cancels the engine's own drop exposure
  col*=1./((1.+1.9*ik)*(1.+.55*uDrop*uDrop));
  float cm=max(max(col.r,col.g),col.b);col*=cm>1.?(1.+.4*(cm-1.))/cm:1.;
#if HD>=1
  fragColor=vec4(max(mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.32+.26*(abHz-1.)+.05+.01*float(HD)),0.),0.);
#else
  fragColor=vec4(max(mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,1.32+.26*(abHz-1.)),0.),0.);   // (v13: a touch more chroma pushed in)
#endif
}
`;
