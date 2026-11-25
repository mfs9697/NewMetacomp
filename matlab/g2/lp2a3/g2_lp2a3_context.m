function C=g2_lp2a3_context(varargin)
%G2_LP2A3_CONTEXT  Read-only LP2-A3 context: preflight, policy, source digests, S8 parent and WP5
% qualification manifests, token. No mesh, FEM, folder or record. Fails closed with G2LP2A3:HOLD_SOURCE.
%  C = g2_lp2a3_context()                      normal preflight (g2_lp0_preflight, 5 GiB guard unchanged)
%  C = g2_lp2a3_context('Preflight',false)     read-only replay / tests (never for a physical call)
% Digests (g2_lp1_digest of sorted lines): g2 = matlab/g2/*.m + vendor p010 (relative paths);
% lp2, lp2a2, lp2a3 = "name sha256" of the folder *.m. All must equal the policy pins (lp2a3 pinned
% in the policy, which is itself hashed into the token). The policy must repeat the LP2-A geometry,
% q domains, BVP and cases exactly. Every S8 parent file (STATE, MESH, PHASE, SOLUTION, TERMINAL) and
% every WP5 qualification record/evidence file must equal its pin.
ip=inputParser;addParameter(ip,'Preflight',true,@islogical);parse(ip,varargin{:});
a3=fileparts(mfilename('fullpath'));here=fileparts(a3);repo=fileparts(fileparts(here));addpath(here);
SRC='G2LP2A3:HOLD_SOURCE';
if ip.Results.Preflight
 Pf=g2_lp0_preflight();assert(Pf.pass,'G2LP2A3:Preflight','%s: %s (RAM %.6f GiB)',Pf.status,Pf.cause,Pf.freePhysicalRAM_GiB);
else
 Pf=struct('pass',false,'status','SKIPPED_READ_ONLY','sourceCommit','','matlabProcesses',NaN);
end
pf=fullfile(a3,'G2_LP2A3_POLICY_v1.json');pol=jsondecode(fileread(pf));ps=lower(g2_sha256_file(pf));
assert(strcmp(pol.schema,'NewMetacomp.G2.LP2A3.Policy.v1'),SRC,'Policy schema.');
fh=@(rel)lower(g2_sha256_file(fullfile(repo,strrep(rel,'/',filesep))));
assert(strcmp(fh(pol.lp1PolicyFile),pol.lp1PolicySHA256)&&strcmp(fh(pol.lp2PolicyFile),pol.lp2PolicySHA256)&&strcmp(fh(pol.lp2a2PolicyFile),pol.lp2a2PolicySHA256), ...
 SRC,'LP1, LP2-A or LP2-A2 policy drift.');
l2=jsondecode(fileread(fullfile(here,'lp2','G2_LP2A_POLICY_v1.json')));
assert(isequal(pol.geometry,l2.geometry)&&isequal(pol.qAnnuli_mm,l2.qAnnuli_mm)&&isequal(pol.bvp,l2.bvp)&&isequal(pol.startPolyline_mm,l2.startPolyline_mm)&& ...
 isequal({pol.cases.id},{l2.cases.id})&&isequal([pol.cases.ratio],[l2.cases.ratio])&&isequal([pol.cases.mask],[l2.cases.mask]), ...
 SRC,'LP2-A3 policy does not repeat the LP2-A geometry, q domains, BVP and cases exactly.');
c=pol.caps;
assert(c.firstStateIndex==9&&c.maxStateIndex==11&&c.statesPerCaseMax==3&&c.maxAdmissions==12&&c.increment_mm==4&&c.initialArc_mm==25.4&& ...
 ~c.adaptiveStep&&abs(c.maxArcLength_mm-(c.initialArc_mm+4*c.maxStateIndex))<1e-12&&pol.meshFamily.seedSpacing_mm==0.45&& ...
 pol.ringProximityGuard.minGap_mm==1&&pol.ringProximityGuard.guideRadius_mm==15,SRC,'LP2-A3 caps, seed spacing or guard differ from the preregistered values.');
% ---- source digests
fs=[dir(fullfile(here,'*.m'));dir(fullfile(here,'vendor_p010_a14d8872','*.m'))];
rel=cell(numel(fs),1);for k=1:numel(fs),rel{k}=strrep(strrep(fullfile(fs(k).folder,fs(k).name),[here filesep],''),filesep,'/');end
[rel,ix]=sort(rel);fs=fs(ix);gl=cell(numel(fs),1);
for k=1:numel(fs),gl{k}=[rel{k},' ',lower(g2_sha256_file(fullfile(fs(k).folder,fs(k).name)))];end
gsrc=g2_lp1_digest(strjoin(gl,newline));
[lp2src,~]=folderDigest(fullfile(here,'lp2'));[a2src,~]=folderDigest(fullfile(here,'lp2a2'));[a3src,a3lines]=folderDigest(a3);
sp=pol.sourcePins;
assert(strcmpi(gsrc,sp.g2SourceSHA256),SRC,'Shared matlab/g2 sources differ from the pinned digest.');
assert(strcmpi(lp2src,sp.lp2SourceSHA256),SRC,'matlab/g2/lp2 sources differ from the pinned digest.');
assert(strcmpi(a2src,sp.lp2a2SourceSHA256),SRC,'matlab/g2/lp2a2 sources differ from the pinned digest.');
assert(strcmpi(a3src,sp.lp2a3SourceSHA256),SRC,'matlab/g2/lp2a3 sources differ from the pinned digest.');
% ---- S8 parents (20 files) and WP5 qualification evidence
ids={pol.cases.id};pl=cell(4,1);
for k=1:4
 p=pol.parents.S8.(ids{k});d=fullfile(repo,strrep(pol.parents.run,'/',filesep),ids{k});
 for f={'STATE','MESH','PHASE','SOLUTION'},assert(strcmpi(g2_sha256_file(fullfile(d,'S8',[f{1} '.mat'])),p.(f{1})),SRC,'S8 %s of %s differs from its pin.',f{1},ids{k});end
 assert(strcmpi(g2_sha256_file(fullfile(d,'TERMINAL.mat')),p.TERMINAL),SRC,'TERMINAL of %s differs from its pin.',ids{k});
 pl{k}=sprintf('%s %s %s %s %s %s',ids{k},p.STATE,p.MESH,p.PHASE,p.SOLUTION,p.TERMINAL);
end
pman=g2_lp1_digest(strjoin(pl,newline));
q=pol.qualificationEvidence;ql={};
for r=[q.records(:);q.evidenceFiles(:)].'
 assert(strcmpi(fh(r.path),r.sha256),SRC,'WP5 qualification file %s differs from its pin.',r.path);ql{end+1}=[r.path ' ' r.sha256]; %#ok<AGROW>
end
assert(numel(q.records)==24,SRC,'Exactly 24 WP5 record files must be pinned.');
ql{end+1}=['archive ' q.archiveSHA256];qman=g2_lp1_digest(strjoin(sort(ql),newline));
au=pol.authorization;
tok=sprintf('G2LP2A3|policy=%s|g2source=%s|lp2source=%s|lp2a2source=%s|lp2a3source=%s|parentsS8=%s|qualification=%s|cases=H,stiff13,soft2,soft1|states=S9-S11|maxAdmissions=12|seed=0.45|campaign=%s|run=%s', ...
 ps,gsrc,lp2src,a2src,a3src,pman,qman,au.campaignId,au.runName);
C=struct('repo',repo,'here',here,'a3',a3,'policy',pol,'policySHA256',ps,'lp2Policy',l2,'g2SourceSHA256',gsrc,'lp2SourceSHA256',lp2src, ...
 'lp2a2SourceSHA256',a2src,'lp2a3SourceSHA256',a3src,'lp2a3SourceLines',{a3lines},'parentManifestSHA256',pman,'qualificationManifestSHA256',qman, ...
 'token',tok,'preflight',Pf,'runRoot',fullfile(repo,strrep(au.runRoot,'/',filesep)),'ledgerRoot',fullfile(repo,strrep(au.ledgerRoot,'/',filesep)), ...
 'goFile',fullfile(repo,strrep(au.goPath,'/',filesep)));
end

function [h,lines]=folderDigest(d)
fl=dir(fullfile(d,'*.m'));nl=sort({fl.name});lines=cell(numel(nl),1);
for k=1:numel(nl),lines{k}=[nl{k},' ',lower(g2_sha256_file(fullfile(d,nl{k})))];end
h=g2_lp1_digest(strjoin(lines,newline));
end
