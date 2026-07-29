function config = configureMicrogliaAnalysisInteractive()
%CONFIGUREMICROGLIAANALYSISINTERACTIVE Create a configuration using MATLAB dialogs.

    % The interactive workflow starts from the metrics used in the paper.
    % Advanced metrics are offered separately after the main selection.
    config = createMicrogliaConfig("paper_metrics");

    modelItems = {'WT / control', 'APP / AD'};
    [modelIndex, ok] = listdlg('PromptString', 'Select models to analyze', ...
        'ListString', modelItems, 'SelectionMode', 'multiple', 'InitialValue', [1 2]);
    requireDialogConfirmation(ok, 'Model selection');
    config.models.wt = ismember(1, modelIndex);
    config.models.ad = ismember(2, modelIndex);

    config.paths.masks = string(selectFolder('Select folder containing binary tissue masks'));
    config.paths.microglia = string(selectFolder('Select folder containing labeled microglia segmentations'));
    if config.models.ad
        config.paths.plaques = string(selectFolder('Select folder containing labeled plaque segmentations'));
    end
    config.paths.output = string(selectFolder('Select the main output folder'));

    [metadataName, metadataPath] = uigetfile({'*.xlsx;*.xls', 'Excel metadata files'}, ...
        'Select the metadata Excel file');
    if isequal(metadataName, 0)
        error('Metadata file selection was cancelled.');
    end
    config.metadata.file = string(fullfile(metadataPath, metadataName));

    metadata = readtable(config.metadata.file, 'VariableNamingRule', 'preserve');
    variableNames = string(metadata.Properties.VariableNames);
    config = selectMetadataColumns(config, variableNames);
    config = selectResolutionAndCorrection(config, variableNames);

    analysisItems = {'Global microglia data', 'Global plaque data', ...
        'Individual plaque data', 'Cortical layer data', 'Sphere data'};
    [analysisIndex, ok] = listdlg('PromptString', 'Select analyses to run', ...
        'ListString', analysisItems, 'SelectionMode', 'multiple', 'InitialValue', 1:5);
    requireDialogConfirmation(ok, 'Analysis selection');
    config.analyses.globalMicroglia.enabled = ismember(1, analysisIndex);
    config.analyses.globalPlaques.enabled = ismember(2, analysisIndex) && config.models.ad;
    config.analyses.individualPlaques.enabled = ismember(3, analysisIndex) && config.models.ad;
    config.analyses.layers.enabled = ismember(4, analysisIndex);
    config.analyses.spheres.enabled = ismember(5, analysisIndex);

    if config.analyses.layers.enabled || config.analyses.individualPlaques.enabled || config.analyses.spheres.enabled
        config = configureLayerImageSelection(config, metadata, variableNames);
    end

    config = configureDilatedPlaques(config);
    config = configureSpheres(config);
    config = configureOutputs(config);
    config = configureParallelExecution(config);

    config = configureMetricSelection(config);
end

function config = selectMetadataColumns(config, variables)
%SELECTMETADATACOLUMNS Map user-facing metadata columns to internal names.
    C = config.metadata.columns;
    C.fileName = chooseColumn(variables, 'Select the image filename column', C.fileName, false);
    C.model = chooseColumn(variables, 'Select the model column', C.model, false);
    C.cortexArea = chooseColumn(variables, 'Select the cortical region column', C.cortexArea, false);
    C.mouse = chooseColumn(variables, 'Select the mouse identifier column', C.mouse, true);
    C.sex = chooseColumn(variables, 'Select the sex column', C.sex, true);
    C.section = chooseColumn(variables, 'Select the section identifier column', C.section, true);
    C.image = chooseColumn(variables, 'Select the image identifier column', C.image, true);
    C.bregmaLevel = chooseColumn(variables, 'Select the bregma-level column', C.bregmaLevel, true);
    C.cropSizeX = chooseColumn(variables, 'Select crop size X column', C.cropSizeX, false);
    C.cropSizeY = chooseColumn(variables, 'Select crop size Y column', C.cropSizeY, false);
    C.cropSizeZ = chooseColumn(variables, 'Select crop size Z column', C.cropSizeZ, false);
    C.cropStartX = chooseColumn(variables, 'Select crop start X column', C.cropStartX, false);
    C.cropStartY = chooseColumn(variables, 'Select crop start Y column', C.cropStartY, false);
    C.cropStartZ = chooseColumn(variables, 'Select crop start Z column', C.cropStartZ, false);
    config.metadata.columns = C;
end

