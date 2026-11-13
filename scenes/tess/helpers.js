// TESS4 polytope sets [hero, inner, satellites]: 0 tesseract, 1 16-cell, 2 24-cell, 3 6-6 duoprism, 4 5-cell,
// 7 600-cell Hopf decagons, 8 Hopf keyrings, 9 8-8 duoprism (a tesseract hero can unfold into its net)
const tessSets=[[0,2,1],[2,0,1],[3,0,4],[0,1,4],[2,1,0],[0,4,1],[0,2,4],[1,2,0],[0,3,1],[2,4,0],[7,0,1],[7,2,4],[8,1,0],[8,0,4],[9,1,0],[9,4,1],[0,7,1],[2,8,4],[0,9,4]];
// TESS4 palette weights: 0 synth, 1 acid, 2 ember, 3 ice, 4 toxic, 5 infra, 6 aurora, 7 tropic, 8 rainbow, 9 solar, 10 prism
// (warm and full-spectrum palettes come up most; the cool ice/aurora pair is rarer)
const tessPalW=[0,1,2,4,7,8,8,9,9,10,10,6,3,5,1,2,4,7];
// TESS4 4D rotation choreographies: rates (radians per beat) on the planes [XY, XZ, XW, YZ, YW, ZW] and the two planes kicks push
const tessModes=[
  {r:[0,0,.3,.2,0,0],k:[2,3]},        // double rotation XW + YZ: the classic tesseract turning inside out
  {r:[0,0,.27,.27,0,0],k:[2,3]},      // isoclinic (Clifford) rotation: every vertex runs on a Hopf circle
  {r:[.05,0,.4,0,0,0],k:[2,0]},       // simple XW rotation: the inner cube swells through the outer one
  {r:[.22,0,0,0,0,.3],k:[5,0]},       // XY + ZW counter-turn
  {r:[0,0,.2,0,.15,.1],k:[2,4]},      // spiral: the w axis sweeps round
  {r:[.08,.14,0,0,.26,0],k:[4,1]},    // tumble: YW with a slow 3D roll
  {r:[0,0,0,.08,.42,0],k:[4,3],pend:1}, // pendulum: YW swings back and forth with the bar
  {r:[.12,0,.3,0,0,.18],k:[2,5]},     // v11 triple: XY + XW + ZW, a slow kaleidoscopic churn
  {r:[0,.2,0,0,0,.32],k:[1,5]}        // v11 XZ + ZW: the body rolls in 3D while its w-depth turns over
];
// TESS4 apply a rotation by angle a in plane p to the 4x4 column-major matrix M (right multiply)
function tessGivens(M,p,a){
  const P=[[0,1],[0,2],[0,3],[1,2],[1,3],[2,3]][p],i=P[0],j=P[1],c=Math.cos(a),s=Math.sin(a);
  for(let r=0;r<4;r++){const x=M[i*4+r],y=M[j*4+r];M[i*4+r]=x*c+y*s;M[j*4+r]=y*c-x*s;}
}
// TESS4 re-orthonormalise the columns (Gram-Schmidt), keeping the matrix a proper rotation
function tessOrtho(M){
  for(let i=0;i<4;i++){
    for(let k=0;k<i;k++){let d=0;for(let r=0;r<4;r++)d+=M[i*4+r]*M[k*4+r];for(let r=0;r<4;r++)M[i*4+r]-=d*M[k*4+r];}
    let l=0;for(let r=0;r<4;r++)l+=M[i*4+r]*M[i*4+r];l=Math.sqrt(l)||1;for(let r=0;r<4;r++)M[i*4+r]/=l;
  }
}
// TESS4 hand-curated palettes, four colours each, neighbours chosen to blend without greying:
// synth, acid, ember, ice, toxic, infra, aurora, tropic, rainbow, solar, prism
const tessPals=[[0xff2a9d,0x9b45ff,0x22d8ff,0xffb020],[0xc6ff1a,0x1affc6,0x2a7bff,0xff2fae],[0xffcf3a,0xff4f1f,0xff2d8a,0x2ee8ff],
  [0x4ff0ff,0x2f6bff,0xb04dff,0xff4fd8],[0x3dff7a,0xf2ff3a,0xff3a8c,0x3ad1ff],[0xff5a5a,0xff3df0,0x5b3dff,0x3dffd9],
  [0x2affb8,0x18c8ff,0x6a3dff,0xd84dff],[0xff3d6e,0xffa31a,0x19e3c8,0x7a4dff],
  [0x30ff6a,0xffc81a,0xff3050,0x3a7aff],[0xffd21a,0xff8a1a,0xff3a7a,0xb8ff2a],[0x7a5cff,0xff3df2,0xffe03a,0x3affd8]];
// TESS4 colour k of the cross-fade from palette a to b (m 0..1), hue-turned by hr, packed as a 24-bit int (gamma 2 on the wire)
function tessCol(a,b,m,k,hr){
  const un=(h)=>[((h>>16)&255)/255,((h>>8)&255)/255,(h&255)/255].map(x=>x*x);
  const A=un(tessPals[a][k]),B=un(tessPals[b][k]),s=m*m*(3-2*m),c=A.map((x,i)=>x+(B[i]-x)*s);
  const ca=Math.cos(hr),sa=Math.sin(hr),q=.57735,d=q*(c[0]+c[1]+c[2])*(1-ca);
  const x=[q*(c[2]-c[1]),q*(c[0]-c[2]),q*(c[1]-c[0])];
  const o=c.map((v,i)=>Math.round(Math.sqrt(Math.min(1,Math.max(0,v*ca+x[i]*sa+q*d)))*255));
  return o[0]*65536+o[1]*256+o[2];
}
// TESS4 start the unfold event: a tesseract hero opens into its net (the Dali cross) and folds back; any other hero
// first bursts and re-assembles as a tesseract
function tessUnfold(c){if(c.set[0]===0)c.uT=0;else{c.exT=0;c.exAmp=.4;c.cloud=0;c.pend='unf';}}
// TESS4 turn the 4D rotation M (left multiply) so its w column moves a fraction f of the way back onto e_w
function tessUntwist(M,f){
  const m=[M[12],M[13],M[14],M[15]],th=Math.acos(Math.max(-1,Math.min(1,m[3])));if(th<1e-4)return;
  let u=[m[0],m[1],m[2],0];const l=Math.hypot(u[0],u[1],u[2]);if(l<1e-6)return;u=u.map(x=>x/l);
  const a=th*f,ca=Math.cos(a)-1,sa=Math.sin(a);
  for(let k=0;k<4;k++){const v=[M[k*4],M[k*4+1],M[k*4+2],M[k*4+3]],du=v[0]*u[0]+v[1]*u[1]+v[2]*u[2],dw=v[3];
    for(let r=0;r<4;r++){const e=r===3?1:0;M[k*4+r]=v[r]+ca*(du*u[r]+dw*e)+sa*(du*e-dw*u[r]);}}
}
// TESS4 exact critically damped spring step (closed form, stable at any dt): c[k] follows target tg at angular rate w
function tessSpring(c,k,tg,w,dt){const v=c[k+'v']||0,x=(c[k]||0)-tg,e=Math.exp(-w*dt),j=v+w*x;c[k]=tg+(x+j*dt)*e;c[k+'v']=(v-w*j*dt)*e;}
