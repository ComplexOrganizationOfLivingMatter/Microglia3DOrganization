function tabla = prepareGlobalSphereDataTable(tabla, nImages)
%PREPAREGLOBALSPHEREDATATABLE Initialize the image-level sphere summary table.
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
    
    tabla.Volume_Total = nan(nImages,1);
    tabla.Valid_Volume = nan(nImages,1);
    tabla.N_Plaques = nan(nImages,1);
    tabla.Plaque_Density = nan(nImages,1);
    tabla.N_Valid_Plaques = nan(nImages,1);
    tabla.N_Valid_Microglia = nan(nImages,1);   
    tabla.Plaque_Density_Valid = nan(nImages,1);
    tabla.Microglia_Density = nan(nImages,1);
    tabla.Microglia_Density_Plaque = nan(nImages,1);
    
    tabla.Mean_Vol_Plaques = nan(nImages,1);
    tabla.Median_Vol_Plaques = nan(nImages,1);
    tabla.P75_Vol_Plaques	 = nan(nImages,1);  
    tabla.IQR_Vol_Plaques = nan(nImages,1);
    tabla.Total_Vol_Plaques = nan(nImages,1);
    tabla.Occupied_Vol_Plaques = nan(nImages,1);
    
    tabla.Mean_Vol_Plaques_Valid = nan(nImages,1);
    tabla.Median_Vol_Plaques_Valid = nan(nImages,1);
    tabla.P75_Vol_Plaques_Valid	 = nan(nImages,1);  
    tabla.IQR_Vol_Plaques_Valid = nan(nImages,1);
    tabla.Total_Vol_Plaques_Valid = nan(nImages,1);
    tabla.Occupied_Vol_Plaques_Valid = nan(nImages,1);
    
    tabla.N_WT_Spheres = nan(nImages,1);
    tabla.N_Non_Plaque_Spheres = nan(nImages,1);
    tabla.N_Plaque_Spheres = nan(nImages,1);
    tabla.N_Completed_Plaque_Spheres = nan(nImages,1);
    
    tabla.Vol_WT_Spheres = nan(nImages,1);
    tabla.Vol_Non_Plaque_Spheres = nan(nImages,1);
    tabla.Vol_Plaque_Sphere = nan(nImages,1);
    tabla.Vol_Overlap_Plaque_Spheres = nan(nImages,1);

end
