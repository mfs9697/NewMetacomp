"""Write matlab/g2/lp2b1s10/G2_LP2B1S10_GO.json from the reviewed template (field order, token, evidence) and the investigator
authorization (decision, actual comment URL, approved head). Asserts the result equals, field by field and in order, the exact
activation record of the authorization comment except the decisionUrl placeholder, which is replaced by the comment URL.
usage: python -I make_go.py <repo> <authRecord.json> <outGO.json>"""
import json, re, sys, os, hashlib
R, authf, out = sys.argv[1], sys.argv[2], sys.argv[3]
URL = 'https://github.com/mfs9697/NewMetacomp/pull/82#issuecomment-7237508619'
HEAD = '0fcee176a5e294b7c8d7f33711ad7d3897be6538'
t = open(os.path.join(R, 'docs/research/G2_LP2B1S10_GO_DECISION_TEMPLATE.md'), encoding='utf-8').read()
G = json.loads(re.search(r'```json\n(.*?)\n```', t, re.S).group(1))
A = json.load(open(authf, encoding='utf-8'))
assert A['decisionUrl'] == 'REPLACE_WITH_THIS_ACTUAL_INVESTIGATOR_COMMENT_URL'
G['decision'] = 'GO_LP2B1_S10'; G['decisionUrl'] = URL; G['approvedHead'] = HEAD
A['decisionUrl'] = URL
assert list(G.keys()) == list(A.keys()), (list(G.keys()), list(A.keys()))
assert G == A, [k for k in G if G[k] != A[k]]
assert hashlib.sha256(open(os.path.join(R, G['contractEvidenceFile']), 'rb').read()).hexdigest() == G['contractEvidenceSHA256'] \
    == '9d97017e78d0fdc58d1d75b45dcd8e8e58ed48c0e2874b9d6877cac32381cf64'
assert G['target'] == 'soft1-S10' and G['admissions'] == 1 and G['physicalSolves'] == 1 and G['attemptsPerSolve'] == 1 and G['seedSpacing_mm'] == 0.4
assert G['campaignId'] == 'G2-LP2B1-S10-001' and G['runName'] == 'run_lp2b1_s10_v1' and G['campaignScope'] == 'LP2B1_S10_SOFT1_SINGLE_STATE_0p40'
assert not os.path.exists(out), out
open(out, 'w', encoding='utf-8', newline='\n').write(json.dumps(G, indent=1, ensure_ascii=False) + '\n')
print('written', hashlib.sha256(open(out, 'rb').read()).hexdigest())
