"""Write matlab/g2/lp2b1eq/G2_LP2B1EQ_GO.json from the reviewed template fields (order, token, evidence) and the
investigator authorization (decision, actual comment URL, approved head). Asserts the result equals, field by field,
the exact activation record of the authorization comment except the decisionUrl placeholder.
usage: python -I make_go.py <repo> <authRecord.json> <outGO.json>"""
import json, re, sys, os, hashlib
R, authf, out = sys.argv[1], sys.argv[2], sys.argv[3]
URL = 'https://github.com/mfs9697/NewMetacomp/pull/79#issuecomment-7211904299'
HEAD = '7d0df53f35b30c4e33734c40fdda33e987ea96ee'
t = open(os.path.join(R, 'docs/research/G2_LP2B1EQ_GO_DECISION_TEMPLATE.md'), encoding='utf-8').read()
G = json.loads(re.search(r'```json\n(.*?)\n```', t, re.S).group(1))
A = json.load(open(authf, encoding='utf-8'))
assert A['decisionUrl'] == 'REPLACE_WITH_THIS_ACTUAL_INVESTIGATOR_COMMENT_URL'
G['decision'] = 'GO_LP2B1_EQ'
G['decisionUrl'] = URL
G['approvedHead'] = HEAD
A['decisionUrl'] = URL
assert list(G.keys()) == list(A.keys()), (list(G.keys()), list(A.keys()))
assert G == A, [k for k in G if G[k] != A[k]]
assert hashlib.sha256(open(os.path.join(R, G['contractEvidenceFile']), 'rb').read()).hexdigest() == G['contractEvidenceSHA256'] \
    == '35d891197fdcf7514f8486ace41ff56c406ebfa4370eb1733db99b81e5b4b77a'
assert G['solves'] == ['EQB-soft1-S9', 'EQB-H-S10'] and G['solveLimit'] == 2 and G['attemptsPerSolve'] == 1 and G['seedSpacing_mm'] == 0.4
open(out, 'w', encoding='utf-8', newline='\n').write(json.dumps(G, indent=1, ensure_ascii=False) + '\n')
print('written', hashlib.sha256(open(out, 'rb').read()).hexdigest())
