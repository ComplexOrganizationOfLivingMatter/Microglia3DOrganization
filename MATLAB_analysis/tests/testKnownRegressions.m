function tests = testKnownRegressions
%TESTKNOWNREGRESSIONS Guard against previously reported code regressions.
    tests = functiontests(localfunctions);
end

function testCorticalLayerWorkerHasOneInput(testCase)
    verifyEqual(testCase, nargin('processCorticalLayerImage_v230'), 1);
end

function testMetricCatalogInitializes(testCase)
    catalog = getMetricCatalog();
    verifyNotEmpty(testCase, catalog);
    expectedFields = {'group','id','label','description','unit','paper'};
    verifyTrue(testCase, all(isfield(catalog, expectedFields)));
end

function testDefaultConfigurationDisablesVoronoi(testCase)
    config = createMicrogliaConfig();
    verifyFalse(testCase, config.voronoi.enabled);
    verifyFalse(testCase, config.metrics.groups.voronoi.enabled);
    verifyFalse(testCase, any(startsWith(string(config.metrics.selected), "voronoi_")));
end

function testNoLegacyMetadataFields(testCase)
    config = createMicrogliaConfig();
    verifyFalse(testCase, isfield(config.metadata.columns, 'bregmaPosition'));
    verifyFalse(testCase, isfield(config.metadata.columns, 'bregmaGroup'));
    verifyTrue(testCase, isfield(config.metadata.columns, 'bregmaLevel'));
end


function testOutputModelNameUsesAD(testCase)
    config = createMicrogliaConfig();
    verifyEqual(testCase, getOutputModelName("APP", config), "AD");
    verifyEqual(testCase, getOutputModelName("WT", config), "WT");
end

function testPaperPresetExcludesVoronoi(testCase)
    config = createMicrogliaConfig("paper_metrics");
    verifyFalse(testCase, any(startsWith(string(config.metrics.selected), "voronoi_")));
end

function testNoCommentsImmediatelyAfterContinuation(testCase)
    root = fileparts(fileparts(mfilename('fullpath')));
    files = dir(fullfile(root, '**', '*.m'));
    offenders = strings(0,1);
    for i = 1:numel(files)
        filePath = fullfile(files(i).folder, files(i).name);
        source = splitlines(string(fileread(filePath)));
        for lineIndex = 1:max(0, numel(source)-1)
            if endsWith(strtrim(source(lineIndex)), '...') && startsWith(strtrim(source(lineIndex+1)), '%')
                offenders(end+1,1) = string(filePath) + ":" + lineIndex; %#ok<AGROW>
            end
        end
    end
    verifyEmpty(testCase, offenders, sprintf('Comments found after continuation lines:\n%s', strjoin(offenders, newline)));
end

function testNoInvalidEmptyStructGrowthPattern(testCase)
    root = fileparts(fileparts(mfilename('fullpath')));
    files = dir(fullfile(root, '**', '*.m'));
    offenders = strings(0,1);
    currentTestFile = string(mfilename('fullpath')) + ".m";
    for i = 1:numel(files)
        filePath = string(fullfile(files(i).folder, files(i).name));
        if filePath == currentTestFile
            continue;
        end
        source = string(fileread(filePath));
        if contains(source, 'struct([])')
            offenders(end+1,1) = filePath; %#ok<AGROW>
        end
    end
    verifyEmpty(testCase, offenders);
end

function testModelSubfolderLoopUsesScalarIndexing(testCase)
    root = fileparts(fileparts(mfilename('fullpath')));
    validatorFile = fullfile(root, 'config', 'validation', 'validateMicrogliaConfig.m');
    source = string(fileread(validatorFile));
    legacyPattern = "for modelName = modelNames" + "'";
    verifyFalse(testCase, contains(source, legacyPattern));
    verifyTrue(testCase, contains(source, 'for modelIndex = 1:numel(modelNames)'));
    verifyTrue(testCase, contains(source, 'modelNames(end+1, 1)'));
end

function testConfiguredPathsAreValidatedAsScalars(testCase)
    root = fileparts(fileparts(mfilename('fullpath')));
    validatorFile = fullfile(root, 'config', 'validation', 'validateMicrogliaConfig.m');
    source = string(fileread(validatorFile));
    verifyTrue(testCase, contains(source, 'requireScalarPath(config.paths.masks'));
    verifyTrue(testCase, contains(source, 'requireScalarPath(config.paths.microglia'));
    workerText = fileread(fullfile(projectRoot, 'analysis', 'layers', 'processCorticalLayerImage_v230.m'));
    assert(contains(workerText, 'useVoronoi, voronoiBoundaryMode)'), ...
        'The layer worker must pass voronoiBoundaryMode explicitly to the summarization subfunction.');

end
