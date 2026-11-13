/* debug / automation hook */
window.HyperVisualizer = {
  S, F, D, REALMS, PTR, Q, DBG, BANDS,
  // ENGINE v24: scenes from a file, the scene set and the playlist (work/engine24/SCENE-PACK-FORMAT.md)
  registerScene, removeScene, addSceneText, SCN, get scenes() { return scnList(); }, get scenesRestored() { return SCN.restored; },
  get playlist() { return scnExport(); }, set playlist(p) { scnImport(Object.assign({}, p, { format: 'hypervisualizer-playlist' })); },
  E, setAutoShow, setAutoManual, autoProfile, get autoManual() { return [...AUTO.manual]; }, // v10: effective settings and the Auto Show
  SHOW, showOf, autoFraming: (V) => realmZoom(V), get FOLD() { return FOLD; }, get AUTOZ() { return AUTOZ; }, // v21: framing and fold state for the tools
  goRealm, triggerDrop, prepare: () => prepareVisualizer('full'), startDemo: () => { AU.init();startWhenReady(()=>{ hideSplash();AU.startDemo(); }); }, hideSplash, setPalette,
  offline: OFFLINE,
  mobile: MOBILE, TOUCH, get gpuTest() { return { packed: PACKED, ...JSON.parse(JSON.stringify(GPU_TEST)) }; }, startVisual: () => { AU.init(); startWhenReady(() => { hideSplash(); AU.startVisual(); }); }, // MOBILE: test hooks
  get preparation() { const ready=REALMS.filter(R=>R.ready).length; return {requested:PREPARE.requested,error:PREPARE.error,mode:PREPARE.mode,compiled:PREPARE.compileIndex+PREPARE.timings.length,programs:PREPARE.queue.length+REALMS.length,done:PREPARE.displayDone&&realmsSettled(),index:ready,ready,failed:REALMS.filter(R=>R.failed).map(R=>R.key),total:REALMS.length,firstMs:PREPARE.firstMs,timings:PREPARE.timings.map(t=>({...t})),displayMs:PREPARE.displayMs,displayIndex:PREPARE.displayIndex,displayTimings:PREPARE.displayTimings.map(t=>({...t}))}; },
  // ready: the app can show a picture. allReady: every realm is prepared (it keeps preparing in the background).
  get allReady() { return glReady && realmsSettled(); },
  get audio() { return AU; }, get ready() { return glReady; }, get renderSize() { return [RW, RH, W, H]; },
  get exposure() {
    if (!glReady || !gl || gl.isContextLost() || !RT.expo[0]) return null;
    gl.bindFramebuffer(gl.FRAMEBUFFER, RT.expo[1 - RT.ei].fbo);
    const b = HALF ? new Float32Array(4) : new Uint8Array(4);
    gl.readPixels(0, 0, 1, 1, gl.RGBA, HALF ? gl.FLOAT : gl.UNSIGNED_BYTE, b);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    return Math.exp((HALF ? b[0] : b[0] / 255 + b[1] / 65025) * 6 - 4) - 0.02;
  }
};
})();
