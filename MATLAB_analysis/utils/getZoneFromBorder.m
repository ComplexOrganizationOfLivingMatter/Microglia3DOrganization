function zoneImg = getZoneFromBorder(imgBorder, distance)

    stats = regionprops3(imgBorder, 'VoxelList');
    voxelList = cell2mat(stats.VoxelList);

    sizeImg = size(imgBorder);
    [height, width, depth] = size(imgBorder);

    clear imgBorder;

    xCoords = voxelList(:, 1);
    yCoords = voxelList(:, 2);
    zCoords = voxelList(:, 3);

    xOffsets = (0:(distance - 1))';

    xRepeated = repelem(xCoords, distance) + ...
        repmat(xOffsets, size(voxelList, 1), 1);

    clear xOffsets;

    yRepeated = repelem(yCoords, distance);
    zRepeated = repelem(zCoords, distance);

    targetPixels = [xRepeated, yRepeated, zRepeated];

    clear xRepeated yRepeated zRepeated;

    isValid = ...
        targetPixels(:, 1) >= 1 & targetPixels(:, 1) <= width & ...
        targetPixels(:, 2) >= 1 & targetPixels(:, 2) <= height & ...
        targetPixels(:, 3) >= 1 & targetPixels(:, 3) <= depth;

    targetPixels = targetPixels(isValid, :);

    targetPixelsInd = sub2ind( ...
        sizeImg, ...
        targetPixels(:, 2), ...
        targetPixels(:, 1), ...
        targetPixels(:, 3));

    zoneImg = zeros(sizeImg);
    zoneImg(targetPixelsInd) = 1;

end