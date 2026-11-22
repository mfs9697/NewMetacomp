% Scratch comparison: apply the VG1 sabotage set to the ORIGINAL PR #55 suite at 70bf6f4.
% Original suite passes/fails as a whole (it asserts); a sabotage is DETECTED only if the
% original suite fails. Sources in the clean clone are never modified (copies in tempdir).
here='<repo>\matlab\g2';
addpath(here,'-begin');
cases={ ...
 'token_binding_removed','g2_lp1_scientific_gate.m','&& ...\n strcmp(G.approvedToken,C.token), ...',', ...'; ...
 'binding_identifier_wrong','g2_lp1_scientific_gate.m','''G2LP1:HOLD_SOURCE'',''Scientific GO does not bind','''G2LP1:HOLD_UNAUTHORIZED_STATE'',''Scientific GO does not bind'; ...
 'unrelated_same_identifier','g2_lp1_scientific_gate.m','fields={','error(''G2LP1:HOLD_SOURCE'',''unrelated failure'');fields={'; ...
 'links_identifier_collapsed','g2_lp1_validate_links.m','''G2LP1:HOLD_SOURCE'',''Parent/source/policy link differs.''','''G2LP1:HOLD_RECORD_INTEGRITY'',''Parent/source/policy link differs.'''; ...
 'S5_cap_removed','g2_lp1_forecast.m','assert(k>=1&&k<=4&&k<=pol.caps.maxStateIndex,','assert(k>=1,'; ...
 'overwrite_allowed','g2_trajectory_record.m','assert(~isfile(file)&&~isfile(manifest),','assert(true,'; ...
 'absent_go_not_checked','g2_lp1_scientific_gate.m','assert(isfile(p),','assert(true,'};
for k=1:size(cases,1)
 [name,file,from,to]=cases{k,:};from=sprintf(from);to=sprintf(to);
 src=strrep(fileread(fullfile(here,file)),sprintf('\r\n'),sprintf('\n'));
 applied=numel(strfind(src,from))==1;detected=false;
 if applied
  tmp=tempname;mkdir(tmp);fid=fopen(fullfile(tmp,file),'w');fwrite(fid,strrep(src,from,to),'char');fclose(fid);
  addpath(tmp,'-begin');clear(file(1:end-2));rehash;
  try,evalc('check_g2_lp1_contract();');detected=false;catch,detected=true;end
  rmpath(tmp);clear(file(1:end-2));rehash;rmdir(tmp,'s');
 end
 fprintf('ORIGINAL_SUITE_MUTATION %s applied=%d detected=%d\n',name,applied,detected);
end
fprintf('ORIGINAL_SUITE_MUTATION folder_before_memory_guard applied=0 detected=0 (no admission function or test exists at 70bf6f4)\n');
