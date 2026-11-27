function X=lp2b1eq_export(repo,sets,outDir)
%LP2B1EQ_EXPORT  Raw little-endian export of the nine canonical arrays of saved mesh MAT files (read-only inputs).
%  X = lp2b1eq_export(repo, sets, outDir)    sets: struct array with fields name, source (repo-relative MAT path),
%                                            expectedCanonicalSHA256. outDir must not exist.
% For each array a of X3,T3,X6,T6,upperBankT6,lowerBankT6,nodalQ,qActiveT6Rows,crackPolyline: file <name>_<array>.f64
% holds double(a(:)) (column-major float64, little endian); its size vector is recorded in EXPORT_INDEX.json. The
% independent Python hashcheck rebuilds the canonical digest from these bytes without MATLAB hashing code.
assert(~isfolder(outDir),'B1EQX:Exists','Export folder exists.');mkdir(outDir);
f={'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows','crackPolyline'};E=struct('name',{},'source',{},'sourceFileSHA256',{},'expectedCanonicalSHA256',{},'arrays',{});
for k=1:numel(sets)
 s=sets(k);p=fullfile(repo,strrep(s.source,'/',filesep));D=load(p);A=struct('name',{},'file',{},'size',{},'numel',{});
 for i=1:numel(f)
  a=double(D.(f{i}));fn=sprintf('%s_%s.f64',s.name,f{i});fid=fopen(fullfile(outDir,fn),'w','ieee-le');fwrite(fid,a(:),'double');fclose(fid);
  A(end+1)=struct('name',f{i},'file',fn,'size',size(a),'numel',numel(a)); %#ok<AGROW>
 end
 E(end+1)=struct('name',s.name,'source',s.source,'sourceFileSHA256',lower(g2_sha256_file(p)),'expectedCanonicalSHA256',s.expectedCanonicalSHA256,'arrays',A); %#ok<AGROW>
end
X=struct('schema','NewMetacomp.G2.LP2B1EQ.Export.v1','sets',E);
fid=fopen(fullfile(outDir,'EXPORT_INDEX.json'),'w');fwrite(fid,jsonencode(X,'PrettyPrint',true),'char');fclose(fid);
end
