function availability = resolveLayerImageSelection(metadataTable, config)
%RESOLVELAYERIMAGESELECTION Determine which metadata rows have valid layer information.
%
% Inputs
%   metadataTable Source metadata table using the user-selected column names.
%   config        Complete pipeline configuration.
%
% Output
%   availability  Logical vector with one value per metadata row.
%
% Selection modes
%   "all"    Every row has valid layer information.
%   "excel"  Values are parsed from a configured metadata column.
%   "manual" Rows are selected by filename from the configuration.

    nRows = height(metadataTable);
    mode = string(config.layers.imageSelection.mode);

    switch mode
        case "excel"
            columnName = string(config.layers.imageSelection.column);
            if strlength(columnName) == 0
                columnName = string(config.metadata.columns.layersEnabled);
            end
            if strlength(columnName) == 0 || ~ismember(columnName, string(metadataTable.Properties.VariableNames))
                error('The configured layer-selection column was not found in the metadata table.');
            end
            availability = parseLogicalFlag(metadataTable.(columnName), false);

        case "manual"
            fileColumn = string(config.metadata.columns.fileName);
            if ~ismember(fileColumn, string(metadataTable.Properties.VariableNames))
                error('The configured filename column was not found in the metadata table.');
            end
            selectedFiles = string(config.layers.imageSelection.selectedFiles);
            selectedFiles = selectedFiles(~ismissing(selectedFiles) & strlength(strtrim(selectedFiles)) > 0);
            availability = ismember(string(metadataTable.(fileColumn)), selectedFiles);

        otherwise
            availability = true(nRows, 1);
    end

    availability = logical(reshape(availability, [], 1));
end
