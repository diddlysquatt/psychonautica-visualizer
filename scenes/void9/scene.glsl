const R_VOID9 = `
// VOID 9 v7. An endless stained-glass cathedral, and you are an ant in it. Colossal naves run in a grid (along z and
// along x) and meet at crossings every 8 bays; the blocks between them hold different rooms: pier forests of low
// aisles, void wells (cloister light-wells open through every level), rotundas (chapter houses round a central
// column, walled in glass) and rose-window walls. Crossings are lantern towers (an octagonal shaft through every
// level, with a well in each floor), domes on glazed drums, or plain groin crossings. The cathedral is stacked in
// levels, so the camera can turn left or right at a crossing, climb a lantern into the level above or dive a well
// into the level below, and it loops forever. Clerestory windows play the mids, the triforium galleries' tiny lamps
// the presence band, the transverse arches carry an equaliser of lamps (bass at the floor, treble at the apex).
// uP1 = (camera position, focal length)   uP2 = (yaw, pitch, roll, zoom-out 0..1)
// uP3 = (build growth, drop burst, snare wave age, kick light)  uP4 = (vault radius, arcade springing, vault springing, -)
// uP5 = (kick wave age, rose spin, glass light, level height)
// uM1 = palette colours 0..2, uM2 = palette colours 3..4 and (aisle vault ratio, route seed, rose petals).
float gTp,gYD,gGy0,gAA,gMat,gMaj,gAc,gQ,gBz,gVp,gY,gNave,gLev,gCt,gBt,gOct,gSA,gApex,gAt,gT0,gT1,gC0,gCy0,gPx,gRc,gRR;
vec2 gBl,gUv;
vec3 C0,C1,C2,C3,C4,gStn;
// D3D: loops start at a zero the HLSL compiler cannot fold, so it keeps them as real loops; de() has one call site.
#define V90 min(int(uTime),0)
#define vW 2.
#define vRV uP4.x
#define vYA uP4.y
#define vYS uP4.z
#define vLY 16.624903
// (v13) uP5.w: height of the zoom-out cut plane (everything above it is sliced away; 1e4 = none)
#define vCUT uP5.w
#define vKA uM2[2][0]
#define vSEED floor(mod(uM2[2][1],4.))
// (v18) fraction of uM2[2][1]: smoothed bass (attack 120 ms, release 400 ms), the only signal that moves geometry
#define vSMB fract(uM2[2][1])
#define vPET floor(uM2[2][1]*.25+.01)
// (v11) uM2[2][2]: air glow gain (sub and bass); floor(uP4.w)/60: blackout
float v9Sq(float x){return x*x;}
// integer modulo that is exact for float integers (the JS route mirrors it)
float v9Mod(float n,float m){return floor(mod(n+.5,m));}
float v9Band(float x){return max(spec(.03+.84*clamp(x,0.,1.)),1e-3);}
// (v11) level and onset of engine band b (0..7)
vec2 v9BO(float b){vec4 oh=vec4(equal(vec4(mod(b,4.)),vec4(0.,1.,2.,3.)));float hi=step(3.5,b);return vec2(dot(mix(uB1,uB2,hi),oh),dot(mix(uO1,uO2,hi),oh));}
// (v15) how far one band stands out of the mix: 1 at the average of the eight, up to about 2.6 when it is twice the
// average, small when it is quiet. The band levels are auto-ranged, so a raw level makes every bay light up together
// ("everything gets a little brighter"); this is what makes the nave play the spectrum instead.
float gBS,gSw;
float v9Rel(float lvl){return clamp(lvl*8./max(gBS,.25),0.,2.6);}
// full-spectrum rainbow (the arches' signature), its phase set per palette by JS (uP4.w), pulled a little toward the
// palette's deep glass so each visit keeps its own cast
vec3 v9Grad(float x){return mix(mix(C1,C4,smoothstep(0.,.5,x)),C3,smoothstep(.5,1.,x));}
// nave cross-section: straight walls up to the springing line ys, then a vault arc of radius r (r=w round, r>w pointed)
float v9Sec(float ax,float y,float w,float ys,float r){return mix(ax-w,length(vec2(ax+r-w,y-ys))-r,step(ys,y));}
// window/arcade opening: half width a, head springing y0, sill yb, head radius ratio k
float v9Arch(vec2 c,float a,float y0,float yb,float k){
  float ra=a*k;
  float box=max(abs(c.x)-a,max(yb-c.y,c.y-y0));
  float top=max(length(vec2(abs(c.x)+ra-a,c.y-y0))-ra,y0-c.y);
  return min(box,top);
}
float v9Oct(vec2 a){return max(max(a.x,a.y),(a.x+a.y)*.70711);}
// crossing type: 0 lantern (a shaft through every level), 1 dome, 2 plain. Lanterns must match void9Lantern in JS.
float v9Cross(vec2 cc,float lev){vec2 m=mod(cc,16.);return step(.5,v9Mod(m.x*5.+m.y*3.+vSEED,3.))*(1.+mod(m.x+m.y+lev,2.));}
// block type (the room inside the ring of aisles): 0 glazed core wall (aisle windows), 1 void well (through every
// level), 2 rotunda / chapter house, 3 rose-window walls closing the arcade, 4 open pier forest, 5 walls of glass
// (one huge window per bay from the dado to the vault, the commonest)
float v9Well(vec2 bb){vec2 m=mod(bb,16.);return step(v9Mod(m.x*7.+m.y*3.+vSEED,5.),.5);}
float v9Block(vec2 bb,float lev){
  vec2 m=mod(bb,16.);
  float h=v9Mod(m.x+m.y*2.+lev*3.+vSEED,9.);
  return mix(5.*step(h,3.5)+2.*step(4.5,h)*step(h,5.5)+3.*step(5.5,h)*step(h,6.5)+4.*step(6.5,h)*step(h,7.5),1.,step(v9Mod(m.x*7.+m.y*3.+vSEED,5.),.5));
}
// (v19) THE CITADEL. Level 0 is the top of the world: its naves are open courts under a psychedelic sky, the wall tops carry
// corbelled, crenellated parapets, and every block between them rises as a keep of stepped drums with a jewelled roof, corner
// bartizans and bridges thrown across the courts. Everything is built in the block's own coordinates (block half width 2,
// centred in an 8-unit cell), so nothing crosses a cell boundary except the bridges, whose two halves agree by edge id.
// Returns distance and piece: 8 parapet, 9 shaft, 10 gilt rim, 11 roof, 12 finial, 13 bridge.
float v9GK(float hb){return step(.83,fract(hb*31.7));}
float v9TH(float hb){return (2.4+2.6*fract(hb*13.7))*(1.+1.45*v9GK(hb))*(1.+.07*vSMB);}
float v9TR(float hb){return 1.12+.35*fract(hb*7.3)+.3*v9GK(hb);}
float v9TK(vec2 bl,vec2 a,float st){return mix(mix(max(a.x,a.y),v9Oct(a),step(.5,st)*step(st,1.5)),length(bl),step(st,.5)+step(1.5,st)*step(st,2.5));}
vec2 v9Top(vec2 bl,vec2 bb,float yt,float tw,float well){
  vec2 a=abs(bl);
  float cheb=max(a.x,a.y),uu=mix(bl.x,bl.y,step(a.y,a.x));
  float hb=h21(mod(bb,16.)+.37);
#if HD>=4
  // the art-print tiers: miniature keeps ring the bartizans (a castle on the castle)
  float micro=9.;
  { vec2 tcM=abs(bl)-1.84;float rM=length(tcM),ca2=atan(tcM.y,tcM.x);
    float cn=8.,sc=(fract(ca2*cn/TAU)-.5)*TAU/cn,y0=2.6+2.2*fract(hb*3.1);
    vec2 pm=vec2(rM*cos(sc),rM*sin(sc))-vec2(.34,0.);
    float rM2=length(pm),y2=yt-y0+.5;
    float tm=max(rM2-.055,max(-.25-y2,y2-.45));
    float ty2=clamp((y2-.45)/.4,0.,1.);
    micro=min(tm,max((rM2-.08*(1.-ty2))*.75,max(.45-y2,y2-.85)));
  }
#endif
  // the parapet: a corbelled walk that overhangs the court, toothed with merlons
  float cp=(fract(uu*2.+.25)-.5)*.5;
  float par=max(abs(cheb-2.07)-.15,abs(yt)-.3);
  par=min(par,max(max(abs(cheb-2.12)-.1,abs(cp)-.13),max(.2-yt,yt-.68)));
  float cf=(fract(uu*4.)-.5)*.25;
  par=min(par,max(max(abs(cf)-.055,cheb-2.-.22*clamp((yt+.72)/.44,0.,1.)),max(max(-.72-yt,yt+.28),1.95-cheb)));
  // corner bartizans, hung out over the court on cones
  vec2 tc=a-1.84;
  float rT=length(tc),tH=2.6+2.2*fract(hb*3.1);
  float bz=max(rT-.34,max(-.5-yt,yt-tH));
  bz=min(bz,max(rT-.34*clamp((yt+1.35)/.85,0.,1.),max(-1.35-yt,yt+.5)));
  float th=clamp((yt-tH)/1.7,0.,1.);
  float rf=max((rT-.47*(1.-th))*.72,max(tH-yt,yt-tH-1.7));
  float fn=max(rT-max(.016,tw),max(tH+1.6-yt,yt-tH-2.25));
  // the keep: three stepped drums, crenellated at every step, under a roof (cone, onion or pyramid)
  float st=floor(hb*4.),R0=v9TR(hb),Hs=v9TH(hb),rk=v9TK(bl,a,st);
  float ty=yt/Hs,k=clamp(floor(ty),0.,2.);
  float sh=max(rk-R0*(1.-.24*k),yt-(k+1.)*Hs);
  sh=min(sh,max(rk-R0*(1.-.24*max(k-1.,0.)),yt-k*Hs));
  float j=clamp(floor(ty),1.,3.),Rj=R0*(1.-.24*(j-1.)),yj=j*Hs,N=floor(Rj*14.),cr=(fract(atan(bl.y,bl.x)*N/TAU)-.5)*Rj*TAU/N;
  float rim=max(max(abs(rk-Rj-.02)-.09,max(yj-yt,yt-yj-.62)),-max(.11-abs(cr),yj+.32-yt));
#if HD>=1
  // (v20) real string courses: a rounded moulding stands out at every register of every drum
  sh-=.03*smoothstep(.12,.03,abs(fract(yt/.68+.5)-.5)*.68)*step(.1,yt);
#endif
#if HD>=2
  // real fluting of the drums (a ribbed shaft, not paint)
  sh+=.012*smoothstep(tw*3.,tw,.05)*(.5+.5*cos(atan(bl.y,bl.x)*N*2.));
#endif
#if HD>=1
  // pepper-pot turrets on every step of the keep (four, folded); at Insane and up a ring of pinnacles between them
  {
    vec2 q2=a-Rj*.7;
    float rq=length(q2),y2=yt-yj,t1=max(rq-.13,max(-.7-y2,y2-.85)),th2=clamp((y2-.85)/.75,0.,1.);
    t1=min(t1,max((rq-.2*(1.-th2))*.75,max(.85-y2,y2-1.6)));
    rim=min(rim,t1);
#if HD>=3
    float ca=(fract(atan(bl.y,bl.x)*N/(TAU*2.))-.5)*Rj*TAU*2./N,hp2=clamp((y2-.62)/.55,0.,1.);
    rim=min(rim,max((length(vec2(ca,rk-Rj-.02))-max(.04*(1.-hp2),tw*.6))*.8,max(.62-y2,y2-1.17)));
#endif
  }
#endif
  float y3=3.*Hs+.05,hr=R0*(1.9+1.6*fract(hb*5.7))*(1.+.3*vSMB),hh=clamp((yt-y3)/hr,0.,1.);
  float pr=mix(1.-hh,1.18*sin(PI*(.18+.82*pow(hh,.62))),step(.5,st)*step(st,1.5));
  float rk2=max((rk-.56*R0*pr)*.6,max(y3-yt,yt-y3-hr));
  float fy=y3+hr,lb=length(bl);
  float fk=min(max(lb-max(.022,tw),max(fy-.15-yt,yt-fy-1.3)),length(vec3(bl,yt-fy-.3))-.13);
  float wo=9.*well;
  sh+=wo;rim+=wo;rk2+=wo;fk+=wo;
  // bridges across the courts: a spoke from each block to the street's midline; both halves of a span share the edge's id
  float zk=1.-smoothstep(.5,.72,max(uP2.w,0.));
  vec2 dr=sign(bl)*vec2(step(a.y,a.x),1.-step(a.y,a.x));
  float eh=h21(mod(bb+max(dr,vec2(0.))+abs(dr)*.31,16.)+.91);
  float al=max(a.x,a.y),sd=min(a.x,a.y),yb=4.7+3.2*fract(eh*5.3),sp=al-2.;
  float yu=yb-.42-1.25*v9Sq(1.-clamp(sp*.5,0.,1.));
  float br=max(max(sd-.36*zk,max(yu-yt,yt-yb)),1.3-al)+9.*step(eh,.33)+9.*step(zk,.02);
#if HD>=1
  // crenellated rails along each bridge; a gatehouse turret where the span meets its block at Cinema and up
  float cq=(fract(al*2.)-.5)*.5;
  br=min(br,max(max(abs(sd-.3)-.05,abs(cq)-.14),max(yb-yt,yt-yb-.3))+9.*step(eh,.33)+9.*step(zk,.02));
#endif
#if HD>=2
  { float rg=length(vec2(sd,al-1.95));
    br=min(br,max(rg-.34,abs(yt-yb+.3)-.9)+9.*step(eh,.33)+9.*step(zk,.02));
    float tg2=clamp((yt-yb-.6)/.9,0.,1.);
    br=min(br,max((rg-.46*(1.-tg2))*.75,max(yb+.6-yt,yt-yb-1.5))+9.*step(eh,.33)+9.*step(zk,.02)); }
#endif
  // assemble: nearest piece wins; the piece id is computed without branches
#if HD>=4
  bz=min(bz,micro);
#endif
#if HD>=1
  // (v20) flying buttresses from the corner bartizans up to the keep, bowed like a drawn bow
  { float fu=(a.x+a.y)*.70711,fv=abs(a.x-a.y)*.70711;
    vec2 fA=vec2(2.42,1.5+tH*.22),fB=vec2(R0*.86,Hs*.8+.3),pa=vec2(fu,yt)-fA,ba=fB-fA;
    float fh=clamp(dot(pa,ba)/dot(ba,ba),0.,1.);pa.y-=2.*fh*(1.-fh)*(.35+.1*Hs);
    par=min(par,max(length(pa-ba*fh)-.075,fv-.075)*.8+wo); }
#endif
  // (v20) the spiral gallery: a walkway winding up one keep in two, a helter-skelter of lamps
  float hx=step(.5,fract(hb*11.3)),Pp=1.25+.5*fract(hb*21.),yw=mod(yt-atan(bl.y,bl.x)/TAU*Pp+Pp*.5,Pp)-Pp*.5;
  float Rc=R0*(1.-.24*k),hel=max(max(abs(rk-Rc-.06)-.1,abs(yw)-.05)*.85,max(.04-yt,yt-(k+1.)*Hs))+wo+9.*(1.-hx);
#if HD<1
  hel=9.;
#endif
  float d=min(min(par,bz),min(sh,min(rim,min(rf,min(rk2,min(fn,min(fk,min(br,hel))))))));
  float e=d+1e-5,id=8.;
  id=mix(id,9.,step(min(bz,sh),e));
  id=mix(id,10.,step(rim,e));
  id=mix(id,11.,step(min(rf,rk2),e));
  id=mix(id,12.,step(min(fn,fk),e));
  id=mix(id,13.,step(br,e));
  id=mix(id,16.,step(hel,e));
  return vec2(d,id);
}
#if HD>=1
// (v20) the sky fleet: spindle castles float over a third of the blocks, each kept inside its own block's column so no street is ever crossed.
vec2 v9Float(vec3 p,float yt,float tw){
  vec2 cl=floor((p.xz-4.)/16.),lo=p.xz-cl*16.-12.;
  float hf=h21(mod(cl,8.)+.71),r=length(lo),sc=.78+.26*fract(hf*9.1),h=yt-(13.+13.*fract(hf*17.3))-1.2*vSMB;
  // a cheap bounding column first: most samples are far from every floater
  float bnd=max(r-2.5,max(h-8.,-11.-h))+9.*step(hf,.56);
  if(bnd>.6)return vec2(bnd,17.);
  float j=floor(h/.8),Rj=2.25*sc*pow(clamp(1.+(j+1.)/(8.*sc),0.,1.),.72),Rk=2.25*sc*pow(clamp(1.+(j+2.)/(8.*sc),0.,1.),.72);
  float hu=max(min(max(r-Rj,abs(h-(j+.5)*.8)-.4),max(r-Rk,abs(h-(j+1.5)*.8)-.4)),max(h,-8.*sc-h));
  float dr=max(r-1.35*sc,max(-h,h-3.4));
  float cr=max(abs(r-1.42*sc)-.09,max(.0-h,h-.4));cr=min(cr,max(abs(r-1.42*sc)-.09,abs(h-3.5)-.14));
  float tt=clamp((h-3.5)/3.,0.,1.),rf=max((r-1.75*sc*sin(PI*(.16+.84*pow(tt,.62))))*.6,max(3.5-h,h-6.5));
  float fi=min(max(r-max(.03,tw),max(6.4-h,h-7.9)),length(vec3(lo,h-6.9))-.16);
  fi=min(fi,max(r-max(.04,tw),max(-8.*sc-2.2-h,h+8.*sc)));
  fi=min(fi,length(vec3(lo,h+8.*sc+2.2))-.24);
  float bd=min(hu,dr),d=min(min(bd,cr),min(rf,fi))+9.*step(hf,.56),e=d+1e-5;
  float id=17.;
  id=mix(id,10.,step(cr+9.*step(hf,.56),e));
  id=mix(id,18.,step(rf+9.*step(hf,.56),e));
  id=mix(id,12.,step(fi+9.*step(hf,.56),e));
  return vec2(d*.9,id);
}
#endif
float de(vec3 p){
  float Ly=vLY,lv=min(floor(p.y/Ly),0.),y=p.y-lv*Ly,lev=mod(lv,8.),top=step(-.5,lv);
  vec2 cc=floor(p.xz*.125+.5),uv=p.xz-cc*8.,a2=abs(uv);
  vec2 bb=floor(p.xz*.125),bl=p.xz-bb*8.-4.;
  // nave frame: distance across the nearest nave, bays counted from the crossing edge
  float ac=min(a2.x,a2.y),q=max(a2.x,a2.y)-vW,s=ac-vW,K=vRV/vW;
  // pixel footprint here: thin mouldings never get thinner than about two pixels, so far silhouettes stay unbroken
  float tw=length(p-uP1.xyz)*gPx,tw9=.9*tw;
  float ct=v9Cross(cc,lev),bt=v9Block(bb,lev),oc=v9Oct(a2);
  // room masks (branch-free: every shape is computed and switched off with a large offset)
  float mRose=step(2.5,bt)*step(bt,3.5),mGlass=step(4.5,bt),mArc=1.-mRose-mGlass,mRot=step(1.5,bt)*step(bt,2.5),mWell=step(.5,bt)*step(bt,1.5);
  float mLan=step(ct,.5),mDome=step(.5,ct)*step(ct,1.5);
  // (v19) the top level has no vault: its naves are open courts
  float nave=mix(v9Sec(ac,y,vW,vYS,vRV),ac-vW,top);
  // aisles: pointed groin vaults over a unit grid of piers (a glazed core wall closes them in blocks of type 0)
  vec2 f=abs(fract(bl)-.5);float ra=.5*vKA,yy=max(y-vYA,0.),vp=fract(q)-.5,cheb=max(abs(bl.x),abs(bl.y));
  float ais=max(min(length(vec2(f.x+ra-.5,yy)),length(vec2(f.y+ra-.5,yy)))-ra,step(bt,.5)*(1.-cheb)-9.*step(.5,bt));
  // elevation: arcade, a triforium gallery of three openings per bay, a splayed clerestory window
  float tri=max(v9Arch(vec2((fract(q*3.)-.5)/3.,y-gT0),.136,gT1-gT0-.32,0.,1.25),s-.4);
  // (walls of glass use the same splayed embrasure, from the dado to the vault)
  float cle=max(v9Arch(vec2(vp,y),mix(.4,.42,mGlass),mix(gCy0,gGy0,mGlass),mix(gC0,.5,mGlass),K)+.35*max(s,0.),s-mix(.16,.22,mGlass));
  // rose-window walls: a shallow recess behind the piers from the floor to the vault
  float rsw=max(y-vYS+.3,s-.25);
  float A=min(nave,min(min(min(ais,tri)+9.*(1.-mArc),cle+9.*(1.-mArc-mGlass)),rsw+9.*(1.-mRose)));
  // round rooms: a rotunda in its block, or a dome on a drum over its crossing
  float rd=length(vec2(length(mix(uv,bl,mRot)),max(y-mix(gApex+.3,vYS-.4,mRot),0.)))-mix(1.75,1.45,mRot);
  A=min(A,rd+9.*(1.-max(mRot,mDome)));
  // the camera level's floor is not in the field: the march meets it as an exact plane (the mirror bounce)
  A=max(A,-y-9.*step(abs(lv-min(floor(uP1.y/Ly),0.)),.5));
  // (v19) above the wall tops of the top level there is only sky
  A=min(A,gYD-y+1e3*(1.-top));
  // lantern shafts and void wells pass through every level; domes rise over their crossings
  A=min(A,min(oc-1.55+9.*(1.-mLan),cheb-.85+9.*(1.-mWell)));
  float wall=-A;
  // colossal clustered piers on the grid (none inside the wells; a rotunda keeps only its central column)
  vec2 gi=clamp(floor(bl+.5),-2.,2.),g=bl-gi;
  float lg=length(g),ag=min(abs(g.x),abs(g.y)),bg=max(abs(g.x),abs(g.y));
  float mi=max(abs(gi.x),abs(gi.y)),rm=mWell*step(mi,.5)+mRot*step(.5,mi)*step(mi,1.5);
  // above the arcade capitals a pier continues only as a slender vaulting shaft up the nave wall
  float pr=max(mix(mix(.1,.26,mRot*step(mi,.5)),mix(.13,.075,mGlass+mRose),step(1.5,mi))*mix(1.,.55,step(vYA,y)),tw9);
  float pier=min(lg-pr,length(vec2(ag,bg-pr))-pr*.38);
  pier=min(pier,max(lg-pr-.06,min(abs(y-vYA+.04),abs(y-vYS+.04))-.045));
  pier=min(pier,max(lg-pr-.07,y-.16))+9.*rm;
  pier=max(pier,top*(y-gYD+.02)-(1.-top));
  // balustrades round the wells in every floor
  pier=min(pier,max(min(abs(oc-1.62)+9.*(1.-mLan),abs(cheb-.92)+9.*(1.-mWell))-.06,y-.22));
  // transverse archivolts at every bay boundary in two stepped orders (the crossing arches are heavier)
  float bn=max(floor(q+.5),0.),bz=q-bn,maj=step(bn,.5),sc=1.+.4*maj,tz=1.+.5*maj;
  float rib=min(max(abs(bz)-max(.12*tz,tw9),-(nave+.12*sc)),max(abs(bz)-max(.07*tz,tw9),-(nave+.28*sc)));
  rib=max(rib,max(nave-.01,vYS-.08-y));
  rib=max(rib,top*(y-gYD+.3)-(1.-top));
  // diagonal and ridge ribs of the vault (the crossing's diagonals run corner to corner); none across shafts and domes
  float sv=clamp((y-vYS)/max(gApex-vYS,.01),0.,1.);
  float dg=mix(abs(abs(vp)-.5*(1.-sv))*.75,abs(a2.x-a2.y)*.7071,step(q,0.));
  float vr=max(max(min(dg,ac)-max(.05,tw9),abs(nave+.05)-.06),vYS-y);
  vr=max(vr,mLan*(1.6-oc)+mDome*(1.8-length(uv))-(1.-mLan-mDome))+9.*top;
  // arcade archivolts: a gilt moulding with lamps round every arch of the nave arcade
  float aA=length(vec2(abs(vp)-.5+ra,yy))-ra;
  float arc=max(max(abs(aA-.045)-max(.045,tw9),abs(s+.015)-.055),vYA-.02-y)+9.*(1.-mArc*step(.05,q));
  rib=min(rib,arc);
  // (v15) coronas: a gilt wheel of jewel lamps hangs from the vault down the middle of every second bay, with a pendant
  // jewel beneath it and a fine chain up to the crown. It is the realm's only structure in the air, so a nave reads as a
  // vaulted volume with depth instead of as a tube of rings, and it gives the high and air bands a surface of their own.
  // (the wheel is 0.72 across, so it needs the two-bay window: one corona every two bays)
  float cq=(q-.5+gSw)*.5,cqd=abs(cq-floor(cq+.5))*2.,cR=length(vec2(ac,cqd)),cY=gApex-1.15-.35*vSMB;
  float cor=length(vec2(cR-.72-.2*vSMB,y-cY))-.024;                 // the wheel
  cor=min(cor,length(vec2(cR,y-cY+.62))-.075);             // the pendant jewel under it
  cor=min(cor,max(cR-.034,cY-y));                          // the chain up into the vault
  cor=min(cor,length(vec2(cR,y-cY-.34))-.1);               // the crown it hangs from
  cor+=9.*step(q,.02)+9.*top;                                     // naves only (not over a crossing or a well)
  // (v18) banners hang in front of the arcade every second bay; they sway with the smoothed bass only
  float bbq=fract(q*.5)-.5,by1=gT0-.1;
  float ban=max(max(abs(s+.28)-.008,abs(bbq)-.17),max(y-by1,by1-1.75-.45*vSMB-y))+9.*step(q,.02);
  // (v19) portcullises hang raised in the great halls' crossing arches, and slam a little lower on every kick (smoothed bass only)
  float pyy=vYS+.85-.6*vSMB,pdx=abs(fract(ac/.36+.5)-.5)*.36-.024,pdy=abs(fract((y-pyy)/.5+.5)-.5)*.5-.024;
  float por=max(max(min(pdx,pdy),pyy-y),max(abs(bz)-.05,nave));
  por=min(por,max(max(pdx+.024*smoothstep(pyy,pyy-.3,y),pyy-.3-y),max(max(abs(bz)-.05,y-pyy),nave)));
  por+=9.*(top+1.-maj);
  // (v19) the citadel above the wall tops
  vec2 tT=v9Top(bl,bb,y-gYD,tw9,mWell);
#if HD>=1
  { vec2 tF2=v9Float(p,y-gYD,tw9);tT=mix(tT,tF2,step(tF2.x,tT.x)); }
#endif
  tT.x+=9.*(1.-top);
  float d0=min(min(wall,rib),min(pier,vr)),d=min(d0,min(cor,min(ban,min(por,tT.x))));
  // material id without branches: 0 wall, 1 transverse arch, 2 pier, 3 vault rib, 4 arcade arch, 5 tunnel arch,
  // 6 corona (added by the same arithmetic: nearest surface wins)
  float dd=d+1e-5;
  gMat=mix(mix(3.*step(vr,dd),2.,step(pier,dd)),1.+3.*step(arc,dd),step(rib,dd));
  gMat=mix(gMat,6.,step(cor,d0));
  gMat=mix(gMat,7.,step(ban,min(d0,cor)));
  gMat=mix(gMat,14.,step(por,min(min(d0,cor),ban)));
  gMat=mix(gMat,tT.y,step(tT.x,min(min(d0,cor),min(ban,por))));
  // (v13) zoomed far out a horizontal cut slices the building open (a cutaway seen from above)
  return max(d,p.y-vCUT)*.8;
}
// the frame quantities of a point, recomputed once at the hit (writing them inside de() would keep a dozen values
// alive across the march loop, which the D3D compiler pays for dearly)
void v9Frame(vec3 p){
  float lv=min(floor(p.y/vLY),0.);gY=p.y-lv*vLY;gLev=v9Mod(lv,8.);gTp=step(-.5,lv);
  vec2 cc=floor(p.xz*.125+.5);gUv=p.xz-cc*8.;vec2 a2=abs(gUv),bb=floor(p.xz*.125);gBl=p.xz-bb*8.-4.;
  gAc=min(a2.x,a2.y);gQ=max(a2.x,a2.y)-vW;
  gCt=v9Cross(cc,gLev);gBt=v9Block(bb,gLev);gOct=v9Oct(a2);
  gNave=mix(v9Sec(gAc,gY,vW,vYS,vRV),gAc-vW,gTp);
  gVp=fract(gQ)-.5;gBz=gQ-max(floor(gQ+.5),0.);gMaj=1.+.4*step(max(floor(gQ+.5),0.),.5);
  float ra=.5*vKA;gAA=length(vec2(abs(gVp)-.5+ra,max(gY-vYA,0.)))-ra;
}
float v9Lead(float e,float px,float lw){return smoothstep(lw+px,max(lw-px,0.),e);}
// polar glass (rose windows, medallions, oculi): a flower centre, a ring of pointed petals, a ring of roundels and
// a scalloped rim. The rings play the spectrum from band b0 (centre) to b1 (rim).
vec3 v9Rose(vec2 c,float R,float px,float N,float b0,float b1,float ang,float seed){
  float r=length(c)/R,an=atan(c.y,c.x)+ang;
  float sec=TAU/N,ai=floor(an/sec+.5),af=an-ai*sec;
  vec2 pc=vec2(cos(af),sin(af))*r;
  // centre flower, ring of petals, ring of roundels and scalloped rim, selected without branches
  float z0=step(r,.17),z2=step(.58,r),z1=1.-z0-z2;
  float pd=(length(vec2(pc.y/(sec*.16),(pc.x-.37)/.17))-1.)*.13;
  float o=step(.83,r),cl=length(pc-vec2(mix(.705,1.,o),0.)),cd=cl-mix(.095,.13,o);
  // (v20) the ground behind the tracery is a mosaic of small wedge tiles, never a flat field; petals are two-toned with a midrib; roundels ringed
  float rN=15.,ri2=floor(r*rN),sN=max(floor(ri2*5.3),6.),sx=an/TAU*sN,si=floor(sx),th=h21(vec2(ri2,mod(si,sN))+seed);
  float mL=smoothstep(.5,.16,px/(R/rN));
  vec3 mos=mix(C0*.75+C3*.25,mix(mix(mix(C0,C3*.9,step(.34,th)),C1*.85,step(.58,th)),C4*.85,step(.8,th)),mL);
  vec3 ptc=mix(C4,C1,step(mod(ai,2.),.5)),ptc2=mix(C1,C3,step(mod(ai,2.),.5));
  vec3 pet=mix(mix(ptc,ptc2,smoothstep(.0,-.05,pd)),C2,smoothstep(.012,.006,abs(pc.y))*step(pd,-.03));
  vec3 rnd=mix(mix(C1,C3,step(cl,.075)),C2,step(cl,.04));
  vec3 col=z0*mix(C2,C4,step(r,.08))+z1*mix(mos,pet,step(pd,0.))
          +z2*mix(mix(mos*.85,rnd,step(cd,0.)),mix(C1,C2,step(cd,0.)),o);
  col=mix(col,mix(C0,C1,.35+.3*step(.5,fract(seed*.37))),smoothstep(.05,.14,px/R));
  float mEr=min(fract(r*rN),1.-fract(r*rN))/rN,mEa=min(fract(sx),1.-fract(sx))*r*TAU/sN,mE=mix(1.,min(mEr,mEa)+.0035,mL);
  float bgd=z1*step(0.,pd)+z2*(1.-o)*step(0.,cd);
  float e=z0*min(abs(r-.08),.17-r)+z1*min(min(abs(pd),min(r-.17,.58-r)),(sec*.5-abs(af))*r)
         +z2*min(min(abs(cd),abs(cl-.075)+step(0.,cd)),min(r-mix(.58,.83,o),mix(.83,1.,o)-r));
  e=min(e,mix(1.,mE,bgd));
  float f=z0*.05+z1*(.12+.6*(r-.17))+z2*mix(.5+.9*(r-.58),.95,o),pid=mix(ai+N*o*z2,-1.,z0);
  float lvl=v9Band(mix(b0,b1,f));
#if HD>=1
  { float mN=N*(HD>=3?12.:6.),mPx=px/max(r*R*TAU/mN,1e-4),mL=smoothstep(.5,.15,mPx);
    float mA=abs(fract(an*mN/TAU)-.5)*2.;
    col*=mix(1.,.72+.56*smoothstep(.15,.6,mA),mL);
    col+=C2*.12*mL*smoothstep(.88,1.,mA)*step(.17,r); }
#endif
  return col*((.35+2.2*lvl*sqrt(lvl))*(.8+.4*h11(pid*.37+floor(r*6.)+seed)))*(1.-v9Lead(e*R,px,min(.006,R*.02))*smoothstep(.2,.06,px/R))*step(r,1.);
}
// stained glass: twin lancets of stacked medallions under an oculus, lattice glass around them and in the head.
// c = (along the wall, height). Medallion rows are a spectrum column: bass at the sill, treble at the head.
// rose > .5: the whole opening is one rose window of radius a centred on c = 0.
vec3 v9Glass(vec2 c,float a,float y0,float yb,float K,float px,float seed,float rose){
  float hh=a*sqrt(max(2.*K-1.,.2));
  float la=a*.5-.014;
  vec2 l=vec2(abs(c.x)-a*.5,c.y);
  float y0l=y0-hh*.22;
  float inL=v9Arch(l,la,y0l,yb,K);
  float Lm=la*2.35,k=floor((c.y-yb)/Lm),nR=max(floor((y0l-yb)/Lm),1.);
  vec2 mv=vec2(l.x,c.y-yb-(k+.5)*Lm);
  float mr=la*.8,dm=length(mv)-mr;
  vec2 pc=mv;float pR=mr,pN=8.,b0=k/nR,b1=(k+1.)/nR,pa=h11(k+seed)*6.28;
  float polar=smoothstep(px,-px,dm)*step(k,nR-.5)*smoothstep(px,-px,inL);
  if(rose>.5){pc=c;pR=a;pN=vPET;b0=0.;b1=1.;pa=uP5.y*(2.*step(1.,mod(seed,2.))-1.);polar=1.;}
  vec3 pol=v9Rose(pc,pR,px,pN,b0,b1,pa,seed);
  // diamond lattice: in the lights around the medallions, and finer in the spandrels of the head
  float sp=step(0.,inL),cs=la*mix(.62,.36,sp);
  vec2 g=vec2(l.x+c.y,c.y-l.x)/cs;
  vec2 gi=floor(g),gf=fract(g)-.5;
  float hs=h21(gi+seed+sp*7.);
  vec3 col=mix(mix(mix(mix(C3,C1,step(.3,hs)),C4,step(.55,hs)),C0,step(.63,hs)),C0*.37+C1*.25+C3*.3+C4*.08,smoothstep(.3,.8,px/cs));
  float e=min(.5-abs(gf.x),.5-abs(gf.y))*cs*.7071;
  e=mix(e,1.,smoothstep(.25,.6,px/cs));
  e=min(e,abs(inL));
  e=min(e,abs(dm)+step(.5,sp)+step(nR,k));
#if HD>=1
  // finer tesserae inside each diamond and a tiny lead between them, gated on the pixel footprint
  { float cf=cs/3.,fL=smoothstep(.85,.28,px/cf);
    vec2 g3=g*3.,gi3=floor(g3),gf3=fract(g3)-.5;
    float h3=h21(gi3+seed*5.);
    col=mix(col,mix(col*(.62+.8*h3),v9Grad(fract(h3*3.+seed*.2)),.28*step(.6,h3))+C2*.1*step(.84,h3),fL);
    float e3=min(.5-abs(gf3.x),.5-abs(gf3.y))*cf*.7071;
    e=mix(e,min(e,e3+.008),fL);
#if HD>=3
    { float cf2=cf/3.,fL2=smoothstep(.45,.15,px/cf2);vec2 g9=g3*3.,gf9=fract(g9)-.5;
      col*=mix(1.,.82+.36*h21(floor(g9)+seed*3.),fL2);
      e=mix(e,min(e,min(.5-abs(gf9.x),.5-abs(gf9.y))*cf2*.7071+.004),fL2); }
#endif
  }
#endif
  float br=(.55+.25*mix(hs,.5,smoothstep(.3,.8,px/cs))+.35*v9Band((k+.5)/nR))*mix(1.,.6,sp)*mix(.8+.4*h11(hs*26.7+seed*1.9),1.,smoothstep(.3,.8,px/cs));
  return mix(col*br*(1.-v9Lead(e,px,.006)),pol,polar);
}
// (v18) coursed ashlar: x = tone of this block (0..1), y = mortar joint; both fade to their average before they can shimmer
vec2 v9Ash(vec2 u,float px){
  float cw=.085,r=floor(u.y/cw),xo=u.x/.17+.5*mod(r,2.);
  vec2 f=vec2(fract(xo)-.5,fract(u.y/cw)-.5);
  float e=min((.5-abs(f.x))*.17,(.5-abs(f.y))*cw),lod=smoothstep(.02,.006,px);
#if HD>=1
  float fL=smoothstep(.006,.0018,px),nh=h21(floor(u*vec2(53.,91.))+vec2(floor(xo),r));
  return vec2(mix(.5,h21(vec2(floor(xo),r)),lod)+(nh-.5)*.3*fL,smoothstep(.006+px,.0015,e)*lod);
#else
  return vec2(mix(.5,h21(vec2(floor(xo),r)),lod),smoothstep(.006+px,.0015,e)*lod);
#endif
}
// (v19) the sky over the citadel: marbled ribbons of the palette, a horizon glow, four flower-shaped halos of spectrum rings
// (one down each street heading, so every vista ends in one), and two layers of impossibly far castle silhouettes.
#if HD>=1
#define V9NS (3+HD)
#else
#define V9NS 1
#endif
vec3 v9Pk(float m){return mix(mix(mix(mix(C0,C3,step(1.,m)),C1,step(2.,m)),mix(C0,C3,.5),step(3.,m)),C4,step(4.,m));}
vec3 v9Sky(vec3 rd,float snF){
  float az=atan(rd.x,rd.z),el=rd.y,tw=uTime*.05;
  float sa1=az*3.+tw*2.,sa2=az*2.-el*4.-tw*3.,sb1=el*7.+az*2.+tw*4.,sA=el*6.+2.*sin(sa1)+1.3*sin(sa2),sB=az*5.+el*9.+tw*2.+sin(sb1);
  float v=.5+.25*(sin(sA)+sin(sB)),sce=max(sqrt(max(1.-el*el,0.)),.06);
  vec2 sgr=.25*(cos(sA)*vec2(6.*cos(sa1)+2.6*cos(sa2),6.-5.2*cos(sa2))+cos(sB)*vec2(5.+2.*cos(sb1),9.+7.*cos(sb1)));
#if HD>=1
  v+=.05*sin(az*11.+el*23.+tw*6.+3.*v)+.022*sin(az*19.-el*37.+tw*9.+6.*v);
#endif
  // (v20) a poster sky: crisp marbled bands of the whole palette, each shaded across its width and edged in a hairline, fine combing inside them
  float fv=v*11.,bi=floor(fv),bf=fv-bi,dw=max(12.5*gPx*length(sgr*vec2(1./sce,sce)),1e-3),bm=mod(bi,5.);
  vec3 bc=v9Pk(bm);
  vec3 sky=bc*bc*(.28+.95*bf*bf);
  float cmb=abs(fract(fv*5.)-.5)*2.;
  sky*=1.-.4*smoothstep(.5,.0,dw*5.)*smoothstep(.3+dw*5.,.08,cmb);
  sky=mix(sky,C2*C2*1.1+.02,smoothstep(dw*1.6,dw*.3,min(bf,1.-bf))*smoothstep(.5,.15,dw));
  sky=mix(sky,C0*.42+C3*.2+C1*.05,exp(-abs(el)*7.)*.7);
  sky*=mix(1.,.55,smoothstep(.15,.95,el));
  // the halos: rings of light that play the spectrum outward
  float a4=mod(az+PI*.25,PI*.5)-PI*.25,e2=el-.24,r=length(vec2(a4,e2));
  float ang=atan(e2,a4);
  float kw=uP5.x;
  float rr=r*(1.+.1*cos(ang*vPET+uP5.y*3.))-.18*kw*exp(-kw*3.);
  float ri=floor(rr*11.),rf=abs(fract(rr*11.)-.5)*2.;
  float lvl=v9Band(ri/8.),mR=smoothstep(.72,.3,r);
  vec3 rg=v9Grad(fract(ri*.17+.5));
  float raw=max(26.*gPx,.012),rsg=(fract(ang*(ri+3.)*2./TAU)-.5)*2.,rbk=smoothstep(.0,.08,abs(rsg)-.1);
  sky=mix(sky,rg*rg*(.5+.95*lvl*sqrt(lvl)+snF*.5*mod(ri,2.))*mix(.55,1.1,rbk),smoothstep(.8+raw,.8-raw,rf)*mR*(.3+.6*min(lvl*2.,1.)));
  sky=mix(sky,C2*C2*1.1+.02,smoothstep(.07+raw,.07,abs(rf-.8))*mR*smoothstep(.2,.05,raw)*.8);
  // a shock ring runs out from each halo on every kick
  sky+=C4*exp(-v9Sq((r-kw*1.1)*8.))*exp(-kw*2.2)*.8;
  { float ja=az*14.3239,ji=floor(ja),jx=abs(fract(ja)-.5),jy=abs(bf-.5),jd=jx*1.25+jy*1.9-.5,jw=max(dw*1.9,18.*gPx/max(sqrt(max(1.-el*el,0.)),.05))+1e-4;
    float jh=h21(vec2(mod(ji,90.),mod(bi,64.)+7.)),jv=smoothstep(.32,.1,jw)*smoothstep(.97,.8,abs(el));
    float jm=mod(bm+2.+floor(jh*2.),5.);vec3 jc=v9Pk(jm);
    float jin=smoothstep(jw,-jw,jd),jed=smoothstep(.07+jw,.07,abs(jd)),jst=smoothstep(.1+jw,.1-jw,jx*1.25+jy*1.9);
    sky=mix(sky,jc*jc*(.5+.9*(jx+jy))+.02,jin*jv*.92);
    sky=mix(sky,C2*C2*1.15+.03,max(jed,jst*jin)*jv);
    sky+=jc*jin*jv*step(.6,jh)*(1.1*uHat+.8*uB2.w+1.2*uO2.w+.5*snF);
#if HD>=1
    { float jf=smoothstep(.2,.06,jw);
      sky=mix(sky,C2*C2*1.1+.03,smoothstep(.05+jw,.03,abs(jd+.27))*jin*jv*jf*.85);
      sky=mix(sky,sky*.55,smoothstep(.03+jw,.0,min(jx,jy)*1.5)*jin*jv*jf*step(jd,-.3));
      float jp=length(vec2((.5-jx)*1.25,jy*1.9))-.085;
      sky=mix(sky,C2*1.1+.1,smoothstep(jw,-jw,jp)*jv*jf); }
#endif
  }
  // stars and glints high up, on the hats
  vec2 sg=vec2(az*14.3239,el*26.),si=floor(sg);
  float sh=h21(vec2(mod(si.x,90.),si.y));
  float sd=length(fract(sg)-.5-.3*(vec2(fract(sh*7.),fract(sh*13.))-.5));
  sky+=(C2+.3)*smoothstep(.09,.0,sd)*step(.8,sh)*smoothstep(.05,.45,el)*(.2+1.3*uB2.w+1.8*uO2.w*step(.92,sh)+2.2*uHat*step(.84,sh));
  // the far citadels, nearest last: each layer is a skyline of towers against the glow
  for(int i=V90;i<V9NS;i++){
    float fi=float(V9NS-1-i),M=84.+fi*46.,x=az/TAU*M,id=floor(x+.5),fx=x-id,hs=h21(vec2(mod(id,M)+fi*3.1,fi+.7));
    float ht=(.018+.1*hs*hs*hs+.025*fract(hs*5.))*1.5/(1.+.55*fi),wd=.14+.14*fract(hs*9.),ch=.03+.08*fract(hs*17.);
    float pr=TAU/M,pa=max(gPx,.0015);
    float sh2=max(abs(fx)*pr-wd*pr,el-ht);
    float co=max(abs(fx)*pr-wd*pr*(1.-clamp((el-ht)/ch,0.,1.)),max(ht-el,el-ht-ch));
    float wl=el-.025-.008*step(.5,fract(x*7.))-.015/(1.+fi);
    float dd=min(min(sh2,co),wl);
    float mk=smoothstep(pa,-pa,dd)*smoothstep(-.14,-.01,el);
    vec3 lc=mix(C0*.08+C1*.05+.01,C0*.3+C3*.24,clamp(fi*.35,0.,1.))*(1.+.8*uB1.y);
    mk*=mix(1.,.6,clamp(fi*.3,0.,1.));
    float wn=step(sh2,0.)*step(.4,fract(el*(110.+fi*50.)))*step(.45,fract(x*9.));
    lc+=mix(C4,C2,fract(hs*11.))*wn*(.15+1.3*spec(fract(hs*3.3+fi*.3)*.84+.03))*smoothstep(.003,.0012,pa);
    sky=mix(sky,lc,mk);
  }
  return sky;
}
#if HD>=2
// (v19) a cheap shading of what a reflection ray lands on: enough colour and light to read as the real building in the gilt
vec3 v9RC(vec3 p,vec3 n,float m,vec3 sunD,vec3 rr,float hit,float snF){
  if(hit<.5)return v9Sky(rr,snF);
  float kd=max(dot(n,sunD),0.)*.8+.25+.25*n.y,top=step(-1.5,p.y);
  vec3 a=gStn*.5,e=vec3(0.);
  if(all(bvec2(m>7.5,m<13.5))){
    if(m<8.5)a=gStn*.55;
    else if(m<9.5)a=v9Grad(fract(p.y*.17+dot(p.xz,vec2(.07,.11))));
    else if(m<10.5){a=C2*.85;e=C2*.2;}
    else if(m<11.5){a=v9Grad(fract(p.y*.31));e=a*.12;}
    else if(m<12.5){a=C2;e=C2*.4;}
    else a=gStn*.5;
  }else if(abs(m-7.)<.5){a=v9Grad(fract(p.y*.2));e=a*.1;}
  else if(m>14.5)a=v9Grad(fract(dot(p.xz,vec2(.13,.07))))*.7;
  return a*(kd*(C2*.5+C4*.35+.35)+(C0*.3+C1*.15)*.6*(.6+.4*n.y))*(1.+.2*top)+e;
}
#endif
void v9Scene(vec2 p){
  C0=uM1[0];C1=uM1[1];C2=uM1[2];C3=uM2[0];C4=uM2[1];gStn=mix(vec3(.62,.48,.42),C2,.34);
  gBS=dot(uB1,vec4(1.))+dot(uB2,vec4(1.));gSw=0.;
  float K=vRV/vW,Ly=vLY;
  gSA=vYS+vRV*acos(clamp((vRV-vW)/vRV,-1.,1.));
  gApex=vYS+sqrt(max(vRV*vRV-v9Sq(vRV-vW),0.));
  gAt=vYA+sqrt(max(.5*vKA-.25,0.));
  gT0=gAt+.25;gT1=gT0+.85;gC0=gT1+.3;gCy0=vYS-.12-.4*sqrt(2.*K-1.);
  gRR=min(1.85,(vYS-.3-gAt)*.5);gRc=vYS-.4-gRR;gGy0=vYS-.15-.42*sqrt(2.*K-1.);gYD=vYS+1.45;
  float pw4=floor(uP4.w),grow=uP3.x,burst=uP3.y,zo=max(uP2.w,0.),zi=max(-uP2.w,0.),bk=.45*mod(pw4,64.)/60.,eK=mod(floor(pw4/64.),4.),eA=floor(pw4/256.)/31.;
  float e1=step(abs(eK-1.),.1)*eA,e2=step(abs(eK-2.),.1)*eA,e3=step(abs(eK-3.),.1)*eA;   // (v12) set pieces
  vec3 ro=uP1.xyz;
  float yaw=uP2.x,pit=uP2.y,fov=uP1.w;
  vec3 ww=vec3(cos(pit)*sin(yaw),sin(pit),cos(pit)*cos(yaw));
  vec3 uu=vec3(-cos(yaw),0.,sin(yaw)),vv=cross(uu,ww);
  uu=uu*cos(uP2.z)+vv*sin(uP2.z);vv=cross(uu,ww);
  vec2 lp=p+uLook*vec2(.5,.35);
  vec3 rd=normalize(lp.x*uu+lp.y*vv+fov*ww);
  vec3 rd0=rd,ro0=ro;
  gPx=1./(uRes.y*fov);
  float detail=clamp(uDetail,.5,16.);
  float flY=min(floor(ro.y/Ly),0.)*Ly;
  float tF=rd.y<-1e-4?(flY-ro.y)/rd.y:1e9,tF0=1e9;
  {
    // the polished floor of the camera's level is a mirror, except over the wells
    vec3 fp=ro+rd*min(tF,1e3);vec2 fu=fp.xz-floor(fp.xz*.125+.5)*8.,fb=fp.xz-floor(fp.xz*.125)*8.-4.;
    float lv0=v9Mod(floor(fp.y/Ly+.5),8.);
    if(step(v9Oct(abs(fu)),1.55)*step(v9Cross(floor(fp.xz*.125+.5),lv0),.5)
      +step(max(abs(fb.x),abs(fb.y)),.85)*v9Well(floor(fp.xz*.125))+step(vCUT-.01,flY)>.5)tF=1e9;
  }
  float t=.02+.1*h21(gl_FragCoord.xy),tTot=0.,bounce=0.,hit=0.,mode=0.,tk=0.,e=1e-4;
  vec3 hp=vec3(0.),fpos=vec3(0.),n=vec3(0.,1.,0.),nacc=vec3(0.);
  float ao1=1.,hT=0.;
  float tmax=(55.+12.*sqrt(detail))*(1.+1.2*zo),stepN=100.+60.*detail+80.*zo;
  vec3 sunD=normalize(vec3(.42,.72,.55));
#if HD>=1
  // (v19) the detail range. One loop, one de() call site, so the extra rays cost almost nothing to compile: after the hit the same
  // loop runs a real shadow ray (mode 2), a ladder of occlusion taps (mode 3) and, at Cinema and up, a reflection ray with its own normal (modes 4, 5).
  float vEnd=38.,mHit=0.,sres=1.,t2=.02,ns=0.,acc=0.,hk=0.,rHit=0.,rt=.03,rMat=0.,nSh=float(32+HD*28),nAO=float(6+HD*3),nRf=float(HD>=2?HD*44:0),nV=float(HD>=5?90:(HD>=3?HD*12:8+HD*6)),nVm=float(HD>=4?12:(HD>=2?6:3)),vk=0.,vm=0.,vs=0.,vl=1.,vol=0.;
  vec3 shO=vec3(0.),shD=sunD,rO=vec3(0.),rR=vec3(0.,1.,0.),rPos=vec3(0.),rN=vec3(0.,1.,0.),rNa=vec3(0.);
#endif
#if HD>=1
  for(int i=V90;i<9000;i++){
#else
  for(int i=V90;i<1200;i++){
#endif
    // after the hit the same loop takes the four tetrahedral normal taps, one AO tap and the hit point itself (so the
    // material id is the hit's)
    vec3 tv=vec3(1.-2.*abs(mod(tk,2.)-step(1.5,tk)),2.*step(1.5,tk)-1.,2.*mod(tk,2.)-1.);
#if HD>=1
    if(float(i)>=stepN+1e5*step(.5,mode))break;
    vec3 qq0=mix(hp+mix(e*tv,n*.2*step(tk,4.5),step(3.5,tk)),ro+rd*t,step(mode,.5));
    if(mode>1.5){
      if(mode<2.5)qq0=shO+shD*t2;
      else if(mode<3.5)qq0=hp+n*(.05*pow(1.75,hk));
#if HD>=2
      else if(mode<4.5)qq0=rO+rR*rt;
      else if(mode<5.5)qq0=rPos+e*tv*step(tk,3.5);
#endif
      else qq0=ro0+rd0*vs+sunD*(.25+.55*vm*vm);
    }
    float d=de(qq0);
#else
    if(float(i)>=stepN+1e4*mode)break;
    float d=de(mix(ro+rd*t,hp+mix(e*tv,n*.2*step(tk,4.5),step(3.5,tk)),mode));
#endif
    if(mode<.5){
      float tt=tTot+t,thr=max(gPx*tt*.8/sqrt(detail),2e-5);
      // the camera level's floor is a mirror: when it is the nearest surface, bounce instead of hitting it
      if(all(bvec3(bounce<.5,tF<1e8,(tF-t)*(-rd.y)*.8<d+thr+1e-3)))t=tF;
      else if(d<min(thr+1e3*step(stepN-1.,float(i)),max(thr,.3))){
        hit=1.;mode=1.;hp=ro+rd*t;hT=tt;
        e=max(gPx*hT*.6,1e-4);continue;
      }
      else t+=min(d,4.);
      if(all(bvec2(t>=tF,bounce<.5))){bounce=1.;fpos=ro+rd*tF;tF0=tF;tTot=tF;ro=fpos;rd.y=-rd.y;t=max(gPx*tF*.7/sqrt(detail),2e-5)/max(rd.y,.015);tF=1e9;continue;}
#if HD>=1
      if(any(bvec2(tTot+t>tmax,t>(22.+30.*zo)*bounce+1e3*(1.-bounce)))){
        vEnd=mix(min(38.,tF0),min(tF0,mix(tmax,hT,hit)),.0)+.001;
        mode=6.;vk=0.;vm=0.;vl=1.;vs=h21(gl_FragCoord.xy*1.13)*vEnd/nV;continue;
      }
#else
      if(any(bvec2(tTot+t>tmax,t>(22.+30.*zo)*bounce+1e3*(1.-bounce))))break;
#endif
    }else{
#if HD>=1
      if(mode>1.5){
        if(mode<2.5){
          // the shadow ray: soft by the closest approach, hard when it lands
          sres=min(sres,10.*d/max(t2,.04));
          t2+=clamp(d,.035,2.8);ns+=1.;
          if(d<.0015){sres=0.;ns=nSh;}
          if(any(bvec2(ns>=nSh,t2>26.))){mode=3.;hk=0.;continue;}
          continue;
        }
        if(mode<3.5){
          float ha=.05*pow(1.75,hk);
          acc+=max(0.,(ha-d)/ha)*pow(.72,hk);
          hk+=1.;
          if(hk>=nAO){
#if HD>=2
            mode=4.;rO=hp+n*max(3.*e,.012);rR=reflect(rd,n);rt=.03;ns=0.;
#else
            mode=6.;vk=0.;vm=0.;vl=1.;vs=(h21(gl_FragCoord.xy*1.13)+.0)*vEnd/nV;
#endif
          }
          continue;
        }
#if HD>=2
        if(mode<4.5){
          float tr=max(gPx*(hT+rt)*.9,3e-4);
          if(d<tr){rHit=1.;rPos=rO+rR*rt;mode=5.;tk=0.;rNa=vec3(0.);continue;}
          rt+=min(d*.92,4.);ns+=1.;
          if(any(bvec2(ns>=nRf,rt>48.))){mode=6.;vk=0.;vm=0.;vl=1.;vs=(h21(gl_FragCoord.xy*1.13)+.0)*vEnd/nV;continue;}
          continue;
        }
        if(mode<5.5){
          rNa+=tv*d*step(tk,3.5);
          if(tk>3.5){rMat=gMat;rN=normalize(rNa+vec3(0.,1e-9,0.));mode=6.;vk=0.;vm=0.;vl=1.;vs=(h21(gl_FragCoord.xy*1.13)+.0)*vEnd/nV;continue;}
          tk+=1.;
          continue;
        }
#endif
        // volumetric light: samples along the view ray, each testing the way to the sun, so real shafts fall between the towers
        vl=min(vl,clamp(d/.18,0.,1.));
        vm+=1.;
        if(vm>=nVm){
          vol+=vl;vk+=1.;vm=0.;vl=1.;vs+=vEnd/nV;
          if(vk>=nV)break;
        }
        continue;
      }
#endif
      nacc+=tv*d*step(tk,3.5);n=normalize(nacc+vec3(0.,1e-9,0.));
      ao1=mix(ao1,clamp(d/.2,0.,1.),step(3.5,tk)*step(tk,4.5));
#if HD>=1
      if(tk>4.5){
        // the shadow ray goes to the sun on the open top level, to the nearest bay chandelier in the great halls
        mHit=gMat;
        vec2 hc0=floor(hp.xz*.125+.5),hu=hp.xz-hc0*8.;
        float flv=min(floor(hp.y/vLY),0.),topH=step(-.5,flv);
        vec3 tgt=mix(vec3(floor(hp.x)+.5,flv*vLY+gApex-1.2,hc0.y*8.),vec3(hc0.x*8.,flv*vLY+gApex-1.2,floor(hp.z)+.5),step(abs(hu.x),abs(hu.y)));
        shO=hp+n*max(4.*e,.012);
        shD=normalize(mix(tgt-shO,sunD,topH));
        vEnd=min(min(hT,tF0),38.)+.001;
        t2=.02;sres=1.;ns=0.;mode=2.;continue;
      }
#else
      if(tk>4.5)break;
#endif
      tk+=1.;
    }
  }
#if HD>=1
  if(hit>.5)gMat=mHit;
  ao1=min(ao1,clamp(1.-.32*acc,0.,1.));
#endif
  v9Frame(hp);
  float y=gY,ac=gAc,q=gQ,s=ac-vW,bt=gBt,ct=gCt,vp=gVp;
  vec3 pos=hp;
  // seen in the mirror floor at a grazing angle a pixel covers far more surface: fade fine detail accordingly
  float pxw=hT*gPx*mix(1.,clamp(.2/max(abs(rd0.y),.01),1.,12.),bounce)*inversesqrt(max(abs(dot(n,rd)),.04));
  float relz=length(pos-ro0);
  // aerial perspective: palette haze, thicker low down, brighter looking up toward the lanterns and the vault
  float hzU=smoothstep(-.3,.9,rd0.y);
  // ... and a glow of light far down the nave ahead, where the arches dissolve
  float hg=v9Sq(v9Sq(v9Sq(max(dot(rd0,normalize(vec3(ww.x,1e-3,ww.z))),0.))))*(1.-.8*smoothstep(.8,.95,zo));
  vec3 haze=(C0*(mix(.13,.28,hzU)*clamp(.35/max(dot(C0,vec3(.2126,.7152,.0722)),.05),1.,2.2))+.006+mix(C4,C0,.3)*.3*hg*hg*(.35+.65*smoothstep(-.06,.01,rd0.y))*(1.+.8*uB1.x))*(1.+.6*burst)*(1.-.4*bk);
  haze*=1.-.3*smoothstep(.7,.95,zo);
  float ext=smoothstep(-1.5,.5,mix(ro0.y,hp.y,hit));
  float snF0=exp(-uP3.z*1.8);
  if(ext>.001)haze=mix(haze,v9Sky(rd,snF0),ext);
  vec3 col=haze;
  // highs, kick and snare brighten the open sky itself, never the fog
  if(hit<.5)col=col*(1.+ext*min(.45*snF0+.32*uP3.w+.26*uB2.z+.22*uB2.w+.34*uB1.z+.3*uB2.x,.72))+ext*(C1*uB1.w+C3*uB2.y)*.12;
  // a lower level's floor seen down a well, or (v13) the cut face of the zoomed-out cutaway: both shade as floor
  float sfl=hit*step(.5,n.y)*max(step(gMat,.5)*step(y,.015+gPx*hT),step(vCUT-.04-2.*gPx*hT,hp.y));
  float hw=exp(-v9Sq(relz-.6-uP3.z*9.)*.5)*exp(-uP3.z*.6);   // snare wave of light running away from the camera
  float pf=pxw;   // pixel footprint used by the moulding and star patterns
  if(hit*(1.-sfl)>.5){
    float ao=.25+.75*ao1;
    float na=mix(abs(n.x),abs(n.z),step(abs(gUv.x),abs(gUv.y)));
    // windows, one arch test and one glass call for all: clerestory twin lancets, one towering window per bay in the
    // walls of glass, a great rose on the rose-window walls
    float mR=step(2.5,bt)*step(bt,3.5),mG=step(4.5,bt);
    vec2 rc=vec2(q-2.,y-gRc);
    float rose=mR*step(length(rc),gRR)*step(.2,s)*step(-.01,q);
    float isW=(1.-mR)*step(mix(.14,.2,mG),s)*step(mix(gC0-.1,.45,mG),y)*step(y,vYS);
    float ga=mix(mix(.344,.343,mG),gRR,rose),gy0=mix(gCy0,gGy0,mG),gyb=mix(gC0+.056,.577,mG);
    vec2 gc=mix(vec2(vp,y),rc,rose);
    float gsd=mix(floor(q)*1.7+(2.+6.*mG)*3.1+gLev*.7+step(0.,gUv.x-gUv.y)*.5,floor(gBl.x*.1)+floor(gBl.y*.1)*3.,rose);
    float wd=mix(v9Arch(gc,ga+.01,gy0,gyb-.01,K),length(rc)-gRR,rose);
    // glass only on the faces that look into the nave, never smeared along the splayed sides of an embrasure
    float gw=step(gMat,.5)*min(isW+rose,1.)*smoothstep(pxw,-pxw,wd)*smoothstep(.5,.3,na);
    vec3 gE=vec3(0.);
    if(gw>.001)gE=v9Glass(gc,ga,gy0,gyb,K,pxw,gsd,rose);
    vec3 lc=ro0+ww*.3-pos;float lcd=length(lc);
    float d2=max(dot(n,lc/lcd),0.)/(1.+lcd*lcd*.5);
    vec3 rf=reflect(rd,n);
    float fres=v9Sq(v9Sq(1.-max(dot(n,-rd),0.)));
    vec3 amb=(C0*1.7+C1*.8+C3*.5)*(.15+.08*uP5.z)*(1.35-.35*gTp)+.012;
    // the glass light: surfaces facing up and inward catch the coloured glow of the windows
    vec3 sky=(C0*.8+C4*.4)*(.42+.2*uB1.w);
    // little window light reaches back into the aisles: the arcade reads in front of a darker depth
    float deep=exp(-max(s,0.)*.9*step(y,gAt+.3));
    // the camera carries a soft lantern tinted like the gilt and the light, never white
    vec3 light=(amb*ao+sky*ao*(.5+.5*n.y))*deep+(C2*.6+C4*.4+.15)*d2*.6;
    // (v18) the window light: every bay's glass throws its own colour onto the stone and plays that bay's band (bass to air
    // along the nave). Large and smooth, so it can be strong without shimmer; this is what the stone is seen by.
    float kf=.8+uP5.x*14.,nK=exp(-v9Sq((relz-kf)*.32))*exp(-uP5.x*1.3)*2.4,nearK=nK+exp(-relz*.3)*uP3.w*.5;
    float snF=exp(-uP3.z*1.8);   // (v18b) the snare's own envelope (light only)
    float bayW=floor(mix(pos.z,pos.x,step(abs(gUv.y),abs(gUv.x)))+.5);
    vec2 bA=v9BO(mod(bayW,8.));
    vec3 wc=v9Grad(fract(bayW/12.+gLev*.21));
    float kFill=smoothstep(kf+2.,kf-1.,relz)*exp(-uP5.x*2.2)*(.25+.75*mod(bayW,2.));
    vec3 wsh=wc*(.3+.9*v9Rel(bA.x)+.8*bA.y)*(.35+.65*smoothstep(1.,vYS,y))*ao*deep*.34;
    float keyS=1.;
#if HD>=1
    keyS=mix(.08,1.35,clamp(sres,0.,1.));
#endif
    light+=wsh+(C2*.5+C4*.25+.12)*v9Sq(max(dot(n,sunD),0.))*ao*deep*.75*keyS;
    // headroom: kick and snare light is strong on dim stone and gentle on stone the mix has already lit, so masonry survives
    float kl=dot(wsh,vec3(.33)),kg=1./(1.+40.*kl*kl);
    light+=(C4*.24+C1*.13+C0*.22)*gTp*ao*(.75+.25*n.y);
    light+=(C4*hw*.8+wc*snF*1.7)*1.5*kg*ao;
    // the kick's light lands after the soft limit: alternate bays surge with the wave, on the stone's own albedo
    vec3 kL=mix(C4,wc,.6)*(nK*2.+kFill*2.2+uP3.w*.5*(.25+.75*mod(bayW,2.)))*.84*kg*ao;
    // soft limit on the light (albedo still multiplies it, so masonry stays visible at the top of a kick)
    light/=1.+1.2*dot(light,vec3(.33));
    vec3 gold=C2*.9+.08;
    vec3 gspec=(C4*.5+C2*.5)*v9Sq(max(rf.y,0.))*.8+C2*d2*.8;
    // every material only sets parameters here; the lamps and gilt mouldings are drawn once below
    vec3 alb=vec3(.05),emi=vec3(0.),lcol=C4;float met=0.;
    float lu=0.,lv=1.,lsp=.1,lr=0.,lon=0.,wall=step(gMat,.5);
    float ra=.5*vKA;
    // a tunnel arch is shaded as a transverse arch with the tunnel's own section
    float sYS=vYS,sRV=vRV,sW=vW,sSA=gSA;
    // arc length round the arch (one atan for both the transverse arches and the arcade)
    float isAr=step(3.5,gMat),gat=atan(mix(y-sYS,max(y-vYA,0.),isAr),mix(ac+sRV-sW,abs(vp)-.5+ra,isAr));
    float gS=mix(mix(y,sYS+sRV*gat,step(sYS,y)),ra*gat,isAr);
    // kick: a ring of light chases away from the camera through the arches
    // (v11) the band of this bay (bass to air along the nave), shared by the glass and the transverse arches
    gMat=mix(gMat,15.,step(gMat,.5)*step(.6,n.y)*step(gYD-.4,y));
    if(gMat>7.5){
      // (v19) the citadel: glazed tile, gilt and masonry. Only drums and roofs branch; the rest is branchless (compile time)
      float yt=y-gYD;
      vec2 aa=abs(gBl),tc=aa-1.84;
      float hb=h21(mod(floor(pos.xz*.125),16.)+.37),st=floor(hb*4.),R0=v9TR(hb),Hs=v9TH(hb),rk=v9TK(gBl,aa,st);
      float an=atan(gBl.y,gBl.x),y3=3.*Hs+.05,hr=R0*(1.9+1.6*fract(hb*5.7))*(1.+.3*vSMB),rT=length(tc),isB=step(rT,.5);
#if HD>=1
      if(gMat>16.5){
        vec2 cl=floor((pos.xz-4.)/16.),lo=pos.xz-cl*16.-12.;
        hb=h21(mod(cl,8.)+.71);yt-=13.+13.*fract(hb*17.3)+1.2*vSMB;rk=length(lo);an=atan(lo.y,lo.x);y3=3.5;hr=3.;isB=0.;st=0.;gMat=mix(11.,9.,step(gMat,17.5));
      }
#endif
      float uR=mix(rk,.4,isB),an2=mix(an,atan(tc.y,tc.x)*2.+hb*6.,isB),uu=mix(gBl.x,gBl.y,step(aa.y,aa.x));
      float isDr=step(8.5,gMat)*step(gMat,9.5);
      vec2 ash=v9Ash(mix(vec2(uu,yt),vec2(an2*uR,yt),isDr),pf);
      vec3 stn=gStn*(.45+.22*ash.x)*(1.-.42*ash.y);
      alb=stn;
      if(isDr>.5){
        // (v20) drums are built in painted registers: blind arcades that play the low mids, jewelled lozenges, chevrons, quatrefoils that play the
        // presence band, arrow slits, barber twists. Every register is outlined in gilt, every string course carries beads for the hats.
        float Hr=.68,ry=yt/Hr,ri=floor(ry),rf=ry-ri,rq=mod(ri+floor(hb*6.),6.);
        float q0=step(rq,.5),q1=step(.5,rq)*step(rq,1.5),q2=step(1.5,rq)*step(rq,2.5),q3=step(2.5,rq)*step(rq,3.5),q4=step(3.5,rq)*step(rq,4.5),q5=step(4.5,rq);
        float cw=q0*.46+q1*.3+q2*.5+q3*.62+q4*.54+q5*.4;
        float Nc=max(floor(uR*TAU/cw),3.);cw=uR*TAU/Nc;
        float ax=an2*Nc/TAU,ci=floor(ax),cx=(ax-ci-.5)*cw,cy=(rf-.5)*Hr,er;
        vec2 ca=abs(vec2(cx,cy));
        er=(q0+q4)*v9Arch(vec2(cx,cy),mix(.06,cw*.33,q0),mix(.12,.08,q0),mix(-.22,-.24,q0),mix(1.4,1.3,q0))
          +q1*(ca.x/(cw*.46)+ca.y/(Hr*.4)-1.)*min(cw,Hr)*.3+q2*(abs(fract(rf*3.+abs(cx/cw)*2.)-.5)-.24)*Hr*.3
          +q3*(min(length(ca-vec2(cw*.17,0.)),length(ca-vec2(0.,cw*.17)))-cw*.155)+q5*(abs(fract((ax+rf*2.)*2.)-.5)-.22)*cw*.2;
        float tiny=smoothstep(.3,.7,pf/cw),tiny2=smoothstep(.25,.6,pf/Hr),ins=mix(smoothstep(pf,-pf,er),.42,tiny);
        vec3 cA=v9Grad(fract(ri*.271+hb*3.7+rq*.13+(ci*.11*step(.5,mod(rq,3.)))*(1.-tiny)));
        vec3 cB=mix(mix(C0,C3,.5+.5*sin(ri*2.1+hb*9.))*.5+.015,stn*1.25+C2*.05,q0+q4);
        { float tiny3=smoothstep(.1,.32,pf/Hr);vec3 kc=v9Grad(fract(hb*3.7+.13));cA=mix(cA,kc,tiny3);cB=mix(cB,kc*kc*.55+C0*.05,tiny3); }
        alb=mix(cB,cA*cA*.95+cA*.1,ins);
        float line=smoothstep(.012+pf,.003,abs(er))*(1.-tiny);
        float tk=smoothstep(.35,.1,pf/(cw*.2));vec2 tg=vec2(cx,cy)/(cw*.2);
        alb*=1.+tk*(.3*mod(floor(tg.x)+floor(tg.y),2.)-.15)*ins;
#if HD>=1
        { float h4=h21(mod(floor(tg),64.)+hb*11.+ri);alb*=1.+tk*ins*(.34*h4-.17);
          float e4=abs(er+.028);line=max(line,.7*smoothstep(.006+pf,.002,e4)*tk);
          float t5=smoothstep(.3,.1,pf/(cw*.07));vec2 tg5=vec2(cx,cy)/(cw*.07);alb*=1.-.28*t5*smoothstep(.1,.02,min(fract(tg5.x),fract(tg5.y)))*(1.-ins*.3);
          alb=mix(alb,v9Grad(fract(h4*2.+ri*.3)),.3*step(.86,h4)*tk*ins); }
#endif
        float sc2=smoothstep(.1+pf/Hr,.06,min(rf,1.-rf))*(1.-tiny2);
        alb=mix(alb,C2*.9+.06,max(line*.85,sc2));met=max(line,sc2)*.7;
        float bdx=(q0+q1+q2+q3)*mod(ci,2.)+2.*q0+6.*q2+4.*q3+q4*mod(ci+ri*3.+hb*8.,8.)+q5;
        vec2 wb=v9BO(mod(bdx,8.));
        float lit=mix(q2*.35*step(.72,fract(ci*.37+ri*.71))+(q1+q5)*.75+q0+q3+q4,.6,tiny);
        float kr=exp(-v9Sq((yt/max(3.*Hs,1.)-uP5.x*1.6)*5.))*exp(-uP5.x*2.6);
        emi+=cA*ins*(.2+lit*(.1+1.7*v9Rel(wb.x)+1.8*wb.y+1.6*snF*step(.5,mod(ri,2.))+1.1*hw+2.4*kr))+(C2+.1)*max(line,sc2)*(.04+.9*uHat+.5*uO2.w);
        lu=an2*uR;lsp=.17;lv=min(rf,1.-rf)*Hr-.0;lr=.018*(1.-tiny2);lcol=mix(C2+.15,v9Grad(fract(ri*.3+hb)),.6);
        lon=.2+2.2*uHat+1.5*uB2.w+1.8*uO2.w+1.2*hw;
      }else if(abs(gMat-11.)<.5){
        // roofs: rows of fish-scale tiles shading through the palette, gilt seams; a ring of light climbs them on the kick
        float ytr=yt-y3,hh=clamp(ytr/hr,0.,1.),sh=.2,vr=ytr/sh,rw=floor(vr),ur=an*max(rk,.12)/.26+.5*mod(rw,2.);
        vec2 sf=vec2(fract(ur)-.5,fract(vr));
        float sd=length(sf)-.52,lodS=smoothstep(.04,.13,pf);
        vec3 scC=v9Grad(fract(rw*.055+floor(ur)*.031*(1.-lodS)+hb*2.));
        alb=scC*mix(.5+.5*smoothstep(.0,-.3,sd),.78,lodS);
        alb*=1.-(1.-lodS)*.55*smoothstep(.05,.0,abs(sd));
#if HD>=1
        // every scale carries a smaller scale inside it and a gilt pip, gated on the pixel
        { float lS2=smoothstep(.015,.04,pf);
          alb=mix(alb,mix(alb*.55,v9Grad(fract(rw*.055+.33+hb*2.)),.5),(1.-lS2)*smoothstep(.02,.0,abs(sd+.2))*.8);
          alb=mix(alb,C2*.9,(1.-lS2)*smoothstep(.07,.05,length(sf-vec2(0.,.62))));
#if HD>=3
          alb*=1.-(1.-smoothstep(.006,.018,pf))*.18*step(.5,fract((sf.x+sf.y)*9.));
#endif
        }
#endif
        float gs=0.;
        { float seam=abs(fract(an*(4.+2.*st)/TAU)-.5)/(4.+2.*st)*TAU*max(rk,.1);
        gs=smoothstep(.035+pf,.01,seam)*smoothstep(.09,.03,pf);
        gs=max(gs,smoothstep(.1+pf,.05,ytr)*smoothstep(.09,.03,pf)); }
        alb=mix(alb,C2*.9+.08,gs*.85);met=gs*.8;
        float kr=exp(-v9Sq((hh-uP5.x*1.6)*5.))*exp(-uP5.x*2.6);
        emi+=scC*(.05+.2*v9Rel(uB1.y)+2.6*kr+.7*uP3.w+1.2*snF*(1.-lodS*.4)+step(.62,fract(rw*.37+floor(ur)*.71))*(1.1*uB2.w+.8*uB2.z+1.4*uHat))*(.55+.45*step(sd,0.));
        emi+=C2*gs*(.1+1.2*uB2.w+1.4*uO2.w);
      }else{
        // parapet 8, gilt rim 10, finial 12, bridge 13, portcullis 14, roof walk 15: parameters by arithmetic
        float is8=step(gMat,8.5),is10=step(9.5,gMat)*step(gMat,10.5),is12=step(11.5,gMat)*step(gMat,12.5),is13=step(12.5,gMat)*step(gMat,13.5),is14=step(13.5,gMat)*step(gMat,14.5),is15=step(14.5,gMat)*step(gMat,15.5),is16=step(15.5,gMat);
        float mi=floor(uu*2.+.75),capd=is8*smoothstep(.57-pf,.6+pf,yt),far2=smoothstep(.03,.14,pf),j=clamp(floor(yt/Hs),1.,3.),yj=j*Hs;
        vec3 jc=v9Grad(fract(mi*.19+hb*3.));
        { vec2 cq2=vec2(uu,yt)/.13;float cq3=mod(floor(cq2.x)+floor(cq2.y),2.),fz=is8*step(abs(yt-.04),.2)*step(1.9,max(aa.x,aa.y))*(1.-smoothstep(.04,.1,pf));
          vec3 fzc=mix(v9Grad(fract(hb*7.+.3)),C0*.7,cq3);alb=mix(alb,fzc*.85,fz); }
        alb=mix(alb,jc*.75+C2*.15,capd);
        vec3 gld=mix(C2*.85+.08,v9Grad(fract(hb*3.+yt*.05))*.7,far2);
        alb=mix(alb,gld,is10+is12);
        alb=mix(alb,vec3(.05,.05,.07),is14);
        float tip=is14*smoothstep(vYS+.55-.6*vSMB,vYS+.25-.6*vSMB,y),gs=is13*.5*smoothstep(.015+pf,.004,abs(yt-floor(yt/.45)*.45-.02));
        alb=mix(alb,C2*.9,tip+gs);
        vec2 pv=pos.xz*2.,pi2=floor(pv),pf2=fract(pv)-.5;
        float lodP=smoothstep(.03,.12,pf),pl=is15*step(abs(pf2.x)+abs(pf2.y),.5);
        vec3 pc2=v9Grad(fract(pi2.x*.13+pi2.y*.07+hb));
        vec3 rfc=v9Grad(fract(hb*3.3+.2));
        alb=mix(alb,mix(pc2*.8,rfc,lodP),is15*mix(pl,.85,lodP));
        met=capd*.3+(is10+is12)*.9*(1.-far2)+is14*.3+tip+gs;
        emi=jc*capd*(.08+1.4*v9Band(mod(mi,8.)/8.)+1.1*uO2.w*step(.5,fract(mi*.5))+1.8*uHat*step(.5,fract(mi*.5+hb)))
           +(C2+.2)*is12*(1.-far2)*(.25+1.2*uB2.w+1.6*uO2.w+2.2*uHat)+C2*tip*(.1+1.4*nearK+.6*uB2.z)
           +pc2*pl*(1.-lodP)*(.05+1.2*v9Band(mod(pi2.x+pi2.y*3.,8.)/8.))+rfc*is15*lodP*(.35+1.1*v9Band(fract(hb*5.))+1.1*uP3.w*smoothstep(.2,.9,zo));
        // the shared lamp row: on the gilt rims and along the bridges
        lu=an*max(rk,.3);lsp=.24;lv=yt-yj-.12;lr=is10*.03;
        lcol=mix(C2+.15,v9Grad(fract(j*.3+hb)),.7);
        lon=.4+2.4*uB2.y+2.2*uO2.y+1.2*hw;
#if HD>=1
        // the spiral gallery: a chase of lamps runs up it on the highs; bars of the air band and every hat
        { float Pq=1.25+.5*fract(hb*21.),hw3=mod(yt-an/TAU*Pq+Pq*.5,Pq)-Pq*.5,hch=fract(an*max(rk,.3)/1.1-uTime*1.3);
          lu=mix(lu,an*max(rk,.3),is16);lsp=mix(lsp,.2,is16);lv=mix(lv,hw3,is16);lr=mix(lr,.03,is16);
          lcol=mix(lcol,v9Grad(fract(floor(an*max(rk,.3)/.2)*.07)),is16);lon=mix(lon,.3+2.*uB2.z+2.2*uHat+2.4*smoothstep(.75,1.,hch)*(uB2.z+uB2.w+uO2.z),is16);
          alb=mix(alb,C2*.8+.06,is16);met=mix(met,.75,is16); }
#endif
#if HD>=1
        { float brL=max(aa.x,aa.y);
        lu=mix(lu,brL,is13);lsp=mix(lsp,.2,is13);lv=mix(lv,min(aa.x,aa.y)-.3,is13);lr+=is13*.025;
        lcol=mix(lcol,v9Grad(fract(floor(brL/.2)*.09)),is13);
        lon=mix(lon,.3+2.2*uB2.z+2.*uO2.z+1.5*hw,is13); }
#endif
      }
    }else if(gMat<.5){
      if(gw>.001){
        // window glass, lit from behind; during a build it fills with light from the sill upward
        float fill=mix(1.,smoothstep(.18+.9*grow,.02+.9*grow,(y-gyb)/max(gy0+ga*1.2-gyb,.1))*.85+.15,grow);
        // (v11) every bay's glass plays one of the 8 bands (bass to air along the nave, so the windows passing by read
        // as a spectrum analyser): its level lights the glass, its onset flashes it. A rose window blooms on the
        // hi-mid/presence onsets and a ring of light runs out through it on every snare.
        float rr=length(rc)/gRR,ring=smoothstep(.16,0.,abs(rr-uP3.z*1.3))*max(1.-uP3.z*.8,0.);
        float bf=.45*(uO2.z+uO2.w)+.7*nK+1.2*kFill+3.1*snF+mix(.4+2.1*v9Rel(bA.x)+1.2*bA.y,.75+2.2*(uO2.x+uO2.y)+1.3*uB2.x,rose);
        emi=gE*(1.35+.7*uP5.z)*bf*fill*gw*(1.+.5*burst)*(1.+1.2*hw)+C4*ring*2.2*rose*gw;
        alb=vec3(.02);
      }else{
        // painted vault, dome and walls: gold stars on deep glass colour (twinkling on the hats up in the vault)
        float vt=step(vYS+.02,y)*step(n.y,-.15),psc=mix(.2,.16,vt);   // (v15) .32 not .42: exactly 128-periodic in x and z
        vec2 pu=mix(mix(vec2(pos.x,y),vec2(pos.z,y),step(.5,abs(n.x))),pos.xz,vt)/psc,cf=fract(pu)-.5,ka=abs(cf);
        vec2 ash=v9Ash(mix(vec2(pos.x,y),vec2(pos.z,y),step(.5,abs(n.x))),pf);
        vec3 pg=mix(gStn*(.56+.2*ash.x)*(1.-.4*ash.y),C0*.3+.01,vt);
        // (v20) bare wall is never bare: a painted diaper of gilt lattice and jewel quatrefoils over the coursed stone (above the dado)
        vec2 wu=mix(vec2(pos.x,y),vec2(pos.z,y),step(.5,abs(n.x))),dg3=vec2(wu.x+wu.y,wu.y-wu.x)/.34,dgi=floor(dg3),dgf=fract(dg3)-.5,flq=abs(dgf);
        float dk=(1.-vt)*step(abs(n.y),.4)*smoothstep(.6,.25,pf/.24)*smoothstep(.45,.6,y),hd2=h21(mod(dgi,128.)+gLev*3.1);
        float fw=(min(min(length(flq-vec2(.17,0.)),length(flq-vec2(0.,.17)))-.17,length(dgf)-.2))*.24,dl3=(.5-max(flq.x,flq.y))*.24;
        vec3 fillC=mix(mix(C0,C3,.5)*.9+.02,v9Grad(fract(gLev*.13+floor(q)*.17)),step(mod(dgi.x+dgi.y,2.),.5));
        float fin=smoothstep(pf,-pf,fw);
        pg=mix(pg,pg*.6+C0*.06,dk*(1.-fin)*.8);
        pg=mix(pg,fillC*fillC*.85+.01,dk*fin*.92);
        pg=mix(pg,C2*.9+.05,dk*smoothstep(.016+pf,.008,length(dgf)*.24)*.9);
        pg=mix(pg,C2*.85+.04,dk*max(smoothstep(.011+pf,.003,dl3),smoothstep(.009+pf,.003,abs(fw)))*.85);
#if HD>=1
        { float t3=smoothstep(.2,.07,pf/.05);vec2 g2=dgf/.08;
          pg*=1.-t3*dk*.22*smoothstep(.14,.06,min(fract(g2.x),fract(g2.y)));
          pg=mix(pg,C2*.9,t3*dk*smoothstep(.022,.014,length(dgf))); }
#endif
        float hs=h21(floor(pu)+gLev*.37);
        float hat=uO2.z+uO2.w,st=min(ka.x*.3+ka.y,ka.y*.3+ka.x)-.11*(.7+.6*hs)*mix(step(.5,hs)*.8,1.,vt)*(1.+.45*hat);
        float spx=pf/psc,star=smoothstep(spx,-spx,st)*smoothstep(.2,.07,spx)*vt;
        float tw=.6+(.6+step(.6,hs))*hat*2.2+uB2.z*(.5+hs)+burst;
        alb=mix(pg,gold,star);met=star;
        emi=C2*star*tw*mix(.12,.5,vt)+(pg*.15+C0*(.5*uB2.x+.3*uO2.x)*vt)*(1.-star)+fillC*fin*dk*(.2+.35*v9Rel(bA.x)+step(.8,hd2)*(.1+1.6*uHat+1.2*uB2.w+1.5*uO2.w));   // (v13) the painted vault breathes with the hi-mids (large smooth light: no shimmer)
        // the snare wave across the vault (v11: the dome's crown oculus, rarely seen, was cut for compile time)
        emi+=C4*vt*hw*.4;
        // tiny lamps along the gallery and clerestory sills, far overhead (the presence band): they set the scale
        float sy=mix(gC0-.05,gT0-.05,step(abs(y-gT0+.05),abs(y-gC0+.05))),up=step(gT0+.5,sy),sm=(1.-vt)*step(.05,s)*step(abs(y-sy),.06);
        lu=q+1./12.;lsp=1./6.;lv=y-sy;lr=.017*sm;lcol=mix(C4,C1,step(.5,fract(floor(q*6.)*.5)));
        lon=.25+2.4*mix(uB2.x,uB2.y,up)+2.*mix(uO2.x,uO2.y,up)+1.5*hw;
        emi+=C2*smoothstep(.012+pxw,.0,abs(y-sy-.035))*.25*sm;
        // (v18) the triforium gallery glows from within, playing the presence band; the walls overhead catch the snare
        emi+=mix(C1,C4,.4)*step(gT0-.02,y)*step(y,gT1+.02)*smoothstep(.1,.35,s)*(.1+.6*v9Rel(uB2.y)+.9*uO2.y);
        emi+=C4*(uP3.w*.35+nearK*.5+snF*.3)*vt;
      }
    }else if(abs(gMat-2.)<.5){
      // colossal clustered piers, gilt annulets and capitals, a ring of light round each plinth (the bass), gilt
      // balustrades round the wells
      vec2 g=gBl-clamp(floor(gBl+.5),-2.,2.);
      float side=mod(floor(gBl.x+.5)+floor(gBl.y+.5),2.);
      float lz=smoothstep(.012+pxw,.012-pxw*.5,abs(fract(y*1.25)-.5)*.8)*smoothstep(.06,.02,pxw);
      float cap=(step(abs(y-vYA+.05),.065)+step(abs(y-vYS+.05),.065))*(.5+.5*smoothstep(.15,.5,abs(fract((g.x-g.y)*13.)-.5)*2.));
      float gm=max(lz,cap);
      // (v13) polychrome piers. From afar (and flying past) they are smooth bands of jewel colour cycling slowly up the
      // shaft; close up or zoomed in, a lattice of lozenges outlined in gold, a gold boss in each, resolves out of them
      // (no fine pattern moves at mid distance, so nothing shimmers). The bass pours light up every pier from its
      // plinth like a level meter with a bright rim riding its top; the kick's ring of light runs along them; the sub
      // lights the plinth rings
      float zp=smoothstep(0.,.45,zi);vec3 pc=mix(C1,C4,smoothstep(.25,.75,abs(fract(y*.08+side*.5+gLev*.1)-.5)*2.));
      float pcj=smoothstep(.006+pxw,.0015,abs(fract(y/.085)-.5)*.085)*smoothstep(.02,.006,pxw);
      alb=gStn*.64*(1.-.4*pcj);
      { float pyb=y*1.25+.5,pbi=floor(pyb),pbf=fract(pyb),pan=atan(g.y,g.x)*mix(1.27324,.31831,step(vYA,y)),pu=abs(fract(pan)-.5),pk2=mod(pbi+side,2.);
        float pfa=step(.2,y)*step(y,vYS-.1),pfar=smoothstep(.012,.04,pxw*mix(1.,2.5,step(vYA,y)));
        float pch=abs(fract(pbf*2.+pu*2.)-.5)*2.,plz=pu*2.+abs(pbf-.5)*2.;
        float pq=mix(smoothstep(.5-pxw*20.,.5+pxw*20.,pch),smoothstep(.72+pxw*14.,.72-pxw*14.,plz),pk2);
        vec3 pA=v9Grad(fract(pbi*.23+side*.37+gLev*.11)),pB=mix(C0,C3,.5+.5*cos(pbi*1.7+side))*.5+.01;
        pq=mix(pq,.5,pfar);
        alb=mix(alb,mix(pB,pA*pA*.9+pA*.08,pq),.9*pfa);
        float pln=smoothstep(.1+pxw*20.,.04,abs(mix(pch-.5,plz-.72,pk2)))*pfa*(1.-pfar);
        alb=mix(alb,gold,pln*.8);gm=max(gm,pln*.6);
#if HD>=1
        { float pfn=(1.-smoothstep(.006,.02,pxw*mix(1.,2.5,step(vYA,y))))*pfa;
          float pl2=smoothstep(.07+pxw*24.,.02,abs(mix(abs(pch-.5)-.26,plz-.4,pk2)))*pfn;
          alb=mix(alb,gold,pl2*.7);gm=max(gm,pl2*.5);
          alb=mix(alb,C2+.1,smoothstep(.13,.09,plz)*pk2*pfn); }
#endif
        emi+=pA*pq*pfa*(.06+.5*v9Rel(bA.x)*step(.5,pk2)+.5*bA.y+.9*hw); }
      alb=mix(alb,gold,max(lz,cap));met=gm;
      float hB=.2+(vYA+.2)*uB1.y*sqrt(uB1.y),fill=smoothstep(hB+.3,hB-.3,y)*zp;
      emi+=C2*cap*(.05+.4*uB2.z+1.2*hw)+C4*smoothstep(.02,.0,abs(y-.17))*step(length(g),.4)*(.3+1.6*uB1.x+1.5*uO1.x)
         +pc*fill*(.05+.32*uB1.y+.3*uO1.y)+(C4+C2)*exp(-abs(y-hB)*5.)*uB1.y*.4*zp
         +(C2+.2)*2.*e3*smoothstep(.55,1.,fract(y*.12-uTime*.6+side*.5))*(.3+.7*gm);
    }else if(gMat>6.5){
      // (v18) banners: a jewel-coloured field, gold borders and a gold roundel, each lit by its own band
      float bq=fract(q*.5)-.5,by=(gT0-.1-y)/1.75,bays=floor(q*.5);
      // (v20) gonfalons: quartered in two jewels with a fine diaper, gilt cross and a lozenge with an eight-point star
      float qt=mod(step(0.,bq)+step(.42,by),2.),bxx=abs(bq),byy=by-.42;
      vec3 bc=v9Grad(fract(bays*.37+gLev*.2)),bc2=mix(C0,C3,.5+.5*cos(bays*2.3+gLev))*.7+.01;
      vec2 dg2=vec2(bq+by*.45,by*.45-bq)/.05;float dif=smoothstep(.6,.2,pxw/.05);
      float dgl=step(.5,mod(floor(dg2.x)+floor(dg2.y),2.));
      vec3 fld=mix(bc,bc2,qt)*(1.+dif*(.22*dgl-.11));
      float sb=max(smoothstep(.016+pxw,.004,abs(bxx-.16))*step(by,.97),smoothstep(.022+pxw,.008,abs(by-.96)));
      float crs=smoothstep(.014+pxw,.004,min(bxx,abs(byy)*.45));
      float lz=(bxx/.12+abs(byy)/.26-1.)*.09;
      vec2 s8=abs(vec2(bq,byy*.45));float stS=min(max(s8.x,s8.y),(s8.x+s8.y)*.70711)-.045;
      float lzI=smoothstep(pxw,-pxw,lz),stI=smoothstep(pxw,-pxw,stS);
      fld=mix(fld,bc2*.45+.01,lzI);
      float gl2=clamp(sb+(crs*(1.-lzI))+smoothstep(.01+pxw,.003,abs(lz))+stI,0.,1.);
      vec2 bB=v9BO(mod(bays*3.+2.,8.));
      float wv=smoothstep(.04,.012,pxw)*(.5+.5*sin(q*150.)*sin(y*150.));
      alb=mix(fld*(.5+.14*wv)+.015,gold,gl2);met=gl2;
      emi=fld*(.02+.2*v9Rel(bB.x)+.6*bB.y)*(1.-gl2)+C2*gl2*(.05+.35*uB2.z)+C2*stI*(.3+1.6*bB.y);
    }else if(gMat>5.5){
      // (v15) the corona: a gilt wheel of twelve jewels hanging from the vault on a fine chain, with a pendant jewel
      // beneath it. The jewels are one lamp row round the wheel (so far away they fade to their average and never
      // speckle). The wheel plays the high and air bands and every hat; the pendant is the sub's own deep jewel.
      float cqd=abs((q-.5+gSw)*.5-floor((q-.5+gSw)*.5+.5))*2.,cR=length(vec2(ac,cqd)),ca=atan(cqd,ac),cy=gApex-1.15-.35*vSMB;
      float ringd=length(vec2(cR-.72-.2*vSMB,y-cy)),pend=length(vec2(cR,y-cy+.62)),pj=step(pend,.1);
      lu=ca*.72;lsp=TAU*.72/14.;lv=ringd;lr=.05;
      lcol=mix(C2*1.15+.15,v9Grad(fract(ca/TAU+.5)),.3);
      // (v15) each corona is a level meter for one of the eight bands (consecutive wheels play consecutive bands), so
      // looking down a nave reads as a spectrum: the wheels that belong to the loud band burn, the rest sit low.
      vec2 hb=v9BO(mod(floor((q-.5)*.5)+8.,8.));
      lon=.35+2.*v9Rel(hb.x)+2.*hb.y+1.5*uB2.w+1.5*hw;
      alb=mix(gold*.9,C0*.6+.05,pj);met=mix(.85,.2,pj);
      // the rim glows in its own lamp colour, the pendant burns from inside with the sub, the chain is a gilt line
      emi=lcol*(.03+.1*uB2.w)*(1.-pj)+C2*(.02+.18*uB2.y)+C0*(.5+1.6*uB1.x+1.2*uO1.x)*smoothstep(.1,.02,pend);
    }else{
      // mouldings with lamps, one shared recipe: transverse archivolts and tunnel arches (1: an equaliser, bass at
      // the springing, treble at the apex; outer order painted), vault ribs (3: jewel studs twinkling on the air band)
      // and arcade archivolts (4: the low mids). Far away the lamps merge into their average glow and the rolls keep
      // their jewel colour instead of the gilt.
      float isT=step(gMat,1.5),isR=step(2.5,gMat)*step(gMat,3.5),isA=step(3.5,gMat),fc=step(.6,na)*isT;
      float dw=-gNave,dm=.2*gMaj,far=smoothstep(.015,.06,pf);
      float sv=clamp((y-vYS)/max(gApex-vYS,.01),0.,1.);
      // across a vault rib (its crown line), or across a transverse arch (face: between the orders; soffit: centre)
      float cr=min(mix(abs(abs(vp)-.5*(1.-sv))*.75,abs(abs(gUv.x)-abs(gUv.y))*.7071,step(gQ,0.)),gAc);
      lsp=mix(.08,.07,isA);
      float li=floor(gS/lsp);
      float sn=mix(mix(clamp((li+.5)*lsp/sSA,0.,1.),sv,isR),fract(li*.123+gLev*.3),isA),lvl=v9Band(sn);
      // the vault ribs keep to the jewel half of the rainbow (cyan, sapphire, violet, magenta), so far overhead they never
      // average to olive
      lu=gS+lsp*.5*isT;
      lv=isT*mix(gBz,dw-dm,fc)+isR*cr+isA*(gAA-.045+step(.6,na));
      lr=mix(mix(.03,.016,isR),.018,isA)*(1.-isT*smoothstep(.3,.1,abs(na-.6)));
      lcol=mix(C2+.1,v9Grad(mix(sn,fract(.5-uP4.w+sv*.35)/.8,isR)),.65);
      lon=isT*(.12+2.6*lvl*sqrt(lvl)+.5*(gMaj-1.))+isR*(.7+uB2.w*(1.+sin(gS*40.+uTime*9.))+2.*uO2.w)
         +isA*(.15+2.2*uB1.z+1.6*uO1.z*step(.5,fract(li*.5)))+(1.-isR)*nearK+1.5*hw+burst*(1.-isR);
      // (v11) every transverse arch plays its bay's band (as the glass does): the giant rainbow arches along the nave are a
      // spectrum analyser, the bass arches thumping, the treble arches flickering; light only
      float aB=mix(1.,.28+1.4*v9Rel(bA.x)+.9*bA.y,isT);lon*=aB;
      // dark painted rolls (the arcade's are gilt near by); a neon band glows along each row of lamps and far away
      // everything merges into its jewel-coloured average
      float vj=smoothstep(.01+pf,.003,abs(fract(gS/.22)-.5)*.22)*smoothstep(.022,.007,pf);
      alb=gStn*(.6+.12*h11(floor(gS/.22)+gMaj))*(1.-.35*vj);
      float bw=mix(.012,.018,fc),band=mix(smoothstep(bw+pf,bw*.2,abs(lv)),.25,far);
      emi=(C2+.08)*isT*smoothstep(.012+pf,0.,abs(dw-.12*gMaj))*(1.-far)*(.22+.7*uB2.z+1.*nearK)+C2*(.02+.3*hw)*(1.-far)
         +lcol*band*(isT*(.04+.25*lvl+.5*nearK+.6*hw+.5*uP3.w)+isR*(.05+.12*uB2.w)+isA*(.04+.12*uB1.z));
      emi*=aB*mix(1.,.28,gTp);lon*=mix(1.2,.45,gTp);   // (v18) stone mouldings with fine jewel lamps; no neon band
      // (v20) the wall-head pilasters of the citadel are painted with stacked chevrons, like the keeps
      if(gTp>.5){ float cv=y/.3+abs(gBz)*5.,cvi=floor(cv),cvF=smoothstep(.09,.03,pf);
        vec3 cvC=v9Grad(fract(cvi*.19+floor(q)*.13));
        float cvL=smoothstep(.07+pf*3.,.02,min(fract(cv),1.-fract(cv)))*cvF,cvJ=smoothstep(.05+pf,.03,length(vec2(abs(gBz)*.6,(fract(y/.6)-.5)*.6)))*cvF;
        alb=mix(alb,C2*.85,cvL);alb=mix(alb,cvC*cvC,cvJ);met=max(met,cvL*.8);
        emi+=cvC*cvJ*(.1+1.6*v9Rel(bA.x)+1.4*bA.y+1.5*uHat); }
    }
    // (v12) procession: a block of two bays lit at a time runs down every nave, eight bays per bar
    float prc=smoothstep(.7,1.,fract(floor(mix(pos.z,pos.x,step(abs(gUv.y),abs(gUv.x)))+.5)*.125-uBar)),pk=mix(1.,.15+2.8*prc,e1);
    // gold ascension: bands of gold light rise up the elevation, every lamp turns gold
    float gb=exp(-v9Sq((y-fract(uTime*.3)*(gApex+1.)+.5)*1.3));
    emi=emi*pk+(C2*1.3+.2)*gb*e2*(.4+.6*ao);lon*=pk*(1.+e2);lcol=mix(lcol,C2+.15,.7*e2);
    // shared lamps (with a small halo) and rounded mouldings; a lamp smaller than about two pixels leaves only its
    // average glow, so far rows of lamps never speckle
    float ld=length(vec2((fract(lu/lsp)-.5)*lsp,lv));
    float lvis=step(.001,lr)*smoothstep(.85,.5,pxw/max(lr,1e-4)),lamp=lvis*smoothstep(lr+pxw,lr-pxw,ld);
    alb=mix(alb,min(lcol,vec3(1.))*.5,lamp);met*=1.-lamp;
    // (the average glow is confined to the lamp row's strip, so a fading row never smears into a band)
    emi+=lcol*lon*(lamp*1.15+lvis*exp(-ld/(lr*.9+1e-4))*(1.-lamp)*.3+step(.001,lr)*(1.-lvis)*mix(.3,.4,wall)*smoothstep(lr*mix(2.2,1.6,wall)+pxw,lr*.4,abs(lv)));
    emi+=alb*kL*(1.-lamp);
    col=(alb*light*(1.-.6*met)+gold*met*(amb*1.5*ao+gspec)*.9+alb*sky*fres*.2*ao)*(1.-bk);
    col+=emi*(.3+.7*ao);
#if HD>=2
    if(step(.0001,nRf)>.5){
      vec3 rc=v9RC(rPos,rN,rMat,sunD,rR,rHit,snF);
      col+=rc*(met*.75+.05+fres*.5)*(1.-.5*bk);
    }
#endif
    // (v11) shafts of window light (sub and bass): world-fixed slanting beams land on every surface as coloured pools
    // that flare with the bass; one evaluation at the hit, anti-aliased against the pixel footprint
    // height fog: thick near the floor, thin under the vault; window light shines through it
    float hy=max(min(ro0.y-flY,y),0.);
    // (v13) from high above the walls are seen edge-on and their fine glass and mouldings would shimmer as the plan
    // scrolls: the cutaway shows them as calm dusk-lit faces, the plan is drawn by the floors, roofs and outlines
    col*=1.-mix(.6,.15,gTp)*smoothstep(.78,.98,zo)*smoothstep(.6,.2,abs(n.y));
    float fogK=1.-exp(-hT*(.022+.02*grow)*mix(1.,.62,ext)*(1.-.7*zo+1.1*smoothstep(.7,.98,zo)*(1.-.75*ext))*(1.-.6*zi)*(.4+.9*exp(-hy*.3)));
    col=mix(col,haze,fogK*(1.-.8*clamp(length(emi),0.,1.)));
  }
  if(max(bounce,sfl)>.5){
    // polished floor: a mirror of the nave (the camera's level) with gold inlay, coloured light pools, the kick runner
    vec3 fq=mix(fpos,hp,sfl);float fT=mix(tF0,hT,sfl);
    float fpx=fT*gPx*inversesqrt(max(abs(rd0.y),.02));
    float fres=1.-abs(rd0.y);fres*=v9Sq(v9Sq(fres));
    vec2 fu=fq.xz-floor(fq.xz*.125+.5)*8.,fa=abs(fu);
    float fac=min(fa.x,fa.y),fal=max(fa.x,fa.y)-vW;
    vec2 g=fq.xz/.64;vec2 gf=fract(g)-.5;   // (v15) .64 not .62: the world is 128 units across, so this pattern is now exactly periodic
    // (v20) the classic eight-point star and cross pavement, with a gilt lead line round every star
    float gsa=max(abs(gf.x),abs(gf.y)),gsb=(abs(gf.x)+abs(gf.y))*.70711,gsd=(min(gsa,gsb)-.27)*.64;
    float dl=abs(gsd);
    float inl=smoothstep(.01+fpx,.01-fpx*.5,dl)*smoothstep(.07,.02,fpx);
    // rainbow light pools thrown by the windows along each wall, a runner of glass tiles down the middle; a wave of
    // light runs out along the runner on every kick
    float fl=smoothstep(.02,.08,fpx),pv=abs(fract(fal)-.5),tzf=fal/.25,inr=step(fac,.5);
    // (v20) lancet pools: the window's own shape thrown on the pavement
    float pool=mix(smoothstep(fpx,-fpx,v9Arch(vec2(fract(fal)-.5,fac-.82),.3,.62,0.,1.5)),.6*smoothstep(.8,1.,fac)*smoothstep(1.98,1.8,fac),fl);
    float run=mix(1.,.75,fl)*smoothstep(.2+fpx,.17-fpx,fac)*mix(smoothstep(.5,.38,abs(fract(tzf)-.5)),.75,fl)*.4;
    float kw=exp(-v9Sq(length(fq.xz-ro0.xz)-.8-uP5.x*11.)*.5)*exp(-uP5.x*1.4);
    float ph=floor(fal)*.382+gLev*.13;
    vec3 pc=v9Grad(fract(mix(ph,floor(tzf)*.29,inr*(1.-fl))));
    float dtk=step(0.,gsd);dtk=mix(dtk,.5,smoothstep(.03,.08,fpx));
    vec3 fc=mix(mix(gStn*.34,v9Grad(fract(floor(g.x)*.13+floor(g.y)*.29))*.4,.55),C0*.22+.015,dtk)*(.55+.5*uB1.y)+C2*inl*(.14+.5*uB1.y)+pc*step(0.,fal)*(pool*(.35+.6*uB1.w)+run*(.12+.5*uB1.y+(2.*kw+.6*burst)*(1.-smoothstep(.7,.9,zo))));
    // v14: labyrinthine gold-and-glass floor medallions, with octagonal rosettes at every crossing.
    // (v13) the cut face: harlequin stained glass over the solid with the inlay as its leading, each 2-unit square lit by
    // its own band from below (seen from above the plan plays the spectrum), outlined in gold where the cut meets the
    // building's surfaces (there the normal taps straddle the corner of the field and tilt the normal)
    vec2 cb=v9BO(mod(floor(fq.x*.5)+floor(fq.z*.5)*3.,8.));
    // (coarse 2-unit diamonds with their own leading, faded to their average before they could shimmer)
    vec2 gc=fract(fq.xz*.5)-.5;float dc=abs(gc.x)+abs(gc.y),kc=fpx*.75,lc=smoothstep(.12,.35,kc);
    vec3 pcl=mix(mix(C1,C3,smoothstep(.5+kc,.5-kc,dc))*(1.-smoothstep(.04+kc,.04,abs(dc-.5))),C1*.45+C3*.45,lc);
    pcl=mix(pcl,gStn*.5,.3);
    fc=mix(fc,mix(pcl*(.25+.9*cb.x+.7*cb.y+.5*hw),(C2+C4*.5)*(.35+1.1*cb.x+.9*cb.y+.5*burst),smoothstep(.998,.9,n.y)*mix(1.,.15,smoothstep(.02,.08,fpx))),step(vCUT-.04-2.*fpx,fq.y)*sfl);
    fc+=mix(C4,C2,.3)*kw*.5*(1.-sfl);
    // (v20) the carpet: a rosette to every bay in that bay's colour, played by that bay's band; gilt borders; a fringe of beads
    { float cl3=fract(fal)-.5,cr=length(vec2(fac,cl3)),ca3=atan(cl3,fac),cs3=mod(ca3+PI/8.,PI/4.)-PI/8.;
      vec2 pt=cr*vec2(cos(cs3),sin(cs3));
      float cFar=smoothstep(.02,.07,fpx),cWd=step(fac,.56)*step(0.,fal)*(1.-sfl);
      float ptl=(length(vec2((pt.x-.23)/.14,pt.y/.075))-1.)*.08,cen=length(vec2(fac,cl3))-.085,brd=abs(fac-.5)-.03,rng=abs(cr-.42)-.012;
      vec3 cc=v9Grad(fract(floor(fal)*.31+gLev*.13)),cc2=mix(C0,C3,.5);
      float cLv=v9Band(mod(floor(fal),8.)/8.+.06);
      vec3 cf=mix(cc2*.42+.008,cc*(.4+2.2*cLv*sqrt(cLv)+1.6*kw),smoothstep(fpx,-fpx,ptl));
      cf=mix(cf,C2*(.5+uB2.x*.8),smoothstep(fpx,-fpx,cen));
      cf=mix(cf,C2*.85,max(smoothstep(.006+fpx,.002,abs(ptl)),max(smoothstep(.012+fpx,.0,brd),smoothstep(.004+fpx,.0,rng))));
      vec2 dg4=vec2(fac+cl3,cl3-fac)/.09;
      cf*=1.+.22*smoothstep(.1,.02,fpx/.09)*(mod(floor(dg4.x)+floor(dg4.y),2.)-.5)*step(0.,ptl);
      cf=mix(cf,pc*(.15+.5*uB1.y+1.2*kw),cFar);
      fc=mix(fc,cf,cWd); }
    // (v18) pilgrims: lanes of tiny candle bearers walking both ways along the nave floor. From gallery height they set the
    // scale of the building; they twinkle on the hats and every fifth one flares on the air-band onsets
    float ln=floor(fac*5.),pdr=mod(ln,2.)*2.-1.,pp=fal*4.+pdr*uTime*.5+h11(ln+3.)*3.,pid=floor(pp);
    float pd2=length(vec2((fract(pp)-.5)*.25,(fract(fac*5.)-.5)*.2)),plod=1.-smoothstep(.012,.04,fpx);
    float pil=smoothstep(.03+fpx,.014,pd2)*plod*step(0.,fal)*step(fac,1.92)*step(.35,h11(pid+ln*7.));
    fc+=(C2*1.3+.35)*pil*(.9+2.2*uB2.z+1.5*uB2.y*h11(pid)+2.5*uO2.w*step(.8,h11(pid*.7)))+(C2+.1)*(1.-plod)*step(0.,fal)*step(fac,1.92)*.07*(.5+2.*uB2.z);
    // near grazing the reflected rays run out of steps among the pier bases: blend to the haze there (no speckle)
    float wM=smoothstep(.72,.86,zo),R=(.38+.5*fres)*(1.-sfl)*(1.-wM),rg=smoothstep(.035,.14,abs(rd0.y))*exp(-fT*.025*(1.-.6*zo));
    col=fc+mix(haze*.3,col,rg)*R;
    col=mix(col,haze,1.-exp(-fT*.012*(1.-.7*zo+1.1*smoothstep(.7,.98,zo))*(1.-.6*zi)*(1.3-.4*max(sfl,wM))));
  }
  // (v11) sub and bass light the air: a smooth glow over the haze, deeper with distance (no samples, no grain)
  float aL=min(mix(mix(tmax,hT,hit),tF0,bounce),26.);
#if HD>=1
  // the sun shafts, tinted by the palette; the bass and the kick make them breathe
  float vf=vol/nV;
  col+=(C1*.35+C3*.35+C0*.3)*vf*vf*min(vEnd*.03,1.)*(.035+.09*uB1.y+.07*uP3.w)*smoothstep(-1.5,.5,ro0.y);
#endif
  col+=C0*uM2[2][2]*.26*min(aL*.03,1.)*(1.-smoothstep(.45,.75,zo));
  // (v18) votive sparks rising through the air of the nave: real points in the world, sized against the pixel, twinkling on
  // the air band and flaring on hat onsets (the highs' own layer)
  vec3 spk=vec3(0.);
  for(int i=V90;i<5;i++){
    float ft=2.5+float(i)*float(i)*1.1;
    if(ft>aL)break;
    vec3 qq=ro0+rd0*ft,cl2=floor(qq/1.6);
    float hsk=h21(cl2.xz+cl2.y*7.);
    vec3 cn=(cl2+.5+.35*vec3(sin(hsk*40.+uTime*.7),cos(hsk*23.+uTime*.5),sin(hsk*77.+uTime*.6)))*1.6;
    vec3 ry=cn-ro0;float dz=dot(ry,rd0),dr=length(ry-rd0*dz),sz=gPx*dz*1.5+.003;
    spk+=v9Grad(fract(hsk*3.1))*step(.55,hsk)*smoothstep(sz*2.2,sz*.4,dr)*step(0.,dz)*(.5+1.8*uB2.w*fract(hsk*17.)+2.5*uO2.w*step(.7,fract(hsk*5.)));
  }
  col+=spk*(1.-smoothstep(.45,.75,zo));
  // the far end opens onto the next realm at builds and drops
  float wr=.08*grow*grow+.1*burst*burst;
  float win=smoothstep(wr,wr*.75,length(lp))*step(30.,hT+60.*(1.-hit))*step(.004,wr);vec2 wl=lp/max(wr,1e-3);
  // (v15) chroma lift, weighted toward the mid and dark tones (the v14 lift was a flat 1.06): the interior has more
  // shadow than the old aerial view did, and the briefs require mean saturation not to fall
  float cl=dot(col,vec3(.2126,.7152,.0722));
  col=mix(vec3(cl),col,1.24+.12*(1.-smoothstep(.15,.7,cl)))*.9;
  fragColor=vec4(max(col,0.),win);fragWin=vec4(wl*.5+.5,1.,1.);
}
void realm(){v9Scene(scr());}
`;
