import json, sys
out = sys.argv[1]
go = {
    "decision": "GO_LP2A2_EQ",
    "decisionUrl": "https://github.com/mfs9697/NewMetacomp/pull/71#issuecomment-7167996437",
    "approvedHead": "4d3701e1ccc91b7512db9052c927f32af52e2479",
    "token": "G2LP2A2EQ|policy=bc1f86e7750aaea653cd7544c8fff0ad757843a23bd00608145dad70dcd8a330|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=00c99e93915ad2c0dbd4eaeb307d94d65b4c71300f94a0f073aadacb9c5a61c2|archivedS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1|limit=4",
    "solveLimit": 4,
    "solves": ["EQ-H", "EQ-stiff13", "EQ-soft2", "EQ-soft1"],
    "campaignId": "G2-LP2A2-EQ-001",
    "contractEvidenceFile": "docs/research/G2_LP2A2_evidence/eq/v2/LP2A2_EQ_TESTS_v2.json",
    "contractEvidenceSHA256": "84f518a6e63ad07babdba632db34c4720d338e756f09c853c31f116a9168180b",
}
tok = open(sys.argv[2], encoding='utf-8').read()
import re
assert go["token"] == re.search(r'"token": "([^"]+)"', tok).group(1), "token differs from the template"
with open(out, 'w', encoding='utf-8', newline='\n') as f:
    f.write(json.dumps(go, indent=1, ensure_ascii=False) + '\n')
print('written', out)
