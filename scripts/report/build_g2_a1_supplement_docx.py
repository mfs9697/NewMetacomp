# -*- coding: utf-8 -*-
"""Ukrainian Word supplement for G2-LP1-A1 (Issue #66): transfer of the EdgeCrackHoleLEFM PR-H
Family B near-tip refinement to the three-ring Cornell metacomposite.

Stage: REVIEW_STOP_A1_TRANSFER_READY. Method, geometry qualification (measured, no FEM),
figures and the template of the numerical section. NO numerical SIF/energy result is written:
those sections are generated only from qualified computations after a separate GO_A1.
Accepted Word editions (v0.1, v0.3, v0.4) are not opened for writing.
usage: python scripts/report/build_g2_a1_supplement_docx.py <repo> <out.docx>
"""
import json, os, re, sys
from docx import Document
from docx.shared import Pt, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

REPO, OUT = sys.argv[1], sys.argv[2]
EV = os.path.join(REPO, 'matlab', 'g2', 'evidence', 'a1_preflight')
Q = json.load(open(os.path.join(EV, 'geometry_d4022da', 'A1_GEOMETRY_QUALIFICATION.json'), encoding='utf-8'))
B = json.load(open(os.path.join(EV, 'batch_6a3a14d', 'PREPHYSICAL_RESULT.json'), encoding='utf-8'))
FIG = os.path.join(REPO, 'reports', 'G2', 'figures', 'a1')

def c(x, nd):  # decimal comma
    return f"{x:.{nd}f}".replace('.', ',').replace('-', '−')
def thou(n):
    s = f"{int(n):,}".replace(',', ' ')
    return s

doc = Document()
st = doc.styles['Normal']; st.font.name = 'Times New Roman'; st.font.size = Pt(12)
st.element.rPr.rFonts.set(qn('w:eastAsia'), 'Times New Roman')
for s in doc.sections:
    s.left_margin = s.right_margin = Cm(2.0); s.top_margin = s.bottom_margin = Cm(2.0)

def rich(p, text, bold=False, italic=False, size=None):
    # markup: _{...} subscript, ^{...} superscript; plain underscores in identifiers are untouched
    for part in re.split(r'([_^]\{[^}]*\})', text):
        if not part:
            continue
        if part[:2] in ('_{', '^{'):
            r = p.add_run(part[2:-1]); r.font.subscript = part[0] == '_'; r.font.superscript = part[0] == '^'
        else:
            r = p.add_run(part)
        r.bold = bold; r.italic = italic
        if size: r.font.size = Pt(size)
def para(text, bold=False, italic=False, align=None, size=None, space=6):
    p = doc.add_paragraph()
    rich(p, text, bold, italic, size)
    if align == 'c': p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    elif align == 'j': p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_after = Pt(space)
    return p
def head(text, lvl=1):
    h = doc.add_heading(text, level=lvl)
    for r in h.runs:
        r.font.name = 'Times New Roman'; r.font.color.rgb = None
        r._element.rPr.rFonts.set(qn('w:eastAsia'), 'Times New Roman')
    return h
def keep(p):
    p.paragraph_format.keep_with_next = True
def figure(name, caption, width=16.5):
    p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER; keep(p)
    p.add_run().add_picture(os.path.join(FIG, name + '.png'), width=Cm(width))
    para(caption, align='j', size=11)
def table(rows, header, widths=None, size=9):
    t = doc.add_table(rows=1, cols=len(header)); t.style = 'Table Grid'; t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(header):
        cell = t.rows[0].cells[i]; cell.text = ''; rich(cell.paragraphs[0], h, bold=True, size=size)
    for row in rows:
        cells = t.add_row().cells
        for i, v in enumerate(row):
            cells[i].text = ''; r = cells[i].paragraphs[0].add_run(str(v)); r.font.size = Pt(size)
    for row in t.rows:
        trPr = row._tr.get_or_add_trPr(); cs = OxmlElement('w:cantSplit'); trPr.append(cs)
        for cell in row.cells:
            for p in cell.paragraphs:
                p.paragraph_format.keep_with_next = True; p.paragraph_format.space_after = Pt(0)
    return t

