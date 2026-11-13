/* TEMPLATE: an endless flower. Rings of petals in log-polar space; each ring listens to one of the 8 frequency bands.
   This file is JavaScript: it declares the scene's GLSL as a template string. Rules for the string:
   - never type a backtick or a dollar sign followed by an opening brace inside it, not even in a comment;
   - it must define  void realm()  and write fragColor (rgb = linear HDR colour, a = 0 unless you use windows);
   - the engine puts its own header in front (uniforms, pal(), spec(), scr(), hashes, rot(), orn(): see
     docs/SCENE-CONTRACT.md), so do not declare uniforms or a #version line here.
   What frame() in entry.js sends to this shader:
     uP1 = (travel in rings 0..8, twist in petal cells 0..1, petal count, hue offset)
     uP2 = (seconds since the last kick, how open the petals are 0..1, 0, 0) */
const R_TEMPLATE = `
// Level and onset pulse of band i (0 = sub ... 7 = air) without indexing a vector by a variable:
// masks and dot products compile fast everywhere (see docs/PITFALLS.md).
float tpBand(float i){
  vec4 a=step(abs(vec4(0.,1.,2.,3.)-i),vec4(.5)),b=step(abs(vec4(4.,5.,6.,7.)-i),vec4(.5));
  return dot(uB1,a)+dot(uB2,b);
}
float tpOnset(float i){
  vec4 a=step(abs(vec4(0.,1.,2.,3.)-i),vec4(.5)),b=step(abs(vec4(4.,5.,6.,7.)-i),vec4(.5));
  return dot(uO1,a)+dot(uO2,b);
}
void realm(){
  // 1. COORDINATES. scr() is centred with the screen height = 1. Dividing by uZoom is the zoom contract:
  //    1 = this scene's own default framing, smaller = further out. The Auto Show moves uZoom between the
  //    far / home / close values of this scene's "show" row; the wheel and pinch go from 0.15 to 2.5.
  vec2 p=scr()/uZoom;
  float r=max(length(p),1e-4),a=atan(p.y,p.x);
  float px=1./(uRes.y*uZoom);            // the size of one pixel in p units: every edge below is anti-aliased with it

  // 2. STRUCTURE. log(r) turns "twice as far out" into "one step": rings repeat for ever, inward and outward,
  //    so the picture is full at every zoom (zoomed out you simply see more rings: scale without emptiness).
  float k=1.7;                            // rings per e-fold of radius
  float l=log(r)*k-uP1.x;                 // uP1.x grows with the music's travel: rings flow outward
  float ring=floor(l),f=fract(l);         // which ring, and 0..1 across it (inner edge to outer edge)
  float band=mod(ring,8.);                // this ring's frequency band
  float lv=tpBand(band),on=tpOnset(band);
  float odd=mod(ring,2.)*2.-1.;           // neighbouring rings turn opposite ways
  float n=uP1.z;                          // petals per ring (a whole number, so the ring closes without a seam)
  float u=(a/TAU+.5)*n+odd*uP1.y+.5*ring;
  float cu=abs(fract(u)-.5)*2.;           // 0 on a petal's axis, 1 half way to the next petal

  // 3. ONE PETAL: a pointed oval. Its width follows the music (uP2.y from frame(), and this ring's band).
  float w=uP2.y*(.45+.6*lv)*max(sin(PI*f),0.);
  float d=cu-w;                           // below 0 inside the petal
  float pu=px*n/(PI*r),pf=px*k/r;         // one pixel measured in cu units and in f units
  float aw=pu+2.*pf+1e-4;                 // anti-aliasing width for d
  float fill=smoothstep(aw,-aw,d);
  float shade=smoothstep(0.,.4,-d);       // 0 at the petal's rim, 1 inside: the rim stays dark (ink between colours)
  float vein=smoothstep(aw+.035,0.,cu)*fill*smoothstep(.1,.3,f)*smoothstep(.95,.7,f);

  // 4. COLOUR. pal() is the engine's current palette (it drifts and changes with the music). Squaring deepens it.
  vec3 base=pal(band/8.+uP1.w+.12*cu);base*=base*1.25;
  vec3 hot=pal(band/8.+uP1.w+.5);
  vec3 ink=vec3(.012,.014,.03)+base*.03*lv;
  // every band lights its own ring; its onset pulse (a sharp rise in that band) adds a flash of the same hue
  vec3 col=base*(.2+1.2*lv+.8*on)*(.3+.7*shade);
  // kick: a ripple of light travels outward through the rings (uP2.x = seconds since the kick)
  float q=log(r)*k+2.-uP2.x*6.;
  col+=base*1.3*exp(-q*q*3.)*exp(-uP2.x*2.5)*uDose;
  // snare: the veins flash (uHit is the snare envelope, already scaled by the Energy and Flashes settings)
  col+=hot*vein*(.35+1.6*uHit);
#if HD>=1
  // Native quality and above only (never compiled on phones): engraved filigree inside each petal.
  col+=base*.55*orn(vec2(cu*1.3,f*2.-1.)*1.2+ring,max(pu,pf)*1.3,ring*.37)*shade;
#endif
  col=mix(ink,col,fill);
  // hats and the top bands: every petal's rim lights up, and a bead between the petals swells
  float hat=max(uHat,max(uO2.z,uO2.w));
  col+=hot*hat*.9*smoothstep(.16,0.,abs(d))*smoothstep(aw*2.,0.,d);
  float bd=length(vec2((1.-cu)*.5*TAU*r/n,(f-.5)*r/k)),br=r*(.02+.05*hat);
  col=mix(col,hot*(.35+2.2*hat),smoothstep(br+px,br-px,bd));
  // a big arrival in the music (drop, band coming in) lifts the whole flower: scale the vector, keep the hue
  col*=1.+.7*uImpact;
  // 5. NEVER SPECKLE. Near the centre the rings become smaller than a pixel: fade them into ink instead of noise.
  col=mix(ink,col,smoothstep(.5,.16,pf+.25*pu));
  fragColor=vec4(col,0.);
}`;
