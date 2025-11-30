% test_preprocess.m
clear; clc; close all;

% Test parameters
record_name = '100';
data_path = 'C:\Users\Potato\Desktop\real-Time-ECG-Signal-Processing-Using-MATLAB\data\raw';

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
    
catch ME
    fprintf('Error in preprocessing test: %s\n', ME.message);
end