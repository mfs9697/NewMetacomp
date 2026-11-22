# G2-LP1-A0 — scientific authorization decision record (TEMPLATE, NOT A GO)

[Issue #60](https://github.com/mfs9697/NewMetacomp/issues/60). **Only the investigator may complete this record and decide `GO_A0` or `HOLD_A0`.**

Claude has not created, filled or committed any GO. Nothing in this document is a runtime file. The JSON below sits in a Markdown code block and deliberately contains placeholder values that the production validator rejects.

## 1. What the production gate checks (`g2_lp1_scientific_gate` → `g2_lp1_go_validate`, source set `6f7fb3ea…`)

- **File location:** the gate reads exactly `matlab/g2/G2_LP1_SCIENTIFIC_GO_v1.json` (hard-coded; no caller-supplied path). The GO must be **committed**, because the preflight requires a clean tree. It is not part of the source-set digest, which covers only `.m` files, so committing it does not change the token.
- **Checks, in order:**

| Field | Required value | Failure identifier |
|---|---|---|
| all 10 fields present | — | `HOLD_UNAUTHORIZED_STATE` |
| `decision` | `GO_LP1_PHYSICAL` | `HOLD_UNAUTHORIZED_STATE` |
| `reviewStatus` | `REVIEWED_ACCEPTED` | `HOLD_UNAUTHORIZED_STATE` |
| `scientificReviewer` | non-empty | `HOLD_UNAUTHORIZED_STATE` |
| `reviewURL` | starts with `https://github.com/mfs9697/NewMetacomp/` | `HOLD_UNAUTHORIZED_STATE` |
| `approvedPolicySHA256` | `074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091` | `HOLD_SOURCE` |
| `approvedSourceSHA256` | `6f7fb3ea51a0ae64e30a5c63f8cc765af5308c511da315c989ae10235fbed030` | `HOLD_SOURCE` |
| `approvedLP0SHA256` | `b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5` | `HOLD_SOURCE` |
| `approvedToken` | exactly the full token in §2 | `HOLD_SOURCE` |
| `contractEvidenceFile` | `matlab/g2/evidence/lp1_preflight/vg1_20261122/E_corrected_batch_f65d252/CONTRACT_TESTS.json` | `HOLD_SOURCE` (path) |
| `contractEvidenceSHA256` | `78b6897f52639e06fafb5aeee03007ac961a9cbb2304762b9096a969cff715be` | `HOLD_SOURCE` (bytes) |
| contract content | pass, 74/74, ≥ 20, 0 solves, 0 meshes, negative and integrity flags true | `HOLD_UNAUTHORIZED_STATE` |

## 2. Exact pins (verified by `scripts/g2/a0/a0_pin_check.py`, 21/21)

```
token = G2LP1|policy=074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091|source=6f7fb3ea51a0ae64e30a5c63f8cc765af5308c511da315c989ae10235fbed030|LP0=b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5|cases=H,stiff13,soft2,soft1|maxState=4
```

## 3. Gate-semantics assessment for a *narrow* A0 approval

| Required narrowing | Enforced by code? | Assessment |
|---|---|---|
| Only the four cases H, stiff13, soft2, soft1 | **Yes**: token `cases=…`, policy v2 case list, controller case parser | supported |
| Only S0–S4, s ≤ 41.4 mm, 4-mm steps, no S5 | **Yes**: token `maxState=4`, policy caps, controller and forecast asserts | supported |
| No mesh refinement (A1), LP2, new physics | **Yes, indirectly**: any such change needs a new policy and/or source, hence a different token, so this GO fails `HOLD_SOURCE` | supported |
| H S0–S2 first; all S2 before any S3 | **Yes**: controller staging asserts | supported |
| Exactly the run name `run_a0_lp1_repro_v1` | **No**: the GO does not bind the run name | **procedural only** |
| A single A0 attempt (no unlimited reruns under the same GO) | **No**: a valid GO stays valid until removed | **procedural only** |
| Decision label "A0" | The literal must be `GO_LP1_PHYSICAL` | acceptable: A0 *is* a bounded LP1 physical run |

**Conclusion.** The physics scope (cases, S0–S4, no A1/LP2/new physics) is code-enforced. Run-name and single-use restrictions are **not** code-enforced. This is not judged a blocker for the bounded A0 scope, but it is a genuine limitation.

The investigator should choose one of:
- **(a)** accept procedural control. The signed GitHub decision states the run name and one attempt, and the GO file is **deleted in a follow-up commit** immediately after the A0 run, which restores the HOLD.
- **(b)** require a gate revision (a VG2 that binds `runName` and single use) before A0. That changes the source set and needs a new no-FEM qualification.

The gate has not been weakened or modified here.

## 4. Decision record (investigator completes; Markdown block only)

```json
{
  "decision": "<INVESTIGATOR ONLY: GO_LP1_PHYSICAL to authorize A0, or do not create this file (HOLD_A0)>",
  "reviewStatus": "<INVESTIGATOR ONLY: REVIEWED_ACCEPTED>",
  "scientificReviewer": "<INVESTIGATOR ONLY: name / GitHub handle>",
  "reviewURL": "<INVESTIGATOR ONLY: URL of the signed GitHub comment recording GO_A0>",
  "approvedPolicySHA256": "074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091",
  "approvedSourceSHA256": "6f7fb3ea51a0ae64e30a5c63f8cc765af5308c511da315c989ae10235fbed030",
  "approvedLP0SHA256": "b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5",
  "approvedToken": "G2LP1|policy=074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091|source=6f7fb3ea51a0ae64e30a5c63f8cc765af5308c511da315c989ae10235fbed030|LP0=b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5|cases=H,stiff13,soft2,soft1|maxState=4",
  "contractEvidenceFile": "matlab/g2/evidence/lp1_preflight/vg1_20261122/E_corrected_batch_f65d252/CONTRACT_TESTS.json",
  "contractEvidenceSHA256": "78b6897f52639e06fafb5aeee03007ac961a9cbb2304762b9096a969cff715be",
  "scope_not_machine_enforced": {
    "experiment": "A0 prospective reproduction of LP1 S0-S4 (Issue #60 preregistration)",
    "runName": "run_a0_lp1_repro_v1",
    "maxFullAttempts": 1,
    "maxResumptionsAfterPreadmissionMemoryHold": 1,
    "excluded": ["A1 mesh refinement", "S5", "LP2", "interface crossing", "CZM", "optimization"],
    "goFileRemovalAfterRun": true
  }
}
```

Extra fields are ignored by the validator and serve as documentation only.

## 5. Signed GitHub decision (suggested wording for the investigator)

> **Decision: GO_A0 / HOLD_A0.** I authorize exactly one bounded A0 reproduction of LP1 S0–S4 (H, stiff13, soft2, soft1; s ≤ 41.4 mm) under the A0-P0 preregistration [PR link], source set `6f7fb3ea…`, policy `074d7edc…`, LP0 `b4240d7e…`, contract evidence `78b6897f…`, run name `run_a0_lp1_repro_v1`. This does not authorize A1, S5, LP2 or any new physics. The GO file is to be removed after the run.

## 6. Pre-commit checklist for whoever commits a genuine GO

1. The commit with the GO contains no change to any `g2_lp0*.m`, `g2_lp1*.m` or `check_g2_lp*.m` file (the source set stays `6f7fb3ea…`).
2. The GO JSON is LF-encoded and contains the exact values above. Placeholder strings are replaced only by the investigator.
3. The execution clone has `core.autocrlf=false`, and the contract evidence bytes hash to `78b6897f…`.
4. `python -I scripts/g2/a0/a0_pin_check.py --commit <GO commit> --clone <clone> --archive <zip>` reports every check passing **except G1 ("no GO in tree")**. G1 must then fail, because the genuine GO is present. Any other failure is a blocker.
