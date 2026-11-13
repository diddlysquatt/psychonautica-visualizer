// 8 band envelopes for geometry: the engine's auto-ranged BANDS.lv, smoothed (fast attack, slower release); plus the
// latent-image envelope from the vocal/lead range (hi-mid + presence)
function spiroBands(c,dt){
  if(!c.b)c.b=new Float32Array(8);
  const L=(typeof BANDS!=='undefined')?BANDS.lv:null;
  for(let k=0;k<8;k++){const t=L?L[k]:0;c.b[k]+=(t-c.b[k])*(1-Math.exp(-dt*(t>c.b[k]?14:4)));}
  // the latent image surfaces only when the vocal/lead range stands out above its own recent average
  const vr=L?(L[4]*.55+L[5]*.45):0;c.lm=(c.lm||0)+(vr-(c.lm||0))*(1-Math.exp(-dt*.25));
  const vt=Math.max(0,Math.min(1,(vr-Math.max(.35,c.lm)-.05)/.3));
  c.la+=(vt-c.la)*(1-Math.exp(-dt*(vt>c.la?4:.9)));
}
// nine hand-curated 5-colour palettes (sRGB); palette 8 follows the global cosine palette
const spiroPals=[
  [[0,.96,.83],[.49,1,.70],[1,.82,.40],[1,.31,.64],[.55,.36,.96]],
  [[1,.42,.21],[1,.71,.15],[1,.24,.47],[.64,.22,.79],[.30,.79,.94]],
  [[.62,.95,1],[.1,.85,1],[.13,.4,1],[.51,.16,.95],[1,0,.43]],
  [[.8,1,0],[.22,1,.08],[0,.9,1],[1,0,.9],[1,.9,0]],
  [[1,.84,0],[1,.55,0],[.9,.22,.27],[.48,.18,.97],[0,.83,1]],
  [[1,.4,.38],[1,.08,.52],[0,.74,.82],[.16,.36,1],[1,.72,.2]],
  [[0,1,.62],[0,.72,1],[.3,.36,1],[.74,0,1],[1,.3,.82]],
  [[1,.18,.33],[1,.8,0],[.2,.78,.35],[0,.78,1],[.69,.32,.87]]];
// returns 5 floats, each an sRGB colour packed as r*65536+g*256+b, after a small hue nudge from the global hue
function spiroPal(pid,hue){
  const out=[],ang=.4*Math.sin(6.283185*hue),cs=Math.cos(ang),sn=Math.sin(ang),k=.57735;
  let cp=null;
  if(pid>=8&&typeof PALETTES!=='undefined'&&typeof D!=='undefined')cp=PALETTES[D.palTo]||PALETTES[0];
  for(let i=0;i<5;i++){
    let c;
    if(cp){const t=i*.2;c=[0,1,2].map(j=>Math.max(0,Math.min(1,cp.a[j]+cp.b[j]*Math.cos(6.283185*(cp.c[j]*t+cp.d[j]+hue)))));}
    else c=spiroPals[Math.min(pid,7)][i];
    // rotate in linear light around the grey axis, back to sRGB
    const L=c.map(x=>Math.pow(x,2.2)),d=k*(L[0]+L[1]+L[2]);
    const cr=[k*(L[2]-L[1]),k*(L[0]-L[2]),k*(L[1]-L[0])];
    const R=L.map((x,j)=>Math.max(0,x*cs+cr[j]*sn+k*d*(1-cs)));
    const b=R.map(x=>Math.round(255*Math.min(1,Math.pow(x,1/2.2))));
    out.push(b[0]*65536+b[1]*256+b[2]);
  }
  return out;
}
// engine's seeded generator (offline renders reproduce); falls back to Math.random outside the page
function spiroRand(){return typeof rand==='function'?rand():Math.random();}
function spiroOld(c){return {sd:c.sd,lay:c.lay,pal:c.pal,sub:c.sub};}
// new design: seed always, palette often, tile arrangement/scale per phrase, layout on big moments (drops, 16 bars)
function spiroReconf(c,big){
  c.old=spiroOld(c);
  c.sd=spiroRand();
  // 0 emblem 1 tiled 2 banknote 3 triptych 5 spirograph garden (4, the moire, was cut for compile budget; the classic notes a little more often)
  if(big){const w=[1.3,1,1.3,1,0,1.1];let l;do{let x=spiroRand()*5.7;l=0;while(l<5&&x>=w[l]){x-=w[l];l++;}}while(l===c.lay);c.lay=l;}
  if(big||spiroRand()<.55){let q;do q=Math.floor(spiroRand()*9);while(q===c.pal);c.pal=q;}
  let u;do u=Math.floor(spiroRand()*3);while(u===c.sub&&c.lay===c.old.lay);c.sub=u;
  c.tsT=[.84,1,1.16][Math.floor(spiroRand()*3)];
  c.wp=0;c.wd=big?1:2;c.ts=0;
  c.wt=Math.floor((c.sd*97.13)%1*3);   // wipe style: radial, press (left to right), venetian blinds
}
