/* ============================== input ================================ */
function toLocal(e) { const r = canvas.getBoundingClientRect(); return [(e.clientX - r.left - r.width / 2) / r.height, (r.height / 2 - (e.clientY - r.top)) / r.height]; }
function activity() { lastActivity = TIME; }
const $cur = $('#cur');
let curT = 0;
window.addEventListener('pointermove', (e) => {
  activity();
  if (e.pointerType === 'mouse' && (e.target === canvas || PTR.down)) { $cur.style.transform = 'translate(' + e.clientX + 'px,' + e.clientY + 'px)'; $cur.classList.add('on'); $cur.classList.toggle('press', PTR.down); clearTimeout(curT); curT = setTimeout(() => $cur.classList.remove('on'), PTR.down ? 2400 : 1600); }
  if (e.target !== canvas && !PTR.down) return;
  const [x, y] = toLocal(e); PTR.tx = x; PTR.ty = y; PTR.lastMove = TIME;
  // moving before the singularity latches makes the press a drag: a pure swirl, no hole, no realm change
  if (PTR.down && !PTR.latched && Math.hypot(x - PTR.ox, y - PTR.oy) > 0.03) PTR.dragged = true;
  if (PTR.pts.has(e.pointerId)) { PTR.pts.set(e.pointerId, [x, y]); pinchUpdate(); }
}, { passive: true });
window.addEventListener('mouseout', (e) => { if (!e.relatedTarget) $cur.classList.remove('on'); }, { passive: true });
canvas.addEventListener('pointerdown', (e) => {
  activity();
  if (e.pointerType === 'mouse') $cur.classList.add('press');
  const [x, y] = toLocal(e);
  PTR.pts.set(e.pointerId, [x, y]);
  PTR.touch = e.pointerType !== 'mouse'; if (PTR.touch) touchDown(e); // MOBILE: touch gestures (below)
  if (PTR.pts.size === 2) { PTR.pinch0 = pinchDist(); PTR.zoom0 = PTR.zoomT; PTR.down = false; PTR.latched = false; D.peek = null; return; }
  PTR.tx = x; PTR.ty = y; PTR.down = true; PTR.downT = TIME; PTR.lastMove = TIME;
  PTR.ox = x; PTR.oy = y; PTR.dragged = false; PTR.latched = false;
  try { canvas.setPointerCapture(e.pointerId); } catch (err) { /* ignore */ }
});
function endPointer(e) {
  PTR.pts.delete(e.pointerId);
  if (e.pointerType !== 'mouse') touchUp(e); // MOBILE
  $cur.classList.remove('press');
  if (!PTR.down) { if (!PTR.pts.size) { PTR.latched = false; if (D.peek && D.peek !== D.nxt) D.peek = null; } return; }
  PTR.down = false;
  const held = TIME - PTR.downT;
  if (e.pointerType === 'mouse' && !PTR.dragged && document.body.classList.contains('minimal') && (e.clientY < innerHeight * TAP_EDGE || e.clientY > innerHeight * (1 - TAP_EDGE))) setMinimal(false);
  if (D.peek && held > 0.9) { const v = D.peek; D.tc = [PTR.x, PTR.y]; goRealm(v.ri, 0.85, 0, false, v); D.peek = null; }
  else D.peek = null;
  PTR.latched = false;
}
canvas.addEventListener('pointerup', endPointer);
canvas.addEventListener('pointercancel', endPointer);
function pinchDist() { const v = Array.from(PTR.pts.values()); return v.length < 2 ? 1 : Math.hypot(v[0][0] - v[1][0], v[0][1] - v[1][1]); }
function pinchUpdate() { if (PTR.pts.size === 2 && PTR.pinch0 > 0) { AUTOZ.userT = TIME; zoomTo(PTR.zoom0 * pinchDist() / PTR.pinch0); } }
canvas.addEventListener('wheel', (e) => { e.preventDefault(); activity(); zoomWheel(-clamp(e.deltaY * (e.deltaMode === 1 ? 33 : 1), -240, 240) * 0.0012); }, { passive: false });
canvas.addEventListener('dblclick', () => { if (PTR.touch) return; /* MOBILE: touch double-tap has its own action */ if (D.cur) goRealm(pickRealm(D.nxt ? D.nxt.ri : D.cur.ri), 1.6); });
canvas.addEventListener('contextmenu', (e) => e.preventDefault());
function pointerUpdate(dt) {
  PTR.x = ease(PTR.x, PTR.tx, dt, 0.045); PTR.y = ease(PTR.y, PTR.ty, dt, 0.045);
  const vx = (PTR.x - PTR.px), vy = (PTR.y - PTR.py);
  PTR.sx = ease(PTR.sx || 0, clamp(vx / Math.max(dt, 1e-3), -3, 3), dt, 0.06);
  PTR.sy = ease(PTR.sy || 0, clamp(vy / Math.max(dt, 1e-3), -3, 3), dt, 0.06);
  PTR.px = PTR.x; PTR.py = PTR.y;
  PTR.vx = ease(PTR.vx, clamp(vx, -0.05, 0.05) * 0.9, dt, 0.03);
  PTR.vy = ease(PTR.vy, clamp(vy, -0.05, 0.05) * 0.9, dt, 0.03);
  PTR.press = ease(PTR.press, PTR.down ? 1 : 0, dt, PTR.down ? 0.35 : 0.15);
  const act = (TIME - PTR.lastMove < 2.2 || PTR.down) ? 1 : 0;
  PTR.active = ease(PTR.active, act, dt, act ? 0.15 : 0.9);
  PTR.inf = 0; // v13b: the pointer no longer bends, stirs or opens anything in the picture (the person found it got in the way)
  zoomSpring(dt);
  PTR.lx = ease(PTR.lx, PTR.x * PTR.inf, dt, 0.8); PTR.ly = ease(PTR.ly, PTR.y * PTR.inf, dt, 0.8);
  if (PTR.down) PTR.lastMove = TIME;
  const held = PTR.down ? TIME - PTR.downT : 0;
  // holding still for a moment latches the singularity; after that it can be dragged around
  const lat = PTR.down && PTR.latched;
  if (lat && held > 0.5 && !D.peek && !D.nxt && D.cur) { const ri = D.upcoming ? D.upcoming.ri : pickRealm(D.cur.ri); if (ri >= 0) D.peek = D.upcoming || makeVisit(ri); }
  if (D.peek && D.nxt) D.peek = null;
  if (D.peek && D.peek !== D.upcoming) { D.peek.mt += dt * 0.6; D.peek.trav += dt; D.peek.R.frame(D.peek, F, dt); }
  PTR.hold = ease(PTR.hold || 0, lat ? Math.min((held - 0.35) / 2, 1) : 0, dt, lat ? 0.2 : 0.12);
  PTR.grav = ease(PTR.grav || 0, lat ? 1 : 0, dt, lat ? 0.3 : 0.15);
  HOLE[0] = PTR.x; HOLE[1] = PTR.y; HOLE[2] = 0.025 + 0.075 * PTR.hold; HOLE[3] = PTR.grav > 0.02 ? PTR.grav : 0;
}

