function [initial_mask, lin_ind_new, selectedVoxels] = fillWithNearestSpheres(initial_mask, radius, maskImg)
%FILLWITHNEARESTSPHERES Fill valid tissue with non-overlapping spheres selected by nearest feasible centers.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.
    
    % Initialize variables
    newSpheres = 1;
    lin_ind_new = {};
    sphereValue = (max(unique(initial_mask))+1);
    selectedVoxels = [];

    % Create a map distance from the spheres
    DT_initial = bwdist(initial_mask>0);
    DT_initial(DT_initial<radius) = 0;

    % Create a mask from borders
    borderMask = zeros(size(initial_mask));
    borderMask(round(radius):(end-round(radius)), round(radius):(end-round(radius)), round(radius):(end-round(radius)))=1;
 
    % Valid region (radius um from borders)
    DT_mask = bwdist(~maskImg);
    clear maskImg;
    valid_region = DT_mask >= radius;
    clear DT_mask;
    valid_region(borderMask==0) = 0;
    DT_initial(valid_region==0) = 0;
    clear valid_region borderMask;
    
    % Get the candidate voxels in the valid region that are at least
    % radius*2 um apart form the spheres centroids.
    candidate_voxel_ind = find(DT_initial>0);
    [~, sortOrder] = sort(DT_initial(candidate_voxel_ind));
    candidate_voxel_ind  = candidate_voxel_ind(sortOrder);
    clear DT_initial;
    
        
    % While there is voxels where a centroid can be placed
    while ~isempty(candidate_voxel_ind)
    
       % Take a random centroid from all the candidates
       [new_centroid_y, new_centroid_x, new_centroid_z] = ind2sub(size(initial_mask), candidate_voxel_ind(1));
       % Obtain the sphere from that centroid and save the voxels within it
       [sphere_voxels, lin_ind] = getSphereFromCentroid([new_centroid_x, new_centroid_y, new_centroid_z], radius, size(initial_mask));
       lin_ind_new{newSpheres} = lin_ind;
       selectedVoxels = [selectedVoxels, candidate_voxel_ind(1)];
       
       % Obtain the sphere from that centroid with a radius equal to
       % radius*2 to eliminate those voxels from the candidates
       [sphere_voxels_temp, lin_ind_to_erase] = getSphereFromCentroid([new_centroid_x, new_centroid_y, new_centroid_z], radius*2, size(initial_mask));
       initial_mask(lin_ind) = initial_mask(lin_ind) + double(sphere_voxels(sphere_voxels)*sphereValue);
       candidate_voxel_ind(ismember(candidate_voxel_ind,lin_ind_to_erase)) = [];

    %    DT_initial = bwdist(initial_mask>0);
    %    candidate_voxels = (DT_initial >= radius_pxl) & valid_region;
    %    candidate_ind = find(candidate_voxels==1);
        
        % Update the number of new spheres
        newSpheres = newSpheres+1;
        

    end
end
