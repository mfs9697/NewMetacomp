# Chapter 7 — матеріал / геометрія, M3, M4.A, M5, X6
Pinned source 923ef406349d75c5d7f7ed77f954cf36614b272d; PR #69 scientific adjudication at d5f4681d851418d4386c2ddb21c7835f620fd9bf. Sources:
- docs/research/G2_M5_X6_evidence/campaign_20261125/M5X6_ANALYSIS.json
- docs/research/G2_M5_evidence/M5_EXISTING_EVIDENCE.json
- matlab/g2/evidence/m4_20261121/analysis/m4a_ratios_both_families.csv
- docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json
- matlab/g2/G2_M3_RESULTS.md; G2_M4A_RESULTS.md; docs/research/G2_M5_MECHANISM_ATTRIBUTION_MEMO_UA.md (historical, before X6); G2_M5_X6_DEMONSTRATION_REPORT_UA.md; scripts/g2/m5/x6/m5x6_analyze.m.
- 171 coefficient checks across 15 observable/architecture rows; max discrepancy 1.1102230246251565e-16, identity residual 1.1102230246251565e-16, max G vs J term difference 0.0000011513223869275002. KII normalized by fixed HH norm, not each state's norm. Exact additive and multiplicative accounting, Shapley and alternate material effect with same denominator.
- S2 for selected architectures has three available states only (H on X missing); historical normalized baselines differ ~8e-8, no exact four-state S2 identity. M3/M4.A all-three-ring cases are different architectures. M4.A is full two-step exterior mesh comparison, not entire S0–S8 nor near-tip/step convergence.
- S4 6 accepted solves and 4 reused A1 B9 diagonal states. No new FEM, no GO. P1/P2 confirmed; P3 no a priori signs; P4 exploratory fails stiff13/soft1, original intervals unchanged. No S4 error bound for crossed terms. soft2 conservative status unchanged.
- New editorial derivations: heading recurrence, tip-vector sum and first-order projection; estimate 16 sin(dtheta0)/d is not causal share. B0 geometry vs B9 crossed elastic values kept distinct. Relative compliance plot is not derivative of absolute difference.
- New TikZ figure CH07_direct_total replaces outdated M5-2 whose S4 direct effect was absent; B0 own contrasts and B9 S4 direct points explicitly marked. Original archived. All other original figures copied as exact blobs; 5 included, 8 archived for future use, not visually inspected here. Final compilation, figure audit and bibliography pending.

| File | Source | SHA-1 | Bytes | Status |
|---|---|---|---:|---|
| F07_1_rozklad_S4.pdf | reports/G2/preliminary_20261125/figures/F07_1_rozklad_S4.pdf | 6efa65a38e3ac980271f90ce46fea32b050dc746 | 48195 | included |
| M5_1_geometriia_UA.pdf | docs/research/G2_M5_evidence/M5_1_geometriia_UA.pdf | dbeb6f65276b82beba416cf7790efa2d3245ac07 | 43540 | included |
| M5_2_FG_priamyi_i_povnyi_UA.pdf | docs/research/G2_M5_evidence/M5_2_FG_priamyi_i_povnyi_UA.pdf | ff0b35fdc859b38ed02f5b7377787955950911af | 30958 | archive |
| M5_3_podatlyvist_UA.pdf | docs/research/G2_M5_evidence/M5_3_podatlyvist_UA.pdf | 4f5b813879e6f0977c84fcaeae96a49b41c90fda | 26560 | included |
| m4a_fig1_paths.png | matlab/g2/evidence/m4_20261121/report/m4a_fig1_paths.png | 18ac91166054680310a259d7bb6a9394d5858285 | 147071 | included |
| m4a_fig2_ratios.png | matlab/g2/evidence/m4_20261121/report/m4a_fig2_ratios.png | 6c6f9ab67be4a3c2aed91250960cc8489b75e01e | 89860 | included |
| m4a_fig3_interface_meshes.png | matlab/g2/evidence/m4_20261121/report/m4a_fig3_interface_meshes.png | e315ebcee10ef6035968f140f91ae2296a0bc8f7 | 395945 | archive |
| m4a_fig4_tip_q_support.png | matlab/g2/evidence/m4_20261121/report/m4a_fig4_tip_q_support.png | 21aaadc84d21e0e71d8b0ee2a2dcd0ccf0051c96 | 539545 | archive |
| m4a_fig5_K.png | matlab/g2/evidence/m4_20261121/report/m4a_fig5_K.png | 7eceef8606c9970a34fd8fb5e82d4954c7f8cfe7 | 157239 | archive |
| m3_paths_offsets.pdf | matlab/g2/evidence/m3_20261121/report/m3_paths_offsets.pdf | 97eca5853c6a94b5ecab32cea13cb0d8f6706353 | 7710 | archive |
| m3_ratios.pdf | matlab/g2/evidence/m3_20261121/report/m3_ratios.pdf | cc8265cc43b4bfbdbb3cfe5b2b44cc300f8623fd | 8775 | archive |
| m3_G_theta.png | matlab/g2/evidence/m3_20261121/report/m3_G_theta.png | 81f121a19b0dd8d291ac3881d5900210082a7ffc | 144679 | archive |
| m3_phase_snapshot.png | matlab/g2/evidence/m3_20261121/report/m3_phase_snapshot.png | 29f44869834cc0754b7a9689c62e1a9c6ccb8530 | 752480 | archive |
