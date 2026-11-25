"""Generate G2_LP2A2_EQ_POLICY_v1.json (preregistered SIF-equivalence policy; no GO).
usage: python -I make_eq_policy.py <execRepo> <outJson> [lp2a2SourceSHA256]"""
import json, hashlib, sys, os
R, out = sys.argv[1], sys.argv[2]
lsrc = sys.argv[3] if len(sys.argv) > 3 else 'TO_BE_PINNED'
sha = lambda p: hashlib.sha256(open(os.path.join(R, p), 'rb').read()).hexdigest()
man = json.load(open(os.path.join(R, 'docs/research/G2_LP2_evidence/campaign_20261125/LP2A_RUN_LEDGER_SHA256.json'), encoding='utf-8'))
base = 'outputs/g2_lp2a_paths_v1/run_lp2a_s5_s8_v1'
lp2 = json.load(open(os.path.join(R, 'matlab/g2/lp2/G2_LP2A_POLICY_v1.json'), encoding='utf-8'))
arch = {}
for c in ('H', 'stiff13', 'soft2', 'soft1'):
    arch[c] = {f: man[f'{base}/{c}/S8/{f}.mat'] for f in ('STATE', 'MESH', 'PHASE', 'SOLUTION')}
    arch[c]['TERMINAL'] = man[f'{base}/{c}/TERMINAL.mat']
