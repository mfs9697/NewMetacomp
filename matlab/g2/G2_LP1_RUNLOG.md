# LP0/LP1 execution ledger — 22 November 2026

> **Concurrent-review disposition:** The remote branch acquired the investigator's [scientific HOLD](https://github.com/mfs9697/NewMetacomp/pull/55#issuecomment-7079495852) while this isolated checkout was calculating/reporting. The 20 stored states were computed with source set `2e5756969e456043e48f048ecc12ebf0c76980b113296eb3903c79ac172cab00`, before the separate GO guard was present in this checkout. They are numerically verified evidence **awaiting scientific disposition**, not a campaign authorized by the current guard. All concurrent safeguards are preserved; no GO record has been created. Current execution remains `HOLD_LP1_PHYSICAL_AUTHORIZATION`. `REVIEW_STOP_LP1` denotes delivery to review, not scientific acceptance or permission to continue. See [reconciliation](G2_LP1_CONCURRENT_REVIEW_RECONCILIATION.md).

All physical work used MATLAB R2023a (9.14.0.2206163), PDE Toolbox 3.10, Windows, the committed new policy and unchanged legacy source. Actual executable: `C:/Program Files/Polyspace/R2023a/bin/matlab.exe`. The launcher and its bin/win64 engine represent one MATLAB session; unknown executable paths remain conservatively counted.

## Ordered execution and failures

| Event | Outcome and evidence |
|---|---|
| Source reading | Issue #52, both PR #54 documents and Issue #50 review read before code changes; exact pinned Git ancestry reconstructed and verified |
| Environment-only observation | 2.9940 GiB available RAM, below 5 GiB. No mesher/FEM called; `initial_environment_probe.log`. This observation was not presented as a successful runtime preflight |
| Prospective LP0 commit | Local `8a19166528aad9be3d41f32bbfe3516719d436a6`; remote `67475b5c54e75814e455bc0089143d81f2786c70`; identical tree `a6880fdf6be73e437fe89be3a38284c9cc393ff6` |
| Algebra/preflight attempt 1 | 23/23 algebra passed; free RAM 5.8133 GiB but naive process count included Windows launcher and engine, giving HOLD_SOURCE before meshing. Preserved LP0 JSON/log |
| Documented process diagnosis | `G2_LP0_PREFLIGHT_INVESTIGATION.md`; exact matlabroot/bin launcher excluded, engine still counted. Committed `932cdc923d0b6c7703499d2c0106c556467c7c73`; no RAM/geometry gate lowered |
| Qualification attempt 2 | One engine, 5.8493 GiB; S0 bitwise 38/38+24/24, N5/N6 34/34, phase/all-mask/negative checks pass. No elasticity solve. `lp0_20261122/QUALIFICATION_ATTEMPT2.json` |
| LP1 enablement committed before solving | Local `3dadf0d43aba0c5b2b3e8c69b90c2d42e89866f8`; remote `60358bbafb43a58458c7b37262956d8c21102800`; identical tree `1cfe8f2dd175dd7051becb45aa90d35a6395e490`. v2 pins successful LP0 evidence |
| Contract suite | 24/24, no FEM. `LP1_CONTRACT.json`, `lp1_contract_and_H0.log` |
| H S0 deliberate interruption | One accepted solve saved to REVIEW, stop before STATE. `H_FIRST_ATTEMPT.json` |
| H S0–S2 | Promoted H S0 from verified REVIEW without solving it again; solved S1/S2. Prospective regression passes. `H_PREFIX.json`, `H_prefix.log` |
| Candidate S0–S2 | stiff13, soft2, soft1 each start from original S0 and their own signed K. Nine independent solves. `*_PREFIX.json`, `candidate_prefixes.log` |
| Bounded S3/S4 | After all four S2 records qualify: eight solves, all accepted. `*_FINAL.json`, `bounded_S3_S4.log` |
| Full replay | Five states reused per case, zero new solves/promotions. 182/182 file hashes unchanged. `REPLAY.json`, `RAW_RECORDS_SHA256.json` |
| First read-only report | MATLAB struct-array assembly error (dissimilar structures). No FEM; preserved `replay_and_report.log`. Fixed cell collection in exporter |
| First independent report-audit attempt | Empty-struct field initialization error. No FEM; preserved `evidence_audit_report2.log`. Fixed explicit fields |
| Independent evidence audit | 20/20 saved states, actual owner geometry and all q supports; 16/16 forged q margins rejected; no solves/remeshes. `INDEPENDENT_EVIDENCE_AUDIT.json`, `evidence_audit_report3.log` |
| Review of report semantics | Retained inherited M3 primary cross-mesh floor 1e-5 and separately exported raw spread. Added explicit pilot-limit labels; earlier report v2 remains in ignored diagnostic output, final v3 is canonical for this PR |
| Final preflight faults | From a clean positive baseline: shadowed only the OS-memory observation with 2 GiB; actual preflight returned HOLD_MEMORY. Removed shadow; positive baseline restored. Created one dirty sentinel; actual preflight returned HOLD_SOURCE; removed only sentinel; positive baseline restored. No large allocations, mesh or FEM. `PREFLIGHT_FAULTS.json` |
| Final report command launch | An initial shell path assumed Program Files/MATLAB and was absent; nothing launched. Retried using discovered `matlab` at Program Files/Polyspace. This is a command-path correction, not a numerical retry |
| Archive upload | Prepared upload helper failed at hosted tools/list DNS before any upload; local 50.39 MiB raw archive retained. No remote archive success claimed |

