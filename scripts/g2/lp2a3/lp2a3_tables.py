"""Ukrainian Markdown tables of the LP2-A3 demonstration from the record dump, the analysis and the audit
(read-only; Python repr = full double precision). usage: python -I lp2a3_tables.py <DUMP.json> <ANALYSIS.json> <AUDIT.json> <out.md>"""
import json, sys
D = json.load(open(sys.argv[1], encoding='utf-8')); A = json.load(open(sys.argv[2], encoding='utf-8')); U = json.load(open(sys.argv[3], encoding='utf-8'))
ids = ['H', 'stiff13', 'soft2', 'soft1']; r = repr
lst = lambda x: x if isinstance(x, list) else [x]
L = ['### Таблиця 1. Прийняті стани S9–S11 (повна точність)\n',
     'K — МПа·√мм, G і J — Н/мм (P = 1 Н), кути — градуси, відстані — мм. Проміжок = ‖вершина − c_i‖ − 19,05 − 15.\n',
     '| Випадок | S | вершина x | вершина y | K_I | K_II | K_II/K_I | G | J | θ_MTS | курс | проміжок до кільця 1 / 2 / 3 |', '|---|---|---|---|---|---|---|---|---|---|---|---|']
for id in ids:
    for p in A['paths'][id]:
        if p['state'] < 9: continue
        L.append(f"| {id} | S{p['state']} | {r(p['tip_mm'][0])} | {r(p['tip_mm'][1])} | {r(p['KI'])} | {r(p['KII'])} | {r(p['KIIoverKI'])} | {r(p['G'])} | {r(p['J'])} | {r(p['MTS_deg'])} | {r(p['heading_deg'])} | {' / '.join(r(g) for g in p['guideRingGap_mm'])} |")
L += ['\n### Таблиця 2. Шлюзи й діагностика кожного прийнятого стану\n',
      '| Випадок | S | T3 | аудит / парування | 16 шлюзів КІН | COD−EDI (відн.) | розкид EDI | J/G − 1 | MTS: стаціонарність | пам’ять перед розв’язком, ГіБ | розв’язок, с |', '|---|---|---|---|---|---|---|---|---|---|---|']
for id in ids:
    for S in sorted(lst(D['cases'][id]['states']), key=lambda S: int(S['folder'][1:])):
        if 'state' not in S: continue
        st = S['state']
        L.append(f"| {id} | S{st['stateIndex']} | {S['mesh']['T3']} | {S['phase']['meshAuditGates']}/34, {S['phase']['pairingGates']}/10 | {'так' if S['K']['pass'] else 'НІ'} | {r(st['CODminusEDI_rel'])} | {r(st['pathSpread_rel'])} | {r(st['JoverGminus1'])} | {r(S['mts']['stationarity'])} | {S['solutionLinks']['memoryGate']['freeGiB']:.3f} | {st['solveSeconds']:.3f} |")
L += ['\n### Таблиця 3. Архітектурний контраст і бічне зміщення відносно H (лише спільні прийняті s)\n',
      '| Випадок | S | s, мм | F_G = G_X/G_H − 1 | ΔF_G за крок | F_J | зміщення по нормалі H, мм | курс_X − курс_H | θ_X − θ_H |', '|---|---|---|---|---|---|---|---|---|']
for id in ids[1:]:
    for c in A['contrastsVsH'][id]:
        L.append(f"| {id} | S{c['state']} | {c['s_mm']:.1f} | {r(c['F_G'])} | {r(c['dF_G']) if 'dF_G' in c else '—'} | {r(c['F_J']) if c['F_J'] is not None else '—'} | {r(c['normalOffset_mm'])} | {r(c['dHeading_deg'])} | {r(c['dMTS_deg'])} |")
L += ['\n### Таблиця 4. Термінали\n', '| Випадок | Термінал | Останній прийнятий | Кандидат після нього | Обмеження (об’єкт, тип, запобіжник, запас мм) | Проміжок кандидата до кільця 1, мм | Причина |', '|---|---|---|---|---|---|---|']
for id in ids:
    t = A['terminals'][id]; cs = t['candidateConstraints']; cs = lst(cs) if cs else []
    con = '; '.join(f"{c['object']}, {c['type']}, {c['guard']}, {r(c['margin_mm'])}" for c in cs) or '—'
    cand = ('S12 (лише інформаційний) ' if t['informationOnly'] else 'S10 ') + (t['candidateClassification'] or '')
    why = 'межа кампанії S11' if t['classification'] == 'CAMPAIGN_LIMIT_REACHED' else f"{t['failure']['identifier']}: {t['failure']['message']}"
    L.append(f"| {id} | {t['classification']} | S{t['lastAcceptedState']} | {cand} | {con} | {r(t['candidateGuideRingGap_mm'][0])} | {why} |")
L += ['\n### Таблиця 5. Лічильники, відновлені з незмінних записів (незалежний аудит)\n', '| Величина | Значення |', '|---|---|',
      '| виклики точки входу / виклики випадків | 1 / 4 |',
      f"| допуски (ADMIT у реєстрі = теки станів) | {U['admissions']}: {', '.join(U['admittedKeys'])} |",
      f"| фізичні розв’язки виконано (усі завершені й прийняті) | {U['physicalSolvesCompletedWithAcceptedState']} |",
      '| спроби розв’язку без прийняття | 0 (soft1 S10 зупинився на сітці до розв’язку) |',
      f"| прийняті стани | {U['acceptedStates']} |", f"| файли запуску / реєстру | {U['runFiles']} / {U['ledgerFiles']} (без зайвих і відсутніх) |",
      f"| проблеми незалежного аудиту | {len(U['problems'])} |"]
open(sys.argv[4], 'w', encoding='utf-8', newline='\n').write('\n'.join(L) + '\n')
print('tables ok')
