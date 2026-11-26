function C=g2_lp2b1eq_context(varargin)
%G2_LP2B1EQ_CONTEXT  Read-only context of the PROSPECTIVE LP2-B1-EQ campaign G2-LP2B1-EQ-001 (two fixed-geometry
% 0.40 mm equivalence solves). No mesh, FEM, folder or record. Fails closed with G2LP2B1EQ:HOLD_SOURCE.
%  C = g2_lp2b1eq_context()                    normal preflight (g2_lp0_preflight; inherited 5 GiB guard unchanged)
%  C = g2_lp2b1eq_context('Preflight',false)   read-only replay and zero-FEM tests only (never a physical call)
% Checks: LP2-A3 context (its own policy, g2/lp2/lp2a2/lp2a3 digests, S8 parents, WP5 qualification pins); this
% policy repeats the LP2-A3 source pins, geometry, q annuli, BVP and the WP5 tolerances exactly (contrast entries
% removed, S9 predictor tolerance renamed nextTipDisplacement_mm); policy files, lp2b1, lp2b1eq and WP5 closure
% digests; every archived reference, parent, next-tip, admission and qualification file against its pin.
% The token binds the policy, all seven source digests and the reference and qualification manifests.
ip=inputParser;addParameter(ip,'Preflight',true,@islogical);parse(ip,varargin{:});
eq=fileparts(mfilename('fullpath'));here=fileparts(eq);repo=fileparts(fileparts(here));
for f={'','lp2','lp2a2','lp2a3','lp2b1'},addpath(fullfile(here,f{1}));end
addpath(fullfile(repo,'scripts','g2','lp2a2','closure'));addpath(eq);
SRC='G2LP2B1EQ:HOLD_SOURCE';
if ip.Results.Preflight
 Pf=g2_lp0_preflight();assert(Pf.pass,'G2LP2B1EQ:Preflight','%s: %s (RAM %.6f GiB)',Pf.status,Pf.cause,Pf.freePhysicalRAM_GiB);
else
 Pf=struct('pass',false,'status','SKIPPED_READ_ONLY','sourceCommit','','matlabProcesses',NaN);
end
pf=fullfile(eq,'G2_LP2B1EQ_POLICY_v1.json');pol=jsondecode(fileread(pf));ps=lower(g2_sha256_file(pf));
assert(strcmp(pol.schema,'NewMetacomp.G2.LP2B1EQ.Policy.v1')&&strcmp(pol.status,'PROPOSED_NOT_AUTHORIZED'),SRC,'Policy schema or status.');
fh=@(rel)lower(g2_sha256_file(fullfile(repo,strrep(rel,'/',filesep))));
pchk=@(p,what)assert(isfile(fullfile(repo,strrep(p.path,'/',filesep)))&&strcmp(fh(p.path),p.sha256),SRC,'%s differs from its pin (%s).',what,p.path);
for f=fieldnames(pol.policyPins).',pchk(pol.policyPins.(f{1}),['policy ' f{1}]);end
pchk(pol.authority.contractDraft,'LP2-B1 contract draft');
% ---- LP2-A3 context (verifies its own policy, four digests, 20 S8 parent files, WP5 qualification)
C3=g2_lp2a3_context('Preflight',false);a3=C3.policy;sp=pol.sourcePins;
assert(strcmp(C3.policySHA256,pol.policyPins.lp2a3.sha256),SRC,'LP2-A3 policy.');
assert(strcmpi(C3.g2SourceSHA256,sp.g2SourceSHA256)&&strcmpi(C3.lp2SourceSHA256,sp.lp2SourceSHA256)&& ...
 strcmpi(C3.lp2a2SourceSHA256,sp.lp2a2SourceSHA256)&&strcmpi(C3.lp2a3SourceSHA256,sp.lp2a3SourceSHA256),SRC,'Inherited source digests differ from the LP2-A3 pins.');
[b1src,~]=folderDigest(fullfile(here,'lp2b1'));[eqsrc,eqlines]=folderDigest(eq);[clsrc,~]=folderDigest(fullfile(repo,'scripts','g2','lp2a2','closure'));
assert(strcmpi(b1src,sp.lp2b1SourceSHA256),SRC,'matlab/g2/lp2b1 sources differ from the pinned digest.');
assert(strcmpi(eqsrc,sp.lp2b1eqSourceSHA256),SRC,'matlab/g2/lp2b1eq sources differ from the pinned digest (%s).',eqsrc);
assert(strcmpi(clsrc,sp.closureSourceSHA256),SRC,'WP5 closure verifier sources differ from the pinned digest.');
assert(isequal(pol.geometry,a3.geometry)&&isequal(pol.qAnnuli_mm,a3.qAnnuli_mm)&&isequal(pol.bvp,a3.bvp)&&isequal(pol.resources,a3.resources)&& ...
 isequal(pol.meshFamily.ExteriorOptions,a3.meshFamily.ExteriorOptions)&&pol.meshFamily.seedSpacing_mm==0.40,SRC,'Geometry, q annuli, BVP, resources or mesh options differ from LP2-A3.');
w5=jsondecode(fileread(fullfile(here,'lp2a2','G2_LP2A2_EQ_POLICY_v1.json')));t5=w5.tolerances;t=pol.tolerances;
fn=fieldnames(t5);fn=fn(~startsWith(fn,'contrast_')&~strcmp(fn,'S9tipDisplacement_mm'));ok=true;
for k=1:numel(fn),ok=ok&&isfield(t,fn{k})&&isequal(t.(fn{k}),t5.(fn{k}));end
assert(ok&&isequal(t.nextTipDisplacement_mm,t5.S9tipDisplacement_mm)&&isequal(t.activeAreaExactZeroWhenArchivedZero,true)&& ...
 t.nearTipRadius_mm==3.3&&t.nodeMatch_mm==1e-9&&numel(fieldnames(t))==numel(fn)+4,SRC,'Tolerances differ from the WP5 policy.');
