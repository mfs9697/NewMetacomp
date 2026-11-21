function L = run_g2_m4a_analysis_batch()
%RUN_G2_M4A_ANALYSIS_BATCH  G2-M4.A original-vs-alternative full-path comparison (Issue #44).
%
% 1. Re-verifies the three alternative chains read-only (dry controller: forecasts, hashes,
%    mesh content, 34/34 re-audits, phase re-maps; no FEM, no writes in the chains).
% 2. Original family: PR #38 records (hash-pinned), WP3/WP3.4 homogeneous meshes (hash-pinned),
%    PR #41 chain records (each SHA found in the M3 ledger); rows recomputed exactly as the M3
%    analysis and REGRESSED against the M3 analysis ledger (1e-12).
% 3. Alternative family: rows from the three alternative chains only (R_direct, R_path, R_total,
%    both uncertainty rules, identity, separation with U_sep); S0 cross-chain bitwise check.
% 4. Cross-family: tips, lateral drift, headings, K and G, separation classes (STABLE /
%    MARGINAL / NONROBUST), ratio classes (ROBUST / SENSITIVE / NOT_ROBUST), band polygon
%    areas and the indicative area-proportional magnitude, overall verdict (G2_M4_POLICY_v1).
% Writes a NEW outputs/g2_m4_alt_family_v1/analysis_run_<time>/ (LEDGER.json, CSVs, FIGDATA.mat,
% SHA256SUMS.txt). No new solve, no crack advance.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pol=jsondecode(fileread(fullfile(here,'G2_M4_POLICY_v1.json')));
root=fullfile(repo,'outputs','g2_m4_alt_family_v1');
folder=fullfile(root,['analysis_run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'m4a_analysis_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
L=struct('schema','NewMetacomp.G2.M4A.AnalysisLedger.v1','issue',44,'started',datestr(now,31),'status','RUNNING','physicalFractureGrowthProven',false);
L.policySHA256=g2_sha256_file(fullfile(here,'G2_M4_POLICY_v1.json'));
try
 [s1,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));[s2,dt]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all -- matlab/g2',repo));
 assert(s1==0&&s2==0&&isempty(strtrim(dt)),'G2M4AA:DirtySource','Uncommitted sources:\n%s',dt);L.gitHead=strtrim(h);
 b=pol.base;s=[25.4 29.4 33.4];
 % ------------------------------------------------ original family
 led3=lower(fileread(fullfile(repo,'matlab','g2','evidence','m3_20261121','SHA256SUMS_original_outputs.txt')));
 assert(strcmpi(g2_sha256_file(fullfile(repo,'matlab','g2','evidence','m3_20261121','SHA256SUMS_original_outputs.txt')),b.m3LedgerSHA256),'G2M4AA:M3Ledger','M3 ledger hash.');
 rec=@(key)m2rec(repo,b,key);
 Ho={rec('S0_H1'),rec('S1_H1'),rec('S2_H1')};Umesh=abs(G(rec('S2alt_H1'))/G(Ho{3})-1);L.U_mesh=Umesh;
 f1=fullfile(repo,b.originalH_S1Mesh);f2=fullfile(repo,b.originalH_S2Mesh);
 assert(strcmpi(g2_sha256_file(f1),b.originalH_S1MeshSHA256)&&strcmpi(g2_sha256_file(f2),b.originalH_S2MeshSHA256),'G2M4AA:HMesh','Original homogeneous mesh hash.');
 m1=load(f1,'crackPolyline','tipTangent');m2=load(f2,'crackPolyline','tipTangent');
 P0=reshape(pol.start.polyline_mm,[],2);if ~isequal(P0(:,1),[101.6;101.6]),P0=reshape(pol.start.polyline_mm.',[],2);end
 PHo={P0,m1.crackPolyline,m2.crackPolyline};tHo={[0 1],m1.tipTangent(:).',m2.tipTangent(:).'};
 mats={'soft','Msoft';'stiff','Mstiff'};
 fam=struct();
 for i=1:2
  id=mats{i,1};MH={rec(['S0_',mats{i,2}]),rec(['S1_',mats{i,2}]),rec(['S2_',mats{i,2}])};
  ch=fullfile(repo,'outputs','g2_material_trajectories_v1',['chain_',id,'_v1']);
  MM=cell(1,3);PM=cell(1,3);tM=cell(1,3);gM=cell(1,3);turn=nan(1,3);MM{1}=MH{1};PM{1}=P0;tM{1}=[0 1];
  for k=1:2
   sd=fullfile(ch,sprintf('STEP_%03d',k));
   St=m3read(sd,'STATE.mat',led3,id,k);Sol=m3read(sd,'SOLUTION.mat',led3,id,k);Rv=m3read(sd,'REVIEW.mat',led3,id,k);
   MM{k+1}=Sol;PM{k+1}=St.crackPolyline_mm;tM{k+1}=St.t(:).';gM{k+1}=Rv.geometry;turn(k+1)=Rv.localTurn_deg;
  end
  [rows,sep]=build_rows(Ho,MH,MM,PHo,tHo,PM,tM,Umesh,pol,['orig ',id]);
  fam.o.(id)=struct('rows',rows,'sep',sep,'P',{PM},'t',{tM},'geom',{gM},'executedTurn_deg',turn,'K',{MM},'KH',{MH});
 end
 fam.o.homogeneous=struct('P',{PHo},'t',{tHo},'K',{Ho});
 % regression against the M3 analysis ledger
 lf=fullfile(repo,b.m3AnalysisLedger);assert(strcmpi(g2_sha256_file(lf),b.m3AnalysisLedgerSHA256),'G2M4AA:M3AnalysisHash','M3 analysis ledger hash.');
 L3=jsondecode(fileread(lf));dev=0;
 for i=1:2
  id=mats{i,1};r3=L3.results.(id).rows;if ~iscell(r3),r3=num2cell(r3);end;e3=L3.results.(id).separation;if ~iscell(e3),e3=num2cell(e3);end
  for k=1:3
   r=fam.o.(id).rows(k);q=r3{k};
   for nm={'R_direct','R_path','R_total'}
    dev=max([dev,rel(r.(nm{1}).R,q.(nm{1}).R),rel(r.(nm{1}).U,q.(nm{1}).U),rel(r.(nm{1}).U_cons,q.(nm{1}).U_cons)]);
   end
   dev=max([dev,rel(r.theta_MM_deg,q.theta_MM_deg),rel(r.dTheta_own_deg,q.dTheta_own_deg)]);
  end
  for k=1:2,dev=max([dev,rel(fam.o.(id).sep(k).lateral_mm,e3{k}.lateral_mm),rel(fam.o.(id).sep(k).U_sep_mm,e3{k}.U_sep_mm)]);end
 end
 L.originalRegressionMaxRelDev=dev;fprintf('M4A ORIGINAL regression vs M3 analysis ledger: max rel dev %.3g\n',dev);
 assert(dev<=pol.decomposition.identityTolerance,'G2M4AA:OriginalRegression','Original-family rows differ from the M3 analysis ledger (%.3g).',dev);
 % ------------------------------------------------ alternative family
 chA=@(id)fullfile(root,['chain_',id,'_alt_v1']);
 ver=struct();
 for id={'homogeneous','soft','stiff'}
  Rchk=g2_m4a_trajectory_run('Material',id{1});
  assert(Rchk.pass&&strcmp(Rchk.stage,'STEP_CAP')&&Rchk.lastStateIndex==2&&Rchk.statesReused==2&&Rchk.statesComputed==0,'G2M4AA:Chain','%s alternative chain not verified (%s).',id{1},Rchk.stage);
  ver.(id{1})=struct('rootSHA256',Rchk.rootSHA256,'s0RecordSHA256',Rchk.s0RecordSHA256,'stage',Rchk.stage);
 end
 L.altChains=ver;
 ch=chA('homogeneous');Ha=cell(1,3);PHa=cell(1,3);tHa=cell(1,3);MHa=struct('soft',{cell(1,3)},'stiff',{cell(1,3)});gHa=cell(1,3);turnHa=nan(1,3);identHa=cell(1,3);
 Ro=rd(fullfile(ch,'ROOT.mat'));identHa{1}=Ro.identityM0;
 Ha{1}=rd(fullfile(ch,'ROOT_S0','SOLUTION.mat'));MHa.soft{1}=rd(fullfile(ch,'ROOT_S0','SOLUTION_Msoft.mat'));MHa.stiff{1}=rd(fullfile(ch,'ROOT_S0','SOLUTION_Mstiff.mat'));
 PHa{1}=P0;tHa{1}=[0 1];
 for k=1:2
  sd=fullfile(ch,sprintf('STEP_%03d',k));St=rd(fullfile(sd,'STATE.mat'));Rv=rd(fullfile(sd,'REVIEW.mat'));
  Ha{k+1}=rd(fullfile(sd,'SOLUTION.mat'));MHa.soft{k+1}=rd(fullfile(sd,'SOLUTION_Msoft.mat'));MHa.stiff{k+1}=rd(fullfile(sd,'SOLUTION_Mstiff.mat'));
  PHa{k+1}=St.crackPolyline_mm;tHa{k+1}=St.t(:).';gHa{k+1}=Rv.geometry;turnHa(k+1)=Rv.localTurn_deg;identHa{k+1}=Rv.identityM0;
 end
 S0=g2_m4a_s0alt('Mode','verify','Reaudit',false);gHa{1}=S0.record.geometry;
 fam.a.homogeneous=struct('P',{PHa},'t',{tHa},'K',{Ha},'geom',{gHa},'executedTurn_deg',turnHa,'identityM0',{identHa});
 L.altM0IdentityBitwise=cellfun(@(x)x.bitwiseUandEDI,identHa);L.altM0IdentityPass=cellfun(@(x)x.pass,identHa);
 for i=1:2
  id=mats{i,1};ch=chA(id);MM=cell(1,3);PM=cell(1,3);tM=cell(1,3);gM=cell(1,3);turn=nan(1,3);
  MM{1}=rd(fullfile(ch,'ROOT_S0','SOLUTION.mat'));PM{1}=P0;tM{1}=[0 1];gM{1}=S0.record.geometry;
  bw=isequal(MM{1}.u,MHa.(id){1}.u)&&isequal(MM{1}.EDI_all,MHa.(id){1}.EDI_all)&&isequal(MM{1}.EDI4x4,MHa.(id){1}.EDI4x4)&& ...
   isequal([MM{1}.KI_COD_raw MM{1}.KII_COD_raw],[MHa.(id){1}.KI_COD_raw MHa.(id){1}.KII_COD_raw]);
  L.altS0CrossChainBitwise.(id)=bw;fprintf('M4A ALT S0 %s chain solve vs homogeneous-chain M%s solve bitwise=%d\n',id,id,bw);
  assert(bw,'G2M4AA:S0CrossChain','%s S0 solve is not bitwise equal to the homogeneous chain''s S0 solve.',id);
  for k=1:2
   sd=fullfile(ch,sprintf('STEP_%03d',k));St=rd(fullfile(sd,'STATE.mat'));Rv=rd(fullfile(sd,'REVIEW.mat'));
   MM{k+1}=rd(fullfile(sd,'SOLUTION.mat'));PM{k+1}=St.crackPolyline_mm;tM{k+1}=St.t(:).';gM{k+1}=Rv.geometry;turn(k+1)=Rv.localTurn_deg;
  end
  [rows,sep]=build_rows(Ha,MHa.(id),MM,PHa,tHa,PM,tM,Umesh,pol,['alt  ',id]);
  fam.a.(id)=struct('rows',rows,'sep',sep,'P',{PM},'t',{tM},'geom',{gM},'executedTurn_deg',turn,'K',{MM},'KH',{MHa.(id)});
 end
 % ------------------------------------------------ cross-family
 X=struct();
 for id={'homogeneous','soft','stiff'}
  o=fam.o.(id{1});a=fam.a.(id{1});r=struct([]);
  for k=1:3
   d=a.P{k}(end,:)-o.P{k}(end,:);nHo=[-fam.o.homogeneous.t{k}(2),fam.o.homogeneous.t{k}(1)];
   Ko=o.K{k};Ka=a.K{k};
   e=struct('s_mm',s(k),'tipOrig_mm',o.P{k}(end,:),'tipAlt_mm',a.P{k}(end,:),'tipDrift_mm',norm(d),'lateralDrift_mm',d*nHo.', ...
    'headingOrig_deg',atan2d(o.t{k}(2),o.t{k}(1)),'headingAlt_deg',atan2d(a.t{k}(2),a.t{k}(1)), ...
    'headingDrift_deg',atan2d(a.t{k}(2),a.t{k}(1))-atan2d(o.t{k}(2),o.t{k}(1)), ...
    'KI_orig',Ko.KI_perkN,'KI_alt',Ka.KI_perkN,'KII_orig',Ko.KII_perkN,'KII_alt',Ka.KII_perkN, ...
    'KI_relDrift',Ka.KI_perkN/Ko.KI_perkN-1,'KII_relDrift',Ka.KII_perkN/Ko.KII_perkN-1,'G_relDrift',G(Ka)/G(Ko)-1, ...
    'thetaOrig_deg',thetas(Ko).edi,'thetaAlt_deg',thetas(Ka).edi,'thetaDrift_deg',thetas(Ka).edi-thetas(Ko).edi, ...
    'KI_COD_relDrift',Ka.KI_COD_perkN/Ko.KI_COD_perkN-1,'J_relDrift',Ka.J/Ko.J-1);
   if isempty(r),r=e;else,r(end+1)=e;end %#ok<AGROW>
  end
  X.(id{1})=r;
  fprintf('M4A CROSS %-11s tip drift [%s] mm, lateral [%s] mm, KI rel [%s], KII rel [%s]\n',id{1},sprintf('%.3g ',[r.tipDrift_mm]),sprintf('%+.3g ',[r.lateralDrift_mm]), ...
   sprintf('%+.3g ',[r.KI_relDrift]),sprintf('%+.3g ',[r.KII_relDrift]));
 end
 L.A1_originalH_S1_sixDigitSeedOffset_mm=4.41e-6;
 cf=pol.crossFamilyCriteria;C=struct();verdictParts={};
 for i=1:2
  id=mats{i,1};so=fam.o.(id).sep;sa=fam.a.(id).sep;cls=struct([]);
  for k=1:2
   dO=so(k).lateral_mm;dA=sa(k).lateral_mm;D=dA-dO;dH=X.homogeneous(k+1).tipDrift_mm;Ua=sa(k).U_sep_mm;
   cond=struct('sameSign',sign(dA)==sign(dO),'relative',abs(D)<=.25*abs(dO),'absolute',abs(D)<=0.010,'distinct',abs(dA)>2*max(dH,Ua),'resolvedAlt',abs(dA)>2*Ua);
   if ~cond.sameSign||~cond.resolvedAlt,c='NONROBUST';elseif cond.relative&&cond.absolute&&cond.distinct,c='STABLE';else,c='MARGINAL';end
   e=struct('s_mm',s(k+1),'delta_orig_mm',dO,'delta_alt_mm',dA,'Delta_mm',D,'Delta_rel',D/dO,'d_H_mm',dH,'U_sep_alt_mm',Ua,'U_sep_orig_mm',so(k).U_sep_mm, ...
    'U_sep_cons_alt_mm',sa(k).U_sep_cons_mm,'conditions',cond,'class',c);
   if isempty(cls),cls=e;else,cls(end+1)=e;end %#ok<AGROW>
   verdictParts{end+1}=c; %#ok<AGROW>
   fprintf('M4A SEP %-5s s=%.1f: delta orig %+.6f alt %+.6f mm, Delta %+.3g (%.2f%%), d_H %.3g, U_sep alt %.3g -> %s\n',id,s(k+1),dO,dA,D,100*D/dO,dH,Ua,c);
  end
  rc=struct([]);
  for nm={'R_direct','R_path','R_total'}
   ks=1:3;if strcmp(nm{1},'R_path'),ks=2:3;end
   for k=ks
    Rq=fam.o.(id).rows(k).(nm{1});Ra=fam.a.(id).rows(k).(nm{1});dO=Rq.R-1;dA=Ra.R-1;
    if sign(dA)~=sign(dO),c='NOT_ROBUST';elseif abs(Ra.R-Rq.R)<=.25*abs(dO)+2*Umesh,c='ROBUST';else,c='SENSITIVE';end
    e=struct('ratio',nm{1},'s_mm',s(k),'R_orig',Rq.R,'R_alt',Ra.R,'dR',Ra.R-Rq.R,'dR_rel_of_effect',(Ra.R-Rq.R)/dO, ...
     'U_orig',Rq.U,'U_alt',Ra.U,'Ucons_orig',Rq.U_cons,'Ucons_alt',Ra.U_cons,'resolved_orig',Rq.resolved,'resolved_alt',Ra.resolved, ...
     'resolvedCons_orig',Rq.resolvedCons,'resolvedCons_alt',Ra.resolvedCons,'class',c);
    if isempty(rc),rc=e;else,rc(end+1)=e;end %#ok<AGROW>
    if k>=2&&~strcmp(nm{1},'R_total'),verdictParts{end+1}=c;end %#ok<AGROW>
    fprintf('M4A RATIO %-5s %-8s s=%.1f: orig %.6f alt %.6f dR %+.2e (%.2f%% of effect) U %.2g/%.2g -> %s\n',id,nm{1},s(k),Rq.R,Ra.R,Ra.R-Rq.R,100*(Ra.R-Rq.R)/dO,Rq.U,Ra.U,c);
   end
  end
  C.(id)=struct('separation',cls,'ratios',rc);
 end
 % band polygon accounting
 areaO=cellfun(@(g)g.annulusArea_mm2(:).',fam.o.soft.geom(2:3),'UniformOutput',false);
 areaA=[{gHa{1}.annulusArea_mm2(:).'},cellfun(@(g)g.annulusArea_mm2(:).',gHa(2:3),'UniformOutput',false), ...
  cellfun(@(g)g.annulusArea_mm2(:).',fam.a.soft.geom(2:3),'UniformOutput',false),cellfun(@(g)g.annulusArea_mm2(:).',fam.a.stiff.geom(2:3),'UniformOutput',false)];
 areaO=[areaO,cellfun(@(g)g.annulusArea_mm2(:).',fam.o.stiff.geom(2:3),'UniformOutput',false)];
 aO=vertcat(areaO{:});aA=vertcat(areaA{:});
 chO=cellfun(@(g)g.chordsPerCircle(:).',[fam.o.soft.geom(2:3),fam.o.stiff.geom(2:3)],'UniformOutput',false);
 chA2=cellfun(@(g)g.chordsPerCircle(:).',[gHa,fam.a.soft.geom(2:3),fam.a.stiff.geom(2:3)],'UniformOutput',false);
 BA=struct('orig_mm2',aO(1,:),'alt_mm2',aA(1,:),'origSpreadRel',(max(aO(:))-min(aO(:)))/mean(aO(:)),'altSpreadRel',(max(aA(:))-min(aA(:)))/mean(aA(:)), ...
  'altOverOrig_minus1',mean(aA(:))/mean(aO(:))-1,'nominal_mm2',pi*(19.05^2-6.35^2),'chordsOrig',unique(vertcat(chO{:}),'rows'),'chordsAlt',unique(vertcat(chA2{:}),'rows'));
 for i=1:2
  id=mats{i,1};for k=2:3,BA.areaHeuristic.(id)(k-1)=abs(fam.o.(id).rows(k).R_direct.R-1)*abs(BA.altOverOrig_minus1);end
 end
 fprintf('M4A BAND AREA orig %s alt %s mm2 (alt/orig-1 = %.4g; spreads %.2g / %.2g); chords orig %s alt %s\n',mat2str(BA.orig_mm2,10),mat2str(BA.alt_mm2,10), ...
  BA.altOverOrig_minus1,BA.origSpreadRel,BA.altSpreadRel,mat2str(BA.chordsOrig),mat2str(BA.chordsAlt));
 L.bandArea=BA;
 if all(strcmp(verdictParts,'STABLE')|strcmp(verdictParts,'ROBUST')),v='FULL_PATH_ROBUST';
 elseif any(strcmp(verdictParts,'NONROBUST')|strcmp(verdictParts,'NOT_ROBUST')),v='NOT_ROBUST';
 else,v='PARTIAL';end
 L.verdict=v;L.verdictParts=verdictParts;fprintf('M4A VERDICT %s (%s)\n',v,strjoin(verdictParts,','));
 L.crossFamily=X;L.classes=C;
 L.originalRows=struct('soft',fam.o.soft.rows,'stiff',fam.o.stiff.rows);L.altRows=struct('soft',fam.a.soft.rows,'stiff',fam.a.stiff.rows);
 L.originalSep=struct('soft',fam.o.soft.sep,'stiff',fam.o.stiff.sep);L.altSep=struct('soft',fam.a.soft.sep,'stiff',fam.a.stiff.sep);
 L.executedTurns=struct('orig_soft',fam.o.soft.executedTurn_deg,'orig_stiff',fam.o.stiff.executedTurn_deg,'alt_homogeneous',turnHa, ...
  'alt_soft',fam.a.soft.executedTurn_deg,'alt_stiff',fam.a.stiff.executedTurn_deg);
 FIG=struct('s',s,'Po',struct('homogeneous',{PHo},'soft',{fam.o.soft.P},'stiff',{fam.o.stiff.P}),'Pa',struct('homogeneous',{PHa},'soft',{fam.a.soft.P},'stiff',{fam.a.stiff.P}), ...
  'rowsO',L.originalRows,'rowsA',L.altRows,'sepO',L.originalSep,'sepA',L.altSep,'classes',C,'cross',X,'bandArea',BA,'U_mesh',Umesh,'verdict',v); %#ok<NASGU>
 save(fullfile(folder,'FIGDATA.mat'),'-struct','FIG');
 L.status='GO';
catch ME
 fprintf(2,'HOLD %s: %s\n',ME.identifier,ME.message);L.status='HOLD';L.hold=struct('identifier',ME.identifier,'message',ME.message,'stack',ME.stack(1).name,'line',ME.stack(1).line);
end
L.finished=datestr(now,31);
fid=fopen(fullfile(folder,'LEDGER.json'),'w');fwrite(fid,jsonencode(sanitize(L,repo),'PrettyPrint',true),'char');fclose(fid);
if strcmp(L.status,'GO'),write_csv(folder,L);end
diary('off');
fl=dir(folder);fl=fl(~[fl.isdir]);fid=fopen(fullfile(folder,'SHA256SUMS.txt'),'w');
for k=1:numel(fl),if ~strcmp(fl(k).name,'SHA256SUMS.txt'),fprintf(fid,'%s *%s\n',lower(g2_sha256_file(fullfile(folder,fl(k).name))),fl(k).name);end,end
fclose(fid);fprintf('G2_M4A_ANALYSIS_STATUS=%s FOLDER=%s\n',L.status,folder);
end

% =====================================================================
function [rows,sep]=build_rows(H,MH,MM,PH,tH,PM,tM,Umesh,pol,tag)
s=[25.4 29.4 33.4];rows=struct([]);
for k=1:3
 cross=k>1;
 Rd=ratio(MH{k},H{k},false);Rp=ratio(MM{k},MH{k},cross,Umesh);Rt=ratio(MM{k},H{k},cross,Umesh);
 if k==1,assert(Rp.R==1,'G2M4AA:S0Path','%s: R_path at S0 must be exactly 1.',tag);end
 idErr=abs(Rt.R-Rd.R*Rp.R)/Rt.R;assert(idErr<=pol.decomposition.identityTolerance,'G2M4AA:Identity','%s R_total identity (%.3g).',tag,idErr);
 thH=thetas(H{k});thMH=thetas(MH{k});thM=thetas(MM{k});
 r=struct('s_mm',s(k),'KI_H',H{k}.KI_perkN,'KII_H',H{k}.KII_perkN,'KI_MH',MH{k}.KI_perkN,'KII_MH',MH{k}.KII_perkN, ...
  'KI_MM',MM{k}.KI_perkN,'KII_MM',MM{k}.KII_perkN,'KI_COD_MM',MM{k}.KI_COD_perkN,'KII_COD_MM',MM{k}.KII_COD_perkN, ...
  'G_H',G(H{k}),'G_MH',G(MH{k}),'G_MM',G(MM{k}),'J_MM',MM{k}.J,'J_H',H{k}.J, ...
  'R_direct',Rd,'R_path',Rp,'R_total',Rt,'identityRelErr',idErr, ...
  'theta_H_deg',thH.edi,'theta_MH_deg',thMH.edi,'theta_MM_deg',thM.edi, ...
  'tangentGlobal_H_deg',atan2d(tH{k}(2),tH{k}(1)),'tangentGlobal_MM_deg',atan2d(tM{k}(2),tM{k}(1)), ...
  'compliance_H',H{k}.compliance_mm_per_N,'compliance_MM',MM{k}.compliance_mm_per_N,'tip_H',PH{k}(end,:),'tip_MM',PM{k}(end,:), ...
  'EDI_COD_offset_H',G(H{k})/((H{k}.KI_COD_raw^2+H{k}.KII_COD_raw^2)/H{k}.Ep_matrix)-1);
 [r.dTheta_own_deg,r.U_dTheta_own_deg,r.dTheta_cons_deg]=dtheta(thM,thH);
 [r.dTheta_direct_deg,r.U_dTheta_direct_deg]=dtheta(thMH,thH);
 fprintf('M4A %s s=%.1f: R_direct %.6f (%s/%s) R_path %.6f U %.2g (%s/%s) R_total %.6f (%s/%s) | theta H %.5f MH %.5f MM %.5f\n',tag,s(k), ...
  Rd.R,yn(Rd.resolved),yn(Rd.resolvedCons),Rp.R,Rp.U,yn(Rp.resolved),yn(Rp.resolvedCons),Rt.R,yn(Rt.resolved),yn(Rt.resolvedCons),thH.edi,thMH.edi,thM.edi);
 if isempty(rows),rows=r;else,rows(end+1)=r;end %#ok<AGROW>
end
sep=struct([]);
for k=2:3
 d=PM{k}(end,:)-PH{k}(end,:);nH=[-tH{k}(2),tH{k}(1)];
 if k==2,Usep=4*deg2rad(rows(1).U_dTheta_own_deg);Ucons=4*deg2rad(rows(1).dTheta_cons_deg);
 else,Usep=8*deg2rad(rows(1).U_dTheta_own_deg)+4*deg2rad(rows(2).U_dTheta_own_deg);Ucons=8*deg2rad(rows(1).dTheta_cons_deg)+4*deg2rad(rows(2).dTheta_cons_deg);end
 e=struct('s_mm',s(k),'tipSeparation_mm',norm(d),'lateral_mm',d*nH.','maxPolylineSeparation_mm',polysep(PM{k},PH{k}),'U_sep_mm',Usep,'U_sep_cons_mm',Ucons, ...
  'resolved',norm(d)>2*Usep,'resolvedCons',norm(d)>2*Ucons);
 if isempty(sep),sep=e;else,sep(end+1)=e;end %#ok<AGROW>
 fprintf('M4A %s s=%.1f: tip separation %.6f mm (lateral %+.6f) U_sep %.2g (%d) U_cons %.2g (%d)\n',tag,s(k),e.tipSeparation_mm,e.lateral_mm,Usep,e.resolved,Ucons,e.resolvedCons);
end
end

function r=m2rec(repo,b,key)
f=fullfile(repo,b.m2Run,['CASE_',key,'.mat']);
assert(strcmpi(g2_sha256_file(f),b.m2CaseSHA256.(key)),'G2M4AA:M2Hash','PR #38 record %s hash.',key);
[r,~,ok]=g2_trajectory_record('read',f);assert(ok,'G2M4AA:M2Record','PR #38 record %s.',key);
end

function r=m3read(sd,name,led,id,k)
f=fullfile(sd,name);h=lower(g2_sha256_file(f));
key=lower(sprintf('%s *g2_material_trajectories_v1/chain_%s_v1/step_%03d/%s',h,id,k,name));
assert(contains(led,key),'G2M4AA:M3Ledger','PR #41 file %s step %d %s not in the M3 ledger.',id,k,name);
[r,~,ok]=g2_trajectory_record('read',f);assert(ok,'G2M4AA:M3Record','PR #41 record %s.',f);
end

function r=rd(f)
[r,~,ok]=g2_trajectory_record('read',f);assert(ok,'G2M4AA:Read','Cannot read %s.',f);
end

function d=rel(a,b)
d=abs(a-b)/max(abs(b),1e-300);if a==b,d=0;end
end

function g=G(r),g=(r.KI_raw^2+r.KII_raw^2)/r.Ep_matrix;end

function Q=ratio(A,B,cross,Umesh)
if nargin<4,Umesh=0;end
E=A.Ep_matrix;g=@(k)(k(:,1).^2+k(:,2).^2)/E;
gA=g(A.EDI_all(:,1:2));gB=g(B.EDI_all(:,1:2));Rc=gA./gB;R=Rc(1);
R4=g(A.EDI4x4)/g(B.EDI4x4);Rcod=g([A.KI_COD_raw,A.KII_COD_raw])/g([B.KI_COD_raw,B.KII_COD_raw]);
U=max([max(abs(Rc-R)),abs(R4-R),abs(Rcod-R)]);if cross,U=max(U,Umesh);end
dA=abs(gA(1)-g([A.KI_COD_raw,A.KII_COD_raw]))/gA(1);dB=abs(gB(1)-g([B.KI_COD_raw,B.KII_COD_raw]))/gB(1);Uc=R*(dA+dB);
Q=struct('R',R,'R_COD',Rcod,'R_4x4',R4,'R_J',A.J/B.J,'R_contours',Rc.','U',U,'U_cons',Uc,'crossMesh',cross, ...
 'resolved',R~=1&&abs(R-1)>2*U&&sign(Rcod-1)==sign(R-1),'resolvedCons',R~=1&&abs(R-1)>Uc&&sign(Rcod-1)==sign(R-1));
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
sP=[0;cumsum(vecnorm(diff(P),2,2))];sQ=[0;cumsum(vecnorm(diff(Q),2,2))];
ss=linspace(0,min(sP(end),sQ(end)),3341).';
pp=[interp1(sP,P(:,1),ss),interp1(sP,P(:,2),ss)];qq=[interp1(sQ,Q(:,1),ss),interp1(sQ,Q(:,2),ss)];
m=max(vecnorm(pp-qq,2,2));
end

function s=yn(b),if b,s='yes';else,s='no';end,end

function write_csv(folder,L)
fid=fopen(fullfile(folder,'m4a_ratios_both_families.csv'),'w');
fprintf(fid,'family,material,s_mm,KI_H,KII_H,KI_M_GammaH,KII_M_GammaH,KI_M_own,KII_M_own,G_H,G_M_GammaH,G_M_own,R_direct,U_direct,Ucons_direct,R_path,U_path,Ucons_path,R_total,U_total,Ucons_total,identityRelErr,theta_H_deg,theta_MH_deg,theta_MM_deg,dTheta_own_deg,U_dTheta_own_deg,tipX_own,tipY_own,tipX_H,tipY_H,EDI_COD_offset_H\n');
for fm={'originalRows','altRows'}
 for m={'soft','stiff'}
  rows=L.(fm{1}).(m{1});
  for k=1:numel(rows)
   r=rows(k);
   fprintf(fid,'%s,%s,%.1f,%.9f,%+.9f,%.9f,%+.9f,%.9f,%+.9f,%.9e,%.9e,%.9e,%.9f,%.2e,%.2e,%.9f,%.2e,%.2e,%.9f,%.2e,%.2e,%.1e,%.6f,%.6f,%.6f,%+.6f,%.2e,%.10f,%.10f,%.10f,%.10f,%.5f\n', ...
    strrep(fm{1},'Rows',''),m{1},r.s_mm,r.KI_H,r.KII_H,r.KI_MH,r.KII_MH,r.KI_MM,r.KII_MM,r.G_H,r.G_MH,r.G_MM,r.R_direct.R,r.R_direct.U,r.R_direct.U_cons, ...
    r.R_path.R,r.R_path.U,r.R_path.U_cons,r.R_total.R,r.R_total.U,r.R_total.U_cons,r.identityRelErr,r.theta_H_deg,r.theta_MH_deg,r.theta_MM_deg, ...
    r.dTheta_own_deg,r.U_dTheta_own_deg,r.tip_MM,r.tip_H,r.EDI_COD_offset_H);
  end
 end
end
fclose(fid);
fid=fopen(fullfile(folder,'m4a_crossfamily_paths.csv'),'w');
fprintf(fid,'path,s_mm,tipX_orig,tipY_orig,tipX_alt,tipY_alt,tipDrift_mm,lateralDrift_mm,headingDrift_deg,KI_orig,KI_alt,KII_orig,KII_alt,KI_relDrift,KII_relDrift,G_relDrift,thetaDrift_deg\n');
for p={'homogeneous','soft','stiff'}
 for r=L.crossFamily.(p{1})
  fprintf(fid,'%s,%.1f,%.10f,%.10f,%.10f,%.10f,%.3e,%+.3e,%+.3e,%.9f,%.9f,%+.9f,%+.9f,%+.3e,%+.3e,%+.3e,%+.3e\n',p{1},r.s_mm,r.tipOrig_mm,r.tipAlt_mm,r.tipDrift_mm,r.lateralDrift_mm, ...
   r.headingDrift_deg,r.KI_orig,r.KI_alt,r.KII_orig,r.KII_alt,r.KI_relDrift,r.KII_relDrift,r.G_relDrift,r.thetaDrift_deg);
 end
end
fclose(fid);
fid=fopen(fullfile(folder,'m4a_classes.csv'),'w');
fprintf(fid,'material,quantity,s_mm,orig,alt,diff,diff_rel_of_effect,U_orig,U_alt,class\n');
for m={'soft','stiff'}
 for e=L.classes.(m{1}).separation
  fprintf(fid,'%s,lateral_mm,%.1f,%+.6f,%+.6f,%+.3e,%+.4f,%.2e,%.2e,%s\n',m{1},e.s_mm,e.delta_orig_mm,e.delta_alt_mm,e.Delta_mm,e.Delta_rel,e.U_sep_orig_mm,e.U_sep_alt_mm,e.class);
 end
 for e=L.classes.(m{1}).ratios
  fprintf(fid,'%s,%s,%.1f,%.9f,%.9f,%+.3e,%+.4f,%.2e,%.2e,%s\n',m{1},e.ratio,e.s_mm,e.R_orig,e.R_alt,e.dR,e.dR_rel_of_effect,e.U_orig,e.U_alt,e.class);
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
