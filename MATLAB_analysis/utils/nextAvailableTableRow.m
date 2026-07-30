function [tableData, rowIndex] = nextAvailableTableRow(tableData)
%NEXTAVAILABLETABLEROW Return an empty table row, growing the table if required.
%
% The function removes the need for arbitrary large table preallocation.

    rowIndex = findEmptyRow(tableData);
    if ~isempty(rowIndex)
        return;
    end

    if height(tableData) == 0
        error('The input table has no schema. Initialize it with one empty row before dynamic growth.');
    end

    newRow = tableData(end, :);
    variableNames = tableData.Properties.VariableNames;
    for i = 1:numel(variableNames)
        value = newRow.(variableNames{i});
        if isnumeric(value)
            newRow.(variableNames{i})(:) = NaN;
        elseif islogical(value)
            newRow.(variableNames{i})(:) = false;
        elseif isstring(value)
            newRow.(variableNames{i})(:) = "";
        elseif iscell(value)
            newRow.(variableNames{i})(:) = {[]};
        elseif iscategorical(value)
            newRow.(variableNames{i})(:) = categorical(missing);
        elseif isdatetime(value)
            newRow.(variableNames{i})(:) = NaT;
        else
            try
                newRow.(variableNames{i})(:) = missing;
            catch
                error('Unsupported table variable type for dynamic growth: %s', variableNames{i});
            end
        end
    end

    tableData = [tableData; newRow];
    rowIndex = height(tableData);
end

function rowIndex = findEmptyRow(tableData)
%FINDEMPTYROW Locate the first unused row using a stable identifier column.
    names = string(tableData.Properties.VariableNames);
    if ismember("File", names)
        values = string(tableData.File);
        rowIndex = find(values == "" | ismissing(values), 1, 'first');
    elseif ismember("IDSphere", names)
        values = tableData.IDSphere;
        rowIndex = find(isnan(values), 1, 'first');
    else
        rowIndex = [];
    end
end
