# VG2 test table: batch at adbc8a6 (138 contract tests and 16 mutation checks)

A negative passes only if the observed identifier equals the expected one **and** the message contains the fragment after `|`. Tests 1-74 are the VG1 tests (unchanged); the campaign, ledger, admission-hook and wiring tests are new in VG2.

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
| 75 | `go_missing_campaign_id` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | Incomplete scientific GO record` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 76 | `go_missing_run_name` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | Incomplete scientific GO record` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 77 | `go_wrong_campaign_scope` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | Campaign scope, run name or campaign ID is invalid` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 78 | `go_historical_run_name` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | Campaign scope, run name or campaign ID is invalid` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 79 | `go_run_name_syntax` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | Campaign scope, run name or campaign ID is invalid` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 80 | `go_campaign_id_syntax` | go | `G2LP1:HOLD_UNAUTHORIZED_STATE | Campaign scope, run name or campaign ID is invalid` | `G2LP1:HOLD_UNAUTHORIZED_STATE` | ✔ |
| 81 | `camp_open_new_positive` | campaign | `true` | `true` | ✔ |
| 82 | `camp_wrong_run_name` | campaign | `G2LP1:HOLD_CAMPAIGN_SCOPE | not the run approved` | `G2LP1:HOLD_CAMPAIGN_SCOPE` | ✔ |
| 83 | `camp_missing_run_name` | campaign | `G2LP1:HOLD_CAMPAIGN_SCOPE | not the run approved` | `G2LP1:HOLD_CAMPAIGN_SCOPE` | ✔ |
| 84 | `camp_historical_run_name` | campaign | `G2LP1:HOLD_CAMPAIGN_SCOPE | not the run approved` | `G2LP1:HOLD_CAMPAIGN_SCOPE` | ✔ |
| 85 | `camp_duplicate_campaign_new_run` | campaign | `G2LP1:HOLD_CAMPAIGN_SCOPE | not the run approved` | `G2LP1:HOLD_CAMPAIGN_SCOPE` | ✔ |
| 86 | `camp_ledger_integrity_fail` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | ledger record failed` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 87 | `camp_run_folder_without_receipt` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | Run folder exists without` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 88 | `camp_entries_without_receipt` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | Ledger entries exist without` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 89 | `camp_closure_without_receipt` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | Ledger entries exist without` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 90 | `camp_continue_positive` | campaign | `true` | `true` | ✔ |
| 91 | `camp_repeated_staged_calls_continue` | campaign | `true` | `true` | ✔ |
| 92 | `camp_receipt_other_go` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | does not bind` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 93 | `camp_receipt_other_campaign` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | does not bind` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 94 | `camp_receipt_other_run` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | does not bind` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 95 | `camp_receipt_other_token` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | does not bind` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 96 | `camp_receipt_spoofed_fields` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | does not bind` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 97 | `camp_interrupted_opening_continue` | campaign | `true` | `true` | ✔ |
| 98 | `camp_deleted_run_folder` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | Admitted states are missing` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 99 | `camp_run_token_mismatch` | campaign | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | Run record token differs` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 100 | `camp_closed_verify_only` | campaign | `true` | `true` | ✔ |
| 101 | `camp_closed_overrides_resume` | campaign | `true` | `true` | ✔ |
| 102 | `camp_hold_without_review` | campaign | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED | Unreviewed pre-admission` | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED` | ✔ |
| 103 | `camp_hold_reviewed_resume_positive` | campaign | `true` | `true` | ✔ |
| 104 | `camp_resume_wrong_hold` | campaign | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED | does not bind this campaign and HOLD` | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED` | ✔ |
| 105 | `camp_resume_wrong_campaign` | campaign | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED | does not bind this campaign and HOLD` | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED` | ✔ |
| 106 | `camp_resume_wrong_decision` | campaign | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED | does not bind this campaign and HOLD` | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED` | ✔ |
| 107 | `camp_resume_foreign_url` | campaign | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED | does not bind this campaign and HOLD` | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED` | ✔ |
| 108 | `camp_resume_empty_reviewer` | campaign | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED | does not bind this campaign and HOLD` | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED` | ✔ |
| 109 | `camp_resume_allowance_exhausted` | campaign | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED | allowance exhausted` | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED` | ✔ |
| 110 | `camp_two_unreviewed_holds` | campaign | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED | More than one` | `G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED` | ✔ |
| 111 | `camp_resolved_hold_continue_without_resume_file` | campaign | `true` | `true` | ✔ |
| 112 | `ledger_absent_snapshot` | ledger | `true` | `true` | ✔ |
| 113 | `ledger_roundtrip_positive` | ledger | `true` | `true` | ✔ |
| 114 | `ledger_duplicate_receipt_refused` | ledger | `G2Chain:RecordExists | overwrite` | `G2Chain:RecordExists` | ✔ |
| 115 | `ledger_duplicate_admit_refused` | ledger | `G2Chain:RecordExists | overwrite` | `G2Chain:RecordExists` | ✔ |
| 116 | `ledger_invalid_entry_name` | ledger | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | Invalid ledger entry name` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 117 | `ledger_path_traversal_name` | ledger | `G2LP1:HOLD_CAMPAIGN_INTEGRITY | Invalid ledger entry name` | `G2LP1:HOLD_CAMPAIGN_INTEGRITY` | ✔ |
| 118 | `ledger_closed_positive` | ledger | `true` | `true` | ✔ |
| 119 | `ledger_tampered_entry_detected` | ledger | `true` | `true` | ✔ |
| 120 | `ledger_unexpected_file_detected` | ledger | `true` | `true` | ✔ |
| 121 | `ledger_foreign_entry_detected` | ledger | `true` | `true` | ✔ |
| 122 | `ledger_kind_spoof_detected` | ledger | `true` | `true` | ✔ |
| 123 | `ledger_orphan_manifest_detected` | ledger | `true` | `true` | ✔ |
| 124 | `admit_hook_not_called_on_low_memory` | admission | `G2LP1:HOLD_MEMORY | 5 GiB` | `G2LP1:HOLD_MEMORY` | ✔ |
| 125 | `admit_hook_low_memory_no_call_no_folder` | admission | `true` | `true` | ✔ |
| 126 | `admit_hook_refusal_leaves_no_folder` | admission | `G2LP1:HOLD_CAMPAIGN_CLOSED | Campaign is closed` | `G2LP1:HOLD_CAMPAIGN_CLOSED` | ✔ |
| 127 | `admit_hook_refusal_no_folder` | admission | `true` | `true` | ✔ |
| 128 | `admit_hook_positive_then_folder` | admission | `true` | `true` | ✔ |
| 129 | `controller_campaign_decided_before_writes` | interface | `true` | `true` | ✔ |
| 130 | `controller_receipt_only_on_open_new` | interface | `true` | `true` | ✔ |
| 131 | `controller_admission_uses_campaign_hook` | interface | `true` | `true` | ✔ |
| 132 | `controller_verify_only_checked_before_loop` | interface | `true` | `true` | ✔ |
| 133 | `controller_campaign_refusal_writes_no_state` | interface | `true` | `true` | ✔ |
| 134 | `gate_returns_validated_go_sha` | interface | `true` | `true` | ✔ |
| 135 | `campaign_validator_opens_no_file` | interface | `true` | `true` | ✔ |
| 136 | `resume_path_hardcoded` | interface | `true` | `true` | ✔ |
| 137 | `controller_rejects_resume_path_argument` | negative | `MATLAB:InputParser:UnmatchedParameter` | `MATLAB:InputParser:UnmatchedParameter` | ✔ |
| 138 | `controller_rejects_campaign_argument` | negative | `MATLAB:InputParser:UnmatchedParameter` | `MATLAB:InputParser:UnmatchedParameter` | ✔ |

