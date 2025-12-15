% Complete pipeline: Load → Preprocess → Filter → Detect R-peaks → Analyze

fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║    ECG SIGNAL PROCESSING PIPELINE - MAIN EXECUTION         ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

%% ============================================================
%  CONFIGURATION
%% ============================================================

% Auto-detect project root (works from any location)
current_file = mfilename('fullpath');
matlab_dir = fileparts(current_file);
src_dir = fileparts(matlab_dir);
project_root = fileparts(src_dir);

% Setup paths
data_raw = fullfile(project_root, 'data', 'raw');
data_processed = fullfile(project_root, 'data', 'processed');
addpath(genpath(matlab_dir));

% Configuration
record_name = '100';  % MIT-BIH record to process
visualize = true;     % Enable visualizations

% Create output directory
if ~exist(data_processed, 'dir')
    mkdir(data_processed);
    fprintf(' Created output directory: %s\n\n', data_processed);
end

fprintf(' Project Root: %s\n', project_root);
fprintf(' Processing Record: %s\n\n', record_name);

%% ============================================================
%  STEP 1: LOAD ECG DATA
%% ============================================================

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('STEP 1: Loading ECG Data\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

try
    [raw_ecg, Fs, ann_samples, ann_symbols] = load_ecg(record_name, data_raw);
    duration = length(raw_ecg) / Fs;
    
    fprintf('✓ Successfully loaded record %s\n', record_name);
    fprintf('  • Samples: %d\n', length(raw_ecg));
    fprintf('  • Sampling Rate: %d Hz\n', Fs);
    fprintf('  • Duration: %.2f seconds (%.2f minutes)\n', duration, duration/60);
    fprintf('  • Annotations: %d R-peaks\n', length(ann_samples));
    
    % Quick visualization of raw ECG
    if visualize
        figure('Name', 'Raw ECG Signal', 'Position', [50, 50, 1200, 400]);
        t_raw = (0:length(raw_ecg)-1) / Fs;
        plot(t_raw, raw_ecg, 'b', 'LineWidth', 0.8);
        xlabel('Time (s)'); ylabel('Amplitude (mV)');
        title(sprintf('Raw ECG Signal - Record %s', record_name));
        grid on; xlim([0, min(10, duration)]);
    end
    
catch ME
    fprintf('✗ ERROR: Failed to load ECG data\n');
    fprintf('  Reason: %s\n', ME.message);
    return;
end

fprintf('\n');

%% ============================================================
%  STEP 2: PREPROCESS ECG
%% ============================================================

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('STEP 2: Preprocessing ECG Signal\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

try
    [clean_ecg, ~, ~] = preprocess_ecg(record_name, data_raw);
    fprintf('✓ Preprocessing completed\n');
    fprintf('  • DC offset removed\n');
    fprintf('  • Baseline wander removed (0.5 Hz highpass)\n');
    fprintf('  • Signal normalized to [-1, 1]\n');
    
catch ME
    fprintf('✗ ERROR: Preprocessing failed\n');
    fprintf('  Reason: %s\n', ME.message);
    return;
end

fprintf('\n');

%% ============================================================
%  STEP 3: FILTER ECG
%% ============================================================

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('STEP 3: Filtering ECG Signal\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

try
    % Use full signal or limit for faster processing
    test_samples = 1:min(60*Fs, length(clean_ecg));  % Process up to 60 seconds
    test_ecg = clean_ecg(test_samples);
    
    [filtered_ecg, filter_info] = filter_ecg(test_ecg, Fs, false);
    fprintf('✓ Filtering completed\n');
    fprintf('  • 50 Hz powerline noise removed\n');
    fprintf('  • Bandpass filtered (5-15 Hz for QRS)\n');
    fprintf('  • Processed duration: %.2f seconds\n', length(filtered_ecg)/Fs);
    
catch ME
    fprintf('✗ ERROR: Filtering failed\n');
    fprintf('  Reason: %s\n', ME.message);
    return;
end

fprintf('\n');

%% ============================================================
%  STEP 4: DETECT R-PEAKS (Pan-Tompkins Algorithm)
%% ============================================================

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('STEP 4: R-Peak Detection\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

try
    [r_locs, r_peaks] = r_peak_detection(filtered_ecg, Fs);
    
    fprintf('✓ R-peak detection completed (Pan-Tompkins)\n');
    fprintf('  • R-peaks detected: %d\n', length(r_locs));
    fprintf('  • Average detection rate: %.1f peaks/second\n', length(r_locs)/(length(filtered_ecg)/Fs));
    
    if length(r_locs) >= 5
        fprintf('  • First 5 R-peak locations (samples): ');
        fprintf('%d ', r_locs(1:5));
        fprintf('\n');
    end
    

    
catch ME
    fprintf('✗ ERROR: R-peak detection failed\n');
    fprintf('  Reason: %s\n', ME.message);
    return;
end

fprintf('\n');

%% ============================================================
%  STEP 5: COMPUTE RR INTERVALS & HEART RATE
%% ============================================================

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('STEP 5: Heart Rate Analysis\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

try
    % Check if compute_rr_hr exists (might be .mlx)
    if exist('compute_rr_hr', 'file')
        [RR_intervals, HR] = compute_rr_hr(r_locs, Fs);
    else
        % Manual computation if function doesn't exist
        RR_intervals = diff(r_locs) / Fs;  % in seconds
        HR = 60 ./ RR_intervals;  % beats per minute
    end
    
    fprintf('✓ Heart rate analysis completed\n');
    fprintf('  • RR intervals computed: %d\n', length(RR_intervals));
    fprintf('  • Mean HR: %.1f BPM\n', mean(HR));
    fprintf('  • HR Range: %.1f - %.1f BPM\n', min(HR), max(HR));
    fprintf('  • HR Std Dev: %.1f BPM\n', std(HR));
    fprintf('  • Mean RR: %.3f seconds\n', mean(RR_intervals));
    
catch ME
    fprintf('⚠ WARNING: Heart rate computation had issues\n');
    fprintf('  Reason: %s\n', ME.message);
    fprintf('  Continuing with available data...\n');
    RR_intervals = [];
    HR = [];
end

fprintf('\n');

%% ============================================================
%  STEP 6: COMPREHENSIVE VISUALIZATION
%% ============================================================

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('STEP 6: Creating Comprehensive Visualization\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

if visualize && exist('r_locs', 'var') && ~isempty(r_locs)
    try
        % Create comprehensive figure
        figure('Name', 'ECG Processing Pipeline Results', 'Position', [50, 50, 1400, 900]);
        
        % Time vectors
        t_raw = (0:length(raw_ecg)-1) / Fs;
        t_filt = (0:length(filtered_ecg)-1) / Fs;
        
        % Limit to first 10 seconds for clarity
        display_duration = min(10, length(filtered_ecg)/Fs);
        idx_raw = t_raw <= display_duration;
        idx_filt = t_filt <= display_duration;
        r_idx = r_locs/Fs <= display_duration;
        
        % Panel 1: Raw ECG Signal
        subplot(3,1,1);
        plot(t_raw(idx_raw), raw_ecg(idx_raw), 'b', 'LineWidth', 1);
        xlabel('Time (s)'); ylabel('Amplitude (mV)');
        title('1. Raw ECG Signal', 'FontSize', 12, 'FontWeight', 'bold');
        grid on; xlim([0 display_duration]);
        
        % Panel 2: Filtered ECG Signal
        subplot(3,1,2);
        plot(t_filt(idx_filt), filtered_ecg(idx_filt), 'g', 'LineWidth', 1);
        xlabel('Time (s)'); ylabel('Amplitude');
        title('2. Filtered ECG Signal (50Hz removed + 5-15Hz bandpass)', 'FontSize', 12, 'FontWeight', 'bold');
        grid on; xlim([0 display_duration]);
        
        % Panel 3: Final Signal with R-Peaks and Heart Rate
        subplot(3,1,3);
        plot(t_filt(idx_filt), filtered_ecg(idx_filt), 'k', 'LineWidth', 1); hold on;
        scatter(r_locs(r_idx)/Fs, r_peaks(r_idx), 100, 'r', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        
        % Add heart rate annotations between R-peaks
        if ~isempty(HR) && length(r_locs(r_idx)) > 1
            r_times = r_locs(r_idx) / Fs;
            for i = 1:length(r_times)-1
                mid_time = (r_times(i) + r_times(i+1)) / 2;
                mid_y = max(filtered_ecg(idx_filt)) * 0.8;
                text(mid_time, mid_y, sprintf('%.0f BPM', HR(i)), ...
                    'HorizontalAlignment', 'center', 'FontSize', 9, ...
                    'BackgroundColor', 'white', 'EdgeColor', 'blue', 'FontWeight', 'bold');
            end
        end
        
        xlabel('Time (s)'); ylabel('Amplitude');
        title('3. Final Signal with Detected R-Peaks & Heart Rate', 'FontSize', 12, 'FontWeight', 'bold');
        legend('Filtered ECG', 'R-Peaks', 'Location', 'best');
        grid on; xlim([0 display_duration]);
        
        sgtitle(sprintf('ECG Signal Processing Pipeline - Record %s', record_name), ...
            'FontSize', 14, 'FontWeight', 'bold');
        
        fprintf('✓ Visualization created successfully\n');
        fprintf('  • Showing first %.1f seconds\n', display_duration);
        fprintf('  • Panel 1: Raw signal\n');
        fprintf('  • Panel 2: Filtered signal\n');
        fprintf('  • Panel 3: Final signal with R-peaks and heart rates\n');
        
    catch ME
        fprintf('⚠ WARNING: Visualization failed\n');
        fprintf('  Reason: %s\n', ME.message);
    end
end

fprintf('\n');

%% ============================================================
%  STEP 7: SAVE RESULTS
%% ============================================================

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('STEP 7: Saving Results\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

try
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    save_filename = sprintf('ecg_results_%s_%s.mat', record_name, timestamp);
    save_path = fullfile(data_processed, save_filename);
    
    % Save all important variables
    save(save_path, 'record_name', 'raw_ecg', 'clean_ecg', 'filtered_ecg', ...
        'Fs', 'filter_info', 'r_locs', 'r_peaks', 'RR_intervals', 'HR', ...
        'ann_samples', 'ann_symbols', 'duration');
    
    [~, fname, ext] = fileparts(save_path);
    fprintf('✓ Results saved successfully\n');
    fprintf('  • File: %s%s\n', fname, ext);
    fprintf('  • Location: %s\n', data_processed);
    fprintf('  • Size: %.2f KB\n', dir(save_path).bytes/1024);
    
catch ME
    fprintf('⚠ WARNING: Failed to save results\n');
    fprintf('  Reason: %s\n', ME.message);
end

fprintf('\n');

%% ============================================================
%  FINAL SUMMARY
%% ============================================================

fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                   PROCESSING COMPLETE                      ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

fprintf(' SUMMARY:\n');
fprintf('  ✓ Data Loaded: Record %s (%.1fs)\n', record_name, duration);
fprintf('  ✓ Preprocessing: DC removal, baseline correction, normalization\n');
fprintf('  ✓ Filtering: 50Hz notch + 5-15Hz bandpass\n');
fprintf('  ✓ R-Peak Detection: %d peaks detected\n', length(r_locs));
if ~isempty(HR)
    fprintf('  ✓ Heart Rate: %.1f BPM (mean)\n', mean(HR));
end
fprintf('  ✓ Results saved to: %s\n', data_processed);
fprintf('\n');

fprintf(' Pipeline executed successfully!\n\n');
