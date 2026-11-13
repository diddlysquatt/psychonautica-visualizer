/* ============================= WebGL core ============================= */
const canvas = $('#stage');
let gl = null;
const spStatus = $('#spStatus');
let HALF = false, PAR = null, vao = null, MAXTEX = 4096;
// ADRENO FIX: PACKED = realm targets are the single RGBA32UI packed attachment. The start-up self-test (gpuSelfTest)
// clears it if the packed round trip is wrong on this GPU; realms then render into an ordinary float target and the
// feedback pass reads FS_FEEDBACK_FLOAT (colour only; realm "windows" are switched off). ?packed=0 forces it (testing).
let PACKED = qs.get('packed') !== '0';
const GPU_TEST = { stage1: null, stage2: null, text: '' };
function getExtensions() {
  HALF = !!(gl.getExtension('EXT_color_buffer_float') || gl.getExtension('EXT_color_buffer_half_float'));
  gl.getExtension('OES_texture_float_linear');
  PAR = gl.getExtension('KHR_parallel_shader_compile');
  MAXTEX = Math.min(gl.getParameter(gl.MAX_TEXTURE_SIZE) || 4096, gl.getParameter(gl.MAX_RENDERBUFFER_SIZE) || 4096, 16384);
  vao = gl.createVertexArray();
  // MOBILE: some mobile drivers expose a colour-buffer extension yet refuse an RGBA16F framebuffer; probe one and fall
  // back to 8-bit targets (the uPack paths) instead of failing every allocation later.
  if (HALF) {
    const t = gl.createTexture(), f = gl.createFramebuffer();
    gl.bindTexture(gl.TEXTURE_2D, t); gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, 4, 4, 0, gl.RGBA, gl.HALF_FLOAT, null);
    gl.bindFramebuffer(gl.FRAMEBUFFER, f); gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, t, 0);
    if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) !== gl.FRAMEBUFFER_COMPLETE) { HALF = false; console.warn('[HyperVisualizer] RGBA16F targets unsupported; using 8-bit targets.'); }
    gl.bindFramebuffer(gl.FRAMEBUFFER, null); gl.deleteFramebuffer(f); gl.deleteTexture(t);
  }
}

function fmt() { return HALF ? { i: gl.RGBA16F, f: gl.RGBA, t: gl.HALF_FLOAT } : { i: gl.RGBA8, f: gl.RGBA, t: gl.UNSIGNED_BYTE }; }
function texFor(w, h, wrap) {
  const F = fmt();
  const tex = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, tex);
  gl.texImage2D(gl.TEXTURE_2D, 0, F.i, w, h, 0, F.f, F.t, null);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap || gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap || gl.CLAMP_TO_EDGE);
  return tex;
}
// packed = a realm target: ONE RGBA32UI attachment holding half-float colour + window mask and the window coordinates
// (written by REALM_MAIN_PACKED, unpacked by the feedback pass). One attachment instead of two keeps ANGLE D3D11 from
// compiling every realm a second time, synchronously, at its first draw.
function makeTarget(w, h, wrap, packed) {
  packed = !!packed && PACKED; // ADRENO FIX fallback: no integer realm targets
  const F = fmt();
  const tex = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, tex);
  if (packed) gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA32UI, w, h, 0, gl.RGBA_INTEGER, gl.UNSIGNED_INT, null);
  else gl.texImage2D(gl.TEXTURE_2D, 0, F.i, w, h, 0, F.f, F.t, null);
  const filter = packed ? gl.NEAREST : gl.LINEAR; // integer textures are never filtered; the feedback pass samples by hand
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, filter);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, filter);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap || gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap || gl.CLAMP_TO_EDGE);
  const fbo = gl.createFramebuffer();
  gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
  gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex, 0);
  const ok = gl.checkFramebufferStatus(gl.FRAMEBUFFER) === gl.FRAMEBUFFER_COMPLETE;
  gl.bindFramebuffer(gl.FRAMEBUFFER, null);
  if (!ok || !tex || !fbo) { gl.deleteTexture(tex); gl.deleteFramebuffer(fbo); throw new Error('GPU could not allocate ' + w + ' × ' + h + '. Choose a lower resolution.'); }
  return { tex, fbo, w, h, packed: !!packed };
}
// clear any target to black (integer targets need clearBuffer; gl.clear on them is an error)
function clearTarget(t, rgba) {
  gl.bindFramebuffer(gl.FRAMEBUFFER, t.fbo);
  if (t.packed) gl.clearBufferuiv(gl.COLOR, 0, new Uint32Array(4));
  else { gl.clearColor(...(rgba || [0, 0, 0, 0])); gl.clear(gl.COLOR_BUFFER_BIT); }
}
function freeTarget(t) { if (t) { gl.deleteTexture(t.tex); gl.deleteFramebuffer(t.fbo); } }

