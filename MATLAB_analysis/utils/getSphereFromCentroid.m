function [sphereMask, linearIndices] = getSphereFromCentroid(centroidXYZ, radiusPixels, imageSize)
%GETSPHEREFROMCENTROID Create a clipped 3-D spherical mask.
%
% Inputs
%   centroidXYZ  - Sphere center in [X Y Z] pixel coordinates.
%   radiusPixels - Sphere radius in pixels.
%   imageSize    - Image size in MATLAB order [rows columns slices].
%
% Outputs
%   sphereMask    - Logical full-size image containing the clipped sphere.
%   linearIndices - Linear indices of voxels inside the clipped sphere.
%
% The sphere is generated inside its clipped local bounding box and then
% copied directly into the full-size logical mask. This avoids manually
% converting XYZ coordinates with sub2ind and therefore prevents out-of-
% range subscripts at image borders.

    arguments
        centroidXYZ (1,3) double
        radiusPixels (1,1) double {mustBePositive}
        imageSize (1,:) double {mustBeInteger, mustBePositive}
    end

    imageSize = double(imageSize(:).');
    if numel(imageSize) == 2
        imageSize(3) = 1;
    elseif numel(imageSize) > 3
        imageSize = imageSize(1:3);
    elseif numel(imageSize) < 2
        error('getSphereFromCentroid:InvalidImageSize', ...
            'imageSize must contain at least rows and columns.');
    end

    x0 = double(centroidXYZ(1));
    y0 = double(centroidXYZ(2));
    z0 = double(centroidXYZ(3));
    radiusPixels = double(radiusPixels);

    sphereMask = false(imageSize);
    linearIndices = zeros(0, 1);

    if any(~isfinite([x0, y0, z0, radiusPixels]))
        return;
    end

    xMin = max(1, floor(x0 - radiusPixels));
    xMax = min(imageSize(2), ceil(x0 + radiusPixels));
    yMin = max(1, floor(y0 - radiusPixels));
    yMax = min(imageSize(1), ceil(y0 + radiusPixels));
    zMin = max(1, floor(z0 - radiusPixels));
    zMax = min(imageSize(3), ceil(z0 + radiusPixels));

    if xMin > xMax || yMin > yMax || zMin > zMax
        return;
    end

    [Y, X, Z] = ndgrid(yMin:yMax, xMin:xMax, zMin:zMax);
    localSphere = (X - x0).^2 + (Y - y0).^2 + (Z - z0).^2 <= radiusPixels.^2;

    if ~any(localSphere, 'all')
        return;
    end

    sphereMask(yMin:yMax, xMin:xMax, zMin:zMax) = localSphere;
    linearIndices = find(sphereMask);
end
