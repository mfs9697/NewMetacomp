# -*- coding: utf-8 -*-
"""Build the Ukrainian Word proposal for the G2-M4.A review packet (Issue #44).

Reads only committed evidence (analysis LEDGER.json, chain run logs, Ukrainian MATLAB figures)
and writes a native .docx with OMML equations. It is a PROPOSAL of additions to the canonical
G2 report, not a canonical revision (canonical v0.2/v0.3 absent locally: HOLD_WORD_INPUT).

usage: python -I scripts/report/build_g2m4a_proposal_docx.py <evidenceDir> <out.docx>
"""
import json, re, sys, hashlib, os
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import qn

EV = sys.argv[1]
OUT = sys.argv[2]
L = json.load(open(os.path.join(EV, 'analysis', 'LEDGER.json'), encoding='utf-8'))
FAULTS = json.load(open(os.path.join(EV, 'faults', 'm4a_faults_summary.json'), encoding='utf-8'))
FEAS = json.load(open(os.path.join(EV, 'feasibility', 'FEASIBILITY.json'), encoding='utf-8'))
PROV = json.load(open(os.path.join(EV, 'PROVENANCE.json'), encoding='utf-8'))
FIG = os.path.join(EV, 'report')

def num(x, nd=6, sign=False):
    s = f"{x:+.{nd}f}" if sign else f"{x:.{nd}f}"
    return s.replace('-', '−').replace('.', ',')

def sci(x, nd=2, sign=False):
    if x == 0:
        return '0'
    s = f"{x:+.{nd}e}" if sign else f"{x:.{nd}e}"
    m, e = s.split('e')
    e = int(e)
    return (m.replace('-', '−').replace('.', ',') + f"·10^{e}").replace('^', '').replace('·10', '·10') if False else m.replace('-', '−').replace('.', ',') + '·10' + sup_digits(e)

SUP = str.maketrans('-0123456789', '⁻⁰¹²³⁴⁵⁶⁷⁸⁹')
def sup_digits(e):
    return str(e).translate(SUP)

def yes(b):
    return 'так' if b else 'ні'


REPL = [(r'U_δ\^альт', 'U_{δ}^{альт}'), (r'U_δ,конс', 'U_{δ,конс}'), (r'U_Δθ0', 'U_{Δθ0}'), (r'U_Δθ1', 'U_{Δθ1}'), (r'U_δ', 'U_{δ}'),
        (r'R_прям', 'R_{прям}'), (r'R_шлях', 'R_{шлях}'), (r'R_заг', 'R_{заг}'), (r'R_4×4', 'R_{4×4}'), (r'R_COD', 'R_{COD}'),
        (r'U_сітки', 'U_{сітки}'), (r'U_конс', 'U_{конс}'), (r'δG_a', 'δG_{a}'), (r'δG_b', 'δG_{b}'), (r'G_EDI', 'G_{EDI}'), (r'G_COD', 'G_{COD}'),
        (r'E_m\b', 'E_{m}'), (r'E_r\b', 'E_{r}'), (r'ν_r\b', 'ν_{r}'), (r'K_aux', 'K_{aux}'), (r'r_in\b', 'r_{in}'), (r'r_out\b', 'r_{out}'), (r'K_0\b', 'K_{0}'),
        (r'x_M\b', 'x_{M}'), (r'x_H\b', 'x_{H}'), (r'n_H\b', 'n_{H}'), (r'd_H\b', 'd_{H}'), (r'K_II\b', 'K_{II}'), (r'K_I\b', 'K_{I}'), (r'θ_MTS', 'θ_{MTS}'),
        (r'δ\^альт', 'δ^{альт}'), (r'δ\^осн', 'δ^{осн}'), (r'R\^альт', 'R^{альт}'), (r'R\^осн', 'R^{осн}'), (r'A\^альт', 'A^{альт}'), (r'A\^осн', 'A^{осн}'),
        (r'10\^\(−3/2\)', '10^{−3/2}')]
def md(t):
    for a, b in REPL:
        t = re.sub(a, b, t)
    return t
def rich(par_, t, size=None, bold=False, italic=False):
    for part in re.split(r'([_^]\{[^}]*\})', md(t)):
        if not part:
            continue
        if part[:2] in ('_{', '^{'):
            run = par_.add_run(part[2:-1])
            if part[0] == '_':
                run.font.subscript = True
            else:
                run.font.superscript = True
        else:
            run = par_.add_run(part)
        run.bold, run.italic = bold, italic
        if size:
            run.font.size = Pt(size)
    return par_

# ---------------------------------------------------------------- OMML helpers
M = 'xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"'
def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
def r(t, plain=False):
    pr = '<m:rPr><m:sty m:val="p"/></m:rPr>' if plain else ''
    return f'<m:r>{pr}<m:t xml:space="preserve">{esc(t)}</m:t></m:r>'
def sub(b, s):
    return f'<m:sSub><m:e>{b}</m:e><m:sub>{s}</m:sub></m:sSub>'
def sup(b, s):
    return f'<m:sSup><m:e>{b}</m:e><m:sup>{s}</m:sup></m:sSup>'
