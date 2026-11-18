function R=run_g2_protected_mesh_batch(familyTag,varargin)
%RUN_G2_PROTECTED_MESH_BATCH  WP1: build and save the full protected Cornell #1 mesh.
% Geometry only. Writes a NEW outputs/g2_protected_mesh/run_* folder with the
% console log, JSON summary, figures and (only on a join PASS) the saved arrays
% GEOMETRY_ONLY_candidate.mat in the format read by g2_independent_t6_checker.
% The independent audits run afterwards in a separate MATLAB process
% (run_g2_protected_audit_batch). No FEM, no SIF, no crack growth.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
vendor=fullfile(here,'vendor_p010_a14d8872');
addpath(vendor,'-begin');
assert(strcmpi(which('main_m1i_increment_ring_geometry_only'),fullfile(vendor,'main_m1i_increment_ring_geometry_only.m'))&& ...
       strcmpi(which('T3toT6_fast'),fullfile(vendor,'T3toT6_fast.m')),'G2Prot:VendorShadowed', ...
       'MATLAB must resolve the pinned vendor sources.');
if nargin<1||isempty(familyTag),familyTag='';end
assert(isempty(familyTag)||~isempty(regexp(familyTag,'^[A-Za-z0-9_]+$','once')),'G2Prot:Tag','Bad family tag.');
outRoot=fullfile(repo,'outputs','g2_protected_mesh');
if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF'),regexprep(['_',familyTag],'^_$','')]);
assert(~exist(folder,'dir'),'G2Prot:Collision','Refusing to overwrite %s',folder);
mkdir(folder);diary(fullfile(folder,'batch_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_WP1_FULL_PROTECTED_MESH\nDATE=%s\nMATLAB_RELEASE=%s\nOUTDIR=%s\n',datestr(now,31),version('-release'),folder);
fprintf('NO_FEM=1; NO_SIF=1; NO_CRACK_GROWTH=1\n');
report=struct('pass',false,'stage','HOLD_NOT_RUN','date',datestr(now,31),'outputDirectory',folder, ...
 'MATLABRelease',version('-release'),'approvedForLEFM',false,'gates',struct(),'failedGates',{{}}, ...
 'summary',struct(),'exception','');
R=struct('pass',false);
try
 fprintf('FAMILY=%s\n',familyTag);
 jb=40000;kx=find(strcmpi(varargin(1:2:end),'MaxT3Elements'));if ~isempty(kx),jb=varargin{2*kx(end)};end
 R=g2_join_protected_mesh('ExteriorOptions',varargin,'MaxT3Elements',jb);
 report.familyTag=familyTag;report.exteriorOptions=varargin;
 report.pass=R.pass;report.stage=R.stage;report.gates=R.gates;
 report.failedGates=R.failedGates;report.summary=R.summary;
 if isfield(R,'X3')
  local_figures(R,folder);
 end
 if R.pass
  X3=R.X3;T3=R.T3;X6=R.X6;T6=R.T6; %#ok<NASGU>
  upperBankT6=R.upperBankT6;lowerBankT6=R.lowerBankT6;physicalTipNode=R.physicalTipNode; %#ok<NASGU>
  nodalQ=R.nodalQ;qActiveT6Rows=R.qActiveT6Rows;elementRows=R.elementRows; %#ok<NASGU>
  collarOuterIDs=R.collarOuterIDs;summary=R.summary;gates=R.gates; %#ok<NASGU>
  extraVertexXY=R.extraVertexXY;extraVertexNodes=R.extraVertexNodes;includeHoles=R.includeHoles;plateXRange=R.plateXRange; %#ok<NASGU>
  geometryOnly=true;approvedForLEFM=false;p010GlobalProtectedMeshQualified=false; %#ok<NASGU>
  save(fullfile(folder,'GEOMETRY_ONLY_candidate.mat'),'X3','T3','X6','T6','upperBankT6','lowerBankT6', ...
   'physicalTipNode','nodalQ','qActiveT6Rows','elementRows','collarOuterIDs','summary','gates', ...
   'geometryOnly','approvedForLEFM','p010GlobalProtectedMeshQualified', ...
   'extraVertexXY','extraVertexNodes','includeHoles','plateXRange','familyTag','-v7.3');
  fprintf('G2_PROTECTED_MESH_MAT=%s\n',fullfile(folder,'GEOMETRY_ONLY_candidate.mat'));
 end
catch ME
 report.stage='HOLD_PROTECTED_MESH_EXCEPTION';report.pass=false;
 report.exception=getReport(ME,'extended','hyperlinks','off');
 fprintf(2,'G2_PROTECTED_MESH_EXCEPTION=%s\n',report.exception);
end
f=fopen(fullfile(folder,'protected_mesh_summary.json'),'w');
fwrite(f,jsonencode(report,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_PROTECTED_MESH_SUMMARY=%s\n',fullfile(folder,'protected_mesh_summary.json'));
fprintf('G2_PROTECTED_MESH_JOIN_PASS=%d\n',report.pass);
if ~report.pass
 error('G2Prot:JoinHOLD','Full protected mesh HOLD: %s',report.stage);
end
fprintf('G2_PROTECTED_MESH_DONE=1; INDEPENDENT_AUDIT_PENDING=1; NO_LEFM=1\n');
end

function local_figures(R,folder)
X=R.X3;T=R.T3;tip=R.summary.tip_mm;rows=R.elementRows;
% full mesh
f=figure('Visible','off','Color','w','Units','centimeters','Position',[1 1 30 13], ...
    'PaperPositionMode','manual','PaperUnits','centimeters','PaperPosition',[0 0 30 13]);
ax=axes(f,'Position',[.05 .1 .92 .82]);
triplot(T(rows.exterior,:),X(:,1),X(:,2),'Color',[.62 .74 .82],'Parent',ax);hold(ax,'on');
triplot(T([rows.core;rows.collar],:),X(:,1),X(:,2),'Color',[.85 .2 .1],'Parent',ax);
plot(ax,[tip(1) tip(1)],[0 tip(2)],'k-','LineWidth',1.5);
axis(ax,'equal');xlim(ax,R.plateXRange);ylim(ax,[0 203.2]);xlabel(ax,'x (mm)');ylabel(ax,'y (mm)');
title(ax,sprintf('Cornell #1 protected mesh: %d T3 (p010 kernel + collar in red) - %s',size(T,1),R.stage),'Interpreter','none');
print(f,fullfile(folder,'protected_full_mesh.png'),'-dpng','-r200');close(f);
% tip region with seams and q support
f=figure('Visible','off','Color','w','Units','centimeters','Position',[1 1 30 15], ...
    'PaperPositionMode','manual','PaperUnits','centimeters','PaperPosition',[0 0 30 15]);
ax1=axes(f,'Position',[.05 .1 .42 .8]);ax2=axes(f,'Position',[.55 .1 .42 .8]);
for ax=[ax1 ax2]
 triplot(T,X(:,1)-tip(1),X(:,2)-tip(2),'Color',[.6 .7 .78],'Parent',ax);hold(ax,'on');axis(ax,'equal');
end
th=linspace(0,2*pi,400);
plot(ax1,3*cos(th),3*sin(th),'r-','LineWidth',1.2);plot(ax1,3.3*cos(th),3.3*sin(th),'g-','LineWidth',1.4);
plot(ax1,[0 0],[-8 0],'k-','LineWidth',1.6);xlim(ax1,[-8 8]);ylim(ax1,[-8 8]);
title(ax1,'64-chord seams: r = 3.0 mm (red), r = 3.3 mm (green)');xlabel(ax1,'x - x_{tip} (mm)');ylabel(ax1,'y - y_{tip} (mm)');
act=R.qActiveT6Rows;
patch(ax2,'Faces',T(act,:),'Vertices',X-tip,'FaceColor',[1 .85 .3],'EdgeColor',[.75 .55 .1],'FaceAlpha',.8);
plot(ax2,.4*cos(th),.4*sin(th),'b-');plot(ax2,2.6*cos(th),2.6*sin(th),'m-');plot(ax2,3*cos(th),3*sin(th),'r-');
xlim(ax2,[-3.6 3.6]);ylim(ax2,[-3.6 3.6]);
title(ax2,sprintf('FE-nodal q: %d active T6 parents (0.4-2.6 mm)',numel(act)));xlabel(ax2,'x - x_{tip} (mm)');
print(f,fullfile(folder,'protected_tip_seams_q.png'),'-dpng','-r200');close(f);
end
