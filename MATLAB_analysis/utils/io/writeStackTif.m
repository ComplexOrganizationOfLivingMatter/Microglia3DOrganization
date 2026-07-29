function writeStackTif(imageStack, fileName)
%WRITESTACKTIF Write a three-dimensional array as a multi-page TIFF file.
%
% Existing files are replaced to prevent accidental page appending across runs.
%
% Inputs
%   imageStack Three-dimensional array with dimensions [row, column, slice].
%   fileName   Destination TIFF path.

    arguments
        imageStack
        fileName {mustBeTextScalar}
    end

    fileName = char(fileName);
    outputFolder = fileparts(fileName);
    if ~isempty(outputFolder) && ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    if isfile(fileName)
        delete(fileName);
    end

    for sliceIndex = 1:size(imageStack, 3)
        if sliceIndex == 1
            mode = 'overwrite';
        else
            mode = 'append';
        end
        imwrite(imageStack(:, :, sliceIndex), fileName, 'WriteMode', mode, 'Compression', 'none');
    end
end
