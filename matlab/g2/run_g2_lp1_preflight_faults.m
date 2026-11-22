function R=run_g2_lp1_preflight_faults()
% Exercise the actual preflight with a low-memory observation; no allocation/FEM.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
before=g2_lp0_preflight();assert(before.pass,'G2LP1Fault:Environment','Start clean and ready.');
folder=fullfile(repo,'outputs',['lp1_memory_fault_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);mkdir(folder);
mock=fullfile(folder,'memory.m');fid=fopen(mock,'w');assert(fid~=-1);
fprintf(fid,'function [u,s]=memory\nu=struct();s=struct(''PhysicalMemory'',struct(''Available'',2*2^30));\nend\n');fclose(fid);
cleanup=onCleanup(@()rmpath(folder));addpath(folder,'-begin');
assert(strcmp(which('memory'),mock),'G2LP1Fault:Shadow','Fault injection is not active.');
low=g2_lp0_preflight();assert(~low.pass&&strcmp(low.cause,'HOLD_MEMORY')&&low.freePhysicalRAM_GiB==2);
clear cleanup
after=g2_lp0_preflight();assert(after.pass,'G2LP1Fault:Cleanup','Preflight did not recover after observation injection.');
sentinel=fullfile(here,'LP1_DIRTY_SENTINEL.txt');assert(~isfile(sentinel));
fid=fopen(sentinel,'w');fprintf(fid,'intentional dirty-source negative');fclose(fid);
cleanup=onCleanup(@()delete(sentinel));dirty=g2_lp0_preflight();
assert(~dirty.pass&&strcmp(dirty.cause,'HOLD_SOURCE'));clear cleanup
final=g2_lp0_preflight();assert(final.pass);
R=struct('pass',true,'lowMemoryRejected',true,'dirtySourceRejectedFromCleanBaseline',true, ...
 'memoryObservationInjected_GiB',2,'guard_GiB',5,'before',before,'low',low,'after',after,'dirty',dirty,'final',final, ...
 'physicalSolves',0,'meshBuilds',0,'largeAllocations',0);
fid=fopen(fullfile(repo,'outputs/g2_lp0_20261122/PREFLIGHT_FAULTS.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('LP1_PREFLIGHT_FAULTS low_RAM=1 dirty_source=1 cleanup=1 NO_FEM=1\n');
end
