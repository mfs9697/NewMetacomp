"""Read-only check of the protected historical records of the LP2-A2 equivalence campaign (zero writes under the execution clone).
 699 = 541 files of the protected qualification/ledger trees (tree SHA-256 20f2d54f...) + 158 LP2-A1 run/ledger files.
usage: python -I lp2a2_eq_protected.py <execRepo> <LP2_PROTECTED_AFTER.json> <LP2A_RUN_LEDGER_SHA256.json> <out.json>"""
import hashlib, json, os, sys
R, tree_ref, led_ref, out = sys.argv[1:5]
EXPECT_TREE = '20f2d54fb59395f373b7c7f7ea4437d69fbdf3be8a8710b96077881c049218ef'


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


T = json.load(open(tree_ref, encoding='utf-8'))
cur = walk(T['roots'])
tree = hashlib.sha256('\n'.join(f'{k} {v}' for k, v in cur.items()).encode()).hexdigest()
tree_ok = (cur == T['hashes']) and tree == EXPECT_TREE == T['treeSHA256']
L = json.load(open(led_ref, encoding='utf-8'))
cur2 = walk(['outputs/g2_lp2a_paths_v1', 'outputs/g2_lp2a_campaign_ledger'])
led_ok = cur2 == L
res = {'schema': 'NewMetacomp.G2.LP2A2.EQ.ProtectedCheck.v1',
       'protectedTreeFiles': len(cur), 'protectedTreeSHA256': tree, 'protectedTreeEqualsReference': tree_ok,
       'lp2a1RunLedgerFiles': len(cur2), 'lp2a1RunLedgerEqualsManifest': led_ok,
       'extraFilesInLp2a1Roots': sorted(set(cur2) - set(L)), 'missingFilesInLp2a1Roots': sorted(set(L) - set(cur2)),
       'changedFilesInLp2a1Roots': sorted(k for k in set(cur2) & set(L) if cur2[k] != L[k]),
       'totalProtectedFiles': len(cur) + len(cur2)}
res['pass'] = tree_ok and led_ok and res['totalProtectedFiles'] == 699
json.dump(res, open(out, 'w', encoding='utf-8', newline='\n'), indent=1)
print('tree', len(cur), tree[:16], tree_ok, '| lp2a1', len(cur2), led_ok, '| total', res['totalProtectedFiles'], 'PASS' if res['pass'] else 'FAIL')
