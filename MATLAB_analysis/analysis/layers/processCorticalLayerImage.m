function R = processCorticalLayerImage(task)
%PROCESSCORTICALLAYERIMAGE_V230 Calculate layer-specific results for one image.
%
% This standalone worker accepts one task structure. Its unique function
% name prevents parallel workers from reusing an older local signature.

    if nargin ~= 1 || ~isstruct(task) || ~isscalar(task)
        error('processCorticalLayerImage_v230 expects one scalar task structure.');
    end

    requiredFields = {'nFile', 'listFiles', 'tableData', 'workerConfig'};
    missingFields = requiredFields(~isfield(task, requiredFields));
    if ~isempty(missingFields)
        error('Cortical-layer worker task is missing fields: %s', strjoin(missingFields, ', '));
    end

    n_file = task.nFile;
    listFiles = task.listFiles;
    tableData = task.tableData;
    workerConfig = task.workerConfig;

    pathImgMask = workerConfig.pathImgMask;
    pathImgPlaque = workerConfig.pathImgPlaque;
    pathImgMicroglia = workerConfig.pathImgMicroglia;
    pathCentroids = workerConfig.pathCentroids;
    pathDilatedPlaques = workerConfig.pathDilatedPlaques;
    voronoiPath = workerConfig.voronoiPath;
    savePath = workerConfig.savePath;
    saveImagesVar = workerConfig.saveImagesVar;
    distanceMedial_um = workerConfig.distanceMedial_um;
    distanceLateral_um = workerConfig.distanceLateral_um;
    useVoronoi = workerConfig.useVoronoi;
    derivedLayersPath = workerConfig.derivedLayersPath;
    voronoiBoundaryMode = workerConfig.voronoiBoundaryMode;

    R = initializeEmptyResultStruct();

    filename = char(string(listFiles{n_file}));

    excelRow = find(string(tableData.Archivo) == string(filename), 1, 'first');

    if isempty(excelRow)
        warning('File %s was not found in tableData.Archivo. Skipping.', filename);
        return;
    end

    if ~getLayerInformationAvailability(tableData, excelRow)
        return;
    end

    cortexArea = char(string(tableData.Zona(excelRow)));
    modelType = char(string(tableData.Modelo(excelRow)));
    outputModelType = char(getOutputModelName(modelType));

    isLateral = ~contains(cortexArea, 'Medial');

    if isLateral
        distance_um = distanceLateral_um;
        areaName = 'Lateral';
    else
        distance_um = distanceMedial_um;
        areaName = 'Medial';
    end

    %% Load input data

    imgMaskPath = fullfile(pathImgMask, modelType, [filename, '.tif']);
    imgMask = logical(readStackTif(imgMaskPath));

    imgMicrogliaPath = fullfile(pathImgMicroglia, modelType, [filename, '.tif']);
    imgMicroglia = readStackTif(imgMicrogliaPath);
    imgSize = size(imgMicroglia);

    if useVoronoi
        centroidFile = fullfile(pathCentroids, [filename, '.mat']);
        Scent = load(centroidFile);
        centroids = extractVariableFromMatStruct(Scent, 'centroids');
        voronoiFile = fullfile(voronoiPath, modelType, [filename, '.mat']);
        Svor = load(voronoiFile, ...
            'good_neighbours', 'vornb', 'neib_number', 'col', ...
            'total_Distance_Neighbours_1', 'total_Surface_Area_1', ...
            'total_Volum_1');
    else
        centroids = extractInstanceCentroids(imgMicroglia);
        Svor = createEmptyVoronoiStruct_Layers();
    end

    %% Plaque-related masks and labels

    imgPlaqueDilatedPath = fullfile(pathDilatedPlaques, [filename, '.tif']);

    if isfile(imgPlaqueDilatedPath)
        imgPlaqueDilated = logical(readStackTif(imgPlaqueDilatedPath));
        plaqueMicrogliaLabels = unique(imgMicroglia(imgPlaqueDilated > 0));
    else
        imgPlaqueDilated = false(imgSize);
        plaqueMicrogliaLabels = [];
    end

    if isempty(plaqueMicrogliaLabels)
        plaqueMicrogliaLabels = [];
    end

    allMicrogliaLabels = unique(imgMicroglia);
    nonPlaqueMicrogliaLabels = setdiff(allMicrogliaLabels, plaqueMicrogliaLabels);

    %% Calculate layer maps once

    % Microglia layer measurements use the configured orthogonal crop.
    useCrop = true;
    [layerMapMicroglia, validCentroids, borderCentroids] = computeLayerMapAndCentroids_optimized( ...
        imgMask, centroids, tableData, distance_um, excelRow, isLateral, useCrop);

    % Plaque layer measurements use the full valid tissue mask without the orthogonal crop.
    % Therefore, we build a second layer map without the crop to preserve behavior.
    useCrop = false;
    [layerMapPlaques, ~, ~] = computeLayerMapAndCentroids_optimized( ...
        imgMask, centroids, tableData, distance_um, excelRow, isLateral, useCrop);

    clear imgMask;

    %% Save layer image only once

    if saveImagesVar
        imageSaveDir = fullfile(derivedLayersPath, outputModelType, areaName);
        if ~isfolder(imageSaveDir)
            mkdir(imageSaveDir);
        end

        writeStackTif(castLabelImageForStorage(layerMapMicroglia), ...
            fullfile(imageSaveDir, [filename, '.tif']));
    end

    %% Common paths

    baseSavePath = fullfile(savePath, outputModelType, areaName);
    noPlaqueSavePath = fullfile(savePath, 'ADNoPlaques', areaName);
    justPlaqueSavePath = fullfile(savePath, 'ADPlaques', areaName);

    %% Calculate WT or APP microglia data

    if contains(modelType, 'APP')

        imgPlaquesPath = fullfile(pathImgPlaque, [filename, '.tif']);

        if isfile(imgPlaquesPath)
            imgPlaques = readStackTif(imgPlaquesPath);
        else
            imgPlaques = false(imgSize);
        end

        plaqueTable = preparePlaqueLayerDataTable(table(), 1, areaName);
        plaqueTable = summarizePlaquesByLayer_optimized( ...
            layerMapPlaques, imgPlaques, tableData, distance_um, excelRow, ...
            plaqueTable, 1, isLateral);

        microgliaTable_APP = prepareLayerDataTable(table(), 1, areaName);
        microgliaTable_APP = summarizeMicrogliaByLayer_optimized( ...
            layerMapMicroglia, [], validCentroids, borderCentroids, ...
            tableData, distance_um, excelRow, microgliaTable_APP, 1, ...
            baseSavePath, isLateral, Svor, filename, imgSize, 0, useVoronoi, voronoiBoundaryMode);

        microgliaTable_APP = fillMetadataColumns(microgliaTable_APP, 1, tableData, excelRow, filename, cortexArea, outputModelType);

        microgliaTable_NoPlaques = prepareLayerDataTable(table(), 1, areaName);
        microgliaTable_NoPlaques = summarizeMicrogliaByLayer_optimized( ...
            layerMapMicroglia, ~imgPlaqueDilated, validCentroids, borderCentroids, ...
            tableData, distance_um, excelRow, microgliaTable_NoPlaques, 1, ...
            noPlaqueSavePath, isLateral, Svor, filename, imgSize, plaqueMicrogliaLabels, useVoronoi, voronoiBoundaryMode);

        microgliaTable_NoPlaques = fillMetadataColumns(microgliaTable_NoPlaques, 1, tableData, excelRow, filename, cortexArea, 'ADNoPlaques');

        microgliaTable_JustPlaques = prepareLayerDataTable(table(), 1, areaName);
        microgliaTable_JustPlaques = summarizeMicrogliaByLayer_optimized( ...
            layerMapMicroglia, imgPlaqueDilated, validCentroids, borderCentroids, ...
            tableData, distance_um, excelRow, microgliaTable_JustPlaques, 1, ...
            justPlaqueSavePath, isLateral, Svor, filename, imgSize, nonPlaqueMicrogliaLabels, useVoronoi, voronoiBoundaryMode);

        microgliaTable_JustPlaques = fillMetadataColumns(microgliaTable_JustPlaques, 1, tableData, excelRow, filename, cortexArea, 'ADPlaques');

        if isLateral
            R.APP_Lateral = microgliaTable_APP;
            R.APPNoPlaques_Lateral = microgliaTable_NoPlaques;
            R.APPJustPlaques_Lateral = microgliaTable_JustPlaques;
            R.Plaques_Lateral = plaqueTable;
        else
            R.APP_Medial = microgliaTable_APP;
            R.APPNoPlaques_Medial = microgliaTable_NoPlaques;
            R.APPJustPlaques_Medial = microgliaTable_JustPlaques;
            R.Plaques_Medial = plaqueTable;
        end

    else

        microgliaTable_WT = prepareLayerDataTable(table(), 1, areaName);

        microgliaTable_WT = summarizeMicrogliaByLayer_optimized( ...
            layerMapMicroglia, [], validCentroids, borderCentroids, ...
            tableData, distance_um, excelRow, microgliaTable_WT, 1, ...
            baseSavePath, isLateral, Svor, filename, imgSize, 0, useVoronoi, voronoiBoundaryMode);

        microgliaTable_WT = fillMetadataColumns(microgliaTable_WT, 1, tableData, excelRow, filename, cortexArea, outputModelType);

        if isLateral
            R.WT_Lateral = microgliaTable_WT;
        else
            R.WT_Medial = microgliaTable_WT;
        end
    end

