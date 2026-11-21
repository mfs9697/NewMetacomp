# -*- coding: utf-8 -*-
"""Build the canonical Ukrainian G2 Word report, revision 0.4 (CANDIDATE), from verified v0.3.

Input: reports/G2/Metakompozyt_G2_Naukovyi_zvit_UA_v0_3_Naskrizne_ruinuvannia_bez_interfeisu.docx
       (SHA-256 49daba7e..., checked before anything is read) and committed evidence only:
       matlab/g2/evidence/m4_20261121 (G2-M4.A) and matlab/g2/evidence/m4b_20261121 (G2-M4.B).
Output: reports/G2/Metakompozyt_G2_Naukovyi_zvit_UA_v0_4_Atrybutsiia_kilets_kandydat.docx
Everything in v0.3 is kept; the edits are listed in the v0.4 revision record (Appendix Ж.10 and the
journal lines). Appendix Е integrates the reviewed M4.A proposal with decisions A/B of the Issue #44
review; Appendix Ж is the new M4.B section, marked «очікує наукової перевірки».

usage: python scripts/report/build_g2_report_v0_4.py <repo> <out.docx>
"""
import copy, hashlib, json, os, re, sys
from docx import Document
from docx.shared import Pt, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import qn
from docx.text.paragraph import Paragraph

REPO = sys.argv[1]
OUT = sys.argv[2]
SRC = os.path.join(REPO, 'reports', 'G2', 'Metakompozyt_G2_Naukovyi_zvit_UA_v0_3_Naskrizne_ruinuvannia_bez_interfeisu.docx')
SRC_SHA = '49daba7ef064d2dccd679abfc77a79e122f67e9cbd22c30da9ddb924c03b0b40'
assert hashlib.sha256(open(SRC, 'rb').read()).hexdigest() == SRC_SHA, 'v0.3 SHA-256 mismatch: HOLD_WORD_INPUT'
EA = os.path.join(REPO, 'matlab', 'g2', 'evidence', 'm4_20261121')
EB = os.path.join(REPO, 'matlab', 'g2', 'evidence', 'm4b_20261121')
LA = json.load(open(os.path.join(EA, 'analysis', 'LEDGER.json'), encoding='utf-8'))
FA = json.load(open(os.path.join(EA, 'faults', 'm4a_faults_summary.json'), encoding='utf-8'))
FEAS = json.load(open(os.path.join(EA, 'feasibility', 'FEASIBILITY.json'), encoding='utf-8'))
PA = json.load(open(os.path.join(EA, 'PROVENANCE.json'), encoding='utf-8'))
LB = json.load(open(os.path.join(EB, 'analysis', 'LEDGER.json'), encoding='utf-8'))
FB = json.load(open(os.path.join(EB, 'faults', 'FAULTS.json'), encoding='utf-8'))
PB = json.load(open(os.path.join(EB, 'PROVENANCE.json'), encoding='utf-8'))
B2 = json.load(open(os.path.join(EB, 'campaign', 'B2_BASELINES.json'), encoding='utf-8'))
RUNB = json.load(open(os.path.join(EB, 'campaign', 'RUN.json'), encoding='utf-8'))

# ---------------------------------------------------------------- number formatting
def num(x, nd=6, sign=False):
    s = f"{x:+.{nd}f}" if sign else f"{x:.{nd}f}"
    return s.replace('-', '−').replace('.', ',')
SUP = str.maketrans('-0123456789', '⁻⁰¹²³⁴⁵⁶⁷⁸⁹')
def sci(x, nd=2, sign=False):
    if x == 0:
        return '0'
    s = f"{x:+.{nd}e}" if sign else f"{x:.{nd}e}"
    m, e = s.split('e')
    return m.replace('-', '−').replace('.', ',') + '·10' + str(int(e)).translate(SUP)
def pct(x, nd=3, sign=True):
    return num(100 * x, nd, sign) + ' %'
def yes(b):
    return 'так' if b else 'ні'

REPL = [(r'U_δ\^альт', 'U_{δ}^{альт}'), (r'U_δ,конс', 'U_{δ,конс}'), (r'U_Δθ0', 'U_{Δθ0}'), (r'U_Δθ1', 'U_{Δθ1}'), (r'U_δ', 'U_{δ}'),
        (r'R_прям', 'R_{прям}'), (r'R_шлях', 'R_{шлях}'), (r'R_заг', 'R_{заг}'), (r'R_4×4', 'R_{4×4}'), (r'R_COD', 'R_{COD}'),
        (r'U_сітки', 'U_{сітки}'), (r'U_конс', 'U_{конс}'), (r'δG_a', 'δG_{a}'), (r'δG_b', 'δG_{b}'), (r'G_EDI', 'G_{EDI}'), (r'G_COD', 'G_{COD}'),
        (r'E_m\b', 'E_{m}'), (r'E_r\b', 'E_{r}'), (r'ν_r\b', 'ν_{r}'), (r'K_aux', 'K_{aux}'), (r'r_in\b', 'r_{in}'), (r'r_out\b', 'r_{out}'), (r'K_0\b', 'K_{0}'),
        (r'x_M\b', 'x_{M}'), (r'x_H\b', 'x_{H}'), (r'n_H\b', 'n_{H}'), (r'd_H\b', 'd_{H}'), (r'K_II\b', 'K_{II}'), (r'K_I\b', 'K_{I}'), (r'θ_MTS', 'θ_{MTS}'),
        (r'δ\^альт', 'δ^{альт}'), (r'δ\^осн', 'δ^{осн}'), (r'R\^альт', 'R^{альт}'), (r'R\^осн', 'R^{осн}'), (r'A\^альт', 'A^{альт}'), (r'A\^осн', 'A^{осн}'),
        (r'10\^\(−3/2\)', '10^{−3/2}'), (r'F_G\b', 'F_{G}'), (r'F_θ', 'F_{θ}'), (r'f_([123])\b', r'f_{\1}'), (r'I_(123|12|13|23)\b', r'I_{\1}'),
        (r'φ_([123])\b', r'φ_{\1}'), (r'G_0\b', 'G_{0}'), (r'θ_0\b', 'θ_{0}'), (r'U_Q\b', 'U_{Q}'), (r'Q_e\b', 'Q_{e}'), (r'Q_COD', 'Q_{COD}'),
        (r'd_k\b', 'd_{k}'), (r'e_k\b', 'e_{k}'), (r'a_k\b', 'a_{k}'), (r'f_θ,([123])', r'f_{θ,\1}'), (r'I_ij\b', 'I_{ij}'), (r'f_i\b', 'f_{i}'),
        (r'φ_i\b', 'φ_{i}'), (r'ω_e\b', 'ω_{e}'), (r'p_e\b', 'p_{e}'), (r'U_R\b', 'U_{R}'), (r'd_S\b', 'd_{S}'), (r'd_0\b', 'd_{0}'),
        (r'θ_COD,k', 'θ_{COD,k}'), (r'θ_EDI,k', 'θ_{EDI,k}'), (r'x_t\b', 'x_{t}'), (r'y_n\b', 'y_{n}')]
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
            run.font.subscript = part[0] == '_'
            run.font.superscript = part[0] == '^'
        else:
            run = par_.add_run(part)
        if bold:
            run.bold = True
        if italic:
            run.italic = True
        if size:
            run.font.size = Pt(size)
    return par_

# ---------------------------------------------------------------- OMML
MNS = 'xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"'
def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
def r(t, plain=False):
    pr = '<m:rPr><m:sty m:val="p"/></m:rPr>' if plain else ''
    return f'<m:r>{pr}<m:t xml:space="preserve">{esc(t)}</m:t></m:r>'
def sub(b, s): return f'<m:sSub><m:e>{b}</m:e><m:sub>{s}</m:sub></m:sSub>'
def sup(b, s): return f'<m:sSup><m:e>{b}</m:e><m:sup>{s}</m:sup></m:sSup>'
def subsup(b, s, p): return f'<m:sSubSup><m:e>{b}</m:e><m:sub>{s}</m:sub><m:sup>{p}</m:sup></m:sSubSup>'
def frac(a, b): return f'<m:f><m:num>{a}</m:num><m:den>{b}</m:den></m:f>'
def sqrt(a): return f'<m:rad><m:radPr><m:degHide m:val="1"/></m:radPr><m:deg/><m:e>{a}</m:e></m:rad>'
def par(a, o='(', c=')'): return f'<m:d><m:dPr><m:begChr m:val="{o}"/><m:endChr m:val="{c}"/></m:dPr><m:e>{a}</m:e></m:d>'
def integral(lo, body): return f'<m:nary><m:naryPr><m:chr m:val="∫"/><m:supHide m:val="1"/></m:naryPr><m:sub>{lo}</m:sub><m:sup/><m:e>{body}</m:e></m:nary>'
def nsum(lo, body, hi=''):
    hide = '<m:supHide m:val="1"/>' if not hi else ''
    return f'<m:nary><m:naryPr><m:chr m:val="∑"/>{hide}</m:naryPr><m:sub>{lo}</m:sub><m:sup>{hi}</m:sup><m:e>{body}</m:e></m:nary>'

