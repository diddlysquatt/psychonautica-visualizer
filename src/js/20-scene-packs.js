/* ===================== COMMUNITY REALM PACKS (runtime mod loading) =====================
   Self-contained block: nothing outside it changes. window.VIZ.registerRealm(pack) adds a realm while the page
   runs. A pack (.realm.js, format 1, see community/docs/REALM-API.md) is one realm's three NEWREALM regions
   (GLSL, HELPERS, ENTRY) plus a `// @realm-pack {json}` header line. It is evaluated HERE, inside the engine's
   scope, as  function(){ <GLSL> <HELPERS> return [ <ENTRY> ][0]; }  so realm code uses exactly the helpers a
   built-in realm sees (rand, clamp, lerp, ease, pick, v3, rotMat3, BANDS, PTR, S ...), and strict mode keeps its
   own declarations local to the pack. The realm is appended to REALMS and then rides the normal pipeline:
   stepRealmPrep() prepares any realm that is neither ready nor failed (link on the driver's threads, settle,
   warm-up draw), the realm cards are rebuilt, and it joins the Auto playlist bag (D.bag).
   Loaded packs are saved (IndexedDB, localStorage fallback) and re-registered on the next visit. Removing a pack
   deletes it from storage and retires it for this session: it stays in REALMS (indices of visits, the bag and
   the preparation queue stay valid) but reads as permanently failed, so it is never prepared or picked again.
   UI: Controls > Realms > "Load realm pack" (file picker), or drop .realm.js files anywhere on the page. */
