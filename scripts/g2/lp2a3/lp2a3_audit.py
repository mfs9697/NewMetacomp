"""Independent read-only audit of the LP2-A3 campaign records (beyond the controller verifier).
Recomputes from the files: the exact file set (no unexpected files), every manifest, all SHA links and the
parent chain from the pinned S8 states, identity/token/digests, default rung and mesh/pairing/phase audits,
signed SIF and all solver gates, MTS root, G = (KI^2+KII^2)/E, the 4-mm signed-MTS recurrence, the 1-mm
guide-to-every-ring margin, terminal causes and prefixes, and the ledger (receipt, ADMIT order, CLOSED).
usage: python -I lp2a3_audit.py <execRepo> <RECORD_DUMP.json> <approvedHead> <out.json>"""
import hashlib, json, math, os, sys
ex, dump, approved, out = sys.argv[1:5]
P = json.load(open(os.path.join(ex, 'matlab/g2/lp2a3/G2_LP2A3_POLICY_v1.json'), encoding='utf-8'))
A = json.load(open(dump, encoding='utf-8'))
E = P['bvp']['E_MPa']; cen = P['geometry']['centres_mm']; Rr = P['ringProximityGuard']['ringR_mm']; Rg = P['ringProximityGuard']['guideRadius_mm']
ids = [c['id'] for c in P['cases']]; masks = {c['id']: c['mask'] for c in P['cases']}
run = os.path.join(ex, *P['authorization']['runRoot'].split('/')); led = os.path.join(ex, *P['authorization']['ledgerRoot'].split('/'))
prob = []; bad = lambda s: prob.append(s)
def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''): h.update(b)
    return h.hexdigest()
def walk(r):
    H = {}
    for d, _, fs in os.walk(r):
        for n in fs: H[os.path.relpath(os.path.join(d, n), r).replace('\\', '/')] = fsha(os.path.join(d, n))
    return H
def mts(KI, KII): return 2 * math.atan(-2 * KII / (KI + math.hypot(KI, math.sqrt(8) * KII)))
def gap(t): return [math.hypot(t[0] - c[0], t[1] - c[1]) - Rr - Rg for c in cen]
def lst(x): return x if isinstance(x, list) else [x]
Hrun, Hled = walk(run), walk(led)
# ---- manifests
for root, H in ((run, Hrun), (led, Hled)):
    for k in H:
        if k.endswith('.manifest.json'):
            m = json.load(open(os.path.join(root, k), encoding='utf-8')); f = k[:-len('.manifest.json')]
            if f not in H or m['SHA256'].lower() != H[f] or m['bytes'] != os.path.getsize(os.path.join(root, f)): bad(f'manifest {k}')
