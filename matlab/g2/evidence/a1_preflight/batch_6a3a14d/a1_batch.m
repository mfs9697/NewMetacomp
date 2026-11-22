repo='<repo>';cd(repo);addpath(fullfile(repo,'matlab','g2'),'-begin');
out=fullfile(repo,'outputs','g2_a1_prephysical_batch',['run_',char(datetime('now','TimeZone','UTC','Format','yyyyMMdd_HHmmss'))]);
fprintf('A1_BATCH_OUT %s\n',strrep(out,repo,'<repo>'));
try
 R=g2_a1_prephysical_batch(out);
catch ME
 fprintf(2,'G2_A1_PREPHYSICAL_FAIL %s %s\n',ME.identifier,ME.message);exit(1);
end
