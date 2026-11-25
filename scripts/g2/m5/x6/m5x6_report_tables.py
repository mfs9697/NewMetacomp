"""M5-X6 demonstration: Ukrainian markdown tables generated from the committed campaign evidence (read-only).
usage: python -I scripts/g2/m5/x6/m5x6_report_tables.py <repo>   -> prints tables; exit 1 if the report lacks any of them
"""
import json, math, os, sys
sys.stdout.reconfigure(encoding='utf-8')
R = sys.argv[1]
E = os.path.join(R, 'docs/research/G2_M5_X6_evidence/campaign_20261125')
A = json.load(open(os.path.join(E, 'M5X6_ANALYSIS.json'), encoding='utf-8'))
CL = json.load(open(os.path.join(E, 'M5X6_CALLS.json'), encoding='utf-8'))
G1 = json.load(open(os.path.join(R, 'docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json'), encoding='utf-8'))
rep = open(os.path.join(R, 'docs/research/G2_M5_X6_DEMONSTRATION_REPORT_UA.md'), encoding='utf-8').read()
SUP = str.maketrans('-0123456789', '⁻⁰¹²³⁴⁵⁶⁷⁸⁹')
uf = lambda x, nd, s=False: (f"{x:+.{nd}f}" if s else f"{x:.{nd}f}").replace('.', ',').replace('-', '−')
def sci(x, nd, s=False):
    e = math.floor(math.log10(abs(x))); m = x / 10 ** e
    if round(abs(m), nd) >= 10: m /= 10; e += 1
    return uf(m, nd, s) + '·10' + str(e).translate(SUP)
arch = [('stiff13', 'жорсткі {1,3}'), ('soft2', 'м’яке {2}'), ('soft1', 'м’яке {1}')]
lines = []
# table 1: six crossed solutions
cfg = {'X6-01': ('H', 'жорсткі {1,3}'), 'X6-02': ('stiff13', 'H'), 'X6-03': ('H', 'м’яке {2}'), 'X6-04': ('soft2', 'H'), 'X6-05': ('H', 'м’яке {1}'), 'X6-06': ('soft1', 'H')}
J = {}
for a, _ in arch:
    r = A[a]['J']; xh = A[a]['records']['XH']; hx = A[a]['records']['HX']; J[xh] = r['qXH']; J[hx] = r['qHX']
t1 = ['| № | Траєкторія | Матеріал | K_I | K_II | G | J | θ_МКН | час, с |', '|---|---|---|---|---|---|---|---|---|']
for c in CL:
    p, m = cfg[c['config']]
    t1.append(f"| {c['config']} | {p}_B9 | {m} | {sci(c['KI'], 6)} | {sci(c['KII'], 6, True)} | {sci(c['G'], 6)} | {sci(J[c['config']], 6)} | {uf(c['MTS_deg'], 4)}° | {uf(c['seconds'], 2)} |")
lines += t1 + ['']
# table 2: decomposition of G
t2 = ['| Архітектура | F_G | F_mat | F_path | F_int | F_path + F_int | \\|F_mat\\|/\\|F_G\\| | залишок тотожності |', '|---|---|---|---|---|---|---|---|']
for a, lab in arch:
    g = A[a]['G']
    t2.append(f"| {lab} | {uf(100*g['F_tot'], 4, True)} % | {uf(100*g['F_mat'], 4, True)} % | {uf(100*g['F_path'], 4, True)} % | {uf(100*g['F_int'], 4, True)} % | {uf(100*g['F_pathPlusInt'], 4, True)} % | {uf(100*A[a]['P1_directShare'], 1)} % | {sci(abs(g['identityResidual']), 0) if g['identityResidual'] else '0'} |")
