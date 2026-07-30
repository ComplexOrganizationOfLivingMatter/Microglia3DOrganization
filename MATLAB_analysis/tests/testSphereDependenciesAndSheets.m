function tests = testSphereDependenciesAndSheets
%TESTSPHEREDEPENDENCIESANDSHEETS Regression tests for sphere helpers and Excel sheets.
    tests = functiontests(localfunctions);
end

function testSphereHelpersAreIntegrated(testCase)
    sourceText = readSphereSource();
    requiredFunctions = [ ...
        "getSpheresGlobalData_optimized_corrected", ...
        "getPlaqueSphereData_optimized_corrected", ...
        "getNoPlaqueSphereData_optimized_corrected"];

    for i = 1:numel(requiredFunctions)
        expression = "(?m)^function[^\\n]*" + requiredFunctions(i) + "\\b";
        verifyNotEmpty(testCase, regexp(sourceText, expression, 'once'), ...
            sprintf('Missing sphere helper function: %s', requiredFunctions(i)));
    end
end

function testExcelSheetNamesAreValid(testCase)
    sourceText = readSphereSource();
    sheetTokens = regexp(sourceText, "'Sheet'\\s*,\\s*'([^']+)'", 'tokens');

    for i = 1:numel(sheetTokens)
        sheetName = string(sheetTokens{i}{1});
        verifyLessThanOrEqual(testCase, strlength(sheetName), 31);
        verifyEmpty(testCase, regexp(sheetName, '[:\\/\\?\\*\\[\\]]', 'once'));
    end

    verifyNotEmpty(testCase, regexp(sourceText, "'SpherePlaqueRelation'", 'once'));
end

function sourceText = readSphereSource()
    rootPath = fileparts(fileparts(mfilename('fullpath')));
    sourceFile = fullfile(rootPath, 'analysis', 'spheres', 'analyzeSphereData.m');
    sourceText = fileread(sourceFile);
end
