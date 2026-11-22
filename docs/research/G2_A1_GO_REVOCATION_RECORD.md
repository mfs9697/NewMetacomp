# G2-LP1-A1 — revoked scientific GO: provenance record (non-executable)

[Issue #66](https://github.com/mfs9697/NewMetacomp/issues/66). The live GO `matlab/g2/G2_A1_SCIENTIFIC_GO_v1.json` is **removed** in the revocation commit that follows this record on branch `research/g2-lp1-a1-family-b-transfer-20261122`, which restores the A1 physical-execution HOLD. This Markdown file is **not** a GO: `g2_a1_scientific_gate` reads only the hard-coded JSON path, and that file no longer exists.

| Item | Value |
|---|---|
| Investigator authorization | https://github.com/mfs9697/NewMetacomp/issues/66#issuecomment-7085445180 (author `mfs9697`, 2026-11-22T20:39:31Z) |
| Reviewed head | `d2121874e70d1eed129cf0a6b3aca7cb44fecc51` |
| GO commit | `ffe5ba9b5136c6fd99d78635f0db3257c3745597` |
| GO file SHA-256 (exact bytes, LF, 2143 bytes) | `b8693fdfdcdab6c378ef0299103a1add66c4ace10015c21a55eaa9897aee1531` |
| Pins bound (independently recomputed from Git blobs before the GO commit) | policy `312e1e00…`, source `7e568370…` (140 files), mesh manifest `ffee15fd…`, contract `06ef678e…` |
| Campaign | `G2-A1-FB-001`, run `run_a1_family_b_s4_v1`, scope `A1_S4_FAMILY_B_FIXED_PATH_MAX12` |
| Use | 12 preregistered calls (12 solves, 2026-11-22T20:42:56Z–20:44:24Z), then 12 VERIFY_ONLY calls (0 solves), all in one fixed clean execution checkout at `ffe5ba9`; campaign CLOSED |
| Ledger | RECEIPT `e7efc0e0…`, 12 ADMIT, CLOSED `41cf5345…`; full manifest in `matlab/g2/evidence/a1_campaign_20261122/campaign/A1_CAMPAIGN_LEDGER_SHA256.json` |
| Composed by | Claude Code at the investigator's explicit instruction; not an independent signature |

Git history keeps the exact GO bytes at the GO commit (`git show ffe5ba9:matlab/g2/G2_A1_SCIENTIFIC_GO_v1.json`). They are reproduced below for the record only:

```text
{
  "decision": "GO_A1_PHYSICAL",
  "reviewStatus": "REVIEWED_ACCEPTED",
  "scientificReviewer": "Principal investigator mfs9697 (repository owner): GO_A1 given in conversation on 2026-11-22 and recorded by the investigator in Issue #66 comment 7085445180",
  "reviewURL": "https://github.com/mfs9697/NewMetacomp/issues/66#issuecomment-7085445180",
  "approvedA1PolicySHA256": "312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013",
  "approvedSourceSHA256": "7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947",
  "approvedMeshManifestSHA256": "ffee15fd508b5b13e78850cefd88e7d0b04308f70c468c0c1e85f7f78a0ecbc5",
  "approvedToken": "G2A1|policy=312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013|source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947|meshes=ffee15fd508b5b13e78850cefd88e7d0b04308f70c468c0c1e85f7f78a0ecbc5|cases=H,stiff13,soft2,soft1|levels=3,6,9|maxSolves=12",
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
    "excluded": [
      "new crack trajectories",
      "S5",
      "LP2",
      "Family A",
      "interface propagation",
      "CZM",
      "optimization",
      "physical arrest",
      "convergence-order claims",
      "soft2 reclassification"
    ],
    "revocation": "remove this file in a separate commit after verified campaign closure"
  }
}
```
