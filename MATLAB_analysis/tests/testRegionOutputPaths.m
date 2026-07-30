function tests = testRegionOutputPaths
tests = functiontests(localfunctions);
end

function testNoConcatenatedRegionFolders(testCase)
projectRoot = fileparts(fileparts(mfilename('fullpath')));
files = dir(fullfile(projectRoot, '**', '*.m'));
for i = 1:numel(files)
    filePath = fullfile(files(i).folder, files(i).name);
    txt = fileread(filePath);
    verifyFalse(testCase, contains(txt, "strcat(savePath, 'Graph/"), filePath);
    verifyFalse(testCase, contains(txt, "strcat(savePath,'Graph/"), filePath);
    verifyFalse(testCase, contains(txt, "strcat(savePath, 'Variables/"), filePath);
    verifyFalse(testCase, contains(txt, "strcat(savePath,'Variables/"), filePath);
end
end
