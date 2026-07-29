function table = preparePlaqueLayerDataTable(table, nImages, cortexArea)
%PREPAREPLAQUELAYERDATATABLE Initialize the result table for layer-specific plaque measurements.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.
    
    
    table.Layer1Volume_Plaques = zeros(nImages,1);
    table.Layer1PlaquesNumber = zeros(nImages,1);
    table.Layer1PlaquesDensitymm3 = zeros(nImages,1);
    table.Layer1MeanPlaquesVolume = zeros(nImages,1);
    table.Layer1StdPlaquesVolume = zeros(nImages,1);
    table.Layer1MeanPlaquesRelativeVolume = zeros(nImages,1);
    
    table.Layer23Volume_Plaques = zeros(nImages,1);
    table.Layer23PlaquesNumber = zeros(nImages,1);
    table.Layer23PlaquesDensitymm3 = zeros(nImages,1);
    table.Layer23MeanPlaquesVolume = zeros(nImages,1);
    table.Layer23StdPlaquesVolume = zeros(nImages,1);
    table.Layer23MeanPlaquesRelativeVolume = zeros(nImages,1);
    
    if contains(cortexArea, 'Lateral')
        table.Layer4Volume_Plaques = zeros(nImages,1);
        table.Layer4PlaquesNumber = zeros(nImages,1);
            table.Layer4PlaquesDensitymm3 = zeros(nImages,1);
                table.Layer4MeanPlaquesVolume = zeros(nImages,1);
        table.Layer4StdPlaquesVolume = zeros(nImages,1);
        table.Layer4MeanPlaquesRelativeVolume = zeros(nImages,1);
    end
    
    table.Layer5Volume_Plaques = zeros(nImages,1);
    table.Layer5PlaquesNumber = zeros(nImages,1);
    table.Layer5PlaquesDensitymm3 = zeros(nImages,1);
    table.Layer5MeanPlaquesVolume = zeros(nImages,1);
    table.Layer5StdPlaquesVolume = zeros(nImages,1);
    table.Layer5MeanPlaquesRelativeVolume = zeros(nImages,1);
    
    if contains(cortexArea, 'Medial')
        table.Layer6Volume_Plaques = zeros(nImages,1);
        table.Layer6PlaquesNumber = zeros(nImages,1);
            table.Layer6PlaquesDensitymm3 = zeros(nImages,1);
                table.Layer6MeanPlaquesVolume = zeros(nImages,1);
        table.Layer6StdPlaquesVolume = zeros(nImages,1);
        table.Layer6MeanPlaquesRelativeVolume = zeros(nImages,1);
    end

end
