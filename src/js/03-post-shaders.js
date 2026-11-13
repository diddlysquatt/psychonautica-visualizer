/* Feedback + compose: warps the previous frame (zoom, swirl, liquid flow, pointer gravity), folds the
   scene through an optional kaleidoscope, flies through a portal between realms, and opens each realm's
   "windows" (its alpha channel) onto a smaller copy of the whole image, so the picture nests inside itself. */
const FS_FEEDBACK = `#version 300 es
precision highp float;
precision highp int; // ADRENO FIX: the fragment default for int/uint is mediump (16-bit on some mobile GPUs)
${HALF_GLSL}
// uA/uB/uN: packed realm targets (see sharpTex below); uPrev: last frame; uBlur: blurred bright pass of the last frame
uniform highp usampler2D uA,uB,uN;
uniform sampler2D uPrev,uBlur;
uniform vec2 uRes,uMouse,uMouseVel,uTC;
uniform vec4 uMouseV,uHole;
uniform float uTime,uMix,uStyle,uSymA,uSymB,uSymRot,uZoomFb,uRotFb,uDecay,uHueStep,uRaw,uPulse,uEcho,uDroste,uPeek,uHold,uSpin,uWin,uCurl,uStut,uSymA0,uSymT;
uniform vec2 uSymRot2; // v21: fold rotation of the incoming scene (x) and of the outgoing fold during a dissolve (y)
// uFlow: liquid flow. x = live sway (height units), y = trail advection per frame, z = field clock, w = field scale
uniform vec4 uFlow;
out vec4 fragColor;
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}
float h21(vec2 p){vec3 q=fract(p.xyx*.1031);q+=dot(q,q.yzx+33.33);return fract((q.x+q.y)*q.z);}
float vn(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h21(i),h21(i+vec2(1,0)),f.x),mix(h21(i+vec2(0,1)),h21(i+vec2(1,1)),f.x),f.y);}
vec3 hueRot(vec3 c,float a){vec3 k=vec3(.57735);float ca=cos(a);return c*ca+cross(k,c)*sin(a)+k*dot(k,c)*(1.-ca);}
// v10 liquid: the curl of a two-octave smooth value-noise potential. Divergence-free, so the image swirls and streams
// like liquid or heat haze instead of bulging; C1-continuous and slowly evolving, so it never tears or flickers.
float flowPot(vec2 p,float t){return vn(p+vec2(t*.31,-t*.23))*.65+vn(p*2.03+vec2(-t*.47,t*.37)+7.1)*.35;}
vec2 flowField(vec2 p){vec2 P=p*uFlow.w;float t=uFlow.z,e=.04,n0=flowPot(P,t);return vec2(flowPot(P+vec2(0.,e),t)-n0,-(flowPot(P+vec2(e,0.),t)-n0))/e*.8;}
// v21: n is the fold count and may be any real number from 2 up (a fold change glides the mirror angle: mirroring the
// angle about the fold axis first keeps the picture continuous for every n, and gives exactly the old fold at whole n).
// n = 1 is the plain left-right mirror, 0 is unfolded.
vec2 kal(vec2 p,float n,float ro){if(n<.5)return p;if(n<1.5)return vec2(abs(p.x),p.y);float a=abs(mod(atan(p.y,p.x)+ro+3.14159265,6.2831853)-3.14159265);float seg=6.2831853/n;a=mod(a,seg);a=abs(a-seg*.5);return length(p)*vec2(cos(a),sin(a));}
vec3 prevAt(vec2 q,vec2 asp){vec2 puv=q/asp+.5;float inb=step(0.,puv.x)*step(puv.x,1.)*step(0.,puv.y)*step(puv.y,1.);return texture(uPrev,puv).rgb*inb;}
// Realm targets are packed into ONE RGBA32UI attachment (half-float rgb + window mask, then the window coordinates).
// Writing two attachments made ANGLE's D3D11 backend (the default on Windows) compile every realm program twice, the
// second time synchronously at its first draw, which froze the whole browser for 1-14 s per realm. Integer textures
// cannot be filtered, so mirrored wrap, bilinear and bicubic sampling are done here by hand.
ivec2 mirrorTexel(vec2 i,vec2 n){vec2 m=mod(i,2.*n);return ivec2(mix(m,2.*n-1.-m,step(n,m)));}
vec4 colAt(highp usampler2D t,vec2 i,vec2 n){highp uvec4 v=texelFetch(t,mirrorTexel(i,n),0);return vec4(hvUnpack(v.x),hvUnpack(v.y));}
vec4 winAt(highp usampler2D t,vec2 i,vec2 n){highp uvec4 v=texelFetch(t,mirrorTexel(i,n),0);return vec4(hvUnpack(v.z),hvUnpack(v.w));}
vec4 colBil(highp usampler2D t,vec2 uv){
  vec2 n=vec2(textureSize(t,0)),s=uv*n-.5,i=floor(s),f=s-i;
  return mix(mix(colAt(t,i,n),colAt(t,i+vec2(1,0),n),f.x),mix(colAt(t,i+vec2(0,1),n),colAt(t,i+vec2(1,1),n),f.x),f.y);
}
vec4 winBil(highp usampler2D t,vec2 uv){
  vec2 n=vec2(textureSize(t,0)),s=uv*n-.5,i=floor(s),f=s-i;
  return mix(mix(winAt(t,i,n),winAt(t,i+vec2(1,0),n),f.x),mix(winAt(t,i+vec2(0,1),n),winAt(t,i+vec2(1,1),n),f.x),f.y);
}
vec4 crRow(highp usampler2D t,vec2 i,vec4 w,vec2 n){return colAt(t,i-vec2(1,0),n)*w.x+colAt(t,i,n)*w.y+colAt(t,i+vec2(1,0),n)*w.z+colAt(t,i+vec2(2,0),n)*w.w;}
// Sharp live sampling. A bilinear tap at a displaced coordinate averages neighbouring texels, and done every frame it
// softened the whole picture. Where the coordinate sits on a texel centre (no warp, spin or pulse there) the texel is
// copied exactly; elsewhere a 16-tap Catmull-Rom keeps edges crisp. Negative lobes are clamped so HDR highlights
// cannot ring below black.
vec4 sharpTex(highp usampler2D t,vec2 uv){
  vec2 n=vec2(textureSize(t,0)),sp=uv*n,tc=floor(sp-.5),f=sp-.5-tc;
  vec2 fe=abs(f-floor(f+.5));
  if(max(fe.x,fe.y)<.004)return colAt(t,floor(sp),n);
  vec2 w0=f*(-.5+f*(1.-.5*f)),w1=1.+f*f*(-2.5+1.5*f),w2=f*(.5+f*(2.-1.5*f)),w3=f*f*(-.5+.5*f);
  vec4 wx=vec4(w0.x,w1.x,w2.x,w3.x);
  vec4 c=crRow(t,tc-vec2(0,1),wx,n)*w0.y+crRow(t,tc,wx,n)*w1.y+crRow(t,tc+vec2(0,1),wx,n)*w2.y+crRow(t,tc+vec2(0,2),wx,n)*w3.y;
  return vec4(max(c.rgb,0.),clamp(c.a,0.,1.));
}
// how much live structure surrounds a sample (0 flat .. 1 busy): trails stay off it so the live image keeps its edges
float liveBusy(highp usampler2D t,vec2 uv){
  vec2 n=vec2(textureSize(t,0)),i=floor(uv*n);vec3 lw=vec3(.299,.587,.114);
  float a=dot(colAt(t,i+vec2(1,1),n).rgb,lw),b=dot(colAt(t,i-vec2(1,1),n).rgb,lw),c=dot(colAt(t,i+vec2(1,-1),n).rgb,lw),d=dot(colAt(t,i+vec2(-1,1),n).rgb,lw);
  float mx=max(max(a,b),max(c,d)),mn=min(min(a,b),min(c,d));
  return smoothstep(.12,.5,(mx-mn)/(mx+.08));
}
void main(){
  vec2 uv=gl_FragCoord.xy/uRes;vec2 asp=vec2(uRes.x/uRes.y,1.);
  vec2 p=(uv-.5)*asp;
  float r=length(p);
  vec3 lw=vec3(.299,.587,.114);
  // ---- trails: last frame, zoomed, turned, flowing like liquid, stirred by the pointer and sucked into the hole
  vec2 q=p*(1.-uZoomFb*(.5+.5*r));
  q=rot(uRotFb*(1.-.3*r))*q;
  // one evaluation of the flow field serves trails and live image (keeps the D3D compile of this pass small)
  vec2 flow=uFlow.x+uFlow.y>0.?flowField(p):vec2(0.);
  q+=uFlow.y*flow; // trails stream along the liquid's currents
  // marbling: trails flow along the contours of a blurred copy of the last frame (its luminance gradient turned 90 degrees)
  if(uCurl>0.){vec2 bq=q/asp+.5;vec2 g=vec2(texture(uBlur,bq+vec2(.012,0.)).a-texture(uBlur,bq-vec2(.012,0.)).a,texture(uBlur,bq+vec2(0.,.012)).a-texture(uBlur,bq-vec2(0.,.012)).a);q+=vec2(-g.y,g.x)*uCurl;}
  vec2 d=q-uMouse;float fall=exp(-dot(d,d)*9.)*uMouseV.w;
  q-=uMouseV.xy*fall;
  q=uMouse+rot(fall*(.006+.05*uMouseV.z))*(q-uMouse);
  q+=d*fall*.035*uMouseV.z;
  if(uHole.w>0.){vec2 hd=q-uHole.xy;float wide=exp(-dot(hd,hd)*1.2);q=uHole.xy+rot(wide*uHold*.045)*hd*(1.+wide*uHold*.012);}
  vec3 prev=prevAt(q,asp);
  // Droste: the whole previous frame nested inside its own centre, so the image regresses forever
  if(uDroste>0.){float dm=smoothstep(.34,.2,r)*uDroste;if(dm>0.)prev=mix(prev,prevAt(rot(.12)*p*2.618,asp)*1.08,dm);}
  prev=hueRot(prev,uHueStep)*uDecay;
  // ---- live image: breathing walls, beat pulse, pointer drag/swirl/lens, gravitational lensing round the hole
  vec2 lv=p;
  // Realm targets mirror at their edges, so no sample may leave the frame: the sway fades out toward the edges (the
  // field's length stays below ~2.3, and the fade width keeps the offset <= the distance to the edge), so nothing is
  // magnified and the interior maps 1:1 wherever the flow is still.
  float wamp=uFlow.x*2.3,toEdge=min(asp.x*.5-abs(p.x),.5-abs(p.y));
  lv+=uFlow.x*flow*smoothstep(0.,max(.04,1.5*wamp),toEdge);
  lv*=1.-uPulse*(1.-.4*r); // a pulse only ever pulls samples inward
  // a turned frame needs just enough magnification for its corners to stay inside: exactly 1 without spin
  if(uSpin!=0.){lv=rot(uSpin)*lv;float sc=abs(cos(uSpin)),ss=abs(sin(uSpin)),ha=asp.x*.5;lv*=min(ha/(ha*sc+.5*ss),.5/(ha*ss+.5*sc));}
  lv=mix(lv,uMouse,.045*uMouseV.w); // the whole field leans a little toward the pointer
  vec2 ld=lv-uMouse;float lf=exp(-dot(ld,ld)*7.)*uMouseV.w;
  lv-=uMouseVel*lf*.12;
  lv=uMouse+rot(lf*(.25+1.4*uMouseV.z))*(lv-uMouse);
  lv+=ld*lf*(.06+.25*uMouseV.z);
  float inside=0.;vec2 hv=vec2(0.);
  if(uHole.w>0.){
    vec2 hd=lv-uHole.xy;float hr=max(length(hd),1e-4);
    lv=uHole.xy+rot(exp(-hr*hr*2.)*uHold*1.2)*hd;
    lv-=hd/hr*min(uHole.z*uHole.z*1.6/hr,hr*.95)*uHole.w;
    inside=smoothstep(uHole.z*1.02,uHole.z*.88,hr)*uPeek;
    hv=uHole.xy+hd/max(uHole.z,1e-3)*.55*(1.+.4*(1.-hr/max(uHole.z,1e-3)));
  }
  // ---- realm transitions: a library of moves, each with its own sampling of the outgoing (A) and incoming (B) realm
  float sm=uMix*uMix*(3.-2.*uMix);
  vec2 la=lv,lb=lv;float m=0.,edge=0.,kFo=0.,kN=4.,kRo=0.;
  int st=int(uStyle+.5);
  if(uMix>0.){
    float n=vn(p*3.+uStyle*7.)*.6+vn(p*8.-uStyle*3.)*.4;
    if(st==0){ // PORTAL: a hole opens and the new realm rushes in out of the distance
      la=lv*(1.-.22*sm);lb=lv*(1.+.8*(1.-sm));
      float f=length(p-uTC)*.8+n*.06,e=uMix*1.35;
      m=1.-smoothstep(e-.1,e,f);edge=exp(-pow((f-e+.05)*28.,2.));
    }else if(st==1){ // VORTEX: the old realm drains into a whirlpool while the new one closes in from the rim
      float fall=1.-min(r*1.3,1.);
      la=rot(sm*sm*7.*fall)*lv*(1.+sm*1.6);
      lb=rot(-(1.-sm)*(1.-sm)*5.*fall)*lv*(1.-.45*(1.-sm));
      float f=1.25-r-.06*sin(atan(p.y,p.x)*5.+r*14.-uTime*2.),e=uMix*1.45;
      m=1.-smoothstep(e-.12,e,f);edge=exp(-pow((f-e+.06)*24.,2.));
    }else if(st==2){ // MELT: the old realm drips away and the new one shows through from above
      float g=vn(vec2(p.x*4.,uTime*.3))*.7+vn(vec2(p.x*11.,1.7))*.3;
      float f=(.55-p.y)*.75+g*.5,e=uMix*1.6;
      la=lv+vec2(.012*sin(p.y*20.+uTime*3.)*sm,-sm*sm*(.25+.5*g));
      m=1.-smoothstep(e-.08,e,f);edge=exp(-pow((f-e+.04)*35.,2.));
      // v21: a broad soft front and only a faint glow on it: a melt, not a line travelling down the screen
      e=uMix*1.75;m=1.-smoothstep(e-.34,e,f);edge=exp(-pow((f-e+.17)*8.,2.))*.3;
    }else if(st==3){ // SHATTER: hexagonal shards turn over one by one and fly into place
      vec2 hp=p*6.,hr=vec2(1.,1.7320508),ha=mod(hp,hr)-hr*.5,hb=mod(hp-hr*.5,hr)-hr*.5;
      vec2 hl=dot(ha,ha)<dot(hb,hb)?ha:hb,hc=(hp-hl)/6.;
      float c=clamp((uMix*1.7-h21(floor(hc*97.))*.45-length(hc)*.35)/.3,0.,1.);
      m=smoothstep(.45,.55,c);
      lb=hc+rot((1.-c)*2.4)*(lv-hc)*(1.+(1.-c)*2.);
      la=hc+rot(-c*1.2)*(lv-hc)*(1.+c*.6);
      edge=smoothstep(.07,0.,.5-max(dot(abs(hl),vec2(.5,.8660254)),abs(hl.x)))*c*(1.-c)*4.;
    }else if(st==4){ // LIGHT LEAK: the new realm floods in through the brightest light of the old one
      float LA=dot(colBil(uA,kal(lv,uSymA,uSymRot)/asp+.5).rgb,lw);
      float f=1.-clamp(LA*.55,0.,1.)*.75-n*.25,e=uMix*1.3;
      m=1.-smoothstep(e-.15,e,f);edge=exp(-pow((f-e+.08)*12.,2.))*.6;
    }else if(st==5){ // KALEIDO (v21): the picture dissolves into a turning kaleidoscope whose fold count glides up and back
      // down; inside it the old scene dissolves into the new one; then the kaleidoscope dissolves into the plain new scene.
      // The folded samples are taken after the plain ones (kFo, kN, kRo below): no coordinate blending, so nothing streaks.
      kFo=smoothstep(0.,.3,uMix)*(1.-smoothstep(.7,1.,uMix));
      kN=mix(3.,9.,sin(3.14159*uMix));kRo=sm*2.2;
      m=smoothstep(.3,.7,uMix+.14*(n-.5));
    }else if(st==6){ // DATAMOSH: blocks glitch across in sixteenth-note steps
      vec2 bc=floor(p*vec2(18.,10.)*(1.+floor(h21(vec2(floor(uTime*6.)))*3.)));
      float h=h21(bc+floor(uTime*8.)*.31),g=sin(3.14159*uMix);
      m=step(h21(bc),floor(uMix*12.)/12.*1.08);
      vec2 off=(vec2(h21(bc+3.1),h21(bc+7.7))-.5)*.12*g*step(.6,h);
      la=lv+off;lb=lv-off*.5;
      edge=step(.92,h)*g;
    }else if(st==8){ // DISSOLVE (v21): a soft organic cross-dissolve, both pictures whole and in place the entire time
      float f=.6*n+.4*clamp(r/(.5*length(asp)),0.,1.);
      m=smoothstep(0.,1.,uMix*1.7-.7*f);
    }else{ // CUT: straight across on the beat
      m=step(.02,uMix);
    }
  }
  vec2 ka=kal(la,uSymA,uSymRot)/asp+.5;
  vec4 At=sharpTex(uA,ka);
  vec2 kq=kFo>0.?kal(lv,kN,kRo)/asp+.5:ka;
  if(kFo>0.)At=mix(At,colBil(uA,kq),kFo);
  // v21 fold change within a visit. Fold to fold needs nothing here: uSymA itself glides (see foldUpdate). To or from the
  // unfolded view (or the plain mirror) it is a slow cross-dissolve that seeps outward from the centre: the soft band is
  // wider than the frame, so there is no edge, ring or wipe line, and both images are complete at every moment.
  if(uSymT<1.&&uMix<=0.){
    float f=clamp(r/(.5*length(asp)),0.,1.)+.22*(vn(p*2.3+uTime*.05)-.5);
    float w=smoothstep(0.,1.,uSymT*1.7-.7*f);
    vec4 A0=sharpTex(uA,kal(la,uSymA0,uSymRot2.y)/asp+.5);
    At=mix(A0,At,w);
  }
  vec3 A=At.rgb;float win=At.a;
  vec3 col=A;
  vec2 kb=ka;bool winB=false; // window coordinates are only unpacked where a window shows
  if(uMix>0.){
    kb=kal(lb,uSymB,uSymRot2.x)/asp+.5;
    vec4 Bt=sharpTex(uB,kb);
    if(kFo>0.)Bt=mix(Bt,colBil(uB,kq),kFo);
    vec3 B=Bt.rgb;
    col=mix(A,B,m);win=mix(win,Bt.a,m);winB=m>.5;
    if(st==6)col=mix(col,vec3(colBil(uA,ka+vec2(.006,0.)).r,col.g,colBil(uB,kb-vec2(.006,0.)).b),edge)+B*edge*.3;
    else col+=(B*.9+A*.3+vec3(.2))*edge*(1.-uMix*.5);
  }
  // build-up stutter: glimpses of the realm the drop is about to open, flickering in on the eighth notes
  if(uStut>0.)col=mix(col,colBil(uN,kal(lv,uSymA,uSymRot)/asp+.5).rgb*1.15,uStut);
  // windows: each one holds the whole last frame shrunk into it (so it nests forever), or the next realm
  if(win>.002&&uWin>0.){
    vec4 Wt=winB?winBil(uB,kb):winBil(uA,ka);
    vec2 wl=Wt.xy*2.-1.;
    float coverage=1.-smoothstep(.96,1.,max(abs(wl.x),abs(wl.y)));
    win*=coverage; // outside the local aperture, keep the actual scene instead of sampling black/edge pixels
    vec3 wc=Wt.z<.5?hueRot(prevAt(rot(.4+.25*sin(uTime*.11))*wl*.5,asp),.5)*.9:colBil(uN,wl*vec2(.5/asp.x,.5)+.5).rgb*1.1;
    col=mix(col,wc+col*.1,clamp(win*uWin,0.,1.));
  }
  if(inside>0.){vec3 pk=colBil(uB,kal(hv,uSymB,uSymRot2.x)/asp+.5).rgb;col=mix(col,pk*1.25,inside);}
  if(uRaw>.5){fragColor=vec4(A,1.);return;}
  // ---- echoes: bright features leave decaying copies that ride the feedback zoom outward; darkness fills with trails.
  // Motion-aware: over a moving camera a full-strength copy (max(live, echo)) ghosts every bright edge next to its live
  // self and reads as fuzz. An echo now only shows where it clearly outshines the live pixel, stays off live structure
  // (edges and texture keep their crispness), and is drawn as a softened glow, so streaks over dark space remain.
  float ls=dot(col,lw),lp=dot(prev,lw);
  vec3 echo=prev*smoothstep(.05,.3,lp);
  vec3 ec=echo*uEcho;float le=dot(ec,lw);
  float gate=smoothstep(.15,.65,(le-ls)/(le+.03));
  if(gate>0.){
    vec2 po=q/asp+.5,o=1.5/uRes;
    vec3 soft=(texture(uPrev,po+o).rgb+texture(uPrev,po-o).rgb+texture(uPrev,po+vec2(o.x,-o.y)).rgb+texture(uPrev,po+vec2(-o.x,o.y)).rgb)*.25;
    soft=hueRot(soft,uHueStep)*uDecay;
    vec3 glow=mix(ec,soft*smoothstep(.05,.3,dot(soft,lw))*uEcho,.4)*.9;
    float busy=m>.5?liveBusy(uB,kb):liveBusy(uA,ka);
    col+=max(glow-col,0.)*gate*(1.-.8*busy);
  }
  col+=echo*(1.-smoothstep(.0,.14,ls))*(1.-uEcho*.6)*.42+prev*.004;
  if(any(isnan(col))||any(isinf(col)))col=vec3(0.);
  fragColor=vec4(min(col,vec3(16.)),1.);
}`;

