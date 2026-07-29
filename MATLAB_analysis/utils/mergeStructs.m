function output = mergeStructs(base, override)
%MERGESTRUCTS Recursively merge an override structure into a base structure.
    output = base;
    names = fieldnames(override);
    for i = 1:numel(names)
        name = names{i};
        if isfield(output, name) && isstruct(output.(name)) && isstruct(override.(name))
            output.(name) = mergeStructs(output.(name), override.(name));
        else
            output.(name) = override.(name);
        end
    end
end
