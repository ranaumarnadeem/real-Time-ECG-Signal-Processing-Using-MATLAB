function snr_db = calculate_snr(signal)
   
    noise_estimate = highpass(signal, 40, 360); 
    noise_estimate = noise_estimate(100:end-100);
    
    signal_power = var(signal);
    noise_power = var(noise_estimate);
    
    if noise_power == 0
        snr_db = Inf;
    else
        snr_db = 10 * log10(signal_power / noise_power);
    end
end