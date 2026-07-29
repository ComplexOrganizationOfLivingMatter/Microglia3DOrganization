function metadataFile = prepareNormalizedMetadata(config)
%PREPARENORMALIZEDMETADATA Create a temporary metadata table with standard names.
%
% The function maps user-selected columns to the internal schema used by the
% analysis modules, applies manual calibration values when requested, and
% filters rows according to the selected WT and AD models.

    sourceTable = readtable(config.metadata.file, 'Sheet', config.metadata.sheet, ...
        'VariableNamingRule', 'preserve');
    columns = config.metadata.columns;

    modelValues = string(sourceTable.(columns.model));
    keepRows = false(height(sourceTable), 1);
    if config.models.wt
        keepRows = keepRows | strcmpi(modelValues, string(config.labels.models.control));
    end
    if config.models.ad
        keepRows = keepRows | strcmpi(modelValues, string(config.labels.models.ad));
    end
    sourceTable = sourceTable(keepRows, :);

    normalized = table();
    normalized.Archivo = copyColumn(sourceTable, columns.fileName, "");

    originalModel = string(copyColumn(sourceTable, columns.model, ""));
    normalized.Modelo = originalModel;
    normalized.Modelo(strcmpi(originalModel, string(config.labels.models.control))) = "WT";
    normalized.Modelo(strcmpi(originalModel, string(config.labels.models.ad))) = "APP";

    originalRegion = string(copyColumn(sourceTable, columns.cortexArea, ""));
    normalized.Zona = originalRegion;
    normalized.Zona(strcmpi(originalRegion, string(config.labels.regions.lateral))) = "Lateral";
    normalized.Zona(strcmpi(originalRegion, string(config.labels.regions.medial))) = "Medial";

    normalized.IDRaton = copyColumn(sourceTable, columns.mouse, "");
    normalized.Sexo = copyColumn(sourceTable, columns.sex, "");
    normalized.IDCorte = copyColumn(sourceTable, columns.section, "");
    normalized.IDImage = copyColumn(sourceTable, columns.image, "");
    normalized.BregmaLevel = copyColumn(sourceTable, columns.bregmaLevel, "");

    layerInformationAvailable = resolveLayerImageSelection(sourceTable, config);
    normalized.LayerInformationAvailable = logical(layerInformationAvailable);
    normalized.Layers = repmat("NO", height(sourceTable), 1);
    normalized.Layers(layerInformationAvailable) = "YES";

    normalized.XCorte2_pxl = copyColumn(sourceTable, columns.cropSizeX, NaN);
    normalized.Ycorte_pxl = copyColumn(sourceTable, columns.cropSizeY, NaN);
    normalized.Zcorte_pxl = copyColumn(sourceTable, columns.cropSizeZ, NaN);
    normalized.CoordXCorte2_pxl = copyColumn(sourceTable, columns.cropStartX, NaN);
    normalized.CoordYCorte_pxl = copyColumn(sourceTable, columns.cropStartY, NaN);
    normalized.CoordZCorte_pxl = copyColumn(sourceTable, columns.cropStartZ, NaN);

    if config.resolution.mode == "excel"
        normalized.ResolucionXY_um_pxl = sourceTable.(config.resolution.xyColumn);
        normalized.ResolucionZ_um_pxl = sourceTable.(config.resolution.zColumn);
    else
        normalized.ResolucionXY_um_pxl = repmat(config.resolution.xy_um_per_px, height(sourceTable), 1);
        normalized.ResolucionZ_um_pxl = repmat(config.resolution.z_um_per_px, height(sourceTable), 1);
    end

    switch string(config.correction.mode)
        case "excel"
            normalized.Correction_Factor = sourceTable.(config.correction.column);
        case "manual"
            normalized.Correction_Factor = repmat(config.correction.value, height(sourceTable), 1);
        otherwise
            normalized.Correction_Factor = ones(height(sourceTable), 1);
    end

    metadataFile = fullfile(tempdir, sprintf('microglia_metadata_%s.xlsx', char(java.util.UUID.randomUUID)));
    writetable(normalized, metadataFile);
end

function values = copyColumn(sourceTable, columnName, defaultValue)
%COPYCOLUMN Copy a selected metadata column or create a default column.
    columnName = string(columnName);
    if strlength(columnName) == 0
        if isstring(defaultValue) || ischar(defaultValue)
            values = repmat(string(defaultValue), height(sourceTable), 1);
        else
            values = repmat(defaultValue, height(sourceTable), 1);
        end
    else
        values = sourceTable.(columnName);
    end
end
