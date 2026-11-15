# Source inventory and provenance — Issue #7
**Audit date:** 2026-11-15. **Root snapshot:** `main` at the time Stage 0 was opened; original blobs unchanged. **Reading convention:** `TXT` = independently read text; `WEB` = primary publisher/open article or bibliographic preview checked; `PDF-PENDING` = repository PDF itself was NOT extracted/rendered; `DOCX-PENDING` = binary version not text-compared. A matching DOI or filename is not proof that the repository binary was read.

## Project source-of-truth and version uncertainty

| Filename | Repository role | Access | Assessment |
|---|---|---|---|
| `proposal2.tex` | Full Ukrainian narrative of proposed 2027–2028 research | **TXT**, sections and all six simulations, bibliography read | **Working scope, NOT demonstrated approved version.** Has overbroad novelty assertions; do not propagate unqualified. |
| `proposal2.pdf` | Presumed rendering of text candidate | PDF-PENDING | Compare page content and build/version metadata before asserting equality. |
| `Proposal2027-2028.improved.docx` | Filename suggests revised proposal | DOCX-PENDING | Version order and sign-off unresolved; do not infer authority from “improved”. |
| `Proposal2027-2028.docx` | Another proposal version | DOCX-PENDING | Requires paragraph-level comparison. |
| `Proposal2027-2028Kipnis.docx` | Named collaborator variant | DOCX-PENDING | Requires author-confirmed version relationship; not automatically authoritative. |
| `Proposal2027-2028.pdf` | Possible submission snapshot | PDF-PENDING | Must compare metadata/text and approval evidence with other variants. |
| `Запит.pdf` | Formal request form, potential governing scope | PDF-PENDING | Scope hierarchy cannot be finalized until inspected. |
| `1230 Селіванов М.Ф.docx` | Administrative/project auxiliary file | DOCX-PENDING | Not treated as technical evidence. |
| `Підтримка_ДП_Антонов_лист_до_Президії.docx` | Support letter | DOCX-PENDING | Not mechanics evidence. |
| `Супроводжувальний лист.pdf` | Accompanying letter | PDF-PENDING | Not mechanics evidence. |
| `README.md` | Root readme (short) | repository metadata | No scientific qualification. |
| `.github/` | CI/workflow files | not audited | No mechanics conclusions. |

**Hierarchy verdict:** unresolved pending comparison of the formal request, signed PDF and three DOCX variants. Stage 0 interprets only the six scenario descriptions in `proposal2.tex`, not an approved allocation of work. Do not merge or rewrite proposal sources. The proposal cites Moini as `Moini2024` with *RILEM Technical Letters* volume 8 (2023), published online 19 January 2024: clarify publication date consistently.

## Scientific PDFs in repository
Links refer to unchanged GitHub blobs. `WEB` means the corresponding journal work was independently located by identifier/metadata, not that the GitHub-hosted PDF was read.

