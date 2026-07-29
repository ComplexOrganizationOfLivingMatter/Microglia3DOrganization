function tabla = prepareSphere_PlaqueDataTable(tabla, nRow)
%PREPARESPHERE_PLAQUEDATATABLE Initialize the sphere-to-plaque relation result table.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    tabla.IDImage = nan(nRow, 1); 
    tabla.ImageSphereID = nan(nRow, 1);
    tabla.IDSphere = nan(nRow, 1);    
    tabla.IDPlaque = nan(nRow, 1);
    
    tabla.VolPlaque = nan(nRow,1);
    tabla.DistToPlaque = nan(nRow,1);
    tabla.DistanceToPlaqueSurface = nan(nRow,1);
    
    tabla.u_plaque_x = nan(nRow,1);
    tabla.u_plaque_y = nan(nRow,1);
    tabla.u_plaque_z = nan(nRow,1);
     
    tabla.Pol = nan(nRow,1);
    tabla.Align = nan(nRow,1);
    tabla.meanCos = nan(nRow,1);
    
    tabla.zAlign = nan(nRow,1);
    tabla.pEmpAlign = nan(nRow,1);
    tabla.zMeanCos = nan(nRow,1);
    tabla.pEmpMeanCos = nan(nRow,1);
    
    
    tabla.AnglePlaqueMaxAlign = nan(nRow,1);  
    tabla.AnglePlaqueMaxCos = nan(nRow,1);
    
    tabla.isClosest = nan(nRow,1);
    tabla.isMostInfluencer = nan(nRow,1);
    
end
