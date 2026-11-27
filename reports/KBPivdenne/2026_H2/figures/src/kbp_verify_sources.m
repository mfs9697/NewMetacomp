function R = kbp_verify_sources(repo,execRepo,outFile)
%KBP_VERIFY_SOURCES  Read-only cross-check of the plotted numbers against the original state records.
% Zero solves; nothing is written except OUTFILE.
%  repo      clone holding the committed LP2A_ANALYSIS.json (the figures' only data source)
%  execRepo  execution clone holding the git-ignored accepted state records:
%            outputs/g2_lp1_matrix_paths_v1/run_a0_lp1_repro_v1/<case>/S0..S4   (A0 reproduction of LP1)
%            outputs/g2_lp2a_paths_v1/run_lp2a_s5_s8_v1/<case>/S5..S8           (LP2-A1)
% Checks per case and state: record SHA-256 equals its manifest; SOLUTION K = STATE K;
% G = (K_I^2 + K_II^2)/E_matrix (plane stress, P = 1 N) equals STATE.G and the analysis record;
% tip and arc length equal the analysis record; S8 polyline = mouth + the nine plotted tips;
% F_G recomputed from the records equals the analysis record and the quoted rounded S8 values;
% S8 STATE/SOLUTION SHA-256 equal the archived-S8 pins of the LP2-A2 equivalence policy;
% lateral offset d recomputed as (tip_X - tip_H).n_H; G increases monotonically along each path.
ids = {'H','stiff13','soft2','soft1'};
af = fullfile(repo,'docs','research','G2_LP2_evidence','campaign_20261125','LP2A_ANALYSIS.json');
A = jsondecode(fileread(af,'Encoding','UTF-8'));
mp = jsondecode(fileread(fullfile(execRepo,'matlab','g2','G2_MATERIAL_POLICY_v1.json')));
E = mp.materials.E_matrix_MPa;
pin = jsondecode(fileread(fullfile(execRepo,'matlab','g2','lp2a2','G2_LP2A2_EQ_POLICY_v1.json'))); pin = pin.pins.archivedS8;
R = struct('schema','NewMetacomp.KBPivdenne.2026H2.FigureNumbersCheck.v1','E_matrix_MPa',E, ...
    'analysisRecord','docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json','analysisSHA256',lower(sha(af)), ...
    'execAnalysisSHA256',lower(sha(fullfile(execRepo,'docs','research','G2_LP2_evidence','campaign_20261125','LP2A_ANALYSIS.json'))), ...
    'physicalSolves',0,'cases',struct());
G = zeros(4,9); T = zeros(9,2,4); TN = zeros(9,2);
for i=1:4
    c = ids{i}; e = struct('manifestOK',true,'KconsistentWithState',true,'maxRelG_vsState',0,'maxRelG_vsAnalysis',0, ...
        'maxTipDiff_mm',0,'maxArcDiff_mm',0,'S8polylineMaxDiff_mm',NaN,'S8pinsOK',false,'Gmonotonic',false,'records',{{}});
    for n=0:8
        if n<=4, d = fullfile(execRepo,'outputs','g2_lp1_matrix_paths_v1','run_a0_lp1_repro_v1',c,sprintf('S%d',n));
        else,    d = fullfile(execRepo,'outputs','g2_lp2a_paths_v1','run_lp2a_s5_s8_v1',c,sprintf('S%d',n)); end
        for fn = {'STATE','SOLUTION'}
            m = jsondecode(fileread(fullfile(d,[fn{1} '.mat.manifest.json'])));
            e.manifestOK = e.manifestOK && strcmpi(m.SHA256,sha(fullfile(d,[fn{1} '.mat'])));
        end
        St = load(fullfile(d,'STATE.mat')); St = St.record; So = load(fullfile(d,'SOLUTION.mat')); So = So.record;
        KI = So.K.KI; KII = So.K.KII;
        e.KconsistentWithState = e.KconsistentWithState && KI==St.KI && KII==St.KII;
        g = (KI^2+KII^2)/E; G(i,n+1) = g;
        e.maxRelG_vsState = max(e.maxRelG_vsState,abs(g/St.G-1));
        e.maxRelG_vsAnalysis = max(e.maxRelG_vsAnalysis,abs(g/A.states.(c).G(n+1)-1));
        tip = St.polyline_mm(end,:); T(n+1,:,i) = tip;
        e.maxTipDiff_mm = max(e.maxTipDiff_mm,norm(tip-A.states.(c).tip(n+1,:)));
        e.maxArcDiff_mm = max(e.maxArcDiff_mm,abs(St.arc_mm-A.states.(c).s(n+1)));
        if i==1, tt = St.tangent(:).'; TN(n+1,:) = [-tt(2) tt(1)]/norm(tt); end
        e.records{end+1} = strrep(strrep(d,[execRepo filesep],''),filesep,'/');
        if n==8
            e.S8polylineMaxDiff_mm = max(max(abs(St.polyline_mm-[101.6 0;A.states.(c).tip])));
            e.S8pinsOK = strcmpi(sha(fullfile(d,'STATE.mat')),pin.(c).STATE) && strcmpi(sha(fullfile(d,'SOLUTION.mat')),pin.(c).SOLUTION);
        end
    end
    e.Gmonotonic = all(diff(G(i,:))>0);
    e.G_S4_to_S8_percent = 100*(G(i,9)/G(i,5)-1);
    R.cases.(c) = e;
end
quoted = struct('stiff13',-10.95,'soft2',-1.49,'soft1',10.73);
for i=2:4
    c = ids{i}; F = G(i,:)./G(1,:)-1; dd = zeros(1,9);
    for n=1:9, dd(n) = (T(n,:,i)-T(n,:,1))*TN(n,:).'; end
    R.cases.(c).F_G_percent_fromRecords = 100*F;
    R.cases.(c).maxAbsDiff_F_G_vsAnalysis = max(abs(F(:)-A.(c).F_G(:)));
    R.cases.(c).F_G_S8_percent = 100*F(9);
    R.cases.(c).F_G_S8_quoted = quoted.(c);
    R.cases.(c).F_G_S8_roundsToQuoted = round(100*F(9)*100)/100==quoted.(c);
    R.cases.(c).d_fromRecords_mm = dd;
    R.cases.(c).maxAbsDiff_d_vsAnalysis_mm = max(abs(dd(:)-A.(c).d_mm(:)));
end
ok = true;
for i=1:4
    e = R.cases.(ids{i});
    ok = ok && e.manifestOK && e.KconsistentWithState && e.maxRelG_vsState<1e-12 && e.maxRelG_vsAnalysis<1e-12 && ...
        e.maxTipDiff_mm<1e-9 && e.maxArcDiff_mm<1e-9 && e.S8polylineMaxDiff_mm<1e-9 && e.S8pinsOK && e.Gmonotonic;
    if i>1, ok = ok && e.maxAbsDiff_F_G_vsAnalysis<1e-12 && e.F_G_S8_roundsToQuoted && e.maxAbsDiff_d_vsAnalysis_mm<1e-9; end
end
R.allPass = ok;
fid = fopen(outFile,'w'); fwrite(fid,jsonencode(R,'PrettyPrint',true),'char'); fclose(fid);
fprintf('KBP_VERIFY allPass=%d  F_G(S8): stiff13 %.4f soft2 %.4f soft1 %.4f\n',ok,R.cases.stiff13.F_G_S8_percent,R.cases.soft2.F_G_S8_percent,R.cases.soft1.F_G_S8_percent);
end

function h = sha(f)
fid = fopen(f,'r'); b = fread(fid,inf,'*uint8'); fclose(fid);
md = java.security.MessageDigest.getInstance('SHA-256'); md.update(b);
h = lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
