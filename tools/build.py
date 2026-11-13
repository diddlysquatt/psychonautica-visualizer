#!/usr/bin/env python3
"""build.py <rootdir> <out.html> [--scenes a,b,c] [--verify original.html] [--quiet]

Assemble the single-file visualizer from <rootdir>/src/ (the engine parts listed in src/manifest.json) and
<rootdir>/scenes/<key>/ (one folder per scene). With no options every scene the engine lists is built, plus every
other folder in scenes/ whose name does not start with "_" (new scenes go after the built-in ones).

  --scenes a,b,c   build only these scenes (keys or folder names; "_template" is allowed here). The file is much
                   smaller and starts faster: use it while you work on one scene.
  --verify FILE    after building, compare the result with FILE byte for byte and say IDENTICAL or where it differs.

<rootdir> may also be given as its src/ folder. Python 3.8+, standard library only.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _lib import (eol_join, sha256_bytes, PARTS, PART_FILE, LINE_PH_RE, ROW_PH_RE, TABLES, KEY_RE, read_text, write_text, sha256, read_json,
                  begin_line, end_line, table_span, scene_dirs, entry_field)


def assemble(root, only=None, log=print):
    """Return the built HTML text. `only`: list of scene keys / folder names, or None for all."""
    if os.path.basename(os.path.normpath(root)) == 'src' and os.path.isfile(os.path.join(root, 'manifest.json')):
        root = os.path.dirname(os.path.normpath(root))
    src, scenes_dir = os.path.join(root, 'src'), os.path.join(root, 'scenes')
    manifest = read_json(os.path.join(src, 'manifest.json'))
    text = ''.join(read_text(os.path.join(src, rel)) for rel in manifest['parts'])
    dirs = scene_dirs(scenes_dir)
    by_folder = {os.path.basename(d): k for k, d in dirs.items()}

    listed = []
    for m in LINE_PH_RE.finditer(text):
        if m.group(2) not in listed:
            listed.append(m.group(2))
    extra = [k for k, d in dirs.items() if k not in listed and not os.path.basename(d).startswith('_')]
    if only is None:
        chosen = listed + extra
    else:
        chosen = []
        for name in only:
            key = name if name in dirs else by_folder.get(name)
            if key is None:
                raise SystemExit('build: no scene "%s" in %s (have: %s)' % (name, scenes_dir, ', '.join(sorted(dirs))))
            chosen.append(key)
        extra = [k for k in chosen if k not in listed]
    for key in chosen:
        if key not in dirs:
            raise SystemExit('build: the engine lists scene "%s" but %s has no folder for it' % (key, scenes_dir))
        if not KEY_RE.match(key):
            raise SystemExit('build: scene key "%s" must be 2-24 lowercase letters / digits, starting with a letter' % key)
    chosen_set = set(chosen)

    cache = {}

    def region(part, key):
        p = os.path.join(dirs[key], PART_FILE[part])
        body = read_text(p) if os.path.isfile(p) else ''
        if body and not body.endswith('\n'):
            body += '\n'
        return begin_line(part, key) + body + end_line(part, key)

    def meta(key):
        if key not in cache:
            p = os.path.join(dirs[key], 'scene.json') if key in dirs else ''
            cache[key] = read_json(p) if p and os.path.isfile(p) else {}
        return cache[key]

    # scenes the engine does not list yet: after the last listed scene of each kind (or, in an engine with no scene
    # placeholders at all, nowhere: that is an error)
    if extra:
        for part in PARTS:
            last = None
            for m in LINE_PH_RE.finditer(text):
                if m.group(1) == part:
                    last = m
            if last is None:
                raise SystemExit('build: src/ has no //@scene %s placeholder to put new scenes after' % part)
            add = ''.join('//@scene %s %s\n' % (part, k) for k in extra)
            text = text[:last.end()] + add + text[last.end():]
        for kind, table in TABLES.items():
            have = {m.group(2) for m in ROW_PH_RE.finditer(text) if m.group(1) == kind}
            add = ''.join('  %s: /*@scene %s %s*/,\n' % (k, kind, k) for k in extra if k not in have and meta(k).get(kind))
            if add:
                span = table_span(text, table)
                if not span:
                    log('build: warning: table %s not found; "%s" of new scenes ignored' % (table, kind))
                    continue
                text = text[:span[0]] + add + text[span[0]:]

    def line_ph(m):
        part, key = m.group(1), m.group(2)
        if key in chosen_set:
            return region(part, key)
        return (manifest.get('stubs') or {}).get(key, '') if part == 'helpers' else ''

    def row_ph(m):
        kind, key = m.group(1), m.group(2)
        value = meta(key).get(kind) if key in dirs else None
        if not value:
            if key in chosen_set:
                raise SystemExit('build: scenes/%s/scene.json has no "%s" (the engine table %s expects one)' % (key, kind, TABLES[kind]))
            return '{}'
        return value

    text = LINE_PH_RE.sub(line_ph, text)
    text = ROW_PH_RE.sub(row_ph, text)

    for key in chosen:
        e = read_text(os.path.join(dirs[key], PART_FILE['entry']))
        ek = entry_field(e, 'key')
        if ek and ek != key:
            raise SystemExit('build: scenes/%s: entry.js says key:\'%s\' but the scene key is "%s"' % (os.path.basename(dirs[key]), ek, key))
        nm, jn = entry_field(e, 'name'), meta(key).get('name')
        if nm and jn and nm != jn:
            log('build: warning: scene "%s": name in entry.js (%s) differs from scene.json (%s)' % (key, nm, jn))
    return text, chosen, manifest


def main(argv):
    args, only, verify, quiet = [], None, None, False
    i = 1
    while i < len(argv):
        a = argv[i]
        if a == '--scenes':
            i += 1
            only = [s.strip() for s in argv[i].split(',') if s.strip()]
        elif a.startswith('--scenes='):
            only = [s.strip() for s in a.split('=', 1)[1].split(',') if s.strip()]
        elif a == '--verify':
            i += 1
            verify = argv[i]
        elif a == '--quiet':
            quiet = True
        elif a in ('-h', '--help'):
            print(__doc__)
            return 0
        else:
            args.append(a)
        i += 1
    if len(args) != 2:
        print(__doc__)
        return 2
    log = (lambda *a: None) if quiet else print
    text, chosen, manifest = assemble(args[0], only, log)
    raw = eol_join(text, manifest)
    d = os.path.dirname(args[1])
    if d:
        os.makedirs(d, exist_ok=True)
    with open(args[1], 'wb') as f:
        f.write(raw)
    log('build: %s  %d bytes, %d scenes (%s)' % (args[1], len(raw), len(chosen),
                                               ', '.join(chosen) if len(chosen) <= 8 else ', '.join(chosen[:8]) + ', ...'))
    if verify:
        with open(verify, 'rb') as f:
            want = f.read()
        if want == raw:
            print('verify: IDENTICAL to %s (%d bytes, sha256 %s)' % (verify, len(raw), sha256_bytes(raw)))
        else:
            n = next((k for k in range(min(len(want), len(raw))) if want[k] != raw[k]), min(len(want), len(raw)))
            print('verify: DIFFERENT from %s: first difference at byte %d (sizes %d / %d)' % (verify, n, len(want), len(raw)))
            return 1
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
