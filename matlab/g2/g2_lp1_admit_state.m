function g2_lp1_admit_state(sd,freeGiB,onAdmit)
%G2_LP1_ADMIT_STATE Admission of a NEW LP1 state folder (VG1, Issue #58; VG2, Issue #62).
% Order: (1) an existing folder without REVIEW is a preserved partial state and is
% never retried (HOLD_RECORD_INTEGRITY, unchanged); (2) the unchanged 5-GiB
% physical-memory guard (HOLD_MEMORY); (3) VG2: the optional campaign hook ONADMIT
% (closed-campaign refusal and immutable ADMIT ledger entry); (4) only then is the
% folder created. A failure in (1)-(3) leaves no state folder.
% The threshold equals policy v2 resources.freePhysicalRAM_GiB_min (5) and is
% not changed. A non-finite or non-numeric observation fails closed.
if nargin<3,onAdmit=[];end
assert(ischar(sd)&&~isempty(sd),'G2LP1:HOLD_INPUT','State folder path required.');
assert(~isfolder(sd),'G2LP1:HOLD_RECORD_INTEGRITY','Partial unreviewed state is preserved, never retried.');
assert(isnumeric(freeGiB)&&isscalar(freeGiB)&&isreal(freeGiB)&&isfinite(freeGiB)&&freeGiB>=5, ...
 'G2LP1:HOLD_MEMORY','Less than 5 GiB free physical RAM; no automatic retry.');
if ~isempty(onAdmit),onAdmit();end
mkdir(sd);
end
