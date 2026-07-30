function value = safeDivide(numerator, denominator, scaleFactor)
%SAFEDIVIDE Divide safely and optionally scale the result.
    if nargin < 3, scaleFactor = 1; end
    value = NaN(size(numerator + denominator));
    valid = isfinite(denominator) & denominator>0;
    value(valid) = numerator(valid)./denominator(valid).*scaleFactor;
end
