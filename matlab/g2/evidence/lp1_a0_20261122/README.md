# A0 campaign G2-LP1-A0-001 evidence (Issue #64), 22 November 2026

| Path | Content |
|---|---|
| `preflight/` | Pin check at the GO commit (all pass except G1, which must fail because the GO exists); execution-clone readiness; read-only production-gate and campaign check (`OPEN_NEW`, wrong run refused, no write) |
| `campaign/` | Campaign driver and log: eight calls, 20 solves, `OPEN_NEW` → `CONTINUE` → `CLOSED`, no HOLD (`A0_CALLS.json`, `A0_CAMPAIGN_RESULT.json`). Post-closure `VERIFY_ONLY` ×4: computed=0, reused=5, promoted=0, 226 files byte-unchanged (`A0_VERIFY_ONLY.json`) |
| `audit/` | Tiered comparison (`A0_COMPARISON.json`: 20/20 tier A, `A0_REPRODUCED_EXACT`); independent Python cross-check (`A0_INDEPENDENT_CROSSCHECK.json`: 20/20 bitwise in all saved fields, provenance, ledger); new-run mesh quality |
| `post_revocation/` | Probe after the GO was removed: correct-token call refused with `HOLD_UNAUTHORIZED_STATE`, 226 files unchanged |
| `A0_RESULTS_TABLES.md` | Call table, 20-row per-state comparison, S4 classes, provenance and STATE hashes, ledger hashes, VERIFY_ONLY |
| `A0_RUN_RECORDS_SHA256.json`, `A0_CAMPAIGN_LEDGER_SHA256.json` | SHA-256 of all 182 new run files and 44 ledger files |
| `A0_ARCHIVE.json` | Out-of-tree archive `NewMetacomp_G2_LP1_A0_Records_20261122.zip`, 52,882,094 bytes, SHA-256 `77be5255251a0aff9cd3e1ff8e5fc8ce69dc43f7776da94553673e734d24c7aa`, 226 members verified |

**Commits.**
- GO: `135a5f6`.
- Computation evidence: `6a34f12`.
- GO provenance record: `cda2502`.
- GO revocation: `3beae0b`.
- Post-revocation evidence and reports: the following commit.

Local paths are replaced by placeholders; each `SANITIZATION.json` keeps the original SHA-256 values. The MAT files are not committed.
