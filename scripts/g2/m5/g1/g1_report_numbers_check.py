"""G2-M5-X6/G1: recompute the numbers cited in the three Ukrainian documents from the committed evidence
and check that each document states them (Ukrainian decimal comma, Unicode minus, superscript exponents).
Read-only; no FEM, no MATLAB.
usage: python -I scripts/g2/m5/g1/g1_report_numbers_check.py <repo>
"""
import json, math, os, sys

sys.stdout.reconfigure(encoding='utf-8')
R = sys.argv[1]
rd = lambda p: open(os.path.join(R, p), encoding='utf-8').read()
js = lambda p: json.load(open(os.path.join(R, p), encoding='utf-8'))
docA = rd('docs/research/G2_M5_X6_EXECUTION_QUALIFICATION_UA.md')
docB = rd('docs/research/G2_G1_FIELD_INVESTIGATION_UA.md')
note = rd('docs/research/G2_M5_X6_G1_INTEGRATION_NOTE_UA.md')
G = js('docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json')
Q = js('docs/research/G2_M5_X6_evidence/M5X6_QUALIFICATION.json')
CT = js('docs/research/G2_M5_X6_evidence/M5X6_CONTRACT.json')
AU = js('docs/research/G2_M5_X6_evidence/M5X6_DIAGONAL_AUDIT.json')
AR = js('docs/research/G2_M5_X6_evidence/M5X6_ARCHIVE_CHECK.json')
PL = js('scripts/g2/m5/x6/G2_M5_X6_PLAN_v1.json')
A1 = js('matlab/g2/evidence/a1_campaign_20261122/campaign/A1_ANALYSIS.json')
M5 = js('docs/research/G2_M5_evidence/M5_EXISTING_EVIDENCE.json')
SUP = str.maketrans('-0123456789', '⁻⁰¹²³⁴⁵⁶⁷⁸⁹')
checks = []


def uf(x, nd, sign=False):
    s = f"{x:+.{nd}f}" if sign else f"{x:.{nd}f}"
    return s.replace('.', ',').replace('-', '−')


def sci(x, nd, sign=False):
    e = math.floor(math.log10(abs(x)))
    m = x / 10 ** e
    if round(abs(m), nd) >= 10:
        m /= 10; e += 1
    return uf(m, nd, sign) + '·10' + str(e).translate(SUP)


def chk(doc, label, s):
    text = {'A': docA, 'B': docB, 'N': note}[doc]
    checks.append((doc, label, s, s in text))


def thin(n):
    return f'{n:,}'.replace(',', ' ')


# ======================================================================= document B (G1)
pv = G['provenance']
chk('B', 'M4B energy reconstruction', sci(max(p['elementEnergyMaxRelErr'] for p in pv['M4B']), 1))
chk('B', 'R1 energy reconstruction', sci(max(p['elementEnergyMaxRelErr'] for p in pv['R1']), 1))
chk('B', 'LP1 energy reconstruction', sci(max(p['elementEnergyMaxRelErr'] for p in pv['LP1_H']), 1))
chk('B', 'LP1 owner ring energy', sci(max(p['ownerRingEnergyRelErr'] for p in pv['LP1_H']), 1))
betti = max(x['bettiRelErr'] for f in ('M4B', 'R1') for x in G['singleRing'][f])
chk('B', 'Betti max', sci(betti, 1))
d = G['line']['ringCentreSignedDistance_mm']
chk('B', 'ring1 to line', uf(abs(d[0]), 1) + ' мм нижче'); chk('B', 'ring2 to line', uf(d[1], 1) + ' мм від центру')
chk('B', 'ring3 to line', uf(d[2], 1) + ' мм вище')
env = G['ringEnvironment']['M4B']
for e in env:
    if e['region'].startswith('ring'):
        k = e['ring']
        row = f"| {k} | {uf(d[k-1], 1, True) if k > 1 else uf(d[k-1], 1)} мм | {uf(1e4*e['avgTensor_s1'], 2)} | {uf(1e4*e['avgTensor_s2'], 2)} | {uf(e['compressiveAxisAngleToLine_deg'], 1)}° | {uf(e['fracCompressionDominated'], 2)} / {uf(e['fracTensionDominated'], 2)} |"
        chk('B', f'ring table row {k}', row)
