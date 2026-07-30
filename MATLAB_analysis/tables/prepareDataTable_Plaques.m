 function table = prepareDataTable_Plaques(table, nImages)
%PREPAREDATATABLE_PLAQUES Initialize the image-level plaque summary columns.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    table.PlaqueNumberTotal = zeros(nImages,1);
    table.PlaqueNumberValid = zeros(nImages,1);
    table.PlaqueDensityTotal = zeros(nImages,1);
    table.PlaqueDensityValid = zeros(nImages,1);
    table.PlaqueVolumeOccupied_Total = zeros(nImages,1);
    table.PlaqueVolumeOccupied_Valid = zeros(nImages,1);
    table.PlaquePercOccupied_Total = zeros(nImages,1);
    table.PlaquePercOccupied_Valid = zeros(nImages,1);

end
