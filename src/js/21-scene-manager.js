/* ============================ ENGINE v24: SCENES ============================
   Scene set, playlist, the Scenes editor and scenes from a file. State: SCN (declared beside the settings).
   Format and API: work/engine24/SCENE-PACK-FORMAT.md.
   1. WHICH SCENE COMES NEXT. refillRealmBag() keeps only the scenes that are on (scnBag); in sequence mode pickRealm()
      returns the scene after the current one in the list order (scnSeqPick) and D.bag holds the scenes that follow, so
      the background / phone preparation still reads "what comes next" from the bag. realmHoldSeconds() / realmChangeDue()
      use a scene's own length when it has one (scnHold). With nothing changed none of these paths is entered.
   2. SCENES FROM A FILE. registerScene(def) evaluates the pack's code HERE, in the engine's scope, exactly as a built-in
      scene is wired:  (function (GLSL) { <helpers>  return [ <entry> ][0]; })(def.glsl) . The scene joins REALMS hidden
      (R.gone), is compiled through the ordinary preparation pipeline first in line (SCN.verify), and is admitted to the
      list and the rotation only once it is ready; a shader that fails, or an init / frame that throws, rejects the
      promise with a readable message and the scene is dropped (it stays in REALMS as permanently failed, so indices held
      by visits, the bag and the preparation queue stay valid). Removing works the same way.
   3. THE EDITOR is built the first time it is opened and costs nothing while closed. */
function scnIndex(key) { for (let i = REALMS.length - 1; i >= 0; i--) if (REALMS[i].key === key && !REALMS[i].gone) return i; return -1; }
function scnOnKey(key) { return SCN.only ? SCN.only.has(key) : !SCN.off.has(key); }
function scnSeq() { return SCN.mode === 'sequence'; }
function scnChanged() { return SCN.mode === 'sequence' || SCN.off.size > 0 || !!SCN.only; } // false = the engine runs exactly as before v24
// list order (indices into REALMS): the named keys first, then every other scene in built-in order; SCN.play = those that are on
function scnOrder() {
  if (SCN.ordRev === SCN.rev && SCN.ordN === REALMS.length) return SCN.ord;
  const seen = new Set(), out = [];
  for (const k of SCN.order) { const i = scnIndex(k); if (i >= 0 && !seen.has(i)) { seen.add(i); out.push(i); } }
  REALMS.forEach((R, i) => { if (!R.gone && !seen.has(i)) out.push(i); });
  const on = out.filter((i) => scnOnKey(REALMS[i].key));
  SCN.ord = out; SCN.play = on.length ? on : out; SCN.ordRev = SCN.rev; SCN.ordN = REALMS.length;
  return out;
}
function scnPlayable() { scnOrder(); return SCN.play; }
function scnBag(bag) { // refillRealmBag: only the scenes that are on (never an empty bag)
  if (!SCN.off.size && !SCN.only && !REALMS.some((R) => R.gone)) return bag;
  const on = bag.filter((i) => !REALMS[i].gone && scnOnKey(REALMS[i].key));
  return on.length ? on : bag.filter((i) => !REALMS[i].gone);
}
// sequence mode: the scenes after `except` in list order, wrapping round (from the last scene of the list that was
// shown when `except` itself is not in it)
function scnSeqList(except) {
  const o = scnPlayable(); let at = o.indexOf(except);
  for (let h = D.history.length - 1; at < 0 && h >= 0; h--) at = o.indexOf(D.history[h]);
  return o.slice(at + 1).concat(o.slice(0, at + 1)).filter((i) => i !== except);
}
function scnSeqPick(except) {
  const q = scnSeqList(except); D.bag = q.slice().reverse();
  for (const ri of q) if (!REALMS[ri].failed) return realmReady(ri) ? ri : -1; // strictly the next one: wait for it rather than skip
  return -1;
}
function scnHold(V) { // this scene's own length in seconds; 0 = the global "Time per scene"
  if (!V) return 0;
  if (SCN.linkSecs) return SCN.linkSecs;
  return SCN.mode === 'sequence' ? (SCN.secs[V.R.key] || 0) : 0;
}
function scnStay() { if (!scnChanged() || !D.cur) return false; const p = scnPlayable(); return p.length === 1 && p[0] === D.cur.ri; } // a set of one never "changes"
function scnTimed() { return !!SCN.linkSecs || (SCN.mode === 'sequence' && scnPlayable().some((i) => SCN.secs[REALMS[i].key] > 0)); }
function scnFirst() { // the scene the app opens on
  if (!scnChanged() && !REALMS[0].gone) return 0;
  const p = scnPlayable(); return !p.length || (!scnSeq() && p.includes(0)) ? 0 : p[0];
}
function scnStoreSave() {
  if (SCN.link) return; // a link's playlist is for this visit only
  try { localStorage.setItem(SCN_KEY, JSON.stringify({ off: [...SCN.off], mode: SCN.mode, order: SCN.order, secs: SCN.secs })); } catch (e) { /* storage blocked */ }
}
function scnApply() { // a changed set / order / mode: the new playlist starts now (as the favourites filter does)
  SCN.rev++; scnStoreSave();
  if (D.cur) { D.bag = []; refillRealmBag(D.cur.ri); D.upcoming = null; }
}
function scnOwn() { // the person edits a link's playlist: its scene set becomes an ordinary on / off set (still not saved)
  if (!SCN.only) return;
  SCN.off = new Set(REALMS.filter((R) => !R.gone && !SCN.only.has(R.key)).map((R) => R.key)); SCN.only = null;
}
function scnExport() {
  const o = scnOrder();
  return { format: 'hypervisualizer-playlist', version: 1, mode: SCN.mode, order: o.map((i) => REALMS[i].key), on: o.filter((i) => scnOnKey(REALMS[i].key)).map((i) => REALMS[i].key), secs: Object.assign({}, SCN.secs) };
}
function scnImport(p) { // returns the keys this visualizer does not have
  if (!p || typeof p !== 'object' || p.format !== 'hypervisualizer-playlist') throw new Error('not a playlist file');
  const order = scnKeys(p.order), on = new Set(scnKeys(Array.isArray(p.on) ? p.on : p.order)), have = (k) => scnIndex(k) >= 0;
  if (![...on].some(have)) throw new Error('none of its scenes are in this visualizer');
  const off = REALMS.filter((R) => !R.gone && !on.has(R.key)).map((R) => R.key);
  scnSet({ order: order.filter(have), off, mode: p.mode, secs: p.secs });
  SCN.link = false; SCN.linkSecs = 0; // a playlist the person loads is their own from here on
  scnApply(); scnRefresh();
  return [...new Set(order.concat([...on]))].filter((k) => !have(k));
}
function scnList() {
  return scnOrder().map((i) => { const R = REALMS[i], m = (R.pack && R.pack.meta) || {}; return { key: R.key, name: R.name, on: scnOnKey(R.key), added: !!R.pack, author: m.author || '', license: m.license || '', description: R.description || m.description || '', index: i }; });
}