hl = G['holeEdge']['M4B']
for h in hl:
    chk('B', f"hole fit ring {h['ring']}", f"{uf(h['compressiveAxisAngleToLine_deg'], 1)}° ({uf(h['R2'], 3)})")
halo = [e for e in env if e['region'].startswith('halo')]
chk('B', 'halo angles', ', '.join(uf(e['compressiveAxisAngleToLine_deg'], 1) + '°' for e in halo[:2]) + ' і ' + uf(halo[2]['compressiveAxisAngleToLine_deg'], 1) + '°')
fd = G['ringEnvironmentFamilyDiff']
rmax = max(abs(x['meanSED_relDiff']) for x in fd if x['region'].startswith('ring'))
chk('B', 'family ring energy', f"не більше ніж на {round(rmax / 10 ** math.floor(math.log10(rmax)))}·10" + str(math.floor(math.log10(rmax))).translate(SUP))
chk('B', 'family halo energy', 'не більше ніж на ' + uf(100 * max(abs(x['meanSED_relDiff']) for x in fd), 1) + ' %')
chk('B', 'family angle', 'не більше ніж на ' + uf(max(abs(x['compressiveAxisAngle_diff_deg']) for x in fd), 1) + '°')
for c in G['corridor']['M4B']:
    o = c['offset_mm']; lab = '0 (пряма)' if o == 0 else (uf(o, 0, True) if o > 0 else uf(o, 0))
    row = f"| {lab} | {uf(c['medianAngle_deg'], 1)}° | {uf(c['fracWithin15deg'], 2)} | {uf(c['fracWithin30deg'], 2)} | {uf(c['fracCompressionDominated'], 2)} | {uf(1e4*c['meanS2'], 2)} |"
    chk('B', f'corridor row {o}', row)
cr = {c['offset_mm']: c for c in G['corridor']['M4B']}
chk('B', 'corridor SED 0 and +30', sci(cr[0]['meanSED'], 2) + ' і ' + sci(cr[30]['meanSED'], 2))
tp = {t['xi_mm']: t for t in G['influenceMapProfiles']['transverse']}
chk('B', 'max compression offsets', 's = ' + ', '.join(uf(tp[q]['sAtMostCompressiveSigma2_mm'], 0, True) for q in (150, 200)) + ' і ' + uf(tp[230]['sAtMostCompressiveSigma2_mm'], 0, True) + ' мм')
chk('B', 'max compression at 175', 'мінімум σ₂ при s = ' + uf(tp[175]['sAtMostCompressiveSigma2_mm'], 0))
tr = G['trajectories']['rows']
up = [t for t in tr if t['direction'] == 1]; dn = [t for t in tr if t['direction'] == -1]
chk('B', 'trajectories toward load', 'не далі ' + uf(max(t['maxAbsOffsetFromLine_mm'] for t in up), 1) + ' мм')
chk('B', 'trajectories toward pin', uf(min(t['maxAbsOffsetFromLine_mm'] for t in dn), 1) + '–' + uf(max(t['maxAbsOffsetFromLine_mm'] for t in dn), 1) + ' мм')
ex = [t for t in dn if t['stop'] == 'void_or_outside'][0]
chk('B', 'trajectory exit x', 'x = ' + uf(ex['end_mm'][0], 1) + ' мм')
chk('B', 'trajectory exit to pin', 'за ' + str(round(ex['end_mm'][0] - 25.4)) + ' мм від шарніра')
hp = G['homogeneousPath']; Ur = hp['U_ring']; U = hp['U_total']
for k in range(3):
    row = f"| {uf(1e8*Ur[0][k], 3)} | {uf(1e8*Ur[2][k], 3)} | {uf(1e8*Ur[4][k], 3)} | {uf(100*(Ur[4][k]/Ur[0][k]-1), 1, True)} % |"
    chk('B', f'ring energy row {k+1}', row)
