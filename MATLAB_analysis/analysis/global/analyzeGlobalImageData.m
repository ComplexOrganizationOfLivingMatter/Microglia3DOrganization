function analyzeGlobalImageData(pathImgMask, pathImgMicroglia, pathPlaques, pathDilatedPlaques, pathCentroids, voronoiPath, nameExcel, pathExcel, saveExcel, savePath, saveADNoPlaquesImages, saveADPlaquesImages, analysisConfig)
%% Optimized fast version of getDataLoop_function
%
% Inputs are compatible with the legacy global-analysis interface.
%
% Goal:
%   Optimize memory and speed WITHOUT changing how data are calculated.
%
% Calculations intentionally preserved:
%   VolumeTotal      = nnz(imgMask) * xyResolution * xyResolution * zResolution * correctionFactor^3
%   AnalyzedVolume      = nnz((imgMask & imgOrtho) & ~imgPlaque) * xyResolution * xyResolution * zResolution * correctionFactor^3
%   MicrogliaNumber  = number of original centroids falling inside targetZone
%   MicrogliaDensity = MicrogliaNumber / AnalyzedVolume * 1e9
%
% Important:
%   The original getDataFunction does not actually use the microglia label image
%   except for size(imgMicroglia). Therefore this version does not pass duplicated
%   APPNoPlaques / APPJustPlaques images into the calculation. It still writes
%   those images to disk when intermediate outputs are requested.
%
% Detected real issue in original code:
%   In the APP branch, imgPlaqueDil and imgPlaque are only loaded inside:
%       if isfile(pathDilatedPlaques...)
%   but are used unconditionally later. If a plaque file is missing, MATLAB may
%   error or, worse, reuse stale variables from a previous iteration depending on
%   workspace state. This version stops with an explicit error for APP images
%   missing plaque or dilated-plaque files.
%
% Supporting functions used by this module:
%   readStackTif
%   writeStackTif
%   prepareDataTable
%   prepareDataTable_Plaques
%   getPlaqueDataFunction
%   getVoronoiLayerData

    if nargin < 11 || isempty(saveADNoPlaquesImages), saveADNoPlaquesImages = false; end
    if nargin < 12 || isempty(saveADPlaquesImages), saveADPlaquesImages = false; end
    if nargin < 13 || isempty(analysisConfig), analysisConfig = createMicrogliaConfig(); end
    useVoronoi = analysisConfig.voronoi.enabled && analysisConfig.voronoi.contexts.global.enabled;

    if ~isfolder(savePath)
        mkdir(savePath);
    end

    tableData = readtable(fullfile(pathExcel, nameExcel));
    listFiles = tableData.Archivo;
    nFiles = numel(listFiles);

    modelList = string(tableData.Modelo);
    nImagesAPP = sum(contains(modelList, "APP"));
    nImagesWT = nFiles - nImagesAPP;

    tableSaveData_WT = prepareDataTable(table(), nImagesWT);
    tableSaveData_APP = prepareDataTable(table(), nImagesAPP);
    tableSaveData_APPJustPlaques = prepareDataTable(table(), nImagesAPP);
    tableSaveData_APPNoPlaques = prepareDataTable(table(), nImagesAPP);

    tablaSaveData_Plaques = prepareDataTable_Plaques(table(), nImagesAPP);

    fileListString = string(tableData.Archivo);

    for n_file = 1:nFiles

        filename = char(string(listFiles{n_file}));
        fprintf('Processing %d/%d: %s\n', n_file, nFiles, filename);

        excelRow = find(fileListString == string(filename), 1, 'first');

        if isempty(excelRow)
            warning('File %s was not found in Excel table. Skipping.', filename);
            continue;
        end

        cortexArea = char(string(tableData.Zona(excelRow)));
        modelType = char(string(tableData.Modelo(excelRow)));
        outputModelType = char(getOutputModelName(modelType, analysisConfig));

        maskFile = fullfile(pathImgMask, modelType, [filename, '.tif']);
        microgliaFile = fullfile(pathImgMicroglia, modelType, [filename, '.tif']);
        imgMask = logical(readStackTif(maskFile));
        imgMicroglia = readStackTif(microgliaFile);

        if useVoronoi
            centroidFile = fullfile(pathCentroids, [filename, '.mat']);
            voronoiFile = fullfile(voronoiPath, modelType, [filename, '.mat']);
            Scent = load(centroidFile);
            centroids = extractVariableFromMatStruct_DataLoop(Scent, 'centroids');
            Svor = load(voronoiFile, ...
                'good_neighbours', 'vornb', 'neib_number', 'col', ...
                'total_Distance_Neighbours_1', 'total_Surface_Area_1', ...
                'total_Volum_1');
        else
            centroids = extractInstanceCentroids(imgMicroglia);
            Svor = createEmptyVoronoiStruct();
        end

        if contains(modelType, 'APP')

            plaqueDilFile = fullfile(pathDilatedPlaques, [filename, '.tif']);
            plaqueFile = fullfile(pathPlaques, [filename, '.tif']);

            if ~isfile(plaqueDilFile) || ~isfile(plaqueFile)
                error(['APP image "%s" is missing plaque files. This would affect the calculation. ', ...
                       'Expected files:\n%s\n%s'], filename, plaqueDilFile, plaqueFile);
            end

            imgPlaqueDil = readStackTif(plaqueDilFile);
            imgPlaque = readStackTif(plaqueFile);

            nTabla = find(tableSaveData_APP.File == "", 1, 'first');

            % APP complete.
            % Original equivalent:
            %   imgPlaque = zeros(size(imgMask))
            % Here [] means no plaque exclusion inside getDataFunction_optimized_fast.
            tableSaveData_APP = getDataFunction_optimized_fast( ...
                imgMask, size(imgMicroglia), centroids, tableData, excelRow, ...
                tableSaveData_APP, nTabla, fullfile(savePath, outputModelType, cortexArea), ...
                Svor.good_neighbours, Svor.neib_number, Svor.vornb, Svor.col, filename, ...
                Svor.total_Distance_Neighbours_1, Svor.total_Surface_Area_1, Svor.total_Volum_1, ...
                [], 0, useVoronoi);

            tablaSaveData_Plaques = getPlaqueDataFunction( ...
                imgMask, imgPlaque, tableData, excelRow, tablaSaveData_Plaques, nTabla);

            tableSaveData_APP = fillMetadata_DataLoop( ...
                tableSaveData_APP, nTabla, tableData, excelRow, filename, cortexArea, string(outputModelType));

            % Identify labels touching the dilated plaque mask.
            plaqueMicrogliaLabels = unique(imgMicroglia(imgPlaqueDil > 0));

            % Create images for downstream compatibility, but do not use them for
            % calculation because getDataFunction only needs the image size.
            labelsInPlaqueMask = ismember(imgMicroglia, plaqueMicrogliaLabels);

            imgMicrogliaNoPlaques = imgMicroglia;
            imgMicrogliaNoPlaques(labelsInPlaqueMask) = 0;

            imgMicrogliaJustPlaques = imgMicroglia;
            imgMicrogliaJustPlaques(~labelsInPlaqueMask) = 0;

            noPlaqueImageFolder = char(analysisConfig.paths.derivedADNoPlaques);
            justPlaqueImageFolder = char(analysisConfig.paths.derivedADPlaques);

            if saveADNoPlaquesImages
                if ~isfolder(noPlaqueImageFolder), mkdir(noPlaqueImageFolder); end
                writeStackTif(castLabelImageForStorage(imgMicrogliaNoPlaques), fullfile(noPlaqueImageFolder, [filename, '.tif']));
            end
            if saveADPlaquesImages
                if ~isfolder(justPlaqueImageFolder), mkdir(justPlaqueImageFolder); end
                writeStackTif(castLabelImageForStorage(imgMicrogliaJustPlaques), fullfile(justPlaqueImageFolder, [filename, '.tif']));
            end

            clear imgMicrogliaNoPlaques imgMicrogliaJustPlaques labelsInPlaqueMask;

            % APPNoPlaques.
            % Original targetZone:
            %   (imgMask & imgOrtho) & ~imgPlaqueDil
            tableSaveData_APPNoPlaques = getDataFunction_optimized_fast( ...
                imgMask, size(imgMicroglia), centroids, tableData, excelRow, ...
                tableSaveData_APPNoPlaques, nTabla, fullfile(savePath, 'ADNoPlaques', cortexArea), ...
                Svor.good_neighbours, Svor.neib_number, Svor.vornb, Svor.col, filename, ...
                Svor.total_Distance_Neighbours_1, Svor.total_Surface_Area_1, Svor.total_Volum_1, ...
                imgPlaqueDil, plaqueMicrogliaLabels, useVoronoi);

            tableSaveData_APPNoPlaques = fillMetadata_DataLoop( ...
                tableSaveData_APPNoPlaques, nTabla, tableData, excelRow, filename, cortexArea, "ADNoPlaques");

            % APPJustPlaques.
            % Original call:
            %   getDataFunction(..., ~imgPlaqueDil, setdiff(unique(imgMicroglia), plaqueMicrogliaLabels))
            % Original targetZone:
            %   (imgMask & imgOrtho) & ~(~imgPlaqueDil)
            % which equals:
            %   (imgMask & imgOrtho) & imgPlaqueDil
            tableSaveData_APPJustPlaques = getDataFunction_optimized_fast( ...
                imgMask, size(imgMicroglia), centroids, tableData, excelRow, ...
                tableSaveData_APPJustPlaques, nTabla, fullfile(savePath, 'ADPlaques', cortexArea), ...
                Svor.good_neighbours, Svor.neib_number, Svor.vornb, Svor.col, filename, ...
                Svor.total_Distance_Neighbours_1, Svor.total_Surface_Area_1, Svor.total_Volum_1, ...
                ~logical(imgPlaqueDil), setdiff(unique(imgMicroglia), plaqueMicrogliaLabels), useVoronoi);

            tableSaveData_APPJustPlaques = fillMetadata_DataLoop( ...
                tableSaveData_APPJustPlaques, nTabla, tableData, excelRow, filename, cortexArea, "ADPlaques");

            clear imgPlaqueDil imgPlaque;

        else

            nTabla = find(tableSaveData_WT.File == "", 1, 'first');

            tableSaveData_WT = getDataFunction_optimized_fast( ...
                imgMask, size(imgMicroglia), centroids, tableData, excelRow, ...
                tableSaveData_WT, nTabla, fullfile(savePath, outputModelType, cortexArea), ...
                Svor.good_neighbours, Svor.neib_number, Svor.vornb, Svor.col, filename, ...
                Svor.total_Distance_Neighbours_1, Svor.total_Surface_Area_1, Svor.total_Volum_1, ...
                [], 0, useVoronoi);

            tableSaveData_WT = fillMetadata_DataLoop( ...
                tableSaveData_WT, nTabla, tableData, excelRow, filename, cortexArea, string(outputModelType));

        end

        clear imgMask imgMicroglia centroids Svor;
    end

    excelFile = fullfile(savePath, saveExcel);

    tableSaveData_APP = [tableSaveData_APP, tablaSaveData_Plaques];
    tableSaveData_APPNoPlaques = [tableSaveData_APPNoPlaques, tablaSaveData_Plaques];
    tableSaveData_APPJustPlaques = [tableSaveData_APPJustPlaques, tablaSaveData_Plaques];

    if ~useVoronoi
        voronoiColumns = ["ValidMicroglia", "MeanNeighs", "StdNeighs", "MeanSurface", ...
            "StdSurface", "MeanVolume", "StdVolume", "MeanDistNeighs", "StdDistNeighs"];
        tableSaveData_WT = removeExistingColumns(tableSaveData_WT, voronoiColumns);
        tableSaveData_APP = removeExistingColumns(tableSaveData_APP, voronoiColumns);
        tableSaveData_APPNoPlaques = removeExistingColumns(tableSaveData_APPNoPlaques, voronoiColumns);
        tableSaveData_APPJustPlaques = removeExistingColumns(tableSaveData_APPJustPlaques, voronoiColumns);
    end

    tableSaveData_WT = standardizeOutputTable(tableSaveData_WT, "global");
    tableSaveData_APP = standardizeOutputTable(tableSaveData_APP, "global");
    tableSaveData_APPNoPlaques = standardizeOutputTable(tableSaveData_APPNoPlaques, "global");
    tableSaveData_APPJustPlaques = standardizeOutputTable(tableSaveData_APPJustPlaques, "global");

    writetable(tableSaveData_WT, excelFile, 'Sheet', 'WT');
    writetable(tableSaveData_APP, excelFile, 'Sheet', 'AD');
    writetable(tableSaveData_APPNoPlaques, excelFile, 'Sheet', 'ADNoPlaques');
    writetable(tableSaveData_APPJustPlaques, excelFile, 'Sheet', 'ADPlaques');

