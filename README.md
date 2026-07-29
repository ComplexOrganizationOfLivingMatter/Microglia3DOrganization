# Microglia 3D Organization

This repository contains the computational resources used for the three-dimensional analysis of microglial organization in the mouse cerebral cortex under physiological and Alzheimer's disease conditions.

The project combines deep-learning-based image segmentation with quantitative analysis of microglial and amyloid-β plaque distributions in cleared brain tissue. The repository includes the trained BiaPy models used for image segmentation and the MATLAB pipeline used to extract the quantitative measurements reported in the associated manuscript.

## Project overview

The main objectives of the project are:

- To characterize the 3D spatial distribution of microglia in the cerebral cortex under physiological conditions.
- To identify alterations in microglial density and spatial organization in an Alzheimer's disease mouse model.
- To quantify the relationship between microglia and amyloid-β plaques.
- To develop reproducible computational workflows for segmentation and quantitative analysis of 3D microscopy images.

The segmentation workflow includes three separate models:

1. Instance segmentation of microglial somas.
2. Instance segmentation of amyloid-β plaques.
3. Semantic segmentation of tissue masks.

## Repository contents

```text
.
├── README.md
├── BiaPy_models/
│   ├── README.md
│   ├── LICENSE.md
│   ├── Microglia/
│   ├── Plaques/
│   └── Masks/
└── MATLAB_analysis/
    ├── analysis/
    │   ├── global/
    │   ├── layers/
    │   ├── plaques/
    │   └── spheres/
    ├── config/
    │   ├── catalog/
    │   ├── interactive/
    │   ├── presets/
    │   └── validation/
    ├── docs/
    ├── examples/
    ├── preprocessing/
    │   ├── instances/
    │   ├── plaques/
    │   └── spheres/
    ├── tables/
    ├── tests/
    ├── utils/
    ├── runMicrogliaAnalysis.m
    └── setupMicrogliaAnalysis.m
```

The repository is organized into two main components:

- `BiaPy_models/`: configuration files and trained weights for the three segmentation models.
- `MATLAB_analysis/`: the quantitative analysis pipeline used to process the final segmentations and generate image-level, plaque-level, layer-level and sphere-level measurements.

## BiaPy models

The `BiaPy_models/` directory contains the configuration files and trained weights used for the segmentation steps described in the manuscript.

| Directory | Segmentation task | BiaPy version |
|---|---|---:|
| `Microglia/` | 3D instance segmentation of microglial somas | 3.4.6 |
| `Plaques/` | 3D instance segmentation of amyloid-β plaques | 3.4.6 |
| `Masks/` | 3D semantic segmentation of tissue masks | 3.3.3 |

Each model directory contains the YAML configuration file and the corresponding trained weights:

```text
BiaPy_models/
├── README.md
├── LICENSE.md
├── Microglia/
│   ├── 3d_instance_segmentation_microgliaSomaGausian.yaml
│   └── unet_3d_microgliaSoma_instance_gausian_0-checkpoint-best.pth
├── Plaques/
│   ├── 3d_instance_segmentation_microgliaPlaques.yaml
│   └── unet_3d_microgliaPlaques_0-checkpoint-best.pth
└── Masks/
    ├── 3d_semantic_segmentation_microglia_mask.yaml
    └── model_weights_unet_3d_microgliaMask_0.h5
```

Before running a model, replace the local paths stored in its YAML file with paths valid for the target system and dataset. Compatibility with BiaPy versions other than those used for training has not been systematically tested.

Further information is provided in [`BiaPy_models/README.md`](BiaPy_models/README.md).

## MATLAB quantitative analysis

The `MATLAB_analysis/` directory contains the analysis pipeline used to extract the quantitative measurements reported in the manuscript. The default workflow is centered on the measurements required for the paper. Additional spatial, directional and Voronoi-based analyses are available but are disabled in the paper preset.

### Analyses reproduced from the paper

#### Global image-level measurements

For each image, the pipeline quantifies:

- total image volume;
- analyzed tissue volume;
- number of segmented microglial somas;
- microglial density in cells/mm³;
- total plaque counts in AD images;
- plaque density in plaques/mm³;
- plaque volume;
- fraction of the total tissue occupied by plaques;
- microglial measurements in plaque-associated and non-plaque regions when those regions are generated.

