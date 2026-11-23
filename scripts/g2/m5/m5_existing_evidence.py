"""G2-M5 read-only analysis of EXISTING records (no FEM, no MATLAB): mechanism attribution inputs.

Sources (all committed, path-free):
  LP1/A0 own-path states S0-S4 (B0 meshes): docs/research/G2_LP1_SR1_independent_check/LP1_records_reduced.json
  A1 S4 Family B levels (B0..B9):            matlab/g2/evidence/a1_campaign_20261122/campaign/A1_ANALYSIS.json
  M4.B frozen homogeneous S2 (direct effect): matlab/g2/evidence/m4b_20261121/analysis/cases_16_logical.csv
  M3 full-band R_direct/R_path (context):     matlab/g2/evidence/m3_20261121/analysis/m3_decomposition.csv
Outputs: M5_EXISTING_EVIDENCE.json and CSV tables in docs/research/G2_M5_evidence/.
usage: python -I scripts/g2/m5/m5_existing_evidence.py <repo>
"""
import csv, json, math, os, sys

R = sys.argv[1]
EV = os.path.join(R, 'docs', 'research', 'G2_M5_evidence')
LP1 = json.load(open(os.path.join(R, 'docs/research/G2_LP1_SR1_independent_check/LP1_records_reduced.json'), encoding='utf-8'))['states']
A1 = json.load(open(os.path.join(R, 'matlab/g2/evidence/a1_campaign_20261122/campaign/A1_ANALYSIS.json'), encoding='utf-8'))
M4B = {r['physical_case']: r for r in csv.DictReader(open(os.path.join(R, 'matlab/g2/evidence/m4b_20261121/analysis/cases_16_logical.csv'), encoding='utf-8'))}
POL = json.load(open(os.path.join(R, 'matlab/g2/G2_LP1_POLICY_v2.json'), encoding='utf-8'))
CASES = ['H', 'stiff13', 'soft2', 'soft1']
ARCH = {'stiff13': 'c2p0_101', 'soft2': 'c0p5_010', 'soft1': 'c0p5_100'}   # same masks/ratios as LP1 (SR1 A5)
E = POL['bvp']['E_MPa']; S1K = math.sqrt(1000.0)
centres = POL['geometry']['centres_mm']; RR = POL['geometry']['ringR_mm']
sup, load = POL['bvp']['pin_mm'], POL['bvp']['load_mm']

def st(c, k):
    for key, v in LP1.items():
        if v['STATE']['caseId'] == c and v['STATE']['stateIndex'] == k:
            return v
    raise KeyError((c, k))
def heading(t): return math.degrees(math.atan2(t[1], t[0]))
def line_dist(p):   # signed distance to the line support(pin) -> load point; + = above (left of direction)
    dx, dy = load[0] - sup[0], load[1] - sup[1]; L = math.hypot(dx, dy)
    return (dx * (p[1] - sup[1]) - dy * (p[0] - sup[0])) / L

out = {'schema': 'NewMetacomp.G2.M5.ExistingEvidence.v1', 'noFEM': True}
# ---------- 1. own-path states S0-S4 (B0)
rows = []
for k in range(5):
    H = st('H', k)
    tH = H['STATE']['tangent']; nH = [-tH[1], tH[0]]; pH = H['STATE']['polyline_mm'][-1]
    for c in CASES:
        s = st(c, k); S = s['STATE']; K = s['SOLUTION']['K']
        p = S['polyline_mm'][-1]; Uq = K['ringStrainEnergy_per_thickness']; Ut = K['strainEnergy_per_thickness']
        d = (p[0] - pH[0]) * nH[0] + (p[1] - pH[1]) * nH[1]
        rows.append({'case': c, 'state': k, 'arc_mm': S['arc_mm'], 'tip_x': p[0], 'tip_y': p[1], 'heading_deg': heading(S['tangent']),
                     'KI': S['KI'], 'KII': S['KII'], 'KIIoverKI': S['KII'] / S['KI'], 'G': S['G'], 'MTS_deg': S['MTS_deg'],
                     'compliance': K['compliance_mm_per_N'], 'U_total': Ut, 'U_matrix_region': Uq[0], 'U_ring1': Uq[1], 'U_ring2': Uq[2],
                     'U_ring3': Uq[3], 'meshSHA256': S['meshSHA256'], 'd_mm': d, 'tipToLine_mm': line_dist(p),
                     'tipToRingInterface_mm': [math.hypot(p[0] - q[0], p[1] - q[1]) - RR for q in centres]})
