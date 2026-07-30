function tests = testLayerImageSelection
%TESTLAYERIMAGESELECTION Verify all, Excel, manual, and normalized selection behavior.

    tests = functiontests(localfunctions);
end

function testAllImages(testCase)
    config = createMicrogliaConfig();
    config.layers.imageSelection.mode = "all";
    metadata = createMetadata();

    actual = resolveLayerImageSelection(metadata, config);

    verifyEqual(testCase, actual, true(3, 1));
end

function testExcelColumn(testCase)
    config = createMicrogliaConfig();
    config.layers.imageSelection.mode = "excel";
    config.layers.imageSelection.column = "UseForLayerAnalysis";
    metadata = createMetadata();

    actual = resolveLayerImageSelection(metadata, config);

    verifyEqual(testCase, actual, [true; false; true]);
end

function testManualSelection(testCase)
    config = createMicrogliaConfig();
    config.layers.imageSelection.mode = "manual";
    config.layers.imageSelection.selectedFiles = ["Image_A"; "Image_C"];
    metadata = createMetadata();

    actual = resolveLayerImageSelection(metadata, config);

    verifyEqual(testCase, actual, [true; false; true]);
end

function testNormalizedAvailability(testCase)
    normalized = table([true; false], ["YES"; "NO"], ...
        'VariableNames', {'LayerInformationAvailable', 'Layers'});

    verifyTrue(testCase, getLayerInformationAvailability(normalized, 1));
    verifyFalse(testCase, getLayerInformationAvailability(normalized, 2));
end

function metadata = createMetadata()
    metadata = table( ...
        ["Image_A"; "Image_B"; "Image_C"], ...
        ["YES"; "NO"; "TRUE"], ...
        'VariableNames', {'Archivo', 'UseForLayerAnalysis'});
end
