import json, glob, os, re, collections
tot = collections.defaultdict(lambda: [0, 0, 0.0, '', []])
for f in sorted(glob.glob('reports/**/*.json*', recursive=True)):
    m = re.search(r'([A-Za-z0-9_]+)-(writer|reader)-\d+\.json(\.lemmas)?$', f)
    if not m: continue
    k = m.group(1) + ' ' + m.group(2)
    for e in json.load(open(f)):
        t = tot[k]; t[0] += 1
        if e.get('passed'): t[1] += 1
        else: t[4].append(e.get('goal'))
        for p in e.get('provers', []) or []:
            tm = p.get('time') or 0
            if tm > t[2]: t[2], t[3] = tm, e.get('goal')
out = ['| set | proved | slowest | not proved |', '|---|---|---|---|']
for k, (n, ok, mx, g, bad) in sorted(tot.items()):
    out.append('| %s | %d / %d | %.1f s %s | %s |' % (k, ok, n, mx, g, ' '.join(bad[:30])))
s = '\n'.join(out); print(s)
open(os.environ.get('GITHUB_STEP_SUMMARY', '/dev/null'), 'a').write(s + '\n')
