function border = computeCorticalBorderX(maskImage)
%COMPUTECORTICALBORDERX Extract the first tissue voxel along the X axis.
%
% Input
%   maskImage Binary tissue mask in MATLAB order [Y, X, Z].
%
% Output
%   border    Structure containing:
%             borderX - matrix indexed by [Y, Z] with the surface X position;
%             x, y, z - coordinates of all detected surface voxels.

    maskImage = logical(maskImage);
    firstVoxelMask = maskImage;
    firstVoxelMask(cumsum(firstVoxelMask, 2) > 1) = false;

    [yCoordinates, xCoordinates, zCoordinates] = ind2sub(size(firstVoxelMask), find(firstVoxelMask));
    border.borderX = nan(size(maskImage, 1), size(maskImage, 3));

    if ~isempty(xCoordinates)
        yzIndices = sub2ind(size(border.borderX), yCoordinates, zCoordinates);
        border.borderX(yzIndices) = xCoordinates;
    end

    border.y = yCoordinates;
    border.x = xCoordinates;
    border.z = zCoordinates;
end
