function [ecg, Fs, ann_samples, ann_symbols, info] = load_data(recordName, dataPath)



   % check for inputs
    if nargin < 2
        error('Usage: load_data(recordName, dataPath)');
    end
    
    if ~isfolder(dataPath)
        error('Data path does not exist: %s', dataPath);
    end

    % Remove trailing slash
    if dataPath(end) == '/' || dataPath(end) == '\'
        dataPath = dataPath(1:end-1);
    end

    
    % Build full WFDB record path
    
    recordPath = fullfile(dataPath, recordName);

    
    % headers
    
    try
        info = wfdbdesc(recordPath);
    catch
        error('Could not read header. Check if WFDB Toolbox is installed or files exist.');
    end

    % Sampling frequency
    Fs = info.fs;

    
    % Read signal
    
    try
        % Read first channel only for simplicity
        [signal, ~] = rdsamp(recordPath, 1);
    catch
        error('Unable to read signal. Ensure .dat and .hea are in the folder.');
    end

    ecg = signal(:,1);   % Channel 1

    
    % Read annotations (.atr)
    
    try
        ann = rdann(recordPath, 'atr');
        ann_samples = ann.annsamp;    % sample indices of annotations
        ann_symbols = ann.ann;        % annotation symbols
    catch
        warning('No annotations found (.atr missing). Returning empty annotations.');
        ann_samples = [];
        ann_symbols = [];
    end

    
  
    
    fprintf('\nLoaded record %s\n', recordName);
    fprintf('  Path: %s\n', recordPath);
    fprintf('  Samples: %d\n', length(ecg));
    fprintf('  Sampling frequency: %d Hz\n', Fs);
    fprintf('  Annotations: %d\n\n', length(ann_samples));

end
