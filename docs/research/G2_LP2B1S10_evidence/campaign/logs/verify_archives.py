"""Verify archive copies on the local backup and the removable drive: SHA-256, and (when a record is given) member count and
every member's SHA-256 against the committed archive record. Also lists all five archives relevant to LP2-B1-S10.
usage: python -I verify_archives.py <execRepo> <localBackupDir> <offDeviceDir> <out.json>"""
import hashlib, json, os, sys, zipfile, ctypes
R, BK, OFF, out = sys.argv[1:5]


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


A = {  # archive -> (sha256, record path relative to repo or None)
    'NewMetacomp_G2_LP2A3_Records_20261126.zip': (None, None),
    'NewMetacomp_G2_LP2B1_Geometry_20261126.zip': ('5a5a4179c987d04dcf14cf3d2552b8f9f1d9c370c370b0a6bd6c930748bbbd42', None),
    'NewMetacomp_G2_LP2B1EQ_Readiness_20261126.zip': ('2187ec2cbb36fb7d1e8fb311ef41fa918e9822a6277f3a6d98dbcf97e6867c24', None),
    'NewMetacomp_G2_LP2B1EQ_Campaign_20261127.zip': ('1d739f80fe77597e3749de7e939abf8f572bc48f27bb703c28d02f94634d6e8a', None),
    'NewMetacomp_G2_LP2B1S10_Readiness_20261127.zip': ('c21ead0996f6e29d83c1b2b0c14ce530ce1c5dff727d487125a49fad7cb42e37',
                                                        'docs/research/G2_LP2B1S10_evidence/closure/LP2B1S10_ARCHIVE_RECORD.json'),
}
res = {'schema': 'NewMetacomp.G2.LP2B1S10.ArchiveCopies.v1', 'archives': {}}
for name, (exp, recp) in A.items():
    rec = json.load(open(os.path.join(R, *recp.split('/')), encoding='utf-8')) if recp else None
    r = {}
    for tag, d in (('local', BK), ('offDevice', OFF)):
        p = os.path.join(d, name); c = {'present': os.path.isfile(p)}
        if c['present']:
            c['sha256'] = fsha(p); c['bytes'] = os.path.getsize(p)
            if rec:
                with zipfile.ZipFile(p) as z:
                    ms = {i.filename: hashlib.sha256(z.read(i)).hexdigest() for i in z.infolist() if not i.is_dir()}
                c['members'] = len(ms); man = ms.pop('MANIFEST.sha256', None)
                c['manifestMemberSHA256OK'] = man == rec.get('manifestSHA256')   # the record pins the manifest member separately (attempt 1 defect)
                c['membersEqualRecord'] = ms == rec['memberSHA256'] and c['manifestMemberSHA256OK']
        r[tag] = c
    shas = {r[t].get('sha256') for t in r}
    r['bothPresent'] = all(r[t]['present'] for t in ('local', 'offDevice'))
    r['copiesIdentical'] = r['bothPresent'] and len(shas) == 1
    r['expectedSHA256'] = exp or (rec['sha256'] if rec else None)
    r['sha256OK'] = r['copiesIdentical'] and (exp is None or shas == {exp})
    if rec:
        r['recordSHA256'] = rec['sha256']; r['recordMembers'] = rec['members']
        r['pass'] = r['sha256OK'] and shas == {rec['sha256']} and all(r[t]['members'] == rec['members'] and r[t]['membersEqualRecord'] for t in ('local', 'offDevice'))
    else:
        r['pass'] = r['sha256OK']
    res['archives'][name] = r
drive = os.path.splitdrive(os.path.abspath(OFF))[0] + '\\'
res['offDeviceDriveType'] = ctypes.windll.kernel32.GetDriveTypeW(drive)
res['offDeviceRemovable'] = res['offDeviceDriveType'] == 2
res['pass'] = all(v['pass'] for v in res['archives'].values()) and res['offDeviceRemovable']
assert not os.path.exists(out), out
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
for k, v in res['archives'].items():
    print(k, v['pass'], v['local'].get('sha256', '')[:12], v.get('recordMembers', ''), v['local'].get('members', ''))
print('ARCHIVES', 'PASS' if res['pass'] else 'FAIL', 'removable', res['offDeviceRemovable'])
