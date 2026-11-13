  {
  key:'swarm',name:'SWARM',src:R_SWARM,cost:2.6,cont:[],description:'a murmuration of light: sculptures of countless dots that orbit, weave and chase each other among ringed worlds',kalZoom:.55,
  fb:{zoom:0,rot:0,decay:.32,warp:0,echo:.06,droste:0,win:0,key:.12},syms:[0,0,0,6,6,8,8,5,3,4,12,16],
  auto:{kal:[0,6],kalCycle:true,kalZoom:.55,transitions:['portal','vortex','kaleido'],notes:'v12 (v12/b0_kal, 3 seeds x 2 times): unfolded is the hero view; 6/8/5/4 fold the figure into a jewel on every seed, 3 and 12 good; 16 dropped (dense figures melt into one soft disc), 2 lopsided'},
  init:s=>{
    const r=swarmRng(s[0]),seq=swarmShuffle([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],r),pals=swarmShuffle([0,1,2,3,4,5],r);
    const prm=Array.from({length:16},()=>r()),off=r();   // one parameter per family id (15 families, ids 0..14)
    const fi=[0,0,1,3,2][Math.floor(r()*5)],sl0=[0,1,3,4,5,2][Math.floor(r()*6)];
    return {r,seq,si:0,figA:seq[0],figB:seq[0],mdA:fi,mdB:fi,slA:sl0,slB:sl0,sb:null,fb:null,car:s[1]*6.283,mt:1,mDur:1,prm,pals,pi:0,palF:pals[0],palT:pals[0],offF:off,offT:off,
      wp:9,wv:6,wd:0,ex:0,exMax:0,kr:9,shR:9,kx:0,kv:0,bass:0,mid:0,bu:0,calm:0,al:s[3]*6.283,h:0,fdir:s[1]<.5?1:-1,
      ring:s[2]<.75?1:0,ringS:s[2]<.75?1:0,az:s[1]*6.283,azV:2,sw:0,swS:0,elT:0,elS:0,el0:(s[3]-.5)*.4,
      oy:s[0]*6.283,op:(s[2]-.5)*.5,bars:0,lt:null,tDrop:null,zT:1,zS:1,fd:null,
      drops:0,vis:0,visS:0,dust:0,dustE:0,rip:0,lastEv:'',fly:0,flyS:0,skim:0,crown:0,skimS:0,crownS:0,rollS:0,rollT:0,grow:1,bloom:0,voc:0,spA:null,spDone:0,sp:'',spN:0};
  },
  frame(V,F,dt){swarmFrame(V,F,dt);}
  },
