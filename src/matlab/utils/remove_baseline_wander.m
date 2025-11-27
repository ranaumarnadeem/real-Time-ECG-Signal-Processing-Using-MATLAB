function filtered_ecg = remove_baseline_wander(ecg_signal, Fs)

    
    cutoff_freq = 0.5; 
    filter_order = 4;
    

    [b, a] = butter(filter_order, cutoff_freq/(Fs/2), 'high');
    
    % zero phase filtering
    filtered_ecg = filtfilt(b, a, ecg_signal);
    
    fprintf('  Baseline removal: Cutoff=%.1f Hz, Order=%d\n', cutoff_freq, filter_order);
end