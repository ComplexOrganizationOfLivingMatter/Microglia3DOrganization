# Cortical-layer image selection

Not every image may be suitable for cortical-layer assignment. Layer eligibility is configured independently from model selection and from the decision to run the layer module.

The same eligibility setting controls:

1. whether the image is included in `cortical_layer_data.xlsx`;
2. whether plaques and spheres from that image receive a cortical-layer label.

## Configuration fields

```matlab
config.layers.imageSelection.mode = "all";
config.layers.imageSelection.column = "";
config.layers.imageSelection.selectedFiles = strings(0, 1);
config.layers.noInformationLabel = "NoInfo";
```

## Selection modes

### `all`

Every metadata row is considered suitable for layer assignment.

```matlab
config.layers.imageSelection.mode = "all";
```

Use this only when every analyzed image contains the required cortical surface and depth information.

### `excel`

Eligibility is read from a metadata column.

```matlab
config.layers.imageSelection.mode = "excel";
config.layers.imageSelection.column = "UseForLayerAnalysis";
```

Accepted true values include:

- logical `true`;
- non-zero numeric values;
- text such as `YES`, `TRUE`, `SI` or `1`.

Accepted false or unavailable values include:

- logical `false`;
- numeric zero;
- empty cells;
- text such as `NO` or `FALSE`.

The interactive workflow allows the user to choose the relevant source column.

### `manual`

Eligibility is defined by an explicit list of filenames.

```matlab
config.layers.imageSelection.mode = "manual";
config.layers.imageSelection.selectedFiles = [
    "image_001"
    "image_004"
    "image_007"
];
```

The names must match entries in the configured metadata filename column.

In interactive mode, the user selects the valid images from a dialog filtered to the enabled models.

## Default cortical layers

### Medial cortex

| Layer | Width |
|---|---:|
| Layer 1 | 105 µm |
| Layer 2–3 | 175 µm |
| Layer 5 | 295 µm |
| Layer 6 | 340 µm |

### Lateral cortex

| Layer | Width |
|---|---:|
| Layer 1 | 135 µm |
| Layer 2–3 | 230 µm |
| Layer 4 | 130 µm |
| Layer 5 | 340 µm |

Widths are measured successively from the cortical surface and converted to pixels using the image calibration and linear correction factor.

## Output behavior

For eligible images:

- the layer module writes layer-specific volumes, counts and densities;
- individual plaques receive a `Layer` value;
- individual spheres receive a `Layer` value;
- `LayerInformationAvailable` is `true`.

For ineligible images:

- the dedicated layer module skips the image;
- global, plaque and sphere analyses still process it;
- plaque and sphere tables write the configured `NoInfo` label;
- `LayerInformationAvailable` is `false`.

This design prevents images without reliable layer information from being discarded from other analyses.

## Normalized metadata

The temporary normalized metadata includes:

- `LayerInformationAvailable`: logical eligibility flag;
- `Layers`: legacy `YES`/`NO` alias retained for compatibility with internal functions.

The normalized metadata copy is removed after the run when it was created as a temporary file.
