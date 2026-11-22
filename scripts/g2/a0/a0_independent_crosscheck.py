"""G2-LP1-A0 independent cross-check (Issue #64). Read-only, standard library only.

Compares the 20 A0 states (full read-only MATLAB extract of the new run, produced by
scripts/g2/sr1/sr1_extract_records.m) with the committed SR1 extract of the historical
run (docs/research/G2_LP1_SR1_independent_check/LP1_records_reduced.json) field by field.
It also compares the independent T3 mesh quality, and checks the new provenance chain,
file-hash links and campaign ledger from raw bytes on disk.

  python -I scripts/g2/a0/a0_independent_crosscheck.py --new-extract X.json --new-meshq Y.json \
      --exec-clone <clone> --out Z.json
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
HIST = REPO / 'docs/research/G2_LP1_SR1_independent_check/LP1_records_reduced.json'
HISTQ = REPO / 'docs/research/G2_LP1_SR1_independent_check/LP1_mesh_quality.json'
CASES = ['H', 'stiff13', 'soft2', 'soft1']
SRC = '9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5'
POL = '074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091'
RUN = 'outputs/g2_lp1_matrix_paths_v1/run_a0_lp1_repro_v1'
LED = 'outputs/g2_lp1_campaign_ledger/G2-LP1-A0-001'


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def flat(x):
    if isinstance(x, list):
        out = []
        for v in x:
            out += flat(v)
        return out
    return [x]


def diff(a, b):
    """Maximum absolute difference between nested numeric lists or scalars; inf on shape mismatch."""
    fa, fb = flat(a), flat(b)
    if len(fa) != len(fb):
        return math.inf
    m = 0.0
    for x, y in zip(fa, fb):
        if x is None or y is None:
            if x != y:
                return math.inf
            continue
        if isinstance(x, bool) or isinstance(y, bool):
            if x != y:
                return math.inf
            continue
        if isinstance(x, str) or isinstance(y, str):
            if x != y:
                return math.inf
            continue
        m = max(m, abs(x - y))
    return m


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--new-extract', required=True)
    ap.add_argument('--new-meshq', required=True)
    ap.add_argument('--exec-clone', required=True)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    H = json.loads(HIST.read_text(encoding='utf-8'))['states']
    HQ = json.loads(HISTQ.read_text(encoding='utf-8'))
    N = json.loads(Path(a.new_extract).read_text(encoding='utf-8'))
    NQ = json.loads(Path(a.new_meshq).read_text(encoding='utf-8'))
    cl = Path(a.exec_clone)
    st_fields = ['polyline_mm', 'tangent', 'normal', 'arc_mm', 'KI', 'KII', 'EDI_all', 'MTS_deg', 'G']
    k_fields = ['J', 'KI_COD', 'KII_COD', 'EDI4x4', 'qActiveElements', 'compliance_mm_per_N', 'CMOD_mm',
                'strainEnergy_per_thickness', 'externalWork_per_thickness', 'reactions', 'ringStrainEnergy_per_thickness',
                'phaseCounts', 'activeArea_mm2', 'interfaceSideL2Rel', 'fullPolyOpeningMin_mm']
    q_fields = ['nT3', 'nNodes', 'minAngle_deg', 'maxAngle_deg', 'minAbsArea_mm2', 'nNegativeArea', 'totalArea_mm2',
                'maxNeighbourLongestEdgeRatio', 'boundaryEdges', 'crackPolyline', 'tipTangent']
    rows, prov = [], []
    for c in CASES:
        prev = None
        for k in range(5):
            key = f'{c}_S{k}'
            h, n = H[key], N[key]
            hs, ns = h['STATE'], n['STATE']
            hk, nk = h['SOLUTION']['K'], n['SOLUTION']['K']
            d = {f: diff(hs[f], ns[f]) for f in st_fields}
            d.update({'K.' + f: diff(hk[f], nk[f]) for f in k_fields})
            d['clearance.metrics'] = diff([hs['clearance']['metrics'][m] for m in sorted(hs['clearance']['metrics'])],
                                          [ns['clearance']['metrics'][m] for m in sorted(ns['clearance']['metrics'])]) \
                if isinstance(hs['clearance'].get('metrics'), dict) and hs['clearance']['metrics'] else 0.0
            d.update({'mesh.' + f: diff(HQ[key][f], NQ[key][f]) for f in q_fields})
            worst = max(d.values())
            sol_gate = nk['pass'] in (1, True) and not nk['failedCriteria']
            ph_gate = n['PHASE']['audit']['pass'] in (1, True) and n['PHASE']['audit']['meshAudit']['gatesPassed'] == n['PHASE']['audit']['meshAudit']['gatesTotal']
            rows.append({'state': key, 'maxAbsDiff_allFields': worst, 'bitwiseAllFields': worst == 0.0,
                         'KI_hist': hs['KI'], 'KI_new': ns['KI'], 'KII_hist': hs['KII'], 'KII_new': ns['KII'],
                         'G_hist': hs['G'], 'G_new': ns['G'], 'MTS_hist_deg': hs['MTS_deg'], 'MTS_new_deg': ns['MTS_deg'],
                         'tip_hist': hs['polyline_mm'][-1], 'tip_new': ns['polyline_mm'][-1],
                         'nT3_hist': HQ[key]['nT3'], 'nT3_new': NQ[key]['nT3'],
                         'sifGatesPass': sol_gate, 'phaseAuditPass': ph_gate, 'diffs': d})
            sd = cl / RUN / c / f'S{k}'
            files = {f: sha(sd / f'{f}.mat') for f in ['MESH', 'PHASE', 'SOLUTION', 'REVIEW', 'STATE']}
            ok = (ns['sourceSHA256'] == SRC and n['SOLUTION']['sourceSHA256'] == SRC and ns['policySHA256'] == POL
                  and ns['meshSHA256'] == files['MESH'] and ns['phaseSHA256'] == files['PHASE']
                  and ns['solutionSHA256'] == files['SOLUTION'] and ns['reviewSHA256'] == files['REVIEW']
                  and (k == 0 or ns['parentSHA256'] == prev) and ns['caseId'] == c and ns['stateIndex'] == k)
            prov.append({'state': key, 'ok': ok, 'stateSHA256': files['STATE'], 'files': files})
            prev = files['STATE']
    led = cl / LED
    entries = sorted(p.name for p in led.iterdir())
    mats = [e for e in entries if e.endswith('.mat')]
    ledger = {'entries': entries, 'sha256': {e: sha(led / e) for e in entries},
              'expectedSet': mats == sorted(['RECEIPT.mat', 'CLOSED.mat'] + [f'ADMIT_{c}_S{k}.mat' for c in CASES for k in range(5)]),
              'allManifests': all((led / (m + '.manifest.json')).is_file() for m in mats)}
    for m in mats:
        man = json.loads((led / (m + '.manifest.json')).read_text(encoding='utf-8'))
        ledger.setdefault('manifestHashOK', True)
        ledger['manifestHashOK'] &= man['SHA256'].lower() == ledger['sha256'][m]
    res = {'schema': 'NewMetacomp.G2.LP1.A0.IndependentCrosscheck.v1', 'states': rows, 'provenance': prov, 'ledger': ledger,
           'bitwiseStates': sum(r['bitwiseAllFields'] for r in rows), 'total': len(rows),
           'provenanceOK': all(p['ok'] for p in prov), 'gatesOK': all(r['sifGatesPass'] and r['phaseAuditPass'] for r in rows)}
    Path(a.out).write_text(json.dumps(res, indent=1, default=str), encoding='utf-8', newline='\n')
    for r in rows:
        print(f"{r['state']:11s} bitwise={r['bitwiseAllFields']} maxdiff={r['maxAbsDiff_allFields']:.3g} T3 {r['nT3_hist']}/{r['nT3_new']}")
    print(f"A0_CROSSCHECK bitwise={res['bitwiseStates']}/{res['total']} provenanceOK={res['provenanceOK']} gatesOK={res['gatesOK']} "
          f"ledgerSet={ledger['expectedSet']} manifests={ledger['allManifests']} manifestHash={ledger.get('manifestHashOK')}")


if __name__ == '__main__':
    main()
