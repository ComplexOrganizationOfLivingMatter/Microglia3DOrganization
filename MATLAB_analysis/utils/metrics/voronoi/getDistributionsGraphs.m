function getDistributionsGraphs(num_neib, num_cells_with_num_neib,total_Volum_1, total_Surface_Area_1, total_Distance_Neighbours_1, savePath, typeSphere, filename, sph, typeData, distNearestPlaque)
%GETDISTRIBUTIONSGRAPHS Generate Voronoi distribution summaries for one sphere or image region.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    if ~isfolder(strcat(savePath, 'Voronoi_', typeData, '/Graph/NeighboursDistribution/count/', typeSphere)), mkdir(strcat(savePath, 'Voronoi_', typeData, '/Graph/NeighboursDistribution/count/', typeSphere)); end
    if ~isfolder(strcat(savePath, 'Voronoi_', typeData, '/Graph/NeighboursDistribution/frequency/', typeSphere)), mkdir(strcat(savePath, 'Voronoi_', typeData, '/Graph/NeighboursDistribution/frequency/', typeSphere)); end    
    if ~isfolder(strcat(savePath, 'Voronoi_', typeData, '/Graph/SurfaceAreaDistribution/', typeSphere)), mkdir(strcat(savePath, 'Voronoi_', typeData, '/Graph/SurfaceAreaDistribution/', typeSphere)); end
    if ~isfolder(strcat(savePath, 'Voronoi_', typeData, '/Graph/VolumeDistribution/', typeSphere)), mkdir(strcat(savePath, 'Voronoi_', typeData, '/Graph/VolumeDistribution/', typeSphere)); end
    if ~isfolder(strcat(savePath, 'Voronoi_', typeData, '/Graph/NeighboursDistanceDistribution/', typeSphere)), mkdir(strcat(savePath, 'Voronoi_', typeData, '/Graph/NeighboursDistanceDistribution/', typeSphere)); end


    figure('Visible', 'off');
    bar(num_neib, num_cells_with_num_neib);
    title(strcat('Cell Neighbour Distribution'));
    xlabel('Neighbours Number');
    ylabel('Cells Number');
    xlim([0 30]);
    xticks(0:30);
    text(1,max(num_cells_with_num_neib)*0.7, strcat('N cells =', string(sum(num_cells_with_num_neib))));
    text(1,max(num_cells_with_num_neib)*0.6, strcat('Dist Plaque =', string(round(distNearestPlaque,2))));
    saveas(gcf, strcat(savePath, 'Voronoi_', typeData, '/Graph/NeighboursDistribution/count/', typeSphere, filename, '_', sph, '.png'));
    close();
    
    figure('Visible', 'off');
    bar(num_neib, num_cells_with_num_neib./sum(num_cells_with_num_neib))
    title(strcat('Cell Neighbour Distribution'));
    xlabel('Neighbours Number');
    ylabel('Cells Number');
    xlim([0 30]);
    ylim([0 1]);
    xticks(0:30);
    text(1,0.7, strcat('N cells =', string(sum(num_cells_with_num_neib))));
    text(1,0.6, strcat('Dist Plaque =', string(round(distNearestPlaque,2))));
    saveas(gcf, strcat(savePath, 'Voronoi_', typeData, '/Graph/NeighboursDistribution/frequency/', typeSphere, filename, '_', string(sph), '.png'));
    close();
    
    figure('Visible', 'off');
    histogram(total_Volum_1,'Normalization', 'probability');
    title(strcat('Cell Volume Distribution'));
    xlabel('Volume (um3)');
    ylabel('Cells Number');
    xlim([20000 200000]);
    text(30000,0.2, strcat('N cells =', string(sum(num_cells_with_num_neib))));
    saveas(gcf, strcat(savePath, 'Voronoi_', typeData, '/Graph/VolumeDistribution/', typeSphere, filename, '_', sph, '.png'));
    close();
    
    figure('Visible', 'off');
    histogram(total_Surface_Area_1,'Normalization', 'probability');
    title(strcat('Cell Surface Area Distribution'));
    xlabel('Surface Area (um2)');
    ylabel('Cells Number');
    xlim([5000 20000]);
    text(6000,0.2, strcat('N cells =', string(sum(num_cells_with_num_neib))));
    saveas(gcf, strcat(savePath, 'Voronoi_', typeData, '/Graph/SurfaceAreaDistribution/', typeSphere, filename, '_', sph, '.png'));
    close();
    
    figure('Visible', 'off');
    histogram(total_Distance_Neighbours_1,'Normalization', 'probability');
    title(strcat('Cell Distance Neighbours Distribution'));
    xlabel('Mean Distance to Neighbours (um)');
    ylabel('Cells Number');
    xlim([0 150]);
    xticks(0:20:150);
    text(10,0.2, strcat('N cells =', string(sum(num_cells_with_num_neib))));
    text(10,0.1, strcat('Dist Plaque =', string(round(distNearestPlaque,2))));
    saveas(gcf, strcat(savePath, 'Voronoi_', typeData, '/Graph/NeighboursDistanceDistribution/', typeSphere, filename, '_', sph, '.png'));
    close();
    
end
