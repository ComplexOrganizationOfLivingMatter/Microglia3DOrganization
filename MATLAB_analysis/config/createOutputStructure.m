function config = createOutputStructure(config)
%CREATEOUTPUTSTRUCTURE Create the standardized result tree.
%
% Data tables, variables, and figures are grouped under Data. Derived image
% folders are not created here; each module creates only the folders that it
% actually needs.

    root = char(config.paths.output);
    if ~isfolder(root)
        mkdir(root);
    end

    dataRoot = makeFolder(root, 'Data');
    config.paths.data = string(dataRoot);
    config.paths.globalResults = string(makeFolder(dataRoot, 'General'));
    config.paths.layerResults = string(makeFolder(dataRoot, 'Layer'));
    config.paths.plaqueResults = string(makeFolder(dataRoot, 'Plaque'));
    config.paths.sphereResults = string(makeFolder(dataRoot, 'Spheres'));

    % Store intended paths without creating optional image folders.
    derivedRoot = fullfile(root, 'DerivedImages');
    config.paths.derived = string(derivedRoot);
    config.paths.derivedDilatedPlaques = string(fullfile(derivedRoot, 'DilatedPlaques'));
    config.paths.derivedSpheres = string(fullfile(derivedRoot, 'Spheres'));
    config.paths.derivedLayers = string(fullfile(derivedRoot, 'Layers'));
    config.paths.derivedADNoPlaques = string(fullfile(derivedRoot, 'ADNoPlaques'));
    config.paths.derivedADPlaques = string(fullfile(derivedRoot, 'ADPlaques'));

    % Logs are available for every pipeline stage.
    config.paths.logs = string(makeFolder(root, 'Log'));
    config.paths.configuration = string(makeFolder(root, 'Configuration'));
end

function p = makeFolder(root, name)
%MAKEFOLDER Create an output subfolder and return its path.
    p = fullfile(root, name);
    if ~isfolder(p)
        mkdir(p);
    end
end
