function R=g2_a1_geometry_qualification(a0RunRoot,outRoot)
%G2_A1_GEOMETRY_QUALIFICATION  Geometry-only A1 matrix: 4 frozen S4 paths x Family B m=0,3,6,9 (Issue #66).
%
%  R = g2_a1_geometry_qualification(a0RunRoot,outRoot)
% a0RunRoot: <exec>/outputs/g2_lp1_matrix_paths_v1/run_a0_lp1_repro_v1 (accepted A0 records, read only)
% outRoot  : new folder for the 12 candidate meshes (m = 3, 6, 9) and the qualification JSON.
% For every case and level: g2_a1_patch_swap, g2_a1_mesh_validate, the unchanged
% g2_m2_state_adapter and g2_lp0_phase_audit (phase map, independent verifier, owner oracle,
% all four masks, activation negatives), owner-free q supports for all five annuli.
% m = 0 must reproduce the saved A0 S4 mesh exactly (no FEM). Candidates are saved with
% file SHA-256 and a MAT-independent content SHA-256. No PDE, loads, solve, COD, EDI or SIF.
assert(isfolder(a0RunRoot),'G2A1:Input','A0 run root not found.');
assert(~isfolder(outRoot),'G2A1:Output','Refusing to reuse an existing output folder.');mkdir(outRoot);
here=fileparts(mfilename('fullpath'));pol=jsondecode(fileread(fullfile(here,'G2_LP1_POLICY_v2.json')));
cases={'H','stiff13','soft2','soft1'};levels=[0 3 6 9];
keyF={'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','qActiveT6Rows','elementRows', ...
 'collarOuterIDs','extraVertexXY','extraVertexNodes','includeHoles','plateXRange','crackPolyline','tipTangent','tipNormal','kinkNodeIDs'};
C=pol.geometry.centres_mm;an=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];
rowsOut=struct('caseId',{},'m',{},'pass',{},'validator',{},'adapterPass',{},'phaseAuditPass',{},'qOwnerFree',{}, ...
 'baselineExact',{},'summary',{},'fileSHA256',{},'contentSHA256',{},'meshFile',{},'seconds',{});
QA=struct();
for c=1:4
 src=fullfile(a0RunRoot,cases{c},'S4','MESH.mat');D=load(src);srcSHA=fsha(src);
 for m=levels
  t0=tic;
  if m==0,spec=struct('family','BASE');else,spec=struct('family','B','extraBandPairs',m);end
  [~,M]=evalc('g2_a1_patch_swap(D,spec)');
  V=g2_a1_mesh_validate(M,D);
  [~,~,Ad]=evalc('g2_m2_state_adapter(M,''LP1'',M.crackPolyline)');
  [~,PA]=evalc('g2_lp0_phase_audit(M,M.crackPolyline,pol)');
  O=g2_m4b_ring_owner_oracle(M.X6,M.T6,C,6.35*ones(3,1),19.05*ones(3,1),struct('onCircleTol_mm',1e-9));
  r6=vecnorm(M.X6-M.crackPolyline(end,:),2,2);free=true;
  for k=1:5
   qq=ones(size(r6));qq(r6>=an(k,2))=0;tr=r6>an(k,1)&r6<an(k,2);qq(tr)=(an(k,2)-r6(tr))/(an(k,2)-an(k,1));
   act=find(max(qq(M.T6),[],2)-min(qq(M.T6),[],2)>1e-14);free=free&&all(O.ownerOracle(act)==0);
  end
  exact=NaN;if m==0,exact=all(cellfun(@(k)isequal(M.(k),D.(k)),keyF));end
  ok=V.pass&&Ad.pass&&PA.pass&&free&&(m~=0||exact==1);
  file='';fs='';cs=g2_a1_mesh_content_sha(M);
  if m>0
   d=fullfile(outRoot,cases{c},sprintf('B%d',m));mkdir(d);file=fullfile(d,'MESH.mat');
   Mesh=M;Mesh.a1.sourceA0MeshSHA256=srcSHA;Mesh.a1.contentSHA256=cs; %#ok<NASGU>
   save(file,'-struct','Mesh','-v7.3');fs=fsha(file);
  end
  rowsOut(end+1)=struct('caseId',cases{c},'m',m,'pass',ok,'validator',rmfield(V,'summary'),'adapterPass',Ad.pass, ...
   'phaseAuditPass',PA.pass,'qOwnerFree',free,'baselineExact',exact,'summary',V.summary,'fileSHA256',fs, ...
   'contentSHA256',cs,'meshFile',strrep(file,outRoot,'<outRoot>'),'seconds',toc(t0)); %#ok<AGROW>
  fprintf('A1_GEOM %s B%d pass=%d gates=%d/%d adapter=%d phase=%d qFree=%d exact=%g T3=%d DOF=%d h1=%.9f q=%d\n', ...
   cases{c},m,ok,V.gatesPassed,V.gatesTotal,Ad.pass,PA.pass,free,exact,V.summary.T3,V.summary.DOF, ...
   V.summary.tipFirstEdgeRadial_mm,V.summary.qActivePrimary);
  QA.(sprintf('%s_B%d',cases{c},m))=struct('X6',M.X6,'T6',M.T6,'act',M.qActiveT6Rows);
 end
end
% common q-active discretization B6 vs B9 (primary annulus), matched by physical coordinates
common=struct('caseId',{},'nB6',{},'nB9',{},'matched',{},'maxNodeDiff_mm',{},'sameFunctional',{});
for c=1:4
 a=QA.(sprintf('%s_B6',cases{c}));b=QA.(sprintf('%s_B9',cases{c}));
 ca=round(1e9*squeeze(mean(reshape(a.X6(a.T6(a.act,:),:),numel(a.act),6,2),2)));
 cb=round(1e9*squeeze(mean(reshape(b.X6(b.T6(b.act,:),:),numel(b.act),6,2),2)));
 [f,loc]=ismember(ca,cb,'rows');dmax=0;
 for k=find(f).'
  ea=a.X6(a.T6(a.act(k),:),:);eb=b.X6(b.T6(b.act(loc(k)),:),:);
  [~,ia]=sortrows(round(1e9*ea));[~,ib]=sortrows(round(1e9*eb));dmax=max(dmax,max(abs(ea(ia,:)-eb(ib,:)),[],'all'));
 end
 common(end+1)=struct('caseId',cases{c},'nB6',numel(a.act),'nB9',numel(b.act),'matched',nnz(f), ...
  'maxNodeDiff_mm',dmax,'sameFunctional',all(f)&&numel(a.act)==numel(b.act)&&dmax<1e-12); %#ok<AGROW>
 fprintf('A1_QCOMMON %s B6=%d B9=%d matched=%d maxdiff=%.3g same=%d\n',cases{c},numel(a.act),numel(b.act),nnz(f),dmax,common(end).sameFunctional);
end
R=struct('schema','NewMetacomp.G2.A1.GeometryQualification.v1','rows',rowsOut,'commonQActiveB6B9',common, ...
 'pass',all([rowsOut.pass]),'physicalSolves',0,'generateMeshCalled',false,'source','g2_a1_patch_swap');
fid=fopen(fullfile(outRoot,'A1_GEOMETRY_QUALIFICATION.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('A1_GEOMETRY_QUALIFICATION pass=%d rows=%d/%d\n',R.pass,nnz([rowsOut.pass]),numel(rowsOut));
end

function h=fsha(file)
fid=fopen(file,'r');b=fread(fid,inf,'*uint8');fclose(fid);
md=java.security.MessageDigest.getInstance('SHA-256');md.update(b);
h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
