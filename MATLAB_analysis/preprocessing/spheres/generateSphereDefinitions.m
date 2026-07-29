function generateSphereDefinitions(plaquePath, maskPath, nameExcel, pathExcel, savePath, radiusPairs_um, saveSphereImages, analysisConfig)
%% Optimized version of getSpheres_function
%
% Same inputs as the original main function:
%
%   getSpheres_function_optimized(plaquePath, maskPath, nameExcel, pathExcel, savePath)
%
% Main changes:
%   1) Each image is loaded, cropped and resized only once.
%   2) The loop order is image -> radius, instead of radius -> image.
%   3) Plaque spheres are calculated once per image because plaque radius is fixed.
%   4) The large full 3D image returned by getSphereFromCentroid is avoided.
%      Instead, sphere indices are generated directly, slice by slice.
%   5) Sphere label images use uint8 up to label 254 and uint16 above that threshold.
%   6) Optional parfor is prepared, but disabled by default.
%
% Supporting functions used by this module:
%   readStackTif
%   writeStackTif
%   fillWithNearestSpheres
%
% Notes:
%   The plaque sphere radius is fixed:
%       radius = 100;
%   The non-plaque sphere radii are:
%       radiusNonPlaque = [50, 100];
%   Therefore the plaque radius is reused for both non-plaque radius folders.

    if ~isfolder(savePath)
        mkdir(savePath);
    end

    if nargin < 6 || isempty(radiusPairs_um), radiusPairs_um = [100 50; 100 100]; end
    if nargin < 7 || isempty(saveSphereImages), saveSphereImages = true; end
    if nargin < 8 || isempty(analysisConfig), analysisConfig = createMicrogliaConfig(); end

    useParallel = analysisConfig.parallel.enabled && analysisConfig.parallel.modules.sphereGeneration;
    derivedImageRoot = char(analysisConfig.paths.derivedSpheres);
    nWorkers = analysisConfig.parallel.numberOfWorkers;
    sizeReduction = 1;
    radiusPairs_um = double(radiusPairs_um);

    %% Load metadata table

    tableData = readtable(fullfile(pathExcel, nameExcel));
    listFiles = tableData.Archivo;
    nFiles = numel(listFiles);

    %% Prepare output folders once

    radiusFolders = cell(size(radiusPairs_um,1), 1);

    for r = 1:size(radiusPairs_um,1)

        plaqueRadius_um = radiusPairs_um(r,1);
        nonPlaqueRadius_um = radiusPairs_um(r,2);
        folderRadius = fullfile(savePath, sprintf('Plaque%d_NonPlaque%d', plaqueRadius_um, nonPlaqueRadius_um));
        radiusFolders{r} = folderRadius;

        createFolderIfNeeded(folderRadius);
        createFolderIfNeeded(fullfile(folderRadius, 'SpheresInd', 'PlaqueSpheresInd'));
        createFolderIfNeeded(fullfile(folderRadius, 'SpheresInd', 'NonPlaqueSpheresInd'));
        createFolderIfNeeded(fullfile(folderRadius, 'SpheresInd', 'WTSpheresInd'));
    end

    %% Process files

    if useParallel
        pool = gcp('nocreate');
        if isempty(pool)
            parpool('local', nWorkers);
        end

        parfor n_file = 1:nFiles
            processOneSphereImage_optimized( ...
                n_file, listFiles, tableData, ...
                plaquePath, maskPath, radiusFolders, ...
                radiusPairs_um, saveSphereImages, derivedImageRoot, ...
                sizeReduction);
        end

    else
        for n_file = 1:nFiles

            filenameBase = getListValueAsChar(listFiles, n_file);
            fprintf('Processing %d/%d: %s\n', n_file, nFiles, filenameBase);

            processOneSphereImage_optimized( ...
                n_file, listFiles, tableData, ...
                plaquePath, maskPath, radiusFolders, ...
                radiusPairs_um, saveSphereImages, derivedImageRoot, ...
                sizeReduction);
        end
    end

end


