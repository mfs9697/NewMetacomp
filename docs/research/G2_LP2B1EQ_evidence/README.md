# G2-LP2-B1-EQ evidence (readiness only)

- **Assignment:** https://github.com/mfs9697/NewMetacomp/issues/78
- **Memorandum (Ukrainian):** [`../G2_LP2B1EQ_READINESS_MEMO_UA.md`](../G2_LP2B1EQ_READINESS_MEMO_UA.md)
- **Decision template:** [`../G2_LP2B1EQ_GO_DECISION_TEMPLATE.md`](../G2_LP2B1EQ_GO_DECISION_TEMPLATE.md). It is not a GO and creates no GO file.
- **Status:** `REVIEW_STOP_LP2B1_EQ_READY`

**Scope:** zero physical FEM (`g2_m4b_sif_partial` never called), no GO, no new state, no target soft1 S10 solve, no LP2-B2, no change to historical sources, policies, records or archives.

**Source commit of all final evidence:** `61733fd7d33adbaad69c09055b0bdcd74a1f93c3`

| Item | Value |
|---|---|
| Policy `matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json` | `b113a7c6d7b2e8fe9950d817ccca3c851c05f1e347c73f66c604b9c41e54eecb` |
| `lp2b1eq` source digest (15 `.m`) | `74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f` |

**Paths and logs:**
- Absolute local paths are sanitized; see `SANITIZATION.json` in each folder for source and published SHA-256 values.
- MATLAB startup path warnings were removed from the logs.
- Binaries (`.mat` arrays, raw `.f64` exports) are in the archive only; see `closure/LP2B1EQ_ARCHIVE_RECORD.json`.

## Folder contents

| Folder | Content |
|---|---|
| `wp0/` | Archived-reference qualification under the real preflight. `wp0_v4` is final: 17/17 checks for each of soft1 S9 and H S10. `wp0_v3` is the same result at an earlier commit. `wp0_v1` and `wp0_v2` stopped before any check because of code defects; they have no JSON, and their logs are `logs/s2_wp0.log` and `logs/s2b_wp0.log` |
| `replay/` | Geometry-only 0.40 mm admission replay, no solve:<br>– `replay_v3` (final): 15/15 + 15/15;<br>– `replay_v2`: same result at the corrected commit;<br>– `replay_v1`: H S10 HOLD on the topology tip sub-check, preserved;<br>– `diag_tip_v1`: diagnosis showing the H tip node one ulp from the polyline tip, identically in the archived and new mesh |
| `export/` | Index of the raw exports (qualification and replay canonical arrays) used by the independent Python hashcheck |
| `tests/` | Zero-FEM suite:<br>– `tests_v3` (final): 252/252; this file is the contract evidence of the GO template, SHA-256 `35d891197fdcf7514f8486ace41ff56c406ebfa4370eb1733db99b81e5b4b77a`;<br>– `tests_v2`: 250/252, two fixture defects;<br>– `tests_v1`: no JSON, crashed after 213 passes; log `logs/s4_tests_v1.log` |
| `closure/` | Protected checks before and after: PASS, 891 files, combined manifest `e351f5ac…` unchanged, including the 832 known files (`e756d64a…`), the 43 LP2-B1 outputs and 61 policy-pinned files. Also the independent hashcheck (12/12), all 12 pre-start records (all pass) and the archive record |
| `logs/` | Stage scripts and logs `s1` to `s5`, plus the helper scripts used (`repin.sh`, `digest.py`, `publish.py`) |
