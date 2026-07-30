function typeData = getVoronoiTypeData(boundaryMode)
%GETVORONOITYPEDATA Convert a config boundary mode to the legacy Voronoi mode.
%
% "include" keeps Voronoi cells that touch the region boundary (legacy
% "Border"). "exclude" retains only cells fully contained in the region
% (legacy "NoBorder").

    boundaryMode = lower(string(boundaryMode));
    if boundaryMode == "include"
        typeData = "Border";
    elseif boundaryMode == "exclude"
        typeData = "NoBorder";
    else
        error('Voronoi boundary mode must be "include" or "exclude".');
    end
end
