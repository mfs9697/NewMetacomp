function W=run_g2_wp34_state2_report_batch(chainDir)
%RUN_G2_WP34_STATE2_REPORT_BATCH  WP3.4 State 2 tables and figures from the SAVED chain (read only).
%  W = run_g2_wp34_state2_report_batch(chainDir)
% Reads ROOT, STEP_002/REVIEW.mat, the State 2 and its mesh after verifying their
% manifests/hashes; no mesher, no solve. Writes a NEW outputs/g2_wp34_state2/run_<time>/
% with state2_summary.json and figures (full mesh, two-kink local zoom with seams and
% q support, trajectory, K versus q annulus). Idealized numerical state only.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
chainDir=char(chainDir);
outRoot=fullfile(repo,'outputs','g2_wp34_state2');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'state2_report_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
before=hash_tree(chainDir);
[Root,rootRecHash,ok1]=g2_trajectory_record('read',fullfile(chainDir,'ROOT.mat'));
[Rev,revHash,ok2]=g2_trajectory_record('read',fullfile(chainDir,'STEP_002','REVIEW.mat'));
[S2,s2Hash,ok3]=g2_wp3_state_io('load',fullfile(chainDir,'STEP_002','state'));
mf=fullfile(chainDir,'STEP_002',Rev.meshFile);
assert(ok1&&ok2&&ok3&&strcmpi(g2_sha256_file(mf),Rev.meshSHA256)&&strcmpi(S2.reviewSHA256,revHash),'G2WP34:Report','Chain integrity.');
D=load(mf);K=Rev.sif;P=Rev.polyline_mm;tip=P(end,:);t=Rev.tangent(:).';n=[-t(2),t(1)];
J=jsondecode(fileread(fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json')));G=J.nominal_geometry_mm;
an=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];s=sqrt(1000);Kr=hypot(K.KI,K.KII);
ann=table(an(:,1),an(:,2),K.EDI_all(:,1)*s,K.EDI_all(:,2)*s,K.EDI_all(:,3), ...
 'VariableNames',{'rIn_mm','rOut_mm','KI_MPa_sqrt_m_per_kN','KII_MPa_sqrt_m_per_kN','J_N_per_mm_per_N'});
disp(ann);
[~,Ep]=g2_plane_D(struct('E',S2.bvp.E_MPa,'nu',S2.bvp.nu,'plane',S2.bvp.plane));
crit=K.criteria;
vals=struct('relativeResidual',K.relativeResidual,'staticsMax',K.staticsMax, ...
 'CODvsEDI_fractionOfK',max(abs([K.KI-K.KI_COD,K.KII-K.KII_COD]))/Kr, ...
 'pathSpread_fractionOfK',max(max(K.EDI_all(:,1:2))-min(K.EDI_all(:,1:2)))/Kr, ...
 'JenergyIdentity',abs(K.EDI_all(1,3)/((K.KI^2+K.KII^2)/Ep)-1), ...
 'qSupportMaxRadius_mm',K.qSupportMaxRadius_mm,'wholeCrackOpeningMin_mm',K.fullPolyOpeningMin_mm, ...
 'KIIoverKI',K.KII/K.KI,'KII_sign_edi_vs_cod_match',K.KII_sign_edi_vs_cod_match,'codFitPairs',K.codFitPairs);
if isfield(K,'EDI4x4'),vals.quadratureDrift_fractionOfK=max(abs(K.EDI4x4-K.EDI_all(1,1:2)))/Kr;end
if isfield(K,'statics'),vals.statics=K.statics;end
Fp=g2_polyline_frame(P);
W=struct('chain','<repo>/outputs/g2_trajectory_chain_v1','rootRecordSHA256',rootRecHash,'reviewSHA256',revHash, ...
 'state2SHA256',s2Hash,'meshSHA256',Rev.meshSHA256,'parentStateSHA256',S2.parentStateSHA256,'policySHA256',S2.policySHA256, ...
 'gitHead',field_or(Rev,'gitHead',''),'polyline_mm',P,'tip2_mm',tip,'tangent2',t,'localTurn2_deg',Rev.localTurn_deg, ...
 'turns_deg',Fp.turns_deg(:).','arcLength_mm',sum(vecnorm(diff(P),2,2)), ...
 'mesh',Rev.meshSummary,'audit',struct('gates',sprintf('%d/%d',Rev.geometryGatesPassed,Rev.geometryGateCount),'summary',Rev.geometrySummary), ...
 'KI_EDI',K.KI_MPa_sqrt_m_per_kN,'KII_EDI',K.KII_MPa_sqrt_m_per_kN,'KI_COD',K.KI_COD*s,'KII_COD',K.KII_COD*s, ...
 'criteria',crit,'criterionValues',vals,'annuli',table2struct(ann), ...
 'nextForecast_NOT_EXECUTED',g2_mts_direction(K.KI_MPa_sqrt_m_per_kN,K.KII_MPa_sqrt_m_per_kN).theta_deg, ...
 'physicalFractureGrowthProven',S2.physicalFractureGrowthProven,'tipAccepted',S2.tipAccepted,'physical_onset',S2.physical_onset, ...
 'stateFields',{fieldnames(S2)},'Ksource',S2.Ksource);
fprintf('TIP2=(%.10f, %.10f) mm, turn %.10f deg, arc %.6f mm\n',tip,Rev.localTurn_deg,W.arcLength_mm);
fprintf('KI=%.6f KII=%+.6f (EDI) | KI=%.6f KII=%+.6f (COD) MPa sqrt(m)/kN\n',W.KI_EDI,W.KII_EDI,W.KI_COD,W.KII_COD);
% ---------------- figures
X3=D.X3;T3=D.T3;hx=arrayfun(@(h)h.center(1),G.holes);hy=arrayfun(@(h)h.center(2),G.holes);hr=arrayfun(@(h)h.radius,G.holes);
ph=linspace(0,2*pi,241);ink=[.15 .15 .15];crackC=[.80 .10 .10];
f1=figure('Visible','off','Position',[0 0 1400 640],'Color','w');
triplot(T3,X3(:,1),X3(:,2),'Color',[.55 .62 .75],'LineWidth',.2);hold on;axis equal tight;
plot(P(:,1),P(:,2),'-','Color',crackC,'LineWidth',1.6);
for k=1:3,plot(hx(k)+hr(k)*cos(ph),hy(k)+hr(k)*sin(ph),'Color',ink,'LineWidth',.8);end
title(sprintf('State 2 protected mesh: %d T3, min angle %.3f\\circ, max ratio %.3f (idealized, numerical)', ...
 Rev.meshSummary.T3elements,Rev.meshSummary.minAngle_deg,Rev.meshSummary.maxNeighborRatio));xlabel('x (mm)');ylabel('y (mm)');
exportgraphics(f1,fullfile(folder,'state2_full_mesh.png'),'Resolution',200);close(f1);
% two-kink local zoom
f2=figure('Visible','off','Position',[0 0 1100 1000],'Color','w');
c0=mean(P(2:end,:),1);hw=6.2;
in=all(X3(T3(:,1),:)>c0-hw-1&X3(T3(:,1),:)<c0+hw+1,2);
qa=D.qActiveT6Rows(:);
patch('Faces',T3(qa,:),'Vertices',X3,'FaceColor',[.98 .86 .55],'EdgeColor','none');hold on;
triplot(T3(in,:),X3(:,1),X3(:,2),'Color',[.45 .52 .66],'LineWidth',.25);
for R0=[3 3.3],plot(tip(1)+R0*cos(ph),tip(2)+R0*sin(ph),'Color',[.10 .35 .75],'LineWidth',1.1);end
plot(tip(1)+2.6*cos(ph),tip(2)+2.6*sin(ph),'--','Color',[.65 .45 .05],'LineWidth',.9);
plot(P(:,1),P(:,2),'-','Color',crackC,'LineWidth',2);plot(P(2:end-1,1),P(2:end-1,2),'o','Color',crackC,'MarkerSize',8,'LineWidth',1.4);
plot(tip(1),tip(2),'kp','MarkerSize',12,'MarkerFaceColor','k');
axis equal;xlim(c0(1)+[-hw hw]);ylim(c0(2)+[-hw hw]);xlabel('x (mm)');ylabel('y (mm)');
legend({'q-active T6 parents (2,443)','mesh','seams r = 3, 3.3 mm','','q outer r = 2.6 mm','crack polyline','kink vertices','tip 2'},'Location','southwest');
title(sprintf('Two-kink region: kinks %.4f\\circ and %.4f\\circ; tip 2 (%.5f, %.5f) mm',W.turns_deg(1),W.turns_deg(2),tip));
exportgraphics(f2,fullfile(folder,'state2_two_kink_zoom.png'),'Resolution',220);exportgraphics(f2,fullfile(folder,'state2_two_kink_zoom.pdf'),'ContentType','vector');close(f2);
% trajectory
f3=figure('Visible','off','Position',[0 0 900 900],'Color','w');
plot(P(:,1),P(:,2),'-o','Color',crackC,'LineWidth',1.6,'MarkerSize',5,'MarkerFaceColor',crackC);hold on;
for k=1:3,plot(hx(k)+hr(k)*cos(ph),hy(k)+hr(k)*sin(ph),'Color',ink,'LineWidth',1);end
plot([40 220],[0 0],'Color',ink);axis equal;xlim([40 220]);ylim([-5 130]);grid on;xlabel('x (mm)');ylabel('y (mm)');
text(P(2,1)+1,P(2,2),'tip 0','FontSize',9);text(P(3,1)+1,P(3,2),'State 1','FontSize',9);text(P(4,1)+1,P(4,2),'State 2','FontSize',9);
title('Idealized numerical crack path, States 0-2 (not an experimental path)');
exportgraphics(f3,fullfile(folder,'state2_trajectory.png'),'Resolution',200);close(f3);
% K versus annulus: two panels (no dual axis)
f4=figure('Visible','off','Position',[0 0 1100 460],'Color','w');
lab=arrayfun(@(i)sprintf('%.1f-%.1f',an(i,1),an(i,2)),1:5,'UniformOutput',false);
subplot(1,2,1);plot(1:5,ann.KI_MPa_sqrt_m_per_kN,'o-','Color',[.10 .35 .75],'LineWidth',2,'MarkerSize',8);hold on;
yline(W.KI_COD,'--','Color',[.80 .45 .05],'LineWidth',1.5);set(gca,'XTick',1:5,'XTickLabel',lab);grid on;
xlabel('q annulus (mm)');ylabel('K_I (MPa m^{1/2} per kN)');legend({'EDI 6\times6','blind bank COD'},'Location','best');title('K_I');
subplot(1,2,2);plot(1:5,ann.KII_MPa_sqrt_m_per_kN,'o-','Color',[.10 .35 .75],'LineWidth',2,'MarkerSize',8);hold on;
yline(W.KII_COD,'--','Color',[.80 .45 .05],'LineWidth',1.5);yline(0,'Color',[.6 .6 .6]);set(gca,'XTick',1:5,'XTickLabel',lab);grid on;
xlabel('q annulus (mm)');ylabel('K_{II} (MPa m^{1/2} per kN)');legend({'EDI 6\times6','blind bank COD'},'Location','best');title('K_{II} (signed)');
sgtitle('State 2 signed SIF versus contour, idealized 1 N pin/roller BVP');
exportgraphics(f4,fullfile(folder,'state2_K_vs_annulus.png'),'Resolution',200);close(f4);
after=hash_tree(chainDir);W.chainUnchangedByReport=isequal(before,after);
f=fopen(fullfile(folder,'state2_summary.json'),'w');fwrite(f,jsonencode(W,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_WP34_STATE2_REPORT_DONE=1 CHAIN_UNCHANGED=%d\nOUTDIR=%s\n',W.chainUnchangedByReport,folder);
end

function v=field_or(s,f,d)
if isfield(s,f),v=s.(f);else,v=d;end
end

function H=hash_tree(d)
f=dir(fullfile(d,'**','*'));f=f(~[f.isdir]);H=cell(numel(f),2);
for k=1:numel(f),p=fullfile(f(k).folder,f(k).name);H(k,:)={p,g2_sha256_file(p)};end
H=sortrows(H,1);
end
