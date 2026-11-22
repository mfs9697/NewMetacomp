"""Independent (non-MATLAB) recomputation of the A1 pins from git blobs at a commit (LF bytes)."""
import hashlib, json, subprocess, sys
repo, rev = sys.argv[1], sys.argv[2]
def blob(p):
    return subprocess.run(['git', '-C', repo, 'show', f'{rev}:{p}'], capture_output=True, check=True).stdout
def ls(prefix):
    out = subprocess.run(['git', '-C', repo, 'ls-tree', '--name-only', f'{rev}:{prefix}'], capture_output=True, check=True, text=True).stdout
    return [n for n in out.splitlines() if n.endswith('.m')]
h = lambda b: hashlib.sha256(b).hexdigest()
rels = sorted(ls('matlab/g2') + ['vendor_p010_a14d8872/' + n for n in ls('matlab/g2/vendor_p010_a14d8872')])
lines = [f"{r} {h(blob('matlab/g2/' + r))}" for r in rels]
src = h('\n'.join(lines).encode('utf-8'))
polb = blob('matlab/g2/G2_A1_POLICY_v1.json'); pol = json.loads(polb)
man = h('\n'.join(f"{k} {pol['meshes'][k]['contentSHA256']}" for k in sorted(pol['meshes'])).encode('utf-8'))
ps = h(polb)
tok = f'G2A1|policy={ps}|source={src}|meshes={man}|cases=H,stiff13,soft2,soft1|levels=3,6,9|maxSolves=12'
con = h(blob('matlab/g2/evidence/a1_preflight/batch_6a3a14d/CONTRACT_TESTS.json'))
exp = {'policy': '312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013',
       'source': '7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947',
       'meshes': 'ffee15fd508b5b13e78850cefd88e7d0b04308f70c468c0c1e85f7f78a0ecbc5',
       'contract': '06ef678ed387d1c3ecfbb105a8a8609aa0248f16d68c8067faed69877f82f3de'}
got = {'policy': ps, 'source': src, 'meshes': man, 'contract': con}
for k in exp: print(f"{k:9s} {got[k]} {'MATCH' if got[k] == exp[k] else 'MISMATCH'}")
print('nSourceFiles', len(rels))
ct = json.loads(blob('matlab/g2/evidence/a1_preflight/batch_6a3a14d/CONTRACT_TESTS.json'))
print('contract', ct['pass'], ct['passed'], ct['total'], ct['physicalSolves'], ct['negativeTestsPassed'])
print('TOKEN', tok)
print('ALL_MATCH', all(got[k] == exp[k] for k in exp))