byk = {(r['case'], r['state']): r for r in rows}
for r in rows:
    h = byk[('H', r['state'])]; K0 = math.hypot(h['KI'], h['KII'])
    r['F_G'] = r['G'] / h['G'] - 1; r['dKI_rel'] = r['KI'] / h['KI'] - 1; r['dKII_overK'] = (r['KII'] - h['KII']) / K0
    r['dMTS_deg'] = r['MTS_deg'] - h['MTS_deg']; r['dHeading_deg'] = r['heading_deg'] - h['heading_deg']
    r['dCompliance_rel'] = r['compliance'] / h['compliance'] - 1
    for i in (1, 2, 3):
        r[f'ring{i}EnergyShare'] = r[f'U_ring{i}'] / r['U_total']
        r[f'dU_ring{i}_rel'] = r[f'U_ring{i}'] / h[f'U_ring{i}'] - 1
out['ownPathStates'] = rows
# C1: raw MAT-file identity and mesh-array identity are different properties. Raw SHA from the reduced records
# (provenance: STATE.meshSHA256); array/content identity from the read-only MATLAB check (S0_MESH_CONTENT_CHECK.json).
s0sha = {c: byk[(c, 0)]['meshSHA256'] for c in CASES}
S0C = json.load(open(os.path.join(EV, 'S0_MESH_CONTENT_CHECK.json'), encoding='utf-8'))
s0c = {x['case']: x for x in (S0C['cases'] if isinstance(S0C['cases'], list) else [S0C['cases']])}
assert set(s0c) == set(CASES), 'S0 content check must cover all four cases'
out['S0_commonGeometry'] = {
    'rawMatFileSHA256': s0sha,
    'rawMatFileSHA256_source': 'docs/research/G2_LP1_SR1_independent_check/LP1_records_reduced.json (STATE.meshSHA256)',
    'rawMatFileSHAEqual': len(set(s0sha.values())) == 1,
    'rawSHA_matches_MATLABcheck': all(s0c[c]['rawMatFileSHA256'] == s0sha[c] for c in CASES),
    'meshContentSHA256': {c: s0c[c]['meshContentSHA256'] for c in CASES},
    'fieldsCompared': s0c['H']['fieldsCompared'],
    'differingFieldsVsH': {c: s0c[c]['differingFieldsVsH'] for c in CASES},
    'meshArrayContentIdentical': all(s0c[c]['arraysIdenticalToH'] for c in CASES)
                                 and len({s0c[c]['meshContentSHA256'] for c in CASES}) == 1,
    'meshArrayContentIdentical_source': 'docs/research/G2_M5_evidence/S0_MESH_CONTENT_CHECK.json (s0_mesh_check_v2.m, plain MATLAB load, no FEM)',
    'polylinesEqual': len({json.dumps(st(c, 0)['STATE']['polyline_mm']) for c in CASES}) == 1}

