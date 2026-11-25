"""LP2-A3 scientific analysis from the actual records only (read-only; dump of g2 records S0-S11).
Per case and accepted state: s, tip, KI, KII, KII/KI, G, J, local MTS, global heading, guide-to-ring gaps, tip-to-ring
circles. Contrasts only at common accepted arclengths s = 25.4 + 4k: F_G = G_X/G_H - 1, F_J, increments; tip offsets
relative to H (dx, dy, signed normal offset along H's local normal n_H = R(+90 deg) t_H). No interpolation/extrapolation.
usage: python -I lp2a3_analyze.py <RECORD_DUMP.json> <policy.json> <out.json>"""
import json, math, sys
A = json.load(open(sys.argv[1], encoding='utf-8')); P = json.load(open(sys.argv[2], encoding='utf-8'))
E = P['bvp']['E_MPa']; cen = P['geometry']['centres_mm']; Rr = P['geometry']['ringR_mm']; Rg = 15.0
ids = [c['id'] for c in P['cases']]; masks = {c['id']: c['mask'] for c in P['cases']}
lst = lambda x: x if isinstance(x, list) else [x]
def mts(KI, KII): return math.degrees(2 * math.atan(-2 * KII / (KI + math.hypot(KI, math.sqrt(8) * KII))))
paths = {}
for id in ids:
    rows = []
    for h in lst(A['history'][id]):
        rows.append({'state': h['stateIndex'], 'source': 'A0' if h['stateIndex'] <= 4 else 'LP2-A1', 'poly': h['polyline_mm'], 'KI': h['KI'], 'KII': h['KII'],
                     'G': h['G'] if h['G'] is not None else (h['KI'] ** 2 + h['KII'] ** 2) / E, 'J': h['J']})
    for S in sorted(lst(A['cases'][id]['states']), key=lambda S: int(S['folder'][1:])):
        if 'state' in S:
            st = S['state']; rows.append({'state': st['stateIndex'], 'source': 'LP2-A3', 'poly': st['polyline_mm'], 'KI': S['K']['KI'], 'KII': S['K']['KII'], 'G': st['G'], 'J': S['K']['J']})
    for r in rows:
        p = r['poly']; tip = p[-1]; seg = (p[-1][0] - p[-2][0], p[-1][1] - p[-2][1])
        r.update({'s_mm': round(sum(math.hypot(p[i + 1][0] - p[i][0], p[i + 1][1] - p[i][1]) for i in range(len(p) - 1)), 9), 'tip_mm': tip,
                  'heading_deg': math.degrees(math.atan2(seg[1], seg[0])), 'MTS_deg': mts(r['KI'], r['KII']), 'KIIoverKI': r['KII'] / r['KI'],
                  'tipToRingCircle_mm': [math.hypot(tip[0] - c[0], tip[1] - c[1]) - Rr for c in cen],
                  'guideRingGap_mm': [math.hypot(tip[0] - c[0], tip[1] - c[1]) - Rr - Rg for c in cen]})
        del r['poly']
        r['tangent'] = [seg[0] / math.hypot(*seg), seg[1] / math.hypot(*seg)]
    paths[id] = rows
Hs = {r['state']: r for r in paths['H']}
contr = {}
for id in ids[1:]:
    out = []
    for r in paths[id]:
        h = Hs.get(r['state'])
        if h is None or abs(h['s_mm'] - r['s_mm']) > 1e-9: continue
        n = [-h['tangent'][1], h['tangent'][0]]; dx = r['tip_mm'][0] - h['tip_mm'][0]; dy = r['tip_mm'][1] - h['tip_mm'][1]
        out.append({'state': r['state'], 's_mm': r['s_mm'], 'F_G': r['G'] / h['G'] - 1, 'F_J': (r['J'] / h['J'] - 1) if (r['J'] and h['J']) else None,
                    'G_X': r['G'], 'G_H': h['G'], 'dx_mm': dx, 'dy_mm': dy, 'normalOffset_mm': dx * n[0] + dy * n[1],
                    'dHeading_deg': r['heading_deg'] - h['heading_deg'], 'dMTS_deg': r['MTS_deg'] - h['MTS_deg']})
    for i in range(1, len(out)): out[i]['dF_G'] = out[i]['F_G'] - out[i - 1]['F_G']
    contr[id] = out
term = {id: {'classification': A['cases'][id]['terminal']['classification'], 'lastAcceptedState': A['cases'][id]['terminal']['lastAcceptedState'],
             'failure': A['cases'][id]['terminal']['failure'], 'candidateTip_mm': lst(A['cases'][id]['terminal']['candidate']['polyline_mm'])[-1] if A['cases'][id]['terminal']['candidate'].get('polyline_mm') else None,
             'candidateClassification': A['cases'][id]['terminal']['candidate'].get('classification'),
             'candidateConstraints': A['cases'][id]['terminal']['candidate'].get('constraints'),
             'informationOnly': bool(A['cases'][id]['terminal'].get('candidateIsInformationOnly'))} for id in ids}
for id in ids:
    t = term[id]['candidateTip_mm']
    if t: term[id]['candidateGuideRingGap_mm'] = [math.hypot(t[0] - c[0], t[1] - c[1]) - Rr - Rg for c in cen]
res = {'schema': 'NewMetacomp.G2.LP2A3.Analysis.v1', 'E_MPa': E, 'paths': paths, 'contrastsVsH': contr, 'terminals': term, 'masks': masks,
       'note': 'unit-load conditional LEFM/MTS; contrasts only at common accepted arclengths; no interpolation or extrapolation; proximity terminals are numerical, not physical arrest or interface encounter'}
json.dump(res, open(sys.argv[3], 'w', encoding='utf-8', newline='\n'), indent=1)
for id in ids[1:]:
    print(id, ' '.join(f"S{c['state']}:{c['F_G']:+.5f}" for c in contr[id]))
for id in ids:
    r = paths[id][-1]; print(id, 'last S%d' % r['state'], 'G=%.6e' % r['G'], 'MTS=%+.4f' % r['MTS_deg'], 'head=%.4f' % r['heading_deg'], 'gap1=%.4f' % r['guideRingGap_mm'][0], term[id]['classification'])
