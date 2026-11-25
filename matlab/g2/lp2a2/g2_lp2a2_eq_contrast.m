function R=g2_lp2a2_eq_contrast(KN,KA,tol)
%G2_LP2A2_EQ_CONTRAST  Architecture-contrast check of the SIF-equivalence campaign (pure function).
% KN, KA: structs with fields H, stiff13, soft2, soft1, each holding KI and KII (new family and
% archived LP2-A1 S8). F_G = G_X/G_H - 1 and dTheta = theta_X - theta_H are recomputed in both
% families; pass requires |F_G,new - F_G,archived| <= tol.contrast_FG_abs, unchanged sign and
% order of F_G, and |dTheta_new - dTheta_archived| <= tol.contrast_MTS_deg.
X={'stiff13','soft2','soft1'};G=@(K)K.KI^2+K.KII^2;th=@(K)getfield(g2_mts_direction(K.KI,K.KII),'theta_deg');
FN=zeros(1,3);FA=FN;TN=FN;TA=FN;
for k=1:3
 FN(k)=G(KN.(X{k}))/G(KN.H)-1;FA(k)=G(KA.(X{k}))/G(KA.H)-1;
 TN(k)=th(KN.(X{k}))-th(KN.H);TA(k)=th(KA.(X{k}))-th(KA.H);
end
[~,oN]=sort(FN);[~,oA]=sort(FA);
c=struct('FG_within',max(abs(FN-FA))<=tol.contrast_FG_abs,'FG_signs',isequal(sign(FN),sign(FA)),'FG_order',isequal(oN,oA), ...
 'MTS_contrast_within',max(abs(TN-TA))<=tol.contrast_MTS_deg);
v=cell2mat(struct2cell(c));f=fieldnames(c);
R=struct('pass',all(v),'criteria',c,'failed',{f(~v)},'cases',{X},'FG_new',FN,'FG_archived',FA,'dFG',FN-FA, ...
 'dTheta_new_deg',TN,'dTheta_archived_deg',TA,'ddTheta_deg',TN-TA);
end
