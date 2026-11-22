function P=g2_a1_family_b_patch(spec,G)
%G2_A1_FAMILY_B_PATCH  Family B near-tip patch for NewMetacomp A1 (Issue #66).
%
% PROVENANCE. Port of EdgeCrackHoleLEFM src/geometry/build_prh_near_tip_patch.m
% (PR-H, Issue #427, PR #428 merged head c69b234; file SHA-256
% d42024e7117c103584e9efab8f26cf9045c59a10372d74c0fa1c864e8f4b4881), branches
% 'BASE' and 'B' only (Family A is not transferred, per Issue #66). The algorithm,
% asserts and identifiers are unchanged; the function name, this header and one
% extra output field (lambda, the disk similarity factor; 1 for BASE) differ. It calls the vendor builders in matlab/g2/vendor_p010_a14d8872, which are
% byte-identical (LF) to the Edge PR-H versions of build_twohole_literal_annulus,
% cut_twohole_literal_annulus and main_m1i_increment_ring_geometry_only.
%
% G is the unchanged 15/15 p010 ring returned by main_m1i_increment_ring_geometry_only
% (in metres; g2_kinked_regular_block keeps it as sourceP010).
%  spec.family='BASE'  the original patch, returned unchanged (m=0).
%  spec.family='B'     spec.extraBandPairs=m: 2m bands of the original geometric
%                      64-sector annulus are continued inward of the original disk
%                      rim, and the original disk shrinks by lambda=q^(-2m).
% The 3 mm outer boundary, its 64 sectors, the crack line and the tip are unchanged.
% No PDE call, join, loads, stiffness, solve, COD, EDI, SIF or file I/O.
assert(isstruct(spec)&&isfield(spec,'family'),'PRH:PatchSpec','Missing patch family.');
assert(isstruct(G)&&G.pass&&numel(fieldnames(G.gates))==15, ...
 'PRH:PatchParentRing','A qualified 15/15 original p010 ring is required.');
base=G.sourcePatch;
scale=G.summary.ringScaleFromQualifiedP010;
t=[cos(G.newDirection_rad),sin(G.newDirection_rad)];
n=[-t(2),t(1)];
rotation=[t(:),n(:)];
diskR=base.innerRadius_m;
pitch=base.innerDisk.radialRings_m(1);
ring=base.originalAnnulus.rings{end}(:);
switch spec.family
 case 'BASE'
  X=G.coord3;T=G.connect3;
  up=base.upperFaceNodes(:);lo=base.lowerFaceNodes(:);tipNode=base.tipNode;
  nDisk=base.nInnerDiskTriangles;lambda=1;
 case 'B'
  m=spec.extraBandPairs;
  assert(isscalar(m)&&m>=1&&m==round(m),'PRH:PatchBands', ...
   'Family B needs a positive integer number of band pairs.');
  [Xlocal,T,up,lo,tipNode,ring,nDisk,lambda]=local_family_b(base,m);
  X=scale*Xlocal*rotation.'+G.tip_m;
  diskR=diskR*lambda;pitch=pitch*lambda;
 otherwise
  error('PRH:PatchFamily','Unknown patch family %s.',spec.family);
end
% Lower bank entry on the outer rim (original node ring(33) is the upper one).
tvec=t;
[~,j]=min(vecnorm(X(lo,:)-(G.tip_m-.003*tvec),2,2));
P=struct('coord3',X,'connect3',T,'tipNode',tipNode, ...
 'upperFaceNodes',up,'lowerFaceNodes',lo, ...
 'outerRing',ring,'lowerEntry',lo(j), ...
 'diskCells',(size(T,1)-nDisk+1:size(T,1))', ...
 'diskRadius_m',scale*diskR,'firstPitch_m',scale*pitch,'lambda',lambda, ...
 'physicalFEMPerformed',false);
end

function [X,T,up,lo,tip,ring,nDisk,lambda]=local_family_b(base,m)
% Same assembly as build_m1i_trial_tip_annulus_p010, with the generic
% annulus builder started 2m bands further in and the disk scaled to fit.
ai0=base.annulusInfo;
q=ai0.qActual;
r0=ai0.r0/q^(2*m);
lambda=r0/ai0.r0;
[original,ai]=build_twohole_literal_annulus('r0',r0,'r1',ai0.r1, ...
 'Ntheta',ai0.Ntheta,'NrOverride',ai0.Nr+2*m);
assert(ai.Nr==ai0.Nr+2*m&&ai.Ntheta==64&&mod(ai.Nr,2)==0, ...
 'PRH:FamilyBLattice','Outer ring must return to the unshifted phase.');
[cutMesh,cut]=cut_twohole_literal_annulus(original);
D=base.innerDisk;
Xd=lambda*D.coord3;Td=D.connect3;
map=zeros(size(Xd,1),1);
for k=1:33
 map(D.ringUpperIDs(k))=k;
end
for k=2:32
 map(D.ringLowerIDs(k))=66-k;
end
leftLower=cut.crackLowerIDs(abs(cutMesh.coord3(cut.crackLowerIDs,1)+r0)<1e-12);
assert(numel(leftLower)==1,'PRH:FamilyBLeftEntry', ...
 'No unique lower crack-face ID on the scaled disk rim.');
map(D.ringLowerIDs(33))=leftLower;
fixed=find(map>0);
assert(map(D.ringLowerIDs(1))==1&& ...
 max(vecnorm(cutMesh.coord3(map(fixed),:)-Xd(fixed,:),2,2))<1e-12, ...
 'PRH:FamilyBDiskSeam','Scaled disk rim differs from the inner annulus ring.');
new=find(map==0);
map(new)=size(cutMesh.coord3,1)+(1:numel(new))';
X=[cutMesh.coord3;Xd(new,:)];
T=[cutMesh.connect3;map(Td)];
tip=map(D.tipNode);
u=(1:D.upperNodeCount)';
upperDisk=u(abs(Xd(u,2))<1e-14&Xd(u,1)<-1e-14);
lowerDisk=D.mirror(upperDisk);
up=unique([cut.crackUpperIDs(:);map(upperDisk);tip]);
lo=unique([cut.crackLowerIDs(:);map(lowerDisk);tip]);
[~,iu]=sort(X(up,1));up=up(iu);
[~,il]=sort(X(lo,1));lo=lo(il);
assert(max(vecnorm(X(up,:)-X(lo,:),2,2))<1e-14&&isequal(intersect(up,lo),tip), ...
 'PRH:FamilyBFaces','Crack faces must coincide and share only the tip.');
ring=original.rings{end}(:);
nDisk=size(Td,1);
end
