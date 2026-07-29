%EXAMPLE_PROGRAMMATIC_CONFIG Configure and run the pipeline without dialogs.

config = createMicrogliaConfig("paper_metrics");

config.paths.masks = "/path/to/Masks";          % Contains WT/ and APP/.
config.paths.microglia = "/path/to/Microglia";  % Contains WT/ and APP/.
config.paths.plaques = "/path/to/Plaques";
config.paths.output = "/path/to/Results";
config.metadata.file = "/path/to/metadata.xlsx";

% Read cortical-layer eligibility from the metadata Excel file.
config.layers.imageSelection.mode = "excel";
config.layers.imageSelection.column = "UseForLayerAnalysis";

% Alternative manual layer selection:
% config.layers.imageSelection.mode = "manual";
% config.layers.imageSelection.selectedFiles = ["Image_01"; "Image_03"];

% Voronoi is disabled by default and is not part of the paper preset.
% It can only be enabled deliberately in a custom configuration:
% config.voronoi.enabled = true;
% config.voronoi.boundaryMode = "exclude"; % or "include"
% config.voronoi.contexts.global.enabled = true;
% config.voronoi.contexts.layers.enabled = true;
% config.paths.voronoiCentroids = "/path/to/VoronoiCentroids";
% config.paths.voronoiResults = "/path/to/VoronoiResults";

% Keep parallel execution disabled until memory requirements are tested.
config.parallel.enabled = false;

runMicrogliaAnalysis(config);
