function points = sampleCSRinSphere(numberOfPoints, radius)
%SAMPLECSRINSPHERE Sample points uniformly inside a three-dimensional sphere.
%
% Inputs
%   numberOfPoints Number of points to generate.
%   radius         Sphere radius.
%
% Output
%   points         N-by-3 coordinates centered at the origin.

    directions = randn(numberOfPoints, 3);
    directions = directions ./ vecnorm(directions, 2, 2);
    radialDistance = radius * rand(numberOfPoints, 1).^(1/3);
    points = directions .* radialDistance;
end
