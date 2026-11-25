# -*- coding: utf-8 -*-
"""Minimal LaTeX-subset -> OMML (native Word equation) converter for the G2 preliminary report.

Only the constructs used by the report are supported; an unknown command raises ValueError so that
a typo can never be rendered silently. Conventions enforced here:
  * Latin and lower-case Greek letters are italic (Word default for math runs);
  * upper-case Greek, \\mathrm{...}, \\text{...} and function names are upright;
  * '-' becomes the minus sign U+2212, a decimal comma inside a number stays inside the number.
"""
import re

MNS = 'http://schemas.openxmlformats.org/officeDocument/2006/math'

GREEK_L = {'alpha': 'α', 'beta': 'β', 'gamma': 'γ', 'delta': 'δ', 'epsilon': 'ε', 'varepsilon': 'ε', 'zeta': 'ζ',
           'eta': 'η', 'iota': 'ι', 'theta': 'θ', 'vartheta': 'ϑ', 'kappa': 'κ', 'lambda': 'λ', 'mu': 'μ', 'nu': 'ν', 'xi': 'ξ',
           'pi': 'π', 'rho': 'ρ', 'sigma': 'σ', 'tau': 'τ', 'phi': 'φ', 'varphi': 'φ', 'chi': 'χ', 'psi': 'ψ',
           'omega': 'ω', 'ell': 'ℓ'}
GREEK_U = {'Gamma': 'Γ', 'Delta': 'Δ', 'Theta': 'Θ', 'Lambda': 'Λ', 'Xi': 'Ξ', 'Pi': 'Π', 'Sigma': 'Σ', 'Phi': 'Φ',
           'Psi': 'Ψ', 'Omega': 'Ω'}
SYMBOLS = {'cdot': '·', 'times': '×', 'approx': '≈', 'le': '≤', 'leq': '≤', 'ge': '≥', 'geq': '≥', 'ne': '≠',
           'neq': '≠', 'pm': '±', 'mp': '∓', 'to': '→', 'rightarrow': '→', 'in': '∈', 'infty': '∞', 'partial': '∂',
           'nabla': '∇', 'll': '≪', 'gg': '≫', 'propto': '∝', 'equiv': '≡', 'sim': '∼', 'ldots': '…', 'dots': '…',
           'cdots': '⋯', 'prime': '′', 'degree': '°', 'circ': '∘', 'cup': '∪', 'cap': '∩', 'setminus': '∖',
           'subset': '⊂', 'forall': '∀', 'mid': '|', 'colon': ':', 'Leftrightarrow': '⇔', 'Rightarrow': '⇒',
           'langle': '⟨', 'rangle': '⟩', 'emptyset': '∅', 'varnothing': '∅', 'otimes': '⊗', 'angle': '∠',
           'lbrace': '{', 'rbrace': '}', '{': '{', '}': '}', '%': '%', '#': '#', '&': '&', '|': '‖'}
SPACES = {',': ' ', ';': ' ', ':': ' ', '!': '', ' ': ' ', 'quad': ' ', 'qquad': '  '}
FUNCS = {'sin', 'cos', 'tan', 'cot', 'ln', 'log', 'exp', 'arctan', 'arccos', 'arcsin', 'max', 'min', 'det', 'lim',
         'sgn', 'tr'}
NARY = {'int': '∫', 'oint': '∮', 'sum': '∑', 'prod': '∏', 'iint': '∬'}
ACCENTS = {'hat': '̂', 'tilde': '̃', 'dot': '̇', 'ddot': '̈', 'vec': '⃗', 'check': '̌'}
DELIMS = {'(': '(', ')': ')', '[': '[', ']': ']', '|': '|', '.': '', '\\{': '{', '\\}': '}', '\\|': '‖',
          '\\langle': '⟨', '\\rangle': '⟩', '\\lceil': '⌈', '\\rceil': '⌉', '\\lfloor': '⌊', '\\rfloor': '⌋', '\\lbrace': '{', '\\rbrace': '}'}