end


%COMPUTELAYERMAPANDCENTROIDS_OPTIMIZED Build a layer label map and identify valid centroids.
function [layerMap, validCentroids, borderCentroids] = computeLayerMapAndCentroids_optimized( ...
    imgMask, centroids, tableData, distance_um, excelRow, isLateral, useCrop)

    imgMask = logical(imgMask);

    correctionFactor = tableData.Correction_Factor(excelRow);
    distance_um = distance_um ./ correctionFactor;

    xyResolution = tableData.ResolucionXY_um_pxl(excelRow);
    distance_pxl = round(distance_um ./ xyResolution);

    starts_zones = [0, cumsum(distance_pxl)];
    starts_zones(end) = [];

    imgBorder = imgMask;
    imgBorder(cumsum(imgBorder, 2) > 1) = 0;

    [~, xMask, ~] = ind2sub(size(imgBorder), find(imgBorder));

    if isempty(xMask)
        layerMap = zeros(size(imgMask), 'uint8');
        validCentroids = zeros(0, 3);
        borderCentroids = [];
        return;
    end

    xStart = min(xMask);
    clear xMask;

    if useCrop
        desire_pxls = [ ...
            tableData.XCorte2_pxl(excelRow), ...
            tableData.Ycorte_pxl(excelRow), ...
            tableData.Zcorte_pxl(excelRow)];

        cropStart = [ ...
            tableData.CoordXCorte2_pxl(excelRow) + 1, ...
            tableData.CoordYCorte_pxl(excelRow) + 1, ...
            tableData.CoordZCorte_pxl(excelRow) + 1];

        cropMask = false(size(imgMask));

        x1 = max(1, cropStart(1));
        y1 = max(1, cropStart(2));
        z1 = max(1, cropStart(3));

        x2 = min(size(imgMask, 2), cropStart(1) + desire_pxls(1));
        y2 = min(size(imgMask, 1), cropStart(2) + desire_pxls(2));
        z2 = min(size(imgMask, 3), cropStart(3) + desire_pxls(3));

        cropMask(y1:y2, x1:x2, z1:z2) = true;
        validBaseMask = imgMask & cropMask;

        validCentroids = centroids( ...
            centroids(:,1) <= x2 & centroids(:,1) >= x1 & ...
            centroids(:,2) <= y2 & centroids(:,2) >= y1 & ...
            centroids(:,3) <= z2 & centroids(:,3) >= z1, :);
    else
        validBaseMask = imgMask;
        validCentroids = centroids;
    end

    layerMap = zeros(size(imgMask), 'uint8');

    for nZ = 1:length(distance_pxl)

        if (xStart + starts_zones(nZ)) > size(imgBorder, 2)
            continue;
        end

        newBorder = false(size(imgBorder));
        newBorder(:, starts_zones(nZ)+1:end, :) = imgBorder(:, 1:(end-starts_zones(nZ)), :);

        targetZone = logical(getZoneFromBorder(newBorder, distance_pxl(nZ)));
        targetZone = targetZone & validBaseMask;

        layerMap(targetZone) = uint8(nZ);

        clear newBorder targetZone;
    end

    if isempty(validCentroids)
        borderCentroids = [];
    else
        cx = clamp(round(validCentroids(:,1)), 1, size(imgMask, 2));
        cy = clamp(round(validCentroids(:,2)), 1, size(imgMask, 1));
        cz = clamp(round(validCentroids(:,3)), 1, size(imgMask, 3));

        borderCentroids = sub2ind(size(imgMask), cy, cx, cz);
    end

