function L = run_g2_m3_analysis_batch()
%RUN_G2_M3_ANALYSIS_BATCH  Issue #39 stage D: direct / path / total decomposition + robustness.
%
%  L = run_g2_m3_analysis_batch()
% 1. Re-verifies both material chains read-only (g2_m3_trajectory_run dry: forecasts, hashes,
%    mesh content, 34/34 re-audit, phase re-map/verifier; no FEM, no writes in the chains).
% 2. Reads PR #38 records (H1 and M on the frozen homogeneous path, S2alt) after hash checks.
% 3. At s = 25.4, 29.4, 33.4 mm: R_direct, R_path, R_total with both preregistered uncertainty
%    verdicts (U_mesh added for cross-mesh ratios), identity R_total = R_direct*R_path, signed
%    K, G, mixity, local and global MTS directions, compliance, CMOD, band/q clearances.
% 4. Path separation (tip, signed lateral, full polyline at equal arclength) with U_sep.
% 5. Preregistered alternative mesh at each material's M2 (GuideHface 1.0, Hmax 5): audit,
%    phase stage, two-phase solve, R_path_alt against the PR #38 S2alt material record.
% Writes a NEW outputs/g2_material_trajectories_v1/analysis_run_<time>/ (LEDGER.json, CSV,
% ALT records, SHA256SUMS.txt). No crack advance beyond the chains, no onset claims.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pol=jsondecode(fileread(fullfile(here,'G2_M3_TRAJECTORY_POLICY_v1.json')));
polM=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
polT=jsondecode(fileread(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')));
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
p0=fullfile(repo,'outputs','g2_p010_isolated','run_20261118_163657_790','P010_ISOLATED_REGULAR_ONLY.mat');
root=fullfile(repo,'outputs','g2_material_trajectories_v1');
folder=fullfile(root,['analysis_run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'m3_analysis_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
L=struct('schema','NewMetacomp.G2.M3AnalysisLedger.v1','issue',39,'started',datestr(now,31),'status','RUNNING','physicalFractureGrowthProven',false);
L.policySHA256=g2_sha256_file(fullfile(here,'G2_M3_TRAJECTORY_POLICY_v1.json'));
try
 [s1,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));[s2,dt]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all -- matlab/g2',repo));
 assert(s1==0&&s2==0&&isempty(strtrim(dt)),'G2M3A:DirtySource','Uncommitted sources:\n%s',dt);L.gitHead=strtrim(h);
 b=pol.base;mats=pol.materials;if iscell(mats),mats=[mats{:}];end
 rec=@(key)m2rec(repo,b,key);
 H={rec('S0_H1'),rec('S1_H1'),rec('S2_H1')};H2alt=rec('S2alt_H1');
 Umesh=abs(G(H2alt)/G(H{3})-1);L.U_mesh=Umesh;
 mH1=load(fullfile(repo,'outputs','g2_wp3_state','run_20261118_185808_963','step1_a','KINKED_GEOMETRY_ONLY_candidate.mat'),'crackPolyline','tipTangent');
 mH2=load(fullfile(repo,'outputs','g2_trajectory_chain_v1_attempt2','STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat'),'crackPolyline','tipTangent');
 PH={reshape(pol.start.polyline_mm,[],2),mH1.crackPolyline,mH2.crackPolyline};tH={[0 1],mH1.tipTangent(:).',mH2.tipTangent(:).'};
 s=[25.4 29.4 33.4];res=struct();
 for i=1:numel(mats)
  m=mats(i);
  Rchk=g2_m3_trajectory_run('Material',m.id);   % dry: full read-only chain verification
  assert(Rchk.pass&&strcmp(Rchk.stage,'STEP_CAP')&&Rchk.lastStateIndex==2,'G2M3A:Chain','%s chain not verified through 2 (%s).',m.id,Rchk.stage);
  chain=fullfile(root,['chain_',m.id,'_v1']);
  MH={rec(['S0_',m.m2Case]),rec(['S1_',m.m2Case]),rec(['S2_',m.m2Case])};MH2alt=rec(['S2alt_',m.m2Case]);
  MM=cell(1,3);PM=cell(1,3);tM=cell(1,3);geomM=cell(1,3);
  MM{1}=MH{1};PM{1}=PH{1};tM{1}=[0 1];
  for k=1:2
   sd=fullfile(chain,sprintf('STEP_%03d',k));
   [St,~,ok1]=g2_trajectory_record('read',fullfile(sd,'STATE.mat'));[Sol,~,ok2]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));
   [Rv,~,ok3]=g2_trajectory_record('read',fullfile(sd,'REVIEW.mat'));assert(ok1&&ok2&&ok3,'G2M3A:Records','%s step %d records.',m.id,k);
   MM{k+1}=Sol;PM{k+1}=St.crackPolyline_mm;tM{k+1}=St.t(:).';geomM{k+1}=Rv.geometry;
  end
  rows=struct([]);
  for k=1:3
   cross=k>1;
   Rd=ratio(MH{k},H{k},false,pol);          % direct (same mesh, PR #38)
   Rp=ratio(MM{k},MH{k},cross,pol,Umesh);    % path
   Rt=ratio(MM{k},H{k},cross,pol,Umesh);     % total
   if k==1,assert(Rp.R==1,'G2M3A:S0Path','R_path at S0 must be exactly 1.');end
   idErr=abs(Rt.R-Rd.R*Rp.R)/Rt.R;assert(idErr<=pol.decomposition.identityTolerance,'G2M3A:Identity','R_total identity failed (%.3g).',idErr);
   thH=thetas(H{k});thMH=thetas(MH{k});thM=thetas(MM{k});
   r=struct('s_mm',s(k),'state',sprintf('%d',k-1),'KI_H',H{k}.KI_perkN,'KII_H',H{k}.KII_perkN,'KI_MH',MH{k}.KI_perkN,'KII_MH',MH{k}.KII_perkN, ...
    'KI_MM',MM{k}.KI_perkN,'KII_MM',MM{k}.KII_perkN,'KI_COD_MM',MM{k}.KI_COD_perkN,'KII_COD_MM',MM{k}.KII_COD_perkN, ...
    'G_H',G(H{k}),'G_MH',G(MH{k}),'G_MM',G(MM{k}),'J_MM',MM{k}.J, ...
    'R_direct',Rd,'R_path',Rp,'R_total',Rt,'identityRelErr',idErr, ...
    'mixity_H_deg',atand(H{k}.KII_raw/H{k}.KI_raw),'mixity_MH_deg',atand(MH{k}.KII_raw/MH{k}.KI_raw),'mixity_MM_deg',atand(MM{k}.KII_raw/MM{k}.KI_raw), ...
    'theta_H_deg',thH.edi,'theta_MH_deg',thMH.edi,'theta_MM_deg',thM.edi, ...
    'tangentGlobal_H_deg',atan2d(tH{k}(2),tH{k}(1)),'tangentGlobal_MM_deg',atan2d(tM{k}(2),tM{k}(1)), ...
    'nextGlobal_H_deg',atan2d(tH{k}(2),tH{k}(1))+thH.edi,'nextGlobal_MM_deg',atan2d(tM{k}(2),tM{k}(1))+thM.edi, ...
    'compliance_H',H{k}.compliance_mm_per_N,'compliance_MH',MH{k}.compliance_mm_per_N,'compliance_MM',MM{k}.compliance_mm_per_N, ...
    'CMOD_H',H{k}.CMOD_mm,'CMOD_MH',MH{k}.CMOD_mm,'CMOD_MM',MM{k}.CMOD_mm,'tip_H',PH{k}(end,:),'tip_MM',PM{k}(end,:));
   if k>1,r.geometry=geomM{k};else,r.geometry=struct();end
   % steering difference of own-path vs homogeneous at the matched parent, with estimator uncertainty
   [r.dTheta_own_deg,r.U_dTheta_own_deg,r.dTheta_cons_deg]=dtheta(thM,thH);
   fprintf(['M3 %-5s s=%.1f: R_direct %.6f (%s) R_path %.6f U %.2g (%s/cons %s) R_total %.6f (%s/cons %s) id %.1e | ', ...
    'theta H %.4f MH %.4f MM %.4f\n'],m.id,s(k),Rd.R,yn(Rd.resolved),Rp.R,Rp.U,yn(Rp.resolved),yn(Rp.resolvedCons),Rt.R,yn(Rt.resolved),yn(Rt.resolvedCons),idErr,thH.edi,thMH.edi,thM.edi);
   if isempty(rows),rows=r;else,rows(end+1)=r;end %#ok<AGROW>
  end
  % path separation and resolution
  sep=struct([]);
  for k=2:3
   d=PM{k}(end,:)-PH{k}(end,:);nH=[-tH{k}(2),tH{k}(1)];
   if k==2,Usep=4*deg2rad(rows(1).U_dTheta_own_deg);Ucons=4*deg2rad(rows(1).dTheta_cons_deg);
   else,Usep=8*deg2rad(rows(1).U_dTheta_own_deg)+4*deg2rad(rows(2).U_dTheta_own_deg);Ucons=8*deg2rad(rows(1).dTheta_cons_deg)+4*deg2rad(rows(2).dTheta_cons_deg);end
   e=struct('s_mm',s(k),'tipSeparation_mm',norm(d),'lateral_mm',d*nH.','maxPolylineSeparation_mm',polysep(PM{k},PH{k}),'U_sep_mm',Usep,'U_sep_cons_mm',Ucons, ...
    'resolved',norm(d)>2*Usep,'resolvedCons',norm(d)>2*Ucons);
   if isempty(sep),sep=e;else,sep(end+1)=e;end %#ok<AGROW>
   fprintf('M3 %-5s s=%.1f: tip separation %.6f mm (lateral %+.6f) maxPoly %.6f U_sep %.2g (resolved %d) U_cons %.2g (resolved %d)\n',m.id,s(k),e.tipSeparation_mm,e.lateral_mm,e.maxPolylineSeparation_mm,Usep,e.resolved,Ucons,e.resolvedCons);
  end
  % preregistered alternative mesh at M2
  alt=alt_mesh(PM{3},tM{3},m,pol,polM,polT,json,p0,folder);
  dStd=rows(3).R_path.R-1;Ralt=G(alt.S)/G(MH2alt);dAlt=Ralt-1;
  if sign(dAlt)~=sign(dStd),cls='NOT_ROBUST';elseif abs(dAlt-dStd)<=.25*abs(dStd)+2*Umesh,cls='ROBUST';else,cls='SENSITIVE';end
  alt.R_path_alt=Ralt;alt.dR_path_std=dStd;alt.dR_path_alt=dAlt;alt.classification=cls;
  alt.thetaM2_alt_deg=thetas(alt.S).edi;alt.thetaM2_std_deg=rows(3).theta_MM_deg;
  fprintf('M3 %-5s ALT M2: T3 %d audit %s chords %s; R_path std %.6f alt %.6f -> %s; theta std %.5f alt %.5f\n',m.id,alt.T3,alt.audit, ...
   mat2str(alt.geometry.chordsPerCircle),rows(3).R_path.R,Ralt,cls,alt.thetaM2_std_deg,alt.thetaM2_alt_deg);
  alt=rmfield(alt,'S');
  res.(m.id)=struct('rows',rows,'separation',sep,'alt',alt,'polylines',{PM},'chainRootSHA256',Rchk.rootSHA256);
 end
 d=res.soft;e=res.stiff;
 L.softVsStiff=struct('tipSeparation_mm',[norm(d.polylines{2}(end,:)-e.polylines{2}(end,:)),norm(d.polylines{3}(end,:)-e.polylines{3}(end,:))]);
 L.results=res;L.homogeneousPolylines=PH;L.status='GO';
catch ME
 fprintf(2,'HOLD %s: %s\n',ME.identifier,ME.message);L.status='HOLD';L.hold=struct('identifier',ME.identifier,'message',ME.message);
end
L.finished=datestr(now,31);
fid=fopen(fullfile(folder,'LEDGER.json'),'w');fwrite(fid,jsonencode(sanitize(L,repo),'PrettyPrint',true),'char');fclose(fid);
if strcmp(L.status,'GO'),write_csv(folder,L);end
diary('off');
fl=dir(folder);fl=fl(~[fl.isdir]);fid=fopen(fullfile(folder,'SHA256SUMS.txt'),'w');
for k=1:numel(fl),if ~strcmp(fl(k).name,'SHA256SUMS.txt'),fprintf(fid,'%s *%s\n',lower(g2_sha256_file(fullfile(folder,fl(k).name))),fl(k).name);end,end
fclose(fid);fprintf('G2_M3_ANALYSIS_STATUS=%s\n',L.status);
end

% =====================================================================
function r=m2rec(repo,b,key)
f=fullfile(repo,b.m2Run,['CASE_',key,'.mat']);
assert(strcmpi(g2_sha256_file(f),b.m2CaseSHA256.(key)),'G2M3A:M2Hash','PR #38 record %s hash.',key);
[r,~,ok]=g2_trajectory_record('read',f);assert(ok,'G2M3A:M2Record','PR #38 record %s.',key);
end

function g=G(r),g=(r.KI_raw^2+r.KII_raw^2)/r.Ep_matrix;end

function Q=ratio(A,B,cross,pol,Umesh)
if nargin<5,Umesh=0;end
E=A.Ep_matrix;g=@(k)(k(:,1).^2+k(:,2).^2)/E;
gA=g(A.EDI_all(:,1:2));gB=g(B.EDI_all(:,1:2));Rc=gA./gB;R=Rc(1);
R4=g(A.EDI4x4)/g(B.EDI4x4);Rcod=g([A.KI_COD_raw,A.KII_COD_raw])/g([B.KI_COD_raw,B.KII_COD_raw]);
U=max([max(abs(Rc-R)),abs(R4-R),abs(Rcod-R)]);if cross,U=max(U,Umesh);end
dA=abs(gA(1)-g([A.KI_COD_raw,A.KII_COD_raw]))/gA(1);dB=abs(gB(1)-g([B.KI_COD_raw,B.KII_COD_raw]))/gB(1);Uc=R*(dA+dB);
cf=2;
Q=struct('R',R,'R_COD',Rcod,'R_4x4',R4,'R_J',A.J/B.J,'R_contours',Rc.','U',U,'U_cons',Uc,'crossMesh',cross, ...
 'resolved',R~=1&&abs(R-1)>cf*U&&sign(Rcod-1)==sign(R-1),'resolvedCons',R~=1&&abs(R-1)>Uc&&sign(Rcod-1)==sign(R-1));
end

function T=thetas(r)
s=sqrt(1000);f=@(KI,KII)g2_mts_direction(KI,KII).theta_deg;
T=struct('edi',f(r.KI_perkN,r.KII_perkN),'cod',f(r.KI_COD_raw*s,r.KII_COD_raw*s),'q4',f(r.EDI4x4(1)*s,r.EDI4x4(2)*s), ...
 'contours',arrayfun(@(c)f(r.EDI_all(c,1)*s,r.EDI_all(c,2)*s),1:5));
end

function [d,U,Uc]=dtheta(A,B)
d=A.edi-B.edi;
U=max([abs((A.cod-B.cod)-d),abs((A.q4-B.q4)-d),max(abs((A.contours-B.contours)-d))]);
Uc=abs(A.edi-A.cod)+abs(B.edi-B.cod);
end

function m=polysep(P,Q)
% maximum distance between two polylines sampled at equal arclength
sP=[0;cumsum(vecnorm(diff(P),2,2))];sQ=[0;cumsum(vecnorm(diff(Q),2,2))];
ss=linspace(0,min(sP(end),sQ(end)),3341).';
pp=[interp1(sP,P(:,1),ss),interp1(sP,P(:,2),ss)];qq=[interp1(sQ,Q(:,1),ss),interp1(sQ,Q(:,2),ss)];
m=max(vecnorm(pp-qq,2,2));
end

function alt=alt_mesh(P,t,m,pol,polM,polT,json,p0,folder)
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5,'GuideHface_mm',1.0,'Hmax_mm',5};
B=g2_kinked_join(P,'ExteriorOptions',opts,'ExpectedVertices',size(P,1),'MaxT3Elements',pol.mesh.T3max,'ExpectedTangent',t);
assert(B.pass,'G2M3A:AltJoin','%s alt join: %s %s',m.id,B.stage,B.message);
mf=fullfile(folder,sprintf('ALT_M2_%s_KINKED_GEOMETRY_ONLY_candidate.mat',m.id));
X3=B.X3;T3=B.T3;X6=B.X6;T6=B.T6;upperBankT6=B.upperBankT6;lowerBankT6=B.lowerBankT6; %#ok<NASGU>
physicalTipNode=B.physicalTipNode;nodalQ=B.nodalQ;qActiveT6Rows=B.qActiveT6Rows;elementRows=B.elementRows; %#ok<NASGU>
collarOuterIDs=B.collarOuterIDs;extraVertexXY=B.extraVertexXY;extraVertexNodes=B.extraVertexNodes;crackPolyline=P; %#ok<NASGU>
tipTangent=t;tipNormal=[-t(2),t(1)];kinkNodeIDs=B.kinkNodeIDs;geometryOnly=true;approvedForLEFM=false; %#ok<NASGU>
plateXRange=B.plateXRange;includeHoles=true;mirrorControl=false; %#ok<NASGU>
save(mf,'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','qActiveT6Rows','elementRows','collarOuterIDs', ...
 'extraVertexXY','extraVertexNodes','crackPolyline','tipTangent','tipNormal','kinkNodeIDs','geometryOnly','approvedForLEFM','plateXRange','includeHoles','mirrorControl','-v7.3');
D=load(mf);C=g2_kinked_mesh_auditor(D,json,p0,size(P,1));
assert(C.pass&&C.gatesPassed==34&&C.summary.T3elements<=pol.mesh.T3max&&C.summary.minAngle_deg>=20&&C.summary.maxNeighborRatio<=1.8,'G2M3A:AltAudit','%s alt audit.',m.id);
[Dm,Ad]=g2_m2_state_adapter(D,'M2alt',P);assert(Ad.pass,'G2M3A:AltAdapter','%s alt adapter.',m.id);
[PMp,V,NC,geom]=g2_material_phase_stage(Dm,polM,P);assert(PMp.pass&&V.pass&&NC.pass,'G2M3A:AltPhase','%s alt phase.',m.id);
Em=pol.model.E_matrix_MPa;mk=@(E)struct('E',E,'nu',pol.model.nu_matrix,'plane',pol.model.plane);
K=g2_material_sif_on_mesh(Dm,PMp.phase,[mk(Em),mk(m.ratio*Em)],polT,PMp);
S=g2_material_case_summary(m.id,K,[],K.loadNode,polT,m.ratio);
R=S;R.schema='NewMetacomp.G2.M3.AltCase.v1';R.u=K.u;R.meshSHA256=g2_sha256_file(mf);
h=g2_trajectory_record('write',fullfile(folder,sprintf('ALT_M2_%s_CASE.mat',m.id)),R);
assert(K.pass,'G2M3A:AltSIF','%s alt SIF gates: %s',m.id,strjoin(K.failedCriteria,', '));
alt=struct('T3',C.summary.T3elements,'audit',sprintf('%d/%d',C.gatesPassed,C.gatesTotal),'meshSHA256',R.meshSHA256,'caseSHA256',h, ...
 'geometry',geom,'KI_perkN',S.KI_perkN,'KII_perkN',S.KII_perkN,'G',G(S),'S',S);
end

function s=yn(b),if b,s='yes';else,s='no';end,end

function write_csv(folder,L)
fid=fopen(fullfile(folder,'m3_decomposition.csv'),'w');
fprintf(fid,['material,s_mm,KI_H,KII_H,KI_M_on_GammaH,KII_M_on_GammaH,KI_M_own,KII_M_own,G_H_N_per_mm,G_M_GammaH,G_M_own,R_direct,R_direct_U,R_direct_resolved,', ...
 'R_direct_resolvedCons,R_path,R_path_U,R_path_resolved,R_path_resolvedCons,R_total,R_total_U,R_total_resolved,R_total_resolvedCons,identityRelErr,', ...
 'theta_H_deg,theta_M_GammaH_deg,theta_M_own_deg,dTheta_own_deg,U_dTheta_own_deg,tipX_own,tipY_own,tipX_H,tipY_H,compliance_ratio_own,CMOD_ratio_own\n']);
for m={'soft','stiff'}
 rows=L.results.(m{1}).rows;
 for k=1:numel(rows)
  r=rows(k);
  fprintf(fid,'%s,%.1f,%.9f,%+.9f,%.9f,%+.9f,%.9f,%+.9f,%.6e,%.6e,%.6e,%.9f,%.2e,%d,%d,%.9f,%.2e,%d,%d,%.9f,%.2e,%d,%d,%.1e,%.6f,%.6f,%.6f,%+.6f,%.2e,%.10f,%.10f,%.10f,%.10f,%.9f,%.9f\n', ...
   m{1},r.s_mm,r.KI_H,r.KII_H,r.KI_MH,r.KII_MH,r.KI_MM,r.KII_MM,r.G_H,r.G_MH,r.G_MM,r.R_direct.R,r.R_direct.U,r.R_direct.resolved,r.R_direct.resolvedCons, ...
   r.R_path.R,r.R_path.U,r.R_path.resolved,r.R_path.resolvedCons,r.R_total.R,r.R_total.U,r.R_total.resolved,r.R_total.resolvedCons,r.identityRelErr, ...
   r.theta_H_deg,r.theta_MH_deg,r.theta_MM_deg,r.dTheta_own_deg,r.U_dTheta_own_deg,r.tip_MM,r.tip_H,r.compliance_MM/r.compliance_H,r.CMOD_MM/r.CMOD_H);
 end
end
fclose(fid);
end

function s=sanitize(s,repo)
if ischar(s),s=strrep(strrep(s,repo,'<repo>'),strrep(repo,'\','/'),'<repo>');
elseif isstruct(s)
 for k=1:numel(s),f=fieldnames(s);for j=1:numel(f),s(k).(f{j})=sanitize(s(k).(f{j}),repo);end,end
elseif iscell(s)
 for k=1:numel(s),s{k}=sanitize(s{k},repo);end
end
end
