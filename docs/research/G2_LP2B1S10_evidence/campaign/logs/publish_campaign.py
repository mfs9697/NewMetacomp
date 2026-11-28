"""Copy the G2-LP2B1-S10-001 campaign evidence into the worktree (docs/research/G2_LP2B1S10_evidence/campaign/) with
absolute local paths sanitized (adapted from the accepted LP2-B1-EQ publisher). Each destination folder gets SANITIZATION.json
(source SHA-256, published SHA-256, replacements). UTF-16 logs are converted to UTF-8; MATLAB startup path warnings are removed
from logs. Binary .mat/.f64 are NOT published (archive only); the current figure PNG/PDF are copied byte for byte (superseded
v1 layouts only in the archive). Full GitHub API dumps are replaced by reduced records (author, URL, time, body hash)."""
import hashlib, json, os, sys
EX = r'<repo>'
WT = r'<worktree>'
SCR = r'<scratch>'
RD = os.path.join(SCR, 'lp2b1s10run')
DST = os.path.join(WT, 'docs', 'research', 'G2_LP2B1S10_evidence', 'campaign')
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
J = os.path.join
plan = []
SKIP_PRE = ('AUTH_COMMENT_7237508619.json', 'READINESS_REVIEW_6091037917.json')
for f in sorted(os.listdir(J(RD, 'pre'))):
    if f not in SKIP_PRE:
        plan.append((J(RD, 'pre', f), f'pre/{f}'))
for f in sorted(os.listdir(J(RD, 'campaign'))):
    plan.append((J(RD, 'campaign', f), f'campaign/{f}'))
sd = J(EX, 'outputs', 'g2_lp2b1_s10_v1', 'run_lp2b1_s10_v1', 'soft1')
for f in ('S10/PHASE.mat.manifest.json', 'S10/SOLUTION.mat.manifest.json', 'S10/STATE.mat.manifest.json', 'TERMINAL.mat.manifest.json', 'S10/GEOMETRY_h040/ATTEMPT.json'):
    plan.append((J(sd, *f.split('/')), f'records/soft1/{f}'))
for f in ('RECEIPT.mat.manifest.json', 'ADMIT_soft1_S10.mat.manifest.json'):
    plan.append((J(EX, 'outputs', 'g2_lp2b1_s10_receipts', 'G2-LP2B1-S10-001', f), f'records/ledger/{f}'))
plan.append((J(EX, 'outputs', 'LP2B1S10_CAMPAIGN.json'), 'records/LP2B1S10_CAMPAIGN.json'))
for f in sorted(os.listdir(J(RD, 'post'))):
    plan.append((J(RD, 'post', f), f'post/{f}'))
for f in sorted(os.listdir(J(RD, 'verify'))):
    if os.path.isfile(J(RD, 'verify', f)):
        plan.append((J(RD, 'verify', f), f'verify/{f}'))
plan.append((J(RD, 'verify', 'raw', 'RAW_INDEX.json'), 'verify/RAW_INDEX.json'))
plan.append((J(RD, 'verify', 'raw_hist_v2', 'RAW_INDEX.json'), 'verify/RAW_INDEX_hist_v2.json'))
for f in sorted(os.listdir(RD)):
    p = J(RD, f)
    if os.path.isfile(p) and (f.endswith(('.m', '.py', '.log', '.txt', '.cmd')) or f == 'memo_template.md'):
        plan.append((p, f'logs/{f}'))
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
for fn, kind in (('AUTH_COMMENT_7237508619.json', 'comment'), ('READINESS_REVIEW_6091037917.json', 'review')):
    b = open(J(RD, 'pre', fn), 'rb').read(); c = json.loads(b.decode('utf-8'))
    red = {'kind': kind, 'html_url': c['html_url'], 'author': c['user']['login'], 'time': c.get('created_at') or c.get('submitted_at'),
           'bodySHA256': sha(c['body'].encode('utf-8'))}
    if kind == 'review':
        red['state'] = c['state']; red['commit_id'] = c['commit_id']
    put('pre/' + fn.replace('.json', '.reduced.json'), (json.dumps(red, indent=1) + '\n').encode('utf-8'), b, {})
for f in sorted(os.listdir(J(RD, 'figures'))):
    if os.path.isfile(J(RD, 'figures', f)):
        b = open(J(RD, 'figures', f), 'rb').read(); put(f'figures/{f}', b, b, {})
for fold, L in rec.items():
    p = os.path.join(DST, *fold.split('/'), 'SANITIZATION.json'); assert not os.path.exists(p)
    json.dump({'schema': 'NewMetacomp.G2.LP2B1S10.Sanitization.v1', 'rule': 'absolute local paths replaced by <repo>, <worktree>, <temp>, <scratch>, <backup>, <home>, <drive>, <matlabroot>; UTF-16 logs converted to UTF-8; MATLAB startup path warnings removed from logs; binaries (.mat, .f64) only in the archive; figures byte for byte (superseded v1 layouts only in the archive)',
               'files': L}, open(p, 'w', encoding='utf-8', newline='\n'), indent=1)
print('published', sum(len(v) for v in rec.values()), 'files into', len(rec), 'folders')
