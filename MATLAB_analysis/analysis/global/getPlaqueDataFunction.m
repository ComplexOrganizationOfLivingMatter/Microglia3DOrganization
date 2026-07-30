function tablaReturn =  getPlaqueDataFunction(imgMask, imgPlaque, tableData,  excelRow, tablaReturn, nTabla)
%GETPLAQUEDATAFUNCTION Calculate image-level plaque counts, densities, and occupied volumes.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    desire_pxls = [tableData.XCorte2_pxl(excelRow), tableData.Ycorte_pxl(excelRow), tableData.Zcorte_pxl(excelRow)];
    start = [tableData.CoordXCorte2_pxl(excelRow)+1, tableData.CoordYCorte_pxl(excelRow)+1, tableData.CoordZCorte_pxl(excelRow)+1];
    
    correctionFactor = tableData.Correction_Factor(excelRow); 
    
    xyResolution = tableData.ResolucionXY_um_pxl(excelRow);
    zResolution = tableData.ResolucionZ_um_pxl(excelRow);

    imgOrtho = false(size(imgPlaque));
    imgOrtho(start(2):(start(2)+desire_pxls(2)), start(1):(start(1)+desire_pxls(1)), start(3):(start(3)+desire_pxls(3))) = true;

    targetZone = (imgMask & imgOrtho);
    volumeTotal = nnz(imgMask) * xyResolution * xyResolution * zResolution * correctionFactor^3;
    validVolume = nnz(targetZone) * xyResolution * xyResolution * zResolution * correctionFactor^3;
    clear imgMask;
    
    imgPlaqueValid = imgPlaque;
    imgPlaqueValid(~targetZone) = 0;
    
    nPlaques = length(unique(imgPlaque))-1;
    nValidPlaques = length(unique(imgPlaqueValid))-1;

    volOcuppiedTotal = nnz(imgPlaque>0) * xyResolution * xyResolution * zResolution * correctionFactor^3;
    volOcuppiedValid = nnz(imgPlaqueValid>0) * xyResolution * xyResolution * zResolution * correctionFactor^3;
    
    tablaReturn.PlaqueNumberTotal(nTabla) = nPlaques;
    tablaReturn.PlaqueNumberValid(nTabla) = nValidPlaques;
    tablaReturn.PlaqueDensityTotal(nTabla) = (nPlaques / volumeTotal) * 1e9;
    tablaReturn.PlaqueDensityValid(nTabla) = (nValidPlaques / validVolume) * 1e9;
    tablaReturn.PlaqueVolumeOccupied_Total(nTabla) = volOcuppiedTotal;
    tablaReturn.PlaqueVolumeOccupied_Valid(nTabla) = volOcuppiedValid;
    tablaReturn.PlaquePercOccupied_Total(nTabla) = volOcuppiedTotal/volumeTotal;
    tablaReturn.PlaquePercOccupied_Valid(nTabla) = volOcuppiedValid/validVolume;
    
end