para('Метакомпозит G2. Доповнення A1 до наукового звіту', bold=True, align='c', size=16)
para('Перенесення апробованої схеми локального подрібнення сітки біля вершини тріщини (родина B, EdgeCrackHoleLEFM PR-H) '
     'на тришарову зразкову пластину Корнелла з кільцевими включеннями', italic=True, align='c', size=12)
para('Завдання № 66; draft PR, складений на PR № 65. Стан: REVIEW_STOP_A1_TRANSFER_READY — перенесення та геометрична '
     'кваліфікація завершені без жодного розрахунку МСЕ. Розділ числових результатів подано як шаблон: його буде заповнено '
     'лише результатами кваліфікованих розрахунків після окремого рішення дослідника GO_A1.', align='j', size=11)

head('1. Мета, межі та зв’язок з попередніми результатами')
para('Мета етапу A1 — показати, наскільки ефективно вже апробовану схему локального подрібнення сітки біля вершини тріщини '
     'можна застосувати до метакомпозита, а не повторювати розроблення методу. Досліджуються чотири заморожені траєкторії стану S4 '
     '(s = 41,4 мм), прийняті в A0 як точно відтворені (PR № 65): однорідний матеріал H, жорсткі кільця {1,3}, м’яке кільце {2} і '
     'м’яке кільце {1}. Траєкторії не поширюються; змінюється лише сітка біля вершини.', align='j')
para('Рівень m = 0 — це вже збережений розв’язок A0 (без нового розрахунку). Нові рівні m = 3, 6, 9 разом дають щонайбільше '
     '12 розрахунків з фіксованою геометрією. Фізична постановка — без змін: плоский напружений стан, E_{m} = 3268,115 МПа, ν = 0,35, '
     'товщина 12,7 мм, зосереджена сила 1 Н у точці (254; 203,2) мм, власні опори зразка, кільця з відношенням модулів 2 або 0,5. '
     'КІН визначаються незмінним ланцюгом NewMetacomp: сліпа оцінка за розкриттям (COD), потім знаковий інтеграл взаємодії (EDI) '
     'на п’яти кільцевих областях.', align='j')

head('2. Метод: родина B і заміна ядра на незмінній зовнішній сітці')
para('Схему взято з EdgeCrackHoleLEFM (завдання № 427, PR № 428, злитий head c69b234; файл build_prh_near_tip_patch.m, '
     'SHA-256 d42024e7…). У родині B геометричне 64-секторне кільце базового ядра p010 продовжується всередину на 2m смуг, а '
     'внутрішній диск зменшується подібністю λ = q^{−2m}. Межа ядра 3 мм, її 64 сектори, лінія тріщини і вершина не змінюються. '
     'Родина A (радіальний перерозподіл) не переноситься.', align='j')
para('Перевірено, що шість базових будівників p010 у NewMetacomp (vendor_p010_a14d8872) побайтово тотожні версіям Edge PR-H '
     '(після нормалізації кінців рядків). Тому перенесення — це пряме портування алгоритму в окремий модуль g2_a1_family_b_patch '
     'без зміни залежностей. Числові значення КІН з Edge не переносяться: там розв’язувалася інша задача (пластина з двома '
     'отворами, плоска деформація, інші матеріал і навантаження, вершина H5).', align='j')
para('Статус доказів Edge. За зведеним звітом PR-H (коміт 0195266, у main) розрахунки МСЕ виконано на всіх чотирьох рівнях '
     'L0, BM3, BM6 і BM9 для замороженої вершини H5; КІН BM6/BM9 незалежно відтворено зі збережених переміщень. У проєктному '
     'документі PR-H (PRH_NEAR_TIP_STUDY_DESIGN.md) і в постановці завдання № 66 BM6/BM9 ще позначені як невиконані або лише геометричні; у цьому доповненні використано пізніший підсумковий статус. '
     'Жоден з цих висновків не доводить асимптотичної збіжності: родина B зберігає відношення h/r ≈ 0,096 поза диском, рівні '
     'не вкладені один в одного.', align='j')
