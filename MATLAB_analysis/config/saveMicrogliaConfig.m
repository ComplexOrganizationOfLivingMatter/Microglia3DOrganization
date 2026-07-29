function saveMicrogliaConfig(config, outputFolder)
%SAVEMICROGLIACONFIG Save configuration as MAT and human-readable JSON.
    if nargin < 2 || strlength(string(outputFolder)) == 0
        outputFolder = pwd;
    end
    if ~isfolder(outputFolder), mkdir(outputFolder); end
    save(fullfile(outputFolder,'microglia_config.mat'),'config');
    jsonText = jsonencode(config, PrettyPrint=true);
    fid = fopen(fullfile(outputFolder,'microglia_config.json'),'w');
    assert(fid >= 0, 'Could not create configuration JSON.');
    cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fwrite(fid, jsonText, 'char');
end
