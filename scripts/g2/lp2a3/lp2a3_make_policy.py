"""Generate matlab/g2/lp2a3/G2_LP2A3_POLICY_v1.json (preregistered LP2-A3 policy; NOT authorized; no GO).
Values that already exist are copied mechanically from the accepted policies and evidence:
geometry/q/BVP/cases from the LP2-A policy (which repeats LP1 v2), S8 parent pins from the LP2-A2 policy
(= the accepted LP2-A1 ledger manifest), WP5 qualification evidence from the committed A2 evidence.
usage: python -I lp2a3_make_policy.py <execRepo> <outJson> [<lp2a3SourceSHA256>]"""
import json, hashlib, os, sys
R, out = sys.argv[1], sys.argv[2]
lsrc = sys.argv[3] if len(sys.argv) > 3 else 'TO_BE_PINNED'
rd = lambda p: json.load(open(os.path.join(R, p), encoding='utf-8'))
sha = lambda p: hashlib.sha256(open(os.path.join(R, p), 'rb').read()).hexdigest()
L2 = rd('matlab/g2/lp2/G2_LP2A_POLICY_v1.json'); EQ = rd('matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json')
man = rd('docs/research/G2_LP2_evidence/campaign_20261125/LP2A_RUN_LEDGER_SHA256.json')
base = 'outputs/g2_lp2a_paths_v1/run_lp2a_s5_s8_v1'
par = {}
for c in ('H', 'stiff13', 'soft2', 'soft1'):
    p = {f: man[f'{base}/{c}/S8/{f}.mat'] for f in ('STATE', 'MESH', 'PHASE', 'SOLUTION')}
    p['TERMINAL'] = man[f'{base}/{c}/TERMINAL.mat']
    assert p == EQ['pins']['archivedS8'][c], c  # LP2-A1 ledger manifest == LP2-A2 policy pins
    par[c] = p
ev = 'docs/research/G2_LP2A2_evidence/eq_campaign_A2/'
arc = rd(ev + 'post/LP2A2_EQ_A2_ARCHIVE_RECORD.json')
rec = {k: v for k, v in sorted(arc['memberSHA256'].items()) if k.startswith('outputs/g2_lp2a2_eq_v1/')}
assert len(rec) == 24
qfiles = [ev + 'post/LP2A2_EQ_A2_ARCHIVE_RECORD.json', ev + 'verify/LP2A2_EQ_A2_INDEPENDENT_AUDIT.json', ev + 'verify/LP2A2_EQ_A2_AUDIT_DUMP.json',
          ev + 'closure/LP2A2_EQ_CLOSURE_VERIFY.json', ev + 'closure/LP2A2_EQ_CLOSURE_FINAL.json', ev + 'closure/LP2A2_EQ_CLOSURE_TESTS.json',
          ev + 'closure/ARCHIVE_UNCHANGED.json', ev + 'campaign/LP2A2_EQ_A2_CAMPAIGN.json']
labels = ['MATRIX_ADVANCE', 'INTERFACE_APPROACH', 'INTERFACE_ENCOUNTER', 'HOLE_BOUNDARY_APPROACH', 'EXTERNAL_BOUNDARY_APPROACH',
          'PASSIVE_CONTOUR_APPROACH', 'NUMERICAL_HOLD', 'CAMPAIGN_LIMIT_REACHED']
