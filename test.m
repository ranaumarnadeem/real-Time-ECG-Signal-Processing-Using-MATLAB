clear; clc; close all;

%% ================================
%  PATHS & PARAMETERS
%  ================================
record_name = '100';
data_path = 'A:\5th semester\signal & syestem\real-Time-ECG-Signal-Processing-Using-MATLAB\data\raw';

addpath('A:\5th semester\signal & syestem\real-Time-ECG-Signal-Processing-Using-MATLAB\src\matlab');
addpath('A:\5th semester\signal & syestem\real-Time-ECG-Signal-Processing-Using-MATLAB\src\matlab\utils');

try
    fprintf("=== ECG Processing Test ===\n");

    %% ================================
    %  PREPROCESSING
    %  ================================
    [clean_ecg, original_ecg, Fs] = preprocess_ecg(record_name, data_path);
    t = (0:length(original_ecg)-1) / Fs;

    %% ================================
    %  ORIGINAL VS CLEAN PLOTS
    %  ================================
    figure('Position',[100 100 1200 800]);

    subplot(2,2,1);
    plot(t, original_ecg, 'b'); hold on;
    plot(t, clean_ecg, 'r');
    title('Original vs Preprocessed ECG'); grid on;
    legend('Original','Cleaned');

    subplot(2,2,2);
    zoom_samples = 1:min(5*Fs, length(clean_ecg));
    plot(t(zoom_samples), original_ecg(zoom_samples),'b'); hold on;
    plot(t(zoom_samples), clean_ecg(zoom_samples),'r');
    title('Zoom: First 5 seconds'); grid on;

    subplot(2,2,3);
    histogram(original_ecg,50,'FaceColor','b'); hold on;
    histogram(clean_ecg,50,'FaceColor','r');
    title('Amplitude Distribution'); grid on;
    legend('Original','Cleaned');

    subplot(2,2,4);
    stats_original = [mean(original_ecg), std(original_ecg), min(original_ecg), max(original_ecg)];
    stats_clean = [mean(clean_ecg), std(clean_ecg), min(clean_ecg), max(clean_ecg)];
    bar([stats_original; stats_clean]');
    set(gca,'XTickLabel',{'Mean','Std','Min','Max'});
    title('Statistical Comparison'); grid on;
    legend('Original','Clean');

    %% ================================
    %  R-PEAK DETECTION
    %  ================================
    fprintf("\n=== Detecting R-peaks ===\n");
    [r_locs, r_peaks] = r_peak_detection(clean_ecg, Fs);
    fprintf("R-peaks detected: %d\n", length(r_locs));

    %% ================================
    %  SINGLE R-WAVE SEGMENT (ZOOMED)
    %  ================================
    if ~isempty(r_locs)
        sample_index = r_locs(1);  % take first R-peak
        pre_samples  = round(0.20 * Fs);   % 200 ms before
        post_samples = round(0.30 * Fs);   % 300 ms after

        start_idx = max(1, sample_index - pre_samples);
        end_idx   = min(length(clean_ecg), sample_index + post_samples);

        r_sample_ecg = clean_ecg(start_idx:end_idx);
        r_sample_t = (start_idx:end_idx) / Fs;

        figure('Name','Single R-wave Segment','Position',[200 200 900 350]);
        plot(r_sample_t, r_sample_ecg,'b','LineWidth',1.5); hold on;
        scatter(sample_index/Fs, clean_ecg(sample_index),50,'r','filled');
        title('Zoomed R-wave Segment (Single Beat)');
        xlabel('Time (s)'); ylabel('Amplitude'); grid on;
    end

    %% ================================
    %  P & T WAVE DETECTION
    %  ================================
    fprintf("\n=== Detecting P & T Waves ===\n");
    [P_locs, T_locs, P_peaks, T_peaks] = detect_p_t_waves(clean_ecg, r_locs, Fs);
    fprintf("P detected: %d\n", length(P_locs));
    fprintf("T detected: %d\n", length(T_locs));

    %% ================================
    %  SEPARATED SIGNALS (P, R, T)
    %  ================================
    P_signal = zeros(size(clean_ecg));  P_signal(P_locs) = P_peaks;
    R_signal = zeros(size(clean_ecg));  R_signal(r_locs) = r_peaks;
    T_signal = zeros(size(clean_ecg));  T_signal(T_locs) = T_peaks;

    %% ================================
    %  PLOT SEPARATED P, R, T PEAKS
    %  ================================
    figure('Name','Separated P, R, T Peaks','Position',[100 100 1200 600]);

    subplot(3,1,1);
    stem(P_locs/Fs, P_peaks,'g','filled');
    title('P-wave Peaks'); ylabel('Amplitude'); grid on;

    subplot(3,1,2);
    stem(r_locs/Fs, r_peaks,'r','filled');
    title('R-wave Peaks'); ylabel('Amplitude'); grid on;

    subplot(3,1,3);
    stem(T_locs/Fs, T_peaks,'m','filled');
    title('T-wave Peaks'); xlabel('Time (s)'); ylabel('Amplitude'); grid on;

    %% ================================
    %  P, R, T ON FULL ECG
    %  ================================
    figure('Name','P, R, T Over ECG','Position',[100 100 1100 400]);
    plot(t, clean_ecg,'b'); hold on;
    scatter(r_locs/Fs, r_peaks, 40,'r','filled');
    scatter(P_locs/Fs, P_peaks, 40,'g','filled');
    scatter(T_locs/Fs, T_peaks, 40,'m','filled');
    legend('Clean ECG','R','P','T');
    title('Detected P, R, T Waves'); grid on;

    %% ================================
    %  RR INTERVALS & HEART RATE
    %  ================================
    fprintf("\n=== Computing RR Intervals & Heart Rate ===\n");
    [RR_intervals, HR] = compute_rr_hr(r_locs, Fs);

    if ~isempty(RR_intervals)
        fprintf("Mean HR: %.2f BPM\n", mean(HR));

        figure('Name','RR Intervals & HR','Position',[100 100 1000 400]);

        subplot(1,2,1);
        plot(RR_intervals,'b','LineWidth',1.5);
        title('RR Intervals'); xlabel('Beat'); ylabel('Seconds'); grid on;

        subplot(1,2,2);
        plot(HR,'r','LineWidth',1.5);
        title('Heart Rate'); xlabel('Beat'); ylabel('BPM'); grid on;
    else
        fprintf("Not enough R-peaks to calculate HR.\n");
    end

catch ME
    fprintf("Error: %s\n", ME.message);
end

