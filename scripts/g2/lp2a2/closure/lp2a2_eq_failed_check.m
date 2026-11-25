function Q=lp2a2_eq_failed_check(rawText,Cm,recomputedFailed,allowed)
%LP2A2_EQ_FAILED_CHECK  Compare the stored failed-criteria list of a COMPARISON.json with the
% recomputed one (pure function). RAWTEXT is the file text, CM its jsondecode, RECOMPUTEDFAILED the
% 'failed' output of g2_lp2a2_eq_compare, ALLOWED the criterion names.
% Three layers, all must hold:
%   1. raw JSON: exactly one "failed" member whose value is a flat array that is either empty or a
%      list of double-quoted strings (so null, nested arrays, numbers, objects are rejected even
%      though null and [] both decode to the same empty double);
%   2. decoded value: lp2a2_eq_failed_list (strict, class-aware normalization);
%   3. equality of the two normalized sorted lists.
Q=struct('rawOK',false,'storedOK',false,'recomputedOK',false,'equal',false,'why','','note','', ...
 'stored',{cell(1,0)},'recomputed',{cell(1,0)});
nm=regexp(rawText,'"failed"\s*:','match');
tk=regexp(rawText,'"failed"\s*:\s*(\[[^\[\]]*\])','tokens');
if numel(nm)~=1||numel(tk)~=1
 Q.why=sprintf('raw text: %d "failed" member(s), %d flat array value(s)',numel(nm),numel(tk));return
end
g=tk{1}{1};
if isempty(regexp(g,'^\[\s*\]$','once'))&&isempty(regexp(g,'^\[\s*"[^"\\]+"(\s*,\s*"[^"\\]+")*\s*\]$','once'))
 Q.why='raw text: failed is not an empty array or a list of strings';return
end
Q.rawOK=true;
if ~isstruct(Cm)||~isfield(Cm,'failed'),Q.why='decoded record has no failed field';return,end
[Q.stored,Q.storedOK,w1,Q.note]=lp2a2_eq_failed_list(Cm.failed,allowed);
if ~Q.storedOK,Q.why=['stored list: ' w1];return,end
[Q.recomputed,Q.recomputedOK,w2]=lp2a2_eq_failed_list(recomputedFailed,allowed);
if ~Q.recomputedOK,Q.why=['recomputed list: ' w2];return,end
Q.equal=isequal(Q.stored,Q.recomputed);
if ~Q.equal,Q.why='stored and recomputed failed lists differ';end
end
