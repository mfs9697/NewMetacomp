function C=g2_lp2b1s10_context(varargin)
%G2_LP2B1S10_CONTEXT  Read-only context of the PROSPECTIVE campaign G2-LP2B1-S10-001 (one soft1 S10 admission and
% solve at 0.40 mm). No mesh, FEM, folder or record. Fails closed with G2LP2B1S10:HOLD_SOURCE.
%  C = g2_lp2b1s10_context()                    normal preflight (g2_lp0_preflight; inherited 5 GiB guard unchanged)
%  C = g2_lp2b1s10_context('Preflight',false)   read-only replay and zero-FEM tests only (never a physical call)
% Checks: LP2-A3 context (its policy, g2/lp2/lp2a2/lp2a3 digests, S8 parents); this policy repeats the LP2-A3 geometry,
% q annuli, BVP, resources, ring guard and mesh options exactly; policy files; lp2b1, lp2b1eq, closure and lp2b1s10
% source digests; every parent, failed-S10, qualification and LP2-B1-EQ evidence file against its pin.
% The token binds the policy, all eight source digests, the parent/failed-S10 manifest, the qualification manifest
% and the LP2-B1-EQ campaign evidence manifest.
ip=inputParser;addParameter(ip,'Preflight',true,@islogical);parse(ip,varargin{:});
md=fileparts(mfilename('fullpath'));here=fileparts(md);repo=fileparts(fileparts(here));
for f={'','lp2','lp2a2','lp2a3','lp2b1','lp2b1eq'},addpath(fullfile(here,f{1}));end
addpath(fullfile(repo,'scripts','g2','lp2a2','closure'));addpath(md);
SRC='G2LP2B1S10:HOLD_SOURCE';
if ip.Results.Preflight
 Pf=g2_lp0_preflight();assert(Pf.pass,'G2LP2B1S10:Preflight','%s: %s (RAM %.6f GiB)',Pf.status,Pf.cause,Pf.freePhysicalRAM_GiB);
else
 Pf=struct('pass',false,'status','SKIPPED_READ_ONLY','sourceCommit','','matlabProcesses',NaN);
end
pf=fullfile(md,'G2_LP2B1S10_POLICY_v1.json');pol=jsondecode(fileread(pf));ps=lower(g2_sha256_file(pf));
assert(strcmp(pol.schema,'NewMetacomp.G2.LP2B1S10.Policy.v1')&&strcmp(pol.status,'PROPOSED_NOT_AUTHORIZED'),SRC,'Policy schema or status.');
fh=@(rel)lower(g2_sha256_file(fullfile(repo,strrep(rel,'/',filesep))));
pchk=@(p,what)assert(isfile(fullfile(repo,strrep(p.path,'/',filesep)))&&strcmp(fh(p.path),p.sha256),SRC,'%s differs from its pin (%s).',what,p.path);
for f=fieldnames(pol.policyPins).',pchk(pol.policyPins.(f{1}),['policy ' f{1}]);end
% ---- LP2-A3 context (verifies its own policy, four digests, S8 parents)
C3=g2_lp2a3_context('Preflight',false);a3=C3.policy;sp=pol.sourcePins;
assert(strcmp(C3.policySHA256,pol.policyPins.lp2a3.sha256),SRC,'LP2-A3 policy.');
assert(strcmpi(C3.g2SourceSHA256,sp.g2SourceSHA256)&&strcmpi(C3.lp2SourceSHA256,sp.lp2SourceSHA256)&& ...
 strcmpi(C3.lp2a2SourceSHA256,sp.lp2a2SourceSHA256)&&strcmpi(C3.lp2a3SourceSHA256,sp.lp2a3SourceSHA256),SRC,'Inherited source digests differ from the LP2-A3 pins.');
[b1src,~]=folderDigest(fullfile(here,'lp2b1'));[eqsrc,~]=folderDigest(fullfile(here,'lp2b1eq'));[clsrc,~]=folderDigest(fullfile(repo,'scripts','g2','lp2a2','closure'));
[s10src,s10lines]=folderDigest(md);
assert(strcmpi(b1src,sp.lp2b1SourceSHA256),SRC,'matlab/g2/lp2b1 sources differ from the pinned digest.');
assert(strcmpi(eqsrc,sp.lp2b1eqSourceSHA256),SRC,'matlab/g2/lp2b1eq sources differ from the pinned digest.');
assert(strcmpi(clsrc,sp.closureSourceSHA256),SRC,'WP5 closure verifier sources differ from the pinned digest.');
assert(strcmpi(s10src,sp.lp2b1s10SourceSHA256),SRC,'matlab/g2/lp2b1s10 sources differ from the pinned digest (%s).',s10src);
assert(isequal(pol.geometry,a3.geometry)&&isequal(pol.qAnnuli_mm,a3.qAnnuli_mm)&&isequal(pol.bvp,a3.bvp)&&isequal(pol.resources,a3.resources)&& ...
 isequal(pol.ringProximityGuard,a3.ringProximityGuard)&&isequal(pol.meshFamily.ExteriorOptions,a3.meshFamily.ExteriorOptions)&&pol.meshFamily.seedSpacing_mm==0.40, ...
 SRC,'Geometry, q annuli, BVP, resources, guard or mesh options differ from LP2-A3.');
tg=pol.target;
assert(strcmp(tg.caseId,'soft1')&&tg.stateIndex==10&&isequal(reshape(tg.mask,1,3),[1 0 0])&&tg.ratio==0.5&&tg.increment_mm==4&&tg.arc_mm==65.4&& ...
 tg.admissions==1&&tg.physicalSolves==1&&tg.attempts==1&&~tg.retry&&~tg.resumption&&~tg.fallback&&~tg.adaptiveStep,SRC,'Target, limits or stop rules differ from the assignment.');
