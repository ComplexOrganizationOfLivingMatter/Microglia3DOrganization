# Dependencies

## Custom functions

All custom MATLAB functions referenced by the current source tree are included in this repository according to the static dependency review.

Voronoi generation itself is not part of the repository. Existing centroid and Voronoi MAT files must be supplied when Voronoi analysis is enabled.

## MATLAB toolboxes

- Image Processing Toolbox
  - 3D morphology, connected-component measurements, resizing, masks, and TIFF image processing.
- Statistics and Machine Learning Toolbox
  - pairwise distances, nearest-neighbor searches, distributions, and statistical utilities.
- Parallel Computing Toolbox
  - optional; required only when parallel execution is enabled.

## Runtime caveat

Static dependency checks cannot guarantee compatibility with every MATLAB release or with the exact structure of externally generated MAT files. The validator checks required variables and dimensions at runtime.
