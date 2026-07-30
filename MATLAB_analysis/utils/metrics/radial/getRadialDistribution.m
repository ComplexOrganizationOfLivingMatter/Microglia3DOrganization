function [meanD, stdD, perCentered]=getRadialDistribution(points, savePath, typeSphere, filename, nSphere, isCompleted)
%GETRADIALDISTRIBUTION Calculate and optionally save the normalized radial point distribution.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    savePath1 = fullfile(savePath, 'Metrics', 'Graphs', 'RadialDistribution', 'AcumulativeDistribution', typeSphere);
    savePath2 = fullfile(savePath, 'Metrics', 'Graphs', 'RadialDistribution', 'Histogram', typeSphere);
    savePathVariable = fullfile(savePath, 'Metrics', 'Variables', 'RadialDistribution', typeSphere);
    
    if ~isfolder(savePath1), mkdir(savePath1); end
    if ~isfolder(savePath2), mkdir(savePath2); end
    if ~isfolder(savePathVariable), mkdir(savePathVariable); end

    
    radii = vecnorm(points,2,2);
    radii = radii(isfinite(radii));
    if isempty(radii)
        meanD = NaN;
        stdD = NaN;
        perCentered = NaN;
        return;
    end
    meanD = mean(radii);
    stdD = std(radii);
    perCentered = mean(radii < (1/3));
    
    if isCompleted
        save(fullfile(savePathVariable, sprintf('%s_%s.mat', filename, string(nSphere))), 'radii');
    end

    R = 1;    
    
    edges_r = linspace(0, R, 20);
    [counts_r, edges_r] = histcounts(radii, edges_r, 'Normalization','cdf');
    counts_rP = histcounts(radii, edges_r, 'Normalization','probability');
    centers_r = 0.5*(edges_r(1:end-1)+edges_r(2:end));

    % Theoretical CSR radial density: f(r) = 3 r^2 for 0 <= r <= 1.
    r_th = linspace(0,R,200);
    f_th = 3*(r_th.^2)/length(radii);
    f_th_acum = (r_th / R).^3;    

    figure('Visible', 'off'); 
    bar(centers_r, counts_r, 'hist'); hold on
    plot(r_th, f_th_acum, 'k', 'LineWidth', 1.5);
    xlabel('Distance from center'); ylabel('frequency'); title('Distribución radial acumulada');
    lgd = legend({'Empírica','CSR teórica 3r^2'},'Location','northwest'); grid on
    lgd.FontSize = 8;
    if isCompleted
        saveas(gcf, fullfile(savePath1, sprintf('%s_%s.png', filename, string(nSphere))))
    end
    close();
    
    figure('Visible', 'off'); 
    bar(centers_r, counts_rP, 'hist'); hold on
    plot(r_th, f_th, 'k', 'LineWidth', 1.5);
    xlabel('Distance from center'); ylabel('frequency'); title('Distribución radial');
    ylim([0,1]);
    lgd = legend({'Empírica','CSR teórica 3r^2'},'Location','northwest'); grid on
    lgd.FontSize = 8;
    grid on
    if isCompleted
        saveas(gcf, fullfile(savePath2, sprintf('%s_%s.png', filename, string(nSphere))));
    end
    close();
    
end
