function T=g2_lp2_contract(C)
%G2_LP2_CONTRACT  LP2-A GO, gate, ledger, forecast, classification, driver and analysis tests. No FEM.
% Negatives require the exact identifier and message fragment. GO fixtures are in memory; ledger
% tests write only inside a removed tempname folder. C: g2_lp2_context output.
rows=struct('name',{},'kind',{},'expected',{},'observed',{},'pass',{});
UN='G2LP2:HOLD_UNAUTHORIZED_STATE';SRC='G2LP2:HOLD_SOURCE';pol=C.policy;
% ---------------------------------------------------------------- GO validator (pure)
Cs=struct('policySHA256',repmat('a',1,64),'g2SourceSHA256',repmat('b',1,64),'lp2SourceSHA256',repmat('c',1,64), ...
 'parentManifestSHA256',repmat('d',1,64),'token','G2LP2A|fixture','policy',struct('authorization',pol.authorization));
ce=struct('pass',true,'passed',40,'total',40,'physicalSolves',0,'negativeTestsPassed',true,'token','G2LP2A|fixture');
good=struct('exists',true,'sha256',repmat('e',1,64),'text',jsonencode(ce));ld=@(E)@(f)E;
G0=struct('decision','GO_LP2A_PHYSICAL','reviewStatus','REVIEWED_ACCEPTED','scientificReviewer','fixture','reviewURL','https://github.com/mfs9697/NewMetacomp/pull/0', ...
 'approvedPolicySHA256',Cs.policySHA256,'approvedG2SourceSHA256',Cs.g2SourceSHA256,'approvedLP2SourceSHA256',Cs.lp2SourceSHA256, ...
 'approvedParentManifestSHA256',Cs.parentManifestSHA256,'approvedToken',Cs.token,'approvedCases',{{'H','stiff13','soft2','soft1'}}, ...
 'maxStateIndex',8,'maxSolves',16,'revocationRequired',true,'contractEvidenceFile','docs/research/G2_LP2_evidence/LP2A_CONTRACT.json', ...
 'contractEvidenceSHA256',good.sha256,'approvedRunName','run_lp2a_s5_s8_v1','campaignId','G2-LP2A-001','campaignScope','LP2A_S5_S8_MAX16');
ok('go_valid_fixture','go',@()isstruct(g2_lp2_go_validate(G0,Cs,ld(good))));
gn('go_missing_field',rmfield(G0,'maxSolves'),UN,'Incomplete');
gn('go_x6_decision',setf(G0,'decision','GO_M5_X6_PHYSICAL'),UN,'decision or review');
gn('go_not_reviewed',setf(G0,'reviewStatus','PENDING'),UN,'decision or review');
gn('go_empty_reviewer',setf(G0,'scientificReviewer',' '),UN,'decision or review');
gn('go_foreign_url',setf(G0,'reviewURL','https://example.org'),UN,'decision or review');
gn('go_wrong_scope',setf(G0,'campaignScope','M5_X6_S4_B9_CROSSED_MAX6'),UN,'scope, run name');
gn('go_bad_run_name',setf(G0,'approvedRunName','bad name'),UN,'scope, run name');
for r={'run_20261122_lp1_v1','run_a0_lp1_repro_v1','run_a1_family_b_s4_v1','run_m5x6_crossed_s4_b9_v1'}
 gn(['go_forbidden_run_' r{1}],setf(G0,'approvedRunName',r{1}),UN,'scope, run name');
end
for r={'G2-LP1-A0-001','G2-A1-FB-001','G2-M5-X6-001'},gn(['go_forbidden_campaign_' r{1}],setf(G0,'campaignId',r{1}),UN,'scope, run name');end
gn('go_three_cases',setf(G0,'approvedCases',{'H','stiff13','soft2'}),UN,'four cases');
gn('go_reordered_cases',setf(G0,'approvedCases',{'stiff13','H','soft2','soft1'}),UN,'four cases');
gn('go_state_nine',setf(G0,'maxStateIndex',9),UN,'four cases');
gn('go_seventeen_solves',setf(G0,'maxSolves',17),UN,'four cases');
gn('go_no_revocation',setf(G0,'revocationRequired',false),UN,'four cases');
for f={'approvedPolicySHA256','approvedG2SourceSHA256','approvedLP2SourceSHA256','approvedParentManifestSHA256'}
 gn(['go_mismatch_' f{1}],setf(G0,f{1},repmat('f',1,64)),SRC,'does not bind');
