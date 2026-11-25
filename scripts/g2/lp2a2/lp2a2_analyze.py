"""LP2-A2 qualification analysis (read-only): WP1 diagnosis of the old mesher, WP4 qualification
summary of the paired-bank mesher, WP6 continuation-ceiling facts.
usage: python -I scripts/g2/lp2a2/lp2a2_analyze.py <qualification.json> <testset.json> <out.json>"""
import json, sys, statistics as st
Q = json.load(open(sys.argv[1], encoding='utf-8')); T = json.load(open(sys.argv[2], encoding='utf-8'))
rows = Q['rows']; trow = {r['id']: r for r in T['rows']}
def L(x): return x if isinstance(x, list) else [x]
out = {'schema': 'NewMetacomp.G2.LP2A2.QualificationSummary.v1', 'testSetSHA256': Q['testSetSHA256'], 'physicalSolves': 0}
# ---------------- group summary
groups = {}
for r in rows:
    g = r['group']; d = groups.setdefault(g, {'rows': 0, 'guard': 0, 'newPass': 0, 'oldPass': 0, 'newFailNonGuard': [], 'oldFailNonGuard': 0})
    d['rows'] += 1
    if r['guardRow']:
        d['guard'] += 1; continue
    d['newPass'] += bool(r['new'].get('pass')); d['oldPass'] += bool(r['old'].get('pass'))
    if not r['new'].get('pass'): d['newFailNonGuard'].append(r['id'])
    if not r['old'].get('pass'): d['oldFailNonGuard'] += 1
out['groups'] = groups
# ---------------- guard rows: both meshers must stop at admissibility
out['guardRows'] = [{'id': r['id'], 'newStage': r['new'].get('stage'), 'oldStage': r['old'].get('stage'), 'newMessage': r['new'].get('message'),
                     'tipToRingCircle_mm': r['tipToRingCircle_mm']} for r in rows if r['guardRow']]
# ---------------- new mesher: failures and metrics
nf = []
for r in rows:
    n = r['new']
    if r['guardRow'] or n.get('pass'): continue
    nf.append({'id': r['id'], 'stage': n.get('stage'), 'message': n.get('message'), 'auditError': n.get('auditError'), 'auditFailed': n.get('auditFailed'),
               'pairingFailed': n.get('pairing', {}).get('failedGates'), 'phaseMasks': n.get('phaseMasks'), 'ringPolygons': n.get('ringPolygons'),
               'tipToRingCircle_mm': r['tipToRingCircle_mm'], 'polylineToRingCircle_mm': r['polylineToRingCircle_mm'], 'vertices': r['vertices']})
out['newFailures'] = nf
P = [r for r in rows if not r['guardRow'] and r['new'].get('stage') == 'KINKED_PROTECTED_MESH_JOIN_PASS']
def rng(key, f):
    v = [f(r) for r in P]; v = [x for x in v if x is not None]
    return [min(v), max(v)] if v else None