para('Заміна ядра. У збережених сітках S4 комір із 128 трикутників і зовнішня сітка торкаються ядра лише через 64 вузли межі '
     'і один вхідний вузол нижнього берега. Тому ядро замінюється без повторного генерування сітки: (1) ядро і комір для '
     'збереженої ламаної перебудовуються незмінним g2_kinked_regular_block і мають побітово збігтися зі збереженими; (2) з того '
     'самого кільця будується латка родини B; (3) координати межі зберігаються побітово, комір і зовнішня сітка лише '
     'перенумеровуються; (4) береги, вузли зламів і вузлова функція q обчислюються так само, як у g2_kinked_join.', align='j')

head('3. Геометрична кваліфікація (виміряно, без МСЕ)')
para('Кожен варіант (4 траєкторії × m = 0, 3, 6, 9) пройшов 19 інваріантів A1 (додатні площі, мінімальний кут ≥ 20°, '
     'відношення сусідніх елементів ≤ 1,8, кут ≥ 30° і якість > 0,85 у диску, відсутність висячих вузлів, точні серединні вузли T6, '
     'шви по 64 ребра на 3 і 3,3 мм, два узгоджені береги з однією вершиною, шестиелементне віяло, носій q усередині ядра, '
     'бюджет 40 000 T3, побітово незмінна зовнішня сітка), незмінний перевіряльник берегів LP1, повний аудит фаз (усі чотири '
     'маски, незалежний оракул власників кілець, негативні контролі) та умову, що носії q усіх п’яти кільцевих областей лежать '
     'у матриці. Для m = 0 усі 19 збережених полів сітки побітово збігаються з A0. Табл. 1 містить виміряні характеристики.', align='j')
rows = []
for r in Q['rows']:
    s = r['summary']
    rows.append([r['caseId'], r['m'], c(s['tipFirstEdgeRadial_mm'], 5), thou(s['T3']), thou(s['DOF']), thou(s['coreT3']),
                 s['qActivePrimary'], c(s['diskRadius_mm'], 3), c(s['minAngle_deg'], 2), c(s['maxNeighborRatio'], 3),
                 f"{r['validator']['gatesPassed']}/{r['validator']['gatesTotal']}", 'так' if r['phaseAuditPass'] else 'ні'])
p = para('Таблиця 1 — Виміряні характеристики сіток (h₁ — перше радіальне ребро біля вершини; СС — ступені свободи; '
         'q — кількість q-активних елементів основної області 0,4–2,6 мм)', size=11); keep(p)
table(rows, ['Траєкторія', 'm', 'h₁, мм', 'T3', 'СС', 'T3 ядра', 'q', 'R_{диска}, мм', 'min кут, °', 'max відн.', 'Інваріанти', 'Фази'], size=8)
para('', space=4)
para(f"Подрібнення від m = 0 до m = 9 зменшує перше ребро у {0.041666666667/0.009861624114:.2f}".replace('.', ',') +
     ' раза (0,04167 → 0,00986 мм), додаючи лише 2 322 трикутники (+8,0 %) і 9 360 СС (+7,9 %) до повної моделі. '
     'Рівномірне подрібнення до того самого h₁ потребувало б, за оцінкою N_{0}(h_{0}/h_{1})², близько 519 000 трикутників — '
     'приблизно в 16,5 раза більше (рис. 3; це оцінка, а не побудована сітка).', align='j')
para('Спільний функціонал для m = 6 і m = 9. Для всіх чотирьох траєкторій 3 225 q-змінних елементів основної області збігаються '
     'між рівнями 6 і 9 (максимальна різниця координат вузлів 1,4·10⁻¹⁴ мм). Отже, зміна КІН між цими рівнями оцінюватиметься на '
     'спільній дискретизації інтеграла взаємодії; зміни 0 → 3 → 6 поєднують зміну розв’язку та зміну області інтегрування.', align='j')
figure('A1_F1_tip_mesh_levels_UA', 'Рисунок 1 — Сітка біля вершини тріщини для траєкторії H у стані S4 на рівнях m = 0, 3, 6, 9 '
       'в однаковому масштабі ±0,6 мм (x_{t} — уздовж дотичної до останнього відрізка, x_{n} — по нормалі; жирна лінія — тріщина).')
