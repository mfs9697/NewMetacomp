function V = g2_m4b_activation_verify(X6,T6,ownerRing,phaseForAssembly,mask,mats,geo,opts)
%G2_M4B_ACTIVATION_VERIFY  Independent check of a partial ring activation (Issue #47).
%
%  V = g2_m4b_activation_verify(X6,T6,ownerRing,phaseForAssembly,mask,mats,geo,opts)
% New checker for G2-M4.B; the legacy g2_material_phase_verify (which assumes three
% active bands) is not used or modified here. It recomputes the independent owner
% oracle (g2_m4b_ring_owner_oracle) on the given X6/T6 and checks:
%  oracleAgreement            ownerRing == oracle owner, element by element
%  oraclePass                 polygons resolved, no straddle, unique owner, no node in a hole
%  centresAscendingY          ring IDs 1,2,3 = strictly ascending y of the centres
%  interfaceIdsOneToOne       ring polygon h is centred on centre h and its inner chord owners are ring h
%  maskCanonical              mask is one of the eight preregistered 1-by-3 binary masks
%  phaseFromMask              phaseForAssembly == 1 + (ownerRing>0 & mask(ownerRing))
%  inactiveAndMatrixLabelOne  every matrix and inactive-ring element has label 1
%  ringAreaIdentity           area of the elements of ring h == polygon annulus area (rel areaRelTol)
%  activeAreaIdentity         area of label-2 elements == sum of active ring areas
%  chordsConforming           each ring chord is a T3 edge with two owners (ring h inside, matrix outside),
%                             one shared midside node on the chord, expected chord count
%  activeChordsCarryJump      label (2|1) across every chord of an active ring
%  passiveChordsNoJump        label (1|1) across every chord of a passive ring
%  jumpEdgeCount              material-jump T3 edges == chords x number of active rings
%  noVoidFilling              domain area identity (plate - hole polygons), all areas positive
%  materialsAdmissible        mats(1) = matrix, mats(2) = c*matrix (or matrix for 'none'), same nu, SPD
%  qSupportOwnerFree          q support and tip guide contain no ring-owned element (any node)
%  qClearance                 nearest ring-owned node - max q radius >= minQClearance_mm
%  ringsAndMatrixConnected    each ring and the matrix are single edge-connected components
%  coincidentOnlyTwins        coincident nodes only at registered crack-bank twin pairs
% geo: centres (3x2), holeR, ringR. opts: onCircleTol_mm, areaRelTol, domainAreaRelTol,
% outerArea_mm2, expectedChords, contrast (0.5 | 2 | 'none'), E_matrix, nu, tip,
% tipGuideRadius_mm, qOuterRadii_mm, minQClearance_mm, twins, midsideTol_mm.
tolOn=getf(opts,'onCircleTol_mm',1e-9);tolMid=getf(opts,'midsideTol_mm',1e-9);
M=size(T6,1);T3=T6(:,1:3);ownerRing=ownerRing(:);phase=phaseForAssembly(:);
nH=size(geo.centres,1);c=struct();val=struct();
assert(numel(ownerRing)==M&&numel(phase)==M,'G2M4BV:Size','One owner and one label per element.');
% ---- oracle
O=g2_m4b_ring_owner_oracle(X6,T6,geo.centres,geo.holeR,geo.ringR,struct('onCircleTol_mm',tolOn));
c.oraclePass=O.pass;val.oracle=O.values;
c.oracleAgreement=isequal(O.ownerOracle,ownerRing);val.oracleMismatches=nnz(O.ownerOracle~=ownerRing);
c.centresAscendingY=all(diff(geo.centres(:,2))>0);
% ---- mask and labels
masks=logical([0 0 0;1 0 0;0 1 0;0 0 1;1 1 0;1 0 1;0 1 1;1 1 1]);
c.maskCanonical=isequal(size(mask),[1 3])&&all(mask==0|mask==1)&&ismember(logical(mask),masks,'rows');
if c.maskCanonical,mask=logical(mask);else,mask=false(1,nH);end
expect=ones(M,1);sel=ownerRing>0&ownerRing<=nH;
if c.maskCanonical,expect(sel)=1+double(mask(ownerRing(sel)));end
c.phaseFromMask=isequal(expect,phase);val.labelMismatches=nnz(expect~=phase);
inact=ownerRing==0;if c.maskCanonical,inact=inact|(sel&~ismember(ownerRing,find(mask)));end
c.inactiveAndMatrixLabelOne=all(phase(inact)==1);
% ---- areas
x=X6(:,1);y=X6(:,2);
A=.5*((x(T3(:,2))-x(T3(:,1))).*(y(T3(:,3))-y(T3(:,1)))-(x(T3(:,3))-x(T3(:,1))).*(y(T3(:,2))-y(T3(:,1))));
ringA=zeros(nH,1);polyA=ringA;ringN=ringA;
for h=1:nH
 ringA(h)=sum(A(ownerRing==h));ringN(h)=nnz(ownerRing==h);
 if O.checks.polygonsResolved
  polyA(h)=polyarea(X6(O.ringVertices{h},1),X6(O.ringVertices{h},2))-polyarea(X6(O.holeVertices{h},1),X6(O.holeVertices{h},2));
 end
end
val.ringArea_mm2=ringA.';val.ringPolygonArea_mm2=polyA.';val.ringElements=ringN.';
c.ringAreaIdentity=all(polyA>0)&&max(abs(ringA-polyA)./polyA)<=getf(opts,'areaRelTol',1e-12);
actA=sum(ringA(mask(:)&true(nH,1)));
val.activeArea_mm2=actA;val.label2Area_mm2=sum(A(phase==2));
c.activeAreaIdentity=abs(val.label2Area_mm2-actA)<=1e-12*max(actA,1);
val.activeVolume_mm3=actA*getf(opts,'thickness_mm',12.7);
% ---- chords: owners, midsides, material jump
Eall=[T3(:,[1 2]);T3(:,[2 3]);T3(:,[3 1])];Mid=[T6(:,4);T6(:,5);T6(:,6)];own=repmat((1:M)',3,1);
[ue,~,ie]=unique(sort(Eall,2),'rows');cntE=accumarray(ie,1);
[~,first]=unique(ie,'first');[~,last]=unique(ie,'last');
okConf=true;okAct=true;okPas=true;nChordTot=0;okIds=true;expCh=getf(opts,'expectedChords',[]);
for h=1:nH
 v=O.ringVertices{h};
 if numel(v)<3,okConf=false;continue,end
 okIds=okIds&&norm(mean(X6(v,:),1)-geo.centres(h,:))<=1e-6;
 ch=sort([v,circshift(v,-1)],2);nChordTot=nChordTot+size(ch,1);
 if ~isempty(expCh),okConf=okConf&&size(ch,1)==expCh;end
 [isE,loc]=ismember(ch,ue,'rows');
 if ~all(isE),okConf=false;continue,end
 if any(cntE(loc)~=2),okConf=false;continue,end
 a=own(first(loc));b=own(last(loc));
 ma=Mid(first(loc));mb=Mid(last(loc));
 mp=.5*(X6(ch(:,1),:)+X6(ch(:,2),:));
 okConf=okConf&&all(ma==mb)&&max(vecnorm(X6(ma,:)-mp,2,2))<=tolMid;
 inner=a;outer=b;sw=ownerRing(a)~=h;inner(sw)=b(sw);outer(sw)=a(sw);
 okIds=okIds&&all(ownerRing(inner)==h)&&all(ownerRing(outer)==0);
 if mask(h),okAct=okAct&&all(phase(inner)==2)&&all(phase(outer)==1);
 else,okPas=okPas&&all(phase(inner)==1)&&all(phase(outer)==1);end
end
c.interfaceIdsOneToOne=okIds;c.chordsConforming=okConf;
c.activeChordsCarryJump=okAct;c.passiveChordsNoJump=okPas;
two=find(cntE==2);
jump=nnz(phase(own(first(two)))~=phase(own(last(two))));
val.jumpEdges=jump;val.chordsTotal=nChordTot;
c.jumpEdgeCount=jump==(nChordTot/nH)*nnz(mask);
% ---- voids / domain
oa=getf(opts,'outerArea_mm2',[]);
if isempty(oa),val.domainAreaRelErr=NaN;c.noVoidFilling=O.checks.noNodeInsideHole&&all(A>0);
else
 holesA=0;for h=1:nH,if numel(O.holeVertices{h})>=3,holesA=holesA+polyarea(X6(O.holeVertices{h},1),X6(O.holeVertices{h},2));end,end
 val.domainAreaRelErr=abs(sum(A)-(oa-holesA))/(oa-holesA);
 c.noVoidFilling=O.checks.noNodeInsideHole&&all(A>0)&&val.domainAreaRelErr<=getf(opts,'domainAreaRelTol',1e-9);
end
% ---- materials
Em=getf(opts,'E_matrix',3268.115);nu=getf(opts,'nu',.35);ct=getf(opts,'contrast','none');
okM=numel(mats)==2&&mats(1).E==Em&&mats(1).nu==nu&&mats(2).nu==nu&&strcmp(mats(1).plane,'stress')&&strcmp(mats(2).plane,'stress');
if okM
 if ischar(ct),okM=strcmp(ct,'none')&&mats(2).E==Em&&~any(phase==2);
 else,okM=mats(2).E==ct*Em&&any(phase==2)==any(mask);end
 for p=1:2,okM=okM&&min(eig(g2_plane_D(mats(p))))>0;end
end
c.materialsAdmissible=okM;
% ---- q support / tip guide / clearance
tip=getf(opts,'tip',[]);
if isempty(tip),c.qSupportOwnerFree=false;c.qClearance=false;
else
 rN=hypot(X6(:,1)-tip(1),X6(:,2)-tip(2));rE=min(reshape(rN(T6(:)),M,6),[],2);
 rad=[getf(opts,'qOuterRadii_mm',[]);getf(opts,'tipGuideRadius_mm',15)];ok=true;
 for k=1:numel(rad),ok=ok&&all(ownerRing(rE<rad(k))==0);end
 c.qSupportOwnerFree=ok;
 rr=min(rN(unique(T6(ownerRing>0,:))));
 val.ringNodeMinDistanceToTip_mm=rr;
 val.perRingMinDistanceToTip_mm=arrayfun(@(h)min(rN(unique(T6(ownerRing==h,:)))),1:nH);
 val.qClearance_mm=rr-max(getf(opts,'qOuterRadii_mm',0));
 c.qClearance=val.qClearance_mm>=getf(opts,'minQClearance_mm',1);
end
% ---- connectivity
ea=own(first(two));eb=own(last(two));okC=true;
for h=0:nH
 s=ownerRing(ea)==h&ownerRing(eb)==h;Gm=graph(ea(s),eb(s),[],M);cc=conncomp(Gm).';
 okC=okC&&numel(unique(cc(ownerRing==h)))==1;
end
c.ringsAndMatrixConnected=okC;
% ---- coincident nodes
tw=getf(opts,'twins',zeros(0,2));tw=sort(tw(tw(:,1)~=tw(:,2),:),2);
[~,~,g]=uniquetol(X6,1e-9,'ByRows',true,'DataScale',1);
cg=accumarray(g,1);bad=0;pairs=zeros(0,2);
for k=find(cg>1).'
 ids=find(g==k);if numel(ids)~=2,bad=bad+1;else,pairs(end+1,:)=sort(ids.');end %#ok<AGROW>
end
val.unregisteredCoincident=bad+nnz(~ismember(pairs,tw,'rows'));
c.coincidentOnlyTwins=val.unregisteredCoincident==0;
f=fieldnames(c);ok=cellfun(@(k)logical(c.(k)),f);
V=struct('pass',all(ok),'checks',c,'failed',{f(~ok)},'values',val,'bits',char('0'+mask),'ownerOracle',O.ownerOracle);
end

function v=getf(s,f,d)
if isfield(s,f)&&~isempty(s.(f)),v=s.(f);else,v=d;end
end
