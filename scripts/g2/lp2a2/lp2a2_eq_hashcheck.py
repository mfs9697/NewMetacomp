"""Independent (non-MATLAB) recomputation of the LP2-A2 equivalence pins, token and contract-evidence
hash, from the files of an execution clone (read-only).
usage: python -I scripts/g2/lp2a2/lp2a2_eq_hashcheck.py <execRepo> <contractEvidence.json> <out.json>"""
import hashlib, json, os, sys
R, ev, out = sys.argv[1], sys.argv[2], sys.argv[3]
sha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
dig = lambda lines: hashlib.sha256('\n'.join(lines).encode('utf-8')).hexdigest()
g2 = os.path.join(R, 'matlab', 'g2')
pf = os.path.join(g2, 'lp2a2', 'G2_LP2A2_EQ_POLICY_v1.json'); P = json.load(open(pf, encoding='utf-8')); pin = P['pins']
ps = sha(pf)
rel = sorted([f for f in os.listdir(g2) if f.endswith('.m')] + ['vendor_p010_a14d8872/' + f for f in os.listdir(os.path.join(g2, 'vendor_p010_a14d8872')) if f.endswith('.m')])
gsrc = dig([f"{r} {sha(os.path.join(g2, r))}" for r in rel])
fd = lambda d: dig([f"{n} {sha(os.path.join(d, n))}" for n in sorted(f for f in os.listdir(d) if f.endswith('.m'))])
lsrc = fd(os.path.join(g2, 'lp2')); asrc = fd(os.path.join(g2, 'lp2a2'))
base = os.path.join(R, 'outputs', 'g2_lp2a_paths_v1', 'run_lp2a_s5_s8_v1'); al = []; arch_ok = True
for s in P['solves']:
    c = s['caseId']; a = pin['archivedS8'][c]
    for f in ('STATE', 'MESH', 'PHASE', 'SOLUTION'):
        arch_ok &= sha(os.path.join(base, c, 'S8', f + '.mat')) == a[f]
    arch_ok &= sha(os.path.join(base, c, 'TERMINAL.mat')) == a['TERMINAL']
    al.append(f"{c} {a['STATE']} {a['MESH']} {a['PHASE']} {a['SOLUTION']} {a['TERMINAL']}")
aman = dig(al)
tok = f"G2LP2A2EQ|policy={ps}|g2source={gsrc}|lp2source={lsrc}|lp2a2source={asrc}|archivedS8={aman}|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1|limit=4"
T = json.load(open(ev, encoding='utf-8'))
res = {'schema': 'NewMetacomp.G2.LP2A2.EQ.Hashcheck.v1', 'policySHA256': ps, 'g2SourceSHA256': gsrc, 'lp2SourceSHA256': lsrc, 'lp2a2SourceSHA256': asrc,
       'archivedManifestSHA256': aman, 'token': tok, 'contractEvidenceSHA256': sha(ev),
       'checks': {'g2SourceEqualsPin': gsrc == pin['g2SourceSHA256'], 'lp2SourceEqualsPin': lsrc == pin['lp2SourceSHA256'],
                  'lp2a2SourceEqualsPin': asrc == pin['lp2a2SourceSHA256'], 'lp1Policy': sha(os.path.join(g2, 'G2_LP1_POLICY_v2.json')) == pin['lp1PolicySHA256'],
                  'lp2Policy': sha(os.path.join(g2, 'lp2', 'G2_LP2A_POLICY_v1.json')) == pin['lp2PolicySHA256'],
                  'testSet': sha(os.path.join(R, 'docs', 'research', 'G2_LP2A2_evidence', 'LP2A2_TEST_SET.json')) == pin['testSetSHA256'],
                  'archived20': arch_ok, 'tokenEqualsMATLAB': tok == T['token'], 'evidencePolicyEqual': ps == T['policySHA256'],
                  'evidenceDigestEqual': asrc == T['lp2a2SourceSHA256'], 'evidenceAllPassed': T['passed'] == T['total'] and T['physicalSolves'] == 0,
                  'noGoFile': not os.path.isfile(os.path.join(R, P['goFile'])), 'statusNotAuthorized': P['status'] == 'PREREGISTERED_NOT_AUTHORIZED'}}
res['pass'] = all(res['checks'].values())
open(out, 'w', encoding='utf-8', newline='\n').write(json.dumps(res, indent=1) + '\n')
print(json.dumps(res['checks']), 'PASS' if res['pass'] else 'FAIL'); print(res['contractEvidenceSHA256'])
