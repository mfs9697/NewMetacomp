function A=g2_a1_analyze(execRepo,runName,outFile)
%G2_A1_ANALYZE  Post-campaign A1 comparison from saved records only (Issue #66). No FEM.
%
%  A = g2_a1_analyze(execRepo,'run_a1_family_b_s4_v1',outFile)
% B0 = the archived A0/LP1 S4 SOLUTION (policy baselineS4 path; bitwise equal to the A0 rerun).
% B3/B6/B9 = the A1 STATE + SOLUTION records of the named run. For every case and level:
% signed K_I, K_II, K_II/K_I, J, G=(K_I^2+K_II^2)/E', local MTS, blind COD, five EDI annuli,
% the 4x4 EDI, path spread, COD-EDI and J-G identities, compliance, cost (A1 only), and signed
% changes versus B0 and versus the previous level. F_G(case,m)=G_case(m)/G_H(m)-1 per level.
% Independent cross-checks: STATE fields bitwise equal to SOLUTION.K, solution SHA in STATE equals
% the file SHA, G recomputed, MTS recomputed in closed form, all SIF gates passed.
here=fileparts(mfilename('fullpath'));g2=fullfile(execRepo,'matlab','g2');addpath(g2,'-begin');
pol=jsondecode(fileread(fullfile(g2,'G2_A1_POLICY_v1.json')));
cases={'H','stiff13','soft2','soft1'};lv=[0 3 6 9];
A=struct('schema','NewMetacomp.G2.A1.Analysis.v1','runName',runName,'levels',lv,'cases',{cases});
A.policySHA256=lower(g2_sha256_file(fullfile(g2,'G2_A1_POLICY_v1.json')));
R=struct();chk={};
for ci=1:4
 c=cases{ci};
 for k=1:4
  m=lv(k);
  if m==0
   bd=fileparts(fullfile(execRepo,strrep(pol.baselineS4.(c).path,'/',filesep)));
   [So,~,ok]=g2_trajectory_record('read',fullfile(bd,'SOLUTION.mat'));assert(ok,'A1AN:Read','B0 solution unreadable');
   K=So.K;M=load(fullfile(bd,'MESH.mat'));
   e=struct('source',strrep(pol.baselineS4.(c).path,'MESH.mat','SOLUTION.mat'),'T3',size(M.T3,1),'DOF',2*size(M.X6,1), ...
    'h1_mm',tipEdge(M),'qActivePrimary',K.qActiveElements(1),'seconds',NaN,'availableBefore_GiB',NaN,'availableAfter_GiB',NaN, ...
    'matlabUsedAfter_GiB',NaN);
  else
   key=sprintf('%s_B%d',c,m);sd=fullfile(execRepo,'outputs','g2_a1_fixed_path_v1',runName,key);
   [St,stSHA,ok1]=g2_trajectory_record('read',fullfile(sd,'STATE.mat'));
   [So,soSHA,ok2]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));
   assert(ok1&&ok2,'A1AN:Read','A1 record unreadable: %s',key);K=So.K;
   chk{end+1}=struct('key',key,'stateSHA256',lower(stSHA),'solutionSHA256',lower(soSHA), ...
    'solutionSHAInState',strcmpi(St.solutionSHA256,soSHA),'meshSHAPreregistered',strcmp(St.meshContentSHA256,pol.meshes.(key).contentSHA256), ...
    'stateEqualsSolution',isequal(St.KI,K.KI)&&isequal(St.KII,K.KII)&&isequal(St.J,K.J)&&isequal(St.EDI_all,K.EDI_all)&&isequal(St.KI_COD,K.KI_COD), ...
    'sifGatesPassed',isequal(K.pass,true)&&isempty(K.failedCriteria), ...
    'Grecomputed',abs(St.G/((K.KI^2+K.KII^2)/K.Ep_matrix)-1), ...
    'MTSclosedForm_absdiff_deg',abs(St.MTS_deg-mtsClosed(K.KI,K.KII)), ...
    'policySHA',strcmp(St.policySHA256,A.policySHA256)); %#ok<AGROW>
   r=St.resources;s=St.mesh;
   e=struct('source',['outputs/g2_a1_fixed_path_v1/' runName '/' key],'T3',s.T3,'DOF',s.DOF,'h1_mm',s.tipFirstEdgeRadial_mm, ...
    'qActivePrimary',K.qActiveElements(1),'seconds',r.seconds,'availableBefore_GiB',r.availableBefore_GiB, ...
    'availableAfter_GiB',r.availableAfter_GiB,'matlabUsedAfter_GiB',r.matlabUsedAfter_GiB);
  end
  Mt=g2_mts_direction(K.KI,K.KII);Kr=hypot(K.KI,K.KII);ed=K.EDI_all;
  e.KI=K.KI;e.KII=K.KII;e.KIIoverKI=K.KII/K.KI;e.J=K.J;e.G=(K.KI^2+K.KII^2)/K.Ep_matrix;e.JoverGminus1=K.J/e.G-1;
  e.MTS_deg=Mt.theta_deg;e.KI_COD=K.KI_COD;e.KII_COD=K.KII_COD;e.EDI_KI=ed(:,1).';e.EDI_KII=ed(:,2).';e.EDI_J=ed(:,3).';
  e.EDI4x4=K.EDI4x4;e.qActiveElements=K.qActiveElements(:).';
  e.pathSpread_rel=max(max(ed(:,1:2))-min(ed(:,1:2)))/Kr;
  e.CODminusEDI_rel=max(abs([K.KI_COD-K.KI,K.KII_COD-K.KII]))/Kr;
  e.quad4x4_rel=max(abs(K.EDI4x4-[K.KI,K.KII]))/Kr;
  e.compliance_mm_per_N=K.compliance_mm_per_N;e.strainEnergy=K.strainEnergy_per_thickness;
  e.relativeResidual=K.relativeResidual;e.energyIdentityRel=K.energyIdentityRel;e.sifPass=K.pass;
  R.(c)(k)=e;
 end
 % signed changes versus B0 and versus the previous level
 for k=1:4
  e0=R.(c)(1);ep=R.(c)(max(k-1,1));e=R.(c)(k);K0=hypot(e0.KI,e0.KII);
  R.(c)(k).dKI_rel_B0=e.KI/e0.KI-1;R.(c)(k).dKII_overK_B0=(e.KII-e0.KII)/K0;R.(c)(k).dG_rel_B0=e.G/e0.G-1;
  R.(c)(k).dJ_rel_B0=e.J/e0.J-1;R.(c)(k).dMTS_deg_B0=e.MTS_deg-e0.MTS_deg;R.(c)(k).dCompliance_rel_B0=e.compliance_mm_per_N/e0.compliance_mm_per_N-1;
  R.(c)(k).dKI_rel_prev=e.KI/ep.KI-1;R.(c)(k).dKII_overK_prev=(e.KII-ep.KII)/K0;R.(c)(k).dG_rel_prev=e.G/ep.G-1;
  R.(c)(k).dMTS_deg_prev=e.MTS_deg-ep.MTS_deg;
 end
