# -*- coding: utf-8 -*-
"""Independent check of the principal numbers of the G2 preliminary report (and generator of the claim ledger).

usage
  python scripts/report/g2_prelim/check_report_numbers.py [--repo <clone>] [--docx <report.docx>]
                                                          [--numbering <numbering.json>] [--out <dir>] [--ledger]

What it does (stdlib only, no FEM, no MATLAB, nothing is written outside --out):
  1. reads the committed evidence of the reviewed snapshot 05bc5f1 (JSON, CSV, one campaign log),
  2. recomputes every principal number that the report quotes (identities, ratios, recurrences, distances),
  3. compares the recomputed value with the value STATED in the report text, hard-coded below with its printed
     rounding; tolerance = half a unit of the last printed digit (bounds: the printed bound itself),
  4. optionally (--docx) looks the stated string up in the text of the built report and warns when it is absent,
  5. writes NUMBERS_CHECK.json and prints a PASS/FAIL table (exit code 1 when a check FAILS),
  6. with --ledger regenerates CLAIM_EVIDENCE_LEDGER_UA.md and FIGURE_INVENTORY_UA.md; section, table and figure
     numbers are read from the numbering map written by build_report.py --ledger (--numbering), so the documents
     can be re-run after the report numbering changes.

A "negative control" row states a historical value that the report REPLACES (for example -1,83 % -> -1,82 %);
it is expected to be rejected by the tolerance, and it counts as a pass only when it is rejected.
"""
import argparse
import csv
import hashlib
import json
import math
import os
import re
import sys
import zipfile
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
OUT_REL = os.path.join('reports', 'G2', 'preliminary_20261125')

MINUS = '−'
E_M = 3268.115                      # MPa, matrix modulus (plane stress, E' = E)
CASES = ['H', 'stiff13', 'soft2', 'soft1']
ARCH = CASES[1:]
CENTRES = [(152.4, 69.85), (152.4, 120.65), (152.4, 171.45)]
R_RING = 19.05
R_GUIDE = 15.0
KCONV = 1000.0 * math.sqrt(1e-3)    # N mm^-3/2 -> MPa sqrt(m) per kN


# ------------------------------------------------------------------------------------------ formatting
def parse_ua(s):
    """'-3,93' -> (-3.93, 2); accepts true minus, decimal comma, spaces, trailing %."""
    t = s.replace(MINUS, '-').replace(' ', '').replace(' ', '').replace(' ', '').replace('%', '')
    t = t.replace(',', '.')
    if t.startswith('+'):
        t = t[1:]
    dec = len(t.split('.')[1]) if '.' in t else 0
    return float(t), dec


def fmt_ua(x, dec=3, signed=False):
    s = ('%+.*f' if signed else '%.*f') % (dec, x)
    return s.replace('-', MINUS).replace('.', ',')


def fmt_sci(x):
    if x == 0:
        return '0'
    m, e = ('%.3e' % x).split('e')
    return m.replace('-', MINUS).replace('.', ',') + 'e' + str(int(e))


# ------------------------------------------------------------------------------------------ check registry
class Checker:
    def __init__(self, text=None):
        self.rows = []
        self.text = text            # normalised text of the built report (or None)

    def _probe(self, s):
        if self.text is None or s is None or s is False:
            return None
        return s in self.text

    def _add(self, **kw):
        kw.setdefault('negative', False)
        kw.setdefault('sec', [])
        kw.setdefault('textFound', None)
        kw['status'] = ('PASS' if kw['ok'] else 'FAIL')
        if kw['negative']:
            kw['status'] = 'REJECTED' if not kw['ok'] else 'FAIL'
        self.rows.append(kw)
        return kw

    def eq(self, cid, fam, desc, computed, stated, scale=1.0, sec=(), probe=None, negative=False):
        """stated: printed string, e.g. '-3,93'; tolerance = half unit of the last printed digit."""
        val, dec = parse_ua(stated)
        comp = computed * scale
        tol = 0.5 * 10 ** (-dec)
        dev = abs(comp - val)
        ok = dev <= tol + 1e-12 * max(1.0, abs(val))
        return self._add(id=cid, family=fam, desc=desc, computed=fmt_ua(comp, dec + 2), stated=stated,
                         tol='±%s' % fmt_ua(tol, dec + 1), dev=dev, ok=ok, negative=negative, sec=list(sec),
                         textFound=self._probe(probe if probe is not None else stated))

    def many(self, cid, fam, desc, pairs, sec=()):
        """pairs: (label, computed, stated_string, scale); every pair must lie within its half-unit tolerance."""
        worst, worst_lab, nbad = 0.0, '', 0
        bad = []
        for lab, comp, st, scale in pairs:
            val, dec = parse_ua(st)
            tol = 0.5 * 10 ** (-dec)
            dev = abs(comp * scale - val)
            r = dev / tol
            if r > worst:
                worst, worst_lab = r, lab
            if dev > tol + 1e-12 * max(1.0, abs(val)):
                nbad += 1
                bad.append('%s: %s vs %s' % (lab, fmt_ua(comp * scale, dec + 2), st))
        ok = nbad == 0
        return self._add(id=cid, family=fam, desc=desc, computed='n=%d; max |відх.|/допуск = %.3f (%s)' % (len(pairs), worst, worst_lab),
                         stated='усі %d значень у межах ½ одиниці останнього розряду' % len(pairs), tol='½ розряду',
                         dev=worst, ok=ok, sec=list(sec), bad=bad)

    def bound(self, cid, fam, desc, computed, op, limit, stated, sec=(), probe=None):
        ok = computed <= limit if op == 'le' else computed >= limit
        return self._add(id=cid, family=fam, desc=desc, computed=fmt_sci(computed), stated=('≤ ' if op == 'le' else '≥ ') + stated,
                         tol='межа', dev=computed - limit, ok=ok, sec=list(sec), textFound=self._probe(probe))

    def flag(self, cid, fam, desc, computed, stated, sec=(), probe=None):
        ok = (computed == stated)
        return self._add(id=cid, family=fam, desc=desc, computed=str(computed), stated=str(stated), tol='збіг', dev=0.0 if ok else 1.0,
                         ok=ok, sec=list(sec), textFound=self._probe(probe))


# ------------------------------------------------------------------------------------------ evidence
class Ev:
    def __init__(self, repo):
        self.repo = repo
        self.used = {}
        dr = os.path.join(repo, 'docs', 'research')
        self.p = {
            'LP2A': os.path.join(dr, 'G2_LP2_evidence', 'campaign_20261125', 'LP2A_ANALYSIS.json'),
            'LP2A_LOG': os.path.join(dr, 'G2_LP2_evidence', 'campaign_20261125', 'lp2a_campaign.log'),
            'MESH_SCAN': os.path.join(dr, 'G2_LP2_evidence', 'LP2_MESH_SCAN.json'),
            'X6': os.path.join(dr, 'G2_M5_X6_evidence', 'campaign_20261125', 'M5X6_ANALYSIS.json'),
            'X6_DIAG': os.path.join(dr, 'G2_M5_X6_evidence', 'M5X6_DIAGONAL_AUDIT.json'),
            'G1': os.path.join(dr, 'G2_G1_evidence', 'G1_FIELD_EVIDENCE.json'),
            'M5': os.path.join(dr, 'G2_M5_evidence', 'M5_EXISTING_EVIDENCE.json'),
            'A1': os.path.join(repo, 'matlab', 'g2', 'evidence', 'a1_campaign_20261122', 'campaign', 'A1_ANALYSIS.json'),
            'LP1': os.path.join(repo, 'reports', 'G2', 'LP1_20261122_v3', 'LP1_COMPARISON.json'),
            'A2_RECON': os.path.join(dr, 'G2_LP2A2_evidence', 'supplement', 'LP2A2_RECONCILIATION.json'),
            'A2_SUPP': os.path.join(dr, 'G2_LP2A2_evidence', 'supplement', 'LP2A2_SUPPLEMENT.json'),
            'A2_ATT2': os.path.join(dr, 'G2_LP2A2_evidence', 'attempt2', 'LP2A2_MESH_QUALIFICATION_ATTEMPT2.json'),
            'A2_SUM2': os.path.join(dr, 'G2_LP2A2_evidence', 'attempt2', 'LP2A2_SUMMARY_ATTEMPT2.json'),
        }
        evd = os.path.join(repo, 'matlab', 'g2', 'evidence')
        self.c = {
            'M4B': os.path.join(evd, 'm4b_20261121', 'analysis', 'cases_16_logical.csv'),
            'M2': os.path.join(evd, 'm2_20261121', 'report', 'm2_results.csv'),
            'M3': os.path.join(evd, 'm3_20261121', 'analysis', 'm3_decomposition.csv'),
            'R1': os.path.join(evd, 'm4b_r1_20261121', 'analysis', 'r1_crossfamily.csv'),
        }
        self._cache = {}

    def _note(self, path):
        rel = os.path.relpath(path, self.repo).replace('\\', '/')
        if rel not in self.used:
            h = hashlib.sha256()
            with open(path, 'rb') as f:
                for chunk in iter(lambda: f.read(1 << 20), b''):
                    h.update(chunk)
            self.used[rel] = h.hexdigest()
        return rel

    def j(self, key):
        if key not in self._cache:
            self._note(self.p[key])
            with open(self.p[key], encoding='utf-8-sig') as f:
                self._cache[key] = json.load(f)
        return self._cache[key]

    def csv(self, key):
        k = 'csv:' + key
        if k not in self._cache:
            self._note(self.c[key])
            with open(self.c[key], encoding='utf-8-sig', newline='') as f:
                self._cache[k] = list(csv.DictReader(f))
        return self._cache[k]

    def log(self, key):
        self._note(self.p[key])
        with open(self.p[key], encoding='utf-8-sig') as f:
            return f.read()


def docx_text(path):
    """Plain text of a .docx (paragraph per line, runs joined, nbsp/thin spaces removed) -- stdlib only."""
    ns = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
    with zipfile.ZipFile(path) as z:
        root = ET.fromstring(z.read('word/document.xml'))
    out = []
    for par in root.iter(ns + 'p'):
        parts = []
        for r in par.iter(ns + 'r'):
            for el in r:
                if el.tag == ns + 't':
                    parts.append(el.text or '')
                elif el.tag == ns + 'tab':
                    parts.append('\t')
        out.append(''.join(parts))
    txt = '\n'.join(out)
    return txt.replace(' ', ' ').replace(' ', ' ').replace(' ', ' ')


def toc_titles(text):
    """{'7.3': 'title'} from the table of contents of the built report (lines 'N.M. title<TAB>page')."""
    out = {}
    if not text:
        return out
    for ln in text.split('\n'):
        m = re.match(r'^(?:Розділ\s+)?(\d+(?:\.\d+)*)\.\s+(.+)\t\d+\s*$', ln)
        if m and m.group(1) not in out:
            out[m.group(1)] = m.group(2).strip()
    return out


def sgn(x):
    return '+' if x > 0 else ('-' if x < 0 else '0')


def dist_to_circle(tip, ring):
    cx, cy = CENTRES[ring]
    return math.hypot(tip[0] - cx, tip[1] - cy) - R_RING


# ------------------------------------------------------------------------------------------ the checks
def run_checks(ev, ck):
    A = ev.j('LP2A')
    W = A['states']
    n = len(W['H']['s'])
    assert n == 9

    # ---------------------------------------------------------------- 1. identities on S0-S8 (36 states)
    res = 0.0
    for c in CASES:
        for i in range(n):
            g = (W[c]['KI'][i] ** 2 + W[c]['KII'][i] ** 2) / E_M
            res = max(res, abs(g - W[c]['G'][i]) / W[c]['G'][i])
    ck.bound('N-01', 'LP2A', 'G = (K_I^2 + K_II^2)/E для всіх 36 станів S0-S8: найбільша відносна нев’язка зі збереженим G',
             res, 'le', 1e-12, '10⁻¹²', sec=['sec:derived', 'sec:edi'])
    rec = 0.0
    for c in CASES:
        h, t = W[c]['head'], W[c]['MTS']
        rec = max(rec, abs(h[0] - 90.0))
        for i in range(n - 1):
            rec = max(rec, abs(h[i + 1] - (h[i] + t[i])))
    ck.bound('N-02', 'LP2A', 'Рекурентність курсу φ_{n+1} = φ_n + θ_n (+ φ_0 = 90°): найбільша нев’язка, градуси',
             rec, 'le', 1e-9, '10⁻⁹°', sec=['sec:mts'])
    rec2 = 0.0
    for c in ARCH:
        X = A[c]
        for i in range(n):
            rec2 = max(rec2, abs(X['dHeading_deg'][i] - (W[c]['head'][i] - W['H']['head'][i])))
            rec2 = max(rec2, abs(X['dMTS_deg'][i] - (W[c]['MTS'][i] - W['H']['MTS'][i])))
            rec2 = max(rec2, abs(X['F_G'][i] - (W[c]['G'][i] / W['H']['G'][i] - 1.0)) * 100.0)
        for i in range(n - 1):
            rec2 = max(rec2, abs(X['dHeading_deg'][i + 1] - (X['dHeading_deg'][i] + X['dMTS_deg'][i])))
    ck.bound('N-03', 'LP2A', 'Збережені Δφ, Δθ, F_G збігаються з перерахованими з станів; Δφ_{n+1} = Δφ_n + Δθ_n (макс. нев’язка, град. або %)',
             rec2, 'le', 1e-9, '10⁻⁹', sec=['sec:derived'])
    # lateral offset recomputed from the tips: d_n = (x_X - x_H) . n_H, n_H = left normal of H last segment
    dres = 0.0
    for c in ARCH:
        for i in range(n):
            t = W['H']['t'][i]
            nv = (-t[1], t[0])
            dx = W[c]['tip'][i][0] - W['H']['tip'][i][0]
            dy = W[c]['tip'][i][1] - W['H']['tip'][i][1]
            dres = max(dres, abs(dx * nv[0] + dy * nv[1] - A[c]['d_mm'][i]))
    ck.bound('N-04', 'LP2A', 'Бічне зміщення d_n: перераховано проєкцією різниці вершин на ліву нормаль останнього відрізка H; макс. відхилення, мм',
             dres, 'le', 1e-9, '10⁻⁹ мм', sec=['sec:derived'])

    # ---------------------------------------------------------------- 2. own-path contrast F_G
    stated_fg = {  # abstract / section 5.4, two decimals
        ('stiff13', 0): '−3,93', ('stiff13', 4): '−7,17', ('stiff13', 8): '−10,95',
        ('soft2', 0): '−4,26', ('soft2', 4): '−2,93', ('soft2', 8): '−1,49',
        ('soft1', 0): '+2,75', ('soft1', 4): '+6,33', ('soft1', 8): '+10,73'}
    k = 5
    for (c, i), st in stated_fg.items():
        ck.eq('N-%02d' % k, 'LP2A', 'F_G(%s) у стані S%d, %%' % (c, i), A[c]['F_G'][i], st, 100.0, sec=['sec:evol'])
        k += 1
    T15 = {  # Table 15, three decimals
        'stiff13': ['−3,931', '−4,497', '−5,348', '−6,241', '−7,173', '−8,136', '−9,111', '−10,066', '−10,949'],
        'soft2': ['−4,259', '−3,881', '−3,577', '−3,260', '−2,932', '−2,593', '−2,242', '−1,875', '−1,488'],
        'soft1': ['+2,746', '+3,274', '+4,239', '+5,258', '+6,329', '+7,441', '+8,573', '+9,688', '+10,732']}
    pairs = [('%s S%d' % (c, i), A[c]['F_G'][i], T15[c][i], 100.0) for c in ARCH for i in range(n)]
    ck.many('N-14', 'LP2A', 'Табл. 15: F_G(S0..S8) для трьох архітектур, % (27 значень)', pairs, sec=['sec:evol'])
    # H1 / H2 strict monotonicity S4..S8 and printed endpoints (6 decimals)
    s48 = range(4, 9)
    inc = lambda L: all(L[i + 1] > L[i] for i in range(len(L) - 1))
    dec = lambda L: all(L[i + 1] < L[i] for i in range(len(L) - 1))
    ck.flag('N-15', 'LP2A', 'H1: F_G(stiff13) < 0 і строго спадає на S4-S8; H2: F_G(soft2) < 0 і строго зростає; soft1 > 0 і зростає',
            (dec([A['stiff13']['F_G'][i] for i in s48]) and all(A['stiff13']['F_G'][i] < 0 for i in s48),
             inc([A['soft2']['F_G'][i] for i in s48]) and all(A['soft2']['F_G'][i] < 0 for i in s48),
             inc([A['soft1']['F_G'][i] for i in s48]) and all(A['soft1']['F_G'][i] > 0 for i in s48)),
            (True, True, True), sec=['sec:p_hres'])
    ck.many('N-16', 'LP2A', 'H1/H2: кінцеві значення F_G на S4 і S8 (6 знаків), %', [
        ('stiff13 S4', A['stiff13']['F_G'][4], '−7,173170', 100.0), ('stiff13 S8', A['stiff13']['F_G'][8], '−10,948893', 100.0),
        ('soft2 S4', A['soft2']['F_G'][4], '−2,931815', 100.0), ('soft2 S8', A['soft2']['F_G'][8], '−1,488351', 100.0)],
        sec=['sec:p_hres'])

    # ---------------------------------------------------------------- 3. absolute G
    st_growth = {'H': '66,37', 'stiff13': '59,60', 'soft2': '68,84', 'soft1': '73,26'}
    for j, c in enumerate(CASES):
        ck.eq('N-%02d' % (17 + j), 'LP2A', 'Зростання абсолютної G між S4 і S8, %%: %s' % c, W[c]['G'][8] / W[c]['G'][4] - 1.0, st_growth[c], 100.0,
              sec=['sec:abs', 'sec:p_K'])
    T16 = {'H': ('0,8585', '1,5390', '2,5604', '2,983'), 'stiff13': ('0,8247', '1,4286', '2,2800', '2,765'),
           'soft2': ('0,8219', '1,4938', '2,5223', '3,069'), 'soft1': ('0,8820', '1,6364', '2,8352', '3,214')}
    pairs = []
    for c in CASES:
        for i, st in zip((0, 4, 8), T16[c][:3]):
            pairs.append(('%s S%d' % (c, i), W[c]['G'][i], st, 1e8))
        pairs.append(('%s G8/G0' % c, W[c]['G'][8] / W[c]['G'][0], T16[c][3], 1.0))
    ck.many('N-21', 'LP2A', 'Табл. 16: G·10⁸ у S0, S4, S8 (Н/мм за P = 1 Н) і G(S8)/G(S0)', pairs, sec=['sec:abs'])
    r04 = {'H': '1,79', 'stiff13': '1,73', 'soft2': '1,82', 'soft1': '1,86'}
    ck.many('N-22', 'LP2A', 'G(S4)/G(S0) за сталої сили (розд. 6.2): 1,79 / 1,73 / 1,82 / 1,86', [
        (c, W[c]['G'][4] / W[c]['G'][0], r04[c], 1.0) for c in CASES], sec=['sec:m5'])

    # ---------------------------------------------------------------- 4. heading, local-angle difference, S9 identity
    ck.eq('N-23', 'LP2A', 'Δφ(stiff13) у S8, градуси', A['stiff13']['dHeading_deg'][8], '+0,023460', sec=['sec:p_dir'])
    ck.eq('N-24', 'LP2A', 'Δθ(stiff13) у S8, градуси', A['stiff13']['dMTS_deg'][8], '+0,382882', sec=['sec:p_dir'])
    for j, (c, st) in enumerate([('stiff13', '+0,406342'), ('soft1', '−0,060412'), ('soft2', '−0,506161')]):
        ck.eq('N-%02d' % (25 + j), 'LP2A', 'Геометричний прогноз S9: Δφ_9 = Δφ_8 + Δθ_8 (%s), градуси' % c,
              A[c]['dHeading_deg'][8] + A[c]['dMTS_deg'][8], st, sec=['sec:p_dir'])
    pat = {}
    for c in ARCH:
        pat[c] = ''.join('o' if sgn(A[c]['dHeading_deg'][i]) != sgn(A[c]['dMTS_deg'][i]) else 's' for i in range(4, 8 + 1))
    ck.flag('N-28', 'LP2A', 'Знаки Δφ і Δθ у S4..S8 (o - протилежні, s - однакові): stiff13 oooos, soft1 ooooo, soft2 sssss',
            (pat['stiff13'], pat['soft1'], pat['soft2']), ('oooos', 'ooooo', 'sssss'), sec=['sec:p_dir', 'sec:p_split'])
    ck.flag('N-29', 'LP2A', 'sign(d) = sign(F_G) на S4..S8 для всіх трьох архітектур',
            all(sgn(A[c]['d_mm'][i]) == sgn(A[c]['F_G'][i]) for c in ARCH for i in s48), True, sec=['sec:p_dir', 'sec:c_table'])
    ck.many('N-30', 'LP2A', 'Бічне зміщення d у S8, мм: −0,278 / −0,209 / +0,495 (3 знаки)', [
        ('stiff13', A['stiff13']['d_mm'][8], '−0,278', 1.0), ('soft2', A['soft2']['d_mm'][8], '−0,209', 1.0),
        ('soft1', A['soft1']['d_mm'][8], '+0,495', 1.0)], sec=['sec:c_table'])
    ck.eq('N-31', 'LP2A', 'Найбільше розходження траєкторій max|d| на S0-S8, мм («не більше ніж на 0,495 мм»)',
          max(abs(v) for c in ARCH for v in A[c]['d_mm']), '0,495', sec=['sec:p_sum'])
    ck.many('N-32', 'LP2A', 'Табл. 36: d (мм), Δφ і Δθ (град.) у S4..S8, 6 знаків (45 значень)', _table36(A), sec=['sec:p_dir'])
    ck.many('N-33', 'LP2A', 'd(stiff13): S7→S8 змінюється лише на +0,0023 мм (немає роздільної здатності)', [
        ('d8-d7', A['stiff13']['d_mm'][8] - A['stiff13']['d_mm'][7], '+0,0023', 1.0)], sec=['sec:p_dir'])
    ck.many('N-34', 'LP2A', '|Δθ| зростає S4→S8 у 4,9 (stiff13) і 4,4 (soft1) раза; |Δφ| досягає максимуму в S2: −0,715° / +1,124°', [
        ('stiff13 |dTh8/dTh4|', A['stiff13']['dMTS_deg'][8] / A['stiff13']['dMTS_deg'][4], '4,9', 1.0),
        ('soft1 |dTh8/dTh4|', A['soft1']['dMTS_deg'][8] / A['soft1']['dMTS_deg'][4], '4,4', 1.0),
        ('stiff13 dPhi(S2)', A['stiff13']['dHeading_deg'][2], '−0,715', 1.0),
        ('soft1 dPhi(S2)', A['soft1']['dHeading_deg'][2], '+1,124', 1.0)], sec=['sec:p_split', 'sec:p_hres'])
    ck.flag('N-35', 'LP2A', 'Для stiff13 і soft1 |Δφ| максимальний у S2 і далі монотонно спадає; для soft2 |Δφ| зростає на S1-S8',
            (all(abs(A[c]['dHeading_deg'][i + 1]) < abs(A[c]['dHeading_deg'][i]) for c in ('stiff13', 'soft1') for i in range(2, 8))
             and all(abs(A[c]['dHeading_deg'][2]) > abs(A[c]['dHeading_deg'][1]) for c in ('stiff13', 'soft1')),
             all(abs(A['soft2']['dHeading_deg'][i + 1]) > abs(A['soft2']['dHeading_deg'][i]) for i in range(1, 8))), (True, True),
            sec=['sec:p_split'])
    # soft2 zero crossing
    f = A['soft2']['F_G']
    step = f[8] - f[7]
    z_last = 57.4 + (-f[8]) / step * 4.0
    z_chord = 57.4 + (-f[8]) / ((f[8] - f[4]) / 16.0)
    ck.many('N-36', 'LP2A', 'Лінійна екстраполяція F_G(soft2) до нуля: 72,8 мм (за останнім кроком) і 73,9 мм (за хордою S4-S8); приріст за крок 0,34→0,39 п.п.', [
        ('останній крок', z_last, '72,8', 1.0), ('хорда S4-S8', z_chord, '73,9', 1.0),
        ('приріст S4-S5', (f[5] - f[4]) * 100, '0,34', 1.0), ('приріст S7-S8', (f[8] - f[7]) * 100, '0,39', 1.0)], sec=['sec:p_hres'])
    # first kink share
    fks = {}
    for c, st in (('stiff13', '0,969'), ('soft2', '0,798'), ('soft1', '0,990')):
        fks[c] = (16.0 * math.sin(math.radians(A[c]['dMTS_deg'][0])) / A[c]['d_mm'][4], st)
    ck.many('N-37', 'LP2A', 'Лінеаризована частка першого зламу 16 sin(Δθ_0)/d(S4): 0,969 / 0,798 / 0,990', [
        (c, v, st, 1.0) for c, (v, st) in fks.items()], sec=['sec:m5', 'sec:c_answer'])

    # ---------------------------------------------------------------- 5. distances to rings (S8, S9 candidate)
    term = {t['caseId']: t for t in A['H4']['terminals']}
    d1 = {c: dist_to_circle(W[c]['tip'][8], 0) for c in CASES}
    st_d1 = {'H': '24,323', 'stiff13': '24,096', 'soft2': '24,158', 'soft1': '24,731'}
    pairs = [('%s S8' % c, d1[c], st_d1[c], 1.0) for c in CASES]
    ck.many('N-38', 'LP2A', 'Відстань вершини S8 до номінального кола кільця 1 (R = 19,05 мм), перерахована з координат вершин, мм (табл. 38, 39)', pairs,
            sec=['sec:p_dist'])
    ck.many('N-39', 'LP2A', 'Діапазон відстаней вершин S8 до кола кільця 1: 24,096-24,731 мм (мін/макс)', [
        ('мін', min(d1.values()), '24,096', 1.0), ('макс', max(d1.values()), '24,731', 1.0)], sec=['sec:p_dist', 'sec:c_not'])
    ck.flag('N-40', 'LP2A', 'Перерахована відстань збігається зі збереженою (ringDistance, terminal.clearanceToRingCircles) до 10⁻⁹ мм',
            max(max(abs(d1[c] - W[c]['ring'][8][0]) for c in CASES), max(abs(d1[c] - term[c]['clearanceToRingCircles_mm'][0]) for c in CASES)) < 1e-9, True,
            sec=['sec:p_dist'])
    d23 = [dist_to_circle(W[c]['tip'][8], r) for c in CASES for r in (1, 2)]
    ck.many('N-41', 'LP2A', 'Відстані S8 до кіл кілець 2 і 3: 57,6-57,8 і 103,6-103,7 мм; запас до 15-мм напрямної 9,1-9,7 мм', [
        ('кільце 2 мін', min(dist_to_circle(W[c]['tip'][8], 1) for c in CASES), '57,6', 1.0),
        ('кільце 2 макс', max(dist_to_circle(W[c]['tip'][8], 1) for c in CASES), '57,8', 1.0),
        ('кільце 3 мін', min(dist_to_circle(W[c]['tip'][8], 2) for c in CASES), '103,6', 1.0),
        ('кільце 3 макс', max(dist_to_circle(W[c]['tip'][8], 2) for c in CASES), '103,7', 1.0),
        ('запас мін', min(d1.values()) - R_GUIDE, '9,1', 1.0), ('запас макс', max(d1.values()) - R_GUIDE, '9,7', 1.0)], sec=['sec:p_dist'])
    s9 = {}
    for c in CASES:
        cand = W[c]['terminal']['candidate']
        poly = cand['polyline_mm'][-1]
        cl = cand['clearance']
        s9[c] = (poly, cl['tipToNominalRing_mm'][0], cl['tipToRingPolygon_mm'][0])
    st_s9 = {'H': ('113,009', '59,455', '21,689', '21,691'), 'stiff13': ('113,251', '59,387', '21,473', '21,476'),
             'soft2': ('113,239', '59,373', '21,488', '21,491'), 'soft1': ('112,535', '59,594', '22,113', '22,114')}
    pairs = []
    for c in CASES:
        poly, dn, dp = s9[c]
        pairs += [('%s x' % c, poly[0], st_s9[c][0], 1.0), ('%s y' % c, poly[1], st_s9[c][1], 1.0),
                  ('%s до кола' % c, dn, st_s9[c][2], 1.0), ('%s до багатокутника' % c, dp, st_s9[c][3], 1.0)]
    ck.many('N-42', 'LP2A', 'Кандидат S9 (лише геометрія): координати, відстань до кола і до багатокутника кільця 1, мм (табл. 38, 39)', pairs, sec=['sec:p_dist'])
    dd = []
    for c in CASES:
        cl = W[c]['terminal']['candidate']['clearance']
        dd += [x - y for x, y in zip(cl['tipToRingPolygon_mm'], cl['tipToNominalRing_mm'])]
    ck.many('N-43', 'LP2A', 'Різниця «багатокутник - коло» для кандидатів S9 (три кільця × чотири кандидати): від 4,7·10⁻⁶ до 0,0033 мм; δ_max = R·(1 - cos π/76) = 0,0163 мм (рівн. 28)', [
        ('мін, ·10⁻⁶ мм', min(dd), '4,7', 1e6), ('макс, мм', max(dd), '0,0033', 1.0),
        ('δ_max, мм', R_RING * (1 - math.cos(math.pi / 76)), '0,0163', 1.0)], sec=['sec:p_dist'])
    # edge distances at S8
    pairs = []
    for c, (yy, top, left) in {'H': ('55,810', '147,390', '111,362'), 'stiff13': ('55,730', '147,470', '111,630'),
                              'soft2': ('55,743', '147,457', '111,560'), 'soft1': ('55,951', '147,249', '110,884')}.items():
        x, y = W[c]['tip'][8]
        pairs += [('%s y' % c, y, yy, 1.0), ('%s верхній край' % c, 203.2 - y, top, 1.0), ('%s лівий край' % c, x, left, 1.0)]
    ck.many('N-44', 'LP2A', 'Відстані S8 до нижнього, верхнього і лівого країв (табл. 39), мм', pairs, sec=['sec:p_dist'])

    # ---------------------------------------------------------------- 6. K_II/K_I, G in Table 34, phi/theta in Table 35
    ck.many('N-45', 'LP2A', 'Табл. 34: K_II/K_I у S4..S8 (5 знаків, 20 значень) і G·10⁸ (5 знаків, 20 значень)', _table34(A), sec=['sec:p_K'])
    ck.many('N-46', 'LP2A', 'Табл. 35: курс φ_n і приріст θ_n у S0..S8, град. (72 значення, 4 знаки)', _table35(A), sec=['sec:p_dir'])
    ck.many('N-47', 'LP2A', 'Знакові КІН: K_I·10³ і K_II·10⁵ у S8 (табл. 34)', [
        ('H KI', W['H']['KI'][8], '9,146881', 1e3), ('H KII', W['H']['KII'][8], '+10,24807', 1e5),
        ('stiff13 KI', W['stiff13']['KI'][8], '8,631902', 1e3), ('stiff13 KII', W['stiff13']['KII'][8], '+6,78508', 1e5),
        ('soft2 KI', W['soft2']['KI'][8], '9,078537', 1e3), ('soft2 KII', W['soft2']['KII'][8], '+10,34358', 1e5),
        ('soft1 KI', W['soft1']['KI'][8], '9,624798', 1e3), ('soft1 KII', W['soft1']['KII'][8], '+14,03784', 1e5)], sec=['sec:p_K'])
    ck.many('N-48', 'LP2A', 'Початкова тріщина (H, S0): K_I = 5,2632·10⁻³, K_II = +0,5954·10⁻³ Н·мм⁻³ᐟ²; 0,166436 і +0,018827 МПа·√м/кН; K_II/K_I = 0,1131', [
        ('KI', W['H']['KI'][0], '5,2632', 1e3), ('KII', W['H']['KII'][0], '+0,5954', 1e3),
        ('KI МПа√м/кН', W['H']['KI'][0] * KCONV, '0,166436', 1.0), ('KII МПа√м/кН', W['H']['KII'][0] * KCONV, '+0,018827', 1.0),
        ('KII/KI', W['H']['KII'][0] / W['H']['KI'][0], '0,1131', 1.0)], sec=['sec:v_sif'])

    # ---------------------------------------------------------------- 7. LP1/A0 family against LP2A (same states S0-S4)
    lp1 = ev.j('LP1')
    byk = {(r['caseId'], r['state']): r for r in lp1['data']}
    mx = {'G': 0.0, 'MTS': 0.0, 'head': 0.0, 'tip': 0.0, 'KI': 0.0, 'F_G': 0.0, 'd': 0.0}
    for c in CASES:
        for i in range(5):
            r = byk[(c, i)]
            mx['G'] = max(mx['G'], abs(r['G_N_per_mm_at_1N'] / W[c]['G'][i] - 1))
            mx['MTS'] = max(mx['MTS'], abs(r['MTS_local_deg'] - W[c]['MTS'][i]))
            mx['head'] = max(mx['head'], abs(r['heading_deg'] - W[c]['head'][i]))
            mx['tip'] = max(mx['tip'], abs(r['tip_x_mm'] - W[c]['tip'][i][0]), abs(r['tip_y_mm'] - W[c]['tip'][i][1]))
            mx['KI'] = max(mx['KI'], abs(r['KI_MPa_sqrt_m_per_kN'] / (W[c]['KI'][i] * KCONV) - 1))
            if c != 'H':
                mx['F_G'] = max(mx['F_G'], abs(r['F_G'] - A[c]['F_G'][i]))
                mx['d'] = max(mx['d'], abs(r['lateral_offset_mm'] - A[c]['d_mm'][i]))
    ck.bound('N-49', 'LP1/A0 ~ LP2A', 'Таблиці S0-S4: LP1_COMPARISON (вибір за caseId+state) і LP2A_ANALYSIS мають ті самі числа; макс. відносна різниця G, K_I',
             max(mx['G'], mx['KI']), 'le', 1e-9, '10⁻⁹', sec=['sec:evol', 'sec:v_lp1'])
    ck.bound('N-50', 'LP1/A0 ~ LP2A', 'Те саме: макс. абс. різниця θ, φ (град.), координат вершин (мм), F_G, d (мм)',
             max(mx['MTS'], mx['head'], mx['tip'], mx['F_G'], mx['d']), 'le', 1e-9, '10⁻⁹', sec=['sec:evol', 'sec:v_lp1'])
    # soft2 status: conservative rule
    ucons = {c: abs(byk[(c, 4)]['F_G']) / byk[(c, 4)]['U_cons_FG'] for c in ARCH}
    ck.many('N-51', 'LP1/A0', 'S4: |F_G|/U_cons: stiff13 2,21; soft1 1,70; soft2 0,863 (soft2 < 1: нерозрізнено за консервативним правилом)', [
        ('stiff13', ucons['stiff13'], '2,21', 1.0), ('soft1', ucons['soft1'], '1,70', 1.0), ('soft2', ucons['soft2'], '0,863', 1.0)], sec=['sec:v_soft2'])
    flags = {c: ''.join('1' if byk[(c, i)]['FG_conservative_resolved'] else '0' for i in range(5)) for c in ARCH}
    ck.flag('N-52', 'LP1/A0', 'Консервативне правило FG_conservative_resolved за S0..S4 (рядок станів): stiff13 11111, soft2 11100, soft1 00111; S4: soft2 = 0',
            (flags['stiff13'], flags['soft2'], flags['soft1']), ('11111', '11100', '00111'), sec=['sec:v_soft2'])
    q = lambda key: [byk[(c, i)][key] for c in CASES for i in range(5)]
    ck.many('N-53', 'LP1/A0', 'Показники якості 20 станів S0-S4: COD-EDI 0,8705-0,8794 %; розкид за областями 1,63-1,64·10⁻⁶; |J/G-1| 6,9·10⁻⁶...2,25·10⁻⁵', [
        ('COD-EDI мін', min(abs(x) for x in q('COD_EDI_fraction_Kref')), '0,8705', 100.0), ('COD-EDI макс', max(abs(x) for x in q('COD_EDI_fraction_Kref')), '0,8794', 100.0),
        ('розкид мін', min(q('contour_fraction_Kref')), '1,63', 1e6), ('розкид макс', max(q('contour_fraction_Kref')), '1,64', 1e6),
        ('|J/G-1| мін', min(abs(x) for x in q('J_identity_relative')), '6,9', 1e6), ('|J/G-1| макс', max(abs(x) for x in q('J_identity_relative')), '22,5', 1e6)],
        sec=['sec:v_lp1'])

    # ---------------------------------------------------------------- 8. LP2-A1 campaign log, Table 32 (S5-S8, 16 states)
    _check_log(ev, ck, A)

    # ---------------------------------------------------------------- 9. A1 (refined family B, state S4)
    _check_a1(ev, ck, A)
    # ---------------------------------------------------------------- 10. M2 / M4.B / R1
    _check_m4b(ev, ck)
    # ---------------------------------------------------------------- 11. M5-X6 crossed solves
    _check_x6(ev, ck, A)
    # ---------------------------------------------------------------- 12. M5 memorandum and G1
    _check_m5_g1(ev, ck, A)
    # ---------------------------------------------------------------- 13. LP2-A2 geometric qualification
    _check_lp2a2(ev, ck)
    _check_lp2a2_failures(ev, ck)


