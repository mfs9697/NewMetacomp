"""Independent (non-MATLAB) audit of the LP2-A2 equivalence campaign records. Read-only.
Python recomputes: file SHA-256 of every record, manifest links, stored SHA links (SOLUTION/PHASE/COMPARISON), identity,
and from the stored K blocks (dumped by MATLAB from SOLUTION.mat): K_I, K_II, G, J, MTS, COD-EDI, EDI spread/4x4, compliance,
active area, the criteria C1-C7, C11 and the contrast. C8 (opening), C9 (chords) and C10 (S9 predictor) rest on mesh/forecast
functions and are checked here from the stored metrics against the policy tolerances; the MATLAB replay (g2_lp2a2_eq_verify)
reproduces them from the stored meshes. Nothing is solved.
usage: python -I lp2a2_eq_audit.py <execRepo> <AUDIT_DUMP.json> <CAMPAIGN.json> <activationHead> <approvedHead> <out.json>
Record set per solve (written by g2_lp2a2_eq_run): MESH.mat, PHASE.mat (+manifest), SOLUTION.mat (+manifest), COMPARISON.json;
MESH.mat has no manifest and is bound by the SHA links in SOLUTION, PHASE and COMPARISON."""
import hashlib, json, math, os, sys
ex, dump, camp, ahead, approved, out = sys.argv[1:7]
pol = json.load(open(os.path.join(ex, 'matlab', 'g2', 'lp2a2', 'G2_LP2A2_EQ_POLICY_v1.json'), encoding='utf-8'))
tol = pol['tolerances']; E = tol['E_MPa']
A = json.load(open(dump, encoding='utf-8')); W = json.load(open(camp, encoding='utf-8')) if os.path.isfile(camp) else None


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def mts(KI, KII):
    return math.degrees(2 * math.atan2(-2 * KII, KI + math.hypot(KI, math.sqrt(8) * KII)))


def spread(K):
    e = K['EDI_all']; e = e if isinstance(e[0], list) else [e]
    return max(max(r[c] for r in e) - min(r[c] for r in e) for c in (0, 1)) / math.hypot(K['KI'], K['KII'])


def quad(K):
    q = K['EDI4x4']
    return max(abs(q[0] - K['KI']), abs(q[1] - K['KII'])) / math.hypot(K['KI'], K['KII'])


def close(a, b, rel=1e-9, ab=1e-14):
    return abs(a - b) <= max(ab, rel * max(abs(a), abs(b)))


ids = [s['id'] for s in pol['solves']]
expectedFiles = sorted(['MESH.mat', 'PHASE.mat', 'PHASE.mat.manifest.json', 'SOLUTION.mat', 'SOLUTION.mat.manifest.json', 'COMPARISON.json'])
root = os.path.join(ex, pol['outputRoot'])
folders = sorted(os.listdir(root)) if os.path.isdir(root) else []
res = {'schema': 'NewMetacomp.G2.LP2A2.EQ.IndependentAudit.v1', 'activationHead': ahead, 'approvedHead': approved,
       'foldersOnDisk': folders, 'unexpectedFolders': [f for f in folders if f not in ids], 'solves': {}, 'problems': []}
prefix = []
for sid in ids:
    if sid in folders:
        prefix.append(sid)
    else:
        break