def subsup(b, s, p):
    return f'<m:sSubSup><m:e>{b}</m:e><m:sub>{s}</m:sub><m:sup>{p}</m:sup></m:sSubSup>'
def frac(a, b):
    return f'<m:f><m:num>{a}</m:num><m:den>{b}</m:den></m:f>'
def sqrt(a):
    return f'<m:rad><m:radPr><m:degHide m:val="1"/></m:radPr><m:deg/><m:e>{a}</m:e></m:rad>'
def par(a, o='(', c=')'):
    return f'<m:d><m:dPr><m:begChr m:val="{o}"/><m:endChr m:val="{c}"/></m:dPr><m:e>{a}</m:e></m:d>'
def integral(lo, body):
    return f'<m:nary><m:naryPr><m:chr m:val="∫"/><m:supHide m:val="1"/></m:naryPr><m:sub>{lo}</m:sub><m:sup/><m:e>{body}</m:e></m:nary>'
def eq(doc, xml, label=None):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p._p.append(parse_xml(f'<m:oMath {M}>{xml}</m:oMath>'))
    if label:
        run = p.add_run(f'\t\t({label})')
    return p

# ---------------------------------------------------------------- document
doc = Document()
sec = doc.sections[0]
sec.page_height, sec.page_width = Cm(29.7), Cm(21.0)
for side in ('left_margin', 'right_margin'):
    setattr(sec, side, Cm(2.0))
sec.top_margin, sec.bottom_margin = Cm(2.0), Cm(2.0)
st = doc.styles['Normal']
st.font.name = 'Times New Roman'
st.font.size = Pt(11)
st.element.rPr.rFonts.set(qn('w:eastAsia'), 'Times New Roman')
st.paragraph_format.space_after = Pt(4)
for name, size in (('Heading 1', 14), ('Heading 2', 12), ('Title', 16)):
    s = doc.styles[name]
    s.font.name = 'Times New Roman'
    s.font.size = Pt(size)
    s.font.color.rgb = RGBColor(0, 0, 0)
    rpr = s.element.get_or_add_rPr()
    rf = rpr.find(qn('w:rFonts'))
    if rf is None:
        rf = parse_xml('<w:rFonts xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"/>')
        rpr.append(rf)
    for a in ('w:ascii', 'w:hAnsi', 'w:cs', 'w:eastAsia'):
        rf.set(qn(a), 'Times New Roman')
    for a in ('w:asciiTheme', 'w:hAnsiTheme', 'w:cstheme', 'w:eastAsiaTheme'):
        if rf.get(qn(a)) is not None:
            del rf.attrib[qn(a)]

hdr = sec.header.paragraphs[0]
hdr.text = "Проєкт доповнень до українського звіту G2 · пакет G2-M4.A · для наукового рев'ю · не є канонічною редакцією"
hdr.runs[0].font.size = Pt(8)
fp = sec.footer.paragraphs[0]
fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
fr = fp.add_run()
fr._r.append(parse_xml('<w:fldSimple xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" w:instr="PAGE"><w:r><w:t>1</w:t></w:r></w:fldSimple>'))

def H1(t): doc.add_heading(t, level=1)
def H2(t): doc.add_heading(t, level=2)
def P(t, bold=False, italic=False, size=None):
    p = doc.add_paragraph()
    rich(p, t, size, bold, italic)
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    return p
def B(t):
    p = doc.add_paragraph(style='List Bullet')
    rich(p, t)
    return p

tabno = [0]
def table(caption, header, rows, widths=None, fs=8.5):
    tabno[0] += 1
    cp = doc.add_paragraph()
    cr = cp.add_run(f'Таблиця Е.{tabno[0]}. {caption}')
    cr.bold = True
    cr.font.size = Pt(10)
    t = doc.add_table(rows=1, cols=len(header))
    t.style = 'Table Grid'
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(header):
        c = t.rows[0].cells[i]
        c.text = ''
        rich(c.paragraphs[0], h, fs, True)
    for row in rows:
        cells = t.add_row().cells
        for i, v in enumerate(row):
            cells[i].text = ''
            rich(cells[i].paragraphs[0], str(v), fs)
    if widths:
        for row in t.rows:
            for i, w in enumerate(widths):
                row.cells[i].width = Cm(w)
    doc.add_paragraph()
    return t

fig = [0]
def figure(png, caption, width=17.0):
    fig[0] += 1
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.add_run().add_picture(os.path.join(FIG, png), width=Cm(width))
    c = doc.add_paragraph()
    c.alignment = WD_ALIGN_PARAGRAPH.CENTER
    rich(c, f'Рисунок Е.{fig[0]}. {caption}', 9.5, False, True)