# ---------------------------------------------------------------- open v0.3
doc = Document(SRC)
P0 = list(doc.paragraphs)
T0 = list(doc.tables)

def set_text_keep_runs(p, old, new):
    """Replace text inside the run(s) of an existing paragraph without touching its formatting."""
    for run in p.runs:
        if old in run.text:
            run.text = run.text.replace(old, new)
            return True
    full = p.text
    assert old in full, (old, full)
    p.runs[0].text = full.replace(old, new)
    for run in p.runs[1:]:
        run.text = ''
    return True

def insert_after(ref, text='', style=None, italic=False, bold=False, size=None):
    new = OxmlElement('w:p')
    ref._p.addnext(new)
    p = Paragraph(new, ref._parent)
    if style:
        p.style = doc.styles[style]
    if text:
        rich(p, text, size, bold, italic)
    return p

def add_row(t, values, size=8.5, bold=False):
    cells = t.add_row().cells
    for i, v in enumerate(values):
        cells[i].text = ''
        rich(cells[i].paragraphs[0], str(v), size, bold)

# ---------------------------------------------------------------- 1. front matter edits
set_text_keep_runs(P0[2], 'WP2–G2-M3', 'WP2–G2-M4.B')
set_text_keep_runs(P0[5], 'Редакція 0.3', 'Редакція 0.4 (кандидат, очікує наукової перевірки)')
for p in doc.sections[0].footer.paragraphs:
    if 'ред. 0.3' in p.text:
        set_text_keep_runs(p, 'ред. 0.3', 'ред. 0.4 (кандидат)')
abst = insert_after(P0[11], "Доповнення редакції 0.4. Пакет G2-M4.A (Додаток Е) повторив усі три двокрокові траєкторії на незалежно "
    "перебудованому сімействі зовнішніх сіток і 112-кутних меж кілець; заздалегідь зареєстрований вердикт FULL_PATH_ROBUST прийнято "
    "науковим рев’ю з обмеженнями (спільне ядро вершини). Пакет G2-M4.B (Додаток Ж, очікує наукової перевірки) розклав прямий "
    "матеріальний вплив на заморожених тріщині й сітці S2 на внески окремих кілець: за однакової активної площі розміщення одного "
    "м’якого кільця змінює G від −3,6 % до +4,4 %, найближче кільце визначає напрямок MTS (+1,31° для м’якого), а сумарний ефект трьох "
    "кілець (+2,2 %) є невеликою різницею внесків протилежних знаків. Взаємодії кілець розрізнені лише за основним правилом.", style='Normal')
abst.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
t = T0[0]
for row in t.rows:
    k = row.cells[0].text.strip()
    if k == 'Версія':
        row.cells[1].text = ''
        rich(row.cells[1].paragraphs[0], '0.4 — КАНДИДАТ: інтегровано Додаток Е (G2-M4.A, рішення A і B наукового рев’ю) та новий Додаток Ж (G2-M4.B, очікує наукової перевірки); редакції 0.1 і 0.3 збережено без змін', 8.5)
    elif k == 'Стан даних':
        row.cells[1].text = ''
        rich(row.cells[1].paragraphs[0], 'Перевірені результати до draft PR #46 (97c9562, G2-M4.A) і нові розрахунки G2-M4.B (запуск run_20261121_194814_009; коміт доказів 47af26c), 21.11.2026', 8.5)
    elif k == 'Рівень перевірки':
        row.cells[1].text = ''
        rich(row.cells[1].paragraphs[0], 'G2-M4.B обчислено в MATLAB R2023a за політикою v2 (16 логічних випадків, 38/38 тестів відмов); Word зібрано скриптом лише з комітованих доказів; усі сторінки перевірено візуально після рендерингу Word', 8.5)
set_text_keep_runs(P0[28], 'наскрізна тріщина', 'наскрізна тріщина; Е — G2-M4.A; Ж — G2-M4.B (кандидат)')
# chronology
add_row(T0[3], ['G2-M4.A / #46, завдання #44', 'Альтернативне С0 (112 хорд), три нові двокрокові ланцюги з власними K; 24/24 тести відмов', 'FULL_PATH_ROBUST; прийнято з обмеженнями (спільне ядро вершини)'])
add_row(T0[3], ['G2-M4.B / новий PR, завдання #47', 'Заморожена S2, 2³ масок × c = 0,5; 2 (16 логічних, 15 розв’язків); незалежний оракул кілець; 38/38 тестів', 'Атрибуція f_{i}, I_{ij}, I_{123}; очікує наукової перевірки'])
# stability table
add_row(T0[8], ['Повна двокрокова траєкторія', 'G2-M4.A: зовнішня сітка й 112-кутні межі перебудовані; усі δ STABLE, усі R ROBUST', 'Незалежна дискретизація біля самої вершини (ядро p010 спільне)'])
add_row(T0[8], ['Внески окремих кілець', 'G2-M4.B: 15 розв’язків на тій самій сітці S2; ∅ = H1 і {1,2,3} = Msoft/Mstiff побітно', 'Збіжність підмножинних ефектів за сіткою; дія консервативного правила на взаємодії'])
# revision journal table
add_row(T0[9], ['G2-M4.A, перевірка джерел', 'Реєстр SHA у нижньому регістрі порівнювався зі шляхом у змішаному регістрі → хибний HOLD', 'Обидва боки зведено до нижнього регістру (b84dea3); повтор F0/F1/F2 PASS; G2-REV-M4-005.'])
add_row(T0[9], ['G2-M4.B, політика v2', 'Повторний checkout змінив закінчення рядків (CRLF) і SHA політики', 'Відновлено байти LF, тотожні blob у git, до будь-якого запуску; G2-REV-M4B-001.'])
add_row(T0[9], ['G2-M4.B, рисунки', 'Фігурні дужки масок у TeX і відсутній у шрифті символ ∅; примітка перекривала легенду', 'Екрановано дужки, G₀/θ₀ замість ∅, примітку перенесено в заголовок легенди; запуск рисунків замінено; G2-REV-M4B-003.'])
add_row(T0[9], ['G2-M4.B, захист доказів', 'Підроблені, підписані повторно чи з оберненим знаком K_II записи; переривання; повтор', '38/38 перевірок відмовили або відновили без нового FEM; повтор 15 записів побітно тотожний.'])
# corrections list (10.1)
last = P0[143]
for t_ in ['Рішення A (21.11.2026): вердикт FULL_PATH_ROBUST пакета G2-M4.A прийнято лише в області перевірки; спільне ядро p010, комір, напрямна зона й q-область — обов’язкове обмеження; нова переатестація ядра зараз не потрібна.',
           'Рішення B: зміну R_прям між сімействами формулювати як «узгоджується з впливом різниці полігональних площ; внески геометрії й сітки не відокремлено»; перевірку 112-кутник/Hmax 6 не замовлено.',
           'Рішення C: дозволено лише G2-M4.B на замороженій однорідній S2 (16 логічних випадків), без поширення тріщини, змішаних модулів, M4.C чи CZM; після G2-M4.B — обов’язкова друга зупинка для рев’ю.',
           'Рішення D: канонічну редакцію 0.3 відновлено з перевіреним SHA-256; її інтегровано в редакцію 0.4 лише після локальної перевірки байтів.']:
    last = insert_after(last, t_, style='List Bullet')
# section 12 note
n12 = insert_after(P0[166], "Доповнення 0.4: пункти 12.1 і 12.2 виконано як G2-M4.A (Додаток Е) та G2-M4.B (Додаток Ж). Згідно з рішенням C "
    "наступним пріоритетом після рев’ю G2-M4.B є окрема задача довшої траєкторії лише в матриці з перевіркою обходу або досягнення "
    "інтерфейсу; вона автоматично не запускається.", style='Normal')
n12.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
# sources
last = P0[188]
for t_ in ['[Р8] NewMetacomp, draft PR #46 — G2-M4.A, незалежне сімейство сіток (97c9562).',
           '[Р9] NewMetacomp, Issue #47 / draft PR #48 (бриф) і новий draft PR реалізації — G2-M4.B, політика G2_M4B_POLICY_v2.json (SHA-256 758f4394…b37b).',
           ]:
    last = insert_after(last, t_, style='Normal')
insert_after(P0[192], '[Л5] Shapley, L. S. (1953). A value for n-person games. In: Contributions to the Theory of Games II, Annals of Mathematics Studies 28, 307–317. DOI: 10.1515/9781400881970-018.', style='Normal')
# revision journal line at the end of Д
jr = insert_after(P0[242], "Журнал редакцій: 0.4 (кандидат, 21.11.2026) — архівовано 0.3 без змін (SHA-256 49daba7e…0b40); інтегровано Додаток Е "
    "(G2-M4.A) з рішеннями A–D наукового рев’ю; додано Додаток Ж (G2-M4.B, нові розрахунки MATLAB R2023a, очікує наукової перевірки); "
    "доповнено анотацію, таблицю статусу, хронологію, таблицю стійкості, журнал корекцій, розділ 12 і джерела. Редакція 0.2 локально "
    "недоступна і не відтворювалась.", style='Normal')

