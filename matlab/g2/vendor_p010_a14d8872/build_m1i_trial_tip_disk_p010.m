function P=build_m1i_trial_tip_disk_p010(varargin)
%BUILD_M1I_TRIAL_TIP_DISK_P010  Explicit 0.1mm first-ring T3 disk ONLY.
% NEW isolated geometry-only source: frozen 0.2mm historical disk stays
% byte-unchanged. First source pilot changes 0.2mm -> 0.1mm first pitch
% with EXACT same 11 rings, sector counts [6:6:60 64], 64 boundary
% coordinates at 2mm and deterministic reflected T3 crack banks.
% Interior radial locations are smoothly graded using a fixed power law,
% NOT linspace, to protect the original 1.8 neighbor size-ratio criterion.
% This does NOT create a full 7.2mm patch or global joined PDE mesh.
% Independent new disk quality gate uses min angle >=30deg, triangle
% quality >.85; historical frozen disk's stricter >=40deg still applies
% ONLY to that original separate immutable builder.
% No FEM solver, stiffness, quadrature or SIF computation.
% Geometry ONLY, no Delaunay / PDE mesh / physical FEM / SIF.
% For the frozen initial straight crack: tip at (0,0), negative-x seam.
% Eleven graded ring radii start at 0.1mm and finish exactly at 2.0mm;
% sector counts 6,12,...,60,64. Each upper semiannulus is linked using
% a deterministic shortest-bridge zipper; the lower is reflected exactly.
% Six triangles meet the single shared tip. The negative x-axis is
% duplicated in topology, not in geometry; positive x remains intact.
ip=inputParser;
addParameter(ip,'Radius',.002,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Pitch',.0001,@(v)isnumeric(v)&&isscalar(v)&&v>0);
parse(ip,varargin{:});o=ip.Results;
assert(abs(o.Radius-.002)<1e-12 && abs(o.Pitch-.0001)<1e-12, ...
    'm1iTrial:FrozenCandidate','Isolated first trial is 2-mm disk and 0.1-mm first pitch.');
nFull=[6:6:60,64]';
% Power grading with SAME 11 sector rings/outer coordinates as source.
% r(1)=0.1mm, r(11)=2mm. Intermediate spacings adapt smoothly.
gradingExponent=log(o.Pitch/o.Radius)/log(1/numel(nFull));
j=(1:numel(nFull))';
r=o.Radius*(j/numel(nFull)).^gradingExponent;
r(1)=o.Pitch;r(end)=o.Radius;
assert(all(diff(r)>0) && gradingExponent>1 && ...
    numel(r)==11 && abs(r(end)-.002)<1e-15, ...
    'm1iTrial:NonmonotoneGradedRadialCoordinates');
assert(numel(r)==numel(nFull) && nFull(end)==64);
U=[0,0]; ids=cell(numel(r),1);
for j=1:numel(r)
    n=nFull(j)/2;
    theta=(0:n)'*pi/n;
    xy=r(j)*[cos(theta),sin(theta)];
    xy([1,end],2)=0;
    ids{j}=size(U,1)+(1:size(xy,1))';
    U=[U;xy]; %#ok<AGROW>
end
Tu=[ones(3,1),ids{1}(1:3),ids{1}(2:4)];
for j=2:numel(r)
    A=ids{j-1}; B=ids{j};
    na=numel(A)-1;nb=numel(B)-1;
    ia=1; ib=1;
    while ia<=na || ib<=nb
        if ia>na
            stepA=false;
        elseif ib>nb
            stepA=true;
        else
            da=sum((U(A(ia+1),:)-U(B(ib),:)).^2);
            db=sum((U(A(ia),:)-U(B(ib+1),:)).^2);
            if abs(da-db)<=64*eps(max(da,db))
                stepA=mod(j+ia+ib,2)==0;
            else
                stepA=da<db;
            end
        end
        if stepA
            Tu(end+1,:)=[A(ia),B(ib),A(ia+1)]; %#ok<AGROW>
            ia=ia+1;
        else
            Tu(end+1,:)=[A(ia),B(ib),B(ib+1)]; %#ok<AGROW>
            ib=ib+1;
        end
    end
end
a=U(Tu(:,2),:)-U(Tu(:,1),:);
b=U(Tu(:,3),:)-U(Tu(:,1),:);
signed=.5*(a(:,1).*b(:,2)-a(:,2).*b(:,1));
assert(all(signed>0),'m1e:BadUpperFan','Nonpositive upper T3 cell.');
nUpper=size(U,1);
axisNodes=find(abs(U(:,2))<1e-14);
shared=axisNodes(U(axisNodes,1)>=-1e-14);
duplicated=setdiff((1:nUpper)',shared);
mirror=(1:nUpper)';
mirror(duplicated)=nUpper+(1:numel(duplicated))';
Z=[U;U(duplicated,1),-U(duplicated,2)];
T=[Tu;mirror(Tu(:,[1,3,2]))];
tip=1;
fan=T(any(T==tip,2),:);
assert(size(fan,1)==6 && numel(setdiff(unique(fan(:)),tip))==7, ...
   'm1e:TipFan','Expected 6 tip triangles and 7 neighbor IDs.');
% The upper and lower negative crack lines use different vertex IDs.
neg=axisNodes(U(axisNodes,1)<-1e-14);
assert(all(mirror(neg)~=neg) && ...
       isequal(Z(neg,:),Z(mirror(neg),:)), ...
       'm1e:FacePair','Negative crack faces are not separate and coincident.');
edge12=vecnorm(Z(T(:,2),:)-Z(T(:,1),:),2,2);
edge23=vecnorm(Z(T(:,3),:)-Z(T(:,2),:),2,2);
edge31=vecnorm(Z(T(:,1),:)-Z(T(:,3),:),2,2);
A1=Z(T(:,2),:)-Z(T(:,1),:);
B1=Z(T(:,3),:)-Z(T(:,1),:);
triArea=.5*(A1(:,1).*B1(:,2)-A1(:,2).*B1(:,1));
assert(all(triArea>0),'m1e:BadT3Area','Negative/zero disk triangle.');
Q=4*sqrt(3)*triArea./(edge12.^2+edge23.^2+edge31.^2);
ang1=acosd(max(-1,min(1,(edge12.^2+edge31.^2-edge23.^2)./(2*edge12.*edge31))));
ang2=acosd(max(-1,min(1,(edge12.^2+edge23.^2-edge31.^2)./(2*edge12.*edge23))));
ang3=acosd(max(-1,min(1,(edge23.^2+edge31.^2-edge12.^2)./(2*edge23.*edge31))));
minAngle=min([ang1;ang2;ang3]);
assert(minAngle>=30 && min(Q)>.85, ...
    'm1iTrial:DiskQuality','Trial disk must pass >=30deg and >0.85 triangle quality.');
% 64 geometrically unique nodes on the 2-mm ring; lower -x is duplicated.
outerUpper=ids{end};outerLower=mirror(outerUpper);
outerCoordinates=unique(round(Z([outerUpper;outerLower],:)/1e-12),'rows');
assert(size(outerCoordinates,1)==64,'m1e:Outer64', ...
    '2-mm interface must have exactly 64 geometrically unique vertices.');
P=struct('coord3',Z,'connect3',T, ...
    'tipNode',tip,'mirror',mirror,'nUpper',nUpper, ...
    'outerUpperIDs',outerUpper,'outerLowerIDs',outerLower, ...
    'negativeUpperIDs',neg,'negativeLowerIDs',mirror(neg), ...
    'radialRings_m',r,'fullSectorCounts',nFull, ...
    'trialPitch_m',o.Pitch,'trialGradingExponent',gradingExponent, ...
    'candidateGeometryOnly',true,'globalPDEJoinQualified',false, ...
    'minAngle_deg',minAngle,'qualityMin',min(Q), ...
    'T3_nodes',size(Z,1),'T3_elements',size(T,1), ...
    'physicalFEMPerformed',false);
end
