"""Read-only check and manifest of the protected historical records for LP2-A3 (zero writes under the clone).
723 = 541 files of the protected qualification/ledger trees (tree SHA-256 20f2d54f...) + 158 LP2-A1 run/ledger files
(including the four S8 parents and TERMINAL records) + 24 WP5 equivalence record files (activation A2).
The three sets are disjoint; the manifest lists every path once with its SHA-256.
usage: python -I lp2a3_protected.py <execRepo> <LP2_PROTECTED_AFTER.json> <LP2A_RUN_LEDGER_SHA256.json> <LP2A2_EQ_A2_ARCHIVE_RECORD.json> <out.json> [<manifestOut.json>]"""
import hashlib, json, os, sys
R, tree_ref, led_ref, arc_ref, out = sys.argv[1:6]
mout = sys.argv[6] if len(sys.argv) > 6 else None
EXPECT_TREE = '20f2d54fb59395f373b7c7f7ea4437d69fbdf3be8a8710b96077881c049218ef'
EXPECT_ARCHIVE = '96ed7a364d8742542244ab4003c754c139f437c5e1c41d80a25dbf0dad9675ea'


def fsha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as fh:
        for b in iter(lambda: fh.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def walk(roots):
    H = {}
    for r in roots:
        for d, _, fs in os.walk(os.path.join(R, r)):
            for n in fs:
                p = os.path.join(d, n)
                H[os.path.relpath(p, R).replace('\\', '/')] = fsha(p)
    return dict(sorted(H.items()))


T = json.load(open(tree_ref, encoding='utf-8')); cur = walk(T['roots'])
tree = hashlib.sha256('\n'.join(f'{k} {v}' for k, v in cur.items()).encode()).hexdigest()
tree_ok = (cur == T['hashes']) and tree == EXPECT_TREE == T['treeSHA256']
L = json.load(open(led_ref, encoding='utf-8')); cur2 = walk(['outputs/g2_lp2a_paths_v1', 'outputs/g2_lp2a_campaign_ledger']); led_ok = cur2 == L
A = json.load(open(arc_ref, encoding='utf-8')); ref3 = {k: v for k, v in A['memberSHA256'].items() if k.startswith('outputs/g2_lp2a2_eq_v1/')}
cur3 = walk(['outputs/g2_lp2a2_eq_v1']); wp5_ok = cur3 == ref3 and len(cur3) == 24 and A['sha256'] == EXPECT_ARCHIVE
disjoint = not (set(cur) & set(cur2)) and not (set(cur) & set(cur3)) and not (set(cur2) & set(cur3))
allm = dict(sorted({**cur, **cur2, **cur3}.items()))
res = {'schema': 'NewMetacomp.G2.LP2A3.ProtectedCheck.v1',
       'protectedTreeFiles': len(cur), 'protectedTreeSHA256': tree, 'protectedTreeEqualsReference': tree_ok,
       'lp2a1RunLedgerFiles': len(cur2), 'lp2a1RunLedgerEqualsManifest': led_ok,
       'wp5RecordFiles': len(cur3), 'wp5RecordsEqualArchiveRecord': wp5_ok, 'setsDisjoint': disjoint,
       'totalProtectedFiles': len(allm), 'manifestSHA256': hashlib.sha256('\n'.join(f'{k} {v}' for k, v in allm.items()).encode()).hexdigest()}
res['pass'] = tree_ok and led_ok and wp5_ok and disjoint and len(allm) == 723
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
if mout:
    json.dump({'schema': 'NewMetacomp.G2.LP2A3.ProtectedManifest.v1', 'files': len(allm), 'manifestSHA256': res['manifestSHA256'], 'hashes': allm},
              open(mout, 'w', encoding='utf-8', newline='\n'), indent=1)
print('tree', len(cur), tree_ok, '| lp2a1', len(cur2), led_ok, '| wp5', len(cur3), wp5_ok, '| total', len(allm), 'PASS' if res['pass'] else 'FAIL')