def _table36(A):
    T = {  # Table 36: d (mm), dphi, dtheta for S4..S8 (+ S9 forecast for dphi)
        'stiff13': (['−0,190902', '−0,231344', '−0,262619', '−0,280054', '−0,277757'],
                    ['−0,661086', '−0,583282', '−0,453847', '−0,257427', '+0,023460'],
                    ['+0,077804', '+0,129435', '+0,196420', '+0,280887', '+0,382882']),
        'soft2': (['−0,085163', '−0,113145', '−0,143242', '−0,175159', '−0,208658'],
                  ['−0,366900', '−0,402544', '−0,433719', '−0,460752', '−0,484460'],
                  ['−0,035644', '−0,031175', '−0,027033', '−0,023708', '−0,021701']),
        'soft1': (['+0,305671', '+0,373461', '+0,430889', '+0,473202', '+0,494777'],
                  ['+1,068209', '+0,979391', '+0,834177', '+0,620743', '+0,326589'],
                  ['−0,088819', '−0,145213', '−0,213434', '−0,294154', '−0,387001'])}
    pairs = []
    for c, (dd, ph, th) in T.items():
        for j, i in enumerate(range(4, 9)):
            pairs.append(('%s d S%d' % (c, i), A[c]['d_mm'][i], dd[j], 1.0))
            pairs.append(('%s dPhi S%d' % (c, i), A[c]['dHeading_deg'][i], ph[j], 1.0))
            pairs.append(('%s dTh S%d' % (c, i), A[c]['dMTS_deg'][i], th[j], 1.0))
    return pairs


def _table34(A):
    W = A['states']
    kk = {'H': ['0,01423', '0,01330', '0,01244', '0,01174', '0,01120'], 'stiff13': ['0,01355', '0,01217', '0,01073', '0,00928', '0,00786'],
          'soft2': ['0,01454', '0,01357', '0,01268', '0,01194', '0,01139'], 'soft1': ['0,01501', '0,01457', '0,01431', '0,01431', '0,01459']}
    gg = {'H': ['1,53896', '1,75257', '1,99175', '2,25989', '2,56037'], 'stiff13': ['1,42857', '1,60998', '1,81027', '2,03240', '2,28004'],
          'soft2': ['1,49384', '1,70712', '1,94709', '2,21750', '2,52227'], 'soft1': ['1,63636', '1,88298', '2,16249', '2,47882', '2,83516']}
    pairs = []
    for c in CASES:
        for j, i in enumerate(range(4, 9)):
            pairs.append(('%s KII/KI S%d' % (c, i), W[c]['KII'][i] / W[c]['KI'][i], kk[c][j], 1.0))
            pairs.append(('%s G S%d' % (c, i), W[c]['G'][i], gg[c][j], 1e8))
    return pairs


def _table35(A):
    W = A['states']
    ph = {'H': '90,0000 77,4042 76,4545 74,6138 72,8873 71,2575 69,7345 68,3091 66,9647',
          'stiff13': '90,0000 76,7416 75,7393 73,9151 72,2262 70,6742 69,2806 68,0516 66,9882',
          'soft2': '90,0000 77,1610 76,1704 74,2868 72,5204 70,8549 69,3008 67,8483 66,4803',
          'soft1': '90,0000 78,4884 77,5785 75,7239 73,9555 72,2369 70,5687 68,9298 67,2913'}
    th = {'H': '−12,5958 −0,9498 −1,8407 −1,7265 −1,6298 −1,5230 −1,4254 −1,3443 −1,2835',
          'stiff13': '−13,2584 −1,0022 −1,8242 −1,6889 −1,5520 −1,3936 −1,2290 −1,0634 −0,9006',
          'soft2': '−12,8390 −0,9905 −1,8837 −1,7664 −1,6654 −1,5542 −1,4524 −1,3680 −1,3052',
          'soft1': '−11,5116 −0,9099 −1,8547 −1,7684 −1,7186 −1,6682 −1,6388 −1,6385 −1,6705'}
    pairs = []
    for c in CASES:
        for i, (a, b) in enumerate(zip(ph[c].split(), th[c].split())):
            pairs.append(('%s phi S%d' % (c, i), W[c]['head'][i], a, 1.0))
            pairs.append(('%s theta S%d' % (c, i), W[c]['MTS'][i], b, 1.0))
    return pairs


def _check_log(ev, ck, A):
    txt = ev.log('LP2A_LOG')
    sif = re.findall(r'G2_M4B_SIF bits=(\d+) pass=(\d) KI=([\d.]+) KII=([+\-\d.]+) MPa sqrt\(m\)/kN, COD ([\d.]+) / ([+\-\d.]+), C=', txt)
    t3 = [int(x) for x in re.findall(r'G2_KJOIN_T3=(\d+)', txt)]
    acc = re.findall(r'G2_LP2A_ACCEPTED (\w+) S(\d) ', txt)
    W = A['states']
    if len(sif) < 16 or len(t3) < 16 or len(acc) != 16:
        ck.flag('N-54', 'LP2A', 'Журнал кампанії LP2-A1: 16 розв’язків, 16 прийнятих станів, 16 сіток', (len(sif), len(t3), len(acc)), (16, 16, 16), sec=['sec:p_exec'])
        return
    order = [(c, s) for c in CASES for s in (5, 6, 7, 8)]
    ok_pass = all(x[1] == '1' for x in sif[:16])
    cod = {}
    kerr = 0.0
    t3c = {}
    for idx, (c, s) in enumerate(order):
        b, p, ki, kii, kic, kiic = sif[idx]
        ki, kii, kic, kiic = float(ki), float(kii), float(kic), float(kiic)
        keff = math.hypot(ki, kii)
        cod.setdefault(c, []).append(max(abs(ki - kic), abs(kii - kiic)) / keff)
        kerr = max(kerr, abs(ki / KCONV / W[c]['KI'][s] - 1), abs(kii / KCONV / W[c]['KII'][s] - 1))
        t3c.setdefault(c, []).append(t3[idx])
    ck.flag('N-54', 'LP2A', 'Журнал LP2-A1: 16 розв’язків (pass=1), 16 записів ACCEPTED у порядку H, stiff13, soft2, soft1 × S5..S8',
            (ok_pass, tuple((c, int(s)) for c, s in acc) == tuple(order)), (True, True), sec=['sec:p_exec'])
    ck.bound('N-55', 'LP2A', 'K_I, K_II з журналу (МПа·√м/кН → Н·мм⁻³ᐟ²) збігаються з LP2A_ANALYSIS у S5-S8; макс. відносна різниця (9 знаків журналу)',
             kerr, 'le', 5e-8, '5·10⁻⁸', sec=['sec:p_exec'])
    allcod = [v for c in CASES for v in cod[c]]
    ck.many('N-56', 'LP2A', 'Табл. 32: COD-EDI (max|ΔK|/K_еф) у S5-S8, %: діапазони по конфігураціях і загальний 0,8757-0,8796', [
        ('H мін', min(cod['H']), '0,8777', 100.0), ('H макс', max(cod['H']), '0,8785', 100.0),
        ('stiff13 мін', min(cod['stiff13']), '0,8790', 100.0), ('stiff13 макс', max(cod['stiff13']), '0,8796', 100.0),
        ('soft2 мін', min(cod['soft2']), '0,8778', 100.0), ('soft2 макс', max(cod['soft2']), '0,8786', 100.0),
        ('soft1 мін', min(cod['soft1']), '0,8757', 100.0), ('soft1 макс', max(cod['soft1']), '0,8780', 100.0),
        ('усі мін', min(allcod), '0,8757', 100.0), ('усі макс', max(allcod), '0,8796', 100.0)], sec=['sec:p_exec'])
    ck.many('N-57', 'LP2A', 'Табл. 32: число трикутників T3 у S5-S8 (діапазони по конфігураціях; 16 сіток)', [
        ('H мін', min(t3c['H']), '29223', 1.0), ('H макс', max(t3c['H']), '29873', 1.0),
        ('stiff13 мін', min(t3c['stiff13']), '29241', 1.0), ('stiff13 макс', max(t3c['stiff13']), '29871', 1.0),
        ('soft2 мін', min(t3c['soft2']), '29217', 1.0), ('soft2 макс', max(t3c['soft2']), '29879', 1.0),
        ('soft1 мін', min(t3c['soft1']), '29245', 1.0), ('soft1 макс', max(t3c['soft1']), '29875', 1.0)], sec=['sec:p_exec'])


