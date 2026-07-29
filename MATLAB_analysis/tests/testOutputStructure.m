function tests = testOutputStructure
%TESTOUTPUTSTRUCTURE Verify centralized data and derived-image folders.
    tests = functiontests(localfunctions);
end

function testStandardOutputTree(testCase)
    root = tempname;
    mkdir(root);
    cleanup = onCleanup(@() rmdir(root, 's')); %#ok<NASGU>

    config = createMicrogliaConfig();
    config.paths.output = root;
    config = createOutputStructure(config);

    verifyEqual(testCase, string(config.paths.globalResults), string(fullfile(root, 'Data', 'General')));
    verifyEqual(testCase, string(config.paths.layerResults), string(fullfile(root, 'Data', 'Layer')));
    verifyEqual(testCase, string(config.paths.plaqueResults), string(fullfile(root, 'Data', 'Plaque')));
    verifyEqual(testCase, string(config.paths.sphereResults), string(fullfile(root, 'Data', 'Spheres')));
    verifyEqual(testCase, string(config.paths.derived), string(fullfile(root, 'DerivedImages')));
    verifyFalse(testCase, isfolder(config.paths.derivedDilatedPlaques));
    verifyFalse(testCase, isfolder(config.paths.derivedSpheres));
    verifyFalse(testCase, isfolder(config.paths.derivedLayers));
    verifyTrue(testCase, isfolder(config.paths.derivedADNoPlaques));
    verifyTrue(testCase, isfolder(config.paths.derivedADPlaques));
end

function testRegionContentPathIsNested(testCase)
    root = tempname;
    mkdir(root);
    cleanup = onCleanup(@() rmdir(root, 's')); %#ok<NASGU>

    actual = getRegionContentPath(root, 'Lateral', 'Variables');
    verifyEqual(testCase, actual, string(fullfile(root, 'Lateral', 'Variables')));
    verifyFalse(testCase, isfolder(fullfile(root, 'LateralVariables')));
end
