"""Independent audit of the LP2-B1 geometry-only records (zero FEM). Reads only saved records and exports.
Checks: preregistration/amendment/pins bytes and commit order (prereg committed before the first alternative mesh,
amendment A1 before attempt 2); attempt-1 records equal the hashes pinned in A1; candidate folders that exist
(no 0.50/0.35 mesh anywhere, since 0.40 was selected); attempt-2 selection, stopping rule, 19/19 checks, arrays SHA,
canonical digests (attempt 1 = attempt 2 = repeat); references at the selected spacing; numpy recomputation of every
exported X3/T3 (max ratio, min angle, violations, threshold counts) against the MATLAB post-audit; WP0 numpy check.
usage: python lp2b1_audit.py <execRepo> <wp0PythonCheck.json> <out.json>"""
import hashlib, json, os, subprocess, sys
from datetime import datetime, timezone
import numpy as np
ex, wp0py, out = sys.argv[1:4]
assert not os.path.exists(out), out + ' exists (audit outputs are never overwritten)'
root = os.path.join(ex, 'outputs', 'g2_lp2b1_geometry_v1')
J = lambda *p: json.load(open(os.path.join(*p), encoding='utf-8'))
fsha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
git = lambda *a: subprocess.run(['git', '-C', ex] + list(a), capture_output=True, text=True).stdout.strip()
prob = []
def need(c, m):
    if not c: prob.append(m)
lp = os.path.join(ex, 'matlab', 'g2', 'lp2b1')
pins, pre, am = (os.path.join(lp, f) for f in ('G2_LP2B1_PINS_v1.json', 'G2_LP2B1_PREREG_v1.json', 'G2_LP2B1_PREREG_AMENDMENT_A1.json'))
P, A1 = J(pre), J(am)
need(P['pinsSHA256'] == fsha(pins), 'prereg pins SHA'); need(A1['amendsSHA256'] == fsha(pre), 'amendment pins prereg')
tc = lambda f: datetime.fromisoformat(git('log', '--diff-filter=A', '--format=%cI', '--', 'matlab/g2/lp2b1/' + f).splitlines()[-1])
ut = lambda s: datetime.strptime(s, '%Y-%m-%dT%H:%M:%S.%fZ').replace(tzinfo=timezone.utc)
a1 = J(root, 'wp1', 'T_soft1_S10_h040', 'ATTEMPT.json'); a2 = J(root, 'wp1_attempt2', 'T_soft1_S10_h040', 'ATTEMPT.json')
need(tc('G2_LP2B1_PREREG_v1.json') < ut(a1['startedUTC']), 'prereg committed before attempt 1')
need(tc('G2_LP2B1_PREREG_AMENDMENT_A1.json') < ut(a2['startedUTC']) and tc('G2_LP2B1_PREREG_AMENDMENT_A1.json') > ut(a1['startedUTC']), 'amendment between attempts')
for k, v in A1['attempt1']['records'].items():
    need(fsha(os.path.join(root, 'wp1', *k.split('/'))) == v, 'attempt-1 record changed: ' + k)
dirs = sorted(os.path.relpath(d, root).replace('\\', '/') for d, _, fs in os.walk(root) if 'ATTEMPT.json' in fs)
expect = ['wp1/T_soft1_S10_h040', 'wp1_attempt2/R_H_S10_h040', 'wp1_attempt2/R_soft1_S9_h040', 'wp1_attempt2/T_soft1_S10_h040', 'wp1_attempt2/T_soft1_S10_h040_REPEAT']
need(dirs == expect, 'attempt folders %s' % dirs)
need(not any(('h050' in d) or ('h035' in d) for d in dirs), 'no 0.50/0.35 mesh exists')
T1, T2, RP, RF = J(root, 'wp1', 'LP2B1_WP1_TARGET.json'), J(root, 'wp1_attempt2', 'LP2B1_WP1_TARGET.json'), J(root, 'wp1_attempt2', 'LP2B1_WP1_REPEAT.json'), J(root, 'wp1_attempt2', 'LP2B1_WP1_REFERENCES.json')
L = lambda x: x if isinstance(x, list) else [x]
need(T1['outcome'] == 'HOLD_NON_QUALITY_FAILURE' and len(L(T1['attempts'])) == 1 and not a1['pass'], 'attempt-1 HOLD record')
t2 = L(T2['attempts'])
need(T2['outcome'] == 'SELECTED' and T2['selected'] == 0.4 and len(t2) == 1 and t2[0]['seedSpacing_mm'] == P['candidateOrder_mm'][0], 'attempt-2 selection = first candidate')
need(T2.get('amendmentA1SHA256') == fsha(am) and T2['preregSHA256'] == fsha(pre), 'attempt-2 stage pins')
res = {}
for d in expect:
    a = J(root, *d.split('/'), 'ATTEMPT.json'); r = {'pass': a['pass'], 'checks': '%d/%d' % (a['checksPassed'], a['checksTotal']), 'seed': a['seedSpacing_mm']}
    r['arraysSHA'] = fsha(os.path.join(root, *d.split('/'), 'ATTEMPT_ARRAYS.mat')) == a['arraysFileSHA256']; need(r['arraysSHA'], 'arrays SHA ' + d)
    r['canonical'] = a['canonicalSHA256']
    if d != 'wp1/T_soft1_S10_h040':
        need(a['pass'] and a['checksPassed'] == 19 and a['checksTotal'] == 19 and all(a['checks'].values()), 'attempt checks ' + d)
        need(a['seedSpacing_mm'] == 0.4 and a['joinGatesPassed'] == 13 and a['pairing']['gatesPassed'] == 10 and a['audit']['meshAudit'] == '34/34' and a['audit']['chordsPerCircle'] == [76, 76, 76], 'gates ' + d)
        need(a['audit']['actualClassification'] == a['audit']['nominalClassification'] == 'MATRIX_ADVANCE' and min(a['audit']['guideRingGap_mm']) >= 1, 'clearance ' + d)
        need(a['independent']['violations'] == 0 and a['independent']['maxNeighborRatio'] <= 1.8 and a['independent']['minAngle_deg'] >= 20 and a['T3'] <= 40000, 'thresholds ' + d)
    res[d] = r
