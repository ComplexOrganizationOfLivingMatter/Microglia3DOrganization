function table = prepareLayerDataTable(table, nImages, cortexArea)
%PREPARELAYERDATATABLE Initialize the result table for layer-specific microglia measurements.
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
    
    table.Layer1Volume = zeros(nImages,1);
    table.Layer1MicrogliaNumber = zeros(nImages,1);
    table.Layer1MicrogliaDensitymm3 = zeros(nImages,1);
    table.Layer1ValidMicroglia = zeros(nImages,1);
    table.Layer1MeanNeighs = zeros(nImages,1);
    table.Layer1StdNeighs = zeros(nImages,1);
    table.Layer1MeanSurface = zeros(nImages,1);
    table.Layer1StdSurface = zeros(nImages,1);
    table.Layer1MeanVolume = zeros(nImages,1);
    table.Layer1StdVolume = zeros(nImages,1);
    table.Layer1MeanDistNeighs = zeros(nImages,1);
    table.Layer1StdDistNeighs = zeros(nImages,1);
    
    table.Layer23Volume = zeros(nImages,1);
    table.Layer23MicrogliaNumber = zeros(nImages,1);
    table.Layer23MicrogliaDensitymm3 = zeros(nImages,1);
    table.Layer23ValidMicroglia = zeros(nImages,1);
    table.Layer23MeanNeighs = zeros(nImages,1);
    table.Layer23StdNeighs = zeros(nImages,1);
    table.Layer23MeanSurface = zeros(nImages,1);
    table.Layer23StdSurface = zeros(nImages,1);
    table.Layer23MeanVolume = zeros(nImages,1);
    table.Layer23StdVolume = zeros(nImages,1);
    table.Layer23MeanDistNeighs = zeros(nImages,1);
    table.Layer23StdDistNeighs = zeros(nImages,1);

    if contains(cortexArea, 'Lateral')
        table.Layer4Volume = zeros(nImages,1);
        table.Layer4MicrogliaNumber = zeros(nImages,1);
            table.Layer4MicrogliaDensitymm3 = zeros(nImages,1);
        table.Layer4ValidMicroglia = zeros(nImages,1);
        table.Layer4MeanNeighs = zeros(nImages,1);
        table.Layer4StdNeighs = zeros(nImages,1);
        table.Layer4MeanSurface = zeros(nImages,1);
        table.Layer4StdSurface = zeros(nImages,1);
        table.Layer4MeanVolume = zeros(nImages,1);
        table.Layer4StdVolume = zeros(nImages,1);
        table.Layer4MeanDistNeighs = zeros(nImages,1);
        table.Layer4StdDistNeighs = zeros(nImages,1);
    end

    
    table.Layer5Volume = zeros(nImages,1);
    table.Layer5MicrogliaNumber = zeros(nImages,1);
    table.Layer5MicrogliaDensitymm3 = zeros(nImages,1);    
    table.Layer5ValidMicroglia = zeros(nImages,1);
    table.Layer5MeanNeighs = zeros(nImages,1);
    table.Layer5StdNeighs = zeros(nImages,1);
    table.Layer5MeanSurface = zeros(nImages,1);
    table.Layer5StdSurface = zeros(nImages,1);
    table.Layer5MeanVolume = zeros(nImages,1);
    table.Layer5StdVolume = zeros(nImages,1);
    table.Layer5MeanDistNeighs = zeros(nImages,1);
    table.Layer5StdDistNeighs = zeros(nImages,1);
        
    if contains(cortexArea, 'Medial')
        table.Layer6Volume = zeros(nImages,1);
        table.Layer6MicrogliaNumber = zeros(nImages,1);
            table.Layer6MicrogliaDensitymm3 = zeros(nImages,1);
        table.Layer6ValidMicroglia = zeros(nImages,1);
        table.Layer6MeanNeighs = zeros(nImages,1);
        table.Layer6StdNeighs = zeros(nImages,1);
        table.Layer6MeanSurface = zeros(nImages,1);
        table.Layer6StdSurface = zeros(nImages,1);
        table.Layer6MeanVolume = zeros(nImages,1);
        table.Layer6StdVolume = zeros(nImages,1);
        table.Layer6MeanDistNeighs = zeros(nImages,1);
        table.Layer6StdDistNeighs = zeros(nImages,1);
    end

end
