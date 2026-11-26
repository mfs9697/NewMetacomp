function O=g2_lp2b1_wp1(stage,outRoot,varargin)
%G2_LP2B1_WP1  Preregistered geometry-only alternative-spacing qualification (zero FEM).
%  O = g2_lp2b1_wp1('target',outRoot)       candidates in the preregistered order on the fixed soft1 S10 target
%  O = g2_lp2b1_wp1('repeat',outRoot)       one geometry-only repeat of the selected spacing (determinism)
%  O = g2_lp2b1_wp1('references',outRoot)   the SAME selected spacing on soft1 S9 and H S10 only
% Requirements checked before any mesh: the preregistration G2_LP2B1_PREREG_v1.json is tracked and
% committed unchanged in the execution clone (git), it pins the pins file by SHA-256; LP2-A3 context
% (normal preflight, 5 GiB guard unchanged; policy, digests and 44 parent/WP5 pins); target and
% reference record hashes; outRoot outside every historical root. Stopping rule (target): the next
% candidate is generated ONLY if the previous one failed the join with failed gates contained in
% {globalMinAngleAtLeast20, globalNeighborRatioAtMost1p8}; any other failure is HOLD; the first
% candidate passing every gate is selected. 'repeat' and 'references' read the selection from the
% saved target attempt records (never from a physical result). A reference failure is a HOLD for
% scientific disposition; the selection is never changed afterwards. No solve, no GO, no state.
ip=inputParser;addParameter(ip,'Preflight',true,@islogical);parse(ip,varargin{:});
here=fileparts(mfilename('fullpath'));g2=fileparts(here);addpath(g2);addpath(fullfile(g2,'lp2'));addpath(fullfile(g2,'lp2a2'));addpath(fullfile(g2,'lp2a3'));
C=g2_lp2a3_context('Preflight',ip.Results.Preflight);repo=C.repo;pol=C.policy;
addpath(fullfile(g2,'vendor_p010_a14d8872'),'-begin');
pf=fullfile(here,'G2_LP2B1_PREREG_v1.json');pr=jsondecode(fileread(pf));pinsF=fullfile(here,'G2_LP2B1_PINS_v1.json');pins=jsondecode(fileread(pinsF));
assert(strcmp(pr.schema,'NewMetacomp.G2.LP2B1.Preregistration.v1')&&strcmpi(pr.pinsSHA256,g2_sha256_file(pinsF)),'G2LP2B1:HOLD_PREREG','Preregistration schema or pins SHA-256.');
[s1,~]=system(sprintf('git -C "%s" ls-files --error-unmatch matlab/g2/lp2b1/G2_LP2B1_PREREG_v1.json',repo));
[s2,~]=system(sprintf('git -C "%s" diff --quiet HEAD -- matlab/g2/lp2b1',repo));
assert(s1==0&&s2==0,'G2LP2B1:HOLD_PREREG','The preregistration and the LP2-B1 sources must be committed unchanged before any alternative mesh.');
assert(isequal(pr.candidateOrder_mm(:).',[0.40 0.50 0.35])&&pr.baseline.seedSpacing_mm==0.45&&strcmp(pr.baseline.source,'stored FAILED_MESH.mat (not regenerated)'), ...
 'G2LP2B1:HOLD_PREREG','Candidate order or baseline differ from the assignment.');
od=char(java.io.File(outRoot).getCanonicalPath());
for r={'g2_lp2a3_paths_v1','g2_lp2a3_campaign_ledger','g2_lp2a_paths_v1','g2_lp2a_campaign_ledger','g2_lp2a2_eq_v1','g2_lp1_matrix_paths_v1'}
 hr=char(java.io.File(fullfile(repo,'outputs',r{1})).getCanonicalPath());
 assert(~startsWith(lower(od),lower(hr)),'G2LP2B1:HOLD_HISTORICAL_ROOT','Refusing to write under a historical root: %s',r{1});
end
if ~isfolder(od),mkdir(od);end
rr=fullfile(repo,strrep(pins.lp2a3.runRoot,'/',filesep));fh=@(rel)lower(g2_sha256_file(fullfile(rr,strrep(rel,'/',filesep))));
tg=pins.target;
assert(strcmp(fh(tg.failedMesh.path),tg.failedMesh.sha256)&&strcmp(fh(tg.parentState.path),tg.parentState.sha256)&&strcmp(fh(tg.terminal.path),tg.terminal.sha256),'G2LP2B1:HOLD_SOURCE','Target record drift.');
refs=pins.references;if ~iscell(refs),refs=num2cell(refs);end
for i=1:2,rf=refs{i};for f={'STATE','MESH','PHASE','SOLUTION'},assert(strcmp(fh(rf.(f{1}).path),rf.(f{1}).sha256),'G2LP2B1:HOLD_SOURCE','Reference %s %s drift.',rf.id,f{1});end,end
[S9,~,ok]=g2_trajectory_record('read',fullfile(rr,'soft1','S9','STATE.mat'));assert(ok,'G2LP2B1:HOLD_SOURCE','S9 manifest.');
F=g2_lp2_forecast(S9,pol);Sf=load(fullfile(rr,'soft1','S10','FAILED_MESH.mat'));fm=Sf.failedMesh;
assert(isequal(F.polyline_mm,fm.crackPolyline),'G2LP2B1:HOLD_SOURCE','Target polyline differs from the stored failed mesh.');
baseT=struct('X3',fm.X3,'T3',fm.T3,'X6',fm.X6,'T6',fm.T6,'qActiveT6Rows',fm.qActiveT6Rows,'nodalQ',fm.nodalQ,'maxRatio',fm.summary.maxNeighborRatio,'minAngle',fm.summary.minAngle_deg);
O=struct('schema','NewMetacomp.G2.LP2B1.WP1.v1','stage',stage,'physicalSolves',0,'preregSHA256',lower(g2_sha256_file(pf)),'preflight',C.preflight,'attempts',{{}});
switch stage
 case 'target'
  O.selected=[];O.outcome='';
  for hs=pr.candidateOrder_mm(:).'
   nm=sprintf('T_soft1_S10_h%03d',round(100*hs));
   R=g2_lp2b1_attempt(nm,F.polyline_mm,F.tangent,10,hs,[1 0 0],S9.clearanceGeometry,baseT,od,C);O.attempts{end+1}=summ(R);
   if R.pass,O.selected=hs;O.outcome='SELECTED';break,end
   if ~R.qualityOnlyFailure,O.outcome='HOLD_NON_QUALITY_FAILURE';break,end
  end
  if isempty(O.outcome),O.outcome='HOLD_ALL_CANDIDATES_FAIL_QUALITY';end
 case 'repeat'
  hs=selectedFrom(od,pr);nm=sprintf('T_soft1_S10_h%03d_REPEAT',round(100*hs));
  R=g2_lp2b1_attempt(nm,F.polyline_mm,F.tangent,10,hs,[1 0 0],S9.clearanceGeometry,baseT,od,C);O.attempts{end+1}=summ(R);
  A1=load(fullfile(od,sprintf('T_soft1_S10_h%03d',round(100*hs)),'ATTEMPT_ARRAYS.mat'));A2=load(fullfile(od,nm,'ATTEMPT_ARRAYS.mat'));
  J1=jsondecode(fileread(fullfile(od,sprintf('T_soft1_S10_h%03d',round(100*hs)),'ATTEMPT.json')));
  f={'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows','elementRows','crackPolyline','extraVertexXY','physicalTipNode'};
  eq=struct();for i=1:numel(f),eq.(f{i})=isequal(A1.(f{i}),A2.(f{i}));end
  O.determinism=struct('arraysEqual',eq,'canonicalSHA256',{{J1.canonicalSHA256,R.canonicalSHA256}},'canonicalEqual',strcmp(J1.canonicalSHA256,R.canonicalSHA256), ...
   'gatesEqual',isequal(A1.gates,A2.gates),'repeatPass',R.pass);
  O.outcome='DETERMINISTIC';if ~(all(cell2mat(struct2cell(eq)))&&O.determinism.canonicalEqual&&O.determinism.gatesEqual&&R.pass),O.outcome='HOLD_NOT_DETERMINISTIC';end
 case 'references'
  hs=selectedFrom(od,pr);O.selected=hs;Par=g2_lp2a3_parent(C,'soft1');
  [H9,~,okh]=g2_trajectory_record('read',fullfile(rr,'H','S9','STATE.mat'));assert(okh,'G2LP2B1:HOLD_SOURCE','H S9 manifest.');
  refs={'soft1_S9','soft1','S9',9,[1 0 0],Par.geom;'H_S10','H','S10',10,[0 0 0],H9.clearanceGeometry};O.outcome='REFERENCES_PASS';
  for i=1:2
   [St,~,okr]=g2_trajectory_record('read',fullfile(rr,refs{i,2},refs{i,3},'STATE.mat'));assert(okr,'G2LP2B1:HOLD_SOURCE','Reference STATE manifest.');
   Bm=load(fullfile(rr,refs{i,2},refs{i,3},'MESH.mat'));
   base=struct('X3',Bm.X3,'T3',Bm.T3,'X6',Bm.X6,'T6',Bm.T6,'qActiveT6Rows',Bm.qActiveT6Rows,'nodalQ',Bm.nodalQ,'maxRatio',Bm.summary.maxNeighborRatio,'minAngle',Bm.summary.minAngle_deg);
   assert(isequal(St.polyline_mm,Bm.crackPolyline),'G2LP2B1:HOLD_SOURCE','Reference polyline differs from its MESH.');
   nm=sprintf('R_%s_h%03d',refs{i,1},round(100*hs));
   R=g2_lp2b1_attempt(nm,St.polyline_mm,St.tangent,refs{i,4},hs,refs{i,5},refs{i,6},base,od,C);s=summ(R);
   s.originalAcceptedMesh=struct('T3',size(Bm.T3,1),'maxRatio',Bm.summary.maxNeighborRatio,'minAngle_deg',Bm.summary.minAngle_deg,'seedSpacing_mm',St.seedSpacing_mm);
   O.attempts{end+1}=s;
   if ~R.pass,O.outcome='HOLD_REFERENCE_FAILURE';break,end
  end
 otherwise
  error('G2LP2B1:HOLD_INPUT','Unknown stage %s.',stage);
end
fn=fullfile(od,sprintf('LP2B1_WP1_%s.json',upper(stage)));assert(~isfile(fn),'G2LP2B1:HOLD_OVERWRITE','Stage record exists: %s',fn);
fid=fopen(fn,'w');fwrite(fid,jsonencode(O,'PrettyPrint',true),'char');fclose(fid);
fprintf('G2_LP2B1_WP1 %s outcome=%s\n',stage,O.outcome);
end

function hs=selectedFrom(od,pr)
J=jsondecode(fileread(fullfile(od,'LP2B1_WP1_TARGET.json')));
assert(strcmp(J.outcome,'SELECTED')&&any(abs(J.selected-pr.candidateOrder_mm)<1e-12),'G2LP2B1:HOLD_NO_SELECTION','No spacing was selected on the target.');
hs=J.selected;
end
function s=summ(R)
s=struct('name',R.name,'seedSpacing_mm',R.seedSpacing_mm,'stage',R.stage,'failedGates',{R.failedGates},'joinGates',sprintf('%d/%d',R.joinGatesPassed,R.joinGatesTotal), ...
 'qualityOnlyFailure',R.qualityOnlyFailure,'pass',R.pass,'checks',sprintf('%d/%d',getf(R,'checksPassed'),getf(R,'checksTotal')));
for f={'T3','canonicalSHA256','arraysFileSHA256'},if isfield(R,f{1}),s.(f{1})=R.(f{1});end,end
if isfield(R,'independent'),s.maxNeighborRatio=R.independent.maxNeighborRatio;s.minAngle_deg=R.independent.minAngle_deg;s.violations=R.independent.violations;end
end
function v=getf(s,f)
if isfield(s,f),v=s.(f);else,v=0;end
end
