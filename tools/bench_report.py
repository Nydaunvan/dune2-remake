#!/usr/bin/env python3
"""Synthèse du banc d'équilibrage : victoires par faction, durée, unités produites."""
import json, sys, collections
rows = [json.loads(l[6:]) for l in open(sys.argv[1]) if l.startswith("BENCH ")]
errs = sorted(set(l.strip() for l in open(sys.argv[1]) if "SCRIPT ERROR" in l))
pts = collections.Counter(); games = collections.Counter(); built = collections.defaultdict(collections.Counter)
kinds = collections.Counter(); dur = []; pair = collections.defaultdict(float)
for r in rows:
    a, b, w = r["a"], r["b"], r["win"]
    games[a] += 1; games[b] += 1; dur.append(r["t"]); kinds[w.strip("AB") or "KO"] += 1
    pa = 1 if w.startswith("A") else (0 if w.startswith("B") else 0.5)
    pts[a] += pa; pts[b] += 1 - pa; pair[(a, b)] += pa; pair[(b, a)] += 1 - pa
    for i, f in enumerate((a, b)):
        for k, v in r["built"][i].items(): built[f][k] += v
print(f"{len(rows)} parties, durée moyenne {sum(dur)/max(len(dur),1)/60:.1f} min ; fins : {dict(kinds)} (KO = base détruite, ~ = aux points, = nul)")
for f in sorted(games, key=lambda f: -pts[f]/games[f]):
    print(f"  {f:9s} {100*pts[f]/games[f]:5.1f} %  ({pts[f]:.1f}/{games[f]})")
fs = sorted(games)
print("  duel (ligne bat colonne) : " + " ".join(f"{f[:5]:>6s}" for f in fs))
for a in fs:
    print(f"    {a:9s}              " + " ".join("     -" if a == b else f"{pair[(a,b)]:6.1f}" for b in fs))
for f in fs:
    print(f"  {f} produit : " + ", ".join(f"{k}×{v}" for k, v in built[f].most_common()))
for e in errs: print("ERREUR", e)
