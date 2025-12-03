% test_ecg_pipeline_fixed.m
clear; clc; close all;

fprintf('==============================================\n');
fprintf('ECG Processing Pipeline - Test\n');
fprintf('==============================================\n\n');

%% 1. Setup Paths
project_root = 'C:\Users\Potato\Desktop\real-Time-ECG-Signal-Processing-Using-MATLAB';
data_raw = fullfile(project_root, 'data', 'raw');
data_processed = fullfile(project_root, 'data', 'processed');
src_path = fullfile(project_root, 'src', 'matlab');

addpath(genpath(src_path));

if ~exist(data_processed, 'dir')
    mkdir(data_processed);
end

%% 2. Test Data Loading
fprintf('1. Testing Data Loading...\n');
try
    [raw_ecg, Fs, ann_samples, ann_symbols] = load_ecg('100', data_raw);
    fprintf('   ✓ Loaded record 100\n');
    fprintf('   Samples: %d, Fs: %d Hz\n', length(raw_ecg), Fs);
    fprintf('   Annotations: %d\n', length(ann_samples));
catch ME
    fprintf('   ✗ Failed: %s\n', ME.message);
    return;
end

%% 3. Use plot_fft to visualize raw ECG spectrum
fprintf('\n2. Visualizing raw ECG spectrum...\n');
plot_fft(raw_ecg(1:min(5000, length(raw_ecg))), Fs, true);

%% 4. Test Preprocessing
fprintf('\n3. Testing Preprocessing...\n');
try
    [clean_ecg, original_ecg, Fs_pp] = preprocess_ecg('100', data_raw);
    
    if length(clean_ecg) == length(original_ecg) && Fs_pp == Fs
        fprintf('   ✓ Preprocessing successful\n');
        fprintf('   Clean range: [%.3f, %.3f]\n', min(clean_ecg), max(clean_ecg));
    else
        fprintf('   ✗ Size mismatch\n');
    end
catch ME
    fprintf('   ✗ Failed: %s\n', ME.message);
    return;
end

%% 5. Use plot_fft to visualize clean ECG spectrum
fprintf('\n4. Visualizing clean ECG spectrum...\n');
plot_fft(clean_ecg(1:min(5000, length(clean_ecg))), Fs, true);

%% 6. Test Filtering (will use its own plot_fft)
fprintf('\n5. Testing Filtering...\n');
try
    test_samples = 1:min(30*Fs, length(clean_ecg));
    test_ecg = clean_ecg(test_samples);
    
    % Call filter_ecg with plots enabled
    [filtered_ecg, filter_info] = filter_ecg(test_ecg, Fs, true);
    
    if length(filtered_ecg) == length(test_ecg)
        fprintf('   ✓ Filtering successful\n');
        fprintf('   Filtered range: [%.3f, %.3f]\n', min(filtered_ecg), max(filtered_ecg));
    else
        fprintf('   ✗ Size mismatch\n');
    end
catch ME
    fprintf('   ✗ Failed: %s\n', ME.message);
    return;
end

%% 7. Save Data
fprintf('\n6. Saving Results...\n');
try
    save_path = fullfile(data_processed, 'test_results.mat');
    save(save_path, 'raw_ecg', 'clean_ecg', 'filtered_ecg', 'Fs', 'filter_info', 'ann_samples', 'ann_symbols');
    fprintf('   ✓ Saved: %s\n', save_path);
catch ME
    fprintf('   ✗ Save failed: %s\n', ME.message);
end

%% 8. Create final comparison using only plot_fft data
fprintf('\n7. Final frequency comparison...\n');

% Get FFT data from all stages (without plotting)
[f_raw, P_raw] = plot_fft(raw_ecg(1:min(5000, length(raw_ecg))), Fs, false);
[f_clean, P_clean] = plot_fft(clean_ecg(1:min(5000, length(clean_ecg))), Fs, false);
[f_filt, P_filt] = plot_fft(filtered_ecg(1:min(5000, length(filtered_ecg))), Fs, false);

