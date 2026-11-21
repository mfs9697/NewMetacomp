function A = g2_m4b_attribution(Gv,THv)
%G2_M4B_ATTRIBUTION  Factorial decomposition of F_G and F_theta with both uncertainty rules (Issue #47).
%
%  A = g2_m4b_attribution(Gv,THv)
% Gv, THv: 8-by-E matrices, rows in the canonical mask order
%   [none, {1}, {2}, {3}, {1,2}, {1,3}, {2,3}, {1,2,3}],
% columns = estimator variants, column 1 = primary (EDI 6x6, q 0.4-2.6 mm), column E = blind COD.
% Gv in N/mm (any consistent unit), THv in degrees (S2 tip frame).
% Every reported quantity Q is a fixed linear combination a of the eight case values
% v (v_k = G_k/G_none for F_G, v_k = theta_k for F_theta). For each variant e the same
% combination is evaluated with that variant in every case (paired, correlated).
%  primary:      U = max_e |Q_e - Q|, resolved iff |Q| > 2U and sign(Q_COD) == sign(Q)
%  conservative: G     U = sum_{k~=none} |a_k| v_k d_k + |sum_{k~=none} a_k v_k| d_none,
%                      d_k = |G_EDI,k - G_COD,k| / G_EDI,k; resolved iff |Q| > U and COD sign agrees
%                theta U = sum_k |a_k| |theta_COD,k - theta_EDI,k|; resolved iff |Q| > U
% Terms: F_S (7 subsets), f_i, I_ij, I_123, Shapley phi_i, 1-ring differences f_i - f_j,
% 2-ring differences F_ij - F_ik. Identities: reconstruction and Shapley sum.
assert(isequal(size(Gv,1),8)&&isequal(size(THv,1),8)&&size(Gv,2)==size(THv,2)&&size(Gv,2)>=2,'G2M4B:AttribShape','Expected 8-by-E inputs.');
names={'F_1','F_2','F_3','F_12','F_13','F_23','F_123','f_1','f_2','f_3','I_12','I_13','I_23','I_123', ...
 'phi_1','phi_2','phi_3','d_1_2','d_1_3','d_2_3','D_12_13','D_12_23','D_13_23'};
% rows: none 1, s1 2, s2 3, s3 4, s12 5, s13 6, s23 7, s123 8
e=@(i)full(sparse(1,i,1,1,8));
F=@(i)e(i)-e(1);
a=zeros(numel(names),8);
a(1,:)=F(2);a(2,:)=F(3);a(3,:)=F(4);a(4,:)=F(5);a(5,:)=F(6);a(6,:)=F(7);a(7,:)=F(8);
a(8,:)=F(2);a(9,:)=F(3);a(10,:)=F(4);
a(11,:)=F(5)-F(2)-F(3);a(12,:)=F(6)-F(2)-F(4);a(13,:)=F(7)-F(3)-F(4);
a(14,:)=F(8)-F(2)-F(3)-F(4)-a(11,:)-a(12,:)-a(13,:);
a(15,:)=F(2)/3+(F(5)-F(3))/6+(F(6)-F(4))/6+(F(8)-F(7))/3;
a(16,:)=F(3)/3+(F(5)-F(2))/6+(F(7)-F(4))/6+(F(8)-F(6))/3;
a(17,:)=F(4)/3+(F(6)-F(2))/6+(F(7)-F(3))/6+(F(8)-F(5))/3;
a(18,:)=F(2)-F(3);a(19,:)=F(2)-F(4);a(20,:)=F(3)-F(4);
a(21,:)=F(5)-F(6);a(22,:)=F(5)-F(7);a(23,:)=F(6)-F(7);
A=struct('termNames',{names},'coefficients',a);
A.G=one(a,Gv./Gv(1,:),'G',Gv);
A.theta=one(a,THv,'theta',THv);
% identities (primary column)
for obs={'G','theta'}
 q=A.(obs{1});v=q.Q;id=@(n)v(strcmp(names,n));
 q.reconstructionResidual=id('F_123')-(id('f_1')+id('f_2')+id('f_3')+id('I_12')+id('I_13')+id('I_23')+id('I_123'));
 q.shapleySumResidual=id('F_123')-(id('phi_1')+id('phi_2')+id('phi_3'));
 A.(obs{1})=q;
end
end

function q=one(a,V,kind,raw)
nE=size(V,2);Qe=a*V;                         % terms x variants
Q=Qe(:,1);Qcod=Qe(:,nE);
U=max(abs(Qe(:,2:end)-Q),[],2);
resP=abs(Q)>2*U&sign(Qcod)==sign(Q);
if strcmp(kind,'G')
 r=V(:,1);d=abs(raw(:,1)-raw(:,nE))./raw(:,1);
 nz=2:8;Uc=abs(a(:,nz))*(r(nz).*d(nz))+abs(a(:,nz)*r(nz))*d(1);
 resC=abs(Q)>Uc&sign(Qcod)==sign(Q);
 extra=struct('d_EDI_COD',d.');
else
 ek=abs(V(:,nE)-V(:,1));Uc=abs(a)*ek;resC=abs(Q)>Uc;
 extra=struct('e_EDI_COD_deg',ek.');
end
cls=repmat({'UNRESOLVED'},numel(Q),1);cls(resP&~resC)={'RESOLVED_PRIMARY_ONLY'};cls(resP&resC)={'RESOLVED_BOTH'};
cls(~resP&resC)={'RESOLVED_CONSERVATIVE_ONLY'};
q=struct('Q',Q,'Q_variants',Qe,'Q_COD',Qcod,'U_primary',U,'resolvedPrimary',resP,'U_conservative',Uc, ...
 'resolvedConservative',resC,'class',{cls},'extra',extra);
end
