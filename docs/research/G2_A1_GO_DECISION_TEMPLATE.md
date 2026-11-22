# G2-LP1-A1 — scientific authorization decision record (TEMPLATE, NOT A GO)

[Issue #66](https://github.com/mfs9697/NewMetacomp/issues/66). Separate from the A0 authorization: the A0 GO (`0f7de607…`, PR #65) was revoked after verified closure and **cannot** satisfy the A1 validator. `g2_a1_go_validate` rejects the A0 run names `run_20261122_lp1_v1` and `run_a0_lp1_repro_v1` and the campaign ID `G2-LP1-A0-001`. Any policy, source or mesh change alters the A1 token, and the validator then returns `G2A1:HOLD_SOURCE`.

**Only the investigator may complete this record and decide `GO_A1` or `HOLD_A1`.** No GO file exists. The JSON below sits inside Markdown and contains placeholders that the validator rejects.

## 1. Pins for a future GO

All values come from the A1 no-FEM batch at source commit `6a3a14d`: `matlab/g2/evidence/a1_preflight/batch_6a3a14d/PREPHYSICAL_RESULT.json`. Result: 16 geometry rows, 12 mesh content SHAs equal to the policy, 12 dry calls, contract 46/46, correct-token refusal with no writes, zero solves.

| Field | Value |
|---|---|
| `approvedA1PolicySHA256` | `312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013` (`matlab/g2/G2_A1_POLICY_v1.json`) |
| `approvedSourceSHA256` | `7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947` (all top-level `matlab/g2/*.m` + `vendor_p010_a14d8872/*.m`) |
| `approvedMeshManifestSHA256` | `ffee15fd508b5b13e78850cefd88e7d0b04308f70c468c0c1e85f7f78a0ecbc5` (12 preregistered B3/B6/B9 meshes) |
| `approvedToken` | `G2A1\|policy=312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013\|source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947\|meshes=ffee15fd508b5b13e78850cefd88e7d0b04308f70c468c0c1e85f7f78a0ecbc5\|cases=H,stiff13,soft2,soft1\|levels=3,6,9\|maxSolves=12` |
| `contractEvidenceFile` | `matlab/g2/evidence/a1_preflight/batch_6a3a14d/CONTRACT_TESTS.json` |
| `contractEvidenceSHA256` | `06ef678ed387d1c3ecfbb105a8a8609aa0248f16d68c8067faed69877f82f3de` (46/46, `physicalSolves` 0) |
| `approvedRunName` | proposed `run_a1_family_b_s4_v1` |
| `campaignId` | proposed `G2-A1-FB-001` (`[A-Za-z0-9_-]{3,64}`, not `G2-LP1-A0-001`) |
| `campaignScope` | `A1_S4_FAMILY_B_FIXED_PATH_MAX12` |
| GO file path (hard-coded) | `matlab/g2/G2_A1_SCIENTIFIC_GO_v1.json` |

The source digest covers every top-level `.m` in `matlab/g2`. Adding, removing or editing any of them after `6a3a14d` invalidates these pins. Report-only code therefore lives in `scripts/report/`.

## 2. Decision record (investigator completes; Markdown block only)

```json
{
  "decision": "<INVESTIGATOR ONLY: GO_A1_PHYSICAL, or do not create the file (HOLD_A1)>",
  "reviewStatus": "<INVESTIGATOR ONLY: REVIEWED_ACCEPTED>",
  "scientificReviewer": "<INVESTIGATOR ONLY>",
  "reviewURL": "<INVESTIGATOR ONLY: https://github.com/mfs9697/NewMetacomp/... comment recording GO_A1>",
  "approvedA1PolicySHA256": "312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013",
  "approvedSourceSHA256": "7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947",
  "approvedMeshManifestSHA256": "ffee15fd508b5b13e78850cefd88e7d0b04308f70c468c0c1e85f7f78a0ecbc5",
  "approvedToken": "G2A1|policy=312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013|source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947|meshes=ffee15fd508b5b13e78850cefd88e7d0b04308f70c468c0c1e85f7f78a0ecbc5|cases=H,stiff13,soft2,soft1|levels=3,6,9|maxSolves=12",
  "contractEvidenceFile": "matlab/g2/evidence/a1_preflight/batch_6a3a14d/CONTRACT_TESTS.json",
  "contractEvidenceSHA256": "06ef678ed387d1c3ecfbb105a8a8609aa0248f16d68c8067faed69877f82f3de",
  "approvedRunName": "<INVESTIGATOR ONLY: e.g. run_a1_family_b_s4_v1>",
  "campaignId": "<INVESTIGATOR ONLY: e.g. G2-A1-FB-001>",
  "campaignScope": "A1_S4_FAMILY_B_FIXED_PATH_MAX12"
}
```

## 3. What a GO_A1 would authorize, and what it would not

| Authorized | Not authorized |
|---|---|
| ≤ 12 fixed-geometry FEM solves: H, stiff13, soft2, soft1 × m = 3, 6, 9 on the 12 preregistered meshes (content SHA checked at every call) | S5, any propagation step, new trajectories, LP2 |
| Cornell plane-stress BVP of LP1 policy v2, unchanged `g2_m4b_sif_partial` (blind COD → signed 5-annulus EDI + 4×4) | the Edge BVP, any Edge numerical value |
| m = 0 = archived A0 S4 solution (no new solve) | refinement beyond m = 9, Family A, other cases |
| one named run, one campaign ledger (`outputs/g2_a1_campaign_ledger/<campaignId>`) | reuse of the A0 GO, run, ledger or receipt |
| report of signed ΔK_I, ΔK_II, ΔG, Δθ and F_G = G_case/G_H − 1 per level | reclassifying soft2, Richardson extrapolation, convergence-order or exact-SIF claims, interface propagation, CZM, optimization, physical arrest |

**Code-enforced:** decision/review proof, scope, run name, campaign ID, policy, source, mesh manifest, token and contract bytes (`g2_a1_go_validate`). The 12-solve ceiling is enforced by the admit hook. Each mesh's preregistered content SHA and mesh validator are re-checked. Memory guard: ≥ 5 GiB free, one MATLAB process. Any HOLD stops the campaign, with no automatic retry and no A1 resume mechanism.

**Not code-enforced (procedural):** single use across clones, or after deleting the ledger and run folder. As in A0, the GO should be removed or revoked by a separate commit right after verified closure.

## 4. Commands after a GO (for the record; do not run without the GO file committed)

```matlab
% clean LF execution clone at the GO commit, core.autocrlf=false; one MATLAB process
cd <repo>; addpath(fullfile(pwd,'matlab','g2'),'-begin');
C = g2_a1_context();                       % prints the token; must equal approvedToken
for c = ["H","stiff13","soft2","soft1"]
  for m = [3 6 9]
    R = g2_a1_run('Case',char(c),'Level',m,'Run',true, ...
                  'AuthToken',C.token,'RunName','<approvedRunName>');
  end
end
```
