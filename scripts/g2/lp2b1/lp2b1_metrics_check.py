"""Independent Python (numpy) reconstruction of the saved soft1 S10 failed-mesh quality metrics (zero FEM).
Reads the raw little-endian X3 (float64, N x 2) and T3 (int32, M x 3, one-based) exported by g2_lp2b1_wp0,
verifies their SHA-256 against the WP0 record, recomputes element size h (largest edge), interior angles (law of
cosines here, a third formulation), signed areas, shared edges (numpy unique on sorted node pairs) and every
neighbour ratio max(h1/h2, h2/h1). Compares T3 count, min angle, max ratio, the violation set (> 1.8) and the
threshold counts with the MATLAB records (saved summary and independent MATLAB metrics).
usage: python -I lp2b1_metrics_check.py <wp0Dir> <out.json>"""
import hashlib, json, os, sys
import numpy as np

wd, out = sys.argv[1:3]
W = json.load(open(os.path.join(wd, 'LP2B1_WP0.json'), encoding='utf-8'))
ex = W['exports']


def fsha(p):
    return hashlib.sha256(open(p, 'rb').read()).hexdigest()


px, pt = os.path.join(wd, ex['X3']['file']), os.path.join(wd, ex['T3']['file'])
sha_ok = fsha(px) == ex['X3']['sha256'] and fsha(pt) == ex['T3']['sha256']
X = np.fromfile(px, dtype='<f8').reshape(ex['X3']['rows'], 2)
T = np.fromfile(pt, dtype='<i4').reshape(ex['T3']['rows'], 3).astype(np.int64) - 1
M = T.shape[0]
a, b, c = X[T[:, 0]], X[T[:, 1]], X[T[:, 2]]
lab, lbc, lca = np.linalg.norm(b - a, axis=1), np.linalg.norm(c - b, axis=1), np.linalg.norm(a - c, axis=1)
h = np.maximum(np.maximum(lab, lbc), lca)
cl = lambda z: np.clip(z, -1.0, 1.0)
angA = np.degrees(np.arccos(cl((lab**2 + lca**2 - lbc**2) / (2 * lab * lca))))
angB = np.degrees(np.arccos(cl((lab**2 + lbc**2 - lca**2) / (2 * lab * lbc))))
angC = np.degrees(np.arccos(cl((lbc**2 + lca**2 - lab**2) / (2 * lbc * lca))))
minang = np.minimum(np.minimum(angA, angB), angC)
area2 = (b[:, 0] - a[:, 0]) * (c[:, 1] - a[:, 1]) - (b[:, 1] - a[:, 1]) * (c[:, 0] - a[:, 0])
E = np.vstack([T[:, [0, 1]], T[:, [1, 2]], T[:, [2, 0]]]); E.sort(axis=1)
own = np.concatenate([np.arange(M)] * 3)
uE, inv, cnt = np.unique(E, axis=0, return_inverse=True, return_counts=True)
inv = inv.ravel()
order = np.argsort(inv, kind='stable'); invs = inv[order]; owns = own[order]
first = np.r_[True, invs[1:] != invs[:-1]]
idx = np.flatnonzero(first)
two = cnt[invs[idx]] == 2
i1 = idx[two]; e1 = owns[i1]; e2 = owns[i1 + 1]
ratio = np.maximum(h[e1] / h[e2], h[e2] / h[e1])
viol = np.flatnonzero(ratio > 1.8)
vpairs = sorted([sorted([int(e1[k]) + 1, int(e2[k]) + 1]) for k in viol])
mat = W['independent']; saved = W['saved']['summary']
mviol = sorted([sorted([v['small'], v['large']]) for v in (W['violations'] if isinstance(W['violations'], list) else [W['violations']])])
counts = {k: int((ratio > float(k.replace('above', '').replace('p', '.'))).sum()) for k in mat['ratioCounts']}
R = {'schema': 'NewMetacomp.G2.LP2B1.PythonMetricsCheck.v1', 'exportsSHA256Match': sha_ok,
     'T3': int(M), 'nodes': int(X.shape[0]), 'edges': int(len(uE)), 'interiorEdges': int((cnt == 2).sum()),
     'boundaryEdges': int((cnt == 1).sum()), 'nonmanifoldEdges': int((cnt > 2).sum()),
     'minAngle_deg': float(minang.min()), 'maxNeighborRatio': float(ratio.max()), 'allAreasPositive': bool((area2 > 0).all()),
     'violations': len(viol), 'violationPairs': vpairs, 'ratioCounts': counts,
     'diff_minAngle_vs_savedSummary': float(minang.min() - saved['minAngle_deg']),
     'diff_maxRatio_vs_savedSummary': float(ratio.max() - saved['maxNeighborRatio']),
     'diff_minAngle_vs_matlabIndependent': float(minang.min() - mat['minAngle_deg']),
     'diff_maxRatio_vs_matlabIndependent': float(ratio.max() - mat['maxNeighborRatio'])}
R['checks'] = {'sha': sha_ok, 'T3': M == saved['T3elements'] == mat['T3'],
               'minAngle': abs(R['diff_minAngle_vs_savedSummary']) <= 1e-9 and abs(R['diff_minAngle_vs_matlabIndependent']) <= 1e-9,
               'maxRatio': abs(R['diff_maxRatio_vs_savedSummary']) <= 1e-12 and abs(R['diff_maxRatio_vs_matlabIndependent']) <= 1e-12,
               'violationSet': vpairs == mviol and len(viol) == mat['violations'],
               'counts': counts == mat['ratioCounts'], 'areas': bool((area2 > 0).all()), 'manifold': int((cnt > 2).sum()) == 0}
R['pass'] = all(R['checks'].values())
json.dump(R, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('python check', 'PASS' if R['pass'] else 'FAIL', R['checks'], 'maxRatio %.15g minAngle %.15g violations %d' % (R['maxNeighborRatio'], R['minAngle_deg'], len(viol)))
