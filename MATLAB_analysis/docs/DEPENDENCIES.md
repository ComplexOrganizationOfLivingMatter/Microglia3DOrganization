# Dependencies

## MATLAB

The pipeline is implemented in MATLAB 2023b.

## Required toolboxes

### Image Processing Toolbox

Used for:

- reading and processing 3D TIFF stacks;
- binary morphology and plaque dilation;
- connected-component and region measurements;
- masks, resizing and image-label operations;
- 3D region properties.

### Statistics and Machine Learning Toolbox

Used for:

- pairwise distances;
- nearest-neighbor searches;
- spatial statistics;
- distribution and summary utilities.

## Optional toolbox

### Parallel Computing Toolbox

Required only when:

```matlab
config.parallel.enabled = true;
```

The pipeline can run sequentially when this toolbox is unavailable.

## Repository functions

All custom MATLAB functions required by the standard non-Voronoi pipeline are included in `MATLAB_analysis/`.

Run:

```matlab
setupMicrogliaAnalysis
```

before executing the pipeline so all project subfolders are added to the MATLAB path.

## External data required for Voronoi analysis

Voronoi generation is not included in this repository. When Voronoi analysis is enabled, the user must provide:

- centroid MAT files corresponding to the seeds used for each Voronoi tessellation;
- externally generated Voronoi result MAT files;
- files with the variable names and dimensions expected by the pipeline.

See [`VORONOI_ANALYSIS.md`](VORONOI_ANALYSIS.md).

## Input file formats

- metadata: `.xlsx` or `.xls`;
- masks: binary 3D `.tif` stacks;
- microglia: labeled 3D `.tif` stacks;
- plaques: labeled 3D `.tif` stacks;
- saved configuration: `.json` or `.mat`;
- optional Voronoi and precomputed sphere inputs: `.mat` files.

## Platform considerations

The code uses `fullfile` and supports absolute or relative configuration paths. Relative paths in JSON files are resolved from the configuration-file directory.

Local paths embedded in example files are placeholders and must be changed before use.

## Runtime validation

Before processing, the validator checks:

- required folders;
- model-specific mask and microglia subfolders;
- metadata file and required columns;
- image resolution and correction-factor values;
- sphere radius pairs;
- layer selection settings;
- optional parallel toolbox availability;
- optional Voronoi folders.

Static source review cannot guarantee compatibility with every MATLAB release or with arbitrary external MAT-file structures. Dataset-specific validation should begin with one WT and one AD image before launching the full dataset.
