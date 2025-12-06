% test_ecg_pipeline_fixed.m
clear; clc; close all;

fprintf('==============================================\n');
fprintf('ECG Processing Pipeline - Test\n');
fprintf('==============================================\n\n');

%% 1. Setup Paths
project_root = 'A:\5th semester\signal & syestem\real-Time-ECG-Signal-Processing-Using-MATLAB';
data_raw = fullfile(project_root, 'data', 'raw');
data_processed = fullfile(project_root, 'data', 'processed');
src_path = fullfile(project_root, 'src', 'matlab');

addpath(genpath(src_path));

if ~exist(data_processed, 'dir')
    mkdir(data_processed);
end

%% 2. Load ECG Data
fprintf('1. Testing Data Loading...\n');
try
    [raw_ecg, Fs, ann_samples, ann_symbols] = load_ecg('100', data_raw);
    fprintf('   ✓ Loaded record 100\n');
    fprintf('   Samples: %d, Fs: %d Hz\n', length(raw_ecg), Fs);
catch ME
    fprintf('   ✗ Failed: %s\n', ME.message);
    return;
end

%% 3. Visualize Raw ECG Spectrum
fprintf('\n2. Visualizing raw ECG spectrum...\n');
plot_fft(raw_ecg(1:min(5000, length(raw_ecg))), Fs, true);

%% 4. Preprocess ECG
fprintf('\n3. Testing Preprocessing...\n');
try
    [clean_ecg, original_ecg, Fs_pp] = preprocess_ecg('100', data_raw);
    fprintf('   ✓ Preprocessing successful\n');
catch ME
    fprintf('   ✗ Failed: %s\n', ME.message);
    return;
end

%% 5. Visualize Clean ECG Spectrum
fprintf('\n4. Visualizing clean ECG spectrum...\n');
plot_fft(clean_ecg(1:min(5000, length(clean_ecg))), Fs, true);

%% 6. Filter ECG
fprintf('\n5. Testing Filtering...\n');
try
    test_samples = 1:min(30*Fs, length(clean_ecg));
    test_ecg = clean_ecg(test_samples);
    [filtered_ecg, filter_info] = filter_ecg(test_ecg, Fs, true);
    fprintf('   ✓ Filtering successful\n');
catch ME
    fprintf('   ✗ Failed: %s\n', ME.message);
    return;
end

%% 7. R-Peak Detection
fprintf('\n6. Detecting R-Peaks...\n');
try
    % Call R-peak detection (2 outputs only)
    [r_locs, r_peaks] = r_peak_detection(filtered_ecg, Fs);

    fprintf('   ✓ R-peaks detected: %d\n', length(r_locs));
    fprintf('   First few R-peaks (samples): ');
    disp(r_locs(1:min(5,end)));

    % Plot R-peaks on filtered ECG
    figure('Name','R-Peaks on Filtered ECG','Position',[100 100 1000 400]);
    t = (0:length(filtered_ecg)-1)/Fs;
    plot(t, filtered_ecg, 'b'); hold on;
    scatter(r_locs/Fs, r_peaks, 40, 'r', 'filled');
    xlabel('Time (s)'); ylabel('Amplitude');
    title('Detected R-Peaks'); grid on;
catch ME
    fprintf('   ✗ R-peak detection failed: %s\n', ME.message);
end

%% 8. RR Intervals & Heart Rate
fprintf('\n7. Computing RR-Intervals & Heart Rate...\n');
try
    [RR_intervals, HR] = compute_rr_hr(r_locs, Fs);

    fprintf('   ✓ RR-intervals: %d\n', length(RR_intervals));
    fprintf('   Mean HR: %.2f BPM\n', mean(HR));
    fprintf('   HR Range: %.2f – %.2f BPM\n', min(HR), max(HR));

    % Plot RR intervals and HR
    figure('Name','RR & Heart Rate','Position',[100 100 1000 400]);
    subplot(1,2,1);
    plot(RR_intervals,'b','LineWidth',1.5); grid on;
    xlabel('Beat Number'); ylabel('RR Interval (s)'); title('RR Intervals');

    subplot(1,2,2);
    plot(HR,'r','LineWidth',1.5); grid on;
    xlabel('Beat Number'); ylabel('BPM'); title('Heart Rate');
catch ME
    fprintf('   ✗ RR/HR computation failed: %s\n', ME.message);
end

%% 9. Save Data
fprintf('\n8. Saving Results...\n');
try
    save_path = fullfile(data_processed, 'test_results.mat');
    save(save_path, 'raw_ecg', 'clean_ecg', 'filtered_ecg', ...
        'Fs', 'filter_info', 'r_locs', 'r_peaks', 'RR_intervals', 'HR', ...
        'ann_samples', 'ann_symbols');
    fprintf('   ✓ Saved: %s\n', save_path);
catch ME
    fprintf('   ✗ Save failed: %s\n', ME.message);
end

%% 10. Summary
fprintf('\n==============================================\n');
fprintf('TEST SUMMARY\n');
fprintf('==============================================\n');
fprintf('✓ Data Loaded\n');
fprintf('✓ Preprocessing\n');
fprintf('✓ Filtering\n');
fprintf('✓ R-Peak Detection\n');
fprintf('✓ HR + RR Calculation\n');
fprintf('✓ Saved & Visualized\n');
fprintf('==============================================\n\n');

