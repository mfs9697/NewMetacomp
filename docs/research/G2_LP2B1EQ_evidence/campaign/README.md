# G2-LP2B1-EQ-001 campaign evidence (authorized physical equivalence demonstration)

- **Authorization:** `GO_LP2B1_EQ`, https://github.com/mfs9697/NewMetacomp/pull/79#issuecomment-7211904299
- **Readiness review:** https://github.com/mfs9697/NewMetacomp/pull/79#pullrequestreview-6084428945
- **Memorandum (Ukrainian):** [`../../G2_LP2B1EQ_DEMONSTRATION_MEMO_UA.md`](../../G2_LP2B1EQ_DEMONSTRATION_MEMO_UA.md)
- **Status:** `REVIEW_STOP_LP2B1_EQ_DEMONSTRATION`

| Item | Value |
|---|---|
| Approved head | `7d0df53f35b30c4e33734c40fdda33e987ea96ee` |
| Activation commit (GO file only) | `3269d125825dcc403ea9ab975fb5ab55d9a003e8`, GO SHA-256 `6abdc02b7ba3d088b9d8b4edced1e7003b4c142f02c21610dcd9ced7567aac2c` |
| Revocation commit (GO file deleted; tree = approved head) | `d8906ce669fe6d7e52f6fd773c4fbdbf65fa7447` |
| Entry calls / case calls / physical solves attempted / completed | 1 / 2 / 2 / 2 |
| Controller outcome | `EQUIVALENT_AT_0p40` (EQB-soft1-S9 `EQUIVALENT_CASE`, then EQB-H-S10 `EQUIVALENT_CASE`) |
| Read-only verifier (in run and after revocation) | `VERIFIED_EQUIVALENT` |
| Independent audit `verify/LP2B1EQ_AUDIT_v3.json` | PASS, 59/59 |
| Campaign archive | `NewMetacomp_G2_LP2B1EQ_Campaign_20261127.zip`, `1d739f80fe77597e3749de7e939abf8f572bc48f27bb703c28d02f94634d6e8a`, 136 members, verified on C: and the removable D: |

**Paths, logs and binaries:**
- Absolute local paths are sanitized; see `SANITIZATION.json` in each folder.
- The full GitHub API dump of the authorization comment is replaced by a reduced record (URL, author, time, body SHA-256).
- `.mat` records and raw `.f64` exports are in the archive only. The figure PNG and PDF are copied byte for byte.

## Folder contents

| Folder | Content |
|---|---|
| `pre/` | Before activation, with the GO absent:<br>– hashcheck 12/12 on the committed contract evidence;<br>– protected check (891 files, `e351f5ac…`);<br>– MATLAB activation checks (correct-token refusals `HOLD_UNAUTHORIZED` for both solves, zero writes);<br>– all pre-start records (01 refused at 5.62 GiB, 02 refused with D: detached, 03–05 pass);<br>– authorization activation record, GO candidate and activation-commit check |
| `campaign/` | `LP2B1EQ_PRECHECK.json` and `LP2B1EQ_CAMPAIGN.json` written by the single entry call |
| `records/` | JSON records of the run (COMPARISON.json, geometry ATTEMPT.json, record manifests, receipt manifest, campaign summary) |
| `post/` | Post-revocation refusals; pre-start records 06–08; protected check after the campaign (attempt 1 with D: detached preserved); archive record |
| `verify/` | Verifier after revocation; full record dump; raw export index; independent audit:<br>– `v3` final, PASS 59/59;<br>– `v2` HOLD, caused by audit defects (case-sensitive hashes and an ill-posed agreement rule);<br>– attempt 1 crashed on dump parsing |
| `figures/` | Ukrainian figure LP2B1EQ-1: tolerance utilization |
| `logs/` | MATLAB scripts and logs, Python helpers, commit messages, tables; `earlier/` holds the failed pre-activation attempt 1 log and the first figure log |
