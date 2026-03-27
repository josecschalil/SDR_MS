function read_app_log(logFile, lastN)
% READ_APP_LOG Print the latest GUI app log entries.
%
% Usage:
%   read_app_log()                    % opens newest log in logs/
%   read_app_log('logs/file.txt')     % opens specific file
%   read_app_log([], 200)             % print last 200 lines
%
% This helper is designed for troubleshooting communication issues.

    if nargin < 2 || isempty(lastN)
        lastN = 150;
    end

    if nargin < 1 || isempty(logFile)
        logFile = findLatestLogFile();
        if isempty(logFile)
            fprintf('No log files found in logs/\n');
            return;
        end
    end

    if ~exist(logFile, 'file')
        fprintf('Log file not found: %s\n', logFile);
        return;
    end

    fprintf('Reading log: %s\n', logFile);
    fprintf('Showing last %d line(s)\n\n', lastN);

    text = fileread(logFile);
    if isempty(text)
        fprintf('(Log file is empty)\n');
        return;
    end

    lines = splitlines(string(text));
    lines = lines(~strcmp(lines, ""));

    startIdx = max(1, numel(lines) - lastN + 1);
    for i = startIdx:numel(lines)
        fprintf('%s\n', lines(i));
    end
end

function logFile = findLatestLogFile()
    logFile = '';
    logDir = fullfile(pwd, 'logs');
    if ~exist(logDir, 'dir')
        return;
    end

    files = dir(fullfile(logDir, 'gui_app_*.txt'));
    if isempty(files)
        return;
    end

    [~, idx] = max([files.datenum]);
    logFile = fullfile(files(idx).folder, files(idx).name);
end
