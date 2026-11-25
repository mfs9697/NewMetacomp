function T=g2_lp2a2_eq_tests(varargin)
%G2_LP2A2_EQ_TESTS  Zero-FEM qualification of the PREPARED SIF-equivalence package.
%  E1 context: every pin verified, token formed, no GO file present
%  E2 identity: archived S8 solution compared with itself passes every criterion with zero deltas;
%     the S9 forecast recomputed from the archived K equals the TERMINAL candidate bitwise
%  E3 negatives: each criterion fails when its quantity is perturbed to twice its tolerance
%  E4 contrast: identity passes; F_G shift of 1.5x tolerance, sign flip and MTS shift fail
%  E5 refusal: Run=true with the correct token -> G2LP2A2:HOLD_UNAUTHORIZED, no output folder
%  E6 dry calls: all four solves READY_NOT_SOLVED (new-family mesh, audits, pairing, phase map;
%     zero solves, no write)
ip=inputParser;addParameter(ip,'Dry',true,@islogical);parse(ip,varargin{:});
C=g2_lp2a2_eq_context();pol=C.policy;tol=pol.tolerances;R={};
R{end+1}=t('E1_context_pins_token',~isempty(strfind(C.token,'G2LP2A2EQ|policy='))&&~isfile(fullfile(C.repo,pol.goFile))&&strcmp(pol.status,'PREREGISTERED_NOT_AUTHORIZED'));
ids={'H','stiff13','soft2','soft1'};KA=struct();
pol9=jsondecode(fileread(fullfile(C.here,'lp2','G2_LP2A_POLICY_v1.json')));pol9.caps.maxStateIndex=9;pol9.caps.maxArcLength_mm=61.4;
lp=jsondecode(fileread(fullfile(C.here,'G2_LP1_POLICY_v2.json')));pm=jsondecode(fileread(fullfile(C.here,'G2_MATERIAL_POLICY_v1.json')));
po=struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm);
for k=1:4
 ab=fullfile(C.archiveBase,ids{k});St=load(fullfile(ab,'S8','STATE.mat'));St=St.record;So=load(fullfile(ab,'S8','SOLUTION.mat'));So=So.record;
 Tm=load(fullfile(ab,'TERMINAL.mat'));Tm=Tm.record;Ma=load(fullfile(ab,'S8','MESH.mat'));
 PMa=g2_material_phase_map(Ma.X6,Ma.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),po);ch=arrayfun(@(q)size(q.chords,1),PMa.interfaces);
 F=g2_lp2_forecast(St,pol9);
 A=struct('state',St,'K',So.K,'D',Ma,'S9tip_mm',Tm.candidate.polyline_mm(end,:),'chordsPerCircle',ch);
 N=struct('K',So.K,'D',Ma,'activeArea_mm2',So.K.activeArea_mm2,'chordsPerCircle',ch,'S9tip_mm',F.polyline_mm(end,:));
 I=g2_lp2a2_eq_compare(N,A,tol);mv=cell2mat(struct2cell(rmfield(I.metrics,{'newJoverGminus1','newCODminusEDI_rel','archivedCODminusEDI_rel','newPathSpread_rel','archivedPathSpread_rel','newQuad4x4_rel','archivedQuad4x4_rel'})));
 R{end+1}=t(sprintf('E2_identity_%s',ids{k}),I.pass&&all(mv==0)&&isequal(F.polyline_mm,Tm.candidate.polyline_mm)); %#ok<AGROW>
 KA.(ids{k})=So.K;
 if k==1
  Keq=hypot(So.K.KI,So.K.KII);neg={};
  neg(end+1,:)={'KI','C1_KI',@(n)setK(n,'KI',n.K.KI+2*tol.KI_overKeq*Keq)};
  neg(end+1,:)={'KII','C2_KII',@(n)setK(n,'KII',n.K.KII+2*tol.KII_overKeq*Keq)};
  neg(end+1,:)={'J','C4_G_J',@(n)setK(n,'J',n.K.J*(1+2*tol.J_rel))};
  neg(end+1,:)={'COD','C6_COD_EDI',@(n)setK(n,'KI_COD',n.K.KI_COD+sign(n.K.KI_COD-n.K.KI)*2*tol.dCODminusEDI*Keq)};
  neg(end+1,:)={'spread','C7_EDI_spread_quadrature',@(n)setEDI(n,2*max(tol.spreadFloor,tol.spreadFactor*1.7e-6)*Keq)};
  neg(end+1,:)={'opening','C8_crackOpening',@(n)scaleOpening(n,1+2*tol.openingWholeCrackRel)};
  neg(end+1,:)={'chords','C9_phaseActivation',@(n)setfield(n,'chordsPerCircle',n.chordsPerCircle+1)}; %#ok<SFLD>
  neg(end+1,:)={'area','C9_phaseActivation',@(n)setfield(n,'activeArea_mm2',n.activeArea_mm2+1e-6*max(n.activeArea_mm2,1))}; %#ok<SFLD>
  neg(end+1,:)={'S9tip','C10_S9predictor',@(n)setfield(n,'S9tip_mm',n.S9tip_mm+[2*tol.S9tipDisplacement_mm 0])}; %#ok<SFLD>
  neg(end+1,:)={'compliance','C11_compliance',@(n)setK(n,'compliance_mm_per_N',n.K.compliance_mm_per_N*(1+2*tol.compliance_rel))};
  for q=1:size(neg,1)
   Iq=g2_lp2a2_eq_compare(neg{q,3}(N),A,tol);
   R{end+1}=t(['E3_negative_',neg{q,1}],~Iq.pass&&any(strcmp(Iq.failed,neg{q,2}))); %#ok<AGROW>
  end
 end