res['attemptedPrefix'] = prefix
res['foldersAreContiguousPrefix'] = sorted(folders) == sorted(prefix)
res['attempts'] = len(folders)
passes = 0; completed = 0; KN = {}; KA = {}; metricsAll = {}
for k, s in enumerate(pol['solves']):
    sid = s['id']; key = sid.replace('-', '_'); r = {'present': sid in folders}
    res['solves'][sid] = r
    if not r['present']:
        continue
    sd = os.path.join(root, sid); files = sorted(os.listdir(sd))
    r['files'] = files; r['filesExactlyExpected'] = files == expectedFiles
    D = A['solves'].get(key, {})
    if not r['filesExactlyExpected']:
        res['problems'].append(f'{sid}: incomplete or unexpected files {files}')
        continue
    completed += 1
    h = {n: fsha(os.path.join(sd, n)) for n in files}; r['sha256'] = h
    r['manifestsMatchFiles'] = all(
        json.load(open(os.path.join(sd, n + '.manifest.json')))['SHA256'].lower() == h[n] and   # manifests store upper-case hex
        json.load(open(os.path.join(sd, n + '.manifest.json')))['bytes'] == os.path.getsize(os.path.join(sd, n)) for n in ('PHASE.mat', 'SOLUTION.mat'))
    Cm = json.load(open(os.path.join(sd, 'COMPARISON.json'), encoding='utf-8'))
    So = D['solution']; Ph = D['phase']
    arch = pol['pins']['archivedS8'][s['caseId']]
    abase = os.path.join(ex, 'outputs', 'g2_lp2a_paths_v1', 'run_lp2a_s5_s8_v1', s['caseId'])
    chk = {
        'solutionMeshLink': So['meshSHA256'] == h['MESH.mat'], 'solutionPhaseLink': So['phaseSHA256'] == h['PHASE.mat'],
        'phaseMeshLink': Ph['meshSHA256'] == h['MESH.mat'], 'comparisonSolutionLink': Cm['solutionSHA256'] == h['SOLUTION.mat'],
        'comparisonMeshLink': Cm['meshSHA256'] == h['MESH.mat'],
        'comparisonArchivedSolution': Cm['archivedSolutionSHA256'] == arch['SOLUTION'] == fsha(os.path.join(abase, 'S8', 'SOLUTION.mat')),
        'archivedStateMeshPhaseTerminal': all(fsha(os.path.join(abase, 'S8', n + '.mat')) == arch[n] for n in ('STATE', 'MESH', 'PHASE')) and fsha(os.path.join(abase, 'TERMINAL.mat')) == arch['TERMINAL'],
        'tokenEqualsStored': So['token'] == W['token'] if W else None,
        'approvedHead': So['approvedHead'] == approved, 'activationHead': So['activationHead'] == ahead,
        'solveIdCaseId': So['solveId'] == sid and So['caseId'] == s['caseId'] and Ph['solveId'] == sid and Ph['caseId'] == s['caseId'] and Cm['solveId'] == sid and Cm['caseId'] == s['caseId'],
        'maskIsPolicy': [int(x) for x in Ph['mask']] == s['mask'] and [int(x) for x in D['archivedState']['mask']] == s['mask'] and [int(x) for x in D['policyMask']] == s['mask'],
        'ratioIsPolicy': D['archivedState']['ratio'] == s['ratio'] == D['policyRatio'],
        'archivedStateIndex8': D['archivedState']['stateIndex'] == 8,
        'polylineBitwiseEqualsArchived': bool(D['newMesh']['polylineBitwiseEqualsArchived']),
        'polylineEqualsArchivedJSON': D['newMesh']['crackPolyline'] == D['archivedState']['polyline_mm'],
        'tipTangentEqualsArchived': D['newMesh'].get('tipTangentEqualsArchived', None),
        'seedRung1': D['newMesh'].get('seedRung', None) == pol['meshFamily']['requiredRung'] if 'seedRung' in D['newMesh'] else None,
        'phaseOwnerLabelCounts': len(Ph['ownerCounts']) == 4 and sum(Ph['ownerCounts']) == Ph['nOwner'] == sum(Ph['labelCounts']) == D['newMesh']['T3'],
        'phaseLabelsMatchMask': (lambda L, O, mk: all(O[i + 1] >= 0 for i in range(3)) and L[1] == sum(O[i + 1] for i in range(3) if mk[i]))(Ph['labelCounts'], Ph['ownerCounts'], s['mask']),
        'memoryGateAt7': bool(So['memoryGate']['pass']) and So['memoryGate']['minGiB'] == 7,
        'newSolverGatesPass': bool(D['K_new']['pass']), 'archivedSolverGatesPass': bool(D['K_archived']['pass'])}
    r['checks'] = chk
    r['newMeshCounts'] = D['newMesh']['T3'], D['newMesh']['X6'], D['newMesh']['upperBankT6'], D['newMesh']['lowerBankT6']
    r['archivedMeshCounts'] = D['archivedMesh']['T3'], D['archivedMesh']['X6'], D['archivedMesh']['upperBankT6'], D['archivedMesh']['lowerBankT6']
    r['phaseCounts'] = {'newOwner': Ph['ownerCounts'], 'newLabels': Ph['labelCounts'], 'archivedOwner': D['phaseArchived']['ownerCounts'], 'archivedLabels': D['phaseArchived']['labelCounts']}
    # ---- recompute scalar criteria from the stored K blocks
    Kn = D['K_new']; Ka = D['K_archived']; KN[s['caseId']] = Kn; KA[s['caseId']] = Ka
    Keq = math.hypot(Ka['KI'], Ka['KII']); Gn = (Kn['KI'] ** 2 + Kn['KII'] ** 2) / E; Ga = (Ka['KI'] ** 2 + Ka['KII'] ** 2) / E
    m = {}
    m['dKI_overKeq'] = (Kn['KI'] - Ka['KI']) / Keq; m['dKII_overKeq'] = (Kn['KII'] - Ka['KII']) / Keq
    m['dKIIoverKI'] = Kn['KII'] / Kn['KI'] - Ka['KII'] / Ka['KI']
    m['dG_rel'] = Gn / Ga - 1; m['dJ_rel'] = Kn['J'] / Ka['J'] - 1; m['newJoverGminus1'] = Kn['J'] / Gn - 1
    m['dMTS_deg'] = mts(Kn['KI'], Kn['KII']) - mts(Ka['KI'], Ka['KII'])
    cn = max(abs(Kn['KI_COD'] - Kn['KI']), abs(Kn['KII_COD'] - Kn['KII'])) / math.hypot(Kn['KI'], Kn['KII'])
    ca = max(abs(Ka['KI_COD'] - Ka['KI']), abs(Ka['KII_COD'] - Ka['KII'])) / Keq
    m['newCODminusEDI_rel'] = cn; m['archivedCODminusEDI_rel'] = ca; m['dCODminusEDI'] = cn - ca
    m['newPathSpread_rel'] = spread(Kn); m['archivedPathSpread_rel'] = spread(Ka); m['newQuad4x4_rel'] = quad(Kn); m['archivedQuad4x4_rel'] = quad(Ka)
    m['dCompliance_rel'] = Kn['compliance_mm_per_N'] / Ka['compliance_mm_per_N'] - 1
    m['dActiveArea_rel'] = (Kn['activeArea_mm2'] - Ka['activeArea_mm2']) / max(Ka['activeArea_mm2'], 1)
    sn = Cm['S9tipNew_mm']; sa = Cm['S9tipArchived_mm']
    m['S9tipDisplacement_mm'] = math.hypot(sn[0] - sa[0], sn[1] - sa[1])
    st = Cm['metrics']
    r['recomputedMetrics'] = m
    r['metricsAgreeWithStored'] = {kk: close(vv, st[kk]) for kk, vv in m.items()}
    c = {}
    c['C1_KI'] = abs(m['dKI_overKeq']) <= tol['KI_overKeq']; c['C2_KII'] = abs(m['dKII_overKeq']) <= tol['KII_overKeq']
    c['C3_KIIoverKI'] = abs(m['dKIIoverKI']) <= tol['KIIoverKI_abs']
    c['C4_G_J'] = abs(m['dG_rel']) <= tol['G_rel'] and abs(m['dJ_rel']) <= tol['J_rel'] and abs(m['newJoverGminus1']) <= tol['newJoverGminus1']
    c['C5_MTS'] = abs(m['dMTS_deg']) <= tol['MTS_deg']
    c['C6_COD_EDI'] = cn <= tol['newCODminusEDI_gate'] and abs(m['dCODminusEDI']) <= tol['dCODminusEDI']
    c['C7_EDI_spread_quadrature'] = m['newPathSpread_rel'] <= max(tol['spreadFloor'], tol['spreadFactor'] * m['archivedPathSpread_rel']) and m['newQuad4x4_rel'] <= max(tol['quadFloor'], tol['quadFactor'] * m['archivedQuad4x4_rel'])
    c['C8_crackOpening'] = st['openingNearTipRel'] <= tol['openingNearTipRel'] and st['openingWholeCrackRel'] <= tol['openingWholeCrackRel']
    c['C9_phaseActivation_partial_noChords'] = bool(Kn['pass']) and abs(m['dActiveArea_rel']) <= tol['activeArea_rel']
    c['C10_S9predictor'] = m['S9tipDisplacement_mm'] <= tol['S9tipDisplacement_mm']
    c['C11_compliance'] = abs(m['dCompliance_rel']) <= tol['compliance_rel']
    r['recomputedCriteria'] = c
    storedC = Cm['criteria']
    r['criteriaAgreeWithStored'] = {kk: (c[kk] == bool(storedC[kk])) for kk in storedC if kk in c}
    r['storedCriteriaPassed'] = {kk: bool(v) for kk, v in storedC.items()}
    r['storedPass'] = bool(Cm['pass']); r['storedFailed'] = Cm['failed']
    r['signed'] = {'new': {'KI': Kn['KI'], 'KII': Kn['KII'], 'G': Gn, 'J': Kn['J'], 'MTS_deg': mts(Kn['KI'], Kn['KII'])},
                   'archived': {'KI': Ka['KI'], 'KII': Ka['KII'], 'G': Ga, 'J': Ka['J'], 'MTS_deg': mts(Ka['KI'], Ka['KII'])}}
    if Cm['pass']:
        passes += 1
    metricsAll[sid] = m
    allchk = [v for v in chk.values() if v is not None]
    r['recordPass'] = r['manifestsMatchFiles'] and all(allchk) and all(r['metricsAgreeWithStored'].values()) and all(r['criteriaAgreeWithStored'].values())
    if not r['recordPass']:
        res['problems'].append(f'{sid}: audit checks failed: ' + str([k for k, v in chk.items() if v is False]) + str([k for k, v in r['metricsAgreeWithStored'].items() if not v]) + str([k for k, v in r['criteriaAgreeWithStored'].items() if not v]))
