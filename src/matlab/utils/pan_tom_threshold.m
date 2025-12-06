function r_locs = pan_tom_threshold(ecg, y, Fs)
% pt_threshold - Adaptive thresholding for Pan–Tompkins
%
% INPUT:
%   ecg - original filtered ECG
%   y   - integrated ECG from pt_preprocess
%
% OUTPUT:
%   r_locs - indices of detected R-peaks

    % Peak detection on integrated signal
    [~, peak_locs] = findpeaks(y, ...
        'MinPeakDistance', round(0.25*Fs));  % 250ms refractory
    
    % Initialize thresholds
    SPKI = max(ecg(1:2*Fs));   % Signal peak initial estimate
    NPKI = mean(ecg(1:Fs));    % Noise peak estimate
    
    r_locs = [];
    
    for i = 1:length(peak_locs)
        idx = peak_locs(i);

        % Local maximum in original ECG around integrated peak
        search_radius = round(0.05 * Fs); % 50 ms
        left  = max(1, idx - search_radius);
        right = min(length(ecg), idx + search_radius);
        [peakAmp, peakIndex] = max(ecg(left:right));
        realPeak = left + peakIndex - 1;
        
        % Adaptive threshold
        THRESHOLD = NPKI + 0.25*(SPKI - NPKI);

        if peakAmp > THRESHOLD
            r_locs(end+1) = realPeak; %#ok<AGROW>
            SPKI = 0.125*peakAmp + 0.875*SPKI;
        else
            NPKI = 0.125*peakAmp + 0.875*NPKI;
        end
    end

end
