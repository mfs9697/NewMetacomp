try
    repo = 'C:\Users\Mikhailo\Documents\Codex\2026-11-22\new-chat\NewMetacomp';
    resultFile = 'C:\Users\Mikhailo\Documents\Codex\2026-11-22\new-chat\NewMetacomp\outputs\g2_lp1_prephysical_batch\run_20261122_143243_195\PREPHYSICAL_RESULT.json';
    probe = 'run_prephysical_guard_20261122_143243_195';
    cd(repo);
    addpath(fullfile(repo,'matlab','g2'),'-begin');
    assert(~isfile(fullfile(repo,'matlab','g2','G2_LP1_SCIENTIFIC_GO_v1.json')), ...
        'G2Batch:UnexpectedGO','Scientific GO must be absent.');
    p = g2_lp0_preflight();
    assert(p.pass && strcmp(p.status,'PREFLIGHT_READY_NOT_LP0_QUALIFIED') && ...
        p.physicalSolves==0 && p.meshBuilds==0, ...
        'G2Batch:Preflight','LP0 preflight failed: %s',p.cause);
    fprintf('LP0_PREFLIGHT_PASS %s RAM_GiB=%.3f\n',p.sourceCommit,p.freePhysicalRAM_GiB);
    g = check_g2_lp0_clearance();
    assert(g.pass && g.passed==23 && g.total==23,'G2Batch:Clearance','Expected 23/23 geometry tests.');
    ids = {'H','stiff13','soft2','soft1'};
    for i=1:numel(ids)
        d = g2_lp1_run('Case',ids{i},'Run',false,'MaxStateIndex',2);
        assert(strcmp(d.status,'DRY_READY_NO_FEM') && d.computed==0 && d.lastState==-1, ...
            'G2Batch:Dry','Dry controller failed for %s',ids{i});
        fprintf('LP1_DRY %s PASS\n',ids{i});
    end
    t = check_g2_lp1_contract();
    assert(t.pass && t.passed==t.total && t.total>=20 && ...
        t.negativeTestsPassed && t.recordIntegrityPassed && ...
        t.physicalSolves==0 && t.meshBuilds==0,'G2Batch:Contract','LP1 contract failed.');
    probeFolder=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1',probe);
    assert(~isfolder(probeFolder),'G2Batch:Probe','Guard probe path exists.');
    refused=false;
    try
        g2_lp1_run('Case','H','Run',true,'MaxStateIndex',0, ...
            'AuthToken','INVALID_NOT_AUTHORIZED','RunName',probe);
    catch ME
        refused=strcmp(ME.identifier,'G2LP1:HOLD_UNAUTHORIZED_STATE');
        fprintf('SCIENTIFIC_GO_REFUSAL %s\n',ME.identifier);
    end
    assert(refused && ~isfolder(probeFolder),'G2Batch:Guard','No-GO refusal failed.');
    r=struct('schema','NewMetacomp.G2.LP1.PrephysicalBatch.v1', ...
        'status','TESTS_PASS_SCIENTIFIC_HOLD','sourceCommit',p.sourceCommit, ...
        'release',p.release,'policySHA256',p.policySHA256, ...
        'freePhysicalRAM_GiB',p.freePhysicalRAM_GiB, ...
        'clearanceTestsPassed',g.passed,'clearanceTestsTotal',g.total, ...
        'contractTestsPassed',t.passed,'contractTestsTotal',t.total, ...
        'negativeTestsPassed',t.negativeTestsPassed, ...
        'recordIntegrityPassed',t.recordIntegrityPassed, ...
        'goRefusedBeforeWrites',true,'dryCases',{ids}, ...
        'scientificGO',false,'physicalSolves',0,'meshBuilds',0, ...
        'evidenceRole','UNREVIEWED_CANDIDATE_NOT_AUTHORIZATION');
    fid=fopen(resultFile,'w');
    assert(fid>=0,'G2Batch:File','Cannot open report.');
    fwrite(fid,jsonencode(r,'PrettyPrint',true),'char');fclose(fid);
    fprintf('G2_LP1_PREFLIGHT_PASS NO_MESH=1 NO_FEM=1 SCIENTIFIC_HOLD=1\n');
catch ME
    fprintf(2,'G2_LP1_PREFLIGHT_FAIL %s %s\n',ME.identifier,ME.message);
    fprintf(2,'%s\n',getReport(ME,'extended','hyperlinks','off'));
    if exist('resultFile','var')
        r=struct('schema','NewMetacomp.G2.LP1.PrephysicalBatch.v1', ...
            'status','FAILED','errorIdentifier',ME.identifier,'message',ME.message, ...
            'scientificGO',false,'evidenceRole','UNREVIEWED_FAILURE');
        fid=fopen(resultFile,'w');
        if fid>=0,fwrite(fid,jsonencode(r,'PrettyPrint',true),'char');fclose(fid);end
    end
    exit(1);
end
exit(0);