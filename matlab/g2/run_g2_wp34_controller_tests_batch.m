function W=run_g2_wp34_controller_tests_batch(tag)
%RUN_G2_WP34_CONTROLLER_TESTS_BATCH  WP3.4 stage B: synthetic (B1-B6) and fault (F01-F23) suites.
%  W = run_g2_wp34_controller_tests_batch(tag)
% Writes a NEW outputs/g2_wp34_controller/run_<time>_<tag>/ with the console log, the
% disposable fault-test work tree and controller_tests_summary.json. No mesh, no FEM.
% Errors at the end (MATLAB exit 1) unless both suites pass.
if nargin<1,tag='run';end
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
outRoot=fullfile(repo,'outputs','g2_wp34_controller');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF'),'_',char(tag)]);
assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'controller_tests_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
[~,head]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
[~,dirty]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all -- matlab/g2',repo));
v=ver('pde');
fprintf('STAGE=G2_WP34_B_CONTROLLER_TESTS\nDATE=%s\nMATLAB_RELEASE=%s\nMATLAB_VERSION=%s\nPDE_TOOLBOX=%s\nGIT_HEAD=%s\nG2_TREE_DIRTY=%d\n', ...
 datestr(now,31),version('-release'),version,v(1).Version,strtrim(head),~isempty(strtrim(dirty)));
W=struct('tag',char(tag),'gitHead',strtrim(head),'matlabRelease',version('-release'),'pass',false, ...
 'synthetic',struct(),'syntheticException','','faults',struct(),'faultsException','');
try
 W.synthetic=check_g2_trajectory_controller();
catch ME
 W.syntheticException=getReport(ME,'extended','hyperlinks','off');fprintf(2,'SYNTHETIC_EXCEPTION=%s\n',W.syntheticException);
end
try
 W.faults=check_g2_trajectory_faults(fullfile(folder,'faults'));
catch ME
 W.faultsException=getReport(ME,'extended','hyperlinks','off');fprintf(2,'FAULTS_EXCEPTION=%s\n',W.faultsException);
end
W.pass=isfield(W.synthetic,'pass')&&W.synthetic.pass&&isfield(W.faults,'pass')&&W.faults.pass;
f=fopen(fullfile(folder,'controller_tests_summary.json'),'w');fwrite(f,jsonencode(W,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_WP34_CONTROLLER_TESTS_PASS=%d\nOUTDIR=%s\n',W.pass,folder);
if ~W.pass,error('G2WP34:ControllerTestsHOLD','WP3.4 stage B HOLD (see %s).',folder);end
end
