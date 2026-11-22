"""G2-LP1-A0-P0 read-only pin and readiness check (Issue #60). No MATLAB, mesh, FEM or GO.

Verifies, from Git blob bytes of --commit, every value a prospective A0 GO would have
to bind:
- the source-set digest (as g2_lp1_context computes it);
- policy v2, policy v1 link, source lock and LP0 evidence;
- the full context token;
- the committed contract evidence: blob SHA, LF bytes, the production-validator
  predicates and path rules, and its relation to the batch manifest and sanitization
  record;
- the absence of a GO in the tree.

Optionally checks a clean execution clone (--clone): core.autocrlf, tree cleanliness,
absence of the proposed run folder, historical run hashes. Optionally checks the raw
archive (--archive).

  python -I scripts/g2/a0/a0_pin_check.py --commit <sha> [--clone <path>] [--archive <zip>] --out <json>
"""
import argparse
import fnmatch
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
EXP = {
    'sourceSet': '6f7fb3ea51a0ae64e30a5c63f8cc765af5308c511da315c989ae10235fbed030',
    'policyV2': '074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091',
    'policyV1': '1cf5a76ded840b0758343a1b935b299041e779ec6332c3b7cb0b6dfba1e2af43',
    'lock': '6e19e222379eda36e0850e439c85181efae105a9347bcc1740e73114c0616b82',
    'lp0': 'b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5',
    'archive': '5b333b03e37f08a0c6de839cb646f8c72ea474ba547ba04022ed213059f3c533',
    'archiveBytes': 52837630,
    'qualifiedSourceCommit': 'f65d2523fe2e5e333f0c6a675deacbf217e1c5ea'}
TOKEN = ('G2LP1|policy={p}|source={s}|LP0={l}|cases=H,stiff13,soft2,soft1|maxState=4'
         .format(p=EXP['policyV2'], s=EXP['sourceSet'], l=EXP['lp0']))
CONTRACT = 'matlab/g2/evidence/lp1_preflight/vg1_20261122/E_corrected_batch_f65d252/CONTRACT_TESTS.json'
EDIR = 'matlab/g2/evidence/lp1_preflight/vg1_20261122/E_corrected_batch_f65d252/'
GO_PATH = 'matlab/g2/G2_LP1_SCIENTIFIC_GO_v1.json'
RUN_NAME = 'run_a0_lp1_repro_v1'
HIST_RUN = 'outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1'
checks = []


def chk(cid, desc, ok, value=None):
    checks.append({'id': cid, 'description': desc, 'pass': bool(ok), 'value': value})


def git(repo, *a):
    return subprocess.run(['git', '-C', str(repo), *a], capture_output=True, check=True).stdout


def blob(commit, path):
    return git(REPO, 'show', f'{commit}:{path}')


def sha(b):
    return hashlib.sha256(b).hexdigest()


