# Cortical-layer image selection

Not every image may be suitable for cortical-layer analysis. Eligibility is
stored independently from the model and analysis-module selections.

## Configuration

```matlab
config.layers.imageSelection.mode = "all";
config.layers.imageSelection.column = "";
config.layers.imageSelection.selectedFiles = strings(0, 1);
config.layers.noInformationLabel = "NoInfo";
```

Supported modes:

- `all`: every metadata row has valid layer information;
- `excel`: eligibility is read from `config.layers.imageSelection.column`;
- `manual`: eligibility is determined by filenames listed in
  `config.layers.imageSelection.selectedFiles`.

Excel flags accept logical values, non-zero numeric values, and common text
values such as `YES`, `TRUE`, `SI`, or `1`. Empty cells, zero, `NO`, and
`FALSE` are treated as unavailable.

## Normalized metadata

The temporary normalized metadata table contains:

- `LayerInformationAvailable`, a logical eligibility flag;
- `Layers`, a legacy `YES`/`NO` alias retained for compatibility.

## Output behavior

The cortical-layer module skips ineligible images. Plaque and sphere modules
continue to analyze those images but write `NoInfo` in the `Layer` column and
`false` in `LayerInformationAvailable`.
