#!/usr/bin/env python3
"""new-scene.py <key> ["NAME"] [--author "your name"] [--description "a few words"]

Start a new scene: copies scenes/_template/ to scenes/<key>/ and renames everything in it to your key.
<key> is 2-24 lowercase letters / digits starting with a letter (it becomes the folder name, the prefix of your
JavaScript names and the scene's id in links). NAME is what people see; default: the key in capitals.

Then:   python tools/build.py . dist/<key>.html --scenes <key>     (a small build with only your scene)
        node tools/check-scene.mjs <key>                           (the checks and a contact sheet)
Run from the repository root. Python 3.8+, standard library only.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _lib import KEY_RE, PART_FILE, read_text, write_text, read_json, write_json, scene_dirs

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main(argv):
    args, author, description = [], None, None
    i = 1
    while i < len(argv):
        if argv[i] == '--author':
            i += 1
            author = argv[i]
        elif argv[i] == '--description':
            i += 1
            description = argv[i]
        elif argv[i] in ('-h', '--help'):
            print(__doc__)
            return 0
        else:
            args.append(argv[i])
        i += 1
    if not args:
        print(__doc__)
        return 2
    key = args[0]
    name = args[1] if len(args) > 1 else key.upper()
    if not KEY_RE.match(key):
        print('new-scene: the key must be 2-24 lowercase letters / digits and start with a letter')
        return 1
    scenes = os.path.join(ROOT, 'scenes')
    if key in scene_dirs(scenes) or os.path.exists(os.path.join(scenes, key)) or key == 'template':
        print('new-scene: a scene "%s" already exists: pick another key' % key)
        return 1
    if "'" in name or '\\' in name or (description and ("'" in description or '\\' in description)):
        print("new-scene: please leave ' and \\ out of the name and description (you can edit entry.js afterwards)")
        return 1
    src, dst = os.path.join(scenes, '_template'), os.path.join(scenes, key)
    for part in PART_FILE.values():
        t = read_text(os.path.join(src, part))
        t = t.replace('R_TEMPLATE', 'R_' + key.upper())
        t = re.sub(r"\btemplate(?=[A-Z])", key, t)                 # templateInit -> <key>Init
        t = t.replace("key:'template'", "key:'%s'" % key).replace("name:'TEMPLATE'", "name:'%s'" % name)
        t = t.replace('TEMPLATE helpers', name + ' helpers').replace('/* TEMPLATE:', '/* ' + name + ':')
        if description:
            t = re.sub(r"description:'[^']*'", lambda m: "description:'%s'" % description, t)
        write_text(os.path.join(dst, part), t)
    meta = read_json(os.path.join(src, 'scene.json'))
    meta.update({'key': key, 'name': name, 'builtin': False})
    if description:
        meta['description'] = description
    meta['author'] = author or 'your name here'
    write_json(os.path.join(dst, 'scene.json'), meta)
    write_text(os.path.join(dst, 'README.md'), (
        '# %s\n\nWhat it is: (one paragraph).\n\nHow it moves with the music: (which sounds drive what; what changes on a drop or a new section).\n\n'
        'Framings: far = ..., home = ..., close = ... (the three numbers of "show" in scene.json).\n\nKnown weak points: ...\n' % name))
    print('new-scene: created scenes/%s/ (scene.glsl, helpers.js, entry.js, scene.json, README.md)' % key)
    print('next:  python tools/build.py . dist/%s.html --scenes %s   then   node tools/check-scene.mjs %s' % (key, key, key))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
