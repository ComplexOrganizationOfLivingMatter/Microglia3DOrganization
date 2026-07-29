# MATLAB analysis workflow

This document provides a compact technical overview of the MATLAB pipeline. The repository-level README presents the manuscript-oriented workflow; this file focuses on how the source tree maps to processing stages.

## Entry points

### `setupMicrogliaAnalysis.m`

Adds the complete `MATLAB_analysis/` source tree to the MATLAB path.

```matlab
setupMicrogliaAnalysis
```

### `runMicrogliaAnalysis.m`

Executes the pipeline in one of three modes:

```matlab
runMicrogliaAnalysis                         % interactive configuration
runMicrogliaAnalysis("config.json")          % JSON or MAT configuration
runMicrogliaAnalysis(config)                 % MATLAB structure
```

The runner:

1. validates and completes the configuration;
2. creates the output structure;
3. saves the validated configuration;
4. prepares normalized metadata;
5. prepares dilated plaque labels;
6. executes enabled analysis modules;
7. records stage status and errors in the log;
8. removes temporary metadata and temporary derived images.

## Source-tree organization

### `analysis/global/`

Image-level measurements for:

- WT whole-image regions;
- AD whole-image regions;
- AD regions outside dilated plaques;
- AD plaque-associated regions.

### `analysis/plaques/`

Individual plaque measurements, including plaque volume, completeness, cortical position and associated microglia.

### `analysis/layers/`

Construction of layer maps and quantification by cortical layer and model.

### `analysis/spheres/`

Image-level and individual analyses of WT, non-plaque and plaque-centered spheres, plus sphere-to-plaque relationships and combined summaries.

### `preprocessing/plaques/`

Generation of dilated plaque labels using the configured physical radius.

### `preprocessing/spheres/`

Generation of sphere centers, sphere masks and per-sphere index files.

### `preprocessing/instances/`

Instance-label preparation and centroid extraction utilities.

### `config/`

- `createMicrogliaConfig.m`: complete default configuration.
- `interactive/`: graphical selection workflow.
- `presets/`: paper and all-metrics selections.
- `validation/`: path, metadata, parameter and dependency checks.
- `createOutputStructure.m`: standardized output paths.
- `prepareNormalizedMetadata.m`: internal normalized metadata table.
- `prepareDilatedPlaques.m`: existing, saved or temporary dilated-plaque mode.

### `tables/`

Initializes the output schemas and standardizes the final tables based on enabled metric groups.

### `utils/`

Shared functions for:

- TIFF I/O;
- crop and geometry operations;
- label storage types;
- layer eligibility;
- metric dependencies;
- logging;
- distances and spatial statistics;
- Voronoi summaries.

### `tests/`

Regression tests for known issues, including:

- density units;
- label-storage type;
- crop and layer selection;
- plaque enumeration;
- output paths;
- sphere radius validation;
- sphere-boundary handling;
- known table and sheet regressions.

## Output and reproducibility

Every run writes the validated configuration to `Configuration/` and stage information to `Log/MicrogliaAnalysis.log`.

The main quantitative outputs are under `Data/`. Optional or required generated image stacks are centralized under `DerivedImages/`, which is created only when needed.

For table definitions, see [`OUTPUT_TABLES.md`](OUTPUT_TABLES.md). For all configurable fields, see [`CONFIG_TEMPLATE_REFERENCE.md`](CONFIG_TEMPLATE_REFERENCE.md).