expected = {'RUN.mat', 'RUN.mat.manifest.json'}
res = {'schema': 'NewMetacomp.G2.LP2A3.IndependentAudit.v1', 'approvedHead': approved, 'cases': {}}
admitted = []; solves_completed = 0; accepted_total = 0
for id in ids:
    C = A['cases'][id]; parent = C['parent']['state']; ph = C['parent']['stateSHA256']
    if ph != P['parents']['S8'][id]['STATE']: bad(f'{id}: parent SHA differs from the S8 pin')
    expected |= {f'{id}/TERMINAL.mat', f'{id}/TERMINAL.mat.manifest.json'}
    St_list = sorted(lst(C['states']), key=lambda S: int(S['folder'][1:])); acc = []; failed = None; minMargin = math.inf; rows = []   # MATLAB dir() order is alphabetical (S10, S11, S9)
    t = parent['tangent']; Ppoly = parent['polyline_mm']; KI, KII = parent['KI'], parent['KII']
    for S in St_list:
        k = int(S['folder'][1:]); admitted.append(f'{id}_S{k}')
        base = f"{id}/{S['folder']}/"
        if 'state' not in S:
            failed = {'stateIndex': k, 'files': S['files'], 'hold': S.get('hold')}
            for f in S['files']: expected.add(base + f)
            continue
        for f in ('MESH.mat', 'PHASE.mat', 'PHASE.mat.manifest.json', 'SOLUTION.mat', 'SOLUTION.mat.manifest.json', 'STATE.mat', 'STATE.mat.manifest.json'): expected.add(base + f)
        st = S['state']; K = S['K']; ok = True
        def chk(c, msg):
            global ok
            if not c: bad(f'{id} S{k}: {msg}')
        hS, hP, hM, hO = Hrun.get(base + 'STATE.mat'), Hrun.get(base + 'PHASE.mat'), Hrun.get(base + 'MESH.mat'), Hrun.get(base + 'SOLUTION.mat')
        chk(S['stateSHA256'].lower() == hS and S['phaseSHA256'].lower() == hP and S['solutionSHA256'].lower() == hO and S['meshFileSHA256'].lower() == hM, 'file hashes differ from the dump')
        chk(st['meshSHA256'].lower() == hM and st['phaseSHA256'].lower() == hP and st['solutionSHA256'].lower() == hO, 'STATE links')
        chk(S['solutionLinks']['meshSHA256'].lower() == hM and S['solutionLinks']['phaseSHA256'].lower() == hP and S['phase']['meshSHA256'].lower() == hM, 'SOLUTION/PHASE links')
        chk(st['parentSHA256'].lower() == ph.lower(), 'parent SHA chain')
        chk(st['stateIndex'] == k and st['caseId'] == id and lst(st['mask']) == masks[id] and S['phase']['stateIndex'] == k and S['solutionLinks']['stateIndex'] == k, 'identity')
        chk(st['token'] == A['token'] and S['solutionLinks']['token'] == A['token'] and st['lp2a3SourceSHA256'] == P['sourcePins']['lp2a3SourceSHA256'], 'token / digest')
        chk(S['solutionLinks']['approvedHead'] == approved, 'approved head in SOLUTION')
        mg = S['solutionLinks']['memoryGate']; chk(bool(mg['pass']) and mg['freeGiB'] >= 7, 'memory gate >= 7 GiB')
        chk(st['seedRung'] == 1 and st['seedSpacing_mm'] == 0.45 and S['mesh']['T3'] <= 40000 and S['mesh']['crackPolylineEqualsState'], 'rung / budget / mesh polyline')
        chk(S['phase']['auditPass'] and S['phase']['meshAuditGates'] == 34 and S['phase']['pairingPass'] and S['phase']['pairingGates'] == 10, 'audit 34 / pairing 10 / phase')
        chk(bool(K['pass']) and len(lst(K['failedCriteria']) if K['failedCriteria'] else []) == 0 and all(bool(v) for v in K['criteria'].values()), 'SIF gates')
        chk(st['KI'] == K['KI'] and st['KII'] == K['KII'] and K['KI'] > 0, 'signed K equality / KI > 0')
        chk(S['mts']['status'] == 'OK' and S['mts']['admissible'] and S['mts']['stationarity'] <= 1e-12, 'MTS root')
        chk(abs(st['G'] - (K['KI'] ** 2 + K['KII'] ** 2) / E) <= 1e-15 * max(1, st['G']), 'G')
        # recurrence from the parent (independent formula)
        th = mts(KI, KII); n = [-t[1], t[0]]; tn = [math.cos(th) * t[0] + math.sin(th) * n[0], math.cos(th) * t[1] + math.sin(th) * n[1]]
        tip = [Ppoly[-1][0] + 4 * tn[0], Ppoly[-1][1] + 4 * tn[1]]; poly = st['polyline_mm']
        chk(len(poly) == len(Ppoly) + 1 and all(abs(poly[i][j] - Ppoly[i][j]) == 0 for i in range(len(Ppoly)) for j in (0, 1)), 'prefix of polyline')
        chk(math.hypot(tip[0] - poly[-1][0], tip[1] - poly[-1][1]) <= 1e-9 and abs(st['arc_mm'] - (25.4 + 4 * k)) <= 1e-9, 'recurrence / arc')
        g = gap(poly[-1]); chk(min(g) >= 1.0, '1-mm guard'); minMargin = min(minMargin, min(g) - 1.0)
        chk(st['classification'] == 'MATRIX_ADVANCE', 'classification')
        acc.append(k); solves_completed += 1
        rows.append({'stateIndex': k, 'tip_mm': poly[-1], 'KI': K['KI'], 'KII': K['KII'], 'G': st['G'], 'J': K['J'], 'MTS_deg': S['mts']['theta_deg'], 'gap_mm': g})
        parent = st; ph = hS; t = st['tangent']; Ppoly = poly; KI, KII = K['KI'], K['KII']
    accepted_total += len(acc)
    Tm = C['terminal']; last = acc[-1] if acc else 8
    if Tm['lastAcceptedState'] != last or Tm['acceptedPrefixLength'] != len(acc) or Tm['parentSHA256'].lower() != ph.lower() or Tm['token'] != A['token']: bad(f'{id}: terminal does not bind the last accepted state')
    if Tm['classification'] == 'CAMPAIGN_LIMIT_REACHED' and (last != 11 or not Tm['candidateIsInformationOnly'] or failed): bad(f'{id}: ceiling terminal inconsistent')
    if Tm['classification'] == 'NUMERICAL_HOLD' and (failed is None or failed['stateIndex'] != last + 1): bad(f'{id}: NUMERICAL_HOLD without the failed folder S{last + 1}')
    if Tm.get('physicalArrest') or Tm.get('interfaceEncounter'): bad(f'{id}: arrest/encounter flag set')
    cand = Tm['candidate']; cg = gap(cand['polyline_mm'][-1]) if cand.get('polyline_mm') else None
    res['cases'][id] = {'acceptedStates': acc, 'terminal': Tm['classification'], 'lastAcceptedState': last, 'failedFolder': failed,
                        'terminalFailure': Tm['failure'], 'terminalCandidateClassification': cand.get('classification'), 'terminalCandidateGap_mm': cg,
                        'minGuardMargin_mm': minMargin, 'rows': rows}
