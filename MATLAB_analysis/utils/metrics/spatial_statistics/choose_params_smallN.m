function params = choose_params_smallN(numberOfPoints, sphereRadius)
%CHOOSE_PARAMS_SMALLN Select stable pair-correlation bins for small samples.
%
% Inputs
%   numberOfPoints Number of points in the sphere.
%   sphereRadius   Observation-window radius.
%
% Output
%   params         Structure containing rmax and equal-volume bin edges.

    if numberOfPoints <= 30
        maximumRadius = 0.7 * sphereRadius;
        numberOfBins = 12;
    else
        maximumRadius = 0.8 * sphereRadius;
        numberOfBins = 16;
    end
    binIndex = 0:numberOfBins;
    edges = maximumRadius * (binIndex / numberOfBins).^(1/3);
    params = struct('rmax', maximumRadius, 'edges_g', edges);
end
