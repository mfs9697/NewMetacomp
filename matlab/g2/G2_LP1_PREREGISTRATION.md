# LP0 qualification and conditional LP1 preregistration — Issue #52

Date: 22 November 2026. Base: PR #54, `6bffd949e89d6f44fa46e0e606492f061886e461`.
This policy and the LP0 implementation are committed before any physical calculation.
The initial environment-only observation was R2023a / PDE 3.10 / 2.9940 GiB
available physical RAM. It did not build a mesh, extract K or solve elasticity.
The 5 GiB guard is unchanged. No automatic retry of a failed mesh or resource gate.

## Prospective sequence

1. Read-only preflight checks release, toolbox, exactly one MATLAB, clean committed
   checkout, RAM, the SHA of the source lock and every legacy/input file in that lock.
   Default `g2_lp0_qualify()` invokes only this preflight. It writes no file and
   calls no mesher or solver. In particular, do not use the inherited M4.A dry
   controller, whose absent-ROOT branch solves S0 before checking `Run`.
2. Small continuous-geometry algebra tests may run independently of meshing. They
   do not constitute mesher qualification. Diagnostic segments intentionally need
   not be legal 4-mm increments; state caps and MTS belong to the future controller.
3. Explicit tokenized `Mode='mesh'` is the only geometry-build route. Rebuild
   original famA S0, compare X3/T3/X6/T6/banks/q bitwise with its accepted MAT,
   require independent 38/38 and protected-tip 24/24. Map phases afresh and test
   H, stiff13, soft2, soft1 plus the ten inherited activation mutation controls.
4. Synthetic N=5 and N=6 polylines use the original S0 then successive 4-mm
   directions 12, 13, 14, 15 degrees clockwise from vertical, truncated to N.
   They are labelled MESH_ONLY_SYNTHETIC, never trajectories. Use unchanged
   `g2_kinked_join`, explicit ExpectedVertices=N and original famA options.
   Each must pass the full join, independent 34/34, 2788/128/2443 core/collar/q,
   64+64 seams, <=40000 T3, >=20 degrees and <=1.8 neighbour ratio. Re-map and
   independently verify all four masks on each resulting mesh. Abort on first
   failure; do not select another synthetic curve after inspecting failures.
5. LP1 physical execution remains disabled in this delivery unless LP0 is
   genuinely established. A dry-ready status is never permission to solve.
   Missing runtime evidence, source, baseline or qualified capability means
   HOLD_LP0_FEASIBILITY. No controller may infer GO from a hand-written boolean.

## Continuous geometric admissibility

The new oracle computes segment-to-every-edge distances and intersections for
closed annular and hole polygons, including endpoint inclusion, tangency and
collinearity. It also enforces the nominal circular envelopes, which conservatively
contain the chordal polygons. Polygon geometry and ring IDs are verified first.
Activity masks cannot disable a geometric obstacle. All previous crack segments
are checked; the shared adjacent endpoint is allowed but retracing/sharp miters
are rejected. A crack mouth on the original bottom edge is the sole boundary
exception for history, not an exception for the new segment.

The segment must clear nominal annuli by >1.52 mm (inherited channel half-width
0.02 plus guide-face size 1.5), nonadjacent crack segments by >0.16 mm, and plate
sides by >0.02 mm. Guide radius stays 15 mm; maximum q radius stays 2.6 mm plus
1 mm clearance. The collar radius stays 3.3 mm; earlier-crack collar clearance
includes channel half-width and one 64-sector rim chord. Tolerance is 1e-9 mm.
All simultaneous causes are retained, even when the primary status shows one.
Actual q support is checked separately by the all-node ring-owner verifier.
Geometric circle clearance alone is not proof of valid FE-nodal q support.

The current guide necessarily fails before a free-edge endpoint: top-tip y must
remain below 188.2 mm (strict margin). At an annulus the centre distance must
remain above 34.05 mm. These are scope limits, not predicted terminal path points
and not physical crack arrest. There is no adaptive step or boundary-breakthrough
method in this policy.

## LP1 contract, conditional and not yet implemented at a HOLD

Exactly H, stiff13, soft2, soft1; each starts at original S0 and solves its own
signed K. No frozen homogeneous S2 seed. Recompute full-precision tensile MTS
(relative stationarity residual <=1e-12), mesh, phase/owner verification, COD,
five-annulus EDI, 4x4/6x6 quadrature, J, energies and reactions at every state.
Use the exact inherited numerical thresholds copied into the policy, including
the signed low-mode-II reporting rules. At most S4 / 41.4 mm / four 4-mm steps.

H S1/S2 regress to saved full-precision historical references. Coordinate
tolerance 1e-5 mm, K error/hypot(KI,KII) <=1e-5, relative G <=2e-5 and MTS
<=0.001 degree are fixed before calculations. The existing M4 preregistration
documents a 4.41e-6 mm historical S1 offset from its six-digit seed, so bytewise
agreement of a new full-precision path is not assumed. Never modify the reference.

Before enabling physical execution, the new controller must demonstrate source,
policy, case, geometry, state-cap and parent-K token checks, write-review-before-
state ordering, file tamper rejection, interruption/replay without re-solving,
wrong-mask rejection, S5 rejection and a clean-tree/resource guard. These tests
are BLOCKED, not passed, if LP0 stops. Historical restart tests are not credited
as tests of a new LP1 controller.

Report U_primary, U_cons and observed R1 cross-family drift separately; shared
p010 support prevents a full mesh-convergence interpretation. Raw nodal compliance
is point-load-sensitive; that explanation is plausible rather than uniquely
demonstrated. Ukrainian greyscale figures must distinguish synthetic qualification
geometry from calculated trajectories. No trajectory/SIF/energy chart is created
without accepted numerical states. Issue #53 retains canonical Word consolidation.

Terminal: REVIEW_STOP_LP1 only after the conditional physical pilot; otherwise
an evidenced HOLD_LP0_FEASIBILITY. No LP2, S5, interface fracture, CZM, optimization,
physical onset/arrest claims or merges.