end
for ci=1:4
 c=cases{ci};
 for k=1:4,R.(c)(k).F_G=R.(c)(k).G/R.H(k).G-1;end
 fg=[R.(c).F_G];A.F_G.(c)=fg;A.F_G_range.(c)=max(fg)-min(fg);A.F_G_B9minusB0.(c)=fg(4)-fg(1);A.F_G_B9minusB6.(c)=fg(4)-fg(3);
end
A.records=R;A.checks=[chk{:}];
A.allChecksPass=all(arrayfun(@(x)x.solutionSHAInState&&x.meshSHAPreregistered&&x.stateEqualsSolution&&x.sifGatesPassed&& ...
 x.Grecomputed<1e-12&&x.MTSclosedForm_absdiff_deg<1e-9&&x.policySHA,A.checks));
A.nA1Records=numel(A.checks);
fid=fopen(outFile,'w');fwrite(fid,jsonencode(A,'PrettyPrint',true),'char');fclose(fid);
fprintf('A1_ANALYSIS records=%d allChecksPass=%d\n',A.nA1Records,A.allChecksPass);
end

function h=tipEdge(M)
fan=find(any(M.T3==M.physicalTipNode,2));E=unique(sort([M.T3(fan,[1 2]);M.T3(fan,[2 3]);M.T3(fan,[3 1])],2),'rows');
e=E(any(E==M.physicalTipNode,2),:);h=min(vecnorm(M.X3(e(:,1),:)-M.X3(e(:,2),:),2,2));
end
function th=mtsClosed(KI,KII)
% maximum tangential stress kink angle, closed form (Erdogan-Sih), degrees
if KII==0,th=0;return,end
th=2*atand((KI-sqrt(KI^2+8*KII^2))/(4*KII));
end
