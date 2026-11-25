"""LP2 memorandum: Ukrainian tables generated from the committed LP2 evidence (read-only).
usage: python -I scripts/g2/lp2/lp2_memo_tables.py <repo>  -> prints tables; exit 1 if the memo lacks any line
"""
import json, math, os, sys
sys.stdout.reconfigure(encoding='utf-8')
R = sys.argv[1]; E = os.path.join(R, 'docs/research/G2_LP2_evidence')
G = json.load(open(os.path.join(E, 'LP2_S5_GEOMETRY.json'), encoding='utf-8'))
memo = open(os.path.join(R, 'docs/research/G2_LP2_CONTINUATION_MEMO_UA.md'), encoding='utf-8').read()
SUP = str.maketrans('-0123456789', '⁻⁰¹²³⁴⁵⁶⁷⁸⁹')
uf = lambda x, nd, s=False: (f"{x:+.{nd}f}" if s else f"{x:.{nd}f}").replace('.', ',').replace('-', '−')
def sci(x, nd, s=False):
    e = math.floor(math.log10(abs(x))); m = x / 10 ** e
    if round(abs(m), nd) >= 10: m /= 10; e += 1
    return uf(m, nd, s) + '·10' + str(e).translate(SUP)
nm = {'H': 'H', 'stiff13': 'жорсткі {1,3}', 'soft2': 'м’яке {2}', 'soft1': 'м’яке {1}'}
cls = {'MATRIX_ADVANCE': 'MATRIX_ADVANCE', 'NUMERICAL_HOLD': 'NUMERICAL_HOLD', 'INTERFACE_APPROACH': 'INTERFACE_APPROACH'}
L = []
L += ['| Випадок | s, мм | вершина S4, мм | курс, ° | K_I | K_II | G | θ_МКН, ° |', '|---|---|---|---|---|---|---|---|']
for r in G['rows']:
    s = r['S4']
    L.append(f"| {nm[r['caseId']]} | {uf(s['arc_mm'], 1)} | ({uf(s['tip_mm'][0], 4)}; {uf(s['tip_mm'][1], 4)}) | {uf(s['heading_deg'], 3)} | {sci(s['KI'], 6)} | {sci(s['KII'], 6, True)} | {sci(s['G'], 6)} | {uf(s['MTS_deg'], 4)} |")
L += ['']
L += ['| Випадок | вершина S5, мм | курс, ° | до кілець 1 / 2 / 3, мм | запас напрямної до кілець, мм | запас до країв плити (min), мм | K1–K10 | класифікація |', '|---|---|---|---|---|---|---|---|']
for r in G['rows']:
    g = r['S5_geometry']; m = g['clearanceMetrics']; t = r['S5_B0']['tip_mm']
    L.append(f"| {nm[r['caseId']]} | ({uf(t[0], 4)}; {uf(t[1], 4)}) | {uf(r['S5_B0']['heading_deg'], 3)} | {' / '.join(uf(v, 2) for v in g['tipToRingCircle_mm'])} | "
             f"{' / '.join(uf(v, 2) for v in m['guideRingMargin_mm'])} | {uf(min(m['guidePlateMargin_mm']), 2)} | {'так' if g['kinkGatesPass'] else 'ні'} | {g['classification']} |")
L += ['']
L += ['| Випадок | Δθ (B9 − A0), ° | зсув вершини S5, мм | заморожений кут: допустимих станів | обмеження | прямий хід: допустимих станів | обмеження |', '|---|---|---|---|---|---|---|']
for r in G['rows']:
    o = r['outlook']; f, s = o['frozenMTS'], o['straight']
    L.append(f"| {nm[r['caseId']]} | {sci(r['B9minusB0']['MTS_deg'], 2, True)} | {sci(r['B9minusB0']['tipDistance_mm'], 2)} | {f['admissibleAdditionalStates']} (до S{f['lastAdmissibleState']}) | {f['classification']}, {f['objects']} | "
             f"{s['admissibleAdditionalStates']} (до S{s['lastAdmissibleState']}) | {s['classification']}, {s['objects']} |")
print('\n'.join(L))
miss = [l for l in L if l and l not in memo]
for l in miss: print('MISSING IN MEMO:', l)
print(f'RESULT {len([l for l in L if l]) - len(miss)}/{len([l for l in L if l])} table lines present')
sys.exit(1 if miss else 0)
