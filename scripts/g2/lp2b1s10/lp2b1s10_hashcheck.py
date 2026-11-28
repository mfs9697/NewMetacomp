"""Independent hashcheck of the LP2-B1-S10 readiness pins (Python only; reads files; writes one JSON). Backup locations are arguments.
Recomputes, without MATLAB: the policy SHA-256; every file pin of the policy; the g2, lp2, lp2a2, lp2a3, lp2b1, lp2b1eq, closure and
lp2b1s10 source digests; the parent, qualification and LP2-B1-EQ evidence manifest digests and the full token string exactly as
g2_lp2b1s10_context builds them; the canonical digest of the qualification and the geometry-replay arrays from raw little-endian
exports; four archives on both devices (LP2-A3 records, LP2-B1 geometry, LP2-B1-EQ readiness and campaign); absence of the GO,
run/receipt roots and summary; the token, policy and source digest recorded in the zero-FEM tests, the target qualification and
the geometry replay.
usage: python lp2b1s10_hashcheck.py <execRepo> <testsJson> <wp0Json> <replayJson> <exportDir> <localBackupDir> <offDeviceDir> <out.json>"""
import hashlib, json, os, sys
R, tj, wj, rj, xd, BK, OFF, out = sys.argv[1:9]


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


polf = 'matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json'; pol = json.load(open(P(polf), encoding='utf-8')); ps = sha(polf)
c = {}; detail = {}; pins = []


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
c['allPolicyFilePins'] = not bad and len(pins) >= 55; detail['filePins'] = len(pins); detail['filePinsBad'] = bad
src = {'g2SourceSHA256': g2digest(), 'lp2SourceSHA256': folder('matlab/g2/lp2'), 'lp2a2SourceSHA256': folder('matlab/g2/lp2a2'),
       'lp2a3SourceSHA256': folder('matlab/g2/lp2a3'), 'lp2b1SourceSHA256': folder('matlab/g2/lp2b1'), 'lp2b1eqSourceSHA256': folder('matlab/g2/lp2b1eq'),
       'closureSourceSHA256': folder('scripts/g2/lp2a2/closure'), 'lp2b1s10SourceSHA256': folder('matlab/g2/lp2b1s10')}
sp = pol['sourcePins']
c['sourceDigests'] = all(src[k] == sp[k].lower() for k in src); detail['sourceDigests'] = src
a3 = json.load(open(P('matlab/g2/lp2a3/G2_LP2A3_POLICY_v1.json'), encoding='utf-8'))
c['inheritedDigestsEqualLP2A3'] = all(a3['sourcePins'][k] == sp[k] for k in ('g2SourceSHA256', 'lp2SourceSHA256', 'lp2a2SourceSHA256', 'lp2a3SourceSHA256'))
c['lp2b1eqDigestAccepted'] = src['lp2b1eqSourceSHA256'] == '74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f'
# ---- manifests and token, exactly as g2_lp2b1s10_context
L = lambda x: f"{x['path']} {x['sha256']}"
p = pol['parent']; fa = pol['failedA3S10']; q = pol['qualification']; e = pol['b1eqEvidence']; tg = pol['target']
pl = []
for k in ('STATE', 'PHASE', 'SOLUTION', 'ADMIT', 'RECEIPT'):
    pl += [L(p[k]['record']), L(p[k]['manifest'])]
pl.append(L(p['MESH'])); pl.append('grandparentS8 ' + p['grandparentS8']['sha256'])
for k in ('TERMINAL', 'HOLD', 'ADMIT'):
    pl += [L(fa[k]['record']), L(fa[k]['manifest'])]
pl.append(L(fa['FAILED_MESH'])); pl.append('expectedTip %.17g %.17g' % tuple(tg['expectedTip_mm']))
ql = [L(q[k]) for k in ('arrays', 'attemptJson', 'repeatArrays', 'repeatJson', 'wp1Target', 'wp1Repeat', 'b1ArchiveRecord')]
ql += ['canonical ' + q['canonicalSHA256'], 'b1archive ' + q['b1ArchiveSHA256'], 'expected T3=%d minAngle=%.17g maxRatio=%.17g' % (q['T3'], q['minAngle_deg'], q['maxNeighborRatio'])]
el = [L(e['archiveRecord']), L(e['policy']), L(e['independentAudit']), 'b1eqarchive ' + e['archiveSHA256']] + [L(x) for x in e['outputs']]
pman = d1('\n'.join(sorted(pl))); qman = d1('\n'.join(sorted(ql))); eman = d1('\n'.join(sorted(el))); au = pol['authorization']
c['a3S8GrandparentPin'] = p['grandparentS8']['sha256'] == a3['parents']['S8']['soft1']['STATE']
tok = ('G2LP2B1S10|policy=%s|g2source=%s|lp2source=%s|lp2a2source=%s|lp2a3source=%s|lp2b1source=%s|lp2b1eqsource=%s|closure=%s|lp2b1s10source=%s|'
       'parent=%s|qualification=%s|eqcampaign=%s|case=soft1|state=S10|admissions=1|seed=0.40|campaign=%s|run=%s') % (
       ps, sp['g2SourceSHA256'].lower(), sp['lp2SourceSHA256'].lower(), sp['lp2a2SourceSHA256'].lower(), sp['lp2a3SourceSHA256'].lower(),
       src['lp2b1SourceSHA256'], src['lp2b1eqSourceSHA256'], src['closureSourceSHA256'], src['lp2b1s10SourceSHA256'], pman, qman, eman, au['campaignId'], au['runName'])
