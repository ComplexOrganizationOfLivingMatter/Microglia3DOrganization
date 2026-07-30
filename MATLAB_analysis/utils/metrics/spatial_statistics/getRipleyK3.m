function AL = getRipleyK3(points, savePath, typeSphere, filename, nSphere, volPlaque, isCompleted)
%GETRIPLEYK3 Calculate three-dimensional Ripley statistics and CSR envelopes for a sphere.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    savePath1 = fullfile(savePath, 'Metrics', 'Graphs', 'RipleyK3', typeSphere);
    savePathVariable = fullfile(savePath, 'Metrics', 'Variables', 'RipleyK3', typeSphere);
    
    if ~isfolder(savePath1), mkdir(savePath1); end
    if ~isfolder(savePathVariable), mkdir(savePathVariable); end
    
    rK = linspace(0, 0.8, 60)';

    % Compute K3, L3, and L3-r using translation edge correction.
    [~, K3, L3, LmR] = K3_trans_sphere(points, 1, rK);
   
    AL = trapz(rK, abs(LmR));
    
    if isCompleted
        save(fullfile(savePathVariable, sprintf('%s_%s_K3.mat', filename, string(nSphere))), 'K3');
        save(fullfile(savePathVariable, sprintf('%s_%s_L3.mat', filename, string(nSphere))), 'L3');
        save(fullfile(savePathVariable, sprintf('%s_%s_LmR.mat', filename, string(nSphere))), 'LmR');
    end
    
    M = 199; 
    N = size(points,1);
    [loL, medL, upL] = csr_envelope_L(N, 1, rK, M);

    figure('Visible', 'off'); hold on
    fill([rK' fliplr(rK')], [loL fliplr(upL)], [0.9 0.9 0.9], 'EdgeColor','none');
    plot(rK, LmR, 'b','LineWidth',1.3);
    plot(rK, medL, 'k--');
    grid on
    xlabel('distance'); ylabel('L_3(r)-r');
    title('L_3(r)-r with CSR envelope');
    lgd = legend('Banda 95% CSR','Muestra','Mediana CSR','Location', 'SouthWest'); 
    lgd.FontSize = 8; hold off
    text(0.7,min(loL)*0.9, strcat('Vol Plaque =', string(round(volPlaque,2))));
    if isCompleted
        saveas(gcf, fullfile(savePath1, sprintf('%s_%s.png', filename, string(nSphere))));
    end
    close();
    
end
