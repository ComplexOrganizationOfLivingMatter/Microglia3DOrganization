function stats = randomDirectionNull(points, C, R, nDirs, opts)
%RANDOMDIRECTIONNULL Build a null distribution from random directions.
%
% Inputs
%   points  N-by-3 point coordinates.
%   C       Sphere center.
%   R       Sphere radius.
%   nDirs   Number of uniformly sampled directions.
%   opts    Options forwarded to computeDirectionalBiasSphere.
%
% Output
%   stats   Summary statistics, maximizing directions, and full null
%           distributions for polarization, alignment, and mean cosine.

    if nargin < 4 || isempty(nDirs), nDirs = 200; end
    if nargin < 5, opts = struct(); end

    Pols     = nan(nDirs,1);
    Aligns   = nan(nDirs,1);
    meanCoss = nan(nDirs,1);
    Ds       = nan(nDirs,1);
    U        = nan(nDirs,3);

    rng(1234); 
    
    for k = 1:nDirs
        u = randn(1,3);
        u = u / norm(u);

        % Store the sampled direction.
        U(k,:) = u;

        % Construct a target point; only its direction from C is used.
        Pfake = C + u;

        out = computeDirectionalBiasSphere(points, C, R, Pfake, opts);

        Pols(k)     = out.Pol;
        Aligns(k)   = out.Align;
        meanCoss(k) = out.meanCos;
        Ds(k)       = out.D;
    end

    % Summarize null distributions.
    stats.Pol_mean = mean(Pols, 'omitnan');
    stats.Pol_sd   = std(Pols,  'omitnan');
    stats.Pol_p95  = prctile(Pols, 95);
    stats.Pol_max  = max(Pols, [], 'omitnan');

    stats.Align_mean = mean(Aligns, 'omitnan');
    stats.Align_sd   = std(Aligns,  'omitnan');
    stats.Align_p95  = prctile(Aligns, 95);
    stats.Align_max  = max(Aligns, [], 'omitnan');

    stats.meanCos_mean = mean(meanCoss, 'omitnan');
    stats.meanCos_sd   = std(meanCoss,  'omitnan');
    stats.meanCos_p95  = prctile(meanCoss, 95);
    stats.meanCos_max  = max(meanCoss, [], 'omitnan');

    stats.D_mean = mean(Ds, 'omitnan'); % Displacement does not depend on direction.
    stats.D_sd   = std(Ds,  'omitnan');

    % Record the first maximizing direction for deterministic output.
    % Use the first maximum index to keep results deterministic.
    % Maximum alignment.
    if all(isnan(Aligns))
        idxMaxAlign = NaN;
        stats.u_maxAlign = [NaN NaN NaN];
        stats.Pol_atMaxAlign = NaN;
        stats.meanCos_atMaxAlign = NaN;
        stats.Align_max = NaN;
    else
        [~, idxMaxAlign] = max(Aligns);
        stats.u_maxAlign = U(idxMaxAlign,:);
        stats.Pol_atMaxAlign = Pols(idxMaxAlign);
        stats.meanCos_atMaxAlign = meanCoss(idxMaxAlign);
        stats.Align_max = Aligns(idxMaxAlign);
    end

    % Maximum mean cosine.
    if all(isnan(meanCoss))
        idxMaxCos = NaN;
        stats.u_maxCos = [NaN NaN NaN];
        stats.Align_atMaxCos = NaN;
        stats.Pol_atMaxCos = NaN;
        stats.meanCos_max = NaN;
    else
        [~, idxMaxCos] = max(meanCoss);
        stats.u_maxCos = U(idxMaxCos,:);
        stats.Align_atMaxCos = Aligns(idxMaxCos);
        stats.Pol_atMaxCos = Pols(idxMaxCos);
        stats.meanCos_max = meanCoss(idxMaxCos);
    end

    % Retain complete null distributions for optional downstream inspection.
    stats.Pols     = Pols;
    stats.Aligns   = Aligns;
    stats.meanCoss = meanCoss;
    stats.Ds       = Ds;
    stats.U        = U;
end