%PROCESSONESPHEREIMAGE_OPTIMIZED Generate all requested sphere definitions for one image.
function processOneSphereImage_optimized( ...
    n_file, listFiles, tableData, ...
    plaquePath, maskPath, radiusFolders, ...
    radiusPairs_um, saveSphereImages, derivedImageRoot, ...
    sizeReduction)

    tStart = tic;

    name = getListValueAsChar(listFiles, n_file);
    filename = [name, '.tif'];

    excelRow = find(string(tableData.Archivo) == string(name), 1, 'first');

    if isempty(excelRow)
        warning('File %s was not found in tableData.Archivo. Skipping.', name);
        return;
    end

    cortexArea = char(string(tableData.Zona(excelRow)));
    modelType = char(string(tableData.Modelo(excelRow)));
    outputModelType = char(getOutputModelName(modelType));

    %% Load original mask

    maskFile = fullfile(maskPath, modelType, filename);

    if ~isfile(maskFile)
        warning('Mask file not found: %s. Skipping.', maskFile);
        return;
    end

    maskImgOriginal = logical(readStackTif(maskFile));
    originalShape = size(maskImgOriginal);

    %% Load original plaque image or create empty image

    plaqueFile = fullfile(plaquePath, filename);
    hasPlaqueFile = isfile(plaqueFile);

    if hasPlaqueFile
        plaqueImgOriginal = readStackTif(plaqueFile);
    else
        plaqueImgOriginal = zeros(originalShape, 'uint16');
    end

    %% Crop valid mask without creating imgOrtho plus mask separately

    desire_pxls = [ ...
        tableData.XCorte2_pxl(excelRow), ...
        tableData.Ycorte_pxl(excelRow), ...
        tableData.Zcorte_pxl(excelRow)];

    cropStart = [ ...
        tableData.CoordXCorte2_pxl(excelRow) + 1, ...
        tableData.CoordYCorte_pxl(excelRow) + 1, ...
        tableData.CoordZCorte_pxl(excelRow) + 1];

    [x1, x2, y1, y2, z1, z2] = getClippedCropBounds(cropStart, desire_pxls, originalShape);

    maskImg = false(originalShape);
    maskImg(y1:y2, x1:x2, z1:z2) = maskImgOriginal(y1:y2, x1:x2, z1:z2);

    clear maskImgOriginal;

    %% Homogenize voxel size

    xyResolution = tableData.ResolucionXY_um_pxl(excelRow);
    zResolution = tableData.ResolucionZ_um_pxl(excelRow);
    correctionFactor = tableData.Correction_Factor(excelRow);

    homogeneousShape = [ ...
        round(originalShape(1) / sizeReduction), ...
        round(originalShape(2) / sizeReduction), ...
        round(originalShape(3) * (zResolution / xyResolution) / sizeReduction)];

    plaqueImg = imresize3(plaqueImgOriginal, homogeneousShape, 'nearest');
    clear plaqueImgOriginal;

    maskImg = logical(imresize3(maskImg, homogeneousShape, 'nearest'));

    xyResolutionHomogeneous = xyResolution * sizeReduction;

    %% Convert radii from um to homogeneous pixels

    %% For each explicit plaque/non-plaque radius pair

    for r = 1:size(radiusPairs_um,1)

        plaqueRadius_um = radiusPairs_um(r,1);
        nonPlaqueRadius_um = radiusPairs_um(r,2);
        radiusPxl = plaqueRadius_um / (xyResolutionHomogeneous * correctionFactor);
        radiusNonSpheresPxl = nonPlaqueRadius_um / (xyResolutionHomogeneous * correctionFactor);

        [basePlaqueSpheresMask, plaqueSpheresInd] = getSphereFromPlaques_fast(plaqueImg, radiusPxl);
        nValidPlaques = unique(plaqueImg(maskImg > 0));
        nValidPlaques(nValidPlaques == 0) = [];
        plaqueSpheresIndValid = filterPlaqueSpheresByValidLabels(plaqueSpheresInd, nValidPlaques);

        folderRadius = radiusFolders{r};

        imageModelFolder = fullfile(derivedImageRoot, ...
            sprintf('Plaque%d_NonPlaque%d', plaqueRadius_um, nonPlaqueRadius_um), ...
            outputModelType);

        % Important: pass a fresh copy to fillWithNearestSpheres, because the
        % function may modify the input mask.
        spheresMaskInput = basePlaqueSpheresMask;

        [spheresMask, noPlaqueSpheresInd, noPlaquesSphereCentroids] = ...
            fillWithNearestSpheres(spheresMaskInput, radiusNonSpheresPxl, maskImg);

        clear spheresMaskInput;

        spheresMask(maskImg == 0) = 0;

        % Resize output back to original dimensions.
        spheresMaskOriginalSize = imresize3(spheresMask, originalShape, 'nearest');
        clear spheresMask;

        if saveSphereImages
            createFolderIfNeeded(imageModelFolder);
            writeStackTif(castLabelImageForStorage(spheresMaskOriginalSize), ...
                fullfile(imageModelFolder, filename));
        end
        clear spheresMaskOriginalSize;

        %% Save indices and centroids

        if hasPlaqueFile
            % Preserve the expected variable name in the saved file.
            plaqueSpheresInd = plaqueSpheresIndValid; %#ok<NASGU>
            save(fullfile(folderRadius, 'SpheresInd', 'PlaqueSpheresInd', [name, '_ind.mat']), ...
                'plaqueSpheresInd', '-v7.3');

            save(fullfile(folderRadius, 'SpheresInd', 'NonPlaqueSpheresInd', [name, '_ind.mat']), ...
                'noPlaqueSpheresInd', '-v7.3');

            save(fullfile(folderRadius, 'SpheresInd', 'NonPlaqueSpheresInd', [name, '_centroids.mat']), ...
                'noPlaquesSphereCentroids', '-v7.3');

        else
            save(fullfile(folderRadius, 'SpheresInd', 'WTSpheresInd', [name, '_ind.mat']), ...
                'noPlaqueSpheresInd', '-v7.3');

            save(fullfile(folderRadius, 'SpheresInd', 'WTSpheresInd', [name, '_centroids.mat']), ...
                'noPlaquesSphereCentroids', '-v7.3');
        end

        fprintf('  radius %d finished for %s\n', nonPlaqueRadius_um, name);
    end

    fprintf('Finished %s in %.2f seconds\n', name, toc(tStart));

    clear plaqueImg maskImg basePlaqueSpheresMask plaqueSpheresInd plaqueSpheresIndValid;

