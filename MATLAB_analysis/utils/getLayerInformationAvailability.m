function availability = getLayerInformationAvailability(metadataTable, rowIndex)
%GETLAYERINFORMATIONAVAILABILITY Read normalized layer-eligibility metadata.
%
% Inputs
%   metadataTable Normalized metadata table.
%   rowIndex      Optional scalar or vector of table row indices.
%
% Output
%   availability  Logical scalar or vector. If no layer-selection column is
%                 present, all requested rows are treated as available.

    if ismember('LayerInformationAvailable', metadataTable.Properties.VariableNames)
        availability = parseLogicalFlag(metadataTable.LayerInformationAvailable, true);
    elseif ismember('Layers', metadataTable.Properties.VariableNames)
        availability = parseLogicalFlag(metadataTable.Layers, true);
    else
        availability = true(height(metadataTable), 1);
    end

    if nargin >= 2 && ~isempty(rowIndex)
        availability = availability(rowIndex);
    end
end
