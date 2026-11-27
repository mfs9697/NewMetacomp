"""Ukrainian Markdown tables of campaign G2-LP2B1-EQ-001 from the INDEPENDENT audit JSON (full precision, repr).
usage: python lp2b1eq_tables.py <audit.json> <out.md>"""
import json, sys

A = json.load(open(sys.argv[1], encoding='utf-8'))
IDS = ['EQB-soft1-S9', 'EQB-H-S10']
r = lambda x: repr(float(x)) if not isinstance(x, bool) else ('так' if x else 'ні')
esc = lambda s: s.replace('|', '\\|')
L = []
rows = [  # (criterion, quantity, archived key, new key, signed metric key, tolerance text, utilization key)
    ('C1', 'K_I, МПа·мм^0,5 (P = 1 Н)', 'archivedKI', 'newKI', 'dKI_overKeq', '|ΔK_I|/K_eq ≤ 5e-4', 'C1_KI'),
    ('C2', 'K_II, МПа·мм^0,5', 'archivedKII', 'newKII', 'dKII_overKeq', '|ΔK_II|/K_eq ≤ 5e-5', 'C2_KII'),
    ('C3', 'K_II/K_I', None, None, 'dKIIoverKI', '|Δ(K_II/K_I)| ≤ 1e-4', 'C3_KIIoverKI'),
    ('C4', 'G = (K_I²+K_II²)/E, Н/мм', 'archivedG', 'newG', 'dG_rel', '|G_н/G_а − 1| ≤ 1e-3', 'C4_G'),
    ('C4', 'J, Н/мм', 'archivedJ', 'newJ', 'dJ_rel', '|J_н/J_а − 1| ≤ 1e-3', 'C4_J'),
    ('C4', 'J/G − 1 (нове)', None, None, 'newJoverGminus1', '|J_н/G_н − 1| ≤ 1e-4', 'C4_JoverG'),
    ('C5', 'θ_MTS, °', 'archivedMTS_deg', 'newMTS_deg', 'dMTS_deg', '|Δθ| ≤ 0,006°; корінь допустимий', 'C5_MTS'),
    ('C6', 'COD−EDI (відносне)', 'archivedCODminusEDI_rel', 'newCODminusEDI_rel', 'dCODminusEDI', 'нове ≤ 0,03; |Δ| ≤ 1e-3', 'C6_dCOD'),
    ('C7', 'розкид шляхів EDI', 'archivedPathSpread_rel', 'newPathSpread_rel', None, 'нове ≤ max(1e-5, 5×архівне)', 'C7_spread'),
    ('C7', 'дрейф квадратури 4×4', 'archivedQuad4x4_rel', 'newQuad4x4_rel', None, 'нове ≤ max(1e-5, 5×архівне)', 'C7_quad'),
    ('C8', 'стрибок |u_U−u_L| біля вершини (≤ 3,3 мм)', None, None, 'openingNearTipRel', '≤ 1e-3', 'C8_nearTip'),
    ('C8', 'стрибок |u_U−u_L| по всій тріщині', None, None, 'openingWholeCrackRel', '≤ 2e-3', 'C8_wholeCrack'),
    ('C9', 'активна площа, мм²', 'archivedActiveArea_mm2', 'newActiveArea_mm2', 'dActiveArea_rel', '|ΔA|/max(A,1) ≤ 1e-9; 16 воріт; 76 хорд', 'C9_activeArea'),
    ('C10', 'наступна вершина, мм', None, None, 'nextTipDisplacement_mm', '≤ 5e-4 мм', 'C10_nextTip'),
    ('C11', 'піддатливість, мм/Н', 'archivedCompliance_mm_per_N', 'newCompliance_mm_per_N', 'dCompliance_rel', '|C_н/C_а − 1| ≤ 1e-3', 'C11_compliance'),
]
for sid in IDS:
    R = A['results'][sid]; m = R['metrics']; u = R['utilization']; fl = R['flags']
    L.append(f'### {sid}\n')
    L.append('| Крит. | Величина | Архівне (0,45 мм) | Нове (0,40 мм) | Знакова метрика | Правило | Використання |')
    L.append('|---|---|---|---|---|---|---|')
    for c, q, ka, kn, km, rule, ku in rows:
        L.append(f"| {c} | {esc(q)} | {r(m[ka]) if ka else '—'} | {r(m[kn]) if kn else '—'} | {r(m[km]) if km else '—'} | {esc(rule)} | {u[ku]:.3e} |")
    L.append(f"| C10 | координати наступної вершини (x, y), мм | ({r(m['archivedNextTipX_mm'])}, {r(m['archivedNextTipY_mm'])}) | ({r(m['newNextTipX_mm'])}, {r(m['newNextTipY_mm'])}) | Δ = ({r(R['diagnostics']['nextTipDelta_mm'][0])}, {r(R['diagnostics']['nextTipDelta_mm'][1])}) | — | — |")
    L.append('')
    L.append('Прапорці C1–C11 (незалежний аудит = записані): ' + ', '.join(f"{k.split('_')[0]} {'✓' if v else '✗'}" for k, v in fl.items()) + '\n')
    d = R['diagnostics']
    L.append('Діагностика розкриття (лише звітується):\n')
    L.append(f"- біля вершини: вузлів {m['nearTipNodes']} (архів {m['nearTipNodesArchived']}), max |Δj| = {r(d['nearTipMaxAbsJumpDiff_mm'])} мм, max |Δg| (знакове нормальне) = {r(d['nearTipMaxAbsSignedDiff_mm'])} мм; max j_нове = {r(m['newMaxJumpNearTip_mm'])} мм;")
    L.append(f"- вся тріщина: станцій {m['bankStationsNew']} (архів {m['bankStationsArchived']}), max |Δj| = {r(d['jumpWholeMax_absDiff_mm'])} мм на s = {d['jumpWholeMaxAt_station_mm']:.3f} мм; max j_нове = {r(m['newMaxJump_mm'])} мм;")
    L.append(f"- знакове нормальне розкриття, вся тріщина: відносна різниця {r(m['signedOpeningWholeCrackRel'])}; максимум |Δg| = {r(d['signedWholeMax_absDiff_mm'])} мм на s = {d['signedWholeMaxAt_station_mm']:.3f} мм ({d['nearestKinkStationDistance_mm']:.3f} мм за зламом s = 25,4 мм); біля вершини {r(m['signedOpeningNearTipRel'])}; мінімум g: нове {r(m['newMinSignedOpening_mm'])}, архів {r(m['archivedMinSignedOpening_mm'])} мм.\n")
open(sys.argv[2], 'w', encoding='utf-8', newline='\n').write('\n'.join(L) + '\n')
print('tables written')