end


%SUMMARIZEMICROGLIABYLAYER_OPTIMIZED Calculate microglia density and optional Voronoi metrics by layer.
function tableLayersData = summarizeMicrogliaByLayer_optimized( ...
    layerMap, boundaryMask, validCentroids, borderCentroids, ...
    tableData, distance_um, excelRow, tableLayersData, nSample, savePath, ...
    isLateral, Svor, filename, imgSize, excludedCellsForVoronoi, useVoronoi, voronoiBoundaryMode)

    correctionFactor = tableData.Correction_Factor(excelRow);
    xyResolution = tableData.ResolucionXY_um_pxl(excelRow);
    zResolution = tableData.ResolucionZ_um_pxl(excelRow);
    voxelVolume_um3 = xyResolution * xyResolution * zResolution;

    distance_um = distance_um ./ correctionFactor;
    distance_pxl = round(distance_um ./ xyResolution);

    layerNumbers = getLayerNumbers(isLateral);

    if isempty(boundaryMask)
        validVoxelMask = layerMap > 0;
        centroidInBoundary = true(size(borderCentroids));
    else
        boundaryMask = logical(boundaryMask);
        validVoxelMask = (layerMap > 0) & boundaryMask;

        if isempty(borderCentroids)
            centroidInBoundary = [];
        else
            centroidInBoundary = boundaryMask(borderCentroids);
        end
    end

    if isempty(borderCentroids)
        centroidLayer = [];
        totalMicroglia = 0;
    else
        centroidLayer = layerMap(borderCentroids);
        totalMicroglia = sum(centroidLayer > 0 & centroidInBoundary);
    end

    for nZ = 1:length(distance_pxl)

        nLayer = layerNumbers(nZ);

        layerVoxelMask = (layerMap == nZ) & validVoxelMask;
        validVolume_um3_uncorrected = nnz(layerVoxelMask) * voxelVolume_um3;

        if isempty(centroidLayer)
            targetCentroids = false(0, 1);
        else
            targetCentroids = (centroidLayer == nZ) & centroidInBoundary;
        end

        microgliaN = sum(targetCentroids);
        microgliaDensity = safeDivide(microgliaN, validVolume_um3_uncorrected * correctionFactor^3, 1e9);

        if useVoronoi

                if ~isfolder(savePath)
                    mkdir(savePath);
                end

            [validCells, Mean_neib_number, std_neib_number, Mean_Surface, std_Surface, ...
                Mean_Volume, std_Volume, Mean_neib_distance, std_neib_distance] = ...
                getVoronoiLayerData( ...
                    Svor.good_neighbours, Svor.neib_number, Svor.col, ...
                    validCentroids(targetCentroids, :), xyResolution, zResolution, ...
                    correctionFactor, imgSize, savePath, sprintf('Layer%d', nLayer), ...
                    filename, Svor.total_Distance_Neighbours_1, ...
                    Svor.total_Surface_Area_1, Svor.total_Volum_1, ...
                    Svor.vornb, excludedCellsForVoronoi, voronoiBoundaryMode);
        else
            [validCells, Mean_neib_number, std_neib_number, Mean_Surface, std_Surface, ...
                Mean_Volume, std_Volume, Mean_neib_distance, std_neib_distance] = deal(NaN);
        end

        volumeCol = sprintf('Layer%dVolume', nLayer);
        microgliaNCol = sprintf('Layer%dMicrogliaNumber', nLayer);
        microgliaDensityMm3Col = sprintf('Layer%dMicrogliaDensitymm3', nLayer);
        validMicrogliaCol = sprintf('Layer%dValidMicroglia', nLayer);
        meanVoronoiNeighsCol = sprintf('Layer%dMeanNeighs', nLayer);
        stdVoronoiNeighsCol = sprintf('Layer%dStdNeighs', nLayer);
        meanVoronoiSurfaceCol = sprintf('Layer%dMeanSurface', nLayer);
        stdVoronoiSurfaceCol = sprintf('Layer%dStdSurface', nLayer);
        meanVoronoiVolumeCol = sprintf('Layer%dMeanVolume', nLayer);
        stdVoronoiVolumeCol = sprintf('Layer%dStdVolume', nLayer);
        meanVoronoiDistNeighsCol = sprintf('Layer%dMeanDistNeighs', nLayer);
        stdVoronoiDistNeighsCol = sprintf('Layer%dStdDistNeighs', nLayer);

        tableLayersData.(volumeCol)(nSample) = validVolume_um3_uncorrected * correctionFactor^3;
        tableLayersData.(microgliaNCol)(nSample) = microgliaN;
        tableLayersData.(microgliaDensityMm3Col)(nSample) = microgliaDensity;

        tableLayersData.(validMicrogliaCol)(nSample) = validCells;
        tableLayersData.(meanVoronoiNeighsCol)(nSample) = Mean_neib_number;
        tableLayersData.(stdVoronoiNeighsCol)(nSample) = std_neib_number;
        tableLayersData.(meanVoronoiSurfaceCol)(nSample) = Mean_Surface;
        tableLayersData.(stdVoronoiSurfaceCol)(nSample) = std_Surface;
        tableLayersData.(meanVoronoiVolumeCol)(nSample) = Mean_Volume;
        tableLayersData.(stdVoronoiVolumeCol)(nSample) = std_Volume;
        tableLayersData.(meanVoronoiDistNeighsCol)(nSample) = Mean_neib_distance;
        tableLayersData.(stdVoronoiDistNeighsCol)(nSample) = std_neib_distance;
    end

