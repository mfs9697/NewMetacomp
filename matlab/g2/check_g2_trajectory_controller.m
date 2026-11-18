function T=check_g2_trajectory_controller(seedStepDir)
%CHECK_G2_TRAJECTORY_CONTROLLER  Geometry/algebra and record negative tests (WP3.4 B1-B6).
% No PDE, no physical FEM, no author source files modified. MATLAB R2023a.
% These tests do not qualify the new second-step mesh or its signed SIF.
%  T = check_g2_trajectory_controller()             % uses the original WP3 step1_a
%  T = check_g2_trajectory_controller(seedStepDir)  % explicit State 1 folder (read only)
% Plan: WP34_QUALIFICATION_PLAN.md section 2. The 6-digit WP3 K test of PR #29 is kept
% (B2a); B2 recomputes the second turn from the FULL-precision accepted State 1 and
% compares g2_mts_direction with an independent bracketed root of the MTS equation.
here=fileparts(mfilename('fullpath'));
repo=fileparts(fileparts(here));
if nargin<1||isempty(seedStepDir)
 seedStepDir=fullfile(repo,'outputs','g2_wp3_state','run_20261118_185808_963','step1_a');
end
j=jsondecode(fileread(fullfile(repo,'docs','research', ...
 'crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json')));
G=j.nominal_geometry_mm;
policy=jsondecode(fileread(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')));
% ---- B1 first MTS turn from the preregistered WP2 K
M0=g2_mts_direction(.166436,.018827);
assert(strcmp(M0.status,'OK'),'G2ChainTest:FirstMTS','WP2 source MTS not admissible.');
assert(abs(M0.theta_deg-(-12.5956937016))<=1e-9,'G2ChainTest:FirstMTSValue', ...
 'First MTS turn %.12f deg differs from the WP3.0 value.',M0.theta_deg);
tip0=[101.6 25.4];t0=[0 1];n0=[-1 0];
t1=cos(M0.theta_rad)*t0+sin(M0.theta_rad)*n0;
P3=[101.6 0;tip0;tip0+4*t1];
% ---- B2a (PR #29 original) second turn from the six-digit WP3 K
M1=g2_mts_direction(.182585,.001514);
assert(strcmp(M1.status,'OK'),'G2ChainTest:SecondMTS','WP3 source MTS not admissible.');
% ---- B2 second turn from the full-precision accepted State 1 (hash-checked reader)
[S1,h1,ok,why]=g2_wp3_state_io('load',fullfile(seedStepDir,'state'));
assert(ok,'G2ChainTest:State1','State 1 integrity: %s',why);
inList=any(arrayfun(@(r)strcmpi(r.stateSHA256,h1)&&strcmpi(r.meshSHA256,S1.meshSHA256),policy.base.allowedWP3State1));
assert(inList,'G2ChainTest:State1Pinned','State 1 is not one of the policy-pinned pairs.');
KI=S1.KI_MPa_sqrt_m_per_kN;KII=S1.KII_MPa_sqrt_m_per_kN;
M2=g2_mts_direction(KI,KII);
assert(strcmp(M2.status,'OK'),'G2ChainTest:SecondMTSFull','Full-precision State 1 MTS not admissible.');
% independent: root of KI sin(th) + KII (3 cos(th) - 1) = 0 on (-pi/2, pi/2), then hoop maximum
f=@(th)KI*sin(th)+KII*(3*cos(th)-1);
if KII>0,br=[-pi/2+1e-12,0];else,br=[0,pi/2-1e-12];end
thInd=fzero(f,br,optimset('TolX',1e-18));
hoop=@(th)cos(th/2).*(KI*cos(th/2).^2-1.5*KII*sin(th));
hstep=1e-4;isMax=hoop(thInd)>hoop(thInd-hstep)&&hoop(thInd)>hoop(thInd+hstep);
dTheta=abs(rad2deg(thInd)-M2.theta_deg);
assert(dTheta<=1e-10&&isMax&&M2.theta_deg<0,'G2ChainTest:SecondMTSIndependent', ...
 'Independent second MTS root %.15f vs %.15f deg (max %d).',rad2deg(thInd),M2.theta_deg,isMax);
% ---- B3 analytic tip 2 in the State 1 last-segment frame (t1, n1 = R(+90) t1)
tS=S1.t(:).';nS=[-tS(2),tS(1)];
tLast=(S1.crackPolyline_mm(end,:)-S1.crackPolyline_mm(end-1,:))/norm(S1.crackPolyline_mm(end,:)-S1.crackPolyline_mm(end-1,:));
assert(norm(tLast-tS)<=1e-12,'G2ChainTest:State1Frame','Stored tangent is not the last-segment direction.');
t2=cos(M2.theta_rad)*tS+sin(M2.theta_rad)*nS;
tip2=S1.tip_mm(:).'+S1.DeltaA_mm*t2;
t2ind=cos(thInd)*tS+sin(thInd)*nS;tip2ind=S1.tip_mm(:).'+4*t2ind;
assert(norm(tip2-tip2ind)<=1e-12,'G2ChainTest:Tip2','Analytic tip 2 differs between MTS routes.');
P4=[S1.crackPolyline_mm;tip2];
% ---- B4 four-vertex K1-K10
A3=g2_kink_admissibility(P3,G,'ExpectedVertices',3,'ExpectedTangent',t1);
A4=g2_kink_admissibility(P4,G,'ExpectedVertices',4,'ExpectedTangent',t2);
assert(A3.pass&&A4.pass,'G2ChainTest:AnalyticalKinks', ...
 'The pure-geometric second-step preflight has a HOLD (inspect gates).');
% ---- B5 negative polylines
wrongCount=g2_kink_admissibility(P3,G,'ExpectedVertices',4);
badLength=P4;badLength(end,1)=badLength(end,1)+.04;
wrongLength=g2_kink_admissibility(badLength,G,'ExpectedVertices',4);
intoHole=P4;intoHole(end,:)=G.holes(1).center(:).';
wrongHole=g2_kink_admissibility(intoHole,G,'ExpectedVertices',4);
rotT=[cosd(1e-4) -sind(1e-4);sind(1e-4) cosd(1e-4)]*t2(:);
wrongTangent=g2_kink_admissibility(P4,G,'ExpectedVertices',4,'ExpectedTangent',rotT);
fold=[P4;P4(end,:)+4*[-t2(2),t2(1)];P4(end,:)+4*[-t2(2),t2(1)]-4*t2];
selfCross=g2_kink_admissibility(fold,G,'ExpectedVertices',6);
assert(~wrongCount.pass&&~wrongCount.gates.K1_polylineIdentity&& ...
 ~wrongLength.pass&&~wrongLength.gates.K1_polylineIdentity&& ...
 ~wrongHole.pass&&~wrongTangent.pass&&~wrongTangent.gates.K1_polylineIdentity&& ...
 ~selfCross.pass,'G2ChainTest:CorruptPolyline', ...
 'Wrong count/length/hole/tangent/fold must be rejected.');
assert(~strcmp(M1.status,'DOCUMENTED_PURE_MODE_II'), ...
 'G2ChainTest:Tensile','Wrong MTS regime.');
% ---- B6 immutable record I/O
temp=tempname;
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
% byte flip in the MAT (copy), manifest untouched
f2=fullfile(temp,'FLIP.mat');copyfile(file,f2);copyfile([file,'.manifest.json'],[f2,'.manifest.json']);
m2=jsondecode(fileread([f2,'.manifest.json']));m2.file='FLIP.mat';
fid=fopen([f2,'.manifest.json'],'w');fwrite(fid,jsonencode(m2),'char');fclose(fid);
fid=fopen(f2,'r+');fseek(fid,-100,'eof');b=fread(fid,1,'*uint8');fseek(fid,-100,'eof');fwrite(fid,bitxor(b,uint8(1)));fclose(fid);
[~,~,validFlip]=g2_trajectory_record('read',f2);
% MAT without manifest
f3=fullfile(temp,'NOMAN.mat');copyfile(file,f3);
[~,~,validNoMan]=g2_trajectory_record('read',f3);
% manifest SHA tamper
mf=[file,'.manifest.json'];
m=jsondecode(fileread(mf));
m.SHA256=repmat('0',1,64);
fid=fopen(mf,'w');assert(fid>=0);
fwrite(fid,jsonencode(m),'char');fclose(fid);
[~,~,valid]=g2_trajectory_record('read',file);
assert(~valid&&~validFlip&&~validNoMan,'G2ChainTest:CorruptManifest', ...
 'Corrupted record trusted (manifest %d, byte flip %d, no manifest %d).',valid,validFlip,validNoMan);
T=struct('pass',true,'algebraFirst_deg',M0.theta_deg, ...
 'algebraSecond6digit_deg',M1.theta_deg,'algebraSecondFull_deg',M2.theta_deg, ...
 'independentSecond_deg',rad2deg(thInd),'secondTurnRouteDifference_deg',dTheta, ...
 'state1SHA256',h1,'state1KI',KI,'state1KII',KII, ...
 'analyticalSecondTip_mm',tip2,'analyticalSecondTangent',t2, ...
 'P3K1toK10',A3.gates,'P4K1toK10',A4.gates,'P4inheritedGuardWouldReject',A4.summary.inheritedGuardWouldReject, ...
 'negativeControls',struct('wrongCount',{wrongCount.failedGates},'wrongLength',{wrongLength.failedGates}, ...
   'tipInHole',{wrongHole.failedGates},'wrongTangent',{wrongTangent.failedGates},'fold',{selfCross.failedGates}), ...
 'immutableRecordPass',true,'physicalSolverExecuted',false,'tip2MeshQualified',false);
fprintf('B1 first turn %.12f deg\n',M0.theta_deg);
fprintf('B2 second turn full precision %.12f deg; independent root %.12f deg; |diff| %.3e deg\n',M2.theta_deg,rad2deg(thInd),dTheta);
fprintf('B3 analytic tip 2 (%.12f, %.12f) mm\n',tip2);
fprintf('B4 P4 K1-K10 %d/10; inherited 0.98 guard would reject: %d\n',nnz(cell2mat(struct2cell(A4.gates))),A4.summary.inheritedGuardWouldReject);
fprintf('B5 negatives rejected: count, length, hole, tangent, fold\nB6 record round trip, no overwrite, 3 tamper modes rejected\n');
fprintf('G2_TRAJECTORY_SYNTHETIC_CONTROLLER_PASS=1\n');
fprintf('G2_TRAJECTORY_ANALYTIC_TIP2_MM=(%.12f,%.12f)\n',tip2(1),tip2(2));
fprintf('G2_TRAJECTORY_NO_NEW_MESH_NO_SIF=1\n');
end

function cleanup(folder)
if isfolder(folder),rmdir(folder,'s');end
end
