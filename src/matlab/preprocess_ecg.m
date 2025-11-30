function [clean_ecg, original_ecg, Fs] = preprocess_ecg(record_name, data_path)
 

    fprintf('Loading ECG data for record: %s\n', record_name);
    [original_ecg, Fs, ~, ~] = load_ecg(record_name, data_path);
    
    fprintf('Removing DC offset...\n');
    ecg_zero_mean = original_ecg - mean(original_ecg);
   
    fprintf('Removing baseline wander...\n');
    ecg_baseline_removed = remove_baseline_wander(ecg_zero_mean, Fs);
    
    fprintf('Normalizing signal amplitude...\n');
    clean_ecg = normalize_signal(ecg_baseline_removed);
    
    
    fprintf('Preprocessing completed successfully!\n');
    fprintf('Original signal range: [%.3f, %.3f]\n', min(original_ecg), max(original_ecg));
    fprintf('Clean signal range: [%.3f, %.3f]\n', min(clean_ecg), max(clean_ecg));
end