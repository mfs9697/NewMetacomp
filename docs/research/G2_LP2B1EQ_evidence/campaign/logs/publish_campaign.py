"""Copy the G2-LP2B1-EQ-001 campaign evidence into the worktree (docs/research/G2_LP2B1EQ_evidence/campaign/) with
absolute local paths sanitized. Each destination folder gets SANITIZATION.json (source SHA-256, published SHA-256,
replacements). UTF-16 logs are converted to UTF-8. Binary .mat/.f64 are NOT published (archive only); the figure
PNG/PDF are copied byte for byte."""
import hashlib, json, os, re, shutil, sys
EX = r'<repo>'
WT = r'<worktree>'
SCR = r'<scratch>'
RD = os.path.join(SCR, 'lp2b1eqrun')
DST = os.path.join(WT, 'docs', 'research', 'G2_LP2B1EQ_evidence', 'campaign')
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
    return t, n


sha = lambda b: hashlib.sha256(b).hexdigest()
plan = []
J = lambda *a: os.path.join(*a)
for f in sorted(os.listdir(J(RD, 'pre'))):
    if f == 'AUTH_COMMENT_7211904299.json':
        continue   # full GitHub API dump not republished; the reduced record below keeps author, URL, time, body hash
    plan.append((J(RD, 'pre', f), f'pre/{f}'))
for f in sorted(os.listdir(J(RD, 'campaign'))):
    plan.append((J(RD, 'campaign', f), f'campaign/{f}'))
for s in ('EQB-soft1-S9', 'EQB-H-S10'):
    sd = J(EX, 'outputs', 'g2_lp2b1_eq_v1', 'run_lp2b1_eq_v1', s)
    for f in ('COMPARISON.json', 'COMPARISON.mat.manifest.json', 'PHASE.mat.manifest.json', 'SOLUTION.mat.manifest.json'):
        plan.append((J(sd, f), f'records/{s}/{f}'))
    plan.append((J(sd, 'GEOMETRY_h040', 'ATTEMPT.json'), f'records/{s}/GEOMETRY_h040/ATTEMPT.json'))
plan.append((J(EX, 'outputs', 'g2_lp2b1_eq_receipts', 'G2-LP2B1-EQ-001', 'RECEIPT.mat.manifest.json'), 'records/receipt/RECEIPT.mat.manifest.json'))
plan.append((J(EX, 'outputs', 'LP2B1EQ_CAMPAIGN.json'), 'records/LP2B1EQ_CAMPAIGN.json'))
for f in sorted(os.listdir(J(RD, 'post'))):
    plan.append((J(RD, 'post', f), f'post/{f}'))
for f in sorted(os.listdir(J(RD, 'verify'))):
    if os.path.isfile(J(RD, 'verify', f)):
        plan.append((J(RD, 'verify', f), f'verify/{f}'))
plan.append((J(RD, 'verify', 'raw', 'RAW_INDEX.json'), 'verify/RAW_INDEX.json'))
for f in sorted(os.listdir(RD)):
    p = J(RD, f)
    if os.path.isfile(p) and (f.endswith('.m') or f.endswith('.py') or f.endswith('.log') or f.endswith('.txt') or f == 'tables.md'):
        plan.append((p, f'logs/{f}'))
for f in sorted(os.listdir(J(RD, 'logs'))):
    if f.endswith('.log') or f.endswith('.txt'):
        plan.append((J(RD, 'logs', f), f'logs/earlier/{f}'))
rec = {}


def put(rel, ob, srcb, n):
    out = os.path.join(DST, *rel.split('/')); os.makedirs(os.path.dirname(out), exist_ok=True); assert not os.path.exists(out), out
    open(out, 'wb').write(ob)
    rec.setdefault(os.path.dirname(rel), []).append({'file': os.path.basename(rel), 'sourceSHA256': sha(srcb), 'publishedSHA256': sha(ob), 'replacements': n})


for src, rel in plan:
    b = open(src, 'rb').read()
    t = b.decode('utf-16') if b[:2] in (b'\xff\xfe', b'\xfe\xff') else b.decode('utf-8')
    t = t.replace('\r\n', '\n'); t, n = sanitize(t)
    if rel.endswith('.log'):
        t = '\n'.join(l for l in t.split('\n') if not l.startswith('[Warning: Name is nonexistent'))
    put(rel, t.encode('utf-8'), b, n)
# reduced authorization record (public GitHub comment)
c = json.load(open(J(RD, 'pre', 'AUTH_COMMENT_7211904299.json'), encoding='utf-8'))
red = {'html_url': c['html_url'], 'author': c['user']['login'], 'created_at': c['created_at'], 'bodySHA256': sha(c['body'].encode('utf-8')),
       'sourceFileSHA256': fsha if False else sha(open(J(RD, 'pre', 'AUTH_COMMENT_7211904299.json'), 'rb').read())}
put('pre/AUTH_COMMENT_7211904299.reduced.json', (json.dumps(red, indent=1) + '\n').encode('utf-8'), open(J(RD, 'pre', 'AUTH_COMMENT_7211904299.json'), 'rb').read(), {})
for f in sorted(os.listdir(J(RD, 'figures'))):
    b = open(J(RD, 'figures', f), 'rb').read(); put(f'figures/{f}', b, b, {})
for fold, L in rec.items():
    p = os.path.join(DST, *fold.split('/'), 'SANITIZATION.json'); assert not os.path.exists(p)
    json.dump({'schema': 'NewMetacomp.G2.LP2B1EQ.Sanitization.v1', 'rule': 'absolute local paths replaced by <repo>, <worktree>, <temp>, <scratch>, <backup>, <home>, <drive>, <matlabroot>; UTF-16 logs converted to UTF-8; MATLAB startup path warnings removed from logs; binaries (.mat, .f64) only in the archive; figures byte for byte',
               'files': L}, open(p, 'w', encoding='utf-8', newline='\n'), indent=1)
print('published', sum(len(v) for v in rec.values()), 'files into', len(rec), 'folders')
