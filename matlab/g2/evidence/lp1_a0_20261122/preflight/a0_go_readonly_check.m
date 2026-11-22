% A0 pre-campaign READ-ONLY check: production gate on the committed GO and the campaign
% decision from read-only facts. Writes nothing (no ledger, no run folder, no mesh, no FEM).
repo='<repo>';cd(repo);addpath(fullfile(repo,'matlab','g2'),'-begin');
[~,m]=memory;fprintf('RAM_INSIDE %.3f GiB\n',m.PhysicalMemory.Available/2^30);
C=g2_lp1_context();
fprintf('CONTEXT_TOKEN %s\n',C.token);
fprintf('SOURCE_SET %s\n',C.sourceSHA256);
G=g2_lp1_scientific_gate(C);
fprintf('GO_VALID decision=%s campaign=%s run=%s scope=%s goSHA=%s\n',G.decision,G.campaignId,G.approvedRunName,G.campaignScope,G.goFileSHA256);
lroot=fullfile(repo,'outputs','g2_lp1_campaign_ledger',G.campaignId);
L=g2_lp1_campaign_ledger('snapshot',lroot);
rd=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1','run_a0_lp1_repro_v1');
F=struct('exists',isfolder(rd),'hasRunRecord',isfile(fullfile(rd,'RUN.mat')),'runTokenMatches',false);
D=g2_lp1_campaign_validate(G,'run_a0_lp1_repro_v1',G.goFileSHA256,C.token,L,F,[]);
fprintf('CAMPAIGN_DECISION mode=%s ledgerExists=%d runExists=%d\n',D.mode,isfolder(lroot),F.exists);
try
 g2_lp1_campaign_validate(G,'run_other',G.goFileSHA256,C.token,L,F,[]);fprintf('WRONG_RUN_NOT_REFUSED\n');
catch ME
 fprintf('WRONG_RUN_REFUSED %s\n',ME.identifier);
end
assert(strcmp(C.token,G.approvedToken)&&strcmp(D.mode,'OPEN_NEW')&&~isfolder(lroot)&&~F.exists,'A0:Readonly','Read-only pre-campaign check failed.');
fprintf('A0_READONLY_PRECHECK_PASS NO_WRITE=1\n');