TOKEN = re.compile(r'\\[A-Za-z]+|\\.|[0-9]+(?:[.,][0-9]+)*|\s+|.', re.S)


def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def run(t, plain=False, aln=False):
    if t == '':
        return ''
    pr = ''
    if plain or aln:
        pr = '<m:rPr>' + ('<m:aln/>' if aln else '') + ('<m:sty m:val="p"/>' if plain else '') + '</m:rPr>'
    return f'<m:r>{pr}<m:t xml:space="preserve">{esc(t)}</m:t></m:r>'


class Parser:
    def __init__(self, src, macros=None):
        for k, v in (macros or {}).items():
            src = re.sub(re.escape(k) + r'(?![A-Za-z])', lambda m, v=v: ' ' + v, src)
        self.toks = [t for t in TOKEN.findall(src)]
        self.i = 0
        self.align_next = False

    def peek(self):
        while self.i < len(self.toks) and self.toks[self.i].isspace():
            self.i += 1
        return self.toks[self.i] if self.i < len(self.toks) else None

    def next(self):
        t = self.peek()
        self.i += 1
        return t

    def raw_group(self):
        """Raw text of a braced group (spaces kept) - for \\text and \\mathrm."""
        assert self.next() == '{', 'expected {'
        depth, out = 1, []
        while self.i < len(self.toks):
            t = self.toks[self.i]
            self.i += 1
            if t == '{':
                depth += 1
            elif t == '}':
                depth -= 1
                if depth == 0:
                    return ''.join(out)
            out.append(t)
        raise ValueError('unbalanced braces')

    def group(self):
        """One argument: a braced group or a single atom."""
        if self.peek() == '{':
            self.next()
            x = self.sequence(('}',))
            assert self.next() == '}'
            return x
        return self.atom()

    def sequence(self, stops):
        out = []
        while True:
            t = self.peek()
            if t is None or t in stops:
                break
            out.append(self.scripted())
        return ''.join(out)

    def scripted(self):
        base = self.atom()
        sub = sup = None
        while self.peek() in ('_', '^'):
            if self.next() == '_':
                sub = self.group()
            else:
                sup = self.group()
        if sub is None and sup is None:
            return base
        if base == '':
            base = run('​')
        if sub is not None and sup is not None:
            return f'<m:sSubSup><m:e>{base}</m:e><m:sub>{sub}</m:sub><m:sup>{sup}</m:sup></m:sSubSup>'
        if sub is not None:
            return f'<m:sSub><m:e>{base}</m:e><m:sub>{sub}</m:sub></m:sSub>'
        return f'<m:sSup><m:e>{base}</m:e><m:sup>{sup}</m:sup></m:sSup>'

    def delim(self):
        t = self.next()
        if t not in DELIMS:
            raise ValueError(f'unsupported delimiter {t!r}')
        return DELIMS[t]

    def take_run(self, text, plain=False):
        a = self.align_next
        self.align_next = False
        return run(text, plain, a)

    def atom(self):
        t = self.next()
        if t is None:
            raise ValueError('unexpected end of formula')
        if t == '{':
            x = self.sequence(('}',))
            assert self.next() == '}'
            return x
        if t == '&':
            self.align_next = True
            return ''
        if t == '-':
            return self.take_run('−')
        if t == "'":
            return self.take_run('′')
        if t == '~':
            return self.take_run(' ')
        if not t.startswith('\\'):
            return self.take_run(t)
        name = t[1:]
        if name in GREEK_L:
            return self.take_run(GREEK_L[name])
        if name in GREEK_U:
            return self.take_run(GREEK_U[name], plain=True)
        if name in SYMBOLS:
            return self.take_run(SYMBOLS[name])
        if name in SPACES:
            return run(SPACES[name])
        if name in ('frac', 'dfrac', 'tfrac'):
            a = self.group()
            b = self.group()
            return f'<m:f><m:num>{a}</m:num><m:den>{b}</m:den></m:f>'
        if name == 'sqrt':
            return ('<m:rad><m:radPr><m:degHide m:val="1"/></m:radPr><m:deg/><m:e>' + self.group() + '</m:e></m:rad>')
        if name in ('mathrm', 'text', 'operatorname', 'textrm', 'mathbf', 'mathit'):
            raw = self.raw_group()
            if name == 'mathit':
                return self.take_run(raw)
            if name == 'mathbf':
                return f'<m:r><m:rPr><m:sty m:val="b"/></m:rPr><m:t xml:space="preserve">{esc(raw)}</m:t></m:r>'
            if name != 'text':
                raw = raw.replace(' ', '')
            return self.take_run(raw.replace('-', '−') if name != 'text' else raw, plain=True)
        if name in ('boldsymbol', 'bm'):
            inner = self.group()
            return inner.replace('<m:r><m:t', '<m:r><m:rPr><m:sty m:val="bi"/></m:rPr><m:t')
        if name in FUNCS:
            fname = run(name, plain=True)
            sub = sup = None
            while self.peek() in ('_', '^'):
                if self.next() == '_':
                    sub = self.group()
                else:
                    sup = self.group()
            if name in ('max', 'min', 'lim') and sub is not None:
                fname = f'<m:limLow><m:e>{fname}</m:e><m:lim>{sub}</m:lim></m:limLow>'
                sub = None
            if sub is not None and sup is not None:
                fname = f'<m:sSubSup><m:e>{fname}</m:e><m:sub>{sub}</m:sub><m:sup>{sup}</m:sup></m:sSubSup>'
            elif sub is not None:
                fname = f'<m:sSub><m:e>{fname}</m:e><m:sub>{sub}</m:sub></m:sSub>'
            elif sup is not None:
                fname = f'<m:sSup><m:e>{fname}</m:e><m:sup>{sup}</m:sup></m:sSup>'
            arg = self.scripted() if self.peek() not in (None, '}', '\\right', '&', '\\\\') else ''
            return f'<m:func><m:fName>{fname}</m:fName><m:e>{arg}</m:e></m:func>'
        if name in NARY:
            sub = sup = None
            while self.peek() in ('_', '^'):
                if self.next() == '_':
                    sub = self.group()
                else:
                    sup = self.group()
            body = self.sequence(('}', '\\right', '&', '\\\\', '\\end'))
            loc = 'undOvr' if name in ('sum', 'prod') else 'subSup'
            pr = (f'<m:naryPr><m:chr m:val="{NARY[name]}"/><m:limLoc m:val="{loc}"/>'
                  + ('<m:subHide m:val="1"/>' if sub is None else '')
                  + ('<m:supHide m:val="1"/>' if sup is None else '') + '</m:naryPr>')
            return f'<m:nary>{pr}<m:sub>{sub or ""}</m:sub><m:sup>{sup or ""}</m:sup><m:e>{body}</m:e></m:nary>'
        if name in ACCENTS:
            return f'<m:acc><m:accPr><m:chr m:val="{ACCENTS[name]}"/></m:accPr><m:e>{self.group()}</m:e></m:acc>'
        if name in ('bar', 'overline'):
            return f'<m:bar><m:barPr><m:pos m:val="top"/></m:barPr><m:e>{self.group()}</m:e></m:bar>'
        if name == 'left':
            o = self.delim()
            body = self.sequence(('\\right',))
            assert self.next() == '\\right', 'missing \\right'
            c = self.delim()
            return (f'<m:d><m:dPr><m:begChr m:val="{esc(o)}"/><m:endChr m:val="{esc(c)}"/></m:dPr>'
                    f'<m:e>{body}</m:e></m:d>')
        if name == 'begin':
            env = self.raw_group()
            rows, row, cell = [], [], []
            while True:
                t2 = self.peek()
                if t2 is None:
                    raise ValueError('unterminated environment ' + env)
                if t2 == '\\end':
                    self.next()
                    assert self.raw_group() == env
                    break
                if t2 == '\\\\':
                    self.next()
                    row.append(''.join(cell)); rows.append(row); row, cell = [], []
                    continue
                if t2 == '&' and env != 'aligned':
                    self.next()
                    row.append(''.join(cell)); cell = []
                    continue
                cell.append(self.scripted())
            row.append(''.join(cell))
            if any(row):
                rows.append(row)
            if env == 'aligned':
                return '<m:eqArr>' + ''.join(f'<m:e>{"".join(r)}</m:e>' for r in rows) + '</m:eqArr>'
            ncol = max(len(r) for r in rows)
            jc = 'left' if env == 'cases' else 'center'
            mat = (f'<m:m><m:mPr><m:mcs><m:mc><m:mcPr><m:count m:val="{ncol}"/><m:mcJc m:val="{jc}"/></m:mcPr></m:mc>'
                   '</m:mcs></m:mPr>'
                   + ''.join('<m:mr>' + ''.join(f'<m:e>{c}</m:e>' for c in r + [''] * (ncol - len(r))) + '</m:mr>'
                             for r in rows) + '</m:m>')
            d = {'pmatrix': ('(', ')'), 'bmatrix': ('[', ']'), 'cases': ('{', ''), 'vmatrix': ('|', '|')}.get(env)
            if env not in ('matrix', 'pmatrix', 'bmatrix', 'cases', 'vmatrix'):
                raise ValueError('unsupported environment ' + env)
            if d:
                return (f'<m:d><m:dPr><m:begChr m:val="{d[0]}"/><m:endChr m:val="{d[1]}"/></m:dPr>'
                        f'<m:e>{mat}</m:e></m:d>')
            return mat
        raise ValueError(f'unsupported LaTeX command \\{name}')


