repo='<repo>';
cd(repo);addpath(fullfile(repo,'matlab','g2'),'-begin');
[~,m]=memory;fprintf('RAM_OBSERVATION pure_start %.6f GiB %s\n',m.PhysicalMemory.Available/2^30,char(datetime('now','TimeZone','UTC')));
T=check_g2_lp1_contract();
S=check_g2_lp1_contract_sensitivity();
out=fullfile(repo,'outputs','g2_lp1_vg2_pure');if ~isfolder(out),mkdir(out);end
fid=fopen(fullfile(out,'CONTRACT_TESTS_PURE.json'),'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);
fid=fopen(fullfile(out,'CONTRACT_SENSITIVITY.json'),'w');fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);
[~,m]=memory;fprintf('RAM_OBSERVATION pure_end %.6f GiB\n',m.PhysicalMemory.Available/2^30);
fprintf('VG2_PURE_DONE contract=%d/%d sensitivity=%d/%d\n',T.passed,T.total,S.detected,S.total);
