/* ============================ frame loop ============================= */
let lastT = performance.now(), started = false, frameCount = 0;
function frame(now) {
  requestAnimationFrame(frame);
  let dt = (now - lastT) / 1000; lastT = now;
  if (!(dt > 0)) dt = 1 / 60;
  dt = Math.min(dt, 0.1);
  if (DBG.fixedDt) dt = DBG.fixedDt;
  if (!PREPARE.requested || PREPARE.error) return;
  if (!glReady) { if(gl && !gl.isContextLost())try { checkPrograms(); } catch (error) { preparationFailed(error); } return; }
  if (!gl.isContextLost()) { prepareInBackground(); hdUpdate(); }
  if (OFF.on) return; // an offline render drives step() itself
  if (!splashGone || (document.hidden && !REC.session)) return; // keep unopened/background tabs idle; preserve an active recording
  step(dt);
}
function step(dt) {
  TIME += dt; RTIME += dt * clamp(Number(S.speed) || 0, 0, 2.5);
  AU.analyze(dt);
  syncVisualFeatures();
  bandsUpdate(dt);
  smoothFeatures(dt); // v10: F.kickS ... and the motion low-pass inputs
  pointerUpdate(dt);
  autoUpdate(dt); // v10: Auto Show publishes the effective settings E before the director reads them
  autoZoomUpdate(); // v13b: default framing per realm, Auto Show zoom glides
  directorUpdate(dt);
  qualityUpdate(dt);
  // Travel is counted in beats. With a confident tempo it surges on every beat (the shape integrates to exactly
  // one unit per beat), runs half-time in breakdowns and double-time after a drop; without one it follows loudness.
  const hold = 1 - 0.6 * (PTR.grav || 0);
  const spd = S.speed * (0.35 + 1.05 * F.level + 0.45 * F.bass + 1.4 * F.build + 0.9 * F.drop) * hold;
  const lockW = clamp((F.conf - 0.35) / 0.35, 0, 1) * (1 - F.idle);
  const surge = 0.45 + 1.65 * Math.pow(1 - F.beat, 2);
  const rateTgt = F.drop > 0.35 ? 2 : F.breakdown > 0.6 ? 0.5 : 1 + F.build;
  [D.cur, D.nxt, D.upcoming].forEach((V) => {
    if (!V) return;
    // v10: up to the default the surge keeps its established depth; above it flattens completely at 100%
    const calm=motionDamping(V), smoothSurge=lerp(surge,1,calm<=.75?calm*0.9:.675+.325*(calm-.75)/.25);
    V.rate = ease(V.rate, rateTgt, dt, 0.6+1.4*calmStretch(calm));
    const locked = (F.bpm || 120) / 60 * smoothSurge * V.rate * S.speed * hold;
    const velocity=lerp(spd*1.6,locked,lockW), morphSpeed=spd*lerp(1,smoothSurge,lockW*0.6);
    if(calm>0){V.velocity=V.velocity===undefined?velocity:ease(V.velocity,velocity,dt,0.12+calmStretch(calm)*0.75);V.morphSpeed=V.morphSpeed===undefined?morphSpeed:ease(V.morphSpeed,morphSpeed,dt,0.12+calmStretch(calm)*0.75);}
    V.trav += dt*(calm>0?V.velocity:velocity);
    V.mt += dt*(calm>0?V.morphSpeed:morphSpeed);
    kzUpdate(V, dt); easeVisit(V, dt); realmFrame(V, dt);
  });
  for (let i = WAVES.length - 1; i >= 0; i--) { WAVES[i].t += dt; if (WAVES[i].t > 2.6) WAVES.splice(i, 1); }
  if (!OFF.skip) { render(dt); uiTick(dt); }
  frameCount++;
}


