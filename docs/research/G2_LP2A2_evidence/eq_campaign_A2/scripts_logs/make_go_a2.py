"""Write the A2 GO file from the investigator authorization (PR #71 comment 7171931196); every value
is checked against the regenerated A2 v3 GO template and the committed contract evidence.
usage: python -I make_go_a2.py <outGO.json> <repo>"""
import json, sys, os, re, hashlib
out, R = sys.argv[1], sys.argv[2]
go = {
    "decision": "GO_LP2A2_EQ",
    "decisionUrl": "https://github.com/mfs9697/NewMetacomp/pull/71#issuecomment-7171931196",
    "approvedHead": "a4561f88dfeda31752ae6c268d2d4d74e16b60a7",
    "token": "G2LP2A2EQ|policy=6f2c290b37d4f8291f428ec8b9e0a886fe6b31fc901bee5781f2518e67c94756|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd|archivedS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1|limit=4",
    "solveLimit": 4,
    "solves": ["EQ-H", "EQ-stiff13", "EQ-soft2", "EQ-soft1"],
    "campaignId": "G2-LP2A2-EQ-001",
    "contractEvidenceFile": "docs/research/G2_LP2A2_evidence/eq/v3/LP2A2_EQ_TESTS_v3.json",
    "contractEvidenceSHA256": "75057751f4d58733d988dc8480440ae4a5ad6f3dff9c9d8819119919c1d2482f",
}
t = open(os.path.join(R, 'docs/research/G2_LP2A2_EQ_GO_DECISION_TEMPLATE.md'), encoding='utf-8').read()
tj = json.loads(re.search(r'```json\n(.*?)\n```', t, re.S).group(1))
for k in ('token', 'solveLimit', 'solves', 'campaignId', 'contractEvidenceFile', 'contractEvidenceSHA256'):
    assert go[k] == tj[k], k + ' differs from the template'
ev = os.path.join(R, go['contractEvidenceFile'])
assert hashlib.sha256(open(ev, 'rb').read()).hexdigest() == go['contractEvidenceSHA256'], 'evidence SHA'
assert list(go) == list(tj), 'field order differs from the template'
with open(out, 'w', encoding='utf-8', newline='\n') as f:
    f.write(json.dumps(go, indent=1, ensure_ascii=False) + '\n')
print('written', out, hashlib.sha256(open(out, 'rb').read()).hexdigest())
