function R = run_g2_specimen1_pencil_batch()
%RUN_G2_SPECIMEN1_PENCIL_BATCH  Headless 3-hole pencil/collapse CAD pilot.
%
% Called by MATLAB R2023a:
%   matlab -batch "addpath('C:/.../NewMetacomp/matlab/g2');run_g2_specimen1_pencil_batch"
%
% This job has ZERO physics: NO K/G, stiffness, solve, propagation.
% A candidate-geometry PASS is NOT an accepted p010 LEFM mesh.
here=fileparts(mfilename('fullpath'));
repoRoot=fileparts(fileparts(here));
outRoot=fullfile(repoRoot,'outputs','g2_specimen1_pencil');
if ~exist(outRoot,'dir'),mkdir(outRoot);end
runName=['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')];
folder=fullfile(outRoot,runName);
assert(~exist(folder,'dir'),'G2:OutputDirectoryExists', ...
 'Refusing to overwrite an existing evidence directory.');
mkdir(folder);
diaryFile=fullfile(folder,'batch_console.log');
diary(diaryFile);
cleanDiary=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_SPECIMEN1_PENCIL_GEOMETRY_ONLY\n');
fprintf('DATE=%s\n',datestr(now,31));
fprintf('MATLAB_VERSION=%s\n',version);
fprintf('MATLAB_RELEASE=%s\n',version('-release'));
fprintf('SOURCE_FILE=%s\n',mfilename('fullpath'));
fprintf('OUTDIR=%s\n',folder);
fprintf('PHYSICAL_SOLVE=NO\n');
summary=struct('stage','NOT_RUN','pass',false, ...
    'approvedForLEFM',false,'sourceFile',mfilename('fullpath'), ...
    'MATLABRelease',version('-release'),'folder',folder, ...
    'error','','geometry',struct());
try
   probe=g2_pde_toolbox_preflight();
   summary.environment=probe;
   fprintf('PDE_MODEL_CLASS=%s\n',probe.modelClass);
   fprintf('PDE_TOOLBOX_VERSION=%s\n',probe.PDEToolboxVersion);
   for k=1:numel(probe.failedChecks)
       fprintf(2,'PDE_PREFLIGHT_FAILURE_%d=%s\n',k,probe.failedChecks{k});
   end
   fprintf('PDE_PREFLIGHT_PASS=%d\n',probe.pass);
   if ~probe.pass
       error('G2:PDEToolboxUnavailable', ...
           'Required PDE capability missing: %s', ...
           strjoin(probe.failedChecks,'; '));
   end
   R=g2_specimen1_pencil_mesh('Plot',true);
   summary.stage=R.stage;
   summary.pass=R.pass;
   summary.approvedForLEFM=R.approvedForLEFM;
   summary.geometry=R.summary;
   summary.message=R.message;
   if isfield(R,'qualityForensics')
       summary.qualityForensics=R.qualityForensics;
       qFile=fullfile(folder,'quality_forensics.json');
       fq=fopen(qFile,'w');
       assert(fq>=0,'G2:CannotWriteForensics', ...
           'Cannot write quality evidence: %s',qFile);
       fwrite(fq,jsonencode(R.qualityForensics,'PrettyPrint',true),'char');
       fclose(fq);
       fprintf('QUALITY_FORENSICS_JSON=%s\n',qFile);
   end
   if isfield(R,'forensicFigure')&&ishandle(R.forensicFigure)
       try
           exportgraphics(R.forensicFigure, ...
               fullfile(folder,'quality_worst_edge_zoom.pdf'), ...
               'ContentType','vector');
           exportgraphics(R.forensicFigure, ...
               fullfile(folder,'quality_worst_edge_zoom.png'), ...
               'Resolution',220);
       catch plotError
           fprintf(2,'QUALITY_PLOT_EXPORT_WARNING=%s\n',plotError.message);
       end
       close(R.forensicFigure);
       R=rmfield(R,'forensicFigure');
   end
   if isfield(R,'figure')&&ishandle(R.figure)
       try
           exportgraphics(R.figure, ...
               fullfile(folder,'mesh_candidate_overview.pdf'), ...
               'ContentType','vector');
           exportgraphics(R.figure, ...
               fullfile(folder,'mesh_candidate_overview.png'), ...
               'Resolution',220);
       catch plotError
           fprintf(2,'PLOT_EXPORT_WARNING=%s\n',plotError.message);
       end
       close(R.figure);
       R=rmfield(R,'figure');
   end
   if R.pass
       X3=R.coord3;T3=R.connect3; %#ok<NASGU>
       X6=R.coord6;T6=R.connect6; %#ok<NASGU>
       upperBankT6=R.bankUpperT6; %#ok<NASGU>
       lowerBankT6=R.bankLowerT6; %#ok<NASGU>
       physicalTipNode=R.physicalTipNode; %#ok<NASGU>
       geometryOnly=true;approvedForLEFM=false; %#ok<NASGU>
       save(fullfile(folder,'GEOMETRY_ONLY_candidate.mat'), ...
           'X3','T3','X6','T6','upperBankT6', ...
           'lowerBankT6','physicalTipNode','geometryOnly', ...
           'approvedForLEFM','-v7.3');
       fprintf('CANDIDATE_GEOMETRY_PASS=1\n');
       fprintf('P010_PROTECTED_CORE_QUALIFIED=0\n');
       fprintf('FEM_ADMISSIBLE=0\n');
   else
       fprintf(2,'CANDIDATE_GEOMETRY_PASS=0\n');
       fprintf(2,'HOLD_STAGE=%s\n',R.stage);
       fprintf(2,'HOLD_REASON=%s\n',R.message);
   end
catch ME
   summary.stage='HOLD_EXCEPTION';
   summary.error=getReport(ME,'extended','hyperlinks','off');
   fprintf(2,'G2_BATCH_EXCEPTION=%s\n',summary.error);
end
summaryFile=fullfile(folder,'batch_summary.json');
fid=fopen(summaryFile,'w');
assert(fid>=0,'G2:CannotWriteSummary', ...
    'Unable to write batch_summary.json: %s',summaryFile);
fwrite(fid,jsonencode(summary,'PrettyPrint',true),'char');
fclose(fid);
fprintf('SUMMARY_JSON=%s\n',summaryFile);
if ~summary.pass
 error('G2:BatchGeometryHOLD', ...
    'Geometry-only stage did not pass. See %s',summaryFile);
end
fprintf(['G2_CANDIDATE_DONE=1; SOURCE_P010_PENDING=1; ', ...
 'NO_ELASTICITY_SOLVE=1\n']);
end
