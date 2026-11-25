# -*- coding: utf-8 -*-
"""Shared notation, number formatting, bibliography and evidence loading for the G2 preliminary report.

Every number that appears in a generated table is read here from committed evidence files of the
reviewed snapshot; nothing is recomputed by FEM. Bibliographic records were checked against the
Crossref registry on 25.11.2026 (see reports/G2/preliminary_20261125/VERIFICATION_RECORD_UA.md).
"""
import json
import os

# ---------------------------------------------------------------------------- math macros (LaTeX subset)
MACROS = {
    r'\KI': r'K_{\mathrm{I}}', r'\KII': r'K_{\mathrm{II}}', r'\FG': r'F_{G}',
    r'\Fm': r'F_{\mathrm{m}}', r'\Fp': r'F_{\mathrm{p}}', r'\Fi': r'F_{\mathrm{i}}',
    r'\Em': r'E_{\mathrm{м}}', r'\Ek': r'E_{\mathrm{к}}', r'\GH': r'G_{\mathrm{H}}', r'\GX': r'G_{X}',
    r'\Ro': r'R_{\mathrm{о}}', r'\Rk': r'R_{\mathrm{к}}', r'\dd': r'\mathrm{d}',
    r'\tv': r'\mathbf{t}', r'\nv': r'\mathbf{n}', r'\xv': r'\mathbf{x}', r'\uv': r'\mathbf{u}',
    r'\aux': r'\mathrm{aux}', r'\mm': r'\text{ мм}',
}

CASES = ['H', 'stiff13', 'soft2', 'soft1']
ARCH = ['stiff13', 'soft2', 'soft1']


# ---------------------------------------------------------------------------- number formatting
def c(x, nd=3):
    """decimal comma, true minus"""
    s = f"{x:.{nd}f}"
    if float(s) == 0:
        s = s.replace('-', '')
    return s.replace('-', '−').replace('.', ',')


def sg(x, nd=3):
    """signed, decimal comma, true minus"""
    s = f"{x:+.{nd}f}"
    if float(s) == 0:
        s = s.replace('-', '').replace('+', '')
    return s.replace('-', '−').replace('.', ',')


SUP = str.maketrans('-0123456789', '⁻⁰¹²³⁴⁵⁶⁷⁸⁹')


def sci(x, nd=2, signed=False):
    if x == 0:
        return '0'
    s = f"{x:+.{nd}e}" if signed else f"{x:.{nd}e}"
    m, e = s.split('e')
    return m.replace('-', '−').replace('.', ',') + '·10' + str(int(e)).translate(SUP)


def pct(x, nd=2, signed=True):
    return (sg(100 * x, nd) if signed else c(100 * x, nd))


def thou(n):
    return f"{int(n):,}".replace(',', ' ')


# ---------------------------------------------------------------------------- evidence
class Evidence:
    """Committed evidence of the reviewed snapshot (read-only)."""

    def __init__(self, repo):
        self.repo = repo
        dr = os.path.join(repo, 'docs', 'research')
        self.paths = {
            'LP2A': os.path.join(dr, 'G2_LP2_evidence', 'campaign_20261125', 'LP2A_ANALYSIS.json'),
            'LP2A_CALLS': os.path.join(dr, 'G2_LP2_evidence', 'campaign_20261125', 'LP2A_CALLS.json'),
            'X6': os.path.join(dr, 'G2_M5_X6_evidence', 'campaign_20261125', 'M5X6_ANALYSIS.json'),
            'X6_DIAG': os.path.join(dr, 'G2_M5_X6_evidence', 'M5X6_DIAGONAL_AUDIT.json'),
            'G1': os.path.join(dr, 'G2_G1_evidence', 'G1_FIELD_EVIDENCE.json'),
            'M5': os.path.join(dr, 'G2_M5_evidence', 'M5_EXISTING_EVIDENCE.json'),
            'A1': os.path.join(repo, 'matlab', 'g2', 'evidence', 'a1_campaign_20261122', 'campaign', 'A1_ANALYSIS.json'),
        }
        ev = os.path.join(repo, 'matlab', 'g2', 'evidence')
        self.csv_paths = {
            'M4B_CASES': os.path.join(ev, 'm4b_20261121', 'analysis', 'cases_16_logical.csv'),
            'M4B_DEC': os.path.join(ev, 'm4b_20261121', 'analysis', 'decomposition.csv'),
            'R1': os.path.join(ev, 'm4b_r1_20261121', 'analysis', 'r1_crossfamily.csv'),
            'M2': os.path.join(ev, 'm2_20261121', 'report', 'm2_results.csv'),
            'M3': os.path.join(ev, 'm3_20261121', 'analysis', 'm3_decomposition.csv'),
        }
        self.data = {}

    def __getitem__(self, key):
        if key not in self.data:
            with open(self.paths[key], encoding='utf-8-sig') as f:
                self.data[key] = json.load(f)
        return self.data[key]

    def csv(self, key):
        import csv
        k = 'csv:' + key
        if k not in self.data:
            with open(self.csv_paths[key], encoding='utf-8-sig', newline='') as f:
                self.data[k] = list(csv.DictReader(f))
        return self.data[k]

    def rel(self, key):
        return os.path.relpath(self.paths[key], self.repo).replace('\\', '/')


