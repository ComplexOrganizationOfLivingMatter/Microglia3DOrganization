function out = computeDirectionalBiasSphere(points, C, R, P, opts)
%COMPUTEDIRECTIONALBIASSPHERE Quantify directional bias inside a sphere.
%
% Inputs
%   points  N-by-3 point coordinates in the same units as C and P.
%   C       1-by-3 sphere center.
%   R       Sphere radius.
%   P       1-by-3 target point defining the reference direction, or [].
%   opts    Optional structure with robust averaging, radial weighting,
%           center exclusion, and an empirical null distribution.
%
% Output
%   out     Structure containing point count, direction, polarization,
%           displacement, alignment, angular projection, z scores, and
%           empirical p values.

    if nargin < 5 || isempty(opts), opts = struct(); end
    if ~isfield(opts, 'useRobust'), opts.useRobust = false; end
    if ~isfield(opts, 'radialWeight'), opts.radialWeight = "none"; end
    if ~isfield(opts, 'excludeCenterEps'), opts.excludeCenterEps = 0; end

    out = struct();
    out.N = size(points,1);
    out.note = "";

    % Initialize optional significance fields.
    out.zAlign = NaN;
    out.pEmpAlign = NaN;
    out.zMeanCos = NaN;
    out.pEmpMeanCos = NaN;

    % Reject underdetermined or invalid inputs.
    if out.N < 3
        out.u = [NaN NaN NaN];
        out.Pol = NaN; out.D = NaN; out.Align = NaN;
        out.meanProj = NaN; out.meanCos = NaN;
        out.note = "N<3: unstable estimate";
        return;
    end
    if R <= 0 || isnan(R)
        out.u = [NaN NaN NaN];
        out.Pol = NaN; out.D = NaN; out.Align = NaN;
        out.meanProj = NaN; out.meanCos = NaN;
        out.note = "Invalid radius";
        return;
    end

    % Express points relative to the sphere center.
    V = points - C(:)';                   % Nx3
    r = sqrt(sum(V.^2, 2));               % Nx1

    % Optionally exclude points near the sphere center.
    if opts.excludeCenterEps > 0
        keep = r >= opts.excludeCenterEps;
        V = V(keep,:); r = r(keep);
        out.N = size(V,1);
        if out.N < 3
            out.u = [NaN NaN NaN];
            out.Pol = NaN; out.D = NaN; out.Align = NaN;
            out.meanProj = NaN; out.meanCos = NaN;
            out.note = "N<3 after center exclusion";
            return;
        end
    end

    % Build optional radial weights.
    switch lower(string(opts.radialWeight))
        case "none"
            w = ones(size(r));
        case "linear"
            w = r / max(r);
            w(w==0) = eps;
        case "inverse"
            w = 1 ./ (r + eps);
        otherwise
            error("radialWeight must be 'none', 'linear', or 'inverse'.");
    end
    w = w / sum(w); % Normalize weights.

    % Unit direction from the sphere center to the target plaque.
    if isempty(P) || any(isnan(P))
        out.u = [NaN NaN NaN];
        out.note = out.note + "No target point; ";
        u = [];
    else
        d = (P(:)' - C(:)');              % 1x3
        nd = norm(d);
        if nd == 0
            out.u = [NaN NaN NaN];
            out.note = out.note + "Target equals sphere center; ";
            u = [];
        else
            u = d / nd;                   % Unit reference direction.
            out.u = u;
        end
    end

    % Compute the weighted or robust displacement vector.
    if opts.useRobust
        vbar = median(V, 1);
    else
        vbar = sum(V .* w, 1);
    end

    out.D = norm(vbar) / R;

    if isempty(u)
        out.Pol = NaN;
        out.Align = NaN;
        out.meanProj = NaN;
        out.meanCos = NaN;
        return;
    end

    % Compute signed and angular projections.
    proj = V * u(:);                      % Nx1 (v·u)
    out.meanProj = sum(proj .* w);        % Weighted mean projection.
    out.Pol = out.meanProj / R;

    % Angular metric: cos(theta) = (v dot u)/|v|.
    cosang = proj ./ (r + eps);
    out.meanCos = sum(cosang .* w);

    % Alignment of the global displacement vector with the target direction.
    nv = norm(vbar);
    if nv < 1e-12
        out.Align = 0;
    else
        out.Align = dot(vbar, u) / nv;
    end

    % Compare observed values with an optional empirical null distribution.
    if isfield(opts, "null") && ~isempty(opts.null)
        null = opts.null;

        % Alignment significance.
        if isfield(null, "Align_mean") && isfield(null, "Align_sd")
            muA = null.Align_mean;
            sdA = null.Align_sd;
            if isfinite(muA) && isfinite(sdA) && sdA > 0
                out.zAlign = (out.Align - muA) / sdA;
            end
        end
        if isfield(null, "Aligns") && ~isempty(null.Aligns)
            A = null.Aligns(:);
            A = A(isfinite(A));
            if ~isempty(A) && isfinite(out.Align)
                out.pEmpAlign = (sum(A >= out.Align) + 1) / (numel(A) + 1);
            end
        end

        % Mean-cosine significance.
        if isfield(null, "meanCos_mean") && isfield(null, "meanCos_sd")
            muC = null.meanCos_mean;
            sdC = null.meanCos_sd;
            if isfinite(muC) && isfinite(sdC) && sdC > 0
                out.zMeanCos = (out.meanCos - muC) / sdC;
            end
        end
        if isfield(null, "meanCoss") && ~isempty(null.meanCoss)
            Cc = null.meanCoss(:);
            Cc = Cc(isfinite(Cc));
            if ~isempty(Cc) && isfinite(out.meanCos)
                out.pEmpMeanCos = (sum(Cc >= out.meanCos) + 1) / (numel(Cc) + 1);
            end
        end
    end
end
