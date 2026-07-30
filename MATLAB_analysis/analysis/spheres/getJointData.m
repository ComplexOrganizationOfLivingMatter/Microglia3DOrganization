function tableData = getJointData(tableData, selectionMode, savePath, outputRow, filename) %#ok<INUSD>
%GETJOINTDATA Aggregate sphere-level Voronoi distributions for one image.
%
% selectionMode is retained for API compatibility but is not included in
% output folder or file names.

    variableRoot = fullfile(savePath, 'Voronoi', 'IndividualSpheres', 'Variables');
    summaryVariableRoot = fullfile(savePath, 'Voronoi', 'CombinedSphereSummary', 'Variables');
    summaryGraphRoot = fullfile(savePath, 'Voronoi', 'CombinedSphereSummary', 'Graphs');

    sphereTypes = {'WTSpheres','PlaqueSpheres','NonPlaqueSpheres'};
    suffixes = {'WTSpheres','PlaqueSpheres','NonPlaqueSpheres'};

    for i = 1:numel(sphereTypes)
        sphereType = sphereTypes{i};
        suffix = suffixes{i};

        neighbours = collectMetric(variableRoot, 'NeighboursDistribution', sphereType, filename, 'neib_numberSP');
        distances = collectMetric(variableRoot, 'NeighboursDistanceDistribution', sphereType, filename, 'total_Distance_Neighbours_1');
        volumes = collectMetric(variableRoot, 'VolumeDistribution', sphereType, filename, 'total_Volum_1');
        surfaces = collectMetric(variableRoot, 'SurfaceAreaDistribution', sphereType, filename, 'total_Surface_Area_1');

        if isempty(neighbours) && isempty(distances) && isempty(volumes) && isempty(surfaces)
            continue;
        end

        tableData.(sprintf('nVoronoiMicroglia%s', suffix))(outputRow) = numel(neighbours);
        tableData.(sprintf('meanNeighboursVoronoi%s', suffix))(outputRow) = meanFinite(neighbours);
        tableData.(sprintf('stdNeighboursVoronoi%s', suffix))(outputRow) = stdFinite(neighbours);
        tableData.(sprintf('meanSurfaceAreaVoronoi%s', suffix))(outputRow) = meanFinite(surfaces);
        tableData.(sprintf('stdSurfaceAreaVoronoi%s', suffix))(outputRow) = stdFinite(surfaces);
        tableData.(sprintf('meanVolumeVoronoi%s', suffix))(outputRow) = meanFinite(volumes);
        tableData.(sprintf('stdVolumeVoronoi%s', suffix))(outputRow) = stdFinite(volumes);
        tableData.(sprintf('meanDistanceNeighboursVoronoi%s', suffix))(outputRow) = meanFinite(distances);
        tableData.(sprintf('stdDistanceNeighboursVoronoi%s', suffix))(outputRow) = stdFinite(distances);

        saveCombinedMetric(summaryVariableRoot, 'NeighboursDistribution', sphereType, filename, 'neighbours', neighbours);
        saveCombinedMetric(summaryVariableRoot, 'NeighboursDistanceDistribution', sphereType, filename, 'neighbourDistances', distances);
        saveCombinedMetric(summaryVariableRoot, 'VolumeDistribution', sphereType, filename, 'volumes', volumes);
        saveCombinedMetric(summaryVariableRoot, 'SurfaceAreaDistribution', sphereType, filename, 'surfaceAreas', surfaces);

        graphName = sprintf('%s.png', filename);
        saveVoronoiDistributionGraph(neighbours, fullfile(summaryGraphRoot, 'NeighboursDistribution', sphereType, graphName), 'Number of neighbours');
        saveVoronoiDistributionGraph(distances, fullfile(summaryGraphRoot, 'NeighboursDistanceDistribution', sphereType, graphName), 'Neighbour distance (um)');
        saveVoronoiDistributionGraph(volumes, fullfile(summaryGraphRoot, 'VolumeDistribution', sphereType, graphName), 'Voronoi cell volume (um^3)');
        saveVoronoiDistributionGraph(surfaces, fullfile(summaryGraphRoot, 'SurfaceAreaDistribution', sphereType, graphName), 'Voronoi cell surface area (um^2)');
    end
end

function values = collectMetric(rootPath, metricFolder, sphereType, filename, variableName)
    folder = fullfile(rootPath, metricFolder, sphereType);
    files = dir(fullfile(folder, sprintf('%s_*.mat', filename)));
    values = [];
    for k = 1:numel(files)
        S = load(fullfile(files(k).folder, files(k).name), variableName);
        if isfield(S, variableName)
            values = [values; S.(variableName)(:)]; %#ok<AGROW>
        end
    end
end

function saveCombinedMetric(rootPath, metricFolder, sphereType, filename, variableName, values)
    folder = fullfile(rootPath, metricFolder, sphereType);
    if ~isfolder(folder), mkdir(folder); end
    S = struct();
    S.(variableName) = values;
    save(fullfile(folder, sprintf('%s.mat', filename)), '-struct', 'S');
end

function value = meanFinite(values)
    values = values(isfinite(values));
    if isempty(values), value = NaN; else, value = mean(values); end
end

function value = stdFinite(values)
    values = values(isfinite(values));
    if isempty(values), value = NaN; else, value = std(values); end
end