end
Ci=g2_lp2a2_eq_contrast(KA,KA,tol);R{end+1}=t('E4_contrast_identity',Ci.pass&&all(Ci.dFG==0));
KB=KA;KB.soft2.KI=KB.soft2.KI*sqrt(1+1.5*tol.contrast_FG_abs/(1+Ci.FG_archived(2)));Cb=g2_lp2a2_eq_contrast(KB,KA,tol);
R{end+1}=t('E4_contrast_FG_shift',~Cb.pass&&any(strcmp(Cb.failed,'FG_within')));
KB=KA;KB.soft2.KI=KB.soft2.KI*sqrt(1.03);Cb=g2_lp2a2_eq_contrast(KB,KA,tol);R{end+1}=t('E4_contrast_sign_flip',~Cb.pass&&any(strcmp(Cb.failed,'FG_signs')));
KB=KA;KB.soft1.KII=KB.soft1.KII+0.0004*KB.soft1.KI;Cb=g2_lp2a2_eq_contrast(KB,KA,tol);R{end+1}=t('E4_contrast_MTS_shift',~Cb.pass&&any(strcmp(Cb.failed,'MTS_contrast_within')));
od=fullfile(C.repo,pol.outputRoot);ex0=exist(od,'dir');
try,g2_lp2a2_eq_run('EQ-H','Run',true,'Token',C.token);ok=false;catch ME,ok=strcmp(ME.identifier,'G2LP2A2:HOLD_UNAUTHORIZED');end
R{end+1}=t('E5_refusal_without_GO',ok&&exist(od,'dir')==ex0&&~ex0);
if ip.Results.Dry
 for k=1:4
  sid=pol.solves(k).id;
  try,O=g2_lp2a2_eq_run(sid);ok=strcmp(O.stage,'READY_NOT_SOLVED')&&O.physicalSolves==0&&strcmp(O.auditGates,'34/34')&&O.phaseAuditPass&&O.phaseMapPass&&O.pairingAudit==10;
   fprintf('EQ_DRY %s T3 %d (archived %d) pairsT6 %d (archived bank nodes %d) chords %s/%s\n',sid,O.T3,O.archivedT3,O.bankPairsT6,O.archivedBankNodesT6,mat2str(O.chordsPerCircle),mat2str(O.archivedChordsPerCircle));
  catch ME,ok=false;fprintf('EQ_DRY %s ERROR %s\n',sid,ME.message);end
  R{end+1}=t(['E6_dry_',sid],ok&&~exist(od,'dir')); %#ok<AGROW>
 end
end
T=struct('schema','NewMetacomp.G2.LP2A2.EQ.Tests.v1','physicalSolves',0,'token',C.token,'lp2a2SourceSHA256',C.lp2a2SourceSHA256,'policySHA256',C.policySHA256, ...
 'passed',nnz(cellfun(@(r)r.pass,R)),'total',numel(R),'tests',{R});
fprintf('LP2A2_EQ_TESTS %d/%d\n',T.passed,T.total);
end

function r=t(name,ok),r=struct('name',name,'pass',logical(ok));fprintf('EQ_TEST %-32s %d\n',name,ok);end
function n=setK(n,f,v),n.K.(f)=v;end
function n=setEDI(n,d),n.K.EDI_all(2,1)=n.K.EDI_all(2,1)+d;end
function n=scaleOpening(n,f)
U=reshape(n.K.u,2,[]);up=n.D.upperBankT6(:);P=n.D.crackPolyline;far=vecnorm(n.D.X6(up,:)-P(end,:),2,2)>3.3+1e-9;
lo=n.D.lowerBankT6(:);
% scale the jump of every far-field pair by f (upper moved away from lower)
[~,iu]=sort(vecnorm(n.D.X6(up,:)-P(1,:),2,2));[~,il]=sort(vecnorm(n.D.X6(lo,:)-P(1,:),2,2));up=up(iu);lo=lo(il);far=far(iu);
U(:,up(far))=U(:,lo(far))+f*(U(:,up(far))-U(:,lo(far)));n.K.u=U(:);
end