end


%SUMMARIZEPLAQUESBYLAYER_OPTIMIZED Calculate plaque count, density, and volume metrics by layer.
function tableLayersData = summarizePlaquesByLayer_optimized( ...
    layerMapPlaques, imgPlaques, tableData, distance_um, excelRow, ...
    tableLayersData, nSample, isLateral)

    correctionFactor = tableData.Correction_Factor(excelRow);
    xyResolution = tableData.ResolucionXY_um_pxl(excelRow);
    zResolution = tableData.ResolucionZ_um_pxl(excelRow);
    voxelVolume_um3 = xyResolution * xyResolution * zResolution;

    distance_um = distance_um ./ correctionFactor;
    distance_pxl = round(distance_um ./ xyResolution);

    layerNumbers = getLayerNumbers(isLateral);

    stats = regionprops3(imgPlaques, {'Centroid', 'Volume'});

    if isempty(stats)
        plaquesVolume_vox = [];
        plaquesCentroids_xyz = zeros(0, 3);
    else
        validPlaqueRows = stats.Volume > 0;
        plaquesVolume_vox = stats.Volume(validPlaqueRows);
        plaquesCentroids_xyz = stats.Centroid(validPlaqueRows, :);
    end

    nPlaques = numel(plaquesVolume_vox);
    if nPlaques == 0
        plaqueLayer = zeros(0, 1, 'uint8');
    else
        px = clamp(round(plaquesCentroids_xyz(:,1)), 1, size(layerMapPlaques, 2));
        py = clamp(round(plaquesCentroids_xyz(:,2)), 1, size(layerMapPlaques, 1));
        pz = clamp(round(plaquesCentroids_xyz(:,3)), 1, size(layerMapPlaques, 3));

        plaquesLinearIdx = sub2ind(size(layerMapPlaques), py, px, pz);
        plaqueLayer = layerMapPlaques(plaquesLinearIdx);
    end

    allPlaqueVolumes_um3_uncorrected = plaquesVolume_vox * voxelVolume_um3;

    for nZ = 1:length(distance_pxl)

        nLayer = layerNumbers(nZ);

        validPlaques = plaqueLayer == nZ;
        plaquesN = sum(validPlaques);

        volumesPlaquesTarget_um3_uncorrected = allPlaqueVolumes_um3_uncorrected(validPlaques);

        validVolume_um3_uncorrected = nnz(layerMapPlaques == nZ) * voxelVolume_um3;
        plaquesDensity = safeDivide(plaquesN, validVolume_um3_uncorrected * correctionFactor^3, 1e9);

        volumeCol = sprintf('Layer%dVolume_Plaques', nLayer);
        plaquesNCol = sprintf('Layer%dPlaquesNumber', nLayer);
        plaquesDensityColmm3 = sprintf('Layer%dPlaquesDensitymm3', nLayer);
        meanPlaquesVolumeCol = sprintf('Layer%dMeanPlaquesVolume', nLayer);
        stdPlaquesVolumeCol = sprintf('Layer%dStdPlaquesVolume', nLayer);
        meanPlaquesVolumeRelativeCol = sprintf('Layer%dMeanPlaquesRelativeVolume', nLayer);

        tableLayersData.(volumeCol)(nSample) = validVolume_um3_uncorrected * correctionFactor^3;
        tableLayersData.(plaquesNCol)(nSample) = plaquesN;
        tableLayersData.(plaquesDensityColmm3)(nSample) = plaquesDensity;

        if isempty(volumesPlaquesTarget_um3_uncorrected)
            tableLayersData.(meanPlaquesVolumeCol)(nSample) = 0;
            tableLayersData.(stdPlaquesVolumeCol)(nSample) = 0;
            tableLayersData.(meanPlaquesVolumeRelativeCol)(nSample) = 0;
        else
            meanTargetVolume = mean(volumesPlaquesTarget_um3_uncorrected);
            meanTotalVolume = mean(allPlaqueVolumes_um3_uncorrected);

            tableLayersData.(meanPlaquesVolumeCol)(nSample) = meanTargetVolume;
            tableLayersData.(stdPlaquesVolumeCol)(nSample) = std(volumesPlaquesTarget_um3_uncorrected);
            tableLayersData.(meanPlaquesVolumeRelativeCol)(nSample) = safeDivide(meanTargetVolume, meanTotalVolume);
        end
    end