function withPreparationPostState(work) {
  const state = { program:gl.getParameter(gl.CURRENT_PROGRAM), vao:gl.getParameter(gl.VERTEX_ARRAY_BINDING),
    draw:gl.getParameter(gl.DRAW_FRAMEBUFFER_BINDING), read:gl.getParameter(gl.READ_FRAMEBUFFER_BINDING),
    viewport:Array.from(gl.getParameter(gl.VIEWPORT)), clear:Array.from(gl.getParameter(gl.COLOR_CLEAR_VALUE)),
    mask:Array.from(gl.getParameter(gl.COLOR_WRITEMASK)), active:gl.getParameter(gl.ACTIVE_TEXTURE), units:[], caps:[] };
  for(const cap of [gl.BLEND,gl.SCISSOR_TEST,gl.DEPTH_TEST,gl.CULL_FACE,gl.RASTERIZER_DISCARD])state.caps.push([cap,gl.isEnabled(cap)]);
  for(let unit=0;unit<7;unit++){gl.activeTexture(gl.TEXTURE0+unit);state.units.push([gl.getParameter(gl.TEXTURE_BINDING_2D),gl.getParameter(gl.SAMPLER_BINDING)]);}
  try {
    for(const [cap] of state.caps)gl.disable(cap);
    gl.colorMask(true,true,true,true);gl.bindVertexArray(vao);
    for(let unit=0;unit<7;unit++)gl.bindSampler(unit,null);
    return work();
  } finally {
    gl.useProgram(state.program);gl.bindVertexArray(state.vao);
    gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER,state.draw);gl.bindFramebuffer(gl.READ_FRAMEBUFFER,state.read);
    gl.viewport(...state.viewport);gl.clearColor(...state.clear);gl.colorMask(...state.mask);
    for(const [cap,on] of state.caps)on?gl.enable(cap):gl.disable(cap);
    for(let unit=0;unit<7;unit++){gl.activeTexture(gl.TEXTURE0+unit);gl.bindTexture(gl.TEXTURE_2D,state.units[unit][0]);gl.bindSampler(unit,state.units[unit][1]);}
    gl.activeTexture(state.active);
  }
}
function makePreparationDisplayTargets() {
  const made=[],make=(...args)=>{const t=makeTarget(...args);made.push(t);return t;};
  try {
    const t={scene:make(2,2,gl.MIRRORED_REPEAT,true),
      history:make(2,2),ping:make(2,2),pong:make(2,2),hi:make(2,2),expoPrev:make(1,1),expoOut:make(1,1)};
    // Composite outputs are normalized8-bit; HALF applies to intermediate targets, not the screen.
    const tex=gl.createTexture(),fbo=gl.createFramebuffer(),ldr={tex,fbo,w:2,h:2};made.push(ldr);
    gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,tex);
    gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA8,2,2,0,gl.RGBA,gl.UNSIGNED_BYTE,null);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);
    gl.bindFramebuffer(gl.FRAMEBUFFER,fbo);gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,tex,0);
    gl.drawBuffers([gl.COLOR_ATTACHMENT0]);
    if(!tex||!fbo||gl.checkFramebufferStatus(gl.FRAMEBUFFER)!==gl.FRAMEBUFFER_COMPLETE)throw new Error('GPU could not allocate preparation display target.');
    t.ldr=ldr;t.all=made;
    for(const target of made)clearTarget(target,[.12,.18,.24,.47]);
    for(const target of [t.expoPrev,t.expoOut]){gl.bindFramebuffer(gl.FRAMEBUFFER,target.fbo);gl.clearColor(.47,0.,0.,1.);gl.clear(gl.COLOR_BUFFER_BIT);}
    return t;
  } catch(error) { made.forEach(freeTarget);throw error; }
}
function freePreparationDisplayTargets() {
  if(PREPARE.displayTargets){PREPARE.displayTargets.all.forEach(freeTarget);PREPARE.displayTargets=null;}
}
function drawPreparationDisplayPass(kind,t) {
  const p=kind==='feedback'?PG.fb:kind==='upscale'?PG.easu:kind==='bloomDown'?PG.down:kind==='bloomUp'?PG.up:kind==='exposure'?PG.expo:kind.startsWith('shadow')?PG.shadowComp:PG.comp;
  gl.useProgram(p.p);
  if(kind==='feedback'){
    const inputs=[['uA',t.scene],['uB',t.scene],['uPrev',t.history],['uN',t.scene],['uBlur',t.history]];
    inputs.forEach(([name,target],unit)=>{bindTex(unit,target.tex);ui(p,name,unit);});
    u2(p,'uRes',2,2);u2(p,'uMouse',0,0);u2(p,'uMouseVel',0,0);u2(p,'uTC',.1,-.1);
    u4(p,'uMouseV',[0,0,0,0]);u4(p,'uHole',[0,0,.1,0]);
    for(const [name,value] of Object.entries({uTime:0,uMix:.25,uStyle:0,uSymA:0,uSymB:0,uSymRot:0,uZoomFb:.001,uRotFb:.01,uDecay:.9,uHueStep:0,uRaw:0,uPulse:.01,uSymA0:3,uSymT:.5,uEcho:.1,uDroste:.05,uPeek:0,uHold:0,uSpin:0,uWin:.1,uCurl:.01,uStut:.1}))u1(p,name,value);
    u4(p,'uFlow',[.001,.001,0,1.7]);drawTo(t.ping,2,2,false);
  }else if(kind==='upscale'){
    bindTex(0,t.ping.tex);ui(p,'uSrc',0);u2(p,'uRes',2,2);
    drawTo(t.hi,2,2,false);
  }else if(kind==='bloomDown'){
    bindTex(0,t.ping.tex);ui(p,'uTex',0);u2(p,'uRes',2,2);u2(p,'uTexel',.5,.5);u1(p,'uThresh',.72);u1(p,'uPre',1);
    drawTo(t.pong,2,2,false);
  }else if(kind==='bloomUp'){
    bindTex(0,t.pong.tex);ui(p,'uTex',0);bindTex(1,t.history.tex);ui(p,'uBase',1); // uBase is a float sampler: never the packed realm targetu2(p,'uRes',2,2);u2(p,'uTexel',.5,.5);
    drawTo(t.ping,2,2,false);
  }else if(kind==='exposure'){
    bindTex(0,t.pong.tex);ui(p,'uSrc',0);bindTex(1,t.expoPrev.tex);ui(p,'uPrevE',1);u1(p,'uRate',.25);u1(p,'uPack',HALF?0:1);
    drawTo(t.expoOut,1,1,false);
  }else{
    bindTex(0,t.ping.tex);ui(p,'uFb',0);bindTex(1,t.pong.tex);ui(p,'uBloom',1);bindTex(2,t.expoOut.tex);ui(p,'uExpo',2);
    u2(p,'uRes',2,2);u2(p,'uFbTexel',.5,.5);
    for(const [name,value] of Object.entries({uTime:0,uChroma:.1,uBloomAmt:.1,uFlash:0,uVig:.38,uKick:.1,uSat:1.14,uExposure:1,uSharp:0,uPeek:0,uKey:.2,uPack:HALF?0:1,uSS:.25,uShadowRecovery:.45}))u1(p,name,value);
    const waves=loc(p,'uWaves[0]');if(waves)gl.uniform4fv(waves,new Float32Array(24));u4(p,'uHole',[0,0,.1,0]);
    // Retain the old actual-default-surface warm-up too: driver internal formats may differ from RGBA8 FBOs.
    drawTo(kind.endsWith('Surface')?null:t.ldr,2,2,false);
  }
}
function prepareDisplayPipelines() {
  const passes=['feedback','bloomDown','bloomUp','exposure','upscale','composite','shadowComposite','compositeSurface','shadowCompositeSurface'];
  try {
    if(!PREPARE.displayStarted){PREPARE.displayStarted=performance.now();PREPARE.displayTargets=withPreparationPostState(makePreparationDisplayTargets);}
    if(PREPARE.displayFence){
      const status=gl.clientWaitSync(PREPARE.displayFence,0,0);
      if(status===gl.TIMEOUT_EXPIRED)return false;
      if(status===gl.WAIT_FAILED)throw new Error('Preparing shared display programs failed on this GPU.');
      gl.deleteSync(PREPARE.displayFence);PREPARE.displayFence=null;
      PREPARE.displayTimings.push({key:passes[PREPARE.displayIndex],ms:performance.now()-PREPARE.displayStepStarted});PREPARE.displayIndex++;
    }
    if(PREPARE.displayIndex>=passes.length){
      PREPARE.displayMs=performance.now()-PREPARE.displayStarted;
      freePreparationDisplayTargets();PREPARE.displayDone=true;return true;
    }
    const key=passes[PREPARE.displayIndex];
    PREPARE.displayStepStarted=performance.now();
    withPreparationPostState(()=>{drawPreparationDisplayPass(key,PREPARE.displayTargets);});
    PREPARE.displayFence=gl.fenceSync(gl.SYNC_GPU_COMMANDS_COMPLETE,0);
    if(!PREPARE.displayFence)throw new Error('Could not fence shared program preparation.');
    gl.flush();return false;
  } catch(error) {
    if(PREPARE.displayFence){gl.deleteSync(PREPARE.displayFence);PREPARE.displayFence=null;}
    freePreparationDisplayTargets();throw error;
  }
}

