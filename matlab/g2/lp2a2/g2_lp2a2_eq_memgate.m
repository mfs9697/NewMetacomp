function M=g2_lp2a2_eq_memgate(minGiB,memfun)
%G2_LP2A2_EQ_MEMGATE  Physical-memory gate of the LP2-A2 equivalence solves (no FEM, no write).
%  M = g2_lp2a2_eq_memgate(7)          % actual helper: free physical RAM seen INSIDE MATLAB
%  M = g2_lp2a2_eq_memgate(7,@() 6.5)  % injected reading (tests only)
% The reading is sys.PhysicalMemory.Available/2^30 from [~,sys]=memory, the same field as the
% validated g2_lp0_preflight. Any query error or a non-finite / non-positive reading REFUSES
% (pass=false) with a reason; a reading below minGiB refuses; nothing is retried.
if nargin<2||isempty(memfun),memfun=@actualFreeGiB;end
M=struct('pass',false,'minGiB',minGiB,'freeGiB',NaN,'reason','');
try
 g=memfun();
catch ME
 M.reason=['MEMORY_QUERY_FAILED: ' ME.message];return
end
if ~(isnumeric(g)&&isscalar(g)&&isfinite(g)&&g>0),M.reason='MEMORY_QUERY_INVALID';return,end
M.freeGiB=double(g);
if M.freeGiB<minGiB,M.reason=sprintf('BELOW_THRESHOLD: %.3f GiB < %g GiB',M.freeGiB,minGiB);return,end
M.pass=true;M.reason='OK';
end

function g=actualFreeGiB()
[~,sys]=memory;g=sys.PhysicalMemory.Available/2^30;
end