def _check_a1(ev, ck, A):
    a1 = ev.j('A1')
    rec = a1['records']
    h1 = rec['H'][0]['h1_mm'] / rec['H'][3]['h1_mm']
    ck.eq('A-01', 'A1 (B9)', 'Подрібнення першого ребра біля вершини h1(m=0)/h1(m=9) («в 4,23 раза»)', h1, '4,23', sec=['sec:v_a1'])
    dF = {c: a1['F_G'][c][3] - a1['F_G'][c][0] for c in ARCH}
    ck.bound('A-02', 'A1 (B9)', 'max |F_G(m=9) - F_G(m=0)| за трьома архітектурами ≤ 5,1·10⁻⁶ (абсолютні одиниці)', max(abs(v) for v in dF.values()), 'le', 5.1e-6,
             '5,1·10⁻⁶', sec=['sec:v_a1', 'sec:c_table'])
    ck.many('A-03', 'A1 (B9)', 'Табл. 12: F_G(9) - F_G(0), ·10⁻⁶: −4,48 / +1,18 / +5,08; F_G(9) - F_G(6): −0,86 / +0,23 / +0,97', [
        ('stiff13 9-0', dF['stiff13'], '−4,48', 1e6), ('soft2 9-0', dF['soft2'], '+1,18', 1e6), ('soft1 9-0', dF['soft1'], '+5,08', 1e6),
        ('stiff13 9-6', a1['F_G']['stiff13'][3] - a1['F_G']['stiff13'][2], '−0,86', 1e6),
        ('soft2 9-6', a1['F_G']['soft2'][3] - a1['F_G']['soft2'][2], '+0,23', 1e6),
        ('soft1 9-6', a1['F_G']['soft1'][3] - a1['F_G']['soft1'][2], '+0,97', 1e6)], sec=['sec:v_a1'])
    dG = {c: rec[c][3]['G'] / rec[c][0]['G'] - 1.0 for c in CASES}
    ck.many('A-04', 'A1 (B9)', 'Відносна зміна G між m=0 і m=9: 1,04-1,14·10⁻⁴ для всіх чотирьох конфігурацій', [
        ('мін', min(dG.values()), '1,04', 1e4), ('макс', max(dG.values()), '1,14', 1e4)], sec=['sec:v_a1', 'sec:c_table'])
    ck.bound('A-05', 'A1 (B9)', 'Зміна кута МКН між m=0 і m=9: менше 2·10⁻⁴ градуса', max(abs(rec[c][3]['MTS_deg'] - rec[c][0]['MTS_deg']) for c in CASES), 'le', 2e-4,
             '2·10⁻⁴°', sec=['sec:v_a1'])
    ck.many('A-06', 'A1 (B9)', 'Табл. 11: розбіжність COD-EDI (·10⁻³) для H на m=0 і m=9: 8,79 і 2,52; |J/G-1|·10⁶: 19,2 і 4,7', [
        ('m0 COD-EDI', abs(rec['H'][0]['CODminusEDI_rel']), '8,79', 1e3), ('m9 COD-EDI', abs(rec['H'][3]['CODminusEDI_rel']), '2,52', 1e3),
        ('m0 J/G', abs(rec['H'][0]['JoverGminus1']), '19,2', 1e6), ('m9 J/G', abs(rec['H'][3]['JoverGminus1']), '4,7', 1e6)], sec=['sec:v_a1'])
    t3 = {m: rec['H'][i]['T3'] for i, m in enumerate((0, 3, 6, 9))}
    ck.many('A-07', 'A1 (B9)', 'Табл. 10: трикутники T3 (H, S4) на рівнях m = 0, 3, 6, 9: 29 063 / 29 837 / 30 611 / 31 385; h1 0,04167 / 0,02577 / 0,01594 / 0,00986', [
        ('T3 m0', t3[0], '29063', 1.0), ('T3 m3', t3[3], '29837', 1.0), ('T3 m6', t3[6], '30611', 1.0), ('T3 m9', t3[9], '31385', 1.0),
        ('h1 m0', rec['H'][0]['h1_mm'], '0,04167', 1.0), ('h1 m3', rec['H'][1]['h1_mm'], '0,02577', 1.0),
        ('h1 m6', rec['H'][2]['h1_mm'], '0,01594', 1.0), ('h1 m9', rec['H'][3]['h1_mm'], '0,00986', 1.0)], sec=['sec:v_a1'])
    W = A['states']
    ck.many('A-08', 'A1 (B9) ~ LP1/A0', 'A1 на m=0 є збереженим розв’язком A0 стану S4: G·10⁸ (Табл. 11) і K_I·10³ збігаються зі станом S4 траєкторій LP1/A0', [
        ('H G', rec['H'][0]['G'], '1,538959', 1e8), ('stiff13 G', rec['stiff13'][0]['G'], '1,428567', 1e8), ('soft2 G', rec['soft2'][0]['G'], '1,493840', 1e8),
        ('soft1 G', rec['soft1'][0]['G'], '1,636359', 1e8), ('H KI', rec['H'][0]['KI'], '7,091176', 1e3), ('soft1 KI', rec['soft1'][0]['KI'], '7,312049', 1e3),
        ('H G vs LP2A', W['H']['G'][4], '1,538959', 1e8), ('H KI vs LP2A', W['H']['KI'][4], '7,091176', 1e3)], sec=['sec:v_a1'])
    # F_G at S4 on baseline (B0) and refined (B9)
    ck.many('A-09', 'A1 (B9)', 'Табл. 12: F_G(S4), %, на m=0 і m=9 (stiff13, soft2, soft1)', [
        ('stiff13 m0', a1['F_G']['stiff13'][0], '−7,17317', 100.0), ('stiff13 m9', a1['F_G']['stiff13'][3], '−7,17362', 100.0),
        ('soft2 m0', a1['F_G']['soft2'][0], '−2,93182', 100.0), ('soft2 m9', a1['F_G']['soft2'][3], '−2,93170', 100.0),
        ('soft1 m0', a1['F_G']['soft1'][0], '+6,32894', 100.0), ('soft1 m9', a1['F_G']['soft1'][3], '+6,32944', 100.0)], sec=['sec:v_a1'])


def _check_m4b(ev, ck):
    rows = ev.csv('M4B')
    by = {(float(r['contrast']), r['mask']): r for r in rows}
    fg = lambda ct, m: float(by[(ct, m)]['F_G'])
    fth = lambda ct, m: float(by[(ct, m)]['F_theta_deg'])
    ck.many('M-01', 'M4.B', 'Текст: одиночні кільця S2: м’які +4,43 / −3,63 / +2,33 %, жорсткі −3,65 / +3,04 / −1,82 %', [
        ('м’яке 1', fg(0.5, 'ring1'), '+4,43', 100.0), ('м’яке 2', fg(0.5, 'ring2'), '−3,63', 100.0), ('м’яке 3', fg(0.5, 'ring3'), '+2,33', 100.0),
        ('жорстке 1', fg(2.0, 'ring1'), '−3,65', 100.0), ('жорстке 2', fg(2.0, 'ring2'), '+3,04', 100.0), ('жорстке 3', fg(2.0, 'ring3'), '−1,82', 100.0)],
        sec=['sec:m4b', 'sec:c_answer'])
    ck.eq('M-02', 'M4.B', 'Жорстке кільце 3, S2: необокуглене F_G = −1,8248 % (запис у звіті: −1,82)', fg(2.0, 'ring3'), '−1,82', 100.0, sec=['sec:m4b'])
    ck.eq('M-03', 'M4.B', 'Негативний контроль: історичне значення −1,83 % для жорсткого кільця 3 має бути відхилене допуском (необокуглене −1,82483)', fg(2.0, 'ring3'),
          '−1,83', 100.0, negative=True, probe='−1,83', sec=['sec:m4b'])
    ck.eq('M-04', 'M4.B', 'Необокуглене значення жорсткого кільця 3, %, чотири знаки (−1,8248)', fg(2.0, 'ring3'), '−1,8248', 100.0, sec=['sec:m4b'])
    T17 = {'ring1': ('+4,430', '+1,311', '−3,652', '−1,110'), 'ring2': ('−3,628', '−0,371', '+3,035', '+0,306'),
           'ring3': ('+2,331', '−0,353', '−1,825', '+0,288'), 'rings12': ('+0,316', '+1,058', '−0,906', '−0,734'),
           'rings13': ('+6,747', '+0,984', '−5,478', '−0,806'), 'rings23': ('−1,675', '−0,767', '+0,980', '+0,574'),
           'all': ('+2,181', '+0,694', '−2,931', '−0,452')}
    pairs = []
    for m, (a, b, c_, d) in T17.items():
        pairs += [('м’які %s F_G' % m, fg(0.5, m), a, 100.0), ('м’які %s F_th' % m, fth(0.5, m), b, 1.0),
                  ('жорсткі %s F_G' % m, fg(2.0, m), c_, 100.0), ('жорсткі %s F_th' % m, fth(2.0, m), d, 1.0)]
    ck.many('M-05', 'M4.B', 'Табл. 17: F_G (%) і F_θ (град.) для семи комбінацій активних кілець, м’які і жорсткі (28 значень)', pairs, sec=['sec:m4b'])
    soft_sum = fg(0.5, 'ring1') + fg(0.5, 'ring2') + fg(0.5, 'ring3')
    ck.many('M-06', 'M4.B', 'Сума одиночних м’яких +4,43 − 3,63 + 2,33 = +3,13 %; повний ефект +2,18 %; взаємодії разом −0,95 %', [
        ('сума', soft_sum, '+3,13', 100.0), ('повний', fg(0.5, 'all'), '+2,18', 100.0), ('взаємодії', fg(0.5, 'all') - soft_sum, '−0,95', 100.0)], sec=['sec:m4b'])
    ratios = []
    for ct in (0.5, 2.0):
        f1 = abs(fth(ct, 'ring1'))
        ratios += [f1 / abs(fth(ct, 'ring2')), f1 / abs(fth(ct, 'ring3'))]
    r = ck.many('M-07', 'M4.B', 'Найближче кільце 1 впливає на локальний кут у 3,5-3,8 раза сильніше за кільця 2 і 3 (мін/макс відношень)', [
        ('мін', min(ratios), '3,5', 1.0), ('макс', max(ratios), '3,8', 1.0)], sec=['sec:m4b'])
    r['note'] = ('Первинне формулювання звіту «3,5–3,9» виправлено на «3,5–3,8» (найбільше відношення 1,11001/0,28832 = 3,84989; '
                 'найменше 3,5285); виправлення зроблено в `ch06.py` після першого прогону цього скрипта.')
    # interactions
    ints = []
    for ct in (0.5, 2.0):
        f1, f2, f3 = fg(ct, 'ring1'), fg(ct, 'ring2'), fg(ct, 'ring3')
        i12 = fg(ct, 'rings12') - f1 - f2
        i13 = fg(ct, 'rings13') - f1 - f3
        i23 = fg(ct, 'rings23') - f2 - f3
        i123 = fg(ct, 'all') - f1 - f2 - f3 - i12 - i13 - i23
        ints.append((i12, i13, i23, i123))
    pairs_all = [x for t in ints for x in t[:3]]
    ck.many('M-08', 'M4.B', 'Парні взаємодії F_G (у частках) лежать між −4,9·10⁻³ і −1,4·10⁻⁵', [
        ('найбільша за модулем', min(pairs_all), '\u22120,0049', 1.0), ('найменша за модулем', max(pairs_all), '\u22120,000014', 1.0)], sec=['sec:m4b'])
    r = ck.many('M-09', 'M4.B', 'Потрійна взаємодія F_G: звіт (підрозділ 6.1) — −7,3·10⁻⁴ (м’які) і +3,1·10⁻⁴ (жорсткі)', [
        ('потрійна, м’які', ints[0][3], '−7,3', 1e4), ('потрійна, жорсткі', ints[1][3], '3,1', 1e4)], sec=['sec:m4b'])
    r['note'] = ('Первинне формулювання звіту «близько ±5·10⁻⁴» було неточним (джерело G2_M4B_RESULTS.md, рядок 129: «±3–7·10⁻⁴»; перераховано −7,33·10⁻⁴ і +3,09·10⁻⁴); '
                 'виправлено в `ch06.py` на «−7,3·10⁻⁴ (м’які) і +3,1·10⁻⁴ (жорсткі)» після першого прогону цього скрипта.')
    m2 = ev.csv('M2')
    g2 = {(r['state'], r['case']): r for r in m2}
    pairs = []
    T13 = {'S0': ('−0,61', '+0,647', '−0,90', '−0,425'), 'S1': ('+0,62', '+0,743', '−1,81', '−0,493'), 'S2': ('+2,18', '+0,694', '−2,93', '−0,452')}
    for s, (a, b, c_, d) in T13.items():
        pairs += [('%s м’які G' % s, float(g2[(s, 'Msoft')]['R_EDI']) - 1, a, 100.0), ('%s м’які Δθ' % s, float(g2[(s, 'Msoft')]['dTheta_deg']), b, 1.0),
                  ('%s жорсткі G' % s, float(g2[(s, 'Mstiff')]['R_EDI']) - 1, c_, 100.0), ('%s жорсткі Δθ' % s, float(g2[(s, 'Mstiff')]['dTheta_deg']), d, 1.0)]
    ck.many('M-10', 'M2', 'Табл. 13: прямий ефект трьох однакових кілець на S0, S1, S2 (G/G_H − 1, %; Δθ, град.) за m2_results.csv', pairs, sec=['sec:first'])
    r1 = ev.csv('R1')
    cls = [r['class'] for r in r1]
    ck.flag('M-11', 'R1', 'R1_PLACEMENT_STABLE: усі рядки r1_crossfamily.csv (30) мають клас STABLE', (len(cls), sum(1 for c in cls if c == 'STABLE')), (30, 30), sec=['sec:m4b'])


def _check_x6(ev, ck, A):
    X = ev.j('X6')
    names = {'stiff13': 'stiff13', 'soft2': 'soft2', 'soft1': 'soft1'}
    resid, resid_own = [], []
    for c in ARCH:
        g = X[c]['G']
        for key in ('G', 'J', 'KI'):
            resid.append(abs(X[c][key]['identityResidual']))
        for key in ('MTS_deg',):
            resid.append(abs(X[c][key]['identityResidual']))
        qHH, qXH, qHX, qXX = g['qHH'], g['qXH'], g['qHX'], g['qXX']
        fm, fp = (qXH - qHH) / qHH, (qHX - qHH) / qHH
        fi = (qXX - qXH - qHX + qHH) / qHH
        ft = (qXX - qHH) / qHH
        resid_own.append(abs(ft - (fm + fp + fi)))
        resid_own.append(max(abs(fm - g['F_mat']), abs(fp - g['F_path']), abs(fi - g['F_int']), abs(ft - g['F_tot'])))
    ck.bound('X-01', 'M5-X6 (B9)', 'Тотожність F_G = F_m + F_p + F_i: збережені нев’язки (G, J, K_I, θ) ≤ 1,2·10⁻¹⁶', max(resid), 'le', 1.2e-16, '1,2·10⁻¹⁶',
             sec=['sec:x6def'])
    ck.bound('X-02', 'M5-X6 (B9)', 'Незалежне перерахування F_m, F_p, F_i, F_G з чотирьох значень G_AB: макс. розбіжність тотожності і зі збереженими (округлення, ≤ 10⁻¹⁵)',
             max(resid_own), 'le', 1e-15, '10⁻¹⁵', sec=['sec:x6def'])
    ck.many('X-03', 'M5-X6 (B9)', 'Табл. 25: F_G, F_m, F_p, F_i у S4, % (4 знаки) для трьох архітектур (12 значень)', [
        ('stiff13 F_G', X['stiff13']['G']['F_tot'], '−7,1736', 100.0), ('stiff13 F_m', X['stiff13']['G']['F_mat'], '−7,3684', 100.0),
        ('stiff13 F_p', X['stiff13']['G']['F_path'], '+0,2024', 100.0), ('stiff13 F_i', X['stiff13']['G']['F_int'], '−0,0077', 100.0),
        ('soft2 F_G', X['soft2']['G']['F_tot'], '−2,9317', 100.0), ('soft2 F_m', X['soft2']['G']['F_mat'], '−3,0320', 100.0),
        ('soft2 F_p', X['soft2']['G']['F_path'], '+0,0945', 100.0), ('soft2 F_i', X['soft2']['G']['F_int'], '+0,0058', 100.0),
        ('soft1 F_G', X['soft1']['G']['F_tot'], '+6,3294', 100.0), ('soft1 F_m', X['soft1']['G']['F_mat'], '+6,6912', 100.0),
        ('soft1 F_p', X['soft1']['G']['F_path'], '−0,3735', 100.0), ('soft1 F_i', X['soft1']['G']['F_int'], '+0,0117', 100.0)], sec=['sec:x6G'])
    sh = {c: abs(X[c]['G']['F_mat']) / abs(X[c]['G']['F_tot']) for c in ARCH}
    ck.many('X-04', 'M5-X6 (B9)', 'Частка |F_m|/|F_G|: 102,7 / 103,4 / 105,7 % (stiff13 / soft2 / soft1)', [
        ('stiff13', sh['stiff13'], '102,7', 100.0), ('soft2', sh['soft2'], '103,4', 100.0), ('soft1', sh['soft1'], '105,7', 100.0)], sec=['sec:x6G', 'sec:c_answer'])
    ck.many('X-05', 'M5-X6 (B9)', 'Траєкторний внесок протилежний матеріальному і становить 2,7 / 3,1 / 5,6 % його модуля; взаємодійний 0,1-0,2 % матеріального', [
        ('|F_p|/|F_m| stiff13', abs(X['stiff13']['G']['F_path']) / abs(X['stiff13']['G']['F_mat']), '2,7', 100.0),
        ('|F_p|/|F_m| soft2', abs(X['soft2']['G']['F_path']) / abs(X['soft2']['G']['F_mat']), '3,1', 100.0),
        ('|F_p|/|F_m| soft1', abs(X['soft1']['G']['F_path']) / abs(X['soft1']['G']['F_mat']), '5,6', 100.0),
        ('|F_i|/|F_m| мін', min(abs(X[c]['G']['F_int']) / abs(X[c]['G']['F_mat']) for c in ARCH), '0,1', 100.0),
        ('|F_i|/|F_m| макс', max(abs(X[c]['G']['F_int']) / abs(X[c]['G']['F_mat']) for c in ARCH), '0,2', 100.0)], sec=['sec:x6G'])
    ck.flag('X-06', 'M5-X6 (B9)', 'Знаки F_p і F_i (P3): stiff13 (+, −), soft2 (+, +), soft1 (−, +); P1, P2 виконано для всіх трьох',
            tuple((sgn(X[c]['G']['F_path']), sgn(X[c]['G']['F_int'])) for c in ARCH) + (all(X[c]['P1_pass'] and X[c]['P2_pass'] for c in ARCH),),
            (('+', '-'), ('+', '+'), ('-', '+'), True), sec=['sec:x6pred'])
    ck.many('X-07', 'M5-X6 (B9)', 'Табл. 24: чотири значення G_AB·10⁸ (Н/мм) у S4 на рівні B9', [
        ('G_HH', X['stiff13']['G']['qHH'], '1,539127', 1e8), ('stiff13 G_XH', X['stiff13']['G']['qXH'], '1,425719', 1e8), ('stiff13 G_HX', X['stiff13']['G']['qHX'], '1,542243', 1e8),
        ('stiff13 G_XX', X['stiff13']['G']['qXX'], '1,428716', 1e8), ('soft2 G_XH', X['soft2']['G']['qXH'], '1,492461', 1e8), ('soft2 G_HX', X['soft2']['G']['qHX'], '1,540581', 1e8),
        ('soft2 G_XX', X['soft2']['G']['qXX'], '1,494004', 1e8), ('soft1 G_XH', X['soft1']['G']['qXH'], '1,642112', 1e8), ('soft1 G_HX', X['soft1']['G']['qHX'], '1,533379', 1e8),
        ('soft1 G_XX', X['soft1']['G']['qXX'], '1,636545', 1e8)], sec=['sec:x6G'])
    # Table 26: Shapley, XX-base, multiplicative
    pairs = []
    T26 = {'stiff13': ('−7,3722', '−7,3760', '0,926316', '1,002024', '1,000078'), 'soft2': ('−3,0291', '−3,0262', '0,969680', '1,000945', '1,000089'),
           'soft1': ('+6,6970', '+6,7029', '1,066912', '0,996265', '1,000346')}
    for c, (sh_, xx_, rm, rp, ri) in T26.items():
        g = X[c]['G']
        pairs += [('%s Шеплі' % c, g['shapley_mat'], sh_, 100.0), ('%s база XX' % c, g['refXX_mat'], xx_, 100.0), ('%s R_m' % c, g['R_mat'], rm, 1.0),
                  ('%s R_p' % c, g['R_path'], rp, 1.0), ('%s R_i' % c, g['R_int'], ri, 1.0)]
    ck.many('X-08', 'M5-X6 (B9)', 'Табл. 26: матеріальний внесок за Шеплі, за базою XX і мультиплікативні множники', pairs, sec=['sec:x6ref'])
    M = {c: X[c]['MTS_deg'] for c in ARCH}
    ck.many('X-09', 'M5-X6 (B9)', 'Табл. 27: розклад Δθ у S4 (град.): повна, матеріал, траєкторія, взаємодія; відношення траєкторія/матеріал', [
        ('stiff13 повна', M['stiff13']['F_tot'], '+0,0778', 1.0), ('stiff13 мат.', M['stiff13']['F_mat'], '−0,7113', 1.0), ('stiff13 траєкт.', M['stiff13']['F_path'], '+0,8057', 1.0),
        ('stiff13 взаєм.', M['stiff13']['F_int'], '−0,0166', 1.0), ('stiff13 відн.', M['stiff13']['F_path'] / M['stiff13']['F_mat'], '−1,133', 1.0),
        ('soft2 повна', M['soft2']['F_tot'], '−0,0357', 1.0), ('soft2 мат.', M['soft2']['F_mat'], '−0,4714', 1.0), ('soft2 траєкт.', M['soft2']['F_path'], '+0,4387', 1.0),
        ('soft2 взаєм.', M['soft2']['F_int'], '−0,0030', 1.0), ('soft2 відн.', M['soft2']['F_path'] / M['soft2']['F_mat'], '−0,931', 1.0),
        ('soft1 повна', M['soft1']['F_tot'], '−0,0888', 1.0), ('soft1 мат.', M['soft1']['F_mat'], '+1,2379', 1.0), ('soft1 траєкт.', M['soft1']['F_path'], '−1,2959', 1.0),
        ('soft1 взаєм.', M['soft1']['F_int'], '−0,0308', 1.0), ('soft1 відн.', M['soft1']['F_path'] / M['soft1']['F_mat'], '−1,047', 1.0)], sec=['sec:x6angle'])
    rem = {c: abs(M[c]['F_tot']) / abs(M[c]['F_mat']) for c in ARCH}
    ck.many('X-10', 'M5-X6 (B9)', 'Залишок після компенсації кута: 7-11 % матеріального члена (мін/макс за трьома архітектурами)', [
        ('мін', min(rem.values()), '7', 100.0), ('макс', max(rem.values()), '11', 100.0)], sec=['sec:x6angle', 'sec:c_table'])
    ck.bound('X-11', 'M5-X6 (B9)', 'COD-EDI у десяти розв’язках: 2,514-2,518·10⁻³ (макс. ≤ 2,518·10⁻³)',
             max(abs(X[c]['informational'][k]) for c in ARCH for k in ('CODminusEDI_rel_XH', 'CODminusEDI_rel_HX')), 'le', 2.518e-3, '2,518·10⁻³', sec=['sec:x6why'])
    # base mixing: B9 reference vs A0 baseline
    W = A['states']
    ck.many('X-12', 'M5-X6 (B9) vs LP1/A0', 'Базові G_HH(S4): 1,539127 (B9, M5-X6) проти 1,538959 (базова сітка, LP1/A0); F_G(stiff13): −7,1736 % (B9) проти −7,1732 % (A0, табл. 15 дає −7,173)', [
        ('G_HH B9', X['stiff13']['G']['qHH'], '1,539127', 1e8), ('G_HH A0', W['H']['G'][4], '1,538959', 1e8),
        ('F_G B9', X['stiff13']['G']['F_tot'], '−7,1736', 100.0), ('F_G A0', A['stiff13']['F_G'][4], '−7,1732', 100.0)], sec=['sec:x6limits'])
    # exploratory sensitivity scale and the mesh drift
    ck.many('X-13', 'M5-X6 (B9)', 'Дослідницький масштаб чутливості сітки (R1, S2): U_m = 6,2·10⁻⁵ (знак F_i(soft2) = +5,80·10⁻⁵ нижче масштабу)', [
        ('F_i(soft2)', X['soft2']['G']['F_int'], '+5,80', 1e5)], sec=['sec:x6G'])
    # P4 recomputation
    G1 = ev.j('G1')
    sr = G1['firstOrderSingleRing']
    ar = G1['firstOrderArchitecture']
    stiff_band = [r['observedOverFirstOrder'] for r in sr if r['contrast'] == 2.0] + [r['observedOverFirstOrder'] for r in ar if r['architecture'] == 'stiff13' and r['state'] in (0, 2)]
    soft_band = [r['observedOverFirstOrder'] for r in sr if r['contrast'] == 0.5] + [r['observedOverFirstOrder'] for r in ar if r['architecture'] in ('soft2', 'soft1') and r['state'] in (0, 2)]
    fo4 = {r['architecture']: r['firstOrder_dUda'] for r in ar if r['state'] == 4}
    iv = {}
    for c in ARCH:
        band = stiff_band if c == 'stiff13' else soft_band
        lo, hi = sorted((fo4[c] * min(band), fo4[c] * max(band)))
        iv[c] = (lo, hi)
    ck.many('X-14', 'M5-X6 (B9) / G1', 'P4 (перераховано з G1_FIELD_EVIDENCE.json, смуга: жорстка для stiff13, м’яка для інших): інтервали [−7,11; −6,50], [−3,28; −2,99], [+5,67; +6,23] %', [
        ('stiff13 нижня', iv['stiff13'][0], '−7,11', 100.0), ('stiff13 верхня', iv['stiff13'][1], '−6,50', 100.0),
        ('soft2 нижня', iv['soft2'][0], '−3,28', 100.0), ('soft2 верхня', iv['soft2'][1], '−2,99', 100.0),
        ('soft1 нижня', iv['soft1'][0], '+5,67', 100.0), ('soft1 верхня', iv['soft1'][1], '+6,23', 100.0)], sec=['sec:x6pred'])
    inside = {c: iv[c][0] <= X[c]['G']['F_mat'] <= iv[c][1] for c in ARCH}
    ck.flag('X-15', 'M5-X6 (B9) / G1', 'P4: F_m всередині інтервалу? stiff13 — ні, soft2 — так, soft1 — ні', (inside['stiff13'], inside['soft2'], inside['soft1']), (False, True, False), sec=['sec:x6pred', 'sec:c_table'])


