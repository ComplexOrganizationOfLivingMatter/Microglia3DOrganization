function tests = testSphereConsolidatedFixesV2314
tests = functiontests(localfunctions);
end

function testNoLegacySphereNames(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
files = [dir(fullfile(root,'analysis','spheres','*.m')); dir(fullfile(root,'tables','*Sphere*.m'))];
text = "";
for i = 1:numel(files)
    text = text + string(fileread(fullfile(files(i).folder, files(i).name)));
end
verifyFalse(testCase, contains(text,'AnalyzedSpheres'));
verifyFalse(testCase, contains(text,'nVoronoiMicroglias'));
verifyFalse(testCase, contains(text,'Centered_Points'));
verifyFalse(testCase, contains(text,'Align_superf'));
verifyFalse(testCase, contains(text,'JointData_'));
end

function testSphereRowsGrowDynamically(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
text = fileread(fullfile(root,'analysis','spheres','analyzeSphereData.m'));
verifyGreaterThanOrEqual(testCase, count(string(text),'nextAvailableTableRow'), 3);
verifyTrue(testCase, contains(text,"saveFolderSpheres = 'PlaqueSpheres'"));
verifyTrue(testCase, contains(text,'CentralThirdMicrogliaFraction'));
verifyTrue(testCase, contains(text,'countSphereCentroids'));
end

function testProfessionalVoronoiPaths(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
text = fileread(fullfile(root,'metrics','voronoi','getVoronoiSphereData.m'));
verifyTrue(testCase, contains(text,"'Voronoi', modeFolder, 'Variables'"));
verifyTrue(testCase, contains(text,'IntersectingCells'));
verifyTrue(testCase, contains(text,'FullyContainedCells'));
end
