% test_filtering.m - UPDATED FOR YOUR PATHS
clear; clc; close all;

% Get project root directory
project_root = 'C:\Users\Potato\Desktop\real-Time-ECG-Signal-Processing-Using-MATLAB';

% Define paths
data_raw_path = fullfile(project_root, 'data', 'raw');
src_path = fullfile(project_root, 'src', 'matlab');
utils_path = fullfile(src_path, 'utils');

% Add paths to MATLAB
addpath(genpath(src_path));
addpath(genpath(utils_path));

fprintf('=== ECG Filtering Pipeline Test ===\n');
fprintf('Project root: %s\n', project_root);
fprintf('Data path: %s\n', data_raw_path);
fprintf('Source path: %s\n', src_path);

% Check if data path exists
if ~exist(data_raw_path, 'dir')
    fprintf('ERROR: Data path not found!\n');
    fprintf('Please ensure MIT-BIH files are in: %s\n', data_raw_path);
    return;
end

% Check for MIT-BIH files
expected_files = {'100.dat', '100.hea', '100.atr'};
all_files_exist = true;
for i = 1:length(expected_files)
    file_path = fullfile(data_raw_path, expected_files{i});
    if ~exist(file_path, 'file')
        fprintf('Missing: %s\n', expected_files{i});
        all_files_exist = false;
    end
end

if ~all_files_exist
    fprintf('\n❌ Missing MIT-BIH files!\n');
    fprintf('Download from: https://physionet.org/content/mitdb/1.0.0/\n');
    fprintf('Place files in: %s\n', data_raw_path);
    return;
end

% Test parameters
record_name = '100';

try
    %% Step 1: Load and preprocess
    fprintf('\n1. Loading and preprocessing ECG...\n');
    [clean_ecg, ~, Fs] = preprocess_ecg(record_name, data_raw_path);
    
    fprintf('   Preprocessing complete!\n');
    fprintf('   Signal length: %d samples (%.1f seconds)\n', ...
            length(clean_ecg), length(clean_ecg)/Fs);
    
    %% Step 2: Apply filtering
    fprintf('\n2. Applying filters...\n');
    
    % Check if filter_ecg function exists
    if exist('filter_ecg', 'file') == 2
        [filtered_ecg, filters_info] = filter_ecg(clean_ecg, Fs);
    else
        fprintf('   filter_ecg.m not found. Creating filtered signal using bandpass only...\n');
        
        % Simple bandpass filter if main function doesn't exist yet
        [b, a] = butter(4, [5, 15]/(Fs/2), 'bandpass');
        filtered_ecg = filtfilt(b, a, clean_ecg);
        filters_info = struct('Fs', Fs, 'filter_type', 'bandpass_5_15_Hz');
    end
    
    %% Step 3: Visualize results
    fprintf('\n3. Creating visualization...\n');
    
    % Create time vector
    t = (0:length(clean_ecg)-1) / Fs;
    
    % Plot comparison
    figure('Position', [100, 100, 1200, 600]);
    
    % Plot 1: Preprocessed vs Filtered (full signal)
    subplot(2, 2, 1);
    plot(t, clean_ecg, 'b', 'LineWidth', 1); hold on;
    plot(t, filtered_ecg, 'r', 'LineWidth', 1.5);
    xlabel('Time (seconds)');
    ylabel('Amplitude');
    title('Preprocessed vs Filtered ECG');
    legend('Preprocessed', 'Filtered', 'Location', 'best');
    grid on;
    
    % Plot 2: Zoomed view (first 5 seconds)
    subplot(2, 2, 2);
    zoom_samples = 1:min(5*Fs, length(clean_ecg));
    plot(t(zoom_samples), clean_ecg(zoom_samples), 'b', 'LineWidth', 1); hold on;
    plot(t(zoom_samples), filtered_ecg(zoom_samples), 'r', 'LineWidth', 1.5);
    xlabel('Time (seconds)');
    title('First 5 Seconds (Zoomed)');
    legend('Preprocessed', 'Filtered', 'Location', 'best');
    grid on;
    
    % Plot 3: Frequency spectrum comparison
    subplot(2, 2, 3);
    [f_pre, P_pre] = plot_fft(clean_ecg, Fs, false);
    [f_filt, P_filt] = plot_fft(filtered_ecg, Fs, false);
    plot(f_pre, 10*log10(P_pre), 'b'); hold on;
    plot(f_filt, 10*log10(P_filt), 'r');
    xlim([0, 100]);
    xlabel('Frequency (Hz)');
    ylabel('Power (dB)');
    title('Frequency Spectrum');
    legend('Preprocessed', 'Filtered');
    grid on;
    
    % Plot 4: QRS complex comparison
    subplot(2, 2, 4);
    % Find a QRS complex (around sample 2000-2500 typically)
    qrs_start = max(1, 2000);
    qrs_end = min(length(clean_ecg), 2500);
    qrs_range = qrs_start:qrs_end;
    
    plot(t(qrs_range), clean_ecg(qrs_range), 'b', 'LineWidth', 1.5); hold on;
    plot(t(qrs_range), filtered_ecg(qrs_range), 'r', 'LineWidth', 2);
    xlabel('Time (seconds)');
    title('Single QRS Complex Comparison');
    legend('Preprocessed', 'Filtered', 'Location', 'best');
    grid on;
    
    %% Step 4: Save results
    fprintf('\n4. Saving results...\n');
    
    % Create processed data directory if it doesn't exist
    processed_dir = fullfile(project_root, 'data', 'processed');
    if ~exist(processed_dir, 'dir')
        mkdir(processed_dir);
        fprintf('   Created directory: %s\n', processed_dir);
    end
    
    % Save filtered data
    save_path = fullfile(processed_dir, 'filtered_ecg_100.mat');
    save(save_path, 'filtered_ecg', 'clean_ecg', 'Fs', 'filters_info', 't');
    
    fprintf('\n✅ Filtering Test Complete!\n');
    fprintf('   Results saved to: %s\n', save_path);
    fprintf('   Filtered signal saved for R-peak detection.\n');
    
catch ME
    fprintf('\n❌ Error during filtering test:\n');
    fprintf('   %s\n', ME.message);
    
    % Try to identify which function is missing
    fprintf('\nDebugging info:\n');
    fprintf('   Checking preprocess_ecg: %s\n', ...
            ternary(exist('preprocess_ecg', 'file') == 2, '✓ Found', '✗ Missing'));
    fprintf('   Checking plot_fft: %s\n', ...
            ternary(exist('plot_fft', 'file') == 2, '✓ Found', '✗ Missing'));
    
    % Show full error stack
    for i = 1:length(ME.stack)
        fprintf('   Error in %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

%% Helper function
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end