let vsObj = null;
const programs = [];
function compileShader(type, src) { const s = gl.createShader(type); gl.shaderSource(s, src); gl.compileShader(s); return s; }
function makeProgram(name, src) {
  const fs = compileShader(gl.FRAGMENT_SHADER, src);
  const p = gl.createProgram();
  gl.attachShader(p, vsObj); gl.attachShader(p, fs); gl.linkProgram(p);
  const P = { name, p, fs, src, ok: null, L: Object.create(null) };
  programs.push(P);
  return P;
}
function programDone(P) { return !PAR || gl.getProgramParameter(P.p, PAR.COMPLETION_STATUS_KHR); }
function finalizeProgram(P) {
  if (P.ok !== null) return P.ok;
  P.ok = !!gl.getProgramParameter(P.p, gl.LINK_STATUS);
  if (!P.ok) {
    const log = (gl.getShaderInfoLog(P.fs) || '') + (gl.getProgramInfoLog(P.p) || '');
    const numbered = P.src.split('\n').map((l, i) => String(i + 1).padStart(4) + ' ' + l).join('\n');
    P.log = log; // ENGINE v24: kept so a scene pack can report why it was refused
    console.error('[HyperVisualizer] shader "' + P.name + '" failed:\n' + log + '\n' + numbered);
  }
  return P.ok;
}
function loc(P, n) { let l = P.L[n]; if (l === undefined) { l = gl.getUniformLocation(P.p, n); P.L[n] = l; } return l; }
const u1 = (P, n, x) => { const l = loc(P, n); if (l) gl.uniform1f(l, x); };
const u2 = (P, n, x, y) => { const l = loc(P, n); if (l) gl.uniform2f(l, x, y); };
const u3 = (P, n, v) => { const l = loc(P, n); if (l) gl.uniform3f(l, v[0], v[1], v[2]); };
const u4 = (P, n, v) => { const l = loc(P, n); if (l) gl.uniform4f(l, v[0], v[1], v[2], v[3]); };
const ui = (P, n, x) => { const l = loc(P, n); if (l) gl.uniform1i(l, x); };
const um3 = (P, n, m) => { const l = loc(P, n); if (l) gl.uniformMatrix3fv(l, false, m); };
function bindTex(unit, tex) { gl.activeTexture(gl.TEXTURE0 + unit); gl.bindTexture(gl.TEXTURE_2D, tex); }
function drawTo(target, w, h, realm) {
  gl.bindFramebuffer(gl.FRAMEBUFFER, target ? target.fbo : null); gl.viewport(0, 0, w, h);
  // Scissor keeps the same full-size framebuffer, gl_FragCoord and derivatives. It only bounds each draw.
  // https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/scissor
  // Shorter submissions help extreme renders coexist with display-driver scheduling; no OS limits change.
  const forced = realm && Number.isFinite(DBG.tileSize) ? Math.max(0, Math.floor(DBG.tileSize / 2) * 2) : null;
  const tile = forced !== null ? forced : realm && (OFF.on || effectiveDetail() > 2.5) && w * h > 2e6 ? 512 : 0;
  if (!tile) { gl.drawArrays(gl.TRIANGLES, 0, 3); return; }
  gl.enable(gl.SCISSOR_TEST);
  try {
    for (let y = 0; y < h; y += tile) {
      for (let x = 0; x < w; x += tile) {
        gl.scissor(x, y, Math.min(tile, w - x), Math.min(tile, h - y)); gl.drawArrays(gl.TRIANGLES, 0, 3);
      }
      gl.flush();
    }
  } finally { gl.disable(gl.SCISSOR_TEST); }
}