ex = lambda r, k: r['new'].get('exterior', {}).get(k)
pm = lambda r, k: r['new'].get('pairing', {}).get('metrics', {}).get(k)
out['newJoinedRows'] = len(P)
out['newPairingPass'] = sum(1 for r in P if r['new'].get('pairing', {}).get('pass'))
out['newAuditPass'] = sum(1 for r in P if r['new'].get('auditPass'))
out['newMetrics'] = {
 'T3': rng('T3', lambda r: r['new'].get('T3')), 'T6nodes': rng('T6', lambda r: r['new'].get('T6nodes')),
 'minAngle_deg': rng('a', lambda r: r['new'].get('minAngle_deg')), 'maxNeighborRatio': rng('q', lambda r: r['new'].get('maxNeighborRatio')),
 'minEdge_mm': rng('e', lambda r: pm(r, 'minEdge_mm')), 'minBankEdge_mm': rng('b', lambda r: pm(r, 'minBankEdge_mm')),
 'pairsT6': rng('p', lambda r: pm(r, 'pairsT6')), 'pairsT3': rng('p3', lambda r: pm(r, 'pairsT3')),
 'unmatchedOnCrack': rng('u', lambda r: pm(r, 'unmatchedOnCrack')), 'maxPairDistanceAfterCollapse_mm': rng('d', lambda r: pm(r, 'maxPairDistance_mm')),
 'seedMaxDeviation_mm': rng('s', lambda r: ex(r, 'seedMaxDeviation_mm')), 'seedStationMismatchRegular_mm': rng('m', lambda r: ex(r, 'seedStationMismatchRegular_mm')),
 'seedStationMismatchForced_mm': rng('f', lambda r: ex(r, 'seedStationMismatchForced_mm')), 'guideCrossingPairs': rng('g', lambda r: ex(r, 'guideCrossingPairs')),
 'minSeedSpacing_mm': rng('ms', lambda r: ex(r, 'minSeedSpacing_mm')), 'pairCollapseResidual_mm': rng('c', lambda r: ex(r, 'pairCollapseResidual_mm')),
 'joinSeconds': rng('j', lambda r: r['new'].get('joinSeconds')), 'auditSeconds': rng('as', lambda r: r['new'].get('auditSeconds')),
 'memUsedMATLAB_GiB': rng('mem', lambda r: r['new'].get('memUsedMATLAB_GiB'))}
out['newPhaseMasksAllPass'] = sum(1 for r in P if r['new'].get('phaseMasks') and all(r['new']['phaseMasks'].values()))
out['newQCollarPass'] = sum(1 for r in P if r['new'].get('qCollarPass'))
# ---------------- old mesher: reproduction and WP1 diagnosis
rep = []
for r in rows:
    if r['group'] != 'C1': continue
    t = trow[r['id']]['source']
    o = r['old']; same = (bool(o.get('pass')) == bool(t['scanPass'])) and (o.get('pass') or o.get('message') == t['scanDetail'])
    rep.append({'id': r['id'], 'scanPass': t['scanPass'], 'oldPass': o.get('pass'), 'identicalOutcomeAndMessage': same})
out['oldReproducesScan'] = {'rows': len(rep), 'identical': sum(1 for x in rep if x['identicalOutcomeAndMessage']), 'differences': [x for x in rep if not x['identicalOutcomeAndMessage']]}
A = [r for r in rows if r['group'] == 'A']
out['groupA_archived'] = [{'id': r['id'], 'oldRerunIdenticalX3T3': r['old'].get('archived', {}).get('oldRerunIdenticalX3T3'), 'archivedT3': r['old'].get('archived', {}).get('T3'),
                           'newT3': r['new'].get('T3'), 'archivedBankNodesT6': r['old'].get('archived', {}).get('bankNodesT6'), 'newBankNodesT6': r['new'].get('pairing', {}).get('metrics', {}).get('bankNodesUL'),
                           'archivedLipStationMismatch_mm': r['old'].get('archived', {}).get('lipStationMismatch_mm'), 'newForcedMismatch_mm': ex(r, 'seedStationMismatchForced_mm'),
                           'newMinAngle_deg': r['new'].get('minAngle_deg'), 'oldMinAngle_deg': r['old'].get('minAngle_deg'), 'newMaxRatio': r['new'].get('maxNeighborRatio'), 'oldMaxRatio': r['old'].get('maxNeighborRatio')} for r in A]
fails = [r for r in rows if not r['guardRow'] and not r['old'].get('pass') and r['old'].get('diagnosis')]
diag = {'failures': len(fails), 'allHOLD_LIP_STATIONS': all('HOLD_LIP_STATIONS' in (r['old'].get('message') or '') for r in fails)}
first, fewerU, dTip, lenOK, gtSame, nBad, kinkBad, kinkAll, dLbad, dLall, segIdx = [], 0, [], [], 0, [], [], [], [], [], []
for r in fails:
    d = r['old']['diagnosis']; fs = L(d['failingSegments']); first.append(d['firstFailingSegment']); fewerU += bool(d['fewerOnUpper']); nBad.append(len(fs))
    dist = L(d['distanceSegmentEndToTip_mm']); turn = L(d['kinkTurn_deg']); dl = L(d['upperMinusLowerLength_mm'])
    for k in fs:
        dTip.append(dist[k - 1]); dLbad.append(dl[k - 1]); segIdx.append(k)
        kinkBad.append(max(abs(turn[k - 2]) if k >= 2 and k - 2 < len(turn) else 0, abs(turn[k - 1]) if k - 1 < len(turn) else 0))
    for k in range(2, d['nSegments']):
        kinkAll.append(max(abs(turn[k - 2]) if k - 2 < len(turn) else 0, abs(turn[k - 1]) if k - 1 < len(turn) else 0)); dLall.append(dl[k - 1])
    gtSame += any(k == d.get('tipGuideCrossingSegment') for k in fs)
