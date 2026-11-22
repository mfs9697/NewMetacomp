"""G2-LP1-SR1 independent read-only numerical check (Issue #56).

Pure Python (standard library only). No MATLAB, mesher, solver or record writer
is called. Inputs are committed tables plus a reduced, path-free extract of the
saved LP1 MAT records (produced by the read-only MATLAB extractor in this folder).

Usage (from repository root):
  python -I scripts/g2/sr1/sr1_independent_check.py                # check + write outputs
  python -I scripts/g2/sr1/sr1_independent_check.py --reduce FULL.json --meshq MESHQ.json  # rebuild inputs first

Outputs (new directory content only):
  docs/research/G2_LP1_SR1_independent_check/SR1_CHECK_RESULTS.json
  docs/research/G2_LP1_SR1_independent_check/SR1_*.csv
"""
import argparse
import csv
import hashlib
import json
import math
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
OUT = REPO / 'docs' / 'research' / 'G2_LP1_SR1_independent_check'
CSV = REPO / 'reports' / 'G2' / 'LP1_20261122_v3' / 'LP1_COMPARISON.csv'
LEDGER = REPO / 'matlab' / 'g2' / 'evidence' / 'lp1_20261122' / 'RAW_RECORDS_SHA256.json'
POLICY = 'matlab/g2/G2_LP1_POLICY_v2.json'
R1CF = REPO / 'matlab' / 'g2' / 'evidence' / 'm4b_r1_20261121' / 'analysis' / 'r1_crossfamily.csv'
R1CASES = REPO / 'matlab' / 'g2' / 'evidence' / 'm4b_r1_20261121' / 'analysis' / 'r1_cases_both_families.csv'
REDUCED = OUT / 'LP1_records_reduced.json'
MESHQ = OUT / 'LP1_mesh_quality.json'

CASES = ['H', 'stiff13', 'soft2', 'soft1']
STATES = range(5)
SRC_SET = '2e5756969e456043e48f048ecc12ebf0c76980b113296eb3903c79ac172cab00'
SRC_COMMIT = '3dadf0d43aba0c5b2b3e8c69b90c2d42e89866f8'
POLICY_SHA = '074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091'
LP0_SHA = 'b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5'
KCONV = 1000.0 / math.sqrt(1000.0)  # N mm^-1.5 at 1 N  ->  MPa m^0.5 per kN

checks = []


def check(cid, desc, ok, value=None, limit=None, status=None):
    checks.append({'id': cid, 'description': desc, 'pass': bool(ok),
                   'value': value, 'limit': limit,
                   'status': status or ('VERIFIED' if ok else 'FAILED')})


def sha_bytes(b):
    return hashlib.sha256(b).hexdigest()


def git_blob(path):
    return subprocess.run(['git', '-C', str(REPO), 'show', 'HEAD:' + path],
                          capture_output=True, check=True).stdout


# ----------------------------------------------------------------- reduction
KEEP_STATE = ['schema', 'stateIndex', 'caseId', 'mask', 'ratio', 'policySHA256', 'sourceSHA256',
              'parentSHA256', 'sourceCommit', 'polyline_mm', 'tangent', 'normal', 'arc_mm', 'KI',
              'KII', 'EDI_all', 'MTS_deg', 'G', 'meshSHA256', 'phaseSHA256', 'solutionSHA256',
              'reviewSHA256', 'clearance', 'Hregression', 'physicalFractureGrowthProven']
KEEP_K = ['pass', 'status', 'failedCriteria', 'KI', 'KII', 'J', 'KI_COD', 'KII_COD', 'EDI_all',
          'EDI4x4', 'qActiveElements', 'qSupportMaxRadius_mm', 'codFitPairs', 'Ep_matrix',
          'relativeResidual', 'staticsMax', 'reactions', 'strainEnergy_per_thickness',
          'externalWork_per_thickness', 'energyIdentityRel', 'ringStrainEnergy_per_thickness',
          'activeInterfaceBalanceRel', 'activeAnnulusResultantRel', 'interfaceSideL2Rel',
          'interfaceSideL2Gated', 'KffPositiveDefinite', 'phaseCounts', 'activeArea_mm2',
          'compliance_mm_per_N', 'uyLoad_mm', 'CMOD_mm', 'fullPolyOpeningMin_mm',
          'KII_sign_edi_vs_cod_match', 'conditionalModeIISignGateEnforced', 'criteria']


def reduce_extract(full):
    F = json.loads(Path(full).read_text(encoding='utf-8'))
    red = {'schema': 'NewMetacomp.G2.LP1.SR1.ReducedRecords.v1',
           'note': 'Read-only reduction of the 20 saved LP1 states; path-bearing and large fields removed.',
           'runToken': F['RUN']['token'], 'runSourceCommit': F['RUN']['sourceCommit'], 'states': {}}
    for c in CASES:
        for k in STATES:
            e = F[f'{c}_S{k}']
            st = {f: e['STATE'][f] for f in KEEP_STATE if f in e['STATE']}
            K = e['SOLUTION']['K']
            ph = e['PHASE']['audit']
            red['states'][f'{c}_S{k}'] = {
                'STATE': st,
                'REVIEW_equals_STATE_fields': all(e['REVIEW'].get(f) == e['STATE'].get(f)
                                                  for f in ['KI', 'KII', 'G', 'MTS_deg', 'polyline_mm',
                                                            'meshSHA256', 'solutionSHA256']),
                'SOLUTION': {'meshSHA256': e['SOLUTION']['meshSHA256'],
                             'phaseSHA256': e['SOLUTION']['phaseSHA256'],
                             'sourceSHA256': e['SOLUTION']['sourceSHA256'],
                             'K': {f: K[f] for f in KEEP_K if f in K}},
                'PHASE': {'meshSHA256': e['PHASE']['meshSHA256'], 'mask': e['PHASE']['mask'],
                          'audit_pass': ph['pass'], 'map': ph['map'], 'ownerOracle': ph['ownerOracle'],
                          'legacyVerifier': ph['legacyVerifier'], 'legacyNegatives': ph['legacyNegatives'],
                          'activationNegatives_pass': ph['activationNegatives']['pass'],
                          'geometry': {g: ph['geometry'][g] for g in
                                       ['counts', 'chordsPerCircle', 'annulusArea_mm2', 'tipToBand_mm',
                                        'qClearance_mm', 'domainAreaRelErr', 'annulusAreaRelErr']},
                          'meshAudit': {g: ph['meshAudit'][g] for g in
                                        ['pass', 'stage', 'gatesPassed', 'gatesTotal']},
                          'ringPolygons': ph['clearanceGeometry']['ringPolygons'],
                          'holePolygons': ph['clearanceGeometry']['holePolygons']}}
    blob = json.dumps(red, sort_keys=True)
    assert 'Users' not in blob and ':\\' not in blob, 'private path survived reduction'
    REDUCED.write_text(json.dumps(red, indent=1, sort_keys=True), encoding='utf-8', newline='\n')


