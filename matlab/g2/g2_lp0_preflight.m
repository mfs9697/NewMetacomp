function R=g2_lp0_preflight()
% Read-only: no startup of another MATLAB, no temp file, mesh, FEM or record.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pfile=fullfile(here,'G2_LP1_POLICY_v1.json');pol=jsondecode(fileread(pfile));
R=struct('pass',false,'status','HOLD_LP0_FEASIBILITY','cause','','physicalSolves',0,'meshBuilds',0);
R.policySHA256=lower(g2_sha256_file(pfile));R.release=['R',version('-release')];
R.pdeAvailable=~isempty(ver('pde'))&&exist('createpde','file')~=0;
[~,sys]=memory;R.freePhysicalRAM_GiB=sys.PhysicalMemory.Available/2^30;
try,pp=System.Diagnostics.Process.GetProcessesByName('MATLAB');R.matlabProcesses=pp.Length;
catch,R.matlabProcesses=NaN;end
[s,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));R.sourceCommit=strtrim(h);
[sd,d]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',repo));R.dirtySource=strtrim(d);
if s~=0||sd~=0||~isempty(R.dirtySource),R.cause='HOLD_SOURCE';return,end
if ~strcmp(R.release,pol.resources.matlabRelease)||~R.pdeAvailable,R.cause='HOLD_INPUT';return,end
if R.matlabProcesses~=1,R.cause='HOLD_SOURCE';return,end
if R.freePhysicalRAM_GiB<pol.resources.freePhysicalRAM_GiB_min,R.cause='HOLD_MEMORY';return,end
lockfile=fullfile(here,'G2_LP0_SOURCE_LOCK_v1.json');
if ~strcmpi(g2_sha256_file(lockfile),pol.sourceLockSHA256),R.cause='HOLD_POLICY_DRIFT';return,end
lock=jsondecode(fileread(lockfile));
% Different entry schemas deliberately handled separately.
for group={'legacy','acceptedInputs'}
 entries=lock.(group{1});
 for k=1:numel(entries)
  f=fullfile(repo,entries(k).file);
  if ~isfile(f),R.cause='HOLD_INPUT';R.failedFile=entries(k).file;return,end
  if ~strcmpi(g2_sha256_file(f),entries(k).sha256),R.cause='HOLD_SOURCE';R.failedFile=entries(k).file;return,end
 end
end
R.token=sprintf('G2LP0|policy=%s|source=%s|geometry=%s|cases=H,stiff13,soft2,soft1|maxState=4', ...
 R.policySHA256,R.sourceCommit,lower(g2_sha256_file(fullfile(repo,'docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json'))));
R.pass=true;R.status='PREFLIGHT_READY_NOT_LP0_QUALIFIED';
end