end
gn('go_token_mismatch',setf(G0,'approvedToken','G2LP2A|other'),SRC,'does not bind');
gn('go_contract_outside_dir',setf(G0,'contractEvidenceFile','docs/research/G2_M5_X6_evidence/M5X6_CONTRACT.json'),SRC,'not pinned');
gn('go_contract_dotdot',setf(G0,'contractEvidenceFile','docs/research/G2_LP2_evidence/../x.json'),SRC,'not pinned');
ex('go_contract_absent','go',@()g2_lp2_go_validate(G0,Cs,ld(struct('exists',false,'sha256','','text',''))),SRC,'absent or changed');
ex('go_contract_changed','go',@()g2_lp2_go_validate(setf(G0,'contractEvidenceSHA256',repmat('9',1,64)),Cs,ld(good)),SRC,'absent or changed');
b=good;b.text=jsonencode(setf(ce,'physicalSolves',1));ex('go_contract_with_solves','go',@()g2_lp2_go_validate(G0,Cs,ld(b)),UN,'has not passed');
b=good;b.text=jsonencode(setf(ce,'passed',39));ex('go_contract_not_passed','go',@()g2_lp2_go_validate(G0,Cs,ld(b)),UN,'has not passed');
b=good;b.text=jsonencode(setf(ce,'token','x'));ex('go_contract_other_token','go',@()g2_lp2_go_validate(G0,Cs,ld(b)),SRC,'another token');
% ---------------------------------------------------------------- gate
ok('gate_go_absent','gate',@()~isfile(fullfile(C.lp2,'G2_LP2A_SCIENTIFIC_GO_v1.json')));
ex('gate_refuses_without_go','gate',@()g2_lp2_scientific_gate(C),UN,'no GO_LP2A record');
% ---------------------------------------------------------------- ledger hook (temp)
tmp=tempname;mkdir(tmp);cl=onCleanup(@()rmdir(tmp,'s'));lr=fullfile(tmp,'L');Co=struct('mode','CONTINUE');
g2_lp1_campaign_ledger('write',lr,'RECEIPT','RECEIPT.mat',struct('campaignId','FIX','runName','run_fix','goSHA256','x','token','t'));
for i=1:4,for k=5:8,g2_lp2_admit_hook(lr,Co,'FIX',sprintf('c%d',i),k);end,end
L=g2_lp1_campaign_ledger('snapshot',lr);ok('hook_sixteen_admissions','ledger',@()L.integrityOK&&numel(L.admits)==16);
ex('hook_seventeenth_refused','ledger',@()g2_lp2_admit_hook(lr,Co,'FIX','c5',5),UN,'sixteen-solve ceiling');
lr2=fullfile(tmp,'L2');g2_lp1_campaign_ledger('write',lr2,'RECEIPT','RECEIPT.mat',struct('campaignId','FIX2','runName','run_fix','goSHA256','x','token','t'));
ex('hook_s4_refused','ledger',@()g2_lp2_admit_hook(lr2,Co,'FIX2','H',4),UN,'Only S5-S8');
ex('hook_s9_refused','ledger',@()g2_lp2_admit_hook(lr2,Co,'FIX2','H',9),UN,'Only S5-S8');
g2_lp2_admit_hook(lr2,Co,'FIX2','H',5);
ex('hook_duplicate_refused','ledger',@()g2_lp2_admit_hook(lr2,Co,'FIX2','H',5),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','already admitted');
ex('hook_closed_refused','ledger',@()g2_lp2_admit_hook(lr2,struct('mode','VERIFY_ONLY'),'FIX2','H',6),'G2LP1:HOLD_CAMPAIGN_CLOSED','closed');
% ---------------------------------------------------------------- forecast and recurrence
A0=fullfile(C.repo,strrep(pol.parents.run,'/',filesep));
p=struct('stateIndex',8,'polyline_mm',[0 0;0 1],'tangent',[0 1],'KI',1,'KII',0);
ex('forecast_s9_refused','forecast',@()g2_lp2_forecast(p,pol),UN,'outside the LP2 policy');
p.stateIndex=3;ex('forecast_s4_refused','forecast',@()g2_lp2_forecast(p,pol),UN,'outside the LP2 policy');
pt=pol;pt.caps.firstStateIndex=1;rep=true;
for i=1:4
 for k=1:4
  [Sa,~,~]=g2_trajectory_record('read',fullfile(A0,pol.cases(i).id,sprintf('S%d',k-1),'STATE.mat'));
  [Sb,~,~]=g2_trajectory_record('read',fullfile(A0,pol.cases(i).id,sprintf('S%d',k),'STATE.mat'));
  F=g2_lp2_forecast(Sa,pt);rep=rep&&isequal(F.polyline_mm,Sb.polyline_mm)&&isequal(F.tangent,Sb.tangent);
 end
end
ok('forecast_reproduces_A0_S1_S4_bitwise','forecast',@()rep);
man=jsondecode(fileread(fullfile(C.repo,strrep(pol.parents.manifest,'/',filesep))));pinOK=true;
for i=1:4,id=pol.cases(i).id;for f={'STATE','MESH','SOLUTION'},pinOK=pinOK&&strcmpi(man.(matlab.lang.makeValidName([id '/S4/' f{1} '.mat'])),pol.parents.(id).(f{1}));end,end
ok('parent_pins_equal_A0_manifest','forecast',@()pinOK);
% ---------------------------------------------------------------- classification (synthetic metrics)
[St,~,~]=g2_trajectory_record('read',fullfile(A0,'H','S4','STATE.mat'));F=g2_lp2_forecast(St,pol);
D4=load(fullfile(A0,'H','S4','MESH.mat'));O=g2_m4b_ring_owner_oracle(D4.X6,D4.T6,pol.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),struct('onCircleTol_mm',1e-9));
geo=struct('centres',pol.geometry.centres_mm,'ringPolygons',{cellfun(@(v)D4.X6(v,:),O.ringVertices,'UniformOutput',false)},'holePolygons',{cellfun(@(v)D4.X6(v,:),O.holeVertices,'UniformOutput',false)});
R0=g2_lp0_clearance(F.polyline_mm(1:end-1,:),F.polyline_mm(end,:),geo,pol);
cls=@(R,m)getfield(g2_lp2_classify(R,m,pol),'classification'); %#ok<GFLD>
ok('classify_S5_H_matrix_advance','classify',@()R0.pass&&strcmp(cls(R0,[0 0 0]),'MATRIX_ADVANCE'));
R1=R0;R1.pass=false;R1.reasons={'HOLD_TIP_GUIDE'};R1.metrics.guideRingMargin_mm(1)=-1;
ok('classify_active_ring_interface_approach','classify',@()strcmp(cls(R1,[1 0 1]),'INTERFACE_APPROACH'));
ok('classify_passive_ring_numerical_hold','classify',@()strcmp(cls(R1,[0 0 0]),'NUMERICAL_HOLD')&&strcmp(cls(R1,[0 1 0]),'NUMERICAL_HOLD'));
T1=g2_lp2_classify(R1,[0 0 0],pol);ok('classify_passive_ring_typed_numerical_ring','classify',@()strcmp(T1.constraints(1).type,'NUMERICAL_RING'));
R2=R1;R2.metrics.guideRingMargin_mm(2)=-1;T2=g2_lp2_classify(R2,[0 1 0],pol);
ok('classify_precedence_active_over_passive','classify',@()strcmp(T2.classification,'INTERFACE_APPROACH')&&any(strcmp({T2.constraints.type},'NUMERICAL_RING')));
R3=R0;R3.pass=false;R3.reasons={'HOLD_TIP_GUIDE'};R3.metrics.guidePlateMargin_mm(4)=-0.5;
ok('classify_external_boundary','classify',@()strcmp(cls(R3,[1 0 1]),'EXTERNAL_BOUNDARY_APPROACH'));
R4=R0;R4.pass=false;R4.reasons={'HOLD_INTERFACE_APPROACH'};R4.metrics.segmentToHolePolygon_mm(2)=0;
ok('classify_hole_boundary','classify',@()strcmp(cls(R4,[0 0 0]),'HOLE_BOUNDARY_APPROACH'));
R5=R0;R5.pass=false;R5.reasons={'HOLD_CRACK_SELF_INTERSECTION'};
ok('classify_self_intersection_numerical','classify',@()strcmp(cls(R5,[1 0 0]),'NUMERICAL_HOLD'));
R6=R0;R6.metrics.guideRingMargin_mm(1)=-1;
ex('classify_inconsistent_refused','classify',@()g2_lp2_classify(R6,[1 0 1],pol),'G2LP2:HOLD_CLASSIFICATION','inconsistent');
ok('classify_never_encounter','classify',@()isempty(strfind(fileread(fullfile(C.lp2,'g2_lp2_classify.m')),'classification=''INTERFACE_ENCOUNTER''')));
% ---------------------------------------------------------------- driver
ex('driver_unknown_case','driver',@()g2_lp2_run('Case','soft3'),'G2LP2:HOLD_INPUT','Exactly H');
src=fileread(fullfile(C.lp2,'g2_lp2_run.m'));a=strfind(src,'% ------------------------------------------------------------------ authorized path only');runPart=src(a:end);
pg=strfind(runPart,'g2_lp2_scientific_gate(C)');fo=@(s)min([strfind(runPart,s),inf]);
ok('driver_gate_first','driver',@()isscalar(pg)&&pg<fo('mkdir(')&&pg<fo('g2_lp1_campaign_ledger(''write''')&&pg<fo('g2_kinked_join(')&& ...
 pg<fo('g2_m4b_sif_partial(')&&pg<fo('g2_trajectory_record(''write''')&&pg<fo('g2_lp1_admit_state('));
