"""SHA-256 of every file under the protected output trees of the execution clone (read-only).
usage: python -I tree_hash.py <execRepo> <out.json>"""
import hashlib, json, os, sys
R, out = sys.argv[1], sys.argv[2]
roots = ['outputs/g2_a1_fixed_path_v1', 'outputs/g2_a1_campaign_ledger', 'outputs/g2_a1_geometry_v1',
         'outputs/g2_lp1_matrix_paths_v1', 'outputs/g2_lp1_campaign_ledger']
H = {}
for r in roots:
    for d, _, fs in os.walk(os.path.join(R, r)):
        for n in fs:
            p = os.path.join(d, n); h = hashlib.sha256()
            with open(p, 'rb') as fh:
                for b in iter(lambda: fh.read(1 << 20), b''):
                    h.update(b)
            H[os.path.relpath(p, R).replace('\\', '/')] = h.hexdigest()
H = dict(sorted(H.items()))
json.dump({'roots': roots, 'files': len(H), 'treeSHA256': hashlib.sha256('\n'.join(f'{k} {v}' for k, v in H.items()).encode()).hexdigest(), 'hashes': H},
          open(out, 'w', encoding='utf-8'), indent=1)
q = sum(1 for k in H if not k.startswith('outputs/g2_lp1_campaign_ledger'))
print('files', len(H), 'of which qualification roots', q, 'tree', hashlib.sha256('\n'.join(f'{k} {v}' for k, v in H.items()).encode()).hexdigest()[:16])
