function config = validateMicrogliaConfig(config)
%VALIDATEMICROGLIACONFIG Validate paths, metadata, numerical parameters, and dependencies.

    defaults = createMicrogliaConfig();
    config = mergeStructs(defaults, config);

    requiredFolders = ["masks", "microglia", "output"];
    if config.models.ad
        requiredFolders(end+1) = "plaques";
    end
    for name = requiredFolders
        value = string(config.paths.(name));
        if strlength(value) == 0 || ~isfolder(value)
            error('Required folder is missing or invalid: config.paths.%s', name);
        end
    end

    validateModelSubfolders(config);

    if strlength(string(config.metadata.file)) == 0 || ~isfile(config.metadata.file)
        error('The metadata Excel file does not exist.');
    end

    if config.voronoi.enabled
        if strlength(string(config.paths.voronoiCentroids)) == 0 || ~isfolder(config.paths.voronoiCentroids)
            error('Voronoi analysis requires a folder containing the centroid MAT files used to generate Voronoi data.');
        end
        if strlength(string(config.paths.voronoiResults)) == 0 || ~isfolder(config.paths.voronoiResults)
            error('Voronoi analysis requires a folder containing Voronoi MAT files.');
        end
    end

    if config.resolution.mode == "manual"
        validateattributes(config.resolution.xy_um_per_px, {'numeric'}, {'scalar','positive','finite'});
        validateattributes(config.resolution.z_um_per_px, {'numeric'}, {'scalar','positive','finite'});
    end
    if config.correction.mode == "manual"
        validateattributes(config.correction.value, {'numeric'}, {'scalar','positive','finite'});
    end

    validateattributes(config.dilatedPlaques.radius_um, {'numeric'}, {'scalar','positive','finite'});
    if config.analyses.spheres.enabled
        config.spheres.radiusPairs_um = normalizeSphereRadiusPairs(config.spheres.radiusPairs_um);
        validateattributes(config.spheres.radiusPairs_um, {'numeric'}, {'ncols',2,'positive','finite'});
    end
    validateLayerImageSelection(config);

    if config.parallel.enabled
        validateattributes(config.parallel.numberOfWorkers, {'numeric'}, {'scalar','integer','positive'});
        if isempty(ver('parallel'))
            error('Parallel Computing Toolbox is required when config.parallel.enabled is true.');
        end
    end

    if isempty(ver('images'))
        error('Image Processing Toolbox is required.');
    end
    if isempty(ver('stats'))
        error('Statistics and Machine Learning Toolbox is required.');
    end

    config.voronoi.boundaryMode = normalizeVoronoiBoundaryMode(config);
    config = normalizeMetricIdentifiers(config);
    config = applyMetricDependencies(config);
    config = applyVoronoiDependencies(config);
    validateMetadataColumns(config);
end


function validateModelSubfolders(config)
%VALIDATEMODELSUBFOLDERS Validate model-named input subfolders.
    modelNames = strings(0, 1);
    if config.models.wt
        modelNames(end+1, 1) = string(config.labels.models.control);
    end
    if config.models.ad
        modelNames(end+1, 1) = string(config.labels.models.ad);
    end

    maskRoot = requireScalarPath(config.paths.masks, 'config.paths.masks');
    microgliaRoot = requireScalarPath(config.paths.microglia, 'config.paths.microglia');

    for modelIndex = 1:numel(modelNames)
        modelName = modelNames(modelIndex);
        maskFolder = fullfile(maskRoot, modelName);
        microgliaFolder = fullfile(microgliaRoot, modelName);
        if ~isfolder(maskFolder)
            error('Missing mask subfolder for model %s: %s', ...
                char(modelName), char(maskFolder));
        end
        if ~isfolder(microgliaFolder)
            error('Missing microglia subfolder for model %s: %s', ...
                char(modelName), char(microgliaFolder));
        end
    end
end

