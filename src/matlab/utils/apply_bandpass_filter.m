function filtered_signal = apply_bandpass_filter(signal, Fs)
  
    low_cutoff = 5; 
    high_cutoff = 15; 
    filter_order = 4;
    
   
    [b, a] = butter(filter_order, [low_cutoff, high_cutoff]/(Fs/2), 'bandpass');
    
    filtered_signal = filtfilt(b, a, signal);
    
    fprintf('    Bandpass filter: [%.1f-%.1f] Hz, Order=%d\n', ...
            low_cutoff, high_cutoff, filter_order);
end