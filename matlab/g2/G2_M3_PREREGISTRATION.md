# G2-M3 independently evolved soft and stiff crack paths: preregistration (Issue #39)

**Status:** committed before any material-specific increment, and before the read-only preflight that reads the S0 material forecasts. The machine-readable contract is `G2_M3_TRAJECTORY_POLICY_v1.json` (same commit).

Unchanged and reused read-only: PR #38 (`49ec4fc`), the policies `G2_TRAJECTORY_POLICY_v1` / `G2_MATERIAL_POLICY_v1` / `G2_M2_POLICY_v1`, the homogeneous chain, and the PR #35–#38 modules.

## 1. Question

If the crack follows its own material-specific numerical MTS path, does that path change the elastic driving force beyond the direct material effect already measured on the frozen homogeneous path?

At matched arclength s = 25.4, 29.4 and 33.4 mm:

| Quantity | Definition |
|---|---|
| R_direct | G_M[Γ_H] / G_H[Γ_H] (PR #38 records) |
| R_path | G_M[Γ_M] / G_M[Γ_H] |
| R_total | G_M[Γ_M] / G_H[Γ_H] = R_direct · R_path |

**Scope of the paths.** These are numerical paths conditional on assumed 4 mm advances, under the idealized 1 N pin/roller BVP with illustrative moduli. They are not physical growth, onset or arrest. This is a phase-only path-feedback decomposition on the same perforated plate, not the hole-versus-no-hole G2 decomposition.

## 2. Paths

- **H (homogeneous):** the existing qualified S0 → S1 → S2, read-only.
- **soft (E_r/E_m = 0.5) and stiff (2):** separate chains `outputs/g2_material_trajectories_v1/chain_<material>_v1`, each from the WP2 straight crack (101.6, 0) → (101.6, 25.4) mm.
  - **ROOT.** It holds the PR #38 S0 material record (`cd506779…` soft, `052bcee4…` stiff, checked against the M2 ledger). The S0 material solve is **recomputed and must equal the record bitwise**.
  - **Steps.** Two steps, M1 (s = 29.4 mm) and M2 (33.4 mm). Each turn comes from that chain's own parent K, using the recurrence of `g2_trajectory_run` exactly.
  - **No homogeneous seeding.** No homogeneous K or geometry is used to seed a material step.

**Read-only control H-REC (no FEM).** Applying the same recurrence to the PR #38 S0 H1 record must reproduce the homogeneous S1 polyline; applying it to the S1 H1 record must reproduce the S2 polyline. Tolerance: 1e−9 mm against the preregistered 10-decimal polylines, and exactly against the saved polylines.

## 3. Per-step gates (unchanged thresholds)

For each step, in order, with a HOLD stopping that chain:

1. MTS status OK; K1–K10 (`g2_kink_admissibility`); arc ≤ 33.4 mm; step ≤ 2.
2. A new mesh from `g2_kinked_join` with the PR #32 exterior options:
   - ≤ 40,000 T3, min angle ≥ 20°, ratio ≤ 1.8;
   - p010 2,788 + 128, 64+64 seams, 2,443 q-active parents;
   - an independent 34/34 audit of the **saved** arrays.
3. A new phase map on that mesh (mapper, separate verifier, state-aware negatives). Chord counts, band areas, tip-to-band distance and q clearance are recorded. No labels are reused from any other mesh.
4. A new two-phase T6 solve (`g2_material_sif_on_mesh`, unchanged), with every inherited SIF, q-phase, energy and interface gate.
5. The SOLUTION and REVIEW records, then the STATE record.

**Reuse.** A REVIEW or STATE is reused, or a REVIEW promoted, only after all of these are re-verified without FEM:
- forecast equality, parent and source hashes;
- mesh hash and content, and the 34/34 re-audit;
- re-map and verify of the saved phase labels.

This guards against the historical forged-review defect D2.

**Authorization.** The default is dry and writes nothing. `-Run` needs the token `G2M3RUN|<policy SHA>|<material>|maxState=2`. A step-3 request is refused. A chain containing a HOLD record is never reused; a retry needs a new chain folder and a committed investigation.

## 4. Uncertainty and resolution (fixed now)

**Ratios.**
- **Primary rule.** U = max(contour spread, 4×4, COD), and for cross-mesh ratios (R_path, R_total at s > 25.4) also U_mesh. U_mesh = |G_H1(S2alt)/G_H1(S2) − 1| from PR #38, the G difference between two independent meshes at identical geometry. Resolved iff |R − 1| > 2U and the COD ratio has the same sign.
- **Conservative rule.** R·(δG_a + δG_b). It is reported and classified alongside the primary verdict.

**Path separation.** At s = 29.4 and 33.4 mm:
- Reported: the tip separation |tip_M − tip_H|, the signed lateral offset along the H terminal normal, and the maximum separation of the full polylines at equal arclength.
- U_sep(29.4) = 4 mm · U_Δθ0, and U_sep(33.4) = 8 · U_Δθ0 + 4 · U_Δθ1. U_Δθ is the estimator uncertainty of θ_M − θ_H at the matched parents, defined as for Δθ in PR #38.
- Resolved iff the separation exceeds 2·U_sep.
- The conservative variant uses |θ_EDI − θ_COD| of both paths, added.
- A nonzero separation alone is not "resolved".

**Angles.** Local MTS angles are compared only within one state's frame. Global terminal tangents are reported separately.

## 5. Robustness (one preregistered check per material)

- **Check.** At each material's M2 geometry, one alternative mesh: the same exterior options plus GuideHface 1.0 and Hmax 5, as for the PR #38 S2alt. All gates apply.
- **Comparison.** R_path,alt = G_M,alt[Γ_M2] / G_M,S2alt[Γ_H]. Both come from the alternative mesh family; the second is the PR #38 S2alt record.
- **Classes:**
  - ROBUST: same sign, and |δR_path,alt − δR_path| ≤ 0.25·|δR_path| + 2·U_mesh;
  - SENSITIVE: same sign, larger difference;
  - NOT_ROBUST: opposite sign.
- **Not checked by mesh:** path separation. It is a single-mesh-family numerical observation.

## 6. Comparability, faults, outputs

- **Comparability.** Each new mesh is geometry-equivalent iff it has 3×76 chords and its band area is within 1e−4 of S2. Otherwise it is flagged.
- **Faults and restarts, on disposable copies.** Each must be refused or handled safely without new FEM:
  - a forged review with another material's or step's mesh;
  - inconsistent phase labels;
  - a switched material id;
  - policy or source drift;
  - a wrong parent hash or parent K;
  - swapped banks;
  - a bad segment;
  - a step-3 request;
  - interrupts after review and after state;
  - a tampered state;
  - a dirty source;
  - a dry-mode write check.

  A deterministic replay of a full chain must equal the accepted chain in all arrays.
- **Outputs.** Under `outputs/g2_material_trajectories_v1/` (gitignored), with sanitized logs, CSV/JSON/PNG and SHA-256 ledgers committed. Results go in `G2_M3_RESULTS.md`.
- **Excluded:** a third increment, State 3, CZM, debonding, onset, toughness, arrest, experimental match, any threshold relaxation, and automatic retries.
