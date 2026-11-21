function L = run_g2_m4b_analysis_batch(runDir)
%RUN_G2_M4B_ANALYSIS_BATCH  Attribution analysis of an accepted G2-M4.B campaign run (Issue #47).
%
%  L = run_g2_m4b_analysis_batch(runDir)
% Re-verifies the run (RUN.json token, CASE_LEDGER, record manifests, SHA256SUMS, campaign
% manifest), builds the 16 logical cases from the 15 physical records, and computes
% F_G, F_theta, f_i, I_ij, I_123, Shapley values and equal-area differences with the
% primary (paired) and conservative (uncorrelated) rules of policy v2
% (g2_m4b_attribution). Also: signed K (EDI, COD, 4x4, contours), J, G, compliance,
% CMOD, per-ring energy, reactions, active area, active-interface diagnostics, ring
% positions in the S2 tip frame, and a cross-check of the full-band cases against the
% accepted M2 ratio table. Self-tests of the algebra on synthetic data run first.
% Writes a NEW outputs/g2_m4b_ring_factorial_v1/analysis_run_<time>/ (never overwrites).
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pol=jsondecode(fileread(fullfile(here,'G2_M4B_POLICY_v2.json')));polSHA=lower(g2_sha256_file(fullfile(here,'G2_M4B_POLICY_v2.json')));
runDir=char(runDir);
out=fullfile(repo,'outputs','g2_m4b_ring_factorial_v1',['analysis_run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);
assert(~exist(out,'dir'),'G2M4B:AnalysisExists','Analysis folder exists.');mkdir(out);
diary(fullfile(out,'m4b_analysis_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
L=struct('schema','NewMetacomp.G2.M4B.AnalysisLedger.v1','issue',47,'status','RUNNING','started',datestr(now,31), ...
 'run',strrep(runDir,repo,'<repo>'),'policySHA256',polSHA,'physicalFractureGrowthProven',false);
L.matlabRelease=['R',version('-release')];
try
 % ---------------- self-tests of the algebra
 L.selfTests=self_tests();
 assert(L.selfTests.pass,'G2M4B:SelfTest','Attribution self-tests failed.');
 % ---------------- run verification
 RUN=jsondecode(fileread(fullfile(runDir,'RUN.json')));
 assert(strcmpi(RUN.policySHA256,polSHA),'G2M4B:AnalysisPolicy','Run was made under another policy.');
 Mf=jsondecode(fileread(fullfile(runDir,'CAMPAIGN_MANIFEST.json')));
 assert(Mf.allPass&&Mf.B2&&numel(Mf.logicalCases)==16,'G2M4B:AnalysisManifest','Campaign manifest not GO.');
 sums=splitlines(strtrim(fileread(fullfile(runDir,'SHA256SUMS.txt'))));nOK=0;
 for k=1:numel(sums)
  tk=regexp(strtrim(sums{k}),'^([0-9a-f]{64}) \*(.+)$','tokens','once');
  assert(~isempty(tk)&&strcmpi(g2_sha256_file(fullfile(runDir,tk{2})),tk{1}),'G2M4B:AnalysisSums','SHA256SUMS mismatch at %s.',sums{k});nOK=nOK+1;
 end
 L.runFilesVerified=nOK;
 ids=cellstr(pol.design.physicalCaseIds);C=struct();
 for k=1:numel(ids)
  [rec,h,ok]=g2_trajectory_record('read',fullfile(runDir,['CASE_',ids{k},'.mat']));
  assert(ok&&rec.K.pass&&rec.activation.pass&&strcmp(rec.caseId,ids{k}),'G2M4B:AnalysisRecord','Record %s invalid.',ids{k});
  C.(ids{k})=summ(rec,lower(h));clear rec
 end
 L.gitHeadOfRun=RUN.gitHead;L.token=RUN.token;
 % ---------------- tables and attribution
 masks=pol.design.masks;bitsOrder={masks.bits};
 tg=tangent_angle_deg(repo,pol);
 L.tangentGlobal_deg=tg;
 contrasts={'0.5','c0p5_';'2','c2p0_'};
 logical16=struct([]);
 for ci=1:2
  pid=cell(1,8);
  for m=1:8
   if strcmp(bitsOrder{m},'000'),pid{m}='none';else,pid{m}=[contrasts{ci,2},bitsOrder{m}];end
  end
  Gv=zeros(8,7);THv=zeros(8,7);
  for m=1:8,Gv(m,:)=C.(pid{m}).Gvar;THv(m,:)=C.(pid{m}).THvar;end
  At=g2_m4b_attribution(Gv,THv);
  At.contrast=contrasts{ci,1};At.physicalCases=pid;At.G_variants=Gv;At.theta_variants=THv;
  At.readings=readings(At);
  L.attribution(ci)=At;
  for m=1:8
   s=C.(pid{m});
   row=struct('contrast',contrasts{ci,1},'mask',masks(m).name,'bits',bitsOrder{m},'physicalCase',pid{m},'recordSHA256',s.sha, ...
    'nActive',nnz(bitsOrder{m}=='1'),'activeArea_mm2',s.activeArea_mm2, ...
    'KI_perkN',s.KI_perkN,'KII_perkN',s.KII_perkN,'KI_COD_perkN',s.KI_COD_perkN,'KII_COD_perkN',s.KII_COD_perkN, ...
    'KI_raw',s.KI_raw,'KII_raw',s.KII_raw,'J_1N_N_per_mm',s.J,'G_1N_N_per_mm',s.Gvar(1),'G_1N_J_per_m2',1000*s.Gvar(1),'G_COD_1N_N_per_mm',s.Gvar(7), ...
    'theta_MTS_deg',s.THvar(1),'theta_MTS_COD_deg',s.THvar(7),'theta_MTS_global_deg',tg+s.THvar(1),'mixity_deg',atand(s.KII_raw/s.KI_raw), ...
    'F_G',Gv(m,1)/Gv(1,1)-1,'F_theta_deg',THv(m,1)-THv(1,1), ...
    'compliance_mm_per_N',s.compliance,'CMOD_mm',s.CMOD,'strainEnergy_N_mm',s.U_total,'ringStrainEnergy_N_mm',s.U_ring, ...
    'reactions',s.reactions,'activeInterfaceBalanceRel',s.bal,'activeAnnulusResultantRel',s.res,'energyIdentityRel',s.eid, ...
    'relativeResidual',s.resid,'MTSrootCheck_rad',s.rootCheck);
   if isempty(logical16),logical16=row;else,logical16(end+1)=row;end %#ok<AGROW>
  end
 end
 L.logicalCases=logical16;
 % ---------------- cross-check: full band vs accepted M2 ratio table (S2)
 Lm2=jsondecode(fileread(fullfile(repo,pol.reference.acceptedBaselines.run,'LEDGER.json')));T2=Lm2.results.S2.table;
 xs=struct();
 for k=1:2
  id={'Msoft','Mstiff'};t=T2(strcmp({T2.id},id{k}));At=L.attribution(k);iF=strcmp(At.termNames,'F_123');
  xs.(id{k})=struct('R_EDI_M2',t.R_EDI,'R_EDI_M4B',1+At.G.Q(iF),'absDiff',abs(t.R_EDI-(1+At.G.Q(iF))), ...
   'U_R_M2',t.U_R,'U_primary_M4B',At.G.U_primary(iF),'U_cons_M2',t.U_R_conservative,'U_cons_M4B',At.G.U_conservative(iF), ...
   'dMTS_M2',t.dMTS_deg,'dTheta_M4B',At.theta.Q(iF),'dThetaDiff',abs(t.dMTS_deg-At.theta.Q(iF)));
 end
 xs.pass=all(structfun(@(s)s.absDiff<=1e-12&&abs(s.U_R_M2-s.U_primary_M4B)<=1e-12&&abs(s.U_cons_M2-s.U_cons_M4B)<=1e-12&&s.dThetaDiff<=1e-10,xs));
 L.crossCheckM2=xs;
 assert(xs.pass,'G2M4B:CrossCheck','Full-band cases do not reproduce the accepted M2 ratio table.');
 % ---------------- ring positions in the S2 tip frame
 D=load(fullfile(repo,pol.reference.mesh),'crackPolyline','tipTangent');tip=D.crackPolyline(end,:);t=D.tipTangent(:).';n=[-t(2),t(1)];
 cen=reshape(pol.rings.centres_mm,[],2);if ~isequal(cen(:,1),[152.4;152.4;152.4]),cen=reshape(pol.rings.centres_mm.',[],2);end
 rn=C.c0p5_111.perRingMinDist;
 for h=1:3
  dv=cen(h,:)-tip;
  L.ringPositions(h)=struct('ring',h,'centre_mm',cen(h,:),'x_tangent_mm',dv*t.','y_normal_mm',dv*n.','distance_mm',norm(dv), ...
   'bearing_deg',atan2d(dv*n.',dv*t.'),'nearestRingNode_mm',rn(h),'area_mm2',C.c0p5_111.ringArea(h));
 end
 L.tip_mm=tip;L.tipTangent=t;
 write_csv(out,L);
 L.status='GO';
catch ME
 fprintf(2,'HOLD %s: %s\n',ME.identifier,ME.message);
 L.status='HOLD';L.hold=struct('identifier',ME.identifier,'message',strrep(ME.message,repo,'<repo>'));
end
L.finished=datestr(now,31);
fid=fopen(fullfile(out,'LEDGER.json'),'w');fwrite(fid,jsonencode(L,'PrettyPrint',true),'char');fclose(fid);
diary('off');
fl=dir(out);fl=fl(~[fl.isdir]);fid=fopen(fullfile(out,'SHA256SUMS.txt'),'w');
for k=1:numel(fl),if ~strcmp(fl(k).name,'SHA256SUMS.txt'),fprintf(fid,'%s *%s\n',lower(g2_sha256_file(fullfile(out,fl(k).name))),fl(k).name);end,end
fclose(fid);
fprintf('G2_M4B_ANALYSIS_STATUS=%s folder %s\n',L.status,strrep(out,repo,'<repo>'));
end

% =====================================================================
function s=summ(rec,h)
K=rec.K;s1k=sqrt(1000);E=K.Ep_matrix;g=@(k)(k(:,1).^2+k(:,2).^2)/E;
mts=@(a,b)g2_mts_direction(a*s1k,b*s1k).theta_deg;
Kv=[K.EDI_all(:,1:2);K.EDI4x4;[K.KI_COD,K.KII_COD]];   % 1 primary, 2-5 other annuli, 6 4x4, 7 COD
s=struct('sha',h,'Gvar',g(Kv).','THvar',arrayfun(@(i)mts(Kv(i,1),Kv(i,2)),1:7), ...
 'KI_raw',K.KI,'KII_raw',K.KII,'KI_perkN',K.KI_MPa_sqrt_m_per_kN,'KII_perkN',K.KII_MPa_sqrt_m_per_kN, ...
 'KI_COD_perkN',K.KI_COD*s1k,'KII_COD_perkN',K.KII_COD*s1k,'J',K.J,'compliance',K.compliance_mm_per_N,'CMOD',K.CMOD_mm, ...
 'U_total',K.strainEnergy_per_thickness*12.7,'U_ring',(K.ringStrainEnergy_per_thickness*12.7).','reactions',K.reactions.', ...
 'bal',K.activeInterfaceBalanceRel,'res',K.activeAnnulusResultantRel,'eid',K.energyIdentityRel,'resid',K.relativeResidual, ...
 'activeArea_mm2',K.activeArea_mm2,'ringArea',K.ringArea_mm2(2:4).','perRingMinDist',rec.activation.values.perRingMinDistanceToTip_mm);
th=s.THvar(1)*pi/180;f=@(x)K.KI*sin(x)+K.KII*(3*cos(x)-1);
s.rootCheck=abs(fzero(f,[-pi/2,pi/2],optimset('TolX',1e-15))-th);
end

function r=readings(At)
nm=At.termNames;ix=@(n)find(strcmp(nm,n));r=struct();
for obs={'G','theta'}
 q=At.(obs{1});Iset=[ix('I_12'),ix('I_13'),ix('I_23'),ix('I_123')];
 if any(q.resolvedPrimary(Iset)),add='NONADDITIVE_PRIMARY';else,add='ADDITIVE_WITHIN_PRIMARY';end
 if any(q.resolvedConservative(Iset)),addC='NONADDITIVE_CONSERVATIVE';else,addC='ADDITIVE_WITHIN_CONSERVATIVE';end
 f=q.Q([ix('f_1'),ix('f_2'),ix('f_3')]);d=[ix('d_1_2'),ix('d_1_3'),ix('d_2_3')];
 [~,ord]=sort(abs(f),'descend');
 r.(obs{1})=struct('additivityPrimary',add,'additivityConservative',addC, ...
  'resolvedInteractionsPrimary',{nm(Iset(q.resolvedPrimary(Iset)))},'orderByAbsSingleRingEffect',ord.', ...
  'singleRingDifferencesResolvedPrimary',q.resolvedPrimary(d).','singleRingDifferencesResolvedConservative',q.resolvedConservative(d).', ...
  'pairDifferencesResolvedPrimary',q.resolvedPrimary([ix('D_12_13'),ix('D_12_23'),ix('D_13_23')]).');
end
H1=any(r.G.singleRingDifferencesResolvedPrimary);
r.H1_unequalRingInfluence_G=ternary(H1,'SUPPORTED_PRIMARY','NOT_RESOLVED');
r.H1_unequalRingInfluence_theta=ternary(any(r.theta.singleRingDifferencesResolvedPrimary),'SUPPORTED_PRIMARY','NOT_RESOLVED');
if all(r.G.singleRingDifferencesResolvedPrimary)&&all(r.theta.singleRingDifferencesResolvedPrimary)
 r.H2_orderDiffers=ternary(isequal(r.G.orderByAbsSingleRingEffect,r.theta.orderByAbsSingleRingEffect),'REFUTED_SAME_ORDER','SUPPORTED_DIFFERENT_ORDER');
else
 r.H2_orderDiffers='NOT_RESOLVED';
end
r.H3_interactions_G=r.G.additivityPrimary;r.H3_interactions_theta=r.theta.additivityPrimary;
end

function T=self_tests()
% (1) exactly additive synthetic data: all I = 0, reconstruction exact
g0=1e-8;fi=[.01,-.004,.002];Gv=zeros(8,7);sets={[],1,2,3,[1 2],[1 3],[2 3],[1 2 3]};
for m=1:8,Gv(m,:)=g0*(1+sum(fi(sets{m})))*(1+1e-4*(0:6));end
Gv(:,1)=g0*(1+cellfun(@(s)sum(fi(s)),sets)).';
TH=repmat(cellfun(@(s)sum([.3 .1 -.05].*ismember(1:3,s)),sets).',1,7);
A=g2_m4b_attribution(Gv,TH);nm=A.termNames;ii=@(n)strcmp(nm,n);
t1=max(abs(A.G.Q(ii('I_12')|ii('I_13')|ii('I_23')|ii('I_123'))))<1e-15&&max(abs(A.theta.Q(ii('I_12')|ii('I_13')|ii('I_23')|ii('I_123'))))<1e-14;
t2=abs(A.G.Q(ii('f_1'))-.01)<1e-15&&abs(A.G.reconstructionResidual)<1e-15&&abs(A.G.shapleySumResidual)<1e-15;
% (2) random data: identities hold
rng(47);Gr=1e-8*(1+.05*rand(8,7));Tr=rand(8,7);B=g2_m4b_attribution(Gr,Tr);
t3=abs(B.G.reconstructionResidual)<1e-14&&abs(B.theta.reconstructionResidual)<1e-13&&abs(B.G.shapleySumResidual)<1e-14&&abs(B.theta.shapleySumResidual)<1e-13;
% (3) conservative rule reduces to R(d_S + d_none) for F_S
d=abs(Gr(:,1)-Gr(:,7))./Gr(:,1);R=Gr(2,1)/Gr(1,1);t4=abs(B.G.U_conservative(1)-R*(d(2)+d(1)))<1e-15;
% (4) primary rule reduces to the inherited U_R for F_S
Rv=Gr(2,:)./Gr(1,:);t5=abs(B.G.U_primary(1)-max(abs(Rv(2:end)-Rv(1))))<1e-15;
T=struct('additiveZeroInteractions',t1,'additiveRecovery',t2,'randomIdentities',t3,'conservativeEqualsInherited',t4,'primaryEqualsInherited',t5);
T.pass=t1&&t2&&t3&&t4&&t5;
fprintf('M4B_SELFTESTS %s -> pass=%d\n',jsonencode(T),T.pass);
end

function deg=tangent_angle_deg(repo,pol)
% global angle of the saved S2 terminal unit tangent t = (t_x, t_y)
D=load(fullfile(repo,pol.reference.mesh),'tipTangent');t=D.tipTangent(:).';
deg=atan2d(t(2),t(1));
end

function write_csv(out,L)
fid=fopen(fullfile(out,'cases_16_logical.csv'),'w');
fprintf(fid,'contrast,mask,bits,physical_case,n_active,active_area_mm2,KI_perkN,KII_perkN,KI_COD_perkN,KII_COD_perkN,J_1N_N_per_mm,G_1N_J_per_m2,theta_MTS_deg,theta_MTS_COD_deg,theta_global_deg,F_G,F_theta_deg,compliance_mm_per_N,CMOD_mm,U_total_N_mm,U_ring1_N_mm,U_ring2_N_mm,U_ring3_N_mm,record_sha256\n');
for r=L.logicalCases
 fprintf(fid,'%s,%s,%s,%s,%d,%.12g,%.12g,%+.12g,%.12g,%+.12g,%.12g,%.12g,%+.12g,%+.12g,%+.12g,%+.12g,%+.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%s\n', ...
  r.contrast,r.mask,r.bits,r.physicalCase,r.nActive,r.activeArea_mm2,r.KI_perkN,r.KII_perkN,r.KI_COD_perkN,r.KII_COD_perkN,r.J_1N_N_per_mm, ...
  r.G_1N_J_per_m2,r.theta_MTS_deg,r.theta_MTS_COD_deg,r.theta_MTS_global_deg,r.F_G,r.F_theta_deg,r.compliance_mm_per_N,r.CMOD_mm,r.strainEnergy_N_mm, ...
  r.ringStrainEnergy_N_mm(2),r.ringStrainEnergy_N_mm(3),r.ringStrainEnergy_N_mm(4),r.recordSHA256);
end
fclose(fid);
fid=fopen(fullfile(out,'decomposition.csv'),'w');
fprintf(fid,'contrast,observable,term,value,U_primary,resolved_primary,U_conservative,resolved_conservative,class,value_COD\n');
for At=L.attribution
 for obs={'G','theta'}
  q=At.(obs{1});
  for k=1:numel(At.termNames)
   fprintf(fid,'%s,%s,%s,%+.12g,%.6g,%d,%.6g,%d,%s,%+.12g\n',At.contrast,ternary(strcmp(obs{1},'G'),'F_G','F_theta_deg'),At.termNames{k}, ...
    q.Q(k),q.U_primary(k),q.resolvedPrimary(k),q.U_conservative(k),q.resolvedConservative(k),q.class{k},q.Q_COD(k));
  end
 end
end
fclose(fid);
fid=fopen(fullfile(out,'ring_positions.csv'),'w');
fprintf(fid,'ring,centre_x_mm,centre_y_mm,x_tangent_mm,y_normal_mm,distance_mm,bearing_deg,nearest_ring_node_mm,area_mm2\n');
for p=L.ringPositions,fprintf(fid,'%d,%.4f,%.4f,%.6f,%.6f,%.6f,%.6f,%.6f,%.12g\n',p.ring,p.centre_mm,p.x_tangent_mm,p.y_normal_mm,p.distance_mm,p.bearing_deg,p.nearestRingNode_mm,p.area_mm2);end
fclose(fid);
end

function r=ternary(c,a,b),if c,r=a;else,r=b;end,end
