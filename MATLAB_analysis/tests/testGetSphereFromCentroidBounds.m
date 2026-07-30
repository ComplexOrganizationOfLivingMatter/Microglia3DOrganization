function tests = testGetSphereFromCentroidBounds
%TESTGETSPHEREFROMCENTROIDBOUNDS Regression tests for clipped spheres.
    tests = functiontests(localfunctions);
end

function testInteriorSphere(testCase)
    imageSize = [40, 50, 30];
    [mask, idx] = getSphereFromCentroid([25, 20, 15], 6, imageSize);
    verifySize(testCase, mask, imageSize);
    verifyTrue(testCase, all(idx >= 1 & idx <= prod(imageSize)));
    verifyEqual(testCase, nnz(mask), numel(idx));
end

function testSphereClippedAtAllBorders(testCase)
    imageSize = [20, 25, 15];
    centers = [1, 1, 1; 25, 20, 15; 0.5, 0.5, 0.5; 25.5, 20.5, 15.5];
    for k = 1:size(centers, 1)
        [mask, idx] = getSphereFromCentroid(centers(k,:), 8, imageSize);
        verifySize(testCase, mask, imageSize);
        verifyTrue(testCase, all(idx >= 1 & idx <= prod(imageSize)));
        verifyEqual(testCase, nnz(mask), numel(idx));
    end
end

function testCenterOutsideImage(testCase)
    imageSize = [20, 25, 15];
    [mask, idx] = getSphereFromCentroid([-100, -100, -100], 4, imageSize);
    verifyFalse(testCase, any(mask, 'all'));
    verifyEmpty(testCase, idx);
end
