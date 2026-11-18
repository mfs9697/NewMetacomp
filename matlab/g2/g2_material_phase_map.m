function R = g2_material_phase_map(X6,T6,centers,holeR,interfaceR,opts)
%G2_MATERIAL_PHASE_MAP  Topological two-phase labels of a saved T6 mesh (Issue #33 mapper).
%
%  R = g2_material_phase_map(X6,T6,centers,holeR,interfaceR,opts)
% Candidate interfaces are closed polygons through the saved T3 vertices that lie on
% the nominal circle |x - c_k| = interfaceR(k) (opts.onCircleTol_mm), in angular
% order. Every consecutive chord must be an existing T3 edge with exactly two owners
% sharing one midside T6 node at the chord midpoint. A flood fill over T3 edge
% adjacency, blocked only at those chords, must give 1 + numel(holeR) components:
% the matrix (label 1, all outer owners) and one annulus per hole (label 2, the
% inner owners of that circle). No centroid rule is used. Fail closed: R.pass false
% with R.stage and R.message; labels are returned only on pass.
% opts: onCircleTol_mm (1e-9), minGap_mm (1e-3), midsideTol_mm (1e-9).
if nargin<6,opts=struct();end
tolOn=getf(opts,'onCircleTol_mm',1e-9);gapMin=getf(opts,'minGap_mm',1e-3);tolMid=getf(opts,'midsideTol_mm',1e-9);
nH=numel(holeR);centers=reshape(centers,nH,2);holeR=holeR(:);interfaceR=interfaceR(:);
M=size(T6,1);T3=T6(:,1:3);
R=struct('pass',false,'stage','HOLD_NOT_STARTED','message','','phase',[],'interfaces',struct([]));
% ---- T3 edges, owners, midsides
Eall=[T3(:,[1 2]);T3(:,[2 3]);T3(:,[3 1])];Mid=[T6(:,4);T6(:,5);T6(:,6)];own=repmat((1:M)',3,1);
[Es,ia,ie]=unique(sort(Eall,2),'rows');cnt=accumarray(ie,1);
if any(cnt>2),R.stage='HOLD_NONMANIFOLD_EDGE';R.message=sprintf('%d T3 edges with more than two owners.',nnz(cnt>2));return,end
o1=zeros(size(Es,1),1);o2=o1;m1=o1;m2=o1;
for k=1:numel(ie)
 e=ie(k);
 if o1(e)==0,o1(e)=own(k);m1(e)=Mid(k);else,o2(e)=own(k);m2(e)=Mid(k);end
end
blocked=false(size(Es,1),1);
vtx=unique(T3(:));
for h=1:nH
 r=vecnorm(X6(vtx,:)-centers(h,:),2,2);d=abs(r-interfaceR(h));
 on=vtx(d<=tolOn);off=d(d>tolOn);
 if numel(on)<3,R.stage='HOLD_INTERFACE_NOT_RESOLVED';R.message=sprintf('Circle %d carries %d T3 vertices.',h,numel(on));return,end
 if ~isempty(off)&&min(off)<gapMin
  R.stage='HOLD_INTERFACE_AMBIGUOUS';R.message=sprintf('Circle %d: a T3 vertex lies %.3g mm off the circle (gap rule %.3g).',h,min(off),gapMin);return
 end
 ang=atan2(X6(on,2)-centers(h,2),X6(on,1)-centers(h,1));[ang,ii]=sort(ang);on=on(ii);
 if any(diff(ang)<=0),R.stage='HOLD_INTERFACE_DUPLICATE_ANGLE';R.message=sprintf('Circle %d has coincident vertices.',h);return,end
 ch=[on,circshift(on,-1)];
 [isE,loc]=ismember(sort(ch,2),Es,'rows');
 if ~all(isE),R.stage='HOLD_INTERFACE_NONCONFORMING';R.message=sprintf('Circle %d: %d chords are not T3 edges.',h,nnz(~isE));return,end
 if any(o2(loc)==0),R.stage='HOLD_INTERFACE_ONE_OWNER';R.message=sprintf('Circle %d: %d chords have one owner (detached or boundary).',h,nnz(o2(loc)==0));return,end
 if any(m1(loc)~=m2(loc)),R.stage='HOLD_INTERFACE_MIDSIDE_NOT_SHARED';R.message=sprintf('Circle %d: %d chords with unshared midside nodes.',h,nnz(m1(loc)~=m2(loc)));return,end
 mp=.5*(X6(ch(:,1),:)+X6(ch(:,2),:));
 if max(vecnorm(X6(m1(loc),:)-mp,2,2))>tolMid,R.stage='HOLD_INTERFACE_MIDSIDE_OFF_CHORD';R.message=sprintf('Circle %d midside off chord.',h);return,end
 % inner / outer owner by the vertex opposite the chord (strictly off the circle by the gap rule)
 inner=zeros(numel(loc),1);outer=inner;
 for j=1:numel(loc)
  a=[o1(loc(j)),o2(loc(j))];side=zeros(1,2);
  for q=1:2
   v=setdiff(T3(a(q),:),ch(j,:));rv=norm(X6(v,:)-centers(h,:));
   side(q)=sign(rv-interfaceR(h));
  end
  if ~isequal(sort(side),[-1 1]),R.stage='HOLD_INTERFACE_SAME_SIDE';R.message=sprintf('Circle %d chord %d owners are on one side.',h,j);return,end
  inner(j)=a(side<0);outer(j)=a(side>0);
 end
 blocked(loc)=true;
 R.interfaces(h).vertexNodes=on;R.interfaces(h).chords=ch;R.interfaces(h).midsideNodes=m1(loc);
 R.interfaces(h).edgeRows=loc;R.interfaces(h).innerOwner=inner;R.interfaces(h).outerOwner=outer;
 R.interfaces(h).maxRadialDeviation_mm=max(d(d<=tolOn));
 R.interfaces(h).minGapToNextVertex_mm=min([off;inf]);
end
% ---- flood fill (connected components of the element graph through unblocked shared edges)
inside=o2>0&~blocked;
Gr=graph(o1(inside),o2(inside),[],M);
comp=conncomp(Gr).';nC=max(comp);
R.components=nC;
if nC~=1+nH,R.stage='HOLD_COMPONENT_COUNT';R.message=sprintf('%d components, expected %d.',nC,1+nH);return,end
outerComp=unique(comp(vertcat(R.interfaces.outerOwner)));
if ~isscalar(outerComp),R.stage='HOLD_MATRIX_NOT_CONNECTED';R.message='Outer owners are in more than one component.';return,end
annComp=zeros(nH,1);
for h=1:nH
 c=unique(comp(R.interfaces(h).innerOwner));
 if ~isscalar(c)||c==outerComp,R.stage='HOLD_ANNULUS_COMPONENT';R.message=sprintf('Annulus %d inner owners not one closed component.',h);return,end
 annComp(h)=c;
end
if numel(unique(annComp))~=nH,R.stage='HOLD_ANNULI_MERGED';R.message='Two annuli share a component.';return,end
phase=ones(M,1);annulusOf=zeros(M,1);
for h=1:nH,sel=comp==annComp(h);phase(sel)=2;annulusOf(sel)=h;end
R.phase=phase;R.annulusOf=annulusOf;R.componentOfElement=comp;
R.counts=[nnz(phase==1),nnz(phase==2)];
R.pass=true;R.stage='PHASE_MAP_TOPOLOGICAL_OK';
R.message=sprintf('%d matrix + %d reinforcement elements; chords per circle %s.',R.counts,mat2str(arrayfun(@(s)size(s.chords,1),R.interfaces)));
end

function v=getf(s,f,d)
if isfield(s,f),v=s.(f);else,v=d;end
end
