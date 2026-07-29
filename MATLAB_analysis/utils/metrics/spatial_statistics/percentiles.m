function values = percentiles(data, requestedPercentiles)
%PERCENTILES Compute column-wise percentiles without additional toolboxes.
%
% Inputs
%   data                 Matrix with observations in rows.
%   requestedPercentiles Percentile values in the interval [0, 100].
%
% Output
%   values               One row per requested percentile and one column per input column.

    if isrow(requestedPercentiles)
        requestedPercentiles = requestedPercentiles(:);
    end
    sortedData = sort(data, 1);
    numberOfRows = size(sortedData, 1);
    position = requestedPercentiles / 100 * (numberOfRows - 1) + 1;
    lowerIndex = max(1, min(numberOfRows, floor(position)));
    upperIndex = max(1, min(numberOfRows, ceil(position)));
    weight = position - lowerIndex;
    values = (1 - weight) .* sortedData(lowerIndex, :) + weight .* sortedData(upperIndex, :);
end
