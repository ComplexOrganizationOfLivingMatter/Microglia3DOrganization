function results = runAllTests()
%RUNALLTESTS Run the repository regression tests.

    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(projectRoot));

    results = runtests(fullfile(projectRoot, 'tests'), 'IncludeSubfolders', true);
    disp(results);

    if any([results.Failed])
        error('One or more MicrogliaAnalysis regression tests failed.');
    end
end
