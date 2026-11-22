"""G2-LP1-VG1 independent source-integrity comparison (Issue #58). Read-only.

Recomputes, from Git blob bytes only, the LP1 source-set digest exactly as
g2_lp1_context builds it:
  lines = ['legacy-lock <policy.sourceLockSHA256>'] +
          ['<name> <sha256(blob)>' for sorted g2_lp0*.m, g2_lp1*.m, check_g2_lp*.m in matlab/g2]
  digest = sha256('\\n'.join(lines))
for the original physical source, the PR #55 guarded head and the VG1 head. It
also lists every blob that differs between them, and checks that the policies,
the source lock and the immutable LP1 evidence did not change.

  python -I scripts/g2/vg1/vg1_source_integrity.py --commit ORIG=<sha>[@<repo>] ... --out <json>
"""
import argparse
import fnmatch
import hashlib
import json
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
PATTERNS = ['g2_lp0*.m', 'g2_lp1*.m', 'check_g2_lp*.m']
PINNED = ['matlab/g2/G2_LP1_POLICY_v1.json', 'matlab/g2/G2_LP1_POLICY_v2.json',
          'matlab/g2/G2_LP0_SOURCE_LOCK_v1.json',
          'matlab/g2/evidence/lp0_20261122/QUALIFICATION_ATTEMPT2.json',
          'matlab/g2/evidence/lp1_20261122/RAW_RECORDS_SHA256.json',
          'matlab/g2/evidence/lp1_20261122/FINAL_PRESERVATION_CHECK.json']


def git(repo, *a):
    return subprocess.run(['git', '-C', str(repo), *a], capture_output=True, check=True).stdout


def tree(repo, commit):
    out = git(repo, 'ls-tree', '-r', commit, '--', 'matlab/g2', 'scripts/g2').decode()
    rows = {}
    for line in out.splitlines():
        meta, path = line.split('\t', 1)
        rows[path] = meta.split()[2]
    return rows


def blob(repo, commit, path):
    return git(repo, 'show', f'{commit}:{path}')


def digest(repo, commit):
    pol = json.loads(blob(repo, commit, 'matlab/g2/G2_LP1_POLICY_v2.json'))
    t = tree(repo, commit)
    names = sorted(p.split('/')[-1] for p in t
                   if p.count('/') == 2 and p.startswith('matlab/g2/')
                   and any(fnmatch.fnmatchcase(p.split('/')[-1], pat) for pat in PATTERNS))
    lines = ['legacy-lock ' + pol['sourceLockSHA256']]
    files = {}
    for n in names:
        h = hashlib.sha256(blob(repo, commit, 'matlab/g2/' + n)).hexdigest()
        files[n] = h
        lines.append(f'{n} {h}')
    d = hashlib.sha256('\n'.join(lines).encode('utf-8')).hexdigest()
    return d, files, lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--commit', action='append', required=True, help='LABEL=SHA[@REPO]')
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    res = {'schema': 'NewMetacomp.G2.LP1.VG1.SourceIntegrity.v1', 'sets': {}, 'pinnedFiles': {}, 'diffs': {}}
    order = []
    for spec in a.commit:
        label, rest = spec.split('=', 1)
        sha, _, rp = rest.partition('@')
        repo = Path(rp) if rp else REPO
        full = git(repo, 'rev-parse', sha).decode().strip()
        d, files, lines = digest(repo, full)
        res['sets'][label] = {'commit': full, 'tree': git(repo, 'rev-parse', full + '^{tree}').decode().strip(),
                              'sourceSetSHA256': d, 'files': files}
        t_all = tree(repo, full)
        res['pinnedFiles'][label] = {p: (hashlib.sha256(blob(repo, full, p)).hexdigest() if p in t_all else None)
                                     for p in PINNED}
        order.append((label, repo, full))
    for (la, ra, ca), (lb, rb, cb) in zip(order, order[1:]):
        fa, fb = res['sets'][la]['files'], res['sets'][lb]['files']
        ta, tb = tree(ra, ca), tree(rb, cb)
        res['diffs'][f'{la}->{lb}'] = {
            'sourceSetFilesChanged': sorted(n for n in set(fa) & set(fb) if fa[n] != fb[n]),
            'sourceSetFilesAdded': sorted(set(fb) - set(fa)),
            'sourceSetFilesRemoved': sorted(set(fa) - set(fb)),
            'allBlobsChanged_matlab_g2_scripts_g2': sorted(p for p in set(ta) & set(tb) if ta[p] != tb[p]),
            'allBlobsAdded': sorted(set(tb) - set(ta)),
            'allBlobsRemoved': sorted(set(ta) - set(tb)),
            'pinnedFilesIdentical': res['pinnedFiles'][la] == res['pinnedFiles'][lb]}
    Path(a.out).write_text(json.dumps(res, indent=1), encoding='utf-8', newline='\n')
    for k, v in res['sets'].items():
        print(f"{k:10s} {v['commit'][:12]} sourceSet={v['sourceSetSHA256']}")
    for k, v in res['diffs'].items():
        print(k, 'changed:', v['sourceSetFilesChanged'], 'added:', v['sourceSetFilesAdded'],
              'removed:', v['sourceSetFilesRemoved'], 'pinnedIdentical:', v['pinnedFilesIdentical'])


if __name__ == '__main__':
    main()