function pathValue = requireScalarPath(value, fieldName)
%REQUIRESCALARPATH Convert a configured path to one non-empty string scalar.
    if ischar(value)
        if size(value, 1) ~= 1
            error('%s must contain one folder path, not a multi-row character array.', fieldName);
        end
        pathValue = string(value);
    elseif isstring(value)
        values = value(:);
        values = values(~ismissing(values) & strlength(strtrim(values)) > 0);
        if numel(values) ~= 1
            error('%s must contain exactly one folder path.', fieldName);
        end
        pathValue = values(1);
    elseif iscell(value)
        try
            values = string(value(:));
        catch
            error('%s must be a character vector or string scalar.', fieldName);
        end
        values = values(~ismissing(values) & strlength(strtrim(values)) > 0);
        if numel(values) ~= 1
            error('%s must contain exactly one folder path.', fieldName);
        end
        pathValue = values(1);
    else
        error('%s must be a character vector or string scalar.', fieldName);
    end

    pathValue = strtrim(pathValue);
    if strlength(pathValue) == 0
        error('%s cannot be empty.', fieldName);
    end
end

function config = normalizeMetricIdentifiers(config)
%NORMALIZEMETRICIDENTIFIERS Migrate legacy metric identifiers.
    selected = string(config.metrics.selected);
    selected(selected == "valid_volume_um3") = "analyzed_volume_um3";
    config.metrics.selected = unique(selected, 'stable');

    if isfield(config.metrics.groups, 'globalMicroglia')
        groupSelected = string(config.metrics.groups.globalMicroglia.selected);
        groupSelected(groupSelected == "valid_volume_um3") = "analyzed_volume_um3";
        config.metrics.groups.globalMicroglia.selected = unique(groupSelected, 'stable');
    end
end

function config = applyVoronoiDependencies(config)
%APPLYVORONOIDEPENDENCIES Disable all Voronoi outputs unless explicitly enabled.
    if ~config.voronoi.enabled
        contextFields = fieldnames(config.voronoi.contexts);
        for i = 1:numel(contextFields)
            config.voronoi.contexts.(contextFields{i}).enabled = false;
        end
        if isfield(config.metrics.groups, 'voronoi')
            config.metrics.groups.voronoi.enabled = false;
            config.metrics.groups.voronoi.selected = strings(0,1);
        end
        config.metrics.selected = string(config.metrics.selected);
        config.metrics.selected(startsWith(config.metrics.selected, "voronoi_")) = [];
    end
end

function validateLayerImageSelection(config)
%VALIDATELAYERIMAGESELECTION Validate the configured source of layer eligibility.

    validModes = ["all", "excel", "manual"];
    mode = string(config.layers.imageSelection.mode);
    if ~ismember(mode, validModes)
        error('config.layers.imageSelection.mode must be "all", "excel", or "manual".');
    end

    if strlength(strtrim(string(config.layers.noInformationLabel))) == 0
        error('config.layers.noInformationLabel must contain a non-empty label.');
    end

    if mode == "excel"
        columnName = string(config.layers.imageSelection.column);
        if strlength(columnName) == 0
            columnName = string(config.metadata.columns.layersEnabled);
        end
        if strlength(columnName) == 0
            error('Excel-based layer selection requires config.layers.imageSelection.column.');
        end
    elseif mode == "manual"
        selectedFiles = string(config.layers.imageSelection.selectedFiles);
        selectedFiles = selectedFiles(~ismissing(selectedFiles) & strlength(strtrim(selectedFiles)) > 0);
        if isempty(selectedFiles)
            error('Manual layer selection requires at least one filename in config.layers.imageSelection.selectedFiles.');
        end

    end
end