# ---------------------------------------------------------------- content
doc.add_paragraph('Додаток Е (проєкт). G2-M4.A: незалежна перевірка повних двокрокових траєкторій на альтернативному сімействі сіток', style='Title')
P("Статус документа: ПРОЄКТ ДОПОВНЕНЬ ДЛЯ НАУКОВОГО РЕВ'Ю (Issue #44). Цей файл не замінює канонічний звіт "
  "«Metakompozyt_G2_Naukovyi_zvit_UA.docx». Канонічні редакції 0.2 і 0.3 локально відсутні (HOLD_WORD_INPUT); "
  "у репозиторії й у теці завантажень є лише редакція 0.1 із перевіреним SHA-256 "
  "85ef072b9be4a6408570e4719aa97be04fa9e014ce589755bb046ca22bf7abc3. Після надання файлу 0.3 цей текст, таблиці й рисунки "
  "пропонується вставити як новий Додаток Е; детальні виведення інтеграла взаємодії (EDI), COD, J-інтеграла, критерію MTS "
  "і перетворення одиниць КІН у канонічному звіті зберігаються без змін.", italic=True)

table('Джерела та ідентифікатори пакета', ['Об’єкт', 'Значення'], [
    ['Наукове завдання', 'Issue #44, етап G2-M4.A (G2-M4.B не дозволено)'],
    ['Гілка / база', 'research/g2-m4-alt-mesh-family-20261121 на брифі bbb7c25 (містить PR #43 9eb5c88 і PR #41 92636e5)'],
    ['Пререєстрація і політика', f"G2_M4_PREREGISTRATION.md, G2_M4_POLICY_v1.json (SHA-256 {L['policySHA256'].lower()})"],
    ['Коміт обчислень ланцюгів', PROV['chainRunCommit']],
    ['Коміт аналізу', L['gitHead']],
    ['Альтернативне С0 (запис / сітка)', f"{PROV['s0RecordSHA256']} / {PROV['s0MeshSHA256']}"],
    ['MATLAB', 'R2023a, PDE Toolbox 3.10; запобіжник ≥ 5 ГіБ вільної пам’яті'],
], widths=[4.5, 12.5])

H1('Е.1. Наукове питання і гіпотези')
P("У G2-M3 (PR #41) м’які та жорсткі кільця відхилили власні траєкторії від однорідної (+0,0905 мм і −0,0602 мм при s = 33,4 мм), "
  "а ефект шляху R_шлях частково компенсував прямий матеріальний ефект. Перевірка на іншій сітці виконувалась лише для вже "
  "вибраної кінцевої геометрії. Пакет G2-M4.A відповідає на питання: чи відтворюється вся двокрокова історія, якщо від стану С0 "
  "незалежно перебудувати сітку зовнішньої області та полігони інтерфейсів кілець?")
B('H1: на альтернативному сімействі знаки й величини бічних відхилень м’яких і жорстких траєкторій від власної однорідної траєкторії стабільні в межах заздалегідь заданих допусків.')
B('H2: R_прям і R_шлях зберігають знак, а їхні відхилення від 1 узгоджуються за успадкованим правилом робастності G2-M3.')
B('Нульова гіпотеза: зміна знака бічного відхилення, R_шлях − 1 або R_прям − 1 при s = 29,4 чи 33,4 мм, або порушення критерію STABLE, спростовує стійкість повної траєкторії для відповідного матеріалу.')

H1('Е.2. Модель і умови')
P("Плоский напружений стан; матриця E_m = 3268,115 МПа, ν = 0,35; товщина 12,7 мм; одна зосереджена сила P = 1 Н донизу в точці "
  "(254; 203,2) мм; шарнір (25,4; 0) і каток (482,6; 0) мм. Три отвори R = 6,35 мм із центрами (152,4; 69,85), (152,4; 120,65), "
  "(152,4; 171,45) мм; номінальні ідеально зчеплені кільця 6,35 < r < 19,05 мм з E_r/E_m = 0,5 (м’які) або 2 (жорсткі), ν_r = 0,35. "
  "Усі властивості ілюстративні. Початкова тріщина: від (101,6; 0) до (101,6; 25,4) мм. Два кроки по 4 мм; третього кроку немає.")

H1('Е.3. Методика (робочі формули, використані без змін)')
P("Локальний базис вершини: t — напрям росту, n = R(+90°)·t. Підписані КІН визначаються двома незалежними способами; "
  "напрямок наступного кроку обчислюється за критерієм максимальних тангенціальних напружень.")
H2('Е.3.1. Інтеграл взаємодії (EDI) з полями Вільямса')
eq(doc, sub(r('I'), r('α')) + r('=') + integral(r('A'), par(sub(r('σ'), r('ij')) + frac(r('∂') + subsup(r('u'), r('i'), r('aux,α')), r('∂') + sub(r('x'), r('1'))) + r('+') + subsup(r('σ'), r('ij'), r('aux,α')) + frac(r('∂') + sub(r('u'), r('i')), r('∂') + sub(r('x'), r('1'))) + r('−') + sub(r('σ'), r('kl')) + subsup(r('ε'), r('kl'), r('aux,α')) + sub(r('δ'), r('1j')), '[', ']') + frac(r('∂q'), r('∂') + sub(r('x'), r('j'))) + r('dA')), 'Е.1')
eq(doc, sub(r('K'), r('α')) + r('=') + frac(sup(r('E'), r('′')), r('2')) + sub(r('I'), r('α')) + r(',  α ∈ {I, II},   ', True) + sup(r('E'), r('′')) + r('=') + sub(r('E'), r('m')) + r('  (плоский напружений стан)', True), 'Е.2')
P("Допоміжні поля — головні члени Вільямса з K_aux = 1; вагова функція q = 1 при r ≤ r_in, лінійно спадає до 0 при r = r_out "
  "і інтерполюється функціями форми T6 за вузловими значеннями. Основна область 0,4–2,6 мм, контрольні 0,2–1,0; 0,4–1,6; 0,8–2,6; "
  "1,2–2,4 мм; квадратура 6×6 (контроль 4×4). Усі 2443 елементи з ненульовим ∇q лежать у захищеному ядрі p010 і тільки в матриці "
  "(перевіряється на кожній сітці).")
