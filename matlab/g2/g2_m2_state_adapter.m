function [Dm,A] = g2_m2_state_adapter(D,stateId,polyline)
%G2_M2_STATE_ADAPTER  Schema adapter for the frozen Issue #36 states (read only, tested).
%
%  [Dm,A] = g2_m2_state_adapter(D,stateId,polyline)
% D: the saved mesh struct (never modified on disk); polyline: preregistered frozen crack
% (N-by-2 mm). S1/S2 already carry every field needed by g2_material_sif_on_mesh; for them
% Dm = D and the tests only confirm the schema. S0 (WP2 straight, family A) lacks
% crackPolyline and tipTangent: Dm.crackPolyline = [mouth; X3(physicalTipNode)] and
% Dm.tipTangent = (0,1). Nothing else is added or changed. Tests (A.checks):
%  schema, tipMatchesPolyline, polylineMatchesPreregistered, banksOnPolyline, banksTwinned
%  (coincident pairs, distinct IDs except exactly the shared tip), upperBankOnPlusNSide
%  (every element touching an upper-bank node off the tip lies on the +n side of the
%  segment, every lower-bank element on the -n side), anchorsPresent.
% The COD equivalence with the historical extractor needs a displacement field and is
% tested by the batch.
Dm=D;c=struct();
need={'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','extraVertexNodes','extraVertexXY'};
c.schema=all(isfield(D,need));
if ~c.schema,A=struct('pass',false,'checks',c,'added',{{}});return,end
added={};
if strcmp(stateId,'S0')
 assert(~isfield(D,'crackPolyline')&&~isfield(D,'tipTangent'),'G2M2Adapter:S0Schema','S0 unexpectedly already carries a polyline.');
 tip=D.X3(D.physicalTipNode,:);
 Dm.crackPolyline=[101.6 0;tip];Dm.tipTangent=[0 1];added={'crackPolyline','tipTangent'};
end
P=Dm.crackPolyline;t=Dm.tipTangent(:).';
c.tipMatchesPolyline=norm(D.X3(D.physicalTipNode,:)-P(end,:))<=1e-12&&abs(norm(t)-1)<=1e-12&& ...
 norm(t-(P(end,:)-P(end-1,:))/norm(P(end,:)-P(end-1,:)))<=1e-10;
c.polylineMatchesPreregistered=isequal(size(P),size(polyline))&&max(abs(P-polyline),[],'all')<=1e-9;
U=D.upperBankT6(:);L=D.lowerBankT6(:);
c.banksTwinned=numel(U)==numel(L)&&max(vecnorm(D.X6(U,:)-D.X6(L,:),2,2))<1e-9&&nnz(U==L)==1&& ...
 all(U(U==L)==D.physicalTipNode|vecnorm(D.X6(U(U==L),:)-P(end,:),2,2)<1e-9);
% distance of every bank node to the polyline, and its segment
ds=diff(P,1,1);lens=vecnorm(ds,2,2);tt=ds./lens;nn=[-tt(:,2),tt(:,1)];
seg=zeros(numel(U),1);dmin=inf(numel(U),1);
for k=1:numel(U)
 x=D.X6(U(k),:);
 for j=1:size(tt,1)
  h=max(0,min(lens(j),dot(x-P(j,:),tt(j,:))));d=norm(x-(P(j,:)+h*tt(j,:)));
  if d<dmin(k),dmin(k)=d;seg(k)=j;end
 end
end
c.banksOnPolyline=max(dmin)<1e-8;
% side test: element centroids touching upper (lower) nodes, excluding the tip and kink vertices
T3=D.T6(:,1:3);ctr=(D.X6(T3(:,1),:)+D.X6(T3(:,2),:)+D.X6(T3(:,3),:))/3;
isVtx=false(numel(U),1);
for j=1:size(P,1),isVtx=isVtx|vecnorm(D.X6(U,:)-P(j,:),2,2)<1e-9;end
okSide=true;nCheckedU=0;nCheckedL=0;
for k=find(~isVtx).'
 eu=find(any(D.T6==U(k),2));el=find(any(D.T6==L(k),2));j=seg(k);
 su=(ctr(eu,:)-D.X6(U(k),:))*nn(j,:).';sl=(ctr(el,:)-D.X6(L(k),:))*nn(j,:).';
 okSide=okSide&&all(su>0)&&all(sl<0)&&~isempty(eu)&&~isempty(el);
 nCheckedU=nCheckedU+numel(eu);nCheckedL=nCheckedL+numel(el);
end
c.upperBankOnPlusNSide=okSide;
xy=reshape(D.extraVertexXY,[],2);
c.anchorsPresent=numel(D.extraVertexNodes)==3&&all(ismember(round(1e6*[25.4 0;482.6 0;254 203.2]),round(1e6*xy),'rows'));
f=fieldnames(c);ok=cellfun(@(q)c.(q),f);
A=struct('pass',all(ok),'checks',c,'failed',{f(~ok)},'added',{added},'bankPairs',numel(U), ...
 'sideElementsChecked',[nCheckedU,nCheckedL],'maxBankOffPolyline_mm',max(dmin));
fprintf('G2_M2_ADAPTER %s pass=%d added=[%s] banks=%d side-checked U/L %d/%d\n',stateId,A.pass,strjoin(added,','),numel(U),nCheckedU,nCheckedL);
end