# ----------------------------------------------------------------- geometry helpers
def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]


def norm(a):
    return math.hypot(a[0], a[1])


def pseg(p, a, b):
    v = sub(b, a)
    den = dot(v, v)
    t = 0.0 if den == 0 else max(0.0, min(1.0, dot(sub(p, a), v) / den))
    return norm(sub(p, (a[0] + t * v[0], a[1] + t * v[1])))


def segseg(a, b, c, d):
    def cr(u, w):
        return u[0] * w[1] - u[1] * w[0]
    r, s = sub(b, a), sub(d, c)
    den = cr(r, s)
    if abs(den) > 1e-14:
        t = cr(sub(c, a), s) / den
        u = cr(sub(c, a), r) / den
        if 0 <= t <= 1 and 0 <= u <= 1:
            return 0.0
    return min(pseg(a, c, d), pseg(b, c, d), pseg(c, a, b), pseg(d, a, b))


def seg_poly(a, b, Q):
    return min(segseg(a, b, Q[i], Q[(i + 1) % len(Q)]) for i in range(len(Q)))


def mts(KI, KII):
    if KII == 0:
        return 0.0
    return math.degrees(2 * math.atan((KI - math.sqrt(KI * KI + 8 * KII * KII)) / (4 * KII)))


def mts_residual(KI, KII, th):
    t = math.radians(th)
    return KI * math.sin(t) + KII * (3 * math.cos(t) - 1)


