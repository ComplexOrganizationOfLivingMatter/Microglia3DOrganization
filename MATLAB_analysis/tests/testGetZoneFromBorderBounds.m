function tests = testGetZoneFromBorderBounds
%TESTGETZONEFROMBORDERBOUNDS Verify bounded layer-zone generation.
    tests = functiontests(localfunctions);
end

function testBorderAtLastColumn(testCase)
    border = false(5, 7, 3);
    border(3, 7, 2) = true;
    zone = getZoneFromBorder(border, 20);
    verifyEqual(testCase, size(zone), size(border));
    verifyTrue(testCase, zone(3, 7, 2));
    verifyEqual(testCase, nnz(zone), 1);
end

function testExtensionAlongPositiveX(testCase)
    border = false(4, 8, 2);
    border(2, 3, 1) = true;
    zone = getZoneFromBorder(border, 4);
    expected = false(size(border));
    expected(2, 3:6, 1) = true;
    verifyEqual(testCase, zone, expected);
end

function testSingletonZ(testCase)
    border = false(4, 8, 1);
    border(2, 2, 1) = true;
    zone = getZoneFromBorder(border, 3);
    verifyTrue(testCase, all(zone(2, 2:4, 1)));
end
