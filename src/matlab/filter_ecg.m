function [filtered_ecg, filters_info] = filter_ecg(ecg_signal, Fs, make_plots)
 
    
    if nargin < 3
        make_plots = true;
    end
    
    fprintf('=== ECG Filtering ===\n');
    
   
    if make_plots
        fprintf('Analyzing original signal...\n');
        plot_fft(ecg_signal, Fs, true);
    end
    
   
    fprintf('1. Removing 50 Hz noise...\n');
    ecg_no_50hz = remove_powerline_noise(ecg_signal, Fs);
    
   
    fprintf('2. Applying bandpass filter (5-15 Hz)...\n');
    filtered_ecg = apply_bandpass_filter(ecg_no_50hz, Fs);
    
  
    if make_plots
        fprintf('Analyzing filtered signal...\n');
        plot_fft(filtered_ecg, Fs, true);
    end
    
  
    filters_info = struct();
    filters_info.Fs = Fs;
    filters_info.filter_steps = {'50Hz_notch', '5-15Hz_bandpass'};
    
    fprintf('Filtering complete!\n');
end