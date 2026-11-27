# G2-LP2-B1-S10 evidence (readiness only)

- **Assignment:** https://github.com/mfs9697/NewMetacomp/issues/81
- **Memorandum (Ukrainian):** [`../G2_LP2B1S10_READINESS_MEMO_UA.md`](../G2_LP2B1S10_READINESS_MEMO_UA.md)
- **Decision template:** [`../G2_LP2B1S10_GO_DECISION_TEMPLATE.md`](../G2_LP2B1S10_GO_DECISION_TEMPLATE.md). It is not a GO and creates no GO file.
- **Status:** `REVIEW_STOP_LP2B1_S10_READY`

**Scope:**
- Zero physical FEM: `g2_m4b_sif_partial` was never called.
- No GO and no new STATE.
- No S11 mesh, admission or solve; no LP2-B2.
- No change to historical sources, policies, records or archives.

**Source commits of the final evidence:**
- `b2a0347799dc02ac6e2f1ab76eb2589d9bce4238`: MATLAB stages.
- `116f3d017430ccf9f4922cfd03381b5afdf17612`: Python checks. It adds only `scripts/g2/lp2b1s10/*.py`, so the token is unchanged.

| Item | Value |
|---|---|
| Policy `matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json` | `f57433eccc5641ba253da52b723a0de6b1ad299793aa227235d309e57f120171` |
| `lp2b1s10` source digest (7 `.m`) | `d544fcfde1cfaa1e7118e0c5959551bdddb1cd477739bcf55376c45fe8388ab9` |

**Paths, logs and binaries:**
- Absolute local paths are sanitized; see `SANITIZATION.json` in each folder.
- MATLAB startup path warnings were removed from the logs.
- Binaries (`.mat`, raw `.f64`) are in the archive only; see `closure/LP2B1S10_ARCHIVE_RECORD.json`.

## Folder contents

| Folder | Content |
|---|---|
| `wp0/` | Target qualification under the real preflight:<br>– `wp0_v2` (final, `b2a0347`): 9/9;<br>– `wp0_v1` (`e95206c`): the same result, plus static analysis of the module |
| `replay/` | Geometry-only 0.40 mm replay of the exact target, no solve. `replay_v1`: B1EQ admission 15/15 plus 7/7 exact expectations, canonical `54293d2a…` |
| `export/` | Index of the raw exports of the qualification and replay arrays, used by the independent hashcheck |
| `tests/` | Zero-FEM suite:<br>– `tests_v2` (final): 96/96; this file is the contract evidence of the GO template, SHA-256 `9d97017e78d0fdc58d1d75b45dcd8e8e58ed48c0e2874b9d6877cac32381cf64`;<br>– `tests_v1`: 95/96, G18 fixture defect; diagnosis in `logs/s3_diag_g18.*` |
| `closure/` | Before and after readiness:<br>– independent hashcheck (15/15);<br>– protected checks before and after (918-file union), plus the trial run of the then-uncommitted script;<br>– all pre-start records;<br>– D: stability log;<br>– archive record |
| `logs/` | Stage scripts and logs `s1` to `s4`, plus the helpers `repin.sh`, `digest.py` and `publish.py` |