let PG = {};
let glReady = false;
// Realm programs write ONE packed RGBA32UI target (see makeTarget): the two outputs COMMON declares become plain
// globals and REALM_MAIN_PACKED packs them. COMMON and REALM_MAIN themselves stay as they are for the realm tools.
const COMMON_PACKED = COMMON.replace('layout(location=0) out vec4 fragColor;', 'vec4 fragColor;')
  .replace('layout(location=1) out vec4 fragWin;', 'vec4 fragWin;\nlayout(location=0) out highp uvec4 fragPack;' + HALF_GLSL);
const REALM_MAIN_PACKED = `
void main(){fragColor=vec4(0.);fragWin=vec4(.5,.5,0.,0.);realm();fragPack=uvec4(hvPack(fragColor.rg),hvPack(fragColor.ba),hvPack(fragWin.xy),hvPack(fragWin.zw));}`; // ADRENO FIX: manual half packing
// ADRENO FIX fallback (PACKED false): the realm writes fragColor only into a float target; fragWin becomes a global.
const COMMON_FLOAT = COMMON.replace('layout(location=1) out vec4 fragWin;', 'vec4 fragWin;');
// v19 detail range. HD is a compile-time tier for the realm shaders: 0 for Auto, Low, Medium, High and every phone, 1 Native,
// 2 Cinema, 3 Insane, 4 Extreme, 5 Offline. Code a realm gates with #if HD>=n costs lower tiers nothing, in compile time or GPU.
// Runtime detail (uDetail) also rises with the resolution tier, so Native and above draw more, not just the same at more pixels.
const HD_BY_QUALITY = { ultra: 1, cinema: 2, insane: 3, extreme: 4, offline: 5 };
const DETAIL_BY_QUALITY = { ultra: 2, cinema: 3, insane: 4.5, extreme: 6.5, offline: 10 };
function wantedHD() { return MOBILE ? 0 : (HD_BY_QUALITY[E.quality] || 0); }
let HD_NOW = 0;
const withHD = (src) => HD_NOW ? src.replace('\n', '\n#define HD ' + HD_NOW + '\n') : src;
const realmSource = (R) => withHD(PACKED ? COMMON_PACKED + R.src + REALM_MAIN_PACKED : COMMON_FLOAT + R.src + REALM_MAIN);
const HDS = { want: 0, t: 0, P: null, ri: -1, hd: 0 };
function releaseRealmProgram(R) {
  const k = programs.indexOf(R.P);
  gl.deleteProgram(R.P.p); gl.deleteShader(R.P.fs); if (k >= 0) programs.splice(k, 1);
  R.P = null; R.ready = false; R.failed = false;
}
// A change of tier recompiles: realms off screen go back through the normal background queue; the realm on screen keeps its
// old program until the new one has linked, then swaps in place, so the picture never stops.
function hdUpdate() {
  if (OFF.on || MOBILE) return;
  const want = wantedHD(), now = performance.now();
  if (want !== HDS.want) { HDS.want = want; HDS.t = now; }
  if (want !== HD_NOW && now - HDS.t > 600) HD_NOW = want; // stepping through the menu does not start a compile per item
  if (HDS.P) {
    if (!programDone(HDS.P)) return;
    const R = REALMS[HDS.ri], P = HDS.P, k = programs.indexOf(P); HDS.P = null;
    if (finalizeProgram(P) && R.P && R.ready) { const old = R.P, i = programs.indexOf(old); gl.deleteProgram(old.p); gl.deleteShader(old.fs); if (i >= 0) programs.splice(i, 1); R.P = P; R.hd = HDS.hd; }
    else { gl.deleteProgram(P.p); gl.deleteShader(P.fs); if (k >= 0) programs.splice(k, 1); R.hd = HDS.hd; } // keep the old picture; do not retry this tier
    return;
  }
  const inUse = new Set([D.cur, D.nxt, D.upcoming, D.peek].filter(Boolean).map((V) => V.ri));
  let changed = false;
  REALMS.forEach((R, i) => { if (R.P && (R.ready || R.failed) && (R.hd || 0) !== HD_NOW && !inUse.has(i)) { releaseRealmProgram(R); changed = true; } });
  if (changed) markRealmStates();
  for (const i of inUse) { const R = REALMS[i]; if (R.P && R.ready && (R.hd || 0) !== HD_NOW) { HDS.P = makeProgram(R.key, realmSource(R)); HDS.ri = i; HDS.hd = HD_NOW; break; } }
}
const FS_FEEDBACK_FLOAT = FS_FEEDBACK.replace('uniform highp usampler2D uA,uB,uN;', 'uniform highp sampler2D uA,uB,uN;')
  .split('highp usampler2D t').join('highp sampler2D t')
  .replace(/vec4 colAt\(highp sampler2D t,vec2 i,vec2 n\)\{[^\n]*\}/, 'vec4 colAt(highp sampler2D t,vec2 i,vec2 n){vec4 c=texelFetch(t,mirrorTexel(i,n),0);return vec4(c.rgb,0.);}')
  .replace(/vec4 winAt\(highp sampler2D t,vec2 i,vec2 n\)\{[^\n]*\}/, 'vec4 winAt(highp sampler2D t,vec2 i,vec2 n){return vec4(.5,.5,0.,0.);}');