dry=src(strfind(src,'if ~o.Run'):a);
ok('driver_dry_has_no_mesh_solve_write','driver',@()isempty(strfind(dry,'g2_kinked_join'))&&isempty(strfind(dry,'g2_m4b_sif_partial'))&& ...
 isempty(strfind(dry,'mkdir'))&&isempty(strfind(dry,'''write'''))&&~isempty(strfind(dry,'return')));
ok('driver_no_other_go','driver',@()isempty(strfind(src,'SCIENTIFIC_GO_v1'))&&isempty(strfind(src,'G2_A1_'))&&isempty(strfind(src,'G2_M5_X6')));
ok('driver_no_resume','driver',@()~isempty(strfind(src,'runFolderFacts(rd,C.token),[])')));
ok('driver_classification_before_admission','driver',@()fo('g2_lp2_classify(')<fo('g2_lp1_admit_state('));
ok('driver_unchanged_mesher_call','driver',@()~isempty(strfind(src,'''TipGuideRadius_mm'',15,''TipGuideHface_mm'',1.5},''MaxT3Elements'',40000')));
dr=cell(1,4);for i=1:4,dr{i}=g2_lp2_run('Case',pol.cases(i).id);end
ok('driver_dry_four_cases','driver',@()all(cellfun(@(d)strcmp(d.status,'DRY_READY_NO_FEM')&&d.computed==0&&strcmp(d.token,C.token)&& ...
 strcmp(d.S5.classification,'MATRIX_ADVANCE'),dr)));
% ---------------------------------------------------------------- analysis regression on A0 S0-S4
ch=struct();for i=1:4,id=pol.cases(i).id;ch.(id)=arrayfun(@(k)fullfile(A0,id,sprintf('S%d',k),'STATE.mat'),0:4,'UniformOutput',false);end
An=g2_lp2_analyze(ch,'');M5=jsondecode(fileread(fullfile(C.repo,'docs','research','G2_M5_evidence','M5_EXISTING_EVIDENCE.json')));
dd=0;fg=0;for c={'stiff13','soft2','soft1'},dd=max(dd,max(abs(An.(c{1}).d_mm-M5.lateralOffset_d_mm.(c{1}).')));fg=max(fg,abs(An.(c{1}).F_G(5)-M5.decompositionExisting.(c{1}).S4_total_B0));end
ok('analysis_reproduces_M5_offsets_and_F_G','analysis',@()dd<=1e-12&&fg<=1e-12);
ok('analysis_H1_H2_not_testable_on_S0_S4','analysis',@()strcmp(An.stiff13.H1.status,'NOT_TESTABLE')&&strcmp(An.soft2.H2.status,'NOT_TESTABLE')&&strcmp(An.H4.status,'NOT_TESTABLE'));
neg=rows(strcmp({rows.expected},'error'));
T=struct('schema','NewMetacomp.G2.LP2A.ContractTests.v1','pass',all([rows.pass]),'passed',nnz([rows.pass]),'total',numel(rows), ...
 'negativeTests',numel(neg),'negativeTestsPassed',all([neg.pass]),'physicalSolves',0,'token',C.token,'rows',rows, ...
 'analysisRegression',struct('max_d_error_mm',dd,'max_F_G_error',fg));
fprintf('LP2A_CONTRACT %d/%d (negatives %d)\n',T.passed,T.total,numel(neg));
for r=rows(~[rows.pass]),fprintf(2,'LP2A_CONTRACT_FAIL %s: %s\n',r.name,r.observed);end
 function ok(name,kind,f)
  try,v=isequal(f(),true);o=mat2str(v);catch ME,v=false;o=['error ' ME.identifier ': ' ME.message];end
  rows(end+1)=struct('name',name,'kind',kind,'expected','true','observed',o,'pass',v);
 end
 function ex(name,kind,f,id,frag)
  try,f();o='no error';v=false;catch ME,o=[ME.identifier ': ' ME.message];v=strcmp(ME.identifier,id)&&contains(ME.message,frag);end
  rows(end+1)=struct('name',name,'kind',kind,'expected','error','observed',o,'pass',v);
 end
 function gn(name,G,id,frag),ex(name,'go',@()g2_lp2_go_validate(G,Cs,ld(good)),id,frag);end
end
function s=setf(s,f,v)
s.(f)=v;
end
