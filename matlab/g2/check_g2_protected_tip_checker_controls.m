function T=check_g2_protected_tip_checker_controls(meshRunDir,p0RunDir,unprotectedRunDir)
%CHECK_G2_PROTECTED_TIP_CHECKER_CONTROLS  Negative controls for the WP1 audits.
% Each control corrupts a COPY of the saved joined mesh in memory (files are
% never modified) and requires the named checker gate(s) to FAIL. The
% unmodified joined mesh must pass. Optionally the original UNPROTECTED
% 38/38 candidate must fail the protected-tip checker.
json=fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'docs','research', ...
    'crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
p0=fullfile(char(p0RunDir),'P010_ISOLATED_REGULAR_ONLY.mat');
D0=load(fullfile(char(meshRunDir),'GEOMETRY_ONLY_candidate.mat'));
tip=D0.X3(D0.physicalTipNode,:);
rows={};
% control 0: unmodified mesh passes both checkers
c=g2_protected_tip_checker(D0,json,p0);c38=g2_independent_t6_checker(D0,json);
rows(end+1,:)={'unmodified joined mesh',c.pass&&c38.pass,'both PASS'};
% control 1: an exterior node moved inside the collar rim
D=D0;r=vecnorm(D.X3-tip,2,2);ext=find(r>3.3+1e-6&r<4);k=ext(1);
D.X3(k,:)=tip+(D.X3(k,:)-tip)*3.25/r(k);D.X6(k,:)=D.X3(k,:);
c=g2_protected_tip_checker(D,json,p0);
rows(end+1,:)={'exterior node pulled to r = 3.25 mm',~c.gates.noExteriorNodeInsideRim,'noExteriorNodeInsideRim FAIL'};
% control 2: crack banks welded at one protected-slit station
D=D0;U=D.upperBankT6;L=D.lowerBankT6;
cand=intersect(U(1:end-1),1:size(D.X3,1));
y=D.X3(cand,2);sel=cand(y>tip(2)-3.3&y<tip(2)-.5);u=sel(1);
twin=L(vecnorm(D.X6(L,:)-D.X6(u,:),2,2)<1e-9);
D.T3(D.T3==twin)=u;D.T6(D.T6==twin)=u;
c=g2_protected_tip_checker(D,json,p0);c38=g2_independent_t6_checker(D,json);
rows(end+1,:)={'banks welded inside the protected region',~c.pass&&~c38.pass,'both HOLD'};
% control 3: corrupted nodal q
D=D0;D.nodalQ(end)=.5;
c=g2_protected_tip_checker(D,json,p0);
rows(end+1,:)={'one nodal q value changed',~c.gates.nodalQEqualsIndependentRecomputation,'nodalQ gate FAIL'};
% control 4: kernel coordinates perturbed by 1e-6 mm
D=D0;D.X3(5,1)=D.X3(5,1)+1e-6;
c=g2_protected_tip_checker(D,json,p0);
rows(end+1,:)={'kernel node moved by 1e-6 mm',~c.gates.kernelAndCollarArraysIdenticalToP0Evidence,'kernel identity FAIL'};
% control 5: the original unprotected 38/38 candidate
if nargin>2&&~isempty(unprotectedRunDir)
 Du=load(fullfile(char(unprotectedRunDir),'GEOMETRY_ONLY_candidate.mat'));
 if ~isfield(Du,'nodalQ'),Du.nodalQ=zeros(size(Du.X6,1),1);end
 c=g2_protected_tip_checker(Du,json,p0);
 rows(end+1,:)={'original UNPROTECTED candidate',~c.pass,sprintf('HOLD (%d/%d gates)',c.gatesPassed,c.gatesTotal)};
end
T=cell2table(rows,'VariableNames',{'control','expectedOutcome','expectation'});
disp(T);
fprintf('G2_WP1_NEGATIVE_CONTROLS=%d/%d\n',nnz(T.expectedOutcome),height(T));
assert(all(T.expectedOutcome),'G2Controls:Failed','A negative control did not behave as expected.');
end
