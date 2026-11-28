"""Final protected-record adjudication at the evidence head: the unchanged readiness checker output (overall flag readiness-only)
plus (a) every protection subcheck, (b) union 918 unchanged, (c) exact post-campaign absence pattern, (d) the 16 LP2-B1-S10 campaign
outputs currently on disk equal the members recorded in the campaign archive record and the bytes inside both archive copies.
usage: python -I adjudicate_final.py <execRepo> <checkerOut.json> <archiveRecord.json> <localBackupDir> <offDeviceDir> <out.json>"""
import hashlib, json, os, sys, zipfile
R, cp, ap, BK, OFF, out = sys.argv[1:7]


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


d = json.load(open(cp, encoding='utf-8')); ar = json.load(open(ap, encoding='utf-8'))
exp = {'outputs/g2_lp2b1_s10_v1/run_lp2b1_s10_v1': False, 'outputs/g2_lp2b1_s10_receipts/G2-LP2B1-S10-001': False, 'matlab/g2/lp2b1s10/G2_LP2B1S10_GO.json': True,
       'outputs/LP2B1S10_CAMPAIGN.json': False, 'outputs/g2_lp2b1_s10_v1': False, 'outputs/g2_lp2b1_s10_receipts': False}
cur = {}
for root in ('outputs/g2_lp2b1_s10_v1', 'outputs/g2_lp2b1_s10_receipts'):
    for dd, _, fs in os.walk(os.path.join(R, *root.split('/'))):
        for n in fs:
            p = os.path.join(dd, n); cur[os.path.relpath(p, R).replace('\\', '/')] = fsha(p)
cur['outputs/LP2B1S10_CAMPAIGN.json'] = fsha(os.path.join(R, 'outputs', 'LP2B1S10_CAMPAIGN.json'))
recOut = {k: v for k, v in ar['memberSHA256'].items() if k.startswith('outputs/')}
inZip = {}
for tag, dev in (('local', BK), ('offDevice', OFF)):
    z = os.path.join(dev, ar['archive']); ok = fsha(z) == ar['sha256']
    with zipfile.ZipFile(z) as zz:
        inZip[tag] = ok and all(hashlib.sha256(zz.read(k)).hexdigest() == v for k, v in cur.items())
sub = {'lp2b1eqSubchecks': all(d['lp2b1eqSubchecks'].values()), 'union891': d['union891Files'] == 891 and d['union891ManifestSHA256'].startswith('e351f5ac'),
       'eqCampaignOutputs23': d['eqCampaignOutputs'] == 23 and d['eqCampaignOutputsEqualRecord'] and not d['eqCampaignOutputsChanged'] and d['eqCampaignOutputsDisjointFrom891'],
       'eqArchives': all(v['pass'] for v in d['eqCampaignArchiveCopies'].values()),
       's10Pins': d['s10PolicyPinnedFiles'] == 60 and d['s10PolicyPinnedUnchanged'] and not d['s10PolicyPinnedChanged'],
       'union918Unchanged': d['unionFiles'] == 918 and d['unionManifestSHA256'] == 'e1ed9be06011cb3e430386ce193b36ea2e779afb8d89e8eee610c60ad94b2d39' and d['unchangedSincePrevious'],
       'noOverlap': not d['overlapWithProtected'], 'removable': d['offDeviceRemovable'] and d['backupLocal'],
       'absencePatternPostCampaign': d['s10RootsAndGoAbsent'] == exp,
       's10CampaignOutputs16EqualArchiveRecord': len(cur) == 16 and cur == recOut, 's10CampaignOutputsEqualBytesInBothArchiveCopies': all(inZip.values())}
res = {'schema': 'NewMetacomp.G2.LP2B1S10.ProtectedFinalAdjudication.v1', 'checkerOutput': os.path.basename(cp), 'checkerOutputSHA256': fsha(cp),
       'checkerOverallFlagReadinessOnly': d['pass'], 'archive': ar['archive'], 'archiveSHA256': ar['sha256'], 's10CampaignOutputs': len(cur), 'subchecks': sub, 'pass': all(sub.values())}
assert not os.path.exists(out), out
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print(sub, 'PASS' if res['pass'] else 'FAIL')