H2('Е.3.2. J-інтеграл і енергетична швидкість')
eq(doc, r('J') + r('=') + integral(r('A'), par(sub(r('σ'), r('ij')) + frac(r('∂') + sub(r('u'), r('i')), r('∂') + sub(r('x'), r('1'))) + r('−') + r('W') + sub(r('δ'), r('1j')), '[', ']') + frac(r('∂q'), r('∂') + sub(r('x'), r('j'))) + r('dA')) + r(',     ', True) + r('G') + r('=') + frac(sup(sub(r('K'), r('I')), r('2')) + r('+') + sup(sub(r('K'), r('II')), r('2')), sup(r('E'), r('′'))), 'Е.3')
H2('Е.3.3. Розкриття берегів (COD), незалежне від EDI')
eq(doc, sub(r('K'), r('app')) + par(r('r')) + r('=') + frac(sup(r('E'), r('′')), r('8')) + sqrt(frac(r('2π'), r('r'))) + par(r('Δ·n,  Δ·t'), '[', ']') + r(',   ', True) + r('Δ') + r('=') + r('u') + par(r('верхній'), '(', ')') + r('−') + r('u') + par(r('нижній'), '(', ')') + r(',   ', True) + r('K') + par(r('r')) + r('≈') + sub(r('K'), r('0')) + r('+') + sub(r('K'), r('1')) + r('r'), 'Е.4')
P("Використовуються лише збережені пари вузлів-близнюків верхнього і нижнього берегів останнього прямолінійного сегмента; "
  "лінійна апроксимація методом найменших квадратів на 0,1 ≤ r ≤ 1,5 мм, K = K_0. Методичний зсув EDI/COD у величині КІН становить "
  f"≈ {num(100*(((1+L['altRows']['soft'][0]['EDI_COD_offset_H'])**0.5)-1),2)} % (у величині G ≈ {num(100*L['altRows']['soft'][0]['EDI_COD_offset_H'],2)} %) і однаковий в обох сімействах сіток.")
H2('Е.3.4. Критерій MTS і рекурентне правило кроку')
eq(doc, r('θ') + r('=') + r('2 atan2', True) + par(r('−2') + sub(r('K'), r('II')) + r(',  ') + sub(r('K'), r('I')) + r('+') + sqrt(sup(sub(r('K'), r('I')), r('2')) + r('+') + r('8') + sup(sub(r('K'), r('II')), r('2')))) + r(',    ', True) + sub(r('K'), r('I')) + r('sin θ', True) + r('+') + sub(r('K'), r('II')) + par(r('3 cos θ', True) + r('−') + r('1')) + r('=') + r('0'), 'Е.5')
eq(doc, sub(r('t'), r('new')) + r('=') + r('cos θ', True) + r(' t') + r('+') + r('sin θ', True) + r(' n,     ') + sub(r('x'), r('вершини')) + r('←') + sub(r('x'), r('вершини')) + r('+') + r('4 мм', True) + r('·') + sub(r('t'), r('new')), 'Е.6')
H2('Е.3.5. Одиниці')
eq(doc, sub(r('K'), r('на 1 кН')) + par(r('МПа√м', True), '[', ']') + r('=') + sqrt(r('1000')) + r('·') + sub(r('K'), r('1 Н')) + par(r('МПа√мм', True), '[', ']'), 'Е.7')
eq(doc, r('G') + par(r('Дж/м²', True), '[', ']') + r('=') + r('1000') + r('·') + r('G') + par(r('Н/мм', True), '[', ']') + r(',     ') + r('G ∝ ', True) + sup(r('P'), r('2')), 'Е.8')
P("Множник √1000 поєднує масштаб навантаження 1 Н → 1 кН (×1000) і перехід √мм → √м (×10^(−3/2)). Напрямок MTS не залежить від P.")
H2('Е.3.6. Розклад енергетичного відгуку і правила невизначеності')
eq(doc, sub(r('R'), r('прям')) + r('=') + frac(sub(r('G'), r('M')) + par(sub(r('Γ'), r('H')), '[', ']'), sub(r('G'), r('H')) + par(sub(r('Γ'), r('H')), '[', ']')) + r(',   ') + sub(r('R'), r('шлях')) + r('=') + frac(sub(r('G'), r('M')) + par(sub(r('Γ'), r('M')), '[', ']'), sub(r('G'), r('M')) + par(sub(r('Γ'), r('H')), '[', ']')) + r(',   ') + sub(r('R'), r('заг')) + r('=') + sub(r('R'), r('прям')) + sub(r('R'), r('шлях')), 'Е.9')
P("Кожне відношення обчислюється лише з величин свого сімейства сіток. Основне правило: U = max(розкид п’яти контурів, |R_4×4 − R|, "
  f"|R_COD − R|, U_сітки для відношень між різними сітками), U_сітки = {sci(L['U_mesh'],2)} (успадковано з PR #38, не переоцінювалось); "
  "ефект розрізнено, якщо |R − 1| > 2U і знак за COD збігається. Консервативне правило: U_конс = R·(δG_a + δG_b), δG = |G_EDI − G_COD|/G_EDI. "
  "Бічне відхилення δ = (x_M − x_H)·n_H; U_δ(29,4) = 4·U_Δθ0, U_δ(33,4) = 8·U_Δθ0 + 4·U_Δθ1 (радіани × мм).")
