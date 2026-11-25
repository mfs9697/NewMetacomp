"""Build and verify the LP2-A2 equivalence campaign archive (deterministic ZIP + SHA-256 manifest); copy and verify on two devices.
Members: every file under outputs/g2_lp2a2_eq_v1 (campaign records, also partial ones after a HOLD), the committed GO file, and every
file in the scratch evidence folders pre/, campaign/, verify/ (logs, scripts, JSON results).
usage: python -I lp2a2_eq_archive.py <execRepo> <runDir(scratch)> <localDir> <offDeviceDir> <out.json>"""
import hashlib, json, os, shutil, sys, zipfile
ex, rdir, loc, off, out = sys.argv[1:6]
name = 'NewMetacomp_G2_LP2A2_EQ_HoldEvidence_20261125.zip'
sha = lambda b: hashlib.sha256(b).hexdigest()


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


members = []
root = os.path.join(ex, 'outputs', 'g2_lp2a2_eq_v1')
for d, _, fs in os.walk(root):
    for n in fs:
        p = os.path.join(d, n)
        members.append((os.path.relpath(p, ex).replace('\\', '/'), p))
nrec = len(members)
go = os.path.join(ex, 'matlab', 'g2', 'lp2a2', 'G2_LP2A2_EQ_GO.json')
if os.path.isfile(go):
    members.append(('matlab/g2/lp2a2/G2_LP2A2_EQ_GO.json', go))
for sub in ('pre', 'campaign', 'verify'):
    for d, _, fs in os.walk(os.path.join(rdir, sub)):
        for n in fs:
            p = os.path.join(d, n)
            members.append(('logs/' + os.path.relpath(p, rdir).replace('\\', '/'), p))
members.sort()
assert len({m for m, _ in members}) == len(members)
man = {m: fsha(p) for m, p in members}
manifest = '\n'.join(f'{v}  {k}' for k, v in man.items()) + '\n'
tmp = os.path.join(rdir, 'archive', name)
os.makedirs(os.path.dirname(tmp), exist_ok=True)
if os.path.exists(tmp):
    os.remove(tmp)
with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as z:
    for m, p in members:
        zi = zipfile.ZipInfo(m, date_time=(2026, 11, 25, 0, 0, 0))
        zi.compress_type = zipfile.ZIP_DEFLATED
        z.writestr(zi, open(p, 'rb').read())
    zi = zipfile.ZipInfo('MANIFEST_SHA256.txt', date_time=(2026, 11, 25, 0, 0, 0))
    zi.compress_type = zipfile.ZIP_DEFLATED
    z.writestr(zi, manifest.encode())
zsha = fsha(tmp)


def verify(path):
    ok = fsha(path) == zsha
    with zipfile.ZipFile(path) as z:
        ok = ok and z.testzip() is None and all(sha(z.read(m)) == h for m, h in man.items())
        ok = ok and sha(z.read('MANIFEST_SHA256.txt')) == sha(manifest.encode()) and len(z.namelist()) == len(man) + 1
    return ok


res = {'archive': name, 'sha256': zsha, 'bytes': os.path.getsize(tmp), 'members': len(members) + 1,
       'campaignRecordFiles': nrec, 'manifestSHA256': sha(manifest.encode())}
for label, d in (('local', loc), ('offDevice', off)):
    os.makedirs(d, exist_ok=True)
    dst = os.path.join(d, name)
    assert not os.path.exists(dst), dst + ' exists'
    shutil.copyfile(tmp, dst)
    res[label + 'CopyVerified'] = verify(dst)
    res[label + 'CopySHA256'] = fsha(dst)
res['memberSHA256'] = man
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('ARCHIVE', zsha, res['bytes'], 'members', res['members'], 'records', nrec, 'local', res['localCopyVerified'], 'off', res['offDeviceCopyVerified'])