# ---------------------------------------------------------------------------- bibliography (verified records)
# Format: authors. title. source. year. volume, issue. pages. DOI.   (*...* = italic)
BIB = {
    'ingraffea1990': 'Ingraffea A. R., Grigoriu M. Probabilistic Fracture Mechanics: A Validation of Predictive Capability. '
                     'Report 90-8. Ithaca, NY: Department of Structural Engineering, Cornell University, 1990. '
                     '(DTIC ADA228877). Доступний авторам лише в розпізнаній текстовій копії; оригінальні скани рисунків не перевірялися.',
    'bittencourt1996': 'Bittencourt T. N., Wawrzynek P. A., Ingraffea A. R., Sousa J. L. Quasi-automatic simulation of crack '
                       'propagation for 2D LEFM problems. *Engineering Fracture Mechanics*. 1996. Vol. 55, No. 2. P. 321–334. '
                       'DOI: 10.1016/0013-7944(95)00247-2.',
    'erdogan1963': 'Erdogan F., Sih G. C. On the crack extension in plates under plane loading and transverse shear. '
                   '*Journal of Basic Engineering*. 1963. Vol. 85, No. 4. P. 519–525. DOI: 10.1115/1.3656897.',
    'williams1957': 'Williams M. L. On the stress distribution at the base of a stationary crack. '
                    '*Journal of Applied Mechanics*. 1957. Vol. 24, No. 1. P. 109–114. DOI: 10.1115/1.4011454.',
    'irwin1957': 'Irwin G. R. Analysis of stresses and strains near the end of a crack traversing a plate. '
                 '*Journal of Applied Mechanics*. 1957. Vol. 24, No. 3. P. 361–364. DOI: 10.1115/1.4011547.',
    'rice1968': 'Rice J. R. A path independent integral and the approximate analysis of strain concentration by notches and cracks. '
                '*Journal of Applied Mechanics*. 1968. Vol. 35, No. 2. P. 379–386. DOI: 10.1115/1.3601206.',
    'yau1980': 'Yau J. F., Wang S. S., Corten H. T. A mixed-mode crack analysis of isotropic solids using conservation laws of '
               'elasticity. *Journal of Applied Mechanics*. 1980. Vol. 47, No. 2. P. 335–341. DOI: 10.1115/1.3153665.',
    'li1985': 'Li F. Z., Shih C. F., Needleman A. A comparison of methods for calculating energy release rates. '
              '*Engineering Fracture Mechanics*. 1985. Vol. 21, No. 2. P. 405–421. DOI: 10.1016/0013-7944(85)90029-3.',
    'moran1987': 'Moran B., Shih C. F. Crack tip and associated domain integrals from momentum and energy balance. '
                 '*Engineering Fracture Mechanics*. 1987. Vol. 27, No. 6. P. 615–642. DOI: 10.1016/0013-7944(87)90155-X.',
    'barsoum1976': 'Barsoum R. S. On the use of isoparametric finite elements in linear fracture mechanics. '
                   '*International Journal for Numerical Methods in Engineering*. 1976. Vol. 10, No. 1. P. 25–37. '
                   'DOI: 10.1002/nme.1620100103.',
    'cotterell1980': 'Cotterell B., Rice J. R. Slightly curved or kinked cracks. *International Journal of Fracture*. 1980. '
                     'Vol. 16, No. 2. P. 155–169. DOI: 10.1007/BF00012619.',
    'he1989': 'He M.-Y., Hutchinson J. W. Crack deflection at an interface between dissimilar elastic materials. '
              '*International Journal of Solids and Structures*. 1989. Vol. 25, No. 9. P. 1053–1067. '
              'DOI: 10.1016/0020-7683(89)90021-8.',
    'hutchinson1991': 'Hutchinson J. W., Suo Z. Mixed mode cracking in layered materials. *Advances in Applied Mechanics*. '
                      'Vol. 29. P. 63–191. DOI: 10.1016/S0065-2156(08)70164-9. (Рік за реєстром Crossref — 1991.)',
    'atkinson1972': 'Atkinson C. The interaction between a crack and an inclusion. *International Journal of Engineering Science*. '
                    '1972. Vol. 10, No. 2. P. 127–136. DOI: 10.1016/0020-7225(72)90011-0.',
    'erdogan1974': 'Erdogan F., Gupta G. D., Ratwani M. Interaction between a circular inclusion and an arbitrarily oriented crack. '
                   '*Journal of Applied Mechanics*. 1974. Vol. 41, No. 4. P. 1007–1013. DOI: 10.1115/1.3423424.',
    'li1993': 'Li R., Chudnovsky A. Energy analysis of crack interaction with an elastic inclusion. '
              '*International Journal of Fracture*. 1993. Vol. 63, No. 3. P. 247–261. DOI: 10.1007/BF00012471.',
    'bush1997': 'Bush M. B. The interaction between a crack and a particle cluster. *International Journal of Fracture*. 1997. '
                'Vol. 88, No. 3. P. 215–232. DOI: 10.1023/A:1007469631883.',
    'simha2003': 'Simha N. K., Fischer F. D., Kolednik O., Chen C. R. Inhomogeneity effects on the crack driving force in elastic '
                 'and elastic–plastic materials. *Journal of the Mechanics and Physics of Solids*. 2003. Vol. 51, No. 1. '
                 'P. 209–240. DOI: 10.1016/S0022-5096(02)00025-X.',
    'fratzl2007': 'Fratzl P., Gupta H. S., Fischer F. D., Kolednik O. Hindered crack propagation in materials with periodically '
                  'varying Young’s modulus — lessons from biological materials. *Advanced Materials*. 2007. Vol. 19, No. 18. '
                  'P. 2657–2661. DOI: 10.1002/adma.200602394.',
    'kolednik2011': 'Kolednik O., Predan J., Fischer F. D., Fratzl P. Bioinspired design criteria for damage-resistant materials '
                    'with periodically varying microstructure. *Advanced Functional Materials*. 2011. Vol. 21, No. 19. '
                    'P. 3634–3641. DOI: 10.1002/adfm.201100443.',
    'hossain2014': 'Hossain M. Z., Hsueh C.-J., Bourdin B., Bhattacharya K. Effective toughness of heterogeneous media. '
                   '*Journal of the Mechanics and Physics of Solids*. 2014. Vol. 71. P. 15–32. DOI: 10.1016/j.jmps.2014.06.002.',
    'fageehi2024': 'Fageehi Y. A., Alshoaibi A. M. Investigating the influence of holes as crack arrestors in simulating crack '
                   'growth behavior using finite element method. *Applied Sciences*. 2024. Vol. 14, No. 2. Art. 897. '
                   'DOI: 10.3390/app14020897.',
    'alshoaibi2023': 'Alshoaibi A. M., Fageehi Y. A. A robust adaptive mesh generation algorithm: a solution for simulating 2D '
                     'crack growth problems. *Materials*. 2023. Vol. 16, No. 19. Art. 6481. DOI: 10.3390/ma16196481.',
    'alshoaibi2022': 'Alshoaibi A. M., Fageehi Y. A. Finite element simulation of a crack growth in the presence of a hole in the '
                     'vicinity of the crack trajectory. *Materials*. 2022. Vol. 15, No. 1. Art. 363. DOI: 10.3390/ma15010363.',
    'arunkumar2023': 'Arunkumar S., Nithin V. K. Effect of a circular hole on the SIF of a plate with a center crack subjected to '
                     'uniaxial loading. *Strength, Fracture and Complexity*. 2023. Vol. 16, No. 1. P. 47–60. '
                     'DOI: 10.3233/SFC-220294.',
    'gupta2026': 'Gupta S., Moini R. Engineering mechanics of bio-inspired architected cementitious materials (ACM) and composites '
                 '(ACC) enabled by digital fabrication. *Materials and Structures*. 2026. Vol. 59, No. 9. Art. 432. '
                 'DOI: 10.1617/s11527-026-03269-0.',
    'moini2024': 'Moini R. Perspectives in architected infrastructure materials. *RILEM Technical Letters*. 2024. Vol. 8. '
                 'P. 125–140. DOI: 10.21809/rilemtechlett.2023.183.',
    'gao2026': 'Gao Y., Liu J., Wei X. Graph-field framework for fracture mechanics of architected lattice materials. '
               '*Journal of the Mechanics and Physics of Solids*. 2026. Vol. 215. Art. 106729. DOI: 10.1016/j.jmps.2026.106729.',
    'wu2018': 'Wu J.-Y., Nguyen V. P. A length scale insensitive phase-field damage model for brittle fracture. '
              '*Journal of the Mechanics and Physics of Solids*. 2018. Vol. 119. P. 20–42. DOI: 10.1016/j.jmps.2018.06.006.',
    'mohmadsalehi2022': 'Mohmadsalehi M., Soghrati S. An automated mesh generation algorithm for simulating complex crack growth '
                        'problems. *Computer Methods in Applied Mechanics and Engineering*. 2022. Vol. 398. Art. 115015. '
                        'DOI: 10.1016/j.cma.2022.115015.',
    'repo': 'NewMetacomp: репозиторій дослідження G2 (код MATLAB, пререєстрації, записи доказів, наукові рецензії). '
            'URL: https://github.com/mfs9697/NewMetacomp (чернеткові запити на злиття № 8–71; стан на 25.11.2026).',
}
