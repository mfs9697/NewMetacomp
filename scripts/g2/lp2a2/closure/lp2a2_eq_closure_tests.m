function T=lp2a2_eq_closure_tests(execRepo,outDir,varargin)
%LP2A2_EQ_CLOSURE_TESTS  Regression tests of the corrected read-only verifier (zero solves).
%  Part A  actual JSON round trip (jsonencode -> file -> fileread -> jsondecode) of failed-criteria lists:
%          empty (1x0, 0x0, 0x1), singleton, multiple, reordered, mismatched, malformed.
%          Also reproduces the historical defect with the historical expression.
%  Part B  end-to-end mutations on a COPY of the four record sets (the originals are never written):
%          the verifier must accept the unmodified copy and reject every mutated one for the stated reason.
%   T=lp2a2_eq_closure_tests(execRepo,outDir,'ReferenceDump',json,'ReferenceArchive',json,'Scratch',dir)
ip=inputParser;addParameter(ip,'ReferenceDump','',@ischar);addParameter(ip,'ReferenceArchive','',@ischar);
addParameter(ip,'Scratch','',@ischar);addParameter(ip,'SkipMutation',false,@islogical);parse(ip,varargin{:});o=ip.Results;
if ~isfolder(outDir),mkdir(outDir);end
allowed={'C1_KI';'C2_KII';'C3_KIIoverKI';'C4_G_J';'C5_MTS';'C6_COD_EDI';'C7_EDI_spread_quadrature';'C8_crackOpening';'C9_phaseActivation';'C10_S9predictor';'C11_compliance'};
tmp=o.Scratch;if isempty(tmp),tmp=tempname;end;if ~isfolder(tmp),mkdir(tmp);end
% ================= Part A =================
cell10=cell(1,0);
cases={ ...
 'empty_1x0_cell',            cell10,                     allowed(false(11,1)),  'equal',    '';
 'empty_0x0_cell',            cell(0,0),                  cell10,                'equal',    '';
 'empty_0x1_cell',            cell(0,1),                  cell(0,1),             'equal',    '';
 'empty_stored_vs_recomputed_empty_0x1', cell10,          allowed(false(11,1)),  'equal',    '';
 'singleton',                 {'C3_KIIoverKI'},           {'C3_KIIoverKI'},      'equal',    '';
 'singleton_recomputed_column', {'C3_KIIoverKI'},         {'C3_KIIoverKI'}.',    'equal',    '';
 'multiple_reordered',        {'C11_compliance','C1_KI','C5_MTS'}, {'C1_KI';'C5_MTS';'C11_compliance'}, 'equal', '';
 'multiple_all_eleven',       allowed.',                  flipud(allowed),       'equal',    '';
 'mismatch_stored_empty',     cell10,                     {'C1_KI'},             'mismatch', 'differ';
 'mismatch_recomputed_empty', {'C1_KI'},                  cell10,                'mismatch', 'differ';
 'mismatch_other_name',       {'C1_KI'},                  {'C2_KII'},            'mismatch', 'differ';
 'mismatch_stored_longer',    {'C1_KI','C2_KII'},         {'C1_KI'},             'mismatch', 'differ';
 'mismatch_stored_shorter',   {'C1_KI'},                  {'C1_KI','C2_KII'},    'mismatch', 'differ';
 'malformed_numeric_vector',  [1 2],                      cell10,                'rejected', 'raw text';
 'malformed_numeric_scalar',  0,                          cell10,                'rejected', 'raw text';
 'malformed_logical',         true,                       cell10,                'rejected', 'raw text';
 'malformed_mixed_elements',  {1,'C1_KI'},                {'C1_KI'},             'rejected', 'raw text';
 'malformed_nested_list',     {{'C1_KI'}},                {'C1_KI'},             'rejected', 'raw text';
 'malformed_nested_empty',    {{}},                       cell10,                'rejected', 'raw text';
 'malformed_object',          struct(),                   cell10,                'rejected', 'raw text';
 'malformed_bare_string',     'C1_KI',                    {'C1_KI'},             'rejected', 'raw text';
 'malformed_empty_string',    '',                         cell10,                'rejected', 'raw text';
 'malformed_empty_name',      {''},                       cell10,                'rejected', 'raw text';
 'malformed_unknown_name',    {'C99_X'},                  {'C99_X'},             'rejected', 'not a criterion';
 'malformed_duplicate_name',  {'C1_KI','C1_KI'},          {'C1_KI'},             'rejected', 'duplicate';
 'malformed_recomputed_numeric', cell10,                  [1 2],                 'rejected', 'recomputed list'};
