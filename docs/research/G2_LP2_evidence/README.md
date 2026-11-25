# LP2 preparation evidence (no FEM, no GO)

The qualification ran in the clean execution clone (`core.autocrlf=false`), detached at commit `86a88fa`. Status `LP2A_PREFLIGHT_PASS_SCIENTIFIC_HOLD`: 70/70, 0 physical solves, 541 protected files unchanged. Memorandum: [`../G2_LP2_CONTINUATION_MEMO_UA.md`](../G2_LP2_CONTINUATION_MEMO_UA.md).

| File | Content |
|---|---|
| `LP2A_CONTRACT.json` | The contract evidence a future GO_LP2A must pin (SHA-256 `ffcd126b…`). It holds 64 contract tests (41 negatives) plus WP1, mesh and closure rows, the token and digests |
| `LP2A_QUALIFICATION.json` | Preflight, policy / g2 / lp2 / parent digests, LP2 source lines, token, mesh scan by state, RAM observations |
| `LP2_S5_GEOMETRY.json` | WP1. Verification of the A0 S4 records and their bitwise equality with LP1, recurrence reproduction of S1–S4, the S5 candidates from A0 and from B9, S5 clearance metrics, kink gates and classification, and the hypothetical frozen-MTS and straight outlooks |
| `LP2_MESH_PROBE.json` | Unchanged mesher and audit on the four actual S5 candidates (4/4, 34/34) and on the last frozen-outlook polylines (synthetic) |
| `LP2_MESH_SCAN.json` | Vertex-count scan S6 … S20 on synthetic outlook polylines (MESH_ONLY_SYNTHETIC; never trajectories) |
| `LP2_1_S4_S5_UA.*`, `LP2_2_sitka_UA.*` | Ukrainian figures (`scripts/g2/lp2/g2_lp2_figures.m`) |
| `lp2a_qualify.m/.log`, `SANITIZATION.json` | The runner and log; original and sanitized hashes |

No mesh was saved and no boundary-value problem was solved; meshes were held in memory for auditing only.
