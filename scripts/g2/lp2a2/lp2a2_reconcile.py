"""LP2-A2 supplementary accounting (read-only): populations, paired outcomes, ladder usage, remaining
failures, forced-pair maxima. usage:
python -I scripts/g2/lp2a2/lp2a2_reconcile.py <evidenceDir> <out.json>
evidenceDir holds LP2A2_TEST_SET.json, attempt1/LP2A2_MESH_QUALIFICATION_ATTEMPT1.json,
attempt2/LP2A2_MESH_QUALIFICATION_ATTEMPT2.json, attempt2/LP2A2_SPACING_EXPLORATION.json,
supplement/LP2A2_SUPPLEMENT.json"""
import json, os, sys
E = sys.argv[1]; J = lambda p: json.load(open(os.path.join(E, p), encoding='utf-8'))
TS = J('LP2A2_TEST_SET.json'); A1 = J('attempt1/LP2A2_MESH_QUALIFICATION_ATTEMPT1.json'); A2 = J('attempt2/LP2A2_MESH_QUALIFICATION_ATTEMPT2.json')
X = J('attempt2/LP2A2_SPACING_EXPLORATION.json'); S = J('supplement/LP2A2_SUPPLEMENT.json')
L = lambda x: x if isinstance(x, list) else [x]
masks = {'H': [0, 0, 0], 'stiff13': [1, 0, 1], 'soft2': [0, 1, 0], 'soft1': [1, 0, 0]}
r1 = {r['id']: r for r in A1['rows']}; r2 = {r['id']: r for r in A2['rows']}; sp = {r['id']: r for r in S['rows']}
ids = [r['id'] for r in TS['rows']]; guard = {r['id'] for r in TS['rows'] if r['guardRow']}; ng = [i for i in ids if i not in guard]
grp = {r['id']: r['group'] for r in TS['rows']}
joined = lambda n: n.get('stage') == 'KINKED_PROTECTED_MESH_JOIN_PASS'
O = {'schema': 'NewMetacomp.G2.LP2A2.Reconciliation.v1', 'physicalSolves': 0}
def tally(R, key):
    t = {'geometries': len(ng), 'joined': 0, 'pairingPass': 0, 'fullAuditPass': 0, 'finalPass': 0, 'finalHOLD': 0}
    for i in ng:
        n = R[i][key]
        if key == 'new':
            if joined(n): t['joined'] += 1
            if n.get('pairing', {}).get('pass'): t['pairingPass'] += 1
            if n.get('auditPass'): t['fullAuditPass'] += 1
        t['finalPass' if n.get('pass') else 'finalHOLD'] += 1
    return t
oldSame = all(bool(r1[i]['old'].get('pass')) == bool(r2[i]['old'].get('pass')) and r1[i]['old'].get('message') == r2[i]['old'].get('message') for i in ids)
rungAttempts = sum(len(L(r2[i]['new'].get('ladder', []))) for i in ng)
O['accounting'] = {
 'uniqueTestGeometries': {'total': len(ids), 'nonGuard': len(ng), 'guardRows': len(guard), 'byGroup': {g: sum(1 for i in ids if grp[i] == g) for g in ('A', 'B', 'C1', 'C2', 'C3')}},
 'originalMesher': {'attemptsPerRun': len(ids), 'runs': 2, 'identicalOutcomesBetweenRuns': oldSame, **{k: v for k, v in tally(r1, 'old').items() if k in ('geometries', 'finalPass', 'finalHOLD')}},
 'newAttempt1': tally(r1, 'new'),
 'spacingExploration': {'geometries': len({r['id'] for r in X['rows']}), 'spacings': X['spacings'], 'meshAttempts': len(X['rows']),
                        'passBySpacing': {str(s): sum(1 for r in X['rows'] if r['seedSpacing_mm'] == s and r['pass']) for s in X['spacings']}, 'disjointFromTestSet': True},
 'newAttempt2': {**tally(r2, 'new'), 'ladderRungAttempts': rungAttempts},
 'guardRowsBothMeshersStopAtAdmissibility': all('KINK_ADMISSIBILITY' in (r2[i]['new'].get('message') or '') and 'KINK_ADMISSIBILITY' in (r2[i]['old'].get('message') or '') for i in guard)}
