% utils/plot_fft.m
function [freq, power] = plot_fft(signal, Fs, make_plot)
    % PLOT_FFT Calculate and optionally plot FFT
    
    if nargin < 3
        make_plot = true;
    end
    
    N = length(signal);
    Y = fft(signal);
    P2 = abs(Y/N);
    P1 = P2(1:floor(N/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    freq = Fs*(0:(N/2))/N;
    power = P1;
    
    if make_plot
        figure;
        plot(freq, 10*log10(power));
        xlabel('Frequency (Hz)');
        ylabel('Power (dB)');
        title('Frequency Spectrum');
        grid on;
        xlim([0, 100]);
    end
end