const POST_NAMES = ['feedback', 'bloomDown', 'bloomUp', 'upscale', 'composite', 'shadowComposite', 'exposure'];
// mode 'fast' (a person pressing enter): the app opens once the post programs and the first realm are ready and the
// other realms prepare in the background. mode 'full' (HyperVisualizer.prepare(), tools, offline renders): ready
// only when every realm is.
const PREPARE = { requested: false, error: '', mode: 'fast', queue: [], compileIndex: 0, finalized: false, displayDone: false, started: 0, timings: [], displayStarted:0, displayFence:null, displayMs:0,displayIndex:0,displayTargets:null,displayStepStarted:0,displayTimings:[], firstMs: 0 };
// Realm preparation, a two-stage pipeline with one realm in each stage:
//  1. link: one program at a time; KHR_parallel_shader_compile keeps it on the driver's worker threads, off the page
//     and off the GPU process' main thread, so live frames keep coming.
//  2. settle + warm: a pause after linking (the driver finishes its own compile on its threads; a draw issued straight
//     away waits for it inside the GPU process and stalls every frame, ~0.45 s for the biggest realms on D3D11), then
//     one draw into a 2x2 packed target behind a fence.
// A realm is selectable (R.ready) only after both. RP.want is a realm the person asked for: it jumps the queue and
// opens once ready.
const RP = { link: -1, settle: [], cur: -1, fence: null, target: null, want: null, first: 0 };
function realmReady(ri) { const R = REALMS[ri]; return !!(R && R.ready); }
function realmsSettled() { return REALMS.every((R) => R.ready || R.failed); }
function realmPrepBusy() { return RP.link >= 0 || RP.settle.length > 0 || RP.cur >= 0; }
function buildPrograms() {
  programs.length = 0;
  Object.assign(PREPARE,{queue:[],compileIndex:0,finalized:false,displayDone:false,started:performance.now(),timings:[],displayStarted:0,displayFence:null,displayMs:0,displayIndex:0,displayTargets:null,displayStepStarted:0,displayTimings:[],firstMs:0});
  if (RP.fence) gl.deleteSync(RP.fence);
  Object.assign(RP, { link: -1, settle: [], cur: -1, fence: null, target: null, want: null });
  vsObj = compileShader(gl.VERTEX_SHADER, VS);
  HDS.P = null; HD_NOW = wantedHD(); HDS.want = HD_NOW;
  REALMS.forEach(R => { R.P = null; R.hd = 0; R.ready = false; R.failed = false; });
  PG = {};
  for (const [key,name,src] of [['fb','feedback',PACKED?FS_FEEDBACK:FS_FEEDBACK_FLOAT],['down','bloomDown',FS_DOWN],['up','bloomUp',FS_UP],['easu','upscale',FS_EASU],['comp','composite',FS_COMPOSITE],['shadowComp','shadowComposite',FS_SHADOW_COMPOSITE],['expo','exposure',FS_EXPO]]) {
    PREPARE.queue.push({ name, src, assign:P=>{ PG[key]=P; } });
  }
}
function nextRealmToPrepare() {
  const open = (i) => i >= 0 && i < REALMS.length && !REALMS[i].ready && !REALMS[i].failed && !REALMS[i].P;
  if (RP.want && open(RP.want.ri)) return RP.want.ri;
  if (open(RP.first)) return RP.first;
  for (const vi of SCN.verify) if (open(vi)) return vi; // ENGINE v24: a scene pack waiting for its compile check
  if (MOBILE && PREPARE.mode !== 'full') return mobileNextToPrepare(open);
  for (let i = D.bag.length - 1; i >= 0; i--) if (open(D.bag[i])) return D.bag[i]; // the order autopilot will visit them
  for (let i = 0; i < REALMS.length; i++) if (open(i)) return i;
  return -1;
}
/* MOBILE: lazy realm preparation. Phones compile big shaders slowly, often on the page's own thread (Safari has no
   KHR_parallel_shader_compile) and with little GPU memory, so only the realm on screen plus MOBILE_AHEAD realms the
   playlist will show next are prepared; anything else compiles when it is picked (RP.want), and at most MOBILE_KEEP
   realm programs stay linked (the least recently shown one is released). A realm that fails is skipped (R.failed). */
