function Q=lp2a2_eq_compare_records(rawText,Cm,Rc,mtol)
%LP2A2_EQ_COMPARE_RECORDS  Stored COMPARISON.json vs the recomputed comparison (pure function).
%  RAWTEXT  text of COMPARISON.json      CM  its jsondecode      RC  result of g2_lp2a2_eq_compare
%  MTOL     representation tolerance for finite metrics, mixed absolute/relative:
%           |stored - recomputed| <= MTOL*max(1,|recomputed|)   (default 1e-12; a text round-trip
%           tolerance, NOT a scientific tolerance; the observed difference is reported as well)
% Every criterion (set and values), every metric (set, finiteness, values), the pass flag and the
% internal consistency (failed list = false criteria, pass = all criteria) are checked.
if nargin<4,mtol=1e-12;end
Q=struct('ok',false,'problems',{{}},'failed',[],'criteriaTotal',0,'criteriaIdentical',0,'criteriaSetEqual',false, ...
 'internallyConsistent',false,'passEqual',false,'metricsTotal',0,'metricsWithinTol',0,'metricsBitwiseIdentical',0, ...
 'metricsMaxAbsDiff',NaN,'metricsMaxRelDiff',NaN,'metricsAllFinite',false,'metricSetEqual',false);
P={};
cn=fieldnames(Rc.criteria);Q.criteriaTotal=numel(cn);
Q.failed=lp2a2_eq_failed_check(rawText,Cm,Rc.failed,cn);
if ~Q.failed.rawOK||~Q.failed.storedOK||~Q.failed.recomputedOK||~Q.failed.equal
 P{end+1}=['FAILED_LIST: ' Q.failed.why]; %#ok<AGROW>
end
% ---- criteria
if isfield(Cm,'criteria')&&isstruct(Cm.criteria)
 sn=fieldnames(Cm.criteria);Q.criteriaSetEqual=isequal(sort(sn),sort(cn));
 if ~Q.criteriaSetEqual,P{end+1}='CRITERIA_SET: stored criterion names differ from the recomputed ones';end %#ok<AGROW>
 sv=false(numel(cn),1);okType=true;
 for k=1:numel(cn)
  if isfield(Cm.criteria,cn{k})
   e=Cm.criteria.(cn{k});
   if islogical(e)&&isscalar(e)
    sv(k)=e;Q.criteriaIdentical=Q.criteriaIdentical+(e==logical(Rc.criteria.(cn{k})));
    if e~=logical(Rc.criteria.(cn{k})),P{end+1}=['CRITERION: ' cn{k} ' differs from the recomputed value'];end %#ok<AGROW>
   else
    okType=false;P{end+1}=['CRITERION: ' cn{k} ' is not a logical scalar'];end %#ok<AGROW>
  else
   okType=false;P{end+1}=['CRITERION: ' cn{k} ' missing'];end %#ok<AGROW>
 end
 % internal consistency: failed list = names of false stored criteria; pass = all(stored criteria)
 if okType&&Q.failed.storedOK
  Q.internallyConsistent=isequal(sort(cn(~sv)).',Q.failed.stored)||(isempty(cn(~sv))&&isempty(Q.failed.stored));
  if ~Q.internallyConsistent,P{end+1}='CONSISTENCY: stored failed list is not the set of false stored criteria';end %#ok<AGROW>
 end
 if isfield(Cm,'pass')&&islogical(Cm.pass)&&isscalar(Cm.pass)
  Q.passEqual=(Cm.pass==logical(Rc.pass))&&okType&&(Cm.pass==all(sv));
 end
 if ~Q.passEqual,P{end+1}='PASS: stored pass differs from the recomputed pass or from all(stored criteria)';end %#ok<AGROW>
else
 P{end+1}='CRITERIA: stored criteria missing or not a struct';
end
% ---- metrics
mn=fieldnames(Rc.metrics);Q.metricsTotal=numel(mn);mad=0;mrd=0;allFin=true;
if isfield(Cm,'metrics')&&isstruct(Cm.metrics)
 Q.metricSetEqual=isequal(sort(fieldnames(Cm.metrics)),sort(mn));
 if ~Q.metricSetEqual,P{end+1}='METRIC_SET: stored metric names differ from the recomputed ones';end %#ok<AGROW>
 for k=1:numel(mn)
  if ~isfield(Cm.metrics,mn{k}),P{end+1}=['METRIC: ' mn{k} ' missing'];continue,end %#ok<AGROW>
  sv=Cm.metrics.(mn{k});rv=Rc.metrics.(mn{k});
  if islogical(rv)||(islogical(sv)&&isscalar(sv))
   if islogical(sv)&&islogical(rv)&&isscalar(sv)&&isscalar(rv)&&sv==rv
    Q.metricsWithinTol=Q.metricsWithinTol+1;Q.metricsBitwiseIdentical=Q.metricsBitwiseIdentical+1;
   else,P{end+1}=['METRIC: ' mn{k} ' differs (logical)'];end %#ok<AGROW>
   continue
  end
  if ~(isnumeric(sv)&&isscalar(sv)&&isnumeric(rv)&&isscalar(rv)&&isfinite(sv)&&isfinite(rv))
   allFin=false;P{end+1}=['METRIC: ' mn{k} ' is not a finite numeric scalar'];continue %#ok<AGROW>
  end
  d=abs(double(sv)-double(rv));mad=max(mad,d);mrd=max(mrd,d/max(abs(double(rv)),realmin));
  if d<=mtol*max(1,abs(double(rv))),Q.metricsWithinTol=Q.metricsWithinTol+1;else,P{end+1}=['METRIC: ' mn{k} ' differs from the recomputed value'];end %#ok<AGROW>
  if d==0,Q.metricsBitwiseIdentical=Q.metricsBitwiseIdentical+1;end
 end
else
 P{end+1}='METRICS: stored metrics missing or not a struct';allFin=false;
end
Q.metricsAllFinite=allFin;Q.metricsMaxAbsDiff=mad;Q.metricsMaxRelDiff=mrd;Q.problems=P;Q.ok=isempty(P);
end
