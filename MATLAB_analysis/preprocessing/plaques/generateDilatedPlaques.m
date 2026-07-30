function generateDilatedPlaques(imgPath, savePath, nameExcel, pathExcel, dilationRadius_um)
%DILATEPLAQUES_FUNCTION Expand plaque labels by a physical radius.
% Labels are propagated from the nearest original plaque voxel, preventing
% grayscale-label dilation artifacts in overlapping regions.

    if nargin < 5 || isempty(dilationRadius_um), dilationRadius_um = 9; end
    if ~isfolder(savePath), mkdir(savePath); end

    files = dir(fullfile(imgPath,'*.tif'));
    tableData = readtable(fullfile(pathExcel,nameExcel));
    fileNames = string(tableData.Archivo);

    for k = 1:numel(files)
        filename = files(k).name;
        name = erase(filename,'.tif');
        row = find(fileNames==string(name),1);
        if isempty(row)
            warning('No metadata row found for %s. Skipping.',name);
            continue;
        end

        labels = uint16(readStackTif(fullfile(imgPath,filename)));
        xy = tableData.ResolucionXY_um_pxl(row);
        z = tableData.ResolucionZ_um_pxl(row);
        cf = tableData.Correction_Factor(row);
        assert(xy>0 && z>0 && cf>0,'Invalid resolution/correction factor for %s.',name);

        % Isotropic grid at the native XY spacing.
        isoSize = [size(labels,1), size(labels,2), round(size(labels,3)*z/xy)];
        labelsIso = uint16(imresize3(labels,isoSize,'nearest'));
        physicalVoxel_um = xy*cf;
        radiusPx = dilationRadius_um/physicalVoxel_um;

        foreground = labelsIso>0;
        if any(foreground(:))
            [distancePx,nearestIdx] = bwdist(foreground);
            dilatedIso = zeros(size(labelsIso),'uint16');
            target = distancePx<=radiusPx;
            nearestLabels = labelsIso(nearestIdx(target));
            dilatedIso(target) = nearestLabels;
        else
            dilatedIso = zeros(size(labelsIso),'uint16');
        end

        dilated = imresize3(dilatedIso, size(labels), 'nearest');
        writeStackTif(castLabelImageForStorage(dilated), fullfile(savePath, filename));
    end
end
