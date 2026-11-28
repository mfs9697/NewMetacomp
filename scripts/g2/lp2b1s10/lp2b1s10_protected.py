"""Read-only protected-record check for LP2-B1-S10 readiness (zero writes under the clone). Backup locations are arguments.
1. The accepted LP2-B1-EQ checker scripts/g2/lp2b1eq/lp2b1eq_protected.py is run UNCHANGED (subprocess). Its readiness-only
   predicate "LP2-B1-EQ roots absent" is obsolete after the accepted campaign; it is NOT satisfied by moving records. Required
   instead: every protection subcheck passes (832 known files e756d64a..., both LP2-A3 archive copies, campaign summary,
   43 LP2-B1 outputs against both LP2-B1 archive copies, LP2-B1-EQ pinned files), its combined union is exactly the accepted
   891 files with manifest e351f5ac..., and the absence pattern is exactly {run root present, receipt root present,
   summary present, GO absent}.
2. The 23 LP2-B1-EQ campaign outputs (outputs/g2_lp2b1_eq_v1, outputs/g2_lp2b1_eq_receipts, outputs/LP2B1EQ_CAMPAIGN.json)
   against the committed campaign archive record AND the member bytes inside both copies of the campaign archive
   (1d739f80..., 136 members); disjointness from the 891.
3. Every file pinned by the LP2-B1-S10 policy re-hashed and equal to its pin.
4. Unique union 891 + 23 + S10 pins (explicit set union; count and manifest digest).
5. LP2-B1-S10 run/receipt roots, summary and GO absent; readiness outputs outside every protected path.
6. Both copies of the LP2-B1-EQ readiness archive (2187ec2c...); off-device root is a removable drive (Windows drive type 2).
7. Optional previous-run comparison (before/after): identical union manifest.
usage: python lp2b1s10_protected.py <execRepo> <out.json> <localBackupDir> <offDeviceDir> [<previousOut.json>]"""
import ctypes, hashlib, json, os, subprocess, sys, zipfile
R, out, BK, OFF = sys.argv[1:5]
prev = sys.argv[5] if len(sys.argv) > 5 else None
EQZIP = 'NewMetacomp_G2_LP2B1EQ_Campaign_20261127.zip'; EQSHA = '1d739f80fe77597e3749de7e939abf8f572bc48f27bb703c28d02f94634d6e8a'
RDZIP = 'NewMetacomp_G2_LP2B1EQ_Readiness_20261126.zip'; RDSHA = '2187ec2cbb36fb7d1e8fb311ef41fa918e9822a6277f3a6d98dbcf97e6867c24'
U891 = 'e351f5aca3629da34f99bd25e738bba33ea515ad6d4b6dc7c848bcb4e975d054'


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as fh:
        for b in iter(lambda: fh.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


J = lambda p: json.load(open(os.path.join(R, *p.split('/')), encoding='utf-8'))
dig = lambda d: hashlib.sha256('\n'.join(f'{k} {v}' for k, v in sorted(d.items())).encode()).hexdigest()
# ---- 1 unchanged LP2-B1-EQ checker
tmp = out + '.lp2b1eq_part.json'; assert not os.path.exists(tmp), tmp
pr = subprocess.run([sys.executable, os.path.join(R, 'scripts', 'g2', 'lp2b1eq', 'lp2b1eq_protected.py'), R, tmp], capture_output=True, text=True)
E = json.load(open(tmp, encoding='utf-8')); os.remove(tmp)
expAbsent = {'outputs/g2_lp2b1_eq_v1/run_lp2b1_eq_v1': False, 'outputs/g2_lp2b1_eq_receipts/G2-LP2B1-EQ-001': False,
             'matlab/g2/lp2b1eq/G2_LP2B1EQ_GO.json': True, 'outputs/LP2B1EQ_CAMPAIGN.json': False}
eqSub = {'lp2b1CheckerPass': E['lp2b1CheckerPass'], 'known832OK': E['known832OK'], 'lp2a3ArchiveCopies': all(E['lp2a3ArchiveCopies'].values()),
         'campaignSummaryOK': E['campaignSummaryOK'], 'b1OutputsEqualArchiveRecord': E['b1OutputsEqualArchiveRecord'], 'b1OutputsDisjointFrom832': E['b1OutputsDisjointFrom832'],
         'b1ArchiveCopies': all(v['pass'] for v in E['b1ArchiveCopies'].values()), 'policyPinnedUnchanged': E['policyPinnedUnchanged'],
         'union891': E['combinedFiles'] == 891 and E['combinedManifestSHA256'] == U891, 'absencePatternPostCampaign': E['eqRootsAndGoAbsent'] == expAbsent,
         'noOverlapWithProtected': not E['overlapWithProtected']}
# rebuild the 891 union exactly as the accepted checker (known 832 manifest + 43 B1 outputs + B1EQ pinned files)
K832 = J('docs/research/G2_LP2B1_evidence/closure/LP2B1_KNOWN_PROTECTED_MANIFEST.json')['hashes']
cur43 = {}
for d, _, fs in os.walk(os.path.join(R, 'outputs', 'g2_lp2b1_geometry_v1')):
    for n in fs:
        p = os.path.join(d, n); cur43[os.path.relpath(p, R).replace('\\', '/')] = fsha(p)


def pinsOf(pol):
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
    walk(pol); return pins


cur = lambda k: fsha(os.path.join(R, *k.split('/'))) if os.path.isfile(os.path.join(R, *k.split('/'))) else None
eqp = pinsOf(J('matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json'))
u891 = dict(sorted({**K832, **cur43, **{k: v for k, v in ((k, cur(k)) for k in eqp) if v}}.items()))
eqSub['union891Rebuilt'] = len(u891) == 891 and dig(u891) == U891
# ---- 2 23 LP2-B1-EQ campaign outputs
AR = J('docs/research/G2_LP2B1EQ_evidence/campaign/post/LP2B1EQ_CAMPAIGN_ARCHIVE_RECORD.json')
rec23 = {k: v for k, v in AR['memberSHA256'].items() if k.startswith('outputs/')}
cur23 = {}
for root in ('outputs/g2_lp2b1_eq_v1', 'outputs/g2_lp2b1_eq_receipts'):
    for d, _, fs in os.walk(os.path.join(R, *root.split('/'))):
        for n in fs:
            p = os.path.join(d, n); cur23[os.path.relpath(p, R).replace('\\', '/')] = fsha(p)
cur23['outputs/LP2B1EQ_CAMPAIGN.json'] = cur('outputs/LP2B1EQ_CAMPAIGN.json')


def zipCheck(z, sha, rec, nmem, outputs):
    e = {'present': os.path.isfile(z)}
    if not e['present']:
        e['pass'] = False; return e
    e['sha256'] = fsha(z); e['shaOK'] = e['sha256'] == sha
    with zipfile.ZipFile(z) as Z:
        mem = {i.filename: hashlib.sha256(Z.read(i)).hexdigest() for i in Z.infolist() if not i.is_dir()}
    e['members'] = len(mem); e['memberBytesEqualRecord'] = rec is None or all(mem.get(k) == v for k, v in rec.items())
    e['outputsEqualMemberBytes'] = all(mem.get(k) == v for k, v in outputs.items())
    e['pass'] = e['shaOK'] and (nmem is None or e['members'] == nmem) and e['memberBytesEqualRecord'] and e['outputsEqualMemberBytes']
    return e


z23 = {t: zipCheck(os.path.join(d, EQZIP), EQSHA, AR['memberSHA256'], 136, cur23) for t, d in (('local', BK), ('offDevice', OFF))}
ok23 = len(cur23) == 23 == AR['outputFiles'] and cur23 == rec23 and AR['sha256'] == EQSHA
disj23 = not (set(cur23) & set(u891))
# ---- 3 S10 policy pins
s10p = pinsOf(J('matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json'))
curS = {k: cur(k) for k in s10p}; okS = curS == s10p
# ---- 4 union
union = dict(sorted({**u891, **cur23, **{k: v for k, v in curS.items() if v}}.items()))
# ---- 5 roots, 6 readiness archive and drive type
pol = J('matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json'); au = pol['authorization']
absent = {p: not os.path.exists(os.path.join(R, *p.split('/'))) for p in (au['runRoot'], au['receiptRoot'], au['goPath'], au['summaryPath'], 'outputs/g2_lp2b1_s10_v1', 'outputs/g2_lp2b1_s10_receipts')}
newroots = [d for d in os.listdir(os.path.join(R, 'outputs')) if d.startswith('g2_lp2b1s10') or d.startswith('g2_lp2b1_s10')]
overlap = [k for k in union if any(k.startswith('outputs/' + d + '/') for d in newroots)]
zr = {t: zipCheck(os.path.join(d, RDZIP), RDSHA, None, 181, {}) for t, d in (('local', BK), ('offDevice', OFF))}
dt = ctypes.windll.kernel32.GetDriveTypeW(os.path.splitdrive(os.path.abspath(OFF))[0] + '\\') if os.name == 'nt' else -1
res = {'schema': 'NewMetacomp.G2.LP2B1S10.ProtectedCheck.v1', 'lp2b1eqCheckerExit': pr.returncode, 'lp2b1eqCheckerStdout': pr.stdout.strip(),
       'lp2b1eqSubchecks': eqSub, 'lp2b1eqOverallFlagReadinessOnly': E['pass'], 'lp2b1eqAbsence': E['eqRootsAndGoAbsent'],
       'union891Files': len(u891), 'union891ManifestSHA256': dig(u891),
       'eqCampaignOutputs': len(cur23), 'eqCampaignOutputsEqualRecord': ok23, 'eqCampaignOutputsChanged': sorted(k for k in set(cur23) | set(rec23) if cur23.get(k) != rec23.get(k)),
       'eqCampaignOutputsDisjointFrom891': disj23, 'eqCampaignArchiveCopies': z23, 'eqReadinessArchiveCopies': zr,
       's10PolicyPinnedFiles': len(s10p), 's10PolicyPinnedUnchanged': okS, 's10PolicyPinnedChanged': sorted(k for k in s10p if curS[k] != s10p[k]),
       's10PinsAlreadyIn891Or23': sum(1 for k in s10p if k in u891 or k in cur23),
       'unionFiles': len(union), 'unionManifestSHA256': dig(union), 'unionFormula': 'set union of the accepted 891, the 23 LP2-B1-EQ campaign outputs and the LP2-B1-S10 policy pins',
       's10RootsAndGoAbsent': absent, 'readinessRoots': newroots, 'overlapWithProtected': overlap,
       'backupLocal': os.path.isdir(BK), 'offDeviceDriveType': dt, 'offDeviceRemovable': dt == 2}
res['pass'] = (all(eqSub.values()) and ok23 and disj23 and all(e['pass'] for e in z23.values()) and all(e['pass'] for e in zr.values()) and okS
               and all(absent.values()) and not overlap and res['offDeviceRemovable'] and len(u891) + len(cur23) == 914)
if prev:
    Pp = json.load(open(prev, encoding='utf-8'))
    res['previousUnionManifestSHA256'] = Pp['unionManifestSHA256']; res['unchangedSincePrevious'] = Pp['unionManifestSHA256'] == res['unionManifestSHA256']
    res['pass'] = res['pass'] and res['unchangedSincePrevious']
assert not os.path.exists(out), out
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('891', eqSub['union891'] and eqSub['union891Rebuilt'], '| eq subchecks', all(eqSub.values()), '| 23', ok23, {k: v['pass'] for k, v in z23.items()}, '| disjoint', disj23,
      '| s10 pins', len(s10p), okS, '| union', len(union), res['unionManifestSHA256'][:12], '| absent', all(absent.values()), '| removable', res['offDeviceRemovable'],
      'PASS' if res['pass'] else 'FAIL')