function mobileNextToPrepare(open) {
  if (!D.cur) { // nothing on screen yet: if the first realm failed, try the cheapest remaining one
    if (REALMS.some((R) => (R.ready || R.P) && !R.failed)) return -1; // one is ready or still in flight
    let best = -1; REALMS.forEach((R, i) => { if (open(i) && (best < 0 || (R.cost || 2) < (REALMS[best].cost || 2))) best = i; });
    return best;
  }
  let ahead = 0;
  for (let i = D.bag.length - 1; i >= 0; i--) {
    const ri = D.bag[i], R = REALMS[ri];
    if (ri === D.cur.ri || R.failed) continue;
    if (R.ready || R.P) { if (++ahead >= MOBILE_AHEAD) return -1; continue; }
    if (open(ri)) return ri;
  }
  return -1;
}
function mobileEvictRealm() {
  if (!MOBILE || PREPARE.mode === 'full' || REALMS.filter((R) => R.P).length < MOBILE_KEEP) return;
  const keep = new Set([D.cur, D.nxt, D.upcoming, D.peek].filter(Boolean).map((V) => V.ri));
  if (RP.want) keep.add(RP.want.ri); if (D.queue) keep.add(D.queue[0]); [RP.link, RP.cur].forEach((ri) => keep.add(ri)); RP.settle.forEach((x) => keep.add(x.ri));
  for (let i = D.bag.length - 1, n = 0; i >= 0 && n < MOBILE_AHEAD; i--) if (REALMS[D.bag[i]].ready && !keep.has(D.bag[i])) { keep.add(D.bag[i]); n++; }
  let victim = -1;
  REALMS.forEach((R, i) => { if (R.P && R.ready && !keep.has(i) && (victim < 0 || D.history.lastIndexOf(i) < D.history.lastIndexOf(victim))) victim = i; });
  if (victim < 0) return;
  const R = REALMS[victim], k = programs.indexOf(R.P);
  gl.deleteProgram(R.P.p); gl.deleteShader(R.P.fs); if (k >= 0) programs.splice(k, 1);
  R.P = null; R.ready = false; markRealmStates();
}
// Advance realm preparation by one step of each stage. Returns true when it progressed without waiting on the GPU.
// DBG.prep logs state changes and slow steps (start time, change, time on the page's thread) for hitch hunting.
function realmPrepState() { return (RP.link >= 0 ? 'link ' + REALMS[RP.link].key : '') + (RP.settle.length ? ' settle ' + RP.settle.map((x) => REALMS[x.ri].key).join(',') : '') + (RP.cur >= 0 ? ' warm ' + REALMS[RP.cur].key : ''); }
function stepRealmPrep() {
  const t = performance.now(), before = realmPrepState();
  const out = stepRealmPrepInner(), ms = performance.now() - t, after = realmPrepState();
  if (before !== after || ms > 20) { (DBG.prep = DBG.prep || []).push([Math.round(t), before + ' > ' + after, Math.round(ms)]); if (DBG.prep.length > 300) DBG.prep.shift(); }
  return out;
}
function stepRealmPrepInner() {
  let progressed = false;
  // stage 2b: a warm-up draw in flight
  if (RP.cur >= 0) {
    const ri = RP.cur, R = REALMS[ri], status = gl.clientWaitSync(RP.fence, 0, 0);
    if (status !== gl.TIMEOUT_EXPIRED) {
      gl.deleteSync(RP.fence); RP.fence = null; RP.cur = -1; progressed = true;
      if (status === gl.WAIT_FAILED) R.failed = true; else R.ready = true;
      PREPARE.timings.push({ key: R.key, ms: Math.round(performance.now() - R.prepT0), linkMs: Math.round(R.linkMs), at: Math.round(performance.now()) });
      realmStateChanged(ri);
    }
  }
  // stage 2a: the next settled realm draws once (the person's choice first)
  if (RP.cur < 0 && RP.settle.length) {
    const wi = RP.want ? RP.settle.findIndex((x) => x.ri === RP.want.ri) : -1, item = RP.settle[wi > 0 ? wi : 0];
    if (performance.now() >= item.at) {
      RP.settle.splice(RP.settle.indexOf(item), 1); progressed = true;
      const ri = item.ri, R = REALMS[ri];
      // Exercise the actual packed scene pipeline once, without changing visits or seeded output. The shader sees a
      // 1280x720 frame (the draw covers its corner), so it runs its usual per-pixel work.
      if (!RP.target) RP.target = makeTarget(2, 2, gl.MIRRORED_REPEAT, true);
      const savedRand = rand;
      try {
        rand = mulberry(0x51f15e7d + ri);
        const V = makeVisit(ri), quiet = Object.assign({}, F, { onKick: false, onHit: false, onDrop: false, onBar: false });
        V.R.frame(V, quiet, 0); gl.bindVertexArray(vao); renderRealm(V, RP.target, [1280, 720]);
        RP.fence = gl.fenceSync(gl.SYNC_GPU_COMMANDS_COMPLETE, 0); gl.flush(); RP.cur = ri;
      } catch (error) {
        console.error('[HyperVisualizer] realm "' + R.key + '" failed to start:', error);
        R.startError = String(error && error.message || error); R.failed = true; realmStateChanged(ri); // ENGINE v24: startError
      } finally { rand = savedRand; gl.bindFramebuffer(gl.FRAMEBUFFER, null); }
    }
  }
  // stage 1: link
  if (RP.link >= 0) {
    const ri = RP.link, R = REALMS[ri];
    if (programDone(R.P)) {
      RP.link = -1; progressed = true; R.linkMs = performance.now() - R.prepT0;
      if (!finalizeProgram(R.P)) { R.failed = true; realmStateChanged(ri); }
      // the settle pause scales with the link time; before the app opens nothing is waiting on frames, so none
      else RP.settle.push({ ri, at: performance.now() + (glReady ? Math.min(3000, 300 + 0.25 * R.linkMs) : 0) });
    }
  }
  if (RP.link < 0) {
    const ri = nextRealmToPrepare();
    if (ri >= 0) { mobileEvictRealm(); const R = REALMS[ri]; R.prepT0 = performance.now(); R.P = makeProgram(R.key, realmSource(R)); R.hd = HD_NOW; RP.link = ri; progressed = true; }
  }
  if (!realmPrepBusy() && RP.target) { freeTarget(RP.target); RP.target = null; }
  return progressed;
}
function realmStateChanged(ri) {
  scnVerified(ri); // ENGINE v24: a scene pack passed or failed its compile check
  markRealmStates();
  const w = RP.want;
  if (!w || w.ri !== ri) return;
  RP.want = null;
  if (REALMS[ri].ready && glReady && D.cur) goRealm(ri, w.dur, w.style);
  else if (REALMS[ri].failed) toast(REALMS[ri].name + ' could not be prepared on this GPU.');
}

