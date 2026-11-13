{
  key:'kubik',name:'KUB1K',src:R_KUBIK,cost:1.2,cont:[],description:'bold cubes dancing in formation',kalZoom:.7,
  fb:{zoom:0,rot:0,decay:.12,warp:0,echo:0,droste:0,win:0,key:.08,live:.05},syms:[0,0,2,2,6,4,8,12],
  auto:{zoom:[.7,1.9],kal:[2,6,4,0,8,5,12],kalCycle:true,kalZoom:.7,tier:1,kind:'3d',bars:32,transitions:['kaleido','shatter','portal'],fx:{warp:.12,trails:.4,chroma:.3},notes:'v12 (v12/b0_kal): mirror (2) first, the person loves KUB1K mirrored; 6/4/8/5 cube mandalas on every seed, 12 good; 3 and 16 fine but busier'},
  init:s=>kubikInit(s),
  frame(V,F,dt){kubikFrame(V,F,dt);}
  },
