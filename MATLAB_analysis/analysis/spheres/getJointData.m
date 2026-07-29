function tableData = getJointData(tableData, selectionMode, savePath, outputRow, filename)
%GETJOINTDATA Aggregate sphere-level Voronoi distributions for one image.

    if contains(string(selectionMode), "NoBorder", 'IgnoreCase', true)
        modeFolder = 'FullyContainedCells';
    else
        modeFolder = 'IntersectingCells';
    end

    variableRoot = fullfile(savePath, 'Voronoi', modeFolder, 'Variables');
    summaryRoot = fullfile(savePath, 'CombinedSphereSummary', modeFolder, 'Variables');

    sphereTypes = {'WTSpheres','PlaqueSpheres','NonPlaqueSpheres'};
    suffixes = {'WTSpheres','PlaqueSpheres','NonPlaqueSpheres'};

    for i = 1:numel(sphereTypes)
        sphereType = sphereTypes{i};
        suffix = suffixes{i};

        neighbours = collectMetric(variableRoot, 'NeighboursDistribution', sphereType, filename, 'neib_numberSP');
        distances = collectMetric(variableRoot, 'NeighboursDistanceDistribution', sphereType, filename, 'total_Distance_Neighbours_1');
        volumes = collectMetric(variableRoot, 'VolumeDistribution', sphereType, filename, 'total_Volum_1');
        surfaces = collectMetric(variableRoot, 'SurfaceAreaDistribution', sphereType, filename, 'total_Surface_Area_1');

        if isempty(neighbours)
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

        saveCombinedMetric(summaryRoot, 'NeighboursDistribution', filename, suffix, 'neighbours', neighbours);
        saveCombinedMetric(summaryRoot, 'NeighboursDistanceDistribution', filename, suffix, 'neighbourDistances', distances);
        saveCombinedMetric(summaryRoot, 'VolumeDistribution', filename, suffix, 'volumes', volumes);
        saveCombinedMetric(summaryRoot, 'SurfaceAreaDistribution', filename, suffix, 'surfaceAreas', surfaces);
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

function saveCombinedMetric(rootPath, metricFolder, filename, suffix, variableName, values)
    folder = fullfile(rootPath, metricFolder);
    if ~isfolder(folder), mkdir(folder); end
    S = struct();
    S.(variableName) = values;
    save(fullfile(folder, sprintf('%s_%s.mat', filename, suffix)), '-struct', 'S');
end

function value = meanFinite(values)
    values = values(isfinite(values));
    if isempty(values), value = NaN; else, value = mean(values); end
end

function value = stdFinite(values)
    values = values(isfinite(values));
    if isempty(values), value = NaN; else, value = std(values); end
end