function checkPrograms() {
  // 1. The shared post-processing programs, submitted one at a time, yielding to input/painting in between.
  if (PREPARE.compileIndex < PREPARE.queue.length) {
    const item = PREPARE.queue[PREPARE.compileIndex];
    spStatus.textContent = 'Loading image pipeline · ' + (PREPARE.compileIndex + 1) + ' / ' + PREPARE.queue.length;
    if (!item.P) { item.P = makeProgram(item.name,item.src); item.assign(item.P); return; }
    if (!programDone(item.P)) return;
    if (!finalizeProgram(item.P)) throw new Error('A shader failed to compile on this GPU (' + item.name + ').');
    PREPARE.compileIndex++; return;
  }
  PREPARE.finalized = true;
  // 2. Realms: the first one (for 'full', all of them) link on the driver's threads while 3. the display passes warm.
  for (let n = 0; n < 4 && stepRealmPrep(); n++);
  if (!PREPARE.displayDone && !prepareDisplayPipelines()) return;
  if (!GPU_TEST.stage2) gpuSelfTestPipeline(); // ADRENO FIX
  const readyCount = REALMS.filter((R) => R.ready).length;
  if (PREPARE.mode === 'full' ? !realmsSettled() : !readyCount) {
    if (realmsSettled() && !readyCount) throw new Error('No scene could be compiled on this GPU.');
    const R = REALMS[RP.first];
    spStatus.textContent = PREPARE.mode === 'full' ? 'Preparing worlds ' + (readyCount + 1) + ' / ' + REALMS.length
      : 'Preparing ' + (R ? R.name : 'the first world') + (MOBILE ? ' · phones can take up to a minute the first time' : ' · the others load while you watch'); // MOBILE
    return;
  }
  PREPARE.firstMs = Math.round(performance.now() - PREPARE.started);
  spStatus.textContent='Ready · choose your audio source';
  document.querySelectorAll('[data-start]').forEach(b=>b.disabled=false);
  glReady = true;
  if (!D.cur) {
    const initial = realmReady(RP.first) ? RP.first : REALMS.findIndex((R) => R.ready);
    D.cur = makeVisit(initial); resetRealmBag(initial); announceRealm(initial); markRealmChips(initial); D.palTo = pick([0, 1, 5]);
  }
  markRealmStates();
  const start = pendingStart; pendingStart = null;
  if (start) start();
}
// Between live frames: prepare the remaining realms, one step per frame, so a frame never waits on the GPU for it.
function prepareInBackground() {
  const now = performance.now();
  if (RP.lastT && now - RP.lastT > 250) (DBG.prep = DBG.prep || []).push([Math.round(now), 'GAP ' + Math.round(now - RP.lastT) + ' during ' + (realmPrepState() || 'idle'), 0]);
  RP.lastT = now;
  if (!realmPrepBusy() && realmsSettled()) return;
  try { stepRealmPrep(); } catch (error) { console.error('[HyperVisualizer] background preparation:', error); }
}