def _merge(xml):
    """Merge adjacent plain italic runs so that Word sees ordinary operator spacing."""
    pat = re.compile(r'<m:r><m:t xml:space="preserve">([^<]*)</m:t></m:r><m:r><m:t xml:space="preserve">([^<]*)</m:t></m:r>')
    while True:
        new = pat.sub(r'<m:r><m:t xml:space="preserve">\1\2</m:t></m:r>', xml)
        if new == xml:
            return xml
        xml = new


def to_omml(latex, macros=None):
    p = Parser(latex, macros)
    body = p.sequence(())
    if p.peek() is not None:
        raise ValueError('trailing input in formula: ' + latex)
    return _merge(body)


def omath(latex, macros=None):
    return f'<m:oMath xmlns:m="{MNS}">{to_omml(latex, macros)}</m:oMath>'


def omath_para(latex, macros=None):
    return (f'<m:oMathPara xmlns:m="{MNS}"><m:oMathParaPr><m:jc m:val="center"/></m:oMathParaPr>'
            f'<m:oMath>{to_omml(latex, macros)}</m:oMath></m:oMathPara>')


if __name__ == '__main__':
    import sys
    from lxml import etree
    for s in [r'F_{G}(s)=\frac{G_{X}(s)}{G_{H}(s)}-1', r'K_{\mathrm{I}}=\frac{E}{2}\,I^{(1)}',
              r'\theta=2\arctan\left(\frac{K_{\mathrm{I}}-\sqrt{K_{\mathrm{I}}^{2}+8K_{\mathrm{II}}^{2}}}{4K_{\mathrm{II}}}\right)',
              r'I=\int_{A}\left[\sigma_{ij}u_{i,1}^{\mathrm{aux}}-W\delta_{1j}\right]q_{,j}\,\mathrm{d}A',
              r'\begin{aligned}a&=b+c\\ d&=e\end{aligned}', r'\mathbf{D}=\frac{E}{1-\nu^{2}}\begin{pmatrix}1&\nu&0\\ \nu&1&0\\ 0&0&\frac{1-\nu}{2}\end{pmatrix}',
              r'x\le 0{,}35\ \text{мм}']:
        etree.fromstring(omath(s))
        print('ok', s)