# crack-face (lip) failures of the original mesher, by population
lip = [i for i in ng if 'HOLD_LIP_STATIONS' in (r1[i]['old'].get('message') or '')]
O['originalCrackFaceFailures'] = {'total': len(lip), 'byGroup': {g: sum(1 for i in lip if grp[i] == g) for g in ('A', 'B', 'C1', 'C2', 'C3')},
                                  'otherOriginalFailures': [(i, r1[i]['old'].get('message')) for i in ng if not r1[i]['old'].get('pass') and i not in lip]}
def paired(R, pop):
    t = {'oldPass_newPass': 0, 'oldPass_newFail': 0, 'oldFail_newPass': 0, 'oldFail_newFail': 0}
    for i in pop:
        o = bool(R[i]['old'].get('pass')); n = bool(R[i]['new'].get('pass'))
        t[f"old{'Pass' if o else 'Fail'}_new{'Pass' if n else 'Fail'}"] += 1
    return t
c1 = [i for i in ng if grp[i] == 'C1']
O['pairedC1'] = {'attempt1': paired(r1, c1), 'attempt2': paired(r2, c1)}
O['pairedAllNonGuard'] = {'attempt1': paired(r1, ng), 'attempt2': paired(r2, ng)}
O['regressions'] = {'attempt1': [i for i in ng if r1[i]['old'].get('pass') and not r1[i]['new'].get('pass')],
                    'attempt2': [i for i in ng if r2[i]['old'].get('pass') and not r2[i]['new'].get('pass')]}
O['resolved'] = {'attempt1': [i for i in ng if not r1[i]['old'].get('pass') and r1[i]['new'].get('pass')],
                 'attempt2': [i for i in ng if not r2[i]['old'].get('pass') and r2[i]['new'].get('pass')]}
def cat(n):
    if n.get('pass'): return 'PASS'
    m = n.get('message') or ''; st = n.get('stage') or ''
    if joined(n) and not n.get('pairing', {}).get('pass', True): return 'PAIRING'
    if joined(n) and not n.get('auditPass'): return 'PHASE_OR_AUDIT'
    if 'SEED_NOT_HONOURED' in m or 'GUIDE_CROSSING' in m or 'PAIRING' in st: return 'PAIRING'
    if 'LADDER_EXHAUSTED' in st or 'globalMinAngle' in m or 'globalNeighborRatio' in m: return 'QUALITY'
    return st
O['failureCategories'] = {'attempt1': {i: cat(r1[i]['new']) for i in ng if not r1[i]['new'].get('pass')},
                          'attempt2': {i: cat(r2[i]['new']) for i in ng if not r2[i]['new'].get('pass')}}
# ladder usage (attempt 2)
use = {}; rej = {}
for i in ng:
    lad = L(r2[i]['new'].get('ladder', []))
    acc = r2[i]['new'].get('seedRung') if r2[i]['new'].get('pass') or joined(r2[i]['new']) else None
    key = str(acc) if acc and (r2[i]['new'].get('pass') or joined(r2[i]['new'])) else 'none'
    use[key] = use.get(key, 0) + 1
    for s in lad:
        if not (s.get('stage') == 'KINKED_PROTECTED_MESH_JOIN_PASS' and s.get('pairingPass')):
            rej.setdefault(str(s['seedSpacing_mm']), []).append((i, s.get('message')))
O['ladder'] = {'firstAcceptedRungCount': use, 'rejections': rej, 'rungs_mm': [0.45, 0.40, 0.50, 0.35],
               'perGeometry': {i: [{'rung': s['rung'], 'seedSpacing_mm': s['seedSpacing_mm'], 'stage': s['stage'], 'message': s['message'], 'pairingPass': s['pairingPass']} for s in L(r2[i]['new'].get('ladder', []))] for i in ng}}
