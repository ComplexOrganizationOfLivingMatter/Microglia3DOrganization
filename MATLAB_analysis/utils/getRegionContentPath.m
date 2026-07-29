function outputPath = getRegionContentPath(basePath, regionName, contentName)
%GETREGIONCONTENTPATH Build nested region/content output paths.
%
% Example: getRegionContentPath(base, "Lateral", "Graph") returns
% base/Lateral/Graph rather than a concatenated folder such as LateralGraph.

    outputPath = string(fullfile(char(basePath), char(string(regionName)), char(string(contentName))));
    if ~isfolder(outputPath)
        mkdir(outputPath);
    end
end
