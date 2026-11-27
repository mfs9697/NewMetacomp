"""Independent read-only audit of campaign G2-LP2B1-EQ-001 (Python + numpy only; no MATLAB function is reused).
Inputs: the execution clone (records, policy, sources, git), the MATLAB closure dump (record scalars) and the raw
little-endian float64 exports of the new and archived arrays. Everything numerical is RE-IMPLEMENTED here:
canonical digests, bank stations and jumps (C8), near-tip matching, interpolation, MTS root (different algebraic
form), next-tip recurrence, phase labels -> active area, G, C1-C11 metrics and flags against the policy thresholds.
Any discrepancy is a problem (=> HOLD, not accepted equivalence).
usage: python b1eq_audit.py <execRepo> <runDir(scratch lp2b1eqrun)> <out.json>"""
import hashlib, json, math, os, re, subprocess, sys
import numpy as np

EX, RD, OUT = sys.argv[1:4]
AUTH_HEAD = '7d0df53f35b30c4e33734c40fdda33e987ea96ee'
GO_HEAD = '3269d125825dcc403ea9ab975fb5ab55d9a003e8'
REV_HEAD = 'd8906ce669fe6d7e52f6fd773c4fbdbf65fa7447'
GO_PATH = 'matlab/g2/lp2b1eq/G2_LP2B1EQ_GO.json'
URL = 'https://github.com/mfs9697/NewMetacomp/pull/79#issuecomment-7211904299'
IDS = ['EQB-soft1-S9', 'EQB-H-S10']
problems, checks, detail = [], {}, {}


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def chk(name, ok, info=None):
    checks[name] = bool(ok)
    if info is not None:
        detail[name] = info
    if not ok:
        problems.append(name)
    return ok


P = lambda rel: os.path.join(EX, *rel.split('/'))
git = lambda *a: subprocess.run(['git', '-C', EX] + list(a), capture_output=True).stdout
pol = json.load(open(P('matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json'), encoding='utf-8'))
tol = pol['tolerances']
au = pol['authorization']
dump = json.load(open(os.path.join(RD, 'verify', 'LP2B1EQ_RECORD_DUMP.json'), encoding='utf-8'))
IX = {x['file'][:-4]: x for x in json.load(open(os.path.join(RD, 'verify', 'raw', 'RAW_INDEX.json'), encoding='utf-8'))}


def raw(name):
    x = IX[name]
    a = np.fromfile(os.path.join(RD, 'verify', 'raw', x['file']), dtype='<f8')
    shp = [int(s) for s in x['shape']]
    assert a.size == int(np.prod(shp)), name
    return a.reshape(shp, order='F')


# ------------------------------------------------------------------ 1 exact run / receipt / summary sets
runRoot, recRoot = P(au['runRoot']), P(au['receiptRoot'])
expect = ['COMPARISON.json', 'COMPARISON.mat', 'COMPARISON.mat.manifest.json', 'GEOMETRY_h040/ATTEMPT.json',
          'GEOMETRY_h040/ATTEMPT_ARRAYS.mat', 'MESH.mat', 'PHASE.mat', 'PHASE.mat.manifest.json', 'SOLUTION.mat', 'SOLUTION.mat.manifest.json']
found = {}
for root, _, fs in os.walk(P('outputs/g2_lp2b1_eq_v1')):
    for f in fs:
        found[os.path.relpath(os.path.join(root, f), P('outputs/g2_lp2b1_eq_v1')).replace('\\', '/')] = fsha(os.path.join(root, f))
want = sorted(f'run_lp2b1_eq_v1/{s}/{e}' for s in IDS for e in expect)
chk('runSetExact', sorted(found) == want, {'files': len(found), 'unexpected': sorted(set(found) - set(want)), 'missing': sorted(set(want) - set(found))})
recf = {}
for root, _, fs in os.walk(P('outputs/g2_lp2b1_eq_receipts')):
    for f in fs:
        recf[os.path.relpath(os.path.join(root, f), P('outputs/g2_lp2b1_eq_receipts')).replace('\\', '/')] = fsha(os.path.join(root, f))
chk('receiptSetExact', sorted(recf) == ['G2-LP2B1-EQ-001/RECEIPT.mat', 'G2-LP2B1-EQ-001/RECEIPT.mat.manifest.json'], sorted(recf))
chk('noHoldFiles', not any('HOLD' in k for k in found))
_dr = dump['files']['run']
dumpFiles = {x['path']: x['sha256'] for x in _dr} if isinstance(_dr, list) else {p: h for p, h in zip(_dr['path'], _dr['sha256'])}
chk('dumpRunHashesEqualAudit', {('outputs/g2_lp2b1_eq_v1/' + k): v for k, v in found.items()} == dumpFiles)
# manifests name the file SHA-256
man = {}
for k in [k for k in found if k.endswith('.manifest.json')] + []:
    m = json.load(open(os.path.join(P('outputs/g2_lp2b1_eq_v1'), *k.split('/')), encoding='utf-8'))
    rec = k[:-len('.manifest.json')]
    man[k] = m['SHA256'].lower() == found[rec]
