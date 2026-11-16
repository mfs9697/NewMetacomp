function R=run_g2_p010_isolated_batch()
%RUN_G2_P010_ISOLATED_BATCH  Pinned Cornell regular p010 + collar, NO PDE.
% Saves fresh geometry-only local evidence. Never edits successful parent
% Cornell 3-hole T3/T6 reference or its independent audit. No physics.
here=fileparts(mfilename('fullpath'));
repo=fileparts(fileparts(here));
vendor=fullfile(here,'vendor_p010_a14d8872');
addpath(vendor,'-begin');
actualMain=which('main_m1i_increment_ring_geometry_only');
actualT6=which('T3toT6_fast');
assert(strcmpi(actualMain,fullfile(vendor, ...
     'main_m1i_increment_ring_geometry_only.m')) && ...
     strcmpi(actualT6,fullfile(vendor,'T3toT6_fast.m')), ...
     'G2P010:VendorShadowed', ...
     'MATLAB must resolve both pinned vendor sources, not personal startup paths.');
outRoot=fullfile(repo,'outputs','g2_p010_isolated');
if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);
assert(~exist(folder,'dir'),'G2P010:OutputCollision', ...
 'Never overwrite a previous p010 experiment: %s',folder);
mkdir(folder);
diary(fullfile(folder,'batch_console.log'));
cleanup=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_P010_CORNELL_ISOLATED_REGULAR_BLOCK\n');
fprintf('DATE=%s\n',datestr(now,31));
fprintf('MATLAB_RELEASE=%s\n',version('-release'));
fprintf('PINNED_UPSTREAM_COMMIT=a14d8872ab588ac551e41b4531bffee2dcd0ce2c\n');
fprintf('PINNED_MAIN_SOURCE=%s\n',which('main_m1i_increment_ring_geometry_only'));
fprintf('PINNED_T3TO6_SOURCE=%s\n',which('T3toT6_fast'));
fprintf('OUTDIR=%s\n',folder);
fprintf('SOURCE_BVP_SOLVED=0\n');
fprintf('NO_NATIVE_PDE_REMESH=1\n');
fprintf('P010_GLOBAL_JOINED=0\n');
fprintf('CORNELL_THREE_HOLES_REQUIRED=1\n');
report=struct('pass',false,'stage','HOLD_NOT_RUN', ...
 'date',datestr(now,31),'outputDirectory',folder, ...
 'MATLABRelease',version('-release'), ...
 'pinnedUpstreamCommit','a14d8872ab588ac551e41b4531bffee2dcd0ce2c', ...
 'approvedForLEFM',false,'globalMeshQualified',false, ...
 'physicalSolvePerformed',false,'gates',struct(), ...
 'failedGates',{{}},'summary',struct(),'exception','');
R=struct('pass',false,'stage','HOLD_NOT_RUN');
try
 R=g2_p010_cornell_regular_block('Plot',true);
 report.pass=R.pass;
 report.stage=R.stage;
 report.gates=R.gates;
 report.failedGates=R.failedGates;
 report.summary=R.summary;
 if isfield(R,'figure')&&ishandle(R.figure)
     try
         exportgraphics(R.figure,fullfile(folder, ...
              'p010_regular_core_and_collar.png'),'Resolution',240);
         exportgraphics(R.figure,fullfile(folder, ...
              'p010_regular_core_and_collar.pdf'),'ContentType','vector');
         fprintf('P010_REGULAR_FIGURE=%s\n', ...
              fullfile(folder,'p010_regular_core_and_collar.png'));
     catch MEplot
         fprintf(2,'G2_P010_FIGURE_WARNING=%s\n',MEplot.message);
     end
     close(R.figure);R=rmfield(R,'figure');
 end
 if isfield(R,'tipZoomFigure')&&ishandle(R.tipZoomFigure)
     try
        exportgraphics(R.tipZoomFigure,fullfile(folder, ...
             'p010_inner_tip_zoom.png'),'Resolution',280);
        exportgraphics(R.tipZoomFigure,fullfile(folder, ...
             'p010_inner_tip_zoom.pdf'),'ContentType','vector');
        fprintf('P010_INNER_DISK_FIGURE=%s\n', ...
             fullfile(folder,'p010_inner_tip_zoom.png'));
     catch MEplot
        fprintf(2,'G2_P010_ZOOM_EXPORT_WARNING=%s\n',MEplot.message);
     end
     close(R.tipZoomFigure);R=rmfield(R,'tipZoomFigure');
 end
 if R.pass
     X3=R.coord3;T3=R.connect3; %#ok<NASGU>
     X6=R.coord6;T6=R.connect6; %#ok<NASGU>
     tipNode=R.tipNode; %#ok<NASGU>
     nodalQ=R.nodalQ; %#ok<NASGU>
     qActiveT6Rows=R.qActiveT6Rows; %#ok<NASGU>
     sourceP010=R.sourceP010; %#ok<NASGU>
     summary=R.summary;gates=R.gates; %#ok<NASGU>
     save(fullfile(folder,'P010_ISOLATED_REGULAR_ONLY.mat'), ...
        'X3','T3','X6','T6','tipNode','nodalQ','qActiveT6Rows', ...
        'sourceP010','summary','gates','-v7.3');
     fprintf('G2_P010_ISOLATED_REGULAR_MAT=%s\n', ...
          fullfile(folder,'P010_ISOLATED_REGULAR_ONLY.mat'));
 end
catch ME
 report.stage='HOLD_P010_ISOLATED_EXCEPTION';
 report.pass=false;
 report.exception=getReport(ME,'extended','hyperlinks','off');
 fprintf(2,'G2_P010_EXCEPTION=%s\n',report.exception);
end
jsonFile=fullfile(folder,'p010_isolated_summary.json');
f=fopen(jsonFile,'w');
assert(f>=0,'G2P010:NoJSONOutput', ...
 'Cannot write isolated P010 evidence report to %s.',jsonFile);
fwrite(f,jsonencode(report,'PrettyPrint',true),'char');
fclose(f);
fprintf('G2_P010_ISOLATED_SUMMARY=%s\n',jsonFile);
fprintf('G2_P010_ISOLATED_RESULT_PASS=%d\n',report.pass);
fprintf('G2_P010_GLOBAL_LEFM_APPROVAL=0\n');
if ~report.pass
 error('G2P010:IsolatedGeometryHOLD', ...
    'Frozen p010 / Cornell-specific isolated geometry HOLD: %s; see %s', ...
    report.stage,jsonFile);
end
fprintf('G2_P010_ISOLATED_DONE=1; CONFORMING_GLOBAL_JOIN_PENDING=1; NO_LEFM=1\n');
end
