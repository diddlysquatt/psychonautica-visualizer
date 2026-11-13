/* ================================ boot =============================== */
const $dock = $('#dock');
const setDockH = () => document.documentElement.style.setProperty('--dockH', $dock.offsetHeight + 'px');
if (window.ResizeObserver) new ResizeObserver(setDockH).observe($dock); else window.addEventListener('resize', setDockH);
setDockH();
buildRealmChips();
buildControls();
rowVisibility(); renderQueue(); // v21: rows hidden from the start, queue tools built
markAutoShow();
addRenderRestore();
$panel.inert = true; $('#dock').inert = true;
markSafe();
$('#hud').hidden = !S.hud;
updateTransport();
requestAnimationFrame(frame);

