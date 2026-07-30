function folderName = getSphereRadiusFolderName(plaqueRadius_um, nonPlaqueRadius_um)
%GETSPHERERADIUSFOLDERNAME Return the canonical folder name for a radius pair.
%
% This function must be used by both sphere-definition generation and
% sphere-data analysis so that saved SphereInd files are always read from
% the same directory in which they were created.
%
% Example:
%   getSphereRadiusFolderName(100, 50)
%   -> "PlaqueSphereR100_NonPlaqueSphereR50"

    plaqueToken = formatRadiusToken(plaqueRadius_um);
    nonPlaqueToken = formatRadiusToken(nonPlaqueRadius_um);

    folderName = sprintf('PlaqueSphereR%s_NonPlaqueSphereR%s', ...
        plaqueToken, nonPlaqueToken);
end

function token = formatRadiusToken(radiusValue)
%FORMATRADIUSTOKEN Convert a positive scalar radius into a path-safe token.

    validateattributes(radiusValue, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'}, mfilename, 'radiusValue');

    token = sprintf('%.12g', double(radiusValue));
    token = strrep(token, '.', 'p');
    token = strrep(token, '-', 'm');
    token = strrep(token, '+', '');
end
