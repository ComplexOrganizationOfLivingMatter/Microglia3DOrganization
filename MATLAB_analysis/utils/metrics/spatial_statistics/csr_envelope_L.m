function [lowerEnvelope, medianEnvelope, upperEnvelope] = csr_envelope_L(numberOfPoints, sphereRadius, radiusVector, numberOfSimulations)
%CSR_ENVELOPE_L Simulate a CSR envelope for the transformed Ripley statistic.
%
% Simulations are conditioned on the observed point count.

    simulatedValues = zeros(numberOfSimulations, numel(radiusVector));
    for simulationIndex = 1:numberOfSimulations
        simulatedPoints = sampleCSRinSphere(numberOfPoints, sphereRadius);
        [~, ~, ~, transformedValues] = K3_trans_sphere(simulatedPoints, sphereRadius, radiusVector);
        simulatedValues(simulationIndex, :) = transformedValues(:)';
    end
    lowerEnvelope = prctile(simulatedValues, 2.5);
    medianEnvelope = prctile(simulatedValues, 50);
    upperEnvelope = prctile(simulatedValues, 97.5);
end
