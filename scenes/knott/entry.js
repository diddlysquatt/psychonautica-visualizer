{
  key:'knott',name:'KN0TT',src:R_KNOTT,cost:1.2,cont:[],description:'Living neon Truchet knotwork',
  fb:{zoom:0,rot:0,decay:.1,warp:0,echo:0,droste:0,win:0,key:.08},syms:[0,0,0,4,6,6,8,8,12,16,5,3,2],kalZoom:.5,
  auto:{kal:[6,8,12,5,4,3,16,2,0],kalCycle:true,kalZoom:.5,transitions:['kaleido','vortex','portal','shatter'],notes:'v12: zoomed out (and at kalZoom .5) the giant knot is a woven tube of the other small weave with a neon spine; kick comets ride the giant strands a tile per beat, crossings glow with the vocal range, mids ripple echo waves off the strands, hats twinkle the tiles, the snare flashes the rails. All folds full of knotwork; 6/8/12 best, 2 (mirror) now fine too; cycle folds on phrases, unfolded on drops shows the wipe'},
  init:(s)=>knottInit(s),
  frame(V,F,dt){knottFrame(V,F,dt);}
  },
