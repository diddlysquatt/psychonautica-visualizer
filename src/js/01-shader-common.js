/* =============================== GLSL ================================ */
/* ADRENO FIX (packed realm targets): driver-independent float<->half conversion, used instead of packHalf2x16 /
   unpackHalf2x16 by the realm programs' packed main and by FS_FEEDBACK. A Samsung S25 (Adreno 830) showed only the
   blue channel; this path uses plain highp integer bit ops only. Rounds to nearest, clamps to +-65504, flushes half
   denormals to 0, NaN -> 0. Keep the realm and feedback sides on these same helpers. */
const HALF_GLSL = `
highp uint hvF2H(highp float f){
  highp uint x=floatBitsToUint(f),s=(x>>16)&0x8000u,e=(x>>23)&0xffu,m=x&0x7fffffu;
  if(e==255u)return m!=0u?0u:(s|0x7bffu);
  if(e<113u)return s;
  highp uint h=((e-112u)<<10)|(m>>13);
  h+=(m>>12)&1u;
  return s|min(h,0x7bffu);
}
highp float hvH2F(highp uint h){
  highp uint e=(h>>10)&0x1fu;
  if(e==0u||e==31u)return 0.;
  return uintBitsToFloat(((h&0x8000u)<<16)|((e+112u)<<23)|((h&0x3ffu)<<13));
}
highp uint hvPack(highp vec2 v){return hvF2H(v.x)|(hvF2H(v.y)<<16);}
highp vec2 hvUnpack(highp uint u){return vec2(hvH2F(u&0xffffu),hvH2F(u>>16));}
`;
const VS = `#version 300 es
void main(){vec2 p=vec2(float((gl_VertexID<<1)&2),float(gl_VertexID&2));gl_Position=vec4(p*2.-1.,0.,1.);}`;

const COMMON = `#version 300 es
precision highp float;
precision highp int;
#ifndef HD
#define HD 0
#endif
uniform vec2 uRes;
uniform float uTime,uMT,uZoom,uDose,uHue,uDetail;
// uSmooth: the Motion smoothness dial 0..1 (0 for MUMM3). Ease your own geometry/camera motion by it.
uniform float uSmooth;
uniform float uSub,uBass,uMid,uHigh,uLevel,uKick,uHit,uHat;
uniform float uBeat,uBar,uDrop,uBuild;
// v22 music structure (see ENGINE v22 in the realm contract): uImpact decays from the strength of the last big arrival,
// uTension 0..1 rises before one, uEnergy absolute loudness 0..1, uSecAge seconds since the section began, uSection its
// counter, uBarPh / uPhrase position in the musical bar / phrase 0..1, uNote melodic onsets, uSwell slow envelope 0..1.
uniform float uImpact,uTension,uEnergy,uSecAge,uSection,uBarPh,uPhrase,uNote,uSwell;
// 8 log-frequency bands (28 Hz..16 kHz), auto-ranged 0..1: uB1 = sub,bass,lowmid,mid; uB2 = himid,presence,high,air.
// uO1/uO2: per-band onset pulses (1 on a sharp rise in that band, decaying over ~0.15 s).
uniform vec4 uB1,uB2,uO1,uO2;
uniform vec4 uSeed,uVar,uP1,uP2,uP3,uP4,uP5;
uniform mat3 uM1,uM2;
uniform vec3 uPa,uPb,uPc,uPd,uQa,uQb,uQc,uQd;
uniform float uPalT;
uniform vec2 uMouse,uLook;
uniform vec4 uMouseV;
uniform sampler2D uSpec;
layout(location=0) out vec4 fragColor; // rgb = HDR colour, a = window mask (0..1)
layout(location=1) out vec4 fragWin;   // xy = window-local coords*.5+.5 (|local|<=1 inside a window), z = window kind (0 nest, 1 next realm)
#define PI 3.14159265
#define TAU 6.28318531
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}
float h11(float p){p=fract(p*.1031);p*=p+33.33;p*=p+p;return fract(p);}
float h21(vec2 p){vec3 q=fract(p.xyx*.1031);q+=dot(q,q.yzx+33.33);return fract((q.x+q.y)*q.z);}
float vnoise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h21(i),h21(i+vec2(1,0)),f.x),mix(h21(i+vec2(0,1)),h21(i+vec2(1,1)),f.x),f.y);}
// current palette; during a palette change the two palettes' colours are mixed with their chroma kept, so a fade never greys out
vec3 pal(float t){
  vec3 a=uPa+uPb*cos(TAU*(uPc*t+uPd+uHue));
  if(uPalT<=0.)return a;
  vec3 b=uQa+uQb*cos(TAU*(uQc*t+uQd+uHue)),m=mix(a,b,uPalT);
  float la=dot(a,vec3(.3333)),lb=dot(b,vec3(.3333)),lm=dot(m,vec3(.3333));
  float cm=length(m-lm),ct=mix(length(a-la),length(b-lb),uPalT);
  return max(lm+(m-lm)*min(ct/max(cm,1e-3),4.),0.);
}
float spec(float x){return textureLod(uSpec,vec2(clamp(x,.002,.998),.25),0.).r;}
vec2 scr(){return (gl_FragCoord.xy-.5*uRes)/uRes.y;}
vec2 lens(vec2 p){return p;} // pointer distortion now happens in the compose pass
// Shared alien filigree: Kali's inversion fold with a pixel-footprint cutoff, so it adds detail without aliasing.
// p: surface coordinates, px: pixel size in p units, sd: per-surface seed. Returns line coverage 0..1.
float orn(vec2 p,float px,float sd){
  vec2 z=p,c=vec2(.74+.12*sin(sd*6.3),.5+.12*cos(sd*4.1));
  float ds=1.,best=1e3,bw=px,md=fract(sd*3.7+uSeed.z);
  for(int i=0;i<32;i++){
    if(float(i)>=8.+4.*log2(max(uDetail,1.)))break;
    float r2=max(dot(z,z),1e-4);z=abs(z)/r2-c;ds/=r2;
    float pw=px*ds;if(pw>.14)break;
    float t=md<.34?min(abs(length(z)-.5),min(abs(z.x),abs(z.y))*1.6):(md<.67?abs(abs(z.x)+abs(z.y)-.62):abs(max(abs(z.x)*.866+abs(z.y)*.5,abs(z.y))-.45));
    if(t<best){best=t;bw=pw;}
  }
  return smoothstep(bw*2.2+.003,0.,best);
}
vec2 cmul(vec2 a,vec2 b){return vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x);}
vec2 cdiv(vec2 a,vec2 b){return vec2(a.x*b.x+a.y*b.y,a.y*b.x-a.x*b.y)/dot(b,b);}
`;