# ---------------------------------------------------------------- appendix helpers (appended at the end)
def page_break():
    p = doc.add_paragraph()
    p.add_run().add_break(WD_BREAK.PAGE)
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
def eq(xml, label=None):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p._p.append(parse_xml(f'<m:oMath {MNS}>{xml}</m:oMath>'))
    if label:
        p.add_run(f'\t({label})')
    return p
CNT = {'tab': 0, 'fig': 0, 'L': ''}
def table(caption, header, rows, widths=None, fs=8.5):
    CNT['tab'] += 1
    cp = doc.add_paragraph(style='Caption')
    rich(cp, f"Таблиця {CNT['L']}.{CNT['tab']}. {caption}")
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
def figure(path, caption, width=16.5):
    CNT['fig'] += 1
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.add_run().add_picture(path, width=Cm(width))
    c = doc.add_paragraph(style='Caption')
    rich(c, f"Рис. {CNT['L']}.{CNT['fig']}. {caption}")

# ================================================================= Appendix Е (G2-M4.A, reviewed)
page_break()
CNT.update(tab=0, fig=0, L='Е')
FIGA = os.path.join(EA, 'report')
H1('Додаток Е. G2-M4.A: незалежна перевірка повних двокрокових траєкторій на альтернативному сімействі сіток')
P("СТАТУС: ПРИЙНЯТО З ОБМЕЖЕННЯМИ (наукове рев’ю Issue #44, рішення A і B від 21.11.2026). Текст інтегровано з проєкту доповнень "
  "draft PR #46 (DOCX SHA-256 ca4e398c…e79c) без зміни чисел; змінено лише статус, формулювання щодо площі полігонів (рішення B) і "
  "стан записів G2-REV. Детальні виведення EDI, COD, J, MTS і перетворення одиниць основного тексту (розділ 4, Додаток А) не змінено; "
  "у Е.3 їх наведено в робочій формі, використаній у розрахунках.", italic=True)
table('Джерела та ідентифікатори пакета', ['Об’єкт', 'Значення'], [
    ['Наукове завдання', 'Issue #44, етап G2-M4.A'],
    ['Гілка / PR', 'research/g2-m4-alt-mesh-family-20261121, draft PR #46 (97c9562)'],
    ['Пререєстрація і політика', f"G2_M4_PREREGISTRATION.md, G2_M4_POLICY_v1.json (SHA-256 {LA['policySHA256'].lower()})"],
    ['Коміт обчислень / аналізу', f"{PA['chainRunCommit']} / {LA['gitHead']}"],
    ['Альтернативне С0 (запис / сітка)', f"{PA['s0RecordSHA256']} / {PA['s0MeshSHA256']}"],
    ['MATLAB', 'R2023a, PDE Toolbox; запобіжник ≥ 5 ГіБ вільної пам’яті'],
], widths=[4.5, 12.0])
H2('Е.1. Наукове питання і гіпотези')
P("У G2-M3 (PR #41) м’які та жорсткі кільця відхилили власні траєкторії від однорідної (+0,0905 мм і −0,0602 мм при s = 33,4 мм), "
  "а ефект шляху R_шлях частково компенсував прямий матеріальний ефект. Пакет G2-M4.A перевіряє, чи відтворюється вся двокрокова "
  "історія, якщо від стану С0 незалежно перебудувати сітку зовнішньої області та полігони інтерфейсів кілець.")
B('H1: знаки й величини бічних відхилень м’яких і жорстких траєкторій від власної однорідної траєкторії стабільні в межах заздалегідь заданих допусків.')
B('H2: R_прям і R_шлях зберігають знак, а їхні відхилення від 1 узгоджуються за успадкованим правилом робастності G2-M3.')
B('Нульова гіпотеза: зміна знака бічного відхилення, R_шлях − 1 або R_прям − 1 при s = 29,4 чи 33,4 мм, або порушення критерію STABLE.')
H2('Е.2. Модель і умови')
P("Плоский напружений стан; E_m = 3268,115 МПа, ν = 0,35; товщина 12,7 мм; сила P = 1 Н донизу в точці (254; 203,2) мм; шарнір "
  "(25,4; 0) і каток (482,6; 0) мм. Три отвори R = 6,35 мм із центрами (152,4; 69,85), (152,4; 120,65), (152,4; 171,45) мм; кільця "
  "6,35 < r < 19,05 мм з E_r/E_m = 0,5 або 2, ν_r = 0,35. Початкова тріщина від (101,6; 0) до (101,6; 25,4) мм; два кроки по 4 мм.")
H2('Е.3. Методика (робочі формули, використані без змін)')
P("Локальний базис вершини: t — напрям росту, n = R(+90°)·t. Підписані КІН визначаються двома незалежними способами; напрямок "
  "наступного кроку — за критерієм максимальних тангенціальних напружень.")
eq(sub(r('I'), r('α')) + r('=') + integral(r('A'), par(sub(r('σ'), r('ij')) + frac(r('∂') + subsup(r('u'), r('i'), r('aux,α')), r('∂') + sub(r('x'), r('1'))) + r('+') + subsup(r('σ'), r('ij'), r('aux,α')) + frac(r('∂') + sub(r('u'), r('i')), r('∂') + sub(r('x'), r('1'))) + r('−') + sub(r('σ'), r('kl')) + subsup(r('ε'), r('kl'), r('aux,α')) + sub(r('δ'), r('1j')), '[', ']') + frac(r('∂q'), r('∂') + sub(r('x'), r('j'))) + r('dA')), 'Е.1')
eq(sub(r('K'), r('α')) + r('=') + frac(sup(r('E'), r('′')), r('2')) + sub(r('I'), r('α')) + r(',  α ∈ {I, II},   ', True) + sup(r('E'), r('′')) + r('=') + sub(r('E'), r('m')) + r('  (плоский напружений стан)', True), 'Е.2')
P("Допоміжні поля — головні члени Вільямса з K_aux = 1; q = 1 при r ≤ r_in, лінійно спадає до 0 при r = r_out (інтерполяція T6). "
  "Основна область 0,4–2,6 мм, контрольні 0,2–1,0; 0,4–1,6; 0,8–2,6; 1,2–2,4 мм; квадратура 6×6 (контроль 4×4). Усі 2443 елементи з "
  "ненульовим ∇q лежать у захищеному ядрі p010 і тільки в матриці.")
eq(r('J') + r('=') + integral(r('A'), par(sub(r('σ'), r('ij')) + frac(r('∂') + sub(r('u'), r('i')), r('∂') + sub(r('x'), r('1'))) + r('−') + r('W') + sub(r('δ'), r('1j')), '[', ']') + frac(r('∂q'), r('∂') + sub(r('x'), r('j'))) + r('dA')) + r(',     ', True) + r('G') + r('=') + frac(sup(sub(r('K'), r('I')), r('2')) + r('+') + sup(sub(r('K'), r('II')), r('2')), sup(r('E'), r('′'))), 'Е.3')
eq(sub(r('K'), r('app')) + par(r('r')) + r('=') + frac(sup(r('E'), r('′')), r('8')) + sqrt(frac(r('2π'), r('r'))) + par(r('Δ·n,  Δ·t'), '[', ']') + r(',   ', True) + r('Δ') + r('=') + r('u') + par(r('верхній')) + r('−') + r('u') + par(r('нижній')) + r(',   ', True) + r('K') + par(r('r')) + r('≈') + sub(r('K'), r('0')) + r('+') + sub(r('K'), r('1')) + r('r'), 'Е.4')
P("Для COD використано збережені пари вузлів-близнюків останнього прямолінійного сегмента; лінійна апроксимація на 0,1 ≤ r ≤ 1,5 мм, "
  f"K = K_0. Методичний зсув EDI/COD у величині КІН ≈ {num(100*(((1+LA['altRows']['soft'][0]['EDI_COD_offset_H'])**0.5)-1),2)} % "
  f"(у G ≈ {num(100*LA['altRows']['soft'][0]['EDI_COD_offset_H'],2)} %), однаковий в обох сімействах.")
