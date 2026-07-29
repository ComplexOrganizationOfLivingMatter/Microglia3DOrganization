function zoneImg = getZoneFromBorder(imgBorder, distance)
%GETZONEFROMBORDER Extend a binary cortical border along the positive X axis.
%
% This implementation preserves the original coordinate-based algorithm.
% The only defensive changes are explicit 3-D image dimensions, scalar
% integer distance normalization, empty-input handling, and a final bounds
% check before converting coordinates to linear indices.

    imgBorder = logical(imgBorder);

    height = size(imgBorder, 1);
    width  = size(imgBorder, 2);
    depth  = size(imgBorder, 3);
    imageSize = [height, width, depth];

    zoneImg = false(imageSize);

    if isempty(imgBorder) || ~any(imgBorder, 'all') || ...
            isempty(distance) || ~isscalar(distance) || ~isfinite(distance)
        return;
    end

    distance = max(0, round(double(distance)));
    if distance == 0
        return;
    end

    stats = regionprops3(imgBorder, 'VoxelList');
    if isempty(stats)
        return;
    end

    voxelCells = stats.VoxelList;
    voxelCells = voxelCells(~cellfun(@isempty, voxelCells));
    if isempty(voxelCells)
        return;
    end

    voxelList = vertcat(voxelCells{:});
    if isempty(voxelList)
        return;
    end

    % regionprops3 returns voxel coordinates as [X Y Z].
    xCoords = double(voxelList(:, 1));
    yCoords = double(voxelList(:, 2));
    zCoords = double(voxelList(:, 3));

    xOffsets = (0:(distance - 1)).';

    xRepeated = repelem(xCoords, distance) + ...
        repmat(xOffsets, numel(xCoords), 1);
    yRepeated = repelem(yCoords, distance);
    zRepeated = repelem(zCoords, distance);

    % Preserve only valid integer coordinates before sub2ind.
    valid = isfinite(xRepeated) & isfinite(yRepeated) & isfinite(zRepeated) & ...
        xRepeated >= 1 & xRepeated <= width & ...
        yRepeated >= 1 & yRepeated <= height & ...
        zRepeated >= 1 & zRepeated <= depth;

    if ~any(valid)
        return;
    end

    xRepeated = round(xRepeated(valid));
    yRepeated = round(yRepeated(valid));
    zRepeated = round(zRepeated(valid));

    % Repeat the bounds check after rounding to make the sub2ind call safe.
    valid = xRepeated >= 1 & xRepeated <= width & ...
        yRepeated >= 1 & yRepeated <= height & ...
        zRepeated >= 1 & zRepeated <= depth;

    if ~any(valid)
        return;
    end

    targetIndices = sub2ind(imageSize, ...
        yRepeated(valid), xRepeated(valid), zRepeated(valid));

    zoneImg(unique(targetIndices)) = true;
end
