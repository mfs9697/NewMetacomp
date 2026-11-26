# G2-LP2-B1 evidence (geometry only)

- **Assignment:** https://github.com/mfs9697/NewMetacomp/issues/76
- **Memorandum (Ukrainian):** [`../G2_LP2B1_GEOMETRY_MEMO_UA.md`](../G2_LP2B1_GEOMETRY_MEMO_UA.md)
- **Status:** `REVIEW_STOP_LP2B1_GEOMETRY_READY`

**Scope:** zero physical FEM, no GO, no new accepted state, no LP2-A3 retry or resumption, no write under any historical run or ledger root.

**Paths and logs:**
- Absolute local paths are sanitized; see `SANITIZATION.json` in each folder.
- MATLAB startup path warnings were removed.
- Raw logs and all generated arrays are in archive `NewMetacomp_G2_LP2B1_Geometry_20261126.zip`:
  - SHA-256 `5a5a4179c987d04dcf14cf3d2552b8f9f1d9c370c370b0a6bd6c930748bbbd42`;
  - 76 members;
  - copies on the internal SSD and the removable drive, both verified member by member.

## Folder contents

| Folder | Content | Source commit |
|---|---|---|
| `wp0/` | `LP2B1_WP0.json`: read-only reconstruction of the stored soft1 S10 failure, 29/29. Contains the offending pair with full geometric context, the ratio distribution, and all ten accepted LP2-A3 meshes for comparison. `LP2B1_WP0_PYTHON_CHECK.json`: independent numpy recomputation, PASS | `e5f0d18` |
| `wp1_attempt1/` | Attempt 1 at 0.40 mm: HOLD caused by harness defects D1/D2 (see amendment A1). Records preserved | `e5f0d18` |
| `wp1_attempt2/` | Attempt 2 under amendment A1, in four parts:<br>– target 0.40 mm SELECTED (19/19);<br>– REPEAT: DETERMINISTIC;<br>– references soft1 S9 and H S10 at 0.40 mm: 19/19 each;<br>– stage records `LP2B1_WP1_TARGET/REPEAT/REFERENCES.json`.<br>0.50 and 0.35 mm were never generated | `3e8de6a` |
| `audit/` | `LP2B1_POSTAUDIT.json`: re-audit of the saved arrays. `LP2B1_SUMMARY_DIFF.json`: shows that the only attempt-1 versus attempt-2 difference is the `nativeMeshingSeconds` timing field. `LP2B1_INDEPENDENT_AUDIT_run1.json`: Python audit, first and only run, 0 problems | `097a971`, `a01e060` |
| `closure/` | Protected-file checks for the 832 known files:<br>– before and after, same manifest `e756d64a…`;<br>– known-protected manifest;<br>– early dry run without the removable drive (fails only on that copy).<br>Also: LP2-A3 hashcheck; archive record; all pre-start records, including the two refusals at 8.192 and 8.171 GiB, after which MATLAB was not started | — |
| `wp2/` | `G2_LP2B1_EQ_CONTRACT_DRAFT_v1.json`: prospective contract for two future equivalence solves (soft1 S9, H S10, 0.40 mm, WP5 C1–C11, state-specific predictor). A draft only, not a policy and not a GO | — |
| `figures/` | Ukrainian figures LP2B1-1 to LP2B1-3 (PNG 300 dpi and vector PDF). `v1_superseded/` holds the first rendering, whose bar-chart tick labels were wrong; it is kept for transparency | `a01e060` |
| `logs/` | Stage scripts and logs `s1`–`s6` | — |

## Pinned inputs

- **Pins file:** `matlab/g2/lp2b1/G2_LP2B1_PINS_v1.json`, SHA-256 `fbef586d…`.
- **Preregistration:** `matlab/g2/lp2b1/G2_LP2B1_PREREG_v1.json`, SHA-256 `3d51140b…`. Committed in `e5f0d18`, before any alternative mesh existed.
- **Amendment:** `matlab/g2/lp2b1/G2_LP2B1_PREREG_AMENDMENT_A1.json`. Committed in `3e8de6a`, before attempt 2.
