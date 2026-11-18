function R=g2_kinked_regular_block(P,varargin)
%G2_KINKED_REGULAR_BLOCK  Frozen p010 kernel + 0.3 mm analytic collar at the tip of a kinked polyline.
%
%  R = g2_kinked_regular_block(P)     % P: N-by-2 mm, mouth first, tip last, last segment 4 mm
% WP3.1 (Issue #24), geometry only. Generalises g2_p010_cornell_regular_block (which
% stays unchanged and asserts the straight starter tip) to the last segment of a
% kinked polyline:
%  - the unchanged vendor builder main_m1i_increment_ring_geometry_only is called
%    with PriorCrackPolyline_m = P(1:end-1)/1000, Delta_mm = 4 and the measured
%    signed turn, so the 2,788-T3 kernel is a rigid motion of the accepted one;
%  - the 128-T3 collar is rebuilt analytically in the rotated frame
%    tip + 3.3 (cos(phi) t + sin(phi) n) with the duplicated entry node
%    (outer(33) upper / +n bank, outer(65) lower bank);
%  - Cornell admissibility is g2_kink_admissibility (K1-K10), not the old 2-hole gates.
% The vendor's 15 local gates use its own old 300x400 mm two-hole plate; they qualify
% the kernel, not the Cornell placement. No PDE, FEM, SIF or growth.
here=fileparts(mfilename('fullpath'));root=fileparts(fileparts(here));
jsonFile=fullfile(root,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
ip=inputParser;
addParameter(ip,'JsonPath',jsonFile,@(v)ischar(v)||isstring(v));
addParameter(ip,'ExpectedTangent',[],@(v)isempty(v)||(isnumeric(v)&&numel(v)==2));
addParameter(ip,'ExpectedVertices',3,@(v)isnumeric(v)&&isscalar(v)&&v>=3&&v==round(v));
addParameter(ip,'TipGuideRadius_mm',15,@(v)isempty(v)||(isnumeric(v)&&isscalar(v)));
parse(ip,varargin{:});o=ip.Results;
R=struct('pass',false,'stage','HOLD_NOT_STARTED','geometryOnly',true,'approvedForLEFM',false, ...
 'gates',struct(),'failedGates',{{}},'summary',struct(),'message','');
J=jsondecode(fileread(char(o.JsonPath)));
assert(strcmp(J.schema,'NewMetacomp.G2.IngraffeaGrigoriu1990.Specimen1.nominal.v1'),'G2KB:Schema','Wrong JSON.');
G=J.nominal_geometry_mm;
A=g2_kink_admissibility(P,G,'DeltaA_mm',4,'ExpectedVertices',o.ExpectedVertices,'ExpectedTangent',o.ExpectedTangent,'TipGuideRadius_mm',o.TipGuideRadius_mm);
R.admissibility=A;
if ~A.pass
 R.stage='HOLD_KINK_ADMISSIBILITY';R.message=strjoin(A.failedGates,', ');return
end
F=g2_polyline_frame(P);tip=F.tip;t=F.t;n=F.n;
turn=F.turns_deg(end);delta=4;rc=3;dr=.30;ro=rc+dr;
Pprior_m=P(1:end-1,:)/1000; %#ok<NASGU> used inside evalc
vendor=fullfile(here,'vendor_p010_a14d8872');
assert(strcmpi(which('main_m1i_increment_ring_geometry_only'),fullfile(vendor,'main_m1i_increment_ring_geometry_only.m')), ...
 'G2KB:Vendor','The pinned vendor builder must be first on the path.');
[~,L]=evalc(['main_m1i_increment_ring_geometry_only(''PriorCrackPolyline_m'',Pprior_m,' ...
 '''Delta_mm'',delta,''Turn_deg'',turn,''Plot'',false)']);
lg=cell2mat(struct2cell(L.gates));
local15=numel(lg)==15&&all(lg);
fprintf('G2_KB_VENDOR_LOCAL_GATES=%d/%d\n',nnz(lg),numel(lg));
if ~local15
 R.stage='HOLD_VENDOR_P010_KERNEL';R.message='Vendor 15-gate kernel failed for this turn.';R.vendorGates=L.gates;return
end
Xu=1000*L.coord3;Tu=L.connect3;
tipVendorErr=norm(1000*L.tip_m-tip);
phi=(0:63)'*2*pi/64;
ring=L.sourcePatch.originalAnnulus.rings{end}(:);
dn=L.sourcePatch.lowerFaceNodes(:);
[~,kD]=min(vecnorm(Xu(dn,:)-(tip-rc*t),2,2));lowerEntry=dn(kD);
idealInner=tip+rc*(cos(phi)*t+sin(phi)*n);
innerAgreement=max(vecnorm(Xu(ring,:)-idealInner,2,2));
entryAgreement=norm(Xu(lowerEntry,:)-(tip-rc*t));
sourceFixed=numel(ring)==64&&size(Tu,1)==2788&&abs(L.summary.coreRadius_mm-rc)<1e-10&& ...
 abs(L.summary.ediInner_mm-.4)<1e-10&&abs(L.summary.ediOuter_mm-2.6)<1e-10&& ...
 tipVendorErr<1e-9&&innerAgreement<1e-8&&entryAgreement<1e-8&&lowerEntry~=ring(33);
if ~sourceFixed
 R.stage='HOLD_ROTATED_P010_PATTERN';
 R.message=sprintf('Rotated kernel mismatch: tip %.3g, ring %.3g, entry %.3g mm.',tipVendorErr,innerAgreement,entryAgreement);return
end
% analytic collar in the rotated frame (same construction as WP1 and upstream)
outerIdeal=tip+ro*(cos(phi)*t+sin(phi)*n);
outerIdeal=[outerIdeal;outerIdeal(33,:)];
outerIDs=(size(Xu,1)+(1:65))';
Tcol=zeros(128,3);innerSide=zeros(64,2);outerSide=zeros(64,2);
for j=1:64
 k=mod(j,64)+1;i0=ring(j);o0=outerIDs(j);
 if j==33,i0=lowerEntry;o0=outerIDs(65);end
 i1=ring(k);o1=outerIDs(k);
 Tcol(2*j-1,:)=[i0,o0,o1];Tcol(2*j,:)=[i0,o1,i1];
 innerSide(j,:)=sort([i0,i1]);outerSide(j,:)=sort([o0,o1]);
end
X=[Xu;outerIdeal];T=[Tu;Tcol];nCore=size(Tu,1);
a=X(T(:,2),:)-X(T(:,1),:);b=X(T(:,3),:)-X(T(:,1),:);a2=a(:,1).*b(:,2)-a(:,2).*b(:,1);
L12=vecnorm(a,2,2);L31=vecnorm(b,2,2);L23=vecnorm(X(T(:,3),:)-X(T(:,2),:),2,2);
cl=@(z)max(-1,min(1,z));
ang=[acosd(cl((L12.^2+L31.^2-L23.^2)./(2*L12.*L31))),acosd(cl((L12.^2+L23.^2-L31.^2)./(2*L12.*L23))), ...
     acosd(cl((L23.^2+L31.^2-L12.^2)./(2*L23.*L31)))];
minAng=min(ang(:));h=max([L12,L23,L31],[],2);
raw=sort([T(:,[1 2]);T(:,[2 3]);T(:,[3 1])],2);[edges,~,ic]=unique(raw,'rows');
inc=accumarray(ic,1);own=repmat((1:size(T,1))',3,1);
lo=accumarray(ic,own,[],@min);hi=accumarray(ic,own,[],@max);adj=inc==2;
maxRatio=max(max(h(lo(adj))./h(hi(adj)),h(hi(adj))./h(lo(adj))));
[im,iIdx]=ismember(innerSide,edges,'rows');[om,oIdx]=ismember(outerSide,edges,'rows');
insideValid=all(im)&&all(inc(iIdx(im))==2)&&nnz(im)==64;
outsideValid=all(om)&&all(inc(oIdx(om))==1)&&nnz(om)==64;
[X6,T6]=T3toT6_fast(X,T);
r6=vecnorm(X6-tip,2,2);q=ones(size(r6));q(r6>=2.6)=0;tr=r6>.4&r6<2.6;q(tr)=(2.6-r6(tr))/(2.6-.4);
active=find(max(q(T6),[],2)-min(q(T6),[],2)>1e-14);
qMaxRadius=max(r6(unique(T6(active,:))));
qInside=all(active<=nCore)&&qMaxRadius<rc*cos(pi/64);
tipNode=L.sourcePatch.tipNode;
gates=struct('vendorLocal15of15',local15,'rotated2788T3And64SectorsMatchFrame',sourceFixed, ...
 'kinkAdmissibleK1toK10',A.pass,'analyticCollar128T3And65OuterNodes',size(Tcol,1)==128&&numel(outerIDs)==65, ...
 'allRegularT3AreasPositive',all(a2>0),'regularT3MinAngleAtLeast20',minAng>=20, ...
 'regularT3NeighborRatioAtMost1p8',maxRatio<=1.8,'exact64TwoOwnerInnerSeamEdges',insideValid, ...
 'exact64OneOwnerOuterRimEdges',outsideValid,'T6HasEveryUniqueMidsideOnce',size(X6,1)==size(X,1)+size(edges,1), ...
 'singlePhysicalTipCorrect',isscalar(tipNode)&&norm(X(tipNode,:)-tip)<1e-9, ...
 'FEqSupport2443InsideKernel',qInside&&numel(active)==2443);
v=cell2mat(struct2cell(gates));f=fieldnames(gates);
R.gates=gates;R.failedGates=f(~v);R.pass=all(v);
R.summary=struct('tip_mm',tip,'tangent',t,'normal',n,'turn_deg',turn,'polyline_mm',P, ...
 'vendorTipError_mm',tipVendorErr,'innerRingAgreement_mm',innerAgreement,'entryAgreement_mm',entryAgreement, ...
 'ringT3Elements',nCore,'collarT3Elements',128,'regularBlockT3Nodes',size(X,1),'regularBlockT6Nodes',size(X6,1), ...
 'minAngle_deg',minAng,'maxNeighborLongestEdgeRatio',maxRatio,'qActiveT6Parents',numel(active), ...
 'qSupportMaxRadius_mm',qMaxRadius,'p010CoreRadius_mm',rc,'outerRimRadius_mm',ro,'admissibility',A.summary);
if R.pass,R.stage='KINKED_P010_BLOCK_PASS';else,R.stage='HOLD_KINKED_P010_BLOCK';R.message=strjoin(R.failedGates,', ');end
fprintf('G2_KB_GATES=%d/%d TURN=%.10f MIN_ANGLE=%.6f RATIO=%.6f Q=%d\n',nnz(v),numel(v),turn,minAng,maxRatio,numel(active));
R.coord3=X;R.connect3=T;R.coord6=X6;R.connect6=T6;R.tipNode=tipNode;R.nodalQ=q;R.qActiveT6Rows=active;
R.collarOuterIDs=outerIDs;R.kernelNodes=size(Xu,1);R.sourceP010=L;
end
