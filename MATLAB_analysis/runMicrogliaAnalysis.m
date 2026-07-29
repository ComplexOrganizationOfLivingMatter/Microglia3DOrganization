function runMicrogliaAnalysis(configInput)
%RUNMICROGLIAANALYSIS Execute the configurable microglia analysis pipeline.

    projectRoot = fileparts(mfilename('fullpath'));
    addpath(genpath(projectRoot));

    if nargin < 1 || isempty(configInput)
        config = configureMicrogliaAnalysisInteractive();
    elseif ischar(configInput) || isstring(configInput)
        config = loadMicrogliaConfig(configInput);
    elseif isstruct(configInput)
        config = configInput;
    else
        error('configInput must be empty, a configuration structure, or a JSON/MAT file path.');
    end

    config = validateMicrogliaConfig(config);
    config = createOutputStructure(config);
    saveMicrogliaConfig(config, config.paths.configuration);
    appendPipelineLog(config.paths.logs, 'Pipeline', 'STARTED', 'Microglia analysis started.');

    metadataFile = runLoggedStage(config, 'Metadata preparation', ...
        @() prepareNormalizedMetadata(config));
    metadataCleanup = onCleanup(@() removeTemporaryMetadata(metadataFile, config)); %#ok<NASGU>
    derivedCleanup = onCleanup(@() cleanupTemporaryDerivedImages(config)); %#ok<NASGU>

    [metadataPath, metadataName, metadataExt] = fileparts(metadataFile);
    metadataName = [metadataName metadataExt];

    dilatedPlaquePath = runLoggedStage(config, 'Dilated plaque preparation', ...
        @() prepareDilatedPlaques(config, metadataPath, metadataName));

    try
        if config.analyses.globalMicroglia.enabled
            runLoggedStage(config, 'Global analysis', @() analyzeGlobalImageData( ...
                config.paths.masks, config.paths.microglia, config.paths.plaques, ...
                dilatedPlaquePath, config.paths.voronoiCentroids, config.paths.voronoiResults, ...
                metadataName, metadataPath, config.outputFiles.globalData, ...
                config.paths.globalResults, config.outputs.saveADNoPlaquesImages, ...
                config.outputs.saveADPlaquesImages, config));
        end

        if config.analyses.individualPlaques.enabled && config.models.ad
            runLoggedStage(config, 'Individual plaque analysis', @() analyzeIndividualPlaques( ...
                config.paths.masks, config.paths.microglia, config.paths.voronoiCentroids, dilatedPlaquePath, ...
                config.paths.plaques, config.paths.voronoiResults, metadataName, metadataPath, ...
                config.paths.plaqueResults, config.outputFiles.individualPlaques, config));
        end

        if config.analyses.layers.enabled
            runLoggedStage(config, 'Cortical layer analysis', @() analyzeCorticalLayers( ...
                config.paths.masks, config.paths.plaques, config.paths.microglia, ...
                config.paths.voronoiCentroids, dilatedPlaquePath, config.paths.voronoiResults, ...
                metadataPath, metadataName, config.outputFiles.layers, ...
                config.paths.layerResults, config.outputs.saveLayerImages, config));
        end

        if config.analyses.spheres.enabled
            if config.spheres.mode == "generate"
                runLoggedStage(config, 'Sphere definition generation', @() generateSphereDefinitions( ...
                    config.paths.plaques, config.paths.masks, metadataName, metadataPath, ...
                    config.paths.sphereResults, config.spheres.radiusPairs_um, ...
                    config.outputs.saveSphereImages, config));
            end

            runLoggedStage(config, 'Sphere analysis', @() analyzeSphereData( ...
                config.paths.plaques, dilatedPlaquePath, config.paths.masks, ...
                config.paths.microglia, config.paths.voronoiCentroids, config.paths.voronoiResults, metadataName, ...
                metadataPath, config.paths.sphereResults, config.outputFiles.spheres, ...
                config.spheres.radiusPairs_um, config));
        end

        appendPipelineLog(config.paths.logs, 'Pipeline', 'COMPLETED', ...
            sprintf('Results written to %s', config.paths.output));
    catch ME
        appendPipelineLog(config.paths.logs, 'Pipeline', 'ERROR', ...
            'Pipeline stopped because a stage failed.', ME);
        rethrow(ME);
    end

    fprintf('\nMicroglia analysis completed. Results were written to:\n%s\n', config.paths.output);
end

function varargout = runLoggedStage(config, stageName, stageFunction)
%RUNLOGGEDSTAGE Execute one stage and record start, completion, or failure.
    appendPipelineLog(config.paths.logs, stageName, 'STARTED', '');
    stageTimer = tic;
    try
        [varargout{1:nargout}] = stageFunction();
        elapsedSeconds = toc(stageTimer);
        appendPipelineLog(config.paths.logs, stageName, 'COMPLETED', ...
            sprintf('Elapsed time: %.2f seconds.', elapsedSeconds));
    catch ME
        elapsedSeconds = toc(stageTimer);
        appendPipelineLog(config.paths.logs, stageName, 'ERROR', ...
            sprintf('Failed after %.2f seconds.', elapsedSeconds), ME);
        rethrow(ME);
    end
end

function removeTemporaryMetadata(metadataFile, config)
%REMOVETEMPORARYMETADATA Delete the normalized metadata copy when requested.
    if isfield(config, 'runtime') && isfield(config.runtime, 'temporaryMetadata') ...
            && config.runtime.temporaryMetadata && isfile(metadataFile)
        delete(metadataFile);
    end
end
