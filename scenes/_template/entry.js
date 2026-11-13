  {
  // The scene object. It is one element of the engine's scene list, so it ends with "}," (keep the comma).
  // key: 2-24 lowercase letters / digits, the same as the folder name. name: what people see (short, stylised).
  // src: the GLSL string from scene.glsl. description: a few words for the scene list.
  key:'template',name:'TEMPLATE',src:R_TEMPLATE,description:'an endless flower, one ring of petals per frequency band',
  // cost: rough GPU cost against the other scenes (1 = light, 2.5 = heavy). Phones show light scenes first.
  cost:0.8,
  // fb: how the engine's feedback pass treats this scene's picture (trails and echo). Crisp line work wants little
  // of it: low decay, no warp, a small echo (leave echo out and you get the engine default 0.7), live low so the engine's own
  // kick zoom and prism split stay gentle. key is the brightness the auto-exposure aims for.
  fb:{zoom:0,rot:0,decay:.2,warp:0,echo:.04,droste:0,win:0,key:.08,live:.2},
  // syms: kaleidoscope folds this scene looks good in (0 = unfolded; repeat a value to make it likelier).
  // kalZoom: framing while folded, as a multiple of the unfolded framing. The Auto Show's own choices come from
  // the "show" row in scene.json; these two are what a person gets when they pick Kaleidoscope: Auto by hand.
  syms:[0,0,0,6,8,12],kalZoom:.9,
  // evolves:true = this scene changes its own formation on the music, so the engine leaves it alone instead of
  // cross-fading into a fresh random variant every few phrases. cont: names of numeric fields in the state that
  // the engine may morph toward a fresh init() (only used when evolves is not set).
  evolves:true,cont:[],
  // init(seed) -> state, frame(V, F, dt): see helpers.js
  init:(s)=>templateInit(s),
  frame(V,F,dt){ templateFrame(V,F,dt); }
  },
