function flags = parseLogicalFlag(values, defaultValue)
%PARSELOGICALFLAG Convert common logical, numeric, and text flags to logical values.
%
% Inputs
%   values       Scalar or array containing logical, numeric, string, char,
%                categorical, or cell values.
%   defaultValue Value assigned to missing or unrecognized entries.
%
% Output
%   flags        Logical array with the same number of elements as values.

    if nargin < 2
        defaultValue = false;
    end
    defaultValue = logical(defaultValue);

    if islogical(values)
        flags = values;
        return;
    end

    if isnumeric(values)
        flags = repmat(defaultValue, size(values));
        valid = isfinite(values);
        flags(valid) = values(valid) ~= 0;
        flags = logical(flags);
        return;
    end

    textValues = lower(strtrim(string(values)));
    flags = repmat(defaultValue, size(textValues));

    trueTokens = ["1", "true", "yes", "y", "si", "sí", "use", ...
        "include", "included", "selected", "layer", "layers"];
    falseTokens = ["0", "false", "no", "n", "exclude", "excluded", ...
        "skip", "none", "noinfo", "na", "n/a"];

    flags(ismember(textValues, trueTokens)) = true;
    flags(ismember(textValues, falseTokens)) = false;
    flags = logical(flags);
end
