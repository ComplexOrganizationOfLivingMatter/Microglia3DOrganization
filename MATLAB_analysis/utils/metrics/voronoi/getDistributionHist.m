function getDistributionHist(x, y, titleName, xName, yName, normalizationType, typeSphere, filename, savePath)
%GETDISTRIBUTIONHIST Create and save a histogram from a discrete distribution.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    if ~isfolder(strcat(savePath, normalizationType, '/')), mkdir(strcat(savePath, normalizationType, '/')); end

    nCells = sum(y);
    if contains(normalizationType, 'frequency')   
        y = y./sum(y);
    end

    figure('Visible', 'off');
    bar(x, y)
    title(titleName);
    xlabel(xName);
    ylabel(yName);
    xticks(x);
    text(min(x)*1, max(y)*0.95, strcat('N cells =', string(nCells)));
    saveas(gcf, strcat(savePath, normalizationType, '/', filename, '_', typeSphere, '.png'));
    close();

end
