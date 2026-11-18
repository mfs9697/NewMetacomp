function varargout=g2_trajectory_record(action,file,record)
%G2_TRAJECTORY_RECORD Atomic immutable SHA-256 JSON-manifested MATLAB record.
% 'write': write RECORD to a NEW MAT file and a neighboring .manifest.json.
% 'read':  verify original file bytes/manifest and return RECORD, SHA256.
% A MAT without a manifest is a HOLD, never accepted as an existing review.
% No overwrite, no implicit repair, no physical fracture acceptance.
if nargin<3,record=[];end
file=char(file);manifest=[file,'.manifest.json'];
switch lower(action)
 case 'write'
  assert(isstruct(record)&&isscalar(record)&&isfield(record,'schema'), ...
   'G2Chain:RecordSchema','Expected a scalar schema-tagged record.');
  assert(~isfile(file)&&~isfile(manifest),'G2Chain:RecordExists', ...
   'Refusing to overwrite an existing numerical record.');
  folder=fileparts(file);
  assert(isfolder(folder),'G2Chain:RecordFolder','Parent record folder must exist.');
  tmp=[tempname(folder),'.mat'];
  tmpJSON=[tempname(folder),'.json'];
  cleaner=onCleanup(@()cleanup(tmp,tmpJSON)); %#ok<NASGU>
  save(tmp,'record','-v7.3');
  h=g2_sha256_file(tmp);
  [ok,msg]=movefile(tmp,file);
  assert(ok,'G2Chain:RecordMove','%s',msg);
  info=dir(file);
  M=struct('schema','NewMetacomp.G2.TrajectoryRecordManifest.v1', ...
   'file',info.name,'SHA256',h,'bytes',info.bytes, ...
   'recordSchema',record.schema, ...
   'stateIndex',getindex(record),'physicalFractureGrowthProven',false);
  fid=fopen(tmpJSON,'w');
  assert(fid>=0,'G2Chain:RecordManifestWrite','Could not create temporary manifest.');
  fwrite(fid,jsonencode(M,'PrettyPrint',true),'char');fclose(fid);
  assert(~isfile(manifest),'G2Chain:ManifestExists','Manifest exists unexpectedly.');
  [ok,msg]=movefile(tmpJSON,manifest);
  assert(ok,'G2Chain:ManifestMove','%s',msg);
  varargout={h};
 case 'read'
  record=[];h='';pass=false;why='HOLD_RECORD_INTEGRITY';
  if isfile(file)&&isfile(manifest)
   try
    M=jsondecode(fileread(manifest));
    h=g2_sha256_file(file);
    if strcmp(M.schema,'NewMetacomp.G2.TrajectoryRecordManifest.v1')&& ...
       strcmpi(M.SHA256,h)&&dir(file).bytes==M.bytes
     D=load(file,'record');record=D.record;
     pass=isstruct(record)&&isscalar(record)&& ...
        strcmp(record.schema,M.recordSchema)&& ...
        isequal(getindex(record),M.stateIndex);
     if pass,why='OK';end
    end
   catch
    pass=false;
   end
  end
  varargout={record,h,pass,why};
 otherwise
  error('G2Chain:BadRecordAction','Unknown record action %s.',action);
end
end

function idx=getindex(r)
idx=-1;
if isfield(r,'stateIndex'),idx=r.stateIndex;end
end

function cleanup(a,b)
if isfile(a),delete(a);end
if isfile(b),delete(b);end
end
