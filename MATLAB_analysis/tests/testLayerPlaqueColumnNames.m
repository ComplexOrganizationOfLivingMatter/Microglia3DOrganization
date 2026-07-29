function tests = testLayerPlaqueColumnNames
%TESTLAYERPLAQUECOLUMNNAMES Verify distinct microglia and plaque layer-volume names.
    tests = functiontests(localfunctions);
end

function testLateralLayerVolumeNamesAreDistinct(testCase)
    microgliaTable = prepareLayerDataTable(table(), 1, 'Lateral');
    plaqueTable = preparePlaqueLayerDataTable(table(), 1, 'Lateral');

    duplicateNames = intersect(string(microgliaTable.Properties.VariableNames), ...
        string(plaqueTable.Properties.VariableNames));

    verifyEmpty(testCase, duplicateNames);
    verifyTrue(testCase, ismember('Layer1Volume_Plaques', plaqueTable.Properties.VariableNames));
    verifyTrue(testCase, ismember('Layer4Volume_Plaques', plaqueTable.Properties.VariableNames));
end

function testMedialLayerVolumeNamesAreDistinct(testCase)
    microgliaTable = prepareLayerDataTable(table(), 1, 'Medial');
    plaqueTable = preparePlaqueLayerDataTable(table(), 1, 'Medial');

    duplicateNames = intersect(string(microgliaTable.Properties.VariableNames), ...
        string(plaqueTable.Properties.VariableNames));

    verifyEmpty(testCase, duplicateNames);
    verifyTrue(testCase, ismember('Layer1Volume_Plaques', plaqueTable.Properties.VariableNames));
    verifyTrue(testCase, ismember('Layer6Volume_Plaques', plaqueTable.Properties.VariableNames));
end