mr = json.load(open(os.path.join(recRoot, 'RECEIPT.mat.manifest.json'), encoding='utf-8'))
man['RECEIPT'] = mr['SHA256'].lower() == recf['G2-LP2B1-EQ-001/RECEIPT.mat']
chk('manifestsMatchFiles', all(man.values()), man)
summ = P('outputs/LP2B1EQ_CAMPAIGN.json')
summOut = os.path.join(RD, 'campaign', 'LP2B1EQ_CAMPAIGN.json')
S = json.load(open(summ, encoding='utf-8'))
chk('summaryCopiesIdentical', fsha(summ) == fsha(summOut), fsha(summ))
chk('summaryOutcome', S['outcome'] == 'EQUIVALENT_AT_0p40' and S['solvesCalled'] == 2 and S['reason'] == '' and S['verification']['outcome'] == 'VERIFIED_EQUIVALENT'
    and S['campaign']['outcome'] == 'EQUIVALENT_AT_0p40' and S['campaign']['holdKind'] == '' and S['campaign']['stoppedAt'] == '',
    {'outcome': S['outcome'], 'solvesCalled': S['solvesCalled'], 'verify': S['verification']['outcome'], 'wall_s': S['wallSeconds']})
pc = S['precheck']
chk('precheck', pc['tokenEqualsContext'] is True and pc['engines'] == 1 and pc['release'] == '2023a' and pc['memgate']['pass'] is True
    and pc['parentCheck']['pass'] is True and pc['parentCheck']['head'] == GO_HEAD and pc['parentCheck']['parent'] == AUTH_HEAD
    and pc['parentCheck']['changedFiles'] in ([GO_PATH], GO_PATH) and list(pc['parentCheck']['statuses']) == [0, 0, 0],
    {'memgateFreeGiB': pc['memgate']['freeGiB'], 'parent': pc['parentCheck']['parent'], 'head': pc['parentCheck']['head']})
pre = json.load(open(os.path.join(RD, 'campaign', 'LP2B1EQ_PRECHECK.json'), encoding='utf-8'))
chk('precheckFileEqualsSummary', pre['tokenEqualsContext'] is True and pre['parentCheck']['head'] == GO_HEAD)

# ------------------------------------------------------------------ 2 activation links and hashes
goBytes = subprocess.run(['git', '-C', EX, 'show', f'{GO_HEAD}:{GO_PATH}'], capture_output=True).stdout
goSha = hashlib.sha256(goBytes).hexdigest()
GO = json.loads(goBytes.decode('utf-8'))
authRec = json.load(open(os.path.join(RD, 'pre', 'AUTH_ACTIVATION_RECORD.json'), encoding='utf-8'))
authRec['decisionUrl'] = URL
chk('goEqualsAuthorizationRecord', GO == authRec and GO['decisionUrl'] == URL and GO['approvedHead'] == AUTH_HEAD)
ph = git('rev-parse', f'{GO_HEAD}~1').decode().strip()
names = git('diff', '--name-only', AUTH_HEAD, GO_HEAD).decode().split()
revn = git('diff', '--name-only', GO_HEAD, REV_HEAD).decode().split()
treeEq = git('rev-parse', f'{REV_HEAD}^{{tree}}').strip() == git('rev-parse', f'{AUTH_HEAD}^{{tree}}').strip()
chk('activationCommit', ph == AUTH_HEAD and names == [GO_PATH], {'parent': ph, 'changed': names})
chk('revocationCommit', git('rev-parse', f'{REV_HEAD}~1').decode().strip() == GO_HEAD and revn == [GO_PATH] and treeEq
    and git('rev-parse', 'HEAD').decode().strip() == REV_HEAD and not os.path.exists(P(GO_PATH)), {'treeEqualsApproved': treeEq})
tok = GO['token']
polSha = fsha(P('matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json'))
d1 = lambda s: hashlib.sha256(s.encode()).hexdigest()
eqd = d1('\n'.join(f'{n} {fsha(os.path.join(P("matlab/g2/lp2b1eq"), n))}' for n in sorted(x for x in os.listdir(P('matlab/g2/lp2b1eq')) if x.endswith('.m'))))
chk('tokenComponents', f'policy={polSha}' in tok and f'lp2b1eqsource={eqd}' in tok, {'policy': polSha, 'lp2b1eqsource': eqd})
R = dump['receipt']['record']
chk('receiptLinks', dump['receipt']['manifestOK'] is True and R['token'] == tok and R['approvedHead'] == AUTH_HEAD and R['activationHead'] == GO_HEAD
    and R['goFileSHA256'] == goSha and R['campaignId'] == 'G2-LP2B1-EQ-001' and R['runName'] == 'run_lp2b1_eq_v1' and R['sourceCommit'] == GO_HEAD,
    {'openedUTC': R['openedUTC'], 'goFileSHA256': goSha})
detail['goFileSHA256'] = goSha

# ------------------------------------------------------------------ helpers (independent numerics)
E_MPa = tol['E_MPa']


def mts_classical(KI, KII):
    # classical closed form theta = 2 atan[(KI - sqrt(KI^2 + 8 KII^2)) / (4 KII)]  (cancellation ~ eps/(4 (KII/KI)^2))
    return 2.0 * math.atan((KI - math.sqrt(KI * KI + 8.0 * KII * KII)) / (4.0 * KII))