/* MOBILE: touch gestures. Tap: next kaleidoscope fold. Tap the top or bottom edge: bring the interface back (or open
   the controls). Horizontal swipe: next realm (left) or back through the realms already shown (right). Hold still
   ~0.55 s: open the controls. Pinch: the shared zoom (pinchUpdate above). Other drags do nothing. */
const TOUCH = { t0: 0, x0: 0, y0: 0, multi: false, long: 0, longFired: false, tapT: 0, lastTap: -1e9, hidden: false, back: null, log: [] };
function touchDown(e) {
  const T = TOUCH, b = document.body.classList;
  clearTimeout(T.long);
  if (PTR.pts.size > 1) { T.multi = true; clearTimeout(T.tapT); return; }
  T.multi = false; T.longFired = false; T.t0 = e.timeStamp; T.x0 = e.clientX; T.y0 = e.clientY;
  T.hidden = b.contains('calm') || b.contains('minimal');
  T.long = setTimeout(() => {
    if (!PTR.down || PTR.dragged || PTR.pts.size !== 1 || !splashGone) return;
    T.longFired = true; T.log.push('long'); setMinimal(false); setPanel(true);
    try { if (navigator.vibrate) navigator.vibrate(12); } catch (err) { /* no haptics */ }
  }, 550);
}
function touchUp(e) {
  const T = TOUCH; clearTimeout(T.long);
  if (T.multi) { if (!PTR.pts.size) T.multi = false; return; } // end of a pinch: nothing else
  if (T.longFired || e.type !== 'pointerup' || !splashGone) return;
  const ms = e.timeStamp - T.t0, dx = e.clientX - T.x0, dy = e.clientY - T.y0;
  T.log.push('up ' + Math.round(ms) + ' ' + Math.round(dx) + ',' + Math.round(dy)); if (T.log.length > 60) T.log.splice(0, 20);
  if (ms < 1000 && Math.abs(dx) > Math.max(50, innerWidth * 0.12) && Math.abs(dx) > 1.6 * Math.abs(dy)) { T.lastTap = -1e9; swipeRealm(dx < 0 ? 1 : -1); return; }
  if (ms > 400 || Math.hypot(dx, dy) > 18) return; // a drag: nothing (the pointer no longer stirs the image)
  touchTap(e.clientY < innerHeight * TAP_EDGE || e.clientY > innerHeight * (1 - TAP_EDGE));
}
// v13b taps (no double-tap, so a tap answers at once): the top or bottom edge brings the interface back (or opens the
// controls when it is already showing), anywhere else steps the kaleidoscope; a tap with the controls or help open
// closes them first
const TAP_EDGE = 0.16;
// the browser's own click from that same tap would land on the interface that just appeared under the finger: drop it
document.addEventListener('click', (e) => { if (performance.now() < (TOUCH.swallow || 0)) { e.stopPropagation(); e.preventDefault(); } }, true);
function touchTap(edge) {
  TOUCH.log.push(edge ? 'edge' : 'tap');
  const b = document.body.classList;
  if ($panel.classList.contains('open')) setPanel(false);
  else if (!$('#help').hidden) toggleHelp(false);
  else if (edge) { TOUCH.swallow = performance.now() + 450; if (b.contains('minimal') || b.contains('calm')) setMinimal(false); else setPanel(true); }
  else cycleKaleido();
  activity();
}
// the kaleidoscope steps Auto -> off -> mirror -> 3 ... 16-fold -> Auto (K key, centre tap); back on Auto, Auto Show
// takes the folds over again
function cycleKaleido() {
  const order = ['auto', '0', '2', '3', '4', '5', '6', '8', '12', '16'];
  S.symmetry = order[(order.indexOf(String(S.symmetry)) + 1) % order.length];
  if (S.symmetry === 'auto' && S.autoShow) setAutoManual('symmetry', false);
  refreshControls(); saveSettings();
  toast('Kaleidoscope: ' + (S.symmetry === 'auto' ? 'auto' : S.symmetry === '0' ? 'off' : S.symmetry === '2' ? 'mirror' : S.symmetry + '-fold'));
}
function swipeRealm(dir) {
  TOUCH.log.push(dir > 0 ? 'next' : 'prev');
  if (!D.cur) return;
  const cur = D.queue ? D.queue[0] : D.nxt ? D.nxt.ri : D.cur.ri;
  let ri = -1;
  if (dir > 0) { TOUCH.back = null; ri = D.upcoming && D.upcoming.ri !== cur ? D.upcoming.ri : pickRealm(cur); }
  else {
    let i = TOUCH.back !== null ? TOUCH.back : D.history.length - 1;
    for (i--; i >= 0; i--) if (D.history[i] !== cur && !REALMS[D.history[i]].failed) break;
    if (i >= 0) { ri = D.history[i]; TOUCH.back = i; }
  }
  if (ri < 0) ri = (cur + dir + REALMS.length) % REALMS.length; // nothing prepared yet: the neighbour (it loads, then opens)
  goRealm(ri, 1.2);
}