end


function T = fillMetadataColumns(T, nSample, tableData, excelRow, filename, cortexArea, modelName)
%FILLMETADATACOLUMNS Write image metadata into one layer-result row.

    T.File(nSample) = string(filename);
    T.CortexArea(nSample) = string(cortexArea);
    T.Mouse(nSample) = string(tableData.IDRaton(excelRow));
    T.Sex(nSample) = string(tableData.Sexo(excelRow));
    T.Section(nSample) = string(tableData.IDCorte(excelRow));
    T.Image(nSample) = string(tableData.IDImage(excelRow));
    T.Model(nSample) = string(modelName);
    T.BregmaLevel(nSample) = string(tableData.BregmaLevel(excelRow));

end


function R = initializeEmptyResultStruct()
%INITIALIZEEMPTYRESULTSTRUCT Create empty result tables for all model and region combinations.

    R = struct();

    R.WT_Medial = table();
    R.WT_Lateral = table();

    R.APP_Medial = table();
    R.APP_Lateral = table();

    R.APPNoPlaques_Medial = table();
    R.APPNoPlaques_Lateral = table();

    R.APPJustPlaques_Medial = table();
    R.APPJustPlaques_Lateral = table();

    R.Plaques_Medial = table();
    R.Plaques_Lateral = table();

