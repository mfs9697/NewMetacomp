function T=check_g2_trajectory_controller()
%CHECK_G2_TRAJECTORY_CONTROLLER  Geometry/algebra and checkpoint negative tests.
% No PDE, no physical FEM, no author source files modified. MATLAB R2023a.
% These tests do not qualify the new second-step mesh or its signed SIF.
here=fileparts(mfilename('fullpath'));
repo=fileparts(fileparts(here));
j=jsondecode(fileread(fullfile(repo,'docs','research', ...
 'crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json')));
G=j.nominal_geometry_mm;
M0=g2_mts_direction(.166436,.018827);
assert(strcmp(M0.status,'OK'),'G2ChainTest:FirstMTS','WP2 source MTS not admissible.');
tip0=[101.6 25.4];t0=[0 1];n0=[-1 0];
t1=cos(M0.theta_rad)*t0+sin(M0.theta_rad)*n0;
P3=[101.6 0;tip0;tip0+4*t1];
M1=g2_mts_direction(.182585,.001514);
assert(strcmp(M1.status,'OK'),'G2ChainTest:SecondMTS','WP3 source MTS not admissible.');
t2=cos(M1.theta_rad)*t1+sin(M1.theta_rad)*[-t1(2),t1(1)];
P4=[P3;P3(end,:)+4*t2];
A3=g2_kink_admissibility(P3,G,'ExpectedVertices',3, ...
 'ExpectedTangent',t1);
A4=g2_kink_admissibility(P4,G,'ExpectedVertices',4, ...
 'ExpectedTangent',t2);
assert(A3.pass&&A4.pass,'G2ChainTest:AnalyticalKinks', ...
 'The pure-geometric second-step preflight has a HOLD (inspect gates).');
wrongCount=g2_kink_admissibility(P3,G,'ExpectedVertices',4);
badLength=P4;badLength(end,1)=badLength(end,1)+.04;
wrongLength=g2_kink_admissibility(badLength,G,'ExpectedVertices',4);
intoHole=P4;intoHole(end,:)=G.holes(1).center(:).';
wrongHole=g2_kink_admissibility(intoHole,G,'ExpectedVertices',4);
assert(~wrongCount.pass&&~wrongCount.gates.K1_polylineIdentity&& ...
 ~wrongLength.pass&&~wrongLength.gates.K1_polylineIdentity&& ...
 ~wrongHole.pass,'G2ChainTest:CorruptPolyline', ...
 'Wrong count/length/hole must be rejected.');
assert(~strcmp(M1.status,'DOCUMENTED_PURE_MODE_II'), ...
 'G2ChainTest:Tensile','Wrong MTS regime.');
temp=fullfile(tempdir,['g2_trajectory_contract_',char(java.util.UUID.randomUUID)]);
mkdir(temp);
c=onCleanup(@()cleanup(temp)); %#ok<NASGU>
file=fullfile(temp,'REVIEW.mat');
source=struct('schema','NewMetacomp.G2.TrajectoryTestRecord.v1', ...
 'stateIndex',2,'value',P4,'physicalFractureGrowthProven',false);
h=g2_trajectory_record('write',file,source);
[r,hash,ok,why]=g2_trajectory_record('read',file);
assert(ok&&strcmpi(h,hash)&&isequal(r,source)&&strcmp(why,'OK'), ...
 'G2ChainTest:RecordRoundTrip','Atomic record round trip failed.');
noOverwrite=false;
try
 g2_trajectory_record('write',file,source);
catch ME
 noOverwrite=strcmp(ME.identifier,'G2Chain:RecordExists');
end
assert(noOverwrite,'G2ChainTest:Overwrite','Overwrite was incorrectly allowed.');
mf=[file,'.manifest.json'];
m=jsondecode(fileread(mf));
m.SHA256=repmat('0',1,64);
fid=fopen(mf,'w');assert(fid>=0);
fwrite(fid,jsonencode(m),'char');fclose(fid);
[~,~,valid]=g2_trajectory_record('read',file);
assert(~valid,'G2ChainTest:CorruptManifest','Corrupted review manifest was trusted.');
T=struct('pass',true,'algebraFirst_deg',M0.theta_deg, ...
 'algebraSecond_deg',M1.theta_deg,'analyticalSecondTip_mm',P4(end,:), ...
 'P3K1toK10',A3.gates,'P4K1toK10',A4.gates, ...
 'negativeControls',4,'immutableRecordPass',true, ...
 'physicalSolverExecuted',false,'tip2MeshQualified',false);
fprintf('G2_TRAJECTORY_SYNTHETIC_CONTROLLER_PASS=1\n');
fprintf('G2_TRAJECTORY_ANALYTIC_TIP2_MM=(%.12f,%.12f)\n',P4(end,1),P4(end,2));
fprintf('G2_TRAJECTORY_NO_NEW_MESH_NO_SIF=1\n');
end

function cleanup(folder)
if isfolder(folder),rmdir(folder,'s');end
end