nNoCount = first.count(None); first = [k for k in first if k is not None]
diag['failuresWithEqualPerSegmentCounts'] = nNoCount
diag['equalCountFailureMessages'] = [r['id'] + ': ' + r['old'].get('message', '') for r in fails if r['old']['diagnosis']['firstFailingSegment'] is None]
diag.update({'firstFailingSegment': {str(k): first.count(k) for k in sorted(set(first))}, 'failingSegmentIndex': {str(k): segIdx.count(k) for k in sorted(set(segIdx))},
             'fewerNodesOnUpperBank': fewerU, 'failingSegmentsPerGeometry': [min(nBad), max(nBad)] if nBad else None,
             'distanceFailingSegmentEndToTip_mm': [min(dTip), max(dTip)] if dTip else None,
             'failingSegmentContainsTipGuideCrossing': gtSame,
             'kinkTurnAtFailingSegment_deg': [min(kinkBad), st.median(kinkBad), max(kinkBad)] if kinkBad else None,
             'kinkTurnAtAllInteriorSegments_deg': [min(kinkAll), st.median(kinkAll), max(kinkAll)] if kinkAll else None,
             'upperMinusLowerLengthFailing_mm': [min(dLbad), max(dLbad)] if dLbad else None, 'upperMinusLowerLengthAll_mm': [min(dLall), max(dLall)] if dLall else None})
byN = {}
for r in rows:
    if r['guardRow']: continue
    b = byN.setdefault(r['vertices'], [0, 0, 0]); b[0] += 1; b[1] += bool(r['old'].get('pass')); b[2] += bool(r['new'].get('pass'))
diag['passByVertices'] = {str(k): {'rows': v[0], 'oldPass': v[1], 'newPass': v[2]} for k, v in sorted(byN.items())}
out['wp1Diagnosis'] = diag
# ---------------- WP6: continuation facts from the predictor continuations
cont = {}
for r in rows:
    if r['group'] not in ('C2', 'C3'): continue
    key = r['id'].rsplit('_S', 1)[0]; c = cont.setdefault(key, {'admissibleStates': [], 'newPass': [], 'guard': None})
    if r['guardRow']:
        c['guard'] = {'state': r['state'], 'stage': r['new'].get('stage'), 'message': r['new'].get('message'), 'tipToRingCircle_mm': r['tipToRingCircle_mm']}
    else:
        c['admissibleStates'].append(r['state']); c['newPass'].append(bool(r['new'].get('pass')))
        c['lastTipToRingCircle_mm'] = r['tipToRingCircle_mm']
out['wp6Continuations'] = cont
open(sys.argv[3], 'w', encoding='utf-8', newline='\n').write(json.dumps(out, indent=1, ensure_ascii=False) + '\n')
print(json.dumps({k: out[k] for k in ('groups', 'newJoinedRows', 'newPairingPass', 'newAuditPass', 'newPhaseMasksAllPass', 'newQCollarPass', 'oldReproducesScan')}, indent=1))
print(json.dumps(out['newMetrics'], indent=0))
print(json.dumps(out['wp1Diagnosis'], indent=0)[:3000])
for f in nf: print('NEW FAIL', f['id'], f['stage'], f['auditError'], f['tipToRingCircle_mm'], f['polylineToRingCircle_mm'], f.get('ringPolygons'))
for k, c in cont.items(): print('WP6', k, c['admissibleStates'], c['newPass'], c['guard'])
