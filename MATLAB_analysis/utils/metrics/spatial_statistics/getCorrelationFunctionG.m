function [N, Ag, gmax, r_gmax, gmin, r_gmin] = getCorrelationFunctionG(points, savePath, typeSphere, filename, nSphere, isCompleted)
%GETCORRELATIONFUNCTIONG Calculate the pair-correlation function and CSR envelopes for a sphere.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    savePath1 = fullfile(savePath, 'Metrics', 'Graphs', 'RadialDistributionFunction_G', typeSphere);
    savePathVariable = fullfile(savePath, 'Metrics', 'Variables', 'RadialDistributionFunction_G', typeSphere);
    
    if ~isfolder(savePath1), mkdir(savePath1); end
    if ~isfolder(savePathVariable), mkdir(savePathVariable); end
    
    N = size(points,1);
    R = 1;
    
    %% Parameters selected for small point counts
    params = choose_params_smallN(N, R);     % rmax y bordes de bins "gruesos" (igual volumen)
    edges = params.edges_g;                  % bin edges for g(r)

    %% Pair-correlation estimate with translation edge correction
    [rC, ghat] = gr_trans_sphere(points, R, edges);

    %% Optional CSR envelope for interpretation
    M = 999;                                  % A large simulation count stabilizes envelopes for small N.
    [lo, med, up] = csr_envelope_gr(N, R, edges, M);
   
    Ag = trapz(rC, abs(ghat - 1));
    [gmax, idx_max] = max(ghat);
    r_gmax = rC(idx_max);
    [gmin, idx_min] = min(ghat);
    r_gmin = rC(idx_min);
    
    if isCompleted
        save(fullfile(savePathVariable, sprintf('%s_%s_rC.mat', filename, string(nSphere))), 'rC');
        save(fullfile(savePathVariable, sprintf('%s_%s_ghat.mat', filename, string(nSphere))), 'ghat');
    end
    
    %% Gráfico
    figure('Visible', 'off'); hold on
    fill([rC fliplr(rC)], [lo fliplr(up)], [0.9 0.9 0.9], 'EdgeColor','none');
    plot(rC, med, 'k--');
    plot(rC, ghat, 'b','LineWidth',1.4);
    yline(1,'k-');
    grid on; xlabel('r'); ylabel('g(r)');
    title('g(r) with translation correction and CSR envelope');
    lgd = legend('Banda 95% CSR','Mediana CSR','Muestra','Location','NorthWest');
    lgd.FontSize = 8;
    hold off
    
    if isCompleted
        saveas(gcf, fullfile(savePath1, sprintf('%s_%s.png', filename, string(nSphere))));
    end
    close();
    
end