/* ---- scenes from a file ---- */
function scnValidate(def) {
  if (!def || typeof def !== 'object') throw new Error('registerScene(def): def must be an object');
  if (def.format !== 1) throw new Error('unknown scene pack format ' + JSON.stringify(def.format) + ' (this visualizer reads format 1)');
  const str = (f, need, max) => {
    const v = def[f];
    if (v === undefined || v === null || v === '') { if (need) throw new Error('required field "' + f + '" is missing'); return ''; }
    if (typeof v !== 'string') throw new Error('field "' + f + '" must be a string');
    if (max && v.length > max) throw new Error('field "' + f + '" is longer than ' + max + ' characters');
    return v;
  };
  const out = { format: 1, key: str('key', true), name: str('name', true, 40).trim(), author: str('author', false, 80), license: str('license', false, 80), description: str('description', false, 300),
    glsl: str('glsl', true), helpers: str('helpers', false), entry: str('entry', true), show: def.show == null ? null : def.show, auto: def.auto == null ? null : def.auto };
  if (!SCN_KEY_RE.test(out.key)) throw new Error('key "' + out.key + '" must be 2 to 24 lowercase letters or digits, starting with a letter');
  if (!out.name) throw new Error('required field "name" is missing');
  if (!/void\s+realm\s*\(\s*\)/.test(out.glsl)) throw new Error('glsl must define  void realm()');
  const num = (x) => typeof x === 'number' && Number.isFinite(x), sh = out.show, au = out.auto;
  if (sh) {
    if (typeof sh !== 'object') throw new Error('show must be an object (the scene\'s SHOW row)');
    if (!Array.isArray(sh.z) || sh.z.length !== 3 || !sh.z.every(num) || !(sh.z[0] >= ZOOM_MIN && sh.z[0] <= sh.z[1] && sh.z[1] <= sh.z[2] && sh.z[2] <= ZOOM_MAX)) throw new Error('show.z must be [far, home, close]: ascending numbers from ' + ZOOM_MIN + ' to ' + ZOOM_MAX);
    if (sh.k !== undefined) {
      if (!sh.k || typeof sh.k !== 'object') throw new Error('show.k must be an object { p, s, o, z }');
      sh.k.s = Array.isArray(sh.k.s) ? sh.k.s : []; sh.k.o = Array.isArray(sh.k.o) ? sh.k.o : [];
      if (!num(sh.k.p)) sh.k.p = sh.k.s.length + sh.k.o.length ? 0.4 : 0;
      if (sh.k.ok !== undefined && typeof sh.k.ok !== 'function') throw new Error('show.k.ok must be a function (V, fold)');
    }
    if (sh.no !== undefined && !Array.isArray(sh.no)) throw new Error('show.no must be an array of transition indices');
    if (sh.hold !== undefined && typeof sh.hold !== 'function') throw new Error('show.hold must be a function (V)');
  }
  if (au) {
    if (typeof au !== 'object') throw new Error('auto must be an object (the scene\'s AUTO_REALM row)');
    if (au.kal !== undefined && !Array.isArray(au.kal)) throw new Error('auto.kal must be an array of folds');
    if (au.tr !== undefined && !Array.isArray(au.tr)) throw new Error('auto.tr must be an array of transition names');
    if (au.fx !== undefined && (!au.fx || typeof au.fx !== 'object')) throw new Error('auto.fx must be an object');
  }
  return out;
}
// Direct eval on purpose: the pack must see the engine's scope, as built-in scenes do. Only packs the person chose
// ("Add scene", their own stored list) or a script of the page itself ever reach this.
function scnEvaluate(__d) { return eval('(function(GLSL){\n' + __d.helpers + '\nreturn [\n' + __d.entry + '\n][0];\n})')(__d.glsl); }
function scnWhy(R) { // why a scene could not be prepared, in words
  if (R.startError) return 'init() or frame() threw: ' + R.startError;
  const P = R.P, log = P && P.log;
  if (!log) return 'the scene could not be prepared on this GPU';
  const at = P.src.indexOf(R.src), off = at > 0 ? P.src.slice(0, at).split('\n').length - 1 : 0;
  const lines = String(log).split('\n').map((s) => s.trim()).filter((s) => /error/i.test(s)).slice(0, 4)
    .map((s) => s.replace(/^ERROR: \d+:(\d+):/, (m, n) => 'glsl line ' + (Number(n) - off) + ':'));
  return 'the shader does not compile\n' + (lines.join('\n') || String(log).trim().slice(0, 300));
}
function scnFree(R) { // release a dropped scene's program once nothing on screen or in preparation uses it
  if (!R.P || !gl) return;
  const ri = REALMS.indexOf(R), busy = [D.cur, D.nxt, D.upcoming, D.peek].some((V) => V && V.R === R) || RP.link === ri || RP.cur === ri || RP.settle.some((x) => x.ri === ri) || (HDS.P && HDS.ri === ri);
  if (busy) { setTimeout(() => scnFree(R), 4000); return; }
  const k = programs.indexOf(R.P);
  try { gl.deleteProgram(R.P.p); gl.deleteShader(R.P.fs); } catch (e) { /* context lost */ }
  if (k >= 0) programs.splice(k, 1); R.P = null;
}
function scnRowsOut(R) { // give the engine tables back what they held before this pack
  const rows = R.pack && R.pack.rows; if (!rows) return; R.pack.rows = null;
  if (rows.hadShow) SHOW[R.key] = rows.show; else delete SHOW[R.key];
  if (rows.hadAuto) AUTO_REALM[R.key] = rows.auto; else delete AUTO_REALM[R.key];
}
function scnDrop(R, to) { // a pack that is not (or no longer) wanted; to = the scene to show if it is on screen
  scnRowsOut(R); packRetire(R, to); if (R.pack) R.pack.retired = true;
  scnFree(R);
}
function scnBack(R) { // a built-in scene a pack stood in for returns
  delete R.ready; delete R.failed; R.gone = false; SCN.rev++; R.failed = false; R.ready = !!(R.P && R.P.ok === true);
  if (R.P && !R.ready && gl && RP.link !== REALMS.indexOf(R)) releaseRealmProgram(R);
  delete R._show; delete R._ap;
}
function scnAdmit(ri, opts) { // the pack joins the scene list and the rotation
  const R = REALMS[ri], key = R.key, def = R.pack.def;
  R.gone = false; SCN.rev++;
  // a scene already there under this key steps aside (the pack takes its place on screen too): an older copy of the pack
  // for good, a built-in until the pack is removed
  REALMS.forEach((x, i) => {
    if (i === ri || x.key !== key || x.gone) return;
    if (x.pack && x.pack.scene) { R.pack.stoodIn = x.pack.stoodIn || null; SCN.added.delete(key); scnDrop(x, ri); }
    else if (x.pack) packRemove(key);
    else { R.pack.stoodIn = x; packRetire(x, ri); }
  });
  R.pack.rows = { hadShow: key in SHOW, show: SHOW[key], hadAuto: key in AUTO_REALM, auto: AUTO_REALM[key] };
  if (def.show) SHOW[key] = def.show; if (def.auto) AUTO_REALM[key] = def.auto;
  delete R._show; delete R._ap;
  if (R.evolves) REALM_EVOLVES.add(key);
  SCN.added.set(key, R); SCN.broken = SCN.broken.filter((b) => b.key !== key);
  if (opts.persist && R.pack.text) scnStore.put({ key, text: R.pack.text, replace: !!R.pack.stoodIn, at: Date.now() }).catch(() => toast('This browser blocks storage: ' + R.name + ' stays for this session only'));
  SCN.rev++;
  if (D.cur && D.bag.length && !scnSeq() && scnOnKey(key)) D.bag.splice(Math.floor(journeyRand() * (D.bag.length + 1)), 0, ri); // joins this cycle
  else if (D.cur && scnSeq()) { D.bag = []; refillRealmBag(D.cur.ri); D.upcoming = null; }
  packRefresh();
  if (opts.open && glReady && D.cur) { if (RP.want) RP.want = null; goRealm(ri, 1.6); }
  return { key, name: R.name, index: ri };
}
function scnVerified(ri) { // from realmStateChanged: a scene waiting for its compile check is ready, or has failed
  const w = SCN.waits.get(ri); if (!w) return;
  const R = REALMS[ri]; if (!R.ready && !R.failed) return;
  SCN.waits.delete(ri); SCN.verify = SCN.verify.filter((x) => x !== ri);
  if (R.ready) { try { w.resolve(scnAdmit(ri, w.opts)); } catch (error) { w.reject(error); } return; }
  const why = scnWhy(R); scnDrop(R);
  w.reject(new Error(R.name + ': ' + why));
}
function registerScene(def, opts) {
  opts = opts || {};
  let R;
  try {
    def = scnValidate(def);
    const key = def.key, builtIn = REALMS.find((x) => x.key === key && !x.pack);
    if (builtIn && !opts.replace) throw new Error('"' + key + '" is the built-in scene ' + builtIn.name + '; replacing it has to be confirmed (options.replace)');
    try { R = scnEvaluate(def); } catch (error) { throw new Error('helpers / entry: ' + (error && error.name ? error.name + ': ' : '') + (error && error.message || error)); }
    if (!R || typeof R !== 'object') throw new Error('entry must be one object literal');
    if (R.key !== undefined && R.key !== key) throw new Error('entry key "' + R.key + '" does not match the pack key "' + key + '"');
    R.key = key; if (typeof R.src !== 'string') R.src = def.glsl; R.name = def.name; if (def.description) R.description = def.description;
    packCheck(R, key);
    R.pack = { scene: true, meta: { key, name: def.name, author: def.author, license: def.license, description: def.description }, def, text: typeof opts.text === 'string' ? opts.text : null, rows: null, stoodIn: null };
  } catch (error) { return Promise.reject(error instanceof Error ? error : new Error(String(error))); }
  R.P = null; R.ready = false; R.failed = false; R.gone = true; // hidden until it has compiled
  const ri = REALMS.push(R) - 1; SCN.rev++;
  if (opts.verify === false) return Promise.resolve(scnAdmit(ri, opts));
  return new Promise((resolve, reject) => { SCN.waits.set(ri, { resolve, reject, opts }); SCN.verify.push(ri); });
}
function removeScene(key) {
  const R = SCN.added.get(key);
  if (R) { SCN.added.delete(key); const back = R.pack.stoodIn; if (back) scnBack(back); scnDrop(R, back ? REALMS.indexOf(back) : -1); }
  else if (PACKS.list.some((p) => p.key === key)) packRemove(key); // an older .realm.js pack
  SCN.broken = SCN.broken.filter((b) => b.key !== key);
  if (scnIndex(key) < 0) { SCN.off.delete(key); delete SCN.secs[key]; SCN.order = SCN.order.filter((k) => k !== key); }
  scnApply(); packRefresh();
  return scnStore.del(key);
}
// run a pack file with a stand-in HyperVisualizer that only records the definition
function scnRead(text) {
  let def = null, n = 0;
  try { new Function('HyperVisualizer', String(text))({ registerScene(d) { def = d; n++; return Promise.resolve(); } }); }
  catch (error) { throw new Error('the file does not run: ' + (error && error.message || error)); }
  if (n !== 1) throw new Error('a scene pack is one HyperVisualizer.registerScene({...}) call');
  return def;
}
function addSceneText(text, opts) {
  opts = Object.assign({}, opts, { text: String(text) });
  if (/^\/\/ @realm-pack /m.test(opts.text)) { // the older .realm.js format
    try { const ri = registerRealm(opts.text, { open: !!opts.open, persist: opts.persist !== false }); return Promise.resolve({ key: REALMS[ri].key, name: REALMS[ri].name, index: ri }); }
    catch (error) { return Promise.reject(error); }
  }
  try { return registerScene(scnRead(opts.text), opts); } catch (error) { return Promise.reject(error); }
}
// name, author ... read WITHOUT running the file (for the question before a scene is added)
function scnPeek(text) {
  text = String(text);
  const old = /^\/\/ @realm-pack (\{.*\})$/m.exec(text);
  if (old) { try { const m = JSON.parse(old[1]); return { key: String(m.key || ''), name: String(m.name || m.key || ''), author: String(m.author || ''), license: String(m.license || ''), description: String(m.description || '') }; } catch (e) { return null; } }
  const at = text.search(/\bregisterScene\s*\(/); if (at < 0) return null;
  const head = text.slice(at, at + 6000).split(/\bglsl\s*:/)[0], out = {};
  for (const f of ['key', 'name', 'author', 'license', 'description']) {
    const m = new RegExp('\\b' + f + '\\s*:\\s*(?:\'((?:[^\'\\\\\\n]|\\\\.)*)\'|"((?:[^"\\\\\\n]|\\\\.)*)")').exec(head);
    out[f] = m ? (m[1] !== undefined ? m[1] : m[2]).replace(/\\(.)/g, '$1') : '';
  }
  return out.key ? out : null;
}
// storage: IndexedDB (a pack can be a few hundred kB); every access is guarded
const scnStore = {
  run(mode, fn) {
    return new Promise((resolve, reject) => {
      let rq; try { rq = indexedDB.open('hypervisualizer-scenes', 1); } catch (e) { reject(e); return; }
      rq.onupgradeneeded = () => { try { rq.result.createObjectStore('scenes', { keyPath: 'key' }); } catch (e) { /* exists */ } };
      rq.onerror = () => reject(rq.error); rq.onblocked = () => reject(new Error('blocked'));
      rq.onsuccess = () => {
        const db = rq.result;
        try {
          const tx = db.transaction('scenes', mode), r = fn(tx.objectStore('scenes'));
          tx.oncomplete = () => { db.close(); resolve(r && r.result); };
          tx.onerror = tx.onabort = () => { db.close(); reject(tx.error); };
        } catch (e) { db.close(); reject(e); }
      };
    });
  },
  put(row) { return this.run('readwrite', (s) => s.put(row)); },
  del(key) { return this.run('readwrite', (s) => s.delete(key)).catch(() => {}); },
  all() { return this.run('readonly', (s) => s.getAll()).catch(() => []); }
};
function scnRestore() { // stored packs join again at start; nothing is compiled for it (lazy, like every scene)
  return scnStore.all().then((rows) => (rows || []).slice().sort((a, b) => (a.at || 0) - (b.at || 0)).reduce((p, row) => p.then(() =>
    addSceneText(row.text, { persist: false, verify: false, replace: !!row.replace }).catch((error) => {
      console.error('[HyperVisualizer] stored scene "' + row.key + '" could not be loaded:', error);
      SCN.broken.push({ key: row.key, error: String(error && error.message || error) }); scnRefresh();
    })), Promise.resolve())).then(() => SCN.added.size).catch(() => 0);
}

/* ---- the Scenes editor (Controls > Scenes > Edit) ---- */
function scnRefresh() { // the scene list changed: dim the cards of scenes that are off, hide scenes that are gone, redraw the open editor
  SCN.rev++;
  document.querySelectorAll('.realm-chip').forEach((b) => {
    const R = REALMS[Number(b.dataset.ri)]; if (!R) return;
    if (R.gone) { b.remove(); return; }
    if (scnOnKey(R.key)) delete b.dataset.off; else b.dataset.off = '1';
  });
  if (SCN.ui && SCN.ui.open) scnRows();
}
function scnMark(ri) { const u = SCN.ui; if (u && u.open && u.list) for (const li of u.list.children) li.classList.toggle('now', Number(li.dataset.ri) === ri); }
function scnOpen(open) {
  const u = SCN.ui; if (!u) return;
  u.open = !!open; u.edit.setAttribute('aria-expanded', String(u.open)); u.box.hidden = !u.open; u.chips.hidden = u.open;
  if (u.open) { scnBuild(); scnRows(); }
}
function scnCard(o) { // the small card above the list: the question before a scene is added, an error, a link to copy
  const u = SCN.ui; if (!u || !u.cardHost) return;
  u.cardHost.textContent = ''; if (!o) return;
  const c = document.createElement('div'); c.className = 'scn-card';
  const add = (tag, cls, text) => { if (!text) return; const e = document.createElement(tag); if (cls) e.className = cls; e.textContent = text; c.appendChild(e); };
  add('b', '', o.title); add('small', '', o.sub); add('small', '', o.text); add('p', '', o.warn); add('div', 'scn-err', o.error);
  if (o.copy) { const i = document.createElement('input'); i.className = 'realm-search'; i.readOnly = true; i.value = o.copy; i.setAttribute('aria-label', 'Link'); c.appendChild(i); setTimeout(() => { i.focus(); i.select(); }, 0); }
  const row = document.createElement('div'); row.className = 'scn-act';
  const mk = (text) => { const b = document.createElement('button'); b.type = 'button'; b.className = 'scn-b'; b.textContent = text; row.appendChild(b); return b; };
  mk(o.run ? 'Cancel' : 'Close').addEventListener('click', () => scnCard(null));
  if (o.run) { const ok = mk(o.ok || 'Add'); ok.dataset.ok = '1'; ok.addEventListener('click', () => { ok.disabled = true; ok.textContent = 'Preparing…'; o.run(); }); }
  c.appendChild(row); u.cardHost.appendChild(c);
}
async function scnOffer(file) { // "Add scene": show what it is and the warning; nothing of the file runs before the person agrees
  setPanel(true); scnOpen(true);
  let text = ''; try { text = await file.text(); } catch (e) { scnCard({ title: file.name, error: 'The file could not be read.' }); return; }
  const m = scnPeek(text);
  if (!m) { scnCard({ title: file.name, error: 'This is not a scene pack: no HyperVisualizer.registerScene({...}) call with a key.' }); return; }
  const builtIn = REALMS.find((x) => x.key === m.key && !x.pack), title = m.name || m.key;
  scnCard({ title, sub: [m.author && 'by ' + m.author, m.license].filter(Boolean).join(' · '), text: m.description,
    warn: 'A scene pack contains code. Add it only if you trust where it came from.' + (builtIn ? ' It replaces the built-in scene ' + builtIn.name + ' in this browser.' : ''),
    ok: builtIn ? 'Replace' : 'Add',
    run: () => addSceneText(text, { persist: true, replace: !!builtIn, open: true }).then((r) => { scnCard(null); toast(r.name + ' added'); },
      (error) => { console.error('[HyperVisualizer] scene pack ' + file.name + ':', error); scnCard({ title, error: String(error && error.message || error) }); }) });
}
function scnLinkURL() {
  const p = scnExport(), secs = SCN.linkSecs || (Number(S.sceneDuration) > 0 ? Number(S.sceneDuration) : 0);
  return location.href.split('#')[0].split('?')[0] + '?scenes=' + p.on.join(',') + '&mode=' + p.mode + (secs ? '&secs=' + secs : '');
}
function scnBuild() {
  const u = SCN.ui; if (!u || u.built) return; u.built = true;
  const mk = (cls, text, title, fn) => { const b = document.createElement('button'); b.type = 'button'; b.className = cls; b.textContent = text; if (title) b.title = title; b.addEventListener('click', fn); return b; };
  const bar = document.createElement('div'); bar.className = 'scn-bar';
  const seg = document.createElement('div'); seg.className = 'seg'; seg.setAttribute('role', 'group'); seg.setAttribute('aria-label', 'Scene order');
  u.modes = [['shuffle', 'Shuffle', 'The Auto Show mixes the scenes that are on'], ['sequence', 'Sequence', 'Play the scenes that are on in this order, round and round']].map(([v, text, title]) => {
    const b = mk('', text, title, () => { if (SCN.mode === v) return; SCN.mode = v; scnApply(); scnRows(); }); b.dataset.v = v; seg.appendChild(b); return b; });
  const sp = document.createElement('span'); sp.className = 'sp';
  bar.append(seg, sp, mk('scn-b', 'All on', 'Switch every scene on', () => { scnOwn(); SCN.off.clear(); scnApply(); scnRefresh(); }));
  const bar2 = document.createElement('div'); bar2.className = 'scn-bar';
  u.plIn = document.createElement('input'); u.plIn.type = 'file'; if (!MOBILE) u.plIn.accept = '.json,application/json'; u.plIn.hidden = true; // phones: no filter (iOS greys out types it does not know)
  u.plIn.addEventListener('change', async () => {
    const f = u.plIn.files && u.plIn.files[0]; u.plIn.value = ''; if (!f) return;
    try { const miss = scnImport(JSON.parse(await f.text())); toast(miss.length ? 'Playlist loaded · not in this visualizer: ' + miss.join(', ') : 'Playlist loaded'); }
    catch (error) { toast('Could not load ' + f.name + ': ' + (error && error.message || error)); }
  });
  u.pkIn = document.createElement('input'); u.pkIn.type = 'file'; if (!MOBILE) u.pkIn.accept = '.js,text/javascript'; u.pkIn.hidden = true;
  u.pkIn.addEventListener('change', () => { const f = u.pkIn.files && u.pkIn.files[0]; u.pkIn.value = ''; if (f) scnOffer(f); });
  bar2.append(
    mk('scn-b', 'Save', 'Save this playlist as a small file you can share', () => {
      const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([JSON.stringify(scnExport(), null, 1)], { type: 'application/json' })); a.download = 'scenes.playlist.json';
      document.body.appendChild(a); a.click(); a.remove(); setTimeout(() => URL.revokeObjectURL(a.href), 4000);
    }),
    mk('scn-b', 'Load', 'Load a playlist file', () => u.plIn.click()),
    mk('scn-b', 'Link', 'Copy a link that opens the visualizer with this playlist', () => {
      const url = scnLinkURL(), show = () => scnCard({ title: 'Link to this playlist', copy: url });
      if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(url).then(() => toast('Link copied'), show); else show();
    }),
    sp.cloneNode(), mk('scn-b scn-add', '+ Scene', 'Add a scene from a .scene.js file', () => u.pkIn.click()), u.plIn, u.pkIn);
  u.cardHost = document.createElement('div');
  u.note = document.createElement('p'); u.note.className = 'scn-note'; u.note.hidden = true;
  u.list = document.createElement('ol'); u.list.className = 'scn-list'; u.list.setAttribute('aria-label', 'Scenes');
  u.box.append(bar, bar2, u.cardHost, u.note, u.list);
  const rowOf = (el) => el.closest('.scn-row'), move = (li, d) => {
    const keys = scnOrder().map((i) => REALMS[i].key), at = keys.indexOf(li.dataset.key), to = at + d;
    if (at < 0 || to < 0 || to >= keys.length) return;
    keys.splice(to, 0, keys.splice(at, 1)[0]); SCN.order = keys; scnApply(); scnRows();
    const again = [...u.list.children].find((r) => r.dataset.key === li.dataset.key), f = again && again.querySelector(d < 0 ? '.scn-mv[data-d="-1"]' : '.scn-mv[data-d="1"]');
    if (f && document.body.classList.contains('mobile')) f.focus(); else if (again) again.querySelector('.scn-grip').focus();
  };
  u.list.addEventListener('click', (e) => {
    const li = rowOf(e.target); if (!li) return; const key = li.dataset.key, ri = Number(li.dataset.ri), b = e.target.closest('button'); if (!b) return;
    if (b.classList.contains('scn-on')) {
      const on = !scnOnKey(key);
      if (!on && scnPlayable().length <= 1 && scnOnKey(key)) { toast('One scene has to stay on'); return; }
      scnOwn(); if (on) SCN.off.delete(key); else SCN.off.add(key);
      scnApply(); scnRefresh();
    } else if (b.classList.contains('scn-name')) { if (ri >= 0) { if (RP.want) { RP.want = null; markRealmStates(); } goRealm(ri, 1.6); } }
    else if (b.classList.contains('scn-mv')) move(li, Number(b.dataset.d));
    else if (b.classList.contains('scn-x')) {
      if (b.dataset.arm) { removeScene(key); toast((li.dataset.name || key) + ' removed'); }
      else { b.dataset.arm = '1'; b.textContent = 'Remove?'; setTimeout(() => { if (b.isConnected) { delete b.dataset.arm; b.textContent = '×'; } }, 3000); }
    }
  });
  u.list.addEventListener('change', (e) => {
    const li = rowOf(e.target); if (!li || !e.target.classList.contains('scn-secs')) return;
    const v = scnSecsOk(e.target.value); if (v) SCN.secs[li.dataset.key] = v; else delete SCN.secs[li.dataset.key];
    e.target.value = v || ''; scnApply();
  });
  u.list.addEventListener('keydown', (e) => {
    if (!e.target.classList.contains('scn-grip') || (e.key !== 'ArrowUp' && e.key !== 'ArrowDown')) return;
    e.preventDefault(); e.stopPropagation(); move(rowOf(e.target), e.key === 'ArrowUp' ? -1 : 1);
  });
  u.list.addEventListener('pointerdown', (e) => { // drag a row by its grip
    if (!e.target.classList.contains('scn-grip') || e.button > 0) return;
    const li = rowOf(e.target); e.preventDefault(); li.classList.add('drag');
    const go = (ev) => {
      let before = null;
      for (const r of u.list.children) { if (r === li) continue; const b = r.getBoundingClientRect(); if (ev.clientY < b.top + b.height / 2) { before = r; break; } }
      if (li.nextSibling !== before) u.list.insertBefore(li, before);
      const sc = $('#panel'), lb = sc.getBoundingClientRect(); if (ev.clientY < lb.top + 50) sc.scrollTop -= 14; else if (ev.clientY > lb.bottom - 80) sc.scrollTop += 14; // the panel scrolls, not the list
    };
    const end = () => {
      window.removeEventListener('pointermove', go); window.removeEventListener('pointerup', end); window.removeEventListener('pointercancel', end);
      li.classList.remove('drag'); SCN.order = [...u.list.children].map((r) => r.dataset.key).filter((k) => SCN_KEY_RE.test(k || '')); scnApply();
    };
    window.addEventListener('pointermove', go); window.addEventListener('pointerup', end); window.addEventListener('pointercancel', end);
  });
}
function scnRows() {
  const u = SCN.ui; if (!u || !u.built) return;
  const cur = D.nxt ? D.nxt.ri : D.cur ? D.cur.ri : -1;
  u.box.dataset.mode = SCN.mode; u.modes.forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.v === SCN.mode)));
  u.note.textContent = ''; u.note.hidden = true;
  if (SCN.link) {
    u.note.hidden = false; u.note.append('Playlist from a link, not saved. ');
    const keep = document.createElement('button'); keep.type = 'button'; keep.className = 'scn-b'; keep.textContent = 'Keep'; keep.title = 'Make it your own playlist';
    keep.addEventListener('click', () => { scnOwn(); SCN.link = false; SCN.linkSecs = 0; scnApply(); scnRows(); toast('Playlist kept'); }); u.note.appendChild(keep);
  } else if (!S.autoShow) { u.note.hidden = false; u.note.textContent = 'Auto Show is off: scenes change only when you pick one.'; }
  const hint = S.sceneDuration === 'bars' ? 'bars' : Number(S.sceneDuration) > 0 ? String(S.sceneDuration) : 'stay';
  const frag = document.createDocumentFragment();
  scnOrder().forEach((ri) => {
    const R = REALMS[ri], on = scnOnKey(R.key), li = document.createElement('li');
    li.className = 'scn-row' + (ri === cur ? ' now' : ''); li.dataset.ri = ri; li.dataset.key = R.key; li.dataset.name = R.name;
    if (!on) li.dataset.off = '1'; if (R.failed) li.dataset.failed = '1';
    li.innerHTML = '<button type="button" class="scn-on" role="switch"><i></i></button><button type="button" class="scn-name"></button>'
      + '<input class="scn-secs" type="number" inputmode="numeric" min="5" max="3600" step="5">'
      + (R.pack ? '<button type="button" class="scn-x">×</button>' : '')
      + '<button type="button" class="scn-mv" data-d="-1">▲</button><button type="button" class="scn-mv" data-d="1">▼</button><button type="button" class="scn-grip">≡</button>';
    const [sw, name] = li.querySelectorAll('button'), secs = li.querySelector('.scn-secs'), m = (R.pack && R.pack.meta) || {};
    sw.setAttribute('aria-checked', String(on)); sw.setAttribute('aria-label', R.name + (on ? ': on' : ': off')); sw.title = on ? 'On: plays in the show' : 'Off: skipped';
    name.textContent = R.name; name.title = (R.description || m.description || R.name) + (m.author ? ' · by ' + m.author : '') + ' · tap to go there now';
    secs.value = SCN.secs[R.key] || ''; secs.placeholder = hint; secs.title = 'Seconds for this scene (empty: Time per scene)'; secs.setAttribute('aria-label', 'Seconds for ' + R.name);
    li.querySelectorAll('.scn-mv').forEach((b) => { b.title = b.dataset.d < 0 ? 'Move up' : 'Move down'; b.setAttribute('aria-label', b.title + ': ' + R.name); });
    const grip = li.querySelector('.scn-grip'); grip.title = 'Drag to reorder (or arrow keys)'; grip.setAttribute('aria-label', 'Reorder ' + R.name);
    const x = li.querySelector('.scn-x'); if (x) { x.title = 'Remove this added scene'; x.setAttribute('aria-label', 'Remove ' + R.name); }
    frag.appendChild(li);
  });
  SCN.broken.forEach((b) => { // a stored pack that no longer loads: shown struck through, removable
    const li = document.createElement('li'); li.className = 'scn-row'; li.dataset.ri = -1; li.dataset.key = b.key; li.dataset.failed = '1'; li.dataset.off = '1';
    li.innerHTML = '<span class="scn-on"></span><button type="button" class="scn-name"></button><button type="button" class="scn-x">×</button>';
    li.querySelector('.scn-name').textContent = b.key; li.querySelector('.scn-name').title = b.error; li.querySelector('.scn-x').title = 'Remove this added scene';
    frag.appendChild(li);
  });
  u.list.textContent = ''; u.list.appendChild(frag);
}
function scnInit() {
  buildQueueTools();
  const sec = $('#grp-realms'), h = sec && sec.querySelector('h3'), chips = $('#realmChips'); if (!h || !chips) return;
  let tools = h.querySelector('.h-tools'); if (!tools) { tools = document.createElement('span'); tools.className = 'h-tools'; h.appendChild(tools); }
  const edit = document.createElement('button'); edit.type = 'button'; edit.className = 'scn-edit'; edit.id = 'scnEdit'; edit.textContent = 'Edit';
  edit.title = 'Choose which scenes play, their order and length, or add a scene from a file'; edit.setAttribute('aria-expanded', 'false'); edit.setAttribute('aria-controls', 'scnBox');
  tools.appendChild(edit);
  const box = document.createElement('div'); box.className = 'scn'; box.id = 'scnBox'; box.hidden = true; chips.parentNode.insertBefore(box, chips);
  SCN.ui = { edit, box, chips, open: false, built: false, list: null, cardHost: null, note: null, modes: [] };
  edit.addEventListener('click', () => scnOpen(!SCN.ui.open));
  // Reset: the Auto Show chooses again from every scene (order, lengths and added scenes are kept)
  $('#resetBtn').addEventListener('click', () => { if (!scnChanged()) return; scnOwn(); SCN.mode = 'shuffle'; SCN.off.clear(); scnApply(); scnRefresh(); });
  AUTO.listeners.push(() => { if (SCN.ui.open) scnRows(); });
  // a dropped .scene.js file is offered like one picked with "+ Scene"; anything else continues to the audio drop handler
  window.addEventListener('drop', (e) => {
    const files = e.dataTransfer ? Array.from(e.dataTransfer.files || []) : [], mine = files.filter((f) => /\.scene\.js$/i.test(f.name));
    if (!mine.length) return;
    e.preventDefault(); e.stopImmediatePropagation(); dragDepth = 0; $('#dropzone').hidden = true;
    scnOffer(mine[0]);
    const rest = files.filter((f) => !mine.includes(f) && !/\.realm\.js$/i.test(f.name)); if (rest.length) startFiles(rest);
  }, true);
  scnRefresh();
}
scnInit();
SCN.restored = scnRestore();
/* ========================== END ENGINE v24: SCENES ========================== */
window.VIZ = Object.freeze({
  packFormat: 1,
  registerRealm: (pack, opts) => registerRealm(pack, opts), // -> realm index; throws on an invalid pack
  removePack: (key) => packRemove(key),
  loadPackFile: (file) => packLoadFile(file),
  loadPackURL: async (url) => registerRealm(await (await fetch(url)).text(), { open: true }),
  parsePack: (text) => { const p = packParse(text); return { meta: p.meta, glsl: p.GLSL, helpers: p.HELPERS, entry: p.ENTRY }; },
  get packs() { return PACKS.list.map((p) => ({ key: p.key, name: (p.meta && p.meta.name) || p.key, meta: p.meta, error: p.error })); },
  get restored() { return PACKS.restored; } // resolves once saved packs are registered again
});
/* =================== END COMMUNITY REALM PACKS =================== */

