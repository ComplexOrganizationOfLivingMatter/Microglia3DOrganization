function config = createMicrogliaConfig(presetName)
%CREATEMICROGLIACONFIG Create a complete pipeline configuration structure.
%
% The default configuration uses the paper metric preset and disables
% Voronoi. Voronoi can only be enabled through a custom configuration file
% or by editing the returned structure programmatically.

    if nargin < 1 || strlength(string(presetName)) == 0
        presetName = "paper_metrics";
    end

    config.version = "2.3.17";

    config.paths.masks = "";
    config.paths.microglia = "";
    config.paths.plaques = "";
    config.paths.voronoiCentroids = "";
    config.paths.voronoiResults = "";
    config.paths.output = "";
    config.paths.dilatedPlaques = "";
    config.paths.existingSphereFolders = strings(0, 1);

    config.metadata.file = "";
    config.metadata.sheet = 1;
    config.metadata.columns.fileName = "Archivo";
    config.metadata.columns.model = "Modelo";
    config.metadata.columns.cortexArea = "Zona";
    config.metadata.columns.mouse = "IDRaton";
    config.metadata.columns.sex = "Sexo";
    config.metadata.columns.section = "IDCorte";
    config.metadata.columns.image = "IDImage";
    config.metadata.columns.bregmaLevel = "BregmaLevel";
    config.metadata.columns.layersEnabled = "Layers";
    config.metadata.columns.cropSizeX = "XCorte2_pxl";
    config.metadata.columns.cropSizeY = "Ycorte_pxl";
    config.metadata.columns.cropSizeZ = "Zcorte_pxl";
    config.metadata.columns.cropStartX = "CoordXCorte2_pxl";
    config.metadata.columns.cropStartY = "CoordYCorte_pxl";
    config.metadata.columns.cropStartZ = "CoordZCorte_pxl";

    config.resolution.mode = "excel";
    config.resolution.xy_um_per_px = 0.4545;
    config.resolution.z_um_per_px = 0.5669;
    config.resolution.xyColumn = "ResolucionXY_um_pxl";
    config.resolution.zColumn = "ResolucionZ_um_pxl";

    config.correction.mode = "excel";
    config.correction.value = 1;
    config.correction.column = "Correction_Factor";

    config.labels.models.control = "WT";
    config.labels.models.ad = "APP";
    config.labels.regions.lateral = "Lateral";
    config.labels.regions.medial = "Medial";
    config.labels.outputs.ad = "AD";
    config.labels.outputs.adNoPlaques = "ADNoPlaques";
    config.labels.outputs.adPlaques = "ADPlaques";

    config.models.wt = true;
    config.models.ad = true;

    config.layers.medial.names = ["Layer 1", "Layer 2-3", "Layer 5", "Layer 6"];
    config.layers.medial.widths_um = [105, 175, 295, 340];
    config.layers.lateral.names = ["Layer 1", "Layer 2-3", "Layer 4", "Layer 5"];
    config.layers.lateral.widths_um = [135, 230, 130, 340];
    config.layers.imageSelection.mode = "all";
    config.layers.imageSelection.column = "";
    config.layers.imageSelection.selectedFiles = strings(0, 1);
    config.layers.noInformationLabel = "NoInfo";

    config.dilatedPlaques.mode = "generate-and-save";
    config.dilatedPlaques.radius_um = 9;

    config.spheres.mode = "generate";
    config.spheres.radiusPairs_um = [100, 100];

    config.parallel.enabled = false;
    config.parallel.numberOfWorkers = 2;
    config.parallel.modules.globalMicroglia = false;
    config.parallel.modules.individualPlaques = false;
    config.parallel.modules.layers = false;
    config.parallel.modules.sphereGeneration = false;
    config.parallel.modules.sphereAnalysis = false;

    config.analyses.globalMicroglia.enabled = true;
    config.analyses.globalPlaques.enabled = true;
    config.analyses.individualPlaques.enabled = true;
    config.analyses.layers.enabled = true;
    config.analyses.spheres.enabled = true;

    config.voronoi.enabled = false;
    config.voronoi.boundaryMode = "exclude";
    config.voronoi.contexts.global.enabled = false;
    config.voronoi.contexts.layers.enabled = false;
    config.voronoi.contexts.spheres.enabled = false;
    config.voronoi.contexts.individualPlaques.enabled = false;
    config.voronoi.contexts.adNoPlaques.enabled = false;
    config.voronoi.contexts.adPlaques.enabled = false;

    catalog = getMetricCatalog();
    config.metrics = selectMetricPreset(catalog, "paper_metrics");

    config.outputs.saveDilatedPlaques = true;
    config.outputs.saveLayerImages = false;
    config.outputs.saveSphereImages = false;
    config.outputs.saveADNoPlaquesImages = false;
    config.outputs.saveADPlaquesImages = false;
    config.outputs.overwrite = false;

    config.outputFiles.globalData = "global_image_data.xlsx";
    config.outputFiles.individualPlaques = "individual_plaque_data.xlsx";
    config.outputFiles.layers = "cortical_layer_data.xlsx";
    config.outputFiles.spheres = "sphere_data.xlsx";

    presetPath = fullfile(fileparts(mfilename('fullpath')), 'presets', string(presetName) + ".json");
    if isfile(presetPath)
        config = mergeStructs(config, loadMicrogliaConfig(presetPath));
    else
        error('Unknown metric preset: %s', presetName);
    end
end