eq(r('θ') + r('=') + r('2 atan2', True) + par(r('−2') + sub(r('K'), r('II')) + r(',  ') + sub(r('K'), r('I')) + r('+') + sqrt(sup(sub(r('K'), r('I')), r('2')) + r('+') + r('8') + sup(sub(r('K'), r('II')), r('2')))) + r(',    ', True) + sub(r('K'), r('I')) + r('sin θ', True) + r('+') + sub(r('K'), r('II')) + par(r('3 cos θ', True) + r('−') + r('1')) + r('=') + r('0'), 'Е.5')
eq(sub(r('t'), r('new')) + r('=') + r('cos θ', True) + r(' t') + r('+') + r('sin θ', True) + r(' n,     ') + sub(r('x'), r('вершини')) + r('←') + sub(r('x'), r('вершини')) + r('+') + r('4 мм', True) + r('·') + sub(r('t'), r('new')), 'Е.6')
eq(sub(r('K'), r('на 1 кН')) + par(r('МПа√м', True), '[', ']') + r('=') + sqrt(r('1000')) + r('·') + sub(r('K'), r('1 Н')) + par(r('МПа√мм', True), '[', ']'), 'Е.7')
eq(r('G') + par(r('Дж/м²', True), '[', ']') + r('=') + r('1000') + r('·') + r('G') + par(r('Н/мм', True), '[', ']') + r(',     ') + r('G ∝ ', True) + sup(r('P'), r('2')), 'Е.8')
P("Множник √1000 поєднує масштаб навантаження 1 Н → 1 кН (×1000) і перехід √мм → √м (×10^(−3/2)). Напрямок MTS не залежить від P.")
eq(sub(r('R'), r('прям')) + r('=') + frac(sub(r('G'), r('M')) + par(sub(r('Γ'), r('H')), '[', ']'), sub(r('G'), r('H')) + par(sub(r('Γ'), r('H')), '[', ']')) + r(',   ') + sub(r('R'), r('шлях')) + r('=') + frac(sub(r('G'), r('M')) + par(sub(r('Γ'), r('M')), '[', ']'), sub(r('G'), r('M')) + par(sub(r('Γ'), r('H')), '[', ']')) + r(',   ') + sub(r('R'), r('заг')) + r('=') + sub(r('R'), r('прям')) + sub(r('R'), r('шлях')), 'Е.9')
P("Основне правило: U = max(розкид п’яти контурів, |R_4×4 − R|, |R_COD − R|, U_сітки для відношень між сітками), "
  f"U_сітки = {sci(LA['U_mesh'],2)}; ефект розрізнено, якщо |R − 1| > 2U і знак за COD збігається. Консервативне правило: "
  "U_конс = R·(δG_a + δG_b), δG = |G_EDI − G_COD|/G_EDI. Критерії між сімействами: STABLE, якщо знак δ збігається, |Δ| ≤ 0,25|δ^осн|, "
  "|Δ| ≤ 0,010 мм і |δ^альт| > 2·max(d_H, U_δ^альт); для відношень ROBUST, якщо знак R − 1 збігається і |R^альт − R^осн| ≤ 0,25|R^осн − 1| + 2U_сітки.")
H2('Е.4. Альтернативне сімейство сіток')
fe = [s for s in FEAS['stages'] if s['name'] == 'F2_ALT_S0'][0]['info']
table('Основне і альтернативне сімейства', ['Параметр', 'Основне (famA, PR #41)', 'Альтернативне (famB_m4alt)'], [
    ['Генератор С0', 'g2_join_protected_mesh (WP2)', 'той самий; відтворення famA перевірено побітно'],
    ['Hface інтерфейсів / Hmax', '1,5 мм / 6 мм', '1,0 мм / 5 мм'],
    ['Хорд на кожному інтерфейсі', '76', '112'],
    ['Площа полігона кільця, мм²', num(LA['bandArea']['orig_mm2'][0], 4), num(LA['bandArea']['alt_mm2'][0], 4)],
    ['Відносна різниця площ', '—', f"+{num(100*LA['bandArea']['altOverOrig_minus1'],4)} % (номінал {num(LA['bandArea']['nominal_mm2'],4)} мм²)"],
    ['T3 у С0', '28 151', f"{fe['independence']['alt_T3']:,}".replace(',', ' ')],
    ['Ядро p010 / комір / q-елементи', '2788 / 128 / 2443 (спільні за політикою)', '2788 / 128 / 2443 (спільні за політикою)'],
    ['Аудити С0', 'з’єднання 13/13, 38/38, 24/24', 'з’єднання 13/13, 38/38, 24/24'],
], widths=[5.0, 5.5, 6.0])
P("Обмеження незалежності (обов’язкове за рішенням A): обидва сімейства мають спільне заморожене ядро p010 біля вершини (2788 T3), "
  "комір (128 T3), напрямну зону радіусом 15 мм і q-область. Отже, G2-M4.A вимірює чутливість повної траєкторії до дискретизації "
  "зовнішньої області й полігонів кілець, а не до дискретизації безпосередньо біля вершини; це не доказ фізичного росту, початку чи зупинки тріщини.")
figure(os.path.join(FIGA, 'm4a_fig3_interface_meshes.png'), 'Сітки стану С0 поблизу нижнього кільця: а) основне сімейство, 76-кутний інтерфейс; б) альтернативне, 112-кутний. Побудовано за даними MATLAB.')
H2('Е.5. Перебіг обчислень і контроль якості')
steps = PA['steps']
table('Кроки альтернативних ланцюгів: сітка, аудит, КІН (на 1 кН, МПа·√м)', ['Траєкторія', 'Крок', 'Вершина (x; y), мм', 'Поворот, °', 'T3', 'Аудит', 'Хорди', 'K_I', 'K_II'],
      [[{'homogeneous': 'однорідна', 'soft': 'м’які', 'stiff': 'жорсткі'}.get(x['material'], x['material']), x['step'], f"({num(x['tip'][0],7)}; {num(x['tip'][1],7)})", num(x['turn'], 6, True), f"{x['T3']:,}".replace(',', ' '), x['audit'], x['chords'], num(x['KI'], 6), num(x['KII'], 6, True)] for x in steps],
      widths=[2.0, 0.9, 3.9, 1.8, 1.3, 1.2, 1.6, 1.7, 1.8], fs=7.5)
fc = FA['cases']
P(f"Тотожність M0 з однорідним H1 на всіх трьох альтернативних станах: {'побітно' if all(LA['altM0IdentityBitwise']) else 'НЕ побітно'}. "
  f"Регресія основного сімейства відносно G2-M3: максимальне відносне відхилення {num(LA['originalRegressionMaxRelDev'],0)}. "
  f"Тести підробок, перезапусків і відтворення: {sum(1 for c in fc if c['pass'])}/{len(fc)}; прийняті ланцюги незмінні: {yes(FA['acceptedUnchanged'])}. "
  "Перший запуск перевірки джерел дав хибний HOLD через різний регістр рядків у пошуку реєстру SHA (виправлено, G2-REV-M4-005).")
figure(os.path.join(FIGA, 'm4a_fig4_tip_q_support.png'), 'Зона вагової функції q на альтернативній сітці м’якого ланцюга при s = 33,4 мм: а) 2443 елементи з ненульовим ∇q (усі в матриці); б) ядро p010, комір і напрямна зона радіусом 15 мм. Побудовано за даними MATLAB.')
H2('Е.6. Результати')
rows = []
for fam, key in (('осн.', 'originalRows'), ('альт.', 'altRows')):
    for m, lab in (('soft', 'м’які'), ('stiff', 'жорсткі')):
        for x in LA[key][m]:
            rows.append([lab, fam, num(x['s_mm'], 1), num(x['R_direct']['R'], 6), sci(x['R_direct']['U'], 1), num(x['R_path']['R'], 6), sci(x['R_path']['U'], 1), num(x['R_total']['R'], 6), yes(x['R_total']['resolvedCons'])])
table('Розклад G в обох сімействах (U — основна похибка)', ['Кільця', 'Сім.', 's, мм', 'R_прям', 'U', 'R_шлях', 'U', 'R_заг', 'R_заг конс.'], rows,
      widths=[1.6, 1.1, 1.0, 2.0, 1.6, 2.0, 1.6, 2.0, 1.8], fs=7.5)
figure(os.path.join(FIGA, 'm4a_fig2_ratios.png'), 'Відношення G в основному (суцільні) й альтернативному (штрихові) сімействах: а) прямий ефект; б) ефект власної траєкторії; в) загальний ефект. Смуги — ±2U за основним правилом. Побудовано за даними MATLAB.')
rows = []
for m, lab in (('soft', 'м’які'), ('stiff', 'жорсткі')):
    for e in LA['classes'][m]['separation']:
        rows.append([lab, num(e['s_mm'], 1), num(e['delta_orig_mm'], 6, True), num(e['delta_alt_mm'], 6, True), sci(e['Delta_mm'], 2, True), num(100 * e['Delta_rel'], 3, True), sci(e['d_H_mm'], 2), e['class']])
table('Бічні відхилення від власної однорідної траєкторії', ['Кільця', 's, мм', 'δ осн., мм', 'δ альт., мм', 'Δ, мм', 'Δ/δ, %', 'd_H, мм', 'Клас'], rows,
      widths=[1.6, 1.1, 2.3, 2.3, 2.1, 1.7, 1.9, 1.6], fs=8)
