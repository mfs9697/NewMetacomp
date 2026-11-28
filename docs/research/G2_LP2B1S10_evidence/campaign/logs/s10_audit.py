"""Independent read-only audit of campaign G2-LP2B1-S10-001 (Python + numpy only; no MATLAB function is reused).
Inputs: the execution clone (records, policy, git), the MATLAB closure dump (record scalars), the raw little-endian float64 exports
and the parent-chain histories of the four architectures. Everything numerical is RE-IMPLEMENTED here: canonical digest, bank stations,
protected near-tip disk, phase labels -> active area, mesh angles/areas, G and J identity, the MTS root (cancellation-free form, with
stationarity and tensile-maximum checks), the 4 mm recurrence of every state of every history, heading, ring/hole circle distances,
the S11 information-only forecast and the four-architecture comparison at the common s = 65.4 mm.
Any discrepancy is a problem (=> VERIFY_HOLD, not accepted).
usage: python -I s10_audit.py <execRepo> <runDir(scratch lp2b1s10run)> <out.json>"""
import hashlib, json, math, os, re, subprocess, sys
import numpy as np

EX, RD, OUT = sys.argv[1:4]
AUTH_HEAD = '0fcee176a5e294b7c8d7f33711ad7d3897be6538'
GO_HEAD = 'c243c58c477fddd7a191a1d00c1117cd5a927ab5'
REV_HEAD = '37458ef1c00acdcc829b22c220c2e73d1ea0d477'
GO_PATH = 'matlab/g2/lp2b1s10/G2_LP2B1S10_GO.json'
URL = 'https://github.com/mfs9697/NewMetacomp/pull/82#issuecomment-7237508619'
PARENT_S9 = '79ebecbc21b4d9425e3a2b82a9bc17270373a85f2a7c26d11cfe1e7c9b45aec6'
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
git = lambda *a: subprocess.run(['git', '-C', EX] + list(a), capture_output=True).stdout.decode().strip()
pol = json.load(open(P('matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json'), encoding='utf-8'))
au, geo, tol = pol['authorization'], pol['geometry'], pol['tolerances']
E_MPa = pol['bvp']['E_MPa']
A = json.load(open(os.path.join(RD, 'verify', 'LP2B1S10_RECORD_DUMP.json'), encoding='utf-8'))
# v2: the MATLAB record reader used by the closure dump returns some SHA-256 strings upper-case (v1 defect); compare case-insensitively
for _k in ('meshFileSHA256', 'phaseSHA256', 'solutionSHA256', 'stateSHA256', 'terminalSHA256'):
    A[_k] = A[_k].lower()
HI = json.load(open(os.path.join(RD, 'verify', 'LP2B1S10_HISTORIES_v2.json'), encoding='utf-8'))
for _c in HI.values():
    for _e in (_c if isinstance(_c, list) else [_c]):
        _e['sha256'] = _e['sha256'].lower(); _e['parentSHA256'] = (_e['parentSHA256'] or '').lower()


def index(d):
    return {x['file'][:-4]: (d, x) for x in json.load(open(os.path.join(RD, 'verify', d, 'RAW_INDEX.json'), encoding='utf-8'))}


IX = {**index('raw'), **index('raw_hist_v2')}


def raw(name):
    d, x = IX[name]
    a = np.fromfile(os.path.join(RD, 'verify', d, x['file']), dtype='<f8')
    shp = [int(s) for s in x['shape']]
    assert a.size == int(np.prod(shp)), name
    return a.reshape(shp, order='F')


# ------------------------------------------------------------------ 1 exact run / ledger / summary sets
runRoot, recRoot = P(au['runRoot']), P(au['receiptRoot'])


def tree(root):
    out = {}
    for r, _, fs in os.walk(root):
        for f in fs:
            out[os.path.relpath(os.path.join(r, f), root).replace('\\', '/')] = fsha(os.path.join(r, f))
    return out


found = tree(P('outputs/g2_lp2b1_s10_v1'))
want = sorted('run_lp2b1_s10_v1/soft1/' + e for e in ['S10/GEOMETRY_h040/ATTEMPT.json', 'S10/GEOMETRY_h040/ATTEMPT_ARRAYS.mat', 'S10/MESH.mat',
    'S10/PHASE.mat', 'S10/PHASE.mat.manifest.json', 'S10/SOLUTION.mat', 'S10/SOLUTION.mat.manifest.json', 'S10/STATE.mat', 'S10/STATE.mat.manifest.json',
    'TERMINAL.mat', 'TERMINAL.mat.manifest.json'])
