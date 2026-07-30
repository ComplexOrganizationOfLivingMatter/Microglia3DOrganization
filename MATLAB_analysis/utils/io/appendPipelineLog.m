function appendPipelineLog(logRoot, stageName, status, messageText, exceptionObject)
%APPENDPIPELINELOG Append a timestamped pipeline event to the general log.
%
% Inputs:
%   logRoot         Root Log folder.
%   stageName       Pipeline stage name.
%   status          STARTED, COMPLETED, WARNING, or ERROR.
%   messageText     Optional descriptive text.
%   exceptionObject Optional MException used to record the full stack.

    if nargin < 4 || isempty(messageText)
        messageText = "";
    end
    if nargin < 5
        exceptionObject = [];
    end

    logRoot = char(logRoot);
    if ~isfolder(logRoot)
        mkdir(logRoot);
    end

    logFile = fullfile(logRoot, 'MicrogliaAnalysis.log');
    fid = fopen(logFile, 'a');
    if fid < 0
        warning('Could not open pipeline log file: %s', logFile);
        return;
    end
    cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

    timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    fprintf(fid, '[%s] [%s] [%s] %s\n', timestamp, upper(char(status)), ...
        char(stageName), char(string(messageText)));

    if ~isempty(exceptionObject)
        fprintf(fid, '  Identifier: %s\n', exceptionObject.identifier);
        fprintf(fid, '  Message: %s\n', exceptionObject.message);
        for k = 1:numel(exceptionObject.stack)
            entry = exceptionObject.stack(k);
            fprintf(fid, '  at %s (line %d)\n', entry.name, entry.line);
        end
    end
end
