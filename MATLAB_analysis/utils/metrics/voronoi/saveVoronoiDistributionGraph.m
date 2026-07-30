function saveVoronoiDistributionGraph(values, outputFile, xLabelText)
%SAVEVORONOIDISTRIBUTIONGRAPH Save one Voronoi distribution histogram.

    values = double(values(:));
    values = values(isfinite(values));
    if isempty(values)
        return;
    end

    outputFolder = fileparts(outputFile);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    figureHandle = figure('Visible', 'off');
    histogram(values, 'Normalization', 'probability');
    xlabel(xLabelText);
    ylabel('Relative frequency');
    grid on;
    saveas(figureHandle, outputFile);
    close(figureHandle);
end
