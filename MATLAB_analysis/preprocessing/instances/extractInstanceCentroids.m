function [centroidsXYZ_px, labelIDs] = extractInstanceCentroids(labelImage)
%EXTRACTINSTANCECENTROIDS Calculate object centroids from a labeled 3-D image.
%
% Inputs
%   labelImage       Labeled instance segmentation. Background must be zero.
%
% Outputs
%   centroidsXYZ_px  N-by-3 centroid matrix in [X, Y, Z] pixel coordinates.
%   labelIDs         N-by-1 vector containing the corresponding label values.

    if isempty(labelImage)
        centroidsXYZ_px = zeros(0, 3);
        labelIDs = zeros(0, 1, 'like', labelImage);
        return;
    end

    stats = regionprops3(labelImage, {'Centroid', 'Volume'});
    if isempty(stats)
        centroidsXYZ_px = zeros(0, 3);
        labelIDs = zeros(0, 1, 'like', labelImage);
        return;
    end

    valid = stats.Volume > 0 & all(isfinite(stats.Centroid), 2);
    centroidsXYZ_px = stats.Centroid(valid, :);
    labelIDs = find(valid);
end