chk('B', 'total energy row', f"| {uf(1e6*U[0], 3)} | {uf(1e6*U[2], 3)} | {uf(1e6*U[4], 3)} | {uf(100*(U[4]/U[0]-1), 1, True)} % |")
chk('B', 'ring2 drop summary', 'падає** на ' + uf(100 * (1 - Ur[4][1] / Ur[0][1]), 1) + ' %')
chk('B', 'ring1/3 rise summary', uf(100 * (Ur[4][0] / Ur[0][0] - 1), 1) + ' % і ' + uf(100 * (Ur[4][2] / Ur[0][2] - 1), 1) + ' %')
es = hp['ringEnvironmentByState']
ring = lambda s, k: [e for e in es[s] if e['ring'] == k and e['region'].startswith('ring')][0]
chk('B', 'ring2 stress evolution', 'з ' + uf(1e4 * ring(0, 2)['avgTensor_s2'], 2) + ' до ' + uf(1e4 * ring(4, 2)['avgTensor_s2'], 2) + '·10⁻⁴ МПа (' + uf(100 * (ring(4, 2)['avgTensor_s2'] / ring(0, 2)['avgTensor_s2'] - 1), 1) + ' %)')
chk('B', 'ring2 axis evolution', uf(ring(0, 2)['compressiveAxisAngleToLine_deg'], 1) + '° → ' + uf(ring(4, 2)['compressiveAxisAngleToLine_deg'], 1) + '°')
chk('B', 'ring1 tension evolution', 'з ' + uf(1e4 * ring(0, 1)['avgTensor_s1'], 2) + ' до ' + uf(1e4 * ring(4, 1)['avgTensor_s1'], 2))
chk('B', 'ring3 compression evolution', 'з ' + uf(1e4 * ring(0, 3)['avgTensor_s2'], 2) + ' до ' + uf(1e4 * ring(4, 3)['avgTensor_s2'], 2))
fs = [x for x in G['firstOrderSingleRing'] if x['family'] == 'M4B']
for k in (1, 2, 3):
    s_ = [x for x in fs if x['ring'] == k and x['contrast'] < 1][0]; h_ = [x for x in fs if x['ring'] == k and x['contrast'] > 1][0]
    row = (f"| {k} | {uf(100*s_['firstOrder'], 2, True)} % | {uf(100*s_['observed_F_G'], 2, True)} % | {uf(s_['observedOverFirstOrder'], 3)} | "
           f"{uf(100*h_['firstOrder'], 2, True)} % | {uf(100*h_['observed_F_G'], 2, True)} % | {uf(h_['observedOverFirstOrder'], 3)} |")
    chk('B', f'single ring row {k}', row)
r1 = [x for x in G['firstOrderSingleRing'] if x['family'] == 'R1']
chk('B', 'R1 ratio agreement', 'з точністю до ' + uf(max(abs(a['observedOverFirstOrder'] - b['observedOverFirstOrder']) for a, b in zip(fs, r1)) + 0.0005, 3))
fa = G['firstOrderArchitecture']
for x in fa:
    chk('B', f"arch {x['architecture']} S{x['state']}", f"{uf(100*x['firstOrder_dUda'], 2, True)} → {uf(100*x['observed_F_G'], 2, True)} % ({uf(x['observedOverFirstOrder'], 3)})")
allr = [x['observedOverFirstOrder'] for x in fa] + [x['observedOverFirstOrder'] for x in G['firstOrderSingleRing']]
soft = [r for r in allr if r < 1]; stiff = [r for r in allr if r > 1]
chk('B', 'soft ratio range', uf(min(soft), 2) + '–' + uf(max(soft), 2))
chk('B', 'stiff ratio range', uf(min(stiff), 2) + '–' + uf(max(stiff), 2))
nsign = sum(x['signAgrees'] for x in fa) + sum(x['signAgrees'] for x in G['firstOrderSingleRing'])
ntot = len(fa) + len(G['firstOrderSingleRing'])
chk('B', 'sign agreement count', f'{nsign} із {ntot}')
im = G['influenceMap']
for k in range(3):
    chk('B', f'map ring integral {k+1}', uf(im['ringIntegral_fromMap'][k], 4) + ' проти ' + uf(im['ringIntegral_fromRecords'][k], 4))
