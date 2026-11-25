"""Independent (non-MATLAB) recomputation of the LP2-A1 pins and token in the execution clone. Read-only.
usage: python -I lp2_activation_hashcheck.py <execRepo> <out.json>"""
import hashlib, json, os, sys
R, out = sys.argv[1], sys.argv[2]
f = lambda p: hashlib.sha256(open(os.path.join(R, p), 'rb').read()).hexdigest()
dig = lambda s: hashlib.sha256(s.encode('utf-8')).hexdigest()
AP = {'policy': '093a546b9bae54d8fab0026420c8d85dced85f0e0e6ed212d597b3fd1aa6eec5',
      'g2source': '7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947',
      'lp2source': '357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca',
      'parents': '0dcc572f42605fc39d005de2ebcbba243147128dee7621bb57a30f16ebdd76f6',
      'contract': '34fedbdaa7c4ca681ec47cf95dc51209411902759a87177174cbb09c3ca421dc'}
TOK = ('G2LP2A|policy=093a546b9bae54d8fab0026420c8d85dced85f0e0e6ed212d597b3fd1aa6eec5|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947'
       '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|parents=0dcc572f42605fc39d005de2ebcbba243147128dee7621bb57a30f16ebdd76f6'
       '|cases=H,stiff13,soft2,soft1|states=S5-S8|maxSolves=16')
g2 = os.path.join(R, 'matlab', 'g2'); v = 'vendor_p010_a14d8872'; lp2 = os.path.join(g2, 'lp2')
rel = sorted([n for n in os.listdir(g2) if n.endswith('.m')] + [v + '/' + n for n in os.listdir(os.path.join(g2, v)) if n.endswith('.m')])
got = {'policy': f('matlab/g2/lp2/G2_LP2A_POLICY_v1.json'),
       'g2source': dig('\n'.join(r + ' ' + f('matlab/g2/' + r) for r in rel)),
       'lp2source': dig('\n'.join(n + ' ' + f('matlab/g2/lp2/' + n) for n in sorted(n for n in os.listdir(lp2) if n.endswith('.m')))),
       'contract': f('docs/research/G2_LP2_evidence/qualification_v2/LP2A_CONTRACT.json')}
pol = json.load(open(os.path.join(lp2, 'G2_LP2A_POLICY_v1.json'), encoding='utf-8'))
ids = [c['id'] for c in pol['cases']]
got['parents'] = dig('\n'.join(i + ' ' + pol['parents'][i]['STATE'] for i in ids))
tok = (f"G2LP2A|policy={got['policy']}|g2source={got['g2source']}|lp2source={got['lp2source']}|parents={got['parents']}"
       f"|cases={','.join(ids)}|states=S5-S8|maxSolves=16")
par = {}
for i in ids:
    d = os.path.join(pol['parents']['run'], i, 'S4')
    par[i] = {k: f(os.path.join(d, k + '.mat')) == pol['parents'][i][k] for k in ('STATE', 'MESH', 'SOLUTION')}
man = json.load(open(os.path.join(R, pol['parents']['manifest']), encoding='utf-8'))
manOK = all(man[f'{i}/S4/{k}.mat'] == pol['parents'][i][k] for i in ids for k in ('STATE', 'MESH', 'SOLUTION'))
Q = json.load(open(os.path.join(R, 'docs/research/G2_LP2_evidence/qualification_v2/LP2A_QUALIFICATION.json'), encoding='utf-8'))
CT = json.load(open(os.path.join(R, 'docs/research/G2_LP2_evidence/qualification_v2/LP2A_CONTRACT.json'), encoding='utf-8'))
res = {'schema': 'NewMetacomp.G2.LP2A.ActivationHashCheck.v1',
       'pins': {k: {'approved': AP[k], 'recomputed': got[k], 'match': got[k] == AP[k]} for k in AP},
       'tokenRecomputed': tok, 'tokenMatchesApproved': tok == TOK, 'tokenInQualificationV2': Q['token'] == TOK, 'tokenInContractV2': CT['token'] == TOK,
       'contractV2': {'pass': CT['pass'], 'passed': CT['passed'], 'total': CT['total'], 'negativeTests': CT['negativeTests'], 'physicalSolves': CT['physicalSolves']},
       'parentPins': par, 'parentPinsMatchA0Manifest': manOK, 'goFilePresent': os.path.isfile(os.path.join(lp2, 'G2_LP2A_SCIENTIFIC_GO_v1.json')),
       'lp2aOutputFolders': [d for d in os.listdir(os.path.join(R, 'outputs')) if 'lp2a' in d]}
res['allPass'] = all(p['match'] for p in res['pins'].values()) and res['tokenMatchesApproved'] and res['tokenInQualificationV2'] and res['tokenInContractV2'] \
    and all(all(v.values()) for v in par.values()) and manOK and not res['goFilePresent'] and not res['lp2aOutputFolders'] and CT['pass'] and CT['passed'] == CT['total'] == 107
json.dump(res, open(out, 'w', encoding='utf-8'), indent=1)
print('pins', {k: p['match'] for k, p in res['pins'].items()}, 'token', res['tokenMatchesApproved'], res['tokenInQualificationV2'], res['tokenInContractV2'],
      'parents', all(all(v.values()) for v in par.values()), manOK, 'contract', CT['passed'], '/', CT['total'], 'GO', res['goFilePresent'], 'outputs', res['lp2aOutputFolders'], 'ALL', res['allPass'])
