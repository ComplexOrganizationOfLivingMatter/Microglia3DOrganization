# Complete configuration reference

The pipeline accepts a MATLAB structure, a JSON file or a MAT file containing a variable named `config`. During validation, the supplied configuration is merged with the default paper configuration, so omitted fields inherit default values.

## Available presets and examples

| File | Purpose |
|---|---|
| `config/presets/paper_metrics.json` | Metric selection used for the manuscript-oriented workflow |
| `config/presets/all_metrics.json` | All standard and advanced metric groups; Voronoi analysis included |
| `examples/config_template_full.json` | Complete editable configuration with every configurable field |
| `examples/example_programmatic_config.m` | Example of building a configuration in MATLAB |

For a reproducible paper-oriented run, copy `examples/config_template_full.json`, adapt paths and metadata mappings, and retain the `paper_metrics` metric section.

## `paths`

```json
"paths": {
  "masks": "/path/to/Masks",
  "microglia": "/path/to/Microglia",
  "plaques": "/path/to/Plaques",
  "voronoiCentroids": "",
  "voronoiResults": "",
  "output": "/path/to/Results",
  "dilatedPlaques": "",
  "existingSphereFolders": []
}
```

- `masks`: root containing model-specific tissue-mask folders.
- `microglia`: root containing model-specific microglia instance-label folders.
- `plaques`: folder containing AD plaque instance-label TIFF files.
- `voronoiCentroids`: external centroid MAT files used only for Voronoi analysis.
- `voronoiResults`: external Voronoi MAT results used only for Voronoi analysis.
- `output`: output root.
- `dilatedPlaques`: existing dilated-plaque folder when `dilatedPlaques.mode` is `existing`.
- `existingSphereFolders`: one sphere-definition folder per radius pair when `spheres.mode` is `existing`.

Relative paths in JSON files are resolved relative to the configuration-file location.

## `metadata`

```json
"metadata": {
  "file": "/path/to/metadata.xlsx",
  "sheet": 1,
  "columns": {
    "fileName": "File",
    "model": "Model",
    "cortexArea": "CortexRegion",
    "mouse": "IDMouse",
    "sex": "Sex",
    "section": "IDSection",
    "image": "IDImage",
    "bregmaLevel": "BregmaLevel",
    "layersEnabled": "Layers",
    "cropSizeX": "XCropSize_pxl",
    "cropSizeY": "YCropSize_pxl",
    "cropSizeZ": "ZCropSize_pxl",
    "cropStartX": "StartXCrop_pxl",
    "cropStartY": "StartYCrop_pxl",
    "cropStartZ": "StartZCrop_pxl"
  }
}
```

The values are source-column names in the metadata workbook. Required fields are validated before processing begins.

The current schema uses `BregmaLevel`.

## `resolution`

```json
"resolution": {
  "mode": "excel",
  "xy_um_per_px": 0.4545,
  "z_um_per_px": 0.5669,
  "xyColumn": "ResolutionXY_um_pxl",
  "zColumn": "ResolutionZ_um_pxl"
}
```

Supported modes:

- `excel`: read XY and Z resolution for every metadata row.
- `manual`: use the fixed values in `xy_um_per_px` and `z_um_per_px`.

Both values must be positive and finite.

## `correction`

```json
"correction": {
  "mode": "excel",
  "value": 1,
  "column": "Correction_Factor"
}
```

Supported modes:

- `excel`: use one linear correction factor per image.
- `manual`: use the scalar value in `value`.
- `none`: use no shrinkage correction.

The correction factor is linear. Lengths are multiplied by the factor, areas by its square and volumes by its cube.

## `labels`

```json
"labels": {
  "models": {
    "control": "WT",
    "ad": "APP"
  },
  "regions": {
    "lateral": "Lateral",
    "medial": "Medial"
  },
  "outputs": {
    "ad": "AD",
    "adNoPlaques": "ADNoPlaques",
    "adPlaques": "ADPlaques"
  }
}
```

`labels.models` must match the metadata values and the mask/microglia subfolder names. The source AD label can be `APP`, while exported outputs use `AD`.

## `models`

```json
"models": {
  "wt": true,
  "ad": true
}
```

At least one model must be enabled. Plaque-specific analyses require `ad: true`.

## `layers`

```json
"layers": {
  "medial": {
    "names": ["Layer 1", "Layer 2-3", "Layer 5", "Layer 6"],
    "widths_um": [105, 175, 295, 340]
  },
  "lateral": {
    "names": ["Layer 1", "Layer 2-3", "Layer 4", "Layer 5"],
    "widths_um": [135, 230, 130, 340]
  },
  "imageSelection": {
    "mode": "all",
    "column": "",
    "selectedFiles": []
  },
  "noInformationLabel": "NoInfo"
}
```

The widths define successive cortical bands measured from the cortical surface. They are converted to pixels using image calibration and correction factor.

