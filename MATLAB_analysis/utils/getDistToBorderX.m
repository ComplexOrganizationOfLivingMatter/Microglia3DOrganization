function distance_um = getDistToBorderX(maskOrBorder, centroidXYZ, xyResolution, correctionFactor)
%GETDISTTOBORDERX Measure cortical depth along X at the centroid Y-Z plane.
%
% Inputs
%   maskOrBorder      Binary tissue mask or a structure returned by
%                     computeCorticalBorderX.
%   centroidXYZ       Object centroid in [X, Y, Z] pixel coordinates.
%   xyResolution      XY pixel size in micrometers per pixel.
%   correctionFactor  Isotropic linear correction factor.
%
% Output
%   distance_um       Signed distance from the cortical surface to the
%                     centroid along X, in micrometers. NaN is returned when
%                     no surface voxel can be identified.

    if isstruct(maskOrBorder)
        border = maskOrBorder;
    else
        border = computeCorticalBorderX(maskOrBorder);
    end

    if isempty(border.x)
        distance_um = NaN;
        return;
    end

    centroidX = centroidXYZ(1);
    centroidY = round(centroidXYZ(2));
    centroidZ = round(centroidXYZ(3));
    centroidY = max(1, min(size(border.borderX, 1), centroidY));
    centroidZ = max(1, min(size(border.borderX, 2), centroidZ));

    surfaceX = border.borderX(centroidY, centroidZ);
    if isnan(surfaceX)
        [~, nearestIndex] = min((border.y - centroidY).^2 + (border.z - centroidZ).^2);
        surfaceX = border.x(nearestIndex);
    end

    distance_um = (centroidX - surfaceX) * xyResolution * correctionFactor;
end