def mts(KI, KII):
    # cancellation-free rationalization of the classical form: (KI - r)/(4 KII) = -2 KII/(KI + r), r = sqrt(KI^2 + 8 KII^2)
    th = 2.0 * math.atan(-2.0 * KII / (KI + math.sqrt(KI * KI + 8.0 * KII * KII)))
    st = KI * math.sin(th) + KII * (3 * math.cos(th) - 1)
    hoop = math.cos(th / 2) * (KI * math.cos(th / 2) ** 2 - 1.5 * KII * math.sin(th))
    h = 1e-6
    f = lambda x: math.cos(x / 2) * (KI * math.cos(x / 2) ** 2 - 1.5 * KII * math.sin(x))
    d2 = (f(th + h) - 2 * f(th) + f(th - h)) / h / h
    return th, abs(st) / math.hypot(KI, KII), hoop > 0 and d2 < 0


def canon(arrs):
    h = hashlib.sha256()
    for a in arrs:
        h.update(np.asarray(a.shape, dtype='<i8').tobytes())
        h.update(np.asarray(a, dtype='<f8').flatten(order='F').tobytes())
    return h.hexdigest()


def stations(X, Pl):
    tt = np.diff(Pl, axis=0); L = np.linalg.norm(tt, axis=1); tt = tt / L[:, None]; Sv = np.concatenate([[0], np.cumsum(L)])
    dk = np.empty((len(X), len(L))); lk = np.empty_like(dk)
    for q in range(len(L)):
        l = np.clip((X - Pl[q]) @ tt[q], 0, L[q]); dk[:, q] = np.linalg.norm(X - (Pl[q] + l[:, None] * tt[q]), axis=1); lk[:, q] = l
    k = np.argmin(dk, axis=1)
    return Sv[k] + lk[np.arange(len(X)), k], k


def banks(X, up, lo, Pl):
    up = up.astype(int).ravel() - 1; lo = lo.astype(int).ravel() - 1
    s, k = stations(X[up], Pl); o = np.argsort(s, kind='stable'); up, s, k = up[o], s[o], k[o]
    sl, _ = stations(X[lo], Pl); lo = lo[np.argsort(sl, kind='stable')]
    pair = float(np.max(np.linalg.norm(X[up] - X[lo], axis=1)))
    shared = sorted(set(up.tolist()) & set(lo.tolist()))
    return dict(s=s, up=up, lo=lo, k=k, pair=pair, shared=shared, uniqueStations=len(np.unique(s)) == len(s),
                uniqueIds=len(set(up.tolist())) == len(up) and len(set(lo.tolist())) == len(lo))


def jumps(B, u, Pl):
    U = u.reshape(-1, 2); J = U[B['up']] - U[B['lo']]; j = np.linalg.norm(J, axis=1)
    tt = np.diff(Pl, axis=0); tt = tt / np.linalg.norm(tt, axis=1)[:, None]; nn = np.stack([-tt[:, 1], tt[:, 0]], 1)
    return j, np.sum(J * nn[B['k']], axis=1)


def tri_area(X, T):
    a, b, c = X[T[:, 0]], X[T[:, 1]], X[T[:, 2]]
    return 0.5 * ((b[:, 0] - a[:, 0]) * (c[:, 1] - a[:, 1]) - (c[:, 0] - a[:, 0]) * (b[:, 1] - a[:, 1]))


