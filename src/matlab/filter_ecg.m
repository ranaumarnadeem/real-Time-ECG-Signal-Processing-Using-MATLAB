function [filtered_ecg, filters_info] = filter_ecg(ecg_signal, Fs)
 
    fprintf('ECG Filtering');
    
    % Store intermediate signals for analysis
    intermediate_signals = struct();
    
   
    fprintf('1. Removing powerline interference (50 Hz)...\n');
    ecg_no_pl = remove_powerline_noise(ecg_signal, Fs);
    intermediate_signals.after_notch = ecg_no_pl;
    
    %% Applying Bandpass Filter (5-15 Hz for QRS enhancement)
    fprintf('2. Applying bandpass filter (5-15 Hz)...\n');
    ecg_bandpass = apply_bandpass_filter(ecg_no_pl, Fs);
    intermediate_signals.after_bandpass = ecg_bandpass;
    
    
    %% Store filter information
    filters_info = struct();
    filters_info.Fs = Fs;
    filters_info.intermediate_signals = intermediate_signals;
    filters_info.filter_types = {'Notch (50 Hz)', 'Bandpass (5-15 Hz)', 'Smoothing'};
    
    fprintf('Filtering complete!\n');
    fprintf('Signal improvement metrics:\n');
    fprintf('  Original SNR: %.2f dB\n', calculate_snr(ecg_signal));
    fprintf('  Filtered SNR: %.2f dB\n', calculate_snr(filtered_ecg));
    
    % Visualize filtering results
    visualize_filtering_results(ecg_signal, filtered_ecg, intermediate_signals, Fs);
end