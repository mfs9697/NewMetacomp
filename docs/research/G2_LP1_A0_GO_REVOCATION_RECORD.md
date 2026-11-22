# G2-LP1-A0 — revoked scientific GO: provenance record (non-executable)

[Issue #64](https://github.com/mfs9697/NewMetacomp/issues/64). The live GO `matlab/g2/G2_LP1_SCIENTIFIC_GO_v1.json` was **removed** in the revocation commit that follows this record on branch `research/g2-lp1-a0-campaign-20261122`. The physical-execution HOLD is therefore restored. This Markdown file is **not** a GO: the gate reads only the hard-coded JSON path, which no longer exists.

| Item | Value |
|---|---|
| Investigator authorization | https://github.com/mfs9697/NewMetacomp/issues/64#issuecomment-7083959515 (author `mfs9697`, 2026-11-22T18:54:28Z) |
| GO commit | `135a5f6d410cf425cb659f3dcb2305985e3897f4` (child of PR #63 head `7f843ac`) |
| GO file SHA-256 (exact bytes, LF, 1804 bytes) | `0f7de6073def97403047666d5e3b5cc8f52b548d155440e1289e7a6771b6dcde` |
| Campaign | `G2-LP1-A0-001`, run `run_a0_lp1_repro_v1`, scope `A0_LP1_S0_S4_REPRODUCTION` |
| Pins bound | source set `9b634df2…`, policy `074d7edc…`, LP0 `b4240d7e…`, contract `1332a4fb…` |
| Use | eight preregistered calls (20 solves) and four VERIFY_ONLY calls (0 solves), all in one fixed execution checkout; campaign CLOSED |
| Composed by | Claude Code at the investigator's explicit instruction; not an independent signature |

The exact GO bytes are kept in Git history at the GO commit (`git show 135a5f6:matlab/g2/G2_LP1_SCIENTIFIC_GO_v1.json`). They are reproduced here for the record only:

```text
{
  "decision": "GO_LP1_PHYSICAL",
  "reviewStatus": "REVIEWED_ACCEPTED",
  "scientificReviewer": "Investigator mfs9697 (repository owner): GO_A0 given in conversation on 2026-11-22 and recorded by the investigator in Issue #64 comment 7083959515",
  "reviewURL": "https://github.com/mfs9697/NewMetacomp/issues/64#issuecomment-7083959515",
  "approvedPolicySHA256": "074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091",
  "approvedSourceSHA256": "9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5",
  "approvedLP0SHA256": "b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5",
  "approvedToken": "G2LP1|policy=074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091|source=9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5|LP0=b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5|cases=H,stiff13,soft2,soft1|maxState=4",
  "contractEvidenceFile": "matlab/g2/evidence/lp1_preflight/vg2_20261122/E_batch_adbc8a6/CONTRACT_TESTS.json",
  "contractEvidenceSHA256": "1332a4fb9b2a5a1f29f0c42024021b35b633f138b887d043fbcda599b5fc314f",
  "approvedRunName": "run_a0_lp1_repro_v1",
  "campaignId": "G2-LP1-A0-001",
  "campaignScope": "A0_LP1_S0_S4_REPRODUCTION",
  "provenance_not_machine_enforced": {
    "assignment": "https://github.com/mfs9697/NewMetacomp/issues/64",
    "composedBy": "Claude Code at the investigator's explicit instruction (Issue #64 and comment 7083959515); this file is not an independent signature",
    "template": "docs/research/G2_LP1_A0_GO_DECISION_TEMPLATE_VG2.md",
    "excluded": [
      "A1 mesh refinement",
      "S5",
      "LP2",
      "interface propagation",
      "CZM",
      "optimization"
    ],
    "revocation": "remove this file in a separate commit after verified campaign closure"
  }
}
```
