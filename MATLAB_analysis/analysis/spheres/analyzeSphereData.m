function analyzeSphereData(plaquePath, pathDilatedPlaques, maskPath, microgliaPath, voronoiCentroidPath, voronoiPath, nameExcel, pathExcel, savePath, saveExcel, radiusPairs_um, analysisConfig)
%% Optimized and corrected version of the sphere-data script
%
% Inputs:
%   plaquePath          Path to plaque instance segmentation TIFFs
%   pathDilatedPlaques  Path to dilated plaque instance segmentation TIFFs
%   maskPath            Path to tissue/microglia mask TIFFs
%   microgliaPath       Path to microglia instance segmentation TIFFs
%   voronoiPath         Path to Voronoi MAT files
%   nameExcel           Excel file name with metadata
%   pathExcel           Folder containing the Excel file
%   savePath            Base folder containing the sphere masks/indices and where outputs are saved
%   saveExcel           Base name used for output Excel files
%
% Supporting functions used by this module:
%   readStackTif
%   prepareIndividualPlaqueSphereDataTable
%   prepareIndividualNonPlaqueSphereDataTable
%   prepareIndividualWTSphereDataTable
%   prepareSphere_PlaqueDataTable
%   prepareGlobalSphereDataTable
%   prepareJoinSphereDataTable
%   getVoronoiSphereData
%   getRadioAndCenterNormalization
%   getRadialDistribution
%   getAngularDistribution
%   getRipleyK3
%   getCorrelationFunctionG
%   randomDirectionNull
%   depthSuperfMetrics
%   computeDirectionalBiasSphere
%
% Corrections applied compared with the pasted script/functions:
%   1) radius_plaqueSpheres is scalar, so radiusPxl uses radius_plaqueSpheres,
%      not radius_plaqueSpheres(r).
%   2) WT images get plaqueDilImg = zeros(size(microgliaImg)), avoiding undefined variable.
%   3) tablePlaqueIndSpheres/tableIndPlaqueSpheres name mismatch fixed.
%   4) Final writetable uses tableJoinSpheres_WT and tableJoinSpheres_APP.
%   5) Output tables are reinitialized for each radius, avoiding carry-over between radii.
%   6) plaqueImg / plaqueDilImg undefined variables inside getPlaqueSphereData fixed.
%   7) volPlaquesDil is not cleared inside the plaque loop.
%   8) MicrogliaDistToNearest_Std uses std(), not mean().
%   9) Global Microglia_Density_Plaque uses microglia inside plaque volume,
%      not number of plaques.
%  10) IQR_Vol_Plaques_Valid uses Q75(valid) - Q25(valid).
%  11) Individual non-plaque / WT MicrogliaDensity is reported per mm3
%      consistently with plaque spheres.


    if nargin < 12 || isempty(analysisConfig)
        analysisConfig = createMicrogliaConfig();
    end
    metricFlags.voronoi = analysisConfig.voronoi.enabled && analysisConfig.voronoi.contexts.spheres.enabled;
    metricFlags.distances = isMetricGroupEnabled(analysisConfig, "distances");
    metricFlags.radial = isMetricGroupEnabled(analysisConfig, "radial");
    metricFlags.spatialStatistics = isMetricGroupEnabled(analysisConfig, "spatialStatistics");
    metricFlags.directional = isMetricGroupEnabled(analysisConfig, "directional");
    metricFlags.voronoiTypeData = getVoronoiTypeData(analysisConfig.voronoi.boundaryMode);

    if ~isfolder(savePath)
        mkdir(savePath);
    end

    tableInfo = readtable(fullfile(pathExcel, nameExcel));
    listFiles = tableInfo.Archivo;
    nImages = length(listFiles);
    isADImage = contains(string(tableInfo.Modelo), 'APP');
    nADImages = sum(isADImage);
    nWTImages = nImages - nADImages;

    distanceMedial_um = [105, 175, 295, 340];
    distanceLateral_um = [135, 230, 130, 340];

    if nargin < 11 || isempty(radiusPairs_um), radiusPairs_um = [100 50; 100 100]; end
    radiusPairs_um = double(radiusPairs_um);

    sizeReduction = 1;

    if nargin < 10 || isempty(saveExcel)
        saveExcel = "SpheresData";
    end

    [~, saveExcelBase, ~] = fileparts(char(saveExcel));
    if isempty(saveExcelBase)
        saveExcelBase = "SpheresData";
    end

    % Hide figures during batch processing to prevent graphics-handle accumulation.
    % This reduces memory pressure during long runs with many spatial plots.
    oldFigureVisible = get(groot, 'DefaultFigureVisible');
    set(groot, 'DefaultFigureVisible', 'off');
    cleanupFigureVisibility = onCleanup(@() set(groot, 'DefaultFigureVisible', oldFigureVisible)); %#ok<NASGU>

    sphereLogPath = fullfile(char(analysisConfig.paths.logs), 'Spheres');
    if ~isfolder(sphereLogPath), mkdir(sphereLogPath); end
    logFile = fullfile(sphereLogPath, sprintf('%s_safe_log.txt', saveExcelBase));

    for r = 1:size(radiusPairs_um,1)

        radiusPlaqueCurrent = radiusPairs_um(r,1);
        radiusCurrent = radiusPairs_um(r,2);

        radiusFolderName = sprintf('PlaqueRadius%d_NonPlaqueRadius%d', radiusPlaqueCurrent, radiusCurrent);
        saveDataPathR = fullfile(savePath, radiusFolderName);
        sphereDerivedPathR = fullfile(char(analysisConfig.paths.derivedSpheres), radiusFolderName);
        if ~isfolder(saveDataPathR)
            mkdir(saveDataPathR);
        end
        if analysisConfig.spheres.mode == "existing"
            if numel(analysisConfig.paths.existingSphereFolders) < r
                error('No existing sphere folder was configured for radius pair %d.', r);
            end
            sphereDataInputPathR = char(analysisConfig.paths.existingSphereFolders(r));
            sphereImageInputPathR = fullfile(sphereDataInputPathR, 'Images');
        else
            sphereDataInputPathR = saveDataPathR;
            sphereImageInputPathR = sphereDerivedPathR;
        end

        plaqueSpheresIndPath = fullfile(sphereDataInputPathR, 'SpheresInd', 'PlaqueSpheresInd');
        nonPlaqueSpheresIndPath = fullfile(sphereDataInputPathR, 'SpheresInd', 'NonPlaqueSpheresInd');
        wtSpheresIndPath = fullfile(sphereDataInputPathR, 'SpheresInd', 'WTSpheresInd');

        %% Reinitialize tables for each radius

        tablePlaqueIndSpheres = prepareIndividualPlaqueSphereDataTable(table(), 1);
        tableIndNonPlaqueSpheres = prepareIndividualNonPlaqueSphereDataTable(table(), 1);
        tableIndWTSpheres = prepareIndividualWTSphereDataTable(table(), 1);
        tableSphere_Plaque = prepareSphere_PlaqueDataTable(table(), 1);

        tableGlobalSpheres = prepareGlobalSphereDataTable(table(), nImages);
        tableJoinSpheres_WT = prepareJoinSphereDataTable(table(), max(nWTImages,1), 'WT');
        tableJoinSpheres_APP = prepareJoinSphereDataTable(table(), max(nADImages,1), 'AD');
        wtRow = 0;
        adRow = 0;

        for n_file = 1:nImages

            tic

            try

            name = char(string(listFiles{n_file}));
            filename = [name, '.tif'];

            fprintf('Radius %d | Processing %d/%d: %s\n', radiusCurrent, n_file, nImages, name);

            excelRow = find(string(tableInfo.Archivo) == string(name), 1, 'first');

            if isempty(excelRow)
                warning('File %s was not found in Excel table. Skipping.', name);
                continue;
            end

            correctionFactor = tableInfo.Correction_Factor(excelRow);
            cortexArea = char(string(tableInfo.Zona(excelRow)));
            typeModel = char(string(tableInfo.Modelo(excelRow)));
            outputModel = char(getOutputModelName(typeModel, analysisConfig));

            if contains(cortexArea, 'Medial')
                distanceLayers = cumsum(distanceMedial_um);
            else
                distanceLayers = cumsum(distanceLateral_um);
            end

            imageData = { ...
                string(name), ...
                string(tableInfo.IDRaton(excelRow)), ...
                string(tableInfo.Sexo(excelRow)), ...
                string(tableInfo.IDCorte(excelRow)), ...
                string(tableInfo.IDImage(excelRow)), ...
                string(outputModel), ...
                string(tableInfo.BregmaLevel(excelRow)), ...
                string(cortexArea), ...
                getLayerInformationAvailability(tableInfo, excelRow), ...
                string(analysisConfig.layers.noInformationLabel)};

            tableGlobalSpheres = fillGlobalImageMetadata(tableGlobalSpheres, excelRow, imageData);
            if contains(typeModel, 'APP')
                adRow = adRow + 1;
                joinRow = adRow;
                tableJoinSpheres_APP = fillJoinImageMetadata(tableJoinSpheres_APP, joinRow, imageData);
            else
                wtRow = wtRow + 1;
                joinRow = wtRow;
                tableJoinSpheres_WT = fillJoinImageMetadata(tableJoinSpheres_WT, joinRow, imageData);
            end

            %% Load images and Voronoi

            sphereImg = readStackTif(fullfile(sphereImageInputPathR, outputModel, filename));
            microgliaImg = readStackTif(fullfile(microgliaPath, typeModel, filename));
            maskImg = logical(readStackTif(fullfile(maskPath, typeModel, filename)));

            if metricFlags.voronoi
                Svor = load(fullfile(voronoiPath, typeModel, [name, '.mat']), ...
                    'good_neighbours', 'vornb', 'neib_number', 'col');
                Scent = load(fullfile(voronoiCentroidPath, [name, '.mat']));
                voronoiCentroidsXYZ = extractMatVariable(Scent, {'centroids', 'Centroids'});
            else
                Svor.good_neighbours = {};
                Svor.vornb = {};
                Svor.neib_number = [];
                Svor.col = [];
                voronoiCentroidsXYZ = zeros(0, 3);
            end

            if isfile(fullfile(plaquePath, filename))
                plaqueImg = readStackTif(fullfile(plaquePath, filename));
                plaqueDilImg = readStackTif(fullfile(pathDilatedPlaques, filename));

                SplaqueInd = load(fullfile(plaqueSpheresIndPath, [name, '_ind.mat']));
                plaqueSpheresInd = extractMatVariable(SplaqueInd, {'plaqueSpheresInd', 'spheresInd'});

                SnpInd = load(fullfile(nonPlaqueSpheresIndPath, [name, '_ind.mat']));
                noPlaqueSpheresInd = extractMatVariable(SnpInd, {'noPlaqueSpheresInd', 'nonPlaqueSpheresInd', 'spheresInd'});

                SnpCent = load(fullfile(nonPlaqueSpheresIndPath, [name, '_centroids.mat']));
                noPlaquesSphereCentroids = extractMatVariable(SnpCent, {'noPlaquesSphereCentroids', 'nonPlaqueSphereCentroids', 'sphereCentroids', 'centroids'});
            else
                plaqueImg = zeros(size(microgliaImg), 'like', microgliaImg);
                plaqueDilImg = zeros(size(microgliaImg), 'like', microgliaImg);

                SwtInd = load(fullfile(wtSpheresIndPath, [name, '_ind.mat']));
                noPlaqueSpheresInd = extractMatVariable(SwtInd, {'noPlaqueSpheresInd', 'wtSpheresInd', 'spheresInd'});

                SwtCent = load(fullfile(wtSpheresIndPath, [name, '_centroids.mat']));
                noPlaquesSphereCentroids = extractMatVariable(SwtCent, {'noPlaquesSphereCentroids', 'wtSphereCentroids', 'sphereCentroids', 'centroids'});

                plaqueSpheresInd = {};
            end

            %% Crop mask

            desire_pxls = [ ...
                tableInfo.XCorte2_pxl(excelRow), ...
                tableInfo.Ycorte_pxl(excelRow), ...
                tableInfo.Zcorte_pxl(excelRow)];

            start = [ ...
                tableInfo.CoordXCorte2_pxl(excelRow) + 1, ...
                tableInfo.CoordYCorte_pxl(excelRow) + 1, ...
                tableInfo.CoordZCorte_pxl(excelRow) + 1];

            imgOrtho = false(size(plaqueImg));
            imgOrtho(start(2):(start(2) + desire_pxls(2)), ...
                     start(1):(start(1) + desire_pxls(1)), ...
                     start(3):(start(3) + desire_pxls(3))) = true;

            %% Resolution and volume

            shape = size(plaqueImg);
            xyResolution = tableInfo.ResolucionXY_um_pxl(excelRow);
            zResolution = tableInfo.ResolucionZ_um_pxl(excelRow);

            volumeTotal = nnz(maskImg) * correctionFactor^3 * xyResolution^2 * zResolution;

            maskImg = maskImg & imgOrtho;
            clear imgOrtho;

            desire_pxls = desire_pxls / sizeReduction;
            start = start / sizeReduction;
            desire_pxls(3) = desire_pxls(3) * (zResolution / xyResolution);

            %% Make isotropic/homogeneous

            % Preserve compact integer types before nearest-neighbor resampling.
            sphereImg = uint16(sphereImg);
            plaqueImg = uint16(plaqueImg);
            plaqueDilImg = uint16(plaqueDilImg);
            microgliaImg = uint16(microgliaImg);
            maskImg = logical(maskImg);

            numRows = round(shape(1) / sizeReduction);
            numCols = round(shape(2) / sizeReduction);
            numSlices = round(shape(3) * (zResolution / xyResolution) / sizeReduction);

            sphereImg = uint16(imresize3(sphereImg, [numRows, numCols, numSlices], 'nearest'));
            plaqueImg = uint16(imresize3(plaqueImg, [numRows, numCols, numSlices], 'nearest'));
            plaqueDilImg = uint16(imresize3(plaqueDilImg, [numRows, numCols, numSlices], 'nearest'));
            maskImg = logical(imresize3(maskImg, [numRows, numCols, numSlices], 'nearest'));
            microgliaImg = uint16(imresize3(microgliaImg, [numRows, numCols, numSlices], 'nearest'));

            xyResolution = xyResolution * sizeReduction;

            %% Radius in pixels

            radiusNonPlaquePxl = radiusCurrent / (xyResolution * correctionFactor);
            radiusPlaquePxl = radiusPlaqueCurrent / (xyResolution * correctionFactor);

            if metricFlags.voronoi
                good_neighbours = cellfun(@(gN) gN / xyResolution, Svor.good_neighbours, 'UniformOutput', false);
            else
                good_neighbours = {};
            end

            %% Microglia centroids

            if metricFlags.voronoi
                voronoiCentroidsXYZ(:, 1:2) = voronoiCentroidsXYZ(:, 1:2) / sizeReduction;
                voronoiCentroidsXYZ(:, 3) = voronoiCentroidsXYZ(:, 3) * ...
                    (zResolution / xyResolution) / sizeReduction;
                centroidsMicrogliaT = voronoiCentroidsXYZ(:, [2 1 3]);
                centroidsMicrogliaT(any(~isfinite(centroidsMicrogliaT), 2), :) = [];
                clear microgliaImg voronoiCentroidsXYZ;
            else
                centroidTable = regionprops3(microgliaImg, 'Centroid');
                clear microgliaImg;
                if isempty(centroidTable)
                    centroidsMicrogliaT = zeros(0, 3);
                else
                    centroidsMicrogliaT = centroidTable.Centroid;
                    centroidsMicrogliaT(:, [1 2]) = centroidsMicrogliaT(:, [2 1]);
                    centroidsMicrogliaT(any(~isfinite(centroidsMicrogliaT), 2), :) = [];
                end
            end

            centroidsMicroglia = centroidsMicrogliaT( ...
                centroidsMicrogliaT(:,1) <= (start(2) + desire_pxls(2)) & centroidsMicrogliaT(:,1) >= start(2) & ...
                centroidsMicrogliaT(:,2) <= (start(1) + desire_pxls(1)) & centroidsMicrogliaT(:,2) >= start(1) & ...
                centroidsMicrogliaT(:,3) <= (start(3) * (zResolution / xyResolution) + desire_pxls(3)) & ...
                centroidsMicrogliaT(:,3) >= start(3) * (zResolution / xyResolution), :);

            nValidPlaques = unique(plaqueImg(maskImg > 0));
            nValidPlaques(nValidPlaques == 0) = [];

            %% Global and individual data

            if contains(typeModel, 'APP')

                [tableGlobalSpheres, tableJoinSpheres_APP] = getSpheresGlobalData_optimized_corrected( ...
                    tableGlobalSpheres, tableJoinSpheres_APP, plaqueImg, sphereImg, ...
                    noPlaquesSphereCentroids, correctionFactor, xyResolution, ...
                    centroidsMicroglia, maskImg, volumeTotal, excelRow, joinRow, typeModel);

                if ~isempty(plaqueSpheresInd)
                    [tablePlaqueIndSpheres, nSpheresCompleted] = getPlaqueSphereData_optimized_corrected( ...
                        tablePlaqueIndSpheres, plaqueImg, plaqueDilImg, plaqueSpheresInd, ...
                        name, correctionFactor, xyResolution, centroidsMicroglia, radiusPlaquePxl, ...
                        maskImg, good_neighbours, Svor.neib_number, Svor.vornb, saveDataPathR, ...
                        nValidPlaques, Svor.col, centroidsMicrogliaT, imageData, distanceLayers, metricFlags);
                else
                    nSpheresCompleted = 0;
                end

                tableGlobalSpheres.N_Completed_Plaque_Spheres(excelRow) = nSpheresCompleted;

                [tableIndNonPlaqueSpheres, tableSphere_Plaque] = getNoPlaqueSphereData_optimized_corrected( ...
                    tableIndNonPlaqueSpheres, tableSphere_Plaque, plaqueImg, noPlaqueSpheresInd, ...
                    name, correctionFactor, xyResolution, centroidsMicroglia, radiusNonPlaquePxl, ...
                    maskImg, good_neighbours, Svor.neib_number, Svor.vornb, saveDataPathR, ...
                    Svor.col, centroidsMicrogliaT, imageData, distanceLayers, metricFlags);

                if metricFlags.voronoi
                    tableJoinSpheres_APP = getJointData(tableJoinSpheres_APP, ...
                        char(metricFlags.voronoiTypeData), saveDataPathR, joinRow, name);
                end

            else

                [tableGlobalSpheres, tableJoinSpheres_WT] = getSpheresGlobalData_optimized_corrected( ...
                    tableGlobalSpheres, tableJoinSpheres_WT, plaqueImg, sphereImg, ...
                    noPlaquesSphereCentroids, correctionFactor, xyResolution, ...
                    centroidsMicroglia, maskImg, volumeTotal, excelRow, joinRow, typeModel);

                [tableIndWTSpheres, tableSphere_Plaque] = getNoPlaqueSphereData_optimized_corrected( ...
                    tableIndWTSpheres, tableSphere_Plaque, plaqueImg, noPlaqueSpheresInd, ...
                    name, correctionFactor, xyResolution, centroidsMicroglia, radiusNonPlaquePxl, ...
                    maskImg, good_neighbours, Svor.neib_number, Svor.vornb, saveDataPathR, ...
                    Svor.col, centroidsMicrogliaT, imageData, distanceLayers, metricFlags);

                if metricFlags.voronoi
                    tableJoinSpheres_WT = getJointData(tableJoinSpheres_WT, ...
                        char(metricFlags.voronoiTypeData), saveDataPathR, joinRow, name);
                end
            end

            clear plaqueImg plaqueDilImg maskImg sphereImg;
            clear centroidsMicroglia centroidsMicrogliaT noPlaqueSpheresInd noPlaquesSphereCentroids;
            clear Svor good_neighbours;

            closeFiguresSafely();



            catch ME

                closeFiguresSafely();
                warning('Error processing image %d/%d. Continuing with next image. Message: %s', n_file, nImages, ME.message);

                try
                    fid = fopen(logFile, 'a');
                    fprintf(fid, '\n[%s] Radius %d | image %d/%d\n', datestr(now), radiusCurrent, n_file, nImages);
                    if exist('name', 'var')
                        fprintf(fid, 'File: %s\n', name);
                    end
                    fprintf(fid, 'Error: %s\n', ME.message);
                    fprintf(fid, '%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
                    fclose(fid);
                catch
                end

                try

                catch
                end

            end

            toc
        end

        tablePlaqueIndSpheres = trimUnusedRows(tablePlaqueIndSpheres);
        tableIndNonPlaqueSpheres = trimUnusedRows(tableIndNonPlaqueSpheres);
        tableIndWTSpheres = trimUnusedRows(tableIndWTSpheres);
        tableSphere_Plaque = trimUnusedRows(tableSphere_Plaque);
        if nWTImages == 0, tableJoinSpheres_WT = tableJoinSpheres_WT([],:); else, tableJoinSpheres_WT = tableJoinSpheres_WT(1:wtRow,:); end
        if nADImages == 0, tableJoinSpheres_APP = tableJoinSpheres_APP([],:); else, tableJoinSpheres_APP = tableJoinSpheres_APP(1:adRow,:); end

        %% Save outputs for this radius

        excelGlobal = fullfile(saveDataPathR, sprintf('%s_Global_r%d.xlsx', saveExcelBase, radiusCurrent));
        excelSpheres = fullfile(saveDataPathR, sprintf('%s_IndividualSpheres_r%d.xlsx', saveExcelBase, radiusCurrent));
        excelJoin = fullfile(saveDataPathR, sprintf('%s_CombinedSphereSummary_r%d.xlsx', saveExcelBase, radiusCurrent));

        if ~metricFlags.voronoi
            tableIndWTSpheres = removeColumnsByPattern(tableIndWTSpheres, ["Voronoi"]);
            tableIndNonPlaqueSpheres = removeColumnsByPattern(tableIndNonPlaqueSpheres, ["Voronoi"]);
            tablePlaqueIndSpheres = removeColumnsByPattern(tablePlaqueIndSpheres, ["Voronoi"]);
            tableJoinSpheres_WT = removeColumnsByPattern(tableJoinSpheres_WT, ["Voronoi"]);
            tableJoinSpheres_APP = removeColumnsByPattern(tableJoinSpheres_APP, ["Voronoi"]);
        end
        if ~metricFlags.distances
            tableIndWTSpheres = removeColumnsByPattern(tableIndWTSpheres, ["MicrogliaDist"]);
            tableIndNonPlaqueSpheres = removeColumnsByPattern(tableIndNonPlaqueSpheres, ["MicrogliaDist"]);
            tablePlaqueIndSpheres = removeColumnsByPattern(tablePlaqueIndSpheres, ["MicrogliaDist"]);
        end
        if ~metricFlags.radial
            radialPatterns = ["Radial", "CentralThirdMicrogliaFraction"];
            tableIndWTSpheres = removeColumnsByPattern(tableIndWTSpheres, radialPatterns);
            tableIndNonPlaqueSpheres = removeColumnsByPattern(tableIndNonPlaqueSpheres, radialPatterns);
            tablePlaqueIndSpheres = removeColumnsByPattern(tablePlaqueIndSpheres, radialPatterns);
        end
        if ~metricFlags.spatialStatistics
            spatialPatterns = ["DeviationAreaK3", "DeviationAreaG", "gMax", "gMin", "distanceG"];
            tableIndWTSpheres = removeColumnsByPattern(tableIndWTSpheres, spatialPatterns);
            tableIndNonPlaqueSpheres = removeColumnsByPattern(tableIndNonPlaqueSpheres, spatialPatterns);
            tablePlaqueIndSpheres = removeColumnsByPattern(tablePlaqueIndSpheres, spatialPatterns);
        end
        if ~metricFlags.directional
            directionalPatterns = ["Pol_", "Align_", "meanCos", "Displacement", "u_", "Angle", "plaqueDir"];
            tableIndWTSpheres = removeColumnsByPattern(tableIndWTSpheres, directionalPatterns);
            tableIndNonPlaqueSpheres = removeColumnsByPattern(tableIndNonPlaqueSpheres, directionalPatterns);
            tableSphere_Plaque = removeColumnsByPattern(tableSphere_Plaque, directionalPatterns);
        end

        tableGlobalSpheres = standardizeOutputTable(tableGlobalSpheres, "spheres");
        tableIndWTSpheres = standardizeOutputTable(tableIndWTSpheres, "spheres");
        tableIndNonPlaqueSpheres = standardizeOutputTable(tableIndNonPlaqueSpheres, "spheres");
        tablePlaqueIndSpheres = standardizeOutputTable(tablePlaqueIndSpheres, "spheres");
        tableSphere_Plaque = standardizeOutputTable(tableSphere_Plaque, "spheres");
        tableJoinSpheres_WT = standardizeOutputTable(tableJoinSpheres_WT, "spheres");
        tableJoinSpheres_APP = standardizeOutputTable(tableJoinSpheres_APP, "spheres");


        tableIndWTSpheres = reorderSphereIdentifierColumns(tableIndWTSpheres);
        tableIndNonPlaqueSpheres = reorderSphereIdentifierColumns(tableIndNonPlaqueSpheres);
        tablePlaqueIndSpheres = reorderSphereIdentifierColumns(tablePlaqueIndSpheres);
        tableSphere_Plaque = reorderSphereRelationIdentifierColumns(tableSphere_Plaque);

        writetable(tableGlobalSpheres, excelGlobal);

        writetable(tableIndWTSpheres, excelSpheres, 'Sheet', 'WTSpheres');
        writetable(tableIndNonPlaqueSpheres, excelSpheres, 'Sheet', 'NonPlaqueSpheres');
        writetable(tablePlaqueIndSpheres, excelSpheres, 'Sheet', 'PlaqueSpheres');
        writetable(tableSphere_Plaque, excelSpheres, 'Sheet', 'SpherePlaqueRelation');

        writetable(tableJoinSpheres_WT, excelJoin, 'Sheet', 'WT');
        writetable(tableJoinSpheres_APP, excelJoin, 'Sheet', 'AD');
    end

end


%GETSPHERESGLOBALDATA_OPTIMIZED_CORRECTED Calculate image-level plaque, sphere, and microglia summaries.
function [tableDataGlobal, tableDataJoin] = getSpheresGlobalData_optimized_corrected( ...
    tableDataGlobal, tableDataJoin, plaqueImage, spheresMask, ...
    noPlaquesSphereCentroids, correctionFactor, xyResolution, ...
    centroidsMicroglia, maskImg, volumeTotal, globalRow, joinRow, typeModel)

    stats = regionprops3(plaqueImage, {'Centroid', 'Volume'});

    if isempty(stats)
        centroids = zeros(0, 3);
        volPlaques = [];
    else
        centroids = stats.Centroid;
        volPlaques = stats.Volume * xyResolution^3 * correctionFactor^3;
        volPlaques(isnan(volPlaques)) = [];

        if ~isempty(centroids)
            centroids(isnan(centroids(:,1)), :) = [];
        end
    end

    if isempty(centroidsMicroglia)
        centroidsMicrogliaInd = [];
    else
        centroidsMicrogliaInd = sub2ind(size(plaqueImage), ...
            uint32(centroidsMicroglia(:,1)), ...
            uint32(centroidsMicroglia(:,2)), ...
            uint32(centroidsMicroglia(:,3)));
    end

    nonPlaqueSpheresLabel = max(spheresMask, [], 'all');
    voxelVolume = xyResolution^3 * correctionFactor^3;
    validVolume = nnz(maskImg) * voxelVolume;

    if contains(typeModel, 'APP')

        tableDataGlobal.N_Plaques(globalRow) = double(size(centroids, 1));
        tableDataGlobal.Plaque_Density(globalRow) = double((size(centroids, 1) / volumeTotal) * 1e9);

        plaqueImageValid = plaqueImage;
        plaqueImageValid(maskImg == 0) = 0;

        statsValid = regionprops3(plaqueImageValid, {'Volume'});

        if isempty(statsValid)
            volPlaquesValid = [];
        else
            volPlaquesValid = statsValid.Volume * voxelVolume;
            volPlaquesValid(isnan(volPlaquesValid)) = [];
        end

        nValidPlaques = length(unique(plaqueImageValid)) - 1;
        plaqueVolumeValid = sum(plaqueImageValid > 0, 'all') * voxelVolume;

        tableDataGlobal.N_Valid_Plaques(globalRow) = double(nValidPlaques);
        tableDataGlobal.Plaque_Density_Valid(globalRow) = double((nValidPlaques / validVolume) * 1e9);

        % Corrected: microglia inside plaque volume, not number of plaques.
        if isempty(centroidsMicrogliaInd)
            nMicrogliaInPlaques = 0;
        else
            nMicrogliaInPlaques = sum(plaqueImageValid(centroidsMicrogliaInd) > 0);
        end
        tableDataGlobal.Microglia_Density_Plaque(globalRow) = double((nMicrogliaInPlaques / plaqueVolumeValid) * 1e9);

        tableDataGlobal.Mean_Vol_Plaques(globalRow) = double(mean(volPlaques));
        tableDataGlobal.Median_Vol_Plaques(globalRow) = double(median(volPlaques));
        tableDataGlobal.P75_Vol_Plaques(globalRow) = double(quantile(volPlaques, 0.75));
        tableDataGlobal.IQR_Vol_Plaques(globalRow) = double(quantile(volPlaques, 0.75) - quantile(volPlaques, 0.25));

        tableDataGlobal.Mean_Vol_Plaques_Valid(globalRow) = double(mean(volPlaquesValid));
        tableDataGlobal.Median_Vol_Plaques_Valid(globalRow) = double(median(volPlaquesValid));
        tableDataGlobal.P75_Vol_Plaques_Valid(globalRow) = double(quantile(volPlaquesValid, 0.75));
        tableDataGlobal.IQR_Vol_Plaques_Valid(globalRow) = double(quantile(volPlaquesValid, 0.75) - quantile(volPlaquesValid, 0.25));

        tableDataGlobal.Total_Vol_Plaques(globalRow) = double(sum(volPlaques));
        tableDataGlobal.Occupied_Vol_Plaques(globalRow) = double(sum(volPlaques) / volumeTotal);
        tableDataGlobal.Total_Vol_Plaques_Valid(globalRow) = double(plaqueVolumeValid);
        tableDataGlobal.Occupied_Vol_Plaques_Valid(globalRow) = double(plaqueVolumeValid / validVolume);

        tableDataGlobal.N_Non_Plaque_Spheres(globalRow) = double(countSphereCentroids(noPlaquesSphereCentroids));
        tableDataGlobal.N_Plaque_Spheres(globalRow) = double(nValidPlaques);

        tableDataGlobal.Vol_Non_Plaque_Spheres(globalRow) = double(sum(spheresMask == nonPlaqueSpheresLabel, 'all') * voxelVolume);
        tableDataGlobal.Vol_Plaque_Sphere(globalRow) = double(sum(spheresMask < nonPlaqueSpheresLabel & spheresMask > 0, 'all') * voxelVolume);
        tableDataGlobal.Vol_Overlap_Plaque_Spheres(globalRow) = double(sum(spheresMask < nonPlaqueSpheresLabel & spheresMask > 1, 'all') * voxelVolume);

        tableDataJoin.VolNonPlaqueSpheres(joinRow) = double(sum(spheresMask == nonPlaqueSpheresLabel, 'all') * voxelVolume);
        tableDataJoin.VolPlaqueSpheres(joinRow) = double(sum(spheresMask < nonPlaqueSpheresLabel & spheresMask > 0, 'all') * voxelVolume);

        spheresNonPlaqueMask = spheresMask == nonPlaqueSpheresLabel;
        volNonPlaqueSpheres = sum(spheresNonPlaqueMask, 'all') * voxelVolume;

        if isempty(centroidsMicrogliaInd)
            nMicrogliaNonPlaqueSpheres = 0;
        else
            nMicrogliaNonPlaqueSpheres = sum(spheresNonPlaqueMask(centroidsMicrogliaInd));
        end

        tableDataJoin.MicrogliaDensityNonPlaqueSpheres(joinRow) = double((nMicrogliaNonPlaqueSpheres / volNonPlaqueSpheres) * 1e9);

        spheresPlaqueMask = spheresMask > 0 & spheresMask < nonPlaqueSpheresLabel;
        volPlaqueSpheres = sum(spheresPlaqueMask, 'all') * voxelVolume;

        if isempty(centroidsMicrogliaInd)
            nMicrogliaPlaqueSpheres = 0;
            nMicrogliaInsidePlaques = 0;
        else
            nMicrogliaPlaqueSpheres = sum(spheresPlaqueMask(centroidsMicrogliaInd));
            nMicrogliaInsidePlaques = sum(plaqueImageValid(centroidsMicrogliaInd) > 0);
        end

        tableDataJoin.MicrogliaDensityPlaqueSpheres(joinRow) = double((nMicrogliaPlaqueSpheres / volPlaqueSpheres) * 1e9);
        tableDataJoin.MicrogliaDensityPlaqueSpheres_WP(joinRow) = double(((nMicrogliaPlaqueSpheres - nMicrogliaInsidePlaques) / volPlaqueSpheres) * 1e9);

        for i = 1:(nonPlaqueSpheresLabel - 1)
            sM = spheresMask == i;
            volSM = sum(sM, 'all') * voxelVolume;

            tableDataJoin.(sprintf("Vol_Overlap_%d_Spheres", i))(joinRow) = volSM;

            if isempty(centroidsMicrogliaInd)
                nMicrogliaSM = 0;
            else
                nMicrogliaSM = sum(sM(centroidsMicrogliaInd));
            end

            tableDataJoin.(sprintf("Microglia_Density_Overlap_%d_Spheres", i))(joinRow) = (nMicrogliaSM / volSM) * 1e9;
        end

    else

        tableDataGlobal.N_WT_Spheres(globalRow) = double(countSphereCentroids(noPlaquesSphereCentroids));
        tableDataGlobal.Vol_WT_Spheres(globalRow) = double(sum(spheresMask > 0, 'all') * voxelVolume);

        tableDataJoin.VolWTSpheres(joinRow) = double(sum(spheresMask > 0, 'all') * voxelVolume);

        spheresNonPlaqueMask = spheresMask == nonPlaqueSpheresLabel;
        volWTSpheres = sum(spheresNonPlaqueMask, 'all') * voxelVolume;

        if isempty(centroidsMicrogliaInd)
            nMicrogliaWTSpheres = 0;
        else
            nMicrogliaWTSpheres = sum(spheresNonPlaqueMask(centroidsMicrogliaInd));
        end

        tableDataJoin.MicrogliaDensityWTSpheres(joinRow) = double((nMicrogliaWTSpheres / volWTSpheres) * 1e9);
    end

    tableDataGlobal.Volume_Total(globalRow) = volumeTotal;
    tableDataGlobal.Valid_Volume(globalRow) = double(validVolume);
    tableDataGlobal.N_Valid_Microglia(globalRow) = double(length(centroidsMicrogliaInd));
    tableDataGlobal.Microglia_Density(globalRow) = double((length(centroidsMicrogliaInd) / validVolume) * 1e9);

end


%GETPLAQUESPHEREDATA_OPTIMIZED_CORRECTED Calculate metrics for plaque-centered spheres.
function [tableData, nSpheresCompleted] = getPlaqueSphereData_optimized_corrected( ...
    tableData, plaqueImage, plaqueDilImg, spheresInd, filename, correctionFactor, ...
    xyResolution, centroidsMicroglia, radius, maskImg, good_neighbours, ...
    neib_number, vornb, savePath, nValidPlaques, col, centroidsMicrogliaT, ...
    imageData, distanceLayers, metricFlags)

    saveFolderSpheres = 'PlaqueSpheres';

    statsPlaquesTotal = regionprops3(plaqueImage, {'Centroid'});

    if isempty(statsPlaquesTotal)
        centroidsPlaques = zeros(0, 3);
    else
        centroidsPlaques = statsPlaquesTotal.Centroid;
    end

    plaqueImage(maskImg == 0) = 0;

    statsPlaques = regionprops3(plaqueImage, {'Volume', 'PrincipalAxisLength'});

    if isempty(statsPlaques)
        volPlaques = [];
        diamPlaques = [];
    else
        volPlaques = statsPlaques.Volume;
        volPlaques(volPlaques == 0) = [];
        volPlaques = volPlaques * xyResolution^3 * correctionFactor^3;

        diamPlaques = statsPlaques.PrincipalAxisLength;
        diamPlaques(diamPlaques == 0) = [];
    end

    if isempty(centroidsMicroglia)
        centroidsMicrogliaInd = [];
    else
        centroidsMicrogliaInd = sub2ind(size(plaqueImage), ...
            uint32(centroidsMicroglia(:,1)), ...
            uint32(centroidsMicroglia(:,2)), ...
            uint32(centroidsMicroglia(:,3)));
    end

    plaqueDilImg(maskImg == 0) = 0;

    statsPlaquesDil = regionprops3(plaqueDilImg, {'Volume', 'PrincipalAxisLength'});

    if isempty(statsPlaquesDil)
        volPlaquesDil = [];
    else
        volPlaquesDil = statsPlaquesDil.Volume;
        volPlaquesDil(volPlaquesDil == 0) = [];
        volPlaquesDil = volPlaquesDil * xyResolution^3 * correctionFactor^3;
    end

    imgBorder = logical(maskImg ./ 255);
    imgBorder(cumsum(imgBorder, 2) > 1) = 0;
    [yBorder, xBorder, zBorder] = ind2sub(size(imgBorder), find(imgBorder));

    if ~isempty(centroidsPlaques)
        centroidsPlaques(:, [1 2]) = centroidsPlaques(:, [2 1]);
        centroidsPlaques(isnan(centroidsPlaques(:,1)), :) = [];
    end

    nSpheresCompleted = 0;
    nPlaquesCompletedCapt = 0; %#ok<NASGU>
    nSpheresTouchPlaques = 0; %#ok<NASGU>

    volSphereCompletedPxl = (4 / 3) * pi * radius^3;
    volSphereCompleted = volSphereCompletedPxl * xyResolution^3 * correctionFactor^3;

    plaques = unique(plaqueImage);
    plaques(plaques == 0) = [];

    for p = 1:length(spheresInd)

        currentSphere = spheresInd{p};

        if length(find(maskImg(currentSphere))) < volSphereCompletedPxl * 0.95
            currentSphere(~maskImg(currentSphere)) = [];
            spheresInd{p} = currentSphere;
        end
    end

    for p = 1:length(spheresInd)

        [tableData, row] = nextAvailableTableRow(tableData);

        tableData = fillSphereMetadata(tableData, row, imageData);
        tableData.IDSphere(row) = row;
        tableData.ImageSphereID(row) = p;
        tableData.TypeSphere(row) = "PlaqueSphere";

        plaqueID = plaques(p);

        tableData.Vol_Plaque(row) = double(volPlaques(p));
        tableData.Length_Plaque(row) = double(diamPlaques(p) * xyResolution * correctionFactor);

        s = spheresInd{p};

        plaqueIndMask = plaqueImage == plaqueID;
        plaqueIndMaskDil = plaqueDilImg == plaqueID;

        volSphere = length(s) * xyResolution^3 * correctionFactor^3;
        tableData.VolSphere(row) = double(volSphere);

        isSphereCompleted = 0;
        isPlaqueInside = 0;
        nPlaquesTouching = 0;

        if volSphere >= volSphereCompleted * 0.95
            isSphereCompleted = 1;
            nSpheresCompleted = nSpheresCompleted + 1;
        end

        if diamPlaques(p) / 2 < radius
            isPlaqueInside = 1;
            nPlaquesCompletedCapt = nPlaquesCompletedCapt + 1; %#ok<NASGU>
        end

        tableData.SphereCompleted(row) = double(isSphereCompleted);
        tableData.Plaque_Inside(row) = double(isPlaqueInside);

        c = centroidsPlaques;

        if length(unique(plaqueImage(s))) > 2
            nPlaquesTouching = length(unique(plaqueImage(s))) - 2;
            nSpheresTouchPlaques = nSpheresTouchPlaques + 1; %#ok<NASGU>
            distNearestPlaque = 0;
        elseif length(spheresInd) <= 1
            distNearestPlaque = NaN;
        else
            if ~isempty(nValidPlaques) && nValidPlaques(p) <= size(c, 1)
                c(nValidPlaques(p), :) = [];
            end

            [yC, xC, zC] = ind2sub(size(plaqueImage), s);
            sphereVoxelCoords = [yC(:), xC(:), zC(:)];

            if isempty(c)
                distNearestPlaque = NaN;
            else
                distNearestPlaque = min(pdist2(sphereVoxelCoords, c), [], 'all') * xyResolution * correctionFactor;
            end
        end

        tableData.N_Plaques_Touching(row) = double(nPlaquesTouching);
        tableData.DistNearestPlaque(row) = distNearestPlaque;

        if isempty(centroidsMicrogliaInd)
            microgliaInSphereMask = false(0, 1);
        else
            microgliaInSphereMask = ismember(centroidsMicrogliaInd, s);
        end

        centroidsMicrogliaSphere = centroidsMicroglia(microgliaInSphereMask, :);

        aux = 1:length(spheresInd);
        volOverlap = sum(ismember(s, [spheresInd{aux(aux ~= p)}])) * xyResolution^3 * correctionFactor^3;

        tableData.VolOverlap(row) = double(volOverlap);

        nMicrogliaSphere = sum(microgliaInSphereMask);
        nMicrogliaPlaque = sum(plaqueIndMask(centroidsMicrogliaInd));
        nMicrogliaPlaqueDil = sum(plaqueIndMaskDil(centroidsMicrogliaInd));

        microgliaDensity = safeDivide(nMicrogliaSphere, volSphere, 1e9);
        microgliaDensityPlaque = safeDivide(nMicrogliaPlaque, volPlaques(p), 1e9);
        microgliaDensityWP = safeDivide(nMicrogliaSphere - nMicrogliaPlaque, volSphere - volPlaques(p), 1e9);
        microgliaDensityWPAM = safeDivide(nMicrogliaSphere - nMicrogliaPlaqueDil, volSphere - volPlaquesDil(p), 1e9);

        tableData.nMicroglia(row) = double(nMicrogliaSphere);
        tableData.MicrogliaDensity(row) = double(microgliaDensity);
        tableData.N_Microglia_Plaque(row) = double(nMicrogliaPlaque);
        tableData.Microglia_Density_Plaque(row) = double(microgliaDensityPlaque);
        tableData.Microglia_Density_WP(row) = double(microgliaDensityWP);
        tableData.Microglia_Density_WPAM(row) = double(microgliaDensityWPAM);

        if metricFlags.distances
            [distMean, distStd, nearestMean, nearestStd] = getMicrogliaDistanceStats(centroidsMicrogliaSphere, xyResolution * correctionFactor);
            tableData.MicrogliaDist_Mean(row) = distMean;
            tableData.MicrogliaDist_Std(row) = distStd;
            tableData.MicrogliaDistToNearest_Mean(row) = nearestMean;
            tableData.MicrogliaDistToNearest_Std(row) = nearestStd;
        end

        plaqueCentroidXYZ = [centroidsPlaques(nValidPlaques(p), 2), centroidsPlaques(nValidPlaques(p), 1), centroidsPlaques(nValidPlaques(p), 3)];
        normalizedPoints = getRadioAndCenterNormalization(plaqueCentroidXYZ, centroidsMicrogliaSphere, radius);
        if metricFlags.radial
            [meanRadialDistance, stdRadialDistance, centeredPoints] = getRadialDistribution(normalizedPoints, savePath, 'PlaqueSpheres/', filename, row, isSphereCompleted);
            getAngularDistribution(normalizedPoints, savePath, 'PlaqueSpheres/', filename, row, 0, isSphereCompleted);
            tableData.MeanRadialDistance(row) = double(meanRadialDistance);
            tableData.StdRadialDistance(row) = double(stdRadialDistance);
            tableData.CentralThirdMicrogliaFraction(row) = double(centeredPoints);
        end
        if metricFlags.spatialStatistics
            AL = getRipleyK3(normalizedPoints, savePath, 'PlaqueSpheres/', filename, row, volPlaques(p), isSphereCompleted);
            [~, Ag, gmax, r_gmax, gmin, r_gmin] = getCorrelationFunctionG(normalizedPoints, savePath, 'PlaqueSpheres/', filename, row, isSphereCompleted);
            tableData.DeviationAreaK3(row) = double(AL);
            tableData.DeviationAreaG(row) = double(Ag);
            tableData.gMax(row) = double(gmax);
            tableData.distanceGMax(row) = double(r_gmax);
            tableData.gMin(row) = double(gmin);
            tableData.distanceGMin(row) = double(r_gmin);
        end
        closeFiguresSafely();

        centroidSphere = plaqueCentroidXYZ;
        tableData.CentroidX(row) = double(centroidSphere(1));
        tableData.CentroidY(row) = double(centroidSphere(2));
        tableData.CentroidZ(row) = double(centroidSphere(3));

        [~, I] = min(pdist2([yBorder, zBorder], centroidSphere(2:3)));
        distToBorder = pdist2([xBorder(I), yBorder(I), zBorder(I)], centroidSphere) * xyResolution * correctionFactor;

        tableData.DistToBorder(row) = double(distToBorder);
        [layerLabel, layerInformationAvailable] = ...
            getLayerLabelForImage(distToBorder, distanceLayers, imageData);
        tableData.Layer(row) = layerLabel;
        tableData.LayerInformationAvailable(row) = layerInformationAvailable;

        if metricFlags.voronoi
            [nValidMicroglias, meanNeighboursVoronoi, stdNeighboursVoronoi, ...
                meanSurfaceAreaVoronoi, stdSurfaceAreaVoronoi, meanVolumeVoronoi, ...
                stdVolumeVoronoi, meanDistanceNeighboursVoronoi, ...
                stdDistanceNeighboursVoronoi] = getVoronoiSphereData( ...
                good_neighbours, neib_number, centroidSphere, radius, vornb, ...
                centroidsMicrogliaSphere, savePath, saveFolderSpheres, filename, ...
                string(row), char(metricFlags.voronoiTypeData), xyResolution, ...
                correctionFactor, size(plaqueImage), centroidsMicrogliaT, col, ...
                distNearestPlaque, 1);

            tableData.nVoronoiMicroglia(row) = double(nValidMicroglias);
            tableData.meanNeighboursVoronoi(row) = double(meanNeighboursVoronoi);
            tableData.stdNeighboursVoronoi(row) = double(stdNeighboursVoronoi);
            tableData.meanSurfaceAreaVoronoi(row) = double(meanSurfaceAreaVoronoi);
            tableData.stdSurfaceAreaVoronoi(row) = double(stdSurfaceAreaVoronoi);
            tableData.meanVolumeVoronoi(row) = double(meanVolumeVoronoi);
            tableData.stdVolumeVoronoi(row) = double(stdVolumeVoronoi);
            tableData.meanDistanceNeighboursVoronoi(row) = double(meanDistanceNeighboursVoronoi);
            tableData.stdDistanceNeighboursVoronoi(row) = double(stdDistanceNeighboursVoronoi);
        end
    end


end



%GETNOPLAQUESPHEREDATA_OPTIMIZED_CORRECTED Calculate non-plaque and WT sphere metrics.
function [tableData, tableSphPlaData] = getNoPlaqueSphereData_optimized_corrected( ...
    tableData, tableSphPlaData, plaqueImage, noPlaqueSpheresInd, filename, ...
    correctionFactor, xyResolution, centroidsMicroglia, radius, maskImg, ...
    good_neighbours, neib_number, vornb, savePath, col, centroidsMicrogliaT, ...
    imageData, distanceLayers, metricFlags)

    stats = regionprops3(plaqueImage, {'Centroid', 'Volume', 'VoxelList'});

    if isempty(stats)
        volPlaques = [];
        centroidsPlaques = zeros(0, 3);
        voxList = {};
    else
        volPlaques = stats.Volume * xyResolution^3 * correctionFactor^3;
        volPlaques(volPlaques == 0) = [];

        centroidsPlaques = stats.Centroid;
        voxList = stats.VoxelList;

        if ~isempty(centroidsPlaques)
            toDelete = cellfun(@(v) isempty(v), voxList);
            voxList(toDelete == 1) = [];
            centroidsPlaques(:, [1 2]) = centroidsPlaques(:, [2 1]);
            centroidsPlaques(isnan(centroidsPlaques(:,1)), :) = [];
        end
    end

    imgBorder = logical(maskImg ./ 255);
    imgBorder(cumsum(imgBorder, 2) > 1) = 0;
    [yBorder, xBorder, zBorder] = ind2sub(size(imgBorder), find(imgBorder));

    if isempty(centroidsMicroglia)
        centroidsMicrogliaInd = [];
    else
        centroidsMicrogliaInd = sub2ind(size(plaqueImage), ...
            uint32(centroidsMicroglia(:,1)), ...
            uint32(centroidsMicroglia(:,2)), ...
            uint32(centroidsMicroglia(:,3)));
    end

    E = 1e-6;

    microgliaDenArray = [];
    centroidsSphereMatrix = [];
    distNearestPlaque = 0;

    opts = struct();
    opts.useRobust = true;
    opts.radialWeight = "none";
    opts.excludeCenterEps = 0;

    for ind = 1:length(noPlaqueSpheresInd)

        [tableData, row] = nextAvailableTableRow(tableData);

        tableData = fillSphereMetadata(tableData, row, imageData);
        tableData.IDSphere(row) = row;
        tableData.ImageSphereID(row) = ind;

        nS = noPlaqueSpheresInd{ind};
        volSphere = length(nS) * xyResolution^3 * correctionFactor^3;

        if isempty(centroidsMicrogliaInd)
            microgliaInSphereMask = false(0, 1);
        else
            microgliaInSphereMask = ismember(centroidsMicrogliaInd, nS);
        end

        nMicrogliaSphere = sum(microgliaInSphereMask);
        microgliaDensitySphere = safeDivide(nMicrogliaSphere, volSphere, 1e9);

        microgliaDenArray = [microgliaDenArray, microgliaDensitySphere]; %#ok<AGROW>

        tableData.VolSphere(row) = double(volSphere);
        tableData.nMicroglia(row) = double(nMicrogliaSphere);
        tableData.MicrogliaDensity(row) = double(microgliaDensitySphere);

        microgliaSphere = centroidsMicroglia(microgliaInSphereMask, :);

        if metricFlags.distances
            [distMean, distStd, nearestMean, nearestStd] = ...
                getMicrogliaDistanceStats(microgliaSphere, xyResolution * correctionFactor);
            tableData.MicrogliaDist_Mean(row) = distMean;
            tableData.MicrogliaDist_Std(row) = distStd;
            tableData.MicrogliaDistToNearest_Mean(row) = nearestMean;
            tableData.MicrogliaDistToNearest_Std(row) = nearestStd;
        end

        [yC, xC, zC] = ind2sub(size(plaqueImage), nS);
        coords = [yC(:), xC(:), zC(:)];
        centroidSphere = mean(coords, 1);

        centroidsSphereMatrix = [centroidsSphereMatrix; centroidSphere]; %#ok<AGROW>

        polarizationInfo = randomDirectionNull(centroidsMicroglia, centroidSphere, radius, 100, opts);

        tableData.Pol_rand_mean(row) = double(polarizationInfo.Pol_mean);
        tableData.Pol_rand_std(row) = double(polarizationInfo.Pol_sd);
        tableData.Pol_rand_P95(row) = double(polarizationInfo.Pol_p95);

        tableData.Align_mean(row) = double(polarizationInfo.Align_mean);
        tableData.Align_std(row) = double(polarizationInfo.Align_sd);
        tableData.Align_P95(row) = double(polarizationInfo.Align_p95);

        tableData.meanCos_mean(row) = double(polarizationInfo.meanCos_mean);
        tableData.meanCos_std(row) = double(polarizationInfo.meanCos_sd);
        tableData.meanCos_P95(row) = double(polarizationInfo.meanCos_p95);

        tableData.DisplacementMagnitude(row) = double(polarizationInfo.D_mean);

        tableData.u_Align_x(row) = double(polarizationInfo.u_maxAlign(2));
        tableData.u_Align_y(row) = double(polarizationInfo.u_maxAlign(1));
        tableData.u_Align_z(row) = double(polarizationInfo.u_maxAlign(3));
        tableData.Align_max(row) = double(polarizationInfo.Align_max);
        tableData.meanCos_atMaxAlign(row) = double(polarizationInfo.meanCos_atMaxAlign);
        tableData.Pol_atMaxAlign(row) = double(polarizationInfo.Pol_atMaxAlign);

        tableData.u_maxCos_x(row) = double(polarizationInfo.u_maxCos(2));
        tableData.u_maxCos_y(row) = double(polarizationInfo.u_maxCos(1));
        tableData.u_maxCos_z(row) = double(polarizationInfo.u_maxCos(3));
        tableData.meanCos_max(row) = double(polarizationInfo.meanCos_max);
        tableData.Align_atMaxCos(row) = double(polarizationInfo.Align_atMaxCos);
        tableData.Pol_atMaxCos(row) = double(polarizationInfo.Pol_atMaxCos);

        u_depth = [0, 1, 0];
        layersPolarizationInfo = depthSuperfMetrics(centroidsMicroglia, centroidSphere, radius, u_depth, opts);

        tableData.Align_depth(row) = double(layersPolarizationInfo.Align_depth);
        tableData.Pol_depth(row) = double(layersPolarizationInfo.Pol_depth);
        tableData.meanCos_depth(row) = double(layersPolarizationInfo.meanCos_depth);

        if contains(imageData{6}, 'APP')

            if ~isempty(centroidsPlaques)

                distPlaques = pdist2(centroidSphere, centroidsPlaques) * xyResolution * correctionFactor;
                [distNearestPlaque, nearestPlaque] = min(distPlaques, [], 'all', 'linear');

                tableData.DistNearestPlaque(row) = distNearestPlaque;
                tableData.PlaqueInfluenceIndex_1(row) = sum(volPlaques ./ (distPlaques' + E));
                tableData.PlaqueInfluenceIndex_2(row) = sum(volPlaques ./ (distPlaques' + E).^2);
                tableData.PlaqueInfluenceIndex_3(row) = sum(volPlaques ./ (distPlaques' + E).^3);
                [tableData.MaxInfluencePlaque(row), maxInfluencePlaque] = max(volPlaques ./ (distPlaques' + E).^2);

                u_plaques = cell(size(centroidsPlaques, 1), 1);

                for nPlaque = 1:size(centroidsPlaques, 1)

                    [tableSphPlaData, row_plaque] = nextAvailableTableRow(tableSphPlaData);

                    centroidPlaque = centroidsPlaques(nPlaque, :);
                    opts.null = polarizationInfo;

                    polarizationInfoPlaque = computeDirectionalBiasSphere(centroidsMicroglia, centroidSphere, radius, centroidPlaque, opts);
                    u_plaques{nPlaque} = polarizationInfoPlaque.u;

                    tableSphPlaData.IDImage(row_plaque) = imageData{5};
                    tableSphPlaData.ImageSphereID(row_plaque) = double(tableData.ImageSphereID(row));
                    tableSphPlaData.IDSphere(row_plaque) = double(row);
                    tableSphPlaData.IDPlaque(row_plaque) = double(nPlaque);

                    tableSphPlaData.VolPlaque(row_plaque) = double(volPlaques(nPlaque));
                    tableSphPlaData.DistToPlaque(row_plaque) = double(distPlaques(nPlaque));

                    plaquePoints = voxList{nPlaque};
                    plaquePoints(:, [1 2]) = plaquePoints(:, [2 1]);

                    tableSphPlaData.DistToPlaque_IntersectingCells(row_plaque) = double(min(pdist2(centroidSphere, plaquePoints), [], 'all', 'linear') * xyResolution * correctionFactor);

                    tableSphPlaData.u_plaque_x(row_plaque) = double(polarizationInfoPlaque.u(2));
                    tableSphPlaData.u_plaque_y(row_plaque) = double(polarizationInfoPlaque.u(1));
                    tableSphPlaData.u_plaque_z(row_plaque) = double(polarizationInfoPlaque.u(3));

                    tableSphPlaData.Pol(row_plaque) = double(polarizationInfoPlaque.Pol);
                    tableSphPlaData.Align(row_plaque) = double(polarizationInfoPlaque.Align);
                    tableSphPlaData.meanCos(row_plaque) = double(polarizationInfoPlaque.meanCos);

                    tableSphPlaData.zAlign(row_plaque) = double(polarizationInfoPlaque.zAlign);
                    tableSphPlaData.pEmpAlign(row_plaque) = double(polarizationInfoPlaque.pEmpAlign);
                    tableSphPlaData.zMeanCos(row_plaque) = double(polarizationInfoPlaque.zMeanCos);
                    tableSphPlaData.pEmpMeanCos(row_plaque) = double(polarizationInfoPlaque.pEmpMeanCos);

                    tableSphPlaData.AnglePlaqueMaxAlign(row_plaque) = double(rad2deg(acos(max(-1, min(1, dot(polarizationInfoPlaque.u, polarizationInfo.u_maxAlign))))));
                    tableSphPlaData.AnglePlaqueMaxCos(row_plaque) = double(rad2deg(acos(max(-1, min(1, dot(polarizationInfoPlaque.u, polarizationInfo.u_maxCos))))));

                    tableSphPlaData.isClosest(row_plaque) = double(nPlaque == nearestPlaque);
                    tableSphPlaData.isMostInfluencer(row_plaque) = double(nPlaque == maxInfluencePlaque);
                end

                U = vertcat(u_plaques{:});

                tableData.plaqueDirDispersion(row) = 1 - norm(mean(U, 1));

                w = volPlaques(:) ./ distPlaques(:);
                w = w / sum(w);

                u_bar_w = sum(U .* w, 1);
                tableData.plaqueDirDispersion_weighted(row) = 1 - norm(u_bar_w);

                u_infl = u_bar_w / (norm(u_bar_w) + eps);
                tableData.u_influence_x(row) = u_infl(1);
                tableData.u_influence_y(row) = u_infl(2);
                tableData.u_influence_z(row) = u_infl(3);

                tableData.AngleUInfluenceMaxAlign(row) = double(rad2deg(acos(max(-1, min(1, dot(u_infl, polarizationInfo.u_maxAlign))))));
                tableData.AngleUInfluenceMaxCos(row) = double(rad2deg(acos(max(-1, min(1, dot(u_infl, polarizationInfo.u_maxCos))))));

            else

                tableData.DistNearestPlaque(row) = NaN;
                tableData.PlaqueInfluenceIndex_1(row) = 0;
                tableData.PlaqueInfluenceIndex_2(row) = 0;
                tableData.PlaqueInfluenceIndex_3(row) = 0;
                tableData.MaxInfluencePlaque(row) = 0;

            end

            tableData.TypeSphere(row) = "NonPlaqueSphere";
            saveFolderSpheres = 'NonPlaqueSpheres/';

        else

            tableData.TypeSphere(row) = "WTSphere";
            saveFolderSpheres = 'WTSpheres/';
        end

        centroidSphere(:, [1 2]) = centroidSphere(:, [2 1]);

        tableData.CentroidX(row) = double(centroidSphere(1));
        tableData.CentroidY(row) = double(centroidSphere(2));
        tableData.CentroidZ(row) = double(centroidSphere(3));

        distToBorder = getDistToBorderX(maskImg, centroidSphere, xyResolution, correctionFactor);
        
        tableData.DistToBorder(row) = double(distToBorder);
        [layerLabel, layerInformationAvailable] = ...
            getLayerLabelForImage(distToBorder, distanceLayers, imageData);
        tableData.Layer(row) = layerLabel;
        tableData.LayerInformationAvailable(row) = layerInformationAvailable;

        centroidsMicrogliaSphere = centroidsMicroglia(microgliaInSphereMask, :);

        normalizedPoints = getRadioAndCenterNormalization( ...
            centroidSphere, centroidsMicrogliaSphere, radius);
        if metricFlags.radial
            [meanRadialDistance, stdRadialDistance, centeredPoints] = ...
                getRadialDistribution(normalizedPoints, savePath, saveFolderSpheres, ...
                filename, string(row), 1);
            getAngularDistribution(normalizedPoints, savePath, saveFolderSpheres, ...
                filename, string(row), distNearestPlaque, 1);
            tableData.MeanRadialDistance(row) = double(meanRadialDistance);
            tableData.StdRadialDistance(row) = double(stdRadialDistance);
            tableData.CentralThirdMicrogliaFraction(row) = double(centeredPoints);
        end
        if metricFlags.spatialStatistics
            AL = getRipleyK3(normalizedPoints, savePath, saveFolderSpheres, ...
                filename, string(row), 0, 1);
            [~, Ag, gmax, r_gmax, gmin, r_gmin] = ...
                getCorrelationFunctionG(normalizedPoints, savePath, saveFolderSpheres, ...
                filename, string(row), 1);
            tableData.DeviationAreaK3(row) = double(AL);
            tableData.DeviationAreaG(row) = double(Ag);
            tableData.gMax(row) = double(gmax);
            tableData.distanceGMax(row) = double(r_gmax);
            tableData.gMin(row) = double(gmin);
            tableData.distanceGMin(row) = double(r_gmin);
        end
        closeFiguresSafely();

        if metricFlags.voronoi
            [nValidMicroglias, meanNeighboursVoronoi, stdNeighboursVoronoi, ...
                meanSurfaceAreaVoronoi, stdSurfaceAreaVoronoi, meanVolumeVoronoi, ...
                stdVolumeVoronoi, meanDistanceNeighboursVoronoi, ...
                stdDistanceNeighboursVoronoi] = getVoronoiSphereData( ...
                good_neighbours, neib_number, centroidSphere, radius, vornb, ...
                centroidsMicrogliaSphere, savePath, saveFolderSpheres, filename, ...
                string(row), char(metricFlags.voronoiTypeData), xyResolution, ...
                correctionFactor, size(plaqueImage), centroidsMicrogliaT, col, ...
                distNearestPlaque, 1);
            tableData.nVoronoiMicroglia(row) = double(nValidMicroglias);
            tableData.meanNeighboursVoronoi(row) = double(meanNeighboursVoronoi);
            tableData.stdNeighboursVoronoi(row) = double(stdNeighboursVoronoi);
            tableData.meanSurfaceAreaVoronoi(row) = double(meanSurfaceAreaVoronoi);
            tableData.stdSurfaceAreaVoronoi(row) = double(stdSurfaceAreaVoronoi);
            tableData.meanVolumeVoronoi(row) = double(meanVolumeVoronoi);
            tableData.stdVolumeVoronoi(row) = double(stdVolumeVoronoi);
            tableData.meanDistanceNeighboursVoronoi(row) = double(meanDistanceNeighboursVoronoi);
            tableData.stdDistanceNeighboursVoronoi(row) = double(stdDistanceNeighboursVoronoi);
        end
    end

end


function T = fillGlobalImageMetadata(T, row, imageData)
%FILLGLOBALIMAGEMETADATA Write metadata into an image-level sphere summary row.

    T.File(row) = imageData{1};
    T.Mouse(row) = imageData{2};
    T.Sex(row) = imageData{3};
    T.Section(row) = imageData{4};
    T.Image(row) = imageData{5};
    T.Model(row) = imageData{6};
    T.BregmaLevel(row) = imageData{7};
    T.CortexArea(row) = imageData{8};

end


function T = fillJoinImageMetadata(T, row, imageData)
%FILLJOINIMAGEMETADATA Write metadata into a joined sphere summary row.

    T.File(row) = imageData{1};
    T.Mouse(row) = imageData{2};
    T.Sex(row) = imageData{3};
    T.Section(row) = imageData{4};
    T.Image(row) = imageData{5};
    T.Model(row) = imageData{6};
    T.BregmaLevel(row) = imageData{7};
    T.CortexArea(row) = imageData{8};

end


function T = fillSphereMetadata(T, row, imageData)
%FILLSPHEREMETADATA Write image metadata and identifiers into one sphere-result row.

    T.IDSphere(row) = row;
    T.File(row) = imageData{1};
    T.Mouse(row) = imageData{2};
    T.Sex(row) = imageData{3};
    T.Section(row) = imageData{4};
    T.Image(row) = imageData{5};
    T.Model(row) = imageData{6};
    T.BregmaLevel(row) = imageData{7};
    T.CortexArea(row) = imageData{8};
    T.LayerInformationAvailable(row) = logical(imageData{9});

end


function [layer, informationAvailable] = getLayerLabelForImage(distToBorder, distanceLayers, imageData)
%GETLAYERLABELFORIMAGE Assign a layer only when the image has valid layer information.

    informationAvailable = logical(imageData{9});
    if informationAvailable
        layer = getLayerFromDistance(distToBorder, distanceLayers, imageData{8});
    else
        layer = string(imageData{10});
    end
end


function layer = getLayerFromDistance(distToBorder, distanceLayers, cortexArea)
%GETLAYERFROMDISTANCE Assign a cortical layer from surface distance and region type.

    if distToBorder <= distanceLayers(1)
        layer = "Layer 1";
    elseif distToBorder <= distanceLayers(2)
        layer = "Layer 2-3";
    elseif distToBorder <= distanceLayers(3)
        if contains(cortexArea, 'Medial')
            layer = "Layer 5";
        else
            layer = "Layer 4";
        end
    elseif distToBorder <= distanceLayers(4)
        if contains(cortexArea, 'Medial')
            layer = "Layer 6";
        else
            layer = "Layer 5";
        end
    else
        layer = "Out of range";
    end

end


function [distMean, distStd, nearestMean, nearestStd] = getMicrogliaDistanceStats(points, distanceScale_um)
%GETMICROGLIADISTANCESTATS Calculate pairwise and nearest-neighbor distance summaries.

    if size(points, 1) > 1
        microgliaDist = pdist(points) * distanceScale_um;
        [~, dist] = knnsearch(points, points, 'K', 2);
        microgliaNearestDist = dist(:, 2) * distanceScale_um;

        distMean = double(mean(microgliaDist));
        distStd = double(std(microgliaDist));
        nearestMean = double(mean(microgliaNearestDist));
        nearestStd = double(std(microgliaNearestDist));
    else
        distMean = NaN;
        distStd = NaN;
        nearestMean = NaN;
        nearestStd = NaN;
    end

end


function value = extractMatVariable(S, candidateNames)
%EXTRACTMATVARIABLE Read the first matching variable from a loaded MAT structure.

    for i = 1:numel(candidateNames)
        if isfield(S, candidateNames{i})
            value = S.(candidateNames{i});
            return;
        end
    end

    fields = fieldnames(S);

    if isempty(fields)
        error('MAT file does not contain any variables.');
    end

    value = S.(fields{1});

end

function closeFiguresSafely()
%CLOSEFIGURESSAFELY Close visible and hidden figures and request Java garbage collection.

    try
        oldHidden = get(groot, 'ShowHiddenHandles');
        set(groot, 'ShowHiddenHandles', 'on');
        close all force;
        set(groot, 'ShowHiddenHandles', oldHidden);
    catch
    end

    try
        drawnow;
    catch
    end

    try
        if usejava('jvm')
            java.lang.System.gc();
        end
    catch
    end

end


function n = countSphereCentroids(centroids)
%COUNTSPHERECENTROIDS Return the number of sphere centroids for Nx3 or 3xN arrays.
    if isempty(centroids)
        n = 0;
    elseif size(centroids,2) == 3
        n = size(centroids,1);
    elseif size(centroids,1) == 3
        n = size(centroids,2);
    else
        n = numel(centroids);
    end
end

function T = reorderSphereIdentifierColumns(T)
%REORDERSPHEREIDENTIFIERCOLUMNS Place identifiers at the start of sphere tables.
    if isempty(T), return; end
    preferred = ["FileName","MouseID","SectionID","ImageID","ImageSphereID", ...
        "SphereID","SphereType","Model","CorticalRegion","Sex","BregmaLevel"];
    names = string(T.Properties.VariableNames);
    preferred = preferred(ismember(preferred,names));
    remaining = names(~ismember(names,preferred));
    T = T(:, cellstr([preferred, remaining]));
end

function T = reorderSphereRelationIdentifierColumns(T)
%REORDERSPHERERELATIONIDENTIFIERCOLUMNS Place relation identifiers first.
    if isempty(T), return; end
    preferred = ["ImageID","ImageSphereID","SphereID","PlaqueID"];
    names = string(T.Properties.VariableNames);
    preferred = preferred(ismember(preferred,names));
    remaining = names(~ismember(names,preferred));
    T = T(:, cellstr([preferred, remaining]));
end