AUTH_TOK = tok
results = {}
for s in pol['solves']:
    sid = s['id']; fn = sid.replace('-', '_'); E = dump['solves'][fn]; Cj = json.load(open(os.path.join(runRoot, sid, 'COMPARISON.json'), encoding='utf-8'))
    r = {}; pfx = sid + ':'
    so, phs = E['solution'], E['phase']
    # ---------------- record links
    f = lambda n: found[f'run_lp2b1_eq_v1/{sid}/{n}']
    chk(pfx + 'recordLinks', E['solutionManifestOK'] and E['phaseManifestOK'] and E['comparisonManifestOK']
        and so['meshSHA256'].lower() == f('MESH.mat') == phs['meshSHA256'].lower() == Cj['meshSHA256'].lower() == E['meshFileSHA256'].lower()
        and so['phaseSHA256'].lower() == f('PHASE.mat') == Cj['phaseSHA256'].lower() and Cj['solutionSHA256'].lower() == f('SOLUTION.mat')
        and E['solutionSHA256'].lower() == f('SOLUTION.mat') and E['phaseSHA256'].lower() == f('PHASE.mat')
        and Cj['comparisonRecordSHA256'].lower() == f('COMPARISON.mat') and E['comparisonSHA256'].lower() == f('COMPARISON.mat')
        and so['archivedSolutionSHA256'].lower() == s['archived']['SOLUTION']['record']['sha256'] == Cj['archivedSolutionSHA256'].lower())
    chk(pfx + 'activationLinks', so['token'] == phs['token'] == Cj['token'] == AUTH_TOK and so['approvedHead'] == AUTH_HEAD and so['activationHead'] == GO_HEAD
        and so['goFileSHA256'] == goSha and so['policySHA256'] == polSha and so['lp2b1eqSourceSHA256'] == eqd)
    chk(pfx + 'identity', so['solveId'] == phs['solveId'] == Cj['solveId'] == sid and so['caseId'] == phs['caseId'] == s['caseId']
        and so['stateIndex'] == phs['stateIndex'] == s['stateIndex'] and list(phs['mask']) == list(s['mask']))
    # ---------------- archived references re-hashed from disk
    a = s['archived']
    chk(pfx + 'archivedPins', all(fsha(P(a[k]['record']['path'])) == a[k]['record']['sha256'] for k in ('STATE', 'SOLUTION', 'PHASE', 'ADMIT'))
        and fsha(P(a['MESH']['path'])) == a['MESH']['sha256'] and fsha(P(s['qualification']['arrays']['path'])) == s['qualification']['arrays']['sha256'])
    # ---------------- geometry: canonical digest, equality with qualification and archived polyline
    order = ['X3', 'T3', 'X6', 'T6', 'upperBankT6', 'lowerBankT6', 'nodalQ', 'qActiveT6Rows', 'crackPolyline']
    new = {k: raw(f'{fn}_new_{k}') for k in order}
    qual = {k: raw(f'{fn}_qual_{k}') for k in order}
    cn, cq = canon([new[k] for k in order]), canon([qual[k] for k in order])
    chk(pfx + 'canonicalDigest', cn == cq == s['qualification']['canonicalSHA256'] == E['meshCanonical'] == so['canonicalSHA256'] == phs['canonicalSHA256'], cn)
    chk(pfx + 'arraysEqualQualification', all(np.array_equal(new[k], qual[k]) for k in order))
    Pa = raw(f'{fn}_arch_statePoly')
    chk(pfx + 'polylineIdentity', np.array_equal(new['crackPolyline'], Pa) and np.array_equal(raw(f'{fn}_arch_poly'), Pa))
    T3n = new['T3'].astype(int) - 1; X3n = new['X3']
    chk(pfx + 'meshQuality', len(T3n) == s['qualification']['T3'] and float(np.min(tri_area(X3n, T3n))) > 0, {'T3': len(T3n), 'minArea_mm2': float(np.min(tri_area(X3n, T3n)))})
    # ---------------- banks and protected near-tip topology (independent)
    Xn, Xa = new['X6'], raw(f'{fn}_arch_X6'); tipNode = int(raw(f'{fn}_qual_physicalTipNode').ravel()[0])
    Bn = banks(Xn, new['upperBankT6'], new['lowerBankT6'], Pa); Ba = banks(Xa, raw(f'{fn}_arch_up'), raw(f'{fn}_arch_lo'), Pa)
    tip = Pa[-1]
    bok = lambda B, X: B['pair'] <= 1e-9 and B['uniqueStations'] and B['uniqueIds'] and len(B['shared']) == 1 and B['up'][-1] == B['lo'][-1] == B['shared'][0] \
        and np.all(B['up'][:-1] != B['lo'][:-1]) and np.linalg.norm(X[B['shared'][0]] - tip) <= 1e-9
    chk(pfx + 'banks', bok(Bn, Xn) and bok(Ba, Xa) and Bn['shared'][0] == tipNode - 1,
        {'new': {'stations': len(Bn['s']), 'pairResidual_mm': Bn['pair'], 'tipNode': Bn['shared'][0] + 1, 'tipOffset_mm': float(np.linalg.norm(Xn[Bn['shared'][0]] - tip))},
         'archived': {'stations': len(Ba['s']), 'pairResidual_mm': Ba['pair'], 'tipNode': Ba['shared'][0] + 1, 'tipOffset_mm': float(np.linalg.norm(Xa[Ba['shared'][0]] - tip))}})
    T6n, T6a = new['T6'].astype(int) - 1, raw(f'{fn}_arch_T6').astype(int) - 1
    rad = tol['nearTipRadius_mm'] + 1e-9

    def disk(X, T):
        inside = np.all(np.linalg.norm(X[T] - tip, axis=2) <= rad, axis=1)
        return sorted(tuple(sorted(tuple(np.round(X[n], 12)) for n in row)) for row in T[inside]), int(inside.sum())

    dn, cnt_n = disk(Xn, T6n); da, cnt_a = disk(Xa, T6a)
    nodesN = np.where(np.linalg.norm(Xn - tip, axis=1) <= rad)[0]; nodesA = np.where(np.linalg.norm(Xa - tip, axis=1) <= rad)[0]
    exactNodes = sorted(map(tuple, Xn[nodesN])) == sorted(map(tuple, Xa[nodesA]))
    chk(pfx + 'protectedTopologyDisk', dn == da and exactNodes and cnt_n > 0, {'elementsInDisk': cnt_n, 'nodesInDisk': int(len(nodesN)), 'nodeCoordinatesBitwiseEqual': exactNodes})
    # ---------------- phase owner/labels and active area
    on, ln = raw(f'{fn}_new_owner').ravel().astype(int), raw(f'{fn}_new_labels').ravel().astype(int)
    oa, la = raw(f'{fn}_arch_owner').ravel().astype(int), raw(f'{fn}_arch_labels').ravel().astype(int)
    mask = list(s['mask'])
    expectLab = lambda o: np.where(np.isin(o, [i + 1 for i in range(3) if mask[i]]), 2, 1)
    Kn, Ka = E['K'], E['archived']['K']
    An = float(np.sum(np.abs(tri_area(X3n, T3n))[ln == 2])) if np.any(ln == 2) else 0.0
    # archived T3 corners = first three T6 nodes
    Aa = float(np.sum(np.abs(tri_area(Xa, T6a[:, :3]))[la == 2])) if np.any(la == 2) else 0.0
    ownerCounts = lambda o: [int(np.sum(o == i)) for i in range(4)]
    chk(pfx + 'phase', np.array_equal(ln, expectLab(on)) and np.array_equal(la, expectLab(oa)) and len(on) == len(T3n)
        and [int(np.sum(ln == 1)), int(np.sum(ln == 2))] == list(Kn['phaseCounts']) and [int(np.sum(la == 1)), int(np.sum(la == 2))] == list(Ka['phaseCounts'])
        and abs(An - Kn['activeArea_mm2']) <= 1e-9 * max(1, An) and abs(Aa - Ka['activeArea_mm2']) <= 1e-9 * max(1, Aa)
        and list(phs['chordsPerCircle']) == [76, 76, 76] and E['phaseAudit']['auditPass'] is True and E['phaseAudit']['pairingPass'] is True,
        {'ownerCountsNew': ownerCounts(on), 'ownerCountsArchived': ownerCounts(oa), 'labelCountsNew': [int(np.sum(ln == 1)), int(np.sum(ln == 2))],
         'labelCountsArchived': [int(np.sum(la == 1)), int(np.sum(la == 2))], 'activeAreaRecomputedNew_mm2': An, 'activeAreaRecomputedArchived_mm2': Aa,
         'activeAreaRecordedNew_mm2': Kn['activeArea_mm2'], 'activeAreaRecordedArchived_mm2': Ka['activeArea_mm2']})
    if not any(mask):
        chk(pfx + 'exactZeroActiveArea', Kn['activeArea_mm2'] == 0 and Ka['activeArea_mm2'] == 0 and not np.any(ln == 2) and not np.any(la == 2))
    # ---------------- solver gates (16) and u shape / BVP
    gN, gA = Kn['criteria'], Ka['criteria']
    un, ua = raw(f'{fn}_new_u').ravel(), raw(f'{fn}_arch_u').ravel()
    ld = int(Kn['loadNode']) - 1
    chk(pfx + 'solverGates', len(gN) == 16 and len(gA) == 16 and all(v is True for v in gN.values()) and all(v is True for v in gA.values())
        and Kn['pass'] is True and Ka['pass'] is True and set(gN) == set(gA), sorted(gN))
    chk(pfx + 'uShapeAndLoad', un.size == 2 * len(Xn) and ua.size == 2 * len(Xa) and np.all(np.isfinite(un)) and np.all(np.isfinite(ua))
        and np.array_equal(Xn[ld], [254.0, 203.2]) and un[2 * ld + 1] == Kn['uyLoad_mm'] and Kn['compliance_mm_per_N'] == abs(Kn['uyLoad_mm']),
        {'u_new': int(un.size), 'u_arch': int(ua.size)})
    # ---------------- metrics recomputed
    KIn, KIIn, KIa, KIIa = Kn['KI'], Kn['KII'], Ka['KI'], Ka['KII']
    Keq = math.hypot(KIa, KIIa); Gn = (KIn ** 2 + KIIn ** 2) / E_MPa; Ga = (KIa ** 2 + KIIa ** 2) / E_MPa
    thn, stn, okn = mts(KIn, KIIn); tha, sta, oka = mts(KIa, KIIa)
    sp = lambda K: max(np.max(np.array(K['EDI_all'])[:, :2], axis=0) - np.min(np.array(K['EDI_all'])[:, :2], axis=0)) / math.hypot(K['KI'], K['KII'])
    qd = lambda K: max(abs(K['EDI4x4'][0] - K['KI']), abs(K['EDI4x4'][1] - K['KII'])) / math.hypot(K['KI'], K['KII'])
    t = raw(f'{fn}_arch_tangent').ravel(); n_ = np.array([-t[1], t[0]])
    nxt = lambda th: Pa[-1] + 4.0 * (math.cos(th) * t + math.sin(th) * n_)
    archNext = np.array(s['nextPredictor']['tip_mm'])
    chk(pfx + 'nextTipRecurrenceReproducesArchived', float(np.linalg.norm(nxt(tha) - archNext)) <= 1e-12, float(np.linalg.norm(nxt(tha) - archNext)))
    tipN = nxt(thn)
    m = {}
    m['dKI_overKeq'] = (KIn - KIa) / Keq; m['dKII_overKeq'] = (KIIn - KIIa) / Keq; m['dKIIoverKI'] = KIIn / KIn - KIIa / KIa
    m['dG_rel'] = Gn / Ga - 1; m['dJ_rel'] = Kn['J'] / Ka['J'] - 1; m['newJoverGminus1'] = Kn['J'] / Gn - 1
    m['dMTS_deg'] = math.degrees(thn) - math.degrees(tha)
    m['newCODminusEDI_rel'] = max(abs(Kn['KI_COD'] - KIn), abs(Kn['KII_COD'] - KIIn)) / math.hypot(KIn, KIIn)
    m['archivedCODminusEDI_rel'] = max(abs(Ka['KI_COD'] - KIa), abs(Ka['KII_COD'] - KIIa)) / Keq
    m['dCODminusEDI'] = m['newCODminusEDI_rel'] - m['archivedCODminusEDI_rel']
    m['newPathSpread_rel'] = sp(Kn); m['archivedPathSpread_rel'] = sp(Ka); m['newQuad4x4_rel'] = qd(Kn); m['archivedQuad4x4_rel'] = qd(Ka)
    m['dCompliance_rel'] = Kn['compliance_mm_per_N'] / Ka['compliance_mm_per_N'] - 1
    m['dActiveArea_rel'] = (Kn['activeArea_mm2'] - Ka['activeArea_mm2']) / max(Ka['activeArea_mm2'], 1.0)
    m['nextTipDisplacement_mm'] = float(np.linalg.norm(tipN - archNext))
    # C8 (independent)
    jN, gNn = jumps(Bn, un, Pa); jA, gAa = jumps(Ba, ua, Pa)
    xN, xA = Xn[Bn['up']], Xa[Ba['up']]
    nt = np.linalg.norm(xN - tip, axis=1) <= tol['nearTipRadius_mm'] + tol['nodeMatch_mm']
    ntA = np.linalg.norm(xA - tip, axis=1) <= tol['nearTipRadius_mm'] + tol['nodeMatch_mm']
    dmat = []
    miss = 0
    for i in np.where(nt)[0]:
        dd = np.linalg.norm(xA - xN[i], axis=1); k = int(np.argmin(dd))
        if dd[k] <= tol['nodeMatch_mm']:
            dmat.append((i, k, abs(jN[i] - jA[k]), abs(gNn[i] - gAa[k]), float(dd[k])))
        else:
            miss += 1
    chk(pfx + 'C8nearTipIdentity', miss == 0 and int(nt.sum()) == int(ntA.sum()) > 0 and max(x[4] for x in dmat) == 0.0,
        {'nearNew': int(nt.sum()), 'nearArchived': int(ntA.sum()), 'maxMatchDistance_mm': max(x[4] for x in dmat)})
    chk(pfx + 'C8noExtrapolation', Bn['s'].min() >= Ba['s'].min() and Bn['s'].max() <= Ba['s'].max(),
        {'newRange': [float(Bn['s'].min()), float(Bn['s'].max())], 'archivedRange': [float(Ba['s'].min()), float(Ba['s'].max())]})
    ji = np.interp(Bn['s'], Ba['s'], jA); gi = np.interp(Bn['s'], Ba['s'], gAa)
    m['openingNearTipRel'] = max(x[2] for x in dmat) / float(np.max(jN[nt]))
    m['openingWholeCrackRel'] = float(np.max(np.abs(ji - jN))) / float(np.max(jN))
    m['signedOpeningNearTipRel'] = max(x[3] for x in dmat) / float(np.max(np.abs(gNn[nt])))
    m['signedOpeningWholeCrackRel'] = float(np.max(np.abs(gi - gNn))) / float(np.max(np.abs(gNn)))
    m['newMinSignedOpening_mm'] = float(np.min(gNn)); m['archivedMinSignedOpening_mm'] = float(np.min(gAa))
    m['newMaxJumpNearTip_mm'] = float(np.max(jN[nt])); m['newMaxJump_mm'] = float(np.max(jN))
    m['nearTipNodes'] = int(nt.sum()); m['nearTipNodesArchived'] = int(ntA.sum()); m['bankStationsNew'] = len(Bn['s']); m['bankStationsArchived'] = len(Ba['s'])
    m['newKI'] = KIn; m['archivedKI'] = KIa; m['newKII'] = KIIn; m['archivedKII'] = KIIa; m['archivedKeq'] = Keq; m['newG'] = Gn; m['archivedG'] = Ga
    m['newJ'] = Kn['J']; m['archivedJ'] = Ka['J']; m['newMTS_deg'] = math.degrees(thn); m['archivedMTS_deg'] = math.degrees(tha)
    m['newCompliance_mm_per_N'] = Kn['compliance_mm_per_N']; m['archivedCompliance_mm_per_N'] = Ka['compliance_mm_per_N']
    m['newActiveArea_mm2'] = Kn['activeArea_mm2']; m['archivedActiveArea_mm2'] = Ka['activeArea_mm2']
    m['newNextTipX_mm'], m['newNextTipY_mm'] = float(tipN[0]), float(tipN[1]); m['archivedNextTipX_mm'], m['archivedNextTipY_mm'] = float(archNext[0]), float(archNext[1])
    # diagnostics of the signed-opening whole-crack difference (reported only)
    iw = int(np.argmax(np.abs(gi - gNn))); ijw = int(np.argmax(np.abs(ji - jN)))
    kinkS = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(Pa, axis=0), axis=1))])
    r['diagnostics'] = {'signedWholeMaxAt_station_mm': float(Bn['s'][iw]), 'signedWholeMaxAt_xy': Xn[Bn['up'][iw]].tolist(),
                        'signedWholeMax_absDiff_mm': float(abs(gi[iw] - gNn[iw])), 'signedNew_mm': float(gNn[iw]), 'signedArchivedInterp_mm': float(gi[iw]),
                        'nearestKinkStationDistance_mm': float(np.min(np.abs(kinkS - Bn['s'][iw]))),
                        'jumpWholeMaxAt_station_mm': float(Bn['s'][ijw]), 'jumpWholeMax_absDiff_mm': float(abs(ji[ijw] - jN[ijw])),
                        'maxSignedOpening_new_mm': float(np.max(gNn)), 'maxAbsSignedOpening_new_mm': float(np.max(np.abs(gNn))),
                        'nearTipMaxAbsJumpDiff_mm': max(x[2] for x in dmat), 'nearTipMaxAbsSignedDiff_mm': max(x[3] for x in dmat),
                        'mtsStationarityNew': stn, 'mtsStationarityArchived': sta, 'mtsTensileMaxNew': okn, 'mtsTensileMaxArchived': oka,
                        'nextTipDelta_mm': (tipN - archNext).tolist(), 'crackStationsArchived_kinks_mm': kinkS.tolist()}
    # compare with the recorded metrics
    # classical-form cross-check (reported; its own cancellation bound)
    r['mtsClassicalForm'] = {'newDiff_deg': math.degrees(mts_classical(KIn, KIIn) - thn), 'archivedDiff_deg': math.degrees(mts_classical(KIa, KIIa) - tha),
                             'cancellationBound_rel': 2.220446049250313e-16 / (4 * (KIIa / KIa) ** 2)}
    # agreement rule (v3): |audit - recorded| <= 1e-12 * operand scale; counts exact
    angScale = max(abs(math.degrees(thn)), abs(math.degrees(tha)))
    crdScale = float(np.max(np.abs(np.concatenate([tipN, archNext]))))
    absKeys = {'newKI', 'archivedKI', 'newKII', 'archivedKII', 'archivedKeq', 'newG', 'archivedG', 'newJ', 'archivedJ', 'newCompliance_mm_per_N',
               'archivedCompliance_mm_per_N', 'newActiveArea_mm2', 'archivedActiveArea_mm2', 'newMaxJumpNearTip_mm', 'newMaxJump_mm',
               'newMinSignedOpening_mm', 'archivedMinSignedOpening_mm'}

    def scale_of(k, v, w):
        if k in ('dMTS_deg', 'newMTS_deg', 'archivedMTS_deg'):
            return angScale, 'angle |theta| (deg)'
        if k == 'nextTipDisplacement_mm' or 'NextTip' in k:
            return crdScale, 'tip coordinate magnitude (mm)'
        if k in absKeys:
            return max(abs(v), abs(w)), 'value'
        return 1.0, 'normalized (dimensionless O(1) operands)'

    rm = Cj['metrics']; cmp = {}
    for k, v in m.items():
        w = rm[k]
        if isinstance(v, int) and not isinstance(v, bool):
            cmp[k] = {'audit': v, 'recorded': w, 'absDiff': abs(v - w), 'ok': v == w, 'rule': 'exact'}
        else:
            ad = abs(v - w); sc, why = scale_of(k, v, w)
            cmp[k] = {'audit': v, 'recorded': w, 'absDiff': ad, 'scale': sc, 'diffOverScale': ad / sc if sc > 0 else (0.0 if ad == 0 else math.inf),
                      'ok': bool(ad == 0 or ad <= 1e-12 * sc), 'rule': why}
    r['metricAgreement'] = cmp
    chk(pfx + 'metricsRecomputed', all(c['ok'] for c in cmp.values()), {k: c for k, c in cmp.items() if not c['ok']})
    chk(pfx + 'metricKeysComplete', set(rm) - set(m) <= {'newSolverGatesPass', 'archivedSolverGatesPass', 'newMTSadmissible', 'chordsEqual'}, sorted(set(rm) - set(m)))
    # flags from the audit metrics and the policy thresholds
    fl = {}
    fl['C1_KI'] = abs(m['dKI_overKeq']) <= tol['KI_overKeq']; fl['C2_KII'] = abs(m['dKII_overKeq']) <= tol['KII_overKeq']
    fl['C3_KIIoverKI'] = abs(m['dKIIoverKI']) <= tol['KIIoverKI_abs']
    fl['C4_G_J'] = abs(m['dG_rel']) <= tol['G_rel'] and abs(m['dJ_rel']) <= tol['J_rel'] and abs(m['newJoverGminus1']) <= tol['newJoverGminus1']
    fl['C5_MTS'] = abs(m['dMTS_deg']) <= tol['MTS_deg'] and okn
    fl['C6_COD_EDI'] = m['newCODminusEDI_rel'] <= tol['newCODminusEDI_gate'] and abs(m['dCODminusEDI']) <= tol['dCODminusEDI']
    fl['C7_EDI_spread_quadrature'] = m['newPathSpread_rel'] <= max(tol['spreadFloor'], tol['spreadFactor'] * m['archivedPathSpread_rel']) and \
        m['newQuad4x4_rel'] <= max(tol['quadFloor'], tol['quadFactor'] * m['archivedQuad4x4_rel'])
    fl['C8_crackOpening'] = m['openingNearTipRel'] <= tol['openingNearTipRel'] and m['openingWholeCrackRel'] <= tol['openingWholeCrackRel']
    zero_ok = m['archivedActiveArea_mm2'] != 0 or m['newActiveArea_mm2'] == 0
    fl['C9_phaseActivation'] = checks[pfx + 'solverGates'] and list(phs['chordsPerCircle']) == list(E['archived']['phase']['audit']['geometry']['chordsPerCircle']) \
        and abs(m['dActiveArea_rel']) <= tol['activeArea_rel'] and zero_ok
    fl['C10_nextPredictor'] = m['nextTipDisplacement_mm'] <= tol['nextTipDisplacement_mm']
    fl['C11_compliance'] = abs(m['dCompliance_rel']) <= tol['compliance_rel']
    chk(pfx + 'criteriaFlagsEqualRecorded', fl == Cj['criteria'] and all(fl.values()) and Cj['outcome'] == 'EQUIVALENT_CASE' and Cj['valid'] is True
        and Cj['validation'] in ([], None) and Cj['failed'] in ([], None) and Cj['pass'] is True)
    # JSON vs MAT comparison record (every field)
    cm = E['comparisonMat']
    jm_ok = all(cm[k] == Cj[k] for k in ('outcome', 'valid', 'pass', 'criteria', 'solveId', 'caseId', 'stateIndex', 'token', 'solutionSHA256', 'meshSHA256', 'phaseSHA256', 'canonicalSHA256'))
    mdiff = max(abs(cm['metrics'][k] - Cj['metrics'][k]) for k in Cj['metrics'] if not isinstance(Cj['metrics'][k], bool))
    vec_ok = cm['vectors']['nextState'] == Cj['vectors']['nextState'] == s['nextPredictor']['state'] and Cj['vectors']['archivedNextTip_mm'] == s['nextPredictor']['tip_mm'] \
        and Cj['vectors']['newChordsPerCircle'] == Cj['vectors']['archivedChordsPerCircle'] == [76, 76, 76] \
        and max(abs(a_ - b_) for a_, b_ in zip(Cj['vectors']['newNextTip_mm'], tipN)) <= 1e-12
    chk(pfx + 'jsonEqualsMatAndVectors', jm_ok and mdiff == 0 and vec_ok, {'maxMetricJsonMatDiff': mdiff})
    # utilization table
    util = {
        'C1_KI': abs(m['dKI_overKeq']) / tol['KI_overKeq'], 'C2_KII': abs(m['dKII_overKeq']) / tol['KII_overKeq'], 'C3_KIIoverKI': abs(m['dKIIoverKI']) / tol['KIIoverKI_abs'],
        'C4_G': abs(m['dG_rel']) / tol['G_rel'], 'C4_J': abs(m['dJ_rel']) / tol['J_rel'], 'C4_JoverG': abs(m['newJoverGminus1']) / tol['newJoverGminus1'],
        'C5_MTS': abs(m['dMTS_deg']) / tol['MTS_deg'], 'C6_newCOD': m['newCODminusEDI_rel'] / tol['newCODminusEDI_gate'], 'C6_dCOD': abs(m['dCODminusEDI']) / tol['dCODminusEDI'],
        'C7_spread': m['newPathSpread_rel'] / max(tol['spreadFloor'], tol['spreadFactor'] * m['archivedPathSpread_rel']),
        'C7_quad': m['newQuad4x4_rel'] / max(tol['quadFloor'], tol['quadFactor'] * m['archivedQuad4x4_rel']),
        'C8_nearTip': m['openingNearTipRel'] / tol['openingNearTipRel'], 'C8_wholeCrack': m['openingWholeCrackRel'] / tol['openingWholeCrackRel'],
        'C9_activeArea': abs(m['dActiveArea_rel']) / tol['activeArea_rel'], 'C10_nextTip': m['nextTipDisplacement_mm'] / tol['nextTipDisplacement_mm'],
        'C11_compliance': abs(m['dCompliance_rel']) / tol['compliance_rel']}
    r['metrics'] = m; r['utilization'] = util; r['flags'] = fl
    # memory and timing
    mg = so['memoryGate']
    chk(pfx + 'memoryGate', mg['pass'] is True and mg['freeGiB'] >= 7 and mg['minGiB'] == 7, mg)
    r['solveSeconds'] = so['solveSeconds']
    results[sid] = r

