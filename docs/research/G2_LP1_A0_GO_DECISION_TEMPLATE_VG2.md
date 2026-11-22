# G2-LP1-A0 — scientific authorization decision record, VG2 re-pin (TEMPLATE, NOT A GO)

[Issue #62](https://github.com/mfs9697/NewMetacomp/issues/62). This supersedes the A0-P0 template (PR #61) prospectively. The A0 tiers A–D, the S0–S4 caps and the historical arrays are unchanged.

**Only the investigator may complete this record and decide `GO_A0` or `HOLD_A0`.** No GO, resume record or signature has been created. The JSON below lives inside Markdown and contains placeholders that the validator rejects.

## 1. Pins for a future GO (verified by `scripts/g2/a0/a0_pin_check.py --profile vg2`, 21/21)

| Field | Value |
|---|---|
| `approvedPolicySHA256` | `074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091` |
| `approvedSourceSHA256` | **`9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5`** (VG2; `6f7fb3ea…` is historical only) |
| `approvedLP0SHA256` | `b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5` |
| `approvedToken` | `G2LP1\|policy=074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091\|source=9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5\|LP0=b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5\|cases=H,stiff13,soft2,soft1\|maxState=4` |
| `contractEvidenceFile` | `matlab/g2/evidence/lp1_preflight/vg2_20261122/E_batch_adbc8a6/CONTRACT_TESTS.json` |
| `contractEvidenceSHA256` | **`1332a4fb9b2a5a1f29f0c42024021b35b633f138b887d043fbcda599b5fc314f`** (138/138, LF, equal to the batch manifest) |
| `approvedRunName` | `run_a0_lp1_repro_v1` |
| `campaignId` | investigator's choice, e.g. `G2-LP1-A0-001` (`[A-Za-z0-9_-]{3,64}`) |
| `campaignScope` | `A0_LP1_S0_S4_REPRODUCTION` |

## 2. Decision record (investigator completes; Markdown block only)

```json
{
  "decision": "<INVESTIGATOR ONLY: GO_LP1_PHYSICAL, or do not create the file (HOLD_A0)>",
  "reviewStatus": "<INVESTIGATOR ONLY: REVIEWED_ACCEPTED>",
  "scientificReviewer": "<INVESTIGATOR ONLY>",
  "reviewURL": "<INVESTIGATOR ONLY: signed GitHub comment recording GO_A0>",
  "approvedPolicySHA256": "074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091",
  "approvedSourceSHA256": "9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5",
  "approvedLP0SHA256": "b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5",
  "approvedToken": "G2LP1|policy=074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091|source=9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5|LP0=b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5|cases=H,stiff13,soft2,soft1|maxState=4",
  "contractEvidenceFile": "matlab/g2/evidence/lp1_preflight/vg2_20261122/E_batch_adbc8a6/CONTRACT_TESTS.json",
  "contractEvidenceSHA256": "1332a4fb9b2a5a1f29f0c42024021b35b633f138b887d043fbcda599b5fc314f",
  "approvedRunName": "run_a0_lp1_repro_v1",
  "campaignId": "<INVESTIGATOR ONLY: e.g. G2-LP1-A0-001>",
  "campaignScope": "A0_LP1_S0_S4_REPRODUCTION"
}
```

## 3. What is code-enforced now

| Narrowing | Enforcement |
|---|---|
| Cases H/stiff13/soft2/soft1; S0–S4; 4-mm steps; no S5 | token, policy v2, controller and forecast asserts (unchanged) |
| No A1, LP2 or new physics | a different policy or source changes the token, so this GO fails `HOLD_SOURCE` |
| One named run | `approvedRunName` checked at every call → `HOLD_CAMPAIGN_SCOPE` |
| One campaign per GO in this checkout | receipt binds campaign, run, GO SHA and token; the run folder cannot be adopted without a receipt; deleted runs are detected; `CLOSED` → `VERIFY_ONLY` |
| No unreviewed resumption | review-bound resume record, ≤ 1 per campaign |
| **Not enforced: global single use across clones or after deleting ledger + run** | **residual; procedural: remove or revoke the GO right after verified closure** |

## 4. Reviewed resumption record (only after a pre-admission memory HOLD; investigator only; Markdown block only)

```json
{
  "decision": "<INVESTIGATOR ONLY: RESUME_AFTER_PREADMISSION_MEMORY_HOLD>",
  "campaignId": "<same campaignId as the GO>",
  "holdRecordSHA256": "<SHA-256 of outputs/g2_lp1_campaign_ledger/<campaignId>/HOLD_PREADMISSION_MEMORY_*.mat>",
  "scientificReviewer": "<INVESTIGATOR ONLY>",
  "reviewURL": "<INVESTIGATOR ONLY: GitHub comment reviewing the HOLD>"
}
```

Path (hard-coded): `matlab/g2/G2_LP1_CAMPAIGN_RESUME_v1.json`. It must be committed, because the preflight requires a clean tree. It can be consumed once.

## 5. Suggested signed GitHub wording

> **Decision: GO_A0 / HOLD_A0.** I authorize campaign `<campaignId>`, run `run_a0_lp1_repro_v1`: one bounded A0 reproduction of LP1 S0–S4 (H, stiff13, soft2, soft1; s ≤ 41.4 mm) under the A0-P0 preregistration (PR #61) and VG2 (PR <link>). The pins are source set `9b634df2…`, policy `074d7edc…`, LP0 `b4240d7e…` and contract evidence `1332a4fb…`. This does not authorize A1, S5, LP2 or any new physics. The GO will be removed after verified campaign closure.

## 6. Prerequisites before any A0 execution (not satisfied by VG2 itself)

1. **`HOLD_ARCHIVE_BACKUP`.** The raw archive (`5b333b03…`) currently exists only on drive C:, as the original plus a read-only copy. An independently verifiable off-device or cloud copy is required. The investigator should report its SHA-256 check.
2. A fresh `core.autocrlf=false` clone at the GO commit; `a0_pin_check.py --profile vg2` passing (G1 is expected to fail once the genuine GO exists).
3. ≈ 7 GiB free RAM before launch. The historical campaign used 62.7 MB of outputs; C: had 4.13 GB free at VG2.
