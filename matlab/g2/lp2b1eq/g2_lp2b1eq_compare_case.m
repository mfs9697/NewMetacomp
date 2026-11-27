function R=g2_lp2b1eq_compare_case(C,s,Ref,K,D,chords)
%G2_LP2B1EQ_COMPARE_CASE  Assemble the inputs of g2_lp2b1eq_compare for one solve and compare (pure apart from
% reading nothing; used identically by the driver and by the read-only verifier).
%  R = g2_lp2b1eq_compare_case(C, s, Ref, K, D, chords)
% New next tip: the inherited recurrence g2_lp2_forecast of the ARCHIVED STATE with K_I, K_II replaced by the new
% values, under the LP2-A3 policy (same caps and increment as the archived next state). If the recurrence refuses
% (non-admissible new MTS root), the next tip is NaN and the comparison is INPUT_INVALID (HOLD, no equivalence).
% The new next state label is derived from the forecast state index, never copied from the policy.
Sn=Ref.state;Sn.KI=K.KI;Sn.KII=K.KII;tip=[NaN NaN];ns='';
try
 F=g2_lp2_forecast(Sn,C.a3.policy);tip=F.polyline_mm(end,:);ns=sprintf('S%d',F.stateIndex);
catch
end
N=struct('K',K,'D',D,'activeArea_mm2',fieldOr(K,'activeArea_mm2'),'chordsPerCircle',chords,'nextTip_mm',tip,'nextState',ns, ...
 'id',struct('solveId',s.id,'caseId',s.caseId,'stateIndex',s.stateIndex,'mask',reshape(s.mask,1,3),'canonicalSHA256',g2_lp2b1eq_canon(D)));
A=struct('state',Ref.state,'K',Ref.solution.K,'D',Ref.mesh,'nextTip_mm',Ref.nextTip_mm,'nextState',Ref.nextState,'chordsPerCircle',Ref.chordsPerCircle, ...
 'id',struct('solutionSHA256',Ref.solutionSHA256));
R=g2_lp2b1eq_compare(N,A,C.policy.tolerances,s);
end
function v=fieldOr(s,f),if isstruct(s)&&isfield(s,f),v=s.(f);else,v=NaN;end,end
