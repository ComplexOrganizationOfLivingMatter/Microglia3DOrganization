function table = prepareDataTable(table, nImages)
%PREPAREDATATABLE Initialize the image-level microglia result table.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.


    table.File = strings(nImages, 1);
    table.Mouse = strings(nImages, 1);
    table.Sex = strings(nImages, 1);
    table.Section = strings(nImages, 1);
    table.Image = strings(nImages, 1);
    table.Model = strings(nImages, 1);
    table.BregmaLevel = strings(nImages, 1);
    table.CortexArea = strings(nImages, 1);
    
    table.VolumeTotal = zeros(nImages,1);
    table.AnalyzedVolume = zeros(nImages,1);

    table.MicrogliaNumber = zeros(nImages,1);
    table.MicrogliaDensity = zeros(nImages,1);

    table.ValidMicroglia = zeros(nImages,1);
    table.MeanNeighs = zeros(nImages,1);
    table.StdNeighs = zeros(nImages,1);
    table.MeanSurface = zeros(nImages,1);
    table.StdSurface = zeros(nImages,1);
    table.MeanVolume = zeros(nImages,1);
    table.StdVolume = zeros(nImages,1);
    table.MeanDistNeighs = zeros(nImages,1);
    table.StdDistNeighs = zeros(nImages,1);

end
