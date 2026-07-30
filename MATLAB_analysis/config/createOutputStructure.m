function config = createOutputStructure(config)
%CREATEOUTPUTSTRUCTURE Prepare only the output folders required by this run.
%
% Paths are always registered in config.paths so downstream modules can use
% them consistently. A directory is created only when the corresponding
% analysis or output is enabled. Optional derived-image directories remain
% uncreated until a module actually writes an image.

    root = char(config.paths.output);
    ensureFolder(root);

    dataRoot = fullfile(root, 'Data');
    config.paths.data = string(dataRoot);

    config.paths.globalResults = string(fullfile(dataRoot, 'General'));
    config.paths.layerResults = string(fullfile(dataRoot, 'Layer'));
    config.paths.plaqueResults = string(fullfile(dataRoot, 'Plaque'));
    config.paths.sphereResults = string(fullfile(dataRoot, 'Spheres'));

    useGlobal = config.analyses.globalMicroglia.enabled || ...
        config.analyses.globalPlaques.enabled;
    useLayers = config.analyses.layers.enabled;
    usePlaques = config.analyses.individualPlaques.enabled && config.models.ad;
    useSpheres = config.analyses.spheres.enabled;

    if useGlobal
        ensureFolder(char(config.paths.globalResults));
    end
    if useLayers
        ensureFolder(char(config.paths.layerResults));
    end
    if usePlaques
        ensureFolder(char(config.paths.plaqueResults));
    end
    if useSpheres
        ensureFolder(char(config.paths.sphereResults));
    end

    % Store optional image paths without creating them. Each producing
    % module creates its directory only immediately before writing a file.
    derivedRoot = fullfile(root, 'DerivedImages');
    config.paths.derived = string(derivedRoot);
    config.paths.derivedDilatedPlaques = string(fullfile(derivedRoot, 'DilatedPlaques'));
    config.paths.derivedSpheres = string(fullfile(derivedRoot, 'Spheres'));
    config.paths.derivedLayers = string(fullfile(derivedRoot, 'Layers'));
    config.paths.derivedADNoPlaques = string(fullfile(derivedRoot, 'ADNoPlaques'));
    config.paths.derivedADPlaques = string(fullfile(derivedRoot, 'ADPlaques'));

    % These two folders are always used in every run.
    config.paths.logs = string(fullfile(root, 'Log'));
    config.paths.configuration = string(fullfile(root, 'Configuration'));
    ensureFolder(char(config.paths.logs));
    ensureFolder(char(config.paths.configuration));
end

function ensureFolder(folderPath)
%ENSUREFOLDER Create a directory only when requested by the caller.
    if ~isfolder(folderPath)
        mkdir(folderPath);
    end
end