def _check_m5_g1(ev, ck, A):
    M5 = ev.j('M5')
    G1 = ev.j('G1')
    ik = M5['irwinKies']
    agree = 0
    tot = 0
    for c in ARCH:
        for a, b in zip(ik[c]['d_deltaC_da_sign'], ik[c]['F_G_fd_compliance_per_step']):
            tot += 1
            agree += (a == ('+' if b > 0 else '-'))
    ck.flag('K-01', 'M5', 'Ірвін-Кіс: знак dΔC/da збігається зі знаком F_G за податливістю на всіх чотирьох кроках S0→S4 для трьох архітектур (12 з 12)', (agree, tot), (12, 12), sec=['sec:m5'])
    ck.many('K-02', 'M5', 'Податливість: ΔC/C м’якого кільця 2: 0,41 % (S0) → 0,33 % (S4); stiff13: оцінка за податливістю −1,66 % проти EDI −4,21 % на першому кроці', [
        ('soft2 S0', ik['soft2']['deltaC_rel_S0toS4'][0], '0,41', 100.0), ('soft2 S4', ik['soft2']['deltaC_rel_S0toS4'][4], '0,33', 100.0),
        ('stiff13 fd', ik['stiff13']['F_G_fd_compliance_per_step'][0], '−1,66', 100.0), ('stiff13 EDI', ik['stiff13']['F_G_EDI_midstep_mean'][0], '−4,21', 100.0)], sec=['sec:m5'])
    gaps = [abs(ik[c]['F_G_fd_compliance_per_step'][k] - ik[c]['F_G_EDI_midstep_mean'][k]) * 100 for c in ARCH for k in (2, 3)]
    ck.many('K-03', 'M5', 'На двох останніх кроках оцінка за податливістю відрізняється від EDI на 0,03-0,5 п.п.', [('мін', min(gaps), '0,03', 1.0), ('макс', max(gaps), '0,5', 1.0)], sec=['sec:m5'])
    # G1 first-order estimate
    sr, ar = G1['firstOrderSingleRing'], G1['firstOrderArchitecture']
    allrows = sr + ar
    ck.flag('G-01', 'G1', 'Знак оцінки першого порядку збігається зі знаком спостереженого ефекту у всіх 21 порівнянні (12 одиночних кілець на двох сімействах + 9 архітектур)',
            (len(sr), len(ar), sum(1 for r in allrows if r['signAgrees'])), (12, 9, 21), sec=['sec:g1', 'sec:c_table'])
    soft_r = [r['observedOverFirstOrder'] for r in sr if r['contrast'] == 0.5] + [r['observedOverFirstOrder'] for r in ar if r['architecture'] in ('soft2', 'soft1')]
    stiff_r = [r['observedOverFirstOrder'] for r in sr if r['contrast'] == 2.0] + [r['observedOverFirstOrder'] for r in ar if r['architecture'] == 'stiff13']
    ck.many('G-02', 'G1', 'Відношення спостереженого до оцінки першого порядку: м’які 0,68-0,78, жорсткі 1,14-1,26', [
        ('м’які мін', min(soft_r), '0,68', 1.0), ('м’які макс', max(soft_r), '0,78', 1.0), ('жорсткі мін', min(stiff_r), '1,14', 1.0), ('жорсткі макс', max(stiff_r), '1,26', 1.0)],
        sec=['sec:g1', 'sec:c_table'])
    ck.many('G-03', 'G1', 'Параметр розвинення 1/λ − 1: +1 (м’яке, λ = 0,5) і −0,5 (жорстке, λ = 2); відхилення 14-32 % = ·(1 − відношення): мін/макс', [
        ('м’яке', 1 / 0.5 - 1, '+1', 1.0), ('жорстке', 1 / 2.0 - 1, '−0,5', 1.0),
        ('відхилення мін', min(abs(1 - r['observedOverFirstOrder']) for r in allrows), '14', 100.0),
        ('відхилення макс', max(abs(1 - r['observedOverFirstOrder']) for r in allrows), '32', 100.0)], sec=['sec:g1'])
    ck.many('G-04', 'G1', 'Нормування оцінки на ΔU/Δa проти G за EDI: +8,0 % (S0), +1,2 % (S2), −5,9 % (S4) (stiff13)', [
        ('S0', [r for r in ar if r['architecture'] == 'stiff13' and r['state'] == 0][0]['firstOrder_GEDI'] / [r for r in ar if r['architecture'] == 'stiff13' and r['state'] == 0][0]['firstOrder_dUda'] - 1, '+8,0', 100.0),
        ('S2', [r for r in ar if r['architecture'] == 'stiff13' and r['state'] == 2][0]['firstOrder_GEDI'] / [r for r in ar if r['architecture'] == 'stiff13' and r['state'] == 2][0]['firstOrder_dUda'] - 1, '+1,2', 100.0),
        ('S4', [r for r in ar if r['architecture'] == 'stiff13' and r['state'] == 4][0]['firstOrder_GEDI'] / [r for r in ar if r['architecture'] == 'stiff13' and r['state'] == 4][0]['firstOrder_dUda'] - 1, '−5,9', 100.0)], sec=['sec:g1'])
    # Table 19: stress states of the rings (homogeneous plate, S2)
    env = {r['ring']: r for r in G1['ringEnvironment']['M4B'] if r['region'].startswith('ring')}
    T19 = {1: ('−32,2', '+4,238', '−1,592', '21,1', '12'), 2: ('+5,8', '+1,919', '−3,806', '5,1', '75'), 3: ('+43,8', '+0,498', '−5,722', '27,1', '96')}
    pairs = []
    for rg, (dist, s1, s2, ang, frac) in T19.items():
        e = env[rg]
        pairs += [('кільце %d відстань' % rg, e['signedDistanceToLine_mm'], dist, 1.0), ('кільце %d σ_1' % rg, e['avgTensor_s1'], s1, 1e4), ('кільце %d σ_2' % rg, e['avgTensor_s2'], s2, 1e4),
                  ('кільце %d кут' % rg, e['compressiveAxisAngleToLine_deg'], ang, 1.0), ('кільце %d частка стиску' % rg, e['fracCompressionDominated'], frac, 100.0)]
    ck.many('G-05', 'G1', 'Табл. 19: усереднений напружений стан у кільцях однорідної пластини (S2): відстань, σ_1, σ_2, кут осі стиску, частка переважного стиску', pairs, sec=['sec:g1'])
    ck.flag('G-06', 'G1', 'Кільце 2: головні напруження різних знаків (σ_1 > 0 > σ_2), отже стан змішаний, а не «стиснутий в обох напрямках» (виправлення К-21)',
            (env[2]['avgTensor_s1'] > 0 > env[2]['avgTensor_s2'], env[1]['avgTensor_s1'] > 0 > env[1]['avgTensor_s2'], env[3]['avgTensor_s1'] > 0 > env[3]['avgTensor_s2']), (True, True, True),
            sec=['sec:g1'])
    cor = [r for r in G1['corridor']['M4B'] if r['offset_mm'] == 0][0]
    ck.many('G-07', 'G1', 'Смуга ±10 мм уздовж лінії «шарнір-сила»: медіанний кут 11,4°, у 61 % площі кут < 15°', [
        ('медіана', cor['medianAngle_deg'], '11,4', 1.0), ('частка < 15°', cor['fracWithin15deg'], '61', 100.0)], sec=['sec:g1'])
    ck.flag('G-08', 'G1', 'G1: обчислень МСЕ не виконано (boundaryValueProblemsSolved = 0)', G1['boundaryValueProblemsSolved'], 0, sec=['sec:g1'])


def _check_lp2a2(ev, ck):
    R = ev.j('A2_RECON')
    acc = R['accounting']
    ck.flag('P-01', 'LP2-A2', 'Склад набору: 127 унікальних геометрій = 117 + 10 рядків-обмежувачів; успадкований генератор: 57 пройшло, 60 HOLD (двічі однаково)',
            (acc['uniqueTestGeometries']['total'], acc['uniqueTestGeometries']['nonGuard'], acc['uniqueTestGeometries']['guardRows'], acc['originalMesher']['finalPass'], acc['originalMesher']['finalHOLD'],
             acc['originalMesher']['identicalOutcomesBetweenRuns']), (127, 117, 10, 57, 60, True), sec=['sec:pr_qual'])
    a1_, a2_ = acc['newAttempt1'], acc['newAttempt2']
    ck.flag('P-02', 'LP2-A2', 'Табл. 48: спроба 1 (108 з’єднано, 108 аудит парування, 107 повний, 10 HOLD); спроба 2 (113, 113, 112, 5 HOLD, 135 спроб щаблів)',
            (a1_['joined'], a1_['pairingPass'], a1_['fullAuditPass'], a1_['finalHOLD'], a2_['joined'], a2_['pairingPass'], a2_['fullAuditPass'], a2_['finalHOLD'], a2_['ladderRungAttempts']),
            (108, 108, 107, 10, 113, 113, 112, 5, 135), sec=['sec:pr_qual', 'sec:pr_levels'])
    pa = R['pairedAllNonGuard']
    pc = R['pairedC1']
    ck.flag('P-03', 'LP2-A2', 'Табл. 49: усі 117 геометрій (спроба 1: 55/2/52/8; спроба 2: 57/0/55/5); лише C1 (спроба 1: 36/0/41/5; спроба 2: 36/0/44/2)',
            tuple(pa['attempt1'][k] for k in ('oldPass_newPass', 'oldPass_newFail', 'oldFail_newPass', 'oldFail_newFail')) +
            tuple(pa['attempt2'][k] for k in ('oldPass_newPass', 'oldPass_newFail', 'oldFail_newPass', 'oldFail_newFail')) +
            tuple(pc['attempt1'][k] for k in ('oldPass_newPass', 'oldPass_newFail', 'oldFail_newPass', 'oldFail_newFail')) +
            tuple(pc['attempt2'][k] for k in ('oldPass_newPass', 'oldPass_newFail', 'oldFail_newPass', 'oldFail_newFail')),
            (55, 2, 52, 8, 57, 0, 55, 5, 36, 0, 41, 5, 36, 0, 44, 2), sec=['sec:pr_qual'])
    fp = R['forcedPairs']
    ck.many('P-04', 'LP2-A2', 'Табл. 43: вимушена пара на колі 15-мм напрямної, 113 сіток: max|Δs| = 2,282 мкм; |Δx| = 1,948 мкм; частина параметризації 0,768 мкм; залишок формули 1,7·10⁻⁹ мм; мін. кут 21,79°; мін. площа 0,0497 мм²', [
        ('max |Δs|, мкм', fp['maxStationMismatch_mm'], '2,282', 1e3), ('max |Δx|, мкм', fp['maxCircleDx_mm'], '1,948', 1e3),
        ('параметризація, мкм', fp['maxParametrisationPart_mm'], '0,768', 1e3), ('залишок формули (·10⁻⁹ мм)', fp['maxAbsPredictedMinusAbsCircleDx_mm'], '1,7', 1e9),
        ('мін. кут', fp['minIncidentMinAngle_deg'], '21,79', 1.0), ('мін. площа', fp['minIncidentArea_mm2'], '0,0497', 1.0)], sec=['sec:pr_forced'])
    ck.flag('P-05', 'LP2-A2', '113 з 113 вимушених пар: різні ідентифікатори, однаковий індекс берега, всередині відрізка, залишок після згортання 0',
            (fp['meshes'], fp['pairs'], fp['allPass'], fp['allDistinctIDs'], fp['allSameBankIndex'], fp['allInteriorOfSegment'], fp['maxResidualAfterCollapse_mm']), (113, 113, True, True, True, True, 0), sec=['sec:pr_forced'])
    supp = ev.j('A2_SUPP')
    nontriv = 0
    sgn_opp = 0
    for r in supp['rows']:
        fpair = r.get('forcedPairs') or {}
        pr = fpair.get('pairs')
        if isinstance(pr, dict):
            pr = [pr]
        for q in (pr or []):
            if abs(q['circleDx_mm']) > 1e-9:
                nontriv += 1
                if q['predictedDx_mm'] * q['circleDx_mm'] < 0:
                    sgn_opp += 1
    ck.flag('P-06', 'LP2-A2', 'LP2A2_SUPPLEMENT.json: у всіх вимушених парах з |circleDx| > 10⁻⁹ мм (58 з 113; решта 55 — прямі ділянки з b ≈ 0, значення на рівні округлення 10⁻¹⁵) predictedDx_mm має знак, протилежний circleDx_mm (потрібна примітка-erratum за рецензією)',
            (nontriv, sgn_opp), (58, 58), sec=['sec:pr_forced'])
    # Table 30: legacy generator on the LP2 scan (82 synthetic polylines)
    scan = ev.j('MESH_SCAN')['rows']
    bystate = {}
    for r in scan:
        bystate.setdefault(r['state'], [0, 0])
        bystate[r['state']][1] += 1
        bystate[r['state']][0] += 1 if r['pass'] else 0
    exp = {6: (8, 8), 7: (8, 8), 8: (8, 8), 9: (5, 8), 10: (4, 8), 11: (2, 8), 12: (0, 5), 13: (1, 4), 14: (0, 4), 15: (0, 4), 16: (0, 4), 17: (0, 4), 18: (0, 4), 19: (0, 4), 20: (0, 1)}
    ck.flag('P-07', 'LP2-A2', 'Табл. 30: успадкований генератор на 82 синтетичних ламаних S6..S20: пройшло / усього за станами (8/8, 8/8, 8/8, 5/8, 4/8, 2/8, 0/5, 1/4, 0/4 … 0/1)',
            tuple((s, tuple(bystate[s])) for s in sorted(bystate)), tuple((s, exp[s]) for s in sorted(exp)), sec=['sec:p_limit'])
    # Table 54: restricted-regime counts from attempt-2 rows
    att = ev.j('A2_ATT2')['rows']
    sel = [r for r in att if not r.get('guardRow')]
    cnt = lambda pred: [r for r in sel if pred(r)]
    clr = lambda r: min(r['tipToRingCircle_mm']) - R_GUIDE
    s611 = cnt(lambda r: 6 <= r['state'] <= 11 and clr(r) >= 1.0)
    s911 = [r for r in s611 if r['state'] >= 9]
    s68 = [r for r in s611 if r['state'] <= 8]
    anyst = cnt(lambda r: clr(r) >= 1.0)
    passn = lambda L: sum(1 for r in L if r['new']['pass'])
    oldn = lambda L: sum(1 for r in L if r.get('old', {}).get('pass'))
    rung = lambda L: tuple(sum(1 for r in L if r['new'].get('seedRung') == k) for k in (1, 2, 3))
    ck.flag('P-08', 'LP2-A2', 'Табл. 54: геометрії обмеженого режиму (зазор напрямна-коло ≥ 1,0 мм): S6-S11 76 (76 пройшло, щаблі 74/2/0), у т.ч. S9-S11 48 (щаблі 46/2/0) і S6-S8 28; будь-який стан 109 (щаблі 104/4/1)',
            (len(s611), passn(s611), rung(s611), len(s911), passn(s911), rung(s911), len(s68), passn(s68), len(anyst), passn(anyst), rung(anyst)),
            (76, 76, (74, 2, 0), 48, 48, (46, 2, 0), 28, 28, 109, 109, (104, 4, 1)), sec=['sec:pr_regime'])

    # failure statistics of the legacy generator (Table 41) and group counts (Table 47)
    of = R['originalCrackFaceFailures']
    ck.flag('P-09', 'LP2-A2', 'Табл. 41: 59 відмов HOLD_LIP_STATIONS у групах A 0, B 1, C1 46, C2 9, C3 3 (+1 відмова мінімального кута: C2_soft1_frozen_S12) = 60',
            (of['total'], tuple(of['byGroup'][g] for g in ('A', 'B', 'C1', 'C2', 'C3')), tuple(x[0] for x in of['otherOriginalFailures'])),
            (59, (0, 1, 46, 9, 3), ('C2_soft1_frozen_S12',)), sec=['sec:pr_problem'])
    gs = ev.j('A2_SUM2')['groups']
    ck.flag('P-10', 'LP2-A2', 'Табл. 47: рядків без обмежувачів A 4, B 4, C1 82, C2 21, C3 6 (=117); старий пройшов 4/3/36/11/3 (=57); новий (спроба 2) 4/4/80/18/6 (=112)',
            (tuple(gs[g]['rows'] - gs[g]['guard'] for g in ('A', 'B', 'C1', 'C2', 'C3')), tuple(gs[g]['oldPass'] for g in ('A', 'B', 'C1', 'C2', 'C3')),
             tuple(gs[g]['newPass'] for g in ('A', 'B', 'C1', 'C2', 'C3'))), ((4, 4, 82, 21, 6), (4, 3, 36, 11, 3), (4, 4, 80, 18, 6)), sec=['sec:pr_qual'])
    # Table 50 (per state, legacy and new attempt 2) and Table 51 (mesh metrics of the 113 joined meshes)
    sel2 = [r for r in ev.j('A2_ATT2')['rows'] if not r.get('guardRow')]
    per = {}
    for r in sel2:
        t = per.setdefault(r['state'], [0, 0, 0])
        t[0] += 1
        t[1] += 1 if r.get('old', {}).get('pass') else 0
        t[2] += 1 if r['new']['pass'] else 0
    exp50 = {6: (8, 8, 8), 7: (8, 8, 8), 8: (12, 12, 12), 9: (12, 8, 12), 10: (18, 12, 18), 11: (18, 5, 18), 12: (12, 3, 8), 13: (4, 1, 4), 14: (4, 0, 4), 15: (4, 0, 4),
             16: (4, 0, 4), 17: (4, 0, 4), 18: (4, 0, 4), 19: (4, 0, 4), 20: (1, 0, 0)}
    ck.flag('P-11', 'LP2-A2', 'Табл. 50: геометрій / старий пройшов / новий (спроба 2) пройшов за станами S6..S20 (117 геометрій; сума 117 / 57 / 112)',
            tuple((k, tuple(per[k])) for k in sorted(per)), tuple((k, exp50[k]) for k in sorted(exp50)), sec=['sec:pr_qual'])
    joined = [r['new'] for r in sel2 if r['new'].get('T3')]
    ck.many('P-12', 'LP2-A2', 'Табл. 51: показники 113 з’єднаних сіток спроби 2: T3 29 579-32 591; вузлів T6 60 149-66 425; мін. кут 21,36-30,13°; відношення ребер 1,592-1,790', [
        ('T3 мін', min(m['T3'] for m in joined), '29579', 1.0), ('T3 макс', max(m['T3'] for m in joined), '32591', 1.0),
        ('T6 мін', min(m['T6nodes'] for m in joined), '60149', 1.0), ('T6 макс', max(m['T6nodes'] for m in joined), '66425', 1.0),
        ('кут мін', min(m['minAngle_deg'] for m in joined), '21,36', 1.0), ('кут макс', max(m['minAngle_deg'] for m in joined), '30,13', 1.0),
        ('відношення мін', min(m['maxNeighborRatio'] for m in joined), '1,592', 1.0), ('відношення макс', max(m['maxNeighborRatio'] for m in joined), '1,790', 1.0)], sec=['sec:pr_qual'])
    ck.flag('P-13', 'LP2-A2', 'Кількість з’єднаних сіток у таблиці 51 дорівнює 113', len(joined), 113, sec=['sec:pr_qual'])



# ------------------------------------------------------------------------------------------ remaining failures (extra check)
def _check_lp2a2_failures(ev, ck):
    R = ev.j('A2_RECON')
    rf = {x['id']: x for x in R['remainingFailures']}
    exp = {'C1_soft1_frozenMTS_S12': '0,1289', 'C1_soft1_straight_S20': '0,4923', 'C2_stiff13_straight_S12': '0,2386',
           'C2_soft2_straight_S12': '0,0750', 'C2_soft1_frozen_S12': '0,2367'}
    pairs = []
    for k, st in exp.items():
        v = rf[k].get('tipGuideClearanceToRing_mm') if k in rf else float('nan')
        pairs.append((k, v if v is not None else float('nan'), st, 1.0))
    ck.many('P-14', 'LP2-A2', 'Табл. 52: п’ять геометрій без побудованої сітки і зазор напрямна-коло кільця, мм (0,0750-0,4923)', pairs, sec=['sec:pr_resid'])


# ------------------------------------------------------------------------------------------ numbering helpers
SEC_TITLE = {
    'sec:problem': 'Наукова проблема, мета і гіпотези дослідження', 'sec:stage0': 'Вихідне питання і нульовий етап: аналіз наукових прогалин',
    'sec:four': 'Чотири поняття, які не можна ототожнювати', 'sec:pivot': 'Зміна об’єкта дослідження: від отворів до зв’язаних кілець',
    'sec:hyp': 'Мета і гіпотези', 'sec:model': 'Постановка модельної задачі', 'sec:cornell': 'Еталонний експеримент Корнелла',
    'sec:ideal': 'Чим ідеалізована задача відрізняється від експерименту', 'sec:configs': 'Досліджувані матеріальні конфігурації',
    'sec:method': 'Чисельна методика визначення траєкторії тріщини', 'sec:bvp': 'Крайова задача і визначальні співвідношення',
    'sec:fem': 'Скінченноелементна дискретизація', 'sec:mesh': 'Сітка з тріщиною: канал-розріз, його згортання і захищене ядро',
    'sec:frame': 'Локальний базис і асимптотичні поля', 'sec:edi': 'Областевий інтеграл взаємодії (EDI)',
    'sec:cod': 'Незалежна «сліпа» оцінка за розкриттям берегів (COD)', 'sec:gates': 'Критерії прийняття розв’язку',
    'sec:mts': 'Критерій напрямку і рекурентна побудова траєкторії', 'sec:derived': 'Похідні величини, що використовуються в аналізі',
    'sec:verif': 'Верифікація і чисельна достовірність', 'sec:v_mesh': 'Від геометрії зразка до сітки, придатної для механіки руйнування',
    'sec:v_sif': 'Перевірка визначення знакових КІН', 'sec:v_kink': 'Перший злам, сітки зі зламами і перезапуск',
    'sec:v_lp1': 'Кампанії LP0 і LP1: траєкторії S0–S4 і питання про дозвіл', 'sec:v_a1': 'Чутливість до подрібнення сітки біля вершини (A1)',
    'sec:v_soft2': 'Оцінки невизначеності і статус конфігурації soft2', 'sec:v_sum': 'Підсумок розділу',
    'sec:arch': 'Вплив матеріальної архітектури на рушійну силу руйнування', 'sec:first': 'Перші результати: три однакові кільця',
    'sec:choice': 'Вибір чотирьох основних конфігурацій', 'sec:fgdef': 'Контраст на власних траєкторіях і умова однакової довжини тріщини',
    'sec:evol': 'Еволюція екранування і підсилення від S0 до S8', 'sec:abs': 'Відносний контраст і абсолютна рушійна сила',
    'sec:mech': 'Механічні причини екранування та підсилення', 'sec:m4b': 'Внески окремих кілець на замороженій тріщині (M4.B)',
    'sec:m5': 'Що було відомо про прямий і траєкторний ефекти до схрещених розрахунків (M5)',
    'sec:g1': 'Польове дослідження G1: напруження, енергія та їх зв’язок з ефектом кілець', 'sec:mechsum': 'Підсумок: що підтверджено безпосередньо і що є тлумаченням',
    'sec:x6': 'Розділення матеріального та геометричного внесків', 'sec:x6why': 'Навіщо потрібне схрещене порівняння',
    'sec:x6def': 'Схема розрахунку і означення внесків', 'sec:x6G': 'Розклад енергетичного ефекту', 'sec:x6ref': 'Залежність розкладу від бази порівняння',
    'sec:x6angle': 'Порівняння з розкладом локального кута поширення', 'sec:x6pred': 'Попередньо зафіксовані передбачення та їх перевірка',
    'sec:x6limits': 'Межі застосовності результату', 'sec:paths': 'Еволюція траєкторій тріщини в матриці: стани S0–S8',
    'sec:p_question': 'Питання, яке ставить розділ', 'sec:p_design': 'Постановка кампанії LP2-A1', 'sec:p_limit': 'Чому кампанія зупинена на S8: сітка, а не напрямна область',
    'sec:p_exec': 'Виконання кампанії і контроль якості', 'sec:p_paths': 'Траєкторії: повний вигляд і збільшене порівняння',
    'sec:p_K': 'Знакові КІН, змішаність мод і швидкість вивільнення енергії', 'sec:p_dir': 'Напрямок: локальні прирости кута, відносний курс і бічне зміщення',
    'sec:p_split': 'Енергетичний і геометричний ефекти: спостереження, а не механізм', 'sec:p_dist': 'Відстані до кілець, отворів і країв; завершальні класи',
    'sec:p_hres': 'Перевірка наперед зафіксованих гіпотез', 'sec:p_sum': 'Що встановлено і чого не встановлено',
    'sec:pairing': 'Детерміноване парування вузлів берегів тріщини (LP2-A2)', 'sec:pr_problem': 'Задача: чому береги тріщини потребують парування',
    'sec:pr_method': 'Спільне параметричне засівання берегів', 'sec:pr_forced': 'Вимушена пара на колі напрямної', 'sec:pr_audit_sec': 'Драбина кроків засівання і аудити кожного стану',
    'sec:pr_qual': 'Кваліфікація на наперед оголошеному наборі', 'sec:pr_resid': 'Залишкові відмови: п’ять геометрій, які не побудовано',
    'sec:pr_levels': 'Що саме доведено: п’ять рівнів доказовості', 'sec:pr_regime': 'Обмежений режим застосування',
    'sec:pr_eq': 'Підготовлена, але не виконана перевірка еквівалентності КІН', 'sec:pr_sum': 'Що встановлено і чого не встановлено',
    'sec:concl': 'Наукові висновки та межі їх застосовності', 'sec:c_answer': 'Відповіді на поставлені питання', 'sec:c_table': 'Зведення за категоріями доказовості',
    'sec:c_not': 'Що не доведено', 'sec:c_nov': 'Потенційна новизна', 'sec:c_words': 'Допустимі та недопустимі формулювання',
    'sec:future': 'Подальші напрями дослідження', 'sec:f_status': 'Статус пунктів і порядок', 'sec:f_eq': 'Найближчий етап: еквівалентність КІН і обмежене продовження',
    'sec:f_refine': 'Зближення областей згущення з кільцями', 'sec:f_objects': 'Три об’єкти з різним статусом', 'sec:f_sif': 'Визначення КІН поблизу межі та ріст у матриці',
    'sec:f_interface': 'Взаємодія з міжфазною межею і фізична зупинка', 'sec:f_aux': 'Допоміжні дослідження', 'sec:f_limits': 'Чого розділ не означає',
}

