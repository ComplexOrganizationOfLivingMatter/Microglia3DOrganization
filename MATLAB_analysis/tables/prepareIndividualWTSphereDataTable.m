function tabla = prepareIndividualWTSphereDataTable(tabla, nImages)
%PREPAREINDIVIDUALWTSPHEREDATATABLE Initialize the result table for individual WT spheres.
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
    tabla.VolSphere = nan(nImages,1);
          
    tabla.MeanRadialDistance = nan(nImages,1);
    tabla.StdRadialDistance = nan(nImages,1);
    tabla.CentralThirdMicrogliaFraction = nan(nImages,1);
    tabla.DeviationAreaK3 = nan(nImages,1);
    tabla.DeviationAreaG = nan(nImages,1);
    tabla.gMax = nan(nImages,1);
    tabla.distanceGMax = nan(nImages,1);
    tabla.gMin = nan(nImages,1);
    tabla.distanceGMin = nan(nImages,1);
    
    tabla.DisplacementMagnitude = nan(nImages,1);
    
    tabla.Pol_rand_mean = nan(nImages,1);
    tabla.Pol_rand_std = nan(nImages,1);
    tabla.Pol_rand_P95 = nan(nImages,1);
    tabla.Align_mean = nan(nImages,1);    
    tabla.Align_std = nan(nImages,1); 
    tabla.Align_P95 = nan(nImages,1); 
    tabla.meanCos_mean = nan(nImages,1);    
    tabla.meanCos_std = nan(nImages,1); 
    tabla.meanCos_P95 = nan(nImages,1);
    
    tabla.u_Align_x = nan(nImages,1);
    tabla.u_Align_y = nan(nImages,1);
    tabla.u_Align_z = nan(nImages,1);
    tabla.Align_max = nan(nImages,1);
    tabla.meanCos_atMaxAlign = nan(nImages,1);
    tabla.Pol_atMaxAlign = nan(nImages,1);
    
    tabla.u_maxCos_x = nan(nImages,1);
    tabla.u_maxCos_y = nan(nImages,1);
    tabla.u_maxCos_z = nan(nImages,1);
    tabla.meanCos_max = nan(nImages,1);
    tabla.Align_atMaxCos = nan(nImages,1);
    tabla.Pol_atMaxCos = nan(nImages,1);
    
    tabla.Align_depth = nan(nImages,1);
    tabla.Pol_depth = nan(nImages,1);
    tabla.meanCos_depth = nan(nImages,1);

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
