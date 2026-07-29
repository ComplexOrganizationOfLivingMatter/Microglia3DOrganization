function catalog = getMetricCatalog()
%GETMETRICCATALOG Return descriptions, units, and grouping for output metrics.
%
% The catalog is used by presets, validation, and the interactive selector.

    catalog = metric("", "", "", "", "", false);
    catalog = catalog([]);
    catalog(end+1) = metric("globalMicroglia", "microglia_count", "Microglia count", "Number of microglial somata in the analyzed volume.", "count", true);
    catalog(end+1) = metric("globalMicroglia", "microglia_density_cells_mm3", "Microglia density", "Microglial soma density in the analyzed volume.", "cells/mm^3", true);
    catalog(end+1) = metric("globalMicroglia", "analyzed_volume_um3", "Analyzed volume", "Tissue volume inside the configured segmentation crop after masking.", "um^3", true);
    catalog(end+1) = metric("globalPlaques", "plaque_count", "Plaque count", "Number of amyloid plaques in the analyzed volume.", "count", true);
    catalog(end+1) = metric("globalPlaques", "plaque_density_plaques_mm3", "Plaque density", "Amyloid plaque density in the analyzed volume.", "plaques/mm^3", true);
    catalog(end+1) = metric("globalPlaques", "plaque_occupied_fraction", "Plaque-occupied fraction", "Fraction of the analyzed volume occupied by plaques.", "fraction", true);
    catalog(end+1) = metric("individualPlaques", "plaque_volume_um3", "Plaque volume", "Volume of each labeled plaque.", "um^3", true);
    catalog(end+1) = metric("individualPlaques", "associated_microglia_count", "Associated microglia count", "Number of microglial somata within the dilated plaque region.", "count", true);
    catalog(end+1) = metric("individualPlaques", "associated_microglia_density_cells_mm3", "Associated microglia density", "Microglia density inside the dilated plaque region.", "cells/mm^3", true);
    catalog(end+1) = metric("individualPlaques", "distance_to_cortical_surface_um", "Distance to cortical surface", "Distance from the plaque centroid to the tissue surface along the cortical depth axis.", "um", true);
    catalog(end+1) = metric("layers", "layer_volume_um3", "Layer volume", "Valid tissue volume assigned to each cortical layer.", "um^3", true);
    catalog(end+1) = metric("layers", "layer_microglia_density_cells_mm3", "Layer microglia density", "Microglia density within each cortical layer.", "cells/mm^3", true);
    catalog(end+1) = metric("layers", "layer_plaque_density_plaques_mm3", "Layer plaque density", "Plaque density within each cortical layer.", "plaques/mm^3", true);
    catalog(end+1) = metric("spheres", "sphere_volume_um3", "Sphere volume", "Valid analyzed volume of each plaque or non-plaque sphere.", "um^3", true);
    catalog(end+1) = metric("spheres", "sphere_microglia_density_cells_mm3", "Sphere microglia density", "Microglia density inside each sphere.", "cells/mm^3", true);
    catalog(end+1) = metric("spheres", "nearest_plaque_distance_um", "Nearest plaque distance", "Distance from a non-plaque sphere to the nearest plaque.", "um", true);
    catalog(end+1) = metric("distances", "mean_pairwise_microglia_distance_um", "Mean pairwise microglia distance", "Mean pairwise distance between microglial centroids in the selected region.", "um", false);
    catalog(end+1) = metric("distances", "mean_nearest_microglia_distance_um", "Mean nearest-neighbor distance", "Mean distance from each microglial centroid to its nearest microglial neighbor.", "um", false);
    catalog(end+1) = metric("radial", "mean_radial_distance", "Mean normalized radial distance", "Sphere-only metric. Mean radial location of cells after sphere-center and radius normalization.", "normalized", false);
    catalog(end+1) = metric("spatialStatistics", "ripley_k3_deviation", "Ripley K3 deviation", "Sphere-only metric. Integrated deviation of the transformed three-dimensional Ripley statistic from CSR.", "dimensionless", false);
    catalog(end+1) = metric("spatialStatistics", "pair_correlation_deviation", "Pair-correlation deviation", "Sphere-only metric. Integrated deviation of the pair-correlation function from CSR.", "dimensionless", false);
    catalog(end+1) = metric("directional", "polarization", "Directional polarization", "Sphere-only metric. Magnitude of directional displacement of cells within a sphere.", "dimensionless", false);
    catalog(end+1) = metric("directional", "alignment", "Directional alignment", "Sphere-only metric. Alignment of cell positions with a selected direction.", "dimensionless", false);
    catalog(end+1) = metric("voronoi", "voronoi_valid_cell_count", "Valid Voronoi cell count", "Number of Voronoi cells that satisfy the selected region and boundary criteria.", "count", false);
    catalog(end+1) = metric("voronoi", "voronoi_mean_neighbor_count", "Mean Voronoi neighbor count", "Mean number of neighboring Voronoi cells.", "count", false);
    catalog(end+1) = metric("voronoi", "voronoi_mean_volume_um3", "Mean Voronoi cell volume", "Mean volume of valid Voronoi cells.", "um^3", false);
    catalog(end+1) = metric("voronoi", "voronoi_mean_surface_area_um2", "Mean Voronoi surface area", "Mean surface area of valid Voronoi cells.", "um^2", false);
    catalog(end+1) = metric("voronoi", "voronoi_mean_neighbor_distance_um", "Mean Voronoi neighbor distance", "Mean distance between neighboring Voronoi cell seeds.", "um", false);
end

function entry = metric(group, id, label, description, unit, paper)
%METRIC Build one metric-catalog entry.
    entry.group = string(group);
    entry.id = string(id);
    entry.label = string(label);
    entry.description = string(description);
    entry.unit = string(unit);
    entry.paper = logical(paper);
end
