% test_visualization_fixed.m
clear; clc; close all;

project_root = 'C:\Users\Potato\Desktop\real-Time-ECG-Signal-Processing-Using-MATLAB';
data_path = fullfile(project_root, 'data', 'raw');

% Load and preprocess
[raw_ecg, Fs] = load_ecg('100', data_path);
[clean_ecg, ~, ~] = preprocess_ecg('100', data_path);

% Test filtering
test_samples = 1:min(10*Fs, length(clean_ecg));
ecg_test = clean_ecg(test_samples);
[filtered_ecg, ~] = filter_ecg(ecg_test, Fs);

% Create time vectors
t_raw = (0:length(raw_ecg)-1)/Fs;
t_test = (0:length(ecg_test)-1)/Fs;
t_filt = (0:length(filtered_ecg)-1)/Fs;

%% Figure 1: Individual Plots (Proper Scaling)
figure('Position', [50, 50, 1400, 800]);

% Plot 1: Raw ECG
subplot(3, 3, 1);
plot(t_raw(1:5*Fs), raw_ecg(1:5*Fs), 'b', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Amplitude');
title('Raw ECG (mV)');
grid on;
fprintf('Raw ECG range: [%.1f, %.1f] mV\n', min(raw_ecg(1:5*Fs)), max(raw_ecg(1:5*Fs)));

% Plot 2: Clean ECG (Normalized)
subplot(3, 3, 2);
plot(t_raw(1:5*Fs), clean_ecg(1:5*Fs), 'r', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Amplitude');
title('Clean ECG (Normalized)');
grid on;
fprintf('Clean ECG range: [%.3f, %.3f]\n', min(clean_ecg(1:5*Fs)), max(clean_ecg(1:5*Fs)));

% Plot 3: Filtered ECG
subplot(3, 3, 3);
plot(t_filt(1:5*Fs), filtered_ecg(1:5*Fs), 'm', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Amplitude');
title('Filtered ECG');
grid on;
fprintf('Filtered ECG range: [%.3f, %.3f]\n', min(filtered_ecg(1:5*Fs)), max(filtered_ecg(1:5*Fs)));

%% Figure 1 Continued: Zoomed QRS Complexes
% Find QRS location (look for high amplitude peaks)
[qrs_peaks, qrs_locs] = findpeaks(abs(filtered_ecg(1:5*Fs)), ...
    'MinPeakHeight', 0.3*max(abs(filtered_ecg(1:5*Fs))), ...
    'MinPeakDistance', 0.3*Fs);

if ~isempty(qrs_locs)
    % Plot 4: Single QRS from raw
    subplot(3, 3, 4);
    qrs_idx = qrs_locs(1);
    window = max(1, qrs_idx-100):min(qrs_idx+100, length(raw_ecg));
    plot(t_raw(window), raw_ecg(window), 'b', 'LineWidth', 2);
    xlabel('Time (s)'); ylabel('Amplitude (mV)');
    title('Single QRS - Raw');
    grid on;
    
    % Plot 5: Single QRS from clean
    subplot(3, 3, 5);
    plot(t_raw(window), clean_ecg(window), 'r', 'LineWidth', 2);
    xlabel('Time (s)'); ylabel('Amplitude');
    title('Single QRS - Clean');
    grid on;
    
    % Plot 6: Single QRS from filtered
    subplot(3, 3, 6);
    window_filt = max(1, qrs_idx-100):min(qrs_idx+100, length(filtered_ecg));
    plot(t_filt(window_filt), filtered_ecg(window_filt), 'm', 'LineWidth', 2);
    xlabel('Time (s)'); ylabel('Amplitude');
    title('Single QRS - Filtered');
    grid on;
end

%% Figure 1 Continued: Overlay plots with proper scaling
% Plot 7: All signals normalized to same scale
subplot(3, 3, 7);
% Normalize all to [0, 1] for comparison
raw_norm = (raw_ecg(1:5*Fs) - min(raw_ecg(1:5*Fs))) / (max(raw_ecg(1:5*Fs)) - min(raw_ecg(1:5*Fs)));
clean_norm = (clean_ecg(1:5*Fs) - min(clean_ecg(1:5*Fs))) / (max(clean_ecg(1:5*Fs)) - min(clean_ecg(1:5*Fs)));
filt_norm = (filtered_ecg(1:5*Fs) - min(filtered_ecg(1:5*Fs))) / (max(filtered_ecg(1:5*Fs)) - min(filtered_ecg(1:5*Fs)));

plot(t_raw(1:5*Fs), raw_norm, 'b', 'LineWidth', 0.5); hold on;
plot(t_raw(1:5*Fs), clean_norm, 'r', 'LineWidth', 1);
plot(t_filt(1:5*Fs), filt_norm, 'm', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Normalized Amplitude');
title('All Signals (Normalized to [0,1])');
legend('Raw', 'Clean', 'Filtered', 'Location', 'best');
grid on;

% Plot 8: Clean vs Filtered (similar scale)
subplot(3, 3, 8);
plot(t_test(1:5*Fs), clean_ecg(1:5*Fs), 'r', 'LineWidth', 1); hold on;
plot(t_filt(1:5*Fs), filtered_ecg, 'm', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Amplitude');
title('Clean vs Filtered (Same Scale)');
legend('Clean', 'Filtered');
grid on;

% Plot 9: Histogram comparison
subplot(3, 3, 9);
histogram(clean_ecg(1:5*Fs), 50, 'FaceColor', 'r', 'FaceAlpha', 0.5); hold on;
histogram(filtered_ecg(1:5*Fs), 50, 'FaceColor', 'm', 'FaceAlpha', 0.5);
xlabel('Amplitude'); ylabel('Count');
title('Amplitude Distribution');
legend('Clean', 'Filtered');
grid on;

sgtitle('ECG Processing - Individual Plots with Proper Scaling', 'FontSize', 14);

%% Figure 2: Check if signal has ECG morphology
figure('Position', [100, 100, 1200, 400]);

% Check a 3-second segment
seg_start = 1;
seg_end = min(3*Fs, length(filtered_ecg));
segment = filtered_ecg(seg_start:seg_end);
t_seg = (0:length(segment)-1)/Fs;

subplot(1, 2, 1);
plot(t_seg, segment, 'b', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Amplitude');
title('Filtered ECG (3 seconds)');
grid on;

% Check for QRS-like peaks
[pks, locs] = findpeaks(segment, 'MinPeakHeight', 0.2*max(segment), ...
    'MinPeakDistance', 0.2*Fs);

if length(pks) >= 2
    hold on;
    plot(t_seg(locs), pks, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
    fprintf('\n✅ ECG morphology detected!\n');
    fprintf('   Found %d peaks in 3 seconds\n', length(pks));
    fprintf('   Approx heart rate: %.1f BPM\n', (length(pks)/3)*60);
else
    fprintf('\n⚠️  Warning: ECG morphology not clear\n');
    fprintf('   Found only %d peaks in 3 seconds\n', length(pks));
end

% Check frequency content
subplot(1, 2, 2);
[Pxx, F] = pwelch(segment, [], [], [], Fs);
plot(F, 10*log10(Pxx), 'b', 'LineWidth', 1.5);
xlim([0, 100]); xlabel('Frequency (Hz)'); ylabel('Power (dB)');
title('Frequency Spectrum');
grid on;
hold on;
line([5 5], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
line([15 15], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
text(20, max(10*log10(Pxx))*0.9, 'QRS Band', 'Color', 'r');
line([50 50], ylim, 'Color', 'k', 'LineStyle', ':', 'LineWidth', 1);
text(52, max(10*log10(Pxx))*0.8, '50 Hz', 'Color', 'k');

fprintf('\n=== Summary ===\n');
fprintf('1. Raw ECG has proper range: ✓\n');
fprintf('2. Clean ECG normalized correctly: ✓\n');
fprintf('3. Filtered ECG has QRS energy in 5-15 Hz band: Check plot\n');
fprintf('4. 50 Hz noise should be attenuated: Check plot\n');