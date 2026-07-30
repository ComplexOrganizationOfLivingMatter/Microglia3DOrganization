function getDistributionsGraphsLayers(num_neib, num_cells_with_num_neib,total_Volum_1, total_Surface_Area_1, total_Distance_Neighbours_1, savePath, folderPath, filename)
%GETDISTRIBUTIONSGRAPHSLAYERS Generate Voronoi distribution summaries for a cortical layer.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    figure('Visible', 'off');
    bar(num_neib, num_cells_with_num_neib);
    title(strcat('Cell Neighbour Distribution'));
    xlabel('Neighbours Number');
    ylabel('Cells Number');
    xlim([0 30]);
    xticks(0:30);
    text(1,max(num_cells_with_num_neib)*0.7, strcat('N cells =', string(sum(num_cells_with_num_neib))));
    if ~isfolder(fullfile(savePath, 'Graph', 'NeighboursDistribution', 'count', folderPath)), mkdir(fullfile(savePath, 'Graph', 'NeighboursDistribution', 'count', folderPath)); end    
    saveas(gcf, fullfile(savePath, 'Graph', 'NeighboursDistribution', 'count', folderPath, [filename, '.png']));
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
    if ~isfolder(fullfile(savePath, 'Graph', 'NeighboursDistribution', 'frequency', folderPath)), mkdir(fullfile(savePath, 'Graph', 'NeighboursDistribution', 'frequency', folderPath)); end       
    saveas(gcf, fullfile(savePath, 'Graph', 'NeighboursDistribution', 'frequency', folderPath, [filename, '.png']));
    close();
    
    figure('Visible', 'off');
    histogram(total_Volum_1,'Normalization', 'probability');
    title(strcat('Cell Volume Distribution'));
    xlabel('Volume (um3)');
    ylabel('Cells Number');
    xlim([20000 300000]);
    text(30000,0.2, strcat('N cells =', string(sum(num_cells_with_num_neib))));
    if ~isfolder(fullfile(savePath, 'Graph', 'VolumeDistribution', folderPath)), mkdir(fullfile(savePath, 'Graph', 'VolumeDistribution', folderPath)); end           
    saveas(gcf, fullfile(savePath, 'Graph', 'VolumeDistribution', folderPath, [filename, '.png']));
    close();
    
    figure('Visible', 'off');
    histogram(total_Surface_Area_1,'Normalization', 'probability');
    title(strcat('Cell Surface Area Distribution'));
    xlabel('Surface Area (um2)');
    ylabel('Cells Number');
    xlim([5000 30000]);
    text(6000,0.2, strcat('N cells =', string(sum(num_cells_with_num_neib))));
    if ~isfolder(fullfile(savePath, 'Graph', 'SurfaceAreaDistribution', folderPath)), mkdir(fullfile(savePath, 'Graph', 'SurfaceAreaDistribution', folderPath)); end              
    saveas(gcf, fullfile(savePath, 'Graph', 'SurfaceAreaDistribution', folderPath, [filename, '.png']));
    close();
    
    figure('Visible', 'off');
    histogram(total_Distance_Neighbours_1,'Normalization', 'probability');
    title(strcat('Cell Distance Neighbours Distribution'));
    xlabel('Mean Distance to Neighbours (um)');
    ylabel('Cells Number');
    xlim([0 150]);
    xticks(0:20:150);
    text(10,0.2, strcat('N cells =', string(sum(num_cells_with_num_neib))));
    if ~isfolder(fullfile(savePath, 'Graph', 'DistanceNeighboursDistribution', folderPath)), mkdir(fullfile(savePath, 'Graph', 'DistanceNeighboursDistribution', folderPath)); end                  
    saveas(gcf, fullfile(savePath, 'Graph', 'DistanceNeighboursDistribution', folderPath, [filename, '.png']));
    close();
    
end
