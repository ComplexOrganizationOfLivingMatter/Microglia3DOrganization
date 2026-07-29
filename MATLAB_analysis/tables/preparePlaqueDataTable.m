function table = preparePlaqueDataTable(table, nImages)
%PREPAREPLAQUEDATATABLE Initialize the result table for individual plaque measurements.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    table.File = strings(nImages, 1);
    table.Mouse = zeros(nImages, 1);
    table.Sex = strings(nImages, 1);
    table.Section = strings(nImages, 1);
    table.Image = zeros(nImages, 1);
    table.Model = strings(nImages, 1);
    table.BregmaLevel = strings(nImages, 1);
    table.CortexArea = strings(nImages, 1);
    table.Layer = strings(nImages, 1);
    table.LayerInformationAvailable = false(nImages, 1);
    table.IDPlaque = zeros(nImages,1);
    table.GlobalPlaqueID = zeros(nImages,1);
    
    table.isInsideCrop = false(nImages,1);
    table.isCompleted = false(nImages,1);
    table.isCompletedInsideCrop = false(nImages,1);
    
    table.PlaqueVolume = zeros(nImages,1);
    table.PlaqueVolumeValid = zeros(nImages,1);
    table.NAssociatedMicroglia = zeros(nImages,1);
    table.NInsideMicroglia = zeros(nImages,1);
    table.NAroundMicroglia = zeros(nImages,1);
    table.MicrogliaDensityTotal = zeros(nImages,1);
    table.MicrogliaDensityInside = zeros(nImages,1);
    table.MicrogliaDensityAround = zeros(nImages,1);
    
    table.MicrogliaDist_Mean = zeros(nImages,1);
    table.MicrogliaDist_Std = zeros(nImages,1);
    table.MicrogliaDistToNearest_Mean = zeros(nImages,1);
    table.MicrogliaDistToNearest_Std = zeros(nImages,1);    
    
    table.Centroid_X = zeros(nImages,1);
    table.Centroid_Y = zeros(nImages,1);
    table.Centroid_Z = zeros(nImages,1);
    
    table.distToBorder = zeros(nImages,1);
    
    table.nVoronoiTotal = zeros(nImages,1);
    table.VoronoisNeighsTotal_Mean = zeros(nImages,1);
    table.VoronoiDistNeighsTotal_Mean = zeros(nImages,1);
    table.VoronoiVolumeTotal_Mean = zeros(nImages,1);
    table.VoronoiSurfaceAreaTotal_Mean = zeros(nImages,1);
    
    table.VoronoisNeighsTotal_Std = zeros(nImages,1);
    table.VoronoiDistNeighsTotal_Std = zeros(nImages,1);
    table.VoronoiVolumeTotal_Std = zeros(nImages,1);
    table.VoronoiSurfaceAreaTotal_Std = zeros(nImages,1);
    
    table.nVoronoiBorder = zeros(nImages,1);
    table.VoronoisNeighsBorder_Mean = zeros(nImages,1);
    table.VoronoiDistNeighsBorder_Mean = zeros(nImages,1);
    table.VoronoiVolumeBorder_Mean = zeros(nImages,1);
    table.VoronoiSurfaceAreaBorder_Mean = zeros(nImages,1);
    
    table.VoronoisNeighsBorder_Std = zeros(nImages,1);
    table.VoronoiDistNeighsBorder_Std = zeros(nImages,1);
    table.VoronoiVolumeBorder_Std = zeros(nImages,1);
    table.VoronoiSurfaceAreaBorder_Std = zeros(nImages,1);     

end
