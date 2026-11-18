function smoke2()
% Diagnostic (disclosed, development only): source of the O(h) nodal displacement error in the coated-hole benchmark.
a=6.35;b=19.05;c=57.15;Em=3268.115;nu=.35;mk=@(E)struct('E',E,'nu',nu,'plane','stress');
for ratio=[1 2]
 X=g2_coated_hole_exact(a,b,c,ratio*Em,Em,nu,1);
 for holeDir=[false true]
  for h=[4.8 2.4 1.2 0.6]
   [X6,T6,outerN,holeN]=mesh1(a,b,c,h);
   P=g2_material_phase_map(X6,T6,[0 0],a,b,struct());
   nodes=outerN;if holeDir,nodes=[outerN;holeN];end
   ue=X.field(X6(nodes,:));
   bc=struct('fixedDofs',[2*nodes-1;2*nodes],'fixedValues',[ue(:,1);ue(:,2)],'F',zeros(2*size(X6,1),1));
   S=g2_t6_elasticity_phase(X6,T6,P.phase,[mk(Em),mk(ratio*Em)],bc);
   uex=X.field(X6);uh=[S.u(1:2:end),S.u(2:2:end)];err=vecnorm(uh-uex,2,2);
   [em,im]=max(err);r=hypot(X6(im,1),X6(im,2));
   isv=im<=max(T6(:,1:3),[],'all');
   rms=sqrt(mean(err.^2))/max(vecnorm(uex,2,2));
   fprintf('ratio=%g holeDirichlet=%d h=%.2f e_max=%.4g at r=%.3f (vertex=%d) e_rms=%.4g e_U=%.4g holeChords=%d\n', ...
    ratio,holeDir,h,em/max(vecnorm(uex,2,2)),r,isv,rms,abs(S.strainEnergy-X.energy)/X.energy,numel(holeN)/2);
  end
 end
end
end
function [X6,T6,outerN,holeN]=mesh1(a,b,c,h)
gd=[1 0 0 c;1 0 0 b;1 0 0 a].';[dl,~]=decsg(gd,'(C3+C2)-C1',char('C3','C2','C1').');
model=createpde(1);geometryFromEdges(model,dl);msh=generateMesh(model,'GeometricOrder','linear','Hmax',h,'Hmin',h/4,'Hgrad',1.3);
X=msh.Nodes.';T=msh.Elements.';
M=size(T,1);E=[T(:,[1 2]);T(:,[2 3]);T(:,[3 1])];[Eu,~,ie]=unique(sort(E,2),'rows');
X6=[X;.5*(X(Eu(:,1),:)+X(Eu(:,2),:))];T6=[T,size(X,1)+reshape(ie,M,3)];
r=hypot(X6(:,1),X6(:,2));
E6=[T6(:,[1 2 4]);T6(:,[2 3 5]);T6(:,[3 1 6])];key=sort(E6(:,1:2),2);[~,~,j]=unique(key,'rows');cnt=accumarray(j,1);bnd=cnt(j)==1;
rv=r(E6(:,1));outerN=unique(reshape(E6(bnd&rv>(a+c)/2,:),[],1));holeN=unique(reshape(E6(bnd&rv<(a+c)/2,:),[],1));
end
