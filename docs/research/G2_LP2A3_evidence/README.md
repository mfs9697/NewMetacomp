# G2-LP2-A3 readiness evidence (preparation only)

- **Assignment:** https://github.com/mfs9697/NewMetacomp/issues/74
- **Memorandum (Ukrainian):** [`../G2_LP2A3_READINESS_MEMO_UA.md`](../G2_LP2A3_READINESS_MEMO_UA.md)
- **GO template (not a GO):** [`../G2_LP2A3_GO_DECISION_TEMPLATE.md`](../G2_LP2A3_GO_DECISION_TEMPLATE.md)

**Status: zero physical FEM solves, zero new accepted states, no GO file, no run root, no ledger root.**

All evidence runs used the clean LF execution clone at the source commit printed in each file. Absolute local paths are sanitized; see `logs/SANITIZATION.json`. Logs written by the launcher as UTF-16 were converted to UTF-8 first.

| File | Content | Source commit |
|---|---|---|
| `LP2A3_TESTS_v1.json` | Contract evidence. LP2-A3 suite **78/78**: context and pins, guard, classification, default-rung mesh (identical to ladder rung 1; real rung-1 failure `C2_stiff13_straight_S10` stays failed, while the ladder would use rung 2), failure classes, admission hook, chain with injected operations (normal S9–S11 + S12 information-only, closure, local and global stops, no retry, tampering, post-closure read-only replay), GO negatives and JSON round trip, 6 real-git tests through Windows `system()`, WP5 replay regression `VERIFIED_V2`. SHA `2aa6a904…` | `2775d8b` |
| `LP2A3_S9_DRY_v1.json` | The four actual S9 candidates from the archived S8 parents: bitwise TERMINAL match, nominal clearance, 1-mm guard, rung-1 mesh, 34 audit gates, pairing P1–P10, phase/owner, 76 chords, actual-polygon clearance. No solve, no write | `2775d8b` |
| `LP2A3_UNCHANGED_LP2_CONTRACT.json` | Unchanged LP2-A1 contract suite `g2_lp2_contract`: 101/101 | `2775d8b` |
| `LP2A3_UNCHANGED_LP2A2_EQ_TESTS.json` | Unchanged LP2-A2 suite v3: 72/80. The 8 failures (E5, E6×4, E9, E11, E12 no-output) each assert that `outputs/g2_lp2a2_eq_v1` is absent. That pre-campaign condition no longer holds: the root now holds the 24 protected WP5 records | `2775d8b` |
| `LP2A3_HASHCHECK_v1.json` | Independent Python recomputation: 4 source digests, 3 policies, 20 S8 parents (= LP2-A1 manifest), 24 WP5 records + 8 evidence files, token equal to MATLAB, evidence SHA. 18/18 | read-only |
| `LP2A3_PROTECTED_CHECK_v1.json`, `LP2A3_PROTECTED_MANIFEST.json` | 723 protected files (541 tree `20f2d54f…` + 158 LP2-A1 run/ledger + 24 WP5 records), disjoint; manifest of every path and SHA-256 | read-only |
| `figures/` | LP2A3-1, the actual S9 candidates near ring 1 (PNG 300 dpi, vector PDF), from `scripts/g2/lp2a3/lp2a3_figures.m` | — |
| `logs/` | Stage scripts and logs `ev1`–`ev4`, figure run, and the development dry smoke (`dev_dry.log`, uncommitted sources, superseded by `ev2_s9`) | — |

**Reproduction:** see the memorandum, section "Відтворення". Earlier, superseded runs of the contract suite are kept only in the scratch logs:
- at `8474edc`, 77/78: H0 was refused by the unchanged 5 GiB preflight after the mesh tests;
- reruns at `2775d8b` caused by a case-insensitive "refuse" match in the wait loop; all were 78/78.
