"""Write matlab/g2/lp2a3/G2_LP2A3_GO.json from the regenerated template (fields, order, token, evidence) and the
investigator authorization (decision, URL, approved head). usage: python -I make_go.py <repo> <outGO.json>"""
import json, re, sys, os, hashlib
R, out = sys.argv[1], sys.argv[2]
t = open(os.path.join(R, 'docs/research/G2_LP2A3_GO_DECISION_TEMPLATE.md'), encoding='utf-8').read()
G = json.loads(re.search(r'```json\n(.*?)\n```', t, re.S).group(1))
G['decision'] = 'GO_LP2A3_PHYSICAL'
G['decisionUrl'] = 'https://github.com/mfs9697/NewMetacomp/pull/75#issuecomment-7175877170'
G['approvedHead'] = '2348ba11b9ebe1e33a723b11055a3603b846383e'
auth = ('G2LP2A3|policy=7a6e17f8baa85c6e6f10186bfab3a9c10c9363e0acb5e532c00095961bf45d43|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947'
        '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd'
        '|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|parentsS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d'
        '|qualification=a77f49200f9f95b36260f44306afd4b05690d8ec9353c4fa71f4b5adbe5d4ded|cases=H,stiff13,soft2,soft1|states=S9-S11|maxAdmissions=12|seed=0.45'
        '|campaign=G2-LP2A3-001|run=run_lp2a3_s9_s11_v1')
assert G['token'] == auth, 'template token differs from the authorization'
assert G['contractEvidenceSHA256'] == '2aa6a9046c9611786963f1abb3d9567aeab2b7f71f4ea80ec1d01e08b29c6a0c'
assert hashlib.sha256(open(os.path.join(R, G['contractEvidenceFile']), 'rb').read()).hexdigest() == G['contractEvidenceSHA256']
assert G['campaignId'] == 'G2-LP2A3-001' and G['runName'] == 'run_lp2a3_s9_s11_v1' and G['cases'] == ['H', 'stiff13', 'soft2', 'soft1']
assert G['maxStateIndex'] == 11 and G['maxAdmissions'] == 12 and G['seedSpacing_mm'] == 0.45
open(out, 'w', encoding='utf-8', newline='\n').write(json.dumps(G, indent=1, ensure_ascii=False) + '\n')
print('written', hashlib.sha256(open(out, 'rb').read()).hexdigest())