# fallback snapshot of the numbering of the build of 25.11.2026 19:08 (used when no numbering map is given)
NUMBERING_SNAPSHOT = {
    'sec:problem': '1', 'sec:stage0': '1.1', 'sec:four': '1.2', 'sec:pivot': '1.3', 'sec:hyp': '1.4', 'sec:model': '2', 'sec:cornell': '2.1', 'sec:ideal': '2.2', 'sec:configs': '2.3',
    'sec:method': '3', 'sec:bvp': '3.1', 'sec:fem': '3.2', 'sec:mesh': '3.3', 'sec:frame': '3.4', 'sec:edi': '3.5', 'sec:cod': '3.6', 'sec:gates': '3.7', 'sec:mts': '3.8', 'sec:derived': '3.9',
    'sec:verif': '4', 'sec:v_mesh': '4.1', 'sec:v_sif': '4.2', 'sec:v_kink': '4.3', 'sec:v_lp1': '4.4', 'sec:v_a1': '4.5', 'sec:v_soft2': '4.6', 'sec:v_sum': '4.7',
    'sec:arch': '5', 'sec:first': '5.1', 'sec:choice': '5.2', 'sec:fgdef': '5.3', 'sec:evol': '5.4', 'sec:abs': '5.5', 'sec:mech': '6', 'sec:m4b': '6.1', 'sec:m5': '6.2', 'sec:g1': '6.3',
    'sec:mechsum': '6.4', 'sec:x6': '7', 'sec:x6why': '7.1', 'sec:x6def': '7.2', 'sec:x6G': '7.3', 'sec:x6ref': '7.4', 'sec:x6angle': '7.5', 'sec:x6pred': '7.6', 'sec:x6limits': '7.7',
    'sec:paths': '8', 'sec:p_question': '8.1', 'sec:p_design': '8.2', 'sec:p_limit': '8.3', 'sec:p_exec': '8.4', 'sec:p_paths': '8.5', 'sec:p_K': '8.6', 'sec:p_dir': '8.7', 'sec:p_split': '8.8',
    'sec:p_dist': '8.9', 'sec:p_hres': '8.10', 'sec:p_sum': '8.11', 'sec:pairing': '9', 'sec:pr_problem': '9.1', 'sec:pr_method': '9.2', 'sec:pr_forced': '9.3', 'sec:pr_audit_sec': '9.4',
    'sec:pr_qual': '9.5', 'sec:pr_resid': '9.6', 'sec:pr_levels': '9.7', 'sec:pr_regime': '9.8', 'sec:pr_eq': '9.9', 'sec:pr_sum': '9.10', 'sec:concl': '10', 'sec:c_answer': '10.1',
    'sec:c_table': '10.2', 'sec:c_not': '10.3', 'sec:c_nov': '10.4', 'sec:c_words': '10.5', 'sec:future': '11', 'sec:f_status': '11.1', 'sec:f_eq': '11.2', 'sec:f_refine': '11.3',
    'sec:f_objects': '11.4', 'sec:f_sif': '11.5', 'sec:f_interface': '11.6', 'sec:f_aux': '11.7', 'sec:f_limits': '11.8',
    'fig:geom': '1', 'fig:configs': '2', 'fig:tipzones': '3', 'fig:a1mesh': '4', 'fig:a1fg': '5', 'fig:GFG': '6', 'fig:m4bbars': '7', 'fig:g1dirs': '8', 'fig:g1energy': '9', 'fig:g1map': '10',
    'fig:x6bars': '11', 'fig:p_traj': '12', 'fig:p_kk': '13', 'fig:p_dir': '14', 'fig:pr_f1': '15', 'fig:pr_f2': '16', 'fig:pr_f3': '17', 'fig:pr_f7': '18', 'fig:pr_f8': '19',
    'tab:FG': '15', 'tab:Gabs': '16', 'tab:m4b': '17', 'tab:m2': '13', 'tab:g1rings': '19', 'tab:g1fo': '20', 'tab:x6dec': '25', 'tab:x6ref': '26', 'tab:x6ang': '27', 'tab:x6P': '28',
    'tab:p_state': '34', 'tab:p_head': '35', 'tab:p_dev': '36', 'tab:p_dist': '38', 'tab:p_s8': '39', 'tab:p_scan': '30', 'tab:pr_diag': '41', 'tab:pr_groups': '47', 'tab:pr_pop': '48',
    'tab:pr_state': '50', 'tab:pr_regime': '54', 'tab:c_sum': '57', 'tab:c_words': '58', 'tab:f_map': '59', 'tab:a_chron': '63', 'tab:a_k14': '77', 'tab:a_k21': '84', 'tab:a_k22': '85',
    'tab:a1res': '11', 'tab:a1fg': '12', 'tab:choice': '14', 'tab:g1verdict': '21', 'tab:pr_forced': '43', 'tab:pr_resid': '52', 'tab:pr_levels': '53',
}


class Num:
    def __init__(self, path, toc=None):
        self.toc = toc or {}
        self.n = dict(NUMBERING_SNAPSHOT)
        self.src = 'вбудований знімок нумерації збірки 25.11.2026 19:08'
        if path and os.path.exists(path):
            with open(path, encoding='utf-8') as f:
                self.n.update(json.load(f)['numbers'])
            self.src = os.path.basename(path)

    def sec(self, k):
        n = self.n.get(k, '?')
        return 'розд. %s «%s»' % (n, self.toc.get(n) or SEC_TITLE.get(k, k))

    def secn(self, k):
        return self.n.get(k, '?')

    def tab(self, k):
        return 'табл. %s' % self.n.get(k, '?')

    def fig(self, k):
        return 'рис. %s' % self.n.get(k, '?')


def esc(s):
    t = str(s).replace('\n', '<br>').replace('<br>', '\x00')
    t = t.replace('<', '&lt;').replace('>', '&gt;').replace('|', '\\|')
    return t.replace('\x00', '<br>')


CAT = {
    '1': 'встановлено прийнятими фізичними (МСЕ) розрахунками або точною тотожністю',
    '2': 'числова тенденція із залишковою невизначеністю дискретизації',
    '3': 'механістичне тлумачення, підтримане частково',
    '4': 'відкрита гіпотеза або відсутність доказу',
}

FAMILIES = [
    ('LP1/A0', 'траєкторії S0–S4 чотирьох конфігурацій на базовому сімействі сіток (перше ребро біля вершини 0,0417 мм); обчислено в LP1, побітово відтворено в A0'),
    ('LP2-A1', 'стани S5–S8 тих самих траєкторій на тому самому сімействі сіток (16 нових розв’язків)'),
    ('A1 (B9)', 'родина B: 12 розв’язків на фіксованій геометрії S4 з подрібненням першого ребра від 0,0417 до 0,0099 мм (m = 0, 3, 6, 9); рівень B9 — найдрібніший'),
    ('M5-X6 (B9)', 'схрещені розв’язки «матеріал X на траєкторії H» і «матеріал H на траєкторії X» у стані S4 на рівні B9 (6 розв’язків) разом з 4 розв’язками родини B9 для H і трьох X'),
    ('M4.B / R1 / M2', 'заморожена тріщина S2 однорідної пластини (M4.B, незалежна сітка R1) і заморожені положення S0–S2 (M2)'),
    ('LP2-A2', 'лише геометрія: побудова й аудит сіток у пам’яті, жодного розв’язку МСЕ'),
]

