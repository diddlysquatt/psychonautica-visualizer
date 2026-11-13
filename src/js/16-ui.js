/* ================================ UI ================================= */
const $realmTag = $('#realmTag'), $realmName = $('#realmName');
let realmDimT = 0;
function announceRealm(ri) {
  const R = REALMS[ri];
  $realmName.textContent = R.name;
  $realmTag.classList.remove('enter', 'dim'); void $realmTag.offsetWidth; $realmTag.classList.add('enter');
  realmDimT = 3;
}
function markRealmChips(ri) { scnMark(ri); document.querySelectorAll('.realm-chip').forEach((b) => b.setAttribute('aria-pressed', String(Number(b.dataset.ri) === ri))); }
// Cards of realms still preparing in the background read 'loading' (or 'opens when ready' once clicked).
function markRealmStates() {
  document.querySelectorAll('.realm-chip').forEach((b) => {
    const R = REALMS[Number(b.dataset.ri)]; if (!R) return;
    const state = R.ready ? 'ready' : R.failed ? 'failed' : RP.want && RP.want.ri === Number(b.dataset.ri) ? 'queued' : (MOBILE && !R.P && PREPARE.mode !== 'full') ? 'later' : 'loading'; // MOBILE: 'later' = prepared on demand
    if (b.dataset.state !== state) { b.dataset.state = state; b.setAttribute('aria-disabled', String(state === 'failed')); b.title = b.dataset.tip + ({ loading: ' (loading)', queued: ' (opens when ready)', failed: ' (unavailable)', later: '' }[state] || ''); }
  });
}
function buildRealmChips() {
  const host = $('#realmChips'); host.innerHTML = '';
  const descriptions={gate:'Neon chrysanthemum funnel',lattice:'Hyperbolic LED honeycombs',mandala:'Living jewelled mandala',klnn:'Kleinian curl architecture',boxx:'Infinite folded box city',cathedral:'Machine elves and recursive vaults',foam:'Porous fractal chambers'};
  REALMS.forEach((R, i) => {
    const b = document.createElement('button');
    b.className = 'realm-chip'; b.dataset.ri = i; b.setAttribute('aria-pressed', 'false');
    // v12: number and name only; the description is the hover tooltip
    b.innerHTML = '<b class="chip-state" aria-hidden="true"></b><small></small><span class="rc-name"></span>';
    b.querySelector('small').textContent = i + 1; b.querySelector('.rc-name').textContent = R.name;
    const description=descriptions[R.key]||R.description;
    b.dataset.tip = R.name + (description ? ': ' + description : '') + (i < 9 ? ' (' + (i + 1) + ')' : ''); b.title = b.dataset.tip;
    b.dataset.search=[R.name,R.key,description||''].join(' ').toLowerCase();
    const star = document.createElement('span'); star.className = 'fav'; star.textContent = '★'; star.title = 'Favourite (L)'; star.setAttribute('aria-hidden', 'true');
    star.addEventListener('click', (e) => { e.stopPropagation(); toggleFavourite(R.key); });
    b.appendChild(star); if (S.favs.includes(R.key)) b.dataset.fav = '1';
    b.addEventListener('click', () => { if (RP.want) { RP.want = null; markRealmStates(); } goRealm(i, 1.6); }); // the newest choice wins
    host.appendChild(b);
  });
  if (D.cur) markRealmChips(D.nxt ? D.nxt.ri : D.cur.ri);
  markRealmStates();
}

let toastT = 0;
function toast(msg, ms) { const t = $('#toast'); t.textContent = msg; t.classList.add('show'); clearTimeout(toastT); toastT = setTimeout(() => t.classList.remove('show'), ms || 3800); }