figure('A1_F2_preservation_UA', 'Рисунок 2 — Збереження геометрії: межа ядра 3 мм (штрих) і зовнішня межа коміра 3,3 мм '
       '(суцільна) для m = 0 і m = 9. Елементи коміра та зовнішньої сітки однакові побітово; змінюється лише ядро r < 3 мм.', width=15)
figure('A1_F3_cost_UA', 'Рисунок 3 — Кількість трикутників залежно від першого ребра h₁: виміряно для побудованих сіток родини B '
       '(підписи — кількість ступенів свободи, СС) та оцінка N_{0}(h_{0}/h_{1})² для гіпотетичного рівномірного подрібнення.', width=14)

head('4. Шаблон числового розділу (заповнюється лише після GO_A1)')
para('Для кожної траєкторії і рівня буде наведено: h₁, кількості T3/T6/СС, q-активні елементи п’яти областей, час розрахунку, '
     'використання пам’яті, знакові K_{I} і K_{II}, K_{II}/K_{I}, J і G = (K_{I}² + K_{II}²)/E_{m}, локальний кут за критерієм максимального '
     'колового напруження (МКН), п’ять оцінок EDI, оцінку 4×4 і COD, перевірки рівноваги, енергії та балансу на межах фаз.', align='j')
para('Порівняння рівнів: знакові зміни ΔK_{I}, ΔK_{II}, ΔG, Δθ між сусідніми рівнями і відносно m = 0. Рівень m = 9 — найдрібніший '
     'з випробуваних, опорний, але не точний розв’язок. Архітектурний сигнал на кожному рівні:', align='j')
para('F_{G}(m) = G_{випадок,S4}(m) / G_{H,S4}(m) − 1', italic=True, align='c')
para('Геометрії тріщин різних випадків відрізняються за побудовою, тому F_{G} — умовне, опосередковане траєкторією порівняння, а не '
     'контраст матеріалу на однаковій геометрії. Локальний кут МКН у замороженому S4 — діагностика, а не нова траєкторія. '
     'Класифікацію м’якого кільця {2} (НЕРОЗРІЗНЕНО за консервативним критерієм) не змінюють без окремо обґрунтованої оцінки '
     'невизначеності та рецензії. Екстраполяцію Річардсона і порядок збіжності не застосовують: рівні не вкладені, h/r поза '
     'диском фіксоване. Заплановані рисунки: знакові K_{I}, K_{II}, кут МКН і F_{G} залежно від h₁ (генератор '
     'scripts/report/g2_a1_report_figures.m, лише зі збережених записів).', align='j')

head('5. Необхідний дозвіл GO_A1')
para('Фізичні розрахунки можливі лише після окремого рішення дослідника, записаного в завданні № 66, і чинного файлу '
     'matlab/g2/G2_A1_SCIENTIFIC_GO_v1.json, що прив’язує:', align='j')
for t in [f"політику A1: SHA-256 {B['policySHA256']};", f"набір коду: SHA-256 {B['sourceSHA256']};",
          f"маніфест 12 сіток: SHA-256 {B['meshManifestSHA256']};",
          'свідоцтво контракту: matlab/g2/evidence/a1_preflight/batch_6a3a14d/CONTRACT_TESTS.json;',
          'межі кампанії A1_S4_FAMILY_B_FIXED_PATH_MAX12, назву запуску і ідентифікатор кампанії (запропоновано run_a1_family_b_s4_v1, G2-A1-FB-001).']:
    para('• ' + t, size=10, space=2)
para('Відкликаний GO етапу A0, його маркер, назва запуску і журнал кампанії не можуть бути використані повторно; це перевірено тестами.', align='j')

head('6. Інтеграція у звіт')
para('Цей файл — окреме доповнення. Прийняті редакції v0.1, v0.3 і кандидат v0.4 не змінювалися. Канонічну консолідацію '
     '(v0.4.1) виконують у межах завдання № 53: розділи 2–3 і рисунки 1–3 можна вставити як підрозділ про чисельну методику, '
     'розділ 4 — після отримання результатів A1.', align='j')
doc.core_properties.title = 'Метакомпозит G2 — доповнення A1'
doc.core_properties.author = 'NewMetacomp G2'
doc.save(OUT)
print('saved', OUT)
