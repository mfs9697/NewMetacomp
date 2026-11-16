# Cornell specimen #1 — isolated **regular p010** geometry block (P0)

**Research status:** **SOURCE-READY, MATLAB UNVERIFIED**. This draft is stacked on [PR #18](https://github.com/mfs9697/NewMetacomp/pull/18) and transfers the **original frozen p010** patch into the Cornell research workspace without changing the existing accepted outer mesh or the 38/38 independent checker. **No physical LEFM, no crack propagation, no global p010 join.**

## Why this now

User's actual MATLAB R2023a success on 2026-11-16:
- [PR #16](https://github.com/mfs9697/NewMetacomp/pull/16), Cornell geometry-only three-hole candidate; 23,207 T3 cells, 47,245 T6 nodes; min angle **33.63741002°**, max adjacent ratio **1.62557238**, 0/34,394 quality violations.
- [PR #17](https://github.com/mfs9697/NewMetacomp/pull/17), user's **independently executed T6 audit PASS 38/38**, exact four boundary loops, Euler -2, one tip, verified original inputs.
- The current accepted candidate deliberately lacks protected p010. **Geometry accepted** does not mean **LEFM admissible**.

## Provenance: byte-for-byte pinned source

Source commit: [`mfs9697/EdgeCrackHoleLEFM@a14d8872ab588ac551e41b4531bffee2dcd0ce2c`](https://github.com/mfs9697/EdgeCrackHoleLEFM/tree/a14d8872ab588ac551e41b4531bffee2dcd0ce2c).

Six source MATLAB files were **copied with EXACT Git blob SHA-1 equality** into `matlab/g2/vendor_p010_a14d8872/`. GitHub's actual destination file blobs were checked against the originals:

| Unmodified upstream file | Verified Git blob SHA-1 |
|---|---|
| `build_m1i_trial_tip_annulus_p010.m` | `9440ceda09609b4bcbb4bc7da2874f9fffde62b1` |
| `build_m1i_trial_tip_disk_p010.m` | `877aa59c8d6cadc0987c791e1d13204f98125d7e` |
| `build_twohole_literal_annulus.m` | `16b2045836f548bbc38eea944663a9eb09a5eec3` |
| `cut_twohole_literal_annulus.m` | `bfdd4418193da5792e28e07562fffa46bfab8196` |
| `T3toT6_fast.m` | `29bf9d8e233b24d70cdc81e392f8b24e239c1afa` |
| `main_m1i_increment_ring_geometry_only.m` | `40fbc6b2e4f35299f773fc14736961d4136a7bf7` |

The launcher checks these **committed blobs** and refuses dirty working-tree modifications. It also verifies the **original Cornell source JSON SHA256** `45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF` (observed in author's successful runs). The old source function itself contains **TWO-HOLE, OLD-PLATE CLEARANCE CHECKS**, so 15/15 from that source **cannot certify Cornell**: our Cornell-specific clearances are separate and mandatory.

## P0 geometry (NO crack growth)

Cornell plate `[0,508]×[0,203.2]mm`, three actual holes `(152.4,69.85/120.65/171.45)mm`, radius 6.35mm. The physical starter tip remains `(101.6,25.4)mm`, tangent **straight upward**.

To instantiate the frozen original 4mm-increment-oriented p010 source **without adding a physical increment**, create only a **construction** prior tip `(101.6,21.4)mm` along the existing crack, then invoke the original unmodified local source with `Delta_mm=4`, `Turn_deg=0`. Its returned physical tip is the **same original Cornell** `(101.6,25.4)mm`. This is not a propagated crack.

- **p010 protected structured disk + annulus:** frozen 2,788 T3 cells, 64 sectors, 3mm radius, first T3 tip edge ~0.041667mm.
- **Analytic collar:** additional **128 T3**, 0.3mm radial thickness, outer radius **3.3mm**, exact separate upper/lower entry vertices, 64 interior seam edges with two owners and 64 unjoined outer-rim edges with one owner.
- **Total isolated regular block:** predicted **2,916 T3**. New T6 is computed from this isolated block and has unique midpoints; no exterior triangles are included yet. T3 ≤20° angle and adjacent ratio ≥1.8 are **not tolerated**: actual gates require min angle **≥20°**, max adjacent longest-edge ratio **≤1.8**, positive areas and correct inner/outer seam owners.
- **Independent Cornell geometry controls:** the 3 original physical hole walls, 3 nonphysical 3R material sizing-guide contours, and all 4 outer plate sides must be outside the 3.3mm collar. The last existing starter-crack segment before the tip must be longer than the collar radius (we use 4mm of existing crack, NOT growth).
- **FE-nodal q:** original proposed radii 0.4–2.6mm, variation determined on all six T6 nodes, support contained strictly within the 3mm p010 polygonal inradius and **2,443 active original p010-parent T6 cells**. Its calculation remains **geometry-only**; NO EDI integration is performed.
- Strict **no p010 global LEFM qualification** regardless of isolated block gates.

### One MATLAB R2023a PowerShell batch

Run **from repository root** on the new branch, with no MATLAB-only manual steps:

```powershell
git fetch origin
git switch research/g2-p010-isolated-kernel-20261116
git pull --ff-only

powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_p010_isolated.ps1
```

Requires MATLAB R2023a and at least 5GiB free physical RAM. It calls no PDE Toolbox (the original vendor code also avoids PDE for the isolated core). Each run creates a new immutable evidence folder under:

```text
outputs/g2_p010_isolated/run_YYYYMMDD_HHMMSS_FFF/
  batch_console.log
  p010_isolated_summary.json
  p010_regular_core_and_collar.png
  p010_regular_core_and_collar.pdf
  p010_inner_tip_zoom.png
  p010_inner_tip_zoom.pdf
  P010_ISOLATED_REGULAR_ONLY.mat   [ONLY if all isolated checks PASS]
```

The two real MATLAB figures show (1) the complete 3mm regular kernel + 0.3mm collar with 2.6mm proposed q support radius, and (2) the innermost protected crack-tip lattice; both are **actual MATLAB T3 plots of the generated arrays**. The MAT contains frozen-source data and the isolated p010/collar T3/T6 arrays for a future conforming global join. On HOLD, the JSON and console remain with an explicit rejected stage. The original Cornell candidate MAT and 38/38 evidence are never modified.

## Next guarded stage (NOT implemented here)

**P1: conforming global protected mesh**. Regenerate the CURRENT 3-hole/3-annular Hface exterior, replacing its native pencil apex by 64-segment **3.3mm outer-rim CAD boundary** with 65 distinct bank end source nodes; then join the isolated p010 2,788-element patch and 128-element collar so **64+64 seams have exactly two owners**, the three true physical circles and four physical boundary components remain valid, and every interior T3/T6 quality gate still passes. The old non-p010 candidate's 38/38 is **not automatically transferred** to a changed mesh.

**Status:** copied sources verified by Git blob equality, implementation statically inspected. **No MATLAB P0 test has been run** and **no numerical P0 success** is claimed. The next real evidence must come from the local batch. No PR merge.
