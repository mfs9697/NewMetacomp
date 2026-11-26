"""Independent hashcheck of the LP2-B1-EQ readiness pins (Python only; reads files; writes one JSON).
Recomputes, without MATLAB: the policy SHA-256; every file pin of the policy; the g2, lp2, lp2a2, lp2a3, lp2b1, lp2b1eq
and WP5-closure source digests (sorted "name sha256" lines, newline-joined, SHA-256; g2 with relative paths incl.
vendor_p010_a14d8872); the reference and qualification manifest digests and the full token string exactly as
g2_lp2b1eq_context builds them; the canonical array digests of the qualification (and optional replay) arrays from raw
little-endian exports (int64 shape bytes, then float64 column-major data bytes, nine arrays in the fixed order); the
two LP2-B1 archive copies; absence of the GO file and of the run/receipt roots; the token, policy and source digest
recorded in the zero-FEM test evidence.
usage: python lp2b1eq_hashcheck.py <execRepo> <testsJson> <exportDir> <out.json>"""
import hashlib, json, os, sys
R, tj, xd, out = sys.argv[1:5]


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


P = lambda rel: os.path.join(R, *rel.split('/'))
sha = lambda rel: fsha(P(rel))
d1 = lambda s: hashlib.sha256(s.encode('utf-8')).hexdigest()


def folder(rel):
    d = P(rel); return d1('\n'.join(f'{n} {fsha(os.path.join(d, n))}' for n in sorted(x for x in os.listdir(d) if x.endswith('.m'))))


def g2digest():
    d = P('matlab/g2'); L = [(n, os.path.join(d, n)) for n in os.listdir(d) if n.endswith('.m')]
    v = os.path.join(d, 'vendor_p010_a14d8872'); L += [('vendor_p010_a14d8872/' + n, os.path.join(v, n)) for n in os.listdir(v) if n.endswith('.m')]
    return d1('\n'.join(f'{r} {fsha(p)}' for r, p in sorted(L)))


polf = 'matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json'; pol = json.load(open(P(polf), encoding='utf-8')); ps = sha(polf)
c = {}; detail = {}
pins = []


def walk(x):
    if isinstance(x, dict):
        if isinstance(x.get('path'), str) and isinstance(x.get('sha256'), str):
            pins.append((x['path'], x['sha256'].lower()))
        for v in x.values():
            walk(v)
    elif isinstance(x, list):
        for v in x:
            walk(v)


walk(pol)
bad = [p for p, h in pins if not os.path.isfile(P(p)) or sha(p) != h]
c['allPolicyFilePins'] = not bad and len(pins) > 60; detail['filePins'] = len(pins); detail['filePinsBad'] = bad
src = {'g2SourceSHA256': g2digest(), 'lp2SourceSHA256': folder('matlab/g2/lp2'), 'lp2a2SourceSHA256': folder('matlab/g2/lp2a2'),
       'lp2a3SourceSHA256': folder('matlab/g2/lp2a3'), 'lp2b1SourceSHA256': folder('matlab/g2/lp2b1'), 'lp2b1eqSourceSHA256': folder('matlab/g2/lp2b1eq'),
       'closureSourceSHA256': folder('scripts/g2/lp2a2/closure')}
c['sourceDigests'] = all(src[k] == pol['sourcePins'][k].lower() for k in src); detail['sourceDigests'] = src
a3 = json.load(open(P('matlab/g2/lp2a3/G2_LP2A3_POLICY_v1.json'), encoding='utf-8'))['sourcePins']
c['inheritedDigestsEqualLP2A3'] = all(a3[k] == pol['sourcePins'][k] for k in ('g2SourceSHA256', 'lp2SourceSHA256', 'lp2a2SourceSHA256', 'lp2a3SourceSHA256'))
# ---- manifests and token, exactly as g2_lp2b1eq_context
L = lambda p: f"{p['path']} {p['sha256']}"
rl, ql = [], []
for s in pol['solves']:
    a = s['archived']
    for k in ('STATE', 'PHASE', 'SOLUTION', 'ADMIT'):
        rl += [L(a[k]['record']), L(a[k]['manifest'])]
    rl.append(L(a['MESH']))
    p = s['parent']
    if 'record' in p['STATE']:
        rl += [L(p['STATE']['record']), L(p['STATE']['manifest']), L(p['ADMIT']['record']), L(p['ADMIT']['manifest'])]
    else:
        rl.append(L(p['STATE']))
    n = s['nextPredictor']
    if 'TERMINAL' in n:
        rl += [L(n['TERMINAL']['record']), L(n['TERMINAL']['manifest']), L(n['FAILED_MESH'])]
    else:
        rl += [L(n['STATE']['record']), L(n['STATE']['manifest']), L(n['ADMIT']['record']), L(n['ADMIT']['manifest'])]
    rl.append('%s nextTip %s %.17g %.17g' % (s['id'], n['state'], n['tip_mm'][0], n['tip_mm'][1]))
    q = s['qualification']; ql += [L(q['arrays']), L(q['attemptJson']), f"{s['id']} canonical {q['canonicalSHA256']}"]
