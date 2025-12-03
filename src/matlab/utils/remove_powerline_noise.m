function filtered_signal = remove_powerline_noise(signal, Fs)
    
    fprintf('    Removing 50 Hz powerline interference...\n');
    
    powerline_freq = 50;  
    
    try
        
        if exist('designNotchPeakIIR', 'file') == 2
          
            notchSpec = fdesign.notch('N,F0,Q', 2, powerline_freq, 35, Fs);
            notchFilt = design(notchSpec);
            [b, a] = tf(notchFilt);
            fprintf('      Using designNotchPeakIIR: %.0f Hz\n', powerline_freq);
        else
          
            fprintf('      Using butterworth bandstop filter...\n');
            [b, a] = butter(2, [48, 52]/(Fs/2), 'stop');
        end
    catch ME
        fprintf('      Error designing notch filter: %s\n', ME.message);
        fprintf('      Using simple bandstop instead...\n');
        [b, a] = butter(2, [49, 51]/(Fs/2), 'stop');
    end
    
  
    filtered_signal = filtfilt(b, a, signal);
    
    fprintf('      50 Hz noise removed successfully\n');
end