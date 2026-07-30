function [validCells, meanNeighbours, stdNeighbours, meanSurface, stdSurface, ...
    meanVolume, stdVolume, meanNeighbourDistance, stdNeighbourDistance] = ...
    getVoronoiSphereData(goodNeighbours, neighbourCount, sphereCentroid, radius, ...
    voronoiNeighbours, sphereMicrogliaCentroids, savePath, sphereType, filename, ...
    sphereID, selectionMode, xyResolution, correctionFactor, imageSize, ...
    allMicrogliaCentroids, colours, nearestPlaqueDistance, isCompleted) %#ok<INUSD>
%GETVORONOISPHEREDATA Calculate and save Voronoi metrics for one sphere.
%
% selectionMode affects cell selection only. It is intentionally not used in
% output folder or file names.

    isFullyContained = contains(string(selectionMode), "NoBorder", 'IgnoreCase', true);

    selectedCells = false(numel(goodNeighbours), 1);
    sphereCentroidYXZ = double(sphereCentroid);
    sphereCentroidYXZ(:, [1 2]) = sphereCentroidYXZ(:, [2 1]);

    for cellIndex = 1:numel(goodNeighbours)
        vertices = goodNeighbours{cellIndex};
        if isempty(vertices)
            continue;
        end

        verticesYXZ = double(vertices);
        verticesYXZ(:, [1 2]) = verticesYXZ(:, [2 1]);

        if isFullyContained
            selectedCells(cellIndex) = all(vecnorm(verticesYXZ - sphereCentroidYXZ, 2, 2) < radius);
        else
            shape = alphaShape(verticesYXZ);
            shape.Alpha = 25 * shape.Alpha;
            selectedCells(cellIndex) = any(inShape(shape, sphereMicrogliaCentroids));
        end
    end

    originalValidCells = find(~cellfun(@isempty, goodNeighbours));
    selectedOriginalCells = find(selectedCells);
    selectedRows = find(ismember(originalValidCells, selectedOriginalCells));

    selectedRows = selectedRows(selectedRows >= 1 & selectedRows <= numel(neighbourCount));
    neighbourValues = double(neighbourCount(selectedRows));
    volumes = zeros(numel(selectedOriginalCells), 1);
    surfaces = zeros(numel(selectedOriginalCells), 1);
    neighbourDistances = nan(numel(selectedOriginalCells), 1);

    for outputIndex = 1:numel(selectedOriginalCells)
        cellIndex = selectedOriginalCells(outputIndex);
        vertices = double(goodNeighbours{cellIndex});
        shape = alphaShape(vertices);
        shape.Alpha = 25 * shape.Alpha;

        volumes(outputIndex) = volume(shape) * xyResolution^3 * correctionFactor^3;
        surfaces(outputIndex) = surfaceArea(shape) * xyResolution^2 * correctionFactor^2;

        neighbourIDs = double(voronoiNeighbours{cellIndex});
        neighbourIDs = neighbourIDs(neighbourIDs >= 1 & neighbourIDs <= size(allMicrogliaCentroids, 1));

        if cellIndex <= size(allMicrogliaCentroids, 1) && ~isempty(neighbourIDs)
            sourcePoint = double(allMicrogliaCentroids(cellIndex, :));
            neighbourPoints = double(allMicrogliaCentroids(neighbourIDs, :));
            distances = vecnorm(neighbourPoints - sourcePoint, 2, 2) ...
                * xyResolution * correctionFactor;
            distances = distances(isfinite(distances) & distances > 0);
            if ~isempty(distances)
                neighbourDistances(outputIndex) = mean(distances);
            end
        end
    end

    validCells = numel(selectedOriginalCells);
    meanNeighbours = meanOrNaN(neighbourValues);
    stdNeighbours = stdOrNaN(neighbourValues);
    meanSurface = meanOrNaN(surfaces);
    stdSurface = stdOrNaN(surfaces);
    meanVolume = meanOrNaN(volumes);
    stdVolume = stdOrNaN(volumes);
    meanNeighbourDistance = meanOrNaN(neighbourDistances);
    stdNeighbourDistance = stdOrNaN(neighbourDistances);

    sphereType = char(strip(string(sphereType), '/'));
    fileStem = sprintf('%s_%s.mat', filename, string(sphereID));
    variableRoot = fullfile(savePath, 'Voronoi', 'IndividualSpheres', 'Variables');
    graphRoot = fullfile(savePath, 'Voronoi', 'IndividualSpheres', 'Graphs');

    saveMetric(fullfile(variableRoot, 'NeighboursDistribution', sphereType, fileStem), 'neib_numberSP', neighbourValues);
    saveMetric(fullfile(variableRoot, 'NeighboursDistanceDistribution', sphereType, fileStem), 'total_Distance_Neighbours_1', neighbourDistances);
    saveMetric(fullfile(variableRoot, 'VolumeDistribution', sphereType, fileStem), 'total_Volum_1', volumes);
    saveMetric(fullfile(variableRoot, 'SurfaceAreaDistribution', sphereType, fileStem), 'total_Surface_Area_1', surfaces);

    if isCompleted
        graphStem = sprintf('%s_%s.png', filename, string(sphereID));
        saveVoronoiDistributionGraph(neighbourValues, fullfile(graphRoot, 'NeighboursDistribution', sphereType, graphStem), 'Number of neighbours');
        saveVoronoiDistributionGraph(neighbourDistances, fullfile(graphRoot, 'NeighboursDistanceDistribution', sphereType, graphStem), 'Neighbour distance (um)');
        saveVoronoiDistributionGraph(volumes, fullfile(graphRoot, 'VolumeDistribution', sphereType, graphStem), 'Voronoi cell volume (um^3)');
        saveVoronoiDistributionGraph(surfaces, fullfile(graphRoot, 'SurfaceAreaDistribution', sphereType, graphStem), 'Voronoi cell surface area (um^2)');
    end
end

function saveMetric(filePath, variableName, value)
    folder = fileparts(filePath);
    if ~isfolder(folder), mkdir(folder); end
    S = struct();
    S.(variableName) = value;
    save(filePath, '-struct', 'S');
end

function value = meanOrNaN(values)
    values = values(isfinite(values));
    if isempty(values), value = NaN; else, value = mean(values); end
end

function value = stdOrNaN(values)
    values = values(isfinite(values));
    if isempty(values), value = NaN; else, value = std(values); end
end