# ---------- 2. direct (material-only) effect at fixed homogeneous geometry: S0 (common) and S2 (M4.B frozen = H S2)
GH2 = float(M4B['none']['G_1N_J_per_m2']) * 1e-9 if float(M4B['none']['G_1N_J_per_m2']) > 1e-3 else float(M4B['none']['G_1N_J_per_m2'])
dec = {}
for c in CASES[1:]:
    m = M4B[ARCH[c]]; n = M4B['none']
    KIn, KIIn = float(n['KI_perkN']) / (1000 / S1K), float(n['KII_perkN']) / (1000 / S1K)
    KIm, KIIm = float(m['KI_perkN']) / (1000 / S1K), float(m['KII_perkN']) / (1000 / S1K)
    Gn, Gm = (KIn ** 2 + KIIn ** 2) / E, (KIm ** 2 + KIIm ** 2) / E
    s2 = byk[(c, 2)]; h2 = byk[('H', 2)]; s0 = byk[(c, 0)]; s4 = byk[(c, 4)]
    direct2 = Gm / Gn - 1; total2 = s2['F_G']
    dec[c] = {
        'S0_direct_equals_total': {'F_G': s0['F_G'], 'dKI_rel': s0['dKI_rel'], 'dKII_overK': s0['dKII_overK'], 'dMTS_deg': s0['dMTS_deg']},
        'S2_direct_M4B': {'F_G': direct2, 'F_G_table': float(m['F_G']), 'dKI_rel': KIm / KIn - 1,
                          'dKII_overK': (KIm and (KIIm - KIIn) / math.hypot(KIn, KIIn)), 'dMTS_deg': float(m['F_theta_deg']) if 'F_theta_deg' in m else float(m['theta_MTS_deg']) - float(n['theta_MTS_deg']),
                          'M4B_baseline_G_vs_LP1_H_S2_rel': Gn / h2['G'] - 1},
        'S2_total_ownPath': total2,
        'S2_pathInArchitectureMaterial_additive': total2 - direct2,            # [G_X(G_X) - G_X(G_H)] / G_H(G_H)
        'S2_R_direct': Gm / Gn, 'S2_R_path_multiplicative': (1 + total2) / (1 + direct2),
        'S2_pathShareOfTotal': (total2 - direct2) / total2,
        'S2_crossed_H_on_X_path': None,                                        # never computed
        'S4_total_B0': s4['F_G'], 'S4_total_B9': A1['F_G'][c][3],
        'S4_direct': None, 'S4_path': None, 'S4_interaction': None,           # require the six crossed solves
        'trend_F_G_S0toS4': [byk[(c, k)]['F_G'] for k in range(5)],
    }
out['decompositionExisting'] = dec

# ---------- 3. geometry: ring placement relative to the support-load line and to the tip
out['loadPathLine'] = {'from_pin': sup, 'to_load': load,
                       'ringCentreDistance_mm': [line_dist(q) for q in centres],
                       'ringIntersectsLine': [abs(line_dist(q)) < RR for q in centres],
                       'holeIntersectsLine': [abs(line_dist(q)) < POL['geometry']['holeR_mm'] for q in centres],
                       'tipS0S4_H_mm': [byk[('H', k)]['tipToLine_mm'] for k in range(5)]}

# ---------- 4. growth of G with crack length and stability indicators (homogeneous and architectures)
stab = {}
for c in CASES:
    G = [byk[(c, k)]['G'] for k in range(5)]; C = [byk[(c, k)]['compliance'] for k in range(5)]
    dlnG = [(math.log(G[k + 1]) - math.log(G[k])) / 4.0 for k in range(4)]
    Gu = [G[k] * (C[0] / C[k]) ** 2 for k in range(5)]   # fixed load-point displacement u = P0 C0
    stab[c] = {'G_S0toS4': G, 'dlnG_da_per_mm': dlnG, 'G_S4_over_S0_loadControl': G[4] / G[0],
               'G_S4_over_S0_displacementControl': Gu[4] / Gu[0], 'compliance': C}
for c in CASES[1:]:
    rate = stab['H']['dlnG_da_per_mm'][3]
    stab[c]['equivalentCrackLengthShift_mm_at_S4'] = math.log(1 + byk[(c, 4)]['F_G']) / rate
out['stability'] = stab

# ---------- 5. steering: S0 heading difference and its share of the S4 offset (SR1 D6), local MTS on own path
steer = {}
for c in CASES[1:]:
    d4 = byk[(c, 4)]['d_mm']; dth0 = byk[(c, 0)]['dMTS_deg']
    # C2: d = (x_X - x_H).n_H with n_H the LEFT normal of H; a positive (counter-clockwise) S0 kink difference moves
    # the tip toward +n_H, so the linearized offset after n = 4 segments of 4 mm is +4n sin(dTheta_S0) (no sign flip).
    steer[c] = {'dTheta_S0_deg': dth0, 'd_S4_mm': d4,
                'firstKinkShare_4n_sin': 4 * 4 * math.sin(math.radians(dth0)) / d4 if d4 else None,
                'firstKinkShare_note': 'linearized geometric estimate 16 sin(dTheta_S0)/d(S4); not a proof that the first kink alone causes later differences',
                'localMTSdiff_S1toS4_deg': [byk[(c, k)]['dMTS_deg'] for k in range(1, 5)],
                'frozenS2_F_theta_deg': dec[c]['S2_direct_M4B']['dMTS_deg']}
