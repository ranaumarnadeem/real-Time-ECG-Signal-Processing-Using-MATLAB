function [ecg, Fs, ann_samples, ann_symbols, info] = load_ecg(recordName, dataPath)

    % Validate inputs
    if nargin < 2
        error('Usage: load_ecg(recordName, dataPath)');
    end
    if ~isfolder(dataPath)
        error('Data path does not exist.');
    end

    %paths
    hea_file = fullfile(dataPath, [recordName '.hea']);
    dat_file = fullfile(dataPath, [recordName '.dat']);
    atr_file = fullfile(dataPath, [recordName '.atr']);

    if ~isfile(hea_file)
        error('Header file not found: %s', hea_file);
    end
    if ~isfile(dat_file)
        error('Signal file (.dat) not found: %s', dat_file);
    end

    % reading headers
    fid = fopen(hea_file, 'r');
    header = textscan(fid, '%s', 'Delimiter', '\n');
    header = header{1};
    fclose(fid);

    first = strsplit(header{1});
    Fs = str2double(first{3});
    numSamples = str2double(first{4});

    % READ SIGNA


    fid = fopen(dat_file, 'r');
    A = fread(fid, [3, inf], 'uint8')';
    fclose(fid);

    M0 = bitshift(A(:,2), -4);
    M1 = bitand(A(:,2), 15);

    x1 = bitshift(M0, 8) + A(:,1);
    x2 = bitshift(M1, 8) + A(:,3);

    x = [x1; x2];
    x(x > 2047) = x(x > 2047) - 4096;  % 12-bit signed
    x = x(1:numSamples);

    ecg = x;

    % read.atr
    if isfile(atr_file)
        [ann_samples, ann_symbols] = readMITBIHAnnotations(atr_file);
    else
        warning('No annotation (.atr) file found.');
        ann_samples = [];
        ann_symbols = [];
    end

    %info in a struct
    info.recordName = recordName;
    info.Fs = Fs;
    info.numSamples = numSamples;

 
    fprintf('\n=== Loaded MIT-BIH record %s ===\n', recordName);
    fprintf('Samples: %d\n', numSamples);
    fprintf('Duration: %.2f seconds\n', numSamples/Fs);
    fprintf('Sampling Frequency: %d Hz\n', Fs);
    fprintf('Annotations: %d\n', length(ann_samples));
    fprintf('==========================================\n\n');

end


%  .atr annotation file 

function [annsamp, anntype] = readMITBIHAnnotations(atr_file)
    fid = fopen(atr_file, 'r');
    A = fread(fid, 'uint8');
    fclose(fid);

    A = A(:);
    I = 1;
    annsamp = [];
    anntype = {};

    t = 0;

    while I < length(A)-1
        ann = bitshift(A(I+1), -2);
        dt  = bitshift(bitand(A(I+1), 3), 8) + A(I);

        if ann == 0
            break;
        end

        t = t + dt;
        annsamp(end+1) = t;
        anntype{end+1} = char(ann);

        I = I + 2;
    end
end
