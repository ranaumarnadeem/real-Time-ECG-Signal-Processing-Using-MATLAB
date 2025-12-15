function [P_locs, T_locs, P_peaks, T_peaks] = detect_p_t_waves(ecg, r_locs, Fs)
% Detect P-wave and T-wave around each R-peak
% Simple delineation based on time windows

num_beats = length(r_locs);
P_locs = zeros(num_beats, 1);
T_locs = zeros(num_beats, 1);

for i = 1:num_beats
    
    r = r_locs(i);

    % ----------- P-WAVE (look BEFORE R-peak) -------------
    p_start = max(1, r - round(0.25 * Fs));   % 250 ms before
    p_end   = max(1, r - round(0.10 * Fs));   % 100 ms before

    [p_amp, p_idx] = max(ecg(p_start:p_end)); % Local max
    P_locs(i) = p_start + p_idx - 1;

    % ----------- T-WAVE (look AFTER QRS) -----------------
    t_start = min(length(ecg), r + round(0.15 * Fs));  % 150 ms after
    t_end   = min(length(ecg), r + round(0.40 * Fs));  % 400 ms after

    [t_amp, t_idx] = max(ecg(t_start:t_end));
    T_locs(i) = t_start + t_idx - 1;

end

P_peaks = ecg(P_locs);
T_peaks = ecg(T_locs);

end
