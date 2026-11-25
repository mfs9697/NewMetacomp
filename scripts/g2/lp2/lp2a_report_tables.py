"""LP2-A1 demonstration report: Ukrainian tables generated from the committed campaign evidence (read-only).
usage: python -I scripts/g2/lp2/lp2a_report_tables.py <repo> -> prints tables; exit 1 if the report lacks any line"""
import json, math, os, sys
sys.stdout.reconfigure(encoding='utf-8')
R = sys.argv[1]; E = os.path.join(R, 'docs/research/G2_LP2_evidence/campaign_20261125')
A = json.load(open(os.path.join(E, 'LP2A_ANALYSIS.json'), encoding='utf-8'))
V = json.load(open(os.path.join(E, 'LP2A_VERIFY_ONLY.json'), encoding='utf-8'))
rep = open(os.path.join(R, 'docs/research/G2_LP2A1_DEMONSTRATION_REPORT_UA.md'), encoding='utf-8').read()
SUP = str.maketrans('-0123456789', '⁻⁰¹²³⁴⁵⁶⁷⁸⁹')
uf = lambda x, nd, s=False: (f"{x:+.{nd}f}" if s else f"{x:.{nd}f}").replace('.', ',').replace('-', '−')
def sci(x, nd, s=False):
    e = math.floor(math.log10(abs(x))); m = x / 10 ** e
    if round(abs(m), nd) >= 10: m /= 10; e += 1
    return uf(m, nd, s) + '·10' + str(e).translate(SUP)
nm = {'H': 'H', 'stiff13': 'жорсткі {1,3}', 'soft2': 'м’яке {2}', 'soft1': 'м’яке {1}'}
W = A['states']; L = []
L += ['| Випадок | Стан | s, мм | вершина, мм | курс, ° | K_I | K_II | K_II/K_I | G | θ_МКН, ° |', '|---|---|---|---|---|---|---|---|---|---|']
for c in ('H', 'stiff13', 'soft2', 'soft1'):
    w = W[c]
    for j in range(5, 9):
        L.append(f"| {nm[c]} | S{j} | {uf(w['s'][j], 1)} | ({uf(w['tip'][j][0], 4)}; {uf(w['tip'][j][1], 4)}) | {uf(w['head'][j], 3)} | {sci(w['KI'][j], 6)} | {sci(w['KII'][j], 6, True)} | "
                 f"{uf(w['KII'][j] / w['KI'][j], 5)} | {sci(w['G'][j], 5)} | {uf(w['MTS'][j], 4)} |")
L += ['']
L += ['| s, мм | G_H, 10⁻⁸ Н/мм | F_G жорсткі {1,3} | F_G м’яке {2} | F_G м’яке {1} |', '|---|---|---|---|---|']
for j in range(9):
    L.append(f"| {uf(W['H']['s'][j], 1)} | {uf(1e8 * W['H']['G'][j], 4)} | {uf(100 * A['stiff13']['F_G'][j], 3, True)} % | {uf(100 * A['soft2']['F_G'][j], 3, True)} % | {uf(100 * A['soft1']['F_G'][j], 3, True)} % |")
L += ['']
L += ['| Архітектура | величина | S4 | S5 | S6 | S7 | S8 |', '|---|---|---|---|---|---|---|']
for c in ('stiff13', 'soft2', 'soft1'):
    r = A[c]
    L.append(f"| {nm[c]} | d, мм | " + ' | '.join(uf(x, 4, True) for x in r['d_mm'][4:]) + ' |')
    L.append(f"| {nm[c]} | Δкурс, ° | " + ' | '.join(uf(x, 3, True) for x in r['dHeading_deg'][4:]) + ' |')
    L.append(f"| {nm[c]} | Δθ_МКН, ° | " + ' | '.join(uf(x, 4, True) for x in r['dMTS_deg'][4:]) + ' |')
L += ['']
L += ['| Випадок | класифікація | останній стан | маска | до кілець 1 / 2 / 3 у S8, мм | найближче кільце | обмеження прогнозу S9 | обірвано межею S8 |', '|---|---|---|---|---|---|---|---|']
for t in A['H4']['terminals']:
    mask = ''.join(str(int(x)) for x in t['ringMask'])
    act = 'активне' if t['nearestRingActive'] else 'пасивне'
    g = ', '.join(t['terminatingGuards']) if t['terminatingGuards'] else 'немає (MATRIX_ADVANCE)'
    L.append(f"| {nm[t['caseId']]} | {t['classification']} | S{t['lastAcceptedState']} | {mask} | {' / '.join(uf(x, 2) for x in t['clearanceToRingCircles_mm'])} | {t['nearestRing']} ({act}) | {g} | {'так' if t['truncatedByCeiling'] else 'ні'} |")
print('\n'.join(L))
ns = V['numericalChecks']
extra = [f"{nnz}/16" for nnz in [sum(1 for n in ns if n['pass'])]]
print('numerical', extra, 'COD-EDI max', max(n['CODminusEDI_rel'] for n in ns), 'J/G-1', max(abs(n['JoverGminus1']) for n in ns))
miss = [l for l in L if l and l not in rep]
for l in miss: print('MISSING IN REPORT:', l)
print(f'RESULT {len([l for l in L if l]) - len(miss)}/{len([l for l in L if l])} table lines present')
sys.exit(1 if miss else 0)
