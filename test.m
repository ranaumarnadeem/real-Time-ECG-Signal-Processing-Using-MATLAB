clear; clc; close all;

% Test parameters
record_name = '100';
data_path = 'A:\5th semester\signal & syestem\real-Time-ECG-Signal-Processing-Using-MATLAB\data\raw';
addpath('A:\5th semester\signal & syestem\real-Time-ECG-Signal-Processing-Using-MATLAB\src\matlab');
addpath('A:\5th semester\signal & syestem\real-Time-ECG-Signal-Processing-Using-MATLAB\src\matlab\utils');

try
    fprintf('=== Testing ECG Preprocessing ===\n');
    
    % Run preprocessing pipeline
    [clean_ecg, original_ecg, Fs] = preprocess_ecg(record_name, data_path);
    
    % Create time vector
    t = (0:length(original_ecg)-1) / Fs;
    
    % Plot results
    figure('Position', [100, 100, 1200, 800]);
    
    % Subplot 1: Original vs Clean ECG
    subplot(2,2,1);
    plot(t, original_ecg, 'b', 'LineWidth', 1); hold on;
    plot(t, clean_ecg, 'r', 'LineWidth', 1.5);
    title('Original vs Preprocessed ECG');
    xlabel('Time (seconds)');
    ylabel('Amplitude');
    legend('Original', 'Preprocessed', 'Location', 'best');
    grid on;
    
    % Subplot 2: First 5 seconds (zoomed)
    subplot(2,2,2);
    zoom_samples = 1:min(5*Fs, length(original_ecg));
    plot(t(zoom_samples), original_ecg(zoom_samples), 'b', 'LineWidth', 1); hold on;
    plot(t(zoom_samples), clean_ecg(zoom_samples), 'r', 'LineWidth', 1.5);
    title('First 5 Seconds (Zoomed)');
    xlabel('Time (seconds)');
    ylabel('Amplitude');
    legend('Original', 'Preprocessed', 'Location', 'best');
    grid on;
    
    % Subplot 3: Histogram comparison
    subplot(2,2,3);
    histogram(original_ecg, 50, 'FaceColor', 'b', 'FaceAlpha', 0.7); hold on;
    histogram(clean_ecg, 50, 'FaceColor', 'r', 'FaceAlpha', 0.7);
    title('Amplitude Distribution');
    xlabel('Amplitude');
    ylabel('Frequency');
    legend('Original', 'Preprocessed');
    grid on;
    
    % Subplot 4: Statistical comparison
    subplot(2,2,4);
    stats_original = [mean(original_ecg), std(original_ecg), min(original_ecg), max(original_ecg)];
    stats_clean = [mean(clean_ecg), std(clean_ecg), min(clean_ecg), max(clean_ecg)];
    bar_matrix = [stats_original; stats_clean]';
    bar(bar_matrix);
    set(gca, 'XTickLabel', {'Mean', 'Std Dev', 'Min', 'Max'});
    title('Statistical Comparison');
    ylabel('Value');
    legend('Original', 'Preprocessed');
    grid on;
    
    fprintf('\n=== Preprocessing Test Complete ===\n');
    fprintf('Signal length: %d samples\n', length(clean_ecg));
    fprintf('Duration: %.2f seconds\n', length(clean_ecg)/Fs);

    %% -----------------------------
    %% R-PEAK DETECTION
    %% -----------------------------
    fprintf('\n=== Detecting R-Peaks ===\n');
    [r_locs, r_peaks] = r_peak_detection(clean_ecg, Fs);
    fprintf('Detected %d R-peaks.\n', length(r_locs));
    %% -----------------------------
%% P & T WAVE DETECTION
%% -----------------------------
fprintf('\n=== Detecting P and T Waves ===\n');

[P_locs, T_locs, P_peaks, T_peaks] = detect_p_t_waves(clean_ecg, r_locs, Fs);

fprintf('Detected %d P-waves and %d T-waves.\n', length(P_locs), length(T_locs));

% Plot on the same figure as R-peaks
figure('Name','P, QRS, and T Wave Detection','Position',[100 100 1100 400]);
plot(t, clean_ecg, 'b'); hold on;
scatter(r_locs/Fs, r_peaks, 40, 'r', 'filled');   % R-peaks
scatter(P_locs/Fs, P_peaks, 40, 'g', 'filled');   % P-waves
scatter(T_locs/Fs, T_peaks, 40, 'm', 'filled');   % T-waves
legend('Clean ECG','R-peaks','P-waves','T-waves');
xlabel('Time (s)'); ylabel('Amplitude');
title('Detected P, QRS, and T Waves');
grid on;

    

    % Plot R-peaks
    figure('Name','R-Peaks on Clean ECG','Position',[100 100 1000 400]);
    plot(t, clean_ecg, 'b'); hold on;
    scatter(r_locs/Fs, r_peaks, 40, 'r', 'filled');
    title('Detected R-Peaks');
    xlabel('Time (s)'); ylabel('Amplitude');
    grid on;

    %% -----------------------------
    %% RR INTERVALS & HEART RATE
    %% -----------------------------
    fprintf('\n=== Computing RR Intervals & Heart Rate ===\n');
    [RR_intervals, HR] = compute_rr_hr(r_locs, Fs);
    
    if ~isempty(RR_intervals)
        fprintf('Mean HR: %.2f BPM, Range: %.2f - %.2f BPM\n', mean(HR), min(HR), max(HR));
        
        figure('Name','RR Intervals & Heart Rate','Position',[100 100 1000 400]);
        subplot(1,2,1);
        plot(RR_intervals, 'b', 'LineWidth', 1.5); grid on;
        xlabel('Beat Number'); ylabel('RR Interval (s)'); title('RR Intervals');
        
        subplot(1,2,2);
        plot(HR, 'r', 'LineWidth', 1.5); grid on;
        xlabel('Beat Number'); ylabel('BPM'); title('Heart Rate');
    else
        fprintf('Not enough R-peaks to calculate HR.\n');
    end
    
catch ME
    fprintf('Error in preprocessing or R-peak detection: %s\n', ME.message);
end

