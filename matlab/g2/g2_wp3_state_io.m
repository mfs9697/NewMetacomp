function varargout = g2_wp3_state_io(action, varargin)
%G2_WP3_STATE_IO  Fail-closed save/verify of WP3 crack states (one MAT + recorded SHA-256 side file).
%  g2_wp3_state_io('save', dir, state)       -> writes dir/state.mat and dir/state.sha256 (dir must be new)
%  [state,h,ok,why] = g2_wp3_state_io('load', dir)  -> ok = false with why = 'HOLD_STATE_INTEGRITY' if
%     the file is missing, the recorded hash differs, or the schema is wrong. Never modifies dir.
switch action
 case 'save'
  d=varargin{1};state=varargin{2};
  assert(~exist(d,'dir'),'G2State:Exists','Refusing to overwrite existing state folder %s',d);
  mkdir(d);save(fullfile(d,'state.mat'),'state','-v7.3');
  h=g2_sha256_file(fullfile(d,'state.mat'));
  fid=fopen(fullfile(d,'state.sha256'),'w');fprintf(fid,'%s *state.mat\n',h);fclose(fid);
  varargout={h};
 case 'load'
  d=varargin{1};state=[];h='';ok=false;why='HOLD_STATE_INTEGRITY';
  f=fullfile(d,'state.mat');s=fullfile(d,'state.sha256');
  if isfile(f)&&isfile(s)
   rec=strtrim(fileread(s));rec=strtok(rec);h=g2_sha256_file(f);
   if strcmpi(rec,h)
    try
     S=load(f,'state');state=S.state;
     ok=isfield(state,'schema')&&strcmp(state.schema,'NewMetacomp.G2.WP3.CrackState.v1');
     if ok,why='OK';end
    catch
     ok=false;
    end
   end
  end
  varargout={state,h,ok,why};
 otherwise
  error('G2State:Action','Unknown action %s.',action);
end
end