**138/138**, schema `NewMetacomp.G2.LP1.ContractTests.v3`, physicalSolves=0, meshBuilds=0.

## Mutation sensitivity (sabotaged copies in a temporary folder outside the repository)

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
| `campaign_run_name_unchecked` | `g2_lp1_campaign_validate.m` | `camp_duplicate_campaign_new_run`, `camp_historical_run_name`, `camp_wrong_run_name` | — | ✔ |
| `receipt_go_sha_unbound` | `g2_lp1_campaign_validate.m` | `camp_receipt_other_go` | — | ✔ |
| `closed_campaign_reopened` | `g2_lp1_campaign_validate.m` | `camp_closed_overrides_resume`, `camp_closed_verify_only` | — | ✔ |
| `resume_allowance_raised` | `g2_lp1_campaign_validate.m` | `camp_resume_allowance_exhausted` | — | ✔ |
| `deleted_run_folder_accepted` | `g2_lp1_campaign_validate.m` | `camp_deleted_run_folder` | — | ✔ |
| `ledger_tamper_ignored` | `g2_lp1_campaign_ledger.m` | `ledger_tampered_entry_detected` | — | ✔ |
| `campaign_hook_before_memory_guard` | `g2_lp1_admit_state.m` | `admit_hook_low_memory_no_call_no_folder` | — | ✔ |
| `go_campaign_scope_unchecked` | `g2_lp1_go_validate.m` | `go_wrong_campaign_scope` | — | ✔ |

**16/16** detected; the unmodified suite passes again afterwards: True.
