# G2: one additional middle-hole local Hface region — pre-registered experiment

**Status:** SOURCE PREPARED, NOT RUN IN MATLAB. Draft stacked on [PR #15](https://github.com/mfs9697/NewMetacomp/pull/15); do not merge, do not authorize LEFM or crack propagation.

## What the researcher's last MATLAB batch actually proved

2026-11-16, **20:45:10 Kyiv**, R2023a / PDE Toolbox 3.10, 10.66 GiB free memory:
`outputs/g2_specimen1_pencil/run_20261116_204510_663/`.

The **two-ring local hole refinement** used the Cornell original three true circular holes, but placed two *internal material partition guides*, each of outer radius `3R=19.05mm`, around lower hole #1 and upper hole #3; both had `Hface=1.5mm`. Original `Hmax=6mm`, `Hmin=.12mm`, `Hgrad=1.12`, lip `Hedge=.45mm` and channel half-width `.020mm`.

**ACTUAL MATLAB console:**
- `G2_LOCAL_CAD_FACE_PREFLIGHT_PASS=1`, `G2_LOCAL_CAD_FACE_IDS=[1 3]`, `G2_LOCAL_CAD_FACE_COUNT=3`: the two-ring partition worked.
- Native and collapsed minimum T3 angle **31.02994128°**, above fixed **20°** limit.
- Native and collapsed maximum adjacent-longest-edge ratio **1.81651696**, just over unchanged **1.8** limit.
- **One** violating interior edge of **31,676**. `G2_T3_SAME_FAILED_EDGE_IDS=1`: same source edge before/after collapse.
- The sole violation is now near **middle hole #2**, which was **not** refined: edge midpoint **(140.923535,127.039340)mm**, actual hole-wall distance **6.78517859mm** (approx 1.07R), T3 element IDs **16967,16968**.
- `HOLD_STAGE=HOLD_T3_QUALITY` — *not passed*. There is no independent T6/LEFM qualification.

| Actual mesh trial | Minimum T3 angle | Max T3 neighbor ratio | Bad native edges |
|---|---:|---:|---:|
| Global Hmax=6mm, no ring Hface | 26.26756357° | 2.25936462 | 19/27,520 |
| Hmax=6mm, lower+upper 3R annuli Hface=1.5mm | **31.02994128°** | **1.81651696** | **1/31,676** |

The worst location moved from the upper hole (#3) to the middle hole (#2). That suggests a **one-step addition** of middle-hole-local refinement rather than changing global parameters or relaxing the 1.8 acceptance gate.

## One new experimental factor

**Only intervention:** `IncludeMiddleHoleAnnulus=true`. The previous two rings, radius `3R`, face target `Hface=1.5mm`, global Hmax6, Hmin .12, Hgrad 1.12, lip Hedge .45, pencil w=.020, unchanged three physical circular holes, 40k T3 work budget and ALL existing T3/T6 bank gates are frozen. Middle hole receives precisely the same **3R material partition** and **1.5mm face target**. CSG must now produce exactly **four distinct material faces** (three annular faces and one bulk face), while **physical boundary components remain four** (outer boundary + three holes).

Analytical preconditions: centers of adjacent holes have 50.8mm pitch; two 3R guide circles have combined radius 38.10mm; therefore guide circles do not intersect (12.70mm clear between neighboring guide circumferences). Each guide is inside the plate and well clear of the bottom-edge starter crack. These checks are also in MATLAB source. Helper guide contours **are NOT extra holes**.

**No automatic retries or sweeps.** Failure to create 4 material faces = `HOLD_LOCAL_ANNULUS_PARTITION`. Native mesh below 40k T3 is required; failure of unchanged 1.8 ratio, 20° min angle, bank topology, T6 conversion or material area is still a HOLD.

### Run once on Windows PowerShell

Update/switch to the **stacked experimental branch**, then run:

```powershell
git fetch origin
git switch research/g2-three-hole-annulus-pilot-20261116
git pull --ff-only

powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_specimen1_pencil.ps1 -Hmax_mm 6 -LocalHoleAnnulusHface_mm 1.5 -IncludeMiddleHoleAnnulus -MinFreeGiB 7
```

The batch creates a new immutable timestamped output directory. On HOLD it preserves `batch_console.log`, `batch_summary.json`, the pre-collapse drawing if CAD/mesh reached it, plus `quality_forensics.json` and a local worst-edge zoom when quality forensics runs. Logs print `CONTROL_INCLUDE_MIDDLE_HOLE_ANNULUS=1`, `G2_LOCAL_CAD_FACE_COUNT`, face IDs, native/collapsed T3 stats and an explicit PASS/HOLD classification.

**Use full console output for review**, even if PowerShell reports exit status 1. The two obsolete MATLAB startup path warnings are unrelated.

### No premature mechanics

Even if the candidate reaches `CANDIDATE_TOPOLOGY_PASS`, the pilot still lacks the verified `EdgeCrackHoleLEFM` protected p010 crack-tip patch/collar and independent 21-gate whole-mesh T6 checker adapted to Cornell. Field `approvedForLEFM=false` remains mandatory; no K_I, K_II, J, G, COD, EDI, propagation or unknown experimental load/CMOD are inferred.

**This source branch is not MATLAB runtime evidence.** Retain the actual 20:45 two-ring HOLD unchanged.
