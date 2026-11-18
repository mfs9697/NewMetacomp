function R=run_g2_wp3_kinked_mesh_batch(manifestMAT,familyTag,mirror,varargin)
%RUN_G2_WP3_KINKED_MESH_BATCH  WP3.1: build and save ONE kinked protected Cornell #1 mesh (geometry only).
%  R = run_g2_wp3_kinked_mesh_batch(manifestMAT, familyTag, mirror, exteriorOptions...)
% manifestMAT : WP3_REFERENCE_MANIFEST.mat written by run_g2_wp3_mts_tests_batch (WP3.0 GO).
% mirror      : false = the preregistered -12.5957 deg kink; true = the geometry-only
%               mirrored +12.5957 deg control (never used for a SIF).
% Writes a NEW outputs/g2_wp3_kinked_mesh/run_* folder: console log, JSON summary,
% figures and (only on a join PASS) KINKED_GEOMETRY_ONLY_candidate.mat. The
% independent kink-aware audit runs afterwards in a separate MATLAB process.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
vendor=fullfile(here,'vendor_p010_a14d8872');addpath(vendor,'-begin');
assert(strcmpi(which('main_m1i_increment_ring_geometry_only'),fullfile(vendor,'main_m1i_increment_ring_geometry_only.m'))&& ...
       strcmpi(which('T3toT6_fast'),fullfile(vendor,'T3toT6_fast.m')),'G2KM:Vendor','Pinned vendor sources must resolve first.');