/* ENGINE v22 developer overlay: the live music cues, for watching them against real music. Off by default; not reachable
   by accident: open the page with ?cues=1, or press Ctrl+Shift+Y. A DOM panel (no WebGL, nothing drawn into the canvas, so
   renders and recordings never contain it); it reads F after the cues are delivered each frame and redraws about 15 times
   a second. One-frame events (onSection, onImpact, onDownbeat, onPhrase, onNote, and the old onBar, onDrop) are latched
   so they stay lit for 0.35 s. */
const CUE_OV = { el: null, rows: null, t: 0, lit: {}, last: { imp: 0, impT: -9, sec: 0 } };
function cueOvToggle(on) {
  on = on === undefined ? !CUE_OV.el || CUE_OV.el.style.display === 'none' : !!on;
  if (on && !CUE_OV.el) {
    const el = document.createElement('div'); el.id = 'cueOverlay';
    el.style.cssText = 'position:fixed;left:8px;top:8px;z-index:99999;pointer-events:none;font:11px/1.35 ui-monospace,Consolas,monospace;color:#e8e8e8;background:rgba(10,10,14,.78);border:1px solid rgba(255,255,255,.18);border-radius:6px;padding:7px 9px;min-width:330px;white-space:pre';
    document.body.appendChild(el); CUE_OV.el = el;
  }
  if (CUE_OV.el) CUE_OV.el.style.display = on ? 'block' : 'none';
  cueOvHook = on ? cueOvFrame : null;
}
function cueOvFrame(audible) {
  const L = CUE_OV.lit, now = audible;
  for (const k of ['onSection', 'onImpact', 'onDownbeat', 'onPhrase', 'onNote', 'onBar', 'onDrop', 'onKick']) if (F[k]) L[k] = now;
  if (F.onImpact) { CUE_OV.last.imp = F.impactStrength; CUE_OV.last.impT = now; }
  const T = performance.now(); if (T - CUE_OV.t < 66) return; CUE_OV.t = T;
  const on = (k) => now - (L[k] ?? -9) < 0.35, f = (x, d = 2) => (+x).toFixed(d), bar = (x, n = 12) => { x = Math.max(0, Math.min(1, x)); const k = Math.round(x * n); return '█'.repeat(k) + '░'.repeat(n - k); };
  const lamp = (k, label, col) => `<span style="padding:0 3px;border-radius:3px;${on(k) ? 'background:' + col + ';color:#000' : 'color:#666'}">${label}</span>`;
  const sum = F.secLow + F.secMid + F.secHigh + 1e-6, rgb = `rgb(${Math.round(255 * F.secLow / sum * 1.6)},${Math.round(255 * F.secMid / sum * 1.6)},${Math.round(255 * F.secHigh / sum * 1.6)})`;
  const hue = `hsl(${Math.round(F.sectionSeed * 360)},80%,55%)`, sw = (c) => `<span style="display:inline-block;width:22px;height:9px;background:${c};vertical-align:middle;border-radius:2px"></span>`;
  const M = Math.max(1, Math.round(F.meter || 4)), beats = Array.from({ length: M }, (_, i) => i === F.barBeat && F.beatConf > 0.4 ? '●' : '○').join('');
  const pBar = Math.floor(F.phrasePos * 8), phr = Array.from({ length: 8 }, (_, i) => i === pBar ? '■' : '□').join('');
  const ago = now - CUE_OV.last.impT;
  CUE_OV.el.innerHTML =
    `<b>ENGINE v22 CUES</b>  <span style="color:#888">Ctrl+Shift+Y hides</span>\n` +
    `energy   ${bar(F.energy)} ${f(F.energy)}  trend ${F.energyTrend >= 0 ? '+' : ''}${f(F.energyTrend)}\n` +
    `swell    ${bar(F.swell)} ${f(F.swell)}  ${F.swellDir > 0.15 ? 'rising' : F.swellDir < -0.15 ? 'falling' : 'steady'}\n` +
    `tension  ${bar(F.tension)} ${f(F.tension)}  novelty ${f(F.novelty)}\n` +
    `${lamp('onSection', 'SECTION', '#7cf')} #${F.section}  age ${f(F.sectionAge, 1)} s  ${sw(rgb)} ${sw(hue)}\n` +
    `         low ${f(F.secLow)} mid ${f(F.secMid)} high ${f(F.secHigh)} dense ${f(F.secDense)} bright ${f(F.secBright)}\n` +
    `${lamp('onImpact', 'IMPACT', '#f75')}  ${bar(F.impact, 8)} ${f(F.impact)}  last ${f(CUE_OV.last.imp)}${CUE_OV.last.impT > -1 && ago < 60 ? ' (' + f(ago, 1) + ' s ago)' : ''}\n` +
    `${lamp('onDownbeat', 'ONE', '#fd4')} ${lamp('onPhrase', 'PHRASE', '#c8f')}  beat ${beats}  bar ${bar(F.barPhase, 8)}\n` +
    `         phrase bar ${phr} ${pBar + 1}/8\n` +
    `tempo ${f(F.tempo, 1)}  metre ${M}/4  beatConf ${f(F.beatConf)}  downConf ${f(F.downConf)}\n` +
    `${lamp('onNote', 'NOTE', '#9f9')} ${f(F.note)}  sustain ${f(F.sustain)}  bright ${f(F.bright)}\n` +
    `<span style="color:#888">old: bpm ${f(F.bpm, 1)} conf ${f(F.conf)}</span> ${lamp('onKick', 'kick', '#aaa')}${lamp('onBar', 'onBar', '#aaa')}${lamp('onDrop', 'onDrop', '#f5a')} <span style="color:#888">brk ${f(F.breakdown)} build ${f(F.build)}</span>`;
}
window.addEventListener('keydown', (e) => { if (e.ctrlKey && e.shiftKey && !e.altKey && (e.key === 'Y' || e.key === 'y')) { e.preventDefault(); cueOvToggle(); } });
if (qs.get('cues') === '1') { if (document.body) cueOvToggle(true); else window.addEventListener('DOMContentLoaded', () => cueOvToggle(true)); }

