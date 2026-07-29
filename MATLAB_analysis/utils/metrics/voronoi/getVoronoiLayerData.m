function  [validCells, Mean_neib_number, std_neib_number, Mean_Surface,	std_Surface, Mean_Volume, std_Volume,Mean_neib_distance, std_neib_distance] = getVoronoiLayerData(good_neighbours, neib_number,col,centroids, xyResolution, zResolution, correctionFactor, imgSize, savePath, layer, filename, total_Distance_Neighbours, total_Surface_Area, total_Volum, vornb, plaqueMicrogliaCells, boundaryMode)
%GETVORONOILAYERDATA Select region-associated Voronoi cells and calculate summary statistics.

    if nargin < 17 || strlength(string(boundaryMode)) == 0
        boundaryMode = "exclude";
    end
    boundaryMode = lower(string(boundaryMode));
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.


    centroids(:,1:2) = centroids(:,1:2)*xyResolution;
    centroids(:,3) = centroids(:,3)*zResolution;
%     centroidsTotal(:,1:2) = centroidsTotal(:,1:2)*xyResolution;
%     centroidsTotal(:,3) = centroidsTotal(:,3)*zResolution;

    good_neighboursSP = good_neighbours;
    selectedMask = false(size(good_neighbours));

    for gN = 1:numel(good_neighbours)
        if isempty(good_neighbours{gN})
            continue;
        end

        cellShape = alphaShape(good_neighbours{gN});
        cellShape.Alpha = 25 * cellShape.Alpha;
        intersectsTarget = any(inShape(cellShape, centroids));
        containsExcludedCell = any(ismember(vornb{gN}, plaqueMicrogliaCells));
        selectedMask(gN) = intersectsTarget && ~containsExcludedCell;
    end

    % Preserve the legacy selection criterion: a Voronoi cell is selected
    % when its polyhedron intersects at least one target centroid and it is
    % not excluded by the supplied microglia-label list. No additional
    % neighbour-based erosion is applied.

    for gN = 1:numel(good_neighboursSP)
        if ~selectedMask(gN)
            good_neighboursSP{gN} = [];
        end
    end

    originalGN = find(cellfun(@(gN) ~isempty(gN), good_neighbours));
    selectedOriginalGN = find(selectedMask);
    newGN = find(ismember(originalGN, selectedOriginalGN));
    neib_numberSP = neib_number(newGN);
    
    total_Volum_1 = [];
    total_Surface_Area_1 = [];
    total_Distance_Neighbours_1 = [];
    
    Mean_Volume = 0;
    std_Volume = 0;

    Mean_Surface= 0;
    std_Surface = 0;

    Mean_neib_number = 0;
    std_neib_number = 0;

    Mean_neib_distance = 0;
    std_neib_distance = 0;
    
    l = 0;
    validCells = l;
    
    if ~isempty(neib_numberSP)
                              
            figure('position',[0 0 600 600],'Color',[1 1 1], 'Visible', 'off');

            for i = 1:size(good_neighboursSP,2)
                
                if ~isempty(good_neighboursSP{i})
                    l = l+1;
                    S_microns = alphaShape(good_neighboursSP{i});
                    S_microns.Alpha = 25*S_microns.Alpha;
%                     V = volume(S_microns)*correctionFactor^3;
%                     A = surfaceArea(S_microns)*correctionFactor^2;
%                     cellInd = inShape(S_microns, centroids);
%                     D = mean(pdist2(centroids(cellInd,:),centroidsTotal(vornb{i},:)))*correctionFactor;
                    [K] = convhull(good_neighboursSP{i});
                    total_Distance_Neighbours_1 = [total_Distance_Neighbours_1,total_Distance_Neighbours(newGN(l))];
                    total_Surface_Area_1 = [total_Surface_Area_1,total_Surface_Area(newGN(l))];
                    total_Volum_1 = [total_Volum_1,total_Volum(newGN(l))];
                    trisurf(K,good_neighboursSP{i}(:,1)*correctionFactor,good_neighboursSP{i}(:,2)*correctionFactor,good_neighboursSP{i}(:,3)*correctionFactor,'FaceColor',col(i,:),'FaceAlpha',0.5,'EdgeAlpha',0)
