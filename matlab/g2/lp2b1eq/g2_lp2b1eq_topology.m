function T=g2_lp2b1eq_topology(Dn,Do,nBlk)
%G2_LP2B1EQ_TOPOLOGY  Protected-block topology of a new mesh versus the archived mesh under global renumbering (pure).
%  T = g2_lp2b1eq_topology(Dnew, Dold)          nBlk = 2916 protected T3/T6 rows (core 2788 + collar 128)
% T6 midside IDs are numbered over the whole mesh, so coordinate equality alone does not prove topology. The map
% old ID -> new ID is built from ELEMENT-LOCAL positions of the protected T6 rows (row e, local node j) and must be:
%  function     every occurrence of an old ID maps to the same new ID
%  injective    distinct old IDs map to distinct new IDs (so the map is a bijection between the block node sets;
%               coincident upper/lower crack-bank nodes stay DISTINCT IDs, hence distinct DOFs 2i-1, 2i)
%  coordinates  X6_new(map(i)) == X6_old(i) bitwise;  nodal q equal at mapped nodes; qActiveT6Rows equal
%  T3 block     T3 rows and the X3 block vertices identical (vertex IDs are protected and not renumbered)
%  banks        map(old upper-bank block nodes) == new upper-bank block nodes (as sets), same for lower; the only
%               block node common to both banks is the physical tip node, in both meshes, and map(tip) = new tip
%  coincidence  every set of coincident block nodes is exactly one {upper, lower} bank pair, in both meshes
% T.pass = all checks; T.checks names each; counts reported.
if nargin<3,nBlk=2916;end
c=struct();
c.blockRows=isfield(Dn,'elementRows')&&isfield(Do,'elementRows')&&Dn.elementRows.collar(end)==nBlk&&Do.elementRows.collar(end)==nBlk&& ...
 Dn.elementRows.core(end)==2788&&Do.elementRows.core(end)==2788&&size(Dn.T6,1)>=nBlk&&size(Do.T6,1)>=nBlk;
T=struct('pass',false,'checks',c,'blockNodes',NaN,'bankPairsInBlock',NaN,'distinctBankDOFsInBlock',NaN,'tipOld',NaN,'tipNew',NaN);
if ~c.blockRows,T.checks=c;return,end
T6o=double(Do.T6(1:nBlk,:));T6n=double(Dn.T6(1:nBlk,:));
[uo,~,io]=unique(T6o(:));nv=T6n(:);
lo=accumarray(io,nv,[],@min);hi=accumarray(io,nv,[],@max);c.function=isequal(lo,hi);mp=lo;
c.injective=c.function&&numel(unique(mp))==numel(mp);
c.coordinates=c.injective&&isequal(Dn.X6(mp,:),Do.X6(uo,:));
c.nodalQ=c.injective&&isequal(Dn.nodalQ(mp),Do.nodalQ(uo));
c.qActiveRows=isequal(Dn.qActiveT6Rows,Do.qActiveT6Rows)&&all(Dn.qActiveT6Rows<=nBlk);
vb=unique(double(Do.T3(1:nBlk,:)));
c.T3block=isequal(Dn.T3(1:nBlk,:),Do.T3(1:nBlk,:))&&isequal(Dn.X3(vb,:),Do.X3(vb,:));
uoU=intersect(uo,double(Do.upperBankT6(:)));uoL=intersect(uo,double(Do.lowerBankT6(:)));
mapf=@(ids)mp(arrayfun(@(i)find(uo==i,1),ids));
nU=intersect(mp,double(Dn.upperBankT6(:)));nL=intersect(mp,double(Dn.lowerBankT6(:)));
c.banks=c.injective&&isequal(sort(mapf(uoU)),sort(nU))&&isequal(sort(mapf(uoL)),sort(nL));
shO=intersect(uoU,uoL);shN=intersect(nU,nL);
tipO=NaN;tipN=NaN;if isfield(Do,'physicalTipNode'),tipO=double(Do.physicalTipNode);end;if isfield(Dn,'physicalTipNode'),tipN=double(Dn.physicalTipNode);end
c.tip=isscalar(shO)&&isscalar(shN)&&isequal(shO,tipO)&&isequal(shN,tipN)&&c.injective&&isequal(mapf(shO),shN)&& ...
 isequal(Do.X6(tipO,:),Do.crackPolyline(end,:))&&isequal(Dn.X6(tipN,:),Dn.crackPolyline(end,:));
c.coincidenceOld=pairsOnly(Do.X6(uo,:),uo,uoU,uoL);c.coincidenceNew=c.injective&&pairsOnly(Dn.X6(mp,:),mp,nU,nL);
T.checks=c;T.pass=all(cell2mat(struct2cell(c)));T.blockNodes=numel(uo);
T.bankPairsInBlock=numel(setdiff(uoU,shO));T.distinctBankDOFsInBlock=2*numel(unique([nU;nL]));T.tipOld=tipO;T.tipNew=tipN;
end

function ok=pairsOnly(X,ids,U,L)
% coincident node groups (identical coordinates) must be exactly one upper and one lower bank node
[~,~,g]=unique(X,'rows');cnt=accumarray(g,1);ok=all(cnt<=2);
for k=find(cnt==2).'
 p=ids(g==k);ok=ok&&numel(intersect(p,U))==1&&numel(intersect(p,L))==1&&numel(intersect(p,intersect(U,L)))==0;
end
end
