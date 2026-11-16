function P = build_m1i_trial_tip_annulus_p010(varargin)
%BUILD_M1I_TRIAL_TIP_ANNULUS_P010  New geometry-only 0.1mm disk + frozen 7.2mm annulus.
% Preserves EXACT historical literal 64-sector 2mm->7.2mm outer ring
% geometry and T3 connectivity, and original topology mapping at the
% 2mm disk/annulus seam. ONLY substitutes the separately verified trial
% 0.1mm first-ring reflected disk for the original 0.2mm frozen disk.
% No original builder, actual historical mesh, PDE, K0, solve, EDI, COD
% or crack path is altered by calling this new experimental function.
% Source-compatible deterministic disk (0--2 mm by default) and regular
% 64-sector Step4B annulus (2--20 mm by default).
% Optional smaller even-ring annulus is a geometry-only experiment.
% The unchanged 20-mm/30-ring default remains the reference.
% This routine performs NO physical FEM, EDI, SIF or crack advancement.
%
% Recovered source: CrackFromHoleLEFM PR #1, sif-asymmetric-mesh-audit,
% build_literal_ring_lattice.m and cut_negative_x_ray_t3.m.
ip=inputParser;
addParameter(ip,'InnerRadius',.002,@(x)isnumeric(x)&&isscalar(x)&&x>0);
addParameter(ip,'OuterRadius',.020,@(x)isnumeric(x)&&isscalar(x)&&x>0);
addParameter(ip,'Htip',.0001,@(x)isnumeric(x)&&isscalar(x)&&x>0);
addParameter(ip,'Ntheta',64,@(x)isnumeric(x)&&isscalar(x)&&x==64);
addParameter(ip,'RadialIntervals',30, ...
    @(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=2&&x==round(x));
parse(ip,varargin{:});c=ip.Results;
assert(c.OuterRadius>c.InnerRadius && c.InnerRadius>=4*c.Htip, ...
       'twohole:CoreSizes','Invalid interior/annular scale.');
assert(mod(c.RadialIntervals,2)==0,'twohole:OddRings', ...
    'Outer ring must return to unshifted phase for a clean exterior seam.');

[original,ai]=build_twohole_literal_annulus( ...
    'r0',c.InnerRadius,'r1',c.OuterRadius, ...
    'Ntheta',c.Ntheta,'NrOverride',c.RadialIntervals);
assert(ai.Nr==c.RadialIntervals&&ai.Ntheta==c.Ntheta, ...
       'twohole:WrongLiteralLattice', ...
       'Unexpected ring count or angular resolution for requested patch.');
[cutMesh,cut]=cut_twohole_literal_annulus(original);
assert(numel(cut.crackUpperIDs)>1&& ...
       numel(cut.crackUpperIDs)==numel(cut.crackLowerIDs), ...
       'twohole:CutMismatch','Original negative-x annulus cut failed.');

% Fill the annular hole with mirrored near-equilateral triangular lattice.
% The FIRST 64 original annulus IDs are the inner polygon.
assert(abs(c.InnerRadius-.002)<1e-12 && ...
       abs(c.OuterRadius-.0072)<1e-12 && ...
       abs(c.Htip-.0001)<1e-12 && ...
       c.Ntheta==64 && c.RadialIntervals==16, ...
       'm1iTrialPatch:FixedGeometryPilotOnly', ...
       'The isolated trial is strictly 0.1mm disk and original 7.2mm/16-ring annulus.');
D=build_m1i_trial_tip_disk_p010('Radius',c.InnerRadius,'Pitch',c.Htip);
D.ringUpperIDs=D.outerUpperIDs;
D.ringLowerIDs=D.outerLowerIDs;
D.upperNodeCount=D.nUpper;
Xd=D.coord3;Td=D.connect3;
map=zeros(size(Xd,1),1);
for k=1:33
    map(D.ringUpperIDs(k))=k;
end
for k=2:32
    % Reflection of theta=(k-1)*2*pi/64 has original index 66-k.
    map(D.ringLowerIDs(k))=66-k;
end
leftLower=cut.crackLowerIDs( ...
    abs(cutMesh.coord3(cut.crackLowerIDs,1)+c.InnerRadius)<1e-12);
assert(numel(leftLower)==1,'twohole:MissingLeftEntry', ...
       'No unique lower crack-face ID on inner annulus rim.');
map(D.ringLowerIDs(33))=leftLower;
assert(map(D.ringLowerIDs(1))==1, ...
    'twohole:IntactPositiveAxis','Positive-axis rim node must be shared.');

fixed=find(map>0);
assert(max(vecnorm(cutMesh.coord3(map(fixed),:)-Xd(fixed,:),2,2))<1e-12, ...
    'twohole:DiskAnnulusCoordinates','Circular interface points mismatch.');
new=find(map==0);
map(new)=size(cutMesh.coord3,1)+(1:numel(new))';
X=[cutMesh.coord3; Xd(new,:)];
T=[cutMesh.connect3;map(Td)];

% Tip shared between upper and lower disk half, never duplicated.
tip=map(D.tipNode);
u=(1:D.upperNodeCount)';
upperDisk=u(abs(Xd(u,2))<1e-14 & Xd(u,1)<-1e-14);
lowerDisk=D.mirror(upperDisk);
up=unique([cut.crackUpperIDs(:);map(upperDisk);tip]);
lo=unique([cut.crackLowerIDs(:);map(lowerDisk);tip]);
[~,iu]=sort(X(up,1));up=up(iu);
[~,il]=sort(X(lo,1));lo=lo(il);
assert(isequal(X(up,:),X(lo,:)), ...
    'twohole:DiskFaces','Upper and lower crack coordinates differ.');
assert(isequal(intersect(up,lo),tip), ...
    'twohole:DiskTip','Only physical tip may be common to crack faces.');

A=area_signed(X,T);
assert(all(A>0),'twohole:PatchInverted','An interface triangle is inverted.');
assert(numel(unique(T(:)))==size(X,1), ...
    'twohole:UnusedPatchNode','An unused interior or ring vertex exists.');

% Check both sides of every 2-mm inner-circle chord: exactly two owners.
E=sort([T(:,[1 2]);T(:,[2 3]);T(:,[3 1])],2);
[eu,~,ic]=unique(E,'rows');inc=accumarray(ic,1);
radius=vecnorm(X,2,2);
arc=all(abs(radius(eu)-c.InnerRadius)<1e-12,2);
assert(sum(arc)==64 && all(inc(arc)==2), ...
    'twohole:DiskAnnulusSeam','Inner circle does not have 64 conforming edges.');
assert(nnz(inc>2)==0,'twohole:NonmanifoldPatch', ...
    'Nonmanifold topological edges in assembled patch.');

P=struct('coord3',X,'connect3',T, ...
    'tipNode',tip,'upperFaceNodes',up,'lowerFaceNodes',lo, ...
    'radius_m',c.OuterRadius,'innerRadius_m',c.InnerRadius, ...
    'innerDisk',D,'annulusInfo',ai,'annulusCut',cut, ...
    'originalAnnulus',original, ...
    'nAnnulusTriangles',size(cutMesh.connect3,1), ...
    'nInnerDiskTriangles',size(D.connect3,1), ...
    'innerInterfaceEdges',sum(arc), ...
    'ringPhases',mod((0:ai.Nr)',2)*pi/c.Ntheta, ...
    'trialInnerDiskFirstPitch_m',c.Htip, ...
    'trialPatchGeometryOnly',true, ...
    'nativePDEExteriorJoined',false, ...
    'physicalFEMPerformed',false);
end

function A=area_signed(X,T)
a=X(T(:,2),:)-X(T(:,1),:);
b=X(T(:,3),:)-X(T(:,1),:);
A=.5*(a(:,1).*b(:,2)-a(:,2).*b(:,1));
end
