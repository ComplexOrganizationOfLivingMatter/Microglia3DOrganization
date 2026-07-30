function analyzeIndividualPlaques(pathImgMask, pathImgMicroglia, pathCentroids, pathDilatedPlaques, pathPlaques, voronoiPath, nameExcel, pathExcel, savePath, saveExcel, analysisConfig)
%% Optimized fast version of getPlaqueInfo_function
%
% Inputs are compatible with the legacy per-plaque analysis interface.
%
% Goal:
%   Optimize speed and memory while applying the agreed corrections.
%
% Calculations intentionally preserved:
%   - Same APP filtering.
%   - Same crop definition: start:(start + desire_pxls).
%   - Same imgTarget definition: imgMask & imgOrtho.
%   - Same plaque volumes from regionprops3.
%   - Same valid plaques / outside plaques logic.
%   - Same plaque-associated / inside / around microglia logic.
%   - Same density formulas.
%   - Same layer assignment formula.
%   - Same Voronoi calculations except for the agreed vornb/good_neighbours correction.
%
% Corrections applied directly:
%
%   1) Centroid Z coordinate for distance metrics is scaled with zResolution.
%   2) MicrogliaDistToNearest_Std uses std(), not mean().
%   3) Voronoi totals use plaqueAssociatedMicroglia filtered by good_neighbours,
%      while vornb is also filtered by good_neighbours but searched using
%      the original associated microglia indices.

    if nargin < 11 || isempty(analysisConfig), analysisConfig = createMicrogliaConfig(); end
    useVoronoi = analysisConfig.voronoi.enabled && analysisConfig.voronoi.contexts.individualPlaques.enabled;
    calculateDistances = isMetricGroupEnabled(analysisConfig, "distances");

    if ~isfolder(savePath)
        mkdir(savePath);
    end

    tableData = readtable(fullfile(pathExcel, nameExcel));
    tableData = tableData(contains(tableData.Modelo, "APP"), :);

    listFiles = tableData.Archivo;
    nImages = length(listFiles);

    tableSaveData = preparePlaqueDataTable(table(), 1);

    % Distances between cortex layers. Preserved from original.
    distanceMedial_um = cumsum([105, 175, 295, 340]);
    distanceLateral_um = cumsum([135, 230, 130, 340]);

    fileListString = string(tableData.Archivo);

    globalPlaqueID = 0;

    for n_file = 1:nImages

        filename = char(string(listFiles{n_file}));
        fprintf('Processing APP plaque image %d/%d: %s\n', n_file, nImages, filename);

        excelRow = find(fileListString == string(filename), 1, 'first');

        if isempty(excelRow)
            warning('File %s was not found in APP-filtered Excel table. Skipping.', filename);
            continue;
        end

        xyResolution = tableData.ResolucionXY_um_pxl(excelRow);
        zResolution = tableData.ResolucionZ_um_pxl(excelRow);
        correctionFactor = tableData.Correction_Factor(excelRow);

        cortexArea = char(string(tableData.Zona(excelRow)));
        modelType = char(string(tableData.Modelo(excelRow)));
        layerInformationAvailable = getLayerInformationAvailability(tableData, excelRow);
        noLayerInformationLabel = string(analysisConfig.layers.noInformationLabel);

        %% Load data

        imgMask = logical(readStackTif(fullfile(pathImgMask, modelType, [filename, '.tif'])));

        if useVoronoi
            Scent = load(fullfile(pathCentroids, [filename, '.mat']));
            centroids = extractVariableFromMatStruct_PlaqueInfo(Scent, 'centroids');
            Svor = load(fullfile(voronoiPath, modelType, [filename, '.mat']), ...
                'good_neighbours', 'vornb', 'total_Distance_Neighbours_1', ...
                'total_Surface_Area_1', 'total_Volum_1', 'neib_number');
        else
            microgliaFile = fullfile(pathImgMicroglia, modelType, [filename, '.tif']);
            microgliaLabels = readStackTif(microgliaFile);
            centroids = extractInstanceCentroids(microgliaLabels);
            clear microgliaLabels;
            Svor = struct();
        end

        imgPlaque = readStackTif(fullfile(pathPlaques, [filename, '.tif']));
        imgPlaqueDilated = readStackTif(fullfile(pathDilatedPlaques, [filename, '.tif']));

        %% Centroid linear indices
        % Preserves original uint32 conversion.

        centroidsInd = sub2ind(size(imgMask), ...
            uint32(centroids(:,2)), ...
            uint32(centroids(:,1)), ...
            uint32(centroids(:,3)));

        %% Centroid coordinates in physical units for pairwise distances
        % Correction applied:
        %   X/Y use xyResolution.
        %   Z uses zResolution.

        centroidsPhysical = centroids;
        centroidsPhysical(:,1:2) = centroidsPhysical(:,1:2) * xyResolution * correctionFactor;
        centroidsPhysical(:,3) = centroidsPhysical(:,3) * zResolution * correctionFactor;

        %% Build target mask without creating imgOrtho as a separate full mask

        desire_pxls = [ ...
            tableData.XCorte2_pxl(excelRow), ...
            tableData.Ycorte_pxl(excelRow), ...
            tableData.Zcorte_pxl(excelRow)];

        start = [ ...
            tableData.CoordXCorte2_pxl(excelRow) + 1, ...
            tableData.CoordYCorte_pxl(excelRow) + 1, ...
            tableData.CoordZCorte_pxl(excelRow) + 1];

        x1 = start(1);
        y1 = start(2);
        z1 = start(3);

        x2 = start(1) + desire_pxls(1);
        y2 = start(2) + desire_pxls(2);
        z2 = start(3) + desire_pxls(3);

        imgTarget = false(size(imgMask));
        imgTarget(y1:y2, x1:x2, z1:z2) = imgMask(y1:y2, x1:x2, z1:z2);

        %% Plaque labels and crop-restricted label images
        % Every non-zero plaque label is retained in the output table.
        % Crop membership affects only the crop-specific flags and metrics.

        % Enumerate every connected plaque object in the full image.
        % Crop and cortical-layer membership never affect whether a row is created.
        plaqueComponents = bwconncomp(imgPlaque > 0, 26);
        nPlaquesInImage = plaqueComponents.NumObjects;

        imgPlaqueDilatedValid = imgPlaqueDilated;
        imgPlaqueDilatedValid(~imgTarget) = 0;

        %% Fast centroid label lookup
        % Equivalent to, for each plaque:
        %   imgPlaqueDilatedAux = (imgPlaqueDilatedValid == plaqueID)
        %   imgPlaqueAux        = (imgPlaqueValid == plaqueID)
        %   plaqueAssociatedMicroglia = arrayfun(@(c) imgPlaqueDilatedAux(uint32(c))>0, centroidsInd)
        %   plaqueInsideMicroglia     = arrayfun(@(c) imgPlaqueAux(uint32(c))>0, centroidsInd)

        centroidPlaqueDilatedLabels = imgPlaqueDilatedValid(centroidsInd);

        %% Voronoi reusable mask
        % good_neighbours has one entry per original microglia.
        % neib_number, total_Distance_Neighbours_1, total_Surface_Area_1
        % and total_Volum_1 already contain only Voronoi-valid cells.
        % vornb is filtered here to match those Voronoi-valid rows, but the
        % neighbour IDs inside each vornb cell are still original microglia IDs.

        if useVoronoi
            keepForVoronoi = cellfun(@(gN) ~isempty(gN), Svor.good_neighbours);
            vornb_valid = Svor.vornb(keepForVoronoi);
        else
            keepForVoronoi = false(size(centroids, 1), 1);
            vornb_valid = {};
        end

        %% Per-plaque loop

        for nPlaque = 1:nPlaquesInImage

            [tableSaveData, nTabla] = nextAvailableTableRow(tableSaveData);
            globalPlaqueID = globalPlaqueID + 1;
            plaqueVoxelIdx = plaqueComponents.PixelIdxList{nPlaque};
            sourceLabels = imgPlaque(plaqueVoxelIdx);
            sourceLabels = sourceLabels(sourceLabels > 0);
            plaqueSourceLabel = mode(double(sourceLabels));

            tableSaveData = fillPlaqueMetadata_PlaqueInfo( ...
                tableSaveData, nTabla, tableData, excelRow, filename, cortexArea, ...
                getOutputModelName(modelType, analysisConfig));

            % Contiguous identifier for every plaque object in this image.
            tableSaveData.IDPlaque(nTabla) = nPlaque;
            tableSaveData.GlobalPlaqueID(nTabla) = globalPlaqueID;

            plaqueMask = false(size(imgPlaque));
            plaqueMask(plaqueVoxelIdx) = true;
            plaqueDilatedMask = imgPlaqueDilated == plaqueSourceLabel;
            plaqueMaskInsideCrop = plaqueMask & imgTarget;
            plaqueDilatedMaskInsideCrop = plaqueDilatedMask & imgTarget;

            % isCompleted: the entire plaque is contained in the full image.
            % isInsideCrop: at least one plaque voxel lies in the valid crop.
            % isCompletedInsideCrop: every plaque voxel lies in the valid crop.
            tableSaveData.isCompleted(nTabla) = ~touchesImageBoundary(plaqueMask);
            tableSaveData.isInsideCrop(nTabla) = any(plaqueMaskInsideCrop, 'all');
            plaqueVoxelInsideCrop = imgTarget(plaqueMask);
            tableSaveData.isCompletedInsideCrop(nTabla) = ...
                ~isempty(plaqueVoxelInsideCrop) && all(plaqueVoxelInsideCrop);

            voxelVolume_um3 = xyResolution^2 * zResolution * correctionFactor^3;
            plaqueVol = nnz(plaqueMask) * voxelVolume_um3;
            plaqueVolValid = nnz(plaqueMaskInsideCrop) * voxelVolume_um3;
            plaqueDilVolValid = nnz(plaqueDilatedMaskInsideCrop) * voxelVolume_um3;

            tableSaveData.PlaqueVolume(nTabla) = plaqueVol;
            tableSaveData.PlaqueVolumeValid(nTabla) = plaqueVolValid;

            %% Microglia associated with this plaque

            plaqueAssociatedMicroglia = centroidPlaqueDilatedLabels == plaqueSourceLabel;
            plaqueInsideMicroglia = plaqueMask(centroidsInd);
            plaqueAroundMicroglia = plaqueAssociatedMicroglia & ~plaqueInsideMicroglia;

            nAssociated = sum(plaqueAssociatedMicroglia);
            nInside = sum(plaqueInsideMicroglia);
            nAround = sum(plaqueAroundMicroglia);

            tableSaveData.NAssociatedMicroglia(nTabla) = nAssociated;
            tableSaveData.NInsideMicroglia(nTabla) = nInside;
            tableSaveData.NAroundMicroglia(nTabla) = nAround;

            tableSaveData.MicrogliaDensityTotal(nTabla) = safeDivide(nAssociated, plaqueDilVolValid, 1e9);
            tableSaveData.MicrogliaDensityInside(nTabla) = safeDivide(nInside, plaqueVolValid, 1e9);
            tableSaveData.MicrogliaDensityAround(nTabla) = safeDivide(nAround, plaqueDilVolValid - plaqueVolValid, 1e9);

            %% Microglia pairwise distances

            if calculateDistances
                microgliaAssociatedCentroids = centroidsPhysical(plaqueAssociatedMicroglia, :);
    
                if size(microgliaAssociatedCentroids, 1) > 1
    
                    microgliaDist = pdist(microgliaAssociatedCentroids);
                    [~, dist] = knnsearch(microgliaAssociatedCentroids, microgliaAssociatedCentroids, 'K', 2);
                    microgliaNearestDist = dist(:, 2);
    
                    tableSaveData.MicrogliaDist_Mean(nTabla) = mean(microgliaDist);
                    tableSaveData.MicrogliaDist_Std(nTabla) = std(microgliaDist);
                    tableSaveData.MicrogliaDistToNearest_Mean(nTabla) = mean(microgliaNearestDist);
                    tableSaveData.MicrogliaDistToNearest_Std(nTabla) = std(microgliaNearestDist);
    
                else
    
                    tableSaveData.MicrogliaDist_Mean(nTabla) = NaN;
                    tableSaveData.MicrogliaDist_Std(nTabla) = NaN;
                    tableSaveData.MicrogliaDistToNearest_Mean(nTabla) = NaN;
                    tableSaveData.MicrogliaDistToNearest_Std(nTabla) = NaN;
    
                end
    
            else
                tableSaveData.MicrogliaDist_Mean(nTabla) = NaN;
                tableSaveData.MicrogliaDist_Std(nTabla) = NaN;
                tableSaveData.MicrogliaDistToNearest_Mean(nTabla) = NaN;
                tableSaveData.MicrogliaDistToNearest_Std(nTabla) = NaN;
            end

            %% Plaque centroid and cortical layer

            [py, px, pz] = ind2sub(size(plaqueMask), find(plaqueMask));
            plaqueCentroid = [mean(px), mean(py), mean(pz)];

            tableSaveData.Centroid_X(nTabla) = plaqueCentroid(1);
            tableSaveData.Centroid_Y(nTabla) = plaqueCentroid(2);
            tableSaveData.Centroid_Z(nTabla) = plaqueCentroid(3);

            distToBorder = getDistToBorderX(imgMask, plaqueCentroid, xyResolution, correctionFactor);
            tableSaveData.distToBorder(nTabla) = double(distToBorder);
            tableSaveData.LayerInformationAvailable(nTabla) = logical(layerInformationAvailable);

            if layerInformationAvailable
                if contains(string(cortexArea), 'Medial')
                    layers = ["Layer 1", "Layer 2-3", "Layer 5", "Layer 6"];
                    layerLimits = distanceMedial_um;
                else
                    layers = ["Layer 1", "Layer 2-3", "Layer 4", "Layer 5"];
                    layerLimits = distanceLateral_um;
                end

                if distToBorder > layerLimits(end)
                    tableSaveData.Layer(nTabla) = "Out of range";
                else
                    idx = find(distToBorder <= layerLimits, 1, 'first');
                    tableSaveData.Layer(nTabla) = layers(idx);
                end
            else
                tableSaveData.Layer(nTabla) = noLayerInformationLabel;
            end

            %% Voronoi data
            if useVoronoi
                % Corrected logic:
                %   plaqueAssociatedMicroglia keeps the original microglia indexing.
                %   plaqueAssociatedVoronoi is filtered to match neib_number and
                %   the other Voronoi arrays, which already contain only valid cells.
                %   vornb_valid is also filtered to Voronoi-valid cells, but the
                %   neighbour IDs inside its cells are compared against original
                %   microglia indices.
    
                plaqueAssociatedVoronoi = plaqueAssociatedMicroglia;
                plaqueAssociatedVoronoi(keepForVoronoi == 0) = [];
    
                tableSaveData.nVoronoiTotal(nTabla) = sum(plaqueAssociatedVoronoi);
                tableSaveData.VoronoisNeighsTotal_Mean(nTabla) = mean(Svor.neib_number(plaqueAssociatedVoronoi));
                tableSaveData.VoronoiDistNeighsTotal_Mean(nTabla) = mean(Svor.total_Distance_Neighbours_1(plaqueAssociatedVoronoi));
                tableSaveData.VoronoiVolumeTotal_Mean(nTabla) = mean(Svor.total_Volum_1(plaqueAssociatedVoronoi));
                tableSaveData.VoronoiSurfaceAreaTotal_Mean(nTabla) = mean(Svor.total_Surface_Area_1(plaqueAssociatedVoronoi));
    
                tableSaveData.VoronoisNeighsTotal_Std(nTabla) = std(Svor.neib_number(plaqueAssociatedVoronoi));
                tableSaveData.VoronoiDistNeighsTotal_Std(nTabla) = std(Svor.total_Distance_Neighbours_1(plaqueAssociatedVoronoi));
                tableSaveData.VoronoiVolumeTotal_Std(nTabla) = std(Svor.total_Volum_1(plaqueAssociatedVoronoi));
                tableSaveData.VoronoiSurfaceAreaTotal_Std(nTabla) = std(Svor.total_Surface_Area_1(plaqueAssociatedVoronoi));
    
                associatedOriginalIdx = find(plaqueAssociatedMicroglia);
                microgliaBorder = cellfun(@(V) all(ismember(V, associatedOriginalIdx)), vornb_valid);
    
                if sum(microgliaBorder) > 0
    
                    tableSaveData.nVoronoiBorder(nTabla) = sum(microgliaBorder);
                    tableSaveData.VoronoisNeighsBorder_Mean(nTabla) = mean(Svor.neib_number(microgliaBorder));
                    tableSaveData.VoronoiDistNeighsBorder_Mean(nTabla) = mean(Svor.total_Distance_Neighbours_1(microgliaBorder));
                    tableSaveData.VoronoiVolumeBorder_Mean(nTabla) = mean(Svor.total_Volum_1(microgliaBorder));
                    tableSaveData.VoronoiSurfaceAreaBorder_Mean(nTabla) = mean(Svor.total_Surface_Area_1(microgliaBorder));
    
                    tableSaveData.VoronoisNeighsBorder_Std(nTabla) = std(Svor.neib_number(microgliaBorder));
                    tableSaveData.VoronoiDistNeighsBorder_Std(nTabla) = std(Svor.total_Distance_Neighbours_1(microgliaBorder));
                    tableSaveData.VoronoiVolumeBorder_Std(nTabla) = std(Svor.total_Volum_1(microgliaBorder));
                    tableSaveData.VoronoiSurfaceAreaBorder_Std(nTabla) = std(Svor.total_Surface_Area_1(microgliaBorder));
    
                else
    
                    tableSaveData.nVoronoiBorder(nTabla) = 0;
                    tableSaveData.VoronoisNeighsBorder_Mean(nTabla) = NaN;
                    tableSaveData.VoronoiDistNeighsBorder_Mean(nTabla) = NaN;
                    tableSaveData.VoronoiVolumeBorder_Mean(nTabla) = NaN;
                    tableSaveData.VoronoiSurfaceAreaBorder_Mean(nTabla) = NaN;
    
                    tableSaveData.VoronoisNeighsBorder_Std(nTabla) = NaN;
                    tableSaveData.VoronoiDistNeighsBorder_Std(nTabla) = NaN;
                    tableSaveData.VoronoiVolumeBorder_Std(nTabla) = NaN;
                    tableSaveData.VoronoiSurfaceAreaBorder_Std(nTabla) = NaN;
    
                end
    
            end

        end

        clear imgMask imgTarget imgPlaque imgPlaqueDilated imgPlaqueValid imgPlaqueDilatedValid;
        clear centroidPlaqueLabels centroidPlaqueDilatedLabels;
        clear Svor centroids centroidsPhysical;
    end

    tableSaveData = trimUnusedRows(tableSaveData);

    if useVoronoi
        boundaryMode = lower(string(analysisConfig.voronoi.boundaryMode));
        if boundaryMode == "include"
            tableSaveData = removeColumnsByPattern(tableSaveData, ["VoronoiBorder", "nVoronoiBorder", "VoronoisNeighsBorder"]);
        else
            tableSaveData = removeColumnsByPattern(tableSaveData, ["VoronoiTotal", "nVoronoiTotal", "VoronoisNeighsTotal"]);
        end
    end

    if ~useVoronoi
        tableSaveData = removeColumnsByPattern(tableSaveData, ["Voronoi", "nVoronoi"]);
    end
    if ~calculateDistances
        tableSaveData = removeColumnsByPattern(tableSaveData, "MicrogliaDist");
    end

    tableSaveData = standardizeOutputTable(tableSaveData, "plaques");
    writetable(tableSaveData, fullfile(savePath, saveExcel));