lines += t2 + ['']
# table 3: K_I, K_II/K and MTS decompositions
t3 = ['| Архітектура | величина | повна зміна | матеріал | траєкторія | взаємодія |', '|---|---|---|---|---|---|']
for a, lab in arch:
    k = A[a]['KI']; t3.append(f"| {lab} | K_I, % | {uf(100*k['F_tot'], 3, True)} | {uf(100*k['F_mat'], 3, True)} | {uf(100*k['F_path'], 3, True)} | {uf(100*k['F_int'], 3, True)} |")
    k = A[a]['KIIoverK']; t3.append(f"| {lab} | K_II/\\|K_HH\\| | {uf(k['F_tot'], 5, True)} | {uf(k['F_mat'], 5, True)} | {uf(k['F_path'], 5, True)} | {uf(k['F_int'], 5, True)} |")
    k = A[a]['MTS_deg']; t3.append(f"| {lab} | θ_МКН, ° | {uf(k['F_tot'], 4, True)} | {uf(k['F_mat'], 4, True)} | {uf(k['F_path'], 4, True)} | {uf(k['F_int'], 4, True)} |")
lines += t3 + ['']
# table 4: bookkeeping alternatives
t4 = ['| Архітектура | F_mat (опора H на Γ_H) | частка Шеплі матеріалу | матеріал з опорою X на Γ_X | R_mat · R_path · R_int |', '|---|---|---|---|---|']
for a, lab in arch:
    g = A[a]['G']
    t4.append(f"| {lab} | {uf(100*g['F_mat'], 4, True)} % | {uf(100*g['shapley_mat'], 4, True)} % | {uf(100*g['refXX_mat'], 4, True)} % | {uf(g['R_mat'], 6)} · {uf(g['R_path'], 6)} · {uf(g['R_int'], 6)} |")
lines += t4 + ['']
# table 5: predictions
fo = {x['architecture']: x['firstOrder_dUda'] for x in G1['firstOrderArchitecture'] if x['state'] == 4}
pre = [x for x in G1['firstOrderArchitecture'] if x['state'] in (0, 2)] + G1['firstOrderSingleRing']
rs = [x['observedOverFirstOrder'] for x in pre if x['observedOverFirstOrder'] > 1]; rf = [x['observedOverFirstOrder'] for x in pre if x['observedOverFirstOrder'] < 1]
t5 = ['| Архітектура | П1 | П2 | П3: знак F_path / F_int | \\|F_int\\| > 2U_m | П4: межі F_mat | П4: F_mat / перше наближення (межі) | П4 |', '|---|---|---|---|---|---|---|---|']
for a, lab in arch:
    g = A[a]['G']; band = rs if fo[a] * g['F_mat'] > 0 and (g['F_mat'] / fo[a]) > 1 and a == 'stiff13' else (rs if a == 'stiff13' else rf)
    lo, hi = sorted([100 * fo[a] * min(band), 100 * fo[a] * max(band)]); ratio = g['F_mat'] / fo[a]
    inside = min(band) <= ratio <= max(band)
    sg = lambda v: '+' if v > 0 else '−'
    t5.append(f"| {lab} | {'так' if A[a]['P1_pass'] else 'ні'} ({uf(100*A[a]['P1_directShare'], 1)} %) | {'так' if A[a]['P2_pass'] else 'ні'} | {sg(g['F_path'])} / {sg(g['F_int'])} | {'так' if A[a]['exceeds2Um']['F_int'] else 'ні'} ({sci(abs(g['F_int']), 1)}) | "
              f"{uf(lo, 2, lo > 0)}…{uf(hi, 2, hi > 0)} % | {uf(ratio, 3)} ({uf(min(band), 3)}–{uf(max(band), 3)}) | {'в межах' if inside else 'поза межами'} |")
lines += t5
txt = '\n'.join(lines)
print(txt)
miss = [l for l in lines if l and l not in rep]
for l in miss: print('MISSING IN REPORT:', l)
print(f'RESULT {len([l for l in lines if l]) - len(miss)}/{len([l for l in lines if l])} table lines present')
sys.exit(1 if miss else 0)