| File | Identified article / DOI | Relates to simulation | Status |
|---|---|---|---|
| `1-s2.0-S0022509614000131-main.pdf` | Mitchell, Pandolfi, Ortiz (2014), **Metaconcrete**; [10.1016/j.jmps.2014.01.003](https://doi.org/10.1016/j.jmps.2014.01.003) | 3 | WEB; PDF-PENDING |
| `1-s2.0-S0950061823026971-main.pdf` | Dong et al. (2023), **New-generation pavement…**; [10.1016/j.conbuildmat.2023.132980](https://doi.org/10.1016/j.conbuildmat.2023.132980) | 6/context | WEB; PDF-PENDING |
| `1-s2.0-S0950061825002600-main.pdf` | **Identification unresolved**: PII not positively matched to a title/DOI | unknown | PDF-PENDING; needs exact first-page/DOI check |
| `1-s2.0-S0950061825046860-main.pdf` | Zhang et al. (2025), **Low-temperature polymer–concrete interface**; [10.1016/j.conbuildmat.2025.144534](https://doi.org/10.1016/j.conbuildmat.2025.144534) | 5 | WEB; PDF-PENDING |
| `1-s2.0-S0958946520301165-main.pdf` | Xu et al. (2020), **Cementitious cellular composites with auxetic behavior**; [10.1016/j.cemconcomp.2020.103624](https://doi.org/10.1016/j.cemconcomp.2020.103624) | 1,2 | WEB full publisher article; PDF-PENDING |
| `1-s2.0-S0958946525002732-main.pdf` | Imagawa et al. (2025), **Spiral resonators**; [10.1016/j.cemconcomp.2025.106191](https://doi.org/10.1016/j.cemconcomp.2025.106191) | 3 | WEB; PDF-PENDING |
| `1-s2.0-S1369702126002658-main.pdf` | Premadasa et al. (2026), **Emerging mechanical metamaterials…**; [10.1016/j.mattod.2026.103419](https://doi.org/10.1016/j.mattod.2026.103419) | all/context | WEB; PDF-PENDING |
| `1-s2.0-S2214860422004183-main.pdf` | Jipa et al. (2022), **Environmental stress cracking…**; [10.1016/j.addma.2022.103026](https://doi.org/10.1016/j.addma.2022.103026) | 4,5 | WEB full publisher article; PDF-PENDING |
| `1-s2.0-S2352710224005679-main.pdf` | Chen et al. (2024), **ECC-based auxetic structures**; [10.1016/j.jobe.2024.108999](https://doi.org/10.1016/j.jobe.2024.108999) | 1,2 | WEB; PDF-PENDING |
| `1-s2.0-S2352710225026622-main.pdf` | Vo & Kim (2025), **Auxetic meta-concrete experiments**; [10.1016/j.jobe.2025.114425](https://doi.org/10.1016/j.jobe.2025.114425) | 1,2 | WEB; PDF-PENDING |
| `Adv Materials Inter - 2025 - Vandadi - Integrating 3D‐Printed Auxetic Structures for Advanced Concrete Reinforcement.pdf` | Vandadi et al. (2025); [10.1002/admi.202500095](https://doi.org/10.1002/admi.202500095) | 4 | WEB full publisher article; PDF-PENDING |
| `Perspectives_in_architected_infrastructure_materia.pdf` | Moini (2023 vol./2024 online); [10.21809/rilemtechlett.2023.183](https://doi.org/10.21809/rilemtechlett.2023.183) | all | WEB full accessible PDF visually inspected at cover only; local repo binary PDF-PENDING |
| `barri.pdf` | Barri et al. (2023); [10.1002/adma.202211027](https://doi.org/10.1002/adma.202211027) | 3,6/context | WEB abstract; PDF-PENDING |
| `materials-18-04032-v2.pdf` | Wang et al. (2025); [10.3390/ma18174032](https://doi.org/10.3390/ma18174032) | all/context | WEB full open article; PDF-PENDING |

All scientific PDF root files above **14 items**; filenames are not checksums and no byte-level duplication claim is made. The repeated article number `114425` is **NOT** a duplicate: Vo & Kim's 2025 *Journal of Building Engineering* paper [10.1016/j.jobe.2025.114425](https://doi.org/10.1016/j.jobe.2025.114425) differs from their 2026 *Thin-Walled Structures* review [10.1016/j.tws.2025.114425](https://doi.org/10.1016/j.tws.2025.114425).

## Coverage by planned six simulations

1. **Cohesive auxetic hinge:** Xu 2020; Xie 2025; Chen 2024; Vo & Kim 2025. These already establish rotation/bridging phenomenology.
2. **Architecture comparison:** Chen 2024; Vo & Kim 2025; Gupta & Moini 2026 (external). Avoid stiffness/energy-only novelty.
3. **Resonant metaconcrete:** Mitchell 2014; Imagawa 2025; Liu et al. 2025 (external). Dynamical fracture remains an extension, not available in current engine.
4. **3D-printed reinforcement:** Vandadi 2025; Huang et al. 2026 (external); lattice/hollow reinforcement 2025 (external). Interfacial kinking already observed.
5. **Polymer/cement debonding:** Zhang 2025; Jipa 2022; Tao & Zhang 2026 (external); He & Hutchinson 1989. Requires new interface model.
6. **Pavement fragment/traps:** Dong 2023; Moini 2023; Gupta & Moini 2026; Li et al. 2026. Focus on bounded, credible, physically distinguishable metric.

## Missing primary competitors (added to literature matrix)

The root collection omits at least Gao–Liu–Wei 2026, Tao–Zhang 2026, Li et al. 2026, Huang et al. 2026, Gupta–Moini 2026, and the classic He–Hutchinson 1989 interface criterion. **These omissions are material to novelty assessment.** Other bibliography citations in `proposal2.tex` are represented in `LITERATURE_MATRIX.csv` and should not be assumed to be full-text verified.

## Unresolved acceptance gates
- [ ] Obtain actual bytes and visually/textually review each repository PDF, particularly unmatched `S0950061825002600`.
- [ ] Compare 3 proposal DOCX variants, `Proposal2027-2028.pdf`, `Запит.pdf` and `proposal2.tex`; record dates, changes, and approval hierarchy.
- [ ] Check complete primary texts for all top-ten competitors and extract explicit crack-path update algorithms.
- [ ] Ask researcher to confirm exact infrastructure geometry/material scope *before* any new FEM simulation.
