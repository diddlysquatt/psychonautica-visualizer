#!/usr/bin/env python3
"""split.py <visualizer.html> <outdir>

Cut the single-file visualizer into small files: <outdir>/src/ (the engine) and <outdir>/scenes/<key>/ (one folder
per scene). `build.py <outdir> <out.html>` puts them back together byte for byte. See _lib.py for the layout.

Re-running it over an existing tree refreshes the code files and the name / description / show / auto fields of
scene.json, and keeps everything else you added there (author, license, credits, README.md, thumb.jpg).
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _lib import (eol_split, sha256_bytes, PARTS, PART_FILE, REGION_RE, LINE_PH_RE, ROW_PH_RE, TABLES, read_text, write_text, sha256, read_json,
                  write_json, match_brace, table_span, entry_field)

# Where the engine JavaScript is cut: (file name, regex of the line that starts the part, name of the anchor the search
# starts after). An anchor that is not found is skipped with a warning (its code stays in the part before it), so the
# round trip never depends on these.
CUTS = [
    ('shader-common', r'^/\* =+ GLSL =+ \*/', None),
    ('scene-shaders-a', r'^//@scene glsl ', 'shader-common'),
    ('post-shaders', r'^const FS_FEEDBACK = ', 'scene-shaders-a'),
    ('scene-shaders-b', r'^//@scene glsl ', 'post-shaders'),
    ('scene-contract-and-helpers', r'^const REALM_MAIN = ', 'scene-shaders-b'),
    ('scene-table', r'^const REALMS = \[', 'scene-contract-and-helpers'),
    ('webgl-core', r'^/\* =+ WebGL core =+ \*/', 'scene-table'),
    ('audio', r'^/\* =+ audio engine =+ \*/', 'webgl-core'),
    ('music-cues', r'^/\* =+ ENGINE v22: MUSIC STRUCTURE CUES', 'audio'),
    ('director-and-transitions', r'^/\* =+ pointer =+ \*/', 'music-cues'),
    ('auto-show', r'^/\* =+ AUTO SHOW =+ \*/', 'director-and-transitions'),
    ('motion-and-audio-response', r'^/\* =+ MOTION SMOOTHNESS =+ \*/', 'auto-show'),
    ('quality', r'^/\* =+ quality =+ \*/', 'motion-and-audio-response'),
    ('rendering', r'^/\* =+ rendering =+ \*/', 'quality'),
    ('frame-loop', r'^/\* =+ frame loop =+ \*/', 'rendering'),
    ('ui', r'^/\* =+ UI =+ \*/', 'frame-loop'),
    ('input', r'^/\* =+ input =+ \*/', 'ui'),
    ('boot', r'^/\* =+ boot =+ \*/', 'input'),
    ('offline-render', r'^/\* =+ offline \(music video\) rendering', 'boot'),
    ('scene-packs', r'^/\* =+ COMMUNITY REALM PACKS', 'offline-render'),
    ('scene-manager', r'^/\* =+ ENGINE v24: SCENES', 'scene-packs', 'optional'),
    ('automation-api', r'^window\.HyperVisualizer = \{', 'scene-packs'),
]


def attach_comment(text, pos):
    """Move a cut up over a comment block that sits directly above it (so a part starts with its own comment)."""
    while pos > 0:
        prev_start = text.rfind('\n', 0, pos - 1) + 1
        prev = text[prev_start:pos - 1]
        if prev.startswith('//') and not prev.startswith('//@scene'):
            pos = prev_start
            continue
        if prev.rstrip().endswith('*/'):
            close = prev_start + len(prev.rstrip()) - 2
            start = text.rfind('/*', 0, close)
            if start >= 0 and (start == 0 or text[start - 1] == '\n') and text.find('*/', start + 2) == close:
                pos = start
                continue
        break
    return pos


def split_rows(js, keys, warn):
    """Replace each scene's row value in the SHOW / AUTO_REALM tables by a placeholder. Returns (js, {kind: {key: text}})."""
    rows = {k: {} for k in TABLES}
    for kind, name in TABLES.items():
        span = table_span(js, name)
        if not span:
            warn('table %s not found: scene.json files get no "%s"' % (name, kind))
            continue
        a, b = span
        body, out, i = js[a:b], [], 0
        for m in re.finditer(r'^  ([a-z0-9]+): (?=\{)', body, re.M):
            key = m.group(1)
            if key not in keys or m.start() < i:
                continue
            j = match_brace(body, m.end())
            rows[kind][key] = body[m.end():j]
            out.append(body[i:m.end()])
            out.append('/*@scene %s %s*/' % (kind, key))
            i = j
        out.append(body[i:])
        js = js[:a] + ''.join(out) + js[b:]
    return js, rows


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    src_html, outdir = argv[1], argv[2]
    with open(src_html, 'rb') as f:
        raw = f.read()
    text, eol = eol_split(raw)
    warnings = []
    warn = warnings.append

    # 1. the shell: head | css | body | script | tail
    m_style = re.search(r'^<style>\n', text, re.M)
    m_style_end = re.search(r'^</style>\n', text, re.M)
    best = None
    for m in re.finditer(r'^<script>\n', text, re.M):
        e = text.find('\n</script>\n', m.end() - 1)
        if e >= 0 and (best is None or e - m.end() > best[1] - best[0].end()):
            best = (m, e)
    if not (m_style and m_style_end and best):
        print('split: cannot find the <style> / <script> blocks (each tag must be alone on its line)')
        return 1
    m_script, m_script_end = best
    head = text[:m_style.end()]
    css = text[m_style.end():m_style_end.start()]
    body = text[m_style_end.start():m_script.end()]
    js = text[m_script.end():m_script_end + 1]
    tail = text[m_script_end + 1:]
    assert head + css + body + js + tail == text
    if LINE_PH_RE.search(text) or ROW_PH_RE.search(text):
        print('split: the input already contains //@scene placeholders: is it a file from src/?')
        return 1

    # 2. scene regions -> placeholders
    scenes, order = {}, []

    def take(m):
        part, key = m.group(1).lower(), m.group(2)
        if key not in scenes:
            scenes[key] = {}
            order.append(key)
        if part in scenes[key]:
            raise SystemExit('split: scene "%s" has two %s regions' % (key, part))
        scenes[key][part] = m.group(3)
        return '//@scene %s %s\n' % (part, key)

    js = REGION_RE.sub(take, js)
    for stray in re.finditer(r'^// (BEGIN|END) NEWREALM [A-Z]+: [a-z0-9]+$', js, re.M):
        raise SystemExit('split: unpaired marker line: ' + stray.group(0))
    entry_order = [m.group(2) for m in LINE_PH_RE.finditer(js) if m.group(1) == 'entry']
    for key in order:
        for part in ('glsl', 'entry'):
            if part not in scenes[key]:
                raise SystemExit('split: scene "%s" has no %s region' % (key, part))

    # 3. Auto Show rows -> placeholders
    js, rows = split_rows(js, set(scenes), warn)

    # 4. cut the engine JavaScript into parts
    found, pos_of = [], {}
    for cut in CUTS:
        name, rx, after = cut[:3]
        start = pos_of.get(after, 0) if after else 0
        if after and after not in pos_of:
            start = max(pos_of.values()) if pos_of else 0
        m = re.compile(rx, re.M).search(js, start)
        if not m:
            if len(cut) > 3:
                continue
            warn('engine section "%s" not found (pattern %s): its code stays in the previous part' % (name, rx))
            continue
        pos_of[name] = m.start()
        found.append((attach_comment(js, m.start()), name))
    found.sort()
    cuts = [(0, 'core')]
    for pos, name in found:
        if pos > cuts[-1][0]:
            cuts.append((pos, name))
        else:
            warn('engine section "%s" starts at or before "%s": merged' % (name, cuts[-1][1]))
    pieces = []
    for n, (pos, name) in enumerate(cuts):
        end = cuts[n + 1][0] if n + 1 < len(cuts) else len(js)
        pieces.append(('js/%02d-%s.js' % (n, name), js[pos:end]))
    assert ''.join(p[1] for p in pieces) == js

    # 4b. names the ENGINE reads or writes but a SCENE declares (so far: one variable the offline loader resets).
    # A build that leaves that scene out needs a stand-in declaration, or the engine code throws.
    stubs = {}
    for key in order:
        code = re.sub(r'`[^`]*`', '``', scenes[key].get('helpers', ''))
        for m in re.finditer(r'^(let|var|const|function)\s+([A-Za-z_$][\w$]*)', code, re.M):
            kind, name = m.group(1), m.group(2)
            if not name.lower().startswith(key):
                continue
            if re.search(r'(?<![\w$.\x27"])' + re.escape(name) + r'(?![\w$\x27":])', js):
                decl = 'function %s() {}' % name if kind == 'function' else 'let %s = null;' % name
                note = ' // stand-in: the engine names this; the scene "%s" (not in this build) declares it' % key
                stubs[key] = stubs.get(key, '') + decl + note + '\n'
    for key, text in stubs.items():
        warn('the engine refers to a name declared by scene "%s": builds without that scene get a stand-in (%s)' % (key, text.split(' //')[0]))

    # 5. write src/
    src = os.path.join(outdir, 'src')
    old = os.path.join(src, 'manifest.json')
    if os.path.isfile(old):
        for rel in read_json(old).get('parts', []):
            p = os.path.join(src, rel)
            if os.path.isfile(p):
                os.remove(p)
    parts = [('shell-head.html', head), ('style.css', css), ('shell-body.html', body)] + pieces + [('shell-tail.html', tail)]
    for rel, content in parts:
        write_text(os.path.join(src, rel), content)
    write_json(os.path.join(src, 'manifest.json'), {
        'format': 1,
        'note': 'Written by tools/split.py. build.py concatenates "parts" in this order and fills the //@scene placeholders from scenes/<key>/.',
        'parts': [p[0] for p in parts],
        'scenes': entry_order,
        'stubs': stubs,
        'bytes': len(raw),
        'sha256': sha256_bytes(raw),
        **eol,
    })

    # 6. write scenes/<key>/
    # the first scenes keep their short descriptions in the UI code instead of their entry: pick those up too
    ui_desc = {}
    dm = re.search(r'const descriptions=\{([^}]*)\}', js)
    if dm:
        ui_desc = dict(re.findall(r"([a-z0-9]+):'([^']*)'", dm.group(1)))
    for key in order:
        d = os.path.join(outdir, 'scenes', key)
        for part in PARTS:
            write_text(os.path.join(d, PART_FILE[part]), scenes[key].get(part, ''))
        meta_path = os.path.join(d, 'scene.json')
        meta = read_json(meta_path) if os.path.isfile(meta_path) else {}
        entry = scenes[key]['entry']
        fresh = {'key': key, 'name': entry_field(entry, 'name') or key.upper()}
        desc = entry_field(entry, 'description') or ui_desc.get(key)
        if desc:
            fresh['description'] = desc
        elif 'description' not in meta:
            fresh['description'] = ''
        meta.update(fresh)
        meta.setdefault('author', 'Stoned Ape / Psychonautica')
        meta.setdefault('license', 'AGPL-3.0-or-later')
        meta.setdefault('builtin', True)
        for kind in TABLES:
            if key in rows[kind]:
                meta[kind] = rows[kind][key]
            else:
                meta.pop(kind, None)
        ordered = {k: meta[k] for k in ('key', 'name', 'description', 'author', 'license') if k in meta}
        ordered.update({k: v for k, v in meta.items() if k not in ordered and k not in TABLES})
        ordered.update({k: meta[k] for k in TABLES if k in meta})
        write_json(meta_path, ordered)

    for w in warnings:
        print('split: warning: ' + w)
    print('split: %d bytes -> %d engine parts in %s, %d scenes in %s' % (
        len(raw), len(parts), src, len(order), os.path.join(outdir, 'scenes')))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
