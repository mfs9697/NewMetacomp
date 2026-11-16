function D = g2_pde_toolbox_preflight()
%G2_PDE_TOOLBOX_PREFLIGHT  Diagnoses availability of PDE Toolbox in MATLAB.
% No CAD, no mesh and no physical computation. MATLAB R2023a compatible.
% 'generateMesh' is a method of the PDE model; exist(...,'file') may be 0.
names={'createpde','decsg','generateMesh','geometryFromEdges', ...
    'nearestEdge','findNodes'};
D=struct('pass',false,'MATLABRelease',version('-release'), ...
    'functions',struct(),'failedChecks',{{}}, ...
    'PDEToolboxVersion','','modelClass','');
for k=1:numel(names)
    n=names{k};
    key=matlab.lang.makeValidName(n);
    D.functions.(key)=struct('which',which(n), ...
        'fileExistCode',exist(n,'file'));
end
try
    v=ver('pde');
    if ~isempty(v)
        D.PDEToolboxVersion=v(1).Version;
    end
catch
    D.PDEToolboxVersion='not determined';
end
if exist('createpde','file')==0
    D.failedChecks{end+1}='createpde not on MATLAB path';
end
if exist('decsg','file')==0
    D.failedChecks{end+1}='decsg not on MATLAB path';
end
if ~isempty(D.failedChecks),return,end
try
    m=createpde(1);
    D.modelClass=class(m);
    if ~ismethod(m,'geometryFromEdges')
        D.failedChecks{end+1}='geometryFromEdges model method unavailable';
    end
    if ~ismethod(m,'generateMesh')
        D.failedChecks{end+1}='generateMesh model method unavailable';
    end
catch ME
    D.failedChecks{end+1}=sprintf( ...
      'createpde(1) failed [%s]: %s',ME.identifier,ME.message);
end
D.pass=isempty(D.failedChecks);
end