The analyzed region is defined by the tissue mask and the configured crop. Physical measurements are calculated using the XY and Z resolutions and the linear shrinkage correction factor supplied in the metadata or configuration.

#### Individual plaque measurements

Each plaque is represented by one row in the individual plaque table. The paper-oriented output includes:

- image and plaque identifiers;
- plaque volume;
- inside analyzed-tissue plaque volume;
- plaque centroid;
- cortical layer assignment;
- distance from the plaque centroid to the cortical surface;
- number and density of associated microglia;
- inclusion and completeness flags.

The plaque flags are interpreted as follows:

- `isCompleted`: the plaque does not touch the original image boundary.
- `isInsideCrop`: at least part of the plaque lies within the analyzed crop.
- `isCompletedInsideCrop`: the complete plaque lies within the analyzed crop.

All segmented plaques are retained in the individual plaque table, including plaques outside the analyzed crop. The flags allow downstream analyses to select the appropriate subset.

#### Cortical layer analysis

The layer module defines cortical bands from the tissue surface and quantifies microglia and plaques within each band. The default layer definitions are:

- Medial cortex: Layer 1, Layer 2–3, Layer 5 and Layer 6.
- Lateral cortex: Layer 1, Layer 2–3, Layer 4 and Layer 5.

Default layer widths are stored in the configuration and are adjusted by the image-specific correction factor. For each image and layer, the paper output includes:

- analyzed layer volume;
- number of microglia;
- microglial density;
- number of plaques;
- plaque density.

Images without valid layer information can be excluded from the dedicated layer analysis while remaining available for global, plaque and sphere analyses. In plaque and sphere tables, those images are labeled with `NoInfo` in the layer field.

#### Plaque-associated and non-plaque spheres

In AD images, plaque-centered spheres are placed at plaque centroids. Additional non-plaque spheres are placed in tissue regions not occupied by plaque-associated spheres. WT images are analyzed with reference spheres generated using the non-plaque sphere radius.

The analysis distinguishes:

- WT reference spheres;
- AD non-plaque spheres;
- AD plaque-centered spheres;
- sphere-to-plaque relationships.

The main paper-oriented measurements include:

- sphere radius and valid analyzed volume;
- number of microglia;
- microglial density;
- sphere completeness;
- plaque volume and plaque occupancy for plaque-centered spheres;
- distance to the nearest plaque for non-plaque spheres;
- cortical layer assignment when layer information is available.

Multiple plaque/non-plaque radius pairs can be analyzed in the same run.

## Paper metric preset

The default configuration uses:

```text
MATLAB_analysis/config/presets/paper_metrics.json
```

This preset enables the metrics used in the manuscript and disables advanced distance, radial, directional, spatial-statistics and Voronoi measurements.

The file:

```text
MATLAB_analysis/examples/paper_metrics_config.json
```

contains the paper metric selection as a reusable configuration fragment. A complete editable configuration is provided at:

```text
MATLAB_analysis/examples/config_template_full.json
```

The full template can be adapted by changing paths, metadata mappings and dataset-specific parameters while retaining the `paper_metrics` selection.

## Running the MATLAB pipeline

### 1. Add the project to the MATLAB path

From the `MATLAB_analysis/` directory, run:

```matlab
setupMicrogliaAnalysis
```

### 2. Interactive mode

Run:

```matlab
runMicrogliaAnalysis
```

When no configuration is supplied, MATLAB opens an interactive workflow. It starts from the paper metric preset and asks the user to select:

- models to analyze;
- mask, microglia, plaque and output folders;
- the metadata Excel file;
- the metadata columns corresponding to each required field;
- image resolution and shrinkage correction sources;
- analyses to run;
- images with valid cortical-layer information;
- plaque dilation mode and radius;
- sphere generation mode and radius pairs;
- optional derived-image outputs;
- optional parallel execution;
- paper metrics and, separately, any advanced metrics.

Advanced metrics are not selected unless the user explicitly enables them.

### 3. Configuration file

A JSON or MAT configuration can be supplied directly:

```matlab
runMicrogliaAnalysis("path/to/config.json")
```

