function [L,ok,why,note]=lp2a2_eq_failed_list(x,allowed)
%LP2A2_EQ_FAILED_LIST  Strict normalization of ONE failed-criteria list (pure function, no I/O).
% Part of the LP2-A2 read-only verification closure (separate from the pinned historical sources;
% not in matlab/g2, not covered by any historical digest).
%
% Why: jsonencode writes an empty cell array as [] and jsondecode reads [] back as an empty DOUBLE
% (0x0). The historical replay compared the recomputed empty CELL with that empty DOUBLE by isequal
% (class-sensitive) and so reported VERIFY_HOLD although both lists were empty.
%
% Accepted (-> L, a 1xN cell row of unique, sorted, non-empty char rows):
%   * any empty cell array (1x0, 0x0, 0x1)                      -> L = cell(1,0)
%   * an empty DOUBLE array (what jsondecode returns for [])    -> L = cell(1,0)
%   * a cell array whose elements are all non-empty char rows   -> sorted list
% Rejected (ok=false, WHY says why): non-empty numeric/logical arrays, empty logical, a bare text value, structs
% (including the empty struct of '{}'), cells with a non-text element or a nested cell, char
% matrices, empty char, duplicate names, and (when ALLOWED is non-empty) names that are not
% criterion names. A rejected list is never converted into an empty list.
% The raw JSON text is validated separately (lp2a2_eq_failed_check), because null and [] both
% decode to the same empty double.
if nargin<2,allowed={};end
L=cell(1,0);ok=false;why='';note='';
if iscell(x)
 if isempty(x),ok=true;note='empty cell array';return,end
 v=x(:).';
elseif ischar(x)
 why='a text value is not a list (a list is an array of strings)';return
elseif isa(x,'double')&&isempty(x)&&ismatrix(x)
 ok=true;note='empty double array (jsondecode of an empty JSON array)';return
else
 why=sprintf('unsupported class %s, size %s',class(x),mat2str(size(x)));return
end
for k=1:numel(v)
 e=v{k};
 if ~(ischar(e)&&isrow(e)&&~isempty(e))
  why=sprintf('element %d is not a non-empty text row (class %s)',k,class(e));return
 end
end
if numel(unique(v))~=numel(v),why='duplicate criterion names';return,end
if ~isempty(allowed)&&~all(ismember(v,allowed)),why='name that is not a criterion';return,end
L=sort(v);ok=true;
end
