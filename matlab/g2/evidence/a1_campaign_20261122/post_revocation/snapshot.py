"""SHA-256 snapshot of protected trees in the execution clone (A0 runs, A0 ledger, A1 meshes).
usage: python snapshot.py <execRepo> <out.json> [<compareTo.json>]"""
import hashlib, json, os, sys
repo, out = sys.argv[1], sys.argv[2]
trees = ['outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1', 'outputs/g2_lp1_matrix_paths_v1/run_a0_lp1_repro_v1',
         'outputs/g2_lp1_campaign_ledger', 'outputs/g2_a1_geometry_v1']
snap = {}
for t in trees:
    for root, _, files in os.walk(os.path.join(repo, t)):
        for f in files:
            p = os.path.join(root, f); rel = os.path.relpath(p, repo).replace(os.sep, '/')
            snap[rel] = hashlib.sha256(open(p, 'rb').read()).hexdigest()
# A0 run vs committed manifest
man = json.load(open(os.path.join(repo, 'matlab/g2/evidence/lp1_a0_20261122/A0_RUN_RECORDS_SHA256.json')))
pre = 'outputs/g2_lp1_matrix_paths_v1/run_a0_lp1_repro_v1/'
bad = [k for k, v in man.items() if snap.get(pre + k) != v]
res = {'nFiles': len(snap), 'a0ManifestEntries': len(man), 'a0ManifestMismatches': bad, 'files': snap}
if len(sys.argv) > 3:
    old = json.load(open(sys.argv[3]))['files']
    res['changedVsBefore'] = sorted(k for k in set(old) | set(snap) if old.get(k) != snap.get(k))
json.dump(res, open(out, 'w'), indent=1, sort_keys=True)
print('nFiles', len(snap), 'a0Manifest', len(man), 'mismatches', len(bad), 'changed', len(res.get('changedVsBefore', [])))