Supported selection modes:

- `all`: all metadata rows have usable layer information.
- `excel`: eligibility is read from a metadata column.
- `manual`: eligibility is determined by `selectedFiles`.

See [`LAYER_IMAGE_SELECTION.md`](LAYER_IMAGE_SELECTION.md).

## `dilatedPlaques`

```json
"dilatedPlaques": {
  "mode": "generate-temporary",
  "radius_um": 9
}
```

Supported modes:

- `existing`: read previously generated dilated plaque labels from `paths.dilatedPlaques`.
- `generate-and-save`: generate and retain dilated plaque images.
- `generate-temporary`: generate them for the current run and delete them afterward.

The radius is expressed in µm.

## `spheres`

```json
"spheres": {
  "mode": "generate",
  "radiusPairs_um": [
    [100, 70],
    [100, 100]
  ]
}
```

Each row contains:

```text
[plaque-sphere radius, non-plaque/WT sphere radius]
```

Supported modes:

- `generate`: create sphere definitions during the run.
- `existing`: reuse one precomputed sphere-definition folder per radius pair.

When sphere generation is enabled, the generated definitions are written because the sphere-analysis stage consumes them.

## `parallel`

```json
"parallel": {
  "enabled": false,
  "numberOfWorkers": 2,
  "modules": {
    "globalMicroglia": false,
    "individualPlaques": false,
    "layers": false,
    "sphereGeneration": false,
    "sphereAnalysis": false
  }
}
```

Parallel execution is optional. The Parallel Computing Toolbox is required only when `enabled` is `true`.

## `analyses`

```json
"analyses": {
  "globalMicroglia": {"enabled": true},
  "globalPlaques": {"enabled": true},
  "individualPlaques": {"enabled": true},
  "layers": {"enabled": true},
  "spheres": {"enabled": true}
}
```

- `globalMicroglia`: image-level tissue and microglia measurements.
- `globalPlaques`: image-level plaque measurements.
- `individualPlaques`: one row per plaque.
- `layers`: cortical layer assignment and layer summaries.
- `spheres`: plaque-centered, non-plaque and WT sphere analyses.

## `metrics`

```json
"metrics": {
  "preset": "paper_metrics",
  "selected": ["microglia_count", "..."],
  "groups": {}
}
```

The `selected` array contains metric identifiers. The paper preset enables:

- global microglia count, density and analyzed volume;
- global plaque count, density and occupied fraction;
- plaque volume, associated microglia and cortical-surface distance;
- layer volume, microglia density and plaque density;
- sphere volume, microglia density and nearest-plaque distance.

The validator resolves metric dependencies and disables Voronoi metrics when `voronoi.enabled` is false.

## `voronoi`

```json
"voronoi": {
  "enabled": false,
  "boundaryMode": "exclude",
  "contexts": {
    "global": {"enabled": false},
    "layers": {"enabled": false},
    "spheres": {"enabled": false},
    "individualPlaques": {"enabled": false},
    "adNoPlaques": {"enabled": false},
    "adPlaques": {"enabled": false}
  }
}
```

Voronoi is intentionally absent from the interactive workflow and must be enabled through a custom configuration. `boundaryMode` accepts `include` or `exclude`. Global analysis always excludes cells intersecting the outer region boundary.

See [`VORONOI_ANALYSIS.md`](VORONOI_ANALYSIS.md).

## `outputs`

```json
"outputs": {
  "saveDilatedPlaques": true,
  "saveLayerImages": false,
  "saveSphereImages": true,
  "saveADNoPlaquesImages": false,
  "saveADPlaquesImages": false,
  "overwrite": false
}
```

- `saveDilatedPlaques`: retain generated dilated plaque labels.
- `saveLayerImages`: retain layer label stacks.
- `saveSphereImages`: retain generated sphere definitions; forced to `true` when generated definitions are required for analysis.
- `saveADNoPlaquesImages`: save AD microglia labels outside plaque-associated regions.
- `saveADPlaquesImages`: save AD microglia labels inside plaque-associated regions.
- `overwrite`: controls replacement of existing outputs where supported.

`DerivedImages/` is created only when an image output is actually needed. Temporary dilated plaque folders are deleted after the run.

## `outputFiles`

```json
"outputFiles": {
  "globalData": "global_image_data.xlsx",
  "individualPlaques": "individual_plaque_data.xlsx",
  "layers": "cortical_layer_data.xlsx",
  "spheres": "sphere_data.xlsx"
}
```

These fields control the main workbook names. Sphere analysis may create additional workbooks for image-level, individual and combined outputs inside each radius folder.

## Saved run configuration

Every run saves:

```text
Results/Configuration/microglia_config.json
Results/Configuration/microglia_config.mat
```

These files contain the validated configuration actually used by the pipeline and should be retained with the results for reproducibility.