P = {
 'schema': 'NewMetacomp.G2.LP2A3.Policy.v1',
 'status': 'PROPOSED_NOT_AUTHORIZED',
 'assignment': 'G2-LP2-A3, https://github.com/mfs9697/NewMetacomp/issues/74; start head 666c3a7842299ec8f95f8a325df01f5c24dde588 (PR #71)',
 'scope': 'Restricted matrix-confined continuation of the four accepted LP2-A1 S8 paths to at most S11 with the LP2-A2 paired-bank mesh family at the default 0.45 mm seed spacing ONLY; unchanged LP1/LP2 numerics, BVP, SIF gates and signed MTS; per-case termination at the first non-MATRIX_ADVANCE classification or local numerical HOLD',
 'authority': {
   'wp5ScientificAcceptance': 'https://github.com/mfs9697/NewMetacomp/pull/71#pullrequestreview-6063867614',
   'wp5FinalClosure': 'https://github.com/mfs9697/NewMetacomp/pull/71#pullrequestreview-6064434652',
   'lp2a1Acceptance': 'https://github.com/mfs9697/NewMetacomp/pull/70#pullrequestreview-6056658077',
   'lp2a1Head': 'ed5c6e605fcff56e78178331df844d21c11863c6'},
 'lp1PolicyFile': 'matlab/g2/G2_LP1_POLICY_v2.json', 'lp1PolicySHA256': sha('matlab/g2/G2_LP1_POLICY_v2.json'),
 'lp2PolicyFile': 'matlab/g2/lp2/G2_LP2A_POLICY_v1.json', 'lp2PolicySHA256': sha('matlab/g2/lp2/G2_LP2A_POLICY_v1.json'),
 'lp2a2PolicyFile': 'matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json', 'lp2a2PolicySHA256': sha('matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json'),
 'sourcePins': {'g2SourceSHA256': L2['g2SourceSHA256'], 'lp2SourceSHA256': EQ['pins']['lp2SourceSHA256'],
   'lp2a2SourceSHA256': EQ['pins']['lp2a2SourceSHA256'], 'lp2a3SourceSHA256': lsrc,
   'definition': 'g2: sorted relative-path sha256 lines of matlab/g2/*.m and matlab/g2/vendor_p010_a14d8872/*.m; lp2, lp2a2, lp2a3: sorted "name sha256" lines of the folder *.m; SHA-256 of the newline-joined string (g2_lp1_digest)'},
 'cases': L2['cases'],
 'parents': {'run': base, 'stateIndex': 8, 'authority': 'accepted LP2-A1 campaign G2-LP2A-001 (PR #70, review 6056658077); the ORIGINAL S8 STATE is the authoritative parent (full-precision polyline, tangent, signed KI/KII); WP5 records are NOT parents',
   'manifest': 'docs/research/G2_LP2_evidence/campaign_20261125/LP2A_RUN_LEDGER_SHA256.json', 'manifestSHA256': sha('docs/research/G2_LP2_evidence/campaign_20261125/LP2A_RUN_LEDGER_SHA256.json'),
   'S8': par,
   'terminalCandidateRule': 'the S9 forecast of g2_lp2_forecast from the S8 STATE under this policy must equal TERMINAL.candidate.polyline_mm of the accepted LP2-A1 chain bitwise (isequal)'},
 'meshTransition': 'S8 parents were solved with the LP1 mesh family (g2_kinked_join); S9-S11 use the LP2-A2 family (g2_lp2a2_join, 0.45 mm paired bank seeds). Eligibility of the new family rests on the WP5 fixed-S8 equivalence (qualificationEvidence), not on new S9-S11 comparisons; the parent S8 geometry/SIFs are not recomputed',
 'qualificationEvidence': {
   'campaign': 'G2-LP2A2-EQ-001 activation A2 (GO 820efd4, revoked 886c230), outcome EQUIVALENT; replay closure VERIFIED_V2',
   'records': [{'path': k, 'sha256': v} for k, v in rec.items()], 'archiveSHA256': arc['sha256'], 'archiveName': arc['archive'], 'archiveManifestSHA256': arc['manifestSHA256'],
   'evidenceFiles': [{'path': f, 'sha256': sha(f)} for f in qfiles],
   'use': 'eligibility of the mesh family only; never a parent state and never an acceptance threshold for S9-S11'},
 'caps': {'firstStateIndex': 9, 'maxStateIndex': 11, 'statesPerCaseMax': 3, 'maxAdmissions': 12, 'initialArc_mm': 25.4, 'increment_mm': 4,
   'maxArcLength_mm': 69.4, 'arcByState_mm': {'S9': 61.4, 'S10': 65.4, 'S11': 69.4}, 'adaptiveStep': False, 'retry': False, 'resumption': False,
   'informationOnlyForecast': 'S12 (geometry only, no admission, mesh or FEM; outside the campaign)'},
 'meshFamily': {'function': 'g2_lp2a3_mesh = g2_lp2a2_join(...,ExteriorOptions,[xo,{SeedSpacing_mm,0.45}]) + g2_lp2a2_pairing_audit (identical to rung 1 of g2_lp2a2_mesh)',
   'seedSpacing_mm': 0.45, 'fallbackRungs': 'NONE: a rung-1 failure stops the case (TERMINAL NUMERICAL_HOLD); no other seed spacing, also not for diagnostics of a live candidate',
   'ExpectedVertices': 'stateIndex + 2', 'ExteriorOptions': EQ['meshFamily']['options'],
   'gates': 'inherited 34 kink-mesh gates (g2_lp1_audit), P1-P10 pairing audit, four-mask phase audit, owner map, actual-polygon clearance; T3 <= 40000, min angle >= 20 deg, neighbour ratio <= 1.8; 76 chords per circle; protected p010 core 3.0 mm, collar 3.3 mm, 64 sectors, q domains'},
 'ringProximityGuard': {'function': 'g2_lp2a3_guard', 'rule': 'min_i(||tip - c_i|| - R_ring - 15 mm) >= 1 mm for EVERY ring i, irrespective of activation; evaluated on the full-precision candidate tip BEFORE any admission or mesh; exactly 1 mm passes, below fails; no rounding',
   'minGap_mm': 1.0, 'guideRadius_mm': 15, 'ringR_mm': L2['geometry']['ringR_mm'],
   'objectTypes': 'active ring -> PHYSICAL_INTERFACE (INTERFACE_APPROACH), passive ring -> NUMERICAL_RING (PASSIVE_CONTOUR_APPROACH); a proximity stop is neither an interface encounter nor crack arrest'},
 'bvp': L2['bvp'], 'qAnnuli_mm': L2['qAnnuli_mm'], 'geometry': L2['geometry'], 'startPolyline_mm': L2['startPolyline_mm'],
 'physics': L2['physics'],
 'classification': {'function': 'matlab/g2/lp2a3/g2_lp2a3_classify.m (wraps the unchanged g2_lp2_classify, adds the ring-proximity guard)', 'labels': labels,
   'precedence': 'INTERFACE_APPROACH > HOLE_BOUNDARY_APPROACH > EXTERNAL_BOUNDARY_APPROACH > PASSIVE_CONTOUR_APPROACH > NUMERICAL_HOLD',
   'passiveContour': 'a candidate whose ONLY failing constraints are NUMERICAL_RING (passive ring contour) is PASSIVE_CONTOUR_APPROACH (LP2-A1 reported this as NUMERICAL_HOLD)',
   'failureClasses': 'g2_lp2a3_failure_class = g2_lp2_failure_class + LP2-A3 local identifiers (mesh rung-1 failure, pairing, actual-polygon clearance)'},
 'acceptance': 'a new state is accepted only after the unchanged inherited gates (34 mesh gates, pairing P1-P10, phase/owner, actual-polygon clearance, 16 SIF gates of g2_m4b_sif_partial, MTS status OK with stationarity <= 1e-12, positive KI) and verified record completion; WP5 criteria C1-C11 are fixed-S8 cross-family comparisons and are NOT acceptance thresholds; there are no archived S9-S11 states to compare with',
 'authorization': {'goPath': 'matlab/g2/lp2a3/G2_LP2A3_GO.json', 'goPresent': False, 'decision': 'GO_LP2A3_PHYSICAL', 'campaignId': 'G2-LP2A3-001',
   'campaignScope': 'LP2A3_S9_S11_MAX12', 'runName': 'run_lp2a3_s9_s11_v1', 'runRoot': 'outputs/g2_lp2a3_paths_v1/run_lp2a3_s9_s11_v1',
   'ledgerRoot': 'outputs/g2_lp2a3_campaign_ledger/G2-LP2A3-001',
   'forbiddenRunNames': L2['authorization']['forbiddenRunNames'] + ['run_lp2a_s5_s8_v1'],
   'forbiddenCampaignIds': L2['authorization']['forbiddenCampaignIds'] + ['G2-LP2A-001', 'G2-LP2A2-EQ-001'],
   'contractEvidenceDir': 'docs/research/G2_LP2A3_evidence/',
   'activation': 'GO file only, committed directly on the reviewed head (validator: ancestor + HEAD~1 == approvedHead + sole changed file, via g2_lp2a2_git)',
   'resumption': 'none'},
 'resources': {'matlabRelease': 'R2023a', 'pdeRequired': True, 'oneMatlabProcess': True, 'freeRAMBeforeMATLABStart_GiB_min': 8.2,
   'freeRAMInsideMATLAB_GiB_min': 7, 'preflightGuard_GiB': 5, 'archiveDevices': 2,
   'memoryTiming': 'g2_lp2a2_eq_memgate(7) immediately before each admission (failure before the state folder exists: pre-admission memory HOLD, global) and again immediately before each solve (failure after admission: global HOLD); the inherited 5 GiB guard of g2_lp1_admit_state and of the solve is unchanged; no automatic retry'},
 'stopRules': ['per case: stop at the first candidate that is not MATRIX_ADVANCE (terminal record, no mesh, no solve)',
   'per case: stop at the first local numerical HOLD (rung-1 mesh failure, audit, pairing, phase, actual clearance, SIF gates, MTS) with TERMINAL NUMERICAL_HOLD; accepted prefix preserved; never retried',
   'per case: CAMPAIGN_LIMIT_REACHED after an accepted S11 (an S12 candidate is forecast for information only)',
   'global: source, policy, authorization, memory, record/ledger integrity or any unexpected error stops the whole campaign with a ledger HOLD; partial records preserved; no resumption',
   'at most 3 admissions per case and 12 in total; no retry, no resumption, no adaptive step, no guide reduction, no passive-ring crossing, no fallback seed spacing'],
 'analysis': {'quantities': 'G, J, signed KI/KII, KII/KI, local MTS, global heading, signed lateral tip offset relative to H, tip-to-ring circle, guide-to-ring gap, segment clearance, phase activity, mesh/solver diagnostics, terminal reason, last accepted state',
   'matching': 'only accepted arclengths s = 25.4 + 4k common to the compared chains; no interpolation or extrapolation',
   'preregistered': 'see docs/research/G2_LP2A3_READINESS_MEMO_UA.md section WP3'},
 'excluded': ['physical FEM during preparation', 'accepted states during preparation', 'fallback seed spacing', 'S12 admission', 'passive-ring crossing',
   'guide reduction', 'adaptive stepping', 'interface propagation / CZM', 'LP2-B', 'physical arrest claims', 'changes to historical sources, policies, records or archives']}
open(out, 'w', encoding='utf-8', newline='\n').write(json.dumps(P, indent=1, ensure_ascii=False) + '\n')
print('written', out, hashlib.sha256(open(out, 'rb').read()).hexdigest())
