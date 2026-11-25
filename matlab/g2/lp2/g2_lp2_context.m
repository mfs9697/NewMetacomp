function C=g2_lp2_context()
%G2_LP2_CONTEXT  Read-only LP2-A context: preflight, policy, source digests, parent manifest, token.
% Preflight is the unchanged g2_lp0_preflight (R2023a + PDE, one engine, clean tree, >= 5 GiB,
% LP0 source lock). The g2 digest covers every top-level matlab/g2/*.m and the p010 vendor and
% must equal the pinned value (no shared module changed); the lp2 digest covers
% matlab/g2/lp2/*.m. The LP2 policy must repeat the LP1 v2 geometry, q domains, BVP and cases
% exactly. No mesh, FEM, folder or record. Fails closed with G2LP2:HOLD_SOURCE.
lp2=fileparts(mfilename('fullpath'));here=fileparts(lp2);repo=fileparts(fileparts(here));addpath(here);
P=g2_lp0_preflight();
assert(P.pass,'G2LP2:Preflight','%s: %s (RAM %.6f GiB)',P.status,P.cause,P.freePhysicalRAM_GiB);
pf=fullfile(lp2,'G2_LP2A_POLICY_v1.json');pol=jsondecode(fileread(pf));ps=lower(g2_sha256_file(pf));
lf=fullfile(here,'G2_LP1_POLICY_v2.json');lp=jsondecode(fileread(lf));
assert(strcmpi(g2_sha256_file(lf),pol.lp1PolicySHA256),'G2LP2:HOLD_SOURCE','LP1 policy v2 drift.');
assert(isequal(pol.geometry,lp.geometry)&&isequal(pol.qAnnuli_mm,lp.qAnnuli_mm)&&isequal(pol.bvp,lp.bvp)&& ...
 isequal(pol.startPolyline_mm,lp.startPolyline_mm)&&isequal({pol.cases.id},{lp.cases.id})&& ...
 isequal([pol.cases.ratio],[lp.cases.ratio])&&isequal([pol.cases.mask],[lp.cases.mask]), ...
 'G2LP2:HOLD_SOURCE','LP2 policy does not repeat the LP1 geometry, q domains, BVP and cases exactly.');
c=pol.caps;
assert(c.firstStateIndex==5&&c.maxStateIndex==8&&c.maxSolves==16&&c.increment_mm==4&&~c.adaptiveStep&& ...
 abs(c.maxArcLength_mm-(c.initialArc_mm+4*c.maxStateIndex))<1e-12,'G2LP2:HOLD_SOURCE','LP2-A caps differ from the preregistered S5-S8 ceiling.');
fs=[dir(fullfile(here,'*.m'));dir(fullfile(here,'vendor_p010_a14d8872','*.m'))];
rel=cell(numel(fs),1);for k=1:numel(fs),rel{k}=strrep(strrep(fullfile(fs(k).folder,fs(k).name),[here filesep],''),filesep,'/');end
[rel,ix]=sort(rel);fs=fs(ix);gl=cell(numel(fs),1);
for k=1:numel(fs),gl{k}=[rel{k},' ',lower(g2_sha256_file(fullfile(fs(k).folder,fs(k).name)))];end
gsrc=g2_lp1_digest(strjoin(gl,newline));
assert(strcmpi(gsrc,pol.g2SourceSHA256),'G2LP2:HOLD_SOURCE','Shared matlab/g2 sources differ from the pinned digest.');
fl=dir(fullfile(lp2,'*.m'));nl=sort({fl.name});ll=cell(numel(nl),1);
for k=1:numel(nl),ll{k}=[nl{k},' ',lower(g2_sha256_file(fullfile(lp2,nl{k})))];end
lsrc=g2_lp1_digest(strjoin(ll,newline));
ids={pol.cases.id};pl=cell(4,1);for k=1:4,pl{k}=[ids{k},' ',pol.parents.(ids{k}).STATE];end
pman=g2_lp1_digest(strjoin(pl,newline));
tok=sprintf('G2LP2A|policy=%s|g2source=%s|lp2source=%s|parents=%s|cases=H,stiff13,soft2,soft1|states=S5-S8|maxSolves=16', ...
 ps,gsrc,lsrc,pman);
C=struct('repo',repo,'here',here,'lp2',lp2,'policy',pol,'policySHA256',ps,'lp1Policy',lp,'g2SourceSHA256',gsrc, ...
 'lp2SourceSHA256',lsrc,'lp2SourceLines',{ll},'parentManifestSHA256',pman,'token',tok,'preflight',P);
end
