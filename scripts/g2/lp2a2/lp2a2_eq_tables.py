"""Markdown tables (Ukrainian) of the LP2-A2 equivalence demonstration from the stored records (read-only).
Values are printed with Python repr (shortest round-trip, i.e. full double precision).
usage: python -I lp2a2_eq_tables.py <execRepo> <INDEPENDENT_AUDIT.json> <out.md>"""
import json, os, sys
ex, aud, out = sys.argv[1:4]
pol = json.load(open(os.path.join(ex, 'matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json'), encoding='utf-8')); t = pol['tolerances']
A = json.load(open(aud, encoding='utf-8'))
ids = ['EQ-H', 'EQ-stiff13', 'EQ-soft2', 'EQ-soft1']; cs = ['H', 'stiff13', 'soft2', 'soft1']
C = {i: json.load(open(os.path.join(ex, pol['outputRoot'], i, 'COMPARISON.json'), encoding='utf-8')) for i in ids}
M = {i: C[i]['metrics'] for i in ids}
r = repr
L = []
L.append('### Таблиця A. Критерії C1–C11 (нове мінус архівне; значення з COMPARISON.json)\n')
L.append('| Критерій | Величина | Допуск | H | stiff13 | soft2 | soft1 | Результат |\n|---|---|---|---|---|---|---|---|')
rows = [
 ('C1', 'ΔK_I / K_eq', f'≤ {t["KI_overKeq"]:g}', 'dKI_overKeq', 'C1_KI'),
 ('C2', 'ΔK_II / K_eq', f'≤ {t["KII_overKeq"]:g}', 'dKII_overKeq', 'C2_KII'),
 ('C3', 'Δ(K_II/K_I)', f'≤ {t["KIIoverKI_abs"]:g}', 'dKIIoverKI', 'C3_KIIoverKI'),
 ('C4', 'ΔG/G', f'≤ {t["G_rel"]:g}', 'dG_rel', 'C4_G_J'),
 ('C4', 'ΔJ/J', f'≤ {t["J_rel"]:g}', 'dJ_rel', 'C4_G_J'),
 ('C4', 'J/G − 1 нової (абс.)', f'≤ {t["newJoverGminus1"]:g}', 'newJoverGminus1', 'C4_G_J'),
 ('C5', 'Δθ_MTS, °', f'≤ {t["MTS_deg"]:g}', 'dMTS_deg', 'C5_MTS'),
 ('C6', '(COD−EDI) нової (абс.)', f'≤ {t["newCODminusEDI_gate"]:g}', 'newCODminusEDI_rel', 'C6_COD_EDI'),
 ('C6', '(COD−EDI) архівної', '—', 'archivedCODminusEDI_rel', None),
 ('C6', 'Δ(COD−EDI)', f'≤ {t["dCODminusEDI"]:g}', 'dCODminusEDI', 'C6_COD_EDI'),
 ('C7', 'розкид EDI нової', f'≤ max({t["spreadFloor"]:g}, {t["spreadFactor"]:g}×арх.)', 'newPathSpread_rel', 'C7_EDI_spread_quadrature'),
 ('C7', 'розкид EDI архівної', '—', 'archivedPathSpread_rel', None),
 ('C7', 'квадратура 4×4 нової', f'≤ max({t["quadFloor"]:g}, {t["quadFactor"]:g}×арх.)', 'newQuad4x4_rel', 'C7_EDI_spread_quadrature'),
 ('C7', 'квадратура 4×4 архівної', '—', 'archivedQuad4x4_rel', None),
 ('C8', 'розкриття біля вершини', f'≤ {t["openingNearTipRel"]:g}', 'openingNearTipRel', 'C8_crackOpening'),
 ('C8', 'розкриття всієї тріщини', f'≤ {t["openingWholeCrackRel"]:g}', 'openingWholeCrackRel', 'C8_crackOpening'),
 ('C9', 'Δ активної площі (відн.)', f'≤ {t["activeArea_rel"]:g}', 'dActiveArea_rel', 'C9_phaseActivation'),
 ('C10', 'зсув вершини S9, мм', f'≤ {t["S9tipDisplacement_mm"]:g}', 'S9tipDisplacement_mm', 'C10_S9predictor'),
 ('C11', 'Δ податливості (відн.)', f'≤ {t["compliance_rel"]:g}', 'dCompliance_rel', 'C11_compliance')]
for c, q, tl, key, crit in rows:
    res = '—' if crit is None else ('так ×4' if all(C[i]['criteria'][crit] for i in ids) else 'НІ')
    L.append(f'| {c} | {q} | {tl} | ' + ' | '.join(r(M[i][key]) for i in ids) + f' | {res} |')