figure(os.path.join(FIGA, 'm4a_fig1_paths.png'), 'а) Положення тріщини і кілець (схематично); б) бічне відхилення δ у кожному сімействі (смуги ±2U_δ; затінення — допуск STABLE); в) розбіжність вершин між сімействами. Побудовано за даними MATLAB.')
rows = []
for m, lab in (('soft', 'м’які'), ('stiff', 'жорсткі')):
    for e in LA['classes'][m]['ratios']:
        nm_ = {'R_direct': 'R_прям', 'R_path': 'R_шлях', 'R_total': 'R_заг'}[e['ratio']]
        rows.append([lab, nm_, num(e['s_mm'], 1), num(e['R_orig'], 6), num(e['R_alt'], 6), sci(e['dR'], 2, True), num(100 * e['dR_rel_of_effect'], 3, True), e['class']])
table('Класифікація відношень між сімействами', ['Кільця', 'Відношення', 's, мм', 'осн.', 'альт.', 'ΔR', 'ΔR/(R−1), %', 'Клас'], rows, widths=[1.6, 2.0, 1.1, 2.2, 2.2, 2.0, 2.4, 2.0], fs=8)
figure(os.path.join(FIGA, 'm4a_fig5_K.png'), 'Підписані КІН на 1 кН у вершинах трьох траєкторій в обох сімействах (а, б) і відносна зміна між сімействами (в). Побудовано за даними MATLAB.')
H2('Е.7. Невизначеність, площа полігонів і обмеження')
ba = LA['bandArea']
P(f"Площа 112-кутного кільця більша за 76-кутне на {num(100*ba['altOverOrig_minus1'],4)} %. Зміна R_прям між сімействами "
  f"({sci(LA['classes']['soft']['ratios'][2]['dR'],2,True)} для м’яких і {sci(LA['classes']['stiff']['ratios'][2]['dR'],2,True)} для жорстких кілець при s = 33,4 мм) "
  "становить 0,07–0,10 % від самого ефекту. Прийняте формулювання (рішення B): зміна узгоджується з впливом різниці полігональних "
  "площ; внески геометрії й сітки не відокремлено.")
P("Основне правило розрізняє всі R_прям, R_шлях і R_заг (крім R_шлях = 1 при s = 25,4 мм) в обох сімействах. За консервативним правилом "
  "(≈ ±3,5 %) жодне відношення не розрізнене, тоді як бічні відхилення розрізнені й за ним. Обидва вердикти збережено.")
B('Спільне ядро p010, комір, напрямна зона і q-область: дискретизацію безпосередньо біля вершини не перевірено (рішення A).')
B('Два кроки по 4 мм; ідеальне зчеплення; ілюстративні модулі; плоский напружений стан; одна сила 1 Н.')
B('Немає тверджень про фізичний початок росту, зупинку, тріщиностійкість, розшарування, CZM чи відповідність експерименту Cornell.')
H2('Е.8. Висновок пакета і рішення наукового рев’ю')
P(f"Вердикт: {LA['verdict']}. Усі чотири бічні відхилення — STABLE; усі вісім класифікацій R_прям і R_шлях при s = 29,4 і 33,4 мм — ROBUST. "
  "Рішення A: ПРИЙНЯТО З ОБМЕЖЕННЯМИ в точно визначеній області перевірки. Рішення B: ПРИЙНЯТО ЯК УЗГОДЖЕНЕ, НЕ ПРИЧИННЕ. "
  "Рішення C: дозволено G2-M4.B (Додаток Ж).")
table('Записи G2-REV пакета G2-M4.A після рев’ю', ['Запис', 'Що було → чому → що стало', 'Стан'], [
    ['G2-REV-M4-005', 'Хибний HOLD перевірки джерел через різний регістр рядків → виправлено (b84dea3), повтор PASS', 'ЗБЕРЕЖЕНО як виправлену помилку інструментарію'],
    ['G2-REV-M4-006', 'Спільне ядро p010, комір, напрямна зона і q → обмеження незалежності', 'ПРИЙНЯТО як обов’язкове обмеження (рішення A)'],
    ['G2-REV-M4-007', 'ΔR_прям узгоджується з +0,069 % площі полігона', 'ПРИЙНЯТО як узгоджене, не причинне (рішення B)'],
    ['G2-REV-M4-008', 'Канонічні 0.2/0.3 були відсутні → окремий DOCX-проєкт', 'ЗАКРИТО: 0.3 відновлено й перевірено (рішення D); 0.2 недоступна'],
], widths=[2.6, 9.0, 5.0], fs=8)

# ================================================================= Appendix Ж (G2-M4.B, candidate)
page_break()
CNT.update(tab=0, fig=0, L='Ж')
FIGB = os.path.join(EB, 'report')
A = LB['attribution']
names = A[0]['termNames']
ix = {n: i for i, n in enumerate(names)}
CLS = {'RESOLVED_BOTH': 'обидва', 'RESOLVED_PRIMARY_ONLY': 'лише осн.', 'UNRESOLVED': 'не розрізн.', 'RESOLVED_CONSERVATIVE_ONLY': 'лише конс.'}
H1('Додаток Ж. G2-M4.B: атрибуція трьох кілець і неадитивність на замороженій тріщині S2')
P("СТАТУС: ОЧІКУЄ НАУКОВОЇ ПЕРЕВІРКИ (REVIEW_STOP_B). Усі результати цього додатка — нові розрахунки MATLAB R2023a за заздалегідь "
  "закомітованою політикою G2_M4B_POLICY_v2.json; жодне тлумачення не є самостійно затвердженим. «Розрізнено» означає чисельну "
  "стійкість за вибраними критеріями оцінювачів, а не фізично встановлений ефект.", italic=True)
table('Джерела та ідентифікатори пакета', ['Об’єкт', 'Значення'], [
    ['Наукове завдання', 'Issue #47 (рішення C рев’ю Issue #44); бриф — draft PR #48 (9467e21)'],
    ['Політика / пререєстрація', f"G2_M4B_POLICY_v2.json (SHA-256 {RUNB['policySHA256']}), G2_M4B_PREREGISTRATION.md; закомічено до розрахунків (c75a82b)"],
    ['Набір джерел (SHA-256)', RUNB['sourceSetSHA256']],
    ['Заморожена сітка S2', f"{RUNB['meshSHA256']} (28 625 T3, 58 161 вузол, 3×76 хорд)"],
    ['Запуск / коміт коду', f"outputs/g2_m4b_ring_factorial_v1/run_20261121_194814_009 / {RUNB['gitHead'][:7]}"],
    ['Аналіз / тести / рисунки', 'analysis_run_20261121_194953_501 (GO) / fault_20261121_195051_593 (38/38) / g2_m4b_report run_20261121_195428_941'],
    ['Еталони', 'CASE_S2_H1, CASE_S2_Msoft, CASE_S2_Mstiff запуску D PR #38 (тотожні запуску C PR #35)'],
], widths=[4.0, 12.5], fs=8)
H2('Ж.1. Наукове питання і гіпотези')
P("На одній і тій самій замороженій тріщині, сітці й навантаженні потрібно визначити, яку частину прямого пружного впливу на "
  "швидкість вивільнення енергії G і на напрямок MTS дає кожне з трьох ідеально зчеплених кілець, і яку — їхні парні та потрійна "
  "взаємодії. Це атрибуція матеріалу за фіксованої геометрії, а не дослідження траєкторії, початку чи зупинки тріщини.")
B('H1: окремі кільця неоднаково впливають на F_G і F_θ. Спростування: відсутність розрізнених відмінностей за однакової активної площі.')
B('H2: порядок важливості кілець за F_G не збігається з порядком за F_θ. Спростування: збіг порядку за розрізненими різницями.')
B('H3: взаємодії I_ij або I_123 суттєві. Нульовий або нерозрізнений результат допустимий.')
H2('Ж.2. Постановка')
P("Еталон — збережена однорідна тріщина S2 (s = 33,4 мм; вершина (103,409; 33,192) мм, дотична 76,45°) з первинними 76-кутними "
  "межами кілець; сітка, навантаження і закріплення незмінні. Кільця нумеровано за зростанням y: 1 — (152,4; 69,85), 2 — (152,4; 120,65), "
  "3 — (152,4; 171,45) мм. Неактивне кільце має модуль матриці (це не отвір і не розшарований шар); активне — E = c·E_m, c ∈ {0,5; 2}; "
  "отвори в усіх випадках порожні. Вісім масок активності × два контрасти = 16 логічних випадків; випадок без активних кілець спільний "
  "для обох контрастів (15 розв’язків).")
figure(os.path.join(FIGB, 'm4b_fig1_schematic.png'), 'Схематично: а) пластина, заморожена тріщина S2, номери кілець, відстані від вершини до центрів і локальний базис (t, n); б) вісім масок активності. Геометрію взято з політики та збереженої ламаної S2.')
H2('Ж.3. Методика')
P("Топологічну належність елемента до кільця бере кваліфікований картограф (PM.annulusOf); її незалежно перевіряє новий оракул, "
  "який класифікує всі шість вузлів T6 кожного елемента за півплощиною тієї хорди полігона, у кутовому секторі якої лежить вузол. "
  "Матеріальна мітка для збирання:")
