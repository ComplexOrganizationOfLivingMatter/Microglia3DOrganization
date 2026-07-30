function tabla = prepareIndividualPlaqueSphereDataTable(tabla, nImages)
%PREPAREINDIVIDUALPLAQUESPHEREDATATABLE Initialize the result table for plaque-centered spheres.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    tabla.IDSphere = nan(nImages, 1);
    tabla.ImageSphereID = nan(nImages, 1);    
    tabla.File = strings(nImages, 1);
    tabla.Mouse = strings(nImages, 1);
    tabla.Sex = strings(nImages, 1);
    tabla.Section = strings(nImages, 1);
    tabla.Image = nan(nImages, 1);
    tabla.Model = strings(nImages, 1);
    tabla.BregmaLevel = strings(nImages, 1);
    tabla.CortexArea = strings(nImages, 1);
    tabla.TypeSphere = strings(nImages, 1);
    
    tabla.Vol_Plaque = nan(nImages,1);
    tabla.Length_Plaque = nan(nImages,1);
    tabla.N_Microglia_Plaque = nan(nImages,1);
    tabla.Microglia_Density_Plaque = nan(nImages,1);
    tabla.Microglia_Density_WP = nan(nImages,1);
    tabla.Microglia_Density_WPAM = nan(nImages,1);
    tabla.Plaque_Inside = nan(nImages,1);
    tabla.N_Plaques_Touching = nan(nImages,1);
     
    tabla.DistToBorder = nan(nImages,1);
    tabla.Layer = strings(nImages,1);
    tabla.LayerInformationAvailable = false(nImages,1);
    tabla.CentroidX = nan(nImages,1);
    tabla.CentroidY = nan(nImages,1);
    tabla.CentroidZ = nan(nImages,1);
    
    tabla.nMicroglia = nan(nImages,1);  
    tabla.MicrogliaDensity = nan(nImages,1);
    tabla.MicrogliaDist_Mean = nan(nImages,1); 
    tabla.MicrogliaDist_Std = nan(nImages,1); 
    tabla.MicrogliaDistToNearest_Mean = nan(nImages,1); 
    tabla.MicrogliaDistToNearest_Std = nan(nImages,1); 
    tabla.SphereCompleted = nan(nImages,1);
    tabla.VolSphere = nan(nImages,1);
    tabla.VolOverlap = nan(nImages,1);
    tabla.DistNearestPlaque = nan(nImages,1);
          
    tabla.MeanRadialDistance = nan(nImages,1);
    tabla.StdRadialDistance = nan(nImages,1);
    tabla.CentralThirdMicrogliaFraction = nan(nImages,1);
    tabla.DeviationAreaK3 = nan(nImages,1);
    tabla.DeviationAreaG = nan(nImages,1);
    tabla.gMax = nan(nImages,1);
    tabla.distanceGMax = nan(nImages,1);
    tabla.gMin = nan(nImages,1);
    tabla.distanceGMin = nan(nImages,1);

    tabla.nVoronoiMicroglia = nan(nImages,1);
    tabla.meanNeighboursVoronoi = nan(nImages,1);
    tabla.stdNeighboursVoronoi = nan(nImages,1);
    tabla.meanSurfaceAreaVoronoi = nan(nImages,1);
    tabla.stdSurfaceAreaVoronoi = nan(nImages,1);
    tabla.meanVolumeVoronoi = nan(nImages,1);
    tabla.stdVolumeVoronoi = nan(nImages,1);
    tabla.meanDistanceNeighboursVoronoi = nan(nImages,1);
    tabla.stdDistanceNeighboursVoronoi = nan(nImages,1);
    
    
end
