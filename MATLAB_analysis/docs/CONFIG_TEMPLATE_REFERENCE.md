# Complete configuration reference

Three configuration presets are provided:

- `paper_metrics.json`: default metrics used by the interactive paper workflow.
- `all_metrics.json`: all standard and advanced metric groups; Voronoi execution still remains disabled unless explicitly enabled in the configuration.
- `config_template_full.json`: complete editable template containing every configurable field.

## Main sections

### `paths`

Input and output roots. Mask and microglia roots must contain model-named subfolders such as `WT` and `APP`.

### `metadata`

Excel file, sheet, and mapping from source columns to the internal schema. Use `bregmaLevel`; `BregmaPosition` and `BregmaGroup` are not part of the current schema.

### `resolution`

Use `excel` for per-image XY and Z columns or `manual` for fixed values.

### `correction`

Use `excel`, `manual`, or `none` for the tissue-shrinkage correction factor.

### `models` and `labels`

Select WT, APP, or both. APP is the source label and is normalized to AD in outputs.

### `layers`

Defines medial/lateral layer names and widths, layer-image eligibility, and the `NoInfo` label.

### `dilatedPlaques`

Select existing labels, temporary generation, or saved generation. Saved labels are written under `DerivedImages/DilatedPlaques`.

### `spheres`

Select generated or existing sphere definitions and the plaque/non-plaque radius pairs. Sphere-specific metric groups are removed when sphere analysis is disabled.

### `analyses`

Enables global, plaque, layer, and sphere modules.

### `voronoi`

Disabled by default and absent from the interactive workflow. Enable only in a custom configuration. `boundaryMode` accepts `include` or `exclude`; global analysis always excludes region-boundary cells.

### `metrics`

Contains the selected metric IDs and group state. The paper preset does not include Voronoi metrics.

### `outputs`

Controls optional derived images. Generated sphere images are always written because the sphere-analysis stage consumes them.

### `parallel`

Controls the pool size and per-module parallel execution.

## Output tree

All tabular data and figures are under `Data`, while all generated image stacks are under the single root `DerivedImages`. Execution support files are kept separately under `Log`, `Checkpoints`, and `Configuration`.
