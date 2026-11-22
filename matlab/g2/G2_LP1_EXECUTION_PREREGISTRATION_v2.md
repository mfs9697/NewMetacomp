# Conditional LP1 execution preregistration v2

The original v1 policy and preregistration remain immutable. Version 2 enables
the bounded physical controller only after the committed LP0 evidence pin:
`b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5`.
S0 rebuilt bitwise; N5 and N6 passed 34/34, original mesh quality and all four
independent masks. T3 counts: S0 28151, N5 28817, N6 29063. These are synthetic
qualification results, not crack trajectories. No physical solve preceded v2.

No numerical/geometry/resource threshold changes. `g2_lp1_run` defaults to a
read-only preflight. Each case uses SHA-verified original S0 mesh, an independent
material-specific solve, and full-precision signed MTS at each parent. The
physical solver is the unchanged partial-activation SIF module. The new controller
does not use inherited M3/M4 dry controllers or seed from homogeneous S2.

Order: H S0-S2; stiff13, soft2, soft1 S0-S2; only after all four qualify may any
S3/S4 be attempted. Every state is saved, independently re-audited and re-mapped
before elasticity. Independent mask controls remain mandatory at every state.
Source/policy/LP0/case/cap tokens, immutable byte manifests, semantic parent/K/
geometry/phase cross-links and review-before-state records guard replay.
HOLD and partial unreviewed states are never silently retried. An explicit
interruption after REVIEW permits promotion without FEM only after verification.

Pure contract negatives precede physical execution. Actual replay/interruption
controls use accepted saved states; they do not authorize extra physical solves.
If any required gate or integrity control fails, preserve the failed record and
stop the affected chain; do not change tolerances to obtain a path.

## Byte provenance

The isolated checkout preserves exact committed Git file bytes (UTF-8/LF).
Historical Windows working copies used CRLF for some inputs. The Cornell JSON
has committed-byte SHA `179b777f4a26caf1482ad470d78f5f802bc24456b9a1b6fc6b641eccf2b66008`;
historical policy pin `45a88fa0926472ddbe5e70e4c80a97b88196dd45d8a266fa04273f89790b47bf`
is retained unchanged. LP0 source lock records actual committed bytes, and all
accepted MAT byte hashes are unchanged. This representation difference is not
a change to nominal geometry; the independent S0 bitwise-array regression is
additional numerical evidence. Transport through the GitHub connector may change
commit metadata but must reproduce the local Git tree exactly; both SHAs and
the matching tree are recorded in the final provenance mapping.

All original uncertainty, compliance, conditional-growth, Ukrainian greyscale
and Word/Issue #53 restrictions remain as in v1. Terminal REVIEW_STOP_LP1 or an
evidenced numerical HOLD; no S5/full paths/interface fracture/CZM/optimization.
