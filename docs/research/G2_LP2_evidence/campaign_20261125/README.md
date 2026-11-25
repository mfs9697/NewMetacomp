# LP2-A1 campaign G2-LP2A-001 evidence (PR #70)

The campaign was authorized in PR #70 comment 7159870558 (approved head `3b7bdb9`; v2 qualification 107/107). Commits: GO `1f200fa`, evidence `72cb18e`, revocation `ee4a28a`. Report: [`../../G2_LP2A1_DEMONSTRATION_REPORT_UA.md`](../../G2_LP2A1_DEMONSTRATION_REPORT_UA.md).

**Outcome:** 16 admissions = 16 physical solves = 16 accepted states (S5–S8 × 4 cases), 0 HOLD. All four cases are `CAMPAIGN_LIMIT_REACHED`, and the campaign is CLOSED.

| File | Content |
|---|---|
| `LP2_ACTIVATION_HASHCHECK.json`, `LP2_ACTIVATION_HASHCHECK_2.json`, `lp2_activation_hashcheck.py` | Independent Python recomputation of the pins and token: the first activation (held for the missing backup drive) and the repeat |
| `LP2_ACTIVATION_CHECKS_1/2.json`, `lp2_activation_checks.m`, `.log`, `2.log` | MATLAB checks with the GO absent: memory inside MATLAB, four dry calls, and the correct-token Run=true refusal probe (no writes) |
| `lp2a_campaign.m/.log`, `LP2A_CALLS.json` | The external campaign wrapper with its global-stop rule, and the four calls with per-case verification decisions |
| `lp2a_verify_analyze.m/.log`, `LP2A_VERIFY_ONLY.json`, `LP2A_ANALYSIS.json` | Four VERIFY_ONLY calls (zero solves, no writes), full verifier, numerical checks of 16/16 states, and the preregistered analysis |
| `LP2_PROTECTED_BEFORE.json`, `LP2_PROTECTED_AFTER.json`, `lp2_tree_hash.py` | The 541 protected files, identical before and after |
| `LP2A_RUN_LEDGER_SHA256.json`, `LP2A_ARCHIVE_RECORD.json`, `lp2a_archive.py` | SHA-256 of the 158 run and ledger files, and the archive `82740133…` (172 members), verified locally and on the removable USB drive |
| `LP2A_POST_REVOCATION.json`, `lp2a_post_revocation.m/.log` | Correct-token calls after revocation, refused with no write |
| `LP2A_1…4_*_UA.png/.pdf` | Ukrainian figures (`scripts/g2/lp2/g2_lp2a_figures.m`) |

Binary MAT records are not committed; they are in the archive.
