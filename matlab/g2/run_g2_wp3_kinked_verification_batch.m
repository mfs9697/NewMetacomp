function V=run_g2_wp3_kinked_verification_batch(manifestMAT)
%RUN_G2_WP3_KINKED_VERIFICATION_BATCH  WP3.2 test MK: manufactured ROTATED Williams fields (WP3_PREREGISTRATION s.6).
% Domain: the rotated kernel + collar of g2_kinked_regular_block for the manifest
% polyline (t1/n1 frame), exact Williams displacements on the r = 3.3 mm rim, crack
% faces free. EDI (g2_sif_interaction with tdir = t1) and bank-ID COD
% (g2_sif_cod_banks) against the exact K; five annuli, 4x4 vs 6x6, J identity.
% Thresholds are the WP2 ones, unchanged. Writes a NEW outputs/g2_wp3_kinked_verification/run_*.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
vendor=fullfile(here,'vendor_p010_a14d8872');addpath(vendor,'-begin');
outRoot=fullfile(repo,'outputs','g2_wp3_kinked_verification');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'kinked_verification_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_WP3_2_MK_ROTATED_MANUFACTURED\nDATE=%s\nMATLAB_RELEASE=%s\nOUTDIR=%s\n',datestr(now,31),version('-release'),folder);
TOL=struct('edi',.010,'cod',.030,'path',.005,'energy',.005,'quad',.001);
V=struct('pass',false,'tolerances',TOL,'manifestSHA256','','cases',struct([]),'exception','');
try
 V.manifestSHA256=g2_sha256_file(manifestMAT);S=load(manifestMAT,'Mf');Mf=S.Mf;
 P=Mf.trial.crackPolyline_mm;t=Mf.trial.t(:).';n=[-t(2),t(1)];
 B=g2_kinked_regular_block(P,'ExpectedTangent',t);assert(B.pass,'G2KV:Block','Rotated block HOLD: %s',B.stage);
 X6=B.coord6;T6=B.connect6;tip=B.summary.tip_mm;
 mat=struct('E',3268.115,'nu',.35,'plane','stress');[~,Ep,kap,mu]=g2_plane_D(mat);
 % boundary edges; crack faces on local eta = 0 behind the tip, side by owner centroid
 E3=[T6(:,[1 2 4]);T6(:,[2 3 5]);T6(:,[3 1 6])];own=repmat((1:size(T6,1))',3,1);
 [~,~,ic]=unique(sort(E3(:,1:2),2),'rows');cnt=accumarray(ic,1);b=cnt(ic)==1;
 lx=@(ids)(X6(ids,:)-tip)*t.';ly=@(ids)(X6(ids,:)-tip)*n.';
 face=b&abs(ly(E3(:,1)))<1e-9&abs(ly(E3(:,2)))<1e-9&lx(E3(:,1))<1e-9&lx(E3(:,2))<1e-9;
 ce=(X6(T6(own,1),:)+X6(T6(own,2),:)+X6(T6(own,3),:))/3;sd=(ce-tip)*n.';
 Ub=unique(reshape(E3(face&sd>0,:),[],1));Lb=unique(reshape(E3(face&sd<0,:),[],1));
 bnd=unique(reshape(E3(b,:),[],1));rimN=setdiff(bnd,union(Ub,Lb));
 % rim: 65 corners at 3.3 + 64 chord midsides at 3.3 cos(pi/64) = 129 nodes, minus the two
 % crack-entry corners (on eta = 0), which belong to the free faces exactly as in WP2 M1
 rr=vecnorm(X6(rimN,:)-tip,2,2);onRim=bnd(vecnorm(X6(bnd,:)-tip,2,2)>=3.3*cos(pi/64)-1e-9);
 entryFree=setdiff(onRim,rimN);
 assert(numel(rimN)==127&&all(rr>=3.3*cos(pi/64)-1e-9&rr<=3.3+1e-9)&&numel(entryFree)==2&& ...
   all(abs(ly(entryFree))<1e-9)&&all(abs(lx(entryFree)+3.3)<1e-9),'G2KV:Rim','Unexpected Dirichlet node set (%d).',numel(rimN));
 cases=[1 0 0;0 1 0;0 -1 0;.6 -.8 0;1 0 .2;.6 -.8 -.2];
 annuli=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];allOK=true;rows={};
 for k=1:size(cases,1)
  KI=cases(k,1);KII=cases(k,2);T=cases(k,3);Kref=hypot(KI,KII);
  W=g2_williams_field(lx(rimN),ly(rimN),KI,KII,T,mu,kap);ug=W.u1*t+W.u2*n;
  bc=struct('fixedDofs',[2*rimN-1;2*rimN],'fixedValues',[ug(:,1);ug(:,2)],'F',zeros(2*size(X6,1),1));
  Sv=g2_t6_elasticity(X6,T6,mat,bc);
  ed=zeros(5,3);for j=1:5,Rj=g2_sif_interaction(X6,T6,Sv.u,mat,tip,t,annuli(j,1),annuli(j,2),6);ed(j,:)=[Rj.KI,Rj.KII,Rj.J];end
  R4=g2_sif_interaction(X6,T6,Sv.u,mat,tip,t,.4,2.6,4);
  Cc=g2_sif_cod_banks(X6,Sv.u,mat,tip,t,Ub,Lb,4,[.1 1.5]);
  eE=max(abs(ed(1,1:2)-[KI KII]))/Kref;eC=max(abs([Cc.KI Cc.KII]-[KI KII]))/Kref;
  sp=max(max(ed(:,1:2))-min(ed(:,1:2)))/Kref;eJ=abs(ed(1,3)/((ed(1,1)^2+ed(1,2)^2)/Ep)-1);
  eQ=max(abs([R4.KI R4.KII]-ed(1,1:2)))/Kref;
  sg=(KII==0)||(sign(ed(1,2))==sign(KII)&&sign(Cc.KII)==sign(KII));
  ok=eE<=TOL.edi&&eC<=TOL.cod&&sp<=TOL.path&&eJ<=TOL.energy&&eQ<=TOL.quad&&sg;allOK=allOK&&ok;
  rows(end+1,:)={KI,KII,T,ed(1,1),ed(1,2),Cc.KI,Cc.KII,eE,eC,sp,eJ,eQ,sg,ok,Sv.relativeResidual}; %#ok<AGROW>
  fprintf('MK (%.1f,%.1f,T=%.1f): EDI (%.6f,%.6f) err %.3e | COD (%.6f,%.6f) err %.3e | spread %.3e | J %.3e | quad %.3e | sign %d -> %d\n', ...
   KI,KII,T,ed(1,1),ed(1,2),eE,Cc.KI,Cc.KII,eC,sp,eJ,eQ,sg,ok);
 end
 Tm=cell2table(rows,'VariableNames',{'KI','KII','T','KI_EDI','KII_EDI','KI_COD','KII_COD','errEDI','errCOD','pathSpread','energyErr','quadErr','signOK','pass','residual'});
 writetable(Tm,fullfile(folder,'MK_rotated_manufactured.csv'));V.cases=table2struct(Tm);
 V.pass=allOK;V.faceNodesPerBank=[numel(Ub),numel(Lb)];V.dirichletNodes=numel(rimN);
catch ME
 V.exception=getReport(ME,'extended','hyperlinks','off');fprintf(2,'G2_WP3_MK_EXCEPTION=%s\n',V.exception);
end
f=fopen(fullfile(folder,'mk_summary.json'),'w');fwrite(f,jsonencode(V,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_WP3_2_MK_PASS=%d\n',V.pass);
if ~V.pass,error('G2KV:HOLD','MK HOLD (see %s).',folder);end
end