unexpected = sorted(set(Hrun) - expected); missing = sorted(expected - set(Hrun))
if unexpected: bad('unexpected run files: ' + ','.join(unexpected))
if missing: bad('missing run files: ' + ','.join(missing))
# ---- ledger
ent = lst(A['ledger']['entries']); names = sorted(e['file'] for e in ent)
adm = [e for e in ent if e['file'].startswith('ADMIT_')]; adm.sort(key=lambda e: e['record']['admittedUTC'])
order = [e['record']['stateKey'] for e in adm]
want_order = [a for a in admitted]  # chain order of folders (case order, then S9..)
if order != want_order: bad(f'ADMIT order {order} differs from the folder order {want_order}')
rc = [e for e in ent if e['file'] == 'RECEIPT.mat']; cl = [e for e in ent if e['file'] == 'CLOSED.mat']
if len(rc) != 1 or rc[0]['record']['token'] != A['token'] or rc[0]['record']['campaignId'] != P['authorization']['campaignId']: bad('receipt')
if len(cl) != 1: bad('CLOSED missing')
else:
    tsh = [Hrun[f'{id}/TERMINAL.mat'] for id in ids]
    if [x.lower() for x in lst(cl[0]['record']['terminalSHA256'])] != tsh: bad('CLOSED does not bind the TERMINAL files')
led_expected = {'RECEIPT.mat', 'CLOSED.mat'} | {f'ADMIT_{a}.mat' for a in admitted}
led_expected |= {n + '.manifest.json' for n in list(led_expected)}
if set(Hled) != led_expected: bad('ledger file set: extra ' + ','.join(sorted(set(Hled) - led_expected)) + ' missing ' + ','.join(sorted(led_expected - set(Hled))))
if len(admitted) > 12 or any(sum(1 for a in admitted if a.startswith(i + '_')) > 3 for i in ids): bad('admission caps')
res.update({'runFiles': len(Hrun), 'ledgerFiles': len(Hled), 'admissions': len(admitted), 'admittedKeys': admitted, 'physicalSolvesCompletedWithAcceptedState': solves_completed,
            'acceptedStates': accepted_total, 'ledgerAdmitOrder': order, 'problems': prob, 'pass': not prob})
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('admissions', len(admitted), 'accepted', accepted_total, 'runFiles', len(Hrun), 'ledgerFiles', len(Hled), 'problems', len(prob), 'PASS' if not prob else 'FAIL')
for p in prob[:20]: print(' -', p)
