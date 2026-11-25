function C=g2_lp2a2_eq_context(varargin)
%G2_LP2A2_EQ_CONTEXT  Read-only context of the PREPARED (not authorized) LP2-A2 SIF-equivalence
% campaign: policy, pinned digests, archived LP2-A1 S8 records and the token. No mesh, no FEM, no
% write. Fails closed with G2LP2A2:HOLD_SOURCE on any drift.
%  shared g2 digest   every top-level matlab/g2/*.m + p010 vendor (identical rule to LP2)
%  LP2 digest         matlab/g2/lp2/*.m (the archived records were produced under it)
%  LP2-A2 digest      matlab/g2/lp2a2/*.m (this campaign's sources)
ip=inputParser;addParameter(ip,'Preflight',true,@islogical);parse(ip,varargin{:});o=ip.Results;
lp2a2=fileparts(mfilename('fullpath'));here=fileparts(lp2a2);repo=fileparts(fileparts(here));addpath(here);
P=struct('pass',true,'status','SKIPPED');
if o.Preflight
 P=g2_lp0_preflight();assert(P.pass,'G2LP2A2:Preflight','%s: %s (RAM %.6f GiB)',P.status,P.cause,P.freePhysicalRAM_GiB);
end
pf=fullfile(lp2a2,'G2_LP2A2_EQ_POLICY_v1.json');pol=jsondecode(fileread(pf));ps=lower(g2_sha256_file(pf));pin=pol.pins;
chk=@(f,h,what)assert(strcmpi(g2_sha256_file(f),h),'G2LP2A2:HOLD_SOURCE','%s drift.',what);
chk(fullfile(here,'G2_LP1_POLICY_v2.json'),pin.lp1PolicySHA256,'LP1 policy v2');
chk(fullfile(here,'lp2','G2_LP2A_POLICY_v1.json'),pin.lp2PolicySHA256,'LP2 policy');
chk(fullfile(repo,'docs','research','G2_LP2A2_evidence','LP2A2_TEST_SET.json'),pin.testSetSHA256,'LP2-A2 test set');
fs=[dir(fullfile(here,'*.m'));dir(fullfile(here,'vendor_p010_a14d8872','*.m'))];
rel=cell(numel(fs),1);for k=1:numel(fs),rel{k}=strrep(strrep(fullfile(fs(k).folder,fs(k).name),[here filesep],''),filesep,'/');end
[rel,ix]=sort(rel);fs=fs(ix);gl=cell(numel(fs),1);
for k=1:numel(fs),gl{k}=[rel{k},' ',lower(g2_sha256_file(fullfile(fs(k).folder,fs(k).name)))];end
gsrc=g2_lp1_digest(strjoin(gl,newline));
assert(strcmpi(gsrc,pin.g2SourceSHA256),'G2LP2A2:HOLD_SOURCE','Shared matlab/g2 sources differ from the pinned digest.');
lsrc=folderDigest(fullfile(here,'lp2'));
assert(strcmpi(lsrc,pin.lp2SourceSHA256),'G2LP2A2:HOLD_SOURCE','LP2 sources differ from the pinned digest.');
asrc=folderDigest(lp2a2);
assert(strcmpi(asrc,pin.lp2a2SourceSHA256),'G2LP2A2:HOLD_SOURCE','LP2-A2 sources differ from the pinned digest (%s).',asrc);
base=fullfile(repo,'outputs','g2_lp2a_paths_v1','run_lp2a_s5_s8_v1');ids={pol.solves.caseId};al=cell(4,1);
for k=1:4
 a=pin.archivedS8.(ids{k});
 for f={'STATE','MESH','PHASE','SOLUTION'},chk(fullfile(base,ids{k},'S8',[f{1} '.mat']),a.(f{1}),sprintf('Archived %s S8 %s',ids{k},f{1}));end
 chk(fullfile(base,ids{k},'TERMINAL.mat'),a.TERMINAL,sprintf('Archived %s TERMINAL',ids{k}));
 al{k}=[ids{k},' ',a.STATE,' ',a.MESH,' ',a.PHASE,' ',a.SOLUTION,' ',a.TERMINAL];
end
aman=g2_lp1_digest(strjoin(al,newline));
tok=sprintf('G2LP2A2EQ|policy=%s|g2source=%s|lp2source=%s|lp2a2source=%s|archivedS8=%s|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1|limit=4', ...
 ps,gsrc,lsrc,asrc,aman);
C=struct('repo',repo,'here',here,'lp2a2',lp2a2,'policy',pol,'policySHA256',ps,'g2SourceSHA256',gsrc,'lp2SourceSHA256',lsrc, ...
 'lp2a2SourceSHA256',asrc,'archivedManifestSHA256',aman,'token',tok,'archiveBase',base,'preflight',P);
end

function d=folderDigest(f)
fl=dir(fullfile(f,'*.m'));nl=sort({fl.name});ll=cell(numel(nl),1);
for k=1:numel(nl),ll{k}=[nl{k},' ',lower(g2_sha256_file(fullfile(f,nl{k})))];end
d=g2_lp1_digest(strjoin(ll,newline));
end
