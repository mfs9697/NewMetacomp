function K = g2_wp3_sif_on_mesh(D, mat)
%G2_WP3_SIF_ON_MESH  WP2 idealized BVP on a saved kinked mesh struct + EDI/COD and the WP3.2 checks.
% D: loaded KINKED_GEOMETRY_ONLY_candidate.mat. mat: struct E, nu, plane.
% Returns K (MPa*sqrt(mm) per N line load P/t with P = 1 N, t = 12.7 mm), the
% five-annulus EDI, 4x4 EDI, bank-ID COD and the C1/C2/M2/M3/M4/QK verdicts.
f=1/12.7;N=size(D.X6,1);P=D.crackPolyline;tip=P(end,:);t=D.tipTangent(:).';
nodeAt=@(xy)D.extraVertexNodes(vecnorm(D.extraVertexXY-xy,2,2)<1e-9);
pin=nodeAt([25.4 0]);rol=nodeAt([482.6 0]);ld=nodeAt([254 203.2]);
assert(isscalar(pin)&&isscalar(rol)&&isscalar(ld),'G2W3S:BCNodes','Support/load nodes missing.');
F=zeros(2*N,1);F(2*ld)=-f;bc=struct('fixedDofs',[2*pin-1;2*pin;2*rol],'fixedValues',[0;0;0],'F',F);
S=g2_t6_elasticity(D.X6,D.T6,mat,bc);Rf=S.reactions;
statics=[abs(Rf(1))/f,abs(Rf(2)+Rf(3)-f)/f,abs(25.4*Rf(2)+482.6*Rf(3)-254*f)/(f*457.2), ...
 abs(Rf(3)/f-(254-25.4)/457.2),abs(Rf(2)/f-(482.6-254)/457.2)];
an=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];ed=zeros(5,3);qmax=0;
for j=1:5,R=g2_sif_interaction(D.X6,D.T6,S.u,mat,tip,t,an(j,1),an(j,2),6);ed(j,:)=[R.KI,R.KII,R.J];qmax=max(qmax,R.maxSupportRadius);end
R4=g2_sif_interaction(D.X6,D.T6,S.u,mat,tip,t,.4,2.6,4);
C=g2_sif_cod_banks(D.X6,S.u,mat,tip,t,D.upperBankT6,D.lowerBankT6,4,[.1 1.5]);
[~,Ep]=g2_plane_D(mat);Kr=hypot(ed(1,1),ed(1,2));
crit=struct('C1',S.relativeResidual<=1e-8&&max(statics)<=1e-8, ...
 'C2',max(abs([ed(1,1)-C.KI,ed(1,2)-C.KII]))/Kr<=.03, ...
 'M2',max(max(ed(:,1:2))-min(ed(:,1:2)))/Kr<=.005, ...
 'M3',abs(ed(1,3)/((ed(1,1)^2+ed(1,2)^2)/Ep)-1)<=.005, ...
 'M4',max(abs([R4.KI-ed(1,1),R4.KII-ed(1,2)]))/Kr<=.001, ...
 'QK',qmax<3*cos(pi/64));
K=struct('KI',ed(1,1),'KII',ed(1,2),'J',ed(1,3),'EDI_all',ed,'KI_COD',C.KI,'KII_COD',C.KII,'relativeResidual',S.relativeResidual, ...
 'staticsMax',max(statics),'qSupportMaxRadius',qmax,'criteria',crit,'pass',all(cell2mat(struct2cell(crit))), ...
 'KI_MPa_sqrt_m_per_kN',ed(1,1)*sqrt(1000),'KII_MPa_sqrt_m_per_kN',ed(1,2)*sqrt(1000));
end