assert(~isempty(regexp(familyTag,'^[A-Za-z0-9_]+$','once')),'G2KM:Tag','Bad family tag.');
outRoot=fullfile(repo,'outputs','g2_wp3_kinked_mesh');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF'),'_',familyTag]);
assert(~exist(folder,'dir'),'G2KM:Collision','Refusing to overwrite %s',folder);mkdir(folder);
diary(fullfile(folder,'kinked_mesh_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_WP3_1_KINKED_PROTECTED_MESH\nDATE=%s\nMATLAB_RELEASE=%s\nOUTDIR=%s\nFAMILY=%s\nMIRROR=%d\n', ...
 datestr(now,31),version('-release'),folder,familyTag,mirror);
fprintf('NO_FEM=1; NO_SIF=1; NO_CRACK_GROWTH=1\n');
report=struct('pass',false,'stage','HOLD_NOT_RUN','familyTag',familyTag,'mirror',mirror,'manifestMAT',manifestMAT, ...
 'manifestSHA256','','exteriorOptions',{varargin},'gates',struct(),'failedGates',{{}},'summary',struct(),'exception','');
R=struct('pass',false);
try
 report.manifestSHA256=g2_sha256_file(manifestMAT);
 S=load(manifestMAT,'Mf');Mf=S.Mf;
 assert(strcmp(Mf.schema,'NewMetacomp.G2.WP3.FirstKink.ReferenceManifest.v1')&&strcmp(Mf.mts.status,'OK'),'G2KM:Manifest','Manifest is not a WP3.0 GO manifest.');
 th=Mf.mts.theta_rad;if mirror,th=-th;end
 t0=Mf.state0.t(:).';n0=Mf.state0.n(:).';tip0=Mf.state0.tip_mm(:).';da=Mf.trial.DeltaA_mm;
 t1=cos(th)*t0+sin(th)*n0;tip1=tip0+da*t1;
 if ~mirror,assert(norm(tip1-Mf.trial.tip_mm(:).')<1e-12,'G2KM:Tip','Trial tip disagrees with the manifest.');end
 P=[Mf.state0.crackPolyline_mm;tip1];
 fprintf('POLYLINE=%s\nTHETA_DEG=%.10f\nTANGENT=(%.12f, %.12f)\n',mat2str(P,15),th*180/pi,t1);
 jb=40000;kx=find(strcmpi(varargin(1:2:end),'MaxT3Elements'));if ~isempty(kx),jb=varargin{2*kx(end)};end
 R=g2_kinked_join(P,'ExteriorOptions',varargin,'MaxT3Elements',jb,'ExpectedTangent',t1);
 report.pass=R.pass;report.stage=R.stage;report.message=R.message;report.gates=R.gates;report.failedGates=R.failedGates;
 report.summary=R.summary;
 if isfield(R,'block'),report.blockStage=R.block.stage;report.blockGates=R.block.gates;end
 if isfield(R,'exterior'),report.exteriorStage=R.exterior.stage;report.exteriorMessage=R.exterior.message;end
 if isfield(R,'X3'),local_figures(R,folder);end
 if R.pass
  X3=R.X3;T3=R.T3;X6=R.X6;T6=R.T6;upperBankT6=R.upperBankT6;lowerBankT6=R.lowerBankT6; %#ok<NASGU>
  physicalTipNode=R.physicalTipNode;nodalQ=R.nodalQ;qActiveT6Rows=R.qActiveT6Rows;elementRows=R.elementRows; %#ok<NASGU>
  collarOuterIDs=R.collarOuterIDs;summary=R.summary;gates=R.gates; %#ok<NASGU>
  extraVertexXY=R.extraVertexXY;extraVertexNodes=R.extraVertexNodes;includeHoles=true;plateXRange=R.plateXRange; %#ok<NASGU>
  crackPolyline=P;tipTangent=t1;tipNormal=[-t1(2),t1(1)];kinkNodeIDs=R.kinkNodeIDs;kinkTheta_rad=th; %#ok<NASGU>
  manifest=Mf;manifestSHA256=report.manifestSHA256;mirrorControl=mirror; %#ok<NASGU>
  geometryOnly=true;approvedForLEFM=false; %#ok<NASGU>
  save(fullfile(folder,'KINKED_GEOMETRY_ONLY_candidate.mat'),'X3','T3','X6','T6','upperBankT6','lowerBankT6', ...
   'physicalTipNode','nodalQ','qActiveT6Rows','elementRows','collarOuterIDs','summary','gates','extraVertexXY', ...
   'extraVertexNodes','includeHoles','plateXRange','crackPolyline','tipTangent','tipNormal','kinkNodeIDs','kinkTheta_rad', ...
   'manifest','manifestSHA256','mirrorControl','familyTag','geometryOnly','approvedForLEFM','-v7.3');
  fprintf('G2_KINKED_MESH_MAT=%s\n',fullfile(folder,'KINKED_GEOMETRY_ONLY_candidate.mat'));
 end
catch ME
 report.stage='HOLD_KINKED_MESH_EXCEPTION';report.pass=false;report.exception=getReport(ME,'extended','hyperlinks','off');
 fprintf(2,'G2_KINKED_MESH_EXCEPTION=%s\n',report.exception);
end
f=fopen(fullfile(folder,'kinked_mesh_summary.json'),'w');fwrite(f,jsonencode(report,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_KINKED_MESH_STAGE=%s\nG2_KINKED_MESH_JOIN_PASS=%d\n',report.stage,report.pass);
if ~report.pass,error('G2KM:HOLD','Kinked protected mesh HOLD: %s',report.stage);end
fprintf('G2_KINKED_MESH_DONE=1; INDEPENDENT_AUDIT_PENDING=1; NO_LEFM=1\n');
end

function local_figures(R,folder)
X=R.X3;T=R.T3;P=R.crackPolyline;tip=P(end,:);t=R.tipTangent;n=R.tipNormal;rows=R.elementRows;
f=figure('Visible','off','Color','w','PaperPositionMode','manual','PaperUnits','centimeters','PaperPosition',[0 0 30 13]);
ax=axes(f,'Position',[.05 .1 .92 .82]);
triplot(T(rows.exterior,:),X(:,1),X(:,2),'Color',[.62 .74 .82],'Parent',ax);hold(ax,'on');
triplot(T([rows.core;rows.collar],:),X(:,1),X(:,2),'Color',[.85 .2 .1],'Parent',ax);
plot(ax,P(:,1),P(:,2),'k-','LineWidth',1.5);axis(ax,'equal');xlim(ax,R.plateXRange);ylim(ax,[0 203.2]);
xlabel(ax,'x (mm)');ylabel(ax,'y (mm)');
title(ax,sprintf('Cornell #1 kinked protected mesh: %d T3, turn %+.4f deg - %s',size(T,1),R.summary.turn_deg,R.stage),'Interpreter','none');
print(f,fullfile(folder,'kinked_full_mesh.png'),'-dpng','-r200');close(f);
% rotated kernel/collar in global coordinates around the new tip, and q support
f=figure('Visible','off','Color','w','PaperPositionMode','manual','PaperUnits','centimeters','PaperPosition',[0 0 30 15]);
ax1=axes(f,'Position',[.05 .1 .42 .8]);ax2=axes(f,'Position',[.55 .1 .42 .8]);
th=linspace(0,2*pi,400);
for ax=[ax1 ax2],triplot(T,X(:,1)-tip(1),X(:,2)-tip(2),'Color',[.6 .7 .78],'Parent',ax);hold(ax,'on');axis(ax,'equal');end
plot(ax1,3*cos(th),3*sin(th),'r-','LineWidth',1.2);plot(ax1,3.3*cos(th),3.3*sin(th),'g-','LineWidth',1.4);
plot(ax1,P(:,1)-tip(1),P(:,2)-tip(2),'k-','LineWidth',1.6);plot(ax1,P(2,1)-tip(1),P(2,2)-tip(2),'ko','MarkerFaceColor','y');
quiver(ax1,0,0,2*t(1),2*t(2),0,'b','LineWidth',1.2);quiver(ax1,0,0,2*n(1),2*n(2),0,'m','LineWidth',1.2);
xlim(ax1,[-6 6]);ylim(ax1,[-6 6]);xlabel(ax1,'x - x_{tip} (mm)');ylabel(ax1,'y - y_{tip} (mm)');
title(ax1,'rotated p010 seams: r = 3.0 (red), 3.3 mm (green); t (blue), n (magenta); kink (yellow)');
act=R.qActiveT6Rows;
patch(ax2,'Faces',T(act,:),'Vertices',X-tip,'FaceColor',[1 .85 .3],'EdgeColor',[.75 .55 .1],'FaceAlpha',.8);
plot(ax2,.4*cos(th),.4*sin(th),'b-');plot(ax2,2.6*cos(th),2.6*sin(th),'m-');plot(ax2,3*cos(th),3*sin(th),'r-');
plot(ax2,P(:,1)-tip(1),P(:,2)-tip(2),'k-','LineWidth',1.4);
xlim(ax2,[-4.2 4.2]);ylim(ax2,[-4.2 4.2]);xlabel(ax2,'x - x_{tip} (mm)');
title(ax2,sprintf('FE-nodal q about the new tip: %d active T6 parents (0.4-2.6 mm)',numel(act)));
print(f,fullfile(folder,'kinked_rotated_core_seams_q.png'),'-dpng','-r200');
print(f,fullfile(folder,'kinked_rotated_core_seams_q.pdf'),'-dpdf','-vector');close(f);
% kink vertex zoom
f=figure('Visible','off','Color','w','PaperPositionMode','manual','PaperUnits','centimeters','PaperPosition',[0 0 16 15]);
ax=axes(f);k=P(2,:);
triplot(T,X(:,1)-k(1),X(:,2)-k(2),'Color',[.45 .6 .72],'Parent',ax);hold(ax,'on');axis(ax,'equal');
plot(ax,P(:,1)-k(1),P(:,2)-k(2),'k-','LineWidth',1.6);plot(ax,3.3*cos(th)+tip(1)-k(1),3.3*sin(th)+tip(2)-k(2),'g-','LineWidth',1.2);
xlim(ax,[-1.6 1.6]);ylim(ax,[-1.6 1.6]);xlabel(ax,'x - x_{kink} (mm)');ylabel(ax,'y - y_{kink} (mm)');
title(ax,'kink vertex (101.6, 25.4): collapsed mitred channel and collar rim (green)');
print(f,fullfile(folder,'kinked_kink_vertex_zoom.png'),'-dpng','-r250');close(f);
end