end


function tf = touchesImageBoundary(binaryObject)
%TOUCHESIMAGEBOUNDARY Return true when an object reaches any array boundary.

    if ~any(binaryObject, 'all')
        tf = false;
        return;
    end

    tf = any(binaryObject(1,:,:), 'all') || ...
         any(binaryObject(end,:,:), 'all') || ...
         any(binaryObject(:,1,:), 'all') || ...
         any(binaryObject(:,end,:), 'all') || ...
         any(binaryObject(:,:,1), 'all') || ...
         any(binaryObject(:,:,end), 'all');
end


function T = fillPlaqueMetadata_PlaqueInfo(T, nRow, tableData, excelRow, filename, cortexArea, modelType)
%FILLPLAQUEMETADATA_PLAQUEINFO Write image-level metadata into one plaque-result row.

    T.File(nRow) = string(filename);
    T.CortexArea(nRow) = string(cortexArea);
    T.Mouse(nRow) = string(tableData.IDRaton(excelRow));
    T.Sex(nRow) = string(tableData.Sexo(excelRow));
    T.Section(nRow) = string(tableData.IDCorte(excelRow));
    T.Image(nRow) = string(tableData.IDImage(excelRow));
    T.Model(nRow) = string(modelType);
    T.BregmaLevel(nRow) = string(tableData.BregmaLevel(excelRow));

end


function value = extractVariableFromMatStruct_PlaqueInfo(S, preferredName)
%EXTRACTVARIABLEFROMMATSTRUCT_PLAQUEINFO Read a preferred variable from a loaded MAT structure.

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