# claim records: id, sec keys (main first), tab/fig keys, claim, sources, accepted, numbers, family, category, limits, manual verification, check ids
CLAIMS = [
    dict(id='CL-01', sec=['sec:pivot', 'sec:stage0'], tabs=['tab:gaps'],
         claim='Досліджено G2 як контрольоване порівняння фаз для зв’язаних кілець (матеріальна, траєкторна і повна дії), а не порівняння «з отворами — без отворів» нульового етапу; фази V1/V2 завдання № 9 не виконувалися.',
         src=['docs/research/crack-growth-gaps-2026/G2_FOCUSED_AUDIT_AND_TEST_PROTOCOL.md, рядки 59–71', 'matlab/g2/G2_MATERIAL_CONTRAST_PREREGISTRATION.md, рядки 17–18', 'тіло завдання № 9, рядки 28–30', 'досьє A, Q1'],
         acc='запит № 8 (голова ba754bd): «широку новизну відхилено», G2 лишено як перевірне дослідження; вибір кілець — завдання № 33–35 (к. 6993841735)',
         num='немає (документальний запис)', fam='—', cat='1',
         lim='Запису про виконання фаз V1/V2 завдання № 9 (порожні отвори H0, H1±, H2a–c) не знайдено. За картою можливостей нульового етапу зв’язані включення — клас B, не A.',
         ver='не перевірялося незалежно; документальний факт (запит Q-01)', chk=[]),
    dict(id='CL-02', sec=['sec:pivot', 'sec:c_nov'],
         claim='Якісні твердження «жорстке включення екранує, м’яке підсилює» новими не є; потенційно новим може бути лише кількісне розділення матеріального й траєкторного внесків на незалежно обчислених траєкторіях у стані S4 і спостережена розбіжність між енергетичним і кутовим ефектами.',
         src=['docs/research/crack-growth-gaps-2026/GAP_ANALYSIS.md (41 запис, 30 — за анотаціями)', 'docs/research/G2_M5_MECHANISM_ATTRIBUTION_MEMO_UA.md, рядок 133 (правило без посилання)', 'досьє A, Q2'],
         acc='оцінка новизни стримана в запиті № 8; ревізії LP2-A1/A2 новизни не оцінювали',
         num='—', fam='M5-X6 (B9)', cat='4',
         lim='Цільового огляду літератури про тріщину поблизу пружних включень і покритих отворів у репозиторії немає; твердження про новизну — лише гіпотеза.',
         ver='не перевірялося незалежно (запит Q-02)', chk=[]),
    dict(id='CL-03', sec=['sec:cornell', 'sec:ideal'], tabs=['tab:geom', 'tab:diff'], figs=['fig:geom'],
         claim='Модельна задача є номінальною ідеалізацією зразка № 1 Корнелла (a = 1 дюйм, d = 6 дюймів) з вибраними, а не виміряними сталими E = 3268,115 МПа, ν = 0,35; порівняння розрахованої траєкторії з експериментальною не виконувалося, тому валідації немає.',
         src=['docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json', 'docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_SOURCE_AUDIT.md, рядок 55', 'matlab/g2/WP2_PREREGISTRATION.md, рядки 19, 21', 'досьє A, Q3, Q9'],
         acc='запити № 10–12 (к. 6901260202, 6909534071, 6909787345); WP0/WP1: к. 6982633594',
         num='E = 3268,115 МПа (1990, зразки без отворів); ν = 0,35 (чисельна модель 2015); пластина 508 × 203,2 × 12,7 мм', fam='—', cat='4',
         lim='Координати експериментальної траєкторії, сила, E і ν зразка № 1, контакт опор і ножа невідомі; оригінальні скани не перевірялися; звіт Корнелла 1990 р. доступний лише як розпізнаний текст.',
         ver='не перевірялося незалежно; обмеження підтверджено рецензією 6013194158 (запит Q-03)', chk=[]),
    dict(id='CL-04', sec=['sec:mts', 'sec:derived', 'sec:edi'], tabs=['tab:FG'],
         claim='Збережені величини внутрішньо узгоджені: G = (K_I² + K_II²)/E для 36 станів S0–S8; курс φ_{n+1} = φ_n + θ_n (φ_0 = 90°); Δφ_{n+1} = Δφ_n + Δθ_n; бічне зміщення d відтворюється проєкцією різниці вершин на ліву нормаль траєкторії H.',
         src=['docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: states.‹конфігурація›.{KI,KII,G,MTS,head,tip,t}; ‹конфігурація›.{F_G,d_mm,dHeading_deg,dMTS_deg}'],
         acc='запит № 70, ревізія ed5c6e6, рецензія 6056658077',
         num='найбільша нев’язка G: 3,8·10⁻¹⁶ (відносна); φ: 1,4·10⁻¹⁴°; d: 0', fam='LP1/A0; LP2-A1', cat='1',
         lim='Перевіряє узгодженість записів, не точність континуального розв’язку.',
         ver='', chk=['N-01', 'N-02', 'N-03', 'N-04']),
    dict(id='CL-05', sec=['sec:v_sif'], tabs=['tab:wp2'],
         claim='Визначення знакових КІН перевірено на заданих полях Вільямса (EDI 0,04–0,12 %, COD 0,76–1,31 %, знак K_II правильний у 6 з 6) і на еталоні крайової тріщини за чистого згину (EDI +0,34 %, COD −0,54 %); знак K_II перевірено чотирма незалежними способами.',
         src=['matlab/g2/SIF_WP2_RESULTS.md, рядки 27–32', 'matlab/g2/WP2_PREREGISTRATION.md', 'matlab/g2/evidence/wp2_20261118/verification_run_20261118_170139_962 (журнали)'],
         acc='WP0–WP2: звіт виконавця, к. 6982633594, запит № 23 (голова 513044c); окремої рецензії немає',
         num='K_I = 5,2632·10⁻³, K_II = +0,5954·10⁻³ Н·мм⁻³ᐟ² (P = 1 Н); K_II/K_I = 0,1131', fam='—', cat='1',
         lim='Точність у задачі з отворами, кільцями і зламами цим не доводиться; перевірки WP2 виконано на однорідній пластині.',
         ver='числа WP2 (поля Вільямса, еталон згину) відтворено з документа SIF_WP2_RESULTS.md, у JSON їх немає — не перераховувалося', chk=['N-48']),
    dict(id='CL-06', sec=['sec:v_lp1'], tabs=['tab:levels'],
         claim='Двадцять станів S0–S4 побітово відтворено під новою версією захисних умов (A0, 20 з 20, рівень A); це детермінована відтворюваність, а не збіжність за сіткою і не менша похибка.',
         src=['docs/research/G2_LP1_A0_TECHNICAL_REPORT_UA.md', 'matlab/g2/evidence/lp1_a0_20261122/', 'reports/G2/LP1_20261122_v3/LP1_COMPARISON.json (вибір за caseId + state)'],
         acc='запит № 65, голова e4f2aba, рецензія 6014015047; дозвіл к. 7083959515 (відкликано)',
         num='20/20 станів, VERIFY_ONLY ×4, 226 файлів без змін; таблиці S0–S4 LP1 і LP2A збігаються (макс. різниця 0 і 4·10⁻¹⁶)', fam='LP1/A0', cat='1',
         lim='Не доводить збіжності, точності абсолютних G, поведінки за межами S4. Сирі архіви поза пристроєм рецензент не відкривав.',
         ver='побітову тотожність сирих файлів перевірено лише рецензією 6014015047 (не перераховувалося)', chk=['N-49', 'N-50']),
    dict(id='CL-07', sec=['sec:v_lp1'],
         claim='Двадцять станів LP1 обчислено до наукового дозволу; записи прийнято як ретроспективні докази, виконання — ні. Захисні умови переписано (VG1: 74 тести, 8 з 8 пошкоджень виявлено; VG2: 138 тестів, 16 з 16) і дозвіл прив’язано до однієї іменованої кампанії.',
         src=['docs/research/G2_LP1_SR1_SCIENTIFIC_DECISION_UA.md', 'docs/research/G2_LP1_VG1_VERIFICATION_REPORT_UA.md', 'docs/research/G2_LP1_VG2_VERIFICATION_REPORT_UA.md', 'docs/research/G2_LP1_SR1_CLAIM_EVIDENCE_LEDGER.md'],
         acc='запити № 57, 59, 63; рецензії 6013194158 (6446a2c), 6013361177 (7cced5a), 6013734219 (7f843ac); к. 7079495852',
         num='VG1 25/25 виявляв 0 з 8 пошкоджень; VG2 138/138, 16/16', fam='LP1/A0', cat='1',
         lim='«Одноразовість» дозволу локальна, не криптографічна; рецензії лише за закомічених доказів.',
         ver='перевірено рецензіями; не перераховувалося (запит Q-13: GO — відтворення відповіді дослідника, не підпис)', chk=[]),
    dict(id='CL-08', sec=['sec:v_a1'], tabs=['tab:a1levels', 'tab:a1res', 'tab:a1fg'], figs=['fig:a1mesh', 'fig:a1fg'],
         claim='За фіксованої геометрії S4 подрібнення першого ребра біля вершини у 4,23 раза змінює контраст F_G не більше ніж на 5,1·10⁻⁶ (абсолютні одиниці), G — на 1,04–1,14·10⁻⁴ (відносно), кут МКН — менше ніж на 2·10⁻⁴°.',
         src=['matlab/g2/evidence/a1_campaign_20261122/campaign/A1_ANALYSIS.json: F_G, F_G_range, F_G_B9minusB0, records.‹конфігурація›[m].{G,KI,KII,MTS_deg,h1_mm,T3,CODminusEDI_rel,JoverGminus1}', 'docs/research/G2_A1_DEMONSTRATION_REPORT_UA.md'],
         acc='запит № 67, голова 30efdaa, рецензія 6014514118; дозвіл к. 7085445180 (відкликано)',
         num='ΔF_G(9−0): −4,48 / +1,18 / +5,08·10⁻⁶; ΔG/G: 1,04–1,14·10⁻⁴; h1(0)/h1(9) = 4,225', fam='A1 (B9)', cat='1',
         lim='Дослідження чутливості, не межа похибки: зовнішня сітка не подрібнювалась, рівні не вкладені, порядку збіжності й екстраполяції Річардсона немає; лише S4; EDI-розкид не монотонний.',
         ver='', chk=['A-01', 'A-02', 'A-03', 'A-04', 'A-05', 'A-06', 'A-07', 'A-08', 'A-09']),
    dict(id='CL-09', sec=['sec:v_soft2'],
         claim='Конфігурацію soft2 за консервативним правилом невизначеності не розрізнено (INCONCLUSIVE): у S4 |F_G|/U_конс = 0,863 (stiff13 — 2,21, soft1 — 1,70); за основним правилом розрізнено; статус не змінювався жодною пізнішою діагностикою.',
         src=['reports/G2/LP1_20261122_v3/LP1_COMPARISON.json: data[caseId, state].{F_G, U_cons_FG, FG_conservative_resolved}', 'docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: soft2.soft2Classification'],
         acc='рецензія 6013194158 (запит № 57) і десять наступних; остання — 6056658077',
         num='soft2: S0–S2 розрізнено, S3–S4 ні; soft1: S0–S1 ні, S2–S4 так; stiff13 — в усіх станах', fam='LP1/A0', cat='2',
         lim='Клас — наслідок правила, що не скорочує спільне зниження COD (0,88 %); перекласифікація a posteriori заборонена. Документи рецензій згадують лише S4.',
         ver='', chk=['N-51', 'N-52']),
    dict(id='CL-10', sec=['sec:gates', 'sec:v_sum', 'sec:p_exec'], tabs=['tab:gates'],
         claim='Усі 36 станів S0–S8 пройшли 16 критеріїв прийняття на одному сімействі сіток (COD–EDI 0,87–0,88 %, |J/G − 1| ≤ 3,2·10⁻⁵, розкид за областями ≈ 1,6·10⁻⁶).',
         src=['reports/G2/LP1_20261122_v3/LP1_COMPARISON.json (S0–S4)', 'docs/research/G2_LP2_evidence/campaign_20261125/lp2a_campaign.log (S5–S8)', 'matlab/g2/lp2/G2_LP2A_POLICY_v1.json (допуски, хеш 093a546b…)'],
         acc='запит № 70, рецензія 6056658077; S0–S4 — рецензія 6014015047',
         num='S5–S8: COD–EDI 0,8757–0,8796 %; T3 29 217–29 879; S0–S4: COD–EDI 0,8705–0,8794 %', fam='LP1/A0; LP2-A1', cat='2',
         lim='Малий розкид на спільній сітці не вимірює похибки дискретизації. J/G для S5–S8 (макс. 3,14·10⁻⁵) і розкид за областями у збережених JSON/журналі відсутні — з відомості кампанії.',
         ver='', chk=['N-53', 'N-54', 'N-55', 'N-56', 'N-57']),
    dict(id='CL-11', sec=['sec:first'], tabs=['tab:m2'],
         claim='Три однакові м’які кільця збільшують G на +2,18 %, три жорсткі зменшують на 2,93 % на замороженій тріщині S2; на S0 повний ефект є прямим точно; знак ефекту м’яких кілець змінюється між S0 (−0,61 %) і S1 (+0,62 %).',
         src=['matlab/g2/evidence/m2_20261121/report/m2_results.csv: R_EDI, dTheta_deg', 'matlab/g2/evidence/m4b_20261121/analysis/cases_16_logical.csv: F_G, F_theta_deg (mask all)'],
         acc='WP-M: к. 6993841735 (запит № 35); M2: к. 7061943355 (запит № 38, 49ec4fc) — звіти виконавця; M4.B: к. 7068731805',
         num='S2: +2,181 / −2,931 %; S0: −0,61 / −0,90 %; S1: +0,62 / −1,81 %', fam='M4.B / R1 / M2', cat='1',
         lim='Окремих рецензій WP-M, M2, M3 немає (прийняті наступними завданнями). За основним правилом розрізнено, за консервативним — ні (WP-M, M2).',
         ver='', chk=['M-10']),
    dict(id='CL-12', sec=['sec:m4b', 'sec:choice'], tabs=['tab:m4b'], figs=['fig:m4bbars'],
         claim='Ефект окремого кільця на замороженій тріщині S2 залежить від його положення: м’які +4,43 / −3,63 / +2,33 %, жорсткі −3,65 / +3,04 / −1,82 %; сума трьох м’яких (+3,13 %) — мала різниця великих внесків; жорстке кільце 3 — −1,8248 %, тобто −1,82 %, а не −1,83 %.',
         src=['matlab/g2/evidence/m4b_20261121/analysis/cases_16_logical.csv: F_G, F_theta_deg', 'matlab/g2/evidence/m4b_r1_20261121/analysis/r1_crossfamily.csv: class, Q_orig, Q_alt', 'matlab/g2/G2_M4B_RESULTS.md, §5 (джерело −1,83)'],
         acc='запит № 49 (ece7469), к. 7068731805 і 7068743888; R1: запит № 51 (6699c54), рецензія 6011572343, к. 7077407079',
         num='F_G(S2): мʼякі {1,2,3,12,13,23,123} +4,430 / −3,628 / +2,331 / +0,316 / +6,747 / −1,675 / +2,181 %; жорсткі −3,652 / +3,035 / −1,825 / −0,906 / −5,478 / +0,980 / −2,931 %', fam='M4.B / R1 / M2', cat='1',
         lim='Одна геометрія, одна сітка, спільне ядро вершини; R1: клас STABLE у 30 з 30, але дрейф між сімействами у 10–100 разів більший за основну невизначеність; «розміщення важливіше за кількість» і «найкраща архітектура» заборонено.',
         ver='', chk=['M-01', 'M-02', 'M-03', 'M-04', 'M-05', 'M-06', 'M-11']),
    dict(id='CL-13', sec=['sec:m4b'], tabs=['tab:m4b'], figs=['fig:m4bbars'],
         claim='Порядок кілець за впливом на локальний кут МКН (кільце 1 найсильніше, +1,31° / −1,11°) інший, ніж за енергією; кільця 2 і 3 діють на кут у ≈ 3,5–3,8 раза слабше.',
         src=['matlab/g2/evidence/m4b_20261121/analysis/cases_16_logical.csv: F_theta_deg (ring1, ring2, ring3)'],
         acc='запит № 49, к. 7068731805 (гіпотезу про однаковий порядок спростовано за наперед зафіксованим правилом)',
         num='відношення |F_θ(1)|/|F_θ(2)|, |F_θ(1)|/|F_θ(3)|: 3,529; 3,709 (м’які); 3,626; 3,850 (жорсткі)', fam='M4.B / R1 / M2', cat='1',
         lim='Один стан S2. Первинне формулювання звіту «3,5–3,9» виправлено на «3,5–3,8» (перерахунок дає 3,8499; запит Q-24).',
         ver='', chk=['M-07']),
    dict(id='CL-14', sec=['sec:m4b'],
         claim='Парні та потрійна взаємодії розкладу є числовими членами облікового розкладу (точна алгебраїчна тотожність), а не фізичними взаємодіями кілець; жодна з архітектур не є «найкращою» чи «обхідною».',
         src=['matlab/g2/G2_M4B_RESULTS.md, рядки 81–92, 129', 'matlab/g2/evidence/m4b_20261121/analysis/cases_16_logical.csv'],
         acc='к. 7068731805, рішення 2 і 4 (запит № 47/49)',
         num='парні F_G: від −4,9·10⁻³ до −1,4·10⁻⁵; потрійна: −7,3·10⁻⁴ (м’які), +3,1·10⁻⁴ (жорсткі)', fam='M4.B / R1 / M2', cat='1',
         lim='Тотожність точна, фізичне тлумачення рецензія забороняє. Первинне формулювання звіту «близько ±5·10⁻⁴» виправлено за перерахунком (−7,33·10⁻⁴ і +3,09·10⁻⁴; джерело: «±3–7·10⁻⁴»; запит Q-24).',
         ver='', chk=['M-08', 'M-09']),
    dict(id='CL-15', sec=['sec:evol', 'sec:fgdef'], tabs=['tab:FG'], figs=['fig:GFG'],
         claim='На власних траєкторіях екранування stiff13 монотонно посилюється (−3,93 → −7,17 → −10,95 %), екранування soft2 монотонно слабшає (−4,26 → −2,93 → −1,49 %), підсилення soft1 зростає (+2,75 → +6,33 → +10,73 %) на S0, S4, S8; H1 і H2 підтримано як обчислені тенденції.',
         src=['docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: stiff13.F_G, soft2.F_G, soft1.F_G (9 значень), H1, H2', 'reports/G2/LP1_20261122_v3/LP1_COMPARISON.json (S0–S4, ті самі числа)', 'docs/research/G2_LP2A1_DEMONSTRATION_REPORT_UA.md'],
         acc='запит № 70, голова ed5c6e6, рецензія 6056658077 (SCIENTIFIC_ACCEPT_LP2A1_DEMONSTRATION), дозвіл к. 7159870558',
         num='F_G(S0..S8), %: stiff13 −3,931 … −10,949; soft2 −4,259 … −1,488; soft1 +2,746 … +10,732', fam='LP1/A0; LP2-A1', cat='2',
         lim='Зміна F_G між сімействами сіток (1–3·10⁻⁵) перевищує основну невизначеність; сертифікованої похибки для S5–S8 немає; soft2 лишається нерозрізненим за консервативним правилом; тенденція поза S8 не стверджується.',
         ver='', chk=['N-05', 'N-06', 'N-07', 'N-08', 'N-09', 'N-10', 'N-11', 'N-12', 'N-13', 'N-14', 'N-15', 'N-16']),
    dict(id='CL-16', sec=['sec:abs', 'sec:p_K'], tabs=['tab:Gabs'], figs=['fig:GFG'],
         claim='Абсолютна G за P = 1 Н зростає в усіх чотирьох конфігураціях (S4 → S8: H +66,37 %, stiff13 +59,60 %, soft2 +68,84 %, soft1 +73,26 %); відносне екранування не означає зменшення рушійної сили, зупинки чи стійкості.',
         src=['docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: states.‹конфігурація›.G'],
         acc='запит № 70, рецензія 6056658077',
         num='G(S8)/G(S0): 2,983 / 2,765 / 3,069 / 3,214; G(S4)/G(S0): 1,79 / 1,73 / 1,82 / 1,86', fam='LP1/A0; LP2-A1', cat='1',
         lim='Умовне навантаження P = 1 Н; для висновку про стійкість потрібні R-крива і режим навантаження (їх у моделі немає).',
         ver='', chk=['N-17', 'N-18', 'N-19', 'N-20', 'N-21', 'N-22']),
    dict(id='CL-17', sec=['sec:m5', 'sec:c_table'], tabs=['tab:c_sum'],
         claim='Різниця траєкторій виникає переважно на першому зламі: лінеаризована частка першого зламу 16 sin Δθ_0 / d(S4) у бічному зміщенні S4 дорівнює 0,969 (stiff13), 0,798 (soft2), 0,990 (soft1).',
         src=['docs/research/G2_M5_evidence/M5_EXISTING_EVIDENCE.json: steering.‹конфігурація›.firstKinkShare_4n_sin', 'docs/research/G2_M5_MECHANISM_ATTRIBUTION_MEMO_UA.md'],
         acc='запит № 68, рецензії 6014654088 (C2: помилку знака виправлено) і 6017650419; SR1 6013194158',
         num='0,9694 / 0,7977 / 0,9904', fam='LP1/A0', cat='3',
         lim='Геометрична оцінка, не доказ причинності; чутливість до кроку Δa не досліджувалась; для soft2 лише 80 % (кути після S0 одного знака).',
         ver='', chk=['N-37']),
    dict(id='CL-18', sec=['sec:m5'], tabs=[],
         claim='На всіх чотирьох кроках S0 → S4 знак скінченної різниці d(C_X − C_H)/da збігається зі знаком F_G для всіх трьох архітектур (12 з 12); це енергетичне тлумачення, узгоджене з розрахунками, а не незалежний доказ.',
         src=['docs/research/G2_M5_evidence/M5_EXISTING_EVIDENCE.json: irwinKies.‹конфігурація›.{deltaC_rel_S0toS4, d_deltaC_da_sign, F_G_fd_compliance_per_step, F_G_EDI_midstep_mean}'],
         acc='запит № 68, рецензії 6014654088 (C1, C3) і 6017650419',
         num='м’яке кільце 2: ΔC/C = 0,41 % (S0) → 0,33 % (S4); stiff13: оцінка за податливістю −1,66 % проти EDI −4,21 % на першому кроці', fam='LP1/A0', cat='3',
         lim='Податливості взято вздовж різних траєкторій; податливість у точці сили чутлива до сітки (перші кроки); механізм екранування кільцем 2 не доведено.',
         ver='', chk=['K-01', 'K-02', 'K-03']),
    dict(id='CL-19', sec=['sec:g1'], tabs=['tab:g1fo', 'tab:g1verdict'], figs=['fig:g1energy'],
         claim='Знак внеску кільця в G збігається зі знаком похідної енергії деформації в області кільця за довжиною тріщини в усіх 21 порівнянні (12 одиночних кілець на двох сімействах сіток + 9 порівнянь архітектур); відношення спостереженого до оцінки першого порядку — 0,68–0,78 (м’які) і 1,14–1,26 (жорсткі).',
         src=['docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json: firstOrderSingleRing[12], firstOrderArchitecture[9], homogeneousPath', 'docs/research/G2_G1_FIELD_INVESTIGATION_UA.md'],
         acc='запит № 69, голова 2baa641, рецензія 6018861433 (G1_PARTIALLY_SUPPORTED)',
         num='21/21 збігів знака; відношення: м’які 0,683–0,778, жорсткі 1,141–1,258', fam='M4.B / R1 / M2; LP1/A0', cat='3',
         lim='21 порівняння не є незалежними випробуваннями (спільні поля, одне навантаження, 6 повторів на іншій сітці); нормування на ΔU/Δa відрізняється від G за EDI на +8,0/+1,2/−5,9 % (S0/S2/S4); механізм передачі навантаження не встановлено.',
         ver='', chk=['G-01', 'G-02', 'G-04']),
    dict(id='CL-20', sec=['sec:g1', 'sec:mechsum'], tabs=['tab:g1verdict'],
         claim='Відхилення спостереженого від оцінки першого порядку (14–32 %) є поправками скінченного контрасту (параметр розвинення 1/λ − 1 = +1 для м’якого і −0,5 для жорсткого кільця), а не виведеними членами другого порядку.',
         src=['docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json: firstOrderSingleRing, firstOrderArchitecture', 'docs/research/G2_G1_FIELD_INVESTIGATION_UA.md, рядки 64, 156, 192 (історична назва «другого порядку»)'],
         acc='рецензія 6018861433: «істотні нелінійні поправки контрасту (14–32 %)»; перейменування — виправлення К-22 цього звіту',
         num='відхилення 14–32 %; параметр +1 і −0,5', fam='M4.B / R1 / M2; LP1/A0', cat='3',
         lim='Формулювання «finite-contrast, не second-order» виявлено під час підготовки звіту; у рецензіях запитів № 8–71 дослівно не знайдено (запит Q-16). Чи справді причина — скінченний контраст, перевірить лише зменшення контрасту.',
         ver='', chk=['G-03']),
    dict(id='CL-21', sec=['sec:g1'], tabs=['tab:g1rings'],
         claim='Область кільця 2 однорідної пластини в S2 перебуває у змішаному напруженому стані з переважанням стиску (σ_1 = +1,919·10⁻⁴, σ_2 = −3,806·10⁻⁴ МПа), а не «стиснута в обох напрямках»; тип стану не визначає знака ефекту кільця.',
         src=['docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json: ringEnvironment.M4B[ring, region = «ring (6.35–19.05 mm)»].{avgTensor_s1, avgTensor_s2, compressiveAxisAngleToLine_deg, fracCompressionDominated}'],
         acc='виправлення К-21 цього звіту; історичний текст (G1_FIELD_INVESTIGATION_UA.md, рядки 9, 106; запит № 69) не змінено',
         num='кільця 1/2/3: σ_1 = +4,238 / +1,919 / +0,498; σ_2 = −1,592 / −3,806 / −5,722 (·10⁻⁴ МПа); кут осі стиску 21,1 / 5,1 / 27,1°; частка стиску 12 / 75 / 96 %', fam='M4.B / R1 / M2', cat='1',
         lim='Усереднення за областю кільця однорідної пластини в S2; не рецензовано (рецензія 6018861433 цього не зазначала; запит Q-15).',
         ver='', chk=['G-05', 'G-06']),
    dict(id='CL-22', sec=['sec:g1', 'sec:mechsum'], figs=['fig:g1dirs', 'fig:g1map'], tabs=['tab:g1verdict'],
         claim='Лінія «шарнір — сила» наближено описує напрямок передачі стиску лише на ділянці від отвору 2 до сили (медіанний кут 11,4°, 61 % площі смуги ±10 мм < 15°); вона не є гребенем стиску чи енергії; «розвантаження діагонального розпору» лишається гіпотезою (G1_PARTIALLY_SUPPORTED).',
         src=['docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json: corridor.M4B[offset_mm = 0], line, influenceMap, influenceMapProfiles', 'docs/research/G2_G1_FIELD_INVESTIGATION_UA.md, рядок 174'],
         acc='запит № 69, рецензія 6018861433',
         num='медіана 11,4°; 61,0 %; кільця 1, 3 лежать на 32,2 мм нижче і 43,8 мм вище лінії', fam='M4.B / R1 / M2', cat='3',
         lim='Нижня частина лінії: середні вздовж лінії знакозмінні («змішаний знак»); для перевірки потрібні контрольні розрахунки (інше положення сили й опор), яких не виконано.',
         ver='', chk=['G-07', 'G-08']),
    dict(id='CL-23', sec=['sec:x6def', 'sec:x6G'], tabs=['tab:x6G', 'tab:x6dec'],
         claim='У схрещеному порівнянні в S4 тотожність F_G = F_m + F_p + F_i виконується з нев’язкою не більше 1,2·10⁻¹⁶ (G, J, K_I, кут МКН); значення чотирьох G_AB у таблиці збігаються зі збереженими.',
         src=['docs/research/G2_M5_X6_evidence/campaign_20261125/M5X6_ANALYSIS.json: ‹конфігурація›.G.{qHH,qXH,qHX,qXX,F_mat,F_path,F_int,F_tot,identityResidual}', 'docs/research/G2_M5_X6_evidence/M5X6_DIAGONAL_AUDIT.json'],
         acc='запит № 69, голова d5f4681, рецензія 6054335912 (SCIENTIFIC_ACCEPT_M5_X6_DEMONSTRATION); дозвіл к. 7096377708',
         num='збережені нев’язки ≤ 1,11·10⁻¹⁶; незалежне перерахування: 1,11·10⁻¹⁶', fam='M5-X6 (B9)', cat='1',
         lim='Тотожність точна за побудовою; рецензент не запускав MATLAB і не відкривав архів USB.',
         ver='', chk=['X-01', 'X-02', 'X-07']),
    dict(id='CL-24', sec=['sec:x6G', 'sec:c_answer'], tabs=['tab:x6dec'], figs=['fig:x6bars'],
         claim='У фіксованому стані S4 матеріальний внесок становить 102,7 / 103,4 / 105,7 % модуля повного ефекту (stiff13 / soft2 / soft1); траєкторний внесок протилежний за знаком і дорівнює 2,7 / 3,1 / 5,6 % матеріального; взаємодійний — 0,1–0,2 %.',
         src=['docs/research/G2_M5_X6_evidence/campaign_20261125/M5X6_ANALYSIS.json: ‹конфігурація›.P1_directShare, G.{F_mat,F_path,F_int}', 'docs/research/G2_M5_X6_DEMONSTRATION_REPORT_UA.md'],
         acc='запит № 69, рецензія 6054335912; P1 і P2 підтверджено',
         num='F_G / F_m / F_p / F_i, %: stiff13 −7,1736 / −7,3684 / +0,2024 / −0,0077; soft2 −2,9317 / −3,0320 / +0,0945 / +0,0058; soft1 +6,3294 / +6,6912 / −0,3735 / +0,0117', fam='M5-X6 (B9)', cat='1',
         lim='Лише S4, лише рівень сітки B9, спільне ядро вершини; сертифікованої похибки немає (дослідницький масштаб U_m = 3,1·10⁻⁵ — для S2); знак F_i(soft2) = +5,8·10⁻⁵ лежить нижче масштабу чутливості 6,2·10⁻⁵; звіт X6 у формулюваннях сильніший за рецензію (запит Q-18).',
         ver='', chk=['X-03', 'X-04', 'X-05']),
    dict(id='CL-25', sec=['sec:x6ref'], tabs=['tab:x6ref'],
         claim='Розклад на матеріальний, траєкторний і взаємодійний внески залежить від бази порівняння (однорідна база, Шеплі, база «X на X», мультиплікативний); це облікова процедура, а не причинні частки.',
         src=['docs/research/G2_M5_X6_evidence/campaign_20261125/M5X6_ANALYSIS.json: ‹конфігурація›.G.{shapley_mat, refXX_mat, R_mat, R_path, R_int}'],
         acc='запит № 69, рецензія 6054335912',
         num='F_m, %: stiff13 −7,3684 / −7,3722 / −7,3760; soft2 −3,0320 / −3,0291 / −3,0262; soft1 +6,6912 / +6,6970 / +6,7029', fam='M5-X6 (B9)', cat='1',
         lim='Чинники не незалежні (траєкторію породив сам матеріал); «траєкторія гасить керування на кожному етапі» заборонено.',
         ver='', chk=['X-08']),
    dict(id='CL-26', sec=['sec:x6angle'], tabs=['tab:x6ang'], figs=['fig:x6bars'],
         claim='У стані S4 власна траєкторія майже повністю компенсує дію матеріалу на локальний кут МКН (траєкторія/матеріал = −1,133 / −0,931 / −1,047; залишок 7–11 % матеріального члена), але лише на кілька відсотків — його дію на G.',
         src=['docs/research/G2_M5_X6_evidence/campaign_20261125/M5X6_ANALYSIS.json: ‹конфігурація›.MTS_deg.{F_mat,F_path,F_int,F_tot}'],
         acc='запит № 69, рецензія 6054335912',
         num='F_θ, °: stiff13 +0,0778 = −0,7113 + 0,8057 − 0,0166; soft2 −0,0357 = −0,4714 + 0,4387 − 0,0030; soft1 −0,0888 = +1,2379 − 1,2959 − 0,0308', fam='M5-X6 (B9)', cat='1',
         lim='Стосується лише локального приросту кута в S4 у локальному базисі кожної траєкторії, не накопичених зміщень чи курсів; динамічний механізм стабілізації не встановлено (тлумачення «підлаштування до нормального відриву» — категорія 3).',
         ver='', chk=['X-09', 'X-10']),
    dict(id='CL-27', sec=['sec:x6pred', 'sec:c_table'], tabs=['tab:x6P'],
         claim='Передбачення P1 (|F_m| ≥ 0,9|F_G|) і P2 (F_p + F_i протилежне F_m) підтверджено; знаки F_p і F_i окремо (P3) отримано; дослідницьке передбачення P4 не виконано для stiff13 і soft1 (виконано для soft2), причину не встановлено.',
         src=['docs/research/G2_M5_X6_evidence/campaign_20261125/M5X6_ANALYSIS.json: ‹конфігурація›.{P1_pass, P2_pass, P3_signs}', 'docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json: firstOrderSingleRing, firstOrderArchitecture (для P4)', 'scripts/g2/m5/x6/m5x6_report_tables.py (P4)'],
         acc='запити № 68–69, рецензії 6018861433, 6054335912',
         num='P4: F_m = −7,37 % поза [−7,11; −6,50]; −3,03 % у [−3,28; −2,99]; +6,69 % поза [+5,67; +6,23]', fam='M5-X6 (B9)', cat='3',
         lim='P4 відсутнє в закріпленому плані і в M5X6_ANALYSIS.json — перераховано з G1 JSON за правилом (жорстка смуга для stiff13, м’яка для решти); P2 і P4 для stiff13/soft1 були несумісні наперед.',
         ver='', chk=['X-06', 'X-14', 'X-15']),
    dict(id='CL-28', sec=['sec:x6limits'],
         claim='Розклад виконано лише для S4 на одному рівні сітки (B9); для S5–S8 і для S1–S3 схрещені члени не обчислено; базові G_HH різних сімейств відрізняються (1,539127 і 1,538959·10⁻⁸), тому F_G(stiff13) = −7,1736 % (B9) і −7,1732 % (базова сітка) не змішуються.',
         src=['docs/research/G2_M5_X6_evidence/campaign_20261125/M5X6_ANALYSIS.json: reference, explorationReference', 'docs/research/G2_M5_evidence/M5_EXISTING_EVIDENCE.json: decompositionExisting'],
         acc='запит № 69, рецензія 6054335912',
         num='G_HH(B9) = 1,539127·10⁻⁸; G_HH(A0) = 1,538959·10⁻⁸ Н/мм', fam='M5-X6 (B9)', cat='4',
         lim='Контрасти розділу про S0–S8 — порівняння незалежно побудованих траєкторій; їх зміну не можна читати як зміну матеріального чи траєкторного внеску.',
         ver='', chk=['X-12']),
    dict(id='CL-29', sec=['sec:p_design', 'sec:p_exec'], tabs=['tab:p_hyp', 'tab:p_qual'],
         claim='Кампанія LP2-A1 прийняла 16 нових станів S5–S8 (16 допущень, 16 розв’язків, жодної зупинки); усі виконують 16 критеріїв; усі чотири випадки завершилися міткою CAMPAIGN_LIMIT_REACHED у S8; гіпотези H1–H4 зафіксовано до розрахунків.',
         src=['docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json', 'docs/research/G2_LP2_evidence/campaign_20261125/LP2A_CALLS.json', 'docs/research/G2_LP2_evidence/campaign_20261125/lp2a_campaign.log', 'docs/research/G2_LP2_evidence/campaign_20261125/LP2A_RUN_LEDGER_SHA256.json', 'matlab/g2/lp2/G2_LP2A_POLICY_v1.json (хеш 093a546b…)', 'docs/research/G2_LP2A1_DEMONSTRATION_REPORT_UA.md'],
         acc='запит № 70, голова ed5c6e6, рецензія 6056658077; дозвіл к. 7159870558; готовність 6055250219, поправки 6055869194 (107/107)',
         num='4 виклики, 16 розв’язків, 0 HOLD; архів LP2-A1 SHA-256 82740133… (не відкривався рецензентом)', fam='LP2-A1', cat='1',
         lim='Статус полів політики лишається PROPOSED_NOT_AUTHORIZED у клоні (запит Q-08); дозвіл — відтворення відповіді дослідника; шлях закриття локальної відмови (C1) перевірено лише на синтетичних записах.',
         ver='решта перевірено рецензією 6056658077', chk=['N-54', 'N-55']),
    dict(id='CL-30', sec=['sec:p_limit'], tabs=['tab:p_scan', 'tab:p_outlook'],
         claim='Кампанія зупинена на S8 не напрямною областю 15 мм і не поведінкою тріщини, а межею надійності незміненого генератора сіток: на 82 синтетичних ламаних він проходить 8/8 до S8, 5/8 у S9, 4/8 у S10, 2/8 у S11 і майже ніколи далі; напрямна область — запобіжник реалізації, а не механічна межа.',
         src=['docs/research/G2_LP2_evidence/LP2_MESH_SCAN.json: rows[state, pass]', 'docs/research/G2_LP2_evidence/LP2_MESH_PROBE.json', 'docs/research/G2_LP2_CONTINUATION_MEMO_UA.md'],
         acc='запити № 70–71; рецензії 6055250219, 6055869194, 6056658077',
         num='табл. 30: 8/8, 8/8, 8/8, 5/8, 4/8, 2/8, 0/5, 1/4, 0/4 … 0/1 (S6…S20)', fam='LP2-A2', cat='1',
         lim='Лише побудова сітки на синтетичних ламаних, не траєкторії; обмеження 15 мм не фізичне.',
         ver='', chk=['P-07']),
    dict(id='CL-31', sec=['sec:p_K'], tabs=['tab:p_state'], figs=['fig:p_kk'],
         claim='Мода II мала в усіх станах; змішаність K_II/K_I у S8 дорівнює 0,01120 (H), 0,00786 (stiff13), 0,01139 (soft2), 0,01459 (soft1); локальний кут МКН практично пропорційний змішаності мод (θ ≈ −2 K_II/K_I), тому кутові розбіжності архітектур є відображенням розбіжностей змішаності.',
         src=['docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: states.‹конфігурація›.{KI, KII, MTS}'],
         acc='запит № 70, рецензія 6056658077',
         num='K_I·10³ у S8: 9,146881 / 8,631902 / 9,078537 / 9,624798; K_II·10⁵: +10,24807 / +6,78508 / +10,34358 / +14,03784', fam='LP1/A0; LP2-A1', cat='1',
         lim='Співвідношення θ ≈ −2 K_II/K_I — наближення малих кутів.',
         ver='', chk=['N-45', 'N-47']),
    dict(id='CL-32', sec=['sec:p_dir'], tabs=['tab:p_head', 'tab:p_dev'], figs=['fig:p_dir', 'fig:p_traj'],
         claim='Відносний курс stiff13 монотонно прямує до нуля й у S8 змінює знак (+0,023460°); протилежність знаків Δφ і Δθ підтверджена лише для S4–S7 (stiff13) і S4–S8 (soft1); геометричний прогноз для S9 за Δφ_9 = Δφ_8 + Δθ_8 (+0,406342; −0,060412; −0,506161°) — тотожність, а не розв’язок.',
         src=['docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: stiff13.dHeading_deg, stiff13.dMTS_deg, soft1.*, soft2.*'],
         acc='запит № 70, рецензія 6056658077 (уточнення: протилежність знаків лише S4–S7; «crossover/turning tendency»)',
         num='Δφ(stiff13), °: −0,661086 … −0,257427, +0,023460; Δθ: +0,077804 … +0,382882', fam='LP2-A1', cat='2',
         lim='Немає сертифікованого розрізнення для змін порядку 0,002 мм чи 0,02°; S9 не проходив ні МСЕ, ні критеріїв; первинний звіт кампанії (рядок 122) стверджує протилежність знаків загалом — виправлено К-17.',
         ver='', chk=['N-23', 'N-24', 'N-25', 'N-26', 'N-27', 'N-28', 'N-32', 'N-46']),
    dict(id='CL-33', sec=['sec:p_dir', 'sec:c_table'], tabs=['tab:p_dev'], figs=['fig:p_dir'],
         claim='У S4–S8 знак бічного зміщення d збігається зі знаком F_G в усіх трьох конфігураціях (S8: −0,278, −0,209, +0,495 мм); найбільше розходження траєкторій 0,495 мм; насичення зміщення stiff13 не стверджується (d: −0,280054 → −0,277757 мм, +0,0023 мм).',
         src=['docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: ‹конфігурація›.d_mm, F_G'],
         acc='запит № 70, рецензія 6056658077 («немає сертифікованої роздільної здатності, асимптоти»)',
         num='d(S8), мм: −0,277757 / −0,208658 / +0,494777', fam='LP2-A1', cat='2',
         lim='Три випадки; зміщення — десяті частки міліметра; у політиці d описано як «від ламаної H», код обчислює проєкцію різниці вершин на нормаль H (запит Q-20).',
         ver='', chk=['N-29', 'N-30', 'N-31', 'N-33']),
    dict(id='CL-34', sec=['sec:p_split'], tabs=['tab:p_split'],
         claim='Для stiff13 і soft1 модуль F_G зростає, а різниця курсів відносно H зменшується (максимум |Δφ| у S2: −0,715° і +1,124°); для soft2 модуль F_G зменшується, а різниця курсів зростає; це спостереження, а не механізм, і воно не пояснює розбіжності без розкладу для S5–S8.',
         src=['docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: ‹конфігурація›.F_G, dHeading_deg, dMTS_deg'],
         acc='запит № 70, рецензія 6056658077',
         num='|Δθ|(S8)/|Δθ|(S4): 4,9 (stiff13), 4,4 (soft1)', fam='LP2-A1', cat='2',
         lim='Розкладу на матеріальний/траєкторний/взаємодійний внески для S5–S8 не існує; три випадки; H3 — лише описовий проксі (DESCRIPTIVE_PROXY_ONLY).',
         ver='', chk=['N-34', 'N-35']),
    dict(id='CL-35', sec=['sec:p_dist', 'sec:c_not'], tabs=['tab:p_dist', 'tab:p_s8'],
         claim='Жодний прийнятий стан не є зустріччю з міжфазною межею: найближча вершина S8 лежить на 24,096–24,731 мм від кола кільця 1, на 57,6–57,8 мм від кільця 2 і на 103,6–103,7 мм від кільця 3; запас до межі 15-мм напрямної 9,1–9,7 мм; H4 не піддається перевірці в LP2-A1; геометричний кандидат S9 — не прогноз.',
         src=['docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: H4.terminals[].clearanceToRingCircles_mm; states.‹конфігурація›.terminal.candidate.clearance', 'docs/research/G2_LP2A1_DEMONSTRATION_REPORT_UA.md (рядок 165: «≈ 19 мм» — виправлено К-17)'],
         acc='запит № 70, рецензія 6056658077',
         num='відстань S8 до кола кільця 1: 24,323 (H) / 24,096 / 24,158 / 24,731 мм; кандидат S9: 21,689 / 21,473 / 21,488 / 22,113 мм', fam='LP2-A1', cat='4',
         lim='Відстані — до номінального кола R = 19,05 мм; різниця «багатокутник − коло» ≤ 0,0033 мм (для S5–S8 у JSON відсутня); H4 — гіпотеза для окремої кваліфікації LP2-B.',
         ver='відстані перераховано з координат вершин (а не прочитано зі збережених полів)', chk=['N-38', 'N-39', 'N-40', 'N-41', 'N-42', 'N-43', 'N-44']),
    dict(id='CL-36', sec=['sec:p_hres'], tabs=['tab:p_hres'],
         claim='Лінійне продовження тренду F_G(soft2) до нуля поблизу s ≈ 73 мм (72,8 мм за останнім кроком, 73,9 мм за хордою S4–S8) — неперевірена числова екстраполяція, а не геометричний чи руйнівний прогноз.',
         src=['docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: soft2.F_G', 'docs/research/G2_LP2A1_DEMONSTRATION_REPORT_UA.md, рядок 101'],
         acc='запит № 70, рецензія 6056658077 («not a geometrical or fracture prediction»)',
         num='приріст F_G за крок зростає від 0,34 до 0,39 п.п.', fam='LP2-A1', cat='4',
         lim='Приріст за крок не сталий; жодного розв’язку за S8; понад S8 нічого не стверджується.',
         ver='', chk=['N-36']),
    dict(id='CL-37', sec=['sec:pr_problem'], tabs=['tab:pr_diag'], figs=['fig:pr_f1'],
         claim='Успадкований генератор на 117 геометріях без обмежувачів не пройшов 60 (59 × HOLD_LIP_STATIONS + 1 × мінімальний кут); на кожному з 116 невдалих відрізків верхній берег має рівно на один вузол менше, далеко (32–72 мм) за вершиною; невдалих відрізків на геометрію від 1 до 6.',
         src=['docs/research/G2_LP2A2_evidence/supplement/LP2A2_RECONCILIATION.json: originalCrackFaceFailures, accounting.originalMesher', 'docs/research/G2_LP2A2_evidence/attempt2/LP2A2_MESH_QUALIFICATION_ATTEMPT2.json: rows[].old', 'docs/research/G2_LP2A2_MESH_QUALIFICATION_MEMO_UA.md (рядок 18: «на одному відрізку» — уточнено)'],
         acc='запит № 71, голова 05bc5f1, рецензія 6058599118 (LP2A2_MESH_QUALIFIED_RESTRICTED, лише геометрія)',
         num='57 пройшло / 60 HOLD; A 0, B 1, C1 46, C2 9, C3 3', fam='LP2-A2', cat='1',
         lim='Спостережено закономірність; пояснення «незалежне ділення двох берегів» — гіпотеза, що відповідає даним (категорія 3); жодного розв’язку МСЕ.',
         ver='', chk=['P-01', 'P-09']),
    dict(id='CL-38', sec=['sec:pr_method', 'sec:pr_forced'], tabs=['tab:pr_forced', 'tab:pr_AB'], figs=['fig:pr_f2', 'fig:pr_f3', 'fig:pr_f7'],
         claim='У новому сімействі береги засіваються спільно й пари визначаються за індексом зерна; єдина вимушена пара на колі 15-мм напрямної має розбіжність станцій до 2,282 мкм, а координатний залишок після згортання — 0; у допоміжному файлі predictedDx_mm має знак, протилежний circleDx_mm (формула в коді відповідає circleDx_mm).',
         src=['docs/research/G2_LP2A2_evidence/supplement/LP2A2_SUPPLEMENT.json: rows[].forcedPairs', 'docs/research/G2_LP2A2_evidence/supplement/LP2A2_RECONCILIATION.json: forcedPairs', 'scripts/g2/lp2a2/', 'docs/research/G2_LP2A2_MESH_QUALIFICATION_MEMO_UA.md'],
         acc='запит № 71, голова 05bc5f1, рецензія 6058599118 (потрібна примітка-erratum про знак)',
         num='max |Δs| 2,282 мкм; |Δx| 1,948 мкм; параметризація 0,768 мкм; залишок формули 1,7·10⁻⁹ мм; мін. кут 21,79°; 113 з 113 пар', fam='LP2-A2', cat='1',
         lim='Геометричний аудит — не фізична придатність; розбіжність до згортання (≤ 2,28 мкм) і залишок після (0) не змішувати; 68 з 113 пар нетривіальні (решта — прямі ділянки).',
         ver='', chk=['P-04', 'P-05', 'P-06']),
    dict(id='CL-39', sec=['sec:pr_qual', 'sec:pr_audit_sec'], tabs=['tab:pr_groups', 'tab:pr_pop', 'tab:pr_2x2', 'tab:pr_state', 'tab:pr_metrics'], figs=[],
         claim='На наперед оголошеному наборі з 117 геометрій новий генератор з’єднав 113, пройшов усі геометричні аудити на 112 (спроба 2), без жодної регресії відносно старого; виправлено 55 відмов; драбина кроків засівання ухвалена після спроби 1 на тому самому наборі.',
         src=['docs/research/G2_LP2A2_evidence/LP2A2_TEST_SET.json', 'docs/research/G2_LP2A2_evidence/attempt1/', 'docs/research/G2_LP2A2_evidence/attempt2/', 'docs/research/G2_LP2A2_evidence/supplement/LP2A2_RECONCILIATION.json: accounting, pairedAllNonGuard, pairedC1', 'docs/research/G2_LP2A2_evidence/lp2a2_testset_build.m', 'scripts/g2/lp2a2/'],
         acc='запит № 71, голова 05bc5f1, рецензія 6058599118; набір SHA-256 7d2b6d35… (зафіксовано комітом 9a2442b)',
         num='спроба 1: 108 / 108 / 107 / 10 HOLD; спроба 2: 113 / 113 / 112 / 5 HOLD; ступенів драбини 135; пара: 57 / 0 / 55 / 5', fam='LP2-A2', cat='1',
         lim='Регресійна кваліфікація (рівень 3 з 5), не незалежна валідація: набір складено зі сканувань LP2, продовжень і чотирьох станів S8; частки не є ймовірністю успіху на довільній траєкторії; універсальну гарантію парування не стверджено.',
         ver='', chk=['P-02', 'P-03', 'P-10', 'P-11', 'P-12', 'P-13']),
    dict(id='CL-40', sec=['sec:pr_resid'], tabs=['tab:pr_resid'], figs=['fig:pr_f8'],
         claim='П’ять геометрій не побудовано (чотири — мінімальний кут на всіх щаблях, одна — аудит фаз); усі мають зазор «коло напрямної — коло кільця» не більший за 0,492 мм, а серед сіток, що пройшли, найменший зазор 0,403 мм; тож межа ≈ 1,0 мм емпірична.',
         src=['docs/research/G2_LP2A2_evidence/supplement/LP2A2_RECONCILIATION.json: remainingFailures[].tipGuideClearanceToRing_mm', 'docs/research/G2_LP2A2_evidence/attempt2/LP2A2_SUMMARY_ATTEMPT2.json'],
         acc='запит № 71, рецензія 6058599118',
         num='зазори, мм: 0,1289 / 0,4923 / 0,2386 / 0,0750 / 0,2367; проходили зазори 0,403, 0,662, 0,868 (збій при 0,492)', fam='LP2-A2', cat='2',
         lim='Зв’язок «менший зазор — відмова» не монотонний; причину (голкоподібний трикутник між колами) спостережено на п’яти геометріях.',
         ver='', chk=['P-14']),
    dict(id='CL-41', sec=['sec:pr_regime', 'sec:pr_levels'], tabs=['tab:pr_regime', 'tab:pr_levels'],
         claim='Обмежений режим застосування LP2A2_MESH_QUALIFIED_RESTRICTED охоплює стани S9–S11 із зазором між колом напрямної і колом кожного кільця не менше 1,0 мм; на таких геометріях набору новий генератор пройшов 48 з 48 (число «76 з 76» меморандуму включає S6–S8; для S9–S11 — 48/48).',
         src=['docs/research/G2_LP2A2_evidence/attempt2/LP2A2_MESH_QUALIFICATION_ATTEMPT2.json: rows[state, tipToRingCircle_mm, new.seedRung]', 'docs/research/G2_LP2A2_MESH_QUALIFICATION_MEMO_UA.md'],
         acc='запит № 71, голова 05bc5f1, рецензія 6058599118',
         num='S6–S11: 76/76 (щаблі 74/2/0), S9–S11: 48/48 (46/2/0), S6–S8: 28/28; будь-який стан: 109/109 (104/4/1); старий пройшов 53, 25, 28, 54', fam='LP2-A2', cat='2',
         lim='Дві сітки на запасному щаблі; 1,0 мм — емпіричний запас; еквівалентність КІН не показана, тож режим не дозволяє фізичного продовження; числа проходження старого генератора взято з табл. 54 звіту (не перераховувалися).',
         ver='', chk=['P-08']),
    dict(id='CL-42', sec=['sec:pr_eq', 'sec:f_eq'], tabs=['tab:pr_eqtol', 'tab:f_crit'],
         claim='Еквівалентність КІН, G і кута МКН на новому сімействі сіток не показана: чотири розв’язки EQ підготовлено (контракт 24/24 без жодного розв’язку), але не виконано; фізичне продовження S9–S11 лишається в стані HOLD до проходження еквівалентності й окремого рішення.',
         src=['docs/research/G2_LP2A2_EQ_GO_DECISION_TEMPLATE.md', 'docs/research/G2_LP2A2_evidence/eq/LP2A2_EQ_TESTS.json', 'docs/research/G2_LP2A2_evidence/eq/LP2A2_HS8_RUNG_CHECK.json', 'політика LP2-A2 (дайджест d09f59b2…)'],
         acc='запит № 71, рецензія 6058599118 (п’ять пунктів закриття відкрито); REVIEW_STOP_LP2A2_EQ_READY не рецензовано; коміти після 05bc5f1 не використано',
         num='допуски C1–C11 фіксовані до розрахунків; 76 хорд на коло; контракт 24/24', fam='LP2-A2', cat='4',
         lim='Критерії — для числової еквівалентності на чотирьох геометріях, не для сертифікованої межі похибки; допуски змінювати не можна.',
         ver='не перевірялося незалежно (запит Q-07)', chk=[]),
    dict(id='CL-43', sec=['sec:c_not', 'sec:four'], tabs=['tab:c_words'],
         claim='У звіті не встановлено і не можна виводити: фізичну зупинку тріщини, зустріч з міжфазною межею, проходження чи відхилення на ній, стійкість росту, загальність щодо архітектур і навантажень, сертифіковану похибку дискретизації для всіх прийнятих станів, експериментальну валідацію траєкторій.',
         src=['рецензії 6056658077, 6054335912, 6014514118, 6013194158 (обмеження); докази відсутності: A1_ANALYSIS.json, LP2A_ANALYSIS.json (H4.status), політика LP2-A1'],
         acc='запити № 67, 69, 70, 71',
         num='найближча вершина — 24,1 мм від кола кільця 1; жодної ознаки зустрічі', fam='LP2-A1', cat='4',
         lim='Числове припинення (HOLD, межа кампанії) — межа області застосування розрахунку, не подія в матеріалі.',
         ver='межі застосовності перевірено рецензіями; відсутність доказів — за документами', chk=['N-38', 'N-39']),
    dict(id='CL-44', sec=['sec:future', 'sec:f_status'], tabs=['tab:f_map'],
         claim='Подальші напрями мають три статуси (заплановано в репозиторії; названо частково; лише пропозиція цього звіту); жодний пункт не є дозволом на розрахунок; спільна область згущення, об’єднане поле розміру і порядок «без МСЕ — потім МСЕ» — пропозиції звіту.',
         src=['docs/research/G2_LP2_CONTINUATION_MEMO_UA.md', 'docs/research/G2_LP2_FEASIBILITY_DECISION.md', 'docs/research/G2_LP2A2_MESH_QUALIFICATION_MEMO_UA.md (запис «спільної області згущення» відсутній — досьє G, Q20)'],
         acc='немає (пропозиції); запити № 70–71 лише обмежують порядок',
         num='—', fam='LP2-A2', cat='4',
         lim='Відкриті питання див. OPEN_QUESTIONS_UA.md; жодної обіцянки дозволу.',
         ver='не перевірялося незалежно', chk=[]),
]


