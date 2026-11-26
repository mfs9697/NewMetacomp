function T=g2_lp2b1eq_tests(varargin)
%G2_LP2B1EQ_TESTS  Zero-FEM readiness qualification of the prospective LP2-B1-EQ controller (no physical solve).
% Real archived LP2-A3 references and LP2-B1 qualification arrays are READ only; every write goes to a fresh folder
% under tempdir; no GO is created in the repository; g2_m4b_sif_partial is never called (every driver test injects a
% non-solving operation; the default solve operation of the test contexts is a sentinel that fails the test).
%  A  context, pins, token, no GO, roots absent, real-preflight refusal without GO, preflight bypass, unknown solve
%  B  archived references (u length/order, gates, links, parents, next state S10/S11, exported data, H zero area)
%  C  comparator: archived-vs-itself positive controls; end-to-end perturbations per criterion (signed KII, low
%     mixity, H exact zero area); invalid/missing/nonfinite inputs; identity and predictor selection; C8 stations
%  L  criteria boundaries: every subgate at (passes), beyond by one ulp (fails) and inside its tolerance
%  D  canonical digest of the qualification arrays (= LP2-B1 serialization) and metadata
%  E  protected topology under global renumbering; merge/swap/rotation/coordinate mutations
%  F  C8 station coverage of the 0.40 mm banks against the archived banks; archived jump interpolation
%  G  driver with injected operations: GO, receipt, order, historical root, memory, test-injection refusal,
%     REAL geometry with a mismatching digest (HOLD before FEM), REAL geometry + fabricated non-solving K (complete
%     record set, INPUT_INVALID, verifier), one attempt only, global stop of the campaign wrapper
%  M  memory gate      H  GO validator (pure)      I  real git through system() on inert fixtures
%  J  read-only verifier: positive-control record sets, JSON round trip ([] / null / malformed / mismatched),
%     missing / extra / partial records, hash links, receipt, global stop, unchanged files
%  K  regression: corrected WP5 closure replay and LP2-A3 campaign verification (read-only)
ip=inputParser;addParameter(ip,'RealGeometry',true,@islogical);addParameter(ip,'RealGit',true,@islogical);addParameter(ip,'Regression',true,@islogical);
addParameter(ip,'OutFile','',@ischar);parse(ip,varargin{:});o=ip.Results;
if ~isempty(o.OutFile),assert(~isfile(o.OutFile),'B1EQT:Overwrite','Test output exists; tests are never overwritten.');end
T0=tic;R={};
C=g2_lp2b1eq_context('Preflight',false);pol=C.policy;tol=pol.tolerances;s1=C.solves{1};s2=C.solves{2};
% ---------------------------------------------------------------- A (A0 first: fresh MATLAB for the real preflight)
R{end+1}=t('A0_no_GO_refused_with_real_preflight',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',C.token),'G2LP2B1EQ:HOLD_UNAUTHORIZED')&&~isfolder(C.runRoot)&&~isfolder(C.receiptRoot));
R{end+1}=t('A1_token_status_no_GO',startsWith(C.token,'G2LP2B1EQ|policy=')&&strcmp(pol.status,'PROPOSED_NOT_AUTHORIZED')&&~isfile(C.goFile)&&isequal(pol.authorization.goPresent,false));
R{end+1}=t('A2_run_and_receipt_roots_absent',~isfolder(C.runRoot)&&~isfolder(C.receiptRoot));
ids=cellfun(@(x)x.id,C.solves,'UniformOutput',false);
R{end+1}=t('A3_two_solves_fixed_order_limit2_seed040',isequal(ids,{'EQB-soft1-S9','EQB-H-S10'})&&pol.solveLimit==2&&pol.attemptsPerSolve==1&&~pol.retry&&~pol.adaptiveStep&&pol.meshFamily.seedSpacing_mm==0.40&&~pol.targetSolve);
w5=jsondecode(fileread(fullfile(C.here,'lp2a2','G2_LP2A2_EQ_POLICY_v1.json'))).tolerances;
R{end+1}=t('A4_tolerances_equal_WP5',tol.KI_overKeq==5e-4&&tol.KII_overKeq==5e-5&&tol.KIIoverKI_abs==1e-4&&tol.G_rel==1e-3&&tol.J_rel==1e-3&&tol.newJoverGminus1==1e-4&& ...
 tol.MTS_deg==0.006&&tol.newCODminusEDI_gate==0.03&&tol.dCODminusEDI==1e-3&&tol.spreadFloor==1e-5&&tol.spreadFactor==5&&tol.quadFloor==1e-5&&tol.quadFactor==5&& ...
 tol.openingNearTipRel==1e-3&&tol.openingWholeCrackRel==2e-3&&tol.activeArea_rel==1e-9&&tol.compliance_rel==1e-3&&tol.nextTipDisplacement_mm==w5.S9tipDisplacement_mm&& ...
 tol.nextTipDisplacement_mm==5e-4&&tol.E_MPa==3268.115&&~isfield(tol,'contrast_FG_abs'));
R{end+1}=t('A5_preflight_bypass_refused',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Preflight',false,'Token',C.token),'G2LP2B1EQ:HOLD_PREFLIGHT_REQUIRED'));
R{end+1}=t('A6_unknown_solve_refused',refuses(@()g2_lp2b1eq_run('EQB-soft1-S10','Preflight',false),'G2LP2B1EQ:HOLD_UNKNOWN_SOLVE')&&refuses(@()g2_lp2b1eq_run('EQ-H','Preflight',false),'G2LP2B1EQ:HOLD_UNKNOWN_SOLVE'));
hr=cellstr(pol.historicalRoots);
R{end+1}=t('A7_new_roots_not_historical',~any(contains(hr,'g2_lp2b1_eq_'))&&any(strcmp(hr,'outputs/g2_lp2a3_paths_v1'))&&any(strcmp(hr,'outputs/g2_lp2b1_geometry_v1')));
R{end+1}=t('A8_target_is_provenance_only',strcmp(pol.provenanceOnly.targetCanonicalSHA256,'54293d2a527f9bec33605ffea10c8f56af46a56291157f0d911cf68301b85bd2')&& ...
 ~any(strcmp({s1.qualification.canonicalSHA256,s2.qualification.canonicalSHA256},pol.provenanceOnly.targetCanonicalSHA256))&&~any(contains(ids,'S10')&contains(ids,'soft1')));
% ---------------------------------------------------------------- B references
Ref1=g2_lp2b1eq_reference(C,s1);Ref2=g2_lp2b1eq_reference(C,s2);RC=containers.Map({s1.id,s2.id},{Ref1,Ref2});
R{end+1}=t('B1_soft1_S9_reference_all_checks',Ref1.pass);
R{end+1}=t('B2_H_S10_reference_all_checks',Ref2.pass);
R{end+1}=t('B3_u_length_2NT6_interleaved_order',Ref1.checks.uShape&&Ref1.checks.uOrdering&&Ref2.checks.uShape&&Ref2.checks.uOrdering&&Ref1.uLength==2*Ref1.N_T6&&Ref2.uLength==2*Ref2.N_T6);
R{end+1}=t('B4_next_state_S10_S11_bitwise',strcmp(Ref1.nextState,'S10')&&strcmp(Ref2.nextState,'S11')&&isequal(Ref1.nextTip_mm,[114.29544883822506 63.18559491151613])&& ...
 isequal(Ref2.nextTip_mm,[116.53715206030587 66.63469316681929]));
R{end+1}=t('B5_active_area_soft1_positive_H_exact_zero',Ref1.solution.K.activeArea_mm2>0&&Ref2.solution.K.activeArea_mm2==0&&Ref2.state.activeArea_mm2==0);
R{end+1}=t('B6_exported_A3_data_and_parents',Ref1.checks.exported&&Ref2.checks.exported&&Ref1.checks.parent&&Ref2.checks.parent&&Ref1.checks.parentRecords&&Ref2.checks.parentRecords);
% ---------------------------------------------------------------- C comparator
[N1,A1,f1]=pc(Ref1,s1);[N2,A2,f2]=pc(Ref2,s2);
P1=g2_lp2b1eq_compare(N1,A1,tol,f1);P2=g2_lp2b1eq_compare(N2,A2,tol,f2);
R{end+1}=t('C0a_positive_control_soft1_all_differences_zero',strcmp(P1.outcome,'EQUIVALENT_CASE')&&zeroDiffs(P1.metrics));
R{end+1}=t('C0b_positive_control_H_all_differences_zero',strcmp(P2.outcome,'EQUIVALENT_CASE')&&zeroDiffs(P2.metrics));
Q1=g2_lp2b1eq_compare_case(C,f1,Ref1,Ref1.solution.K,Ref1.mesh,Ref1.chordsPerCircle);Q2=g2_lp2b1eq_compare_case(C,f2,Ref2,Ref2.solution.K,Ref2.mesh,Ref2.chordsPerCircle);
R{end+1}=t('C0c_compare_case_forecast_S10_soft1',strcmp(Q1.outcome,'EQUIVALENT_CASE')&&Q1.metrics.nextTipDisplacement_mm==0&&strcmp(Q1.vectors.nextState,'S10'));
R{end+1}=t('C0d_compare_case_forecast_S11_H',strcmp(Q2.outcome,'EQUIVALENT_CASE')&&Q2.metrics.nextTipDisplacement_mm==0&&strcmp(Q2.vectors.nextState,'S11'));
R{end+1}=t('C0e_archived_opening_from_saved_u',P1.metrics.newMaxJump_mm>0&&P1.metrics.newMaxJumpNearTip_mm>0&&P1.metrics.nearTipNodes>0&&P2.metrics.nearTipNodes==P2.metrics.nearTipNodesArchived);
K1=hypot(N1.K.KI,N1.K.KII);K2=hypot(N2.K.KI,N2.K.KII);cmp=@(N,A,f)g2_lp2b1eq_compare(N,A,tol,f);
X=N1;X.K.KI=N1.K.KI*(1+1e-3);R{end+1}=t('C1_KI_outside_fails_C1',~cmp(X,A1,f1).criteria.C1_KI);
X=N1;X.K.KI=N1.K.KI+4e-4*K1;R{end+1}=t('C1_KI_inside_passes_C1',cmp(X,A1,f1).criteria.C1_KI);
X=N1;X.K.KII=-N1.K.KII;Y=cmp(X,A1,f1);R{end+1}=t('C2_signed_KII_flip_fails',~Y.criteria.C2_KII&&Y.metrics.dKII_overKeq<0&&abs(Y.metrics.dKII_overKeq+2*N1.K.KII/K1)<1e-15);
X=N2;X.K.KII=N2.K.KII+4e-5*K2;Y=cmp(X,A2,f2);R{end+1}=t('C2_low_mixity_H_inside_C2_C3_C5',Y.criteria.C2_KII&&Y.criteria.C3_KIIoverKI&&Y.criteria.C5_MTS);
X=N2;X.K.KII=N2.K.KII+6e-5*K2;Y=cmp(X,A2,f2);R{end+1}=t('C2_low_mixity_H_outside_C2_and_C5',~Y.criteria.C2_KII&&~Y.criteria.C5_MTS&&abs(Y.metrics.dMTS_deg)>tol.MTS_deg);
X=N1;X.K.J=N1.K.J*(1+2e-3);R{end+1}=t('C4_J_only',onlyFail(cmp(X,A1,f1),{'C4_G_J'}));
X=N1;X.K.compliance_mm_per_N=N1.K.compliance_mm_per_N*(1+2e-3);R{end+1}=t('C11_compliance_only',onlyFail(cmp(X,A1,f1),{'C11_compliance'}));
X=N1;X.K.compliance_mm_per_N=N1.K.compliance_mm_per_N*(1+9e-4);R{end+1}=t('C11_compliance_inside_equivalent',strcmp(cmp(X,A1,f1).outcome,'EQUIVALENT_CASE'));
X=N1;X.K.EDI_all(3,1)=X.K.EDI_all(3,1)+1e-3*K1;R{end+1}=t('C7_path_spread_only',onlyFail(cmp(X,A1,f1),{'C7_EDI_spread_quadrature'}));
X=N1;X.K.EDI4x4(1)=X.K.EDI4x4(1)+1e-3*K1;R{end+1}=t('C7_quadrature_only',onlyFail(cmp(X,A1,f1),{'C7_EDI_spread_quadrature'}));
X=N1;X.K.KI_COD=X.K.KI+0.0305*K1;R{end+1}=t('C6_COD_EDI_only',onlyFail(cmp(X,A1,f1),{'C6_COD_EDI'}));
X=N1;X.K.u=N1.K.u*(1+3e-3);R{end+1}=t('C8_jump_scale_outside_only',onlyFail(cmp(X,A1,f1),{'C8_crackOpening'}));
X=N1;X.K.u=N1.K.u*(1+5e-4);R{end+1}=t('C8_jump_scale_inside_equivalent',strcmp(cmp(X,A1,f1).outcome,'EQUIVALENT_CASE'));
B1=g2_lp2b1eq_banks(N1.D);kn=find(vecnorm(B1.x-N1.D.crackPolyline(end,:),2,2)<=3.3&B1.up~=B1.lo,1,'last');
U1=reshape(N1.K.u,2,[]).';J1=U1(B1.up(kn),:)-U1(B1.lo(kn),:);X=N1;X.K.u(2*B1.up(kn)+(-1:0))=X.K.u(2*B1.up(kn)+(-1:0))+2e-3*P1.metrics.newMaxJumpNearTip_mm*(J1/norm(J1)).';R{end+1}=t('C8_local_near_tip_jump_fails',~cmp(X,A1,f1).criteria.C8_crackOpening);
X=N1;X.activeArea_mm2=N1.activeArea_mm2*(1+1e-6);R{end+1}=t('C9_active_area_soft1_only',onlyFail(cmp(X,A1,f1),{'C9_phaseActivation'}));
X=N1;X.activeArea_mm2=N1.activeArea_mm2*(1+5e-10);R{end+1}=t('C9_active_area_soft1_inside_equivalent',strcmp(cmp(X,A1,f1).outcome,'EQUIVALENT_CASE'));
X=N2;X.activeArea_mm2=1e-12;Y=cmp(X,A2,f2);R{end+1}=t('C9_H_exact_zero_stronger_than_relative',onlyFail(Y,{'C9_phaseActivation'})&&abs(Y.metrics.dActiveArea_rel)<=tol.activeArea_rel);
X=N1;X.chordsPerCircle=[76 76 75];R{end+1}=t('C9_chords_only',onlyFail(cmp(X,A1,f1),{'C9_phaseActivation'}));
X=N1;X.K.criteria.elasticEquilibrium=false;X.K.pass=false;R{end+1}=t('C9_solver_gate_only',onlyFail(cmp(X,A1,f1),{'C9_phaseActivation'}));
X=N1;X.nextTip_mm=A1.nextTip_mm+[4.9e-4 0];R{end+1}=t('C10_inside_equivalent',strcmp(cmp(X,A1,f1).outcome,'EQUIVALENT_CASE'));
X=N1;X.nextTip_mm=A1.nextTip_mm+[0 5.1e-4];R{end+1}=t('C10_outside_only',onlyFail(cmp(X,A1,f1),{'C10_nextPredictor'}));
% invalid inputs (verification-infrastructure HOLD)
inv={'u_NaN',@(N)setK(N,'u',[NaN;N.K.u(2:end)]),'U_SHAPE: new';'u_short',@(N)setK(N,'u',N.K.u(1:end-2)),'U_SHAPE: new';
 'u_missing',@(N)setfield(N,'K',rmfield(N.K,'u')),'K_FIELDS: new';'KI_NaN',@(N)setK(N,'KI',NaN),'K_NONFINITE: new KI';
 'KII_complex',@(N)setK(N,'KII',N.K.KII+1i),'K_NONFINITE: new KII';'EDI_all_size',@(N)setK(N,'EDI_all',N.K.EDI_all(1:4,:)),'K_EDI_ALL: new';
 'EDI4x4_empty',@(N)setK(N,'EDI4x4',[]),'K_EDI4X4: new';'gates_15',@(N)setK(N,'criteria',rmfield(N.K.criteria,'elasticEquilibrium')),'K_GATES_SHAPE: new';
 'KI_zero',@(N)setK(N,'KI',0),'NEW_KI_ZERO';'chords_missing',@(N)setfield(N,'chordsPerCircle',[]),'CHORDS: new';
 'nextTip_NaN',@(N)setfield(N,'nextTip_mm',[NaN NaN]),'NEXT_TIP: new'}; %#ok<SFLD>
for k=1:size(inv,1),Y=cmp(inv{k,2}(N1),A1,f1);R{end+1}=t(['C_invalid_' inv{k,1}],isInvalid(Y,inv{k,3}));end %#ok<AGROW>
Y=A1;Y.K.KI=-A1.K.KI;R{end+1}=t('C_invalid_archived_KI_negative',isInvalid(cmp(N1,Y,f1),'ARCHIVED_NONPOSITIVE'));
Y=A1;Y.K.criteria.KIpositive=false;R{end+1}=t('C_invalid_archived_gate_false',isInvalid(cmp(N1,Y,f1),'ARCHIVED_GATES'));
% identity and predictor selection
idt={'solve',@(N,A,f)deal(setId(N,'solveId','EQB-H-S10'),A,f),'IDENTITY_SOLVE';'case',@(N,A,f)deal(setId(N,'caseId','H'),A,f),'IDENTITY_CASE';
 'state',@(N,A,f)deal(setId(N,'stateIndex',10),A,f),'IDENTITY_STATE';'mask',@(N,A,f)deal(setId(N,'mask',[0 0 0]),A,f),'IDENTITY_MASK';
 'canonical',@(N,A,f)deal(setId(N,'canonicalSHA256',repmat('0',1,64)),A,f),'IDENTITY_CANONICAL_MESH';
 'archived_solution_pin',@(N,A,f)deal(N,setfield(A,'id',struct('solutionSHA256',repmat('1',1,64))),f),'IDENTITY_ARCHIVED_SOLUTION';
 'geometry',@(N,A,f)deal(setfield(N,'D',setfield(N.D,'crackPolyline',N.D.crackPolyline+[0 1e-12])),A,f),'IDENTITY_GEOMETRY';
 'hardcoded_S9_predictor',@(N,A,f)deal(setfield(N,'nextState','S9'),setfield(A,'nextState','S9'),f),'IDENTITY_NEXT_STATE';
 'S11_for_soft1',@(N,A,f)deal(setfield(N,'nextState','S11'),A,f),'IDENTITY_NEXT_STATE';
 'H_next_tip_for_soft1',@(N,A,f)deal(N,setfield(A,'nextTip_mm',A2.nextTip_mm),f),'IDENTITY_ARCHIVED_NEXT_TIP'}; %#ok<SFLD>
for k=1:size(idt,1),[Xn,Xa,Xf]=idt{k,2}(N1,A1,f1);R{end+1}=t(['C_identity_' idt{k,1}],isInvalid(cmp(Xn,Xa,Xf),idt{k,3}));end %#ok<AGROW>
R{end+1}=t('C_predictor_selection_S10_vs_S11',strcmp(f1.nextPredictor.state,'S10')&&strcmp(f2.nextPredictor.state,'S11')&&isInvalid(cmp(N2,A2,f1),'IDENTITY_SOLVE'));
% C8 stations
up=N1.D.upperBankT6;
X=N1;X.D.upperBankT6(2)=up(1);R{end+1}=t('C8_duplicate_bank_id',isInvalid(cmp(X,A1,f1),'C8_NEW_BANK_DUPLICATE_ID'));
X=N1;X.D.lowerBankT6=X.D.lowerBankT6(1:end-1);R{end+1}=t('C8_unpaired_bank_lengths',isInvalid(cmp(X,A1,f1),'C8_NEW_BANK_INDEX'));
nb=setdiff(unique(N1.D.T6(:)),[N1.D.upperBankT6(:);N1.D.lowerBankT6(:)]);X=N1;X.D.lowerBankT6(5)=nb(1);R{end+1}=t('C8_bank_pairing',isInvalid(cmp(X,A1,f1),'C8_NEW_BANK_PAIRING'));
X=N1;X.D.lowerBankT6(X.D.lowerBankT6==B1.lo(10))=B1.up(10);R{end+1}=t('C8_merged_coincident_ids',isInvalid(cmp(X,A1,f1),'C8_NEW_BANK_SHARED_ID'));
X=N1;X.D.X6([B1.up(kn) B1.lo(kn)],1)=X.D.X6([B1.up(kn) B1.lo(kn)],1)+1e-6;R{end+1}=t('C8_near_tip_identity',isInvalid(cmp(X,A1,f1),'C8_NEAR_TIP_IDENTITY'));
Ba=g2_lp2b1eq_banks(A1.D);Y=A1;Y.D.upperBankT6=setdiff(A1.D.upperBankT6,Ba.up(1),'stable');Y.D.lowerBankT6=setdiff(A1.D.lowerBankT6,Ba.lo(1),'stable');
R{end+1}=t('C8_no_extrapolation',isInvalid(cmp(N1,Y,f1),'C8_EXTRAPOLATION'));
X=N1;X.K.u=zeros(size(N1.K.u));R{end+1}=t('C8_zero_normalization',isInvalid(cmp(X,A1,f1),'C8_ZERO_NORMALIZATION'));
% ---------------------------------------------------------------- L criteria boundaries
m0=P1.metrics;R{end+1}=t('L0_base_all_true',all(cellfun(@(x)x,struct2cell(g2_lp2b1eq_criteria(m0,tol)))));
up1=@(x)x+eps(x);
L={'C1_KI','dKI_overKeq',tol.KI_overKeq;'C2_KII','dKII_overKeq',tol.KII_overKeq;'C3_KIIoverKI','dKIIoverKI',tol.KIIoverKI_abs;'C4_G_J','dG_rel',tol.G_rel;
 'C4_G_J','dJ_rel',tol.J_rel;'C4_G_J','newJoverGminus1',tol.newJoverGminus1;'C5_MTS','dMTS_deg',tol.MTS_deg;'C6_COD_EDI','dCODminusEDI',tol.dCODminusEDI;
 'C9_phaseActivation','dActiveArea_rel',tol.activeArea_rel;'C11_compliance','dCompliance_rel',tol.compliance_rel};
for k=1:size(L,1)
 [c,f,v]=L{k,:};
 R{end+1}=t(sprintf('L_%s_%s_at_plus_tol',c,f),only(m0,tol,f,v,c,true)); %#ok<AGROW>
 R{end+1}=t(sprintf('L_%s_%s_at_minus_tol',c,f),only(m0,tol,f,-v,c,true)); %#ok<AGROW>
 R{end+1}=t(sprintf('L_%s_%s_beyond_plus',c,f),only(m0,tol,f,up1(v),c,false)); %#ok<AGROW>
 R{end+1}=t(sprintf('L_%s_%s_beyond_minus',c,f),only(m0,tol,f,-up1(v),c,false)); %#ok<AGROW>
end
L2={'C6_COD_EDI','newCODminusEDI_rel',tol.newCODminusEDI_gate;'C8_crackOpening','openingNearTipRel',tol.openingNearTipRel;
 'C8_crackOpening','openingWholeCrackRel',tol.openingWholeCrackRel;'C10_nextPredictor','nextTipDisplacement_mm',tol.nextTipDisplacement_mm};
for k=1:size(L2,1)
 [c,f,v]=L2{k,:};
 R{end+1}=t(sprintf('L_%s_%s_at_tol',c,f),only(m0,tol,f,v,c,true)); %#ok<AGROW>
 R{end+1}=t(sprintf('L_%s_%s_beyond',c,f),only(m0,tol,f,up1(v),c,false)); %#ok<AGROW>
 R{end+1}=t(sprintf('L_%s_%s_inside',c,f),only(m0,tol,f,v/2,c,true)); %#ok<AGROW>
end
for q={'Path','Quad'}
 nf=['new' q{1}];if strcmp(q{1},'Path'),nf='newPathSpread_rel';af='archivedPathSpread_rel';fl=tol.spreadFloor;fa=tol.spreadFactor;else,nf='newQuad4x4_rel';af='archivedQuad4x4_rel';fl=tol.quadFloor;fa=tol.quadFactor;end
 m=m0;m.(af)=0;R{end+1}=t(['L_C7_' q{1} '_floor_at'],only(m,tol,nf,fl,'C7_EDI_spread_quadrature',true)); %#ok<AGROW>
 R{end+1}=t(['L_C7_' q{1} '_floor_beyond'],only(m,tol,nf,up1(fl),'C7_EDI_spread_quadrature',false)); %#ok<AGROW>
 m=m0;m.(af)=1e-3;b=max(fl,fa*1e-3);R{end+1}=t(['L_C7_' q{1} '_factor_at'],only(m,tol,nf,b,'C7_EDI_spread_quadrature',true)); %#ok<AGROW>
 R{end+1}=t(['L_C7_' q{1} '_factor_beyond'],only(m,tol,nf,up1(b),'C7_EDI_spread_quadrature',false)); %#ok<AGROW>
end
R{end+1}=t('L_C5_inadmissible_root',only(m0,tol,'newMTSadmissible',false,'C5_MTS',false));
R{end+1}=t('L_C9_solver_gates_false',only(m0,tol,'newSolverGatesPass',false,'C9_phaseActivation',false));
R{end+1}=t('L_C9_chords_false',only(m0,tol,'chordsEqual',false,'C9_phaseActivation',false));
m=m0;m.archivedActiveArea_mm2=0;R{end+1}=t('L_C9_zero_zero_passes',only(m,tol,'newActiveArea_mm2',0,'C9_phaseActivation',true));
R{end+1}=t('L_C9_zero_tiny_fails',only(m,tol,'newActiveArea_mm2',realmin,'C9_phaseActivation',false));
m=m0;m.archivedActiveArea_mm2=5;R{end+1}=t('L_C9_nonzero_archived_rule_not_applied',only(m,tol,'newActiveArea_mm2',realmin,'C9_phaseActivation',true));
m=m0;m.archivedActiveArea_mm2=0;t2=tol;t2.activeAreaExactZeroWhenArchivedZero=false;R{end+1}=t('L_C9_zero_rule_controlled_by_policy_flag',only(m,t2,'newActiveArea_mm2',realmin,'C9_phaseActivation',true));
% ---------------------------------------------------------------- D canonical digests
Qa=cell(1,2);okd=true;mt=cell(1,2);
for k=1:2
 q=C.solves{k}.qualification;qf=fullfile(C.repo,strrep(q.arrays.path,'/',filesep));Qa{k}=load(qf);[h,mt{k}]=g2_lp2b1eq_canon(Qa{k});
 okd=okd&&strcmpi(g2_sha256_file(qf),q.arrays.sha256)&&strcmpi(h,q.canonicalSHA256)&&numel(mt{k})==64;
end
R{end+1}=t('D1_qualification_arrays_reproduce_pinned_canonical',okd&&strcmp(s1.qualification.canonicalSHA256,'7535d71ad4790f3a24a47d03e27c3d73d8ba61df03050a2e952accfeffebee16')&& ...
 strcmp(s2.qualification.canonicalSHA256,'45298fae6257674b99de036341b6d0c05b55fbb6bb7be635786f8ae71bb068e3'));
Tg=load(fullfile(C.repo,'outputs','g2_lp2b1_geometry_v1','wp1_attempt2','T_soft1_S10_h040','ATTEMPT_ARRAYS.mat'));
R{end+1}=t('D2_target_provenance_digest_same_serialization',strcmp(g2_lp2b1eq_canon(Tg),pol.provenanceOnly.targetCanonicalSHA256));
R{end+1}=t('D3_canonical_sensitive_to_one_ulp',~strcmp(g2_lp2b1eq_canon(setfield(Qa{1},'nodalQ',up1(Qa{1}.nodalQ))),s1.qualification.canonicalSHA256)); %#ok<SFLD>
% ---------------------------------------------------------------- E topology
E1=g2_lp2b1eq_topology(Qa{1},Ref1.mesh);E2=g2_lp2b1eq_topology(Qa{2},Ref2.mesh);
R{end+1}=t('E1_soft1_protected_topology_bijection',E1.pass&&E1.blockNodes==5953&&E1.bankPairsInBlock>0);
R{end+1}=t('E2_H_protected_topology_bijection',E2.pass&&E2.blockNodes==5953);
Dr=renumber(Qa{1});R{end+1}=t('E3_global_renumbering_invariant',g2_lp2b1eq_topology(Dr,Ref1.mesh).pass&&~isequal(Dr.T6,Qa{1}.T6));
Bq=g2_lp2b1eq_banks(Qa{1});inb=ismember(Bq.up,Qa{1}.T6(1:2916,:))&ismember(Bq.lo,Qa{1}.T6(1:2916,:))&Bq.up~=Bq.lo;kb=find(inb,1);
Dm=Qa{1};blk=Dm.T6(1:2916,:);blk(blk==Bq.lo(kb))=Bq.up(kb);Dm.T6(1:2916,:)=blk;Em=g2_lp2b1eq_topology(Dm,Ref1.mesh);
coordOnly=isequal(Dm.X6(Dm.T6(1:2916,:),:),Ref1.mesh.X6(Ref1.mesh.T6(1:2916,:),:));
R{end+1}=t('E4_merged_bank_pair_detected_although_coordinates_equal',~Em.pass&&~Em.checks.injective&&coordOnly);
Ds=Qa{1};Ds.upperBankT6=Qa{1}.lowerBankT6;Ds.lowerBankT6=Qa{1}.upperBankT6;R{end+1}=t('E5_swapped_bank_sides_detected',~g2_lp2b1eq_topology(Ds,Ref1.mesh).checks.banks);
Dc=Qa{1};nd=Dc.T6(100,4);Dc.X6(nd,1)=up1(Dc.X6(nd,1));R{end+1}=t('E6_one_ulp_coordinate_detected',~g2_lp2b1eq_topology(Dc,Ref1.mesh).checks.coordinates);
Dt=Qa{1};Dt.T6(100,:)=Dt.T6(100,[2 3 1 5 6 4]);R{end+1}=t('E7_local_rotation_detected',~g2_lp2b1eq_topology(Dt,Ref1.mesh).pass);
R{end+1}=t('E8_H_tip_one_ulp_from_polyline_identical_in_both_meshes',E2.checks.tip&&E2.tipOffsetFromPolyline_mm(1)>0&&E2.tipOffsetFromPolyline_mm(1)<=1e-13&&isequal(E2.tipOffsetFromPolyline_mm(1),E2.tipOffsetFromPolyline_mm(2))&&E1.tipOffsetFromPolyline_mm(1)==0);
Du=Qa{2};Du.X6(Du.physicalTipNode,1)=up1(Du.X6(Du.physicalTipNode,1));Tu=g2_lp2b1eq_topology(Du,Ref2.mesh);
R{end+1}=t('E9_tip_moved_one_ulp_versus_archived_detected',~Tu.pass&&~Tu.checks.tip&&~Tu.checks.coordinates);
% ---------------------------------------------------------------- F C8 station coverage 0.40 mm vs archived
okf=true;F=struct([]);
for k=1:2
 Rk=RC(C.solves{k}.id);Bn=g2_lp2b1eq_banks(Qa{k});Bo=g2_lp2b1eq_banks(Rk.mesh);tip=Rk.state.tip_mm;r=3.3+1e-9;
 nt=find(vecnorm(Bn.x-tip,2,2)<=r);mtc=arrayfun(@(i)min(vecnorm(Bo.x-Bn.x(i,:),2,2))<=1e-9,nt);
 U=reshape(Rk.solution.K.u,2,[]).';ja=vecnorm(U(Bo.up,:)-U(Bo.lo,:),2,2);ji=interp1(Bo.s,ja,Bn.s,'linear');
 e=struct('solveId',C.solves{k}.id,'newPairs',Bn.n,'archivedPairs',Bo.n,'nearNew',numel(nt),'nearArchived',nnz(vecnorm(Bo.x-tip,2,2)<=r),'nearMatched',nnz(mtc), ...
  'rangeNew',[Bn.s(1) Bn.s(end)],'rangeArchived',[Bo.s(1) Bo.s(end)],'interpolatedFinite',all(isfinite(ji)),'archivedMaxJump_mm',max(ja));
 okf=okf&&isempty(Bn.problems)&&isempty(Bo.problems)&&e.nearMatched==e.nearNew&&e.nearNew==e.nearArchived&&e.interpolatedFinite&&Bn.s(1)>=Bo.s(1)&&Bn.s(end)<=Bo.s(end);
 F=[F e]; %#ok<AGROW>
end
R{end+1}=t('F1_C8_station_coverage_and_near_tip_identity_both',okf);
% ---------------------------------------------------------------- M memory gate
mg=@(v)g2_lp2a2_eq_memgate(7,v);
R{end+1}=t('M1_exactly_7_passes',mg(@()7).pass);R{end+1}=t('M2_below_refuses',~mg(@()6.999).pass);
R{end+1}=t('M3_nan_refuses',~mg(@()NaN).pass);R{end+1}=t('M4_query_error_refuses',~mg(@()error('T:x','x')).pass);R{end+1}=t('M5_negative_refuses',~mg(@()-1).pass);
Mr=g2_lp2a2_eq_memgate(7);R{end+1}=t('M6_actual_reading_finite',isfinite(Mr.freeGiB)&&Mr.freeGiB>0);
% ---------------------------------------------------------------- G driver with injected operations
root=fullfile(tempdir,sprintf('lp2b1eq_t_%s',datestr(now,'yyyymmddHHMMSSFFF')));mkdir(root);
cnt=containers.Map({'solve','mem','sentinel'},{0,0,0});
okGate=@(C,tok)struct('pass',true,'approvedHead',repmat('a',1,40),'goFileSHA256',repmat('b',1,64));
memOK=@(m)bumpMem(cnt,m,true);memNo=@(m)bumpMem(cnt,m,false);
refC=@(C,s)RC(s.id);sentinel=@(varargin)sentinelSolve(cnt);
G=struct('notRun',true);
R{end+1}=t('G1_no_GO_refused_real_gate',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',C.token,'Test',tt(mk('g1',false),struct('solve',sentinel))),'G2LP2B1EQ:HOLD_UNAUTHORIZED')&&~isfolder(fullfile(root,'g1','run')));
Cg=mk('g2',false);wf(Cg.goFile,jsonencode(struct('decision','GO_LP2B1_EQ','fixture','INERT_NOT_AN_AUTHORIZATION','approvedHead',repmat('a',1,40))));
R{end+1}=t('G2_inert_GO_file_without_binding_refused',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',C.token,'Test',tt(Cg,struct('solve',sentinel))),'G2LP2B1EQ:HOLD_UNAUTHORIZED')&&~isfolder(Cg.runRoot));
R{end+1}=t('G3_no_receipt_refused',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',C.token,'Test',tt(mk('g3',false),struct('gate',okGate,'solve',sentinel))),'G2LP2B1EQ:HOLD_NO_RECEIPT'));
Cw=mk('g4',false);mkdir(Cw.receiptRoot);g2_trajectory_record('write',fullfile(Cw.receiptRoot,'RECEIPT.mat'),struct('schema','NewMetacomp.G2.LP2B1EQ.Receipt.v1','campaignId',pol.campaignId,'token','WRONG'));
R{end+1}=t('G4_receipt_other_token_refused',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',C.token,'Test',tt(Cw,struct('gate',okGate,'solve',sentinel))),'G2LP2B1EQ:HOLD_NO_RECEIPT'));
Co=mk('g5',true);R{end+1}=t('G5_second_solve_first_refused_order',refuses(@()g2_lp2b1eq_run('EQB-H-S10','Run',true,'Token',C.token,'Test',tt(Co,struct('gate',okGate,'solve',sentinel))),'G2LP2B1EQ:HOLD_ORDER')&&~isfolder(fullfile(Co.runRoot,'EQB-H-S10')));
Ch=mk('g6',true);Ch.historicalRoots{end+1}=fileparts(Ch.runRoot);
R{end+1}=t('G6_historical_root_refused',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',C.token,'Test',tt(Ch,struct('gate',okGate,'solve',sentinel))),'G2LP2B1EQ:HOLD_HISTORICAL_ROOT')&&~isfolder(Ch.runRoot));
Cm=mk('g7',true);R{end+1}=t('G7_memory_refusal_before_folder',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',C.token,'Test',tt(Cm,struct('gate',okGate,'memgate',memNo,'reference',refC,'solve',sentinel))),'G2LP2B1EQ:HOLD_MEMORY')&&~isfolder(fullfile(Cm.runRoot,'EQB-soft1-S9')));
R{end+1}=t('G8_injection_outside_tempdir_refused',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Test',struct('root',C.repo,'context',mk('g8',false))),'G2LP2B1EQ:HOLD_TEST_INJECTION'));
Cx=mk('g9',false);Cx.runRoot=fullfile(C.repo,'outputs','g2_lp2b1_eq_v1','x');
R{end+1}=t('G9_test_context_roots_outside_test_root_refused',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Test',tt(Cx,struct())),'G2LP2B1EQ:HOLD_TEST_INJECTION'));
Cr=mk('g10',false);R{end+1}=t('G10_replay_root_inside_run_root_refused',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Mesh',true,'ReplayRoot',fullfile(Cr.runRoot,'r'),'Test',tt(Cr,struct('reference',refC))),'G2LP2B1EQ:HOLD_INPUT'));
if o.RealGeometry
 Cd=mk('g11',true);Cd.solves{1}.qualification.canonicalSHA256=repmat('0',1,64);s0=cnt('solve');
 R{end+1}=t('G11_real_geometry_digest_mismatch_HOLD_before_FEM',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',C.token,'Test',tt(Cd,struct('gate',okGate,'memgate',memOK,'reference',refC,'solve',sentinel))),'G2LP2B1EQ:HOLD_MESH_QUALIFICATION')&& ...
  cnt('solve')==s0&&cnt('sentinel')==0&&isfile(fullfile(Cd.runRoot,'EQB-soft1-S9','HOLD.json'))&&~isfile(fullfile(Cd.runRoot,'EQB-soft1-S9','MESH.mat'))&&isfile(fullfile(Cd.runRoot,'EQB-soft1-S9','GEOMETRY_h040','ATTEMPT.json')));
 Hd=jsondecode(fileread(fullfile(Cd.runRoot,'EQB-soft1-S9','HOLD.json')));At=jsondecode(fileread(fullfile(Cd.runRoot,'EQB-soft1-S9','GEOMETRY_h040','ATTEMPT.json')));
 R{end+1}=t('G11b_hold_record_stage_geometry_attempt_19',strcmp(Hd.stage,'GEOMETRY')&&At.checksPassed==19&&strcmp(At.canonicalSHA256,s1.qualification.canonicalSHA256));
 Cf=mk('g12',true);m0c=cnt('mem');fk=@(D,act,mats,polT,PM,expect)fakeK(D,act,mats,expect,Ref1,s1,pol,cnt);
 try
  Og=g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',C.token,'Test',tt(Cf,struct('gate',okGate,'memgate',memOK,'reference',refC,'solve',fk)));
 catch ME
  Og=struct('stage',['EXCEPTION ' ME.identifier ': ' ME.message]);
 end
 sd=fullfile(Cf.runRoot,'EQB-soft1-S9');Ti=dir(fullfile(sd,'**','*'));Ti=Ti(~[Ti.isdir]);nf=numel(Ti);
 R{end+1}=t('G12_real_geometry_full_preFEM_path_fabricated_K',strcmp(Og.stage,'SOLVED_COMPARED')&&strcmp(Og.outcome,'INPUT_INVALID')&&any(strcmp(Og.validation,'C8_ZERO_NORMALIZATION'))&& ...
  Og.geometry.pass&&nf==10&&cnt('mem')-m0c==2&&cnt('solve')==1&&cnt('sentinel')==0);
 if strcmp(Og.stage,'SOLVED_COMPARED')
  G=struct('stage',Og.stage,'outcome',Og.outcome,'validation',{Og.validation},'geometry',Og.geometry,'files',nf);
 else
  G=struct('stage',Og.stage,'files',nf);
 end
 Vg=g2_lp2b1eq_verify(Cf,'Reference',refC);
 R{end+1}=t('G12b_verifier_on_driver_records_infrastructure_hold',strcmp(Vg.outcome,'VERIFIED_INFRASTRUCTURE_HOLD')&&Vg.unchanged&&Vg.receipt.tokenOK);
 h0=treeHash(Cf.runRoot);
 R{end+1}=t('G13_one_attempt_no_retry',refuses(@()g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',C.token,'Test',tt(Cf,struct('gate',okGate,'memgate',memOK,'reference',refC,'solve',sentinel))),'G2LP2B1EQ:HOLD_ONE_ATTEMPT')&&isequal(h0,treeHash(Cf.runRoot)));
 Wv=g2_lp2b1eq_campaign('x','Context',Cf,'Validator',@()struct('pass',true,'failed',{{}}),'Runner',@(id)Og);
 R{end+1}=t('G14_campaign_stops_on_infrastructure_hold',strcmp(Wv.outcome,'HOLD_VERIFICATION_INPUT')&&strcmp(Wv.holdKind,'VERIFICATION_INFRASTRUCTURE')&&Wv.solvesCalled==1);
end
% campaign global stop (injected runners; zero solves)
okV=@()struct('pass',true,'failed',{{}});eqO=@(id)struct('stage','SOLVED_COMPARED','outcome','EQUIVALENT_CASE','comparisonPass',true,'newK',struct('KI',1,'KII',0),'solutionSHA256','x','validation',{{}},'failed',{{}});
neO=@(id)struct('stage','SOLVED_COMPARED','outcome','NOT_EQUIVALENT','comparisonPass',false,'newK',struct('KI',1,'KII',0),'solutionSHA256','x','validation',{{}},'failed',{{'C4_G_J'}});
calls=containers.Map('KeyType','char','ValueType','double');
W=g2_lp2b1eq_campaign('x','Context',C,'Validator',okV,'Runner',@(id)rec(calls,id,eqO(id)));R{end+1}=t('G15_both_equivalent_EQUIVALENT_AT_0p40',strcmp(W.outcome,'EQUIVALENT_AT_0p40')&&W.solvesCalled==2);
remove(calls,keys(calls));W=g2_lp2b1eq_campaign('x','Context',C,'Validator',okV,'Runner',@(id)rec(calls,id,neO(id)));
R{end+1}=t('G16_first_not_equivalent_global_stop',strcmp(W.outcome,'NOT_EQUIVALENT_HOLD')&&W.solvesCalled==1&&~isKey(calls,'EQB-H-S10')&&strcmp(W.holdKind,'NUMERICAL_EQUIVALENCE'));
W=g2_lp2b1eq_campaign('x','Context',C,'Validator',okV,'Runner',@(id)error('T:inj','injected first failure'));
R{end+1}=t('G17_injected_exception_global_stop',strcmp(W.outcome,'HOLD_EXCEPTION')&&W.solvesCalled==1&&strcmp(W.stoppedAt,'EQB-soft1-S9'));
W=g2_lp2b1eq_campaign('x','Context',C,'Validator',okV,'Runner',@(id)struct('stage','SOLVED_COMPARED'));R{end+1}=t('G18_incomplete_driver_result_stop',strcmp(W.outcome,'HOLD_INCOMPLETE_RECORD')&&W.solvesCalled==1);
W=g2_lp2b1eq_campaign('x','Context',C,'Validator',@()struct('pass',false,'failed',{{'token'}}),'Runner',@(id)error('T:never','never'));
R{end+1}=t('G19_validator_failure_zero_calls',strcmp(W.outcome,'HOLD_UNAUTHORIZED')&&W.solvesCalled==0);
W=g2_lp2b1eq_campaign('x','Context',mk('g20',false));R{end+1}=t('G20_default_validator_no_GO_zero_calls',strcmp(W.outcome,'HOLD_UNAUTHORIZED')&&W.solvesCalled==0);
% ---------------------------------------------------------------- H GO validator (pure)
gitOK=struct('isAncestor',@(h)true,'headParent',@()repmat('c',1,40),'changedFiles',@(h){pol.authorization.goPath});
evOK=@(p)struct('exists',true,'sha256',repmat('e',1,64),'text',jsonencode(struct('passed',120,'total',120,'physicalSolves',0,'token',C.token)));
G0=struct('decision','GO_LP2B1_EQ','decisionUrl','https://github.com/mfs9697/NewMetacomp/pull/79#issuecomment-1','approvedHead',repmat('c',1,40),'token',C.token, ...
 'campaignId',pol.authorization.campaignId,'campaignScope',pol.authorization.campaignScope,'runName',pol.authorization.runName,'solves',{{'EQB-soft1-S9','EQB-H-S10'}}, ...
 'solveLimit',2,'attemptsPerSolve',1,'seedSpacing_mm',0.40,'contractEvidenceFile',[pol.authorization.contractEvidenceDir 'tests/x.json'],'contractEvidenceSHA256',repmat('e',1,64));
V=@(G,git,ev,tok)g2_lp2b1eq_go_validate(G,C,tok,git,ev);
R{end+1}=t('H0_valid_fixture_passes',V(G0,gitOK,evOK,C.token).pass);
neg={'decision','GO_LP2A3_PHYSICAL','decision';'decisionUrl','https://github.com/other/NewMetacomp/pull/1#issuecomment-1','decisionUrl';'token','x','token';
 'campaignId','G2-LP2A3-001','campaign';'runName','run_lp2a3_s9_s11_v1','campaign';'solves',{'EQB-H-S10','EQB-soft1-S9'},'solves';'solves','EQB-soft1-S9','solves';
 'solves',{'EQB-soft1-S9','EQB-H-S10','EQB-soft1-S10'},'solves';'solveLimit',3,'limits';'attemptsPerSolve',2,'limits';'seedSpacing_mm',0.45,'limits';
 'approvedHead',repmat('C',1,40),'approvedHead';'approvedHead','HEAD^','approvedHead';'contractEvidenceFile','docs/research/../x.json','evidence';
 'contractEvidenceSHA256',repmat('f',1,64),'evidence'};
for k=1:size(neg,1)
 Gk=G0;Gk.(neg{k,1})=neg{k,2};Vk=V(Gk,gitOK,evOK,C.token);R{end+1}=t(sprintf('H%d_%s_%s',k,neg{k,1},neg{k,3}),~Vk.pass&&any(strcmp(Vk.failed,neg{k,3}))); %#ok<AGROW>
end
R{end+1}=t('H_caller_token_differs',~V(G0,gitOK,evOK,'other').checks.token);
R{end+1}=t('H_missing_field',~V(rmfield(G0,'solveLimit'),gitOK,evOK,C.token).checks.fields);
R{end+1}=t('H_not_a_scalar_struct',~V([G0 G0],gitOK,evOK,C.token).pass&&~V([],gitOK,evOK,C.token).pass);
ev1=@(p)struct('exists',true,'sha256',repmat('e',1,64),'text',jsonencode(struct('passed',120,'total',120,'physicalSolves',1,'token',C.token)));
ev2=@(p)struct('exists',true,'sha256',repmat('e',1,64),'text',jsonencode(struct('passed',119,'total',120,'physicalSolves',0,'token',C.token)));
ev3=@(p)struct('exists',true,'sha256',repmat('e',1,64),'text',jsonencode(struct('passed',120,'total',120,'physicalSolves',0,'token','other')));
ev4=@(p)struct('exists',false,'sha256','','text','');
R{end+1}=t('H_evidence_physical_solves',~V(G0,gitOK,ev1,C.token).checks.evidence);R{end+1}=t('H_evidence_not_all_passed',~V(G0,gitOK,ev2,C.token).checks.evidence);
R{end+1}=t('H_evidence_other_token',~V(G0,gitOK,ev3,C.token).checks.evidence);R{end+1}=t('H_evidence_absent',~V(G0,gitOK,ev4,C.token).checks.evidence);
g1=gitOK;g1.isAncestor=@(h)false;R{end+1}=t('H_not_ancestor',~V(G0,g1,evOK,C.token).checks.ancestor);
g2=gitOK;g2.headParent=@()repmat('d',1,40);R{end+1}=t('H_post_revocation_parent_differs',~V(G0,g2,evOK,C.token).checks.activationBinding);
g3=gitOK;g3.changedFiles=@(h){pol.authorization.goPath,'x.m'};R{end+1}=t('H_extra_changed_file',~V(G0,g3,evOK,C.token).checks.activationBinding);
g4=gitOK;g4.changedFiles=@(h){};R{end+1}=t('H_no_changed_file',~V(G0,g4,evOK,C.token).checks.activationBinding);
Gj=jsondecode(jsonencode(G0));R{end+1}=t('H_JSON_round_trip_passes',V(Gj,gitOK,evOK,C.token).pass);
Gn=jsondecode(strrep(jsonencode(G0),'"solves":["EQB-soft1-S9","EQB-H-S10"]','"solves":null'));R{end+1}=t('H_JSON_null_solves_rejected',~V(Gn,gitOK,evOK,C.token).checks.solves);
% ---------------------------------------------------------------- I real git
RG=struct();if o.RealGit,[Ri,RG]=realGit(pol,C);R=[R Ri];end
% ---------------------------------------------------------------- J verifier: positive-control record sets and mutations
Jr=struct();
Cp=mk('j0',true);for k=1:2,Cp.solves{k}.qualification.canonicalSHA256=g2_lp2b1eq_canon(RC(Cp.solves{k}.id).mesh);end
writeSet(Cp,1,RC,[]);writeSet(Cp,2,RC,[]);
Vp=g2_lp2b1eq_verify(Cp,'Reference',refC);Jr.positive=Vp.outcome;
R{end+1}=t('J0_positive_control_two_complete_sets_VERIFIED_EQUIVALENT',strcmp(Vp.outcome,'VERIFIED_EQUIVALENT')&&Vp.unchanged&&isempty(Vp.problems)&&numel(Vp.solves)==2);
R{end+1}=t('J0b_json_closure_all_metrics_and_flags',Vp.solves{1}.compare.ok&&Vp.solves{1}.compare.failedListRawOK&&Vp.solves{1}.compare.metricsAllFinite&& ...
 Vp.solves{1}.compare.criteriaIdentical==11&&Vp.solves{2}.compare.metricsWithinTol==Vp.solves{2}.compare.metricsTotal);
Cn=mk('jnr',false);R{end+1}=t('J1_no_records',strcmp(g2_lp2b1eq_verify(Cn,'Reference',refC).outcome,'NO_RECORDS'));
Ce=mk('jempty',true);mkdir(Ce.runRoot);R{end+1}=t('J2_empty_run_root_hold',strcmp(g2_lp2b1eq_verify(Ce,'Reference',refC).outcome,'VERIFY_HOLD'));
jm={'failed_null',@(x)regexprep(x,'"failed":\s*\[\s*\]','"failed": null'),false;
 'failed_string',@(x)regexprep(x,'"failed":\s*\[\s*\]','"failed": "C1_KI"'),false;
 'failed_nested',@(x)regexprep(x,'"failed":\s*\[\s*\]','"failed": [[]]'),false;
 'failed_mismatch',@(x)regexprep(x,'"failed":\s*\[\s*\]','"failed": ["C1_KI"]'),false;
 'failed_number',@(x)regexprep(x,'"failed":\s*\[\s*\]','"failed": [1]'),false;
 'criterion_flag_flipped',@(x)regexprep(x,'"C11_compliance":\s*true','"C11_compliance": false'),false;
 'metric_changed',@(x)regexprep(x,'"dJ_rel":\s*0\b','"dJ_rel": 1e-9'),false;
 'metric_removed',@(x)regexprep(x,'"dJ_rel":\s*0,\s*',''),false;
 'metric_null',@(x)regexprep(x,'"dJ_rel":\s*0\b','"dJ_rel": null'),false;
 'outcome_text',@(x)regexprep(x,'"outcome":\s*"EQUIVALENT_CASE"','"outcome": "EQUIVALENT"'),false;
 'validation_null',@(x)regexprep(x,'"validation":\s*\[\s*\]','"validation": null'),false;
 'pass_flag',@(x)regexprep(x,'"pass":\s*true','"pass": false','once'),false;
 'whitespace_only',@(x)strrep(x,'"failed": []','"failed":[ ]'),true};
for k=1:size(jm,1)
 Ck=mk(['jm' num2str(k)],true);for q=1:2,Ck.solves{q}.qualification=Cp.solves{q}.qualification;end
 copyfile(Cp.runRoot,Ck.runRoot);f=fullfile(Ck.runRoot,'EQB-soft1-S9','COMPARISON.json');x=fileread(f);y=jm{k,2}(x);changed=~strcmp(x,y);wf(f,y);
 Vk=g2_lp2b1eq_verify(Ck,'Reference',refC);Jr.(['m_' jm{k,1}])=Vk.outcome;
 if jm{k,3},okk=strcmp(Vk.outcome,'VERIFIED_EQUIVALENT');else,okk=changed&&strcmp(Vk.outcome,'VERIFY_HOLD');end
 R{end+1}=t(['J_json_' jm{k,1}],okk); %#ok<AGROW>
end
fm={'missing_comparison_json',@(r)delete(fullfile(r,'EQB-soft1-S9','COMPARISON.json'));'extra_file',@(r)wf(fullfile(r,'EQB-soft1-S9','extra.txt'),'x');
 'mesh_bytes_changed',@(r)resave(fullfile(r,'EQB-soft1-S9','MESH.mat'));'extra_top_file',@(r)wf(fullfile(r,'x.json'),'{}');
 'unexpected_folder',@(r)mkdir(fullfile(r,'EQB-soft1-S10'));'second_only',@(r)rmdir(fullfile(r,'EQB-soft1-S9'),'s')};
for k=1:size(fm,1)
 Ck=mk(['jf' num2str(k)],true);for q=1:2,Ck.solves{q}.qualification=Cp.solves{q}.qualification;end
 copyfile(Cp.runRoot,Ck.runRoot);fm{k,2}(Ck.runRoot);Vk=g2_lp2b1eq_verify(Ck,'Reference',refC);Jr.(['f_' fm{k,1}])=Vk.outcome;
 R{end+1}=t(['J_set_' fm{k,1}],strcmp(Vk.outcome,'VERIFY_HOLD')); %#ok<AGROW>
end
Ck=mk('jp',true);for q=1:2,Ck.solves{q}.qualification=Cp.solves{q}.qualification;end
copyfile(fullfile(Cp.runRoot,'EQB-soft1-S9'),fullfile(Ck.runRoot,'EQB-soft1-S9'));delete(fullfile(Ck.runRoot,'EQB-soft1-S9','COMPARISON*'));
wf(fullfile(Ck.runRoot,'EQB-soft1-S9','HOLD.json'),jsonencode(struct('schema','NewMetacomp.G2.LP2B1EQ.Hold.v1','stage','COMPARISON','identifier','T:inj','message','fixture')));
R{end+1}=t('J_partial_hold_preserved_VERIFIED_PARTIAL_HOLD',strcmp(g2_lp2b1eq_verify(Ck,'Reference',refC).outcome,'VERIFIED_PARTIAL_HOLD'));
mkdir(fullfile(Ck.runRoot,'EQB-H-S10'));copyfile(fullfile(Cp.runRoot,'EQB-H-S10'),fullfile(Ck.runRoot,'EQB-H-S10'));
R{end+1}=t('J_second_after_partial_hold_GLOBAL_STOP',strcmp(g2_lp2b1eq_verify(Ck,'Reference',refC).outcome,'VERIFY_HOLD'));
Cq=mk('jne',true);for q=1:2,Cq.solves{q}.qualification=Cp.solves{q}.qualification;end
writeSet(Cq,1,RC,@(K)setfield(K,'J',K.J*(1+2e-3))); %#ok<SFLD>
Vq=g2_lp2b1eq_verify(Cq,'Reference',refC);R{end+1}=t('J_consistent_not_equivalent_VERIFIED_NOT_EQUIVALENT',strcmp(Vq.outcome,'VERIFIED_NOT_EQUIVALENT')&&Vq.solves{1}.compare.failedListRawOK);
copyfile(fullfile(Cp.runRoot,'EQB-H-S10'),fullfile(Cq.runRoot,'EQB-H-S10'));
R{end+1}=t('J_second_after_not_equivalent_GLOBAL_STOP',strcmp(g2_lp2b1eq_verify(Cq,'Reference',refC).outcome,'VERIFY_HOLD'));
Cz=mk('jrc',false);mkdir(Cz.receiptRoot);g2_trajectory_record('write',fullfile(Cz.receiptRoot,'RECEIPT.mat'),struct('schema','NewMetacomp.G2.LP2B1EQ.Receipt.v1','campaignId',pol.campaignId,'token','other'));
for q=1:2,Cz.solves{q}.qualification=Cp.solves{q}.qualification;end;copyfile(Cp.runRoot,Cz.runRoot);
R{end+1}=t('J_receipt_other_token_hold',strcmp(g2_lp2b1eq_verify(Cz,'Reference',refC).outcome,'VERIFY_HOLD'));
Cy=mk('jnorc',false);for q=1:2,Cy.solves{q}.qualification=Cp.solves{q}.qualification;end;copyfile(Cp.runRoot,Cy.runRoot);
R{end+1}=t('J_receipt_missing_hold',strcmp(g2_lp2b1eq_verify(Cy,'Reference',refC).outcome,'VERIFY_HOLD'));
R{end+1}=t('J_positive_set_unchanged_after_all_replays',strcmp(g2_lp2b1eq_verify(Cp,'Reference',refC).outcome,'VERIFIED_EQUIVALENT'));
% ---------------------------------------------------------------- K regression (read-only)
KR=struct();
if o.Regression
 ev='docs/research/G2_LP2A2_evidence/eq_campaign_A2/';
 Rv=lp2a2_eq_closure_verify(C.repo,'ReferenceDump',fullfile(C.repo,ev,'verify','LP2A2_EQ_A2_AUDIT_DUMP.json'),'ReferenceArchive',fullfile(C.repo,ev,'post','LP2A2_EQ_A2_ARCHIVE_RECORD.json'));
 KR.wp5Closure=Rv.outcome;R{end+1}=t('K1_WP5_closure_replay_VERIFIED_V2',strcmp(Rv.outcome,'VERIFIED_V2')&&Rv.unchanged);
 C3=g2_lp2a3_context('Preflight',false);p3=C3.policy;i3={p3.cases.id};
 V3=struct('rd',C3.runRoot,'lroot',C3.ledgerRoot,'ids',{i3},'masks',reshape([p3.cases.mask],3,[]).','parents',struct(),'pol',p3,'token',C3.token, ...
  'policySHA256',C3.policySHA256,'g2SourceSHA256',C3.g2SourceSHA256,'lp2a2SourceSHA256',C3.lp2a2SourceSHA256,'lp2a3SourceSHA256',C3.lp2a3SourceSHA256,'requireTerminal',true);
 for i=1:numel(i3),Pi=g2_lp2a3_parent(C3,i3{i});V3.parents.(i3{i})=struct('state',Pi.state,'stateSHA256',Pi.stateSHA256);end
 h3=treeHash(C3.runRoot);Rv3=g2_lp2a3_verify(V3);KR.a3=struct('pass',Rv3.pass,'closed',Rv3.closed,'problems',{Rv3.problems});
 R{end+1}=t('K2_LP2A3_campaign_verification_read_only',Rv3.pass&&Rv3.closed&&isequal(h3,treeHash(C3.runRoot)));
end
R{end+1}=t('Z_no_physical_solve_sentinel_never_called',cnt('sentinel')==0);
R{end+1}=t('Z_repository_roots_still_absent',~isfolder(C.runRoot)&&~isfolder(C.receiptRoot)&&~isfile(C.goFile));
rm=true;try,[~,~]=system(sprintf('attrib -R "%s\\*" /S /D',root));rmdir(root,'s');catch,rm=false;end
v=cellfun(@(r)r.pass,R);
T=struct('schema','NewMetacomp.G2.LP2B1EQ.Tests.v1','passed',nnz(v),'total',numel(v),'failedTests',{cellfun(@(r)r.name,R(~v),'UniformOutput',false)}, ...
 'physicalSolves',0,'token',C.token,'policySHA256',C.policySHA256,'lp2b1eqSourceSHA256',C.lp2b1eqSourceSHA256,'sourceCommit',gitHead(C.repo), ...
 'tests',{R},'references',struct('soft1_S9',refSum(Ref1),'H_S10',refSum(Ref2)),'stationCoverage',F,'topology',struct('soft1',E1,'H',E2), ...
 'metadataSHA256',{mt},'driverRealGeometry',G,'verifier',Jr,'regression',KR,'realGit',RG,'tempRootRemoved',rm,'wallSeconds',toc(T0), ...
 'options',o,'matlab',version);
if ~isempty(o.OutFile),fid=fopen(o.OutFile,'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);end
fprintf('LP2B1EQ_TESTS %d/%d (%.1f s)\n',T.passed,T.total,T.wallSeconds);

 function Cx=mk(name,withReceipt)
  % test context: the real context with every write root inside the temp root
  Cx=C;b=fullfile(root,name);mkdir(b);Cx.runRoot=fullfile(b,'run');Cx.receiptRoot=fullfile(b,'receipt');Cx.goFile=fullfile(b,'GO.json');
  if withReceipt
   mkdir(Cx.receiptRoot);g2_trajectory_record('write',fullfile(Cx.receiptRoot,'RECEIPT.mat'),struct('schema','NewMetacomp.G2.LP2B1EQ.Receipt.v1', ...
    'campaignId',pol.campaignId,'token',C.token,'fixture','INERT_TEST_RECEIPT'));
  end
 end
 function S=tt(Cx,ops)
  if ~isfield(ops,'solve'),ops.solve=sentinel;end
  S=struct('root',root,'context',Cx,'ops',ops);
 end
end

% =====================================================================
function r=t(name,ok),r=struct('name',name,'pass',isequal(ok,true));fprintf('LP2B1EQ_TEST %-66s %d\n',name,r.pass);end
function ok=refuses(f,id)
try,f();ok=false;catch ME,ok=strcmp(ME.identifier,id);if ~ok,fprintf('  refused with %s: %s\n',ME.identifier,ME.message);end,end
end
function [N,A,f]=pc(Ref,s)
% positive control: the archived record compared with itself (identity of the 0.45 mm mesh accepted by
% replacing the canonical pin in a COPY of the solve entry; never written to the policy)
K=Ref.solution.K;f=s;f.qualification.canonicalSHA256=g2_lp2b1eq_canon(Ref.mesh);
N=struct('K',K,'D',Ref.mesh,'activeArea_mm2',K.activeArea_mm2,'chordsPerCircle',Ref.chordsPerCircle,'nextTip_mm',Ref.nextTip_mm,'nextState',Ref.nextState, ...
 'id',struct('solveId',s.id,'caseId',s.caseId,'stateIndex',s.stateIndex,'mask',reshape(s.mask,1,3),'canonicalSHA256',f.qualification.canonicalSHA256));
A=struct('state',Ref.state,'K',K,'D',Ref.mesh,'nextTip_mm',Ref.nextTip_mm,'nextState',Ref.nextState,'chordsPerCircle',Ref.chordsPerCircle,'id',struct('solutionSHA256',Ref.solutionSHA256));
end
function ok=zeroDiffs(m)
f={'dKI_overKeq','dKII_overKeq','dKIIoverKI','dG_rel','dJ_rel','dMTS_deg','dCODminusEDI','dCompliance_rel','dActiveArea_rel','nextTipDisplacement_mm', ...
 'openingNearTipRel','openingWholeCrackRel','signedOpeningNearTipRel','signedOpeningWholeCrackRel'};
ok=all(cellfun(@(x)m.(x)==0,f));
end
function ok=onlyFail(Rc,names),ok=Rc.valid&&isequal(sort(Rc.failed(:)).',sort(names));if ~ok,fprintf('  failed=[%s] validation=[%s]\n',strjoin(Rc.failed,','),strjoin(Rc.validation,','));end,end
function ok=isInvalid(Rc,tag)
ok=strcmp(Rc.outcome,'INPUT_INVALID')&&~Rc.valid&&~Rc.pass&&any(startsWith(Rc.validation,tag))&&numel(Rc.failed)==11;
if ~ok,fprintf('  outcome=%s validation=[%s] expected %s\n',Rc.outcome,strjoin(Rc.validation,','),tag);end
end
function N=setK(N,f,v),N.K.(f)=v;end
function N=setId(N,f,v),N.id.(f)=v;end
function ok=only(m,tol,f,v,crit,expect)
m.(f)=v;c=g2_lp2b1eq_criteria(m,tol);fn=fieldnames(c);others=fn(~strcmp(fn,crit));
ok=isequal(c.(crit),expect)&&all(cellfun(@(x)c.(x),others));
end
function D=renumber(D)
n=size(D.X6,1);p=(n:-1:1).';D.X6(p,:)=D.X6;D.T6=p(D.T6);D.upperBankT6=p(D.upperBankT6);D.lowerBankT6=p(D.lowerBankT6);D.nodalQ(p)=D.nodalQ;D.physicalTipNode=p(D.physicalTipNode);
end
function M=bumpMem(cnt,m,ok)
cnt('mem')=cnt('mem')+1;M=struct('pass',ok,'minGiB',m,'freeGiB',9*ok+1,'reason','INJECTED');
end
function K=sentinelSolve(cnt),cnt('sentinel')=cnt('sentinel')+1;error('B1EQT:SENTINEL','The default solve operation must never be called in tests.');end
function K=fakeK(D,act,mats,expect,Ref,s,pol,cnt)
% injected NON-SOLVING operation: checks what the driver passes to the solver, returns the archived K fields with a
% zero displacement vector of the NEW mesh length (so the comparison is INPUT_INVALID by design; no FEM)
cnt('solve')=cnt('solve')+1;
ok=strcmp(g2_lp2b1eq_canon(D),s.qualification.canonicalSHA256)&&numel(act.phaseForAssembly)==size(D.T6,1)&&mats(1).E==pol.bvp.E_MPa&& ...
 mats(2).E==pol.bvp.E_MPa*s.ratio&&mats(1).nu==0.35&&strcmp(mats(1).plane,'stress')&&expect.P_N==1&&expect.thickness_mm==12.7&&isequal(expect.load_mm,[254 203.2]);
assert(ok,'B1EQT:FAKE_INPUTS','Driver passed unexpected solver inputs.');
K=Ref.solution.K;K.u=zeros(2*size(D.X6,1),1);K.fixture='INERT_NON_SOLVING_OPERATION';
end
function O=rec(m,id,O),if isKey(m,id),m(id)=m(id)+1;else,m(id)=1;end,end
function writeSet(Cx,k,RC,mod)
% complete record set of one solve, written like the driver, from the ARCHIVED arrays and K (inert positive control)
s=Cx.solves{k};Ref=RC(s.id);sd=fullfile(Cx.runRoot,s.id);mkdir(fullfile(sd,'GEOMETRY_h040'));
D=Ref.mesh;mf=fullfile(sd,'MESH.mat');save(mf,'-struct','D','-v7.3');mh=lower(g2_sha256_file(mf));D=load(mf);cn=g2_lp2b1eq_canon(D);
af=fullfile(sd,'GEOMETRY_h040','ATTEMPT_ARRAYS.mat');X3=D.X3;save(af,'X3','-v7.3');
wf(fullfile(sd,'GEOMETRY_h040','ATTEMPT.json'),jsonencode(struct('pass',true,'canonicalSHA256',cn,'arraysFileSHA256',lower(g2_sha256_file(af)),'fixture','INERT_POSITIVE_CONTROL')));
Ph=struct('schema','NewMetacomp.G2.LP2B1EQ.Phase.v1','solveId',s.id,'caseId',s.caseId,'stateIndex',s.stateIndex,'mask',reshape(s.mask,1,3),'meshSHA256',mh, ...
 'canonicalSHA256',cn,'owner',Ref.phase.owner,'labels',Ref.phase.labels,'chordsPerCircle',Ref.chordsPerCircle,'token',Cx.token);
ph=lower(g2_trajectory_record('write',fullfile(sd,'PHASE.mat'),Ph));K=Ref.solution.K;if ~isempty(mod),K=mod(K);end
S=struct('schema','NewMetacomp.G2.LP2B1EQ.Solution.v1','solveId',s.id,'caseId',s.caseId,'stateIndex',s.stateIndex,'meshSHA256',mh,'phaseSHA256',ph,'canonicalSHA256',cn, ...
 'policySHA256',Cx.policySHA256,'lp2b1eqSourceSHA256',Cx.lp2b1eqSourceSHA256,'token',Cx.token,'K',K,'archivedSolutionSHA256',Ref.solutionSHA256,'fixture','INERT');
sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),S));Rc=g2_lp2b1eq_compare_case(Cx,s,Ref,K,D,Ref.chordsPerCircle);
Cm=struct('schema','NewMetacomp.G2.LP2B1EQ.Comparison.v1','solveId',s.id,'caseId',s.caseId,'stateIndex',s.stateIndex,'solutionSHA256',sh,'meshSHA256',mh,'phaseSHA256',ph, ...
 'canonicalSHA256',cn,'archivedSolutionSHA256',Ref.solutionSHA256,'token',Cx.token,'outcome',Rc.outcome,'valid',Rc.valid,'validation',{Rc.validation},'pass',Rc.pass, ...
 'criteria',Rc.criteria,'failed',{Rc.failed},'metrics',Rc.metrics,'vectors',Rc.vectors,'interpretation','INERT positive-control fixture');
cmh=lower(g2_trajectory_record('write',fullfile(sd,'COMPARISON.mat'),Cm));Cm.comparisonRecordSHA256=cmh;
wf(fullfile(sd,'COMPARISON.json'),jsonencode(Cm,'PrettyPrint',true));
end
function resave(f),S=load(f);S.fixtureTamper=1;save(f,'-struct','S','-v7.3');end
function wf(p,txt),d=fileparts(p);if ~isfolder(d),mkdir(d);end;fid=fopen(p,'w');fwrite(fid,txt,'char');fclose(fid);end
function H=treeHash(root)
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);H=cell(numel(d),2);
for k=1:numel(d),p=fullfile(d(k).folder,d(k).name);H{k,1}=p;H{k,2}=lower(g2_sha256_file(p));end
H=sortrows(H,1);
end
function h=gitHead(repo),[~,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));h=strtrim(h);end
function s=refSum(R)
s=struct('pass',R.pass,'checks',R.checks,'nextState',R.nextState,'nextTip_mm',R.nextTip_mm,'uLength',R.uLength,'N_T6',R.N_T6,'loadNode',R.loadNode,'pinNode',R.pinNode, ...
 'rollerNode',R.rollerNode,'banks',R.banks,'maxJump_mm',R.maxJump_mm,'maxJumpNearTip_mm',R.maxJumpNearTip_mm,'chordsPerCircle',R.chordsPerCircle, ...
 'activeArea_mm2',R.state.activeArea_mm2,'activeAreaRecomputed_mm2',R.archivedActiveAreaRecomputed_mm2,'KI',R.state.KI,'KII',R.state.KII,'mts',R.mts, ...
 'stateSHA256',R.stateSHA256,'solutionSHA256',R.solutionSHA256,'meshSHA256',R.meshSHA256,'phaseSHA256',R.phaseSHA256);
end
function [R,Rec]=realGit(pol,C)
% real git through MATLAB system() (cmd.exe on Windows) on disposable inert fixtures outside the repository
R={};fx=fullfile(tempdir,sprintf('lp2b1eq_git_%s',datestr(now,'yyyymmddHHMMSSFFF')));fr=[fx '_root'];fn=[fx '_notrepo'];
[~,gv]=system('git --version');goF=pol.authorization.goPath;
Rec=struct('matlab',version,'comSpec',getenv('ComSpec'),'git',strtrim(gv),'cases',struct([]));
try
 mkdir(fx);sh(sprintf('git init -q "%s"',fx));sh(sprintf('git -C "%s" config core.autocrlf false',fx));
 wf(fullfile(fx,'README_FIXTURE.txt'),'Inert LP2-B1-EQ git fixture; not an authorization; no token.');c0=commit(fx);
 wf(fullfile(fx,'evidence.txt'),'inert');c1=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b valid %s',fx,c1));wf(fullfile(fx,strrep(goF,'/',filesep)),'{"fixture":"INERT_NOT_AN_AUTHORIZATION"}');cA=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b extra %s',fx,c1));wf(fullfile(fx,strrep(goF,'/',filesep)),'{"fixture":"INERT"}');wf(fullfile(fx,'extra.txt'),'x');cX=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b revoked %s',fx,cA));sh(sprintf('git -C "%s" rm -q "%s"',fx,goF));cV=commit(fx);
 mkdir(fr);sh(sprintf('git init -q "%s"',fr));wf(fullfile(fr,'a.txt'),'root');cR=commit(fr);mkdir(fn);
 Rec.commits=struct('c0',c0,'c1',c1,'cA',cA,'cX',cX,'cV',cV,'cR',cR);
 tokF='FIXTURE-INERT-TOKEN';Cf=struct('repo',fx,'policy',pol,'token',tokF,'solves',{C.solves});
 evF=@(p)struct('exists',true,'sha256',repmat('b',1,64),'text',jsonencode(struct('passed',60,'total',60,'physicalSolves',0,'token',tokF)));
 G=struct('decision','GO_LP2B1_EQ','decisionUrl','https://github.com/mfs9697/NewMetacomp/pull/79#issuecomment-1','approvedHead',c1,'token',tokF, ...
  'campaignId',pol.authorization.campaignId,'campaignScope',pol.authorization.campaignScope,'runName',pol.authorization.runName,'solves',{{'EQB-soft1-S9','EQB-H-S10'}}, ...
  'solveLimit',2,'attemptsPerSolve',1,'seedSpacing_mm',0.40,'contractEvidenceFile',[pol.authorization.contractEvidenceDir 'x.json'],'contractEvidenceSHA256',repmat('b',1,64));
 K={'valid','valid',c1,fx,true,true;'wrong_parent','valid',c0,fx,false,false;'extra_file','extra',c1,fx,false,false;'post_revocation','revoked',c1,fx,false,false;
    'root_commit','',c1,fr,false,false;'not_a_repo','',c1,fn,false,false};
 for k=1:size(K,1)
  [nm,br,ah,rp,expV,expP]=K{k,:};if ~isempty(br),sh(sprintf('git -C "%s" checkout -q %s',rp,br));end
  Ck=Cf;Ck.repo=rp;Vk=g2_lp2b1eq_go_validate(setfield(G,'approvedHead',ah),Ck,tokF,[],evF); %#ok<SFLD>
  Pk=g2_lp2b1eq_external_run(ah,'','','ParentCheckOnly',true,'Repo',rp);Hp=g2_lp2a2_git('parent',rp);
  R{end+1}=t(['I_real_git_' nm],Vk.pass==expV&&Pk.pass==expP); %#ok<AGROW>
  c=struct('case',nm,'approvedHead',ah,'parentStatus',Hp.status,'parentValue',Hp.value,'command',strrep(Hp.command,rp,'<fixture>'),'validatorPass',Vk.pass,'failed',{Vk.failed},'externalPass',Pk.pass);
  if isempty(Rec.cases),Rec.cases=c;else,Rec.cases(end+1)=c;end
 end
 sh(sprintf('git -C "%s" checkout -q valid',fx));[s1,o1]=system(sprintf('git -C "%s" rev-parse HEAD^',fx));
 if ispc,R{end+1}=t('I_cmd_caret_defect_still_reproduced_HEAD_tilde_used',s1==0&&strcmp(strtrim(o1),cA));end
 try,g2_lp2a2_git('isAncestor',fx,'HEAD^');okm=false;catch ME,okm=strcmp(ME.identifier,'G2LP2A2:GIT_UNSAFE_ARG');end
 R{end+1}=t('I_metacharacter_argument_refused',okm);
catch ME
 fprintf('LP2B1EQ I ERROR %s: %s\n',ME.identifier,ME.message);R{end+1}=t('I_fixture_error',false);
end
for d={fx,fr,fn},if isfolder(d{1}),[~,~]=system(sprintf('attrib -R "%s\\*" /S /D',d{1}));try,rmdir(d{1},'s');catch,end,end,end
end
function sh(cmd),[st,o]=system(cmd);assert(st==0,'B1EQT:SETUP','fixture setup failed (%d): %s',st,o);end
function c=commit(root)
sh(sprintf('git -C "%s" add -A',root));sh(sprintf('git -C "%s" -c user.name=lp2b1eq-fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false commit -q -m fixture',root));
[st,o]=system(sprintf('git -C "%s" rev-parse --verify HEAD',root));c=strtrim(o);assert(st==0&&~isempty(regexp(c,'^[0-9a-f]{40}$','once')),'B1EQT:SETUP','commit hash');
end
