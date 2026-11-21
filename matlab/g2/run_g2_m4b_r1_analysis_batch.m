function L = run_g2_m4b_r1_analysis_batch(r1Run)
%RUN_G2_M4B_R1_ANALYSIS_BATCH  Cross-family comparison original S2 (76) vs matched S2alt (112) (Issue #50).
%
%  L = run_g2_m4b_r1_analysis_batch(r1Run)
% Re-verifies the R1 run (RUN.json policy, manifest, SHA256SUMS) and the original-family M4.B
% records against the committed M4.B ledger, then for each family separately computes F_G and
% F_theta of the seven targets and the two full-band anchors with that family's own 'none', the
% primary (paired) and conservative (uncorrelated) uncertainty of policy v2, the equal-area
% single-ring differences d_ij, and finally the preregistered cross-family classes
% (STABLE / SENSITIVE / NOT_ROBUST / UNRESOLVED), ranking classes, stiff {1,3} context and the
% R1 verdict. A self-test requires the per-family formulas, applied to the original family, to
% reproduce the accepted M4.B decomposition ledger exactly. Writes a NEW
% outputs/g2_m4b_r1_s2alt_v1/analysis_run_<time>/ (never overwrites). No solve.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pf=fullfile(here,'G2_M4B_R1_POLICY_v1.json');pol=jsondecode(fileread(pf));polSHA=lower(g2_sha256_file(pf));
r1Run=char(r1Run);
out=fullfile(repo,'outputs','g2_m4b_r1_s2alt_v1',['analysis_run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);
assert(~exist(out,'dir'),'G2M4BR1:AnalysisExists','Analysis folder exists.');mkdir(out);
diary(fullfile(out,'r1_analysis_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
L=struct('schema','NewMetacomp.G2.M4B.R1.AnalysisLedger.v1','issue',50,'status','RUNNING','started',datestr(now,31), ...
 'r1Run',strrep(r1Run,repo,'<repo>'),'policySHA256',polSHA,'matlabRelease',['R',version('-release')],'physicalFractureGrowthProven',false);
ids={'none','c0p5_100','c0p5_010','c0p5_001','c0p5_111','c2p0_100','c2p0_010','c2p0_001','c2p0_101','c2p0_111'};
try
 % ---------------- verify R1 run
 RUN=jsondecode(fileread(fullfile(r1Run,'RUN.json')));
 assert(strcmpi(RUN.policySHA256,polSHA),'G2M4BR1:Policy','R1 run was made under another policy.');
 Mf=jsondecode(fileread(fullfile(r1Run,'CAMPAIGN_MANIFEST.json')));
 assert(Mf.allPass&&Mf.B2&&Mf.matchedGeometry&&numel(Mf.cases)==10,'G2M4BR1:Manifest','R1 manifest not GO.');
 L.r1FilesVerified=verify_sums(r1Run);L.r1Token=RUN.token;L.r1GitHead=RUN.gitHead;
 % ---------------- original-family records against the committed M4.B ledger
 of=pol.reference.originalFamilyResults;led=fullfile(repo,of.ledger);
 A=struct();O=struct();
 for k=1:numel(ids)
  [ra,ha,oka]=g2_trajectory_record('read',fullfile(r1Run,['CASE_',ids{k},'.mat']));
  assert(oka&&ra.K.pass&&ra.activation.pass&&strcmp(ra.caseId,ids{k}),'G2M4BR1:Record','R1 record %s invalid.',ids{k});
  fo=fullfile(repo,of.run,['CASE_',ids{k},'.mat']);
  [ro,ho,oko]=g2_trajectory_record('read',fo);
  assert(oko&&ledger_has(led,ho,[of.run,'/CASE_',ids{k},'.mat']),'G2M4BR1:OrigRecord','Original record %s not in the M4.B ledger.',ids{k});
  A.(ids{k})=summ(ra,lower(ha));O.(ids{k})=summ(ro,lower(ho));
  L.alphaCheck.(ids{k})=isequal(ra.bits,ro.bits)&&isequal(ra.mats,ro.mats);
  clear ra ro
 end
 assert(all(cellfun(@(x)x,struct2cell(L.alphaCheck))),'G2M4BR1:CaseMismatch','Case masks or materials differ between families.');
 % ---------------- linear-combination quantities per family
 % rows: 1 none, then the remaining ids in order; quantities as coefficient vectors over rows
 e=@(i)full(sparse(1,i,1,1,numel(ids)));row=@(id)find(strcmp(ids,id));F=@(id)e(row(id))-e(1);
 Q=struct('name',{},'kind',{},'contrast',{},'a',{});
 tg={'c0p5_100','c0p5_010','c0p5_001','c2p0_100','c2p0_010','c2p0_001','c2p0_101','c0p5_111','c2p0_111'};
 for k=1:numel(tg),Q(end+1)=struct('name',['F_',tg{k}],'kind',ternary(k<=7,'target','anchor'),'contrast',tg{k}(1:4),'a',F(tg{k})); end %#ok<AGROW>
 for c={'c0p5','c2p0'}
  s={[c{1},'_100'],[c{1},'_010'],[c{1},'_001']};pr=[1 2;1 3;2 3];
  for p=1:3,Q(end+1)=struct('name',sprintf('d_%d_%d_%s',pr(p,1),pr(p,2),c{1}),'kind','difference','contrast',c{1},'a',F(s{pr(p,1)})-F(s{pr(p,2)})); end %#ok<AGROW>
 end
 fam={'orig','alt'};S={O,A};res=struct();
 for f=1:2
  Gv=zeros(numel(ids),7);TH=Gv;
  for k=1:numel(ids),Gv(k,:)=S{f}.(ids{k}).Gvar;TH(k,:)=S{f}.(ids{k}).THvar;end
  aa=vertcat(Q.a);
  res.(fam{f}).G=lin(aa,Gv./Gv(1,:),'G',Gv);res.(fam{f}).theta=lin(aa,TH,'theta',TH);
  res.(fam{f}).Gv=Gv;res.(fam{f}).TH=TH;
 end
 % ---------------- self-test: original family must reproduce the accepted M4.B decomposition ledger
 Lm=jsondecode(fileread(fullfile(repo,'matlab','g2','evidence','m4b_20261121','analysis','LEDGER.json')));
 st=true;maxdev=0;
 map={'F_c0p5_100',1,'F_1';'F_c0p5_010',1,'F_2';'F_c0p5_001',1,'F_3';'F_c0p5_111',1,'F_123';'d_1_2_c0p5',1,'d_1_2';'d_1_3_c0p5',1,'d_1_3';'d_2_3_c0p5',1,'d_2_3'; ...
  'F_c2p0_100',2,'F_1';'F_c2p0_010',2,'F_2';'F_c2p0_001',2,'F_3';'F_c2p0_101',2,'F_13';'F_c2p0_111',2,'F_123';'d_1_2_c2p0',2,'d_1_2';'d_1_3_c2p0',2,'d_1_3';'d_2_3_c2p0',2,'d_2_3'};
 for k=1:size(map,1)
  i=strcmp({Q.name},map{k,1});At=Lm.attribution(map{k,2});j=strcmp(At.termNames,map{k,3});
  for obs={'G','theta'}
   v=[res.orig.(obs{1}).Q(i),res.orig.(obs{1}).U_primary(i),res.orig.(obs{1}).U_conservative(i)];
   w=[At.(obs{1}).Q(j),At.(obs{1}).U_primary(j),At.(obs{1}).U_conservative(j)];
   d=max(abs(v-w));maxdev=max(maxdev,d);st=st&&d<=1e-14;
  end
 end
 L.selfTest=struct('pass',st,'maxAbsDevVsM4Bledger',maxdev);
 fprintf('R1_SELFTEST reproduce M4.B decomposition: pass=%d maxdev=%.3g\n',st,maxdev);
 assert(st,'G2M4BR1:SelfTest','Per-family formulas do not reproduce the M4.B ledger.');
 % ---------------- classes
 rows=struct([]);
 for k=1:numel(Q)
  for obs={'G','theta'}
   o=res.orig.(obs{1});a=res.alt.(obs{1});
   qo=o.Q(k);qa=a.Q(k);rpO=o.resolvedPrimary(k);rpA=a.resolvedPrimary(k);
   if ~(rpO&&rpA),cls='UNRESOLVED';elseif sign(qa)~=sign(qo),cls='NOT_ROBUST';elseif abs(qa-qo)<=0.10*abs(qo),cls='STABLE';else,cls='SENSITIVE';end
   r=struct('quantity',Q(k).name,'kind',Q(k).kind,'contrast',Q(k).contrast,'observable',obs{1}, ...
    'Q_orig',qo,'U_orig',o.U_primary(k),'Ucons_orig',o.U_conservative(k),'resP_orig',rpO,'resC_orig',o.resolvedConservative(k), ...
    'Q_alt',qa,'U_alt',a.U_primary(k),'Ucons_alt',a.U_conservative(k),'resP_alt',rpA,'resC_alt',a.resolvedConservative(k), ...
    'delta',qa-qo,'relDelta',(qa-qo)/abs(qo),'deltaOverUcons',abs(qa-qo)/max(o.U_conservative(k),realmin),'class',cls);
   if isempty(rows),rows=r;else,rows(end+1)=r;end %#ok<AGROW>
  end
 end
 L.comparison=rows;
 % ---------------- rankings (equal active area, single rings)
 rk=struct([]);
 for c={'c0p5','c2p0'}
  for obs={'G','theta'}
   fo=arrayfun(@(i)res.orig.(obs{1}).Q(strcmp({Q.name},sprintf('F_%s_%s',c{1},bitstr(i)))),1:3);
   fa=arrayfun(@(i)res.alt.(obs{1}).Q(strcmp({Q.name},sprintf('F_%s_%s',c{1},bitstr(i)))),1:3);
   [~,po]=sort(fo,'descend');[~,pa]=sort(fa,'descend');
   dc={rows(strcmp({rows.contrast},c{1})&strcmp({rows.observable},obs{1})&strcmp({rows.kind},'difference')).class};
   if isequal(po,pa)&&~any(strcmp(dc,'NOT_ROBUST'))&&~any(strcmp(dc,'UNRESOLVED')),rc='RANKING_STABLE';
   elseif isequal(po,pa)&&~any(strcmp(dc,'NOT_ROBUST')),rc='RANKING_UNRESOLVED';
   else,rc='RANKING_CHANGED';end
   x=struct('contrast',c{1},'observable',obs{1},'orderOrig',po,'orderAlt',pa,'f_orig',fo,'f_alt',fa,'differenceClasses',{dc},'class',rc);
   if isempty(rk),rk=x;else,rk(end+1)=x;end %#ok<AGROW>
  end
 end
 L.rankings=rk;
 % ---------------- stiff {1,3} context (unequal area)
 sn={'c2p0_100','c2p0_010','c2p0_001','c2p0_101','c2p0_111'};
 fgA=arrayfun(@(i)res.alt.G.Q(strcmp({Q.name},['F_',sn{i}])),1:5);fgO=arrayfun(@(i)res.orig.G.Q(strcmp({Q.name},['F_',sn{i}])),1:5);
 [~,ia]=min(fgA);[~,io]=min(fgO);
 L.stiff13=struct('cases',{sn},'F_G_orig',fgO,'F_G_alt',fgA,'lowestOrig',sn{io},'lowestAlt',sn{ia}, ...
  'classG',rows(strcmp({rows.quantity},'F_c2p0_101')&strcmp({rows.observable},'G')).class, ...
  'classTheta',rows(strcmp({rows.quantity},'F_c2p0_101')&strcmp({rows.observable},'theta')).class, ...
  'note','unequal-area context only; no other two-ring set computed on S2alt');
 % ---------------- anchors and per-case drift
 cd=struct([]);
 for k=1:numel(ids)
  o=O.(ids{k});a=A.(ids{k});
  x=struct('case',ids{k},'KI_orig',o.KI_perkN,'KI_alt',a.KI_perkN,'KI_rel',(a.KI_perkN-o.KI_perkN)/o.KI_perkN, ...
   'KII_orig',o.KII_perkN,'KII_alt',a.KII_perkN,'KII_rel',(a.KII_perkN-o.KII_perkN)/o.KII_perkN, ...
   'KI_COD_alt',a.KI_COD_perkN,'KII_COD_alt',a.KII_COD_perkN,'J_alt',a.J,'G_orig',o.Gvar(1),'G_alt',a.Gvar(1),'G_rel',(a.Gvar(1)-o.Gvar(1))/o.Gvar(1), ...
   'theta_orig',o.THvar(1),'theta_alt',a.THvar(1),'theta_diff',a.THvar(1)-o.THvar(1), ...
   'C_orig',o.compliance,'C_alt',a.compliance,'C_rel',(a.compliance-o.compliance)/o.compliance,'CMOD_alt',a.CMOD, ...
   'U_alt',a.U_total,'Uring_alt',a.U_ring,'activeArea_alt',a.activeArea_mm2,'activeArea_orig',o.activeArea_mm2, ...
   'bal_alt',a.bal,'res_alt',a.res,'eid_alt',a.eid,'resid_alt',a.resid,'rootCheck_alt',a.rootCheck,'sha_alt',a.sha,'sha_orig',o.sha);
  if isempty(cd),cd=x;else,cd(end+1)=x;end %#ok<AGROW>
 end
 L.cases=cd;
 Lm2=jsondecode(fileread(fullfile(repo,'outputs','g2_material_evolution_v1','run_20261121_132226_301','LEDGER.json')));
 m2=Lm2.results.S2alt.classification;
 L.anchorCheck=struct('soft_dR_alt_M2',m2.Msoft.dR_alt,'soft_dR_alt_R1',res.alt.G.Q(strcmp({Q.name},'F_c0p5_111')), ...
  'stiff_dR_alt_M2',m2.Mstiff.dR_alt,'stiff_dR_alt_R1',res.alt.G.Q(strcmp({Q.name},'F_c2p0_111')));
 L.anchorCheck.pass=abs(L.anchorCheck.soft_dR_alt_M2-L.anchorCheck.soft_dR_alt_R1)<=1e-12&&abs(L.anchorCheck.stiff_dR_alt_M2-L.anchorCheck.stiff_dR_alt_R1)<=1e-12;
 assert(L.anchorCheck.pass,'G2M4BR1:Anchor','Full-band S2alt F_G does not reproduce the M2 S2alt table.');
 % ---------------- verdict
 sr=rows(strcmp({rows.kind},'target')&~strcmp({rows.quantity},'F_c2p0_101'));
 sc={sr.class};rcl={rk.class};
 if all(strcmp(sc,'STABLE'))&&all(strcmp(rcl,'RANKING_STABLE')),v='R1_PLACEMENT_STABLE';
 elseif ~any(strcmp(sc,'NOT_ROBUST'))&&~any(strcmp(rcl,'RANKING_CHANGED')),v='R1_PLACEMENT_SENSITIVE';
 else,v='R1_NOT_ROBUST';end
 L.verdict=v;L.singleRingClasses=struct('stable',nnz(strcmp(sc,'STABLE')),'sensitive',nnz(strcmp(sc,'SENSITIVE')), ...
  'unresolved',nnz(strcmp(sc,'UNRESOLVED')),'notRobust',nnz(strcmp(sc,'NOT_ROBUST')),'total',numel(sc));
 fprintf('R1_VERDICT %s  single-ring classes %s  rankings %s  stiff13 G %s theta %s\n',v,jsonencode(L.singleRingClasses),strjoin(rcl,','),L.stiff13.classG,L.stiff13.classTheta);
 write_csv(out,L);
 save(fullfile(out,'R1_FIGDATA.mat'),'res','Q','ids','-v7');
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
fprintf('G2_M4B_R1_ANALYSIS_STATUS=%s folder %s\n',L.status,strrep(out,repo,'<repo>'));
end

% =====================================================================
function q=lin(a,V,kind,raw)
% identical formulas to g2_m4b_attribution (policy v2): primary = max variant deviation of the
% same combination (paired), conservative = uncorrelated linear bound
nE=size(V,2);Qe=a*V;Q=Qe(:,1);Qcod=Qe(:,nE);
U=max(abs(Qe(:,2:end)-Q),[],2);resP=abs(Q)>2*U&sign(Qcod)==sign(Q);
if strcmp(kind,'G')
 r=V(:,1);d=abs(raw(:,1)-raw(:,nE))./raw(:,1);nz=2:size(V,1);
 Uc=abs(a(:,nz))*(r(nz).*d(nz))+abs(a(:,nz)*r(nz))*d(1);resC=abs(Q)>Uc&sign(Qcod)==sign(Q);
else
 ek=abs(V(:,nE)-V(:,1));Uc=abs(a)*ek;resC=abs(Q)>Uc;
end
q=struct('Q',Q,'Q_COD',Qcod,'U_primary',U,'resolvedPrimary',resP,'U_conservative',Uc,'resolvedConservative',resC,'Q_variants',Qe);
end

function s=summ(rec,h)
K=rec.K;s1k=sqrt(1000);E=K.Ep_matrix;g=@(k)(k(:,1).^2+k(:,2).^2)/E;
mts=@(a,b)g2_mts_direction(a*s1k,b*s1k).theta_deg;
Kv=[K.EDI_all(:,1:2);K.EDI4x4;[K.KI_COD,K.KII_COD]];
s=struct('sha',h,'Gvar',g(Kv).','THvar',arrayfun(@(i)mts(Kv(i,1),Kv(i,2)),1:7), ...
 'KI_perkN',K.KI_MPa_sqrt_m_per_kN,'KII_perkN',K.KII_MPa_sqrt_m_per_kN,'KI_COD_perkN',K.KI_COD*s1k,'KII_COD_perkN',K.KII_COD*s1k, ...
 'J',K.J,'compliance',K.compliance_mm_per_N,'CMOD',K.CMOD_mm,'U_total',K.strainEnergy_per_thickness*12.7, ...
 'U_ring',(K.ringStrainEnergy_per_thickness*12.7).','activeArea_mm2',K.activeArea_mm2, ...
 'bal',K.activeInterfaceBalanceRel,'res',K.activeAnnulusResultantRel,'eid',K.energyIdentityRel,'resid',K.relativeResidual);
th=s.THvar(1)*pi/180;f=@(x)K.KI*sin(x)+K.KII*(3*cos(x)-1);
s.rootCheck=abs(fzero(f,[-pi/2,pi/2],optimset('TolX',1e-15))-th);
end

function b=bitstr(i)
b='000';b(i)='1';
end

function n=verify_sums(d)
s=splitlines(strtrim(fileread(fullfile(d,'SHA256SUMS.txt'))));n=0;
for k=1:numel(s)
 tk=regexp(strtrim(s{k}),'^([0-9a-f]{64}) \*(.+)$','tokens','once');
 assert(~isempty(tk)&&strcmpi(g2_sha256_file(fullfile(d,tk{2})),tk{1}),'G2M4BR1:Sums','SHA256SUMS mismatch at %s.',s{k});n=n+1;
end
end

function ok=ledger_has(file,hash,path)
ok=false;if ~isfile(file),return,end
txt=splitlines(fileread(file));rel=lower(regexprep(path,'^outputs/',''));
for k=1:numel(txt)
 l=lower(strtrim(txt{k}));
 if startsWith(l,lower(hash))&&endsWith(l,['*',rel]),ok=true;return,end
end
end

function write_csv(out,L)
fid=fopen(fullfile(out,'r1_crossfamily.csv'),'w');
fprintf(fid,'quantity,kind,contrast,observable,Q_orig,U_primary_orig,U_cons_orig,resolvedP_orig,resolvedC_orig,Q_alt,U_primary_alt,U_cons_alt,resolvedP_alt,resolvedC_alt,delta,rel_delta,delta_over_Ucons_orig,class\n');
for r=L.comparison
 fprintf(fid,'%s,%s,%s,%s,%+.12g,%.4g,%.4g,%d,%d,%+.12g,%.4g,%.4g,%d,%d,%+.6g,%+.6g,%.4g,%s\n',r.quantity,r.kind,r.contrast,r.observable, ...
  r.Q_orig,r.U_orig,r.Ucons_orig,r.resP_orig,r.resC_orig,r.Q_alt,r.U_alt,r.Ucons_alt,r.resP_alt,r.resC_alt,r.delta,r.relDelta,r.deltaOverUcons,r.class);
end
fclose(fid);
fid=fopen(fullfile(out,'r1_cases_both_families.csv'),'w');
fprintf(fid,'case,KI_orig,KI_alt,KI_rel,KII_orig,KII_alt,KII_rel,KI_COD_alt,KII_COD_alt,J_alt,G_orig,G_alt,G_rel,theta_orig,theta_alt,theta_diff,C_orig,C_alt,C_rel,CMOD_alt,active_area_orig,active_area_alt,sha_alt\n');
for c=L.cases
 fprintf(fid,'%s,%.12g,%.12g,%+.4e,%+.12g,%+.12g,%+.4e,%.12g,%+.12g,%.12g,%.12g,%.12g,%+.4e,%+.10g,%+.10g,%+.4e,%.12g,%.12g,%+.4e,%.12g,%.10g,%.10g,%s\n',c.case, ...
  c.KI_orig,c.KI_alt,c.KI_rel,c.KII_orig,c.KII_alt,c.KII_rel,c.KI_COD_alt,c.KII_COD_alt,c.J_alt,c.G_orig,c.G_alt,c.G_rel,c.theta_orig,c.theta_alt,c.theta_diff, ...
  c.C_orig,c.C_alt,c.C_rel,c.CMOD_alt,c.activeArea_orig,c.activeArea_alt,c.sha_alt);
end
fclose(fid);
fid=fopen(fullfile(out,'r1_rankings.csv'),'w');fprintf(fid,'contrast,observable,order_orig,order_alt,class\n');
for r=L.rankings,fprintf(fid,'%s,%s,%s,%s,%s\n',r.contrast,r.observable,mat2str(r.orderOrig),mat2str(r.orderAlt),r.class);end
fclose(fid);
end

function r=ternary(c,a,b),if c,r=a;else,r=b;end,end
