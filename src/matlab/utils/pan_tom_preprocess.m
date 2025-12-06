function y = pan_tom_preprocess(ecg, Fs)
% Pan–Tompkins preprocessing:
% Differentiation -> Squaring -> Moving Window Integration

    % ----------- (1) DIFFERENTIATION --------------------
    % Standard Pan-Tompkins 5-point derivative
    diff_ecg = filter([1 2 0 -2 -1] * (1/(8*1/Fs)), 1, ecg);

    % ----------- (2) SQUARING ---------------------------
    squared_ecg = diff_ecg .^ 2;

    % ----------- (3) MOVING WINDOW INTEGRATION ----------
    win_size = round(0.15 * Fs);  % 150 ms window
    mov_int = conv(squared_ecg, ones(1,win_size)/win_size, 'same');

    y = mov_int;
end
