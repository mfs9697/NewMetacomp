# -*- coding: utf-8 -*-
"""Document kit for the G2 preliminary report: a two-pass block list -> native .docx.

Content modules append blocks (headings, paragraphs, equations, figures, tables) to a Report object.
Pass 1 numbers every labelled figure/table/equation and every cited source; pass 2 renders with
python-docx. Figures, tables and equations carry SEQ fields inside bookmarks, references are REF fields,
headings use a real multilevel list, and the table of contents is a TOC field (Word updates the fields
when the PDF is rendered).

Inline markup in every text string:
    $...$            native Word equation (LaTeX subset, see omml.py)
    **...**          bold          *...*   italic          `...`  monospace identifier
    [[fig:key]] [[tab:key]] [[eq:key]] [[sec:key]]   cross-reference (number only)
    [[cite:key]] or [[cite:k1,k2]]                     bibliography reference
"""
import os
import re
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.section import WD_ORIENT
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import qn, nsdecls

from omml import omath, omath_para

FONT = 'Times New Roman'
MONO = 'Consolas'
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
NBSP = chr(0xA0)

INLINE = re.compile(r'(\$[^$]+\$|\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`|\[\[[a-z]+:[^\]]+\]\])')


class Report:
    def __init__(self, macros=None, bibliography=None):
        self.blocks = []
        self.macros = macros or {}
        self.bib = bibliography or {}     # key -> formatted reference text
        self.num = {}                     # 'fig:key' -> number string
        self.cited = []                   # keys in order of first citation
        self.sec_counter = [0, 0, 0]
        self.appendix_mode = False
        self.errors = []
        self.nobreak = True               # keep inline formulas with \cdot in one piece (running text only)

    # ------------------------------------------------------------------ block constructors
    def add(self, kind, **kw):
        self.blocks.append(dict(kind=kind, **kw))

    def H(self, level, text, key=None, numbered=True):
        self.add('h', level=level, text=text, key=key, numbered=numbered)

    def P(self, text, style=None, indent=True, align='j', size=None, keep=False, space_after=None):
        self.add('p', text=text, style=style, indent=indent, align=align, size=size, keep=keep,
                 space_after=space_after)

    def BUL(self, items, numbered=False):
        self.add('list', items=items, numbered=numbered)

    def EQ(self, latex, key=None):
        self.add('eq', latex=latex, key=key)

    def FIG(self, key, path, caption, width=16.0):
        self.add('fig', key=key, path=path, caption=caption, width=width)

    def TAB(self, key, caption, header, rows, widths=None, size=9, align=None, landscape=False, note=None):
        self.add('tab', key=key, caption=caption, header=header, rows=rows, widths=widths, size=size,
                 align=align, note=note)

    def BREAK(self):
        self.add('break')

    def SECTION(self, landscape):
        self.add('section', landscape=landscape)

    def TOC(self):
        self.add('toc')

    def BIB(self):
        self.add('bib')

    def RAW(self, fn):
        self.add('raw', fn=fn)

    # ------------------------------------------------------------------ pass 1
    def _scan_cites(self, text):
        for m in re.finditer(r'\[\[cite:([^\]]+)\]\]', text or ''):
            for k in m.group(1).split(','):
                k = k.strip()
                if k not in self.bib:
                    self.errors.append('unknown citation ' + k)
                if k not in self.cited:
                    self.cited.append(k)

    def number(self):
        nf = nt = ne = 0
        sec = [0, 0, 0]
        for b in self.blocks:
            k = b['kind']
            if k == 'h':
                if b['numbered']:
                    lv = b['level']
                    sec[lv - 1] += 1
                    for j in range(lv, 3):
                        sec[j] = 0
                    b['number'] = '.'.join(str(x) for x in sec[:lv])
                    if b.get('key'):
                        self.num['sec:' + b['key']] = b['number']
                self._scan_cites(b['text'])
            elif k == 'fig':
                nf += 1
                b['number'] = nf
                self.num['fig:' + b['key']] = str(nf)
                self._scan_cites(b['caption'])
            elif k == 'tab':
                nt += 1
                b['number'] = nt
                self.num['tab:' + b['key']] = str(nt)
                self._scan_cites(b['caption'])
                for r in [b['header']] + b['rows']:
                    for c in r:
                        self._scan_cites(str(c))
                self._scan_cites(b.get('note'))
            elif k == 'eq':
                if b.get('key'):
                    ne += 1
                    b['number'] = ne
                    self.num['eq:' + b['key']] = str(ne)
            elif k == 'p':
                self._scan_cites(b['text'])
            elif k == 'list':
                for it in b['items']:
                    self._scan_cites(it)
        self.counts = dict(figures=nf, tables=nt, equations=ne, sources=len(self.cited))

    # ------------------------------------------------------------------ low-level XML helpers
    def _fld(self, par, instr, cached, bold=None, italic=None, size=None):
        """Complex field with a cached result."""
        def r(inner):
            el = parse_xml(f'<w:r {nsdecls("w")}>{inner}</w:r>')
            par._p.append(el)
            return el
        if not instr.startswith('TOC') and 'MERGEFORMAT' not in instr:
            # keep the cached run formatting (bold label numbers, small table notes, 9 pt footer) when Word updates
            instr += ' \\* MERGEFORMAT'
        r('<w:fldChar w:fldCharType="begin"/>')
        r(f'<w:instrText xml:space="preserve"> {instr} </w:instrText>')
        r('<w:fldChar w:fldCharType="separate"/>')
        run = par.add_run(cached)
        self._fmt(run, bold, italic, size)
        r('<w:fldChar w:fldCharType="end"/>')

    def _fmt(self, run, bold=None, italic=None, size=None, mono=False):
        if bold:
            run.bold = True
        if italic:
            run.italic = True
        if size:
            run.font.size = Pt(size)
        if mono:
            run.font.name = MONO
            run._element.rPr.rFonts.set(qn('w:eastAsia'), MONO)
            run._element.rPr.rFonts.set(qn('w:cs'), MONO)
            if size:
                run.font.size = Pt(size - 1)
            else:
                run.font.size = Pt(10)

    _bm = 100

    def _bookmark_seq(self, par, name, seqname, cached, bold=None, size=None):
        Report._bm += 1
        bid = Report._bm
        par._p.append(parse_xml(f'<w:bookmarkStart {nsdecls("w")} w:id="{bid}" w:name="{name}"/>'))
        self._fld(par, f'SEQ {seqname} \\* ARABIC', cached, bold=bold, size=size)
        par._p.append(parse_xml(f'<w:bookmarkEnd {nsdecls("w")} w:id="{bid}"/>'))

    @staticmethod
    def _attach_punct(text):
        """A , . ; : ) that directly follows an inline formula is moved inside it (as upright text): Word otherwise
        puts a visible gap between the equation object and the punctuation mark."""
        parts = re.split(r'(\$[^$]+\$)', text)
        out = []
        for i in range(2, len(parts), 2):
            parts[i] = re.sub(r'^ (?=(?:%|мм|мкм|кН|МПа|ГіБ|Н|с|°)(?![А-Яа-яІіЇїЄєҐґA-Za-z]))', NBSP, parts[i])
        for i, p in enumerate(parts):
            if i % 2 == 0 and i > 0 and p and p[0] in ',.;:)' and out:
                k = 1
                while k < len(p) and p[k] in ',.;:)':
                    k += 1
                out[-1] = out[-1][:-1] + '\\text{' + p[:k] + '}$'
                p = p[k:]
            out.append(p)
        return ''.join(out)

    @staticmethod
    def _typo(text):
        """Non-breaking spaces: before a percent sign / unit that follows a number, after the numero sign."""
        text = re.sub(r'(?<=\d) (?=(?:%|мм|мкм|кН|МПа|ГіБ|Н|с|°)(?![А-Яа-яІіЇїЄєҐґA-Za-z]))', NBSP, text)
        return text.replace('№ ', '№' + NBSP)

    def rich(self, par, text, bold=None, italic=None, size=None):
        """Render inline markup into a paragraph."""
        self._rich(par, self._attach_punct(text), bold, italic, size)
        # a paragraph that consists of a single formula would be typeset by Word as a centred display equation
        has_math = par._p.find('{http://schemas.openxmlformats.org/officeDocument/2006/math}oMath') is not None
        has_text = any((t.text or '').strip('​') for t in par._p.iter(qn('w:t')))
        if has_math and not has_text:
            par.add_run('​')
        return par

    def _rich(self, par, text, bold=None, italic=None, size=None):
        parts = INLINE.split(text)
        for pi, part in enumerate(parts):
            if not part:
                continue
            prev = parts[pi - 1] if pi else ''
            if part.startswith('$') and part.endswith('$') and len(part) > 2:
                try:
                    el = parse_xml(omath(part[1:-1], self.macros))
                    if self.nobreak and re.search(r'\\cdot|\\times|\\pm', part) and len(part) < 60:
                        # an inline formula such as 2·10^-13 must not be broken at its operator
                        MN = '{http://schemas.openxmlformats.org/officeDocument/2006/math}'
                        box = parse_xml(f'<m:box xmlns:m="{MN[1:-1]}"><m:boxPr><m:noBreak m:val="1"/></m:boxPr><m:e/></m:box>')
                        e = box.find(MN + 'e')
                        for ch in list(el):
                            e.append(ch)
                        el.append(box)
                except Exception as ex:   # noqa
                    self.errors.append(f'math error {ex} in {part}')
                    par.add_run(part)
                    continue
                if size or bold:
                    # carry size / bold into the math runs
                    for mr in el.iter('{http://schemas.openxmlformats.org/officeDocument/2006/math}r'):
                        rpr = parse_xml(f'<w:rPr {nsdecls("w")}><w:rFonts w:ascii="Cambria Math" w:hAnsi="Cambria Math"/>'
                                        + ('<w:b/>' if bold else '')
                                        + (f'<w:sz w:val="{int(size * 2)}"/><w:szCs w:val="{int(size * 2)}"/>' if size else '')
                                        + '</w:rPr>')
                        mt = mr.find('{http://schemas.openxmlformats.org/officeDocument/2006/math}t')
                        mt.addprevious(rpr)
                par._p.append(el)
            elif part.startswith('**') and part.endswith('**'):
                self._rich(par, part[2:-2], True, italic, size)      # nested formulas / references allowed
            elif part.startswith('*') and part.endswith('*') and len(part) > 2:
                self._rich(par, part[1:-1], bold, True, size)
            elif part.startswith('`') and part.endswith('`'):
                self._fmt(par.add_run(part[1:-1]), bold, italic, size, mono=True)
            elif part.startswith('[['):
                kind, key = part[2:-2].split(':', 1)
                if kind == 'cite':
                    nums = []
                    for k in key.split(','):
                        k = k.strip()
                        nums.append(self.cited.index(k) + 1 if k in self.cited else 0)
                    nums.sort()
                    self._fmt(par.add_run('[' + ', '.join(str(n) for n in nums) + ']'), bold, italic, size)
                else:
                    # [[tab:k]] -> "табл. N", [[fig:k]] -> "рис. N"; [[tabn:k]] / [[fign:k]] -> bare number
                    prefix = {'tab': 'табл.' + NBSP, 'fig': 'рис.' + NBSP}.get(kind, '')
                    kind = {'tabn': 'tab', 'fign': 'fig'}.get(kind, kind)
                    full = kind + ':' + key
                    if prefix and full in self.num:
                        self._fmt(par.add_run(prefix), bold, italic, size)
                    if full not in self.num:
                        self.errors.append('unresolved reference ' + full)
                        par.add_run('??')
                    elif kind == 'sec':
                        # plain number: heading numbering is fixed by the generator, and a REF \r field would
                        # return the full list text ("Розділ N.") of level-1 headings
                        word = ''
                        if prev.rstrip().endswith('('):
                            word = ('підрозділ' if '.' in self.num[full] else 'розділ') + NBSP
                        self._fmt(par.add_run(word + self.num[full]), bold, italic, size)
                    else:
                        self._fld(par, f'REF {kind}_{key} \\h', self.num[full], bold, italic, size)
            else:
                self._fmt(par.add_run(self._typo(part)), bold, italic, size)
        return par

    # ------------------------------------------------------------------ document set-up
    def _setup(self, title_short):
        doc = Document()
        self.doc = doc
        st = doc.styles
        n = st['Normal']
        n.font.name = FONT
        n.font.size = Pt(12)
        n.element.rPr.rFonts.set(qn('w:eastAsia'), FONT)
        n.element.rPr.rFonts.set(qn('w:cs'), FONT)
        n.element.rPr.append(parse_xml(f'<w:lang {nsdecls("w")} w:val="uk-UA" w:eastAsia="uk-UA"/>'))
        n.paragraph_format.space_after = Pt(4)
        n.paragraph_format.line_spacing = 1.07
        for name, size, before, after, italic in (('Heading 1', 15, 18, 9, False), ('Heading 2', 13, 12, 6, False),
                                                  ('Heading 3', 12, 9, 4, True), ('Title', 18, 0, 12, False)):
            s = st[name]
            s.font.name = FONT
            s.font.size = Pt(size)
            s.font.bold = True
            s.font.italic = italic
            s.font.color.rgb = RGBColor(0, 0, 0)
            rf = s.element.rPr.rFonts
            for a in ('w:ascii', 'w:hAnsi', 'w:eastAsia', 'w:cs'):
                rf.set(qn(a), FONT)
            for a in ('w:asciiTheme', 'w:hAnsiTheme', 'w:eastAsiaTheme', 'w:cstheme'):
                if rf.get(qn(a)) is not None:
                    del rf.attrib[qn(a)]
            s.paragraph_format.space_before = Pt(before)
            s.paragraph_format.space_after = Pt(after)
            s.paragraph_format.keep_with_next = True
            s.paragraph_format.line_spacing = 1.05
        cap = st['Caption']
        cap.font.name = FONT
        cap.font.size = Pt(10.5)
        cap.font.bold = False
        cap.font.italic = False
        cap.font.color.rgb = RGBColor(0, 0, 0)
        cap.element.rPr.rFonts.set(qn('w:eastAsia'), FONT)
        cap.paragraph_format.space_after = Pt(8)
        cap.paragraph_format.space_before = Pt(4)
        for lb in ('List Bullet', 'List Number'):
            st[lb].font.name = FONT
            st[lb].paragraph_format.space_after = Pt(2)
        # TOC styles
        for i in (1, 2, 3):
            try:
                ts = st.add_style(f'TOC {i}', 1)
            except ValueError:
                ts = st[f'TOC {i}']
            ts.base_style = n
            ts.font.name = FONT
            ts.font.size = Pt(11.5 if i == 1 else 11)
            ts.font.bold = (i == 1)
            ts.paragraph_format.left_indent = Cm(0.6 * (i - 1))
            ts.paragraph_format.space_after = Pt(1)
            ts.paragraph_format.space_before = Pt(4 if i == 1 else 0)
        sec = doc.sections[0]
        sec.page_width, sec.page_height = Cm(21.0), Cm(29.7)
        sec.left_margin, sec.right_margin = Cm(2.5), Cm(1.8)
        sec.top_margin, sec.bottom_margin = Cm(2.0), Cm(2.0)
        self.text_width = 21.0 - 2.5 - 1.8
        self._heading_numbering()
        self._footer(sec, title_short)
        return doc

    def _heading_numbering(self):
        """A real multilevel list bound to Heading 1-3 ('Розділ 1.', '1.1.', '1.1.1.')."""
        numbering = self.doc.part.numbering_part.numbering_definitions._numbering
        abstract = parse_xml(
            f'<w:abstractNum {nsdecls("w")} w:abstractNumId="90"><w:multiLevelType w:val="multilevel"/>'
            '<w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:pStyle w:val="Heading1"/>'
            '<w:suff w:val="space"/><w:lvlText w:val="Розділ %1."/><w:lvlJc w:val="left"/>'
            '<w:pPr><w:ind w:left="0" w:firstLine="0"/></w:pPr></w:lvl>'
            '<w:lvl w:ilvl="1"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:pStyle w:val="Heading2"/>'
            '<w:suff w:val="space"/><w:lvlText w:val="%1.%2."/><w:lvlJc w:val="left"/>'
            '<w:pPr><w:ind w:left="0" w:firstLine="0"/></w:pPr></w:lvl>'
            '<w:lvl w:ilvl="2"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:pStyle w:val="Heading3"/>'
            '<w:suff w:val="space"/><w:lvlText w:val="%1.%2.%3."/><w:lvlJc w:val="left"/>'
            '<w:pPr><w:ind w:left="0" w:firstLine="0"/></w:pPr></w:lvl>'
            '</w:abstractNum>')
        first_num = numbering.find(qn('w:num'))
        if first_num is not None:
            first_num.addprevious(abstract)
        else:
            numbering.append(abstract)
        numbering.append(parse_xml(f'<w:num {nsdecls("w")} w:numId="90"><w:abstractNumId w:val="90"/></w:num>'))
        for i, name in enumerate(('Heading 1', 'Heading 2', 'Heading 3')):
            ppr = self.doc.styles[name].element.get_or_add_pPr()
            for old in ppr.findall(qn('w:numPr')):
                ppr.remove(old)
            ppr.insert(0, parse_xml(f'<w:numPr {nsdecls("w")}><w:ilvl w:val="{i}"/><w:numId w:val="90"/></w:numPr>'))

    def _footer(self, sec, title_short):
        p = sec.footer.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(title_short + '   ·   ')
        r.font.size = Pt(9)
        self._fld(p, 'PAGE', '1', size=9)

    # ------------------------------------------------------------------ pass 2
    def render(self, out, title_short):
        self.number()
        doc = self._setup(title_short)
        body_started = False
        for b in self.blocks:
            k = b['kind']
            if k == 'h':
                self._render_heading(b)
            elif k == 'p':
                p = doc.add_paragraph(style=b['style']) if b['style'] else doc.add_paragraph()
                self.rich(p, b['text'], size=b['size'])
                al = b['align']
                p.alignment = {'j': WD_ALIGN_PARAGRAPH.JUSTIFY, 'c': WD_ALIGN_PARAGRAPH.CENTER,
                               'l': WD_ALIGN_PARAGRAPH.LEFT, 'r': WD_ALIGN_PARAGRAPH.RIGHT}[al]
                if b['indent'] and al == 'j' and not b['style']:
                    p.paragraph_format.first_line_indent = Cm(1.0)
                if b['keep']:
                    p.paragraph_format.keep_with_next = True
                if b['space_after'] is not None:
                    p.paragraph_format.space_after = Pt(b['space_after'])
            elif k == 'list':
                for it in b['items']:
                    p = doc.add_paragraph(style='List Number' if b['numbered'] else 'List Bullet')
                    self.rich(p, it)
                    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
                if b['numbered']:
                    self._restart_list(doc.paragraphs[-len(b['items'])], len(b['items']))
            elif k == 'eq':
                self._render_eq(b)
            elif k == 'fig':
                self._render_fig(b)
            elif k == 'tab':
                self._render_tab(b)
            elif k == 'break':
                doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)
            elif k == 'section':
                self._new_section(b['landscape'], title_short)
            elif k == 'toc':
                p = doc.add_paragraph()
                self._fld(p, 'TOC \\o "1-2" \\h \\z \\u', 'Зміст оновлюється під час відкриття документа у Word (F9).')
            elif k == 'bib':
                for i, key in enumerate(self.cited, start=1):
                    p = doc.add_paragraph()
                    self.rich(p, f'{i}. ' + self.bib.get(key, '?? ' + key), size=11)
                    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
                    p.paragraph_format.left_indent = Cm(0.9)
                    p.paragraph_format.first_line_indent = Cm(-0.9)
                    p.paragraph_format.space_after = Pt(3)
            elif k == 'raw':
                b['fn'](self, doc)
        doc.core_properties.author = 'NewMetacomp G2'
        doc.core_properties.language = 'uk-UA'
        doc.save(out)
        return self.errors

    def _restart_list(self, first_par, n):
        """Give this numbered list its own w:num so numbering restarts at 1."""
        numbering = self.doc.part.numbering_part.numbering_definitions._numbering
        style = self.doc.styles['List Number']
        base = style.element.pPr.numPr.numId.val
        abs_id = None
        for num in numbering.findall(qn('w:num')):
            if int(num.get(qn('w:numId'))) == base:
                abs_id = num.find(qn('w:abstractNumId')).get(qn('w:val'))
        Report._bm += 1
        new_id = 200 + Report._bm
        numbering.append(parse_xml(
            f'<w:num {nsdecls("w")} w:numId="{new_id}"><w:abstractNumId w:val="{abs_id}"/>'
            '<w:lvlOverride w:ilvl="0"><w:startOverride w:val="1"/></w:lvlOverride></w:num>'))
        body = first_par._p
        for _ in range(n):
            ppr = body.get_or_add_pPr()
            ppr.append(parse_xml(f'<w:numPr {nsdecls("w")}><w:ilvl w:val="0"/><w:numId w:val="{new_id}"/></w:numPr>'))
            body = body.getnext()
            if body is None:
                break

    def _render_heading(self, b):
        doc = self.doc
        h = doc.add_paragraph(style=f'Heading {b["level"]}')
        if b.get('key') and b['numbered']:
            Report._bm += 1
            h._p.append(parse_xml(f'<w:bookmarkStart {nsdecls("w")} w:id="{Report._bm}" w:name="sec_{b["key"]}"/>'))
            self.rich(h, b['text'])
            h._p.append(parse_xml(f'<w:bookmarkEnd {nsdecls("w")} w:id="{Report._bm}"/>'))
        else:
            self.rich(h, b['text'])
        if not b['numbered']:
            ppr = h._p.get_or_add_pPr()
            ppr.append(parse_xml(f'<w:numPr {nsdecls("w")}><w:ilvl w:val="0"/><w:numId w:val="0"/></w:numPr>'))
        if b['level'] == 1:
            h.paragraph_format.page_break_before = True

    def _borderless(self, t):
        tblPr = t._tbl.tblPr
        tblPr.append(parse_xml(
            f'<w:tblBorders {nsdecls("w")}>' + ''.join(
                f'<w:{e} w:val="nil"/>' for e in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'))
            + '</w:tblBorders>'))

    def _render_eq(self, b):
        doc = self.doc
        t = doc.add_table(rows=1, cols=3)
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        t.autofit = False
        self._borderless(t)
        widths = (1.4, self.text_width - 2.8, 1.4)
        for i, w in enumerate(widths):
            t.rows[0].cells[i].width = Cm(w)
            t.rows[0].cells[i].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        mid = t.rows[0].cells[1].paragraphs[0]
        mid.alignment = WD_ALIGN_PARAGRAPH.CENTER
        mid.paragraph_format.space_after = Pt(3)
        mid.paragraph_format.space_before = Pt(3)
        try:
            mid._p.append(parse_xml(omath_para(b['latex'], self.macros)))
        except Exception as ex:   # noqa
            self.errors.append(f'math error {ex} in {b["latex"]}')
            mid.add_run(b['latex'])
        right = t.rows[0].cells[2].paragraphs[0]
        right.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        right.paragraph_format.space_after = Pt(0)
        if b.get('key'):
            right.add_run('(')
            self._bookmark_seq(right, 'eq_' + b['key'], 'Формула', str(b['number']))
            right.add_run(')')
        t.rows[0]._tr.get_or_add_trPr().append(OxmlElement('w:cantSplit'))

    def _render_fig(self, b):
        doc = self.doc
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.keep_with_next = True
        p.paragraph_format.space_before = Pt(6)
        p.paragraph_format.space_after = Pt(0)
        if not os.path.exists(b['path']):
            self.errors.append('missing figure ' + b['path'])
            p.add_run('[відсутній рисунок: ' + os.path.basename(b['path']) + ']')
        else:
            p.add_run().add_picture(b['path'], width=Cm(b['width']))
        c = doc.add_paragraph(style='Caption')
        c.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        c.add_run('Рисунок ').bold = True
        self._bookmark_seq(c, 'fig_' + b['key'], 'Рисунок', str(b['number']), bold=True)
        self.rich(c, ' — ' + b['caption'])

    def _render_tab(self, b):
        doc = self.doc
        c = doc.add_paragraph(style='Caption')
        c.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        c.paragraph_format.keep_with_next = True
        c.paragraph_format.space_after = Pt(3)
        c.add_run('Таблиця ').bold = True
        self._bookmark_seq(c, 'tab_' + b['key'], 'Таблиця', str(b['number']), bold=True)
        self.rich(c, ' — ' + b['caption'])
        ncol = len(b['header'])
        self.nobreak = False
        t = doc.add_table(rows=1, cols=ncol)
        t.style = 'Table Grid'
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        fs = b['size']
        hdr = t.rows[0]
        for i, h in enumerate(b['header']):
            cell = hdr.cells[i]
            cell.text = ''
            self.rich(cell.paragraphs[0], h, bold=True, size=fs)
            cell.paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            cell._tc.get_or_add_tcPr().append(parse_xml(f'<w:shd {nsdecls("w")} w:val="clear" w:color="auto" w:fill="E7E6E6"/>'))
        hdr._tr.get_or_add_trPr().append(OxmlElement('w:tblHeader'))
        al = b['align'] or ('l' + 'c' * (ncol - 1))
        amap = {'l': WD_ALIGN_PARAGRAPH.LEFT, 'c': WD_ALIGN_PARAGRAPH.CENTER, 'r': WD_ALIGN_PARAGRAPH.RIGHT,
                'j': WD_ALIGN_PARAGRAPH.LEFT}
        short = len(b['rows']) <= 10 and sum(len(str(c)) for r in b['rows'] for c in r) <= 1500
        for row in b['rows']:
            cells = t.add_row().cells
            for i, v in enumerate(row):
                cells[i].text = ''
                self.rich(cells[i].paragraphs[0], str(v), size=fs)
                cells[i].paragraphs[0].alignment = amap[al[i]]
                cells[i].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        nrows = len(t.rows)
        for ri, row in enumerate(t.rows):
            row._tr.get_or_add_trPr().append(OxmlElement('w:cantSplit'))
            # short tables stay on one page; a long table may split, but never right after the header row
            # (header + two rows stay together) and never leaves a single row on the next page
            keep = (ri < nrows - 1) if short else (ri <= 1 or ri == nrows - 2)
            for cell in row.cells:
                for p in cell.paragraphs:
                    p.paragraph_format.space_after = Pt(0)
                    p.paragraph_format.line_spacing = 1.0
                    if keep:
                        p.paragraph_format.keep_with_next = True
                    # the paragraph mark carries the table font size, so empty cells do not make rows taller
                    p._p.get_or_add_pPr().append(parse_xml(
                        f'<w:rPr {nsdecls("w")}><w:sz w:val="{int(fs * 2)}"/><w:szCs w:val="{int(fs * 2)}"/></w:rPr>'))
        if b['widths']:
            t.autofit = False
            for row in t.rows:
                for i, w in enumerate(b['widths']):
                    row.cells[i].width = Cm(w)
        self.nobreak = True
        if b.get('note'):
            n = doc.add_paragraph()
            self.rich(n, b['note'], size=9.5)
            n.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
            n.paragraph_format.space_before = Pt(3)
            n.paragraph_format.space_after = Pt(8)
        else:
            sp = doc.add_paragraph()
            sp.paragraph_format.space_after = Pt(2)
            for r in sp.runs:
                r.font.size = Pt(4)

    def _new_section(self, landscape, title_short):
        from docx.enum.section import WD_SECTION
        sec = self.doc.add_section(WD_SECTION.NEW_PAGE)
        if landscape:
            sec.orientation = WD_ORIENT.LANDSCAPE
            sec.page_width, sec.page_height = Cm(29.7), Cm(21.0)
            sec.left_margin, sec.right_margin = Cm(2.0), Cm(2.0)
            sec.top_margin, sec.bottom_margin = Cm(2.5), Cm(1.8)
            self.text_width = 29.7 - 4.0
        else:
            sec.orientation = WD_ORIENT.PORTRAIT
            sec.page_width, sec.page_height = Cm(21.0), Cm(29.7)
            sec.left_margin, sec.right_margin = Cm(2.5), Cm(1.8)
            sec.top_margin, sec.bottom_margin = Cm(2.0), Cm(2.0)
            self.text_width = 21.0 - 2.5 - 1.8