P("Критерії між сімействами (заздалегідь зареєстровані): STABLE, якщо sign δ^альт = sign δ^осн, |Δ| ≤ 0,25|δ^осн|, |Δ| ≤ 0,010 мм і "
  "|δ^альт| > 2·max(d_H, U_δ^альт), де Δ = δ^альт − δ^осн, d_H — розбіжність вершин однорідних траєкторій; MARGINAL — той самий знак, "
  "але порушено одну з інших умов; NONROBUST — зміна знака або нерозрізнене δ^альт. Для відношень: ROBUST, якщо знак R − 1 збігається і "
  "|R^альт − R^осн| ≤ 0,25|R^осн − 1| + 2U_сітки; SENSITIVE — той самий знак, більша різниця; NOT_ROBUST — зміна знака.")

H1('Е.4. Альтернативне сімейство сіток')
fe = [s for s in FEAS['stages'] if s['name'] == 'F2_ALT_S0'][0]['info']
table('Основне і альтернативне сімейства', ['Параметр', 'Основне (famA, PR #41)', 'Альтернативне (famB_m4alt)'], [
    ['Генератор С0', 'g2_join_protected_mesh (WP2)', 'той самий; відтворення famA перевірено побітно'],
    ['Hface інтерфейсів / Hmax', '1,5 мм / 6 мм', '1,0 мм / 5 мм'],
    ['Хорд на кожному інтерфейсі', '76', '112'],
    ['Площа полігона кільця, мм²', num(L['bandArea']['orig_mm2'][0], 4), num(L['bandArea']['alt_mm2'][0], 4)],
    ['Відносна різниця площ', '—', f"+{num(100*L['bandArea']['altOverOrig_minus1'],4)} % (номінал {num(L['bandArea']['nominal_mm2'],4)} мм²)"],
    ['T3 у С0', '28 151', f"{fe['independence']['alt_T3']:,}".replace(',', ' ')],
    ['Ядро p010 / комір / q-елементи', '2788 / 128 / 2443 (спільні за політикою)', '2788 / 128 / 2443 (спільні за політикою)'],
    ['Аудити С0', 'з’єднання 13/13, 38/38, 24/24', 'з’єднання 13/13, 38/38, 24/24'],
    ['Збіг зовнішніх вузлів із famA', '—', f"{fe['independence']['exteriorNodesCoincidingWithFamA']} з {fe['independence']['exteriorNodesAlt']} (фіксовані вершини меж)"],
], widths=[5.0, 5.6, 6.4])
P("Розкриття незалежності: за політикою обидва сімейства використовують те саме заморожене ядро p010 біля вершини (2788 T3), "
  "аналітичний комір (128 T3) і напрямну зону вершини радіусом 15 мм. Тому G2-M4.A вимірює чутливість повної траєкторії до "
  "дискретизації зовнішньої області та полігонів кілець (включно з їхньою площею), а не до дискретизації безпосередньо біля вершини.")
figure('m4a_fig3_interface_meshes.png', 'Сітки стану С0 поблизу нижнього кільця: а) основне сімейство, 76-кутний інтерфейс; б) альтернативне сімейство, 112-кутний інтерфейс. Колір — фаза елемента за перевіреною картою фаз; пунктир — номінальне коло r = 19,05 мм. Побудовано за даними MATLAB.', 16.5)

H1('Е.5. Перебіг обчислень і контроль якості')
runs = PROV['runs']
UA_RUNS = [('M4.0: здійсненність (лише сітка)', 'HOLD (хибний): нижній регістр реєстру SHA порівнювався зі шляхом у змішаному регістрі; сітку не будували'),
 ('діагностичний вираз', 'відтворено помилку пошуку (хеш є, ключ у змішаному регістрі відсутній); файлів немає'),
 ('M4.0: здійсненність (лише сітка)', 'FEASIBLE: F0 джерела, F1 famA побітно, F2 альтернативне С0 13/13, 38/38, 24/24, фази OK'),
 ('С0ALT, сухий режим', 'PASS, файлів немає'),
 ('С0ALT, запис (-Run)', 'С0ALT записано (34 641 T3, 3×112 хорд)'),
 ('сухий режим: однорідна, м’які, жорсткі', 'PASS: власні K альтернативного С0 і прогноз кроку 1; файлів немає'),
 ('запис (-Run): однорідна, м’які, жорсткі', 'STEP_CAP на стані 2 для всіх трьох ланцюгів'),
 ('аналіз', 'GO; регресія основного сімейства 0; вердикт FULL_PATH_ROBUST'),
 ('тести підробок', '24/24; прийняті ланцюги незмінні'),
 ('рисунки', 'замінено: перекриття легенд/заголовків, відсутній гліф, десяткові крапки'),
 ('рисунки', 'замінено: перекриття підписів на рис. 1в'),
 ('рисунки', 'остаточні рисунки, усі перевірено візуально')]
