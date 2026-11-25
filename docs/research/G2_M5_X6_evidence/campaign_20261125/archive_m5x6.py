"""Build and verify the M5-X6 campaign archive (deterministic ZIP + SHA-256 manifest), then copy and verify.
usage: python -I archive_m5x6.py <execRepo> <runDir(scratch)> <localDir> <offDeviceDir> <out.json>"""
import hashlib, json, os, shutil, sys, zipfile
ex, rdir, loc, off, out = sys.argv[1:6]
name = 'NewMetacomp_G2_M5X6_Records_20261125.zip'
sha = lambda b: hashlib.sha256(b).hexdigest()
def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''): h.update(b)
    return h.hexdigest()
members = []
for root in ('outputs/g2_m5x6_crossed_v1', 'outputs/g2_m5x6_campaign_ledger'):
    for d, _, fs in os.walk(os.path.join(ex, root)):
        for n in fs:
            p = os.path.join(d, n); members.append((os.path.relpath(p, ex).replace('\\', '/'), p))
for n in ('m5x6_campaign.log', 'm5x6_verify_analyze.log', 'activation_checks.log', 'campaign/M5X6_CALLS.json', 'verify/M5X6_VERIFY_ONLY.json',
          'verify/M5X6_ANALYSIS.json', 'activation/ACTIVATION_CHECKS.json', 'activation/ACT_DIAGONAL_AUDIT.json', 'PROTECTED_BEFORE.json',
          'PROTECTED_AFTER.json', 'ACTIVATION_HASHCHECK.json', 'campaign_attempt0/precheck_refused.log'):
    members.append(('logs/' + n, os.path.join(rdir, n)))
members.sort()
man = {m: fsha(p) for m, p in members}
manifest = '\n'.join(f'{v}  {k}' for k, v in man.items()) + '\n'
tmp = os.path.join(rdir, name)
with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as z:
    for m, p in members:
        zi = zipfile.ZipInfo(m, date_time=(2026, 11, 25, 0, 0, 0)); zi.compress_type = zipfile.ZIP_DEFLATED
        z.writestr(zi, open(p, 'rb').read())
    zi = zipfile.ZipInfo('MANIFEST_SHA256.txt', date_time=(2026, 11, 25, 0, 0, 0)); zi.compress_type = zipfile.ZIP_DEFLATED
    z.writestr(zi, manifest.encode())
zsha = fsha(tmp)
def verify(path):
    ok = fsha(path) == zsha
    with zipfile.ZipFile(path) as z:
        ok = ok and z.testzip() is None and all(sha(z.read(m)) == h for m, h in man.items())
    return ok
res = {'archive': name, 'sha256': zsha, 'bytes': os.path.getsize(tmp), 'members': len(members) + 1,
       'runAndLedgerFiles': sum(1 for m, _ in members if m.startswith('outputs/')), 'manifestSHA256': sha(manifest.encode())}
for label, d in (('local', loc), ('offDevice', off)):
    os.makedirs(d, exist_ok=True); dst = os.path.join(d, name)
    assert not os.path.exists(dst), dst + ' exists'
    shutil.copyfile(tmp, dst); res[label + 'CopyVerified'] = verify(dst)
res['scratchCopyVerified'] = verify(tmp)
res['memberSHA256'] = man
json.dump(res, open(out, 'w', encoding='utf-8'), indent=1)
print('ARCHIVE', zsha, res['bytes'], 'members', res['members'], 'local', res['localCopyVerified'], 'off', res['offDeviceCopyVerified'])