chk('runSetExact11', sorted(found) == want, {'files': len(found), 'unexpected': sorted(set(found) - set(want)), 'missing': sorted(set(want) - set(found))})
recf = tree(P('outputs/g2_lp2b1_s10_receipts'))
wantR = sorted('G2-LP2B1-S10-001/' + e for e in ['RECEIPT.mat', 'RECEIPT.mat.manifest.json', 'ADMIT_soft1_S10.mat', 'ADMIT_soft1_S10.mat.manifest.json'])
chk('ledgerSetExact4', sorted(recf) == wantR, sorted(recf))
chk('noHoldOrClosedFiles', not any(('HOLD' in k) or ('CLOSED' in k) for k in list(found) + list(recf)))
dr = A['files']['run']; dumpRun = {p: h for p, h in zip(dr['path'], dr['sha256'])} if isinstance(dr, dict) else {x['path']: x['sha256'] for x in dr}
chk('dumpRunHashesEqualAudit', {('outputs/g2_lp2b1_s10_v1/' + k): v for k, v in found.items()} == dumpRun)
man = {}
for k in [k for k in found if k.endswith('.manifest.json')]:
    m = json.load(open(os.path.join(P('outputs/g2_lp2b1_s10_v1'), *k.split('/')), encoding='utf-8'))
    man[k] = m['SHA256'].lower() == found[k[:-len('.manifest.json')]]
for k in [k for k in recf if k.endswith('.manifest.json')]:
    m = json.load(open(os.path.join(P('outputs/g2_lp2b1_s10_receipts'), *k.split('/')), encoding='utf-8'))
    man[k] = m['SHA256'].lower() == recf[k[:-len('.manifest.json')]]
chk('manifestsMatchFiles', len(man) == 6 and all(man.values()), man)
summ = P(au['summaryPath']); summOut = os.path.join(RD, 'campaign', 'LP2B1S10_CAMPAIGN.json')
S = json.load(open(summ, encoding='utf-8'))
chk('summaryCopiesIdentical', fsha(summ) == fsha(summOut), fsha(summ))
chk('summaryOutcome', S['outcome'] == 'STATE_ACCEPTED' and S['admissions'] == 1 and S['solveCalls'] == 1 and S['reason'] == ''
    and S['verification']['outcome'] == 'VERIFIED_ACCEPTED' and S['driver']['stage'] == 'STATE_ACCEPTED',
    {'outcome': S['outcome'], 'admissions': S['admissions'], 'solveCalls': S['solveCalls'], 'verify': S['verification']['outcome'], 'wall_s': S['wallSeconds']})
pc = S['precheck']
chk('precheck', pc['tokenEqualsContext'] is True and pc['engines'] == 1 and pc['release'] == '2023a' and pc['pde'] == '3.10' and pc['memgate']['pass'] is True
    and pc['parentCheck']['pass'] is True and pc['parentCheck']['head'] == GO_HEAD and pc['parentCheck']['parent'] == AUTH_HEAD
    and pc['parentCheck']['changedFiles'] in ([GO_PATH], GO_PATH) and list(pc['parentCheck']['statuses']) == [0, 0, 0],
    {'memgateFreeGiB': pc['memgate']['freeGiB']})

# ------------------------------------------------------------------ 2 activation, revocation, receipt, ledger
goBytes = subprocess.run(['git', '-C', EX, 'show', f'{GO_HEAD}:{GO_PATH}'], capture_output=True).stdout
goSha = hashlib.sha256(goBytes).hexdigest(); GO = json.loads(goBytes.decode('utf-8'))
authRec = json.load(open(os.path.join(RD, 'pre', 'AUTH_ACTIVATION_RECORD.json'), encoding='utf-8')); authRec['decisionUrl'] = URL
chk('goEqualsAuthorizationRecord', GO == authRec and list(GO) == list(authRec) and GO['approvedHead'] == AUTH_HEAD, goSha)
chk('activationCommit', git('rev-parse', f'{GO_HEAD}~1') == AUTH_HEAD and git('diff', '--name-only', AUTH_HEAD, GO_HEAD).split() == [GO_PATH])
treeEq = git('rev-parse', f'{REV_HEAD}^{{tree}}') == git('rev-parse', f'{AUTH_HEAD}^{{tree}}')
chk('revocationCommit', git('rev-parse', f'{REV_HEAD}~1') == GO_HEAD and git('diff', '--name-only', GO_HEAD, REV_HEAD).split() == [GO_PATH] and treeEq
    and git('rev-parse', 'HEAD') == REV_HEAD and not os.path.exists(P(GO_PATH)), {'treeEqualsApproved': treeEq})
