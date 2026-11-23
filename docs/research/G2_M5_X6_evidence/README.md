# M5-X6 qualification evidence (WP1, no FEM, no GO)

The qualification ran in the clean execution clone (`core.autocrlf=false`), detached at commit `2a5127e`; the clone was then restored to `16681cc`. Status `M5X6_PREFLIGHT_PASS_SCIENTIFIC_HOLD`.

| File | Content |
|---|---|
| `M5X6_CONTRACT.json` | The contract evidence a future `GO_M5_X6` must pin (SHA-256 `0d163d9a…`): 74/74 rows (61 contract tests, including 42 negatives, plus 4 diagonal audits, ring-area equality, 6 dry static checks, protected-tree and no-folder closure), `physicalSolves = 0`, token |
| `M5X6_QUALIFICATION.json` | Preflight, plan / A1 / X6 / mesh-manifest digests, X6 source lines, token, dry static checks of the six configurations, RAM observations, 910 protected files unchanged |
| `M5X6_DIAGONAL_AUDIT.json` | WP1.1: independent read-only audit of the four A1 B9 solutions (bytes, manifests, identities, 16/16 SIF criteria, mesh 19/19, frozen polyline, own-mask activation verifier, saved material, EDI recomputed bitwise from the saved u) |
| `M5X6_ARCHIVE_CHECK.json` | The local A1 archive `da0a1580…`: its SHA-256 and the eight B9 members, which equal the pins, the committed manifest and the clone. The off-device copy was not re-checked on 2026-11-23 (drive not attached) |
| `qual1.m/.log` | The exact runner and console log |
| `SANITIZATION.json` | Original and sanitized hashes (paths replaced by `<repo>`, `<scratch>`; MATLAB startup path warnings removed) |

No GO file exists. Nothing in this folder authorizes a physical calculation.
