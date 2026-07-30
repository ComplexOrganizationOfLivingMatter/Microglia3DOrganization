function tests = testSphereRadiusFolderConsistency
%TESTSPHERERADIUSFOLDERCONSISTENCY Verify canonical sphere-radius paths.
    tests = functiontests(localfunctions);
end

function testIntegerRadii(testCase)
    actual = getSphereRadiusFolderName(100, 50);
    verifyEqual(testCase, actual, 'PlaqueSphereR100_NonPlaqueSphereR50');
end

function testDecimalRadii(testCase)
    actual = getSphereRadiusFolderName(12.5, 7.25);
    verifyEqual(testCase, actual, 'PlaqueSphereR12p5_NonPlaqueSphereR7p25');
end

function testGenerationAndAnalysisUseHelper(testCase)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    generationText = fileread(fullfile(projectRoot, 'preprocessing', 'spheres', ...
        'generateSphereDefinitions.m'));
    analysisText = fileread(fullfile(projectRoot, 'analysis', 'spheres', ...
        'analyzeSphereData.m'));

    verifyNotEmpty(testCase, strfind(generationText, 'getSphereRadiusFolderName')); %#ok<STRIFCND>
    verifyNotEmpty(testCase, strfind(analysisText, 'getSphereRadiusFolderName')); %#ok<STRIFCND>
    verifyEmpty(testCase, strfind(generationText, 'Plaque%d_NonPlaque%d')); %#ok<STRIFCND>
    verifyEmpty(testCase, strfind(analysisText, 'PlaqueRadius%d_NonPlaqueRadius%d')); %#ok<STRIFCND>
end
