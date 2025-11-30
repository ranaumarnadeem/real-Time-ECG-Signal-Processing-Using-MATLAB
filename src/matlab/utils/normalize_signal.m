function normalized_signal = normalize_signal(signal)
    % NORMALIZE_SIGNAL Normalize signal to range [-1, 1] or zero-mean/unit-variance
    
    method = 'range'; % Options: 'range', 'zscore'
    
    switch method
        case 'range'
            % Normalize to range [-1, 1]
            max_val = max(abs(signal));
            if max_val > 0
                normalized_signal = signal / max_val;
            else
                normalized_signal = signal;
            end
            
        case 'zscore'
            % Zero-mean, unit variance
            normalized_signal = (signal - mean(signal)) / std(signal);
            
        otherwise
            normalized_signal = signal;
    end
    
    fprintf('  Normalization method: %s\n', method);
end