assert len(UA_RUNS) == len(runs)
table('Журнал запусків G2-M4 (MATLAB R2023a)', ['№', 'Режим', 'Коміт', 'Результат'], [[str(i + 1), UA_RUNS[i][0], x['head'], UA_RUNS[i][1]] for i, x in enumerate(runs)], widths=[0.8, 4.4, 1.8, 10.0], fs=8)
steps = PROV['steps']
table('Кроки альтернативних ланцюгів: сітка, аудит, КІН (на 1 кН, МПа·√м)', ['Траєкторія', 'Крок', 'Вершина (x; y), мм', 'Поворот, °', 'T3', 'Аудит', 'Хорди', 'K_I', 'K_II'],
      [[x['material'], x['step'], f"({num(x['tip'][0],7)}; {num(x['tip'][1],7)})", num(x['turn'], 6, True), f"{x['T3']:,}".replace(',', ' '), x['audit'], x['chords'], num(x['KI'], 6), num(x['KII'], 6, True)] for x in steps],
      widths=[2.2, 1.0, 4.0, 1.9, 1.3, 1.2, 1.6, 1.7, 1.9], fs=7.5)
fc = FAULTS['cases']
P(f"Тотожність M0 (двофазний розв’язувач при E_r = E_m) з однорідним H1 на всіх трьох альтернативних станах: "
  f"{'побітно' if all(L['altM0IdentityBitwise']) else 'НЕ побітно'}. Розв’язок С0 м’якого і жорсткого ланцюгів побітно збігається з розв’язками Msoft/Mstiff "
  f"однорідного ланцюга на тій самій сітці: {yes(all(L['altS0CrossChainBitwise'].values()))}. Регресія основного сімейства відносно реєстру аналізу G2-M3: "
  f"максимальне відносне відхилення {num(L['originalRegressionMaxRelDev'],0)}. Тести підробок, перезапусків і відтворення: "
  f"{sum(1 for c in fc if c['pass'])}/{len(fc)}; прийняті ланцюги PR #41, С0 і альтернативні ланцюги після тестів незмінні: {yes(FAULTS['acceptedUnchanged'])}.")
def ua(t):
    for a, b in [('2 steps computed; mesh, phase, u, EDI, COD identical (4 solves per state)', '2 кроки обчислено; сітка, фази, u, EDI, COD тотожні (4 розв’язки на стан)'),
                 ('promoted 1, computed 0, state equals accepted', 'підвищено 1, обчислено 0, стан дорівнює прийнятому'),
                 ('reused 1, computed 0, tree identical', 'повторно використано 1, обчислено 0, дерево незмінне'),
                 ('reused 2, computed 0, tree identical', 'повторно використано 2, обчислено 0, дерево незмінне'),
                 ('DRY_S0ALT_NO_FILES, root listing unchanged', 'DRY_S0ALT_NO_FILES, вміст кореня незмінний'),
                 ('STEP_CAP, tree identical', 'STEP_CAP, дерево незмінне'),
                 ('computed 2, identical 1', 'обчислено 2, тотожність: так'), ('same 1', 'дерево незмінне: так'),
                 (' promoted 1 computed 0', ' підвищено 1, обчислено 0'), (' reused 1 computed 0', ' повторно використано 1, обчислено 0'),
                 ('reused 2 computed 0', 'повторно використано 2, обчислено 0')]:
        t = t.replace(a, b)
    return t
table('Тести підробок, перезапусків і відтворення', ['Тест', 'Очікування', 'Отримано', 'Так/ні'],
      [[c['id'], ua(c['expect']), ua(c['observed']), yes(c['pass'])] for c in fc], widths=[5.4, 4.6, 5.4, 1.4], fs=7)
figure('m4a_fig4_tip_q_support.png', 'Зона вагової функції q на альтернативній сітці м’якого ланцюга при s = 33,4 мм: а) 2443 елементи з ненульовим ∇q (усі в матриці, у ядрі p010); б) ядро p010, комір і напрямна зона вершини радіусом 15 мм. Відстань від вершини до найближчого кільця ≈ 42 мм. Побудовано за даними MATLAB.', 16.5)

H1('Е.6. Результати')
rows = []
for fam, key in (('осн.', 'originalRows'), ('альт.', 'altRows')):
    for m, lab in (('soft', 'м’які'), ('stiff', 'жорсткі')):
        for x in L[key][m]:
            rows.append([lab, fam, num(x['s_mm'], 1), num(x['R_direct']['R'], 6), sci(x['R_direct']['U'], 1), num(x['R_path']['R'], 6), sci(x['R_path']['U'], 1), num(x['R_total']['R'], 6), yes(x['R_path']['resolved']) if x['s_mm'] > 26 else '—', yes(x['R_total']['resolvedCons'])])