function config = selectResolutionAndCorrection(config, variables)
%SELECTRESOLUTIONANDCORRECTION Configure image calibration and shrinkage correction.
    mode = questdlg('How are image resolutions provided?', 'Image calibration', ...
        'Excel columns', 'Manual values', 'Excel columns');
    if strcmp(mode, 'Manual values')
        values = inputdlg({'XY resolution (um/pixel)', 'Z resolution (um/pixel)'}, ...
            'Image calibration', 1, {'0.4545', '0.5669'});
        if isempty(values), error('Image calibration was cancelled.'); end
        config.resolution.mode = "manual";
        config.resolution.xy_um_per_px = str2double(values{1});
        config.resolution.z_um_per_px = str2double(values{2});
    else
        config.resolution.mode = "excel";
        config.resolution.xyColumn = chooseColumn(variables, 'Select XY-resolution column', config.resolution.xyColumn, false);
        config.resolution.zColumn = chooseColumn(variables, 'Select Z-resolution column', config.resolution.zColumn, false);
    end

    mode = questdlg('How is the correction factor provided?', 'Correction factor', ...
        'No correction', 'Excel column', 'Manual value', 'Excel column');
    switch mode
        case 'No correction'
            config.correction.mode = "none";
        case 'Manual value'
            value = inputdlg('Correction factor', 'Correction factor', 1, {'1'});
            if isempty(value), error('Correction-factor configuration was cancelled.'); end
            config.correction.mode = "manual";
            config.correction.value = str2double(value{1});
        otherwise
            config.correction.mode = "excel";
            config.correction.column = chooseColumn(variables, 'Select correction-factor column', config.correction.column, false);
    end
end

function config = configureLayerImageSelection(config, metadata, variables)
%CONFIGURELAYERIMAGESELECTION Define which images have valid cortical-layer information.
%
% The selection controls both the dedicated cortical-layer analysis and the
% layer labels written to individual plaque and sphere tables.

    choice = questdlg( ...
        'Which images have valid information for cortical-layer assignment?', ...
        'Layer image selection', ...
        'All images', 'Select manually', 'Use Excel column', 'All images');

    switch choice
        case 'Select manually'
            config.layers.imageSelection.mode = "manual";
            fileColumn = config.metadata.columns.fileName;
            modelColumn = config.metadata.columns.model;

            fileNames = string(metadata.(fileColumn));
            keepRows = true(height(metadata), 1);
            if strlength(string(modelColumn)) > 0 && ismember(string(modelColumn), string(metadata.Properties.VariableNames))
                modelValues = string(metadata.(modelColumn));
                keepRows = false(height(metadata), 1);
                if config.models.wt
                    keepRows = keepRows | strcmpi(modelValues, string(config.labels.models.control));
                end
                if config.models.ad
                    keepRows = keepRows | strcmpi(modelValues, string(config.labels.models.ad));
                end
            end

            fileNames = unique(fileNames(keepRows), 'stable');
            fileNames = fileNames(~ismissing(fileNames) & strlength(strtrim(fileNames)) > 0);
            if isempty(fileNames)
                error('No image filenames are available for manual layer selection.');
            end

            [selected, ok] = listdlg( ...
                'PromptString', 'Select images with valid cortical-layer information', ...
                'ListString', cellstr(fileNames), ...
                'SelectionMode', 'multiple', ...
                'InitialValue', 1:numel(fileNames), ...
                'ListSize', [600 500]);
            requireDialogConfirmation(ok, 'Layer image selection');
            if isempty(selected)
                error('At least one image must be selected for manual layer assignment.');
            end

            config.layers.imageSelection.selectedFiles = fileNames(selected);
            config.layers.imageSelection.column = "";

        case 'Use Excel column'
            config.layers.imageSelection.mode = "excel";
            defaultColumn = config.layers.imageSelection.column;
            if strlength(string(defaultColumn)) == 0
                defaultColumn = config.metadata.columns.layersEnabled;
            end
            selectedColumn = chooseColumn(variables, ...
                'Select the column indicating valid layer information', ...
                defaultColumn, false);
            config.layers.imageSelection.column = selectedColumn;
            config.metadata.columns.layersEnabled = selectedColumn;
            config.layers.imageSelection.selectedFiles = strings(0, 1);

        otherwise
            config.layers.imageSelection.mode = "all";
            config.layers.imageSelection.column = "";
            config.layers.imageSelection.selectedFiles = strings(0, 1);
    end
end

function config = configureDilatedPlaques(config)
%CONFIGUREDILATEDPLAQUES Configure plaque dilation input and output behavior.
    if ~config.models.ad
        return;
    end
    choice = questdlg('How should dilated plaques be obtained?', 'Dilated plaques', ...
        'Use existing', 'Generate and save', 'Generate temporarily', 'Generate and save');
    switch choice
        case 'Use existing'
            config.dilatedPlaques.mode = "existing";
            config.paths.dilatedPlaques = string(selectFolder('Select folder containing dilated plaque labels'));
        case 'Generate temporarily'
            config.dilatedPlaques.mode = "generate-temporary";
            config.outputs.saveDilatedPlaques = false;
        otherwise
            config.dilatedPlaques.mode = "generate-and-save";
            config.outputs.saveDilatedPlaques = true;
    end
    value = inputdlg('Plaque dilation radius (um)', 'Dilated plaques', 1, {'9'});
    if ~isempty(value)
        config.dilatedPlaques.radius_um = str2double(value{1});
    end
