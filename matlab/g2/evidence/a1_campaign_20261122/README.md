# A1 campaign G2-A1-FB-001 evidence (Issue #66)

Authorized by the investigator in Issue #66, comment 7085445180. GO commit ffe5ba9 (GO SHA-256 `b8693fdf…`); revocation commit 16681cc. Results tables: [`A1_RESULTS_TABLES.md`](A1_RESULTS_TABLES.md).

| Path | Content |
|---|---|
| `campaign/a1_campaign.m`, `.log` | Driver for the 12 sequential calls. It checks the in-MATLAB context token, validates the GO and confirms no run folder or ledger exists; it stops on any exception or returned HOLD. Log of all 12 `A1_STATE_COMPLETE` calls and `A1_CAMPAIGN_DONE closed=1`. |
| `campaign/A1_CALLS.json` | Per-call status, K_I, K_II, G, J, MTS, time and memory |
| `campaign/a1_verify.m`, `.log`, `A1_VERIFY_ONLY.json` | 12 VERIFY_ONLY calls (0 solves), ledger snapshot and inventory, CLOSED keys and state SHAs |
| `campaign/A1_ANALYSIS.json` | `scripts/report/g2_a1_analyze.m` output, computed from saved records only. Includes the independent record checks. |
| `campaign/A1_RUN_RECORDS_SHA256.json`, `A1_CAMPAIGN_LEDGER_SHA256.json` | SHA-256 of all 50 run files and all 28 ledger files |
| `campaign/A1_PROTECTED_RECORDS_UNCHANGED.json` | Before/after hashes of the A0/LP1 runs, the A0 ledger and the A1 meshes (421 files; 0 changed; A0 manifest 182/182) |
| `post_revocation/` | Refusal probe after revocation (`G2A1:HOLD_UNAUTHORIZED_STATE`, no writes) and generation of result figures F4–F6. Also holds the helper scripts used: independent pin recheck, GO composer, protected-tree snapshot, archive builder and verifier. |
| `A1_ARCHIVE.json` | Archive record: local copy plus a physically separate removable drive, both verified |

Local paths are sanitized to `<repo>` (execution clone), `<worktree>`, `<scratch>` and `<user>`. The `SANITIZATION.json` files record original and sanitized hashes. Binary `.mat` records are not committed; they are in the archive.
