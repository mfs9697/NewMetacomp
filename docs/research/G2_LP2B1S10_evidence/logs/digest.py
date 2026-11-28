import hashlib, os, sys
def fd(d):
    L = []
    for n in sorted(x for x in os.listdir(d) if x.endswith('.m')):
        L.append(n + ' ' + hashlib.sha256(open(os.path.join(d, n), 'rb').read()).hexdigest())
    return hashlib.sha256('\n'.join(L).encode('utf-8')).hexdigest(), len(L)
for d in sys.argv[1:]:
    print(d, *fd(d))
