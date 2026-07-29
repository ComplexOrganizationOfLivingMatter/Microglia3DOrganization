function tests = testPlaqueEnumeration
%TESTPLAQUEENUMERATION Guard against crop- or label-based plaque omission.
    tests = functiontests(localfunctions);
end

function testNoOriginalLabelOutputColumn(testCase)
    root = fileparts(fileparts(mfilename('fullpath')));
    tableFile = fullfile(root, 'tables', 'preparePlaqueDataTable.m');
    standardizeFile = fullfile(root, 'tables', 'standardizeOutputTable.m');
    verifyFalse(testCase, contains(fileread(tableFile), 'OriginalPlaqueLabel'));
    verifyFalse(testCase, contains(fileread(standardizeFile), 'OriginalPlaqueLabel_TIFF'));
end

function testConnectedComponentsDriveRows(testCase)
    root = fileparts(fileparts(mfilename('fullpath')));
    code = fileread(fullfile(root, 'analysis', 'plaques', 'analyzeIndividualPlaques.m'));
    verifyTrue(testCase, contains(code, 'bwconncomp(imgPlaque > 0, 26)'));
    verifyTrue(testCase, contains(code, 'for nPlaque = 1:nPlaquesInImage'));
    verifyFalse(testCase, contains(code, 'for nPlaque = 1:numel(plaques)'));
end
