import json, hashlib, sys
out = sys.argv[1]
tok = ('G2A1|policy=312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013'
       '|source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947'
       '|meshes=ffee15fd508b5b13e78850cefd88e7d0b04308f70c468c0c1e85f7f78a0ecbc5'
       '|cases=H,stiff13,soft2,soft1|levels=3,6,9|maxSolves=12')
go = {
    "decision": "GO_A1_PHYSICAL",
    "reviewStatus": "REVIEWED_ACCEPTED",
    "scientificReviewer": "Principal investigator mfs9697 (repository owner): GO_A1 given in conversation on 2026-11-22 and recorded by the investigator in Issue #66 comment 7085445180",
    "reviewURL": "https://github.com/mfs9697/NewMetacomp/issues/66#issuecomment-7085445180",
    "approvedA1PolicySHA256": "312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013",
    "approvedSourceSHA256": "7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947",
    "approvedMeshManifestSHA256": "ffee15fd508b5b13e78850cefd88e7d0b04308f70c468c0c1e85f7f78a0ecbc5",
    "approvedToken": tok,
    "contractEvidenceFile": "matlab/g2/evidence/a1_preflight/batch_6a3a14d/CONTRACT_TESTS.json",
    "contractEvidenceSHA256": "06ef678ed387d1c3ecfbb105a8a8609aa0248f16d68c8067faed69877f82f3de",
    "approvedRunName": "run_a1_family_b_s4_v1",
    "campaignId": "G2-A1-FB-001",
    "campaignScope": "A1_S4_FAMILY_B_FIXED_PATH_MAX12",
    "provenance_not_machine_enforced": {
        "assignment": "https://github.com/mfs9697/NewMetacomp/issues/66",
        "basedOnReviewedHead": "d2121874e70d1eed129cf0a6b3aca7cb44fecc51",
        "composedBy": "Claude Code at the investigator's explicit instruction (Issue #66 comment 7085445180); this file is not an independent signature",
        "template": "docs/research/G2_A1_GO_DECISION_TEMPLATE.md",
        "scope": "12 fixed-S4 Family B solves: H, stiff13, soft2, soft1 x m = 3, 6, 9; m = 0 is the archived A0 S4 baseline (not recomputed)",
        "excluded": ["new crack trajectories", "S5", "LP2", "Family A", "interface propagation", "CZM",
                     "optimization", "physical arrest", "convergence-order claims", "soft2 reclassification"],
        "revocation": "remove this file in a separate commit after verified campaign closure"
    }
}
data = (json.dumps(go, indent=2, ensure_ascii=False) + '\n').encode('utf-8')
open(out, 'wb').write(data)
print(hashlib.sha256(data).hexdigest())
