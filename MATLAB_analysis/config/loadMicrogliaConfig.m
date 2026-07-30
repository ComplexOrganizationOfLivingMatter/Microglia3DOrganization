function config = loadMicrogliaConfig(configFile)
%LOADMICROGLIACONFIG Load MAT or JSON configuration.
    if nargin < 1 || strlength(string(configFile)) == 0
        [fileName,pathName] = uigetfile({'*.json;*.mat','Configuration files (*.json, *.mat)'}, ...
            'Select microglia analysis configuration');
        if isequal(fileName,0), error('Configuration selection was cancelled.'); end
        configFile = fullfile(pathName,fileName);
    end
    configFile = char(configFile);
    [basePath,~,ext] = fileparts(configFile);
    switch lower(ext)
        case '.mat'
            S = load(configFile,'config');
            config = S.config;
        case '.json'
            config = jsondecode(fileread(configFile));
        otherwise
            error('Unsupported configuration format: %s', ext);
    end
    config = resolveRelativeConfigPaths(config, basePath);
end

function config = resolveRelativeConfigPaths(config, basePath)
%RESOLVERELATIVECONFIGPATHS Resolve relative input paths against the configuration-file folder.
    fields = {'masks','microglia','plaques','voronoiCentroids','voronoiResults','output','dilatedPlaques'};
    if isfield(config, 'paths')
    for i = 1:numel(fields)
        f = fields{i};
        if isfield(config.paths,f) && strlength(string(config.paths.(f))) > 0
            p = char(config.paths.(f));
            if ~isAbsolutePath(p), config.paths.(f) = string(fullfile(basePath,p)); end
        end
    end
    end
    if isfield(config,'metadata') && strlength(string(config.metadata.file)) > 0
        p = char(config.metadata.file);
        if ~isAbsolutePath(p), config.metadata.file = string(fullfile(basePath,p)); end
    end
end

function tf = isAbsolutePath(p)
%ISABSOLUTEPATH Return true when a path is absolute on the current operating system.
    if ispc
        tf = ~isempty(regexp(p,'^[A-Za-z]:[\\/]|^\\\\','once'));
    else
        tf = startsWith(p,'/');
    end
end