tok = GO['token']; polSha = fsha(P('matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json'))
d1 = lambda s: hashlib.sha256(s.encode()).hexdigest()
s10d = d1('\n'.join(f'{n} {fsha(os.path.join(P("matlab/g2/lp2b1s10"), n))}' for n in sorted(x for x in os.listdir(P('matlab/g2/lp2b1s10')) if x.endswith('.m'))))
chk('tokenComponents', f'policy={polSha}' in tok and f'lp2b1s10source={s10d}' in tok and A['token'] == tok and A['policySHA256'] == polSha, {'policy': polSha, 'lp2b1s10source': s10d})
R = A['receipt']['record']
chk('receiptLinks', A['receipt']['manifestOK'] is True and R['token'] == tok and R['approvedHead'] == AUTH_HEAD and R['activationHead'] == GO_HEAD
    and R['goFileSHA256'] == goSha and R['campaignId'] == 'G2-LP2B1-S10-001' and R['runName'] == 'run_lp2b1_s10_v1' and R['sourceCommit'] == GO_HEAD,
    {'openedUTC': R['openedUTC']})
Ad = A['admit']['record']
chk('admitAndLedger', A['admit']['manifestOK'] is True and Ad['stateKey'] == 'soft1_S10' and Ad['caseId'] == 'soft1' and Ad['stateIndex'] == 10
    and Ad['token'] == tok and Ad['campaignId'] == 'G2-LP2B1-S10-001' and A['ledger'] == {'integrityOK': True, 'nAdmits': 1, 'nHolds': 0, 'closed': False},
    {'ledger': A['ledger'], 'note': 'single-state policy: no CLOSED ledger entry is written by design'})

# ------------------------------------------------------------------ 3 record links and identity
st, so, ph, tr, K = A['state'], A['solution'], A['phase'], A['terminal'], A['K']
f = lambda n: found['run_lp2b1_s10_v1/soft1/' + n]
chk('recordLinks', A['stateManifestOK'] and A['solutionManifestOK'] and A['phaseManifestOK'] and A['terminalManifestOK']
    and st['meshSHA256'] == f('S10/MESH.mat') == so['meshSHA256'] == ph['meshSHA256'] == A['meshFileSHA256']
    and st['phaseSHA256'] == f('S10/PHASE.mat') == so['phaseSHA256'] == A['phaseSHA256'] and st['solutionSHA256'] == f('S10/SOLUTION.mat') == A['solutionSHA256']
    and tr['stateSHA256'] == tr['parentSHA256'] == f('S10/STATE.mat') == A['stateSHA256'] and A['terminalSHA256'] == f('TERMINAL.mat'))
chk('activationLinksInRecords', st['token'] == so['token'] == ph['token'] == tr['token'] == tok and so['approvedHead'] == AUTH_HEAD and so['activationHead'] == GO_HEAD
    and so['goFileSHA256'] == goSha and st['sourceCommit'] == GO_HEAD and st['policySHA256'] == so['policySHA256'] == polSha
    and st['lp2b1s10SourceSHA256'] == so['lp2b1s10SourceSHA256'] == s10d)
chk('parentIsOriginalS9', st['parentSHA256'] == tr['originalParentSHA256'] == PARENT_S9 == A['target']['parentSHA256'] and st['parentSchema'] == 'NewMetacomp.G2.LP2A3.State.v1'
    and fsha(P('outputs/g2_lp2a3_paths_v1/run_lp2a3_s9_s11_v1/soft1/S9/STATE.mat')) == PARENT_S9)
chk('identity', st['caseId'] == so['caseId'] == ph['caseId'] == tr['caseId'] == 'soft1' and st['stateIndex'] == so['stateIndex'] == ph['stateIndex'] == 10
    and list(st['mask']) == list(ph['mask']) == list(tr['mask']) == [1, 0, 0] and st['ratio'] == 0.5 and st['numericalStatus'] == 'ACCEPTED'
    and st['physicalFractureGrowthProven'] is False and tr['physicalArrest'] is False and tr['interfaceEncounter'] is False
    and tr['classification'] == 'SINGLE_STATE_LIMIT_REACHED' and tr['lastAcceptedState'] == 10 and tr['candidateIsInformationOnly'] is True)
chk('targetQualification', A['target']['pass'] is True and all(A['target']['checks'].values()) and len(A['target']['checks']) == 9, A['target']['checks'])

