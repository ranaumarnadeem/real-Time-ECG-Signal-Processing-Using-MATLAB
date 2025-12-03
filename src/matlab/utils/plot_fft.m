function [freq, power_db] = plot_fft(signal, Fs, make_plot)
    % SIMPLE FFT for ECG
    
    if nargin < 3
        make_plot = true;
    end
    
    N = length(signal);
    Y = fft(signal);
    P2 = abs(Y/N);
    P1 = P2(1:floor(N/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    freq = Fs*(0:(N/2))/N;
    power_linear = P1;
    power_db = 10*log10(power_linear);
    
    if make_plot
        figure;
        
        % Main plot
        subplot(1, 2, 1);
        plot(freq, power_db, 'b', 'LineWidth', 1.5);
        xlabel('Frequency (Hz)');
        ylabel('Power (dB)');
        title('ECG Frequency Spectrum');
        grid on;
        xlim([0, 100]);
        
        % Mark 50 Hz
        line([50, 50], ylim, 'Color', 'r', 'LineStyle', '--');
        text(52, max(power_db)*0.9, '50 Hz', 'Color', 'r');
        
        % Zoomed plot for QRS band
        subplot(1, 2, 2);
        plot(freq, power_db, 'r', 'LineWidth', 1.5);
        xlabel('Frequency (Hz)');
        ylabel('Power (dB)');
        title('QRS Band (0-30 Hz)');
        grid on;
        xlim([0, 30]);
        
        % Mark QRS band
        fill([5, 5, 15, 15], [min(power_db), max(power_db), max(power_db), min(power_db)], ...
             'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
        text(10, max(power_db)*0.9, 'QRS Band', 'Color', 'g', ...
             'HorizontalAlignment', 'center');
    end
end