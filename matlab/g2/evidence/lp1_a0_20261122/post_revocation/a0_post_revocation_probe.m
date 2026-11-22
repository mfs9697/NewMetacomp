% Post-revocation probe (Issue #64, A0-4): with the GO removed, a Run=true call with the
% correct token and approved run name must be refused by the gate before any write.
repo='<repo>';cd(repo);addpath(fullfile(repo,'matlab','g2'),'-begin');
assert(~isfile(fullfile(repo,'matlab','g2','G2_LP1_SCIENTIFIC_GO_v1.json')),'A0:Probe','GO still present.');
tok=['G2LP1|policy=074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091', ...
 '|source=9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5', ...
 '|LP0=b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5|cases=H,stiff13,soft2,soft1|maxState=4'];
rd=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1','run_a0_lp1_repro_v1');lroot=fullfile(repo,'outputs','g2_lp1_campaign_ledger','G2-LP1-A0-001');
b=[listing(rd);listing(lroot)];id='<no error>';msg='';
try
 g2_lp1_run('Case','H','MaxStateIndex',4,'Run',true,'AuthToken',tok,'RunName','run_a0_lp1_repro_v1');
catch ME
 id=ME.identifier;msg=ME.message;
end
a=[listing(rd);listing(lroot)];
ok=strcmp(id,'G2LP1:HOLD_UNAUTHORIZED_STATE')&&contains(msg,'no separate GO record')&&isequal(a,b);
fprintf('POST_REVOCATION_REFUSAL id=%s unchanged=%d files=%d pass=%d\n',id,isequal(a,b),size(b,1),ok);
function L=listing(folder)
d=dir(fullfile(folder,'**','*'));d=d(~[d.isdir]);L=sort(strcat({d.folder}',filesep,{d.name}'));
L=[L,cellfun(@(f)num2str(dir(f).bytes),L,'UniformOutput',false),cellfun(@(f)char(string(dir(f).datenum)),L,'UniformOutput',false)];
end
