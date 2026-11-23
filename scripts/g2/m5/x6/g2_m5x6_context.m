function C=g2_m5x6_context()
%G2_M5X6_CONTEXT  Read-only M5-X6 context: A1 context, plan, X6 source digest, mesh manifest, token.
% Reuses the unchanged g2_a1_context (g2_lp0_preflight: R2023a + PDE, one engine, clean tree,
% >= 5 GiB, LP1 source lock; A1 policy; A1 source digest over every top-level matlab/g2/*.m and
% the p010 vendor). The X6 digest covers every scripts/g2/m5/x6/*.m file (sorted
% 'name sha256' lines), so any change to the driver, gate, validator or checks changes the token.
% No mesh, FEM, folder or record. Fails closed with G2M5X6:HOLD_SOURCE on any pin mismatch.
x6=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(fileparts(fileparts(x6))));
g2=fullfile(repo,'matlab','g2');addpath(g2);
pf=fullfile(x6,'G2_M5_X6_PLAN_v1.json');plan=jsondecode(fileread(pf));ps=lower(g2_sha256_file(pf));
A=g2_a1_context();
assert(strcmpi(A.policySHA256,plan.a1.policySHA256)&&strcmpi(A.sourceSHA256,plan.a1.sourceSHA256)&& ...
 strcmpi(A.policy.lp1PolicySHA256,plan.a1.lp1PolicySHA256)&& ...
 strcmpi(g2_sha256_file(fullfile(g2,'G2_LP1_POLICY_v2.json')),plan.a1.lp1PolicySHA256), ...
 'G2M5X6:HOLD_SOURCE','A1 policy, A1 source digest or LP1 policy differs from the M5-X6 plan.');
cfg=planConfigurations(plan,A.policy);
fs=dir(fullfile(x6,'*.m'));names=sort({fs.name});lines=cell(numel(names),1);
for k=1:numel(names),lines{k}=[names{k},' ',lower(g2_sha256_file(fullfile(x6,names{k})))];end
xs=g2_lp1_digest(strjoin(lines,newline));
keys=sort({plan.diagonal.key});ml=cell(numel(keys),1);
for k=1:numel(keys),ml{k}=[keys{k},' ',A.policy.meshes.(keys{k}).contentSHA256];end
man=g2_lp1_digest(strjoin(ml,newline));
tok=sprintf('G2M5X6|plan=%s|a1policy=%s|a1source=%s|x6source=%s|meshes=%s|configs=%s|maxSolves=6', ...
 ps,A.policySHA256,A.sourceSHA256,xs,man,strjoin({cfg.id},','));
C=struct('repo',repo,'g2',g2,'x6',x6,'plan',plan,'planSHA256',ps,'configurations',cfg,'a1',A, ...
 'a1SourceSHA256',A.sourceSHA256,'x6SourceSHA256',xs,'x6SourceLines',{lines},'meshManifestSHA256',man, ...
 'token',tok,'preflight',A.preflight);
end

function cfg=planConfigurations(plan,pol)
% The six identities are fixed; every mesh pin and material definition must equal the A1 policy.
ids={'X6-01','X6-02','X6-03','X6-04','X6-05','X6-06'};
cfg=plan.configurations;
assert(numel(cfg)==6&&isequal({cfg.id},ids)&&plan.maxSolves==6&&plan.initialSolves==6&&plan.level==9, ...
 'G2M5X6:HOLD_SOURCE','The plan does not define exactly the six preregistered configurations.');
cs={pol.cases.id};pairs={'H','stiff13';'stiff13','H';'H','soft2';'soft2','H';'H','soft1';'soft1','H'};
for k=1:6
 c=cfg(k);ip=find(strcmp(cs,c.pathCase));im=find(strcmp(cs,c.materialCase));
 assert(isscalar(ip)&&isscalar(im)&&strcmp(c.pathCase,pairs{k,1})&&strcmp(c.materialCase,pairs{k,2})&& ...
  strcmp(c.meshKey,[c.pathCase '_B9'])&&strcmp(c.key,strrep(c.id,'-','_'))&& ...
  strcmp(c.meshContentSHA256,pol.meshes.(c.meshKey).contentSHA256)&& ...
  isequal(reshape(c.mask,1,3),reshape(pol.cases(im).mask,1,3))&&c.ratio==pol.cases(im).ratio, ...
  'G2M5X6:HOLD_SOURCE','Configuration %s differs from the A1 policy cases or meshes.',c.id);
end
end