/* spectrum texture: row 0 = log spectrum, row 1 = waveform */
const NB = 256;
const specBytes = new Uint8Array(NB * 2);
let specTex = null;
function makeSpecTex() {
  specTex = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, specTex);
  gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.R8, NB, 2, 0, gl.RED, gl.UNSIGNED_BYTE, specBytes);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
}

/* render targets */
let W = 0, H = 0, RW = 0, RH = 0;
const RT = { A: null, B: null, N: null, hi: null, fb: [null, null], cur: 0, down: [], up: [], expo: [null, null], ei: 0 };
const BLOOM_LEVELS = 5;
function allocTargets(rw, rh) {
  // Commit the whole new set atomically. A failed extreme allocation must leave the last valid scene intact.
  const created = [], make = (...args) => { const t = makeTarget(...args); created.push(t); return t; };
  try {
    const next = { A: make(rw, rh, gl.MIRRORED_REPEAT, true), B: make(rw, rh, gl.MIRRORED_REPEAT, true),
      N: make(Math.max(1, Math.round(rw / 3)), Math.max(1, Math.round(rh / 3)), gl.MIRRORED_REPEAT, true),
      fb: [make(rw, rh), make(rw, rh)], down: [], up: [] };
    let w = rw, h = rh;
    for (let i = 0; i < BLOOM_LEVELS; i++) {
      w = Math.max(1, w >> 1); h = Math.max(1, h >> 1);
      next.down.push(make(w, h)); next.up.push(i < BLOOM_LEVELS - 1 ? make(w, h) : null);
    }
    const keep = RT.fb[RT.cur];
    if (keep) {
      gl.bindFramebuffer(gl.READ_FRAMEBUFFER, keep.fbo); gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, next.fb[0].fbo);
      gl.blitFramebuffer(0, 0, keep.w, keep.h, 0, 0, rw, rh, gl.COLOR_BUFFER_BIT, gl.LINEAR);
    }
    [RT.A, RT.B, RT.N, ...RT.fb, ...RT.down, ...RT.up].forEach(freeTarget);
    Object.assign(RT, next, { cur: 0 }); RW = rw; RH = rh;
  } catch (error) { created.forEach(freeTarget); throw error; }
  finally { gl.bindFramebuffer(gl.FRAMEBUFFER, null); }
}