# ------------------------------------------------------------------ ordering (file times) and counts
mt = lambda p: os.path.getmtime(p)
t_rec = mt(os.path.join(recRoot, 'RECEIPT.mat'))
t1 = mt(os.path.join(runRoot, IDS[0], 'COMPARISON.json')); t2a = mt(os.path.join(runRoot, IDS[1], 'GEOMETRY_h040', 'ATTEMPT.json')); t2 = mt(os.path.join(runRoot, IDS[1], 'COMPARISON.json'))
chk('ordering', t_rec <= t1 <= t2a <= t2 <= mt(summ), {'receipt->soft1 comparison->H geometry->H comparison->summary (s)': [0, t1 - t_rec, t2a - t_rec, t2 - t_rec, mt(summ) - t_rec]})
logt = open(os.path.join(RD, 'b1eq_campaign.log'), 'rb').read()
logt = logt.decode('utf-16') if logt[:2] in (b'\xff\xfe', b'\xfe\xff') else logt.decode('utf-8', 'replace')
counts = {'entryCalls': logt.count('B1EQ_ENTRY_CALL'), 'physicalSolveLines': len(re.findall(r'^G2_M4B_SIF ', logt, re.M)),
          'geometryAdmissions': len(re.findall(r'^G2_LP2B1_ATTEMPT GEOMETRY_h040', logt, re.M)), 'caseCalls': S['solvesCalled'],
          'solutionRecords': sum(1 for k in found if k.endswith('/SOLUTION.mat'))}
chk('counts', counts == {'entryCalls': 1, 'physicalSolveLines': 2, 'geometryAdmissions': 2, 'caseCalls': 2, 'solutionRecords': 2}, counts)
out = {'schema': 'NewMetacomp.G2.LP2B1EQ.IndependentAudit.v1', 'pass': not problems, 'problems': problems, 'checks': checks, 'detail': detail,
       'physicalSolvesAttempted': 2, 'physicalSolvesCompleted': 2, 'caseCalls': S['solvesCalled'], 'entryInvocations': counts['entryCalls'], 'results': results}
json.dump(out, open(OUT, 'w', encoding='utf-8', newline='\n'), indent=1, default=lambda o: o.item() if hasattr(o, 'item') else str(o))
print('AUDIT', 'PASS' if not problems else 'HOLD', f'{sum(checks.values())}/{len(checks)}', problems)