The loaded configuration is merged with the default paper configuration during validation, so a configuration file may override only the required fields. For fully reproducible runs, using a complete configuration is recommended.

Relative paths in a JSON configuration are resolved relative to the location of that configuration file.

### 4. MATLAB structure

The pipeline can also be configured programmatically:

```matlab
config = createMicrogliaConfig("paper_metrics");
config.paths.masks = "/path/to/Masks";
config.paths.microglia = "/path/to/Microglia";
config.paths.plaques = "/path/to/Plaques";
config.paths.output = "/path/to/Results";
config.metadata.file = "/path/to/metadata.xlsx";

runMicrogliaAnalysis(config);
```

See [`MATLAB_analysis/examples/example_programmatic_config.m`](MATLAB_analysis/examples/example_programmatic_config.m) and [`MATLAB_analysis/docs/CONFIG_TEMPLATE_REFERENCE.md`](MATLAB_analysis/docs/CONFIG_TEMPLATE_REFERENCE.md).

## Required input data

### Image folders

The mask and microglia roots must contain one subfolder per model, using the configured model labels:

```text
Masks/
├── WT/
└── APP/

Microglia/
├── WT/
└── APP/
```

Plaque images are stored in a single plaque folder because they are only used for the AD model:

```text
Plaques/
├── image_001.tif
├── image_002.tif
└── ...
```

Input image requirements:

- tissue masks: binary 3D TIFF stacks;
- microglia: labeled 3D instance-segmentation TIFF stacks;
- plaques: labeled 3D instance-segmentation TIFF stacks;
- filenames: must correspond to the filename column in the metadata table.

### Metadata Excel file

The source column names are configurable. The default mapping expects:

| Internal field | Default column | Meaning | Required |
|---|---|---|---:|
| `fileName` | `Archivo` | Image filename without extension | Yes |
| `model` | `Modelo` | Model label, normally `WT` or `APP` | Yes |
| `cortexArea` | `Zona` | `Medial` or `Lateral` | Yes |
| `mouse` | `IDRaton` | Mouse identifier | Recommended |
| `sex` | `Sexo` | Sex | Optional |
| `section` | `IDCorte` | Brain-section identifier | Optional |
| `image` | `IDImage` | Image identifier | Optional |
| `bregmaLevel` | `BregmaLevel` | Bregma level or group | Optional |
| `cropStartX/Y/Z` | `CoordXCorte2_pxl`, `CoordYCorte_pxl`, `CoordZCorte_pxl` | Start coordinates of the valid crop | Yes |
| `cropSizeX/Y/Z` | `XCorte2_pxl`, `Ycorte_pxl`, `Zcorte_pxl` | Size of the valid crop | Yes |
| `layersEnabled` | `Layers` | Whether layer information is valid | Conditional |
| XY resolution | `ResolucionXY_um_pxl` | XY calibration in µm/pixel | Required in Excel mode |
| Z resolution | `ResolucionZ_um_pxl` | Z calibration in µm/pixel | Required in Excel mode |
| correction factor | `Correction_Factor` | Linear tissue-shrinkage correction | Required in Excel mode |

The exact source names can be selected interactively or changed in the configuration.

## Main processing stages

- `preprocessing/instances/`: instance-label preprocessing utilities.
- `preprocessing/plaques/`: generation of dilated plaque labels.
- `preprocessing/spheres/`: generation of plaque and non-plaque sphere definitions.
- `analysis/global/`: image-level microglia, plaque and AD-region measurements.
- `analysis/plaques/`: one-row-per-plaque measurements.
- `analysis/layers/`: cortical layer assignment and layer-level measurements.
- `analysis/spheres/`: sphere-level and sphere-to-plaque measurements.
- `tables/`: initialization, normalization and export of output tables.
- `config/`: default configuration, presets, validation and interactive dialogs.
- `utils/`: image I/O, metrics, geometry, logging and shared helper functions.

A complete function inventory is available in [`MATLAB_analysis/docs/FUNCTION_INVENTORY.csv`](MATLAB_analysis/docs/FUNCTION_INVENTORY.csv).

## Output structure

A typical analysis produces:

```text
Results/
├── Configuration/
│   ├── microglia_config.json
│   └── microglia_config.mat
├── Data/
│   ├── General/
│   ├── Layer/
│   ├── Plaque/
│   └── Spheres/
├── DerivedImages/          # Created only when derived images are written
└── Log/
    └── MicrogliaAnalysis.log
```

