function tabla = prepareJoinSphereDataTable(tabla, nImages, typeImage)
%PREPAREJOINSPHEREDATATABLE Initialize the joined image-level sphere summary table.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    tabla.File = strings(nImages, 1);
    tabla.Mouse = strings(nImages, 1);
    tabla.Sex = strings(nImages, 1);
    tabla.Section = strings(nImages, 1);
    tabla.Image = nan(nImages, 1);
    tabla.Model = strings(nImages, 1);
    tabla.BregmaLevel = strings(nImages, 1);
    tabla.CortexArea = strings(nImages, 1);
    
    if contains(typeImage, 'AD') || contains(typeImage, 'APP')
        
        tabla.VolNonPlaqueSpheres = nan(nImages,1);
        tabla.VolPlaqueSpheres = nan(nImages,1);
        tabla.MicrogliaDensityNonPlaqueSpheres = nan(nImages,1);   
        tabla.MicrogliaDensityPlaqueSpheres = nan(nImages,1);
        tabla.MicrogliaDensityPlaqueSpheres_WP = nan(nImages,1);

        tabla.Vol_Overlap_1_Spheres = nan(nImages,1);
        tabla.Vol_Overlap_2_Spheres = nan(nImages,1);
        tabla.Vol_Overlap_3_Spheres	= nan(nImages,1);  
        tabla.Vol_Overlap_4_Spheres = nan(nImages,1);
        tabla.Vol_Overlap_5_Spheres	= nan(nImages,1);

        tabla.Microglia_Density_Overlap_1_Spheres = nan(nImages,1);
        tabla.Microglia_Density_Overlap_2_Spheres = nan(nImages,1);
        tabla.Microglia_Density_Overlap_3_Spheres = nan(nImages,1);
        tabla.Microglia_Density_Overlap_4_Spheres = nan(nImages,1);
        tabla.Microglia_Density_Overlap_5_Spheres = nan(nImages,1);

        tabla.nVoronoiMicrogliaNonPlaqueSpheres = nan(nImages,1);
        tabla.meanNeighboursVoronoiNonPlaqueSpheres = nan(nImages,1);
        tabla.stdNeighboursVoronoiNonPlaqueSpheres = nan(nImages,1);
        tabla.meanSurfaceAreaVoronoiNonPlaqueSpheres = nan(nImages,1);
        tabla.stdSurfaceAreaVoronoiNonPlaqueSpheres = nan(nImages,1);
        tabla.meanVolumeVoronoiNonPlaqueSpheres = nan(nImages,1);
        tabla.stdVolumeVoronoiNonPlaqueSpheres = nan(nImages,1);
        tabla.meanDistanceNeighboursVoronoiNonPlaqueSpheres = nan(nImages,1);
        tabla.stdDistanceNeighboursVoronoiNonPlaqueSpheres = nan(nImages,1);


        tabla.nVoronoiMicrogliaPlaqueSpheres = nan(nImages,1);
        tabla.meanNeighboursVoronoiPlaqueSpheres = nan(nImages,1);
        tabla.stdNeighboursVoronoiPlaqueSpheres = nan(nImages,1);
        tabla.meanSurfaceAreaVoronoiPlaqueSpheres = nan(nImages,1);
        tabla.stdSurfaceAreaVoronoiPlaqueSpheres = nan(nImages,1);
        tabla.meanVolumeVoronoiPlaqueSpheres = nan(nImages,1);
        tabla.stdVolumeVoronoiPlaqueSpheres = nan(nImages,1);
        tabla.meanDistanceNeighboursVoronoiPlaqueSpheres = nan(nImages,1);
        tabla.stdDistanceNeighboursVoronoiPlaqueSpheres = nan(nImages,1);

    
    else
        
        tabla.VolWTSpheres = nan(nImages,1);
        tabla.MicrogliaDensityWTSpheres = nan(nImages,1);

        tabla.nVoronoiMicrogliaWTSpheres = nan(nImages,1);
        tabla.meanNeighboursVoronoiWTSpheres = nan(nImages,1);
        tabla.stdNeighboursVoronoiWTSpheres = nan(nImages,1);
        tabla.meanSurfaceAreaVoronoiWTSpheres = nan(nImages,1);
        tabla.stdSurfaceAreaVoronoiWTSpheres = nan(nImages,1);
        tabla.meanVolumeVoronoiWTSpheres = nan(nImages,1);
        tabla.stdVolumeVoronoiWTSpheres = nan(nImages,1);
        tabla.meanDistanceNeighboursVoronoiWTSpheres = nan(nImages,1);
        tabla.stdDistanceNeighboursVoronoiWTSpheres = nan(nImages,1);

    end
