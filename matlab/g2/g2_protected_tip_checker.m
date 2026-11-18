function C = g2_protected_tip_checker(data, geometryFile, p0File)
%G2_PROTECTED_TIP_CHECKER  Independent protected-p010 audit of a SAVED joined mesh.
%
% Complements the unchanged 38-gate g2_independent_t6_checker (which checks the
% global T3/T6 topology, quality, boundary loops and crack banks) with the
% protected-tip conditions of Issue #20 WP1. It reads only saved arrays, the
% pinned Cornell JSON and the immutable isolated-P0 evidence MAT; it does not
% call the mesher, the join or the p010 builders, and it does not modify input.
%
%  C = g2_protected_tip_checker(load(joinedMAT), jsonPath, p0MAT)
%
% Millimetres. Geometry only: a PASS is not an LEFM permit.
req={'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ'};
assert(isstruct(data)&&all(isfield(data,req)),'G2Prot:MissingData','Joined MAT lacks required fields.');
J=jsondecode(fileread(geometryFile));
assert(strcmp(J.schema,'NewMetacomp.G2.IngraffeaGrigoriu1990.Specimen1.nominal.v1'),'G2Prot:Schema','Wrong JSON.');
Gm=J.nominal_geometry_mm;
P0=load(p0File,'X3','T3','nodalQ','qActiveT6Rows');
X3=data.X3;T3=data.T3;X6=data.X6;T6=data.T6;tipID=data.physicalTipNode;
tip=Gm.initial_crack.tip(:).';cx=tip(1);
rc=3;ro=3.3;tol=1e-9;
centers=zeros(3,2);radii=zeros(3,1);
for k=1:3,centers(k,:)=Gm.holes(k).center(:).';radii(k)=Gm.holes(k).radius;end
g=struct();
% 1. the frozen kernel + collar are present unchanged (exact arrays of the P0 evidence)
nb=size(P0.X3,1);mb=size(P0.T3,1);
g.p0EvidenceIs2788Plus128=mb==2916;
g.kernelAndCollarArraysIdenticalToP0Evidence=size(X3,1)>=nb&&size(T3,1)>=mb&& ...
    isequal(X3(1:nb,:),P0.X3)&&isequal(T3(1:mb,:),P0.T3);