`DerivedImages/` and its subfolders are created only when required by the selected outputs or by the sphere-analysis workflow. Temporarily generated dilated plaques are deleted after the run.

The `Configuration/` directory stores the exact configuration used for the run. The log records the start, completion, duration and errors of each processing stage.

## Output tables

The main files are:

| File | Main unit represented |
|---|---|
| `global_image_data.xlsx` | One image per row |
| `individual_plaque_data.xlsx` | One plaque per row |
| `cortical_layer_data.xlsx` | One image per row, separated by model and cortical region sheets |
| sphere result workbooks | Image-level summaries, individual spheres, sphere-to-plaque relations and combined summaries |

The global workbook contains the sheets `WT`, `AD`, `ADNoPlaques` and `ADPlaques` when those datasets are available.

The cortical layer workbook can contain:

- `WT_Lateral`
- `WT_Medial`
- `AD_Lateral`
- `AD_Medial`
- `ADNoPlaques_Lateral`
- `ADNoPlaques_Medial`
- `ADPlaques_Lateral`
- `ADPlaques_Medial`

Sphere results contain separate sheets for:

- `WTSpheres`
- `NonPlaqueSpheres`
- `PlaqueSpheres`
- `SpherePlaqueRelation`
- combined WT and AD summaries

A detailed dictionary of files, sheets, columns and units is provided in [`MATLAB_analysis/docs/OUTPUT_TABLES.md`](MATLAB_analysis/docs/OUTPUT_TABLES.md).

## Recommended workflow for reproducing the manuscript analyses

1. Run the BiaPy models and manually curate the final segmentations.
2. Organize masks and microglia segmentations into model-specific folders and place AD plaque segmentations in the plaque folder.
3. Complete the metadata Excel file, including calibration, correction factor and crop coordinates.
4. Adapt `examples/config_template_full.json` to the local dataset while keeping the paper metric preset.
5. Run `setupMicrogliaAnalysis`.
6. Run `runMicrogliaAnalysis(...)` with the configuration file.
7. Use the generated Excel tables as input for the statistical analyses described in the manuscript.

The MATLAB pipeline generates the quantitative measurements. Statistical models and final manuscript figures may be performed in separate analysis scripts.

## Other advanced measurements

The pipeline also contains optional measurements that are not required for the main paper workflow, including:

- pairwise and nearest-neighbor microglial distances;
- normalized radial distributions inside spheres;
- central-third microglial fraction;
- Ripley K3 and pair-correlation deviations;
- polarization and directional alignment metrics;
- additional sphere-to-plaque influence measurements.

These metrics can be selected interactively or enabled through `config/presets/all_metrics.json`. Their definitions and output fields are described in [`MATLAB_analysis/docs/ADVANCED_METRICS.md`](MATLAB_analysis/docs/ADVANCED_METRICS.md).

## Voronoi analysis

Voronoi analysis is disabled by default and is not part of the paper metric preset. When enabled through a custom configuration, the pipeline reads externally generated centroid and Voronoi result files and summarizes:

- valid Voronoi cell count;
- number of neighbors;
- cell volume;
- cell surface area;
- distance between neighboring seeds.

Voronoi generation itself is not included in this repository. Required inputs, supported contexts and boundary handling are described in [`MATLAB_analysis/docs/VORONOI_ANALYSIS.md`](MATLAB_analysis/docs/VORONOI_ANALYSIS.md).

## Dependencies

The core pipeline requires MATLAB with the Image Processing Toolbox and Statistics and Machine Learning Toolbox. Parallel Computing Toolbox is optional and is only required when parallel execution is enabled.

See [`MATLAB_analysis/docs/DEPENDENCIES.md`](MATLAB_analysis/docs/DEPENDENCIES.md).

## BiaPy license

BiaPy is distributed under the MIT License. A copy of the BiaPy license is included as [`BiaPy_models/LICENSE.md`](BiaPy_models/LICENSE.md).

The license in that directory applies to the BiaPy software. The configuration files and trained weights are provided as research resources associated with this project.

## Citation

Citation information for the associated manuscript will be added when available.
