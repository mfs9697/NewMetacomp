# Concurrent review reconciliation — no merge, no retrospective GO

During final publication the expected branch lease at `60358bbafb43a58458c7b37262956d8c21102800` failed. Inspection showed seven concurrent commits ending at `da877a760f0965b6b96b3905bb3a66c75cb26c9c` (tree `666bdb1f6391f6378c98377d87fa70274c4e211d`). The scientist's [review](https://github.com/mfs9697/NewMetacomp/pull/55#issuecomment-7079495852), created 22 November 2026 at 13:00 UTC, imposed HOLD pending a separate, SHA-bound GO.

This isolated checkout had already generated 20 S0–S4 physical states using local source commit `3dadf0d43aba0c5b2b3e8c69b90c2d42e89866f8`, whose tree is identical to remote `60358bbafb43a58458c7b37262956d8c21102800`. Its physical source-set SHA is `2e5756969e456043e48f048ecc12ebf0c76980b113296eb3903c79ac172cab00`. The separate GO guard was absent from that source, and no GO record existed. We do not claim these calculations satisfy the concurrent review's prospective authorization requirement, or that all calculations preceded the timestamp of that review. This discrepancy requires the scientist's disposition; numerical checks cannot substitute for it.

No physical solve or mesh was run after discovering this concurrent HOLD. The computed MATs, successful and failed logs, original source hashes and figures are preserved as evidence. They are neither deleted nor silently relabeled as results of the new guarded source. Their stored `REVIEW_STOP_LP1` strings are historical controller statuses. The present review package stops for review, while current physical execution remains `HOLD_LP1_PHYSICAL_AUTHORIZATION`.

## Preservation of the concurrent work

All five files changed by the seven concurrent commits were copied exactly and their Git blob SHAs verified:

- `matlab/g2/G2_LP1_PREPHYSICAL_REVIEW_20261122.md`
- `matlab/g2/check_g2_lp1_contract.m`
- `matlab/g2/g2_lp1_run.m`
- `matlab/g2/g2_lp1_scientific_gate.m`
- `scripts/g2/Invoke-G2LP1-PrephysicalBatch.ps1`

No concurrent file was overwritten by an older version. The delivery is appended as a normal child of the concurrent remote head, without a merge commit or force update. Earlier PRs and original source/policies/results remain unchanged. The orphaned upload-preparation commit `7f585c638636c39eef6341a3cadb11b29f284a9f` was not installed as the branch head and must not be used as the current implementation.

The current guard requires a separately reviewed GO and pinned contract evidence before Run=true, even for replay. No GO file is supplied. Consequently the original 20-state replay evidence applies only to its original source-set hash. The current default dry controller, pure tests, no-GO refusal and read-only saved-record audit can be exercised without bypassing the guard. Do not checkout older code to evade the current HOLD.

## Verification after preserving the guarded controller

The supplied Windows PowerShell 5.1 prephysical batch was executed on the clean combined source (`b276b7131934ae25dceee750630d504373ad5033`), with MATLAB R2023a/PDE, one engine and the unchanged >=5 GiB guard. Initial preflight passed at 5.380 GiB and geometry algebra passed 23/23; available RAM then dropped to 4.958122 GiB before the dry-case checks, so the actual batch stopped at HOLD_MEMORY. Its failed result, console log, runner and manifest are saved under `evidence/lp1_preflight/concurrent_review_20261122/`. There was no automatic batch retry, mesh or FEM. The four current dry cases and full controller no-GO-before-write probe remain incomplete. A separate small pure-contract run records the amended tests without requiring a mesh/FEM resource qualification; it is evidence only, not GO.

The separate amended pure suite passed **25/25**, including missing/mismatched GO, negative and record-integrity controls, with zero FEM/meshing. The overall prephysical batch still **failed HOLD_MEMORY**; passing pure tests does not clear it. The earlier 24/24 contract result remains explicitly tied to the source that computed the paths; it is not presented as the test count for the amended controller. Existing note `G2_LP1_PREPHYSICAL_REVIEW_20261122.md` is preserved as the original review record; its statement that MATLAB had not yet run is historical, superseded only by the separate new execution evidence.

Scientific questions: whether to accept these previously computed states as a retrospective bounded pilot; whether to require a prospectively authorized reproduction under the corrected controller; and whether the conservative soft2 result is sufficient for the intended report. None is decided by this implementation delivery. Canonical Word consolidation remains in Issue #53.
