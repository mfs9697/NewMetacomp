function lp2a2_eq_opening_export(ex,outDir)
%LP2A2_EQ_OPENING_EXPORT  READ-ONLY export of the crack-face jump profiles of the LP2-A2 equivalence
% records (new family) and the archived LP2-A1 S8 solutions, for the comparison figures.
% Same definitions as g2_lp2a2_eq_compare: jump |u_U - u_L| and signed normal opening (u_U - u_L).n at the
% paired bank stations; archived values interpolated linearly in arc length onto the new stations.
% Writes <outDir>/LP2A2_EQ_A2_OPENING_<solveId>.csv (s_mm, distToTip_mm, jumpNew, jumpArchivedInterp,
% signedNew, signedArchivedInterp). No solve; nothing written under the execution clone.
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
C=g2_lp2a2_eq_context('Preflight',false);pol=C.policy;root=fullfile(C.repo,pol.outputRoot);
for k=1:numel(pol.solves)
 s=pol.solves(k);sd=fullfile(root,s.id);
 Sx=load(fullfile(sd,'SOLUTION.mat'));Sx=Sx.record;D=load(fullfile(sd,'MESH.mat'));
 ab=fullfile(C.archiveBase,s.caseId);So=load(fullfile(ab,'S8','SOLUTION.mat'));So=So.record;Ma=load(fullfile(ab,'S8','MESH.mat'));
 [sN,jN,xN,gN]=jumps(D,Sx.K.u);[sA,jA,~,gA]=jumps(Ma,So.K.u);tip=D.crackPolyline(end,:);
 T=table(sN,vecnorm(xN-tip,2,2),jN,interp1(sA,jA,sN,'linear'),gN,interp1(sA,gA,sN,'linear'), ...
  'VariableNames',{'s_mm','distToTip_mm','jumpNew_mm','jumpArchivedInterp_mm','signedNew_mm','signedArchivedInterp_mm'});
 writetable(T,fullfile(outDir,sprintf('LP2A2_EQ_A2_OPENING_%s.csv',s.id)));
 fprintf('OPEN %s stations new %d archived %d max|dj|/max j %.3g\n',s.id,numel(sN),numel(sA),max(abs(T.jumpNew_mm-T.jumpArchivedInterp_mm))/max(jN));
end
end

function [s,j,x,g]=jumps(D,u)
U=reshape(u,2,[]).';up=D.upperBankT6(:);lo=D.lowerBankT6(:);P=D.crackPolyline;
x=D.X6(up,:);[s,kq]=station(x,P);[s,o]=sort(s);up=up(o);x=x(o,:);kq=kq(o);
sl=station(D.X6(lo,:),P);[~,o]=sort(sl);lo=lo(o);
J=U(up,:)-U(lo,:);j=vecnorm(J,2,2);
tt=diff(P);tt=tt./vecnorm(tt,2,2);nn=[-tt(:,2),tt(:,1)];g=sum(J.*nn(kq,:),2);
end

function [s,k]=station(X,P)
tt=diff(P);L=vecnorm(tt,2,2);tt=tt./L;Sv=[0;cumsum(L)];M=size(X,1);dk=inf(M,numel(L));lk=dk;
for q=1:numel(L),l=max(0,min(L(q),(X-P(q,:))*tt(q,:).'));dk(:,q)=vecnorm(X-(P(q,:)+l*tt(q,:)),2,2);lk(:,q)=l;end
[~,k]=min(dk,[],2);s=Sv(k)+lk(sub2ind(size(lk),(1:M)',k));
end