window.addEventListener('keydown', (e) => {
  const tag = (e.target && e.target.tagName) || '';
  if (/INPUT|SELECT|TEXTAREA/.test(tag) && e.key !== 'Escape') return;
  if ((tag === 'BUTTON' || tag === 'SUMMARY') && (e.key === ' ' || e.key === 'Enter')) return;
  if (e.metaKey || e.ctrlKey || e.altKey) return;
  activity();
  const k = e.key;
  const cur = D.queue ? D.queue[0] : D.nxt ? D.nxt.ri : (D.cur ? D.cur.ri : 0);
  if (k === ' ') { e.preventDefault(); if (!splashGone) { AU.init();startWhenReady(()=>{hideSplash();AU.startDemo();}); } else if(glReady)togglePlay(); }
  else if (k === 'ArrowRight' || k === 'n' || k === 'N') { if (D.cur) goRealm((cur + 1) % REALMS.length, 1.6); }
  else if (k === 'ArrowLeft') { if (D.cur) goRealm((cur - 1 + REALMS.length) % REALMS.length, 1.6); }
  else if (/^[1-9]$/.test(k) && Number(k) <= REALMS.length) { if (D.cur) goRealm(Number(k) - 1, 1.4); }
  else if (k === 's' || k === 'S') { setAutoShow(!S.autoShow); refreshControls(); }
  else if (k === 'l' || k === 'L') { const V = D.nxt || D.cur; if (V) toggleFavourite(V.R.key); }
  else if (k === 'a' || k === 'A') { setAutoShow(!S.autoShow); refreshControls(); toast('Auto Show '+(S.autoShow?'on':'off')); }
  else if (k === 'b' || k === 'B') { if (D.cur) triggerDrop(true); }
  else if (k === 'r' || k === 'R') reseed();
  else if (k === 'k' || k === 'K') cycleKaleido();
  else if (k === 'c' || k === 'C') { if (S.palette !== 'auto') S.palette = String((Number(S.palette) + 1) % PALETTES.length); else nextPalette(1.2); refreshControls(); saveSettings(); toast('Palette: ' + PALETTES[S.palette === 'auto' ? D.palTo : Number(S.palette)].name); }
  else if (k === '+' || k === '=') { S.dose = clamp(S.dose + 0.1, 0, 2); refreshControls(); saveSettings(); toast('Energy ' + Math.round(S.dose * 100) + '%'); }
  else if (k === '-' || k === '_') { S.dose = clamp(S.dose - 0.1, 0, 1.5); refreshControls(); saveSettings(); toast('Energy ' + Math.round(S.dose * 100) + '%'); }
  else if (k === 't' || k === 'T') AU.tap();
  else if (k === 'g' || k === 'G') setPanel(!$panel.classList.contains('open'));
  else if (k === 'v' || k === 'V') { S.hud = !S.hud; onSetting('hud'); refreshControls(); saveSettings(); }
  else if (k === 'h' || k === 'H') setMinimal(!document.body.classList.contains('minimal'));
  else if (k === 'f' || k === 'F') toggleFullscreen();
  else if (k === 'x' || k === 'X') toggleRecord();
  else if (k === '0') { AUTOZ.userT = TIME; PTR.zoomT = realmHome(D.nxt||D.cur); toast('Scene framing reset'); }
  else if (k === '?' || k === '/') toggleHelp();
  else if (k === 'Escape') { toggleHelp(false); setPanel(false); }
});
['pointerdown', 'keydown', 'wheel'].forEach((ev) => window.addEventListener(ev, activity, { passive: true }));
document.addEventListener('click', (e) => { const b = e.target && e.target.closest && e.target.closest('button'); if (b && e.detail > 0) b.blur(); });
// An AudioContext created outside a gesture (e.g. from a file drop) starts suspended; wake it on the next interaction.
['pointerdown', 'keydown', 'touchend'].forEach((ev) => window.addEventListener(ev, () => { if (AU.ctx && AU.ctx.state === 'suspended') AU.ctx.resume(); }, { passive: true }));

window.addEventListener('pagehide', () => { AU.list.forEach((t) => { try { URL.revokeObjectURL(t.url); } catch (e) { /* ignore */ } }); });

/* drag and drop */
let dragDepth = 0;
window.addEventListener('dragenter', (e) => { if (e.dataTransfer && Array.from(e.dataTransfer.types || []).indexOf('Files') >= 0) { e.preventDefault(); dragDepth++; $('#dropzone').hidden = false; } });
window.addEventListener('dragover', (e) => { e.preventDefault(); });
window.addEventListener('dragleave', () => { dragDepth = Math.max(0, dragDepth - 1); if (!dragDepth) $('#dropzone').hidden = true; });
window.addEventListener('drop', (e) => { e.preventDefault(); dragDepth = 0; $('#dropzone').hidden = true; if (e.dataTransfer && e.dataTransfer.files.length) gatherDrop(e.dataTransfer).then(startFiles); });