# ------------------------------------------------------------------ 4 geometry: canonical digest, arrays, polyline, quality
order = ['X3', 'T3', 'X6', 'T6', 'upperBankT6', 'lowerBankT6', 'nodalQ', 'qActiveT6Rows', 'crackPolyline']


def canon(arrs):
    h = hashlib.sha256()
    for a in arrs:
        h.update(np.asarray(a.shape, dtype='<i8').tobytes()); h.update(np.asarray(a, dtype='<f8').flatten(order='F').tobytes())
    return h.hexdigest()


new = {k: raw('new_' + k) for k in order}; qual = {k: raw('qual_' + k) for k in order}
cn, cq = canon([new[k] for k in order]), canon([qual[k] for k in order])
chk('canonicalDigest', cn == cq == pol['qualification']['canonicalSHA256'] == A['meshCanonical'] == st['canonicalSHA256'] == ph['canonicalSHA256'], cn)
chk('arraysEqualQualification', all(np.array_equal(new[k], qual[k]) for k in order) and A['qualificationArraysSHA256'] == pol['qualification']['arrays']['sha256']
    == fsha(P(pol['qualification']['arrays']['path'])))
Ps = raw('new_statePoly'); Pf = raw('target_forecastPoly')
chk('polylineIdentity', np.array_equal(new['crackPolyline'], Ps) and np.array_equal(Ps, Pf) and np.array_equal(raw('fail_crackPolyline'), Ps)
    and list(Ps[-1]) == pol['target']['expectedTip_mm'] == list(st['tip_mm']))
X3, T3 = new['X3'], new['T3'].astype(int) - 1


def tri_area(X, T):
    a, b, c = X[T[:, 0]], X[T[:, 1]], X[T[:, 2]]
    return 0.5 * ((b[:, 0] - a[:, 0]) * (c[:, 1] - a[:, 1]) - (c[:, 0] - a[:, 0]) * (b[:, 1] - a[:, 1]))


def min_angle(X, T):
    a, b, c = X[T[:, 0]], X[T[:, 1]], X[T[:, 2]]
    ang = []
    for p, q, r in ((a, b, c), (b, c, a), (c, a, b)):
        u, v = q - p, r - p
        ang.append(np.degrees(np.arctan2(np.abs(u[:, 0] * v[:, 1] - u[:, 1] * v[:, 0]), np.sum(u * v, axis=1))))
    return float(np.min(np.minimum(np.minimum(ang[0], ang[1]), ang[2])))


ar = tri_area(X3, T3); mang = min_angle(X3, T3); ex = pol['meshFamily']['expected']
at = A['attempt']; ind = at.get('independent', {})
chk('meshQuality', len(T3) == ex['T3'] == st['T3'] and float(ar.min()) > 0 and abs(mang - ex['minAngle_deg']) <= 1e-9 and mang >= 20
    and ind.get('minAngle_deg') == ex['minAngle_deg'] and ind.get('maxNeighborRatio') == ex['maxNeighborRatio'] and ex['maxNeighborRatio'] <= 1.8
    and int(new['qActiveT6Rows'].size) == ex['qActiveT6Parents'] and st['pairingGates'] == 10 and st['meshAuditGates'] == 34,
    {'T3': len(T3), 'minArea_mm2': float(ar.min()), 'minAngleRecomputed_deg': mang, 'minAngleRecorded_deg': ind.get('minAngle_deg'),
     'maxNeighborRatioRecorded': ind.get('maxNeighborRatio'), 'qActiveT6Parents': int(new['qActiveT6Rows'].size)})


def stations(X, Pl):
    tt = np.diff(Pl, axis=0); L = np.linalg.norm(tt, axis=1); tt = tt / L[:, None]; Sv = np.concatenate([[0], np.cumsum(L)])
    dk = np.empty((len(X), len(L))); lk = np.empty_like(dk)
    for q in range(len(L)):
        l = np.clip((X - Pl[q]) @ tt[q], 0, L[q]); dk[:, q] = np.linalg.norm(X - (Pl[q] + l[:, None] * tt[q]), axis=1); lk[:, q] = l
    k = np.argmin(dk, axis=1)
    return Sv[k] + lk[np.arange(len(X)), k], k