eq(sub(r('a'), r('e')) + r('=') + r('[', True) + sub(r('ω'), r('e')) + r('>0', True) + r(' ∧ ', True) + sub(r('m'), sub(r('ω'), r('e'))) + r('=1', True) + r(']', True) + r(',     ', True) + sub(r('p'), r('e')) + r('=') + r('1') + r('+') + sub(r('a'), r('e')) + r(',     ', True) + sub(r('E'), r('e')) + r('=') + par(r('1') + r('+') + par(r('c') + r('−') + r('1')) + sub(r('a'), r('e'))) + sub(r('E'), r('m')), 'Ж.1')
P("Тут ω_e ∈ {0, 1, 2, 3} — топологічний номер кільця елемента (зберігається окремо), m — бінарна маска, p_e — мітка фази для "
  "незмінного розв’язувача g2_t6_elasticity_phase. Спостережувані величини обчислюються в одному локальному базисі вершини S2 "
  "методами розділу 4 і рівнянь Е.1–Е.8 (EDI 6×6 на 0,4–2,6 мм — основний оцінювач; матеріал матриці біля вершини):")
eq(sub(r('F'), r('G')) + par(r('S;c')) + r('=') + frac(r('G') + par(r('S;c')), sub(r('G'), r('0'))) + r('−') + r('1') + r(',     ', True) + sub(r('F'), r('θ')) + par(r('S;c')) + r('=') + r('θ') + par(r('S;c')) + r('−') + sub(r('θ'), r('0')), 'Ж.2')
eq(sub(r('f'), r('i')) + r('=') + r('F') + par(r('{i}')) + r(',   ', True) + sub(r('I'), r('ij')) + r('=') + r('F') + par(r('{i,j}')) + r('−') + sub(r('f'), r('i')) + r('−') + sub(r('f'), r('j')) + r(',   ', True) + sub(r('I'), r('123')) + r('=') + r('F') + par(r('{1,2,3}')) + r('−') + nsum(r('i'), sub(r('f'), r('i'))) + r('−') + nsum(r('i<j'), sub(r('I'), r('ij'))), 'Ж.3')
eq(sub(r('φ'), r('1')) + r('=') + frac(r('1'), r('3')) + sub(r('f'), r('1')) + r('+') + frac(r('1'), r('6')) + par(r('F') + par(r('{1,2}')) + r('−') + sub(r('f'), r('2')), '[', ']') + r('+') + frac(r('1'), r('6')) + par(r('F') + par(r('{1,3}')) + r('−') + sub(r('f'), r('3')), '[', ']') + r('+') + frac(r('1'), r('3')) + par(r('F') + par(r('{1,2,3}')) + r('−') + r('F') + par(r('{2,3}')), '[', ']'), 'Ж.4')
P("Розклад виконується окремо для F_G (безрозмірна) і F_θ (градуси); ці величини не підсумовуються. Значення Шеплі φ_i (аналогічно для "
  "φ_2, φ_3) — лише бухгалтерія з точною тотожністю φ_1 + φ_2 + φ_3 = F({1,2,3}), а не доказ незалежної дії кілець [Л5].")
P("Кожна величина Q — фіксована лінійна комбінація восьми значень F з коефіцієнтами a_k. Основне (парне, корельоване) правило: Q_e "
  "обчислюється тим самим варіантом оцінювача e у всіх випадках (чотири інші області EDI, EDI 4×4, COD):")
eq(sub(r('U'), r('Q')) + r('=') + sub(r('max'), r('e')) + par(sub(r('Q'), r('e')) + r('−') + r('Q'), '|', '|') + r(',     розрізнено, якщо ', True) + par(r('Q'), '|', '|') + r('>') + r('2') + sub(r('U'), r('Q')) + r(' і знак ', True) + sub(r('Q'), r('COD')) + r(' = знак Q', True), 'Ж.5')
eq(sub(r('U'), r('конс')) + r('=') + nsum(r('k≠0'), par(sub(r('a'), r('k')), '|', '|') + sub(r('r'), r('k')) + sub(r('d'), r('k'))) + r('+') + par(nsum(r('k≠0'), sub(r('a'), r('k')) + sub(r('r'), r('k'))), '|', '|') + sub(r('d'), r('0')) + r(',   ', True) + sub(r('d'), r('k')) + r('=') + frac(par(sub(r('G'), r('EDI,k')) + r('−') + sub(r('G'), r('COD,k')), '|', '|'), sub(r('G'), r('EDI,k'))) + r(',   ', True) + sub(r('r'), r('k')) + r('=') + frac(sub(r('G'), r('k')), sub(r('G'), r('0'))), 'Ж.6')
P("Для F_G(S) правило Ж.5 збігається з успадкованим U_R, а Ж.6 — з консервативною межею R(d_S + d_0) ≈ ±3,5 %. Для кутів "
  "U_конс = Σ|a_k|·|θ_COD,k − θ_EDI,k|. Класи: розрізнено за обома правилами, лише за основним, не розрізнено.")
H2('Ж.4. Перевірки і контрольні тотожності')
table('Ворота B0–B3', ['Ворота', 'Результат'], [
    ['B0 інвентаризація', 'PASS: SHA політики, закріплення успадкованих модулів на PR #46, SHA сітки/огляду/еталонів і рядки реєстрів, R2023a + PDE Toolbox, ≥ 5 ГіБ, чисте дерево'],
    ['B1 активація', 'PASS: аудит 34/34; старі картограф, перевіряльник і 8 негативних тестів PASS; оракул = annulusOf поелементно; 15/15 активацій; 10/10 нових мутацій відхилено потрібною перевіркою'],
    ['B2 еталони', f"{len(B2['checks'])}/{len(B2['checks'])} побітно: ∅ = CASE_S2_H1; {{1,2,3}} при c = 0,5 і 2 = CASE_S2_Msoft / Mstiff (u, EDI, 4×4, COD, J, податливість, CMOD, реакції, енергії); старий g2_material_sif_on_mesh PASS і тотожний"],
    ['B3 випадки', '12/12 підмножин проходять усі успадковані ворота КІН і нові ворота часткової активації (баланс активних інтерфейсів ≤ 3,8·10⁻¹², енергетична тотожність ≤ 1,0·10⁻¹¹, нев’язка ≤ 1,6·10⁻¹²)'],
    ['Перехресна перевірка', 'F_G({1,2,3}) + 1, U, U_конс і Δθ збігаються з таблицею G2-M2 точно (відхилення 0)'],
], widths=[3.2, 13.3], fs=8)
NEG = {'N1_wrong_mask': ('неправильна маска', 'мітки з маски 010 при заявленій 100'),
       'N2_swapped_ring_ids': ('переставлені номери кілець', 'ω: 1 ↔ 3'),
       'N3_swapped_centre_order': ('обернений порядок центрів', 'спадання y'),
       'N4_off_band_E': ('модуль поза кільцем', 'елемент матриці з міткою 2'),
       'N5_ring_element_dropped': ('втрачено елемент кільця', 'ω_e = 0 для елемента кільця 1'),
       'N6_detached_midside': ('від’єднаний серединний вузол', 'окремий вузол на хорді активного кільця'),
       'N7_q_reaches_ring': ('q-область досягає кільця', 'радіус = відстань до кільця + 1 мм'),
       'N8_node_in_hole': ('вузол в отворі', 'зсув на 0,2 мм усередину отвору 1'),
       'N9_wrong_modulus': ('неправильний модуль', '0,6E_m замість 0,5E_m'),
       'N10_inactive_ring_jump': ('стрибок на неактивному кільці', 'мітки 110 при заявленій 100')}
EXPECT = {'phaseFromMask': 'мітки з маски', 'oracleAgreement': 'збіг з оракулом', 'centresAscendingY': 'порядок центрів',
          'chordsConforming': 'конформність хорд', 'qSupportOwnerFree': 'q без кілець', 'noVoidFilling': 'без заповнення отворів',
          'materialsAdmissible': 'допустимі матеріали', 'passiveChordsNoJump': 'пасивні хорди без стрибка'}
negs = [t_ for t_ in FB['tests'] if t_['name'].startswith('F03_')]
table('Мутації, які новий перевіряльник активації мусить відхилити', ['Мутація', 'Спосіб', 'Очікувана перевірка', 'Відхилено'],
      [[NEG[t_['name'][4:]][0], NEG[t_['name'][4:]][1], EXPECT[t_['expected'].replace('rejected by ', '')], yes(t_['pass'])] for t_ in negs], widths=[4.3, 5.4, 4.8, 2.0], fs=8)
