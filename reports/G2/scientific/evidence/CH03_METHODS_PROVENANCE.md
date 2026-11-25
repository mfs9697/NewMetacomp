# Розділ 3: джерела, межі та рисунки

Зріз вихідного коду і рисунків: PR #72, 923ef406349d75c5d7f7ed77f954cf36614b272d; історичні прийняття й окремий пізніший результат LP2-A2 EQ — див. SR0_REVIEW_SNAPSHOTS.json.

| Підрозділ | Першоджерело |
|---|---|
| T6, квадратура, плоский напружений стан, P/t | matlab/g2/g2_t6_elasticity_phase.m, g2_plane_D.m, g2_material_sif_on_mesh.m |
| Ядро, комір, згортання | matlab/g2/PROTECTED_MESH_WP1.md, g2_kinked_regular_block.m, g2_kinked_exterior_mesh.m, vendor_p010_a14d8872/build_m1i_trial_tip_disk_p010.m, build_m1i_trial_tip_annulus_p010.m |
| Локальне подрібнення B | matlab/g2/g2_a1_family_b_patch.m |
| Парне розбиття | docs/research/G2_LP2A2_MESH_QUALIFICATION_MEMO_UA.md, matlab/g2/lp2a2/g2_lp2a2_exterior_mesh.m |
| Матеріальна класифікація | matlab/g2/g2_material_phase_map.m, g2_material_phase_verify.m |
| Williams, COD, EDI, J, одиниці | matlab/g2/g2_williams_field.m, g2_sif_cod.m, g2_sif_cod_banks.m, g2_sif_interaction.m, g2_material_sif_on_mesh.m, WP2_PREREGISTRATION.md |
| MTS, приріст, допустимість | matlab/g2/g2_mts_direction.m, g2_lp1_forecast.m, g2_lp0_clearance.m, G2_TRAJECTORY_POLICY_v1.json |

## Графічні джерела (незмінні Git blobs)
| Файл у figures/ | Шлях джерела | Git blob SHA-1 | Байтів |
|---|---|---|---:|
| F03_zony_bilia_vershyny.pdf | `reports/G2/preliminary_20261125/figures/F03_zony_bilia_vershyny.pdf` | `ada7681bc6e3da2130d543f165dfe952791072ff` | 118895 |
| LP2A2_2_stantsii_UA.pdf | `docs/research/G2_LP2A2_evidence/figures/LP2A2_2_stantsii_UA.pdf` | `58381e6c984511d6be0b42713cb271f89626d683` | 31557 |
| LP2A2_3_pislia_kolapsu_UA.pdf | `docs/research/G2_LP2A2_evidence/figures/LP2A2_3_pislia_kolapsu_UA.pdf` | `822a0758ff870819d6ab1547c66c16c02da7de5d` | 30835 |
| LP2A2_4_komir_UA.pdf | `docs/research/G2_LP2A2_evidence/figures/LP2A2_4_komir_UA.pdf` | `840944d4b8e28bc7d0079d5190b339ddcd38c77c` | 106099 |
| LP2A2_5_povni_sitky_UA.pdf | `docs/research/G2_LP2A2_evidence/figures/LP2A2_5_povni_sitky_UA.pdf` | `0e8d1d5203b90383c3012bb4f59d29a9057866d9` | 1574399 |

F03 — номінальна схема початкової тріщини; LP2A2-2 і -3 — геометричний прогноз S9 soft2, не розв'язок; LP2A2-4 — ядро, комір та вхід берегів; LP2A2-5 — прийнята геометрія S8 H та прогноз S9 soft2. Збережено українські підписи. Усі оригінали Клауде; без нової генерації. Фактичний вигляд PDF через конектор не переглянуто, потрібне локальне візуальне приймання.

## Наукові рішення
- Відокремлено геометрію від фізичного розв'язку; 15-мм напрямна — допоміжна, пасивні кільця все одно є чисельними перешкодами у LP0/LP1.
- COD та EDI алгебраїчно незалежні, але використовують один розв'язок; J та EDI додатково мають спільну область і квадратуру. Узгодженість не є сертифікованою похибкою.
- Введено K_* для розмірнісно коректного запису одиничних допоміжних полів.
- Формула МКН і похідна виведені редакційно; у коді корінь atan2. Малі кути в радіанах.
- Не ототожнювати сімейства зовнішньої сітки A/B з локальними B0/B3/B6/B9.
- Порогові значення наведено для базової політики, не як універсальні оцінки похибки. Обмежена кваліфікація LP2-A2 та її еквівалентність — предмет розділу 4, не дозвіл на S9.
- Бібліографічне оформлення Williams, interaction integral, MTS та T6 залишено для цільового огляду і перевірки посилань. Ніяких FEM, змін обчислювального коду, дозволів чи злиття. Компіляцію і візуальну перевірку нового розділу ще не виконано.

Додатково наведено явні компоненти поля напружень Вільямса, регулярний T-член та формули аналітичних похідних згідно з g2_williams_field.m. Локальне перетворення градієнтів відповідає rot2 у g2_sif_interaction.m.
