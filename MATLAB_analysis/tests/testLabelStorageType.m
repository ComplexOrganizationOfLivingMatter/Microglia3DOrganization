function tests = testLabelStorageType
%TESTLABELSTORAGETYPE Verify automatic uint8/uint16 selection for label images.
    tests = functiontests(localfunctions);
end

function testUsesUint8UpTo254(testCase)
    image = reshape(0:254, [15, 17]);
    actual = castLabelImageForStorage(image);
    verifyClass(testCase, actual, 'uint8');
    verifyEqual(testCase, max(actual(:)), uint8(254));
end

function testUsesUint16Above254(testCase)
    image = uint16([0 1 254 255 500]);
    actual = castLabelImageForStorage(image);
    verifyClass(testCase, actual, 'uint16');
    verifyEqual(testCase, max(actual(:)), uint16(500));
end
