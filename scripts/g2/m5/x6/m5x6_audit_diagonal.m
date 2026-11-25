function R=m5x6_audit_diagonal(C,outFile)
%M5X6_AUDIT_DIAGONAL  WP1.1: independent read-only audit of the four authoritative A1 B9 solutions.
% Never recomputes a solve. For H, stiff13, soft2, soft1 on their own S4 paths (Family B, m = 9):
%  - file SHA-256 of STATE/SOLUTION (+ manifests) equal to the plan pins and to the committed
%    A1_RUN_RECORDS_SHA256.json; g2_trajectory_record manifests verify; solution SHA inside STATE;
%  - key, mesh content SHA, A1 policy SHA and A1 source digest inside the records;
%  - STATE fields bitwise equal to SOLUTION.K; G and MTS recomputed; all 16 SIF criteria true;
%  - mesh: content SHA, A1 mesh validation, frozen polyline (g2_m5x6_configuration_check with the
%    diagonal pair, i.e. the independent activation verifier on the case's own mask);
%  - saved material: phase counts, active area and modulus ratio equal the policy case;
%  - EDI (0.4-2.6 mm, 6-point) recomputed from the saved displacement u: bitwise equal.
% No FEM, no write except outFile.
pol=C.a1.policy;plan=C.plan;g2=C.g2;
man=jsondecode(fileread(fullfile(C.repo,'matlab','g2','evidence','a1_campaign_20261122','campaign','A1_RUN_RECORDS_SHA256.json')));
mkey=@(s)matlab.lang.makeValidName(s);
rows={};
for k=1:4
 d=plan.diagonal(k);c=d.caseId;key=d.key;sd=fullfile(C.repo,'outputs','g2_a1_fixed_path_v1',plan.a1.runName,key);
 r=struct('caseId',c,'key',key);
 f={'STATE.mat','STATE.mat.manifest.json','SOLUTION.mat','SOLUTION.mat.manifest.json'};fh=struct();ok=true;
 for j=1:4
  h=lower(g2_sha256_file(fullfile(sd,f{j})));fh.(mkey(f{j}))=h;ok=ok&&strcmpi(h,man.(mkey([key '/' f{j}])));
 end
 r.fileSHA256=fh;r.filesEqualCommittedManifest=ok;
 r.filesEqualPlanPins=strcmpi(fh.STATE_mat,d.stateFileSHA256)&&strcmpi(fh.SOLUTION_mat,d.solutionFileSHA256);
 [St,stSHA,ok1]=g2_trajectory_record('read',fullfile(sd,'STATE.mat'));
 [So,soSHA,ok2]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));K=So.K;
 r.recordManifestsVerify=ok1&&ok2;r.solutionSHAInState=strcmpi(St.solutionSHA256,soSHA)&&strcmpi(stSHA,fh.STATE_mat);
 r.recordIdentity=strcmp(St.key,key)&&strcmp(So.key,key)&&strcmp(St.caseId,c)&&St.level==9&& ...
  strcmp(St.meshContentSHA256,pol.meshes.(key).contentSHA256)&&strcmp(St.meshContentSHA256,d.meshContentSHA256)&& ...
  strcmpi(St.policySHA256,plan.a1.policySHA256)&&strcmpi(St.sourceSHA256,plan.a1.sourceSHA256);
 r.stateEqualsSolution=isequal(St.KI,K.KI)&&isequal(St.KII,K.KII)&&isequal(St.J,K.J)&&isequal(St.EDI_all,K.EDI_all)&& ...
  isequal(St.KI_COD,K.KI_COD)&&isequal(St.KII_COD,K.KII_COD);
 Mt=g2_mts_direction(K.KI,K.KII);
 r.Grecomputed_rel=abs(St.G/((K.KI^2+K.KII^2)/K.Ep_matrix)-1);r.MTSrecomputed_absdiff_deg=abs(St.MTS_deg-Mt.theta_deg);
 cr=cell2mat(struct2cell(K.criteria));r.sifCriteriaTrue=sprintf('%d/%d',nnz(cr),numel(cr));
 r.sifGatesPassed=isequal(K.pass,true)&&isempty(K.failedCriteria)&&all(cr)&&numel(cr)==16;
 r.relativeResidual=K.relativeResidual;r.staticsMax=K.staticsMax;r.energyIdentityRel=K.energyIdentityRel;
 r.CODminusEDI_rel=max(abs([K.KI_COD-K.KI,K.KII_COD-K.KII]))/hypot(K.KI,K.KII);
 % mesh, polyline and own-mask activation (diagonal pair)
 ic=find(strcmp({pol.cases.id},c));
 cfg=struct('id',['DIAG-' c],'pathCase',c,'meshKey',key,'meshContentSHA256',d.meshContentSHA256, ...
  'materialCase',c,'mask',pol.cases(ic).mask,'ratio',pol.cases(ic).ratio);
 Q=g2_m5x6_configuration_check(C,cfg);
 r.meshGates=Q.meshGates;r.crackArclength_mm=Q.crackArclength_mm;r.tip_mm=Q.tip_mm;
 r.activationVerifierPass=Q.pass;r.ringElements=Q.ringElements;r.ringArea_mm2=Q.ringArea_mm2;
 on=Q.act.activeRings(:).';M=numel(Q.act.phaseForAssembly);
 r.savedMaterialMatchesPolicy=isequal(K.phaseCounts(:).',[M-Q.act.activeElements,Q.act.activeElements])&& ...
  ((isempty(on)&&K.activeArea_mm2==0&&K.phaseDminEig(2)==K.phaseDminEig(1))|| ...
   (~isempty(on)&&abs(K.activeArea_mm2-sum(Q.ringArea_mm2(on)))<=1e-12*sum(Q.ringArea_mm2(on))&& ...
    abs(K.phaseDminEig(2)/K.phaseDminEig(1)-pol.cases(ic).ratio)<=1e-12))&& ...
  isequal(logical(K.interfaceSideL2Gated(:).'),ismember(1:3,on));
 r.mask=Q.mask;r.ratio=Q.ratio;r.activeElements=Q.act.activeElements;
 % EDI from the saved displacement field
 D=Q.D;P=D.crackPolyline;matM=struct('E',Q.Em,'nu',Q.lp.bvp.nu,'plane','stress');
 E=g2_sif_interaction(D.X6,D.T6,K.u,matM,P(end,:),D.tipTangent(:).',.4,2.6,6);
 r.EDIfromSavedU_bitwise=isequal([E.KI,E.KII,E.J],K.EDI_all(1,:));
 r.KI=K.KI;r.KII=K.KII;r.J=K.J;r.G=St.G;r.MTS_deg=St.MTS_deg;r.KI_COD=K.KI_COD;r.KII_COD=K.KII_COD;
 r.compliance_mm_per_N=K.compliance_mm_per_N;r.T3=Q.T3;r.DOF=Q.DOF;
 r.pass=r.filesEqualCommittedManifest&&r.filesEqualPlanPins&&r.recordManifestsVerify&&r.solutionSHAInState&& ...
  r.recordIdentity&&r.stateEqualsSolution&&r.Grecomputed_rel<1e-12&&r.MTSrecomputed_absdiff_deg<1e-9&& ...
  r.sifGatesPassed&&r.activationVerifierPass&&r.savedMaterialMatchesPolicy&&r.EDIfromSavedU_bitwise;
 rows{end+1}=r; %#ok<AGROW>
 fprintf('M5X6_DIAGONAL %-8s pass=%d files=%d/%d edi=%d verifier=%d material=%d mesh=%s\n',key,r.pass, ...
  r.filesEqualCommittedManifest,r.filesEqualPlanPins,r.EDIfromSavedU_bitwise,r.activationVerifierPass,r.savedMaterialMatchesPolicy,r.meshGates);
end
rows=[rows{:}];
ra=reshape([rows.ringArea_mm2],3,[]).';
R=struct('schema','NewMetacomp.G2.M5X6.DiagonalAudit.v1','physicalSolves',0,'rows',rows, ...
 'ringAreaEqualAcrossMeshes_maxRelDiff',max(max(abs(ra-ra(1,:))./ra(1,:))), ...
 'ringElementsByMesh',reshape([rows.ringElements],3,[]).','allPass',all([rows.pass]));
if nargin>1&&~isempty(outFile)
 fid=fopen(outFile,'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
end
end
