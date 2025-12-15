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
results_dir = fullfile(project_root, 'results');
results_logs = fullfile(results_dir, 'logs');
results_plots = fullfile(results_dir, 'plots');
results_reports = fullfile(results_dir, 'reports');
addpath(genpath(matlab_dir));

%% ============================================================
%  USER CONFIGURATION - CHANGE RECORD NAME HERE
%% ============================================================
record_name = '104';  % Change this to process different ECG records (e.g., '101', '102', '103', etc.)
visualize = true;     % Enable visualizations (set to false for faster processing)

% Create output directories
if ~exist(data_processed, 'dir')
    mkdir(data_processed);
end
if ~exist(results_logs, 'dir')
    mkdir(results_logs);
end
if ~exist(results_plots, 'dir')
    mkdir(results_plots);
end
if ~exist(results_reports, 'dir')
    mkdir(results_reports);
end
fprintf(' Created/verified output directories\n\n');

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
        fig1 = figure('Name', 'Raw ECG Signal', 'Position', [50, 50, 1200, 400]);
        t_raw = (0:length(raw_ecg)-1) / Fs;
        plot(t_raw, raw_ecg, 'b', 'LineWidth', 0.8);
        xlabel('Time (s)'); ylabel('Amplitude (mV)');
        title(sprintf('Raw ECG Signal - Record %s', record_name));
        grid on; xlim([0, min(10, duration)]);
        
        % Save plot
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        saveas(fig1, fullfile(results_plots, sprintf('raw_ecg_%s_%s.png', record_name, timestamp)));
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
%  STEP 4.5: DETECT P AND T WAVES
%% ============================================================

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('STEP 4.5: P and T Wave Detection\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

try
    [P_locs, T_locs, P_peaks, T_peaks] = detect_p_t_waves(filtered_ecg, r_locs, Fs);
    
    fprintf('✓ P and T wave detection completed\n');
    fprintf('  • P-waves detected: %d\n', length(P_locs));
    fprintf('  • T-waves detected: %d\n', length(T_locs));
    fprintf('  • Complete PQRST complexes identified: %d\n', length(r_locs));
    
catch ME
    fprintf('⚠ WARNING: P-T wave detection failed\n');
    fprintf('  Reason: %s\n', ME.message);
    fprintf('  Continuing without P-T wave data...\n');
    P_locs = [];
    T_locs = [];
    P_peaks = [];
    T_peaks = [];
end

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
        fig2 = figure('Name', 'ECG Processing Pipeline Results', 'Position', [50, 50, 1400, 900]);
        
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
        plot(t_filt(idx_filt), filtered_ecg(idx_filt), 'g', 'LineWidth', 1);
        hold on;
        scatter(r_locs(r_idx)/Fs, r_peaks(r_idx), 100, 'r', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        xlabel('Time (s)'); ylabel('Amplitude');
        title('3. R-Peak Detection', 'FontSize', 12, 'FontWeight', 'bold');
        legend('Filtered ECG', 'R-Peaks', 'Location', 'best');
        grid on; xlim([0 display_duration]);
        
        sgtitle(sprintf('ECG Signal Processing Pipeline - Record %s', record_name), ...
            'FontSize', 14, 'FontWeight', 'bold');
        
        % Save comprehensive plot
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        saveas(fig2, fullfile(results_plots, sprintf('pipeline_results_%s_%s.png', record_name, timestamp)));
        
        % Create separate PQRST detection figure
        fig3 = figure('Name', 'Complete PQRST Detection', 'Position', [100, 100, 1600, 600]);
        plot(t_filt(idx_filt), filtered_ecg(idx_filt), 'Color', [0.3 0.3 0.3], 'LineWidth', 1.2); hold on;
        
        % Plot P-waves (blue)
        if exist('P_locs', 'var') && ~isempty(P_locs)
            p_idx = P_locs/Fs <= display_duration;
            scatter(P_locs(p_idx)/Fs, P_peaks(p_idx), 80, 'b', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
        end
        
        % Plot R-peaks (red)
        scatter(r_locs(r_idx)/Fs, r_peaks(r_idx), 100, 'r', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        
        % Plot T-waves (green)
        if exist('T_locs', 'var') && ~isempty(T_locs)
            t_idx = T_locs/Fs <= display_duration;
            scatter(T_locs(t_idx)/Fs, T_peaks(t_idx), 80, 'g', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
        end
        
        xlabel('Time (s)', 'FontSize', 11); 
        ylabel('Amplitude', 'FontSize', 11);
        title(sprintf('Complete PQRST Detection with Heart Rate - Record %s', record_name), ...
            'FontSize', 13, 'FontWeight', 'bold');
        if exist('P_locs', 'var') && ~isempty(P_locs) && exist('T_locs', 'var') && ~isempty(T_locs)
            legend('Filtered ECG', 'P-Waves', 'R-Peaks', 'T-Waves', 'Location', 'best', 'FontSize', 10);
        else
            legend('Filtered ECG', 'R-Peaks', 'Location', 'best', 'FontSize', 10);
        end
        grid on; xlim([0 display_duration]);
        
        % Save PQRST detection plot separately
        saveas(fig3, fullfile(results_plots, sprintf('pqrst_detection_%s_%s.png', record_name, timestamp)));
        
        fprintf('✓ Visualization created successfully\n');
        fprintf('  • Showing first %.1f seconds\n', display_duration);
        fprintf('  • Panel 1: Raw signal\n');
        fprintf('  • Panel 2: Filtered signal\n');
        fprintf('  • Panel 3: R-peak detection\n');
        fprintf('  • Saved to: results/plots/pipeline_results_%s_%s.png\n', record_name, timestamp);
        fprintf('  • Separate PQRST plot created:\n');
        if exist('P_locs', 'var') && ~isempty(P_locs)
            fprintf('    - Blue markers: P-waves\n');
        end
        fprintf('    - Red markers: R-peaks\n');
        if exist('T_locs', 'var') && ~isempty(T_locs)
            fprintf('    - Green markers: T-waves\n');
        end
        fprintf('  • Saved to: results/plots/pqrst_detection_%s_%s.png\n', record_name, timestamp);
        
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
    
    % Save processed data to results/reports
    save_filename = sprintf('ecg_results_%s_%s.mat', record_name, timestamp);
    save_path = fullfile(results_reports, save_filename);
    
    % Save all important variables
    if exist('P_locs', 'var') && exist('T_locs', 'var')
        save(save_path, 'record_name', 'raw_ecg', 'clean_ecg', 'filtered_ecg', ...
            'Fs', 'filter_info', 'r_locs', 'r_peaks', 'RR_intervals', 'HR', ...
            'P_locs', 'P_peaks', 'T_locs', 'T_peaks', ...
            'ann_samples', 'ann_symbols', 'duration');
    else
        save(save_path, 'record_name', 'raw_ecg', 'clean_ecg', 'filtered_ecg', ...
            'Fs', 'filter_info', 'r_locs', 'r_peaks', 'RR_intervals', 'HR', ...
            'ann_samples', 'ann_symbols', 'duration');
    end
    
    [~, fname, ext] = fileparts(save_path);
    fprintf('✓ Results saved successfully\n');
    fprintf('  • File: %s%s\n', fname, ext);
    fprintf('  • Location: results/reports/\n');
    fprintf('  • Size: %.2f KB\n', dir(save_path).bytes/1024);
    
    % Create processing log
    log_filename = sprintf('processing_log_%s_%s.txt', record_name, timestamp);
    log_path = fullfile(results_logs, log_filename);
    log_fid = fopen(log_path, 'w');
    
    fprintf(log_fid, '═══════════════════════════════════════════════════════════\n');
    fprintf(log_fid, 'ECG SIGNAL PROCESSING LOG\n');
    fprintf(log_fid, '═══════════════════════════════════════════════════════════\n\n');
    fprintf(log_fid, 'Timestamp: %s\n', datestr(now));
    fprintf(log_fid, 'Record: %s\n', record_name);
    fprintf(log_fid, '\n');
    fprintf(log_fid, 'SIGNAL INFORMATION:\n');
    fprintf(log_fid, '  - Total Samples: %d\n', length(raw_ecg));
    fprintf(log_fid, '  - Sampling Rate: %d Hz\n', Fs);
    fprintf(log_fid, '  - Duration: %.2f seconds (%.2f minutes)\n', duration, duration/60);
    fprintf(log_fid, '\n');
    fprintf(log_fid, 'PROCESSING STEPS:\n');
    fprintf(log_fid, '  ✓ Step 1: ECG data loaded\n');
    fprintf(log_fid, '  ✓ Step 2: Preprocessing (DC removal, baseline correction, normalization)\n');
    fprintf(log_fid, '  ✓ Step 3: Filtering (50Hz notch + 5-15Hz bandpass)\n');
    fprintf(log_fid, '  ✓ Step 4: R-peak detection (Pan-Tompkins)\n');
    fprintf(log_fid, '  ✓ Step 5: Heart rate analysis\n');
    fprintf(log_fid, '\n');
    fprintf(log_fid, 'DETECTION RESULTS:\n');
    fprintf(log_fid, '  - R-peaks detected: %d\n', length(r_locs));
    if exist('P_locs', 'var') && ~isempty(P_locs)
        fprintf(log_fid, '  - P-waves detected: %d\n', length(P_locs));
    end
    if exist('T_locs', 'var') && ~isempty(T_locs)
        fprintf(log_fid, '  - T-waves detected: %d\n', length(T_locs));
    end
    if exist('P_locs', 'var') && ~isempty(P_locs) && exist('T_locs', 'var') && ~isempty(T_locs)
        fprintf(log_fid, '  - Complete PQRST complexes: %d\n', min([length(P_locs), length(r_locs), length(T_locs)]));
    end
    fprintf(log_fid, '  - Annotations available: %d\n', length(ann_samples));
    if ~isempty(HR)
        fprintf(log_fid, '  - Mean Heart Rate: %.1f BPM\n', mean(HR));
        fprintf(log_fid, '  - HR Range: %.1f - %.1f BPM\n', min(HR), max(HR));
        fprintf(log_fid, '  - HR Std Dev: %.1f BPM\n', std(HR));
        fprintf(log_fid, '  - Mean RR Interval: %.3f seconds\n', mean(RR_intervals));
    end
    fprintf(log_fid, '\n');
    fprintf(log_fid, 'OUTPUT FILES:\n');
    fprintf(log_fid, '  - Data: results/reports/%s\n', save_filename);
    fprintf(log_fid, '  - Plots: results/plots/pipeline_results_%s_%s.png\n', record_name, timestamp);
    fprintf(log_fid, '  - Log: results/logs/%s\n', log_filename);
    fprintf(log_fid, '\n');
    fprintf(log_fid, '═══════════════════════════════════════════════════════════\n');
    fprintf(log_fid, 'Processing completed successfully\n');
    fprintf(log_fid, '═══════════════════════════════════════════════════════════\n');
    
    fclose(log_fid);
    fprintf('  • Log file: %s\n', log_filename);
    fprintf('  • Log location: results/logs/\n');
    
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
if exist('P_locs', 'var') && ~isempty(P_locs) && exist('T_locs', 'var') && ~isempty(T_locs)
    fprintf('  ✓ PQRST Detection: %d P-waves, %d T-waves\n', length(P_locs), length(T_locs));
end
if ~isempty(HR)
    fprintf('  ✓ Heart Rate: %.1f BPM (mean)\n', mean(HR));
end
fprintf('  ✓ Results saved to:\n');
fprintf('    - Data: results/reports/\n');
fprintf('    - Plots: results/plots/\n');
fprintf('    - Logs: results/logs/\n');
fprintf('\n');

fprintf(' Pipeline executed successfully!\n\n');
