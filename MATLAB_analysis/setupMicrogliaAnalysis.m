function setupMicrogliaAnalysis()
%SETUPMICROGLIAANALYSIS Add all project folders to the MATLAB search path.
    projectRoot = fileparts(mfilename('fullpath'));
    addpath(genpath(projectRoot));
    fprintf('MicrogliaAnalysis folders added to the MATLAB path.\n');
end