// v12: the controls drawer. One line per control, grouped into collapsible sections (open/closed state is remembered
// per viewer); each row's title attribute is its one-line hint. Rows whose key is in AUTO_KEYS carry a small badge while
// Auto Show is on: "auto" (the show is choosing; the row shows its live choice) or "manual" (the person took it over;
// click it to give it back).
const CONTROLS = [
  { sec: 'show', title: 'Show', open: true },
  { key: 'vibe', type: 'preset', label: 'Vibe', tip: 'A whole mood in one tap: Energy, Speed and the pace of the show', options: [
    ['chill', 'Chill', { dose: 0.7, speed: 0.7, warp: 0.4, trails: 0.5, colorSpeed: 0.4, chroma: 0.3, bloom: 0.7, switchBars: 64 }],
    ['trip', 'Trip', { dose: 1, speed: 1, warp: 0.55, trails: 0.6, colorSpeed: 0.6, chroma: 0.5, bloom: 0.8, switchBars: 32 }],
    ['insane', 'Insane', { dose: 1.8, speed: 1.5, warp: 1.2, trails: 0.85, colorSpeed: 1.5, chroma: 1, bloom: 1.15, switchBars: 16 }]] },
  { key: 'symmetry', type: 'select', label: 'Kaleidoscope', tip: 'Fold the image. Auto uses the folds each scene looks best with (K)', options: [['auto', 'Auto'], ['0', 'Off'], ['2', 'Mirror'], ['3', '3-fold'], ['4', '4-fold'], ['5', '5-fold'], ['6', '6-fold'], ['8', '8-fold'], ['12', '12-fold'], ['16', '16-fold']] },
  { key: 'autoKal', type: 'seg', label: 'Auto folds', str: true, tip: 'How much the Auto Show folds scenes into kaleidoscopes', options: [['off', 'Off'], ['subtle', 'Some'], ['lots', 'Lots']] },
  { key: 'autopilot', type: 'toggle', label: 'Autopilot', tip: 'Move to the next scene on phrases and drops (A)' },
  { key: 'favMode', type: 'seg', label: 'Play', str: true, tip: 'Star scenes below (or press L) to play only your favourites', options: [['all', 'All'], ['favs', '★ Favs']] },
  { sec: 'realms', title: 'Realms', open: true, el: '#grp-realms' },
  { sec: 'feel', title: 'Feel' },
  { key: 'dose', type: 'range', label: 'Energy', min: 0, max: 2, step: 0.01, fmt: (v) => Math.round(v * 100) + '%', tip: 'How hard scenes react to the music (+ and -)' },
  { key: 'reactivity', type: 'range', label: 'Sensitivity', min: 0.3, max: 2.5, step: 0.01, fmt: (v) => v.toFixed(2) + 'x', tip: 'How far scenes move with the music' },
  { key: 'flashes', type: 'range', label: 'Flashes', min: 0, max: 1, step: 0.01, fmt: (v) => Math.round(v * 100) + '%', tip: 'Flash, kick zoom and snare spin strength. Lower it if flashes are uncomfortable' },
  { key: 'speed', type: 'range', label: 'Speed', min: 0, max: 2.5, step: 0.01, fmt: (v) => v.toFixed(2) + 'x', tip: 'How fast scenes travel and animate' },
  { key: 'motionSmooth', type: 'range', label: 'Smoothness', min: 0, max: 1, step: 0.01, fmt: (v) => Math.round(v * 100) + '%', tip: 'Low snaps to every hit, high glides' },
  { sec: 'look', title: 'Look' },
  { key: 'palette', type: 'select', label: 'Palette', tip: 'Auto morphs with the music (C)', options: [['auto', 'Auto']].concat(PALETTES.map((p, i) => [String(i), p.name])) },
  // the dial is quadratic (fine control near still colours, up to 6x at the end); the default 0.6x sits near a third
  { key: 'colorSpeed', type: 'range', label: 'Color flow', min: 0, max: 1, step: 0.002, map: (x) => +(6 * x * x).toFixed(3), unmap: (v) => Math.sqrt(clamp(v, 0, 6) / 6), fmt: (v) => (+v).toFixed(2) + 'x', tip: 'How fast colours drift and palettes change' },
  { key: 'saturation', type: 'range', label: 'Saturation', min: 0, max: 1.6, step: 0.01, fmt: (v) => Math.round(v * 100) + '%', tip: '0 is black and white' },
  { key: 'trails', type: 'range', label: 'Trails', min: 0, max: 1, step: 0.01, fmt: (v) => Math.round(v * 100) + '%', tip: 'Glowing streaks behind moving light' },
  { key: 'warp', type: 'range', label: 'Warp', min: 0, max: 1.5, step: 0.01, fmt: (v) => Math.round(v * 100) + '%', tip: 'Liquid heat-haze flow that breathes with the bass' },
  { key: 'bloom', type: 'range', label: 'Glow', min: 0, max: 1.6, step: 0.01, fmt: (v) => Math.round(v * 100) + '%', tip: 'Light bleeding around bright shapes' },
  { key: 'chroma', type: 'range', label: 'Prism', min: 0, max: 1.5, step: 0.01, fmt: (v) => Math.round(v * 100) + '%', tip: 'Prism colour split toward the edges' },
  { sec: 'journey', title: 'Journey' },
  { key: 'journeyMinutes', type: 'select', label: 'No repeats for', tip: 'How long before any scene comes back. Quick tour moves on every scene length', options: [[60, 'One hour'], [120, 'Two hours'], [0, 'Quick tour']] },
  { key: 'switchBars', type: 'seg', label: 'Length', options: [[8, '8'], [16, '16'], [32, '32'], [64, '64']], suffix: 'bars', tip: 'Bars a scene stays before the next phrase change' },
  { key: 'transition', type: 'select', label: 'Transition', tip: 'How one scene turns into the next', options: [['auto', 'Auto']].concat(TRANS) },
  { key: 'transTime', type: 'range', label: 'Blend time', min: 0.3, max: 3, step: 0.01, fmt: (v) => (+v).toFixed(2) + 'x', tip: 'Longer blends scenes for longer' },
  { sec: 'display', title: 'Display' },
  { key: 'perf', type: 'preset', label: 'Quality', tip: 'Saver: battery and phones. Balanced: adaptive. Max: strong GPUs', options: [
    ['saver', 'Saver', { quality: 'low', detail: 0.75 }], ['balanced', 'Balanced', { quality: 'auto', detail: 1 }], ['max', 'Max', { quality: 'high', detail: 1.5 }]] },
  { key: 'quality', type: 'select', label: 'Resolution', tip: 'Only Auto adapts to the frame rate. Native and above also add real detail, and each step asks far more of the GPU. Changing tier rebuilds the scenes in the background', options: [['auto', 'Auto'], ['low', 'Low'], ['medium', 'Medium'], ['high', 'High'], ['ultra', 'Native'], ['cinema', 'Cinema 1.5x'], ['insane', 'Insane 2x'], ['extreme', 'Extreme 3x'], ['offline', 'Offline 4x']] },
  { key: 'detail', type: 'range', label: 'Detail', min: 0.5, max: 16, step: 0.25, fmt: (v) => (+v).toFixed(2) + 'x', tip: 'Nested geometry and ray steps. 8-16x is for big GPUs or offline renders' },
  { key: 'hud', type: 'toggle', label: 'Beat monitor', tip: 'Tempo, beat and spectrum (V)' },
  { type: 'status', label: 'Actual render size' }
];
// v16: essentials remain visible; only the advanced tools use a disclosure.
{
 const byKey=new Map(CONTROLS.filter(c=>c.key).map(c=>[c.key,c]));
 const vibe=byKey.get('vibe');vibe.tip='Five levels of visual energy. Scene duration stays exactly as you choose.';
 vibe.options.unshift(['drift','Drift',{dose:.45,speed:.5,warp:.15,trails:.35,colorSpeed:.25,chroma:.15,bloom:.5}]);
 vibe.options.splice(3,0,['vivid','Vivid',{dose:1.4,speed:1.2,warp:.8,trails:.7,colorSpeed:1,chroma:.7,bloom:1}]);
 vibe.options.forEach(o=>delete o[2].switchBars);
 const symmetry=byKey.get('symmetry');symmetry.tip='Off shows the original scene. Automatic folds each scene only into the patterns that suit it, on musical moments; a number holds that pattern.';symmetry.options[0]=['auto','Automatic'];
 const folds=byKey.get('autoKal');folds.label='Folds';folds.tip='How often Automatic folds a scene into a kaleidoscope';
 const favMode=byKey.get('favMode');favMode.label='Scenes shown';favMode.tip='All scenes, or only the ones you starred (L)';
 const basics=[vibe,
  {key:'sceneDuration',type:'select',label:'Time per scene',tip:'Time before moving to a different scene. Each full cycle visits every scene once.',options:[[30,'30 seconds'],[60,'1 minute'],[90,'90 seconds'],[120,'2 minutes'],[180,'3 minutes'],[300,'5 minutes'],['bars','Musical bars…'],[0,'Stay on this scene']]},
  {...byKey.get('switchBars'),label:'Musical length',tip:'One bar is four beats. At 120 BPM: 8 bars ≈16s, 16 ≈32s, 32 ≈64s, 64 ≈128s.'},
  {key:'cameraMode',type:'seg',str:true,label:'Framing',tip:'Tour shows each scene wide, with short visits closer and further out. Hold keeps your own zoom, even when the scene changes.',options:[['tour','Tour'],['hold','Hold zoom']]},
  symmetry,folds,byKey.get('palette'),byKey.get('perf')];
 const used=new Set(basics.map(c=>c.key));used.add('favMode');
 const advanced=CONTROLS.filter(c=>!c.sec&&!used.has(c.key)&&!['autoKal','autopilot','journeyMinutes'].includes(c.key));
 CONTROLS.splice(0,CONTROLS.length,{sec:'show',title:'',open:true},...basics,{sec:'music',title:'Music',open:true,el:'#grp-music'},{sec:'realms',title:'Scenes',open:true,el:'#grp-realms'},favMode,{sec:'advanced',title:'Advanced',open:false},...advanced);
}
const ctlRefs = {}, autoTags = {};
function setFill(input) { const mn = +input.min, mx = +input.max; input.style.setProperty('--fill', ((input.value - mn) / (mx - mn) * 100) + '%'); }
// what a control shows: the Auto Show's live choice while it owns the setting, else the person's own value
const shownSetting = (k) => (AUTO_KEYS.includes(k) && autoActive(k) ? E[k] : S[k]);
// a person's change to an Auto setting takes it over at once (autoUpdate would also notice on the next frame)
function touchSetting(k) { if (AUTO_KEYS.includes(k)) { AUTO.seen[k] = S[k]; if (S.autoShow && !AUTO.manual.has(k)) setAutoManual(k, true); } }
function markAutoTag(k) {
  const t = autoTags[k]; if (!t) return;
  const on = !!S.autoShow, man = AUTO.manual.has(k);
  t.hidden = !on; t.dataset.state = man ? 'manual' : 'auto';
  t.textContent = man ? 'manual ↺' : 'auto';
  t.title = man ? 'You set this. Click to give it back to the Auto Show' : 'Chosen by the Auto Show. Change it to take it over';
  t.setAttribute('aria-label', man ? 'Manual. Give ' + k + ' back to the Auto Show' : 'Chosen by the Auto Show');
  t.disabled = !man;
}
// open/closed state of the groups: a per-viewer convenience (every access guarded; defaults when storage is blocked)
const GROUPS_KEY = 'hyperVisualizer.v12.groups';
function readGroups() { try { const o = JSON.parse(localStorage.getItem(GROUPS_KEY) || '{}'); return o && typeof o === 'object' ? o : {}; } catch (e) { return {}; } }
function saveGroups(sec, open) { try { const o = readGroups(); o[sec] = open; localStorage.setItem(GROUPS_KEY, JSON.stringify(o)); } catch (e) { /* storage blocked */ } }
function buildControls() {
  const root = $('#ctlHost'), saved = readGroups(); root.innerHTML = '';
  let host = root;
  CONTROLS.forEach((c) => {
    if (c.sec) {
      let g = c.el ? $(c.el) : null;
      if (!g) {
        g = document.createElement('details'); g.className = 'p-group'; g.id = 'grp-' + c.sec; g.dataset.sec = c.sec;
        const sum = document.createElement('summary'); sum.textContent = c.title;
        const body = document.createElement('div'); body.className = 'g-body'; g.append(sum, body);
      }
      if(c.sec!=='advanced'){
        const flat=document.createElement('section');flat.className='p-group flat-group';flat.id='grp-'+c.sec;
        if(c.title){const title=document.createElement('h3');title.textContent=c.title;flat.appendChild(title);}
        flat.appendChild(g.querySelector('.g-body'));g.remove();g=flat;
      }
      g.open = c.sec in saved ? !!saved[c.sec] : !!c.open;
      g.addEventListener('toggle', () => saveGroups(c.sec, g.open));
      root.appendChild(g); host = g.querySelector('.g-body'); return;
    }
    if (c.type === 'status') { const d = document.createElement('p'); d.id = 'renderInfo'; d.className = 'render-info'; d.setAttribute('aria-label', c.label); host.appendChild(d); return; }
    const row = document.createElement('div'); row.className = 'ctl t-' + c.type; row.dataset.key = c.key;
    const id = 'ctl-' + c.key;
    const head = document.createElement('div'); head.className = 'ctl-head';
    const lab = document.createElement('label'); lab.textContent = c.label; lab.htmlFor = id; head.appendChild(lab);
    if (AUTO_KEYS.includes(c.key)) {
      const tag = document.createElement('button'); tag.type = 'button'; tag.className = 'auto-tag'; autoTags[c.key] = tag;
      tag.addEventListener('click', () => { setAutoManual(c.key, false); refreshControls(); toast(c.label + ': back to auto'); });
      head.appendChild(tag);
    }
    row.appendChild(head);
    let el;
    const changed = () => { touchSetting(c.key); saveSettings(); onSetting(c.key); };
    if (c.type === 'range') {
      const out = document.createElement('output'); out.htmlFor = id;
      el = document.createElement('input'); el.type = 'range'; el.id = id; el.min = c.min; el.max = c.max; el.step = c.step;
      // c.map/c.unmap: a perceptual dial position <-> the stored setting (identity for most controls)
      const toS = c.map || ((x) => x), toEl = c.unmap || ((v) => v);
      el.addEventListener('input', () => { S[c.key] = toS(+el.value); out.textContent = c.fmt(S[c.key]); setFill(el); changed(); markAutoTag(c.key); });
      ctlRefs[c.key] = () => { const v = shownSetting(c.key); if (document.activeElement !== el || !autoActive(c.key)) el.value = toEl(v); out.textContent = c.fmt(v); setFill(el); markAutoTag(c.key); };
      row.append(el, out);
    } else if (c.type === 'toggle') {
      el = document.createElement('button'); el.className = 'switch'; el.id = id; el.setAttribute('role', 'switch');
      el.addEventListener('click', () => { S[c.key] = !shownSetting(c.key); ctlRefs[c.key](); changed(); markAutoTag(c.key); });
      ctlRefs[c.key] = () => { el.setAttribute('aria-checked', String(!!shownSetting(c.key))); markAutoTag(c.key); };
      row.appendChild(el);
    } else if (c.type === 'select') {
      el = document.createElement('select'); el.id = id;
      c.options.forEach(([v, t]) => { const o = document.createElement('option'); o.value = v; o.textContent = t; el.appendChild(o); });
      el.addEventListener('change', () => { S[c.key] = el.value; changed(); markAutoTag(c.key); });
      ctlRefs[c.key] = () => { el.value = String(shownSetting(c.key)); markAutoTag(c.key); };
      row.appendChild(el);
    } else if (c.type === 'preset') {
      el = document.createElement('div'); el.className = 'seg'; el.id = id; el.setAttribute('role', 'group'); el.setAttribute('aria-label', c.label);
      c.options.forEach(([v, t, vals]) => {
        const b = document.createElement('button'); b.textContent = t; b.dataset.v = v;
        b.addEventListener('click', () => { applyPreset(c.key, v, vals); saveSettings(); refreshControls(); toast(c.label + ': ' + t); });
        el.appendChild(b);
      });
      ctlRefs[c.key] = () => el.querySelectorAll('button').forEach((b) => b.setAttribute('aria-pressed', String(S[c.key] === b.dataset.v)));
      row.appendChild(el);
    } else if (c.type === 'seg') {
      const out = document.createElement('output');
      el = document.createElement('div'); el.className = 'seg'; el.id = id; el.setAttribute('role', 'group'); el.setAttribute('aria-label', c.label);
      c.options.forEach(([v, t]) => {
        const b = document.createElement('button'); b.textContent = t; b.dataset.v = v; b.setAttribute('aria-label', t + ' ' + (c.suffix || ''));
        b.addEventListener('click', () => { S[c.key] = v; ctlRefs[c.key](); changed(); markAutoTag(c.key); });
        el.appendChild(b);
      });
      // the output shows a value only when it is not one of the buttons (the Auto Show's realm lengths: 24, 40, 48 ...)
      ctlRefs[c.key] = () => {
        const v = shownSetting(c.key); let hit = false;
        el.querySelectorAll('button').forEach((b) => { const on = c.str ? b.dataset.v === String(v) : Number(b.dataset.v) === Number(v); hit = hit || on; b.setAttribute('aria-pressed', String(on)); });
        out.textContent = c.suffix && !hit ? v + ' ' + c.suffix : ''; markAutoTag(c.key);
      };
      row.append(el, out);
    }
    if (c.tip) row.title = c.tip;
    host.appendChild(row);
    ctlRefs[c.key]();
  });
}
// presets: Vibe and Performance. With Auto Show on, Vibe sets only Energy and Speed and flavours the show
// (S.vibe scales its effects and realm length); Performance's Balanced hands resolution and detail back to Auto.
function applyPreset(key, v, vals) {
  S[key] = v;
  if (key === 'vibe' && S.autoShow) { S.dose = vals.dose; S.speed = vals.speed; return; }
  if (key === 'perf' && v === 'balanced' && S.autoShow) { Object.assign(S, vals); ['quality', 'detail'].forEach((k) => setAutoManual(k, false)); onSetting('quality'); return; }
  Object.assign(S, vals); Object.keys(vals).forEach(touchSetting);
  if ('quality' in vals) { renderSettingsChosen = true; onSetting('quality'); }
}
// the Auto Show switch (panel hero + top bar pill), its manual summary and "give everything back"
function markAutoShow() {
  const on = !!S.autoShow, n = AUTO.manual.size;
  document.querySelectorAll('[data-autoshow]').forEach((b) => b.setAttribute('aria-pressed', String(on)));
  const st = $('#autoState'); if (st) st.textContent = on ? 'on' : 'off';
  const back = $('#autoAllBack'); if (back) {back.hidden=!(on&&n);back.title='Return '+n+' custom effect settings to Auto Show';}
  document.body.classList.toggle('auto-show', on);
}
AUTO.listeners.push(() => { markAutoShow(); Object.keys(autoTags).forEach(markAutoTag); });
function refreshControls() { Object.keys(ctlRefs).forEach((k) => ctlRefs[k]()); markAutoShow();
 rowVisibility();
}
// rows that only apply in one state stay out of the way otherwise (v21: also at start-up, and the Folds amount)
function rowVisibility(){
 const row=document.querySelector('[data-key="switchBars"]');if(row)row.hidden=S.sceneDuration!=='bars';
 const fr=document.querySelector('[data-key="autoKal"]');if(fr)fr.hidden=S.symmetry!=='auto';
}
function toggleFavourite(key) {
  const on = !S.favs.includes(key); S.favs = on ? S.favs.concat([key]) : S.favs.filter((k) => k !== key); saveSettings();
  document.querySelectorAll('.realm-chip').forEach((b) => { const R = REALMS[Number(b.dataset.ri)]; if (R && R.key === key) { if (on) b.dataset.fav = '1'; else delete b.dataset.fav; } });
  const R = REALMS.find((x) => x.key === key); toast((R ? R.name : key) + (on ? ' is a favourite' : ' is no longer a favourite'));
}
document.querySelectorAll('[data-autoshow]').forEach((b) => b.addEventListener('click', () => { setAutoShow(!S.autoShow); refreshControls(); }));
$('#autoAllBack').addEventListener('click', () => { setAutoShow(true, true); refreshControls(); toast('Every setting is back in the Auto Show'); });
function onSetting(k) {
  if(k==='sceneDuration'||k==='switchBars'){D.realmTime=0;D.realmBars=0;refreshControls();}
  if(k==='cameraMode'){AUTOZ.dur=0;AUTOZ.q.length=0;AUTOZ.armed=null;AUTOZ.kind='';PTR.zoomT=PTR.zoom;ZOOMS.v=0;AUTOZ.key=null;AUTOZ.userT=-1e9;}
  if(k==='symmetry'&&S.symmetry==='auto'){setAutoManual('symmetry',false);}
  if(k==='symmetry'){if(D.cur&&!D.nxt)D.cur.kal=autoKalPlan(D.cur);}

  if (k === 'quality' || k === 'detail') renderSettingsChosen = true;
  if (k === 'hud') $('#hud').hidden = !S.hud;
  if (k === 'quality') { Q.realmScale = REALMS.map(() => null); Q.lastScale = AUTO_START; Q.lastRi = -1; Q.capDt = 0; Q.probe = null; Q.failedRequest = null; }
  if (k === 'palette' && S.palette === 'auto') nextPalette(2);
  if (k === 'favMode' && D.cur) { D.bag = []; refillRealmBag(D.cur.ri); D.upcoming = null; } // the new playlist starts now
  if (k === 'autoKal' && D.cur && !D.nxt) D.cur.kal = autoKalPlan(D.cur);
}