bx = G['influenceMapProfiles']['bandsByLinePart']
for part, lab in ((120, 'ξ 120–266 мм (бік сили)'), (40, 'ξ 40–120 мм (бік шарніра)')):
    row = '| ' + lab + ' | ' + ' | '.join(uf(b['fractionPositive'], 2) for b in bx if b['xi_from_mm'] == part) + ' |'
    chk('B', f'band row {part}', row)
for q in (150, 200, 230):
    lo, hi = tp[q]['negativeRunThroughLine_s_mm']
    chk('B', f'negative run {q}', 'від ' + uf(lo, 0) + ' до ' + uf(hi, 0, True) + ' мм на ξ = ' + str(q))
lo, hi = tp[175]['negativeRunThroughLine_s_mm']
chk('B', 'negative run 175', 'від ' + uf(lo, 0) + ' до ' + uf(hi, 0) + ' мм, далі перервана отвором 2')
cp = G['influenceMapProfiles']['ringColumn_y_meanIota_n']
neg = [r[0] for r in cp if r[1] < 0]
chk('B', 'ring column negative span', f'y від {round(min(neg))} до {round(max(neg))} мм')
oth = [abs(v) for x in G['singleRing']['M4B'] for i, v in enumerate(x['dU_ring_rel']) if i + 1 != x['ring']]
so = [abs(v) for x in G['singleRing']['M4B'] if x['contrast'] < 1 for i, v in enumerate(x['dU_ring_rel']) if i + 1 != x['ring']]
st = [abs(v) for x in G['singleRing']['M4B'] if x['contrast'] > 1 for i, v in enumerate(x['dU_ring_rel']) if i + 1 != x['ring']]
chk('B', 'other-ring energy changes', f'зростають на {round(100*min(so))}–{round(100*max(so))} % у разі м’якого кільця і падають на {round(100*min(st))}–{round(100*max(st))} %')
# ======================================================================= document A (M5-X6)
for r in AU['rows']:
    c = r['caseId']
    row = (f"`{r['fileSHA256']['STATE_mat'][:8]}…` / `{r['fileSHA256']['SOLUTION_mat'][:8]}…` | {thin(r['T3'])} / {thin(r['DOF'])} | "
           f"{sci(r['KI'], 6)} | {sci(r['KII'], 6, True)} | {sci(r['G'], 6)} | {uf(r['MTS_deg'], 4)}° | {r['mask']} / {uf(r['ratio'], 1) if r['ratio'] != round(r['ratio']) else str(round(r['ratio']))} |")
    chk('A', f'diagonal row {c}', row)
    chk('A', f'diagonal mesh {c}', '`' + PL['diagonal'][[d['caseId'] for d in PL['diagonal']].index(c)]['meshContentSHA256'][:8] + '…`')
chk('A', 'diagonal all pass', '4/4' if AU['allPass'] else 'FAIL')
chk('A', 'G recomputed', sci(max(r['Grecomputed_rel'] for r in AU['rows']), 1))
chk('A', 'residual', sci(max(r['relativeResidual'] for r in AU['rows']), 1))
chk('A', 'ring area equality', sci(AU['ringAreaEqualAcrossMeshes_maxRelDiff'], 1))
chk('A', 'tip gap', sci(max(d['tipNodeGap_mm'] for d in Q['dryChecks']), 1) + ' мм')
for dct in Q['dryChecks']:
    row = f"| {thin(dct['activeElements'])} | {dct['jumpEdges']} | {uf(dct['qClearance_mm'], 3)} | {dct['meshGates']} |"
    chk('A', f"dry row {dct['id']}", row)
chk('A', 'contract total', f"{CT['passed']}/{CT['total']}")
chk('A', 'negatives', f"{CT['negativeTests']} негативні")
from collections import Counter
cnt = Counter(r['kind'] for r in CT['rows'])
for kind, lab in (('go', 'GO-валідатор'), ('gate', 'Гейт'), ('ledger', 'Журнал і допуск'), ('driver', 'Драйвер'), ('activation', 'Активація'), ('analysis', 'Аналіз')):
    chk('A', f'group {kind}', f'| {lab} | {cnt[kind]}/{cnt[kind]} |')