X6 = new['X6']; up = new['upperBankT6'].astype(int).ravel() - 1; lo = new['lowerBankT6'].astype(int).ravel() - 1
su, _ = stations(X6[up], Ps); sl, _ = stations(X6[lo], Ps); up = up[np.argsort(su, kind='stable')]; lo = lo[np.argsort(sl, kind='stable')]
pair = float(np.max(np.linalg.norm(X6[up] - X6[lo], axis=1))); shared = sorted(set(up.tolist()) & set(lo.tolist())); tip = Ps[-1]
tipNode = int(raw('qual_physicalTipNode').ravel()[0]) - 1
chk('banksAndUniqueTip', pair <= 1e-9 and len(shared) == 1 and shared[0] == tipNode and up[-1] == lo[-1] == tipNode and np.all(up[:-1] != lo[:-1])
    and float(np.linalg.norm(X6[tipNode] - tip)) <= 1e-9, {'stations': int(len(up)), 'pairResidual_mm': pair, 'tipOffset_mm': float(np.linalg.norm(X6[tipNode] - tip))})
T6 = new['T6'].astype(int) - 1; XF, TF = raw('fail_X6'), raw('fail_T6').astype(int) - 1; rad = tol['nearTipRadius_mm'] + 1e-9


def disk(X, T):
    inside = np.all(np.linalg.norm(X[T] - tip, axis=2) <= rad, axis=1)
    return sorted(tuple(sorted(tuple(X[n]) for n in row)) for row in T[inside]), int(inside.sum())


dn, cn_ = disk(X6, T6); dfm, cf_ = disk(XF, TF)
chk('protectedNearTipDiskEqualsFailedMeshBaseline', dn == dfm and cn_ > 0, {'elementsInDisk': cn_, 'radius_mm': tol['nearTipRadius_mm']})

# ------------------------------------------------------------------ 5 phase, solver gates, BVP
on, ln = raw('new_owner').ravel().astype(int), raw('new_labels').ravel().astype(int)
expectLab = np.where(on == 1, 2, 1)
Aact = float(np.sum(np.abs(ar)[ln == 2]))
chk('phase', np.array_equal(ln, expectLab) and len(on) == len(T3) and [int(np.sum(ln == 1)), int(np.sum(ln == 2))] == list(K['phaseCounts']) == list(st['phaseCounts'])
    and abs(Aact - K['activeArea_mm2']) <= 1e-9 * Aact and K['activeArea_mm2'] == st['activeArea_mm2'] and list(ph['chordsPerCircle']) == [76, 76, 76]
    and A['phaseAudit'] == {'auditPass': True, 'pairingPass': True, 'auditGates': 34, 'pairingGates': 10},
    {'ownerCounts': [int(np.sum(on == i)) for i in range(4)], 'labelCounts': [int(np.sum(ln == 1)), int(np.sum(ln == 2))], 'activeAreaRecomputed_mm2': Aact,
     'activeAreaRecorded_mm2': K['activeArea_mm2']})
gates = K['criteria']
chk('solverGates16', len(gates) == 16 and all(v is True for v in gates.values()) and K['pass'] is True and K['failedCriteria'] in ([], None, ''), sorted(gates))
u = raw('new_u').ravel(); ld = int(K['loadNode']) - 1
chk('uShapeLoadCompliance', u.size == 2 * len(X6) and np.all(np.isfinite(u)) and list(X6[ld]) == [254.0, 203.2] and u[2 * ld + 1] == K['uyLoad_mm']
    and K['compliance_mm_per_N'] == abs(K['uyLoad_mm']) == st['compliance_mm_per_N'], {'dofs': int(u.size), 'compliance_mm_per_N': K['compliance_mm_per_N']})
mg = so['memoryGate']
chk('memoryGateBeforeSolve', mg['pass'] is True and mg['freeGiB'] >= 7 and mg['minGiB'] == 7, mg)


# ------------------------------------------------------------------ 6 numerics recomputed
def mts(KI, KII):
    th = 2.0 * math.atan(-2.0 * KII / (KI + math.sqrt(KI * KI + 8.0 * KII * KII)))
    st_ = abs(KI * math.sin(th) + KII * (3 * math.cos(th) - 1)) / math.hypot(KI, KII)
    fh = lambda x: math.cos(x / 2) * (KI * math.cos(x / 2) ** 2 - 1.5 * KII * math.sin(x)); h = 1e-6
    return th, st_, fh(th) > 0 and (fh(th + h) - 2 * fh(th) + fh(th - h)) / h / h < 0


