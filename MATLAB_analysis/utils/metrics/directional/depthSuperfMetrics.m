function stats = depthSuperfMetrics(points, C, R, u_depth, opts)
%DEPTHSUPERFMETRICS Measure bias along deep and superficial directions.
%
% Inputs
%   points   N-by-3 point coordinates.
%   C        Sphere center.
%   R        Sphere radius.
%   u_depth  Vector pointing toward cortical depth.
%   opts     Options forwarded to computeDirectionalBiasSphere.
%
% Output
%   stats    Alignment, polarization, and mean cosine for the deep axis
%            and its opposite superficial direction.

    if nargin < 5 || isempty(opts), opts = struct(); end
    if nargin < 4 || isempty(u_depth) || any(isnan(u_depth))
        error("u_depth must be a valid 1x3 vector.");
    end

    ud = u_depth(:)';
    n = norm(ud);
    if n < 1e-12
        error("u_depth has near-zero norm.");
    end
    ud = ud / n;              % Unit deep direction.
    us = -ud;                 % Opposite superficial direction.

    % Convert each direction into a target point for the shared metric function.
    Pdepth = C(:)' + ud;
    Psuper = C(:)' + us;

    outD = computeDirectionalBiasSphere(points, C, R, Pdepth, opts);
    outS = computeDirectionalBiasSphere(points, C, R, Psuper, opts);

    stats.Align_depth   = outD.Align;
    stats.Pol_depth     = outD.Pol;
    stats.meanCos_depth = outD.meanCos;

    stats.Align_superf   = outS.Align;
    stats.Pol_superf     = outS.Pol;
    stats.meanCos_superf = outS.meanCos;
end
