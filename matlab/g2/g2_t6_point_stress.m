function s = g2_t6_point_stress(X6,T6,u,Dk,elems,P)
%G2_T6_POINT_STRESS  Stress [sxx syy sxy] of straight-sided T6 elements at given points (Issue #33).
%
%  s = g2_t6_point_stress(X6,T6,u,Dk,elems,P)
% elems(i) is the element evaluated at point P(i,:) (the point may lie on its edge);
% Dk is 3-by-3-by-n with the constitutive matrix used for point i (the phase of
% that element). Local coordinates from the affine T3 parent map. Units mm, MPa.
n=numel(elems);s=zeros(n,3);ux=u(1:2:end);uy=u(2:2:end);
for i=1:n
 e=T6(elems(i),:);x=X6(e,1);y=X6(e,2);
 J=[x(2)-x(1),x(3)-x(1);y(2)-y(1),y(3)-y(1)];
 rs=J\(P(i,:).'-[x(1);y(1)]);r=rs(1);q=rs(2);t=1-r-q;
 dNr=[-(4*t-1),4*r-1,0,4*(t-r),4*q,-4*q];
 dNs=[-(4*t-1),0,4*q-1,-4*r,4*r,4*(t-q)];
 G=J.'\[dNr;dNs];            % [dN/dx; dN/dy]
 ex=G(1,:)*ux(e);ey=G(2,:)*uy(e);gxy=G(2,:)*ux(e)+G(1,:)*uy(e);
 s(i,:)=(Dk(:,:,i)*[ex;ey;gxy]).';
end
end
