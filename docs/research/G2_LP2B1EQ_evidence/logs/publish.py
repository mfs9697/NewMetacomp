"""Copy LP2-B1-EQ readiness evidence into the worktree with absolute local paths sanitized.
Each destination folder gets SANITIZATION.json: source path (relative), source SHA-256, published SHA-256, replacements.
UTF-16 logs (runml) are converted to UTF-8 first. Binary files (.mat, .f64) are NOT published (archive only)."""
import hashlib, json, os, re, shutil, sys
EX = r'<repo>'
WT = r'<home>\Documents\GitHub\NewMetacomp_wt_b1eq'
SC = r'<scratch>\lp2b1eq'
RR = os.path.join(EX, 'outputs', 'g2_lp2b1eq_readiness_v1')
DST = os.path.join(WT, 'docs', 'research', 'G2_LP2B1EQ_evidence')
PAT = [(r'<scratch>', '<scratch>'),
       (r'<temp>', '<temp>'), (r'<repo>', '<repo>'),
       (r'<backup>', '<backup>'), (r'<matlabroot>', '<matlabroot>'),
       (r'<drive>', '<drive>'), (r'<home>', '<home>')]


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
    t = re.sub(r'lp2b1eq_(t|git)_\d{17}', r'lp2b1eq_\1_<stamp>', t)
    return t, n


sha = lambda b: hashlib.sha256(b).hexdigest()
plan = []   # (src, dst-relative)
for d in ('wp0_v3', 'wp0_v4'):
    plan.append((os.path.join(RR, d, 'LP2B1EQ_WP0_REFERENCES.json'), f'wp0/{d}/LP2B1EQ_WP0_REFERENCES.json'))
for d in ('replay_v1', 'replay_v2', 'replay_v3'):
    for s in ('EQB-soft1-S9', 'EQB-H-S10'):
        f = os.path.join(RR, d, s, 'GEOMETRY_REPLAY.json')
        if os.path.isfile(f):
            plan.append((f, f'replay/{d}/{s}/GEOMETRY_REPLAY.json'))
        plan.append((os.path.join(RR, d, s, 'GEOMETRY_h040', 'ATTEMPT.json'), f'replay/{d}/{s}/GEOMETRY_h040/ATTEMPT.json'))
plan.append((os.path.join(RR, 'diag_tip_v1', 'LP2B1EQ_DIAG_TIP.json'), 'replay/diag_tip_v1/LP2B1EQ_DIAG_TIP.json'))
for d in ('export_v3',):
    plan.append((os.path.join(RR, d, 'EXPORT_INDEX.json'), f'export/{d}/EXPORT_INDEX.json'))
for d in ('tests_v2', 'tests_v3'):
    plan.append((os.path.join(RR, d, 'LP2B1EQ_TESTS.json'), f'tests/{d}/LP2B1EQ_TESTS.json'))
for f in sorted(os.listdir(os.path.join(SC, 'pre'))):
    plan.append((os.path.join(SC, 'pre', f), f'closure/{f}'))
for f in sorted(os.listdir(os.path.join(SC, 'post'))):
    plan.append((os.path.join(SC, 'post', f), f'closure/{f}'))
for f in sorted(os.listdir(SC)):
    if (f.endswith('.m') and f[0] == 's' and f[1].isdigit()) or (f.endswith('.log') and not f.endswith('.utf8.log')):
        plan.append((os.path.join(SC, f), f'logs/{f}'))
for f in ('publish.py', 'repin.sh', 'digest.py'):
    plan.append((os.path.join(SC, f), f'logs/{f}'))
rec = {}
for src, rel in plan:
    b = open(src, 'rb').read()
    if b[:2] in (b'\xff\xfe', b'\xfe\xff'):
        t = b.decode('utf-16')
    else:
        t = b.decode('utf-8')
    t = t.replace('\r\n', '\n')
    t, n = sanitize(t)
    if rel.startswith('logs/') and rel.endswith('.log'):
        t = '\n'.join(l for l in t.split('\n') if not l.startswith('[Warning: Name is nonexistent'))
    out = os.path.join(DST, *rel.split('/')); os.makedirs(os.path.dirname(out), exist_ok=True); assert not os.path.exists(out), out
    ob = t.encode('utf-8'); open(out, 'wb').write(ob)
    fold = os.path.dirname(rel)
    rec.setdefault(fold, []).append({'file': os.path.basename(rel), 'sourceSHA256': sha(b), 'publishedSHA256': sha(ob), 'replacements': n})
for fold, L in rec.items():
    p = os.path.join(DST, *fold.split('/'), 'SANITIZATION.json'); assert not os.path.exists(p)
    json.dump({'schema': 'NewMetacomp.G2.LP2B1EQ.Sanitization.v1', 'rule': 'absolute local paths replaced by <repo>, <temp>, <scratch>, <backup>, <home>, <drive>, <matlabroot>; test temp stamps by <stamp>; UTF-16 logs converted to UTF-8; MATLAB startup path warnings removed from logs; binaries (.mat, .f64) only in the archive',
               'files': L}, open(p, 'w', encoding='utf-8', newline='\n'), indent=1)
print('published', len(plan), 'files into', len(rec), 'folders')
