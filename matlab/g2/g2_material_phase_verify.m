function V = g2_material_phase_verify(X6,T6,phase,centers,holeR,interfaceR,opts)
%G2_MATERIAL_PHASE_VERIFY  Independent geometric check of two-phase labels (Issue #33 verifier).
%
%  V = g2_material_phase_verify(X6,T6,phase,centers,holeR,interfaceR,opts)
% Written separately from g2_material_phase_map (no flood fill, no owner logic reuse).
% Every one of the six T6 nodes of every element is classified against each
% interface polygon (saved T3 vertices on the nominal circle, angular order) as
% inside / on (distance to the polygon <= tolOn) / outside. An element is
% reinforcement iff no node is strictly outside some polygon k, matrix iff no node
% is strictly inside any polygon; a node strictly inside and another strictly
% outside the same polygon is a nonconforming straddle. Checks (all must hold):
%  labelsMatchGeometry, noStraddle, interfaceChordsTwoOwnersMixed, interfaceMidsideShared,
%  noOtherMixedEdges, noVoidPenetration, annulusAreaIdentity, domainAreaIdentity,
%  bandsConnected, matrixConnected, coincidentNodesOnlyRegisteredTwins,
%  tipGuideMatrixOnly, qSupportMatrixOnly (and clearance).
% opts: onCircleTol_mm, areaRelTol, domainAreaRelTol, outerArea_mm2 (domain area
% without holes; [] skips), twins (P-by-2 registered coincident node pairs), tip,
% tipGuideRadius_mm, qOuterRadii_mm, minQClearance_mm, voidTol_mm.
if nargin<7,opts=struct();end
tolOn=getf(opts,'onCircleTol_mm',1e-9);
nH=numel(holeR);centers=reshape(centers,nH,2);holeR=holeR(:);interfaceR=interfaceR(:);
M=size(T6,1);phase=phase(:);T3=T6(:,1:3);
c=struct();val=struct();
assert(numel(phase)==M,'G2PV:Labels','One label per element required.');
vtx=unique(T3(:));
polyI=cell(nH,1);polyH=cell(nH,1);
for h=1:nH
 polyI{h}=ring(X6,vtx,centers(h,:),interfaceR(h),tolOn);
 polyH{h}=ring(X6,vtx,centers(h,:),holeR(h),tolOn);
end
% ---- node classification against each interface polygon: -1 inside, 0 on, +1 outside
cls=zeros(size(X6,1),nH);
for h=1:nH
 P=X6(polyI{h},:);
 inn=inpolygon(X6(:,1),X6(:,2),P(:,1),P(:,2));
 cls(:,h)=1-2*inn;
 near=find(abs(vecnorm(X6-centers(h,:),2,2)-interfaceR(h))<.1*interfaceR(h));
 dmin=poly_dist(X6(near,:),P);cls(near(dmin<=tolOn),h)=0;
end
geo=ones(M,1);straddle=false(M,1);
for h=1:nH
 ce=reshape(cls(T6(:),h),M,6);
 straddle=straddle|(any(ce<0,2)&any(ce>0,2));
 inBand=all(ce<=0,2)&any(ce<0,2);
 geo(inBand)=2;
end
c.noStraddle=~any(straddle);val.straddlingElements=nnz(straddle);
c.labelsMatchGeometry=isequal(geo,phase);val.labelMismatches=nnz(geo~=phase);
% ---- interface chords: two owners with labels {1,2}, one shared midside node
Eall=[T3(:,[1 2]);T3(:,[2 3]);T3(:,[3 1])];Mid=[T6(:,4);T6(:,5);T6(:,6)];own=repmat((1:M)',3,1);
key=sort(Eall,2);
okChord=true;okMid=true;nChord=0;
for h=1:nH
 v=polyI{h};ch=sort([v,circshift(v,-1)],2);nChord=nChord+size(ch,1);
 for j=1:size(ch,1)
  k=find(key(:,1)==ch(j,1)&key(:,2)==ch(j,2));
  if numel(k)~=2||~isequal(sort(phase(own(k))).',[1 2]),okChord=false;
  elseif Mid(k(1))~=Mid(k(2))||norm(X6(Mid(k(1)),:)-.5*(X6(ch(j,1),:)+X6(ch(j,2),:)))>tolOn,okMid=false;end
 end
end
c.interfaceChordsTwoOwnersMixed=okChord;c.interfaceMidsideShared=okMid;
[ue,~,ie]=unique(key,'rows');
pmin=accumarray(ie,phase(own),[size(ue,1) 1],@min);pmax=accumarray(ie,phase(own),[size(ue,1) 1],@max);
mixed=nnz(pmin~=pmax);c.noOtherMixedEdges=mixed==nChord;val.mixedEdges=mixed;val.interfaceChords=nChord;
% ---- voids
pen=0;
for h=1:nH
 P=X6(polyH{h},:);inn=inpolygon(X6(:,1),X6(:,2),P(:,1),P(:,2));
 near=find(inn);d=poly_dist(X6(near,:),P);pen=pen+nnz(d>getf(opts,'voidTol_mm',1e-9));
end
c.noVoidPenetration=pen==0;val.nodesInsideVoids=pen;
% ---- areas (straight-sided T6: area of the T3 parent)
x=X6(:,1);y=X6(:,2);
A=.5*((x(T3(:,2))-x(T3(:,1))).*(y(T3(:,3))-y(T3(:,1)))-(x(T3(:,3))-x(T3(:,1))).*(y(T3(:,2))-y(T3(:,1))));
annA=zeros(nH,1);refA=annA;nomA=annA;
for h=1:nH
 sel=phase==2&vecnorm(.5*(X6(T3(:,1),:)+X6(T3(:,2),:))-centers(h,:),2,2)<interfaceR(h)+1;
 annA(h)=sum(A(sel));
 refA(h)=polyarea(X6(polyI{h},1),X6(polyI{h},2))-polyarea(X6(polyH{h},1),X6(polyH{h},2));
 nomA(h)=pi*(interfaceR(h)^2-holeR(h)^2);
end
val.annulusArea_mm2=annA;val.annulusPolygonArea_mm2=refA;val.annulusNominalArea_mm2=nomA;
val.annulusAreaRelErr=max(abs(annA-refA)./refA);val.polygonVsNominalRel=(refA-nomA)./nomA;
c.annulusAreaIdentity=val.annulusAreaRelErr<=getf(opts,'areaRelTol',1e-12)&&abs(sum(A(phase==2))-sum(annA))<=1e-12*sum(annA);
oa=getf(opts,'outerArea_mm2',[]);
if isempty(oa)
 c.domainAreaIdentity=true;val.domainAreaRelErr=NaN;
else
 holesA=sum(cellfun(@(p)polyarea(X6(p,1),X6(p,2)),polyH));
 val.domainAreaRelErr=abs(sum(A)-(oa-holesA))/(oa-holesA);
 c.domainAreaIdentity=val.domainAreaRelErr<=getf(opts,'domainAreaRelTol',1e-9)&&all(A>0);
end
% ---- connectivity (edge adjacency inside one label)
two=find(accumarray(ie,1)==2);
[~,first]=unique(ie,'first');[~,last]=unique(ie,'last');
ea=own(first(two));eb=own(last(two));same=phase(ea)==phase(eb);
Gm=graph(ea(same),eb(same),[],M);cc=conncomp(Gm).';
c.matrixConnected=numel(unique(cc(phase==1)))==1;
bandComps=unique(cc(phase==2));c.bandsConnected=numel(bandComps)==nH;
val.bandComponents=numel(bandComps);
% ---- coincident nodes: only registered crack-bank twins
tw=getf(opts,'twins',zeros(0,2));tw=sort(tw(tw(:,1)~=tw(:,2),:),2);
[~,~,g]=uniquetol(X6,1e-9,'ByRows',true,'DataScale',1);
cntG=accumarray(g,1);dupG=find(cntG>1);pairs=zeros(0,2);multi=false;
for k=dupG.'
 ids=find(g==k);if numel(ids)~=2,multi=true;else,pairs(end+1,:)=sort(ids.');end %#ok<AGROW>
end
c.coincidentNodesOnlyRegisteredTwins=~multi&&all(ismember(pairs,tw,'rows'));
val.coincidentPairs=size(pairs,1);val.unregisteredCoincidentPairs=nnz(~ismember(pairs,tw,'rows'))+multi;
% ---- tip guide and q support
tip=getf(opts,'tip',[]);
if isempty(tip)
 c.tipGuideMatrixOnly=true;c.qSupportMatrixOnly=true;
else
 rN=vecnorm(X6-tip(:).',2,2);rE=min(reshape(rN(T6(:)),M,6),[],2);
 c.tipGuideMatrixOnly=all(phase(rE<getf(opts,'tipGuideRadius_mm',15))==1);
 qo=getf(opts,'qOuterRadii_mm',[]);ok=true;
 rRe=min(rN(unique(T6(phase==2,:))));
 for k=1:numel(qo),ok=ok&&all(phase(rE<qo(k))==1);end
 val.reinforcementNodeMinDistanceToTip_mm=rRe;
 val.qClearance_mm=rRe-max([qo(:);0]);
 c.qSupportMatrixOnly=ok&&val.qClearance_mm>=getf(opts,'minQClearance_mm',1);
end
val.counts=[nnz(phase==1),nnz(phase==2)];val.chordsPerCircle=cellfun(@numel,polyI).';
val.holeVerticesPerCircle=cellfun(@numel,polyH).';
f=fieldnames(c);ok=cellfun(@(k)c.(k),f);
V=struct('pass',all(ok),'checks',c,'failed',{f(~ok)},'values',val,'geometricLabels',geo);
end

function v=ring(X,vtx,c0,R,tol)
r=vecnorm(X(vtx,:)-c0,2,2);v=vtx(abs(r-R)<=tol);
[~,i]=sort(atan2(X(v,2)-c0(2),X(v,1)-c0(1)));v=v(i);
end

function d=poly_dist(Q,P)
d=inf(size(Q,1),1);n=size(P,1);
for j=1:n
 a=P(j,:);b=P(mod(j,n)+1,:);ab=b-a;t=max(0,min(1,((Q-a)*ab.')/(ab*ab.')));
 d=min(d,vecnorm(Q-(a+t.*ab),2,2));
end
end

function v=getf(s,f,d)
if isfield(s,f)&&~isempty(s.(f)),v=s.(f);else,v=d;end
end