out['steering'] = steer
out['KIIoverKI_H'] = [byk[('H', k)]['KIIoverKI'] for k in range(5)]

# ---------- 6. energetic (Irwin-Kies) reading: G = (P^2/2t) dC/da, so F_G ~ d(C_X)/da / d(C_H)/da - 1
irk = {}
for c in CASES[1:]:
    CX = stab[c]['compliance']; CH = stab['H']['compliance']
    dCX = [(CX[k + 1] - CX[k]) / 4.0 for k in range(4)]; dCH = [(CH[k + 1] - CH[k]) / 4.0 for k in range(4)]
    irk[c] = {'deltaC_rel_S0toS4': [CX[k] / CH[k] - 1 for k in range(5)],
              'd_deltaC_da_sign': ['+' if (CX[k + 1] - CH[k + 1]) - (CX[k] - CH[k]) > 0 else '-' for k in range(4)],
              'F_G_fd_compliance_per_step': [dCX[k] / dCH[k] - 1 for k in range(4)],
              'F_G_EDI_midstep_mean': [0.5 * (byk[(c, k)]['F_G'] + byk[(c, k + 1)]['F_G']) for k in range(4)]}
irk['caveats'] = ['C_X and C_H are evaluated along different, architecture-specific crack trajectories',
                  'finite differences over 4-mm steps approximate dC/da; they do not isolate a unique local physical mechanism',
                  'the first increment (S0-S1) is sensitive to the concentrated point load (SR1 B10)',
                  'energetic interpretation consistent with the computed results; it does not independently prove why soft ring 2 shields']
out['irwinKies'] = irk
out['lateralOffset_d_mm'] = {c: [byk[(c, k)]['d_mm'] for k in range(5)] for c in CASES[1:]}

json.dump(out, open(os.path.join(EV, 'M5_EXISTING_EVIDENCE.json'), 'w', encoding='utf-8', newline='\n'), indent=1)
cols = ['case', 'state', 'arc_mm', 'tip_x', 'tip_y', 'heading_deg', 'KI', 'KII', 'KIIoverKI', 'G', 'MTS_deg', 'F_G', 'dKI_rel', 'dKII_overK',
        'dMTS_deg', 'dHeading_deg', 'd_mm', 'compliance', 'dCompliance_rel', 'ring1EnergyShare', 'ring2EnergyShare', 'ring3EnergyShare',
        'dU_ring1_rel', 'dU_ring2_rel', 'dU_ring3_rel', 'tipToLine_mm']
with open(os.path.join(EV, 'M5_OWN_PATH_STATES.csv'), 'w', encoding='utf-8', newline='') as f:
    w = csv.writer(f, lineterminator='\n'); w.writerow(cols + ['tipToRing1Interface_mm'])
    for r in rows: w.writerow([r[k] for k in cols] + [r['tipToRingInterface_mm'][0]])
print(json.dumps({'S0_rawEqual': out['S0_commonGeometry']['rawMatFileSHAEqual'], 'S0_contentIdentical': out['S0_commonGeometry']['meshArrayContentIdentical'], 'line': out['loadPathLine']['ringCentreDistance_mm']}, indent=0))
for c in CASES[1:]:
    x = dec[c]
    print(c, 'S0', round(100 * x['S0_direct_equals_total']['F_G'], 4), 'S2dir', round(100 * x['S2_direct_M4B']['F_G'], 4),
          'S2tot', round(100 * x['S2_total_ownPath'], 4), 'path', round(100 * x['S2_pathInArchitectureMaterial_additive'], 4),
          'S4', round(100 * x['S4_total_B9'], 4), 'trend', [round(100 * v, 3) for v in x['trend_F_G_S0toS4']])
print('stab', {c: (round(stab[c]['G_S4_over_S0_loadControl'], 4), round(stab[c]['G_S4_over_S0_displacementControl'], 4)) for c in CASES})
print('dlnG H', [round(v, 5) for v in stab['H']['dlnG_da_per_mm']], 'shift', {c: round(stab[c]['equivalentCrackLengthShift_mm_at_S4'], 3) for c in CASES[1:]})
print('steer', {c: (round(steer[c]['dTheta_S0_deg'], 4), round(steer[c]['d_S4_mm'], 4), round(steer[c]['frozenS2_F_theta_deg'], 4)) for c in CASES[1:]})
