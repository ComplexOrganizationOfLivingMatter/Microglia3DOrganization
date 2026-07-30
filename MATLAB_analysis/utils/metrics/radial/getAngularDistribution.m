function getAngularDistribution(points, savePath, typeSphere, filename, nSphere, distNearestPlaque, isCompleted)
%GETANGULARDISTRIBUTION Calculate and optionally save angular point distributions inside a sphere.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    savePath1 = fullfile(savePath, 'Metrics', 'Graphs', 'AngularDistribution', typeSphere);
    savePathVariable = fullfile(savePath, 'Metrics', 'Variables', 'AngularDistribution', typeSphere);
    
    if ~isfolder(savePath1), mkdir(savePath1); end
    if ~isfolder(savePathVariable), mkdir(savePathVariable); end
    
    radii = vecnorm(points,2,2);   % distancias al centro
    u = points ./ max(radii, eps);        % direcciones unitarias
    x = u(:,1); y = u(:,2); z = u(:,3);

    phi = atan2(y,x);                     % azimut en [-pi, pi]
    phi(phi<0) = phi(phi<0) + 2*pi;       % en [0, 2pi)
    mu = z;                               % mu = cos(theta), which is uniform under isotropy.

    if isCompleted
        save(fullfile(savePathVariable, sprintf('%s_%s_phi.mat', filename, string(nSphere))), 'phi');
        save(fullfile(savePathVariable, sprintf('%s_%s_mu.mat', filename, string(nSphere))), 'mu');
    end
    
    % Histogramas simples y uniformes de referencia
    edges_phi = linspace(0, 2*pi, 24);
    [count_phi, edges_phi] = histcounts(phi, edges_phi, 'Normalization','probability');
    cent_phi = 0.5*(edges_phi(1:end-1)+edges_phi(2:end));

    edges_mu = linspace(-1, 1, 24);
    [count_mu, edges_mu] = histcounts(mu, edges_mu, 'Normalization','probability');
    cent_mu = 0.5*(edges_mu(1:end-1)+edges_mu(2:end));

    figure('Visible', 'off');
    subplot(1,2,1); bar(cent_phi, count_phi); hold on
    xlabel('\phi [rad]'); ylabel('frecuency'); ylim([0,1]);
    title('Azimuth \phi'); grid on;
    subplot(1,2,2); bar(cent_mu, count_mu); hold on
    xlabel('\mu = cos(\theta)'); ylabel('frecuency'); ylim([0,1]);
    title('Elevation cos\theta'); grid on;
    text(-0.9,0.7, strcat('N cells =', string(size(points,1))));
    if ~contains(typeSphere, 'WT')
        text(-0.9,0.6, strcat('Dist Plaque =', string(round(distNearestPlaque,2)))); 
    end
    if isCompleted
        saveas(gcf, fullfile(savePath1, sprintf('%s_%s.png', filename, string(nSphere))));
    end
    close();
    
end