GROUPS = [('F01', 'сухий режим нічого не записує'), ('F02', 'підроблені байти сітки S2 → HOLD_SOURCE'), ('F03', '10 мутацій активації (табл. Ж.3)'),
          ('F04', 'дисбаланс сил на активному інтерфейсі виявлено (чисто 2,3·10⁻¹², збурено 0,22)'), ('F05', 'неправильні сила і товщина → ворота навантаження'),
          ('F06', 'п’ять неправильних токенів → HOLD_AUTH_TOKEN без розв’язків'), ('F07', 'зміна політики → HOLD_POLICY_DRIFT'),
          ('F08', 'брудне дерево джерел → HOLD_DIRTY_SOURCE'), ('F09', 'запобіжник пам’яті (імітація 4,9 ГіБ; запускач не дозволяє знизити поріг)'),
          ('F10', 'чотири випадки поза планом → HOLD_CASE_OUTSIDE_DESIGN'), ('F11', 'пошкоджені, повторно підписані, з оберненим K_II, без реєстру, підроблені записи → HOLD_RECORD_INTEGRITY; чиста копія — GO без FEM'),
          ('F12', 'переривання після 2 розв’язків, відновлення без FEM, завершення = побітно тотожний повтор 15 записів і 2 контролів'),
          ('F13', 'прийнятий запуск незмінний (80 файлів)')]
rows = []
for g, d_ in GROUPS:
    ts = [t_ for t_ in FB['tests'] if t_['name'].startswith(g)]
    rows.append([g, d_, f"{sum(t_['pass'] for t_ in ts)}/{len(ts)}"])
table(f"Тести відмов, перезапусків і відтворення ({FB['passed']}/{FB['total']})", ['Група', 'Зміст', 'Пройдено'], rows, widths=[1.4, 13.0, 2.1], fs=8)
H2('Ж.5. Результати')
lc = LB['logicalCases']
ML = {'000': '∅', '100': '{1}', '010': '{2}', '001': '{3}', '110': '{1,2}', '101': '{1,3}', '011': '{2,3}', '111': '{1,2,3}'}
rows = []
for x in lc:
    if x['contrast'] == '2' and x['bits'] == '000':
        continue
    rows.append(['—' if x['bits'] == '000' else num(float(x['contrast']), 1), ML[x['bits']], num(x['KI_perkN'], 6), num(x['KII_perkN'], 6, True), num(x['KII_COD_perkN'], 6, True),
                 num(x['G_1N_J_per_m2'] * 1e5, 4), pct(x['F_G'], 3), num(x['theta_MTS_deg'], 4, True), num(x['F_theta_deg'], 3, True), num(x['compliance_mm_per_N'] * 1e4, 5)])
table('Логічні випадки (∅ спільний для обох контрастів): КІН на 1 кН (МПа·√м), G при 1 Н, напрямок MTS у базисі S2',
      ['c', 'S', 'K_I', 'K_II', 'K_II (COD)', 'G, 10⁻⁵ Дж/м²', 'F_G', 'θ, °', 'F_θ, °', 'Податл., 10⁻⁴ мм/Н'], rows,
      widths=[0.9, 1.3, 1.6, 1.7, 1.7, 1.8, 1.7, 1.6, 1.5, 1.9], fs=7.5)
P("У всіх випадках K_I > 0 і K_II > 0; знак K_II за EDI і COD збігається. Позитивне F_θ — поворот проти годинникової стрілки, у бік +n, "
  "тобто від сторони кілець (центри всіх кілець мають від’ємну координату n у базисі вершини).")
figure(os.path.join(FIGB, 'm4b_fig2_FG_Ftheta.png'), 'Прямий матеріальний вплив для всіх восьми масок і двох контрастів: а) F_G; б) F_θ. Вуса — консервативна похибка ±U_конс; основна ±2U менша за маркер. Побудовано за даними MATLAB.')
def drow(term, label):
    out = [label]
    for obs, sc, nd, unit in (('G', 100, 3, ' %'), ('theta', 1, 3, '')):
        for ci in range(2):
            q = A[ci][obs]
            k = ix[term]
            out.append(f"{num(sc*q['Q'][k], nd, True)}{unit} ({CLS[q['class'][k]]})")
    return out
rows = [drow(t_, l_) for t_, l_ in [('f_1', 'f_1'), ('f_2', 'f_2'), ('f_3', 'f_3'), ('I_12', 'I_12'), ('I_13', 'I_13'), ('I_23', 'I_23'), ('I_123', 'I_123'), ('phi_1', 'φ_1'), ('phi_2', 'φ_2'), ('phi_3', 'φ_3')]]
table('Розклад F_G і F_θ (у дужках — клас розрізнення)', ['Член', 'F_G, c = 0,5', 'F_G, c = 2', 'F_θ, °, c = 0,5', 'F_θ, °, c = 2'], rows, widths=[1.5, 3.8, 3.8, 3.7, 3.7], fs=8)
recG = max(abs(a_['G']['reconstructionResidual']) for a_ in A)
recT = max(abs(a_['theta']['reconstructionResidual']) for a_ in A)
shp = max(max(abs(a_['G']['shapleySumResidual']), abs(a_['theta']['shapleySumResidual'])) for a_ in A)
ucG = [A[ci]['G']['U_conservative'][ix[t_]] for ci in range(2) for t_ in ('f_1', 'f_2', 'f_3')]
ucI = [A[ci]['G']['U_conservative'][ix[t_]] for ci in range(2) for t_ in ('I_12', 'I_13', 'I_23')]
ucT = [A[ci]['G']['U_conservative'][ix['I_123']] for ci in range(2)]
upG = max(A[ci]['G']['U_primary'][k] for ci in range(2) for k in range(len(names)))
upT = max(A[ci]['theta']['U_primary'][k] for ci in range(2) for k in range(len(names)))
P(f"Тотожності: залишок розкладу ≤ {sci(recG,1)} (F_G) і ≤ {sci(recT,1)}° (F_θ); сума Шеплі ≤ {sci(shp,1)}. Основна похибка "
  f"U ≤ {sci(upG,1)} (F_G) і ≤ {num(upT,3)}° (F_θ). Консервативна U_конс для F_G: {num(100*min(ucG),1)}–{num(100*max(ucG),1)} % для окремих кілець, "
  f"{num(100*min(ucI),1)}–{num(100*max(ucI),1)} % для парних взаємодій, {num(100*min(ucT),1)}–{num(100*max(ucT),1)} % для I_123.")
figure(os.path.join(FIGB, 'm4b_fig3_decomposition.png'), 'Внески окремих кілець і взаємодій: а, б) F_G; в, г) F_θ для м’яких і жорстких кілець. Насичений колір — розрізнено за обома правилами, світлий — лише за основним; вуса — ±U_конс. Побудовано за даними MATLAB.')
rd = {ci: A[ci]['readings'] for ci in range(2)}
P(f"Висновки за заздалегідь заданими правилами (обидва контрасти однаково): для F_G — {rd[0]['G']['additivityPrimary']} за основним, "
  f"{rd[0]['G']['additivityConservative']} за консервативним правилом; для F_θ — {rd[0]['theta']['additivityPrimary']} і "
  f"{rd[0]['theta']['additivityConservative']} (I_12 розрізнено обома правилами). H1: {rd[0]['H1_unequalRingInfluence_G']} (F_G) і "
  f"{rd[0]['H1_unequalRingInfluence_theta']} (F_θ). H2 за правилом порядку модулів: {rd[0]['H2_orderDiffers']} (|f_1| > |f_2| > |f_3| для обох величин), "
  "проте знакові картини різні: для G протилежний знак має кільце 2, для θ — кільце 1. H3: неадитивність розрізнена лише за основним правилом для G.")
P("Порівняння за однакової активної площі (1012,15 мм² для одного кільця, 2024,31 мм² для двох; площі полігонів кілець рівні до "
  "округлення, кількість елементів 4088 / 4102 / 4088). Одне м’яке кільце: +4,43 % (1), −3,63 % (2), +2,33 % (3); різниці f_1 − f_2 "
  "(+8,06 %) і f_2 − f_3 (−5,96 %) розрізнено обома правилами, f_1 − f_3 (+2,10 %) — лише основним. Дві м’які пари: {1,2} +0,32 %, "
  "{1,3} +6,75 %, {2,3} −1,68 %. Найбільше зменшення G серед усіх 15 конфігурацій — жорсткі {1,3}: −5,48 % (обидва правила).")
figure(os.path.join(FIGB, 'm4b_fig4_equal_area.png'), 'Порівняння за однакової активної площі: а, в) одне активне кільце (у дужках — відстань від вершини до центру); б, г) дві активні пари. Вуса — ±U_конс. Побудовано за даними MATLAB.')
rp = LB['ringPositions']
table('Положення кілець у базисі вершини S2', ['Кільце', 'Центр, мм', 'x_t, мм', 'y_n, мм', 'Відстань, мм', 'Пеленг від t, °', 'Найближчий вузол кільця, мм'],
      [[str(p_['ring']), f"({num(p_['centre_mm'][0],2)}; {num(p_['centre_mm'][1],2)})", num(p_['x_tangent_mm'], 2), num(p_['y_normal_mm'], 2, True), num(p_['distance_mm'], 2), num(p_['bearing_deg'], 1, True), num(p_['nearestRingNode_mm'], 2)] for p_ in rp],
      widths=[1.4, 3.0, 1.8, 1.8, 2.0, 2.4, 3.6], fs=8)
