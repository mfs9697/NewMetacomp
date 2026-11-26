"""Read-only protected-record check for LP2-B1-EQ (zero writes under the clone).
1. The accepted LP2-B1 checker scripts/g2/lp2b1/lp2b1_protected.py is run UNCHANGED (subprocess): 832 known files
   (723 LP2-A3-protected + 109 LP2-A3 run/ledger), both LP2-A3 archive copies member by member, campaign summary.
2. The 43 LP2-B1 output files (outputs/g2_lp2b1_geometry_v1) against the committed LP2-B1 archive record member
   manifest AND against SHA-256 values recomputed from the member BYTES inside both copies of the LP2-B1 archive
   (file SHA-256 5a5a4179...; 76 members); disjointness from the 832.
3. Every file pinned by the LP2-B1-EQ policy (policy files, contract, references, parents, next-tip sources,
   admissions, qualification arrays/records, committed evidence) re-hashed and equal to its pin.
4. The LP2-B1-EQ run/receipt roots and GO file absent (readiness); readiness outputs outside every protected path.
5. Optional previous-run comparison (before/after): identical combined manifest.
usage: python lp2b1eq_protected.py <execRepo> <out.json> [<previousOut.json>]"""
import hashlib, json, os, subprocess, sys, zipfile
R, out = sys.argv[1], sys.argv[2]
prev = sys.argv[3] if len(sys.argv) > 3 else None
BK = r'C:\Users\Mikhailo\Documents\NewMetacomp_LP1_archive_backup'; OFF = 'D:\\'
B1ZIP = 'NewMetacomp_G2_LP2B1_Geometry_20261126.zip'; B1SHA = '5a5a4179c987d04dcf14cf3d2552b8f9f1d9c370c370b0a6bd6c930748bbbd42'
A3ZIP = 'NewMetacomp_G2_LP2A3_Records_20261126.zip'
here = os.path.dirname(os.path.abspath(__file__))


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as fh:
        for b in iter(lambda: fh.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


J = lambda p: json.load(open(os.path.join(R, *p.split('/')), encoding='utf-8'))
dig = lambda d: hashlib.sha256('\n'.join(f'{k} {v}' for k, v in sorted(d.items())).encode()).hexdigest()
tmp = out + '.lp2b1_part.json'
assert not os.path.exists(tmp), tmp
cmd = [sys.executable, os.path.join(R, 'scripts', 'g2', 'lp2b1', 'lp2b1_protected.py'), R,
       os.path.join(R, 'docs', 'research', 'G2_LP2A3_evidence', 'LP2A3_PROTECTED_MANIFEST.json'),
       os.path.join(R, 'docs', 'research', 'G2_LP2A3_evidence', 'campaign', 'post', 'LP2A3_ARCHIVE_RECORD.json'),
       os.path.join(BK, A3ZIP), os.path.join(OFF, A3ZIP), os.path.join(R, 'matlab', 'g2', 'lp2b1', 'G2_LP2B1_PINS_v1.json'), tmp]
pr = subprocess.run(cmd, capture_output=True, text=True)
P832 = json.load(open(tmp, encoding='utf-8')); os.remove(tmp)
known = P832['knownManifestSHA256']
# ---- 43 LP2-B1 outputs
AR = J('docs/research/G2_LP2B1_evidence/closure/LP2B1_ARCHIVE_RECORD.json')
rec43 = {k: v for k, v in AR['memberSHA256'].items() if k.startswith('outputs/')}
cur43 = {}
for d, _, fs in os.walk(os.path.join(R, 'outputs', 'g2_lp2b1_geometry_v1')):
    for n in fs:
        p = os.path.join(d, n); cur43[os.path.relpath(p, R).replace('\\', '/')] = fsha(p)
z43 = {}
for tag, z in (('local', os.path.join(BK, B1ZIP)), ('offDevice', os.path.join(OFF, B1ZIP))):
    e = {'present': os.path.isfile(z)}
    if e['present']:
        e['sha256'] = fsha(z); e['shaOK'] = e['sha256'] == B1SHA == AR['sha256']
        with zipfile.ZipFile(z) as Z:
            mem = {i.filename: hashlib.sha256(Z.read(i)).hexdigest() for i in Z.infolist() if not i.is_dir()}
        e['members'] = len(mem); e['memberBytesEqualRecord'] = all(mem.get(k) == v for k, v in AR['memberSHA256'].items())
        e['outputs43EqualMemberBytes'] = all(mem.get(k) == v for k, v in cur43.items())
        e['pass'] = e['shaOK'] and e['members'] == AR['members'] == 76 and e['memberBytesEqualRecord'] and e['outputs43EqualMemberBytes']
    else:
        e['pass'] = False
    z43[tag] = e
K832 = json.load(open(os.path.join(R, 'docs', 'research', 'G2_LP2B1_evidence', 'closure', 'LP2B1_KNOWN_PROTECTED_MANIFEST.json'), encoding='utf-8'))['hashes']
ok43 = len(cur43) == 43 == AR['outputFiles'] and cur43 == rec43
disj = not (set(cur43) & set(K832))
# ---- every policy-pinned file
pol = J('matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json')
pins = {}


def walk(x):
    if isinstance(x, dict):
        if set(x.keys()) >= {'path', 'sha256'} and isinstance(x.get('path'), str) and isinstance(x.get('sha256'), str):
            pins[x['path']] = x['sha256'].lower()
        for v in x.values():
            walk(v)
    elif isinstance(x, list):
        for v in x:
            walk(v)


walk(pol)
curp = {k: (fsha(os.path.join(R, *k.split('/'))) if os.path.isfile(os.path.join(R, *k.split('/'))) else None) for k in pins}
okp = curp == pins
au = pol['authorization']
absent = {p: not os.path.exists(os.path.join(R, *p.split('/'))) for p in (au['runRoot'], au['receiptRoot'], au['goPath'], 'outputs/LP2B1EQ_CAMPAIGN.json')}
allm = dict(sorted({**K832, **cur43, **{k: v for k, v in curp.items() if v}}.items()))
newroots = [d for d in os.listdir(os.path.join(R, 'outputs')) if d.startswith('g2_lp2b1eq') or d.startswith('g2_lp2b1_eq')]
overlap = [k for k in allm if any(k.startswith('outputs/' + d + '/') for d in newroots)]
res = {'schema': 'NewMetacomp.G2.LP2B1EQ.ProtectedCheck.v1', 'lp2b1CheckerPass': P832['pass'], 'lp2b1CheckerExit': pr.returncode,
       'lp2b1CheckerStdout': pr.stdout.strip(), 'known832ManifestSHA256': known, 'known832Expected': 'e756d64aee23adde0ea4a1662d0e9e77dbae3eb27c1195145a0056367fff1f35',
       'known832OK': known == 'e756d64aee23adde0ea4a1662d0e9e77dbae3eb27c1195145a0056367fff1f35' and P832['totalKnownProtectedFiles'] == 832,
       'lp2a3ArchiveCopies': {k: v['pass'] for k, v in P832['archiveCopies'].items()}, 'campaignSummaryOK': P832['additionalOK'],
       'b1Outputs': len(cur43), 'b1OutputsEqualArchiveRecord': ok43, 'b1OutputsChanged': sorted(k for k in set(cur43) | set(rec43) if cur43.get(k) != rec43.get(k)),
       'b1OutputsDisjointFrom832': disj, 'b1ArchiveCopies': z43, 'policyPinnedFiles': len(pins), 'policyPinnedUnchanged': okp,
       'policyPinnedChanged': sorted(k for k in pins if curp[k] != pins[k]), 'eqRootsAndGoAbsent': absent, 'readinessRoots': newroots, 'overlapWithProtected': overlap,
       'combinedFiles': len(allm), 'combinedManifestSHA256': dig(allm)}
res['pass'] = (P832['pass'] and res['known832OK'] and ok43 and disj and all(e['pass'] for e in z43.values()) and okp and all(absent.values()) and not overlap)
if prev:
    Pp = json.load(open(prev, encoding='utf-8'))
    res['previousCombinedManifestSHA256'] = Pp['combinedManifestSHA256']; res['unchangedSincePrevious'] = Pp['combinedManifestSHA256'] == res['combinedManifestSHA256']
    res['pass'] = res['pass'] and res['unchangedSincePrevious']
assert not os.path.exists(out), out
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('832', P832['pass'], known[:12], '| b1 43', ok43, {k: v['pass'] for k, v in z43.items()}, '| pinned', len(pins), okp, '| absent', all(absent.values()),
      '| combined', len(allm), res['combinedManifestSHA256'][:12], 'PASS' if res['pass'] else 'FAIL')