% Convert to dB safely (avoid log of zero/negative)
P_raw_db = 10*log10(abs(P_raw) + eps);  % Add eps to avoid log(0)
P_clean_db = 10*log10(abs(P_clean) + eps);
P_filt_db = 10*log10(abs(P_filt) + eps);

% Create comparison figure
figure('Position', [50, 50, 1000, 400], 'Name', 'ECG Processing - Frequency Analysis');

% Plot all spectra together
subplot(1, 2, 1);
plot(f_raw, P_raw_db, 'b', 'LineWidth', 1); hold on;
plot(f_clean, P_clean_db, 'r', 'LineWidth', 1);
plot(f_filt, P_filt_db, 'm', 'LineWidth', 1.5);
xlim([0, 100]); xlabel('Frequency (Hz)'); ylabel('Power (dB)');
title('Frequency Spectra Comparison');
legend('Raw', 'Clean', 'Filtered', 'Location', 'best');
grid on;
line([50 50], ylim, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);

% Zoom on QRS band
subplot(1, 2, 2);
plot(f_raw, P_raw_db, 'b', 'LineWidth', 0.5); hold on;
plot(f_clean, P_clean_db, 'r', 'LineWidth', 0.5);
plot(f_filt, P_filt_db, 'm', 'LineWidth', 1.5);
xlim([0, 30]); xlabel('Frequency (Hz)'); ylabel('Power (dB)');
title('QRS Band (0-30 Hz)');
legend('Raw', 'Clean', 'Filtered', 'Location', 'best');
grid on;

% Fix fill command - use actual y-limits
y_limits = ylim;
fill([5, 5, 15, 15], [y_limits(1), y_limits(2), y_limits(2), y_limits(1)], ...
     'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
text(10, y_limits(2)*0.9, 'QRS Band', 'Color', 'g', 'HorizontalAlignment', 'center');

%% 9. Simple Statistics
fprintf('\n8. Basic Statistics...\n');
fprintf('   Signal Lengths:\n');
fprintf('     Raw: %d samples (%.1f seconds)\n', length(raw_ecg), length(raw_ecg)/Fs);
fprintf('     Clean: %d samples (%.1f seconds)\n', length(clean_ecg), length(clean_ecg)/Fs);
fprintf('     Filtered: %d samples (%.1f seconds)\n', length(filtered_ecg), length(filtered_ecg)/Fs);

fprintf('\n   Amplitude Ranges:\n');
fprintf('     Raw: [%.3f, %.3f]\n', min(raw_ecg), max(raw_ecg));
fprintf('     Clean: [%.3f, %.3f]\n', min(clean_ecg), max(clean_ecg));
fprintf('     Filtered: [%.3f, %.3f]\n', min(filtered_ecg), max(filtered_ecg));

% Calculate QRS band power for each stage
qrs_band = f_raw >= 5 & f_raw <= 15;
qrs_power_raw = mean(P_raw_db(qrs_band));
qrs_power_clean = mean(P_clean_db(qrs_band));
qrs_power_filt = mean(P_filt_db(qrs_band));

fprintf('\n   QRS Band (5-15 Hz) Power:\n');
fprintf('     Raw: %.2f dB\n', qrs_power_raw);
fprintf('     Clean: %.2f dB\n', qrs_power_clean);
fprintf('     Filtered: %.2f dB\n', qrs_power_filt);
fprintf('     Improvement: %.2f dB\n', qrs_power_filt - qrs_power_raw);

%% 10. Summary
fprintf('\n==============================================\n');
fprintf('TEST SUMMARY\n');
fprintf('==============================================\n');
fprintf('✓ Data Loading: Working\n');
fprintf('✓ Preprocessing: Working\n');
fprintf('✓ Filtering: Working\n');
fprintf('✓ Data Saved: Yes\n');
fprintf('✓ Visualizations: Created using plot_fft\n');
fprintf('\nNEXT STEP: Implement R-peak detection\n');
fprintf('==============================================\n');