P = {
 'schema': 'NewMetacomp.G2.LP2A2.SIFEquivalencePolicy.v1',
 'status': 'PREREGISTERED_NOT_AUTHORIZED',
 'scope': 'Four fixed-geometry solves on the accepted LP2-A1 S8 geometries with the LP2-A2 paired-bank mesh family; '
          'each compared with its archived LP2-A1 S8 solution. No trajectory, no state acceptance, no S9 solve.',
 'goFile': 'matlab/g2/lp2a2/G2_LP2A2_EQ_GO.json',
 'goRequirement': 'An explicit investigator decision GO_LP2A2_EQ in the PR thread. The GO file (g2_lp2a2_eq_go_validate) must give decision GO_LP2A2_EQ, the token, solveLimit 4, solves exactly EQ-H, EQ-stiff13, EQ-soft2, EQ-soft1 in this order, the campaignId, a decision URL of the form https://github.com/mfs9697/NewMetacomp/pull/<n>#issuecomment-<n> or #pullrequestreview-<n>, the full 40-hex approved (reviewed) head, and the contract-evidence file with its SHA-256. The activation commit must add only the GO file directly on the approved head. Physical calls require the normal preflight. No GO exists in this policy commit.',
 'campaignId': 'G2-LP2A2-EQ-001',
 'outputRoot': 'outputs/g2_lp2a2_eq_v1',
 'solves': [
   {'id': 'EQ-H', 'geometry': 'H S8', 'material': 'H', 'caseId': 'H', 'mask': [0, 0, 0], 'ratio': 1},
   {'id': 'EQ-stiff13', 'geometry': 'stiff13 S8', 'material': 'stiff13', 'caseId': 'stiff13', 'mask': [1, 0, 1], 'ratio': 2},
   {'id': 'EQ-soft2', 'geometry': 'soft2 S8', 'material': 'soft2', 'caseId': 'soft2', 'mask': [0, 1, 0], 'ratio': 0.5},
   {'id': 'EQ-soft1', 'geometry': 'soft1 S8', 'material': 'soft1', 'caseId': 'soft1', 'mask': [1, 0, 0], 'ratio': 0.5}],
 'solveLimit': 4, 'attemptsPerSolve': 1, 'retry': False, 'adaptiveStep': False,
 'pins': {
   'lp1PolicySHA256': sha('matlab/g2/G2_LP1_POLICY_v2.json'),
   'lp2PolicySHA256': sha('matlab/g2/lp2/G2_LP2A_POLICY_v1.json'),
   'g2SourceSHA256': lp2['g2SourceSHA256'],
   'lp2SourceSHA256': '357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca',
   'lp2a2SourceSHA256': lsrc,
   'lp2a2SourceDefinition': 'g2_lp1_digest over sorted lines "<name> <sha256>" of matlab/g2/lp2a2/*.m',
   'testSetSHA256': sha('docs/research/G2_LP2A2_evidence/LP2A2_TEST_SET.json'),
   'archivedS8': arch},
 'meshFamily': {'mesher': 'g2_lp2a2_mesh (seed-spacing ladder over g2_lp2a2_join = g2_kinked_regular_block + g2_lp2a2_exterior_mesh)',
   'seedSpacingRungs_mm': [0.45, 0.40, 0.50, 0.35], 'requiredRung': 1,
   'rungRule': 'next rung only when the global join quality gates fail; the equivalence campaign requires rung 1 (0.45 mm) on all four S8 geometries; a continuation state meshed at a higher rung differs from rung 1 only in the bank seed spacing and is NOT covered by this campaign',
   'options': {'BottomVertices_mm': [25.4, 482.6], 'TopVertices_mm': 254, 'TipGuideRadius_mm': 15, 'TipGuideHface_mm': 1.5, 'MaxT3Elements': 40000},
   'unchanged': 'p010 core 3.0 mm, collar 3.3 mm, 64 sectors, q domains, COD/EDI, phase mapping, 15-mm guide, 4-mm increment, all LP1/LP2 acceptance criteria',
   'difference': 'explicit paired bank seeds: m_k = ceil(L_k/0.45) pieces per centre-line segment (starter 57 instead of the old 51), guide-circle crossings as forced paired seeds; the exterior PDE mesh is regenerated'},
 'bvp': lp2['bvp'], 'qAnnuli_mm': lp2['qAnnuli_mm'],
 'tolerances': {
   'E_MPa': lp2['bvp']['E_MPa'],
   'KI_overKeq': 5e-4, 'KII_overKeq': 5e-5, 'KIIoverKI_abs': 1e-4,
   'G_rel': 1e-3, 'J_rel': 1e-3, 'newJoverGminus1': 1e-4,
   'MTS_deg': 0.006, 'S9tipDisplacement_mm': 5e-4,
   'newCODminusEDI_gate': 0.03, 'dCODminusEDI': 1e-3,
   'spreadFloor': 1e-5, 'spreadFactor': 5, 'quadFloor': 1e-5, 'quadFactor': 5,
   'openingNearTipRel': 1e-3, 'openingWholeCrackRel': 2e-3,
   'activeArea_rel': 1e-9, 'compliance_rel': 1e-3,
   'contrast_FG_abs': 2e-4, 'contrast_MTS_deg': 0.01},
 'toleranceJustification': {
   'reference_A1': 'A1 near-tip refinement m=0->9 at S4: deltaG ~1.1e-4 relative, deltaTheta_MTS 1.2-1.8e-4 deg, |deltaF_G| <= 5.1e-6, EDI change <= 6e-5, COD-EDI 8.8e-3 -> 2.5e-3 (A1 report).',
   'reference_LP2A1': 'LP2-A1 S8: COD-EDI 0.876-0.880 %, path spread 1.64e-6, |J/G-1| <= 3.1e-5, K_II/K_I 0.0079-0.0146; per-step F_G change >= 0.34 percentage points; smallest |F_G| 1.488 % (soft2); S9 relative headings +0.406, -0.060, -0.506 deg; stiff13 local MTS difference +0.383 deg.',
   'expected_effect': 'The near-tip core and collar are identical; only the bank discretization outside the collar and the exterior PDE mesh change. The change is therefore expected to be of the order of far-field discretization effects, at or below the A1 near-tip sensitivity.',
   'KI_G_J': 'G/J within 1e-3 (K_I within 5e-4 K_eq): about 10x the A1 near-tip sensitivity, yet at least 15x below the smallest architecture contrast (1.49 %) and 3x below one step of F_G change.',
   'KII_MTS': 'MTS ~ -2 K_II/K_I rad for small mixity; K_II within 5e-5 K_eq gives |dTheta| <= 0.0057 deg: 30x the A1 refinement change, 10 % of the smallest S9 relative heading (soft1 -0.060 deg) and 1.5 % of the stiff13 MTS contrast.',
   'S9predictor': 'A 4-mm step with |dTheta| <= 0.006 deg moves the predicted tip by <= 4.2e-4 mm; the tolerance is 5e-4 mm.',
   'COD_EDI': 'The inherited 3 % gate must hold; the change of the blind COD-EDI difference must stay within 1e-3 (A1 refinement changed it by 6e-3 with a refined near-tip mesh; here the near-tip mesh is identical).',
   'spread_quadrature': 'Path spread and 4x4 quadrature differences must stay below max(1e-5, 5x the archived value).',
   'opening': 'Near-tip jumps at identical node positions within 1e-3 of the near-tip maximum; whole-crack jump (archived linearly interpolated to the new stations) within 2e-3 of the maximum opening.',
   'phase': 'Activation labels verified by the solver gates, same ring chord count, active ring area identical to 1e-9 relative (CAD circles, same chords).',
   'contrast': 'F_G = G_X/G_H - 1 recomputed from the four new solutions must differ from the archived contrast by <= 2e-4 absolute (<= 1.4 % of the smallest contrast, <= 6 % of one step) with unchanged sign and order; theta_X - theta_H within 0.01 deg.'},
 'interpretation': {
   'EQUIVALENT': 'All criteria of all four solves and the contrast check pass: the LP2-A2 mesh family reproduces the accepted S8 results within the preregistered numerical tolerances. This is NUMERICAL EQUIVALENCE on four geometries, NOT a certified discretization-error bound for either family and not a convergence statement.',
   'NOT_EQUIVALENT': 'Any criterion fails: HOLD; the new family may not be used for continuation until the difference is explained in a separate review. No retry, no tolerance change after any solve.'},
 'resources': {'freeRAMInsideMATLAB_GiB_min': 7, 'preflightGuard_GiB': 5, 'matlabProcesses': 1, 'archiveDevices': 2,
   'freeRAMBeforeMATLABStart_GiB_min': 8.2},
 'activation': {'label': 'A2',
   'previous': 'A1: GO 91667cf on 4d3701e, revoked 91718b0, HOLD_LP2A2_EQ_ACTIVATION_BINDING_WINDOWS_CARET before the first wrapper call, zero solves; its authorization (PR #71 issuecomment-7167996437) is consumed and may not be reused',
   'externalScript': 'matlab/g2/lp2a2/g2_lp2a2_eq_external_run.m',
   'prestartCheck': 'scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1 (>= 8.2 GiB available before MATLAB starts, no MATLAB process, removable backup drive)',
   'gitQueries': 'g2_lp2a2_git: parent as HEAD~1 (never an unquoted caret, which cmd.exe consumes), exit status checked, commit accepted only as an exact 40-hex output',
   'evidenceAndArchiveNames': 'docs/research/G2_LP2A2_evidence/eq_campaign_A2/, LP2A2_EQ_A2_*.json, NewMetacomp_G2_LP2A2_EQ_A2_Records_<date>.zip'},
 'excluded': ['accepted S9 states', 'trajectory continuation', 'adaptive stepping', 'guide reduction', 'passive-ring crossing', 'interface/CZM', 'M5', 'changes to any LP1/A0/A1/M5-X6/LP2-A1 record']}
open(out, 'w', encoding='utf-8', newline='\n').write(json.dumps(P, indent=1, ensure_ascii=False) + '\n')
print('written', out, hashlib.sha256(open(out, 'rb').read()).hexdigest())
