function dilatedPath = prepareDilatedPlaques(config, metadataPath, metadataName)
%PREPAREDILATEDPLAQUES Resolve existing, persistent, temporary, or unused plaque dilation.
%
% Temporary dilated plaques are created under DerivedImages/DilatedPlaques
% and removed by runMicrogliaAnalysis after the pipeline finishes or fails.

    if ~config.models.ad
        dilatedPath = "";
        return;
    end

    switch string(config.dilatedPlaques.mode)
        case "existing"
            dilatedPath = string(config.paths.dilatedPlaques);

        case "generate-temporary"
            dilatedPath = string(config.paths.derivedDilatedPlaques);
            ensureCleanFolder(dilatedPath);
            generateDilatedPlaques(config.paths.plaques, dilatedPath, metadataName, ...
                metadataPath, config.dilatedPlaques.radius_um);

        otherwise
            dilatedPath = string(config.paths.derivedDilatedPlaques);
            if ~isfolder(dilatedPath)
                mkdir(dilatedPath);
            end
            generateDilatedPlaques(config.paths.plaques, dilatedPath, metadataName, ...
                metadataPath, config.dilatedPlaques.radius_um);
    end
end

function ensureCleanFolder(folderPath)
%ENSURECLEANFOLDER Recreate a folder so stale temporary files cannot persist.
    folderPath = char(folderPath);
    if isfolder(folderPath)
        rmdir(folderPath, 's');
    end
    mkdir(folderPath);
end