ql += [L(r) for r in pol['qualificationEvidence']['records']] + [L(r) for r in pol['qualificationEvidence']['evidenceFiles']]
ql.append('b1archive ' + pol['qualificationEvidence']['b1ArchiveSHA256'])
rman = d1('\n'.join(sorted(rl))); qman = d1('\n'.join(sorted(ql))); au = pol['authorization']; sp = pol['sourcePins']
tok = ('G2LP2B1EQ|policy=%s|g2source=%s|lp2source=%s|lp2a2source=%s|lp2a3source=%s|lp2b1source=%s|lp2b1eqsource=%s|closure=%s|references=%s|qualification=%s|'
       'solves=EQB-soft1-S9,EQB-H-S10|limit=2|seed=0.40|campaign=%s|run=%s') % (ps, sp['g2SourceSHA256'].lower(), sp['lp2SourceSHA256'].lower(), sp['lp2a2SourceSHA256'].lower(),
       sp['lp2a3SourceSHA256'].lower(), src['lp2b1SourceSHA256'], src['lp2b1eqSourceSHA256'], src['closureSourceSHA256'], rman, qman, au['campaignId'], au['runName'])
T = json.load(open(tj, encoding='utf-8'))
c['tokenReconstructedEqualsTests'] = tok == T['token']; c['testsPolicyAndSource'] = T['policySHA256'] == ps and T['lp2b1eqSourceSHA256'] == src['lp2b1eqSourceSHA256']
c['testsAllPassedZeroFEM'] = T['passed'] == T['total'] and T['physicalSolves'] == 0
detail.update(referenceManifestSHA256=rman, qualificationManifestSHA256=qman, token=tok, testsPassed=f"{T['passed']}/{T['total']}")
# ---- canonical digests from raw exports
X = json.load(open(os.path.join(xd, 'EXPORT_INDEX.json'), encoding='utf-8')); can = {}
for e in X['sets']:
    h = hashlib.sha256()
    for a in e['arrays']:
        b = open(os.path.join(xd, a['file']), 'rb').read(); assert len(b) == 8 * a['numel'], a
        h.update(b''.join(int(v).to_bytes(8, 'little', signed=True) for v in a['size'])); h.update(b)
    can[e['name']] = {'recomputed': h.hexdigest(), 'expected': e['expectedCanonicalSHA256'], 'sourceFileSHA256': e['sourceFileSHA256'],
                      'sourceFileNow': sha(e['source']) if e['source'].startswith('outputs/') else None}
c['canonicalFromRawExports'] = all(v['recomputed'] == v['expected'] for v in can.values()) and len(can) >= 2
q = {s['id']: s['qualification'] for s in pol['solves']}
c['qualificationCanonicalPins'] = all(can.get('Q_' + k, {}).get('recomputed') == v['canonicalSHA256'] and can['Q_' + k]['sourceFileSHA256'] == v['arrays']['sha256'] for k, v in q.items())
detail['canonical'] = can
# ---- archives, GO and roots
B1 = pol['qualificationEvidence']['b1ArchiveSHA256']; nm = pol['qualificationEvidence']['b1ArchiveName']
cp = {t: (fsha(os.path.join(d, nm)) if os.path.isfile(os.path.join(d, nm)) else None) for t, d in (('local', r'C:\Users\Mikhailo\Documents\NewMetacomp_LP1_archive_backup'), ('offDevice', 'D:\\'))}
c['b1ArchiveBothCopies'] = all(v == B1 for v in cp.values()); detail['b1ArchiveCopies'] = cp
c['noGoNoRoots'] = not os.path.exists(P(au['goPath'])) and not os.path.exists(P(au['runRoot'])) and not os.path.exists(P(au['receiptRoot']))
c['policyNotAuthorized'] = pol['status'] == 'PROPOSED_NOT_AUTHORIZED' and au['goPresent'] is False
CON = json.load(open(P('docs/research/G2_LP2B1_evidence/wp2/G2_LP2B1_EQ_CONTRACT_DRAFT_v1.json'), encoding='utf-8'))
c['nextTipsEqualContract'] = all(pol['solves'][i]['nextPredictor']['tip_mm'] == CON['solves'][i]['nextPredictor']['archivedNextTip_mm'] for i in range(2))
res = {'schema': 'NewMetacomp.G2.LP2B1EQ.Hashcheck.v1', 'policySHA256': ps, 'checks': c, 'pass': all(c.values()), 'detail': detail}
assert not os.path.exists(out), out
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('hashcheck', sum(c.values()), '/', len(c), 'PASS' if res['pass'] else 'FAIL', [k for k, v in c.items() if not v])
