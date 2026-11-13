"""Shared helpers for split.py, build.py and the other tools. Python 3.8+, standard library only.

Vocabulary: the docs say "scene"; the engine code still says "realm" (REALMS, NEWREALM markers). Same thing.

How the single HTML file maps to small files
--------------------------------------------
The visualizer is one HTML file. split.py cuts it into:

  src/manifest.json            the ordered list of engine parts (build.py concatenates them in this order)
  src/shell-head.html          everything up to and including the <style> line
  src/style.css                the CSS
  src/shell-body.html          </style> ... <script>
  src/js/NN-name.js            the engine JavaScript, cut at its own section headers
  src/shell-tail.html          </script> ... end of file
  scenes/<key>/scene.glsl      the scene's GLSL region   (JavaScript that declares the shader as a template string)
  scenes/<key>/helpers.js      the scene's HELPERS region (top-level JavaScript helpers)
  scenes/<key>/entry.js        the scene's ENTRY region   (the scene object in the REALMS array)
  scenes/<key>/scene.json      name, description, credits, and the scene's Auto Show rows ("show", "auto")

Inside the engine parts a scene is represented by placeholders:

  //@scene glsl <key>          a whole line: replaced by the marker lines plus scenes/<key>/scene.glsl
  //@scene helpers <key>       same for helpers.js
  //@scene entry <key>         same for entry.js
  /*@scene show <key>*/        inside the SHOW table: replaced by the "show" text of scenes/<key>/scene.json
  /*@scene auto <key>*/        inside the AUTO_REALM table: replaced by the "auto" text

split followed by build reproduces the input byte for byte.
"""
import hashlib
import json
import os
import re

PARTS = ('glsl', 'helpers', 'entry')
PART_FILE = {'glsl': 'scene.glsl', 'helpers': 'helpers.js', 'entry': 'entry.js'}
MARK = {'glsl': 'GLSL', 'helpers': 'HELPERS', 'entry': 'ENTRY'}
KEY_RE = re.compile(r'^[a-z][a-z0-9]{1,23}$')
REGION_RE = re.compile(r'^// BEGIN NEWREALM (GLSL|HELPERS|ENTRY): ([a-z0-9]+)\n(.*?)^// END NEWREALM \1: \2\n', re.S | re.M)
LINE_PH_RE = re.compile(r'^//@scene (glsl|helpers|entry) ([a-z0-9]+)\n', re.M)
ROW_PH_RE = re.compile(r'/\*@scene (show|auto) ([a-z0-9]+)\*/')
TABLES = {'show': 'SHOW', 'auto': 'AUTO_REALM'}


def read_text(path):
    with open(path, 'rb') as f:
        return f.read().decode('utf-8')


def write_text(path, text):
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    with open(path, 'wb') as f:
        f.write(text.encode('utf-8'))


def eol_split(raw):
    """Decode file bytes and normalise line ends to LF. Returns (text, info); info goes into the manifest so that
    build.py can restore the original line ends exactly: {"newline": "lf" | "crlf" | "mixed", "eol_runs": [...]}."""
    text = raw.decode('utf-8')
    crlf, lf = text.count('\r\n'), text.count('\n')
    if crlf == 0:
        return text, {'newline': 'lf'}
    if crlf == lf and text.count('\r') == crlf:
        return text.replace('\r\n', '\n'), {'newline': 'crlf'}
    runs = []  # mixed: run-length list of line-end kinds, [count, 1 = CRLF / 0 = LF]
    for line in text.split('\n')[:-1]:
        kind = 1 if line.endswith('\r') else 0
        if runs and runs[-1][1] == kind:
            runs[-1][0] += 1
        else:
            runs.append([1, kind])
    return text.replace('\r\n', '\n'), {'newline': 'mixed', 'eol_runs': runs}


def eol_join(text, info):
    """Inverse of eol_split: LF text -> bytes with the recorded line ends."""
    kind = (info or {}).get('newline', 'lf')
    if kind == 'crlf':
        text = text.replace('\n', '\r\n')
    elif kind == 'mixed':
        lines = text.split('\n')
        runs = info.get('eol_runs') or []
        if sum(r[0] for r in runs) == len(lines) - 1:
            out, i = [], 0
            for count, k in runs:
                for line in lines[i:i + count]:
                    out.append(line + ('\r\n' if k else '\n'))
                i += count
            out.append(lines[-1])
            text = ''.join(out)
        else:  # the sources were edited: the per-line record no longer fits, use CRLF throughout
            text = text.replace('\n', '\r\n')
    return text.encode('utf-8')


def sha256_bytes(raw):
    return hashlib.sha256(raw).hexdigest()


def sha256(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def read_json(path):
    return json.loads(read_text(path))


def write_json(path, obj):
    write_text(path, json.dumps(obj, indent=2, ensure_ascii=False) + '\n')


def begin_line(part, key):
    return '// BEGIN NEWREALM %s: %s\n' % (MARK[part], key)


def end_line(part, key):
    return '// END NEWREALM %s: %s\n' % (MARK[part], key)


def match_brace(text, i):
    """text[i] is '{'. Return the index just past its matching '}', skipping strings and comments."""
    assert text[i] == '{'
    depth, n = 0, len(text)
    while i < n:
        c = text[i]
        if c in '\'"`':
            j = i + 1
            while j < n and text[j] != c:
                j += 2 if text[j] == '\\' else 1
            i = j + 1
            continue
        if c == '/' and i + 1 < n and text[i + 1] == '/':
            j = text.find('\n', i)
            i = n if j < 0 else j
            continue
        if c == '/' and i + 1 < n and text[i + 1] == '*':
            j = text.find('*/', i + 2)
            i = n if j < 0 else j + 2
            continue
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError('unbalanced braces')


def table_span(text, name):
    """(start of the first row, index of the closing '};') of `const NAME = {` ... `};`, or None."""
    m = re.search(r'^const %s = \{\n' % re.escape(name), text, re.M)
    if not m:
        return None
    end = text.find('\n};', m.end() - 1)
    if end < 0:
        return None
    return m.end(), end + 1


def scene_dirs(scenes_dir):
    """{key: folder path} for every folder in scenes/ that holds a scene (entry.js present)."""
    out = {}
    if not os.path.isdir(scenes_dir):
        return out
    for name in sorted(os.listdir(scenes_dir)):
        d = os.path.join(scenes_dir, name)
        if not os.path.isfile(os.path.join(d, 'entry.js')):
            continue
        key = name
        meta = os.path.join(d, 'scene.json')
        if os.path.isfile(meta):
            try:
                key = read_json(meta).get('key') or name
            except ValueError:
                pass
        out[key] = d
    return out


def entry_field(entry_text, field):
    """First `field:'...'` or `field:"..."` string in a scene's entry.js (name, description), or None."""
    m = re.search(r'\b%s\s*:\s*(\'(?:[^\'\\\n]|\\.)*\'|"(?:[^"\\\n]|\\.)*")' % field, entry_text)
    if not m:
        return None
    s = m.group(1)
    body = s[1:-1]
    return re.sub(r'\\(.)', r'\1', body)
