function tests = testGetZoneFromBorderOriginalBehavior
%TESTGETZONEFROMBORDERORIGINALBEHAVIOR Regression tests for the original layer-zone algorithm.
    tests = functiontests(localfunctions);
end

function testExtendsAlongPositiveX(testCase)
    border = false(5, 8, 3);
    border(3, 2, 2) = true;
    zone = getZoneFromBorder(border, 4);

    expected = false(size(border));
    expected(3, 2:5, 2) = true;
    verifyEqual(testCase, zone, expected);
end

function testClipsAtImageBoundary(testCase)
    border = false(4, 5, 2);
    border(2, 4, 1) = true;
    zone = getZoneFromBorder(border, 10);

    expected = false(size(border));
    expected(2, 4:5, 1) = true;
    verifyEqual(testCase, zone, expected);
end

function testMultipleBorderVoxels(testCase)
    border = false(4, 7, 2);
    border(1, 1, 1) = true;
    border(4, 3, 2) = true;
    zone = getZoneFromBorder(border, 3);

    expected = false(size(border));
    expected(1, 1:3, 1) = true;
    expected(4, 3:5, 2) = true;
    verifyEqual(testCase, zone, expected);
end

function testSingletonZ(testCase)
    border = false(4, 6, 1);
    border(2, 2, 1) = true;
    zone = getZoneFromBorder(border, 3);

    expected = false(4, 6, 1);
    expected(2, 2:4, 1) = true;
    verifyEqual(testCase, zone, expected);
end
