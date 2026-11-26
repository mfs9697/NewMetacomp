# Розділ 4 — верифікація: джерела та межі

Основний зріз: 923ef406349d75c5d7f7ed77f954cf36614b272d (PR #72). Додатково: наукове приймання PR #71 на 2a25973a8b7fc4e6c10c19a01b4243e5ffddafc8 і технічне закриття на 666c3a7842299ec8f95f8a325df01f5c24dde588. Історичний SR0 не переписано.

| Підрозділ | Джерело |
|---|---|
| Геометрія, T6, перша відмова | matlab/g2/PROTECTED_MESH_WP1.md; SIF_WP2_RESULTS.md |
| Williams, згин, S0 | matlab/g2/evidence/wp2_20261118/verification_run_20261118_170139_962/M1_M4_manufactured.csv; b1_run_20261118_170142_961/b1_benchmark_summary.json; cornell_run_20261118_170047_650/cornell_sif_summary.json (у тому самому дереві evidence); WP2_PREREGISTRATION.md |
| S1 | matlab/g2/WP3_FIRST_KINK_RESULTS.md |
| Кільце, еталон і фази | matlab/g2/G2_MATERIAL_CONTRAST_RESULTS.md; check_g2_material_benchmark.m; g2_coated_hole_exact.m |
| R1 і показники невизначеності | matlab/g2/G2_M4B_R1_RESULTS.md; evidence/m4b_r1_20261121/report/g2_three_questions.csv; reports/G2/LP1_20261122_v3/SCIENTIFIC_REVIEW_UA.md |
| A1 | docs/research/G2_A1_TRANSFER_REPORT_UA.md; G2_A1_DEMONSTRATION_REPORT_UA.md; matlab/g2/evidence/a1_campaign_20261122/A1_RESULTS_TABLES.md |
| A0/S5–8 | docs/research/G2_LP1_A0_TECHNICAL_REPORT_UA.md; G2_LP2A1_DEMONSTRATION_REPORT_UA.md; незалежні рецензії в SR0_REVIEW_SNAPSHOTS.json |
| LP2-A2 | docs/research/G2_LP2A2_MESH_QUALIFICATION_MEMO_UA.md; рецензії PR #71; G2_LP2A2_EQ_A2_DEMONSTRATION_MEMO_UA.md на 666c3a7842299ec8f95f8a325df01f5c24dde588; eq_campaign_A2/closure/LP2A2_EQ_CLOSURE_FINAL.json |

## Рисунки
| Локальна назва | Першоджерело | Blob SHA-1 | Байтів |
|---|---|---|---:|
| A1_F1_tip_mesh_levels_UA.pdf | `reports/G2/figures/a1/A1_F1_tip_mesh_levels_UA.pdf` | `d63caa0ace90d6ef52b50504b8cf9cb68e79bff7` | 103708 |
| A1_F2_preservation_UA.pdf | `reports/G2/figures/a1/A1_F2_preservation_UA.pdf` | `be88caad71b975f4bf3634af4129c2ba6a4c1350` | 64746 |
| A1_F3_cost_UA.pdf | `reports/G2/figures/a1/A1_F3_cost_UA.pdf` | `75c599f09ca4ac33fcca2e28a8bcca6ab33a96e3` | 28635 |
| A1_F4_sif_changes_UA.pdf | `reports/G2/figures/a1/A1_F4_sif_changes_UA.pdf` | `627e732c02d35a13293028ab11e74711dd4b2775` | 41673 |
| A1_F5_FG_robustness_UA.pdf | `reports/G2/figures/a1/A1_F5_FG_robustness_UA.pdf` | `3c14389d569337c13a46b4e62b21d8b45f238b6b` | 29793 |
| A1_F6_numerical_indicators_UA.pdf | `reports/G2/figures/a1/A1_F6_numerical_indicators_UA.pdf` | `fc8978d12a9e55bd1e1ab6115ec19249b833c0e4` | 38193 |
| r1_g1_crossfamily_grey.png | `matlab/g2/evidence/m4b_r1_20261121/report/r1_g1_crossfamily_grey.png` | `77a816e3a2db1b9df0bc9f687f3f51d9b4670cd2` | 79008 |
| r1_g2_three_questions_grey.png | `matlab/g2/evidence/m4b_r1_20261121/report/r1_g2_three_questions_grey.png` | `5fd3903aa07284b2dd7598868741a0d6084576c6` | 126184 |
| LP2A2_6_kvalifikatsiia_UA.pdf | `docs/research/G2_LP2A2_evidence/figures/LP2A2_6_kvalifikatsiia_UA.pdf` | `0590b29450e916b9e1e19a5bb00982533ba00cd2` | 35146 |
| LP2A2_7_vymushena_para_UA.pdf | `docs/research/G2_LP2A2_evidence/figures/LP2A2_7_vymushena_para_UA.pdf` | `00014e234ceaa4802585263da1037785cb97cacd` | 39613 |
| LP2A2_8_zalyshkovi_vidmovy_UA.pdf | `docs/research/G2_LP2A2_evidence/figures/LP2A2_8_zalyshkovi_vidmovy_UA.pdf` | `44a3928674c5275d486f72c88a403c7e52e7ef59` | 40101 |

Усі 11 оригінальних файлів Клауде з українськими підписами за джерелами: 9 PDF і 2 PNG. Візуально не переглянуто через текстовий конектор. Ранні англомовні графіки WP2/COD/EDI та coated-hole збережено в історичному каталозі; таблиці з їхніми числами вже в тексті, українізовані графіки можна додати після відновлення вихідних числових масивів. Рисунки A1-F2/F3/F4/F6 повернуто, не тільки F1/F5. R1 g1/g2 — дві різні діагностики; g3–g7 для фізичного аналізу зарезервовано.

## Редакційні уточнення
- Розрізняються методична перевірка, чутливість до сітки, детермінізм, фізична валідація. Не називаємо U_cons гарантованою похибкою.
- R1: за дев'ятьма рядками CSV фактичний діапазон drift/U_primary для G ширший за узагальнення 10–100; відображено діапазон, а не твердження про однаковий порядок у всіх випадках.
- A1: геометрії S4 власних траєкторій фіксовані окремо. B6/B9 — спільний q-функціонал, не глобальне подрібнення. Зміна F_G безрозмірна.
- LP2-A2: 76/76 охоплює S6–S11 (74+2), 8/8 незалежний тест; 112/117 не дорівнює 113/117 з'єднаним сіткам. LP2-A2-8 містить не тільки фінальні відмови.
- Пізнє закриття: окремий верифікатор VERIFIED_V2; 32+23 тести, 4/4, 25 метрик побітово, 24 файли не змінено. Це не нова кампанія і не дозвіл S9.
- Бібліографія Tada/Paris/Irwin, Williams, Michell та джерело точного покритого отвору потребує перевірки й оформлення. Нових FEM або змін розрахункового коду немає.
