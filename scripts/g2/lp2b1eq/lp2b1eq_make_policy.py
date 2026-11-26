"""Generate matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json (prospective LP2-B1-EQ policy; NOT authorized; no GO).
Every pin is copied from committed evidence (LP2-A3 policy and record dump, LP2-A2 EQ policy, LP2-B1 pins, LP2-B1
archive record, LP2-B1 prospective contract) AND re-hashed from the actual files of the execution clone; any
difference aborts. The lp2b1eq source digest is passed in (it cannot be computed from this JSON, which it excludes).
usage: python lp2b1eq_make_policy.py <execRepo> <outJson> <lp2b1eqSourceSHA256> <closureSourceSHA256> <lp2b1SourceSHA256>"""
import hashlib, json, os, sys
R, out, eqsrc, closrc, b1src = sys.argv[1:6]
rd = lambda p: json.load(open(os.path.join(R, *p.split('/')), encoding='utf-8'))


def sha(p):
    h = hashlib.sha256()
    with open(os.path.join(R, *p.split('/')), 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


A3P = 'matlab/g2/lp2a3/G2_LP2A3_POLICY_v1.json'; EQP = 'matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json'
A3 = rd(A3P); EQ = rd(EQP); B1 = rd('matlab/g2/lp2b1/G2_LP2B1_PINS_v1.json')
DUMPF = 'docs/research/G2_LP2A3_evidence/campaign/verify/LP2A3_RECORD_DUMP.json'; DUMP = rd(DUMPF)
dumpsha = {f['path']: f['sha256'].lower() for g in ('run', 'ledger') for f in DUMP['files'][g]}
B1ARF = 'docs/research/G2_LP2B1_evidence/closure/LP2B1_ARCHIVE_RECORD.json'; B1AR = rd(B1ARF)
CONF = 'docs/research/G2_LP2B1_evidence/wp2/G2_LP2B1_EQ_CONTRACT_DRAFT_v1.json'; CON = rd(CONF)
RUN = A3['authorization']['runRoot']; LED = A3['authorization']['ledgerRoot']


def pin(p, ref):
    """file pin {path, sha256}: committed reference hash must equal the actual file hash"""
    h = sha(p); assert h == ref.lower(), (p, h, ref); return {'path': p, 'sha256': h}


def rec(p):
    return {'record': pin(p, dumpsha[p]), 'manifest': pin(p + '.manifest.json', dumpsha[p + '.manifest.json'])}


def qual(name):
    b = f'outputs/g2_lp2b1_geometry_v1/wp1_attempt2/{name}'
    a = pin(b + '/ATTEMPT_ARRAYS.mat', B1AR['memberSHA256'][b + '/ATTEMPT_ARRAYS.mat'])
    j = pin(b + '/ATTEMPT.json', B1AR['memberSHA256'][b + '/ATTEMPT.json'])
    J = rd(b + '/ATTEMPT.json'); assert J['pass'] and J['checksPassed'] == 19 and J['arraysFileSHA256'] == a['sha256']
    return {'attempt': name, 'arrays': a, 'attemptJson': j, 'canonicalSHA256': J['canonicalSHA256'], 'T3': J['T3'], 'seedSpacing_mm': J['seedSpacing_mm'],
            'minAngle_deg': J['independent']['minAngle_deg'], 'maxNeighborRatio': J['independent']['maxNeighborRatio']}


s8 = A3['parents']['S8']['soft1']
assert DUMP['cases']['soft1']['parent']['stateSHA256'] == s8['STATE']
SOL = [
 {'order': 1, 'id': 'EQB-soft1-S9', 'caseId': 'soft1', 'stateIndex': 9, 'mask': [1, 0, 0], 'ratio': 0.5, 'arc_mm': 61.4,
  'archived': {'folder': f'{RUN}/soft1/S9', 'STATE': rec(f'{RUN}/soft1/S9/STATE.mat'), 'MESH': pin(f'{RUN}/soft1/S9/MESH.mat', dumpsha[f'{RUN}/soft1/S9/MESH.mat']),
               'PHASE': rec(f'{RUN}/soft1/S9/PHASE.mat'), 'SOLUTION': rec(f'{RUN}/soft1/S9/SOLUTION.mat'), 'ADMIT': rec(f'{LED}/ADMIT_soft1_S9.mat')},
  'parent': {'kind': 'LP2-A1 S8 STATE (original accepted parent of LP2-A3 soft1 S9)', 'STATE': {'path': A3['parents']['run'] + '/soft1/S8/STATE.mat', 'sha256': s8['STATE']},
             'loader': 'g2_lp2a3_parent(C3,soft1) (pins S8 STATE/MESH/PHASE/SOLUTION/TERMINAL of the LP2-A3 policy)'},
  'nominalGeometry': 'clearanceGeometry of the soft1 S8 parent STATE (as LP2-B1 WP1 references)',
  'nextPredictor': {'state': 'S10', 'tip_mm': B1['target']['expectedTip_mm'], 'source': 'signed-MTS forecast g2_lp2_forecast(soft1 S9 STATE, LP2-A3 policy) = TERMINAL.candidate (NUMERICAL_HOLD terminal) = FAILED_MESH crack polyline; no accepted S10 exists',
                    'TERMINAL': rec(f'{RUN}/soft1/TERMINAL.mat'), 'FAILED_MESH': pin(f'{RUN}/soft1/S10/FAILED_MESH.mat', dumpsha[f'{RUN}/soft1/S10/FAILED_MESH.mat'])},
  'qualification': qual('R_soft1_S9_h040')},
 {'order': 2, 'id': 'EQB-H-S10', 'caseId': 'H', 'stateIndex': 10, 'mask': [0, 0, 0], 'ratio': 1, 'arc_mm': 65.4,
  'archived': {'folder': f'{RUN}/H/S10', 'STATE': rec(f'{RUN}/H/S10/STATE.mat'), 'MESH': pin(f'{RUN}/H/S10/MESH.mat', dumpsha[f'{RUN}/H/S10/MESH.mat']),
               'PHASE': rec(f'{RUN}/H/S10/PHASE.mat'), 'SOLUTION': rec(f'{RUN}/H/S10/SOLUTION.mat'), 'ADMIT': rec(f'{LED}/ADMIT_H_S10.mat')},
  'parent': {'kind': 'LP2-A3 H S9 STATE (accepted)', 'STATE': rec(f'{RUN}/H/S9/STATE.mat'), 'ADMIT': rec(f'{LED}/ADMIT_H_S9.mat'),
             'grandparent': {'path': A3['parents']['run'] + '/H/S8/STATE.mat', 'sha256': A3['parents']['S8']['H']['STATE']}},
  'nominalGeometry': 'clearanceGeometry of the accepted H S9 STATE (as LP2-B1 WP1 references)',
  'nextPredictor': {'state': 'S11', 'tip_mm': None, 'source': 'accepted H S11 STATE tip = g2_lp2_forecast(H S10 STATE, LP2-A3 policy)',
                    'STATE': rec(f'{RUN}/H/S11/STATE.mat'), 'ADMIT': rec(f'{LED}/ADMIT_H_S11.mat')},
  'qualification': qual('R_H_S10_h040')}]
H11 = [x for x in DUMP['cases']['H']['states'] if x['folder'] == 'S11'][0]['state']
SOL[1]['nextPredictor']['tip_mm'] = H11['tip_mm']
assert SOL[1]['nextPredictor']['tip_mm'] == CON['solves'][1]['nextPredictor']['archivedNextTip_mm']
assert SOL[0]['nextPredictor']['tip_mm'] == CON['solves'][0]['nextPredictor']['archivedNextTip_mm']
for i, s in enumerate(SOL):
    for k in ('STATE', 'SOLUTION', 'MESH'):
        h = s['archived'][k]['record']['sha256'] if k != 'MESH' else s['archived'][k]['sha256']
        assert h == CON['solves'][i]['archived'][k], (s['id'], k)
tol = {k: v for k, v in EQ['tolerances'].items() if not k.startswith('contrast_') and k != 'S9tipDisplacement_mm'}
tol['nextTipDisplacement_mm'] = EQ['tolerances']['S9tipDisplacement_mm']
tol['activeAreaExactZeroWhenArchivedZero'] = True
tol['nearTipRadius_mm'] = 3.3; tol['nodeMatch_mm'] = 1e-9
B1Q = {p: pin(p, B1AR['memberSHA256'][p]) for p in sorted(B1AR['memberSHA256']) if p.startswith('outputs/g2_lp2b1_geometry_v1/wp1')
       and (p.endswith('.json') or p.endswith('ATTEMPT_ARRAYS.mat'))}
ev = ['docs/research/G2_LP2B1_evidence/closure/LP2B1_ARCHIVE_RECORD.json', 'docs/research/G2_LP2B1_evidence/closure/LP2B1_KNOWN_PROTECTED_MANIFEST.json',
      'docs/research/G2_LP2B1_evidence/closure/LP2B1_PROTECTED_AFTER.json', 'docs/research/G2_LP2B1_evidence/audit/LP2B1_INDEPENDENT_AUDIT_run1.json',
      'docs/research/G2_LP2B1_evidence/audit/LP2B1_SUMMARY_DIFF.json', CONF, DUMPF, 'docs/research/G2_LP2A3_evidence/LP2A3_PROTECTED_MANIFEST.json']
hist = sorted(d for d in os.listdir(os.path.join(R, 'outputs')) if os.path.isdir(os.path.join(R, 'outputs', d)) and not d.startswith('g2_lp2b1eq_'))   # readiness outputs of this phase are not historical
assert 'g2_lp2b1_eq_v1' not in hist and 'g2_lp2b1_eq_receipts' not in hist
src = A3['sourcePins']
P = {
 'schema': 'NewMetacomp.G2.LP2B1EQ.Policy.v1',
 'status': 'PROPOSED_NOT_AUTHORIZED',
 'assignment': 'G2-LP2-B1-EQ, https://github.com/mfs9697/NewMetacomp/issues/78; start head 28f554883f8248423098fbab5224bec42ba98a1a (PR #77)',
 'scope': 'Readiness of exactly two FUTURE fixed-geometry physical equivalence solves at the LP2-B1 qualified 0.40 mm bank seed spacing against the ORIGINAL accepted LP2-A3 records of the same geometry and material: EQB-soft1-S9 then EQB-H-S10, one attempt each, global stop on the first failure. No propagation, no new STATE, no target soft1 S10 solve, no same-s contrast, no fallback, no retry, no adaptive step, no LP2-B2, no S12.',
 'authority': {'b1Review': 'https://github.com/mfs9697/NewMetacomp/pull/77#pullrequestreview-6072320621 (LP2B1_MESH_QUALIFIED_RESTRICTED_0p40)',
               'b1Head': '28f554883f8248423098fbab5224bec42ba98a1a',
               'wp5ScientificAcceptance': 'https://github.com/mfs9697/NewMetacomp/pull/71#pullrequestreview-6063867614',
               'wp5FinalClosure': 'https://github.com/mfs9697/NewMetacomp/pull/71#pullrequestreview-6064434652',
               'a3ScientificAcceptance': 'https://github.com/mfs9697/NewMetacomp/pull/75#pullrequestreview-6069396048',
               'contractDraft': pin(CONF, sha(CONF))},
 'campaignId': 'G2-LP2B1-EQ-001',
 'solves': SOL,
 'solveLimit': 2, 'attemptsPerSolve': 1, 'retry': False, 'adaptiveStep': False, 'newStates': 0, 'targetSolve': False,
 'provenanceOnly': {'targetCanonicalSHA256': '54293d2a527f9bec33605ffea10c8f56af46a56291157f0d911cf68301b85bd2', 'note': 'soft1 S10 target qualification digest: provenance only, NOT a solve case'},
 'policyPins': {'lp1': pin('matlab/g2/G2_LP1_POLICY_v2.json', A3['lp1PolicySHA256']), 'lp2': pin('matlab/g2/lp2/G2_LP2A_POLICY_v1.json', A3['lp2PolicySHA256']),
                'lp2a2': pin(EQP, A3['lp2a2PolicySHA256']), 'lp2a3': pin(A3P, B1['lp2a3']['policySHA256']),
                'lp2b1Pins': pin('matlab/g2/lp2b1/G2_LP2B1_PINS_v1.json', sha('matlab/g2/lp2b1/G2_LP2B1_PINS_v1.json')),
                'lp2b1Prereg': pin('matlab/g2/lp2b1/G2_LP2B1_PREREG_v1.json', '3d51140b80075cf27dd21820f16e65ceaa1456ea7a512acbc6ffe9888c70f9b1'),
                'lp2b1AmendmentA1': pin('matlab/g2/lp2b1/G2_LP2B1_PREREG_AMENDMENT_A1.json', sha('matlab/g2/lp2b1/G2_LP2B1_PREREG_AMENDMENT_A1.json'))},
 'sourcePins': {'g2SourceSHA256': src['g2SourceSHA256'], 'lp2SourceSHA256': src['lp2SourceSHA256'], 'lp2a2SourceSHA256': src['lp2a2SourceSHA256'],
                'lp2a3SourceSHA256': src['lp2a3SourceSHA256'], 'lp2b1SourceSHA256': b1src, 'lp2b1eqSourceSHA256': eqsrc, 'closureSourceSHA256': closrc,
                'definition': 'g2: sorted relative-path sha256 lines of matlab/g2/*.m and matlab/g2/vendor_p010_a14d8872/*.m; lp2, lp2a2, lp2a3, lp2b1, lp2b1eq and scripts/g2/lp2a2/closure: sorted "name sha256" lines of the folder *.m; SHA-256 of the newline-joined string (g2_lp1_digest)'},
 'qualificationEvidence': {'b1ArchiveSHA256': B1AR['sha256'], 'b1ArchiveName': B1AR['archive'], 'b1ArchiveMembers': B1AR['members'], 'b1ArchiveManifestSHA256': B1AR['manifestSHA256'],
                           'b1OutputFiles': B1AR['outputFiles'], 'records': list(B1Q.values()), 'evidenceFiles': [pin(p, sha(p)) for p in ev],
                           'attempt1': 'outputs/g2_lp2b1_geometry_v1/wp1 (HOLD on harness defects D1/D2, preserved; amendment A1)',
                           'use': 'mesh-family admission only (canonical arrays and metadata); never a physical result'},
 'meshFamily': {'function': 'g2_lp2a2_join(P,ExpectedVertices k+2,ExpectedTangent t,ExteriorOptions [xo,{SeedSpacing_mm,0.40}],MaxT3Elements 40000) + g2_lp2a2_pairing_audit + g2_lp1_audit; NO ladder, NO other spacing',
                'seedSpacing_mm': 0.40, 'ExteriorOptions': A3['meshFamily']['ExteriorOptions'],
                'admissionHarness': 'g2_lp2b1_attempt (accepted LP2-B1 harness under amendment A1, unchanged): 19/19 checks on the fixed reference geometry and canonical digest equal to the qualification record',
                'canonicalDigest': 'SHA-256 over, in this order, X3,T3,X6,T6,upperBankT6,lowerBankT6,nodalQ,qActiveT6Rows,crackPolyline: for each, int64 size vector bytes then double(a(:)) column-major bytes (little endian), identical to canon() of g2_lp2b1_attempt',
                'metadataNotInDigest': 'elementRows, extraVertexXY, physicalTipNode, gates and the remaining saved summary fields are compared with the qualification ATTEMPT_ARRAYS.mat by isequal (summary except the timing field nativeMeshingSeconds); ring polygons and 76 chords per circle from the audit',
                'protectedTopology': 'g2_lp2b1eq_topology: element-local bijection of the 2916 protected T6 rows (core 2788 + collar 128) between the archived 0.45 mm MESH and the new mesh, coordinates and nodal q bitwise, bank side and distinct coincident upper/lower IDs preserved except the single physical tip node',
                'expectedChords': 76},
 'bvp': A3['bvp'], 'qAnnuli_mm': A3['qAnnuli_mm'], 'geometry': A3['geometry'],
 'physics': 'unchanged: g2_m4b_ring_activation(case mask) on the audited phase owner map -> g2_m4b_sif_partial (G2_TRAJECTORY_POLICY_v1 BVP, 16 numerical gates, signed K, COD, five-annulus EDI + 4x4) -> g2_mts_direction; matrix E = 3268.115 MPa, active rings E*ratio, nu 0.35, plane stress, P = 1 N, thickness 12.7 mm',
 'tolerances': tol,
 'units': {'K': 'MPa*mm^0.5 at P = 1 N (x sqrt(1000) = MPa*m^0.5/kN)', 'G_J': 'MPa*mm = N/mm at P = 1 N', 'compliance': 'mm/N', 'activeArea': 'mm^2', 'MTS': 'deg', 'nextTip': 'mm'},
 'criteria': {'C1_KI': '|KI_new - KI_arch| / Keq_arch <= 5e-4, Keq_arch = hypot(KI_arch, KII_arch)',
              'C2_KII': '|KII_new - KII_arch| / Keq_arch <= 5e-5 (signed KII)',
              'C3_KIIoverKI': '|KII_new/KI_new - KII_arch/KI_arch| <= 1e-4',
              'C4_G_J': '|G_new/G_arch - 1| <= 1e-3 and |J_new/J_arch - 1| <= 1e-3 and |J_new/G_new - 1| <= 1e-4, G = (KI^2 + KII^2)/E',
              'C5_MTS': '|theta_MTS,new - theta_MTS,arch| <= 0.006 deg and new tensile root admissible',
              'C6_COD_EDI': 'new COD-EDI <= 0.03 and |new - archived COD-EDI| <= 1e-3',
              'C7_EDI_spread_quadrature': 'new path spread <= max(1e-5, 5 x archived) and new 4x4 quadrature drift <= max(1e-5, 5 x archived)',
              'C8_crackOpening': 'scalar jump magnitude j = |u_U - u_L| (difference of magnitudes, NOT norm of vector differences); near tip (<= 3.3 mm, identical node positions within 1e-9 mm): max|j_new - j_arch| / max j_new(near) <= 1e-3; whole crack: archived j linearly interpolated in arc station onto new stations (no extrapolation), max|.| / max j_new <= 2e-3; signed normal opening reported only',
              'C9_phaseActivation': 'all 16 inherited solver gates pass, chords per circle equal to archived (76 each), |dA_active| / max(A_arch, 1 mm^2) <= 1e-9 and, STRONGER (draft requirement), new active area exactly 0 when archived is exactly 0 (H)',
              'C10_nextPredictor': '|forecast(new K) - archived next tip| <= 5e-4 mm with the STATE-SPECIFIC next state: S10 for EQB-soft1-S9, S11 for EQB-H-S10',
              'C11_compliance': '|C_new/C_arch - 1| <= 1e-3'},
 'validation': 'before any criterion: finite real inputs of the correct shape/type, positive archived KI/Keq/G/J/compliance, valid archived MTS root, all 16 archived gates, u of length 2*N_T6 for each mesh, identity of solve/case/state/mask/geometry/predictor/pins/canonical digest, paired banks with unique stations, near-tip node identity, station coverage without extrapolation, nonzero normalizations (C8 near-tip and whole-crack maxima and the maxima of the reported signed normal opening), finite metrics (a non-admissible new MTS root makes the forecast impossible: NaN next tip); any failure = INPUT_INVALID (verification-infrastructure HOLD, never an equivalence statement)',
 'outcomes': {'EQUIVALENT_CASE': 'valid and C1-C11 pass', 'NOT_EQUIVALENT': 'valid and at least one criterion fails (numerical HOLD)', 'INPUT_INVALID': 'verification-infrastructure HOLD'},
 'excludedComparisons': CON['excludedComparisons'],
 'interpretation': CON['interpretation'],
 'protected': {'knownManifestSHA256': 'e756d64aee23adde0ea4a1662d0e9e77dbae3eb27c1195145a0056367fff1f35', 'knownFiles': 832,
               'campaignSummary': B1['lp2a3']['campaignSummary'], 'b1OutputFiles': B1AR['outputFiles'], 'b1ArchiveRecord': pin(B1ARF, sha(B1ARF))},
 'historicalRoots': ['outputs/' + d for d in hist],
 'authorization': {'goPath': 'matlab/g2/lp2b1eq/G2_LP2B1EQ_GO.json', 'goPresent': False, 'decision': 'GO_LP2B1_EQ', 'campaignId': 'G2-LP2B1-EQ-001',
                   'campaignScope': 'LP2B1_EQ_TWO_FIXED_REFERENCES_0p40', 'runName': 'run_lp2b1_eq_v1', 'runRoot': 'outputs/g2_lp2b1_eq_v1/run_lp2b1_eq_v1',
                   'receiptRoot': 'outputs/g2_lp2b1_eq_receipts/G2-LP2B1-EQ-001',
                   'forbiddenRunNames': A3['authorization']['forbiddenRunNames'] + [A3['authorization']['runName']],
                   'forbiddenCampaignIds': A3['authorization']['forbiddenCampaignIds'] + [A3['authorization']['campaignId']],
                   'contractEvidenceDir': 'docs/research/G2_LP2B1EQ_evidence/',
                   'activation': 'GO file only, committed directly on the reviewed head (validator: ancestor + HEAD~1 == approvedHead + sole changed file, via g2_lp2a2_git); single external entry g2_lp2b1eq_external_run writes the receipt; the driver refuses a physical call without a receipt bound to the token',
                   'resumption': 'none'},
 'resources': A3['resources'],
 'records': {'perSolve': ['GEOMETRY_h040/ATTEMPT.json', 'GEOMETRY_h040/ATTEMPT_ARRAYS.mat', 'MESH.mat', 'PHASE.mat', 'PHASE.mat.manifest.json', 'SOLUTION.mat', 'SOLUTION.mat.manifest.json',
                          'COMPARISON.mat', 'COMPARISON.mat.manifest.json', 'COMPARISON.json'],
             'onFailure': 'HOLD.json in the solve folder (never overwritten); partial records preserved', 'receipt': ['RECEIPT.mat', 'RECEIPT.mat.manifest.json'],
             'noState': 'no STATE, no ADMIT, no accepted propagation record'},
 'stopRules': ['global: stop at the first failure of any criterion, gate, integrity, resource or authorization check; the second solve is not called; no retry, no resumption',
               'EQB-H-S10 may be called only after EQB-soft1-S9 has a complete record set with outcome EQUIVALENT_CASE'],
 'excluded': ['physical FEM during readiness', 'live GO during readiness', 'new accepted states', 'target soft1 S10 solve', 'other seed spacings', 'same-s or architecture contrast',
              'LP2-B2', 'S12', 'retries or resumption', 'changes to historical sources, policies, records or archives', 'merges']}
open(out, 'w', encoding='utf-8', newline='\n').write(json.dumps(P, indent=1) + '\n')
print('policy written', out, hashlib.sha256(open(out, 'rb').read()).hexdigest())
