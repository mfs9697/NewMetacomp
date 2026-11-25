# LP2 preparation evidence (no FEM, no GO)

Memorandum: [`../G2_LP2_CONTINUATION_MEMO_UA.md`](../G2_LP2_CONTINUATION_MEMO_UA.md).

| Location | Status | Content |
|---|---|---|
| `qualification_v2/` | **current** (after corrections C1–C4, commit `8d49759`) | `LP2A_CONTRACT.json` (SHA-256 `34fedbda…`; the file a future GO_LP2A must pin): 107/107, 56 negatives, 0 solves. Also `LP2A_QUALIFICATION.json` (token, digests, original-versus-corrected pins, inherited-evidence provenance), `LP2_S5_GEOMETRY_recheck.json` (read-only S4/S5 re-run, identical to the original), runner and log |
| `qualification_v1_86a88fa/` | historical (superseded) | The original qualification: 70/70, policy `f9d0ce0c…`, LP2 source `f114a619…`, contract `ffcd126b…`. Its token is no longer valid for a GO |
| `LP2_S5_GEOMETRY.json` | inherited unchanged | WP1. A0 S4 audit, S5 candidates (A0 and B9), clearance, kink gates, classification, hypothetical outlooks |
| `LP2_MESH_PROBE.json`, `LP2_MESH_SCAN.json` | inherited unchanged (82 meshes, not rebuilt) | S5 candidate meshes 4/4; synthetic S6–S20 scan. Provenance is rechecked in v2: the producing LP2 files are byte-identical, and the shared digest and parents are unchanged |
| `LP2_1_S4_S5_UA.*`, `LP2_2_sitka_UA.*` | inherited unchanged | Ukrainian figures |
| `SANITIZATION.json` (top level, v1 files) and `qualification_v2/SANITIZATION.json` | — | Original and sanitized hashes |

No mesh was saved and no boundary-value problem was solved.
