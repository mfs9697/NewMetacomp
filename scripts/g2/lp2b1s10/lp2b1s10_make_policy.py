"""Generate matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json (prospective LP2-B1-S10 policy; NOT authorized; no GO).
Every pin is copied from committed evidence (LP2-A3 policy and record dump, LP2-B1 pins and archive record, LP2-B1-EQ
policy and campaign archive record) AND re-hashed from the actual files of the execution clone; any difference aborts.
The lp2b1s10 source digest is passed in (it cannot be computed from this JSON).
usage: python lp2b1s10_make_policy.py <execRepo> <outJson> <lp2b1s10SourceSHA256>"""
import hashlib, json, os, sys
R, out, s10src = sys.argv[1:4]
rd = lambda p: json.load(open(os.path.join(R, *p.split('/')), encoding='utf-8'))


def sha(p):
    h = hashlib.sha256()
    with open(os.path.join(R, *p.split('/')), 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


A3P = 'matlab/g2/lp2a3/G2_LP2A3_POLICY_v1.json'; EQP = 'matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json'
A3 = rd(A3P); EQ = rd(EQP); B1 = rd('matlab/g2/lp2b1/G2_LP2B1_PINS_v1.json')
DUMPF = 'docs/research/G2_LP2A3_evidence/campaign/verify/LP2A3_RECORD_DUMP.json'; DUMP = rd(DUMPF)
dumpsha = {f['path']: f['sha256'].lower() for g in ('run', 'ledger') for f in DUMP['files'][g]}
B1ARF = 'docs/research/G2_LP2B1_evidence/closure/LP2B1_ARCHIVE_RECORD.json'; B1AR = rd(B1ARF)
EQARF = 'docs/research/G2_LP2B1EQ_evidence/campaign/post/LP2B1EQ_CAMPAIGN_ARCHIVE_RECORD.json'; EQAR = rd(EQARF)
EQAUD = 'docs/research/G2_LP2B1EQ_evidence/campaign/verify/LP2B1EQ_AUDIT_v3.json'
RUN = A3['authorization']['runRoot']; LED = A3['authorization']['ledgerRoot']
assert EQAR['sha256'] == '1d739f80fe77597e3749de7e939abf8f572bc48f27bb703c28d02f94634d6e8a' and EQAR['pass'] and EQAR['outputFiles'] == 23


def pin(p, ref):
    """file pin {path, sha256}: committed reference hash must equal the actual file hash"""
    h = sha(p); assert h == ref.lower(), (p, h, ref); return {'path': p, 'sha256': h}


def rec(p):
    return {'record': pin(p, dumpsha[p]), 'manifest': pin(p + '.manifest.json', dumpsha[p + '.manifest.json'])}


def b1(p):
    return pin(p, B1AR['memberSHA256'][p])


WP = 'outputs/g2_lp2b1_geometry_v1/wp1_attempt2'
J = rd(f'{WP}/T_soft1_S10_h040/ATTEMPT.json'); Jr = rd(f'{WP}/T_soft1_S10_h040_REPEAT/ATTEMPT.json')
assert J['pass'] and J['checksPassed'] == 19 and J['T3'] == 30357 and J['canonicalSHA256'] == '54293d2a527f9bec33605ffea10c8f56af46a56291157f0d911cf68301b85bd2'
assert J['independent']['minAngle_deg'] == 23.179107436795395 and J['independent']['maxNeighborRatio'] == 1.6015350873084404
assert J['arraysFileSHA256'] == '086b6671a733bafad3874dee8d50c84bc52e6bfaa6ba0174caae09995c2f2a88' and Jr['canonicalSHA256'] == J['canonicalSHA256'] and Jr['pass']
assert rd(f'{WP}/LP2B1_WP1_REPEAT.json')['outcome'] == 'DETERMINISTIC' and rd(f'{WP}/LP2B1_WP1_TARGET.json')['selected'] == 0.4
tg = B1['target']; s8 = A3['parents']['S8']['soft1']
S9 = [x for x in DUMP['cases']['soft1']['states'] if x['folder'] == 'S9'][0]['state']
assert S9['stateIndex'] == 9 and S9['parentSHA256'] == s8['STATE'] and S9['numericalStatus'] == 'ACCEPTED'
src = A3['sourcePins']; es = EQ['sourcePins']
hist = sorted(d for d in os.listdir(os.path.join(R, 'outputs')) if os.path.isdir(os.path.join(R, 'outputs', d)) and not d.startswith('g2_lp2b1s10_'))
assert 'g2_lp2b1_s10_v1' not in hist and 'g2_lp2b1_s10_receipts' not in hist and 'g2_lp2b1_eq_v1' in hist and 'g2_lp2b1_eq_receipts' in hist
eqOut = {p: pin(p, h) for p, h in sorted(EQAR['memberSHA256'].items()) if p.startswith('outputs/')}
P = {
 'schema': 'NewMetacomp.G2.LP2B1S10.Policy.v1',
 'status': 'PROPOSED_NOT_AUTHORIZED',
 'assignment': 'G2-LP2-B1-S10, https://github.com/mfs9697/NewMetacomp/issues/81; start head d030ac2878ca8b11f2c085960496e8ad01ba1853 (PR #79)',
 'scope': 'Readiness of exactly ONE future physical admission and solve: soft1 S10 (mask 100, ratio 0.5, 4 mm increment, s = 65.4 mm) at the qualified 0.40 mm bank seed spacing, continuing the ORIGINAL accepted LP2-A3 soft1 S9 STATE. One attempt; no retry, resumption or fallback; S11 forecast for information only; no S11 mesh, admission or solve; no equivalence criterion on the target; no LP2-B2.',
 'authority': {'a3ScientificAcceptance': 'https://github.com/mfs9697/NewMetacomp/pull/75#pullrequestreview-6069396048',
               'b1GeometryAcceptance': 'https://github.com/mfs9697/NewMetacomp/pull/77#pullrequestreview-6072320621',
               'b1eqReadinessReview': 'https://github.com/mfs9697/NewMetacomp/pull/79#pullrequestreview-6084428945',
               'b1eqDemonstrationAcceptance': 'https://github.com/mfs9697/NewMetacomp/pull/79#pullrequestreview-6085607255',
               'startHead': 'd030ac2878ca8b11f2c085960496e8ad01ba1853'},
 'campaignId': 'G2-LP2B1-S10-001',
 'target': {'caseId': 'soft1', 'stateIndex': 10, 'state': 'S10', 'mask': [1, 0, 0], 'ratio': 0.5, 'increment_mm': 4, 'arc_mm': 65.4,
            'admissions': 1, 'physicalSolves': 1, 'attempts': 1, 'retry': False, 'resumption': False, 'fallback': False, 'adaptiveStep': False,
            'expectedTip_mm': tg['expectedTip_mm'], 'expectedClassification': 'MATRIX_ADVANCE',
            'ring1GuideGap_mm': {'matlabGuard': 4.6329563816383335, 'issueValue': 4.632956381638341, 'issueValueSource': 'independent Python LP2-A3 analysis (LP2A3_ANALYSIS.json); |difference| <= 1e-12 mm required',
                                 'matlabSource': 'g2_lp2a3_guard on the full-precision candidate tip (LP2A3 record dump / LP2-B1 WP0 / attempt JSON)'}},
 'parent': {'kind': 'ORIGINAL accepted LP2-A3 soft1 S9 STATE (sole authoritative parent; NOT the LP2-B1-EQ re-solve)', 'folder': f'{RUN}/soft1/S9',
            'STATE': rec(f'{RUN}/soft1/S9/STATE.mat'), 'MESH': pin(f'{RUN}/soft1/S9/MESH.mat', dumpsha[f'{RUN}/soft1/S9/MESH.mat']),
            'PHASE': rec(f'{RUN}/soft1/S9/PHASE.mat'), 'SOLUTION': rec(f'{RUN}/soft1/S9/SOLUTION.mat'),
            'ADMIT': rec(f'{LED}/ADMIT_soft1_S9.mat'), 'RECEIPT': rec(f'{LED}/RECEIPT.mat'),
            'grandparentS8': {'path': A3['parents']['run'] + '/soft1/S8/STATE.mat', 'sha256': s8['STATE']},
            'nominalGeometry': 'clearanceGeometry stored in the soft1 S9 STATE (as the LP2-B1 WP1 target attempt)'},
 'failedA3S10': {'note': 'immutable evidence of the LP2-A3 soft1 S10 local NUMERICAL_HOLD (0.45 mm join failed globalNeighborRatioAtMost1p8); preserved, never resumed',
                 'TERMINAL': rec(f'{RUN}/soft1/TERMINAL.mat'), 'FAILED_MESH': pin(f'{RUN}/soft1/S10/FAILED_MESH.mat', tg['failedMesh']['sha256']),
                 'HOLD': rec(f'{RUN}/soft1/S10/HOLD.mat'), 'ADMIT': rec(f'{LED}/ADMIT_soft1_S10.mat'),
                 'expectedSavedSummary': tg['expectedSavedSummary'], 'baselineUse': 'protected-block baseline of the 0.40 mm admission (same geometry), exactly as the LP2-B1 WP1 target attempt'},
 'qualification': {'attempt': 'T_soft1_S10_h040', 'arrays': b1(f'{WP}/T_soft1_S10_h040/ATTEMPT_ARRAYS.mat'), 'attemptJson': b1(f'{WP}/T_soft1_S10_h040/ATTEMPT.json'),
                   'repeatArrays': b1(f'{WP}/T_soft1_S10_h040_REPEAT/ATTEMPT_ARRAYS.mat'), 'repeatJson': b1(f'{WP}/T_soft1_S10_h040_REPEAT/ATTEMPT.json'),
                   'wp1Target': b1(f'{WP}/LP2B1_WP1_TARGET.json'), 'wp1Repeat': b1(f'{WP}/LP2B1_WP1_REPEAT.json'),
                   'canonicalSHA256': J['canonicalSHA256'], 'T3': J['T3'], 'seedSpacing_mm': J['seedSpacing_mm'],
                   'minAngle_deg': J['independent']['minAngle_deg'], 'maxNeighborRatio': J['independent']['maxNeighborRatio'],
                   'b1ArchiveSHA256': B1AR['sha256'], 'b1ArchiveRecord': pin(B1ARF, sha(B1ARF))},
 'b1eqEvidence': {'archiveSHA256': EQAR['sha256'], 'archiveName': EQAR['archive'], 'archiveMembers': EQAR['members'], 'archiveRecord': pin(EQARF, sha(EQARF)),
                  'policy': pin(EQP, sha(EQP)), 'independentAudit': pin(EQAUD, sha(EQAUD)), 'outputs': list(eqOut.values()),
                  'acceptance': 'SCIENTIFIC_ACCEPT_LP2B1_EQ_DEMONSTRATION / EQUIVALENT_AT_0p40 (qualification evidence of the 0.40 mm family; NOT a proof that the target is equivalent or converged)'},
 'policyPins': {'lp1': pin('matlab/g2/G2_LP1_POLICY_v2.json', A3['lp1PolicySHA256']), 'lp2': pin('matlab/g2/lp2/G2_LP2A_POLICY_v1.json', A3['lp2PolicySHA256']),
                'lp2a2': pin('matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json', A3['lp2a2PolicySHA256']), 'lp2a3': pin(A3P, B1['lp2a3']['policySHA256']),
                'lp2b1Pins': pin('matlab/g2/lp2b1/G2_LP2B1_PINS_v1.json', EQ['policyPins']['lp2b1Pins']['sha256']),
                'lp2b1Prereg': pin('matlab/g2/lp2b1/G2_LP2B1_PREREG_v1.json', EQ['policyPins']['lp2b1Prereg']['sha256']),
                'lp2b1AmendmentA1': pin('matlab/g2/lp2b1/G2_LP2B1_PREREG_AMENDMENT_A1.json', EQ['policyPins']['lp2b1AmendmentA1']['sha256']),
                'lp2b1eq': pin(EQP, 'b113a7c6d7b2e8fe9950d817ccca3c851c05f1e347c73f66c604b9c41e54eecb'),
                'trajectory': pin('matlab/g2/G2_TRAJECTORY_POLICY_v1.json', sha('matlab/g2/G2_TRAJECTORY_POLICY_v1.json'))},
 'sourcePins': {'g2SourceSHA256': src['g2SourceSHA256'], 'lp2SourceSHA256': src['lp2SourceSHA256'], 'lp2a2SourceSHA256': src['lp2a2SourceSHA256'],
                'lp2a3SourceSHA256': src['lp2a3SourceSHA256'], 'lp2b1SourceSHA256': es['lp2b1SourceSHA256'], 'lp2b1eqSourceSHA256': '74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f',
                'closureSourceSHA256': es['closureSourceSHA256'], 'lp2b1s10SourceSHA256': s10src,
                'definition': 'g2: sorted relative-path sha256 lines of matlab/g2/*.m and matlab/g2/vendor_p010_a14d8872/*.m; lp2, lp2a2, lp2a3, lp2b1, lp2b1eq, lp2b1s10 and scripts/g2/lp2a2/closure: sorted "name sha256" lines of the folder *.m; SHA-256 of the newline-joined string (g2_lp1_digest)'},
 'meshFamily': {'function': 'UNCHANGED g2_lp2b1eq_geometry (accepted LP2-B1-EQ admission): g2_lp2b1_attempt 19/19 + identical g2_lp2a2_join(P,k+2,t,[xo,{SeedSpacing_mm,0.40}],40000) + g2_lp2a2_pairing_audit + g2_lp1_audit + g2_m4b_ring_activation; baseline = the stored FAILED_MESH of the same geometry; NO ladder, NO other spacing',
                'seedSpacing_mm': 0.40, 'ExteriorOptions': A3['meshFamily']['ExteriorOptions'],
                'expected': {'T3': 30357, 'minAngle_deg': 23.179107436795395, 'maxNeighborRatio': 1.6015350873084404, 'chordsPerCircle': [76, 76, 76], 'qActiveT6Parents': 2443,
                             'coreRadius_mm': 3.0, 'collarRadius_mm': 3.3, 'limits': {'minAngle_deg': 20, 'maxNeighborRatio': 1.8, 'maxT3': 40000}},
                'canonicalDigest': EQ['meshFamily']['canonicalDigest'], 'metadataNotInDigest': EQ['meshFamily']['metadataNotInDigest'],
                'protectedTopology': 'g2_lp2b1eq_topology versus the stored FAILED_MESH: element-local bijection of the 2916 protected T6 rows, coordinates and nodal q bitwise, distinct coincident bank IDs except the single physical tip node, tip within the inherited 1e-9 mm of the polyline end with identical old/new coordinates'},
 'bvp': A3['bvp'], 'qAnnuli_mm': A3['qAnnuli_mm'], 'geometry': A3['geometry'], 'ringProximityGuard': A3['ringProximityGuard'], 'resources': A3['resources'],
 'tolerances': {'nodeMatch_mm': 1e-9, 'nearTipRadius_mm': 3.3, 'mtsStationarity_rel': 1e-12, 'ring1GuideGapIssueValue_mm': 1e-12,
                'note': 'no C1-C11 equivalence criterion on the target (no valid 0.45 mm S10 solution exists); nodeMatch/nearTipRadius only serve the unchanged admission station check'},
 'physics': 'unchanged: g2_m4b_ring_activation(mask 100) on the audited phase owner map -> g2_m4b_sif_partial (G2_TRAJECTORY_POLICY_v1 BVP, 16 numerical gates, signed K, COD, five-annulus EDI + 4x4) -> g2_mts_direction; matrix E = 3268.115 MPa, ring 1 E*0.5, nu 0.35, plane stress, P = 1 N, thickness 12.7 mm',
 'acceptance': ['target qualification (parent pins/links/identity, signed-MTS forecast bitwise = FAILED_MESH polyline = TERMINAL candidate = pinned tip, nominal clearance and 1 mm guard MATRIX_ADVANCE)',
                'pre-admission 7 GiB memory gate, then g2_lp1_admit_state (5 GiB guard, no partial-state retry) with the campaign ledger ADMIT (exactly one, key soft1_S10)',
                'g2_lp2b1eq_geometry PASS (attempt 19/19, canonical = pin, 14 arrays = qualification, pairing 10/10, audit 34/34, four-mask phase audit, 76 chords, protected topology, ring polygons, stations) and expected T3/min angle/max ratio exactly',
                'actual-polygon clearance on the 0.40 mm clearance geometry and the 1 mm guide-to-every-ring guard: MATRIX_ADVANCE (as LP2-A3 computeState)',
                '7 GiB and 5 GiB memory gates before the solve', 'all 16 g2_m4b_sif_partial gates (K.pass)',
                'KI > 0 and admissible tensile MTS root (status OK, stationarity <= 1e-12)',
                'kink admissibility recorded (as LP2-A3)', 'STATE written only after all of the above; TERMINAL with the S11 forecast for information only'],
 'protected': {'knownManifestSHA256': 'e756d64aee23adde0ea4a1662d0e9e77dbae3eb27c1195145a0056367fff1f35', 'knownFiles': 832, 'b1OutputFiles': 43,
               'previousUnionFiles': 891, 'previousUnionManifestSHA256': 'e351f5aca3629da34f99bd25e738bba33ea515ad6d4b6dc7c848bcb4e975d054', 'b1eqCampaignOutputs': 23},
 'historicalRoots': ['outputs/' + d for d in hist],
 'authorization': {'goPath': 'matlab/g2/lp2b1s10/G2_LP2B1S10_GO.json', 'goPresent': False, 'decision': 'GO_LP2B1_S10', 'campaignId': 'G2-LP2B1-S10-001',
                   'campaignScope': 'LP2B1_S10_SOFT1_SINGLE_STATE_0p40', 'runName': 'run_lp2b1_s10_v1', 'runRoot': 'outputs/g2_lp2b1_s10_v1/run_lp2b1_s10_v1',
                   'receiptRoot': 'outputs/g2_lp2b1_s10_receipts/G2-LP2B1-S10-001', 'summaryPath': 'outputs/LP2B1S10_CAMPAIGN.json',
                   'forbiddenRunNames': EQ['authorization']['forbiddenRunNames'] + [EQ['authorization']['runName']],
                   'forbiddenCampaignIds': EQ['authorization']['forbiddenCampaignIds'] + [EQ['authorization']['campaignId']],
                   'contractEvidenceDir': 'docs/research/G2_LP2B1S10_evidence/',
                   'activation': 'GO file only, committed directly on the reviewed head (validator: ancestor + HEAD~1 == approvedHead + sole changed file, via g2_lp2a2_git); single external entry g2_lp2b1s10_external_run writes the ledger RECEIPT; the driver refuses a physical call without it',
                   'resumption': 'none'},
 'records': {'run': ['soft1/S10/GEOMETRY_h040/ATTEMPT.json', 'soft1/S10/GEOMETRY_h040/ATTEMPT_ARRAYS.mat', 'soft1/S10/MESH.mat', 'soft1/S10/PHASE.mat', 'soft1/S10/PHASE.mat.manifest.json',
                     'soft1/S10/SOLUTION.mat', 'soft1/S10/SOLUTION.mat.manifest.json', 'soft1/S10/STATE.mat', 'soft1/S10/STATE.mat.manifest.json', 'soft1/TERMINAL.mat', 'soft1/TERMINAL.mat.manifest.json'],
             'ledger': ['RECEIPT.mat', 'RECEIPT.mat.manifest.json', 'ADMIT_soft1_S10.mat', 'ADMIT_soft1_S10.mat.manifest.json'],
             'onFailure': 'HOLD.json in soft1/S10 (never overwritten); partial records preserved; no TERMINAL, no STATE'},
 'excluded': ['physical FEM during readiness', 'live GO during readiness', 'new STATE during readiness', 'S11 mesh, admission or solve', 'other seed spacings', 'equivalence criteria on the target',
              'LP2-B2', 'retries, resumption or fallback', 'alteration of the closed LP2-A3 ledger or any historical record', 'merges']}
open(out, 'w', encoding='utf-8', newline='\n').write(json.dumps(P, indent=1) + '\n')
print('policy written', out, hashlib.sha256(open(out, 'rb').read()).hexdigest())
