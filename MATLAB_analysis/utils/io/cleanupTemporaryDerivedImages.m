function cleanupTemporaryDerivedImages(config)
%CLEANUPTEMPORARYDERIVEDIMAGES Remove temporary plaque images and empty parents.
%
% DerivedImages/DilatedPlaques is always removed when plaque dilation was
% configured as temporary. DerivedImages itself is removed only when empty.

    if ~isfield(config, 'dilatedPlaques') || ...
            string(config.dilatedPlaques.mode) ~= "generate-temporary"
        return;
    end

    dilatedFolder = char(config.paths.derivedDilatedPlaques);
    if isfolder(dilatedFolder)
        rmdir(dilatedFolder, 's');
    end

    derivedRoot = char(config.paths.derived);
    if isfolder(derivedRoot)
        contents = dir(derivedRoot);
        names = {contents.name};
        names = names(~ismember(names, {'.', '..'}));
        if isempty(names)
            rmdir(derivedRoot);
        end
    end
end