res['completedRecordSets'] = completed; res['passingComparisons'] = passes
# ---- contrast recomputed independently from the stored K blocks (only when all four exist)
if len(KN) == 4:
    Xs = ['stiff13', 'soft2', 'soft1']; G = lambda K: K['KI'] ** 2 + K['KII'] ** 2
    FN = [G(KN[x]) / G(KN['H']) - 1 for x in Xs]; FA = [G(KA[x]) / G(KA['H']) - 1 for x in Xs]
    TN = [mts(KN[x]['KI'], KN[x]['KII']) - mts(KN['H']['KI'], KN['H']['KII']) for x in Xs]
    TA = [mts(KA[x]['KI'], KA[x]['KII']) - mts(KA['H']['KI'], KA['H']['KII']) for x in Xs]
    order = lambda v: sorted(range(3), key=lambda i: v[i])
    sg = lambda v: [(x > 0) - (x < 0) for x in v]
    ct = {'cases': Xs, 'FG_new': FN, 'FG_archived': FA, 'dFG': [a - b for a, b in zip(FN, FA)], 'dTheta_new_deg': TN, 'dTheta_archived_deg': TA,
          'ddTheta_deg': [a - b for a, b in zip(TN, TA)]}
    ct['criteria'] = {'FG_within': max(abs(x) for x in ct['dFG']) <= tol['contrast_FG_abs'], 'FG_signs': sg(FN) == sg(FA), 'FG_order': order(FN) == order(FA),
                      'MTS_contrast_within': max(abs(x) for x in ct['ddTheta_deg']) <= tol['contrast_MTS_deg']}
    ct['pass'] = all(ct['criteria'].values())
    if W and W.get('contrast'):
        wc = W['contrast']; ct['agreesWithWrapper'] = all(close(a, b) for a, b in zip(ct['dFG'], wc['dFG'])) and all(close(a, b) for a, b in zip(ct['ddTheta_deg'], wc['ddTheta_deg'])) and bool(wc['pass']) == ct['pass']
    res['contrast'] = ct
res['wrapper'] = {k: W.get(k) for k in ('campaignId', 'outcome', 'stoppedAt', 'reason', 'solvesCalled')} if W else None
res['allRecordSetsAudited'] = all(res['solves'][i].get('recordPass', False) for i in prefix) and len(prefix) == completed
res['verdictAudit'] = ('EQUIVALENT_CONFIRMED' if (completed == 4 and passes == 4 and not res['problems'] and res['foldersAreContiguousPrefix'] and not res['unexpectedFolders']
                                                   and res['allRecordSetsAudited'] and res.get('contrast', {}).get('pass') and W and W.get('outcome') == 'EQUIVALENT') else 'NOT_CONFIRMED')
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('attempts', res['attempts'], 'completed', completed, 'passing', passes, 'problems', len(res['problems']), 'verdict', res['verdictAudit'])
