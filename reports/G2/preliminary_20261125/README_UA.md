# Проміжний науковий звіт G2: «Керування рушійною силою та траєкторією поширення тріщини в метакомпозитах: механізми впливу матеріальної архітектури»

**Статус: `REVIEW_STOP_G2_PRELIMINARY_REPORT` — чернетка для наукової перевірки; не злито.**

Стан дослідження на 25.11.2026. Звіт зібрано **лише з комітованих записів рецензованого знімка** `05bc5f1` (запит № 71; LP2-A2 прийнято з обмеженнями, лише геометрично, рецензія `6058599118`) із базовою прийнятою ревізією LP2-A1 `ed5c6e6` (запит № 70, рецензія `6056658077`). Нових розрахунків МСЕ не виконувалося. Новіші нерецензовані коміти гілки запиту № 71 (`13fc23e`, `7a96184`, `6b94a55`, `4288289`) як докази не використано.

## Що містить тека

| Файл / тека | Призначення |
|---|---|
| `Metakompozyt_G2_Preliminary_Report_20261125_UA.docx` (+ `.pdf`) | сам звіт: редагований Word-файл із рідними формулами (OMML), полями SEQ/REF і змістом (поле TOC); PDF експортовано Word |
| `figures/` | 10 нових рисунків звіту (PNG 300 dpi і PDF); прийняті рисунки A1, G1 і LP2-A2 вставляються з їхніх каталогів без змін |
| `CLAIM_EVIDENCE_LEDGER_UA.md` | реєстр 44 основних тверджень звіту: розділ, джерело (шлях і ключ), прийнятий коміт/запит/рецензія, числа, категорія доказовості (1–4), обмеження, статус незалежної перевірки; родини чисел (LP1/A0, A1 B9, M5-X6 B9, LP2-A1, M4.B/R1/M2, LP2-A2) не змішано |
| `FIGURE_INVENTORY_UA.md` | реєстр 19 рисунків (новий чи прийнятий, дані, скрипт, мова, збільшення/схема/геометричний прогноз) і перелік свідомо невикористаних рисунків з причинами |
| `OPEN_QUESTIONS_UA.md` | короткий перелік нерозв’язаних наукових питань (12) |
| `VERIFICATION_RECORD_UA.md` | зведений запис перевірки: походження знімка й гілок, процедура збірки, бібліографія (Crossref), результати перерахунку чисел, виправлення відносно історичних документів, нерозв’язані запити Q-01…Q-34; розділ «Візуальна перевірка сторінок» заповнюється після перевірки |
| `NUMBERS_CHECK.json` | результат `check_report_numbers.py`: 117 рядків (PASS 116, FAIL 0; перший прогін дав 2 FAIL — неточності тексту звіту, виправлені; негативний контроль 1), SHA-256 використаних файлів доказів |
| `NUMBERING_MAP.json` | карта нумерації розділів, таблиць, рисунків і формул збірки (за ключами); вхід для регенерації реєстрів |
| `README_UA.md` | цей файл |

Скрипти (у `scripts/report/g2_prelim/`): `ch01_02.py … ch10_11.py`, `appendix.py` (зміст звіту), `common.py`, `docx_kit.py`, `omml.py` (інструментарій), `build_report.py`, `render_pdf.ps1`, `g2_prelim_figures_a.m`, `g2_prelim_figures_b.m`, `g2_prelim_figures_c.m`, `g2_prelim_fig_common.m`, `check_report_numbers.py`.

## Як відтворити

1. **Рисунки** (MATLAB R2023a; лише побудова за комітованими JSON/CSV, без МСЕ):
   `matlab -batch "addpath('scripts/report/g2_prelim'); g2_prelim_figures_a(pwd,'reports/G2/preliminary_20261125/figures'); g2_prelim_figures_b(pwd,'reports/G2/preliminary_20261125/figures'); g2_prelim_figures_c(pwd,'reports/G2/preliminary_20261125/figures')"` — з кореня клону `NewMetacomp`.
2. **Документ:** `python scripts/report/g2_prelim/build_report.py <корінь_клону> reports/G2/preliminary_20261125/figures <raw.docx> --ledger reports/G2/preliminary_20261125/NUMBERING_MAP.json` (потрібен `python-docx`).
3. **Поля і PDF** (Microsoft Word): `powershell -File scripts/report/g2_prelim/render_pdf.ps1 -Docx <raw.docx> -Out reports/G2/preliminary_20261125/Metakompozyt_G2_Preliminary_Report_20261125_UA.docx -Pdf reports/G2/preliminary_20261125/Metakompozyt_G2_Preliminary_Report_20261125_UA.pdf` — Word оновлює зміст, нумерацію SEQ/REF і колонтитули, зберігає `.docx` і експортує PDF.
4. **Перерахунок чисел і регенерація реєстрів** (лише стандартна бібліотека Python; пише тільки в теку виходу):
   `python scripts/report/g2_prelim/check_report_numbers.py --docx reports/G2/preliminary_20261125/Metakompozyt_G2_Preliminary_Report_20261125_UA.docx --ledger`
   Після будь-якої зміни нумерації розділів чи таблиць повторіть кроки 2–4: `NUMBERING_MAP.json` оновлюється кроком 2, а реєстри тверджень і рисунків і заголовки розділів у них — кроком 4. Код виходу скрипта 1, якщо хоч один рядок має стан FAIL.

## Збережені попередні редакції (не змінювалися)

У `reports/G2/` без змін лишаються прийняті Word-редакції: `Metakompozyt_G2_Naukovyi_zvit_UA_v0_1.docx`, `Metakompozyt_G2_Naukovyi_zvit_UA_v0_3_Naskrizne_ruinuvannia_bez_interfeisu.docx`, `Metakompozyt_G2_Naukovyi_zvit_UA_v0_4_Atrybutsiia_kilets_kandydat.docx` і пропозиції доповнень у `reports/G2/proposals/` (зокрема `Metakompozyt_G2_A1_dopovnennia_UA.docx`, `Metakompozyt_G2_M4A_proponovani_dopovnennia_UA.docx`, `Metakompozyt_G2_M4B_R1_proponovani_dopovnennia_UA.docx`). Історичні документи досліджень (`docs/research/`, `matlab/g2/`) також не змінювалися: виправлення внесено лише у цей зведений звіт і перелічено в додатку А звіту та в `VERIFICATION_RECORD_UA.md`, п. (д).

## Межі використання

Результати — для ідеалізованої лінійно-пружної крайової задачі (ЛМР/МКН, одинична сила P = 1 Н, плоский напружений стан, ідеальне зчеплення фаз). Звіт не встановлює фізичної зупинки тріщини, зустрічі з міжфазною межею, проходження чи відхилення на ній, стійкості росту, загальності щодо інших архітектур і навантажень, сертифікованої похибки дискретизації для всіх станів і експериментальної валідації траєкторій. Жоден розділ звіту не є дозволом на розрахунок.

`crossref_records/` — записи реєстру Crossref (JSON), за якими 25.11.2026 перевірено бібліографічні дані переліку джерел; назва файлу — DOI із заміною `/` на `_`.
