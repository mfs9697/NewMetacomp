# A1 pre-physical evidence (Issue #66)

No FEM solve was performed for anything in this folder.

| Folder | Source commit | Content |
|---|---|---|
| `geometry_d4022da/` | d4022da | `A1_GEOMETRY_QUALIFICATION.json`: 4 cases × m = 0, 3, 6, 9. Covers validator (19 gates), LP1 bank adapter, phase audit, owner-free q, m = 0 exactness (19 fields), mesh file and content SHA-256, and the B6/B9 common q-active set. Includes the run log. |
| `batch_6a3a14d/` | 6a3a14d | `PREPHYSICAL_RESULT.json` (status `A1_TESTS_PASS_SCIENTIFIC_HOLD`; token; 12 dry calls; RAM observations; 0 solves). `CONTRACT_TESTS.json` (46/46; this exact file is the `contractEvidenceFile` a GO_A1 must bind, SHA-256 `06ef678ed387d1c3ecfbb105a8a8609aa0248f16d68c8067faed69877f82f3de`). The driver `a1_batch.m` and its log. `SANITIZATION.json`. |

Local paths in logs are replaced by `<repo>`, `<scratch>` and `<user>`. `SANITIZATION.json` records that `CONTRACT_TESTS.json` was not modified.

The A1 source digest covers every top-level `matlab/g2/*.m`. Do not add, remove or edit any of these files after 6a3a14d unless the policy and the GO pins are regenerated.