const FS_DOWN = `#version 300 es
precision highp float;
uniform sampler2D uTex;uniform vec2 uRes,uTexel;uniform float uThresh,uPre;
out vec4 fragColor;
// alpha carries encoded log-luminance down the chain, so the smallest level is a smooth exposure meter
void main(){
  vec2 uv=gl_FragCoord.xy/uRes;
  vec4 t=texture(uTex,uv+uTexel*vec2(-1.,-1.))+texture(uTex,uv+uTexel*vec2(1.,-1.))+texture(uTex,uv+uTexel*vec2(-1.,1.))+texture(uTex,uv+uTexel*vec2(1.,1.));
  t*=.25;
  vec3 c=t.rgb;float a=t.a;
  if(uPre>.5){
    a=clamp((log(dot(c,vec3(.2126,.7152,.0722))+.02)+4.)/6.,0.,1.);
    float br=max(c.r,max(c.g,c.b));float kn=uThresh*.5;float s=clamp(br-uThresh+kn,0.,2.*kn);s=s*s/(4.*kn+1e-4);c*=max(s,br-uThresh)/max(br,1e-4);
  }
  fragColor=vec4(c,a);
}`;

const FS_UP = `#version 300 es
precision highp float;
uniform sampler2D uTex,uBase;uniform vec2 uRes,uTexel;
out vec4 fragColor;
void main(){
  vec2 uv=gl_FragCoord.xy/uRes;
  vec3 s=texture(uTex,uv).rgb*4.;
  s+=(texture(uTex,uv+uTexel*vec2(-1.,0.)).rgb+texture(uTex,uv+uTexel*vec2(1.,0.)).rgb+texture(uTex,uv+uTexel*vec2(0.,-1.)).rgb+texture(uTex,uv+uTexel*vec2(0.,1.)).rgb)*2.;
  s+=texture(uTex,uv+uTexel*vec2(-1.,-1.)).rgb+texture(uTex,uv+uTexel*vec2(1.,-1.)).rgb+texture(uTex,uv+uTexel*vec2(-1.,1.)).rgb+texture(uTex,uv+uTexel*vec2(1.,1.)).rgb;
  fragColor=vec4(texture(uBase,uv).rgb+s*(.65/16.),1.); // ENGINE v23: wider levels weigh less (was a plain sum = a veil)
}`;