c3=a3.cases(strcmp({a3.cases.id},'soft1'));assert(isequal(reshape(c3.mask,1,3),[1 0 0])&&c3.ratio==0.5,SRC,'soft1 case differs from LP2-A3.');
% ---- parent, failed S10, qualification and LP2-B1-EQ evidence files
p=pol.parent;fa=pol.failedA3S10;q=pol.qualification;e=pol.b1eqEvidence;
pl={};
for f={'STATE','PHASE','SOLUTION','ADMIT','RECEIPT'},pl=[pl,recLines(p.(f{1}))];end %#ok<AGROW>
pl{end+1}=pline(p.MESH);
assert(strcmpi(p.grandparentS8.sha256,a3.parents.S8.soft1.STATE),SRC,'soft1 S8 grandparent pin differs from LP2-A3.');
pl{end+1}=['grandparentS8 ' p.grandparentS8.sha256];
for f={'TERMINAL','HOLD','ADMIT'},pl=[pl,recLines(fa.(f{1}))];end %#ok<AGROW>
pl{end+1}=pline(fa.FAILED_MESH);
pl{end+1}=sprintf('expectedTip %.17g %.17g',tg.expectedTip_mm(1),tg.expectedTip_mm(2));
ql={};for f={'arrays','attemptJson','repeatArrays','repeatJson','wp1Target','wp1Repeat','b1ArchiveRecord'},ql{end+1}=pline(q.(f{1}));end %#ok<AGROW>
ql=[ql,{['canonical ' q.canonicalSHA256],['b1archive ' q.b1ArchiveSHA256],sprintf('expected T3=%d minAngle=%.17g maxRatio=%.17g',q.T3,q.minAngle_deg,q.maxNeighborRatio)}];
el={pline(e.archiveRecord),pline(e.policy),pline(e.independentAudit),['b1eqarchive ' e.archiveSHA256]};
eo=e.outputs;if ~iscell(eo),eo=num2cell(eo);end
assert(numel(eo)==23,SRC,'Exactly 23 LP2-B1-EQ campaign outputs must be pinned.');
for k=1:numel(eo),el{end+1}=pline(eo{k});end %#ok<AGROW>
pman=g2_lp1_digest(strjoin(sort(pl),newline));qman=g2_lp1_digest(strjoin(sort(ql),newline));eman=g2_lp1_digest(strjoin(sort(el),newline));
au=pol.authorization;
assert(~any(strcmp(au.runName,cellstr(au.forbiddenRunNames)))&&~any(strcmp(au.campaignId,cellstr(au.forbiddenCampaignIds))),SRC,'Forbidden run name or campaign id.');
tok=sprintf(['G2LP2B1S10|policy=%s|g2source=%s|lp2source=%s|lp2a2source=%s|lp2a3source=%s|lp2b1source=%s|lp2b1eqsource=%s|closure=%s|lp2b1s10source=%s|' ...
 'parent=%s|qualification=%s|eqcampaign=%s|case=soft1|state=S10|admissions=1|seed=0.40|campaign=%s|run=%s'], ...
 ps,lower(sp.g2SourceSHA256),lower(sp.lp2SourceSHA256),lower(sp.lp2a2SourceSHA256),lower(sp.lp2a3SourceSHA256),b1src,eqsrc,clsrc,s10src,pman,qman,eman,au.campaignId,au.runName);
hr=cellfun(@(r)fullfile(repo,strrep(r,'/',filesep)),cellstr(pol.historicalRoots),'UniformOutput',false);
% fields used by the unchanged g2_lp2b1eq_geometry (policy.meshFamily, policy.tolerances, here, repo, lp2Policy, a3)
C=struct('repo',repo,'here',here,'md',md,'policy',pol,'policySHA256',ps,'a3',C3,'lp2Policy',C3.lp2Policy,'g2SourceSHA256',lower(sp.g2SourceSHA256), ...
 'lp2b1SourceSHA256',b1src,'lp2b1eqSourceSHA256',eqsrc,'closureSourceSHA256',clsrc,'lp2b1s10SourceSHA256',s10src,'lp2b1s10SourceLines',{s10lines}, ...
 'parentManifestSHA256',pman,'qualificationManifestSHA256',qman,'eqEvidenceManifestSHA256',eman,'token',tok,'preflight',Pf, ...
 'runRoot',fullfile(repo,strrep(au.runRoot,'/',filesep)),'receiptRoot',fullfile(repo,strrep(au.receiptRoot,'/',filesep)), ...
 'summaryFile',fullfile(repo,strrep(au.summaryPath,'/',filesep)),'goFile',fullfile(repo,strrep(au.goPath,'/',filesep)),'historicalRoots',{hr},'test',false);
 function L=recLines(r),pchk(r.record,'record');pchk(r.manifest,'record manifest');L={pline(r.record),pline(r.manifest)};end
 function L=pline(x),pchk(x,'pinned file');L=[x.path ' ' x.sha256];end
end

function [h,lines]=folderDigest(d)
fl=dir(fullfile(d,'*.m'));nl=sort({fl.name});lines=cell(numel(nl),1);
for k=1:numel(nl),lines{k}=[nl{k},' ',lower(g2_sha256_file(fullfile(d,nl{k})))];end
h=g2_lp1_digest(strjoin(lines,newline));
end
