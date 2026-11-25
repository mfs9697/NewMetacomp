"""M5-X6 WP1.1: verify the A1 archive copy that holds the four diagonal B9 records (read-only).

usage: python -I scripts/g2/m5/x6/m5x6_archive_check.py <worktree> <archive.zip> <execRepo> <out.json>
Checks the archive SHA-256 against A1_ARCHIVE.json and the plan, finds the eight B9 STATE/SOLUTION
members, hashes their bytes inside the ZIP and compares them with the plan pins, the committed
A1_RUN_RECORDS_SHA256.json and the files in the execution clone. Writes only out.json.
Local paths are written sanitized (<archive>, <repo>).
"""
import hashlib, json, os, sys, zipfile

wt, arc, ex, out = sys.argv[1:5]
plan = json.load(open(os.path.join(wt, 'scripts/g2/m5/x6/G2_M5_X6_PLAN_v1.json'), encoding='utf-8'))
rec = json.load(open(os.path.join(wt, 'matlab/g2/evidence/a1_campaign_20261122/A1_ARCHIVE.json'), encoding='utf-8'))
man = json.load(open(os.path.join(wt, 'matlab/g2/evidence/a1_campaign_20261122/campaign/A1_RUN_RECORDS_SHA256.json'), encoding='utf-8'))
sha = lambda b: hashlib.sha256(b).hexdigest()
h = hashlib.sha256()
with open(arc, 'rb') as f:
    for blk in iter(lambda: f.read(1 << 20), b''):
        h.update(blk)
zsha = h.hexdigest()
rows = []
with zipfile.ZipFile(arc) as z:
    names = z.namelist()
    for d in plan['diagonal']:
        for fn, pin in (('STATE.mat', d['stateFileSHA256']), ('SOLUTION.mat', d['solutionFileSHA256'])):
            rel = f"{d['key']}/{fn}"
            m = [n for n in names if n.replace('\\', '/').endswith('/' + plan['a1']['runName'] + '/' + rel)]
            zb = sha(z.read(m[0])) if len(m) == 1 else None
            fb = sha(open(os.path.join(ex, 'outputs', 'g2_a1_fixed_path_v1', plan['a1']['runName'], d['key'], fn), 'rb').read())
            rows.append({'record': rel, 'archiveMember': m[0] if len(m) == 1 else None, 'archiveSHA256': zb,
                         'execCloneSHA256': fb, 'planPin': pin, 'committedManifest': man[rel],
                         'allEqual': zb == fb == pin == man[rel]})
res = {'schema': 'NewMetacomp.G2.M5X6.ArchiveCheck.v1', 'archive': '<archive>/' + os.path.basename(arc),
       'archiveSHA256': zsha, 'expectedSHA256': rec['sha256'], 'planSHA256Pin': plan['a1']['archiveSHA256'],
       'archiveSHA256Matches': zsha == rec['sha256'] == plan['a1']['archiveSHA256'], 'members': len(names),
       'membersExpected': rec['members'], 'b9Records': rows, 'allB9RecordsEqual': all(r['allEqual'] for r in rows),
       'offDeviceCopyRechecked': False,
       'offDeviceNote': 'removable drive D: not attached on 2026-11-23; the off-device copy was verified on 2026-11-22 (A1_ARCHIVE.json) and is not re-verified here'}
json.dump(res, open(out, 'w', encoding='utf-8'), indent=1)
print('ARCHIVE', res['archiveSHA256Matches'], 'members', len(names), 'B9 records equal', res['allB9RecordsEqual'])
