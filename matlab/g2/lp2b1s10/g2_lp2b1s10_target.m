function Tq=g2_lp2b1s10_target(C)
%G2_LP2B1S10_TARGET  Read-only qualification of the sole authoritative parent and the fixed soft1 S10 target geometry
% (zero FEM, no mesh, no write). Every check is named in Tq.checks; Tq.pass = all.
%  Tq = g2_lp2b1s10_target(C)          C = g2_lp2b1s10_context (or a test copy with altered pins)
%  parentRecords   ORIGINAL LP2-A3 soft1 S9 STATE/PHASE/SOLUTION/ADMIT/RECEIPT read through their manifests, file SHA-256
%                  = pins, MESH = pin
%  parentIdentity  S9, soft1, mask 100, ratio 0.5, ACCEPTED, 0.45 mm rung 1, LP2-A3 token, parent = pinned S8 STATE
%  parentLinks     STATE -> MESH/PHASE/SOLUTION, PHASE/SOLUTION -> MESH; signed KI, KII, J, compliance of STATE == SOLUTION
%                  bitwise; all 16 gates of the S9 solution; ADMIT key soft1_S9 under the LP2-A3 receipt
%  mtsIndependent  signed MTS root of the parent recomputed independently (rationalized closed form) equals
%                  g2_mts_direction (<= 4 eps rad) and the parent root is admissible (status OK, stationarity <= 1e-12)
%  forecast        g2_lp2_forecast(S9, LP2-A3 policy): S10, s = 65.4 mm, tip == pinned (114.29544883822506,
%                  63.18559491151613) bitwise; independent 4-mm recurrence tip within 1e-12 mm
%  failedMesh      stored FAILED_MESH pin; its crack polyline == forecast polyline bitwise; saved summary T3 30387,
%                  12/13 join gates, failed gate globalNeighborRatioAtMost1p8 (preserved evidence, not modified)
%  terminal        LP2-A3 soft1 TERMINAL pin: NUMERICAL_HOLD, last accepted S9, parent = S9 STATE, candidate polyline ==
%                  forecast bitwise, failure G2LP2A3:HOLD_MESH_QUALITY; HOLD.mat LOCAL S10 with the same identifier;
%                  ADMIT_soft1_S10 present in the closed LP2-A3 ledger (never altered)
%  nominalClearance g2_lp0_clearance on the S9 clearance geometry + g2_lp2a3_classify (1 mm guide-to-every-ring guard):
%                  MATRIX_ADVANCE; ring-1 guide gap == 4.6329563816383335 mm bitwise and within 1e-12 mm of the issue
%                  value 4.632956381638341 mm
%  notShiftedEq    the LP2-B1-EQ shifted S10 predictor (from the re-solved K) is NOT used: forecast tip differs from it
INT='G2LP2B1S10:HOLD_TARGET';repo=C.repo;fp=@(p)fullfile(repo,strrep(p,'/',filesep));pol=C.policy;a3=C.a3.policy;p=pol.parent;fa=pol.failedA3S10;tg=pol.target;
c=struct();info=struct();
pinOK=@(x)isfile(fp(x.path))&&strcmpi(g2_sha256_file(fp(x.path)),x.sha256);
recOK=@(r)pinOK(r.record)&&pinOK(r.manifest);
% ---------------------------------------------------------------- parent
c.parentRecords=recOK(p.STATE)&&recOK(p.PHASE)&&recOK(p.SOLUTION)&&recOK(p.ADMIT)&&recOK(p.RECEIPT)&&pinOK(p.MESH);
St=[];So=[];Ph=[];sth='';
if c.parentRecords
 [St,sth,o1]=g2_trajectory_record('read',fp(p.STATE.record.path));[So,sos,o2]=g2_trajectory_record('read',fp(p.SOLUTION.record.path));
 [Ph,phs,o3]=g2_trajectory_record('read',fp(p.PHASE.record.path));[Ad,~,o4]=g2_trajectory_record('read',fp(p.ADMIT.record.path));
 [Rc,~,o5]=g2_trajectory_record('read',fp(p.RECEIPT.record.path));mh=lower(g2_sha256_file(fp(p.MESH.path)));
 c.parentRecords=o1&&o2&&o3&&o4&&o5&&strcmpi(sth,p.STATE.record.sha256);
 c.parentIdentity=St.stateIndex==9&&strcmp(St.caseId,'soft1')&&isequal(reshape(St.mask,1,3),[1 0 0])&&St.ratio==0.5&&strcmp(St.numericalStatus,'ACCEPTED')&& ...
  St.seedSpacing_mm==0.45&&St.seedRung==1&&strcmp(St.token,C.a3.token)&&strcmpi(St.parentSHA256,p.grandparentS8.sha256)&&strcmp(St.schema,'NewMetacomp.G2.LP2A3.State.v1');
 K=So.K;g=struct2cell(K.criteria);
 c.parentLinks=strcmpi(St.meshSHA256,mh)&&strcmpi(St.phaseSHA256,phs)&&strcmpi(St.solutionSHA256,sos)&&strcmpi(Ph.meshSHA256,mh)&&strcmpi(So.meshSHA256,mh)&& ...
  strcmpi(So.phaseSHA256,phs)&&isequal(St.KI,K.KI)&&isequal(St.KII,K.KII)&&isequal(St.J,K.J)&&isequal(St.compliance_mm_per_N,K.compliance_mm_per_N)&& ...
  K.pass&&numel(g)==16&&all(cellfun(@(x)isequal(x,true),g))&&K.KI>0&&strcmp(Ad.stateKey,'soft1_S9')&&strcmp(Ad.campaignId,Rc.campaignId)&&strcmp(Rc.token,C.a3.token);
 % ---- independent signed MTS (rationalized closed form) and the inherited root
 M=g2_mts_direction(St.KI,St.KII);thI=2*atan(-2*St.KII/(St.KI+sqrt(St.KI^2+8*St.KII^2)));
 c.mtsIndependent=strcmp(M.status,'OK')&&M.admissibleForStep&&M.stationarityResidual_rel<=pol.tolerances.mtsStationarity_rel&&abs(thI-M.theta_rad)<=4*eps(abs(M.theta_rad));
 info.mts=struct('theta_deg',M.theta_deg,'thetaIndependent_deg',thI*180/pi,'diff_rad',thI-M.theta_rad,'stationarity',M.stationarityResidual_rel,'parentMTS_deg_state',St.MTS_deg);
 % ---- forecast (inherited recurrence) and independent recurrence
 F=g2_lp2_forecast(St,a3);P=F.polyline_mm;t=St.tangent;n=[-t(2),t(1)];tipI=St.tip_mm+4*(cos(thI)*t+sin(thI)*n);
 c.forecast=F.stateIndex==10&&abs(F.arc_mm-65.4)<=1e-9&&isequal(P(end,:),reshape(tg.expectedTip_mm,1,2))&&isequal(P(1:end-1,:),St.polyline_mm)&& ...
  norm(tipI-P(end,:))<=1e-12&&isequal(size(P),[12 2]);
 info.forecast=struct('tip_mm',P(end,:),'tangent',F.tangent,'heading_deg',F.heading_deg,'arc_mm',F.arc_mm,'parentMTS_deg',F.parentMTS_deg,'independentTipDiff_mm',norm(tipI-P(end,:)));
 % ---- preserved failed S10 records
 fmOK=pinOK(fa.FAILED_MESH);fm=[];
 if fmOK,Sf=load(fp(fa.FAILED_MESH.path));fm=Sf.failedMesh;end
 es=fa.expectedSavedSummary;
 c.failedMesh=fmOK&&isequal(fm.crackPolyline,P)&&size(fm.T3,1)==es.T3&&~fm.pass&&isequal(cellstr(fm.failedGates),{es.failedGate})&& ...
  abs(fm.summary.maxNeighborRatio-es.maxNeighborRatio)<=5e-7&&all(isfield(fm,{'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows'}));
 c.terminal=false;
 if recOK(fa.TERMINAL)&&recOK(fa.HOLD)&&recOK(fa.ADMIT)
  [Tm,~,ot]=g2_trajectory_record('read',fp(fa.TERMINAL.record.path));[Hd,~,oh]=g2_trajectory_record('read',fp(fa.HOLD.record.path));
  [A10,~,oa]=g2_trajectory_record('read',fp(fa.ADMIT.record.path));
  c.terminal=ot&&oh&&oa&&strcmp(Tm.caseId,'soft1')&&strcmp(Tm.classification,'NUMERICAL_HOLD')&&Tm.lastAcceptedState==9&&strcmpi(Tm.parentSHA256,sth)&& ...
   isequal(Tm.candidate.polyline_mm,P)&&strcmp(Tm.failure.identifier,'G2LP2A3:HOLD_MESH_QUALITY')&&strcmp(Hd.scope,'LOCAL')&&Hd.stateIndex==10&& ...
   strcmp(Hd.identifier,'G2LP2A3:HOLD_MESH_QUALITY')&&strcmpi(Hd.parentSHA256,sth)&&strcmp(A10.stateKey,'soft1_S10')&&strcmp(A10.campaignId,Rc.campaignId);
 end
 % ---- nominal clearance and guard on the S9 clearance geometry
 Rn=g2_lp0_clearance(P(1:end-1,:),P(end,:),St.clearanceGeometry,a3);Tn=g2_lp2a3_classify(Rn,[1 0 0],a3,P(end,:));gp=Tn.ringProximity.gap_mm;
 gg=tg.ring1GuideGap_mm;
 c.nominalClearance=Rn.pass&&strcmp(Tn.classification,'MATRIX_ADVANCE')&&Tn.ringProximity.pass&&min(gp)>=1&&isequal(gp(1),gg.matlabGuard)&& ...
  abs(gp(1)-gg.issueValue)<=pol.tolerances.ring1GuideGapIssueValue_mm;
 info.nominal=struct('classification',Tn.classification,'guideRingGap_mm',gp,'gapMinusIssueValue_mm',gp(1)-gg.issueValue,'clearance',Rn.metrics, ...
  'tipToRingCircle_mm',vecnorm(pol.geometry.centres_mm-P(end,:),2,2).'-pol.geometry.ringR_mm);
 eqShift=[114.2954484554881 63.1855950991163];   % LP2-B1-EQ forecast from the re-solved K (C10 diagnostic) - must NOT be the target
 c.notShiftedEq=~isequal(P(end,:),eqShift)&&norm(P(end,:)-eqShift)>1e-7;
else
 for f={'parentIdentity','parentLinks','mtsIndependent','forecast','failedMesh','terminal','nominalClearance','notShiftedEq'},c.(f{1})=false;end
 F=[];fm=[];P=[];
end
v=cellfun(@(x)isequal(x,true),struct2cell(c));f=fieldnames(c);
Tq=struct('pass',all(v),'checks',c,'failed',{f(~v).'},'info',info,'parent',St,'parentSHA256',lower(sth),'solution',So,'forecast',F,'failedMesh',fm, ...
 'nominalGeometry',[],'identifier',INT);
if ~isempty(St),Tq.nominalGeometry=St.clearanceGeometry;end
end
