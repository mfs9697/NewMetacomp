"""Independent (non-MATLAB) recomputation of the M5-X6 pins in the execution clone. Read-only.
usage: python -I activation_hashcheck.py <execRepo> <out.json>"""
import hashlib, json, os, sys
R, out = sys.argv[1], sys.argv[2]
f = lambda p: hashlib.sha256(open(os.path.join(R, p), 'rb').read()).hexdigest()
dig = lambda s: hashlib.sha256(s.encode('utf-8')).hexdigest()
APPROVED = {
 'plan': 'e6153735e76b09382a24376002110f7f07485d27db12aaca09108419e43fea52',
 'a1policy': '312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013',
 'a1source': '7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947',
 'x6source': 'f21d7d44a2de33922dd766c226320cec0695252f24d5516908f500c3a8d8e6bb',
 'meshes': '9c3d0f4560da34216c674cf8af5a9f6782d28ab80ec86076f284e55278904ad8',
 'contract': '0d163d9af4b8c97308ae548fe75f3a1214bd193de302ed8b9ae3bc67dc16ae8f',
 'lp1policy': '074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091'}
TOKEN = ('G2M5X6|plan=e6153735e76b09382a24376002110f7f07485d27db12aaca09108419e43fea52|a1policy=312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013'
         '|a1source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947|x6source=f21d7d44a2de33922dd766c226320cec0695252f24d5516908f500c3a8d8e6bb'
         '|meshes=9c3d0f4560da34216c674cf8af5a9f6782d28ab80ec86076f284e55278904ad8|configs=X6-01,X6-02,X6-03,X6-04,X6-05,X6-06|maxSolves=6')
g2 = os.path.join(R, 'matlab', 'g2'); x6 = os.path.join(R, 'scripts', 'g2', 'm5', 'x6')
v = 'vendor_p010_a14d8872'
rel = sorted([n for n in os.listdir(g2) if n.endswith('.m')] + [v + '/' + n for n in os.listdir(os.path.join(g2, v)) if n.endswith('.m')])
a1src = dig('\n'.join(r + ' ' + f('matlab/g2/' + r) for r in rel))
names = sorted(n for n in os.listdir(x6) if n.endswith('.m'))
x6src = dig('\n'.join(n + ' ' + f('scripts/g2/m5/x6/' + n) for n in names))
pol = json.load(open(os.path.join(g2, 'G2_A1_POLICY_v1.json'), encoding='utf-8'))
plan = json.load(open(os.path.join(x6, 'G2_M5_X6_PLAN_v1.json'), encoding='utf-8'))
keys = sorted(d['key'] for d in plan['diagonal'])
man = dig('\n'.join(k + ' ' + pol['meshes'][k]['contentSHA256'] for k in keys))
got = {'plan': f('scripts/g2/m5/x6/G2_M5_X6_PLAN_v1.json'), 'a1policy': f('matlab/g2/G2_A1_POLICY_v1.json'), 'a1source': a1src,
       'x6source': x6src, 'meshes': man, 'contract': f('docs/research/G2_M5_X6_evidence/M5X6_CONTRACT.json'),
       'lp1policy': f('matlab/g2/G2_LP1_POLICY_v2.json')}
tok = (f"G2M5X6|plan={got['plan']}|a1policy={got['a1policy']}|a1source={got['a1source']}|x6source={got['x6source']}"
       f"|meshes={got['meshes']}|configs={','.join(c['id'] for c in plan['configurations'])}|maxSolves={plan['maxSolves']}")
CT = json.load(open(os.path.join(R, 'docs/research/G2_M5_X6_evidence/M5X6_CONTRACT.json'), encoding='utf-8'))
Q = json.load(open(os.path.join(R, 'docs/research/G2_M5_X6_evidence/M5X6_QUALIFICATION.json'), encoding='utf-8'))
AU = json.load(open(os.path.join(R, 'docs/research/G2_M5_X6_evidence/M5X6_DIAGONAL_AUDIT.json'), encoding='utf-8'))
cfg = [(c['id'], c['pathCase'], c['materialCase'], ''.join(str(int(m)) for m in c['mask']), c['ratio'], c['meshContentSHA256'] == pol['meshes'][c['meshKey']]['contentSHA256']) for c in plan['configurations']]
res = {'schema': 'NewMetacomp.G2.M5X6.ActivationHashCheck.v1', 'pins': {k: {'approved': APPROVED[k], 'recomputed': got[k], 'match': got[k] == APPROVED[k]} for k in APPROVED},
       'a1SourceFiles': len(rel), 'x6SourceFiles': names, 'tokenRecomputed': tok, 'tokenMatchesApproved': tok == TOKEN,
       'tokenInQualification': Q['token'] == TOKEN, 'tokenInContract': CT['token'] == TOKEN,
       'configurations': cfg, 'configurationsExact': [c[0] for c in cfg] == ['X6-01', 'X6-02', 'X6-03', 'X6-04', 'X6-05', 'X6-06'] and all(c[5] for c in cfg),
       'contract': {'pass': CT['pass'], 'passed': CT['passed'], 'total': CT['total'], 'negativeTests': CT['negativeTests'], 'physicalSolves': CT['physicalSolves']},
       'qualification': {'status': Q['status'], 'protectedFilesHashed': Q['protectedFilesHashed'], 'protectedUnchanged': Q['protectedUnchanged'], 'goPresent': Q['goPresent']},
       'diagonalAudit': {'allPass': AU['allPass'], 'rows': [(r['key'], r['pass']) for r in AU['rows']]},
       'goFilePresent': os.path.isfile(os.path.join(x6, 'G2_M5_X6_SCIENTIFIC_GO_v1.json')),
       'm5x6OutputFolders': [d for d in os.listdir(os.path.join(R, 'outputs')) if 'm5x6' in d]}
res['allPinsMatch'] = all(p['match'] for p in res['pins'].values())
json.dump(res, open(out, 'w', encoding='utf-8'), indent=1)
print('pins', {k: p['match'] for k, p in res['pins'].items()}, 'token', res['tokenMatchesApproved'], res['tokenInQualification'], res['tokenInContract'],
      'configs', res['configurationsExact'], 'contract', CT['passed'], '/', CT['total'], 'qual', Q['status'], Q['protectedFilesHashed'],
      'diag', AU['allPass'], 'GO', res['goFilePresent'], 'outputs', res['m5x6OutputFolders'])