extra={'malformed_null',        '{"schema": "x", "failed": null}',               cell10,      'rejected','raw text'; ...
 'malformed_missing_field',     '{"schema": "x"}',                                cell10,      'rejected','raw text'; ...
 'malformed_two_members',       '{"schema": "x", "failed": [], "failed": []}',    cell10,      'rejected','raw text'; ...
 'malformed_trailing_number',   '{"schema": "x", "failed": ["C1_KI", 2]}',        {'C1_KI'},   'rejected','raw text'; ...
 'valid_hand_written_empty',    '{"schema": "x", "failed": [ ]}',                 cell10,      'equal',   ''; ...
 'valid_hand_written_singleton','{"schema": "x", "failed": ["C5_MTS"]}',          {'C5_MTS'},  'equal',   ''};
TA=struct('name',{},'expect',{},'got',{},'pass',{},'storedClass',{},'storedSize',{},'legacyIsequal',{},'why',{});
for q=1:size(cases,1)
 nm=cases{q,1};val=cases{q,2};rec=cases{q,3};ex=cases{q,4};
 S=struct('schema','x','failed',{val});
 [raw,Cm]=roundtripFile(S,tmp,nm);
 TA(end+1)=evalCase(nm,raw,Cm,rec,allowed,ex,cases{q,5}); %#ok<AGROW>
end
for q=1:size(extra,1)
 raw=extra{q,2};try,Cm=jsondecode(raw);catch,Cm=struct();end %#ok<NASGU>
 TA(end+1)=evalCase(extra{q,1},raw,Cm,extra{q,3},allowed,extra{q,4},extra{q,5}); %#ok<AGROW>
end
T=struct('schema','NewMetacomp.G2.LP2A2.EQ.ClosureTests.v1','partA',TA,'partAPassed',sum([TA.pass]),'partATotal',numel(TA));
% historical defect, historical expression, real round trip
fl=jsondecode(jsonencode(struct('failed',{cell10}))).failed;rc=allowed(false(11,1));
T.defect=struct('storedClassAfterRoundTrip',class(fl),'storedSizeAfterRoundTrip',size(fl),'recomputedClass',class(rc),'recomputedSize',size(rc), ...
 'historicalIsequal',isequal(sort(rc(:)).',sort(fl(:)).'),'corrected',lp2a2_eq_failed_check(sprintf('{"failed": []}'),struct('failed',fl),rc,allowed).equal);