T = json.load(open(tj, encoding='utf-8')); W = json.load(open(wj, encoding='utf-8')); G = json.load(open(rj, encoding='utf-8'))
c['tokenReconstructedEqualsTestsWp0Replay'] = tok == T['token'] == W['token'] == G['token']
c['testsPolicyAndSource'] = T['policySHA256'] == ps == W['policySHA256'] and T['lp2b1s10SourceSHA256'] == src['lp2b1s10SourceSHA256'] == W['lp2b1s10SourceSHA256']
c['testsAllPassedZeroFEM'] = T['passed'] == T['total'] and T['physicalSolves'] == 0 and T['total'] >= 40
c['targetQualificationPass'] = W['target']['pass'] is True and W['physicalSolves'] == 0 and W['rootsAbsent'] is True
g = G['geometry']
c['geometryReplayPass'] = (G['stage'] == 'GEOMETRY_REPLAY_NO_SOLVE' and g['pass'] is True and g['canonicalSHA256'] == q['canonicalSHA256'] and g['T3'] == 30357
                           and g['minAngle_deg'] == q['minAngle_deg'] and g['maxNeighborRatio'] == q['maxNeighborRatio'] and g['chordsPerCircle'] == [76, 76, 76]
                           and g['actualClassification'] == 'MATRIX_ADVANCE' and min(g['guideRingGap_mm']) >= 1 and G['solveCalls'] == 0)
detail.update(parentManifestSHA256=pman, qualificationManifestSHA256=qman, eqEvidenceManifestSHA256=eman, token=tok, testsPassed=f"{T['passed']}/{T['total']}")
# ---- canonical digests from raw exports
X = json.load(open(os.path.join(xd, 'EXPORT_INDEX.json'), encoding='utf-8')); can = {}
for s in X['sets']:
    h = hashlib.sha256()
    for a in s['arrays']:
        b = open(os.path.join(xd, a['file']), 'rb').read(); assert len(b) == 8 * a['numel'], a
        h.update(b''.join(int(v).to_bytes(8, 'little', signed=True) for v in a['size'])); h.update(b)
    can[s['name']] = {'recomputed': h.hexdigest(), 'expected': s['expectedCanonicalSHA256'], 'sourceFileSHA256': s['sourceFileSHA256']}
c['canonicalFromRawExports'] = len(can) == 2 and all(v['recomputed'] == q['canonicalSHA256'] == v['expected'] for v in can.values())
c['qualificationArraysFileEqualsPin'] = can['Q_soft1_S10']['sourceFileSHA256'] == q['arrays']['sha256']
detail['canonical'] = can
# ---- archives, GO and roots
AR = {'NewMetacomp_G2_LP2A3_Records_20261126.zip': 'e089d749737f6c52', 'NewMetacomp_G2_LP2B1_Geometry_20261126.zip': q['b1ArchiveSHA256'],
      'NewMetacomp_G2_LP2B1EQ_Readiness_20261126.zip': '2187ec2cbb36fb7d1e8fb311ef41fa918e9822a6277f3a6d98dbcf97e6867c24', e['archiveName']: e['archiveSHA256']}
cp = {}
for nm, h in AR.items():
    cp[nm] = {t: (fsha(os.path.join(d, nm)) if os.path.isfile(os.path.join(d, nm)) else None) for t, d in (('local', BK), ('offDevice', OFF))}
c['archivesBothCopies'] = all(all(v is not None and v.startswith(AR[nm]) for v in cp[nm].values()) for nm in AR); detail['archiveCopies'] = cp
c['noGoNoRootsNoSummary'] = not any(os.path.exists(P(x)) for x in (au['goPath'], au['runRoot'], au['receiptRoot'], au['summaryPath']))
c['policyNotAuthorized'] = pol['status'] == 'PROPOSED_NOT_AUTHORIZED' and au['goPresent'] is False
res = {'schema': 'NewMetacomp.G2.LP2B1S10.Hashcheck.v1', 'policySHA256': ps, 'checks': c, 'detail': detail, 'pass': all(c.values()), 'failed': [k for k, v in c.items() if not v]}
assert not os.path.exists(out), out
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('hashcheck', sum(c.values()), '/', len(c), 'PASS' if res['pass'] else 'FAIL', res['failed'])
