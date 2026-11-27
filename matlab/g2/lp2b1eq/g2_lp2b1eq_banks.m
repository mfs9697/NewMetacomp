function B=g2_lp2b1eq_banks(D,matchTol)
%G2_LP2B1EQ_BANKS  Crack-bank stations of ONE mesh (pure; no displacement, no I/O).
%  B = g2_lp2b1eq_banks(D)        D.X6, D.upperBankT6, D.lowerBankT6, D.crackPolyline (optional D.physicalTipNode)
% Upper and lower bank T6 node lists are sorted by arc-length station along the crack polyline with the SAME
% nearest-segment projection and stable sort as the accepted WP5 comparator (g2_lp2a2_eq_compare, jumps/station).
% Instead of asserting, defects are returned in B.problems (verification-infrastructure, never numerical):
%  BANK_FIELDS, BANK_POLYLINE, BANK_INDEX (non-integer, out of range, empty, unequal lengths), BANK_PAIRING (sorted
%  banks do not coincide within matchTol, default 1e-9 mm), BANK_DUPLICATE_STATION (non-unique upper stations),
%  BANK_DUPLICATE_ID (repeated ID within a bank), BANK_SHARED_ID (upper and lower share an ID anywhere other than
%  exactly one node at the polyline tip, which must be physicalTipNode when that field exists).
% Fields: s (upper stations, ascending), up, lo (paired IDs), x (upper coordinates), kq (segment index), n, tipNode,
% sharedIds, problems.
if nargin<2,matchTol=1e-9;end
B=struct('s',[],'up',[],'lo',[],'x',[],'kq',[],'n',0,'tipNode',NaN,'sharedIds',[],'problems',{{}});
if ~isstruct(D)||~all(isfield(D,{'X6','upperBankT6','lowerBankT6','crackPolyline'})),B.problems{end+1}='BANK_FIELDS';return,end
X=D.X6;P=D.crackPolyline;up=D.upperBankT6(:);lo=D.lowerBankT6(:);N=size(X,1);
if ~(isnumeric(X)&&isreal(X)&&size(X,2)==2&&all(isfinite(X(:)))),B.problems{end+1}='BANK_FIELDS';return,end
if ~(isnumeric(P)&&isreal(P)&&size(P,2)==2&&size(P,1)>=2&&all(isfinite(P(:)))&&all(vecnorm(diff(P),2,2)>0)),B.problems{end+1}='BANK_POLYLINE';return,end
ix=@(v)isnumeric(v)&&~isempty(v)&&all(isfinite(v))&&all(v==round(v))&&all(v>=1)&&all(v<=N);
if ~(ix(up)&&ix(lo)&&numel(up)==numel(lo)),B.problems{end+1}='BANK_INDEX';return,end
up=double(up);lo=double(lo);
if numel(unique(up))~=numel(up)||numel(unique(lo))~=numel(lo),B.problems{end+1}='BANK_DUPLICATE_ID';end
x=X(up,:);[s,kq]=station(x,P);[s,o]=sort(s);up=up(o);x=x(o,:);kq=kq(o);
sl=station(X(lo,:),P);[~,o]=sort(sl);lo=lo(o);
if max(vecnorm(X(up,:)-X(lo,:),2,2))>matchTol,B.problems{end+1}='BANK_PAIRING';end
if numel(unique(s))~=numel(s),B.problems{end+1}='BANK_DUPLICATE_STATION';end
sh=intersect(up,lo);B.sharedIds=sh(:).';tip=P(end,:);
okTip=isscalar(sh)&&norm(X(sh,:)-tip)<=matchTol&&up(end)==sh&&lo(end)==sh&&all(up(1:end-1)~=lo(1:end-1));
if isfield(D,'physicalTipNode'),okTip=okTip&&isequal(double(D.physicalTipNode),sh);end
if ~okTip,B.problems{end+1}='BANK_SHARED_ID';else,B.tipNode=sh;end
B.s=s;B.up=up;B.lo=lo;B.x=x;B.kq=kq;B.n=numel(up);
end

function [s,k]=station(X,P)
% identical to the WP5 comparator: nearest segment, clamped projection, station = cumulative length + offset
tt=diff(P);L=vecnorm(tt,2,2);tt=tt./L;Sv=[0;cumsum(L)];M=size(X,1);dk=inf(M,numel(L));lk=dk;
for q=1:numel(L),l=max(0,min(L(q),(X-P(q,:))*tt(q,:).'));dk(:,q)=vecnorm(X-(P(q,:)+l*tt(q,:)),2,2);lk(:,q)=l;end
[~,k]=min(dk,[],2);s=Sv(k)+lk(sub2ind(size(lk),(1:M)',k));
end
