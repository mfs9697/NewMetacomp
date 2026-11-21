function C = check_g2_m4b_activation_negatives(D,PM,geo,vopts,mk)
%CHECK_G2_M4B_ACTIVATION_NEGATIVES  Mutations the M4.B activation verifier must reject (Issue #47).
%
%  C = check_g2_m4b_activation_negatives(D,PM,geo,vopts,mk)
% D: saved S2 mesh (X6,T6); PM: qualified phase map (annulusOf); geo/vopts: verifier
% inputs; mk: @(E) material constructor. A positive control (mask 100, c = 0.5) must
% PASS first. Each negative case is built from that control and must FAIL, and the
% intended check must be among the failed checks (a rejection for an unrelated reason
% does not count). Nothing is written.
Em=vopts.E_matrix;own=PM.annulusOf(:);
base=g2_m4b_ring_activation(own,[1 0 0]);mats=[mk(Em),mk(.5*Em)];
o=vopts;o.contrast=.5;
V0=g2_m4b_activation_verify(D.X6,D.T6,own,base.phaseForAssembly,base.mask,mats,geo,o);
cases=struct('name',{},'expect',{},'rejected',{},'failed',{});
% N1 wrong binary mask: labels of ring 2 declared as mask 100
a=g2_m4b_ring_activation(own,[0 1 0]);
cases=run(cases,'N1_wrong_mask','phaseFromMask',D.X6,D.T6,own,a.phaseForAssembly,[1 0 0],mats,geo,o);
% N2 swapped ring IDs 1 <-> 3 in the owner field
ow=own;ow(own==1)=3;ow(own==3)=1;a=g2_m4b_ring_activation(ow,[1 0 0]);
cases=run(cases,'N2_swapped_ring_ids','oracleAgreement',D.X6,D.T6,ow,a.phaseForAssembly,[1 0 0],mats,geo,o);
% N3 swapped physical centre order (descending y)
g=geo;g.centres=flipud(geo.centres);g.holeR=flipud(geo.holeR);g.ringR=flipud(geo.ringR);
cases=run(cases,'N3_swapped_centre_order','centresAscendingY',D.X6,D.T6,own,base.phaseForAssembly,[1 0 0],mats,g,o);
% N4 off-band E: the matrix owner of one ring-1 chord gets label 2
I=PM.interfaces(1);ph=base.phaseForAssembly;ph(I.outerOwner(1))=2;
cases=run(cases,'N4_off_band_E','phaseFromMask',D.X6,D.T6,own,ph,[1 0 0],mats,geo,o);
% N5 ring-owned element dropped from the owner field
ow=own;e1=find(own==1,1);ow(e1)=0;a=g2_m4b_ring_activation(ow,[1 0 0]);
cases=run(cases,'N5_ring_element_dropped','oracleAgreement',D.X6,D.T6,ow,a.phaseForAssembly,[1 0 0],mats,geo,o);
% N6 detached midside on one active chord: the outer owner gets its own coincident node
X=D.X6;T=D.T6;m=I.midsideNodes(1);eo=I.outerOwner(1);X(end+1,:)=X(m,:);T(eo,T(eo,:)==m)=size(X,1);
cases=run(cases,'N6_detached_midside','chordsConforming',X,T,own,base.phaseForAssembly,[1 0 0],mats,geo,o);
% N7 q domain reaching ring 1 (radius = tip-to-ring distance + 1 mm)
rr=V0.values.ringNodeMinDistanceToTip_mm;oq=o;oq.qOuterRadii_mm=[o.qOuterRadii_mm(:);rr+1];
cases=run(cases,'N7_q_reaches_ring','qSupportOwnerFree',D.X6,D.T6,own,base.phaseForAssembly,[1 0 0],mats,geo,oq);
% N8 void filling: a midside node of a hole-edge element moved 0.2 mm into hole 1
X=D.X6;hv=unique(D.T6(own==1,:));rh=hypot(X(hv,1)-geo.centres(1,1),X(hv,2)-geo.centres(1,2));
[~,k]=min(abs(rh-geo.holeR(1)-0.05));n8=hv(k);
dirc=(geo.centres(1,:)-X(n8,:))/norm(geo.centres(1,:)-X(n8,:));X(n8,:)=geo.centres(1,:)-(geo.holeR(1)-0.2)*dirc;
cases=run(cases,'N8_node_in_hole','noVoidFilling',X,D.T6,own,base.phaseForAssembly,[1 0 0],mats,geo,o);
% N9 wrong active modulus for c = 0.5
mw=[mk(Em),mk(.6*Em)];
cases=run(cases,'N9_wrong_modulus','materialsAdmissible',D.X6,D.T6,own,base.phaseForAssembly,[1 0 0],mw,geo,o);
% N10 inactive ring 2 given the material jump (labels of mask 110, declared 100)
a=g2_m4b_ring_activation(own,[1 1 0]);
cases=run(cases,'N10_inactive_ring_jump','passiveChordsNoJump',D.X6,D.T6,own,a.phaseForAssembly,[1 0 0],mats,geo,o);
ok=[cases.rejected];
C=struct('pass',V0.pass&&all(ok),'positiveControlPass',V0.pass,'positiveFailed',{V0.failed},'cases',cases);
fprintf('M4B_ACTIVATION_NEGATIVES positive=%d, rejected %d/%d -> pass=%d\n',V0.pass,nnz(ok),numel(ok),C.pass);
end

function cases=run(cases,name,expect,X,T,own,ph,mask,mats,geo,o)
V=g2_m4b_activation_verify(X,T,own,ph,mask,mats,geo,o);
rej=~V.pass&&any(strcmp(V.failed,expect));
cases(end+1)=struct('name',name,'expect',expect,'rejected',rej,'failed',{V.failed});
fprintf('  %-26s expect %-24s rejected=%d failed=[%s]\n',name,expect,rej,strjoin(V.failed,','));
end
