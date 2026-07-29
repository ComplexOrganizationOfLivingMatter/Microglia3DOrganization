function tests = testConsolidatedFixesV238
%TESTCONSOLIDATEDFIXESV238 Regression tests for v2.3.8 fixes.
    tests = functiontests(localfunctions);
end

function testLayerTablesContainOnlyPerLayerMeasurements(testCase)
    T = prepareLayerDataTable(table(), 1, 'Medial');
    names = string(T.Properties.VariableNames);
    verifyFalse(testCase, any(contains(names, 'DensityRelative')));
    verifyFalse(testCase, any(contains(names, 'Percentage')));
    verifyFalse(testCase, any(names == 'VolumeTotal'));
    verifyFalse(testCase, any(names == 'MicrogliaDensityTotal'));
end

function testPlaqueLayerNamesUseDescriptiveSuffix(testCase)
    T = preparePlaqueLayerDataTable(table(), 1, 'Lateral');
    names = string(T.Properties.VariableNames);
    verifyTrue(testCase, any(names == 'Layer1Volume_Plaques'));
    verifyTrue(testCase, any(names == 'Layer4Volume_Plaques'));
    verifyFalse(testCase, any(endsWith(names, '_P')));
end

function testPlaqueFlagsExistWithoutOriginalLabel(testCase)
    T = preparePlaqueDataTable(table(), 1);
    names = string(T.Properties.VariableNames);
    verifyTrue(testCase, all(ismember(["isCompleted", "isInsideCrop", ...
        "isCompletedInsideCrop"], names)));
    verifyFalse(testCase, any(names == "OriginalPlaqueLabel"));
end

function testSphereIndicesAreClipped(testCase)
    [~, idx] = getSphereFromCentroid([1, 1, 1], 20, [10, 11, 12]);
    verifyGreaterThanOrEqual(testCase, idx, ones(size(idx)));
    verifyLessThanOrEqual(testCase, idx, repmat(prod([10, 11, 12]), size(idx)));
end
