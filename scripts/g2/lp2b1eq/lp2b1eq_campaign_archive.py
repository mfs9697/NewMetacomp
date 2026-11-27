"""Build and verify the LP2-B1-EQ CAMPAIGN archive (variant of lp2b1eq_archive.py: <outputsRels> is a comma-separated list
of folders and/or single files relative to the clone) (deterministic ZIP + SHA-256 manifest) and copy it to two devices.
Members: every file under <execRepo>/<outputsRel> and every file of the scratch evidence folder (published under logs/).
Existing archives are never overwritten; each copy is re-read and verified member by member.
usage: python lp2b1eq_campaign_archive.py <execRepo> <outputsRels> <scratchDir> <localDir> <offDeviceDir> <archiveName> <out.json>"""
import hashlib, json, os, shutil, sys, zipfile
ex, orel, sd, loc, off, name, out = sys.argv[1:8]


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


members = []
for rel in orel.split(','):
    base = os.path.join(ex, *rel.split('/'))
    if os.path.isfile(base):
        members.append((rel, base)); continue
    assert os.path.isdir(base), rel
    for d, _, fs in os.walk(base):
        for n in fs:
            p = os.path.join(d, n); members.append((os.path.relpath(p, ex).replace('\\', '/'), p))
nout = len(members)
for d, _, fs in os.walk(sd):
    if os.path.abspath(d).startswith(os.path.abspath(os.path.join(sd, 'archive'))):
        continue
    for n in fs:
        p = os.path.join(d, n); members.append(('logs/' + os.path.relpath(p, sd).replace('\\', '/'), p))
members.sort(); assert len({m for m, _ in members}) == len(members)
man = {m: fsha(p) for m, p in members}
mtxt = ''.join(f'{v}  {k}\n' for k, v in man.items())
tmp = os.path.join(sd, 'archive', name); os.makedirs(os.path.dirname(tmp), exist_ok=True); assert not os.path.exists(tmp), tmp
with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as z:
    for m, p in members:
        zi = zipfile.ZipInfo(m, date_time=(2026, 11, 27, 0, 0, 0)); zi.compress_type = zipfile.ZIP_DEFLATED
        z.writestr(zi, open(p, 'rb').read())
    z.writestr(zipfile.ZipInfo('MANIFEST.sha256', date_time=(2026, 11, 27, 0, 0, 0)), mtxt)
h = fsha(tmp)


def verify(p):
    if fsha(p) != h:
        return False
    with zipfile.ZipFile(p) as z:
        return all(hashlib.sha256(z.read(m)).hexdigest() == v for m, v in man.items())


res = {'schema': 'NewMetacomp.G2.LP2B1EQ.ArchiveRecord.v1', 'archive': name, 'sha256': h, 'bytes': os.path.getsize(tmp), 'members': len(man) + 1,
       'outputFiles': nout, 'logFiles': len(man) - nout, 'manifestSHA256': hashlib.sha256(mtxt.encode()).hexdigest(), 'memberSHA256': man}
for tag, dd in (('local', loc), ('offDevice', off)):
    dst = os.path.join(dd, name); assert not os.path.exists(dst), dst + ' exists'
    shutil.copyfile(tmp, dst); res[tag + 'CopyVerified'] = verify(dst)
res['pass'] = res['localCopyVerified'] and res['offDeviceCopyVerified']
assert not os.path.exists(out), out
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('archive', name, h, res['members'], 'members', 'outputs', nout, '| local', res['localCopyVerified'], '| off-device', res['offDeviceCopyVerified'])
