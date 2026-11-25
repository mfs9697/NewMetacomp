function T=m5x6_decompose(qHH,qXH,qHX,qXX,mode)
%M5X6_DECOMPOSE  Exact 2x2 material x path decomposition of one quantity (pure arithmetic).
%
%  T = m5x6_decompose(qHH,qXH,qHX,qXX,'relative')   % divide by qHH (G, J, K_I)
%  T = m5x6_decompose(qHH,qXH,qHX,qXX,'absolute')   % plain differences (MTS angle, K_II/K)
% qAB = quantity with material A on path B (H = homogeneous, X = architecture).
%   F_mat  = (qXH - qHH)/den      F_path = (qHX - qHH)/den
%   F_int  = (qXX - qXH - qHX + qHH)/den              F_tot = (qXX - qHH)/den
% F_tot = F_mat + F_path + F_int exactly; the split depends on the reference (H on Gamma_H).
% Alternatives reported for sensitivity of the bookkeeping, not as new physics:
%   Shapley:            F_mat + F_int/2 and F_path + F_int/2
%   reference X on X:   material and path effects measured from the architecture state
%   multiplicative (relative mode): R_mat = qXH/qHH, R_path = qHX/qHH, R_int = qXX qHH/(qXH qHX)
switch mode
 case 'relative',den=qHH;
 case 'absolute',den=1;
 otherwise,error('M5X6:Mode','mode must be relative or absolute');
end
T=struct('mode',mode,'qHH',qHH,'qXH',qXH,'qHX',qHX,'qXX',qXX);
T.F_mat=(qXH-qHH)/den;T.F_path=(qHX-qHH)/den;T.F_int=(qXX-qXH-qHX+qHH)/den;T.F_tot=(qXX-qHH)/den;
T.F_pathPlusInt=T.F_path+T.F_int;
T.identityResidual=T.F_tot-(T.F_mat+T.F_path+T.F_int);
T.shapley_mat=T.F_mat+T.F_int/2;T.shapley_path=T.F_path+T.F_int/2;
T.refXX_mat=(qXX-qHX)/den;T.refXX_path=(qXX-qXH)/den;
if strcmp(mode,'relative')
 T.R_mat=qXH/qHH;T.R_path=qHX/qHH;T.R_int=qXX*qHH/(qXH*qHX);T.R_tot=qXX/qHH;
 T.multiplicativeResidual=T.R_tot-T.R_mat*T.R_path*T.R_int;
end
end
