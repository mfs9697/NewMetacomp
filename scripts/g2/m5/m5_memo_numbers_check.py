"""G2-M5: recompute every number cited in the Ukrainian memorandum from the evidence and check that the
memo states it (Ukrainian decimal comma, Unicode minus). Read-only; no FEM, no MATLAB.
usage: python -I scripts/g2/m5/m5_memo_numbers_check.py <repo>
"""
import json, math, os, sys

sys.stdout.reconfigure(encoding='utf-8')
R = sys.argv[1]
memo = open(os.path.join(R, 'docs/research/G2_M5_MECHANISM_ATTRIBUTION_MEMO_UA.md'), encoding='utf-8').read()
D = json.load(open(os.path.join(R, 'docs/research/G2_M5_evidence/M5_EXISTING_EVIDENCE.json'), encoding='utf-8'))
A1 = json.load(open(os.path.join(R, 'matlab/g2/evidence/a1_campaign_20261122/campaign/A1_ANALYSIS.json'), encoding='utf-8'))
C = ['stiff13', 'soft2', 'soft1']
dec, st = D['decompositionExisting'], D['ownPathStates']
by = {(r['case'], r['state']): r for r in st}

def f(x, nd, sign=False):
    s = f"{x:+.{nd}f}" if sign else f"{x:.{nd}f}"
    return s.replace('.', ',').replace('-', '−')
checks = []
def chk(label, s):
    checks.append((label, s, s in memo))

for c in C:
    a, b = dec[c]['S0_direct_equals_total'], dec[c]['S2_direct_M4B']
    for lab, x in (('S0', a), ('S2', b)):
        chk(f'{c} {lab} F_G', f(100 * x['F_G'], 3, True).replace('+', '+') + ' %' if x['F_G'] > 0 else f(100 * x['F_G'], 3) + ' %')
        chk(f'{c} {lab} dKI', (f(100 * x['dKI_rel'], 3, True)) + ' %')
        chk(f'{c} {lab} dKII/K', f(x['dKII_overK'], 4, True))
        chk(f'{c} {lab} dTheta', f(x['dMTS_deg'], 3, True))
    chk(f'{c} S2 total', f(100 * dec[c]['S2_total_ownPath'], 3, True) + ' %')
    chk(f'{c} S2 residual pp', f(100 * dec[c]['S2_pathInArchitectureMaterial_additive'], 3, True) + ' в.п.')
    chk(f'{c} S2 residual share', f(100 * dec[c]['S2_pathShareOfTotal'], 1) + ' %')
    chk(f'{c} R_path', f(dec[c]['S2_R_path_multiplicative'], 5))
    chk(f'{c} S4 F_G (A0, m=0)', f(100 * dec[c]['S4_total_B0'], 3, True) + ' %')
    chk(f'{c} S4 F_G (B9)', f(100 * A1['F_G'][c][3], 3, True))
    chk(f'{c} first-kink share', f(D['steering'][c]['firstKinkShare_4n_sin'], 3, True))
    chk(f'{c} d(S4) mm', f(D['steering'][c]['d_S4_mm'], 2, True))
    irk = D['irwinKies'][c]['deltaC_rel_S0toS4']
    chk(f'{c} dC/C S0->S4', f(100 * irk[0], 2, True) + ' → ' + f(100 * irk[4], 2, True) + ' %')
    chk(f'{c} equivalent shift mm', f(D['stability'][c]['equivalentCrackLengthShift_mm_at_S4'], 1, True))
