# Chapter 6 — M4.B / R1 / G1 evidence
Source 923ef406349d75c5d7f7ed77f954cf36614b272d; scientific reviews PR #51 and #69 (SR0_REVIEW_SNAPSHOTS.json). All 16 logical cases (15 different distributions), 12 subset solves from original campaign; no new FEM.
- matlab/g2/evidence/m4b_20261121/analysis/cases_16_logical.csv
- matlab/g2/evidence/m4b_20261121/analysis/decomposition.csv
- docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json
- matlab/g2/G2_M4B_RESULTS.md, G2_M4B_R1_RESULTS.md; docs/research/G2_G1_FIELD_INVESTIGATION_UA.md; scripts/g2/m5/g1/g1_field_analysis.m and g1_figures.m.
- Recomputed 40 Möbius/Shapley coefficients from rounded CSV, max absolute difference 2.9999891459908667e-12 (fraction or degree). CSV source and derived values included. G1 homogeneous energy series extracted as per-thickness N (N mm/mm). b FD=[0.05958583554498579,-0.04872300608884557,0.0304966977582073], growth percent=[26.33694949933869,-18.985794031073453,9.186664377951281], signs=21/21, ratios=0.6829782449894896..1.2580499494206896. Not independent trials.
- Betti identity and first-order sensitivity derived in report; shape derivative vs finite differences along changing paths distinguished; no guaranteed error bound, no second-order coefficient measurement. Corrected original G1 assertion of biaxial compression: mean tensor principal stresses ring2 +1.92 and −3.81 ×10^-4 MPa. G1 PARTIALLY_SUPPORTED, no causal strut claim. P4 later failed for stiff13 and soft1, addressed in Ch7. R1 did not repeat interactions or all pairs. soft2 frozen S2 both criteria; not same as own-path conservative classification.
- Original G1-1..5 used, F06_1 and R1 fields/masks/decomp used; F06_2 and local-scale R1 stress alternative archived in figures but not included (redundancy and different scale). Actual visual check not done here.

| Figure | Original path | SHA-1 | Bytes |
|---|---|---|---:|
| G1_1_napriamy_stysku_UA.pdf | docs/research/G2_G1_evidence/G1_1_napriamy_stysku_UA.pdf | e4af7c3853e663362f7d4981904cdafe1606ab3b | 129933 |
| G1_2_gustyna_energii_UA.pdf | docs/research/G2_G1_evidence/G1_2_gustyna_energii_UA.pdf | 50a18b28566874a52efca6824cda280f7cf238a7 | 438482 |
| G1_3_pererozpodil_energii_UA.pdf | docs/research/G2_G1_evidence/G1_3_pererozpodil_energii_UA.pdf | 177865cf3005fdc908986eeea57f08f78ceaf277 | 721781 |
| G1_4_karta_vplyvu_UA.pdf | docs/research/G2_G1_evidence/G1_4_karta_vplyvu_UA.pdf | 7ef6ff78fd65373eaecbdd6a1ee901217a7f715f | 114568 |
| G1_5_energii_kilets_UA.pdf | docs/research/G2_G1_evidence/G1_5_energii_kilets_UA.pdf | 54ed76bb278ffd2f8f21b9f414351a9b7d5bed3c | 43451 |
| F06_1_vnesky_kilets.pdf | reports/G2/preliminary_20261125/figures/F06_1_vnesky_kilets.pdf | 8c108d938f4f60bf8102a318488992aaaa6f003b | 43254 |
| F06_2_enerhii_kilets.pdf | reports/G2/preliminary_20261125/figures/F06_2_enerhii_kilets.pdf | 8e0b5d27b249b7679b438b35e7f602f811168550 | 48543 |
| r1_g3_equal_area_grey.png | matlab/g2/evidence/m4b_r1_20261121/report/r1_g3_equal_area_grey.png | 39ae62de1d2f74b2c57c35fb9021852b2d62e992 | 119328 |
| r1_g4_stress_global_grey.png | matlab/g2/evidence/m4b_r1_20261121/report/r1_g4_stress_global_grey.png | 40453ad00f71e74ae2cdb07031c37391ce512dc3 | 568874 |
| r1_g4b_stress_local_grey.png | matlab/g2/evidence/m4b_r1_20261121/report/r1_g4b_stress_local_grey.png | 6e55e19aa086439cf3a24e549069e8710af94aed | 372263 |
| r1_g5_energy_density_grey.png | matlab/g2/evidence/m4b_r1_20261121/report/r1_g5_energy_density_grey.png | b9a699dd6b0570c3a21dfa5ea8e113e3ddb9af6a | 462422 |
| r1_g6_m4b_masks_grey.png | matlab/g2/evidence/m4b_r1_20261121/report/r1_g6_m4b_masks_grey.png | 7c241fabce3b68035cf5a3a0ba0797a516eab5d4 | 61272 |
| r1_g7_m4b_decomposition_grey.png | matlab/g2/evidence/m4b_r1_20261121/report/r1_g7_m4b_decomposition_grey.png | e720812de357700bf3c816f3aede9acc92b8c6fb | 72709 |

Local XeLaTeX compilation, visual inspection, and bibliography pending. No merge, no GO, no alteration to historical sources.