# ------------------------------------------------------------------------------------------ figure inventory data
NEW_DIR = 'reports/G2/preliminary_20261125/figures/'
LP1_DIR = 'reports/G2/figures/a1/'
G1_DIR = 'docs/research/G2_G1_evidence/'
A2_DIR = 'docs/research/G2_LP2A2_evidence/figures/'
COMMON_STYLE = 'підписи українською, Times New Roman 9 пт; десяткова кома і справжній мінус (допоміжна функція dec); одна відповідність «конфігурація — колір — лінія — маркер» у всьому звіті: H чорна суцільна з кружками, stiff13 червоно-брунатна штрихова з трикутниками, soft2 синя штрихпунктирна з квадратами, soft1 зелена пунктирна з ромбами'

FIGS = [
    dict(key='fig:geom', file=NEW_DIR + 'F02_geometriia_zadachi', new=True,
         shows='Ідеалізована модельна задача: пластина 508 × 203,2 мм, гирло і початкова тріщина, три отвори з кільцями 1–3, опори, сила, розміри.',
         data='константи політик розрахунку (G2_TRAJECTORY_POLICY_v1.json, G2_MATERIAL_POLICY_v1.json), задані у g2_prelim_fig_common.m; жодних розрахункових даних',
         script='scripts/report/g2_prelim/g2_prelim_figures_a.m (розділ «geometry of the model problem»)',
         lang=COMMON_STYLE + '; кільця — світло-сірі', flags='схема (геометричне креслення), однаковий масштаб осей; без траєкторій і без збільшення'),
    dict(key='fig:configs', file=NEW_DIR + 'F05_chotyry_arkhitektury', new=True,
         shows='Чотири конфігурації: активні кільця (жорсткі — червонувате, м’які — блакитне заливання), пасивні контури, розрахункові траєкторії до S8.',
         data='docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: states.‹конфігурація›.tip, H4.terminals[].ringMask',
         script='scripts/report/g2_prelim/g2_prelim_figures_a.m (розділ «four architectures»)',
         lang=COMMON_STYLE, flags='траєкторії в масштабі пластини (на ньому не розрізняються); без збільшення; кандидатів S9 немає'),
    dict(key='fig:tipzones', file=NEW_DIR + 'F03_zony_bilia_vershyny', new=True,
         shows='Зони біля вершини: локальний базис, ядро 3,0 мм, комір 3,3 мм, область інтегрування 0,4–2,6 мм, вікно COD 0,1–1,5 мм, напрямна область 15 мм; дві панелі (± 18 мм і збільшення ± 3,6 мм).',
         data='сталі протоколу біля вершини (g2_prelim_fig_common.m: rCore, rCollar, rGuide; політики LP2-A1); розрахункових даних немає',
         script='scripts/report/g2_prelim/g2_prelim_figures_b.m (розділ «F03: near-tip zones»)',
         lang=COMMON_STYLE, flags='схема в масштабі (true scale) за сталими коду; права панель — збільшення'),
    dict(key='fig:a1mesh', file=LP1_DIR + 'A1_F1_tip_mesh_levels_UA', new=False,
         shows='Сітка біля вершини для H у S4 на рівнях подрібнення m = 0, 3, 6, 9 в однаковому масштабі ± 0,6 мм.',
         data='розв’язки родини B кампанії A1 (A1_ANALYSIS.json: records.H[m]); сіткові масиви у локальному архіві, що не комітований',
         script='scripts/report/g2_a1_report_figures.m',
         lang='підписи українською, десяткова кома на осях, мінус на осях — дефіс (як у джерелі); панелі позначено латинськими (a), (b); чорно-біле', flags='збільшення ± 0,6 мм (однакове на всіх панелях); прийнятий рисунок додатку A1 без змін'),
    dict(key='fig:a1fg', file=LP1_DIR + 'A1_F5_FG_robustness_UA', new=False,
         shows='(а) F_G трьох архітектур на рівнях m = 0, 3, 6, 9 (стовпці практично однакові); (б) F_G(m) − F_G(0) у абсолютних одиницях ×10⁻⁶ проти h1.',
         data='matlab/g2/evidence/a1_campaign_20261122/campaign/A1_ANALYSIS.json: F_G, F_G_B9minusB0',
         script='scripts/report/g2_a1_report_figures.m',
         lang='підписи українською, кома, дефіс замість мінуса на осях, латинські (a), (b), сіра гама', flags='панель (б) — різниці у масштабі ×10⁻⁶ (збільшення); прийнятий рисунок A1 без змін'),
    dict(key='fig:GFG', file=NEW_DIR + 'F08_3_G_FG', new=True,
         shows='(а) абсолютна G на власних траєкторіях за P = 1 Н; (б) відносний контраст F_G; вертикальна пунктирна лінія — межа LP1/A0 (S0–S4) і LP2-A1 (S5–S8).',
         data='docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: states.‹конфігурація›.G, ‹конфігурація›.F_G',
         script='scripts/report/g2_prelim/g2_prelim_figures_a.m (розділ «absolute G and own-path contrast»)',
         lang=COMMON_STYLE, flags='геометричних прогнозів немає; без збільшення'),
    dict(key='fig:m4bbars', file=NEW_DIR + 'F06_1_vnesky_kilets', new=True,
         shows='Внески окремих кілець на замороженій тріщині S2: (а) F_G, (б) F_θ; блакитні стовпці — м’яке кільце, червонуваті — жорстке; праворуч усі три кільця разом.',
         data='matlab/g2/evidence/m4b_20261121/analysis/cases_16_logical.csv: F_G, F_theta_deg',
         script='scripts/report/g2_prelim/g2_prelim_figures_b.m (розділ «F06_1: single rings, M4B»)',
         lang='Times New Roman 9 пт, десяткова кома, справжній мінус; м’які — блакитний, жорсткі — червонуватий (кольори заливання кілець)', flags='стовпці на замороженій геометрії S2, не траєкторії; значення над стовпцями з двома знаками (−1,82 для кільця 3)'),
    dict(key='fig:g1dirs', file=G1_DIR + 'G1_1_napriamy_stysku_UA', new=False,
         shows='Осі стискального головного напруження в однорідній пластині в S2 (чорні/сірі позначки за переважанням) і шість траєкторій головних напружень.',
         data='docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json (трасування за збереженими переміщеннями; 0 нових крайових задач)',
         script='scripts/g2/m5/g1/g1_figures.m; docs/research/G2_G1_evidence/run_fig.m',
         lang='підписи українською (Arial), десяткова кома на осях, панелі кирилицею; сіра гама', flags='поле напружень, не траєкторії тріщини; прийнятий рисунок G1 без змін; два відрізки «near_load» можна прочитати як шлях від сили до тріщини (досьє E, Q14)'),
    dict(key='fig:g1energy', file=NEW_DIR + 'F06_2_enerhii_kilets', new=True,
         shows='(а) Відносна зміна енергії деформації в областях кілець і повної енергії однорідної пластини вздовж траєкторії H; (б) спостережений ефект проти оцінки першого порядку (12 + 9 порівнянь), штрихова лінія — рівність.',
         data='docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json: homogeneousPath.{U_total, U_ring}, firstOrderSingleRing, firstOrderArchitecture',
         script='scripts/report/g2_prelim/g2_prelim_figures_b.m (розділ «F06_2: ring energies and first-order estimates»)',
         lang='Times New Roman 9 пт, десяткова кома, справжній мінус; м’які — блакитний, жорсткі — червонуватий', flags='замінює G1-2, G1-3 і G1-5 (консолідація); 21 порівняння не є незалежними випробуваннями'),
    dict(key='fig:g1map', file=G1_DIR + 'G1_4_karta_vplyvu_UA', new=False,
         shows='Карта густини впливу ι у S2: сині області — податливіший матеріал зменшує G (перше наближення), червоні — збільшує.',
         data='docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json: influenceMap, influenceMapProfiles',
         script='scripts/g2/m5/g1/g1_figures.m; docs/research/G2_G1_evidence/run_fig.m',
         lang='підписи українською; поділки колірної шкали з десятковою крапкою (зазначено в підписі); кольорова карта', flags='поле, не траєкторія; прийнятий рисунок G1 без змін'),
    dict(key='fig:x6bars', file=NEW_DIR + 'F07_1_rozklad_S4', new=True,
         shows='Розклад ефекту в S4: (а) контраст G — F_m, F_p, F_i і сума; (б) те саме для локального кута МКН; різні масштаби панелей.',
         data='docs/research/G2_M5_X6_evidence/campaign_20261125/M5X6_ANALYSIS.json: ‹конфігурація›.G.{F_mat,F_path,F_int,F_tot}, MTS_deg.*',
         script='scripts/report/g2_prelim/g2_prelim_figures_b.m (розділ «F07_1: decomposition at S4»)',
         lang=COMMON_STYLE.split(';')[0] + '; кольори стовпців — за внеском (матеріал, траєкторія, взаємодія, сума)', flags='лише S4 і рівень B9; панелі в різних масштабах (зазначено в підписі); без геометричних прогнозів'),
    dict(key='fig:p_traj', file=NEW_DIR + 'F08_1_traiektorii', new=True,
         shows='Траєкторії S0–S8: (а) H на тлі пластини; (б) усі чотири в справжньому масштабі, відкриті маркери — геометричний прогноз S9; (в) відхилення від H, збільшені в 20 разів.',
         data='docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: states.‹конфігурація›.tip; states.‹конфігурація›.terminal.candidate.polyline_mm',
         script='scripts/report/g2_prelim/g2_prelim_figures_a.m (розділ «crack paths»)',
         lang=COMMON_STYLE, flags='панель (в) — збільшення ×20 (x_H + 20(x_X − x_H), осі умовні); кандидати S9 лише геометричні (відкриті маркери, не прийняті стани); (а) схематичного масштабу пластини'),
    dict(key='fig:p_kk', file=NEW_DIR + 'F08_2_KI_KII', new=True,
         shows='Знакові КІН вздовж траєкторій (P = 1 Н): (а) K_I; (б) K_II для S1–S8; (в) змішаність K_II/K_I для S1–S8; стан S0 поза шкалою.',
         data='docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: states.‹конфігурація›.{KI, KII}',
         script='scripts/report/g2_prelim/g2_prelim_figures_a.m (розділ «signed SIFs and mode mixity»)',
         lang=COMMON_STYLE, flags='геометричних прогнозів немає; S0 поза шкалою (зазначено в підписі)'),
    dict(key='fig:p_dir', file=NEW_DIR + 'F08_4_kurs_i_zmishchennia', new=True,
         shows='Напрямок: (а) θ_n (S0 поза шкалою); (б) Δθ_n; (в) відносний курс Δφ_n з відкритими маркерами геометричного прогнозу S9; (г) бічне зміщення d.',
         data='docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json: ‹конфігурація›.{dMTS_deg, dHeading_deg, d_mm}, states.‹конфігурація›.MTS',
         script='scripts/report/g2_prelim/g2_prelim_figures_a.m (розділ «local MTS increments, relative heading, lateral offset»)',
         lang=COMMON_STYLE, flags='прогноз S9 (панель в) — геометричний предиктор Δφ_9 = Δφ_8 + Δθ_8, не розв’язок; різниці в градусах, збільшень немає'),
    dict(key='fig:pr_f1', file=NEW_DIR + 'F09_vidmova_parovannia', new=True,
         shows='Відмова парування успадкованого генератора на геометричному прогнозі S9 для soft2: (а) кількість внутрішніх вузлів на відрізках осьової лінії, верхній і нижній береги; (б) відрізок 2 — 7 внутрішніх вузлів проти 8 (схема з рівномірними станціями).',
         data='числа меморандуму G2_LP2A2_MESH_QUALIFICATION_MEMO_UA.md (розділ 2): верхній берег [50 7 8 8 8 8 8 8 8 1], нижній [50 8 8 8 8 8 8 8 8 1]; файли доказів не читалися',
         script='scripts/report/g2_prelim/g2_prelim_figures_c.m',
         lang=COMMON_STYLE + '; кольори берегів червоний/синій близькі до кольорів stiff13/soft2, але конфігурацій не позначають', flags='лише геометрія, жодного розв’язку; панель (б) — схема, не координати з розрахунку; перемальовано, бо в прийнятому рисунку LP2A2-1 обрізано заголовок панелі (а) і крапка як десятковий роздільник'),
    dict(key='fig:pr_f2', file=A2_DIR + 'LP2A2_2_stantsii_UA', new=False,
         shows='Нова побудова на прогнозі S9 для soft2: (а) однакова кількість зерен на обох берегах кожного відрізка; (б) пари за індексом зерна на відрізку 7, помаранчева — вимушена пара.',
         data='docs/research/G2_LP2A2_evidence/ (побудова сітки у пам’яті)', script='scripts/g2/lp2a2/lp2a2_figures.m',
         lang='підписи українською; десятковий роздільник — крапка', flags='лише геометрія; прогноз S9; прийнятий без змін'),
    dict(key='fig:pr_f3', file=A2_DIR + 'LP2A2_3_pislia_kolapsu_UA', new=False,
         shows='Сітка після згортання біля зламу 3 (прогноз S9, soft2): (а) загальний вигляд; (б) збільшення — кожна пара є двома різними вузлами в одній точці.',
         data='docs/research/G2_LP2A2_evidence/ (побудова сітки у пам’яті)', script='scripts/g2/lp2a2/lp2a2_figures.m',
         lang='підписи українською; десятковий роздільник — крапка', flags='лише геометрія; збільшення на панелі (б); прийнятий без змін'),
    dict(key='fig:pr_f7', file=A2_DIR + 'LP2A2_7_vymushena_para_UA', new=False,
         shows='Вимушена пара: (а) перетин кола 15-мм напрямної з берегами ±w у локальних координатах (мкм) для прогнозу S9 soft2; (б) після згортання — два вузли в одній точці.',
         data='docs/research/G2_LP2A2_evidence/supplement/LP2A2_SUPPLEMENT.json: forcedPairs', script='scripts/g2/lp2a2/lp2a2_figures.m',
         lang='підписи українською; десятковий роздільник — крапка', flags='масштаб мікрометрів (сильне збільшення); лише геометрія; прогноз S9; прийнятий без змін'),
    dict(key='fig:pr_f8', file=A2_DIR + 'LP2A2_8_zalyshkovi_vidmovy_UA', new=False,
         shows='Залишкові відмови: (а) голкоподібний трикутник між колом напрямної і колом кільця 1 (soft2, S12); (б) нерівномірні хорди кільця 2 (soft1, S20); (в) відмова відношення сусідів на щаблі 1 (stiff13, S10), яку знімає щабель 2.',
         data='docs/research/G2_LP2A2_evidence/attempt2/LP2A2_MESH_QUALIFICATION_ATTEMPT2.json; supplement/LP2A2_RECONCILIATION.json: remainingFailures', script='scripts/g2/lp2a2/lp2a2_figures.m',
         lang='підписи українською; десятковий роздільник — крапка у заголовках і на осях', flags='збільшення локальних фрагментів; лише геометрія; синтетичні геометрії; прийнятий без змін'),
]