/* Upscaler, after AMD FidelityFX Super Resolution 1 (EASU). Below native resolution (Auto, Medium, Low) the scene used
   to be stretched to the screen with one bilinear tap, which smeared it. This 12-tap edge-adaptive filter measures
   the local gradient direction and stretches a Lanczos-like kernel along edges (sharp across them, smooth along
   them), then clamps to the nearest 2x2 texels so it cannot ring. HDR in, HDR out: edge analysis uses a tone-
   compressed luma. The composite's RCAS pass then sharpens at screen resolution. */
const FS_EASU = `#version 300 es
precision highp float;
uniform sampler2D uSrc;
uniform vec2 uRes;
out vec4 fragColor;
vec3 tap(ivec2 p,ivec2 mx){return texelFetch(uSrc,clamp(p,ivec2(0),mx),0).rgb;}
float lum(vec3 c){c/=1.+c;return c.b*.5+(c.r*.5+c.g);}
// accumulate gradient direction and edge length for one of the four bilinear neighbours
void easuSet(inout vec2 dir,inout float len,float w,float lA,float lB,float lC,float lD,float lE){
  float lenX=max(abs(lD-lC),abs(lC-lB)),dirX=lD-lB;
  dir.x+=dirX*w;lenX=clamp(abs(dirX)/max(lenX,1e-6),0.,1.);len+=lenX*lenX*w;
  float lenY=max(abs(lE-lC),abs(lC-lA)),dirY=lE-lA;
  dir.y+=dirY*w;lenY=clamp(abs(dirY)/max(lenY,1e-6),0.,1.);len+=lenY*lenY*w;
}
void easuTap(inout vec3 aC,inout float aW,vec2 off,vec2 dir,vec2 len2,float lob,float clp,vec3 c){
  vec2 v=vec2(dot(off,dir),dot(off,vec2(-dir.y,dir.x)))*len2;
  float d2=min(dot(v,v),clp);
  float wB=.4*d2-1.,wA=lob*d2-1.;wB*=wB;wA*=wA;wB=1.5625*wB-.5625;
  float w=wB*wA;aC+=c*w;aW+=w;
}
void main(){
  vec2 src=vec2(textureSize(uSrc,0)),pp=gl_FragCoord.xy*src/uRes-.5,fp=floor(pp);pp-=fp;
  ivec2 i=ivec2(fp),mx=ivec2(src)-1;
  //    b c
  //  e f g h
  //  i j k l
  //    n o
  vec3 b=tap(i+ivec2(0,-1),mx),c=tap(i+ivec2(1,-1),mx),e=tap(i+ivec2(-1,0),mx),f=tap(i,mx),g=tap(i+ivec2(1,0),mx),h=tap(i+ivec2(2,0),mx),
       ti=tap(i+ivec2(-1,1),mx),j=tap(i+ivec2(0,1),mx),k=tap(i+ivec2(1,1),mx),l=tap(i+ivec2(2,1),mx),n=tap(i+ivec2(0,2),mx),o=tap(i+ivec2(1,2),mx);
  float bL=lum(b),cL=lum(c),eL=lum(e),fL=lum(f),gL=lum(g),hL=lum(h),iL=lum(ti),jL=lum(j),kL=lum(k),lL=lum(l),nL=lum(n),oL=lum(o);
  vec2 dir=vec2(0.);float len=0.;
  easuSet(dir,len,(1.-pp.x)*(1.-pp.y),bL,eL,fL,gL,jL);
  easuSet(dir,len,pp.x*(1.-pp.y),cL,fL,gL,hL,kL);
  easuSet(dir,len,(1.-pp.x)*pp.y,fL,iL,jL,kL,nL);
  easuSet(dir,len,pp.x*pp.y,gL,jL,kL,lL,oL);
  float dirR=dot(dir,dir);
  dir=dirR<1./32768.?vec2(1.,0.):dir*inversesqrt(dirR);
  len*=.5;len*=len;
  float stretch=1./max(abs(dir.x),abs(dir.y));
  vec2 len2=vec2(1.+(stretch-1.)*len,1.-.5*len);
  float lob=.5+(.21-.5)*len,clp=1./lob;
  vec3 aC=vec3(0.);float aW=0.;
  easuTap(aC,aW,vec2(0.,-1.)-pp,dir,len2,lob,clp,b);easuTap(aC,aW,vec2(1.,-1.)-pp,dir,len2,lob,clp,c);
  easuTap(aC,aW,vec2(-1.,1.)-pp,dir,len2,lob,clp,ti);easuTap(aC,aW,vec2(0.,1.)-pp,dir,len2,lob,clp,j);
  easuTap(aC,aW,vec2(0.,0.)-pp,dir,len2,lob,clp,f);easuTap(aC,aW,vec2(-1.,0.)-pp,dir,len2,lob,clp,e);
  easuTap(aC,aW,vec2(1.,1.)-pp,dir,len2,lob,clp,k);easuTap(aC,aW,vec2(2.,1.)-pp,dir,len2,lob,clp,l);
  easuTap(aC,aW,vec2(2.,0.)-pp,dir,len2,lob,clp,h);easuTap(aC,aW,vec2(1.,0.)-pp,dir,len2,lob,clp,g);
  easuTap(aC,aW,vec2(1.,2.)-pp,dir,len2,lob,clp,o);easuTap(aC,aW,vec2(0.,2.)-pp,dir,len2,lob,clp,n);
  vec3 lo=min(min(f,g),min(j,k)),hi=max(max(f,g),max(j,k));
  vec3 col=clamp(aC/max(aW,1e-5),lo,hi);
  if(any(isnan(col)))col=f;
  fragColor=vec4(col,1.);
}`;

