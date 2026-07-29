function tableData = trimUnusedRows(tableData)
%TRIMUNUSEDROWS Remove unused rows from dynamically grown result tables.

    if isempty(tableData)
        return;
    end

    names = string(tableData.Properties.VariableNames);
    if ismember("File", names)
        keep = string(tableData.File) ~= "" & ~ismissing(string(tableData.File));
    elseif ismember("IDSphere", names)
        keep = ~isnan(tableData.IDSphere);
    else
        return;
    end
    tableData = tableData(keep, :);
end
