# G2 LP0/LP1 results — REVIEW_STOP_LP1

> **Concurrent-review disposition:** The remote branch acquired the investigator's [scientific HOLD](https://github.com/mfs9697/NewMetacomp/pull/55#issuecomment-7079495852) while this isolated checkout was calculating/reporting. The 20 stored states were computed with source set `2e5756969e456043e48f048ecc12ebf0c76980b113296eb3903c79ac172cab00`, before the separate GO guard was present in this checkout. They are numerically verified evidence **awaiting scientific disposition**, not a campaign authorized by the current guard. All concurrent safeguards are preserved; no GO record has been created. Current execution remains `HOLD_LP1_PHYSICAL_AUTHORIZATION`. `REVIEW_STOP_LP1` denotes delivery to review, not scientific acceptance or permission to continue. See [reconciliation](G2_LP1_CONCURRENT_REVIEW_RECONCILIATION.md).

Issue #52; draft [PR #55](https://github.com/mfs9697/NewMetacomp/pull/55), stacked on PR #54 at `6bffd949e89d6f44fa46e0e606492f061886e461`. Exactly four independent own-S0 paths reached S4, s=41.4 mm. Twenty elasticity solves, sixteen new physical-path meshes, no S5, no physical HOLD and no merge. Scientific acceptance remains pending review.

## Review entry points

- [Insertion-ready Ukrainian review and numbered tables/captions](../../reports/G2/LP1_20261122_v3/SCIENTIFIC_REVIEW_UA.md).
- [Full-precision per-state CSV](../../reports/G2/LP1_20261122_v3/LP1_COMPARISON.csv), [JSON including vertices and record links](../../reports/G2/LP1_20261122_v3/LP1_COMPARISON.json), [SIF/energy diagnostics](../../reports/G2/LP1_20261122_v3/LP1_SIF_ENERGY_DIAGNOSTICS.json).
- Six greyscale vector PDFs and 450-dpi PNGs beside those tables. All figure text is Ukrainian; figure captions are in the Ukrainian review. All six final figures visually checked for glyphs, clipping, distinct markers and geometry aspect. The figures mark the pilot limit, not a physical arrest.
- [Run log](G2_LP1_RUNLOG.md), [reproduction commands](G2_LP1_REPRODUCE.md), [evidence](evidence/lp1_20261122/).

## Mandatory feasibility

S0 reproduced bitwise (28151 T3), 38/38 independent geometry and 24/24 protected-tip checks. Synthetic N5/N6 complete banks and meshes passed 34/34 each, all four masks and 10/10 activation mutation controls per mesh. N5=28817 and N6=29063 T3; minimum angle 30.12684732 degrees, maximum neighbour ratio 1.59182855. Protected 2788/128/2443 core/collar/q counts remain unchanged. Continuous segment/closed-polygon and circular-envelope tests: 23/23. These are mesh-only synthetic probes, not physical paths.

| Architecture | LP0 full geometry/owner/mask | Own S0 solve | Accepted terminal |
|---|---|---|---|
| H | PASS | independent | S4, 41.4 mm |
| stiff13 | PASS | independent | S4, 41.4 mm |
| soft2 | PASS | independent | S4, 41.4 mm |
| soft1 | PASS | independent | S4, 41.4 mm |

## Results at S4

| Розподіл | x, мм | y, мм | КІН I, МПа√м/кН | КІН II, МПа√м/кН | G при 1 Н, Н/мм | Зміна G, % | Поперечне зміщення, мм |
|---|---:|---:|---:|---:|---:|---:|---:|
| Однорідний матеріал | 105.647460055 | 40.872016664 | 0.224242670 | +0.003190841 | 1.5389592037e-08 | +0.000000 | +0.000000000 |
| Жорсткі кільця {1,3} | 105.831993105 | 40.822607978 | 0.216052411 | +0.002927408 | 1.4285670500e-08 | -7.173170 | -0.190901981 |
| М’яке кільце {2} | 105.729743122 | 40.849850321 | 0.220930036 | +0.003212524 | 1.4938397603e-08 | -2.931815 | -0.085162711 |
| М’яке кільце {1} | 105.350582326 | 40.946568796 | 0.231227276 | +0.003469718 | 1.6363589482e-08 | +6.328936 | +0.305671429 |

Stiff13 shields while moving toward the nominal rings; soft1 amplifies while moving away. Soft2 gives modest ringward steering. Its -2.931815% G difference is unresolved under U_cons=3.397543 percentage points, and its lateral offset is also unresolved under the cautious |d|>2U_cons,d comparison. Stiff13 and soft1 are resolved under both reported estimator conventions. No R_path/R_total decomposition is claimed for different evolving geometries.

The primary energy uncertainty includes the inherited M3 1e-5 cross-mesh reference floor; raw paired estimator agreement is separately exported. R1 observed fixed-S2 family drift is reported separately, not substituted for new path convergence. The first-order angle-to-position uncertainty is a diagnostic, not a certified remeshing bound. See the Ukrainian review for exact formulas and thresholds.

## Verification and preservation

Pure new-contract tests 24/24; saved-state independent audit 20/20; forged q-clearance refusals 16/16; actual preflight rejects injected 2 GiB and a dirty source from a clean positive baseline. Byte tamper, wrong case/mask, altered parent signed K, source/policy, unit drift and S5 are rejected. H S0 interruption after REVIEW was promoted with zero repeated S0 solve. Full replay reused 20 states with zero solves/remeshes; all 182 campaign files stayed byte-identical.

All 689 historical source/evidence files and 654 accepted MAT inputs still match the source lock. No inherited module, policy, earlier result or Word file is modified. H S1/S2 reproduction stayed within prospective tolerances; maximum coordinate error 4.414240294e-6 mm reflects the previously documented six-digit historical seed.

No threshold was reduced. LP0 initial resource and process-count observations, all expected negatives, and two read-only reporting errors are retained in the run log. No scientific failure was replaced by a favourable mesh.

## Raw record availability

`NewMetacomp_G2_LP1_Raw_Records_20261122.zip`: 52837630 bytes, SHA256 `5b333b03e37f08a0c6de839cb646f8c72ea474ba547ba04022ed213059f3c533`. It contains the complete 182-file campaign, including mesh, phase, solution, REVIEW, STATE and manifests. Restore beneath `outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1/` using the supplied restore script. Archive members were independently checked against the committed raw-record SHA ledger.

The archive is retained locally alongside this checkout. The attempted persistent archive upload failed before upload because the upload helper could not resolve its hosted tools endpoint (DNS). It is not claimed as a remotely published archive. Source, numerical tables, diagnostics, logs, checksums and figures are published in the draft PR. Historical MAT inputs remain in the investigator's accepted worktree and can be restored only after hash verification.

## Research gate

`REVIEW_STOP_LP1`. Conditional directions only: no toughness/onset/stability/arrest inference, no interface propagation, no full-length path or external breakthrough. Word v0.4.1 consolidation remains in Issue #53. No computation beyond S4 is authorized by this package.
