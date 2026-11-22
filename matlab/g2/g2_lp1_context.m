function C=g2_lp1_context()
% Pure read-only context; invokes the independently qualified LP0 preflight.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));P=g2_lp0_preflight();
assert(P.pass,'G2LP1:Preflight','%s: %s (RAM %.6f GiB)',P.status,P.cause,P.freePhysicalRAM_GiB);
pf=fullfile(here,'G2_LP1_POLICY_v2.json');pol=jsondecode(fileread(pf));ps=lower(g2_sha256_file(pf));
assert(strcmpi(g2_sha256_file(fullfile(here,'G2_LP1_POLICY_v1.json')),pol.previousPolicySHA256),'G2LP1:Policy','LP0 policy drift.');
ef=fullfile(repo,pol.lp0Evidence.file);assert(strcmpi(g2_sha256_file(ef),pol.lp0Evidence.sha256),'G2LP1:LP0','LP0 evidence drift.');
E=jsondecode(fileread(ef));assert(E.pass&&strcmp(E.status,pol.lp0Evidence.requiredStatus)&&E.physicalSolves==0,'G2LP1:LP0','LP0 did not qualify.');
for f={'S0','N5','N6'},assert(E.probes.(f{1}).phase.pass,'G2LP1:LP0','Missing phase qualification.');end
assert(E.probes.N5.audit.gatesPassed==34&&E.probes.N6.audit.gatesPassed==34,'G2LP1:LP0','N5/N6 not qualified.');
fs=[dir(fullfile(here,'g2_lp0*.m'));dir(fullfile(here,'g2_lp1*.m'));dir(fullfile(here,'check_g2_lp*.m'))];
[~,ix]=sort({fs.name});fs=fs(ix);lines={['legacy-lock ',pol.sourceLockSHA256]};
for k=1:numel(fs),lines{end+1}=[fs(k).name,' ',lower(g2_sha256_file(fullfile(here,fs(k).name)))];end %#ok<AGROW>
src=g2_lp1_digest(strjoin(lines,newline));
tok=sprintf('G2LP1|policy=%s|source=%s|LP0=%s|cases=H,stiff13,soft2,soft1|maxState=4',ps,src,pol.lp0Evidence.sha256);
C=struct('repo',repo,'here',here,'policy',pol,'policySHA256',ps,'sourceSHA256',src,'sourceLines',{lines},'token',tok,'preflight',P);
end