figure(os.path.join(FIGB, 'm4b_fig5_energy_density.png'), 'Відносна зміна питомої енергії деформації Δw/w₀ відносно випадку без активних кілець: а) м’яке кільце 1; б) м’яке кільце 2; в) три м’які кільця. Значення обмежено діапазоном ±0,5. Побудовано за даними MATLAB.')
H2('Ж.6. Спостереження для наукового рев’ю (не встановлені механізми)')
B('Прийнятий ефект трьох м’яких кілець (+2,18 %) є невеликою різницею внесків протилежних знаків: +4,43 − 3,63 + 2,33 % і взаємодій −0,95 %. Висновок G2-M2/M3 «м’які кільця збільшують G приблизно на 2 %» приховує вдвічі більші ефекти розміщення.')
B('Напрямок MTS визначає найближче кільце: |f_θ,1| у 3,5–3,9 раза більше за |f_θ,2| і |f_θ,3| і має протилежний знак; кільця 2 і 3 керують майже однаково (різниця 0,018°).')
B('Вплив на G не визначається лише близькістю: кільце 3 (146,7 мм від вершини) змінює G на +2,3 % (м’яке), знаки чергуються 1 / 2 / 3. Поля Δw/w₀ (рис. Ж.5) показують перерозподіл у всій навантаженій перемичці, що узгоджується з глобальним (згинальним) шляхом навантаження; це прочитання полів, а не відокремлений механізм.')
B('Взаємодії на 1–2 порядки менші за головні ефекти (для G |I_ij| ≤ 0,49 %) і не розрізнені консервативним правилом. I_13 (м’які −1,4·10⁻⁴, жорсткі −1,4·10⁻⁵) та I_123 (±3–7·10⁻⁴) співмірні з розбіжністю R_прям між сімействами сіток у G2-M4.A (≈ 1,5–2·10⁻⁵); це додаткове порівняння не входило до пререєстрації, але I_13 для жорстких кілець не слід тлумачити, хоча основне правило позначає його як розрізнене.')
B('Основне правило вимірює узгодженість оцінювачів (контури EDI, 4×4, COD) на одній сітці і не є межею похибки дискретизації; перевірку сімейством сіток G2-M4.A виконано лише для повністю активних кілець.')
H2('Ж.7. Кандидати для майбутньої, окремо дозволеної матричної траєкторії (лише пропозиція)')
P("Не обчислено і не дозволено. Вибір — для другого наукового рев’ю; кожна траєкторія мала б зупинятися до контакту з інтерфейсом або виходу на зовнішню межу.")
B('C1 — жорсткі {1,3}: найбільше зменшення G (−5,48 %, обидва правила) з поворотом у бік кілець (−0,81°). Перевіряє, чи екранувальне розташування водночас притягує шлях до кільця 1.')
B('C2 — м’яке {2}: зменшення G (−3,63 %, обидва правила) за слабкого повороту (−0,37°); екранування майже без зміни напрямку, сценарій обходу в матриці.')
B('C3 — м’яке {1}: найсильніший поворот від кілець (+1,31°) з підсиленням G (+4,43 %); контрастний сценарій відведення.')
H2('Ж.8. Обмеження')
B('Одна заморожена тріщина S2, одна сітка, два контрасти, ідеальне зчеплення, лінійна пружність, P = 1 Н, ілюстративні модулі.')
B('Ядро біля вершини спільне з усіма попередніми етапами; збіжність підмножинних ефектів за сіткою не досліджено.')
B('Консервативне правило (≈ ±3,5 %) не розрізняє f_3 (обидва контрасти), f_2 (жорсткі) і всі взаємодії для G.')
B('Немає тверджень про фізичний початок руйнування, зупинку, тріщиностійкість, розшарування, проникнення, CZM чи відповідність експерименту.')
H2('Ж.9. Журнал G2-REV пакета G2-M4.B (кандидати; потребують рішення дослідника)')
table('Записи', ['Запис', 'Де виникло', 'Що було → чому → що стало', 'Перевірка', 'Стан'], [
    ['G2-REV-M4B-001', 'Політика v2', 'Повторний checkout переписав файл із CRLF (core.autocrlf) → SHA 758f4394… → b9435356… → відновлено байти LF, тотожні blob у git, до будь-якого розрахунку', 'SHA = blob; усі записи прив’язані до 758f4394…', 'виправлено до запусків'],
    ['G2-REV-M4B-002', 'Контролер', 'Set-Content PowerShell 5.1 додав BOM у g2_m4b_campaign.m → видалено до коміту', 'байти EF BB BF відсутні', 'виправлено до коміту'],
    ['G2-REV-M4B-003', 'Рисунки', 'Дужки масок у TeX, відсутній у Arial символ ∅, примітка перекривала легенду → екрановано, G₀/θ₀, примітка в заголовку легенди', 'візуальна перевірка 5/5', 'запуск рисунків замінено'],
    ['G2-REV-M4B-004', 'Тлумачення', 'Основне правило не оцінює дискретизацію; I_13 і I_123 співмірні з дрейфом G2-M4.A → пропонується не тлумачити їх фізично', 'неперереєстроване порівняння', 'потребує наукового рішення'],
    ['G2-REV-M4B-005', 'Word', 'Канонічну 0.3 знайдено в перевіреному пакеті передачі; SHA-256 49daba7e… збігся → закомічено без змін → HOLD_WORD_INPUT знято; 0.2 недоступна', 'SHA-256 перед читанням файлу', 'виконано (рішення D)'],
], widths=[2.4, 2.0, 6.6, 3.1, 2.4], fs=7.5)
H2('Ж.10. Запис реєстру рішень (за формою розділу 11.2)')
table('Запис G2-M4.B', ['Поле запису', 'Зміст'], [
    ['Ідентифікатор', f"G2-M4.B, 21.11.2026, Issue #47, бриф PR #48, новий draft PR; код {RUNB['gitHead']}, докази 47af26c"],
    ['Постановка', 'Атрибуція прямого пружного впливу трьох кілець на замороженій S2; нульова гіпотеза — адитивність і рівний вплив'],
    ['Докази', 'run_20261121_194814_009 (15 записів MAT + 2 контролі), analysis_run_20261121_194953_501, 38/38 тестів; реєстр 323 файлів SHA-256'],
    ['Зауваження', 'Очікують нашого рев’ю: тлумачення I_13/I_123, глобальний шлях навантаження, вибір кандидатів C1–C3'],
    ['Виправлення', 'G2-REV-M4B-001…005 (табл. Ж.8)'],
    ['Рішення', 'ОЧІКУЄ НАУКОВОЇ ПЕРЕВІРКИ (REVIEW_STOP_B); M4.C, траєкторії, 3³, CZM не дозволено'],
    ['Word / рисунки', 'Редакція 0.4 (кандидат); нові рисунки Ж.1–Ж.5 і перенесені Е.1–Е.5, усі підписи українською'],
], widths=[3.2, 13.3], fs=8)
H2('Ж.11. Відкриті питання для наукового рев’ю')
B('Чи приймається розклад і класифікація неадитивності, зважаючи на те, що для G взаємодії розрізнені лише основним правилом?')
B('Чи погоджуєтеся не тлумачити I_13 та I_123 фізично через співмірність із дрейфом дискретизації (G2-REV-M4B-004)?')
B('Чи потрібна перевірка підмножинних ефектів на іншому сімействі сіток перед вибором архітектур?')
B('Які з кандидатів C1–C3 (або інші) включити в окрему задачу довгої матричної траєкторії із зупинкою до інтерфейсу?')

# ---------------------------------------------------------------- layout: keep short tables, captions and figures together
def keep_together(d):
    for tb in d.tables:
        rows = tb.rows
        if len(rows) <= 25:
            for k, row in enumerate(rows):
                trPr = row._tr.get_or_add_trPr()
                if trPr.find(qn('w:cantSplit')) is None:
                    trPr.append(OxmlElement('w:cantSplit'))
                if k == 0 and trPr.find(qn('w:tblHeader')) is None:
                    trPr.append(OxmlElement('w:tblHeader'))
                if k < len(rows) - 1:
                    for c in row.cells:
                        for pp in c.paragraphs:
                            pp.paragraph_format.keep_with_next = True
        prev = tb._tbl.getprevious()
        if prev is not None and prev.tag == qn('w:p'):
            pp = Paragraph(prev, tb._parent)
            if pp.style is not None and pp.style.name == 'Caption':
                pp.paragraph_format.keep_with_next = True
    for pp in d.paragraphs:
        if pp._p.findall('.//' + qn('w:drawing')):
            pp.paragraph_format.keep_with_next = True
keep_together(doc)

doc.core_properties.title = 'Матеріало-індуковане екранування та керування траєкторією тріщини — редакція 0.4 (кандидат)'
doc.core_properties.author = 'NewMetacomp G2'
doc.core_properties.language = 'uk-UA'
doc.core_properties.revision = 4
doc.save(OUT)
print('WROTE', OUT, hashlib.sha256(open(OUT, 'rb').read()).hexdigest())