% ================= Part B =================
T.partB=struct([]);T.partBPassed=0;T.partBTotal=0;
if ~o.SkipMutation
 C=g2_lp2a2_eq_context('Preflight',false);real=fullfile(C.repo,C.policy.outputRoot);
 base=fullfile(tmp,'base');if isfolder(base),rmdir(base,'s');end;copyfile(real,base);
 ref={'ReferenceDump',o.ReferenceDump,'ReferenceArchive',o.ReferenceArchive};
 M={ ...
  'm00_baseline_copy_no_reference',    @(r)0,                                   {},  'VERIFIED_V2', ''; ...
  'm01_baseline_copy_with_reference',  @(r)0,                                   ref, 'VERIFIED_V2', ''; ...
  'm02_failed_nonempty_with_pass',     @(r)edit(r,'EQ-soft2','COMPARISON.json','"failed": []','"failed": ["C1_KI"]'), {}, 'VERIFY_HOLD_V2','FAILED_LIST'; ...
  'm03_failed_null',                   @(r)edit(r,'EQ-soft2','COMPARISON.json','"failed": []','"failed": null'),     {}, 'VERIFY_HOLD_V2','FAILED_LIST'; ...
  'm04_failed_numeric',                @(r)edit(r,'EQ-soft2','COMPARISON.json','"failed": []','"failed": [1,2]'),    {}, 'VERIFY_HOLD_V2','FAILED_LIST'; ...
  'm05_failed_object',                 @(r)edit(r,'EQ-soft2','COMPARISON.json','"failed": []','"failed": {}'),       {}, 'VERIFY_HOLD_V2','FAILED_LIST'; ...
  'm06_failed_duplicate_names',        @(r)edit(r,'EQ-soft2','COMPARISON.json','"failed": []','"failed": ["C1_KI","C1_KI"]'), {}, 'VERIFY_HOLD_V2','FAILED_LIST'; ...
  'm07_failed_nested',                 @(r)edit(r,'EQ-soft2','COMPARISON.json','"failed": []','"failed": [["C1_KI"]]'), {}, 'VERIFY_HOLD_V2','FAILED_LIST'; ...
  'm08_failed_bare_string',            @(r)edit(r,'EQ-soft2','COMPARISON.json','"failed": []','"failed": "C1_KI"'),  {}, 'VERIFY_HOLD_V2','FAILED_LIST'; ...
  'm09_failed_duplicate_member',       @(r)edit(r,'EQ-soft2','COMPARISON.json','"failed": [],','"failed": [],"failed": [],'), {}, 'VERIFY_HOLD_V2','FAILED_LIST'; ...
  'm10_criterion_false_inconsistent',  @(r)edit(r,'EQ-H','COMPARISON.json','"C5_MTS": true','"C5_MTS": false'),      {}, 'VERIFY_HOLD_V2','CRITERION'; ...
  'm11_criterion_not_logical',         @(r)edit(r,'EQ-H','COMPARISON.json','"C1_KI": true','"C1_KI": 1'),           {}, 'VERIFY_HOLD_V2','not a logical scalar'; ...
  'm12_pass_flag_false',               @(r)edit(r,'EQ-stiff13','COMPARISON.json','"pass": true','"pass": false'),    {}, 'VERIFY_HOLD_V2','PASS'; ...
  'm13_metric_perturbed_1e-6',         @(r)perturb(r,'EQ-soft1','COMPARISON.json','dG_rel',1e-6),                    {}, 'VERIFY_HOLD_V2','METRIC: dG_rel'; ...
  'm14_metric_renamed',                @(r)edit(r,'EQ-soft1','COMPARISON.json','"dJ_rel"','"dJ_relX"'),               {}, 'VERIFY_HOLD_V2','METRIC_SET'; ...
  'm15_metric_null',                   @(r)nullify(r,'EQ-soft1','COMPARISON.json','dG_rel'),                          {}, 'VERIFY_HOLD_V2','not a finite numeric scalar'; ...
  'm16_manifest_file_deleted',         @(r)delf(r,'EQ-soft2','PHASE.mat.manifest.json'),                              {}, 'VERIFY_HOLD_V2','RECORD_SET'; ...
  'm17_extra_file',                    @(r)addf(r,'EQ-H','junk.txt'),                                                 {}, 'VERIFY_HOLD_V2','unexpected file'; ...
  'm18_solve_folder_missing',          @(r)delfolder(r,'EQ-soft1'),                                                  {}, 'VERIFY_HOLD_V2','missing'; ...
  'm19_mesh_link_broken',              @(r)edit(r,'EQ-H','COMPARISON.json','"meshSHA256": "3','"meshSHA256": "4'),    {}, 'VERIFY_HOLD_V2','LINKS'; ...
  'm20_manifest_sha_broken',           @(r)edit(r,'EQ-soft2','SOLUTION.mat.manifest.json','"SHA256": "7','"SHA256": "8'), {}, 'VERIFY_HOLD_V2','LINKS'; ...
  'm21_phase_file_modified',           @(r)appendbyte(r,'EQ-stiff13','PHASE.mat'),                                    {}, 'VERIFY_HOLD_V2','LINKS'; ...
  'm22_reference_detects_whitespace',  @(r)appendnl(r,'EQ-H','COMPARISON.json'),                                      ref, 'VERIFY_HOLD_V2','REFERENCE'};
 TB=struct('name',{},'expectOutcome',{},'outcome',{},'expectTag',{},'tagFound',{},'pass',{},'problems',{});
 for q=1:size(M,1)
  cd0=fullfile(tmp,'case');if isfolder(cd0),rmdir(cd0,'s');end;copyfile(base,cd0);
  M{q,2}(cd0);
  R=lp2a2_eq_closure_verify(execRepo,'RecordsRoot',cd0,M{q,3}{:});
  pr=strjoin(R.problems,' || ');tag=M{q,5};tf=isempty(tag)||contains(pr,tag);
  for k=1:numel(R.solves),pr=[pr ' || ' strjoin(R.solves(k).problems,' | ')];tf=tf||isempty(tag)||contains(pr,tag);end %#ok<AGROW>
  ok=strcmp(R.outcome,M{q,4})&&tf;
  TB(end+1)=struct('name',M{q,1},'expectOutcome',M{q,4},'outcome',R.outcome,'expectTag',tag,'tagFound',tf,'pass',ok,'problems',pr(1:min(600,numel(pr)))); %#ok<AGROW>
  fprintf('MUT %-38s expect %-15s got %-15s tag %d pass %d\n',M{q,1},M{q,4},R.outcome,tf,ok);
 end
 if isfolder(cd0),rmdir(cd0,'s');end;rmdir(base,'s');
 T.partB=TB;T.partBPassed=sum([TB.pass]);T.partBTotal=numel(TB);