NOT_USED = [
    ('docs/research/G2_LP2_evidence/campaign_20261125/LP2A_4_vidstani_UA.png (+ .pdf)', 'накладання анотацій на рисунку; відстані подано таблицями 38 і 39 (відстань до кола кільця 1, завершальні записи S8, кандидат S9).'),
    ('docs/research/G2_LP2A2_evidence/figures/LP2A2_5_povni_sitky_UA.png (+ .pdf)', 'підпис не відповідає змісту рисунка (за досьє G: повні сітки з H S8, прогнозом soft2 S9 і збільшеннями біля кілець); повні сітки для висновків звіту не потрібні.'),
    ('docs/research/G2_LP2A2_evidence/figures/LP2A2_6_kvalifikatsiia_UA.png (+ .pdf)', 'у панелі (б) заголовок накладається на показник степеня ×10⁴ осі; замість рисунка використано таблиці 47–51 (склад набору, знаменники, стани, показники сіток).'),
    ('docs/research/G2_LP2A2_evidence/figures/LP2A2_4_komir_UA.png (+ .pdf)', 'ядро p010 і комір показано схемою на рисунку 3; окремо рисунок у звіті не потрібен (відбір причин не зафіксовано письмово — припущення упорядника).'),
    ('docs/research/G2_G1_evidence/G1_2_gustyna_energii_UA, G1_3_pererozpodil_energii_UA, G1_5_energii_kilets_UA', 'консолідовано в рис. F06_2 (енергії областей кілець і оцінка першого порядку); рисунки G1-2 і G1-3 у досьє описано лише за кодом генерації, візуально не переглядалися.'),
    ('docs/research/G2_M5_evidence/M5_1_geometriia_UA, M5_2_FG_priamyi_i_povnyi_UA, M5_3_podatlyvist_UA', 'консолідовано в рис. F06_1, F06_2, F07_1 і F08_x; анотація «S4: direct effect not computed» на M5-2 застаріла після кампанії M5-X6; позначки панелей латинські (a), (b), тоді як у G1 — кириличні.'),
    ('reports/G2/figures/a1/A1_F2_preservation_UA, A1_F3_cost_UA, A1_F4_sif_changes_UA, A1_F6_numerical_indicators_UA', 'консолідовано: підсумок A1 подано таблицями 10–12 і двома рисунками (A1-F1, A1-F5); F2 (збереження ядра), F3 (вартість), F4 (зміни КІН), F6 (показники якості) не додають висновків, яких немає в таблицях.'),
    ('docs/research/G2_LP2_evidence/campaign_20261125/LP2A_1_traiektorii_UA, LP2A_2_G_UA, LP2A_3_vidkhylennia_UA; docs/research/G2_LP2_evidence/LP2_1_S4_S5_UA, LP2_2_sitka_UA', 'замінено консолідованими рисунками 12–14 для всіх станів S0–S8: на LP2A-1(а) прогноз S9 пунктиром у кольорі випадку (той самий стиль, що в stiff13), на LP2-1(а) є непідписана штрихова лінія (досьє G, Q19).'),
    ('reports/G2/LP1_20261122_v3/LP1_*_UA.png', 'охоплюють лише S0–S4; замінено рисунками S0–S8 (F08_x).'),
    ('десять рисунків 1.1–Г.1 Word-редакцій v0.1–v0.3', 'немає ні реєстру рисунків, ні вказівки на дані в репозиторії (досьє D, Q17); не використано.'),
]


# ------------------------------------------------------------------------------------------ document writers
def _ids(ids):
    if len(ids) <= 3:
        return ', '.join(ids)
    return '%s…%s (%d)' % (ids[0], ids[-1], len(ids))


def _ver_text(c, res):
    ids = c['chk']
    parts = []
    if ids:
        sts = {i: res[i]['status'] for i in ids if i in res}
        fails = [i for i, s in sts.items() if s == 'FAIL']
        okc = sum(1 for s in sts.values() if s in ('PASS', 'REJECTED'))
        if fails:
            parts.append('перераховано check_report_numbers.py: %d з %d рядків PASS; ВІДХИЛЕННЯ тексту звіту в %s (див. NUMBERS_CHECK.json і VERIFICATION_RECORD_UA.md, п. (d)–(f))' % (okc, len(sts), _ids(fails)))
        else:
            parts.append('перераховано check_report_numbers.py — PASS (%d з %d рядків: %s)' % (okc, len(sts), _ids(ids)))
    if c['ver']:
        parts.append(c['ver'])
    return '; '.join(parts) if parts else 'не перевірялося незалежно'


def write_ledger(path, num, ck, outname):
    res = {r['id']: r for r in ck.rows}
    c = summarize(ck)
    L = []
    w = L.append
    w('# Реєстр тверджень і доказів проміжного наукового звіту G2 (25.11.2026)')
    w('')
    w('Статус: `REVIEW_STOP_G2_PRELIMINARY_REPORT` — чернетка для наукової перевірки; не злито.')
    w('Звіт: `Metakompozyt_G2_Preliminary_Report_20261125_UA.docx` (+ `.pdf`). Рецензований знімок: `05bc5f1` (запит № 71); базова прийнята ревізія LP2-A1: `ed5c6e6` (запит № 70).')
    w('Цей файл згенеровано скриптом `scripts/report/g2_prelim/check_report_numbers.py --ledger` (нумерація розділів, таблиць і рисунків — з %s); при зміні нумерації звіту скрипт слід повторно запустити.' % num.src)
    w('')
    w('## Як читати реєстр')
    w('')
    w('- **Категорії доказовості** (ті самі, що в розд. %s звіту):' % num.secn('sec:c_table'))
    for k in '1234':
        w('  - %s — %s;' % (k, CAT[k]))
    w('- **Родини чисел** не змішуються. Кожне твердження вказує, до якої родини належать його числа:')
    for k, v in FAMILIES:
        w('  - **%s** — %s.' % (k, v))
    w('- Графа «Прийнято» вказує запит (PR) у репозиторії `mfs9697/NewMetacomp`, його голову (коміт), номер рецензії (`R`) або коментаря (`к.`). Усі 43 запити № 8–71 — відкриті чернетки; «прийнято» означає розпорядження дослідника в тексті завдань і рецензій, а не злиття. Усі рецензії і коментарі опубліковано одним обліковим записом; «незалежність» визначається змістом (див. додаток А звіту, А.1). Етапи WP0–M3 власної рецензії не мають.')
    w('- Графа «Незалежна перевірка» містить результат **перерахунку з комітованих доказів** скриптом `check_report_numbers.py` (рядки `N-…`, `A-…`, `M-…`, `X-…`, `K-…`, `G-…`, `P-…` у `NUMBERS_CHECK.json`) і/або вказівку на рецензію. Рецензії перевіряли закомічені докази; вони не запускали MATLAB, не відкривали сирі архіви поза пристроєм і не переглядали бінарні рисунки. Ні скрипт, ні рецензії не є експериментальною валідацією.')
    w('- Підсумок скрипта: PASS %d, FAIL %d, негативні контролі відхилено %d (усього %d рядків). Обидва FAIL — неточності тексту звіту (розд. %s), а не скрипта; вони описані в `VERIFICATION_RECORD_UA.md`.' % (c['PASS'], c['FAIL'], c['REJECTED'], len(ck.rows), num.secn('sec:m4b')))
    w('')
    cnt = {}
    for cl in CLAIMS:
        k = cl['cat'][0]
        cnt[k] = cnt.get(k, 0) + 1
    w('Усього тверджень: **%d** (категорія 1 — %d; 2 — %d; 3 — %d; 4 — %d).' % (len(CLAIMS), cnt.get('1', 0), cnt.get('2', 0), cnt.get('3', 0), cnt.get('4', 0)))
    w('')
    w('## Реєстр')
    w('')
    w('| ID | Розділ звіту | Твердження | Джерело (шлях; ключ JSON / стовпець CSV / рядок) | Прийнято (запит, коміт, рецензія) | Числові докази | Кат. | Обмеження | Незалежна перевірка |')
    w('|---|---|---|---|---|---|---|---|---|')
    for cl in CLAIMS:
        secs = '; '.join(num.sec(k) for k in cl['sec'])
        extra = []
        if cl.get('tabs'):
            extra.append(', '.join(num.tab(k) for k in cl['tabs']))
        if cl.get('figs'):
            extra.append(', '.join(num.fig(k) for k in cl['figs']))
        if extra:
            secs += '<br>(' + '; '.join(extra) + ')'
        src = '<br>'.join(re.sub(r'((?:docs|matlab|reports|scripts)/[^\s,;():«»]+)', r'`\1`', t) for t in cl['src'])
        row = [cl['id'], secs, cl['claim'], src, cl['acc'], cl['num'] + '<br>[родина: %s]' % cl['fam'], cl['cat'], cl['lim'], _ver_text(cl, res)]
        w('| ' + ' | '.join(esc(x) for x in row) + ' |')
    w('')
    w('## Примітки')
    w('')
    w('1. Твердження категорії 4 включають і твердження про **відсутність** доказу (валідація, зустріч з межею, зупинка): вони позначають межу застосовності, а не обчислений результат.')
    w('2. Числа, які неможливо перерахувати з комітованих JSON, CSV чи журналу (результати WP2 за журналами, показник |J/G − 1| для S5–S8, COD-оцінки K для S0–S4 у даних LP2), у реєстрі так і позначено; вони взяті з документів досьє.')
    w('3. Історичні записи (M5-меморандум, G1-документ, звіт LP2-A1, меморандум LP2-A2) у репозиторії не змінювалися; виправлення внесено лише у зведений звіт (додаток А, К-14, К-17…К-22).')
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(L) + '\n')


def write_figures(path, num, repo):
    L = []
    w = L.append
    w('# Реєстр рисунків проміжного наукового звіту G2 (25.11.2026)')
    w('')
    w('Статус: `REVIEW_STOP_G2_PRELIMINARY_REPORT` — чернетка для наукової перевірки; не злито. Номери рисунків — з %s (генерується скриптом `check_report_numbers.py --ledger`).' % num.src)
    w('')
    nnew = sum(1 for f in FIGS if f['new'])
    w('У звіті **%d** рисунків: **%d нових** (скрипти `g2_prelim_figures_a.m`, `g2_prelim_figures_b.m` зі спільним `g2_prelim_fig_common.m`; лише побудова за комітованими доказами, без МСЕ, без MAT-файлів) і **%d прийнятих рисунків, відтворених без змін** (з кампаній A1, G1 і LP2-A2). Усі нові рисунки існують у двох форматах (PNG 300 dpi і векторний PDF) у `reports/G2/preliminary_20261125/figures/`; Word-звіт вставляє PNG. Рисунки у вузьких PDF обрізано щільно (запит Q-25).' % (len(FIGS), nnew, len(FIGS) - nnew))
    w('')
    w('## Використані рисунки')
    w('')
    w('| № | Ключ | Файл (без розширення; є .png і .pdf) | Що показано | Джерело даних | Скрипт | Новий / прийнятий | Мова, колір, позначення | Збільшення / схема / геометричний прогноз |')
    w('|---|---|---|---|---|---|---|---|---|')
    for f in sorted(FIGS, key=lambda g: int(num.n.get(g['key'], '999'))):
        exists = all(os.path.exists(os.path.join(repo, f['file'] + e)) for e in ('.png', '.pdf'))
        status = ('новий' if f['new'] else 'прийнятий, без змін') + ('' if exists else ' [ФАЙЛ НЕ ЗНАЙДЕНО]')
        row = [num.fig(f['key']).replace('рис. ', ''), '`%s`' % f['key'], '`%s`' % f['file'], f['shows'], f['data'], '`%s`' % f['script'].split(' ')[0] + ' ' + ' '.join(f['script'].split(' ')[1:]), status, f['lang'], f['flags']]
        w('| ' + ' | '.join(esc(x) for x in row) + ' |')
    w('')
    w('## Існуючі прийняті рисунки, які свідомо не використано')
    w('')
    w('| Файл | Чому не використано |')
    w('|---|---|')
    for a, b in NOT_USED:
        w('| `%s` | %s |' % (esc(a), esc(b)))
    w('')
    w('## Спостереження щодо узгодженості рисунків')
    w('')
    w('- Десятковий роздільник: у нових рисунках, A1 і G1 — кома; у рисунках LP2-A2 (рис. %s–%s, %s, %s) і на колірній шкалі рис. %s — крапка (відтворено без змін; про це сказано в підписах).' % (
        num.n.get('fig:pr_f1', '?'), num.n.get('fig:pr_f3', '?'), num.n.get('fig:pr_f7', '?'), num.n.get('fig:pr_f8', '?'), num.n.get('fig:g1map', '?')))
    w('- Позначки панелей: нові рисунки — кирилиця (а), (б), (в); A1 — латиниця (a), (b); G1 і LP2-A2 — кирилиця.')
    w('- Мінус на осях A1 — дефіс, у нових рисунках — справжній мінус.')
    w('- Кольори берегів і кільця на рисунках LP2-A2 (червоний, синій, зелений) близькі до кольорів stiff13, soft2, soft1; на цих рисунках кольори не позначають конфігурації (запит Q-26).')
    w('- Візуальну перевірку PNG/PDF рисунків рецензії не виконували; нові рисунки переглянуто лише в процесі побудови звіту (розділ «Візуальна перевірка сторінок» у `VERIFICATION_RECORD_UA.md`).')
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(L) + '\n')


def write_documents(repo, out, numbering_path, ck, text=None):
    if numbering_path is None:
        cand = os.path.join(out, 'NUMBERING_MAP.json')
        numbering_path = cand if os.path.exists(cand) else None
    num = Num(numbering_path, toc_titles(text))
    write_ledger(os.path.join(out, 'CLAIM_EVIDENCE_LEDGER_UA.md'), num, ck, 'CLAIM_EVIDENCE_LEDGER_UA.md')
    write_figures(os.path.join(out, 'FIGURE_INVENTORY_UA.md'), num, repo)
    print('записано CLAIM_EVIDENCE_LEDGER_UA.md (%d тверджень) і FIGURE_INVENTORY_UA.md (%d рисунків); нумерація: %s' % (len(CLAIMS), len(FIGS), num.src))



# ------------------------------------------------------------------------------------------ driver
def summarize(ck):
    c = {'PASS': 0, 'FAIL': 0, 'REJECTED': 0}
    for r in ck.rows:
        c[r['status']] += 1
    return c


def print_table(ck):
    w = sys.stdout.write
    w('%-5s %-18s %-9s %s\n' % ('ID', 'Родина', 'Результат', 'Перевірка | обчислено | заявлено'))
    for r in ck.rows:
        d = r['desc'] if len(r['desc']) <= 110 else r['desc'][:107] + '...'
        extra = ''
        if r['textFound'] is False:
            extra = '  [рядок не знайдено в тексті звіту]'
        w('%-5s %-18s %-9s %s | %s | %s%s\n' % (r['id'], r['family'], r['status'], d, r['computed'], r['stated'], extra))
        for b in r.get('bad', [])[:6]:
            w('        ! %s\n' % b)
    c = summarize(ck)
    w('\nПІДСУМОК: PASS %d, FAIL %d, негативні контролі відхилено (REJECTED) %d, усього %d рядків\n' % (c['PASS'], c['FAIL'], c['REJECTED'], len(ck.rows)))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--repo', default=DEFAULT_REPO)
    ap.add_argument('--docx', default=None, help='built report (.docx): stated strings are looked up in its text')
    ap.add_argument('--numbering', default=None, help='numbering map written by build_report.py --ledger')
    ap.add_argument('--out', default=None, help='output folder (default: <repo>/reports/G2/preliminary_20261125)')
    ap.add_argument('--ledger', action='store_true', help='also (re)generate CLAIM_EVIDENCE_LEDGER_UA.md and FIGURE_INVENTORY_UA.md')
    a = ap.parse_args(argv)
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass
    repo = os.path.abspath(a.repo)
    out = a.out or os.path.join(repo, OUT_REL)
    text = None
    if a.docx and os.path.exists(a.docx):
        text = docx_text(a.docx)
    ev = Ev(repo)
    ck = Checker(text)
    run_checks(ev, ck)
    print_table(ck)
    c = summarize(ck)
    meta = {
        'schema': 'NewMetacomp.G2.PrelimReport.NumbersCheck.v1',
        'script': 'scripts/report/g2_prelim/check_report_numbers.py',
        'reviewedSnapshot': '05bc5f1',
        'E_matrix_MPa': E_M,
        'tolerance': 'half a unit of the last printed digit; bounds: the printed bound; negative controls must be rejected',
        'docxProbed': os.path.basename(a.docx) if text is not None else None,
        'counts': {'PASS': c['PASS'], 'FAIL': c['FAIL'], 'REJECTED_NEGATIVE_CONTROLS': c['REJECTED'], 'total': len(ck.rows)},
        'statedStringsNotFoundInText': [r['id'] for r in ck.rows if r['textFound'] is False],
        'evidenceFiles': ev.used,
        'checks': [{k: v for k, v in r.items() if k not in ('ok',)} for r in ck.rows],
    }
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, 'NUMBERS_CHECK.json'), 'w', encoding='utf-8') as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    print('записано', os.path.join(out, 'NUMBERS_CHECK.json'))
    if a.ledger:
        write_documents(repo, out, a.numbering, ck, text)
    return 1 if c['FAIL'] else 0



if __name__ == '__main__':
    sys.exit(main())
