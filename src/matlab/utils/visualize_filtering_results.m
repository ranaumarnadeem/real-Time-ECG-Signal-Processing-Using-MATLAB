function visualize_filtering_results(original_signal, filtered_signal, intermediate, Fs)
  
    t = (0:length(original_signal)-1) / Fs;
    
    
    figure('Position', [100, 100, 1400, 900]);
    
    % Plot 1: Original vs Final Filtered
    subplot(3, 3, [1, 2]);
    plot(t, original_signal, 'b', 'LineWidth', 1); hold on;
    plot(t, filtered_signal, 'r', 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Amplitude');
    title('Original vs Fully Filtered ECG');
    legend('Original', 'Filtered');
    grid on;
    
    % Plot 2: Zoomed view (first 5 seconds)
    subplot(3, 3, 3);
    zoom_samples = 1:min(5*Fs, length(original_signal));
    plot(t(zoom_samples), original_signal(zoom_samples), 'b'); hold on;
    plot(t(zoom_samples), filtered_signal(zoom_samples), 'r');
    xlabel('Time (s)');
    title('Zoomed (First 5s)');
    grid on;
    
    % Plot 3: After notch filter
    if isfield(intermediate, 'after_notch')
        subplot(3, 3, 4);
        plot(t, intermediate.after_notch, 'g');
        xlabel('Time (s)');
        title('After Notch Filter (50 Hz removed)');
        grid on;
    end
    
    % Plot 4: After bandpass filter
    if isfield(intermediate, 'after_bandpass')
        subplot(3, 3, 5);
        plot(t, intermediate.after_bandpass, 'm');
        xlabel('Time (s)');
        title('After Bandpass Filter (5-15 Hz)');
        grid on;
    end
    
    % Plot 5: Frequency spectrum comparison
    subplot(3, 3, 6);
    [f_orig, P_orig] = plot_fft(original_signal, Fs, false);
    [f_filt, P_filt] = plot_fft(filtered_signal, Fs, false);
    plot(f_orig, 10*log10(P_orig), 'b'); hold on;
    plot(f_filt, 10*log10(P_filt), 'r');
    xlim([0, 100]);
    xlabel('Frequency (Hz)');
    ylabel('Power (dB)');
    title('Frequency Spectrum');
    legend('Original', 'Filtered');
    grid on;
    
    % Plot 6: Histogram comparison
    subplot(3, 3, 7);
    histogram(original_signal, 50, 'FaceColor', 'b', 'FaceAlpha', 0.5); hold on;
    histogram(filtered_signal, 50, 'FaceColor', 'r', 'FaceAlpha', 0.5);
    xlabel('Amplitude');
    ylabel('Count');
    title('Amplitude Distribution');
    legend('Original', 'Filtered');
    grid on;
    
    % Plot 7: Signal statistics
    subplot(3, 3, 8);
    stats_orig = [mean(original_signal), std(original_signal), ...
                  min(original_signal), max(original_signal)];
    stats_filt = [mean(filtered_signal), std(filtered_signal), ...
                  min(filtered_signal), max(filtered_signal)];
    
    bar([stats_orig; stats_filt]');
    set(gca, 'XTickLabel', {'Mean', 'Std', 'Min', 'Max'});
    title('Signal Statistics');
    legend('Original', 'Filtered');
    grid on;
    
    % Plot 8: Filter frequency responses (simplified)
    subplot(3, 3, 9);
    plot_filter_responses(Fs);
    title('Filter Frequency Responses');
    grid on;
    
    sgtitle('ECG Filtering Analysis', 'FontSize', 14, 'FontWeight', 'bold');
end