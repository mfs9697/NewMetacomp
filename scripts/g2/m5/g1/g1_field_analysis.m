function R=g1_field_analysis(execRepo,outDir)
%G1_FIELD_ANALYSIS  G1 read-only post-processing of SAVED elastic fields. No boundary-value problem.
%
%  R = g1_field_analysis(execRepo,outDir)
% Sources (all saved, manifest-verified records; nothing is solved):
%  M4.B frozen S2 ring factorial (Issue #47): mesh 9269be43..., CASE_none and the six single-ring
%       cases (contrast 0.5 and 2, rings 1/2/3)
%  R1 matched S2alt (Issue #50): mesh 0627dd3a..., the same seven cases on the other mesh family
%  LP1 homogeneous path H S0-S4 (A0-reproduced bitwise, PR #65): MESH, SOLUTION (u), PHASE (owner)
%  LP1 architecture states S0, S2, S4 (G only)
% Stress, strain and strain-energy density are RECONSTRUCTED element by element from the saved
% displacement u with the solver's own T6 kinematics and plane-stress D (per element phase);
% fidelity is checked against the saved element strain energies. Point values use the element that
% contains the point (no interpolation across elements, voids, cracks or interfaces).
% Writes outDir/G1_FIELD_EVIDENCE.json and outDir/G1_FIGDATA.mat.
g2=fullfile(execRepo,'matlab','g2');addpath(g2,'-begin');
assert(~isfolder(outDir),'G1:Out','Output folder exists.');mkdir(outDir);
lp=jsondecode(fileread(fullfile(g2,'G2_LP1_POLICY_v2.json')));Em=lp.bvp.E_MPa;nu=lp.bvp.nu;t=lp.bvp.thickness_mm;
m4p=jsondecode(fileread(fullfile(g2,'G2_M4B_POLICY_v2.json')));r1p=jsondecode(fileread(fullfile(g2,'G2_M4B_R1_POLICY_v1.json')));
L=struct('p0',[25.4 0],'p1',[254 203.2]);L.len=norm(L.p1-L.p0);L.e=(L.p1-L.p0)/L.len;L.n=[-L.e(2) L.e(1)];
L.angle_deg=atan2d(L.e(2),L.e(1));
cen=[152.4 69.85;152.4 120.65;152.4 171.45];rh=6.35;rr=19.05;
R=struct('schema','NewMetacomp.G2.G1.FieldEvidence.v1','boundaryValueProblemsSolved',0, ...
 'line',struct('from_pin',L.p0,'to_load',L.p1,'angle_deg',L.angle_deg,'ringCentreSignedDistance_mm',(cen-L.p0)*L.n.'));
FD=struct();
% ======================================================================= M4.B and R1 frozen S2
fam={'M4B','R1'};runs={fullfile('outputs','g2_m4b_ring_factorial_v1','run_20261121_194814_009'), ...
 fullfile('outputs','g2_m4b_r1_s2alt_v1','run_20261121_232938_287')};
meshF={m4p.reference.mesh,r1p.reference.mesh};meshS={m4p.reference.meshSHA256,r1p.reference.meshSHA256};
evd={'m4b_20261121','m4b_r1_20261121'};
ids={'none','c0p5_100','c0p5_010','c0p5_001','c2p0_100','c2p0_010','c2p0_001'};
for f=1:2
 mf=fullfile(execRepo,strrep(meshF{f},'/',filesep));
 assert(strcmpi(g2_sha256_file(mf),meshS{f}),'G1:Mesh','%s mesh bytes differ from the policy pin.',fam{f});
 D=load(mf);chkT3(D);TR=triangulation(D.T3,D.X3);
 S=struct();prov={};
 for k=1:numel(ids)
  % the execution-clone run folders hold the MAT files only; their manifests are committed evidence
  rf=fullfile(execRepo,runs{f},['CASE_' ids{k} '.mat']);h=lower(g2_sha256_file(rf));
  mj=jsondecode(fileread(fullfile(g2,'evidence',evd{f},'campaign',['CASE_' ids{k} '.mat.manifest.json'])));
  rec=load(rf,'record');rec=rec.record;
  assert(strcmpi(h,mj.SHA256)&&strcmp(rec.schema,mj.recordSchema)&&strcmpi(rec.meshSHA256,meshS{f})&&strcmp(rec.caseId,ids{k})&& ...
   isequal(rec.K.pass,true),'G1:Record','%s %s record fails verification against its committed manifest.',fam{f},ids{k});
  Ee=Em*ones(size(D.T6,1),1);c=rec.contrast;if ~isnan(c),Ee(rec.phaseForAssembly==2)=Em*c;end
  F=elemField(D,rec.K.u,Ee,nu);
  err=max(abs(F.eE-rec.K.elementStrainEnergy_per_thickness))/max(rec.K.elementStrainEnergy_per_thickness);
  errU=abs(sum(F.eE)/rec.K.strainEnergy_per_thickness-1);
  Gk=(rec.K.KI^2+rec.K.KII^2)/rec.K.Ep_matrix;
  S.(ids{k})=struct('F',F,'K',rec.K,'owner',rec.ownerRing,'phase',rec.phaseForAssembly,'contrast',c,'G',Gk,'Ee',Ee);
  prov{end+1}=struct('family',fam{f},'case',ids{k},'recordSHA256',lower(h),'meshSHA256',meshS{f}, ...
   'elementEnergyMaxRelErr',err,'totalEnergyRelErr',errU); %#ok<AGROW>
 end
 R.provenance.(fam{f})=[prov{:}];
 H=S.none;FH=H.F;
 % ---------------- G1b ring environments in the homogeneous field
 R.ringEnvironment.(fam{f})=ringEnv(FH,H.owner,cen,rh,rr,L);
 R.holeEdge.(fam{f})=holeFit(FH,H.owner,cen,rh,L);
 % ---------------- G1a corridor alignment and parallel controls (homogeneous field)
 R.corridor.(fam{f})=corridorStats(FH,H.owner,cen,L,D.crackPolyline);
 % ---------------- G1c single-ring effects and exact Betti identity on the frozen mesh
 sr={};
 for k=2:numel(ids)
  X=S.(ids{k});ring=find(ids{k}(end-2:end)=='1');lam=X.contrast;
  in=X.phase==2;dS=(1/lam-1)/Em;   % S_X - S_H for the same nu: (1/(lam Em) - 1/Em) * S_unit
  ib=bettiIntegral(D,H.K.u,X.K.u,in,Em,nu,dS);
  dC=X.K.compliance_mm_per_N-H.K.compliance_mm_per_N;
  sr{end+1}=struct('case',ids{k},'ring',ring,'contrast',lam,'F_G',X.G/H.G-1, ...
   'dKI_rel',X.K.KI/H.K.KI-1,'dMTS_deg',mts(X.K)-mts(H.K),'dCompliance_mm_per_N',dC, ...
   'bettiCompliance_mm_per_N',t*ib,'bettiRelErr',abs(t*ib/dC-1), ...
   'dU_ring_rel',(X.K.ringStrainEnergy_per_thickness(2:4)./H.K.ringStrainEnergy_per_thickness(2:4)-1).'); %#ok<AGROW>
 end
 R.singleRing.(fam{f})=[sr{:}];
 if f==1
  % principal-stress glyphs and trajectories (homogeneous S2 field, element-constant directions)
  R.trajectories=trajectories(D,TR,FH,L,cen,rh);
  FD.M4B=struct('X3',D.X3,'T3',D.T3,'crack',D.crackPolyline,'SED_H',FH.w,'s1_H',FH.s1,'s2_H',FH.s2,'th2_H',FH.th2, ...
   'cx',FH.cx,'cy',FH.cy,'owner',H.owner,'traj',{R.trajectories.paths});
  for k=2:numel(ids),FD.M4B.(['dSEDrel_' ids{k}])=S.(ids{k}).F.w./FH.w-1;end
  [gx,gy]=meshgrid(4:8:504,4:8:200);P=[gx(:),gy(:)];[ws,a2,s1p,s2p]=pointField(D,TR,H.K.u,H.Ee,nu,P);
  FD.M4B.glyph=struct('P',P,'w',ws,'th2',a2,'s1',s1p,'s2',s2p);
 end
end
% robustness of field metrics across the two mesh families
R.ringEnvironmentFamilyDiff=familyDiff(R.ringEnvironment.M4B,R.ringEnvironment.R1);
% ======================================================================= LP1 homogeneous path S0-S4
base=fullfile(execRepo,'outputs','g2_lp1_matrix_paths_v1','run_20261122_lp1_v1');
Hs=cell(1,5);hp={};
for s=0:4
 d=fullfile(base,'H',sprintf('S%d',s));
 [So,hs,ok1]=g2_trajectory_record('read',fullfile(d,'SOLUTION.mat'));[Ph,~,ok2]=g2_trajectory_record('read',fullfile(d,'PHASE.mat'));
 [St,~,ok3]=g2_trajectory_record('read',fullfile(d,'STATE.mat'));
 assert(ok1&&ok2&&ok3,'G1:LP1','LP1 H S%d records fail verification.',s);
 D=load(fullfile(d,'MESH.mat'));chkT3(D);owner=Ph.owner(:);
 F=elemField(D,So.K.u,Em*ones(size(D.T6,1),1),nu);
 hp{end+1}=struct('state',s,'solutionSHA256',lower(hs),'meshSHA256',So.meshSHA256, ...
  'elementEnergyMaxRelErr',max(abs(F.eE-So.K.elementStrainEnergy_per_thickness))/max(So.K.elementStrainEnergy_per_thickness), ...
  'ownerRingEnergyRelErr',max(abs(accumarray(owner+1,F.eE,[4 1])./So.K.ringStrainEnergy_per_thickness-1))); %#ok<AGROW>
 Hs{s+1}=struct('D',D,'u',So.K.u,'F',F,'owner',owner,'U',So.K.strainEnergy_per_thickness, ...
  'Uring',So.K.ringStrainEnergy_per_thickness(2:4).','G',St.G,'arc',St.arc_mm,'env',ringEnv(F,owner,cen,rh,rr,L), ...
  'hole',holeFit(F,owner,cen,rh,L));
end
R.provenance.LP1_H=[hp{:}];
arc=cellfun(@(h)h.arc,Hs);U=cellfun(@(h)h.U,Hs);Ur=cell2mat(cellfun(@(h)h.Uring,Hs,'UniformOutput',false).');GH=cellfun(@(h)h.G,Hs);
R.homogeneousPath=struct('arc_mm',arc,'U_total',U,'U_ring',Ur,'G_EDI',GH, ...
 'ringEnvironmentByState',{cellfun(@(h)h.env,Hs,'UniformOutput',false)}, ...
 'holeEdgeByState',{cellfun(@(h)h.hole,Hs,'UniformOutput',false)});
% architecture G on own paths at S0, S2, S4 (saved states only)
arch={'stiff13',[1 0 1],2;'soft2',[0 1 0],0.5;'soft1',[1 0 0],0.5};
st=[0 2 4];dif={[1 2],[2 4],[4 5]};lab={'S0 forward S0-S1','S2 central S1-S3','S4 backward S3-S4'};
fo={};
for a=1:3
 for j=1:3
  [Sa,~,oka]=g2_trajectory_record('read',fullfile(base,arch{a,1},sprintf('S%d',st(j)),'STATE.mat'));assert(oka,'G1:LP1','LP1 %s state unreadable.',arch{a,1});
  ii=dif{j};da=arc(ii(2))-arc(ii(1));dUk=(Ur(ii(2),:)-Ur(ii(1),:))/da;dU=(U(ii(2))-U(ii(1)))/da;
  m=logical(arch{a,2});lam=arch{a,3};
  pred=(1/lam-1)*sum(dUk(m))/dU;predG=(1/lam-1)*sum(dUk(m))/GH(st(j)+1);obs=Sa.G/GH(st(j)+1)-1;
  fo{end+1}=struct('architecture',arch{a,1},'state',st(j),'difference',lab{j},'firstOrder_dUda',pred, ...
   'firstOrder_GEDI',predG,'observed_F_G',obs,'observedOverFirstOrder',obs/pred,'signAgrees',sign(obs)==sign(pred), ...
   'note',ternary(st(j)==0,'S0: common geometry, observed = direct material effect', ...
   ternary(st(j)==2,'S2: observed on the own path (direct + path remainder)','S4: observed on the own path (direct + path remainder)'))); %#ok<AGROW>
 end
end
R.firstOrderArchitecture=[fo{:}];
% single rings at S2 (M4.B, R1) versus the first-order prediction from the homogeneous path
ii=[2 4];da=arc(4)-arc(2);dUk=(Ur(4,:)-Ur(2,:))/da;dU=(U(4)-U(2))/da;fs={};
for f=1:2
 for x=R.singleRing.(fam{f})
  p=(1/x.contrast-1)*dUk(x.ring)/dU;
  fs{end+1}=struct('family',fam{f},'case',x.case,'ring',x.ring,'contrast',x.contrast,'firstOrder',p, ...
   'observed_F_G',x.F_G,'observedOverFirstOrder',x.F_G/p,'signAgrees',sign(x.F_G)==sign(p)); %#ok<AGROW>
 end
end
R.firstOrderSingleRing=[fs{:}];R.firstOrderInputsS2=struct('dUring_da',dUk,'dU_da',dU,'G_EDI_S2',GH(3),'states',ii-1);
% ======================================================================= influence map d w / d a at S2
h1=Hs{2};h3=Hs{4};
[gx,gy]=meshgrid(0.5:1:507.5,0.5:1:202.7);P=[gx(:),gy(:)];
w1=pointField(h1.D,triangulation(h1.D.T3,h1.D.X3),h1.u,Em*ones(size(h1.D.T6,1),1),nu,P);
w3=pointField(h3.D,triangulation(h3.D.T3,h3.D.X3),h3.u,Em*ones(size(h3.D.T6,1),1),nu,P);
dwda=(w3-w1)/(arc(4)-arc(2));
crack3=h3.D.crackPolyline;dc=distToPolyline(P,crack3);
bad=dc<6|vecnorm(P-L.p1,2,2)<10|vecnorm(P-L.p0,2,2)<10|vecnorm(P-[482.6 0],2,2)<10;
iota=dwda/dU;iota(bad)=NaN;                    % first-order influence density, 1/mm^2
% ring integrals of the map (1 mm^2 samples) versus the record-based values
ringInt=zeros(1,3);for k=1:3,rk=vecnorm(P-cen(k,:),2,2);in=rk>rh&rk<rr;ringInt(k)=sum(iota(in),'omitnan');end
% 4 x 4 mm cell averages for display and band statistics
[cx,cy,cm,cn]=cellAverage(gx,gy,iota,4);
s=(P-L.p0)*L.n.';xi=(P-L.p0)*L.e.';
bands=[-90 -60;-60 -30;-30 -10;-10 10;10 30;30 60;60 90];bs={};
for b=1:size(bands,1)
 in=s>=bands(b,1)&s<bands(b,2)&xi>40&xi<L.len-40&~isnan(iota)&~inRings(P,cen,rr);
 bs{end+1}=struct('s_from_mm',bands(b,1),'s_to_mm',bands(b,2),'samples',nnz(in),'meanIota_per_mm2',mean(iota(in)), ...
  'fractionPositive',mean(iota(in)>0)); %#ok<AGROW>
end
alongLine=[];for q=40:10:L.len-40
 in=abs(xi-q)<=5&abs(s)<=5&~isnan(iota);alongLine(end+1,:)=[q,mean(iota(in)),nnz(in)]; %#ok<AGROW>
end
% the same band statistics separately for the lower (pin side) and upper (load side) parts of the line
xr=[40 120;120 L.len-40];bx={};
for r=1:2
 for b=1:size(bands,1)
  in=s>=bands(b,1)&s<bands(b,2)&xi>xr(r,1)&xi<xr(r,2)&~isnan(iota)&~inRings(P,cen,rr);
  bx{end+1}=struct('xi_from_mm',xr(r,1),'xi_to_mm',xr(r,2),'s_from_mm',bands(b,1),'s_to_mm',bands(b,2), ...
   'samples',nnz(in),'meanIota_per_mm2',mean(iota(in)),'fractionPositive',mean(iota(in)>0)); %#ok<AGROW>
 end
end
% transverse profiles across the line (influence and homogeneous S2 compression from M4.B CASE_none)
Dm=load(fullfile(execRepo,strrep(m4p.reference.mesh,'/',filesep)));Hn=load(fullfile(execRepo,runs{1},'CASE_none.mat'));
[~,~,~,s2m]=pointField(Dm,triangulation(Dm.T3,Dm.X3),Hn.record.K.u,Em*ones(size(Dm.T6,1),1),nu,P);
tp={};
for q=[150 175 200 230]
 sb=-60:2:60;mi=nan(size(sb));ms=mi;
 for j=1:numel(sb)
  in=abs(xi-q)<=3&abs(s-sb(j))<=1;v=in&~isnan(iota);if nnz(v)>=3,mi(j)=mean(iota(v));end
  v=in&~isnan(s2m);if nnz(v)>=3,ms(j)=mean(s2m(v));end
 end
 [~,j0]=min(abs(sb));neg=mi<0;lo=NaN;hi=NaN;
 if neg(j0),a=j0;while a>1&&neg(a-1),a=a-1;end;b=j0;while b<numel(sb)&&neg(b+1),b=b+1;end;lo=sb(a);hi=sb(b);end
 [~,jm]=min(ms);
 tp{end+1}=struct('xi_mm',q,'s_mm',sb,'meanIota',mi,'meanSigma2',ms,'negativeRunThroughLine_s_mm',[lo hi], ...
  'sAtMostCompressiveSigma2_mm',sb(jm)); %#ok<AGROW>
end
% vertical profile through the ring column x = 152.4 mm (outside holes)
cp=[];for yy=26:2:200
 in=abs(P(:,1)-152.4)<=2&abs(P(:,2)-yy)<=1&~isnan(iota);if nnz(in)>=3,cp(end+1,:)=[yy,mean(iota(in)),nnz(in)];end %#ok<AGROW>
end
R.influenceMapProfiles=struct('bandsByLinePart',[bx{:}],'transverse',[tp{:}],'ringColumn_y_meanIota_n',cp);
R.influenceMap=struct('states','LP1 H S1 and S3 (central difference at S2)','grid_mm',1,'masks', ...
 'crack +/- 6 mm, 10 mm around load, pin and roller; holes are voids (no element, no value)', ...
 'ringIntegral_fromMap',ringInt,'ringIntegral_fromRecords',dUk/dU,'bands',[bs{:}], ...
 'alongLine_xi_meanIota_n',alongLine,'positiveFraction',mean(iota(~isnan(iota))>0));
FD.influence=struct('cx',cx,'cy',cy,'iota',cm,'count',cn,'crackS1',h1.D.crackPolyline,'crackS3',crack3);
FD.line=L;FD.cen=cen;FD.homPath=R.homogeneousPath;
save(fullfile(outDir,'G1_FIGDATA.mat'),'-struct','FD','-v7.3');
fid=fopen(fullfile(outDir,'G1_FIELD_EVIDENCE.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('G1_FIELD_ANALYSIS done: provenance M4B max %.2e, R1 max %.2e, LP1 max %.2e\n', ...
 max([R.provenance.M4B.elementEnergyMaxRelErr]),max([R.provenance.R1.elementEnergyMaxRelErr]),max([R.provenance.LP1_H.elementEnergyMaxRelErr]));
end

% ======================================================================= helpers
function chkT3(D)
for k=1:3,assert(isequal(D.X6(D.T6(:,k),:),D.X3(D.T3(:,k),:)),'G1:T3','T3 and T6 vertex numbering differ.');end
end
function F=elemField(D,u,Ee,nu)
X=D.X6;T=D.T6;M=size(T,1);x=reshape(X(T(:),1),M,6);y=reshape(X(T(:),2),M,6);
J11=x(:,2)-x(:,1);J12=x(:,3)-x(:,1);J21=y(:,2)-y(:,1);J22=y(:,3)-y(:,1);dJ=J11.*J22-J12.*J21;
ux=u(1:2:end);uy=u(2:2:end);UX=ux(T);UY=uy(T);c=Ee(:)./(1-nu^2);D11=c;D12=c*nu;D33=c*(1-nu)/2;
qp=[1/6 1/6;2/3 1/6;1/6 2/3];eE=zeros(M,1);
for g=1:3
 [e1,e2,e3]=strain(qp(g,1),qp(g,2));eE=eE+.5*(1/6)*dJ.*((D11.*e1+D12.*e2).*e1+(D12.*e1+D11.*e2).*e2+D33.*e3.*e3);
end
[e1,e2,e3]=strain(1/3,1/3);sxx=D11.*e1+D12.*e2;syy=D12.*e1+D11.*e2;sxy=D33.*e3;
m=(sxx+syy)/2;r=sqrt(((sxx-syy)/2).^2+sxy.^2);th1=.5*atan2(2*sxy,sxx-syy);
F=struct('eE',eE,'A',dJ/2,'cx',mean(x(:,1:3),2),'cy',mean(y(:,1:3),2),'sxx',sxx,'syy',syy,'sxy',sxy, ...
 's1',m+r,'s2',m-r,'th1',th1,'th2',th1+pi/2,'w',eE./(dJ/2));
 function [ex,ey,gxy]=strain(rr,ss)
  [dNr,dNs]=t6dN(rr,ss);Nx=(J22*dNr-J21*dNs)./dJ;Ny=(-J12*dNr+J11*dNs)./dJ;
  ex=sum(Nx.*UX,2);ey=sum(Ny.*UY,2);gxy=sum(Ny.*UX+Nx.*UY,2);
 end
end
function [dNr,dNs]=t6dN(r,s)
t=1-r-s;dNr=[-(4*t-1),4*r-1,0,4*(t-r),4*s,-4*s];dNs=[-(4*t-1),0,4*s-1,-4*r,4*r,4*(t-s)];
end
function [w,th2,s1,s2]=pointField(D,TR,u,Ee,nu,P)
n=size(P,1);w=nan(n,1);th2=w;s1=w;s2=w;e=pointLocation(TR,P);v=find(~isnan(e));e=e(v);
T=D.T6(e,:);X=D.X6;x=reshape(X(T(:),1),[],6);y=reshape(X(T(:),2),[],6);
J11=x(:,2)-x(:,1);J12=x(:,3)-x(:,1);J21=y(:,2)-y(:,1);J22=y(:,3)-y(:,1);dJ=J11.*J22-J12.*J21;
px=P(v,1)-x(:,1);py=P(v,2)-y(:,1);r=(J22.*px-J12.*py)./dJ;q=(-J21.*px+J11.*py)./dJ;tt=1-r-q;
dNr=[-(4*tt-1),4*r-1,zeros(size(r)),4*(tt-r),4*q,-4*q];dNs=[-(4*tt-1),zeros(size(r)),4*q-1,-4*r,4*r,4*(tt-q)];
Nx=(J22.*dNr-J21.*dNs)./dJ;Ny=(-J12.*dNr+J11.*dNs)./dJ;ux=u(1:2:end);uy=u(2:2:end);UX=ux(T);UY=uy(T);
ex=sum(Nx.*UX,2);ey=sum(Ny.*UY,2);g=sum(Ny.*UX+Nx.*UY,2);c=Ee(e)./(1-nu^2);
sxx=c.*(ex+nu*ey);syy=c.*(nu*ex+ey);sxy=c.*(1-nu)/2.*g;
w(v)=.5*(sxx.*ex+syy.*ey+sxy.*g);m=(sxx+syy)/2;rr=sqrt(((sxx-syy)/2).^2+sxy.^2);
s1(v)=m+rr;s2(v)=m-rr;th2(v)=.5*atan2(2*sxy,sxx-syy)+pi/2;
end
function E=ringEnv(F,owner,cen,rh,rr,L)
E=struct('ring',{},'region',{},'area_mm2',{},'meanSxx',{},'meanSyy',{},'meanSxy',{},'avgTensor_s1',{},'avgTensor_s2',{}, ...
 'compressiveAxisAngleToLine_deg',{},'meanSED',{},'fracCompressionDominated',{},'fracTensionDominated',{},'signedDistanceToLine_mm',{});
for k=1:3
 rk=hypot(F.cx-cen(k,1),F.cy-cen(k,2));
 regs={owner==k,'ring (6.35-19.05 mm)';owner==0&rk>rr&rk<rr+6.35,'halo (19.05-25.4 mm)'};
 for j=1:2
  in=regs{j,1};A=F.A(in);a=sum(A);sx=sum(A.*F.sxx(in))/a;sy=sum(A.*F.syy(in))/a;sxy=sum(A.*F.sxy(in))/a;
  m=(sx+sy)/2;r=sqrt(((sx-sy)/2)^2+sxy^2);th2=.5*atan2(2*sxy,sx-sy)+pi/2;
  ang=abs(mod(rad2deg(th2)-L.angle_deg+90,180)-90);
  cd=F.s2(in)<0&abs(F.s2(in))>abs(F.s1(in));td=F.s1(in)>0&abs(F.s1(in))>=abs(F.s2(in));
  E(end+1)=struct('ring',k,'region',regs{j,2},'area_mm2',a,'meanSxx',sx,'meanSyy',sy,'meanSxy',sxy,'avgTensor_s1',m+r,'avgTensor_s2',m-r, ...
   'compressiveAxisAngleToLine_deg',ang,'meanSED',sum(F.eE(in))/a,'fracCompressionDominated',sum(A(cd))/a, ...
   'fracTensionDominated',sum(A(td))/a,'signedDistanceToLine_mm',(cen(k,:)-L.p0)*L.n.'); %#ok<AGROW>
 end
end
end
function E=holeFit(F,owner,cen,rh,L)
% Kirsch-type reading of the hoop stress on the first element layer at each hole edge (approximate):
% sigma_tt(t) ~ a0 + a1c cos t + a1s sin t + a2c cos 2t + a2s sin 2t; for a locally uniform far field
% with principal stresses sA >= sB, a0 = sA + sB and the 2t term is -2 (sA - sB) cos 2(t - phiA).
E=struct('ring',{},'elements',{},'sA',{},'sB',{},'phiA_deg',{},'compressiveAxisAngleToLine_deg',{},'R2',{});
for k=1:3
 rk=hypot(F.cx-cen(k,1),F.cy-cen(k,2));in=owner==k&rk<rh+1;
 th=atan2(F.cy(in)-cen(k,2),F.cx(in)-cen(k,1));sn=sin(th);cs=cos(th);
 stt=F.sxx(in).*sn.^2+F.syy(in).*cs.^2-2*F.sxy(in).*sn.*cs;
 B=[ones(size(th)),cs,sn,cos(2*th),sin(2*th)];w=sqrt(F.A(in));a=(B.*w)\(stt.*w);
 res=stt-B*a;R2=1-sum(F.A(in).*res.^2)/sum(F.A(in).*(stt-sum(F.A(in).*stt)/sum(F.A(in))).^2);
 dl=hypot(a(4),a(5))/2;phiA=.5*atan2(-a(5),-a(4));phiB=phiA+pi/2;
 E(end+1)=struct('ring',k,'elements',nnz(in),'sA',(a(1)+dl)/2,'sB',(a(1)-dl)/2,'phiA_deg',rad2deg(phiA), ...
  'compressiveAxisAngleToLine_deg',abs(mod(rad2deg(phiB)-L.angle_deg+90,180)-90),'R2',R2); %#ok<AGROW>
end
end
function C=corridorStats(F,owner,cen,L,crack)
s=([F.cx F.cy]-L.p0)*L.n.';xi=([F.cx F.cy]-L.p0)*L.e.';dc=distToPolyline([F.cx F.cy],crack);
ang=abs(mod(rad2deg(F.th2)-L.angle_deg+90,180)-90);
near=false(size(s));for k=1:3,near=near|hypot(F.cx-cen(k,1),F.cy-cen(k,2))<25;end
off=[-60 -30 0 30 60];C=struct('offset_mm',{},'elements',{},'area_mm2',{},'medianAngle_deg',{},'fracWithin15deg',{}, ...
 'fracWithin30deg',{},'fracCompressionDominated',{},'meanS2',{},'meanSED',{});
for o=off
 in=abs(s-o)<=10&xi>40&xi<L.len-40&~near&owner==0&dc>10;A=F.A(in);a=sum(A);
 cd=F.s2(in)<0&abs(F.s2(in))>abs(F.s1(in));
 C(end+1)=struct('offset_mm',o,'elements',nnz(in),'area_mm2',a,'medianAngle_deg',wmedian(ang(in),A), ...
  'fracWithin15deg',sum(A(ang(in)<=15))/a,'fracWithin30deg',sum(A(ang(in)<=30))/a,'fracCompressionDominated',sum(A(cd))/a, ...
  'meanS2',sum(A.*F.s2(in))/a,'meanSED',sum(F.eE(in))/a); %#ok<AGROW>
end
end
function m=wmedian(x,w)
[x,i]=sort(x);w=w(i);c=cumsum(w)/sum(w);m=x(find(c>=.5,1));
end
function I=bettiIntegral(D,uH,uX,in,Em,nu,dS)
% integral over the active elements of sigma_H : (S_X - S_H) : sigma_X (3-point rule, per unit thickness)
X=D.X6;T=D.T6(in,:);M=size(T,1);x=reshape(X(T(:),1),M,6);y=reshape(X(T(:),2),M,6);
J11=x(:,2)-x(:,1);J12=x(:,3)-x(:,1);J21=y(:,2)-y(:,1);J22=y(:,3)-y(:,1);dJ=J11.*J22-J12.*J21;
Su=[1 -nu 0;-nu 1 0;0 0 2*(1+nu)];c=Em/(1-nu^2);Dm=c*[1 nu 0;nu 1 0;0 0 (1-nu)/2];
lam=1/(1+dS*Em);qp=[1/6 1/6;2/3 1/6;1/6 2/3];I=0;
for g=1:3
 [dNr,dNs]=t6dN(qp(g,1),qp(g,2));Nx=(J22*dNr-J21*dNs)./dJ;Ny=(-J12*dNr+J11*dNs)./dJ;
 eH=epsOf(uH);eX=epsOf(uX);sH=eH*Dm.';sX=lam*(eX*Dm.');
 I=I+sum((1/6)*dJ.*sum((sH*(dS*Su).').*sX,2));
end
 function e=epsOf(u)
  ux=u(1:2:end);uy=u(2:2:end);UX=ux(T);UY=uy(T);e=[sum(Nx.*UX,2),sum(Ny.*UY,2),sum(Ny.*UX+Nx.*UY,2)];
 end
end
function th=mts(K)
M=g2_mts_direction(K.KI,K.KII);th=M.theta_deg;
end
function T=trajectories(D,TR,F,L,cen,rh)
seeds=[70 150 230];paths={};rows={};
for sd=seeds
 x0=L.p0+sd*L.e;
 for dirn=[1 -1]
  [p,why]=march(TR,F.th2,x0,dirn*L.e,L);paths{end+1}=p; %#ok<AGROW>
  s=(p-L.p0)*L.n.';d2=min(vecnorm(p-cen(2,:),2,2));
  rows{end+1}=struct('seed_xi_mm',sd,'direction',dirn,'points',size(p,1),'length_mm',sum(vecnorm(diff(p,1,1),2,2)), ...
   'maxAbsOffsetFromLine_mm',max(abs(s)),'endOffsetFromLine_mm',s(end),'end_mm',p(end,:),'stop',why, ...
   'minDistanceToHole2Centre_mm',d2,'entersRing2',d2<19.05,'reachesHole2Edge',d2<=rh+0.5); %#ok<AGROW>
 end
end
T=struct('method','streamlines of the element-constant compressive principal direction (sigma_2 axis) of the reconstructed homogeneous S2 field; RK2, step 0.5 mm; stop at a void/outside, near the load/pin or after 400 mm','paths',{paths},'rows',[rows{:}]);
end
function [p,why]=march(TR,th2,x,d,L)
h=.5;p=x;why='length';
for i=1:800
 e=pointLocation(TR,x);if isnan(e),why='void_or_outside';break,end
 a=[cos(th2(e)) sin(th2(e))];if dot(a,d)<0,a=-a;end
 xm=x+.5*h*a;em=pointLocation(TR,xm);if isnan(em),why='void_or_outside';break,end
 b=[cos(th2(em)) sin(th2(em))];if dot(b,a)<0,b=-b;end
 x=x+h*b;d=b;p(end+1,:)=x; %#ok<AGROW>
 if norm(x-L.p1)<8,why='near_load';break,end
 if norm(x-L.p0)<8,why='near_pin';break,end
end
end
function d=distToPolyline(P,Q)
d=inf(size(P,1),1);
for j=1:size(Q,1)-1
 a=Q(j,:);b=Q(j+1,:);ab=b-a;t=max(0,min(1,((P-a)*ab.')/(ab*ab.')));d=min(d,vecnorm(P-(a+t.*ab),2,2));
end
end
function b=inRings(P,cen,rr)
b=false(size(P,1),1);for k=1:3,b=b|vecnorm(P-cen(k,:),2,2)<rr;end
end
function [cx,cy,cm,cn]=cellAverage(gx,gy,v,k)
V=reshape(v,size(gx));nr=floor(size(gx,1)/k);nc=floor(size(gx,2)/k);cm=nan(nr,nc);cn=zeros(nr,nc);cx=cm;cy=cm;
for i=1:nr
 for j=1:nc
  blk=V((i-1)*k+(1:k),(j-1)*k+(1:k));ok=~isnan(blk);cn(i,j)=nnz(ok);
  cx(i,j)=mean(gx(1,(j-1)*k+(1:k)));cy(i,j)=mean(gy((i-1)*k+(1:k),1));
  if cn(i,j)>=0.75*k*k,cm(i,j)=mean(blk(ok));end
 end
end
end
function D=familyDiff(A,B)
D=struct('ring',{},'region',{},'meanSED_relDiff',{},'compressiveAxisAngle_diff_deg',{});
for i=1:numel(A)
 D(end+1)=struct('ring',A(i).ring,'region',A(i).region,'meanSED_relDiff',B(i).meanSED/A(i).meanSED-1, ...
  'compressiveAxisAngle_diff_deg',B(i).compressiveAxisAngleToLine_deg-A(i).compressiveAxisAngleToLine_deg); %#ok<AGROW>
end
end
function y=ternary(c,a,b)
if c,y=a;else,y=b;end
end
