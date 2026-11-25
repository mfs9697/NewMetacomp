function run_stage(stage)
restoredefaultpath;
wt='<worktree>';
ex='<repo>';
sc='<scratch>';
ev=fullfile(wt,'docs','research','G2_LP2A2_evidence','eq_campaign_A2');
addpath(fullfile(wt,'scripts','g2','lp2a2','closure'));
try
 lp2a2_eq_closure_run(stage,ex,fullfile(sc,'closure_out'),fullfile(ev,'verify','LP2A2_EQ_A2_AUDIT_DUMP.json'),fullfile(ev,'post','LP2A2_EQ_A2_ARCHIVE_RECORD.json'),fullfile(ev,'post','LP2A2_EQ_A2_HASHCHECK_CLOSURE.json'));
catch ME
 fprintf(2,'CLOSURE_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));exit(1);
end
end