The inherited fixed-45-mm phase negative N7 does not reject S0 because that synthetic mutation does not reach a ring there. The wrapper records this outcome and requires the state-aware reaching-radius N7s mutation instead. The original generic log's `G2_MATERIAL_PHASE_NEGATIVES_PASS=0` on that control is not concealed and is not a physical gate bypass; the correct state-aware mutation and all owner/mask controls pass.

## Reproduction tolerances and result preservation

H S0 matches the archived result exactly. H S1: coordinate error 4.414240294e-6 mm, K error/Kref 6.293719306e-7, relative G error 1.340663114e-8, MTS difference 7.209983034e-5 degrees. H S2: coordinate error 4.414240294e-6 mm, K error/Kref 3.936802974e-8, relative G error 7.997673124e-8, MTS difference 4.379677931e-6 degrees. Limits were committed before calculations (1e-5 mm, 1e-5, 2e-5, 0.001 degree respectively).

The Cornell JSON's exact committed UTF-8/LF bytes hash to `179b777f4a26caf1482ad470d78f5f802bc24456b9a1b6fc6b641eccf2b66008`. Converting LF to CRLF reproduces historical Windows hash `45a88fa0926472ddbe5e70e4c80a97b88196dd45d8a266fa04273f89790b47bf`. No old expected hash or geometry was edited. Accepted MAT hashes are unchanged. The new source lock explicitly pins actual Git bytes.

Report-only functions and documentation were outside the physical computation source-set token. The original physical token matches every immutable campaign record. The subsequently preserved concurrent controller/test/GO-guard edits deliberately produce a different current source-set token: current code must not replay old records through Run=true or treat their provenance as its own. The final independent audit explicitly compares recorded clearance structures with a fresh oracle result. Runtime replay independently checks admissibility and all stored record links but does not itself compare every stored descriptive clearance metric; the additional final audit covers that reporting-integrity check.

GitHub connector transport gives commits different metadata/SHA from local commits but identical trees. The final PR head and tree are reported in PR metadata; physical records preserve their actual local computation commit. No history is rewritten. No earlier PR is merged or modified.

All final checks and archive member hashes appear in `FINAL_PRESERVATION_CHECK.json`. Stop: REVIEW_STOP_LP1.
