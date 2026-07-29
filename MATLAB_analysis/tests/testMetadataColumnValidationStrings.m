function testMetadataColumnValidationStrings()
%TESTMETADATACOLUMNVALIDATIONSTRINGS Regression test for char-to-string column lists.
    names = struct();
    names.fileName = 'File';
    names.model = 'Model';
    names.cortexArea = 'Cortex Region';
    names.cropSizeX = 'X_Crop_pxl';
    names.cropSizeY = 'Y_Crop_pxl';
    names.cropSizeZ = 'Z_Crop_px';
    names.cropStartX = 'X_Crop_Start';
    names.cropStartY = 'Y_Crop_Start';
    names.cropStartZ = 'Z_Crop_Start';

    required = [string(names.fileName), string(names.model), ...
        string(names.cortexArea), string(names.cropSizeX), ...
        string(names.cropSizeY), string(names.cropSizeZ), ...
        string(names.cropStartX), string(names.cropStartY), ...
        string(names.cropStartZ)];
    required(end+1) = string('correctionFactor');

    assert(numel(required) == 10);
    assert(required(end) == "correctionFactor");
end
