"""Independent (non-MATLAB) recomputation of the LP2-A3 pins, parent and qualification manifests, token and
contract-evidence hash from the files of an execution clone (read-only).
usage: python -I scripts/g2/lp2a3/lp2a3_hashcheck.py <execRepo> <contractEvidence.json|-> <out.json>"""
import hashlib, json, os, sys
R, ev, out = sys.argv[1], sys.argv[2], sys.argv[3]
sha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
dig = lambda lines: hashlib.sha256('\n'.join(lines).encode('utf-8')).hexdigest()
g2 = os.path.join(R, 'matlab', 'g2')
pf = os.path.join(g2, 'lp2a3', 'G2_LP2A3_POLICY_v1.json'); P = json.load(open(pf, encoding='utf-8')); ps = sha(pf); sp = P['sourcePins']
rel = sorted([f for f in os.listdir(g2) if f.endswith('.m')] + ['vendor_p010_a14d8872/' + f for f in os.listdir(os.path.join(g2, 'vendor_p010_a14d8872')) if f.endswith('.m')])
gsrc = dig([f"{r} {sha(os.path.join(g2, r))}" for r in rel])
fd = lambda d: dig([f"{n} {sha(os.path.join(d, n))}" for n in sorted(f for f in os.listdir(d) if f.endswith('.m'))])
l2, a2, a3 = fd(os.path.join(g2, 'lp2')), fd(os.path.join(g2, 'lp2a2')), fd(os.path.join(g2, 'lp2a3'))
ids = ['H', 'stiff13', 'soft2', 'soft1']; pl = []; par_ok = True
for c in ids:
    p = P['parents']['S8'][c]; d = os.path.join(R, *P['parents']['run'].split('/'), c)
    for f in ('STATE', 'MESH', 'PHASE', 'SOLUTION'):
        par_ok &= sha(os.path.join(d, 'S8', f + '.mat')) == p[f]
    par_ok &= sha(os.path.join(d, 'TERMINAL.mat')) == p['TERMINAL']
    pl.append(f"{c} {p['STATE']} {p['MESH']} {p['PHASE']} {p['SOLUTION']} {p['TERMINAL']}")
pman = dig(pl)
man = json.load(open(os.path.join(R, *P['parents']['manifest'].split('/')), encoding='utf-8'))
base = P['parents']['run']
man_ok = all(man[f"{base}/{c}/S8/{f}.mat"] == P['parents']['S8'][c][f] for c in ids for f in ('STATE', 'MESH', 'PHASE', 'SOLUTION')) and \
         all(man[f"{base}/{c}/TERMINAL.mat"] == P['parents']['S8'][c]['TERMINAL'] for c in ids)
q = P['qualificationEvidence']; ql = []; q_ok = len(q['records']) == 24
for r in q['records'] + q['evidenceFiles']:
    q_ok &= sha(os.path.join(R, *r['path'].split('/'))) == r['sha256']; ql.append(f"{r['path']} {r['sha256']}")
ql.append('archive ' + q['archiveSHA256']); qman = dig(sorted(ql))
au = P['authorization']
tok = (f"G2LP2A3|policy={ps}|g2source={gsrc}|lp2source={l2}|lp2a2source={a2}|lp2a3source={a3}|parentsS8={pman}|qualification={qman}"
       f"|cases=H,stiff13,soft2,soft1|states=S9-S11|maxAdmissions=12|seed=0.45|campaign={au['campaignId']}|run={au['runName']}")
chk = {'g2SourceEqualsPin': gsrc == sp['g2SourceSHA256'], 'lp2SourceEqualsPin': l2 == sp['lp2SourceSHA256'], 'lp2a2SourceEqualsPin': a2 == sp['lp2a2SourceSHA256'],
       'lp2a3SourceEqualsPin': a3 == sp['lp2a3SourceSHA256'], 'lp1Policy': sha(os.path.join(R, *P['lp1PolicyFile'].split('/'))) == P['lp1PolicySHA256'],
       'lp2Policy': sha(os.path.join(R, *P['lp2PolicyFile'].split('/'))) == P['lp2PolicySHA256'],
       'lp2a2Policy': sha(os.path.join(R, *P['lp2a2PolicyFile'].split('/'))) == P['lp2a2PolicySHA256'],
       'parents20': par_ok, 'parentsEqualLP2A1Manifest': man_ok, 'qualification24PlusEvidence': q_ok,
       'noGoFile': not os.path.isfile(os.path.join(R, *au['goPath'].split('/'))),
       'runRootAbsent': not os.path.isdir(os.path.join(R, *au['runRoot'].split('/'))), 'ledgerRootAbsent': not os.path.isdir(os.path.join(R, *au['ledgerRoot'].split('/'))),
       'statusNotAuthorized': P['status'] == 'PROPOSED_NOT_AUTHORIZED'}
res = {'schema': 'NewMetacomp.G2.LP2A3.Hashcheck.v1', 'policySHA256': ps, 'g2SourceSHA256': gsrc, 'lp2SourceSHA256': l2, 'lp2a2SourceSHA256': a2,
       'lp2a3SourceSHA256': a3, 'parentManifestSHA256': pman, 'qualificationManifestSHA256': qman, 'token': tok}
if ev != '-':
    T = json.load(open(ev, encoding='utf-8')); res['contractEvidenceSHA256'] = sha(ev)
    chk.update({'tokenEqualsMATLAB': T['token'] == tok, 'evidencePolicyEqual': T['policySHA256'] == ps, 'evidenceDigestEqual': T['lp2a3SourceSHA256'] == a3,
                'evidenceAllPassed': T['passed'] == T['total'] and T['physicalSolves'] == 0})
res['checks'] = chk; res['pass'] = all(chk.values())
open(out, 'w', encoding='utf-8', newline='\n').write(json.dumps(res, indent=1) + '\n')
print(json.dumps(chk), 'PASS' if res['pass'] else 'FAIL')