# shares of total and residual range
shares = [dec[c]['S2_direct_M4B']['F_G'] / dec[c]['S2_total_ownPath'] for c in C]
chk('direct share range', f'{round(100 * min(1.0, min(shares)))}–' + f(100 * max(shares), 1) + ' %')
res = [abs(dec[c]['S2_pathShareOfTotal']) for c in C]
chk('residual share range', f(100 * min(res), 1) + '–' + f(100 * max(res), 1) + ' %')
# stability, H
sH = D['stability']['H']
chk('G growth load control', f(sH['G_S4_over_S0_loadControl'], 2) + ' раза при сталій силі')
chk('G growth displacement control', f(sH['G_S4_over_S0_displacementControl'], 2) + ' раза при сталому')
chk('compliance growth', f(100 * (sH['compliance'][4] / sH['compliance'][0] - 1), 1) + ' %')
rates = sH['dlnG_da_per_mm']
chk('log growth rate', f(100 * min(rates), 1) + '–' + f(100 * max(rates), 1) + ' % на 1 мм')
allr = [D['stability'][c][k] for c in ['H'] + C for k in ('G_S4_over_S0_loadControl', 'G_S4_over_S0_displacementControl')]
chk('G growth range all', f'{round(100 * (min(allr) - 1))}–{round(100 * (max(allr) - 1))} %')
# geometry
L = D['loadPathLine']['ringCentreDistance_mm']
chk('ring2 to line', f(abs(L[1]), 1) + ' мм від центру'); chk('ring1 below line', f(abs(L[0]), 1) + ' мм нижче')
chk('ring3 above line', f(abs(L[2]), 1) + ' мм вище')
tl = D['loadPathLine']['tipS0S4_H_mm']; chk('tip to line S0', f(abs(tl[0]), 1) + ' мм у S0'); chk('tip to line S4', f(abs(tl[4]), 1) + ' мм у S4')
k = D['KIIoverKI_H']; chk('KII/KI S0', f(k[0], 3)); kk = [r['KIIoverKI'] for r in st if r['state'] > 0]
chk('KII/KI after S0', f(min(kk), 3) + '–' + f(max(kk), 3))
dk = [dec[c]['S0_direct_equals_total']['dKII_overK'] for c in C]
chk('dKII/K S0 range', f(min(dk), 3) + '…' + f(max(dk), 3, True))
mts = [r['MTS_deg'] for r in st if r['state'] > 0]
chk('local MTS S1-S4 range', f(max(mts), 1) + ' … ' + f(min(mts), 1) + '°')
# energy partition
sh = [r[f'ring{i}EnergyShare'] for r in st for i in (1, 2, 3)]
chk('ring energy share', f(100 * min(sh), 1) + '–' + f(100 * max(sh), 1) + ' %')
s2 = by[('soft2', 4)]; chk('soft2 ring1 energy', f(100 * s2['dU_ring1_rel'], 1, True) + ' %'); chk('soft2 ring3 energy', f(100 * s2['dU_ring3_rel'], 1, True) + ' %')
s13 = by[('stiff13', 4)]; chk('stiff13 ring2 energy', f'{round(abs(100 * s13["dU_ring2_rel"]))} %')
oth = [abs(by[('soft2', 4)]['dU_ring1_rel']), abs(by[('soft2', 4)]['dU_ring3_rel']), abs(by[('soft1', 4)]['dU_ring2_rel']),
       abs(by[('soft1', 4)]['dU_ring3_rel']), abs(by[('stiff13', 4)]['dU_ring2_rel'])]
chk('other-ring energy range', f'{round(100 * min(oth))}–{round(100 * max(oth))} %')
cl = [r['tipToRingInterface_mm'][0] for r in st]; chk('clearance range', f'{round(min(cl))}–{round(max(cl))} мм')
tr = dec['soft2']['trend_F_G_S0toS4']; chk('soft2 trend', f(100 * tr[0], 2) + ' → ' + f(100 * tr[4], 2))
s0c = D['S0_commonGeometry']
chk('S0 content SHA prefix', s0c['meshContentSHA256']['H'][:8])
chk('S0 fields compared', f"{s0c['fieldsCompared']}/{s0c['fieldsCompared']}")
assert s0c['rawMatFileSHAEqual'] is False and s0c['meshArrayContentIdentical'] is True and s0c['rawSHA_matches_MATLABcheck'] is True
# Irwin-Kies last-two-step agreement
ag = [abs(D['irwinKies'][c]['F_G_fd_compliance_per_step'][j] - D['irwinKies'][c]['F_G_EDI_midstep_mean'][j]) for c in C for j in (2, 3)]
chk('Irwin-Kies agreement', f(100 * min(ag), 2) + '–' + f(100 * max(ag), 1) + ' в.п.')
signs_ok = all((D['irwinKies'][c]['d_deltaC_da_sign'][j] == '+') == (D['irwinKies'][c]['F_G_EDI_midstep_mean'][j] > 0) for c in C for j in range(4))

bad = [c for c in checks if not c[2]]
for lab, s, ok in checks:
    print(('OK   ' if ok else 'MISS ') + f'{lab}: "{s}"')
print(f'Irwin-Kies sign agreement on all steps: {signs_ok}')
print(f'RESULT {len(checks) - len(bad)}/{len(checks)} cited values found; S0 flags consistent')
sys.exit(0 if not bad and signs_ok else 1)
