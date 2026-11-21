function R = g2_m4a_s0alt(varargin)
%G2_M4A_S0ALT  Alternative-family State 0 mesh for G2-M4.A (Issue #44), build or verify.
%
%  R = g2_m4a_s0alt('Mode','build')                     dry: build + audit in memory, writes nothing
%  R = g2_m4a_s0alt('Mode','build','Run',true,'AuthToken',tok)   writes S0ALT/ once
%  R = g2_m4a_s0alt('Mode','verify','Reaudit',tf)        read-only verification for the chains
% G2_M4_POLICY_v1.json, altFamily. The mesh is g2_join_protected_mesh with the policy's
% exteriorOptions (the exact WP2 routine; GuideHface 1.0, Hmax 5). Gates on the SAVED arrays:
% join 13/13, g2_independent_t6_checker 38/38, g2_protected_tip_checker 24/24, S0 schema
% adapter, PR #38 phase stage (mapper, verifier, state-aware negatives). Token
% G2M4AS0|<policy SHA>|family=famB_m4alt. Folder outputs/g2_m4_alt_family_v1/S0ALT (or
% 'S0Dir' below that root whose name contains S0ALT). Never overwritten.
ip=inputParser;
addParameter(ip,'Mode','build',@(s)any(strcmpi(s,{'build','verify'})));
addParameter(ip,'Run',false,@islogical);
addParameter(ip,'AuthToken','',@(s)ischar(s)||isstring(s));
addParameter(ip,'S0Dir','',@(s)ischar(s)||isstring(s));
addParameter(ip,'Reaudit',true,@islogical);
parse(ip,varargin{:});o=ip.Results;
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
addpath(fullfile(here,'vendor_p010_a14d8872'),'-begin');
polFile=fullfile(here,'G2_M4_POLICY_v1.json');pol=jsondecode(fileread(polFile));polSHA=g2_sha256_file(polFile);
polM=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
p0=fullfile(repo,'outputs','g2_p010_isolated','run_20261118_163657_790','P010_ISOLATED_REGULAR_ONLY.mat');
assert(strcmpi(g2_sha256_file(json),pol.base.cornellJSON_SHA256)&&strcmpi(g2_sha256_file(p0),pol.base.trustedP0SHA256), ...
 'G2M4S0:PolicyHash','Cornell JSON or trusted P0 hash differs from the M4 policy.');
opts=local_opts(pol.altFamily.exteriorOptions);
root=fullfile(repo,'outputs','g2_m4_alt_family_v1');
d=char(o.S0Dir);if isempty(d),d=fullfile(root,'S0ALT');end
d=local_abs(d);[~,dn]=fileparts(d);
assert(local_inside(d,local_abs(root))&&contains(dn,'S0ALT'),'G2M4S0:Location','S0ALT folder must lie below %s and be named *S0ALT*.',root);
R=struct('pass',false,'stage','HOLD_NOT_STARTED','policySHA256',polSHA,'s0Dir',strrep(d,repo,'<repo>'),'message','');
P0=reshape(pol.start.polyline_mm,[],2);if ~isequal(size(P0),[2 2]),P0=reshape(pol.start.polyline_mm.',[],2);end
meshFile=fullfile(d,'GEOMETRY_ONLY_candidate.mat');recFile=fullfile(d,'S0ALT.mat');
if strcmpi(o.Mode,'verify')
 [Rec,recHash,ok]=g2_trajectory_record('read',recFile);
 assert(ok,'G2M4S0:RecordIntegrity','S0ALT record integrity.');
 assert(strcmpi(Rec.policySHA256,polSHA)&&isequal(Rec.exteriorOptions,opts),'G2M4S0:RecordDrift','S0ALT record policy/options drift.');
 assert(isfile(meshFile)&&strcmpi(g2_sha256_file(meshFile),Rec.meshSHA256),'G2M4S0:MeshHash','S0ALT mesh hash differs from its record.');
 D=load(meshFile);
 assert(strcmp(D.familyTag,pol.altFamily.id)&&size(D.T3,1)==Rec.T3,'G2M4S0:MeshContent','S0ALT mesh is not the recorded alternative family.');
 [Dm,Ad]=g2_m2_state_adapter(D,'S0',P0);assert(Ad.pass,'G2M4S0:Adapter','S0ALT adapter: %s',strjoin(Ad.failed,','));
 R.record=Rec;R.recordSHA256=recHash;R.D=D;R.Dm=Dm;R.meshSHA256=Rec.meshSHA256;
 if o.Reaudit
  A=local_audit(D,Dm,json,p0,polM,P0);
  assert(A.pass&&isequal(A.PM.phase,Rec.phase)&&isequal(A.PM.annulusOf,Rec.annulusOf),'G2M4S0:Reaudit','S0ALT re-audit or phase re-map differs from the record.');
  R.PM=A.PM;R.audit=A.summary;
 else
  R.PM=struct('pass',true,'phase',Rec.phase,'annulusOf',Rec.annulusOf,'interfaces',Rec.interfaces);
 end
 R.pass=true;R.stage='S0ALT_VERIFIED';return
end
% ---------------- build
if o.Run
 expect=sprintf('G2M4AS0|%s|family=%s',upper(polSHA),pol.altFamily.id);
 assert(strcmp(char(o.AuthToken),expect),'G2M4S0:Authorization','S0ALT token does not bind this policy SHA and family.');
 [head,dirty]=local_git(repo);assert(~isempty(head)&&isempty(dirty),'G2M4S0:DirtySource','Uncommitted or untracked sources:\n%s',dirty);
 assert(~isfile(recFile)&&~isfile(meshFile),'G2M4S0:Exists','S0ALT already exists; never overwritten.');
end
B=g2_join_protected_mesh('ExteriorOptions',opts,'MaxT3Elements',pol.mesh.T3max);
assert(B.pass,'G2M4S0:Join','HOLD_ALT_S0: join %s',strjoin(B.failedGates,','));
X3=B.X3;T3=B.T3;X6=B.X6;T6=B.T6;upperBankT6=B.upperBankT6;lowerBankT6=B.lowerBankT6;physicalTipNode=B.physicalTipNode; %#ok<NASGU>
nodalQ=B.nodalQ;qActiveT6Rows=B.qActiveT6Rows;elementRows=B.elementRows;collarOuterIDs=B.collarOuterIDs;summary=B.summary;gates=B.gates; %#ok<NASGU>
extraVertexXY=B.extraVertexXY;extraVertexNodes=B.extraVertexNodes;includeHoles=B.includeHoles;plateXRange=B.plateXRange; %#ok<NASGU>
geometryOnly=true;approvedForLEFM=false;p010GlobalProtectedMeshQualified=false;familyTag=pol.altFamily.id; %#ok<NASGU>
vars={'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','qActiveT6Rows','elementRows','collarOuterIDs', ...
 'summary','gates','geometryOnly','approvedForLEFM','p010GlobalProtectedMeshQualified','extraVertexXY','extraVertexNodes','includeHoles','plateXRange','familyTag'};
if o.Run
 if ~isfolder(d),mkdir(d);end
 save(meshFile,vars{:},'-v7.3');D=load(meshFile);meshHash=g2_sha256_file(meshFile);
else
 D=struct();for k=1:numel(vars),D.(vars{k})=eval(vars{k});end;meshHash='';
end
[Dm,Ad]=g2_m2_state_adapter(D,'S0',P0);assert(Ad.pass,'G2M4S0:Adapter','HOLD_ALT_S0: adapter %s',strjoin(Ad.failed,','));
A=local_audit(D,Dm,json,p0,polM,P0);
assert(A.pass,'G2M4S0:Audit','HOLD_ALT_S0: %s',jsonencode(A.summary));
joinG=sprintf('%d/%d',nnz(cell2mat(struct2cell(B.gates))),numel(fieldnames(B.gates)));
R.summary=struct('T3',size(D.T3,1),'join',joinG,'audits',A.summary,'geometry',A.geom);
fprintf('G2_M4_S0ALT T3 %d join %s 38-gate %s protected %s chords %s band area %s phase OK\n',size(D.T3,1),joinG,A.summary.independent38, ...
 A.summary.protectedTip,mat2str(A.geom.chordsPerCircle(:).'),mat2str(A.geom.annulusArea_mm2(:).',10));
if ~o.Run
 R.pass=true;R.stage='DRY_S0ALT_NO_FILES';fprintf('G2_M4_S0ALT_DRY NO_FILES=1\n');return
end
[head,~]=local_git(repo);
Rec=struct('schema','NewMetacomp.G2.M4.S0Alt.v1','family',pol.altFamily.id,'policySHA256',polSHA,'exteriorOptions',{opts}, ...
 'sourceHashes',g2_m4a_sources(here),'gitHead',head,'meshFile','GEOMETRY_ONLY_candidate.mat','meshSHA256',meshHash,'T3',size(D.T3,1), ...
 'join',joinG,'joinGates',B.gates,'audits',A.summary,'adapterChecks',Ad.checks,'phase',A.PM.phase,'annulusOf',A.PM.annulusOf, ...
 'interfaces',A.PM.interfaces,'verifierValues',A.V.values,'negatives',struct('pass',A.NC.pass),'geometry',A.geom, ...
 'created',datestr(now,31),'physicalFractureGrowthProven',false);
R.recordSHA256=g2_trajectory_record('write',recFile,Rec);R.meshSHA256=meshHash;
R.pass=true;R.stage='S0ALT_WRITTEN';
fprintf('G2_M4_S0ALT_WRITTEN mesh %s record %s\n',lower(meshHash),lower(R.recordSHA256));
end

% =====================================================================
function A=local_audit(D,Dm,json,p0,polM,P0)
C38=g2_independent_t6_checker(D,json);CP=g2_protected_tip_checker(D,json,p0);
[PM,V,NC,geom]=g2_material_phase_stage(Dm,polM,P0);
A=struct('pass',C38.pass&&C38.gatesPassed==38&&C38.gatesTotal==38&&CP.pass&&CP.gatesPassed==CP.gatesTotal&&CP.gatesTotal==24&& ...
 PM.pass&&V.pass&&NC.pass&&size(D.T3,1)<=40000, ...
 'summary',struct('independent38',sprintf('%d/%d',C38.gatesPassed,C38.gatesTotal),'protectedTip',sprintf('%d/%d',CP.gatesPassed,CP.gatesTotal), ...
 'phaseMap',PM.pass,'phaseVerifier',V.pass,'phaseNegatives',NC.pass),'PM',PM,'V',V,'NC',NC,'geom',geom);
end

function o=local_opts(x)
if iscell(x),o=x(:).';else,o=num2cell(x(:).');end
for k=1:numel(o)
 if isnumeric(o{k}),o{k}=reshape(o{k},1,[]);end
end
end

function [head,dirty]=local_git(repo)
head='';dirty='git unavailable';
[s1,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
[s2,d]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all -- matlab/g2 docs/research/crack-growth-gaps-2026',repo));
if s1==0&&s2==0,head=strtrim(h);dirty=strtrim(d);end
end

function p=local_abs(p)
p=char(p);if ~java.io.File(p).isAbsolute(),p=fullfile(pwd,p);end
p=char(java.io.File(p).getCanonicalPath());
end

function tf=local_inside(a,b)
a=lower(strrep(a,'/','\'));b=lower(strrep(b,'/','\'));
if ~endsWith(b,'\'),b=[b,'\'];end
tf=startsWith([a,'\'],b)&&~strcmp([a,'\'],b);
end