% 2. single physical tip and the six-triangle tip fan of the kernel
tipIDs=find(vecnorm(X3-tip,2,2)<tol);
fan=find(any(T3==tipID,2));
nbr=unique(T3(fan,:));nbr(nbr==tipID)=[];
firstEdge=min(vecnorm(X3(nbr,:)-tip,2,2));
g.singleTipNodeAtNominalTip=isscalar(tipIDs)&&tipIDs==tipID;
g.tipFanSixTrianglesSevenNeighbours=numel(fan)==6&&numel(nbr)==7&&all(fan<=2788);
g.firstTipEdgeIsScaledP010Pitch=abs(firstEdge-.1*3/7.2)<1e-9;
% 3. protected region: exactly the 2,916 block elements lie inside r <= 3.3,
%    and no non-block node lies strictly inside the collar rim
r3=vecnorm(X3-tip,2,2);
cen=(X3(T3(:,1),:)+X3(T3(:,2),:)+X3(T3(:,3),:))/3;
rcen=vecnorm(cen-tip,2,2);
inside=find(rcen<ro);
g.exactly2916ElementsInsideCollarRim=isequal(inside,(1:mb)');
g.blockElementsWithinRim=all(max(r3(T3(1:mb,:)),[],2)<=ro+tol);
g.noExteriorNodeInsideRim=all(r3(nb+1:end)>ro-tol);
% 4. seams: 64 edges on r = 3 and 64 edges on r = 3.3, each with exactly two
%    owners on opposite sides (inner/outer centroid)
raw=sort([T3(:,[1 2]);T3(:,[2 3]);T3(:,[3 1])],2);
[E,~,ic]=unique(raw,'rows');
cnt=accumarray(ic,1);
own=repmat((1:size(T3,1))',3,1);
o1=accumarray(ic,own,[],@min);o2=accumarray(ic,own,[],@max);
seam=@(rad)find(all(abs(r3(E)-rad)<1e-9,2));
s3=seam(rc);s33=seam(ro);
twoSided=@(s,rad)all(cnt(s)==2)&&all(min(rcen(o1(s)),rcen(o2(s)))<rad)&&all(max(rcen(o1(s)),rcen(o2(s)))>rad);
g.coreRimSeam64EdgesTwoOwnersOppositeSides=numel(s3)==64&&twoSided(s3,rc);
g.collarRimSeam64EdgesTwoOwnersOppositeSides=numel(s33)==64&&twoSided(s33,ro);
g.rim65NodeIdentitiesAt3p3=numel(find(abs(r3-ro)<1e-9))==65;
g.ring65NodeIdentitiesAt3p0=numel(find(abs(r3-rc)<1e-9))==65;
% chords: every r = 3.3 seam edge spans exactly one 64th of the circle
ang=@(p)atan2(p(:,2)-tip(2),p(:,1)-tip(1));
dth=abs(angle(exp(1i*(ang(X3(E(s33,1),:))-ang(X3(E(s33,2),:))))));
g.rimSeamEdgesAreSingleChords=numel(s33)==64&&max(abs(dth-2*pi/64))<1e-9;
% 5. crack banks inside the protected region: two IDs per position, tip once
onSlit=find(abs(X6(:,1)-cx)<tol&X6(:,2)<tip(2)-tol&X6(:,2)>tip(2)-ro-tol);
[~,~,grp]=unique(round(X6(onSlit,2)/1e-9));
U=data.upperBankT6(:);L=data.lowerBankT6(:);
g.protectedSlitPositionsHaveTwoNodeIDs=~isempty(onSlit)&&all(accumarray(grp,1)==2);
g.protectedSlitNodesSplitBetweenBanks=all(ismember(onSlit,union(U,L)))&& ...
    numel(intersect(onSlit,U))==numel(intersect(onSlit,L));
g.banksShareOnlyTheTip=isequal(intersect(U,L),tipID);
% 6. FE-nodal q recomputed independently (0.4 .. 2.6 mm) and its support
r6=vecnorm(X6-tip,2,2);
q=ones(size(r6));q(r6>=2.6)=0;tr=r6>.4&r6<2.6;q(tr)=(2.6-r6(tr))/(2.6-.4);
act=find(max(q(T6),[],2)-min(q(T6),[],2)>1e-14);
g.nodalQEqualsIndependentRecomputation=max(abs(q-data.nodalQ))<1e-14;
g.qActive2443ParentsAllInKernel=numel(act)==2443&&all(act<=2788)&&isequal(act,P0.qActiveT6Rows(:));
g.qSupportStrictlyInsideCoreInradius=max(r6(unique(T6(act,:))))<rc*cos(pi/64);
g.qZeroOnCollarAndExterior=all(q(unique(T6(2789:end,:)))==0);
% 7. clearance of the protected region from true holes, guides and plate
d=vecnorm(centers-tip,2,2);
g.protectedRegionClearOfTrueHoles=all(d-radii>ro);
g.protectedRegionClearOfGuideCircles=all(d-3*radii>ro);
g.protectedRegionInsidePlate=tip(2)-Gm.plate.y_range(1)>ro&&tip(1)-Gm.plate.x_range(1)>ro&& ...
    Gm.plate.x_range(2)-tip(1)>ro&&Gm.plate.y_range(2)-tip(2)>ro;
% 8. local quality inside and across the protected region (same thresholds)
h=max([vecnorm(X3(T3(:,2),:)-X3(T3(:,1),:),2,2),vecnorm(X3(T3(:,3),:)-X3(T3(:,2),:),2,2), ...
       vecnorm(X3(T3(:,1),:)-X3(T3(:,3),:),2,2)],[],2);
nearRim=find(cnt==2&(rcen(o1)<ro+2|rcen(o2)<ro+2));
rr=max(h(o1(nearRim))./h(o2(nearRim)),h(o2(nearRim))./h(o1(nearRim)));
g.neighbourRatioWithin2mmOfRimAtMost1p8=max(rr)<=1.8;
v=cell2mat(struct2cell(g));
f=fieldnames(g);
C=struct('pass',all(v),'stage','HOLD_PROTECTED_TIP','gates',g,'gatesPassed',nnz(v), ...
 'gatesTotal',numel(v),'failedGates',{f(~v)},'approvedForLEFM',false, ...
 'summary',struct('kernelNodes',nb,'blockElements',mb,'tipFanTriangles',numel(fan), ...
   'firstTipEdge_mm',firstEdge,'coreSeamEdges',numel(s3),'rimSeamEdges',numel(s33), ...
   'protectedSlitNodes',numel(onSlit),'qActive',numel(act), ...
   'qSupportMaxRadius_mm',max(r6(unique(T6(act,:)))),'maxRatioNearRim',max(rr), ...
   'holeWallMarginBeyondRim_mm',min(d-radii)-ro,'guideMarginBeyondRim_mm',min(d-3*radii)-ro));
if C.pass,C.stage='PROTECTED_TIP_AUDIT_PASS';end
fprintf('G2_PROTECTED_TIP_GATES=%d/%d\n',C.gatesPassed,C.gatesTotal);
fprintf('G2_PROTECTED_TIP_PASS=%d\n',C.pass);
if ~C.pass,fprintf(2,'G2_PROTECTED_TIP_HOLD=%s\n',strjoin(C.failedGates,','));end
end
