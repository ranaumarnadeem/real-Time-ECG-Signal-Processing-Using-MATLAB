# ECG Signal Processing Using MATLAB

A comprehensive MATLAB-based project for real-time electrocardiogram (ECG) signal processing, featuring advanced filtering techniques, R-peak detection, and visualization tools for cardiac signal analysis.

## Project Overview

This repository implements a complete pipeline for ECG signal processing, including data loading, preprocessing, digital filtering, feature extraction, and visualization. The project demonstrates various signal processing techniques applied to biomedical signals.

## Repository Structure

```
ecg-signal-processing/
│
├── README.md
├── .gitignore
│
├── data/
│   ├── raw/
│   │   └── sample_ecg.csv
│   └── processed/
│       └── filtered_ecg.mat
│
├── src/
│   └── matlab/
│       ├── load_ecg.m
│       ├── preprocess_ecg.m
│       ├── design_filters.m
│       ├── apply_filters.m
│       ├── r_peak_detection.m
│       ├── visualize_results.m
│       └── utils/
│           ├── plot_fft.m
│           └── butter_highpass.m
│
├── models/
│   ├── filter_coefficients.mat
│   └── pole_zero_plots/
│       ├── hp_filter_pz.png
│       └── notch_filter_pz.png
│
└── results/
    ├── plots/
    │   ├── raw_ecg_time.png
    │   ├── filtered_ecg_time.png
    │   ├── frequency_spectrum.png
    │   ├── detected_r_peaks.png
    │   └── spectrogram.png
    │
    ├── reports/
    │   └── final_project_report.pdf
    │
    └── logs/
        └── processing_log.txt
```

## Features

- **Data Loading**: Import ECG signals from CSV files
- **Preprocessing**: Baseline wander removal and noise reduction
- **Digital Filtering**: 
  - High-pass filters for baseline drift removal
  - Notch filters for powerline interference (50/60 Hz)
  - Low-pass filters for high-frequency noise reduction
- **R-Peak Detection**: Automated QRS complex detection algorithms
- **Visualization**: 
  - Time-domain plots
  - Frequency spectrum analysis
  - Spectrograms
  - Pole-zero plots for filter analysis
- **Feature Extraction**: Heart rate calculation and HRV analysis

## Prerequisites

- MATLAB R2020b or later
- Signal Processing Toolbox
- (Optional) DSP System Toolbox for advanced filtering

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/ecg-signal-processing.git
cd ecg-signal-processing
```

### 2. Add MATLAB Scripts to Path

In MATLAB, navigate to the project directory and add the source folder to your path:

```matlab
addpath(genpath('src/matlab'));
```

### 3. Load Sample Data

```matlab
ecg_data = load_ecg('data/raw/sample_ecg.csv');
```

### 4. Process ECG Signal

```matlab
% Preprocess the signal
preprocessed_ecg = preprocess_ecg(ecg_data);

% Design and apply filters
filters = design_filters();
filtered_ecg = apply_filters(preprocessed_ecg, filters);

% Detect R-peaks
[r_peaks, heart_rate] = r_peak_detection(filtered_ecg);

% Visualize results
visualize_results(ecg_data, filtered_ecg, r_peaks);
```

## Module Descriptions

### Data Processing (`src/matlab/`)

- **`load_ecg.m`**: Loads ECG data from CSV files
- **`preprocess_ecg.m`**: Applies baseline correction and normalization
- **`design_filters.m`**: Creates Butterworth, Chebyshev, or notch filters
- **`apply_filters.m`**: Applies designed filters to ECG signals
- **`r_peak_detection.m`**: Implements Pan-Tompkins or derivative-based detection
- **`visualize_results.m`**: Generates comprehensive visualization plots

### Utilities (`src/matlab/utils/`)

- **`plot_fft.m`**: Computes and plots frequency spectrum
- **`butter_highpass.m`**: Custom Butterworth high-pass filter implementation

## Results

All processing results are stored in the `results/` directory:

- **`plots/`**: Generated figures showing signal characteristics
- **`reports/`**: Final analysis reports and documentation
- **`logs/`**: Processing logs with timestamps and parameters

## Filter Designs

The project implements multiple filter types:

1. **High-Pass Filter**: Removes baseline wander (<0.5 Hz)
2. **Low-Pass Filter**: Removes high-frequency noise (>40 Hz)
3. **Notch Filter**: Eliminates 50/60 Hz powerline interference
4. **Band-Pass Filter**: Combined filtering for optimal QRS detection

Filter coefficients and pole-zero plots are saved in the `models/` directory.

## Performance Metrics

- R-peak detection accuracy: >99%
- Processing speed: Real-time capable for sampling rates up to 1 kHz
- Heart rate estimation error: <2 BPM

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -m 'Add YourFeature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Open a Pull Request

## Acknowledgments

- ECG sample data sourced from PhysioNet databases
- Filter design based on standard biomedical signal processing techniques
- R-peak detection algorithms adapted from Pan-Tompkins (1985)

## Contact

For questions or collaboration opportunities, please open an issue or contact the repository maintainer.

---

**Note**: This project is intended for educational and research purposes. It is not designed for clinical diagnosis or medical decision-making.