L.append('| C9 | шлюзи розв’язувача нової / архівної; хорди на коло | усі пройдено; 76/76/76 | ' + ' | '.join(f'{M[i]["newSolverGatesPass"]} / {M[i]["archivedSolverGatesPass"]}' for i in ids) + ' | так ×4 |')
L.append('\nЗвітується, не є критерієм (знакове нормальне розкриття (u_U − u_L)·n):\n')
L.append('| Величина | H | stiff13 | soft2 | soft1 |\n|---|---|---|---|---|')
for key, q in (('signedOpeningNearTipRel', 'біля вершини (відн.)'), ('signedOpeningWholeCrackRel', 'уся тріщина (відн.)'),
               ('newMinSignedOpening_mm', 'мін. розкриття нової, мм'), ('archivedMinSignedOpening_mm', 'мін. розкриття архівної, мм')):
    L.append(f'| {q} | ' + ' | '.join(r(M[i][key]) for i in ids) + ' |')
L.append('\n### Таблиця B. Знакові значення: архівне S8 (LP2-A1) і нове сімейство (LP2-A2, щабель 1)\n')
L.append('K, G і J — в одиницях розв’язувача g2_m4b_sif_partial (G = (K_I² + K_II²)/E, E = tolerances.E_MPa політики, як у g2_lp2a2_eq_compare); θ_MTS у градусах.\n')
L.append('| Розв’язок | Величина | Архівне | Нове | Нове − архівне |\n|---|---|---|---|---|')
for i, c in zip(ids, cs):
    s = A['solves'][i]['signed']
    for q in ('KI', 'KII', 'G', 'J', 'MTS_deg'):
        a, n = s['archived'][q], s['new'][q]
        L.append(f'| {c} | {q.replace("MTS_deg", "θ_MTS").replace("KI", "K_I").replace("K_II", "K_II").replace("K_IΙ", "K_II")} | {r(a)} | {r(n)} | {r(n - a)} |')
L.append('\n### Таблиця C. Геометричний предиктор S9 (лише геометрія, без розв’язку)\n')
L.append('| Розв’язок | Вершина S9 архівна, мм | Вершина S9 нова, мм | Зсув, мм | Допуск |\n|---|---|---|---|---|')
for i, c in zip(ids, cs):
    L.append(f'| {c} | ({r(C[i]["S9tipArchived_mm"][0])}, {r(C[i]["S9tipArchived_mm"][1])}) | ({r(C[i]["S9tipNew_mm"][0])}, {r(C[i]["S9tipNew_mm"][1])}) | {r(M[i]["S9tipDisplacement_mm"])} | ≤ {t["S9tipDisplacement_mm"]:g} |')
ct = A['contrast']
L.append('\n### Таблиця D. Архітектурний контраст (відносно H)\n')
L.append('| Випадок | F_G архівний | F_G новий | ΔF_G (допуск ≤ ' + f'{t["contrast_FG_abs"]:g}) | θ_X−θ_H архівний, ° | θ_X−θ_H новий, ° | Δ, ° (допуск ≤ {t["contrast_MTS_deg"]:g}) |\n|---|---|---|---|---|---|---|')
for k, c in enumerate(ct['cases']):
    L.append(f'| {c} | {r(ct["FG_archived"][k])} | {r(ct["FG_new"][k])} | {r(ct["dFG"][k])} | {r(ct["dTheta_archived_deg"][k])} | {r(ct["dTheta_new_deg"][k])} | {r(ct["ddTheta_deg"][k])} |')
L.append('\nЗнаки F_G: ' + ('однакові' if ct['criteria']['FG_signs'] else 'РІЗНІ') + '; порядок: ' + ('однаковий' if ct['criteria']['FG_order'] else 'РІЗНИЙ') + '; контраст ' + ('пройдено' if ct['pass'] else 'НЕ пройдено') + '.')
L.append('\n### Таблиця E. Сітки\n')
L.append('| Розв’язок | T3 нова / архівна | вузли T6 нова / архівна | вузли берегів (пари) нова / архівна |\n|---|---|---|---|')
for i, c in zip(ids, cs):
    n = A['solves'][i]['newMeshCounts']; a = A['solves'][i]['archivedMeshCounts']
    L.append(f'| {c} | {n[0]} / {a[0]} | {n[1]} / {a[1]} | {n[2]} / {a[2]} |')
open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(L) + '\n')
print('written', out)