const FS_COMPOSITE = `#version 300 es
precision highp float;
uniform sampler2D uFb,uBloom,uExpo;
uniform float uBridgeW; // v22 brightness bridge weight (see EXPO_FAST)
uniform vec2 uRes,uFbTexel;
uniform float uTime,uChroma,uBloomAmt,uFlash,uVig,uKick,uSat,uExposure,uSharp,uPeek,uKey,uPack,uSS;
uniform vec4 uWaves[6];
uniform vec4 uHole;
out vec4 fragColor;
float h21(vec2 p){vec3 q=fract(p.xyx*.1031);q+=dot(q,q.yzx+33.33);return fract((q.x+q.y)*q.z);}
vec3 aces(vec3 c){return clamp((c*(2.51*c+.03))/(c*(2.43*c+.59)+.14),0.,1.);}
void main(){
  vec2 uv=gl_FragCoord.xy/uRes;vec2 asp=vec2(uRes.x/uRes.y,1.);
  vec2 p=(uv-.5)*asp;
  float ring=0.;
  for(int i=0;i<6;i++){
    vec4 w=uWaves[i];if(w.w<=0.)continue;
    vec2 d=p-w.xy;float rr=length(d)+1e-5;
    float x=rr-w.z;
    float a=w.w*exp(-x*x*70.)*smoothstep(.0,.2,w.z); // grows in from the centre instead of a blob
    p-=d/rr*a*.05;ring+=a;
  }
  uv=p/asp+.5;
  vec2 cd=uv-.5;
  float ca=uChroma*(.0012+.008*uKick+.008*ring)*(.3+length(cd)*1.4);
  vec3 cc=texture(uFb,uv).rgb;
  // supersampled frames: average a 2x2 footprint of the larger render instead of one bilinear tap
  if(uSS>0.){vec2 o=vec2(uSS)/uRes;cc=(texture(uFb,uv+o*vec2(-1.,-1.)).rgb+texture(uFb,uv+o*vec2(1.,-1.)).rgb+texture(uFb,uv+o*vec2(-1.,1.)).rgb+texture(uFb,uv+o*vec2(1.,1.)).rgb)*.25;}
  vec3 c=vec3(texture(uFb,uv-cd*ca).r,cc.g,texture(uFb,uv+cd*ca).b);
  if(uSS>0.)c=mix(cc,c,clamp(ca*400.,0.,1.));
  // Contrast-adaptive sharpening after FSR1's RCAS, at screen resolution (after the EASU upscale when there is one).
  // The negative lobe is limited per pixel by the local min/max, so detail sharpens without halos and flat or noisy
  // areas are left alone. It runs on a tone-compressed copy (x/(1+x)) so HDR highlights behave like display values,
  // and it is applied as a luminance ratio, so the prism split stays clean. uSharp: 0 off .. 1 full strength.
  if(uSharp>0.){
    vec3 nN=texture(uFb,uv+vec2(0.,uFbTexel.y)).rgb,nS=texture(uFb,uv-vec2(0.,uFbTexel.y)).rgb,nE=texture(uFb,uv+vec2(uFbTexel.x,0.)).rgb,nW=texture(uFb,uv-vec2(uFbTexel.x,0.)).rgb;
    vec3 b=nN/(1.+nN),d=nW/(1.+nW),e=cc/(1.+cc),f=nE/(1.+nE),h=nS/(1.+nS);
    vec3 mn4=min(min(b,d),min(f,h)),mx4=max(max(b,d),max(f,h));
    vec3 lobe3=max(-mn4/(4.*mx4+1e-5),(1.-mx4)/(4.*mn4-4.));
    float lobe=max(-.1875,min(max(lobe3.r,max(lobe3.g,lobe3.b)),0.))*uSharp;
    vec3 lw=vec3(.5,1.,.5);float bL=dot(b,lw),dL=dot(d,lw),eL=dot(e,lw),fL=dot(f,lw),hL=dot(h,lw);
    float nz=abs(.25*(bL+dL+fL+hL)-eL)/(max(max(max(bL,dL),max(fL,hL)),eL)-min(min(min(bL,dL),min(fL,hL)),eL)+1e-5);
    lobe*=1.-.5*clamp(nz,0.,1.); // a lone speck that differs from all four neighbours is noise, not an edge
    vec3 s=clamp((lobe*(b+d+f+h)+e)/(4.*lobe+1.),0.,.995);s/=1.-s;
    vec3 lr=vec3(.2126,.7152,.0722);
    c*=clamp((dot(s,lr)+.002)/(dot(cc,lr)+.002),0.,3.);
  }
  // ENGINE v23 anti-washout: glow and shock rings are light, but they must not lay grey over colour. The glow gets a toe
  // of its own (a faint wide veil drops away, the halo of a real highlight stays), and on a lit pixel glow and ring are
  // delivered as a gain along that pixel's own hue (same added luminance) instead of being added on top, which raised
  // its smallest channel and turned it pale. Over ink they still add, so a highlight keeps its halo.
  vec3 gw=texture(uBloom,uv).rgb*uBloomAmt;
  float gL=dot(gw,vec3(.2126,.7152,.0722));
  gw*=gL/(gL+.04);
  gw+=ring*(.5+.5*cos(6.2831*(vec3(0.,.33,.67)+length(p)*2.-uTime*.5)))*.45;
  float cL=dot(c,vec3(.2126,.7152,.0722)),wL=dot(gw,vec3(.2126,.7152,.0722));
  c=mix(c+gw,c*(1.+wL/max(cL,1e-4)),smoothstep(.1,.5,cL));
  if(uHole.w>0.){
    vec2 hd=p-uHole.xy;float hr=length(hd),rs=uHole.z;
    float ha=atan(hd.y,hd.x);
    c*=mix(1.,smoothstep(rs*.82,rs*1.05,hr),uHole.w*(1.-uPeek));
    float disk=exp(-pow((hr-rs*1.3)/(rs*.3),2.))*(.6+.4*sin(ha*3.-uTime*7.+hr*40.));
    c+=(.5+.5*cos(6.2831*(vec3(0.,.33,.67)+ha*.159+uTime*.4)))*disk*uHole.w*2.8;
  }
  // auto exposure keeps bright realms from going milky and dark ones from sinking
  vec4 ev=texture(uExpo,vec2(.5));
  float avgL=exp((uPack>.5?ev.r+ev.g/255.:ev.r)*6.-4.)-.02;
  float ex=mix(1.,clamp(uKey/max(avgL,1e-3),.6,1.3),.75);
  if(uBridgeW>0.){float ref=exp(ev.b*6.-4.)-.02;ex*=mix(1.,clamp(ref/max(ex*avgL,1e-3),1.,1.5),uBridgeW);} // v22: a darker incoming scene starts at the outgoing level
  // ENGINE v23: the drop / kick / build pump lands in full on dark and mid frames; on a frame that already sits well above
  // the key it is cut to 45 %, so a bright scene is not blown further toward white
  float pump=uExposure*(1.+uFlash*1.6)-1.;
  pump*=1.-.55*smoothstep(uKey*1.05,uKey*2.2,ex*avgL);
  c*=ex*(1.+pump);
  // hue-preserving tone curve on luminance, rolling only the hottest highlights toward white
  float L=dot(c,vec3(.2126,.7152,.0722));
  c*=L/(L+.025);L*=L/(L+.025); // toe: shadows sink to black, mids barely move
  float Lt=aces(vec3(L)).r;
  vec3 hp=c*(Lt/max(L,1e-4));
  float mx=max(hp.r,max(hp.g,hp.b));
  hp/=max(mx,1.);
  c=mix(hp,aces(c),smoothstep(1.4,5.,L)*.45); // ENGINE v23: was from Lt .55 up (most of the lit picture), toward white = pale
  float l=dot(c,vec3(.2126,.7152,.0722));
  c=mix(vec3(l),c,uSat);
  c*=1.-uVig*dot(cd*asp,cd*asp)*.9;
  c=max(c,0.);c/=max(1.,max(c.r,max(c.g,c.b))); // ENGINE v23: scale the vector, never clip one channel
  c+=(h21(gl_FragCoord.xy+fract(uTime*7.)*91.)-.5)/255.*1.5;
  fragColor=vec4(clamp(c,0.,1.),1.);
}`;

