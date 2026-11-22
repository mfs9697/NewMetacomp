function C=g2_a1_context()
%G2_A1_CONTEXT  Read-only A1 context (Issue #66): preflight, policy, source digest, mesh manifest, token.
% Preflight is the unchanged g2_lp0_preflight (R2023a+PDE, one engine, clean tree, >= 5 GiB,
% locked inputs). The A1 source digest covers EVERY top-level matlab/g2/*.m file and the
% p010 vendor (sorted 'relative-path sha256' lines), so any change to any MATLAB source,
% including the frozen A0 controller and the shared SIF/phase/solver modules, changes it.
% The mesh manifest digest binds the twelve preregistered content SHA-256 values.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
P=g2_lp0_preflight();
assert(P.pass,'G2A1:Preflight','%s: %s (RAM %.6f GiB)',P.status,P.cause,P.freePhysicalRAM_GiB);
pf=fullfile(here,'G2_A1_POLICY_v1.json');pol=jsondecode(fileread(pf));ps=lower(g2_sha256_file(pf));
fs=[dir(fullfile(here,'*.m'));dir(fullfile(here,'vendor_p010_a14d8872','*.m'))];
rel=cell(numel(fs),1);
for k=1:numel(fs),rel{k}=strrep(strrep(fullfile(fs(k).folder,fs(k).name),[here filesep],''),filesep,'/');end
[rel,ix]=sort(rel);fs=fs(ix);lines=cell(numel(fs),1);
for k=1:numel(fs),lines{k}=[rel{k},' ',lower(g2_sha256_file(fullfile(fs(k).folder,fs(k).name)))];end
src=g2_lp1_digest(strjoin(lines,newline));
keys=sort(fieldnames(pol.meshes));ml=cell(numel(keys),1);
for k=1:numel(keys),ml{k}=[keys{k},' ',pol.meshes.(keys{k}).contentSHA256];end
man=g2_lp1_digest(strjoin(ml,newline));
tok=sprintf('G2A1|policy=%s|source=%s|meshes=%s|cases=H,stiff13,soft2,soft1|levels=3,6,9|maxSolves=12',ps,src,man);
C=struct('repo',repo,'here',here,'policy',pol,'policySHA256',ps,'sourceSHA256',src,'sourceLines',{lines}, ...
 'meshManifestSHA256',man,'token',tok,'preflight',P);
end