def tree(commit, *paths):
    out = git(REPO, 'ls-tree', '-r', '--name-only', commit, '--', *paths).decode().splitlines()
    return set(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--commit', required=True)
    ap.add_argument('--clone')
    ap.add_argument('--archive')
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    c = git(REPO, 'rev-parse', a.commit).decode().strip()

    # source set exactly as g2_lp1_context
    pol2b = blob(c, 'matlab/g2/G2_LP1_POLICY_v2.json')
    pol = json.loads(pol2b)
    names = sorted(p.split('/')[-1] for p in tree(c, 'matlab/g2')
                   if p.count('/') == 2 and any(fnmatch.fnmatchcase(p.split('/')[-1], q)
                                                for q in ['g2_lp0*.m', 'g2_lp1*.m', 'check_g2_lp*.m']))
    lines = ['legacy-lock ' + pol['sourceLockSHA256']] + [f'{n} {sha(blob(c, "matlab/g2/" + n))}' for n in names]
    src = sha('\n'.join(lines).encode('utf-8'))
    chk('S1', 'Source-set digest at commit equals the qualified VG1 source set', src == EXP['sourceSet'], src)
    chk('S2', 'Policy v2 blob SHA-256', sha(pol2b) == EXP['policyV2'], sha(pol2b))
    chk('S3', 'Policy v1 blob equals v2.previousPolicySHA256',
        sha(blob(c, 'matlab/g2/G2_LP1_POLICY_v1.json')) == pol['previousPolicySHA256'] == EXP['policyV1'],
        pol['previousPolicySHA256'])
    chk('S4', 'Source lock blob equals v2.sourceLockSHA256',
        sha(blob(c, 'matlab/g2/G2_LP0_SOURCE_LOCK_v1.json')) == pol['sourceLockSHA256'] == EXP['lock'],
        pol['sourceLockSHA256'])
    lp0b = blob(c, pol['lp0Evidence']['file'])
    lp0 = json.loads(lp0b)
    chk('S5', 'LP0 evidence blob equals v2.lp0Evidence.sha256 and carries the required status',
        sha(lp0b) == pol['lp0Evidence']['sha256'] == EXP['lp0'] and lp0.get('status') == pol['lp0Evidence']['requiredStatus']
        and lp0.get('pass') is True and lp0.get('physicalSolves') == 0,
        {'sha': sha(lp0b), 'status': lp0.get('status')})
    tok = f"G2LP1|policy={sha(pol2b)}|source={src}|LP0={pol['lp0Evidence']['sha256']}|cases=H,stiff13,soft2,soft1|maxState=4"
    chk('S6', 'Context token rebuilt from pins equals the expected full token', tok == TOKEN, tok)
    res = json.loads(blob(c, EDIR + 'PREPHYSICAL_RESULT.json'))
    chk('S7', 'Corrected batch result: TESTS_PASS_SCIENTIFIC_HOLD at the qualified source commit, printed token equal, '
        'no GO, zero solves/meshes, both refusals HOLD_UNAUTHORIZED_STATE',
        res['status'] == 'TESTS_PASS_SCIENTIFIC_HOLD' and res['sourceCommit'] == EXP['qualifiedSourceCommit']
        and res['currentToken'] == TOKEN and res['scientificGO'] is False and res['physicalSolves'] == 0
        and res['meshBuilds'] == 0 and res['refusalProbeIdentifiers'] == ['G2LP1:HOLD_UNAUTHORIZED_STATE'] * 2,
        {k: res[k] for k in ['status', 'sourceCommit', 'refusalProbeIdentifiers']})

    # contract evidence as the production validator would read it
    cb = blob(c, CONTRACT)
    T = json.loads(cb)
    pred = (T.get('pass') is True and T.get('passed') == T.get('total') and T.get('total', 0) >= 20
            and T.get('physicalSolves') == 0 and T.get('meshBuilds') == 0
            and T.get('negativeTestsPassed') is True and T.get('recordIntegrityPassed') is True)
    pathok = (CONTRACT.startswith('matlab/g2/evidence/lp1_preflight/') and '..' not in CONTRACT
              and re.fullmatch(r'[A-Za-z0-9_./-]+', CONTRACT) is not None)
    chk('C1', 'Contract evidence path satisfies the validator path rules', pathok, CONTRACT)
    chk('C2', 'Contract evidence bytes are LF-only (an autocrlf checkout would change the SHA)', b'\r' not in cb, len(cb))
    chk('C3', 'Contract content satisfies every g2_lp1_go_validate predicate', pred,
        {k: T.get(k) for k in ['pass', 'passed', 'total', 'physicalSolves', 'meshBuilds',
                               'negativeTestsPassed', 'recordIntegrityPassed']})
    chk('C4', 'Contract is the amended v2 suite: 74/74 and all VG1 class flags',
        T.get('total') == 74 and T.get('passed') == 74 and T.get('schema') == 'NewMetacomp.G2.LP1.ContractTests.v2'
        and all(T.get(f) is True for f in ['goFixturesPassed', 'admissionPassed', 'interfacePassed', 'exactIdentifierNegatives'])
        and all(t['pass'] for t in T['tests']), {'total': T.get('total'), 'schema': T.get('schema')})
    man = json.loads(blob(c, EDIR + 'BATCH_MANIFEST.json'))
    san = json.loads(blob(c, EDIR + 'SANITIZATION.json'))
    mf = {f['name']: f['sha256'] for f in man['files']}
    sf = {f['file']: f for f in san['files']}
    chk('C5', 'Committed contract bytes equal the original batch bytes listed in BATCH_MANIFEST (unchanged by sanitization)',
        mf.get('CONTRACT_TESTS.json') == sf['CONTRACT_TESTS.json']['originalSHA256'] == sha(cb),
        {'committed': sha(cb), 'manifest': mf.get('CONTRACT_TESTS.json')})
    chk('C6', 'Batch manifest: exit 0, no GO, commit = qualified source commit, branch VG1',
        man['exitCode'] == 0 and man['scientificGO'] is False and man['sourceCommit'] == EXP['qualifiedSourceCommit']
        and man['branch'] == 'research/g2-lp1-vg1-guard-negatives-20261122',
        {k: man[k] for k in ['exitCode', 'sourceCommit', 'branch']})
    chk('G1', 'No scientific GO file exists in the tree at the commit', GO_PATH not in tree(c, 'matlab/g2'), GO_PATH)
    chk('R1', 'Proposed A0 run name satisfies the controller parser and differs from the historical run',
        re.fullmatch(r'run_[a-zA-Z0-9_]+', RUN_NAME) is not None and RUN_NAME != 'run_20261122_lp1_v1', RUN_NAME)

    if a.clone:
        cl = Path(a.clone)
        chk('K1', 'Execution clone: core.autocrlf=false',
            git(cl, 'config', '--get', 'core.autocrlf').decode().strip() == 'false')
        chk('K2', 'Execution clone: clean tree', git(cl, 'status', '--porcelain', '--untracked-files=all').strip() == b'')
        chk('K3', 'Execution clone: proposed A0 run folder does not exist',
            not (cl / 'outputs/g2_lp1_matrix_paths_v1' / RUN_NAME).exists())
        led = json.loads(blob(c, 'matlab/g2/evidence/lp1_20261122/RAW_RECORDS_SHA256.json'))
        bad = [n for n, h in led.items() if not (cl / HIST_RUN / n).is_file() or sha((cl / HIST_RUN / n).read_bytes()) != h]
        chk('K4', 'Execution clone: all 182 historical records present and hash-equal', not bad and len(led) == 182, bad[:5])
        lock = json.loads(blob(c, 'matlab/g2/G2_LP0_SOURCE_LOCK_v1.json'))
        miss = [e['file'] for e in lock['acceptedInputs']
                if not (cl / e['file']).is_file() or sha((cl / e['file']).read_bytes()) != e['sha256']]
        chk('K5', 'Execution clone: all 654 accepted historical MAT inputs present and hash-equal',
            not miss and len(lock['acceptedInputs']) == 654, miss[:5])
    if a.archive:
        z = Path(a.archive)
        data = z.read_bytes()
        led = json.loads(blob(c, 'matlab/g2/evidence/lp1_20261122/RAW_RECORDS_SHA256.json'))
        with zipfile.ZipFile(z) as zf:
            ok = sum(1 for n in zf.namelist() if n in led and sha(zf.read(n)) == led[n])
        chk('H1', 'Raw archive SHA, size and 182/182 members',
            sha(data) == EXP['archive'] and len(data) == EXP['archiveBytes'] and ok == 182, {'members': ok})

    out = {'schema': 'NewMetacomp.G2.LP1.A0P0.PinCheck.v1', 'commit': c, 'expectedToken': TOKEN,
           'contractEvidence': {'path': CONTRACT, 'sha256': sha(cb)}, 'proposedRunName': RUN_NAME,
           'checks': checks, 'passed': sum(x['pass'] for x in checks), 'total': len(checks),
           'noMATLAB': True, 'noFEM': True, 'noGO': True}
    Path(a.out).write_text(json.dumps(out, indent=1), encoding='utf-8', newline='\n')
    for x in checks:
        print(f"{x['id']:3s} {'PASS' if x['pass'] else 'FAIL'}  {x['description'][:100]}")
    print(f"A0_P0_PIN_CHECK={out['passed']}/{out['total']} contractSHA256={sha(cb)}")


if __name__ == '__main__':
    main()
