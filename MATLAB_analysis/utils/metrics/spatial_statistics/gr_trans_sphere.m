function [radiusCenters, pairCorrelation] = gr_trans_sphere(points, sphereRadius, radiusEdges)
%GR_TRANS_SPHERE Estimate g(r) in a spherical window with edge correction.
%
% Inputs
%   points        N-by-3 coordinates centered at the origin.
%   sphereRadius  Observation-window radius.
%   radiusEdges   Increasing pair-distance bin edges.
%
% Outputs
%   radiusCenters Equal-volume representative radius for each bin.
%   pairCorrelation Translation-corrected pair-correlation estimate.

    windowVolume = (4/3) * pi * sphereRadius^3;
    numberOfPoints = size(points, 1);

    lowerEdges = radiusEdges(1:end-1);
    upperEdges = radiusEdges(2:end);
    radiusCenters = ((upperEdges.^3 + lowerEdges.^3) / 2).^(1/3);
    shellVolumes = (4/3) * pi * (upperEdges.^3 - lowerEdges.^3);

    if numberOfPoints < 2
        pairCorrelation = zeros(size(radiusCenters));
        return;
    end

    squaredNorm = sum(points.^2, 2);
    squaredDistances = max(0, squaredNorm + squaredNorm' - 2 * (points * points'));
    pairDistances = sqrt(squaredDistances(triu(true(numberOfPoints), 1)));

    intersectionVolume = volIntersectEqualSpheres(sphereRadius, pairDistances);
    observableFraction = intersectionVolume ./ windowVolume;
    observableFraction(observableFraction == 0) = Inf;
    pairWeights = 1 ./ observableFraction;

    binIndex = discretize(pairDistances, radiusEdges);
    numberOfBins = numel(radiusCenters);
    if ~all(isnan(binIndex))
        weightedCounts = accumarray(binIndex(~isnan(binIndex)), pairWeights(~isnan(binIndex)), ...
            [numberOfBins, 1], @sum, 0);
    else
        weightedCounts = zeros(numberOfBins, 1);
    end

    pairCorrelation = windowVolume / (numberOfPoints * (numberOfPoints - 1)) ...
        * (2 * weightedCounts(:)') ./ max(shellVolumes, eps);
    pairCorrelation = pairCorrelation(:);
end
