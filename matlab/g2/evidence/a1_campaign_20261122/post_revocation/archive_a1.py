"""Deterministic ZIP of the A1 campaign records + ledger + log + preregistered meshes, with an
embedded SHA-256 manifest; copy to a physically separate drive and verify both copies member by member.
usage: python archive_a1.py <execRepo> <localDir> <offDeviceDir>"""
import hashlib, json, os, shutil, sys, zipfile
X, LOC, OFF = sys.argv[1], sys.argv[2], sys.argv[3]
NAME = 'NewMetacomp_G2_A1_FamilyB_Records_20261122.zip'
trees = ['outputs/g2_a1_fixed_path_v1/run_a1_family_b_s4_v1', 'outputs/g2_a1_campaign_ledger/G2-A1-FB-001',
         'outputs/g2_a1_campaign_log', 'outputs/g2_a1_geometry_v1']
h = lambda b: hashlib.sha256(b).hexdigest()
files = []
for t in trees:
    for r, _, fs in os.walk(os.path.join(X, t)):
        for f in fs:
            p = os.path.join(r, f); files.append(os.path.relpath(p, X).replace(os.sep, '/'))
files.sort()
man = {f: h(open(os.path.join(X, f), 'rb').read()) for f in files}
manb = (json.dumps({'schema': 'NewMetacomp.G2.A1.ArchiveManifest.v1', 'campaign': 'G2-A1-FB-001',
                    'run': 'run_a1_family_b_s4_v1', 'files': man}, indent=1) + '\n').encode()
os.makedirs(LOC, exist_ok=True)
zp = os.path.join(LOC, NAME)
assert not os.path.exists(zp), 'archive exists'
with zipfile.ZipFile(zp, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in files:
        zi = zipfile.ZipInfo(f, date_time=(2026, 11, 22, 0, 0, 0)); zi.compress_type = zipfile.ZIP_DEFLATED
        z.writestr(zi, open(os.path.join(X, f), 'rb').read())
    zi = zipfile.ZipInfo('A1_ARCHIVE_MANIFEST_SHA256.json', date_time=(2026, 11, 22, 0, 0, 0)); zi.compress_type = zipfile.ZIP_DEFLATED
    z.writestr(zi, manb)
zsha = h(open(zp, 'rb').read())
def verify(path):
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        names = [n for n in z.namelist() if n != 'A1_ARCHIVE_MANIFEST_SHA256.json']
        ok = sorted(names) == files and all(h(z.read(n)) == man[n] for n in names)
        ok = ok and z.read('A1_ARCHIVE_MANIFEST_SHA256.json') == manb
    return ok and h(open(path, 'rb').read()) == zsha
okL = verify(zp)
op = os.path.join(OFF, NAME)
assert not os.path.exists(op), 'off-device archive exists'
shutil.copyfile(zp, op)
okO = verify(op)
res = {'archive': NAME, 'bytes': os.path.getsize(zp), 'sha256': zsha, 'members': len(files) + 1,
       'runFiles': sum(f.startswith(trees[0]) for f in files), 'ledgerFiles': sum(f.startswith(trees[1]) for f in files),
       'logFiles': sum(f.startswith(trees[2]) for f in files), 'meshFiles': sum(f.startswith(trees[3]) for f in files),
       'manifestSHA256': h(manb), 'localCopyVerified': okL, 'offDeviceCopyVerified': okO,
       'localLocation': '<user>/Documents/NewMetacomp_LP1_archive_backup/', 'offDeviceLocation': 'removable NTFS drive D:\\ (physically separate from C:)'}
print(json.dumps(res, indent=1))
json.dump(res, open(os.path.join(LOC, NAME + '.json'), 'w'), indent=1)
