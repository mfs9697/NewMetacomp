function [D,Ep,kappa,mu] = g2_plane_D(mat)
%G2_PLANE_D  Plane-stress / plane-strain elasticity matrix (Voigt [s11 s22 s12] = D*[e11 e22 2e12]).
% Also returns E' (stress: E; strain: E/(1-nu^2)), Kolosov kappa and shear modulus mu.
E=mat.E;nu=mat.nu;mu=E/(2*(1+nu));
switch lower(mat.plane)
 case 'stress'
  D=E/(1-nu^2)*[1 nu 0;nu 1 0;0 0 (1-nu)/2];Ep=E;kappa=(3-nu)/(1+nu);
 case 'strain'
  D=E/((1+nu)*(1-2*nu))*[1-nu nu 0;nu 1-nu 0;0 0 (1-2*nu)/2];Ep=E/(1-nu^2);kappa=3-4*nu;
 otherwise
  error('G2T6:Plane','mat.plane must be ''stress'' or ''strain''.');
end
end