KI, KII = K['KI'], K['KII']; Kr = math.hypot(KI, KII); G = Kr * Kr / E_MPa
th, stn, tens = mts(KI, KII)
ed = raw('new_EDI_all')
rec = {'G': (G, st['G']), 'JoverGminus1': (K['J'] / G - 1, st['JoverGminus1']), 'KIIoverKI': (KII / KI, st['KIIoverKI']), 'MTS_deg': (math.degrees(th), st['MTS_deg']),
       'CODminusEDI_rel': (max(abs(K['KI_COD'] - KI), abs(K['KII_COD'] - KII)) / Kr, st['CODminusEDI_rel']),
       'pathSpread_rel': (float(np.max(np.max(ed[:, :2], axis=0) - np.min(ed[:, :2], axis=0))) / Kr, st['pathSpread_rel']),
       'quad4x4_rel': (max(abs(K['EDI4x4'][0] - KI), abs(K['EDI4x4'][1] - KII)) / Kr, st['quad4x4_rel']),
       'KI_MPa_sqrt_m_per_kN': (KI * 1000 / math.sqrt(1000), K['KI_MPa_sqrt_m_per_kN']), 'KII_MPa_sqrt_m_per_kN': (KII * 1000 / math.sqrt(1000), K['KII_MPa_sqrt_m_per_kN'])}
agree = {k: {'audit': a, 'recorded': b, 'absDiff': abs(a - b), 'ok': abs(a - b) <= 1e-12 * max(abs(a), abs(b), 1e-300) or abs(a - b) <= 1e-15} for k, (a, b) in rec.items()}
chk('numericsRecomputed', all(v['ok'] for v in agree.values()) and st['KI'] == KI and st['KII'] == KII and st['J'] == K['J'], {k: v for k, v in agree.items()})
chk('mtsAdmissible', KI > 0 and stn <= tol['mtsStationarity_rel'] and tens and A['newMTS']['status'] == 'OK' and A['newMTS']['admissibleForStep'] is True,
    {'stationarity': stn, 'tensileMaximum': tens})
cen = np.array(geo['centres_mm']); dc = np.linalg.norm(cen - tip, axis=1)
chk('ringAndHoleCircleDistances', np.max(np.abs(dc - geo['ringR_mm'] - np.array(st['tipToRingCircle_mm']))) <= 1e-12
    and np.max(np.abs(dc - geo['holeR_mm'] - np.array(st['tipToHoleCircle_mm']))) <= 1e-12 and st['classification'] == 'MATRIX_ADVANCE'
    and min(st['guideRingGap_mm']) >= 1.0 and abs(st['guideRingGap_mm'][0] - pol['target']['ring1GuideGap_mm']['matlabGuard']) <= 1e-12
    and abs(st['guideRingGap_mm'][0] - pol['target']['ring1GuideGap_mm']['issueValue']) <= tol['ring1GuideGapIssueValue_mm'],
    {'tipToRingCircle_mm': (dc - geo['ringR_mm']).tolist(), 'guideRingGap_mm': st['guideRingGap_mm']})
cl = A['state'].get('clearance', {})
chk('kinkAdmissibilityRecorded', st['kinkGatesPass'] is True)

# ------------------------------------------------------------------ 7 recurrence of every state of every history, S11 forecast
hist = {c: sorted(v if isinstance(v, list) else [v], key=lambda e: e['stateIndex']) for c, v in HI.items()}
recur = {}
for c, ch in hist.items():
    chk(f'history_{c}_complete', [e['stateIndex'] for e in ch] == list(range(11)) and all(e['manifestOK'] for e in ch)
        and all(abs(e['arc_mm'] - (25.4 + 4 * e['stateIndex'])) <= 1e-9 for e in ch))
    worst = 0.0; worstAng = 0.0
    for a_, b_ in zip(ch[:-1], ch[1:]):
        Pa_ = raw(f'hist_{c}_S{a_["stateIndex"]}_poly'); Pb_ = raw(f'hist_{c}_S{b_["stateIndex"]}_poly')
        t = (Pa_[-1] - Pa_[-2]) / np.linalg.norm(Pa_[-1] - Pa_[-2]); n_ = np.array([-t[1], t[0]])
        thA, _, _ = mts(a_['KI'], a_['KII'])
        nxt = Pa_[-1] + 4.0 * (math.cos(thA) * t + math.sin(thA) * n_)
        worst = max(worst, float(np.linalg.norm(nxt - Pb_[-1])), float(np.max(np.abs(Pb_[:-1] - Pa_)) if Pb_.shape[0] == Pa_.shape[0] + 1 else 1e9))
        worstAng = max(worstAng, abs(math.degrees(thA) - a_['MTS_deg']))
        if b_['G'] is not None and b_['KI'] is not None:
            worstAng = max(worstAng, 0.0)
    recur[c] = {'maxTipRecurrenceError_mm': worst, 'maxMTSdiff_deg': worstAng}
    chk(f'history_{c}_recurrence', worst <= 1e-9 and worstAng <= 1e-9, recur[c])
    gerr = max(abs((e['KI'] ** 2 + e['KII'] ** 2) / E_MPa / e['G'] - 1) for e in ch)
    chk(f'history_{c}_G_identity', gerr <= 1e-12, gerr)