end


%GETDATAFUNCTION_OPTIMIZED_FAST Calculate image-level volume, density, and optional Voronoi summaries.
function tableResultsData = getDataFunction_optimized_fast( ...
    imgMask, imgSize, centroids, tableData, excelRow, tableResultsData, ...
    nSample, savePath, good_neighbours, neib_number, vornb, col, filename, ...
    total_Distance_Neighbours_1, total_Surface_Area_1, total_Volum_1, ...
    imgPlaque, plaqueMicrogliaCells, useVoronoi)

    if ~isfolder(savePath)
        mkdir(savePath);
    end

    desire_pxls = [ ...
        tableData.XCorte2_pxl(excelRow), ...
        tableData.Ycorte_pxl(excelRow), ...
        tableData.Zcorte_pxl(excelRow)];

    start = [ ...
        tableData.CoordXCorte2_pxl(excelRow) + 1, ...
        tableData.CoordYCorte_pxl(excelRow) + 1, ...
        tableData.CoordZCorte_pxl(excelRow) + 1];

    correctionFactor = tableData.Correction_Factor(excelRow);

    xyResolution = tableData.ResolucionXY_um_pxl(excelRow);
    zResolution = tableData.ResolucionZ_um_pxl(excelRow);

    % Preserve original inclusive limits.
    x1 = start(1);
    y1 = start(2);
    z1 = start(3);

    x2 = start(1) + desire_pxls(1);
    y2 = start(2) + desire_pxls(2);
    z2 = start(3) + desire_pxls(3);

    % Same centroid filter as original.
    validCentroids = centroids( ...
        centroids(:,1) <= x2 & centroids(:,1) >= x1 & ...
        centroids(:,2) <= y2 & centroids(:,2) >= y1 & ...
        centroids(:,3) <= z2 & centroids(:,3) >= z1, :);

    if isempty(validCentroids)
        validCentroidsInd = [];
    else
        validCentroidsInd = sub2ind(imgSize, ...
            uint32(validCentroids(:,2)), ...
            uint32(validCentroids(:,1)), ...
            uint32(validCentroids(:,3)));
    end

    % Equivalent to original:
    %
    %   imgOrtho = false(size(imgMicroglia));
    %   imgOrtho(y1:y2, x1:x2, z1:z2) = true;
    %   targetZone = (imgMask & imgOrtho) & ~imgPlaque;
    %
    % but without creating imgOrtho.

    targetZone = false(imgSize);

    if isempty(imgPlaque)
        targetZone(y1:y2, x1:x2, z1:z2) = imgMask(y1:y2, x1:x2, z1:z2);
    else
        targetZone(y1:y2, x1:x2, z1:z2) = ...
            imgMask(y1:y2, x1:x2, z1:z2) & ~logical(imgPlaque(y1:y2, x1:x2, z1:z2));
    end

    validVolumeTotal = nnz(targetZone);
    validVolumeTotal = validVolumeTotal * xyResolution * xyResolution * zResolution;

    % Direct indexing. Same result as original arrayfun.
    if isempty(validCentroidsInd)
        targetCentroids = false(0, 1);
    else
        targetCentroids = targetZone(validCentroidsInd);
    end

    microgliaDensityTotal = sum(targetCentroids) / (validVolumeTotal * correctionFactor^3);

    if useVoronoi
        [validCells, Mean_neib_number, std_neib_number, Mean_Surface, std_Surface, ...
            Mean_Volume, std_Volume, Mean_neib_distance, std_neib_distance] = ...
            getVoronoiLayerData( ...
                good_neighbours, neib_number, col, validCentroids(targetCentroids, :), ...
                xyResolution, zResolution, correctionFactor, imgSize, savePath, ...
                'CompleteImage', filename, total_Distance_Neighbours_1, ...
                total_Surface_Area_1, total_Volum_1, vornb, plaqueMicrogliaCells, "exclude");
    else
        [validCells, Mean_neib_number, std_neib_number, Mean_Surface, std_Surface, ...
            Mean_Volume, std_Volume, Mean_neib_distance, std_neib_distance] = deal(NaN);
    end

    % Formulas preserved from original.
    tableResultsData.VolumeTotal(nSample) = nnz(imgMask) * xyResolution * xyResolution * zResolution * correctionFactor^3;
    tableResultsData.AnalyzedVolume(nSample) = validVolumeTotal * correctionFactor^3;
    tableResultsData.MicrogliaNumber(nSample) = sum(targetCentroids);
    tableResultsData.MicrogliaDensity(nSample) = microgliaDensityTotal * 1000000000;

    tableResultsData.ValidMicroglia(nSample) = validCells;
    tableResultsData.MeanNeighs(nSample) = Mean_neib_number;
    tableResultsData.StdNeighs(nSample) = std_neib_number;
    tableResultsData.MeanSurface(nSample) = Mean_Surface;
    tableResultsData.StdSurface(nSample) = std_Surface;
    tableResultsData.MeanVolume(nSample) = Mean_Volume;
    tableResultsData.StdVolume(nSample) = std_Volume;
    tableResultsData.MeanDistNeighs(nSample) = Mean_neib_distance;
    tableResultsData.StdDistNeighs(nSample) = std_neib_distance;