table('Розклад G в обох сімействах (U — основна похибка)', ['Кільця', 'Сім.', 's, мм', 'R_прям', 'U', 'R_шлях', 'U', 'R_заг', 'R_шлях розрізн.', 'R_заг конс.'], rows,
      widths=[1.6, 1.1, 1.0, 1.9, 1.5, 1.9, 1.5, 1.9, 1.9, 1.6], fs=7.5)
figure('m4a_fig2_ratios.png', 'Відношення енергетичної швидкості вивільнення в основному (суцільні лінії) й альтернативному (штрихові) сімействах сіток: а) прямий ефект на однорідній траєкторії; б) ефект власної траєкторії; в) загальний ефект. Смуги — ±2U за основним правилом. Побудовано за даними MATLAB.')
rows = []
for m, lab in (('soft', 'м’які'), ('stiff', 'жорсткі')):
    for e in L['classes'][m]['separation']:
        rows.append([lab, num(e['s_mm'], 1), num(e['delta_orig_mm'], 6, True), num(e['delta_alt_mm'], 6, True), sci(e['Delta_mm'], 2, True), num(100 * e['Delta_rel'], 3, True), sci(e['d_H_mm'], 2), sci(e['U_sep_alt_mm'], 2), sci(e['U_sep_cons_alt_mm'], 2), e['class']])
table('Бічні відхилення від власної однорідної траєкторії та їхня стабільність', ['Кільця', 's, мм', 'δ осн., мм', 'δ альт., мм', 'Δ, мм', 'Δ/δ, %', 'd_H, мм', 'U_δ альт.', 'U_δ конс.', 'Клас'], rows,
      widths=[1.5, 1.0, 1.9, 1.9, 1.8, 1.4, 1.6, 1.6, 1.6, 1.4], fs=7.5)
figure('m4a_fig1_paths.png', 'а) Положення тріщини і кілець (схематично, за геометрією моделі); б) бічне відхилення δ матеріальних траєкторій від однорідної в кожному сімействі (смуги ±2U_δ; затінення — допуск STABLE); в) розбіжність вершин між сімействами для однорідної, м’якої й жорсткої траєкторій. Побудовано за даними MATLAB.')
rows = []
for m, lab in (('soft', 'м’які'), ('stiff', 'жорсткі')):
    for e in L['classes'][m]['ratios']:
        nm = {'R_direct': 'R_прям', 'R_path': 'R_шлях', 'R_total': 'R_заг'}[e['ratio']]
        rows.append([lab, nm, num(e['s_mm'], 1), num(e['R_orig'], 6), num(e['R_alt'], 6), sci(e['dR'], 2, True), num(100 * e['dR_rel_of_effect'], 3, True), e['class']])
table('Класифікація відношень між сімействами', ['Кільця', 'Відношення', 's, мм', 'осн.', 'альт.', 'ΔR', 'ΔR/(R−1), %', 'Клас'], rows, widths=[1.6, 2.0, 1.1, 2.2, 2.2, 2.0, 2.4, 2.2], fs=8)
rows = []
for p, lab in (('homogeneous', 'однорідна'), ('soft', 'м’які'), ('stiff', 'жорсткі')):
    for x in L['crossFamily'][p]:
        rows.append([lab, num(x['s_mm'], 1), sci(x['tipDrift_mm'], 2) if x['tipDrift_mm'] > 0 else '0', sci(x['headingDrift_deg'], 2, True) if x['headingDrift_deg'] != 0 else '0', sci(x['KI_relDrift'], 2, True), sci(x['KII_relDrift'], 2, True), sci(x['G_relDrift'], 2, True), sci(x['thetaDrift_deg'], 2, True)])
table('Розбіжність між сімействами для кожної траєкторії', ['Траєкторія', 's, мм', '|Δx| вершини, мм', 'Δкурсу, °', 'ΔK_I/K_I', 'ΔK_II/K_II', 'ΔG/G', 'Δθ_MTS, °'], rows, widths=[2.0, 1.1, 2.4, 2.0, 2.0, 2.2, 2.0, 2.0], fs=8)
figure('m4a_fig5_K.png', 'Підписані КІН на 1 кН у вершинах трьох траєкторій в обох сімействах (а, б) і відносна зміна між сімействами (в). Побудовано за даними MATLAB.')

