"""Markdown tables (Ukrainian) generated from the independent audit LP2B1S10_AUDIT_v2.json; fills the memo template.
usage: python -I make_tables.py <audit.json> <memoTemplate.md> <out.md>"""
import json, sys
A = json.load(open(sys.argv[1], encoding='utf-8')); s = A['science']; T = s['S10']; E = s['evolution']
cases = ['H', 'stiff13', 'soft2', 'soft1']
lab = {'H': 'H (000, 1)', 'stiff13': 'stiff13 (101, 2)', 'soft2': 'soft2 (010, 0,5)', 'soft1': 'soft1 (100, 0,5)'}
ua = lambda x, f: (f % x).replace('.', ',').replace('-', '−')
rows = ['| Архітектура (маска, E_к/E_м) | K_I, МПа·√мм | K_II, МПа·√мм | K_II/K_I | J, Н/мм | G, Н/мм | F_G | θ_MTS, ° | курс, ° |',
        '|---|---|---|---|---|---|---|---|---|']
for c in cases:
    t = T[c]
    rows.append(f"| {lab[c]} | {ua(t['KI'], '%.10f')} | {ua(t['KII'], '%.9e')} | {ua(t['KIIoverKI'], '%.7f')} | {ua(t['J'], '%.9e')} | {ua(t['G'], '%.9e')} | "
                f"{ua(t['F_G'], '%+.6f')} | {ua(t['MTS_deg'], '%+.6f')} | {ua(t['heading_deg'], '%.6f')} |")
tab1 = '\n'.join(rows)
rows = ['| Архітектура | вершина (x, y), мм | зміщення від H: бічне / вздовж / повне, мм | до кола кільця 1 / 2 / 3, мм | податливість, мм/Н |', '|---|---|---|---|---|']
for c in cases:
    t = T[c]
    rows.append(f"| {lab[c]} | ({ua(t['tip_mm'][0], '%.6f')}; {ua(t['tip_mm'][1], '%.6f')}) | {ua(t['signedLateralOffsetFromH_mm'], '%+.4f')} / {ua(t['alongOffsetFromH_mm'], '%+.4f')} / {ua(t['offsetFromH_mm'], '%.4f')} | "
                f"{' / '.join(ua(x, '%.4f') for x in t['tipToRingCircle_mm'])} | {ua(t['compliance_mm_per_N'], '%.6e')} |")
tab2 = '\n'.join(rows)
rows = ['| Стан | s, мм | F_G stiff13 | F_G soft2 | F_G soft1 | приріст F_G soft1 | бічне зміщення soft1 від H, мм | 10³·K_II/K_I soft1 | 10³·K_II/K_I H |', '|---|---|---|---|---|---|---|---|---|']
inc = [None] + s['soft1_F_G_increments']
for k in range(11):
    rows.append(f"| S{k} | {ua(E['soft1'][k]['s_mm'], '%.1f')} | {ua(E['stiff13'][k]['F_G'], '%+.6f')} | {ua(E['soft2'][k]['F_G'], '%+.6f')} | {ua(E['soft1'][k]['F_G'], '%+.6f')} | "
                f"{'—' if inc[k] is None else ua(inc[k], '%+.6f')} | {ua(E['soft1'][k]['lateralOffsetFromH_mm'], '%+.5f')} | {ua(1e3 * E['soft1'][k]['KIIoverKI'], '%.4f')} | {ua(1e3 * E['H'][k]['KIIoverKI'], '%.4f')} |")
tab3 = '\n'.join(rows)
g = s['G_increase_S9_to_S10']
tab4 = ' | '.join(f"{c}: {ua(100 * g[c], '%+.3f')} %" for c in cases)
t = open(sys.argv[2], encoding='utf-8').read()
for k, v in (('{TAB_S10_K}', tab1), ('{TAB_S10_GEOM}', tab2), ('{TAB_EVOLUTION}', tab3), ('{TAB_G_GROWTH}', tab4)):
    assert t.count(k) == 1, k; t = t.replace(k, v)
assert '{' + 'TAB' not in t
open(sys.argv[3], 'w', encoding='utf-8', newline='\n').write(t)
print('memo written')
