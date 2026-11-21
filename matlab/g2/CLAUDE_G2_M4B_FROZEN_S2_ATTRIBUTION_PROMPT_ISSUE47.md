# Claude Code — G2-M4.B: Attribution of Three Bonded Annuli on Frozen S2

**Implementation assignment:** [Issue #47](https://github.com/mfs9697/NewMetacomp/issues/47). Parent scientific issue: [#44](https://github.com/mfs9697/NewMetacomp/issues/44). Scientist review authorizing B: [comment 7066297598](https://github.com/mfs9697/NewMetacomp/issues/44#issuecomment-7066297598). New scientific baseline: [draft PR #46](https://github.com/mfs9697/NewMetacomp/pull/46), head \`97c9562442e0abea8d77a42ab0f285d90eb3f370\`.

**Read Issue #47 IN FULL first. It is normative; this prompt provides an executable plan, not a substitute.**

## Objective: isolate the material architecture, NOT trajectory feedback

Compute **exactly the 2³ activation subsets of the three rings** for each common active modulus contrast \`c=E_active/E_matrix∈{0.5,2.0}\`, with the original homogeneous **frozen S2** crack at arclength **s=33.4 mm**. Use exactly the same saved S2 mesh, hole/ring geometry, T6 DOFs, homogeneous reference, 1 N force and material matrix; change **only** which ring has \`E_active=c E_matrix\`. For an inactive ring, \`E=E_matrix\`. No remeshing, no crack advancement, no propagation until an interface, no State 3, no mixed per-ring modulus combinations.

The 8 masks for **each** contrast, in canonical order:
\`\`\`
none       000   ∅
ring1      100   {1}
ring2      010   {2}
ring3      001   {3}
rings12    110   {1,2}
rings13    101   {1,3}
rings23    011   {2,3}
all        111   {1,2,3}
\`\`\`
Ring IDs: 1 lower/nearest initial tip (y=69.85mm), 2 middle (y=120.65mm), 3 upper (y=171.45mm); all x=152.4mm. Hole R=6.35 mm; outer annulus R=19.05 mm. Contrast-independent \`none\` baseline may be reused once: **16 logical cases, 15 distinct material distributions**. Do not confuse these with 16 independent trajectory computations.

## Scientific source constraints and first actions

1. From PR #46 and its parent #41/#38, inspect \`G2_M4A_RESULTS.md\`, \`G2_M4_PREREGISTRATION.md\`, \`G2_M4_POLICY_v1.json\`, \`G2_M2_SHIELDING_STEERING_RESULTS.md\`, \`g2_material_phase_map.m\`, \`g2_material_phase_verify.m\`, \`g2_material_sif_on_mesh.m\`, \`g2_t6_elasticity_phase.m\`, \`g2_plane_D.m\`, \`g2_sif_interaction.m\`, \`g2_sif_cod_banks.m\`, \`g2_mts_direction.m\`, the original frozen homogeneous **S2** saved-array MAT and SHA ledger. Pin **full** source, BVP and mesh SHA. The **M4.A alternative S2** is NOT the reference for this test: use the original S2 with 76-facet annuli. Never use a material-specific S2 crack geometry.
2. Keep v1 policy, all historical code, PR heads, evidence and outputs unchanged. The old v1 \`M4_B=NOT AUTHORIZED\` is historically correct as of M4.A. Do not rewrite it. Prospective B authorization is in Issue #44 review and Issue #47.
3. In a **fresh implementation branch from this docs-only brief head**, open ONE new **DRAFT PR** stacked on the brief. First commit a **new versioned** \`G2_M4B_POLICY_v2.json\` and \`G2_M4B_PREREGISTRATION.md\` BEFORE ANY B physical solve. Bind token to policy SHA, source tree SHA, frozen S2 mesh SHA, mask, contrast and legal case cap. Declare machine resources (genuine MATLAB R2023a + PDE Toolbox, >=5 GiB available RAM), exact identity tolerances, uncertainty, reproducibility, all negative tests and STOP codes. Dry/preflight = no writes unless explicitly preregistered as a separate evidence-only log.
4. Run read-only feasibility and a new independent mask-verification test suite BEFORE the 16-case physical campaign.

## Non-negotiable implementation boundary

The existing qualified topology mapper \`g2_material_phase_map\` returns \`PM.phase\` (1 matrix, 2 annuli) and \`PM.annulusOf\` (0 outside bands, 1/2/3 per hole). Its geometry and connectivity remain the **source of topology**, not the material activation rule. Existing \`g2_material_phase_verify\` and \`g2_material_sif_on_mesh\` assume all three band interfaces separate two materials and cannot just be passed a subset mask. **DO NOT MODIFY OR WEAKEN THEM.**

Design and implement new separate routines, with names you select and document, for:
- \`ownerRing = PM.annulusOf\` saved and re-checked by a **separate geometric owner oracle** for all three rings. No centroid-only shortcuts; verify all T6 nodes, polygons, chord edge owners/midsides, hole voids, ring areas and identifiers.
- \`active(e) = ownerRing(e)>0 && mask(ownerRing(e))\` and \`phaseForAssembly(e)=1+active(e)\` with \`mats(1)=matrix\`, \`mats(2)=active\` at selected contrast. **Always retain ownerRing as a separate field** and validate \`phaseForAssembly==1\` on every inactive-ring and matrix element. This permits use of unchanged \`g2_t6_elasticity_phase\` assembly.
- Independently check active versus passive ring chords, same physical T6 nodes on the interface, SPD elasticity, correct per-ring area/volume, matrix-only q **for the entire element support including nodes**, q clearance, reaction/energy identities, static BVP, COD-EDI/J gates, signed KII, exact thickness and 1N-to-per-kN units, no coupling to crack geometry changes.
- Provide **new local phase-aware SIF/interface verification** for partial activation. Do not weaken the full-band verifier to coerce PASS; re-use validated lower-level COD and EDI pieces where mathematically valid. On rings with no material jump, check geometric conformity but do NOT interpret a passive guide boundary as a real traction jump or run inappropriate two-material nodal-force balance diagnostics.
- Implement independent negative mutations: swapped ring IDs/centres, wrong binary mask, off-band E drift, missing/incorrect ring-owned element, detached interface midside, q touching active ring, wrong load or thickness, changed parent mesh bytes, reversed KII, bad token, forged review, dirty source and unauthorized 17th case. Tests must actually fail the correct gate. Source hashes must be rechecked before state/review reuse.

## Blocking exact regression controls BEFORE unknown subset results

1. \`none\` should be **bit-identical** to original S2 homogeneous H1 wherever identical assembly order allows. If a distinct solver prevents bitwise equality, set and justify a tight, prospective numerical identity threshold in v2 **before any B physics**; do not silently downgrade after testing.
2. \`all\` c=0.5 and c=2.0 must reproduce accepted original-S2 three-active-ring results from PR #38/#41, under unchanged historical tolerances: signed \`KI,KII\`, COD from saved twin banks, five EDI q annuli with 6×6 + 4×4 quadrature, \`J\`, \`G\`, full \`u\`, compliance, CMOD, reactions, strain/phase energy, stress/interface resultant. Historical fully-active phase verifier must pass unchanged.
3. Same exact source S2 mesh SHA and BVP for all masks; 3 holes remain true holes. Abort \`HOLD_BASELINE_REGRESSION\` if either endpoint fails. No subset conclusions until both endpoints are qualified.

## Scientific quantities and mathematics

For each \`c\`, define \`S⊆{1,2,3}\` and **one common** homogeneous \`G_0=G(∅)\`, \`θ_0=θ(∅)\`, all measured in the SAME terminal S2 frame:
\`\`\`
F_G(S;c)   = G(S;c)/G_0 - 1               (dimensionless)
F_theta(S;c) = theta_MTS(S;c) - theta_0    (signed degrees)
f_i        = F({i})
I_ij       = F({i,j}) - f_i - f_j
I_123      = F({1,2,3}) - (f_1+f_2+f_3) - (I_12+I_13+I_23)
F({1,2,3}) = Σ_i f_i + Σ_i<j I_ij + I_123
\`\`\`
Use the same decomposition separately for F_G and F_theta; verify exact reconstruction and retain **signed angles** (no abs, branch wrap, or global-vs-local confusion). Optionally compute Shapley allocations of each ring to each observable (all six insertion orders; exact sum identity); **Shapley is bookkeeping, not evidence that a ring acts independently**.

For all 16 logical evaluations save: frozen MAT + SHA, activity bitmask, full-precision \`K_I,K_{II}\` (signed, EDI/COD), \`J\`, \`G\`, MTS forecast \`θ\`, applied force/thickness, u/compliance/CMOD, total and per-ring strain energies, reactions, active area/volume, interface resultant and validation status. Calculate pair/triple interactions with appropriate numerical error propagation including correlations of common H1 baseline, not only independent per-case error bars. Report **both** the existing paired-estimator and conservative (~±3.5%) verdict; don't proclaim small nonzero I_ij statistically/numerically meaningful if unresolved.

**Interpretation gate:** same-number-of-active-rings comparisons control for nominal reinforcement area (1 vs 1, 2 vs 2). Report ring locations. The \`F_G(S)\` is a **direct material effect at fixed crack geometry**, not \`R_total\` or \`R_path\` from material-specific trajectory calculations. Observe but do not assume lower ring dominance, shielding/steering correlation, beneficial nonadditivity or any performance optimum.

## Output format and Word documentation (mandatory)

- Save immutable run artefacts under separate \`outputs/g2_m4b_ring_factorial_v1/run_YYYYMMDD_...\` roots; sanitized tables, full-precision CSV/JSON, failure tests, provenance/SHAs and figures committed under \`matlab/g2/evidence/m4b_20261121/\` or date-appropriate versioned directory.
- Produce \`G2_M4B_RESULTS.md\` and \`G2_M4B_RUNLOG.md\` plus a single **consolidated review** with accepted and failed outcomes and **potential** ring interpretations clearly distinguished from proven numerical facts.
- Include plots of \`F_G\` and \`F_theta\` across all masks, individual/pair/triple interactions with uncertainty, equal-active-volume comparison, geometry/ring-index schematic and selected local stress/strain-energy-field difference maps if grounded in actual data. **All titles, axes, legends, captions and annotations inside every newly prepared figure are in Ukrainian**. Label schematic drawings as \`Схематично\`, and MATLAB-data figures with exact source.
- The canonical editable \`reports/G2/Metakompozyt_G2_Naukovyi_zvit_UA.docx\` is authoritative. The latest available user-verified source was \`Metakompozyt_G2_Naukovyi_zvit_UA_v0_3_Naskrizne_ruinuvannia_bez_interfeisu.docx\`, SHA-256 \`49daba7ef064d2dccd679abfc77a79e122f67e9cbd22c30da9ddb924c03b0b40\`. **First verify its actual bytes on your machine**. A prior chat provided a ZIP handoff; that does NOT prove local availability. If absent, report \`HOLD_WORD_INPUT\` and create a separate native Ukrainian DOCX proposal, as in PR #46, without altering the canonical v0.1 or fabricating v0.3. Once present and SHA-verified, preserve archival 0.3, integrate reviewed M4.A "Додаток Е", then new M4.B section as a *candidate* pending our scientific review. Keep original SIF extraction details (Williams EDI, COD, J, MTS and 1N/per-kN conversions), both error rules and all \`G2-REV-###\` corrections.
- Native **Word is mandatory** (not only TeX, PDF or Markdown). Use OMML for editable equations where practical, numbered equations/tables/figures, bibliography, change log, hashes, render to page images using Word and visually examine **every** page. Place results in the report as **'очікує наукової перевірки'** until scientist approval. No auto-release of claims.

## Review, autonomy and stop

Once all preregistered B cases, controls and documented failures are complete, **STOP** and deliver **ONE consolidated review package** to the researcher and ChatGPT. Do NOT proceed to \`G2-M4.C\`, 3³ mixed materials, long material-specific trajectories, a third 4-mm increment, interface penetration/deflection, cohesive debonding, fracture toughness, or claimed arrest. You may propose **2–3 future architecture candidates** for a separately authorized matrix-only long-trajectory campaign, with early STOP before interface or outer boundary; *proposal only*.

Open one new DRAFT implementation PR stacked on the brief branch. Keep #38/#41/#43/#45/#46 and all original source records untouched; no merges, no overwriting accepted runs. Provide a final machine-readable manifest of which exact 16 logical cases passed, along with FAIL/HOLD records and reproducible MATLAB R2023a commands.

**Definition of Done:** prospectively fixed policy v2 and signed source chain; authentic 16-case frozen-S2 matrix; strict baseline identity; separately validated ring activation; both uncertainty verdicts and nonadditivity analysis; Ukrainian figures and true Word output (or transparently logged Word-input HOLD with independent native DOCX proposal); all tests pass; draft PR; **REVIEW_STOP_B**.
