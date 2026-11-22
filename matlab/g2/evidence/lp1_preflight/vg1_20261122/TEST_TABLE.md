# VG1 test table: corrected batch at f65d252 (74 contract tests and 8 mutation checks)

Source: `E_corrected_batch_f65d252/CONTRACT_TESTS.json` (contract tests) and `B_amended_pure_suite_f65d252/CONTRACT_SENSITIVITY.json` (mutation checks).
A negative passes only when the observed identifier equals the expected identifier **and** the message contains the expected fragment (the part after `|`).

| # | Test | Class | Expected | Observed | Pass |
|---:|---|---|---|---|:---:|
| 1 | `positive_links` | positive | `true` | `true` | ✔ |
| 2 | `mutate_KI` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Signed K or solution` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 3 | `mutate_KII` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Signed K or solution` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 4 | `mutate_caseId` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Case, mask, ratio or index changed.` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 5 | `mutate_mask` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Case, mask, ratio or index changed.` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 6 | `mutate_ratio` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Case, mask, ratio or index changed.` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 7 | `mutate_stateIndex` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Case, mask, ratio or index changed.` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 8 | `mutate_policySHA256` | negative | `G2LP1:HOLD_SOURCE | Parent/source/policy link differs.` | `G2LP1:HOLD_SOURCE` | ✔ |
| 9 | `mutate_sourceSHA256` | negative | `G2LP1:HOLD_SOURCE | Parent/source/policy link differs.` | `G2LP1:HOLD_SOURCE` | ✔ |
| 10 | `mutate_parentSHA256` | negative | `G2LP1:HOLD_SOURCE | Parent/source/policy link differs.` | `G2LP1:HOLD_SOURCE` | ✔ |
| 11 | `mutate_polyline_mm` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Saved geometry differs` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 12 | `mutate_meshSHA256` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Signed K or solution` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 13 | `mutate_phaseSHA256` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Signed K or solution` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 14 | `wrong_units` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Unit conversion changed.` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 15 | `forged_pass_flag` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Signed K or solution` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 16 | `solution_case_link` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Signed K or solution` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 17 | `solution_source_drift` | negative | `G2LP1:HOLD_RECORD_INTEGRITY | Signed K or solution` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 18 | `own_signed_MTS` | positive | `true` | `true` | ✔ |
| 19 | `signed_KII_changes_path` | positive | `true` | `true` | ✔ |
| 20 | `S5_forecast` | negative | `G2LP1:HOLD_UNAUTHORIZED_STATE | S5 and later` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 21 | `S5_controller` | negative | `G2LP1:HOLD_UNAUTHORIZED_STATE | Only S0-S4` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 22 | `negative_state_controller` | negative | `G2LP1:HOLD_UNAUTHORIZED_STATE | Only S0-S4` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 23 | `fractional_state_controller` | negative | `G2LP1:HOLD_UNAUTHORIZED_STATE | Only S0-S4` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 24 | `compressive_parent` | negative | `G2LP1:HOLD_K_EXTRACTION | Invalid tensile MTS root` | `G2LP1:HOLD_K_EXTRACTION` | ✔ |
| 25 | `nonfinite_parent` | negative | `G2LP1:HOLD_K_EXTRACTION | Invalid tensile MTS root` | `G2LP1:HOLD_K_EXTRACTION` | ✔ |
| 26 | `zero_K_parent` | negative | `G2LP1:HOLD_K_EXTRACTION | Invalid tensile MTS root` | `G2LP1:HOLD_K_EXTRACTION` | ✔ |
| 27 | `controller_rejects_go_path_argument` | negative | `MATLAB:InputParser:UnmatchedParameter` | `MATLAB:InputParser:UnmatchedParameter` | ✔ |
| 28 | `gate_takes_context_only` | interface | `true` | `true` | ✔ |
| 29 | `gate_go_path_hardcoded` | interface | `true` | `true` | ✔ |
| 30 | `controller_calls_gate_before_run_folder` | interface | `true` | `true` | ✔ |
| 31 | `validator_opens_no_file` | interface | `true` | `true` | ✔ |
| 32 | `go_absent_production_gate` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | no separate GO record` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 33 | `go_absent_left_no_file` | go | `true` | `true` | ✔ |
| 34 | `go_fixture_positive_control` | go | `true` | `true` | ✔ |
| 35 | `go_not_struct` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | Incomplete scientific GO record` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 36 | `go_missing_field` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | Incomplete scientific GO record` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 37 | `go_wrong_decision` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | absent or invalid` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 38 | `go_wrong_review_status` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | absent or invalid` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 39 | `go_empty_reviewer` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | absent or invalid` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 40 | `go_foreign_review_url` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | absent or invalid` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 41 | `go_policy_mismatch` | go | `G2LP1:HOLD_SOURCE | does not bind` | `G2LP1:HOLD_SOURCE` | ✔ |
| 42 | `go_source_mismatch` | go | `G2LP1:HOLD_SOURCE | does not bind` | `G2LP1:HOLD_SOURCE` | ✔ |
| 43 | `go_lp0_mismatch` | go | `G2LP1:HOLD_SOURCE | does not bind` | `G2LP1:HOLD_SOURCE` | ✔ |
| 44 | `go_token_mismatch` | go | `G2LP1:HOLD_SOURCE | does not bind` | `G2LP1:HOLD_SOURCE` | ✔ |
| 45 | `go_contract_path_outside` | go | `G2LP1:HOLD_SOURCE | not pinned` | `G2LP1:HOLD_SOURCE` | ✔ |
| 46 | `go_contract_path_traversal` | go | `G2LP1:HOLD_SOURCE | not pinned` | `G2LP1:HOLD_SOURCE` | ✔ |
| 47 | `go_contract_missing` | go | `G2LP1:HOLD_SOURCE | absent or changed` | `G2LP1:HOLD_SOURCE` | ✔ |
| 48 | `go_contract_sha_mismatch` | go | `G2LP1:HOLD_SOURCE | absent or changed` | `G2LP1:HOLD_SOURCE` | ✔ |
| 49 | `go_contract_lacks_fields` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | lacks negative` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 50 | `go_contract_not_pass` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | has not passed` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 51 | `go_contract_incomplete_count` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | has not passed` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 52 | `go_contract_too_few_tests` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | has not passed` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 53 | `go_contract_physical_solve` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | has not passed` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 54 | `go_contract_mesh_build` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | has not passed` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 55 | `go_contract_negatives_false` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | has not passed` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 56 | `go_contract_integrity_false` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | has not passed` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 57 | `record_roundtrip` | record | `true` | `true` | ✔ |
| 58 | `overwrite_refused` | record | `G2Chain:RecordExists | overwrite` | `G2Chain:RecordExists` | ✔ |
| 59 | `byte_tamper` | record | `true` | `true` | ✔ |
| 60 | `manifest_tamper` | record | `true` | `true` | ✔ |
| 61 | `mat_without_manifest` | record | `true` | `true` | ✔ |
| 62 | `missing_record` | record | `true` | `true` | ✔ |
| 63 | `record_without_schema` | record | `G2Chain:RecordSchema | schema-tagged` | `G2Chain:RecordSchema` | ✔ |
| 64 | `record_missing_folder` | record | `G2Chain:RecordFolder | Parent record folder` | `G2Chain:RecordFolder` | ✔ |
| 65 | `admit_partial_state_refused` | admission | `G2LP1:HOLD_RECORD_INTEGRITY | Partial unreviewed state` | `G2LP1:HOLD_RECORD_INTEGRITY` | ✔ |
| 66 | `admit_partial_state_untouched` | admission | `true` | `true` | ✔ |
| 67 | `admit_low_memory_refused` | admission | `G2LP1:HOLD_MEMORY | 5 GiB` | `G2LP1:HOLD_MEMORY` | ✔ |
| 68 | `admit_low_memory_no_folder` | admission | `true` | `true` | ✔ |
| 69 | `admit_boundary_below_refused` | admission | `G2LP1:HOLD_MEMORY | 5 GiB` | `G2LP1:HOLD_MEMORY` | ✔ |
| 70 | `admit_nonfinite_memory_refused` | admission | `G2LP1:HOLD_MEMORY | 5 GiB` | `G2LP1:HOLD_MEMORY` | ✔ |
| 71 | `admit_nonfinite_no_folder` | admission | `true` | `true` | ✔ |
| 72 | `admit_at_threshold_creates_folder` | admission | `true` | `true` | ✔ |
| 73 | `admit_threshold_equals_policy` | admission | `true` | `true` | ✔ |
| 74 | `source_digest_detects_one_byte_drift` | positive | `true` | `true` | ✔ |

**74/74**, schema `NewMetacomp.G2.LP1.ContractTests.v2`, physicalSolves=0, meshBuilds=0.

## Mutation sensitivity (8 sabotaged guard copies, written to a temporary folder outside the repository)

| Mutation | File | Detected by | Missed | Pass |
|---|---|---|---|:---:|
| `token_binding_removed` | `g2_lp1_go_validate.m` | `go_token_mismatch` | — | ✔ |
| `binding_identifier_wrong` | `g2_lp1_go_validate.m` | `go_lp0_mismatch`, `go_policy_mismatch`, `go_source_mismatch`, `go_token_mismatch` | — | ✔ |
| `unrelated_same_identifier` | `g2_lp1_go_validate.m` | `go_contract_missing`, `go_fixture_positive_control`, `go_policy_mismatch`, `go_wrong_decision` | — | ✔ |
| `links_identifier_collapsed` | `g2_lp1_validate_links.m` | `mutate_parentSHA256`, `mutate_policySHA256`, `mutate_sourceSHA256` | — | ✔ |
| `folder_before_memory_guard` | `g2_lp1_admit_state.m` | `admit_low_memory_no_folder`, `admit_nonfinite_no_folder` | — | ✔ |
| `S5_cap_removed` | `g2_lp1_forecast.m` | `S5_forecast` | — | ✔ |
| `overwrite_allowed` | `g2_trajectory_record.m` | `overwrite_refused` | — | ✔ |
| `absent_go_not_checked` | `g2_lp1_scientific_gate.m` | `go_absent_production_gate` | — | ✔ |

**8/8** detected, clean suite passes afterwards: True. The original PR #55 suite detected **0/8** on the same set (7 applied; the admission-order case has no function at 70bf6f4); see `C_original_suite_mutation_comparison/orig_sens.log`.