end


function T = fillMetadata_DataLoop(T, nSample, tableData, excelRow, filename, cortexArea, modelName)
%FILLMETADATA_DATALOOP Write image metadata into one global-result row.

    T.File(nSample) = string(filename);
    T.CortexArea(nSample) = string(cortexArea);
    T.Mouse(nSample) = string(tableData.IDRaton(excelRow));
    T.Sex(nSample) = string(tableData.Sexo(excelRow));
    T.Section(nSample) = string(tableData.IDCorte(excelRow));
    T.Image(nSample) = string(tableData.IDImage(excelRow));
    T.Model(nSample) = string(modelName);
    T.BregmaLevel(nSample) = string(tableData.BregmaLevel(excelRow));

end


function S = createEmptyVoronoiStruct()
%CREATEEMPTYVORONOISTRUCT Return empty fields used when Voronoi is disabled.
    S.good_neighbours = {};
    S.vornb = {};
    S.neib_number = [];
    S.col = [];
    S.total_Distance_Neighbours_1 = [];
    S.total_Surface_Area_1 = [];
    S.total_Volum_1 = [];
end

function T = removeExistingColumns(T, names)
%REMOVEEXISTINGCOLUMNS Remove listed variables when they exist in a table.
    present = names(ismember(names, string(T.Properties.VariableNames)));
    if ~isempty(present)
        T = removevars(T, cellstr(present));
    end
end

function value = extractVariableFromMatStruct_DataLoop(S, preferredName)
%EXTRACTVARIABLEFROMMATSTRUCT_DATALOOP Read a preferred variable from a loaded MAT structure.

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
