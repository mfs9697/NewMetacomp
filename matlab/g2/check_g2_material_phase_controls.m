function C = check_g2_material_phase_controls(D,PM,geo,vopts)
%CHECK_G2_MATERIAL_PHASE_CONTROLS  Phase-map negative controls on in-memory copies of State 2 (Issue #33).
%
%  C = check_g2_material_phase_controls(D,PM,geo,vopts)
% D: saved State 2 mesh (never modified on disk); PM: accepted mapper result;
% geo: struct centers, holeR, interfaceR; vopts: verifier options used for the accepted map.
% Every corruption must be REJECTED by the mapper or the verifier (or both):
%  N1 swapped labels; N2 band element at an interface relabelled matrix; N3 matrix element
%  at an interface relabelled band; N4 detached interface (band-side nodes duplicated);
%  N5 nonconforming interface (one interface vertex moved 0.01 mm off the circle);
%  N6 filled void (fan of elements inside hole 1); N7 q domain reaching a band
%  (outer radius 45 mm); N9 band label inside the 15-mm tip guide.
X6=D.X6;T6=D.T6;ph=PM.phase;c=geo.centers;hr=geo.holeR;ir=geo.interfaceR;
mopts=struct('onCircleTol_mm',vopts.onCircleTol_mm,'minGap_mm',vopts.minGap_mm,'midsideTol_mm',vopts.onCircleTol_mm);
run=@(X,T,p,o)deal(g2_material_phase_map(X,T,c,hr,ir,mopts),g2_material_phase_verify(X,T,p,c,hr,ir,o));
I=PM.interfaces(1);
cases={};
% N1
p=3-ph;[m,v]=run(X6,T6,p,vopts);cases(end+1,:)={'N1_swapped_labels',m,v,true};
% N2 / N3
p=ph;p(I.innerOwner(1))=1;[m,v]=run(X6,T6,p,vopts);cases(end+1,:)={'N2_band_element_relabelled_matrix',m,v,true};
p=ph;p(I.outerOwner(1))=2;[m,v]=run(X6,T6,p,vopts);cases(end+1,:)={'N3_matrix_element_relabelled_band',m,v,true};
% N4 detached interface of circle 1
nodes=unique([I.vertexNodes;I.midsideNodes]);map=zeros(size(X6,1),1);map(nodes)=size(X6,1)+(1:numel(nodes));
X4=[X6;X6(nodes,:)];T4=T6;band=find(PM.annulusOf==1);
for e=band.',for q=1:6,if map(T4(e,q))>0,T4(e,q)=map(T4(e,q));end,end,end
[m,v]=run(X4,T4,ph,vopts);cases(end+1,:)={'N4_detached_interface',m,v,false};
% N5 one interface vertex moved off the circle (radially, +0.01 mm)
X5=X6;k=I.vertexNodes(1);dr=(X5(k,:)-c(1,:))/norm(X5(k,:)-c(1,:));X5(k,:)=X5(k,:)+.01*dr;
[m,v]=run(X5,T6,ph,vopts);cases(end+1,:)={'N5_nonconforming_interface',m,v,false};
% N6 filled void: centre node + fan of T6 elements on the hole-1 rim, labelled band
vt=unique(T6(:,1:3));rr=vecnorm(X6(vt,:)-c(1,:),2,2);rim=vt(abs(rr-hr(1))<1e-9);
[~,o]=sort(atan2(X6(rim,2)-c(1,2),X6(rim,1)-c(1,1)));rim=rim(o);
nr=numel(rim);n0=size(X6,1);X7=[X6;c(1,:)];ctr=n0+1;
Tnew=zeros(nr,6);Xm=zeros(0,2);
E3=[T6(:,[1 2 4]);T6(:,[2 3 5]);T6(:,[3 1 6])];key=sort(E3(:,1:2),2);
for j=1:nr
 a=rim(j);b=rim(mod(j,nr)+1);
 kk=find(key(:,1)==min(a,b)&key(:,2)==max(a,b),1);mab=E3(kk,3);
 Xm=[Xm;.5*(X6(a,:)+c(1,:));.5*(X6(b,:)+c(1,:))]; %#ok<AGROW>
 id=size(X7,1)+size(Xm,1)-1;
 Tnew(j,:)=[ctr,a,b,id,mab,id+1];   % counter-clockwise (rim sorted by increasing angle)
end
X7=[X7;Xm];T7=[T6;Tnew];p7=[ph;2*ones(nr,1)];
[m,v]=run(X7,T7,p7,vopts);
cases(end+1,:)={'N6_filled_void',m,v,false};
% N7 q domain reaching a band
o7=vopts;o7.qOuterRadii_mm=[vopts.qOuterRadii_mm(:);45];
[m,v]=run(X6,T6,ph,o7);cases(end+1,:)={'N7_q_domain_crossing_band',m,v,true};
% N9 band label inside the tip guide (element ~10 mm from the tip)
rE=vecnorm(.5*(X6(T6(:,1),:)+X6(T6(:,2),:))-vopts.tip(:).',2,2);[~,e9]=min(abs(rE-10));
p=ph;p(e9)=2;[m,v]=run(X6,T6,p,vopts);cases(end+1,:)={'N9_band_label_in_tip_guide',m,v,true};
n=size(cases,1);C=struct('pass',true,'cases',struct([]));
for i=1:n
 m=cases{i,2};v=cases{i,3};labelsOnly=cases{i,4};
 % for label-only corruptions the mesh is unchanged, so the mapper legitimately passes;
 % the verifier must reject. For mesh corruptions either may reject.
 rejected=~v.pass||(~labelsOnly&&~m.pass);
 C.cases(i).name=cases{i,1};C.cases(i).mapperPass=m.pass;C.cases(i).mapperStage=m.stage;
 C.cases(i).verifierPass=v.pass;C.cases(i).verifierFailed=strjoin(v.failed,',');C.cases(i).rejected=rejected;
 C.pass=C.pass&&rejected;
 fprintf('PHASE_NEG %-36s mapper=%d (%s) verifier=%d [%s] -> rejected=%d\n',cases{i,1},m.pass,m.stage,v.pass,strjoin(v.failed,','),rejected);
end
fprintf('G2_MATERIAL_PHASE_NEGATIVES_PASS=%d (%d cases)\n',C.pass,n);
end