end



function layerNumbers = getLayerNumbers(isLateral)
%GETLAYERNUMBERS Return output layer identifiers for medial or lateral cortex.

    if isLateral
        % Layer numbering follows the configured cortex-region mapping:
        % nZ=1 -> Layer1
        % nZ=2 -> Layer23
        % nZ=3 -> Layer4
        % nZ=4 -> Layer5
        layerNumbers = [1, 23, 4, 5];
    else
        % Layer numbering follows the configured cortex-region mapping:
        % nZ=1 -> Layer1
        % nZ=2 -> Layer23
        % nZ=3 -> Layer5
        % nZ=4 -> Layer6
        layerNumbers = [1, 23, 5, 6];
    end

end


function x = clamp(x, lowerBound, upperBound)
%CLAMP Restrict values to an inclusive lower and upper bound.

    x = max(lowerBound, min(upperBound, x));

end


function S = createEmptyVoronoiStruct_Layers()
%CREATEEMPTYVORONOISTRUCT_LAYERS Return empty Voronoi fields for non-Voronoi runs.
    S.good_neighbours = {};
    S.vornb = {};
    S.neib_number = [];
    S.col = [];
    S.total_Distance_Neighbours_1 = [];
    S.total_Surface_Area_1 = [];
    S.total_Volum_1 = [];
end

function value = extractVariableFromMatStruct(S, preferredName)
%EXTRACTVARIABLEFROMMATSTRUCT Read a preferred variable from a loaded MAT structure.

    if isfield(S, preferredName)
        value = S.(preferredName);
        return;
    end

    fields = fieldnames(S);

    if isempty(fields)
        error('The MAT file does not contain any variables.');
    end

    value = S.(fields{1});

end
