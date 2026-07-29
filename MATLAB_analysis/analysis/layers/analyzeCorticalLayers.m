function analyzeCorticalLayers(pathImgMask, pathImgPlaque, pathImgMicroglia, pathCentroids, pathDilatedPlaques, voronoiPath, pathExcel, nameExcel, saveExcel, savePath, saveImagesVar, analysisConfig)
%% Get microglia density and volume data for different zones of the cortex column
% Optimized version.
%
% Main changes:
%   1) Layers are calculated once per image, not once per condition.
%   2) APPNoPlaques and APPJustPlaques are calculated using masks, not by
%      creating duplicated 3D label images.
%   3) arrayfun over centroid indices has been replaced by direct indexing.
%   4) Saved layer images use uint8 or uint16 according to the maximum label.
%   5) Optional parfor is prepared, but disabled by default.
%
% Supporting functions used by this module:
%   readStackTif
%   writeStackTif
%   prepareLayerDataTable
%   preparePlaqueLayerDataTable
%   getZoneFromBorder
%   getVoronoiLayerData

    if ~isfolder(savePath)
        mkdir(savePath);
    end

    if nargin < 12 || isempty(analysisConfig)
        analysisConfig = createMicrogliaConfig();
    end
    firstFile = 1;
    useVoronoi = analysisConfig.voronoi.enabled && analysisConfig.voronoi.contexts.layers.enabled;
    useParallel = analysisConfig.parallel.enabled && analysisConfig.parallel.modules.layers;
    nWorkers = analysisConfig.parallel.numberOfWorkers;

    %% Load Excel table

    tableData = readtable(fullfile(pathExcel, nameExcel));
    listFiles = tableData.Archivo;
    nRows = height(tableData);

    distanceMedial_um = [105, 175, 295, 340];
    distanceLateral_um = [135, 230, 130, 340];

    layerInformationAvailable = getLayerInformationAvailability(tableData);
    filesToProcess = find(layerInformationAvailable);
    filesToProcess = filesToProcess(filesToProcess >= firstFile);
    if isempty(filesToProcess)
        warning('No images were selected for cortical-layer analysis.');
        return;
    end
    results = cell(numel(filesToProcess), 1);

    workerConfig = struct();
    workerConfig.pathImgMask = pathImgMask;
    workerConfig.pathImgPlaque = pathImgPlaque;
    workerConfig.pathImgMicroglia = pathImgMicroglia;
    workerConfig.pathCentroids = pathCentroids;
    workerConfig.pathDilatedPlaques = pathDilatedPlaques;
    workerConfig.voronoiPath = voronoiPath;
    workerConfig.savePath = savePath;
    workerConfig.saveImagesVar = saveImagesVar;
    workerConfig.distanceMedial_um = distanceMedial_um;
    workerConfig.distanceLateral_um = distanceLateral_um;
    workerConfig.useVoronoi = useVoronoi;
    workerConfig.derivedLayersPath = char(analysisConfig.paths.derivedLayers);
    workerConfig.voronoiBoundaryMode = string(analysisConfig.voronoi.boundaryMode);

    %% Process images

    if useParallel
        pool = gcp('nocreate');
        if isempty(pool)
            pool = parpool('local', nWorkers);
        end

        % Refresh the current source file on existing workers. This prevents
        % workers from using an older cached source file after
        % the project code has been updated.
        sourceFile = mfilename('fullpath');
        workerFile = which('processCorticalLayerImage_v230');
        if isempty(workerFile)
            error('The cortical-layer worker file processCorticalLayerImage_v230.m was not found on the MATLAB path.');
        end
        addAttachedFiles(pool, {sourceFile, workerFile});
        updateAttachedFiles(pool);

        parfor ii = 1:numel(filesToProcess)
            task = struct();
            task.nFile = filesToProcess(ii);
            task.listFiles = listFiles;
            task.tableData = tableData;
            task.workerConfig = workerConfig;
            results{ii} = processCorticalLayerImage_v230(task);
        end
    else
        for ii = 1:numel(filesToProcess)
            n_file = filesToProcess(ii);

            fprintf('Processing image %d/%d: %s\n', ...
                ii, numel(filesToProcess), string(listFiles{n_file}));

            task = struct();
            task.nFile = n_file;
            task.listFiles = listFiles;
            task.tableData = tableData;
            task.workerConfig = workerConfig;
            results{ii} = processCorticalLayerImage_v230(task);
        end
    end

    %% Join results

    tableSaveData_WT_Medial = table();
    tableSaveData_WT_Lateral = table();

    tableSaveData_APP_Medial = table();
    tableSaveData_APP_Lateral = table();

    tableSaveData_APPNoPlaques_Medial = table();
    tableSaveData_APPNoPlaques_Lateral = table();

    tableSaveData_APPJustPlaques_Medial = table();
    tableSaveData_APPJustPlaques_Lateral = table();

    tableSaveData_Plaques_Medial = table();
    tableSaveData_Plaques_Lateral = table();

    for ii = 1:numel(results)

        R = results{ii};

        if isempty(R)
            continue;
        end

        tableSaveData_WT_Medial = appendTableRow(tableSaveData_WT_Medial, R.WT_Medial);
        tableSaveData_WT_Lateral = appendTableRow(tableSaveData_WT_Lateral, R.WT_Lateral);

        tableSaveData_APP_Medial = appendTableRow(tableSaveData_APP_Medial, R.APP_Medial);
        tableSaveData_APP_Lateral = appendTableRow(tableSaveData_APP_Lateral, R.APP_Lateral);

        tableSaveData_APPNoPlaques_Medial = appendTableRow(tableSaveData_APPNoPlaques_Medial, R.APPNoPlaques_Medial);
        tableSaveData_APPNoPlaques_Lateral = appendTableRow(tableSaveData_APPNoPlaques_Lateral, R.APPNoPlaques_Lateral);

        tableSaveData_APPJustPlaques_Medial = appendTableRow(tableSaveData_APPJustPlaques_Medial, R.APPJustPlaques_Medial);
        tableSaveData_APPJustPlaques_Lateral = appendTableRow(tableSaveData_APPJustPlaques_Lateral, R.APPJustPlaques_Lateral);

        tableSaveData_Plaques_Medial = appendTableRow(tableSaveData_Plaques_Medial, R.Plaques_Medial);
        tableSaveData_Plaques_Lateral = appendTableRow(tableSaveData_Plaques_Lateral, R.Plaques_Lateral);
    end

    %% Add plaque columns to APP tables, preserving the original logic

    tableSaveData_APP_Lateral = appendPlaqueColumns(tableSaveData_APP_Lateral, tableSaveData_Plaques_Lateral);
    tableSaveData_APP_Medial = appendPlaqueColumns(tableSaveData_APP_Medial, tableSaveData_Plaques_Medial);

    tableSaveData_APPNoPlaques_Lateral = appendPlaqueColumns(tableSaveData_APPNoPlaques_Lateral, tableSaveData_Plaques_Lateral);
    tableSaveData_APPNoPlaques_Medial = appendPlaqueColumns(tableSaveData_APPNoPlaques_Medial, tableSaveData_Plaques_Medial);

    tableSaveData_APPJustPlaques_Lateral = appendPlaqueColumns(tableSaveData_APPJustPlaques_Lateral, tableSaveData_Plaques_Lateral);
    tableSaveData_APPJustPlaques_Medial = appendPlaqueColumns(tableSaveData_APPJustPlaques_Medial, tableSaveData_Plaques_Medial);

    if ~useVoronoi
        tableSaveData_WT_Medial = removeColumnsByPattern(tableSaveData_WT_Medial, ["ValidMicroglia", "MeanNeighs", "StdNeighs", "MeanSurface", "StdSurface", "MeanVolume", "StdVolume", "MeanDistNeighs", "StdDistNeighs"]);
        tableSaveData_WT_Lateral = removeColumnsByPattern(tableSaveData_WT_Lateral, ["ValidMicroglia", "MeanNeighs", "StdNeighs", "MeanSurface", "StdSurface", "MeanVolume", "StdVolume", "MeanDistNeighs", "StdDistNeighs"]);
        tableSaveData_APP_Medial = removeColumnsByPattern(tableSaveData_APP_Medial, ["ValidMicroglia", "MeanNeighs", "StdNeighs", "MeanSurface", "StdSurface", "MeanVolume", "StdVolume", "MeanDistNeighs", "StdDistNeighs"]);
        tableSaveData_APP_Lateral = removeColumnsByPattern(tableSaveData_APP_Lateral, ["ValidMicroglia", "MeanNeighs", "StdNeighs", "MeanSurface", "StdSurface", "MeanVolume", "StdVolume", "MeanDistNeighs", "StdDistNeighs"]);
        tableSaveData_APPNoPlaques_Medial = removeColumnsByPattern(tableSaveData_APPNoPlaques_Medial, ["ValidMicroglia", "MeanNeighs", "StdNeighs", "MeanSurface", "StdSurface", "MeanVolume", "StdVolume", "MeanDistNeighs", "StdDistNeighs"]);
        tableSaveData_APPNoPlaques_Lateral = removeColumnsByPattern(tableSaveData_APPNoPlaques_Lateral, ["ValidMicroglia", "MeanNeighs", "StdNeighs", "MeanSurface", "StdSurface", "MeanVolume", "StdVolume", "MeanDistNeighs", "StdDistNeighs"]);
        tableSaveData_APPJustPlaques_Medial = removeColumnsByPattern(tableSaveData_APPJustPlaques_Medial, ["ValidMicroglia", "MeanNeighs", "StdNeighs", "MeanSurface", "StdSurface", "MeanVolume", "StdVolume", "MeanDistNeighs", "StdDistNeighs"]);
        tableSaveData_APPJustPlaques_Lateral = removeColumnsByPattern(tableSaveData_APPJustPlaques_Lateral, ["ValidMicroglia", "MeanNeighs", "StdNeighs", "MeanSurface", "StdSurface", "MeanVolume", "StdVolume", "MeanDistNeighs", "StdDistNeighs"]);
    end

    tableSaveData_WT_Medial = standardizeOutputTable(tableSaveData_WT_Medial, "layers");
    tableSaveData_WT_Lateral = standardizeOutputTable(tableSaveData_WT_Lateral, "layers");
    tableSaveData_APP_Medial = standardizeOutputTable(tableSaveData_APP_Medial, "layers");
    tableSaveData_APP_Lateral = standardizeOutputTable(tableSaveData_APP_Lateral, "layers");
    tableSaveData_APPNoPlaques_Medial = standardizeOutputTable(tableSaveData_APPNoPlaques_Medial, "layers");
    tableSaveData_APPNoPlaques_Lateral = standardizeOutputTable(tableSaveData_APPNoPlaques_Lateral, "layers");
    tableSaveData_APPJustPlaques_Medial = standardizeOutputTable(tableSaveData_APPJustPlaques_Medial, "layers");
    tableSaveData_APPJustPlaques_Lateral = standardizeOutputTable(tableSaveData_APPJustPlaques_Lateral, "layers");

    %% Save Excel

    excelFile = fullfile(savePath, saveExcel);

    if ~isempty(tableSaveData_WT_Lateral), writetable(tableSaveData_WT_Lateral, excelFile, 'Sheet', 'WT_Lateral'); end
    if ~isempty(tableSaveData_WT_Medial),  writetable(tableSaveData_WT_Medial,  excelFile, 'Sheet', 'WT_Medial');  end

    if ~isempty(tableSaveData_APP_Lateral)
        writetable(tableSaveData_APP_Lateral, excelFile, 'Sheet', 'AD_Lateral');
    end

    if ~isempty(tableSaveData_APP_Medial)
        writetable(tableSaveData_APP_Medial, excelFile, 'Sheet', 'AD_Medial');
    end

    if ~isempty(tableSaveData_APPNoPlaques_Lateral)
        writetable(tableSaveData_APPNoPlaques_Lateral, excelFile, 'Sheet', 'ADNoPlaques_Lateral');
    end

    if ~isempty(tableSaveData_APPNoPlaques_Medial)
        writetable(tableSaveData_APPNoPlaques_Medial, excelFile, 'Sheet', 'ADNoPlaques_Medial');
    end

    if ~isempty(tableSaveData_APPJustPlaques_Lateral)
        writetable(tableSaveData_APPJustPlaques_Lateral, excelFile, 'Sheet', 'ADPlaques_Lateral');
    end

    if ~isempty(tableSaveData_APPJustPlaques_Medial)
        writetable(tableSaveData_APPJustPlaques_Medial, excelFile, 'Sheet', 'ADPlaques_Medial');
    end

end


function T = appendTableRow(T, rowT)
%APPENDTABLEROW Append a non-empty one-row table to an accumulated table.

    if isempty(rowT)
        return;
    end

    if isempty(T)
        T = rowT;
    else
        T = [T; rowT];
    end

end


function T = appendPlaqueColumns(T, P)
%APPENDPLAQUECOLUMNS Append plaque summary columns after validating compatibility.

    if isempty(T) || isempty(P)
        return;
    end

    if height(T) ~= height(P)
        error('Cannot append plaque columns because row numbers are different. Microglia rows: %d. Plaque rows: %d.', height(T), height(P));
    end

    duplicateNames = intersect(string(T.Properties.VariableNames), ...
        string(P.Properties.VariableNames), 'stable');
    if ~isempty(duplicateNames)
        error(['Cannot append plaque columns because duplicate variable names remain: %s. ' ...
            'Plaque-specific layer volumes must use the suffix _Plaques.'], ...
            strjoin(duplicateNames, ', '));
    end

    T = [T, P];

end


