function T=check_g2_lp1_contract()
% Pure forecast/link controls + isolated immutable-record I/O. No mesh/FEM.
here=fileparts(mfilename('fullpath'));pol=jsondecode(fileread(fullfile(here,'G2_LP1_POLICY_v2.json')));
c=pol.cases(1);P=pol.startPolyline_mm;tn=[0 1];
K=struct('pass',true,'criteria',struct('test',true),'KI',1,'KII',.1,'EDI_all',[1 .1 0], ...
 'KI_MPa_sqrt_m_per_kN',sqrt(1000),'KII_MPa_sqrt_m_per_kN',.1*sqrt(1000));
R=struct('schema','NewMetacomp.G2.LP1.Test.v1','stateIndex',0,'caseId','H','mask',[0 0 0],'ratio',1, ...
 'policySHA256','policy','sourceSHA256','source','parentSHA256','parent','polyline_mm',P,'tangent',tn,'arc_mm',25.4, ...
 'KI',1,'KII',.1,'EDI_all',[1 .1 0],'meshSHA256','mesh','phaseSHA256','phase');
S=struct('K',K,'caseId','H','meshSHA256','mesh','phaseSHA256','phase','policySHA256','policy','sourceSHA256','source');
verify=@(r,s)g2_lp1_validate_links(r,s,c,0,P,tn,'policy','source','parent');
verify(R,S);rows=struct('name','positive_links','pass',true);
fields={'KI','KII','caseId','mask','ratio','stateIndex','policySHA256','sourceSHA256','parentSHA256','polyline_mm','meshSHA256','phaseSHA256'};
vals={2,-.1,'soft1',[1 0 0],.5,5,'bad','bad','bad',P+.1,'bad','bad'};
for k=1:numel(fields),r=R;r.(fields{k})=vals{k};reject(['mutate_',fields{k}],@()verify(r,S));end
s=S;s.K.KI_MPa_sqrt_m_per_kN=1;reject('wrong_units',@()verify(R,s));
s=S;s.K.criteria.test=false;reject('forged_pass_flag',@()verify(R,s));
parent=R;f=g2_lp1_forecast(parent,pol);assert(f.stateIndex==1&&abs(f.arc_mm-29.4)<1e-12);add('own_signed_MTS',true);
parent.KII=-parent.KII;f2=g2_lp1_forecast(parent,pol);add('signed_KII_changes_path',f2.polyline_mm(end,1)~=f.polyline_mm(end,1));
parent.stateIndex=4;reject('S5_forecast',@()g2_lp1_forecast(parent,pol));
reject('S5_controller',@()g2_lp1_run('MaxStateIndex',5));
parent=R;parent.KI=-1;reject('compressive_parent',@()g2_lp1_forecast(parent,pol));
parent=R;parent.KII=NaN;reject('nonfinite_parent',@()g2_lp1_forecast(parent,pol));
% Records live in a unique test directory, not an accepted run directory.
folder=fullfile(fileparts(fileparts(here)),'outputs',['g2_lp1_contract_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);mkdir(folder);
file=fullfile(folder,'REVIEW.mat');h=g2_trajectory_record('write',file,R);
[back,h2,ok]=g2_trajectory_record('read',file);add('record_roundtrip',ok&&isequal(R,back)&&strcmp(h,h2));
reject('overwrite_refused',@()g2_trajectory_record('write',file,R));
fid=fopen(file,'a');fwrite(fid,uint8(1));fclose(fid);[~,~,ok]=g2_trajectory_record('read',file);add('byte_tamper',~ok);
T=struct('pass',all([rows.pass]),'tests',rows,'passed',nnz([rows.pass]),'total',numel(rows),'physicalSolves',0,'meshBuilds',0);
fprintf('G2_LP1_CONTRACT_TESTS=%d/%d\n',T.passed,T.total);assert(T.pass,'G2LP1:ContractTests','A contract test failed.');
 function reject(name,fn)
  caught=false;try,fn();catch,caught=true;end;add(name,caught);
 end
 function add(name,pass),rows(end+1)=struct('name',name,'pass',pass);fprintf('%s %d\n',name,pass);end
end