end

function config = configureSpheres(config)
%CONFIGURESPHERES Configure existing or newly generated sphere definitions.
    if ~config.analyses.spheres.enabled
        return;
    end
    choice = questdlg('Generate sphere definitions or use existing definitions?', ...
        'Sphere definitions', 'Generate', 'Use existing', 'Generate');
    if strcmp(choice, 'Use existing')
        config.spheres.mode = "existing";
    else
        config.spheres.mode = "generate";
    end
    values = inputdlg({'Plaque-sphere radii (um, comma-separated)', ...
        'Non-plaque-sphere radii (um, comma-separated)'}, ...
        'Sphere radius pairs', 1, {'100,100', '50,100'});
    if isempty(values), error('Sphere-radius configuration was cancelled.'); end
    plaqueRadii = str2num(values{1}); %#ok<ST2NM>
    nonPlaqueRadii = str2num(values{2}); %#ok<ST2NM>
    if numel(plaqueRadii) ~= numel(nonPlaqueRadii)
        error('Plaque and non-plaque radius lists must contain the same number of values.');
    end
    config.spheres.radiusPairs_um = [plaqueRadii(:), nonPlaqueRadii(:)];
    if config.spheres.mode == "existing"
        folders = strings(numel(plaqueRadii), 1);
        for i = 1:numel(plaqueRadii)
            titleText = sprintf('Select sphere folder for plaque %.3g um / non-plaque %.3g um', ...
                plaqueRadii(i), nonPlaqueRadii(i));
            folders(i) = string(selectFolder(titleText));
        end
        config.paths.existingSphereFolders = folders;
    end
end

function config = configureOutputs(config)
%CONFIGUREOUTPUTS Select optional intermediate image outputs for enabled modules.
    config.outputs.saveLayerImages = false;
    config.outputs.saveSphereImages = false;
    config.outputs.saveADNoPlaquesImages = false;
    config.outputs.saveADPlaquesImages = false;

    if config.analyses.layers.enabled
        config.outputs.saveLayerImages = askYesNo('Save cortical layer label images?');
    end
    if config.analyses.spheres.enabled
        % Generated sphere labels are required by the analysis stage and are
        % therefore always written to the centralized DerivedImages folder.
        config.outputs.saveSphereImages = string(config.spheres.mode) == "generate";
    end
    if config.models.ad && config.analyses.globalMicroglia.enabled
        config.outputs.saveADNoPlaquesImages = askYesNo('Save AD no-plaque microglia images?');
        config.outputs.saveADPlaquesImages = askYesNo('Save AD plaque-region microglia images?');
    end
end

function config = configureParallelExecution(config)
%CONFIGUREPARALLELEXECUTION Configure optional image-level parallel processing.
    config.parallel.enabled = askYesNo('Enable parallel processing where supported?');
    if ~config.parallel.enabled
        return;
    end
    value = inputdlg('Number of parallel workers', 'Parallel processing', 1, {'2'});
    if isempty(value), error('Parallel configuration was cancelled.'); end
    config.parallel.numberOfWorkers = str2double(value{1});
    moduleNames = {'Global microglia', 'Individual plaques', 'Layers', ...
        'Sphere generation', 'Sphere analysis'};
    [selected, ok] = listdlg('PromptString', 'Select modules allowed to use parallel processing', ...
        'ListString', moduleNames, 'SelectionMode', 'multiple', 'InitialValue', 1:5);
    requireDialogConfirmation(ok, 'Parallel module selection');
    fields = {'globalMicroglia', 'individualPlaques', 'layers', 'sphereGeneration', 'sphereAnalysis'};
    for i = 1:numel(fields)
        config.parallel.modules.(fields{i}) = ismember(i, selected);
    end
    if ~config.analyses.spheres.enabled
        config.parallel.modules.sphereGeneration = false;
        config.parallel.modules.sphereAnalysis = false;
    end
    if ~config.analyses.layers.enabled
        config.parallel.modules.layers = false;
    end
    if ~config.analyses.individualPlaques.enabled
        config.parallel.modules.individualPlaques = false;
    end
end

