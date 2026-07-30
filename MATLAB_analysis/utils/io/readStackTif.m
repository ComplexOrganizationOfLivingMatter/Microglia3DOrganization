function [imageStack, imageInfo] = readStackTif(fileName)
%READSTACKTIF Read a multi-page TIFF while preserving the stored numeric type.
%
% Inputs
%   fileName   Path to a multi-page TIFF file.
%
% Outputs
%   imageStack Three-dimensional array with dimensions [row, column, slice].
%   imageInfo  Structure array returned by IMFINF0 for all TIFF pages.

    arguments
        fileName {mustBeTextScalar}
    end

    fileName = char(fileName);
    if ~isfile(fileName)
        error('TIFF file not found: %s', fileName);
    end

    imageInfo = imfinfo(fileName);
    if isempty(imageInfo)
        error('The TIFF file does not contain any readable pages: %s', fileName);
    end

    firstSlice = imread(fileName, 1, 'Info', imageInfo);
    imageStack = zeros(imageInfo(1).Height, imageInfo(1).Width, numel(imageInfo), 'like', firstSlice);
    imageStack(:, :, 1) = firstSlice;

    for sliceIndex = 2:numel(imageInfo)
        imageStack(:, :, sliceIndex) = imread(fileName, sliceIndex, 'Info', imageInfo);
    end
end
