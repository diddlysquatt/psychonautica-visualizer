{
  key:'hypr',name:'L1M1T',src:R_HYPR,cost:0.9,cont:[],description:'hyperbolic jewel tilings',
  fb:{zoom:0,rot:0,decay:.14,warp:0,echo:.02,droste:0,win:0,key:.05,live:.15},syms:[0,0,0,6,8,12,16,6,8,4,5],kalZoom:.8,
  auto:{kal:[0,12,6,8,16,5],kalCycle:true,kalZoom:.8,tier:2,kind:'3d',transitions:['portal','vortex','kaleido'],notes:'v12: every fold reads (rose windows of jewels); 12 and 16 make the richest rose windows, 6/8 jewel mandalas, 5 a star; 2/3/4 also fine but plainer'},
  init:(s)=>hyprInit(s),
  frame(V,F,dt){ hyprFrame(V,F,dt); }
  },
