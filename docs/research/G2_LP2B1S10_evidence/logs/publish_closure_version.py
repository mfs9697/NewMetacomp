"""Copy LP2-B1-S10 readiness evidence into the worktree with absolute local paths sanitized.
Each destination folder gets SANITIZATION.json: source SHA-256, published SHA-256, replacements. UTF-16 logs are converted to
UTF-8; MATLAB startup path warnings are removed from logs. Binary files (.mat, .f64) are NOT published (archive only).
usage: python publish.py <stage: main|closure>"""
import hashlib, json, os, re, sys
stage = sys.argv[1]
EX = r'<repo>'
WT = r'<worktree>'
SCR = r'<scratch>'
SC = os.path.join(SCR, 'lp2b1s10')
RR = os.path.join(EX, 'outputs', 'g2_lp2b1s10_readiness_v1')
DST = os.path.join(WT, 'docs', 'research', 'G2_LP2B1S10_evidence')
PAT = [(SCR, '<scratch>'), (r'<temp>', '<temp>'), (EX, '<repo>'), (WT, '<worktree>'),
       (r'<backup>', '<backup>'), (r'<matlabroot>', '<matlabroot>'),
       (r'<matlabroot>', '<matlabroot>'), (r'<drive>', '<drive>'), (r'<home>', '<home>')]


def variants(p):
    v = {p, p.replace('\\', '/'), p.replace('\\', '\\\\'), p.lower(), p.replace('\\', '/').lower(), p.replace('\\', '\\\\').lower()}
    if p.startswith('C:'):
        v |= {'/c' + p[2:].replace('\\', '/'), 'c' + p[1:], ('c' + p[1:]).replace('\\', '\\\\')}
    return sorted(v, key=len, reverse=True)


def sanitize(t):
    n = {}
    for p, r in PAT:
        for v in variants(p):
            k = t.count(v)
            if k:
                t = t.replace(v, r); n[r] = n.get(r, 0) + k
    t = re.sub(r'lp2b1s10_(t|git)_\d{17}', r'lp2b1s10_\1_<stamp>', t)
    return t, n


sha = lambda b: hashlib.sha256(b).hexdigest()
J = os.path.join
plan = []
if stage == 'main':
    for d in ('wp0_v1', 'wp0_v2'):
        plan.append((J(RR, d, 'LP2B1S10_WP0.json'), f'wp0/{d}/LP2B1S10_WP0.json'))
    plan.append((J(RR, 'replay_v1', 'soft1_S10', 'GEOMETRY_REPLAY.json'), 'replay/replay_v1/soft1_S10/GEOMETRY_REPLAY.json'))
    plan.append((J(RR, 'replay_v1', 'soft1_S10', 'GEOMETRY_h040', 'ATTEMPT.json'), 'replay/replay_v1/soft1_S10/GEOMETRY_h040/ATTEMPT.json'))
    plan.append((J(RR, 'export_v1', 'EXPORT_INDEX.json'), 'export/export_v1/EXPORT_INDEX.json'))
    for d in ('tests_v1', 'tests_v2'):
        plan.append((J(RR, d, 'LP2B1S10_TESTS.json'), f'tests/{d}/LP2B1S10_TESTS.json'))
    for f in sorted(os.listdir(J(SC, 'pre'))):
        if not f.startswith('D_STABILITY_LOG'):   # stability logs are published at the closure stage
            plan.append((J(SC, 'pre', f), f'closure/{f}'))
    for f in sorted(os.listdir(SC)):
        if (f.endswith('.m') and f[0] == 's' and f[1].isdigit()) or (f.endswith('.log') and not f.endswith('.utf8.log')) or f in ('repin.sh', 'publish.py'):
            plan.append((J(SC, f), f'logs/{f}'))
    plan.append((J(SCR, 'lp2b1eq', 'digest.py'), 'logs/digest.py'))
else:
    for f in sorted(os.listdir(J(SC, 'post'))):
        plan.append((J(SC, 'post', f), f'closure/{f}'))
    for f in ('D_STABILITY_LOG_attempt1_INVALID_QUERY.csv', 'D_STABILITY_LOG_v2.csv'):
        plan.append((J(SC, 'pre', f), f'closure/{f}'))
    plan.append((J(SC, 'd_stability.ps1'), 'logs/d_stability.ps1'))
    plan.append((J(SC, 'publish.py'), 'logs/publish_closure_version.py'))
rec = {}
for src, rel in plan:
    b = open(src, 'rb').read()
    t = b.decode('utf-16') if b[:2] in (b'\xff\xfe', b'\xfe\xff') else b.decode('utf-8')
    t = t.replace('\r\n', '\n'); t, n = sanitize(t)
    if rel.endswith('.log'):
        t = '\n'.join(l for l in t.split('\n') if not l.startswith('[Warning: Name is nonexistent'))
    out = os.path.join(DST, *rel.split('/')); os.makedirs(os.path.dirname(out), exist_ok=True); assert not os.path.exists(out), out
    ob = t.encode('utf-8'); open(out, 'wb').write(ob)
    rec.setdefault(os.path.dirname(rel), []).append({'file': os.path.basename(rel), 'sourceSHA256': sha(b), 'publishedSHA256': sha(ob), 'replacements': n})
for fold, L in rec.items():
    p = os.path.join(DST, *fold.split('/'), 'SANITIZATION.json')
    old = json.load(open(p, encoding='utf-8'))['files'] if os.path.exists(p) else []
    names = {x['file'] for x in L}
    json.dump({'schema': 'NewMetacomp.G2.LP2B1S10.Sanitization.v1', 'rule': 'absolute local paths replaced by <repo>, <worktree>, <temp>, <scratch>, <backup>, <home>, <drive>, <matlabroot>; test temp stamps by <stamp>; UTF-16 logs converted to UTF-8; MATLAB startup path warnings removed from logs; binaries (.mat, .f64) only in the archive',
               'files': [x for x in old if x['file'] not in names] + L}, open(p, 'w', encoding='utf-8', newline='\n'), indent=1)
print('published', len(plan), 'files into', len(rec), 'folders')
