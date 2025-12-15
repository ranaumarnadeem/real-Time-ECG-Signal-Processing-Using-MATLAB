function [r_locs, r_peaks] = r_peak_detection(ecg, Fs)
% detect_r_peaks_pt - Pan-Tompkins R-peak detection
%
% INPUT:
%   ecg  - preprocessed ECG (baseline removed, filtered)
%   Fs   - sampling rate
%
% OUTPUT:
%   r_locs  - sample indices of R-peaks
%   r_peaks - amplitudes of R-peaks

    % -------------------------------
    % 1. Differentiation, Squaring, Integration
    % -------------------------------
    y = pan_tom_preprocess(ecg, Fs);

    % -------------------------------
    % 2. Thresholding + Peak Detection
    % -------------------------------
    r_locs = pan_tom_threshold(ecg, y, Fs);

    % Return R-peak amplitudes
    r_peaks = ecg(r_locs);

end
