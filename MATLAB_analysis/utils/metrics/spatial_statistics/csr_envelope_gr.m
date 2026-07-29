function [lowerEnvelope, medianEnvelope, upperEnvelope] = csr_envelope_gr(numberOfPoints, sphereRadius, radiusEdges, numberOfSimulations)
%CSR_ENVELOPE_GR Simulate a CSR envelope for the pair-correlation function.
%
% Simulations are conditioned on the observed point count.

    numberOfBins = numel(radiusEdges) - 1;
    simulatedValues = zeros(numberOfSimulations, numberOfBins);
    for simulationIndex = 1:numberOfSimulations
        simulatedPoints = sampleCSRinSphere(numberOfPoints, sphereRadius);
        [~, pairCorrelation] = gr_trans_sphere(simulatedPoints, sphereRadius, radiusEdges);
        simulatedValues(simulationIndex, :) = pairCorrelation(:)';
    end
    lowerEnvelope = percentiles(simulatedValues, 2.5);
    medianEnvelope = percentiles(simulatedValues, 50);
    upperEnvelope = percentiles(simulatedValues, 97.5);
end
