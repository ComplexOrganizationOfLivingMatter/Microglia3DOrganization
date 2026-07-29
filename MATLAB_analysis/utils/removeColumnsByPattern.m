function tableData = removeColumnsByPattern(tableData, patterns)
%REMOVECOLUMNSBYPATTERN Remove table variables whose names contain a pattern.

    if isempty(tableData)
        return;
    end
    names = string(tableData.Properties.VariableNames);
    removeMask = false(size(names));
    for pattern = string(patterns)
        removeMask = removeMask | contains(names, pattern, 'IgnoreCase', true);
    end
    if any(removeMask)
        tableData = removevars(tableData, cellstr(names(removeMask)));
    end
end
