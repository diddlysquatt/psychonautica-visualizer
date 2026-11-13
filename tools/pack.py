#!/usr/bin/env python3
"""pack.py <key> [out.scene.js] [--author "name"] [--license "AGPL-3.0-or-later"]

Turn scenes/<key>/ into one scene pack file (default: dist/scenes/<key>.scene.js): the file people add to their
visualizer with "Add scene". The format is described in docs/SCENE-PACKS.md. author / license default to the
values in the scene's scene.json. Run from the repository root. Python 3.8+, standard library only.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _lib import read_text, write_text, read_json, scene_dirs, entry_field

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def raw(text):
    """A JavaScript String.raw template literal holding `text` exactly."""
    out = text.replace('${', "${'$'}{").replace('`', "${'`'}")
    if out.endswith('\\') or re.search(r'\\u(?![0-9a-fA-F]{4}|\{)|\\x(?![0-9a-fA-F]{2})', out):
        return json.dumps(text)  # a form String.raw cannot hold: a plain JSON string literal is equally valid
    return 'String.raw`' + out + '`'


def js_string(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('\n', ' ') + "'"


def make_pack(key, author=None, license_=None):
    dirs = scene_dirs(os.path.join(ROOT, 'scenes'))
    by_folder = {os.path.basename(d): k for k, d in dirs.items()}
    key = key if key in dirs else by_folder.get(key)
    if key is None:
        raise SystemExit('pack: no such scene')
    d = dirs[key]
    rd = lambda f: read_text(os.path.join(d, f)) if os.path.isfile(os.path.join(d, f)) else ''
    region, helpers, entry = rd('scene.glsl'), rd('helpers.js'), rd('entry.js')
    meta = read_json(os.path.join(d, 'scene.json')) if os.path.isfile(os.path.join(d, 'scene.json')) else {}
    const = 'R_' + key.upper()
    m = re.search(r'const\s+' + re.escape(const) + r'\s*=\s*`(.*?)`\s*;[ \t]*\n?', region, re.S)
    if not m:
        raise SystemExit('pack: scenes/%s/scene.glsl has no  const %s = `...`;  (the shader must be one template string)' % (key, const))
    glsl = m.group(1)
    if '${' in glsl:
        raise SystemExit('pack: the shader text contains "${"')
    # the rest of the GLSL file (comments, a few scenes keep small tables there) goes in front of the helpers
    rest = region[:m.start()] + 'const %s = GLSL;\n' % const + region[m.end():]
    helpers = rest + helpers
    name = meta.get('name') or entry_field(entry, 'name') or key.upper()
    desc = meta.get('description') or entry_field(entry, 'description') or ''
    lines = [
        '// Scene pack for the Psychonautica visualizer. Add it with Scenes > "Add scene".',
        '// A scene pack is code that runs inside the visualizer: only add packs from people you trust.',
        'HyperVisualizer.registerScene({',
        '  format: 1,',
        '  key: %s,' % js_string(key),
        '  name: %s,' % js_string(name),
        '  author: %s,' % js_string(author or meta.get('author') or ''),
        '  license: %s,' % js_string(license_ or meta.get('license') or ''),
        '  description: %s,' % js_string(desc),
        '  glsl: %s,' % raw(glsl),
        '  helpers: %s,' % raw(helpers),
        '  entry: %s' % raw(entry.rstrip().rstrip(',')) + (',' if meta.get('show') or meta.get('auto') else ''),
    ]
    rows = [(k, meta[k]) for k in ('show', 'auto') if meta.get(k)]
    for n, (k, v) in enumerate(rows):
        lines.append('  %s: %s%s' % (k, v, ',' if n + 1 < len(rows) else ''))
    lines.append('});')
    return key, '\n'.join(lines) + '\n'


def main(argv):
    args, author, license_ = [], None, None
    i = 1
    while i < len(argv):
        if argv[i] == '--author':
            i += 1
            author = argv[i]
        elif argv[i] == '--license':
            i += 1
            license_ = argv[i]
        elif argv[i] in ('-h', '--help'):
            print(__doc__)
            return 0
        else:
            args.append(argv[i])
        i += 1
    if not args:
        print(__doc__)
        return 2
    key, text = make_pack(args[0], author, license_)
    out = args[1] if len(args) > 1 else os.path.join(ROOT, 'dist', 'scenes', key + '.scene.js')
    write_text(out, text)
    print('pack: %s (%d bytes)' % (out, len(text.encode('utf-8'))))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