function validateMetadataColumns(config)
%VALIDATEMETADATACOLUMNS Verify that configured columns exist in the metadata table.
    T = readtable(config.metadata.file, 'Sheet', config.metadata.sheet, 'VariableNamingRule', 'preserve');
    available = string(T.Properties.VariableNames);
    columns = config.metadata.columns;
    required = [ ...
        string(columns.fileName), ...
        string(columns.model), ...
        string(columns.cortexArea), ...
        string(columns.cropSizeX), ...
        string(columns.cropSizeY), ...
        string(columns.cropSizeZ), ...
        string(columns.cropStartX), ...
        string(columns.cropStartY), ...
        string(columns.cropStartZ)];
    if string(config.resolution.mode) == "excel"
        required = [required, ...
            string(config.resolution.xyColumn), ...
            string(config.resolution.zColumn)];
    end
    if string(config.correction.mode) == "excel"
        required(end+1) = string(config.correction.column);
    end
    if string(config.layers.imageSelection.mode) == "excel"
        layerColumn = string(config.layers.imageSelection.column);
        if strlength(layerColumn) == 0
            layerColumn = string(config.metadata.columns.layersEnabled);
        end
        required(end+1) = string(layerColumn);
    end
    required = required(strlength(required) > 0);
    missing = required(~ismember(required, available));
    if ~isempty(missing)
        error('Metadata columns not found: %s', strjoin(missing, ', '));
    end

    if string(config.layers.imageSelection.mode) == "manual"
        selectedFiles = string(config.layers.imageSelection.selectedFiles);
        selectedFiles = selectedFiles(~ismissing(selectedFiles) & strlength(strtrim(selectedFiles)) > 0);
        availableFiles = string(T.(columns.fileName));
        missingFiles = selectedFiles(~ismember(selectedFiles, availableFiles));
        if ~isempty(missingFiles)
            error('Manually selected layer images were not found in the metadata file: %s', strjoin(missingFiles, ', '));
        end
    end

    if config.analyses.layers.enabled
        layerAvailability = resolveLayerImageSelection(T, config);
        if ~any(layerAvailability)
            warning('No metadata rows are selected for cortical-layer analysis.');
        end
    end
end


function boundaryMode = normalizeVoronoiBoundaryMode(config)
%NORMALIZEVORONOIBOUNDARYMODE Normalize the global Voronoi boundary-handling mode.
    boundaryMode = "exclude";
    if isfield(config, 'voronoi') && isfield(config.voronoi, 'boundaryMode')
        candidate = string(config.voronoi.boundaryMode);
        if any(strcmpi(candidate, ["include","exclude"]))
            boundaryMode = lower(candidate);
        end
    end
end

function config = applyMetricDependencies(config)
%APPLYMETRICDEPENDENCIES Remove module-specific metrics when the parent analysis is disabled.
    sphereOnlyGroups = {"spheres", "distances", "radial", "spatialStatistics", "directional"};
    if ~config.analyses.spheres.enabled
        config.outputs.saveSphereImages = false;
        config.parallel.modules.sphereGeneration = false;
        config.parallel.modules.sphereAnalysis = false;
        for i = 1:numel(sphereOnlyGroups)
            fieldName = matlab.lang.makeValidName(sphereOnlyGroups{i});
            if isfield(config.metrics.groups, fieldName)
                config.metrics.groups.(fieldName).enabled = false;
                config.metrics.groups.(fieldName).selected = strings(0,1);
            end
        end
        sphereOnlyMetrics = [
            "sphere_volume_um3"; "sphere_microglia_density_cells_mm3"; "nearest_plaque_distance_um"; ...
            "mean_pairwise_microglia_distance_um"; "mean_nearest_microglia_distance_um"; ...
            "mean_radial_distance"; "ripley_k3_deviation"; "pair_correlation_deviation"; ...
            "polarization"; "alignment"];
        config.metrics.selected = setdiff(string(config.metrics.selected), sphereOnlyMetrics, 'stable');
    end
end


function radiusPairs = normalizeSphereRadiusPairs(radiusPairs)
%NORMALIZESPHERERADIUSPAIRS Convert JSON-decoded radius pairs to an N-by-2 matrix.
    radiusPairs = double(radiusPairs);
    if isempty(radiusPairs)
        error('config.spheres.radiusPairs_um must contain at least one [plaqueRadius, nonPlaqueRadius] pair.');
    end
    if isvector(radiusPairs)
        if numel(radiusPairs) ~= 2
            error('A sphere-radius vector must contain exactly two values: [plaqueRadius, nonPlaqueRadius].');
        end
        radiusPairs = reshape(radiusPairs, 1, 2);
    elseif size(radiusPairs, 2) ~= 2 && size(radiusPairs, 1) == 2
        radiusPairs = radiusPairs.';
    end
end