H1('Е.7. Невизначеність, площа полігонів і обмеження')
ba = L['bandArea']
P(f"Площа 112-кутного кільця більша за 76-кутне на {num(100*ba['altOverOrig_minus1'],4)} %. Зміна R_прям між сімействами становить "
  f"0,07–0,10 % від самого ефекту (|R − 1|) з тим самим знаком, що й збільшення активної площі (підсилення м’яких кілець трохи зростає, "
  f"екранування жорстких — теж). Орієнтовна величина |R^осн − 1|·|A^альт/A^осн − 1| дорівнює {sci(ba['areaHeuristic']['soft'][1],2)} (м’які, s = 33,4 мм) "
  f"і {sci(ba['areaHeuristic']['stiff'][1],2)} (жорсткі) проти спостережених ΔR_прям {sci(L['classes']['soft']['ratios'][2]['dR'],2,True)} і "
  f"{sci(L['classes']['stiff']['ratios'][2]['dR'],2,True)}. Це узгоджується з геометричним походженням зміни, але є лише евристикою: "
  "площа полігона і дискретизація змінюються одночасно і в цьому пакеті не розділяються.")
P("Основне правило розрізняє всі R_прям, R_шлях і R_заг (крім R_шлях = 1 при s = 25,4 мм) в обох сімействах. За консервативним правилом "
  "(≈ ±3,5 %) жодне відношення не розрізнене в жодному сімействі, тоді як бічні відхилення розрізнені й за консервативним правилом "
  "(наприклад, м’які кільця при s = 33,4 мм: δ ≈ 0,0905 мм > 2·U_δ,конс ≈ 0,036 мм). Обидва вердикти наведено поруч.")
B('Спільне ядро p010 (2788 T3), комір і напрямна зона вершини: чутливість до дискретизації безпосередньо біля вершини цим пакетом не перевірена.')
B('Два кроки по 4 мм; ідеальне зчеплення; ілюстративні модулі; плоский напружений стан; одна сила 1 Н. Висновки стосуються лише умовних чисельних траєкторій.')
B('Немає тверджень про фізичний початок росту, зупинку, тріщиностійкість, розшарування, CZM, проникнення в кільце чи відповідність експерименту Cornell.')
B('Атрибуція внесків окремих кілець (G2-M4.B) не виконувалась і не дозволена до рішення за цим рев’ю.')

H1('Е.8. Висновок пакета (ОЧІКУЄ НАУКОВОГО РЕВ’Ю)')
P(f"Заздалегідь зареєстрований вердикт: {L['verdict']}. Усі чотири бічні відхилення мають клас STABLE (зміна між сімействами ≤ 0,05 % "
  "для м’яких і ≤ 0,01 % для жорстких кілець, розбіжність однорідних вершин d_H ≤ 1,2·10⁻⁴ мм), усі вісім класифікацій R_прям і R_шлях "
  "при s = 29,4 і 33,4 мм — ROBUST. Результати G2-M3 щодо відхилення траєкторій і протидії ефекту шляху прямому ефекту відтворено "
  "на незалежно перебудованому зовнішньому/інтерфейсному сімействі сіток. Рішення GO/HOLD для етапу G2-M4.B — за дослідником.", bold=False)

H1('Е.9. Кандидати до журналу G2-REV (потребують рішення дослідника)')
table('Пропоновані записи', ['Кандидат', 'Де виникло', 'Що було → чому → що стало', 'Перевірка', 'Стан'], [
    ['G2-REV-M4-005', 'Перевірка джерел M4.0 (запуск 1)', 'Порівнювався нижній регістр реєстру SHA з шляхом у змішаному регістрі → хибний HOLD → шлях також переведено в нижній регістр (коміт b84dea3)', 'Повтор: F0 PASS, F1 побітно, F2 FEASIBLE', 'виправлено; потребує підтвердження'],
    ['G2-REV-M4-006', 'Пререєстрація M4.A', 'Обидва сімейства мають спільне ядро p010 → обмеження незалежності → явне розкриття в політиці та розділі Е.4', '—', 'пропозиція тексту'],
    ['G2-REV-M4-007', 'Інтерпретація ΔR_прям', 'Зміна 0,07 % ефекту збігається за знаком і порядком із +0,069 % площі полігона → не приписувати лише МСЕ-дискретизації', 'Евристика, без розділення', 'потребує наукового рішення'],
    ['G2-REV-M4-008', 'Word-звіт', 'Редакції 0.2/0.3 відсутні локально → HOLD_WORD_INPUT → цей окремий DOCX-проєкт замість канонічної редакції', 'SHA 0.1 перевірено', 'очікує файл 0.3'],
], widths=[2.3, 2.8, 6.2, 3.0, 2.7], fs=7.5)

H1('Е.10. Відкриті питання для наукового рев’ю')
B('Чи достатньо незалежності зовнішньої/інтерфейсної дискретизації, чи потрібна окремо кваліфікована альтернатива ядра p010 (нова політика)?')
B('Чи приймається евристичне пояснення зміни R_прям площею полігона, чи потрібне окреме розділення (наприклад, 112-кутний інтерфейс за Hmax 6)?')
B('Дозвіл, відкладення або зміна постановки G2-M4.B (16 конфігурацій на замороженому S2) і пріоритет майбутньої задачі наскрізної траєкторії без перетину кілець.')

doc.core_properties.title = 'G2-M4.A: пропоновані доповнення до українського звіту'
doc.core_properties.author = 'NewMetacomp G2'
doc.core_properties.language = 'uk-UA'
doc.save(OUT)
print('WROTE', OUT, hashlib.sha256(open(OUT, 'rb').read()).hexdigest())