chk('A', 'group audit/dry/closure', f"| Аудит, сухі виклики, закриття | {cnt['audit']+cnt['dry']+cnt['closure']}/{cnt['audit']+cnt['dry']+cnt['closure']} |")
chk('A', 'protected files', f"{Q['protectedFilesHashed']} захищених")
for key in ('planSHA256', 'a1SourceSHA256', 'x6SourceSHA256', 'meshManifestSHA256'):
    chk('A', key, Q[key])
import hashlib
chk('A', 'contract SHA', hashlib.sha256(open(os.path.join(R, 'docs/research/G2_M5_X6_evidence/M5X6_CONTRACT.json'), 'rb').read()).hexdigest())
chk('A', 'qualification commit', Q['sourceCommit'][:7])
chk('A', 'archive members', f"({AR['members']} членів)")
for a, lab in (('stiff13', 'жорсткі {1,3}'), ('soft2', 'м’яке {2}'), ('soft1', 'м’яке {1}')):
    chk('A', f'B6-B9 {a}', lab + ' ' + sci(abs(A1['F_G_B9minusB6'][a]), 1))
s4 = {x['architecture']: x for x in fa if x['state'] == 4}
chk('A', 'P4 first order', ', '.join(f"{lab} {uf(100*s4[a]['firstOrder_dUda'], 2, True if s4[a]['firstOrder_dUda'] > 0 else False)} %" for a, lab in (('stiff13', 'жорсткі {1,3}'), ('soft2', 'м’яке {2}'), ('soft1', 'м’яке {1}'))))
pre = [x for x in fa if x['state'] in (0, 2)] + G['firstOrderSingleRing']
rs = [x['observedOverFirstOrder'] for x in pre if x['observedOverFirstOrder'] > 1]
rf = [x['observedOverFirstOrder'] for x in pre if x['observedOverFirstOrder'] < 1]
chk('A', 'P4 stiff ratio band', uf(min(rs), 3) + '–' + uf(max(rs), 3))
chk('A', 'P4 soft ratio band', uf(min(rf), 3) + '–' + uf(max(rf), 3))
band = lambda a, r: sorted([100 * s4[a]['firstOrder_dUda'] * min(r), 100 * s4[a]['firstOrder_dUda'] * max(r)])
b1, b2, b3 = band('stiff13', rs), band('soft2', rf), band('soft1', rf)
chk('A', 'P4 band stiff13', 'від ' + uf(b1[0], 2) + ' до ' + uf(b1[1], 2) + ' %')
chk('A', 'P4 band soft2', 'від ' + uf(b2[0], 2) + ' до ' + uf(b2[1], 2) + ' %')
chk('A', 'P4 band soft1', 'від ' + uf(b3[0], 2, True) + ' до ' + uf(b3[1], 2, True) + ' %')
# ======================================================================= integration note
dS4 = [M5['steering'][c]['d_S4_mm'] for c in ('stiff13', 'soft2', 'soft1')]
chk('N', 'lateral offset range', 'від ' + uf(min(dS4), 2) + ' до ' + uf(max(dS4), 2, True) + ' мм')
fg4 = [A1['F_G'][c][3] for c in ('stiff13', 'soft2', 'soft1')]
chk('N', 'F_G S4 range', 'від ' + uf(100 * min(fg4), 1) + ' до ' + uf(100 * max(fg4), 1, True) + ' %')
cl = [r['tipToRingInterface_mm'] for r in M5['ownPathStates']]
chk('N', 'nearest ring clearance', f"{round(min(c[0] for c in cl))}–{round(max(c[0] for c in cl))} мм")
chk('N', 'all ring clearance', f"{round(min(min(c) for c in cl))}–{round(max(max(c) for c in cl))} мм")
fk = [M5['steering'][c]['firstKinkShare_4n_sin'] for c in ('stiff13', 'soft2', 'soft1')]
chk('N', 'first-kink share range', uf(min(fk), 2) + '–' + uf(max(fk), 2))

bad = [c for c in checks if not c[3]]
for doc, lab, s, ok in checks:
    print(('OK   ' if ok else 'MISS ') + f'[{doc}] {lab}: "{s}"')
print(f'RESULT {len(checks) - len(bad)}/{len(checks)} cited values found')
sys.exit(0 if not bad else 1)