/* ADRENO FIX: GPU colour self-test.
   Stage 1 (before any realm compiles, a few ms): a tiny realm writes rgba .25/.5/.75/1 and window .1/.2/.3/.4 through
   the real packed main into a 1x1 RGBA32UI target; it is read back as integers and decoded in JS, then unpacked on the
   GPU with the same HALF_GLSL helpers into RGBA8 and read again. Any mismatch switches PACKED off (float fallback).
   Stage 2 (after the post programs exist): the test colour goes through the real feedback and composite programs into
   an RGBA8 target; the rgb must keep its order (r < g < b, all lit). The result is logged and shown in the controls. */
const halfToFloat = (h) => { const e = (h >> 10) & 31, m = h & 1023, sg = h & 0x8000 ? -1 : 1; return e === 0 ? sg * m * Math.pow(2, -24) : e === 31 ? NaN : sg * Math.pow(2, e - 15) * (1 + m / 1024); };
const SELFTEST_REALM = 'void realm(){fragColor=vec4(.25,.5,.75,1.);fragWin=vec4(.1,.2,.3,.4);}';
function selfTestProgram(vs, src) {
  const fs = compileShader(gl.FRAGMENT_SHADER, src), p = gl.createProgram();
  gl.attachShader(p, vs); gl.attachShader(p, fs); gl.linkProgram(p);
  const ok = !!gl.getProgramParameter(p, gl.LINK_STATUS);
  if (!ok) console.warn('[HyperVisualizer] self-test shader failed:', (gl.getShaderInfoLog(fs) || '') + (gl.getProgramInfoLog(p) || ''));
  return { p, fs, ok, free() { gl.deleteProgram(p); gl.deleteShader(fs); } };
}
function gpuSelfTest() {
  if (GPU_TEST.stage1) return; // decided once per page (a context restore keeps the decision)
  if (!PACKED) { GPU_TEST.stage1 = { ok: false, forced: true }; GPU_TEST.text = 'packed path off (forced), float fallback'; return; }
  const vs = compileShader(gl.VERTEX_SHADER, VS), made = [], R1 = { ok: false };
  try {
    const writer = selfTestProgram(vs, COMMON_PACKED + SELFTEST_REALM + REALM_MAIN_PACKED); made.push(writer);
    const reader = selfTestProgram(vs, '#version 300 es\nprecision highp float;\nprecision highp int;\n' + HALF_GLSL +
      'uniform highp usampler2D uA;uniform float uW;out vec4 o;void main(){highp uvec4 v=texelFetch(uA,ivec2(0),0);o=uW>.5?vec4(hvUnpack(v.z),hvUnpack(v.w)):vec4(hvUnpack(v.x),hvUnpack(v.y));}'); made.push(reader);
    if (writer.ok && reader.ok) {
      const tp = makeTarget(1, 1, null, true), t8 = gl.createTexture(), f8 = gl.createFramebuffer();
      try {
        gl.bindVertexArray(vao);
        gl.useProgram(writer.p); gl.bindFramebuffer(gl.FRAMEBUFFER, tp.fbo); gl.viewport(0, 0, 1, 1); gl.drawArrays(gl.TRIANGLES, 0, 3);
        const u = new Uint32Array(4); gl.readPixels(0, 0, 1, 1, gl.RGBA_INTEGER, gl.UNSIGNED_INT, u);
        R1.packed = Array.from(u).flatMap((x) => [halfToFloat(x & 0xffff), halfToFloat(x >>> 16)]).map((x) => +x.toFixed(4));
        gl.bindTexture(gl.TEXTURE_2D, t8); gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        gl.bindFramebuffer(gl.FRAMEBUFFER, f8); gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, t8, 0);
        gl.useProgram(reader.p); gl.activeTexture(gl.TEXTURE0); gl.bindTexture(gl.TEXTURE_2D, tp.tex); gl.uniform1i(gl.getUniformLocation(reader.p, 'uA'), 0);
        R1.unpacked = [];
        for (const w of [0, 1]) { gl.uniform1f(gl.getUniformLocation(reader.p, 'uW'), w); gl.drawArrays(gl.TRIANGLES, 0, 3); const b = new Uint8Array(4); gl.readPixels(0, 0, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, b); R1.unpacked.push(...Array.from(b, (x) => +(x / 255).toFixed(3))); }
        const want = [.25, .5, .75, 1, .1, .2, .3, .4];
        R1.ok = want.every((x, i) => Math.abs(R1.packed[i] - x) < 2e-3 && Math.abs(R1.unpacked[i] - x) < 6e-3);
      } finally { gl.bindFramebuffer(gl.FRAMEBUFFER, null); freeTarget(tp); gl.deleteTexture(t8); gl.deleteFramebuffer(f8); }
    }
    R1.glError = gl.getError();
  } catch (error) { R1.error = String(error.message || error); }
  finally { made.forEach((x) => x.free()); gl.deleteShader(vs); gl.useProgram(null); }
  GPU_TEST.stage1 = R1;
  if (!R1.ok) { PACKED = false; console.warn('[HyperVisualizer] GPU colour self-test (packed targets) FAILED, using the float fallback: ' + JSON.stringify(R1)); }
  else console.info('[HyperVisualizer] GPU colour self-test (packed targets): OK ' + JSON.stringify(R1));
  GPU_TEST.text = R1.ok ? 'packed OK' : 'packed FAILED (' + (R1.packed || []).slice(0, 3).join(',') + ' / ' + (R1.unpacked || []).slice(0, 3).join(',') + '), float fallback';
}
function gpuSelfTestPipeline() {
  const vs = compileShader(gl.VERTEX_SHADER, VS), R2 = { ok: false };
  let writer = null, t = null;
  try {
    writer = selfTestProgram(vs, (PACKED ? COMMON_PACKED : COMMON_FLOAT) + SELFTEST_REALM + (PACKED ? REALM_MAIN_PACKED : REALM_MAIN));
    if (writer.ok) withPreparationPostState(() => {
      t = makePreparationDisplayTargets();
      for (const x of t.all) if (x !== t.expoPrev && x !== t.expoOut) clearTarget(x, [0, 0, 0, 0]);
      gl.useProgram(writer.p); drawTo(t.scene, 2, 2, false);
      const p = PG.fb; gl.useProgram(p.p);
      [['uA', t.scene], ['uB', t.scene], ['uPrev', t.history], ['uN', t.scene], ['uBlur', t.history]].forEach(([name, target], unit) => { bindTex(unit, target.tex); ui(p, name, unit); });
      u2(p, 'uRes', 2, 2); u2(p, 'uMouse', 0, 0); u2(p, 'uMouseVel', 0, 0); u2(p, 'uTC', 0, 0); u4(p, 'uMouseV', [0, 0, 0, 0]); u4(p, 'uHole', [0, 0, .1, 0]);
      for (const n of ['uTime', 'uMix', 'uStyle', 'uSymA', 'uSymB', 'uSymRot', 'uZoomFb', 'uRotFb', 'uDecay', 'uHueStep', 'uRaw', 'uPulse', 'uSymA0', 'uEcho', 'uDroste', 'uPeek', 'uHold', 'uSpin', 'uWin', 'uCurl', 'uStut']) u1(p, n, 0); u1(p, 'uSymT', 1);
      drawTo(t.ping, 2, 2, false);
      const c = PG.comp; gl.useProgram(c.p);
      bindTex(0, t.ping.tex); ui(c, 'uFb', 0); bindTex(1, t.pong.tex); ui(c, 'uBloom', 1); bindTex(2, t.expoOut.tex); ui(c, 'uExpo', 2);
      u2(c, 'uRes', 2, 2); u2(c, 'uFbTexel', .5, .5);
      for (const [n, v] of Object.entries({ uTime: 0, uChroma: 0, uBloomAmt: 0, uFlash: 0, uVig: 0, uKick: 0, uSat: 1, uExposure: 1, uSharp: 0, uPeek: 0, uKey: .2, uPack: HALF ? 0 : 1, uSS: 0 })) u1(c, n, v);
      const waves = loc(c, 'uWaves[0]'); if (waves) gl.uniform4fv(waves, new Float32Array(24)); u4(c, 'uHole', [0, 0, .1, 0]);
      drawTo(t.ldr, 2, 2, false);
      const px = new Uint8Array(4); gl.bindFramebuffer(gl.FRAMEBUFFER, t.ldr.fbo); gl.readPixels(0, 0, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, px);
      R2.rgb = Array.from(px.slice(0, 3));
      R2.ok = R2.rgb[0] > 8 && R2.rgb[1] > R2.rgb[0] + 4 && R2.rgb[2] > R2.rgb[1] + 4;
    });
  } catch (error) { R2.error = String(error.message || error); }
  finally { if (t) t.all.forEach(freeTarget); if (writer) writer.free(); gl.deleteShader(vs); gl.bindFramebuffer(gl.FRAMEBUFFER, null); }
  GPU_TEST.stage2 = R2;
  const s1 = !!(GPU_TEST.stage1 && GPU_TEST.stage1.ok);
  GPU_TEST.text = (s1 ? 'OK' : (GPU_TEST.stage1 && GPU_TEST.stage1.forced ? 'packed path off (forced)' : 'packed path FAILED') + ', float fallback in use')
    + (R2.ok ? (s1 ? '' : ', pipeline OK') : ', pipeline check FAILED (rgb ' + (R2.rgb || []).join(',') + ')');
  (R2.ok ? console.info : console.warn)('[HyperVisualizer] GPU colour self-test (feedback + composite): ' + (R2.ok ? 'OK ' : 'FAILED ') + JSON.stringify(R2));
}
function initGL() {
  document.querySelectorAll('[data-start]').forEach(b=>b.disabled=true);
  gl = canvas.getContext('webgl2', { antialias:false, alpha:false, depth:false, stencil:false, premultipliedAlpha:false, preserveDrawingBuffer:false, powerPreference:'high-performance' });
  if (!gl) throw new Error(MOBILE ? 'WebGL 2 is unavailable. It needs iOS 15 or later (Safari) or a recent Chrome on Android.' : 'WebGL 2 is unavailable. Enable hardware acceleration in your browser.'); // MOBILE
  getExtensions();
  gpuSelfTest(); // ADRENO FIX: may switch PACKED off before any realm program is built
  buildPrograms();
  // The realm the app opens on prepares first: the current one after a context loss, else a ?realm= link, else I.
  const linked = REALMS.findIndex(R=>R.key===qs.get('realm'));
  RP.first = D.cur ? D.cur.ri : linked >= 0 ? linked : scnFirst(); // ENGINE v24: 0 unless the person's playlist says otherwise
  makeSpecTex();
  W = H = RW = RH = 0;
  RT.A = RT.B = RT.N = RT.hi = null; RT.fb = [null, null]; RT.down = []; RT.up = [];
  RT.expo = [makeTarget(1, 1), makeTarget(1, 1)];
  [0, 1].forEach((i) => { gl.bindFramebuffer(gl.FRAMEBUFFER, RT.expo[i].fbo); gl.clearColor(0.47, 0, 0, 1); gl.clear(gl.COLOR_BUFFER_BIT); });
  gl.bindFramebuffer(gl.FRAMEBUFFER, null);
}
let pendingStart = null;
function preparationFailed(error) {
  PREPARE.error = String(error.message || error); pendingStart = null;
  spStatus.textContent = PREPARE.error + ' Reload to try again.';
  console.error('[HyperVisualizer] startup:', error);
}
function prepareVisualizer(mode) {
  if (mode === 'full') PREPARE.mode = 'full'; // a request for everything upgrades a start that has not opened yet
  if (PREPARE.requested) return;
  PREPARE.requested = true;
  spStatus.textContent = 'Loading · first load takes a few seconds';
  document.querySelectorAll('[data-start]').forEach(b=>b.disabled=true);
  // Paint the loading message before asking the GPU driver to do any work.
  requestAnimationFrame(() => setTimeout(() => { try { initGL(); } catch (error) { preparationFailed(error); } },0));
}
// MOBILE/context loss: phones drop the WebGL context under memory pressure or after a GPU fault. A realm that was
// warming up or had just appeared when the page was visible is the likely cause: it is skipped after the restore.
const LOST = { bad: new Set(), timer: 0 };
canvas.addEventListener('webglcontextlost', (e) => {
  e.preventDefault(); glReady = false; spStatus.textContent = 'Graphics context lost. Restoring...';
  if (!document.hidden) { const sus = RP.cur >= 0 ? RP.cur : (D.cur && D.timeIn < 3 ? D.cur.ri : -1); if (sus >= 0) LOST.bad.add(sus); }
  if (splashGone) toast('The graphics were reset by the system. Restoring...');
  clearTimeout(LOST.timer); LOST.timer = setTimeout(() => { if (!glReady) toast('The graphics did not come back. Reload the page to continue.'); }, 8000);
});
canvas.addEventListener('webglcontextrestored', () => {
  programs.length = 0; PG = {}; REALMS.forEach((R) => { R.P = null; R.ready = false; R.failed = false; }); PREPARE.error='';
  Q.failedRequest = null; Q.hiFailed = null; clearTimeout(LOST.timer);
  if (D.cur && LOST.bad.has(D.cur.ri)) D.cur = null; // checkPrograms opens the first realm that prepares instead
  // only the current realm is prepared again before the picture returns; anything else in flight is dropped
  Object.assign(D, { nxt: null, upcoming: null, peek: null, queue: null, mix: 0, hurry: false });
  try { initGL(); } catch (error) { preparationFailed(error); }
  LOST.bad.forEach((ri) => { REALMS[ri].failed = true; console.warn('[HyperVisualizer] skipping realm "' + REALMS[ri].key + '" after a context loss'); });
  if (splashGone) toast('Graphics restored.');
});

