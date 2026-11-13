#!/usr/bin/env python3
"""gallery.py [--out gallery] [--visualizer ../dist/psychonautica-visualizer.html] [--scenes-url ../scenes] [--no-packs]

Write the scene gallery: one static page (<out>/index.html) with a card per scene in scenes/ (thumbnail, name,
author, description, "open in the visualizer", "download scene pack"), and the packs themselves in <out>/packs/.
Everything comes from scenes/<key>/scene.json and thumb.jpg. No scripts, no outside resources.

  --visualizer URL   where the built visualizer is, seen from the gallery page (the Pages build passes "../")
  --scenes-url URL   where the scenes folder is, seen from the gallery page (for the thumbnails)
Run from the repository root. Python 3.8+, standard library only.
"""
import html
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _lib import read_json, write_text, scene_dirs, read_text

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CSS = """
:root{color-scheme:dark}
*{box-sizing:border-box}
body{margin:0;background:#0b0a10;color:#e9e6f2;font:16px/1.5 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
header{max-width:1200px;margin:0 auto;padding:40px 20px 8px}
h1{margin:0 0 6px;font-size:30px;letter-spacing:.02em}
header p{margin:0 0 6px;color:#b9b3c9;max-width:70ch}
a{color:#ffd166}
main{max-width:1200px;margin:0 auto;padding:16px 20px 60px;display:grid;grid-template-columns:repeat(auto-fill,minmax(270px,1fr));gap:18px}
article{background:#15131d;border:1px solid #2a2638;border-radius:10px;overflow:hidden;display:flex;flex-direction:column}
.thumb{display:block;aspect-ratio:16/9;background:linear-gradient(135deg,#2b1b4a,#0f3a4a 55%,#4a1b3a);position:relative}
.thumb img{width:100%;height:100%;object-fit:cover;display:block}
.thumb span{position:absolute;inset:0;display:grid;place-items:center;font-size:22px;letter-spacing:.12em;color:#ffffffb0}
.body{padding:12px 14px 14px;display:flex;flex-direction:column;gap:6px;flex:1}
h2{margin:0;font-size:18px;letter-spacing:.06em}
.by{color:#9d97b0;font-size:13px}
.desc{margin:0;color:#cfcadd;font-size:14px;flex:1}
.links{display:flex;gap:14px;flex-wrap:wrap;font-size:14px;margin-top:4px}
.new{font-size:11px;border:1px solid #ffd16680;color:#ffd166;border-radius:20px;padding:0 7px;margin-left:8px;vertical-align:2px}
footer{max-width:1200px;margin:0 auto;padding:0 20px 50px;color:#9d97b0;font-size:14px}
"""


def main(argv):
    out, viz, scenes_url, packs = os.path.join(ROOT, 'gallery'), '../dist/psychonautica-visualizer.html', '../scenes', True
    i = 1
    while i < len(argv):
        a = argv[i]
        if a == '--out':
            i += 1
            out = argv[i]
        elif a == '--visualizer':
            i += 1
            viz = argv[i]
        elif a == '--scenes-url':
            i += 1
            scenes_url = argv[i]
        elif a == '--no-packs':
            packs = False
        else:
            print(__doc__)
            return 0 if a in ('-h', '--help') else 2
        i += 1
    dirs = scene_dirs(os.path.join(ROOT, 'scenes'))
    order = []
    manifest = os.path.join(ROOT, 'src', 'manifest.json')
    if os.path.isfile(manifest):
        order = [k for k in read_json(manifest).get('scenes', []) if k in dirs]
    keys = order + sorted(k for k, d in dirs.items() if k not in order and not os.path.basename(d).startswith('_'))
    make_pack = None
    if packs:
        from pack import make_pack
    cards, n_packs = [], 0
    e = html.escape
    for key in keys:
        d = dirs[key]
        meta = read_json(os.path.join(d, 'scene.json')) if os.path.isfile(os.path.join(d, 'scene.json')) else {}
        name, author = meta.get('name') or key.upper(), meta.get('author') or 'unknown'
        desc = (meta.get('description') or '').strip()
        desc = desc[:1].upper() + desc[1:] if desc else ''
        folder = os.path.basename(d)
        has_thumb = os.path.isfile(os.path.join(d, 'thumb.jpg'))
        thumb = ('<img loading="lazy" src="%s/%s/thumb.jpg" alt="%s">' % (e(scenes_url), e(folder), e(name))) if has_thumb else '<span>%s</span>' % e(name)
        sep = '&' if '?' in viz else '?'
        open_url = '%s%srealm=%s&scenes=%s' % (viz, sep, key, key)
        links = ['<a href="%s">Open in the visualizer</a>' % e(open_url)]
        if make_pack:
            try:
                _, text = make_pack(key)
                write_text(os.path.join(out, 'packs', key + '.scene.js'), text)
                links.append('<a href="packs/%s.scene.js" download>Download scene pack</a>' % e(key))
                n_packs += 1
            except SystemExit as err:
                print('gallery: no pack for %s (%s)' % (key, err))
        new = '' if meta.get('builtin') else '<span class="new">community</span>'
        cards.append(
            '<article id="%s"><a class="thumb" href="%s">%s</a><div class="body"><h2>%s%s</h2><div class="by">by %s%s</div>'
            '<p class="desc">%s</p><div class="links">%s</div></div></article>' % (
                e(key), e(open_url), thumb, e(name), new, e(author),
                (' &middot; ' + e(meta['license'])) if meta.get('license') else '', e(desc), ' '.join(links)))
    page = (
        '<!DOCTYPE html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">\n'
        '<title>Scenes: Psychonautica Visualizer</title><style>%s</style></head><body>\n'
        '<header><h1>Scenes</h1><p>%d scenes for the <a href="%s">Psychonautica Visualizer</a>. Open one in the visualizer, or download its '
        'scene pack and add it to your own copy with Scenes &gt; Edit &gt; "+ Scene".</p>'
        '<p>Want to make one? <a href="https://github.com/diddlysquatt/psychonautica-visualizer#make-a-scene">Here is how</a>. '
        'A scene pack is code: only add packs from people you trust.</p></header>\n<main>\n%s\n</main>\n'
        '<footer>Psychonautica Visualizer by Stoned Ape / Psychonautica and contributors. Code under AGPL-3.0-or-later; what you make with it is yours.</footer>\n'
        '</body></html>\n' % (CSS, len(cards), e(viz), '\n'.join(cards)))
    write_text(os.path.join(out, 'index.html'), page)
    print('gallery: %s (%d scenes, %d packs)' % (os.path.join(out, 'index.html'), len(cards), n_packs))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