end
T.physicalSolves=0;
fid=fopen(fullfile(outDir,'LP2A2_EQ_CLOSURE_TESTS.json'),'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);
fprintf('CLOSURE_TESTS partA %d/%d partB %d/%d\n',T.partAPassed,T.partATotal,T.partBPassed,T.partBTotal);
end

function [raw,Cm]=roundtripFile(S,tmp,nm)
% real file round trip: jsonencode -> fwrite -> fileread -> jsondecode
f=fullfile(tmp,['rt_' nm '.json']);fid=fopen(f,'w');fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);
raw=fileread(f);Cm=jsondecode(raw);delete(f);
end

function e=evalCase(nm,raw,Cm,rec,allowed,expect,whyTag)
Q=lp2a2_eq_failed_check(raw,Cm,rec,allowed);
if Q.rawOK&&Q.storedOK&&Q.recomputedOK&&Q.equal,got='equal';elseif Q.rawOK&&Q.storedOK&&Q.recomputedOK,got='mismatch';else,got='rejected';end
ok=strcmp(got,expect)&&(isempty(whyTag)||contains(Q.why,whyTag));
sc='(absent)';ss=[];leg=false;
if isfield(Cm,'failed'),sc=class(Cm.failed);ss=size(Cm.failed);fl=Cm.failed;
 try,leg=isequal(sort(rec(:)).',sort(fl(:)).');catch,leg=false;end
end
e=struct('name',nm,'expect',expect,'got',got,'pass',ok,'storedClass',sc,'storedSize',ss,'legacyIsequal',leg,'why',Q.why);
end

function p=fp(r,id,n),p=fullfile(r,id,n);end
function edit(r,id,n,a,b)
p=fp(r,id,n);s=fileread(p);assert(contains(s,a),'mutation anchor not found: %s',a);i=strfind(s,a);s=[s(1:i(1)-1) b s(i(1)+numel(a):end)];
fid=fopen(p,'w');fwrite(fid,s,'char');fclose(fid);
end
function perturb(r,id,n,key,rel)
p=fp(r,id,n);s=fileread(p);m=regexp(s,['"' key '"\s*:\s*(-?[0-9.eE+-]+)'],'tokens','once');v=str2double(m{1});
edit(r,id,n,['"' key '": ' m{1}],['"' key '": ' sprintf('%.17g',v*(1+rel)+rel*1e-3)]);
end
function nullify(r,id,n,key)
p=fp(r,id,n);s=fileread(p);m=regexp(s,['"' key '"\s*:\s*(-?[0-9.eE+-]+)'],'tokens','once');edit(r,id,n,['"' key '": ' m{1}],['"' key '": null']);
end
function delf(r,id,n),delete(fp(r,id,n));end
function delfolder(r,id,~),rmdir(fullfile(r,id),'s');end
function addf(r,id,n),fid=fopen(fp(r,id,n),'w');fwrite(fid,'x','char');fclose(fid);end
function appendbyte(r,id,n),fid=fopen(fp(r,id,n),'a');fwrite(fid,uint8(0),'uint8');fclose(fid);end
function appendnl(r,id,n),fid=fopen(fp(r,id,n),'a');fwrite(fid,10,'uint8');fclose(fid);end
