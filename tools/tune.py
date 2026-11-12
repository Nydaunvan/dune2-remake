#!/usr/bin/env python3
"""Modifie des caractéristiques d'unités dans game_data.gd : tools/tune.py unité champ=valeur [champ=valeur…] [unité …]
Un champ absent (vs_ground…) est ajouté. Affiche chaque changement."""
import re, sys
p = 'game_data.gd'; s = open(p).read()
cur = None
for a in sys.argv[1:]:
    if '=' not in a:
        cur = a; continue
    k, v = a.split('=')
    m = re.search(r'\n\t"%s": \{\n(.*?)\n\t\},' % cur, s, re.S)
    assert m, cur
    blk = m.group(1)
    fm = re.search(r'"%s": ([0-9.]+)' % k, blk)
    if fm:
        nb = blk[:fm.start(1)] + v + blk[fm.end(1):]; old = fm.group(1)
    else:
        nb = blk.rstrip().rstrip(',') + ', "%s": %s,' % (k, v); old = '-'
    print(f'{cur}.{k}: {old} -> {v}')
    s = s[:m.start(1)] + nb + s[m.end(1):]
open(p, 'w').write(s)
