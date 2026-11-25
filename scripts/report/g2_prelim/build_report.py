# -*- coding: utf-8 -*-
"""Build the Ukrainian G2 preliminary report (editable .docx with native equations).

usage: python scripts/report/g2_prelim/build_report.py <repo> <figdir> <out_raw.docx> [--ledger <out.json>]

Reads committed evidence of the reviewed snapshot only; performs no FEM and writes nothing but the
output document (and, optionally, the numbering map used by the claim ledger). The raw .docx is then
passed through render_pdf.ps1, which lets Microsoft Word update the fields and export the PDF.
"""
import importlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from docx_kit import Report          # noqa: E402
from common import MACROS, BIB, Evidence   # noqa: E402

TITLE_SHORT = 'Метакомпозит G2 — проміжний науковий звіт, стан на 25.11.2026'
PARTS = [('ch01_02', ['front', 'ch1', 'ch2']), ('ch03', ['ch3']), ('ch04', ['ch4']), ('ch05', ['ch5']),
         ('ch06', ['ch6']), ('ch07', ['ch7']), ('ch08', ['ch8']), ('ch09', ['ch9']),
         ('ch10_11', ['ch10', 'ch11', 'refs']), ('appendix', ['app_a'])]


def main():
    repo, figdir, out = sys.argv[1], sys.argv[2], sys.argv[3]
    D = Evidence(repo)
    R = Report(MACROS, BIB)
    for mod, fns in PARTS:
        if not os.path.exists(os.path.join(HERE, mod + '.py')):
            print('  (part not present yet: %s)' % mod)
            continue
        m = importlib.import_module(mod)
        for fn in fns:
            getattr(m, fn)(R, D, figdir)
    errors = R.render(out, TITLE_SHORT)
    print('counts', R.counts)
    if '--ledger' in sys.argv:
        with open(sys.argv[sys.argv.index('--ledger') + 1], 'w', encoding='utf-8') as f:
            json.dump({'numbers': R.num, 'cited': R.cited, 'counts': R.counts}, f, ensure_ascii=False, indent=1)
    if errors:
        print('ERRORS (%d):' % len(errors))
        for e in errors:
            print('  ', e)
        sys.exit(2)
    print('saved', out)


if __name__ == '__main__':
    main()
