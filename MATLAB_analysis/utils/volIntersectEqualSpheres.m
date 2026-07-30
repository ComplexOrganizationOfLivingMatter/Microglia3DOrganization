function volume = volIntersectEqualSpheres(radius, separation)
%VOLINTERSECTEQUALSPHERES Compute overlap volume for two equal spheres.
%
% Inputs
%   radius      Common sphere radius.
%   separation  Center-to-center distance. Scalar and array inputs are supported.
%
% Output
%   volume      Intersection volume for each separation value.

    volume = zeros(size(separation));
    volume(separation <= 0) = (4/3) * pi * radius^3;
    valid = separation > 0 & separation < 2 * radius;
    distance = separation(valid);
    volume(valid) = pi .* (4 * radius + distance) .* (2 * radius - distance).^2 / 12;
end