%                     trisurf(K,good_neighboursSP{i}(:,1),good_neighboursSP{i}(:,2),good_neighboursSP{i}(:,3),'FaceColor',col(i,:),'FaceAlpha',0.5,'EdgeAlpha',0)                    
                    hold on;
                end
            end
            
            modeFolder = char(boundaryMode);
            variableRoot = fullfile(savePath, 'Variables', modeFolder);
            if ~isfolder(fullfile(variableRoot, 'VolumeDistribution', layer)), mkdir(fullfile(variableRoot, 'VolumeDistribution', layer)); end
            if ~isfolder(fullfile(variableRoot, 'SurfaceAreaDistribution', layer)), mkdir(fullfile(variableRoot, 'SurfaceAreaDistribution', layer)); end
            if ~isfolder(fullfile(variableRoot, 'NeighboursDistribution', layer)), mkdir(fullfile(variableRoot, 'NeighboursDistribution', layer)); end
            if ~isfolder(fullfile(variableRoot, 'DistanceNeighboursDistribution', layer)), mkdir(fullfile(variableRoot, 'DistanceNeighboursDistribution', layer)); end
            
            
            save(fullfile(variableRoot, 'VolumeDistribution', layer, [filename, '.mat']), 'total_Volum_1');
            save(fullfile(variableRoot, 'SurfaceAreaDistribution', layer, [filename, '.mat']), 'total_Surface_Area_1');
            save(fullfile(variableRoot, 'NeighboursDistribution', layer, [filename, '.mat']), 'neib_numberSP');
            save(fullfile(variableRoot, 'DistanceNeighboursDistribution', layer, [filename, '.mat']), 'total_Distance_Neighbours_1');

            Mean_Volume = sum(total_Volum_1)/length(total_Volum_1);
            std_Volume = std(total_Volum_1);

            Mean_Surface= sum(total_Surface_Area_1)/length(total_Surface_Area_1);
            std_Surface = std(total_Surface_Area_1);

            Mean_neib_number = sum(neib_numberSP)/length(neib_numberSP);
            std_neib_number = std(neib_numberSP);

            Mean_neib_distance = sum(total_Distance_Neighbours_1)/length(total_Distance_Neighbours_1);
            std_neib_distance = std(total_Distance_Neighbours_1);
            
            validCells = l;
            
            [num_cells_with_num_neib,num_neib] = groupcounts(neib_numberSP');
            
            x_max_microns_R = imgSize(2)*xyResolution*correctionFactor;
            y_max_microns_R = imgSize(1)*xyResolution*correctionFactor;
            z_max_microns_R = imgSize(3)*zResolution*correctionFactor;
            
            
            axis('equal')
  %         axis([0 x_max_microns 0 y_max_microns 0 z_max_microns]);
            axis([0 x_max_microns_R 0 y_max_microns_R 0 z_max_microns_R]);
  %         set(gca,'xtick',[0 x_max_microns]);
  %         set(gca,'ytick',[0 y_max_microns]);
  %         set(gca,'ztick',[0 z_max_microns]);
            set(gca,'xtick',[0 x_max_microns_R]);
            set(gca,'ytick',[0 y_max_microns_R]);
            set(gca,'ztick',[0 z_max_microns_R]);
            set(gca,'FontSize',16);
            xlabel('X');ylabel('Y');zlabel('Z');
            hold off
            figureRoot = fullfile(savePath, 'VoronoiFigures', modeFolder);
            if ~isfolder(figureRoot), mkdir(figureRoot); end
            figurename = fullfile(figureRoot, [filename, '_', layer]);
            savefig(figurename)
            close all;

            getDistributionsGraphsLayers(num_neib, num_cells_with_num_neib,total_Volum_1, total_Surface_Area_1, total_Distance_Neighbours_1, savePath, layer, filename);
    end

end