s=pol.solves;if ~iscell(s),s=num2cell(s);end
assert(numel(s)==2&&strcmp(s{1}.id,'EQB-soft1-S9')&&strcmp(s{2}.id,'EQB-H-S10')&&pol.solveLimit==2&&pol.attemptsPerSolve==1&& ...
 ~pol.retry&&~pol.adaptiveStep&&pol.newStates==0&&~pol.targetSolve,SRC,'Solve set, order or limits differ from the assignment.');
% ---- reference, parent, next-tip, admission and qualification files
rl={};ql={};
for k=1:2
 a=s{k}.archived;rl=[rl,recLines(a.STATE),{pline(a.MESH)},recLines(a.PHASE),recLines(a.SOLUTION),recLines(a.ADMIT)]; %#ok<AGROW>
 p=s{k}.parent;if isfield(p.STATE,'record'),rl=[rl,recLines(p.STATE),recLines(p.ADMIT)];else,rl{end+1}=pline(p.STATE);end %#ok<AGROW>
 n=s{k}.nextPredictor;
 if isfield(n,'TERMINAL'),rl=[rl,recLines(n.TERMINAL),{pline(n.FAILED_MESH)}];else,rl=[rl,recLines(n.STATE),recLines(n.ADMIT)];end %#ok<AGROW>
 rl{end+1}=sprintf('%s nextTip %s %.17g %.17g',s{k}.id,n.state,n.tip_mm(1),n.tip_mm(2)); %#ok<AGROW>
 q=s{k}.qualification;ql=[ql,{pline(q.arrays),pline(q.attemptJson),[s{k}.id ' canonical ' q.canonicalSHA256]}]; %#ok<AGROW>
end
p8=a3.parents.S8.soft1.STATE;assert(strcmpi(p8,s{1}.parent.STATE.sha256),SRC,'soft1 S8 parent pin differs from LP2-A3.');
assert(strcmpi(a3.parents.S8.H.STATE,s{2}.parent.grandparent.sha256),SRC,'H S8 grandparent pin differs from LP2-A3.');
for r=pol.qualificationEvidence.records(:).',pchk(r,'qualification record');ql{end+1}=pline(r);end %#ok<AGROW>
for r=pol.qualificationEvidence.evidenceFiles(:).',pchk(r,'qualification evidence');ql{end+1}=pline(r);end %#ok<AGROW>
ql{end+1}=['b1archive ' pol.qualificationEvidence.b1ArchiveSHA256];
rman=g2_lp1_digest(strjoin(sort(rl),newline));qman=g2_lp1_digest(strjoin(sort(ql),newline));
au=pol.authorization;
assert(~any(strcmp(au.runName,cellstr(au.forbiddenRunNames)))&&~any(strcmp(au.campaignId,cellstr(au.forbiddenCampaignIds))),SRC,'Forbidden run name or campaign id.');
tok=sprintf(['G2LP2B1EQ|policy=%s|g2source=%s|lp2source=%s|lp2a2source=%s|lp2a3source=%s|lp2b1source=%s|lp2b1eqsource=%s|closure=%s|' ...
 'references=%s|qualification=%s|solves=EQB-soft1-S9,EQB-H-S10|limit=2|seed=0.40|campaign=%s|run=%s'], ...
 ps,lower(sp.g2SourceSHA256),lower(sp.lp2SourceSHA256),lower(sp.lp2a2SourceSHA256),lower(sp.lp2a3SourceSHA256),b1src,eqsrc,clsrc,rman,qman,au.campaignId,au.runName);
hr=cellfun(@(r)fullfile(repo,strrep(r,'/',filesep)),cellstr(pol.historicalRoots),'UniformOutput',false);
C=struct('repo',repo,'here',here,'eq',eq,'policy',pol,'solves',{s},'policySHA256',ps,'a3',C3,'lp2Policy',C3.lp2Policy,'g2SourceSHA256',lower(sp.g2SourceSHA256), ...
 'lp2b1SourceSHA256',b1src,'lp2b1eqSourceSHA256',eqsrc,'lp2b1eqSourceLines',{eqlines},'closureSourceSHA256',clsrc,'referenceManifestSHA256',rman, ...
 'qualificationManifestSHA256',qman,'token',tok,'preflight',Pf,'runRoot',fullfile(repo,strrep(au.runRoot,'/',filesep)), ...
 'receiptRoot',fullfile(repo,strrep(au.receiptRoot,'/',filesep)),'goFile',fullfile(repo,strrep(au.goPath,'/',filesep)),'historicalRoots',{hr},'test',false);
 function L=recLines(r),pchk(r.record,'reference record');pchk(r.manifest,'reference manifest');L={pline(r.record),pline(r.manifest)};end
 function L=pline(p),pchk(p,'reference file');L=[p.path ' ' p.sha256];end
end

function [h,lines]=folderDigest(d)
fl=dir(fullfile(d,'*.m'));nl=sort({fl.name});lines=cell(numel(nl),1);
for k=1:numel(nl),lines{k}=[nl{k},' ',lower(g2_sha256_file(fullfile(d,nl{k})))];end
h=g2_lp1_digest(strjoin(lines,newline));
end