const PACKS = { list: [], restored: null };
const PACK_DB = 'viszualizerrr-realm-packs', PACK_LS = 'viszualizerrr.realmPacks', PACK_KEY_RE = /^[a-z][a-z0-9]{1,23}$/;
REALMS.forEach((R) => { if (R.evolves) REALM_EVOLVES.add(R.key); }); // built-in realms may also declare evolves:true
function packParse(text) {
  text = String(text).replace(/\r\n/g, '\n'); if (!text.endsWith('\n')) text += '\n';
  const h = /^\/\/ @realm-pack (\{.*\})$/m.exec(text);
  if (!h) throw new Error('not a scene pack (no "// @realm-pack {...}" header line)');
  const meta = JSON.parse(h[1]), key = meta.key, part = { meta };
  if (!PACK_KEY_RE.test(key || '')) throw new Error('pack key "' + key + '" must be 2-24 lowercase letters/digits');
  for (const t of ['GLSL', 'HELPERS', 'ENTRY']) {
    const b = '// BEGIN NEWREALM ' + t + ': ' + key + '\n', i = text.indexOf(b), j = i < 0 ? -1 : text.indexOf('\n// END NEWREALM ' + t + ': ' + key + '\n', i + b.length - 1);
    if (i < 0 || j < 0) throw new Error('pack "' + key + '" has no complete ' + t + ' region');
    part[t] = text.slice(i + b.length, j + 1);
  }
  return part;
}
// Direct eval on purpose: the pack must see the engine's scope, as built-in realms do. Only packs the person
// chose (file picker, drop, or their own saved list) ever reach this.
function packEvaluate(__pack) { return eval('(function(){\n' + __pack.GLSL + __pack.HELPERS + 'return [\n' + __pack.ENTRY + '][0];\n})')(); }
function packCheck(R, key) {
  if (!R || typeof R !== 'object') throw new Error('the ENTRY region must be a realm object');
  if (R.key !== key) throw new Error('entry key "' + R.key + '" does not match the pack key "' + key + '"');
  if (typeof R.src !== 'string' || !/void\s+realm\s*\(\s*\)/.test(R.src)) throw new Error('entry src must be GLSL that defines void realm()');
  if (typeof R.init !== 'function' || typeof R.frame !== 'function') throw new Error('entry needs init(seed) and frame(V, F, dt)');
  R.name = String(R.name || key);
  R.fb = Object.assign({ zoom: 0, rot: 0, decay: .25, warp: 0, echo: .04, droste: 0, win: 0, key: .08 }, R.fb || {});
  if (!Array.isArray(R.syms) || !R.syms.length) R.syms = [0];
  if (!Array.isArray(R.cont)) R.cont = [];
  if (!(R.cost > 0)) R.cost = 1;
}
// a retired pack realm reads as failed forever (engine resets after a context loss included)
function packRetire(R, to) { // ENGINE v24: to = the scene that takes its place on screen (default: the next one)
  R.gone = true; SCN.rev++; // ENGINE v24: out of every scene list
  Object.defineProperty(R, 'ready', { get: () => false, set: () => {}, configurable: true });
  Object.defineProperty(R, 'failed', { get: () => true, set: () => {}, configurable: true });
  if (D.upcoming && D.upcoming.R === R) D.upcoming = null;
  if (RP.want && REALMS[RP.want.ri] === R) RP.want = null;
  if (D.cur && D.cur.R === R && glReady) { const ri = to >= 0 ? to : pickRealm(D.cur.ri); if (ri >= 0) goRealm(ri, 1.6); }
}
function registerRealm(pack, opts) {
  opts = opts || {};
  let R, meta, src = null;
  if (typeof pack === 'string') { src = pack; const part = packParse(pack); meta = part.meta; R = packEvaluate(part); packCheck(R, meta.key); }
  else if (pack && typeof pack === 'object') { R = pack; meta = { key: R.key, name: R.name }; packCheck(R, R.key); }
  else throw new Error('registerRealm(pack): pass the text of a .realm.js pack or a realm object');
  const key = R.key, old = REALMS.find((x) => x.key === key && x.pack && !x.pack.retired);
  if (REALMS.some((x) => x.key === key && !x.pack)) throw new Error('"' + key + '" is a built-in scene of this visualizer');
  if (old) { packRetire(old); old.pack.retired = true; }   // a newer copy of a loaded pack replaces it
  R.pack = { meta, src }; R.P = null; R.ready = false; R.failed = false;
  if (R.evolves) REALM_EVOLVES.add(key);
  const ri = REALMS.push(R) - 1;
  if (D.bag.length) D.bag.splice(Math.floor(journeyRand() * (D.bag.length + 1)), 0, ri); // joins this Auto cycle
  PACKS.list = PACKS.list.filter((p) => p.key !== key).concat([{ key, meta, R, error: '' }]);
  if (src && opts.persist !== false) packSave(key, src);
  packRefresh();
  if (opts.open && glReady && D.cur) { RP.want = { ri, dur: 1.6 }; markRealmStates(); toast(R.name + ' loaded · it opens as soon as it is ready'); }
  return ri;
}
function packRemove(key) {
  const p = PACKS.list.find((x) => x.key === key);
  PACKS.list = PACKS.list.filter((x) => x.key !== key);
  if (p && p.R) { packRetire(p.R); p.R.pack.retired = true; }
  packDelete(key); packRefresh();
}
async function packLoadFile(file) {
  try { registerRealm(await file.text(), { open: true }); }
  catch (error) { console.error('[HyperVisualizer] realm pack ' + file.name + ':', error); toast('Could not load ' + file.name + ': ' + (error.message || error)); }
}
// storage: IndexedDB (packs can be large), localStorage as fallback; every access is guarded
const packLs = {
  get() { try { return JSON.parse(localStorage.getItem(PACK_LS) || '{}') || {}; } catch (e) { return {}; } },
  set(o) { try { localStorage.setItem(PACK_LS, JSON.stringify(o)); return true; } catch (e) { return false; } }
};
function packIdb(mode, fn) {
  return new Promise((resolve, reject) => {
    let rq; try { rq = indexedDB.open(PACK_DB, 1); } catch (e) { reject(e); return; }
    rq.onupgradeneeded = () => { try { rq.result.createObjectStore('packs', { keyPath: 'key' }); } catch (e) { /* exists */ } };
    rq.onerror = () => reject(rq.error); rq.onblocked = () => reject(new Error('blocked'));
    rq.onsuccess = () => {
      const db = rq.result;
      try {
        const tx = db.transaction('packs', mode), r = fn(tx.objectStore('packs'));
        tx.oncomplete = () => { db.close(); resolve(r && r.result); };
        tx.onerror = tx.onabort = () => { db.close(); reject(tx.error); };
      } catch (e) { db.close(); reject(e); }
    };
  });
}
function packSave(key, src) {
  return packIdb('readwrite', (s) => s.put({ key, src, at: Date.now() })).catch(() => {
    const o = packLs.get(); o[key] = src; if (!packLs.set(o)) toast('This browser blocks storage: the pack stays for this session only');
  });
}
function packDelete(key) {
  const o = packLs.get(); if (key in o) { delete o[key]; packLs.set(o); }
  return packIdb('readwrite', (s) => s.delete(key)).catch(() => {});
}
function packRestore() {
  return packIdb('readonly', (s) => s.getAll()).catch(() => []).then((rows) => {
    rows = (rows || []).slice().sort((a, b) => (a.at || 0) - (b.at || 0));
    const ls = packLs.get(); Object.keys(ls).forEach((k) => { if (!rows.some((r) => r.key === k)) rows.push({ key: k, src: ls[k] }); });
    for (const row of rows) {
      try { registerRealm(row.src, { persist: false }); }
      catch (error) {
        console.error('[HyperVisualizer] saved realm pack "' + row.key + '" could not be loaded:', error);
        PACKS.list.push({ key: row.key, meta: { key: row.key, name: row.key }, R: null, error: String(error.message || error) });
      }
    }
    packRefresh();
    return PACKS.list.length;
  }).catch((error) => { console.error('[HyperVisualizer] realm packs:', error); return 0; });
}
// UI: rebuilt realm cards (retired packs hidden, packs marked) and a pack manager under them
function packRefresh() {
  buildRealmChips();
  let live = 0;
  document.querySelectorAll('.realm-chip').forEach((b) => {
    const R = REALMS[Number(b.dataset.ri)]; if (!R) return;
    if (R.pack && R.pack.retired) { b.remove(); return; }
    live++; if (R.pack) b.dataset.pack = '1';
  });
  const search = $('#realmSearch'); if (search) search.placeholder = 'Find a scene (' + live + ')';
  scnRefresh(); // ENGINE v24: packs are listed, added and removed in the Scenes editor
}
// dropped .realm.js files are packs; anything else continues to the audio drop handler
window.addEventListener('drop', (e) => {
  const files = e.dataTransfer ? Array.from(e.dataTransfer.files || []) : [], packs = files.filter((f) => /\.realm\.js$/i.test(f.name));
  if (!packs.length) return;
  e.preventDefault(); e.stopImmediatePropagation(); dragDepth = 0; $('#dropzone').hidden = true;
  packs.forEach(packLoadFile);
  const rest = files.filter((f) => !packs.includes(f)); if (rest.length) startFiles(rest);
}, true);
packRefresh();
PACKS.restored = packRestore();
