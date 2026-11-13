/* I. Chrysanthemum Gate — three parallax layers of neon petals in log-polar space: an infinite flower you fall into.
   Petals glow with their own slice of the spectrum; a ring of light rides each beat outward. */
//@scene glsl gate

/* II. Jeweled Lattice — {P,Q} hyperbolic tiling in the Poincare disk, Mobius-flown. */
//@scene glsl lattice

/* III. Elf Cathedral — an endless recursive Menger temple corridor that twists with the bass, lit by glowing
   circuit seams that carry the spectrum, with light entities darting past. */
//@scene glsl cathedral

/* IV. Apollonian Foam — sphere-inversion fractal, bubbles inside bubbles forever. */
//@scene glsl foam

/* V. Mandala Bloom — Multibrot Julia sets (natural n-fold symmetry) riding just outside the connectedness
   boundary: spiral galaxies of fractal dust, coloured with stripe-average ribbons that flow with the music. */
//@scene glsl mandala

/* VI. Breakthrough Tunnel — nested cylinders of neon glyph rosettes at different radii (true parallax), spectrum-lit
   cells, beat rings rushing past, and the white light at the end. Analytic ray/cylinder hits keep it cheap. */
const R_TUNNEL = `
float cellPat(vec2 f,float id,float aa,out float fill){
  vec2 g=f;float tr=1e3,s=1.;
  for(int i=0;i<4;i++){
    g=abs(g)-vec2(.18,.12)*(1.+.25*sin(id+uMT*.3));
    g=rot(.55+uP1.z+float(i)*.2)*g;
    g*=1.6;s*=1.6;
    tr=min(tr,abs(length(g)-.33)/s);
  }
  float rf=length(f),af=atan(f.y,f.x);
  float ros=abs(rf-(.28+.06*cos(uP1.w*af+uMT)));
  fill=smoothstep(.32,.0,rf);
  float l1=smoothstep(aa,0.,tr);
  float l2=smoothstep(aa*1.2,0.,ros-.002);
  float l3=orn(f*2.3,aa*2.3,id*.37)*smoothstep(.5,.3,rf);
  return l1*.8+l2*.7+l3*.9;
}
void realm(){
  vec2 p=scr()/uZoom;p=lens(p);
  p=rot(uMT*.06+uP2.x)*p;
  p+=uLook*.25;
  vec3 rd=normalize(vec3(p,uP1.x*(1.+uBuild*.8)));
  float N=uP1.y;
  vec3 col=vec3(0.);
  float alpha=1.;
  float th=atan(rd.y,rd.x);
  float rxy=max(length(rd.xy),1e-3);
  float pxa=1./(uRes.y*uZoom*max(length(p),1e-3));
  float win=0.;vec2 wl=vec2(0.);
  for(int L=0;L<3;L++){
    if(float(L)>=uP3.x)break;
    float fl=float(L);
    float R=1.+fl*.8-.12*uBass;
    float t=R/rxy;
    float nx=N*(1.+fl);
    vec2 uv=vec2(th/TAU*nx,t*rd.z*.35*N/6.+uP2.y*(1.+fl*.25)+uKick*.02*N);
    float ring=floor(uv.y);
    uv.x+=ring*.5;
    vec2 id=floor(uv);id.x=mod(id.x,nx);
    vec2 f=fract(uv)-.5;
    float aa=fwidth(uv.y)+pxa*nx/TAU+1e-4;
    float fill;
    float ln=cellPat(f,id.x*1.3+id.y*.7,aa*1.2,fill);
    float h=h21(id+fl*7.);
    float sp=spec(fract(h*.8+.05));
    float fog=exp(-t*.13);
    float lod=smoothstep(.35,.06,aa);
    float beat=exp(-pow(fract(uv.y*.125-uBeat*.5)-.5,2.)*60.)*uKick;
    vec3 lc=pal(h*.3+ring*.04+fl*.2)*(.2+.85*sp*uDose)*uP3.y+beat*1.;
    vec3 fc=pal(h*.3+.5+fl*.2)*fill*.05*(.5+sp);
    vec3 lay=(lc*ln+fc)*lod*fog;
    float cov=clamp(ln*.8+fill*.2,0.,1.)*lod*fog;
    col+=lay*alpha*(1.-fl*.18);
    float wk=alpha*smoothstep(.19,.13,length(f))*lod*fog*(1.-fl*.4);
    if(wk>win*.5)wl=f/.16;
    win+=wk;
    alpha*=1.-cov*.7;
  }
  float r=length(p);
  float ang=atan(p.y,p.x);
  col+=pal(.1)*pow(.5+.5*cos(ang*N*2.+uMT*.5),8.)*exp(-r*3.)*uP3.z*(.4+uKick);
  col+=pal(.08)*(.012/(r*r+.012))*(.3+uLevel*.6+uKick*.5);
  col+=vec3(1.)*.0012/(r*r+.0008)*(.4+uKick);
  fragColor=vec4(col,clamp(win,0.,1.));fragWin=vec4(wl*.5+.5,0.,1.);
}`;

/* VII. Glyph Tapestry — Kali's inversion fold in 2D with a level-of-detail cutoff: neon alien script on black. */
//@scene glsl merc