# ----------------------------------------------------------------- main checks
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--reduce', help='full MATLAB extract JSON to reduce first')
    ap.add_argument('--meshq', help='mesh-quality JSON from sr1_mesh_quality.m to install first')
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    if args.reduce:
        reduce_extract(args.reduce)
    if args.meshq:
        mqj = json.loads(Path(args.meshq).read_text(encoding='utf-8'))
        MESHQ.write_text(json.dumps(mqj, indent=1, sort_keys=True), encoding='utf-8', newline='\n')

    pol = json.loads(git_blob(POLICY))
    check('P0', 'Policy v2 Git blob SHA-256 equals the pinned physical policy SHA',
          sha_bytes(git_blob(POLICY)) == POLICY_SHA, sha_bytes(git_blob(POLICY)), POLICY_SHA)
    E = pol['bvp']['E_MPa']
    t_mm = pol['bvp']['thickness_mm']
    P_N = pol['bvp']['P_N']
    g = pol['geometry']
    C = [tuple(c) for c in g['centres_mm']]
    Rr, Rh, Wp, Hp = g['ringR_mm'], g['holeR_mm'], g['plate_mm'][0], g['plate_mm'][1]
    guide, qmax, qbuf = g['tipGuideRadius_mm'], max(q[1] for q in pol['qAnnuli_mm']), g['minQClearance_mm']

    rows = {}
    with CSV.open(encoding='utf-8') as f:
        for r in csv.DictReader(f):
            rows[(r['caseId'], int(r['state']))] = r
    fv = lambda c, k, name: float(rows[(c, k)][name])
    led = json.loads(LEDGER.read_text(encoding='utf-8'))
    RED = json.loads(REDUCED.read_text(encoding='utf-8'))
    S = RED['states']

    # ---------------- provenance
    tok = RED['runToken']
    check('P1', 'RUN token binds policy v2, computation source set and LP0 evidence',
          tok == f'G2LP1|policy={POLICY_SHA}|source={SRC_SET}|LP0={LP0_SHA}|cases=H,stiff13,soft2,soft1|maxState=4', tok)
    bad = []
    for c in CASES:
        for k in STATES:
            st = S[f'{c}_S{k}']['STATE']
            sol = S[f'{c}_S{k}']['SOLUTION']
            key = f'{c}/S{k}/'
            if st['sourceSHA256'] != SRC_SET or sol['sourceSHA256'] != SRC_SET: bad.append(key + 'source')
            if st['policySHA256'] != POLICY_SHA: bad.append(key + 'policy')
            if st['sourceCommit'] != SRC_COMMIT: bad.append(key + 'commit')
            if led[key + 'MESH.mat'] != st['meshSHA256']: bad.append(key + 'mesh')
            if led[key + 'PHASE.mat'] != st['phaseSHA256']: bad.append(key + 'phase')
            if led[key + 'SOLUTION.mat'] != st['solutionSHA256']: bad.append(key + 'solution')
            if led[key + 'REVIEW.mat'] != st['reviewSHA256']: bad.append(key + 'review')
            if led[key + 'STATE.mat'] != rows[(c, k)]['stateSHA256']: bad.append(key + 'csvState')
            if sol['meshSHA256'] != st['meshSHA256'] or S[f'{c}_S{k}']['PHASE']['meshSHA256'] != st['meshSHA256']:
                bad.append(key + 'meshLink')
            if not S[f'{c}_S{k}']['REVIEW_equals_STATE_fields']: bad.append(key + 'reviewFields')
            if k > 0 and st['parentSHA256'] != led[f'{c}/S{k-1}/STATE.mat']: bad.append(key + 'parent')
            if st['caseId'] != c or st['stateIndex'] != k: bad.append(key + 'identity')
    check('P2', 'All 20 states: source/policy/commit pins, ledger hashes of MESH/PHASE/SOLUTION/REVIEW/STATE, '
          'parent-state hash chain S1..S4, CSV state hash, record identity', not bad, bad)
    masks = {'H': [0, 0, 0], 'stiff13': [1, 0, 1], 'soft2': [0, 1, 0], 'soft1': [1, 0, 0]}
    ratios = {'H': 1, 'stiff13': 2, 'soft2': 0.5, 'soft1': 0.5}
    mbad = [f'{c}_S{k}' for c in CASES for k in STATES
            if S[f'{c}_S{k}']['STATE']['mask'] != masks[c] or S[f'{c}_S{k}']['PHASE']['mask'] != masks[c]
            or S[f'{c}_S{k}']['STATE']['ratio'] != ratios[c]]
    check('P3', 'Mask and modulus ratio of every state equal the preregistered architecture', not mbad, mbad)

    # ---------------- numerics
    unit_err = g_err = j_err = mts_err = mts_res = 0.0
    sol_eq = []
    for c in CASES:
        for k in STATES:
            st, K = S[f'{c}_S{k}']['STATE'], S[f'{c}_S{k}']['SOLUTION']['K']
            if st['KI'] != K['KI'] or st['KII'] != K['KII']: sol_eq.append(f'{c}_S{k}')
            unit_err = max(unit_err, abs(st['KI'] * KCONV - fv(c, k, 'KI_MPa_sqrt_m_per_kN')) / fv(c, k, 'KI_MPa_sqrt_m_per_kN'),
                           abs(st['KII'] * KCONV - fv(c, k, 'KII_MPa_sqrt_m_per_kN')) / abs(fv(c, k, 'KI_MPa_sqrt_m_per_kN')))
            Gk = (st['KI'] ** 2 + st['KII'] ** 2) / E
            g_err = max(g_err, abs(Gk - st['G']) / st['G'], abs(Gk - fv(c, k, 'G_N_per_mm_at_1N')) / Gk)
            j_err = max(j_err, abs(K['J'] - Gk) / Gk)
            th = mts(st['KI'], st['KII'])
            mts_err = max(mts_err, abs(th - st['MTS_deg']), abs(th - fv(c, k, 'MTS_local_deg')))
            mts_res = max(mts_res, abs(mts_residual(st['KI'], st['KII'], st['MTS_deg'])) / math.hypot(st['KI'], st['KII']))
    check('N0', 'STATE K equals SOLUTION K (all 20)', not sol_eq, sol_eq)
    check('N1', 'Unit conversion K[N mm^-1.5 at 1 N] x 1000/sqrt(1000) = CSV MPa m^0.5 per kN (max rel. error)',
          unit_err < 1e-12, unit_err, 1e-12)
    check('N2', 'Plane-stress G=(KI^2+KII^2)/E_m reproduces record and CSV G (max rel. error)', g_err < 1e-12, g_err, 1e-12)
    check('N3', 'Interaction-integral J agrees with G from K (max rel.; policy J/energy gate 0.005)', j_err < 0.005, j_err, 0.005)
    check('N4', 'Independent MTS root reproduces recorded/CSV local angle (max abs deg) and stationarity residual',
          mts_err < 1e-9 and mts_res < 1e-12, {'maxAbsDeg': mts_err, 'maxResidualOverK': mts_res}, {'deg': 1e-9, 'res': 1e-12})

    # geometry
    gbad, maxseg, maxhead = [], 0.0, 0.0
    tips, heads, normals, polys = {}, {}, {}, {}
    for c in CASES:
        prev = None
        for k in STATES:
            st = S[f'{c}_S{k}']['STATE']
            P = [tuple(p) for p in st['polyline_mm']]
            polys[(c, k)] = P
            segs = [norm(sub(P[i + 1], P[i])) for i in range(len(P) - 1)]
            if len(P) != k + 2: gbad.append(f'{c}_S{k}:vertices')
            if P[0] != (101.6, 0.0) or P[1] != (101.6, 25.4): gbad.append(f'{c}_S{k}:start')
            for sgl in segs[1:]:
                maxseg = max(maxseg, abs(sgl - 4.0))
            if abs(sum(segs) - st['arc_mm']) > 1e-9 or abs(st['arc_mm'] - (25.4 + 4 * k)) > 1e-9: gbad.append(f'{c}_S{k}:arc')
            if prev is not None and P[:-1] != prev: gbad.append(f'{c}_S{k}:prefix')
            tip = P[-1]
            tips[(c, k)] = tip
            tv = sub(P[-1], P[-2]); tv = (tv[0] / norm(tv), tv[1] / norm(tv))
            if max(abs(tv[0] - st['tangent'][0]), abs(tv[1] - st['tangent'][1])) > 1e-12: gbad.append(f'{c}_S{k}:tangent')
            if st['normal'] != [-st['tangent'][1], st['tangent'][0]]: gbad.append(f'{c}_S{k}:normal')
            normals[(c, k)] = tuple(st['normal'])
            heads[(c, k)] = math.degrees(math.atan2(tv[1], tv[0]))
            if abs(tip[0] - fv(c, k, 'tip_x_mm')) > 1e-9 or abs(tip[1] - fv(c, k, 'tip_y_mm')) > 1e-9: gbad.append(f'{c}_S{k}:csvtip')
            if abs(heads[(c, k)] - fv(c, k, 'heading_deg')) > 1e-9: gbad.append(f'{c}_S{k}:heading')
            if k > 0:
                maxhead = max(maxhead, abs((heads[(c, k)] - heads[(c, k - 1)]) - S[f'{c}_S{k-1}']['STATE']['MTS_deg']))
            prev = P
    check('N5', 'Geometry: k+2 vertices, common S0, exact 4-mm segments, arc 25.4+4k, prefix extension, '
          'tangent/left-normal, CSV tip and heading', not gbad and maxseg < 1e-9, {'failures': gbad, 'maxSegmentError_mm': maxseg})
    check('N6', 'Heading recurrence: heading(S_k+1) - heading(S_k) = own MTS(S_k) (max abs deg)', maxhead < 1e-9, maxhead, 1e-9)
    mq = json.loads(MESHQ.read_text(encoding='utf-8'))
    mqbad = []
    worst_angle, worst_ratio = 180.0, 0.0
    for c in CASES:
        for k in STATES:
            q = mq[f'{c}_S{k}']
            worst_angle = min(worst_angle, q['minAngle_deg'])
            worst_ratio = max(worst_ratio, q['maxNeighbourLongestEdgeRatio'])
            cp = [tuple(p) for p in q['crackPolyline']]
            if q['nT3'] != int(fv(c, k, 'mesh_T3')): mqbad.append(f'{c}_S{k}:T3')
            if q['nNegativeArea'] != 0: mqbad.append(f'{c}_S{k}:inverted')
            if max(norm(sub(a, b)) for a, b in zip(cp, polys[(c, k)])) > 1e-12 or len(cp) != len(polys[(c, k)]):
                mqbad.append(f'{c}_S{k}:meshPolyline')
            if abs(q['totalArea_mm2'] - (Wp * Hp - 3 * math.pi * Rh ** 2)) / (Wp * Hp) > 2e-4:
                mqbad.append(f'{c}_S{k}:area')
    check('N7', 'Independent T3 quality from saved MESH arrays: no inverted elements, T3 count = CSV, mesh crack '
          'polyline = state polyline; min angle >= 20 deg and neighbour longest-edge ratio <= 1.8 (policy)',
          not mqbad and worst_angle >= pol['numerics']['T3minAngle_deg'] and worst_ratio <= pol['numerics']['T3maxNeighborLongestEdgeRatio'],
          {'failures': mqbad, 'worstMinAngle_deg': worst_angle, 'worstNeighbourRatio': worst_ratio})

    # ---------------- comparisons at matched arclength
    cmp_rows = []
    cbad = []
    for c in CASES[1:]:
        for k in STATES:
            st, sh = S[f'{c}_S{k}']['STATE'], S[f'H_S{k}']['STATE']
            KM, KH = S[f'{c}_S{k}']['SOLUTION']['K'], S[f'H_S{k}']['SOLUTION']['K']
            FG = st['G'] / sh['G'] - 1
            dvec = sub(tips[(c, k)], tips[('H', k)])
            d = dot(dvec, normals[('H', k)])
            sep = norm(dvec)
            Fth = st['MTS_deg'] - sh['MTS_deg']
            dpsi = heads[(c, k)] - heads[('H', k)]
            # paired estimator variants: 5 EDI annuli (rows), 4x4 quadrature, COD
            def Gv(Krec, v):
                if v == 'COD':
                    return (Krec['KI_COD'] ** 2 + Krec['KII_COD'] ** 2) / E
                if v == '4x4':
                    return (Krec['EDI4x4'][0] ** 2 + Krec['EDI4x4'][1] ** 2) / E
                r = Krec['EDI_all'][v]
                return (r[0] ** 2 + r[1] ** 2) / E
            def Tv(Krec, v):
                if v == 'COD':
                    return mts(Krec['KI_COD'], Krec['KII_COD'])
                if v == '4x4':
                    return mts(Krec['EDI4x4'][0], Krec['EDI4x4'][1])
                r = Krec['EDI_all'][v]
                return mts(r[0], r[1])
            edi_vars = [1, 2, 3, 4, '4x4']
            FG_var = {str(v): Gv(KM, v) / Gv(KH, v) - 1 for v in edi_vars + ['COD']}
            Th_var = {str(v): Tv(KM, v) - Tv(KH, v) for v in edi_vars + ['COD']}
            UpG_edi = max(abs(FG_var[str(v)] - FG) for v in edi_vars)
            UpG_all = max(abs(x - FG) for x in FG_var.values())
            UpT_all = max(abs(x - Fth) for x in Th_var.values())
            dM = abs(Gv(KM, 'COD') - st['G']) / st['G']
            dH = abs(Gv(KH, 'COD') - sh['G']) / sh['G']
            Ucons = (st['G'] / sh['G']) * (dM + dH)
            eM = abs(Tv(KM, 'COD') - st['MTS_deg'])
            eH = abs(Tv(KH, 'COD') - sh['MTS_deg'])
            UconsT = eM + eH
            cmp_rows.append({'case': c, 'state': k, 'arc_mm': st['arc_mm'], 'F_G': FG, 'F_G_COD_paired': FG_var['COD'],
                             'F_G_COD_minus_EDI': FG_var['COD'] - FG, 'U_primary_FG_raw_EDIonly': UpG_edi,
                             'U_primary_FG_raw_withCOD': UpG_all, 'U_primary_FG_floored': max(UpG_all, 1e-5),
                             'U_cons_FG': Ucons, 'F_theta_deg': Fth, 'F_theta_COD_paired_deg': Th_var['COD'],
                             'U_primary_theta_deg': UpT_all, 'U_cons_theta_deg': UconsT,
                             'heading_diff_deg': dpsi, 'lateral_offset_mm': d, 'tip_separation_mm': sep,
                             'G_COD_rel_bias_case': dM, 'G_COD_rel_bias_H': dH})
            # compare with CSV
            r = rows[(c, k)]
            for name, val in [('F_G', FG), ('lateral_offset_mm', d), ('tip_separation_mm', sep),
                              ('U_cons_FG', Ucons), ('F_theta_local_deg', Fth), ('U_cons_theta_deg', UconsT)]:
                ref = float(r[name])
                if abs(val - ref) > 1e-9 * max(1.0, abs(ref)):
                    cbad.append(f'{c}_S{k}:{name}:{val}!={ref}')
            if abs(max(UpG_all, 1e-5) - float(r['U_primary_FG'])) > 1e-9 and k > 0:
                cbad.append(f'{c}_S{k}:U_primary_FG')
            if abs(UpG_all - float(r['U_primary_FG_raw'])) > 1e-9:
                cbad.append(f'{c}_S{k}:U_primary_FG_raw:{UpG_all}!={r["U_primary_FG_raw"]}')
            if abs(UpT_all - float(r['U_primary_theta_deg'])) > 1e-9:
                cbad.append(f'{c}_S{k}:U_primary_theta:{UpT_all}!={r["U_primary_theta_deg"]}')
    check('N8', 'Independent F_G, signed lateral offset (projection on H left normal), tip separation, F_theta, '
          'paired primary spread (EDI annuli, 4x4, COD) and conservative COD-vs-EDI U reproduce the CSV',
          not cbad, cbad)

    # offset uncertainty propagation and classes
    off_rows, obad = [], []
    by = {(r['case'], r['state']): r for r in cmp_rows}
    for c in CASES[1:]:
        for n in range(1, 5):
            Up = 4 * sum((n - j) * math.radians(by[(c, j)]['U_primary_theta_deg']) for j in range(n))
            Uc = 4 * sum((n - j) * math.radians(by[(c, j)]['U_cons_theta_deg']) for j in range(n))
            Upaired = 4 * sum((n - j) * math.radians(abs(by[(c, j)]['F_theta_COD_paired_deg'] - by[(c, j)]['F_theta_deg']))
                              for j in range(n))
            d = by[(c, n)]['lateral_offset_mm']
            if abs(Up - float(rows[(c, n)]['U_primary_separation_mm'])) > 1e-9 or abs(Uc - float(rows[(c, n)]['U_cons_separation_mm'])) > 1e-9:
                obad.append(f'{c}_S{n}')
            # first-kink transport: heading difference set at S0 carried over n segments of 4 mm
            first_kink = 4 * n * math.radians(by[(c, 0)]['F_theta_deg'])
            off_rows.append({'case': c, 'state': n, 'd_mm': d, 'U_d_primary_mm': Up, 'U_d_cons_mm': Uc,
                             'U_d_pairedCOD_mm': Upaired, 'ratio_abs_d_over_2Ucons': abs(d) / (2 * Uc),
                             'first_kink_transport_mm': first_kink, 'first_kink_share': first_kink / d if d else None})
    check('N9', 'Offset uncertainty U_d = 4 sum_j (n-j) U_dtheta_j [rad] reproduces CSV (primary and conservative)', not obad, obad)

    s4 = {r['case']: r for r in cmp_rows if r['state'] == 4}
    o4 = {r['case']: r for r in off_rows if r['state'] == 4}
    classes = {}
    for c in CASES[1:]:
        r = s4[c]
        sign_ok = (r['F_G'] > 0) == (r['F_G_COD_paired'] > 0)
        classes[c] = {
            'F_G_pp': 100 * r['F_G'],
            'FG_primary_resolved': abs(r['F_G']) > 2 * r['U_primary_FG_floored'] and sign_ok,
            'FG_conservative_resolved': abs(r['F_G']) > r['U_cons_FG'] and sign_ok,
            'FG_over_Ucons': abs(r['F_G']) / r['U_cons_FG'],
            'offset_mm': o4[c]['d_mm'],
            'offset_primary_resolved': abs(o4[c]['d_mm']) > 2 * o4[c]['U_d_primary_mm'],
            'offset_cautious_resolved': abs(o4[c]['d_mm']) > 2 * o4[c]['U_d_cons_mm'],
            'offset_over_2Ucons': o4[c]['ratio_abs_d_over_2Ucons'],
            'F_G_COD_minus_EDI_pp': 100 * r['F_G_COD_minus_EDI'],
            'paired_offset_diag_mm': o4[c]['U_d_pairedCOD_mm']}
    exp = {'stiff13': (True, True, True), 'soft2': (True, False, False), 'soft1': (True, True, True)}
    clsbad = [c for c in classes if (classes[c]['FG_primary_resolved'], classes[c]['FG_conservative_resolved'],
                                     classes[c]['offset_cautious_resolved']) != exp[c]]
    check('N10', 'S4 classification reproduced: stiff13 and soft1 resolved (primary, conservative, cautious offset); '
          'soft2 resolved only by the primary rule', not clsbad, classes)

    # energy: compliance finite difference vs EDI G
    fd_rows = []
    worst_fd = 0.0
    for c in CASES:
        for k in range(4):
            C0 = S[f'{c}_S{k}']['SOLUTION']['K']['compliance_mm_per_N']
            C1 = S[f'{c}_S{k+1}']['SOLUTION']['K']['compliance_mm_per_N']
            Gfd = P_N ** 2 / (2 * t_mm) * (C1 - C0) / 4.0
            G0, G1 = S[f'{c}_S{k}']['STATE']['G'], S[f'{c}_S{k+1}']['STATE']['G']
            Gtrap = 0.5 * (G0 + G1)
            Gmid = math.sqrt(G0 * G1)
            rel = Gfd / Gtrap - 1
            worst_fd = max(worst_fd, abs(rel)) if k > 0 else worst_fd
            fd_rows.append({'case': c, 'step': f'S{k}-S{k+1}', 'G_fd_compliance': Gfd, 'G_trapezoid_EDI': Gtrap,
                            'G_geomean_EDI': Gmid, 'rel_fd_minus_trap': rel})
        # compare F_G from compliance for curved steps
    for r in fd_rows:
        if r['case'] != 'H':
            h = next(x for x in fd_rows if x['case'] == 'H' and x['step'] == r['step'])
            r['F_G_fd'] = r['G_fd_compliance'] / h['G_fd_compliance'] - 1
            r['F_G_trap'] = r['G_trapezoid_EDI'] / h['G_trapezoid_EDI'] - 1
    smooth = sorted(abs(r['rel_fd_minus_trap']) for r in fd_rows if r['step'] != 'S0-S1')
    within = sum(x <= 0.01 for x in smooth)
    check('N11', 'Global energy diagnostic: (P^2/2t) dC/da from successive point-load compliances vs mean EDI G on '
          'the 12 smooth steps (S1-S4); point-load compliance is remeshing-sensitive, so this is corroboration, '
          'not a gate', within >= 11,
          {'within1pct': f'{within}/12', 'median_abs_rel': smooth[len(smooth) // 2], 'max_abs_rel': smooth[-1]},
          'diagnostic', status='CORROBORATING_DIAGNOSTIC')

    # energy identities and solution gates recorded
    egbad = []
    for c in CASES:
        for k in STATES:
            K = S[f'{c}_S{k}']['SOLUTION']['K']
            if not (K['pass'] and K['status'] == 'M4B_SIF_VERIFIED' and not K['failedCriteria']): egbad.append(f'{c}_S{k}:gate')
            if K['energyIdentityRel'] > 1e-9 or K['relativeResidual'] > pol['verification']['elasticRelativeResidualMax']:
                egbad.append(f'{c}_S{k}:energy')
            if abs(K['strainEnergy_per_thickness'] - K['externalWork_per_thickness']) / K['externalWork_per_thickness'] > 1e-9:
                egbad.append(f'{c}_S{k}:work')
            # compliance = 2 U / P^2 with U total = U_per_t * t
            if abs(2 * K['strainEnergy_per_thickness'] * t_mm / P_N ** 2 - K['compliance_mm_per_N']) / K['compliance_mm_per_N'] > 1e-9:
                egbad.append(f'{c}_S{k}:compliance')
            if abs(sum(K['reactions'][1:]) - P_N / t_mm) > 1e-12: egbad.append(f'{c}_S{k}:reactions')
            if K['fullPolyOpeningMin_mm'] < pol['verification']['minWholeCrackNormalOpening_mm']: egbad.append(f'{c}_S{k}:opening')
            if not K['KII_sign_edi_vs_cod_match']: egbad.append(f'{c}_S{k}:KIIsign')
            ph = S[f'{c}_S{k}']['PHASE']
            # S0 is the straight crack (independent T6 auditor, 38 gates); S1-S4 are kinked (34 gates)
            ng = 38 if k == 0 else 34
            if not (ph['audit_pass'] and ph['map'] and ph['ownerOracle'] and ph['legacyVerifier'] and ph['activationNegatives_pass']
                    and ph['meshAudit']['gatesPassed'] == ng and ph['meshAudit']['gatesTotal'] == ng):
                egbad.append(f'{c}_S{k}:phase')
            act = sum(m for m in masks[c])
            if abs(K['activeArea_mm2'] - act * ph['geometry']['annulusArea_mm2'][0]) > 1e-6: egbad.append(f'{c}_S{k}:activeArea')
    check('N12', 'Saved SOLUTION/PHASE fields: verified SIF status, energy = external work, compliance = 2U/P^2, '
          'reactions sum to P/t, non-negative whole-crack opening, signed KII EDI/COD agreement, phase/owner/34-gate '
          'audits, active area = active rings x annulus polygon area', not egbad, egbad,
          status='VERIFIED_SAVED_FIELDS')

    # ---------------- clearances (independent)
    cl_rows, clbad = [], []
    for c in CASES:
        for k in STATES:
            P = polys[(c, k)]
            tip = P[-1]
            a = P[-2]
            ph = S[f'{c}_S{k}']['PHASE']
            ringP = [[tuple(v) for v in Q] for Q in ph['ringPolygons']]
            holeP = [[tuple(v) for v in Q] for Q in ph['holePolygons']]
            tipRing = [norm(sub(tip, cc)) - Rr for cc in C]
            tipHole = [norm(sub(tip, cc)) - Rh for cc in C]
            segRingNom = [pseg(cc, a, tip) - Rr for cc in C]
            segRingPoly = [seg_poly(a, tip, Q) for Q in ringP]
            pathRingPoly = min(seg_poly(P[i], P[i + 1], Q) for i in range(len(P) - 1) for Q in ringP)
            pathHolePoly = min(seg_poly(P[i], P[i + 1], Q) for i in range(len(P) - 1) for Q in holeP)
            nonadj = min([segseg(P[i], P[i + 1], P[j], P[j + 1]) for i in range(len(P) - 1)
                          for j in range(i + 2, len(P) - 1)] or [math.inf])
            plate = [tip[0], Wp - tip[0], tip[1], Hp - tip[1]]
            row = {'case': c, 'state': k, 'tip_ring_mm': tipRing, 'tip_hole_min_mm': min(tipHole),
                   'segment_ring_nominal_min_mm': min(segRingNom), 'segment_ring_polygon_mm': segRingPoly,
                   'path_ring_polygon_min_mm': pathRingPoly, 'path_hole_polygon_min_mm': pathHolePoly,
                   'guide_ring_margin_mm': min(tipRing) - guide, 'q_ring_margin_mm': min(tipRing) - qmax - qbuf,
                   'tip_plate_min_mm': min(plate), 'guide_plate_margin_mm': min(plate) - guide,
                   'nonadjacent_segment_mm': nonadj}
            cl_rows.append(row)
            r = rows[(c, k)]
            for i in range(3):
                if abs(tipRing[i] - float(r[f'tip_ring{i+1}_mm'])) > 1e-9: clbad.append(f'{c}_S{k}:ring{i+1}')
            for name, val in [('tip_hole_min_mm', min(tipHole)), ('segment_ring_min_mm', min(segRingNom)),
                              ('guide_ring_min_margin_mm', min(tipRing) - guide), ('q_ring_min_margin_mm', min(tipRing) - qmax - qbuf),
                              ('tip_plate_min_mm', min(plate)), ('guide_plate_min_margin_mm', min(plate) - guide)]:
                if abs(val - float(r[name])) > 1e-9: clbad.append(f'{c}_S{k}:{name}')
            ref_na = float(r['nonadjacent_segment_mm'])
            if k >= 2 and not math.isnan(ref_na) and not math.isinf(ref_na):
                # CSV reports the new segment against non-adjacent earlier segments only
                last = min(segseg(P[-2], P[-1], P[j], P[j + 1]) for j in range(len(P) - 3))
                if abs(last - ref_na) > 1e-9: clbad.append(f'{c}_S{k}:nonadjacent')
            if k > 0:
                m = S[f'{c}_S{k}']['STATE']['clearance']['metrics']
                if max(abs(x - y) for x, y in zip(segRingPoly, m['segmentToRingPolygon_mm'])) > 1e-9: clbad.append(f'{c}_S{k}:polyRec')
    check('N13', 'Independent clearances (nominal circles, saved 76-gon ring polygons, holes, plate, non-adjacent '
          'segments) reproduce CSV/record metrics; every state stays in the admissible matrix region',
          not clbad and all(r['guide_ring_margin_mm'] > 0 and r['guide_plate_margin_mm'] > 0 for r in cl_rows if r['state'] > 0),
          clbad)

    # ---------------- cross-check against accepted frozen-S2 M4.B / R1 evidence
    r1 = {}
    with R1CF.open(encoding='utf-8') as f:
        for r in csv.DictReader(f):
            r1[(r['quantity'], r['observable'])] = r
    mapq = {'stiff13': 'F_c2p0_101', 'soft2': 'F_c0p5_010', 'soft1': 'F_c0p5_100'}
    x2 = []
    for c, q in mapq.items():
        direct = float(r1[(q, 'G')]['Q_orig'])
        drift = float(r1[(q, 'G')]['delta'])
        dth = float(r1[(q, 'theta')]['Q_orig'])
        tot = by[(c, 2)]['F_G']
        x2.append({'case': c, 'F_G_LP1_ownpath_S2': tot, 'F_G_M4B_frozen_S2_direct': direct,
                   'path_contribution': tot - direct, 'opposes_direct': (tot - direct) * direct < 0,
                   'R1_crossfamily_drift_FG': drift,
                   'F_theta_M4B_frozen_S2_deg': dth, 'F_theta_LP1_ownpath_S2_deg': by[(c, 2)]['F_theta_deg'],
                   'heading_diff_LP1_S2_deg': by[(c, 2)]['heading_diff_deg']})
    hs2 = S['H_S2']['STATE']
    r1none = None
    with R1CASES.open(encoding='utf-8') as f:
        for r in csv.DictReader(f):
            if r['case'] == 'none':
                r1none = r
    hreg = abs(hs2['G'] / float(r1none['G_orig']) - 1)
    check('X1', 'LP1 H S2 reproduces the accepted M4.B/R1 homogeneous frozen-S2 G (rel.)', hreg < 2e-5, hreg, 2e-5)
    check('X2', 'LP1 own-path S2 total effect vs accepted frozen-S2 direct effect: path contribution opposes '
          'the direct effect for all three architectures (consistent with M3)', all(r['opposes_direct'] for r in x2), x2,
          status='VERIFIED_CONSISTENCY')

    # ---------------- feasibility geometry (pure geometry, no K or angle forecast)
    Rg = Rr + guide
    feas = {'guideEnvelopeRadius_mm': Rg, 'qEnvelopeRadius_mm': Rr + qmax + qbuf,
            'segmentEnvelopeRadius_mm': Rr + g['minSegmentRingClearance_mm'],
            'tipBox_mm': {'x': [guide, Wp - guide], 'y': [guide, Hp - guide]},
            'interRingGap_mm': (C[1][1] - C[0][1]) - 2 * Rr, 'ring3ToTopGap_mm': Hp - (C[2][1] + Rr),
            'guideEnvelopeTopOfRing3_mm': C[2][1] + Rg,
            'envelopeWaistHalfWidth_mm': math.sqrt(Rg ** 2 - ((C[1][1] - C[0][1]) / 2) ** 2),
            'envelopeLeftmostX_mm': C[0][0] - Rg}

    def blocked(p, mode):
        if mode == 'numerical':
            if any(norm(sub(p, cc)) <= Rg for cc in C): return 'GUIDE_ENVELOPE'
            if p[0] <= guide or p[0] >= Wp - guide or p[1] <= guide: return 'GUIDE_PLATE'
            if p[1] >= Hp - guide: return 'TOP_GUIDE_LIMIT'
        else:
            if any(norm(sub(p, cc)) <= Rr for cc in C): return 'NOMINAL_INTERFACE'
            if p[1] >= Hp: return 'TOP_EDGE'
        return None

    def ray(p0, psi, mode, ds=0.01, smax=400):
        s = 0.0
        while s < smax:
            s += ds
            p = (p0[0] + s * math.cos(math.radians(psi)), p0[1] + s * math.sin(math.radians(psi)))
            b = blocked(p, mode)
            if b: return b, s, p
        return 'NONE', s, p

    def min_heading(p0, mode, target):
        lo, hi = 0.0, 180.0
        # smallest heading whose straight ray reaches the target class first
        def ok(psi):
            return ray(p0, psi, mode, ds=0.02)[0] == target
        cand = [x / 10 for x in range(0, 1800)]
        good = [x for x in cand if x >= 30 and ok(x)]
        return min(good) if good else None

    straight = []
    for c in CASES:
        p0, psi0 = tips[(c, 4)], heads[(c, 4)]
        bn, sn, pn = ray(p0, psi0, 'numerical')
        bp, sp, pp = ray(p0, psi0, 'physical')
        closest = []
        for i, cc in enumerate(C):
            v = sub(cc, p0)
            u = (math.cos(math.radians(psi0)), math.sin(math.radians(psi0)))
            tpar = dot(v, u)
            perp = abs(v[0] * u[1] - v[1] * u[0])
            closest.append({'ring': i + 1, 'along_mm': tpar, 'centreDistance_mm': perp, 'interfaceClearance_mm': perp - Rr})
        straight.append({'case': c, 'tip': p0, 'heading_deg': psi0, 'numericalStop': bn, 'numericalStop_ds_mm': sn,
                         'numericalStop_s_total_mm': 41.4 + sn, 'numericalStopPoint': pn,
                         'physicalEvent': bp, 'physicalEvent_ds_mm': sp, 'physicalEventPoint': pp,
                         'tangentLineClosestApproach': closest,
                         'minHeading_reach_top_guide_numerical_deg': min_heading(p0, 'numerical', 'TOP_GUIDE_LIMIT'),
                         'minHeading_reach_top_edge_nominal_deg': min_heading(p0, 'physical', 'TOP_EDGE')})
    feas['straightContinuationFromS4'] = straight

    turn = []
    for c in ['H']:
        for delta in [-3.0, -2.0, -1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0, 3.0]:
            for mode in ['numerical', 'physical']:
                p, psi, n, ev = tips[(c, 4)], heads[(c, 4)], 0, None
                while n < 200:
                    psi += delta
                    q = (p[0] + 4 * math.cos(math.radians(psi)), p[1] + 4 * math.sin(math.radians(psi)))
                    # sample the segment for nominal events
                    for j in range(1, 41):
                        z = (p[0] + (q[0] - p[0]) * j / 40, p[1] + (q[1] - p[1]) * j / 40)
                        ev = blocked(z, mode)
                        if ev: break
                    n += 1
                    if ev: break
                    p = q
                turn.append({'fromCase': c, 'perStepTurn_deg': delta, 'mode': mode, 'event': ev,
                             'steps': n, 'arc_at_event_mm': 41.4 + 4 * n})
    feas['constantTurnFamily_from_H_S4'] = turn

    # mesh budget: linear T3 growth S1..S4
    budget = []
    for c in CASES:
        ys = [int(fv(c, k, 'mesh_T3')) for k in range(1, 5)]
        xs = [1, 2, 3, 4]
        mx, my = sum(xs) / 4, sum(ys) / 4
        slope = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / sum((x - mx) ** 2 for x in xs)
        incs = [ys[i + 1] - ys[i] for i in range(3)]
        budget.append({'case': c, 'T3_S1_S4': ys, 'T3_per_step_fit': slope, 'T3_per_step_min': min(incs),
                       'T3_per_step_max': max(incs),
                       'steps_to_budget_at_fit': (pol['numerics']['primaryT3Budget'] - ys[-1]) / slope})
    feas['meshBudget'] = budget
    feas['minArcToTopGuideLine_mm'] = 41.4 + (Hp - guide - max(tips[(c, 4)][1] for c in CASES))
    check('F1', 'Pure-geometry feasibility analysis computed (no K/angle forecast)', True, None, status='GEOMETRY_ONLY')

    # ---------------- write
    res = {'schema': 'NewMetacomp.G2.LP1.SR1.IndependentCheck.v1', 'issue': 56,
           'inputs': {'csv_sha256': sha_bytes(CSV.read_bytes()), 'ledger_sha256': sha_bytes(LEDGER.read_bytes()),
                      'reduced_records_sha256': sha_bytes(REDUCED.read_bytes()),
                      'mesh_quality_sha256': sha_bytes(MESHQ.read_bytes()), 'policy_blob_sha256': POLICY_SHA},
           'summary': {'total': len(checks), 'passed': sum(c['pass'] for c in checks)},
           'checks': checks, 'classesS4': classes, 'feasibility': feas, 'crossCheckFrozenS2': x2,
           'noFEM': True, 'noMesh': True, 'noRecordWritten': True}
    (OUT / 'SR1_CHECK_RESULTS.json').write_text(json.dumps(res, indent=1, default=str), encoding='utf-8', newline='\n')

    def wcsv(name, data):
        if not data: return
        keys = []
        for r in data:
            keys += [k for k in r if k not in keys]
        with (OUT / name).open('w', encoding='utf-8', newline='\n') as f:
            w = csv.DictWriter(f, fieldnames=keys, lineterminator='\n')
            w.writeheader()
            for r in data:
                w.writerow({k: (json.dumps(v) if isinstance(v, (list, tuple, dict)) else v) for k, v in r.items()})
    wcsv('SR1_comparisons.csv', cmp_rows)
    wcsv('SR1_offset_uncertainty.csv', off_rows)
    wcsv('SR1_compliance_energy_check.csv', fd_rows)
    wcsv('SR1_clearances.csv', cl_rows)
    wcsv('SR1_frozenS2_crosscheck.csv', x2)
    wcsv('SR1_feasibility_constant_turn.csv', turn)
    for c in checks:
        print(f"{c['id']:4s} {'PASS' if c['pass'] else 'FAIL'}  {c['status']:22s} {c['description'][:90]}")
    print(f"SR1_INDEPENDENT_CHECKS={res['summary']['passed']}/{res['summary']['total']} NO_FEM=1 NO_MESH=1")


if __name__ == '__main__':
    main()
