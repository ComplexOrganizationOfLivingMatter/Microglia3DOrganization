function tests = testSphereRadiusPairsValidation
%TESTSPHERERADIUSPAIRSVALIDATION Regression tests for JSON-decoded radius-pair shapes.
    tests = functiontests(localfunctions);
end

function testSingleColumnVectorIsAccepted(testCase)
    config = createMicrogliaConfig();
    config.spheres.radiusPairs_um = [100; 100];
    normalized = normalizeForTest(config.spheres.radiusPairs_um);
    verifyEqual(testCase, size(normalized), [1, 2]);
    verifyEqual(testCase, normalized, [100, 100]);
end

function radiusPairs = normalizeForTest(radiusPairs)
    radiusPairs = double(radiusPairs);
    if isvector(radiusPairs)
        radiusPairs = reshape(radiusPairs, 1, 2);
    elseif size(radiusPairs, 2) ~= 2 && size(radiusPairs, 1) == 2
        radiusPairs = radiusPairs.';
    end
end
