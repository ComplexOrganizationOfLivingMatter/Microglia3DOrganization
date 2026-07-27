# Microglia3DOrganization
ed.

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
    └── To be added
```

The repository is currently organized into the following main components:

- `BiaPy_models/`: configuration files and trained weights for the three segmentation models.
- `MATLAB_analysis/`: quantitative analysis code used to extract data from the final segmentations. This directory will be added when the analysis pipeline is complete.

## BiaPy models

The `BiaPy_models/` directory contains the configuration files and trained weights used for the segmentation steps described in the manuscript.

Each model is stored in a separate subdirectory:

| Directory | Segmentation task | BiaPy version |
|---|---|---:|
| `Microglia/` | 3D instance segmentation of microglial somas | 3.4.6 |
| `Plaques/` | 3D instance segmentation of amyloid-β plaques | 3.4.6 |
| `Masks/` | 3D semantic segmentation of tissue masks | 3.3.3 |

The models were trained using different versions of BiaPy. For reproducibility, each model should preferably be run using the same BiaPy version used during its original training. Compatibility with other versions has not been systematically tested.

### Model files

Each model directory contains:

- The BiaPy configuration file used for the corresponding workflow.
- The trained model weights.

The files are organized as follows:

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

Further information about the architecture, configuration parameters, weight formats and local path requirements is provided in [`BiaPy_models/README.md`](BiaPy_models/README.md).

### Using the models

Before running a model, the paths contained in its YAML configuration file must be replaced with valid paths for the local system and input dataset.

The model weights are provided in two formats:

- The `Microglia` and `Plaques` models use PyTorch checkpoint files (`.pth`).
- The `Masks` model uses an HDF5 weight file (`.h5`).

The appropriate BiaPy version should be selected before loading each model.

## BiaPy license

BiaPy is distributed under the MIT License. A copy of the BiaPy license is included as [`BiaPy_models/LICENSE.md`](BiaPy_models/LICENSE.md).

The license included in that directory applies to the BiaPy software. The configuration files and trained weights are provided as research resources associated with this project.

## Quantitative analysis code

The MATLAB code used to process the final segmentations and extract the quantitative measurements reported in the manuscript is currently being finalized.

This section will be expanded to include:

- Required MATLAB version and toolboxes.
- Expected input data structure.
- Image and metadata naming conventions.
- Configuration of local paths and analysis parameters.
- Microglial density analysis.
- Amyloid-β plaque measurements.
- Cortical layer assignment.
- Plaque-associated and non-plaque sphere analysis.
- Output tables and derived images.
- Instructions for reproducing the analyses reported in the manuscript.
