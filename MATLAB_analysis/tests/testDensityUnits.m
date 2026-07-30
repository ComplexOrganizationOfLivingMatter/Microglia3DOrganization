function tests = testDensityUnits
%TESTDENSITYUNITS Guard density names and mm3 conversion factors.
    tests = functiontests(localfunctions);
end

function testLayerTablesContainOnlyMm3AbsoluteDensities(testCase)
    medial = prepareLayerDataTable(table(), 1, 'Medial');
    lateral = preparePlaqueLayerDataTable(table(), 1, 'Lateral');
    names = string([medial.Properties.VariableNames, lateral.Properties.VariableNames]);
    verifyFalse(testCase, any(endsWith(names, 'MicrogliaDensity')));
    verifyFalse(testCase, any(endsWith(names, 'PlaquesDensity')));
    verifyTrue(testCase, any(names == 'Layer1MicrogliaDensitymm3'));
    verifyTrue(testCase, any(names == 'Layer1PlaquesDensitymm3'));
end

function testContextSpecificLayerTotalDensityName(testCase)
    layerTable = table(1, 'VariableNames', {'MicrogliaDensityTotal'});
    plaqueTable = table(1, 'VariableNames', {'MicrogliaDensityTotal'});
    layerTable = standardizeOutputTable(layerTable, 'layers');
    plaqueTable = standardizeOutputTable(plaqueTable, 'plaques');
    verifyEqual(testCase, string(layerTable.Properties.VariableNames), "MicrogliaDensityTotal_cells_mm3");
    verifyEqual(testCase, string(plaqueTable.Properties.VariableNames), "AssociatedMicrogliaDensity_cells_mm3");
end

function testGlobalPlaqueDensityUsesMm3Scale(testCase)
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    source = fileread(fullfile(projectRoot, 'metrics', 'density', 'getPlaqueDataFunction.m'));
    verifyNotEmpty(testCase, regexp(source, 'PlaqueDensityTotal.*\* 1e9', 'once'));
    verifyNotEmpty(testCase, regexp(source, 'PlaqueDensityValid.*\* 1e9', 'once'));
end