s9 = hist['soft1'][9]
chk('S10parentInHistory', s9['sha256'] == PARENT_S9 and hist['soft1'][10]['sha256'] == f('S10/STATE.mat'))
heading = math.degrees(math.atan2(Ps[-1, 1] - Ps[-2, 1], Ps[-1, 0] - Ps[-2, 0]))
t10 = (Ps[-1] - Ps[-2]) / np.linalg.norm(Ps[-1] - Ps[-2]); n10 = np.array([-t10[1], t10[0]])
chk('headingTangent', abs(heading - st['heading_deg']) <= 1e-12 * 100 and np.max(np.abs(t10 - np.array(st['tangent']))) <= 1e-15 and abs(np.linalg.norm(Ps[-1] - Ps[-2]) - 4) <= 1e-12,
    {'heading_deg': heading, 'stepLength_mm': float(np.linalg.norm(Ps[-1] - Ps[-2]))})
cand = tr['candidate']; P11 = raw('s11_poly')
tip11 = tip + 4.0 * (math.cos(th) * t10 + math.sin(th) * n10)
d11 = np.linalg.norm(cen - P11[-1], axis=1) - geo['ringR_mm']
chk('S11forecastInformationOnly', np.array_equal(P11[:-1], Ps) and float(np.linalg.norm(P11[-1] - tip11)) <= 1e-12 and cand['classification'] == 'MATRIX_ADVANCE'
    and cand['clearancePass'] is True and np.max(np.abs(d11 - np.array(cand['tipToRingCircle_mm']))) <= 1e-12 and min(cand['guideRingGap_mm']) >= 1.0
    and 'information only' in cand['note'],
    {'S11tip_mm': P11[-1].tolist(), 'S11tipError_mm': float(np.linalg.norm(P11[-1] - tip11)), 'S11tipToRingCircle_mm': d11.tolist(),
     'S11guideRingGap_mm': cand['guideRingGap_mm'], 'classification': cand['classification']})

# ------------------------------------------------------------------ 8 counts from the log and records
logt = open(os.path.join(RD, 's10_campaign.log'), 'rb').read()
logt = logt.decode('utf-16') if logt[:2] in (b'\xff\xfe', b'\xfe\xff') else logt.decode('utf-8', 'replace')
counts = {'entryCalls': logt.count('S10_ENTRY_CALL'), 'physicalSolveLines': len(re.findall(r'^G2_M4B_SIF ', logt, re.M)),
          'geometryAdmissions': len(re.findall(r'^G2_LP2B1_ATTEMPT GEOMETRY_h040', logt, re.M)), 'acceptedLines': logt.count('G2_LP2B1S10_ACCEPTED'),
          'admitRecords': sum(1 for k in recf if re.search(r'ADMIT_.*\.mat$', k)), 'solutionRecords': sum(1 for k in found if k.endswith('/SOLUTION.mat')),
          'wrapperAdmissions': S['admissions'], 'wrapperSolveCalls': S['solveCalls']}
chk('countsActualFEM', counts == {'entryCalls': 1, 'physicalSolveLines': 1, 'geometryAdmissions': 1, 'acceptedLines': 1, 'admitRecords': 1, 'solutionRecords': 1,
                                  'wrapperAdmissions': 1, 'wrapperSolveCalls': 1}, counts)
mt = os.path.getmtime
seq = [mt(os.path.join(recRoot, 'RECEIPT.mat')), mt(os.path.join(recRoot, 'ADMIT_soft1_S10.mat')), mt(os.path.join(runRoot, 'soft1', 'S10', 'MESH.mat')),
       mt(os.path.join(runRoot, 'soft1', 'S10', 'SOLUTION.mat')), mt(os.path.join(runRoot, 'soft1', 'S10', 'STATE.mat')), mt(os.path.join(runRoot, 'soft1', 'TERMINAL.mat')), mt(summ)]
chk('ordering', all(a_ <= b_ for a_, b_ in zip(seq[:-1], seq[1:])), [s_ - seq[0] for s_ in seq])

