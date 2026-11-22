try
    repo = '<repo>';
    resultFile = '<repo>\outputs\g2_lp1_prephysical_batch\run_20261122_180805_142\PREPHYSICAL_RESULT.json';
    contractFile = '<repo>\outputs\g2_lp1_prephysical_batch\run_20261122_180805_142\CONTRACT_TESTS.json';
    probe = 'run_prephysical_guard_20261122_180805_142';
    cd(repo);
    addpath(fullfile(repo,'matlab','g2'),'-begin');
    ram = struct('stage',{},'utc',{},'freeGiB',{});
    assert(~isfile(fullfile(repo,'matlab','g2','G2_LP1_SCIENTIFIC_GO_v1.json')), ...
        'G2Batch:UnexpectedGO','Scientific GO must be absent.');
    assert(~isfile(fullfile(repo,'matlab','g2','G2_LP1_CAMPAIGN_RESUME_v1.json')), ...
        'G2Batch:UnexpectedResume','Campaign resume record must be absent.');
    ledgerRoot=fullfile(repo,'outputs','g2_lp1_campaign_ledger');ledgerBefore=listing(ledgerRoot);
    ram = observe(ram,'start');
    p = g2_lp0_preflight();
    assert(p.pass && strcmp(p.status,'PREFLIGHT_READY_NOT_LP0_QUALIFIED') && ...
        p.physicalSolves==0 && p.meshBuilds==0, ...
        'G2Batch:Preflight','LP0 preflight failed: %s',p.cause);
    fprintf('LP0_PREFLIGHT_PASS %s RAM_GiB=%.3f\n',p.sourceCommit,p.freePhysicalRAM_GiB);
    g = check_g2_lp0_clearance();
    assert(g.pass && g.passed==23 && g.total==23,'G2Batch:Clearance','Expected 23/23 geometry tests.');
    ids = {'H','stiff13','soft2','soft1'};
    tokens = cell(1,numel(ids));
    for i=1:numel(ids)
        ram = observe(ram,['dry_' ids{i}]);
        d = g2_lp1_run('Case',ids{i},'Run',false,'MaxStateIndex',2);
        assert(strcmp(d.status,'DRY_READY_NO_FEM') && d.computed==0 && d.lastState==-1, ...
            'G2Batch:Dry','Dry controller failed for %s',ids{i});
        tokens{i} = d.token;
        fprintf('LP1_DRY %s PASS\n',ids{i});
    end
    assert(all(strcmp(tokens,tokens{1})),'G2Batch:Dry','Dry tokens differ between cases.');
    fprintf('LP1_CURRENT_TOKEN %s\n',tokens{1});
    ram = observe(ram,'contract');
    t = check_g2_lp1_contract();
    assert(t.pass && t.passed==t.total && t.total>=20 && ...
        t.negativeTestsPassed && t.recordIntegrityPassed && ...
        isfield(t,'goFixturesPassed') && t.goFixturesPassed && t.admissionPassed && ...
        t.interfacePassed && t.exactIdentifierNegatives && ...
        isfield(t,'campaignPassed') && t.campaignPassed && t.ledgerPassed && ...
        t.physicalSolves==0 && t.meshBuilds==0,'G2Batch:Contract','LP1 contract failed.');
    fid=fopen(contractFile,'w');assert(fid>=0,'G2Batch:File','Cannot open contract report.');
    fwrite(fid,jsonencode(t,'PrettyPrint',true),'char');fclose(fid);
    % Two refusal probes: an invalid token and the CORRECT current token. Both must be
    % refused by the absent GO (exact identifier and message) before any folder exists.
    runRoot=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1');
    before=listing(runRoot);
    probes={'INVALID_NOT_AUTHORIZED',tokens{1}};probeIds=cell(1,2);
    for j=1:2
        pf=fullfile(runRoot,[probe '_' num2str(j)]);
        assert(~isfolder(pf),'G2Batch:Probe','Guard probe path exists.');
        ram = observe(ram,sprintf('probe_%d',j));
        refused=false;probeIds{j}='<no error>';
        try
            g2_lp1_run('Case','H','Run',true,'MaxStateIndex',0, ...
                'AuthToken',probes{j},'RunName',[probe '_' num2str(j)]);
        catch ME
            probeIds{j}=ME.identifier;
            refused=strcmp(ME.identifier,'G2LP1:HOLD_UNAUTHORIZED_STATE') && ...
                contains(ME.message,'no separate GO record');
        end
        fprintf('SCIENTIFIC_GO_REFUSAL probe=%d token=%s id=%s\n',j, ...
            ternary(j==1,'invalid','current'),probeIds{j});
        assert(refused && ~isfolder(pf),'G2Batch:Guard','No-GO refusal failed for probe %d.',j);
    end
    assert(isequal(before,listing(runRoot)),'G2Batch:Guard','Run root changed during refusal probes.');
    assert(isequal(ledgerBefore,listing(ledgerRoot)),'G2Batch:Guard','Campaign ledger changed during the batch.');
    ram = observe(ram,'end');
    r=struct('schema','NewMetacomp.G2.LP1.PrephysicalBatch.v2', ...
        'status','TESTS_PASS_SCIENTIFIC_HOLD','sourceCommit',p.sourceCommit, ...
        'release',p.release,'policySHA256',p.policySHA256, ...
        'freePhysicalRAM_GiB',p.freePhysicalRAM_GiB,'ramObservations',ram, ...
        'clearanceTestsPassed',g.passed,'clearanceTestsTotal',g.total, ...
        'contractTestsPassed',t.passed,'contractTestsTotal',t.total, ...
        'negativeTestsPassed',t.negativeTestsPassed, ...
        'recordIntegrityPassed',t.recordIntegrityPassed, ...
        'goFixturesPassed',t.goFixturesPassed,'admissionPassed',t.admissionPassed, ...
        'interfacePassed',t.interfacePassed,'exactIdentifierNegatives',t.exactIdentifierNegatives, ...
        'campaignPassed',t.campaignPassed,'ledgerPassed',t.ledgerPassed, ...
        'currentToken',tokens{1},'refusalProbeIdentifiers',{probeIds}, ...
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
        if ~exist('ram','var'),ram=struct('stage',{},'utc',{},'freeGiB',{});end
        try,ram=observe(ram,'failure');catch,end
        r=struct('schema','NewMetacomp.G2.LP1.PrephysicalBatch.v2', ...
            'status','FAILED','errorIdentifier',ME.identifier,'message',ME.message, ...
            'ramObservations',ram,'scientificGO',false,'evidenceRole','UNREVIEWED_FAILURE');
        fid=fopen(resultFile,'w');
        if fid>=0,fwrite(fid,jsonencode(r,'PrettyPrint',true),'char');fclose(fid);end
    end
    exit(1);
end
exit(0);

function ram=observe(ram,stage)
[~,s]=memory;
ram(end+1)=struct('stage',stage,'utc',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z''')), ...
    'freeGiB',s.PhysicalMemory.Available/2^30);
fprintf('RAM_OBSERVATION %s %.6f GiB\n',stage,ram(end).freeGiB);
end
function L=listing(folder)
if ~isfolder(folder),L={};return,end
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}));
end
function y=ternary(c,a,b)
if c,y=a;else,y=b;end
end