# G2-LP0/LP1 — independent scientist review and pre-physical correction ledger

**Date:** 2026-11-22. **Issue:** #52. **Draft implementation:** PR #55 stacked on PR #54.
**Review:** https://github.com/mfs9697/NewMetacomp/pull/55#issuecomment-7079495852

## Decision

**HOLD_LP1_PHYSICAL_AUTHORIZATION.** LP0 geometry qualification may be evaluated scientifically; it is **not** a GO for LP1 physical solves. The original LP0 `QUALIFICATION_ATTEMPT2.json` states `LP0_GEOMETRY_QUALIFIED_REVIEW_REQUIRED`, includes three geometry mesh builds and **zero FEM solves**. S0, N5 and N6 results are synthetic geometry/phase qualification, **not** propagated trajectories.

This correction pass intentionally preserves v1 and v2 policy/preregistration files, all previously recorded source and MAT evidence, and older PR heads. The v2 policy's `physicalEnabled=true` field alone no longer enables the controller: a **separate, absent-by-default** SHA-bound scientific GO record is now mandatory. No such GO record is supplied in this branch.

## New, fail-closed prospective gate

`g2_lp1_run(...,'Run',true,...)` now invokes `g2_lp1_scientific_gate` before a run directory, geometry build or FEM solve. The only possible scientific release is a **new** file `matlab/g2/G2_LP1_SCIENTIFIC_GO_v1.json`, created *after* the investigator signs off. Its required fields are:

- `decision=GO_LP1_PHYSICAL` and `reviewStatus=REVIEWED_ACCEPTED`;
- nonempty `scientificReviewer`, exact GitHub `reviewURL`;
- `approvedPolicySHA256`, `approvedSourceSHA256`, `approvedLP0SHA256`, `approvedToken` matching the read-only runtime context;
- `contractEvidenceFile` under `matlab/g2/evidence/lp1_preflight/` and its `contractEvidenceSHA256`, with a file recording passing pure contract tests and zero FEM/mesh builds.

Do **not** create a dummy GO or hand-edit the source/policy/LP0 digest to make these checks pass. If the review declines permission, retain HOLD and report scientific questions instead.

## Code corrections in this pass

1. Enforce an independent scientific GO as well as the pre-existing authorization token. A token produced by a dry preflight is not approval.
2. Before any material-contrast configuration, require a saved, integrity-checked homogeneous H S2 state. Before S3/S4, require all four S2 state records and reject altered/held records.
3. Preserve the exact continuous-clearance oracle `HOLD_*` identifier in errors, plus a saved `stopCode`, all geometric reasons, and clearance metrics in the HOLD record. Never use the generic `HOLD_GEOMETRY` as a substitute for `HOLD_INTERFACE_APPROACH`, `HOLD_Q_PHASE`, `HOLD_TIP_GUIDE`, `HOLD_CRACK_SELF_INTERSECTION` or `HOLD_EXTERNAL_BOUNDARY`.
4. A single completed case returns `CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW`, **not** `REVIEW_STOP_LP1`. Only a separately reviewed four-case campaign audit may issue that terminal scientific classification.
5. Extend the pure contract test with a rejection case for absent/mismatched scientific GO and explicit negative-/record-integrity test fields for future saved evidence.

## Tests and remaining gates (NO claim of execution)

This pass involved **GitHub source edits and static source inspection only**. MATLAB R2023a/PDE was not available for execution in the assistant runtime. The modified code and updated `check_g2_lp1_contract` **have not been run**, and no post-correction MATLAB test log or physical trajectory exists.

Before a scientist can authorize `Run=true`, independently verify and commit:

1. A clean commit/source lock, exact retained S0/N5/N6 LP0 SHA evidence, and the read-only preflight with >=5 GiB available RAM and exactly one MATLAB engine.
2. MATLAB execution of `check_g2_lp0_clearance` and `check_g2_lp1_contract` with every negative, tamper and immutable-record control passing; keep both stdout and a SHA-pinned structured result. Inspect specific failure identifiers, not only a blanket pass boolean.
3. Read-only/dry `g2_lp1_run` for all four named cases; check that `Run=true` cannot reach file creation, meshing or a physical solve without a separate GO (even when supplied with the dry token).
4. Independent audit of the v2 source-set digest, retained source lock and all relevant archived MAT input identities. Make sure source edits have not affected accepted legacy evidence.
5. A signed scientific decision recorded in PR #55 (or a new scientific review issue), **then** a prospectively committed explicit GO record matching that *reviewed* code and evidence. The investigator may instead retain HOLD.

**After (not before) approval:** H S0–S2 first with signed SIF and full H regression; then stiff13, soft2 and soft1 each from own S0 to S2; only if all four qualify allow at most S3 and S4. Preserve physical HOLDs, replay/interruption evidence and an independent four-case campaign review. No S5, LP2, interface crossing, delamination, CZM, automatic retry, physical arrest conclusion or merging older PRs.