need(res['wp1/T_soft1_S10_h040']['canonical'] == res['wp1_attempt2/T_soft1_S10_h040']['canonical'] == res['wp1_attempt2/T_soft1_S10_h040_REPEAT']['canonical'], 'canonical digests equal (attempt 1, attempt 2, repeat)')
need(RP['outcome'] == 'DETERMINISTIC' and all(RP['determinism']['arraysEqual'].values()) and RP['determinism']['canonicalEqual'] and RP['determinism']['gatesEqual'], 'repeat determinism')
need(RF['outcome'] == 'REFERENCES_PASS' and RF['selected'] == 0.4 and [x['name'] for x in L(RF['attempts'])] == ['R_soft1_S9_h040', 'R_H_S10_h040'], 'references')
PA = J(root, 'postaudit_v1', 'LP2B1_POSTAUDIT.json')
need(all(x['pass'] for x in L(PA['attempts'])), 'post-audit attempts')
diff = [k for k, v in PA['attempt1VsAttempt2'].items() if not v]
need(diff == ['summary'], 'attempt-1 vs attempt-2 differences outside the timing-bearing summary: %s' % diff)
npres = []
for e in L(PA['exports']):
    d = os.path.join(root, 'postaudit_v1')
    sx, st = fsha(os.path.join(d, e['X3'])) == e['X3sha256'], fsha(os.path.join(d, e['T3'])) == e['T3sha256']
    X = np.fromfile(os.path.join(d, e['X3']), '<f8').reshape(e['rows'][0], 2); T = np.fromfile(os.path.join(d, e['T3']), '<i4').reshape(e['rows'][1], 3).astype(np.int64) - 1
    a, b, c = X[T[:, 0]], X[T[:, 1]], X[T[:, 2]]
    l = np.stack([np.linalg.norm(b - a, axis=1), np.linalg.norm(c - b, axis=1), np.linalg.norm(a - c, axis=1)], 1); h = l.max(1)
    cosang = lambda u, v: np.degrees(np.arccos(np.clip((u * v).sum(1) / np.linalg.norm(u, axis=1) / np.linalg.norm(v, axis=1), -1, 1)))
    ang = np.minimum(np.minimum(cosang(b - a, c - a), cosang(c - b, a - b)), cosang(a - c, b - c))
    E = np.sort(np.vstack([T[:, [0, 1]], T[:, [1, 2]], T[:, [2, 0]]]), 1); own = np.tile(np.arange(len(T)), 3)
    o = np.lexsort((E[:, 1], E[:, 0])); Es, ow = E[o], own[o]; same = np.all(Es[1:] == Es[:-1], 1)
    i = np.flatnonzero(same); r = np.maximum(h[ow[i]] / h[ow[i + 1]], h[ow[i + 1]] / h[ow[i]])
    cnt = {k: int((r > float(k.replace('above', '').replace('p', '.'))).sum()) for k in e['ratioCounts']}
    q = {'attempt': e['attempt'], 'shaOK': sx and st, 'maxRatio': float(r.max()), 'minAngle_deg': float(ang.min()), 'violations': int((r > 1.8).sum()),
         'dMaxRatio': float(r.max() - e['maxNeighborRatio']), 'dMinAngle': float(ang.min() - e['minAngle_deg']), 'countsEqual': cnt == e['ratioCounts']}
    q['pass'] = q['shaOK'] and abs(q['dMaxRatio']) <= 1e-12 and abs(q['dMinAngle']) <= 1e-9 and q['violations'] == e['violations'] and q['countsEqual']
    need(q['pass'], 'numpy ' + e['attempt']); npres.append(q)
W = J(wp0py); need(W['pass'], 'WP0 numpy check')
R = {'schema': 'NewMetacomp.G2.LP2B1.IndependentAudit.v1', 'physicalSolves': 0, 'attemptFolders': dirs, 'attempts': res, 'numpy': npres,
     'attempt1VsAttempt2Differences': diff, 'wp0NumpyPass': W['pass'], 'problems': prob, 'pass': not prob}
json.dump(R, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('audit', 'PASS' if not prob else 'FAIL', len(prob), 'problems', prob)