# ------------------------------------------------------------------ 9 scientific comparison (original H/stiff13/soft2 S10, soft1 history)
cases = ['H', 'stiff13', 'soft2', 'soft1']
sci = {'common_s_mm': 65.4, 'E_matrix_MPa': E_MPa, 'note': 'H S10 is the ORIGINAL LP2-A3 record (not the LP2-B1-EQ re-solve)'}
H10 = hist['H'][10]
assert H10['path'].endswith('run_lp2a3_s9_s11_v1/H/S10/STATE.mat')
PH = raw('hist_H_S10_poly'); tH = (PH[-1] - PH[-2]) / np.linalg.norm(PH[-1] - PH[-2]); nH = np.array([-tH[1], tH[0]])
tab = {}
for c in cases:
    e = hist[c][10]; Pc = raw(f'hist_{c}_S10_poly'); tipc = Pc[-1]; tc = (Pc[-1] - Pc[-2]) / np.linalg.norm(Pc[-1] - Pc[-2])
    Gc = (e['KI'] ** 2 + e['KII'] ** 2) / E_MPa; GH = (H10['KI'] ** 2 + H10['KII'] ** 2) / E_MPa; thc, _, _ = mts(e['KI'], e['KII'])
    dcc = np.linalg.norm(cen - tipc, axis=1)
    tab[c] = {'mask': e['mask'], 'ratio': e['ratio'], 'path': e['path'], 'tip_mm': tipc.tolist(), 'KI': e['KI'], 'KII': e['KII'], 'KIIoverKI': e['KII'] / e['KI'],
              'J': e['J'], 'G': Gc, 'G_recorded': e['G'], 'F_G': Gc / GH - 1, 'MTS_deg': math.degrees(thc), 'MTS_recorded_deg': e['MTS_deg'],
              'heading_deg': math.degrees(math.atan2(tc[1], tc[0])), 'offsetFromH_mm': float(np.linalg.norm(tipc - PH[-1])),
              'signedLateralOffsetFromH_mm': float((tipc - PH[-1]) @ nH), 'alongOffsetFromH_mm': float((tipc - PH[-1]) @ tH),
              'tipToRingCircle_mm': (dcc - geo['ringR_mm']).tolist(), 'compliance_mm_per_N': e['compliance_mm_per_N']}
sci['S10'] = tab
evo = {}
for c in cases:
    rows = []
    for k in range(11):
        e, h = hist[c][k], hist['H'][k]
        Gc = (e['KI'] ** 2 + e['KII'] ** 2) / E_MPa; GH = (h['KI'] ** 2 + h['KII'] ** 2) / E_MPa
        Pc = raw(f'hist_{c}_S{k}_poly'); Phk = raw(f'hist_H_S{k}_poly'); tk = (Phk[-1] - Phk[-2]) / np.linalg.norm(Phk[-1] - Phk[-2]); nk = np.array([-tk[1], tk[0]])
        thc, _, _ = mts(e['KI'], e['KII'])
        rows.append({'state': k, 's_mm': e['arc_mm'], 'G': Gc, 'F_G': Gc / GH - 1, 'KIIoverKI': e['KII'] / e['KI'], 'MTS_deg': math.degrees(thc),
                     'lateralOffsetFromH_mm': float((Pc[-1] - Phk[-1]) @ nk), 'tipToRing1Circle_mm': float(np.linalg.norm(cen[0] - Pc[-1]) - geo['ringR_mm'])})
    evo[c] = rows
sci['evolution'] = evo
f1 = [r['F_G'] for r in evo['soft1']]
sci['soft1_F_G_increments'] = [f1[k + 1] - f1[k] for k in range(10)]
sci['soft1_F_G_S9_to_S10'] = {'S9': f1[9], 'S10': f1[10], 'change': f1[10] - f1[9], 'relativeChange': f1[10] / f1[9] - 1}
sci['G_increase_S9_to_S10'] = {c: hist[c][10]['G'] / hist[c][9]['G'] - 1 for c in cases}
out = {'schema': 'NewMetacomp.G2.LP2B1S10.IndependentAudit.v1', 'pass': not problems, 'problems': problems, 'checks': checks, 'detail': detail,
       'outcome': 'ACCEPTED_INDEPENDENTLY_CONFIRMED' if not problems else 'VERIFY_HOLD', 'physicalSolvesAttempted': 1, 'physicalSolvesCompleted': 1, 'admissions': 1,
       'entryInvocations': counts['entryCalls'], 'goFileSHA256': goSha, 'recurrence': recur, 'science': sci}
assert not os.path.exists(OUT), OUT
json.dump(out, open(OUT, 'w', encoding='utf-8', newline='\n'), indent=1, default=lambda o: o.item() if hasattr(o, 'item') else str(o))
print('AUDIT', 'PASS' if not problems else 'VERIFY_HOLD', f'{sum(checks.values())}/{len(checks)}', problems)