# remaining failures (attempt 2), with geometry facts
rem = []
for i in ng:
    q = r2[i]
    if q['new'].get('pass'): continue
    rc = q['tipToRingCircle_mm']; h = min(range(3), key=lambda k: rc[k]); m = masks[q['caseId']]
    s = sp.get(i, {})
    rem.append({'id': i, 'group': grp[i], 'caseId': q['caseId'], 'state': q['state'], 'nearestRing': h + 1, 'nearestRingActive': bool(m[h]),
                'tipToRingCircle_mm': rc[h], 'tipGuideClearanceToRing_mm': rc[h] - 15, 'category': cat(q['new']), 'finalStage': q['new'].get('stage'),
                'finalMessage': q['new'].get('message') or q['new'].get('auditError'), 'oldStage': q['old'].get('stage'), 'oldMessage': (q['old'].get('message') or '')[:160],
                'rungs': [{'seedSpacing_mm': w['seedSpacing_mm'], 'stage': w['stage'], 'message': w['message'], 'minAngle_deg': w.get('minAngle_deg'), 'maxNeighborRatio': w.get('maxNeighborRatio'),
                           'minAngleAt': w.get('minAngleAt'), 'maxRatioAt': w.get('maxRatioAt'), 'auditPass': w.get('auditPass'), 'ringPolygons': w.get('ringPolygons')} for w in L(s.get('rungs', []))],
                'oldDetail': s.get('old')})
O['remainingFailures'] = rem
# forced pairs (all accepted meshes of the supplement)
fp = [p for r in S['rows'] if r.get('forcedPairs') for p in L(r['forcedPairs'].get('pairs', []))]
mx = lambda k, f=abs: max(f(p[k]) for p in fp if p.get(k) is not None)
O['forcedPairs'] = {'meshes': sum(1 for r in S['rows'] if r.get('forcedPairs')), 'pairs': len(fp), 'allPass': all(p['pass'] for p in fp),
 'maxStationMismatch_mm': mx('stationMismatch_mm'), 'maxCircleDx_mm': mx('circleDx_mm'), 'maxParametrisationPart_mm': mx('parametrisationPart_mm'),
 'maxAbsPredictedMinusAbsCircleDx_mm': max(abs(abs(p['predictedDx_mm']) - abs(p['circleDx_mm'])) for p in fp), 'maxDsMinusCirclePlusParam_mm': max(abs(p['stationMismatch_mm'] - p['circleDx_mm'] - p['parametrisationPart_mm']) for p in fp), 'maxNativeDistance_mm': mx('nativeDistance_mm'),
 'maxResidualAfterCollapse_mm': mx('residualAfterCollapse_mm'), 'maxMidsideResidual_mm': mx('midsideResidual_mm'),
 'allDistinctIDs': all(p.get('distinctIDs') for p in fp), 'allSameBankIndex': all(p.get('sameBankIndex') for p in fp), 'allInteriorOfSegment': all(p.get('interiorOfSegment') for p in fp),
 'minIncidentMinAngle_deg': min(p['incidentMinAngle_deg'] for p in fp), 'minIncidentArea_mm2': min(p['incidentMinArea_mm2'] for p in fp),
 'distanceToTip_mm': [min(p['distanceToTip_mm'] for p in fp), max(p['distanceToTip_mm'] for p in fp)], 'maxCollapseDisplacement_mm': max(max(p['collapseDisplacementU_mm'], p['collapseDisplacementL_mm']) for p in fp),
 'nodesAtCollapsedPoint': sorted({p['nodesAtCollapsedPoint'] for p in fp}), 'maxAbsTipNormalOffset_mm': mx('tipNormalOffset_mm')}
O['determinism'] = {'rowsRemeshed': len(S['rows']), 'sameRungAndT3': sum(1 for r in S['rows'] if r['deterministic'])}
open(sys.argv[2], 'w', encoding='utf-8', newline='\n').write(json.dumps(O, indent=1, ensure_ascii=False) + '\n')
for k in ('accounting', 'originalCrackFaceFailures', 'pairedC1', 'pairedAllNonGuard', 'regressions', 'failureCategories', 'forcedPairs', 'determinism'):
    print(k, json.dumps(O[k], ensure_ascii=False)[:1500])
print('ladder', O['ladder']['firstAcceptedRungCount'], {k: len(v) for k, v in O['ladder']['rejections'].items()})
for r in rem: print('REM', r['id'], r['category'], r['nearestRing'], r['nearestRingActive'], round(r['tipGuideClearanceToRing_mm'], 3), r['finalMessage'], '| old', r['oldStage'])
