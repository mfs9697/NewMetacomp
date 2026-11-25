# M5-X6 campaign G2-M5-X6-001 evidence (PR #69)

The campaign was authorized in PR #69 comment 7096377708 (approved head `2baa641`). Commits: GO `dbf1b8d`, evidence `4f285b2`, revocation `c894394`. Report: [`../../G2_M5_X6_DEMONSTRATION_REPORT_UA.md`](../../G2_M5_X6_DEMONSTRATION_REPORT_UA.md).

| File | Content |
|---|---|
| `ACTIVATION_HASHCHECK.json`, `activation_hashcheck.py` | Independent Python recomputation of every pin and of the token (GO absent) |
| `ACTIVATION_CHECKS.json`, `ACT_DIAGONAL_AUDIT.json`, `activation_checks.m/.log` | MATLAB re-verification: 4/4 diagonals and six dry checks, plus the correct-token Run=true refusal probe (`G2M5X6:HOLD_UNAUTHORIZED_STATE`, no writes) |
| `m5x6_campaign_precheck_refused.log` | The first launch, refused by the wrapper's own in-MATLAB ≥ 7 GiB check (6.861 GiB) before any driver call |
| `m5x6_campaign.m/.log`, `M5X6_CALLS.json` | The six calls, each `M5X6_STATE_COMPLETE`, with the ledger closed after the sixth |
| `m5x6_verify_analyze.m/.log`, `M5X6_VERIFY_ONLY.json`, `M5X6_ANALYSIS.json` | Six VERIFY_ONLY calls (zero solves), record checks, ledger snapshot, and the output of the preregistered `m5x6_analyze` |
| `PROTECTED_BEFORE.json`, `PROTECTED_AFTER.json`, `tree_hash.py` | SHA-256 of the 499 protected A0/A1/LP1 output files: identical before and after |
| `M5X6_RUN_LEDGER_SHA256.json` | SHA-256 of the 42 run and ledger files |
| `M5X6_ARCHIVE_RECORD.json`, `archive_m5x6.py` | Archive `49def65c…` (55 members), verified locally and on the removable USB drive D: |
| `M5X6_POST_REVOCATION.json`, `post_revocation.m/.log` | Correct-token calls after revocation, refused with no write |
| `SANITIZATION.json` | Original and sanitized hashes of the text files |

Binary MAT records are not committed; they are in the archive.