/* Exposure meter: a 1x1 target that tracks, over time, the log-average luminance carried in the alpha of the
   smallest bloom level. On 8-bit targets the value is split over two channels so slow blending still moves it. */
const FS_SHADOW_COMPOSITE = FS_COMPOSITE
  .replace("uniform float uTime,uChroma,uBloomAmt,uFlash,uVig,uKick,uSat,uExposure,uSharp,uPeek,uKey,uPack,uSS;","uniform float uTime,uChroma,uBloomAmt,uFlash,uVig,uKick,uSat,uExposure,uSharp,uPeek,uKey,uPack,uSS,uShadowRecovery;")
  .replace("  c+=(h21(gl_FragCoord.xy+fract(uTime*7.)*91.)-.5)/255.*1.5;","  if(uShadowRecovery>0.){\n    float recovery=clamp(uShadowRecovery,0.,1.)*(1.-smoothstep(.10,.20,avgL));\n    if(recovery>0.){\n      vec3 q=clamp(c,0.,1.);\n      vec3 srgb=mix(12.92*q,1.055*pow(q,vec3(1./2.4))-.055,step(vec3(.0031308),q));\n      c=mix(q,srgb,recovery);\n    }\n  }\n  c+=(h21(gl_FragCoord.xy+fract(uTime*7.)*91.)-.5)/255.*1.5;");

const FS_EXPO = `#version 300 es
precision highp float;
uniform sampler2D uSrc,uPrevE;uniform float uRate,uPack,uRef,uKey;
out vec4 fragColor;
void main(){
  float s=0.;
  for(int y=0;y<6;y++)for(int x=0;x<10;x++)s+=texture(uSrc,(vec2(x,y)+.5)/vec2(10.,6.)).a;
  vec4 pe=texture(uPrevE,vec2(.5));
  float p=uPack>.5?pe.r+pe.g/255.:pe.r;
  float v=mix(p,s/60.,uRate);
  // v22 brightness bridge: on the first frame of a scene change keep the outgoing scene's screen level (gain x average, as the
  // composite computes it, log-encoded like v) in the third channel; otherwise carry it on
  float aL=exp(p*6.-4.)-.02,ex=mix(1.,clamp(uKey/max(aL,1e-3),.6,1.3),.75);
  float ref=uRef>.5?clamp((log(max(ex*aL,1e-3)+.02)+4.)/6.,0.,1.):pe.b;
  if(uPack>.5){float hi=floor(v*255.)/255.;fragColor=vec4(hi,(v-hi)*255.,ref,1.);}
  else fragColor=vec4(v,0.,ref,1.);
}`;