end


function [spheresMask, plaqueSpheresInd] = getSphereFromPlaques_fast(plaqueImage, radius)
%GETSPHEREFROMPLAQUES_FAST Create plaque-centered sphere indices and an overlap-count mask.

    stats = regionprops3(plaqueImage, 'Centroid');

    if isempty(stats)
        centroids = zeros(0, 3);
    else
        centroids = stats.Centroid;

        if ~isempty(centroids)
            centroids(isnan(centroids(:,1)), :) = [];
        end
    end

    imageSize = size(plaqueImage);
    clear plaqueImage;

    % single uses half the memory of double and is enough for a mask/count image.
    spheresMask = zeros(imageSize, 'single');
    plaqueSpheresInd = cell(size(centroids, 1), 1);

    for i = 1:size(centroids, 1)

        sphereInd = getSphereIndicesFromCentroid_fast(centroids(i, :), radius, imageSize);

        % Store indices as uint32 to reduce MAT-file size.
        % They are converted internally only when indexing is needed.
        plaqueSpheresInd{i} = uint32(sphereInd(:)');

        if ~isempty(sphereInd)
            spheresMask(sphereInd) = spheresMask(sphereInd) + 1;
        end
    end

end


function sphereInd = getSphereIndicesFromCentroid_fast(centroidXYZ, radius, imageSize)
%% Generate sphere indices directly, without creating a full 3D sphere image.
%
% This is intentionally slice-wise:
%   - avoids allocating a full (2r+1)^3 local cube
%   - only allocates a 2D disk per z-slice

    if isempty(centroidXYZ) || isempty(radius) || isnan(radius) || radius <= 0
        sphereInd = [];
        return;
    end

    x0 = centroidXYZ(1);
    y0 = centroidXYZ(2);
    z0 = centroidXYZ(3);

    xMinGlobal = 1;
    xMaxGlobal = imageSize(2);
    yMinGlobal = 1;
    yMaxGlobal = imageSize(1);
    zMinGlobal = 1;
    zMaxGlobal = imageSize(3);

    zMin = max(zMinGlobal, floor(z0 - radius));
    zMax = min(zMaxGlobal, ceil(z0 + radius));

    if zMin > zMax
        sphereInd = [];
        return;
    end

    radius2 = radius ^ 2;

    indicesBySlice = cell(zMax - zMin + 1, 1);
    nSlicesUsed = 0;

    for z = zMin:zMax

        dz2 = (double(z) - z0) ^ 2;
        radiusXY2 = radius2 - dz2;

        if radiusXY2 < 0
            continue;
        end

        radiusXY = sqrt(radiusXY2);

        xMin = max(xMinGlobal, floor(x0 - radiusXY));
        xMax = min(xMaxGlobal, ceil(x0 + radiusXY));
        yMin = max(yMinGlobal, floor(y0 - radiusXY));
        yMax = min(yMaxGlobal, ceil(y0 + radiusXY));

        if xMin > xMax || yMin > yMax
            continue;
        end

        xRange = xMin:xMax;
        yRange = yMin:yMax;

        [Y, X] = ndgrid(yRange, xRange);

        insideDisk = ((double(X) - x0).^2 + (double(Y) - y0).^2) <= radiusXY2;

        if any(insideDisk(:))
            yInside = Y(insideDisk);
            xInside = X(insideDisk);
            zInside = repmat(z, numel(yInside), 1);

            nSlicesUsed = nSlicesUsed + 1;
            indicesBySlice{nSlicesUsed} = sub2ind(imageSize, yInside, xInside, zInside);
        end
    end

    if nSlicesUsed == 0
        sphereInd = [];
    else
        sphereInd = vertcat(indicesBySlice{1:nSlicesUsed});
    end

end


function plaqueSpheresIndValid = filterPlaqueSpheresByValidLabels(plaqueSpheresInd, nValidPlaques)
%FILTERPLAQUESPHERESBYVALIDLABELS Keep plaque spheres whose plaque labels occur inside valid tissue.

    if isempty(plaqueSpheresInd) || isempty(nValidPlaques)
        plaqueSpheresIndValid = {};
        return;
    end

    nValidPlaques = double(nValidPlaques(:));
    nValidPlaques = nValidPlaques(nValidPlaques >= 1 & nValidPlaques <= numel(plaqueSpheresInd));

    if isempty(nValidPlaques)
        plaqueSpheresIndValid = {};
        return;
    end

    plaqueSpheresIndValid = cell(numel(nValidPlaques), 1);

    for i = 1:numel(nValidPlaques)
        plaqueSpheresIndValid{i} = plaqueSpheresInd{nValidPlaques(i)};
    end

end


function [x1, x2, y1, y2, z1, z2] = getClippedCropBounds(cropStart, desire_pxls, imageSize)
%GETCLIPPEDCROPBOUNDS Convert crop metadata into image-clipped inclusive bounds.

    x1 = max(1, round(cropStart(1)));
    y1 = max(1, round(cropStart(2)));
    z1 = max(1, round(cropStart(3)));

    % Crop endpoints use inclusive indexing:
    % start:(start + desire_pxls)
    x2 = min(imageSize(2), round(cropStart(1) + desire_pxls(1)));
    y2 = min(imageSize(1), round(cropStart(2) + desire_pxls(2)));
    z2 = min(imageSize(3), round(cropStart(3) + desire_pxls(3)));

    if x2 < x1 || y2 < y1 || z2 < z1
        error('Invalid crop bounds. Check cropStart and desire_pxls values.');
    end

end


function value = getListValueAsChar(listValues, idx)
%GETLISTVALUEASCHAR Read one filename from a cell, string, or character collection.

    if iscell(listValues)
        value = char(string(listValues{idx}));
    else
        value = char(string(listValues(idx)));
    end

end


function createFolderIfNeeded(folderPath)
%CREATEFOLDERIFNEEDED Create a folder when it does not already exist.

    if ~isfolder(folderPath)
        mkdir(folderPath);
    end

end