function config = configureMetricSelection(config)
%CONFIGUREMETRICSELECTION Select paper metrics first and advanced metrics separately.
    catalog = filterCatalogForEnabledAnalyses(getMetricCatalog(), config);
    paperCatalog = catalog([catalog.paper]);
    advancedCatalog = catalog(~[catalog.paper]);

    paperLabels = buildMetricLabels(paperCatalog);
    [selectedPaper, ok] = listdlg( ...
        'Name', 'Paper metrics', ...
        'PromptString', {'Metrics used in the paper', ...
            'These are selected by default. Deselect only metrics you do not need.'}, ...
        'ListString', cellstr(paperLabels), ...
        'SelectionMode', 'multiple', ...
        'InitialValue', 1:numel(paperCatalog), ...
        'ListSize', [760 500]);
    requireDialogConfirmation(ok, 'Paper metric selection');

    selectedIDs = string({paperCatalog(selectedPaper).id})';

    if ~isempty(advancedCatalog)
        addAdvanced = askYesNo('Select other advanced metrics?');
        if addAdvanced
            advancedLabels = buildMetricLabels(advancedCatalog);
            [selectedAdvanced, ok] = listdlg( ...
                'Name', 'Other advanced metrics', ...
                'PromptString', {'Other advanced metrics', ...
                    'These metrics are not part of the default paper analysis.'}, ...
                'ListString', cellstr(advancedLabels), ...
                'SelectionMode', 'multiple', ...
                'InitialValue', [], ...
                'ListSize', [760 500]);
            requireDialogConfirmation(ok, 'Advanced metric selection');
            selectedIDs = [selectedIDs; string({advancedCatalog(selectedAdvanced).id})'];
        end
    end

    config.metrics.preset = "custom";
    config.metrics.selected = unique(selectedIDs, 'stable');

    fullCatalog = getMetricCatalog();
    groups = unique(string({fullCatalog.group}), 'stable');
    for group = groups
        fieldName = matlab.lang.makeValidName(group);
        groupIDs = string({fullCatalog(string({fullCatalog.group}) == group).id});
        config.metrics.groups.(fieldName).enabled = any(ismember(groupIDs, config.metrics.selected));
        config.metrics.groups.(fieldName).selected = groupIDs(ismember(groupIDs, config.metrics.selected));
    end
end

function labels = buildMetricLabels(catalog)
%BUILDMETRICLABELS Build descriptive labels for a metric-selection dialog.
    labels = strings(numel(catalog), 1);
    for i = 1:numel(catalog)
        labels(i) = sprintf('%s [%s] - %s', ...
            catalog(i).label, catalog(i).unit, catalog(i).description);
    end
end

function catalog = filterCatalogForEnabledAnalyses(catalog, config)
%FILTERCATALOGFORENABLEDANALYSES Hide module-specific metrics when a module is disabled.
    keep = true(1, numel(catalog));
    sphereOnlyGroups = ["spheres", "distances", "radial", "spatialStatistics", "directional"];
    if ~config.analyses.spheres.enabled
        keep = keep & ~ismember(string({catalog.group}), sphereOnlyGroups);
    end
    if ~config.analyses.individualPlaques.enabled
        keep = keep & string({catalog.group}) ~= "individualPlaques";
    end
    if ~config.analyses.layers.enabled
        keep = keep & string({catalog.group}) ~= "layers";
    end
    if ~config.analyses.globalMicroglia.enabled
        keep = keep & string({catalog.group}) ~= "globalMicroglia";
    end
    if ~config.analyses.globalPlaques.enabled
        keep = keep & string({catalog.group}) ~= "globalPlaques";
    end
    keep = keep & string({catalog.group}) ~= "voronoi";
    catalog = catalog(keep);
end

function folder = selectFolder(titleText)
%SELECTFOLDER Open a folder-selection dialog and reject cancellation.
    folder = uigetdir(pwd, titleText);
    if isequal(folder, 0)
        error('Folder selection was cancelled: %s', titleText);
    end
end

function columnName = chooseColumn(variables, promptText, defaultName, optional)
%CHOOSECOLUMN Select one required or optional metadata column.
    if optional
        choices = ["<none>", variables];
    else
        choices = variables;
    end
    initial = find(choices == string(defaultName), 1);
    if isempty(initial), initial = 1; end
    [index, ok] = listdlg('PromptString', promptText, 'ListString', cellstr(choices), ...
        'SelectionMode', 'single', 'InitialValue', initial);
    requireDialogConfirmation(ok, 'Column selection');
    if optional && index == 1
        columnName = "";
    else
        columnName = choices(index);
    end
end

function result = askYesNo(questionText)
%ASKYESNO Return true only when the user selects Yes.
    result = strcmp(questdlg(questionText, 'Microglia analysis', 'Yes', 'No', 'No'), 'Yes');
end

function requireDialogConfirmation(ok, context)
%REQUIREDIALOGCONFIRMATION Reject cancelled list dialogs.
    if ~ok
        error('%s was cancelled.', context);
    end
end