/* transport */
const $play = $('#playBtn'), $prev = $('#prevBtn'), $next = $('#nextBtn'), $seek = $('#seek');
const PLAY_SVG = '<path d="M8 5v14l11-7z"/>', PAUSE_SVG = '<path d="M7 5h4v14H7zm6 0h4v14h-4z"/>', STOP_SVG = '<path d="M6 6h12v12H6z"/>';
function fmtTime(s) { if (!isFinite(s) || s < 0) s = 0; const m = Math.floor(s / 60); return m + ':' + String(Math.floor(s % 60)).padStart(2, '0'); }
function updateTransport() {
  const mode = AU.mode;
  document.querySelectorAll('.src').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.src === mode || (b.dataset.src === 'file' && mode === 'file'))));
  const icon = $('#playIcon');
  const multi = mode === 'file' && AU.list.length > 1;
  $prev.disabled = !multi; $next.disabled = !multi;
  $seek.disabled = mode !== 'file';
  if (mode !== 'file') { $seek.value = 0; setFill($seek); }
  if (mode === 'file') {
    const tr = AU.list[AU.idx];
    $('#trackName').textContent = tr ? tr.name : 'Track';
    $('#srcLabel').textContent = AU.list.length > 1 ? (AU.idx + 1) + ' / ' + AU.list.length : 'Your file';
    $play.disabled = false;
    icon.innerHTML = AU.pl.paused ? PLAY_SVG : PAUSE_SVG;
    $play.setAttribute('aria-label', AU.pl.paused ? 'Play' : 'Pause');
  } else if (mode === 'demo') {
    $('#trackName').textContent = 'Hyperspace Rite (generative demo)';
    $('#srcLabel').textContent = '128 BPM · A minor';
    $play.disabled = false; icon.innerHTML = PAUSE_SVG; $play.setAttribute('aria-label', 'Stop demo'); $('#tDur').textContent = 'loop';
  } else if (mode === 'visual') { // MOBILE: silent visual demo
    $('#trackName').textContent = 'Silent visual demo';
    $('#srcLabel').textContent = '140 BPM · no sound';
    $play.disabled = false; icon.innerHTML = STOP_SVG; $play.setAttribute('aria-label', 'Stop the silent demo'); $('#tDur').textContent = 'loop';
  } else if (mode === 'mic' || mode === 'tab') {
    $('#trackName').textContent = mode === 'mic' ? 'Microphone input' : 'Shared audio' + (AU.captureLabel ? ': ' + AU.captureLabel : '');
    $('#srcLabel').textContent = 'Live';
    $play.disabled = false; icon.innerHTML = STOP_SVG; $play.setAttribute('aria-label', 'Stop listening');
  } else {
    $('#trackName').textContent = AU.list.length ? 'Paused' : 'Pick a source to begin';
    $('#srcLabel').textContent = 'Drop audio files anywhere';
    $play.disabled = false; icon.innerHTML = PLAY_SVG; $play.setAttribute('aria-label', 'Play');
    $('#tCur').textContent = '0:00'; $('#tDur').textContent = '0:00';
  }
  renderQueue();
}
function togglePlay() {
  if (AU.ctx && AU.ctx.state === 'suspended') AU.ctx.resume();
  const m = AU.mode;
  if (m === 'file') { if (AU.pl.paused) AU.pl.play().catch(() => {}); else AU.pl.pause(); }
  else if (m === 'demo' || m === 'mic' || m === 'tab' || m === 'visual') { AU.stopAll(); updateTransport(); }
  else if (AU.list.length) AU.playIndex(AU.idx < 0 ? 0 : AU.idx);
  else { AU.startDemo(); }
}
function chooseSource(src) {
  if (src === 'demo') { if (AU.mode === 'demo') { AU.stopAll(); updateTransport(); } else AU.startDemo(); }
  else if (src === 'visual') { if (AU.mode === 'visual') { AU.stopAll(); updateTransport(); } else AU.startVisual(); } // MOBILE
  else if (src === 'file') $('#fileInput').click();
  else AU.startCapture(src);
}
$play.addEventListener('click', togglePlay);
$prev.addEventListener('click', () => AU.nextTrack(-1));
$next.addEventListener('click', () => AU.nextTrack(1));
$seek.addEventListener('input', () => { if (AU.mode === 'file' && isFinite(AU.pl.duration)) AU.pl.currentTime = $seek.value / 1000 * AU.pl.duration; });
$('#volume').value = S.volume; setFill($('#volume'));
$('#volume').addEventListener('input', (e) => { S.volume = +e.target.value; setFill(e.target); if (AU.out) AU.out.gain.value = S.volume; saveSettings(); });
document.querySelectorAll('.src').forEach((b) => b.addEventListener('click', () => chooseSource(b.dataset.src)));
/* v21 music queue view (controls panel, Music). The list is rebuilt only when the queue itself changes (AU.rev). */
const ICON = {
  add: '<path d="M11 5h2v6h6v2h-6v6h-2v-6H5v-2h6z"/>',
  folder: '<path d="M10 4l2 2h8a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1h6z"/>',
  shuffle: '<path d="M3 6h4.2l9 10H18v-2.5l4 3.5-4 3.5V18h-2.7l-9-10H3zm0 10h3.3l2.2-2.4 1.4 1.5L7.2 18H3zm12.3-10H18V3.500l4 3.500-4 3.500V8h-1.800l-2.200 2.400-1.400-1.500z"/>',
  repeat: '<path d="M7 6h10V3.500l4 3.500-4 3.500V8H7v3H5V6zm10 12H7v2.500L3 17l4-3.500V16h10v-3h2v5z"/>',
  clear: '<path d="M9 3h6l1 1.500h4v2H4v-2h4zM6 8.500h12L17 21H7z"/>',
  coffee: '<path d="M4 9h13v1.500h1.200a2.800 2.800 0 0 1 0 5.600H16.400A5 5 0 0 1 12 19H9a5 5 0 0 1-5-5zm13 3.300v2h1.200a1 1 0 0 0 0-2zM7 3.500h1.500V7H7zm3.250 0h1.500V7h-1.500zm3.250 0H15V7h-1.500zM3 20.500h15V22H3z"/>',
  github: '<path d="M12 .297c-6.630 0-12 5.373-12 12 0 5.303 3.438 9.800 8.205 11.385.600.113.820-.258.820-.577 0-.285-.010-1.040-.015-2.040-3.338.724-4.042-1.610-4.042-1.610C4.422 18.070 3.633 17.700 3.633 17.700c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.070 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.760-1.605-2.665-.300-5.466-1.332-5.466-5.930 0-1.310.465-2.380 1.235-3.220-.135-.303-.540-1.523.105-3.176 0 0 1.005-.322 3.300 1.230.960-.267 1.980-.399 3-.405 1.020.006 2.040.138 3 .405 2.280-1.552 3.285-1.230 3.285-1.230.645 1.653.240 2.873.120 3.176.765.840 1.230 1.910 1.230 3.220 0 4.610-2.805 5.625-5.475 5.920.420.360.810 1.096.810 2.220 0 1.606-.015 2.896-.015 3.286 0 .315.210.690.825.570C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/>',
  shroom: '<path fill-rule="evenodd" d="M12 2.500c-5.200 0-9.500 3.700-9.500 8 0 .800.600 1.300 1.400 1.300h16.200c.800 0 1.400-.500 1.400-1.300 0-4.300-4.300-8-9.500-8zM8.200 6.300a1.500 1.500 0 1 1 0 3 1.500 1.500 0 0 1 0-3zm6-1.300a1.900 1.900 0 1 1 0 3.800 1.900 1.900 0 0 1 0-3.800zM9.300 13.300h5.400l.900 6.300c.200 1.100-.600 1.900-1.700 1.900h-3.800c-1.100 0-1.900-.800-1.700-1.900z"/>'
};
const svgIcon = (name) => '<svg viewBox="0 0 24 24" aria-hidden="true">' + ICON[name] + '</svg>';
const PL = { rev: -1, cur: -2, built: false };
function buildQueueTools() {
  if (PL.built) return; const h = document.querySelector('#grp-music h3'); if (!h) return; PL.built = true;
  const tools = document.createElement('span'); tools.className = 'h-tools';
  const mk = (id, icon, label, fn, cls) => { const b = document.createElement('button'); b.type = 'button'; b.id = id; b.className = 'pl-b' + (cls ? ' ' + cls : ''); b.title = label; b.setAttribute('aria-label', label); b.innerHTML = svgIcon(icon); b.addEventListener('click', fn); tools.appendChild(b); return b; };
  const count = document.createElement('span'); count.id = 'plCount'; count.className = 'pl-count'; tools.appendChild(count);
  mk('plShuffle', 'shuffle', 'Shuffle', () => { S.plShuffle = !S.plShuffle; AU.bag = null; saveSettings(); renderQueue(true); });
  mk('plRepeat', 'repeat', 'Repeat', () => { S.plRepeat = { all: 'one', one: 'off', off: 'all' }[S.plRepeat] || 'all'; saveSettings(); renderQueue(true); });
  mk('plClear', 'clear', 'Clear the queue', () => AU.clearList());
  mk('plFolder', 'folder', 'Add a folder of music', () => $('#folderInput').click(), 'desktop-only');
  mk('plAdd', 'add', 'Add music files', () => $('#fileInput').click());
  h.appendChild(tools);
  $('#plList').addEventListener('click', (e) => {
    const li = e.target.closest('li'); if (!li) return; const i = Number(li.dataset.i);
    if (e.target.closest('.pl-x')) AU.removeAt(i); else if (!(AU.mode === 'file' && i === AU.idx)) AU.playIndex(i, true);
  });
  // the scene filter (all / starred) sits beside the Scenes title
  const fav = $('#ctl-favMode'), favRow = document.querySelector('[data-key="favMode"]'), sh = document.querySelector('#grp-realms h3');
  if (fav && favRow && sh) { const w = document.createElement('span'); w.className = 'h-tools'; fav.title = favRow.title; w.appendChild(fav); sh.appendChild(w); favRow.hidden = true; }
}
function renderQueue(force) {
  buildQueueTools(); const ol = $('#plList'); if (!ol || !PL.built) return;
  const list = AU.list, cur = AU.mode === 'file' ? AU.idx : -1;
  if (PL.rev !== AU.rev) {
    PL.rev = AU.rev; PL.cur = -2; ol.textContent = '';
    const frag = document.createDocumentFragment();
    list.forEach((t, i) => { const li = document.createElement('li'); li.dataset.i = i; const b = document.createElement('button'); b.type = 'button'; b.className = 'pl-t'; b.textContent = t.name; b.title = t.name;
      const x = document.createElement('button'); x.type = 'button'; x.className = 'pl-x'; x.textContent = '×'; x.setAttribute('aria-label', 'Remove ' + t.name); li.append(b, x); frag.appendChild(li); });
    ol.appendChild(frag);
    $('#plEmpty').hidden = list.length > 0; $('#plCount').textContent = list.length ? String(list.length) : ''; $('#plClear').hidden = !list.length;
  }
  if (PL.cur !== cur) {
    PL.cur = cur; const old = ol.querySelector('li.now'); if (old) old.classList.remove('now');
    const li = cur >= 0 ? ol.children[cur] : null; if (li) { li.classList.add('now'); if ($panel.classList.contains('open')) li.scrollIntoView({ block: 'nearest' }); }
  }
  const sb = $('#plShuffle'), rb = $('#plRepeat');
  sb.setAttribute('aria-pressed', String(!!S.plShuffle));
  rb.setAttribute('aria-pressed', String(S.plRepeat !== 'off')); rb.dataset.mode = S.plRepeat; rb.title = S.plRepeat === 'one' ? 'Repeat: this track' : S.plRepeat === 'off' ? 'Repeat: off (stop after the last track)' : 'Repeat: the whole queue'; rb.setAttribute('aria-label', rb.title);
}
// the files of a drop, with dropped folders walked (their own order is kept through the path)
function gatherDrop(dt) {
  const entries = Array.from(dt.items || []).map((it) => (it.kind === 'file' && it.webkitGetAsEntry ? it.webkitGetAsEntry() : null)).filter(Boolean);
  if (!entries.some((en) => en.isDirectory)) return Promise.resolve(Array.from(dt.files || []));
  const out = [];
  const walk = (en, dir) => new Promise((done) => {
    if (out.length >= 5000) { done(); return; }
    if (en.isFile) en.file((f) => { try { f._path = dir + f.name; } catch (e) { /* a plain name then */ } out.push(f); done(); }, () => done());
    else if (en.isDirectory) { const rd = en.createReader(); const more = () => rd.readEntries((batch) => { if (!batch.length) { done(); return; } Promise.all(batch.map((b) => walk(b, dir + en.name + '/'))).then(more); }, () => done()); more(); }
    else done();
  });
  return Promise.all(entries.map((en) => walk(en, ''))).then(() => out);
}
// credit and links: controls footer and enter screen
function buildCredit() {
  const ok = (u) => typeof u === 'string' && /^https:\/\/[^\s"'<>]+$/.test(u);
  document.querySelectorAll('[data-by]').forEach((el) => { el.innerHTML = svgIcon('shroom') + 'by Stoned Ape'; });
  document.querySelectorAll('[data-links]').forEach((el) => {
    el.textContent = '';
    for (const [url, icon, label] of [[SUPPORT_URL, 'coffee', 'Buy me a coffee (or some compute)'], [REPO_URL, 'github', 'Source on GitHub']]) {
      if (!ok(url)) continue;
      const a = document.createElement('a'); a.href = url; a.target = '_blank'; a.rel = 'noopener'; a.title = label; a.setAttribute('aria-label', label); a.innerHTML = svgIcon(icon); el.appendChild(a);
    }
    el.hidden = !el.children.length;
  });
}
buildCredit();
function startFiles(files) { const saved=Array.from(files).filter(f=>/^audio\//.test(f.type)||/\.(mp3|wav|ogg|oga|m4a|aac|flac|opus|webm)$/i.test(f.name));if(!saved.length){toast('Drop an audio file to begin.');return;}AU.init();startWhenReady(() => { AU.addFiles(saved); hideSplash(); }); }
$('#fileInput').addEventListener('change', (e) => { if (e.target.files && e.target.files.length) startFiles(e.target.files); e.target.value = ''; });
$('#folderInput').addEventListener('change', (e) => { if (e.target.files && e.target.files.length) startFiles(e.target.files); e.target.value = ''; });

/* panel, help, view */
const $panel = $('#panel');
function setPanel(open) { $panel.classList.toggle('open', open); $panel.inert = !open; $('#guiToggleButton').setAttribute('aria-expanded', String(open)); $('#guiToggleButton').setAttribute('aria-pressed', String(open)); }
$('#guiToggleButton').addEventListener('click', () => setPanel(!$panel.classList.contains('open')));
$('#panelClose').addEventListener('click', () => setPanel(false));
function toggleHelp(force) {
  const h = $('#help'), show = force !== undefined ? force : h.hidden;
  h.hidden = !show;
  if (show) { h.setAttribute('tabindex', '-1'); h.focus(); } else if (document.activeElement === h) $('#helpBtn').focus();
}
$('#helpBtn').addEventListener('click', () => toggleHelp());
$('#panelHelpBtn').addEventListener('click', () => toggleHelp(true));
const HIDE_HINT = { n: 0 };
function setMinimal(on) {
  const was = document.body.classList.contains('minimal');
  document.body.classList.toggle('minimal', on); $('#minimalToggleBtn').setAttribute('aria-pressed', String(on)); $('#minimalToggleBtn').setAttribute('aria-label', on ? 'Show interface' : 'Hide interface'); if (on) setPanel(false);
  // v21: the reminder shows the first two times in a session only, and for 60% of the usual time
  if (on && !was && splashGone && HIDE_HINT.n++ < 2) toast(PTR.touch || MOBILE ? 'Tap the top or bottom edge to bring the controls back' : 'Press H or click the top or bottom edge to bring the controls back', 2300);
}
$('#minimalToggleBtn').addEventListener('click', () => setMinimal(!document.body.classList.contains('minimal')));
function toggleFullscreen() {
  const d = document;
  if (d.fullscreenElement || d.webkitFullscreenElement) { (d.exitFullscreen || d.webkitExitFullscreen).call(d); return; }
  const el = d.documentElement, req = el.requestFullscreen || el.webkitRequestFullscreen;
  // MOBILE: iPhone Safari has no element fullscreen and embeds may forbid it; hide the interface instead
  const fallback = () => { if (MOBILE) { setMinimal(true); toast('Fullscreen is not available here (iPhone Safari and embedded pages). The interface is hidden instead; tap to bring it back. Share > Add to Home Screen gives a full-screen view.'); } else toast('Fullscreen is not available here.'); };
  if (!req) { fallback(); return; }
  try { const r = req.call(el); if (r && r.catch) r.catch(fallback); } catch (e) { fallback(); }
}
$('#fsBtn').addEventListener('click', toggleFullscreen);
/* recording: the canvas plus the audio exactly as heard, encoded by the browser (MP4 where supported, else WebM) */
/* Recording owns each canvas capture; the audio destination is shared across takes. */
const REC = { mr: null, dest: null, session: null, t0: 0 };
function toggleRecord() {
  if (REC.session) {
    const take = REC.session;
    if (take.stopping) return;
    take.stopping = true;
    try { if (take.mr.state !== 'inactive') take.mr.stop(); }
    catch (e) { take.error = e; take.finish(false); }
    return;
  }
  if (!canvas.captureStream || !window.MediaRecorder) { toast('Recording is not supported in this browser.'); return; }
  const take = { vs: null, mr: null, srcs: [], audioTracks: [], dest: null, chunks: [], error: null, finished: false, stopping: false, timer: null, t0: performance.now() };
  const errorText = (e) => String((e && (e.message || e.name)) || 'The encoder stopped unexpectedly.');
  take.finish = (save = true) => {
    if (take.finished) return;
    take.finished = true;
    if (take.timer) clearTimeout(take.timer);
    take.srcs.forEach((n) => { try { n.disconnect(take.dest); } catch (e) { /* already disconnected */ } });
    if (take.vs) take.vs.getTracks().forEach((t) => t.stop());
    take.audioTracks.forEach((t) => t.stop());
    // Never stop REC.dest's audio track: it feeds subsequent recordings too.
    if (REC.session === take) { REC.session = null; REC.mr = null; $('#recBtn').setAttribute('aria-pressed', 'false'); }
    const bytes = take.chunks.reduce((n, c) => n + c.size, 0);
    if (!save || !bytes) {
      toast(take.error ? 'Recording failed: ' + errorText(take.error) : 'Recording stopped without video data.');
      return;
    }
    let url;
    try {
      const blob = new Blob(take.chunks, { type: take.mr.mimeType || take.type || 'video/webm' });
      const a = document.createElement('a'), d = new Date();
      url = URL.createObjectURL(blob); a.href = url;
      a.download = 'viszualizerrr-' + d.toISOString().slice(0, 19).replace(/[:T]/g, '-') + (take.error ? '-partial' : '') + (/mp4/.test(blob.type) ? '.mp4' : '.webm');
      document.body.appendChild(a); a.click(); a.remove();
      setTimeout(() => URL.revokeObjectURL(url), 120000);
      toast(take.error ? 'Recording stopped early: ' + errorText(take.error) + ' Saved the available partial video.' : 'Saved ' + Math.round((performance.now() - take.t0) / 1000) + ' s of video.');
    } catch (e) {
      if (url) URL.revokeObjectURL(url);
      toast('Could not save the recording: ' + errorText(e));
    }
  };
  REC.session = take;
  try {
    // Create a silent audio track now so sources started later remain in this take.
    const audioReady = AU.init();
    take.vs = canvas.captureStream(60);
    const tracks = take.vs.getVideoTracks().slice();
    if (audioReady && AU.ctx) {
      if (!REC.dest || REC.dest.context !== AU.ctx) REC.dest = AU.ctx.createMediaStreamDestination();
      take.dest = REC.dest;
      [AU.look, AU.captureMix].forEach((n) => { if (n) { n.connect(take.dest); take.srcs.push(n); } });
      // Clones belong to this take, so even a failed encoder cannot retain a live shared track.
      take.dest.stream.getAudioTracks().forEach((t) => { const owned = t.clone(); take.audioTracks.push(owned); tracks.push(owned); });
    }
    take.type = ['video/mp4;codecs=avc1.640034,mp4a.40.2', 'video/mp4', 'video/webm;codecs=vp9,opus', 'video/webm;codecs=vp8,opus', 'video/webm'].find((t) => MediaRecorder.isTypeSupported(t)) || '';
    const mr = take.mr = new MediaRecorder(new MediaStream(tracks), Object.assign(take.type ? { mimeType: take.type } : {}, { videoBitsPerSecond: clamp(W * H * 30 * 0.14, 8e6, 160e6), audioBitsPerSecond: 320000 }));
    mr.ondataavailable = (e) => { if (!take.finished && e.data && e.data.size) take.chunks.push(e.data); };
    mr.onstop = () => take.finish();
    mr.onerror = (e) => {
      take.error = (e && e.error) || new Error('The encoder stopped unexpectedly.');
      take.stopping = true;
      // The error event is followed by final data and stop; retain any usable data.
      // A bounded fallback still releases capture resources if an implementation omits stop.
      take.timer = setTimeout(() => take.finish(), 3000);
      try { if (mr.state !== 'inactive') mr.stop(); } catch (ignored) { /* final error/stop events may already be queued */ }
    };
    REC.mr = mr; REC.t0 = take.t0;
    mr.start(1000);
    $('#recBtn').setAttribute('aria-pressed', 'true');
    toast(audioReady ? 'Recording. Press X or the red button again to stop and save.' : 'Recording video only; audio is unavailable. Press X to stop and save.');
  } catch (e) {
    take.error = e;
    // Some implementations can allocate the encoder before start throws.
    try { if (take.mr && take.mr.state !== 'inactive') take.mr.stop(); } catch (ignored) { /* failed start */ }
    take.finish(false);
  }
}

$('#recBtn').addEventListener('click', toggleRecord);
$('#reseedBtn').addEventListener('click', () => reseed());
$('#resetBtn').addEventListener('click', () => { const vol = S.volume, favs = S.favs; Object.assign(S, DEFAULTS, { volume: vol, favs, autoManual: [] }); setAutoShow(true, true); saveSettings(); refreshControls(); onSetting('hud'); onSetting('quality'); toast('Controls reset'); });
function reseed() { if (D.cur) goRealm(D.nxt ? D.nxt.ri : D.cur.ri, 1.2, viewVisitStyle('mutate'), true); }

/* splash */
const $splash = $('#splash');
let splashGone = false;
function hideSplash() { if (splashGone) return; splashGone = true; document.body.classList.add('started'); $('#dock').inert = false; $splash.classList.add('gone'); setTimeout(() => { $splash.hidden = true; }, 950); lastActivity = TIME;
  if (MOBILE && !OFF.on) { keepAwake(true); setTimeout(() => { if (!$('#toast').classList.contains('show')) toast('Swipe: scenes · tap: kaleidoscope · tap top or bottom: controls · pinch: zoom'); }, 1200); } }
/* MOBILE: keep the screen awake while the visualizer runs (Screen Wake Lock API; embeds may refuse it), re-acquired
   when the page becomes visible again. Audio is resumed on return and on any touch (iOS 'interrupted' state too). */
const WAKE = { lock: null, want: false, busy: false };
async function keepAwake(on) {
  WAKE.want = on;
  if (!on) { try { if (WAKE.lock) await WAKE.lock.release(); } catch (e) { /* already released */ } WAKE.lock = null; return; }
  if (WAKE.lock || WAKE.busy || !navigator.wakeLock || document.visibilityState !== 'visible') return;
  WAKE.busy = true;
  try { const l = await navigator.wakeLock.request('screen'); WAKE.lock = l; l.addEventListener('release', () => { if (WAKE.lock === l) WAKE.lock = null; }); }
  catch (e) { WAKE.lock = null; } finally { WAKE.busy = false; }
}
function resumeAudio() { const c = AU.ctx; if (c && c.state !== 'running' && c.state !== 'closed') { try { const r = c.resume(); if (r && r.catch) r.catch(() => {}); } catch (e) { /* not allowed yet */ } } }
if (MOBILE) {
  document.addEventListener('visibilitychange', () => { if (document.visibilityState === 'visible') { resumeAudio(); if (WAKE.want) keepAwake(true); } });
  ['touchend', 'click'].forEach((ev) => window.addEventListener(ev, () => { resumeAudio(); if (WAKE.want && !WAKE.lock) keepAwake(true); }, { passive: true }));
}
document.querySelectorAll('[data-start]').forEach((b) => b.addEventListener('click', () => {
  const k = b.dataset.start;
  if (k === 'file') { $('#fileInput').click(); AU.init(); return; }
  AU.init();
  if (k === 'visual') { startWhenReady(() => { hideSplash(); AU.startVisual(); }); return; } // MOBILE: silent demo
  // Display/tab capture requires the original user gesture; the demo can wait for the picture.
  if (k !== 'demo') {
    const ready=AU.startCapture(k); // begin the permission request within this click
    // MOBILE: a refused/blocked mic still opens the visuals, driven by the silent demo (the toast says why)
    ready.then(ok=>{if(ok)startWhenReady(hideSplash);else if(MOBILE)startWhenReady(()=>{hideSplash();if(AU.mode==='none')AU.startVisual();});});
  } else startWhenReady(() => { hideSplash();chooseSource(k); });
}));
function startWhenReady(start) { if(glReady)start(); else { pendingStart=start; prepareVisualizer(); } }
function addRenderRestore() { if (hadHeavySettings) {
  const restore=document.createElement('button');restore.className='sp-link';restore.id='restoreRenderSettings';
  restore.textContent='Previous render settings: '+previousRenderSettings.quality+' / '+previousRenderSettings.detail+'x · restore after entering';
  restore.addEventListener('click',()=>{ if(!glReady || !splashGone)return; Object.assign(S,previousRenderSettings);saveSettings();refreshControls();onSetting('quality');restore.remove(); });
  ($('#grp-display .g-body') || $('#ctlHost')).appendChild(restore);
} }
const $safe = $('#safeBtn');
function markSafe() { $safe.setAttribute('aria-pressed', String(S.flashes <= 0.2)); $safe.textContent = S.flashes <= 0.2 ? 'reduced' : 'reduce'; }
$safe.addEventListener('click', () => {
  if (S.flashes > 0.2) { S.flashes = 0.12; S.chroma = Math.min(S.chroma, 0.25); S.dose = Math.min(S.dose, 0.8); }
  else { S.flashes = DEFAULTS.flashes; S.chroma = DEFAULTS.chroma; S.dose = DEFAULTS.dose; }
  saveSettings(); refreshControls(); markSafe();
});

/* HUD */
const hudCtx = $('#hudSpec').getContext('2d');
const $beats = Array.from(document.querySelectorAll('#hudBeats i'));
function drawHud() {
  const c = hudCtx, w = 456, h = 104;
  c.clearRect(0, 0, w, h);
  const bars = 64, bw = w / bars;
  for (let i = 0; i < bars; i++) {
    const v = specBytes[Math.floor(i * NB / bars)] / 255;
    const hue = 300 - i / bars * 220;
    c.fillStyle = 'hsl(' + hue + ',95%,' + (45 + v * 25) + '%)';
    const bh = Math.max(2, v * (h - 8));
    c.fillRect(i * bw + 1, h - bh, bw - 2, bh);
  }
  c.fillStyle = 'rgba(255,255,255,' + (0.15 + F.kick * 0.8) + ')';
  c.fillRect(0, 0, w * F.kick, 4);
  $('#hudBpm').textContent = (F.bpm && F.conf > 0.15 ? Math.round(F.bpm) : '---') + ' BPM';
  const bi = Math.floor(F.bar * 4);
  $beats.forEach((b, i) => b.classList.toggle('on', i === bi && F.beat < 0.5));
  const st = $('#hudState');
  let label = F.silent ? 'IDLE' : 'LISTENING', hot = false;
  if (!F.silent) { if (F.drop > 0.3) { label = 'DROP'; hot = true; } else if (F.build > 0.25) { label = 'BUILD ' + Math.round(F.build * 100) + '%'; hot = true; } else if (F.breakdown > 0.5) label = 'BREAKDOWN'; }
  st.textContent = label; st.classList.toggle('hot', hot);
}

/* idle-hide of the interface */
let lastActivity = 0;
function uiTick(dt) {
  if (frameCount % 15 === 0) {
    const info = $('#renderInfo'), eff = effectiveDetail(), ready = REALMS.filter((R) => R.ready).length;
    if (info) info.textContent = RW + ' × ' + RH + ' scene' + (RW < W ? ' (sharpened upscale to ' + W + ' × ' + H + ')' : '') + ' · ' + baseDetail().toFixed(2) + 'x detail'
      + (eff < baseDetail() - 0.005 ? ' (running ' + eff.toFixed(2) + 'x to keep the frame rate)' : '') + ' · ' + (E.quality === 'auto' && !OFF.on ? 'adaptive' : 'fixed')
      + (GPU_TEST.text ? ' · GPU colour self-test: ' + GPU_TEST.text : '') // ADRENO FIX
      + (Q.limit ? ' · ' + Q.limit : '') + (Q.error ? ' · ' + Q.error : '') + (ready < REALMS.length && !realmsSettled() ? ' · preparing scenes ' + ready + ' / ' + REALMS.length : '');
    markRealmStates();
    if ($panel.classList.contains('open') && S.autoShow) AUTO_KEYS.forEach((k) => { if (ctlRefs[k] && autoActive(k)) ctlRefs[k](); }); // v10: show the Auto Show's live choices
  }
  if (realmDimT > 0) { realmDimT -= dt; if (realmDimT <= 0) $realmTag.classList.add('dim'); }
  const playing = AU.mode !== 'none';
  const idleFor = document.body.classList.contains('clean-embed-mode') ? 1.8 : 3.5;
  const calm = splashGone && playing && TIME - lastActivity > idleFor && !$panel.classList.contains('open') && $('#help').hidden;
  document.body.classList.toggle('calm', calm);
  if (AU.mode === 'file' && AU.pl && isFinite(AU.pl.duration)) {
    if (frameCount % 10 === 0) { $('#tCur').textContent = fmtTime(AU.pl.currentTime); $('#tDur').textContent = fmtTime(AU.pl.duration); if (document.activeElement !== $seek) { $seek.value = Math.round(AU.pl.currentTime / AU.pl.duration * 1000); setFill($seek); } }
  } else if (AU.mode === 'demo' && frameCount % 10 === 0) { $('#tCur').textContent = fmtTime(AU.demo ? AU.demo.position : 0); }
  if (S.hud && frameCount % 2 === 0) drawHud();
  if (frameCount % 30 === 0) $('#bpmTag').textContent = (F.bpm && F.conf > 0.25 && !F.silent) ? Math.round(F.bpm) + ' BPM' : '';
}

