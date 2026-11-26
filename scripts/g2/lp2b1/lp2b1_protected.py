"""Read-only protected-record check for LP2-B1 (zero writes under the clone).
832 known files = the 723 LP2-A3-protected files (committed manifest LP2A3_PROTECTED_MANIFEST.json, digest 44c54678...)
+ the 109 LP2-A3 run/ledger files (G2-LP2A3-001), independently checked for disjointness. The 109 are compared with
(a) the committed archive record member manifest and (b) SHA-256 values recomputed from the member BYTES inside each
archive copy (local SSD and removable device), whose file SHA-256 must equal e089d749.... Additional relevant
records: outputs/LP2A3_CAMPAIGN.json (archive member) and the LP2-B1 pins file. Optionally compares with a previous
run of this script (before/after) and refuses any overlap of a new LP2-B1 output root with a protected path.
usage: python -I lp2b1_protected.py <execRepo> <A3ProtectedManifest.json> <A3ArchiveRecord.json> <localZip> <offDeviceZip>
                                     <pins.json> <out.json> [<manifestOut.json>] [<previousOut.json>]"""
import hashlib, json, os, sys, zipfile
R, a3man, a3arc, zl, zo, pinsf, out = sys.argv[1:8]
mout = sys.argv[8] if len(sys.argv) > 8 and sys.argv[8] != '-' else None
prev = sys.argv[9] if len(sys.argv) > 9 else None
ARCH = 'e089d749737f6c5259e6ad391c785b6ac222a636ca4716aaefbbde2fd5186dc6'
A3DIG = '44c54678607fa2ed77b29eac59e7caa8b527c51b6e60d8133550906c82d7e02f'


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as fh:
        for b in iter(lambda: fh.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


dig = lambda d: hashlib.sha256('\n'.join(f'{k} {v}' for k, v in sorted(d.items())).encode()).hexdigest()
M = json.load(open(a3man, encoding='utf-8'))
ref723 = M['hashes']
cur723 = {k: fsha(os.path.join(R, *k.split('/'))) if os.path.isfile(os.path.join(R, *k.split('/'))) else None for k in ref723}
ok723 = cur723 == ref723 and len(ref723) == 723 and M['manifestSHA256'] == A3DIG == dig(ref723)
cur109 = {}
for r in ('outputs/g2_lp2a3_paths_v1', 'outputs/g2_lp2a3_campaign_ledger'):
    for d, _, fs in os.walk(os.path.join(R, *r.split('/'))):
        for n in fs:
            p = os.path.join(d, n); cur109[os.path.relpath(p, R).replace('\\', '/')] = fsha(p)
A = json.load(open(a3arc, encoding='utf-8'))
rec109 = {k: v.lower() for k, v in A['memberSHA256'].items() if k.startswith('outputs/g2_lp2a3_')}
zres = {}
for tag, z in (('local', zl), ('offDevice', zo)):
    e = {'path_present': os.path.isfile(z)}
    if e['path_present']:
        e['sha256'] = fsha(z); e['shaOK'] = e['sha256'] == ARCH
        with zipfile.ZipFile(z) as Z:
            mem = {i.filename: hashlib.sha256(Z.read(i)).hexdigest() for i in Z.infolist() if not i.is_dir()}
        e['members'] = len(mem)
        e['memberBytesEqualRecord'] = all(mem.get(k) == v.lower() for k, v in A['memberSHA256'].items())
        e['run109EqualMemberBytes'] = all(mem.get(k) == v for k, v in cur109.items())
        e['campaignSummaryEqual'] = mem.get('outputs/LP2A3_CAMPAIGN.json') == fsha(os.path.join(R, 'outputs', 'LP2A3_CAMPAIGN.json'))
        e['pass'] = e['shaOK'] and e['members'] == 135 and e['memberBytesEqualRecord'] and e['run109EqualMemberBytes'] and e['campaignSummaryEqual']
    else:
        e['pass'] = False
    zres[tag] = e
ok109 = len(cur109) == 109 and cur109 == rec109
disj = not (set(cur723) & set(cur109))
allm = dict(sorted({**ref723, **cur109}.items()))
pins = json.load(open(pinsf, encoding='utf-8'))
extra = {'outputs/LP2A3_CAMPAIGN.json': fsha(os.path.join(R, 'outputs', 'LP2A3_CAMPAIGN.json'))}
extra_ok = extra['outputs/LP2A3_CAMPAIGN.json'] == pins['lp2a3']['campaignSummary']['sha256'] == A['memberSHA256'].get('outputs/LP2A3_CAMPAIGN.json', '').lower()
newroots = [d for d in os.listdir(os.path.join(R, 'outputs')) if d.startswith('g2_lp2b1')]
overlap = [k for k in allm if any(k.startswith('outputs/' + d + '/') for d in newroots)]
res = {'schema': 'NewMetacomp.G2.LP2B1.ProtectedCheck.v1',
       'a3ProtectedFiles': len(ref723), 'a3ProtectedUnchanged': ok723, 'a3ProtectedMissingOrChanged': sorted(k for k in ref723 if cur723[k] != ref723[k]),
       'a3RunLedgerFiles': len(cur109), 'a3RunLedgerEqualArchiveRecord': ok109,
       'a3RunLedgerChanged': sorted(set(rec109) ^ set(cur109) | {k for k in cur109 if rec109.get(k) != cur109[k]}),
       'setsDisjoint': disj, 'totalKnownProtectedFiles': len(allm), 'knownManifestSHA256': dig(allm),
       'archiveCopies': zres, 'additional': extra, 'additionalOK': extra_ok, 'lp2b1OutputRoots': newroots, 'overlapWithProtected': overlap}
res['pass'] = ok723 and ok109 and disj and len(allm) == 832 and all(z['pass'] for z in zres.values()) and extra_ok and not overlap
if prev:
    P = json.load(open(prev, encoding='utf-8'))
    res['previousManifestSHA256'] = P['knownManifestSHA256']; res['unchangedSincePrevious'] = P['knownManifestSHA256'] == res['knownManifestSHA256']
    res['pass'] = res['pass'] and res['unchangedSincePrevious']
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
if mout:
    json.dump({'schema': 'NewMetacomp.G2.LP2B1.KnownProtectedManifest.v1', 'files': len(allm), 'manifestSHA256': res['knownManifestSHA256'], 'hashes': allm},
              open(mout, 'w', encoding='utf-8', newline='\n'), indent=1)
print('a3', len(ref723), ok723, '| run/ledger', len(cur109), ok109, '| disjoint', disj, '| total', len(allm),
      '| archives', {k: v['pass'] for k, v in zres.items()}, '| extra', extra_ok, '| overlap', len(overlap), 'PASS' if res['pass'] else 'FAIL')
