function [points] = getRadioAndCenterNormalization(centroid, points, radio)
%GETRADIOANDCENTERNORMALIZATION Center sphere points and normalize coordinates by sphere radius.
%
% Inputs and outputs follow the function signature. Array coordinates use
% MATLAB image order unless the argument name explicitly states XYZ.

    pts = points - centroid;            % centrar
    R = 1;                                % radio común de análisis
    points = pts * (R/radio);             % escalar al radio 1

end
