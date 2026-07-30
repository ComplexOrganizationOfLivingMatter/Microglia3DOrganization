function [radii, K3, L3, LminusR] = K3_trans_sphere(points, sphereRadius, radiusVector)
%K3_TRANS_SPHERE Estimate three-dimensional Ripley K with edge correction.
%
% Inputs
%   points        N-by-3 coordinates inside a sphere centered at the origin.
%   sphereRadius  Observation-window radius.
%   radiusVector  Distances at which K3 is evaluated.
%
% Outputs
%   radii         Column vector of evaluation radii.
%   K3            Translation-corrected Ripley K estimate.
%   L3            Variance-stabilized three-dimensional L transform.
%   LminusR       L3 minus radius, which is zero under ideal CSR.

    windowVolume = (4/3) * pi * sphereRadius^3;
    numberOfPoints = size(points, 1);
    radii = radiusVector(:);
    K3 = zeros(size(radii));
    L3 = zeros(size(radii));
    LminusR = zeros(size(radii));
    if numberOfPoints < 2
        return;
    end

    squaredNorm = sum(points.^2, 2);
    squaredDistances = max(0, squaredNorm + squaredNorm' - 2 * (points * points'));
    pairDistances = sqrt(squaredDistances(triu(true(numberOfPoints), 1)));

    intersectionVolume = volIntersectEqualSpheres(sphereRadius, pairDistances);
    observableFraction = intersectionVolume ./ windowVolume;
    observableFraction(observableFraction == 0) = Inf;
    pairWeights = 1 ./ observableFraction;

    [sortedDistances, order] = sort(pairDistances);
    cumulativeWeights = cumsum(pairWeights(order));

    for radiusIndex = 1:numel(radii)
        lastPair = find(sortedDistances <= radii(radiusIndex), 1, 'last');
        if ~isempty(lastPair)
            K3(radiusIndex) = windowVolume / (numberOfPoints * (numberOfPoints - 1)) ...
                * 2 * cumulativeWeights(lastPair);
        end
    end

    L3 = (K3 / ((4/3) * pi)).^(1/3);
    LminusR = L3 - radii;
end
